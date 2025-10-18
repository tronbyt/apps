"""
Applet: ha3dprint
Summary: View HA 3D printer status
Description: Display the current job name, progress and remaining time for a selected 3D printer via Home Assistant.
Author: brombomb
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

C_DISPLAY_WIDTH = 64
C_BACKGROUND = [0, 0, 0]
C_TEXT_COLOR = [255, 255, 255]

C_MIN_WIDTH = 1
C_HEIGHT = 8

# colors
RED = "#FF0000"
WHITE = "#FFFFFF"
GREEN = "#00FF00"

def fetch_ha_data(ha_url, ha_token, name_entity, current_layer_entity, total_layers_entity, progress_entity, remaining_time_entity, end_time_entity, status_entity, cache_duration):
    """Fetch printer data from Home Assistant REST API using template endpoint for efficiency"""
    headers = {
        "Authorization": "Bearer " + ha_token,
        "Content-Type": "application/json",
    }

    # Clean up URL - remove trailing slash
    base_url = ha_url.rstrip("/")

    # Default values in case of errors
    defaults = {
        "name": "Printer",
        "current_layer": "0",
        "total_layers": "0",
        "progress": "0",
        "remaining_time": "0",
        "end_time": "0",
        "status": "Unknown",
    }

    # Create a template that fetches all entities in a single request
    template = """
{
    "name": "{{ states('%s') | default('Printer') }}",
    "current_layer": "{{ states('%s') | default('0') }}",
    "total_layers": "{{ states('%s') | default('0') }}",
    "progress": "{{ states('%s') | default('0') }}",
    "remaining_time": "{{ states('%s') | default('0') }}",
    "end_time": "{{ states('%s') | default('0') }}",
    "status": "{{ states('%s') | default('Unknown') }}"
}
""" % (
        name_entity,
        current_layer_entity,
        total_layers_entity,
        progress_entity,
        remaining_time_entity,
        end_time_entity,
        status_entity,
    )

    # Only make API request if ha_token is not the default value
    if ha_token != "APIKEY":
        # Make single request to template endpoint
        template_url = base_url + "/api/template"
        payload = {"template": template}

        resp = http.post(template_url, headers = headers, json_body = payload, ttl_seconds = cache_duration)

        print(resp.body())

        # Correctly return printer entity fields
        if resp.status_code == 200:
            # Parse the JSON response from the template
            response_body = resp.body()
            if response_body:
                data = json.decode(response_body)
                return (
                    data.get("name", defaults["name"]),
                    data.get("current_layer", defaults["current_layer"]),
                    data.get("total_layers", defaults["total_layers"]),
                    data.get("progress", defaults["progress"]),
                    data.get("remaining_time", defaults["remaining_time"]),
                    data.get("end_time", defaults["end_time"]),
                    data.get("status", defaults["status"]),
                )

# convert color specification from JSON to hex string
def to_rgb(color, combine = None, combine_level = 0.5):
    # default to white color in case of error when parsing color
    (r, g, b) = (255, 255, 255)

    if str(type(color)) == "string":
        # parse various formats of colors as string
        if len(color) == 7:
            # color is in form of #RRGGBB
            r = int(color[1:3], 16)
            g = int(color[3:5], 16)
            b = int(color[5:7], 16)
        elif len(color) == 6:
            # color is in form of RRGGBB
            r = int(color[0:2], 16)
            g = int(color[2:4], 16)
            b = int(color[4:6], 16)
        elif len(color) == 4 and color[0:1] == "#":
            # color is in form of #RGB
            r = int(color[1:2], 16) * 0x11
            g = int(color[2:3], 16) * 0x11
            b = int(color[3:4], 16) * 0x11
        elif len(color) == 3 and color[0:1] != "#":
            # color is in form of RGB
            r = int(color[0:1], 16) * 0x11
            g = int(color[1:2], 16) * 0x11
            b = int(color[2:3], 16) * 0x11
    elif str(type(color)) == "list" and len(color) == 3:
        # otherwise assume color is an array of R, G, B tuple
        r = color[0]
        g = color[1]
        b = color[2]

    if combine != None:
        combine_color = lambda v0, v1, level: min(max(int(math.round(v0 + float(v1 - v0) * float(level))), 0), 255)
        r = combine_color(r, combine[0], combine_level)
        g = combine_color(g, combine[1], combine_level)
        b = combine_color(b, combine[2], combine_level)

    return "#" + str("%x" % ((1 << 24) + (r << 16) + (g << 8) + b))[1:]

# render a single item's progress
def renderProgress(label, progress_value, padding, bar_color):
    stack_children = [
        render.Box(width = C_DISPLAY_WIDTH, height = C_HEIGHT + padding, color = to_rgb(C_BACKGROUND)),
    ]

    color = bar_color or "#64BFE5"

    if progress_value != None:
        progress = progress_value / 100.0
        progress_percent = int(math.round(progress_value))
        if label != "":
            label += ": "
        label += str(progress_percent) + "%"

        progress_width = C_MIN_WIDTH + int(math.round(float(C_DISPLAY_WIDTH - C_MIN_WIDTH) * progress))

        stack_children.append(
            render.Box(
                width = progress_width,
                padding = 1,
                color = to_rgb(color, combine = C_BACKGROUND, combine_level = 0.1),
                height = C_HEIGHT,
                child = render.Box(
                    color = to_rgb(color, combine = C_BACKGROUND, combine_level = 0.5),
                ),
            ),
        )

    # stack the progress bar with label
    stack_children.append(
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Text(
                    content = label,
                    color = to_rgb(color, combine = C_TEXT_COLOR, combine_level = 0.8),
                    height = C_HEIGHT,
                    offset = 1,
                    font = "tom-thumb",
                ),
            ],
        ),
    )

    # render the entire row
    return render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            render.Stack(
                children = stack_children,
            ),
        ],
    )

def main(config):
    ha_url = config.str("haUrl", "http://homeassistant.local:8123")
    ha_token = config.str("haApiKey", "APIKEY")
    name_entity = config.str("task_name", "task_name")
    current_layer_entity = config.str("current_layer", "test_current_layer")
    total_layers_entity = config.str("total_layers", "test_total_layers")
    progress_entity = config.str("progress", "test_progress")
    remaining_time_entity = config.str("remaining_time", "test_remaining_time")
    status_entity = config.str("status", "test_status")
    end_time_entity = config.str("end_time", "")
    cache_duration = 4

    # Always fetch printer data for rendering
    result = fetch_ha_data(
        ha_url,
        ha_token,
        name_entity,
        current_layer_entity,
        total_layers_entity,
        progress_entity,
        remaining_time_entity,
        end_time_entity,
        status_entity,
        cache_duration,
    )
    if result == None:
        result = ("Printer", "0", "0", "0", "0", "0", "Unknown")
    (name, current_layer, total_layers, progress, remaining_time, end_time, status) = result

    # Check if we should render anything
    skip_render = False
    # Check status
    if str(status).lower() == "offline":
        skip_render = True
        print("Printer is offline, skipping render")
    # Check end_time using Starlark's time.parse_time and duration
    if not skip_render and end_time != None and str(end_time) != "":
        end_dt = time.parse_time(str(end_time))
        now_dt = time.now()
        diff = end_dt - now_dt
        if diff.total_seconds() > 4 * 3600:
            skip_render = True
            print("Printer finished more than 4 hours from now, skipping render")

    if skip_render:
        return []

    # Format time left (handles float hours, minutes)
    time_left = ""
    seconds = 0
    if str(type(remaining_time)) == "string":
        did_parse = False
        if remaining_time.find(".") != -1:
            digits = "0123456789."
            valid = True
            for i in range(len(remaining_time)):
                c = remaining_time[i]
                if digits.find(c) == -1:
                    valid = False
                    break
            if valid:
                hours_float = float(remaining_time)
                seconds = int(hours_float * 3600)
                did_parse = True
        if not did_parse and remaining_time.isdigit():
            seconds = int(remaining_time)
    elif str(type(remaining_time)) == "int":
        seconds = remaining_time
    elif str(type(remaining_time)) == "float":
        seconds = int(remaining_time * 3600)
    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    min_str = str(minutes)
    if minutes < 10:
        min_str = "0" + min_str
    if seconds > 0:
        time_left = "%dh %sm left" % (hours, min_str)

    # Status color
    stateColor = WHITE
    status_upper = str(status).upper()
    if status_upper in ["FAILED", "ERROR", "CANCELLED"]:
        stateColor = RED
    elif status_upper in ["RUNNING", "SUCCESS"]:
        stateColor = GREEN

    # Render UI
    return render.Root(
        child = render.Box(
            width = 64,
            height = 32,
            child = render.Padding(
                pad = (0, 1, 0, 0),
                child = render.Column(
                    main_align = "center",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Marquee(
                            child = render.Text(str(name), font = "tom-thumb"),
                            width = 64,
                            align = "start",
                            offset_start = 5,
                            offset_end = 8,
                        ) if len(str(name)) > 15 else render.Text(str(name), font = "tom-thumb"),
                        render.WrappedText(status_upper, color = stateColor),
                        render.Text(time_left) if time_left else render.Text(""),
                        # Safely convert progress to int, default to 0 if not a number
                        renderProgress("Completion", int(progress) if str(progress).isdigit() else 0, 1, "#64BFE5"),
                    ],
                ),
            ),
        ),
    )

def get_schema():
    fields = [
        schema.Text(id = "haUrl", name = "Home Assistant URL", desc = "Base URL of your Home Assistant instance (e.g. http://homeassistant.local:8123)", icon = "server"),
        schema.Text(id = "haApiKey", name = "Home Assistant API Key", desc = "Long-Lived Access Token from Home Assistant user profile", icon = "key"),
        schema.Text(id = "task_name", name = "Task Name", desc = "Currently Printing Task", icon = "file"),
        schema.Text(id = "current_layer", name = "Current Layer", desc = "Entity ID for current layer", icon = "layerGroup"),
        schema.Text(id = "total_layers", name = "Total Layers", desc = "Entity ID for total layers", icon = "layerGroup"),
        schema.Text(id = "progress", name = "Print Progress", desc = "Entity ID for print progress (%)", icon = "percent"),
        schema.Text(id = "remaining_time", name = "Remaining Time", desc = "Entity ID for remaining time (decimal hours/minutes)", icon = "clock"),
        schema.Text(id = "end_time", name = "Print End Time", desc = "Entity ID for print end time (Y-M-D H:M:S)", icon = "calendar"),
        schema.Text(id = "status", name = "Print Status", desc = "Entity ID for print status", icon = "info"),

    ]

    return schema.Schema(version = "1", fields = fields)
