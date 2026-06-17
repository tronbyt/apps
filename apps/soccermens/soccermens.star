"""
Applet: SoccerMens
Summary: Displays men's soccer scores for various leages and tournaments
Description: Displays live and upcoming soccer scores from a data feed.   Heavily taken from the other sports score apps - @LunchBox8484 is the original.
Author: jvivona
"""

# 20230812 added display of penalty kick score if applicable
#          toned down colors when display team colors - you couldn't see winner score if team color was also yellow
# 20230816 changed list of tournaments to get dynamically instead of having to do a PR each time I add one
# 20230906 found bug in ESPN API where some teams don't have abbreviation - added code to check for it and display value + indiicator
# 20240926 resolve issue where sometimes FT indicator from API is longer than can be displayed, override to show just FT
#          reduce lists cache time for comps/abbr json to 12 hours

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

VERSION = 24270

# thanks to @jesushairdo for the new option to be able to show home or away team first.  Let's be more international :-)

CACHE_TTL_SECONDS = 60
DEFAULT_TIMEZONE = "America/New_York"
SPORT = "soccer"

MISSING_LOGO = "https://upload.wikimedia.org/wikipedia/commons/c/ca/1x1.png?src=soccermens"

DEFAULT_LEAGUE = "ger.1"
API = "https://site.api.espn.com/apis/site/v2/sports/" + SPORT + "/"

ABBR_URL = "https://raw.githubusercontent.com/jvivona/tidbyt-data/main/soccermens/league_abbr.json"
COMPS_URL = "https://raw.githubusercontent.com/jvivona/tidbyt-data/main/soccermens/comps.json"
COMPS_TTL = 43200

DEFAULT_TEAM_DISPLAY = "visitor"  # default to Visitor first, then Home - US order
DEFAULT_DISPLAY_SPEED = "2000"

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

# ============================================================================
# Wide 2x layouts (display options "Wide 3" and "Wide 4")
# Designed for the native 128x64 canvas. See design handoff README.
# All sizes are in LED units (the real grid), not the mock's px.
# ============================================================================

# State / accent tokens (from the design handoff)
W_BG = "#000000"  # pure black (LED off)
W_WIN = "#ffe14d"  # winner text (yellow)
W_WHITE = "#ffffff"  # loser / neutral text
W_LIVE = "#2ee65f"  # in-progress (green)
W_HALF = "#ffb02e"  # half-time (amber)
W_FINAL = "#7f8794"  # final / muted label (grey)
W_REC = "#8a93a3"  # W-D-L record muted on black
W_DASH = "#5b6470"  # score dash
W_HDR_BG = "#11151f"  # header bg (a hair lighter than black)
W_HDR_RULE = "#232a38"  # header bottom rule
W_STEEL = "#444b57"  # fallback for near-black team colors

# Game box when the colors toggle is OFF, so games read as separate boxes (split
# by the black gridlines) instead of blending into one black field.
W_OFF_BG = "#262b33"
W_TEAM_ALPHA = "80"  # alpha on team-color bands so they read softer over black (~50%)

# Fonts (bitmap, real sizes). Hero numerals re-derived to fit the 18-LED row:
# terminus-16 + an 8-LED status will not co-exist in one row, so the hero score
# uses 6x13 and the status uses tom-thumb. See README "Fidelity" note.
W_FONT_HEADER = "tb-8"
W_FONT_CODE = "tb-8"
W_FONT_REC = "tb-8"
W_FONT_SCORE = "6x10"  # hero score / kickoff in Wide 3 (was 6x13 — toned down)
W3_STATUS_FONT = "CG-pixel-3x5-mono"  # Wide 3 status line (5 LED, fits under 6x13)
W_FONT_STATUS = "tom-thumb"  # Wide 3/4 status chips / records
W_FONT_CELL = "tb-8"  # code + score in Wide 4 cells

# Geometry (LED units)
W_W = 128
W_H = 64
W_HEADER_H = 8  # 7 bg + 1 rule (all-caps day header has no descenders)

# Narrow center score column in Wide 3, to widen the team zones so a two-digit
# W-D-L record ("20-8-10") clears the center.
W3_CENTER_W = 26
W3_ROW_H = 18  # 3 rows * 18 + 2 * 1 divider == 56 body, exact
W3_FLAG = 16  # flag/crest in Wide 3 zone
W4_FLAG = 9  # flag/crest in Wide 4 cell line

def main(config):
    LEAGUE_ABBR = json.decode(http.get(url = ABBR_URL, ttl_seconds = COMPS_TTL).body())
    renderCategory = []
    selectedLeague = config.get("leagueOptions", DEFAULT_LEAGUE)
    leagueAbbr = LEAGUE_ABBR[selectedLeague]

    # we already need now value in multiple places - so just go ahead and get it and use it
    timezone = time.tz()
    now = time.now().in_location(timezone)

    # calculate start and end date if we are set to use range of days
    date_range_search = ""
    if config.bool("day_range", False):
        back_time = now - time.parse_duration("%dh" % (int(config.get("days_back", 1)) * 24))
        fwd_time = now + time.parse_duration("%dh" % (int(config.get("days_forward", 1)) * 24))
        date_range_search = "?dates=%s-%s" % (back_time.format("20060102"), (fwd_time.format("20060102")))

    scoreboard_url = API + selectedLeague + "/scoreboard" + date_range_search
    league = {API: scoreboard_url}

    scores = get_scores(league)

    if len(scores) > 0:
        displayType = config.get("displayType", "colors")

        # New 2x wide styles take a completely separate render path.
        if displayType == "wide3" or displayType == "wide4":
            return render_wide(config, scores, displayType, timezone, leagueAbbr, scoreboard_url)

        #logoType = config.get("logoType", "primary")
        timeColor = config.get("displayTimeColor", "#FFF")

        rotationSpeed = int(config.get("displaySpeed", DEFAULT_DISPLAY_SPEED))

        for _, s in enumerate(scores):
            gameStatus = s["status"]["type"]["state"]
            competition = s["competitions"][0]
            homeCompetitor = competition["competitors"][0]
            home = competition["competitors"][0]["team"].get("abbreviation", competition["competitors"][0]["team"]["name"][0:2].upper() + "*")
            away = competition["competitors"][1]["team"].get("abbreviation", competition["competitors"][1]["team"]["name"][0:2].upper() + "*")
            homeTeamName = competition["competitors"][0]["team"]["shortDisplayName"]
            awayTeamName = competition["competitors"][1]["team"]["shortDisplayName"]
            homeColorCheck = competition["competitors"][0]["team"].get("color", "NO")
            if homeColorCheck == "NO":
                homePrimaryColor = "000000"
            else:
                homePrimaryColor = competition["competitors"][0]["team"]["color"]

            awayColorCheck = competition["competitors"][1]["team"].get("color", "NO")
            if awayColorCheck == "NO":
                awayPrimaryColor = "000000"
            else:
                awayPrimaryColor = competition["competitors"][1]["team"]["color"]

            homeColor = get_background_color(displayType, homePrimaryColor)
            awayColor = get_background_color(displayType, awayPrimaryColor)

            homeLogoCheck = competition["competitors"][0]["team"].get("logo", "NO")
            if homeLogoCheck == "NO":
                homeLogoURL = "https://a.espncdn.com/i/espn/misc_logos/500/ncaa_football.vresize.50.50.medium.1.png"
            else:
                homeLogoURL = competition["competitors"][0]["team"]["logo"]

            awayLogoCheck = competition["competitors"][1]["team"].get("logo", "NO")
            if awayLogoCheck == "NO":
                awayLogoURL = "https://a.espncdn.com/i/espn/misc_logos/500/ncaa_football.vresize.50.50.medium.1.png"
            else:
                awayLogoURL = competition["competitors"][1]["team"]["logo"]
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
                checkSeries = competition.get("series", "NO")
                checkRecord = homeCompetitor.get("records", "NO")
                if checkRecord == "NO":
                    homeScore = ""
                    awayScore = ""
                else:
                    homeScore = competition["competitors"][0]["records"][0]["summary"]
                    awayScore = competition["competitors"][1]["records"][0]["summary"]

            if gameStatus == "in":
                gameTime = s["status"]["type"]["shortDetail"]
                homeScore = competition["competitors"][0]["score"]
                homeScoreColor = "#fff"
                awayScore = competition["competitors"][1]["score"]
                awayScoreColor = "#fff"

            if gameStatus == "post":
                gameTime = s["status"]["type"]["shortDetail"]
                gameDate = s["date"]
                convertedTime = time.parse_time(gameDate, format = "2006-01-02T15:04Z").in_location(timezone)
                if convertedTime.format("1/2") != now.format("1/2"):
                    # check to see if the game is today or not.   If not today, show date
                    # use settings to determine if INTL or US + time
                    if config.bool("is_us_date_format", False):
                        gameTime = convertedTime.format("1/2 ") + gameTime
                    else:
                        gameTime = convertedTime.format("2 Jan ") + gameTime
                gameName = s["status"]["type"]["name"]
                checkSeries = competition.get("series", "NO")
                checkNotes = len(competition["notes"])
                if checkSeries != "NO":
                    seriesNote = competition["notes"][0]["headline"].split(" - ")[0]
                    gameTime = seriesNote
                if checkNotes > 0 and checkSeries == "NO":
                    gameHeadline = competition["notes"][0]["headline"]
                    if gameHeadline.find(" - ") > 0:
                        gameNoteArray = gameHeadline.split(" - ")
                        gameTime = str(gameNoteArray[1]) + " / " + gameTime
                if gameName == "STATUS_POSTPONED":
                    scoreFont = "CG-pixel-3x5-mono"

                    #if game is PPD - show records instead of blanks
                    homeScore = competition["competitors"][0]["records"][0]["summary"]
                    awayScore = competition["competitors"][1]["records"][0]["summary"]
                    gameTime = "Postponed"
                else:
                    homeScore = competition["competitors"][0]["score"]
                    awayScore = competition["competitors"][1]["score"]
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
                    homeShootoutScore = competition["competitors"][0]["shootoutScore"]
                    awayShootoutScore = competition["competitors"][1]["shootoutScore"]
                    homeScore = "%s (%s)" % (homeScore, homeShootoutScore)
                    awayScore = "%s (%s)" % (awayScore, awayShootoutScore)
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

        anim = render.Animation(children = renderCategory)

        # `supports2x: true` makes the server hand every style a 128x64 canvas.
        # The legacy 64x32 styles aren't responsive, so on a wide canvas pin them
        # to a crisp, centered 64x32 island instead of rendering broken top-left.
        # (Wide 3/4 are the native 2x styles and use the full canvas.)
        if canvas.is2x() or canvas.width() > 64:
            root_child = render.Box(
                width = canvas.width(),
                height = canvas.height(),
                color = "#000000",
                child = render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [render.Box(width = 64, height = 32, child = anim)],
                ),
            )
        else:
            root_child = render.Column(children = [anim])

        return render.Root(
            delay = rotationSpeed,
            show_full_animation = True,
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
    schema.Option(
        display = "Wide · 3 Games (2x)",
        value = "wide3",
    ),
    schema.Option(
        display = "Wide · 4 Games (2x)",
        value = "wide4",
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

daysOptions = [
    schema.Option(
        display = "0",
        value = "0",
    ),
    schema.Option(
        display = "1",
        value = "1",
    ),
    schema.Option(
        display = "2",
        value = "2",
    ),
    schema.Option(
        display = "3",
        value = "3",
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
    http_response = http.get(url = COMPS_URL, ttl_seconds = COMPS_TTL)
    if http_response.status_code != 200:
        fail("Comp list request failed with status {} and result {}".format(http_response.status_code, http_response.body()))
    comps = json.decode(http_response.body())
    comp_options = []

    if len(comps) > 0:
        for comp in comps:
            comp_options.append(
                schema.Option(
                    display = comp["display"],
                    value = comp["value"],
                ),
            )

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "leagueOptions",
                name = "League / Tournament",
                desc = "League or Tournament ",
                icon = "futbol",
                default = comp_options[0].value,
                options = comp_options,
            ),
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
            schema.Generated(
                id = "wide_generated",
                source = "displayType",
                handler = show_wide_options,
            ),
            schema.Color(
                id = "displayTimeColor",
                name = "Time Color",
                desc = "Select which color you want the time to be.",
                icon = "palette",
                default = "#FFF",
            ),
            schema.Dropdown(
                id = "displaySpeed",
                name = "Time to display each score",
                desc = "Display time for each score",
                icon = "stopwatch",
                default = "2000",
                options = displaySpeeds,
            ),
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
            schema.Toggle(
                id = "day_range",
                name = "Enable range of days",
                desc = "Enable showing scores in a range of days",
                icon = "rightLeft",
                default = False,
            ),
            schema.Generated(
                id = "generated",
                source = "day_range",
                handler = show_day_range,
            ),
        ],
    )

def show_wide_options(displayType):
    # Team-colors background toggle only applies to the wide 2x styles.
    if displayType == "wide3" or displayType == "wide4":
        return [
            schema.Toggle(
                id = "wide_team_colors",
                name = "Team color backgrounds",
                desc = "Tint each team's area with its team color (off = black bands).",
                icon = "palette",
                default = True,
            ),
        ]
    else:
        return []

def show_day_range(day_range):
    # need to do the string comparison here to make it consistent instead of converting to bool - its a whole thing
    if day_range == "true":
        return [
            schema.Dropdown(
                id = "days_back",
                name = "# of days back to show",
                desc = "Number of days back to search for scores",
                icon = "arrowLeft",
                default = "1",
                options = daysOptions,
            ),
            schema.Dropdown(
                id = "days_forward",
                name = "# of days forward to show",
                desc = "Number of days forward to search for scores",
                icon = "arrowRight",
                default = "1",
                options = daysOptions,
            ),
        ]
    else:
        return []

def get_scores(urls):
    allscores = []
    for i, s in urls.items():
        data = get_cachable_data(s)
        decodedata = json.decode(data)
        allscores.extend(decodedata["events"])
        all([i, allscores])

    return allscores

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

# ============================================================================
# Wide 2x layouts — render path
# ============================================================================

def render_wide(config, scores, displayType, timezone, leagueAbbr, scoreboard_url):
    # These layouts need the native 128x64 (2x) canvas. The device signals 2x via
    # canvas.is2x() (requires `supports2x: true` in manifest.yaml, or the server
    # renders 1x); CLI `-w 128 -t 64` reports width 128 but not is2x. Accept
    # either so it works on real wide hardware and in local render tests.
    if not (canvas.is2x() or canvas.width() >= W_W):
        return wide_needs_2x()

    perPage = {"wide3": 3, "wide4": 4}[displayType]
    colors_on = config.bool("wide_team_colors", True)
    rotationSpeed = int(config.get("displaySpeed", DEFAULT_DISPLAY_SPEED))
    comp_label = get_comp_label(scoreboard_url, leagueAbbr)

    # Header (competition + date) color, so back-to-back apps can be tinted apart.
    header_color = config.get("displayTimeColor", "#FFF")

    games = []
    for s in scores:
        g = parse_game_wide(s, config, timezone)
        if g != None:
            games.append(g)

    pages = build_pages(games, perPage)
    if len(pages) == 0:
        return []

    frames = []
    for pg in pages:
        if displayType == "wide3":
            frames.append(wide3_page(pg, comp_label, header_color, colors_on))
        else:
            frames.append(wide4_page(pg, comp_label, header_color, colors_on))

    # Each page is one static frame; the per-frame delay is the rotation timer,
    # so every page in the window shows at least once per loop.
    return render.Root(
        delay = rotationSpeed,
        show_full_animation = True,
        child = render.Column(children = [render.Animation(children = frames)]),
    )

def get_comp_label(scoreboard_url, leagueAbbr):
    # Cache-hit reuse of the scoreboard fetch just to read the competition name
    # (leagues[0].abbreviation, e.g. "FIFA World Cup") for the header. Works for
    # every league/tournament the app offers; falls back to the short league code.
    data = json.decode(get_cachable_data(scoreboard_url))
    leagues = data.get("leagues", [])
    if len(leagues) > 0:
        abbr = leagues[0].get("abbreviation", "")
        if abbr != "":
            return abbr
    return leagueAbbr

def parse_game_wide(s, config, timezone):
    comp = s["competitions"][0]
    competitors = comp["competitors"]
    if len(competitors) < 2:
        return None

    state = s["status"]["type"]["state"]
    type_name = s["status"]["type"].get("name", "")
    short_detail = s["status"]["type"].get("shortDetail", "")

    # local date for day grouping + header (short, no weekday)
    dt = time.parse_time(s["date"], format = "2006-01-02T15:04Z").in_location(timezone)
    day_key = dt.format("20060102")
    if config.bool("is_us_date_format", False):
        date_text = dt.format("1/2")  # e.g. "6/17"
    else:
        date_text = dt.format("2 Jan")  # e.g. "17 Jun"

    home = wide_side(competitors[0])
    away = wide_side(competitors[1])

    # penalty shootout: scores present while pens are live AND after (FINAL_PEN).
    # The regulation score stays in the score slot; the tally goes in the status
    # ("PK 4-2" live / "FT 4-2" final) since 0(4)-0(2) won't fit the narrow center.
    hp = competitors[0].get("shootoutScore", "0")
    ap = competitors[1].get("shootoutScore", "0")
    pen_final = type_name == "STATUS_FINAL_PEN"
    pen_live = state == "in" and (hp != "0" or ap != "0")

    # winner (post only) — shown by yellow text, never a swapped background
    home_win = False
    away_win = False
    if state == "post" and type_name != "STATUS_POSTPONED":
        if pen_final:
            home_win = int_or(hp) > int_or(ap)
            away_win = int_or(ap) > int_or(hp)
        else:
            home_win = int_or(home["score"]) > int_or(away["score"])
            away_win = int_or(away["score"]) > int_or(home["score"])

    # status text + color + kickoff
    is_live = False
    kickoff = ""
    if state == "pre":
        kickoff = wide_kickoff(s["date"], config, timezone)
        status_text = ""
        status_color = W_FINAL
    elif state == "in":
        up = short_detail.upper()
        if pen_live:
            status_text = "PENS"  # live shootout; a tally here would be stale, omit it
            status_color = W_LIVE
            is_live = True
        elif up.startswith("HT") or up.find("HALF") >= 0:
            status_text = "HT"
            status_color = W_HALF
        else:
            status_text = short_detail.strip()[:6]
            status_color = W_LIVE
            is_live = True
    elif type_name == "STATUS_POSTPONED":
        status_text = "PPD"
        status_color = W_FINAL
        home["score"] = ""
        away["score"] = ""
    else:  # post
        status_text = "FT"
        status_color = W_FINAL

    home["code_color"] = W_WIN if home_win else W_WHITE
    away["code_color"] = W_WIN if away_win else W_WHITE
    home["score_color"] = W_WIN if home_win else W_WHITE
    away["score_color"] = W_WIN if away_win else W_WHITE

    # team_sequence: which team sits on the left (home zone)
    if config.get("team_sequence", DEFAULT_TEAM_DISPLAY) == "home":
        left, right = home, away
        lp, rp = hp, ap
    else:
        left, right = away, home
        lp, rp = ap, hp

    # final shootout: append the tally (display order) -> "FT 4-2". Live shootouts
    # stay just "PENS" (the running tally would be stale between refreshes).
    has_pen = pen_final
    if pen_final:
        status_text = status_text + " " + lp + "-" + rp

    return dict(
        state = state,
        is_live = is_live,
        status_text = status_text,
        status_color = status_color,
        kickoff = kickoff,
        has_pen = has_pen,
        day_key = day_key,
        date_text = date_text,
        left = left,
        right = right,
    )

def wide_side(competitor):
    team = competitor["team"]
    name = team.get("name", "")
    code = team.get("abbreviation", name[0:3].upper() if name != "" else "?")
    logo_url = team.get("logo", "") or MISSING_LOGO
    score = competitor.get("score", "")
    record = ""
    recs = competitor.get("records", None)
    if recs != None and len(recs) > 0:
        record = recs[0].get("summary", "")
    return dict(
        code = code[:3],
        color = wide_team_color(team.get("color", "")),
        logo = get_logoType(logo_url),
        score = score,
        record = record,
        code_color = W_WHITE,
        score_color = W_WHITE,
    )

def int_or(v):
    if v != None and str(v).isdigit():
        return int(v)
    return 0

def wide_kickoff(date_str, config, timezone):
    t = time.parse_time(date_str, format = "2006-01-02T15:04Z").in_location(timezone)
    if config.bool("is_24_hour_format", False):
        return t.format("15:04")
    return t.format("3:04PM")[:-1]  # strip trailing M -> "3:04P"

HEX = "0123456789abcdef"

def hex2(n):
    # Starlark's % formatting has no width/zero-pad, so build hex bytes by hand.
    if n < 0:
        n = 0
    if n > 255:
        n = 255
    return HEX[n // 16] + HEX[n % 16]

def wide_team_color(hexcolor):
    # Returned with an alpha suffix so the band softens against the black panel
    # (same idea as the legacy "colors" style's 77 alpha), keeping white/yellow
    # text readable.
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

def build_pages(games, perPage):
    # Group by local day in feed (kickoff) order, chunk each day into pages of
    # perPage, skip empty days, flatten day-by-day, page-by-page.
    order = []
    bucket = {}
    for g in games:
        k = g["day_key"]
        if k not in bucket:
            bucket[k] = []
            order.append(k)
        bucket[k].append(g)

    pages = []
    for k in order:
        dgames = bucket[k]
        npages = (len(dgames) + perPage - 1) // perPage
        for p in range(npages):
            pages.append(dict(
                date_text = dgames[0]["date_text"],
                games = dgames[p * perPage:(p + 1) * perPage],
            ))
    return pages

# ---- shared chrome ---------------------------------------------------------

def wide_header(comp_label, date_text, text_color):
    # Competition (what you're looking at) on the left, short date on the right.
    # Both take the user's "Time Color" so back-to-back apps can be tinted apart.
    return render.Column(children = [
        render.Box(
            width = W_W,
            height = W_HEADER_H - 1,
            color = W_HDR_BG,
            child = render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Padding(pad = (2, 0, 0, 0), child = render.Text(content = comp_label, font = W_FONT_HEADER, color = text_color)),
                    render.Padding(pad = (0, 0, 2, 0), child = render.Text(content = date_text, font = W_FONT_HEADER, color = text_color)),
                ],
            ),
        ),
        render.Box(width = W_W, height = 1, color = W_HDR_RULE),
    ])

def wide_needs_2x():
    # 1x devices can't fit the wide layouts; explain rather than render garbage.
    return render.Root(
        child = render.Box(
            width = 64,
            height = 32,
            color = W_BG,
            child = render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text(content = "WIDE VIEW", font = "tb-8", color = W_WIN),
                    render.Box(width = 1, height = 1),
                    render.Text(content = "needs a 2x", font = "tom-thumb", color = W_WHITE),
                    render.Text(content = "display", font = "tom-thumb", color = W_WHITE),
                ],
            ),
        ),
    )

# ---- Wide 3 ----------------------------------------------------------------

def wide3_page(pg, comp_label, header_color, colors_on):
    games = pg["games"]
    rows = []
    for i in range(len(games)):
        if i > 0:
            rows.append(render.Box(width = W_W, height = 1, color = W_BG))
        rows.append(wide3_row(games[i], colors_on))
    body = render.Box(
        width = W_W,
        height = W_H - W_HEADER_H,
        child = render.Column(expanded = True, main_align = "center", cross_align = "center", children = rows),
    )
    return render.Column(children = [wide_header(comp_label, pg["date_text"], header_color), body])

def wide3_row(g, colors_on):
    left = g["left"]
    right = g["right"]
    lcolor = left["color"] if colors_on else W_OFF_BG
    rcolor = right["color"] if colors_on else W_OFF_BG
    zone_w = (W_W - W3_CENTER_W) // 2  # 47
    return render.Row(
        expanded = True,
        cross_align = "center",
        children = [
            wide3_zone(left, lcolor, "left", zone_w),
            wide3_center(g),
            wide3_zone(right, rcolor, "right", zone_w),
        ],
    )

def wide3_zone(side, bg, side_name, w):
    flag = render.Image(src = side["logo"], width = W3_FLAG, height = W3_FLAG)
    show_rec = side["record"] != ""

    # W-D-L record sits on its own line under the code (the zone can't fit
    # flag+code+record side by side). Shown for every state — the game's score or
    # kickoff lives in the center column.
    if show_rec:
        idblock = render.Column(
            cross_align = "start" if side_name == "left" else "end",
            children = [
                render.Text(content = side["code"], font = W_FONT_CODE, color = side["code_color"]),
                render.Text(content = side["record"], font = W_FONT_STATUS, color = W_WHITE),
            ],
        )
    else:
        idblock = render.Text(content = side["code"], font = W_FONT_CODE, color = side["code_color"])

    if side_name == "left":
        inner = render.Row(expanded = True, main_align = "start", cross_align = "center", children = [flag, render.Box(width = 4, height = 1), idblock])
        pad = (2, 0, 0, 0)
    else:
        inner = render.Row(expanded = True, main_align = "end", cross_align = "center", children = [idblock, render.Box(width = 4, height = 1), flag])
        pad = (0, 0, 2, 0)

    return render.Box(width = w, height = W3_ROW_H, color = bg, child = render.Padding(pad = pad, child = inner))

def wide3_center(g):
    if g["state"] == "pre":
        # tb-8 (not the hero 6x10) so a 6-char kickoff like "12:00A" fits the
        # narrow center column.
        kids = [render.Text(content = g["kickoff"], font = W_FONT_HEADER, color = W_WHITE)]
    else:
        score_row = render.Row(cross_align = "center", children = [
            render.Text(content = g["left"]["score"], font = W_FONT_SCORE, color = g["left"]["score_color"]),
            render.Box(width = 2, height = 1),
            render.Text(content = "-", font = W_FONT_SCORE, color = W_DASH),
            render.Box(width = 2, height = 1),
            render.Text(content = g["right"]["score"], font = W_FONT_SCORE, color = g["right"]["score_color"]),
        ])

        # The time already renders green for a live match, so it carries the
        # in-progress signal on its own — no separate pulse dot needed.
        status = render.Text(content = g["status_text"], font = W3_STATUS_FONT, color = g["status_color"])
        kids = [score_row, status]
    return render.Box(
        width = W3_CENTER_W,
        height = W3_ROW_H,
        color = W_BG,
        child = render.Column(expanded = True, main_align = "center", cross_align = "center", children = kids),
    )

# ---- Wide 4 ----------------------------------------------------------------
# A 2x2 grid. The cells (~63 wide) are roomy enough to keep the flag, code,
# score/record AND a status line (FT/HT/clock/kickoff) below each game.

def wide4_page(pg, comp_label, header_color, colors_on):
    games = pg["games"]
    n = len(games)
    cols = 2
    grid_rows = [games[r:r + cols] for r in range(0, n, cols)]
    cell_w = (W_W - (cols - 1)) // cols  # 63, black gridlines between cells
    body_h = W_H - W_HEADER_H  # 56
    cell_h = (body_h - 1) // 2  # 27

    row_widgets = []
    for ri in range(len(grid_rows)):
        if ri > 0:
            row_widgets.append(render.Box(width = W_W, height = 1, color = W_BG))
        cells = []
        for ci in range(len(grid_rows[ri])):
            if ci > 0:
                cells.append(render.Box(width = 1, height = cell_h, color = W_BG))
            cells.append(wide4_cell(grid_rows[ri][ci], colors_on, cell_w, cell_h))
        row_widgets.append(render.Row(main_align = "center", cross_align = "center", children = cells))

    body = render.Box(
        width = W_W,
        height = body_h,
        child = render.Column(expanded = True, main_align = "center", cross_align = "center", children = row_widgets),
    )
    return render.Column(children = [wide_header(comp_label, pg["date_text"], header_color), body])

def wide4_cell(g, colors_on, w, h):
    left = g["left"]
    right = g["right"]
    lc = left["color"] if colors_on else W_OFF_BG
    rc = right["color"] if colors_on else W_OFF_BG
    status_h = 7
    line_h = (h - status_h) // 2
    return render.Column(children = [
        wide4_line(g, left, lc, line_h, w),
        wide4_line(g, right, rc, h - status_h - line_h, w),
        wide4_status(g, w, status_h),
    ])

def wide4_line(g, side, bg, lh, w):
    flag = render.Image(src = side["logo"], width = W4_FLAG, height = W4_FLAG)
    code = render.Text(content = side["code"], font = W_FONT_CELL, color = side["code_color"])
    if g["state"] == "pre":
        rightval = render.Text(content = side["record"], font = W_FONT_STATUS, color = W_WHITE)
    else:
        rightval = render.Text(content = side["score"], font = W_FONT_CELL, color = side["score_color"])
    return render.Box(
        width = w,
        height = lh,
        color = bg,
        child = render.Padding(pad = (2, 0, 2, 0), child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Row(cross_align = "center", children = [flag, render.Box(width = 3, height = 1), code]),
                rightval,
            ],
        )),
    )

def wide4_status(g, w, h):
    # Black status footer with the game time/state centered: kickoff (upcoming),
    # clock (live, green), HT (amber) or FT (grey). A live match already reads as
    # in-progress from the green clock, so there's no separate pulse dot.
    if g["state"] == "pre":
        kids = [render.Text(content = g["kickoff"], font = W_FONT_STATUS, color = W_WHITE)]
    else:
        kids = [render.Text(content = g["status_text"], font = W_FONT_STATUS, color = g["status_color"])]
    return render.Box(
        width = w,
        height = h,
        color = W_BG,
        child = render.Row(expanded = True, main_align = "center", cross_align = "center", children = kids),
    )
