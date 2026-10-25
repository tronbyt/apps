"""
Applet: NBA Play By Play
Summary: Follow your NBA team live
Description: Live game state for your NBA team, sibling of NFL Play By Play.
Author: nsluke

Four states, mirroring the NFL app:
  idle    - logo, record, and a team-color marquee scrolling division standings
  pregame - tipoff time beside side-by-side team panels, records on the
            marquee strip (game day only)
  live    - quarter + clock, last play scrolling below, score on team-color
            bands; HALF / END Q3 variants during stoppages
  final   - FIN (or F/OT) beside the score bands, for 24h after tipoff

On a 64x64 panel the same four states get a square layout: the two team
bands stack as full-width tiles over a state band that gives the last-play
marquee the whole width, and idle shows the division standing still as a
table instead of scrolling it past a 7px strip.

Data: ESPN's public scoreboard + standings JSON (no key). Basketball field
notes, all from live probes (see NOTES.md): the undated scoreboard returns
the NEXT scheduled game through the whole offseason, so "pre" only renders
on game day. There is no possession/down data like football; the in-game
situation carries at most a lastPlay - rendered only when present, never
required. NBA standings entries have no "overall" record stat (unlike NFL);
the record is built from the wins/losses displayValues. period 5+ is OT.
state stays "in" at halftime (STATUS_HALFTIME) and between quarters
(STATUS_END_PERIOD). Postponed/canceled report state "post" without
STATUS_FINAL and must not render as a 0-0 final.
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

API_BASE = "https://site.api.espn.com"
SCOREBOARD_PATH = "/apis/site/v2/sports/basketball/nba/scoreboard"
STANDINGS_PATH = "/apis/v2/sports/basketball/nba/standings?level=3"

FRESH_LIVE = 10  # live game: re-poll every 10s (ESPN serves max-age=2)
FRESH_IDLE = 600  # no live game: every 10 min
RETRY_TTL = 60  # back off after a failure
STALE_TTL = 21600  # serve last good extract up to 6h through an outage
STANDINGS_TTL = 3600
LOGO_TTL = 86400

WHITE = "#FFFFFF"
GREY = "#9C9C9C"
DARKGREY = "#4A4A4A"
AMBER = "#FFA33A"

TEAMS = {
    "ATL": "Atlanta Hawks",
    "BKN": "Brooklyn Nets",
    "BOS": "Boston Celtics",
    "CHA": "Charlotte Hornets",
    "CHI": "Chicago Bulls",
    "CLE": "Cleveland Cavaliers",
    "DAL": "Dallas Mavericks",
    "DEN": "Denver Nuggets",
    "DET": "Detroit Pistons",
    "GS": "Golden State Warriors",
    "HOU": "Houston Rockets",
    "IND": "Indiana Pacers",
    "LAC": "LA Clippers",
    "LAL": "Los Angeles Lakers",
    "MEM": "Memphis Grizzlies",
    "MIA": "Miami Heat",
    "MIL": "Milwaukee Bucks",
    "MIN": "Minnesota Timberwolves",
    "NO": "New Orleans Pelicans",
    "NY": "New York Knicks",
    "OKC": "Oklahoma City Thunder",
    "ORL": "Orlando Magic",
    "PHI": "Philadelphia 76ers",
    "PHX": "Phoenix Suns",
    "POR": "Portland Trail Blazers",
    "SA": "San Antonio Spurs",
    "SAC": "Sacramento Kings",
    "TOR": "Toronto Raptors",
    "UTAH": "Utah Jazz",
    "WSH": "Washington Wizards",
}

# ESPN's primary for the Warriors is their yellow, which reads as a warning
# light at panel brightness; the community nbascores app swaps in their blue
# and it looks right, so borrow that. Pure black/white primaries (BKN, SA)
# are lifted to charcoal by team_color's guard instead.
ALT_COLOR = {
    "GS": "#1D428A",
}

def main(config):
    team = config.str("team", "NY")
    tz = config.get("$tz") or "America/New_York"
    base = config.str("api", API_BASE)  # test hook: point at a local stub

    game = get_game(team, base)
    now = time.now().in_location(tz)

    if game != None:
        if game["state"] == "in":
            # Live doesn't need the tipoff time at all, so render it before
            # touching the date - a live event missing its date still shows.
            return render.Root(child = live_view(game, final = False))
        if valid_espn_date(game["date"]):
            # An event with a missing/null/unreadable date (never live-observed)
            # falls through to idle instead of aborting inside parse_time.
            tip = time.parse_time(game["date"], format = "2006-01-02T15:04Z").in_location(tz)
            if game["state"] == "post" and game["status_name"] == "STATUS_FINAL":
                # Genuinely final (postponed/canceled also report state "post" -
                # those fall through to idle rather than faking a 0-0 final).
                # Show the final for a day, then fall back to idle.
                if now - tip < time.parse_duration("24h"):
                    return render.Root(child = live_view(game, final = True))
            if game["state"] == "pre" and same_day(tip, now):
                return pregame_root(game, team, tip, base)

    if config.bool("gameday_only", False):
        return []
    return idle_root(team, base)

def same_day(a, b):
    return a.format("2006-01-02") == b.format("2006-01-02")

MONTH_DAYS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

def valid_espn_date(s):
    """Whether time.parse_time can read s with ESPN's layout. parse_time
    aborts the render on a string it can't parse and Starlark cannot recover,
    so validate first: the exact "2026-09-02T14:07Z" shape (verified live) plus
    the calendar ranges Go's parser enforces. Anything else counts as no date."""
    if len(s) != 17:
        return False
    if s[4] != "-" or s[7] != "-" or s[10] != "T" or s[13] != ":" or s[16] != "Z":
        return False
    year, month, day = to_int(s[0:4]), to_int(s[5:7]), to_int(s[8:10])
    hour, minute = to_int(s[11:13]), to_int(s[14:16])
    if year < 0 or month < 1 or month > 12 or day < 1:
        return False
    if hour < 0 or hour > 23 or minute < 0 or minute > 59:
        return False
    last = MONTH_DAYS[month - 1]
    if month == 2 and year % 4 == 0 and (year % 100 != 0 or year % 400 == 0):
        last = 29
    return day <= last

def as_list(x):
    """JSON-null tolerance: ESPN sending a present-but-null (or wrong-typed)
    key must degrade, not abort the render. Same for as_dict below."""
    return x if type(x) == "list" else []

def as_dict(x):
    return x if type(x) == "dict" else {}

# ---------------------------------------------------------------- data layer

def fetch_json(url, gate_key, fresh_ttl):
    """Gate-before-request: a transport error aborts the render and Starlark
    cannot catch it, so the gate key (written before the request) limits the
    damage to one failed render per RETRY_TTL."""
    if cache.get(gate_key) != None:
        return None  # recently fetched or recently failed; caller uses cache
    cache.set(gate_key, "1", ttl_seconds = RETRY_TTL)
    resp = http.get(url, ttl_seconds = RETRY_TTL)
    body = resp.body()
    if resp.status_code != 200:
        print("nba: " + url[:60] + " -> " + str(resp.status_code))
        return None
    if not (body.startswith("{") and body.endswith("}")):
        print("nba: non-JSON body from " + url[:60])
        return None
    cache.set(gate_key, "1", ttl_seconds = fresh_ttl)
    return json.decode(body)

def get_game(team, base):
    """Extract the focus team's event from the scoreboard into a small dict,
    cached so an ESPN outage serves the last good reading."""
    ck = "nbapbp:g:" + team
    d = fetch_json(base + SCOREBOARD_PATH, ck + ":gate", FRESH_LIVE)
    if d == None:
        raw = cache.get(ck)
        if raw == None:
            return None
        g = json.decode(raw)
        return None if "none" in g else g  # no-game marker, not a game

    game = None
    for raw_ev in as_list(d.get("events")):
        ev = as_dict(raw_ev)
        comps = as_list(ev.get("competitions"))
        if len(comps) == 0:
            continue
        comp = as_dict(comps[0])
        sides = [as_dict(s) for s in as_list(comp.get("competitors"))]
        if len(sides) != 2:
            continue
        if team in [as_dict(s.get("team")).get("abbreviation", "") for s in sides]:
            game = extract_game(ev, comp, sides)
            break

    if game == None:
        cache.set(ck, json.encode({"none": True}), ttl_seconds = STALE_TTL)
        cache.set(ck + ":gate", "1", ttl_seconds = FRESH_IDLE)  # offseason: poll slowly
        return None
    cache.set(ck, json.encode(game), ttl_seconds = STALE_TTL)

    # Poll slowly when nothing is live.
    if game["state"] != "in":
        cache.set(ck + ":gate", "1", ttl_seconds = FRESH_IDLE)
    return game

def extract_game(ev, comp, sides):
    status = as_dict(ev.get("status"))
    stype = as_dict(status.get("type"))
    away, home = None, None
    for s in sides:
        if s.get("homeAway") == "home":
            home = s
        else:
            away = s
    if home == None or away == None:
        away, home = sides[0], sides[1]

    return {
        "state": str(stype.get("state") or "pre"),
        "status_name": str(stype.get("name") or ""),
        "detail": str(stype.get("shortDetail") or ""),
        "period": as_period(status.get("period")),
        "clock": str(status.get("displayClock", "") or ""),
        "date": str(ev.get("date", "") or ""),
        "play": last_play(comp),
        "away": extract_team(away),
        "home": extract_team(home),
    }

def as_period(p):
    """status.period as an int. ESPN sends it as a JSON number, but a string
    ("3") has been seen in hostile testing - int() on a non-digit string
    would abort the render, so route strings through to_int."""
    if type(p) == "int":
        return p
    if type(p) == "float":
        return int(p)
    if type(p) == "string":
        n = to_int(p)
        return n if n >= 0 else 0
    return 0

def last_play(comp):
    """situation.lastPlay.text when ESPN sends one; every level is optional
    (absent pre/post, and could not be live-verified in the offseason - the
    layout must read complete without it)."""
    sit = comp.get("situation", None)
    if type(sit) != "dict":
        return ""
    play = sit.get("lastPlay", None)
    if type(play) != "dict":
        return ""
    text = play.get("text", "")
    if type(text) != "string":
        return ""
    return text[0:120]

def extract_team(side):
    t = as_dict(side.get("team"))
    abbr = str(t.get("abbreviation") or "?")
    score = str(side.get("score", "0") or "0")
    record = ""
    for r in as_list(side.get("records")):
        if type(r) == "dict" and r.get("name") == "overall":
            record = str(r.get("summary", "") or "")
    return {
        "id": str(t.get("id") or ""),
        "abbr": abbr,
        "score": score if score != "" else "0",
        "record": record,
        "color": team_color(abbr, t.get("color")),
        "alt": hex_color(t.get("alternateColor"), "ffffff"),
        "logo": str(t.get("logo") or ""),
    }

def hex_color(raw, fallback):
    """ESPN sends colors as bare 6-digit hex with no '#'. Anything else - null,
    a number, a truncated or non-hex string - reaches render.Box as an invalid
    color and aborts the render, so only a real hex triple is passed through."""
    s = str(raw or "").lower()
    if len(s) != 6:
        return "#" + fallback
    for ch in s.elems():
        if "0123456789abcdef".find(ch) < 0:
            return "#" + fallback
    return "#" + s

def team_color(abbr, raw):
    if abbr in ALT_COLOR:
        return ALT_COLOR[abbr]
    c = hex_color(raw, "222222")
    if c in ("#ffffff", "#000000"):
        return "#222222"
    return c

def get_standings(team, base):
    """Division entry list for the focus team + its record, small-cached.
    Two verified divergences from the NFL feed: NBA entries carry no
    "overall" record stat (the W-L is assembled from the wins/losses
    displayValues), and ?level=3 entries arrive UNSORTED (Central came back
    DET, CLE, IND, CHI, MIL), so rank is computed here by win percentage -
    close enough without ESPN's tiebreakers."""
    ck = "nbapbp:s:" + team
    d = fetch_json(base + STANDINGS_PATH, ck + ":gate", STANDINGS_TTL)
    if d == None:
        raw = cache.get(ck)
        return json.decode(raw) if raw != None else None

    out = None
    for conf in as_list(d.get("children")):
        for div in as_list(as_dict(conf).get("children")):
            dd = as_dict(div)
            entries = [as_dict(e) for e in as_list(as_dict(dd.get("standings")).get("entries"))]
            abbrs = [as_dict(e.get("team")).get("abbreviation", "") for e in entries]
            if team not in abbrs:
                continue
            rows = sorted([entry_row(e) for e in entries], key = row_order)
            lines = []
            record = ""
            for i, row in enumerate(rows):
                tok = str(i + 1) + ":" + row["a"]
                if row["rec"] != "":
                    tok += " " + row["rec"]
                lines.append(tok)
                if row["a"] == team:
                    record = row["rec"]
            out = {
                "marquee": "  ".join(lines),
                "record": record,
                "div": str(dd.get("name") or dd.get("abbreviation") or ""),
                # The same ranked division, unjoined: a 64x64 panel has the
                # rows to show the table standing still instead of scrolling
                # it. Wide panels never read this key.
                "rows": [{"a": r["a"], "rec": r["rec"]} for r in rows],
            }
    if out != None:
        cache.set(ck, json.encode(out), ttl_seconds = STALE_TTL)
    return out

def entry_row(e):
    wins, losses = -1, -1
    for stat in as_list(e.get("stats")):
        if type(stat) != "dict":
            continue
        if stat.get("name") == "wins":
            wins = to_int(str(stat.get("displayValue", "") or ""))
        if stat.get("name") == "losses":
            losses = to_int(str(stat.get("displayValue", "") or ""))
    rec = ""
    pct = -1
    if wins >= 0 and losses >= 0:
        rec = str(wins) + "-" + str(losses)
        pct = 10000 * wins // (wins + losses) if wins + losses > 0 else 0
    return {"a": str(as_dict(e.get("team")).get("abbreviation") or "?"), "rec": rec, "pct": pct, "w": wins}

def row_order(row):
    # sorted() is ascending: highest pct first, most wins breaking ties.
    return (-row["pct"], -row["w"])

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

def get_logo(url, abbr):
    """Logo bytes via ESPN's combiner (server-side resize keeps it crisp),
    kept in cache.star so a CDN outage can't abort renders: the un-gated
    http.get path only runs when we have no cached copy AND no recent
    failure. Returns None on failure - callers draw a colored box."""
    ck = "nbapbp:l:" + abbr
    cached = cache.get(ck)
    if cached != None:
        return base64.decode(cached)
    if cache.get(ck + ":gate") != None:
        return None  # recent failure; don't risk an aborting fetch every render
    cache.set(ck + ":gate", "1", ttl_seconds = RETRY_TTL)

    if url == "":
        url = "https://a.espncdn.com/i/teamlogos/nba/500/scoreboard/" + abbr.lower() + ".png"
    dark = url.replace("/500/scoreboard", "/500-dark/scoreboard").replace("a.espncdn.com/", "a.espncdn.com/combiner/i?img=/")
    dark = dark + "&h=50&w=50"
    resp = http.get(dark, ttl_seconds = LOGO_TTL)
    if resp.status_code != 200 or len(resp.body()) < 100:
        print("nba: logo fetch failed for " + abbr)
        return None
    cache.set(ck, base64.encode(resp.body()), ttl_seconds = LOGO_TTL * 7)
    return resp.body()

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
    p = game["period"]
    if p >= 1 and p <= 4:
        return "Q" + str(p)
    if p == 5:
        return "OT"
    if p > 5:
        return str(p - 4) + "OT"
    return ""

def logo_cell(team, size):
    body = get_logo(team["logo"], team["abbr"])
    if body != None:
        return render.Box(width = size, height = size, child = render.Image(src = body, width = size, height = size))
    return render.Box(
        width = size,
        height = size,
        color = team["color"],
        child = render.Text(team["abbr"][0:1], font = "tom-thumb", color = text_on(team["color"])),
    )

# --------------------------------------------------- square (64x64) layouts

def is_square():
    # Branch on canvas SHAPE, not size: a 2x wide panel reports 128x64 and a
    # 2x square one 128x128, so a bare height test gets both wrong.
    w, h = canvas.size()
    return h * 2 > w + 16

def square_cell(width, text, color):
    """Left-aligned fixed-width cell, for the division table's columns."""
    return render.Box(
        width = width,
        height = 6,
        child = render.Row(
            expanded = True,
            main_align = "start",
            cross_align = "center",
            children = [render.Text(text, font = "tom-thumb", color = color)],
        ),
    )

def square_tile(team, logo_px, abbr_color, right):
    """Full-width 64x21 team tile: logo, abbrev, one number on the right.

    The wide band is 36px of a shared row, so its abbrev and score have to
    stack in a 20px column beside a 14px logo. Here the tile owns the whole
    width and they read straight across, both a font larger. Same team-color
    ground, same accent-on-band rule, same white number.

    The widths are budgeted for the worst real payload, measured in these
    fonts: 60px of padded tile less the logo and a 3px gutter leaves the
    abbrev ("UTAH", the league's only 4-char code, 18px in tb-8) beside a
    3-digit score (18px in 6x13) or a 5-char record ("62-20", 20px in
    tom-thumb) with clear air between them - which is why the pregame tile
    spends 2px of crest that the live tile keeps.

    Both halves of that budget are enforced rather than assumed, because
    space_between alone degrades badly: it hands the leftovers to the gap, so
    an abbrev even a few px over budget takes the gap to zero and welds the
    letters to the digits. So the abbrev gets a fixed 20px cell (clipped, not
    overflowing - tb-8 is proportional, so a character count can't bound a
    width: UTAH is 18px but four Ws are 23px) and the number a 3px left pad.
    Worst case is then exactly 60px with either number, so the number is
    never the thing that gives - and with real payloads both are pure slack
    absorbed from what was already blank, so nothing moves."""
    return render.Box(
        width = 64,
        height = 21,
        color = team["color"],
        child = render.Padding(
            pad = (2, 0, 2, 0),
            child = render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Row(
                        cross_align = "center",
                        children = [
                            logo_cell(team, logo_px),
                            render.Box(width = 3, height = 1),
                            render.Box(
                                width = 20,
                                height = 10,  # tb-8's own line box; a shorter one would crop the glyphs
                                child = render.Row(
                                    expanded = True,
                                    main_align = "start",
                                    cross_align = "center",
                                    children = [render.Text(team["abbr"][0:4], font = "tb-8", color = abbr_color)],
                                ),
                            ),
                        ],
                    ),
                    render.Padding(pad = (3, 0, 0, 0), child = right),
                ],
            ),
        ),
    )

def square_status(game, final):
    """The state line under the two tiles: quarter beside the clock (a real
    scoreboard reads across, and the square has the width for it), or FIN /
    HALF / END Qn. The last play scrolls below it at the full panel width -
    the wide layout can only give that marquee a 25px slot."""
    if final:
        fin = "FIN"
        if game["period"] > 4:
            fin = "F/OT"
        head = [render.Text(fin, font = "tb-8", color = WHITE)]
    elif game["status_name"] == "STATUS_HALFTIME":
        head = [render.Text("HALF", font = "tb-8", color = WHITE)]
    elif game["status_name"] == "STATUS_END_PERIOD":
        head = [
            render.Text(quarter_label(game), font = "tom-thumb", color = GREY),
            render.Box(width = 3, height = 1),
            render.Text("END", font = "tb-8", color = WHITE),
        ]
    elif quarter_label(game) == "" and game["clock"] == "":
        head = [render.Text("LIVE", font = "tb-8", color = WHITE)]
    else:
        head = [
            render.Text(quarter_label(game), font = "tom-thumb", color = GREY),
            render.Box(width = 3, height = 1),
            render.Text(game["clock"][0:5], font = "tb-8", color = WHITE),
        ]

    row = render.Row(children = head, main_align = "center", cross_align = "center")
    if final or game["play"] == "":
        return render.Box(width = 64, height = 21, child = row)
    return render.Box(
        width = 64,
        height = 21,
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                row,
                render.Box(width = 62, height = 3),
                render.Marquee(
                    width = 62,
                    child = render.Text(game["play"], font = "tom-thumb", color = AMBER),
                ),
            ],
        ),
    )

def square_live(game, final):
    """Two stacked score tiles over the state band. The wide layout's 1px
    DARKGREY rule survives the rotation - vertical there, horizontal here."""
    away, home = game["away"], game["home"]
    return render.Column(
        children = [
            square_tile(
                away,
                16,
                accent_on(away["color"], away["alt"]),
                render.Text(away["score"][0:3], font = "6x13", color = WHITE),
            ),
            square_tile(
                home,
                16,
                accent_on(home["color"], home["alt"]),
                render.Text(home["score"][0:3], font = "6x13", color = WHITE),
            ),
            render.Box(width = 64, height = 1, color = DARKGREY),
            square_status(game, final),
        ],
    )

def square_pre_tile(team):
    """Pregame tile: the record replaces the score. On the wide panel a 5-char
    NBA record cannot fit an 18px team panel and has to ride the marquee; a
    full-width tile just prints it."""
    fg = text_on(team["color"])
    rec = team["record"][0:5]
    if rec == "":
        return square_tile(team, 16, fg, render.Box(width = 1, height = 1))
    return square_tile(team, 14, fg, render.Text(rec, font = "tom-thumb", color = fg))

def square_pregame(game, team, tip, base):
    tip_row = render.Row(
        children = [
            render.Text("TIP", font = "tom-thumb", color = GREY),
            render.Box(width = 3, height = 1),
            render.Text(tip.format("3:04"), font = "tb-8", color = WHITE),
        ],
        main_align = "center",
        cross_align = "center",
    )
    children = [
        square_pre_tile(game["away"]),
        square_pre_tile(game["home"]),
        render.Box(width = 64, height = 1, color = DARKGREY),
    ]
    if matchup_line(game) != "":
        children.append(render.Box(width = 64, height = 21, child = tip_row))
    else:
        # No records (preseason/offseason events carry none), so the tiles are
        # bare and the division marquee earns the strip, same as on wide.
        away, home = game["away"], game["home"]
        focus = home if home["abbr"] == team else away
        children.append(render.Box(width = 64, height = 14, child = tip_row))
        children.append(marquee_strip(get_standings(team, base), focus["color"]))
    return render.Root(child = render.Column(children = children), show_full_animation = True)

def square_div_table(rows, team):
    """The whole division, standing still. This is the trade the square makes
    for its extra rows: the wide panel can only scroll these five teams past a
    7px strip, one at a time; here they are all readable at once, focus team
    in the app's amber."""
    lines = []
    for i, raw in enumerate(rows[0:5]):
        # Five rows is the whole division; the dict-normalize is the same
        # habit as every other read in this file - these come back out of
        # cache.star, so treat them as a payload rather than as locals.
        row = as_dict(raw)
        abbr = str(row.get("a") or "?")
        color = AMBER if abbr == team else WHITE
        lines.append(render.Row(
            children = [
                render.Box(width = 2, height = 6),
                square_cell(9, str(i + 1), GREY),
                square_cell(21, abbr[0:4], color),
                square_cell(30, str(row.get("rec") or "")[0:7], GREY),
            ],
            main_align = "start",
            cross_align = "center",
        ))
    return render.Box(
        width = 64,
        height = 31,
        # Centered, not top-aligned: a full division fills the box either way,
        # but a mangled feed with two rows sits in the middle of the block
        # instead of hanging off the strip above a black third.
        child = render.Column(children = lines, main_align = "center", cross_align = "start"),
    )

def square_idle(team, base):
    st = get_standings(team, base)
    color = team_idle_color(team, base)
    logo_url = "https://a.espncdn.com/i/teamlogos/nba/500/scoreboard/" + team.lower() + ".png"
    fake = {"abbr": team, "color": "#222222", "alt": WHITE, "logo": logo_url, "id": "", "score": ""}
    record = st["record"] if st != None else ""
    rows = as_list(st.get("rows")) if st != None else []

    if len(rows) == 0:
        # Nothing to table (an outage, or standings ESPN mangled): don't leave
        # a black half under the crest. The logo goes up to 36px with the name
        # stacked beneath it - a square crest for a square panel - and the
        # scrolling strip the wide panel would have shown stays put.
        return render.Root(
            child = render.Column(
                children = [
                    render.Box(
                        width = 64,
                        height = 57,
                        child = render.Column(
                            main_align = "center",
                            cross_align = "center",
                            children = [
                                logo_cell(fake, 36),
                                render.Box(width = 1, height = 2),
                                render.Text(team, font = "tb-8", color = GREY),
                                render.Text(record, font = "tom-thumb", color = WHITE),
                            ],
                        ),
                    ),
                    marquee_strip(st, color),
                ],
            ),
            show_full_animation = True,
        )
    return render.Root(
        child = render.Column(
            children = [
                square_crest(fake, team, record, 25, 24),
                render.Box(
                    width = 64,
                    height = 8,
                    color = color,
                    child = render.Padding(
                        pad = (2, 0, 0, 0),
                        child = render.Row(
                            expanded = True,
                            main_align = "start",
                            cross_align = "center",
                            children = [render.Text(
                                str(st.get("div", ""))[0:14],
                                font = "tom-thumb",
                                color = text_on(color),
                            )],
                        ),
                    ),
                ),
                square_div_table(rows, team),
            ],
        ),
        show_full_animation = True,
    )

def square_crest(fake, team, record, height, size):
    return render.Box(
        width = 64,
        height = height,
        child = render.Row(
            main_align = "center",
            cross_align = "center",
            children = [
                logo_cell(fake, size),
                render.Box(width = 4, height = 1),
                render.Column(
                    cross_align = "center",
                    children = [
                        render.Text(team, font = "tb-8", color = GREY),
                        render.Text(record, font = "tom-thumb", color = WHITE),
                    ],
                ),
            ],
        ),
    )

# ------------------------------------------------------------------- states

def live_view(game, final):
    if is_square():
        return square_live(game, final)

    left = []
    if final:
        fin = "FIN"
        if game["period"] > 4:
            fin = "F/OT"
        left = [render.Text(fin, font = "tb-8", color = WHITE)]
    elif game["status_name"] == "STATUS_HALFTIME":
        left = [render.Text("HALF", font = "tb-8", color = WHITE)]
    elif game["status_name"] == "STATUS_END_PERIOD":
        left = [
            render.Text(quarter_label(game), font = "tom-thumb", color = GREY),
            render.Text("END", font = "tb-8", color = WHITE),
        ]
    elif quarter_label(game) == "" and game["clock"] == "":
        # Degenerate in-game payload (period 0, empty clock): say *something*
        # true rather than leaving the whole column blank.
        left = [render.Text("LIVE", font = "tb-8", color = WHITE)]
    else:
        left = [
            render.Text(quarter_label(game), font = "tom-thumb", color = GREY),
            render.Text(game["clock"][0:5], font = "tb-8", color = WHITE),
        ]

    # The last play scrolls under the clock when ESPN sends one - basketball's
    # stand-in for football's down & distance. Optional by design.
    if not final and game["play"] != "":
        left.append(render.Box(width = 27, height = 3))
        left.append(render.Marquee(
            width = 25,
            child = render.Text(game["play"], font = "tom-thumb", color = AMBER),
        ))

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
                    band(game["away"]),
                    band(game["home"]),
                ],
            ),
        ],
    )

def band(team):
    """36x16 team-color band: 14px logo, abbrev in the team accent, score in
    tb-8. No possession/timeout furniture - basketball's scoreboard feed has
    neither, which conveniently also frees the right edge UTAH's four
    tom-thumb chars run into."""
    bg = team["color"]
    return render.Stack(
        children = [
            render.Box(width = 36, height = 16, color = bg),
            render.Padding(
                pad = (1, 1, 0, 0),
                child = render.Row(
                    children = [
                        logo_cell(team, 14),
                        render.Padding(
                            pad = (2, 0, 0, 0),
                            child = render.Column(
                                children = [
                                    render.Text(team["abbr"][0:4], font = "tom-thumb", color = accent_on(bg, team["alt"])),
                                    render.Text(team["score"][0:3], font = "tb-8", color = WHITE),
                                ],
                            ),
                        ),
                    ],
                ),
            ),
        ],
    )

def pregame_root(game, team, tip, base):
    if is_square():
        return square_pregame(game, team, tip, base)

    away, home = game["away"], game["home"]
    panels = render.Row(
        children = [
            pre_panel(away),
            pre_panel(home),
        ],
    )
    left = render.Box(
        width = 27,
        height = 25,
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text("TIP", font = "tom-thumb", color = GREY),
                render.Text(tip.format("3:04"), font = "tb-8", color = WHITE),
            ],
        ),
    )
    focus = home if home["abbr"] == team else away

    # On game day the bottom strip carries the matchup records instead of the
    # division marquee - 5-char NBA records don't fit inside the 18px panels.
    strip_text = matchup_line(game)
    if strip_text == "":
        st = get_standings(team, base)
        body = render.Column(
            children = [
                render.Row(children = [left, render.Box(width = 1, height = 25, color = DARKGREY), panels]),
                marquee_strip(st, focus["color"]),
            ],
        )
    else:
        body = render.Column(
            children = [
                render.Row(children = [left, render.Box(width = 1, height = 25, color = DARKGREY), panels]),
                render.Box(
                    width = 64,
                    height = 7,
                    color = focus["color"],
                    child = render.Marquee(
                        width = 64,
                        child = render.Text(" " + strip_text, font = "tom-thumb", color = text_on(focus["color"])),
                    ),
                ),
            ],
        )
    return render.Root(child = body, show_full_animation = True)

def matchup_line(game):
    """"NY 12-4 @ BOS 11-5" - empty when ESPN omits the records (offseason
    and preseason games carry none; verified live on both)."""
    away, home = game["away"], game["home"]
    if away["record"] == "" or home["record"] == "":
        return ""
    return away["abbr"] + " " + away["record"] + " @ " + home["abbr"] + " " + home["record"]

def pre_panel(team):
    return render.Box(
        width = 18,
        height = 25,
        color = team["color"],
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                logo_cell(team, 14),
                render.Text(team["abbr"][0:4], font = "tom-thumb", color = text_on(team["color"])),
            ],
        ),
    )

def idle_root(team, base):
    if is_square():
        return square_idle(team, base)

    st = get_standings(team, base)
    logo_url = "https://a.espncdn.com/i/teamlogos/nba/500/scoreboard/" + team.lower() + ".png"
    fake = {"abbr": team, "color": "#222222", "alt": WHITE, "logo": logo_url, "id": "", "score": ""}
    record = st["record"] if st != None else ""
    body = render.Column(
        children = [
            render.Box(
                width = 64,
                height = 25,
                child = render.Row(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        logo_cell(fake, 22),
                        render.Box(width = 4, height = 1),
                        render.Column(
                            cross_align = "center",
                            children = [
                                render.Text(team, font = "tb-8", color = GREY),
                                render.Text(record, font = "tom-thumb", color = WHITE),
                            ],
                        ),
                    ],
                ),
            ),
            marquee_strip(st, team_idle_color(team, base)),
        ],
    )
    return render.Root(child = body, show_full_animation = True)

def team_idle_color(team, base):
    """Focus team's primary color for the marquee strip when the team isn't
    on the scoreboard (idle days). One tiny fetch, cached a week."""
    ck = "nbapbp:c:" + team
    cached = cache.get(ck)
    if cached != None:
        return cached
    color = ALT_COLOR.get(team, "#333333")
    d = fetch_json(base + "/apis/site/v2/sports/basketball/nba/teams/" + team, ck + ":gate", LOGO_TTL)
    if d != None:
        color = team_color(team, as_dict(d.get("team")).get("color") or "333333")

        # Only cache what we actually fetched - a failure must not pin the
        # grey fallback for a week (fetch_json's gate handles retry pacing).
        cache.set(ck, color, ttl_seconds = LOGO_TTL * 7)
    return color

def marquee_strip(st, color, height = 7):
    if st == None or st.get("marquee", "") == "":
        return render.Box(width = 64, height = height, color = "#111111")
    return render.Box(
        width = 64,
        height = height,
        color = color,
        child = render.Marquee(
            width = 64,
            child = render.Text(" " + st["marquee"], font = "tom-thumb", color = text_on(color)),
        ),
    )

# -------------------------------------------------------------------- schema

def get_schema():
    options = [schema.Option(display = TEAMS[a], value = a) for a in sorted(TEAMS.keys())]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "team",
                name = "Team",
                desc = "The team to follow.",
                icon = "basketball",
                default = "NY",
                options = options,
            ),
            schema.Toggle(
                id = "gameday_only",
                name = "Game day only",
                desc = "Hide the app entirely on days your team doesn't play.",
                icon = "calendarDay",
                default = False,
            ),
        ],
    )
