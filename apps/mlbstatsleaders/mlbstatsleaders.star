"""
Applet: MLB Leader Stats
Summary: Displays MLB Leader Stats
Description: Displays live and upcoming MLB scores from a data feed.
Author: symm512
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

TEAM_COLORS = {
    "ARI": "#A71930",
    "ATL": "#132448",
    "BAL": "#DF4601",
    "BOS": "#BD3039",
    "CHC": "#0E3386",
    "CWS": "#222222",
    "CIN": "#C6011F",
    "CLE": "#00385D",
    "COL": "#33006F",
    "DET": "#0C2340",
    "HOU": "#002D62",
    "KCR": "#004687",
    "LAA": "#BA0021",
    "LAD": "#005A9C",
    "MIA": "#1F1F1F",
    "MIL": "#1F4E79",
    "MIN": "#002B5C",
    "NYM": "#FF5910",
    "NYY": "#0A193B",
    "ATH": "#004B3F",
    "PHI": "#E81828",
    "SD": "#2F241D",
    "PIT": "#2F2F2F",
    "SEA": "#008080",
    "SF": "#FD5A1E",
    "STL": "#C41E3A",
    "TB": "#092C5C",
    "TEX": "#003278",
    "TOR": "#1A5BBF",
    "WSH": "#AB0003",
}

TEAM_TEXT_COLORS = {
    "ARI": "#FFD1D8",
    "ATL": "#CE1141",
    "BAL": "#FFFFFF",
    "BOS": "#FFE0E2",
    "CHC": "#B7D0FF",
    "CWS": "#FFFFFF",
    "CIN": "#FFD0D6",
    "CLE": "#E31937",
    "COL": "#E6D6FF",
    "DET": "#B9CFFF",
    "HOU": "#FF6600",
    "KCR": "#C2DDFF",
    "LAA": "#FFD0D0",
    "LAD": "#FFFFFF",
    "MIA": "#00A3E0",
    "MIL": "#FFC72C",
    "MIN": "#FF3B3B",
    "NYM": "#FFE2D6",
    "NYY": "#FFFFFF",
    "ATH": "#F5C542",
    "PHI": "#FFFFFF",
    "PIT": "#FDB827",
    "SD": "#D6CEC7",
    "SEA": "#FFFFFF",
    "SF": "#FFE1C9",
    "STL": "#FFD0D6",
    "TB": "#BFD6FF",
    "TEX": "#BFD6FF",
    "TOR": "#FFFFFF",
    "WSH": "#DCDCDC",
}

DEFAULT_COLOR = "#333333"
DEFAULT_TEXT = "#FFFFFF"

TEAM_NAME_MAP = {
    "Arizona Diamondbacks": "ARI",
    "Atlanta Braves": "ATL",
    "Baltimore Orioles": "BAL",
    "Boston Red Sox": "BOS",
    "Chicago Cubs": "CHC",
    "Chicago White Sox": "CWS",
    "Cincinnati Reds": "CIN",
    "Cleveland Guardians": "CLE",
    "Colorado Rockies": "COL",
    "Detroit Tigers": "DET",
    "Houston Astros": "HOU",
    "Kansas City Royals": "KCR",
    "Los Angeles Angels": "LAA",
    "Los Angeles Dodgers": "LAD",
    "Miami Marlins": "MIA",
    "Milwaukee Brewers": "MIL",
    "Minnesota Twins": "MIN",
    "New York Mets": "NYM",
    "New York Yankees": "NYY",
    "Athletics": "ATH",
    "Philadelphia Phillies": "PHI",
    "Pittsburgh Pirates": "PIT",
    "San Diego Padres": "SD",
    "Seattle Mariners": "SEA",
    "San Francisco Giants": "SF",
    "St. Louis Cardinals": "STL",
    "Tampa Bay Rays": "TB",
    "Texas Rangers": "TEX",
    "Toronto Blue Jays": "TOR",
    "Washington Nationals": "WSH",
}

STAT_CONFIG = {
    "None": {"api": "NoneNada", "title": "NO LEADERS", "group": "hitting"},
    "G": {"api": "games", "title": "G LEADERS", "group": "hitting"},
    "AB": {"api": "atBats", "title": "AB LEADERS", "group": "hitting"},
    "R": {"api": "runs", "title": "R LEADERS", "group": "hitting"},
    "H": {"api": "hits", "title": "H LEADERS", "group": "hitting"},
    "2B": {"api": "doubles", "title": "2B LEADERS", "group": "hitting"},
    "3B": {"api": "triples", "title": "3B LEADERS", "group": "hitting"},
    "HR": {"api": "homeRuns", "title": "HR LEADERS", "group": "hitting"},
    "RBI": {"api": "runsBattedIn", "title": "RBI LEADERS", "group": "hitting"},
    "BB": {"api": "walks", "title": "BB LEADERS", "group": "hitting"},
    "SO": {"api": "strikeOuts", "title": "SO LEADERS", "group": "hitting"},
    "SB": {"api": "stolenBases", "title": "SB LEADERS", "group": "hitting"},
    "CS": {"api": "caughtStealing", "title": "CS LEADERS", "group": "hitting"},
    "AVG": {"api": "battingAverage", "title": "AVG LEADERS", "group": "hitting"},
    "OBP": {"api": "onBasePercentage", "title": "OBP LEADERS", "group": "hitting"},
    "SLG": {"api": "sluggingPercentage", "title": "SLG LEADERS", "group": "hitting"},
    "OPS": {"api": "onBasePlusSlugging", "title": "OPS LEADERS", "group": "hitting"},
    "HBP": {"api": "hitByPitches", "title": "HBP LEADERS", "group": "hitting"},
    "IW": {"api": "intentionalWalks", "title": "IW LEADERS", "group": "hitting"},
    "W": {"api": "wins", "title": "W LEADERS", "group": "pitching"},
    "L": {"api": "losses", "title": "L LEADERS", "group": "pitching"},
    "ERA": {"api": "earnedRunAverage", "title": "ERA LEADERS", "group": "pitching"},
    "GP": {"api": "gamesPlayed", "title": "G LEADERS", "group": "pitching"},
    "IP": {"api": "inningsPitched", "title": "IP LEADERS", "group": "pitching"},
    "HP": {"api": "hits", "title": "H LEADERS", "group": "pitching"},
    "RP": {"api": "runs", "title": "R LEADERS", "group": "pitching"},
    "HRP": {"api": "homeRuns", "title": "HR LEADERS", "group": "pitching"},
    "BBP": {"api": "walks", "title": "BB LEADERS", "group": "pitching"},
    "SOP": {"api": "strikeOuts", "title": "SO LEADERS", "group": "pitching"},
    "WHIP": {"api": "walksAndHitsPerInningPitched", "title": "WHIP LEADERS", "group": "pitching"},
}

def get_team_color(team):
    return TEAM_COLORS.get(team, DEFAULT_COLOR)

def get_text_color(team):
    return TEAM_TEXT_COLORS.get(team, DEFAULT_TEXT)

def format_name(full_name, stat_key):
    name = full_name.split(" ")[-1]
    if stat_key == "OPS":
        return name[:8]
    return name[:9]

def normalize(s):
    return (s or "").lower().replace(" ", "").replace("-", "")

def fetch_leaders(stat_key):
    if stat_key == "None":
        return []

    config = STAT_CONFIG[stat_key]
    url = "https://statsapi.mlb.com/api/v1/stats/leaders?leaderCategories={}&statGroup={}&season={}".format(
        config["api"],
        config["group"],
        time.now().year,
    )
    res = http.get(url, ttl_seconds = 3600)
    if res.status_code != 200:
        return []

    data = res.json()
    league_leaders = data.get("leagueLeaders")
    if not league_leaders or len(league_leaders) == 0:
        return []
    leaders_data = league_leaders[0].get("leaders", [])
    leaders = []

    for l in leaders_data[:5]:
        leaders.append({
            "name": format_name(l["person"]["fullName"], stat_key),
            "team": TEAM_NAME_MAP.get(l["team"].get("name"), l["team"].get("abbreviation", l["team"].get("name", "???"))),
            "value": l["value"],
        })
    return leaders

def render_leader_row(leader):
    team_color = get_team_color(leader["team"])
    text_color = get_text_color(leader["team"])

    return render.Row(
        main_align = "space_between",
        cross_align = "center",
        expanded = True,
        children = [
            render.Box(
                width = 46,
                height = 5,
                color = team_color,
                child = render.Row(
                    main_align = "start",
                    cross_align = "center",
                    children = [
                        render.Box(width = 1, height = 5),
                        render.Text(
                            content = leader["name"],
                            font = "tom-thumb",
                            color = text_color,
                        ),
                    ],
                ),
            ),
            render.Text(
                content = str(leader["value"]),
                font = "tom-thumb",
                color = "#FFF",
            ),
        ],
    )

def render_stat_slide(stat_key, leaders):
    if not leaders:
        return []

    config = STAT_CONFIG[stat_key]
    rows = [
        render.Box(
            width = 64,
            height = 5,
            color = "#000",
            child = render.Text(
                content = config["title"],
                font = "tom-thumb",
                color = "#FFFF00",
            ),
        ),
    ]

    for l in leaders:
        rows.append(render_leader_row(l))

    return render.Column(children = rows)

def main(config):
    rotation_speed = int(config.get("speed", "3"))
    selected_stats = []
    for i in range(1, 11):
        stat = config.get("stat{}".format(i), "None")
        if stat != "None":
            selected_stats.append(stat)

    if not selected_stats:
        selected_stats = ["HR", "ERA"]

    slides = []
    for stat in selected_stats:
        leaders = fetch_leaders(stat)
        if leaders:
            slides.append(render_stat_slide(stat, leaders))

    if not slides:
        return render.Root(
            child = render.WrappedText("No Stats Found"),
        )

    return render.Root(
        delay = rotation_speed * 1000,
        child = render.Animation(children = slides),
    )

def get_schema():
    stat_options = [schema.Option(display = k, value = k) for k in STAT_CONFIG.keys()]
    stat_options = sorted(stat_options, key = lambda x: x.display)

    fields = [
        schema.Dropdown(
            id = "speed",
            name = "Rotation Speed",
            desc = "Seconds per stat",
            icon = "clock",
            default = "3",
            options = [
                schema.Option(display = "2s", value = "2"),
                schema.Option(display = "3s", value = "3"),
                schema.Option(display = "5s", value = "5"),
            ],
        ),
    ]

    for i in range(1, 11):
        fields.append(
            schema.Dropdown(
                id = "stat{}".format(i),
                name = "Stat {}".format(i),
                desc = "Select stat to display",
                icon = "trophy",
                default = "None",
                options = stat_options,
            ),
        )

    return schema.Schema(version = "1", fields = fields)
