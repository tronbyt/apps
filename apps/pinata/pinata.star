"""
Applet: Pinata
Summary: Smack a pinata until it bursts
Description: A colorful pinata swings on its rope while a stick smacks it.
Author: tscott98
"""

load("math.star", "math")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

SCALE = 2 if canvas.is2x() else 1
DEV_W, DEV_H = canvas.size()

# Logical (1x) screen size. All physics runs in 1x units; drawing multiplies by SCALE.
W = DEV_W // SCALE
H = DEV_H // SCALE
GROUND_Y = H - 1
ANCHOR_X = W // 2
ANCHOR_Y = -12

# ---------------------------------------------------------------------------
# Colors

RAINBOW = ["#ff2d6f", "#ff8a1c", "#ffe03a", "#35d45a", "#22b8ff", "#9d4dff"]
PASTEL = ["#ff7ac0", "#ffd84d", "#4de8c8", "#b07bff", "#ff9a4d"]
OCEAN = ["#14d2c8", "#22a0ff", "#7a5cff", "#ff4fa3", "#ff9d2e", "#ffe14a"]
CONES = ["#ff2d6f", "#ffe03a", "#22b8ff", "#35d45a", "#ff8a1c", "#9d4dff", "#ff4fd8"]

BASE_COLORS = {
    "k": "#000000",
    "w": "#ffffff",
    "p": "#ff8fc8",
    "h": "#6b4a32",
    "t": "#ffd23f",
    "u": "#ff2fa0",
    "r": "#ff2a2a",
    "g": "#2fbf4a",
    "Y": "#ffe03a",
    "b": "#3aa8ff",
    "c": "#fff1d6",
    "f": "#ffb21c",
    "m": "#9a5a2a",
    "y": "#f7c948",
    "o": "#c98a2a",
    "P": "#ff7eb6",
    "M": "#7ef0c0",
    "G": "#3fd35a",
    "O": "#d2663a",
}

# ---------------------------------------------------------------------------
# Pinata sprites, drawn at 1x. "." is transparent.
#   S  horizontal stripes from the sprite's stripe palette (band rows tall)
#   V  vertical stripes from the stripe palette (band columns wide)
#   1-7  star cones
#   anything else: BASE_COLORS, overridden by the sprite's own colors
# hook is the (x, y) pixel the rope ties to. fringe lists the crepe-paper
# colors that get a ruffled darker lower half on 2x displays.

PINATAS = {
    "star": {
        "name": "Star",
        "hook": (9, 0),
        "band": 2,
        "stripes": ["#ffe03a", "#ff2d6f", "#22b8ff"],
        "fringe": "S1234567",
        "colors": {},
        "grid": [
            ".........1.........",
            ".........1.........",
            "........111........",
            "..7.....111.....2..",
            "..7777.11111.2222..",
            "...7777SSSSS2222...",
            "...777SSSSSSS222...",
            "....7SSSSSSSSS2....",
            "....7SSSSSSSSS3....",
            "...66SSSSSSSSS33...",
            ".6666SSSSSSSSS3333.",
            "66666SSSSSSSSS33333",
            "t...66SSSSSSS43...t",
            "u....55SSSSS44....u",
            "t....555554444....t",
            ".....5555.4444.....",
            ".....555...444.....",
            ".....5.......4.....",
            ".....t.......t.....",
            ".....u.......u.....",
            ".....t.......t.....",
        ],
    },
    "donkey": {
        "name": "Donkey",
        "hook": (10, 9),
        "band": 2,
        "stripes": RAINBOW,
        "fringe": "St",
        "colors": {},
        "grid": [
            ".............S..S.....",
            ".............SS.SS....",
            ".............SSSSS....",
            "............SSSSSSS...",
            "............SSSSkSSS..",
            "............SSSSSSSSSS",
            "............SSSSSSSSpk",
            "............SSSSS.SSpp",
            "............SSSSS.....",
            "....SSSSSSSSSSSSS.....",
            ".t.SSSSSSSSSSSSSS.....",
            "t.SSSSSSSSSSSSSSS.....",
            "u.SSSSSSSSSSSSSSS.....",
            "t.SSSSSSSSSSSSSSS.....",
            "u.SSSSSSSSSSSSSSS.....",
            "..SS.SS.....SS.SS.....",
            "..SS.SS.....SS.SS.....",
            "..hh.hh.....hh.hh.....",
        ],
    },
    "llama": {
        "name": "Llama",
        "hook": (7, 9),
        "band": 1,
        "stripes": PASTEL,
        "fringe": "cS",
        "colors": {},
        "grid": [
            "............t.t....",
            "............c.c....",
            "...........ccccc...",
            "...........cckccc..",
            "...........ccccccp.",
            "...........cccc....",
            "...........cccc....",
            "...........cccc....",
            "...........cccc....",
            "..ccSSSSSSScccc....",
            ".cccSSSSSSScccc....",
            "tcccSSSSSSScccc....",
            "ucccSSSSSSScccc....",
            ".ccctutututcccc....",
            "..cc.cc...cc.cc....",
            "..cc.cc...cc.cc....",
            "..cc.cc...cc.cc....",
            "..hh.hh...hh.hh....",
        ],
    },
    "fish": {
        "name": "Fish",
        "hook": (10, 0),
        "band": 2,
        "stripes": OCEAN,
        "fringe": "Vf",
        "colors": {"p": "#ff4f7a"},
        "grid": [
            "..........ff.........",
            ".........ffff........",
            "f.......VVVVVVV......",
            "ff....VVVVVVVVVVV....",
            "fff.VVVVVVVVVVVVVV...",
            "ffffVVVVVVVVVVVVwkVV.",
            "ffffVVVVVVVVVVVVkkVVV",
            "fffVVVVVVVVVVVVVVVVVp",
            "fff.VVVVVVVVVVVVVVVV.",
            "ff....VVVVVVVVVVVVV..",
            "f.......VVVVVVVVV....",
            ".........ff..........",
        ],
    },
    "icecream": {
        "name": "Ice Cream",
        "hook": (6, 2),
        "band": 2,
        "stripes": RAINBOW,
        "fringe": "PMyo",
        "colors": {"g": "#3fae3f"},
        "grid": [
            ".......g.....",
            "......rr.....",
            "....PPPPP....",
            "...PPwPPPP...",
            "..PPPPPPbPP..",
            "..PYPPPPPPP..",
            "..PPPPwPPPP..",
            ".MPMMPMMPPMM.",
            ".MMMMMMMMMMM.",
            "MMMMMbMMMMMMM",
            "MMMMMMMMMYMMM",
            ".MMMMMMMMMMM.",
            ".yyyoyyyoyyy.",
            "..yoyoyoyoy..",
            "..oyyyoyyyo..",
            "...oyoyoyo...",
            "...yoyyyoy...",
            "....yoyoy....",
            "....yyoyy....",
            ".....oyo.....",
            "......y......",
        ],
    },
    "cactus": {
        "name": "Cactus",
        "hook": (7, 0),
        "band": 1,
        "stripes": RAINBOW,
        "fringe": "GgO",
        "colors": {"g": "#1f8f3a", "p": "#ff4fb8"},
        "grid": [
            ".......p.......",
            "......pYp......",
            ".......p.......",
            "......GgG......",
            ".....GgGgG..G..",
            ".....GgGgG.GgG.",
            "..G..GgGgG.GgG.",
            ".GgG.GgGgG.GgG.",
            ".GgG.GgGgG.GgG.",
            ".GgG.GgGgGGGgG.",
            ".GgG.GgGgGGGG..",
            ".GgGGGgGgG.....",
            "..GGGGgGgG.....",
            ".....GgGgG.....",
            ".....GgGgG.....",
            "...ooooooooo...",
            "...VVVVVVVVV...",
            "....OOOOOOO....",
            "....OOOOOOO....",
            ".....OOOOO.....",
        ],
    },
}

PINATA_IDS = ["star", "donkey", "llama", "fish", "icecream", "cactus"]

CANDY_COLORS = ["#ff2d6f", "#ffe03a", "#22b8ff", "#35d45a", "#ff8a1c", "#9d4dff", "#ff4fd8", "#ffffff"]

# Candy patterns: C = candy color, e = light twist, w = shine, s = lollipop stick.
CANDY_1X = [
    ["eCe"],
    ["wC", "CC"],
    ["Cw", "wC", "s.", "s."],
]
CANDY_2X = [
    ["e.CCC.e", "eeCCCee", "e.CCC.e"],
    [".CC.", "CwCC", "CCCC", ".CC."],
    [".CwC.", "CCwCw", "wCCwC", "CwCCw", ".CwC.", "..s..", "..s..", "..s.."],
]

# Timing and physics. Physics runs in 1x units and seconds.
DELAY = 80
FRAMES = 180
DT = DELAY / 1000.0
SWING_K = 14.0  # g / L of the pendulum
SWING_DAMP = 0.35
MAX_THETA = 0.6
STICK_OUT = 118  # stick angle (degrees) when fully out of view
STICK_RAISED = 70
STICK_LOW = -10

# ---------------------------------------------------------------------------
# Small helpers

HEX = "0123456789abcdef"

def shade(color, f):
    c = color.lstrip("#").lower()
    out = "#"
    for i in range(3):
        v = HEX.index(c[2 * i]) * 16 + HEX.index(c[2 * i + 1])
        v = min(255, int(v * f))
        out += HEX[v // 16] + HEX[v % 16]
    return out

def rnd(v):
    return int(math.floor(v + 0.5))

def rand(a, b):
    return a + (b - a) * random.float()

def chance(p):
    return random.float() < p

def pick(items):
    return items[random.number(0, len(items) - 1)]

def epx(grid):
    """Scale2x/EPX: doubles a char grid and smooths diagonal edges."""
    h = len(grid)
    w = len(grid[0])
    out = []
    for y in range(h):
        r0 = []
        r1 = []
        for x in range(w):
            p = grid[y][x]
            a = grid[y - 1][x] if y > 0 else "."
            b = grid[y][x + 1] if x < w - 1 else "."
            c = grid[y][x - 1] if x > 0 else "."
            d = grid[y + 1][x] if y < h - 1 else "."
            r0.append(a if (c == a and c != d and a != b) else p)
            r0.append(b if (a == b and a != c and b != d) else p)
            r1.append(c if (d == c and d != b and c != a) else p)
            r1.append(d if (b == d and b != a and d != c) else p)
        out.append("".join(r0))
        out.append("".join(r1))
    return out

def device_grid(grid):
    return epx(grid) if SCALE == 2 else ["".join(r) for r in grid]

def pixel_color(sp, colors, ch, x, y, shift):
    """Color of char ch at device pixel (x, y) of a (possibly 2x) sprite grid."""
    row = y // SCALE
    col = x // SCALE
    stripes = sp["stripes"]
    if ch == "S":
        c = stripes[(row // sp["band"] + shift) % len(stripes)]
    elif ch == "V":
        c = stripes[(col // sp["band"] + shift) % len(stripes)]
    elif ch in "1234567":
        c = CONES[(int(ch) - 1 + shift) % len(CONES)]
    else:
        c = colors.get(ch, "#ffffff")
    if SCALE == 2 and ch in sp["fringe"] and y % 2 == 1:
        c = shade(c, 0.78)
    return c

def sprite_widget(sp, colors, grid, shift, ox = 0, oy = 0):
    """Turn a device-resolution char grid into a Column of run-length Rows."""
    rows = []
    for y in range(len(grid)):
        line = grid[y]
        kids = []
        x = 0
        n = len(line)
        for _ in range(n):
            if x >= n:
                break
            ch = line[x]
            start = x
            if ch == ".":
                for _ in range(n):
                    if x >= n or line[x] != ".":
                        break
                    x += 1
                if x < n:
                    kids.append(render.Box(width = x - start, height = 1))
                continue
            color = pixel_color(sp, colors, ch, x + ox, y + oy, shift)
            x += 1
            for _ in range(n):
                if x >= n or line[x] == ".":
                    break
                if pixel_color(sp, colors, line[x], x + ox, y + oy, shift) != color:
                    break
                x += 1
            kids.append(render.Box(width = x - start, height = 1, color = color))
        if kids:
            rows.append(render.Row(children = kids))
        else:
            rows.append(render.Box(width = 1, height = 1))
    return render.Column(children = rows)

def at(x, y, child):
    return render.Padding(pad = (x, y, 0, 0), child = child)

def runs_to_widgets(pixels):
    """pixels: dict (x, y) -> color in device px. Returns positioned row runs."""
    out = []
    by_row = {}
    for (x, y), c in pixels.items():
        if x < 0 or y < 0 or x >= DEV_W or y >= DEV_H:
            continue
        by_row.setdefault(y, []).append((x, c))
    for y, items in by_row.items():
        items = sorted(items)
        i = 0
        for _ in range(len(items)):
            if i >= len(items):
                break
            x0, c = items[i]
            j = i + 1
            for _ in range(len(items)):
                if j >= len(items) or items[j][0] != x0 + (j - i) or items[j][1] != c:
                    break
                j += 1
            out.append(at(x0, y, render.Box(width = j - i, height = 1, color = c)))
            i = j
    return out

def blit(px, pattern, x0, y0, color):
    for y in range(len(pattern)):
        row = pattern[y]
        for x in range(len(row)):
            ch = row[x]
            if ch == ".":
                continue
            if ch == "C":
                c = color
            elif ch == "w":
                c = "#ffffff"
            elif ch == "s":
                c = "#e8e8e8"
            else:
                c = shade(color, 1.6)
            px[(x0 + x, y0 + y)] = c

# ---------------------------------------------------------------------------
# Scenery

def string_y(x):
    """Bunting string height (device px) at device column x: two droopy swags."""
    half = DEV_W / 2.0
    t = (x % half) / half
    return rnd(2 * SCALE * math.sin(math.pi * t))

def bunting():
    px = {}
    for x in range(DEV_W):
        px[(x, string_y(x))] = "#e8e8e8" if SCALE == 1 else ("#f0f0f0" if x % 2 == 0 else "#b0b0b0")
    if SCALE == 1:
        shape = [3, 3, 1]
    else:
        shape = [7, 7, 5, 5, 3, 1]
    fw = shape[0]
    step = 6 * SCALE
    i = 0
    for fx in range(SCALE * 2, DEV_W - fw, step):
        color = RAINBOW[i % len(RAINBOW)]
        top = string_y(fx + fw // 2) + 1
        for r in range(len(shape)):
            wr = shape[r]
            off = (fw - wr) // 2
            for k in range(wr):
                c = color
                if SCALE == 2 and k == 0 and r < 4:
                    c = shade(color, 1.35)
                px[(fx + off + k, top + r)] = c
        i += 1
    return runs_to_widgets(px)

def ground():
    px = {}
    for x in range(DEV_W):
        if SCALE == 1:
            px[(x, DEV_H - 1)] = "#3fa04a" if x % 5 == 0 else "#1f6b2a"
        else:
            px[(x, DEV_H - 1)] = "#1f6b2a"
            px[(x, DEV_H - 2)] = "#2f8a3a" if x % 3 != 0 else "#1f6b2a"
            if x % 7 == 2:
                px[(x, DEV_H - 3)] = "#4fbf5a"
    return runs_to_widgets(px)

def rope(hx, hy):
    """Rope from the off-screen anchor to the hook (device px)."""
    px = {}
    ax = ANCHOR_X * SCALE
    ay = ANCHOR_Y * SCALE
    if hy <= ay:
        return []
    for y in range(max(0, ay), hy):
        x = rnd(ax + (y - ay) * (hx - ax) / float(hy - ay))
        if SCALE == 1:
            px[(x, y)] = "#c9a26a"
        else:
            px[(x, y)] = "#e0c08a" if y % 3 else "#9a7444"
    return runs_to_widgets(px)

def stick_dir(side, angle_deg):
    a = math.radians(angle_deg)
    return (side * math.cos(a), -math.sin(a))

def draw_stick(px, pvx, pvy, side, angle_deg, length):
    """A taped broomstick from an off-screen pivot (1x units)."""
    dx, dy = stick_dir(side, angle_deg)
    steep = abs(dy) > abs(dx)
    thick = 2 if SCALE == 1 else 3
    steps = int(length * SCALE * 2)
    for s in range(steps):
        d = s / 2.0
        x = rnd(pvx * SCALE + dx * d)
        y = rnd(pvy * SCALE + dy * d)
        if x < -thick or y < -thick or x > DEV_W + thick or y > DEV_H + thick:
            continue
        band = int(d / (4 * SCALE))
        c = "#c68a4a" if band % 2 == 0 else RAINBOW[(band // 2) % len(RAINBOW)]
        if d > length * SCALE - 2 * SCALE:
            c = "#ff2d6f"
        for t in range(thick):
            edge = shade(c, 0.7) if t == thick - 1 else c
            if steep:
                px[(x + t, y)] = edge
            else:
                px[(x, y + t)] = edge

def draw_pow(px, cx, cy, age, big):
    """Comic-book smack burst centered at device px (cx, cy)."""
    dirs = [(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)]
    m = 2 if big else 1
    if age == 0:
        spans = (0, 2 * SCALE * m)
        cols = ["#ffffff", "#fff27a"]
    elif age == 1:
        spans = (2 * SCALE, 4 * SCALE * m)
        cols = ["#ffe03a", "#ffffff", "#ff8a1c"]
    else:
        spans = (4 * SCALE * m - SCALE, 5 * SCALE * m)
        cols = ["#ff8a1c", "#ff2d6f"]
    for i in range(len(dirs)):
        ddx, ddy = dirs[i]
        r_end = spans[1] if i < 4 else spans[1] * 3 // 4
        for r in range(spans[0], r_end + 1):
            px[(cx + ddx * r, cy + ddy * r)] = cols[(r // SCALE) % len(cols)]

# ---------------------------------------------------------------------------
# Pinata geometry

def rest_hook_y(sp):
    """Hook height that leaves the pinata's bottom a few rows above the grass."""
    return (GROUND_Y - 5) - (len(sp["grid"]) - sp["hook"][1])

def is_edge(cur, x, y):
    h = len(cur)
    w = len(cur[0])
    for dx, dy in [(1, 0), (-1, 0), (0, 1), (0, -1)]:
        nx = x + dx
        ny = y + dy
        if nx < 0 or ny < 0 or nx >= w or ny >= h or cur[ny][nx] == ".":
            return True
    return False

def near_hook(sp, x, y):
    hx, hy = sp["hook"]
    return abs(x - hx) <= 2 and abs(y - hy) <= 2

def chip(sp, cur, gx0, gy0, n):
    """Knock up to n edge pixels off near grid point (gx0, gy0). Returns [(x, y, ch)]."""
    h = len(cur)
    w = len(cur[0])
    best = None
    bestd = 1000000.0
    for y in range(h):
        for x in range(w):
            if cur[y][x] == "." or near_hook(sp, x, y) or not is_edge(cur, x, y):
                continue
            d = (x - gx0) * (x - gx0) + (y - gy0) * (y - gy0) + rand(0, 3)
            if d < bestd:
                bestd = d
                best = (x, y)
    if best == None:
        return []
    removed = []
    queue = [best]
    for _ in range(n * 6):
        if len(removed) >= n or not queue:
            break
        x, y = queue.pop(0)
        if cur[y][x] == ".":
            continue
        removed.append((x, y, cur[y][x]))
        cur[y][x] = "."
        nbrs = [(1, 0), (-1, 0), (0, 1), (0, -1)]
        for _ in range(2):
            k = random.number(0, 3)
            nbrs[0], nbrs[k] = nbrs[k], nbrs[0]
        for dx, dy in nbrs:
            nx = x + dx
            ny = y + dy
            if nx >= 0 and ny >= 0 and nx < w and ny < h and cur[ny][nx] != "." and not near_hook(sp, nx, ny):
                queue.append((nx, ny))
    return removed

def stick_contact(cur, left, top, pvx, pvy, side, angle_deg, length):
    """First point of the stick inside an opaque pinata pixel, or None (1x units)."""
    dx, dy = stick_dir(side, angle_deg)
    h = len(cur)
    w = len(cur[0])
    for s in range(int(length * 2)):
        d = s / 2.0
        x = pvx + dx * d
        y = pvy + dy * d
        gx = int(math.floor(x - left))
        gy = int(math.floor(y - top))
        if gx >= 0 and gy >= 0 and gx < w and gy < h and cur[gy][gx] != ".":
            return (x, y, gx, gy)
    return None

# ---------------------------------------------------------------------------

def main(config):
    seed = config.get("seed") or ""
    if seed.isdigit():
        random.seed(int(seed))
    else:
        random.seed(time.now().unix)

    pid = config.get("pinata") or "random"
    if pid not in PINATAS:
        pid = pick(PINATA_IDS)
    sp = PINATAS[pid]
    mode = config.get("burst") or "sometimes"
    if mode == "always":
        will_burst = True
    elif mode == "never":
        will_burst = False
    else:
        will_burst = chance(0.6)
    burst_on_hit = random.number(3, 5)

    shift = random.number(0, 11)
    colors = dict(BASE_COLORS)
    colors.update(sp["colors"])
    paper = sp["stripes"] + CONES

    gw = len(sp["grid"][0])
    gh = len(sp["grid"])
    hook_x, hook_y = sp["hook"]
    rope_len = float(rest_hook_y(sp) - ANCHOR_Y)

    # Stick pivots sit off-screen at the bottom corners, like an unseen kid swinging.
    pivots = {1: (-6.0, H + 6.0), -1: (W + 6.0, H + 6.0)}
    rest_cx = ANCHOR_X - hook_x + gw / 2.0
    rest_cy = rest_hook_y(sp) - hook_y + gh / 2.0
    reach = {}
    for side in [1, -1]:
        pvx, pvy = pivots[side]
        reach[side] = math.sqrt((rest_cx - pvx) * (rest_cx - pvx) + (rest_cy - pvy) * (rest_cy - pvy)) + 4

    cur = [[r[i] for i in range(len(r))] for r in sp["grid"]]
    candy_shapes = CANDY_2X if SCALE == 2 else CANDY_1X
    ground_top = DEV_H - SCALE
    pile = [ground_top] * DEV_W

    static = render.Stack(children = [render.Box(width = DEV_W, height = DEV_H, color = "#000000")] + bunting() + ground())

    st = {
        "theta": rand(-0.2, 0.2),
        "omega": rand(-0.4, 0.4),
        "stick": "idle",
        "gap": random.number(3, 8),
        "side": 1,
        "angle": STICK_OUT,
        "hold": 0,
        "hits": 0,
        "burst": False,
        "sprite": None,
        "dirty": True,
        "jolt": 0,
        "settled": [],
        "settled_px": {},
        "settled_dirty": False,
    }
    bodies = []
    flying = []  # dicts: kind (paper|chunk|candy), x, y, vx, vy, ...
    pows = []

    def sprite_pos():
        hx = ANCHOR_X + rope_len * math.sin(st["theta"])
        hy = ANCHOR_Y + rope_len * math.cos(st["theta"])
        return hx, hy

    def spawn_paper(x, y, n, spread):
        for _ in range(n):
            flying.append({
                "kind": "paper",
                "x": x + rand(-spread, spread),
                "y": y + rand(-spread, spread),
                "vx": rand(-4, 4) + st["side"] * rand(0, 4),
                "vy": rand(-7, -1),
                "c": pick(paper),
                "ph": rand(0, 6.28),
                "bounced": True,
            })

    def burst(left, top, vx_pinata):
        st["burst"] = True
        below = gh - hook_y
        crack = hook_y + max(2, int(below * 0.4))

        # Everything below a jagged crack shatters into shards about 5x4 pixels.
        pieces = {}
        for x in range(gw):
            cy = crack + (1 if (x % 3 == 0) else 0) + random.number(0, 1)
            for y in range(cy, gh):
                if cur[y][x] != ".":
                    key = (x // 5, (y - crack) // 4)
                    pieces.setdefault(key, []).append((x, y, cur[y][x]))
                    cur[y][x] = "."

        # Anything no longer joined to the rope (say, a cactus arm tip) falls too.
        seen = {sp["hook"]: True}
        queue = [sp["hook"]]
        for _ in range(gw * gh):
            if not queue:
                break
            x, y = queue.pop()
            for dx in [-1, 0, 1]:
                for dy in [-1, 0, 1]:
                    nx = x + dx
                    ny = y + dy
                    if nx >= 0 and ny >= 0 and nx < gw and ny < gh and cur[ny][nx] != "." and (nx, ny) not in seen:
                        seen[(nx, ny)] = True
                        queue.append((nx, ny))
        for y in range(gh):
            for x in range(gw):
                if cur[y][x] != "." and (x, y) not in seen:
                    pieces.setdefault(("loose", x // 5, y // 4), []).append((x, y, cur[y][x]))
                    cur[y][x] = "."

        for pts in pieces.values():
            x0 = min([p[0] for p in pts])
            x1 = max([p[0] for p in pts])
            y0 = min([p[1] for p in pts])
            y1 = max([p[1] for p in pts])
            g = [["."] * (x1 - x0 + 1) for _ in range(y1 - y0 + 1)]
            bots = {}
            for x, y, ch in pts:
                g[y - y0][x - x0] = ch
                gx = x - x0
                gy = y - y0
                if gx not in bots or gy > bots[gx]:
                    bots[gx] = gy
            out = (x0 + x1) / 2.0 - gw / 2.0
            bodies.append({
                "w": sprite_widget(sp, colors, device_grid(g), shift, x0 * SCALE, y0 * SCALE),
                "x": left + x0,
                "y": top + y0,
                "pw": x1 - x0 + 1,
                "vx": out * 1.1 + rand(-3, 3) + vx_pinata * 0.2,
                "vy": rand(-7, -1),
                "bots": bots,
                "bounced": False,
                "landed": False,
            })
        n = random.number(18, 28)
        for _ in range(n):
            flying.append({
                "kind": "candy",
                "x": left + rand(2, gw - 3),
                "y": top + crack - 1,
                "vx": rand(-6, 6) + vx_pinata * 0.2,
                "vy": rand(-14, -2),
                "shape": random.number(0, len(candy_shapes) - 1),
                "c": pick(CANDY_COLORS),
                "bounced": False,
            })
        spawn_paper(left + gw / 2.0, top + crack, 22, gw / 3.0)

    def hit(contact, left, top):
        x, y, gx, gy = contact
        st["hits"] += 1
        st["omega"] += st["side"] * rand(0.8, 1.3)
        st["jolt"] = st["side"]
        vx_pinata = rope_len * st["omega"] * math.cos(st["theta"])
        big = False
        if will_burst and not st["burst"] and (st["hits"] >= burst_on_hit or (f_now[0] > 105 and st["hits"] >= 2)):
            burst(left, top, vx_pinata)
            big = True
        else:
            if chance(0.8):
                spawn_paper(x, y, random.number(2, 6), 1.5)
            if chance(0.45):
                for cx, cy, ch in chip(sp, cur, gx, gy, random.number(2, 4)):
                    flying.append({
                        "kind": "chunk",
                        "x": left + cx,
                        "y": top + cy,
                        "vx": st["side"] * rand(1, 5) + rand(-1, 1),
                        "vy": rand(-6, -1),
                        "c": pixel_color(sp, colors, ch, cx * SCALE, cy * SCALE, shift),
                        "bounced": False,
                    })
        st["dirty"] = True
        pows.append({"x": rnd(x * SCALE), "y": rnd(y * SCALE), "age": 0, "big": big})

    def settle_pixels(pattern_px):
        for k, v in pattern_px.items():
            st["settled_px"][k] = v
        st["settled_dirty"] = True

    def pile_top(dx, pw):
        return min([pile[min(max(c, 0), DEV_W - 1)] for c in range(dx, dx + pw)])

    def land(p, dx, dy, pw, ph):
        """Advance a falling item; returns True once it comes to rest."""
        top = pile_top(dx, pw)
        if p["vy"] <= 0 or dy + ph < top:
            return False
        if dy + ph > top + ph + SCALE:
            # Ran sideways into a heap that is taller than this item: bounce off it.
            p["vx"] = -p["vx"] * 0.4
            p["x"] -= 2 * p["vx"] * DT
            return False
        if not p["bounced"] and p["vy"] > 10:
            p["bounced"] = True
            p["vy"] = -p["vy"] * 0.3
            p["vx"] = p["vx"] * 0.5
            p["y"] = (top - ph) / float(SCALE)
            return False

        # Roll down the side of the heap until both neighbours are no lower.
        if p["kind"] != "paper":
            for _ in range(8 * SCALE):
                here = pile_top(dx, pw)
                lft = pile_top(dx - 1, pw) if dx > 0 else -1
                rgt = pile_top(dx + 1, pw) if dx + pw < DEV_W else -1
                if lft > here + 1 and lft >= rgt:
                    dx -= 1
                elif rgt > here + 1:
                    dx += 1
                else:
                    break
        top = pile_top(dx, pw)
        p["rest_x"] = dx
        p["rest_y"] = top - ph
        if p["kind"] != "paper":
            for c in range(max(dx, 0), min(dx + pw, DEV_W)):
                pile[c] = min(pile[c], top - ph)
        return True

    f_now = [0]
    frames = []
    for f in range(FRAMES):
        f_now[0] = f

        # Pendulum.
        for _ in range(4):
            h = DT / 4
            alpha = -SWING_K * math.sin(st["theta"]) - SWING_DAMP * st["omega"]
            st["omega"] += alpha * h
            st["theta"] += st["omega"] * h
        if st["theta"] > MAX_THETA:
            st["theta"] = MAX_THETA
            st["omega"] = -abs(st["omega"]) * 0.5
        if st["theta"] < -MAX_THETA:
            st["theta"] = -MAX_THETA
            st["omega"] = abs(st["omega"]) * 0.5

        hx, hy = sprite_pos()
        left = hx - hook_x
        top = hy - hook_y

        # Stick.
        state = st["stick"]
        side = st["side"]
        pvx, pvy = pivots[side]
        if state == "idle":
            if not st["burst"] and f < FRAMES - 25:
                st["gap"] -= 1
                if st["gap"] <= 0:
                    st["side"] = 1 if chance(0.5) else -1
                    st["stick"] = "enter"
                    st["angle"] = STICK_OUT
                    st["hold"] = 0
        elif state == "enter":
            st["angle"] -= 12
            if st["angle"] <= STICK_RAISED:
                st["angle"] = STICK_RAISED
                st["stick"] = "windup"
        elif state == "windup":
            st["hold"] += 1
            st["angle"] = STICK_RAISED + min(st["hold"] * 2, 10)
            near = abs(hx - ANCHOR_X) < 5
            if st["hold"] >= 3 and (near or st["hold"] >= 9):
                st["stick"] = "sweep"
        elif state == "sweep":
            a0 = st["angle"]
            target = a0 - 22
            found = None
            for k in range(1, 12):
                a = a0 - 2 * k
                if a < target:
                    break
                c = stick_contact(cur, left, top, pvx, pvy, side, a, reach[side])
                if c != None:
                    found = (a, c)
                    break
            if found != None:
                st["angle"] = found[0] + 2
                hit(found[1], left, top)
                st["stick"] = "recoil"
                st["hold"] = 0
            else:
                st["angle"] = target
                if target <= STICK_LOW:
                    st["stick"] = "retract"
        elif state == "recoil":
            st["hold"] += 1
            st["angle"] += 6
            if st["hold"] >= 2:
                st["stick"] = "retract"
        elif state == "retract":
            st["angle"] += 16
            if st["angle"] >= STICK_OUT:
                st["stick"] = "idle"
                st["gap"] = random.number(2, 9)

        # Shards falling after a burst.
        for b in bodies:
            if b["landed"]:
                continue
            b["vy"] += 60 * DT
            b["x"] += b["vx"] * DT
            b["y"] += b["vy"] * DT
            if b["x"] < 0:
                b["x"] = 0.0
                b["vx"] = abs(b["vx"]) * 0.4
            if b["x"] > W - b["pw"]:
                b["x"] = float(W - b["pw"])
                b["vx"] = -abs(b["vx"]) * 0.4
            bx = rnd(b["x"] * SCALE)
            by = rnd(b["y"] * SCALE)

            # Shards lie on the grass; candy may land on top of them later.
            limit = DEV_H
            for gx, gy in b["bots"].items():
                for k in range(SCALE):
                    c = bx + gx * SCALE + k
                    if c >= 0 and c < DEV_W:
                        limit = min(limit, ground_top - (gy + 1) * SCALE)
            if b["vy"] > 0 and by >= limit:
                if not b["bounced"] and b["vy"] > 12:
                    b["bounced"] = True
                    b["vy"] = -b["vy"] * 0.3
                    b["vx"] = b["vx"] * 0.5
                    b["y"] = limit / float(SCALE)
                    continue
                b["landed"] = True
                by = limit
                b["y"] = by / float(SCALE)

        # Paper, chunks and candy.
        still = []
        for p in flying:
            kind = p["kind"]
            if kind == "paper":
                p["vy"] = min(p["vy"] + 22 * DT, 5.0)
                p["vx"] = p["vx"] * 0.9
                p["x"] += (p["vx"] + 2.0 * math.sin(f * 0.5 + p["ph"])) * DT
                pw = 2 if SCALE == 2 else 1
                ph = 1
            else:
                p["vy"] += 60 * DT
                p["x"] += p["vx"] * DT
                if kind == "chunk":
                    pw = SCALE
                    ph = SCALE
                else:
                    shape = candy_shapes[p["shape"]]
                    pw = len(shape[0])
                    ph = len(shape)
            p["y"] += p["vy"] * DT
            maxx = W - pw / float(SCALE)
            if p["x"] < 0:
                p["x"] = 0.0
                p["vx"] = abs(p["vx"]) * 0.5
            if p["x"] > maxx:
                p["x"] = maxx
                p["vx"] = -abs(p["vx"]) * 0.5
            dx = rnd(p["x"] * SCALE)
            dy = rnd(p["y"] * SCALE)
            if land(p, dx, dy, pw, ph):
                px = {}
                if kind == "paper":
                    for k in range(pw):
                        px[(p["rest_x"] + k, p["rest_y"])] = p["c"]
                elif kind == "chunk":
                    for k in range(pw):
                        for j in range(ph):
                            px[(p["rest_x"] + k, p["rest_y"] + j)] = p["c"]
                else:
                    blit(px, candy_shapes[p["shape"]], p["rest_x"], p["rest_y"], p["c"])
                settle_pixels(px)
            else:
                p["dx"] = dx
                p["dy"] = dy
                still.append(p)
        flying.clear()
        flying.extend(still)

        # ---- Draw.
        if st["dirty"]:
            st["sprite"] = sprite_widget(sp, colors, device_grid(cur), shift)
            st["dirty"] = False
        if st["settled_dirty"]:
            st["settled"] = runs_to_widgets(st["settled_px"])
            st["settled_dirty"] = False

        kids = [static]
        kids.extend(st["settled"])
        for b in bodies:
            kids.append(at(rnd(b["x"] * SCALE), rnd(b["y"] * SCALE), b["w"]))
        hx_dev = rnd(hx * SCALE)
        hy_dev = rnd(hy * SCALE)
        kids.extend(rope(hx_dev, hy_dev))
        jolt = st["jolt"] * SCALE
        st["jolt"] = 0
        kids.append(at(hx_dev - hook_x * SCALE + jolt, hy_dev - hook_y * SCALE, st["sprite"]))

        front = {}
        for p in flying:
            kind = p["kind"]
            if kind == "paper":
                flip = (f + int(p["ph"] * 2)) % 4 < 2
                front[(p["dx"], p["dy"])] = p["c"]
                if SCALE == 2:
                    if flip:
                        front[(p["dx"] + 1, p["dy"])] = p["c"]
                    else:
                        front[(p["dx"], p["dy"] + 1)] = shade(p["c"], 0.7)
            elif kind == "chunk":
                for k in range(SCALE):
                    for j in range(SCALE):
                        front[(p["dx"] + k, p["dy"] + j)] = p["c"]
            else:
                blit(front, candy_shapes[p["shape"]], p["dx"], p["dy"], p["c"])
        if st["stick"] != "idle":
            draw_stick(front, pvx, pvy, st["side"], st["angle"], reach[st["side"]])
        live = []
        for pw_ in pows:
            draw_pow(front, pw_["x"], pw_["y"], pw_["age"], pw_["big"])
            pw_["age"] += 1
            if pw_["age"] < 3:
                live.append(pw_)
        pows.clear()
        pows.extend(live)
        kids.extend(runs_to_widgets(front))
        frames.append(render.Stack(children = kids))

    return render.Root(
        delay = DELAY,
        show_full_animation = True,
        child = render.Animation(children = frames),
    )

def get_schema():
    options = [schema.Option(display = "Random", value = "random")]
    for pid in PINATA_IDS:
        options.append(schema.Option(display = PINATAS[pid]["name"], value = pid))
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "pinata",
                name = "Pinata",
                desc = "Which pinata to smack. Random picks a new one each time.",
                icon = "star",
                default = "random",
                options = options,
            ),
            schema.Dropdown(
                id = "burst",
                name = "Burst open",
                desc = "How often the pinata breaks and spills candy.",
                icon = "candyCane",
                default = "sometimes",
                options = [
                    schema.Option(display = "Sometimes", value = "sometimes"),
                    schema.Option(display = "Every time", value = "always"),
                    schema.Option(display = "Never", value = "never"),
                ],
            ),
        ],
    )
