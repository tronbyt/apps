"""
Applet: PWHL Scores
Summary: PWHL scores and schedule
Description: Live PWHL game scores in a scorebug layout. After a game ends, the final alternates with the next game for a while. Optionally filter to a single favorite team. Data and logos from the PWHL (HockeyTech) feed.
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

# After a game goes final it alternates with the next game until this long
# after its scheduled start. 18h holds a 7 PM game's final until about 1 PM
# the next day; a game that starts sooner takes over once it is live.
FINAL_HOLD = "18h"

# Each frame of the final/next pair is shown this long. Tronbyt cuts an app
# off at its display time (8s by default on this device) unless "show full
# animation" is on, so two 4s frames fit the slot; a longer slot just loops.
PAIR_FRAME_MS = 4000

# HockeyTech publishes no status enum, so match on GameStatusString's text
# rather than on numeric codes. "Unofficial Final" contains "final" and so
# counts as complete, which is what we want: the score is real, only the stats
# are still being verified.
LIVE_STATUS = "2"
DISRUPTED_MARKS = ["postpone", "suspend", "cancel", "delay"]

# 1px strip across the top: the only remnant of the old status bar.
STRIP_LIVE = "#cc2222"
STRIP_FINAL = "#444444"
STRIP_NEXT = "#1a6dc1"

WHITE = "#ffffff"
GRAY = "#8a8a8a"
DIM = "#6a6a6a"
AMBER = "#ffb300"
LIVE_RED = "#ff4040"

ORDINALS = {1: "1ST", 2: "2ND", 3: "3RD"}

def main(config):
    team = config.get("team", "all")
    tz = json.decode(config.get("location", DEFAULT_LOCATION))["timezone"]
    now = time.now().in_location(tz)

    games = fetch_games()
    if games == None:
        return message("No data")

    if team != "all":
        games = [g for g in games if g["HomeID"] == team or g["VisitorID"] == team]

    live, upcoming, past = pick_games(games, now)
    scale = 2 if is_2x() else 1

    if live != None:
        return render.Root(child = scorebug(live, "live", scale, now, tz))

    fresh_final = past != None and now - parse_start(past) < time.parse_duration(FINAL_HOLD)
    if fresh_final and upcoming != None:
        return render.Root(
            delay = PAIR_FRAME_MS,
            child = render.Animation(children = [
                scorebug(past, "final", scale, now, tz),
                scorebug(upcoming, "next", scale, now, tz),
            ]),
        )
    if upcoming != None and not fresh_final:
        return render.Root(child = scorebug(upcoming, "next", scale, now, tz))
    if past != None:
        return render.Root(child = scorebug(past, "final", scale, now, tz))
    return message("No games")

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

def is_shootout(game):
    return game.get("PeriodNameShort", "").upper() == "SO"

def is_live(game, start, now, window):
    # Require a positive in-progress signal. Treating "started and not final" as
    # live shows postponed and suspended games as though they were being played,
    # with whatever period and clock the feed happens to carry.
    if game.get("GameStatus", "") == LIVE_STATUS:
        return True
    if start > now or now - start >= window:
        return False
    return period_number(game) > 0

def pick_games(games, now):
    # Returns (live, upcoming, past): the earliest-started live game, the
    # soonest upcoming game, and the most recent final. A game that matches
    # none of those - disrupted, or started long ago and never finalised - is
    # left out rather than shown as something it is not.
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
    return (
        live[1] if live != None else None,
        upcoming[1] if upcoming != None else None,
        past[1] if past != None else None,
    )

# ---------------------------------------------------------------------------
# Labels. The feed's PeriodNameShort is a bare "1"/"2"/"3" and GameClock is
# zero-padded ("06:49"), so both are rebuilt here rather than shown as-is.

def period_label(game):
    if is_shootout(game):
        return "SO"
    n = period_number(game)
    if n in ORDINALS:
        return ORDINALS[n]
    if n == 4:
        return "OT"
    if n > 4:
        return "%dOT" % (n - 3)  # playoff multi-OT: 5 -> 2OT
    return game.get("PeriodNameShort", "").upper()

def clock_label(game):
    clock = game.get("GameClock", "")
    if clock.startswith("0") and len(clock) > 1 and clock[1] != ":":
        clock = clock[1:]  # "06:49" -> "6:49", but "0:42" stays
    return clock

def final_suffix(game):
    if is_shootout(game):
        return "SO"
    if period_number(game) > 3:
        return "OT" if period_number(game) == 4 else "%dOT" % (period_number(game) - 3)
    return ""

def day_label(start, now):
    if start.format("2006-01-02") == now.format("2006-01-02"):
        return "TODAY"
    if start - now < time.parse_duration("144h"):
        return start.format("Mon").upper()  # within the week: TUE
    return start.format("1/2")  # further out: 11/30

# ---------------------------------------------------------------------------
# Layout (1x numbers; everything is multiplied by scale on 2x hardware):
#   row 0       1px colour strip (red live / gray final / blue next)
#   rows 6-25   20x20 logos at x=1 and x=43
#   x 21-42     22px centre column: a vertically centred stack of lines

def scorebug(game, kind, scale, now, tz):
    if kind == "live":
        strip, center = STRIP_LIVE, live_center(game, scale)
    elif kind == "final":
        strip, center = STRIP_FINAL, final_center(game, scale)
    else:
        start = parse_start(game).in_location(tz)
        strip, center = STRIP_NEXT, next_center(start, now, scale)

    return render.Column(
        children = [
            render.Box(width = canvas.width(), height = scale, color = strip),
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    logo_widget(game["VisitorLogo"], game["VisitorCode"], scale),
                    render.Box(width = 22 * scale, height = canvas.height() - scale, child = center),
                    logo_widget(game["HomeLogo"], game["HomeCode"], scale),
                ],
            ),
        ],
    )

def is_intermission(game):
    # The feed's Intermission flag stays "0" during real intermissions; what it
    # does do is freeze GameClock at "00:00" for the period that just ended.
    if game.get("Intermission", "") == "1":
        return True
    return period_number(game) > 0 and game.get("GameClock", "").replace(":", "").strip("0") == ""

def live_center(game, scale):
    if is_shootout(game):
        line1, color1, line2 = "SO", LIVE_RED, ""
    elif is_intermission(game):
        line1, color1, line2 = "END", AMBER, period_label(game)
    else:
        line1, color1, line2 = period_label(game), LIVE_RED, clock_label(game)
    return stack([
        score_row(game, scale, False),
        gap(3, scale),
        small(line1, color1, scale),
        gap(1, scale),
        small(line2, WHITE, scale),
    ])

def final_center(game, scale):
    return stack([
        score_row(game, scale, True),
        gap(3, scale),
        small("FINAL", GRAY, scale),
        gap(1, scale),
        small(final_suffix(game), AMBER, scale),
    ])

def next_center(start, now, scale):
    return stack([
        small(day_label(start, now), AMBER, scale),
        render.Text(content = start.format("3:04"), font = score_font(scale), color = WHITE),
        gap(1, scale),
        small(start.format("PM"), GRAY, scale),
    ])

def stack(children):
    return render.Column(main_align = "center", cross_align = "center", children = children)

def gap(px, scale):
    return render.Box(width = 1, height = px * scale)

def small(text, color, scale):
    # An empty line still takes its height so the stack doesn't shift between
    # FINAL and FINAL/OT.
    if text == "":
        return render.Box(width = 1, height = small_height(scale))
    return render.Text(content = text, font = small_font(scale), color = color)

def score_row(game, scale, dim_loser):
    away, home = game["VisitorGoals"], game["HomeGoals"]
    away_color, home_color = WHITE, WHITE
    if dim_loser and away.isdigit() and home.isdigit():
        if int(away) > int(home):
            home_color = DIM
        elif int(home) > int(away):
            away_color = DIM
    font = score_font(scale)
    return render.Row(children = [
        render.Text(content = away, font = font, color = away_color),
        render.Text(content = "-", font = font, color = GRAY),
        render.Text(content = home, font = font, color = home_color),
    ])

def logo_widget(url, code, scale):
    logo = fetch_logo(url)
    if logo != None:
        child = render.Image(src = logo, width = 20 * scale, height = 20 * scale)
    else:
        child = render.Text(content = code, font = small_font(scale), color = WHITE)
    return render.Box(width = 21 * scale, height = 20 * scale, child = child)

def is_2x():
    # canvas.is2x() is the documented signal, but the released pixlet CLI never
    # sets it, so treat a double-width canvas as 2x too. Both hold on real 2x
    # hardware, and the second keeps the layout testable with -w 128 -t 64.
    return canvas.is2x() or canvas.width() >= 128

def small_font(scale):
    return "terminus-12" if scale == 2 else "tom-thumb"

def small_height(scale):
    return 12 if scale == 2 else 6

def score_font(scale):
    return "terminus-16" if scale == 2 else "tb-8"

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
