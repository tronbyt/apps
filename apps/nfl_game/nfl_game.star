# nfl_game.star
# title: NFL Game (recreation of the original Tidbyt NFL app)
# description: Left = status column (quarter/clock/down, kickoff, or final). Right = team tiles.
# Companion to mlb_game: same fonts, helpers, and ESPN logo handling.

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

# ----------------------- Canvas + fonts ---------------------------------------
# 2x panels (128x64) reuse the 64x32 layout with every dimension doubled.
S = 2 if canvas.is2x() else 1
FONT_SMALL = "6x10" if S == 2 else "CG-pixel-3x5-mono"
FONT_MED = "terminus-16" if S == 2 else "5x8"

WHITE = "#ffffff"
GRAY = "#888888"
DIVIDER = "#444444"

STATUS_W = 24
TILE_W = 39
PRE_AWAY_W = 20
PRE_HOME_W = 19
PRE_TOP_H = 25
STRIP_H = 7

ESPN_NFL = "https://site.api.espn.com/apis/site/v2/sports/football/nfl"
STANDINGS_URL = "https://site.api.espn.com/apis/v2/sports/football/nfl/standings?level=3"
LOGO_URL = "https://a.espncdn.com/combiner/i?img=/i/teamlogos/nfl/500-dark/scoreboard/%s.png&h=%d&w=%d"

# Postponed and canceled games also report state "post"; they never show.
SKIP_STATUS = ["STATUS_POSTPONED", "STATUS_CANCELED", "STATUS_FORFEIT"]

# ----------------------- Teams ------------------------------------------------
# Seeded from ESPN color/alternateColor, then tuned for the LEDs: black or
# washed-out primaries get a dark stand-in, and accents that vanish on the
# primary get the team's next color.
TEAMS = {
    "ARI": {"name": "Arizona Cardinals", "bg": "#a40227", "accent": "#ffb612"},
    "ATL": {"name": "Atlanta Falcons", "bg": "#a71930", "accent": "#a5acaf"},
    "BAL": {"name": "Baltimore Ravens", "bg": "#29126f", "accent": "#c9a227"},
    "BUF": {"name": "Buffalo Bills", "bg": "#00338d", "accent": "#d50a0a"},
    "CAR": {"name": "Carolina Panthers", "bg": "#0085ca", "accent": "#bfc0bf"},
    "CHI": {"name": "Chicago Bears", "bg": "#0b1c3a", "accent": "#e64100"},
    "CIN": {"name": "Cincinnati Bengals", "bg": "#fb4f14", "accent": "#000000"},
    "CLE": {"name": "Cleveland Browns", "bg": "#472a08", "accent": "#ff3c00"},
    "DAL": {"name": "Dallas Cowboys", "bg": "#002a5c", "accent": "#b0b7bc"},
    "DEN": {"name": "Denver Broncos", "bg": "#0a2343", "accent": "#fc4c02"},
    "DET": {"name": "Detroit Lions", "bg": "#0076b6", "accent": "#bbbbbb"},
    "GB": {"name": "Green Bay Packers", "bg": "#204e32", "accent": "#ffb612"},
    "HOU": {"name": "Houston Texans", "bg": "#03202f", "accent": "#eb0028"},
    "IND": {"name": "Indianapolis Colts", "bg": "#003b75", "accent": "#ffffff"},
    "JAX": {"name": "Jacksonville Jaguars", "bg": "#007487", "accent": "#d7a22a"},
    "KC": {"name": "Kansas City Chiefs", "bg": "#e31837", "accent": "#ffb612"},
    "LAC": {"name": "Los Angeles Chargers", "bg": "#0080c6", "accent": "#ffc20e"},
    "LAR": {"name": "Los Angeles Rams", "bg": "#003594", "accent": "#ffd100"},
    "LV": {"name": "Las Vegas Raiders", "bg": "#333333", "accent": "#a5acaf"},
    "MIA": {"name": "Miami Dolphins", "bg": "#008e97", "accent": "#fc4c02"},
    "MIN": {"name": "Minnesota Vikings", "bg": "#4f2683", "accent": "#ffc62f"},
    "NE": {"name": "New England Patriots", "bg": "#002a5c", "accent": "#c60c30"},
    "NO": {"name": "New Orleans Saints", "bg": "#222222", "accent": "#d3bc8d"},
    "NYG": {"name": "New York Giants", "bg": "#003c7f", "accent": "#c9243f"},
    "NYJ": {"name": "New York Jets", "bg": "#115740", "accent": "#ffffff"},
    "PHI": {"name": "Philadelphia Eagles", "bg": "#06424d", "accent": "#a5acaf"},
    "PIT": {"name": "Pittsburgh Steelers", "bg": "#222222", "accent": "#ffb612"},
    "SEA": {"name": "Seattle Seahawks", "bg": "#002244", "accent": "#69be28"},
    "SF": {"name": "San Francisco 49ers", "bg": "#aa0000", "accent": "#b3995d"},
    "TB": {"name": "Tampa Bay Buccaneers", "bg": "#bd1c36", "accent": "#b1babf"},
    "TEN": {"name": "Tennessee Titans", "bg": "#0c2340", "accent": "#4495d2"},
    "WSH": {"name": "Washington Commanders", "bg": "#5a1414", "accent": "#ffb612"},
}

DEFAULT_TEAM = "ARI"

# ----------------------- Tiny helpers -----------------------------------------
def spacer_w(w):
    return render.Box(width = w * S, height = 1)

def spacer_h(h):
    return render.Box(width = 1, height = h * S)

def at(x, y, child):
    return render.Padding(pad = (x * S, y * S, 0, 0), child = child)

def small(text, color = WHITE):
    return render.Text(text, font = FONT_SMALL, color = color)

def med(text, color = WHITE):
    return render.Text(text, font = FONT_MED, color = color)

def centered(w, h, child):
    return render.Box(width = w * S, height = h * S, child = child)

def px(c):
    return render.Box(width = 1, height = 1, color = c)

def sprite_row_palette(pattern, palette):
    pixels = []
    for i in range(len(pattern)):
        ch = pattern[i]
        col = palette.get(ch)
        if col == None:
            col = "#000000"
        pixels.append(px(col))
    return render.Row(children = pixels, main_align = "start", cross_align = "start")

def sprite_palette(rows, palette):
    line_rows = []
    for r in rows:
        line_rows.append(sprite_row_palette(r, palette))
    return render.Column(children = line_rows, main_align = "start", cross_align = "start")

def clamp(v, lo, hi):
    if v < lo:
        return lo
    if v > hi:
        return hi
    return v

# Safe accessors (no exceptions)
def as_str(x, d):
    return x if (x != None and type(x) == "string") else d

def as_int(x, d):
    if x == None:
        return d
    if type(x) == "int":
        return x
    if type(x) == "float":
        return int(x)
    return d

def as_bool(x, d):
    return x if (x != None and type(x) == "bool") else d

def as_dict(x):
    return x if type(x) == "dict" else {}

def as_list(x):
    return x if type(x) == "list" else []

HEX_VAL = {
    "0": 0,
    "1": 1,
    "2": 2,
    "3": 3,
    "4": 4,
    "5": 5,
    "6": 6,
    "7": 7,
    "8": 8,
    "9": 9,
    "a": 10,
    "b": 11,
    "c": 12,
    "d": 13,
    "e": 14,
    "f": 15,
    "A": 10,
    "B": 11,
    "C": 12,
    "D": 13,
    "E": 14,
    "F": 15,
}

HEX_DIGITS = "0123456789abcdef"

def hex_byte(s, start):
    if type(s) != "string" or len(s) < start + 2:
        return 0
    hi = s[start]
    lo = s[start + 1]
    if hi not in HEX_VAL or lo not in HEX_VAL:
        return 0
    return HEX_VAL[hi] * 16 + HEX_VAL[lo]

def hex2(v):
    v = clamp(v, 0, 255)
    return HEX_DIGITS[v // 16] + HEX_DIGITS[v % 16]

def luminance(c):
    if type(c) != "string" or len(c) != 7 or c[0] != "#":
        return 0
    return (hex_byte(c, 1) * 299 + hex_byte(c, 3) * 587 + hex_byte(c, 5) * 114) // 1000

def team_font_color(bg):
    # Weighted luminance for simple contrast selection.
    if luminance(bg) >= 140:
        return "#111111"
    return "#ffffff"

def accent_on(bg, accent):
    # Team accent for the abbreviation, unless it vanishes on the tile. Compare
    # channels, not luminance: red on blue is legible at equal brightness.
    dist = 0
    for i in [1, 3, 5]:
        dist += abs(hex_byte(accent, i) - hex_byte(bg, i))
    if dist < 150:
        return team_font_color(bg)
    return accent

def dim_color(c, pct):
    if type(c) != "string" or len(c) != 7 or c[0] != "#":
        return "#111111"
    return "#" + hex2(hex_byte(c, 1) * pct // 100) + hex2(hex_byte(c, 3) * pct // 100) + hex2(hex_byte(c, 5) * pct // 100)

def get_cachable_data(url, ttl_seconds):
    res = http.get(url = url, ttl_seconds = ttl_seconds)
    if res.status_code != 200:
        return None
    body = res.body()
    if body == None or len(body) == 0:
        return None
    return body

def fetch_json(url, ttl_seconds):
    body = get_cachable_data(url, ttl_seconds)
    if body == None or body[0] != "{":
        return None
    parsed = json.decode(body)
    if type(parsed) != "dict":
        return None
    return parsed

# ----------------------- Time helpers -----------------------------------------
def local_tz(config):
    tz = as_str(config.get("$tz"), "")
    if tz == "":
        tz = as_str(time.tz(), "")
    if tz == "":
        tz = "America/New_York"
    return tz

def parse_kickoff(s, tz):
    # ESPN dates look like 2026-10-27T00:15Z (no seconds).
    if type(s) != "string" or len(s) < 17:
        return None
    if len(s) == 17:
        return time.parse_time(s, format = "2006-01-02T15:04Z").in_location(tz)
    return time.parse_time(s).in_location(tz)

def day_key(t):
    return t.format("2006-01-02")

def is_today(t, now):
    return day_key(t) == day_key(now)

def is_yesterday(t, now):
    return day_key(t) == day_key(now - time.parse_duration("24h"))

# ----------------------- ESPN parsing -----------------------------------------
def team_info(abbr, team_id, score):
    meta = TEAMS.get(abbr, {"name": abbr, "bg": "#222222", "accent": WHITE})
    return {
        "abbr": abbr,
        "id": team_id,
        "score": score,
        "bg": meta["bg"],
        "accent": meta["accent"],
    }

def score_text(x):
    # Scoreboard scores are strings; schedule scores are {value, displayValue}.
    if type(x) == "string":
        return x
    if type(x) == "dict":
        return as_str(x.get("displayValue"), "0")
    if type(x) == "int":
        return str(x)
    return "0"

def down_text(sit):
    down = as_int(sit.get("down"), -1)
    if down < 1:
        return ""
    short = as_str(sit.get("shortDownDistanceText"), "")
    if "Goal" in short:
        return str(down) + "&G"
    return str(down) + "&" + str(as_int(sit.get("distance"), 0))

def parse_situation(sit):
    # situation is missing before and after games, and mid-stoppage it can be
    # degenerate (down -1, no possession): only show a down when both exist.
    if type(sit) != "dict":
        return None
    poss = as_str(sit.get("possession"), "")
    down = down_text(sit)
    return {
        "valid": down != "" and poss != "",
        "down": down,
        "spot": as_str(sit.get("possessionText"), "").upper(),
        "poss": poss,
        "hto": clamp(as_int(sit.get("homeTimeouts"), 3), 0, 3),
        "ato": clamp(as_int(sit.get("awayTimeouts"), 3), 0, 3),
    }

def parse_event(ev, tz):
    if type(ev) != "dict":
        return None
    comps = as_list(ev.get("competitions"))
    if len(comps) == 0 or type(comps[0]) != "dict":
        return None
    comp = comps[0]
    status = as_dict(comp.get("status"))
    if len(status) == 0:
        status = as_dict(ev.get("status"))
    stype = as_dict(status.get("type"))
    kick = parse_kickoff(as_str(ev.get("date"), ""), tz)
    if kick == None:
        return None

    away = None
    home = None
    for ct in as_list(comp.get("competitors")):
        if type(ct) != "dict":
            continue
        t = as_dict(ct.get("team"))
        info = team_info(as_str(t.get("abbreviation"), "?"), as_str(t.get("id"), ""), score_text(ct.get("score")))
        if ct.get("homeAway") == "home":
            home = info
        else:
            away = info
    if away == None or home == None:
        return None

    state = as_str(stype.get("state"), "pre")
    return {
        "id": as_str(ev.get("id"), ""),
        "state": state,
        "status_name": as_str(stype.get("name"), ""),
        "completed": as_bool(stype.get("completed"), False),
        "period": as_int(status.get("period"), 0),
        "clock": as_str(status.get("displayClock"), ""),
        "kick": kick,
        "time_valid": as_bool(comp.get("timeValid"), True),
        "away": away,
        "home": home,
        "sit": parse_situation(comp.get("situation")) if state == "in" else None,
    }

# ----------------------- Fetch + select ---------------------------------------
def schedule_events(team, tz, query, ttl_seconds):
    d = fetch_json(ESPN_NFL + "/teams/" + team.lower() + "/schedule" + query, ttl_seconds)
    if d == None:
        return None
    out = []
    for ev in as_list(d.get("events")):
        g = parse_event(ev, tz)
        if g != None and g["status_name"] not in SKIP_STATUS:
            out.append(g)
    return out

def select_game(games, now):
    live = None
    upcoming = None
    recent = None
    stale = now - time.parse_duration("12h")
    for g in games:
        if g["state"] == "in":
            live = g
        elif g["state"] == "pre":
            if g["kick"] > stale and (upcoming == None or g["kick"] < upcoming["kick"]):
                upcoming = g
        elif g["completed"]:
            if recent == None or g["kick"] > recent["kick"]:
                recent = g

    if live != None:
        return live
    if upcoming != None and is_today(upcoming["kick"], now):
        return upcoming

    # The original kept the final up through the day after the game.
    if recent != None and (is_today(recent["kick"], now) or is_yesterday(recent["kick"], now)):
        return recent
    if upcoming != None:
        return upcoming
    return recent

def refresh_from_scoreboard(game, tz):
    # The schedule has no field situation, so anything that could be under way
    # re-reads its event from the scoreboard for the game's (Eastern) date.
    dates = game["kick"].in_location("America/New_York").format("20060102")
    ttl = 15 if game["state"] != "post" else 300
    d = fetch_json(ESPN_NFL + "/scoreboard?dates=" + dates, ttl)
    if d == None:
        return game
    for ev in as_list(d.get("events")):
        if type(ev) == "dict" and as_str(ev.get("id"), "") == game["id"]:
            fresh = parse_event(ev, tz)
            if fresh != None:
                return fresh
    return game

def get_game(team, now, tz):
    games = schedule_events(team, tz, "", 300)
    if games == None:
        return None

    has_current = False
    for g in games:
        if g["state"] == "in" or g["state"] == "pre":
            has_current = True
    if not has_current:
        # Past the regular season: pick up playoff games, and the last
        # regular-season game if the default schedule already rolled over.
        seen = {g["id"]: True for g in games}
        for query in ["?seasontype=3", "?seasontype=2"]:
            extra = schedule_events(team, tz, query, 3600)
            for g in (extra or []):
                if g["id"] not in seen:
                    seen[g["id"]] = True
                    games.append(g)

    game = select_game(games, now)
    if game == None:
        return None

    near_kickoff = game["state"] == "pre" and game["kick"] - now < time.parse_duration("15m")
    if game["state"] == "in" or near_kickoff or (game["state"] == "post" and is_today(game["kick"], now)):
        game = refresh_from_scoreboard(game, tz)
    return game

def standings_seed(entry):
    for st in as_list(entry.get("stats")):
        if type(st) == "dict" and st.get("name") == "playoffSeed":
            return as_int(st.get("value"), 99)
    return 99

def get_standings(team):
    d = fetch_json(STANDINGS_URL, 3600)
    if d == None:
        return None
    for conf in as_list(d.get("children")):
        for div in as_list(as_dict(conf).get("children")):
            entries = [e for e in as_list(as_dict(as_dict(div).get("standings")).get("entries")) if type(e) == "dict"]
            abbrs = [as_str(as_dict(e.get("team")).get("abbreviation"), "") for e in entries]
            if team not in abbrs:
                continue
            ordered = sorted(entries, key = standings_seed)
            parts = [as_str(div.get("name"), "").upper()]
            for i, e in enumerate(ordered):
                parts.append(str(i + 1) + ":" + as_str(as_dict(e.get("team")).get("abbreviation"), "?"))
            return "  ".join(parts)
    return None

# ----------------------- Labels -----------------------------------------------
def quarter_label(period):
    if period == 1:
        return "1st"
    if period == 2:
        return "2nd"
    if period == 3:
        return "3rd"
    if period == 4:
        return "4th"
    if period == 5:
        return "OT"
    if period > 5:
        return str(period - 4) + "OT"
    return ""

def kickoff_label(kick, now):
    if is_today(kick, now):
        return "START"
    if kick - now < time.parse_duration("144h"):
        return kick.format("Mon").upper()
    return kick.format("1/2")

# ----------------------- Pieces -----------------------------------------------
def team_logo(abbr, size):
    # Fetch at 4x and let pixlet downscale: crisper than ESPN's antialiased
    # small sizes. The dark variant keeps navy logos visible on navy tiles.
    px = size * S
    img = get_cachable_data(LOGO_URL % (abbr.lower(), px * 4, px * 4), 86400)
    if img == None:
        return med(abbr[:1])
    return render.Image(img, width = px, height = px)

# CG-pixel-3x5-mono draws "&" like a G, which turns "1&G" into "1GG".
AMPERSAND = [
    ".#..",
    "#.#.",
    ".#..",
    "#.#.",
    ".#.#",
]

def down_line(text):
    if S == 2 or "&" not in text:
        return small(text)
    parts = text.split("&")
    return render.Row(
        children = [
            small(parts[0]),
            render.Box(width = 4, height = 5, child = sprite_palette(AMPERSAND, {"#": WHITE})),
            spacer_w(1),
            small(parts[1]),
        ],
        main_align = "start",
        cross_align = "start",
    )

def divider(h):
    return render.Box(width = S, height = h * S, color = DIVIDER)

def status_column(lines, h):
    return render.Box(
        width = STATUS_W * S,
        height = h * S,
        child = render.Column(
            children = lines,
            main_align = "center",
            cross_align = "center",
        ),
    )

def timeout_bars(n, color):
    bars = []
    for i in range(n):
        if i > 0:
            bars.append(spacer_w(1))
        bars.append(render.Box(width = 3 * S, height = S, color = color))
    return render.Row(children = bars, main_align = "center", cross_align = "center")

def standings_strip(text, focus):
    color = dim_color(focus["bg"], 45)
    if text == None or text == "":
        return render.Box(width = 64 * S, height = STRIP_H * S, color = color)
    return render.Box(
        width = 64 * S,
        height = STRIP_H * S,
        color = color,
        child = render.Marquee(width = 64 * S, child = small(text)),
    )

# ----------------------- Live + Final -----------------------------------------
def team_tile(team, sit, is_home):
    bg = team["bg"]
    fg = team_font_color(bg)
    layers = [
        render.Box(width = TILE_W * S, height = 16 * S, color = bg),
        at(1, 0, centered(18, 16, team_logo(team["abbr"], 16))),
        at(19, 1, centered(16, 5, small(team["abbr"], accent_on(bg, team["accent"])))),
        at(19, 6, centered(16, 8, med(team["score"], fg))),
    ]
    if sit != None:
        layers.append(at(19, 14, centered(16, 1, timeout_bars(sit["hto"] if is_home else sit["ato"], fg))))
        if sit["poss"] != "" and sit["poss"] == team["id"]:
            layers.append(at(36, 8, render.Box(width = 2 * S, height = 2 * S, color = fg)))
    return render.Stack(children = layers)

def live_status(game):
    name = game["status_name"]
    sit = game["sit"]
    if name == "STATUS_HALFTIME":
        return [med("HALF")]
    if name == "STATUS_END_PERIOD":
        return [med("END"), spacer_h(4), med(quarter_label(game["period"]))]
    lines = [med(quarter_label(game["period"]))]
    if sit != None and sit["valid"]:
        return lines + [
            spacer_h(1),
            med(game["clock"]),
            spacer_h(2),
            down_line(sit["down"]),
            spacer_h(1),
            small(sit["spot"]),
        ]
    return lines + [spacer_h(4), med(game["clock"])]

def final_status(game):
    return [
        med("F/OT" if game["period"] > 4 else "Final"),
        spacer_h(3),
        small(game["kick"].format("Mon").upper(), GRAY),
        spacer_h(1),
        small(game["kick"].format("1/2"), GRAY),
    ]

def scoreboard_layout(game, final):
    sit = None if final else game["sit"]
    return render.Row(
        children = [
            status_column(final_status(game) if final else live_status(game), 32),
            divider(32),
            render.Column(
                children = [
                    team_tile(game["away"], sit, False),
                    team_tile(game["home"], sit, True),
                ],
            ),
        ],
    )

# ----------------------- Upcoming ---------------------------------------------
def team_column(team, w):
    bg = team["bg"]
    return render.Stack(
        children = [
            render.Box(width = w * S, height = PRE_TOP_H * S, color = bg),
            at(0, 1, centered(w, 16, team_logo(team["abbr"], 16))),
            at(0, 19, centered(w, 5, small(team["abbr"], accent_on(bg, team["accent"])))),
        ],
    )

def pregame_status(game, now):
    when = game["kick"].format("3:04") if game["time_valid"] else "TBD"
    return [small(kickoff_label(game["kick"], now), GRAY), spacer_h(3), med(when)]

def pregame_layout(game, now, standings, focus):
    return render.Column(
        children = [
            render.Row(
                children = [
                    status_column(pregame_status(game, now), PRE_TOP_H),
                    divider(PRE_TOP_H),
                    team_column(game["away"], PRE_AWAY_W),
                    team_column(game["home"], PRE_HOME_W),
                ],
            ),
            standings_strip(standings, focus),
        ],
    )

# ----------------------- Dev fixtures -----------------------------------------
# `fixture=<name>` renders canned games so layouts can be checked without a
# live game. Not exposed in the schema.
def at_clock(day, hour, minute, tz):
    return time.time(year = day.year, month = day.month, day = day.day, hour = hour, minute = minute, location = tz)

def fixture_game(name, now, tz):
    yesterday = now - time.parse_duration("24h")
    game = {
        "id": "fixture",
        "state": "in",
        "status_name": "STATUS_IN_PROGRESS",
        "completed": False,
        "period": 2,
        "clock": "5:15",
        "kick": at_clock(now, 16, 25, tz),
        "time_valid": True,
        "away": team_info("BUF", "2", "7"),
        "home": team_info("KC", "12", "0"),
        "sit": {"valid": True, "down": "3&4", "spot": "KC 47", "poss": "12", "hto": 3, "ato": 2},
    }
    if name == "live_nosit":
        game["period"] = 1
        game["clock"] = "8:17"
        game["away"] = team_info("LV", "13", "0")
        game["home"] = team_info("NYG", "19", "7")
        game["sit"] = {"valid": False, "down": "", "spot": "", "poss": "13", "hto": 3, "ato": 3}
    elif name == "half":
        game["status_name"] = "STATUS_HALFTIME"
        game["away"] = team_info("MIN", "16", "7")
        game["home"] = team_info("PHI", "21", "7")
        game["sit"] = {"valid": False, "down": "", "spot": "", "poss": "", "hto": 3, "ato": 1}
    elif name == "goal":
        game["period"] = 4
        game["clock"] = "0:42"
        game["away"] = team_info("PHI", "21", "24")
        game["home"] = team_info("MIA", "15", "31")
        game["sit"] = {"valid": True, "down": "1&G", "spot": "MIA 8", "poss": "21", "hto": 0, "ato": 1}
    elif name.startswith("pre"):
        game["state"] = "pre"
        game["status_name"] = "STATUS_SCHEDULED"
        game["sit"] = None
        game["away"] = team_info("PHI", "21", "0")
        game["home"] = team_info("NYG", "19", "0")
        game["standings"] = "NFC EAST  1:NYG  2:DAL  3:PHI  4:WSH"
        if name == "pre_week":
            game["kick"] = at_clock(now + time.parse_duration("96h"), 13, 0, tz)
        elif name == "pre_far":
            game["kick"] = at_clock(now + time.parse_duration("288h"), 20, 20, tz)
        elif name == "pre_tbd":
            game["kick"] = at_clock(now + time.parse_duration("288h"), 0, 0, tz)
            game["time_valid"] = False
        else:
            game["kick"] = at_clock(now, 22, 0, tz)
    elif name.startswith("final"):
        game["state"] = "post"
        game["status_name"] = "STATUS_FINAL"
        game["completed"] = True
        game["sit"] = None
        game["period"] = 4
        game["kick"] = at_clock(yesterday, 20, 15, tz)
        game["away"] = team_info("DAL", "6", "38")
        game["home"] = team_info("PHI", "21", "21")
        if name == "final_ot":
            game["period"] = 5
            game["kick"] = at_clock(yesterday, 13, 0, tz)
            game["away"] = team_info("NYG", "19", "23")
            game["home"] = team_info("HOU", "34", "20")
    return game

# ----------------------- Main -------------------------------------------------
def main(config):
    tz = local_tz(config)
    now = time.now().in_location(tz)
    team = as_str(config.get("team"), DEFAULT_TEAM)
    if team not in TEAMS:
        team = DEFAULT_TEAM

    fixture = as_str(config.get("fixture"), "")
    if fixture != "":
        game = fixture_game(fixture, now, tz)
    else:
        game = get_game(team, now, tz)

    if game == None:
        print("--- NO GAME DATA, SKIPPING RENDER ---")
        return []

    if config.bool("gameday_only", False) and game["state"] != "in" and not is_today(game["kick"], now):
        print("--- APPLET HIDDEN FROM ROTATION (NO GAME TODAY) ---")
        return []

    if game["state"] == "pre":
        # The standings strip follows the selected team; fixtures fall back to home.
        focus = game["away"] if game["away"]["abbr"] == team else game["home"]
        standings = game["standings"] if "standings" in game else get_standings(focus["abbr"])
        child = pregame_layout(game, now, standings, focus)
    else:
        child = scoreboard_layout(game, game["state"] == "post")

    # Marquee speed is per frame, so 2x halves the delay to scroll at the same rate.
    return render.Root(
        delay = 50 // S,
        show_full_animation = True,
        child = render.Box(color = "#000000", child = child),
    )

def team_name(abbr):
    return TEAMS[abbr]["name"]

def get_schema():
    team_options = [
        schema.Option(display = team_name(abbr), value = abbr)
        for abbr in sorted(TEAMS.keys(), key = team_name)
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "team",
                name = "Team",
                desc = "The team to follow.",
                icon = "football",
                default = team_options[0].value,
                options = team_options,
            ),
            schema.Toggle(
                id = "gameday_only",
                name = "Show only on game day",
                desc = "Hide app from rotation when the selected team has no game today.",
                icon = "calendar",
                default = False,
            ),
        ],
    )
