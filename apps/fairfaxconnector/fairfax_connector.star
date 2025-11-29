"""
Applet: Fairfax Connector
Summary: Connector bus stop info
Description: Shows when your next bus is arriving. Visit fairfaxconnector.com for more information.
Author: Austin Pearce
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/bus_stop_picture.png", BUS_STOP_PICTURE_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

BUS_STOP_PICTURE = BUS_STOP_PICTURE_ASSET.readall()

ONE_MINUTE = 60
ONE_DAY = ONE_MINUTE * 60 * 24
ONE_WEEK = ONE_DAY * 7
BASE_URL = "https://www.fairfaxcounty.gov/bustime/api/v3"
DEFAULT_STOP = "6484"

def getAllRoutes(config):
    routes = cache.get("ROUTES")
    if routes == None:
        routesUrl = BASE_URL + "/getroutes?key=" + config.get("fairfax_connector_api_key") + "&format=json"
        routes = http.get(routesUrl).body()

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("ROUTES", routes, ONE_DAY)

    routes = json.decode(routes).get("bustime-response").get("routes")
    return routes

def getRouteDirections(route, config):
    cacheKey = "DIRECTIONS-" + route.get("rt")
    directions = cache.get(cacheKey)
    if directions == None:
        dirUrl = BASE_URL + "/getdirections?key=" + config.get("fairfax_connector_api_key") + "&rt=" + route.get("rt") + "&format=json"
        directions = http.get(dirUrl).body()

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(cacheKey, directions, ONE_DAY)

    directions = json.decode(directions).get("bustime-response").get("directions")
    return directions

def getStops(route, direction, config):
    cacheKey = "STOPS-" + route.get("rt") + "-" + direction.get("id")
    stops = cache.get(cacheKey)
    if stops == None:
        stopsUrl = BASE_URL + "/getstops?key=" + config.get("fairfax_connector_api_key") + "&rt=" + route.get("rt") + "&dir=" + direction.get("id") + "&format=json"

        # Some of the directions have spaces in their IDs. Why this is allowed, I have no clue. I can't seem to find a starlark lib
        # for URL encoding, so I'm doing this one-off here where it's needed.
        stopsUrl = stopsUrl.replace(" ", "%20")
        stops = http.get(stopsUrl).body()

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(cacheKey, stops, ONE_DAY)

    stops = json.decode(stops).get("bustime-response").get("stops")
    return stops

# Warning: Expensive operation! Sends a lot of network requests the first time it's called
# before the cache is filled up (and again every 24h when the cache expires).
def getAllStops(config):
    allStops = []
    routes = getAllRoutes(config)
    for route in routes:
        directions = getRouteDirections(route, config)
        for direction in directions:
            stops = getStops(route, direction, config)
            if stops == None:
                continue
            for stop in stops:
                allStops.append([route, stop])

    return allStops

def getRouteColor(routeId, config):
    routeColor = cache.get("COLOR-" + routeId)
    if routeColor == None:
        routes = getAllRoutes(config)

        # Find the matching route and extract its color
        for route in routes:
            if route["rt"] == routeId:
                routeColor = route["rtclr"]

                # TODO: Determine if this cache call can be converted to the new HTTP cache.
                cache.set("COLOR-" + routeId, routeColor, ONE_WEEK)
                break
    return routeColor or "#ffffff"

# Gets the list of predicted bus times for an individual bus stop
def getPredictions(stopId, config):
    stopPredictions = cache.get(stopId)
    if stopPredictions == None:
        predictionUrl = BASE_URL + "/getpredictions?key=" + config.get("fairfax_connector_api_key") + "&stpid=" + stopId + "&format=json"
        stopPredictions = http.get(predictionUrl).body()

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(stopId, stopPredictions, ONE_MINUTE)

    stopPredictions = json.decode(stopPredictions).get("bustime-response")
    if (stopPredictions.get("error") != None):
        if (len(stopPredictions.get("error")) > 0 and stopPredictions.get("error")[0].get("msg") == "No arrival times"):
            return []
        else:
            return None
    return stopPredictions.get("prd")

def renderBusRow(prediction, config):
    routeColor = getRouteColor(prediction.get("rt"), config)
    if prediction == None:
        return render.Text("")
    minutesRemaining = prediction.get("prdctdn")
    if minutesRemaining != "DUE":
        minutesRemaining = minutesRemaining + " min"
    return render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            render.Text(
                content = prediction.get("rt"),
                color = routeColor,
            ),
            render.Text(
                content = minutesRemaining,
            ),
        ],
    )

def main(config):
    stop = config.get("stop") or DEFAULT_STOP
    banner = render.Row(
        children = [
            render.Text(
                content = "FFX",
                color = "#f00",
            ),
            render.Text(
                content = " Connector",
                color = "#ff0",
            ),
        ],
    )
    predictions = getPredictions(stop, config)
    if predictions == None:
        return render.Root(
            child = render.Column(
                children = [
                    banner,
                    render.Text(
                        content = "API Error",
                    ),
                ],
            ),
        )
    if len(predictions) == 0:
        return render.Root(
            child = render.Stack(
                children = [
                    render.Padding(
                        pad = (38, 5, 0, 0),
                        child = render.WrappedText(
                            content = "No Buses",
                            width = 24,
                        ),
                    ),
                    render.Image(
                        src = BUS_STOP_PICTURE,
                    ),
                ],
            ),
        )
    rows = [
        banner,
        render.Marquee(
            width = 64,
            child = render.Text(
                content = predictions[0].get("stpnm"),
                color = "#bbb",
            ),
        ),
    ]
    for prediction in predictions:
        rows.append(renderBusRow(prediction, config))
    return render.Root(
        child = render.Column(
            children = rows,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "fairfax_connector_api_key",
                name = "Fairfax Connector API Key",
                desc = "Your Fairfax Connector API key. See https://www.fairfaxcounty.gov/bustime/api/v3 for details.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "stop",
                name = "Stop ID",
                desc = "The ID of the stop, found on the bus stop sign or online at https://www.fairfaxcounty.gov/bustime/map/displaymap.jsp",
                icon = "busSimple",
            ),
        ],
    )
