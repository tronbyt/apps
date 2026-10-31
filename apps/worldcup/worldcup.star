"""
Applet: World Cup
Summary: Follow a World Cup country
Description: Track your favorite country's World Cup matches, live scores, upcoming schedules, and team records.
Author: Brombomb
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

SCOREBOARD_API = "https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/scoreboard"
TEAM_API = "https://site.api.espn.com/apis/site/v2/sports/soccer/all/teams/%s"
DEFAULT_COUNTRY = "660"  # United States

COUNTRIES = [
    ("624", "Algeria (ALG)"),
    ("202", "Argentina (ARG)"),
    ("628", "Australia (AUS)"),
    ("474", "Austria (AUT)"),
    ("459", "Belgium (BEL)"),
    ("452", "Bosnia-Herzegovina (BIH)"),
    ("205", "Brazil (BRA)"),
    ("206", "Canada (CAN)"),
    ("2597", "Cape Verde (CPV)"),
    ("208", "Colombia (COL)"),
    ("2850", "Congo DR (COD)"),
    ("477", "Croatia (CRO)"),
    ("11678", "Curaçao (CUW)"),
    ("450", "Czechia (CZE)"),
    ("209", "Ecuador (ECU)"),
    ("2620", "Egypt (EGY)"),
    ("448", "England (ENG)"),
    ("478", "France (FRA)"),
    ("481", "Germany (GER)"),
    ("4469", "Ghana (GHA)"),
    ("2654", "Haiti (HAI)"),
    ("469", "Iran (IRN)"),
    ("4375", "Iraq (IRQ)"),
    ("4789", "Ivory Coast (CIV)"),
    ("627", "Japan (JPN)"),
    ("2917", "Jordan (JOR)"),
    ("203", "Mexico (MEX)"),
    ("2869", "Morocco (MAR)"),
    ("449", "Netherlands (NED)"),
    ("2666", "New Zealand (NZL)"),
    ("464", "Norway (NOR)"),
    ("2659", "Panama (PAN)"),
    ("210", "Paraguay (PAR)"),
    ("482", "Portugal (POR)"),
    ("4398", "Qatar (QAT)"),
    ("655", "Saudi Arabia (KSA)"),
    ("580", "Scotland (SCO)"),
    ("654", "Senegal (SEN)"),
    ("467", "South Africa (RSA)"),
    ("451", "South Korea (KOR)"),
    ("164", "Spain (ESP)"),
    ("466", "Sweden (SWE)"),
    ("475", "Switzerland (SUI)"),
    ("659", "Tunisia (TUN)"),
    ("465", "Türkiye (TUR)"),
    ("660", "United States (USA)"),
    ("212", "Uruguay (URU)"),
    ("2570", "Uzbekistan (UZB)"),
]

COUNTRY_OPTIONS = [schema.Option(display = name, value = val) for val, name in COUNTRIES]

SEQUENCE_OPTIONS = [
    schema.Option(display = "Home first (International)", value = "home"),
    schema.Option(display = "Away first (US style)", value = "away"),
]

def main(config):
    timezone = time.tz()
    now = time.now().in_location(timezone)

    followed_country = config.get("followed_country", DEFAULT_COUNTRY)
    hide_scores = config.bool("hide_scores", False)
    is_24_hour = config.bool("is_24_hour_format", False)
    is_us_date = config.bool("is_us_date_format", False)
    team_sequence = config.get("team_sequence", "home")

    SCALE = 2 if canvas.is2x() else 1

    # 1. Fetch World Cup Scoreboard (today's games)
    scoreboard_data_str = get_cache_data(SCOREBOARD_API, ttl_seconds = 60)
    scoreboard_match = None
    is_group_stage = False

    if scoreboard_data_str:
        scoreboard_json = json.decode(scoreboard_data_str)
        if "leagues" in scoreboard_json and len(scoreboard_json["leagues"]) > 0:
            league = scoreboard_json["leagues"][0]
            season_type_name = league.get("season", {}).get("type", {}).get("name", "")
            is_group_stage = (season_type_name == "Group Stage")

        events = scoreboard_json.get("events", [])
        for event in events:
            competitions = event.get("competitions", [])
            if len(competitions) > 0:
                competitors = competitions[0].get("competitors", [])
                for competitor in competitors:
                    if competitor.get("id") == followed_country:
                        # Check if game is today in local time
                        match_date_str = event.get("date")
                        if match_date_str:
                            match_time = time.parse_time(match_date_str, format = "2006-01-02T15:04Z").in_location(timezone)
                            if match_time.format("2006-01-02") == now.format("2006-01-02"):
                                scoreboard_match = event
                                break
                if scoreboard_match:
                    break

    # 2. Determine match to render
    match_to_render = None
    is_scoreboard_source = False

    if scoreboard_match:
        match_to_render = scoreboard_match
        is_scoreboard_source = True
    else:
        # Fallback to team schedule API
        team_url = TEAM_API % followed_country
        team_data_str = get_cache_data(team_url, ttl_seconds = 600)  # cache schedule/records for 10 min
        if team_data_str:
            team_json = json.decode(team_data_str)
            team_obj = team_json.get("team", {})
            next_events = team_obj.get("nextEvent", [])
            if len(next_events) > 0:
                match_to_render = next_events[0]

    if not match_to_render:
        return []

    # 3. Extract match details
    competitions = match_to_render.get("competitions", [])
    if len(competitions) == 0:
        return []

    competition = competitions[0]
    competitors = competition.get("competitors", [])
    if len(competitors) < 2:
        return []

    # Determine home and away competitors
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

    home_id = home_team.get("id")
    away_id = away_team.get("id")

    home_abbr = home_team.get("abbreviation", "HOME")
    away_abbr = away_team.get("abbreviation", "AWAY")

    home_name = home_team.get("displayName", "Home")
    away_name = away_team.get("displayName", "Away")

    home_logo_url = ""
    home_logos = home_team.get("logos", [])
    if len(home_logos) > 0:
        home_logo_url = home_logos[0].get("href", "")
    else:
        home_logo_url = home_team.get("logo", "")

    away_logo_url = ""
    away_logos = away_team.get("logos", [])
    if len(away_logos) > 0:
        away_logo_url = away_logos[0].get("href", "")
    else:
        away_logo_url = away_team.get("logo", "")

    home_color = get_team_color(home_team.get("color", "NO"))
    away_color = get_team_color(away_team.get("color", "NO"))
    away_alt_color = get_team_color(away_team.get("alternateColor", "NO"))

    # 4. Extract scores and records
    game_status = match_to_render.get("status", {}).get("type", {}).get("state", "pre")  # pre, in, post
    status_detail = match_to_render.get("status", {}).get("type", {}).get("shortDetail", "")
    match_date_str = match_to_render.get("date", "")

    home_score = home_competitor.get("score", "0")
    away_score = away_competitor.get("score", "0")

    # Check for penalty shootout
    home_shootout = home_competitor.get("shootoutScore")
    away_shootout = away_competitor.get("shootoutScore")

    home_record = "0-0-0"
    away_record = "0-0-0"

    # If the game is today, or we are in scoreboard source, extract records if present
    if is_scoreboard_source:
        home_records = home_competitor.get("records", [])
        if len(home_records) > 0:
            home_record = home_records[0].get("summary", "0-0-0")
        away_records = away_competitor.get("records", [])
        if len(away_records) > 0:
            away_record = away_records[0].get("summary", "0-0-0")
    else:
        # Fallback upcoming match needs full detail calls for records
        home_info = get_team_info(home_id, home_abbr, home_name, home_logo_url)
        away_info = get_team_info(away_id, away_abbr, away_name, away_logo_url)

        home_abbr = home_info["abbr"]
        home_logo_url = home_info["logo_url"]
        home_color = home_info["color"]
        home_record = home_info["record"]

        away_abbr = away_info["abbr"]
        away_logo_url = away_info["logo_url"]
        away_color = away_info["color"]
        away_record = away_info["record"]
        away_alt_color = away_info["away_alt_color"]

        # We can also assume the fallback upcoming event is during Group Stage
        # if the league default is Group Stage, or just default it
        is_group_stage = True

    # Check for color clash
    dist_primary = color_distance(home_color, away_color)
    dist_alt = color_distance(home_color, away_alt_color)

    if dist_primary < 8000 and dist_alt > dist_primary:
        away_color = away_alt_color

    # 5. Format display values
    home_val = ""
    away_val = ""
    show_val = False

    is_today = False
    if match_date_str:
        match_time = time.parse_time(match_date_str, format = "2006-01-02T15:04Z").in_location(timezone)
        is_today = (match_time.format("2006-01-02") == now.format("2006-01-02"))

    if is_today or game_status in ("in", "post"):
        # Game played today or active/completed
        show_val = True
        if hide_scores:
            home_val = "-"
            away_val = "-"
        else:
            home_val = home_score
            away_val = away_score
            if home_shootout != None and away_shootout != None:
                home_val = "%s (%s)" % (home_score, str(int(home_shootout)))
                away_val = "%s (%s)" % (away_score, str(int(away_shootout)))
    elif is_group_stage:
        # Pre-game and in group stage: show record
        show_val = True
        home_val = home_record
        away_val = away_record

    # 6. Format status row text
    status_text = ""
    is_live = False

    if is_today or game_status in ("in", "post"):
        if game_status == "in":
            status_text = status_detail
            is_live = True
        elif game_status == "post":
            # If shootout happened
            if home_shootout != None and away_shootout != None:
                status_text = "FT-PENS"
            else:
                status_text = "FINAL"
        else:
            # Scheduled for today
            if match_date_str:
                match_time = time.parse_time(match_date_str, format = "2006-01-02T15:04Z").in_location(timezone)
                if is_24_hour:
                    status_text = match_time.format("15:04")
                else:
                    status_text = match_time.format("3:04 PM")
            else:
                status_text = "TODAY"
    else:
        # Next match (upcoming, not today)
        if match_date_str:
            match_time = time.parse_time(match_date_str, format = "2006-01-02T15:04Z").in_location(timezone)
            day_str = match_time.format("Mon")

            if is_us_date:
                date_str = match_time.format("1/2")
            else:
                date_str = match_time.format("2/1")

            if is_24_hour:
                time_str = match_time.format("15:04")
            else:
                time_str = match_time.format("3:04 PM")

            status_text = "%s %s %s" % (day_str, date_str, time_str)
        else:
            status_text = "UPCOMING"

    # 7. Retrieve country flags (scaled)
    home_flag_data = get_flag_image(home_logo_url, SCALE)
    away_flag_data = get_flag_image(away_logo_url, SCALE)

    home_flag = get_flag_widget(home_flag_data, home_color, SCALE)
    away_flag = get_flag_widget(away_flag_data, away_color, SCALE)

    # 8. Render rows
    if team_sequence == "away":
        row1_flag = away_flag
        row1_abbr = away_abbr
        row1_is_followed = (away_id == followed_country)
        row1_val = away_val
        row1_color = away_color

        row2_flag = home_flag
        row2_abbr = home_abbr
        row2_is_followed = (home_id == followed_country)
        row2_val = home_val
        row2_color = home_color
    else:
        row1_flag = home_flag
        row1_abbr = home_abbr
        row1_is_followed = (home_id == followed_country)
        row1_val = home_val
        row1_color = home_color

        row2_flag = away_flag
        row2_abbr = away_abbr
        row2_is_followed = (away_id == followed_country)
        row2_val = away_val
        row2_color = away_color

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render_team_row(row1_flag, row1_abbr, row1_is_followed, row1_val, show_val, row1_color, SCALE),
                render_team_row(row2_flag, row2_abbr, row2_is_followed, row2_val, show_val, row2_color, SCALE),
                render_status_row(status_text, is_live, SCALE),
            ],
        ),
    )

def render_team_row(flag_widget, abbr, is_followed, score_or_record, show_score_or_record, team_color, scale):
    font_abbr = "terminus-16" if scale == 2 else "tb-8"
    font_val = "tb-8" if scale == 2 else "CG-pixel-3x5-mono"

    if is_light_color(team_color):
        abbr_color = "#B8860B" if is_followed else "#000000"
        val_color = "#000000"
    else:
        abbr_color = "#FFE065" if is_followed else "#FFFFFF"
        val_color = "#FFFFFF"

    val_text = None
    if show_score_or_record:
        val_text = render.Text(content = score_or_record, font = font_val, color = val_color)
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

def get_team_color(color_hex):
    if not color_hex or color_hex == "NO":
        return "#222222"
    return "#" + color_hex

def get_flag_image(logo_url, scale):
    if not logo_url:
        return None
    flag_w = 16 * scale
    flag_h = 10 * scale

    # Use ESPN combiner to resize flag image
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

def get_team_info(team_id, default_abbr, default_name, default_logo_url):
    url = TEAM_API % team_id
    team_data_str = get_cache_data(url, ttl_seconds = 600)

    abbr = default_abbr
    name = default_name
    logo_url = default_logo_url
    color = "#222222"
    away_alt_color = "#222222"
    record = "0-0-0"

    if team_data_str:
        team_json = json.decode(team_data_str)
        t = team_json.get("team", {})
        abbr = t.get("abbreviation", default_abbr)
        name = t.get("displayName", default_name)
        color = get_team_color(t.get("color", "NO"))
        alt_c = get_team_color(t.get("alternateColor", "NO"))
        away_alt_color = alt_c

        logos = t.get("logos", [])
        if len(logos) > 0:
            logo_url = logos[0].get("href", default_logo_url)

        record_obj = t.get("record", {})
        items = record_obj.get("items", [])
        if len(items) > 0:
            record = items[0].get("summary", "0-0-0")

    return dict(abbr = abbr, name = name, color = color, away_alt_color = away_alt_color, logo_url = logo_url, record = record)

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
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "followed_country",
                name = "Country to Follow",
                desc = "Choose the country you want to track.",
                icon = "futbol",
                default = DEFAULT_COUNTRY,
                options = COUNTRY_OPTIONS,
            ),
            schema.Dropdown(
                id = "team_sequence",
                name = "Display which team first?",
                desc = "Home First (International) or Away First (US style)",
                icon = "arrowsRotate",
                default = SEQUENCE_OPTIONS[0].value,
                options = SEQUENCE_OPTIONS,
            ),
            schema.Toggle(
                id = "hide_scores",
                name = "Hide Scores",
                desc = "Hide match scores to avoid spoilers.",
                icon = "eyeSlash",
                default = False,
            ),
            schema.Toggle(
                id = "is_24_hour_format",
                name = "24 Hour Format",
                desc = "Display times in 24-hour format.",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = "is_us_date_format",
                name = "US Date Format",
                desc = "Display dates as MM/DD instead of DD/MM.",
                icon = "calendarDays",
                default = False,
            ),
        ],
    )
