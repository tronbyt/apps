"""
Applet: Bambu Printer Status
Summary: Bambu Printer Status
Description: View printer status, estimated finish time, and recent print history.
Authors: Robert Ison
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

def is_square():
    """True on a 64x64 panel.

    Panels are told apart by SHAPE, never by size: the 128x64 wide panel is
    also 64 tall.
    """
    w, h = canvas.size()
    return h == w

def center_on_square(child, width = None, height = None):
    """Centre `child` on the square (64x64); other panels get it unchanged.

    A scene hand-laid for 64x32 passes its size so the Box that centres it
    has the scene's bounds rather than the panel's.
    """
    if not is_square():
        return child
    if width != None and height != None:
        child = render.Box(width = width, height = height, child = child)
    return render.Box(width = canvas.width(), height = canvas.height(), child = child)

DEFAULT_STATUS_URL = ""
DEFAULT_SCROLL = "60"
DEFAULT_TIMEZONE = "America/New_York"

SETUP_GUIDE_TITLE = "Bambu Printer Status JSON Setup Instructions"

# Add the public PDF URL here after hosting the guide.
SETUP_GUIDE_URL = ""

RECENT_FINISH_SECONDS = 30 * 60
STALE_WARNING_SECONDS = 5 * 60
STALE_CRITICAL_SECONDS = 15 * 60

PALETTE = {
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

    text = str(text)

    if len(text) <= max_len:
        return text

    if max_len <= 1:
        return text[:max_len]

    return text[:max_len - 1] + "…"

def _safe_get(obj, key, default = None):
    if type(obj) != "dict":
        return default

    return obj.get(key, default)

def _text(value):
    if value == None:
        return ""

    if type(value) == "list":
        parts = []

        for item in value:
            if item != None:
                item_text = str(item).strip()

                if item_text:
                    parts.append(item_text)

        return ", ".join(parts)

    return str(value).strip()

def _join_unique(values):
    parts = []

    for value in values:
        text = _text(value)

        if text and text not in parts:
            parts.append(text)

    return " · ".join(parts)

def _seconds(value):
    value_type = type(value)

    if value_type == "string":
        value = value.strip()
        digits = value

        if digits.startswith("-") or digits.startswith("+"):
            digits = digits[1:]

        if not digits:
            return None

        for char in digits:
            if char not in "0123456789":
                return None

    elif value_type != "int" and value_type != "float":
        return None

    value = int(value)

    if value < 0:
        return 0

    return value

def _fmt_duration(total):
    total = _seconds(total)

    if total == None:
        return "?"

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

def _parse_timestamp(value):
    text = _text(value)

    if not text:
        return None

    if text.endswith("Z"):
        text = text[:-1] + "+00:00"

    return time.parse_time(
        text,
        "2006-01-02T15:04:05Z07:00",
    )

def _age_seconds(value, now):
    parsed = _parse_timestamp(value)

    if parsed == None:
        return None

    age = int((now - parsed).seconds)

    if age < 0:
        return 0

    return age

def _status_url(config):
    direct = _text(config.get("status_url"))

    if direct:
        return direct

    # Retain compatibility with older base_url configurations.
    base = _text(config.get("base_url"))

    if not base:
        return DEFAULT_STATUS_URL

    if base.endswith("/status.json"):
        return base

    if base.endswith("/"):
        return base + "status.json"

    return base + "/status.json"

def _printers(data):
    printers = _safe_get(data, "printers", [])

    if type(printers) != "list":
        return []

    return [
        printer
        for printer in printers
        if type(printer) == "dict"
    ]

def printer_field(status_url):
    status_url = _text(status_url)

    if not status_url:
        return []

    resp = http.get(status_url)

    if resp.status_code != 200:
        return []

    data = json.decode(resp.body())
    options = []
    seen_ids = []

    for printer in _printers(data):
        pid = _text(printer.get("id"))
        name = _text(printer.get("name")) or pid

        if pid and pid not in seen_ids:
            seen_ids.append(pid)

            options.append(
                schema.Option(
                    display = name + " (" + pid + ")",
                    value = pid,
                ),
            )

    if not options:
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
    guide_reference = "See the PDF: " + SETUP_GUIDE_TITLE + "."

    if SETUP_GUIDE_URL:
        guide_reference += " " + SETUP_GUIDE_URL

    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "show_instructions",
                name = "Show Setup Instructions",
                desc = (
                    "Display setup help instead of printer status. " +
                    guide_reference
                ),
                icon = "info",
                default = False,
            ),
            schema.Text(
                id = "status_url",
                name = "Status JSON URL",
                desc = (
                    "Full HTTP URL to status.json. " +
                    guide_reference
                ),
                icon = "link",
                default = DEFAULT_STATUS_URL,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll speed.",
                icon = "truckFast",
                options = [
                    schema.Option(
                        display = "Slow",
                        value = "60",
                    ),
                    schema.Option(
                        display = "Medium",
                        value = "45",
                    ),
                    schema.Option(
                        display = "Fast",
                        value = "30",
                    ),
                ],
                default = DEFAULT_SCROLL,
            ),
            schema.Toggle(
                id = "active_only",
                name = "Only During Active Prints",
                desc = (
                    "Skip inactive printers, including recently completed " +
                    "prints. Setup instructions override this setting."
                ),
                icon = "play",
                default = False,
            ),
            schema.Toggle(
                id = "show_finish_time",
                name = "Estimated Finish Time",
                desc = (
                    "Add an estimated local finish time while printing."
                ),
                icon = "clock",
                default = True,
            ),
            schema.Toggle(
                id = "show_recent_finish",
                name = "Highlight Recent Completion",
                desc = (
                    "Show Finished for 30 minutes after the recorded " +
                    "completion time."
                ),
                icon = "check",
                default = True,
            ),
            schema.Toggle(
                id = "warn_stale",
                name = "Warn About Old Data",
                desc = (
                    "Warn after 5 minutes if JSON includes updated_at. " +
                    "Show STALE DATA after 15 minutes."
                ),
                icon = "circleExclamation",
                default = True,
            ),
            schema.Generated(
                id = "printer_picker",
                source = "status_url",
                handler = printer_field,
            ),
        ],
    )

def _first_printer(data, selected_id):
    printers = _printers(data)

    if not printers:
        return {}

    if selected_id:
        for printer in printers:
            if _text(printer.get("id")) == selected_id:
                return printer

        # Never silently substitute a different printer.
        return {}

    return printers[0]

def _state(printer):
    return _text(printer.get("state")).upper() or "UNKNOWN"

def _status_color(state):
    if state == "PRINTING":
        return PALETTE["success"]

    if state == "PAUSED":
        return PALETTE["warning"]

    if state == "OFFLINE":
        return PALETTE["error"]

    if state == "IDLE":
        return PALETTE["info"]

    if state == "ERROR":
        return PALETTE["error"]

    return PALETTE["text_primary"]

def _is_active(state):
    return state == "PRINTING" or state == "PAUSED"

def _job_name(printer, max_len):
    name = _join_unique([
        printer.get("job_name"),
        printer.get("plate_name"),
        printer.get("job_objects"),
    ])

    return _truncate(name or "No active print", max_len)

def _last_job_name(printer, max_len):
    name = _join_unique([
        printer.get("last_completed_job_name"),
        printer.get("last_completed_job_objects"),
    ])

    return _truncate(name or "No recent job", max_len)

def _headline(printer, now, recently_finished, finish_age):
    state = _state(printer)

    if state == "PRINTING":
        progress = printer.get("progress")

        if progress != None:
            return "Printing · " + str(progress) + "%"

        return "Printing"

    if state == "PAUSED":
        return "Paused"

    if state == "OFFLINE":
        return "Offline"

    if state == "IDLE":
        if recently_finished:
            return "Finished · " + _fmt_duration(finish_age) + " ago"

        idle_age = _age_seconds(
            printer.get("idle_since"),
            now,
        )

        if idle_age == None:
            idle_age = finish_age

        if idle_age != None:
            return "Idle · " + _fmt_duration(idle_age)

        return "Idle"

    return state

def _subline(printer, max_len):
    state = _state(printer)

    if _is_active(state):
        return _job_name(printer, max_len)

    if state == "IDLE":
        return _last_job_name(printer, max_len)

    name = (
        _text(printer.get("job_objects")) or
        _text(printer.get("job_name")) or
        "Waiting"
    )

    return _truncate(name, max_len)

def _finish_label(now, remaining, timezone):
    finish = now + time.parse_duration(
        str(remaining) + "s",
    )

    local_now = now.in_location(timezone)
    local_finish = finish.in_location(timezone)

    clock = local_finish.format("3:04 PM")
    today = local_now.format("2006-01-02")
    finish_date = local_finish.format("2006-01-02")

    if finish_date == today:
        return "Done ~" + clock

    # Local noon plus 24 hours identifies tomorrow across DST changes.
    local_noon = time.parse_time(
        today + " 12:00:00",
        "2006-01-02 15:04:05",
        timezone,
    )

    tomorrow = local_noon + time.parse_duration("24h")

    if finish_date == tomorrow.format("2006-01-02"):
        return "Done ~Tomorrow " + clock

    return "Done ~" + local_finish.format("Jan 2, 3:04 PM")

def _footer(printer, now, timezone, show_finish_time):
    state = _state(printer)

    if state == "PRINTING":
        remaining = _seconds(printer.get("time_left"))

        if remaining != None:
            if remaining == 0:
                return "Finishing · awaiting update"

            text = _fmt_duration(remaining) + " left"

            if show_finish_time:
                text += " · " + _finish_label(
                    now,
                    remaining,
                    timezone,
                )

            return text

        estimate = _text(
            printer.get("estimated_duration_text"),
        )

        if estimate:
            return "Est. " + estimate

        return "Printing"

    if state == "PAUSED":
        return "Print paused"

    if state == "IDLE":
        duration = _text(
            printer.get("last_completed_duration_text"),
        )

        if not duration:
            seconds = _seconds(
                printer.get("last_completed_duration_seconds"),
            )

            if seconds != None:
                duration = _fmt_duration(seconds)

        if duration:
            return "Last print: " + duration

        return "No print history"

    return "Waiting"

def _message_screen(font, delay, line2, line3, line4):
    return render.Root(
        center_on_square(render.Column(
            children = [
                render.Text(
                    content = "Bambu Status",
                    font = font,
                    color = PALETTE["text_primary"],
                ),
                render.Text(
                    content = line2,
                    font = font,
                    color = PALETTE["warning"],
                ),
                render.Text(
                    content = line3,
                    font = font,
                    color = PALETTE["text_secondary"],
                ),
                render.Text(
                    content = line4,
                    font = font,
                    color = PALETTE["text_muted"],
                ),
            ],
        )),
        show_full_animation = True,
        delay = delay,
    )

def _instructions_screen(
        font,
        delay,
        screen_width,
        font_width):
    line2 = (
        "1. Read the PDF supplied with this app. " +
        "2. Create status.json using its Python script."
    )

    line3 = (
        "3. Schedule updates every minute. " +
        "4. Serve status.json over HTTP."
    )

    line4 = (
        "5. Enter the JSON URL and select a printer. " +
        "6. Turn off Show Setup Instructions."
    )

    offset3 = len(line2) * font_width
    offset4 = offset3 + len(line3) * font_width

    return render.Root(
        center_on_square(render.Column(
            children = [
                render.Text(
                    content = "Bambu Status",
                    font = font,
                    color = PALETTE["text_primary"],
                ),
                render.Marquee(
                    width = screen_width,
                    child = render.Text(
                        content = line2,
                        font = font,
                        color = PALETTE["text_primary"],
                    ),
                ),
                render.Marquee(
                    offset_start = offset3,
                    width = screen_width,
                    child = render.Text(
                        content = line3,
                        font = font,
                        color = PALETTE["text_secondary"],
                    ),
                ),
                render.Marquee(
                    offset_start = offset4,
                    width = screen_width,
                    child = render.Text(
                        content = line4,
                        font = font,
                        color = PALETTE["text_muted"],
                    ),
                ),
            ],
        )),
        show_full_animation = True,
        delay = delay,
    )

def main(config):
    font = "tb-8"
    screen_width = 64
    font_width = 5
    max_text_length = 150

    scroll = str(config.get("scroll") or DEFAULT_SCROLL)

    if scroll not in ["60", "45", "30"]:
        scroll = DEFAULT_SCROLL

    delay = int(scroll)

    if canvas.is2x():
        delay = int(delay / 2)
        font = "terminus-16"
        screen_width = 128
        font_width = 8
        max_text_length = 300

    # Instructions work without a configured status URL.
    if config.bool("show_instructions", False):
        return _instructions_screen(
            font,
            delay,
            screen_width,
            font_width,
        )

    timezone = config.get("$tz") or DEFAULT_TIMEZONE
    now = time.now()

    status_url = _status_url(config)

    if not status_url:
        return _message_screen(
            font,
            delay,
            "No status URL",
            "Enable setup",
            "instructions",
        )

    resp = http.get(status_url)

    if resp.status_code != 200:
        return _message_screen(
            font,
            delay,
            "HTTP error",
            str(resp.status_code),
            "Check URL",
        )

    data = json.decode(resp.body())

    if type(data) != "dict":
        return _message_screen(
            font,
            delay,
            "Invalid data",
            "Expected JSON",
            "object",
        )

    if type(data.get("printers")) != "list":
        return _message_screen(
            font,
            delay,
            "Invalid data",
            "No printers",
            "list in JSON",
        )

    selected_id = _text(config.get("printer_id"))
    printer = _first_printer(data, selected_id)
    active_only = config.bool("active_only", False)

    if not printer:
        if active_only:
            return []

        if selected_id:
            return _message_screen(
                font,
                delay,
                "Not found",
                "Selected",
                "printer",
            )

        return _message_screen(
            font,
            delay,
            "No printers",
            "Check status",
            "JSON source",
        )

    state = _state(printer)

    if active_only and not _is_active(state):
        return []

    finish_age = _age_seconds(
        printer.get("last_completed_end_time"),
        now,
    )

    recently_finished = (
        config.bool("show_recent_finish", True) and
        state == "IDLE" and
        finish_age != None and
        finish_age < RECENT_FINISH_SECONDS
    )

    printer_name = _truncate(
        _text(printer.get("name")) or "Bambu Printer",
        max_text_length,
    )

    line2 = _headline(
        printer,
        now,
        recently_finished,
        finish_age,
    )

    line3 = _subline(
        printer,
        max_text_length,
    )

    line4 = _footer(
        printer,
        now,
        timezone,
        config.bool("show_finish_time", True),
    )

    status_color = _status_color(state)
    footer_color = PALETTE["text_muted"]

    if recently_finished:
        status_color = PALETTE["success"]

    # This measures timestamp age, not API-call success.
    updated_at = (
        printer.get("updated_at") or
        data.get("updated_at")
    )

    if config.bool("warn_stale", True) and updated_at:
        data_age = _age_seconds(updated_at, now)

        if data_age != None and data_age >= STALE_WARNING_SECONDS:
            line4 = "Status " + _fmt_duration(data_age) + " old"
            footer_color = PALETTE["warning"]

            if data_age >= STALE_CRITICAL_SECONDS:
                line2 = "STALE DATA"
                status_color = PALETTE["error"]

                line4 = (
                    "Last state: " + state +
                    " · Updated " + _fmt_duration(data_age) + " ago"
                )

    line4 = _truncate(line4, max_text_length)

    # Preserve the original staggered scrolling calculation.
    footer_offset = len(line3) * font_width

    return render.Root(
        center_on_square(render.Column(
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
                        font = font,
                        color = PALETTE["text_primary"],
                    ),
                ),
                render.Marquee(
                    offset_start = footer_offset,
                    width = screen_width,
                    child = render.Text(
                        content = line4,
                        font = font,
                        color = footer_color,
                    ),
                ),
            ],
        )),
        show_full_animation = True,
        delay = delay,
    )
