"""
Applet: NHL Next Game
Summary: Gets Next Game Info
Description: Gets info on preferred NHL teams next game.
Author: AKKanMan
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/img_01d99a02.png", IMG_01d99a02_ASSET = "file")
load("images/img_038e492a.png", IMG_038e492a_ASSET = "file")
load("images/img_13e8e8f8.png", IMG_13e8e8f8_ASSET = "file")
load("images/img_14824432.png", IMG_14824432_ASSET = "file")
load("images/img_1b535193.png", IMG_1b535193_ASSET = "file")
load("images/img_1f68820b.png", IMG_1f68820b_ASSET = "file")
load("images/img_268d3e8f.png", IMG_268d3e8f_ASSET = "file")
load("images/img_2efed4c8.png", IMG_2efed4c8_ASSET = "file")
load("images/img_2fac0c2c.png", IMG_2fac0c2c_ASSET = "file")
load("images/img_3431b90f.png", IMG_3431b90f_ASSET = "file")
load("images/img_3fc9c4be.png", IMG_3fc9c4be_ASSET = "file")
load("images/img_41468249.png", IMG_41468249_ASSET = "file")
load("images/img_52ce3f9f.png", IMG_52ce3f9f_ASSET = "file")
load("images/img_77716713.png", IMG_77716713_ASSET = "file")
load("images/img_8548dabb.png", IMG_8548dabb_ASSET = "file")
load("images/img_92602d88.png", IMG_92602d88_ASSET = "file")
load("images/img_94c3653d.png", IMG_94c3653d_ASSET = "file")
load("images/img_97bcc840.png", IMG_97bcc840_ASSET = "file")
load("images/img_a31a5920.png", IMG_a31a5920_ASSET = "file")
load("images/img_aa9f76da.png", IMG_aa9f76da_ASSET = "file")
load("images/img_b59ce7fc.png", IMG_b59ce7fc_ASSET = "file")
load("images/img_bd928a09.png", IMG_bd928a09_ASSET = "file")
load("images/img_c0a3c133.png", IMG_c0a3c133_ASSET = "file")
load("images/img_c36025a5.png", IMG_c36025a5_ASSET = "file")
load("images/img_c9c2185d.png", IMG_c9c2185d_ASSET = "file")
load("images/img_cb7906a9.png", IMG_cb7906a9_ASSET = "file")
load("images/img_cba54416.png", IMG_cba54416_ASSET = "file")
load("images/img_d3caf455.png", IMG_d3caf455_ASSET = "file")
load("images/img_d59fde8d.png", IMG_d59fde8d_ASSET = "file")
load("images/img_e6d07705.png", IMG_e6d07705_ASSET = "file")
load("images/img_ebb5bd2e.png", IMG_ebb5bd2e_ASSET = "file")
load("images/img_ec0980fe.png", IMG_ec0980fe_ASSET = "file")

def getTeamIconFromID(teamID):
    if teamID == 2:  #NYI
        return (IMG_d59fde8d_ASSET.readall())
    elif teamID == 24:  #ANA
        return (IMG_14824432_ASSET.readall())
    elif teamID == 53:  #ARI
        return (IMG_c36025a5_ASSET.readall())
    elif teamID == 6:  #BOS
        return (IMG_2fac0c2c_ASSET.readall())
    elif teamID == 7:  #BUF
        return (IMG_e6d07705_ASSET.readall())
    elif teamID == 20:  #CGY
        return (IMG_d3caf455_ASSET.readall())
    elif teamID == 12:  #CAR
        return (IMG_94c3653d_ASSET.readall())
    elif teamID == 16:  #CHI
        return (IMG_c0a3c133_ASSET.readall())
    elif teamID == 21:  #COL
        return (IMG_bd928a09_ASSET.readall())
    elif teamID == 29:  #CBJ
        return (IMG_ebb5bd2e_ASSET.readall())
    elif teamID == 25:  #DAL
        return (IMG_1b535193_ASSET.readall())
    elif teamID == 17:  #DET
        return (IMG_a31a5920_ASSET.readall())
    elif teamID == 22:  #EDM
        return (IMG_77716713_ASSET.readall())
    elif teamID == 13:  #FLA
        return (IMG_b59ce7fc_ASSET.readall())
    elif teamID == 26:  #LAK
        return (IMG_01d99a02_ASSET.readall())
    elif teamID == 30:  #MIN
        return (IMG_1f68820b_ASSET.readall())
    elif teamID == 8:  #MTL
        return (IMG_038e492a_ASSET.readall())
    elif teamID == 18:  #NSH
        return IMG_41468249_ASSET.readall()
    elif teamID == 1:  #NJD
        return IMG_268d3e8f_ASSET.readall()
    elif teamID == 3:  #NYR
        return IMG_cba54416_ASSET.readall()
    elif teamID == 9:  #OTT
        return IMG_ec0980fe_ASSET.readall()
    elif teamID == 4:  #PHI
        return IMG_c9c2185d_ASSET.readall()
    elif teamID == 5:  #PIT
        return IMG_aa9f76da_ASSET.readall()
    elif teamID == 28:  #SJS
        return IMG_3431b90f_ASSET.readall()
    elif teamID == 55:  #SEA
        return IMG_13e8e8f8_ASSET.readall()
    elif teamID == 19:  #STL
        return IMG_52ce3f9f_ASSET.readall()
    elif teamID == 14:  #TBL
        return IMG_cb7906a9_ASSET.readall()
    elif teamID == 10:  #TOR
        return IMG_97bcc840_ASSET.readall()
    elif teamID == 23:  #VAN
        return IMG_2efed4c8_ASSET.readall()
    elif teamID == 54:  #VGK
        return IMG_92602d88_ASSET.readall()
    elif teamID == 15:  #WSH
        return IMG_8548dabb_ASSET.readall()
    elif teamID == 52:  #WPG
        return IMG_3fc9c4be_ASSET.readall()
    else:
        return ""

def getTeamAbbFromID(teamID):
    if teamID == 2:  #NYI
        return ("NYI")
    elif teamID == 24:  #ANA
        return ("ANA")
    elif teamID == 53:  #ARI
        return ("ARI")
    elif teamID == 6:  #BOS
        return ("BOS")
    elif teamID == 7:  #BUF
        return ("BUF")
    elif teamID == 20:  #CGY
        return ("CGY")
    elif teamID == 12:  #CAR
        return ("CAR")
    elif teamID == 16:  #CHI
        return ("CHI")
    elif teamID == 21:  #COL
        return ("COL")
    elif teamID == 29:  #CBJ
        return ("CBJ")
    elif teamID == 25:  #DAL
        return ("DAL")
    elif teamID == 17:  #DET
        return ("DET")
    elif teamID == 22:  #EDM
        return ("EDM")
    elif teamID == 13:  #FLA
        return ("FLA")
    elif teamID == 26:  #LAK
        return ("LAK")
    elif teamID == 30:  #MIN
        return ("MIN")
    elif teamID == 8:  #MTL
        return ("MTL")
    elif teamID == 18:  #NSH
        return "NSH"
    elif teamID == 1:  #NJD
        return "NJD"
    elif teamID == 3:  #NYR
        return "NYR"
    elif teamID == 9:  #OTT
        return "OTT"
    elif teamID == 4:  #PHI
        return "PHI"
    elif teamID == 5:  #PIT
        return "PIT"
    elif teamID == 28:  #SJS
        return "SJS"
    elif teamID == 55:  #SEA
        return "SEA"
    elif teamID == 19:  #STL
        return "STL"
    elif teamID == 14:  #TBL
        return "TBL"
    elif teamID == 10:  #TOR
        return "TOR"
    elif teamID == 23:  #VAN
        return "VAN"
    elif teamID == 54:  #VGK
        return "VGK"
    elif teamID == 15:  #WSH
        return "WSH"
    elif teamID == 52:  #WPG
        return "WPG"
    else:
        return ""

def main(config):
    # Get data out of config
    main_team_id = config.str("main_team") or "24"
    time_zone_str = config.str("time_zone") or "America/New_York"
    #---------------------------------------

    TEAM_NEXT_GAME_JSON = "https://statsapi.web.nhl.com/api/v1/teams/" + str(main_team_id) + "?expand=team.schedule.next"

    nhldata_cached = cache.get("nhl_data/%s" % main_team_id)
    if nhldata_cached != None:
        nhldata = json.decode(nhldata_cached)
    else:
        print("Miss! Calling NHL API.")
        rep = http.get(TEAM_NEXT_GAME_JSON)
        if rep.status_code != 200:
            fail("NHL API request failed with status %d", rep.status_code)
        nhldata = rep.json()

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("nhl_data/%s" % main_team_id, json.encode(nhldata), ttl_seconds = 3600)
    homeTeamID = nhldata["teams"][0]["nextGameSchedule"]["dates"][0]["games"][0]["teams"]["home"]["team"]["id"]
    awayTeamID = nhldata["teams"][0]["nextGameSchedule"]["dates"][0]["games"][0]["teams"]["away"]["team"]["id"]
    homeTeamRecord = str(int(nhldata["teams"][0]["nextGameSchedule"]["dates"][0]["games"][0]["teams"]["home"]["leagueRecord"]["wins"])) + "-" + str(int(nhldata["teams"][0]["nextGameSchedule"]["dates"][0]["games"][0]["teams"]["home"]["leagueRecord"]["losses"])) + "-" + str(int(nhldata["teams"][0]["nextGameSchedule"]["dates"][0]["games"][0]["teams"]["home"]["leagueRecord"]["ot"]))
    awayTeamRecord = str(int(nhldata["teams"][0]["nextGameSchedule"]["dates"][0]["games"][0]["teams"]["away"]["leagueRecord"]["wins"])) + "-" + str(int(nhldata["teams"][0]["nextGameSchedule"]["dates"][0]["games"][0]["teams"]["away"]["leagueRecord"]["losses"])) + "-" + str(int(nhldata["teams"][0]["nextGameSchedule"]["dates"][0]["games"][0]["teams"]["away"]["leagueRecord"]["ot"]))
    homeTeamIcon = base64.decode(getTeamIconFromID(homeTeamID))
    awayTeamIcon = base64.decode(getTeamIconFromID(awayTeamID))
    homeTeamAbb = getTeamAbbFromID(homeTeamID)
    awayTeamAbb = getTeamAbbFromID(awayTeamID)

    gameDate = nhldata["teams"][0]["nextGameSchedule"]["dates"][0]["games"][0]["gameDate"]
    displayDate = ""

    date_key = humanize.time_format("yyyy-MM-dd", time.parse_time(gameDate).in_location(time_zone_str))
    time_key = humanize.time_format("KK:mm aa", time.parse_time(gameDate).in_location(time_zone_str))

    todaysDate = time.now()
    todaysDateFormatted = humanize.time_format("yyyy-MM-dd", todaysDate)

    if date_key == todaysDateFormatted:
        displayDate = "Today"
    else:
        displayDate = humanize.time_format("EEE, MMM d", time.parse_time(gameDate).in_location(time_zone_str))

    return render.Root(
        delay = 2000,
        child = render.Box(
            child = render.Animation(
                children = [
                    render.Box(
                        child = render.Column(
                            expanded = True,
                            #main_align="space_between",
                            cross_align = "center",
                            children = [
                                render.Row(
                                    expanded = True,
                                    main_align = "center",
                                    cross_align = "center",
                                    children = [
                                        render.Text(displayDate, font = "tom-thumb"),
                                    ],
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "center",
                                    children = [
                                        render.Padding(
                                            pad = (5, 0, 0, 0),
                                            child = render.Image(awayTeamIcon, width = 18, height = 18),
                                        ),
                                        render.Padding(
                                            pad = (0, 0, 5, 0),
                                            child = render.Image(homeTeamIcon, width = 18, height = 18),
                                        ),
                                    ],
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_evenly",
                                    cross_align = "center",
                                    children = [
                                        render.Text(awayTeamAbb, font = "tom-thumb"),
                                        render.Text("@"),
                                        render.Text(homeTeamAbb, font = "tom-thumb"),
                                    ],
                                ),
                            ],
                        ),
                    ),
                    render.Box(
                        child = render.Column(
                            expanded = True,
                            #main_align="space_between",
                            cross_align = "center",
                            children = [
                                render.Row(
                                    expanded = True,
                                    main_align = "center",
                                    cross_align = "center",
                                    children = [
                                        render.Text(time_key, font = "tom-thumb"),
                                    ],
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "center",
                                    children = [
                                        render.Padding(
                                            pad = (5, 0, 0, 0),
                                            child = render.Image(awayTeamIcon, width = 18, height = 18),
                                        ),
                                        render.Padding(
                                            pad = (0, 0, 5, 0),
                                            child = render.Image(homeTeamIcon, width = 18, height = 18),
                                        ),
                                    ],
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "center",
                                    children = [
                                        render.Text(awayTeamRecord, font = "tom-thumb"),
                                        render.Text("", font = "tom-thumb"),
                                        render.Text("", font = "tom-thumb"),
                                    ],
                                ),
                            ],
                        ),
                    ),
                    render.Box(
                        child = render.Column(
                            expanded = True,
                            #main_align="space_between",
                            cross_align = "center",
                            children = [
                                render.Row(
                                    expanded = True,
                                    main_align = "center",
                                    cross_align = "center",
                                    children = [
                                        render.Text(time_key, font = "tom-thumb"),
                                    ],
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "center",
                                    children = [
                                        render.Padding(
                                            pad = (5, 0, 0, 0),
                                            child = render.Image(awayTeamIcon, width = 18, height = 18),
                                        ),
                                        render.Padding(
                                            pad = (0, 0, 5, 0),
                                            child = render.Image(homeTeamIcon, width = 18, height = 18),
                                        ),
                                    ],
                                ),
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "center",
                                    children = [
                                        render.Text("", font = "tom-thumb"),
                                        render.Text("", font = "tom-thumb"),
                                        render.Text(homeTeamRecord, font = "tom-thumb"),
                                    ],
                                ),
                            ],
                        ),
                    ),
                ],
            ),
        ),
    )

TEAM_LIST = [
    schema.Option(display = "Anaheim Ducks", value = "24"),
    schema.Option(display = "Arizona Coyotes", value = "53"),
    schema.Option(display = "Boston Bruins", value = "6"),
    schema.Option(display = "Buffalo Sabres", value = "7"),
    schema.Option(display = "Calgary Flames", value = "20"),
    schema.Option(display = "Carolina Hurricanes", value = "12"),
    schema.Option(display = "Chicago Blackhawks", value = "16"),
    schema.Option(display = "Colorado Avalanche", value = "21"),
    schema.Option(display = "Columbus Blue Jackets", value = "29"),
    schema.Option(display = "Dallas Stars", value = "25"),
    schema.Option(display = "Detroit Red Wings", value = "17"),
    schema.Option(display = "Edmonton Oilers", value = "22"),
    schema.Option(display = "Florida Panthers", value = "13"),
    schema.Option(display = "Los Angeles Kings", value = "26"),
    schema.Option(display = "Minnesota Wild", value = "30"),
    schema.Option(display = "Montreal Canadiens", value = "8"),
    schema.Option(display = "Nashville Predators", value = "18"),
    schema.Option(display = "New Jersey Devils", value = "1"),
    schema.Option(display = "New York Islanders", value = "2"),
    schema.Option(display = "New York Rangers", value = "3"),
    schema.Option(display = "Ottawa Senators", value = "9"),
    schema.Option(display = "Philadelphia Flyers", value = "4"),
    schema.Option(display = "Pittsburgh Penguins", value = "5"),
    schema.Option(display = "San Jose Sharks", value = "28"),
    schema.Option(display = "Seattle Kraken", value = "55"),
    schema.Option(display = "St. Louis Blues", value = "19"),
    schema.Option(display = "Tampa Bay Lightning", value = "14"),
    schema.Option(display = "Toronto Maple Leafs", value = "10"),
    schema.Option(display = "Vancouver Canucks", value = "23"),
    schema.Option(display = "Vegas Golden Knights", value = "54"),
    schema.Option(display = "Washington Capitals", value = "15"),
    schema.Option(display = "Winnipeg Jets", value = "52"),
]

TIME_ZONES = [
    schema.Option(display = "Eastern", value = "America/New_York"),
    schema.Option(display = "Central", value = "America/Chicago"),
    schema.Option(display = "Mountain", value = "America/Denver"),
    schema.Option(display = "Pacific", value = "America/Los_Angeles"),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "main_team",
                name = "Team",
                desc = "Pick a team to follow",
                icon = "hockeyPuck",
                default = TEAM_LIST[0].value,
                options = TEAM_LIST,
            ),
            schema.Dropdown(
                id = "time_zone",
                name = "Time Zone",
                desc = "Pick a time zone.",
                icon = "earthAmericas",
                default = TIME_ZONES[0].value,
                options = TIME_ZONES,
            ),
        ],
    )
