"""
Applet: CS2 Scores
Summary: Display live CS2 match scores
Description: Displays the current CS2 matches from a data feed.
Author: Lt_r3p0rt
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

PANDASCORE_API = (
    "https://api.pandascore.co/csgo/matches" +
    "?page=1" +
    "&per_page=100"
)

CACHE_TTL_SECONDS = 60
DEFAULT_LOCATION = {
    "lat": "47.3769",
    "lng": "8.5417",
    "description": "Zurich, ZH, CH",
    "locality": "Zurich",
    "timezone": "Europe/Zurich",
}

def get_cachable_data(url, ttl_seconds = CACHE_TTL_SECONDS):
    res = http.get(
        url = url,
        ttl_seconds = ttl_seconds,
    )
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

def get_api_page(page, api_key):
    url = (
        "https://api.pandascore.co/csgo/matches" +
        "?page=%d" +
        "&per_page=100"
    ) % page

    return get_api_data(url, api_key)

def get_all_matches(pages, api_key):
    matches = []

    for page in range(1, pages + 1):
        data = get_api_page(page, api_key)
        decoded = json.decode(data)

        matches += decoded

    return matches

def get_api_data(url, api_key, ttl_seconds = CACHE_TTL_SECONDS):
    res = http.get(
        url = url,
        ttl_seconds = ttl_seconds,
        headers = {
            "Authorization": "Bearer " + api_key,
        },
    )

    if res.status_code != 200:
        fail("request failed: %d - %s" % (res.status_code, res.body()))

    return res.body()

# JSON feed URL (raw GitHub file)
VALVE_RANKINGS_URL = "https://raw.githubusercontent.com/janlauber3388/CS2_tidbyt/main/valve_rankings.json"

RANKINGS_JSON = json.decode(get_cachable_data(VALVE_RANKINGS_URL))
DEFAULT_LOGO = "https://raw.githubusercontent.com/janlauber3388/CS2_tidbyt/main/logos/default.png"
DEFAULT_COLOR = "#1F1F1F"  # black
TAGS_JSON = json.decode(get_cachable_data("https://raw.githubusercontent.com/janlauber3388/CS2_tidbyt/main/team_tags.json"))
COLORS_JSON = json.decode(get_cachable_data("https://raw.githubusercontent.com/janlauber3388/CS2_tidbyt/main/team_colors.json"))
LOGO_BASE_URL = "https://raw.githubusercontent.com/janlauber3388/CS2_tidbyt/main/logos/"

DEFAULT_LOGO_BYTES = http.get(
    url = DEFAULT_LOGO,
    ttl_seconds = CACHE_TTL_SECONDS,
).body()

EVENT_COLORS = {
    "IEM": "#002585",
    "ESL PRO LEAGUE": "#37f22e",
    "BLAST BOUNTY": "#0247fd",
    "BLAST OPEN": "#f71e41",
    "BLAST RIVALS": "#fc8c05",
    "PGL": "#e20417",
    "STARLADDER": "#d40000",
    "MAJOR": "#8f886d",
}

DEFAULT_EVENT_COLOR = "#d8790e"

SHORTENED_WORDS = """
{
    " PM": "P",
    " AM": "A",
    " - ": " ",
    " / ": " ",
    " of": "",
    "not_started": "SOON",
    "Overtime": "OT",
    "1st Half": "1H",
    "2nd Half": "2H",
    "running": "LIVE",
    "finished": "FINAL",
    "canceled": "CANCEL"}
"""

def get_canonical_team_name(team_name):
    for canonical_name, info in TAGS_JSON.items():
        if team_name == canonical_name:
            return canonical_name

        for alias in info.get("pandascore", []):
            if alias == team_name:
                return canonical_name

    return team_name

def get_team_info(team_name, use_alt_logo = False):
    # Convert PandaScore name to our canonical name
    if team_name == "TBD":
        logo_resp = http.get(url = LOGO_BASE_URL + "TBD.png", ttl_seconds = CACHE_TTL_SECONDS)
        return (logo_resp.body(), "TBD", DEFAULT_COLOR, "#FFFFFF", 0)

    canonical_name = get_canonical_team_name(team_name)

    safe_name = canonical_name.replace(" ", "_")

    normal_logo = LOGO_BASE_URL + safe_name + ".png"
    alt_logo = LOGO_BASE_URL + safe_name + "_alt.png"
    default_logo = LOGO_BASE_URL + "default.png"

    logo_url = normal_logo

    if use_alt_logo:
        alt_resp = http.get(
            url = alt_logo,
            ttl_seconds = CACHE_TTL_SECONDS,
        )

        if alt_resp.status_code == 200:
            logo_url = alt_logo

    logo_resp = http.get(
        url = logo_url,
        ttl_seconds = CACHE_TTL_SECONDS,
    )

    if logo_resp.status_code != 200:
        logo_resp = http.get(
            url = default_logo,
            ttl_seconds = CACHE_TTL_SECONDS,
        )

    logo = logo_resp.body()

    tag_info = TAGS_JSON.get(canonical_name, {})
    tag = tag_info.get("tag", canonical_name[:4].upper())

    color_info = COLORS_JSON.get(canonical_name, {})
    team_color = color_info.get("color", DEFAULT_COLOR)
    text_color = "#000000" if color_info.get("darkText", False) else "#FFFFFF"

    rank = get_team_rank(canonical_name)

    return logo, tag, team_color, text_color, rank

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

def get_event_color(event_name):
    name = event_name.upper()

    if "MAJOR" in name:
        return EVENT_COLORS["MAJOR"]

    if "IEM" in name or "INTEL EXTREME MASTERS" in name:
        return EVENT_COLORS["IEM"]

    if "ESL PRO LEAGUE" in name:
        return EVENT_COLORS["ESL PRO LEAGUE"]

    if "BLAST BOUNTY" in name:
        return EVENT_COLORS["BLAST BOUNTY"]

    if "BLAST OPEN" in name:
        return EVENT_COLORS["BLAST OPEN"]

    if "BLAST RIVALS" in name:
        return EVENT_COLORS["BLAST RIVALS"]

    if "PGL" in name:
        return EVENT_COLORS["PGL"]

    if "STARLADDER" in name:
        return EVENT_COLORS["STARLADDER"]

    return DEFAULT_EVENT_COLOR

def shorten_event_name(event_name):
    name = event_name

    replacements = {
        "Intel Extreme Masters": "IEM",
        "ESL Pro League": "EPL",
        "StarLadder StarSeries": "SL StarSeries",
        "Thunderpick World Championship": "Thunder WC",
        "CS Asia Championships": "CAC",
        "Perfect World": "PW",
        "PGL Masters": "PGL",
        "Open Qualifier": "OQ",
        "Closed Qualifier": "CQ",
        "Europe": "EU",
        "North America": "NA",
        "South America": "SA",
    }

    for old, new in replacements.items():
        name = name.replace(old, new)

    # BLAST Premier -> Premier
    if "BLAST" in name:
        name = name.replace("BLAST ", "")

    # Seasons
    for i in range(1, 30):
        name = name.replace(
            "Season " + str(i),
            "S" + str(i),
        )

    return name

def get_event_text_color(event_name):
    name = event_name.upper()

    if "MAJOR" in name:
        return "#ffffff"

    return "#ffffff"

def main(config):
    api_key = config.get("API_KEY", "")
    renderCategory = []
    selectedTeam = config.get("selectedTeam", "all")
    showRanking = config.bool("displayRanking")
    displayType = config.get("displayType", "colors")
    rotationSpeed = config.get("rotationSpeed", "5")
    location = config.get("location", DEFAULT_LOCATION)
    if type(location) == "string":
        loc = json.decode(location)
    else:
        loc = location
    timezone = loc["timezone"]
    now = time.now().in_location(timezone)
    if api_key == "":
        sample_resp = http.get(
            url = "https://raw.githubusercontent.com/janlauber3388/CS2_tidbyt/main/Sample.png",
            ttl_seconds = CACHE_TTL_SECONDS,
        )

        return render.Root(
            child = render.Stack(
                children = [
                    render.Image(
                        sample_resp.body(),
                        width = 64,
                        height = 32,
                    ),
                    render.Column(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(
                                "NO API KEY",
                                font = "6x13",
                                color = "#ff0000",
                            ),
                        ],
                    ),
                ],
            ),
        )
    scores = get_scores(selectedTeam, timezone, api_key)

    if len(scores) > 0:
        for match in scores:
            gameStatus = match["status"]
            if len(match["opponents"]) < 2:
                continue
            homeTeamName = match["opponents"][0]["opponent"]["name"]
            awayTeamName = match["opponents"][1]["opponent"]["name"]

            useAltLogos = displayType == "black"

            tournamentName = match.get("league", {}).get("name", "CS2")

            displayTournamentName = shorten_event_name(tournamentName)
            tournamentColor = get_event_color(tournamentName)
            tournamentTextColor = get_event_text_color(tournamentName)

            matchFormat = get_match_stage(match)

            homeLogo, homeTag, homeColor, homeTextColor, homeRank = get_team_info(
                homeTeamName,
                useAltLogos,
            )

            awayLogo, awayTag, awayColor, awayTextColor, awayRank = get_team_info(
                awayTeamName,
                useAltLogos,
            )

            if homeTextColor == "#000000":
                homeWinText = "#9000FF"
                homeLoseText = "#000000"

            else:
                homeWinText = "#ffff00"
                homeLoseText = "#ffffff"

            if awayTextColor == "#000000":
                awayWinText = "#9000FF"
                awayLoseText = "#000000"

            else:
                awayWinText = "#ffff00"
                awayLoseText = "#ffffff"

            homeScore = ""
            awayScore = ""
            gameTime = ""
            homeScoreColor = "#fff"
            awayScoreColor = "#fff"
            teamFont = "Dina_r400-6"
            scoreFont = "Dina_r400-6"

            if gameStatus == "not_started":
                gameTime = match["begin_at"]
                scoreFont = "CG-pixel-3x5-mono"

                convertedTime = time.parse_time(
                    gameTime,
                    format = "2006-01-02T15:04:05Z",
                ).in_location(timezone)

                if convertedTime.format("1/2") != now.format("1/2"):
                    gameTime = convertedTime.format("Jan 2")
                else:
                    gameTime = convertedTime.format("3:04PM")
                    gameTime = gameTime.replace("AM", "A").replace("PM", "P")

            if gameStatus == "running":
                gameTime = "LIVE"
                homeScore = str(match["results"][0]["score"])
                homeScoreColor = "#fff"
                awayScore = str(match["results"][1]["score"])
                awayScoreColor = "#fff"

            if gameStatus == "canceled":
                scoreFont = "CG-pixel-3x5-mono"
                homeScore = ""
                awayScore = ""
                gameTime = "Canceled"

            if gameStatus == "finished":
                gameTime = "Final"

                homeScore = str(match["results"][0]["score"])
                awayScore = str(match["results"][1]["score"])

                if int(homeScore) > int(awayScore):
                    homeTextColor = homeWinText
                    awayTextColor = awayLoseText

                elif int(awayScore) > int(homeScore):
                    awayTextColor = awayWinText
                    homeTextColor = homeLoseText

            if displayType == "retro":
                retroFont = "CG-pixel-3x5-mono"

                renderCategory.extend(
                    [
                        render.Column(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "start",
                            children = [
                                get_top_bar(
                                    displayTournamentName,
                                    tournamentColor,
                                    tournamentTextColor,
                                    matchFormat,
                                    gameTime,
                                ),
                                render.Column(
                                    children = [
                                        render.Box(width = 64, height = 11, color = awayColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                            render.Box(width = 40, height = 11, child = render.Text(content = get_team_name(awayTeamName), color = awayTextColor, font = retroFont)),
                                            render.Box(width = 26, height = 11, child = render.Text(content = awayScore, color = awayTextColor, font = retroFont)),
                                        ])),
                                        render.Box(width = 64, height = 11, color = homeColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                            render.Box(width = 40, height = 11, child = render.Text(content = get_team_name(homeTeamName), color = homeTextColor, font = retroFont)),
                                            render.Box(width = 26, height = 11, child = render.Text(content = homeScore, color = homeTextColor, font = retroFont)),
                                        ])),
                                    ],
                                ),
                            ],
                        ),
                    ],
                )

            elif displayType == "horizontal":
                homeTextColor = "#fff"
                awayTextColor = "#fff"

                if gameStatus == "finished":
                    if int(homeScore) > int(awayScore):
                        homeTextColor = "#ff0"
                    elif int(awayScore) > int(homeScore):
                        awayTextColor = "#ff0"

                renderCategory.extend(
                    [
                        render.Column(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "start",
                            children = [
                                get_top_bar(
                                    displayTournamentName,
                                    tournamentColor,
                                    tournamentTextColor,
                                    matchFormat,
                                    gameTime,
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "start",
                                    children = [
                                        render.Row(
                                            children = [
                                                render.Box(width = 32, height = 22, color = awayColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                                        render.Stack(children = [
                                                            render.Box(width = 32, height = 22, child = render.Image(awayLogo, width = 32, height = 32)),
                                                            render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                                                render.Box(width = 32, height = 14),
                                                                render.Box(width = 32, height = 8, color = "#000a", child = render.Text(content = awayScore, color = awayTextColor, font = scoreFont)),
                                                            ]),
                                                        ]),
                                                    ]),
                                                ])),
                                                render.Box(width = 32, height = 22, color = homeColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                                        render.Stack(children = [
                                                            render.Box(width = 32, height = 22, child = render.Image(homeLogo, width = 32, height = 32)),
                                                            render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                                                render.Box(width = 32, height = 14),
                                                                render.Box(width = 32, height = 8, color = "#000a", child = render.Text(content = homeScore, color = homeTextColor, font = scoreFont)),
                                                            ]),
                                                        ]),
                                                    ]),
                                                ])),
                                            ],
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                )

            elif displayType == "logos":
                textFont = teamFont

                renderCategory.extend(
                    [
                        render.Column(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "start",
                            children = [
                                get_top_bar(
                                    displayTournamentName,
                                    tournamentColor,
                                    tournamentTextColor,
                                    matchFormat,
                                    gameTime,
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "start",
                                    children = [
                                        render.Column(
                                            children = [
                                                render.Box(width = 64, height = 11, color = awayColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Image(awayLogo, width = 30, height = 30),
                                                    render.Box(width = 34, height = 11, child = render.Text(content = awayScore, color = awayTextColor, font = scoreFont)),
                                                ])),
                                                render.Box(width = 64, height = 11, color = homeColor, child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Image(homeLogo, width = 30, height = 30),
                                                    render.Box(width = 34, height = 11, child = render.Text(content = homeScore, color = homeTextColor, font = scoreFont)),
                                                ])),
                                            ],
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                )

            elif displayType == "black":
                textFont = teamFont

                homeTextColor = "#fff"
                awayTextColor = "#fff"

                if gameStatus == "finished":
                    if int(homeScore) > int(awayScore):
                        homeTextColor = "#ff0"
                    elif int(awayScore) > int(homeScore):
                        awayTextColor = "#ff0"

                renderCategory.extend(
                    [
                        render.Column(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "start",
                            children = [
                                get_top_bar(
                                    displayTournamentName,
                                    tournamentColor,
                                    tournamentTextColor,
                                    matchFormat,
                                    gameTime,
                                ),
                                render.Column(
                                    children = [
                                        render.Box(
                                            width = 64,
                                            height = 11,
                                            color = "#222",
                                            child = render.Row(
                                                expanded = True,
                                                children = get_logo_column(showRanking, awayTag, awayLogo, 16, awayRank, awayScoreColor, awayTextColor, textFont, awayScore, scoreFont),
                                            ),
                                        ),
                                        render.Box(
                                            width = 64,
                                            height = 11,
                                            color = "#222",
                                            child = render.Row(
                                                expanded = True,
                                                children = get_logo_column(showRanking, homeTag, homeLogo, 16, homeRank, homeScoreColor, homeTextColor, textFont, homeScore, scoreFont),
                                            ),
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                )

            else:
                textFont = teamFont

                renderCategory.extend(
                    [
                        render.Column(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "start",
                            children = [
                                get_top_bar(
                                    displayTournamentName,
                                    tournamentColor,
                                    tournamentTextColor,
                                    matchFormat,
                                    gameTime,
                                ),
                                render.Column(
                                    children = [
                                        render.Box(
                                            width = 64,
                                            height = 11,
                                            color = awayColor,
                                            child = render.Row(
                                                expanded = True,
                                                children = get_logo_column(showRanking, awayTag, awayLogo, 16, awayRank, awayScoreColor, awayTextColor, textFont, awayScore, scoreFont),
                                            ),
                                        ),
                                        render.Box(
                                            width = 64,
                                            height = 11,
                                            color = homeColor,
                                            child = render.Row(
                                                expanded = True,
                                                children = get_logo_column(showRanking, homeTag, homeLogo, 16, homeRank, homeScoreColor, homeTextColor, textFont, homeScore, scoreFont),
                                            ),
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                )

        return render.Root(
            delay = int(rotationSpeed) * 1000,
            show_full_animation = True,
            child = render.Column(
                children = [
                    render.Animation(
                        children = renderCategory,
                    ),
                ],
            ),
        )
    else:
        return []

teamOptions = [
    schema.Option(
        display = "All Teams",
        value = "all",
    ),
    schema.Option(
        display = "Vitality",
        value = "VIT",
    ),
    schema.Option(
        display = "FURIA",
        value = "FUR",
    ),
    schema.Option(
        display = "Falcons",
        value = "FLC",
    ),
    schema.Option(
        display = "Aurora",
        value = "AUR",
    ),
    schema.Option(
        display = "MOUZ",
        value = "MOUZ",
    ),
    schema.Option(
        display = "The MongolZ",
        value = "MGLZ",
    ),
    schema.Option(
        display = "Spirit",
        value = "TS",
    ),
    schema.Option(
        display = "Liquid",
        value = "TL",
    ),
    schema.Option(
        display = "G2",
        value = "G2",
    ),
    schema.Option(
        display = "Natus Vincere",
        value = "NAVI",
    ),
    schema.Option(
        display = "Legacy",
        value = "LGY",
    ),
    schema.Option(
        display = "Astralis",
        value = "AST",
    ),
    schema.Option(
        display = "HEROIC",
        value = "HRC",
    ),
    schema.Option(
        display = "3DMAX",
        value = "3DM",
    ),
    schema.Option(
        display = "paiN",
        value = "PAIN",
    ),
    schema.Option(
        display = "B8",
        value = "B8",
    ),
    schema.Option(
        display = "FaZe",
        value = "FAZE",
    ),
    schema.Option(
        display = "SAW",
        value = "SAW",
    ),
    schema.Option(
        display = "PARIVISION",
        value = "PARI",
    ),
    schema.Option(
        display = "Gentle Mates",
        value = "GM",
    ),
    schema.Option(
        display = "GamerLegion",
        value = "GL",
    ),
    schema.Option(
        display = "FUT",
        value = "FUT",
    ),
    schema.Option(
        display = "BetBoom",
        value = "BB",
    ),
    schema.Option(
        display = "fnatic",
        value = "FNC",
    ),
    schema.Option(
        display = "M80",
        value = "M80",
    ),
    schema.Option(
        display = "FlyQuest",
        value = "FQ",
    ),
    schema.Option(
        display = "Passion UA",
        value = "P UA",
    ),
    schema.Option(
        display = "HOTU",
        value = "HOTU",
    ),
    schema.Option(
        display = "Ninjas in Pyjamas",
        value = "NIP",
    ),
    schema.Option(
        display = "Lynn Vision",
        value = "LV",
    ),
    schema.Option(
        display = "NRG",
        value = "NRG",
    ),
    schema.Option(
        display = "Imperial",
        value = "IMP",
    ),
    schema.Option(
        display = "EYEBALLERS",
        value = "EYE",
    ),
    schema.Option(
        display = "Inner Circle",
        value = "IC",
    ),
    schema.Option(
        display = "OG",
        value = "OG",
    ),
    schema.Option(
        display = "9INE",
        value = "9INE",
    ),
    schema.Option(
        display = "MIBR",
        value = "MIBR",
    ),
    schema.Option(
        display = "TYLOO",
        value = "TY",
    ),
    schema.Option(
        display = "ENCE",
        value = "ENCE",
    ),
    schema.Option(
        display = "Fluxo",
        value = "FLUX",
    ),
    schema.Option(
        display = "Virtus.pro",
        value = "VP",
    ),
    schema.Option(
        display = "Monte",
        value = "MNT",
    ),
    schema.Option(
        display = "SINNERS",
        value = "SIN",
    ),
    schema.Option(
        display = "ECSTATIC",
        value = "ECST",
    ),
    schema.Option(
        display = "BIG",
        value = "BIG",
    ),
    schema.Option(
        display = "Sharks",
        value = "SHA",
    ),
    schema.Option(
        display = "Alliance",
        value = "ALC",
    ),
    schema.Option(
        display = "Sashi",
        value = "SAI",
    ),
    schema.Option(
        display = "9z",
        value = "9Z",
    ),
    schema.Option(
        display = "100 Thieves",
        value = "100T",
    ),
    schema.Option(
        display = "Luminosity",
        value = "LG",
    ),
    schema.Option(
        display = "magic",
        value = "MAG",
    ),
    schema.Option(
        display = "Nemesis",
        value = "NEM",
    ),
    schema.Option(
        display = "K27",
        value = "K27",
    ),
    schema.Option(
        display = "Wildcard",
        value = "WC",
    ),
    schema.Option(
        display = "INFINITE",
        value = "INF",
    ),
    schema.Option(
        display = "THUNDER dOWNUNDER",
        value = "TDU",
    ),
    schema.Option(
        display = "5star",
        value = "5S",
    ),
    schema.Option(
        display = "The Huns",
        value = "HUN",
    ),
    schema.Option(
        display = "Chinggis Warriors",
        value = "GHW",
    ),
]

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

displayOptions = [
    schema.Option(
        display = "Team Colors",
        value = "colors",
    ),
    schema.Option(
        display = "Black",
        value = "black",
    ),
    schema.Option(
        display = "Logos",
        value = "logos",
    ),
    schema.Option(
        display = "Horizontal",
        value = "horizontal",
    ),
    schema.Option(
        display = "Retro",
        value = "retro",
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "API_KEY",
                name = "PandaScore API Key",
                desc = "Standard PandaScore API key for CS2 fixture (free tier available). Go to pandascore.co to get your free API key.",
                icon = "gear",
                secret = True,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for the correct timezone.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "selectedTeam",
                name = "Team Focus",
                desc = "Only show scores for selected team.",
                icon = "gear",
                default = teamOptions[0].value,
                options = teamOptions,
            ),
            schema.Toggle(
                id = "displayRanking",
                name = "Show Top 32 Rank",
                desc = "A toggle to display the top 32 ranking of the recent official Valve global ranking.",
                icon = "trophy",
                default = True,
            ),
            schema.Dropdown(
                id = "rotationSpeed",
                name = "Rotation Speed",
                desc = "Amount of seconds each score is displayed.",
                icon = "gear",
                default = rotationOptions[2].value,
                options = rotationOptions,
            ),
            schema.Dropdown(
                id = "displayType",
                name = "Display Type",
                desc = "Style of how the scores are displayed.",
                icon = "gear",
                default = displayOptions[0].value,
                options = displayOptions,
            ),
        ],
    )

def filter_quality(matches):
    print("FILTERING MATCHES:", len(matches))

    good_matches = []

    for match in matches:
        if match["status"] not in [
            "not_started",
            "running",
            "finished",
        ]:
            continue

        if len(match["opponents"]) < 2:
            continue

        homeTeamName = match["opponents"][0]["opponent"]["name"]
        awayTeamName = match["opponents"][1]["opponent"]["name"]

        tournamentName = match.get("league", {}).get("name", "")

        homeRank = get_team_rank(homeTeamName)
        awayRank = get_team_rank(awayTeamName)

        rankedTeam = (
            homeRank <= 32 or
            awayRank <= 32
        )

        goodTournament = is_good_tournament(tournamentName)

        qualifier = is_bad_tournament(tournamentName)

        # Remove qualifiers unless a ranked team is involved
        if qualifier and not rankedTeam:
            continue

        # Remove everything that is neither a good tournament
        # nor contains a top 32 team
        if not rankedTeam and not goodTournament:
            continue

        good_matches.append(match)

    return good_matches

def is_bad_tournament(name):
    bad_keywords = [
        "qualifier",
        "qualifiers",
        "qualification",
        "open qualifier",
        "closed qualifier",
    ]

    name = name.lower()

    for keyword in bad_keywords:
        if keyword in name:
            return True

    return False

def get_match_stage(match):
    name = match.get("name", "")

    # Extract the stage part before the team names
    if ":" in name:
        stage = name.split(":")[0].strip().lower()
    else:
        stage = name.lower()

    # Grand final
    if "grand final" in stage:
        return "GRAND FIN"

    # Consolidation final
    if "consolidation final" in stage:
        return "CF"

    # Third place
    if "3rd place" in stage or "third place" in stage:
        return "3rd/4th"

    # Brackets
    if "upper bracket" in stage:
        return "UB"

    if "lower bracket" in stage:
        return "LB"

    # Playoff rounds
    if "quarter" in stage:
        return "QF"

    if "semi" in stage:
        return "Semi"

    # Round numbers
    if "round of 16" in stage:
        return "RO 16"

    if "round of 32" in stage:
        return "RO 32"

    # Swiss rounds
    if "round 1" in stage:
        return "Swiss R1"

    if "round 2" in stage:
        return "Swiss R2"

    if "round 3" in stage:
        return "Swiss R3"

    if "round 4" in stage:
        return "Swiss R4"

    if "round 5" in stage:
        return "Swiss R5"

    # Generic decider
    if "decider" in stage:
        return "Decider"

    # Unknown
    return ""

def get_scores(team, timezone, api_key):
    matches = get_all_matches(10, api_key)
    print("TOTAL MATCHES:", len(matches))

    if team == "all":
        matches = filter_quality(matches)
        return filter_today_matches(matches, timezone)

    teamMatches = []

    for match in matches:
        opponents = match["opponents"]

        # Skip matches with no known participants
        if len(opponents) == 0:
            continue

        # If only one team is known, create a temporary TBD opponent
        if len(opponents) == 1:
            opponents = opponents + [
                {
                    "opponent": {
                        "name": "TBD",
                    },
                },
            ]

        homeName = opponents[0]["opponent"].get("name", "TBD")
        awayName = opponents[1]["opponent"].get("name", "TBD")

        homeTag = TAGS_JSON.get(
            get_canonical_team_name(homeName),
            {},
        ).get(
            "tag",
            homeName[:4].upper(),
        )

        awayTag = TAGS_JSON.get(
            get_canonical_team_name(awayName),
            {},
        ).get(
            "tag",
            awayName[:4].upper(),
        )

        if homeTag == team or awayTag == team:
            # Save the patched opponents so the rendering code also sees the TBD team
            match["opponents"] = opponents
            teamMatches.append(match)

    return select_team_matches(teamMatches, timezone)

def get_today_matches(api_key):
    matches = []

    for page in range(1, 11):
        url = (
            "https://api.pandascore.co/csgo/matches/upcoming" +
            "?page=%d" +
            "&per_page=100"
        ) % page

        data = get_api_data(url, api_key)
        decoded = json.decode(data)

        if len(decoded) == 0:
            break

        matches += decoded

    return matches

def filter_today_matches(matches, timezone):
    now = time.now().in_location(timezone)

    start_window = now - time.parse_duration("24h")
    end_window = now + time.parse_duration("24h")

    todayMatches = []

    for m in matches:
        if not m.get("begin_at"):
            continue

        start = time.parse_time(
            m["begin_at"],
            format = "2006-01-02T15:04:05Z",
        ).in_location(timezone)

        if start >= start_window and start <= end_window:
            todayMatches.append(m)

    todayMatches = sorted(
        todayMatches,
        key = lambda m: (
            m.get("league", {}).get("name", ""),
            m.get("begin_at", ""),
        ),
    )

    return todayMatches

def select_team_matches(matches, timezone):
    now = time.now().in_location(timezone)

    past = None
    current = None
    future = None

    for m in matches:
        if not m.get("begin_at"):
            continue

        start = time.parse_time(
            m["begin_at"],
            format = "2006-01-02T15:04:05Z",
        ).in_location(timezone)

        # Ignore matches outside the 7 day window
        if start < now - time.parse_duration("168h"):
            continue

        if start > now + time.parse_duration("168h"):
            continue

        status = m.get("status", "")

        # Running match
        if status == "running":
            current = m

            # Finished match
        elif start < now:
            if past == None:
                past = m
            else:
                old_start = time.parse_time(
                    past["begin_at"],
                    format = "2006-01-02T15:04:05Z",
                ).in_location(timezone)

                if start > old_start:
                    past = m

            # Upcoming match
        elif start > now:
            if future == None:
                future = m
            else:
                future_start = time.parse_time(
                    future["begin_at"],
                    format = "2006-01-02T15:04:05Z",
                ).in_location(timezone)

                if start < future_start:
                    future = m

    result = []

    if past != None:
        result.append(past)

    if current != None:
        result.append(current)

    if future != None:
        result.append(future)

    return result

RANKINGS_DATA = json.decode(get_cachable_data(VALVE_RANKINGS_URL))

def get_team_rank(team_name):
    canonical_name = get_canonical_team_name(team_name)

    rankings = RANKINGS_JSON.get("global", [])

    for team in rankings:
        if team.get("tag") == canonical_name:
            return team.get("rank", 99)

    return 99

def get_team_name(name):
    if len(name) > 9:
        theName = name[:8] + "_"
    else:
        theName = name
    return theName.upper()

def get_shortened_display(text):
    if len(text) > 8:
        text = text.replace("Final", "F").replace("Game ", "G")
    words = json.decode(SHORTENED_WORDS)
    for _, s in enumerate(words):
        text = text.replace(s, words[s])
    return text

def get_top_bar(tournamentName, tournamentColor, tournamentTextColor, matchFormat, gameTime):
    return render.Column(
        children = [
            render.Box(
                width = 64,
                height = 5,
                color = tournamentColor,
                child = render.Text(
                    content = tournamentName,
                    color = tournamentTextColor,
                    font = "CG-pixel-3x5-mono",
                ),
            ),
            render.Box(
                width = 64,
                height = 5,
                color = "#000",
                child = render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Text(
                            content = matchFormat,
                            color = "#fff",
                            font = "CG-pixel-3x5-mono",
                        ),
                        render.Text(
                            content = gameTime,
                            color = "#fff",
                            font = "CG-pixel-3x5-mono",
                        ),
                    ],
                ),
            ),
        ],
    )

def is_good_tournament(name):
    name = name.lower()

    good_keywords = [
        "iem",
        "intel extreme masters",
        "esl pro league",
        "blast",
        "major",
        "pgl",
        "starladder",
        "starseries",
        "epl",
    ]

    for keyword in good_keywords:
        if keyword in name:
            return True

    return False

def get_logo_column(showRanking, team, Logo, LogoSize, Rank, ScoreColor, TextColor, textFont, Score, scoreFont):
    if Score == None:
        Score = ""

    if team == None:
        team = ""

    if showRanking and Rank > 0 and Rank < 33:
        if Rank < 10:
            rankSize = 4
        else:
            rankSize = 8

        gameTimeColumn = [
            render.Stack(children = [
                render.Box(
                    width = 16,
                    height = 11,
                    child = render.Image(Logo, width = LogoSize, height = LogoSize),
                ),
                render.Column(
                    expanded = True,
                    main_align = "end",
                    cross_align = "start",
                    children = [
                        render.Row(children = [
                            render.Box(width = 1, height = 5, color = "#000b"),
                            render.Box(
                                width = rankSize,
                                height = 5,
                                color = "#000b",
                                child = render.Text(
                                    str(Rank),
                                    color = ScoreColor,
                                    font = "CG-pixel-3x5-mono",
                                ),
                            ),
                        ]),
                    ],
                ),
            ]),
            render.Box(
                width = 24,
                height = 11,
                child = render.Text(content = team, color = TextColor, font = textFont),
            ),
            render.Box(
                width = 24,
                height = 11,
                child = render.Text(content = str(Score), color = TextColor, font = scoreFont),
            ),
        ]

    else:
        gameTimeColumn = [
            render.Box(
                width = 16,
                height = 11,
                child = render.Image(Logo, width = LogoSize, height = LogoSize),
            ),
            render.Box(
                width = 24,
                height = 11,
                child = render.Text(content = team, color = TextColor, font = textFont),
            ),
            render.Box(
                width = 24,
                height = 11,
                child = render.Text(content = str(Score), color = TextColor, font = scoreFont),
            ),
        ]

    return gameTimeColumn

# derp
