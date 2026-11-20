"""
Applet: SpotTheStation
Summary: Next ISS visit overhead
Description: Displays the next visible International Space Station pass.
Author: Robert Ison
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/iss_icon.png", ISS_ICON_ASSET = "file")
load("images/iss_icon2.png", ISS_ICON2_ASSET = "file")
load("images/iss_icon3.png", ISS_ICON3_ASSET = "file")
load("images/iss_icon4.png", ISS_ICON4_ASSET = "file")
load("images/iss_icon5.png", ISS_ICON5_ASSET = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

ISS_ICON = ISS_ICON_ASSET.readall()
ISS_ICON2 = ISS_ICON2_ASSET.readall()
ISS_ICON3 = ISS_ICON3_ASSET.readall()
ISS_ICON4 = ISS_ICON4_ASSET.readall()
ISS_ICON5 = ISS_ICON5_ASSET.readall()

# Set this to the actual width of the PNG assets.
ISS_IMAGE_WIDTH = 16

CACHE_DURATION = 86400
PREDICTION_DAYS = 10

# Request broadly; all user-selected filters are applied locally.
API_MIN_VISIBILITY = 1
SPACE_STATION_ID = 25544

STATION_LOCATION_API = (
    "https://api.n2yo.com/rest/v1/satellite/visualpasses/" +
    "{space_station_id}/{latitude}/{longitude}/0/" +
    "{days}/{min_visibility}/&apiKey={api_key}"
)

DEFAULT_LOCATION = """
{
    "lat": "40.6781784",
    "lng": "-73.9441579",
    "description": "Brooklyn, NY, USA",
    "locality": "Brooklyn",
    "place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
    "timezone": "America/New_York"
}
"""

SAMPLE_DATA = """
{
    "info": {
        "satid": 25544,
        "satname": "SPACE STATION",
        "passescount": 1
    },
    "passes": [
        {
            "startAz": 332.18,
            "startAzCompass": "NNW",
            "startEl": 2.54,
            "startUTC": 1767095020,
            "maxAz": 40.05,
            "maxAzCompass": "NE",
            "maxEl": 19.95,
            "maxUTC": 1767095320,
            "endAz": 107.07,
            "endAzCompass": "ESE",
            "endEl": 0.3,
            "endUTC": 1767095615,
            "mag": -0.4,
            "duration": 555,
            "startVisibility": 1767095060
        }
    ]
}
"""

def display_font():
    return "terminus-16" if canvas.is2x() else "5x8"

def character_width():
    # Used to estimate text widths and stagger marquee starts.
    return 8 if canvas.is2x() else 5

def fit_or_scroll(text, width, color, font):
    if len(text) * character_width() <= width:
        return render.Text(
            text,
            color = color,
            font = font,
        )

    return render.Marquee(
        width = width,
        child = render.Text(
            text,
            color = color,
            font = font,
        ),
    )

def magnitude_description(mag):
    if mag == None or mag == 100000:
        return "Brightness unknown"

    mag = float(mag)

    if mag < -3:
        return "Extremely bright"
    elif mag < -1:
        return "Very bright"
    elif mag < 0:
        return "Bright"
    elif mag < 2:
        return "Naked-eye visibility"
    elif mag < 4:
        return "Dark skies preferred"
    elif mag < 6:
        return "Faint"
    else:
        return "Very faint"

def compact_duration(seconds):
    total = max(0, int(seconds))
    hours = total // 3600
    minutes = (total % 3600) // 60
    secs = total % 60

    if hours > 0:
        return "{}h {}m".format(hours, minutes)

    if minutes > 0:
        if secs > 0:
            return "{}m {}s".format(minutes, secs)
        return "{}m".format(minutes)

    return "{}s".format(secs)

def format_locality(locality, ideal_length = 10):
    if len(locality) <= ideal_length or "," not in locality:
        return locality

    return locality.split(",")[0].strip()

def local_timestamp(timestamp, timezone):
    return time.from_timestamp(
        int(timestamp),
        0,
    ).in_location(timezone)

def get_sample_data(current_time):
    # Preserve the existing sample behavior: move it ten minutes
    # into the future on each render.
    data = json.decode(SAMPLE_DATA)
    sample_pass = data["passes"][0]
    shift = current_time + 600 - int(sample_pass["startUTC"])

    for field in [
        "startUTC",
        "maxUTC",
        "endUTC",
        "startVisibility",
    ]:
        if field in sample_pass:
            sample_pass[field] = int(sample_pass[field]) + shift

    return data

def filter_passes(
        passes,
        current_time,
        minimum_duration,
        notice_hours,
        minimum_elevation):
    upcoming_count = 0
    duration_count = 0
    elevation_count = 0
    combined_count = 0
    selected = None

    for p in passes:
        if type(p) != "dict":
            continue

        if p.get("startUTC") == None or p.get("endUTC") == None:
            continue

        if p.get("duration") == None or p.get("maxEl") == None:
            continue

        pass_start = int(p["startUTC"])
        pass_end = int(p["endUTC"])

        if pass_end <= pass_start or pass_end <= current_time:
            continue

        upcoming_count += 1

        duration_ok = int(p["duration"]) >= minimum_duration
        elevation_ok = float(p["maxEl"]) >= minimum_elevation

        if duration_ok:
            duration_count += 1

        if elevation_ok:
            elevation_count += 1

        if not duration_ok or not elevation_ok:
            continue

        combined_count += 1

        if notice_hours > 0:
            if pass_start > current_time + notice_hours * 3600:
                continue

        if selected == None:
            selected = p
        elif pass_start < int(selected["startUTC"]):
            selected = p

    return {
        "selected": selected,
        "upcoming": upcoming_count,
        "duration": duration_count,
        "elevation": elevation_count,
        "combined": combined_count,
    }

def no_match_message(
        result,
        minimum_duration,
        notice_hours,
        minimum_elevation):
    if result["upcoming"] == 0:
        return "No upcoming visible passes in cached predictions"

    if result["duration"] == 0 and result["elevation"] == 0:
        return "No passes meet the duration or elevation minimums"

    if result["duration"] == 0:
        return "No passes last at least {}".format(
            compact_duration(minimum_duration),
        )

    if result["elevation"] == 0:
        return "No passes reach {} deg".format(minimum_elevation)

    if result["combined"] == 0:
        return "No passes meet both duration and elevation settings"

    if notice_hours > 0:
        return "No matching passes within {} hour{}".format(
            notice_hours,
            "" if notice_hours == 1 else "s",
        )

    return "No upcoming passes match your filters"

def pass_time_label(sighting, current_time, timezone):
    start = int(sighting["startUTC"])
    end = int(sighting["endUTC"])

    if start <= current_time and current_time < end:
        return "Visible now"

    seconds_until = start - current_time

    if seconds_until < 60:
        return "In {}s".format(max(1, seconds_until))

    if seconds_until < 3600:
        # Round up so 59m 59s does not become "In 59m".
        minutes_until = (seconds_until + 59) // 60
        return "In {}m".format(minutes_until)

    local_now = local_timestamp(current_time, timezone)
    local_start = local_timestamp(start, timezone)

    today = local_now.format("2006-01-02")
    event_day = local_start.format("2006-01-02")

    # Find roughly noon tomorrow, away from midnight/DST edges.
    local_hour = int(local_now.format("15"))
    local_minute = int(local_now.format("04"))
    tomorrow_probe = (
        current_time +
        (36 - local_hour) * 3600 -
        local_minute * 60
    )
    tomorrow = local_timestamp(
        tomorrow_probe,
        timezone,
    ).format("2006-01-02")

    event_time = local_start.format("3:04 PM")

    if event_day == today:
        prefix = "Tonight" if int(local_start.format("15")) >= 18 else "Today"
        return "{} {}".format(prefix, event_time)

    if event_day == tomorrow:
        return "Tomorrow {}".format(event_time)

    return event_time

def pass_details(sighting, current_time):
    start = int(sighting["startUTC"])
    end = int(sighting["endUTC"])
    peak_time = sighting.get("maxUTC")
    peak_elevation = int(float(sighting["maxEl"]))

    start_direction = sighting.get("startAzCompass", "?")
    peak_direction = sighting.get("maxAzCompass", "?")
    end_direction = sighting.get("endAzCompass", "?")
    brightness = magnitude_description(sighting.get("mag"))

    if start <= current_time and current_time < end:
        remaining = compact_duration(end - current_time)

        if peak_time != None and current_time < int(peak_time):
            return (
                "Ends in {} | Peak {} deg toward {} in {} | {}"
            ).format(
                remaining,
                peak_elevation,
                peak_direction,
                compact_duration(int(peak_time) - current_time),
                brightness,
            )

        if peak_time != None:
            return "Ends in {} | Disappears toward {} | {}".format(
                remaining,
                end_direction,
                brightness,
            )

        return "Ends in {} | Peak {} deg toward {} | Ends {} | {}".format(
            remaining,
            peak_elevation,
            peak_direction,
            end_direction,
            brightness,
        )

    return "{} > {} > {} | Peak {} deg | {} | {}".format(
        start_direction,
        peak_direction,
        end_direction,
        peak_elevation,
        compact_duration(sighting["duration"]),
        brightness,
    )

def display_status(message, scroll_speed = 45):
    font = display_font()

    return render.Root(
        delay = scroll_speed,
        show_full_animation = True,
        child = render.Column(
            children = [
                fit_or_scroll(
                    "Spot the Station",
                    canvas.width(),
                    "#65d0e6",
                    font,
                ),
                render.Marquee(
                    width = canvas.width(),
                    child = render.Text(
                        message,
                        color = "#f4a306",
                        font = font,
                    ),
                ),
            ],
        ),
    )

def main(config):
    scroll_speed = int(config.get("scroll", "45"))

    if config.bool("instructions", False):
        return display_instructions(scroll_speed)

    location = json.decode(config.get("location", DEFAULT_LOCATION))
    current_time = time.now().unix

    api_key = (config.get("api_key", "") or "").strip()

    minimum_duration = max(
        0,
        int(config.get("minimum_duration", "0")),
    )
    notice_hours = max(
        0,
        int(config.get("notice_period", "0")),
    )
    minimum_elevation = int(config.get("minimum_elevation", "5"))
    hide_when_empty = config.bool("hide_when_empty", False)

    is_sample_data = not api_key

    if is_sample_data:
        station_data = get_sample_data(current_time)
    else:
        # Changing display filters does not change this URL.
        url = STATION_LOCATION_API.format(
            space_station_id = SPACE_STATION_ID,
            latitude = location["lat"],
            longitude = location["lng"],
            days = PREDICTION_DAYS,
            min_visibility = API_MIN_VISIBILITY,
            api_key = api_key,
        )

        resp = http.get(url, ttl_seconds = CACHE_DURATION)

        if resp.status_code != 200:
            return display_status(
                "API request failed: HTTP {}".format(resp.status_code),
                scroll_speed,
            )

        station_data = resp.json()

        if type(station_data) != "dict":
            return display_status(
                "API returned an unexpected response",
                scroll_speed,
            )

        # Avoid displaying raw error text that might contain
        # request details or the API key.
        if "error" in station_data:
            return display_status(
                "N2YO API error. Check your API key and account.",
                scroll_speed,
            )

    passes = station_data.get("passes")

    if type(passes) != "list":
        return display_status(
            "API response is missing a valid passes list",
            scroll_speed,
        )

    result = filter_passes(
        passes,
        current_time,
        minimum_duration,
        notice_hours,
        minimum_elevation,
    )
    sighting = result["selected"]

    if sighting == None:
        if hide_when_empty:
            return []

        message = no_match_message(
            result,
            minimum_duration,
            notice_hours,
            minimum_elevation,
        )

        if is_sample_data:
            message = "Sample: " + message

        return display_status(message, scroll_speed)

    timezone = (
        location.get("timezone") or
        config.get("$tz") or
        "America/New_York"
    )

    event_start = local_timestamp(
        sighting["startUTC"],
        timezone,
    )

    time_text = pass_time_label(
        sighting,
        current_time,
        timezone,
    )

    details_text = pass_details(sighting, current_time)

    # Keep exact local start time available when the main label
    # shows a countdown, relative day, or ongoing-pass status.
    date_text = "{} | Starts {}".format(
        event_start.format("Jan 2, 2006"),
        event_start.format("3:04 PM"),
    )

    if is_sample_data:
        time_text = "Sample: " + time_text
        details_text = "Sample only, not a real prediction | " + details_text

    locality = (
        location.get("locality") or
        location.get("description") or
        "Selected location"
    )

    return get_display(
        format_locality(locality),
        time_text,
        date_text,
        details_text,
        scroll_speed,
    )

def display_instructions(scroll_speed = 45):
    font = display_font()
    char_width = character_width()

    lines = [
        "Spot the Station",
        "1. Create a free N2YO.com account and generate an API key.",
        "2. Enter your API key and select your location in settings.",
        (
            "3. Set duration, elevation, and notice filters. " +
            "Predictions are cached for 24 hours. " +
            "Turn off Display Instructions when finished."
        ),
    ]

    children = []
    offset = 0

    for index in range(len(lines)):
        text = lines[index]

        children.append(
            render.Marquee(
                width = canvas.width(),
                offset_start = offset,
                child = render.Text(
                    text,
                    color = "#65d0e6" if index == 0 else "#f4a306",
                    font = font,
                ),
            ),
        )

        # Start the next line shortly before this one finishes.
        offset += max(
            char_width * 4,
            len(text) * char_width - canvas.width() // 4,
        )

    return render.Root(
        delay = scroll_speed,
        show_full_animation = True,
        child = render.Column(children = children),
    )

def get_iss_animation():
    frames = [
        ISS_ICON,
        ISS_ICON2,
        ISS_ICON,
        ISS_ICON3,
        ISS_ICON,
        ISS_ICON4,
        ISS_ICON,
        ISS_ICON5,
        ISS_ICON,
        ISS_ICON5,
        ISS_ICON,
        ISS_ICON5,
        ISS_ICON,
        ISS_ICON5,
        ISS_ICON,
        ISS_ICON5,
        ISS_ICON,
        ISS_ICON4,
        ISS_ICON,
        ISS_ICON3,
        ISS_ICON,
        ISS_ICON2,
    ] + [ISS_ICON] * 11

    return render.Animation(
        children = [
            render.Image(src = frame)
            for frame in frames
        ],
    )

def get_display(location, row1, row2, row3, scroll_speed = 45):
    font = display_font()
    text_width = canvas.width() - ISS_IMAGE_WIDTH

    return render.Root(
        show_full_animation = True,
        delay = scroll_speed,
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        get_iss_animation(),
                        render.Column(
                            children = [
                                fit_or_scroll(
                                    location,
                                    text_width,
                                    "#0099FF",
                                    font,
                                ),
                                fit_or_scroll(
                                    row1,
                                    text_width,
                                    "#fff",
                                    font,
                                ),
                            ],
                        ),
                    ],
                ),
                fit_or_scroll(
                    row2,
                    canvas.width(),
                    "#fff",
                    font,
                ),
                render.Marquee(
                    width = canvas.width(),
                    child = render.Text(
                        row3,
                        color = "#ff0",
                        font = font,
                    ),
                ),
            ],
        ),
    )

def get_schema():
    notice_period_options = [
        schema.Option(value = "1", display = "1 hour"),
        schema.Option(value = "2", display = "2 hours"),
        schema.Option(value = "3", display = "3 hours"),
        schema.Option(value = "4", display = "4 hours"),
        schema.Option(value = "5", display = "5 hours"),
        schema.Option(value = "12", display = "12 hours"),
        schema.Option(value = "24", display = "1 day"),
        schema.Option(value = "48", display = "2 days"),
        schema.Option(value = "72", display = "3 days"),
        schema.Option(value = "168", display = "1 week"),
        schema.Option(
            value = "0",
            display = "Always display next matching sighting if known",
        ),
    ]

    minimum_duration_options = [
        schema.Option(value = "60", display = "1 minute"),
        schema.Option(value = "120", display = "2 minutes"),
        schema.Option(value = "180", display = "3 minutes"),
        schema.Option(value = "240", display = "4 minutes"),
        schema.Option(value = "300", display = "5 minutes"),
        schema.Option(value = "360", display = "6 minutes"),
        schema.Option(value = "420", display = "7 minutes"),
        schema.Option(value = "480", display = "8 minutes"),
        schema.Option(value = "540", display = "9 minutes"),
        schema.Option(value = "600", display = "10 minutes"),
        schema.Option(
            value = "0",
            display = "Any returned pass (1 second or longer)",
        ),
    ]

    minimum_elevation_options = [
        schema.Option(
            value = "5",
            display = "Low passes or higher (5 degrees)",
        ),
        schema.Option(
            value = "20",
            display = "Moderate passes or higher (20 degrees)",
        ),
        schema.Option(
            value = "40",
            display = "High passes or higher (40 degrees)",
        ),
        schema.Option(
            value = "60",
            display = "Very high passes (60 degrees or higher)",
        ),
    ]

    scroll_speed_options = [
        schema.Option(value = "60", display = "Slow Scroll"),
        schema.Option(value = "45", display = "Medium Scroll"),
        schema.Option(value = "30", display = "Fast Scroll"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "N2YO.com API Key",
                icon = "locationArrow",
                desc = (
                    "Create a free N2YO.com account, then generate " +
                    "an API key from your profile."
                ),
                secret = True,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = (
                    "Used for pass predictions and the displayed " +
                    "local date and time."
                ),
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "notice_period",
                name = "Notice Period",
                desc = (
                    "Display matching passes within this period. " +
                    "Applied locally to cached predictions."
                ),
                icon = "userClock",
                options = notice_period_options,
                default = "0",
            ),
            schema.Dropdown(
                id = "minimum_duration",
                name = "Minimum Duration",
                desc = (
                    "Minimum total visible duration. " +
                    "Applied locally to cached predictions."
                ),
                icon = "stopwatch",
                options = minimum_duration_options,
                default = "0",
            ),
            schema.Dropdown(
                id = "minimum_elevation",
                name = "Types of Passes",
                desc = (
                    "Minimum peak elevation above the horizon. " +
                    "Applied locally to cached predictions."
                ),
                icon = "mountainSun",
                options = minimum_elevation_options,
                default = "5",
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll speed",
                icon = "scroll",
                options = scroll_speed_options,
                default = "45",
            ),
            schema.Toggle(
                id = "hide_when_empty",
                name = "Hide When No Matching Pass",
                desc = (
                    "Hide the app instead of showing a " +
                    "no-matching-passes message."
                ),
                icon = "info",
                default = False,
            ),
            schema.Toggle(
                id = "instructions",
                name = "Display Instructions",
                desc = "",
                icon = "book",
                default = False,
            ),
        ],
    )
