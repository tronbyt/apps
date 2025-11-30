"""
Applet: Arcade Classics
Summary: Classic arcade animations
Description: Animations from classic arcade video games.
Author: Steve Otteson
"""

load("images/alien1_a.png", ALIEN1_A_ASSET = "file")
load("images/alien1_b.png", ALIEN1_B_ASSET = "file")
load("images/alien2_a.png", ALIEN2_A_ASSET = "file")
load("images/alien2_b.png", ALIEN2_B_ASSET = "file")
load("images/alien3_a.png", ALIEN3_A_ASSET = "file")
load("images/alien3_b.png", ALIEN3_B_ASSET = "file")
load("images/blue_1.png", BLUE_1_ASSET = "file")
load("images/blue_2.png", BLUE_2_ASSET = "file")
load("images/cyan_l1.png", CYAN_L1_ASSET = "file")
load("images/cyan_l2.png", CYAN_L2_ASSET = "file")
load("images/cyan_r1.png", CYAN_R1_ASSET = "file")
load("images/cyan_r2.png", CYAN_R2_ASSET = "file")
load("images/mspm_l1.png", MSPM_L1_ASSET = "file")
load("images/mspm_l2.png", MSPM_L2_ASSET = "file")
load("images/mspm_l3.png", MSPM_L3_ASSET = "file")
load("images/mspm_r1.png", MSPM_R1_ASSET = "file")
load("images/mspm_r2.png", MSPM_R2_ASSET = "file")
load("images/mspm_r3.png", MSPM_R3_ASSET = "file")
load("images/peach_l1.png", PEACH_L1_ASSET = "file")
load("images/peach_l2.png", PEACH_L2_ASSET = "file")
load("images/peach_r1.png", PEACH_R1_ASSET = "file")
load("images/peach_r2.png", PEACH_R2_ASSET = "file")
load("images/pink_l1.png", PINK_L1_ASSET = "file")
load("images/pink_l2.png", PINK_L2_ASSET = "file")
load("images/pink_r1.png", PINK_R1_ASSET = "file")
load("images/pink_r2.png", PINK_R2_ASSET = "file")
load("images/pm_1.png", PM_1_ASSET = "file")
load("images/pm_l1.png", PM_L1_ASSET = "file")
load("images/pm_l2.png", PM_L2_ASSET = "file")
load("images/pm_r1.png", PM_R1_ASSET = "file")
load("images/pm_r2.png", PM_R2_ASSET = "file")
load("images/red_l1.png", RED_L1_ASSET = "file")
load("images/red_l2.png", RED_L2_ASSET = "file")
load("images/red_r1.png", RED_R1_ASSET = "file")
load("images/red_r2.png", RED_R2_ASSET = "file")
load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

ALIEN1_A = ALIEN1_A_ASSET.readall()
ALIEN1_B = ALIEN1_B_ASSET.readall()
ALIEN2_A = ALIEN2_A_ASSET.readall()
ALIEN2_B = ALIEN2_B_ASSET.readall()
ALIEN3_A = ALIEN3_A_ASSET.readall()
ALIEN3_B = ALIEN3_B_ASSET.readall()

FRAME_WIDTH = 64
FRAME_HEIGHT = 32

MAX_SPEED = 10
MIN_SPEED = 50

PACMAN_ANIMATION = "pacman"
SPACE_INVADERS_ANIMATION = "spaceinvaders"
CENTIPEDE_ANIMATION = "centipede"
RANDOM_ANIMATION = "random"

SECONDS_TO_RENDER = 15

SPEED_ADJUST = {
    PACMAN_ANIMATION: 1,
    SPACE_INVADERS_ANIMATION: 10,
    CENTIPEDE_ANIMATION: 3,
}

def main(config):
    animation = config.str("animation", PACMAN_ANIMATION)
    if animation == RANDOM_ANIMATION:
        animation = ANIMATION_LIST.values()[rand(len(ANIMATION_LIST) - 1)]

    speed = int(config.str("speed", DEFAULT_SPEED))
    if speed < 0:
        speed = rand(MIN_SPEED + MAX_SPEED + 1) + MAX_SPEED

    speed = speed * SPEED_ADJUST[animation]
    delay = speed * time.millisecond

    app_cycle_speed = SECONDS_TO_RENDER * time.second
    num_frames = math.ceil(app_cycle_speed // delay)

    allFrames = []
    for _ in range(1, 1000):
        if animation == PACMAN_ANIMATION:
            frames = pacman_get_frames()
        elif animation == SPACE_INVADERS_ANIMATION:
            frames = spaceinvaders_get_frames()
        else:
            frames = centipede_get_frames()

        allFrames.extend(frames)
        if len(allFrames) >= num_frames:
            break

    return render.Root(
        delay = delay.milliseconds,
        child = render.Animation(allFrames),
    )

def rand(ceiling):
    return random.number(0, ceiling - 1)

DEFAULT_SPEED = "30"

SPEED_LIST = {
    "Snail": "50",
    "Slow": "40",
    "Medium": "30",
    "Fast": "20",
    "Turbo": "10",
    "Random": "-1",
}

DEFAULT_ANIMATION = PACMAN_ANIMATION

ANIMATION_LIST = {
    "Pac-Man": PACMAN_ANIMATION,
    "Space Invaders": SPACE_INVADERS_ANIMATION,
    "Random": RANDOM_ANIMATION,
}

def get_schema():
    speed_options = [
        schema.Option(display = key, value = value)
        for key, value in SPEED_LIST.items()
    ]

    animation_options = [
        schema.Option(display = key, value = value)
        for key, value in ANIMATION_LIST.items()
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "animation",
                name = "Animation",
                desc = "Which game animation to show.",
                icon = "gear",
                default = DEFAULT_ANIMATION,
                options = animation_options,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Speed",
                desc = "Change the speed of the animation.",
                icon = "gear",
                default = DEFAULT_SPEED,
                options = speed_options,
            ),
        ],
    )

# Pac-Man

RED_R1 = RED_R1_ASSET.readall()
RED_R2 = RED_R2_ASSET.readall()
RED_L1 = RED_L1_ASSET.readall()
RED_L2 = RED_L2_ASSET.readall()
PINK_R1 = PINK_R1_ASSET.readall()
PINK_R2 = PINK_R2_ASSET.readall()
PINK_L1 = PINK_L1_ASSET.readall()
PINK_L2 = PINK_L2_ASSET.readall()
CYAN_R1 = CYAN_R1_ASSET.readall()
CYAN_R2 = CYAN_R2_ASSET.readall()
CYAN_L1 = CYAN_L1_ASSET.readall()
CYAN_L2 = CYAN_L2_ASSET.readall()
PEACH_R1 = PEACH_R1_ASSET.readall()
PEACH_R2 = PEACH_R2_ASSET.readall()
PEACH_L1 = PEACH_L1_ASSET.readall()
PEACH_L2 = PEACH_L2_ASSET.readall()
PM_1 = PM_1_ASSET.readall()
PM_R1 = PM_R1_ASSET.readall()
PM_R2 = PM_R2_ASSET.readall()
PM_L1 = PM_L1_ASSET.readall()
PM_L2 = PM_L2_ASSET.readall()
BLUE_1 = BLUE_1_ASSET.readall()
BLUE_2 = BLUE_2_ASSET.readall()

#WHITE_1 = WHITE_1_ASSET.readall()
#WHITE_2 = WHITE_2_ASSET.readall()
MSPM_L1 = MSPM_L1_ASSET.readall()
MSPM_L2 = MSPM_L2_ASSET.readall()
MSPM_L3 = MSPM_L3_ASSET.readall()
MSPM_R1 = MSPM_R1_ASSET.readall()
MSPM_R2 = MSPM_R2_ASSET.readall()
MSPM_R3 = MSPM_R3_ASSET.readall()

PACMANS = [
    [[PM_1, PM_R1, PM_R2, PM_R1], [PM_1, PM_L1, PM_L2, PM_L1]],
    [[MSPM_R1, MSPM_R2, MSPM_R3, MSPM_R2], [MSPM_L1, MSPM_L2, MSPM_L3, MSPM_L2]],
]

GHOSTS = [
    [[RED_R1, RED_R2], [RED_L1, RED_L2]],
    [[PINK_R1, PINK_R2], [PINK_L1, PINK_L2]],
    [[CYAN_R1, CYAN_R2], [CYAN_L1, CYAN_L2]],
    [[PEACH_R1, PEACH_R2], [PEACH_L1, PEACH_L2]],
    [[BLUE_1, BLUE_2], [BLUE_1, BLUE_2]],
]

# Not yet using a blinking ghost
# GHOST_CHASED_BLINKING = [
#     BLUE_1,
#     BLUE_2,
#     WHITE_1,
#     WHITE_2,
# ]

SPRITE_WIDTH = 15

PM_NUM_X_POSITIONS = FRAME_WIDTH + SPRITE_WIDTH * 2
PM_NUM_Y_POSITIONS = FRAME_HEIGHT - SPRITE_WIDTH

DIST_BETWEEN_SPRITES = 10

PM_MOVE_SPEED = 1

MIN_X = -(SPRITE_WIDTH + DIST_BETWEEN_SPRITES + SPRITE_WIDTH)
MAX_X = FRAME_WIDTH
FRAMES_PER_CALL = (MAX_X - MIN_X) // PM_MOVE_SPEED

CHASING_GHOST_COUNT = 4
CHASED_GHOST = 4

# Make the odds of chasing a ghost a little higher
CHANCE_FOR_CHASED_GHOST = 2

def pacman_get_frames():
    yPos = rand(PM_NUM_Y_POSITIONS)
    mspacman = rand(2) == 1
    reverse = rand(2) == 1
    whichGhost = rand(CHASING_GHOST_COUNT + CHANCE_FOR_CHASED_GHOST)
    if whichGhost >= CHASING_GHOST_COUNT:
        whichGhost = CHASED_GHOST

    if reverse:
        beginX = MAX_X
        endX = MIN_X
        step = -PM_MOVE_SPEED
    else:
        beginX = MIN_X
        endX = MAX_X
        step = PM_MOVE_SPEED

    frames = [
        pacman_get_frame(xPos, yPos, mspacman, reverse, whichGhost)
        for xPos in range(beginX, endX, step)
    ]
    return frames

# How many app frames before we increase the sprite frame
PACMAN_FRAMES_PER_FRAME = 1
GHOST_FRAMES_PER_FRAME = 3

def pacman_get_frame(xPos, yPos, mspacman, reverse, whichGhost):
    frameIndex = xPos // PM_MOVE_SPEED
    pacManFrameIndex = (frameIndex // PACMAN_FRAMES_PER_FRAME) % 4
    ghostFrameIndex = (frameIndex // GHOST_FRAMES_PER_FRAME) % 2

    whichPacman = 1 if mspacman else 0
    whichDir = 1 if reverse else 0
    pacmanChasing = whichGhost >= CHASING_GHOST_COUNT

    pacmanImage = PACMANS[whichPacman][whichDir][pacManFrameIndex]
    ghostImage = GHOSTS[whichGhost][whichDir][ghostFrameIndex]

    if (pacmanChasing and not reverse) or (not pacmanChasing and reverse):
        firstImage = pacmanImage
        secondImage = ghostImage
    else:
        firstImage = ghostImage
        secondImage = pacmanImage

    return render.Padding(
        pad = (xPos, yPos, 0, 0),
        child =
            render.Row(
                children = [
                    render.Image(firstImage),
                    render.Box(width = DIST_BETWEEN_SPRITES, height = 1, color = "#000"),
                    render.Image(secondImage),
                ],
            ),
    )

# Space Invaders

BIG_ALIEN_WIDTH = 12
ALIENS_PER_ROW = 3
SPACE_BETWEEN_ALIENS = 4
INVADER_ROW_WIDTH = (BIG_ALIEN_WIDTH * ALIENS_PER_ROW) + (SPACE_BETWEEN_ALIENS * (ALIENS_PER_ROW - 1))

SPACEINVADERS_IMAGES = [
    [ALIEN1_A, ALIEN1_B],
    [ALIEN2_A, ALIEN2_B],
    [ALIEN3_A, ALIEN3_B],
]

SI_NUM_X_POSITIONS = FRAME_WIDTH - INVADER_ROW_WIDTH + 1

# -2 because we don't want to duplicate the first and last X
NUM_STATES = (SI_NUM_X_POSITIONS * 2) - 2

def spaceinvaders_get_frames():
    frames = [
        spaceinvaders_get_frame(i)
        for i in range(0, NUM_STATES)
    ]

    return frames

def spaceinvaders_get_frame(state):
    whichFrame = state % 2

    currentState = state % NUM_STATES
    pos_x = currentState % SI_NUM_X_POSITIONS
    pos_y = 2

    if currentState >= SI_NUM_X_POSITIONS:
        pos_x = SI_NUM_X_POSITIONS - pos_x - 2

    col1Image = SPACEINVADERS_IMAGES[0][whichFrame]
    col2Image = SPACEINVADERS_IMAGES[1][whichFrame]
    col3Image = SPACEINVADERS_IMAGES[2][whichFrame]

    return render.Padding(
        pad = (pos_x, pos_y, 0, 0),
        child =
            render.Column(
                children = [
                    render.Row(
                        children = [
                            render.Box(width = 1, height = 8, color = "#000"),
                            render.Image(col1Image),
                            render.Box(width = SPACE_BETWEEN_ALIENS + 3, height = 8, color = "#000"),
                            render.Box(width = 1, height = 8, color = "#000"),
                            render.Image(col1Image),
                            render.Box(width = SPACE_BETWEEN_ALIENS + 3, height = 8, color = "#000"),
                            render.Box(width = 1, height = 8, color = "#000"),
                            render.Image(col1Image),
                        ],
                    ),
                    render.Box(width = 1, height = 2, color = "#000"),
                    render.Row(
                        children = [
                            render.Image(col2Image),
                            render.Box(width = SPACE_BETWEEN_ALIENS + 1, height = 8, color = "#000"),
                            render.Image(col2Image),
                            render.Box(width = SPACE_BETWEEN_ALIENS + 1, height = 8, color = "#000"),
                            render.Image(col2Image),
                        ],
                    ),
                    render.Box(width = 1, height = 2, color = "#000"),
                    render.Row(
                        children = [
                            render.Image(col3Image),
                            render.Box(width = SPACE_BETWEEN_ALIENS, height = 8, color = "#000"),
                            render.Image(col3Image),
                            render.Box(width = SPACE_BETWEEN_ALIENS, height = 8, color = "#000"),
                            render.Image(col3Image),
                        ],
                    ),
                ],
            ),
    )

# Centipede

CENT_SPRITE_WIDTH = 8
CENT_SPRITE_HEIGHT = 8
CENT_NUM_SEGMENTS = 5
CENT_DIST_BETWEEN_SEGMENTS = CENT_SPRITE_WIDTH
CENT_MOVE_PER_STATE = 2
CENT_NUM_COLS = FRAME_WIDTH // CENT_SPRITE_WIDTH
CENT_NUM_ROWS = FRAME_HEIGHT // CENT_SPRITE_HEIGHT
CENT_NUM_STATES = (FRAME_WIDTH // CENT_MOVE_PER_STATE) * (FRAME_HEIGHT // CENT_SPRITE_HEIGHT) * 2
CENT_LEG_STATE_COUNT = 8
CENT_LEG_WRAP_AT = 5
CENT_BG_COLOR = "#000"
CENT_DIST_BEFORE_TURN = 2
CENT_HORZ_INDEX = 0
CENT_VERT_INDEX = 1
CENT_MIN_MUSHROOMS = 4
CENT_MAX_MUSHROOMS = 6

CENT_RED = "#F00"
CENT_GREEN = "#0F0"
CENT_OFF_WHITE = "#FFB"
CENT_MAGENTA = "#F0F"
CENT_PALE_GREEN = "#0FB"
CENT_BLUE_GREEN = "#0FF"
CENT_YELLOW = "#FF0"
CENT_DARK_YELLOW = "#FB0"
CENT_BLUE = "#00F"
CENT_PINK = "#F0B"

CENT_ORIG_EYE_COLOR = CENT_RED
CENT_ORIG_BODY_COLOR = CENT_GREEN
CENT_ORIG_LEG_COLOR = CENT_OFF_WHITE

CENT_HIST_MOVES_PER_SEGMENT = CENT_SPRITE_WIDTH // CENT_MOVE_PER_STATE
CENT_MAX_HISTORY_ITEMS = CENT_HIST_MOVES_PER_SEGMENT * CENT_NUM_SEGMENTS

def centipede_get_frames():
    colorScheme = get_color_scheme()
    centSprites = create_all_cent_sprites(colorScheme)
    mushroomSprite = create_mushroom_sprite(colorScheme)
    mushroomMap = create_mushroom_map(mushroomSprite)

    xDir = rand(2)
    if xDir == 0:
        xDir = -1
        centStartX = FRAME_WIDTH
    else:
        centStartX = -CENT_SPRITE_WIDTH

    centStartY = 0
    yDir = 1
    head = create_head(centStartX, centStartY, xDir, yDir)

    frames = []
    history = []
    for state in range(CENT_NUM_STATES):
        children = [render.Box(render.Box(color = CENT_BG_COLOR))]

        for item in mushroomMap.values():
            children.append(item[0])

        process_head_move(head, state, mushroomMap, history)

        for segmentIndex in range(CENT_NUM_SEGMENTS):
            item = get_segment_render_child(centSprites, segmentIndex, history)
            if item != None:
                children.append(item)

        frames.append(
            render.Stack(
                children = children,
            ),
        )

    return frames

def get_leg_index(state):
    legIndex = state % CENT_LEG_STATE_COUNT
    if legIndex >= CENT_LEG_WRAP_AT:
        legIndex = CENT_LEG_STATE_COUNT - legIndex

    return legIndex

def create_head(x, y, xDir, yDir):
    ret = {
        "x": x,
        "y": y,
        "xDir": xDir,
        "yDir": yDir,
        "turnFrame": -1,
    }

    return ret

def get_mushroomLoc_at_loc(x, y, mushroomMap):
    if x >= FRAME_WIDTH or y >= FRAME_HEIGHT or x < 0 or y < 0:
        return -1

    slot1 = centipede_get_sprite_slot(x, y)
    if slot1 in mushroomMap:
        return slot1

    slot2 = centipede_get_sprite_slot(x + CENT_SPRITE_WIDTH, y)
    if slot2 in mushroomMap:
        return slot2

    return -1

def should_turn(mushroomLoc, mushroomMap):
    if mushroomLoc == -1:
        return False

    mushroomItem = mushroomMap[mushroomLoc]

    # Has it never been hit?
    if mushroomItem[1] == False:
        # Then mark it as hit
        mushroomItem[1] = True

        # And indicate a turn is needed
        return True
    else:
        # We've hit this mushroom before. Get rid of it and don't turn
        mushroomMap.pop(mushroomLoc)
        return False

def process_head_move(segment, state, mushroomMap, history):
    # turnFrame keeps track of the 4 frames needed for a turn
    turnFrame = segment["turnFrame"]
    xDir = segment["xDir"]
    yDir = segment["yDir"]

    if turnFrame == -1:
        if xDir == 1:
            if (FRAME_WIDTH - (segment["x"] + CENT_SPRITE_WIDTH) <= CENT_DIST_BEFORE_TURN):
                turnFrame = 0
        elif segment["x"] <= CENT_DIST_BEFORE_TURN:
            turnFrame = 0

        mushroomLoc = get_mushroomLoc_at_loc(segment["x"] + (segment["xDir"] * CENT_MOVE_PER_STATE), segment["y"], mushroomMap)
        if should_turn(mushroomLoc, mushroomMap):
            turnFrame = 0

    y = segment["y"]
    if turnFrame == 0:
        if (y // CENT_SPRITE_HEIGHT) == 0:
            yDir = 1
            segment["yDir"] = yDir
        elif (y // CENT_SPRITE_HEIGHT) == (CENT_NUM_ROWS - 1):
            yDir = -1
            segment["yDir"] = yDir

    segment["turnFrame"] = turnFrame

    # This moves the leg state every other frame
    legState = (state % (CENT_LEG_STATE_COUNT * 2)) // 2

    xDirIndex = 1 if xDir > 0 else 0
    yDirIndex = 1 if yDir > 0 else 0

    diagIndex = -1
    horzVertIndex = -1
    if turnFrame == -1 or turnFrame == 3:
        horzVertIndex = CENT_HORZ_INDEX
    elif turnFrame == 0:
        # diag
        diagIndex = 0 if xDir < 0 else 2
        horzVertIndex = CENT_VERT_INDEX
    elif turnFrame == 1:
        # down/up
        diagIndex = 1
        horzVertIndex = CENT_VERT_INDEX
    elif turnFrame == 2:
        # diag
        segment["xDir"] = -segment["xDir"]
        diagIndex = 2 if xDir < 0 else 0
        horzVertIndex = CENT_VERT_INDEX

    if turnFrame >= 0:
        segment["y"] = segment["y"] + (CENT_MOVE_PER_STATE * yDir)
        if turnFrame < 3:
            segment["turnFrame"] = turnFrame + 1
        else:
            # Quit turning after frame 3 of a turn
            segment["turnFrame"] = -1

    segment["x"] = segment["x"] + (segment["xDir"] * CENT_MOVE_PER_STATE)

    x = segment["x"]
    y = segment["y"]

    # If this was the last frame of the turn...
    if turnFrame == 3:
        # Look for a mushroom in our path
        mushroomLoc = get_mushroomLoc_at_loc(x, y, mushroomMap)

        # Did we turn right into a mushroom?
        if should_turn(mushroomLoc, mushroomMap):
            # Then turn again
            segment["turnFrame"] = 0

    currentHistoryItem = struct(
        x = x,
        y = y,
        legState = legState,
        horzVertIndex = horzVertIndex,
        xDirIndex = xDirIndex,
        yDirIndex = yDirIndex,
        diagIndex = diagIndex,
    )

    # Push the latest location and sprite info onto the history
    history.insert(0, currentHistoryItem)

    # If the history has gotten longer than we need, prune the last one
    if len(history) > CENT_MAX_HISTORY_ITEMS:
        history.pop(CENT_MAX_HISTORY_ITEMS - 1)

    return

def get_segment_render_child(centSprites, segmentIndex, history):
    historyIndex = segmentIndex * CENT_HIST_MOVES_PER_SEGMENT
    if historyIndex >= len(history):
        return None

    historyItem = history[historyIndex]

    legIndex = get_leg_index(history[historyIndex].legState + segmentIndex)

    bodyIndex = 0 if historyIndex == 0 else 1

    if historyItem.horzVertIndex == CENT_HORZ_INDEX:
        sprite = centSprites[bodyIndex][CENT_HORZ_INDEX][historyItem.xDirIndex][legIndex]
    else:
        # 1 means up/down which has all leg frames
        # 0 or 2 is diag which only has two frames
        if historyItem.diagIndex != 1:
            legIndex = legIndex % 2
        sprite = centSprites[bodyIndex][CENT_VERT_INDEX][historyItem.diagIndex][historyItem.yDirIndex][legIndex]

    return render.Padding(
        pad = (historyItem.x, historyItem.y, 0, 0),
        child = render.Column(
            children = sprite,
        ),
    )

def add_mushroom(mushroomMap, mushroomSprite):
    col = rand(CENT_NUM_COLS)
    row = rand(CENT_NUM_ROWS)

    x = col * CENT_SPRITE_WIDTH
    y = row * CENT_SPRITE_WIDTH

    item = render.Padding(
        pad = (x, y, 0, 0),
        child = render.Column(
            children = mushroomSprite,
        ),
    )

    slot = centipede_get_sprite_slot(x, y)

    # [0]: render item
    # [1]: True if has been hit before
    mushroomMap[slot] = [item, False]

def centipede_get_sprite_slot(x, y):
    if x >= FRAME_WIDTH or y >= FRAME_HEIGHT or x < 0 or y < 0:
        return -1

    fixedCol = x // CENT_SPRITE_WIDTH
    fixedRow = y // CENT_SPRITE_HEIGHT
    return fixedRow * CENT_NUM_COLS + fixedCol

def create_mushroom_sprite(colorScheme):
    mushroomPixels = [
        ["#XXX", "#XXX", "#F00", "#F00", "#F00", "#F00", "#XXX", "#XXX"],
        ["#XXX", "#F00", "#0F0", "#0F0", "#0F0", "#0F0", "#F00", "#XXX"],
        ["#F00", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#F00"],
        ["#F00", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#F00"],
        ["#F00", "#F00", "#F00", "#F00", "#F00", "#F00", "#F00", "#F00"],
        ["#XXX", "#XXX", "#F00", "#0F0", "#0F0", "#F00", "#XXX", "#XXX"],
        ["#XXX", "#XXX", "#F00", "#0F0", "#0F0", "#F00", "#XXX", "#XXX"],
        ["#XXX", "#XXX", "#F00", "#F00", "#F00", "#F00", "#XXX", "#XXX"],
    ]

    return makeSprite(mushroomPixels, colorReplacements = colorScheme)

def get_color_scheme():
    colorSchemes = [
        # Green, red, off white
        {CENT_ORIG_BODY_COLOR: CENT_GREEN, CENT_ORIG_EYE_COLOR: CENT_RED, CENT_ORIG_LEG_COLOR: CENT_OFF_WHITE},

        # Pale green, magenta, yellow
        {CENT_ORIG_BODY_COLOR: CENT_PALE_GREEN, CENT_ORIG_EYE_COLOR: CENT_MAGENTA, CENT_ORIG_LEG_COLOR: CENT_YELLOW},

        # Magenta, pale green, red
        {CENT_ORIG_BODY_COLOR: CENT_MAGENTA, CENT_ORIG_EYE_COLOR: CENT_PALE_GREEN, CENT_ORIG_LEG_COLOR: CENT_RED},

        # Pink, pale green, dark yellow
        {CENT_ORIG_BODY_COLOR: CENT_PINK, CENT_ORIG_EYE_COLOR: CENT_PALE_GREEN, CENT_ORIG_LEG_COLOR: CENT_DARK_YELLOW},

        # Blue green, dark yellow, blue
        {CENT_ORIG_BODY_COLOR: CENT_BLUE_GREEN, CENT_ORIG_EYE_COLOR: CENT_DARK_YELLOW, CENT_ORIG_LEG_COLOR: CENT_BLUE},

        # Dark yellow, blue, pale green
        {CENT_ORIG_BODY_COLOR: CENT_DARK_YELLOW, CENT_ORIG_EYE_COLOR: CENT_BLUE, CENT_ORIG_LEG_COLOR: CENT_PALE_GREEN},

        # Red, blue, yellow
        {CENT_ORIG_BODY_COLOR: CENT_RED, CENT_ORIG_EYE_COLOR: CENT_BLUE, CENT_ORIG_LEG_COLOR: CENT_YELLOW},

        # Red, yellow, pale green
        {CENT_ORIG_BODY_COLOR: CENT_RED, CENT_ORIG_EYE_COLOR: CENT_YELLOW, CENT_ORIG_LEG_COLOR: CENT_PALE_GREEN},

        # Yellow, magenta, green
        {CENT_ORIG_BODY_COLOR: CENT_YELLOW, CENT_ORIG_EYE_COLOR: CENT_MAGENTA, CENT_ORIG_LEG_COLOR: CENT_GREEN},

        # Pale green, red, off white
        {CENT_ORIG_BODY_COLOR: CENT_PALE_GREEN, CENT_ORIG_EYE_COLOR: CENT_RED, CENT_ORIG_LEG_COLOR: CENT_OFF_WHITE},

        # Off white, magenta, green
        {CENT_ORIG_BODY_COLOR: CENT_OFF_WHITE, CENT_ORIG_EYE_COLOR: CENT_MAGENTA, CENT_ORIG_LEG_COLOR: CENT_GREEN},

        # Dark yellow, blue, off white
        {CENT_ORIG_BODY_COLOR: CENT_DARK_YELLOW, CENT_ORIG_EYE_COLOR: CENT_BLUE, CENT_ORIG_LEG_COLOR: CENT_OFF_WHITE},

        # Blue green, red, yellow
        {CENT_ORIG_BODY_COLOR: CENT_BLUE_GREEN, CENT_ORIG_EYE_COLOR: CENT_RED, CENT_ORIG_LEG_COLOR: CENT_YELLOW},

        # Green, magenta, red
        {CENT_ORIG_BODY_COLOR: CENT_GREEN, CENT_ORIG_EYE_COLOR: CENT_MAGENTA, CENT_ORIG_LEG_COLOR: CENT_RED},
    ]

    return colorSchemes[rand(len(colorSchemes))]

def create_mushroom_map(mushroomSprite):
    mushroomCount = rand(CENT_MAX_MUSHROOMS - CENT_MIN_MUSHROOMS + 1) + CENT_MIN_MUSHROOMS
    mushroomMap = {}
    for _ in range(mushroomCount):
        add_mushroom(mushroomMap, mushroomSprite)

    return mushroomMap

def create_all_cent_sprites(colorScheme):
    headHorzLeftPixels = [
        [
            ["#XXX", "#FFB", "#XXX", "#XXX", "#XXX", "#XXX", "#XXX"],
            ["#XXX", "#F00", "#F00", "#0F0", "#0F0", "#XXX", "#XXX"],
            ["#0F0", "#F00", "#F00", "#0F0", "#0F0", "#0F0", "#XXX"],
            ["#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0"],
            ["#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0"],
            ["#0F0", "#F00", "#F00", "#0F0", "#0F0", "#0F0", "#XXX"],
            ["#XXX", "#F00", "#F00", "#0F0", "#0F0", "#XXX", "#XXX"],
            ["#XXX", "#FFB", "#XXX", "#XXX", "#XXX", "#XXX", "#XXX"],
        ],
        [
            ["#XXX", "#XXX", "#FFB", "#XXX", "#XXX", "#XXX", "#XXX"],
            ["#XXX", "#F00", "#F00", "#0F0", "#0F0", "#XXX", "#XXX"],
            ["#0F0", "#F00", "#F00", "#0F0", "#0F0", "#0F0", "#XXX"],
            ["#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0"],
            ["#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0"],
            ["#0F0", "#F00", "#F00", "#0F0", "#0F0", "#0F0", "#XXX"],
            ["#XXX", "#F00", "#F00", "#0F0", "#0F0", "#XXX", "#XXX"],
            ["#XXX", "#XXX", "#FFB", "#XXX", "#XXX", "#XXX", "#XXX"],
        ],
        [
            ["#XXX", "#XXX", "#XXX", "#FFB", "#XXX", "#XXX", "#XXX"],
            ["#XXX", "#F00", "#F00", "#0F0", "#0F0", "#XXX", "#XXX"],
            ["#0F0", "#F00", "#F00", "#0F0", "#0F0", "#0F0", "#XXX"],
            ["#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0"],
            ["#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0"],
            ["#0F0", "#F00", "#F00", "#0F0", "#0F0", "#0F0", "#XXX"],
            ["#XXX", "#F00", "#F00", "#0F0", "#0F0", "#XXX", "#XXX"],
            ["#XXX", "#XXX", "#XXX", "#FFB", "#XXX", "#XXX", "#XXX"],
        ],
        [
            ["#XXX", "#XXX", "#XXX", "#XXX", "#FFB", "#XXX", "#XXX"],
            ["#XXX", "#F00", "#F00", "#0F0", "#0F0", "#XXX", "#XXX"],
            ["#0F0", "#F00", "#F00", "#0F0", "#0F0", "#0F0", "#XXX"],
            ["#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0"],
            ["#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0"],
            ["#0F0", "#F00", "#F00", "#0F0", "#0F0", "#0F0", "#XXX"],
            ["#XXX", "#F00", "#F00", "#0F0", "#0F0", "#XXX", "#XXX"],
            ["#XXX", "#XXX", "#XXX", "#XXX", "#FFB", "#XXX", "#XXX"],
        ],
        [
            ["#XXX", "#XXX", "#XXX", "#XXX", "#XXX", "#FFB", "#XXX"],
            ["#XXX", "#F00", "#F00", "#0F0", "#0F0", "#XXX", "#XXX"],
            ["#0F0", "#F00", "#F00", "#0F0", "#0F0", "#0F0", "#XXX"],
            ["#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0"],
            ["#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0"],
            ["#0F0", "#F00", "#F00", "#0F0", "#0F0", "#0F0", "#XXX"],
            ["#XXX", "#F00", "#F00", "#0F0", "#0F0", "#XXX", "#XXX"],
            ["#XXX", "#XXX", "#XXX", "#XXX", "#XXX", "#FFB", "#XXX"],
        ],
    ]

    headVertDownPixels = [
        [
            ["#XXX", "#XXX", "#XXX", "#XXX", "#XXX", "#FFB", "#XXX", "#XXX"],
            ["#XXX", "#XXX", "#XXX", "#0F0", "#0F0", "#XXX", "#XXX", "#XXX"],
            ["#XXX", "#XXX", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX", "#XXX"],
            ["#XXX", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX"],
            ["#XXX", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX"],
            ["#XXX", "#F00", "#F00", "#0F0", "#0F0", "#F00", "#F00", "#XXX"],
            ["#FFB", "#F00", "#F00", "#0F0", "#0F0", "#F00", "#F00", "#FFB"],
            ["#XXX", "#XXX", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX", "#XXX"],
        ],
        [
            ["#XXX", "#XXX", "#XXX", "#XXX", "#XXX", "#FFB", "#XXX", "#XXX"],
            ["#XXX", "#XXX", "#XXX", "#0F0", "#0F0", "#XXX", "#XXX", "#XXX"],
            ["#XXX", "#XXX", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX", "#XXX"],
            ["#XXX", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX"],
            ["#XXX", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX"],
            ["#FFB", "#F00", "#F00", "#0F0", "#0F0", "#F00", "#F00", "#FFB"],
            ["#XXX", "#F00", "#F00", "#0F0", "#0F0", "#F00", "#F00", "#XXX"],
            ["#XXX", "#XXX", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX", "#XXX"],
        ],
        [
            ["#XXX", "#XXX", "#XXX", "#XXX", "#XXX", "#FFB", "#XXX", "#XXX"],
            ["#XXX", "#XXX", "#XXX", "#0F0", "#0F0", "#XXX", "#XXX", "#XXX"],
            ["#XXX", "#XXX", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX", "#XXX"],
            ["#XXX", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX"],
            ["#FFB", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#FFB"],
            ["#XXX", "#F00", "#F00", "#0F0", "#0F0", "#F00", "#F00", "#XXX"],
            ["#XXX", "#F00", "#F00", "#0F0", "#0F0", "#F00", "#F00", "#XXX"],
            ["#XXX", "#XXX", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX", "#XXX"],
        ],
        [
            ["#XXX", "#XXX", "#XXX", "#XXX", "#XXX", "#FFB", "#XXX", "#XXX"],
            ["#XXX", "#XXX", "#XXX", "#0F0", "#0F0", "#XXX", "#XXX", "#XXX"],
            ["#XXX", "#XXX", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX", "#XXX"],
            ["#FFB", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#FFB"],
            ["#XXX", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX"],
            ["#XXX", "#F00", "#F00", "#0F0", "#0F0", "#F00", "#F00", "#XXX"],
            ["#XXX", "#F00", "#F00", "#0F0", "#0F0", "#F00", "#F00", "#XXX"],
            ["#XXX", "#XXX", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX", "#XXX"],
        ],
        [
            ["#XXX", "#XXX", "#XXX", "#XXX", "#XXX", "#FFB", "#XXX", "#XXX"],
            ["#XXX", "#XXX", "#XXX", "#0F0", "#0F0", "#XXX", "#XXX", "#XXX"],
            ["#FFB", "#XXX", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX", "#FFB"],
            ["#XXX", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX"],
            ["#XXX", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX"],
            ["#XXX", "#F00", "#F00", "#0F0", "#0F0", "#F00", "#F00", "#XXX"],
            ["#XXX", "#F00", "#F00", "#0F0", "#0F0", "#F00", "#F00", "#XXX"],
            ["#XXX", "#XXX", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX", "#XXX"],
        ],
    ]

    headDiagDownLeftPixels = [
        [
            ["#XXX", "#XXX", "#FFB", "#XXX", "#XXX", "#XXX", "#XXX", "#XXX", "#XXX"],
            ["#XXX", "#XXX", "#XXX", "#0F0", "#0F0", "#0F0", "#XXX", "#XXX", "#XXX"],
            ["#XXX", "#XXX", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX", "#XXX"],
            ["#XXX", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX"],
            ["#XXX", "#F00", "#F00", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX"],
            ["#XXX", "#F00", "#F00", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX"],
            ["#XXX", "#XXX", "#0F0", "#F00", "#F00", "#0F0", "#0F0", "#XXX", "#FFB"],
            ["#XXX", "#XXX", "#XXX", "#F00", "#F00", "#0F0", "#XXX", "#XXX", "#XXX"],
        ],
        [
            ["#XXX", "#XXX", "#XXX", "#XXX", "#XXX", "#XXX", "#XXX", "#XXX", "#XXX"],
            ["#XXX", "#FFB", "#XXX", "#0F0", "#0F0", "#0F0", "#XXX", "#XXX", "#XXX"],
            ["#XXX", "#XXX", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX", "#XXX"],
            ["#XXX", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX"],
            ["#XXX", "#F00", "#F00", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX"],
            ["#XXX", "#F00", "#F00", "#0F0", "#0F0", "#0F0", "#0F0", "#0F0", "#XXX"],
            ["#XXX", "#XXX", "#0F0", "#F00", "#F00", "#0F0", "#0F0", "#XXX", "#XXX"],
            ["#XXX", "#XXX", "#XXX", "#F00", "#F00", "#0F0", "#XXX", "#FFB", "#XXX"],
        ],
    ]

    eyeSprites = createCentSprites(headHorzLeftPixels, headVertDownPixels, headDiagDownLeftPixels, colorScheme, True)
    bodySprites = createCentSprites(headHorzLeftPixels, headVertDownPixels, headDiagDownLeftPixels, colorScheme, False)

    return [eyeSprites, bodySprites]

def createCentSprites(headHorzLeftPixels, headVertDownPixels, headDiagDownLeftPixels, colorScheme, eyes = True):
    # If we're not creating sprites for the eyes, we need to replace the eye color with the body color
    origRedReplacement = ""
    if not eyes:
        origRedReplacement = colorScheme[CENT_ORIG_EYE_COLOR]
        colorScheme[CENT_ORIG_EYE_COLOR] = colorScheme[CENT_ORIG_BODY_COLOR]

    headHorzLeft = []
    headHorzRight = []
    for item in headHorzLeftPixels:
        headHorzLeft.append(makeSprite(item, colorReplacements = colorScheme))
        headHorzRight.append(makeSprite(item, xMirror = True, colorReplacements = colorScheme))

    headVertDown = []
    headVertUp = []
    for item in headVertDownPixels:
        headVertDown.append(makeSprite(item, colorReplacements = colorScheme))
        headVertUp.append(makeSprite(item, colorReplacements = colorScheme, yMirror = True))

    headDiagDownLeft = []
    headDiagUpLeft = []
    headDiagDownRight = []
    headDiagUpRight = []
    for item in headDiagDownLeftPixels:
        headDiagDownLeft.append(makeSprite(item, colorReplacements = colorScheme))
        headDiagUpLeft.append(makeSprite(item, yMirror = True, colorReplacements = colorScheme))
        headDiagDownRight.append(makeSprite(item, xMirror = True, colorReplacements = colorScheme))
        headDiagUpRight.append(makeSprite(item, xMirror = True, yMirror = True, colorReplacements = colorScheme))

    # If we're not creating sprites for the eyes, put back the color we replaced
    if not eyes:
        colorScheme[CENT_ORIG_EYE_COLOR] = origRedReplacement

    centSprites = [
        [headHorzLeft, headHorzRight],
        [
            [headDiagUpLeft, headDiagDownLeft],
            [headVertUp, headVertDown],
            [headDiagUpRight, headDiagDownRight],
        ],
    ]

    return centSprites

# Adapted from: https://github.com/savetz/tidbyt-sprite-demo
# Additions made: xMirror and yMirror
def makeSprite(sprite, xMirror = False, yMirror = False, colorReplacements = {}):
    ###turn sprite pixel colors into a widget pile
    spriterow = []
    for i in range(len(sprite)):
        skipPixels = 0
        spriterow.append([])
        for j in range(len(sprite[i])):
            colIndex = j if not xMirror else len(sprite[i]) - 1 - j
            pixelColor = sprite[i][colIndex]
            if (pixelColor != "#XXX"):
                if pixelColor in colorReplacements:
                    pixelColor = colorReplacements[pixelColor]
                spriterow[i].append(
                    render.Padding(
                        pad = (skipPixels, 0, 0, 0),
                        child = render.Box(
                            color = pixelColor,
                            width = 1,
                            height = 1,
                        ),
                    ),
                )
                skipPixels = 0
            else:  #See-thru pixel #XXX
                skipPixels += 1
                if skipPixels == len(sprite[i]):  #if this was a whole row of see-thru pixels, force skip a line
                    spriterow[i].append(
                        render.Box(
                            #invisible box (no color)
                            width = 1,
                            height = 1,
                        ),
                    )

    spritecol = []
    for i in range(len(spriterow)):  #combine lines of Box widgets (the lines of the sprite) into columns of Row widgets
        rowIndex = i if not yMirror else len(spriterow) - 1 - i
        spritecol.append(
            render.Row(
                children = spriterow[rowIndex],
            ),
        )

    ###that's it: we have our sprite in a widget pile in spritecol
    return spritecol
