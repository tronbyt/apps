"""Classic MLB: a Tidbyt-inspired 64x32 baseball scoreboard."""

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
    colors = {"mlb": {"PHI": "#C8102E", "ATL": "#13274F", "TB": "#092C5C", "NYM": "#002D72", "MIL": "#12284B"}}
    return colors.get(league, {}).get(abbr, "#" + team.get("color", "183C60"))

def secondary(team, league):
    abbr = team.get("abbreviation", "?")
    overrides = {"mlb": {"PHI": "#6BACE4", "BOS": "#0C2340", "TB": "#8FBCE6"}}
    if abbr in overrides.get(league, {}):
        return overrides[league][abbr]
    sport = "baseball"
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

def diamond(filled):
    rows = []
    for y in range(9):
        pixels = []
        for x in range(9):
            dist = abs(x - 4) + abs(y - 4)
            color = ("#FFD438" if filled else "#FFFFFF") if dist == 4 else ("#FFD438" if filled and dist < 4 else "#000000")
            pixels.append(render.Box(width = 1, height = 1, color = color) if dist <= 4 else render.Box(width = 1, height = 1))
        rows.append(render.Row(children = pixels))
    return render.Column(children = rows)

def inning_triangle(short):
    pattern = ["00100", "01110", "11111"]
    if "BOT" in short:
        pattern = list(reversed(pattern))
    if "TOP" not in short and "BOT" not in short:
        return render.Box(width = 5, height = 3)
    return render.Column(children = [render.Row(children = [render.Box(width = 1, height = 1, color = "#FFFFFF" if pixel == "1" else "#000000") for pixel in row.elems()]) for row in pattern])

def outbox(filled, known):
    return render.Box(width = 4, height = 4, color = "#FFD438" if filled else ("#707070" if known else "#48515B"), child = render.Box(width = 2, height = 2, color = "#FFD438" if filled else "#000000"))

def mlb_live_panel(status, kind, sit):
    # Coordinates measured on the reference64x32 LED grid; divider at global x32.
    def at(x, y, child):
        return render.Padding(pad = (x, y, 0, 0), child = child)

    outs = sit.get("outs")
    count = "%s-%s" % (whole_number(sit.get("balls")), whole_number(sit.get("strikes")))
    layers = [
        render.Box(width = 31, height = 32, color = "#000000"),
        at(11, 1, diamond(sit.get("onSecond", False))),
        at(5, 7, diamond(sit.get("onThird", False))),
        at(17, 7, diamond(sit.get("onFirst", False))),
        at(1, 23, inning_triangle(kind.get("shortDetail", "").upper())),
        at(7, 20, txt(whole_number(status.get("period")), font = "5x8")),
        at(15, 19, txt(count, font = "CG-pixel-4x5-mono")),
        at(18, 26, outbox(outs != None and outs > 0, outs != None)),
        at(23, 26, outbox(outs != None and outs > 1, outs != None)),
    ]
    return render.Box(width = 31, height = 32, color = "#000000", child = render.Stack(children = layers))

def teamtile(c, state, league):
    team = c.get("team", {})
    info = render.Column(cross_align = "center", children = [render.Box(width = 15, height = 1), render.Box(width = 15, height = 6, child = txt(team.get("abbreviation", "?"), secondary(team, league), font = "CG-pixel-3x5-mono")), render.Box(width = 15, height = 8, child = txt(score(c, state), font = "5x8")), render.Box(width = 15, height = 1)])
    return render.Box(width = 32, height = 16, color = teamcolor(team, league), child = render.Row(children = [render.Box(width = 17, height = 16, child = logo(team, league, 14)), render.Box(width = 15, height = 16, child = info)]))

def statuspanel(event, c, kind, state, zone, compact = False):
    when = stamp(event["date"]).in_location(zone)
    name = kind.get("name")
    if name in ["STATUS_POSTPONED", "STATUS_CANCELED", "STATUS_SUSPENDED"]:
        return render.Column(cross_align = "center", children = [txt({"STATUS_POSTPONED": "PPD", "STATUS_CANCELED": "CANC" if compact else "CANCELED", "STATUS_SUSPENDED": "SUSP"}[name], "#FFD438"), txt(when.format("1/2") if compact else when.format("Jan 2"))])
    if state == "pre":
        return render.Column(cross_align = "center", children = [txt("NEXT", "#8FAABD"), txt(when.format("Mon").upper()), txt(when.format("3:04") if c.get("timeValid", True) else "TBD", font = "tom-thumb" if compact else "5x8"), txt(when.format("PM") if c.get("timeValid", True) else "")])
    return render.Column(cross_align = "center", children = [txt("FINAL", "#FFD438"), render.Box(width = 1, height = 3), txt(when.format("1/2") if compact else when.format("Jan 2"))])

def pregame(event, c, away, home, league, zone, team_id):
    height = 24
    when = stamp(event["date"]).in_location(zone)
    today = time.now().in_location(zone).format("2006-01-02") == when.format("2006-01-02")
    label = "START" if today and league == "mlb" else when.format("Mon").upper()
    info = render.Column(cross_align = "center", children = ([txt(label, "#8FAABD")] if label else []) + [txt(when.format("3:04") if c.get("timeValid", True) else "TBD", font = "5x8")])
    cols = [render.Box(width = 23, height = height, color = "#000000", child = render.Padding(pad = (2, 0, 0, 0), child = info)), render.Box(width = 1, height = height, color = "#FFFFFF")]
    for t in [away, home]:
        team = t.get("team", {})
        cols.append(render.Box(width = 20, height = height, color = teamcolor(team, league), child = render.Column(cross_align = "center", children = [render.Box(width = 20, height = 17, child = logo(team, league, 14)), render.Box(width = 1, height = 1), txt(team.get("abbreviation", "?"), secondary(team, league))])))
    return render.Column(cross_align = "start", children = [render.Row(children = cols), render.Box(width = 64, height = 8, color = "#401016", child = division_ticker(team_id))])

TEAMS = [("ARI", "Arizona Diamondbacks", 109), ("ATH", "Athletics", 133), ("ATL", "Atlanta Braves", 144), ("BAL", "Baltimore Orioles", 110), ("BOS", "Boston Red Sox", 111), ("CHC", "Chicago Cubs", 112), ("CHW", "Chicago White Sox", 145), ("CIN", "Cincinnati Reds", 113), ("CLE", "Cleveland Guardians", 114), ("COL", "Colorado Rockies", 115), ("DET", "Detroit Tigers", 116), ("HOU", "Houston Astros", 117), ("KC", "Kansas City Royals", 118), ("LAA", "Los Angeles Angels", 108), ("LAD", "Los Angeles Dodgers", 119), ("MIA", "Miami Marlins", 146), ("MIL", "Milwaukee Brewers", 158), ("MIN", "Minnesota Twins", 142), ("NYM", "New York Mets", 121), ("NYY", "New York Yankees", 147), ("PHI", "Philadelphia Phillies", 143), ("PIT", "Pittsburgh Pirates", 134), ("SD", "San Diego Padres", 135), ("SEA", "Seattle Mariners", 136), ("SF", "San Francisco Giants", 137), ("STL", "St. Louis Cardinals", 138), ("TB", "Tampa Bay Rays", 139), ("TEX", "Texas Rangers", 140), ("TOR", "Toronto Blue Jays", 141), ("WSH", "Washington Nationals", 120)]

def division_ticker(team_id):
    r = http.get("https://statsapi.mlb.com/api/v1/standings?leagueId=103,104&standingsTypes=regularSeason", ttl_seconds = 900)
    if r.status_code != 200:
        return txt("STANDINGS UNAVAILABLE", "#8FAABD")
    divisions = [d for d in r.json().get("records", []) if any([t.get("team", {}).get("id") == team_id for t in d.get("teamRecords", [])])]
    if not divisions:
        return txt("STANDINGS UNAVAILABLE", "#8FAABD")
    codes = {t[2]: t[0] for t in TEAMS}
    cells = []
    for t in sorted(divisions[0].get("teamRecords", []), key = lambda t: int(t.get("divisionRank", "99"))):
        ident = t.get("team", {}).get("id")
        cells.append(txt("%s:%s   " % (whole_number(t.get("divisionRank")), codes.get(ident, "?")), "#FFD438" if ident == team_id else "#FFFFFF"))
    return render.Marquee(width = 64, child = render.Row(children = cells))

def page(event, zone, team_id):
    c = event["competitions"][0]
    status = c.get("status", {})
    kind = status.get("type", {})
    state = kind.get("state", "")
    away = [t for t in c.get("competitors", []) if t.get("homeAway") == "away"]
    home = [t for t in c.get("competitors", []) if t.get("homeAway") == "home"]
    if not away or not home:
        return txt("NO TEAM DATA")
    if state == "pre" and kind.get("name") not in ["STATUS_POSTPONED", "STATUS_CANCELED", "STATUS_SUSPENDED", "STATUS_DELAYED"]:
        return pregame(event, c, away[0], home[0], "mlb", zone, team_id)
    left = render.Column(cross_align = "center", children = [teamtile(away[0], state, "mlb"), teamtile(home[0], state, "mlb")])
    if kind.get("name") == "STATUS_DELAYED":
        right = render.Box(width = 31, height = 32, child = txt("DELAY"))
    elif state == "in":
        right = mlb_live_panel(status, kind, c.get("situation", {}))
    else:
        right = render.Box(width = 31, height = 32, child = statuspanel(event, c, kind, state, zone))
    return render.Row(children = [left, render.Box(width = 1, height = 32, color = "#FFFFFF"), right])

def eligible(event, now, role):
    if not event.get("competitions"):
        return False
    c = event["competitions"][0]
    kind = c.get("status", {}).get("type", {})
    season = event.get("season", {}).get("type", event.get("seasonType", {}).get("type"))
    age = now - stamp(event["date"]).unix
    return (role == "allgames" or whole_number(season) == "3") and kind.get("state") == "in" and not kind.get("completed", False) and kind.get("name") not in ["STATUS_POSTPONED", "STATUS_CANCELED", "STATUS_SUSPENDED"] and age >= -300 and age < 21600

def main(config):
    team = config.get("team", "PHI")
    choices = [t for t in TEAMS if t[0] == team]
    if not choices:
        return message("MLB", "SELECT TEAM")
    zone = config.get("timezone", "America/New_York")
    role = config.get("role", "rotation")
    focus = role != "rotation"
    now = time.now().unix
    base = "https://site.api.espn.com/apis/site/v2/sports/baseball/mlb/"
    events = {}

    # Scoreboard first: current game details should not wait for the schedule cache.
    today = time.now().in_location(zone)
    for offset in [-86400, 0]:
        day = time.from_timestamp(today.unix + offset).in_location(zone).format("20060102")
        r = http.get(base + "scoreboard?dates=" + day + "&limit=100", ttl_seconds = 10)
        if r.status_code == 200:
            for e in r.json().get("events", []):
                if any([t.get("team", {}).get("abbreviation") == team for t in e.get("competitions", [{}])[0].get("competitors", [])]):
                    events[e["id"]] = e
    live = [e for e in events.values() if e["competitions"][0].get("status", {}).get("type", {}).get("state") == "in" and now - stamp(e["date"]).unix >= 0 and now - stamp(e["date"]).unix < 64800]
    if focus:
        live = [e for e in live if eligible(e, now, role)]
        return render.Root(child = page(sorted(live, key = lambda e: e["date"])[0], zone, choices[0][2])) if live else []
    if live:
        return render.Root(child = page(sorted(live, key = lambda e: e["date"])[0], zone, choices[0][2]))
    for suffix in ["", "?seasontype=3"]:
        r = http.get(base + "teams/" + team.lower() + "/schedule" + suffix, ttl_seconds = 60)
        if r.status_code == 200:
            for e in r.json().get("events", []):
                if e["id"] not in events:
                    events[e["id"]] = e
    selected = choose(events.values(), now)
    if not selected:
        return message("MLB", "NO GAME LISTED")
    upcoming = [e for e in selected if e["competitions"][0].get("status", {}).get("type", {}).get("state") == "pre" and e["competitions"][0].get("status", {}).get("type", {}).get("name") not in ["STATUS_POSTPONED", "STATUS_CANCELED", "STATUS_SUSPENDED"]]
    if upcoming and not any([e["competitions"][0].get("status", {}).get("type", {}).get("name") in ["STATUS_POSTPONED", "STATUS_CANCELED", "STATUS_SUSPENDED"] for e in selected]):
        selected = upcoming[:1]
    return render.Root(delay = 5000, child = render.Animation(children = [page(e, zone, choices[0][2]) for e in selected]))

def get_schema():
    return schema.Schema(version = "1", fields = [
        schema.Dropdown(id = "team", name = "Team", desc = "Team to follow and highlight in division standings", icon = "flag", default = "PHI", options = [schema.Option(display = t[1], value = t[0]) for t in TEAMS]),
        schema.Text(id = "timezone", name = "Time zone", desc = "IANA time zone, e.g. America/New_York or America/Los_Angeles", icon = "clock", default = "America/New_York"),
        schema.Dropdown(id = "role", name = "App role", desc = "Keep Autopin OFF for normal rotation. For focus, add another copy and enable Autopin only on that copy. Focus ends when the game ends.", icon = "flag", default = "rotation", options = [schema.Option(display = "Normal rotation", value = "rotation"), schema.Option(display = "Postseason focus", value = "postseason"), schema.Option(display = "All-game focus", value = "allgames")]),
    ])
