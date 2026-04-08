"""
Applet: Waste Pickup Reminder
Summary: Waste Pickup Reminder
Description: Displays waste pickup for today and tomorrow.
Author: Robert Ison
"""

load("humanize.star", "humanize")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

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
            desc = "Skip the app or show the next pickup date when nothing is scheduled for today or tomorrow",
            icon = "calendar",
            options = empty_behavior_options,
            default = "skip",
        ),
        schema.Toggle(
            id = "icons_only",
            name = "Icons Only",
            desc = "Only show icons",
            icon = "closedCaptioning",
            default = False,
        ),
        schema.Dropdown(
            id = "scroll",
            name = "Scroll",
            desc = "Scroll Speed",
            icon = "scroll",
            options = scroll_speed_options,
            default = scroll_speed_options[0].value,
        ),
    ]

    def add_waste_type(name, icon):
        for i in range(len(weekdays)):
            value = weekdays[i][0]
            day = weekdays[i][1]

            fields.append(
                schema.Toggle(
                    id = name.replace(" ", "_").lower() + "_" + value,
                    name = day + " (" + name + ")",
                    desc = name + " Pickup on " + day,
                    icon = icon,
                    default = False,
                ),
            )

    add_waste_type("Garbage", "trash")
    add_waste_type("Recycling", "recycle")
    add_waste_type("Yard Waste", "leaf")
    add_waste_type("Bulk Waste", "truck")

    return schema.Schema(
        version = "1",
        fields = fields,
    )

WASTE_TYPES = [
    {
        "name": "Garbage",
        "icon": "🗑️",
    },
    {
        "name": "Recycling",
        "icon": "♻️",
    },
    {
        "name": "Yard Waste",
        "icon": "🌳",
    },
    {
        "name": "Bulk Waste",
        "icon": "🚛",
    },
]

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
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

        if config.bool(key):
            pickups.append(get_label_for_waste_type(waste_type, icons_only))

    return pickups

def get_local_noon_anchor(now):
    return now + time.parse_duration("{}h".format(12 - now.hour))

def find_next_pickup(config, today_anchor, icons_only):
    for offset in range(2, 8):
        candidate = today_anchor + time.parse_duration("{}h".format(offset * 24))
        candidate_day = humanize.day_of_week(candidate)
        candidate_pickups = get_pickups_for_day(config, candidate_day, icons_only)

        if len(candidate_pickups) > 0:
            return {
                "time": candidate,
                "pickups": candidate_pickups,
            }

    return None

def main(config):
    timezone = time.tz()
    now = time.now().in_location(timezone)

    icons_only = config.bool("icons_only")
    empty_behavior = config.get("empty_behavior", "skip")

    today_day = humanize.day_of_week(now)

    one_day = time.parse_duration("24h")
    today_anchor = get_local_noon_anchor(now)
    tomorrow = today_anchor + one_day
    tomorrow_day = humanize.day_of_week(tomorrow)

    pickups_today = get_pickups_for_day(config, today_day, icons_only)
    pickups_tomorrow = get_pickups_for_day(config, tomorrow_day, icons_only)

    show_next_pickup = len(pickups_today) == 0 and len(pickups_tomorrow) == 0
    next_pickup = None

    if show_next_pickup:
        if empty_behavior == "skip":
            return []

        next_pickup = find_next_pickup(config, today_anchor, icons_only)

        if next_pickup == None:
            return []

    if canvas.is2x():
        connector = "  "
    elif icons_only:
        connector = " "
    else:
        connector = ", "

    row1 = connector.join(pickups_today) if len(pickups_today) > 0 else ""

    if show_next_pickup and next_pickup != None:
        row2 = connector.join(next_pickup["pickups"])
        second_date = next_pickup["time"].day
    else:
        row2 = connector.join(pickups_tomorrow) if len(pickups_tomorrow) > 0 else ""
        second_date = tomorrow.day

    screen_height = canvas.height()
    screen_width = canvas.width()

    if canvas.is2x():
        date_font = "terminus-18"
        pickup_font = "6x13"
        calendar_date_offset = 6
        text_vertical_offset = 3
    else:
        date_font = "5x8"
        pickup_font = "5x8"
        calendar_date_offset = 4
        text_vertical_offset = 2

    calendar_box_size = int(screen_height / 2) - 2
    scroll_speed = int(config.get("scroll", 45))
    delay = scroll_speed // 2 if canvas.is2x() else scroll_speed

    return render.Root(
        render.Stack(
            children = [
                add_padding_to_child_element(
                    render.Box(
                        color = "#ffffff",
                        width = calendar_box_size,
                        height = calendar_box_size,
                    ),
                    1,
                    1,
                ),
                add_padding_to_child_element(
                    render.Box(
                        color = "#ffffff",
                        width = calendar_box_size,
                        height = calendar_box_size,
                    ),
                    1,
                    int(screen_height / 2) + 1,
                ),
                add_padding_to_child_element(
                    render.Box(
                        color = "#ff0000",
                        width = calendar_box_size,
                        height = int(calendar_box_size / 3),
                    ),
                    1,
                    1,
                ),
                add_padding_to_child_element(
                    render.Box(
                        color = "#ff0000",
                        width = calendar_box_size,
                        height = int(calendar_box_size / 3),
                    ),
                    1,
                    int(screen_height / 2) + 1,
                ),
                add_padding_to_child_element(
                    render.Text(
                        "{}{}".format("0" if now.day < 10 else "", str(now.day)),
                        color = "#000000",
                        font = date_font,
                    ),
                    calendar_date_offset,
                    int(calendar_box_size / 3) + 2,
                ),
                add_padding_to_child_element(
                    render.Text(
                        "{}{}".format("0" if second_date < 10 else "", str(second_date)),
                        color = "#000000",
                        font = date_font,
                    ),
                    calendar_date_offset,
                    calendar_box_size + int(calendar_box_size / 3) + 4,
                ),
                add_padding_to_child_element(
                    render.Marquee(
                        width = screen_width - calendar_box_size,
                        child = render.Text(
                            row1,
                            font = pickup_font,
                        ),
                    ),
                    calendar_box_size + 2,
                    text_vertical_offset,
                ),
                add_padding_to_child_element(
                    render.Marquee(
                        width = screen_width - calendar_box_size,
                        child = render.Text(
                            row2,
                            font = pickup_font,
                        ),
                    ),
                    calendar_box_size + 2,
                    int(screen_height / 2) + text_vertical_offset,
                ),
            ],
        ),
        delay = delay,
        show_full_animation = True,
    )
