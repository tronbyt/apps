"""
Applet: Snake
Summary: Snake game animation
Description: Shows random snake game animation.
Author: noahpodgurski
"""

load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

WHITE = "#ffffff"
BLACK = "#000000"
RED = "#ff0000"
GREEN = "#00ff00"
ORANGE = "#db8f00"

WIDTH = 64
HEIGHT = 32

# How many candidate cells to roll for a new egg before giving up.
EGG_PLACEMENT_TRIES = 16

def randomCell():
    return [random.number(2, WIDTH - 2), random.number(2, HEIGHT - 2)]

def newEgg(snake):
    # Don't hide the egg underneath the snake. Bounded retry: Starlark has no
    # while loop, and a long snake could in principle fill every candidate cell,
    # so after EGG_PLACEMENT_TRIES rolls we give up and accept the last one.
    egg = randomCell()
    for _ in range(EGG_PLACEMENT_TRIES - 1):
        if not collideTail(snake, egg):
            break
        egg = randomCell()
    return egg

white_pixel = render.Box(
    width = 1,
    height = 1,
    color = WHITE,
)
green_pixel = render.Box(
    width = 1,
    height = 1,
    color = GREEN,
)
background = render.Box(
    width = WIDTH,
    height = HEIGHT,
    color = BLACK,
)

def place_pixel(pos, pixel):
    return render.Padding(
        pad = (pos[0], pos[1], 0, 0),
        child = pixel,
    )

def render_frame(snake, egg):
    # Draw only the live cells on a black background instead of a full
    # WIDTH x HEIGHT grid of 1x1 boxes: ~2000 widgets per frame down to a
    # few dozen, which is what lets 300 frames render within the budget on
    # Pi-class servers. The egg is drawn last so it overdraws the head on
    # the catch frame, matching the old row-grid renderer.
    children = [background]
    for s in snake:
        children.append(place_pixel(s, white_pixel))
    children.append(place_pixel(egg, green_pixel))
    return render.Stack(children = children)

def collideTail(snake, pos):
    return pos in snake

def playSnake(STARTING_SIZE, GROWTH_RATE):
    frames = []

    # init snake
    snake = []
    snakeDirs = ["u", "r", "d", "l"]
    snakeDir = snakeDirs[0]  #u r d l
    SNAKE_INIT = [(WIDTH // 2) - STARTING_SIZE, HEIGHT // 2]
    for x in range(STARTING_SIZE):
        snake.append([SNAKE_INIT[0] + x, SNAKE_INIT[1]])

    # init egg
    egg = newEgg(snake)

    for _ in range(300):
        snakePos = snake[-1]
        lastPos = snake[-2]

        # move towards egg
        if snakeDir == "u" or snakeDir == "d":
            if egg[0] < snakePos[0]:
                snakeDir = "l"
            elif egg[0] > snakePos[0]:
                snakeDir = "r"
                # moving away at same col

            elif math.fabs(egg[1] - snakePos[1]) > math.fabs(egg[1] - lastPos[1]):
                snakeDir = "l"
        if snakeDir == "l" or snakeDir == "r":
            if egg[1] < snakePos[1]:
                snakeDir = "u"
            elif egg[1] > snakePos[1]:
                snakeDir = "d"
                # moving away at same row

            elif math.fabs(egg[0] - snakePos[0]) > math.fabs(egg[0] - lastPos[0]):
                snakeDir = "u"

        # do your best to dodge tail
        for _ in range(2):
            if snakeDir == "u":
                if collideTail(snake, [snakePos[0], snakePos[1] - 1]):
                    snakeDir = ["r", "d", "l"][random.number(0, 2)]
            if snakeDir == "r":
                if collideTail(snake, [snakePos[0] + 1, snakePos[1]]):
                    snakeDir = ["d", "l", "u"][random.number(0, 2)]
            if snakeDir == "d":
                if collideTail(snake, [snakePos[0], snakePos[1] + 1]):
                    snakeDir = ["l", "u", "r"][random.number(0, 2)]
            if snakeDir == "l":
                if collideTail(snake, [snakePos[0] - 1, snakePos[1]]):
                    snakeDir = ["u", "r", "d"][random.number(0, 2)]

        # render frame
        # This has to happen before the egg is consumed below. Otherwise the
        # frame in which the head lands on the egg is drawn with the *next*
        # egg already in place, so the egg always appears to teleport away one
        # step before the snake reaches it and the catch is never shown.
        frames.append(render_frame(snake, egg))

        # get egg
        if snakePos == egg:
            egg = newEgg(snake)
            for _ in range(GROWTH_RATE):
                tail = [0, 0]
                tail[0] = snake[-1][0]
                tail[1] = snake[-1][1]
                snake.insert(0, tail)

        # move snake towards egg
        tail = snake.pop(0)
        tail[0] = snakePos[0]
        tail[1] = snakePos[1]
        if snakeDir == "u":
            tail[1] = (tail[1] - 1) % HEIGHT
        elif snakeDir == "r":
            tail[0] = (tail[0] + 1) % WIDTH
        elif snakeDir == "d":
            tail[1] = (tail[1] + 1) % HEIGHT
        elif snakeDir == "l":
            tail[0] = (tail[0] - 1) % WIDTH
        snake.append(tail)

    return frames

def animate(STARTING_SIZE, GROWTH_RATE):
    frames = playSnake(STARTING_SIZE, GROWTH_RATE)

    return render.Animation(children = frames)

def main(config):
    STARTING_SIZE = 4
    GROWTH_RATE = 1

    if config.get("STARTING_SIZE"):
        STARTING_SIZE = int(config.get("STARTING_SIZE"))
    if config.get("GROWTH_RATE"):
        GROWTH_RATE = int(config.get("GROWTH_RATE"))
    return render.Root(
        child = render.Stack(
            children = [
                animate(STARTING_SIZE, GROWTH_RATE),
            ],
        ),
    )

startingSizeOptions = [
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
]

growthRateOptions = [
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
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "STARTING_SIZE",
                name = "Starting size",
                desc = "The starting size of the snake.",
                icon = "gear",
                default = startingSizeOptions[0].value,
                options = startingSizeOptions,
            ),
            schema.Dropdown(
                id = "GROWTH_RATE",
                name = "Growth rate",
                desc = "The rate at which the snake grows.",
                icon = "gear",
                default = growthRateOptions[0].value,
                options = growthRateOptions,
            ),
        ],
    )
