"""
Applet: Steam
Summary: Steam Now Playing
Description: Displays the game that the specified user is currently playing, or the most recent games if currently not in-game.
Author: Jeremy Tavener
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/steam_icon.png", STEAM_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

STEAM_ICON = STEAM_ICON_ASSET.readall()

CACHE_TTL_SECONDS = 300
API_BASE_URL = "http://api.steampowered.com/"
API_PLAYER_SUMMARIES = API_BASE_URL + "ISteamUser/GetPlayerSummaries/v0002"
API_RECENTLY_PLAYED_GAMES = API_BASE_URL + "IPlayerService/GetRecentlyPlayedGames/v0001"
API_OWNED_GAMES = API_BASE_URL + "IPlayerService/GetOwnedGames/v0001"

def main(config):
    steam_id = config.get("steam_id", None)
    api_key = config.get("steam_api_key")

    if steam_id == None or api_key == None:
        return do_render(DEMO_DATA["player_name"], DEMO_DATA["main_icon"], DEMO_DATA["game_string"])

    # Is the user currently playing a game?
    # Note - this will only return if their profile is set to show this information publically
    resp = http.get(API_PLAYER_SUMMARIES, params = {"key": api_key, "steamids": steam_id})

    if resp.status_code != 200:
        return display_failure("Failed to get the current player summary with code {}".format(resp.status_code))

    if len(resp.json()["response"]["players"]) != 1:
        return display_failure("Failed to find player with SteamID {}".format(steam_id))

    if resp.json()["response"]["players"][0]["communityvisibilitystate"] != 3:
        return display_failure("Profile is not public, can't get current game")

    player_name = resp.json()["response"]["players"][0]["personaname"]

    if "gameextrainfo" in resp.json()["response"]["players"][0].keys():
        game_string = "Now Playing: " + resp.json()["response"]["players"][0]["gameextrainfo"]
        current_game_id = resp.json()["response"]["players"][0]["gameid"]

        # Grab the game Icon - this is groooooosss
        json_blob = json.encode({"steamid": steam_id, "include_appinfo": True, "appids_filter": [current_game_id]})

        resp = http.get(API_OWNED_GAMES, params = {"key": api_key, "input_json": str(json_blob)}, ttl_seconds = CACHE_TTL_SECONDS)

        if resp.status_code != 200:
            return display_failure("Failed to get the current game icon with code {}".format(resp.status_code))

        if resp.json()["response"]["game_count"] == 1:
            game_icon_hash = resp.json()["response"]["games"][0]["img_icon_url"]
            game_icon_url = "http://media.steampowered.com/steamcommunity/public/images/apps/" + str(current_game_id) + "/" + game_icon_hash + ".jpg"
            main_icon = http.get(game_icon_url, ttl_seconds = CACHE_TTL_SECONDS).body()
        else:
            main_icon = STEAM_ICON

    else:
        # There's no current game - get a list of previously played to display.
        resp = http.get(API_RECENTLY_PLAYED_GAMES, params = {"key": api_key, "steamid": steam_id})

        game_string = ""

        # Just display a blank string if we can't find the game list.
        if resp.status_code == 200:
            if (resp.json()["response"]["total_count"] > 0):
                for game in resp.json()["response"]["games"]:
                    game_string = game_string + "   " + game["name"]

        main_icon = STEAM_ICON

    return do_render(player_name, main_icon, game_string)

def do_render(player_name, main_icon, game_string):
    return render.Root(
        render.Column(
            main_align = "space_around",
            cross_align = "center",
            expanded = True,
            children = [
                render.Row(
                    main_align = "start",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Box(
                            child = render.Image(
                                src = main_icon,
                                height = 20,
                                width = 20,
                            ),
                            width = 20,
                            height = 20,
                            padding = 2,
                        ),
                        render.Marquee(
                            width = 42,
                            child = render.Text(
                                content = player_name,
                                font = "tb-8",
                            ),
                        ),
                    ],
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(
                        content = game_string,
                        font = "CG-pixel-3x5-mono",
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "steam_id",
                name = "Steam ID",
                desc = "Your 17 digit Steam ID (use https://steamid.xyz/ if you're unsure)",
                icon = "user",
            ),
            schema.Text(
                id = "steam_api_key",
                name = "Steam API Key",
                desc = "A Steam API key to access the Steam API.",
                icon = "key",
                secret = True,
            ),
        ],
    )

def display_failure(msg):
    return render.Root(
        child = render.Marquee(
            width = 64,
            child = render.Text(msg),
        ),
    )

DEMO_DATA = {
    "player_name": "Demo Player",
    "game_string": "Farcry 5   Goldeneye 007   Half-Life 2   Halo Infinite",
    "main_icon": STEAM_ICON,
}
