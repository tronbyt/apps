"""
Applet: RTD Denver
Summary: Live RTD transit times
Description: Shows real-time bus and train arrival times for Denver RTD stops. Displays routes grouped by line with destination, color-coded by urgency based on your walk time.
Author: wfmer
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# Public proxy URL (deployed on Google Cloud Run)
# Note: RTD GTFS-RT feeds are Protocol Buffer format only; this proxy parses
# them and exposes a JSON API for use in Tidbyt's Starlark environment.
PROXY_URL = "https://rtd-proxy-194821693431.us-central1.run.app"

# RTD brand blue
RTD_BLUE = "#003DA5"
RTD_LIGHT_BLUE = "#0099CC"

# Default config values
DEFAULT_STOP_ID = "11981"
DEFAULT_WALK_TIME = "5"
DEFAULT_YELLOW_BUFFER = "5"  # minutes above walk_time before color = yellow
DEFAULT_GREEN_BUFFER = "10"  # minutes above walk_time before color = green

def main(config):
    """Main function to render RTD arrival times"""
    stop_id = config.get("stop_id", DEFAULT_STOP_ID)

    # Parse walk time with validation
    walk_time = parse_int(config.get("walk_time", DEFAULT_WALK_TIME), 5)
    yellow_buffer = parse_int(config.get("yellow_buffer", DEFAULT_YELLOW_BUFFER), 5)
    green_buffer = parse_int(config.get("green_buffer", DEFAULT_GREEN_BUFFER), 10)

    # Fetch predictions from proxy (30s cache is a good balance of freshness vs. load)
    url = "%s/predictions/%s" % (PROXY_URL, stop_id)
    rep = http.get(url, ttl_seconds = 30)

    if rep.status_code != 200:
        return error_screen("RTD unavailable")

    data = json.decode(rep.body())

    # Proxy may return stop_name if enhanced; fall back gracefully
    stop_name = data.get("stop_name", "")
    if stop_name == "" or stop_name == None:
        stop_name = "Stop %s" % stop_id

    predictions = data.get("predictions", [])

    if len(predictions) == 0:
        return no_service_screen(stop_name)

    # Group predictions by route, collecting up to 2 departure times per route
    route_order = []
    routes = {}
    for pred in predictions:
        route = pred.get("route", "?")
        minutes = pred.get("minutes", 0)
        headsign = pred.get("headsign", "")

        if route not in routes:
            route_order.append(route)
            routes[route] = {"headsign": headsign, "times": [minutes]}
        elif len(routes[route]["times"]) < 2:
            routes[route]["times"].append(minutes)

    # Build rows — show up to 3 routes
    rows = []
    for i in range(min(3, len(route_order))):
        route = route_order[i]
        info = routes[route]
        headsign = info["headsign"]
        times = info["times"]

        # Build time string with urgency color on first (soonest) departure
        first_min = times[0]
        color = urgency_color(first_min, walk_time, yellow_buffer, green_buffer)
        time_str = format_times(times)

        rows.append(make_route_row(route, headsign, time_str, color))

    return render.Root(
        delay = 100,
        show_full_animation = True,
        child = render.Column(
            main_align = "start",
            cross_align = "start",
            children = [make_header(stop_name)] + rows,
        ),
    )

def make_header(stop_name):
    """Renders the stop name header bar"""
    return render.Box(
        width = 64,
        height = 9,
        color = RTD_BLUE,
        child = render.Row(
            main_align = "start",
            cross_align = "center",
            expanded = True,
            children = [
                render.Padding(
                    pad = (2, 0, 0, 0),
                    child = render.Marquee(
                        width = 60,
                        child = render.Text(
                            content = stop_name,
                            color = "#ffffff",
                            font = "tom-thumb",
                        ),
                        offset_start = 0,
                        offset_end = 32,
                    ),
                ),
            ],
        ),
    )

def make_route_row(route, headsign, time_str, color):
    """Renders one route row: [BADGE] destination ... time"""

    # Route badge (up to 4 chars to fit nicely)
    badge_width = 16
    badge = render.Box(
        width = badge_width,
        height = 7,
        color = RTD_LIGHT_BLUE,
        child = render.Text(
            content = route[:4],
            color = "#ffffff",
            font = "tom-thumb",
        ),
    )

    # Right-aligned time with urgency color
    time_widget = render.Text(
        content = time_str,
        color = color,
        font = "tom-thumb",
    )

    # Destination: fill space between badge and time using marquee
    dest_content = headsign if headsign != "" else ""
    dest_widget = render.Marquee(
        width = 28,
        child = render.Text(
            content = dest_content,
            color = "#cccccc",
            font = "tom-thumb",
        ),
        offset_start = 0,
        offset_end = 5,
    )

    return render.Box(
        width = 64,
        height = 7,
        child = render.Padding(
            pad = (1, 1, 0, 0),
            child = render.Row(
                main_align = "start",
                cross_align = "center",
                expanded = True,
                children = [
                    badge,
                    render.Box(width = 2, height = 7),
                    dest_widget,
                    render.Box(width = 1, height = 7),
                    time_widget,
                ],
            ),
        ),
    )

def urgency_color(minutes, walk_time, yellow_buffer, green_buffer):
    """Returns color string based on minutes vs. walk time thresholds"""
    if minutes < walk_time:
        return "#ff3333"  # Red: too late
    elif minutes < walk_time + yellow_buffer:
        return "#ff9900"  # Orange: leave now
    elif minutes < walk_time + green_buffer:
        return "#ffdd00"  # Yellow: soon
    else:
        return "#33cc33"  # Green: plenty of time

def format_times(times):
    """Formats a list of minutes into a display string"""
    parts = []
    for t in times:
        if t == 0:
            parts.append("Now")
        else:
            parts.append("%dm" % t)
    return ",".join(parts)

def no_service_screen(stop_name):
    """Renders a friendly no-service screen"""
    return render.Root(
        child = render.Column(
            main_align = "start",
            cross_align = "start",
            children = [
                make_header(stop_name),
                render.Box(
                    width = 64,
                    height = 23,
                    child = render.Column(
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text("No service", color = "#aaaaaa", font = "tom-thumb"),
                            render.Box(height = 2),
                            render.Text("Check schedule", color = "#666666", font = "tom-thumb"),
                        ],
                    ),
                ),
            ],
        ),
    )

def error_screen(msg):
    """Renders an error screen"""
    return render.Root(
        child = render.Box(
            child = render.Column(
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text("RTD", color = RTD_LIGHT_BLUE, font = "6x13"),
                    render.Text(msg, color = "#ff3333", font = "tom-thumb"),
                ],
            ),
        ),
    )

def parse_int(s, default):
    """Safely parse a string to int with a default fallback"""
    if s == None or s == "":
        return default
    val = int(s)
    if val < 0:
        return default
    return val

def get_schema():
    """Configuration schema for the Tidbyt mobile app"""
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "stop_id",
                name = "RTD Stop ID",
                desc = "Enter your RTD stop ID. Find it at rtd-denver.com or on the stop sign post.",
                icon = "bus",
                default = DEFAULT_STOP_ID,
            ),
            schema.Text(
                id = "walk_time",
                name = "Walk time (minutes)",
                desc = "How many minutes does it take you to walk to the stop? Arrivals sooner than this show red.",
                icon = "personWalking",
                default = DEFAULT_WALK_TIME,
            ),
            schema.Text(
                id = "yellow_buffer",
                name = "Leave-now window (minutes)",
                desc = "Arrivals within this many minutes beyond your walk time show orange. Default: 5",
                icon = "clock",
                default = DEFAULT_YELLOW_BUFFER,
            ),
            schema.Text(
                id = "green_buffer",
                name = "Comfortable window (minutes)",
                desc = "Arrivals at least this many minutes beyond your walk time show green. Default: 10",
                icon = "check",
                default = DEFAULT_GREEN_BUFFER,
            ),
        ],
    )
