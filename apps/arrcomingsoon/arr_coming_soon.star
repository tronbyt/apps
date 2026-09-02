"""
Applet: Coming Soon for Sonarr/Radarr
Summary: What your *arr drops next
Description: Tonight's episodes and this week's movie releases, straight from
your own Sonarr or Radarr calendar.
Author: nsluke

Layout (64x32): a 7px header (service glyph + TONIGHT / THIS WEEK + a "+N"
overflow counter), a 1px rule, then two 12px item rows. Sonarr rows are
series-title marquee over S05E03 + air time/weekday; Radarr rows are title
marquee over release type (DIGITAL / CINEMA / DISC) + weekday. A green pip
after the episode label means Sonarr already has the file.

Ordering is "what's next", not "what's on the calendar today": an episode
that already aired more than AIRED_GRACE hours ago sinks below everything
still upcoming and only ever appears as filler, so a two-row panel headed
TONIGHT cannot fill up with this morning's dailies.

Data: the user's OWN instance on their LAN - GET <base>/api/v3/calendar with
an X-Api-Key header. Shapes verified against both projects' published OpenAPI
specs (2026-09): Sonarr returns EpisodeResource[] (title, series.title and
airDateUtc are all nullable; includeSeries=true is required for the series
title), Radarr returns MovieResource[] (title nullable; inCinemas /
digitalRelease / physicalRelease each nullable).

Two timezone rules, and they differ on purpose: Sonarr's airDateUtc is a real
instant, so it is converted through the configured location (an 01:00Z airdate
IS tonight in the US). Radarr's release fields are midnight-UTC stand-ins for
plain DATES - converting those through a US timezone would shift every release
a day early, so only the date part is used, unconverted.

With no URL/key configured the app renders a built-in demo card (zero
network) so the default install always shows something worth looking at.
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

FRESH_TTL = 900  # got data: don't re-poll the LAN box for 15 min
RETRY_TTL = 60  # any failure: back off a minute before the next attempt
STALE_TTL = 86400  # serve the last good extract up to a day through an outage
AUTH_TTL = 3600  # a diagnosed bad key re-checks hourly at worst

# How long an episode stays "now" after its air time. Long enough that a show
# still on air leads the panel, short enough that this morning's daily does
# not outrank tonight's premiere.
AIRED_GRACE = 3.0

WHITE = "#FFFFFF"
GREY = "#9C9C9C"
DIM = "#5A5A5A"
RULE = "#333333"
GREEN = "#3DDC84"
RED = "#FF6B6B"

SONARR_BLUE = "#35C5F4"
RADARR_GOLD = "#FFC230"

DAYS = {"1": 1, "3": 3, "7": 7}

# RFC3339 sniff: time.parse_time on a malformed string ABORTS the render
# (uncatchable), so nothing reaches it without matching one of these first.
# The regex only checks SHAPE - "T99:00:00Z" still matches - so valid_instant
# range-checks the digits too (verified on the local binary: out-of-range
# hour/month/day/second all abort parse_time; offsets and time.time do not).
TS_RE = r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$"
DATE_RE = r"^\d{4}-\d{2}-\d{2}$"

# 5x5 pixel service glyphs: Sonarr's sonar target, a play arrow for Radarr.
GLYPH_SONARR = [
    ".###.",
    "#...#",
    "#.#.#",
    "#...#",
    ".###.",
]
GLYPH_RADARR = [
    "#....",
    "###..",
    "#####",
    "###..",
    "#....",
]

def main(config):
    service = "radarr" if config.get("service", "sonarr") == "radarr" else "sonarr"
    days = DAYS.get(config.get("days", "7"), 7)
    tz = get_tz(config)

    # "api" is a CLI-only test hook (no schema field, per the exemplar - a
    # visible field would silently override the real Server URL on phones).
    base = (config.get("api", "") or config.get("url", "") or "").strip().rstrip("/")
    key = (config.get("apikey", "") or "").strip()
    now = time.now().in_location(tz)

    if base == "" or key == "":
        items = demo_items(service, now, tz)
        return render_list(service, items, now, tz, days, demo = True)

    # A schemeless/malformed base (the single most likely URL typo) is the one
    # transport error that IS detectable before http.get - which would abort
    # the render uncatchably once per RETRY_TTL, forever, since the URL never
    # heals on its own. Catch it pre-flight and say so instead. Case-blind:
    # phone keyboards capitalize, and Go's URL parser accepts "Http://"
    # (verified on the local binary against the stub).
    low = base.lower()
    if not (low.startswith("http://") or low.startswith("https://")) or host_of(base) == "":
        return card(service, "CHECK URL", host_of(base) or base, RED)

    got = get_calendar(service, base, key, days, tz, now)
    if got == "auth":
        return card(service, "CHECK API KEY", "unauthorized", RED)
    if got == "service":
        other = "sonarr" if service == "radarr" else "radarr"
        return card(service, "CHECK SERVICE", "got " + other + " data", RED)
    if got == None:
        return card(service, "CAN'T CONNECT", host_of(base), GREY)
    return render_list(
        service,
        got["items"],
        now,
        tz,
        days,
        demo = False,
        stale_host = host_of(base) if got["stale"] else None,
    )

def get_tz(config):
    """in_location() on an unknown zone name ABORTS the render (uncatchable),
    so every timezone string - the Location config's and the runtime's $tz -
    goes through time.is_valid_timezone first (verified present on local
    pixlet 0.34: Bogus/Zone -> False, real IANA names -> True)."""
    loc = config.get("location")
    if loc != None:
        loc = loc.strip()
        if loc.startswith("{") and loc.endswith("}"):
            obj = json.decode(loc, None)  # default: bad JSON must not abort
            if type(obj) == "dict":
                tz = obj.get("timezone", "")
                if type(tz) == "string" and tz != "" and time.is_valid_timezone(tz):
                    return tz
    tz = config.get("$tz") or "America/New_York"
    return tz if time.is_valid_timezone(tz) else "America/New_York"

def host_of(base):
    i = base.find("://")
    host = base[i + 3:] if i >= 0 else base
    j = host.find("/")
    return host[:j] if j >= 0 else host

# ---------------------------------------------------------------- data layer

def get_calendar(service, base, key, days, tz, now):
    """Returns {"items": [...], "stale": bool} for usable data, "auth" for a
    rejected key, "service" for a service/URL mismatch, or None when the
    server is unreachable and nothing usable is cached. "stale" says the live
    fetch failed and these items came out of the cache - the caller needs it,
    because an empty STALE extract is an outage, not an empty calendar. The
    cache key carries every config value the data depends on."""
    ck = "arrsoon:v3:" + service + ":" + str(days) + ":" + tz + ":" + base + ":" + key

    # A diagnosed config problem answers from cache with NO request: AUTH_TTL
    # is the promise that a bad key or a service mismatch re-checks hourly at
    # worst, and the gate alone cannot keep it. Recovery is still immediate
    # because correcting the key, URL or service changes ck.
    marker = diagnosed(cache.get(ck))
    if marker != None:
        return marker

    start = time.time(year = now.year, month = now.month, day = now.day, location = tz)

    # Count calendar days like classify() does, not 24h blocks: across the
    # DST fall-back, midnight + days*24h ends an HOUR SHORT of the window the
    # panel displays, so the last day's late-night episodes are never even
    # requested (Sonarr/Radarr filter server-side, and the client clamp can
    # only remove). time.time normalizes day overflow.
    end = time.time(year = now.year, month = now.month, day = now.day + days, location = tz)

    d = fetch_calendar(service, base, key, start, end, ck + ":gate")
    if d == "auth":
        return mark(ck, "auth")
    if d == None:
        raw = cache.get(ck)
        if raw == None:
            return None
        obj = json.decode(raw, None)  # our own blob, but decode defensively
        if type(obj) != "dict":
            return None
        items = obj.get("items", [])
        return {"items": items if type(items) == "list" else [], "stale": True}

    items = extract_sonarr(d) if service == "sonarr" else extract_radarr(d)
    if len(items) == 0 and other_service_answered(service, d):
        # Radarr selected but a Sonarr URL configured (or vice versa) would
        # otherwise extract zero items from a FULL calendar and render a
        # confident ALL CAUGHT UP.
        return mark(ck, "service")
    cache.set(ck, json.encode({"items": items}), ttl_seconds = STALE_TTL)
    return {"items": items, "stale": False}

def mark(ck, err):
    """Cache a diagnosed config state AND hold the gate for as long as the
    marker lives, so a permanently misconfigured install stops re-polling the
    LAN box every RETRY_TTL. The exemplar paces its idle path the same way
    (cache.set(ck + ":gate", "1", ttl_seconds = FRESH_IDLE))."""
    cache.set(ck, json.encode({"err": err}), ttl_seconds = AUTH_TTL)
    cache.set(ck + ":gate", "1", ttl_seconds = AUTH_TTL)
    return err

def diagnosed(raw):
    """A cached {"err": ...} marker -> the diagnosis; anything else -> None."""
    if raw == None:
        return None
    obj = json.decode(raw, None)
    if type(obj) != "dict":
        return None
    err = obj.get("err")
    return err if err == "auth" or err == "service" else None

def other_service_answered(service, d):
    """A non-empty calendar that extracted to ZERO items is either genuinely
    undated or the OTHER *arr answering: sniff the first dict entry for the
    other service's signature keys (presence only - values may be null).
    EpisodeResource always carries seriesId/episodeNumber/airDateUtc keys;
    MovieResource always carries tmdbId and the release-date keys."""
    for e in d[:5]:
        if type(e) != "dict":
            continue
        if service == "sonarr":
            return "digitalRelease" in e or "inCinemas" in e or "physicalRelease" in e or "tmdbId" in e
        return "airDateUtc" in e or "episodeNumber" in e or "seriesId" in e
    return False

def fetch_calendar(service, base, key, start, end, gate_key):
    """Gate-before-request: a transport error aborts the render uncatchably,
    so the gate (written before the request) limits the damage to one failed
    render per RETRY_TTL; every later render serves cache."""
    if cache.get(gate_key) != None:
        return None
    cache.set(gate_key, "1", ttl_seconds = RETRY_TTL)

    url = base + "/api/v3/calendar?start=" + fmt_utc(start) + "&end=" + fmt_utc(end)
    if service == "sonarr":
        url += "&includeSeries=true"
    resp = http.get(url, headers = {"X-Api-Key": key}, ttl_seconds = RETRY_TTL)
    if resp.status_code == 401 or resp.status_code == 403:
        return "auth"
    if resp.status_code != 200:
        print("arrsoon: " + url[:60] + " -> " + str(resp.status_code))
        return None
    body = resp.body().strip()
    if not (body.startswith("[") and body.endswith("]")):
        print("arrsoon: non-JSON-array body from " + url[:60])
        return None
    d = json.decode(body, None)  # array-SHAPED garbage must not abort either
    if d == None:
        print("arrsoon: undecodable body from " + url[:60])
        return None
    cache.set(gate_key, "1", ttl_seconds = FRESH_TTL)
    return d

def fmt_utc(t):
    return t.in_location("UTC").format("2006-01-02T15:04:05") + "Z"

def extract_sonarr(d):
    """EpisodeResource[] -> small cached items. Anything without a sane
    airDateUtc can't be placed on a timeline, so it is skipped."""
    items = []
    for e in d[:40]:
        if type(e) != "dict":
            continue
        utc = e.get("airDateUtc")
        if type(utc) != "string" or not re.match(TS_RE, utc) or not valid_instant(utc):
            continue
        stitle = None
        ser = e.get("series")
        if type(ser) == "dict":
            stitle = ser.get("title")
        if type(stitle) != "string" or stitle.strip() == "":
            stitle = "Unknown series"
        items.append({
            "t": clip(stitle),
            "l": ep_label(e.get("seasonNumber"), e.get("episodeNumber")),
            "u": utc,
            "h": True if e.get("hasFile") else False,
        })
    return items

def valid_instant(s):
    """Range-check a TS_RE-shaped string so a cached value can never make
    time.parse_time abort: hour 99 / month 13 / Feb 30 all pass the regex but
    kill the render at parse. Character positions are fixed by the regex."""
    y = int(s[0:4])
    mo = int(s[5:7])
    dy = int(s[8:10])
    if mo < 1 or mo > 12 or dy < 1 or dy > month_days(y, mo):
        return False
    if int(s[11:13]) > 23 or int(s[14:16]) > 59 or int(s[17:19]) > 59:
        return False
    return True

def month_days(y, mo):
    if mo == 2:
        leap = (y % 4 == 0 and y % 100 != 0) or y % 400 == 0
        return 29 if leap else 28
    return 30 if mo in (4, 6, 9, 11) else 31

def ep_label(season, ep):
    """At most 7 chars, which is what the 60px meta line can spare beside a
    7-char air time. A 4+ digit episode number IS absolute numbering (anime,
    dailies), so the season is noise there and dropping it is what keeps the
    episode number itself readable: "S01E1100" does not fit, "E1100" does."""
    if type(ep) != "int" or ep < 0:
        return "NEW"
    if type(season) != "int" or season < 0 or season > 99 or ep > 999:
        return ("E" + str(ep))[:7]  # daily shows use year-sized season numbers
    return "S" + pad2(season) + "E" + pad2(ep)

def pad2(n):
    s = str(n)
    return s if len(s) >= 2 else "0" + s

def extract_radarr(d):
    """MovieResource[] -> items keeping EVERY plausible release date, because
    which one is 'next' depends on the render-time date, not the fetch-time
    one. Radarr dates are date-semantics: only the yyyy-mm-dd part is kept."""
    items = []
    for m in d[:40]:
        if type(m) != "dict":
            continue
        title = m.get("title")
        if type(title) != "string" or title.strip() == "":
            title = "Untitled"
        year = m.get("year")
        if type(year) == "int" and year > 1800 and year < 2200:
            title = title + " (" + str(year) + ")"
        rel = []
        for pair in [("digitalRelease", "DIGITAL"), ("physicalRelease", "DISC"), ("inCinemas", "CINEMA")]:
            v = m.get(pair[0])
            if type(v) == "string" and re.match(TS_RE, v):
                rel.append([v[:10], pair[1]])
        if len(rel) == 0:
            continue
        items.append({"t": clip(title), "rel": rel})
    return items

def clip(s, n = 48):
    # Caps marquee length so one absurd title can't stretch the animation
    # cycle past the device dwell.
    return s if len(s) <= n else s[:n - 2] + ".."

# ------------------------------------------------------------ classification

def classify(items, now, tz, days):
    """Cached/demo items -> renderable rows, clamped to the days window
    CLIENT-side (never trust the server to honor start/end - and a stale
    cache can hold items the window has since scrolled past). Sonarr instants
    convert through tz; Radarr dates never do.

    Order is what's NEXT: still-upcoming rows soonest-first, then anything
    that already aired, most recent first. The panel shows two rows under a
    TONIGHT header, so an already-aired 6AM daily outranking tonight's 9PM
    premiere would be a straight lie; as filler below it is still useful."""
    today = local_midnight(now, tz)
    today_str = today.format("2006-01-02")
    upcoming = []
    aired = []
    for i, it in enumerate(items):
        if "u" in it:
            t = time.parse_time(it["u"]).in_location(tz)  # TS_RE-vetted before caching
            dstr = t.format("2006-01-02")
            if dstr < today_str:
                continue
            diff = day_diff(today, local_midnight(t, tz))
            if diff >= days:
                continue
            past = (now - t).hours > AIRED_GRACE
            day = t.format("3:04PM") if diff == 0 else day_label(t, diff)
            row = (t.format("2006-01-02T15:04:05"), i, {
                "t": it["t"],
                "l": it["l"],
                "day": day,
                "diff": diff,
                "dot": it.get("h", False),
                "past": past,
                "eve": t.hour >= 17,
            })
            if past:
                aired.append(row)
            else:
                upcoming.append(row)
        else:
            best = None
            for r in it.get("rel", []):
                if type(r) != "list" or len(r) != 2:
                    continue
                if type(r[0]) != "string" or not re.match(DATE_RE, r[0]):
                    continue
                if r[0] < today_str:
                    continue
                if best == None or r[0] < best[0]:
                    best = r
            if best == None:
                continue
            t = time.time(
                year = int(best[0][0:4]),
                month = int(best[0][5:7]),
                day = int(best[0][8:10]),
                location = tz,
            )
            diff = day_diff(today, t)
            if diff >= days:
                continue

            # Radarr dates carry no time of day, so a release dated today is
            # out today - never "already aired".
            upcoming.append((best[0] + "T00:00:00", i, {
                "t": it["t"],
                "l": best[1],
                "day": "TODAY" if diff == 0 else day_label(t, diff),
                "diff": diff,
                "dot": False,
                "past": False,
                "eve": True,  # unused: Radarr rows are headed OUT NOW
            }))
    return [k[2] for k in sorted(upcoming)] + [k[2] for k in sorted(aired, reverse = True)]

def local_midnight(t, tz):
    return time.time(year = t.year, month = t.month, day = t.day, location = tz)

def day_diff(a, b):
    return int(((b - a).hours + 1.0) // 24.0)  # +1 rides out DST's 23h days

def day_label(t, diff):
    if diff > 6:
        return t.format("Jan 2").upper()  # a weekday 7+ days out reads as today
    return t.format("Mon").upper()

# ------------------------------------------------------------------- layouts

def accent_of(service):
    return SONARR_BLUE if service == "sonarr" else RADARR_GOLD

def glyph(service):
    rows = GLYPH_SONARR if service == "sonarr" else GLYPH_RADARR
    accent = accent_of(service)
    dots = [render.Box(width = 5, height = 5)]
    for y, row in enumerate(rows):
        for x in range(len(row)):
            if row[x] == "#":
                dots.append(render.Padding(
                    pad = (x, y, 0, 0),
                    child = render.Box(width = 1, height = 1, color = accent),
                ))
    return render.Stack(children = dots)

def header(service, label, corner):
    layers = [
        render.Box(width = 64, height = 7),
        render.Padding(pad = (1, 1, 0, 0), child = glyph(service)),
        render.Padding(
            pad = (9, 1, 0, 0),
            child = render.Text(label, font = "tom-thumb", color = accent_of(service)),
        ),
    ]
    if corner != "":
        layers.append(render.Padding(
            pad = (63 - 4 * len(corner), 1, 0, 0),
            child = render.Text(corner, font = "tom-thumb", color = DIM),
        ))
    return render.Stack(children = layers)

def item_row(row, service):
    # tom-thumb advances 4px per character and draws 3 of them, so a label of
    # L chars starting at x=2 ends at x=4L and a right-aligned day string of D
    # chars starts at x=62-4D. Both are absolute, so the pip between them is
    # placed from the same arithmetic instead of an independent guess.
    label, day = row["l"], row["day"]
    day_x = 62 - 4 * len(day)
    pip_x = 2 + 4 * len(label)
    day_color = WHITE if row["diff"] == 0 and not row["past"] else GREY
    meta = [
        render.Box(width = 64, height = 6),
        render.Padding(
            pad = (2, 0, 0, 0),
            child = render.Text(label, font = "tom-thumb", color = accent_of(service)),
        ),
        render.Padding(
            pad = (day_x, 0, 0, 0),
            child = render.Text(day, font = "tom-thumb", color = day_color),
        ),
    ]

    # The pip is decorative and its x depends on a label that came out of the
    # cache, so it is drawn only where it clears the air time with a pixel to
    # spare - never on top of it, which turned "12:00AM" into "2:00AM".
    # ep_label caps labels at 7 chars and the widest day string is 7, so in
    # practice this is a bound, not a branch the live app takes.
    if row["dot"] and pip_x + 3 < day_x:
        meta.append(render.Padding(
            pad = (pip_x, 1, 0, 0),
            child = render.Box(width = 3, height = 3, color = GREEN),
        ))
    return render.Column(
        children = [
            render.Padding(
                pad = (2, 0, 0, 0),
                child = render.Marquee(
                    width = 62,
                    child = render.Text(row["t"], font = "tom-thumb", color = WHITE),
                ),
            ),
            render.Stack(children = meta),
        ],
    )

def render_list(service, items, now, tz, days, demo, stale_host = None):
    rows = classify(items, now, tz, days)
    if len(rows) == 0:
        if stale_host != None:
            # The live fetch failed AND the cached extract no longer holds
            # anything in-window. "ALL CAUGHT UP thru <date>" would be a
            # confident claim about days that were never fetched - and
            # STALE_TTL is a day, so it would hold all through an outage.
            return card(service, "CAN'T CONNECT", stale_host, GREY)

        # Count CALENDAR days like classify() does, not duration hours:
        # midnight + (days-1)*24h lands a day short across a DST fall-back
        # (Oct 31 + 6*24h = Nov 5 23:00 EST while Nov 6 is still in-window).
        # time.time normalizes day overflow (probed: Oct 31 + day 37 -> Nov 6,
        # Dec 31 + day 34 -> Jan 3).
        last = time.time(year = now.year, month = now.month, day = now.day + days - 1, location = tz)
        sub = "thru " + last.format("Jan 2").upper() if days > 1 else "nothing tonight"
        return card(service, "ALL CAUGHT UP", sub, WHITE)

    # "TONIGHT" is a claim about the top row, so only make it when the top row
    # is actually tonight: not something that already aired (nothing upcoming
    # is left in the window), and not a 12:00PM airing, which is what a UTC+12
    # viewer sees for a US prime-time slot.
    top = rows[0]
    if top["diff"] != 0:
        label = "THIS WEEK"
    elif service != "sonarr":
        label = "OUT NOW"
    elif top["past"] or not top["eve"]:
        label = "TODAY"
    else:
        label = "TONIGHT"
    corner = ""
    if demo:
        corner = "DEMO"
    elif len(rows) > 2:
        corner = "+" + str(len(rows) - 2)

    kids = [
        header(service, label, corner),
        render.Box(width = 64, height = 1, color = RULE),
    ]
    for row in rows[:2]:
        kids.append(item_row(row, service))
    return render.Root(child = render.Column(children = kids))

def card(service, big, small, big_color):
    """Full-status card: caught-up, unreachable, bad key."""
    return render.Root(
        child = render.Column(
            children = [
                header(service, service.upper(), ""),
                render.Box(width = 64, height = 1, color = RULE),
                render.Box(
                    width = 64,
                    height = 24,
                    child = render.Column(
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(big, font = "tom-thumb", color = big_color),
                            render.Box(width = 1, height = 2),
                            render.Marquee(
                                width = 60,
                                align = "center",
                                child = render.Text(small, font = "tom-thumb", color = GREY),
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

# ---------------------------------------------------------------------- demo

def demo_items(service, now, tz):
    """Fictional-but-plausible calendar, built relative to render time so the
    demo always opens on a TONIGHT state. Zero network."""
    if service == "sonarr":
        return [
            {"t": "Signal Lost", "l": "S03E05", "u": demo_utc(now, tz, 0, 21), "h": False},
            {"t": "Harbor Lights", "l": "S01E08", "u": demo_utc(now, tz, 0, 22), "h": True},
            {"t": "The Long Static", "l": "S02E01", "u": demo_utc(now, tz, 2, 20), "h": False},
            {"t": "Copper Canyon", "l": "S05E12", "u": demo_utc(now, tz, 4, 21), "h": False},
        ]
    return [
        {"t": "Midnight Freight (2026)", "rel": [[demo_date(now, tz, 0), "DIGITAL"]]},
        {"t": "The Glass Orchard (2025)", "rel": [[demo_date(now, tz, 3), "DISC"]]},
        {"t": "Static Fields (2026)", "rel": [[demo_date(now, tz, 5), "CINEMA"]]},
    ]

def demo_utc(now, tz, days_ahead, hour):
    t = local_midnight(now, tz) + time.parse_duration(str(days_ahead * 24 + hour) + "h")
    return fmt_utc(t)

def demo_date(now, tz, days_ahead):
    t = local_midnight(now, tz) + time.parse_duration(str(days_ahead * 24) + "h")
    return t.format("2006-01-02")

# -------------------------------------------------------------------- schema

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "service",
                name = "Service",
                desc = "Which *arr calendar to watch.",
                icon = "tv",
                default = "sonarr",
                options = [
                    schema.Option(display = "Sonarr (TV)", value = "sonarr"),
                    schema.Option(display = "Radarr (movies)", value = "radarr"),
                ],
            ),
            schema.Text(
                id = "url",
                name = "Server URL",
                desc = "Base URL of your instance, e.g. http://192.168.1.50:8989.",
                icon = "globe",
                default = "",
            ),
            schema.Text(
                id = "apikey",
                name = "API key",
                desc = "From Settings > General in Sonarr/Radarr.",
                icon = "key",
                default = "",
            ),
            schema.Dropdown(
                id = "days",
                name = "Days ahead",
                desc = "How far into the calendar to look.",
                icon = "calendarDay",
                default = "7",
                options = [
                    schema.Option(display = "Tonight only", value = "1"),
                    schema.Option(display = "3 days", value = "3"),
                    schema.Option(display = "7 days", value = "7"),
                ],
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Timezone for air dates.",
                icon = "locationDot",
            ),
        ],
    )
