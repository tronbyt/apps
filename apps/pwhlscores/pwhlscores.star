"""
Applet: PWHL Scores
Summary: PWHL scores and schedule
Description: Live PWHL game scores, or the next/most-recent game when nothing is live. Optionally filter to a single favorite team. Data and logos from the PWHL (HockeyTech) feed.
Author: hiawatha98
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

KEY = "446521baf8c38984"
CLIENT = "pwhl"

# Scorebar: recent + upcoming games (windowed to keep the payload small).
SCOREBAR_URL = (
    "https://lscluster.hockeytech.com/feed/index.php?feed=modulekit&view=scorebar" +
    "&numberofdaysback=21&numberofdaysahead=120&key=" + KEY + "&client_code=" + CLIENT
)

# Season list, used to find the current season for the favorite-team dropdown.
# Hardcoding a season_id goes stale every year (and hides expansion teams).
SEASONS_URL = (
    "https://lscluster.hockeytech.com/feed/index.php?feed=modulekit&view=seasons" +
    "&key=" + KEY + "&client_code=" + CLIENT
)

DEFAULT_LOCATION = '{"timezone": "America/New_York"}'

ISO_FMT = "2006-01-02T15:04:05Z07:00"
LIVE_WINDOW = "5h"  # treat a non-final game started within this window as live

BAR_LIVE = "#cc2222"
BAR_FINAL = "#444444"
BAR_NEXT = "#1a6dc1"
WHITE = "#ffffff"
AMBER = "#ffb300"

def main(config):
    team = config.get("team", "all")
    tz = json.decode(config.get("location", DEFAULT_LOCATION))["timezone"]
    now = time.now().in_location(tz)

    games = fetch_games()
    if games == None:
        return message("No data")

    if team != "all":
        games = [g for g in games if g["HomeID"] == team or g["VisitorID"] == team]

    if len(games) == 0:
        return message("No games")

    game = pick_game(games, now)
    return render_game(game, now, tz)

def fetch_games():
    resp = http.get(SCOREBAR_URL, ttl_seconds = 60)
    if resp.status_code != 200:
        return None
    return json.decode(resp.body())["SiteKit"]["Scorebar"]

def parse_start(game):
    return time.parse_time(game["GameDateISO8601"], format = ISO_FMT)

def is_final(game):
    return game["GameStatus"] == "4" or game["GameStatusString"] == "Final"

def pick_game(games, now):
    # Prefer a live game; else the soonest upcoming; else the most recent final.
    window = time.parse_duration(LIVE_WINDOW)
    live = None
    upcoming = None
    past = None
    for g in games:
        st = parse_start(g)
        final = is_final(g)
        if not final and st <= now and now - st < window:
            if live == None or st < live[0]:
                live = (st, g)
        elif not final and st > now:
            if upcoming == None or st < upcoming[0]:
                upcoming = (st, g)
        elif past == None or st > past[0]:
            past = (st, g)

    chosen = live or upcoming or past
    return chosen[1] if chosen != None else games[0]

def render_game(game, now, tz):
    away_logo = fetch_logo(game["VisitorLogo"])
    home_logo = fetch_logo(game["HomeLogo"])
    st = parse_start(game)

    if is_final(game):
        bar_color = BAR_FINAL
        bar_text = final_text(game)
        center = score_widget(game)
    elif st > now:
        bar_color = BAR_NEXT
        bar_text = st.in_location(tz).format("Jan 2 3:04 PM")
        center = render.Text(content = "VS", font = "tom-thumb", color = AMBER)
    else:
        bar_color = BAR_LIVE
        bar_text = live_text(game)
        center = score_widget(game)

    return render.Root(
        child = render.Column(
            children = [
                status_bar(bar_color, bar_text),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "center",
                    children = [
                        team_widget(away_logo, game["VisitorCode"]),
                        center,
                        team_widget(home_logo, game["HomeCode"]),
                    ],
                ),
            ],
        ),
    )

def status_bar(color, text):
    return render.Box(
        width = 64,
        height = 7,
        color = color,
        child = render.Marquee(
            width = 62,
            child = render.Text(content = text, font = "tom-thumb", color = WHITE),
        ),
    )

def team_widget(logo, code):
    if logo != None:
        child = render.Image(src = logo, width = 22, height = 22)
    else:
        child = render.Text(content = code, font = "tom-thumb", color = WHITE)
    return render.Box(width = 24, height = 24, child = child)

def score_widget(game):
    return render.Text(
        content = "%s-%s" % (game["VisitorGoals"], game["HomeGoals"]),
        font = "tb-8",
        color = WHITE,
    )

def final_text(game):
    if game["PeriodNameShort"] == "SO":
        return "FINAL/SO"
    if int(game["Period"]) > 3:
        return "FINAL/OT"
    return "FINAL"

def live_text(game):
    if game["Intermission"] == "1":
        return game["PeriodNameShort"] + " INT"
    return game["PeriodNameShort"] + " " + game["GameClock"]

def fetch_logo(url):
    if url == "":
        return None
    resp = http.get(url, ttl_seconds = 86400)
    if resp.status_code != 200:
        return None
    return resp.body()

def message(text):
    return render.Root(
        child = render.Box(
            child = render.WrappedText(content = text, font = "tom-thumb", align = "center"),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "team",
                name = "Team",
                desc = "Show only this team, or all teams.",
                icon = "users",
                options = get_team_options(),
                default = "all",
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Used to show game times in your local timezone.",
                icon = "locationDot",
            ),
        ],
    )

def get_team_options():
    options = [schema.Option(display = "All teams", value = "all")]
    for t in fetch_current_teams():
        options.append(schema.Option(display = t["name"], value = t["id"]))
    return options

def teams_url(season_id):
    return (
        "https://lscluster.hockeytech.com/feed/index.php?feed=modulekit&view=teamsbyseason" +
        "&season_id=" + season_id + "&key=" + KEY + "&client_code=" + CLIENT
    )

def fetch_current_teams():
    # Newest season first. A season can be published before its teams are
    # entered, which returns an empty list, so fall back to the previous one.
    for season_id in fetch_season_ids()[:4]:
        resp = http.get(teams_url(season_id), ttl_seconds = 86400)
        if resp.status_code != 200:
            continue
        teams = json.decode(resp.body())["SiteKit"]["Teamsbyseason"]
        if len(teams) > 0:
            return teams
    return []

def fetch_season_ids():
    resp = http.get(SEASONS_URL, ttl_seconds = 86400)
    if resp.status_code != 200:
        return []
    ids = [int(s["season_id"]) for s in json.decode(resp.body())["SiteKit"]["Seasons"]]
    return [str(i) for i in sorted(ids, reverse = True)]
