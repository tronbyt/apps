"""
Applet: Moonraker Klipper
Summary: Monitor Klipper 3D printer
Description: Direct Moonraker connection to monitor 3D print progress, nozzle & bed temperatures, print time, and current file.
Author: brombomb
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/klipper_icon.png", KLIPPER_ICON_ASSET = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")

RED = "#e03131"
GREEN = "#00ff66"
CYAN = "#00e5ff"
YELLOW = "#ffcc00"
ORANGE = "#ff922b"
MUTED = "#868e96"
WHITE = "#ffffff"
BG_COLOR = "#000000"

SAMPLE_DATA = {
    "state": "printing",
    "filename": "benchy_pla_0.2.gcode",
    "progress": 0.68,
    "print_duration": 3480,
    "time_left": 1640,
    "nozzle_temp": 215,
    "nozzle_target": 215,
    "bed_temp": 60,
    "bed_target": 60,
}

def format_duration(seconds):
    if seconds <= 0:
        return "0m"
    hours = int(seconds) // 3600
    minutes = (int(seconds) % 3600) // 60
    if hours > 0:
        return "%dh %dm" % (hours, minutes)
    return "%dm" % minutes

def clean_filename(filename):
    if not filename:
        return "No Job"
    name = filename
    if name.endswith(".gcode"):
        name = name[:-6]
    elif name.endswith(".3mf"):
        name = name[:-4]
    return name

def fetch_moonraker_status(printer_url, api_key):
    if not printer_url or printer_url.strip() == "":
        return SAMPLE_DATA

    clean_url = printer_url.strip()
    if clean_url.endswith("/"):
        clean_url = clean_url[:-1]

    endpoint = clean_url + "/printer/objects/query?print_stats&extruder&heater_bed&display_status"

    cache_key = "moonraker_" + endpoint
    cached = cache.get(cache_key)
    if cached:
        return json.decode(cached)

    headers = {"User-Agent": "Tronbyt-Moonraker-Monitor"}
    if api_key and api_key.strip() != "":
        headers["X-Api-Key"] = api_key.strip()

    res = http.get(endpoint, headers = headers, ttl_seconds = 15)
    if res.status_code != 200:
        print("Failed to query Moonraker API:", res.status_code, endpoint)
        return None

    raw_json = res.json()
    status = (raw_json.get("result") or {}).get("status") or {}

    print_stats = status.get("print_stats") or {}
    display_status = status.get("display_status") or {}
    extruder = status.get("extruder") or {}
    heater_bed = status.get("heater_bed") or {}

    state = print_stats.get("state", "standby").lower()
    filename = print_stats.get("filename", "")
    print_duration = int(print_stats.get("print_duration", 0))
    progress = display_status.get("progress", 0.0)

    time_left = 0
    if progress > 0.01 and print_duration > 0:
        estimated_total = print_duration / progress
        time_left = int(estimated_total - print_duration)

    nozzle_temp = int(extruder.get("temperature", 0))
    nozzle_target = int(extruder.get("target", 0))
    bed_temp = int(heater_bed.get("temperature", 0))
    bed_target = int(heater_bed.get("target", 0))

    data = {
        "state": state,
        "filename": filename,
        "progress": progress,
        "print_duration": print_duration,
        "time_left": time_left,
        "nozzle_temp": nozzle_temp,
        "nozzle_target": nozzle_target,
        "bed_temp": bed_temp,
        "bed_target": bed_target,
    }

    cache.set(cache_key, json.encode(data), ttl_seconds = 15)
    return data

def get_state_color(state):
    if state == "printing":
        return GREEN
    elif state == "paused":
        return YELLOW
    elif state == "complete":
        return CYAN
    elif state == "error":
        return RED
    return MUTED

def render_printer_view(scale, width, data, klipper_icon, font_title, font_tiny):
    icon_width = 12 * scale
    icon_height = 10 * scale

    state = data["state"]
    state_color = get_state_color(state)
    state_label = state.upper()[:8]

    filename_display = clean_filename(data["filename"])
    progress_pct = int(data["progress"] * 100)

    header = render.Row(
        expanded = True,
        cross_align = "center",
        main_align = "space_between",
        children = [
            render.Row(
                cross_align = "center",
                children = [
                    render.Image(src = klipper_icon, width = icon_width, height = icon_height),
                    render.Box(width = 2 * scale, height = 1),
                    render.Marquee(
                        width = width - (48 * scale),
                        child = render.Text(filename_display if filename_display else "Klipper", font = font_title, color = WHITE),
                    ),
                ],
            ),
            render.Box(
                color = "#112211" if state == "printing" else "#221111",
                child = render.Padding(
                    pad = (2 * scale, 1 * scale, 2 * scale, 1 * scale),
                    child = render.Text(state_label, font = font_tiny, color = state_color),
                ),
            ),
        ],
    )

    # OctoPrint-style prominent embedded progress bar
    bar_outer_width = width - (4 * scale)
    bar_height = 8 * scale
    fill_width = int(bar_outer_width * data["progress"])
    if fill_width < 1 and data["progress"] > 0:
        fill_width = 1
    if fill_width > bar_outer_width:
        fill_width = bar_outer_width

    time_text = format_duration(data["time_left"]) if state == "printing" else format_duration(data["print_duration"])
    if state == "printing":
        bar_label = "%d%% · %s left" % (progress_pct, time_text)
    else:
        bar_label = "%d%% · %s" % (progress_pct, state.upper())

    progress_bar = render.Box(
        width = bar_outer_width,
        height = bar_height,
        color = "#151c24",
        child = render.Stack(
            children = [
                render.Row(
                    children = [
                        render.Box(
                            width = fill_width,
                            height = bar_height,
                            color = state_color,
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Text(
                            content = bar_label,
                            font = font_tiny,
                            color = WHITE,
                            offset = -1 if scale == 1 else 0,
                        ),
                    ],
                ),
            ],
        ),
    )

    temps_row = render.Row(
        expanded = True,
        cross_align = "center",
        main_align = "space_between",
        children = [
            render.Row(
                cross_align = "center",
                children = [
                    render.Text("E: ", font = font_tiny, color = ORANGE),
                    render.Text("%d" % data["nozzle_temp"], font = font_tiny, color = WHITE),
                    render.Text("/%d°" % data["nozzle_target"] if data["nozzle_target"] > 0 else "°", font = font_tiny, color = MUTED),
                ],
            ),
            render.Row(
                cross_align = "center",
                children = [
                    render.Text("B: ", font = font_tiny, color = CYAN),
                    render.Text("%d" % data["bed_temp"], font = font_tiny, color = WHITE),
                    render.Text("/%d°" % data["bed_target"] if data["bed_target"] > 0 else "°", font = font_tiny, color = MUTED),
                ],
            ),
        ],
    )

    return render.Column(
        expanded = True,
        main_align = "space_between",
        children = [
            render.Padding(pad = (2 * scale, 1 * scale, 2 * scale, 0), child = header),
            render.Padding(
                pad = (2 * scale, 0, 2 * scale, 0),
                child = progress_bar,
            ),
            render.Padding(pad = (2 * scale, 0, 2 * scale, 1 * scale), child = temps_row),
        ],
    )

def main(config):
    width, height = canvas.size()
    scale = 2 if canvas.is2x() else 1

    font_title = "tb-8" if scale == 1 else "terminus-14"
    font_tiny = "tom-thumb" if scale == 1 else "tb-8"

    printer_url = config.str("printer_url", "")
    api_key = config.str("api_key", "")
    hide_when_idle = config.bool("hide_when_idle", False)

    data = fetch_moonraker_status(printer_url, api_key)

    if not data:
        return render.Root(
            child = render.Box(
                width = width,
                height = height,
                child = render.Column(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Text("Check Moonraker URL", font = font_tiny, color = MUTED),
                    ],
                ),
            ),
        )

    if hide_when_idle and data["state"] in ["standby", "complete"]:
        return []

    klipper_icon = KLIPPER_ICON_ASSET.readall()
    root_child = render_printer_view(
        scale,
        width,
        data,
        klipper_icon,
        font_title,
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
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "printer_url",
                name = "Moonraker URL",
                desc = "Host URL of your Moonraker / Klipper 3D printer",
                icon = "server",
                default = "http://localhost:7125",
            ),
            schema.Text(
                id = "api_key",
                name = "API Key (Optional)",
                desc = "Moonraker API key if authentication is enabled",
                icon = "key",
                secret = True,
            ),
            schema.Toggle(
                id = "hide_when_idle",
                name = "Hide When Idle",
                desc = "Skip rendering when the printer is in standby or complete",
                icon = "eyeSlash",
                default = False,
            ),
        ],
    )
