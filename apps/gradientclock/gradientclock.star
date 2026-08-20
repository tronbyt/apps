load("encoding/json.star", "json")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

APP_DURATION_MILLISECONDS = 1000
REFRESH_MILLISECONDS = 500

P_LOCATION = "location"

def main(config):
    location = config.get(P_LOCATION)
    location = json.decode(location) if location else {}

    timezone = location.get(
        "timezone",
        time.tz(),
    )
    now = config.get("time")

    now = (time.parse_time(now) if now else time.now()).in_location(timezone)
    now_date = now.format("2 Jan")
    use_12h = config.bool("use_12h", False)

    t = (now - time.time(year = 2000)) / time.second
    mults = [15436, 37531, 108444, 48954, 97676, 324345, 27841, 29841, 33564, 47474, 83562, 91919]
    rates = []
    for x in range(0, 9):
        rates.append(math.sin(t / mults[x]) * 8)
    for x in range(9, 12):
        rates.append(math.sin(t / mults[x]) * 1000)

    board = []
    for _ in range(canvas.height()):
        board.append(["#ff0000"] * canvas.width())
    frames = []

    scale = 2 if canvas.is2x() else 1
    time_font = "terminus-32" if scale == 2 else "terminus-18"
    date_font = "terminus-24" if scale == 2 else "6x13"
    time_box_height = 32 if scale == 2 else 18
    date_box_height = 24 if scale == 2 else 13

    for y in range(canvas.height()):
        for x in range(canvas.width()):
            board[y][x] = get_hex(rates[9] + rates[0] * x + rates[1] * y, rates[10] + rates[3] * x + rates[4] * y, rates[11] + rates[6] * x + rates[7] * y)
    for i in range(0, APP_DURATION_MILLISECONDS, REFRESH_MILLISECONDS):
        text_column = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children =
                [
                    render.Box(
                        height = time_box_height,
                        child = render.Row(
                            main_align = "center",
                            cross_align = "center",
                            children = [
                                render.Text(
                                    content = now.format("3" if use_12h else "15"),
                                    font = time_font,
                                    color = "#000000",
                                ),
                                render.Padding(
                                    pad = (-2 * scale, 0, -2 * scale, 0),  # Adjust horizontal padding
                                    child = render.Text(
                                        content = ":" if i % 1000 < 500 else " ",
                                        font = time_font,
                                        color = "#000000",
                                    ),
                                ),
                                render.Text(
                                    content = now.format("04"),
                                    font = time_font,
                                    color = "#000000",
                                ),
                            ],
                        ),
                    ),
                    render.Box(
                        height = date_box_height,
                        child = render.Text(
                            content = now_date,
                            color = "#000000",
                            font = date_font,
                        ),
                    ),
                ],
        )

        frames.append(render.Stack(children = [render_frame(board), text_column]))
    return render.Root(render.Animation(children = frames), delay = REFRESH_MILLISECONDS)

def render_frame(board, text = None):
    """
    Renders a frame for a given board. Use this in an animation to display each round.
    """
    children = [
        render.Column(
            children = [render_row(row) for row in board],
        ),
    ]

    if text:
        children.append(
            render.Box(
                child = render.Text(
                    content = text,
                    font = "6x13",
                    color = "#000000",
                ),
                width = canvas.width(),
                height = canvas.height(),
            ),
        )
    return render.Stack(
        children = children,
    )

def render_row(row):
    """
    Helper to render a row.
    """
    return render.Row(children = [render_cell(cell) for cell in row])

def render_cell(cell):
    """
    Helper to render a cell.
    """
    return render.Box(width = 1, height = 1, color = cell)

def pad_0(num):
    return ("0" + str(num))[-2:]

m = 101
pim = m * 2 * math.pi
save_rate = 2

def get_rgb_val(x):
    #    if int(x%pim * save_rate) in rgb_vals:
    #      return rgb_vals[int(x%pim * save_rate)]
    out = pad_0("%X" % int(boomerang(x) * 0xFF))

    #  rgb_vals[int(x%pim * save_rate)] = out
    return out

def boomerang(x):
    return math.sin(x / m) / 4 + 0.75

#    y = x % (2*m) / m

#   return min(y, 2-y)

def get_hex(r, g, b):
    return "#" + get_rgb_val(r) + get_rgb_val(g) + get_rgb_val(b)

def cmap(x):
    return "#" + get_rgb_val(x * 2.) + get_rgb_val(x * 3.) + get_rgb_val(x * 5.)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "use_12h",
                name = "12-hour Format",
                desc = "Display time in 12-hour format.",
                icon = "clock",
                default = False,
            ),
        ],
    )
