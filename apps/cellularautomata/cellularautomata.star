"""
Applet: CellularAutomata
Summary: Draws 1D cellular automata
Description: Draws the evolution of one-dimensional cellular automata.
Author: dinosaursrarr
"""

load("math.star", "math")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

ALIVE = True
DEAD = False
WIDTH = canvas.width()
HEIGHT = canvas.height()
REFRESH_MILLISECONDS = 200

# Every frame repaints every row grown so far, so a 64-row panel adds two
# rows per frame (at twice the delay, so the pace is unchanged) to keep the
# render inside the server deadline.
ROWS_PER_FRAME = max(1, HEIGHT // 32)
CHOOSE_RANDOM = "-"
SINGLE_CELL = "+"

WHITE = "#ffffff"
BLACK = "#000000"

def neighbours_to_binary(left, middle, right):
    res = 0
    res += int(left) << 2
    res += int(middle) << 1
    res += int(right)
    return res

def next_row(current_row, rule):
    new_row = []
    for i in range(len(current_row)):
        left = current_row[i - 1]
        middle = current_row[i]
        right = current_row[(i + 1) % len(current_row)]
        child = (rule >> neighbours_to_binary(left, middle, right)) & 1
        new_row.append(bool(child))
    return new_row

def render_row(row, alive_colour, dead_colour):
    # Consecutive cells in the same state are painted as one Box: pixel-
    # identical, and a fraction of the widgets per frame (every frame repaints
    # every row grown so far).
    boxes = []
    start = 0
    for i in range(1, len(row) + 1):
        if i == len(row) or row[i] != row[start]:
            boxes.append(render.Box(width = i - start, height = 1, color = alive_colour if row[start] else dead_colour))
            start = i
    return render.Row(children = boxes)

def render_grid(grid, alive_colour, dead_colour):
    return render.Column(children = [render_row(row, alive_colour, dead_colour) for row in grid])

def animate(alive_colour, dead_colour, rule, starting_row):
    frames = []

    first_row = [DEAD] * WIDTH
    if starting_row == SINGLE_CELL:
        first_row[math.ceil(WIDTH / 2)] = ALIVE
    elif starting_row == CHOOSE_RANDOM:
        for i in range(len(first_row)):
            if random.number(0, 1) > 0.5:
                first_row[i] = ALIVE

    grid = [first_row]
    frames.append(render_grid(grid, alive_colour, dead_colour))

    for i in range(HEIGHT):
        row = next_row(grid[-1], rule)
        grid.append(row)
        if (i + 1) % ROWS_PER_FRAME == 0 or i == HEIGHT - 1:
            frames.append(render_grid(grid, alive_colour, dead_colour))

    return render.Animation(children = frames)

def main(config):
    alive_colour = config.get("alive_colour")
    if not alive_colour:
        alive_colour = WHITE
    dead_colour = config.get("dead_colour")
    if not dead_colour:
        dead_colour = BLACK
    starting_row = config.get("starting_row")
    if not starting_row:
        starting_row = SINGLE_CELL

    # seed the RNG with a new value every 15 seconds to improve
    # cross-user caching.
    random.seed(time.now().unix // 15)
    rule_option = config.get("rule")
    if not rule_option or rule_option == CHOOSE_RANDOM:
        rule = random.number(0, 256)
    else:
        rule = int(rule_option)

    # Turns out to be significantly faster to re-use
    # a single element rather than create one for each
    # cell on each iteration.
    return render.Root(
        delay = REFRESH_MILLISECONDS * ROWS_PER_FRAME,
        child = render.Stack(
            children = [
                animate(alive_colour, dead_colour, rule, starting_row),
                render.Padding(
                    pad = (1, 1, 0, 0),
                    color = dead_colour,
                    child = render.Text(
                        content = "{}".format(rule),
                        color = alive_colour,
                        font = "tom-thumb",
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "alive_colour",
                name = "Alive colour",
                desc = "The colour to show for living cells",
                icon = "heartPulse",
                default = WHITE,
            ),
            schema.Color(
                id = "dead_colour",
                name = "Dead colour",
                desc = "The colour to show for dead cells",
                icon = "skullCrossbones",
                default = BLACK,
            ),
            schema.Dropdown(
                id = "rule",
                name = "Rule",
                desc = "Rule determining evolution of cells",
                icon = "dice",
                default = CHOOSE_RANDOM,
                options = [schema.Option(display = "Random", value = CHOOSE_RANDOM)] + [
                    schema.Option(display = str(i), value = str(i))
                    for i in range(256)
                ],
            ),
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
