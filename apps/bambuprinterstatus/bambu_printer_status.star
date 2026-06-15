"""
Applet: Bambu Printer Status
Summary: Bambu Printer Status
Description: View status information for a Bambu Printer.
Authors: Robert Ison
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_STATUS_URL = ""

PALETTE = {
    "bg": "0F1115",
    "text_primary": "FFFFFF",
    "text_secondary": "C7CDD4",
    "text_muted": "7F8790",
    "success": "A6FF00",
    "warning": "FFD84D",
    "error": "FF5A5F",
    "info": "58D1FF",
}

def printer_field(status_url):
    if not status_url:
        return []

    resp = http.get(str(status_url))
    data = json.decode(resp.body())
    printers = data.get("printers", [])

    options = []
    for p in printers:
        pid = str(p.get("id", ""))
        pname = str(p.get("name", pid))
        if pid:
            options.append(
                schema.Option(
                    display = pname + " (" + pid + ")",
                    value = pid,
                ),
            )

    if len(options) == 0:
        return []

    return [
        schema.Dropdown(
            id = "printer_id",
            name = "Printer",
            desc = "Choose which printer to display.",
            icon = "print",
            default = options[0].value,
            options = options,
        ),
    ]

def get_schema():
    scroll_speed_options = [
        schema.Option(display = "Slow", value = "60"),
        schema.Option(display = "Medium", value = "45"),
        schema.Option(display = "Fast", value = "30"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "status_url",
                name = "Status JSON URL",
                desc = "URL to the status.json file.",
                icon = "link",
                default = DEFAULT_STATUS_URL,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "truckFast",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
            schema.Generated(
                id = "printer_picker",
                source = "status_url",
                handler = printer_field,
            ),
        ],
    )

def _status_url(config):
    direct = config.get("status_url")
    if direct:
        return str(direct)

    base = config.get("base_url")
    if not base:
        return ""

    base = str(base)
    if base.endswith("/status.json"):
        return base
    if base.endswith("/"):
        return base + "status.json"
    return base + "/status.json"

def _truncate(text, max_len):
    if text == None:
        return ""
    s = str(text)
    if len(s) <= max_len:
        return s
    if max_len <= 1:
        return s[:max_len]
    return s[:max_len - 1] + "…"

def _safe_get(map_obj, key, default = None):
    if map_obj == None:
        return default
    return map_obj.get(key, default)

def _first_printer(data, selected_id = None):
    printers = _safe_get(data, "printers", [])
    if not printers or len(printers) == 0:
        return {}

    if selected_id:
        for p in printers:
            if str(_safe_get(p, "id", "")) == str(selected_id):
                return p

    return printers[0]

def _parse_iso_utc(s):
    if not s:
        return None
    t = str(s)
    if t.endswith("Z"):
        t = t[:-1] + "+00:00"
    return time.parse_time(t, "2006-01-02T15:04:05Z07:00")

def _fmt_duration_from_seconds(total):
    if total == None:
        return "?"
    total = int(total)
    if total < 60:
        return str(total) + "s"
    mins = total // 60
    if mins < 60:
        return str(mins) + "m"
    hrs = mins // 60
    rem = mins % 60
    if rem == 0:
        return str(hrs) + "h"
    return str(hrs) + "h " + str(rem) + "m"

def _fmt_idle_since(idle_since):
    if not idle_since:
        return "?"
    parsed = _parse_iso_utc(idle_since)
    if parsed == None:
        return "?"
    now = time.now()
    diff = now - parsed
    seconds = int(diff.seconds)
    if seconds < 0:
        seconds = 0
    return _fmt_duration_from_seconds(seconds)

def _status_color(state):
    if state == "PRINTING":
        return PALETTE["success"]
    if state == "PAUSED":
        return PALETTE["warning"]
    if state == "OFFLINE":
        return PALETTE["error"]
    if state == "IDLE":
        return PALETTE["info"]
    return PALETTE["text_primary"]

def _job_display_name(printer, max_len):
    parts = []

    job_name = _safe_get(printer, "job_name")
    plate_name = _safe_get(printer, "plate_name")
    job_objects = _safe_get(printer, "job_objects")

    if job_name:
        parts.append(str(job_name))
    if plate_name:
        parts.append(str(plate_name))
    if job_objects:
        parts.append(str(job_objects))

    if len(parts) > 0:
        return _truncate(" · ".join(parts), max_len)

    return "No active print"

def _headline(printer):
    state = _safe_get(printer, "state", "UNKNOWN")
    progress = _safe_get(printer, "progress")
    if state == "PRINTING" and progress != None:
        return "Printing · " + str(progress) + "%"
    if state == "IDLE":
        idle = _fmt_idle_since(_safe_get(printer, "idle_since"))
        return "Idle · " + idle
    if state == "PAUSED":
        return "Paused"
    if state == "OFFLINE":
        return "Offline"
    return str(state)

def _subline(printer, max_len):
    state = _safe_get(printer, "state", "UNKNOWN")

    if state == "PRINTING":
        left = _safe_get(printer, "time_left")
        if left != None:
            return _fmt_duration_from_seconds(left) + " left"
        est = _safe_get(printer, "estimated_duration_text")
        if est:
            return "Est. " + str(est)
        return "Printing"

    if state == "IDLE":
        last_name = _safe_get(printer, "last_completed_job_objects") or _safe_get(printer, "last_completed_job_name")
        if last_name:
            return _truncate("Last: " + str(last_name), max_len)
        current_name = _job_display_name(printer, max_len)
        if current_name:
            return _truncate(current_name, max_len)
        return "No recent job"

    if state == "PAUSED":
        return _job_display_name(printer, max_len)

    return _truncate(_job_display_name(printer, max_len) or "Waiting", max_len)

def _footer(data, printer, max_len):
    state = _safe_get(printer, "state", "UNKNOWN")
    if state == "PRINTING":
        return _job_display_name(printer, max_len)

    updated = _safe_get(data, "updated_at")
    if updated and len(str(updated)) >= 16:
        return "Updated " + str(updated)[11:16]
    return "No timestamp"

def _instruction_lines(is_2x):
    if is_2x:
        return [
            "Bambu Status",
            "Set Status URL",
            "to your hosted",
            "status.json",
        ]
    return [
        "Bambu Status",
        "Set Status URL",
        "to status.json",
        "in settings",
    ]

def main(config):
    font = "tb-8"
    text_font = font
    screen_width = 64
    delay = int(config.get("scroll", "45"))
    max_text_length = 150
    is_2x = canvas.is2x()

    if is_2x:
        delay = int(delay / 2)
        font = "terminus-16"
        text_font = font
        screen_width = 128
        max_text_length = 300

    status_url = _status_url(config)

    if not status_url:
        lines = _instruction_lines(is_2x)

        return render.Root(
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "start",
                children = [
                    render.Text(
                        content = lines[0],
                        font = text_font,
                        color = PALETTE["text_primary"],
                    ),
                    render.Text(
                        content = lines[1],
                        font = text_font,
                        color = PALETTE["warning"],
                    ),
                    render.Text(
                        content = lines[2],
                        font = text_font,
                        color = PALETTE["text_primary"],
                    ),
                    render.Text(
                        content = lines[3],
                        font = text_font,
                        color = PALETTE["text_muted"],
                    ),
                ],
            ),
            delay = delay,
        )

    resp = http.get(status_url)
    data = json.decode(resp.body())
    printer = _first_printer(data, config.get("printer_id"))

    printer_name = _truncate(_safe_get(printer, "name", "Bambu Printer"), max_text_length)
    state = _safe_get(printer, "state", "UNKNOWN")
    line2 = _headline(printer)
    line3 = _subline(printer, max_text_length)
    line4 = _footer(data, printer, max_text_length)
    color = _status_color(state)

    text1 = render.Text(
        content = printer_name,
        font = text_font,
        color = PALETTE["text_primary"],
    )
    marquee1 = render.Marquee(
        width = screen_width,
        delay = 0,
        child = text1,
    )

    text2 = render.Text(
        content = _truncate(line2, max_text_length),
        font = text_font,
        color = color,
    )
    marquee2 = render.Marquee(
        width = screen_width,
        delay = marquee1.frame_count(),
        child = text2,
    )

    text3 = render.Text(
        content = _truncate(line3, max_text_length),
        font = text_font,
        color = PALETTE["text_primary"],
    )
    marquee3 = render.Marquee(
        width = screen_width,
        delay = marquee1.frame_count() + marquee2.frame_count(),
        child = text3,
    )

    text4 = render.Text(
        content = _truncate(line4, max_text_length),
        font = text_font,
        color = PALETTE["text_muted"],
    )
    marquee4 = render.Marquee(
        width = screen_width,
        delay = marquee1.frame_count() + marquee2.frame_count() + marquee3.frame_count(),
        child = text4,
    )

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "start",
            children = [
                marquee1,
                marquee2,
                marquee3,
                marquee4,
            ],
        ),
        show_full_animation = True,
        delay = delay,
    )
