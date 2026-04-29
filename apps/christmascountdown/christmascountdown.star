"""
Applet: Christmas Countdown
Summary: Christmas Countdown
Description: Displays an animated tree and Merry Christmas and (optionally) the number of days until Dec. 25.
Author: Michael Creamer
"""

load("humanize.star", "humanize")
load("i18n.star", "tr")
load("images/christmastree.png", CHRISTMASTree = "file")
load("images/christmastree1.png", CHRISTMASTree1 = "file")
load("images/christmastree2.png", CHRISTMASTree2 = "file")
load("images/christmastree3.png", CHRISTMASTree3 = "file")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

def main(config):
    #-----------------------
    # Get Configured Values
    #-----------------------
    line1Text = tr("Merry")
    line2Text = tr("Christmas")
    line1Color = config.get("line1Color", "#ff0000")
    line2Color = config.get("line2Color", "#00ff00")
    showCountdown = config.bool("showCountdown", True)
    maxCountdownValue = config.get("maxCountdownValue", 365)

    if maxCountdownValue == None or maxCountdownValue == "":
        maxCountdownValue = 365

    #--------------------------------
    # Calculate days until Christmas
    #--------------------------------
    timezone = time.tz()
    now = time.now().in_location(timezone)
    today = time.time(year = now.year, month = now.month, day = now.day, location = timezone)
    current_xmas = time.time(year = today.year, month = 12, day = 25, location = timezone)

    if today > current_xmas:
        current_xmas = time.time(year = today.year + 1, month = 12, day = 25, location = timezone)

    date_diff = current_xmas - now
    days = math.ceil(date_diff.hours / 24)

    #---------------------------
    # Setup array of text lines
    #---------------------------
    scale = 2 if canvas.is2x() else 1
    font = "terminus-12" if canvas.is2x() else "tom-thumb"
    image_width = 27
    image_height = 32

    text_col_padding = (image_width * scale, 0, 0, 0)

    # If text is long, let it overlap the tree a bit
    max_text_len = max(len(line1Text), len(line2Text))
    if max_text_len > 9:
        text_col_padding = (image_width * scale - 7 * scale, 0, 0, 0)

    displayChildren = [
        render.Text(content = line1Text, font = font, color = line1Color),
        render.Text(content = line2Text, font = font, color = line2Color),
    ]
    if showCountdown and days > 0:
        line3Color = config.get("line3Color", "#0000ff")
        line3Text = humanize.plural(days, tr("day"), tr("days"))
        child = render.Padding(
            child = render.Text(content = line3Text, font = font, color = line3Color),
            pad = (0, 3 * scale, 0, 0),
        )
        displayChildren.append(child)

    #---------
    # Prepare
    #---------
    displayChildren = [
        render.Stack(
            children = [
                render.Image(src = CHRISTMASTree.readall(), width = image_width * scale, height = image_height * scale),
                render.Padding(
                    pad = text_col_padding,
                    child = render.Column(
                        cross_align = "center",
                        main_align = "center",
                        expanded = True,
                        children = displayChildren,
                    ),
                ),
            ],
        ),
        render.Stack(
            children = [
                render.Image(src = CHRISTMASTree1.readall(), width = image_width * scale, height = image_height * scale),
                render.Padding(
                    pad = text_col_padding,
                    child = render.Column(
                        cross_align = "center",
                        main_align = "center",
                        expanded = True,
                        children = displayChildren,
                    ),
                ),
            ],
        ),
        render.Stack(
            children = [
                render.Image(src = CHRISTMASTree2.readall(), width = image_width * scale, height = image_height * scale),
                render.Padding(
                    pad = text_col_padding,
                    child = render.Column(
                        cross_align = "center",
                        main_align = "center",
                        expanded = True,
                        children = displayChildren,
                    ),
                ),
            ],
        ),
        render.Stack(
            children = [
                render.Image(src = CHRISTMASTree3.readall(), width = image_width * scale, height = image_height * scale),
                render.Padding(
                    pad = text_col_padding,
                    child = render.Column(
                        cross_align = "center",
                        main_align = "center",
                        expanded = True,
                        children = displayChildren,
                    ),
                ),
            ],
        ),
    ]

    if days > int(maxCountdownValue):
        return []

    #--------
    # Render
    #--------
    return render.Root(
        delay = 4000,
        child = render.Animation(children = displayChildren),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "line1Color",
                name = "Line 1 Color",
                desc = "Line 1 Color",
                icon = "brush",
                default = "#FF0000",
            ),
            schema.Color(
                id = "line2Color",
                name = "Line 2 Color",
                desc = "Line 2 Color",
                icon = "brush",
                default = "#00FF00",
            ),
            schema.Color(
                id = "line3Color",
                name = "Line 3 Color",
                desc = "Line 3 Color",
                icon = "brush",
                default = "#0000FF",
            ),
            schema.Toggle(
                id = "showCountdown",
                name = "Show Remaining Count",
                desc = "Show Remaining Count",
                icon = "gear",
                default = True,
            ),
            schema.Text(
                id = "maxCountdownValue",
                name = "Max Remaining Value",
                desc = "Max Remaining Value",
                icon = "gear",
                default = "365",
            ),
        ],
    )
