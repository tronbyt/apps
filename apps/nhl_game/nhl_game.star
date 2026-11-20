# nhl_game.star
# title: NHL Game (in the style of Tidbyt's original sports apps)
# description: Left = status column (period/clock/power play, start time, or final). Right = team tiles.
# Tidbyt never shipped an NHL app, so this follows its Basketball and Football
# apps, and shares fonts, helpers, and logo handling with nfl_game and mlb_game.

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

# ----------------------- Canvas + fonts ---------------------------------------
# 2x panels (128x64) reuse the 64x32 layout with every dimension doubled.
S = 2 if canvas.is2x() else 1
FONT_SMALL = "6x10" if S == 2 else "CG-pixel-3x5-mono"
FONT_WIDE = "6x10" if S == 2 else "CG-pixel-4x5-mono"
FONT_MED = "terminus-16" if S == 2 else "5x8"

WHITE = "#ffffff"
GRAY = "#888888"
DIVIDER = "#444444"

# Pregame screen, measured from the original Baseball/Basketball previews.
LABEL_GRAY = "#999999"
PRE_DIVIDER = "#777777"
STRIP_BG = "#3A0610"

STATUS_W = 24
TILE_W = 39
PRE_STATUS_W = 21
PRE_TEAM_W = 21
PRE_TOP_H = 25
STRIP_H = 7

NHL_API = "https://api-web.nhle.com/v1"
LOGO_URL = "https://a.espncdn.com/combiner/i?img=/i/teamlogos/nhl/500-dark/%s.png&h=%d&w=%d"

# Postponed, canceled, and suspended games never show.
SKIP_SCHEDULE_STATES = ["PPD", "CNCL", "SUSP"]

# ----------------------- Teams ------------------------------------------------
# Keyed by NHL API abbreviation; `espn` is ESPN's logo slug. Colors are seeded
# from ESPN color/alternateColor, then tuned for the LEDs: black primaries get
# a dark stand-in, and accents that vanish on the primary get the next color.
TEAMS = {
    "ANA": {"name": "Anaheim Ducks", "espn": "ana", "bg": "#fc4c02", "accent": "#000000"},
    "BOS": {"name": "Boston Bruins", "espn": "bos", "bg": "#222222", "accent": "#fdb71a"},
    "BUF": {"name": "Buffalo Sabres", "espn": "buf", "bg": "#00468b", "accent": "#fdb71a"},
    "CAR": {"name": "Carolina Hurricanes", "espn": "car", "bg": "#e30426", "accent": "#a2aaad"},
    "CBJ": {"name": "Columbus Blue Jackets", "espn": "cbj", "bg": "#002d62", "accent": "#e31937"},
    "CGY": {"name": "Calgary Flames", "espn": "cgy", "bg": "#dd1a32", "accent": "#f1be48"},
    "CHI": {"name": "Chicago Blackhawks", "espn": "chi", "bg": "#e31937", "accent": "#ffffff"},
    "COL": {"name": "Colorado Avalanche", "espn": "col", "bg": "#860038", "accent": "#a4a9ad"},
    "DAL": {"name": "Dallas Stars", "espn": "dal", "bg": "#20864c", "accent": "#a2aaad"},
    "DET": {"name": "Detroit Red Wings", "espn": "det", "bg": "#e30526", "accent": "#ffffff"},
    "EDM": {"name": "Edmonton Oilers", "espn": "edm", "bg": "#00205b", "accent": "#ff4c00"},
    "FLA": {"name": "Florida Panthers", "espn": "fla", "bg": "#e51937", "accent": "#b9975b"},
    "LAK": {"name": "Los Angeles Kings", "espn": "la", "bg": "#222222", "accent": "#a2aaad"},
    "MIN": {"name": "Minnesota Wild", "espn": "min", "bg": "#124734", "accent": "#ae122a"},
    "MTL": {"name": "Montreal Canadiens", "espn": "mtl", "bg": "#c41230", "accent": "#ffffff"},
    "NJD": {"name": "New Jersey Devils", "espn": "nj", "bg": "#e30b2b", "accent": "#000000"},
    "NSH": {"name": "Nashville Predators", "espn": "nsh", "bg": "#fdba31", "accent": "#002d62"},
    "NYI": {"name": "New York Islanders", "espn": "nyi", "bg": "#00529b", "accent": "#f47d31"},
    "NYR": {"name": "New York Rangers", "espn": "nyr", "bg": "#0056ae", "accent": "#e51937"},
    "OTT": {"name": "Ottawa Senators", "espn": "ott", "bg": "#dd1a32", "accent": "#b79257"},
    "PHI": {"name": "Philadelphia Flyers", "espn": "phi", "bg": "#fe5823", "accent": "#000000"},
    "PIT": {"name": "Pittsburgh Penguins", "espn": "pit", "bg": "#222222", "accent": "#fdb71a"},
    "SEA": {"name": "Seattle Kraken", "espn": "sea", "bg": "#000d33", "accent": "#a3dce4"},
    "SJS": {"name": "San Jose Sharks", "espn": "sj", "bg": "#00788a", "accent": "#e57200"},
    "STL": {"name": "St. Louis Blues", "espn": "stl", "bg": "#0070b9", "accent": "#fdb71a"},
    "TBL": {"name": "Tampa Bay Lightning", "espn": "tb", "bg": "#003e7e", "accent": "#ffffff"},
    "TOR": {"name": "Toronto Maple Leafs", "espn": "tor", "bg": "#003e7e", "accent": "#ffffff"},
    "UTA": {"name": "Utah Mammoth", "espn": "utah", "bg": "#222222", "accent": "#7ab2e1"},
    "VAN": {"name": "Vancouver Canucks", "espn": "van", "bg": "#003e7e", "accent": "#ffffff"},
    "VGK": {"name": "Vegas Golden Knights", "espn": "vgk", "bg": "#344043", "accent": "#b4975a"},
    "WPG": {"name": "Winnipeg Jets", "espn": "wpg", "bg": "#002d62", "accent": "#c41230"},
    "WSH": {"name": "Washington Capitals", "espn": "wsh", "bg": "#d71830", "accent": "#ffffff"},
}

# ESPN logos fill 92% of their square, so round and tall ones touch the top
# and bottom of a 16px score tile. These draw smaller to keep a margin, at
# whichever size leaves equal dark rows above and below once the faint
# antialiased edge rows (too dim to light an LED) are discounted.
LOGO_SIZE = {
    "BOS": 15,
    "BUF": 15,
    "EDM": 15,
    "FLA": 14,
    "NJD": 14,
    "NYI": 15,
    "NYR": 14,
    "PIT": 14,
    "SEA": 15,
    "TBL": 14,
    "TOR": 15,
    "VAN": 14,
    "VGK": 14,
    "WPG": 15,
}

DEFAULT_TEAM = "ANA"

# ----------------------- Tiny helpers -----------------------------------------
def spacer_w(w):
    return render.Box(width = w * S, height = 1)

def spacer_h(h):
    return render.Box(width = 1, height = h * S)

def at(x, y, child):
    return render.Padding(pad = (x * S, y * S, 0, 0), child = child)

def small(text, color = WHITE):
    return render.Text(text, font = FONT_SMALL, color = color)

def wide(text, color = WHITE):
    return render.Text(text, font = FONT_WIDE, color = color)

def med(text, color = WHITE):
    return render.Text(text, font = FONT_MED, color = color)

def centered(w, h, child):
    return render.Box(width = w * S, height = h * S, child = child)

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

def int_from_digits(s, d):
    if type(s) != "string" or len(s) == 0:
        return d
    for i in range(len(s)):
        ch = s[i]
        if ch < "0" or ch > "9":
            return d
    return int(s)

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

def hex_byte(s, start):
    if type(s) != "string" or len(s) < start + 2:
        return 0
    hi = s[start]
    lo = s[start + 1]
    if hi not in HEX_VAL or lo not in HEX_VAL:
        return 0
    return HEX_VAL[hi] * 16 + HEX_VAL[lo]

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

def parse_start(s, tz):
    # NHL start times are RFC3339: 2026-10-28T00:00:00Z
    if type(s) != "string" or len(s) < 20:
        return None
    return time.parse_time(s).in_location(tz)

def day_key(t):
    return t.format("2006-01-02")

def is_today(t, now):
    return day_key(t) == day_key(now)

def is_yesterday(t, now):
    return day_key(t) == day_key(now - time.parse_duration("24h"))

def short_clock(s):
    # The API pads minutes ("01:23"); scoreboards don't.
    if len(s) == 5 and s[0] == "0":
        return s[1:]
    return s

# ----------------------- NHL parsing ------------------------------------------
STATE_MAP = {
    "FUT": "pre",
    "PRE": "pre",
    "LIVE": "in",
    "CRIT": "in",
    "FINAL": "post",
    "OFF": "post",
}

def team_info(abbr, team_id, score):
    meta = TEAMS.get(abbr, {"name": abbr, "espn": abbr.lower(), "bg": "#222222", "accent": WHITE})
    return {
        "abbr": abbr,
        "id": team_id,
        "score": score,
        "bg": meta["bg"],
        "accent": meta["accent"],
    }

def parse_situation(sit):
    # situationCode is away goalie, away skaters, home skaters, home goalie:
    # "1451" is a home power play, "0651" an away extra attacker. Only an
    # uneven count is worth a line on the scoreboard.
    if type(sit) != "dict":
        return None
    code = as_str(sit.get("situationCode"), "")
    if len(code) != 4 or int_from_digits(code, -1) < 0:
        return None
    away_goalie = int(code[0])
    away_skaters = int(code[1])
    home_skaters = int(code[2])
    home_goalie = int(code[3])

    # A pulled goalie's extra attacker isn't a power play.
    away_strength = away_skaters - (1 if away_goalie == 0 else 0)
    home_strength = home_skaters - (1 if home_goalie == 0 else 0)
    adv = ""
    if away_strength > home_strength:
        adv = "away"
    elif home_strength > away_strength:
        adv = "home"

    label = ""
    if adv != "":
        label = "PP"
    elif away_goalie == 0 or home_goalie == 0:
        label = "EN"
    if label == "":
        return None

    left = short_clock(as_str(sit.get("timeRemaining"), ""))
    if left == "":
        left = str(away_skaters) + "V" + str(home_skaters)
    return {"label": label, "adv": adv, "time": left}

def parse_game(g, tz):
    if type(g) != "dict":
        return None
    start = parse_start(as_str(g.get("startTimeUTC"), ""), tz)
    if start == None:
        return None
    away_raw = as_dict(g.get("awayTeam"))
    home_raw = as_dict(g.get("homeTeam"))
    away_abbr = as_str(away_raw.get("abbrev"), "")
    home_abbr = as_str(home_raw.get("abbrev"), "")
    if away_abbr == "" or home_abbr == "":
        return None

    period = as_dict(g.get("periodDescriptor"))
    clock = as_dict(g.get("clock"))
    outcome = as_dict(g.get("gameOutcome"))
    period_type = as_str(period.get("periodType"), "REG")
    state = STATE_MAP.get(as_str(g.get("gameState"), ""), "pre")

    sog = None
    if away_raw.get("sog") != None and home_raw.get("sog") != None:
        sog = str(as_int(away_raw.get("sog"), 0)) + "-" + str(as_int(home_raw.get("sog"), 0))

    return {
        "id": str(as_int(g.get("id"), 0)),
        "state": state,
        "schedule_state": as_str(g.get("gameScheduleState"), "OK"),
        "period": as_int(period.get("number"), 0),
        "period_type": period_type,
        "last_period": as_str(outcome.get("lastPeriodType"), period_type),
        "clock": short_clock(as_str(clock.get("timeRemaining"), "")),
        "intermission": as_bool(clock.get("inIntermission"), False),
        "kick": start,
        "time_valid": True,
        "away": team_info(away_abbr, str(as_int(away_raw.get("id"), 0)), str(as_int(away_raw.get("score"), 0))),
        "home": team_info(home_abbr, str(as_int(home_raw.get("id"), 0)), str(as_int(home_raw.get("score"), 0))),
        "sog": sog,
        "sit": parse_situation(g.get("situation")) if state == "in" else None,
    }

# ----------------------- Fetch + select ---------------------------------------
def schedule_games(team, tz):
    d = fetch_json(NHL_API + "/club-schedule-season/" + team + "/now", 300)
    if d == None:
        return None
    out = []
    for g in as_list(d.get("games")):
        game = parse_game(g, tz)
        if game != None and game["schedule_state"] not in SKIP_SCHEDULE_STATES:
            out.append(game)
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
        elif recent == None or g["kick"] > recent["kick"]:
            recent = g

    if live != None:
        return live
    if upcoming != None and is_today(upcoming["kick"], now):
        return upcoming

    # Like the original apps, keep the final up through the day after the game.
    if recent != None and (is_today(recent["kick"], now) or is_yesterday(recent["kick"], now)):
        return recent
    if upcoming != None:
        return upcoming
    return recent

def refresh_from_boxscore(game, tz):
    # The season schedule has no clock or skater counts, so anything that
    # could be under way re-reads the game's boxscore.
    ttl = 15 if game["state"] != "post" else 300
    d = fetch_json(NHL_API + "/gamecenter/" + game["id"] + "/boxscore", ttl)
    if d == None:
        return game
    fresh = parse_game(d, tz)
    if fresh == None:
        return game
    return fresh

def get_game(team, now, tz):
    games = schedule_games(team, tz)
    if games == None:
        return None
    game = select_game(games, now)
    if game == None:
        return None

    near_start = game["state"] == "pre" and game["kick"] - now < time.parse_duration("15m")
    if game["state"] == "in" or near_start or (game["state"] == "post" and is_today(game["kick"], now)):
        game = refresh_from_boxscore(game, tz)
    return game

def division_seq(entry):
    return as_int(entry.get("divisionSequence"), 99)

def get_standings(team):
    # "1:BOS  2:OTT  3:TOR ..." for the team's division, like the original
    # apps' bottom ticker.
    d = fetch_json(NHL_API + "/standings/now", 3600)
    if d == None:
        return ""
    entries = [e for e in as_list(d.get("standings")) if type(e) == "dict"]
    division = ""
    for e in entries:
        if as_str(as_dict(e.get("teamAbbrev")).get("default"), "") == team:
            division = as_str(e.get("divisionAbbrev"), "")
    if division == "":
        return ""
    ordered = sorted([e for e in entries if e.get("divisionAbbrev") == division], key = division_seq)
    parts = []
    for e in ordered:
        parts.append(str(division_seq(e)) + ":" + as_str(as_dict(e.get("teamAbbrev")).get("default"), "?"))
    return "  ".join(parts)

# ----------------------- Labels -----------------------------------------------
def period_label(period, period_type):
    if period_type == "SO":
        return "SO"
    if period == 1:
        return "1st"
    if period == 2:
        return "2nd"
    if period == 3:
        return "3rd"
    if period == 4:
        return "OT"
    if period > 4:
        return str(period - 3) + "OT"
    return ""

def final_label(game):
    if game["last_period"] == "SO":
        return "F/SO"
    if game["last_period"] == "OT" or game["period"] > 3:
        if game["period"] > 4:
            return "F/" + str(game["period"] - 3) + "OT"
        return "F/OT"
    return "Final"

def start_label(kick, now):
    if is_today(kick, now):
        return "START"
    if kick - now < time.parse_duration("144h"):
        return kick.format("Mon").upper()
    return kick.format("1/2")

# ----------------------- Pieces -----------------------------------------------
def team_logo(abbr, size):
    # Fetch at 4x and let pixlet downscale: crisper than ESPN's antialiased
    # small sizes. The dark variant keeps dark logos visible on dark tiles.
    px = size * S
    slug = TEAMS[abbr]["espn"] if abbr in TEAMS else abbr.lower()
    img = get_cachable_data(LOGO_URL % (slug, px * 4, px * 4), 86400)
    if img == None:
        return med(abbr[:1])
    return render.Image(img, width = px, height = px)

def divider(h, color):
    return render.Box(width = S, height = h * S, color = color)

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

def standings_strip(text):
    if text == None or text == "":
        return render.Box(width = 64 * S, height = STRIP_H * S, color = STRIP_BG)
    return render.Box(
        width = 64 * S,
        height = STRIP_H * S,
        color = STRIP_BG,
        child = render.Marquee(width = 64 * S, child = wide(text)),
    )

# ----------------------- Live + Final -----------------------------------------
def team_tile(team, sit, is_home):
    bg = team["bg"]
    fg = team_font_color(bg)

    # Box centering rounds an odd gap toward the bottom; round it toward the
    # top instead so 15px logos keep one dark row above and below on the panel.
    size = LOGO_SIZE.get(team["abbr"], 16)
    logo_top = (16 - size) * S // 2
    layers = [
        render.Box(width = TILE_W * S, height = 16 * S, color = bg),
        render.Padding(
            pad = (S, logo_top, 0, 0),
            child = render.Box(width = 18 * S, height = size * S, child = team_logo(team["abbr"], size)),
        ),
        at(19, 1, centered(16, 5, small(team["abbr"], accent_on(bg, team["accent"])))),
        at(19, 6, centered(16, 8, med(team["score"], fg))),
    ]

    # The power-play team gets the dot the football app used for possession.
    if sit != None and sit["adv"] == ("home" if is_home else "away"):
        layers.append(at(36, 8, render.Box(width = 2 * S, height = 2 * S, color = fg)))
    return render.Stack(children = layers)

def live_status(game):
    period = period_label(game["period"], game["period_type"])
    if game["intermission"]:
        return [med("END"), spacer_h(4), med(period)]
    if game["period_type"] == "SO":
        return [med("SO")]

    lines = [med(period)]
    sit = game["sit"]
    if sit != None:
        extra = [small(sit["label"]), spacer_h(1), small(sit["time"])]
    elif game["sog"] != None:
        extra = [small("SOG", GRAY), spacer_h(1), small(game["sog"])]
    else:
        return lines + [spacer_h(4), med(game["clock"])]
    return lines + [spacer_h(1), med(game["clock"]), spacer_h(2)] + extra

def final_status(game):
    return [
        med(final_label(game)),
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
            divider(32, DIVIDER),
            render.Column(
                children = [
                    team_tile(game["away"], sit, False),
                    team_tile(game["home"], sit, True),
                ],
            ),
        ],
    )

# ----------------------- Upcoming ---------------------------------------------
def team_column(team):
    bg = team["bg"]
    return render.Stack(
        children = [
            render.Box(width = PRE_TEAM_W * S, height = PRE_TOP_H * S, color = bg),
            at(0, 1, centered(PRE_TEAM_W, 14, team_logo(team["abbr"], 14))),
            at(0, 18, centered(PRE_TEAM_W, 5, wide(team["abbr"], accent_on(bg, team["accent"])))),
        ],
    )

def pregame_status(game, now):
    when = game["kick"].format("3:04") if game["time_valid"] else "TBD"
    return render.Column(
        children = [small(start_label(game["kick"], now), LABEL_GRAY), spacer_h(2), small(when)],
        main_align = "center",
        cross_align = "center",
    )

def pregame_layout(game, now, standings):
    return render.Column(
        children = [
            render.Row(
                children = [
                    # CG-pixel text carries a trailing blank column, so center
                    # in x1-20 to land where the originals drew START (x1-19).
                    at(1, 0, centered(PRE_STATUS_W - 1, PRE_TOP_H, pregame_status(game, now))),
                    divider(PRE_TOP_H, PRE_DIVIDER),
                    team_column(game["away"]),
                    team_column(game["home"]),
                ],
            ),
            standings_strip(standings),
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
        "schedule_state": "OK",
        "period": 2,
        "period_type": "REG",
        "last_period": "REG",
        "clock": "12:34",
        "intermission": False,
        "kick": at_clock(now, 19, 0, tz),
        "time_valid": True,
        "away": team_info("BOS", "6", "2"),
        "home": team_info("CAR", "12", "1"),
        "sog": "21-18",
        "sit": {"label": "PP", "adv": "away", "time": "1:23"},
    }
    if name == "live_sog":
        game["sit"] = None
    elif name == "en":
        game["period"] = 3
        game["clock"] = "1:12"
        game["away"] = team_info("BOS", "6", "3")
        game["home"] = team_info("TOR", "10", "2")
        game["sit"] = {"label": "EN", "adv": "", "time": "5V6"}
    elif name == "int":
        game["intermission"] = True
        game["sit"] = None
    elif name == "ot":
        game["period"] = 4
        game["period_type"] = "OT"
        game["clock"] = "3:08"
        game["home"] = team_info("CAR", "12", "2")
        game["sit"] = {"label": "PP", "adv": "home", "time": "0:51"}
    elif name.startswith("pre"):
        game["state"] = "pre"
        game["sit"] = None
        game["sog"] = None
        game["away"] = team_info("TOR", "10", "0")
        game["home"] = team_info("BOS", "6", "0")
        game["standings"] = "1:BOS  2:OTT  3:TOR  4:TBL  5:MTL  6:FLA  7:DET  8:BUF"
        if name == "pre_week":
            game["kick"] = at_clock(now + time.parse_duration("72h"), 19, 0, tz)
        else:
            game["kick"] = at_clock(now, 19, 0, tz)
    elif name.startswith("final"):
        game["state"] = "post"
        game["sit"] = None
        game["period"] = 3
        game["kick"] = at_clock(yesterday, 19, 0, tz)
        game["away"] = team_info("BOS", "6", "4")
        game["home"] = team_info("MTL", "8", "2")
        if name == "final_ot":
            game["period"] = 4
            game["last_period"] = "OT"
            game["away"] = team_info("BOS", "6", "2")
            game["home"] = team_info("DAL", "25", "3")
        elif name == "final_so":
            game["period"] = 5
            game["period_type"] = "SO"
            game["last_period"] = "SO"
            game["away"] = team_info("BOS", "6", "3")
            game["home"] = team_info("FLA", "13", "2")
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
        standings = game["standings"] if "standings" in game else get_standings(team)
        child = pregame_layout(game, now, standings)
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
                icon = "hockeyPuck",
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
