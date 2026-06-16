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

def _status_url(config):
    direct = config.get("status_url")
    if direct:
        return str(direct)

    base = config.get("base_url")
    if not base:
        return DEFAULT_STATUS_URL

    base = str(base)
    if base.endswith("/status.json"):
        return base
    if base.endswith("/"):
        return base + "status.json"
    return base + "/status.json"

def printer_field(status_url):
    if not status_url:
        return []

    resp = http.get(str(status_url))
    if resp.status_code != 200:
        return []

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
            schema.Toggle(
                id = "active_only",
                name = "Only During Active Prints",
                desc = "Show only while printing or paused; otherwise skip.",
                icon = "play",
                default = False,
            ),
            schema.Generated(
                id = "printer_picker",
                source = "status_url",
                handler = printer_field,
            ),
        ],
    )

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
        return None
    parsed = _parse_iso_utc(idle_since)
    if parsed == None:
        return None
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

def _is_active_state(state):
    return state == "PRINTING" or state == "PAUSED"

def _job_display_name(printer, max_len):
    job_name = _safe_get(printer, "job_name")
    plate_name = _safe_get(printer, "plate_name")
    job_objects = _safe_get(printer, "job_objects")

    parts = []
    if job_name:
        parts.append(str(job_name))
    if plate_name:
        parts.append(str(plate_name))
    if job_objects:
        parts.append(str(job_objects))

    if len(parts) > 0:
        return _truncate(" · ".join(parts), max_len)

    return "No active print"

def _last_completed_name(printer, max_len):
    last_objects = _safe_get(printer, "last_completed_job_objects")
    last_name = _safe_get(printer, "last_completed_job_name")

    parts = []
    if last_name:
        parts.append(str(last_name))
    if last_objects and str(last_objects) != str(last_name):
        parts.append(str(last_objects))

    if len(parts) > 0:
        return _truncate(" · ".join(parts), max_len)

    return "No recent job"

def _headline(printer):
    state = _safe_get(printer, "state", "UNKNOWN")
    progress = _safe_get(printer, "progress")

    if state == "PRINTING" and progress != None:
        return "Printing · " + str(progress) + "%"

    if state == "IDLE":
        idle = _fmt_idle_since(_safe_get(printer, "idle_since"))
        if idle:
            return "Idle · " + idle

        last_end = _fmt_idle_since(_safe_get(printer, "last_completed_end_time"))
        if last_end:
            return "Idle · " + last_end

        return "Idle"

    if state == "PAUSED":
        return "Paused"

    if state == "OFFLINE":
        return "Offline"

    return str(state)

def _subline(printer, max_len):
    state = _safe_get(printer, "state", "UNKNOWN")

    if state == "PRINTING":
        return _job_display_name(printer, max_len)

    if state == "PAUSED":
        return _job_display_name(printer, max_len)

    if state == "IDLE":
        return _last_completed_name(printer, max_len)

    return _truncate(_safe_get(printer, "job_objects") or _safe_get(printer, "job_name") or "Waiting", max_len)

def _footer(printer):
    state = _safe_get(printer, "state", "UNKNOWN")

    if state == "PRINTING":
        left = _safe_get(printer, "time_left")
        if left != None:
            return _fmt_duration_from_seconds(left) + " left"

        est = _safe_get(printer, "estimated_duration_text")
        if est:
            return "Est. " + str(est)

        return "Printing"

    if state == "PAUSED":
        return "Print paused"

    if state == "IDLE":
        last_duration_text = _safe_get(printer, "last_completed_duration_text")
        if last_duration_text:
            return "Last print: " + str(last_duration_text)

        last_duration_seconds = _safe_get(printer, "last_completed_duration_seconds")
        if last_duration_seconds != None:
            return "Last print: " + _fmt_duration_from_seconds(last_duration_seconds)

        return "No print history"

    return "Waiting"

def main(config):
    font = "tb-8"
    screen_width = 64
    delay = int(config.get("scroll", "45"))
    font_width = 5
    max_text_length = 150

    if canvas.is2x():
        delay = int(delay / 2)
        font = "terminus-16"
        screen_width = 128
        font_width = 8
        max_text_length = 300

    status_url = _status_url(config)
    if not status_url:
        return render.Root(
            render.Column(
                children = [
                    render.Text("Bambu Status", font = font, color = PALETTE["text_primary"]),
                    render.Text("No status URL", font = font, color = PALETTE["warning"]),
                    render.Text("Set status_url", font = font, color = PALETTE["text_secondary"]),
                    render.Text("in config", font = font, color = PALETTE["text_muted"]),
                ],
            ),
            show_full_animation = True,
            delay = delay,
        )

    resp = http.get(status_url)
    if resp.status_code != 200:
        return render.Root(
            render.Column(
                children = [
                    render.Text("Bambu Status", font = font, color = PALETTE["text_primary"]),
                    render.Text("HTTP error", font = font, color = PALETTE["error"]),
                    render.Text(str(resp.status_code), font = font, color = PALETTE["warning"]),
                    render.Text("Check URL", font = font, color = PALETTE["text_muted"]),
                ],
            ),
            show_full_animation = True,
            delay = delay,
        )

    data = json.decode(resp.body())
    printer = _first_printer(data, config.get("printer_id"))

    printer_name = _truncate(_safe_get(printer, "name", "Bambu Printer"), max_text_length)
    state = _safe_get(printer, "state", "UNKNOWN")
    active_only = config.bool("active_only", False)

    if active_only and not _is_active_state(state):
        return []

    line2 = _headline(printer)
    line3 = _subline(printer, max_text_length)
    line4 = _footer(printer)
    status_color = _status_color(state)

    return render.Root(
        render.Column(
            children = [
                render.Text(
                    content = printer_name,
                    font = font,
                    color = PALETTE["text_primary"],
                ),
                render.Text(
                    content = line2,
                    font = font,
                    color = status_color,
                ),
                render.Marquee(
                    width = screen_width,
                    child = render.Text(
                        content = line3,
                        color = PALETTE["text_primary"],
                        font = font,
                    ),
                ),
                render.Marquee(
                    offset_start = len(line3) * font_width,
                    width = screen_width,
                    child = render.Text(
                        content = line4,
                        color = PALETTE["text_muted"],
                        font = font,
                    ),
                ),
            ],
        ),
        show_full_animation = True,
        delay = delay,
    )
