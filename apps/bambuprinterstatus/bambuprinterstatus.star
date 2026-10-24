"""
Applet: Bambu Printer Status
Summary: Bambu Printer Status
Description: View printer status, estimated finish time, and recent print history.
Authors: Robert Ison
"""

load("cache.star", "cache")
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

DEFAULT_STATUS_URL = ""
DEFAULT_SCROLL = "60"
DEFAULT_TIMEZONE = "America/New_York"

SETUP_GUIDE_TITLE = "Bambu Printer Status JSON Setup Instructions"

# Add the public PDF URL here after hosting the guide.
SETUP_GUIDE_URL = ""

RECENT_FINISH_SECONDS = 30 * 60
STALE_WARNING_SECONDS = 5 * 60
STALE_CRITICAL_SECONDS = 15 * 60
FUTURE_TIMESTAMP_TOLERANCE_SECONDS = 2 * 60

PREVIOUS_STATUS_TTL_SECONDS = 30 * 24 * 60 * 60

# "none" is deliberately excluded: only these values trigger playback.
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

def _timestamp_info(value, now):
    parsed = _parse_timestamp(value)

    if parsed == None:
        return {
            "time": None,
            "age": None,
            "future": False,
        }

    age = int((now - parsed).seconds)

    if age < -FUTURE_TIMESTAMP_TOLERANCE_SECONDS:
        return {
            "time": parsed,
            "age": None,
            "future": True,
        }

    return {
        "time": parsed,
        "age": max(0, age),
        "future": False,
    }

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

def audio_notification_fields(sound):
    # Connection settings appear only when an actual sound is selected.
    if _text(sound) not in NOTIFICATION_SOUNDS:
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
            desc = "Tronbyt device ID of your Gen 2 display.",
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
        guide_reference = (
            "Setup guide: " + SETUP_GUIDE_URL
        )
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
                    "Hide idle and recently completed prints. " +
                    "Errors and enabled data warnings remain visible. " +
                    "Setup instructions override this setting."
                ),
                icon = "play",
                default = False,
            ),
            schema.Toggle(
                id = "always_show_offline",
                name = "Always Show Offline",
                desc = (
                    "Show an offline printer even when Only During " +
                    "Active Prints is enabled."
                ),
                icon = "plug",
                default = False,
            ),
            schema.Toggle(
                id = "show_finish_time",
                name = "Estimated Finish Time",
                desc = (
                    "Add an estimated local finish time while printing. " +
                    "Use updated_at to anchor the estimate when available."
                ),
                icon = "flagCheckered",
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
            schema.Generated(
                id = "audio_notification_settings",
                source = "notification_sound",
                handler = audio_notification_fields,
            ),
            schema.Toggle(
                id = "warn_stale",
                name = "Warn About Old Data",
                desc = (
                    "Warn after 5 minutes if JSON includes updated_at. " +
                    "Show STALE DATA after 15 minutes. Also warn about " +
                    "timestamps more than 2 minutes in the future."
                ),
                icon = "triangleExclamation",
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

def _check_completion_notification(config, status_url, printer):
    current_state = _state(printer)
    printer_id = _text(printer.get("id"))
    device_id = _text(config.get("notification_device_id"))

    # Cache is shared. Separate sources, printers, and notification devices.
    cache_key = "bambuprinterstatus:previous-state:v1:" + json.encode([
        status_url,
        printer_id,
        device_id,
    ])

    previous_state = cache.get(cache_key)

    # Record all observed states, including when No sound is selected.
    # Update before sending so failed requests do not repeat the alert.
    cache.set(
        cache_key,
        current_state,
        ttl_seconds = PREVIOUS_STATUS_TTL_SECONDS,
    )

    # First observation only initializes tracking.
    # Only the direct PRINTING -> IDLE transition triggers notification.
    if previous_state != "PRINTING" or current_state != "IDLE":
        return

    sound = _text(config.get("notification_sound")) or "none"

    # No sound, missing values, and invalid choices remain silent.
    if sound not in NOTIFICATION_SOUNDS:
        return

    server_url = _text(
        config.get("notification_server_url"),
    ).rstrip("/")

    api_key = _text(config.get("notification_api_key"))

    if not server_url or not device_id or not api_key:
        print(
            "Completion audio skipped: notification settings are incomplete.",
        )
        return

    response = http.post(
        server_url + "/v0/devices/" + device_id + "/sound",
        headers = {
            "Authorization": "Bearer " + api_key,
        },
        json_body = {
            "sound": sound,
        },
    )

    if response.status_code != 200:
        print(
            "Completion audio failed: HTTP " +
            str(response.status_code),
        )

def _status_color(state):
    if state == "PRINTING":
        return PALETTE["success"]

    if state == "PAUSED":
        return PALETTE["warning"]

    if state == "OFFLINE" or state == "ERROR":
        return PALETTE["error"]

    if state == "IDLE":
        return PALETTE["info"]

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

def _headline(printer, recently_finished):
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
        if recently_finished:
            return "Finished"

        return "Idle"

    if state == "UNKNOWN":
        return "Unknown"

    return _truncate(state, 12)

def _subline(printer, max_len):
    state = _state(printer)

    if _is_active(state):
        return _job_name(printer, max_len)

    if state == "IDLE":
        return _last_job_name(printer, max_len)

    name = _join_unique([
        printer.get("job_name"),
        printer.get("plate_name"),
        printer.get("job_objects"),
    ])

    if name:
        return _truncate(name, max_len)

    if state == "ERROR":
        return "Printer needs attention"

    if state == "OFFLINE":
        return "No live connection"

    return "No current job"

def _finish_label(now, finish, timezone):
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

def _print_timing(printer, now, update_info):
    remaining = _seconds(printer.get("time_left"))

    if remaining == None:
        return {
            "remaining": None,
            "finish": None,
        }

    anchor = now

    if update_info["time"] != None and not update_info["future"]:
        anchor = update_info["time"]

        # Small future clock skew is tolerated, not added to the estimate.
        if int((anchor - now).seconds) > 0:
            anchor = now

    finish = anchor + time.parse_duration(
        str(remaining) + "s",
    )

    adjusted_remaining = max(
        0,
        int((finish - now).seconds),
    )

    return {
        "remaining": adjusted_remaining,
        "finish": finish,
    }

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
    # Optional existing fields; no JSON producer change is required.
    for key in ["error_message", "error_text", "error"]:
        value = printer.get(key)

        if type(value) == "string":
            text = value.strip()

            if text:
                return text

    return ""

def _footer(
        printer,
        now,
        timezone,
        show_finish_time,
        update_info,
        recently_finished,
        finish_info,
        idle_info):
    state = _state(printer)

    if state == "PRINTING":
        timing = _print_timing(
            printer,
            now,
            update_info,
        )
        remaining = timing["remaining"]

        if remaining != None:
            if remaining == 0:
                return "Finishing · awaiting update"

            text = _fmt_duration(remaining) + " left"

            if show_finish_time:
                text += " · " + _finish_label(
                    now,
                    timing["finish"],
                    timezone,
                )

            return text

        estimate = _text(
            printer.get("estimated_duration_text"),
        )

        if estimate:
            return "Est. " + estimate

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
        parts = []
        duration = _last_duration(printer)

        if recently_finished:
            parts.append(
                _fmt_duration(finish_info["age"]) + " ago",
            )

            if duration:
                parts.append("Print took " + duration)

            return " · ".join(parts)

        idle_age = idle_info["age"]

        if idle_age == None and not idle_info["future"]:
            idle_age = finish_info["age"]

        if idle_age != None:
            parts.append("Idle " + _fmt_duration(idle_age))

        if duration:
            parts.append("Last print: " + duration)
        else:
            parts.append("No print history")

        return " · ".join(parts)

    return "Status unavailable"

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
    if SETUP_GUIDE_URL:
        guide_text = (
            "1. Open the setup guide linked in this app's settings. "
        )
    else:
        guide_text = (
            "1. Ask the app provider for the PDF titled '" +
            SETUP_GUIDE_TITLE +
            "'. No public guide URL is configured. "
        )

    line2 = (
        guide_text +
        "2. Create status.json using the guide's Python script."
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

    # Configuration/data failures remain visible in active-only mode.
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

    # Run before active-only mode can hide the idle screen.
    _check_completion_notification(
        config,
        status_url,
        printer,
    )

    active_only = config.bool("active_only", False)
    warn_stale = config.bool("warn_stale", True)

    updated_at = (
        printer.get("updated_at") or
        data.get("updated_at")
    )

    update_info = _timestamp_info(updated_at, now)
    finish_info = _timestamp_info(
        printer.get("last_completed_end_time"),
        now,
    )

    idle_info = _timestamp_info(None, now)

    if state == "IDLE":
        idle_info = _timestamp_info(
            printer.get("idle_since"),
            now,
        )

    data_age = update_info["age"]

    stale_warning = (
        data_age != None and
        data_age >= STALE_WARNING_SECONDS
    )

    # Only flag completion/idle timestamps when relevant to the display.
    clock_warning = update_info["future"]

    if state == "IDLE":
        clock_warning = (
            clock_warning or
            finish_info["future"] or
            idle_info["future"]
        )

    visible_data_warning = (
        warn_stale and
        (stale_warning or clock_warning)
    )

    always_show_offline = config.bool(
        "always_show_offline",
        False,
    )

    if active_only:
        show_printer = (
            _is_active(state) or
            state == "ERROR" or
            visible_data_warning or
            (state == "OFFLINE" and always_show_offline)
        )

        if not show_printer:
            return []

    recently_finished = (
        config.bool("show_recent_finish", True) and
        state == "IDLE" and
        finish_info["age"] != None and
        finish_info["age"] < RECENT_FINISH_SECONDS
    )

    printer_name = _truncate(
        _text(printer.get("name")) or "Bambu Printer",
        max_text_length,
    )

    line2 = _headline(
        printer,
        recently_finished,
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
        update_info,
        recently_finished,
        finish_info,
        idle_info,
    )

    status_color = _status_color(state)
    footer_color = PALETTE["text_muted"]

    if recently_finished:
        status_color = PALETTE["success"]

    if state == "ERROR":
        footer_color = PALETTE["error"]
    elif state == "PAUSED":
        footer_color = PALETTE["warning"]

    warning_parts = []

    if warn_stale:
        if stale_warning:
            if data_age >= STALE_CRITICAL_SECONDS:
                line2 = "STALE DATA"
                status_color = PALETTE["error"]

                warning_parts.append(
                    "Last state: " + state +
                    " · Updated " + _fmt_duration(data_age) + " ago",
                )
            else:
                warning_parts.append(
                    "Status " + _fmt_duration(data_age) + " old",
                )

        if clock_warning:
            if update_info["future"]:
                warning_parts.append(
                    "Update timestamp is in the future · Check clocks",
                )
            else:
                warning_parts.append(
                    "Job timestamp is in the future · Check clocks",
                )

        if warning_parts:
            # Preserve actionable error details alongside data warnings.
            if state == "ERROR":
                detail = _error_detail(printer) or "Check printer"
                warning_parts.append(detail)

            line4 = " · ".join(warning_parts)
            footer_color = PALETTE["warning"]

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
