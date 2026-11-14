"""
Applet: Countup Clock
Summary: Time since a event
Description: Display the days, hours, and minutes since a specified event.
Author: jvivona
borrowed Fade In and Out technique and the math calculations from @CubsAaron countdown_clock
"""

# 20231107 - jvivona - change fade code to new code & cleanup for loops
# 20240802 - jvivona - added in code to handle widget mode and remove animations

load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

VERSION = 24215

DEFAULT_TIMEZONE = "America/New_York"
TITLE_FONT = "5x8"
DAYS_FONT = "6x13"
HOURS_FONT = "tb-8"
HOURS_COLOR = "#888888"

WIDGET_MODE = False

# 2x (128x64) has the vertical room to wrap the title across more lines and show
# hours and minutes as their own static lines instead of the fading marquee.
IS2X = canvas.is2x()
TITLE_FONT_2X = "6x13"

# Keep the title to 2 lines. We greedily word-wrap it into at most two 21-char
# lines (6x13 is 6px wide, so 128px holds 21 chars) and render each as its own
# Text line - shrink-wrapped and vertically centered in its half with tight
# spacing (a fixed WrappedText height would top-align a single line instead).
# Longer titles get an ellipsis.
LINE_CHARS_2X = 21
DAYS_FONT_2X = "terminus-16"
HOURS_FONT_2X = "tb-8"
HOURS_COLOR_2X = "#AAAAAA"

coloropt = [
    schema.Option(
        display = "Red",
        value = "#FF0000",
    ),
    schema.Option(
        display = "Orange",
        value = "#FFA500",
    ),
    schema.Option(
        display = "Yellow",
        value = "#FFFF00",
    ),
    schema.Option(
        display = "Green",
        value = "#008000",
    ),
    schema.Option(
        display = "Blue",
        value = "#0000FF",
    ),
    schema.Option(
        display = "Indigo",
        value = "#4B0082",
    ),
    schema.Option(
        display = "Violet",
        value = "#EE82EE",
    ),
    schema.Option(
        display = "Pink",
        value = "#FC46AA",
    ),
]

def main(config):
    widgetMode = config.bool("$widget")
    return render.Root(
        delay = 100,
        show_full_animation = True,
        max_age = 120,
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = get_render_children(config, widgetMode),
        ),
    ) if not widgetMode else render.Root(
        max_age = 120,
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = get_render_children(config, widgetMode),
        ),
    )

def get_render_children(config, widgetMode):
    displayhours = config.bool("display_hours", True)
    displayminutes = config.bool("display_minutes", True) if displayhours else False
    titlebelow = config.bool("title_below", False)
    is2x = IS2X and not widgetMode
    current_time = time.now().in_location(time.tz())

    origin_time = time.parse_time(config.str("event_time", current_time.format("2006-01-02T15:04:05Z07:00")))
    datediff = current_time - origin_time

    # we are always going to display days - so we can calc in main - no horsepower lost
    days = math.floor(datediff.hours // 24)
    daystring = "{} {}".format(str(days), "Day" if days == 1 else "Days")

    if is2x:
        return get_2x_children(config, datediff, days, daystring, displayhours, displayminutes, titlebelow)

    render_children = []
    days_font = HOURS_FONT if (widgetMode and displayhours) else DAYS_FONT
    render_children.append(render.Text(content = daystring, font = days_font))

    if displayhours:
        render_children.append(get_hours_minutes(datediff, days, displayminutes, widgetMode))

    title_insert_index = len(render_children) if titlebelow else 0

    render_children.insert(title_insert_index, get_title(config.str("event", ""), config.str("event_color", coloropt[3].value), displayhours, widgetMode))

    return render_children

def title_lines_2x(text):
    # Greedy word-wrap into at most two 21-char lines; ellipsis if it overflows.
    lines = ["", ""]
    li = 0
    truncated = False
    for w in text.split():
        cand = w if lines[li] == "" else lines[li] + " " + w
        if len(cand) <= LINE_CHARS_2X:
            lines[li] = cand
        elif li == 0:
            li = 1
            lines[1] = w
        else:
            truncated = True
            break

    # guard against a single word wider than a line
    lines = [ln[:LINE_CHARS_2X] for ln in lines]
    if truncated:
        tail = lines[1]
        if len(tail) >= LINE_CHARS_2X:
            tail = tail[:LINE_CHARS_2X - 1]
        lines[1] = tail + "…"

    return [ln for ln in lines if ln != ""]

def get_2x_children(config, datediff, days, daystring, displayhours, displayminutes, titlebelow):
    # Split the 128x64 canvas into two equal 32px halves - the title in one and
    # the day/hour/minute counts in the other - each vertically centered in its
    # half (render.Box centers its child). The larger title is clamped to 2 lines.
    titlecolor = config.str("event_color", coloropt[3].value)
    title_box = render.Box(
        width = 128,
        height = 32,
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(content = line, font = TITLE_FONT_2X, color = titlecolor)
                for line in title_lines_2x(config.str("event", ""))
            ],
        ),
    )

    count_lines = [render.Text(content = daystring, font = DAYS_FONT_2X)]
    if displayhours:
        count_lines.extend(get_hours_minutes_2x(datediff, days, displayminutes))
    count_box = render.Box(
        width = 128,
        height = 32,
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = count_lines,
        ),
    )

    if titlebelow:
        return [count_box, title_box]
    return [title_box, count_box]

def get_title(eventtitle, titlecolor, displayhours, widgetMode):
    if displayhours and not widgetMode:
        # since we are displaying hours - title needs to be marquee - text less than width will center on screen
        return render.Marquee(
            child = render.Text(content = eventtitle, font = TITLE_FONT, color = titlecolor),
            width = 64,
            align = "center",
        )
    else:
        # we can't put in any more than 2 lines of 5x8 - so force widget to be only 2 lines high and hide rest
        textheight = 8 if len(eventtitle) < 14 else 16
        return render.WrappedText(
            content = eventtitle,
            color = titlecolor,
            align = "center",
            font = TITLE_FONT,
            width = 64,
            height = textheight,
        )

def get_hours_minutes(datediff, days, displayminutes, widgetMode):
    # at a minimum we are displaying hours. we already calculated days in the caller - so just pass it in
    # if we are showing both hours and minutes - we need to the fade in and out, otherwise just show hours static
    hours = math.floor(datediff.hours - days * 24)
    hours_text = "{} {}".format(str(hours), "Hour" if hours == 1 else "Hours")

    if displayminutes:
        minutes = math.floor(datediff.minutes - (days * 24 * 60 + hours * 60))
        if widgetMode:
            return render.Text("{} h   {} m".format(str(hours), str(minutes)), font = HOURS_FONT, color = "#FFFFFF")
        else:
            return render.Animation(
                children =
                    createfadelist(hours_text, 30) +
                    createfadelist("{} {}".format(str(minutes), "Minute" if minutes == 1 else "Minutes"), 30),
            )
    else:
        # just hours so put a single static line here
        return render.Row(
            children = [
                render.Text(hours_text, font = HOURS_FONT, color = HOURS_COLOR if not widgetMode else "#FFFFFF"),
            ],
            main_align = "center",
            expanded = True,
        )

def get_hours_minutes_2x(datediff, days, displayminutes):
    # 2x static lines: no fade animation - just stack hours (and minutes) below days
    hours = math.floor(datediff.hours - days * 24)
    lines = [
        render.Text(
            content = "{} {}".format(str(hours), "Hour" if hours == 1 else "Hours"),
            font = HOURS_FONT_2X,
            color = HOURS_COLOR_2X,
        ),
    ]
    if displayminutes:
        minutes = math.floor(datediff.minutes - (days * 24 * 60 + hours * 60))
        lines.append(render.Text(
            content = "{} {}".format(str(minutes), "Minute" if minutes == 1 else "Minutes"),
            font = HOURS_FONT_2X,
            color = HOURS_COLOR_2X,
        ))
    return lines

def createfadelist(text, cycles):
    alpha_values = ["00", "33", "66", "99", "CC", "FF"]
    cycle_list = []

    # this is a pure genius technique and is borrowed from @CubsAaron countdown_clock
    # need to ponder if there is a different way to do it if we want something other than grey
    # use alpha channel to fade in and out

    # go from none to full color
    for x in alpha_values:
        cycle_list.append(render.Text(text, font = HOURS_FONT, color = HOURS_COLOR + x))
    for x in range(cycles):
        cycle_list.append(render.Text(text, font = HOURS_FONT, color = HOURS_COLOR))

    # go from full color back to none
    for x in alpha_values[5:0]:
        cycle_list.append(render.Text(text, font = HOURS_FONT, color = HOURS_COLOR + x))

    return cycle_list

def show_minutes_option(display_hours):
    # need to do the string comparison here to make it consistent instead of converting to bool - its a whole thing
    if display_hours == "true":
        return [
            schema.Toggle(
                id = "display_minutes",
                name = "Display minutes",
                desc = "Display minutes in countup?",
                icon = "clock",
                default = False,
            ),
        ]
    else:
        return []

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "event",
                name = "Title",
                desc = "The title text to display.",
                icon = "heading",
            ),
            schema.Toggle(
                id = "title_below",
                name = "Title at bottom?",
                desc = "Display title below the elapsed time?",
                icon = "arrowsUpDown",
                default = False,
            ),
            schema.DateTime(
                id = "event_time",
                name = "Start Date",
                desc = "The start date and time of the event.",
                icon = "clock",
            ),
            schema.Dropdown(
                id = "event_color",
                name = "Text Color",
                desc = "The color of the title text.",
                icon = "brush",
                default = coloropt[3].value,
                options = coloropt,
            ),
            schema.Toggle(
                id = "display_hours",
                name = "Display hours",
                desc = "Display hours in countup?  If disabled, display minutes is also disabled.",
                icon = "clock",
                default = True,
            ),
            schema.Generated(
                id = "generated",
                source = "display_hours",
                handler = show_minutes_option,
            ),
        ],
    )
