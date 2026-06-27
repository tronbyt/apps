"""
Applet: World Cup Today
Summary: Today's World Cup games
Description: Displays live and upcoming World Cup soccer matches for the current day.
Author: Brombomb
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

SCOREBOARD_API = "https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/scoreboard"

def main(config):
    timezone = time.tz()
    now = time.now().in_location(timezone)

    is_24_hour = config.bool("is_24_hour_format", False)
    team_sequence = config.get("team_sequence", "home")
    rotation_speed = int(config.get("rotation_speed", "4"))

    SCALE = 2 if canvas.is2x() else 1

    scoreboard_data_str = get_cache_data(SCOREBOARD_API, ttl_seconds = 60)
    if not scoreboard_data_str:
        return []

    scoreboard_json = json.decode(scoreboard_data_str)
    events = scoreboard_json.get("events", [])

    games_to_render = []

    for event in events:
        match_date_str = event.get("date")
        if not match_date_str:
            continue

        match_time = time.parse_time(match_date_str, format = "2006-01-02T15:04Z").in_location(timezone)

        # Check if game is today in local time
        if match_time.format("2006-01-02") != now.format("2006-01-02"):
            continue

        game_status = event.get("status", {}).get("type", {}).get("state", "pre")

        # Skip games that are already finished
        if game_status == "post":
            continue

        games_to_render.append((event, match_time, game_status))

    if len(games_to_render) == 0:
        return []

    screens = []

    for game_data in games_to_render:
        event = game_data[0]
        match_time = game_data[1]
        game_status = game_data[2]

        competitions = event.get("competitions", [])
        if len(competitions) == 0:
            continue

        competitors = competitions[0].get("competitors", [])
        if len(competitors) < 2:
            continue

        home_competitor = None
        away_competitor = None
        for competitor in competitors:
            if competitor.get("homeAway") == "home":
                home_competitor = competitor
            elif competitor.get("homeAway") == "away":
                away_competitor = competitor

        if not home_competitor:
            home_competitor = competitors[0]
        if not away_competitor:
            away_competitor = competitors[1]

        home_team = home_competitor.get("team", {})
        away_team = away_competitor.get("team", {})

        home_abbr = home_team.get("abbreviation", "HOME")
        away_abbr = away_team.get("abbreviation", "AWAY")

        home_score = home_competitor.get("score", "0")
        away_score = away_competitor.get("score", "0")

        home_shootout = home_competitor.get("shootoutScore")
        away_shootout = away_competitor.get("shootoutScore")

        home_logo_url = get_logo_url(home_team)
        away_logo_url = get_logo_url(away_team)

        home_color = get_team_color(home_team.get("color", "NO"))
        away_color = get_team_color(away_team.get("color", "NO"))

        away_alt_color = get_team_color(away_team.get("alternateColor", "NO"))

        # If colors are too similar, switch the away team to its alternate color if it provides better contrast
        dist_primary = color_distance(home_color, away_color)
        dist_alt = color_distance(home_color, away_alt_color)

        if dist_primary < 8000 and dist_alt > dist_primary:
            away_color = away_alt_color

        home_flag_data = get_flag_image(home_logo_url, SCALE)
        away_flag_data = get_flag_image(away_logo_url, SCALE)

        home_flag = get_flag_widget(home_flag_data, home_color, SCALE)
        away_flag = get_flag_widget(away_flag_data, away_color, SCALE)

        is_live = game_status == "in"
        status_detail = event.get("status", {}).get("type", {}).get("shortDetail", "")

        if is_live:
            status_text = status_detail
        elif is_24_hour:
            status_text = match_time.format("15:04")
        else:
            status_text = match_time.format("3:04 PM")

        # Format scores (shootout if applicable)
        show_val = is_live

        home_val = home_score
        away_val = away_score

        if show_val and home_shootout != None and away_shootout != None:
            home_val = "%s (%s)" % (home_score, str(int(home_shootout)))
            away_val = "%s (%s)" % (away_score, str(int(away_shootout)))

        if team_sequence == "away":
            row1 = render_team_row(away_flag, away_abbr, away_val, show_val, away_color, SCALE)
            row2 = render_team_row(home_flag, home_abbr, home_val, show_val, home_color, SCALE)
        else:
            row1 = render_team_row(home_flag, home_abbr, home_val, show_val, home_color, SCALE)
            row2 = render_team_row(away_flag, away_abbr, away_val, show_val, away_color, SCALE)

        screen = render.Column(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                row1,
                row2,
                render_status_row(status_text, is_live, SCALE),
            ],
        )
        screens.append(screen)

    if len(screens) == 0:
        return []

    if len(screens) == 1:
        return render.Root(child = screens[0])

    return render.Root(
        delay = rotation_speed * 1000,
        show_full_animation = True,
        child = render.Animation(
            children = screens,
        ),
    )

def render_team_row(flag_widget, abbr, score, show_score, team_color, scale):
    font_abbr = "terminus-16" if scale == 2 else "tb-8"
    font_val = "tb-8" if scale == 2 else "CG-pixel-3x5-mono"

    if is_light_color(team_color):
        abbr_color = "#000000"
        val_color = "#000000"
    else:
        abbr_color = "#FFFFFF"
        val_color = "#FFFFFF"

    if show_score:
        val_text = render.Text(content = score, font = font_val, color = val_color)
    else:
        val_text = render.Box(width = 1, height = 1)

    return render.Box(
        width = 64 * scale,
        height = 13 * scale,
        color = team_color,
        child = render.Padding(
            pad = (2 * scale, 0, 2 * scale, 0),
            child = render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Row(
                        cross_align = "center",
                        children = [
                            flag_widget,
                            render.Box(width = 2 * scale, height = 1),
                            render.Text(content = abbr, font = font_abbr, color = abbr_color),
                        ],
                    ),
                    val_text,
                ],
            ),
        ),
    )

def render_status_row(status_text, is_live, scale):
    font_status = "tb-8" if scale == 2 else "CG-pixel-3x5-mono"
    status_color = "#5bbd19" if is_live else "#FFFFFF"

    return render.Box(
        width = 64 * scale,
        height = 6 * scale,
        color = "#111111",
        child = render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(content = status_text, font = font_status, color = status_color),
            ],
        ),
    )

def get_logo_url(team):
    logos = team.get("logos", [])
    if len(logos) > 0:
        return logos[0].get("href", "")
    return team.get("logo", "")

def get_team_color(color_hex):
    if not color_hex or color_hex == "NO":
        return "#222222"
    return "#" + color_hex

def get_flag_image(logo_url, scale):
    if not logo_url:
        return None
    flag_w = 16 * scale
    flag_h = 10 * scale

    combiner_url = logo_url.replace("https://a.espncdn.com/", "https://a.espncdn.com/combiner/i?img=")
    combiner_url += "&h=%d&w=%d" % (flag_h, flag_w)

    return get_cache_data(combiner_url, ttl_seconds = 86400)

def get_flag_widget(flag_data, team_color, scale):
    flag_w = 16 * scale
    flag_h = 10 * scale
    if flag_data:
        return render.Image(src = flag_data, width = flag_w, height = flag_h)
    else:
        return render.Box(width = flag_w, height = flag_h, color = team_color)

def get_cache_data(url, ttl_seconds):
    res = http.get(url, ttl_seconds = ttl_seconds)
    if res.status_code != 200:
        return None
    return res.body()

def color_distance(c1, c2):
    r1, g1, b1 = hex_to_rgb(c1)
    r2, g2, b2 = hex_to_rgb(c2)
    return (r1 - r2) * (r1 - r2) + (g1 - g2) * (g1 - g2) + (b1 - b2) * (b1 - b2)

def hex_to_rgb(hex_str):
    hex_str = hex_str.replace("#", "")
    if len(hex_str) != 6:
        return (0, 0, 0)
    return (int(hex_str[0:2], 16), int(hex_str[2:4], 16), int(hex_str[4:6], 16))

def is_light_color(hex_str):
    r, g, b = hex_to_rgb(hex_str)
    luminance = (212 * r + 715 * g + 72 * b) // 1000
    return luminance > 128

def get_schema():
    rotation_options = [
        schema.Option(display = "2 seconds", value = "2"),
        schema.Option(display = "3 seconds", value = "3"),
        schema.Option(display = "4 seconds", value = "4"),
        schema.Option(display = "5 seconds", value = "5"),
        schema.Option(display = "6 seconds", value = "6"),
        schema.Option(display = "7 seconds", value = "7"),
    ]

    sequence_options = [
        schema.Option(display = "Home first (International)", value = "home"),
        schema.Option(display = "Away first (US style)", value = "away"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "team_sequence",
                name = "Display which team first?",
                desc = "Home First (International) or Away First (US style)",
                icon = "arrowsRotate",
                default = sequence_options[0].value,
                options = sequence_options,
            ),
            schema.Dropdown(
                id = "rotation_speed",
                name = "Rotation Speed",
                desc = "Amount of seconds each game is displayed.",
                icon = "gear",
                default = rotation_options[2].value,
                options = rotation_options,
            ),
            schema.Toggle(
                id = "is_24_hour_format",
                name = "24 Hour Format",
                desc = "Display times in 24-hour format.",
                icon = "clock",
                default = False,
            ),
        ],
    )
