"""
Applet: MBTA
Summary: MBTA departures
Description: MBTA bus and rail departure times. Updated to work with Tronbyt.
Author: marcusb, eric-pierce
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

URL = "https://api-v3.mbta.com/predictions"
STOPS_URL = "https://api-v3.mbta.com/stops"
ROUTES_URL = "https://api-v3.mbta.com/routes"

# Stop and route lists are reference data that changes on timetable boundaries,
# so they are cached hard. Predictions are deliberately not cached: the app's
# recommendedInterval is 5 minutes, so any TTL short enough to keep arrival times
# honest would expire before the next render anyway.
LOOKUP_TTL = 3600

# Only two rows fit on a 64x32 display; widget mode has room for another.
MAX_DEPARTURES = 3

# Sentinel for "do not filter by route". Schema validation rejects both an empty
# option value and an empty dropdown default, so this cannot be "".
ROUTE_ALL = "all"

API_KEY = ""

# Keyed by route id first, then by fare_class for the route families whose
# members share one badge. Routes carrying a short_name (all bus routes, and the
# Silver Line as SL1-SLW) never reach this table.
T_ABBREV = {
    "Blue": "BL",
    "Mattapan": "M",
    "Orange": "OL",
    "Red": "RL",
    "Commuter Rail": "CR",
    "Ferry": "F",
}

def main(config):
    option = config.get("stop", '{"display": "South Station", "value": "place-sstat"}')
    stop = json.decode(option)
    mintime = config.get("mintime", "0")
    api_key = (config.get("api", "") or "").strip()
    route_filter = (config.get("route", "") or "").strip()

    widgetMode = config.bool("$widget")

    params = {
        "sort": "departure_time",
        "include": "route,trip",
        "filter[stop]": stop["value"],
    }
    if route_filter != "" and route_filter != ROUTE_ALL:
        params["filter[route]"] = route_filter
    if api_key != "":
        params["api_key"] = api_key

    rep = http.get(URL, params = params)
    if rep.status_code != 200:
        return message("No data", widgetMode)

    body = rep.json()
    departures = collect_departures(body, time.now(), float(mintime))

    if not departures:
        return message("No departures", widgetMode)

    rows = []
    for departure in departures[:MAX_DEPARTURES]:
        rows.append(renderDeparture(departure, widgetMode))
        rows.append(render.Box(height = 1, width = 64, color = "#8c8c8c"))

    return render.Root(
        child = render.Column(children = rows, main_align = "start"),
    )

def collect_departures(body, now, mintime):
    """Turn an API response into a plain list of departures, newest filter first.

    Every reason a prediction is dropped lives here, and the clock is read once
    by the caller and passed in. Previously this work was split between main and
    the render function, each calling time.now() separately, so a prediction
    could satisfy one filter and fail the other across a second boundary.

    The return value is a list of plain dicts, which is what makes the behavior
    of this app testable at all: rendering depends on the live clock and a live
    feed, but this list does not.

        API response ──► index route/trip ──► per prediction:
                                               drop no departure_time
                                               drop SKIPPED / CANCELLED
                                               drop already departed
                                               drop earlier than mintime
                                             ──► [{route_id, short_name, ...}]
    """
    routes = index_by_id(body, "route")
    trips = index_by_id(body, "trip")

    departures = []
    for prediction in body["data"]:
        attrs = prediction["attributes"]

        # SKIPPED and CANCELLED trips are not going to show up. The API leaves
        # schedule_relationship null for an ordinary scheduled trip.
        if attrs["schedule_relationship"] in ("SKIPPED", "CANCELLED"):
            continue

        if not attrs["departure_time"]:
            continue

        arrival = time.parse_time(attrs["arrival_time"] or attrs["departure_time"]) - now
        if arrival.minutes < 0 or arrival.minutes < mintime:
            continue

        route = routes.get(prediction["relationships"]["route"]["data"]["id"])
        if not route:
            continue
        route_attrs = route["attributes"]

        departures.append({
            "short_name": route_attrs["short_name"] or
                          T_ABBREV.get(route["id"], "") or
                          T_ABBREV.get(route_attrs["fare_class"], ""),
            "color": "#{}".format(route_attrs["color"] or "ffc72c"),
            "text_color": "#{}".format(route_attrs["text_color"] or "000"),
            "headsign": headsign(prediction, route_attrs, trips, attrs),
            "minutes": int(arrival.minutes + 0.5),
            "status": attrs["status"] or "",
        })

    return departures

def headsign(prediction, route_attrs, trips, attrs):
    """Where this particular vehicle is going.

    The route's direction_destinations only describes the line as a whole, so at
    a stop midway along it every vehicle reads as the far terminus. Route 137 at
    Main St @ Briggs St is the clear case: consecutive buses run to Oak Grove and
    to Malden, but direction_destinations labels both "Malden Center Station".
    The per-trip headsign is the real answer; the route is the fallback for when
    a trip is missing from the response's included section.
    """
    trip_ref = prediction["relationships"].get("trip", {}).get("data")
    if trip_ref:
        trip = trips.get(trip_ref["id"])
        if trip and trip["attributes"]["headsign"]:
            return trip["attributes"]["headsign"].upper()

    destinations = route_attrs["direction_destinations"]
    direction = int(attrs["direction_id"])
    if destinations and direction < len(destinations) and destinations[direction]:
        return destinations[direction].upper()
    return ""

def index_by_id(body, type_name):
    """Index the response's included section once, instead of scanning per row."""
    indexed = {}
    for item in body.get("included", []):
        if item["type"] == type_name:
            indexed[item["id"]] = item
    return indexed

def message(text, widgetMode):
    return render.Root(
        child = render.Marquee(
            width = 64,
            child = render.Text(
                content = text,
                height = 8,
                offset = -1,
                font = "Dina_r400-6",
            ),
        ) if not widgetMode else render.WrappedText(
            content = text,
            width = 62,
            font = "Dina_r400-6",
        ),
    )

def renderDeparture(departure, widgetMode = False):
    msg = "{} min".format(departure["minutes"]) if departure["minutes"] else "Now"

    if departure["status"]:
        first_line = render.Row(
            children = [
                render.Text(
                    content = departure["headsign"] + " · ",
                    height = 8,
                    offset = -1,
                    font = "Dina_r400-6",
                ),
                render.Text(
                    content = departure["status"],
                    height = 8,
                    offset = -1,
                    font = "Dina_r400-6",
                    color = "#df000f",
                ),
            ],
        )
    else:
        first_line = render.Text(
            content = departure["headsign"],
            height = 8,
            offset = -1,
            font = "Dina_r400-6",
        )

    headsign_widget = render.Marquee(
        width = 50,
        child = first_line,
    ) if not widgetMode else render.Row(
        expanded = True,
        main_align = "start",
        children = [
            first_line,
        ],
    )

    short_name = departure["short_name"]
    return render.Row(
        main_align = "space_between",
        children = [
            render.Stack(
                children = [
                    render.Circle(
                        diameter = 12,
                        color = departure["color"],
                        child = render.Text(
                            content = short_name,
                            color = departure["text_color"],
                            font = "CG-pixel-3x5-mono" if len(short_name) > 2 else "tb-8",
                        ),
                    ),
                ],
            ),
            render.Box(width = 2, height = 5),
            render.Column(
                main_align = "start",
                cross_align = "left",
                children = [
                    headsign_widget,
                    render.Text(
                        content = msg,
                        height = 8,
                        offset = -1,
                        font = "Dina_r400-6",
                        color = "#ffd11a",
                    ),
                ],
            ),
        ],
        cross_align = "center",
    )

def get_stops(location):
    loc = json.decode(location)

    # The location object reaches this handler two ways, and they disagree on
    # type. A fresh pick in the location search box yields strings, matching the
    # documented schema. A location restored from the device record yields JSON
    # numbers, because the server stores the coordinates as floats. http.get
    # rejects non-string params, so the second path used to abort the handler and
    # surface in the UI as "Error loading options" with no way to recover.
    lat = loc.get("lat")
    lng = loc.get("lng")
    if lat == None or lng == None or lat == "" or lng == "":
        return []

    params = {
        "page[limit]": "100",
        "filter[latitude]": str(lat),
        "filter[longitude]": str(lng),
        "sort": "distance",
    }

    rep = http.get(STOPS_URL, params = params, ttl_seconds = LOOKUP_TTL)
    if rep.status_code != 200:
        # Returning no options leaves the picker empty but retryable. Failing
        # hard here is indistinguishable, to the user, from a broken app, and
        # keyless clients are throttled at 20 requests/minute so a non-200 is
        # reachable from the settings screen alone.
        return []
    data = rep.json()
    stops = []
    for s in data["data"]:
        if s["type"] != "stop":
            continue
        if s["relationships"]["parent_station"]["data"]:
            continue
        stops.append(schema.Option(
            display = s["attributes"]["name"],
            value = s["id"],
        ))
    return stops

def get_route_field(stop_option):
    """Offer a route filter, but only where one would do something.

    Most bus stops are served by a single route in a single direction, and there
    the filter is a control that cannot change the display. It is only offered
    once the chosen stop actually has more than one route to choose between.
    """
    if not stop_option:
        return []

    stop = json.decode(stop_option)
    stop_id = stop.get("value", "")
    if not stop_id:
        return []

    rep = http.get(
        ROUTES_URL,
        params = {"filter[stop]": stop_id},
        ttl_seconds = LOOKUP_TTL,
    )
    if rep.status_code != 200:
        return []

    options = []
    for route in rep.json()["data"]:
        attrs = route["attributes"]
        options.append(schema.Option(
            display = attrs["short_name"] or attrs["long_name"] or route["id"],
            value = route["id"],
        ))

    if len(options) < 2:
        return []

    return [
        schema.Dropdown(
            id = "route",
            name = "Route",
            desc = "Show only one of the routes serving this stop.",
            icon = "bus",
            default = ROUTE_ALL,
            options = [schema.Option(display = "All routes", value = ROUTE_ALL)] + options,
        ),
    ]

def get_schema():
    options = [
        schema.Option(display = "0 minutes", value = "0"),
        schema.Option(display = "1 minutes", value = "1"),
        schema.Option(display = "2 minutes", value = "2"),
        schema.Option(display = "3 minutes", value = "3"),
        schema.Option(display = "4 minutes", value = "4"),
        schema.Option(display = "5 minutes", value = "5"),
        schema.Option(display = "6 minutes", value = "6"),
        schema.Option(display = "7 minutes", value = "7"),
        schema.Option(display = "8 minutes", value = "8"),
        schema.Option(display = "9 minutes", value = "9"),
        schema.Option(display = "10 minutes", value = "10"),
        schema.Option(display = "15 minutes", value = "15"),
        schema.Option(display = "20 minutes", value = "20"),
        schema.Option(display = "25 minutes", value = "25"),
        schema.Option(display = "30 minutes", value = "30"),
        schema.Option(display = "45 minutes", value = "45"),
        schema.Option(display = "60 minutes", value = "60"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "stop",
                name = "Stop",
                desc = "The stop or station name.",
                icon = "bus",
                handler = get_stops,
            ),
            schema.Generated(
                id = "route_generated",
                source = "stop",
                handler = get_route_field,
            ),
            schema.Dropdown(
                id = "mintime",
                name = "Show arriving in",
                desc = "Minimum arrival time.",
                icon = "bus",
                default = options[0].value,
                options = options,
            ),
            schema.Text(
                id = "api",
                name = "MBTA v3 API Key",
                desc = "Go to https://www.mbta.com/developers/v3-api, sign up for a free account and enter your API key here. Limited to 1000 requests per minute",
                icon = "gear",
                secret = True,
            ),
        ],
    )
