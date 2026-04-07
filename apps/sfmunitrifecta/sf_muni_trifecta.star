"""
Applet: SF Muni Trifecta
Summary: Three Muni stops at once
Description: Monitor three SF Muni stops on a single screen.
Author: Tony
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# 511.org API endpoint
PREDICTIONS_URL = "https://api.511.org/transit/StopMonitoring?api_key=%s&agency=SF&stopCode=%s&format=json"

# Row colors (background, text)
ROW_COLORS = [
    ("#008752", "#FFF"),  # Green
    ("#00539b", "#FFF"),  # Blue
    ("#8B008B", "#FFF"),  # Purple
]
COLOR_DIRECTION = "#AAA"
COLOR_TIMES = "#D4A017"

def main(config):
    api_key = config.get("api_key")
    if not api_key:
        return render.Root(
            child = render.Box(
                render.WrappedText(
                    content = "Set API key in config",
                    font = "tom-thumb",
                ),
            ),
        )

    # Get configuration for each row
    rows = []
    for i in range(1, 4):
        route = config.get("route%d" % i) or ""
        stop = config.get("stop%d" % i) or ""
        direction = config.get("dir%d" % i) or "IN"

        if route and route != "none" and stop:
            predictions = get_predictions(api_key, stop, route)
            bg_color, text_color = ROW_COLORS[(i - 1) % len(ROW_COLORS)]
            rows.append(render_row(route, direction, predictions, bg_color, text_color))

    if not rows:
        return render.Root(
            child = render.Box(
                render.WrappedText(
                    content = "Configure stops",
                    font = "tom-thumb",
                ),
            ),
        )

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            children = rows,
        ),
    )

def get_predictions(api_key, stop_id, route_filter):
    """Fetch and parse predictions for a stop, filtered by route."""
    url = PREDICTIONS_URL % (api_key, stop_id)
    res = http.get(
        url,
        ttl_seconds = 60,
        headers = {"Accept-Encoding": "identity"},
    )

    if res.status_code != 200:
        print("API request failed: %d" % res.status_code)
        return []

    body = res.body().lstrip("\ufeff")
    data = json.decode(body)

    delivery = data.get("ServiceDelivery", {})
    monitoring = delivery.get("StopMonitoringDelivery", {})
    if not monitoring:
        return []

    visits = monitoring.get("MonitoredStopVisit", [])
    if not visits:
        return []

    predictions = []
    now = time.now().unix

    for visit in visits:
        journey = visit.get("MonitoredVehicleJourney", {})
        line = journey.get("LineRef")

        if line != route_filter:
            continue

        call = journey.get("MonitoredCall", {})
        expected = call.get("ExpectedDepartureTime") or call.get("ExpectedArrivalTime")

        if not expected:
            continue

        expected_time = time.parse_time(expected)
        if expected_time:
            minutes = int((expected_time.unix - now) / 60)
            if minutes >= 0:
                predictions.append(minutes)

    return sorted(predictions)[:3]

def render_row(route, direction, predictions, circle_color, text_color):
    """Render a single row: route, direction, and times."""

    if predictions:
        times_str = ",".join([str(m) for m in predictions])
    else:
        times_str = "--"

    # Use short direction labels
    dir_label = "I" if direction == "IN" else "O"

    return render.Row(
        expanded = True,
        main_align = "start",
        cross_align = "center",
        children = [
            render.Box(width = 2, height = 1),
            render.Circle(
                diameter = 9,
                color = circle_color,
                child = render.Text(route, font = "tom-thumb", color = text_color),
            ),
            render.Box(width = 3, height = 1),
            render.Box(
                width = 6,
                height = 8,
                child = render.Text(dir_label, color = COLOR_DIRECTION),
            ),
            render.Box(width = 3, height = 1),
            render.Text(times_str, color = COLOR_TIMES),
        ],
    )

def get_schema():
    route_options = [
        schema.Option(display = "N Judah", value = "N"),
        schema.Option(display = "J Church", value = "J"),
        schema.Option(display = "K Ingleside", value = "K"),
        schema.Option(display = "L Taraval", value = "L"),
        schema.Option(display = "M Ocean View", value = "M"),
        schema.Option(display = "T Third Street", value = "T"),
        schema.Option(display = "F Market", value = "F"),
        schema.Option(display = "1 California", value = "1"),
        schema.Option(display = "5 Fulton", value = "5"),
        schema.Option(display = "14 Mission", value = "14"),
        schema.Option(display = "22 Fillmore", value = "22"),
        schema.Option(display = "38 Geary", value = "38"),
        schema.Option(display = "38R Geary Rapid", value = "38R"),
        schema.Option(display = "43 Masonic", value = "43"),
        schema.Option(display = "48 Quintara/24th St", value = "48"),
        schema.Option(display = "49 Van Ness/Mission", value = "49"),
    ]

    direction_options = [
        schema.Option(display = "IN", value = "IN"),
        schema.Option(display = "OUT", value = "OUT"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "511.org API Key",
                desc = "Get free key at 511.org/open-data/token",
                icon = "key",
            ),
            # Row 1
            schema.Dropdown(
                id = "route1",
                name = "Row 1 Route",
                desc = "First row route",
                icon = "bus",
                options = route_options,
                default = "N",
            ),
            schema.Text(
                id = "stop1",
                name = "Row 1 Stop Code",
                desc = "Find codes at 511.org/transit/agencies/stop-id",
                icon = "mapPin",
            ),
            schema.Dropdown(
                id = "dir1",
                name = "Row 1 Direction",
                desc = "Direction label",
                icon = "arrowRight",
                options = direction_options,
                default = "IN",
            ),
            # Row 2
            schema.Dropdown(
                id = "route2",
                name = "Row 2 Route",
                desc = "Second row route",
                icon = "bus",
                options = [schema.Option(display = "None", value = "none")] + route_options,
                default = "none",
            ),
            schema.Text(
                id = "stop2",
                name = "Row 2 Stop Code",
                desc = "Find codes at 511.org/transit/agencies/stop-id",
                icon = "mapPin",
            ),
            schema.Dropdown(
                id = "dir2",
                name = "Row 2 Direction",
                desc = "Direction label",
                icon = "arrowRight",
                options = direction_options,
                default = "OUT",
            ),
            # Row 3
            schema.Dropdown(
                id = "route3",
                name = "Row 3 Route",
                desc = "Third row route",
                icon = "bus",
                options = [schema.Option(display = "None", value = "none")] + route_options,
                default = "none",
            ),
            schema.Text(
                id = "stop3",
                name = "Row 3 Stop Code",
                desc = "Find codes at 511.org/transit/agencies/stop-id",
                icon = "mapPin",
            ),
            schema.Dropdown(
                id = "dir3",
                name = "Row 3 Direction",
                desc = "Direction label",
                icon = "arrowRight",
                options = direction_options,
                default = "IN",
            ),
        ],
    )
