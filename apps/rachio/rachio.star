"""
Applet: Rachio
Summary: Rachio sprinkler system
Description: View schedules and data for a Rachio sprinkler system.
Authors: Matt Fischer and Rob Ison
"""

load("http.star", "http")
load("images/rachio_icon.png", RACHIO_ICON_ASSET = "file")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

RACHIO_ICON = RACHIO_ICON_ASSET.readall()

RACHIO_BLUE = "#0070D2"
RACHIO_SECONDARY_COLOR = "#00A676"
RACHIO_TEXT = "#FFD700"

ACCURACY_IN_MINUTES = 3  #We'll round to the nearest 3 minutes when calling Rachio API
LONG_TTL_SECONDS = 7200
RACHIO_URL = "https://api.rach.io/1/public"
SAMPLE_DATA = [{"type": "WEATHER_INTELLIGENCE_CLIMATE_SKIP", "date": "Thursday 04:31AM", "summary": "Water all zones was scheduled for 10/03 at 04:26 AM (EDT), but will be skipped based on weather and soil conditions."}, {"type": "WEATHER_INTELLIGENCE_SKIP", "date": "Sunday 04:31AM", "summary": "Water all zones was scheduled for 10/06 at 04:28 AM (EDT), but was skipped due to PLUS weather network which observed 0.00 in and predicted 0.16 in precipitation compared to schedules's threshold of 0.13 in."}, {"type": "SCHEDULE_STARTED", "date": "Tuesday 01:45PM", "summary": "Button press started Quick Run will run for 3 minutes."}, {"type": "SCHEDULE_STARTED", "date": "Tuesday 01:48PM", "summary": "Button press started Quick Run will run for 3 minutes."}, {"type": "SCHEDULE_STARTED", "date": "Tuesday 01:50PM", "summary": "Button press started Quick Run will run for 3 minutes."}, {"type": "SCHEDULE_STARTED", "date": "Tuesday 01:51PM", "summary": "Button press started Quick Run will run for 3 minutes."}, {"type": "SCHEDULE_STARTED", "date": "Tuesday 01:55PM", "summary": "Button press started Quick Run will run for 3 minutes."}, {"type": "WEATHER_INTELLIGENCE_SKIP", "date": "Thursday 04:31AM", "summary": "Water all zones was scheduled for 10/10 at 04:30 AM (EDT), but was skipped due to PLUS weather network which observed 5.10 in and predicted 3.96 in precipitation compared to schedules's threshold of 0.13 in."}, {"type": "WEATHER_INTELLIGENCE_CLIMATE_SKIP", "date": "Sunday 04:36AM", "summary": "Water all zones was scheduled for 10/13 at 04:32 AM (EDT), but will be skipped based on weather and soil conditions."}, {"type": "WEATHER_INTELLIGENCE_CLIMATE_SKIP", "date": "Thursday 04:36AM", "summary": "Water all zones was scheduled for 10/17 at 04:34 AM (EDT), but will be skipped based on weather and soil conditions."}, {"type": "SCHEDULE_STARTED", "date": "Saturday 06:11PM", "summary": "Quick Run will run for 1 minutes."}]
SHORT_TTL_SECONDS = 600

SCHED_START = "SCHEDULE_STARTED"
SCHED_STOP = "SCHEDULE_COMPLETED"
WEATHER_CLIMATE_SKIP = "WEATHER_INTELLIGENCE_CLIMATE_SKIP"
WEATHER_SKIP = "WEATHER_INTELLIGENCE_SKIP"
ZONE_STARTED = "ZONE_STARTED"

def main(config):
    tz = time.tz()
    now = time.now().in_location(tz)
    api_key = config.str("api_key", "4edda71b-e284-4bb4-8c0e-d687fcb4eca9")
    skip_when_empty = config.bool("skipwhenempty", False)
    screen_width = canvas.width()
    icon_width = 16

    delay = int(config.get("scroll", 45))
    font = "5x8"
    font_height = 8
    font_width = 5

    #Mods for 2x Display
    if (canvas.is2x()):
        delay = int(delay / 2)
        font = "terminus-16"
        font_height = 16
        font_width = 8

    if (api_key.strip() == ""):
        return display_error_screen(now, "Please enter your API Key", "It can be found in the Rachio App", delay, screen_width, font_height, font)

    devices = get_devices(api_key)
    selected_device = config.str("device")

    if (devices == None or selected_device == None or selected_device == ""):
        if devices == None:
            # No device selected, and no device available from the list, send an error
            return display_error_screen(now, "No devices found.", "Make sure you have entered the correct API key and selected your display device", delay, screen_width, font)
        else:
            selected_device = devices[0]["id"]

    # we have a selected device; otherwise, they've already been sent to the display_error_screen

    now = time.now().in_location(tz)

    # If we use the time to the millisecond, nothing will ever be cached and we'll hit our limit of rachio requests in a day
    # So we'll round off to the nearest X minutes (They provide enough calls to give you 1 per minutes.)
    # But in addition, let's go a few minutes into the future, no point in every making a call that could miss the most recent event.
    now = time.now() + time.parse_duration("{}m".format(str(ACCURACY_IN_MINUTES)))
    rounded_time = time.time(year = now.year, month = now.month, day = now.day, hour = now.hour, minute = round_to_nearest_X(now.minute, ACCURACY_IN_MINUTES), second = 0, location = tz)

    # The data they send is a little odd in that the there isn't a time stamp, but a time display.
    # So to get the 'last' and 'next' event, you could get all the data at once, and parse through their time display
    # OR, pull in past events and separate events to let them determine the cutoff on thier side
    # now I can grab the latest past event and the first next event.
    past_start = rounded_time + time.parse_duration("-160h")

    #initialize
    recent_events = None
    current_events = None

    all_events = get_events(selected_device, api_key, past_start, rounded_time)
    recent_events = get_selected_events(tz, all_events, False)
    current_events = get_selected_events(tz, all_events, True)

    return render_rachio(tz, config, get_device_name(devices, selected_device), recent_events, current_events, now, delay, skip_when_empty, screen_width, icon_width, font_height, font_width, font)

def get_device_name(devices, selected_device):
    for device in devices:
        if device["id"] == selected_device:
            return device["name"]

    return ""

def round_to_nearest_X(number_to_round, nearest_number):
    return int(nearest_number * math.round(number_to_round / nearest_number))

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )

    return padded_element

def display_error_screen(time, line_3, line_4 = "", delay = 45, screen_width = 64, font_height = 8, font = "5x8"):
    return render.Root(
        render.Column(
            children = [
                render.Row(
                    main_align = "start",
                    cross_align = "start",
                    children = [
                        render.Image(src = RACHIO_ICON),
                        render.Box(width = 1, height = 1, color = "#000"),
                        render.Stack(
                            children = [
                                render.Text(time.format("Jan 02"), font = font, color = RACHIO_BLUE),
                                add_padding_to_child_element(render.Text(time.format("3:04 PM"), font = font, color = RACHIO_BLUE), 0, font_height),
                            ],
                        ),
                    ],
                ),
                render.Marquee(
                    width = screen_width,
                    child = render.Text(line_3, color = RACHIO_SECONDARY_COLOR, font = font),
                ),
                render.Marquee(
                    offset_start = len(line_3) * 5,
                    width = screen_width,
                    child = render.Text(line_4, color = RACHIO_SECONDARY_COLOR, font = font),
                ),
            ],
        ),
        show_full_animation = True,
        delay = delay,
    )

def render_rachio(tz, config, device_name, recent_events, current_events, now, delay, skip_when_empty = True, screen_width = 64, icon_width = 16, font_height = 8, font_width = 5, font = "5x8"):
    show_device_name = config.bool("title_display", True)

    line_1 = "Rachio"
    line_2 = now.format("Mon Jan 2")
    line_3 = ""
    line_4 = ""

    if (show_device_name):
        line_1 = device_name

    show_recent_events = recent_events != None and len(recent_events) > 0

    if (not show_recent_events):
        if skip_when_empty:
            return []
        else:
            return display_error_screen(now, "No Events within a week.", "", delay, screen_width, font_height)

    # whew, made it with at least one event to display

    #do we have any current events?
    show_current_events = current_events != None and len(current_events) > 0

    if show_recent_events:
        latest_event = recent_events[len(recent_events) - 1]

        #this current event is only relevant if the latest_event
        if (latest_event["type"] and latest_event["type"] == SCHED_STOP):
            show_current_events = False

        preface = "Last"
        if show_current_events:
            preface = "Current"

        readable_date = time.from_timestamp(int(int(latest_event["eventDate"]) / 1000.0)).in_location(tz)
        line_2 = readable_date.format("Mon Jan 2 at 3:04 PM")
        line_3 = "%s: %s - %s" % (preface, latest_event["summary"], readable_date.format("Mon Jan 2 at 3:04 PM"))

    if show_current_events:
        current_event = current_events[len(current_events) - 1]
        display = current_event["summary"].strip()
        if len(display) > 0:
            display = "Zone: %s" % display

        if line_3 == "":
            line_3 = display
        else:
            line_4 = display

    return render.Root(
        render.Column(
            children = [
                render.Row(
                    main_align = "start",
                    cross_align = "start",
                    children = [
                        render.Image(src = RACHIO_ICON),
                        render.Box(width = 1, height = 1, color = "#000"),
                        render.Stack(
                            children = [
                                render.Marquee(width = screen_width - icon_width, child = render.Text(line_1, font = font, color = RACHIO_BLUE)),
                                add_padding_to_child_element(render.Marquee(offset_start = len(line_1) * font_width, width = screen_width, child = render.Text(line_2, color = RACHIO_BLUE, font = font)), 0, font_height),
                            ],
                        ),
                    ],
                ),
                render.Marquee(
                    width = screen_width,
                    child = render.Text(line_3, color = RACHIO_SECONDARY_COLOR, font = font),
                ),
                render.Marquee(
                    offset_start = len(line_3) * font_width,
                    width = screen_width,
                    child = render.Text(line_4, color = RACHIO_SECONDARY_COLOR, font = font),
                ),
            ],
        ),
        show_full_animation = True,
        delay = delay,
    )

def get_events(deviceId, api_key, start, end):
    # Rachio uses MS from epoch, not seconds
    start_time = start.unix * 1000
    end_time = end.unix * 1000

    event_url = "%s/device/%s/event?startTime=%d&endTime=%d" % (RACHIO_URL, deviceId, start_time, end_time)

    event_response = http.get(url = event_url, headers = get_headers(api_key), ttl_seconds = SHORT_TTL_SECONDS)

    if event_response.status_code != 200:
        print("GET %s failed with status %d: %s" % (event_url, event_response.status_code, event_response.body()))
        return None

    return event_response.json()

def get_selected_events(tz, events, current):
    selected_sub_types = []
    if current:
        selected_sub_types = [ZONE_STARTED]
    else:
        selected_sub_types = [SCHED_START, SCHED_STOP, WEATHER_SKIP, WEATHER_CLIMATE_SKIP]

    selected_events = []
    for event in events:
        if "subType" in event.keys():
            if event["subType"] in selected_sub_types:
                eventDateSecs = time.from_timestamp(int(event["eventDate"] / 1000)).in_location(tz)
                parsedDate = eventDateSecs.format("Monday 03:04PM")
                newEvent = dict(type = event["subType"], date = parsedDate, summary = event["summary"], eventDate = event["eventDate"])
                selected_events.append(newEvent)

    return selected_events

def get_headers(api_key):
    headers = {}
    headers["Authorization"] = "Bearer %s" % api_key
    return headers

def get_devices(api_key):
    #Device Dictionary of IDs and names
    device_information = []

    info_url = "%s/person/info" % RACHIO_URL

    # cache for 1 hour, this should never change
    response = http.get(url = info_url, headers = get_headers(api_key), ttl_seconds = LONG_TTL_SECONDS)

    if response.status_code != 200:
        print("Failed to retrieve person id: %d %s" % (response.status_code, response.body()))
        return None
    else:
        data = response.json()
        person_id = data.get("id")
        if not person_id:
            return None
        else:
            person_url = "%s/person/%s" % (RACHIO_URL, person_id)

            # cache for 1 hour, this should never change
            person_response = http.get(url = person_url, headers = get_headers(api_key), ttl_seconds = LONG_TTL_SECONDS)

            if person_response.status_code != 200:
                print("Failed to retrieve person data: %d %s" % (person_response.status_code, person_response.body()))
                return None
            else:
                # Parse and print the response for the second call
                person_data = person_response.json()

                # Extract the 'devices' array
                devices = person_data.get("devices", [])

            if not devices:
                print("No devices found: %s" % person_data)
                return None
            else:
                # List to store device ids
                device_ids = []

                # Loop through each device and extract the 'id' field
                for device in devices:
                    deviceId = device.get("id")
                    if deviceId:
                        new_device = {"id": deviceId, "name": device.get("name"), "status": device.get("status")}
                        device_ids.append(deviceId)
                        device_information.append(new_device)

    return device_information

def generate_option_list_of_devices(api_key):
    devices = get_devices(api_key)

    if (devices == None or len(devices) == 0):
        return []

    options = [
        schema.Option(display = device["name"], value = device["id"])
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
                desc = "From the phone app or rachio.com you can acquire your API key. From the web app select Account Settings and GET API KEY",
                icon = "key",
                secret = True,
            ),
            schema.Toggle(
                id = "title_display",
                name = "Display Device Name",
                desc = "Do you want the device name to appear on the screen?",
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
                desc = "Skip this app from the Tidbyt display if there are no Rachio events to display.",
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
