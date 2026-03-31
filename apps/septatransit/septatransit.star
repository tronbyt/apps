"""
Applet: SEPTA Transit
Summary: SEPTA Transit Departures
Description: Displays departure times for SEPTA buses, trolleys, and MFL/BSL in and around Philadelphia.
Author: radiocolin
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

API_BASE = "http://www3.septa.org/api"
API_ROUTES = API_BASE + "/Routes/"
API_STOPS = API_BASE + "/Stops/"
API_SCHEDULE = API_BASE + "/BusSchedules/index.php"
DEFAULT_ROUTE = "17"
DEFAULT_STOP = "10264"
DEFAULT_BANNER = ""

def call_routes_api():
    cached = cache.get("routes")
    if cached != None:
        return sort_routes(json.decode(cached))
    routes = []
    for attempt in range(10):
        if len(routes) > 0:
            break
        r = http.get(API_ROUTES, params = {"_": str(attempt)})
        body = r.body()
        if body != None and body.startswith("["):
            routes = json.decode(body)
    if len(routes) > 0:
        cache.set("routes", json.encode(routes), ttl_seconds = 604800)
    return sort_routes(routes)

def sort_routes(routes):
    numerical_routes = []
    non_numerical_routes = []

    for route in routes:
        if route["route_short_name"].isdigit():
            numerical_routes.append(route)
        else:
            non_numerical_routes.append(route)

    numerical_routes = sorted(numerical_routes, key = lambda x: int(x["route_short_name"]))
    return numerical_routes + non_numerical_routes

def get_routes():
    routes = call_routes_api()
    list_of_routes = []

    for i in routes:
        if i["route_type"] != "2":
            list_of_routes.append(
                schema.Option(
                    display = i["route_short_name"] + ": " + i["route_long_name"],
                    value = i["route_id"],
                ),
            )

    return list_of_routes

def get_route_name(route):
    routes = call_routes_api()
    for i in routes:
        if i["route_id"] == route:
            return i["route_short_name"] + ": " + i["route_long_name"]
    return ""

def get_route_bg_color(route):
    routes = call_routes_api()
    for i in routes:
        if i["route_id"] == route:
            return i["route_color"]
    return "#000"

def get_route_icon(route):
    routes = call_routes_api()
    for i in routes:
        if i["route_id"] == route:
            if i["route_type"] == "0":
                return "trainTram"
            if i["route_type"] == "1":
                return "trainSubway"
            if i["route_type"] == "3":
                return "bus"
    return "question"

def get_route_text_color(route):
    routes = call_routes_api()
    for i in routes:
        if i["route_id"] == route:
            return i["route_text_color"]
    return "#fff"

def fetch_stops(route):
    cache_key = "stops_" + route
    cached = cache.get(cache_key)
    if cached != None:
        return json.decode(cached)
    stops = []
    for attempt in range(10):
        if len(stops) > 0:
            break
        r = http.get(API_STOPS, params = {"req1": route, "_": str(attempt)})
        body = r.body()
        if body != None and body.startswith("["):
            stops = json.decode(body)
    if len(stops) > 0:
        cache.set(cache_key, json.encode(stops), ttl_seconds = 604800)
    return stops

def sort_stops_geographically(stops):
    if len(stops) <= 1:
        return stops
    lats = [float(s["lat"]) for s in stops]
    lngs = [float(s["lng"]) for s in stops]
    if max(lngs) - min(lngs) > max(lats) - min(lats):
        return sorted(stops, key = lambda s: float(s["lng"]))
    else:
        return sorted(stops, key = lambda s: float(s["lat"]))

def stop_direction(dlat, dlng):
    # In the US, buses stop on the right side of the road.
    # A stop's position relative to the intersection center reveals travel direction:
    #   East side (lng+) = NB,  West side (lng-) = SB
    #   North side (lat+) = WB, South side (lat-) = EB
    # Use whichever axis dominates to pick the label.
    if abs(dlng) >= abs(dlat):
        return "NB" if dlng > 0 else "SB"
    else:
        return "WB" if dlat > 0 else "EB"

def direction_labels(stops):
    name_groups = {}
    for s in stops:
        name = s["stopname"]
        if name not in name_groups:
            name_groups[name] = []
        name_groups[name].append(s)
    labels = {}
    for name in name_groups:
        group = name_groups[name]
        if len(group) < 2:
            continue
        total_lat = 0.0
        total_lng = 0.0
        for s in group:
            total_lat += float(s["lat"])
            total_lng += float(s["lng"])
        center_lat = total_lat / len(group)
        center_lng = total_lng / len(group)
        for s in group:
            dlat = float(s["lat"]) - center_lat
            dlng = float(s["lng"]) - center_lng
            labels[s["stopid"]] = stop_direction(dlat, dlng)
    return labels

def get_stops(route):
    stops = sort_stops_geographically(fetch_stops(route))
    labels = direction_labels(stops)
    return [
        schema.Option(
            display = i["stopname"].replace("&amp;", "&") + " (" + (labels[i["stopid"]] + ", " if i["stopid"] in labels else "") + i["stopid"] + ")",
            value = i["stopid"],
        )
        for i in stops
    ]

def call_schedule_api(route, stopid):
    cache_string = cache.get(route + "_" + stopid + "_" + "schedule_api_response")
    schedule = None
    if cache_string != None:
        schedule = json.decode(cache_string)
    if schedule == None:
        best_schedule = None
        best_expiry = None
        for attempt in range(8):
            r = http.get(API_SCHEDULE, params = {"stop_id": stopid, "_": str(attempt)})
            body = r.body()
            if body == None or body.startswith('{"error"') or not (body.startswith("{") or body.startswith("[")):
                continue
            candidate = json.decode(body)
            if type(candidate) != "dict" or not candidate.get(route) or len(candidate.get(route)) == 0:
                continue

            # SEPTA API often returns stale data. We check if at least one trip is "recent".
            # We allow trips up to 10 minutes in the past to account for late vehicles
            # and slight clock skews.
            now = time.now()
            trips = candidate[route]
            has_recent_trip = False
            first_future_expiry = None

            for t in trips:
                t_time = time.parse_time(t["DateCalender"], "01/02/06 03:04 pm", "America/New_York")
                diff = int((t_time - now).seconds)
                if diff > -600:  # -10 minutes
                    has_recent_trip = True
                    if first_future_expiry == None or (diff > 0 and diff < first_future_expiry):
                        first_future_expiry = diff

            if not has_recent_trip:
                continue  # All trips are too far in the past, likely stale data.

            # If we don't have any future trips yet, but we have recent past ones,
            # use a small expiry to check again soon.
            candidate_expiry = first_future_expiry if first_future_expiry != None else 60

            if best_expiry == None or candidate_expiry < best_expiry:
                best_expiry = candidate_expiry
                best_schedule = candidate

            # If we found a trip in the near future, we can stop retrying.
            if best_expiry > 0 and best_expiry < 1800:
                break

        if best_schedule == None:
            return {}
        schedule = best_schedule
        expiry = best_expiry if (best_expiry != None and best_expiry > 30) else 30
        if expiry > 3600:
            expiry = 3600
        cache.set(route + "_" + stopid + "_" + "schedule_api_response", json.encode(schedule), ttl_seconds = expiry)
    return schedule

def get_schedule(route, stopid, show_relative_times):
    schedule = call_schedule_api(route, stopid)
    list_of_departures = []
    if type(schedule) == "dict" and schedule.get(route):
        now = time.now()
        for i in schedule.get(route):
            departure_time = None

            # Parse time for filtering and relative display
            departure = time.parse_time(i["DateCalender"], "01/02/06 03:04 pm", "America/New_York")
            diff_seconds = int((departure - now).seconds)

            # Filter out trips that are more than 10 minutes in the past
            if diff_seconds < -600:
                continue

            if len(list_of_departures) % 2 == 1:
                background = "#222"
                text = "#fff"
            else:
                background = "#000"
                text = "#ffc72c"

            if show_relative_times:
                departure_time = str(int(diff_seconds / 60)) + "m"
                if len(departure_time) == 2:
                    departure_time = "0" + departure_time
            elif len(i["date"]) == 5:
                departure_time = " " + i["date"]
            else:
                departure_time = i["date"]

            item = render.Box(
                height = 6,
                width = 64,
                color = background,
                child = render.Row(
                    cross_align = "right",
                    children = [
                        render.Box(
                            width = 25,
                            child = render.Text(
                                departure_time,
                                font = "tom-thumb",
                                color = text,
                            ),
                        ),
                        render.Marquee(
                            child = render.Text(
                                i["DirectionDesc"],
                                font = "tom-thumb",
                                color = text,
                            ),
                            width = 39,
                            offset_start = 40,
                            offset_end = 40,
                        ),
                    ],
                ),
            )
            list_of_departures.append(item)

    if len(list_of_departures) < 1:
        msg = "No departures" if stopid else "Select a stop"
        return [render.Box(
            height = 6,
            width = 64,
            color = "#000",
            child = render.Text(msg, font = "tom-thumb"),
        )]
    else:
        return list_of_departures

def select_stop(route):
    stops_data = sort_stops_geographically(fetch_stops(route))
    if len(stops_data) == 0:
        return []
    options = get_stops(route)
    return [
        schema.Dropdown(
            id = "stop",
            name = "Stop",
            desc = "Select a stop. If a single stop is served by two directions, the same name will be listed twice, with a different stop number for each direction.",
            icon = get_route_icon(route),
            default = stops_data[0]["stopid"],
            options = options,
        ),
    ]

def main(config):
    route = config.str("route", DEFAULT_ROUTE)
    stop = config.str("stop", DEFAULT_STOP)
    show_relative_times = config.bool("show_relative_times", False)
    user_text = config.str("banner", "")
    schedule = get_schedule(route, stop, show_relative_times)
    timezone = config.get("timezone") or "America/New_York"
    now = time.now().in_location(timezone)
    left_pad = 4

    if config.bool("use_custom_banner_color"):
        route_bg_color = config.str("custom_banner_color")
    else:
        route_bg_color = get_route_bg_color(route)

    if config.bool("use_custom_text_color"):
        route_text_color = config.str("custom_text_color")
    else:
        route_text_color = get_route_text_color(route)

    if user_text == "":
        banner_text = route
    else:
        banner_text = user_text

    if config.bool("show_time"):
        if int(now.format("15")) < 12:
            meridian = "a"
        else:
            meridian = "p"
        banner_text = now.format("3:04") + meridian + " " + banner_text
        if now.format("3") in ["10", "11", "12"]:
            left_pad = 0

    return render.Root(
        delay = 100,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Column(
                    children = [
                        render.Stack(children = [
                            render.Box(height = 6, width = 64, color = route_bg_color),
                            render.Padding(pad = (left_pad, 0, 0, 0), child = render.Text(banner_text, font = "tom-thumb", color = route_text_color)),
                        ]),
                    ],
                ),
                render.Padding(pad = (0, 0, 0, 2), color = route_bg_color, child = render.Column(children = schedule)),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "banner",
                name = "Custom banner text",
                desc = "Custom text for the top bar. Leave blank to show the selected route.",
                icon = "penNib",
                default = "",
            ),
            schema.Toggle(
                id = "use_custom_banner_color",
                name = "Use custom banner color",
                desc = "Use a custom background color for the top banner.",
                icon = "palette",
                default = False,
            ),
            schema.Color(
                id = "custom_banner_color",
                name = "Custom banner color",
                desc = "A custom background color for the top banner.",
                icon = "brush",
                default = "#7AB0FF",
            ),
            schema.Toggle(
                id = "use_custom_text_color",
                name = "Use custom text color",
                desc = "Use a custom text color for the top banner.",
                icon = "palette",
                default = False,
            ),
            schema.Color(
                id = "custom_text_color",
                name = "Custom text color",
                desc = "A custom text color for the top banner.",
                icon = "brush",
                default = "#FFFFFF",
            ),
            schema.Toggle(
                id = "show_time",
                name = "Show time",
                desc = "Show the current time in the top banner.",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = "show_relative_times",
                name = "Show relative departure times",
                desc = "Show relative departure times.",
                icon = "clock",
                default = False,
            ),
            schema.Dropdown(
                id = "route",
                name = "Route",
                desc = "Select a route",
                icon = "signsPost",
                default = DEFAULT_ROUTE,
                options = get_routes(),
            ),
            schema.Generated(
                id = "stop",
                source = "route",
                handler = select_stop,
            ),
        ],
    )
