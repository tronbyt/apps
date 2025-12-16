"""
Applet: SF Next Muni
Summary: SF Muni arrival times
Description: Shows the predicted arrival times from 511.org for a given SF Muni stop.
Author: Martin Strauss
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_LOCATION = """
{
  "lat": "37.7844",
  "lng": "-122.4080",
	"description": "San Francisco, CA, USA",
	"locality": "San Francisco",
	"timezone": "America/Los_Angeles"
}
"""
DEFAULT_STOP = """
{
    "display":"Metro Powell Station/Outbound (#16995)",
    "value":"16995"
}
"""
PREDICTIONS_URL = "https://api.511.org/transit/StopMonitoring?format=json&api_key=%s&agency=SF&stopcode=%s"
ROUTES_URL = "https://api.511.org/transit/lines?format=json&api_key=%s&operator_id=SF"
STOPS_URL = "https://api.511.org/transit/stops?format=json&api_key=%s&operator_id=SF"
ALERTS_URL = "https://api.511.org/transit/servicealerts?format=json&api_key=%s&agency=SF"

API_KEY = None

# Colours for Muni Metro/Street Car lines
MUNI_COLORS = {
    "E": "#666666",
    "F": "#f0e68c",
    "J": "#faa634",
    "K": "#569bbe",
    "L": "#92278f",
    "M": "#008752",
    "N": "#00539b",
    "T": "#d31245",
    "S": "#ffcc00",
}

# Display the route letter in black text (#000000) inside the circle for these routes
MUNI_BLACK_TEXT = [
    "F",
    "S",
]

# Inbound stops on KT line that should display as K. If not listed stop will display as T
K_INBOUND_STOPS = [
    "17778",
    "15784",
    "15794",
    "15797",
    "15787",
    "15788",
    "15809",
    "15779",
    "15806",
    "17113",
    "17109",
    "16898",
]

# Outbound stops on KT line that should display as T. If not listed stop will display as K
T_OUTBOUND_STOPS = [
    "17398",
    "17399",
    "17400",
    "17347",
    "17343",
    "17345",
    "17401",
    "17402",
    "17403",
    "17404",
    "17352",
    "17353",
    "17354",
    "17355",
    "17356",
    "17357",
    "17358",
    "17166",
    "15237",
    "17145",
    "14510",
]

# Dictionary to define default config values when pixlet commands are run as get_schema() currently not referenced then
DEFAULT_CONFIG = {
    "route_filter": "all-routes",
    "prediction_format": "long",
}

def get_schema():
    formats = [
        schema.Option(
            display = "With destination",
            value = "xlong",
        ),
        schema.Option(
            display = "Short destination",
            value = "long",
        ),
        schema.Option(
            display = "No destination",
            value = "medium",
        ),
        schema.Option(
            display = "Compact",
            value = "short",
        ),
        schema.Option(
            display = "Two line w/destination",
            value = "two_line_dest",
        ),
        schema.Option(
            display = "Two line w/4 times",
            value = "two_line_four_times",
        ),
    ]
    scroll_speeds = [
        schema.Option(display = "Slow", value = "70"),
        schema.Option(display = "Normal (default)", value = "50"),
        schema.Option(display = "Fast", value = "30"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "511_api_key",
                name = "511.org API Key",
                desc = "A 511.org API key to access the 511.org API.",
                icon = "key",
                secret = True,
            ),
            schema.Typeahead(
                id = "stop_code",
                name = "Bus Stop",
                desc = "Search by stop name (e.g., 'Powell', 'Castro') or stop ID (e.g., '16995').",
                icon = "bus",
                handler = get_stops,
            ),
            schema.Typeahead(
                id = "route_filter",
                name = "Route Filter",
                desc = "Search by route number (e.g., '38', 'N', 'KT') or route name (e.g., 'Geary').",
                icon = "route",
                handler = get_route_filter_typeahead,
            ),
            schema.Toggle(
                id = "show_title",
                name = "Show stop title",
                desc = "A toggle to show the stop title.",
                icon = "signHanging",
                default = False,
            ),
            schema.Dropdown(
                id = "prediction_format",
                name = "Prediction format",
                desc = "Select the format of the prediction text.",
                icon = "borderAll",
                default = "long",
                options = formats,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Scroll Speed",
                desc = "Change the speed that text scrolls.",
                icon = "gear",
                default = "50",
                options = scroll_speeds,
            ),
            schema.Toggle(
                id = "agency_alerts",
                name = "Show agency-wide service alerts",
                desc = "Show service alerts targeted to all of SF Muni.",
                icon = "exclamation",
                default = False,
            ),
            schema.Toggle(
                id = "route_alerts",
                name = "Show route-specific service alerts",
                desc = "Show service alerts targeted to the routes at the selected stop.",
                icon = "exclamation",
                default = False,
            ),
            schema.Toggle(
                id = "stop_alerts",
                name = "Show stop-specific service alerts",
                desc = "Show service alerts targeted to the selected stop.",
                icon = "exclamation",
                default = False,
            ),
            schema.Text(
                id = "alert_languages",
                name = "Service alert langauges",
                desc = "Languages to show service alerts in, separated by commas.",
                icon = "flag",
                default = "en",
            ),
            schema.Text(
                id = "minimum_time",
                name = "Minimum time to show",
                desc = "Don't show predictions nearer than this minimum.",
                icon = "clock",
                default = "0",
            ),
        ],
    )

def fetch_stops(api_key):
    stops = {}

    raw_stops = fetch_cached(STOPS_URL % api_key, 86400)

    if type(raw_stops) != "string" and "Contents" in raw_stops:
        stops.update([(stop["id"], stop) for stop in raw_stops["Contents"]["dataObjects"]["ScheduledStopPoint"]])
        print("[DEBUG] Loaded %d stop(s) from API" % len(stops))
    else:
        print("[ERROR] Failed to load stops from API")

    return stops

def get_stops(pattern, config):
    api_key = config.get("511_api_key")
    if not api_key:
        return [schema.Option(display = "API key not set", value = json.encode({"display": "API key not set", "value": ""}))]

    stops = fetch_stops(api_key)
    if not stops:
        return [schema.Option(display = "No stops found", value = json.encode({"display": "No stops found", "value": ""}))]

    # Convert pattern to string, handling None
    search_pattern = pattern if pattern != None else ""

    # Filter stops based on the search pattern
    if search_pattern:
        filtered_stops = [
            stop
            for stop in stops.values()
            if search_pattern.lower() in stop["Name"].lower() or search_pattern in stop["id"]
        ]

        # Limit search results
        filtered_stops = sorted(filtered_stops, key = lambda stop: stop["Name"])[:100]
    else:
        # Return first 100 stops when no pattern, sorted alphabetically
        filtered_stops = sorted(stops.values(), key = lambda stop: stop["Name"])[:100]

    options = [
        schema.Option(
            display = "%s (#%s)" % (stop["Name"], stop["id"]),
            value = json.encode({"display": "%s (#%s)" % (stop["Name"], stop["id"]), "value": stop["id"]}),
        )
        for stop in filtered_stops
    ]

    # If no options found, provide a helpful message
    if not options:
        return [schema.Option(display = "No matching stops", value = json.encode({"display": "No matching stops", "value": ""}))]

    return options

def get_route_filter_typeahead(pattern, config):
    """Handler for the route filter typeahead field."""
    api_key = config.get("511_api_key")
    if not api_key:
        return [schema.Option(display = "All Routes (API key not set)", value = "all-routes")]

    routes = fetch_cached(ROUTES_URL % api_key, 86400)
    if type(routes) == "string" or not routes:
        return [schema.Option(display = "All Routes", value = "all-routes")]

    # Always include "All Routes" option
    route_options = [schema.Option(display = "All Routes", value = "all-routes")]

    # Convert pattern to string, handling None
    search_pattern = pattern if pattern != None else ""

    # Filter routes based on search pattern
    if search_pattern:
        filtered_routes = [
            route
            for route in routes
            if search_pattern.lower() in route["Id"].lower() or search_pattern.lower() in route["Name"].lower()
        ]
    else:
        # Show all routes when no pattern
        filtered_routes = routes

    # Add filtered routes
    route_options.extend([
        schema.Option(
            display = "%s %s" % (route["Id"], route["Name"]),
            value = route["Id"],
        )
        for route in filtered_routes
    ])

    return route_options

def get_route_filter(api_key):
    """Handler for the Generated route_filter field."""
    return [
        schema.Dropdown(
            id = "route_filter",
            name = "Route Filter",
            desc = "Filter to only display one route",
            icon = "route",
            default = "all-routes",
            options = get_route_list(api_key),
        ),
    ]

# Function to get the available route list for route filter selection. Additionally adds 'all-routes' option to the beginning of the list
def get_route_list(api_key = None):
    if not api_key:
        return [
            schema.Option(
                display = "All Routes",
                value = "all-routes",
            ),
        ]

    routes = fetch_cached(ROUTES_URL % api_key, 86400)
    if type(routes) == "string":
        # Return default option on error instead of empty list
        return [
            schema.Option(
                display = "All Routes",
                value = "all-routes",
            ),
        ]

    route_list = [
        schema.Option(
            display = "%s %s" % (route["Id"], route["Name"]),
            value = route["Id"],
        )
        for route in routes
    ]
    route_list.insert(
        0,
        schema.Option(
            display = "All Routes",
            value = "all-routes",
        ),
    )
    return route_list

def square_distance(lat1, lon1, lat2, lon2):
    latitude_difference = int((float(lat2) - float(lat1)) * 10000)
    longitude_difference = int((float(lon2) - float(lon1)) * 10000)
    return latitude_difference * latitude_difference + longitude_difference * longitude_difference

def fetch_cached(url, ttl):
    res = http.get(url, ttl_seconds = ttl)
    if res.status_code != 200:
        print("[ERROR] 511.org API request failed - URL: %s | Status: %d" % (sanitize(url), res.status_code))
        return res.body().lstrip("\ufeff")

    # Trim off the UTF-8 byte-order mark
    body = res.body().lstrip("\ufeff")
    data = json.decode(body)

    return data

def higher_priority_than(pri, threshold):
    return threshold == "Low" or pri == "High" or threshold == pri

def main(config):
    print("[INFO] ========== SF Next Muni App Starting ==========")
    api_key = config.get("511_api_key")
    if not api_key:
        print("[ERROR] No 511.org API Key provided")
        return render.Root(
            child = render.Text("No 511.org API Key provided.", font = "tom-thumb"),
        )

    # Get the stop configuration
    stop_code = config.get("stop_code")
    if not stop_code:
        # If no stop is selected, use the default stop
        stop = json.decode(DEFAULT_STOP)
        print("[DEBUG] Using default stop")
    else:
        stop = json.decode(stop_code)

    # Extract stopId and handle double-encoding
    stopId = stop["value"]
    if type(stopId) == "string" and stopId.startswith("{"):
        nested = json.decode(stopId)
        if type(nested) == "dict" and "value" in nested:
            stopId = nested["value"]

    ## Fetch and parse predictions
    (stopTitle, routes, predictions) = getPredictions(api_key, config, stop)

    ## Fetch, parse and filter service messages
    messages = getMessages(api_key, config, routes, stopId)

    ## Render the title, predictions and messages
    print("[INFO] Rendering output with %d prediction(s) and %d message(s)" % (len(predictions), len(messages)))
    print("[INFO] ========== SF Next Muni App Finished ==========")
    return renderOutput(stopTitle, predictions, messages, config)

def getPredictions(api_key, config, stop):
    # Handle cases where stop["value"] might be a nested JSON string
    stopId = stop["value"]

    # If stopId looks like a JSON string, decode it to get the actual ID
    if type(stopId) == "string" and stopId.startswith("{"):
        nested = json.decode(stopId)
        if type(nested) == "dict" and "value" in nested:
            stopId = nested["value"]

    stopTitle = stop["display"]
    print("[DEBUG] Fetching predictions for stop: %s (ID: %s)" % (stopTitle, stopId))
    data = fetch_cached(PREDICTIONS_URL % (api_key, stopId), 240)
    if type(data) == "string":
        print("[ERROR] Failed to fetch predictions - API returned error: %s" % data)
        return (data, [], [])

    route_filter = config.get("route_filter", DEFAULT_CONFIG["route_filter"])
    if not route_filter:
        route_filter = "all-routes"

    # Handle double-encoded route filter (same issue as stopId)
    if type(route_filter) == "string" and route_filter.startswith("{"):
        nested = json.decode(route_filter)
        if type(nested) == "dict" and "value" in nested:
            route_filter = nested["value"]

    print("[DEBUG] Route filter: %s | Minimum time: %s min" % (route_filter, config.str("minimum_time", "0")))

    minimum_time_string = config.str("minimum_time", "0")
    minimum_time = int(minimum_time_string) if minimum_time_string.isdigit() else 0
    prediction_map = {}
    routes = []
    stops = fetch_stops(api_key)
    if stopId in stops:
        stopTitle = stops[stopId]["Name"]

    # Parse Stop Monitoring API response
    service_delivery = data.get("ServiceDelivery", {})
    if not service_delivery:
        print("[WARNING] No ServiceDelivery found in API response for stop: %s" % stopId)
        return (stopTitle, [], [])

    stop_monitoring = service_delivery.get("StopMonitoringDelivery", {})
    if not stop_monitoring:
        print("[WARNING] No StopMonitoringDelivery found in API response for stop: %s" % stopId)
        return (stopTitle, [], [])

    monitored_stops = stop_monitoring.get("MonitoredStopVisit", [])
    if not monitored_stops:
        print("[WARNING] No MonitoredStopVisit entries found for stop: %s" % stopId)
        return (stopTitle, [], [])

    response_timestamp = service_delivery.get("ResponseTimestamp", "")
    current_time = time.now()

    for visit in monitored_stops:
        journey = visit.get("MonitoredVehicleJourney", {})
        if not journey:
            continue

        routeTag = journey.get("LineRef", "")
        if not routeTag:
            continue

        # Apply route filter
        if route_filter != "all-routes" and routeTag != route_filter:
            continue

        if routeTag not in routes:
            routes.append(routeTag)

        destTitle = journey.get("DestinationName", "")
        direction_ref = journey.get("DirectionRef", "")

        # Hack for KT interlining
        if routeTag == "KT":
            kt_override_stops = {}
            for stop_kt in K_INBOUND_STOPS:
                kt_override_stops[stop_kt] = "K"
            for stop_t in T_OUTBOUND_STOPS:
                kt_override_stops[stop_t] = "T"
            # DirectionRef: "IB" = inbound (0), "OB" = outbound (1)
            routeTag = kt_override_stops.get(stopId, "T" if direction_ref == "OB" else "K")

        # Get arrival time from MonitoredCall
        monitored_call = journey.get("MonitoredCall", {})
        if not monitored_call:
            continue

        expected_arrival = monitored_call.get("ExpectedArrivalTime", "")
        if not expected_arrival:
            expected_arrival = monitored_call.get("AimedArrivalTime", "")
        if not expected_arrival:
            continue

        # Parse ISO 8601 timestamp and calculate minutes until arrival
        arrival_time = time.parse_time(expected_arrival)
        seconds = arrival_time.unix - current_time.unix
        minutes = int(seconds / 60)

        # Skip if less than minimum time
        if minutes < minimum_time:
            continue

        titleKey = (routeTag, routeTag) if config.get("prediction_format") in ("short", "medium", "two_line_four_times") else (routeTag, destTitle)
        if titleKey not in prediction_map:
            prediction_map[titleKey] = []

        prediction_map[titleKey].append(minutes)

    output_map = {}
    for key in prediction_map:
        output_map[key] = [str(prediction) for prediction in sorted(prediction_map[key])]

    output = sorted(output_map.items(), key = lambda kv: int(min(kv[1], key = int))) if output_map.items() else []

    if not output:
        print("[WARNING] No predictions found for stop: %s | Route filter: %s | Routes found: %s" % (stopId, route_filter, ", ".join(routes) if routes else "none"))
    else:
        print("[DEBUG] Found %d prediction(s) for stop: %s" % (len(output), stopId))

    return (stopTitle, routes, output)

def getMessages(api_key, config, routes, stopId):
    print("[DEBUG] Fetching service alerts for stop: %s" % stopId)
    data = fetch_cached(ALERTS_URL % api_key, 240)
    if type(data) == "string":
        print("[ERROR] Failed to fetch alerts - API returned error: %s" % data)
        return [data]

    # https://developers.google.com/transit/gtfs-realtime/reference#message-feedentity
    entities = data.get("Entities")

    messages = []

    if not entities:
        print("[DEBUG] No alert entities found")
        return messages

    for entry in entities:
        # https://developers.google.com/transit/gtfs-realtime/reference#message-alert
        alert = entry["Alert"]
        if not alert:
            continue

        translations = [translation["Text"] for translation in alert["HeaderText"]["Translations"] if translation["Language"] == "en"]

        if not translations:
            continue

        # https://developers.google.com/transit/gtfs-realtime/reference#message-entityselector
        informedAgencies = [entity["AgencyId"] for entity in alert["InformedEntities"] if "AgencyId" in entity]
        informedRoutes = [entity["RouteId"] for entity in alert["InformedEntities"] if "RouteId" in entity]
        informedStops = [entity["StopId"] for entity in alert["InformedEntities"] if "StopId" in entity]
        if ((config.bool("agency_alerts") and "SF" in informedAgencies) or
            (config.bool("route_alerts") and [route for route in informedRoutes if route in routes]) or
            (config.bool("stop_alerts") and stopId in informedStops)):
            messages.extend(translations)

    print("[DEBUG] Found %d service alert(s)" % len(messages))
    return messages

def sanitize(txt):
    return txt.replace(API_KEY, "API_KEY") if API_KEY else txt

def renderOutput(stopTitle, output, messages, config):
    lines = 4
    height = 32

    if config.bool("show_title"):
        lines = lines - 1
        height = height - 9
    if messages:
        lines = lines - 1
        height = height - 8

    rows = []
    if config.bool("show_title"):
        rows.append(
            render.Column(
                children = [
                    render.Marquee(
                        width = 64,
                        child = render.Text(sanitize(stopTitle)),
                    ),
                    render.Box(
                        width = 64,
                        height = 1,
                        color = "#FFF",
                    ),
                ],
                main_align = "start",
            ),
        )

    predictionLines = []

    if "short" == config.get("prediction_format"):
        predictionLines = shortPredictions(output, lines)
    else:
        predictionLines = longRows(output[:lines], config)

    # If no predictions, show a message instead of a blank screen
    if not predictionLines:
        predictionLines = [
            render.Box(
                child = render.WrappedText(
                    content = "No arrivals",
                    font = "tom-thumb",
                ),
            ),
        ]

    rows.append(
        render.Box(
            height = height,
            padding = 0,
            child = render.Column(
                children = predictionLines,
                main_align = "space_evenly",
                expanded = True,
            ),
        ),
    )

    if messages:
        rows.append(
            render.Column(
                children = [
                    render.Padding(
                        pad = (0, 0, 0, 1),
                        child = render.Box(
                            width = 64,
                            height = 1,
                            color = "#FFF",
                        ),
                    ),
                    render.Marquee(
                        width = 64,
                        child = render.Text(sanitize("      ".join(messages)), font = "tom-thumb"),
                    ),
                ],
                main_align = "end",
            ),
        )

    return render.Root(
        delay = int(config.str("speed", "50")),  # Allow customization of scroll speed.
        show_full_animation = True,
        child = render.Column(
            children = rows,
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
        ),
    )

def calculateLength(predictions):
    return (7 +  # diameter of line circle
            4 +  # leading space
            4 * len(",".join(predictions[:2])) +
            4)  # trailing space

def shortPredictions(output, lines):
    predictionLengths = [calculateLength(predictions) for (routeTag, predictions) in output]

    rows = []
    for _ in range(lines):
        row = []
        cumulativeLength = 0
        for length in predictionLengths:
            cumulativeLength = cumulativeLength + length
            if (cumulativeLength - 4 > 64 or not output):
                break
            row.append(output.pop(0))
        if (row):
            rows.append(row)

    padding = 2
    horizontalMargin = []

    if len(rows) == lines:
        padding = 0
        horizontalMargin = [render.Text(" ")]

    return [
        render.Box(
            padding = padding,
            child = render.Column(
                expanded = True,
                children = [
                    render.Row(
                        children = horizontalMargin + [
                            render.Row(
                                children = [
                                    render.Circle(
                                        child = render.Text(routeTag[0], font = "tom-thumb", color = "#000000" if routeTag[0] in MUNI_BLACK_TEXT else "#ffffff"),
                                        diameter = 7,
                                        color = MUNI_COLORS[routeTag[0]] if routeTag[0] in MUNI_COLORS else "#000000",
                                    ),
                                    render.Text(" "),
                                    render.Text(sanitize(",".join(predictions[:2])), font = "tom-thumb"),
                                    render.Text(" "),
                                ],
                                main_align = "space_around",
                                cross_align = "center",
                            )
                            for (routeTag, predictions) in row
                        ] + horizontalMargin,
                        main_align = "start",
                        cross_align = "center",
                        expanded = True,
                    )
                    for row in rows
                ],
            ),
        ),
    ]

def longRows(output, config):
    output = output[:2] if config.get("prediction_format", DEFAULT_CONFIG["prediction_format"])[:8] == "two_line" else output
    return [
        render.Row(
            children = getLongRow(routeTag, destination, predictions, config),
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
        )
        for ((routeTag, destination), predictions) in output
    ]

def getLongRow(routeTag, destination, predictions, config):
    row = []
    if routeTag in MUNI_COLORS:
        row.append(
            render.Circle(
                child = render.Text(routeTag, font = "tom-thumb" if config.get("prediction_format", DEFAULT_CONFIG["prediction_format"])[:8] != "two_line" else "", color = "#000000" if routeTag in MUNI_BLACK_TEXT else "#ffffff"),
                diameter = 7 if config.get("prediction_format", DEFAULT_CONFIG["prediction_format"])[:8] != "two_line" else 12,
                color = MUNI_COLORS[routeTag],
            ),
        )
    else:
        row.append(
            render.Text(
                routeTag + " ",
                font = "tom-thumb" if config.get("prediction_format", DEFAULT_CONFIG["prediction_format"])[:8] != "two_line" else "",
            ),
        )
    if "xlong" == config.get("prediction_format", DEFAULT_CONFIG["prediction_format"]):
        row.append(
            render.Marquee(
                child = render.Text(sanitize(destination), font = "tom-thumb"),
                width = 40,
            ),
        )
        row.append(
            render.Marquee(
                child = render.Text(sanitize((" " if len(predictions[0]) < 2 else "") + predictions[0]), font = "tom-thumb"),
                width = 10,
            ),
        )
    elif "long" == config.get("prediction_format", DEFAULT_CONFIG["prediction_format"]):
        row.append(
            render.Marquee(
                child = render.Text(sanitize(destination), font = "tom-thumb"),
                width = 30,
            ),
        )
        nextTwoPredictions = ",".join(predictions[:2])
        nextTwoPredictions = " " * (5 - len(nextTwoPredictions)) + nextTwoPredictions
        row.append(
            render.Marquee(
                child = render.Text(sanitize(nextTwoPredictions), font = "tom-thumb"),
                width = 20,
            ),
        )
    elif "two_line" == config.get("prediction_format", DEFAULT_CONFIG["prediction_format"])[:8]:
        max_width = 50
        max_predictions = 4
        if "two_line_dest" == config.get("prediction_format", DEFAULT_CONFIG["prediction_format"]):
            row.append(
                render.Marquee(
                    child = render.Text(sanitize(destination)),
                    width = 25,
                ),
            )
            max_width = max_width - 25
            max_predictions = 2

        row.append(
            render.Marquee(
                child = render.Text(sanitize(",".join([prediction for prediction in predictions[:max_predictions]]))),
                width = max_width,
            ),
        )
    else:
        row.append(
            render.Marquee(
                child = render.Text(sanitize("%s min" % " & ".join([prediction for prediction in predictions[:2]])), font = "tom-thumb"),
                width = 50,
            ),
        )

    return row
