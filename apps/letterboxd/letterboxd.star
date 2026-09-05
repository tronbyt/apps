load("animation.star", "animation")
load("hmac.star", "hmac")
load("http.star", "http")
load("images/heart_image.png", HEART_IMAGE_ASSET = "file")
load("images/lb_image.png", LB_IMAGE_ASSET = "file")
load("images/rewatch_image.png", REWATCH_IMAGE_ASSET = "file")
load("images/star_image.png", STAR_IMAGE_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

HEART_IMAGE = HEART_IMAGE_ASSET.readall()
LB_IMAGE = LB_IMAGE_ASSET.readall()
REWATCH_IMAGE = REWATCH_IMAGE_ASSET.readall()
STAR_IMAGE = STAR_IMAGE_ASSET.readall()

DEFAULT_USERNAME = "danny"

BASE_URL = "https://api.letterboxd.com/api/v0"
LB_URL = "https://letterboxd.com/"

UUID_URL = "https://www.uuidtools.com/api/generate/v4"
LB_ICON = LB_IMAGE
STAR_ICON = STAR_IMAGE
HEART_ICON = HEART_IMAGE
REWATCH_ICON = REWATCH_IMAGE

PERC_IN = 0.10
PERC_OUT = 0.90
DURATION = 105
DELAY_1 = 0
DELAY_2 = 95
DELAY_3 = 190
ACTIVITY_START_INDEX = 0
ACTIVITY_END_INDEX = 4
REVIEW_COUNT = 3

def main(config):
    api_key = config.get("letterboxd_api_key")
    api_secret = config.get("letterboxd_api_secret")
    if not api_key or not api_secret:
        return render.Root(
            child = render.Text("Please set your Letterboxd API key and secret in the config."),
        )
    username = config.str("username", DEFAULT_USERNAME)
    Lid = getLID(username)
    activityUrl = "/member/%s/activity" % (Lid)
    memberActivity = getMemberActivity(api_key, api_secret, Lid, activityUrl)
    recentActivity = memberActivity["items"]
    entryList = recentActivity[ACTIVITY_START_INDEX:ACTIVITY_END_INDEX]
    entryList = [getEntry(api_key, api_secret, Lid, entryList[i]) for i in range(REVIEW_COUNT)]
    return render.Root(
        child = renderReviews(entryList),
    )

# functions
def get(api_key, api_secret, Lid, route, params = ""):
    method = "GET"
    toSalt = constructUrl(route, api_key, params)
    signature = getSignature(api_secret, method, toSalt)
    url = "%s&signature=%s" % (toSalt, signature)

    # CACHE CHECK
    jsonresults = check_cache(url, "json", Lid)
    return jsonresults

def getSignature(api_secret, method, toSalt):
    body = ""
    str = "%s\u0000%s\u0000%s" % (method, toSalt, body)
    sigHash = hmac.sha256(api_secret, str).lower()
    lowerSig = sigHash.lower()
    return lowerSig

def constructUrl(authRoute, apiKey, params = ""):
    timestamp = time.now().unix
    nonce = http.get(UUID_URL).json()[0]
    formattedParams = ["&%s=%s" % (p, params[p]) for p in params] if params else [""]
    constructParams = "".join(formattedParams)
    constructed = "%s%s?apikey=%s&nonce=%s&timestamp=%s%s" % (BASE_URL, authRoute, apiKey, nonce, timestamp, constructParams)
    return constructed

def getLID(target):
    url = "%s%s" % (LB_URL, target)

    # CACHE CHECK
    lid = check_cache(url, "identifier")
    return lid

def getMemberActivity(api_key, api_secret, Lid, query):
    activity = get(api_key, api_secret, Lid, query, {"where": "NotOwnActivity", "include": "DiaryEntryActivity"})
    return activity

def getEntry(api_key, api_secret, Lid, item):
    film = item["diaryEntry"]["film"]
    diaryEntry = item["diaryEntry"]
    id = diaryEntry["id"]
    logEntryUrl = ("/log-entry/%s") % (id)
    logEntry = get(api_key, api_secret, Lid, logEntryUrl)
    review = logEntry.get("review", "")
    reviewText = review.get("lbml", "") if review != "" else ""
    movieName = film.get("name", "")
    releaseYear = film.get("releaseYear", "")
    releaseYear = int(releaseYear)
    releaseYear = "%d" % releaseYear
    diaryDetails = logEntry.get("diaryDetails", {})
    rewatch = diaryDetails.get("rewatch", False)
    posterUrl = film["poster"]["sizes"][0]["url"]

    # CACHE CHECK
    poster = check_cache(posterUrl, "body")
    owner = item["diaryEntry"]["owner"]
    ownerName = owner["displayName"]
    avatarUrl = owner["avatar"]["sizes"][0]["url"]

    # CACHE CHECK
    avatar = check_cache(avatarUrl, "body")
    rating = diaryEntry.get("rating", "")
    like = diaryEntry.get("like", 0)
    entryDict = {
        "reviewText": reviewText,
        "movieName": movieName,
        "releaseYear": releaseYear,
        "rewatch": rewatch,
        "poster": poster,
        "ownerName": ownerName,
        "avatar": avatar,
        "rating": rating,
        "like": like,
    }
    return entryDict

def renderReviews(entryList):
    return render.Column(
        children = [
            render.Row(
                children = [
                    render.Padding(
                        pad = (0, 0, 0, 0),
                        child = render.Image(
                            width = 23,
                            src = LB_ICON,
                        ),
                    ),
                    render.Box(
                        width = 41,
                        height = 8,
                        child = render.Stack(
                            children = [
                                animation.Transformation(
                                    wait_for_child = True,
                                    child = getUsername(entryList[0], 20),
                                    duration = DURATION,
                                    delay = DELAY_1,
                                    keyframes = getKeyframes(-32, -64),
                                ),
                                animation.Transformation(
                                    wait_for_child = True,
                                    child = getUsername(entryList[1], 110),
                                    duration = DURATION,
                                    delay = DELAY_2,
                                    keyframes = getKeyframes(-32, -64),
                                ),
                                animation.Transformation(
                                    wait_for_child = True,
                                    child = getUsername(entryList[2], 210),
                                    duration = DURATION,
                                    delay = DELAY_3,
                                    keyframes = getKeyframes(-32, -64),
                                ),
                            ],
                        ),
                    ),
                ],
            ),
            render.Stack(
                children = [
                    animation.Transformation(
                        wait_for_child = True,
                        child = getContent(entryList[0], 20),
                        duration = DURATION,
                        delay = DELAY_1,
                        keyframes = getKeyframes(32, 64),
                    ),
                    animation.Transformation(
                        wait_for_child = True,
                        child = getContent(entryList[1], 110),
                        duration = DURATION,
                        delay = DELAY_2,
                        keyframes = getKeyframes(32, 64),
                    ),
                    animation.Transformation(
                        wait_for_child = True,
                        child = getContent(entryList[2], 210),
                        duration = DURATION,
                        delay = DELAY_3,
                        keyframes = getKeyframes(32, 64),
                    ),
                ],
            ),
        ],
    )

def renderStar(width, height):
    return render.Box(
        height = height,
        width = width,
        child = render.Image(
            width = width,
            src = STAR_ICON,
        ),
    )

def renderHalfStar(width):
    return render.Box(
        width = width,
        child = render.Row(
            children = [
                render.Image(
                    width = width * 2 - 1,
                    src = STAR_ICON,
                ),
            ],
        ),
    )

def getStarCount(count, releaseYear):
    if count == "":
        return [render.Padding(child = render.Text(releaseYear), pad = (1, 0, 0, 0))]
    halfStarRender = render.Padding(child = renderHalfStar(4), pad = (1, 0, 0, 0))
    halfStar = count % 1 != 0
    starCount = int(count - 0.5) if halfStar else int(count)
    starList = [render.Padding(child = renderStar(7, 7), pad = (1, 1, 0, 0)) for x in range(starCount)]
    halfStarList = starList + [halfStarRender] if halfStar else starList
    return halfStarList

def renderHeart(width, height):
    return render.Box(
        height = height,
        width = width,
        child = render.Image(
            width = width,
            src = HEART_ICON,
        ),
    )

def renderRewatch(width, height):
    return render.Box(
        height = height,
        width = width,
        child = render.Image(
            width = width,
            src = REWATCH_ICON,
        ),
    )

def getHeart(hasHeart):
    if hasHeart == True:
        return render.Padding(
            child = renderHeart(13, 13),
            pad = (1, 0, 0, 0),
        )
    return render.Text("")

def getRewatch(isRewatch):
    if isRewatch == True:
        return render.Padding(
            child = renderRewatch(10, 10),
            pad = (1, 1, 0, 0),
        )
    return render.Text("")

def getKeyframes(yIn, xOut):
    return [
        animation.Keyframe(
            percentage = 0.0,
            transforms = [animation.Translate(0, yIn)],
            curve = "ease_in_out",
        ),
        animation.Keyframe(
            percentage = PERC_IN,
            transforms = [animation.Translate(0, 0)],
            curve = "ease_in_out",
        ),
        animation.Keyframe(
            percentage = PERC_OUT,
            transforms = [animation.Translate(0, 0)],
            curve = "ease_in_out",
        ),
        animation.Keyframe(
            percentage = 1.0,
            transforms = [animation.Translate(xOut, 0)],
        ),
    ]

def getContent(entryObject, marqueeOffsetStart):
    return render.Row(
        expanded = True,
        children = [
            render.Padding(
                child = render.Image(
                    width = 23,
                    src = entryObject["avatar"],
                ),
                pad = (0, 1, 0, 0),
            ),
            render.Row(
                expanded = True,
                children = [
                    render.Column(
                        children = [
                            render.Padding(
                                pad = (0, 2, 0, 0),
                                child = render.Marquee(
                                    width = 41,
                                    offset_start = marqueeOffsetStart,
                                    child = render.Row(
                                        children = [
                                            render.Text(
                                                entryObject["movieName"],
                                                font = "6x13",
                                            ),
                                            getHeart(entryObject["like"]),
                                            getRewatch(entryObject["rewatch"]),
                                        ],
                                    ),
                                    align = "center",
                                ),
                            ),
                            render.Row(
                                cross_align = "center",
                                children = getStarCount(entryObject["rating"], entryObject["releaseYear"]),
                            ),
                        ],
                    ),
                ],
            ),
        ],
    )

def getUsername(entryObject, marqueeOffsetStart):
    return render.Marquee(
        width = 41,
        offset_start = marqueeOffsetStart,
        child = render.Row(
            children = [
                render.Text(
                    entryObject["ownerName"],
                ),
            ],
        ),
    )

def check_cache(url, type = "body", timeout = 300):
    if type == "json":
        # the URL can't be used as a key here because each request has a UUID
        res = http.get(url = url, ttl_seconds = timeout)
        if res.status_code != 200:
            fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

        return res.json()

    res = http.get(url = url, ttl_seconds = timeout)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    if type == "identifier":
        return res.headers["X-Letterboxd-Identifier"]

    return res.body()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "username",
                desc = "Letterboxd username",
                icon = "user",
            ),
            schema.Text(
                id = "letterboxd_api_key",
                name = "Letterboxd API Key",
                desc = "A Letterboxd API key to access the Letterboxd API.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "letterboxd_api_secret",
                name = "Letterboxd API Secret",
                desc = "A Letterboxd API secret to access the Letterboxd API.",
                icon = "key",
                secret = True,
            ),
        ],
    )
