"""
Applet: CFB Play By Play
Summary: Follow your CFB team live
Description: Live game state for your college football team, the college
sibling of NFL Play By Play.
Author: nsluke

Four states:
  idle    - logo, rank, record, next game, and an AP Top 10 marquee
  pregame - kickoff time beside team panels with ranks/records (game day only)
  live    - quarter, clock, down & distance, field position, possession,
            timeouts, score on team-color bands
  final   - FIN beside the score bands, ranked matchup tags underneath

Data: ESPN's public college-football scoreboard + rankings JSON (no key).
Field notes from live probing (2026-09-01, week 1):
  - The plain scoreboard is the curated top-25 slate (~25 events, 350KB);
    ?groups=80 is all of FBS (~99 events, 1.5MB). We try the small one first
    and only pull the big one when the team isn't on it, so ranked teams
    (including the default) never pay the 1.5MB decode.
  - competitors[].curatedRank.current is the AP rank; 99 means unranked.
  - competitors[].score is a STRING on some events and an INT on others in
    the same payload. Everything numeric goes through as_int/sc().
  - /teams/{abbrev} resolves to the WRONG team (OSU -> Ohio, not Ohio State);
    only /teams/{numeric id} works, so ids are learned from scoreboard or
    rankings sightings and cached for bye weeks.
  - situation is the same family as NFL: absent pre/post, degenerate
    mid-stoppage (down -1, possession null, stale isRedZone). possession is a
    team ID. Halftime keeps state "in" (status name STATUS_HALFTIME).
  - Team abbreviations run up to 4 chars (UCLA, TULN), one more than NFL, so
    the band geometry differs from the NFL app: 13px logo + 1px pad leaves
    exactly enough for 4 chars + the possession ball clear of the pips
    (4-char names lean on tom-thumb's blank trailing column as the gap;
    shorter ones get an explicit 1px spacer).
    A rank prefix ("14 UCLA" = 27px) can never fit the 19px band, so ranks
    show in the pregame/final/idle states instead of the live bands - always
    as an amber number or "AP14", never "#14": tom-thumb's "#" glyph renders
    as an unreadable blob (checked on-panel).
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

API_BASE = "https://site.api.espn.com"
SB_PATH = "/apis/site/v2/sports/football/college-football/scoreboard"
FBS_QS = "?groups=80"  # all FBS; the bare scoreboard is only the top-25 slate
RANK_PATH = "/apis/site/v2/sports/football/college-football/rankings"
TEAM_PATH = "/apis/site/v2/sports/football/college-football/teams/"

FRESH_LIVE = 10  # live game: re-poll every 10s (ESPN serves max-age=2)
FRESH_IDLE = 600  # no live game: every 10 min
RETRY_TTL = 60  # back off after a failure
STALE_TTL = 21600  # serve last good extract up to 6h through an outage
RANK_TTL = 21600  # AP poll moves weekly; 6h is generous
ID_TTL = 2592000  # abbr -> ESPN team id, 30 days (survives a bye week)
LOGO_TTL = 86400

WHITE = "#FFFFFF"
GREY = "#9C9C9C"
DARKGREY = "#4A4A4A"
AMBER = "#FFA33A"
RED = "#FF3B30"

def main(config):
    team = config.str("team", "OSU").strip().upper()
    if team == "":
        team = "OSU"
    tz = config.get("$tz") or "America/New_York"
    base = config.str("api", API_BASE)  # test hook: point at a local stub
    kp = key_prefix(base)

    game = get_game(team, base, kp)
    now = time.now().in_location(tz)

    if game != None:
        if game["state"] == "in":
            # The live view needs no date at all, so it returns before any
            # date parsing: a malformed ESPN date can never cost us the one
            # view that matters most.
            return render.Root(child = live_view(game, False, kp))
        kick = parse_kick(game["date"], tz)
        if game["state"] == "post" and game["status_name"] == "STATUS_FINAL":
            # Genuinely final (postponed/canceled also report state "post").
            # Show the final for a day, then fall back to idle.
            if kick != None and now - kick < time.parse_duration("24h"):
                return render.Root(child = live_view(game, True, kp))
        if game["state"] == "pre" and kick != None and same_day(kick, now):
            return pregame_root(game, team, kick, kp)

    if config.bool("gameday_only", False):
        return []

    if game != None:
        return idle_root(game, team, now, tz, base, kp)

    info = get_team_info(team, base, kp)
    if info != None:
        return bye_root(info, tz, base, kp)
    return notfound_root(team)

def key_prefix(base):
    # Cache rows must not leak between the real API and a stub override.
    if base == API_BASE:
        return "cfbpbp:"
    return "cfbpbp@stub:"

def same_day(a, b):
    return a.format("2006-01-02") == b.format("2006-01-02")

def parse_kick(date, tz):
    """ESPN dates look like 2026-09-05T16:30Z; anything else returns None
    rather than letting time.parse_time abort the render. Shape checks are
    not enough: parse_time also aborts on all-digit dates with out-of-range
    fields (month 00, hour 99, Sep 31...), so every component is range-
    checked against a real calendar first."""
    if len(date) != 17 or date[10] != "T" or date[16] != "Z":
        return None
    if date[4] != "-" or date[7] != "-" or date[13] != ":":
        return None
    year = to_int(date[0:4])
    month = to_int(date[5:7])
    day = to_int(date[8:10])
    hour = to_int(date[11:13])
    minute = to_int(date[14:16])
    if year < 1 or month < 1 or month > 12:
        return None
    if day < 1 or day > days_in_month(year, month):
        return None
    if hour < 0 or hour > 23 or minute < 0 or minute > 59:
        return None
    return time.parse_time(date, format = "2006-01-02T15:04Z").in_location(tz)

def days_in_month(year, month):
    if month == 2:
        leap = year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)
        return 29 if leap else 28
    if month == 4 or month == 6 or month == 9 or month == 11:
        return 30
    return 31

# ---------------------------------------------------------------- type guards

def s_str(v):
    return v if type(v) == "string" else ""

def as_list(v):
    return v if type(v) == "list" else []

def as_dict(v):
    return v if type(v) == "dict" else {}

def as_int(v, dv):
    t = type(v)
    if t == "int":
        return v
    if t == "float":
        return int(v)
    if t == "string":
        n = to_int(v)
        return n if n >= 0 else dv
    return dv

def to_int(s):
    """Digits-only parse; -1 on anything else. int() would abort the render."""
    digits = "0123456789"
    if s == "":
        return -1
    n = 0
    for ch in s.elems():
        d = digits.find(ch)
        if d < 0:
            return -1
        n = n * 10 + d
    return n

def sc(v):
    """Score: string on some events, int on others in the SAME payload."""
    t = type(v)
    if t == "string":
        return v[0:3] if v != "" else "0"
    if t == "int":
        return str(v)
    if t == "float":
        return str(int(v))
    return "0"

# ---------------------------------------------------------------- data layer

def fetch_json(url, gate_key, fresh_ttl):
    """Gate-before-request: a transport error aborts the render and Starlark
    cannot catch it, so the gate key (written before the request) limits the
    damage to one failed render per RETRY_TTL."""
    if cache.get(gate_key) != None:
        return None  # recently fetched or recently failed; caller uses cache
    cache.set(gate_key, "1", ttl_seconds = RETRY_TTL)
    d = try_fetch_json(url, min(fresh_ttl, RETRY_TTL))
    if d == None:
        return None
    cache.set(gate_key, "1", ttl_seconds = fresh_ttl)
    return d

def try_fetch_json(url, ttl):
    """One un-gated fetch attempt: status + sniff checked, no gate logic.
    Callers must have opened a gate already. ttl feeds pixlet's HTTP-layer
    cache: keep it at or below the caller's re-poll cadence, or a fresh
    gate gets answered with a stale cached body."""
    resp = http.get(url, ttl_seconds = ttl)
    body = resp.body()
    if resp.status_code != 200:
        print("cfbpbp: " + url[:60] + " -> " + str(resp.status_code))
        return None
    if not (body.startswith("{") and body.endswith("}")):
        print("cfbpbp: non-JSON body from " + url[:60])
        return None
    return json.decode(body)

def get_game(team, base, kp):
    """The focus team's event as a small dict, cached so an ESPN outage
    serves the last good reading. Two-tier fetch under ONE gate: the curated
    scoreboard first (350KB), all-FBS (?groups=80, 1.5MB) only on a miss."""
    ck = kp + "g:" + team
    gate = ck + ":gate"
    if cache.get(gate) != None:
        return cached_game(ck)
    cache.set(gate, "1", ttl_seconds = RETRY_TTL)

    # The scoreboard's HTTP ttl matches the fastest re-poll (FRESH_LIVE):
    # during a live game the gate reopens every 10s and must reach ESPN,
    # not a 60s-old cached body. Idle cadence is enforced by the gate.
    d = try_fetch_json(base + SB_PATH, FRESH_LIVE)
    if d == None:
        return cached_game(ck)
    game = find_team(d, team)
    if game == None:
        d = try_fetch_json(base + SB_PATH + FBS_QS, FRESH_LIVE)
        if d == None:
            return cached_game(ck)
        game = find_team(d, team)

    if game == None:
        cache.set(ck, json.encode({"none": True}), ttl_seconds = STALE_TTL)
        cache.set(gate, "1", ttl_seconds = FRESH_IDLE)  # bye week: poll slowly
        return None
    cache.set(ck, json.encode(game), ttl_seconds = STALE_TTL)

    # Remember the ESPN team id: /teams/{abbrev} resolves to the WRONG
    # school, so bye-week lookups need an id learned while the team was
    # on a scoreboard.
    me = focus_side(game, team)
    if me["id"] != "":
        cache.set(kp + "id:" + team, me["id"], ttl_seconds = ID_TTL)

    # Re-arm the gate for the state we just saw: 10s during a live game,
    # 10min otherwise. Without this the gate stays at RETRY_TTL and a live
    # game only refreshes once a minute.
    if game["state"] == "in":
        cache.set(gate, "1", ttl_seconds = FRESH_LIVE)
    else:
        cache.set(gate, "1", ttl_seconds = FRESH_IDLE)
    return game

def cached_game(ck):
    raw = cache.get(ck)
    if raw == None:
        return None
    g = json.decode(raw)
    return None if "none" in g else g  # no-game marker, not a game

def find_team(d, team):
    for ev in as_list(d.get("events", None)):
        ev = as_dict(ev)
        comps = as_list(ev.get("competitions", None))
        if len(comps) == 0:
            continue
        comp = as_dict(comps[0])
        sides = as_list(comp.get("competitors", None))
        if len(sides) != 2:
            continue
        abbrs = [s_str(as_dict(as_dict(s).get("team", None)).get("abbreviation", "")).upper() for s in sides]
        if team in abbrs:
            return extract_game(ev, comp, sides)
    return None

def extract_game(ev, comp, sides):
    status = as_dict(ev.get("status", None))
    stype = as_dict(status.get("type", None))
    away, home = None, None
    for s in sides:
        s = as_dict(s)
        if s.get("homeAway") == "home":
            home = s
        else:
            away = s
    if home == None or away == None:
        away, home = as_dict(sides[0]), as_dict(sides[1])

    game = {
        "state": s_str(stype.get("state", "pre")) or "pre",
        "status_name": s_str(stype.get("name", "")),
        "period": as_int(status.get("period", 0), 0),
        "clock": s_str(status.get("displayClock", ""))[0:5],
        "date": s_str(ev.get("date", "")),
        "away": extract_team(away),
        "home": extract_team(home),
    }

    sit = comp.get("situation", None)
    if type(sit) == "dict" and game["state"] == "in":
        down = as_int(sit.get("down", -1), -1)
        poss = sit.get("possession", None)
        game["sit"] = {
            "down_text": s_str(sit.get("shortDownDistanceText", "")),
            "spot": s_str(sit.get("possessionText", "")),
            "red": bool(sit.get("isRedZone", False)) and down >= 1,
            "poss": s_str(poss) or (str(poss) if type(poss) == "int" else ""),
            "hto": as_int(sit.get("homeTimeouts", 3), 3),
            "ato": as_int(sit.get("awayTimeouts", 3), 3),
            "valid": down >= 1 and poss != None and poss != "",
        }
    return game

def extract_team(side):
    t = as_dict(side.get("team", None))
    tid = t.get("id", "")
    rec = ""
    for r in as_list(side.get("records", None)):
        r = as_dict(r)
        if r.get("type") == "total":
            rec = s_str(r.get("summary", ""))[0:7]
    return {
        "id": s_str(tid) or (str(tid) if type(tid) == "int" else ""),
        "abbr": (s_str(t.get("abbreviation", "")).upper() or "?")[0:4],
        "score": sc(side.get("score", "0")),
        "rank": as_int(as_dict(side.get("curatedRank", None)).get("current", 0), 0),
        "record": rec,
        "color": team_color(t.get("color", None)),
        "alt": "#" + color_hex(t.get("alternateColor", None), "ffffff"),
        "logo": s_str(t.get("logo", "")),
    }

def color_hex(v, dv):
    v = s_str(v).lower()
    if len(v) != 6:
        return dv
    for ch in v.elems():
        if "0123456789abcdef".find(ch) < 0:
            return dv
    return v

def team_color(v):
    c = "#" + color_hex(v, "222222")

    # Near-black and white schemes vanish on the panel; several FCS schools
    # ship color "000000".
    if luminance(c) < 16 or c == "#ffffff":
        return "#222222"
    return c

def ranked(t):
    return t["rank"] >= 1 and t["rank"] <= 25

def focus_side(game, team):
    if game["home"]["abbr"] == team[0:4]:
        return game["home"]
    return game["away"]

def get_rankings(base, kp):
    """AP Top 25 extract: a top-10 marquee string plus an abbr->id map (the
    bye-week id resolver for ranked teams). The raw payload is 645KB, so
    only the extract is cached."""
    ck = kp + "ap"
    d = fetch_json(base + RANK_PATH, ck + ":gate", RANK_TTL)
    if d == None:
        raw = cache.get(ck)
        return json.decode(raw) if raw != None else None

    poll = None
    for r in as_list(d.get("rankings", None)):
        r = as_dict(r)
        if poll == None:
            poll = r
        if s_str(r.get("type", "")) == "ap":
            poll = r
            break
    if poll == None:
        return None

    entries = []
    ids = {}
    for e in as_list(poll.get("ranks", None)):
        e = as_dict(e)
        t = as_dict(e.get("team", None))
        rk = as_int(e.get("current", 0), 0)
        ab = s_str(t.get("abbreviation", "")).upper()[0:4]
        tid = t.get("id", "")
        tid = s_str(tid) or (str(tid) if type(tid) == "int" else "")
        if rk < 1 or rk > 25 or ab == "":
            continue
        entries.append((rk, ab))
        if tid != "":
            ids[ab] = tid
    if len(entries) == 0:
        return None
    entries = sorted(entries, key = lambda p: p[0])
    out = {
        "m": "AP: " + " ".join([str(rk) + " " + ab for rk, ab in entries[0:10]]),
        "ids": ids,
    }

    # Outlive the gate, don't expire with it: the extract must still be here
    # when the RANK_TTL gate reopens, or an outage at that moment costs us
    # the marquee AND the bye-week id map with zero stale-serve headroom.
    cache.set(ck, json.encode(out), ttl_seconds = RANK_TTL + STALE_TTL)
    return out

def get_team_info(team, base, kp):
    """Bye-week fallback via /teams/{id}: record, next game, standing. Needs
    an id from a previous scoreboard sighting or the AP poll; without one
    (unranked team, cold cache) the caller shows the not-found card."""
    tid = cache.get(kp + "id:" + team)
    if tid == None:
        ap = get_rankings(base, kp)
        if ap != None:
            tid = ap["ids"].get(team, None)
    if tid == None:
        return None

    ck = kp + "t:" + team
    d = fetch_json(base + TEAM_PATH + tid, ck + ":gate", FRESH_IDLE)
    if d == None:
        raw = cache.get(ck)
        return json.decode(raw) if raw != None else None

    t = as_dict(d.get("team", None))
    rec = ""
    for it in as_list(as_dict(t.get("record", None)).get("items", None)):
        it = as_dict(it)
        if it.get("type") == "total":
            rec = s_str(it.get("summary", ""))[0:7]

    rank = 0
    next_date = ""
    next_name = ""
    nes = as_list(t.get("nextEvent", None))
    if len(nes) > 0:
        ne = as_dict(nes[0])
        next_date = s_str(ne.get("date", ""))
        next_name = s_str(ne.get("shortName", ""))[0:14]
        comps = as_list(ne.get("competitions", None))
        if len(comps) > 0:
            for c in as_list(as_dict(comps[0]).get("competitors", None)):
                c = as_dict(c)
                cid = as_dict(c.get("team", None)).get("id", "")
                cid = s_str(cid) or (str(cid) if type(cid) == "int" else "")
                if cid == tid:
                    rank = as_int(as_dict(c.get("curatedRank", None)).get("current", 0), 0)

    info = {
        "abbr": (s_str(t.get("abbreviation", "")).upper() or team)[0:4],
        "rank": rank,
        "record": rec,
        "color": team_color(t.get("color", None)),
        "logo": "https://a.espncdn.com/i/teamlogos/ncaa/500/" + tid + ".png",
        "next_date": next_date,
        "next_name": next_name,
        "standing": s_str(t.get("standingSummary", ""))[0:24],
    }
    cache.set(ck, json.encode(info), ttl_seconds = STALE_TTL)
    return info

def get_logo(url, abbr, kp):
    """Logo bytes, resized server-side by ESPN's combiner (the device decodes
    a ~2.5KB 44px PNG instead of a 500px one), kept in cache.star so a CDN
    outage can't abort renders: the http.get only runs when we have no cached
    copy AND no recent failure. Returns None on failure - callers draw a
    colored box."""
    ck = kp + "l:" + abbr
    cached = cache.get(ck)
    if cached != None:
        return base64.decode(cached)
    if cache.get(ck + ":gate") != None:
        return None  # recent failure; don't risk an aborting fetch every render
    if url == "":
        return None
    cache.set(ck + ":gate", "1", ttl_seconds = RETRY_TTL)

    if url.startswith("https://a.espncdn.com/i/"):
        path = url[len("https://a.espncdn.com"):].replace("/teamlogos/ncaa/500/", "/teamlogos/ncaa/500-dark/")
        url = "https://a.espncdn.com/combiner/i?img=" + path + "&h=44&w=44"
    resp = http.get(url, ttl_seconds = LOGO_TTL)
    body = resp.body()
    if resp.status_code != 200 or not is_image(body):
        print("cfbpbp: logo fetch failed for " + abbr)
        return None
    cache.set(ck, base64.encode(body), ttl_seconds = LOGO_TTL * 7)
    return body

def is_image(body):
    """render.Image aborts on undecodable bytes, so sniff the magic first.
    Starlark forbids non-ASCII escapes in literals, so match the printable
    parts of each signature (PNG at byte 1, GIF8 at 0, JFIF/Exif at 6)."""
    if len(body) < 100:
        return False
    if body[1:4] == "PNG" or body[0:4] == "GIF8":
        return True
    return body[6:10] == "JFIF" or body[6:10] == "Exif"

# ------------------------------------------------------------------ helpers

def luminance(color):
    c = color.lstrip("#")
    if len(c) < 6:
        return 0
    v = [hex_byte(c[0:2]), hex_byte(c[2:4]), hex_byte(c[4:6])]
    return (299 * v[0] + 587 * v[1] + 114 * v[2]) // 1000

def hex_byte(s):
    digits = "0123456789abcdef"
    s = s.lower()
    if len(s) != 2 or digits.find(s[0]) < 0 or digits.find(s[1]) < 0:
        return 0
    return digits.find(s[0]) * 16 + digits.find(s[1])

def text_on(bg):
    return "#111111" if luminance(bg) > 150 else WHITE

def accent_on(bg, accent):
    """Team accent color for the abbreviation, unless it vanishes on the band."""
    diff = luminance(accent) - luminance(bg)
    if diff < 0:
        diff = -diff
    if diff < 60:
        return text_on(bg)
    return accent

def quarter_label(game):
    name = game["status_name"]
    p = game["period"]
    if name == "STATUS_HALFTIME":
        return "HALF"
    if p == 1:
        return "1st"
    if p == 2:
        return "2nd"
    if p == 3:
        return "3rd"
    if p == 4:
        return "4th"
    if p == 5:
        return "OT"
    if p > 5:
        return str(p - 4) + "OT"
    return ""

def compact_down(text):
    # "1st & 10" -> "1st&10", "3rd & Goal" -> "3rd&GL": 6 tom-thumb chars
    # is the most the 27px column fits, so hard-cap it.
    t = text.replace(" & ", "&").replace("Goal", "GL")
    return t[0:6]

def compact_spot(text):
    # CFB abbreviations reach 4 chars, so "UCLA 38" (7 chars) overflows the
    # 27px column the way NFL spots never did: drop the space, then cap.
    t = text
    if len(t) > 6:
        t = t.replace(" ", "")
    return t[0:6]

def logo_cell(team, size, kp):
    body = get_logo(team["logo"], team["abbr"], kp)
    if body != None:
        return render.Box(width = size, height = size, child = render.Image(src = body, width = size, height = size))
    return render.Box(
        width = size,
        height = size,
        color = team["color"],
        child = render.Text(team["abbr"][0:1], font = "tom-thumb", color = text_on(team["color"])),
    )

def marquee_strip(text, color, height = 7):
    if text == "":
        return render.Box(width = 64, height = height, color = "#111111")
    return render.Box(
        width = 64,
        height = height,
        color = color,
        child = render.Marquee(
            width = 64,
            child = render.Text(" " + text[0:120], font = "tom-thumb", color = text_on(color)),
        ),
    )

# ------------------------------------------------------------------- states

def live_view(game, final, kp):
    sit = game.get("sit", None)
    left = []
    if final:
        fin = "F/OT" if game["period"] > 4 else "FIN"
        left = [render.Text(fin, font = "tb-8", color = WHITE)]

        # AP tags for the ranked side(s): amber rank + grey abbr, the same
        # idiom as the AP marquee. (tom-thumb's "#" glyph renders as a blob,
        # so no "#N" - verified on-panel.)
        tags = [t for t in [game["away"], game["home"]] if ranked(t)]
        if len(tags) > 0:
            left.append(render.Box(width = 27, height = 3))
        for t in tags:
            left.append(render.Row(children = [
                render.Text(str(t["rank"]), font = "tom-thumb", color = AMBER),
                render.Box(width = 2, height = 1),
                render.Text(t["abbr"], font = "tom-thumb", color = GREY),
            ]))
    elif game["status_name"] == "STATUS_HALFTIME":
        left = [render.Text("HALF", font = "tb-8", color = WHITE)]
    else:
        left = [
            render.Text(quarter_label(game), font = "tom-thumb", color = GREY),
            render.Text(game["clock"], font = "tb-8", color = WHITE),
        ]
        if sit != None and sit["valid"]:
            spot_color = RED if sit["red"] else AMBER
            left.append(render.Box(width = 27, height = 2))
            left.append(render.Text(compact_down(sit["down_text"]), font = "tom-thumb", color = WHITE))
            left.append(render.Text(compact_spot(sit["spot"]), font = "tom-thumb", color = spot_color))

    return render.Row(
        children = [
            render.Box(
                width = 27,
                height = 32,
                child = render.Column(
                    main_align = "center",
                    cross_align = "center",
                    children = left,
                ),
            ),
            render.Box(width = 1, height = 32, color = DARKGREY),
            render.Column(
                children = [
                    band(game["away"], game, sit, False, kp),
                    band(game["home"], game, sit, True, kp),
                ],
            ),
        ],
    )

def band(team, game, sit, is_home, kp):
    """36x16 team-color band. Geometry differs from the NFL app: a 13px logo
    + 1px pad puts the name at x=15. tom-thumb advances 4px/char, so a
    4-char abbr runs to x=31 and its blank trailing column is the only gap
    before the ball (x=31-33); shorter names get an explicit 1px spacer.
    Either way the ball stays clear of the pips at x=34."""
    bg = team["color"]
    has_ball = sit != None and sit["valid"] and sit["poss"] == team["id"]
    touts = -1
    if sit != None and game["state"] == "in":
        touts = sit["hto"] if is_home else sit["ato"]

    name_row = [render.Text(team["abbr"], font = "tom-thumb", color = accent_on(bg, team["alt"]))]
    if has_ball:
        ball_color = RED if sit["red"] else AMBER
        if len(team["abbr"]) < 4:
            # 4-char names already end in a blank 1px advance column; an
            # extra spacer would push the ball into the pip column (UCLA).
            name_row.append(render.Box(width = 1, height = 1))
        name_row.append(render.Box(width = 3, height = 3, color = ball_color))

    pips = []
    if touts >= 0:
        for i in range(3):
            pips.append(render.Box(width = 1, height = 2, color = WHITE if i < touts else "#333333"))
            if i < 2:
                pips.append(render.Box(width = 1, height = 1))

    return render.Stack(
        children = [
            render.Box(width = 36, height = 16, color = bg),
            render.Padding(
                pad = (1, 1, 0, 0),
                child = render.Row(
                    children = [
                        logo_cell(team, 13, kp),
                        render.Padding(
                            pad = (1, 0, 0, 0),
                            child = render.Column(
                                children = [
                                    render.Row(cross_align = "center", children = name_row),
                                    render.Text(team["score"], font = "tb-8", color = WHITE),
                                ],
                            ),
                        ),
                    ],
                ),
            ),
            render.Padding(
                pad = (34, 4, 0, 0),
                child = render.Column(children = pips),
            ),
        ],
    )

def pregame_root(game, team, kick, kp):
    away, home = game["away"], game["home"]
    focus = focus_side(game, team)
    left = render.Box(
        width = 27,
        height = 25,
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text("TODAY", font = "tom-thumb", color = GREY),
                render.Text(kick.format("3:04"), font = "tb-8", color = WHITE),
            ],
        ),
    )
    marq = pre_tag(away) + " @ " + pre_tag(home)
    body = render.Column(
        children = [
            render.Row(children = [
                left,
                render.Box(width = 1, height = 25, color = DARKGREY),
                pre_panel(away, kp),
                pre_panel(home, kp),
            ]),
            marquee_strip(marq, focus["color"]),
        ],
    )
    return render.Root(child = body, show_full_animation = True)

def pre_tag(t):
    tag = "AP" + str(t["rank"]) + " " if ranked(t) else ""
    tag += t["abbr"]
    if t["record"] != "":
        tag += " " + t["record"]
    return tag

def pre_panel(team, kp):
    # 18x25: 12px logo + abbr + rank (or record when unranked).
    bottom = "AP" + str(team["rank"]) if ranked(team) else team["record"]
    return render.Box(
        width = 18,
        height = 25,
        color = team["color"],
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                logo_cell(team, 12, kp),
                render.Text(team["abbr"], font = "tom-thumb", color = text_on(team["color"])),
                render.Text(bottom[0:4], font = "tom-thumb", color = accent_on(team["color"], team["alt"])),
            ],
        ),
    )

def idle_root(game, team, now, tz, base, kp):
    """The team is on the scoreboard but not playing today: identity + record
    + next game, AP Top 10 scrolling underneath."""
    me = focus_side(game, team)
    opp = game["away"] if me == game["home"] else game["home"]
    kick = parse_kick(game["date"], tz)

    line3 = ""
    marq_next = ""
    if game["state"] == "pre" and kick != None and kick > now:
        line3 = ("VS " if me == game["home"] else "AT ") + opp["abbr"]
        marq_next = "NEXT " + kick.format("Mon 1/2 3:04 PM")
    return idle_frame(me, line3, marq_next, base, kp)

def bye_root(info, tz, base, kp):
    """Not on this week's scoreboard at all: /teams/{id} supplies the record
    and next game."""
    kick = parse_kick(info["next_date"], tz)
    line3 = kick.format("Mon 1/2") if kick != None else ""
    marq_next = ""
    if info["next_name"] != "":
        marq_next = "NEXT " + info["next_name"]
        if kick != None:
            marq_next += " " + kick.format("Mon 1/2 3:04 PM")
    if info["standing"] != "":
        marq_next = join_dot(marq_next, info["standing"])
    me = {"abbr": info["abbr"], "rank": info["rank"], "record": info["record"], "color": info["color"], "logo": info["logo"]}
    return idle_frame(me, line3.upper(), marq_next, base, kp)

def join_dot(a, b):
    if a == "" or b == "":
        return a + b
    return a + " - " + b

def idle_frame(me, line3, marq_next, base, kp):
    ap = get_rankings(base, kp)
    marq = join_dot(marq_next, ap.get("m", "") if ap != None else "")

    name_row = []
    if ranked(me):
        name_row.append(render.Text("AP" + str(me["rank"]), font = "tom-thumb", color = AMBER))
        name_row.append(render.Box(width = 2, height = 1))
    name_row.append(render.Text(me["abbr"], font = "tb-8", color = WHITE))

    lines = [
        render.Row(cross_align = "end", children = name_row),
    ]
    if me["record"] != "":
        lines.append(render.Text(me["record"], font = "tom-thumb", color = GREY))
    if line3 != "":
        lines.append(render.Text(line3[0:8], font = "tom-thumb", color = AMBER))

    body = render.Column(
        children = [
            render.Box(
                width = 64,
                height = 25,
                child = render.Row(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        logo_cell(me, 22, kp),
                        render.Box(width = 4, height = 1),
                        render.Column(cross_align = "center", children = lines),
                    ],
                ),
            ),
            marquee_strip(marq, me["color"]),
        ],
    )
    return render.Root(child = body, show_full_animation = True)

def notfound_root(team):
    """Nothing resolved for this abbreviation. Two different causes land here
    - a typo'd team, or a total ESPN outage on a cold cache - so the copy
    offers the fix without asserting the user got it wrong."""
    body = render.Column(
        children = [
            render.Box(
                width = 64,
                height = 25,
                child = render.Row(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Box(
                            width = 18,
                            height = 18,
                            color = "#222222",
                            child = render.Text("?", font = "tb-8", color = AMBER),
                        ),
                        render.Box(width = 4, height = 1),
                        render.Column(
                            cross_align = "center",
                            children = [
                                render.Text(team[0:6], font = "tb-8", color = WHITE),
                                render.Text("NO GAME", font = "tom-thumb", color = GREY),
                            ],
                        ),
                    ],
                ),
            ),
            marquee_strip(
                "No FBS game found for " + team[0:10] + " - check back soon, or set your ESPN abbreviation: OSU MICH BAMA TEX ND UGA ORE",
                "#4A3000",
            ),
        ],
    )
    return render.Root(child = body, show_full_animation = True)

# -------------------------------------------------------------------- schema

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "team",
                name = "Team abbreviation",
                desc = "ESPN abbreviation of the team to follow, e.g. OSU, MICH, BAMA, TEX, ND.",
                icon = "football",
                default = "OSU",
            ),
            schema.Toggle(
                id = "gameday_only",
                name = "Game day only",
                desc = "Hide the app entirely on days your team doesn't play.",
                icon = "calendarDay",
                default = False,
            ),
            # The "api" config key main() reads is a test hook only (the
            # exemplar does the same): deliberately NOT in the schema, so
            # no user can point the app at a dead base and abort renders.
        ],
    )
