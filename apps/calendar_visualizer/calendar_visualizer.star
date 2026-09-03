"""
Applet: Calendar Visualizer
Summary: Spatial Calendar Visualizer
Description: Displays a very dense visualization of events from a Google Calendar iCal URL.
Author: Ctrl-G, Gemini
Concept: Ctrl-G
Version: 26.09.02.0001
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# --- Color Constants ---
COLOR_BG = "#000000"
COLOR_BOUNDS = "#404040"
COLOR_RED_INDICATOR = "#ED1C24"
COLOR_WHITE_MONTH = "#FFFFFF"
COLOR_GREEN_WEEKEND = "#00FF00"
COLOR_GREY_5DAY = "#C3C3C3"
COLOR_ALL_DAY_EVT = "#0F3060"
COLOR_DEFAULT_EVT = "#7092BE"
COLOR_ORANGE_TIME = "#FF9900"
COLOR_TTL_INDICATOR = "#800080"

CURRENT_DAY_OFFSET = 5

DAY_IN_SECONDS = 86400
HOUR_IN_SECONDS = 3600

DEFAULT_LOCATION = """
 {
     "lat": 40.689267,
     "lng": -74.044520,
     "locality": "New_York, NY",
     "timezone": "America/New_York"
 }
 """

# --- Helper Functions ---

def clean_line(line):
    return line.replace("\r", "").strip()

# +---------
# | get_day_of_week(t): - Gemini Version
# |     Calculate and return the day of the week.
# +---------

# def get_day_of_week(t):
#     days_since_epoch = t.unix // DAY_IN_SECONDS
#     return (days_since_epoch + 4) % 7

# +---------
# | get_day_of_week(t):
# |     Calculate and return the day of the week.
# +---------

def get_day_of_week(t):
    tz_offset_is_negative = False

    tz_offset = int(str(t).split(" ")[2])  # Get timezone offset from tz string.

    if tz_offset < 0:
        tz_offset_is_negative = True
        tz_offset = abs(tz_offset)

    tz_offset_hrs = tz_offset // 100
    tz_offset_mins = tz_offset % 100

    offset_duration = days_to_duration(0, tz_offset_hrs, tz_offset_mins)

    if tz_offset_is_negative:
        time_plus_tz_offset = t - offset_duration
    else:
        time_plus_tz_offset = t + offset_duration

    # t.unix returns total seconds since 1970-01-01 00:00:00 UTC
    # 86400 seconds in a day
    # days_since_epoch = t.unix // 86400

    days_since_epoch = time_plus_tz_offset.unix // 86400

    # 1970-01-01 was Thursday (Index 4 if Sunday = 0)
    # (days_since_epoch + 4) % 7 gives 0=Sun, 1=Mon, ..., 6=Sat

    return (days_since_epoch + 4) % 7

def days_to_duration(days, hours = 0, mins = 0, secs = 0):
    total_hours = (days * 24) + hours
    duration_str = "%dh%dm%ds" % (total_hours, mins, secs)
    return time.parse_duration(duration_str)

def hour_to_y(hour):
    if hour < 8:
        return 0
    elif hour >= 17:
        return 10
    else:
        return hour - 8 + 1

def sort_events_by_key(events, key):
    arr = list(events)
    n = len(arr)
    for i in range(n):
        for j in range(0, n - i - 1):
            if arr[j][key] > arr[j + 1][key]:
                temp = arr[j]
                arr[j] = arr[j + 1]
                arr[j + 1] = temp
    return arr

# --- iCal Timestamp Parsing ---

def parse_ical_date(val_str, params, default_tz):
    val_str = clean_line(val_str)
    tz_id = params.get("TZID", default_tz)

    if val_str.endswith("Z"):
        clean_val = val_str[:-1]
        if "T" in clean_val:
            return time.parse_time(clean_val, "20060102T150405", "UTC").in_location(default_tz), "HMS"
        else:
            return time.parse_time(clean_val, "20060102", "UTC").in_location(default_tz), "DAY"

    if "T" in val_str:
        return time.parse_time(val_str, "20060102T150405", tz_id).in_location(default_tz), "HMS"

    t = time.parse_time(val_str, "20060102", tz_id).in_location(default_tz)
    return time.time(year = t.year, month = t.month, day = t.day, hour = 0, minute = 0, second = 0, location = default_tz), "DAY"

def parse_line_params(line):
    parts = line.split(":", 1)
    if len(parts) < 2:
        return "", {}, ""

    prop_and_params = parts[0].split(";")
    prop_name = prop_and_params[0].upper()
    params = {}

    for p in prop_and_params[1:]:
        if "=" in p:
            k, v = p.split("=", 1)
            params[k.upper()] = v

    return prop_name, params, parts[1]

# --- RRULE Expansion Engine ---

def parse_rrule(rrule_str):
    rule = {"FREQ": None, "INTERVAL": 1, "UNTIL": None, "COUNT": None, "BYDAY": []}
    for item in rrule_str.split(";"):
        if "=" in item:
            k, v = item.split("=", 1)
            k = k.upper()
            if k == "FREQ":
                rule["FREQ"] = v.upper()
            elif k == "INTERVAL":
                rule["INTERVAL"] = int(v)
            elif k == "COUNT":
                rule["COUNT"] = int(v)
            elif k == "UNTIL":
                rule["UNTIL"] = v
            elif k == "BYDAY":
                rule["BYDAY"] = v.split(",")
    return rule

def expand_recurring_event(evt, rrule_str, exdates, win_start, win_end, default_tz):
    rule = parse_rrule(rrule_str)
    if not rule["FREQ"]:
        return [evt]

    occurrences = []
    duration_sec = evt["duration_sec"]
    dtstart = evt["raw_start"]

    until_t = None
    if rule["UNTIL"]:
        until_t, _ = parse_ical_date(rule["UNTIL"], {}, default_tz)

    curr = dtstart
    count = 0
    max_loop = 365 * 5

    for _ in range(max_loop):
        if rule["COUNT"] and count >= rule["COUNT"]:
            break
        if until_t and curr.unix > until_t.unix:
            break
        if curr.unix > win_end.unix:
            break

        # Calculate exact occurrence start and adjusted exclusive end (-1 sec)
        curr_start_unix = curr.unix
        curr_end_unix = curr.unix + duration_sec
        adjusted_end_unix = curr_end_unix - 1 if curr_end_unix > curr_start_unix else curr_start_unix

        if adjusted_end_unix >= win_start.unix and curr_start_unix <= win_end.unix:
            is_excluded = False
            for ex in exdates:
                if ex.unix == curr_start_unix:
                    is_excluded = True
                    break

            if not is_excluded:
                occurrences.append({
                    "UNIX_Epoch_Start": curr_start_unix,
                    "UNIX_Epoch_End": adjusted_end_unix,
                    "UNIX_Epoch_Elapsed": duration_sec,
                    "type": evt["type"],
                })

        count += 1
        freq = rule["FREQ"]
        interval = rule["INTERVAL"]

        if freq == "DAILY":
            curr = curr + days_to_duration(interval)
        elif freq == "WEEKLY":
            curr = curr + days_to_duration(7 * interval)
        elif freq == "MONTHLY":
            new_m = curr.month + interval
            new_y = curr.year + (new_m - 1) // 12
            new_m = ((new_m - 1) % 12) + 1
            curr = time.time(year = new_y, month = new_m, day = curr.day, hour = curr.hour, minute = curr.minute, second = curr.second, location = default_tz)
        elif freq == "YEARLY":
            curr = time.time(year = curr.year + interval, month = curr.month, day = curr.day, hour = curr.hour, minute = curr.minute, second = curr.second, location = default_tz)
        else:
            break

    return occurrences

# --- Rendering Canvas ---

def draw_clock_sans_colon(now, clock_format_24hr):
    clock_str = now.format("15 04") if clock_format_24hr else now.format("3 04 PM")
    return (render.Padding(pad = (19, 0, 0, 0), child = render.Text(clock_str, color = COLOR_ORANGE_TIME)))

def draw_time_dot(now):
    current_day_offset = CURRENT_DAY_OFFSET
    current_y = hour_to_y(now.hour)
    return (render.Padding(pad = (current_day_offset, 20 + current_y, 0, 0), child = render.Box(width = 1, height = 1, color = COLOR_ORANGE_TIME)))

def draw_calendar_graph(now, clock_format_24hr, led_first_pixel_second, day_events, hms_events, ttl_pixel_ind):
    elements = []
    current_day_offset = CURRENT_DAY_OFFSET

    # 1. Date and Time Header Display
    month_pad = 3 if now.month < 10 else 1
    elements.append(render.Padding(pad = (month_pad, 0, 0, 0), child = render.Text(str(now.month), color = COLOR_RED_INDICATOR)))

    day_pad = 3 if now.day < 10 else 1
    elements.append(render.Padding(pad = (day_pad, 7, 0, 0), child = render.Text(str(now.day), color = COLOR_RED_INDICATOR)))

    clock_str = now.format("15:04") if clock_format_24hr else now.format("3:04 PM")
    elements.append(render.Padding(pad = (19, 0, 0, 0), child = render.Text(clock_str, color = COLOR_ORANGE_TIME)))

    # 2. Bounding Box & Background Area (62x13)
    elements.append(render.Padding(pad = (0, 19, 0, 0), child = render.Box(width = 64, height = 13, color = COLOR_BOUNDS)))
    elements.append(render.Padding(pad = (1, 20, 0, 0), child = render.Box(width = 62, height = 11, color = COLOR_BG)))

    # 3. X-Axis Day Grid Indicators
    for x in range(0, 62):
        runner_time = now + days_to_duration(x - 4)
        runner_dow = get_day_of_week(runner_time)

        if x != (current_day_offset - 1):
            if runner_time.day == 1:
                elements.append(render.Padding(pad = (x + 1, 15, 0, 0), child = render.Box(width = 1, height = 3, color = COLOR_WHITE_MONTH)))
            elif runner_time.day % 5 == 0:
                elements.append(render.Padding(pad = (x + 1, 19, 0, 0), child = render.Box(width = 1, height = 1, color = COLOR_GREY_5DAY)))

        if runner_dow == 0 or runner_dow == 6:
            elements.append(render.Padding(pad = (x + 1, 18, 0, 0), child = render.Box(width = 1, height = 1, color = COLOR_GREEN_WEEKEND)))

    # 4. Render Day Events
    for evt in reversed(day_events):
        evt_start_epoch = evt["UNIX_Epoch_Start"]
        evt_end_epoch = evt["UNIX_Epoch_End"]  # Already adjusted (-1 sec)

        # Calculate pixel width based on inclusive day span
        start_day_idx = (evt_start_epoch - led_first_pixel_second.unix) // DAY_IN_SECONDS
        end_day_idx = (evt_end_epoch - led_first_pixel_second.unix) // DAY_IN_SECONDS

        if start_day_idx < 62 and end_day_idx >= 0:
            if start_day_idx < 0:
                start_day_idx = 0
            if end_day_idx > 61:
                end_day_idx = 61
            width_in_pixels = end_day_idx - start_day_idx + 1  # width in "displayable" pixels
            elements.append(
                render.Padding(
                    pad = (start_day_idx + 1, 20, 0, 0),
                    child = render.Box(width = width_in_pixels, height = 11, color = COLOR_ALL_DAY_EVT),
                ),
            )

    # 5. Render HMS Events
    for evt in reversed(hms_events):
        evt_start_epoch = evt["UNIX_Epoch_Start"]
        evt_end_epoch = evt["UNIX_Epoch_End"]  # Already adjusted (-1 sec)

        graph_start_sec = evt_start_epoch - led_first_pixel_second.unix
        graph_end_sec = evt_end_epoch - led_first_pixel_second.unix

        graph_start_hr = graph_start_sec // HOUR_IN_SECONDS
        graph_end_hr = graph_end_sec // HOUR_IN_SECONDS

        x_start = graph_start_hr // 24
        x_end = graph_end_hr // 24

        event_days = x_end - x_start + 1  # Event happens during this many calendar days.

        width_in_pixels = event_days  # width in "displayable" pixels

        if x_start < 0:  # If the event begins before the start of the graph.
            start_hr = 0
            width_in_pixels = width_in_pixels + x_start
            x_start_disp = 0
        else:
            start_hr = graph_start_hr % 24
            x_start_disp = x_start

        y_start = hour_to_y(start_hr)

        if x_end > 61:  # If the event extends past the end of the graph.
            end_hr = 23
            width_in_pixels = width_in_pixels - (x_end - 61)
        else:
            end_hr = graph_end_hr % 24

        y_end = hour_to_y(end_hr)

        event_days = width_in_pixels

        if event_days == 1:
            elements.append(render.Padding(pad = (x_start_disp + 1, 20 + y_start, 0, 0), child = render.Box(width = 1, height = y_end - y_start + 1, color = COLOR_DEFAULT_EVT)))
        elif event_days == 2:
            elements.append(render.Padding(pad = (x_start_disp + 1, 20 + y_start, 0, 0), child = render.Box(width = 1, height = 11 - y_start, color = COLOR_DEFAULT_EVT)))
            elements.append(render.Padding(pad = (x_start_disp + 2, 20, 0, 0), child = render.Box(width = 1, height = y_end + 1, color = COLOR_DEFAULT_EVT)))
        else:
            elements.append(render.Padding(pad = (x_start_disp + 1, 20 + y_start, 0, 0), child = render.Box(width = 1, height = 11 - y_start, color = COLOR_DEFAULT_EVT)))
            elements.append(render.Padding(pad = (x_start_disp + 2, 20, 0, 0), child = render.Box(width = event_days - 2, height = 11, color = COLOR_DEFAULT_EVT)))
            elements.append(render.Padding(pad = (x_start_disp + event_days, 20, 0, 0), child = render.Box(width = 1, height = y_end + 1, color = COLOR_DEFAULT_EVT)))

    # 6. Fixed Axis Ticks and Time Crosshairs
    red_x = current_day_offset
    current_y = hour_to_y(now.hour)

    elements.append(render.Padding(pad = (red_x, 15, 0, 0), child = render.Box(width = 1, height = 3, color = COLOR_RED_INDICATOR)))
    elements.append(render.Padding(pad = (red_x, 19, 0, 0), child = render.Box(width = 1, height = 1, color = COLOR_ORANGE_TIME)))
    elements.append(render.Padding(pad = (red_x, 31, 0, 0), child = render.Box(width = 1, height = 1, color = COLOR_ORANGE_TIME)))
    elements.append(render.Padding(pad = (0, 20 + current_y, 0, 0), child = render.Box(width = 1, height = 1, color = COLOR_ORANGE_TIME)))
    if ttl_pixel_ind >= 0 and ttl_pixel_ind <= 10:
        elements.append(render.Padding(pad = (63, 20 + 10 - ttl_pixel_ind, 0, 0), child = render.Box(width = 1, height = 1, color = COLOR_TTL_INDICATOR)))
    else:
        elements.append(render.Padding(pad = (63, 19, 0, 0), child = render.Box(width = 1, height = 1, color = COLOR_TTL_INDICATOR)))
        elements.append(render.Padding(pad = (63, 31, 0, 0), child = render.Box(width = 1, height = 1, color = COLOR_TTL_INDICATOR)))

    # elements.append(render.Padding(pad = (red_x, 20 + current_y, 0, 0), child = render.Box(width = 1, height = 1, color = COLOR_ORANGE_TIME)))

    return render.Stack(children = elements)

# --- Main App Logic ---

def main(config):
    frames = []

    url = config.str("calendar_url", "")
    if not url:
        return render.Root(
            render.Padding(
                pad = (1, 1, 1, 1),
                child = render.WrappedText("Enter a Google Calendar iCal URL in settings.", font = "tom-thumb"),
            ),
        )

    ttl = int(config.str("ttl", "3600"))
    rep = http.get(url, ttl_seconds = ttl)
    if rep.status_code != 200:
        print("iCal fetch failed with status %d" % rep.status_code)
        return []

    location_data = json.decode(config.get("location", DEFAULT_LOCATION))
    timezone = location_data.get("timezone", time.tz())

    # Get real D&T:
    now = time.now().in_location(timezone)

    # # If need Debug D&T:  / Pretend date. \   / Date format. \  /   Timezone   \
    # now = time.parse_time("20260901T120000", "20060102T150405", "America/Chicago")

    # print("now . . . . . . . . . = ", str(now))

    # Calculate TTL Indicator info

    # Go reference string for HTTP RFC 1123 / GMT dates
    HTTP_DATE_FORMAT = "Mon, 02 Jan 2006 15:04:05 MST"

    # Get cached response timestamp string from headers
    cached_date_str = rep.headers.get("Date")

    if cached_date_str:
        # Parse into a UTC time object
        cached_time = time.parse_time(cached_date_str, HTTP_DATE_FORMAT)

        # Calculate how many seconds old the cache is
        cache_age_seconds = time.now().unix - cached_time.unix

        # Calculate how many seconds remain before Pixlet fetches fresh data
        ttl_remaining_seconds = ttl - cache_age_seconds

        # Possibly do floating division and then round the result.  That seems better for the long run.
        # Something to look into.
        # ttl_pixel_ind = int(ttl_remaining_seconds // (ttl / (10 + 1)))  # 1-11 with 11 at top.
        ttl_pixel_ind = int(math.round(ttl_remaining_seconds / (ttl / (10))))

    else:
        ttl_pixel_ind = 0

    if ttl_pixel_ind < 0 or ttl_pixel_ind > 10:
        ttl_pixel_ind = -1

    # Calculate 62-Day Visualization Window Boundaries
    today_at_0000 = time.time(year = now.year, month = now.month, day = now.day, hour = 0, minute = 0, second = 0, location = timezone)
    led_display_range_start = today_at_0000 - days_to_duration(4)
    led_display_range_end = today_at_0000 + days_to_duration(57, 23, 59, 59)

    raw_lines = rep.body().split("\n")

    # Handle iCalendar Line Folding (RFC 5545)
    lines = []
    for line in raw_lines:
        line = line.replace("\r", "")
        if (line.startswith(" ") or line.startswith("\t")) and len(lines) > 0:
            lines[-1] += line[1:].rstrip()
        elif line.strip():
            lines.append(line.strip())

    parsed_events = []
    in_vevent = False
    cur_event = None

    for line in lines:
        if line == "BEGIN:VEVENT":
            in_vevent = True
            cur_event = {"raw_start": None, "raw_end": None, "rrule": None, "exdates": [], "type": "HMS"}
            continue
        elif line == "END:VEVENT":
            if in_vevent and cur_event["raw_start"] and cur_event["raw_end"]:
                dur = cur_event["raw_end"].unix - cur_event["raw_start"].unix
                cur_event["duration_sec"] = dur if dur > 0 else 0
                parsed_events.append(cur_event)
            in_vevent = False
            cur_event = None
            continue

        if in_vevent:
            prop, params, val = parse_line_params(line)
            if prop == "DTSTART":
                t, evt_type = parse_ical_date(val, params, timezone)
                cur_event["raw_start"] = t
                cur_event["type"] = evt_type
            elif prop == "DTEND":
                t, _ = parse_ical_date(val, params, timezone)
                cur_event["raw_end"] = t
            elif prop == "RRULE":
                cur_event["rrule"] = val
            elif prop == "EXDATE":
                for ex_val in val.split(","):
                    if ex_val.strip():
                        ex_t, _ = parse_ical_date(ex_val, params, timezone)
                        cur_event["exdates"].append(ex_t)

    # Process and Expand Recurrences into Render Arrays
    day_events = []
    hms_events = []

    for evt in parsed_events:
        if evt["rrule"]:
            occurrences = expand_recurring_event(evt, evt["rrule"], evt["exdates"], led_display_range_start, led_display_range_end, timezone)
            for occ in occurrences:
                if occ["type"] == "DAY":
                    day_events.append(occ)
                else:
                    hms_events.append(occ)
        else:
            s_unix = evt["raw_start"].unix
            raw_e_unix = evt["raw_end"].unix

            # Apply -1 second offset to raw end timestamp for single events
            e_unix = raw_e_unix - 1 if raw_e_unix > s_unix else s_unix

            if e_unix >= led_display_range_start.unix and s_unix <= led_display_range_end.unix:
                occ = {
                    "UNIX_Epoch_Start": s_unix,
                    "UNIX_Epoch_End": e_unix,
                    "UNIX_Epoch_Elapsed": evt["duration_sec"],
                    "type": evt["type"],
                }
                if evt["type"] == "DAY":
                    day_events.append(occ)
                else:
                    hms_events.append(occ)

    day_events = sort_events_by_key(day_events, "UNIX_Epoch_Elapsed")
    hms_events = sort_events_by_key(hms_events, "UNIX_Epoch_Elapsed")

    hour_format_24 = config.bool("24hour_format", False)

    # flash_colon = config.bool("flash_colon", True)
    flash_time_dot = config.bool("flash_time_dot", True)

    frame_background = draw_calendar_graph(now, hour_format_24, led_display_range_start, day_events, hms_events, ttl_pixel_ind)

    frame_all = render.Stack(
        # Frame with all data (icluding time dot)
        children = [
            frame_background,  # Reused reference
            # draw_clock_sans_colon(now, hour_format_24),
            draw_time_dot(now),  # Draw the dot.
        ],
    )

    if flash_time_dot:  # Was: flash_colon or flash_time_dot:
        frames.append(frame_all)  # Frame with dot!
        frames.append(frame_background)  # Basically everything drawn (No dot).

        ret_val = render.Root(
            delay = 500,
            child = render.Animation(
                children = frames,
            ),
        )
    else:
        ret_val = render.Root(frame_all)

    return ret_val

def get_schema():
    ttl_options = [
        schema.Option(display = "5 minutes", value = "300"),
        schema.Option(display = "15 minutes", value = "900"),
        schema.Option(display = "1 hour", value = "3600"),
        schema.Option(display = "1 day", value = "86400"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(id = "calendar_url", name = "Calendar URL", desc = "Google Calendar iCal URL", icon = "calendar"),
            schema.Dropdown(id = "ttl", name = "Refresh Rate", desc = "iCal cache interval", icon = "clock", default = "3600", options = ttl_options),
            schema.Location(id = "location", name = "Location", desc = "Location timezone", icon = "locationDot"),
            schema.Toggle(id = "24hour_format", name = "24-Hour Clock", desc = "Display 24-hour time", icon = "clock", default = False),
            # schema.Toggle(id = "flash_colon", name = "Flashing Colon", desc = "Flash the clock's colon", icon = "clock", default = True),
            schema.Toggle(id = "flash_time_dot", name = "Flash Time Dot", desc = "Flash the graph's current time dot", icon = "clock", default = True),
        ],
    )
