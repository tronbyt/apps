# nba_game.star
# title: NBA Game (recreation of the original Tidbyt Basketball app)
# description: Left = status column (quarter/clock, start time, or final). Right = team tiles.
# Companion to nfl_game, mlb_game, and nhl_game: same fonts, helpers, and
# ESPN logo handling.

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

# Pregame screen, measured from the original Basketball app-store preview.
LABEL_GRAY = "#999999"
PRE_DIVIDER = "#777777"
STRIP_BG = "#3A0610"

STATUS_W = 24
TILE_W = 39
PRE_STATUS_W = 21
PRE_TEAM_W = 21
PRE_TOP_H = 25
STRIP_H = 7

# Seven teams of the conference ticker, centered on the selected team: the
# full fifteen would hold the app on screen for over half a minute.
STANDINGS_WINDOW = 7

ESPN_NBA = "https://site.api.espn.com/apis/site/v2/sports/basketball/nba"
STANDINGS_URL = "https://site.api.espn.com/apis/v2/sports/basketball/nba/standings"
LOGO_URL = "https://a.espncdn.com/combiner/i?img=/i/teamlogos/nba/500-dark/%s.png&h=%d&w=%d"

# Postponed and canceled games also report state "post"; they never show.
SKIP_STATUS = ["STATUS_POSTPONED", "STATUS_CANCELED", "STATUS_FORFEIT"]

# ----------------------- Teams ------------------------------------------------
# Keyed by ESPN abbreviation; `short` is the NBA tricode shown on the tile.
# Colors are seeded from ESPN color/alternateColor, then tuned for the LEDs:
# black primaries get a dark stand-in, and accents that vanish on the primary
# get the team's next color. Celtics green is darkened so the green roundel
# logo stands out from its tile, and the all-red Rockets logo gets a dark tile.
TEAMS = {
    "ATL": {"name": "Atlanta Hawks", "short": "ATL", "bg": "#c8102e", "accent": "#fdb927"},
    "BKN": {"name": "Brooklyn Nets", "short": "BKN", "bg": "#222222", "accent": "#ffffff"},
    "BOS": {"name": "Boston Celtics", "short": "BOS", "bg": "#003d22", "accent": "#ba9653"},
    "CHA": {"name": "Charlotte Hornets", "short": "CHA", "bg": "#008ca8", "accent": "#ffffff"},
    "CHI": {"name": "Chicago Bulls", "short": "CHI", "bg": "#ce1141", "accent": "#000000"},
    "CLE": {"name": "Cleveland Cavaliers", "short": "CLE", "bg": "#860038", "accent": "#bc945c"},
    "DAL": {"name": "Dallas Mavericks", "short": "DAL", "bg": "#0064b1", "accent": "#bbc4ca"},
    "DEN": {"name": "Denver Nuggets", "short": "DEN", "bg": "#0e2240", "accent": "#fec524"},
    "DET": {"name": "Detroit Pistons", "short": "DET", "bg": "#1d428a", "accent": "#c8102e"},
    "GS": {"name": "Golden State Warriors", "short": "GSW", "bg": "#1d428a", "accent": "#fdb927"},
    "HOU": {"name": "Houston Rockets", "short": "HOU", "bg": "#222222", "accent": "#ce0e2d"},
    "IND": {"name": "Indiana Pacers", "short": "IND", "bg": "#0c2340", "accent": "#ffd520"},
    "LAC": {"name": "LA Clippers", "short": "LAC", "bg": "#12173f", "accent": "#c8102e"},
    "LAL": {"name": "Los Angeles Lakers", "short": "LAL", "bg": "#552583", "accent": "#fdb927"},
    "MEM": {"name": "Memphis Grizzlies", "short": "MEM", "bg": "#5d76a9", "accent": "#f5b112"},
    "MIA": {"name": "Miami Heat", "short": "MIA", "bg": "#222222", "accent": "#d6102f"},
    "MIL": {"name": "Milwaukee Bucks", "short": "MIL", "bg": "#00471b", "accent": "#eee1c6"},
    "MIN": {"name": "Minnesota Timberwolves", "short": "MIN", "bg": "#266092", "accent": "#ffffff"},
    "NO": {"name": "New Orleans Pelicans", "short": "NOP", "bg": "#0a2240", "accent": "#b4975a"},
    "NY": {"name": "New York Knicks", "short": "NYK", "bg": "#1d428a", "accent": "#f58426"},
    "OKC": {"name": "Oklahoma City Thunder", "short": "OKC", "bg": "#007ac1", "accent": "#ef3b24"},
    "ORL": {"name": "Orlando Magic", "short": "ORL", "bg": "#0150b5", "accent": "#9ca0a3"},
    "PHI": {"name": "Philadelphia 76ers", "short": "PHI", "bg": "#1d428a", "accent": "#e01234"},
    "PHX": {"name": "Phoenix Suns", "short": "PHX", "bg": "#29127a", "accent": "#e56020"},
    "POR": {"name": "Portland Trail Blazers", "short": "POR", "bg": "#e03a3e", "accent": "#000000"},
    "SA": {"name": "San Antonio Spurs", "short": "SAS", "bg": "#222222", "accent": "#c4ced4"},
    "SAC": {"name": "Sacramento Kings", "short": "SAC", "bg": "#5a2d81", "accent": "#ffffff"},
    "TOR": {"name": "Toronto Raptors", "short": "TOR", "bg": "#d91244", "accent": "#a1a1a4"},
    "UTAH": {"name": "Utah Jazz", "short": "UTA", "bg": "#4e008e", "accent": "#79a3dc"},
    "WSH": {"name": "Washington Wizards", "short": "WAS", "bg": "#e31837", "accent": "#ffffff"},
}

# ESPN logos fill 92% of their square, so round and tall ones touch the top
# and bottom of a 16px score tile. These draw smaller to keep a margin, at
# whichever size leaves equal dark rows above and below on the tile color.
LOGO_SIZE = {
    "ATL": 15,
    "BKN": 15,
    "BOS": 14,
    "CHI": 15,
    "CLE": 15,
    "DAL": 15,
    "DEN": 15,
    "DET": 15,
    "GS": 15,
    "LAC": 15,
    "MIA": 15,
    "MIN": 15,
    "ORL": 15,
    "PHI": 15,
    "POR": 15,
    "SAC": 15,
    "TOR": 15,
    "WSH": 15,
}

DEFAULT_TEAM = "ATL"

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

def parse_tipoff(s, tz):
    # ESPN dates look like 2026-10-27T23:30Z (no seconds).
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
def team_info(espn_abbr, team_id, score):
    meta = TEAMS.get(espn_abbr, {"name": espn_abbr, "short": espn_abbr, "bg": "#222222", "accent": WHITE})
    return {
        "espn": espn_abbr,
        "abbr": meta["short"],
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
    tipoff = parse_tipoff(as_str(ev.get("date"), ""), tz)
    if tipoff == None:
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

    return {
        "id": as_str(ev.get("id"), ""),
        "state": as_str(stype.get("state"), "pre"),
        "status_name": as_str(stype.get("name"), ""),
        "completed": as_bool(stype.get("completed"), False),
        "period": as_int(status.get("period"), 0),
        "clock": as_str(status.get("displayClock"), ""),
        "kick": tipoff,
        "time_valid": as_bool(comp.get("timeValid"), True),
        "away": away,
        "home": home,
    }

# ----------------------- Fetch + select ---------------------------------------
def schedule_events(team, tz, query, ttl_seconds):
    d = fetch_json(ESPN_NBA + "/teams/" + team.lower() + "/schedule" + query, ttl_seconds)
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
    # The schedule has no game clock, so anything that could be under way
    # re-reads its event from the scoreboard for the game's (Eastern) date.
    dates = game["kick"].in_location("America/New_York").format("20060102")
    ttl = 15 if game["state"] != "post" else 300
    d = fetch_json(ESPN_NBA + "/scoreboard?dates=" + dates, ttl)
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

    near_tipoff = game["state"] == "pre" and game["kick"] - now < time.parse_duration("15m")
    if game["state"] == "in" or near_tipoff or (game["state"] == "post" and is_today(game["kick"], now)):
        game = refresh_from_scoreboard(game, tz)
    return game

def standings_seed(entry):
    for st in as_list(entry.get("stats")):
        if type(st) == "dict" and st.get("name") == "playoffSeed":
            return as_int(st.get("value"), 99)
    return 99

def get_standings(team):
    # "3:CHA  4:TOR  5:BOS  6:CLE ..." from the team's conference, like the
    # original's bottom ticker.
    d = fetch_json(STANDINGS_URL, 3600)
    if d == None:
        return ""
    for conf in as_list(d.get("children")):
        entries = [e for e in as_list(as_dict(as_dict(conf).get("standings")).get("entries")) if type(e) == "dict"]
        ordered = sorted(entries, key = standings_seed)
        abbrs = [as_str(as_dict(e.get("team")).get("abbreviation"), "") for e in ordered]
        if team not in abbrs:
            continue
        first = clamp(abbrs.index(team) - STANDINGS_WINDOW // 2, 0, max(0, len(abbrs) - STANDINGS_WINDOW))
        parts = []
        for i in range(first, min(len(abbrs), first + STANDINGS_WINDOW)):
            parts.append(str(standings_seed(ordered[i])) + ":" + TEAMS.get(abbrs[i], {"short": abbrs[i]})["short"])
        return "  ".join(parts)
    return ""

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

def final_label(game):
    if game["period"] == 5:
        return "F/OT"
    if game["period"] > 5:
        return "F/" + str(game["period"] - 4) + "OT"
    return "Final"

def start_label(tipoff, now):
    if is_today(tipoff, now):
        return "START"
    if tipoff - now < time.parse_duration("144h"):
        return tipoff.format("Mon").upper()
    return tipoff.format("1/2")

# ----------------------- Pieces -----------------------------------------------
def team_logo(espn_abbr, size):
    # Fetch at 4x and let pixlet downscale: crisper than ESPN's antialiased
    # small sizes. The dark variant keeps dark logos visible on dark tiles.
    px = size * S
    img = get_cachable_data(LOGO_URL % (espn_abbr.lower(), px * 4, px * 4), 86400)
    if img == None:
        return med(espn_abbr[:1])
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
def team_tile(team):
    bg = team["bg"]
    fg = team_font_color(bg)

    # Box centering rounds an odd gap toward the bottom; round it toward the
    # top instead so odd-sized logos keep even margins on the panel.
    size = LOGO_SIZE.get(team["espn"], 16)
    logo_top = (16 - size) * S // 2
    return render.Stack(
        children = [
            render.Box(width = TILE_W * S, height = 16 * S, color = bg),
            render.Padding(
                pad = (S, logo_top, 0, 0),
                child = render.Box(width = 18 * S, height = size * S, child = team_logo(team["espn"], size)),
            ),
            at(19, 1, centered(16, 5, small(team["abbr"], accent_on(bg, team["accent"])))),
            at(19, 6, centered(16, 8, med(team["score"], fg))),
        ],
    )

def live_status(game):
    # The original showed just the quarter and clock.
    name = game["status_name"]
    if name == "STATUS_HALFTIME":
        return [med("HALF")]
    if name == "STATUS_END_PERIOD":
        return [med("END"), spacer_h(4), med(quarter_label(game["period"]))]
    return [med(quarter_label(game["period"])), spacer_h(4), med(game["clock"])]

def final_status(game):
    return [
        med(final_label(game)),
        spacer_h(3),
        small(game["kick"].format("Mon").upper(), GRAY),
        spacer_h(1),
        small(game["kick"].format("1/2"), GRAY),
    ]

def scoreboard_layout(game, final):
    return render.Row(
        children = [
            status_column(final_status(game) if final else live_status(game), 32),
            divider(32, DIVIDER),
            render.Column(
                children = [
                    team_tile(game["away"]),
                    team_tile(game["home"]),
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
            at(0, 1, centered(PRE_TEAM_W, 14, team_logo(team["espn"], 14))),
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
                    # in x1-20 to land where the original drew START (x1-19).
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
        "status_name": "STATUS_IN_PROGRESS",
        "completed": False,
        "period": 1,
        "clock": "6:36",
        "kick": at_clock(now, 19, 30, tz),
        "time_valid": True,
        "away": team_info("BOS", "2", "11"),
        "home": team_info("DEN", "7", "10"),
    }
    if name == "live_late":
        game["period"] = 4
        game["clock"] = "42.3"
        game["away"] = team_info("BKN", "17", "101")
        game["home"] = team_info("BOS", "2", "104")
    elif name == "half":
        game["status_name"] = "STATUS_HALFTIME"
        game["period"] = 2
        game["away"] = team_info("BKN", "17", "51")
        game["home"] = team_info("BOS", "2", "58")
    elif name == "end":
        game["status_name"] = "STATUS_END_PERIOD"
        game["period"] = 3
        game["away"] = team_info("BKN", "17", "77")
        game["home"] = team_info("BOS", "2", "84")
    elif name == "ot":
        game["period"] = 5
        game["clock"] = "3:12"
        game["away"] = team_info("NY", "18", "108")
        game["home"] = team_info("BOS", "2", "110")
    elif name.startswith("pre"):
        game["state"] = "pre"
        game["status_name"] = "STATUS_SCHEDULED"
        game["away"] = team_info("BKN", "17", "0")
        game["home"] = team_info("BOS", "2", "0")
        game["standings"] = "2:PHI  3:CHA  4:TOR  5:BOS  6:CLE  7:ATL  8:IND"
        if name == "pre_week":
            game["kick"] = at_clock(now + time.parse_duration("72h"), 19, 30, tz)
    elif name.startswith("final"):
        game["state"] = "post"
        game["status_name"] = "STATUS_FINAL"
        game["completed"] = True
        game["period"] = 4
        game["kick"] = at_clock(yesterday, 19, 30, tz)
        game["away"] = team_info("CHI", "4", "99")
        game["home"] = team_info("BOS", "2", "134")
        if name == "final_ot":
            game["period"] = 5
            game["away"] = team_info("MIA", "14", "118")
            game["home"] = team_info("BOS", "2", "121")
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
                icon = "basketball",
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
