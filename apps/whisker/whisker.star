"""
Applet: Whisker
Summary: Monitor Litter-Robot status
Description: Ambient desk gauge for Litter-Robot tracking waste drawer level, cycle status, and cat visits.
Author: brombomb
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/whisker_icon.png", WHISKER_ICON_ASSET = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")

WHISKER_BLUE = "#41bdf5"
GREEN = "#00ff66"
RED = "#ff3333"
YELLOW = "#ffcc00"
ORANGE = "#ff9900"
CYAN = "#00e5ff"
WHITE = "#ffffff"
MUTED = "#8899aa"
BG_COLOR = "#000000"

SAMPLE_DATA = {
    "name": "Litter-Robot",
    "waste_level": 62,
    "status": "Ready",
    "status_code": "ready",
    "pet_weight": "10.4 lbs",
}

def clean_status(raw_status):
    s = raw_status.lower().replace("_", " ").strip()
    if "clean" in s or "cycl" in s:
        return {"label": "CYCLING", "color": CYAN, "bg": "#002b33"}
    elif "full" in s:
        return {"label": "FULL", "color": RED, "bg": "#330000"}
    elif "cat" in s or "detect" in s or "timing" in s:
        return {"label": "OCCUPIED", "color": ORANGE, "bg": "#331800"}
    elif "pause" in s:
        return {"label": "PAUSED", "color": YELLOW, "bg": "#332b00"}
    elif "ready" in s or "normal" in s:
        return {"label": "READY", "color": GREEN, "bg": "#002b11"}
    elif "off" in s or "sleep" in s:
        return {"label": "SLEEP", "color": MUTED, "bg": "#111822"}
    return {"label": s.upper()[:8], "color": WHITE, "bg": "#111822"}

def fetch_ha_entity(ha_url, ha_token, entity_id):
    if not entity_id or entity_id.strip() == "":
        return None

    clean_url = ha_url.strip()
    if clean_url.endswith("/"):
        clean_url = clean_url[:-1]

    endpoint = clean_url + "/api/states/" + entity_id.strip()
    cache_key = "ha_state_" + endpoint
    cached = cache.get(cache_key)
    if cached:
        return json.decode(cached)

    headers = {
        "Authorization": "Bearer " + ha_token.strip(),
        "Content-Type": "application/json",
        "User-Agent": "Tronbyt-Whisker",
    }

    res = http.get(endpoint, headers = headers, ttl_seconds = 30)
    if res.status_code != 200:
        return None

    data = res.json()
    cache.set(cache_key, json.encode(data), ttl_seconds = 30)
    return data

def fetch_whisker_data(ha_url, ha_token, waste_id, status_id, pet_id):
    if not ha_url or not ha_token or ha_url.strip() == "" or ha_token.strip() == "":
        return SAMPLE_DATA

    waste_data = fetch_ha_entity(ha_url, ha_token, waste_id)
    if not waste_data:
        return None

    raw_state = waste_data.get("state", "0")
    waste_pct = int(float(raw_state)) if raw_state.replace(".", "", 1).isdigit() else 0

    status_str = "Ready"
    if status_id and status_id.strip() != "":
        st_data = fetch_ha_entity(ha_url, ha_token, status_id)
        if st_data:
            status_str = st_data.get("state", "Ready")

    pet_str = ""
    if pet_id and pet_id.strip() != "":
        pet_data = fetch_ha_entity(ha_url, ha_token, pet_id)
        if pet_data:
            state_val = pet_data.get("state", "")
            unit = pet_data.get("attributes", {}).get("unit_of_measurement", "lbs")
            if state_val and state_val != "unavailable":
                pet_str = "%s %s" % (state_val, unit)

    return {
        "name": waste_data.get("attributes", {}).get("friendly_name", "Litter-Robot").replace(" Waste Drawer", "").replace(" Waste", ""),
        "waste_level": waste_pct,
        "status": status_str,
        "pet_weight": pet_str,
    }

def render_whisker_gauge(scale, width, data, whisker_icon, cat_name, font_title, font_main, font_tiny):
    icon_width = 12 * scale
    icon_height = 10 * scale

    st_meta = clean_status(data["status"])
    waste_pct = data["waste_level"]

    if waste_pct >= 85 or st_meta["label"] == "FULL":
        bar_color = RED
    elif waste_pct >= 70:
        bar_color = ORANGE
    else:
        bar_color = GREEN

    header = render.Row(
        expanded = True,
        cross_align = "center",
        main_align = "space_between",
        children = [
            render.Row(
                cross_align = "center",
                children = [
                    render.Image(src = whisker_icon, width = icon_width, height = icon_height),
                    render.Box(width = 2 * scale, height = 1),
                    render.Text(data["name"][:10 if scale == 1 else 16], font = font_title, color = WHISKER_BLUE),
                ],
            ),
            render.Box(
                color = st_meta["bg"],
                child = render.Padding(
                    pad = (2 * scale, 1 * scale, 2 * scale, 1 * scale),
                    child = render.Text(st_meta["label"], font = font_tiny, color = st_meta["color"]),
                ),
            ),
        ],
    )

    bar_outer_width = width - (4 * scale)
    bar_height = 4 * scale
    fill_width = int(bar_outer_width * (waste_pct / 100.0))
    if fill_width < 1 and waste_pct > 0:
        fill_width = 1
    if fill_width > bar_outer_width:
        fill_width = bar_outer_width

    progress_bar = render.Box(
        width = bar_outer_width,
        height = bar_height,
        color = "#1e293b",
        child = render.Row(
            children = [
                render.Box(
                    width = fill_width,
                    height = bar_height,
                    color = bar_color,
                ),
            ],
        ),
    )

    drawer_row = render.Row(
        expanded = True,
        cross_align = "center",
        main_align = "space_between",
        children = [
            render.Text("DRAWER", font = font_tiny, color = MUTED),
            render.Text("%d%% FULL" % waste_pct, font = font_main, color = bar_color),
        ],
    )

    bottom_text = "%s: %s" % (cat_name, data["pet_weight"]) if data["pet_weight"] else "Status: " + data["status"]

    return render.Column(
        expanded = True,
        main_align = "space_between",
        children = [
            render.Padding(pad = (2 * scale, 1 * scale, 2 * scale, 0), child = header),
            render.Padding(
                pad = (2 * scale, 1 * scale, 2 * scale, 1 * scale),
                child = render.Column(
                    children = [
                        drawer_row,
                        render.Box(width = 1, height = 1 * scale),
                        progress_bar,
                    ],
                ),
            ),
            render.Padding(
                pad = (2 * scale, 0, 2 * scale, 1 * scale),
                child = render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "center",
                    children = [
                        render.Text(bottom_text[:18 if scale == 1 else 28], font = font_tiny, color = MUTED),
                        render.Text("WHISKER", font = font_tiny, color = WHISKER_BLUE),
                    ],
                ),
            ),
        ],
    )

def main(config):
    width, height = canvas.size()
    scale = 2 if canvas.is2x() else 1

    font_title = "tb-8" if scale == 1 else "terminus-14"
    font_main = "tb-8" if scale == 1 else "terminus-14"
    font_tiny = "tom-thumb" if scale == 1 else "tb-8"

    ha_url = config.str("ha_url", "")
    ha_token = config.str("ha_token", "")
    waste_id = config.str("waste_entity", "sensor.litter_robot_waste_drawer")
    status_id = config.str("status_entity", "sensor.litter_robot_status_code")
    pet_id = config.str("pet_weight_entity", "sensor.litter_robot_pet_weight")
    only_above_full = config.bool("only_above_full", False)
    full_level = int(config.str("full_level", "80"))

    data = fetch_whisker_data(ha_url, ha_token, waste_id, status_id, pet_id)

    if not data:
        return render.Root(
            child = render.Box(
                width = width,
                height = height,
                child = render.Column(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Text("Whisker Offline", font = font_main, color = RED),
                        render.Text("Check HA Config", font = font_tiny, color = MUTED),
                    ],
                ),
            ),
        )

    if only_above_full and data["waste_level"] < full_level and clean_status(data["status"])["label"] != "FULL":
        return []

    whisker_icon = WHISKER_ICON_ASSET.readall()
    data = dict(data)
    custom_dev_name = config.str("device_name", "").strip()
    if custom_dev_name:
        data["name"] = custom_dev_name
    elif data["name"] == "Litter-Robot":
        data["name"] = "Robot 4"

    custom_cat_name = config.str("cat_name", "").strip()
    cat_name = custom_cat_name if custom_cat_name else "Luna"

    root_child = render_whisker_gauge(
        scale,
        width,
        data,
        whisker_icon,
        cat_name,
        font_title,
        font_main,
        font_tiny,
    )

    delay = 40 // scale
    return render.Root(
        delay = delay,
        child = render.Box(
            width = width,
            height = height,
            color = BG_COLOR,
            child = root_child,
        ),
    )

def get_schema():
    threshold_options = [
        schema.Option(display = "50% Full", value = "50"),
        schema.Option(display = "60% Full", value = "60"),
        schema.Option(display = "70% Full", value = "70"),
        schema.Option(display = "75% Full", value = "75"),
        schema.Option(display = "80% Full", value = "80"),
        schema.Option(display = "85% Full", value = "85"),
        schema.Option(display = "90% Full", value = "90"),
        schema.Option(display = "95% Full", value = "95"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "device_name",
                name = "Device Name",
                desc = "Display name for your Litter-Robot (e.g. Robot 4, Whisker)",
                icon = "tag",
                default = "Robot 4",
            ),
            schema.Text(
                id = "cat_name",
                name = "Cat Name",
                desc = "Name of your cat for weight display (e.g. Luna, Oliver)",
                icon = "cat",
                default = "Luna",
            ),
            schema.Text(
                id = "ha_url",
                name = "Home Assistant URL",
                desc = "URL of your Home Assistant server",
                icon = "server",
                default = "http://homeassistant.local:8123",
            ),
            schema.Text(
                id = "ha_token",
                name = "Long-Lived Access Token",
                desc = "Long-lived access token from Home Assistant",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "waste_entity",
                name = "Waste Drawer Entity",
                desc = "Entity ID for waste drawer sensor",
                icon = "trash",
                default = "sensor.litter_robot_waste_drawer",
            ),
            schema.Text(
                id = "status_entity",
                name = "Status Entity (Optional)",
                desc = "Entity ID for status code sensor",
                icon = "circleCheck",
                default = "sensor.litter_robot_status_code",
            ),
            schema.Text(
                id = "pet_weight_entity",
                name = "Pet Weight Entity (Optional)",
                desc = "Entity ID for pet weight sensor",
                icon = "weightScale",
                default = "sensor.litter_robot_pet_weight",
            ),
            schema.Toggle(
                id = "only_above_full",
                name = "Only Render If Above Level",
                desc = "Only display when waste drawer is at or above the full level",
                icon = "trash",
                default = False,
            ),
            schema.Dropdown(
                id = "full_level",
                name = "Full Level Threshold",
                desc = "Drawer percentage considered full for filtering",
                icon = "triangleExclamation",
                default = "80",
                options = threshold_options,
            ),
        ],
    )
