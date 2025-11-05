"""
Applet: San Diego Trolley
Summary: Trolley arrival times
Description: Shows scheduled and, when possible, real-time arrival times for San Diego MTS Trolleys.
Author: Alex Serriere
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Need to convert from a string to none value
NONE_STR = "__NONE__"

DEFAULT_STOP_ID_1 = "MTS_75078"
DEFAULT_STOP_ID_2 = "MTS_75079"

ROUTE_COLORS = {
    "Blue": "#0000FF",
    "Green": "#009900",
    "Orange": "#FF6600",
    "Silver": "#B4BCC2",
    "Black": "#000000",  #error state
}

def none_str_to_none_val(maybe_none_str):
    if maybe_none_str == NONE_STR:
        return None
    return maybe_none_str

def search_stops(prefix, config):
    if not prefix:
        return []

    response = http.get(
        "https://realtime.sdmts.com/api/api/where/stops-for-location.json?key=" + get_api_key(config) + "&query=" + prefix,
        ttl_seconds = 30,
    )
    if response.status_code != 200 or not response.body():
        print("Could not access transit data. HTTP Status: " + str(response.status_code))
        return []

    data = json.decode(response.body())["data"]
    stops = data["stops"]

    options = []
    for stop in stops:
        options.append(schema.Option(display = stop["name"], value = stop["id"]))
    return options

def get_api_key(config):
    return config.get("mts_api_key") or "NONE"

def get_arrivals_for_stop(stop_id, config):
    now = time.now().unix
    response = http.get("https://realtime.sdmts.com/api/api/where/arrivals-and-departures-for-stop/" + stop_id + ".json?key=" + get_api_key(config), ttl_seconds = 30)
    if response.status_code != 200 or not response.body():
        print("Could not access transit data. HTTP Status: " + str(response.status_code))
        return {"No Data": {"Black": ["0", "0", "0"]}}
    raw_stops = response.body()

    arrivals_and_departures = json.decode(raw_stops)["data"]["entry"]["arrivalsAndDepartures"]

    arrivals_by_heading = dict()

    for event in arrivals_and_departures:
        arrival_time_from_now = int((event["scheduledArrivalTime"] / 1000 - now) / 60)
        if event["predicted"]:
            arrival_time_from_now = int((event["predictedArrivalTime"] / 1000 - now) / 60)

        if arrival_time_from_now <= 0:
            continue

        arrivals_by_heading.setdefault(event["tripHeadsign"], {}).setdefault(event["routeShortName"], []).append(str(arrival_time_from_now))

    # Debug log
    for heading, arrivals in arrivals_by_heading.items():
        for route, times in arrivals.items():
            print(heading, route, times)

    return arrivals_by_heading

def show_arrivals_at_stop(stop_data):
    children = []
    for heading, arrivals in stop_data.items():
        for route, times in arrivals.items():
            children.append(
                render.Row(children = [
                    render.Padding(child = render.Box(width = 4, height = 12, color = ROUTE_COLORS[route]), pad = 2),
                    render.Column(children = [
                        render.Text(str(heading)),
                        render.Text(",".join(times), color = "#f2711c"),
                    ]),
                ]),
            )

    return render.Column(children)

def show_arrivals(stops_data):
    children = []
    for stop in stops_data:
        children.append(show_arrivals_at_stop(stop))
        if len(children) <= len(stops_data) - 1:
            children.append(
                render.Box(
                    height = 1,
                    width = 64,
                    color = "#fff",
                ),
            )

    return render.Marquee(
        height = 32,
        child = render.Column(children),
        scroll_direction = "vertical",
    )

def main(config):
    stop1 = none_str_to_none_val(config.get("stop1", DEFAULT_STOP_ID_1))
    stop2 = none_str_to_none_val(config.get("stop2", DEFAULT_STOP_ID_2))
    stops_arrivals = []
    if stop1:
        stops_arrivals.append(get_arrivals_for_stop(stop1, config))
    if stop2:
        stops_arrivals.append(get_arrivals_for_stop(stop2, config))
    return render.Root(
        child = show_arrivals(stops_arrivals),
        delay = 150,
        max_age = 30,
        show_full_animation = True,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "stop1",
                name = "Top station",
                desc = "The first station to show",
                icon = "arrowUp",
                handler = search_stops,
            ),
            schema.Typeahead(
                id = "stop2",
                name = "Bottom station",
                desc = "The second station to show",
                icon = "arrowDown",
                handler = search_stops,
            ),
            schema.Text(
                id = "mts_api_key",
                name = "MTS API Key",
                desc = "An MTS API key to access the MTS API.",
                icon = "key",
                secret = True,
            ),
        ],
    )
