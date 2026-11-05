"""
Applet: MBTA New Trains
Summary: Track new MBTA subway cars
Description: Displays the real time location of new subway cars in Boston's MBTA rapid transit system.
Author: joshspicer
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/img.png", IMG_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

IMG = IMG_ASSET.readall()

# MBTA New Train Tracker
#
# Copyright (c) 2022 Josh Spicer <hello@joshspicer.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

STATION_NAMES_URL = "https://traintracker.transitmatters.org/stops/Green-B,Green-C,Green-D,Green-E,Orange,Red"
TRAIN_LOCATION_URL = "https://traintracker.transitmatters.org/trains/Green-B,Green-C,Green-D,Green-E,Orange,Red-A,Red-B"

ARROW_DOWN = "⇩"
ARROW_UP = "⇧"
ARROW_RIGHT = "⇨"
ARROW_LEFT = "⇦"

RED = "#FF0000"
GREEN = "#00FF00"
ORANGE = "#FFA500"

CACHE_TTL_SECONDS = 3600 * 24  # 1 day in seconds.

# mockData = [
#     {
#         "direction": 0,
#         "stationId": "place-rugg",
#         "route": "Orange"
#         "isNewTrain": "true"
#     },
#     {
#         "direction": 0,
#         "stationId": "place-unsqu",
#         "route": "Green-E"
#         "isNewTrain": "true"
#     },
#     {
#         "direction": 1,
#         "stationId": "place-bbsta",
#         "route": "Orange",
#         "isNewTrain": "true"
#     },
#         {
#         "direction": 1,
#         "stationId": "place-davis",
#         "route": "Red-A",
#         "isNewTrain": "true"
#     },
# ]

def fetchStationNames(useCache):
    if useCache:
        res = http.get(STATION_NAMES_URL, ttl_seconds = CACHE_TTL_SECONDS)
    else:
        res = http.get(STATION_NAMES_URL)

    if res.status_code != 200:
        fail("stations request failed with status %d", res.status_code)
    cachedStations = res.body()

    stations = json.decode(cachedStations)
    map = {}
    for station in stations:
        map[station["id"]] = station["name"]

    return map

def mapStationIdToName(id):
    stations = fetchStationNames(True)
    return stations[id]

def mapRouteToColor(route, config):
    split = route.split("-")
    line = ""
    if len(split) > 1:
        line = split[1]

    if "Red" in route and config.bool("disableRed") != True:
        return (RED, line)
    elif "Green" in route and config.bool("disableGreen") != True:
        return (GREEN, line)
    elif "Orange" in route and config.bool("disableOrange") != True:
        return (ORANGE, line)

    return None

def createTrain(loc, config):
    if loc["isNewTrain"] != True:
        return None

    routeResult = mapRouteToColor(loc["route"], config)
    if routeResult == None:
        return None
    (color, line) = routeResult

    stationName = mapStationIdToName(loc["stationId"])

    if line != "":
        stationName += " (" + line + ")"

    isGreenLine = color == "#00FF00"

    if loc["direction"] == 1:
        arrow = ARROW_RIGHT if isGreenLine else ARROW_UP
    else:
        arrow = ARROW_LEFT if isGreenLine else ARROW_DOWN

    return render.Row(
        children = [
            render.Text(
                content = "{} ".format(arrow),
                color = color,
            ),
            render.Marquee(
                child = render.WrappedText(
                    content = stationName,
                    width = 56,
                    color = color,
                ),
                width = 64,
            ),
        ],
    )

def displayIndividualTrains(apiResult, config):
    trains = []
    for loc in apiResult:
        train = createTrain(loc, config)
        if train != None:
            trains.append(train)

    #    for mock in mockData:
    #        trains.append(createTrain(mock))

    if len(trains) == 0:
        return render.Root(
            child = render.Box(
                child = render.WrappedText(
                    content = "No New Trains Running!",
                    width = 60,
                ),
            ),
        )

    return render.Root(
        child = render.Marquee(
            child = render.Column(
                children = trains,
            ),
            scroll_direction = "vertical",
            height = 32,
            offset_start = 32,
        ),
    )

def renderDigestRow(color, count, disabled):
    if not disabled:
        return render.Padding(
            pad = (1, 1, 0, 0),
            child = render.Row(
                children = [
                    render.Circle(
                        color = color,
                        diameter = 9,
                        child = render.Text(
                            content = "T",
                            font = "Dina_r400-6",
                        ),
                    ),
                    render.Padding(
                        pad = (4, 1, 0, 0),
                        child = render.Text(
                            content = "{} ".format(count),
                        ),
                    ),
                ],
            ),
        )
    else:
        return None

def displayDigest(apiResult, config):
    r = 0
    g = 0
    o = 0
    for loc in apiResult:
        if loc["isNewTrain"] != True:
            continue
        route = loc["route"]
        if "Red" in route:
            r += 1
        elif "Green" in route:
            g += 1
        elif "Orange" in route:
            o += 1

    return render.Root(
        render.Row(
            children = [
                render.Column(
                    children = [
                        renderDigestRow(RED, r, config.bool("disableRed")),
                        renderDigestRow(GREEN, g, config.bool("disableGreen")),
                        renderDigestRow(ORANGE, o, config.bool("disableOrange")),
                    ],
                ),
                render.Padding(
                    pad = (6, 1, 0, 0),
                    child = render.Image(
                        src = IMG,
                        width = 36,
                        height = 30,
                    ),
                ),
            ],
        ),
    )

def main(config):
    res = http.get(TRAIN_LOCATION_URL)
    if res.status_code != 200:
        return render.Root(
            child = render.WrappedText("Location request failed with status %d" % res.status_code),
        )

    apiResult = res.json()

    if config.bool("showLiveLocations"):
        return displayIndividualTrains(apiResult, config)
    else:
        return displayDigest(apiResult, config)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "showLiveLocations",
                name = "Show Live Locations",
                desc = "Shows live location of new trains in a scrolling marquee.  If disabled, only the count of new trains running will be displayed.",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "disableRed",
                name = "Hide Red Line Trains",
                desc = "If enabled, new trains on the red line will be hidden.",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "disableGreen",
                name = "Hide Green Line Trains",
                desc = "If enabled, new trains on the green line will be hidden.",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "disableOrange",
                name = "Hide Orange Line Trains",
                desc = "If enabled, new trains on the orange line will be hidden.",
                icon = "gear",
                default = False,
            ),
        ],
    )
