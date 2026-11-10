"""
Applet: Waste Pickup Reminder
Summary: Waste Pickup Reminder
Description: Displays waste pickup for today and tomorrow, or the next scheduled pickup.
Author: Robert Ison
"""

load("humanize.star", "humanize")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

CALENDAR_BACKGROUND = "#ffffff"
CALENDAR_HEADER = "#ff0000"
CALENDAR_TEXT = "#000000"
SKIP_MARKER_COLOR = "#ffb000"

WASTE_TYPES = [
    {
        "name": "Garbage",
        "icon": "🗑️",
        "icon_name": "trash",
    },
    {
        "name": "Recycling",
        "icon": "♻️",
        "icon_name": "recycle",
    },
    {
        "name": "Yard Waste",
        "icon": "🌳",
        "icon_name": "leaf",
    },
    {
        "name": "Bulk Waste",
        "icon": "🚛",
        "icon_name": "truck",
    },
]

def get_schema():
    scroll_speed_options = [
        schema.Option(
            display = "Slow Scroll",
            value = "60",
        ),
        schema.Option(
            display = "Medium Scroll",
            value = "45",
        ),
        schema.Option(
            display = "Fast Scroll",
            value = "30",
        ),
    ]

    empty_behavior_options = [
        schema.Option(
            display = "Skip App",
            value = "skip",
        ),
        schema.Option(
            display = "Show Next Pickup Date",
            value = "next",
        ),
    ]

    weekdays = [
        ["1", "Monday"],
        ["2", "Tuesday"],
        ["3", "Wednesday"],
        ["4", "Thursday"],
        ["5", "Friday"],
        ["6", "Saturday"],
        ["7", "Sunday"],
    ]

    fields = [
        schema.Dropdown(
            id = "empty_behavior",
            name = "When Nothing Is Due Soon",
            desc = "Skip the app or show the next pickup date when nothing is scheduled for today or tomorrow.",
            icon = "calendar",
            options = empty_behavior_options,
            default = "skip",
        ),
        schema.Toggle(
            id = "icons_only",
            name = "Icons Only",
            desc = "Only show pickup icons, without waste-type names.",
            icon = "closedCaptioning",
            default = False,
        ),
        schema.Dropdown(
            id = "scroll",
            name = "Scroll",
            desc = "Scroll Speed",
            icon = "scroll",
            options = scroll_speed_options,
            default = "60",
        ),
    ]

    for waste_type in WASTE_TYPES:
        name = waste_type["name"]
        prefix = name.replace(" ", "_").lower()

        for value, day in weekdays:
            fields.append(
                schema.Toggle(
                    id = prefix + "_" + value,
                    name = day + " (" + name + ")",
                    desc = name + " Pickup on " + day,
                    icon = waste_type["icon_name"],
                    default = False,
                ),
            )

    return schema.Schema(
        version = "1",
        fields = fields,
    )

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

def get_label_for_waste_type(waste_type, icons_only):
    if icons_only:
        return waste_type["icon"]

    return waste_type["icon"] + " " + waste_type["name"]

def get_pickups_for_day(config, day_number, icons_only):
    pickups = []

    for waste_type in WASTE_TYPES:
        prefix = waste_type["name"].replace(" ", "_").lower()
        key = prefix + "_" + str(day_number)

        if config.bool(key, False):
            pickups.append(
                get_label_for_waste_type(waste_type, icons_only),
            )

    return pickups

def get_local_noon_anchor(now, timezone):
    return time.time(
        year = now.year,
        month = now.month,
        day = now.day,
        hour = 12,
        minute = 0,
        second = 0,
        location = timezone,
    )

def config_day_of_week(date):
    # humanize: Sunday = 0 through Saturday = 6.
    # Configuration: Monday = 1 through Sunday = 7.
    dow = humanize.day_of_week(date)
    return 7 if dow == 0 else dow

def find_next_pickup(config, today_anchor, icons_only):
    # Today and tomorrow have already been checked.
    for offset in range(2, 8):
        candidate = (
            today_anchor +
            time.parse_duration("{}h".format(offset * 24))
        )

        candidate_pickups = get_pickups_for_day(
            config,
            config_day_of_week(candidate),
            icons_only,
        )

        if len(candidate_pickups) > 0:
            return {
                "time": candidate,
                "pickups": candidate_pickups,
            }

    return None

def make_calendar(
        day_number,
        left,
        top,
        size,
        header_height,
        date_font,
        date_font_width,
        date_font_height):
    date_text = ("0" if day_number < 10 else "") + str(day_number)

    text_width = len(date_text) * date_font_width
    text_left = max(0, (size - text_width) // 2)

    body_height = size - header_height
    text_top = (
        header_height +
        max(0, (body_height - date_font_height) // 2)
    )

    return [
        add_padding_to_child_element(
            render.Box(
                color = CALENDAR_BACKGROUND,
                width = size,
                height = size,
            ),
            left = left,
            top = top,
        ),
        add_padding_to_child_element(
            render.Box(
                color = CALENDAR_HEADER,
                width = size,
                height = header_height,
            ),
            left = left,
            top = top,
        ),
        add_padding_to_child_element(
            render.Text(
                date_text,
                color = CALENDAR_TEXT,
                font = date_font,
            ),
            left = left + text_left,
            top = top + text_top,
        ),
    ]

def make_skip_marker(left, top, scale):
    # Two downward chevrons, drawn as pixels rather than an emoji.
    #
    # #.#
    # .#.
    # #.#
    # .#.
    pixels = [
        [0, 0],
        [2, 0],
        [1, 1],
        [0, 2],
        [2, 2],
        [1, 3],
    ]

    elements = []

    for x, y in pixels:
        elements.append(
            add_padding_to_child_element(
                render.Box(
                    color = SKIP_MARKER_COLOR,
                    width = scale,
                    height = scale,
                ),
                left = left + x * scale,
                top = top + y * scale,
            ),
        )

    return elements

def make_pickup_row(
        text,
        left,
        top,
        width,
        font):
    # Do not create an empty scrolling text element.
    if text == "":
        return []

    return [
        add_padding_to_child_element(
            render.Marquee(
                width = width,
                child = render.Text(
                    text + " ",
                    font = font,
                ),
            ),
            left = left,
            top = top,
        ),
    ]

def main(config):
    timezone = time.tz()
    now = time.now().in_location(timezone)

    icons_only = config.bool("icons_only", False)
    empty_behavior = config.str("empty_behavior", "skip")

    today_anchor = get_local_noon_anchor(now, timezone)
    tomorrow = today_anchor + time.parse_duration("24h")

    pickups_today = get_pickups_for_day(
        config,
        config_day_of_week(today_anchor),
        icons_only,
    )

    pickups_tomorrow = get_pickups_for_day(
        config,
        config_day_of_week(tomorrow),
        icons_only,
    )

    show_next_pickup = (
        len(pickups_today) == 0 and
        len(pickups_tomorrow) == 0
    )

    second_time = tomorrow
    second_pickups = pickups_tomorrow

    if show_next_pickup:
        if empty_behavior != "next":
            return []

        next_pickup = find_next_pickup(
            config,
            today_anchor,
            icons_only,
        )

        if next_pickup == None:
            return []

        second_time = next_pickup["time"]
        second_pickups = next_pickup["pickups"]

    is_2x = canvas.is2x()
    scale = 2 if is_2x else 1

    screen_height = canvas.height()
    screen_width = canvas.width()
    half_height = screen_height // 2

    connector = "  " if is_2x else " "
    row1 = connector.join(pickups_today)
    row2 = connector.join(second_pickups)

    if is_2x:
        # Slightly smaller date digits allow shorter calendar tiles.
        date_font = "terminus-16"
        date_font_width = 8
        date_font_height = 16

        # Preserve the existing larger pickup text/icons.
        pickup_font = "terminus-18"
        text_vertical_offset = 3
    else:
        date_font = "5x8"
        date_font_width = 5
        date_font_height = 8

        pickup_font = "5x8"
        text_vertical_offset = 2

    # Standard display:
    #   top calendar:    y = 1, height = 12
    #   lower calendar:  y = 18, height = 12
    #   gap:             5 pixels
    #
    # Dimensions scale proportionally for a 2x display.
    calendar_left = scale
    calendar_size = half_height - 4 * scale
    calendar_header_height = 3 * scale

    top_calendar_y = scale
    bottom_calendar_y = half_height + 2 * scale

    # Leave one scaled pixel between calendars and pickup text.
    pickup_left = calendar_left + calendar_size + scale
    pickup_width = max(1, screen_width - pickup_left)

    scroll_speed = int(config.str("scroll", "60"))
    delay = scroll_speed // 2 if is_2x else scroll_speed

    children = []

    children.extend(
        make_calendar(
            day_number = now.day,
            left = calendar_left,
            top = top_calendar_y,
            size = calendar_size,
            header_height = calendar_header_height,
            date_font = date_font,
            date_font_width = date_font_width,
            date_font_height = date_font_height,
        ),
    )

    children.extend(
        make_calendar(
            day_number = second_time.day,
            left = calendar_left,
            top = bottom_calendar_y,
            size = calendar_size,
            header_height = calendar_header_height,
            date_font = date_font,
            date_font_width = date_font_width,
            date_font_height = date_font_height,
        ),
    )

    if show_next_pickup:
        marker_width = 3 * scale
        marker_height = 4 * scale

        gap_top = top_calendar_y + calendar_size
        gap_height = bottom_calendar_y - gap_top

        marker_left = (
            calendar_left +
            (calendar_size - marker_width) // 2
        )

        marker_top = (
            gap_top +
            (gap_height - marker_height) // 2
        )

        children.extend(
            make_skip_marker(
                left = marker_left,
                top = marker_top,
                scale = scale,
            ),
        )

    children.extend(
        make_pickup_row(
            text = row1,
            left = pickup_left,
            top = text_vertical_offset,
            width = pickup_width,
            font = pickup_font,
        ),
    )

    children.extend(
        make_pickup_row(
            text = row2,
            left = pickup_left,
            top = half_height + text_vertical_offset,
            width = pickup_width,
            font = pickup_font,
        ),
    )

    return render.Root(
        render.Stack(
            children = children,
        ),
        delay = delay,
        show_full_animation = True,
    )
