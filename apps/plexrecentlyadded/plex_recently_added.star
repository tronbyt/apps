"""
Applet: Plex Recently Added
Summary: Display Plex recently added
Description: Displays recently added on Plex server. Recommended to set up a local proxy server `index.js` to host the data. See https://github.com/tidbyt/community/blob/main/apps/plexrecentlyadded/README.md for more information.
Author: noahpodgurski
"""

load("animation.star", "animation")
load("http.star", "http")
load("images/plex_icon.png", PLEX_ICON_ASSET = "file")
load("images/sample1.jpg", SAMPLE1_ASSET = "file")
load("images/sample2.jpg", SAMPLE2_ASSET = "file")
load("images/sample3.jpg", SAMPLE3_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

PLEX_ICON = PLEX_ICON_ASSET.readall()

REFRESH_TIME = 86400  # twice a day

SAMPLE_DATA = {
    "MediaContainer": {
        "Metadata": [
            {
                "title": "Aquaman",
                "contentRating": "PG-13",
            },
            {
                "title": "A Walk to Remember",
                "titleSort": "Walk to Remember",
                "contentRating": "PG",
            },
            {
                "title": "Enemy at the Gates",
                "contentRating": "R",
            },
        ],
    },
}

SAMPLE_IMAGES = [
    SAMPLE1_ASSET.readall(),
    SAMPLE2_ASSET.readall(),
    SAMPLE3_ASSET.readall(),
]

def requestStatus(serverIP, serverPort, plexToken, apiKey):
    res = http.get(
        "http://%s:%d/library/recentlyAdded" % (serverIP, serverPort),
        headers = {
            "Accept": "application/json",
            "X-Plex-Token": plexToken,
            "x-api-key": apiKey,
        },
        ttl_seconds = REFRESH_TIME,
    )
    if res.status_code != 200:
        fail("request failed with status %d", res.status_code)
    res = res.json()
    return res

def requestThumb(serverIP, serverPort, plexToken, apiKey, thumbnailURL):
    res = http.get(
        "http://%s:%d%s" % (serverIP, serverPort, thumbnailURL),
        headers = {
            "Accept": "image/jpeg",
            "X-Plex-Token": plexToken,
            "x-api-key": apiKey,
        },
        ttl_seconds = REFRESH_TIME,
    )
    if res.status_code != 200:
        fail("request failed with status %d", res.status_code)
    return res.body()

def main(config):
    usingSampleData = False
    serverIP = config.str("serverIP")
    serverPort = config.str("serverPort")
    plexToken = config.str("plexToken")
    apiKey = config.str("apiKey", "")
    showTitleCard = config.bool("showTitleCard", True)
    title = ""

    if not serverIP or type(int(serverPort)) != "int":
        usingSampleData = True
        print("Using sample data")

    if usingSampleData:
        # have to do it this weird way to dodge frozen hash table error
        newData = {}
        newData["MediaContainer"] = {}
        newData["MediaContainer"]["Metadata"] = []
        for i in range(0, 3):
            newData["MediaContainer"]["Metadata"].append({})
            newData["MediaContainer"]["Metadata"][i]["title"] = SAMPLE_DATA["MediaContainer"]["Metadata"][i]["title"]
            newData["MediaContainer"]["Metadata"][i]["thumb"] = SAMPLE_IMAGES[i]
            title = newData["MediaContainer"]["Metadata"][i]["title"]
        data = newData
    else:
        serverPort = int(serverPort)
        data = requestStatus(serverIP, serverPort, plexToken, apiKey)

    recentlyAdded = []

    #only show last 3
    for i in range(0, 3):
        entry = data["MediaContainer"]["Metadata"][i]
        if entry.get("parentThumb"):
            thumbnailURL = entry["parentThumb"]
        else:
            thumbnailURL = entry["thumb"]

        if entry.get("parentTitle"):
            title = entry["parentTitle"]
        else:
            title = entry["title"]

        if not usingSampleData:
            thumbnail = requestThumb(serverIP, serverPort, plexToken, apiKey, thumbnailURL)
        else:
            thumbnail = entry["thumb"]

        recentlyAdded.append(
            render.Column(
                children = [
                    render.Image(src = thumbnail, width = 21, height = 27),
                    render.Marquee(
                        width = 21,
                        offset_start = 60 if showTitleCard else 0,  #offset to wait to slide in
                        child = render.Text(title, font = "CG-pixel-3x5-mono"),
                    ),
                ],
            ),
        )
        recentlyAdded.append(
            render.Box(height = 32, width = 1, color = "#EFAF08"),
        )

    if showTitleCard:
        return render.Root(
            render.Stack(
                children = [
                    animation.Transformation(
                        child = render.Column(
                            children = [
                                render.Box(height = 1, width = 64, color = "#EFAF08"),
                                render.Box(
                                    width = 64,
                                    height = 30,
                                    child = render.Row(
                                        main_align = "center",
                                        cross_align = "center",
                                        expanded = True,
                                        children = [
                                            render.Image(src = PLEX_ICON),
                                            render.Box(width = 2),
                                            render.WrappedText("Recently Added", align = "center"),
                                        ],
                                    ),
                                ),
                                render.Box(height = 1, width = 64, color = "#EFAF08"),
                            ],
                        ),
                        duration = 200,
                        delay = 0,
                        origin = animation.Origin(0, 0),
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(0, 0)],
                            ),
                            animation.Keyframe(
                                percentage = 0.1,
                                transforms = [animation.Translate(0, 0)],
                            ),
                            animation.Keyframe(
                                percentage = 0.2,
                                transforms = [animation.Translate(0, -32)],
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(0, -32)],
                            ),
                        ],
                    ),
                    animation.Transformation(
                        child = render.Row(
                            children = recentlyAdded,
                        ),
                        duration = 200,
                        delay = 0,
                        origin = animation.Origin(0, 0),
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(0, 32)],
                            ),
                            animation.Keyframe(
                                percentage = 0.1,
                                transforms = [animation.Translate(0, 32)],
                            ),
                            animation.Keyframe(
                                percentage = 0.2,
                                transforms = [animation.Translate(0, 0)],
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(0, 0)],
                            ),
                        ],
                    ),
                ],
            ),
        )
    else:
        return render.Root(
            child = render.Row(
                children = recentlyAdded,
            ),
        )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "serverIP",
                name = "Server IP",
                desc = "IP of Plex Server",
                icon = "gear",
            ),
            schema.Text(
                id = "serverPort",
                name = "Server Port",
                desc = "Ex: 32400",
                icon = "gear",
            ),
            schema.Text(
                id = "plexToken",
                name = "Plex-Token",
                desc = "\"X-Plex-Token\"",
                icon = "gear",
                secret = True,
            ),
            schema.Text(
                id = "apiKey",
                name = "API Key",
                desc = "Use with proxy server (optional)",
                icon = "gear",
                secret = True,
            ),
            schema.Toggle(
                id = "showTitleCard",
                name = "Show title card",
                desc = "Show title card",
                icon = "gear",
                default = True,
            ),
        ],
    )
