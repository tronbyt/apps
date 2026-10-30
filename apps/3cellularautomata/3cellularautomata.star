"""
Applet: 3CellularAutomata
Summary: Draws 1D cellular automata
Description: Draws the evolution of one-dimensional, three-state cellular automata.
Author: dinosaursrarr
"""

load("math.star", "math")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

WIDTH = canvas.width()
HEIGHT = canvas.height()
REFRESH_MILLISECONDS = 200

# Every frame repaints every row grown so far, so a 64-row panel adds two
# rows per frame (at twice the delay, so the pace is unchanged) to keep the
# render inside the server deadline.
ROWS_PER_FRAME = max(1, HEIGHT // 32)
CHOOSE_RANDOM = "-"
SINGLE_CELL = "+"
STATES = 3

DEFAULT_COLOURS = [
    "#000000",
    "#ffffff",
    "#0000ff",
]

def neighbours_to_ternary(left, middle, right):
    return (left * STATES * STATES) + (middle * STATES) + right

def next_row(current_row, rule):
    new_row = []
    for i in range(len(current_row)):
        left = current_row[i - 1]
        middle = current_row[i]
        right = current_row[(i + 1) % len(current_row)]
        scenario = neighbours_to_ternary(left, middle, right)
        child = math.floor(rule / math.pow(STATES, scenario)) % STATES
        new_row.append(child)
    return new_row

def render_row(row, colours):
    # Consecutive cells in the same state are painted as one Box: pixel-
    # identical, and a fraction of the widgets per frame (every frame repaints
    # every row grown so far).
    boxes = []
    start = 0
    for i in range(1, len(row) + 1):
        if i == len(row) or row[i] != row[start]:
            boxes.append(render.Box(width = i - start, height = 1, color = colours[row[start]]))
            start = i
    return render.Row(children = boxes)

def render_grid(grid, colours):
    return render.Column(children = [render_row(row, colours) for row in grid])

def animate(colours, rule, starting_row):
    frames = []

    first_row = [0] * WIDTH
    if starting_row == SINGLE_CELL:
        first_row[math.ceil(WIDTH / 2)] = 1
    elif starting_row == CHOOSE_RANDOM:
        for i in range(len(first_row)):
            first_row[i] = math.floor(random.number(0, 1) / (1 / STATES))
            if first_row[i] == STATES:
                first_row[i] = STATES - 1

    grid = [first_row]
    frames.append(render_grid(grid, colours))

    for i in range(HEIGHT):
        row = next_row(grid[-1], rule)
        grid.append(row)
        if (i + 1) % ROWS_PER_FRAME == 0 or i == HEIGHT - 1:
            frames.append(render_grid(grid, colours))

    return render.Animation(children = frames)

def main(config):
    colours = []
    for s in range(STATES):
        colour = config.get("state_{}_colour".format(s))
        if not colour:
            colour = DEFAULT_COLOURS[s]
        colours.append(colour)

    starting_row = config.get("starting_row")
    if not starting_row:
        starting_row = SINGLE_CELL

    # seed the RNG with a new value every 15 seconds to improve
    # cross-user caching.
    random.seed(time.now().unix // 15)
    rule = random.number(0, int(math.pow(STATES, math.pow(STATES, 3))))
    print("Using rule {}".format(rule))

    return render.Root(
        delay = REFRESH_MILLISECONDS * ROWS_PER_FRAME,
        child = animate(colours, rule, starting_row),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "state_{}_colour".format(s),
                name = "State {} colour".format(s),
                desc = "The colour to show for cells in state {}".format(s),
                icon = "palette",
                default = DEFAULT_COLOURS[s],
            )
            for s in range(STATES)
        ] + [
            schema.Dropdown(
                id = "starting_row",
                name = "Starting row",
                desc = "Determine starting conditions",
                icon = "play",
                default = SINGLE_CELL,
                options = [
                    schema.Option(display = "Random", value = CHOOSE_RANDOM),
                    schema.Option(display = "Single cell", value = SINGLE_CELL),
                ],
            ),
        ],
    )
