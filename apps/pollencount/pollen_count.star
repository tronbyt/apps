"""
Applet: Pollen Count
Summary: Pollen count for your area
Description: Displays a pollen count for your area. Enter your location for updates every 12 hours on the current conditions in your town, as well as which types of pollen are in the air today. Get your API key from the Google Maps Platform (Pollen API).
Author: Nicole Brooks
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/ground_bare.png", GROUND_BARE_ASSET = "file")
load("images/ground_grass.png", GROUND_GRASS_ASSET = "file")
load("images/sky_high_pollen.png", SKY_HIGH_POLLEN_ASSET = "file")
load("images/sky_low_pollen.png", SKY_LOW_POLLEN_ASSET = "file")
load("images/sky_med_pollen.png", SKY_MED_POLLEN_ASSET = "file")
load("images/trees.png", TREES_ASSET = "file")
load("images/weeds.png", WEEDS_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

# DEFAULT_LOC = {
#     "lat": "40.63",
#     "lng": "-74.02",
#     "locality": "",
# }
DEFAULT_LOCATION = """
{
	"lat": "40.6781784",
	"lng": "-73.9441579",
	"description": "Brooklyn, NY, USA",
	"locality": "Brooklyn",
	"place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
	"timezone": "America/New_York"
}
"""
COLORS = {
    "yellow": "#D19C21",
    "red": "#B31F0E",
    "green": "#338722",
}
DEFAULT_TIMEZONE = "America/New_York"
API_URL_BASE = "https://pollen.googleapis.com/v1/forecast:lookup?days=1&location.latitude="

def main(config):
    print("Initializing Pollen Count...")

    #Get lat and long from schema.
    loc = json.decode(config.get("location", DEFAULT_LOCATION))

    lat = float(loc.get("lat"))
    lng = float(loc.get("lng"))

    dev_key = config.str("dev_key", "")

    # make API call and cache result
    print("calling API")
    todaysCount = getTodaysCount(lat, lng, dev_key)

    firstMixin = None
    secondMixin = None
    if "message" in todaysCount:
        print("Error! " + todaysCount["message"])
        average = ""

        skySrc = images["skyLowPollen"]
        groundSrc = images["groundBare"]

        # Google API rate limit is HTTP 429
        if todaysCount.get("code") == 429:
            textOne = "RATE"
            textTwo = "LIMIT"
        else:
            textOne = "ERROR"
            textTwo = todaysCount.get("status", "UNKNOWN")
        textColumn = [
            render.Text(
                content = textOne,
                color = "#FFFFFF",
                font = "tb-8",
            ),
            render.Padding(
                pad = (2, 2, 2, 2),
                child = render.Box(
                    height = 1,
                    color = "#fff",
                ),
            ),
            render.Marquee(
                width = 32,
                child = render.Text(
                    content = textTwo,
                    color = "#FFFFFF",
                    font = "tb-8",
                ),
            ),
        ]
    else:
        indexes = getTopTwo(todaysCount)

        #if indexes[0].get("index")!=None: #if all values aren't zero
        average = getAverage(indexes)

        # Graphics are three layers:
        # First, sky. Based on average pollen.
        # Second, ground. Bare if grass isn't high pollen, grassy if it is.
        # Thirds, mixins. Shows trees and weeds if those are high pollen.
        skySrc = getSky(average)
        groundSrc = getGround(indexes)
        mixins = getMixins(indexes)
        if len(mixins) == 2:
            firstMixin = mixins[0]
            secondMixin = mixins[1]
        elif len(mixins) == 1:
            firstMixin = mixins[0]
        textColumn = renderColumn(indexes)

    return render.Root(
        child =
            render.Column(
                children = [
                    render.Box(
                        color = COLORS["yellow"],
                        height = 8,
                        child = render.Text(
                            content = "POLLEN COUNT",
                            font = "tb-8",
                            color = "#3D1F01",
                        ),
                    ),
                    render.Row(
                        children = [
                            render.Stack(
                                children = [
                                    render.Image(
                                        src = skySrc,
                                        width = 31,
                                        height = 24,
                                    ),
                                    render.Image(
                                        src = groundSrc,
                                        width = 31,
                                        height = 24,
                                    ),
                                    firstMixin,
                                    secondMixin,
                                    render.Padding(
                                        pad = (17, 0, 0, 0),
                                        child = render.Text(
                                            font = "tb-8",
                                            content = str(average),
                                            color = "#3D1F01",
                                        ),
                                    ),
                                ],
                            ),
                            render.Box(
                                color = COLORS["yellow"],
                                height = 24,
                                width = 2,
                            ),
                            render.Box(
                                height = 24,
                                width = 31,
                                child = render.Column(
                                    main_align = "space_between",
                                    cross_align = "center",
                                    children = textColumn,
                                ),
                            ),
                        ],
                    ),
                ],
            ),
    )

# Make API call and process data.
def getTodaysCount(lat, lng, dev_key):
    print("Getting API for: " + str(lat) + "," + str(lng) + " for " + str(3600 * 12) + " seconds")
    FULL_URL = (
        API_URL_BASE +
        str(lat) +
        "&location.longitude=" +
        str(lng) +
        "&key=" +
        dev_key
    )
    rep = http.get(FULL_URL, ttl_seconds = 3600 * 12)
    data = rep.json()

    print(rep.body())

    # Google API errors come back as { "error": { "code": ..., "message": ..., "status": ... } }
    if "error" in data:
        err = data["error"]
        return {
            "message": err.get("message", "Unknown error"),
            "code": err.get("code", 0),
            "status": err.get("status", "ERROR"),
        }

    # Parse pollenTypeInfo array into the flat dict shape the rest of the app expects:
    # { "treeIndex": N, "grassIndex": N, "weedIndex": N }
    pollenTypeInfo = data["dailyInfo"][0]["pollenTypeInfo"]
    result = {}
    for entry in pollenTypeInfo:
        code = entry["code"]
        if "indexInfo" not in entry:
            continue
        value = entry["indexInfo"]["value"]
        if code == "TREE":
            result["treeIndex"] = value
        elif code == "GRASS":
            result["grassIndex"] = value
        elif code == "WEED":
            result["weedIndex"] = value

    return result

# Get total average of pollen indexes to two decimal points.
def getAverage(indexes):
    total = 0
    for i in range(0, len(indexes)):
        total += indexes[i]["index"]
    average = float(int(total / len(indexes) * 10) / 10)
    return average

# Takes index values and turns it into a color/word pair.
def getTopTwo(indexes):
    aboveOnes = []
    for index in indexes:
        if indexes[index] > 1:
            aboveOnes.append({
                "name": getName(index),
                "index": indexes[index],
                "color": getColor(indexes[index]),
            })
    if len(aboveOnes) == 0:
        aboveOnes.append({
            "name": ":)",
            "index": 0,
            "color": COLORS["green"],
        })
    return aboveOnes

# Returns array of children to show in text column.
def renderColumn(topItems):
    layout = []
    if len(topItems) >= 1:
        layout.append(render.Text(
            content = topItems[0]["name"],
            color = topItems[0]["color"],
            font = "tb-8",
        ))
    if len(topItems) >= 2:
        layout.append(render.Padding(
            pad = (2, 2, 2, 2),
            child = render.Box(
                height = 1,
                color = "#fff",
            ),
        ))
        layout.append(render.Text(
            content = topItems[1]["name"],
            color = topItems[1]["color"],
            font = "tb-8",
        ))
    return layout

# Get color text should be based on index.
def getColor(index):
    if index >= 2 and index < 3:
        return COLORS["green"]
    elif index >= 3 and index < 4:
        return COLORS["yellow"]
    elif index >= 4:
        return COLORS["red"]
    else:
        return ""

# Get display text for index.
def getName(indexName):
    if indexName == "weedIndex":
        return "WEED"
    elif indexName == "grassIndex":
        return "GRASS"
    elif indexName == "treeIndex":
        return "TREE"
    else:
        return ""

# Returns appropriate sky image to show.
def getSky(average):
    if average < 2:
        return images["skyLowPollen"]
    elif average >= 2 and average < 3.5:
        return images["skyMedPollen"]
    elif average >= 3.5:
        return images["skyHighPollen"]
    else:
        return ""

# Returns appropriate ground image to show.
def getGround(topTwo):
    matches = False
    for i in range(0, len(topTwo)):
        if topTwo[i]["name"] == "GRASS":
            matches = True

    if matches == True:
        return images["groundGrass"]

    return images["groundBare"]

# Returns array of mixin children (weeds and trees)
def getMixins(topTwo):
    mixins = []
    for i in range(0, len(topTwo)):
        if topTwo[i]["name"] == "TREE":
            mixins.append(render.Image(src = images["trees"], width = 31, height = 24))
        elif topTwo[i]["name"] == "WEED":
            mixins.append(render.Image(src = images["weeds"], width = 31, height = 24))
    return mixins

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location required to find pollen count in your area.",
                icon = "mapLocation",
            ),
            schema.Text(
                id = "dev_key",
                name = "API Key",
                desc = "API key from Google Maps Platform (Pollen API).",
                icon = "key",
                secret = True,
            ),
        ],
    )

images = {
    "skyLowPollen": SKY_LOW_POLLEN_ASSET.readall(),
    "skyMedPollen": SKY_MED_POLLEN_ASSET.readall(),
    "skyHighPollen": SKY_HIGH_POLLEN_ASSET.readall(),
    "groundBare": GROUND_BARE_ASSET.readall(),
    "groundGrass": GROUND_GRASS_ASSET.readall(),
    "trees": TREES_ASSET.readall(),
    "weeds": WEEDS_ASSET.readall(),
}
