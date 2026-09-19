"""
Applet: Bday Countdown
Summary: Create a bday countdown
Description: Create a bday countdown!
Author: Jared Brockmyre
"""

load("humanize.star", "humanize")
load("i18n.star", "tr")
load("images/cake_frame1.png", CAKE_FRAME1 = "file")
load("images/cake_frame1@2x.png", CAKE_FRAME1_2X = "file")
load("images/cake_frame2.png", CAKE_FRAME2 = "file")
load("images/cake_frame2@2x.png", CAKE_FRAME2_2X = "file")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

def main(config):
    timezone = time.tz()
    now = time.now().in_location(timezone)
    birth_month = int(config.get("birthMonth", "1"), 10)
    birth_day = int(config.get("birthDay", "1"), 10)
    bday = time.time(year = now.year, month = birth_month, day = birth_day, location = timezone)
    name = config.str("name")
    days_until = bday - now
    days = math.ceil(days_until.hours / 24)

    if days < 0:
        bday = time.time(year = now.year + 1, month = birth_month, day = birth_day, location = timezone)
        days_until = bday - now
        days = math.ceil(days_until.hours / 24)

    scale = 2 if canvas.is2x() else 1
    if scale == 2:
        text_font = "terminus-14-light"
    else:
        text_font = "tom-thumb"

    c = config.get("nameColor", "#0000ff")

    if days == 0:
        row1Text = tr("Happy")
        row2Text = tr("Birthday")
        row3Text = name + "!" if name else ""
        row4Text = ""
    else:
        row1Text = humanize.plural(days, tr("day"), tr("days"))
        row2Text = tr("until")
        row3Text = name + tr("'s") if name else tr("Your")
        row4Text = tr("birthday")

    textRows = [
        render.Text(content = row1Text, font = text_font),
        render.Text(content = row2Text, font = text_font),
        render.Text(content = row3Text, font = text_font, color = c),
        render.Text(content = row4Text, font = text_font),
    ]

    displayChildren = [
        render.Row(
            children = [
                render.Image(src = (CAKE_FRAME1_2X if scale == 2 else CAKE_FRAME1).readall(), width = 24 * scale, height = 24 * scale),
                render.Box(
                    width = canvas.width() - 24 * scale,
                    height = canvas.height(),
                    child = render.Column(
                        cross_align = "center",
                        main_align = "center",
                        children = textRows,
                    ),
                ),
            ],
        ),
        render.Row(
            children = [
                render.Image(src = (CAKE_FRAME2_2X if scale == 2 else CAKE_FRAME2).readall(), width = 24 * scale, height = 24 * scale),
                render.Box(
                    width = canvas.width() - 24 * scale,
                    height = canvas.height(),
                    child = render.Column(
                        cross_align = "center",
                        main_align = "center",
                        children = textRows,
                    ),
                ),
            ],
        ),
    ]

    return render.Root(
        delay = 800,
        child = render.Animation(children = displayChildren),
    )

def get_schema():
    dayOptions = [
        schema.Option(
            display = "1",
            value = "1",
        ),
        schema.Option(
            display = "2",
            value = "2",
        ),
        schema.Option(
            display = "3",
            value = "3",
        ),
        schema.Option(
            display = "4",
            value = "4",
        ),
        schema.Option(
            display = "5",
            value = "5",
        ),
        schema.Option(
            display = "6",
            value = "6",
        ),
        schema.Option(
            display = "7",
            value = "7",
        ),
        schema.Option(
            display = "8",
            value = "8",
        ),
        schema.Option(
            display = "9",
            value = "9",
        ),
        schema.Option(
            display = "10",
            value = "10",
        ),
        schema.Option(
            display = "11",
            value = "11",
        ),
        schema.Option(
            display = "12",
            value = "12",
        ),
        schema.Option(
            display = "13",
            value = "13",
        ),
        schema.Option(
            display = "14",
            value = "14",
        ),
        schema.Option(
            display = "15",
            value = "15",
        ),
        schema.Option(
            display = "16",
            value = "16",
        ),
        schema.Option(
            display = "17",
            value = "17",
        ),
        schema.Option(
            display = "18",
            value = "18",
        ),
        schema.Option(
            display = "19",
            value = "19",
        ),
        schema.Option(
            display = "20",
            value = "20",
        ),
        schema.Option(
            display = "21",
            value = "21",
        ),
        schema.Option(
            display = "22",
            value = "22",
        ),
        schema.Option(
            display = "23",
            value = "23",
        ),
        schema.Option(
            display = "24",
            value = "24",
        ),
        schema.Option(
            display = "25",
            value = "25",
        ),
        schema.Option(
            display = "26",
            value = "26",
        ),
        schema.Option(
            display = "27",
            value = "27",
        ),
        schema.Option(
            display = "28",
            value = "28",
        ),
        schema.Option(
            display = "29",
            value = "29",
        ),
        schema.Option(
            display = "30",
            value = "30",
        ),
        schema.Option(
            display = "31",
            value = "31",
        ),
    ]
    monthOptions = [
        schema.Option(
            display = "1",
            value = "1",
        ),
        schema.Option(
            display = "2",
            value = "2",
        ),
        schema.Option(
            display = "3",
            value = "3",
        ),
        schema.Option(
            display = "4",
            value = "4",
        ),
        schema.Option(
            display = "5",
            value = "5",
        ),
        schema.Option(
            display = "6",
            value = "6",
        ),
        schema.Option(
            display = "7",
            value = "7",
        ),
        schema.Option(
            display = "8",
            value = "8",
        ),
        schema.Option(
            display = "9",
            value = "9",
        ),
        schema.Option(
            display = "10",
            value = "10",
        ),
        schema.Option(
            display = "11",
            value = "11",
        ),
        schema.Option(
            display = "12",
            value = "12",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "name",
                name = "Birthday Person's Name",
                desc = "Birthday Person's Name (Max 9 characters)",
                icon = "gear",
                default = "",
            ),
            schema.Color(
                id = "nameColor",
                name = "Name Color",
                desc = "Color of the name.",
                icon = "brush",
                default = "#0000FF",
            ),
            schema.Dropdown(
                id = "birthDay",
                name = "Birth day",
                desc = "The birth day.",
                icon = "gear",
                default = dayOptions[0].value,
                options = dayOptions,
            ),
            schema.Dropdown(
                id = "birthMonth",
                name = "Birth month",
                desc = "The birth month.",
                icon = "gear",
                default = monthOptions[0].value,
                options = monthOptions,
            ),
        ],
    )
