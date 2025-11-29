"""
Applet: Roblox
Summary: Online friends & games
Description: Real time views of your Roblox experiences.
Author: Chad Milburn / CODESTRONG
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/roblox_dark_logo.png", ROBLOX_DARK_LOGO_ASSET = "file")
load("images/roblox_light_logo.png", ROBLOX_LIGHT_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

ROBLOX_DARK_LOGO = ROBLOX_DARK_LOGO_ASSET.readall()
ROBLOX_LIGHT_LOGO = ROBLOX_LIGHT_LOGO_ASSET.readall()

### CONSTANTS
TTL_SECONDS = 240
TRIO_CIRCLES_TOP_OFFSET = 12

### DEFAULTS
DEFAULT_DARK_MODE = True
DEFAULT_USER_NAME = "C0DESTR0NG"
DEFAULT_ACCENT_COLOR = "#f77a24"

### VIEW MODES
VIEW_FRIENDS = "view_friends"
VIEW_FAVORITE_GAMES = "view_favorite_games"

def main(config):
    ### SET VIEW MODE FROM APP CONFIG SETTINGS
    view_mode = config.str("view_mode") if config.str("view_mode") != None and config.str("view_mode") != "" else VIEW_FRIENDS

    ### SET ACCENT COLOR FROM APP CONFIG SETTINGS
    accent_color = config.str("accent_color") if config.str("accent_color") != None and config.str("accent_color") != "" else DEFAULT_ACCENT_COLOR

    ### SET IS DARK MODE FROM APP CONFIG SETTINGS
    dark_mode = config.bool("dark_mode") if config.bool("dark_mode") != None and config.bool("dark_mode") != "" else DEFAULT_DARK_MODE

    ### SET USERNAME
    username = config.str("username") if config.str("username") != None and config.str("username") != "" else DEFAULT_USER_NAME

    renderGame = []
    renderFriend = []

    ### GET USER ID
    user_id_cached = cache.get("user_id_%s" % username)
    if user_id_cached != None and user_id_cached != str(""):
        print("Using cached user id")
        userRobloxId = str(user_id_cached)
    else:
        getUserId = "https://users.roblox.com/v1/users/search?keyword=%s&limit=10" % username
        repGetUserId = http.get(getUserId)
        if repGetUserId.status_code == 200:
            print("Fetching user id")
            userId = "%d" % repGetUserId.json()["data"][0]["id"] if len(repGetUserId.json()["data"]) > 0 else ""
            userRobloxId = "%s" % userId

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set("user_id_%s" % username, str(userRobloxId), ttl_seconds = TTL_SECONDS)
        else:
            userRobloxId = ""

    ### RETURN AND SHOW 'USER NOT FOUND' SCREEN IF FAILS TO GET USER ID
    if userRobloxId == None or userRobloxId == "":
        print("User id not found")

        return render.Root(
            child = render.Stack(
                children = [
                    render.Padding(
                        pad = (2, 2, 0, 0),
                        child = render.Row(
                            children = [
                                render.Stack(
                                    children = [
                                        render.Circle(
                                            color = "#888",
                                            diameter = 21,
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ),
                    render.Padding(
                        pad = (19, 19, 0, 0),
                        child = render.Circle(
                            color = "#333",
                            diameter = 4,
                        ),
                    ),
                    render.Padding(
                        pad = (9, 25, 0, 0),
                        child = render.Marquee(
                            width = 64,
                            child = render.Text(content = "User not found. User not found.", font = "tom-thumb"),
                        ),
                    ),
                    render.Padding(
                        pad = (1, 24, 0, 0),
                        child = render.Image(src = ROBLOX_DARK_LOGO, width = 7, height = 7),
                    ),
                ],
            ),
        )

    ### GET USER AVATAR
    user_avatar_cached = cache.get("user_avatar_%s" % username)
    if user_avatar_cached != None and user_avatar_cached != str(""):
        print("Using cached user avatar")
        profilePhotoImg = str(user_avatar_cached)
    else:
        print("Fetching user avatar")
        getProfilePhoto = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%s&size=60x60&format=Png&isCircular=true" % userRobloxId
        repGetProfilePhoto = http.get(getProfilePhoto)
        if repGetProfilePhoto.status_code != 200:
            print("Fetching user avatar failed with status %d" % repGetProfilePhoto.status_code)
            profilePhotoImg = ""
        else:
            profilePhotoUrl = repGetProfilePhoto.json()["data"][0]["imageUrl"]
            profilePhotoImg = http.get(profilePhotoUrl).body()

        ### Caching profilePhotoImg value from fetched logic
        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("user_avatar_%s" % username, str(profilePhotoImg), ttl_seconds = TTL_SECONDS)

    ### GET ONLINE STYLE
    user_online_status_cached = cache.get("user_online_status_%s" % username)
    if user_online_status_cached != None and user_online_status_cached != str(""):
        print("Using cached user online status")
        isOnline = json.decode(user_online_status_cached)
    else:
        print("Fetching user online status")
        getUserOnlineStatus = "https://api.roblox.com/users/%s/onlinestatus/" % userRobloxId
        repGetUserOnlineStatus = http.get(getUserOnlineStatus)
        if repGetUserOnlineStatus.status_code != 200:
            print("Fetching user online status failed with status %d" % repGetUserOnlineStatus.status_code)
            isOnline = False
        else:
            isOnline = repGetUserOnlineStatus.json()["IsOnline"]

        ### Caching isOnline value from fetched logic
        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("user_online_status_%s" % username, json.encode(isOnline), ttl_seconds = TTL_SECONDS)

    ### FRIEND MODE
    if view_mode == VIEW_FRIENDS:
        ### GET USER FRIENDS
        user_friend_list_cached = cache.get("user_friend_list_%s" % username)
        if user_friend_list_cached != None and user_friend_list_cached != str(""):
            print("Using cached user friend list")
            userFriends = json.decode(user_friend_list_cached)
        else:
            print("Fetching user friend list")
            getUsersFriends = "https://friends.roblox.com/v1/users/%s/friends?userSort=StatusFrequents" % userRobloxId
            repGetUsersFriends = http.get(getUsersFriends)
            if repGetUsersFriends.status_code != 200:
                print("Fetching user friend list failed with status %d" % repGetUsersFriends.status_code)
                userFriends = []
            else:
                userFriends = repGetUsersFriends.json()["data"]

            ### Caching userFriends value from fetched logic
            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set("user_friend_list_%s" % username, json.encode(userFriends), ttl_seconds = TTL_SECONDS)

        ### POPULATE FRIENDS LIST
        friendsList = []
        for friend in userFriends:
            getUserAvatar = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%d&size=48x48&format=Png&isCircular=true" % friend["id"]
            repGetUserAvatar = http.get(getUserAvatar)
            friendObject = {"username": friend["name"], "id": "%d" % friend["id"], "isOnline": friend["isOnline"], "avatarUrl": repGetUserAvatar.json()["data"][0]["imageUrl"]}
            friendsList.append(friendObject)

        ### SORT BY ONLINE STATUS
        friendsList = sorted(friendsList, key = lambda f: f["isOnline"], reverse = True)

        ### BUILD FRIEND RENDER LIST
        renderFriend = []
        for friend in range(3):
            friend_avatar_cached = cache.get("user_avatar_%s" % friendsList[friend]["username"]) if friend < len(userFriends) else ""

            if friend_avatar_cached != None and friend_avatar_cached != str(""):
                print("Using cached friend avatar")
                friendAvatar = str(friend_avatar_cached)
            else:
                print("Fetching friend avatar")
                friendAvatar = ""
                if len(userFriends) != 0 and friend < len(userFriends):
                    friendAvatarUrl = friendsList[friend]["avatarUrl"]
                    friendAvatar = http.get(friendAvatarUrl).body()

                ### Caching friendAvatar value from fetched logic
                if friend < len(userFriends):
                    # TODO: Determine if this cache call can be converted to the new HTTP cache.
                    cache.set("user_avatar_%s" % friendsList[friend]["username"], str(friendAvatar), ttl_seconds = TTL_SECONDS)

            renderFriend.append(
                render.Padding(
                    pad = (25 + (13 * friend), TRIO_CIRCLES_TOP_OFFSET, 0, 0),
                    child = render.Row(
                        children = [
                            render.Stack(
                                children = [
                                    render.Circle(
                                        color = "#333" if dark_mode == True else "#222",
                                        diameter = 11,
                                    ),
                                    render.Image(src = friendAvatar, width = 11, height = 11) if friendAvatar != "" else render.Text(content = ""),
                                    render.Padding(
                                        pad = (10, 10, 0, 0),
                                        child = render.Circle(
                                            color = "#0f0" if len(userFriends) != 0 and friend < len(userFriends) and friend != len(userFriends) and friendsList[friend]["isOnline"] else "#888",
                                            diameter = 1,
                                        ),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ),
            )

        ### FAVORITE GAME MODE
    else:
        ### GET USER FAVORITE GAMES
        user_favorite_games_list_cached = cache.get("user_favorite_games_list_%s" % username)
        if user_favorite_games_list_cached != None and user_favorite_games_list_cached != str(""):
            print("Using cached user favorite game list")
            userFavoriteGames = json.decode(user_favorite_games_list_cached)
        else:
            print("Fetching user favorite game list")
            getUsersFavoriteGames = "https://games.roblox.com/v2/users/%s/favorite/games?accessFilter=Public&sortOrder=Desc&limit=10" % userRobloxId
            repGetUsersFavoriteGames = http.get(getUsersFavoriteGames)
            if repGetUsersFavoriteGames.status_code != 200:
                print("Fetching user favorite game list failed with status %d" % repGetUsersFavoriteGames.status_code)
                userFavoriteGames = []
            else:
                userFavoriteGames = repGetUsersFavoriteGames.json()["data"]

            ### Caching userFavoriteGames value from fetched logic
            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set("user_favorite_games_list_%s" % username, json.encode(userFavoriteGames), ttl_seconds = TTL_SECONDS)

        ### POPULATE FAVORITE GAMES RENDER LIST
        favoriteGamesList = []
        for game in userFavoriteGames:
            getGameAvatar = "https://thumbnails.roblox.com/v1/games/icons?universeIds=%d&size=50x50&format=Png&isCircular=false" % game["id"]
            repGetUserGame = http.get(getGameAvatar)
            gameObject = {"gameId": "%d" % game["id"], "avatarUrl": repGetUserGame.json()["data"][0]["imageUrl"]}
            favoriteGamesList.append(gameObject)

        ### BUILD POPULATE FAVORITE GAMES
        renderGame = []
        for game in range(3):
            game_avatar_cached = cache.get("game_avatar_%s" % favoriteGamesList[game]["gameId"]) if game < len(userFavoriteGames) else ""

            if game_avatar_cached != None and game_avatar_cached != str(""):
                print("Using cached game avatar")
                gameAvatar = str(game_avatar_cached)
            else:
                print("Fetching game avatar")
                gameAvatar = ""
                if len(userFavoriteGames) != 0 and game < len(userFavoriteGames):
                    gameAvatarUrl = favoriteGamesList[game]["avatarUrl"]
                    gameAvatar = http.get(gameAvatarUrl).body()

                ### Caching gameAvatar value from fetched logic
                if game < len(userFavoriteGames):
                    # TODO: Determine if this cache call can be converted to the new HTTP cache.
                    cache.set("game_avatar_%s" % favoriteGamesList[game]["gameId"], str(gameAvatar), ttl_seconds = TTL_SECONDS)

            renderGame.append(
                render.Padding(
                    pad = (25 + (13 * game), TRIO_CIRCLES_TOP_OFFSET, 0, 0),
                    child = render.Row(
                        children = [
                            render.Stack(
                                children = [
                                    render.Box(
                                        color = "#333",
                                        width = 11,
                                        height = 11,
                                    ),
                                    render.Image(src = gameAvatar, width = 11, height = 11) if gameAvatar != "" else render.Text(content = ""),
                                ],
                            ),
                        ],
                    ),
                ),
            )

    return render.Root(
        child = render.Stack(
            children = [
                render.Box(
                    color = "#000" if dark_mode == True else "#fff",
                    width = 64,
                    height = 32,
                ),
                render.Padding(
                    pad = (2, 2, 0, 0),
                    child = render.Row(
                        children = [
                            render.Stack(
                                children = [
                                    render.Circle(
                                        color = "#fff" if dark_mode == True else "#222",
                                        diameter = 21,
                                    ),
                                    render.Image(src = profilePhotoImg, width = 21, height = 21) if profilePhotoImg != "" else render.Text(content = ""),
                                ],
                            ),
                        ],
                    ),
                ),
                render.Padding(
                    pad = (19, 19, 0, 0),
                    child = PULSATING_ONLINE_DOT if isOnline else render.Circle(diameter = 4, color = "#888"),
                ),
                render.Padding(
                    pad = (30, 4, 0, 0),
                    child = render.Text(content = "friends", font = "CG-pixel-3x5-mono", color = accent_color),
                ) if view_mode == VIEW_FRIENDS else render.Padding(
                    pad = (26, 4, 0, 0),
                    child = render.Text(content = "favorites", font = "CG-pixel-3x5-mono", color = accent_color),
                ),
                render.Padding(
                    pad = (10, 26, 0, 0),
                    child = render.Marquee(
                        width = 64,
                        child = render.Text(content = "%s" % username, color = "#c7d0d8" if dark_mode == True else "#333", font = "CG-pixel-4x5-mono"),
                    ),
                ),
                render.Padding(
                    pad = (1, 24, 0, 0),
                    child = render.Image(src = ROBLOX_DARK_LOGO if dark_mode == True else ROBLOX_LIGHT_LOGO, width = 7, height = 7),
                ),
                renderFriend[0] if view_mode == VIEW_FRIENDS else renderGame[0],
                renderFriend[1] if view_mode == VIEW_FRIENDS else renderGame[1],
                renderFriend[2] if view_mode == VIEW_FRIENDS else renderGame[2],
            ],
        ),
    )

def get_schema():
    userIcons = ("userAstronaut", "userDoctor", "userTie", "userNurse", "userNinja")
    randomUserIcon = userIcons[time.now().second % 5]

    cubesIcons = ("cube", "cubes", "cubesStacked")
    randomCubeIcon = cubesIcons[time.now().second % 3]

    colorIcons = ("droplet", "palette", "eyeDropper")
    randomColorIcon = colorIcons[time.now().second % 3]

    darkModeIcons = ("sun", "moon", "lightbulb")
    randomDarkModeIcon = darkModeIcons[time.now().second % 3]

    view_mode_options = [
        schema.Option(
            display = "Online Friends",
            value = VIEW_FRIENDS,
        ),
        schema.Option(
            display = "Favorite Games",
            value = VIEW_FAVORITE_GAMES,
        ),
    ]

    accent_color_options = [
        schema.Option(
            display = "White",
            value = "#fff",
        ),
        schema.Option(
            display = "Red",
            value = "#f72525",
        ),
        schema.Option(
            display = "Orange",
            value = "#f77a24",
        ),
        schema.Option(
            display = "Yellow",
            value = "#f7cd25",
        ),
        schema.Option(
            display = "Green",
            value = "#25f739",
        ),
        schema.Option(
            display = "Blue",
            value = "#1a57f0",
        ),
        schema.Option(
            display = "Purple",
            value = "#8329e9",
        ),
        schema.Option(
            display = "Pink",
            value = "#fe2fe8",
        ),
        schema.Option(
            display = "Gray",
            value = "#444",
        ),
        schema.Option(
            display = "Clear",
            value = "#000",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "Roblox username",
                desc = "Enter a Roblox username",
                icon = randomUserIcon,
                default = "",
            ),
            schema.Dropdown(
                id = "view_mode",
                name = "View mode",
                desc = "Display your friends or games",
                icon = randomCubeIcon,
                default = view_mode_options[0].value,
                options = view_mode_options,
            ),
            schema.Dropdown(
                id = "accent_color",
                name = "Accent color",
                desc = "Choose an accent color",
                icon = randomColorIcon,
                default = accent_color_options[0].value,
                options = accent_color_options,
            ),
            schema.Toggle(
                id = "dark_mode",
                name = "Dark mode",
                desc = "Toggle between light and dark modes",
                icon = randomDarkModeIcon,
                default = True,
            ),
        ],
    )

PULSATING_ONLINE_DOT = render.Animation(
    children = [
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 4, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 4, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 4, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 3, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 3, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 3, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 3, color = "#0f0"),
        ),
        render.Padding(
            pad = (1, 1, 0, 0),
            child = render.Circle(diameter = 2, color = "#0f0"),
        ),
        render.Padding(
            pad = (1, 1, 0, 0),
            child = render.Circle(diameter = 2, color = "#0f0"),
        ),
        render.Padding(
            pad = (1, 1, 0, 0),
            child = render.Circle(diameter = 2, color = "#0f0"),
        ),
        render.Padding(
            pad = (1, 1, 0, 0),
            child = render.Circle(diameter = 2, color = "#0f0"),
        ),
        render.Padding(
            pad = (1, 1, 0, 0),
            child = render.Circle(diameter = 2, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 3, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 3, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 3, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 3, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 4, color = "#0f0"),
        ),
        render.Padding(
            pad = (0, 0, 0, 0),
            child = render.Circle(diameter = 4, color = "#0f0"),
        ),
    ],
)
