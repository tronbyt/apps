"""
Applet: Getaway Clock
Summary: Clock over a crime spree
Description: The time in fat bevelled arcade numerals, over a four-lane street seen from directly above — traffic both ways, a squad car working its lightbar, and a wanted meter. Styled after the top-down crime games of the late nineties. The city shifts through day, dusk and night with your clock.
Author: nsluke

A LukeByt original.

The time, told the way a top-down crime game from 1997 would tell it. Every
pixel here is drawn as run-length boxes from an index palette, which is what
lets the whole city re-tint for the hour without any of the drawing code
knowing about it: no sprite sheets, no font files, and nothing lifted from
anybody's game.
"""

load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

# --- Animation budget -------------------------------------------------------
# 150 frames at 100 ms is fifteen seconds, which is as long an animation as
# pixlet will encode and comfortably longer than the slot most devices give an
# app — so the clock rarely has to loop back on itself. Everything that moves
# wraps on a 50px world at a whole number of pixels a frame, so the run always
# lands back where it started and the loop has no seam. Ten frames to the
# second keeps the seconds honest.
DELAY_MS = 100
FRAME_COUNT = 150
FRAMES_PER_SECOND = 10
MAX_AGE = 15

WIDTH = 64
HEIGHT = 32
WORLD = 50
SCROLL = 2

# --- Street geometry --------------------------------------------------------
# Scaled off the car: in the originals a car was one block long and half a
# block wide, so it is 9 by 5 here and everything else follows from that. The
# road below is four lanes and a little over four car-lengths across.
KERB_L = 10
KERB_R = 53
ROAD_L = 11
ROAD_R = 52
CENTRE = 32
LANES = [16, 26, 37, 47]
DASH_LANES = [21, 42]
PLAYER_LANE = 2
PLAYER_Y = 18

HEXD = "0123456789abcdef"

# --- Palette ----------------------------------------------------------------
# One index per material, authored once at noon and re-tinted for the other two
# passes. The originals ran a blue-violet slate for tarmac rather than grey,
# yellow lane paint, and sandy pavement, and that combination is most of why a
# screenshot is recognisable at a glance.
ROAD = 0
ROAD_WORN = 1
DASH = 2
KERB = 3
WALK = 4
WALK_JOINT = 5
ROOF_A = 6
ROOF_B = 7
ROOF_TRIM = 8
SKYLIGHT = 9
GLASS = 10
CAR1 = 11
CAR1_TOP = 12
CAR2 = 13
CAR2_TOP = 14
CAR3 = 15
CAR3_TOP = 16
CAR4 = 17
CAR4_TOP = 18
COP = 19
COP_TOP = 20
FLASH_R = 21
FLASH_B = 22
PED = 23
HERO = 24
HERO_TOP = 25
ARROW = 26
HEADLAMP = 27
TAILLAMP = 28
SCORE_HI = 29
SCORE = 30
SCORE_RIM = 31
READOUT = 32
CAP = 33
PIPING = 34
FACE = 35
BADGE = 36
SCORE_LO = 37

NOON = [
    (74, 73, 115),  # tarmac: blue-violet slate, not grey
    (82, 81, 107),  # worn patch
    (255, 205, 79),  # lane paint
    (197, 198, 221),  # kerb, pale lilac
    (169, 169, 128),  # pavement slab
    (199, 199, 141),  # slab joint
    (91, 88, 122),  # block lid
    (104, 100, 138),  # block lid, second shade
    (68, 66, 98),  # parapet
    (199, 199, 141),  # skylight, dull by day
    (30, 29, 50),  # glass
    (200, 72, 46),
    (233, 122, 96),
    (47, 111, 181),
    (96, 158, 219),
    (78, 158, 87),
    (128, 200, 136),
    (216, 210, 196),
    (245, 242, 234),
    (232, 232, 236),
    (255, 255, 255),
    (255, 42, 42),
    (58, 92, 255),
    (217, 201, 176),
    (232, 179, 58),
    (255, 220, 130),
    (255, 252, 226),  # the dart over your own car, paler than both the car and the paint
    (255, 243, 196),
    (196, 55, 42),
    (255, 247, 33),
    (231, 219, 0),
    (66, 65, 0),  # the score readout
    (0, 233, 0),  # lives green, borrowed for the date
    (0, 48, 90),
    (222, 223, 173),
    (181, 109, 66),
    (255, 215, 60),
    (181, 174, 0),  # the shade the bevel drops down each stroke's lower edge
]

# Anything a city light would still burn through keeps its colour when the sun
# goes down; everything else takes the pass. Lane paint sits in between — it
# keeps most of its brightness but not all of it, because paint that never dims
# ends up with more contrast at midnight than it had at noon.
HALF_LIT = [DASH]

UNTINTED = [
    FLASH_R,
    FLASH_B,
    ARROW,
    HEADLAMP,
    TAILLAMP,
    SCORE_HI,
    SCORE,
    SCORE_RIM,
    READOUT,
    CAP,
    PIPING,
    FACE,
    BADGE,
    SCORE_LO,
]

# A flat multiply is the wrong model for nightfall: it scales the gap between
# two colours as well as their brightness, so the road and the block lids —
# only fifteen luma apart at noon — collapse into one field after dark. Scaling
# less and subtracting instead keeps that separation while still dropping the
# overall level, and it stops dusk from washing the blue-violet out of the
# tarmac into a neutral maroon.
TINTS = {
    "day": ((1.0, 1.0, 1.0), (0, 0, 0)),
    "dusk": ((0.86, 0.78, 0.80), (26, 2, -14)),
    "night": ((0.74, 0.78, 0.96), (-30, -28, -20)),
}
GLOW = (255, 217, 138)

def hx(v):
    v = int(v)
    if v < 0:
        v = 0
    if v > 255:
        v = 255
    return HEXD[v // 16] + HEXD[v % 16]

def rgb(c):
    return "#" + hx(c[0]) + hx(c[1]) + hx(c[2])

def shade(c, tint, bias, strength):
    out = []
    for i in range(3):
        lit = c[i] * tint[i] + bias[i]
        out.append(c[i] + (lit - c[i]) * strength)
    return out

def palette_for(mode):
    pass_ = TINTS[mode]
    tint = pass_[0]
    bias = pass_[1]
    out = []
    for i in range(len(NOON)):
        c = NOON[i]
        strength = 1.0
        if i in UNTINTED:
            strength = 0.0
        elif i in HALF_LIT:
            strength = 0.5
        out.append(rgb(shade(c, tint, bias, strength)))
    if mode != "day":
        out[SKYLIGHT] = rgb(GLOW)
    return out

# --- Type ---------------------------------------------------------------------
# A 3x5 label alphabet, plus chunky score numerals at cap 10. These are shaped
# after the readouts arcade games put on screen rather than after a display
# face — a display face draws its 1 as a bare stem, which is fine on a poster
# and unreadable on a clock. Every digit is the same width so the time never
# jitters as the minutes roll.
SMALL = {
    "A": [".#.", "#.#", "###", "#.#", "#.#"],
    "B": ["##.", "#.#", "##.", "#.#", "##."],
    "C": ["###", "#..", "#..", "#..", "###"],
    "D": ["##.", "#.#", "#.#", "#.#", "##."],
    "E": ["###", "#..", "##.", "#..", "###"],
    "F": ["###", "#..", "##.", "#..", "#.."],
    "G": ["###", "#..", "#.#", "#.#", "###"],
    "H": ["#.#", "#.#", "###", "#.#", "#.#"],
    "I": ["###", ".#.", ".#.", ".#.", "###"],
    "J": ["..#", "..#", "..#", "#.#", "###"],
    "K": ["#.#", "#.#", "##.", "#.#", "#.#"],
    "L": ["#..", "#..", "#..", "#..", "###"],
    "M": ["#..#", "####", "####", "#..#", "#..#"],
    "N": ["#..#", "##.#", "#.##", "#..#", "#..#"],
    "O": ["###", "#.#", "#.#", "#.#", "###"],
    "P": ["##.", "#.#", "##.", "#..", "#.."],
    "Q": ["###", "#.#", "#.#", "###", "..#"],
    "R": ["##.", "#.#", "##.", "#.#", "#.#"],
    "S": ["###", "#..", "###", "..#", "###"],
    "T": ["###", ".#.", ".#.", ".#.", ".#."],
    "U": ["#.#", "#.#", "#.#", "#.#", "###"],
    "V": ["#.#", "#.#", "#.#", "#.#", ".#."],
    "W": ["#..#", "#..#", "####", "####", "#..#"],
    "X": ["#.#", "#.#", ".#.", "#.#", "#.#"],
    "Y": ["#.#", "#.#", ".#.", ".#.", ".#."],
    "Z": ["###", "..#", ".#.", "#..", "###"],
    "0": ["###", "#.#", "#.#", "#.#", "###"],
    "1": [".#.", "##.", ".#.", ".#.", "###"],
    "2": ["###", "..#", "###", "#..", "###"],
    "3": ["###", "..#", "###", "..#", "###"],
    "4": ["#.#", "#.#", "###", "..#", "..#"],
    "5": ["###", "#..", "###", "..#", "###"],
    "6": ["###", "#..", "###", "#.#", "###"],
    "7": ["###", "..#", ".#.", ".#.", ".#."],
    "8": ["###", "#.#", "###", "#.#", "###"],
    "9": ["###", "#.#", "###", "..#", "###"],
    ":": [".", "#", ".", "#", "."],
    ".": [".", ".", ".", ".", "#"],
    "!": ["#", "#", "#", ".", "#"],
    "-": ["...", "...", "###", "...", "..."],
    "'": ["#", "#", ".", ".", "."],
    "/": ["..#", "..#", ".#.", "#..", "#.."],
    "+": ["...", ".#.", "###", ".#.", "..."],
    " ": ["..", "..", "..", "..", ".."],
}

BIG = {
    "0": [".#####.", "##ooo##", "##ooo##", "##ooo##", "##ooo##", "##ooo##", "##ooo##", "##ooo##", "##ooo##", ".#####."],
    "1": ["...##..", "..###..", ".####..", "...##..", "...##..", "...##..", "...##..", "...##..", "...##..", ".#####."],
    "2": [".#####.", "##ooo##", ".....##", ".....##", "....##.", "...##..", "..##...", ".##....", "##.....", "#######"],
    "3": [".#####.", "##ooo##", ".....##", "....##.", "..###..", "....##.", ".....##", ".....##", "##ooo##", ".#####."],
    "4": ["....##.", "...###.", "..####.", ".##o##.", "##oo##.", "#######", "#######", "....##.", "....##.", "....##."],
    "5": ["#######", "##.....", "##.....", "######.", ".....##", ".....##", ".....##", ".....##", "##ooo##", ".#####."],
    "6": ["..####.", ".##....", "##.....", "##.....", "######.", "##ooo##", "##ooo##", "##ooo##", "##ooo##", ".#####."],
    "7": ["#######", "##ooo##", "....##.", "....##.", "...##..", "...##..", "..##...", "..##...", "..##...", "..##..."],
    "8": [".#####.", "##ooo##", "##ooo##", "##ooo##", ".#####.", "##ooo##", "##ooo##", "##ooo##", "##ooo##", ".#####."],
    "9": [".#####.", "##ooo##", "##ooo##", "##ooo##", "##ooo##", ".######", ".....##", ".....##", "....##.", ".####.."],
    ":": ["..", "..", "##", "##", "..", "..", "##", "##", "..", ".."],
}

# The wanted meter was a row of police heads, not stars: a peaked navy cap with
# a badge and cream piping over a face. Five pixels across is just enough to
# carry it. Four heads was the ceiling in the first game; the sequel went to
# six.
COP_HEAD = [
    ".ccc.",
    "ccbcc",
    "ppppp",
    ".fff.",
    ".e.e.",
]
HEAD_INK = {"c": CAP, "b": BADGE, "p": PIPING, "f": FACE, "e": GLASS}

# The location dart that floated over your own car.
DART = ["#####", ".###.", "..#.."]

# --- Pixel plumbing ---------------------------------------------------------
# Frames hold palette indices, so a whole scene re-tints for time of day
# without any of the drawing code knowing about it. Index -1 means leave the
# pixel alone, which is how the HUD layers see the street underneath.
CLEAR = -1

def street_rows():
    """The cross-section of the street is the same on every row, so it gets
    built once and copied. Only what actually scrolls is drawn on top — the
    difference between two thousand writes a frame and about four hundred."""
    row = [ROOF_A] * WIDTH
    for x in range(56, WIDTH):
        row[x] = ROOF_B
    for x in range(8, 10):
        row[x] = WALK
    for x in range(54, 56):
        row[x] = WALK
    row[KERB_L] = KERB
    row[KERB_R] = KERB
    for x in range(ROAD_L, ROAD_R + 1):
        row[x] = ROAD
    return [row] * HEIGHT

def blank(w, h):
    return [[CLEAR] * w for _ in range(h)]

def put(fb, x, y, index):
    if x >= 0 and x < len(fb[0]) and y >= 0 and y < len(fb):
        fb[y][x] = index

def rect(fb, x, y, w, h, index):
    for yy in range(y, y + h):
        if yy >= 0 and yy < len(fb):
            row = fb[yy]
            for xx in range(x, x + w):
                if xx >= 0 and xx < len(row):
                    row[xx] = index

def blit(fb, glyph, x, y, index):
    for gy in range(len(glyph)):
        row = glyph[gy]
        for gx in range(len(row)):
            if row[gx] != ".":
                put(fb, x + gx, y + gy, index)

def blit_keyed(fb, glyph, x, y, keys):
    for gy in range(len(glyph)):
        row = glyph[gy]
        for gx in range(len(row)):
            index = keys.get(row[gx])
            if index != None:
                put(fb, x + gx, y + gy, index)

def text_width(font, s):
    total = 0
    for ch in s.elems():
        glyph = font.get(ch)
        if glyph == None:
            total += 3
        else:
            total += len(glyph[0]) + 1
    if total > 0:
        total -= 1
    return total

def draw_text(fb, font, s, x, y, index, counter):
    """An 'o' marks a glyph's enclosed counter. It takes its own colour so a
    hole in a digit reads as part of the digit rather than as a window onto
    whatever is driving past behind it."""
    for ch in s.elems():
        glyph = font.get(ch)
        if glyph == None:
            x += 3
        else:
            for gy in range(len(glyph)):
                row = glyph[gy]
                for gx in range(len(row)):
                    if row[gx] == "#":
                        put(fb, x + gx, y + gy, index)
                    elif row[gx] == "o":
                        put(fb, x + gx, y + gy, counter)
            x += len(glyph[0]) + 1
    return x

def draw_rimmed(fb, font, s, x, y, index, counter, rim, reach_x, reach_y):
    """Ink inside a hard rim, which is the whole trick behind a readout that
    stays legible over moving traffic. The horizontal reach runs to two on the
    clock: glyphs whose strokes stop short of their own edge otherwise leave a
    one-pixel column of road running down the gap between them, and a stripe of
    tarmac through the middle of the time is not something you can unsee."""
    for dy in range(-reach_y, reach_y + 1):
        for dx in range(-reach_x, reach_x + 1):
            if dx != 0 or dy != 0:
                draw_text(fb, font, s, x + dx, y + dy, rim, rim)
    draw_text(fb, font, s, x, y, index, counter)

def seal(fb, fill):
    """Close any one-pixel channel the rims of two neighbouring glyphs leave
    between them. A single column of road running down the middle of the
    readout is the sort of thing you cannot unsee once you have seen it. Two
    pixels of clearance survives, so the gap before the seconds stays open."""
    holes = []
    width = len(fb[0])
    for y in range(len(fb)):
        row = fb[y]
        for x in range(width):
            if row[x] != CLEAR:
                continue
            across = x > 0 and x < width - 1 and row[x - 1] != CLEAR and row[x + 1] != CLEAR
            down = y > 0 and y < len(fb) - 1 and fb[y - 1][x] != CLEAR and fb[y + 1][x] != CLEAR
            if across and down:
                holes.append((x, y))
    for hole in holes:
        fb[hole[1]][hole[0]] = fill

def bevel(fb, body, highlight, shade):
    """Light the top edge of every stroke and drop a shade down the bottom of
    it. The old score digits were drawn bevelled, and two substituted rows of
    pixels are the whole effect."""
    lit = []
    for y in range(len(fb)):
        row = fb[y]
        for x in range(len(row)):
            if row[x] != body:
                continue
            if y == 0 or fb[y - 1][x] != body:
                lit.append((x, y, highlight))
            elif y == len(fb) - 1 or fb[y + 1][x] != body:
                lit.append((x, y, shade))
    for spot in lit:
        fb[spot[1]][spot[0]] = spot[2]

def runs(row):
    out = []
    start = 0
    cur = row[0]
    for x in range(1, len(row)):
        if row[x] != cur:
            out.append((x - start, cur))
            start = x
            cur = row[x]
    out.append((len(row) - start, cur))
    return out

def emit(fb, palette, scale, boxes):
    """One Box per run of like-coloured pixels, and every Box memoised on its
    width and colour. Across a hundred frames the same few hundred
    boxes come back over and over, and looking one up costs a fraction of
    building it — which is most of this app's render budget."""
    rows = []
    for y in range(len(fb)):
        cells = []
        for run in runs(fb[y]):
            key = run[1] * 128 + run[0]
            box = boxes.get(key)
            if box == None:
                if run[1] == CLEAR:
                    box = render.Box(width = run[0] * scale, height = scale)
                else:
                    box = render.Box(width = run[0] * scale, height = scale, color = palette[run[1]])
                boxes[key] = box
            cells.append(box)
        rows.append(render.Row(children = cells))
    return render.Column(children = rows)

def at(x, y, child, scale):
    return render.Padding(pad = (x * scale, y * scale, 0, 0), child = child)

# --- The street -------------------------------------------------------------

def car(fb, x, y, body, top, heading, lit):
    """Nine pixels of car seen from straight above. Nose to tail it goes lamp
    nubs, bonnet, a dark windscreen band, the bright roof panel, the rear
    window, boot, tail lamps — which is the read that makes a five pixel wide
    smudge look like a car."""
    for yy in range(1, 8):
        for xx in range(5):
            put(fb, x + xx, y + yy, body)
    for xx in range(1, 4):
        put(fb, x + xx, y, body)
        put(fb, x + xx, y + 8, body)
    front = y
    back = y + 8
    if heading > 0:
        front = y + 8
        back = y
    rect(fb, x + 1, front - 3 * heading, 3, 1, top)
    rect(fb, x + 1, front - 4 * heading, 3, 1, top)
    rect(fb, x + 1, front - 2 * heading, 3, 1, GLASS)
    rect(fb, x + 1, front - 5 * heading, 3, 1, GLASS)
    if lit:
        put(fb, x + 1, front, HEADLAMP)
        put(fb, x + 3, front, HEADLAMP)
        put(fb, x + 1, back, TAILLAMP)
        put(fb, x + 3, back, TAILLAMP)

def wrap(value):
    return value % WORLD - 10

def draw_blocks(fb, offset):
    """Block lids panning with the camera at the same rate as the road beside
    them: a parapet every second block, and roof plant between, with a skylight
    that comes on after dark. Both pitches divide the 50px world, so the
    buildings wrap where the road does."""
    scrolled = offset * SCROLL
    for k in range(0, 2):
        y = (k * 25 + scrolled) % 50 - 12
        rect(fb, 0, y, 8, 1, ROOF_TRIM)
        rect(fb, 56, y + 8, 8, 1, ROOF_TRIM)
    for k in range(0, 5):
        y = (k * 10 + scrolled) % 50 - 12
        rect(fb, 2, y + 4, 4, 2, SKYLIGHT)
        rect(fb, 5, y + 8, 2, 1, ROOF_TRIM)
        rect(fb, 58, y + 7, 4, 2, SKYLIGHT)
        rect(fb, 57, y + 2, 2, 1, ROOF_TRIM)

def draw_road(fb, offset):
    scrolled = offset * SCROLL
    for k in range(0, 5):
        y = (k * 10 + scrolled) % 50 - 8
        rect(fb, 8, y, 2, 1, WALK_JOINT)
        rect(fb, 54, y + 5, 2, 1, WALK_JOINT)
    rect(fb, CENTRE - 1, 0, 1, HEIGHT, DASH)
    rect(fb, CENTRE + 1, 0, 1, HEIGHT, DASH)
    for lane in DASH_LANES:
        for k in range(0, 5):
            rect(fb, lane, (k * 10 + scrolled) % 50 - 8, 1, 5, DASH)
    for k in range(0, 5):
        rect(fb, 12, (k * 10 + scrolled) % 50 - 8, 1, 2, ROAD_WORN)

def draw_pedestrians(fb, offset):
    """Both pavements travel with the ground; the far side merely walks against
    it, which is a pixel a frame slower, not a different direction."""
    for i in range(6):
        side = 9
        step = offset * SCROLL
        if i % 2 == 1:
            side = 54
            step = offset * SCROLL - 1
        put(fb, side, wrap(i * 10 + step), PED)

# Lane, drift per frame, body, roof, and the phase that spaces them out. The
# player holds lane 2 and the squad car works lane 3, so nothing else is
# allowed in either: two cars sharing a lane at different speeds will sooner or
# later drive through each other, and at this size that reads as one smeared
# blob rather than a near miss. Every pairing here was checked frame by frame
# across the whole loop.
TRAFFIC = [
    (0, 4, CAR1, CAR1_TOP, 0),
    (0, 4, CAR4, CAR4_TOP, 26),
    (1, 3, CAR2, CAR2_TOP, 12),
    (1, 3, CAR3, CAR3_TOP, 38),
    (3, -2, CAR2, CAR2_TOP, 30),
]

def draw_traffic(fb, offset, lit):
    for entry in TRAFFIC:
        x = LANES[entry[0]] - 2
        heading = 1
        if entry[1] < 0:
            heading = -1
        car(fb, x, wrap(entry[4] + entry[1] * offset), entry[2], entry[3], heading, lit)

def draw_police(fb, offset, lit):
    # Matched to the drift of the car it shares lane 3 with, so the pair keeps
    # its spacing all the way round the loop.
    x = LANES[3] - 2
    y = wrap(1 - 2 * offset)
    car(fb, x, y, COP, COP_TOP, -1, lit)

    # The lightbar was a two frame sprite swap at about ten a second, which at
    # 100 ms a frame means it alternates every single frame.
    bar = FLASH_R
    if offset % 2 == 1:
        bar = FLASH_B
    put(fb, x + 1, y + 4, bar)
    put(fb, x + 3, y + 4, bar)

def draw_hero(fb, lit):
    x = LANES[PLAYER_LANE] - 2
    car(fb, x, PLAYER_Y, HERO, HERO_TOP, -1, lit)
    blit(fb, DART, x, PLAYER_Y - 4, ARROW)

# --- HUD --------------------------------------------------------------------
# These layers sit on top of the street rather than inside it, so each one is
# built once and reused across every frame it applies to. The clock only
# changes once a second; the meter and the date never change at all.
CLOCK_Y = 1
CLOCK_H = 13
METER_Y = 26
HEAD_PITCH = 6
READOUT_Y = 27

def clock_layer(label, meridiem, seconds_label):
    """The time, with whatever small readouts belong beside it stacked in a
    column to its right — the meridiem on top, the seconds under it, the way a
    score kept its multiplier hanging off the end."""
    width = text_width(BIG, label)
    side = text_width(SMALL, meridiem)
    seconds_w = text_width(SMALL, seconds_label)
    if seconds_w > side:
        side = seconds_w
    total = width
    if side > 0:
        total += side + 3
    x = (WIDTH - total) // 2
    fb = blank(WIDTH, CLOCK_H)
    draw_rimmed(fb, BIG, label, x, 2, SCORE, SCORE_RIM, SCORE_RIM, 2, 1)
    side_x = x + width + 3
    if meridiem != "" and seconds_label != "":
        draw_rimmed(fb, SMALL, meridiem, side_x, 2, SCORE, SCORE, SCORE_RIM, 1, 1)
        draw_rimmed(fb, SMALL, seconds_label, side_x, 8, READOUT, READOUT, SCORE_RIM, 1, 1)
    elif meridiem != "":
        draw_rimmed(fb, SMALL, meridiem, side_x, 5, SCORE, SCORE, SCORE_RIM, 1, 1)
    elif seconds_label != "":
        draw_rimmed(fb, SMALL, seconds_label, side_x, 7, READOUT, READOUT, SCORE_RIM, 1, 1)
    seal(fb, SCORE_RIM)
    bevel(fb, SCORE, SCORE_HI, SCORE_LO)
    return fb

def hud_layer(wanted, readout):
    fb = blank(WIDTH, HEIGHT - METER_Y)
    width = wanted * HEAD_PITCH - 1
    for i in range(wanted):
        blit_keyed(fb, COP_HEAD, WIDTH - width + i * HEAD_PITCH, 0, HEAD_INK)
    draw_rimmed(fb, SMALL, readout, 1, READOUT_Y - METER_Y, READOUT, READOUT, SCORE_RIM, 1, 1)
    return fb

# --- Composition ------------------------------------------------------------

def scene_for(hour, choice):
    # A stale or hand-edited config value must not reach the palette lookup: a
    # missing dict key aborts the render outright and blanks the panel.
    if choice in TINTS:
        return choice
    if hour < 6 or hour >= 21:
        return "night"
    if hour >= 18:
        return "dusk"
    return "day"

def two(n):
    if n < 10:
        return "0" + str(n)
    return str(n)

def clock_label(hour, minute, use_24):
    if use_24:
        return two(hour) + ":" + two(minute)
    display = hour % 12
    if display == 0:
        display = 12
    return str(display) + ":" + two(minute)

def meridiem_for(hour, use_24):
    """Without this a twelve-hour clock cannot tell noon from midnight."""
    if use_24:
        return ""
    if hour < 12:
        return "AM"
    return "PM"

def street_frame(base, frame, lit):
    fb = [row[:] for row in base]
    draw_blocks(fb, frame)
    draw_road(fb, frame)
    draw_pedestrians(fb, frame)
    draw_traffic(fb, frame, lit)
    draw_police(fb, frame, lit)
    draw_hero(fb, lit)
    return fb

def main(config):
    scale = 2 if canvas.is2x() else 1

    # A zone name the time module rejects would abort the render outright, and
    # Starlark gives you no way to catch that.
    zone = time.tz()
    if not time.is_valid_timezone(zone):
        zone = "UTC"
    now = time.now().in_location(zone)
    use_24 = config.bool("clock24", False)
    show_seconds = config.bool("seconds", True)
    mode = scene_for(now.hour, config.str("scene", "auto"))
    palette = palette_for(mode)
    lit = mode != "day"

    readout = now.format("Mon").upper() + " " + two(now.day)

    # One head per quarter of the hour, so the meter fills as the hour runs
    # out. Four was the ceiling in the first game; the sequel went to six.
    wanted = now.minute // 15 + 1

    base = street_rows()
    boxes = {}
    hud = emit(hud_layer(wanted, readout), palette, scale, boxes)
    start = now.hour * 3600 + now.minute * 60 + now.second

    if config.bool("$widget", False):
        # A still, so a frozen seconds count would only mislead.
        label = clock_label(now.hour, now.minute, use_24)
        return render.Root(child = render.Stack(children = [
            emit(street_frame(base, 0, lit), palette, scale, boxes),
            at(0, CLOCK_Y, emit(clock_layer(label, meridiem_for(now.hour, use_24), ""), palette, scale, boxes), scale),
            at(0, METER_Y, hud, scale),
        ]))

    # One clock layer per distinct second rather than per frame; the street is
    # the only thing that has to be redrawn ten times a second.
    clocks = []
    for s in range((FRAME_COUNT - 1) // FRAMES_PER_SECOND + 1):
        moment = (start + s) % 86400
        hour = moment // 3600
        label = clock_label(hour, (moment % 3600) // 60, use_24)
        seconds_label = ""
        if show_seconds:
            seconds_label = two(moment % 60)
        clocks.append(at(0, CLOCK_Y, emit(clock_layer(label, meridiem_for(hour, use_24), seconds_label), palette, scale, boxes), scale))

    frames = []
    for i in range(FRAME_COUNT):
        frames.append(render.Stack(children = [
            emit(street_frame(base, i, lit), palette, scale, boxes),
            clocks[i // FRAMES_PER_SECOND],
            at(0, METER_Y, hud, scale),
        ]))

    return render.Root(
        delay = DELAY_MS,
        max_age = MAX_AGE,
        child = render.Animation(children = frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "clock24",
                name = "24-hour clock",
                desc = "Show the time on a 24-hour clock.",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = "seconds",
                name = "Show seconds",
                desc = "Run a seconds counter beside the time.",
                icon = "stopwatch",
                default = True,
            ),
            schema.Dropdown(
                id = "scene",
                name = "Time of day",
                desc = "Which pass of the city to drive through.",
                icon = "sun",
                default = "auto",
                options = [
                    schema.Option(display = "Follow the clock", value = "auto"),
                    schema.Option(display = "Daylight", value = "day"),
                    schema.Option(display = "Dusk", value = "dusk"),
                    schema.Option(display = "Night", value = "night"),
                ],
            ),
        ],
    )
