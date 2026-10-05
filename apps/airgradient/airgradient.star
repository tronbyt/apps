"""
Applet: AirGradient
Summary: AirGradient ONE monitor
Description: Interfaces with an AirGradient ONE indoor air quality monitor via direct local network or Home Assistant, capturing the LED bar and screen metrics.
Author: brombomb
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")

# Default mock data matching the AirGradient ONE (I-9PSL)
DEFAULT_DATA = {
    "rco2": 708,
    "pm02": 0.5,
    "pm02Compensated": 2.7,
    "atmp": 23.5,
    "atmpCompensated": 23.5,
    "rhum": 38.0,
    "rhumCompensated": 38.0,
    "tvocIndex": 35,
    "noxIndex": 1,
    "wifi": -65,
    "ledMode": "co2",
    "serialno": "34b7da9f7894",
    "firmware": "3.7.0",
    "model": "I-9PSL",
}

# Color palettes
COLOR_LED_GREEN = "#00E640"
COLOR_LED_YELLOW = "#FFE600"
COLOR_LED_ORANGE = "#FF8C00"
COLOR_LED_RED = "#FF2828"
COLOR_LED_PURPLE = "#B418FF"
COLOR_LED_OFF = "#181b1f"
COLOR_STATUS_OFF = "#121417"
COLOR_STATUS_ERR = "#FF2828"

# Block colors for section backgrounds
BLOCK_GREEN = "#00A638"
BLOCK_YELLOW = "#CCA300"
BLOCK_ORANGE = "#CC5C00"
BLOCK_RED = "#CC2222"
BLOCK_PURPLE = "#8F10D4"

# Ambient full-screen background tints
AMBIENT_GREEN = "#002E12"
AMBIENT_YELLOW = "#382900"
AMBIENT_ORANGE = "#3D1600"
AMBIENT_RED = "#3D0808"
AMBIENT_PURPLE = "#2A063A"

COLOR_TEXT_WHITE = "#FFFFFF"
COLOR_TEXT_DIM = "#8A929B"
COLOR_TEXT_SUBTLE = "#555A60"
COLOR_DIVIDER = "#24272D"
COLOR_BG = "#000000"

def get_co2_level(co2):
    if co2 <= 600:
        return 1, COLOR_LED_GREEN
    elif co2 <= 800:
        return 2, COLOR_LED_GREEN
    elif co2 <= 1000:
        return 3, COLOR_LED_YELLOW
    elif co2 <= 1250:
        return 4, COLOR_LED_ORANGE
    elif co2 <= 1500:
        return 5, COLOR_LED_ORANGE
    elif co2 <= 1750:
        return 6, COLOR_LED_RED
    elif co2 <= 2000:
        return 7, COLOR_LED_RED
    elif co2 <= 3000:
        return 8, COLOR_LED_PURPLE
    else:
        return 9, COLOR_LED_PURPLE

def get_pm25_level(pm25):
    if pm25 <= 5:
        return 1, COLOR_LED_GREEN
    elif pm25 <= 9:
        return 2, COLOR_LED_GREEN
    elif pm25 <= 20:
        return 3, COLOR_LED_YELLOW
    elif pm25 <= 35:
        return 4, COLOR_LED_YELLOW
    elif pm25 <= 45:
        return 5, COLOR_LED_ORANGE
    elif pm25 <= 55:
        return 6, COLOR_LED_ORANGE
    elif pm25 <= 100:
        return 7, COLOR_LED_RED
    elif pm25 <= 125:
        return 8, COLOR_LED_RED
    elif pm25 <= 225:
        return 9, COLOR_LED_PURPLE
    else:
        return 9, COLOR_LED_PURPLE

def get_iaqs_level(co2, pm25):
    co2_lvl, _ = get_co2_level(co2)
    pm_lvl, _ = get_pm25_level(pm25)
    worst = co2_lvl if co2_lvl > pm_lvl else pm_lvl
    if worst <= 2:
        return worst, COLOR_LED_GREEN
    elif worst <= 4:
        return worst, COLOR_LED_YELLOW
    elif worst <= 6:
        return worst, COLOR_LED_ORANGE
    elif worst <= 8:
        return worst, COLOR_LED_RED
    else:
        return 9, COLOR_LED_PURPLE

def get_block_palette(level):
    if level <= 2:
        return BLOCK_GREEN, "#000000"
    elif level <= 4:
        return BLOCK_YELLOW, "#000000"
    elif level <= 6:
        return BLOCK_ORANGE, "#FFFFFF"
    elif level <= 8:
        return BLOCK_RED, "#FFFFFF"
    else:
        return BLOCK_PURPLE, "#FFFFFF"

def get_ambient_bg(level):
    if level <= 2:
        return AMBIENT_GREEN
    elif level <= 4:
        return AMBIENT_YELLOW
    elif level <= 6:
        return AMBIENT_ORANGE
    elif level <= 8:
        return AMBIENT_RED
    else:
        return AMBIENT_PURPLE

def calculate_led_bar(co2, pm25, led_mode, device_mode, direction_rtl, has_error):
    mode = led_mode
    if mode == "auto":
        mode = device_mode if device_mode in ["co2", "pm", "iaqs", "off"] else "co2"

    count = 0
    tier_color = COLOR_LED_GREEN
    level = 1

    if mode == "co2":
        level, tier_color = get_co2_level(co2)
        count = level
    elif mode == "pm":
        level, tier_color = get_pm25_level(pm25)
        count = level
    elif mode == "iaqs":
        level, tier_color = get_iaqs_level(co2, pm25)
        count = level
    elif mode == "off":
        count = 0

    leds = []
    is_extreme = (mode == "co2" and co2 > 3000) or (mode == "pm" and pm25 > 225)

    for i in range(9):
        active = False
        if direction_rtl:
            if i >= (9 - count):
                active = True
        elif i < count:
            active = True

        if active:
            if is_extreme:
                c = COLOR_LED_PURPLE if i % 2 == 0 else COLOR_LED_RED
            else:
                c = tier_color
            leds.append(c)
        else:
            leds.append(COLOR_LED_OFF)

    status_color = COLOR_STATUS_ERR if has_error else COLOR_STATUS_OFF
    return status_color, leds, level

def normalize_url(url):
    cleaned = url.strip()
    if cleaned.endswith("/"):
        cleaned = cleaned[:-1]
    if not cleaned.startswith("http://") and not cleaned.startswith("https://"):
        cleaned = "http://" + cleaned
    if not cleaned.endswith("/measures/current"):
        cleaned = cleaned + "/measures/current"
    return cleaned

def fetch_direct_data(device_url):
    target = normalize_url(device_url)
    resp = http.get(target, ttl_seconds = 10)
    if resp.status_code == 200:
        return resp.json(), False

    # Try fallback to standard hostnames
    if "192.168.1.27" in target:
        fallback_resp = http.get("http://air.gradient.lan/measures/current", ttl_seconds = 10)
        if fallback_resp.status_code == 200:
            return fallback_resp.json(), False
    elif "air.gradient.lan" in target:
        fallback_resp = http.get("http://192.168.1.27/measures/current", ttl_seconds = 10)
        if fallback_resp.status_code == 200:
            return fallback_resp.json(), False

    return DEFAULT_DATA, True

def fetch_ha_data(ha_url, ha_token, prefix, co2_override, pm25_override, temp_override, hum_override, tvoc_override, nox_override):
    if not ha_token or ha_token == "APIKEY":
        return DEFAULT_DATA, False

    base_url = ha_url.strip().rstrip("/")
    template_url = base_url + "/api/template"
    headers = {
        "Authorization": "Bearer " + ha_token,
        "Content-Type": "application/json",
    }

    p = prefix if prefix else "airgradient_one"
    co2_e = co2_override if co2_override else "sensor.%s_co2" % p
    pm_e = pm25_override if pm25_override else "sensor.%s_pm2_5" % p
    temp_e = temp_override if temp_override else "sensor.%s_temperature" % p
    hum_e = hum_override if hum_override else "sensor.%s_humidity" % p
    tvoc_e = tvoc_override if tvoc_override else "sensor.%s_tvoc_index" % p
    nox_e = nox_override if nox_override else "sensor.%s_nox_index" % p

    jinja = """
{
  "rco2": {{ states('%(co2)s') | float(0) }},
  "pm02": {{ states('%(pm)s') | float(0) }},
  "atmp": {{ states('%(temp)s') | float(0) }},
  "rhum": {{ states('%(hum)s') | float(0) }},
  "tvocIndex": {{ states('%(tvoc)s') | float(0) }},
  "noxIndex": {{ states('%(nox)s') | float(0) }}
}
""" % {
        "co2": co2_e,
        "pm": pm_e,
        "temp": temp_e,
        "hum": hum_e,
        "tvoc": tvoc_e,
        "nox": nox_e,
    }

    resp = http.post(template_url, headers = headers, json_body = {"template": jinja}, ttl_seconds = 10)
    if resp.status_code == 200:
        data = json.decode(resp.body())
        data["ledMode"] = "co2"
        return data, False

    return DEFAULT_DATA, True

def format_number(val):
    int_val = int(math.round(val))
    return str(int_val)

def format_pm(val):
    if val < 10:
        r = math.round(val * 10) / 10.0
        s = str(r)
        if s.endswith(".0"):
            s = s[:-2]
        return s
    return str(int(math.round(val)))

def render_led_bar_1x(status_color, leds):
    pollutant_children = []
    for i in range(9):
        pollutant_children.append(
            render.Box(
                width = 3,
                height = 2,
                color = leds[i],
            ),
        )
        if i < 8:
            pollutant_children.append(render.Box(width = 1, height = 2, color = COLOR_BG))

    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            render.Padding(
                pad = (2, 0, 0, 0),
                child = render.Box(width = 2, height = 2, color = status_color),
            ),
            render.Padding(
                pad = (0, 0, 2, 0),
                child = render.Row(children = pollutant_children),
            ),
        ],
    )

def render_led_bar_2x(status_color, leds):
    pollutant_children = []
    for i in range(9):
        pollutant_children.append(
            render.Box(
                width = 7,
                height = 4,
                color = leds[i],
            ),
        )
        if i < 8:
            pollutant_children.append(render.Box(width = 2, height = 4, color = COLOR_BG))

    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            render.Padding(
                pad = (4, 0, 0, 0),
                child = render.Box(width = 4, height = 4, color = status_color),
            ),
            render.Padding(
                pad = (0, 0, 4, 0),
                child = render.Row(children = pollutant_children),
            ),
        ],
    )

def render_dashboard_1x(temp_str, hum_str, co2_str, pm_str, voc_str, nox_str, co2_color, pm_color, use_color, col_height):
    c_co2 = co2_color if use_color else COLOR_TEXT_WHITE
    c_pm = pm_color if use_color else COLOR_TEXT_WHITE

    return render.Column(
        children = [
            # Top header row: Temp & Humidity
            render.Padding(
                pad = (2, 0, 2, 0),
                child = render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "center",
                    children = [
                        render.Text(temp_str, font = "tom-thumb", color = COLOR_TEXT_WHITE),
                        render.Text(hum_str, font = "tom-thumb", color = COLOR_TEXT_WHITE),
                    ],
                ),
            ),
            # Divider line
            render.Box(width = 64, height = 1, color = COLOR_DIVIDER),
            # Main 3 Columns
            render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    # Col 1: CO2
                    render.Padding(
                        pad = (2, 0, 0, 0),
                        child = render.Column(
                            cross_align = "start",
                            children = [
                                render.Text("CO2", font = "CG-pixel-3x5-mono", color = COLOR_TEXT_DIM),
                                render.Text(co2_str, font = "tb-8", color = c_co2),
                                render.Text("ppm", font = "CG-pixel-3x5-mono", color = COLOR_TEXT_SUBTLE),
                            ],
                        ),
                    ),
                    # Vertical separator
                    render.Box(width = 1, height = col_height, color = COLOR_DIVIDER),
                    # Col 2: PM2.5
                    render.Column(
                        cross_align = "start",
                        children = [
                            render.Text("PM2.5", font = "CG-pixel-3x5-mono", color = COLOR_TEXT_DIM),
                            render.Text(pm_str, font = "tb-8", color = c_pm),
                            render.Text("ug/m3", font = "CG-pixel-3x5-mono", color = COLOR_TEXT_SUBTLE),
                        ],
                    ),
                    # Vertical separator
                    render.Box(width = 1, height = col_height, color = COLOR_DIVIDER),
                    # Col 3: VOC & NOx
                    render.Padding(
                        pad = (0, 0, 2, 0),
                        child = render.Column(
                            cross_align = "start",
                            children = [
                                render.Text("VOC", font = "CG-pixel-3x5-mono", color = COLOR_TEXT_DIM),
                                render.Text(voc_str, font = "tom-thumb", color = COLOR_TEXT_WHITE),
                                render.Text("NOx", font = "CG-pixel-3x5-mono", color = COLOR_TEXT_DIM),
                                render.Text(nox_str, font = "tom-thumb", color = COLOR_TEXT_WHITE),
                            ],
                        ),
                    ),
                ],
            ),
        ],
    )

def render_big_numbers_1x(temp_str, hum_str, co2_str, pm_str, voc_str, nox_str, co2_color, pm_color, use_color):
    c_co2 = co2_color if use_color else COLOR_TEXT_WHITE
    c_pm = pm_color if use_color else COLOR_TEXT_WHITE

    return render.Column(
        children = [
            # Top header: Temp and Humidity
            render.Padding(
                pad = (2, 0, 2, 0),
                child = render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "center",
                    children = [
                        render.Text(temp_str, font = "tom-thumb", color = COLOR_TEXT_WHITE),
                        render.Text(hum_str, font = "tom-thumb", color = COLOR_TEXT_WHITE),
                    ],
                ),
            ),
            render.Box(width = 64, height = 1, color = COLOR_DIVIDER),
            # Big split cards
            render.Row(
                expanded = True,
                main_align = "space_around",
                children = [
                    # CO2 card
                    render.Box(
                        width = 31,
                        height = 16,
                        child = render.Row(
                            cross_align = "center",
                            main_align = "center",
                            children = [
                                render.Text(co2_str, font = "6x10", color = c_co2),
                                render.Padding(
                                    pad = (1, 3, 0, 0),
                                    child = render.Text("ppm", font = "CG-pixel-3x5-mono", color = COLOR_TEXT_SUBTLE),
                                ),
                            ],
                        ),
                    ),
                    render.Box(width = 1, height = 16, color = COLOR_DIVIDER),
                    # PM2.5 card
                    render.Box(
                        width = 31,
                        height = 16,
                        child = render.Row(
                            cross_align = "center",
                            main_align = "center",
                            children = [
                                render.Text(pm_str, font = "6x10", color = c_pm),
                                render.Padding(
                                    pad = (1, 3, 0, 0),
                                    child = render.Text("ug", font = "CG-pixel-3x5-mono", color = COLOR_TEXT_SUBTLE),
                                ),
                            ],
                        ),
                    ),
                ],
            ),
            render.Box(width = 64, height = 1, color = COLOR_DIVIDER),
            # Bottom row: VOC & NOx
            render.Padding(
                pad = (3, 0, 3, 0),
                child = render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "center",
                    children = [
                        render.Row(
                            children = [
                                render.Text("VOC ", font = "CG-pixel-3x5-mono", color = COLOR_TEXT_DIM),
                                render.Text(voc_str, font = "CG-pixel-3x5-mono", color = COLOR_TEXT_WHITE),
                            ],
                        ),
                        render.Row(
                            children = [
                                render.Text("NOx ", font = "CG-pixel-3x5-mono", color = COLOR_TEXT_DIM),
                                render.Text(nox_str, font = "CG-pixel-3x5-mono", color = COLOR_TEXT_WHITE),
                            ],
                        ),
                    ],
                ),
            ),
        ],
    )

def render_color_blocks_1x(temp_str, hum_str, co2_str, pm_str, voc_str, nox_str, co2_lvl, pm_lvl, block_h):
    co2_bg, co2_fg = get_block_palette(co2_lvl)
    pm_bg, pm_fg = get_block_palette(pm_lvl)

    return render.Column(
        children = [
            # Header
            render.Padding(
                pad = (2, 0, 2, 0),
                child = render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "center",
                    children = [
                        render.Text(temp_str, font = "tom-thumb", color = COLOR_TEXT_WHITE),
                        render.Text(hum_str, font = "tom-thumb", color = COLOR_TEXT_WHITE),
                    ],
                ),
            ),
            render.Box(width = 64, height = 1, color = COLOR_DIVIDER),
            # 3 Color Block Tiles
            render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    # CO2 Section Box
                    render.Box(
                        width = 23,
                        height = block_h,
                        color = co2_bg,
                        child = render.Column(
                            cross_align = "center",
                            main_align = "space_around",
                            children = [
                                render.Text("CO2", font = "CG-pixel-3x5-mono", color = co2_fg),
                                render.Text(co2_str, font = "tb-8", color = co2_fg),
                                render.Text("ppm", font = "CG-pixel-3x5-mono", color = co2_fg),
                            ],
                        ),
                    ),
                    render.Box(width = 1, height = block_h, color = COLOR_BG),
                    # PM2.5 Section Box
                    render.Box(
                        width = 23,
                        height = block_h,
                        color = pm_bg,
                        child = render.Column(
                            cross_align = "center",
                            main_align = "space_around",
                            children = [
                                render.Text("PM2.5", font = "CG-pixel-3x5-mono", color = pm_fg),
                                render.Text(pm_str, font = "tb-8", color = pm_fg),
                                render.Text("ug/m3", font = "CG-pixel-3x5-mono", color = pm_fg),
                            ],
                        ),
                    ),
                    render.Box(width = 1, height = block_h, color = COLOR_BG),
                    # VOC / NOx Box
                    render.Box(
                        width = 16,
                        height = block_h,
                        color = "#16191E",
                        child = render.Column(
                            cross_align = "center",
                            main_align = "space_around",
                            children = [
                                render.Text("VOC", font = "CG-pixel-3x5-mono", color = COLOR_TEXT_DIM),
                                render.Text(voc_str, font = "tom-thumb", color = COLOR_TEXT_WHITE),
                                render.Text("NOx", font = "CG-pixel-3x5-mono", color = COLOR_TEXT_DIM),
                                render.Text(nox_str, font = "tom-thumb", color = COLOR_TEXT_WHITE),
                            ],
                        ),
                    ),
                ],
            ),
        ],
    )

def render_dashboard_2x(temp_str, hum_str, co2_str, pm_str, voc_str, nox_str, co2_color, pm_color, use_color, col_height):
    c_co2 = co2_color if use_color else COLOR_TEXT_WHITE
    c_pm = pm_color if use_color else COLOR_TEXT_WHITE

    return render.Column(
        children = [
            # Top header row: Temp & Humidity
            render.Padding(
                pad = (4, 1, 4, 1),
                child = render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "center",
                    children = [
                        render.Text(temp_str, font = "tb-8", color = COLOR_TEXT_WHITE),
                        render.Row(
                            cross_align = "center",
                            children = [
                                render.Text("AIRGRADIENT ONE", font = "CG-pixel-3x5-mono", color = COLOR_TEXT_SUBTLE),
                            ],
                        ),
                        render.Text(hum_str, font = "tb-8", color = COLOR_TEXT_WHITE),
                    ],
                ),
            ),
            # Divider line
            render.Box(width = 128, height = 1, color = COLOR_DIVIDER),
            # Main 3 Columns at 2x resolution
            render.Row(
                expanded = True,
                children = [
                    # Col 1: CO2
                    render.Box(
                        width = 46,
                        height = col_height,
                        child = render.Column(
                            cross_align = "start",
                            main_align = "space_around",
                            children = [
                                render.Text("CO2", font = "tb-8", color = COLOR_TEXT_DIM),
                                render.Text(co2_str, font = "terminus-16", color = c_co2),
                                render.Text("ppm", font = "tb-8", color = COLOR_TEXT_SUBTLE),
                            ],
                        ),
                    ),
                    render.Box(width = 1, height = col_height, color = COLOR_DIVIDER),
                    # Col 2: PM2.5
                    render.Box(
                        width = 46,
                        height = col_height,
                        child = render.Padding(
                            pad = (3, 0, 0, 0),
                            child = render.Column(
                                cross_align = "start",
                                main_align = "space_around",
                                children = [
                                    render.Text("PM2.5", font = "tb-8", color = COLOR_TEXT_DIM),
                                    render.Text(pm_str, font = "terminus-16", color = c_pm),
                                    render.Text("ug/m3", font = "tb-8", color = COLOR_TEXT_SUBTLE),
                                ],
                            ),
                        ),
                    ),
                    render.Box(width = 1, height = col_height, color = COLOR_DIVIDER),
                    # Col 3: VOC & NOx
                    render.Box(
                        width = 34,
                        height = col_height,
                        child = render.Padding(
                            pad = (4, 0, 0, 0),
                            child = render.Column(
                                cross_align = "start",
                                main_align = "space_around",
                                children = [
                                    render.Text("VOC:", font = "tb-8", color = COLOR_TEXT_DIM),
                                    render.Text(voc_str, font = "tb-8", color = COLOR_TEXT_WHITE),
                                    render.Text("NOx:", font = "tb-8", color = COLOR_TEXT_DIM),
                                    render.Text(nox_str, font = "tb-8", color = COLOR_TEXT_WHITE),
                                ],
                            ),
                        ),
                    ),
                ],
            ),
        ],
    )

def render_color_blocks_2x(temp_str, hum_str, co2_str, pm_str, voc_str, nox_str, co2_lvl, pm_lvl, block_h):
    co2_bg, co2_fg = get_block_palette(co2_lvl)
    pm_bg, pm_fg = get_block_palette(pm_lvl)

    return render.Column(
        children = [
            # Top header row: Temp & Humidity
            render.Padding(
                pad = (4, 1, 4, 1),
                child = render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "center",
                    children = [
                        render.Text(temp_str, font = "tb-8", color = COLOR_TEXT_WHITE),
                        render.Text("AIRGRADIENT ONE", font = "CG-pixel-3x5-mono", color = COLOR_TEXT_SUBTLE),
                        render.Text(hum_str, font = "tb-8", color = COLOR_TEXT_WHITE),
                    ],
                ),
            ),
            # Divider line
            render.Box(width = 128, height = 1, color = COLOR_DIVIDER),
            # Main 3 Color Blocks
            render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    # Col 1: CO2
                    render.Box(
                        width = 46,
                        height = block_h,
                        color = co2_bg,
                        child = render.Column(
                            cross_align = "center",
                            main_align = "space_around",
                            children = [
                                render.Text("CO2", font = "tb-8", color = co2_fg),
                                render.Text(co2_str, font = "terminus-16", color = co2_fg),
                                render.Text("ppm", font = "tb-8", color = co2_fg),
                            ],
                        ),
                    ),
                    render.Box(width = 1, height = block_h, color = COLOR_BG),
                    # Col 2: PM2.5
                    render.Box(
                        width = 46,
                        height = block_h,
                        color = pm_bg,
                        child = render.Column(
                            cross_align = "center",
                            main_align = "space_around",
                            children = [
                                render.Text("PM2.5", font = "tb-8", color = pm_fg),
                                render.Text(pm_str, font = "terminus-16", color = pm_fg),
                                render.Text("ug/m3", font = "tb-8", color = pm_fg),
                            ],
                        ),
                    ),
                    render.Box(width = 1, height = block_h, color = COLOR_BG),
                    # Col 3: VOC & NOx
                    render.Box(
                        width = 34,
                        height = block_h,
                        color = "#16191E",
                        child = render.Column(
                            cross_align = "center",
                            main_align = "space_around",
                            children = [
                                render.Text("VOC", font = "tb-8", color = COLOR_TEXT_DIM),
                                render.Text(voc_str, font = "tb-8", color = COLOR_TEXT_WHITE),
                                render.Text("NOx", font = "tb-8", color = COLOR_TEXT_DIM),
                                render.Text(nox_str, font = "tb-8", color = COLOR_TEXT_WHITE),
                            ],
                        ),
                    ),
                ],
            ),
        ],
    )

def main(config):
    source = config.get("source", "direct")
    device_url = config.get("device_url", "http://192.168.1.27")
    temp_unit = config.get("temp_unit", "f")
    display_mode = config.get("display_mode", "classic")
    show_led_bar = config.bool("show_led_bar", True)
    led_mode = config.get("led_mode", "auto")
    direction_rtl = config.bool("direction_rtl", True)
    use_color = config.bool("use_color", True)

    # If led_mode is explicitly off, hide the bar completely (no gray dots)
    if led_mode == "off":
        show_led_bar = False

    # Fetch data
    if source == "homeassistant":
        ha_url = config.get("ha_url", "http://homeassistant.local:8123")
        ha_token = config.get("ha_token", "")
        ha_prefix = config.get("ha_prefix", "airgradient_one")
        co2_ov = config.get("ha_co2_entity", "")
        pm_ov = config.get("ha_pm25_entity", "")
        temp_ov = config.get("ha_temp_entity", "")
        hum_ov = config.get("ha_hum_entity", "")
        tvoc_ov = config.get("ha_tvoc_entity", "")
        nox_ov = config.get("ha_nox_entity", "")
        data, has_error = fetch_ha_data(ha_url, ha_token, ha_prefix, co2_ov, pm_ov, temp_ov, hum_ov, tvoc_ov, nox_ov)
    else:
        data, has_error = fetch_direct_data(device_url)

    # Extract metrics
    co2_raw = data.get("rco2", 0)
    co2 = int(math.round(co2_raw)) if co2_raw else 0

    pm25_comp = data.get("pm02Compensated")
    pm25_raw = data.get("pm02", 0)
    pm25 = float(pm25_comp if pm25_comp != None and pm25_comp > 0 else pm25_raw)

    atmp_raw = data.get("atmpCompensated") or data.get("atmp", 20.0)
    rhum_raw = data.get("rhumCompensated") or data.get("rhum", 40.0)
    tvoc_raw = data.get("tvocIndex", 0)
    nox_raw = data.get("noxIndex", 0)
    device_led_mode = data.get("ledMode", "co2")

    # Smart Temperature handling: check if input is already Fahrenheit
    temp_val = float(atmp_raw)
    if temp_val > 45:
        # Already Fahrenheit
        if temp_unit == "c":
            temp_c = (temp_val - 32.0) * 5.0 / 9.0
            temp_str = "%s°C" % format_number(temp_c)
        else:
            temp_str = "%s°F" % format_number(temp_val)
    else:
        # In Celsius
        if temp_unit == "c":
            temp_str = "%s°C" % format_number(temp_val)
        else:
            temp_f = (temp_val * 9.0 / 5.0) + 32.0
            temp_str = "%s°F" % format_number(temp_f)

    hum_str = "%s%%" % format_number(rhum_raw)
    co2_str = format_number(co2)
    pm_str = format_pm(pm25)
    voc_str = format_number(tvoc_raw)
    nox_str = format_number(nox_raw)

    # Compute LED bar colors and states
    status_color, leds, led_level = calculate_led_bar(co2, pm25, led_mode, device_led_mode, direction_rtl, has_error)

    # Air quality color accents
    co2_lvl, co2_color = get_co2_level(co2)
    pm_lvl, pm_color = get_pm25_level(pm25)

    is2x = canvas.is2x()
    width, height = canvas.size()

    # Determine canvas background color
    canvas_bg = COLOR_BG
    if display_mode == "ambient":
        canvas_bg = get_ambient_bg(led_level)

    # Build layout children
    children = []

    if is2x:
        col_height = 46 if show_led_bar else 52
        if show_led_bar:
            children.append(render_led_bar_2x(status_color, leds))
            children.append(render.Box(width = width, height = 1, color = canvas_bg))

        if display_mode == "blocks":
            body = render_color_blocks_2x(temp_str, hum_str, co2_str, pm_str, voc_str, nox_str, co2_lvl, pm_lvl, col_height)
        else:
            body = render_dashboard_2x(temp_str, hum_str, co2_str, pm_str, voc_str, nox_str, co2_color, pm_color, use_color, col_height)
        children.append(body)
    else:
        col_height = 21 if show_led_bar else 24
        if show_led_bar:
            children.append(render_led_bar_1x(status_color, leds))
            children.append(render.Box(width = width, height = 1, color = canvas_bg))

        if display_mode == "big":
            body = render_big_numbers_1x(temp_str, hum_str, co2_str, pm_str, voc_str, nox_str, co2_color, pm_color, use_color)
        elif display_mode == "blocks":
            body = render_color_blocks_1x(temp_str, hum_str, co2_str, pm_str, voc_str, nox_str, co2_lvl, pm_lvl, col_height)
        else:
            body = render_dashboard_1x(temp_str, hum_str, co2_str, pm_str, voc_str, nox_str, co2_color, pm_color, use_color, col_height)
        children.append(body)

    return render.Root(
        max_age = 15,
        child = render.Box(
            width = width,
            height = height,
            color = canvas_bg,
            child = render.Column(
                children = children,
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "source",
                name = "Data Source",
                desc = "Choose how to connect to your AirGradient ONE",
                icon = "plug",
                default = "direct",
                options = [
                    schema.Option(display = "Direct Local (AirGradient ONE)", value = "direct"),
                    schema.Option(display = "Home Assistant", value = "homeassistant"),
                ],
            ),
            schema.Text(
                id = "device_url",
                name = "AirGradient Device URL / IP",
                desc = "IP address or hostname of your AirGradient monitor (e.g. http://192.168.1.27 or http://air.gradient.lan)",
                icon = "networkWired",
                default = "http://192.168.1.27",
            ),
            schema.Dropdown(
                id = "display_mode",
                name = "Display Mode",
                desc = "Screen layout style for the Tronbyt display",
                icon = "tableColumns",
                default = "classic",
                options = [
                    schema.Option(display = "AirGradient ONE (Classic 3-Column)", value = "classic"),
                    schema.Option(display = "Big Numbers (Across the Room)", value = "big"),
                    schema.Option(display = "Color Blocks (Section Backgrounds)", value = "blocks"),
                    schema.Option(display = "Ambient (Full Background Color)", value = "ambient"),
                ],
            ),
            schema.Toggle(
                id = "show_led_bar",
                name = "Show LED Bar",
                desc = "Display the 11-LED bar along the top. Turn off to completely hide it without gray dots.",
                icon = "lightbulb",
                default = True,
            ),
            schema.Dropdown(
                id = "temp_unit",
                name = "Temperature Unit",
                desc = "Select temperature format",
                icon = "temperatureHalf",
                default = "f",
                options = [
                    schema.Option(display = "Fahrenheit (°F)", value = "f"),
                    schema.Option(display = "Celsius (°C)", value = "c"),
                ],
            ),
            schema.Dropdown(
                id = "led_mode",
                name = "LED Bar Metric",
                desc = "Pollutant represented on the top LED bar",
                icon = "sliders",
                default = "auto",
                options = [
                    schema.Option(display = "Auto (from Monitor Settings)", value = "auto"),
                    schema.Option(display = "CO2", value = "co2"),
                    schema.Option(display = "PM2.5", value = "pm"),
                    schema.Option(display = "IAQS (Air Quality Score)", value = "iaqs"),
                    schema.Option(display = "Off", value = "off"),
                ],
            ),
            schema.Toggle(
                id = "direction_rtl",
                name = "Physical LED Direction (R to L)",
                desc = "Light up from right to left matching physical AirGradient hardware",
                icon = "arrowLeft",
                default = True,
            ),
            schema.Toggle(
                id = "use_color",
                name = "Air Quality Color Accents",
                desc = "Color code the readings (Green/Yellow/Orange/Red/Purple) for easy reading across the room",
                icon = "palette",
                default = True,
            ),
            schema.Text(
                id = "ha_url",
                name = "Home Assistant URL",
                desc = "Base URL of Home Assistant (e.g. http://homeassistant.local:8123)",
                icon = "server",
                default = "http://homeassistant.local:8123",
            ),
            schema.Text(
                id = "ha_token",
                name = "Home Assistant Token",
                desc = "Long-Lived Access Token for Home Assistant",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "ha_prefix",
                name = "Home Assistant Entity Prefix",
                desc = "Prefix for sensors (e.g. airgradient_one for sensor.airgradient_one_co2)",
                icon = "tag",
                default = "airgradient_one",
            ),
            schema.Text(
                id = "ha_co2_entity",
                name = "Custom CO2 Entity (optional)",
                desc = "Override entity ID for CO2 (e.g. sensor.living_room_co2)",
                icon = "smog",
            ),
            schema.Text(
                id = "ha_pm25_entity",
                name = "Custom PM2.5 Entity (optional)",
                desc = "Override entity ID for PM2.5 (e.g. sensor.living_room_pm2_5)",
                icon = "wind",
            ),
            schema.Text(
                id = "ha_temp_entity",
                name = "Custom Temp Entity (optional)",
                desc = "Override entity ID for Temperature",
                icon = "temperatureHalf",
            ),
            schema.Text(
                id = "ha_hum_entity",
                name = "Custom Humidity Entity (optional)",
                desc = "Override entity ID for Humidity",
                icon = "droplet",
            ),
            schema.Text(
                id = "ha_tvoc_entity",
                name = "Custom TVOC Entity (optional)",
                desc = "Override entity ID for TVOC",
                icon = "flask",
            ),
            schema.Text(
                id = "ha_nox_entity",
                name = "Custom NOx Entity (optional)",
                desc = "Override entity ID for NOx",
                icon = "biohazard",
            ),
        ],
    )
