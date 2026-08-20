"""
Applet: ClashClansTrophy
Summary: Displays Trophy Count
Description: Displays trophies for Clash of Clans.
Author: Brandon Marks
"""

load("http.star", "http")
load("images/archer_logo.jpg", ARCHER_LOGO_ASSET = "file")
load("images/barbarian_logo.jpg", BARBARIAN_LOGO_ASSET = "file")
load("images/castle_icon.png", CASTLE_ICON_ASSET = "file")
load("images/goblin_logo.jpg", GOBLIN_LOGO_ASSET = "file")
load("images/trophy_icon.png", TROPHY_ICON_ASSET = "file")
load("images/wizard_logo.jpg", WIZARD_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

ARCHER_LOGO = ARCHER_LOGO_ASSET.readall()
BARBARIAN_LOGO = BARBARIAN_LOGO_ASSET.readall()
CASTLE_ICON = CASTLE_ICON_ASSET.readall()
GOBLIN_LOGO = GOBLIN_LOGO_ASSET.readall()
TROPHY_ICON = TROPHY_ICON_ASSET.readall()
WIZARD_LOGO = WIZARD_LOGO_ASSET.readall()

CLASH_URL = "https://cocproxy.royaleapi.dev/v1/players/%23"

def main(config):
    playerID = config.get("PlayerID", "")
    pictureChoice = config.get("pictureChoice", "Barbarian")
    nameScrollActive = config.bool("nameScrollActive", "False")

    decrypted_Token = config.get("clash_of_clans_api_key") or "No_Key"

    #to be displayed in case of error
    trophy_Count = 0
    townHallLevel = 0
    player_Name = "N/A"

    #send request for data
    if (playerID != "" and decrypted_Token != "No_Key"):
        headers_clash = {
            "Authorization": decrypted_Token,
        }

        fullURL = CLASH_URL + playerID
        rep = http.get(fullURL, ttl_seconds = 200, headers = headers_clash)
        if rep.status_code != 200:
            print("\n\nClash API request failed with status %d", rep.status_code)

            # print("Printing below\n")
            # print(rep)
            # print('\n\nHere is the token\n')
            # print(decrypted_Token)
            player_Name = "Not Found"
            nameScrollActive = "True"

        else:
            trophy_Count = rep.json()["trophies"]
            player_Name = rep.json()["name"]
            townHallLevel = rep.json()["townHallLevel"]

    ##handles all rendering of images, delegates to functions for each item
    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render_Picture(pictureChoice),
                    render.Column(
                        cross_align = "center",
                        children = [
                            render_Name(player_Name, nameScrollActive),
                            render_TH_row(townHallLevel),
                            render_trophy_Count(trophy_Count),
                        ],
                    ),
                ],
            ),
        ),
    )

def render_Name(name_passed, nameScrollActive):
    if nameScrollActive:
        #text will scroll accross the screen
        return render.Marquee(
            child = render.Text(
                font = "tb-8",
                content = name_passed,
            ),
            width = 34,
        )
    else:
        return render.Text("%s" % name_passed)

def render_Picture(pictureChoice):
    picSRC = determinePicture(pictureChoice)

    return render.Box(
        width = 28,  # Set the width of the box
        height = 28,  # Set the height of the box
        padding = 1,  #surrounds box with blank space
        child = render.Image(src = picSRC, width = 28),
    )

def determinePicture(pictureChoice):
    if (pictureChoice == "1"):
        return BARBARIAN_LOGO
    elif (pictureChoice == "2"):
        return ARCHER_LOGO
    elif (pictureChoice == "3"):
        return GOBLIN_LOGO
    elif (pictureChoice == "4"):
        return WIZARD_LOGO

    #defaults to barbarian
    return BARBARIAN_LOGO

def render_TH_row(townHallLevel):
    return render.Row(
        main_align = "space_evenly",
        cross_align = "center",
        expanded = True,
        children = [
            render.Image(src = CASTLE_ICON),
            render.Text("TH: %d" % townHallLevel),
        ],
    )

def render_trophy_Count(trophy_Count):
    return render.Row(
        main_align = "space_evenly",
        cross_align = "center",
        expanded = True,
        children = [
            render.Image(src = TROPHY_ICON),
            render.Text("%d" % trophy_Count),
        ],
    )

# Set up configuration options
def get_schema():
    picture_Options = [
        schema.Option(
            display = "Barbarian",
            value = "1",
        ),
        schema.Option(
            display = "Archer",
            value = "2",
        ),
        schema.Option(
            display = "Goblin",
            value = "3",
        ),
        schema.Option(
            display = "Wizard",
            value = "4",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "clash_of_clans_api_key",
                name = "Clash of Clans API Key",
                desc = "Your Clash of Clans API key. See https://developer.clashofclans.com/ for details.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "PlayerID",
                name = "PlayerID",
                desc = "Account ID; Don't include '#'",
                icon = "user",
            ),
            schema.Toggle(
                id = "nameScrollActive",
                name = "Scrolling Name",
                desc = "A toggle to enable scrolling name.",
                icon = "gear",
                default = False,
            ),
            schema.Dropdown(
                id = "pictureChoice",
                name = "Picture Selection",
                desc = "The choice of what picture to display",
                icon = "brush",
                default = picture_Options[0].value,
                options = picture_Options,
            ),
        ],
    )
