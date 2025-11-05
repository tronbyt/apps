"""
Applet: Sound Transit
Summary: Seattle light rail times
Description: Shows upcoming arrivals at up to 2 different stations in Sound Transit's Link light rail system in Seattle.
Author: Jon Janzen
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Some TidByt APIs require strings, but we want to use `None` values.
# ref `none_str_to_none_val`
NONE_STR = "__NONE__"

# The original author lived in Capitol Hill at the time of writing:
STATION1_DEFAULT = "40_99603"  # Capitol Hill N
STATION2_DEFAULT = "40_99610"  # Capitol Hill S
SHOULD_SCROLL_DEFAULT = True

# Cache next arrival information for a minute:
CACHE_TIMETABLE_SECONDS = 60

# Cache route information (which stops exist, etc) for one day:
CACHE_ROUTE_SECONDS = 60 * 60 * 24

def none_str_to_none_val(maybe_none_str):
    if maybe_none_str == NONE_STR:
        return None
    return maybe_none_str

def search_stations(prefix, config):
    if not prefix:
        return []

    # Use the OneBusAway API to search for stops by location/query
    response = http.get(
        "https://api.pugetsound.onebusaway.org/api/where/stops-for-location.json?key=" + get_api_token(config) + "&query=" + prefix,
        ttl_seconds = CACHE_ROUTE_SECONDS,
    )

    if response.status_code != 200 or not response.body():
        print("Could not access OBA for stop search. HTTP Status: " + str(response.status_code))
        return []

    data = json.decode(response.body())["data"]
    stops = data.get("list", [])  # OBA uses 'list' for stops-for-location results

    # Filter for light rail stops only (routeType == 0)
    light_rail_stops = [
        stop
        for stop in stops
        if any([route.get("type") == 0 for route in stop.get("routes", [])])
    ]

    return [
        schema.Option(display=stop["name"], value=stop["id"])
        for stop in light_rail_stops
    ]

now = time.now().unix

def get_api_token(config):
    # "OBAKEY" API key seems to work, but only use this as fallback
    return config.get("oba_api_key") or "OBAKEY"

def get_stop_data(stop_id, config):
    rep = http.get("https://api.pugetsound.onebusaway.org/api/where/schedule-for-stop/" + stop_id + ".json?key=" + get_api_token(config), ttl_seconds = CACHE_TIMETABLE_SECONDS)
    if rep.status_code != 200:
        fail("Could not access OBA")
    rep = rep.body()
    data = json.decode(rep)["data"]

    routes = {route["id"]: route for route in data["references"]["routes"]}

    result_data = []

    for route_schedule in data["entry"]["stopRouteSchedules"]:
        route = routes[route_schedule["routeId"]]

        for direction_schedule in route_schedule["stopRouteDirectionSchedules"]:
            next_stop_times = []
            for stop_time in direction_schedule["scheduleStopTimes"]:
                arrival_time_from_now = int((stop_time["arrivalTime"] / 1000 - now) / 60)

                if arrival_time_from_now < 0:
                    continue

                next_stop_times.append(str(arrival_time_from_now))

                if len(next_stop_times) >= 4:
                    break

            result_data.append(
                struct(
                    route = struct(
                        color = "#" + route["color"] if len(route["color"]) > 0 else "#000",
                        name = route["shortName"][0],
                    ),
                    headsign = direction_schedule["tripHeadsign"],
                    times = ",".join(next_stop_times),
                ),
            )

    return result_data

def show_stops(stop_id1, stop_id2, scroll_names, widgetMode, config):
    stop1_data = get_stop_data(stop_id1, config) if stop_id1 != None else []
    stop2_data = get_stop_data(stop_id2, config) if stop_id2 != None else []

    max_length = 0
    route_count = 0

    if scroll_names:
        for stop in stop1_data + stop2_data:
            stop_len = len(stop.headsign)
            if stop_len > max_length:
                max_length = stop_len
    else:
        max_length = 9

    for stop in [stop1_data, stop2_data]:
        if len(stop) > route_count:
            route_count = len(stop)

    sequence_children = []

    for stop_data in [stop1_data, stop2_data]:
        stop_row = []
        for stop in stop_data:
            stop_headsign = stop.headsign
            for _ in range(max_length - len(stop.headsign)):
                stop_headsign += " "

            for _ in range(len(stop.headsign) - max_length):
                stop_headsign = stop_headsign.removesuffix(stop_headsign[-1])

            if not widgetMode:
                headsign = render.Marquee(width = 64 - 16, child = render.Text(stop_headsign, font = "CG-pixel-4x5-mono"))
            else:
                headsign = render.Text(stop_headsign, font = "CG-pixel-4x5-mono")

            stop_row.append(render.Row(
                expanded = True,
                main_align = "space_evenly",
                children = [
                    render.Padding(
                        child = render.Circle(
                            color = stop.route.color,
                            diameter = 13,
                            child = render.Text(stop.route.name),
                        ),
                        pad = (1, 1, 0, 0),
                    ),
                    render.Padding(
                        child = render.Column(
                            children = [
                                headsign,
                                render.Text(stop.times, color = "#B84"),
                            ],
                        ),
                        pad = (1, 2, 0, 0),
                    ),
                ],
            ))

        if len(stop_row) < route_count and len(stop_row) >= 1:
            stop_row.append(stop_row[-1])

        sequence_children.append(render.Sequence(children = stop_row))

    return render.Column(children = [
        sequence_children[0],
        render.Box(color = "#444", height = 1),
        sequence_children[1],
    ])

def main(config):
    scroll_names = config.bool("scroll_names", SHOULD_SCROLL_DEFAULT)
    station1 = none_str_to_none_val(config.get("station1", STATION1_DEFAULT))
    station2 = none_str_to_none_val(config.get("station2", STATION2_DEFAULT))
    widgetMode = config.bool("$widget")

    return render.Root(
        child = show_stops(station1, station2, scroll_names, widgetMode, config),
        delay = 0 if scroll_names else 5 * 1000,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "station1",
                name = "Top station",
                desc = "The first station to show",
                icon = "arrowUp",
                handler = search_stations,
            ),
            schema.Typeahead(
                id = "station2",
                name = "Bottom station",
                desc = "The second station to show",
                icon = "arrowDown",
                handler = search_stations,
            ),
            schema.Toggle(
                id = "scroll_names",
                name = "Scroll names",
                desc = "Scroll the stop names if they're too long to fit on screen",
                icon = "scissors",
                default = SHOULD_SCROLL_DEFAULT,
            ),
            schema.Text(
                id = "oba_api_key",
                name = "OBA API Key",
                desc = "An OBA API key to access the OBA API.",
                icon = "key",
                secret = True,
            ),
        ],
    )
