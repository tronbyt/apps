"""
Applet: Teslamate Driving
Summary: Route Info about your Tesla
Description: See where your Tesla is going and when it will get there.
Author: Brombomb
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

def fetch_ha_data(ha_url, ha_token, name_entity, tesla_state_entity, route_dest_entity, route_dist_entity,
        route_time_entity, traffic_delay_entity, trip_total_entity, trip_progress_entity, cache_duration):
    """Fetch Tesla data from Home Assistant REST API using template endpoint for efficiency"""
    def pretty_json(value, indent = "  ", level = 0):
        value_type = type(value)
        if value_type == "dict":
            keys = sorted(value.keys())
            if len(keys) == 0:
                return "{}"
            rendered = []
            for key in keys:
                rendered.append(
                    "%s%s: %s" % (
                        indent * (level + 1),
                        json.encode(key),
                        pretty_json(value[key], indent, level + 1),
                    )
                )
            return "{\n%s\n%s}" % ("\n".join(rendered), indent * level)
        if value_type == "list":
            if len(value) == 0:
                return "[]"
            rendered = [
                "%s%s" % (indent * (level + 1), pretty_json(item, indent, level + 1))
                for item in value
            ]
            return "[\n%s\n%s]" % ("\n".join(rendered), indent * level)
        return json.encode(value)

    invalid_strings = {
        "unknown": True,
        "unavailable": True,
        "none": True,
        "": True,
    }

    def normalize(value, fallback):
        if value == None:
            return fallback
        if type(value) == "string" and invalid_strings.get(value.lower(), False):
            return fallback
        return value

    if not ha_url or not ha_token:
        return (
            "Tesla", "Unknown", "Unknown", 0.0, 0.0, "Unknown", 0.0, 0.0
        )

    headers = {
        "Authorization": "Bearer %s" % ha_token,
        "Content-Type": "application/json",
    }

    # Clean up URL - remove trailing slash
    base_url = ha_url.rstrip("/")

    # Create a template that fetches all entities in a single request
    # The template returns a JSON string with all values
    template = """
{
    "name": "{{ states('%s') | default('Tesla') }}",
    "tesla_state": "{{ states('%s') | default('Unknown') }}",
    "route_dest": "{{ states('%s') | default('Unknown') }}",
    "route_dist": "{{ states('%s') | float(0) }}",
    "route_time": "{{ states('%s') | float(0) }}",
    "traffic_delay": "{{ states('%s') | default('Unknown') }}",
    "trip_total": "{{ states('%s') | float(0) }}",
    "trip_progress": "{{ states('%s') | float(0) }}"
}
""".strip() % (
            name_entity, tesla_state_entity, route_dest_entity, route_dist_entity,
            route_time_entity, traffic_delay_entity, trip_total_entity, trip_progress_entity
        )

    # Make single request to template endpoint
    template_url = base_url + "/api/template"
    payload = {"template": template}

    resp = http.post(template_url, headers = headers, json_body = payload, ttl_seconds = cache_duration)

    if resp.status_code == 200:
        response_body = resp.body()
        if response_body:
            data = json.decode(response_body)
            print(pretty_json(data))
            normalized = {
                "name": normalize(data.get("name"), "Tesla"),
                "tesla_state": normalize(data.get("tesla_state"), "Unknown"),
                "route_dest": normalize(data.get("route_dest"), "Unknown"),
                "route_dist": normalize(data.get("route_dist"), 0.0),
                "route_time": normalize(data.get("route_time"), 0.0),
                "traffic_delay": normalize(data.get("traffic_delay"), "Unknown"),
                "trip_total": normalize(data.get("trip_total"), 0.0),
                "trip_progress": normalize(data.get("trip_progress"), 0.0),
            }
            return (
                normalized["name"],
                normalized["tesla_state"],
                normalized["route_dest"],
                normalized["route_dist"],
                normalized["route_time"],
                normalized["traffic_delay"],
                normalized["trip_total"],
                normalized["trip_progress"],
            )
    # Return defaults if request failed or parsing failed
    return ("Tesla", "Unknown", "Unknown", 0.0, 0.0, "Unknown", 0.0, 0.0)

def main(config):

    ha_url = config.str("ha_url")
    ha_token = config.str("ha_token")
    name_entity = config.str("name_entity")
    tesla_state_entity = config.str("tesla_state_entity")
    # Align config keys with schema and HA entity names
    route_dest_entity = config.str("active_route_destination_entity")
    route_time_entity = config.str("active_route_minutes_entity")
    route_dist_entity = config.str("active_route_distance_entity")
    trip_total_entity = config.str("active_route_total_distance_entity")
    traffic_delay_entity = config.str("active_route_traffic_delay_entity")
    trip_progress_entity = config.str("active_route_progress_entity")
    bar_complete_color = config.str("bar_complete_color", "#66666680")
    car_color = config.str("car_color", "#FFFFFF")
    dest_color = config.str("dest_color", "#FFFFFF")
    time_color = config.str("time_color", "#FFFFFF")
    cache_duration = 0  # seconds

    # Fetch all data
    (
        name, tesla_state, route_dest, route_dist, route_time, traffic_delay, trip_total, trip_progress
    ) = fetch_ha_data(
        ha_url, ha_token, name_entity, tesla_state_entity, route_dest_entity, route_dist_entity,
        route_time_entity, traffic_delay_entity, trip_total_entity, trip_progress_entity, cache_duration
    )

    # Skip render if not driving
    if tesla_state != "driving":
        return []

    # Format destination with emoji
    dest_str = route_dest

    # Defensive: ensure all values are strings and not None
    def safe_str(val, default="Unknown"):
        if val == None:
            return default
        return str(val)

    def parse_float(val, default):
        if type(val) == "float" or type(val) == "int":
            return float(val)
        if type(val) == "string" and re.match("^-?\\d+(\\.\\d+)?$", val):
            return float(val)
        return default

    def format_minutes(val):
        mins = int(math.round(parse_float(val, 0.0)))
        hours = mins // 60
        rem = mins % 60
        parts = []
        if hours > 0:
            parts.append("%d hr" % hours)
        parts.append("%d min" % rem)
        return " ".join(parts)

    # Numeric values
    distance_val = parse_float(route_dist, 0.0)
    total_distance = parse_float(trip_total, distance_val)
    if total_distance < distance_val:
        total_distance = distance_val
    completed_distance = max(total_distance - distance_val, 0.0)

    progress = 0.0
    tp_val = parse_float(trip_progress, -1.0)
    if tp_val >= 0 and tp_val <= 100:
        progress = max(0.0, min(1.0, tp_val / 100.0))
    elif total_distance > 0:
        progress = max(0.0, min(1.0, completed_distance / total_distance))

    # Traffic color mapping
    def traffic_color(delay_val):
        val = parse_float(delay_val, 0.0)
        if val < 3:
            return "#34A853C0"  # green
        if val < 10:
            return "#FBBC04C0"  # orange
        if val < 30:
            return "#EA4335C0"  # red
        return "#A92727C0"     # dark red

    # Full-width bar (62px fill + 2px border = 64px total)
    bar_width = 62
    bar_height = 7
    complete_width = int(bar_width * progress)
    remaining_width = max(bar_width - complete_width, 0)

    # Build bar layers
    bar_fill = render.Row(
        children = [
            render.Box(width = complete_width, height = bar_height, color = bar_complete_color),
            render.Box(width = remaining_width, height = bar_height, color = traffic_color(traffic_delay)),
        ],
    )

    bar_container = render.Box(
        width = bar_width + 2,
        height = bar_height + 2,
        color = "#FFFFFF",  # white border
        child = render.Box(
            width = bar_width,
            height = bar_height,
            color = "#444444",  # track background
            child = bar_fill,
        ),
    )

    shimmer_frames = []
    shimmer_w = 12

    # Sweep highlight left to right; grow in and shrink out to avoid pops
    for pos in range(0, bar_width + shimmer_w, 2):
        left_gap = 1
        visible_w = 0
        if(pos < shimmer_w):
            left_gap = 1
            visible_w = pos  # grow from 0 -> shimmer_w
        else:
            left_gap = max(1, pos - shimmer_w)
            visible_w = shimmer_w

        if visible_w > 0:
            shimmer_frames.append(
                render.Stack(
                    children = [
                        bar_container,
                        render.Row(
                            children = [
                                render.Box(width = left_gap, height = bar_height + 2),
                                render.Box(width = visible_w, height = bar_height + 2, color = "#FFFFFF30"),
                            ],
                            cross_align = "start",
                        ),
                    ],
                )
            )
        else:
            shimmer_frames.append(bar_container)

    # Hold on clean bar to avoid flicker at loop boundary
    for _ in range(30):
        shimmer_frames.append(bar_container)

    shimmer = render.Animation(children = shimmer_frames)

    car_offset = max(0, min(bar_width - 2, int(progress * (bar_width - 2))))
    bar_with_car = render.Box(
        height = bar_height + 2,
        child = render.Stack(
            children = [
                bar_container,
                shimmer,
                render.Row(
                    children = [
                        render.Box(width = max(0, car_offset - 6), height = bar_height + 2),
                        render.Column(
                            children = [
                                render.Text(content = "🚙", offset = 2),
                            ],
                        ),
                    ],
                    cross_align = "start",
                ),
            ],
        ),
    )

    header_row = render.Row(
        children = [
            render.Emoji(emoji = "📍", height = 8),
            render.Text(content = " %s" % safe_str(dest_str) , color = dest_color ),
        ],
    )

    info_row = render.Row(
        children = [
            render.Emoji(emoji = "🕒", height = 8),
            render.Text(content = format_minutes(route_time), color = time_color ),
        ],
    )

    return render.Root(
        child = render.Column(
            children = [
                header_row,
                bar_with_car,
                info_row,
                render.Text(content = name, color = car_color ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ha_url",
                name = "Home Assistant URL",
                desc = "e.g. https://homeassistant.local:8123",
                icon = "server",
            ),
            schema.Text(
                id = "ha_token",
                name = "Home Assistant Token",
                desc = "Long-lived access token from HA",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "name_entity",
                name = "Display Name",
                desc = "Entity name for vehicle display name",
                icon = "tag",
                default = "sensor.tesla_display_name",
            ),
            schema.Text(
                id = "tesla_state_entity",
                name = "Tesla State for Driving",
                desc = "Entity for Tesla driving state",
                icon = "car",
                default = "sensor.tesla_state",
            ),
            schema.Text(
                id = "active_route_destination_entity",
                name = "Active Route Destination",
                desc = "Entity for active route destination",
                icon = "locationDot",
                default = "sensor.tesla_active_route_destination",
            ),
            schema.Text(
                id = "active_route_distance_entity",
                name = "Active Route Distance",
                desc = "Entity for active route distance",
                icon = "ruler",
                default = "sensor.tesla_active_route_distance",
            ),
            schema.Text(
                id="active_route_total_distance_entity",
                name="Active Route Total Distance",
                desc="Entity for active route total distance",
                icon="rulerCombined",
                default="sensor.tesla_active_route_total_distance",
            ),
            schema.Text(
                id = "active_route_minutes_entity",
                name = "Active Route Minutes to Arrival",
                desc = "Entity for active route minutes to arrival",
                icon = "clock",
                default = "sensor.tesla_active_route_minutes_to_arrival",
            ),
            schema.Text(
                id = "active_route_traffic_delay_entity",
                name = "Active Route Traffic Minutes Delay",
                desc = "Entity for active route traffic minutes delay",
                icon = "trafficLight",
                default = "sensor.tesla_active_route_traffic_minutes_delay",
            ),
            schema.Text(
                id = "active_route_progress_entity",
                name = "Trip Progress Entity",
                desc = "Entity for trip progress percent",
                icon = "gauge",
                default = "sensor.teslamate_1_trip_progress",
            ),
            schema.Text(
                id = "bar_complete_color",
                name = "Bar Complete Color",
                desc = "Hex color for completed portion of the bar",
                icon = "palette",
                default = "#66666680",
            ),
            schema.Text(
                id = "car_color",
                name = "Car Name Color",
                desc = "Hex color applied to the car name",
                icon = "car",
                default = "#FFFFFF",
            ),
        ],
    )
