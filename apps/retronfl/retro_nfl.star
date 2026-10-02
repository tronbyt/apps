"""
Applet: Retro NFL
Summary: Classic football scoreboard
Description: Team colors, live scores, possession, timeouts and division standings. Optional companion adds touchdown celebrations and game-time focus.
Author: Created with OpenAI Codex
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def txt(s, color = "#ffffff", font = "tom-thumb"):
    return render.Text(content = str(s), color = color, font = font)

def message(league, s):
    return render.Root(child = render.Box(child = render.Column(cross_align = "center", children = [txt(league.upper()), txt(s, "#ffbf69")])))

def stamp(value):
    # ESPN omits seconds in scheduled timestamps.
    if len(value) == 17:
        value = value[:-1] + ":00Z"
    return time.parse_time(value)

def choose(events, now):
    live = []
    future = []
    recent = []
    held = []
    for event in events:
        games = event.get("competitions", [])
        if not games:
            continue
        status = games[0].get("status", {}).get("type", {})
        age = now - stamp(event["date"]).unix
        state = status.get("state", "")
        if status.get("name") in ["STATUS_POSTPONED", "STATUS_CANCELED", "STATUS_SUSPENDED"] and age >= 0 and age < 64800:
            held.append(event)
        elif state == "in" and age >= -3600 and age < 64800:
            live.append(event)
        elif state == "post" and status.get("completed", False) and age >= 0 and age < 64800:
            recent.append(event)
        elif state == "pre" and age < 0:
            future.append(event)
    live = sorted(live, key = lambda e: e["date"])
    recent = sorted(recent, key = lambda e: e["date"], reverse = True)
    future = sorted(future, key = lambda e: e["date"])
    if live:
        return live[:1]
    return held[:1] + future[:1] if held else recent[:1] + future[:1]

def whole_number(value):
    # Older NAS renderers decode JSON numbers as floats; never display .0 in scores/counts.
    if type(value) in ["int", "float"]:
        return str(int(value)) if value == int(value) else "?"
    if type(value) == "string":
        pieces = value.split(".")
        if pieces[0].isdigit() and (len(pieces) == 1 or (len(pieces) == 2 and pieces[1] and all([d == "0" for d in pieces[1].elems()]))):
            return str(int(pieces[0]))
    return "?"

def score(c, state):
    if state == "pre":
        return "-"
    value = c.get("score")
    if type(value) == "dict":
        return whole_number(value.get("displayValue"))
    return whole_number(value)

def teamcolor(team, league):
    abbr = team.get("abbreviation", "?")
    colors = {"mlb": {"PHI": "#C8102E", "ATL": "#13274F", "TB": "#092C5C", "NYM": "#002D72", "MIL": "#12284B"}, "nfl": {"PHI": "#004C54", "DAL": "#003594", "WSH": "#5A1414", "CHI": "#0B162A", "MIN": "#4F2683"}}
    return colors.get(league, {}).get(abbr, "#" + team.get("color", "183C60"))

def secondary(team, league):
    abbr = team.get("abbreviation", "?")
    overrides = {"mlb": {"PHI": "#6BACE4", "BOS": "#0C2340", "TB": "#8FBCE6"}, "nfl": {"PHI": "#A5ACAF"}}
    if abbr in overrides.get(league, {}):
        return overrides[league][abbr]
    sport = "baseball" if league == "mlb" else "football"
    r = http.get("https://site.api.espn.com/apis/site/v2/sports/%s/%s/teams/%s" % (sport, league, abbr.lower()), ttl_seconds = 86400)
    color = r.json().get("team", {}).get("alternateColor", "") if r.status_code == 200 else ""
    return "#" + color if len(color) == 6 else "#FFFFFF"

def logo(team, league, size):
    abbr = team.get("abbreviation", "?")
    url = "https://a.espncdn.com/i/teamlogos/%s/500-dark/%s.png" % (league, abbr.lower())
    if league == "mlb" and abbr == "PHI":
        url = "https://b.fssta.com/uploads/application/mlb/team-logos/Phillies-alternate.png"
    r = http.get(url, ttl_seconds = 86400)
    return render.Image(src = r.body(), width = size, height = size) if r.status_code == 200 else render.Box(width = size, height = size, child = txt(abbr))

def statuspanel(event, c, kind, state, compact = False, timezone = "America/New_York"):
    when = stamp(event["date"]).in_location(timezone)
    name = kind.get("name")
    if name in ["STATUS_POSTPONED", "STATUS_CANCELED", "STATUS_SUSPENDED"]:
        return render.Column(cross_align = "center", children = [txt({"STATUS_POSTPONED": "PPD", "STATUS_CANCELED": "CANC" if compact else "CANCELED", "STATUS_SUSPENDED": "SUSP"}[name], "#FFD438"), txt(when.format("1/2") if compact else when.format("Jan 2"))])
    if state == "pre":
        return render.Column(cross_align = "center", children = [txt("NEXT", "#8FAABD"), txt(when.format("Mon").upper()), txt(when.format("3:04") if c.get("timeValid", True) else "TBD", font = "tom-thumb" if compact else "5x8"), txt(when.format("PM") if c.get("timeValid", True) else "")])
    return render.Column(cross_align = "center", children = [txt("FINAL", "#FFD438"), render.Box(width = 1, height = 3), txt(when.format("1/2") if compact else when.format("Jan 2"))])

def nfl_ticker(favorite):
    r = http.get("https://site.api.espn.com/apis/v2/sports/football/nfl/standings?type=0&level=3", ttl_seconds = 900)
    if r.status_code != 200:
        return txt("STANDINGS UNAVAILABLE", "#8FAABD")
    entries = []
    for conference in r.json().get("children", []):
        for division in conference.get("children", []):
            if any([t.get("team", {}).get("abbreviation") == favorite for t in division.get("standings", {}).get("entries", [])]):
                entries = division.get("standings", {}).get("entries", [])
    if not entries:
        return txt("STANDINGS UNAVAILABLE", "#8FAABD")
    cells = []
    for i, t in enumerate(entries):
        abbr = t.get("team", {}).get("abbreviation", "?")
        cells.append(txt("%s:%s   " % (i + 1, abbr), "#FFD438" if abbr == favorite else "#FFFFFF"))
    return render.Marquee(width = 64, child = render.Row(children = cells))

def pregame(event, c, away, home, league, favorite, timezone):
    height = 24
    when = stamp(event["date"]).in_location(timezone)
    today = time.now().in_location(timezone).format("2006-01-02") == when.format("2006-01-02")
    label = "START" if today and league == "mlb" else when.format("Mon").upper()
    info = render.Column(cross_align = "center", children = ([txt(label, "#8FAABD")] if label else []) + [txt(when.format("3:04") if c.get("timeValid", True) else "TBD", font = "5x8")])
    cols = [render.Box(width = 23, height = height, color = "#000000", child = render.Padding(pad = (2, 0, 0, 0), child = info)), render.Box(width = 1, height = height, color = "#FFFFFF")]
    for t in [away, home]:
        team = t.get("team", {})
        cols.append(render.Box(width = 20, height = height, color = teamcolor(team, league), child = render.Column(cross_align = "center", children = [render.Box(width = 20, height = 17, child = logo(team, league, 14)), render.Box(width = 1, height = 1), txt(team.get("abbreviation", "?"), secondary(team, league))])))
    return render.Column(cross_align = "start", children = [render.Row(children = cols), render.Box(width = 64, height = 8, color = "#401016", child = nfl_ticker(favorite))])

def field_position(c):
    sit = c.get("situation", {})
    text = sit.get("possessionText", "").upper().strip()
    if not text:
        description = sit.get("downDistanceText", "")
        text = description.upper().split(" AT ")[-1] if " AT " in description.upper() else ""
    parts = text.split(" ")
    if len(parts) == 2 and parts[1].isdigit() and int(parts[1]) <= 50:
        codes = [t.get("team", {}).get("abbreviation", "") for t in c.get("competitors", [])]
        if parts[0] in codes:
            return parts[0] + parts[1]
    if text in ["50", "50 YD", "MIDFIELD"]:
        return "50 YD"
    return ""

def field_position_widget(c):
    spot = field_position(c)
    if spot == "50 YD":
        return txt("50", "#8FAABD")
    for t in c.get("competitors", []):
        abbr = t.get("team", {}).get("abbreviation", "")
        if abbr and spot.startswith(abbr):
            yards = spot[len(abbr):]
            pattern = ["00100", "01110", "11111", "00100", "00100"]
            if t.get("homeAway") == "home":
                pattern = list(reversed(pattern))
            arrow = render.Column(children = [render.Row(children = [render.Box(width = 1, height = 1, color = "#8FAABD" if pixel == "1" else "#000000") for pixel in row.elems()]) for row in pattern])
            return render.Row(children = [arrow, render.Box(width = 2, height = 1), txt(yards, "#8FAABD")])
    return render.Box(width = 1, height = 1)

def timeout_count(c, t):
    side = t.get("homeAway", "")
    value = c.get("situation", {}).get(side + "Timeouts") if side in ["home", "away"] else None
    return int(value) if type(value) in ["int", "float"] and value == int(value) and value >= 0 and value <= 3 else None

def nfl_teamrow(c, t, state):
    team = t.get("team", {})
    bg = teamcolor(team, "nfl")
    if state == "post":
        numbers = render.Column(cross_align = "center", children = [render.Box(width = 17, height = 1), render.Box(width = 17, height = 6, child = txt(team.get("abbreviation", "?"), secondary(team, "nfl"), font = "CG-pixel-4x5-mono")), render.Box(width = 17, height = 8, child = txt(score(t, state), font = "5x8")), render.Box(width = 17, height = 1)])
        return render.Box(width = 32, height = 16, color = bg, child = render.Row(children = [render.Box(width = 15, height = 16, child = logo(team, "nfl", 13)), numbers]))
    count = timeout_count(c, t) if state == "in" else None
    bars = []
    for i in range(3):
        bars.extend([render.Box(width = 5, height = 1, color = "#FFFFFF" if count != None and i < count else bg), render.Box(width = 1, height = 1)])
    numbers = render.Column(cross_align = "center", children = [render.Box(width = 20, height = 1), render.Box(width = 20, height = 6, child = txt(team.get("abbreviation", "?"), secondary(team, "nfl"), font = "CG-pixel-4x5-mono")), render.Box(width = 20, height = 7, child = txt(score(t, state), font = "CG-pixel-4x5-mono")), render.Box(width = 20, height = 2, child = render.Column(cross_align = "center", children = [render.Row(children = bars), render.Box(width = 20, height = 1)]))])
    has_ball = possession_id(c) == str(t.get("id", "")) and possession_id(c) != ""
    return render.Box(width = 43, height = 16, color = bg, child = render.Stack(children = [render.Padding(pad = (1, 0, 0, 0), child = render.Row(children = [render.Box(width = 17, height = 16, child = logo(team, "nfl", 14)), numbers])), render.Padding(pad = (37, 0, 0, 0), child = render.Box(width = 6, height = 16, child = render.Box(width = 2, height = 2, color = "#FFFFFF" if has_ball else bg)))]))

def possession_id(c):
    kind = c.get("status", {}).get("type", {})
    if kind.get("state") != "in" or kind.get("name") in ["STATUS_HALFTIME", "STATUS_END_PERIOD", "STATUS_SUSPENDED", "STATUS_DELAYED"]:
        return ""
    ident = str(c.get("situation", {}).get("possession", ""))
    return ident if ident in [str(t.get("id", "")) for t in c.get("competitors", [])] else ""

def compact_clock(value):
    glyphs = {"0": ["111", "101", "101", "101", "111"], "1": ["010", "110", "010", "010", "111"], "2": ["111", "001", "111", "100", "111"], "3": ["111", "001", "111", "001", "111"], "4": ["101", "101", "111", "001", "001"], "5": ["111", "100", "111", "001", "111"], "6": ["111", "100", "111", "101", "111"], "7": ["111", "001", "010", "010", "010"], "8": ["111", "101", "111", "101", "111"], "9": ["111", "101", "111", "001", "111"], ":": ["0", "1", "0", "1", "0"], "-": ["000", "000", "111", "000", "000"]}
    chars = []
    for i, ch in enumerate(value.elems()):
        if i:
            chars.append(render.Box(width = 1, height = 5))
        chars.append(render.Column(children = [render.Row(children = [render.Box(width = 1, height = 1, color = "#FFFFFF" if px == "1" else "#000000") for px in row.elems()]) for row in glyphs.get(ch, glyphs["-"])]))
    return render.Row(children = chars)

def page(event, league, detail = None, favorite = "PHI", timezone = "America/New_York"):
    c = event["competitions"][0]
    status = c.get("status", {})
    kind = status.get("type", {})
    state = kind.get("state", "")
    teams = c.get("competitors", [])
    away = [t for t in teams if t.get("homeAway") == "away"]
    home = [t for t in teams if t.get("homeAway") == "home"]
    if not away or not home:
        return render.Box(child = txt("NO TEAM DATA"))
    if state == "pre" and kind.get("name") not in ["STATUS_POSTPONED", "STATUS_CANCELED", "STATUS_SUSPENDED"]:
        return pregame(event, c, away[0], home[0], league, favorite, timezone)

    # Football: status strip left; two large team-color columns on the right.
    if state == "in":
        label = "Q" + whole_number(status.get("period"))
        if status.get("period", 0) > 4:
            label = "OT"
        clock = status.get("displayClock", "")
        label = "HALF" if kind.get("name") == "STATUS_HALFTIME" else label
        value = (detail or clock or "--:--").replace("1ST", "1").replace("2ND", "2").replace("3RD", "3").replace("4TH", "4").replace("GOAL", "G")
        parts = value.replace("&", " & ").split(" ") if len(value) > 5 else [value]
        spot = field_position(c) if detail else ""
        info = render.Column(cross_align = "center", children = [txt(label, "#FFD438", font = "CG-pixel-3x5-mono"), render.Box(width = 1, height = 3)] + [compact_clock(part) if ":" in part else txt(part, font = "CG-pixel-3x5-mono") for part in parts if part] + ([render.Box(width = 1, height = 1), field_position_widget(c)] if spot else []))
    else:
        info = statuspanel(event, c, kind, state, compact = True, timezone = timezone)
    rows = render.Column(cross_align = "center", children = [nfl_teamrow(c, away[0], state), nfl_teamrow(c, home[0], state)])
    return render.Row(children = [render.Box(width = 31 if state == "post" else 20, height = 32, color = "#000000", child = info), render.Box(width = 1, height = 32, color = "#FFFFFF"), rows])

TEAMS = {"ARI": "Cardinals", "ATL": "Falcons", "BAL": "Ravens", "BUF": "Bills", "CAR": "Panthers", "CHI": "Bears", "CIN": "Bengals", "CLE": "Browns", "DAL": "Cowboys", "DEN": "Broncos", "DET": "Lions", "GB": "Packers", "HOU": "Texans", "IND": "Colts", "JAX": "Jaguars", "KC": "Chiefs", "LV": "Raiders", "LAC": "Chargers", "LAR": "Rams", "MIA": "Dolphins", "MIN": "Vikings", "NE": "Patriots", "NO": "Saints", "NYG": "Giants", "NYJ": "Jets", "PHI": "Philadelphia", "PIT": "Steelers", "SF": "49Ers", "SEA": "Seahawks", "TB": "Buccaneers", "TEN": "Titans", "WSH": "Commanders"}

def main(config):
    favorite = config.get("team", "PHI").upper()
    if favorite not in TEAMS:
        return message("nfl", "CHOOSE TEAM")
    timezone = config.get("timezone", "America/New_York")
    now = time.now()
    days = [now.in_location("America/New_York").format("20060102")]
    if int(now.in_location("America/New_York").format("15")) < 6:
        days.append(time.from_timestamp(now.unix - 86400).in_location("America/New_York").format("20060102"))
    live_events = []
    for day in days:
        board = http.get("https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard?dates=%s&limit=100" % day, ttl_seconds = 10)
        if board.status_code == 200:
            for event in board.json().get("events", []):
                c = event.get("competitions", [{}])[0]
                teams = [t.get("team", {}).get("abbreviation") for t in c.get("competitors", [])]
                if favorite in teams and c.get("status", {}).get("type", {}).get("state") == "in":
                    live_events.append(event)
    if live_events:
        events = live_events[:1]
    else:
        schedule = http.get("https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams/%s/schedule" % favorite.lower(), ttl_seconds = 300)
        if schedule.status_code != 200:
            return message("nfl", "UNAVAILABLE")
        events = choose(schedule.json().get("events", []), now.unix)
        upcoming = [e for e in events if e["competitions"][0].get("status", {}).get("type", {}).get("state") == "pre"]
        if upcoming:
            events = upcoming[:1]
    if not events:
        return message("nfl", "NO GAME LISTED")
    pages = []
    for event in events:
        c = event["competitions"][0]
        sit = c.get("situation", {})
        if c.get("status", {}).get("type", {}).get("state") == "in":
            if "homeTimeouts" not in sit or "awayTimeouts" not in sit:
                eventid = event["id"]
                extra = http.get("https://sports.core.api.espn.com/v2/sports/football/leagues/nfl/events/%s/competitions/%s/situation" % (eventid, c.get("id", eventid)), ttl_seconds = 10)
                if extra.status_code == 200:
                    for field in ["homeTimeouts", "awayTimeouts"]:
                        if field in extra.json():
                            sit[field] = extra.json()[field]
                    c["situation"] = sit
        pages.append(page(event, "nfl", favorite = favorite, timezone = timezone))
        detail = sit.get("shortDownDistanceText", "").upper().replace(" & ", "&") if possession_id(c) else ""
        if detail:
            pages.append(page(event, "nfl", detail, favorite = favorite, timezone = timezone))
    return render.Root(delay = 5000, child = render.Animation(children = pages))

def get_schema():
    return schema.Schema(version = "1", fields = [
        schema.Dropdown(id = "team", name = "Favorite team", desc = "Team to follow", icon = "flag", default = "PHI", options = [schema.Option(display = TEAMS[k], value = k) for k in sorted(TEAMS)]),
        schema.Text(id = "timezone", name = "Time zone", desc = "IANA time zone, such as America/New_York", icon = "clock", default = "America/New_York"),
        schema.Toggle(id = "game_focus", name = "Game-time focus", desc = "Companion required: keep this app on screen during your team's live game", icon = "flag", default = True),
        schema.Dropdown(id = "celebrate", name = "Celebrate touchdowns", desc = "Companion required: choose whose touchdowns trigger the animation", icon = "flag", default = "either", options = [schema.Option(display = "Either team", value = "either"), schema.Option(display = "My team only", value = "favorite")]),
    ])
