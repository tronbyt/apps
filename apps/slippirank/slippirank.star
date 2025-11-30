"""
Applet: SlippiRank
Summary: Shows slippi rank
Description: Shows current rank from SSBM Slippi profile.
Author: noahpodgurski
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("images/img_07a65b2b.png", IMG_07a65b2b_ASSET = "file")
load("images/img_10d3ba6a.png", IMG_10d3ba6a_ASSET = "file")
load("images/img_1495fb4a.png", IMG_1495fb4a_ASSET = "file")
load("images/img_1c8150b1.png", IMG_1c8150b1_ASSET = "file")
load("images/img_21dc8586.png", IMG_21dc8586_ASSET = "file")
load("images/img_25a1d983.png", IMG_25a1d983_ASSET = "file")
load("images/img_2c613b44.png", IMG_2c613b44_ASSET = "file")
load("images/img_46533544.png", IMG_46533544_ASSET = "file")
load("images/img_49498b46.png", IMG_49498b46_ASSET = "file")
load("images/img_4af5a275.png", IMG_4af5a275_ASSET = "file")
load("images/img_4e6ab285.png", IMG_4e6ab285_ASSET = "file")
load("images/img_68148cc9.png", IMG_68148cc9_ASSET = "file")
load("images/img_864cc267.png", IMG_864cc267_ASSET = "file")
load("images/img_87ca9876.png", IMG_87ca9876_ASSET = "file")
load("images/img_8bfa1995.png", IMG_8bfa1995_ASSET = "file")
load("images/img_acc5feb5.png", IMG_acc5feb5_ASSET = "file")
load("images/img_b2619eea.png", IMG_b2619eea_ASSET = "file")
load("images/img_b572838d.png", IMG_b572838d_ASSET = "file")
load("images/img_b9e83542.png", IMG_b9e83542_ASSET = "file")
load("images/img_dc234e76.png", IMG_dc234e76_ASSET = "file")
load("images/img_ee6638b0.png", IMG_ee6638b0_ASSET = "file")
load("images/img_f2435098.png", IMG_f2435098_ASSET = "file")

REFRESH_TIME = 43200  # twice a day
DEFAULT_USER_CODE = "hbox-305"

RANKS = [
    {
        "name": "GM",
        "max": 9999,
        "min": 2350,
    },
    {
        "name": "Master 2",
        "max": 2349.99,
        "min": 2275,
    },
    {
        "name": "Master 1",
        "max": 2274.99,
        "min": 2191.75,
    },
    {
        "name": "Diamond 3",
        "max": 2191.74,
        "min": 2136.28,
    },
    {
        "name": "Diamond 2",
        "max": 2136.27,
        "min": 2073.67,
    },
    {
        "name": "Diamond 1",
        "max": 2073.66,
        "min": 2003.92,
    },
    {
        "name": "Platinum3",
        "max": 2003.91,
        "min": 1927.03,
    },
    {
        "name": "Platinum2",
        "max": 1927.02,
        "min": 1843,
    },
    {
        "name": "Platinum1",
        "max": 1842.99,
        "min": 1751.83,
    },
    {
        "name": "Gold 3",
        "max": 1751.82,
        "min": 1653.52,
    },
    {
        "name": "Gold 2",
        "max": 1653.51,
        "min": 1548.07,
    },
    {
        "name": "Gold 1",
        "max": 1548.06,
        "min": 1435.48,
    },
    {
        "name": "Silver 3",
        "max": 1435.47,
        "min": 1315.75,
    },
    {
        "name": "Silver 2",
        "max": 1315.74,
        "min": 1188.88,
    },
    {
        "name": "Silver 1",
        "max": 1188.87,
        "min": 1054.87,
    },
    {
        "name": "Bronze 3",
        "max": 1054.86,
        "min": 913.72,
    },
    {
        "name": "Bronze 2",
        "max": 913.71,
        "min": 765.43,
    },
    {
        "name": "Bronze 1",
        "max": 765.42,
        "min": 0,
    },
]

RANK_IMGS = {
    "Bronze 1": IMG_8bfa1995_ASSET.readall(),
    "Bronze 2": IMG_864cc267_ASSET.readall(),
    "Bronze 3": IMG_b2619eea_ASSET.readall(),
    "Diamond 1": IMG_2c613b44_ASSET.readall(),
    "Diamond 2": IMG_68148cc9_ASSET.readall(),
    "Diamond 3": IMG_49498b46_ASSET.readall(),
    "GM": IMG_10d3ba6a_ASSET.readall(),
    "Gold 1": IMG_25a1d983_ASSET.readall(),
    "Gold 2": IMG_21dc8586_ASSET.readall(),
    "Gold 3": IMG_46533544_ASSET.readall(),
    "Master 1": IMG_87ca9876_ASSET.readall(),
    "Master 2": IMG_07a65b2b_ASSET.readall(),
    "Master 3": IMG_ee6638b0_ASSET.readall(),
    "Platinum1": IMG_b572838d_ASSET.readall(),
    "Platinum2": IMG_1c8150b1_ASSET.readall(),
    "Platinum3": IMG_1495fb4a_ASSET.readall(),
    "Silver 1": IMG_b9e83542_ASSET.readall(),
    "Silver 2": IMG_acc5feb5_ASSET.readall(),
    "Silver 3": IMG_dc234e76_ASSET.readall(),
    "Unranked 1": IMG_4af5a275_ASSET.readall(),
    "Unranked 2": IMG_4e6ab285_ASSET.readall(),
    "Unranked 3": IMG_f2435098_ASSET.readall(),
}

def getRank(elo):
    for rank in RANKS:
        if rank["min"] < elo and rank["max"] > elo:
            return rank["name"]
    return "Unranked3"

RANK_URL = "https://gql-gateway-dot-slippi.uc.r.appspot.com/graphql"

def getUserCodeDashIndex(userCode):
    for i in range(len(userCode)):
        if userCode[i] == "#" or userCode[i] == "-":
            return i
    return -1

def requestRank(userCode):
    body = json.encode({
        "operationName": "AccountManagementPageQuery",
        "variables": {
            "cc": userCode,
            "uid": userCode,
        },
        "query": "fragment userProfilePage on User {\n  fbUid\n  displayName\n  connectCode {\n    code\n    __typename\n  }\n  status\n  activeSubscription {\n    level\n    hasGiftSub\n    __typename\n  }\n  rankedNetplayProfile {\n    id\n    ratingOrdinal\n    ratingUpdateCount\n    wins\n    losses\n    dailyGlobalPlacement\n    dailyRegionalPlacement\n    continent\n    characters {\n      id\n      character\n      gameCount\n      __typename\n    }\n    __typename\n  }\n  __typename\n}\n\nquery AccountManagementPageQuery($cc: String!, $uid: String!) {\n  getUser(fbUid: $uid) {\n    ...userProfilePage\n    __typename\n  }\n  getConnectCode(code: $cc) {\n    user {\n      ...userProfilePage\n      __typename\n    }\n    __typename\n  }\n}\n",
    })
    res = http.post(
        RANK_URL,
        body = body,
        headers = {
            "Content-Type": "application/json",
        },
        ttl_seconds = REFRESH_TIME,
    )
    if res.status_code != 200:
        fail("request failed with status %d", res.status_code)
    res = res.json()
    return res

def main(config):
    userCode = config.str("userCode")
    showRankName = config.bool("showRankName")
    showElo = config.bool("showElo")
    if userCode == None or userCode == "":
        userCode = DEFAULT_USER_CODE
        # fail("No user code configured")

    userCode = userCode.upper()
    userCodeDashIndex = getUserCodeDashIndex(userCode)
    if userCodeDashIndex == -1:
        fail("Invalid user code")

    # print(userCode)

    userCodeHash = userCode[:userCodeDashIndex] + "#" + userCode[userCodeDashIndex + 1:]
    rankedData = cache.get("rankedData")
    if rankedData != None:
        # print("Cached - Displaying cached rankedData.")
        rankedData = json.decode(rankedData)

        # print(rankedData)
        if not rankedData["data"]["getUser"] or userCodeHash != rankedData["data"]["getConnectCode"]["user"]["connectCode"]["code"]:
            #new usercode, request data again
            rankedData = requestRank(userCodeHash)
            cache.set("rankedData", json.encode(rankedData), ttl_seconds = REFRESH_TIME)
    else:
        # print("No data available - Calling slippi API.")
        rankedData = requestRank(userCodeHash)
        cache.set("rankedData", json.encode(rankedData), ttl_seconds = REFRESH_TIME)

    if rankedData["data"]["getConnectCode"]["user"]["displayName"]:
        elo = rankedData["data"]["getConnectCode"]["user"]["rankedNetplayProfile"]["ratingOrdinal"]
        rank = getRank(elo)
        name = rankedData["data"]["getConnectCode"]["user"]["displayName"]
        rankedImg = base64.decode(RANK_IMGS[rank])
    else:
        fail("Ranked data did not respond correctly")

    msg = "%s \n%s \n%d" % (name, rank, elo)
    print(showRankName)
    if showRankName == False:
        rank = ""
        msg = "%s \n%d" % (name, elo)
    if showElo == False:
        msg = "%s \n%s" % (name, rank)

    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = rankedImg, width = 18, height = 18),
                render.Column(
                    expanded = True,
                    main_align = "center",
                    children = [
                        render.WrappedText(msg),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "userCode",
                name = "User Code",
                desc = "Ex: (HBOX-123 or HBOX#123)",
                icon = "user",
            ),
            schema.Toggle(
                id = "showRankName",
                name = "Show Rank Name",
                desc = "",
                icon = "question",
                default = True,
            ),
            schema.Toggle(
                id = "showElo",
                name = "Show Elo",
                desc = "",
                icon = "question",
                default = True,
            ),
        ],
    )
