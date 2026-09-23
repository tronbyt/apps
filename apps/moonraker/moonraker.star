"""
Applet: Moonraker Klipper
Summary: Monitor Klipper 3D printer
Description: Direct Moonraker connection to monitor 3D print progress, nozzle & bed temperatures, print time, and current file.
Author: brombomb
"""

load("http.star", "http")
load("images/klipper_icon.png", KLIPPER_ICON_ASSET = "file")
load("images/sample_thumb.png", SAMPLE_THUMB_ASSET = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

RED = "#ff453a"
GREEN = "#30d158"
CYAN = "#64d2ff"
YELLOW = "#ffd60a"
ORANGE = "#ff9f0a"
MUTED = "#8e8e93"
BAR_BG = "#1c1c1e"
WHITE = "#ffffff"
BG_COLOR = "#000000"

SAMPLE_DATA = {
    "state": "printing",
    "filename": "Pokeshooter_PLA_2h56m.gcode",
    "clean_name": "Pokeshooter",
    "progress": 0.68,
    "print_duration": 4820,
    "total_duration": 4820,
    "filament_m": 14.3,
    "time_left": 2260,
    "current_layer": 492,
    "total_layer": 723,
    "nozzle_temp": 220,
    "nozzle_target": 220,
    "bed_temp": 65,
    "bed_target": 65,
    "completed_age_seconds": 0,
}

def format_duration(seconds):
    if seconds <= 0:
        return "0m"
    hours = int(seconds) // 3600
    minutes = (int(seconds) % 3600) // 60
    if hours > 0:
        return "%dh %dm" % (hours, minutes)
    return "%dm" % minutes

def format_compact_duration(seconds):
    if seconds <= 0:
        return "0m"
    hours = int(seconds) // 3600
    minutes = (int(seconds) % 3600) // 60
    if hours > 0:
        return "%dh%dm" % (hours, minutes)
    return "%dm" % minutes

def clean_filename(filename):
    if not filename:
        return "No Job"
    name = filename
    if "/" in name:
        name = name.split("/")[-1]
    if name.endswith(".gcode"):
        name = name[:-6]
    elif name.endswith(".3mf"):
        name = name[:-4]
    return name

def format_temp(celsius, unit):
    if unit == "f":
        return int(celsius * 9 / 5 + 32)
    return celsius

def get_state_color(state):
    if state == "printing":
        return GREEN
    elif state == "heating":
        return ORANGE
    elif state == "paused":
        return YELLOW
    elif state == "complete":
        return CYAN
    elif state == "error":
        return RED
    return MUTED

def normalize_url(url):
    if not url or url.strip() == "":
        return ""
    u = url.strip()
    if u.endswith("/"):
        u = u[:-1]
    if not u.startswith("http://") and not u.startswith("https://"):
        u = "http://" + u
    host_part = u[7:] if u.startswith("http://") else u[8:]
    if ":" not in host_part and "/" not in host_part:
        u = u + ":7125"
    return u

def escape_url_path(path):
    return path.replace(" ", "%20")

def fetch_moonraker_status(printer_url, api_key, show_thumbnail, temp_unit):
    clean_url = normalize_url(printer_url)
    if not clean_url:
        return None, None

    headers = {"User-Agent": "Tronbyt-Moonraker-Monitor"}
    if api_key and api_key.strip() != "":
        headers["X-Api-Key"] = api_key.strip()

    endpoint = clean_url + "/printer/objects/query?print_stats&extruder&heater_bed&display_status"
    res = http.get(endpoint, headers = headers, ttl_seconds = 10)
    if res.status_code != 200:
        return None, None

    raw_json = res.json()
    status = (raw_json.get("result") or {}).get("status") or {}
    print_stats = status.get("print_stats") or {}
    display_status = status.get("display_status") or {}
    extruder = status.get("extruder") or {}
    heater_bed = status.get("heater_bed") or {}

    state = print_stats.get("state", "standby").lower()
    filename = print_stats.get("filename", "")
    print_duration = int(print_stats.get("print_duration", 0))
    total_duration = int(print_stats.get("total_duration", 0))
    filament_used_mm = float(print_stats.get("filament_used", 0))
    progress = float(display_status.get("progress", 0.0))

    info = print_stats.get("info") or {}
    current_layer = int(info.get("current_layer", 0)) if info.get("current_layer") != None else 0
    total_layer = int(info.get("total_layer", 0)) if info.get("total_layer") != None else 0

    nozzle_temp = format_temp(int(extruder.get("temperature", 0)), temp_unit)
    nozzle_raw_target = int(extruder.get("target", 0))
    nozzle_target = format_temp(nozzle_raw_target, temp_unit) if nozzle_raw_target > 0 else 0

    bed_temp = format_temp(int(heater_bed.get("temperature", 0)), temp_unit)
    bed_raw_target = int(heater_bed.get("target", 0))
    bed_target = format_temp(bed_raw_target, temp_unit) if bed_raw_target > 0 else 0

    # Heating detection
    if state == "printing" and progress < 0.01:
        if (nozzle_raw_target > 0 and int(extruder.get("temperature", 0)) < nozzle_raw_target - 3) or (bed_raw_target > 0 and int(heater_bed.get("temperature", 0)) < bed_raw_target - 3):
            state = "heating"

    # Time remaining
    time_left = 0
    if progress > 0.01 and print_duration > 0:
        estimated_total = print_duration / progress
        time_left = int(estimated_total - print_duration)

    # Completed age check via history
    completed_age_seconds = 0
    if state == "complete":
        hist_url = clean_url + "/server/history/list?limit=1"
        hist_res = http.get(hist_url, headers = headers, ttl_seconds = 60)
        if hist_res.status_code == 200:
            jobs = (hist_res.json().get("result") or {}).get("jobs") or []
            if len(jobs) > 0:
                end_time = float(jobs[0].get("end_time", 0))
                if end_time > 0:
                    completed_age_seconds = time.now().unix - int(end_time)

    # Fetch thumbnail
    thumb_data = None
    if show_thumbnail and filename:
        meta_url = clean_url + "/server/files/metadata"
        meta_res = http.get(meta_url, params = {"filename": filename}, headers = headers, ttl_seconds = 300)
        if meta_res.status_code == 200:
            meta = (meta_res.json().get("result") or {})
            if total_layer == 0 and meta.get("layer_count"):
                total_layer = int(meta.get("layer_count", 0))

            thumbs = meta.get("thumbnails") or []
            if len(thumbs) > 0:
                selected_thumb = thumbs[0]
                for t in thumbs:
                    tw = t.get("width", 0)
                    if tw >= 48 and tw <= 150:
                        selected_thumb = t
                        break
                rel_path = selected_thumb.get("relative_path")
                if rel_path:
                    thumb_img_url = clean_url + "/server/files/gcodes/" + escape_url_path(rel_path)
                    img_res = http.get(thumb_img_url, headers = headers, ttl_seconds = 600)
                    if img_res.status_code == 200:
                        thumb_data = img_res.body()

    data = {
        "state": state,
        "filename": filename,
        "clean_name": clean_filename(filename),
        "progress": progress,
        "print_duration": print_duration,
        "total_duration": total_duration,
        "filament_m": filament_used_mm / 1000.0,
        "time_left": time_left,
        "current_layer": current_layer,
        "total_layer": total_layer,
        "nozzle_temp": nozzle_temp,
        "nozzle_target": nozzle_target,
        "bed_temp": bed_temp,
        "bed_target": bed_target,
        "completed_age_seconds": completed_age_seconds,
    }

    return data, thumb_data

def render_thumb_view_1x(data, thumb_data):
    width, height = 64, 32
    thumb_size = 26
    right_width = width - thumb_size - 3

    state = data["state"]
    state_color = get_state_color(state)
    pct = int(data["progress"] * 100)

    left_side = render.Box(
        width = thumb_size,
        height = height,
        child = render.Image(src = thumb_data, width = thumb_size, height = thumb_size),
    )

    row_title = render.Marquee(
        width = right_width,
        child = render.Text(data["clean_name"], font = "tom-thumb", color = WHITE),
    )

    if state == "complete":
        row_status = render.Row(
            expanded = True,
            main_align = "space_between",
            children = [
                render.Text("DONE", font = "tom-thumb", color = CYAN),
                render.Text(format_compact_duration(data["total_duration"]), font = "tom-thumb", color = MUTED),
            ],
        )
    elif state == "heating":
        row_status = render.Row(
            expanded = True,
            main_align = "space_between",
            children = [
                render.Text("HEAT", font = "tom-thumb", color = ORANGE),
                render.Text("♨", font = "tom-thumb", color = ORANGE),
            ],
        )
    elif state == "paused":
        row_status = render.Row(
            expanded = True,
            main_align = "space_between",
            children = [
                render.Text("PAUSE", font = "tom-thumb", color = YELLOW),
                render.Text("%d%%" % pct, font = "tom-thumb", color = YELLOW),
            ],
        )
    else:
        row_status = render.Row(
            expanded = True,
            main_align = "space_between",
            children = [
                render.Text("%d%%" % pct, font = "tom-thumb", color = state_color),
                render.Text(format_compact_duration(data["time_left"]), font = "tom-thumb", color = MUTED),
            ],
        )

    bar_h = 3
    fill_w = int(right_width * data["progress"])
    if fill_w < 1 and data["progress"] > 0:
        fill_w = 1
    if fill_w > right_width:
        fill_w = right_width

    bar = render.Box(
        width = right_width,
        height = bar_h,
        color = BAR_BG,
        child = render.Row(
            children = [
                render.Box(width = fill_w, height = bar_h, color = state_color),
            ],
        ),
    )

    row_telemetry = render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            render.Text("E%d°" % data["nozzle_temp"], font = "tom-thumb", color = ORANGE),
            render.Text("B%d°" % data["bed_temp"], font = "tom-thumb", color = CYAN),
        ],
    )

    right_col = render.Column(
        expanded = True,
        main_align = "space_between",
        children = [
            row_title,
            row_status,
            bar,
            row_telemetry,
        ],
    )

    return render.Padding(
        pad = (1, 1, 1, 1),
        child = render.Row(
            cross_align = "center",
            children = [
                left_side,
                render.Box(width = 2, height = 1),
                right_col,
            ],
        ),
    )

def render_full_view_1x(data, klipper_icon):
    state = data["state"]
    state_color = get_state_color(state)
    pct = int(data["progress"] * 100)

    top_row = render.Row(
        expanded = True,
        cross_align = "center",
        main_align = "space_between",
        children = [
            render.Row(
                cross_align = "center",
                children = [
                    render.Image(src = klipper_icon, width = 10, height = 8),
                    render.Box(width = 2, height = 1),
                    render.Marquee(
                        width = 34,
                        child = render.Text(data["clean_name"], font = "tom-thumb", color = WHITE),
                    ),
                ],
            ),
            render.Box(
                height = 8,
                color = "#1c1c1e",
                child = render.Padding(
                    pad = (2, 1, 2, 1),
                    child = render.Text(state.upper()[:6], font = "tom-thumb", color = state_color),
                ),
            ),
        ],
    )

    bar_w = 62
    bar_h = 7
    fill_w = int(bar_w * data["progress"])
    if fill_w < 1 and data["progress"] > 0:
        fill_w = 1
    if fill_w > bar_w:
        fill_w = bar_w

    if state == "complete":
        bar_text = "COMPLETE · %s" % format_compact_duration(data["total_duration"])
    elif state == "heating":
        bar_text = "HEATING · %d°/%d°" % (data["nozzle_temp"], data["nozzle_target"])
    else:
        bar_text = "%d%% · %s left" % (pct, format_compact_duration(data["time_left"]))

    progress_bar = render.Box(
        width = bar_w,
        height = bar_h,
        color = BAR_BG,
        child = render.Stack(
            children = [
                render.Row(
                    children = [
                        render.Box(width = fill_w, height = bar_h, color = state_color),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Text(bar_text, font = "tom-thumb", color = WHITE, offset = -1),
                    ],
                ),
            ],
        ),
    )

    if data["total_layer"] > 0:
        layer_text = "L%d/%d" % (data["current_layer"], data["total_layer"])
    elif data["filament_m"] > 0:
        layer_text = "%dm" % int(data["filament_m"])
    else:
        layer_text = ""

    bottom_row = render.Row(
        expanded = True,
        cross_align = "center",
        main_align = "space_between",
        children = [
            render.Text(layer_text, font = "tom-thumb", color = "#90caf9"),
            render.Row(
                children = [
                    render.Text("E%d°" % data["nozzle_temp"], font = "tom-thumb", color = ORANGE),
                    render.Text(" ", font = "tom-thumb"),
                    render.Text("B%d°" % data["bed_temp"], font = "tom-thumb", color = CYAN),
                ],
            ),
        ],
    )

    return render.Padding(
        pad = (1, 1, 1, 1),
        child = render.Column(
            expanded = True,
            main_align = "space_between",
            children = [
                top_row,
                progress_bar,
                bottom_row,
            ],
        ),
    )

def render_thumb_view_2x(data, thumb_data):
    width, height = 128, 64
    thumb_size = 56
    pad_h = 3
    pad_v = 3
    spacing = 4
    right_width = width - (pad_h * 2) - thumb_size - spacing  # 62px

    state = data["state"]
    state_color = get_state_color(state)
    pct = int(data["progress"] * 100)

    left_side = render.Box(
        width = thumb_size,
        height = height - (pad_v * 2),
        child = render.Image(src = thumb_data, width = thumb_size, height = thumb_size),
    )

    row_title = render.Marquee(
        width = right_width,
        child = render.Text(data["clean_name"], font = "tb-8", color = WHITE),
    )

    if state == "complete":
        row_status = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Text("DONE", font = "tb-8", color = CYAN),
                render.Text(format_compact_duration(data["total_duration"]), font = "tb-8", color = MUTED),
            ],
        )
    elif state == "heating":
        row_status = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Text("HEAT", font = "tb-8", color = ORANGE),
                render.Text("♨", font = "tb-8", color = ORANGE),
            ],
        )
    elif state == "paused":
        row_status = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Text("PAUSE", font = "tb-8", color = YELLOW),
                render.Text("%d%%" % pct, font = "tb-8", color = YELLOW),
            ],
        )
    else:
        row_status = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Text("%d%%" % pct, font = "terminus-14", color = state_color),
                render.Text(format_compact_duration(data["time_left"]), font = "tb-8", color = MUTED),
            ],
        )

    bar_h = 5
    fill_w = int(right_width * data["progress"])
    if fill_w < 1 and data["progress"] > 0:
        fill_w = 1
    if fill_w > right_width:
        fill_w = right_width

    bar = render.Box(
        width = right_width,
        height = bar_h,
        color = BAR_BG,
        child = render.Row(
            children = [
                render.Box(width = fill_w, height = bar_h, color = state_color),
            ],
        ),
    )

    if state == "complete":
        layer_row = render.Row(
            expanded = True,
            main_align = "space_between",
            children = [
                render.Text("L %d/%d" % (data["current_layer"], data["total_layer"]) if data["total_layer"] > 0 else "Complete", font = "tb-8", color = "#90caf9"),
                render.Text("%dm" % int(data["filament_m"]) if data["filament_m"] > 0 else "", font = "tb-8", color = MUTED),
            ],
        )
    elif data["total_layer"] > 0:
        layer_row = render.Row(
            expanded = True,
            main_align = "space_between",
            children = [
                render.Text("L %d/%d" % (data["current_layer"], data["total_layer"]), font = "tb-8", color = "#90caf9"),
                render.Text("%dm" % int(data["filament_m"]) if data["filament_m"] > 0 else "", font = "tb-8", color = MUTED),
            ],
        )
    elif data["filament_m"] > 0:
        layer_row = render.Text("%dm filament" % int(data["filament_m"]), font = "tb-8", color = MUTED)
    else:
        layer_row = render.Box(height = 8)

    row_telemetry = render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            render.Text("E: %d°" % data["nozzle_temp"], font = "tb-8", color = ORANGE),
            render.Text("B: %d°" % data["bed_temp"], font = "tb-8", color = CYAN),
        ],
    )

    right_col = render.Column(
        expanded = True,
        main_align = "space_between",
        children = [
            row_title,
            row_status,
            bar,
            layer_row,
            row_telemetry,
        ],
    )

    return render.Padding(
        pad = (pad_h, pad_v, pad_h, pad_v),
        child = render.Row(
            cross_align = "center",
            children = [
                left_side,
                render.Box(width = spacing, height = 1),
                right_col,
            ],
        ),
    )

def render_full_view_2x(data, klipper_icon):
    state = data["state"]
    state_color = get_state_color(state)
    pct = int(data["progress"] * 100)

    icon_w = 16
    icon_h = 13
    top_row = render.Row(
        expanded = True,
        cross_align = "center",
        main_align = "space_between",
        children = [
            render.Row(
                cross_align = "center",
                children = [
                    render.Image(src = klipper_icon, width = icon_w, height = icon_h),
                    render.Box(width = 4, height = 1),
                    render.Marquee(
                        width = 50,
                        child = render.Text(data["clean_name"], font = "tb-8", color = WHITE),
                    ),
                ],
            ),
            render.Box(
                height = 13,
                color = "#1c1c1e",
                child = render.Padding(
                    pad = (3, 1, 3, 1),
                    child = render.Text(state.upper()[:8], font = "tb-8", color = state_color),
                ),
            ),
        ],
    )

    if state == "complete":
        mid_row = render.Row(
            expanded = True,
            cross_align = "center",
            main_align = "space_between",
            children = [
                render.Text("FINISHED", font = "terminus-14", color = CYAN),
                render.Text("Took %s" % format_duration(data["total_duration"]), font = "tb-8", color = MUTED),
            ],
        )
    elif state == "heating":
        mid_row = render.Row(
            expanded = True,
            cross_align = "center",
            main_align = "space_between",
            children = [
                render.Text("HEATING", font = "terminus-14", color = ORANGE),
                render.Text("Target %d°" % data["nozzle_target"] if data["nozzle_target"] > 0 else "Heating", font = "tb-8", color = ORANGE),
            ],
        )
    elif state == "paused":
        mid_row = render.Row(
            expanded = True,
            cross_align = "center",
            main_align = "space_between",
            children = [
                render.Text("PAUSED", font = "terminus-14", color = YELLOW),
                render.Text("L %d/%d" % (data["current_layer"], data["total_layer"]) if data["total_layer"] > 0 else "", font = "tb-8", color = "#90caf9"),
                render.Text("%d%%" % pct, font = "tb-8", color = YELLOW),
            ],
        )
    else:
        mid_row = render.Row(
            expanded = True,
            cross_align = "center",
            main_align = "space_between",
            children = [
                render.Text("%d%%" % pct, font = "terminus-16", color = state_color),
                render.Text("L %d/%d" % (data["current_layer"], data["total_layer"]) if data["total_layer"] > 0 else "", font = "tb-8", color = "#90caf9"),
                render.Text("%s left" % format_duration(data["time_left"]), font = "tb-8", color = MUTED),
            ],
        )

    bar_w = 120
    bar_h = 6
    fill_w = int(bar_w * data["progress"])
    if fill_w < 1 and data["progress"] > 0:
        fill_w = 1
    if fill_w > bar_w:
        fill_w = bar_w

    bar = render.Box(
        width = bar_w,
        height = bar_h,
        color = BAR_BG,
        child = render.Row(
            children = [
                render.Box(width = fill_w, height = bar_h, color = state_color),
            ],
        ),
    )

    nozzle_target_str = "/%d°" % data["nozzle_target"] if data["nozzle_target"] > 0 else "°"
    bed_target_str = "/%d°" % data["bed_target"] if data["bed_target"] > 0 else "°"

    bottom_row = render.Row(
        expanded = True,
        cross_align = "center",
        main_align = "space_between",
        children = [
            render.Row(
                cross_align = "center",
                children = [
                    render.Text("E: ", font = "tb-8", color = ORANGE),
                    render.Text("%d" % data["nozzle_temp"], font = "tb-8", color = WHITE),
                    render.Text(nozzle_target_str, font = "tb-8", color = MUTED),
                ],
            ),
            render.Text("Filament: %dm" % int(data["filament_m"]) if data["filament_m"] > 0 else "", font = "tb-8", color = MUTED),
            render.Row(
                cross_align = "center",
                children = [
                    render.Text("B: ", font = "tb-8", color = CYAN),
                    render.Text("%d" % data["bed_temp"], font = "tb-8", color = WHITE),
                    render.Text(bed_target_str, font = "tb-8", color = MUTED),
                ],
            ),
        ],
    )

    return render.Padding(
        pad = (4, 4, 4, 4),
        child = render.Column(
            expanded = True,
            main_align = "space_between",
            children = [
                top_row,
                mid_row,
                bar,
                bottom_row,
            ],
        ),
    )

def render_standby_1x(data, klipper_icon):
    top_row = render.Row(
        expanded = True,
        cross_align = "center",
        children = [
            render.Image(src = klipper_icon, width = 12, height = 10),
            render.Box(width = 4, height = 1),
            render.Text("Klipper", font = "tb-8", color = WHITE),
        ],
    )
    mid_row = render.Row(
        expanded = True,
        main_align = "center",
        children = [
            render.Text("IDLE / READY", font = "tom-thumb", color = GREEN),
        ],
    )
    bottom_row = render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            render.Text("E: %d°" % data["nozzle_temp"], font = "tom-thumb", color = ORANGE),
            render.Text("B: %d°" % data["bed_temp"], font = "tom-thumb", color = CYAN),
        ],
    )
    return render.Padding(
        pad = (2, 2, 2, 2),
        child = render.Column(
            expanded = True,
            main_align = "space_between",
            children = [
                top_row,
                mid_row,
                bottom_row,
            ],
        ),
    )

def render_standby_2x(data, klipper_icon):
    top_row = render.Row(
        expanded = True,
        cross_align = "center",
        children = [
            render.Image(src = klipper_icon, width = 24, height = 20),
            render.Box(width = 6, height = 1),
            render.Text("Klipper Ready", font = "terminus-14", color = WHITE),
        ],
    )
    mid_row = render.Row(
        children = [
            render.Box(
                height = 14,
                color = "#122616",
                child = render.Padding(
                    pad = (6, 2, 6, 2),
                    child = render.Text("● READY FOR PRINT", font = "tb-8", color = GREEN),
                ),
            ),
        ],
    )
    bottom_row = render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            render.Text("Nozzle: %d°" % data["nozzle_temp"], font = "tb-8", color = ORANGE),
            render.Text("Bed: %d°" % data["bed_temp"], font = "tb-8", color = CYAN),
        ],
    )
    return render.Padding(
        pad = (4, 4, 4, 4),
        child = render.Column(
            expanded = True,
            main_align = "space_between",
            children = [
                top_row,
                mid_row,
                bottom_row,
            ],
        ),
    )

def main(config):
    width, height = canvas.size()
    is_2x = canvas.is2x()

    printer_url = config.str("printer_url", "")
    api_key = config.str("api_key", "")
    show_thumbnail = config.bool("show_thumbnail", True)
    hide_when_idle = config.bool("hide_when_idle", False)
    max_complete_hours_str = config.str("max_complete_hours", "4")
    temp_unit = config.str("temp_unit", "c")

    max_complete_hours = 4.0
    if max_complete_hours_str and max_complete_hours_str.isdigit():
        max_complete_hours = float(max_complete_hours_str)

    data, thumb_data = fetch_moonraker_status(printer_url, api_key, show_thumbnail, temp_unit)

    # Rule: Offline should just not render
    if not data:
        if printer_url and printer_url.strip() != "":
            return []
        data = SAMPLE_DATA
        thumb_data = SAMPLE_THUMB_ASSET.readall() if show_thumbnail else None

    state = data["state"]

    # Rule: Complete should only render for 4 hours after completing a print
    if state == "complete":
        if max_complete_hours > 0 and data["completed_age_seconds"] > (max_complete_hours * 3600):
            return []

    # Standby / idle hiding
    if hide_when_idle and state in ["standby", "idle"]:
        return []

    klipper_icon = KLIPPER_ICON_ASSET.readall()

    if state in ["standby", "idle"]:
        content = render_standby_2x(data, klipper_icon) if is_2x else render_standby_1x(data, klipper_icon)
    elif is_2x:
        if thumb_data:
            content = render_thumb_view_2x(data, thumb_data)
        else:
            content = render_full_view_2x(data, klipper_icon)
    elif thumb_data:
        content = render_thumb_view_1x(data, thumb_data)
    else:
        content = render_full_view_1x(data, klipper_icon)

    delay = 20 if is_2x else 40

    return render.Root(
        delay = delay,
        child = render.Box(
            width = width,
            height = height,
            color = BG_COLOR,
            child = content,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "printer_url",
                name = "Moonraker URL",
                desc = "Host URL of your Moonraker / Klipper 3D printer (e.g. http://192.168.1.50:7125)",
                icon = "server",
            ),
            schema.Text(
                id = "api_key",
                name = "API Key (Optional)",
                desc = "Moonraker API key if authentication is enabled",
                icon = "key",
                secret = True,
            ),
            schema.Toggle(
                id = "show_thumbnail",
                name = "Show 3D Model Preview",
                desc = "Display sliced G-code thumbnail if available",
                icon = "image",
                default = True,
            ),
            schema.Dropdown(
                id = "max_complete_hours",
                name = "Max Complete Age",
                desc = "How long to show completed print screen",
                icon = "clock",
                default = "4",
                options = [
                    schema.Option(display = "1 Hour", value = "1"),
                    schema.Option(display = "2 Hours", value = "2"),
                    schema.Option(display = "4 Hours (Default)", value = "4"),
                    schema.Option(display = "8 Hours", value = "8"),
                    schema.Option(display = "12 Hours", value = "12"),
                    schema.Option(display = "24 Hours", value = "24"),
                    schema.Option(display = "Always Show", value = "0"),
                ],
            ),
            schema.Toggle(
                id = "hide_when_idle",
                name = "Hide When Idle",
                desc = "Skip rendering when the printer is in standby",
                icon = "eyeSlash",
                default = False,
            ),
            schema.Dropdown(
                id = "temp_unit",
                name = "Temperature Unit",
                desc = "Choose Celsius or Fahrenheit",
                icon = "temperatureHalf",
                default = "c",
                options = [
                    schema.Option(display = "Celsius (°C)", value = "c"),
                    schema.Option(display = "Fahrenheit (°F)", value = "f"),
                ],
            ),
        ],
    )
