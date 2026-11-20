"""
Applet: Code Rain Clock
Summary: Time shimmers through code rain
Description: Green characters rain down the display. Wherever the rain
             passes a spot that belongs to the digits of the current time the
             characters light up much brighter, so the time (HH:MM) shimmers
             through the rain.
Author: Sonic-79
"""

load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TZ = "Europe/Berlin"

# The display is a grid of tiny pseudo characters: each cell is 3x4 px and
# holds a 2x3 px glyph: 21 columns, 8 rows on a 64x32 panel. On 128x64
# panels everything is drawn at twice the size; 64x64 panels get more rows
# with the time in the middle. All sizes below are in 1x pixels.
COLS = 21
CELL_W = 3
CELL_H = 4
TOP = 2  # px above the first row, centres the digits vertically

FRAMES = 150  # x 100 ms = 15 s
FRAME_MS = 100
DROPS_PER_COLUMN = 2

BG = "#000000"

# ordinary rain: leading character of a drop, then its fading tail
HEAD = "#2c9c48"
TAIL = ["#00701c", "#005a16", "#004611", "#00340c", "#002408", "#001604"]

# the same drop where it crosses a digit of the time: much brighter
HEAD_TIME = "#ffffff"
TAIL_TIME = ["#e8ffe8", "#c8ffc8", "#a4f8a4", "#80ec80", "#60dc60", "#46c846"]

# After a drop has left a digit position the spot glows on (three frames per
# colour) and then keeps the last, faint colour until the next drop arrives.
# So the time forms with the first drops and stays visible as a soft shimmer.
GLOW = ["#52c452", "#48ac48", "#3e963e", "#358035", "#2c6c2c", "#245a24", "#1e4c1e"]
GLOW_FRAMES = 3

# 3x5 cell digits
DIGITS = {
    "0": ["111", "101", "101", "101", "111"],
    "1": ["010", "110", "010", "010", "111"],
    "2": ["111", "001", "111", "100", "111"],
    "3": ["111", "001", "111", "001", "111"],
    "4": ["101", "101", "111", "001", "001"],
    "5": ["111", "100", "111", "001", "111"],
    "6": ["111", "100", "111", "101", "111"],
    "7": ["111", "001", "001", "001", "001"],
    "8": ["111", "101", "111", "101", "111"],
    "9": ["111", "101", "111", "001", "111"],
}
DIGIT_COLS = [2, 6, 12, 16]  # first column of each digit
COLON_COL = 10

def popcount(n):
    count = 0
    for i in range(6):
        if n & (1 << i):
            count += 1
    return count

# 2x3 glyphs as 6-bit patterns. Sparse ones for the rain, dense ones where
# the rain crosses the digits (so they look a little more solid).
SPARSE = [n for n in range(64) if popcount(n) in (3, 4)]
DENSE = [n for n in range(64) if popcount(n) in (4, 5)]

def glyph(cache, bits, color, scale):
    """Glyph widget; cache (a dict owned by main) avoids rebuilding it."""
    key = (bits, color)
    if key in cache:
        return cache[key]
    lines = []
    for r in range(3):
        cells = []
        for c in range(2):
            if bits & (1 << (r * 2 + c)):
                cells.append(render.Box(width = scale, height = scale, color = color))
            else:
                cells.append(render.Box(width = scale, height = scale))
        lines.append(render.Row(children = cells))
    widget = render.Column(children = lines)
    cache[key] = widget
    return widget

def mix(c, r, k):
    """Cheap deterministic hash -> non-negative int."""
    h = (c * 73856093) ^ (r * 19349663) ^ (k * 83492791)
    h = (h ^ (h >> 13)) * 1274126177
    return (h ^ (h >> 16)) & 0x7fffffff

def time_cells(hh, mm, digit_row):
    """Set of (col, row) that belong to the digits and the colon."""
    cells = {}
    text = "%d%d%d%d" % (hh // 10, hh % 10, mm // 10, mm % 10)
    for i in range(4):
        art = DIGITS[text[i]]
        for r in range(5):
            for c in range(3):
                if art[r][c] == "1":
                    cells[(DIGIT_COLS[i] + c, digit_row + r)] = True
    cells[(COLON_COL, digit_row + 1)] = True
    cells[(COLON_COL, digit_row + 3)] = True
    return cells

def new_drop(first):
    return {
        "head": -random.number(0, 14 if first else 6),
        "speed": random.number(1, 3),  # frames per cell
        "tail": random.number(5, 10),
    }

def main(config):
    tz = config.get("timezone") or config.get("$tz") or DEFAULT_TZ
    now = time.now().in_location(tz)
    hh = now.hour
    mm = now.minute

    # for testing: set "test_time" to e.g. "07:30" in the config
    test_time = config.get("test_time", "")
    if test_time != "":
        parts = test_time.split(":")
        hh = int(parts[0])
        mm = int(parts[1])

    random.seed(now.unix // 30)

    scale = 2 if canvas.is2x() else 1
    width, height = canvas.size()
    rows = (height // scale - TOP + CELL_H - 1) // CELL_H
    digit_row = (rows - 5) // 2

    target = time_cells(hh, mm, digit_row)
    cache = {}
    last_lit = {}  # digit cell -> frame in which a drop last covered it
    drops = [[new_drop(True) for _ in range(DROPS_PER_COLUMN)] for _ in range(COLS)]

    frames = []
    for f in range(FRAMES):
        layers = [render.Box(width = width, height = height, color = BG)]
        for c in range(COLS):
            col_drops = drops[c]

            # advance the drops of this column
            for d in col_drops:
                if f % d["speed"] == 0:
                    d["head"] += 1
                    if d["head"] - d["tail"] > rows:
                        fresh = new_drop(False)
                        d["head"] = fresh["head"]
                        d["speed"] = fresh["speed"]
                        d["tail"] = fresh["tail"]

            for r in range(rows):
                # brightest drop passing this cell: 0 = head, 1.. = tail
                best = -1
                for d in col_drops:
                    dist = d["head"] - r
                    if dist >= 0 and dist <= d["tail"]:
                        step = 0 if dist == 0 else 1 + (dist - 1) * len(TAIL) // d["tail"]
                        if best < 0 or step < best:
                            best = step
                is_time = (c, r) in target
                if best < 0:
                    if not is_time or (c, r) not in last_lit:
                        continue
                    age = (f - last_lit[(c, r)] - 1) // GLOW_FRAMES
                    color = GLOW[min(age, len(GLOW) - 1)]
                    bits = DENSE[mix(c, r, (f + c * 5 + r * 3) // 6) % len(DENSE)]
                elif is_time:
                    last_lit[(c, r)] = f
                    color = HEAD_TIME if best == 0 else TAIL_TIME[best - 1]
                    bits = DENSE[mix(c, r, (f + c * 5 + r * 3) // 6) % len(DENSE)]
                else:
                    color = HEAD if best == 0 else TAIL[best - 1]
                    bits = SPARSE[mix(c, r, (f + c * 7 + r * 11) // 6) % len(SPARSE)]

                layers.append(render.Padding(
                    pad = ((c * CELL_W + 1) * scale, (TOP + r * CELL_H) * scale, 0, 0),
                    child = glyph(cache, bits, color, scale),
                ))

        frames.append(render.Stack(children = layers))

    return render.Root(
        delay = FRAME_MS,
        show_full_animation = True,
        child = render.Animation(children = frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
