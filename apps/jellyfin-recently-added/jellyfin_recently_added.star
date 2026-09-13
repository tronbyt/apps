"""
Applet: Jellyfin Recently Added
Summary: Display Jellyfin recently added
Description: Displays recently added on Jellyfin server. Home screen sections plugin required.
Author: noahpodgurski
"""

load("animation.star", "animation")
load("http.star", "http")
load("images/jellyfin_icon.png", JELLYFIN_ICON_ASSET = "file")
load("images/sample1.jpg", SAMPLE1_ASSET = "file")
load("images/sample2.jpg", SAMPLE2_ASSET = "file")
load("images/sample3.jpg", SAMPLE3_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

JELLYFIN_ICON = JELLYFIN_ICON_ASSET.readall()

REFRESH_TIME = 86400  # once a day

SAMPLE_DATA = {
    "Items": [
        {
            "Name": "Aquaman",
            "Id": "abc",
        },
        {
            "Name": "A Walk to Remember",
            "Id": "def",
        },
        {
            "Name": "Enemy at the Gates",
            "Id": "ghi",
        },
    ],
}

SAMPLE_IMAGES = [
    SAMPLE1_ASSET.readall(),
    SAMPLE2_ASSET.readall(),
    SAMPLE3_ASSET.readall(),
]

def requestStatus(serverIP, serverPort, collectionName, apiKey, userId):
    res = http.get(
        "http://%s:%s/HomeScreen/Section/RecentlyAdded%s?api_key=%s&UserId=%s" % (serverIP, serverPort, collectionName, apiKey, userId),
        headers = {
            "Accept": "application/json",
        },
        ttl_seconds = REFRESH_TIME,
    )
    if res.status_code != 200:
        fail("request failed with status %d", res.status_code)
    res = res.json()
    return res

def requestThumb(serverIP, serverPort, apiKey, id):
    res = http.get(
        "http://%s:%s/Items/%s/Images/Primary?fillHeight=27&fillWidth=21&quality=96&api_key=%s" % (serverIP, serverPort, id, apiKey),
        headers = {
            "Accept": "image/jpeg",
        },
        ttl_seconds = REFRESH_TIME,
    )
    if res.status_code != 200:
        fail("request failed with status %d", res.status_code)
    return res.body()

def main(config):
    usingSampleData = False
    serverIP = config.get("serverIP", "")
    serverPort = config.get("serverPort", "")
    apiKey = config.get("apiKey", "")
    userId = config.get("userId")
    collectionName = config.get("collectionName", "Movies")
    titleText = config.get("titleText", "Recently added")
    showTitleCard = config.bool("showTitleCard", True)
    title = ""

    if not serverIP or not serverPort or not apiKey or not userId:
        usingSampleData = True

    if usingSampleData:
        newData = {"Items": []}
        for i in range(0, 3):
            newData["Items"].append({"ImageTags": {}})
            newData["Items"][i]["Name"] = SAMPLE_DATA["Items"][i]["Name"]
            newData["Items"][i]["Id"] = SAMPLE_IMAGES[i]
        data = newData
    else:
        serverPort = int(serverPort)
        data = requestStatus(serverIP, serverPort, collectionName, apiKey, userId)

    recentlyAdded = []

    n = 3
    l = len(data["Items"])
    if l < 3:
        n = l

    #only show last 3
    for i in range(0, n):
        entry = data["Items"][i]
        id = entry["Id"]
        title = entry["Name"]

        if not usingSampleData:
            thumbnail = requestThumb(serverIP, serverPort, apiKey, id)
        else:
            thumbnail = entry["Id"]

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
        if i < l - 1:
            recentlyAdded.append(
                render.Box(height = 32, width = 1, color = "#a160c4"),
            )

    if showTitleCard:
        return render.Root(
            render.Stack(
                children = [
                    animation.Transformation(
                        child = render.Column(
                            children = [
                                render.Box(height = 1, width = 64, color = "#a160c4"),
                                render.Box(
                                    width = 64,
                                    height = 30,
                                    child = render.Row(
                                        main_align = "center",
                                        cross_align = "center",
                                        expanded = True,
                                        children = [
                                            render.Image(src = JELLYFIN_ICON, width = 16),
                                            render.Box(width = 2),
                                            render.WrappedText(titleText, align = "center"),
                                        ],
                                    ),
                                ),
                                render.Box(height = 1, width = 64, color = "#a160c4"),
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
    collectionNameOptions = [
        schema.Option(
            display = "Movies",
            value = "Movies",
        ),
        schema.Option(
            display = "Shows",
            value = "Shows",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "serverIP",
                name = "Server IP",
                desc = "IP of Jellyfin Server",
                icon = "gear",
            ),
            schema.Text(
                id = "serverPort",
                name = "Server Port",
                desc = "Ex: 8096",
                icon = "gear",
            ),
            schema.Text(
                id = "apiKey",
                name = "Api Key",
                desc = "Add API key from server dashboard advanced settings",
                icon = "gear",
                secret = True,
            ),
            schema.Text(
                id = "userId",
                name = "User Id",
                desc = "Id of the user's dashboard (find IDs in URL by clicking on users in server dashboard)",
                icon = "gear",
            ),
            schema.Dropdown(
                id = "collectionName",
                name = "Collection Name",
                icon = "gear",
                desc = "Select collection",
                default = collectionNameOptions[0].value,
                options = collectionNameOptions,
            ),
            schema.Text(
                id = "titleText",
                name = "Title Text",
                icon = "gear",
                desc = "Text to show on title card",
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
