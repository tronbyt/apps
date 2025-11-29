"""
Applet: Gradient Clock
Summary: Animated Gradient Clock
Description: Clock displayed over animated, colorful gradient background.
Author: tpatel12
"""

load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

num_rows = 16
num_cols = 32
mapping = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]

def hex_map(r, g, b, a = 15):
    if r < 0:
        r = 0
    if r > 15:
        r = 15
    if g < 0:
        g = 0
    if g > 15:
        g = 15
    if b < 0:
        b = 0
    if b > 15:
        b = 15

    r = int(r)
    g = int(g)
    b = int(b)

    if a != None:
        a = max(0, min(15, int(a)))

    return mapping[r] + mapping[g] + mapping[b] + mapping[a]

def render_overlay(now, show_date, scale, use_24h, blinking_separator, frame_num):
    if scale == 2:
        time_font = "terminus-32"
        date_font = "terminus-24"
        time_box_height = 32
        date_box_height = 24
    else:
        time_font = "10x20"
        date_font = "6x13"
        time_box_height = 20
        date_box_height = 13

    time_format = ("15" if use_24h else "3") + ":04"
    if blinking_separator and frame_num % 20 < 10:
        time_format = time_format.replace(":", " ")

    time_child = render.Box(
        height = time_box_height,
        child = render.Text(
            content = now.format(time_format),
            font = time_font,
            color = "#FFFFFF",
        ),
    )

    children = [time_child]

    if show_date:
        children.append(
            render.Box(
                height = date_box_height,
                child = render.Text(
                    content = now.format("2 Jan"),
                    font = date_font,
                    color = "#FFFFFF",
                ),
            ),
        )

    return render.Column(
        expanded = True,
        main_align = "center",
        cross_align = "center",
        children = children,
    )

def get_rectangle(row, col, frame_num, box_size):
    frame_num *= 2
    period = 125
    if frame_num < period:
        alpha = frame_num - row - col

    elif frame_num < period * 2:
        alpha = 200 - (frame_num + row - col)

    elif frame_num < period * 3:
        alpha = -2 * period + frame_num - (num_rows - row) - (num_cols - col)

    else:
        alpha = 2 * period + 200 - (frame_num + (num_rows - row) - (num_rows - col))

    if (row + col) % 2 == 0:
        return render.Box(width = box_size, height = box_size, color = hex_map(15 - row - 1, row - 1, col - 1, alpha))
    else:
        return render.Box(width = box_size, height = box_size, color = hex_map(15 - row - 4, row - 4, col - 4, alpha))

def render_grid(frame_num, box_size):
    rows = []
    for grid_row in range(num_rows):
        rows.append(render.Row([get_rectangle(grid_row, grid_col, frame_num, box_size) for grid_col in range(num_cols)]))

    return render.Column(rows)

def render_frame(frame_num, now, show_date, scale, box_size, use_24h, blinking_separator):
    return render.Stack(children = [
        render_grid(frame_num, box_size),
        render_overlay(now, show_date, scale, use_24h, blinking_separator, frame_num),
    ])

def main(config):
    timezone = time.tz()
    now = time.now().in_location(timezone)
    show_date = config.bool("show_date", False)
    use_24h = config.bool("use_24h", True)
    blinking_separator = config.bool("blinking_separator", True)

    is_2x = canvas.is2x()
    scale = 2 if is_2x else 1
    box_size = 4 if is_2x else 2

    NUM_FRAMES = 250
    frames = [render_frame(i, now, show_date, scale, box_size, use_24h, blinking_separator) for i in range(NUM_FRAMES)]

    return render.Root(
        delay = 60,
        child = render.Animation(frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "show_date",
                name = "Show Date",
                desc = "Display the date below the time.",
                icon = "calendar",
                default = False,
            ),
            schema.Toggle(
                id = "use_24h",
                name = "24-hour Format",
                desc = "Display time in 24-hour format.",
                icon = "clock",
                default = True,
            ),
            schema.Toggle(
                id = "blinking_separator",
                name = "Blinking Separator",
                desc = "The separator between hours and minutes blinks.",
                icon = "toggleOn",
                default = True,
            ),
        ],
    )
