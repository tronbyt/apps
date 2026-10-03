"""
Applet: PWHL Scores
Summary: PWHL scores and schedule
Description: Live PWHL game scores, or the next/most-recent game when nothing is live. Optionally filter to a single favorite team. Data and logos from the PWHL (HockeyTech) feed.
Author: hiawatha98
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
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
LIVE_WINDOW = "5h"  # a started game is only treated as live for this long

# HockeyTech publishes no status enum, so match on GameStatusString's text
# rather than on numeric codes. "Unofficial Final" contains "final" and so
# counts as complete, which is what we want: the score is real, only the stats
# are still being verified.
LIVE_STATUS = "2"
DISRUPTED_MARKS = ["postpone", "suspend", "cancel", "delay"]

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

    kind, game = pick_game(games, now)
    if game == None:
        return message("No games")

    return render_game(kind, game, tz)

def fetch_games():
    resp = http.get(SCOREBAR_URL, ttl_seconds = 60)
    if resp.status_code != 200:
        return None
    return json.decode(resp.body())["SiteKit"]["Scorebar"]

def parse_start(game):
    return time.parse_time(game["GameDateISO8601"], format = ISO_FMT)

def status_text(game):
    return game.get("GameStatusString", "").lower()

def is_final(game):
    return game.get("GameStatus", "") == "4" or "final" in status_text(game)

def is_disrupted(game):
    text = status_text(game)
    for mark in DISRUPTED_MARKS:
        if mark in text:
            return True
    return False

def period_number(game):
    period = game.get("Period", "")
    return int(period) if period.isdigit() else 0

def is_live(game, start, now, window):
    # Require a positive in-progress signal. Treating "started and not final" as
    # live shows postponed and suspended games as though they were being played,
    # with whatever period and clock the feed happens to carry.
    if game.get("GameStatus", "") == LIVE_STATUS:
        return True
    if start > now or now - start >= window:
        return False
    return period_number(game) > 0

def pick_game(games, now):
    # Prefer a live game; else the soonest upcoming; else the most recent final.
    # A game that matches none of those - disrupted, or started long ago and
    # never finalised - is left out rather than shown as something it is not.
    window = time.parse_duration(LIVE_WINDOW)
    live = None
    upcoming = None
    past = None
    for g in games:
        if is_disrupted(g):
            continue
        start = parse_start(g)
        if is_final(g):
            if past == None or start > past[0]:
                past = (start, g)
        elif is_live(g, start, now, window):
            if live == None or start < live[0]:
                live = (start, g)
        elif start > now:
            if upcoming == None or start < upcoming[0]:
                upcoming = (start, g)

    if live != None:
        return ("live", live[1])
    if upcoming != None:
        return ("next", upcoming[1])
    if past != None:
        return ("final", past[1])
    return (None, None)

def render_game(kind, game, tz):
    scale = 2 if is_2x() else 1
    away_logo = fetch_logo(game["VisitorLogo"])
    home_logo = fetch_logo(game["HomeLogo"])

    if kind == "final":
        bar_color = BAR_FINAL
        bar_text = final_text(game)
        center = score_widget(game, scale)
    elif kind == "next":
        bar_color = BAR_NEXT
        bar_text = parse_start(game).in_location(tz).format("Jan 2 3:04 PM")
        center = render.Text(content = "VS", font = small_font(scale), color = AMBER)
    else:
        bar_color = BAR_LIVE
        bar_text = live_text(game)
        center = score_widget(game, scale)

    return render.Root(
        child = render.Column(
            children = [
                status_bar(bar_color, bar_text, scale),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "center",
                    children = [
                        team_widget(away_logo, game["VisitorCode"], scale),
                        center,
                        team_widget(home_logo, game["HomeCode"], scale),
                    ],
                ),
            ],
        ),
    )

def is_2x():
    # canvas.is2x() is the documented signal, but the released pixlet CLI never
    # sets it, so treat a double-width canvas as 2x too. Both hold on real 2x
    # hardware, and the second keeps the layout testable with -w 128 -t 64.
    return canvas.is2x() or canvas.width() >= 128

def small_font(scale):
    # terminus-16 is the default 2x font, but it is too tall for the status bar;
    # terminus-12 keeps the same proportions the 1x bar has with tom-thumb.
    return "terminus-12" if scale == 2 else "tom-thumb"

def score_font(scale):
    return "terminus-16" if scale == 2 else "tb-8"

def status_bar(color, text, scale):
    return render.Box(
        width = canvas.width(),
        height = 7 * scale,
        color = color,
        child = render.Marquee(
            width = canvas.width() - 2 * scale,
            child = render.Text(content = text, font = small_font(scale), color = WHITE),
        ),
    )

def team_widget(logo, code, scale):
    if logo != None:
        child = render.Image(src = logo, width = 22 * scale, height = 22 * scale)
    else:
        child = render.Text(content = code, font = small_font(scale), color = WHITE)
    return render.Box(width = 24 * scale, height = 24 * scale, child = child)

def score_widget(game, scale):
    return render.Text(
        content = "%s-%s" % (game["VisitorGoals"], game["HomeGoals"]),
        font = score_font(scale),
        color = WHITE,
    )

def final_text(game):
    if game.get("PeriodNameShort", "") == "SO":
        return "FINAL/SO"
    if period_number(game) > 3:
        return "FINAL/OT"
    return "FINAL"

def live_text(game):
    if game.get("Intermission", "") == "1":
        return game.get("PeriodNameShort", "") + " INT"
    return game.get("PeriodNameShort", "") + " " + game.get("GameClock", "")

def fetch_logo(url):
    if url == "":
        return None
    resp = http.get(url, ttl_seconds = 86400)
    if resp.status_code != 200:
        return None
    return resp.body()

def message(text):
    scale = 2 if is_2x() else 1
    return render.Root(
        child = render.Box(
            child = render.WrappedText(content = text, font = small_font(scale), align = "center"),
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
