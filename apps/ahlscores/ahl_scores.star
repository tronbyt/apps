"""
Applet: AHL Scores
Summary: Live, scheduled, and final scores for the American Hockey League
Description: Displays live, scheduled, and final scores for the American Hockey League (AHL) with team colors, official logos, and status indicators.
Author: zandif
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

CACHE_TTL_SECONDS = 120
DEFAULT_LOCATION = """
{
    "lat": "39.7392",
    "lng": "-104.9903",
    "description": "Denver, CO, USA",
    "locality": "Denver",
    "place_id": "ChIJzPO_n6zkbIcR-R-jP5j0t3I",
    "timezone": "America/Denver"
}
"""
LEAGUE_DISPLAY = "AHL"
LEAGUE_DISPLAY_OFFSET = -4

# Public AHL HockeyTech feed endpoint & public client key
AHL_FEED_URL = "https://lscluster.hockeytech.com/feed/index.php?feed=modulekit&view=scorebar&client_code=ahl&key=50c2cd9b5e18e390&fmt=json&lang=en"

DISRUPTED_KEYWORDS = ("postpone", "cancel", "suspend", "delay")

# Team colors: (Background / Primary, Text / Secondary).
# Note: Teams whose raw primary+secondary pairs have low contrast on an LED matrix
# (e.g., dark red on navy, red on forest green, black on red, or bright orange bg)
# use a dark team color for the background and a brightened team accent, tertiary
# team color (gold/wheat/ice blue), or white for readable text.
TEAM_COLORS = {
    "ABB": ("#00205B", "#4CE08A"),  # Brightened green for contrast on navy
    "BAK": ("#002F6C", "#FF7F32"),  # Brightened orange for contrast on navy
    "BEL": ("#000000", "#FF5C6C"),  # Brightened red for contrast on #222
    "CGY": ("#A60D26", "#F1BE48"),  # Deepened red for gold contrast
    "CLT": ("#B80000", "#FFFFFF"),  # White text instead of black on red
    "CHI": ("#8A100B", "#EED28C"),  # Burgundy bg with brightened gold text
    "CLE": ("#002244", "#FFB81C"),  # Tertiary gold instead of burgundy on navy
    "CV": ("#002B49", "#99D9D9"),  # Tertiary ice blue instead of red on navy
    "COL": ("#002D62", "#FDB927"),  # Tertiary gold instead of burgundy on navy
    "GR": ("#A60D26", "#FFFFFF"),  # White text instead of silver on red
    "HAM": ("#003B73", "#FF8C33"),  # Deepened blue with brightened orange text
    "HFD": ("#00205B", "#FFFFFF"),  # White text instead of red on navy
    "HSK": ("#384047", "#E6D29B"),  # Deepened steel gray with brightened gold
    "HER": ("#4A2E18", "#E6BA7A"),
    "IA": ("#154734", "#DDCBA4"),  # Tertiary wheat instead of red on green
    "LAV": ("#00205B", "#FFFFFF"),  # White text instead of red on navy
    "LV": ("#000000", "#FF7A1A"),  # Black (#222) bg with orange text
    "MB": ("#00205B", "#7F9FB7"),
    "MIL": ("#002B49", "#9EA2A2"),
    "ONT": ("#000000", "#A2AAAD"),
    "PRO": ("#000000", "#FFB81C"),
    "ROC": ("#00205B", "#FFFFFF"),  # White text instead of red on navy
    "RFD": ("#A60D26", "#FFFFFF"),  # White text instead of black on red
    "SD": ("#002244", "#FF8C2E"),  # Navy bg with brightened orange text
    "SJ": ("#005960", "#FFFFFF"),  # White text instead of orange on teal
    "SPR": ("#002F6C", "#00A3E0"),
    "SYR": ("#00205B", "#8BB8E8"),
    "TEX": ("#006A4E", "#E2E6EA"),  # Brightened silver for contrast on green
    "TOR": ("#00205B", "#FFFFFF"),
    "TUC": ("#8C2633", "#DDCBA4"),
    "UTC": ("#A60D26", "#FFFFFF"),  # Red bg with white text (Devils palette)
    "WBS": ("#000000", "#FFB81C"),
}

DEFAULT_BG = "#1A1A1A"
DEFAULT_FG = "#FFFFFF"

def pad_zero(val):
    s = str(val)
    if len(s) < 2:
        return "0" + s
    return s

def format_date_key(t):
    return str(t.year) + "-" + pad_zero(t.month) + "-" + pad_zero(t.day)

def get_team_color(code):
    return TEAM_COLORS.get(code, (DEFAULT_BG, DEFAULT_FG))

def get_background_color(code, displayType):
    if displayType == "black":
        return "#222"
    bg, _ = get_team_color(code)
    if bg.lower() in ("#ffffff", "#000000"):
        return "#222"
    return bg

def get_text_color(code, displayType):
    if displayType == "black":
        return DEFAULT_FG
    _, fg = get_team_color(code)
    return fg

def fetch_ahl_scores():
    # Cache for 120 seconds to balance freshness and API friendliness
    res = http.get(AHL_FEED_URL, ttl_seconds = CACHE_TTL_SECONDS)
    if res.status_code != 200:
        return []

    data = res.json()
    site_kit = data.get("SiteKit", {})
    games = site_kit.get("Scorebar", [])
    if type(games) != "list":
        return []

    return games

def get_logo_data(url, logo_cache):
    if not url:
        return None
    if url in logo_cache:
        return logo_cache[url]
    res = http.get(url, ttl_seconds = 86400)
    data = res.body() if res.status_code == 200 else None
    logo_cache[url] = data
    return data

def parse_game_time(game):
    # Parses GameDateISO8601 (RFC3339, supporting offsets and UTC Z) into a time object
    if str(game.get("DateTbd", "0")) == "1":
        return None
    iso = game.get("GameDateISO8601", "")
    if not iso or "T" not in iso or len(iso) < 20:
        return None
    return time.parse_time(iso, format = "2006-01-02T15:04:05Z07:00")

def is_game_disrupted(game):
    status_str = (game.get("GameStatusString", "") + " " + game.get("GameStatusStringLong", "")).lower()
    for kw in DISRUPTED_KEYWORDS:
        if kw in status_str:
            return True
    return False

def is_game_final(game):
    status_str = (game.get("GameStatusString", "") + " " + game.get("GameStatusStringLong", "")).lower()
    game_status = str(game.get("GameStatus", ""))
    return "final" in status_str or game_status in ("3", "4")

def is_game_live(game):
    if is_game_disrupted(game) or is_game_final(game):
        return False

    status_str = game.get("GameStatusString", "").lower()
    game_status = str(game.get("GameStatus", ""))

    # If status string contains am/pm or is "scheduled", game has not started yet
    if "am" in status_str or "pm" in status_str or "sched" in status_str:
        return False

    if game_status == "2" or "in progress" in status_str or "live" in status_str or game.get("Intermission", "0") == "1":
        return True

    clock = game.get("GameClock", "00:00")
    return clock != "00:00" and clock != "0:00" and clock != ""

def is_game_started(game):
    return is_game_final(game) or is_game_live(game)

def get_team_record(game, prefix):
    wins = game.get(prefix + "Wins", "0")
    losses = game.get(prefix + "RegulationLosses", "0")
    ot_losses = int(game.get(prefix + "OTLosses", "0") or 0) + int(game.get(prefix + "ShootoutLosses", "0") or 0)
    return "%s-%s-%s" % (wins, losses, str(ot_losses))

def format_status(game, user_tz, now_user, compact_pregame = False):
    status_str = game.get("GameStatusString", "")
    status_str_long = game.get("GameStatusStringLong", "")
    period_short = game.get("PeriodNameShort", "")
    period = str(game.get("Period", ""))
    clock = game.get("GameClock", "")

    if is_game_disrupted(game):
        combined = (status_str + " " + status_str_long).lower()
        if "postpone" in combined:
            return "PPD"
        if "cancel" in combined:
            return "CANC"
        if "suspend" in combined:
            return "SUSP"
        return "DELAY"

    if is_game_final(game):
        full_status = (status_str + " " + status_str_long + " " + period_short).upper()
        if "SO" in full_status or "SHOOTOUT" in full_status:
            return "Final/SO"
        elif "OT" in full_status or "OVERTIME" in full_status:
            return "Final/OT"
        return "Final"

    if is_game_live(game):
        ps_upper = period_short.upper()
        if "SO" in ps_upper:
            period_name = "SO"
        elif "OT" in ps_upper:
            period_name = ps_upper
        elif period == "4":
            period_name = "OT"
        elif period == "5":
            period_name = "SO"
        else:
            period_name = "P" + period

        if game.get("Intermission", "0") == "1":
            return "END " + period_name

        if clock and clock != "0:00" and clock != "00:00":
            return "%s %s" % (period_name, clock)
        return period_name

    # Pre-game: format time in user's timezone
    gt = parse_game_time(game)
    if gt:
        local_gt = gt.in_location(user_tz)

        if str(game.get("TimeTbd", "0")) == "1":
            if compact_pregame:
                return "TBD"
            return "%d/%d TBD" % (local_gt.month, local_gt.day)

        hr = local_gt.hour % 12
        if hr == 0:
            hr = 12
        minute = pad_zero(local_gt.minute)
        ampm = "a" if local_gt.hour < 12 else "p"

        if compact_pregame:
            # Compact form for narrow 1x clock-mode top bar (e.g. "5:00p" or "Sat 7:05p")
            if format_date_key(local_gt) == format_date_key(now_user):
                return "%d:%s%s" % (hr, minute, ampm)
            return "%s %d:%s%s" % (local_gt.format("Mon"), hr, minute, ampm)

        # Standard pre-game format e.g. "11/20 5:00p"
        return "%d/%d %d:%s%s" % (local_gt.month, local_gt.day, hr, minute, ampm)

    return "SCHED"

def get_date_column(displayTop, now, scoreNumber, rotationSpeed, textColor, borderColor, gameTime, timeColor, is_2x):
    scale = 2 if is_2x else 1
    font_header = "terminus-16" if is_2x else "tb-8"
    font_sub = "6x13" if is_2x else "CG-pixel-3x5-mono"

    if displayTop == "gameinfo":
        return [
            render.Box(
                width = 64 * scale,
                height = 8 * scale,
                color = borderColor,
                child = render.Row(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Text(color = timeColor, content = gameTime, font = font_sub),
                    ],
                ),
            ),
        ]
    else:
        timeBox = 20 * scale
        statusBox = 44 * scale
        if displayTop == "league":
            theTime = LEAGUE_DISPLAY
            timeBox += LEAGUE_DISPLAY_OFFSET * scale
            statusBox -= LEAGUE_DISPLAY_OFFSET * scale
        else:
            now = now + time.parse_duration("%ds" % (int(scoreNumber) * int(rotationSpeed)))
            hr = now.hour % 12
            if hr == 0:
                hr = 12
            theTime = "%d:%s" % (hr, pad_zero(now.minute))
            if len(theTime) > 4:
                timeBox += 4 * scale
                statusBox -= 4 * scale

        return [
            render.Box(
                width = timeBox,
                height = 8 * scale,
                color = borderColor,
                child = render.Row(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Box(width = 1 * scale, height = 8 * scale),
                        render.Text(color = timeColor, content = theTime, font = font_header),
                    ],
                ),
            ),
            render.Box(
                width = statusBox,
                height = 8 * scale,
                color = borderColor,
                child = render.Row(
                    expanded = True,
                    main_align = "end",
                    cross_align = "center",
                    children = [
                        render.Padding(
                            pad = (0, 0, 1 * scale, 0),
                            child = render.Text(color = textColor, content = gameTime, font = font_sub),
                        ),
                    ],
                ),
            ),
        ]

def render_team_row(code, display_val, text_color, score_color, is_record, bg_color, logo_url, is_2x, logo_cache):
    scale = 2 if is_2x else 1
    logo_size = 24 if is_2x else 12
    team_font = "6x13" if is_2x else "Dina_r400-6"
    score_font = ("6x13" if is_2x else "CG-pixel-3x5-mono") if is_record else ("6x13" if is_2x else "CG-pixel-4x5-mono")
    fallback_font = "6x13" if is_2x else "tom-thumb"

    logo_bytes = get_logo_data(logo_url, logo_cache)
    display_code = code[:3].upper() if code else "TBD"

    logo_child = render.Image(src = logo_bytes, width = logo_size, height = logo_size) if logo_bytes else render.Text(content = display_code, color = text_color, font = fallback_font)

    return render.Box(
        width = 64 * scale,
        height = 12 * scale,
        color = bg_color,
        child = render.Row(
            expanded = True,
            main_align = "start",
            cross_align = "center",
            children = [
                # Logo area (12px logo + 1px gap before team code at 1x)
                render.Box(
                    width = 13 * scale,
                    height = 12 * scale,
                    child = render.Row(
                        expanded = True,
                        main_align = "start",
                        cross_align = "center",
                        children = [logo_child],
                    ),
                ),
                # Team abbreviation (left-aligned)
                render.Box(
                    width = 18 * scale,
                    height = 12 * scale,
                    child = render.Row(
                        expanded = True,
                        main_align = "start",
                        cross_align = "center",
                        children = [
                            render.Text(content = display_code, color = text_color, font = team_font),
                        ],
                    ),
                ),
                # Score / Record area (right-aligned; fits full 8-char W-L-OTL at 1x and 2x)
                render.Box(
                    width = 33 * scale,
                    height = 12 * scale,
                    child = render.Row(
                        expanded = True,
                        main_align = "end",
                        cross_align = "center",
                        children = [
                            render.Padding(
                                pad = (0, 0, 1 * scale, 0),
                                child = render.Text(
                                    content = display_val,
                                    color = score_color,
                                    font = score_font,
                                ),
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def render_game_card(game, index, user_tz, now_user, config, is_2x, logo_cache):
    displayTop = config.get("displayTop", "league")
    displayType = config.get("displayType", "colors")
    rotationSpeed = config.get("rotationSpeed", "5")
    timeColor = config.get("displayTimeColor", "#FFA500")

    home_code = game.get("HomeCode", "")
    away_code = game.get("VisitorCode", "")
    home_logo = game.get("HomeLogo", "")
    away_logo = game.get("VisitorLogo", "")

    is_live = is_game_live(game)
    is_final = is_game_final(game)
    started = is_live or is_final
    compact_pregame = (displayTop == "time" and not is_2x)
    game_time = format_status(game, user_tz, now_user, compact_pregame = compact_pregame)

    if started:
        home_score = game.get("HomeGoals", "0")
        away_score = game.get("VisitorGoals", "0")
        home_val = str(home_score) if home_score != "" else "0"
        away_val = str(away_score) if away_score != "" else "0"
        is_record = False
    else:
        home_val = get_team_record(game, "Home")
        away_val = get_team_record(game, "Visitor")
        is_record = True

    away_bg = get_background_color(away_code, displayType)
    home_bg = get_background_color(home_code, displayType)
    away_text_color = get_text_color(away_code, displayType)
    home_text_color = get_text_color(home_code, displayType)

    home_int = int(game.get("HomeGoals", 0) or 0)
    away_int = int(game.get("VisitorGoals", 0) or 0)

    if is_final:
        if home_int > away_int:
            home_score_color = "#FFD700"
            away_score_color = "#CCCCCC"
        elif away_int > home_int:
            home_score_color = "#CCCCCC"
            away_score_color = "#FFD700"
        else:
            home_score_color = home_text_color
            away_score_color = away_text_color
    else:
        home_score_color = home_text_color
        away_score_color = away_text_color

    text_status_color = "#00FF00" if is_live else "#FFF"

    return render.Column(
        expanded = True,
        main_align = "space_between",
        cross_align = "start",
        children = [
            # Top Header Bar
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "start",
                children = get_date_column(displayTop, now_user, index, rotationSpeed, text_status_color, "#000", game_time, timeColor, is_2x),
            ),
            # Teams area: away row stacked over home row
            render.Column(
                children = [
                    render_team_row(away_code, away_val, away_text_color, away_score_color, is_record, away_bg, away_logo, is_2x, logo_cache),
                    render_team_row(home_code, home_val, home_text_color, home_score_color, is_record, home_bg, home_logo, is_2x, logo_cache),
                ],
            ),
        ],
    )

def main(config):
    is_2x = canvas.is2x() if hasattr(canvas, "is2x") else False
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location) if type(location) == "string" and location.startswith("{") else {}
    user_tz = loc.get("timezone") or config.get("timezone") or "America/Denver"

    selected_team = config.get("team", "ALL")
    rotation_speed = int(config.get("rotationSpeed", "5"))
    games = fetch_ahl_scores()

    if not games:
        return []

    now_user = time.now().in_location(user_tz)
    today_str = format_date_key(now_user)
    recent_final_cutoff = now_user - time.hour * 27

    # 1. Filter by selected team
    team_games = []
    for g in games:
        home_code = g.get("HomeCode", "")
        away_code = g.get("VisitorCode", "")
        if selected_team != "ALL" and selected_team != home_code and selected_team != away_code:
            continue
        team_games.append(g)

    if not team_games:
        return []

    # 2. Separate into live, recent final, and upcoming games from the default feed window
    live_games = []
    upcoming_games = []
    recent_past_games = []

    for g in team_games:
        gt = parse_game_time(g)

        if is_game_live(g):
            live_games.append(g)
        elif is_game_final(g):
            if gt:
                # Started within the last 27 hours (~completed within the previous 24 hours)
                if gt >= recent_final_cutoff and gt <= now_user:
                    recent_past_games.append(g)
        else:
            # Scheduled or disrupted game from today onward within the default feed window
            if gt:
                game_day_str = format_date_key(gt.in_location(user_tz))
                if game_day_str >= today_str:
                    upcoming_games.append(g)

    # If a live game is currently playing, it takes absolute exclusivity
    if len(live_games) > 0:
        filtered_games = live_games
    else:
        filtered_games = recent_past_games + upcoming_games

        # If more than 10 games are queued, narrow to today's games to keep render time fast
        if len(filtered_games) > 10:
            todays_games = [
                g
                for g in filtered_games
                if parse_game_time(g) and format_date_key(parse_game_time(g).in_location(user_tz)) == today_str
            ]
            if todays_games:
                filtered_games = todays_games
            else:
                filtered_games = filtered_games[:10]

    # Return empty list so the app displays nothing if no games are eligible
    if not filtered_games:
        return []

    # Render all matching games in a multi-frame sequence (deduplicating logo fetches per run)
    logo_cache = {}
    frames = [render_game_card(g, idx, user_tz, now_user, config, is_2x, logo_cache) for idx, g in enumerate(filtered_games)]

    return render.Root(
        delay = rotation_speed * 1000,
        show_full_animation = True,
        child = render.Animation(children = frames) if len(frames) > 1 else frames[0],
    )

teamOptions = [
    schema.Option(display = "All Teams", value = "ALL"),
    schema.Option(display = "Abbotsford Canucks", value = "ABB"),
    schema.Option(display = "Bakersfield Condors", value = "BAK"),
    schema.Option(display = "Belleville Senators", value = "BEL"),
    schema.Option(display = "Calgary Wranglers", value = "CGY"),
    schema.Option(display = "Charlotte Checkers", value = "CLT"),
    schema.Option(display = "Chicago Wolves", value = "CHI"),
    schema.Option(display = "Cleveland Monsters", value = "CLE"),
    schema.Option(display = "Coachella Valley Firebirds", value = "CV"),
    schema.Option(display = "Colorado Eagles", value = "COL"),
    schema.Option(display = "Grand Rapids Griffins", value = "GR"),
    schema.Option(display = "Hamilton Hammers", value = "HAM"),
    schema.Option(display = "Hartford Wolf Pack", value = "HFD"),
    schema.Option(display = "Henderson Silver Knights", value = "HSK"),
    schema.Option(display = "Hershey Bears", value = "HER"),
    schema.Option(display = "Iowa Wild", value = "IA"),
    schema.Option(display = "Laval Rocket", value = "LAV"),
    schema.Option(display = "Lehigh Valley Phantoms", value = "LV"),
    schema.Option(display = "Manitoba Moose", value = "MB"),
    schema.Option(display = "Milwaukee Admirals", value = "MIL"),
    schema.Option(display = "Ontario Reign", value = "ONT"),
    schema.Option(display = "Providence Bruins", value = "PRO"),
    schema.Option(display = "Rochester Americans", value = "ROC"),
    schema.Option(display = "Rockford IceHogs", value = "RFD"),
    schema.Option(display = "San Diego Gulls", value = "SD"),
    schema.Option(display = "San Jose Barracuda", value = "SJ"),
    schema.Option(display = "Springfield Thunderbirds", value = "SPR"),
    schema.Option(display = "Syracuse Crunch", value = "SYR"),
    schema.Option(display = "Texas Stars", value = "TEX"),
    schema.Option(display = "Toronto Marlies", value = "TOR"),
    schema.Option(display = "Tucson Roadrunners", value = "TUC"),
    schema.Option(display = "Utica Comets", value = "UTC"),
    schema.Option(display = "Wilkes-Barre/Scranton Penguins", value = "WBS"),
]

rotationOptions = [
    schema.Option(display = "3 seconds", value = "3"),
    schema.Option(display = "4 seconds", value = "4"),
    schema.Option(display = "5 seconds", value = "5"),
    schema.Option(display = "6 seconds", value = "6"),
    schema.Option(display = "7 seconds", value = "7"),
    schema.Option(display = "8 seconds", value = "8"),
    schema.Option(display = "9 seconds", value = "9"),
    schema.Option(display = "10 seconds", value = "10"),
]

displayOptions = [
    schema.Option(display = "Team Colors", value = "colors"),
    schema.Option(display = "Black", value = "black"),
]

displayTopOptions = [
    schema.Option(display = "League Name", value = "league"),
    schema.Option(display = "Current Time", value = "time"),
    schema.Option(display = "Game Info Only", value = "gameinfo"),
]

colorOptions = [
    schema.Option(display = "White", value = "#FFF"),
    schema.Option(display = "Yellow", value = "#FF0"),
    schema.Option(display = "Red", value = "#F00"),
    schema.Option(display = "Blue", value = "#00F"),
    schema.Option(display = "Green", value = "#0F0"),
    schema.Option(display = "Orange", value = "#FFA500"),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "team",
                name = "Team Focus",
                desc = "Only show scores for selected team.",
                icon = "hockeyPuck",
                default = teamOptions[0].value,
                options = teamOptions,
            ),
            schema.Dropdown(
                id = "rotationSpeed",
                name = "Rotation Speed",
                desc = "Amount of seconds each score is displayed.",
                icon = "clock",
                default = rotationOptions[2].value,
                options = rotationOptions,
            ),
            schema.Dropdown(
                id = "displayType",
                name = "Display Type",
                desc = "Style of how the scores are displayed.",
                icon = "palette",
                default = displayOptions[0].value,
                options = displayOptions,
            ),
            schema.Dropdown(
                id = "displayTop",
                name = "Top Display",
                desc = "A toggle of what to display on the top shelf.",
                icon = "gear",
                default = displayTopOptions[0].value,
                options = displayTopOptions,
            ),
            schema.Dropdown(
                id = "displayTimeColor",
                name = "Top Display Color",
                desc = "Select which color you want the top display to be.",
                icon = "brush",
                default = colorOptions[5].value,
                options = colorOptions,
            ),
        ],
    )
