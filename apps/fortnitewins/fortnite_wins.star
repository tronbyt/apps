""" 
Fortnite Win Tracker by Hunter Berry

Applet/App Name: Fortnite Win Tracker
Author: Hunter Berry (https://www.github.com/HunBurry)
Summary: Tracks Fortnite wins. 
Description: Shows how many wins the user has in each main game mode (i.e., Solos, Duos, Trios, and Squads).

Example gif generated through the following command: 
    pixlet render fortnite_wins.star username="HunBurry05" show_kd=True show_win_rate=True --gif --magnify 10
"""

######################################################################################### Loads/Imports #########################################################################################

load("http.star", "http")
load("images/icon_left.png", ICON_LEFT_ASSET = "file")
load("images/icon_right.png", ICON_RIGHT_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

ICON_LEFT = ICON_LEFT_ASSET.readall()
ICON_RIGHT = ICON_RIGHT_ASSET.readall()

######################################################################################### Global Variables #########################################################################################

yellow = "#ffcc66"
blue = "#3399ff"
default_username = ""

#

######################################################################################### Helper Functions ########################################################################################

def float_to_string_without_trailing_decimal(f):
    if f % 1 == 0:
        return str(int(f))
    else:
        return str(f)

######################################################################################### Main Function #########################################################################################

def main(config):
    decrypted_key = config.get("fortnite_api_key")
    if not decrypted_key:
        return render.Root(
            child = render.WrappedText("API Key not set", color = "#ff0000"),
        )

    headers = {
        "Authorization": decrypted_key,
    }

    username = config.str("username", default_username)
    show_kd = config.bool("show_kd")
    win_rate = config.bool("show_win_rate")

    if username == None:  # Eror message prompting user to input a username into the app.
        message = "No username found... Input a username in the app to check your wins here!"
    else:
        primary_url = "https://fortniteapi.io/v1/lookup?username=" + username
        accountID_request = http.get(primary_url, headers = headers, ttl_seconds = 86400)

        if accountID_request.status_code != 200:  # Can't find the passed in username.
            message = "Couldn't find your Epic account information... Make sure to use your Epic account username and not your display name!"
            print("Fortnite player lookup request failed because the username can't be found..")
        else:  # Username can be found, proceed.
            accountID = accountID_request.json()["account_id"]
            secondary_url = "https://fortniteapi.io/v1/stats?account=" + accountID
            playerStats_request = http.get(secondary_url, headers = headers, ttl_seconds = 1200)

            if playerStats_request.status_code != 200:  #Something went wrong and we can't get the account associated with the ID.
                message = "We couldn't find a Fortnite account associated with the given Epic username."
                print("Fortnite player stats request failed because something went wrong...")

            if playerStats_request.json().get("code", None) == "PRIVATE_ACCOUNT":
                message = "Sorry, your account is private, so we can't view your stats! Make your account public to see stats."
                print("Fortnite player stats request failed because the user's account is private.")

            else:
                playerStats_request = playerStats_request.json()
                squad_wins = "Squads: " + float_to_string_without_trailing_decimal(playerStats_request["global_stats"]["squad"]["placetop1"])
                trio_wins = "Trios: " + float_to_string_without_trailing_decimal(playerStats_request["global_stats"]["trio"]["placetop1"])
                duo_wins = "Duos: " + float_to_string_without_trailing_decimal(playerStats_request["global_stats"]["duo"]["placetop1"])
                solo_wins = "Solos: " + float_to_string_without_trailing_decimal(playerStats_request["global_stats"]["solo"]["placetop1"])

                if show_kd:
                    squad_wins = squad_wins + " (K/D: " + str(playerStats_request["global_stats"]["squad"]["kd"]) + ")"
                    trio_wins = trio_wins + " (K/D: " + str(playerStats_request["global_stats"]["trio"]["kd"]) + ")"
                    duo_wins = duo_wins + " (K/D: " + str(playerStats_request["global_stats"]["duo"]["kd"]) + ")"
                    solo_wins = solo_wins + " (K/D: " + str(playerStats_request["global_stats"]["solo"]["kd"]) + ")"
                if win_rate:
                    squad_wins = squad_wins + " (W/L: " + str(playerStats_request["global_stats"]["squad"]["winrate"]) + ")"
                    trio_wins = trio_wins + " (W/L: " + str(playerStats_request["global_stats"]["trio"]["winrate"]) + ")"
                    duo_wins = duo_wins + " (W/L: " + str(playerStats_request["global_stats"]["duo"]["winrate"]) + ")"
                    solo_wins = solo_wins + " (W/L: " + str(playerStats_request["global_stats"]["solo"]["winrate"]) + ")"

                message = solo_wins + "    " + duo_wins + "    " + trio_wins + "    " + squad_wins

    return render.Root(
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Column(
                    children = [
                        render.Row(
                            main_align = "center",
                            cross_align = "center",
                            children = [
                                render.Image(
                                    src = ICON_LEFT,
                                    width = 16,
                                    height = 16,
                                ),
                                render.Column(
                                    children = [
                                        render.Padding(
                                            pad = (4, 0, 0, 0),
                                            child = render.WrappedText(
                                                content = "Fortnite Win Tracker",
                                                color = yellow,
                                                align = "center",
                                            ),
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
                render.Marquee(
                    width = 64,
                    offset_start = 48,
                    child = render.Text(
                        message,
                        color = blue,
                    ),
                ),
            ],
        ),
    )

########################################################################################### Schema ###########################################################################################

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "fortnite_api_key",
                name = "Fortnite API Key",
                desc = "Your FortniteAPI.io API key. See https://fortniteapi.io/ for details.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "username",
                name = "Fortnite Username",
                desc = "Fortnite/Epic Games Username. Please note this may or may not be the same as your display name.",
                icon = "user",
            ),
            schema.Toggle(
                id = "show_kd",
                name = "Show K/D Ratio?",
                desc = "Turn on to show your K/D ratio for each game mode alongside your wins.",
                icon = "gun",
                default = False,
            ),
            schema.Toggle(
                id = "show_win_rate",
                name = "Show Win Rate?",
                desc = "Turn on to show your win/loss ratio for each game mode alongside your wins.",
                icon = "crown",
                default = False,
            ),
        ],
    )
