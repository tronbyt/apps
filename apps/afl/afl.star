"""
Applet: AFL
Summary: AFL standings
Description: Display the current Australian Football League standings and the next game time/date for a selected team.
Author: andymcrae
"""

#some code borrowed or inspired by nhlnextgame by AKKanman

load("http.star", "http")
load("humanize.star", "humanize")
load("images/logo_adelaide.png", LOGO_ADELAIDE_ASSET = "file")
load("images/logo_brisbane.png", LOGO_BRISBANE_ASSET = "file")
load("images/logo_carlton.png", LOGO_CARLTON_ASSET = "file")
load("images/logo_collingwood.png", LOGO_COLLINGWOOD_ASSET = "file")
load("images/logo_essendon.png", LOGO_ESSENDON_ASSET = "file")
load("images/logo_freemantle.png", LOGO_FREEMANTLE_ASSET = "file")
load("images/logo_geelong.png", LOGO_GEELONG_ASSET = "file")
load("images/logo_gold_coast.png", LOGO_GOLD_COAST_ASSET = "file")
load("images/logo_greater_western_sydney.png", LOGO_GREATER_WESTERN_SYDNEY_ASSET = "file")
load("images/logo_hawthorn.png", LOGO_HAWTHORN_ASSET = "file")
load("images/logo_melbourne.png", LOGO_MELBOURNE_ASSET = "file")
load("images/logo_north_melbourne.png", LOGO_NORTH_MELBOURNE_ASSET = "file")
load("images/logo_port_adelaide.png", LOGO_PORT_ADELAIDE_ASSET = "file")
load("images/logo_richmond.png", LOGO_RICHMOND_ASSET = "file")
load("images/logo_st_kilda.png", LOGO_ST_KILDA_ASSET = "file")
load("images/logo_sydney.png", LOGO_SYDNEY_ASSET = "file")
load("images/logo_west_coast.png", LOGO_WEST_COAST_ASSET = "file")
load("images/logo_western_bulldogs.png", LOGO_WESTERN_BULLDOGS_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

#URLs for AFL API data
AFL_STANDINGS_URL = "https://api.squiggle.com.au/?q=standings"
AFL_GAMES_URL = "https://api.squiggle.com.au/?q=games;year={0};team={1};complete=!100"

#set default team to the Sydney Swans
DEFAULT_TEAM = "16"

#team icons in base64
def getTeamIconFromID(team_id):
    if team_id == 1:  #ADE
        return (LOGO_ADELAIDE_ASSET.readall())
    elif team_id == 2:  #BRI
        return (LOGO_BRISBANE_ASSET.readall())
    elif team_id == 3:  #CAR
        return (LOGO_CARLTON_ASSET.readall())
    elif team_id == 4:  #COL
        return (LOGO_COLLINGWOOD_ASSET.readall())
    elif team_id == 5:  #ESS
        return (LOGO_ESSENDON_ASSET.readall())
    elif team_id == 6:  #FRE
        return (LOGO_FREEMANTLE_ASSET.readall())
    elif team_id == 7:  #GEE
        return (LOGO_GEELONG_ASSET.readall())
    elif team_id == 8:  #GCS
        return (LOGO_GOLD_COAST_ASSET.readall())
    elif team_id == 9:  #GWS
        return (LOGO_GREATER_WESTERN_SYDNEY_ASSET.readall())
    elif team_id == 10:  #HAW
        return (LOGO_HAWTHORN_ASSET.readall())
    elif team_id == 11:  #MEL
        return (LOGO_MELBOURNE_ASSET.readall())
    elif team_id == 12:  #NOR
        return (LOGO_NORTH_MELBOURNE_ASSET.readall())
    elif team_id == 13:  #POR
        return (LOGO_PORT_ADELAIDE_ASSET.readall())
    elif team_id == 14:  #RIC
        return (LOGO_RICHMOND_ASSET.readall())
    elif team_id == 15:  #STK
        return (LOGO_ST_KILDA_ASSET.readall())
    elif team_id == 16:  #SYD
        return (LOGO_SYDNEY_ASSET.readall())
    elif team_id == 17:  #WCE
        return (LOGO_WEST_COAST_ASSET.readall())
    elif team_id == 18:  #WBD
        return (LOGO_WESTERN_BULLDOGS_ASSET.readall())
    return None

#get abbreviated team name from the team_id. Teams are in alphabetical order
def getTeamAbbFromID(team_id):
    if team_id == 1:  #ADE
        return ("ADE")
    elif team_id == 2:  #BRI
        return ("BRI")
    elif team_id == 3:  #CAR
        return ("CAR")
    elif team_id == 4:  #COL
        return ("COL")
    elif team_id == 5:  #ESS
        return ("ESS")
    elif team_id == 6:  #FRE
        return ("FRE")
    elif team_id == 7:  #GEE
        return ("GEE")
    elif team_id == 8:  #GCS
        return ("GCS")
    elif team_id == 9:  #GWS
        return ("GWS")
    elif team_id == 10:  #HAW
        return ("HAW")
    elif team_id == 11:  #MEL
        return ("MEL")
    elif team_id == 12:  #NOR
        return ("NOR")
    elif team_id == 13:  #POR
        return ("POR")
    elif team_id == 14:  #RIC
        return ("RIC")
    elif team_id == 15:  #STK
        return ("STK")
    elif team_id == 16:  #SYD
        return ("SYD")
    elif team_id == 17:  #WCE
        return ("WCE")
    elif team_id == 18:  #WBD
        return ("WBD")
    return None

def main(config):
    team_id = config.get("main_team") or DEFAULT_TEAM
    show_standings = config.bool("show_standings")

    todays_date = time.now()
    todays_date_formatted = humanize.time_format("yyyy-MM-dd", todays_date)

    message = " "

    # get standings if we should
    standings = []
    if show_standings:
        resp = http.get(AFL_STANDINGS_URL, ttl_seconds = 3600)
        if resp.status_code != 200:
            fail("Squiggle request failed with status", resp.status_code)
        stand_data = resp.json().get("standings")

        # get the team identifier in standings order
        for i in range(len(stand_data)):
            standings.append(stand_data[i]["id"])

        # build the standings message
        for i, _ in enumerate(standings):
            message = message + str(i + 1) + ": " + getTeamAbbFromID(standings[i]) + "  "

    # call the Squiggle API and retreive list of unfinished games for the year
    games_url = AFL_GAMES_URL.format(todays_date_formatted[0:4], str(team_id))
    resp = http.get(games_url, ttl_seconds = 3600)
    if resp.status_code != 200:
        fail("Squiggle request failed with status", resp.status_code)
    game_data = resp.json().get("games")

    hgames = []
    hometeam = 0
    agames = []
    awayteam = 0

    #find the games for this team - finals data is null until populated at end of primary rounds
    for i in range(len(game_data)):
        hometeam = int(game_data[i].get("hteamid"))  #convert to int as this field is decimal
        if str(hometeam) == str(team_id):  #compare the two as strings
            hgames.append(game_data[i]["id"])  #add this game to the list of games
            continue  # found what we need, go on to the next

        # otherwise see if we are the away team
        awayteam = int(game_data[i].get("ateamid"))
        if str(awayteam) == str(team_id):
            agames.append(game_data[i]["id"])

    #make sure we have the first game either home or away
    if len(agames) > 0 and len(hgames) > 0:
        if agames[0] > hgames[0]:
            nextgame_id = int(hgames[0])
        else:
            nextgame_id = int(agames[0])
    elif len(agames) > 0:
        nextgame_id = int(agames[0])
    elif len(hgames) > 0:
        nextgame_id = int(hgames[0])
    else:
        # No games found
        return render.Root(
            child = render.Box(
                child = render.WrappedText("No upcoming games found.", font = "tom-thumb", align = "center"),
            ),
        )

    hometeam_id = ""
    awayteam_id = ""
    nextgamedate = ""
    round_number = ""

    #get the data for the next game
    for i in range(len(game_data)):
        if game_data[i]["id"] == nextgame_id:
            hometeam_id = game_data[i]["hteamid"]
            awayteam_id = game_data[i]["ateamid"]
            nextgamedate = game_data[i]["date"]
            round_number = int(game_data[i]["round"])

    display_date = ""
    date_key = nextgamedate[0:10]

    if date_key == todays_date_formatted:
        display_date = "Today"
    else:
        display_date = nextgamedate[8:10] + "-" + nextgamedate[5:7]

    display_time = nextgamedate[11:16]

    #get icon data
    home_team_icon = getTeamIconFromID(hometeam_id)
    away_team_icon = getTeamIconFromID(awayteam_id)

    #get abbreviated team name
    home_team_abb = getTeamAbbFromID(hometeam_id)
    away_team_abb = getTeamAbbFromID(awayteam_id)

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_around",
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "center",
                    children = [
                        render.Box(
                            width = 24,
                            height = 26,
                            child = render.WrappedText("RD:" + str(round_number) + " " + display_date + " " + display_time, font = "tom-thumb"),
                        ),
                        render.Box(
                            width = 20,
                            height = 26,
                            padding = 1,
                            child = render.Column(
                                cross_align = "center",
                                children = [
                                    render.Image(home_team_icon),
                                    render.Text(home_team_abb, font = "tom-thumb"),
                                ],
                            ),
                        ),
                        render.Box(
                            width = 20,
                            height = 26,
                            padding = 1,
                            child = render.Column(
                                cross_align = "center",
                                children = [
                                    render.Image(away_team_icon),
                                    render.Text(away_team_abb, font = "tom-thumb"),
                                ],
                            ),
                        ),
                    ],
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(message, font = "tom-thumb"),
                    offset_start = 5,
                    offset_end = 32,
                ) if show_standings else None,
            ],
        ),
    )

TEAM_LIST = [
    schema.Option(display = "Adelaide", value = "1"),
    schema.Option(display = "Brisbane", value = "2"),
    schema.Option(display = "Carlton", value = "3"),
    schema.Option(display = "Collingwood", value = "4"),
    schema.Option(display = "Essendon", value = "5"),
    schema.Option(display = "Freemantle", value = "6"),
    schema.Option(display = "Geelong", value = "7"),
    schema.Option(display = "Gold Coast", value = "8"),
    schema.Option(display = "Greater Western Sydney", value = "9"),
    schema.Option(display = "Hawthorn", value = "10"),
    schema.Option(display = "Melbourne", value = "11"),
    schema.Option(display = "North Melbourne", value = "12"),
    schema.Option(display = "Port Adelaide", value = "13"),
    schema.Option(display = "Richmond", value = "14"),
    schema.Option(display = "St Kilda", value = "15"),
    schema.Option(display = "Sydney", value = "16"),
    schema.Option(display = "West Coast", value = "17"),
    schema.Option(display = "Western Bulldogs", value = "18"),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "main_team",
                name = "Team",
                desc = "Pick a team to follow",
                icon = "peopleGroup",
                default = TEAM_LIST[0].value,
                options = TEAM_LIST,
            ),
            schema.Toggle(
                id = "show_standings",
                name = "Show Standings",
                desc = "Whether the standings should be shown.",
                icon = "gear",
                default = True,
            ),
        ],
    )
