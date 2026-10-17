"""
Applet: Rachio
Summary: Rachio sprinkler system
Description: View recent activity and inferred running status for a Rachio sprinkler system.
Authors: Matt Fischer and Rob Ison
"""

load("http.star", "http")
load("images/rachio_icon.png", RACHIO_ICON_ASSET = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

RACHIO_ICON = RACHIO_ICON_ASSET.readall()

RACHIO_BLUE = "#0070D2"
RACHIO_SECONDARY_COLOR = "#00A676"

RACHIO_URL = "https://api.rach.io/1/public"

# Keep event request URLs stable within each three-minute bucket.
ACCURACY_IN_MINUTES = 3
SHORT_TTL_SECONDS = ACCURACY_IN_MINUTES * 60

# Device/account information is cached for two hours.
LONG_TTL_SECONDS = 7200

LOOKBACK_DURATION = "168h"

# This is a display safeguard, not proof that a run has stopped.
INFERRED_ACTIVE_MAX_AGE = "3h"

SCHED_START = "SCHEDULE_STARTED"
SCHED_STOP = "SCHEDULE_COMPLETED"
WEATHER_SKIP = "WEATHER_INTELLIGENCE_SKIP"
WEATHER_CLIMATE_SKIP = "WEATHER_INTELLIGENCE_CLIMATE_SKIP"
WEATHER_FREEZE_SKIP = "WEATHER_INTELLIGENCE_FREEZE_SKIP"
ZONE_STARTED = "ZONE_STARTED"

SCHEDULE_EVENT_NAMES = {
    SCHED_START: "Started",
    SCHED_STOP: "Finished",
    WEATHER_SKIP: "Rain Skip",
    WEATHER_CLIMATE_SKIP: "Soil Saturation Skip",
    WEATHER_FREEZE_SKIP: "Freeze Skip",
}

def main(config):
    tz = time.tz()
    now = time.now().in_location(tz)

    api_key = config.str("api_key", "").strip()
    skip_when_empty = config.bool("skipwhenempty", True)

    screen_width = canvas.width()
    icon_width = 16
    font = "5x8"
    font_height = 8
    font_width = 5

    delay = int(config.str("scroll", "60"))

    if canvas.is2x():
        delay = int(delay / 2)
        font = "terminus-16"
        font_height = 16
        font_width = 8

    if api_key == "":
        return display_error_screen(
            now,
            "Please enter your API key.",
            "Find it in your Rachio account settings.",
            delay,
            screen_width,
            icon_width,
            font_height,
            font,
            font_width,
        )

    devices = get_devices(api_key)

    if devices == None:
        return display_error_screen(
            now,
            "Unable to load Rachio devices.",
            "Check API key or try again later.",
            delay,
            screen_width,
            icon_width,
            font_height,
            font,
            font_width,
        )

    if len(devices) == 0:
        return display_error_screen(
            now,
            "No Rachio devices found.",
            "Check your Rachio account.",
            delay,
            screen_width,
            icon_width,
            font_height,
            font,
            font_width,
        )

    selected_device = config.str("device", "")

    if selected_device == None or selected_device == "":
        selected_device = devices[0]["id"]

    device = get_selected_device(devices, selected_device)

    if device == None:
        return display_error_screen(
            now,
            "Selected device is unavailable.",
            "Choose a device in app settings.",
            delay,
            screen_width,
            icon_width,
            font_height,
            font,
            font_width,
        )

    # Use the next three-minute Unix-time boundary.
    # This avoids constructing dates with minute = 60.
    bucket_seconds = ACCURACY_IN_MINUTES * 60
    rounded_unix = (
        (int(now.unix) // bucket_seconds) + 1
    ) * bucket_seconds

    rounded_time = time.from_timestamp(rounded_unix).in_location(tz)
    past_start = rounded_time - time.parse_duration(LOOKBACK_DURATION)

    all_events = get_events(
        selected_device,
        api_key,
        past_start,
        rounded_time,
    )

    if all_events == None:
        return display_error_screen(
            now,
            "Unable to load Rachio events.",
            "Check API key or try again later.",
            delay,
            screen_width,
            icon_width,
            font_height,
            font,
            font_width,
        )

    events = normalize_events(all_events, now)

    return render_rachio(
        config = config,
        device_name = device["name"],
        events = events,
        now = now,
        tz = tz,
        delay = delay,
        skip_when_empty = skip_when_empty,
        screen_width = screen_width,
        icon_width = icon_width,
        font_height = font_height,
        font_width = font_width,
        font = font,
    )

def get_selected_device(devices, selected_device):
    for device in devices:
        if device["id"] == selected_device:
            return device

    return None

def get_latest_event(events):
    latest = None

    for event in events:
        if latest == None:
            latest = event
        elif event["eventDate"] > latest["eventDate"]:
            latest = event
        elif event["eventDate"] == latest["eventDate"]:
            # If timestamps tie, prefer a schedule completion over
            # a start so we do not infer activity from that tie.
            if event["type"] == SCHED_STOP:
                latest = event

    return latest

def normalize_events(events, now):
    normalized = []
    now_ms = int(now.unix * 1000)

    for event in events:
        sub_type = event.get("subType")
        event_date = event.get("eventDate")

        if sub_type == None or event_date == None:
            continue

        relevant = (
            sub_type in SCHEDULE_EVENT_NAMES or
            sub_type == ZONE_STARTED
        )

        if not relevant:
            continue

        event_date = int(event_date)

        # The query endpoint is in the future for stable caching.
        # Do not display future-dated events as already occurring.
        if event_date > now_ms:
            continue

        summary = event.get("summary") or ""

        normalized.append({
            "type": sub_type,
            "display_type": SCHEDULE_EVENT_NAMES.get(
                sub_type,
                "Zone Started",
            ),
            "summary": summary.strip(),
            "eventDate": event_date,
            "zoneNumber": event.get("zoneNumber"),
        })

    return normalized

def get_activity_state(events, now):
    schedule_events = []
    zone_events = []

    for event in events:
        if event["type"] in SCHEDULE_EVENT_NAMES:
            schedule_events.append(event)
        elif event["type"] == ZONE_STARTED:
            zone_events.append(event)

    latest_schedule = get_latest_event(schedule_events)
    latest_zone = get_latest_event(zone_events)
    latest_event = get_latest_event(events)

    likely_active = False
    associated_zone = None

    if latest_schedule != None:
        if latest_schedule["type"] == SCHED_START:
            schedule_time = time.from_timestamp(
                int(latest_schedule["eventDate"] // 1000),
            )

            schedule_age = now - schedule_time

            if latest_zone != None:
                zone_belongs_to_time_window = (
                    latest_zone["eventDate"] >=
                    latest_schedule["eventDate"]
                )

                if zone_belongs_to_time_window:
                    associated_zone = latest_zone

                    # Historical evidence only:
                    # a schedule start followed by a zone start,
                    # no later selected schedule event, and a
                    # bounded age. This does not confirm water flow.
                    likely_active = (
                        schedule_age <=
                        time.parse_duration(INFERRED_ACTIVE_MAX_AGE)
                    )

    return {
        "latest_event": latest_event,
        "latest_schedule": latest_schedule,
        "latest_zone": latest_zone,
        "associated_zone": associated_zone,
        "likely_active": likely_active,
    }

def format_zone_detail(event, prefix = "Last zone"):
    zone_number = event.get("zoneNumber")
    summary = event.get("summary") or ""

    label = prefix

    if zone_number != None:
        if str(zone_number) != "" and str(zone_number) != "0":
            label = "%s %s" % (prefix, zone_number)

    if summary != "":
        return "%s: %s" % (label, summary)

    return "%s started" % label

def format_event_date(event, now, tz):
    event_time = time.from_timestamp(
        int(event["eventDate"] // 1000),
    ).in_location(tz)

    is_today = (
        event_time.year == now.year and
        event_time.month == now.month and
        event_time.day == now.day
    )

    if is_today:
        return "Today at " + event_time.format("3:04 PM")

    return event_time.format("Mon, Jan 2") + " at " + event_time.format("3:04 PM")

def add_padding_to_child_element(
        element,
        left = 0,
        top = 0,
        right = 0,
        bottom = 0):
    return render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )

def build_display(
        line_1,
        line_2,
        line_3,
        line_4,
        delay,
        screen_width,
        icon_width,
        font_height,
        font,
        font_width):
    header_width = max(1, screen_width - icon_width - 1)

    return render.Root(
        render.Column(
            children = [
                render.Row(
                    main_align = "start",
                    cross_align = "start",
                    children = [
                        render.Image(src = RACHIO_ICON),
                        render.Box(
                            width = 1,
                            height = 1,
                            color = "#000",
                        ),
                        render.Stack(
                            children = [
                                render.Marquee(
                                    width = header_width,
                                    child = render.Text(
                                        line_1,
                                        font = font,
                                        color = RACHIO_BLUE,
                                    ),
                                ),
                                add_padding_to_child_element(
                                    render.Marquee(
                                        offset_start = len(line_1) * font_width,
                                        width = header_width,
                                        child = render.Text(
                                            line_2,
                                            font = font,
                                            color = RACHIO_BLUE,
                                        ),
                                    ),
                                    top = font_height,
                                ),
                            ],
                        ),
                    ],
                ),
                render.Marquee(
                    width = screen_width,
                    child = render.Text(
                        line_3,
                        color = RACHIO_SECONDARY_COLOR,
                        font = font,
                    ),
                ),
                render.Marquee(
                    offset_start = len(line_3) * font_width,
                    width = screen_width,
                    child = render.Text(
                        line_4,
                        color = RACHIO_SECONDARY_COLOR,
                        font = font,
                    ),
                ),
            ],
        ),
        show_full_animation = True,
        delay = delay,
    )

def display_error_screen(
        now,
        line_3,
        line_4 = "",
        delay = 60,
        screen_width = 64,
        icon_width = 16,
        font_height = 8,
        font = "5x8",
        font_width = 5):
    return build_display(
        line_1 = now.format("Jan 02"),
        line_2 = now.format("3:04 PM"),
        line_3 = line_3,
        line_4 = line_4,
        delay = delay,
        screen_width = screen_width,
        icon_width = icon_width,
        font_height = font_height,
        font = font,
        font_width = font_width,
    )

def render_rachio(
        config,
        device_name,
        events,
        now,
        tz,
        delay,
        skip_when_empty = True,
        screen_width = 64,
        icon_width = 16,
        font_height = 8,
        font_width = 5,
        font = "5x8"):
    if len(events) == 0:
        if skip_when_empty:
            return []

        return display_error_screen(
            now = now,
            line_3 = "No events within a week.",
            line_4 = "",
            delay = delay,
            screen_width = screen_width,
            icon_width = icon_width,
            font_height = font_height,
            font = font,
            font_width = font_width,
        )

    state = get_activity_state(events, now)

    latest_event = state["latest_event"]
    latest_schedule = state["latest_schedule"]
    latest_zone = state["latest_zone"]
    likely_active = state["likely_active"]

    show_device_name = config.bool("title_display", True)
    line_1 = device_name if show_device_name else "Rachio"
    line_4 = ""

    if likely_active:
        # Date and status refer to the schedule start.
        displayed_event = latest_schedule
        line_3 = "Likely active: Started"
        line_4 = format_zone_detail(state["associated_zone"])

    elif latest_event["type"] == ZONE_STARTED:
        # A zone start can exist without a matching selected
        # schedule event. Show it as history, not live status.
        displayed_event = latest_event
        line_3 = "Last: Zone Started"
        line_4 = format_zone_detail(latest_event)

    else:
        displayed_event = latest_event
        line_3 = "Last: %s" % latest_event["display_type"]

        if latest_event["type"] == SCHED_START:
            # A start alone is insufficient to claim current activity.
            line_4 = "Live status unconfirmed"

        elif latest_event["summary"] != "":
            line_4 = latest_event["summary"]

        elif latest_event["type"] == SCHED_STOP and latest_zone != None:
            # Show a zone detail only if it falls between the
            # latest known start and this completion.
            run_starts = []

            for event in events:
                if event["type"] == SCHED_START:
                    if event["eventDate"] <= latest_event["eventDate"]:
                        run_starts.append(event)

            run_start = get_latest_event(run_starts)

            if run_start != None:
                if (
                    latest_zone["eventDate"] >= run_start["eventDate"] and
                    latest_zone["eventDate"] <= latest_event["eventDate"]
                ):
                    line_4 = format_zone_detail(latest_zone)

    line_2 = format_event_date(displayed_event, now, tz)

    return build_display(
        line_1 = line_1,
        line_2 = line_2,
        line_3 = line_3,
        line_4 = line_4,
        delay = delay,
        screen_width = screen_width,
        icon_width = icon_width,
        font_height = font_height,
        font = font,
        font_width = font_width,
    )

def get_headers(api_key):
    return {
        "Authorization": "Bearer %s" % api_key,
    }

def get_events(device_id, api_key, start, end):
    start_time = int(start.unix * 1000)
    end_time = int(end.unix * 1000)

    event_url = (
        "%s/device/%s/event?startTime=%d&endTime=%d" %
        (RACHIO_URL, device_id, start_time, end_time)
    )

    response = http.get(
        url = event_url,
        headers = get_headers(api_key),
        ttl_seconds = SHORT_TTL_SECONDS,
    )

    if response.status_code != 200:
        print(
            "Rachio event request failed with status %d" %
            response.status_code,
        )
        return None

    events = response.json()

    if type(events) != "list":
        print("Rachio event response was not a list.")
        return None

    return events

def get_devices(api_key):
    info_url = "%s/person/info" % RACHIO_URL

    response = http.get(
        url = info_url,
        headers = get_headers(api_key),
        ttl_seconds = LONG_TTL_SECONDS,
    )

    if response.status_code != 200:
        print(
            "Rachio person-info request failed with status %d" %
            response.status_code,
        )
        return None

    data = response.json()

    if type(data) != "dict":
        print("Rachio person-info response was not an object.")
        return None

    person_id = data.get("id")

    if not person_id:
        print("Rachio person-info response had no person ID.")
        return None

    person_url = "%s/person/%s" % (RACHIO_URL, person_id)

    person_response = http.get(
        url = person_url,
        headers = get_headers(api_key),
        ttl_seconds = LONG_TTL_SECONDS,
    )

    if person_response.status_code != 200:
        print(
            "Rachio person request failed with status %d" %
            person_response.status_code,
        )
        return None

    person_data = person_response.json()

    if type(person_data) != "dict":
        print("Rachio person response was not an object.")
        return None

    devices = person_data.get("devices") or []

    if type(devices) != "list":
        print("Rachio devices field was not a list.")
        return None

    device_information = []

    for device in devices:
        device_id = device.get("id")

        if device_id:
            device_information.append({
                "id": device_id,
                "name": device.get("name") or "Rachio",
                "status": device.get("status"),
            })

    return device_information

def generate_option_list_of_devices(api_key):
    if api_key == None:
        return []

    api_key = api_key.strip()

    if api_key == "":
        return []

    devices = get_devices(api_key)

    if devices == None or len(devices) == 0:
        return []

    options = [
        schema.Option(
            display = device["name"],
            value = device["id"],
        )
        for device in devices
    ]

    return [
        schema.Dropdown(
            id = "device",
            name = "Device",
            desc = "Choose the device to display",
            icon = "sprayCan",
            options = options,
            default = options[0].value,
        ),
    ]

def get_schema():
    scroll_speed_options = [
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
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "Rachio API Key",
                desc = "Enter the API key from your Rachio account settings.",
                icon = "key",
                secret = True,
            ),
            schema.Toggle(
                id = "title_display",
                name = "Display Device Name",
                desc = "Show the device name on the screen.",
                icon = "display",
                default = True,
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
                id = "skipwhenempty",
                name = "Skip when nothing to display",
                desc = "Skip this app when there are no relevant Rachio events within a week.",
                icon = "flipboard",
                default = True,
            ),
            schema.Generated(
                id = "device",
                source = "api_key",
                handler = generate_option_list_of_devices,
            ),
        ],
    )
