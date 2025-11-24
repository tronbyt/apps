"""
Applet: TeslaMate
Summary: Shows charge/name/range via Home Assistant
Description: Shows your Tesla's current Name, Charge in Mi/KM and battery % via TeslaMate integration through Home Assistant REST API. Also shows if its charging or not.
Supports Home Assistant integration or default test values.
Author: brombomb

Based on the original TeslaFi app by @mrrobot245
Licensed under the Apache License, Version 2.0
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/bolt.png", BOLT = "file")
load("images/bolt_animated.gif", BOLT_ANIMATED = "file")
load("images/bolt_green.png", BOLT_GREEN = "file")
load("images/bolt_grey.png", BOLT_GREY = "file")
load("images/plug_blue.png", PLUG_BLUE = "file")
load("images/plug_red.png", PLUG_RED = "file")
load("images/tesla.png", TESLA = "file")
load("math.star", "math")
load("re.star", "re")
load("render.star", "canvas", "render")
load("schema.star", "schema")

DEFAULT_CACHE_DURATION = 300  # seconds

def lightness(color, amount):
    hsl_color = rgb_to_hsl(*hex_to_rgb(color))
    hsl_color_list = list(hsl_color)
    hsl_color_list[2] = hsl_color_list[2] * amount
    hsl_color = tuple(hsl_color_list)
    return rgb_to_hex(*hsl_to_rgb(*hsl_color))

def rgb_to_hsl(r, g, b):
    r = float(r / 255)
    g = float(g / 255)
    b = float(b / 255)
    high = max(r, g, b)
    low = min(r, g, b)
    h, s, l = ((high + low) / 2,) * 3

    if high == low:
        h = 0.0
        s = 0.0
    else:
        d = high - low
        s = d / (2 - high - low) if l > 0.5 else d / (high + low)
        if high == r:
            h = (g - b) / d + (6 if g < b else 0)
        elif high == g:
            h = (b - r) / d + 2
        elif high == b:
            h = (r - g) / d + 4
        h /= 6

    return int(math.round(h * 360)), s, l

def hue_to_rgb(p, q, t):
    if t < 0:
        t += 1
    if t > 1:
        t -= 1
    if t < 1 / 6:
        return p + (q - p) * 6 * t
    if t < 1 / 2:
        return q
    if t < 2 / 3:
        return p + (q - p) * (2 / 3 - t) * 6
    return p

def hsl_to_rgb(h, s, l):
    h = h / 360
    if s == 0:
        r, g, b = (l,) * 3  # achromatic
    else:
        q = l * (1 + s) if l < 0.5 else l + s - l * s
        p = 2 * l - q
        r = hue_to_rgb(p, q, h + 1 / 3)
        g = hue_to_rgb(p, q, h)
        b = hue_to_rgb(p, q, h - 1 / 3)

    return int(math.round(r * 255)), int(math.round(g * 255)), int(math.round(b * 255))

def hex_to_rgb(color):
    # Expand 4 digit hex to 7 digit hex
    if len(color) == 4:
        x = "([A-Fa-f0-9])"
        matches = re.match("#%s%s%s" % (x, x, x), color)
        rgb_hex_list = list(matches[0])
        rgb_hex_list.pop(0)
        for i in range(len(rgb_hex_list)):
            rgb_hex_list[i] = rgb_hex_list[i] + rgb_hex_list[i]
        color = "#" + "".join(rgb_hex_list)

    # Split hex into RGB
    x = "([A-Fa-f0-9]{2})"
    matches = re.match("#%s%s%s" % (x, x, x), color)
    rgb_hex_list = list(matches[0])
    rgb_hex_list.pop(0)
    for i in range(len(rgb_hex_list)):
        rgb_hex_list[i] = int(rgb_hex_list[i], 16)
    rgb = tuple(rgb_hex_list)

    return rgb

# Convert RGB tuple to hex
def rgb_to_hex(r, g, b):
    return "#" + str("%x" % ((1 << 24) + (r << 16) + (g << 8) + b))[1:]

def get_battery_color(battery_level, color_stops):
    """
    Calculate battery color based on level using configurable gradient colors.
    Color points are determined by the color_stops parameter passed from config.
    """

    stops = color_stops

    # Clamp battery level between 0 and 100
    level = max(0, min(100, battery_level))

    # Find the two color stops to interpolate between
    for i in range(len(stops) - 1):
        current_stop = stops[i]
        next_stop = stops[i + 1]

        if level <= next_stop[0]:
            # Calculate interpolation factor
            if next_stop[0] == current_stop[0]:
                factor = 0
            else:
                factor = (level - current_stop[0]) / (next_stop[0] - current_stop[0])

            # Interpolate RGB values using list comprehension
            start_rgb = current_stop[1]
            end_rgb = next_stop[1]
            rgb = [
                int(start_rgb[c] + (end_rgb[c] - start_rgb[c]) * factor)
                for c in range(3)
            ]
            return rgb_to_hex(rgb[0], rgb[1], rgb[2])

    # Fallback to the last color if somehow we get here
    return rgb_to_hex(*stops[-1][1])

def fetch_ha_data(ha_url, ha_token, battery_entity, range_entity, name_entity, charger_power_entity, plugged_in_entity, charge_limit_entity, cache_duration):
    """Fetch Tesla data from Home Assistant REST API using template endpoint for efficiency"""
    headers = {
        "Authorization": "Bearer " + ha_token,
        "Content-Type": "application/json",
    }

    # Clean up URL - remove trailing slash
    base_url = ha_url.rstrip("/")

    # Default values in case of errors
    defaults = {
        "name": "Tesla",
        "rangemi": 0.0,
        "batterylevel": 0.0,
        "charger_power": 0.0,
        "plugged_in": "off",
        "charge_limit": 80.0,
    }

    # Create a template that fetches all entities in a single request
    # The template returns a JSON string with all values
    template = """
{
  "name": "{{ states('%s') | default('Tesla') }}",
  "rangemi": "{{ states('%s') | float(0) }}",
  "batterylevel": "{{ states('%s') | float(0) }}",
  "charger_power": "{{ states('%s') | float(0) }}",
  "plugged_in": "{{ states('%s') | default('off') }}",
  "charge_limit": "{{ states('%s') | float(80) }}"
}
""".strip() % (name_entity, range_entity, battery_entity, charger_power_entity, plugged_in_entity, charge_limit_entity)

    # Make single request to template endpoint
    template_url = base_url + "/api/template"
    payload = {"template": template}

    resp = http.post(template_url, headers = headers, json_body = payload, ttl_seconds = cache_duration)

    if resp.status_code == 200:
        # Parse the JSON response from the template
        response_body = resp.body()
        if response_body:
            data = json.decode(response_body)
            return (
                data.get("name", defaults["name"]),
                data.get("rangemi", defaults["rangemi"]),
                data.get("batterylevel", defaults["batterylevel"]),
                data.get("charger_power", defaults["charger_power"]),
                data.get("plugged_in", defaults["plugged_in"]),
                data.get("charge_limit", defaults["charge_limit"]),
            )

    # Return defaults if request failed or parsing failed
    return defaults["name"], defaults["rangemi"], defaults["batterylevel"], defaults["charger_power"], defaults["plugged_in"], defaults["charge_limit"]

def main(config):
    scale = 2 if canvas.is2x() else 1

    ha_url = config.str("ha_url")
    ha_token = config.str("ha_token")
    battery_entity = config.str("battery_entity", "sensor.tesla_battery_level")
    range_entity = config.str("range_entity", "sensor.tesla_est_battery_range")
    name_entity = config.str("name_entity", "sensor.tesla_display_name")
    charger_power_entity = config.str("charger_power_entity", "sensor.tesla_charger_power")
    plugged_in_entity = config.str("plugged_in_entity", "binary_sensor.tesla_plugged_in")
    charge_limit_entity = config.str("charge_limit_entity", "sensor.tesla_charge_limit_soc")
    cache_duration_str = config.str("cache_duration", str(DEFAULT_CACHE_DURATION))

    if cache_duration_str.isdigit():
        cache_duration = int(cache_duration_str)
    else:
        cache_duration = DEFAULT_CACHE_DURATION

    # Build custom color stops from config
    color_stops = [
        (10, hex_to_rgb(config.str("color_10", "#FF0000"))),  # Red at 10%
        (20, hex_to_rgb(config.str("color_20", "#FF8000"))),  # Orange at 20%
        (30, hex_to_rgb(config.str("color_30", "#FFFF00"))),  # Yellow at 30%
        (50, hex_to_rgb(config.str("color_50", "#00FF00"))),  # Green at 50%
        (80, hex_to_rgb(config.str("color_80", "#00AAFF"))),  # Bright Blue at 80%
    ]

    # Add 0% and 100% stops to match the gradient boundaries
    color_stops = [(0, color_stops[0][1])] + color_stops + [(100, color_stops[-1][1])]

    if not ha_url:
        # Use dummy data
        name = "Shadow"
        rangemi = 133.0
        batterylevel = 43.0
        charger_power = 0.0
        plugged_in = "on"  # Represents is_plugged: True
        charge_limit = 80.0
    else:
        if not ha_token:
            return render.Root(
                child = render.WrappedText("Please configure Home Assistant token!"),
            )

        # Fetch data from Home Assistant REST API
        name, rangemi, batterylevel, charger_power, plugged_in, charge_limit = fetch_ha_data(ha_url, ha_token, battery_entity, range_entity, name_entity, charger_power_entity, plugged_in_entity, charge_limit_entity, cache_duration)

    # Determine the correct range value and unit for display
    range_value = rangemi
    unit = config.str("unit", "mi")

    if unit == "mi" and config.bool("mi2km") and range_value:
        range_value = str(math.round((float(range_value) * 1.60934)))
        unit = "km"

    # Determine charging state based on TeslaMate entities
    # Any non-zero charger power = charging
    # Battery level equals charge limit = complete
    # Plugged in but not charging = connected/not charging
    battery_val = int(batterylevel)
    limit_val = int(charge_limit)

    # Handle various string representations of boolean values
    # Added common TeslaMate states: "unplugged", "plugged in"
    plugged_states = ["on", "true", "1", "yes", "plugged in", "plugged", "connected"]
    is_plugged = str(plugged_in).lower() in plugged_states

    if charger_power > 0:
        image = BOLT_ANIMATED
    elif battery_val >= limit_val and is_plugged:
        image = BOLT_GREEN
    elif is_plugged:
        image = BOLT
    else:
        image = BOLT_GREY

    battery_level = int(batterylevel)
    state = {
        "batterylevel": battery_level,
        "color": get_battery_color(battery_level, color_stops),
        "name": name,
        "range_value": int(float(range_value)),
        "unit": unit,
        "image": image.readall(),
        "logo": TESLA.readall(),
        "state_image": PLUG_BLUE.readall() if is_plugged else PLUG_RED.readall(),
        "plugged_in_debug": plugged_in,  # For debugging
    }

    return render.Root(
        delay = 32,  # 30 fps
        child = render.Box(
            child = render.Animation(
                children = [
                    get_frame(state, fr, config, capanim((fr) * 3), scale)
                    for fr in range(300)
                ],
            ),
        ),
    )

def easeOut(t):
    sqt = t * t
    return sqt / (2.0 * (sqt - t) + 1.0)

def render_progress_bar(state, label, percent, col1, col3, animprogress, scale):
    animpercent = easeOut(animprogress / 100) * percent

    label1color = lightness("#fff", animprogress / 100)
    label2align = "start"

    # HSL approach for better text contrast:
    # - Bar fill (col2): 20% brightness for dark muted background
    # - Text: Full brightness for vibrant readability
    # - Bar edge (col3): Full brightness for crisp border
    bar_fill_color = lightness(col3, 0.20)  # 20% brightness for bar fill
    label2color = lightness(col3, animprogress / 100)  # Full brightness for text

    labelcomponent = None
    widthmax = canvas.width() - (1 * scale)
    labelcomponent = render.Stack(
        children = [
            render.Text(
                content = label,
                color = label1color,
                font = "terminus-12" if scale == 2 else "tom-thumb",
            ),
            render.Box(width = 2 * scale, height = 6 * scale),
        ],
    )
    widthmax -= 4 * scale

    progresswidth = max(1 * scale, int(widthmax * animpercent / 100))

    progressfill = None
    if animpercent > 0:
        progressfill = render.Row(
            main_align = "start",
            cross_align = "center",
            expanded = True,
            children = [
                render.Box(width = progresswidth, height = 7 * scale, color = bar_fill_color),
                render.Box(width = 1 * scale, height = 7 * scale, color = col3),
            ],
        )

    label2component = None
    label2component = render.Stack(
        children = [
            render.Text(
                content = "{}%".format(int(percent * animprogress / 100)),
                color = label2color,
                font = "terminus-12" if scale == 2 else "tom-thumb",
            ),
        ],
    )

    return render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            labelcomponent,
            render.Stack(
                children = [
                    render.Row(
                        main_align = "start",
                        cross_align = "center",
                        expanded = True,
                        children = [
                            render.Box(width = widthmax, height = 7 * scale, color = col1),
                        ],
                    ),
                    progressfill,
                    render.Row(
                        main_align = label2align,
                        cross_align = "center",
                        expanded = True,
                        children = [
                            render.Box(width = 1 * scale, height = 8 * scale),
                            label2component,
                        ],
                    ),
                    render.Row(
                        main_align = "end",
                        cross_align = "center",
                        expanded = True,
                        children = [
                            render.Image(src = state["image"], width = 6 * scale, height = 7 * scale),
                            render.Image(src = state["state_image"], width = 8 * scale, height = 8 * scale),
                            render.Box(width = 2 * scale, height = 8 * scale),
                        ],
                    ),
                ],
            ),
            render.Box(width = 1 * scale, height = 8 * scale),
        ],
    )

def capanim(input):
    return max(0, min(100, input))

def get_frame(state, fr, config, animprogress, scale):
    children = []

    font_std = "terminus-16" if scale == 2 else "tb-8"

    delay = 0
    color = state["color"]
    if config.bool("carimg", True):
        children.append(
            render.Row(
                expanded = True,
                main_align = "space_around",
                cross_align = "center",
                children = [
                    render.Image(src = state["logo"], width = 20 * scale, height = 15 * scale),
                    render.Marquee(
                        width = 40 * scale,
                        child = render.Text("%s" % state["name"], font = font_std),
                    ),
                ],
            ),
        )
    else:
        children.append(
            render.Row(
                expanded = True,
                main_align = "space_around",
                cross_align = "center",
                children = [
                    render.Marquee(
                        width = 40 * scale,
                        child = render.Text("%s" % state["name"], font = font_std),
                    ),
                ],
            ),
        )
    children.append(
        render_progress_bar(state, "", int(state["batterylevel"]), lightness(color, 0.06), color, capanim((fr - delay) * 3), scale),
    )

    children.append(
        render.Row(
            expanded = True,
            main_align = "center",
            children = [
                render.Text("Range: ", font = font_std),
                render.Box(width = 1 * scale, height = 1 * scale),
                render.Text("%s %s" % (state["range_value"], state["unit"]), font = font_std, color = lightness("#e5a00d", animprogress / 100)),
            ],
        ),
    )

    return render.Column(
        main_align = "space_between",
        cross_align = "center",
        children = children,
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
                id = "battery_entity",
                name = "Battery Level",
                desc = "Entity name for battery level",
                icon = "batteryHalf",
                default = "sensor.tesla_battery_level",
            ),
            schema.Text(
                id = "range_entity",
                name = "Range",
                desc = "Entity name for range",
                icon = "gauge",
                default = "sensor.tesla_est_battery_range",
            ),
            schema.Text(
                id = "name_entity",
                name = "Display Name",
                desc = "Entity name for vehicle display name",
                icon = "tag",
                default = "sensor.tesla_display_name",
            ),
            schema.Text(
                id = "charger_power_entity",
                name = "Charger Power",
                desc = "Entity name for charger power",
                icon = "bolt",
                default = "sensor.tesla_charger_power",
            ),
            schema.Text(
                id = "plugged_in_entity",
                name = "Plugged In",
                desc = "Entity name for plugged in status",
                icon = "plug",
                default = "binary_sensor.tesla_plugged_in",
            ),
            schema.Text(
                id = "charge_limit_entity",
                name = "Charge Limit",
                desc = "Entity name for charge limit",
                icon = "batteryFull",
                default = "sensor.tesla_charge_limit_soc",
            ),
            schema.Dropdown(
                id = "unit",
                name = "Unit",
                desc = "The unit of the 'Range' entity from Home Assistant. Select 'Kilometers (km)' if your sensor already provides range in kilometers.",
                icon = "ruler",
                default = "mi",
                options = [
                    schema.Option(
                        display = "Miles (mi)",
                        value = "mi",
                    ),
                    schema.Option(
                        display = "Kilometers (km)",
                        value = "km",
                    ),
                ],
            ),
            schema.Toggle(
                id = "mi2km",
                name = "Display as KM",
                desc = "Convert range from miles to kilometers for display. Only applies when 'Unit' is set to 'Miles (mi)'.",
                icon = "codeFork",
                default = False,
            ),
            schema.Toggle(
                id = "carimg",
                name = "Car Image",
                desc = "Show car image",
                icon = "car",
                default = True,
            ),
            schema.Text(
                id = "cache_duration",
                name = "Cache Duration",
                desc = "How long to cache data from Home Assistant (in seconds)",
                icon = "clock",
                default = str(DEFAULT_CACHE_DURATION),
            ),
            schema.Color(
                id = "color_10",
                name = "Color at 10%",
                desc = "Battery color when at 10% or below",
                icon = "palette",
                default = "#FF0000",
            ),
            schema.Color(
                id = "color_20",
                name = "Color at 20%",
                desc = "Battery color when at 20%",
                icon = "palette",
                default = "#FF8000",
            ),
            schema.Color(
                id = "color_30",
                name = "Color at 30%",
                desc = "Battery color when at 30%",
                icon = "palette",
                default = "#FFFF00",
            ),
            schema.Color(
                id = "color_50",
                name = "Color at 50%",
                desc = "Battery color when at 50%",
                icon = "palette",
                default = "#00FF00",
            ),
            schema.Color(
                id = "color_80",
                name = "Color at 80%",
                desc = "Battery color when at 80% and above",
                icon = "palette",
                default = "#00AAFF",
            ),
        ],
    )
