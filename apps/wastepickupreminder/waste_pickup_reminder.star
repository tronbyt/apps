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
        schema.Toggle(
            id = "hide_if_nothing_to_display",
            name = "Hide If Nothing To Display",
            desc = "Hide the calendar if nothing to display",
            icon = "eye",
            default = True,
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

    # Helper to add toggles for a waste type
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
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )

    return padded_element

def main(config):
    timezone = time.tz()
    now = time.now().in_location(timezone)
    today = int(humanize.day_of_week(now))

    one_day = time.parse_duration("24h")
    tomorrow = now.in_location(timezone) + one_day
    tomorrow_day = int(humanize.day_of_week(tomorrow))

    pickups_today = []
    pickups_tomorrow = []

    nothing_to_display = True

    icons_only = config.bool("icons_only")
    connector = " " if canvas.is2x() else "" if icons_only else ", "

    for i in range(len(WASTE_TYPES)):
        prefix = WASTE_TYPES[i]["name"].replace(" ", "_").lower()

        if icons_only:
            label = WASTE_TYPES[i]["icon"]
        else:
            label = WASTE_TYPES[i]["icon"] + " " + WASTE_TYPES[i]["name"]

        key = prefix + "_" + str(today)

        if config.bool(key):
            pickups_today.append(label)
            nothing_to_display = False

        key = prefix + "_" + str(tomorrow_day)

        if config.bool(key):
            pickups_tomorrow.append(label)
            nothing_to_display = False

    if nothing_to_display and config.bool("hide_if_nothing_to_display"):
        return None

    if len(pickups_today) == 0:
        row1 = ""
    else:
        row1 = connector.join(pickups_today)

    if len(pickups_tomorrow) == 0:
        row2 = ""
    else:
        row2 = connector.join(pickups_tomorrow)

    screen_height = canvas.height()
    screen_width = canvas.width()

    if canvas.is2x():
        font = "terminus-18"
        calendar_date_offset = 6
        text_verticle_offset = 6
    else:
        font = "5x8"
        calendar_date_offset = 4
        text_verticle_offset = 2

    calendar_box_size = int(screen_height / 2) - 2
    delay = int(config.get("scroll", 45)) // 2 if canvas.is2x() else int(config.get("scroll", 45))

    return render.Root(
        render.Stack(
            children = [
                add_padding_to_child_element(render.Box(color = "#ffffff", width = calendar_box_size, height = calendar_box_size), 1, 1),
                add_padding_to_child_element(render.Box(color = "#ffffff", width = calendar_box_size, height = calendar_box_size), 1, int(screen_height / 2) + 1),
                add_padding_to_child_element(render.Box(color = "#ff0000", width = calendar_box_size, height = int(calendar_box_size / 3)), 1, 1),
                add_padding_to_child_element(render.Box(color = "#ff0000", width = calendar_box_size, height = int(calendar_box_size / 3)), 1, int(screen_height / 2) + 1),
                add_padding_to_child_element(render.Text("{}{}".format("0" if now.day < 10 else "", str(now.day)), color = "#000000", font = font), calendar_date_offset, int(calendar_box_size / 3) + 2),
                add_padding_to_child_element(render.Text("{}{}".format("0" if tomorrow.day < 10 else "", str(tomorrow.day)), color = "#000000", font = font), calendar_date_offset, calendar_box_size + int(calendar_box_size / 3) + 4),
                add_padding_to_child_element(render.Marquee(width = screen_width - calendar_box_size, child = render.Text(row1, font = font)), calendar_box_size + 2, text_verticle_offset),
                add_padding_to_child_element(render.Marquee(width = screen_width - calendar_box_size, child = render.Text(row2, font = font)), calendar_box_size + 2, int(screen_height / 2) + text_verticle_offset),
            ],
        ),
        delay = delay,
        show_full_animation = True,
    )
