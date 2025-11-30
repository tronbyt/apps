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
load("images/ana.png", ANA_ICON = "file")
load("images/ari.png", ARI_ICON = "file")
load("images/bos.png", BOS_ICON = "file")
load("images/buf.png", BUF_ICON = "file")
load("images/car.png", CAR_ICON = "file")
load("images/cbj.png", CBJ_ICON = "file")
load("images/cgy.png", CGY_ICON = "file")
load("images/chi.png", CHI_ICON = "file")
load("images/col.png", COL_ICON = "file")
load("images/dal.png", DAL_ICON = "file")
load("images/det.png", DET_ICON = "file")
load("images/edm.png", EDM_ICON = "file")
load("images/fla.png", FLA_ICON = "file")
load("images/lak.png", LAK_ICON = "file")
load("images/min.png", MIN_ICON = "file")
load("images/mtl.png", MTL_ICON = "file")
load("images/njd.png", NJD_ICON = "file")
load("images/nsh.png", NSH_ICON = "file")
load("images/nyi.png", NYI_ICON = "file")
load("images/nyr.png", NYR_ICON = "file")
load("images/ott.png", OTT_ICON = "file")
load("images/phi.png", PHI_ICON = "file")
load("images/pit.png", PIT_ICON = "file")
load("images/sea.png", SEA_ICON = "file")
load("images/sjs.png", SJS_ICON = "file")
load("images/stl.png", STL_ICON = "file")
load("images/tbl.png", TBL_ICON = "file")
load("images/tor.png", TOR_ICON = "file")
load("images/van.png", VAN_ICON = "file")
load("images/vgk.png", VGK_ICON = "file")
load("images/wpg.png", WPG_ICON = "file")
load("images/wsh.png", WSH_ICON = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def getTeamIconFromID(teamID):
    if teamID == 2:  #NYI
        return (NYI_ICON.readall())
    elif teamID == 24:  #ANA
        return (ANA_ICON.readall())
    elif teamID == 53:  #ARI
        return (ARI_ICON.readall())
    elif teamID == 6:  #BOS
        return (BOS_ICON.readall())
    elif teamID == 7:  #BUF
        return (BUF_ICON.readall())
    elif teamID == 20:  #CGY
        return (CGY_ICON.readall())
    elif teamID == 12:  #CAR
        return (CAR_ICON.readall())
    elif teamID == 16:  #CHI
        return (CHI_ICON.readall())
    elif teamID == 21:  #COL
        return (COL_ICON.readall())
    elif teamID == 29:  #CBJ
        return (CBJ_ICON.readall())
    elif teamID == 25:  #DAL
        return (DAL_ICON.readall())
    elif teamID == 17:  #DET
        return (DET_ICON.readall())
    elif teamID == 22:  #EDM
        return (EDM_ICON.readall())
    elif teamID == 13:  #FLA
        return (FLA_ICON.readall())
    elif teamID == 26:  #LAK
        return (LAK_ICON.readall())
    elif teamID == 30:  #MIN
        return (MIN_ICON.readall())
    elif teamID == 8:  #MTL
        return (MTL_ICON.readall())
    elif teamID == 18:  #NSH
        return NSH_ICON.readall()
    elif teamID == 1:  #NJD
        return NJD_ICON.readall()
    elif teamID == 3:  #NYR
        return NYR_ICON.readall()
    elif teamID == 9:  #OTT
        return OTT_ICON.readall()
    elif teamID == 4:  #PHI
        return PHI_ICON.readall()
    elif teamID == 5:  #PIT
        return PIT_ICON.readall()
    elif teamID == 28:  #SJS
        return SJS_ICON.readall()
    elif teamID == 55:  #SEA
        return SEA_ICON.readall()
    elif teamID == 19:  #STL
        return STL_ICON.readall()
    elif teamID == 14:  #TBL
        return TBL_ICON.readall()
    elif teamID == 10:  #TOR
        return TOR_ICON.readall()
    elif teamID == 23:  #VAN
        return VAN_ICON.readall()
    elif teamID == 54:  #VGK
        return VGK_ICON.readall()
    elif teamID == 15:  #WSH
        return WSH_ICON.readall()
    elif teamID == 52:  #WPG
        return WPG_ICON.readall()
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
