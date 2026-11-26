"""
Applet: Bambu Printer Status
Summary: Bambu Printer Status
Description: View the current or most recently completed Bambu print.
Authors: Robert Ison
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_STATUS_URL = ""
DEFAULT_SCROLL = "60"
DEFAULT_TIMEZONE = "America/New_York"

SETUP_GUIDE_TITLE = "Bambu Printer Status JSON Setup Instructions"
SETUP_GUIDE_URL = ""

PREVIOUS_STATUS_TTL_SECONDS = 30 * 24 * 60 * 60

# Logging and forced playback are separate.
# Leave both False for normal use.
DEBUG_LOGGING = False
DEBUG_FORCE_SOUND = False

NOTIFICATION_SOUNDS = [
    "chime",
    "ding",
    "bell",
    "pop",
    "alert",
    "tron",
]

PALETTE = {
    "text_primary": "FFFFFF",
    "text_secondary": "C7CDD4",
    "text_muted": "7F8790",
    "success": "A6FF00",
    "warning": "FFD84D",
    "error": "FF5A5F",
    "info": "58D1FF",
}

def _debug(message):
    if DEBUG_LOGGING:
        print("[BambuDebug] " + message)

def is_square():
    w, h = canvas.size()
    return h == w

def center_on_square(child, width = None, height = None):
    if not is_square():
        return child

    if width != None and height != None:
        child = render.Box(
            width = width,
            height = height,
            child = child,
        )

    return render.Box(
        width = canvas.width(),
        height = canvas.height(),
        child = child,
    )

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

def _truncate(value, max_len):
    text = _text(value)

    if len(text) <= max_len:
        return text

    if max_len <= 1:
        return text[:max_len]

    return text[:max_len - 1] + "…"

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

    return max(0, int(value))

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

    if hrs >= 24:
        days = hrs // 24
        rem_hrs = hrs % 24

        if rem_hrs == 0:
            return str(days) + "d"

        return str(days) + "d " + str(rem_hrs) + "h"

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

def _status_url(config):
    direct = _text(config.get("status_url"))

    if direct:
        return direct

    # Compatibility with older configurations.
    base = _text(config.get("base_url"))

    if not base:
        return DEFAULT_STATUS_URL

    if base.endswith("/status.json"):
        return base

    if base.endswith("/"):
        return base + "status.json"

    return base + "/status.json"

def _printers(data):
    if type(data) != "dict":
        return []

    printers = data.get("printers", [])

    if type(printers) != "list":
        return []

    return [
        printer
        for printer in printers
        if type(printer) == "dict"
    ]

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
    if printer.get("online") == False:
        return "OFFLINE"

    return _text(printer.get("state")).upper() or "UNKNOWN"

def _is_active(state):
    return state == "PRINTING" or state == "PAUSED"

def printer_field(status_url):
    status_url = _text(status_url)

    _debug(
        "Printer picker handler called; status URL supplied=" +
        str(bool(status_url)),
    )

    if not status_url:
        return []

    response = http.get(status_url)

    _debug(
        "Printer picker: status JSON HTTP " +
        str(response.status_code),
    )

    if response.status_code != 200:
        return []

    data = json.decode(response.body())
    options = []
    seen_ids = []

    for printer in _printers(data):
        printer_id = _text(printer.get("id"))
        name = _text(printer.get("name")) or printer_id

        if printer_id and printer_id not in seen_ids:
            seen_ids.append(printer_id)

            options.append(
                schema.Option(
                    display = name + " (" + printer_id + ")",
                    value = printer_id,
                ),
            )

    _debug(
        "Printer picker: found " +
        str(len(options)) +
        " printer option(s).",
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

def audio_notification_fields(sound):
    visible = _text(sound) in NOTIFICATION_SOUNDS

    _debug(
        "Audio settings handler called: type=" +
        type(sound) +
        "; value=" +
        str(sound),
    )

    _debug("Audio settings visible=" + str(visible))

    if not visible:
        return []

    return [
        schema.Text(
            id = "notification_server_url",
            name = "Tronbyt Server URL",
            desc = (
                "Server URL reachable by Pixlet, including port if needed. " +
                "Example: http://tronbyt.local:8000"
            ),
            icon = "link",
            default = "",
        ),
        schema.Text(
            id = "notification_device_id",
            name = "Notification Device ID",
            desc = "Tronbyt device ID of the display that plays the sound.",
            icon = "info",
            default = "",
        ),
        schema.Text(
            id = "notification_api_key",
            name = "Notification API Key",
            desc = (
                "Device API key from Tronbyt. Treat this value as a secret. " +
                "Do not include it in the source code."
            ),
            icon = "lock",
            default = "",
        ),
    ]

def get_schema():
    if SETUP_GUIDE_URL:
        guide_reference = "Setup guide: " + SETUP_GUIDE_URL
    else:
        guide_reference = (
            "Ask the app provider for the PDF titled '" +
            SETUP_GUIDE_TITLE +
            "'. No public guide URL is configured."
        )

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
                name = "Scroll Speed",
                desc = "Choose the scrolling speed.",
                icon = "truckFast",
                default = DEFAULT_SCROLL,
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
            ),
            schema.Toggle(
                id = "hide_when_offline",
                name = "Hide When Printer Offline",
                desc = (
                    "Hide this app when the selected printer reports offline. " +
                    "Setup instructions and configuration or data errors " +
                    "remain visible."
                ),
                icon = "plug",
                default = False,
            ),
            schema.Generated(
                id = "printer_picker",
                source = "status_url",
                handler = printer_field,
            ),
            schema.Dropdown(
                id = "notification_sound",
                name = "Notification Sound",
                desc = (
                    "Gen 2 support only. Play when printing changes to idle. " +
                    "Choose No sound to disable."
                ),
                icon = "bell",
                default = "none",
                options = [
                    schema.Option(
                        display = "No sound",
                        value = "none",
                    ),
                    schema.Option(
                        display = "Chime",
                        value = "chime",
                    ),
                    schema.Option(
                        display = "Ding",
                        value = "ding",
                    ),
                    schema.Option(
                        display = "Bell",
                        value = "bell",
                    ),
                    schema.Option(
                        display = "Pop",
                        value = "pop",
                    ),
                    schema.Option(
                        display = "Alert",
                        value = "alert",
                    ),
                    schema.Option(
                        display = "Tron Bit",
                        value = "tron",
                    ),
                ],
            ),
            schema.Text(
                id = "notification_server_url",
                name = "Tronbyt Server URL",
                desc = (
                    "OPTIONAL - Only Needed for Gen 2 with Sound Option. " +
                    "Server URL reachable by Pixlet, including port. " +
                    "Example: http://tronbyt.local:8000"
                ),
                icon = "link",
                default = "",
            ),
            schema.Text(
                id = "notification_device_id",
                name = "Notification Device ID",
                desc = (
                    "OPTIONAL - Only Needed for Gen 2 with Sound Option. " +
                    "Tronbyt device ID of the display that plays the sound."
                ),
                icon = "info",
                default = "",
            ),
            schema.Text(
                id = "notification_api_key",
                name = "Notification API Key",
                desc = (
                    "OPTIONAL - Only Needed for Gen 2 with Sound Option. " +
                    "Device API key from Tronbyt. Treat this value as a secret."
                ),
                icon = "lock",
                default = "",
            ),
        ],
    )

def _check_completion_notification(config, status_url, printer):
    current_state = _state(printer)
    printer_id = _text(printer.get("id"))
    device_id = _text(config.get("notification_device_id"))
    sound = _text(config.get("notification_sound")) or "none"

    server_url = _text(
        config.get("notification_server_url"),
    ).rstrip("/")

    api_key = _text(config.get("notification_api_key"))

    # Preserve the existing cache key and completion-trigger behavior.
    cache_key = "bambuprinterstatus:previous-state:v1:" + json.encode([
        status_url,
        printer_id,
        device_id,
    ])

    previous_state = cache.get(cache_key)

    _debug(
        "Completion check: printer=" +
        printer_id +
        "; previous=" +
        str(previous_state) +
        "; current=" +
        current_state +
        "; sound=" +
        sound,
    )

    _debug(
        "Connection settings present: server=" +
        str(bool(server_url)) +
        "; device=" +
        str(bool(device_id)) +
        "; API key=" +
        str(bool(api_key)),
    )

    # Save before playback, preserving existing no-retry behavior.
    cache.set(
        cache_key,
        current_state,
        ttl_seconds = PREVIOUS_STATUS_TTL_SECONDS,
    )

    if DEBUG_FORCE_SOUND:
        _debug(
            "DEBUG_FORCE_SOUND enabled: forcing a sound attempt " +
            "without requiring a completion transition.",
        )
    else:
        if previous_state != "PRINTING" or current_state != "IDLE":
            _debug(
                "Sound NOT attempted: no direct PRINTING -> IDLE " +
                "transition, or first observation.",
            )
            return

        _debug("Direct PRINTING -> IDLE transition detected.")

    if sound not in NOTIFICATION_SOUNDS:
        _debug(
            "Sound NOT attempted: disabled or invalid sound selection.",
        )
        return

    missing = []

    if not server_url:
        missing.append("Tronbyt Server URL")

    if not device_id:
        missing.append("Notification Device ID")

    if not api_key:
        missing.append("Notification API Key")

    if missing:
        print(
            "[BambuAudio] Sound NOT attempted: missing " +
            ", ".join(missing),
        )
        return

    # Do not log the URL or authorization headers.
    _debug(
        "Sound POST ATTEMPT: device=" +
        device_id +
        "; sound=" +
        sound,
    )

    response = http.post(
        server_url + "/v0/devices/" + device_id + "/sound",
        headers = {
            "Authorization": "Bearer " + api_key,
        },
        json_body = {
            "sound": sound,
        },
    )

    body = response.body().replace(api_key, "[REDACTED]")

    _debug(
        "Sound POST response: HTTP " +
        str(response.status_code) +
        "; body=" +
        _truncate(body, 1000),
    )

    if response.status_code == 200:
        _debug(
            "Sound request ACCEPTED by server; " +
            "audible playback is not confirmed.",
        )
    else:
        print(
            "[BambuAudio] Sound request FAILED: HTTP " +
            str(response.status_code) +
            "; body=" +
            _truncate(body, 1000),
        )

def _status_color(state):
    if state == "PRINTING":
        return PALETTE["success"]

    if state == "PAUSED":
        return PALETTE["warning"]

    if state == "ERROR" or state == "OFFLINE":
        return PALETTE["error"]

    if state == "IDLE":
        return PALETTE["info"]

    return PALETTE["text_primary"]

def _current_job_name(printer, max_len):
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

    return _truncate(name or "No print history", max_len)

def _has_last_job(printer):
    for key in [
        "last_completed_job_id",
        "last_completed_job_name",
        "last_completed_job_objects",
        "last_completed_end_time",
        "last_completed_duration_seconds",
        "last_completed_duration_text",
    ]:
        if _text(printer.get(key)):
            return True

    return False

def _last_duration(printer):
    duration = _text(
        printer.get("last_completed_duration_text"),
    )

    if duration:
        return duration

    seconds = _seconds(
        printer.get("last_completed_duration_seconds"),
    )

    if seconds != None:
        return _fmt_duration(seconds)

    return ""

def _error_detail(printer):
    for key in ["error_message", "error_text", "error"]:
        value = printer.get(key)

        if type(value) == "string":
            text = value.strip()

            if text:
                return text

    return ""

def _finish_label(now, finish, timezone):
    local_now = now.in_location(timezone)
    local_finish = finish.in_location(timezone)

    clock = local_finish.format("3:04 PM")
    today = local_now.format("2006-01-02")
    finish_date = local_finish.format("2006-01-02")

    if finish_date == today:
        return "Done ~" + clock

    local_noon = time.parse_time(
        today + " 12:00:00",
        "2006-01-02 15:04:05",
        timezone,
    )

    tomorrow = local_noon + time.parse_duration("24h")

    if finish_date == tomorrow.format("2006-01-02"):
        return "Done ~Tomorrow " + clock

    return "Done ~" + local_finish.format("Jan 2, 3:04 PM")

def _print_timing(printer, now, updated_at):
    remaining = _seconds(printer.get("time_left"))

    if remaining == None:
        return {
            "remaining": None,
            "finish": None,
        }

    anchor = _parse_timestamp(updated_at)

    if anchor == None:
        anchor = now
    elif int((anchor - now).seconds) > 0:
        # Do not add future clock skew to the estimate.
        anchor = now

    finish = anchor + time.parse_duration(
        str(remaining) + "s",
    )

    return {
        "remaining": max(0, int((finish - now).seconds)),
        "finish": finish,
    }

def _headline(printer):
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

    if state == "ERROR":
        return "Error"

    if state == "IDLE":
        if _has_last_job(printer):
            return "Last print finished"

        return "Idle"

    if state == "UNKNOWN":
        return "Unknown"

    return _truncate(state, 20)

def _subline(printer, max_len):
    state = _state(printer)

    if _is_active(state):
        return _current_job_name(printer, max_len)

    if state == "IDLE":
        return _last_job_name(printer, max_len)

    name = _join_unique([
        printer.get("job_name"),
        printer.get("plate_name"),
        printer.get("job_objects"),
    ])

    if name:
        return _truncate(name, max_len)

    if _has_last_job(printer):
        return _last_job_name(printer, max_len)

    if state == "ERROR":
        return "Printer needs attention"

    if state == "OFFLINE":
        return "No live connection"

    return "No current job"

def _footer(printer, now, timezone, updated_at):
    state = _state(printer)

    if state == "PRINTING":
        timing = _print_timing(
            printer,
            now,
            updated_at,
        )

        remaining = timing["remaining"]

        if remaining != None:
            if remaining == 0:
                return "Finishing · awaiting update"

            return (
                _fmt_duration(remaining) +
                " left · " +
                _finish_label(now, timing["finish"], timezone)
            )

        estimate = _text(
            printer.get("estimated_duration_text"),
        )

        if estimate:
            return "Est. duration " + estimate

        return "Time remaining unavailable"

    if state == "PAUSED":
        detail = _error_detail(printer)

        if detail:
            return "Paused · " + detail

        return "Print paused · Check printer"

    if state == "ERROR":
        return _error_detail(printer) or "Check printer"

    if state == "OFFLINE":
        return "Printer unavailable"

    if state == "IDLE":
        if not _has_last_job(printer):
            return "No print history"

        parts = []

        finished_at = _parse_timestamp(
            printer.get("last_completed_end_time"),
        )

        if finished_at != None:
            age = max(0, int((now - finished_at).seconds))
            parts.append("Finished " + _fmt_duration(age) + " ago")

        duration = _last_duration(printer)

        if duration:
            parts.append("Print took " + duration)

        return " · ".join(parts) or "No active print"

    return "Status unavailable"

def _message_screen(font, delay, line2, line3, line4):
    return render.Root(
        center_on_square(
            render.Column(
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
            ),
        ),
        show_full_animation = True,
        delay = delay,
    )

def _instructions_screen(font, delay, screen_width, font_width):
    line2 = "Use the PDF guide to create your status feed. Enter its Status JSON URL and select your printer."

    line3 = "Optional Gen 2 sound: choose a tone, then enter the Tronbyt server URL, display device ID, and API key."

    line4 = "Leave No sound selected to skip audio setup. Turn off Show Setup Instructions to view printer status."

    offset3 = len(line2) * font_width
    offset4 = offset3 + len(line3) * font_width

    return render.Root(
        center_on_square(
            render.Column(
                children = [
                    render.Text(
                        content = "Bambu Setup",
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
            ),
        ),
        show_full_animation = True,
        delay = delay,
    )

def main(config):
    _debug("main() started: simplified Bambu Printer Status")

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

    if config.bool("show_instructions", False):
        _debug("Showing setup instructions.")

        return _instructions_screen(
            font,
            delay,
            screen_width,
            font_width,
        )

    status_url = _status_url(config)

    if not status_url:
        _debug("No status URL configured.")

        return _message_screen(
            font,
            delay,
            "No status URL",
            "Enable setup",
            "instructions",
        )

    _debug("Fetching status JSON (URL withheld).")

    response = http.get(status_url)

    _debug(
        "Status JSON response: HTTP " +
        str(response.status_code),
    )

    if response.status_code != 200:
        return _message_screen(
            font,
            delay,
            "HTTP error",
            str(response.status_code),
            "Check URL",
        )

    data = json.decode(response.body())

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

    if not printer:
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

    # Notification tracking runs independently of offline visibility.
    _check_completion_notification(
        config,
        status_url,
        printer,
    )

    if config.bool("hide_when_offline", False) and state == "OFFLINE":
        _debug("Display hidden because the printer reports offline.")
        return []

    timezone = config.get("$tz") or DEFAULT_TIMEZONE
    now = time.now()

    updated_at = (
        printer.get("updated_at") or
        data.get("updated_at")
    )

    printer_name = _truncate(
        _text(printer.get("name")) or "Bambu Printer",
        max_text_length,
    )

    line2 = _headline(printer)

    line3 = _subline(
        printer,
        max_text_length,
    )

    line4 = _truncate(
        _footer(
            printer,
            now,
            timezone,
            updated_at,
        ),
        max_text_length,
    )

    status_color = _status_color(state)
    footer_color = PALETTE["text_muted"]

    if state == "ERROR":
        footer_color = PALETTE["error"]
    elif state == "PAUSED":
        footer_color = PALETTE["warning"]

    footer_offset = len(line3) * font_width

    return render.Root(
        center_on_square(
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
            ),
        ),
        show_full_animation = True,
        delay = delay,
    )
