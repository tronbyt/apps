"""
Applet: CS2 Valve Ranking
Summary: Display CS2 Valve Rankings
Description: Displays the current CS2 Valve Ranking from a data feed.
Author: Lt_r3p0rt
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CACHE_TTL_SECONDS = 300

def get_cachable_data(url, ttl_seconds = CACHE_TTL_SECONDS):
    res = http.get(url = url, ttl_seconds = ttl_seconds)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

DEFAULT_LOCATION = {
    "lat": "47.3769",
    "lng": "8.5417",
    "description": "Zurich, ZH, CH",
    "locality": "Zurich",
    "timezone": "Europe/Zurich",
}

# App display
LEAGUE_DISPLAY = "CS2"
LEAGUE_DISPLAY_OFFSET = 6

# JSON feed URL (raw GitHub file)
VALVE_RANKINGS_URL = "https://raw.githubusercontent.com/janlauber3388/CS2_tidbyt/main/valve_rankings.json"

DEFAULT_LOGO = "https://raw.githubusercontent.com/janlauber3388/CS2_tidbyt/main/logos/default.png"
DEFAULT_COLOR = "#1F1F1F"  # black
TAGS_JSON = json.decode(get_cachable_data("https://raw.githubusercontent.com/janlauber3388/CS2_tidbyt/main/team_tags.json"))
COLORS_JSON = json.decode(get_cachable_data("https://raw.githubusercontent.com/janlauber3388/CS2_tidbyt/main/team_colors.json"))
LOGO_BASE_URL = "https://raw.githubusercontent.com/janlauber3388/CS2_tidbyt/main/logos/"

DEFAULT_LOGO_BYTES = http.get(
    url = DEFAULT_LOGO,
    ttl_seconds = CACHE_TTL_SECONDS,
).body()

REGION_DISPLAY = {
    "global": "Global",
    "eu": "Europe",
    "na": "Americas",
    "asia": "Asia",
}

INVITE_THRESHOLDS = {
    "eu": (6, 6, 6),
    "na": (2, 1, 6),
    "asia": (0, 1, 4),
}

STAGE3_COLOR = "#00FF00"  # Green
STAGE2_COLOR = "#FFFF00"  # Yellow
STAGE1_COLOR = "#FFA500"  # Orange
DEFAULT_RANK_COLOR = "#FFFFFF"
RANK_BACKGROUND = "#1F1F1F"

def get_rank_color(region, rank):
    # Never color global rankings
    if region == "global":
        return DEFAULT_RANK_COLOR

    stage3, stage2, stage1 = INVITE_THRESHOLDS.get(region, (0, 0, 0))

    if rank <= stage3:
        return STAGE3_COLOR
    elif rank <= stage3 + stage2:
        return STAGE2_COLOR
    elif rank <= stage3 + stage2 + stage1:
        return STAGE1_COLOR
    else:
        return DEFAULT_RANK_COLOR

def get_team_info(team_name):
    safe_name = team_name.replace(" ", "_")

    logo = LOGO_BASE_URL + safe_name + ".png"

    tag_info = TAGS_JSON.get(team_name, {})
    tag = tag_info.get("tag", team_name[:4].upper())

    # Look up team background color from GitHub JSON
    color_info = COLORS_JSON.get(team_name, {})
    team_color = color_info.get("color", DEFAULT_COLOR)
    text_color = "#000000" if color_info.get("darkText", False) else "#FFFFFF"

    return logo, tag, team_color, text_color

def build_logo_cache(entries, max_logos = 6):
    cache = {}
    fetched = 0

    for team in entries:
        if fetched >= max_logos:
            break

        teamName = team.get("tag", team.get("tag")[:4])
        logo_url, _, _, _ = get_team_info(teamName)

        if logo_url in cache:
            continue

        resp = http.get(
            url = logo_url,
            ttl_seconds = CACHE_TTL_SECONDS,
        )

        if resp.status_code == 200:
            cache[logo_url] = resp.body()
        else:
            cache[logo_url] = DEFAULT_LOGO_BYTES

        fetched += 1

    return cache

def main(config):
    renderCategory = []

    rotationSpeed = int(config.get("rotationSpeed", 5))
    teamsPerView = int(config.get("teamsOptions", 3))
    maxTeams = int(config.get("maxTeams", 12))
    displayTop = config.get("displayTop", "league")
    timeColor = config.get("displayTimeColor", "#FFA500")

    location = config.get("location", DEFAULT_LOCATION)
    timezone = location["timezone"]
    now = time.now().in_location(timezone)

    # --- REGION CONFIG ---
    region = config.get("region", "global")

    # --- FETCH RANKINGS ---
    resp = http.get(
        url = VALVE_RANKINGS_URL,
        ttl_seconds = CACHE_TTL_SECONDS,
    )

    entries = []
    if resp.status_code == 200:
        data = json.decode(resp.body())
        entries = data.get(region, [])

    # ALWAYS RETURN A ROOT (NO INACTIVE APP)
    if len(entries) == 0:
        return render.Root(
            child = render.Box(
                width = 64,
                height = 32,
                child = render.Text(
                    content = "NO DATA",
                    color = "#F00",
                    font = "CG-pixel-3x5-mono",
                ),
            ),
        )

    # APPLY MAX TEAMS HERE (THIS WAS MISSING)
    entries = entries[:maxTeams]

    # --- BUILD LOGO CACHE ONCE ---
    logo_cache = build_logo_cache(entries, max_logos = len(entries))

    # --- RENDER ENTRIES ---
    for x in range(0, len(entries), teamsPerView):
        renderCategory.append(
            render.Column(
                expanded = True,
                main_align = "start",
                cross_align = "start",
                children = [
                    render.Column(
                        children = get_team(
                            x,
                            entries,
                            teamsPerView,
                            region,
                            logo_cache,
                        ),
                    ),
                ],
            ),
        )

    divisionName = REGION_DISPLAY.get(region, region)

    return render.Root(
        delay = rotationSpeed * 1000,
        show_full_animation = True,
        child = render.Column(
            children = get_top_column(
                displayTop,
                now,
                timeColor,
                divisionName,
                renderCategory,
            ),
        ),
    )

rotationOptions = [
    schema.Option(
        display = "3 seconds",
        value = "3",
    ),
    schema.Option(
        display = "4 seconds",
        value = "4",
    ),
    schema.Option(
        display = "5 seconds",
        value = "5",
    ),
    schema.Option(
        display = "6 seconds",
        value = "6",
    ),
    schema.Option(
        display = "7 seconds",
        value = "7",
    ),
    schema.Option(
        display = "8 seconds",
        value = "8",
    ),
    schema.Option(
        display = "9 seconds",
        value = "9",
    ),
    schema.Option(
        display = "10 seconds",
        value = "10",
    ),
    schema.Option(
        display = "11 seconds",
        value = "11",
    ),
    schema.Option(
        display = "12 seconds",
        value = "12",
    ),
    schema.Option(
        display = "13 seconds",
        value = "13",
    ),
    schema.Option(
        display = "14 seconds",
        value = "14",
    ),
    schema.Option(
        display = "15 seconds",
        value = "15",
    ),
]

teamsOptions = [
    schema.Option(
        display = "2",
        value = "2",
    ),
    schema.Option(
        display = "3",
        value = "3",
    ),
    schema.Option(
        display = "4",
        value = "4",
    ),
]

maxTeamsOptions = [
    schema.Option(display = "Top 6", value = "6"),
    schema.Option(display = "Top 12", value = "12"),
    schema.Option(display = "Top 24", value = "24"),
    schema.Option(display = "Top 32", value = "32"),
]

displayTopOptions = [
    schema.Option(
        display = "League Name",
        value = "league",
    ),
    schema.Option(
        display = "Current Time",
        value = "time",
    ),
    schema.Option(
        display = "League Name Only",
        value = "gameinfo",
    ),
]

colorOptions = [
    schema.Option(
        display = "White",
        value = "#FFF",
    ),
    schema.Option(
        display = "Yellow",
        value = "#FF0",
    ),
    schema.Option(
        display = "Red",
        value = "#F00",
    ),
    schema.Option(
        display = "Blue",
        value = "#00F",
    ),
    schema.Option(
        display = "Green",
        value = "#0F0",
    ),
    schema.Option(
        display = "Orange",
        value = "#FFA500",
    ),
]

regionOptions = [
    schema.Option(display = "Global", value = "global"),
    schema.Option(display = "Europe", value = "eu"),
    schema.Option(display = "Americas", value = "na"),
    schema.Option(display = "Asia", value = "asia"),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "region",
                name = "Region",
                desc = "Which CS2 region rankings to display.",
                icon = "gear",
                default = "global",
                options = regionOptions,
            ),
            schema.Dropdown(
                id = "rotationSpeed",
                name = "Rotation Speed",
                desc = "Amount of seconds each ranking is displayed.",
                icon = "gear",
                default = rotationOptions[2].value,
                options = rotationOptions,
            ),
            schema.Dropdown(
                id = "teamsOptions",
                name = "Teams Per View",
                desc = "How many teams to show at once.",
                icon = "gear",
                default = teamsOptions[1].value,
                options = teamsOptions,
            ),
            schema.Dropdown(
                id = "maxTeams",
                name = "Max Teams",
                desc = "How many ranked teams to include.",
                icon = "gear",
                default = "12",
                options = maxTeamsOptions,
            ),
            schema.Dropdown(
                id = "displayTop",
                name = "Top Display",
                desc = "Toggle what to show at the top.",
                icon = "gear",
                default = displayTopOptions[0].value,
                options = displayTopOptions,
            ),
            schema.Dropdown(
                id = "displayTimeColor",
                name = "Top Display Color",
                desc = "Select the color of the top display.",
                icon = "gear",
                default = colorOptions[5].value,
                options = colorOptions,
            ),
        ],
    )

def get_standings(url):
    data = get_cachable_data(url)
    return json.decode(data)

def get_team(x, entries, entriesToDisplay, region, logo_cache):
    output = []
    containerHeight = int(24 / entriesToDisplay)

    for i in range(entriesToDisplay):
        if i + x < len(entries):
            team = entries[i + x]

            teamName = team.get("tag", team.get("tag")[:4])
            teamLogo, tag, teamColor, textColor = get_team_info(teamName)

            # Pre-fetched logo bytes
            logo_bytes = logo_cache.get(teamLogo, DEFAULT_LOGO_BYTES)

            rank = team["rank"]
            points = team["points"]
            rank_color = get_rank_color(region, rank)

            output.append(
                render.Column(
                    children = [
                        render.Box(
                            width = 64,
                            height = containerHeight,
                            color = teamColor,
                            child = render.Row(
                                expanded = True,
                                main_align = "start",
                                cross_align = "center",
                                children = [
                                    # ── RANK ─────────────────────
                                    render.Box(
                                        width = 8,
                                        height = containerHeight,
                                        color = "#1F1F1F",
                                        child = render.Text(
                                            content = str(rank),
                                            color = rank_color,
                                            font = "CG-pixel-3x5-mono",
                                        ),
                                    ),

                                    # ── LOGO ─────────────────────
                                    render.Box(
                                        width = 8,
                                        height = containerHeight,
                                        child = render.Image(
                                            logo_bytes,
                                            width = 10,
                                            height = 10,
                                        ),
                                    ),

                                    # ── TEAM TAG ─────────────────
                                    render.Box(
                                        width = 20,
                                        height = containerHeight,
                                        child = render.Text(
                                            content = tag,
                                            color = textColor,
                                            font = "CG-pixel-3x5-mono",
                                        ),
                                    ),

                                    # ── POINTS ───────────────────
                                    render.Box(
                                        width = 28,
                                        height = containerHeight,
                                        child = render.Text(
                                            content = str(points),
                                            color = textColor,
                                            font = "CG-pixel-3x5-mono",
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
            )
        else:
            # Empty filler row
            output.append(
                render.Column(
                    children = [
                        render.Box(
                            width = 64,
                            height = containerHeight,
                            color = "#111",
                        ),
                    ],
                ),
            )

    return output

def get_top_column(displayTop, now, timeColor, divisionName, renderCategory):
    cs2_name = "CS2"

    # ── LEAGUE NAME ONLY (CENTERED REGION) ─────────────
    if displayTop == "gameinfo":
        return [
            render.Box(
                width = 64,
                height = 8,
                child = render.Stack(
                    children = [
                        render.Box(width = 64, height = 8, color = "#000"),
                        render.Row(
                            expanded = True,
                            main_align = "center",
                            cross_align = "center",
                            children = [
                                render.Text(
                                    content = divisionName,
                                    color = timeColor,
                                    font = "tb-8",
                                ),
                            ],
                        ),
                    ],
                ),
            ),
            render.Animation(children = renderCategory),
        ]

    # ── LEAGUE OR TIME (CS2 LEFT, REGION OR TIME RIGHT) ─
    right_text = (
        divisionName if displayTop == "league" else now.format("3:04")
    )

    return [
        render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                # Left: CS2
                render.Box(
                    width = 28,
                    height = 8,
                    child = render.Row(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(
                                content = cs2_name,
                                color = timeColor,
                                font = "tb-8",
                            ),
                        ],
                    ),
                ),
                # Right: Region or Time
                render.Box(
                    width = 36,
                    height = 8,
                    child = render.Row(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(
                                content = right_text,
                                color = timeColor,
                                font = "tb-8",
                            ),
                        ],
                    ),
                ),
            ],
        ),
        render.Animation(children = renderCategory),
    ]
