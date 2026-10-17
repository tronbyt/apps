"""
Applet: LaunchCountdown
Summary: Displays next world launch
Description: Displays the next matching rocket launch in the world.
Author: Robert Ison
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/rocket_icon.png", ROCKET_ICON_ASSET = "file")
load("images/rocket_icon_b.png", ROCKET_ICON_B_ASSET = "file")
load("images/rocket_icon_c.png", ROCKET_ICON_C_ASSET = "file")
load("images/rocket_icon_d.png", ROCKET_ICON_D_ASSET = "file")
load("images/rocket_icon_e.png", ROCKET_ICON_E_ASSET = "file")
load("images/rocket_icon_f.png", ROCKET_ICON_F_ASSET = "file")
load("images/rocket_icon_g.png", ROCKET_ICON_G_ASSET = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

ROCKET_ICON = ROCKET_ICON_ASSET.readall()
ROCKET_ICON_B = ROCKET_ICON_B_ASSET.readall()
ROCKET_ICON_C = ROCKET_ICON_C_ASSET.readall()
ROCKET_ICON_D = ROCKET_ICON_D_ASSET.readall()
ROCKET_ICON_E = ROCKET_ICON_E_ASSET.readall()
ROCKET_ICON_F = ROCKET_ICON_F_ASSET.readall()
ROCKET_ICON_G = ROCKET_ICON_G_ASSET.readall()

ROCKET_LAUNCH_URL = "https://fdo.rocketlaunch.live/json/launches/next/5"

HTTP_CACHE_SECONDS = 300
POST_TIME_GRACE_SECONDS = 15 * 60

# Match this to the actual width of your PNG assets.
ROCKET_IMAGE_WIDTH = 16

DEFAULT_LOCATION = """
{
    "lat": "28.53933",
    "lng": "-81.38325",
    "description": "Orlando, FL, USA",
    "locality": "Orlando",
    "timezone": "America/New_York"
}
"""

MONTH_NAMES = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
]

PERIOD_OPTIONS = [
    schema.Option(value = "1", display = "1 hour"),
    schema.Option(value = "2", display = "2 hours"),
    schema.Option(value = "3", display = "3 hours"),
    schema.Option(value = "4", display = "4 hours"),
    schema.Option(value = "5", display = "5 hours"),
    schema.Option(value = "6", display = "6 hours"),
    schema.Option(value = "12", display = "12 hours"),
    schema.Option(value = "24", display = "1 day"),
    schema.Option(value = "48", display = "2 days"),
    schema.Option(value = "72", display = "3 days"),
    schema.Option(value = "168", display = "1 week"),
    schema.Option(
        value = "0",
        display = "Always display next matching launch if known",
    ),
]

SCROLL_SPEED_OPTIONS = [
    schema.Option(value = "60", display = "Slow Scroll"),
    schema.Option(value = "45", display = "Medium Scroll"),
    schema.Option(value = "30", display = "Fast Scroll"),
]

def display_font():
    return "terminus-16" if canvas.is2x() else "5x8"

def character_width():
    return 8 if canvas.is2x() else 5

def as_dict(value):
    return value if type(value) == "dict" else {}

def clean_text(value):
    if value == None:
        return ""

    return str(value).strip()

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

def compact_duration(seconds):
    total = max(0, int(seconds))
    days = total // 86400
    hours = (total % 86400) // 3600
    minutes = (total % 3600) // 60
    secs = total % 60

    if days > 0:
        return "{}d {}h".format(days, hours)

    if hours > 0:
        return "{}h {}m".format(hours, minutes)

    if minutes > 0:
        return "{}m {}s".format(minutes, secs)

    return "{}s".format(secs)

def parse_launch_time(value):
    if type(value) != "string":
        return None

    value = value.strip()

    if not value:
        return None

    # Normalize minute-only UTC timestamps without changing
    # timestamps that already contain seconds.
    if len(value) == 17 and value.endswith("Z"):
        value = value[:-1] + ":00Z"

    return time.parse_time(value)

def launch_time_info(launch):
    t0 = clean_text(launch.get("t0"))

    if t0:
        return {
            "time": parse_launch_time(t0),
            "kind": "launch",
        }

    window_open = clean_text(launch.get("win_open"))

    if window_open:
        return {
            "time": parse_launch_time(window_open),
            "kind": "window",
        }

    return {
        "time": None,
        "kind": "estimated",
    }

def parse_filter_list(value):
    items = []

    for part in clean_text(value).split(","):
        item = part.strip().lower()

        if item and item not in items:
            items.append(item)

    return items

def filter_launches(launches, provider_text, country_text):
    providers = parse_filter_list(provider_text)
    countries = parse_filter_list(country_text)
    filtered = []

    for launch in launches:
        if type(launch) != "dict":
            continue

        provider = as_dict(launch.get("provider"))
        pad = as_dict(launch.get("pad"))
        launch_location = as_dict(pad.get("location"))

        provider_name = clean_text(provider.get("name")).lower()
        country_name = clean_text(launch_location.get("country")).lower()

        if providers and provider_name not in providers:
            continue

        if countries and country_name not in countries:
            continue

        filtered.append(launch)

    return filtered

def select_launch(launches, current_time, notice_hours):
    candidates = []
    expired_count = 0
    estimated_count = 0

    for launch in launches:
        info = launch_time_info(launch)
        event_time = info["time"]

        if event_time == None:
            estimated_count += 1

            # Keep estimated entries in feed order, but only
            # include them when Always Display is selected.
            if notice_hours == 0:
                candidates.append({
                    "launch": launch,
                    "time": None,
                    "kind": "estimated",
                })

            continue

        seconds_until = event_time.unix - current_time

        if seconds_until < -POST_TIME_GRACE_SECONDS:
            expired_count += 1
            continue

        if notice_hours > 0:
            if seconds_until > notice_hours * 3600:
                continue

        candidates.append({
            "launch": launch,
            "time": event_time,
            "kind": info["kind"],
        })

    # Preserve the feed's upcoming-launch order, including its
    # placement of estimated-date entries in Always Display mode.
    return {
        "selected": candidates[0] if candidates else None,
        "expired": expired_count,
        "estimated": estimated_count,
    }

def estimated_date_text(launch):
    estimate = as_dict(launch.get("est_date"))

    year = clean_text(estimate.get("year"))
    month = clean_text(estimate.get("month"))
    day = clean_text(estimate.get("day"))

    month_name = ""

    # Accept numeric months without risking int() on arbitrary text.
    for index in range(len(MONTH_NAMES)):
        number = index + 1

        if month == str(number) or month == "{:02d}".format(number):
            month_name = MONTH_NAMES[index]
            break

    if month_name and day:
        date_text = "{} {}".format(month_name, day)

        if year:
            date_text += " " + year

        return date_text

    if month_name:
        return "{} {}".format(month_name, year).strip()

    if year:
        return year

    return "Date TBD"

def launch_details(launch):
    provider = as_dict(launch.get("provider"))
    pad = as_dict(launch.get("pad"))
    launch_location = as_dict(pad.get("location"))

    pad_name = clean_text(pad.get("name"))

    if pad_name.lower() == "launch pad":
        pad_name = ""

    items = [
        clean_text(provider.get("name")),
        pad_name,
        clean_text(launch_location.get("name")),
        clean_text(launch_location.get("state")),
        clean_text(launch_location.get("country")),
    ]

    unique_items = []
    seen = []

    for item in items:
        key = item.lower()

        if item and key not in seen:
            unique_items.append(item)
            seen.append(key)

    return " | ".join(unique_items)

def mission_details(launch):
    items = []
    mission_name = clean_text(launch.get("name"))
    description = clean_text(launch.get("launch_description")).replace("\u202f", " ")

    if mission_name:
        items.append(mission_name)

    # Preserve the source description rather than replacing UTC
    # times in prose without also correcting associated dates.
    if description and description.lower() != mission_name.lower():
        items.append(description)

    return " | ".join(items)

def build_launch_rows(selected, current_time, timezone):
    launch = selected["launch"]
    event_time = selected["time"]
    kind = selected["kind"]

    vehicle = as_dict(launch.get("vehicle"))
    row1 = clean_text(vehicle.get("name")) or "Rocket launch"

    location_details = launch_details(launch)
    mission_text = mission_details(launch)

    if event_time == None:
        row2 = estimated_date_text(launch) + " | Time TBD"
        row3 = location_details or "Launch location unavailable"
        row4 = mission_text or "Exact launch time not announced"

        return [row1, row2, row3, row4]

    local_event = event_time.in_location(timezone)

    mission_text = replace_local_time_into_description(
        mission_text,
        local_event,
        event_time.in_location("UTC"),
    )

    seconds_until = event_time.unix - current_time

    # Always retain the exact local date and time.
    row2 = local_event.format("Jan 2 '06 | 3:04 PM MST")

    if kind == "window":
        row2 = "Window: " + row2

    if seconds_until > 0:
        if kind == "window":
            status = "Window opens in " + compact_duration(seconds_until)
        else:
            status = "Launch in " + compact_duration(seconds_until)
    else:
        elapsed = compact_duration(-seconds_until)

        if kind == "window":
            status = (
                "Window opened {} ago | Awaiting launch update"
            ).format(elapsed)
        else:
            status = (
                "Scheduled time passed | Scheduled {} ago | " +
                "Awaiting schedule update"
            ).format(elapsed)

    row3 = status

    if location_details:
        row3 += " | " + location_details

    row4 = mission_text or "No additional launch details"

    return [row1, row2, row3, row4]

def display_status(title, message, scroll_speed):
    font = display_font()

    return render.Root(
        delay = scroll_speed,
        show_full_animation = True,
        child = render.Column(
            children = [
                fit_or_scroll(
                    title,
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

def display_error(message, show_errors, scroll_speed):
    # Always record detected errors in Show Render Debug.
    print("[LaunchCountdown ERROR] " + message)

    # This setting only controls the physical display.
    if not show_errors:
        return []

    return display_status(
        "Launch Feed Error",
        message,
        scroll_speed,
    )

def display_empty(message, hide_when_empty, scroll_speed):
    if hide_when_empty:
        return []

    return display_status(
        "No Matching Launch",
        message,
        scroll_speed,
    )

def display_instructions(scroll_speed):
    font = display_font()
    char_width = character_width()

    lines = [
        "Launch Countdown",
        (
            "Launch data: RocketLaunch.live. " +
            "The free feed contains the next five worldwide launches."
        ),
        (
            "Filter by exact provider or launch-site country name. " +
            "Separate multiple names with commas. " +
            "Examples: SpaceX or United States."
        ),
        (
            "Notice settings filter cached data. " +
            "Always Display allows estimated dates marked Time TBD. " +
            "Display Errors is separate from Hide When No Matching Launch. " +
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

        offset += max(
            char_width * 4,
            len(text) * char_width - canvas.width() // 4,
        )

    return render.Root(
        delay = scroll_speed,
        show_full_animation = True,
        child = render.Column(children = children),
    )

def rocket_animation():
    frames = [
        ROCKET_ICON,
        ROCKET_ICON_B,
        ROCKET_ICON_C,
        ROCKET_ICON_D,
        ROCKET_ICON_E,
        ROCKET_ICON_F,
        ROCKET_ICON_G,
        ROCKET_ICON_F,
        ROCKET_ICON_D,
        ROCKET_ICON_C,
        ROCKET_ICON_B,
        ROCKET_ICON,
        ROCKET_ICON_B,
        ROCKET_ICON,
        ROCKET_ICON_C,
        ROCKET_ICON,
        ROCKET_ICON_B,
        ROCKET_ICON_C,
        ROCKET_ICON_B,
        ROCKET_ICON_C,
        ROCKET_ICON_B,
        ROCKET_ICON_C,
        ROCKET_ICON_B,
        ROCKET_ICON_C,
        ROCKET_ICON_D,
        ROCKET_ICON_E,
        ROCKET_ICON_D,
        ROCKET_ICON_C,
        ROCKET_ICON_B,
        ROCKET_ICON,
        ROCKET_ICON,
    ]

    return render.Animation(
        children = [
            render.Image(src = frame)
            for frame in frames
        ],
    )

def display_launch(rows, scroll_speed):
    font = display_font()
    char_width = character_width()
    text_width = canvas.width() - ROCKET_IMAGE_WIDTH

    widths = [
        text_width,
        text_width,
        canvas.width(),
        canvas.width(),
    ]

    colors = [
        "#65d0e6",
        "#fff",
        "#fff",
        "#ff0",
    ]

    widgets = []
    offset = 0

    for index in range(len(rows)):
        text = rows[index]
        width = widths[index]
        estimated_width = len(text) * char_width

        if estimated_width <= width:
            widgets.append(
                render.Text(
                    text,
                    color = colors[index],
                    font = font,
                ),
            )
        else:
            widgets.append(
                render.Marquee(
                    width = width,
                    offset_start = offset,
                    child = render.Text(
                        text,
                        color = colors[index],
                        font = font,
                    ),
                ),
            )

            # Start the next scrolling row shortly before
            # this row finishes its first pass.
            offset += max(
                char_width * 4,
                estimated_width - width // 4,
            )

    return render.Root(
        show_full_animation = True,
        delay = scroll_speed,
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Column(
                            children = [
                                widgets[0],
                                widgets[1],
                            ],
                        ),
                        rocket_animation(),
                    ],
                ),
                widgets[2],
                widgets[3],
            ],
        ),
    )

def replace_local_time_into_description(description, local_time, utc_time):
    if local_time == None or utc_time == None:
        return description

    # Normalize unusual spaces so either feed format matches.
    description = description.replace("\u202f", " ")
    description = description.replace("\u00a0", " ")

    timezone_abbr = local_time.format("MST")

    utc_hour_raw = utc_time.format("15")
    utc_min_raw = utc_time.format("04")
    utc_hour_12 = int(utc_hour_raw) % 12

    if utc_hour_12 == 0:
        utc_hour_12 = 12

    utc_ampm = "PM" if int(utc_hour_raw) >= 12 else "AM"

    local_hour_raw = local_time.format("15")
    local_min_raw = local_time.format("04")
    local_hour_12 = int(local_hour_raw) % 12

    if local_hour_12 == 0:
        local_hour_12 = 12

    local_ampm = "PM" if int(local_hour_raw) >= 12 else "AM"

    utc_part = "%d:%s %s (UTC)" % (
        utc_hour_12,
        utc_min_raw,
        utc_ampm,
    )

    local_part = "%d:%s %s (%s)" % (
        local_hour_12,
        local_min_raw,
        local_ampm,
        timezone_abbr,
    )

    return description.replace(utc_part, local_part)

def main(config):
    scroll_speed = int(config.get("scroll", "60"))

    if config.bool("instructions", False):
        return display_instructions(scroll_speed)

    hide_when_empty = config.bool("hide", True)
    show_errors = config.bool("display_errors", False)

    notice_hours = max(
        0,
        int(config.get("notice_period", "0")),
    )

    location = json.decode(
        config.get("location", DEFAULT_LOCATION),
    )

    timezone = (
        location.get("timezone") or
        config.get("$tz") or
        "America/New_York"
    )

    # Single caching layer. The request URL is independent of
    # provider, country, notice period, and display settings.
    response = http.get(
        ROCKET_LAUNCH_URL,
        ttl_seconds = HTTP_CACHE_SECONDS,
    )

    if response.status_code != 200:
        return display_error(
            "HTTP {}".format(response.status_code),
            show_errors,
            scroll_speed,
        )

    data = response.json()

    if type(data) != "dict":
        return display_error(
            "Unexpected feed response",
            show_errors,
            scroll_speed,
        )

    launches = data.get("result")

    if type(launches) != "list":
        return display_error(
            "Feed is missing a valid launch list",
            show_errors,
            scroll_speed,
        )

    if not launches:
        return display_empty(
            "No launches returned by the feed",
            hide_when_empty,
            scroll_speed,
        )

    # A list containing only invalid entries is a feed error,
    # not a normal empty-filter result.
    valid_launches = [
        launch
        for launch in launches
        if type(launch) == "dict"
    ]

    if not valid_launches:
        return display_error(
            "Feed contains no valid launch entries",
            show_errors,
            scroll_speed,
        )

    filtered = filter_launches(
        valid_launches,
        config.get("filter_for_providers", ""),
        config.get("filter_for_countries", ""),
    )

    if not filtered:
        return display_empty(
            "No provider/country matches among the next 5 launches",
            hide_when_empty,
            scroll_speed,
        )

    current_time = time.now().unix

    selection = select_launch(
        filtered,
        current_time,
        notice_hours,
    )

    selected = selection["selected"]

    if selected == None:
        if notice_hours > 0:
            if selection["estimated"] == len(filtered):
                message = (
                    "Matching launches have Time TBD | " +
                    "Use Always Display to include them"
                )
            else:
                message = (
                    "No eligible matching launch within {} hour{} " +
                    "among the next 5 launches"
                ).format(
                    notice_hours,
                    "" if notice_hours == 1 else "s",
                )
        else:
            message = (
                "Matching launch times have passed the " +
                "15-minute grace period | Awaiting feed update"
            )

        return display_empty(
            message,
            hide_when_empty,
            scroll_speed,
        )

    rows = build_launch_rows(
        selected,
        current_time,
        timezone,
    )

    return display_launch(rows, scroll_speed)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Used to display launch times in your local timezone.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "notice_period",
                name = "Notice Period",
                desc = (
                    "Display timed launches within this period. " +
                    "Always Display also includes estimated dates."
                ),
                icon = "userClock",
                options = PERIOD_OPTIONS,
                default = "0",
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll and animation speed.",
                icon = "stopwatch",
                options = SCROLL_SPEED_OPTIONS,
                default = "60",
            ),
            schema.Text(
                id = "filter_for_providers",
                name = "Only Show These Providers",
                desc = (
                    "Comma-separated exact provider names. " +
                    "Leave blank for all. Searches the next 5 launches."
                ),
                icon = "industry",
            ),
            schema.Text(
                id = "filter_for_countries",
                name = "Only Show These Countries",
                desc = (
                    "Comma-separated exact launch-site country names. " +
                    "Leave blank for all. Searches the next 5 launches."
                ),
                icon = "globe",
            ),
            schema.Toggle(
                id = "hide",
                name = "Hide When No Matching Launch",
                desc = (
                    "Hide instead of showing an empty-feed or " +
                    "no-matching-launch message."
                ),
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "display_errors",
                name = "Display Errors",
                desc = (
                    "Show detected HTTP and feed-structure errors. " +
                    "When off, hide the app for those errors."
                ),
                icon = "info",
                default = False,
            ),
            schema.Toggle(
                id = "instructions",
                name = "Display Instructions",
                desc = "Show setup instructions instead of launch information.",
                icon = "book",
                default = False,
            ),
        ],
    )
