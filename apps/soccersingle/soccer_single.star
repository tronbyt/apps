"""
Applet: Soccer Single
Summary: Soccer Single Team
Description: Show upcoming / current / future game for a single soccer team regardless of the league / tournament they are playing in - one app tracks the team everywhere.
Author: jvivona
"""
# 20230812 added display of penalty kick score if applicable
#          toned down colors when display team colors - you couldn't see winner score if team color was also yellow
# 20230829 fixed PK score - in a different place for single match results..   Not enough testing :-)
# 20240223 fixed issue with PPD games showing before their scheduled start time
# 20240802 added code to handle widgetMode - only show the 1st piece, no animations
# 20240926 resolve issue where sometimes FT indicator from API is longer than can be displayed, override to show just FT
# 20260927 on 2x displays, optional Team 2-4 pickers show up to 4 teams at once in a grid

# Tons of thanks to @whyamihere/@rs7q5 for the API assistance - couldn't have gotten here without you
# and thanks to @dinotash/@dinosaursrarr for making me think deep thoughts about connected schema fields
# and of course - the original author of a bunch of this display code is @Lunchbox8484

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

VERSION = 24270

CACHE_TTL_SECONDS = 60

# this is for when we are handling 2 stage cache - leave this here
#CACHE2_ADD_TTL_SECONDS = 86400

DEFAULT_TIMEZONE = "America/New_York"
MISSING_LOGO = "https://upload.wikimedia.org/wikipedia/commons/c/ca/1x1.png?src=soccermens"
DEFAULT_TEAM = "203"
API = "https://site.api.espn.com/apis/site/v2/sports/soccer/%s/teams/%s"
TEAM_SEARCH_API = "https://tidbyt.apis.ajcomputers.com/soccer/api/search/%s"
DEFAULT_TEAM_DISPLAY = "visitor"  # default to Visitor first, then Home - US order
DEFAULT_DISPLAY_SPEED = "2000"
ABBR_URL = "https://raw.githubusercontent.com/jvivona/tidbyt-data/main/soccermens/league_abbr.json"
ABBR_TTL = 43200
EXTRA_TEAM_KEYS = ("teamid2", "teamid3", "teamid4")  # 2x only
TEAM_TTL_SECONDS = 3600  # opponent colors + records barely change; don't refetch every minute

SHORTENED_WORDS = """
{
    " PM": "P",
    " AM": "A",
    " Wins": "",
    " Leads": "",
    " Series": "",
    " - ": " ",
    " / ": " ",
    "Postponed": "PPD",
    "1st Half": "1H",
    "2nd Half": "2H",
    "FT-Pens": "FT",
    "AET" : "FT"
}
"""

def main(config):
    widgetMode = config.bool("$widget")
    renderCategory = []

    # we already need now value in multiple places - so just go ahead and get it and use it
    timezone = time.tz()
    now = time.now().in_location(timezone)

    teamid = get_team_id(config, "teamid") or DEFAULT_TEAM

    # On a 2x display, picking any of Team 2-4 switches to the multi-team grid,
    # whatever display type is selected - it's a completely separate render path.
    # On 1x the extra teams are ignored (settings can carry over from a 2x device).
    extra_ids = [get_team_id(config, k) for k in EXTRA_TEAM_KEYS]
    if is_wide_canvas() and any(extra_ids):
        return render_wide(config, [teamid] + extra_ids, timezone, now)

    league = API % ("all", str(teamid))
    teamdata = get_scores(league)
    scores = teamdata["nextEvent"]

    if len(scores) > 0:
        leagueAbbr = scores[0]["league"]["abbreviation"][0:6]
        leagueSlug = scores[0]["league"]["slug"]
        displayType = config.get("displayType", "colors")

        #logoType = config.get("logoType", "primary")
        timeColor = config.get("displayTimeColor", "#FFF")

        rotationSpeed = int(config.get("displaySpeed", DEFAULT_DISPLAY_SPEED))

        for _, s in enumerate(scores):
            gameStatus = s["competitions"][0]["status"]["type"]["state"]
            competition = s["competitions"][0]
            home = competition["competitors"][0]["team"]["abbreviation"]
            away = competition["competitors"][1]["team"]["abbreviation"]
            homeTeamName = competition["competitors"][0]["team"]["shortDisplayName"]
            awayTeamName = competition["competitors"][1]["team"]["shortDisplayName"]

            homeColorCheck = json.decode(get_cachable_data(API % ("all", str(competition["competitors"][0]["id"]))))["team"]["color"]
            if homeColorCheck == "NO":
                homePrimaryColor = "000000"
            else:
                homePrimaryColor = homeColorCheck

            awayColorCheck = json.decode(get_cachable_data(API % ("all", str(competition["competitors"][1]["id"]))))["team"]["color"]
            if awayColorCheck == "NO":
                awayPrimaryColor = "000000"
            else:
                awayPrimaryColor = awayColorCheck
            homeColor = get_background_color(displayType, homePrimaryColor)
            awayColor = get_background_color(displayType, awayPrimaryColor)

            homeLogoCheck = competition["competitors"][0]["team"].get("logos", "NO")
            if homeLogoCheck == "NO":
                homeLogoURL = MISSING_LOGO
            else:
                homeLogoURL = competition["competitors"][0]["team"]["logos"][0]["href"]

            awayLogoCheck = competition["competitors"][1]["team"].get("logos", "NO")
            if awayLogoCheck == "NO":
                awayLogoURL = MISSING_LOGO
            else:
                awayLogoURL = competition["competitors"][1]["team"]["logos"][0]["href"]
            homeLogo = get_logoType(homeLogoURL if homeLogoURL != "" else MISSING_LOGO)
            awayLogo = get_logoType(awayLogoURL if awayLogoURL != "" else MISSING_LOGO)
            homeLogoSize = get_logoSize()
            awayLogoSize = get_logoSize()
            homeScore = ""
            awayScore = ""
            gameTime = ""
            homeScoreColor = "#fff"
            awayScoreColor = "#fff"
            teamFont = "Dina_r400-6"
            scoreFont = "Dina_r400-6"

            if gameStatus == "pre":
                gameTime = s["date"]
                scoreFont = "CG-pixel-3x5-mono"
                convertedTime = time.parse_time(gameTime, format = "2006-01-02T15:04Z").in_location(timezone)
                if convertedTime.format("1/2") != now.format("1/2"):
                    # check to see if the game is today or not.   If not today, show date + time
                    # use settings to determine if INTL or US + time
                    if config.bool("is_us_date_format", False):
                        gameDate = convertedTime.format("Jan 2 ")
                    else:
                        gameDate = convertedTime.format("2 Jan ")
                    if config.bool("is_24_hour_format", False):
                        gameTimeFmt = convertedTime.format("15:04")
                    else:
                        gameTimeFmt = convertedTime.format("3:04PM")[:-1]
                    gameTime = gameDate + gameTimeFmt
                else:
                    if config.bool("is_24_hour_format", False):
                        gameTimeFmt = convertedTime.format("15:04")
                    else:
                        gameTimeFmt = convertedTime.format("3:04PM")[:-1]
                    gameTime = gameTimeFmt

                # need to get the legaue the game is being played in, then go query the "other" team's record can't use ALL here becuase they may have another game before this One
                # we're just going to get them both
                homeData = json.decode(get_cachable_data(API % (leagueSlug, str(competition["competitors"][0]["id"]))))
                awayData = json.decode(get_cachable_data(API % (leagueSlug, str(competition["competitors"][1]["id"]))))

                checkHomeTeamRecord = homeData["team"]["record"].get("items", "NO")
                if checkHomeTeamRecord == "NO":
                    homeScore = ""
                else:
                    homeScore = checkHomeTeamRecord[0]["summary"]

                checkAwayTeamRecord = awayData["team"]["record"].get("items", "NO")
                if checkAwayTeamRecord == "NO":
                    awayScore = ""
                else:
                    awayScore = checkAwayTeamRecord[0]["summary"]

            if gameStatus == "in":
                gameTime = competition["status"]["type"]["shortDetail"]
                homeScore = competition["competitors"][0]["score"]["displayValue"]
                homeScoreColor = "#fff"
                awayScore = competition["competitors"][1]["score"]["displayValue"]
                awayScoreColor = "#fff"

            if gameStatus == "post":
                gameTime = competition["status"]["type"]["shortDetail"]
                gameDate = competition["date"]
                convertedTime = time.parse_time(gameDate, format = "2006-01-02T15:04Z").in_location(timezone)
                if convertedTime.format("1/2") != now.format("1/2"):
                    # check to see if the game is today or not.   If not today, show date
                    # use settings to determine if INTL or US + time
                    if config.bool("is_us_date_format", False):
                        gameTime = convertedTime.format("1/2 ") + gameTime
                    else:
                        gameTime = convertedTime.format("2 Jan ") + gameTime
                gameName = competition["status"]["type"]["name"]

                if gameName == "STATUS_POSTPONED":
                    scoreFont = "CG-pixel-3x5-mono"

                    homeData = json.decode(get_cachable_data(API % (leagueSlug, str(competition["competitors"][0]["id"]))))
                    awayData = json.decode(get_cachable_data(API % (leagueSlug, str(competition["competitors"][1]["id"]))))

                    #if game is PPD - show records instead of blanks
                    checkHomeTeamRecord = homeData["team"]["record"].get("items", "NO")
                    if checkHomeTeamRecord == "NO":
                        homeScore = ""
                    else:
                        homeScore = checkHomeTeamRecord[0]["summary"]

                    checkAwayTeamRecord = awayData["team"]["record"].get("items", "NO")
                    if checkAwayTeamRecord == "NO":
                        awayScore = ""
                    else:
                        awayScore = checkAwayTeamRecord[0]["summary"]
                        gameTime = "Postponed"
                else:
                    homeScore = competition["competitors"][0]["score"]["displayValue"]
                    awayScore = competition["competitors"][1]["score"]["displayValue"]
                    if (int(homeScore) > int(awayScore)):
                        homeScoreColor = "#ff0"
                        awayScoreColor = "#fffc"
                    elif (int(awayScore) > int(homeScore)):
                        homeScoreColor = "#fffc"
                        awayScoreColor = "#ff0"
                    else:
                        homeScoreColor = "#fff"
                        awayScoreColor = "#fff"

                # if FT-Pens - get penalty shootout score & append to score
                if gameName == "STATUS_FINAL_PEN":
                    scoreFont = "CG-pixel-3x5-mono"
                    homeShootoutScore = competition["competitors"][0]["score"]["shootoutScore"]
                    awayShootoutScore = competition["competitors"][1]["score"]["shootoutScore"]
                    homeScore = "%s (%s)" % (homeScore, str(int(homeShootoutScore)))
                    awayScore = "%s (%s)" % (awayScore, str(int(awayShootoutScore)))
                    if (int(homeShootoutScore) > int(awayShootoutScore)):
                        homeScoreColor = "#ff0"
                        awayScoreColor = "#fffc"
                    elif (int(awayShootoutScore) > int(homeShootoutScore)):
                        homeScoreColor = "#fffc"
                        awayScoreColor = "#ff0"
                    else:
                        homeScoreColor = "#fff"
                        awayScoreColor = "#fff"

            # settle needed values into dict
            homeInfo = dict(abbreviation = home[:3], color = homeColor, teamname = homeTeamName, score = homeScore, logo = homeLogo, logosize = homeLogoSize, scorecolor = homeScoreColor)
            awayInfo = dict(abbreviation = away[:3], color = awayColor, teamname = awayTeamName, score = awayScore, logo = awayLogo, logosize = awayLogoSize, scorecolor = awayScoreColor)

            # determine which team to show first - thanks for @jesushairdo for this new option / way to display - stop being us centric always
            if config.get("team_sequence", DEFAULT_TEAM_DISPLAY) == "home":
                matchInfo = [homeInfo, awayInfo]
            else:
                matchInfo = [awayInfo, homeInfo]

            if displayType == "retro":
                retroTextColor = "#ffe065"
                retroFont = "CG-pixel-3x5-mono"

                renderCategory.extend(
                    [
                        render.Column(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "start",
                            children = [
                                render.Column(
                                    children = [
                                        render.Box(width = 64, height = 13, color = matchInfo[0]["color"], child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                            render.Box(width = 40, height = 13, child = render.Text(content = get_team_name(matchInfo[0]["teamname"]), color = retroTextColor, font = retroFont)),
                                            render.Box(width = 26, height = 13, child = render.Text(content = get_record(matchInfo[0]["score"]), color = retroTextColor, font = retroFont)),
                                        ])),
                                        render.Box(width = 64, height = 13, color = matchInfo[1]["color"], child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                            render.Box(width = 40, height = 13, child = render.Text(content = get_team_name(matchInfo[1]["teamname"]), color = retroTextColor, font = retroFont)),
                                            render.Box(width = 26, height = 13, child = render.Text(content = get_record(matchInfo[1]["score"]), color = retroTextColor, font = retroFont)),
                                        ])),
                                    ],
                                ),
                                render.Box(width = 64, height = 1),
                                render.Row(
                                    expanded = True,
                                    main_align = "end",
                                    cross_align = "center",
                                    children = get_gametime_column(gameTime, timeColor, leagueAbbr),
                                ),
                            ],
                        ),
                    ],
                )

            elif displayType == "horizontal":
                renderCategory.extend(
                    [
                        render.Column(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "start",
                            children = [
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "start",
                                    children = [
                                        render.Row(
                                            children = [
                                                render.Box(width = 32, height = 26, color = matchInfo[0]["color"], child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                                        render.Stack(children = [
                                                            render.Box(width = 32, height = 26, child = render.Image(matchInfo[0]["logo"], width = 32, height = 32)),
                                                            render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                                                render.Box(width = 32, height = 17),
                                                                render.Box(width = 32, height = 10, color = "#000a", child = render.Text(content = matchInfo[0]["score"], color = matchInfo[0]["scorecolor"], font = scoreFont)),
                                                            ]),
                                                        ]),
                                                    ]),
                                                ])),
                                                render.Box(width = 32, height = 26, color = matchInfo[1]["color"], child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                                        render.Stack(children = [
                                                            render.Box(width = 32, height = 26, child = render.Image(matchInfo[1]["logo"], width = 32, height = 32)),
                                                            render.Column(expanded = True, main_align = "start", cross_align = "center", children = [
                                                                render.Box(width = 32, height = 17),
                                                                render.Box(width = 32, height = 10, color = "#000a", child = render.Text(content = matchInfo[1]["score"], color = matchInfo[1]["scorecolor"], font = scoreFont)),
                                                            ]),
                                                        ]),
                                                    ]),
                                                ])),
                                            ],
                                        ),
                                    ],
                                ),
                                render.Box(width = 64, height = 1),
                                render.Row(
                                    expanded = True,
                                    main_align = "end",
                                    cross_align = "center",
                                    children = get_gametime_column(gameTime, timeColor, leagueAbbr),
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
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "start",
                                    children = [
                                        render.Column(
                                            children = [
                                                render.Box(width = 64, height = 12, color = matchInfo[0]["color"], child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Image(matchInfo[0]["logo"], width = 30, height = 30),
                                                    render.Box(width = 34, height = 12, child = render.Text(content = matchInfo[0]["score"], color = matchInfo[0]["scorecolor"], font = scoreFont)),
                                                ])),
                                                render.Box(width = 64, height = 12, color = matchInfo[1]["color"], child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Image(matchInfo[1]["logo"], width = 30, height = 30),
                                                    render.Box(width = 34, height = 12, child = render.Text(content = matchInfo[1]["score"], color = matchInfo[1]["scorecolor"], font = scoreFont)),
                                                ])),
                                            ],
                                        ),
                                    ],
                                ),
                                render.Box(width = 64, height = 1),
                                render.Row(
                                    expanded = True,
                                    main_align = "end",
                                    cross_align = "center",
                                    children = get_gametime_column(gameTime, timeColor, leagueAbbr),
                                ),
                            ],
                        ),
                    ],
                )

            elif displayType == "black":
                textFont = teamFont

                renderCategory.extend(
                    [
                        render.Column(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "start",
                            children = [
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "start",
                                    children = [
                                        render.Column(
                                            children = [
                                                render.Box(width = 64, height = 13, color = "#222", child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Box(width = 16, height = 15, child = render.Image(matchInfo[0]["logo"], width = awayLogoSize, height = awayLogoSize)),
                                                    render.Box(width = 24, height = 13, child = render.Text(content = matchInfo[0]["abbreviation"], color = matchInfo[0]["scorecolor"], font = textFont)),
                                                    render.Box(width = 24, height = 13, child = render.Text(content = get_record(matchInfo[0]["score"]), color = matchInfo[0]["scorecolor"], font = scoreFont)),
                                                ])),
                                                render.Box(width = 64, height = 13, color = "#222", child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Box(width = 16, height = 15, child = render.Image(matchInfo[1]["logo"], width = homeLogoSize, height = homeLogoSize)),
                                                    render.Box(width = 24, height = 13, child = render.Text(content = matchInfo[1]["abbreviation"], color = matchInfo[1]["scorecolor"], font = textFont)),
                                                    render.Box(width = 24, height = 13, child = render.Text(content = get_record(matchInfo[1]["score"]), color = matchInfo[1]["scorecolor"], font = scoreFont)),
                                                ])),
                                            ],
                                        ),
                                    ],
                                ),
                                render.Box(width = 64, height = 1),
                                render.Row(
                                    expanded = True,
                                    main_align = "end",
                                    cross_align = "center",
                                    children = get_gametime_column(gameTime, timeColor, leagueAbbr),
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
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "start",
                                    children = [
                                        render.Column(
                                            children = [
                                                render.Box(width = 64, height = 13, color = matchInfo[0]["color"] + "77", child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Box(width = 16, height = 17, child = render.Image(matchInfo[0]["logo"], width = awayLogoSize, height = awayLogoSize)),
                                                    render.Box(width = 24, height = 13, child = render.Text(content = matchInfo[0]["abbreviation"], color = matchInfo[0]["scorecolor"], font = textFont)),
                                                    render.Box(width = 24, height = 13, child = render.Text(content = get_record(matchInfo[0]["score"]), color = matchInfo[0]["scorecolor"], font = scoreFont)),
                                                ])),
                                                render.Box(width = 64, height = 13, color = matchInfo[1]["color"] + "77", child = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [
                                                    render.Box(width = 16, height = 17, child = render.Image(matchInfo[1]["logo"], width = homeLogoSize, height = homeLogoSize)),
                                                    render.Box(width = 24, height = 13, child = render.Text(content = matchInfo[1]["abbreviation"], color = matchInfo[1]["scorecolor"], font = textFont)),
                                                    render.Box(width = 24, height = 13, child = render.Text(content = get_record(matchInfo[1]["score"]), color = matchInfo[1]["scorecolor"], font = scoreFont)),
                                                ])),
                                            ],
                                        ),
                                    ],
                                ),
                                render.Box(width = 64, height = 1),
                                render.Row(
                                    expanded = True,
                                    main_align = "end",
                                    cross_align = "center",
                                    children = get_gametime_column(gameTime, timeColor, leagueAbbr),
                                ),
                            ],
                        ),
                    ],
                )

        root_child = render.Animation(children = renderCategory) if not widgetMode else renderCategory[0]

        # `supports2x: true` makes the server hand every style a 128x64 canvas.
        # The legacy 64x32 styles aren't responsive, so on a wide canvas pin them
        # to a crisp, centered 64x32 island instead of rendering broken top-left.
        # (The multi-team grid is native 2x and uses the full canvas.)
        if canvas.is2x() or canvas.width() > 64:
            root_child = render.Box(
                width = canvas.width(),
                height = canvas.height(),
                color = "#000000",
                child = render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [render.Box(width = 64, height = 32, child = root_child)],
                ),
            )
        else:
            root_child = render.Column(children = [root_child])

        return render.Root(
            delay = rotationSpeed,
            show_full_animation = True,
            child = root_child,
        ) if not widgetMode else render.Root(
            child = root_child,
        )
    else:
        return []

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
        display = "Horizontal",
        value = "horizontal",
    ),
    schema.Option(
        display = "Retro",
        value = "retro",
    ),
]

pregameOptions = [
    schema.Option(
        display = "Team Record",
        value = "record",
    ),
    schema.Option(
        display = "Nothing",
        value = "nothing",
    ),
]

displayFirstOptions = [
    schema.Option(
        display = "Away Team",
        value = "visitor",
    ),
    schema.Option(
        display = "Home Team",
        value = "home",
    ),
]

displaySpeeds = [
    schema.Option(
        display = "1 second (fast)",
        value = "1000",
    ),
    schema.Option(
        display = "1.5 seconds",
        value = "1500",
    ),
    schema.Option(
        display = "2 seconds (medium)",
        value = "2000",
    ),
    schema.Option(
        display = "2.5 seconds",
        value = "2500",
    ),
    schema.Option(
        display = "3 seconds (slow)",
        value = "3000",
    ),
]

def get_schema():
    # The server builds the settings form with the device's canvas, so
    # canvas.is2x() here is true only when configuring a 2x device. The extra
    # teams + grid color toggle are only offered there.
    is2x = canvas.is2x()

    extra_teams = []
    wide_fields = []
    if is2x:
        for i in range(len(EXTRA_TEAM_KEYS)):
            extra_teams.append(schema.Typeahead(
                id = EXTRA_TEAM_KEYS[i],
                name = "Team %d (optional)" % (i + 2),
                desc = "Add teams to show all their games at once in a grid",
                icon = "futbol",
                handler = search_teams,
            ))
        wide_fields.append(schema.Toggle(
            id = "wide_team_colors",
            name = "Team color backgrounds",
            desc = "Multi-team grid: tint each team's area with its team color (off = grey bands).",
            icon = "palette",
            default = True,
        ))

    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "teamid",
                name = "Team Name to search for",
                desc = "Team Name to search for",
                icon = "futbol",
                handler = search_teams,
            ),
        ] + extra_teams + [
            schema.Dropdown(
                id = "team_sequence",
                name = "Display which team first?",
                desc = "Home First or Away First ",
                icon = "arrowsRotate",
                default = displayFirstOptions[0].value,
                options = displayFirstOptions,
            ),
            schema.Dropdown(
                id = "displayType",
                name = "Display Type",
                desc = "Style of how the scores are displayed.",
                icon = "desktop",
                default = displayOptions[0].value,
                options = displayOptions,
            ),
        ] + wide_fields + [
            schema.Color(
                id = "displayTimeColor",
                name = "Time Color",
                desc = "Select which color you want the time to be.",
                icon = "palette",
                default = "#FFF",
            ),

            #schema.Dropdown(
            #    id = "displaySpeed",
            #    name = "Time to display each score",
            #    desc = "Display time for each score",
            #    icon = "stopwatch",
            #    default = "2000",
            #    options = displaySpeeds,
            #),
            schema.Toggle(
                id = "is_24_hour_format",
                name = "24 hour format",
                desc = "Display the time in 24 hour format.",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = "is_us_date_format",
                name = "US Date format",
                desc = "Display the date in US format (default is Intl).",
                icon = "calendarDays",
                default = False,
            ),
        ],
    )

def search_teams(team_text):
    if len(team_text) > 3:
        result = http.get(TEAM_SEARCH_API % team_text).body()
        if len(result) > 0:
            return [schema.Option(value = s["id"], display = "%s" % s["displayName"]) for s in json.decode(result)]

    return []

def get_scores(urls):
    allscores = []

    #for i, s in urls.items():
    data = get_cachable_data(urls)
    decodedata = json.decode(data)
    allscores.extend(decodedata["team"])

    #all([i, allscores])
    all(allscores)
    return decodedata["team"]

def get_detail(gamedate):
    finddash = gamedate.find("-")
    if finddash > 0:
        gameTimearray = gamedate.split(" - ")
        gameTimeval = gameTimearray[1]
    else:
        gameTimeval = gamedate
    return gameTimeval

def get_team_name(name):
    if len(name) > 9:
        theName = name[:8] + "_"
    else:
        theName = name
    return theName.upper()

def get_record(record):
    if len(record) > 6:
        theRecord = record[:5] + "_"
    else:
        theRecord = record
    return theRecord

def get_background_color(displayType, color):
    if displayType == "black" or displayType == "retro":
        color = "#222"
    else:
        color = "#" + color
    if color == "#ffffff" or color == "#000000":
        color = "#222222"
    return color

def get_logoType(logo):
    logo = logo.replace("500/scoreboard", "500-dark/scoreboard")
    logo = logo.replace("https://a.espncdn.com/", "https://a.espncdn.com/combiner/i?img=", 36000)
    logo = get_cachable_data(logo + "&h=50&w=50")
    return logo

def get_logoSize():
    logosize = int(16)
    return logosize

def get_date_column(display, now, textColor, borderColor, displayType, gameTime, timeColor):
    if display:
        theTime = now.format("3:04")
        if len(str(theTime)) > 4:
            timeBox = 24
            statusBox = 40
        else:
            timeBox = 20
            statusBox = 44
        dateTimeColumn = [
            render.Box(width = timeBox, height = 8, color = borderColor, child = render.Row(expanded = True, main_align = "center", cross_align = "center", children = [
                render.Box(width = 1, height = 8),
                render.Text(color = displayType == "retro" and textColor or timeColor, content = theTime, font = "tb-8"),
            ])),
            render.Box(width = statusBox, height = 8, child = render.Stack(children = [
                render.Box(width = statusBox, height = 8, color = displayType == "stadium" and borderColor or "#111"),
                render.Box(width = statusBox, height = 8, child = render.Row(expanded = True, main_align = "end", cross_align = "center", children = [
                    render.Text(color = textColor, content = get_shortened_display(gameTime), font = "CG-pixel-3x5-mono"),
                ])),
            ])),
        ]
    else:
        dateTimeColumn = []
    return dateTimeColumn

def get_shortened_display(text):
    if len(text) > 8:
        text = text.replace("Final", "F").replace("Game ", "G")
    words = json.decode(SHORTENED_WORDS)
    for _, s in enumerate(words):
        text = text.replace(s, words[s])
    return text

def get_gametime_column(gameTime, textColor, leagueAbbr):
    # I swear - this is the only way...

    gameTimeColumn = [
        render.WrappedText(width = 25, height = 6, content = leagueAbbr, linespacing = 1, font = "CG-pixel-3x5-mono", color = textColor, align = "center"),
        render.WrappedText(width = 39, height = 6, content = get_shortened_display(gameTime), linespacing = 1, font = "CG-pixel-3x5-mono", color = textColor, align = "right"),
    ]
    return gameTimeColumn

def get_cachable_data(url):
    res = http.get(url = url, ttl_seconds = CACHE_TTL_SECONDS)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

def get_team_id(config, key):
    # Typeahead values are stored as JSON: {"display": ..., "value": <team id>}
    raw = config.get(key)
    if not raw:
        return None
    return (json.decode(raw) or {}).get("value") or None

# ============================================================================
# Multi-team 2x grid (shown on 2x displays when any of Team 2-4 is picked)
# Same design language as the soccermens / soccerwomens Wide 4 grid, but every
# cell is a different team's game, so each cell carries its own competition +
# date strip instead of one shared header. All sizes are in LED units.
# ============================================================================

# State / accent tokens (shared with the soccermens wide styles)
W_BG = "#000000"  # pure black (LED off)
W_WIN = "#ffe14d"  # winner text (yellow)
W_WHITE = "#ffffff"  # loser / neutral text
W_LIVE = "#2ee65f"  # in-progress (green)
W_HALF = "#ffb02e"  # half-time (amber)
W_FINAL = "#7f8794"  # final / muted label (grey)
W_HDR_BG = "#11151f"  # competition strip bg (a hair lighter than black)
W_STEEL = "#444b57"  # fallback for near-black team colors
W_OFF_BG = "#262b33"  # team band when the colors toggle is OFF
W_TEAM_ALPHA = "80"  # alpha on team-color bands so they read softer over black (~50%)

W_W = 128
W_H = 64

def is_wide_canvas():
    # The device signals 2x via canvas.is2x(); CLI `-w 128 -t 64` reports width
    # 128 but not is2x. Accept either so it works on real wide hardware and in
    # local render tests.
    return canvas.is2x() or canvas.width() >= W_W

def render_wide(config, ids, timezone, now):
    team_ids = []
    for tid in ids:
        if tid and str(tid) not in team_ids:
            team_ids.append(str(tid))

    abbrs = fetch_json(ABBR_URL, ABBR_TTL) or {}

    games = []
    seen_events = {}
    for tid in team_ids:
        team = (fetch_json(API % ("all", tid), CACHE_TTL_SECONDS) or {}).get("team") or {}
        events = team.get("nextEvent") or []
        if len(events) == 0:
            continue

        # two picked teams playing each other share one cell
        event_id = events[0].get("id")
        if event_id in seen_events:
            continue
        seen_events[event_id] = True

        g = parse_game_single(events[0], team, config, timezone, now, abbrs)
        if g != None:
            games.append(g)

    if len(games) == 0:
        return []

    colors_on = config.bool("wide_team_colors", True)
    header_color = config.get("displayTimeColor", "#FFF")
    return render.Root(child = wide_grid(games, colors_on, header_color))

def fetch_json(url, ttl):
    # Soft fetch: one team's API hiccup shouldn't blank the other teams' cells.
    res = http.get(url = url, ttl_seconds = ttl)
    if res.status_code != 200:
        return None
    return json.decode(res.body())

def parse_game_single(event, tracked, config, timezone, now, abbrs):
    comps = event.get("competitions") or []
    if len(comps) == 0:
        return None
    comp = comps[0]
    competitors = comp.get("competitors") or []
    if len(competitors) < 2:
        return None
    home_c = competitors[0]
    away_c = competitors[1]
    if home_c.get("homeAway") == "away":
        home_c, away_c = away_c, home_c

    status = (comp.get("status") or {}).get("type") or {}
    state = status.get("state") or "pre"
    type_name = status.get("name") or ""
    short_detail = status.get("shortDetail") or ""
    postponed = type_name == "STATUS_POSTPONED"

    league = event.get("league") or {}
    slug = league.get("slug") or ""
    league_label = abbrs.get(slug) or (league.get("abbreviation") or slug)[0:6].strip()

    date_str = event.get("date") or ""
    if not date_str:
        return None
    dt = time.parse_time(date_str, format = "2006-01-02T15:04Z").in_location(timezone)
    if dt.format("20060102") == now.format("20060102"):
        day_text = "TODAY"
    elif config.bool("is_us_date_format", False):
        day_text = dt.format("1/2")
    else:
        day_text = dt.format("2 Jan")

    # records only matter before kickoff (or when there's no score to show)
    want_record = state == "pre" or postponed
    home = single_side(home_c, tracked, slug, want_record)
    away = single_side(away_c, tracked, slug, want_record)

    # penalty shootout: regulation score stays in the score slot; the tally goes
    # in the status strip ("FT 4-2") - a live running tally would be stale, so
    # a live shootout just says "PENS".
    hp = home["pens"]
    ap = away["pens"]
    pen_final = type_name == "STATUS_FINAL_PEN"
    pen_live = state == "in" and (hp > 0 or ap > 0)

    # winner (post only) - shown by yellow text, never a swapped background
    home_win = False
    away_win = False
    if state == "post" and not postponed:
        if pen_final:
            home_win = hp > ap
            away_win = ap > hp
        else:
            home_win = int_or(home["score"]) > int_or(away["score"])
            away_win = int_or(away["score"]) > int_or(home["score"])
    home["color_text"] = W_WIN if home_win else W_WHITE
    away["color_text"] = W_WIN if away_win else W_WHITE

    kickoff = ""
    if state == "pre":
        kickoff = wide_kickoff(dt, config)
        status_text = kickoff
        status_color = W_WHITE
    elif state == "in":
        up = short_detail.upper()
        if pen_live:
            status_text = "PENS"
            status_color = W_LIVE
        elif up.startswith("HT") or up.find("HALF") >= 0:
            status_text = "HT"
            status_color = W_HALF
        else:
            status_text = short_detail.strip()[:6]
            status_color = W_LIVE
    elif postponed:
        status_text = "PPD"
        status_color = W_FINAL
        home["score"] = ""
        away["score"] = ""
    else:
        status_text = "FT"
        status_color = W_FINAL

    # team_sequence: which team sits on top
    if config.get("team_sequence", DEFAULT_TEAM_DISPLAY) == "home":
        first, second = home, away
    else:
        first, second = away, home

    if pen_final:
        status_text = "FT %d-%d" % (first["pens"], second["pens"])

    return dict(
        state = state,
        postponed = postponed,
        league_label = league_label,
        day_text = day_text,
        status_text = status_text,
        status_color = status_color,
        first = first,
        second = second,
    )

def single_side(competitor, tracked, slug, want_record):
    team = competitor.get("team") or {}
    team_id = str(competitor.get("id") or team.get("id") or "")
    name = team.get("shortDisplayName") or team.get("displayName") or ""
    code = team.get("abbreviation") or (name[0:3].upper() if name else "?")
    logos = team.get("logos") or []
    logo_url = (logos[0].get("href") if len(logos) > 0 else "") or MISSING_LOGO

    # this endpoint nests the score: {"displayValue": "2", "shootoutScore": 4, ...}
    score = ""
    pens = 0
    sc = competitor.get("score")
    if type(sc) == "dict":
        score = str(sc.get("displayValue") or "")
        pens = int_or(sc.get("shootoutScore"))
    elif sc != None:
        score = str(sc)
    if pens == 0:
        pens = int_or(competitor.get("shootoutScore"))

    # The team-detail call carries the color; the tracked team's is already in hand.
    if team_id == str(tracked.get("id") or ""):
        color = tracked.get("color")
    else:
        color = ((fetch_json(API % ("all", team_id), TEAM_TTL_SECONDS) or {}).get("team") or {}).get("color")

    record = ""
    if want_record and slug:
        rec = ((fetch_json(API % (slug, team_id), TEAM_TTL_SECONDS) or {}).get("team") or {}).get("record") or {}
        items = rec.get("items") or []
        if len(items) > 0:
            record = str(items[0].get("summary") or "")

    return dict(
        code = code[:3],
        name = name,
        color = wide_team_color(color),
        logo = wide_logo(logo_url),
        score = score,
        pens = pens,
        record = record,
        color_text = W_WHITE,
    )

def wide_logo(url):
    if url == MISSING_LOGO:
        return get_cachable_data(MISSING_LOGO)
    url = url.replace("500/scoreboard", "500-dark/scoreboard")
    url = url.replace("https://a.espncdn.com/", "https://a.espncdn.com/combiner/i?img=", 36000)
    res = http.get(url = url + "&h=50&w=50", ttl_seconds = TEAM_TTL_SECONDS)
    if res.status_code != 200:
        return get_cachable_data(MISSING_LOGO)
    return res.body()

def int_or(v):
    if type(v) == "int":
        return v
    if type(v) == "float":
        return int(v)
    if v != None and str(v).isdigit():
        return int(str(v))
    return 0

def wide_kickoff(dt, config):
    if config.bool("is_24_hour_format", False):
        return dt.format("15:04")
    return dt.format("3:04PM")[:-1]  # strip trailing M -> "3:04P"

HEX = "0123456789abcdef"

def hex2(n):
    # Starlark's % formatting has no width/zero-pad, so build hex bytes by hand.
    if n < 0:
        n = 0
    if n > 255:
        n = 255
    return HEX[n // 16] + HEX[n % 16]

def wide_team_color(hexcolor):
    # Alpha-suffixed so the band softens against the black panel, keeping white /
    # yellow text readable. Same rules as the soccermens wide styles.
    if not hexcolor:
        return W_STEEL + W_TEAM_ALPHA
    h = hexcolor.replace("#", "")
    if len(h) != 6:
        return W_STEEL + W_TEAM_ALPHA
    r = int(h[0:2], 16)
    g = int(h[2:4], 16)
    b = int(h[4:6], 16)
    lum = (299 * r + 587 * g + 114 * b) // 1000

    # near-black is invisible on a black panel -> steel
    if lum < 55:
        return W_STEEL + W_TEAM_ALPHA

    # too light/bright kills white & yellow text -> scale down to a mid lum
    if lum > 125:
        r = (r * 125) // lum
        g = (g * 125) // lum
        b = (b * 125) // lum
    return "#" + hex2(r) + hex2(g) + hex2(b) + W_TEAM_ALPHA

# ---- grid ------------------------------------------------------------------
# 1 team: one big card. 2: two full-width cells stacked. 3: two cells on top,
# one full-width below. 4: 2x2 grid. Black 1-LED gridlines between cells.

W_CELL_H = 31  # (64 - 1 gridline) // 2
W_LEFT_W = 64  # 64 + 1 gridline + 63 == 128
W_RIGHT_W = 63

def wide_grid(games, colors_on, header_color):
    n = len(games)
    if n == 1:
        return wide_cell(games[0], W_W, W_H, colors_on, header_color)

    def cell(g, w):
        return wide_cell(g, w, W_CELL_H, colors_on, header_color)

    def pair(a, b):
        return render.Row(children = [cell(a, W_LEFT_W), render.Box(width = 1, height = W_CELL_H, color = W_BG), cell(b, W_RIGHT_W)])

    if n == 2:
        top, bottom = cell(games[0], W_W), cell(games[1], W_W)
    elif n == 3:
        top, bottom = pair(games[0], games[1]), cell(games[2], W_W)
    else:
        top, bottom = pair(games[0], games[1]), pair(games[2], games[3])

    return render.Box(
        width = W_W,
        height = W_H,
        color = W_BG,
        child = render.Column(
            expanded = True,
            main_align = "center",
            children = [top, render.Box(width = W_W, height = 1, color = W_BG), bottom],
        ),
    )

def wide_cell(g, w, h, colors_on, header_color):
    # competition + date strip / first team / second team / status strip
    big = h >= 48
    strip_h = 9 if big else 7
    status_h = 9 if big else 6
    line_h = (h - strip_h - status_h) // 2
    strip_font = "tb-8" if big else "tom-thumb"

    first = g["first"]
    second = g["second"]
    return render.Column(children = [
        render.Box(
            width = w,
            height = strip_h,
            color = W_HDR_BG,
            child = render.Padding(pad = (2, 0, 2, 0), child = render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Text(content = g["league_label"], font = strip_font, color = header_color),
                    render.Text(content = g["day_text"], font = strip_font, color = header_color),
                ],
            )),
        ),
        wide_line(g, first, first["color"] if colors_on else W_OFF_BG, w, line_h, big),
        wide_line(g, second, second["color"] if colors_on else W_OFF_BG, w, h - strip_h - status_h - line_h, big),
        render.Box(
            width = w,
            height = status_h,
            color = W_BG,
            child = render.Row(expanded = True, main_align = "center", cross_align = "center", children = [
                render.Text(content = g["status_text"], font = strip_font, color = g["status_color"]),
            ]),
        ),
    ])

def wide_line(g, side, bg, w, lh, big):
    flag_size = 18 if big else 9
    name_font = "6x13" if big else "tb-8"

    # full-width cells have room for the team name, half cells get the 3-letter code
    if big:
        label = side["name"][:11]
    elif w >= W_W:
        label = side["name"][:15]
    else:
        label = side["code"]

    if g["state"] == "pre" or g["postponed"]:
        rightval = render.Text(content = side["record"], font = "tb-8" if big else "tom-thumb", color = W_WHITE)
    else:
        rightval = render.Text(content = side["score"], font = name_font, color = side["color_text"])

    return render.Box(
        width = w,
        height = lh,
        color = bg,
        child = render.Padding(pad = (2, 0, 2, 0), child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Row(cross_align = "center", children = [
                    render.Image(src = side["logo"], width = flag_size, height = flag_size),
                    render.Box(width = 3, height = 1),
                    render.Text(content = label, font = name_font, color = side["color_text"]),
                ]),
                rightval,
            ],
        )),
    )
