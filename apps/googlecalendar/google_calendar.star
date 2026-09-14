"""
Applet: Google Calendar
Summary: Your next event at a glance
Description: Shows the next event on your primary Google Calendar, in the spirit of Tidbyt's first-party app.
Author: nsluke

Layout: a red-banner pixel calendar icon on the left showing the date the
card is about, and on the right the event title over a when-line: "in 25 min"
as it approaches, "3:30 PM" later the same day, "NOW" while it is in
progress, "Thursday" for tomorrow onward, "All day" for date-only events.
With nothing left today it previews the next event within a week, or shows
"All clear".

On a square (64x64) panel that same card is the top half and the height goes
to what a glance asks next: a hairline, then the following events one row
each, "when | what". Cards that are not about an event (setup, offline, All
clear) become a centred poster instead. See square_card.

Auth, three ways, first match wins:
  1. config "auth" non-empty -> used directly as a Bearer access token. This
     is the tronbyt server Connections injection contract: the server owns
     the OAuth dance and hands the app a live token.
  2. client_id + client_secret + refresh_token -> classic manual OAuth like
     the community spotify app: one POST to oauth2.googleapis.com exchanges
     the refresh token for an access token, cached for expires_in - 60.
  3. Neither -> a setup card, rendered with zero network.

API notes, verified against the live discovery doc (see repo notes):
  - events.list timeMin filters on the event's END time, so an in-progress
    event is still returned when timeMin=now. That is what makes NOW work.
  - maxAttendees=1 returns only the requesting participant, which is exactly
    the attendee needed for the self-declined check, and keeps big meetings
    from bloating the payload.
  - eventTypes defaults to "all", which mixes Google's own working-location,
    out-of-office, focus-time and birthday entries in with real meetings.
    Working-location events are all-day and therefore sort ahead of every
    timed event of the day, so they are asked for and filtered out.
  - maxResults is a PAGE size, not a result count, and a page may even come
    back empty with a nextPageToken. Declined events are dropped after the
    fetch, so pages are followed until something survives the filter.
  - start/end each carry either "dateTime" (RFC3339 with offset) or "date"
    (all-day). Display uses the offsets in the payload plus $tz; no Location
    schema field in v1.
  - a 401/403 on events clears the cached access token so the next cycle
    re-exchanges, and events render from stale cache through the outage.

Every fetch is gated (a transport error aborts a pixlet render uncatchably),
bodies are sniffed before json.decode, dates are fully validated and parsed
BEFORE anything is cached (time.parse_time aborts on an out-of-range date,
and a cached bad date would abort every render for as long as it lived), and
only small extracted values are cached, keyed by a hash of the credentials
they belong to.
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

TOKEN_HOST = "https://oauth2.googleapis.com"
API_HOST = "https://www.googleapis.com"
EVENTS_PATH = "/calendar/v3/calendars/primary/events"

RFC3339 = "2006-01-02T15:04:05Z07:00"
DAY_FMT = "2006-01-02"

FRESH_TTL = 240  # happy path: re-poll events every ~4 min
RETRY_TTL = 60  # back off after any failure
STALE_TTL = 21600  # serve the last good extract up to 6h through an outage
MAX_TOKEN_TTL = 86400  # cache.set rejects an oversized ttl, so cap expires_in
MAX_RESULTS = 25  # page size; declined events are filtered after the fetch
MAX_PAGES = 3  # follow nextPageToken this far while nothing has survived
WINDOW = 7 * 24 * 3600  # look ahead one week
MAX_LIST = 3  # square panels only: how far down the agenda the list runs

WHITE = "#FFFFFF"
GREY = "#9C9C9C"
AMBER = "#FFA33A"
RED = "#FF3B30"
GREEN = "#4CD964"
BANNER = "#EA4335"  # the Google Calendar red
PAPER = "#E8E8E8"
INKDARK = "#1A1A1A"
RULE = "#333333"  # the hairline under the square panel's hero

# The character table backing tiny_hash. find() returns -1 for anything
# exotic, which still hashes; this only needs to separate cache keys.
HASH_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~/+=:"

# base64url plus padding: the alphabet a Google pageToken is drawn from.
TOKEN_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_=."

DIGITS = "0123456789"

def main(config):
    tz = config.get("$tz") or "America/New_York"
    now = time.now().in_location(tz)

    # Undocumented test hook, deliberately NOT a schema field: this one value
    # redirects the token POST, which carries the client secret and refresh
    # token in its body, as well as the events GET.
    base = config.str("api", "").strip().rstrip("/")

    direct = config.str("auth", "").strip()
    cid = config.str("client_id", "").strip()
    csec = config.str("client_secret", "").strip()
    rtok = config.str("refresh_token", "").strip()

    if direct != "":
        idh = "c" + tiny_hash(direct)
        token = direct
    elif cid != "" and csec != "" and rtok != "":
        idh = "m" + tiny_hash(cid + ":" + rtok)
        token = get_access_token(cid, csec, rtok, idh, base)
    else:
        # Nothing configured: the zero-network setup card.
        return card(now, "Google Calendar", "no account", AMBER, "connect one in the app config")

    rec = get_events(token, idh, now, tz, base)
    if rec == None:
        if cache.get("gcal:autherr:" + idh) != None:
            return card(now, "Google Calendar", "reconnect", RED, "check account")
        return card(now, "Google Calendar", "offline", GREY, "")
    return render_events(rec, now, tz)

# ---------------------------------------------------------------- data layer

def tiny_hash(s):
    """djb2-style string hash so credentials never appear in cache keys."""
    h = 5381
    for ch in s.elems():
        h = (h * 33 + HASH_CHARS.find(ch) + 2) % 4294967296
    return str(h)

def form_enc(v):
    """Percent-encode the characters that would break a form body."""
    return v.replace("%", "%25").replace("&", "%26").replace("+", "%2B").replace("=", "%3D")

def looks_json(body):
    s = body.strip()  # Google terminates bodies with a newline
    return s.startswith("{") and s.endswith("}")

def get_access_token(cid, csec, rtok, idh, base):
    """Refresh-token exchange, cached until just before expiry. Returns None
    on failure; a 4xx also flags an auth error so main renders the reconnect
    card instead of the offline one."""
    ck = "gcal:at:" + idh
    tok = cache.get(ck)
    if tok != None and tok != "":
        return tok
    if cache.get(ck + ":gate") != None:
        return None  # recent attempt (or recent failure): don't thrash
    cache.set(ck + ":gate", "1", ttl_seconds = RETRY_TTL)

    url = (base if base != "" else TOKEN_HOST) + "/token"
    resp = http.post(
        url,
        headers = {"Content-Type": "application/x-www-form-urlencoded"},
        body = "grant_type=refresh_token&client_id=" + form_enc(cid) +
               "&client_secret=" + form_enc(csec) +
               "&refresh_token=" + form_enc(rtok),
    )
    body = resp.body()
    if resp.status_code != 200 or not looks_json(body):
        print("gcal: token exchange -> " + str(resp.status_code))
        if resp.status_code >= 400 and resp.status_code < 500:
            cache.set("gcal:autherr:" + idh, "1", ttl_seconds = RETRY_TTL)
        return None

    d = json.decode(body)
    at = d.get("access_token", "")
    if type(at) != "string" or at == "":
        return None
    cache.set(ck, at, ttl_seconds = token_ttl(d.get("expires_in", 3600)))
    return at

def token_ttl(exp):
    """expires_in minus a minute, defensively typed AND clamped: int() aborts
    on junk, and cache.set rejects a ttl that overflows an int64, so a body
    claiming expires_in "99999999999999999999" must not reach it."""
    n = 3600
    if type(exp) == "int":
        n = exp
    elif type(exp) == "float":
        n = int(exp)
    elif type(exp) == "string":
        v = to_int(exp)
        if v > 0:
            n = v
    return min(max(n - 60, 60), MAX_TOKEN_TTL)

def to_int(s):
    """Digits-only parse; -1 on anything else. int() would abort the render."""
    if s == "":
        return -1
    n = 0
    for ch in s.elems():
        d = DIGITS.find(ch)
        if d < 0:
            return -1
        n = n * 10 + d
    return n

def get_events(token, idh, now, tz, base):
    """The next week of events as a small extracted list, cached long so an
    outage serves the last good reading. Gate-before-request throughout, and
    a reading that could not be understood is never written to the cache."""
    ck = "gcal:ev:" + idh
    if token != None and cache.get(ck + ":gate") == None:
        cache.set(ck + ":gate", "1", ttl_seconds = RETRY_TTL)
        rec = fetch_events(token, idh, now, tz, base)
        if rec != None:
            cache.set(ck, json.encode(rec), ttl_seconds = STALE_TTL)
            cache.set(ck + ":gate", "1", ttl_seconds = FRESH_TTL)
            return rec

        # Unusable: leave the gate at RETRY_TTL and fall back to the last
        # good extract rather than persisting a fabricated empty week.

    raw = cache.get(ck)
    if raw != None and raw != "":
        return as_record(json.decode(raw))
    return None

def fetch_events(token, idh, now, tz, base):
    """One events.list read, following nextPageToken while nothing has
    survived the declined/all-types filter. Returns None when the response
    was not a usable events page - the caller must not cache that."""
    q = EVENTS_PATH + \
        "?maxResults=" + str(MAX_RESULTS) + \
        "&singleEvents=true&orderBy=startTime&maxAttendees=1&eventTypes=default" + \
        "&timeMin=" + enc_time(now.format(RFC3339)) + \
        "&timeMax=" + enc_time((now + time.parse_duration("168h")).format(RFC3339))
    host = base if base != "" else API_HOST

    out = []
    junk = 0
    page = ""
    more = ""
    for _page in range(MAX_PAGES):
        url = host + q + ("&pageToken=" + page if page != "" else "")
        resp = http.get(url, headers = {"Authorization": "Bearer " + token}, ttl_seconds = RETRY_TTL)
        body = resp.body()
        if resp.status_code != 200 or not looks_json(body):
            print("gcal: events -> " + str(resp.status_code))
            if resp.status_code == 401 or resp.status_code == 403:
                # The token is bad: drop it so the next cycle re-exchanges.
                cache.set("gcal:at:" + idh, "", ttl_seconds = 1)
                cache.set("gcal:autherr:" + idh, "1", ttl_seconds = RETRY_TTL)
            return None

        got = extract_events(json.decode(body), tz)
        if got == None:
            print("gcal: events body carried no item list")
            return None
        out.extend(got["e"])
        junk += got["junk"]
        more = got["more"]
        if len(out) > 0 or more == "" or more == page:
            break
        page = more

    if len(out) == 0 and junk > 0:
        # Items came back and not one of them could be read: that is a failed
        # reading, not an empty week, and it must not be cached as one.
        print("gcal: no readable event in " + str(junk) + " item(s)")
        return None

    # How far the reading got is part of the reading. "u" (unknown): the week
    # came back empty with a page still unread, so it is not "All clear". "c"
    # (complete): every page in the window was read, so a list that ran out is
    # genuinely the end of the week and the square agenda may say so.
    return {"v": 1, "e": out, "u": len(out) == 0 and more != "", "c": more == ""}

def as_record(v):
    """Cached extract, tolerating shapes written by older versions: the
    pre-pagination one (a bare list) and the pre-"c" one. Both read as
    incomplete, so the panel declines to claim a whole week rather than
    guessing on one - a stale entry is replaced within a poll anyway."""
    if type(v) == "list":
        return {"v": 1, "e": v, "u": False, "c": False}
    if type(v) != "dict":
        return None
    evs = v.get("e", None)
    if type(evs) != "list":
        return None
    return {"v": 1, "e": evs, "u": v.get("u", False) == True, "c": v.get("c", False) == True}

def enc_time(s):
    return s.replace("+", "%2B")  # a "+00:00" offset must not become a space

def safe_token(t):
    """A nextPageToken goes straight back into the query string, so only the
    base64url alphabet is accepted: a hostile body cannot append parameters."""
    if type(t) != "string" or t == "" or len(t) > 512:
        return ""
    for ch in t.elems():
        if TOKEN_CHARS.find(ch) < 0:
            return ""
    return t

def extract_events(d, tz):
    """One events.list page -> {e: [{t, s, e, a}], junk, more}: title, start,
    end, all_day. Returns None when the body is not an events page at all,
    which must never be cached as a reading of an empty week.

    Drops, and why they are counted differently: cancelled, declined and
    non-default event types (working location, out of office, focus time,
    birthdays) are events the user has nothing to attend, so an empty result
    is still "All clear"; an item we could not read is not, and is counted as
    junk so the caller can refuse to call that week empty. Every date is
    parsed HERE, before the caller caches anything, because a bad date that
    reached the cache would abort every render for as long as it lived."""
    if type(d) != "dict":
        return None
    items = d.get("items", None)
    if type(items) != "list":
        return None

    out = []
    junk = 0
    for ev in items:
        if type(ev) != "dict":
            junk += 1
            continue
        if ev.get("status", "") == "cancelled":
            continue
        et = ev.get("eventType", "default")
        if type(et) == "string" and et != "default":
            continue
        if is_declined(ev.get("attendees", None)):
            continue
        start = ev.get("start", None)
        if type(start) != "dict":
            junk += 1
            continue
        end = ev.get("end", None)
        if type(end) != "dict":
            end = {}
        sdt = str_or(start.get("dateTime", ""))
        sd = str_or(start.get("date", ""))
        if sdt == "" and sd == "":
            junk += 1
            continue
        title = str_or(ev.get("summary", ""))
        rec = {
            "t": title if title != "" else "(untitled)",
            "s": sdt if sdt != "" else sd,
            "e": str_or(end.get("dateTime", "")) or str_or(end.get("date", "")),
            "a": sdt == "",
        }
        if parse_event(rec, tz) == None:
            junk += 1  # a date time.parse_time would abort on
            continue
        out.append(rec)
    return {"e": out, "junk": junk, "more": safe_token(d.get("nextPageToken", ""))}

def is_declined(atts):
    if type(atts) != "list":
        return False
    for a in atts:
        if type(a) == "dict" and a.get("self", False) and a.get("responseStatus", "") == "declined":
            return True
    return False

def str_or(v):
    return v if type(v) == "string" else ""

# ------------------------------------------------------------- date plumbing

def days_in_month(y, m):
    if m == 2:
        return 29 if (y % 4 == 0 and y % 100 != 0) or y % 400 == 0 else 28
    if m == 4 or m == 6 or m == 9 or m == 11:
        return 30
    return 31

def is_day(s):
    """A real yyyy-mm-dd. Shape alone is not enough: time.parse_time rejects
    2026-09-31 and 2027-02-30 with an abort, so the calendar is checked too."""
    if len(s) != 10 or s[4] != "-" or s[7] != "-":
        return False
    y = to_int(s[0:4])
    m = to_int(s[5:7])
    d = to_int(s[8:10])
    if y < 1 or m < 1 or m > 12 or d < 1:
        return False
    return d <= days_in_month(y, m)

def is_moment(s):
    """A real RFC3339 instant, optional fractional seconds, Z or +hh:mm."""
    if len(s) < 20 or s[10] != "T" or s[13] != ":" or s[16] != ":":
        return False
    if not is_day(s[0:10]):
        return False
    h = to_int(s[11:13])
    mi = to_int(s[14:16])
    sec = to_int(s[17:19])
    if h < 0 or h > 23 or mi < 0 or mi > 59 or sec < 0 or sec > 59:
        return False

    tail = s[19:]
    if tail.startswith("."):
        k = 1
        for ch in tail[1:].elems():
            if DIGITS.find(ch) < 0:
                break
            k += 1
        if k == 1:
            return False  # a lone "." with no digits
        tail = tail[k:]

    if tail == "Z":
        return True
    if len(tail) != 6 or (tail[0] != "+" and tail[0] != "-") or tail[3] != ":":
        return False
    oh = to_int(tail[1:3])
    om = to_int(tail[4:6])
    return oh >= 0 and oh <= 23 and om >= 0 and om <= 59

def parse_event(ev, tz):
    """Trimmed extract -> {t, a, st, en} (timed) or {t, a, st, sd, ed}
    (all-day), or None when a date will not parse. The validators above are
    what make the time.parse_time calls here safe: an out-of-range date
    aborts the whole render, uncatchably."""
    title = str_or(ev.get("t", ""))
    s = str_or(ev.get("s", ""))
    e = str_or(ev.get("e", ""))
    if ev.get("a", False) == True:
        if not is_day(s):
            return None
        st = time.parse_time(s, format = DAY_FMT, location = tz)
        if not is_day(e):
            # End missing: treat as one day (the end date is exclusive).
            e = (st + time.parse_duration("24h")).format(DAY_FMT)
        return {"t": title, "a": True, "st": st, "sd": s, "ed": e}
    if not is_moment(s):
        return None
    st = time.parse_time(s).in_location(tz)
    en = time.parse_time(e).in_location(tz) if is_moment(e) else st + time.parse_duration("30m")
    return {"t": title, "a": False, "st": st, "en": en}

# ------------------------------------------------------------- event picking

def parse_events(evs, now, tz):
    """Cached extracts back into moments, dropping anything already over -
    stale cache can hold finished events."""
    out = []
    today = now.format(DAY_FMT)
    for ev in evs:
        if type(ev) != "dict":
            continue
        p = parse_event(ev, tz)
        if p == None:
            continue
        if p["a"]:
            if p["ed"] <= today:  # ISO dates compare lexically; end is exclusive
                continue
        elif p["en"].unix <= now.unix:
            continue
        out.append(p)
    return out

def render_events(rec, now, tz):
    parsed = parse_events(rec["e"], now, tz)
    today = now.format(DAY_FMT)

    # Whether the fetch actually finished the week, carried down to the square
    # agenda: only a complete reading may end its list with "nothing else".
    whole = rec["c"]

    # The loops below carry an index because a square panel's card lists what
    # comes AFTER the one it picked, and the list is start-ordered: everything
    # past the winning index is exactly "what follows". Wide panels ignore it.

    # 1. A timed event in progress right now. The badge shows today, not the
    # day it started: a shift or a conference that began on Monday still
    # means "now" on Wednesday.
    for i in range(len(parsed)):
        ev = parsed[i]
        if not ev["a"] and ev["st"].unix <= now.unix:
            return card(now, ev["t"], "NOW", GREEN, until_line(ev["en"], now), tail(parsed, i, now), whole)

    # 2. A timed event starting within the hour. Deliberately NOT gated on
    # the calendar date: at 23:30 the next event is usually tomorrow, and it
    # still deserves the countdown (and the red <=5 min warning).
    for i in range(len(parsed)):
        ev = parsed[i]
        if ev["a"]:
            continue
        mins = (ev["st"].unix - now.unix) // 60
        if mins < 60:
            if mins < 1:
                mins = 1
            color = RED if mins <= 5 else AMBER
            return card(ev["st"], ev["t"], "in " + str(mins) + " min", color, ev["st"].format("3:04 PM"), tail(parsed, i, now), whole)

    # 3. A later timed event still on today's date.
    for i in range(len(parsed)):
        ev = parsed[i]
        if not ev["a"] and ev["st"].format(DAY_FMT) == today:
            return card(ev["st"], ev["t"], ev["st"].format("3:04 PM"), WHITE, "", tail(parsed, i, now), whole)

    # 4. An all-day event covering today. The badge shows today for the same
    # reason as state 1: a holiday week that started on Saturday is on now.
    for i in range(len(parsed)):
        ev = parsed[i]
        if ev["a"] and ev["sd"] <= today and today < ev["ed"]:
            return card(now, ev["t"], "All day", AMBER, "", tail(parsed, i, now), whole)

    # 5. The earliest upcoming event within the week (list is start-ordered).
    # Weekday alone on the when-line: "Wednesday" is 36px, always static,
    # where "Wed 12:45PM" is 44px and would jiggle inside a 43px marquee.
    # The clock time goes on the dim third line instead.
    for i in range(len(parsed)):
        ev = parsed[i]
        if ev["st"].unix > now.unix and ev["st"].unix - now.unix < WINDOW:
            when = when_label(ev["st"], now)
            if ev["a"]:
                return card(ev["st"], ev["t"], when, WHITE, "all day", tail(parsed, i, now), whole)
            return card(ev["st"], ev["t"], when, WHITE, ev["st"].format("3:04 PM"), tail(parsed, i, now), whole)

    # 6. Nothing survived. Only claim an empty week when the reading actually
    # said so - a page we could not finish reading is not "All clear".
    if rec["u"]:
        return card(now, "Google Calendar", "unknown", GREY, "too many to scan")
    return card(now, "All clear", "no events", GREEN, "next 7 days")

def until_line(en, now):
    """The NOW card's dim line. Something finishing today gets a bare clock
    time with AM/PM; anything running past midnight is named by weekday too,
    because a lone "til 3:45" on a three-day event reads as this afternoon."""
    if en.format(DAY_FMT) == now.format(DAY_FMT):
        return "til " + en.format("3:04PM")
    return "til " + en.format("Mon 3:04PM")

def when_label(st, now):
    """A bare weekday name collides with today's once the preview reaches a
    week out - "Wednesday" rendered on a Wednesday reads as today."""
    if st.format("Monday") == now.format("Monday"):
        return "Next " + st.format("Mon")
    return st.format("Monday")

def tail(parsed, i, now):
    """What follows the event on the card: the next MAX_LIST events, already
    labelled for the square panel's agenda list. Built here rather than in the
    drawing code because this is the only place `now` meets the ordered list.

    An event that has already begun is skipped whatever its index: the card
    above is the one that is on now, and a second thing running concurrently
    is not "up next"."""
    out = []
    for p in parsed[i + 1:]:
        if p["st"].unix <= now.unix:
            continue
        out.append({"w": short_when(p["st"], p["a"], now), "t": p["t"]})
        if len(out) == MAX_LIST:
            break
    return out

def short_when(st, all_day, now):
    """At most 6 characters, which is exactly the list's 24px label column: a
    clock time for something today, the weekday for any other day. The exact
    minute of a Thursday meeting is not what a glance is for - the hero card
    above carries the precise wording for the event that is actually next."""
    if st.format(DAY_FMT) != now.format(DAY_FMT):
        return st.format("Mon")
    if all_day:
        return "today"
    return st.format("3:04") + ("p" if st.format("PM") == "PM" else "a")

# ------------------------------------------------------------------- drawing

def card(icon_t, title, when, when_color, dim, rest = None, whole = False):
    """Calendar icon left, title marquee + when-line right. Every text row is
    capped at 43px by its own Marquee, so nothing can collide with the icon.

    `rest` is what follows this event, for square panels only; None marks a
    card that is not about an event at all (setup, offline, All clear).
    `whole` says whether the fetch read the entire week, which is what lets a
    square agenda end its list with a claim; wide ignores both."""
    if is_square():
        return square_card(icon_t, title, when, when_color, dim, rest, whole)
    rows = [
        render.Marquee(width = 43, child = render.Text(title, font = "tom-thumb", color = WHITE)),
        render.Box(width = 1, height = 3),
        render.Marquee(width = 43, child = render.Text(when, font = "tom-thumb", color = when_color)),
    ]
    if dim != "":
        rows.append(render.Box(width = 1, height = 2))
        rows.append(render.Marquee(width = 43, child = render.Text(dim, font = "tom-thumb", color = GREY)))
    return render.Root(
        child = render.Row(
            children = [
                render.Box(width = 19, height = 32, child = cal_icon(icon_t)),
                render.Box(
                    width = 45,
                    height = 32,
                    child = render.Padding(pad = (1, 0, 1, 0), child = render.Column(children = rows)),
                ),
            ],
        ),
    )

def cal_icon(t):
    """A page-a-day calendar: red month banner over the day number."""
    return render.Column(
        children = [
            render.Box(
                width = 17,
                height = 8,
                color = BANNER,
                child = render.Text(t.format("Jan").upper(), font = "tom-thumb", color = WHITE),
            ),
            render.Box(
                width = 17,
                height = 12,
                color = PAPER,
                child = render.Text(t.format("2"), font = "tb-8", color = INKDARK),
            ),
        ],
    )

# ----------------------------------------------------- square (64x64) layout

def is_square():
    # Branch on canvas SHAPE, not size: a 2x wide panel reports 128x64 and a
    # 2x square one 128x128, so a bare height test gets one of them wrong.
    w, h = canvas.size()
    return h * 2 > w + 16

def square_card(icon_t, title, when, when_color, dim, rest, whole):
    """The square panel is not the wide card with room underneath - that is
    the thing it is here to stop doing.

    A card about an event becomes an agenda. The wide card answers "what is
    next"; the second half of a square answers the question a glance asks
    immediately afterwards, "and then?", from events the app already fetched
    and cached but had nowhere to put. Hero on top, a hairline, then the next
    few, one compact row each.

    A card about nothing in particular - the setup prompt, an outage, All
    clear - has no agenda to draw, so it becomes a poster instead: the badge
    centred over its message, with the whole 64px width to say it in rather
    than the 43px the icon leaves beside it on the wide panel."""
    if rest == None:
        return render.Root(child = square_poster(icon_t, title, when, when_color, dim))
    return render.Root(
        child = render.Column(
            children = [
                square_hero(icon_t, title, when, when_color, dim),
                render.Box(width = 64, height = 2),
                render.Box(width = 64, height = 1, color = RULE),
                render.Box(width = 64, height = 3),
                square_agenda(rest, whole),
            ],
        ),
    )

def square_hero(icon_t, title, when, when_color, dim):
    """The wide card's own composition - badge left, title over when-line
    right - drawn at the size a square has room for. Same colours, same font,
    same order; the badge grows and the marquees lose 3px to it."""
    rows = [
        render.Marquee(width = 41, child = render.Text(title, font = "tom-thumb", color = WHITE)),
        render.Box(width = 1, height = 3),
        render.Marquee(width = 41, child = render.Text(when, font = "tom-thumb", color = when_color)),
    ]
    if dim != "":
        rows.append(render.Box(width = 1, height = 2))
        rows.append(render.Marquee(width = 41, child = render.Text(dim, font = "tom-thumb", color = GREY)))
    return render.Row(
        children = [
            render.Box(width = 22, height = 31, child = big_cal_icon(icon_t)),
            render.Box(
                width = 42,
                height = 31,
                child = render.Padding(pad = (1, 0, 0, 0), child = render.Column(children = rows)),
            ),
        ],
    )

def square_agenda(rest, whole):
    """The bottom 27 rows: up to MAX_LIST rows of "when | what", spread evenly
    so a short list sits balanced in the band instead of clinging to the rule
    with a hole under it.

    A short list ends with a line saying what it is, because a reading is worth
    more panel than the black it would otherwise be - but WHICH line depends on
    how far the fetch got. fetch_events stops following pages the moment one
    event survives the declined filter, so a calendar whose first page is
    almost all declined can leave real events unread. "nothing else this week"
    is a claim about the week and is only earned when `whole` says every page
    was read; otherwise the list says what is true of the app instead."""
    rows = [square_row(ev) for ev in rest]
    if len(rest) < MAX_LIST:
        if not whole:
            rows.append(centred("more unread", GREY))
        else:
            rows.append(centred("nothing else", GREY))
            if len(rest) == 0:
                rows.append(centred("this week", GREY))
    return render.Box(
        width = 64,
        height = 27,
        child = render.Column(children = rows, main_align = "space_evenly", cross_align = "center"),
    )

def square_row(ev):
    """One agenda line: the when in 24px (six tom-thumb cells, which is every
    label short_when can produce), then the title. Both halves are Marquees
    for the same reason every row on the wide card is - a width a widget
    cannot exceed is what keeps a 170-character meeting title out of its
    neighbour."""
    return render.Padding(
        pad = (1, 0, 0, 0),
        child = render.Row(
            children = [
                render.Marquee(width = 24, child = render.Text(ev["w"], font = "tom-thumb", color = GREY)),
                render.Box(width = 3, height = 1),
                render.Marquee(width = 36, child = render.Text(ev["t"], font = "tom-thumb", color = WHITE)),
            ],
        ),
    )

def square_poster(icon_t, title, when, when_color, dim):
    """Badge over message, centred on the whole panel.

    The Box is not decoration: main_align only has something to align inside
    a bounded height, and a Column handed straight to render.Root has none -
    it draws from y=0 and the poster hangs off the top edge with a third of
    the panel black beneath it. square_agenda is bounded the same way."""
    children = [
        big_cal_icon(icon_t),
        render.Box(width = 1, height = 5),
        centred(title, WHITE),
        render.Box(width = 1, height = 3),
        centred(when, when_color),
    ]
    if dim != "":
        children.append(render.Box(width = 1, height = 2))
        children.append(centred(dim, GREY))
    return render.Box(
        width = 64,
        height = 64,
        child = render.Column(children = children, main_align = "center", cross_align = "center"),
    )

def centred(s, color):
    """Centred across the panel when it fits, marqueed when it does not.
    tom-thumb is a 4px monospace cell, so the width is countable - and len()
    counts BYTES, so a multibyte title only ever over-counts and falls to the
    marquee, which is the harmless side to be wrong on."""
    t = render.Text(s, font = "tom-thumb", color = color)
    if len(s) * 4 <= 62:
        return render.Row(children = [t], expanded = True, main_align = "center")
    return render.Marquee(width = 64, child = t)

def big_cal_icon(t):
    """The wide card's page-a-day badge at the size a square affords: the day
    number goes from an 8px font to a 13px one, the banner from 17px to 21px
    wide. Same red, same paper, same shape."""
    return render.Column(
        children = [
            render.Box(
                width = 21,
                height = 9,
                color = BANNER,
                child = render.Text(t.format("Jan").upper(), font = "tom-thumb", color = WHITE),
            ),
            render.Box(
                width = 21,
                height = 16,
                color = PAPER,
                child = render.Text(t.format("2"), font = "6x13", color = INKDARK),
            ),
        ],
    )

# -------------------------------------------------------------------- schema

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "client_id",
                name = "Google OAuth Client ID",
                desc = "From your Google Cloud OAuth client. Not needed on a tronbyt server with a Google connection.",
                icon = "key",
            ),
            schema.Text(
                id = "client_secret",
                name = "Google OAuth Client Secret",
                desc = "From the same Google Cloud OAuth client.",
                icon = "lock",
            ),
            schema.Text(
                id = "refresh_token",
                name = "Refresh Token",
                desc = "Minted once via the OAuth playground or a loopback flow, with the calendar.events.readonly scope.",
                icon = "rotate",
            ),
        ],
    )
