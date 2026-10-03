"""
Applet: SlippiRank
Summary: Shows slippi rank
Description: Shows current rank from SSBM Slippi profile.
Author: noahpodgurski
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/rank_bronze_1.png", RANK_BRONZE_1_ASSET = "file")
load("images/rank_bronze_2.png", RANK_BRONZE_2_ASSET = "file")
load("images/rank_bronze_3.png", RANK_BRONZE_3_ASSET = "file")
load("images/rank_diamond_1.png", RANK_DIAMOND_1_ASSET = "file")
load("images/rank_diamond_2.png", RANK_DIAMOND_2_ASSET = "file")
load("images/rank_diamond_3.png", RANK_DIAMOND_3_ASSET = "file")
load("images/rank_gm.png", RANK_GM_ASSET = "file")
load("images/rank_gold_1.png", RANK_GOLD_1_ASSET = "file")
load("images/rank_gold_2.png", RANK_GOLD_2_ASSET = "file")
load("images/rank_gold_3.png", RANK_GOLD_3_ASSET = "file")
load("images/rank_master_1.png", RANK_MASTER_1_ASSET = "file")
load("images/rank_master_2.png", RANK_MASTER_2_ASSET = "file")
load("images/rank_master_3.png", RANK_MASTER_3_ASSET = "file")
load("images/rank_platinum_1.png", RANK_PLATINUM_1_ASSET = "file")
load("images/rank_platinum_2.png", RANK_PLATINUM_2_ASSET = "file")
load("images/rank_platinum_3.png", RANK_PLATINUM_3_ASSET = "file")
load("images/rank_silver_1.png", RANK_SILVER_1_ASSET = "file")
load("images/rank_silver_2.png", RANK_SILVER_2_ASSET = "file")
load("images/rank_silver_3.png", RANK_SILVER_3_ASSET = "file")
load("images/rank_unranked_1.png", RANK_UNRANKED_1_ASSET = "file")
load("images/rank_unranked_2.png", RANK_UNRANKED_2_ASSET = "file")
load("images/rank_unranked_3.png", RANK_UNRANKED_3_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

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
    "Bronze 1": RANK_BRONZE_1_ASSET.readall(),
    "Bronze 2": RANK_BRONZE_2_ASSET.readall(),
    "Bronze 3": RANK_BRONZE_3_ASSET.readall(),
    "Diamond 1": RANK_DIAMOND_1_ASSET.readall(),
    "Diamond 2": RANK_DIAMOND_2_ASSET.readall(),
    "Diamond 3": RANK_DIAMOND_3_ASSET.readall(),
    "GM": RANK_GM_ASSET.readall(),
    "Gold 1": RANK_GOLD_1_ASSET.readall(),
    "Gold 2": RANK_GOLD_2_ASSET.readall(),
    "Gold 3": RANK_GOLD_3_ASSET.readall(),
    "Master 1": RANK_MASTER_1_ASSET.readall(),
    "Master 2": RANK_MASTER_2_ASSET.readall(),
    "Master 3": RANK_MASTER_3_ASSET.readall(),
    "Platinum1": RANK_PLATINUM_1_ASSET.readall(),
    "Platinum2": RANK_PLATINUM_2_ASSET.readall(),
    "Platinum3": RANK_PLATINUM_3_ASSET.readall(),
    "Silver 1": RANK_SILVER_1_ASSET.readall(),
    "Silver 2": RANK_SILVER_2_ASSET.readall(),
    "Silver 3": RANK_SILVER_3_ASSET.readall(),
    "Unranked 1": RANK_UNRANKED_1_ASSET.readall(),
    "Unranked 2": RANK_UNRANKED_2_ASSET.readall(),
    "Unranked 3": RANK_UNRANKED_3_ASSET.readall(),
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
        rankedImg = RANK_IMGS[rank]
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
