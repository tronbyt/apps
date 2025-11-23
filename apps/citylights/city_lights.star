"""
Applet: City Lights
Summary: Nighttime cityscape
Description: City Lights generates a random and mesmorizing nighttime cityscape.
Author: Nicholas Arent
"""

load("random.star", "random")
load("render.star", "render")
load("time.star", "time")

# Constants
HEIGHT = 32
WIDTH = 64
BUILDINGS = 8
BUILDING_MAX_W = 8
BUILDING_MIN_W = 2
BUILDING_MAX_H = 18
BUILDING_MIN_H = 6
WINDOW_COLOR_ON = "#E8E337"
WINDOW_COLOR_OFF = "#222222"
LIGHT_COLOR_ON = "#FF0000"
LIGHT_COLOR_OFF = "#420000ff"
STAR_COLOR = "#DDDDDD"
BACKGROUND_COLOR = "#000000"
BORDER_COLOR = "#000001"

# 0-x, 1-y, 2-height, 3-width, 4-windows, 5-tallest
BUILDING_X, BUILDING_Y, BUILDING_H, BUILDING_W, BUILDING_WINDOWS, IS_TALLEST = range(6)

# Animation Properties
DELAY = 200  # Delay between frames in milliseconds
DURATION_SECONDS = 15  # Total animation duration in seconds
NUM_FRAMES = DURATION_SECONDS * 1000 // DELAY  # Number of frames in the animation

tallestBuilding = 0

def gen_buildings(frame):
    buildings = [[0, 0, 0, 0, 0, 0, 0] for _ in range(BUILDINGS)]
    tallestBuildingHeight = 0
    tallestBuilding = 0

    for b in range(BUILDINGS):
        buildings[b][BUILDING_X] = b * 8
        buildings[b][BUILDING_Y] = 31
        buildings[b][BUILDING_H] = random.number(BUILDING_MIN_H, BUILDING_MAX_H)
        buildings[b][BUILDING_W] = random.number(BUILDING_MIN_W, BUILDING_MAX_W)
        buildings[b][BUILDING_WINDOWS] = buildings[b][BUILDING_W] * buildings[b][BUILDING_H]
        buildings[b][IS_TALLEST] = False

        frame = set_windows_off(buildings[b], frame)

        if tallestBuildingHeight <= buildings[b][BUILDING_H]:
            tallestBuilding = b
            tallestBuildingHeight = buildings[b][BUILDING_H]

    frame = set_tallest_building(buildings[tallestBuilding], frame)

    return buildings, frame

def set_windows_off(building, frame):
    for y in range(building[BUILDING_H]):
        for x in range(building[BUILDING_W]):
            window_x = building[BUILDING_X] + x
            window_y = building[BUILDING_Y] - y
            frame[window_y][window_x] = WINDOW_COLOR_OFF
    return frame

def set_tallest_building(building, frame):
    building[IS_TALLEST] = True

    if building[BUILDING_W] % 2 == 0:
        building[BUILDING_W] = building[BUILDING_W] + 1
        for y in range(building[BUILDING_H]):
            window_y = building[BUILDING_Y] - y
            window_x = building[BUILDING_X] + building[BUILDING_W] - 1
            if window_x > 63:
                window_x = 63
            frame[window_y][window_x] = WINDOW_COLOR_OFF

    light_x = building[BUILDING_X] + (building[BUILDING_W] // 2)
    light_y = building[BUILDING_Y] - building[BUILDING_H]
    frame[light_y][light_x] = LIGHT_COLOR_OFF

    return frame

def stars(frame):
    for _ in range(random.number(3, 5)):
        star_x = random.number(0, 63)
        star_y = random.number(0, 23)

        if not_star_collision(frame, star_y, star_x):
            frame[star_y][star_x] = STAR_COLOR
    return frame

def not_star_collision(frame, star_y, star_x):
    no_collision = not_color_collision(frame[star_y][star_x]) and not_color_collision(frame[star_y + 1][star_x])

    if star_x - 1 >= 0:
        no_collision = no_collision and not_color_collision(frame[star_y][star_x - 1])

    if star_x + 1 < 64:
        no_collision = no_collision and not_color_collision(frame[star_y][star_x + 1])

    return no_collision

def not_color_collision(f):
    return (f != WINDOW_COLOR_ON) and (f != WINDOW_COLOR_OFF) and (f != LIGHT_COLOR_ON) and (f != LIGHT_COLOR_OFF)

def update_view(frame, buildings, light_counter):
    for b in range(BUILDINGS):
        window = random.number(0, buildings[b][BUILDING_WINDOWS] - 1)
        window_row = window // buildings[b][BUILDING_W]
        window_col = window - (window_row * buildings[b][BUILDING_W])
        window_x = buildings[b][BUILDING_X] + window_col
        window_y = buildings[b][BUILDING_Y] - window_row
        if window_x > 63:
            window_x = 63
        frame[window_y][window_x] = WINDOW_COLOR_ON
        if (buildings[b][IS_TALLEST] == True) and (light_counter % 6 == 0):
            frame = update_tallest(buildings[b], frame)

    return frame

def update_tallest(building, frame):
    light_x = building[BUILDING_X] + (building[BUILDING_W] // 2)
    light_y = building[BUILDING_Y] - building[BUILDING_H]
    if frame[light_y][light_x] == LIGHT_COLOR_ON:
        frame[light_y][light_x] = LIGHT_COLOR_OFF
    else:
        frame[light_y][light_x] = LIGHT_COLOR_ON

    return frame

def render_frame(frame):
    children = [render_column(frame)]
    return render.Stack(children = children)

def render_column(frame):
    rows = []
    for row in frame:
        rows.append(render_row(row))
    return render.Column(children = rows)

def render_row(row):
    cells = []
    for cell in row:
        cells.append(render_cell(cell))
    return render.Row(children = cells)

def render_cell(cell):
    return render.Box(width = 1, height = 1, color = cell)

def main():
    random.seed(time.now().unix)

    frames = []
    frame = [[BACKGROUND_COLOR for _ in range(WIDTH)] for _ in range(HEIGHT)]

    buildings = [[0, 0, 0, 0, 0, 0, 0] for _ in range(BUILDINGS)]
    buildings, frame = gen_buildings(frame)

    for counter in range(NUM_FRAMES):
        frame = stars(frame)
        frame = update_view(frame, buildings, counter)
        frames.append(render_frame(frame))

    return render.Root(
        delay = DELAY,
        show_full_animation = True,
        child = render.Animation(children = frames),
    )
