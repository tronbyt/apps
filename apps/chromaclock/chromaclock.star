"""
Applet: Chroma Clock
Summary: Stylish animated clock
Description: A clock with 23 looks, or a random one each time, from simple (outline, words, analog, dot grid, moon, world clocks) to animated (neon, morph, matrix, fire, pong, tetris, aquarium, snow, lava lamp, starfield, pac-man and more).
Author: alejoar
"""

load("math.star", "math")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

W = 64
H = 32

# 5x9 digit glyphs, drawn at 2x (10x18) for the big styles
GLYPHS = {
    "0": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "1": ["..#..", ".##..", "#.#..", "..#..", "..#..", "..#..", "..#..", "..#..", "#####"],
    "2": [".###.", "#...#", "....#", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
    "3": [".###.", "#...#", "....#", "....#", "..##.", "....#", "....#", "#...#", ".###."],
    "4": ["...#.", "..##.", ".#.#.", "#..#.", "#..#.", "#####", "...#.", "...#.", "...#."],
    "5": ["#####", "#....", "#....", "####.", "....#", "....#", "....#", "#...#", ".###."],
    "6": [".###.", "#....", "#....", "####.", "#...#", "#...#", "#...#", "#...#", ".###."],
    "7": ["#####", "....#", "....#", "...#.", "..#..", "..#..", ".#...", ".#...", ".#..."],
    "8": [".###.", "#...#", "#...#", "#...#", ".###.", "#...#", "#...#", "#...#", ".###."],
    "9": [".###.", "#...#", "#...#", "#...#", ".####", "....#", "....#", "...#.", ".##.."],
}

# 3x5 glyphs for small labels (AM/PM)
SMALL = {
    "0": ["###", "#.#", "#.#", "#.#", "###"],
    "1": [".#.", "##.", ".#.", ".#.", "###"],
    "2": ["###", "..#", "###", "#..", "###"],
    "3": ["###", "..#", ".##", "..#", "###"],
    "4": ["#.#", "#.#", "###", "..#", "..#"],
    "5": ["###", "#..", "###", "..#", "###"],
    "6": ["###", "#..", "###", "#.#", "###"],
    "7": ["###", "..#", ".#.", ".#.", ".#."],
    "8": ["###", "#.#", "###", "#.#", "###"],
    "9": ["###", "#.#", "###", "..#", "###"],
    "A": [".#.", "#.#", "###", "#.#", "#.#"],
    "P": ["##.", "#.#", "##.", "#..", "#.."],
    "M": ["#.#", "###", "###", "#.#", "#.#"],
}

DEFAULT_SECONDS = 15

# ---------- color helpers ----------

def clamp(v, lo, hi):
    return max(lo, min(hi, v))

HEX = "0123456789abcdef"

def hex2(v):
    v = int(clamp(v, 0, 255))
    return HEX[v // 16] + HEX[v % 16]

def pad2(v):
    return ("0" + str(v)) if v < 10 else str(v)

def hexc(rgb):
    return "#" + hex2(rgb[0]) + hex2(rgb[1]) + hex2(rgb[2])

def mix(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t)

def scale_rgb(a, k):
    return (a[0] * k, a[1] * k, a[2] * k)

def hsv(h, s, v):
    h = (h % 1.0) * 6.0
    i = int(h)
    f = h - i
    p = v * (1 - s)
    q = v * (1 - s * f)
    t = v * (1 - s * (1 - f))
    rgb = [(v, t, p), (q, v, p), (p, v, t), (p, q, v), (t, p, v), (v, p, q)][i % 6]
    return (rgb[0] * 255, rgb[1] * 255, rgb[2] * 255)

def parse_hex(s):
    s = s.lstrip("#")
    if len(s) == 3:
        s = s[0] * 2 + s[1] * 2 + s[2] * 2
    if len(s) < 6:
        return None
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16))

# ---------- pixel buffer ----------

def new_buf(color, w = W, h = H):
    return [[color for _ in range(w)] for _ in range(h)]

def put(buf, x, y, c):
    if y >= 0 and y < len(buf):
        row = buf[y]
        if x >= 0 and x < len(row):
            row[x] = c

def buf_to_widget(buf):
    # Run-length encode each row into boxes. 64x32 buffers are doubled on 2x
    # screens; the few styles drawn natively at 128x64 are used as-is.
    h = len(buf)
    w = len(buf[0])
    px = 2 if canvas.is2x() and w == W else 1
    rows = []
    for y in range(h):
        row = buf[y]
        children = []
        start = 0
        for x in range(1, w + 1):
            if x == w or row[x] != row[start]:
                if row[start] == None:
                    children.append(render.Box(width = (x - start) * px, height = px))
                else:
                    children.append(render.Box(width = (x - start) * px, height = px, color = hexc(row[start])))
                start = x
        rows.append(render.Row(children = children))
    return render.Column(children = rows)

# ---------- glyph layout ----------

def glyph_cells(text, glyphs, gw, gh, sc, gap, colon_w):
    """Returns (cells, width, height): cells are (x, y) pixels relative to origin."""
    cells = []
    x = 0
    for i, ch in enumerate(text.elems()):
        if ch == ":":
            x += colon_w
        elif ch == " ":
            x += gw * sc // 2
        else:
            g = glyphs[ch]
            for gy in range(gh):
                for gx in range(gw):
                    if g[gy][gx] == "#":
                        for dy in range(sc):
                            for dx in range(sc):
                                cells.append((x + gx * sc + dx, gy * sc + dy))
            x += gw * sc
        if i < len(text) - 1:
            x += gap
    return cells, x, gh * sc

def colon_cells(x, y, sc, h):
    # Two dots vertically placed at 1/3 and 2/3 of the digit height
    cells = []
    for cy in (h // 3 - sc // 2, (2 * h) // 3 - sc // 2):
        for dy in range(sc):
            for dx in range(sc):
                cells.append((x + dx, y + cy + dy))
    return cells

def time_parts(now, use_24h):
    hh = now.hour
    ampm = ""
    if not use_24h:
        ampm = "AM" if hh < 12 else "PM"
        hh = hh % 12
        if hh == 0:
            hh = 12
    hs = pad2(hh) if use_24h else str(hh)
    return hs, pad2(now.minute), ampm

def big_time_cells(now, use_24h, ox = None, oy = None):
    """Layout big 10x18 digits, centered. Returns digit cells, colon cells, ampm cells."""
    hs, ms, ampm = time_parts(now, use_24h)
    hcells, hw, gh = glyph_cells(hs, GLYPHS, 5, 9, 2, 2, 0)
    mcells, mw, _ = glyph_cells(ms, GLYPHS, 5, 9, 2, 2, 0)
    colon_w = 6
    total = hw + colon_w + mw
    x0 = (W - total) // 2 if ox == None else ox
    y0 = (H - gh) // 2 if oy == None else oy
    digits = [(x + x0, y + y0) for (x, y) in hcells] + [(x + x0 + hw + colon_w, y + y0) for (x, y) in mcells]
    colon = colon_cells(x0 + hw + 2, y0, 2, gh)
    return digits, colon, ampm, (x0, y0, total, gh)

# ---------- styles ----------

NEON_PALETTE = [
    # hour, color: midnight violet -> dawn pink -> morning amber -> noon cyan -> dusk orange -> night pink
    (0.0, (170, 80, 255)),
    (5.0, (255, 70, 170)),
    (8.0, (255, 170, 40)),
    (12.0, (40, 220, 255)),
    (17.0, (255, 120, 40)),
    (20.0, (255, 50, 130)),
    (24.0, (170, 80, 255)),
]

def neon_color(now):
    hf = now.hour + now.minute / 60.0
    for i in range(len(NEON_PALETTE) - 1):
        a = NEON_PALETTE[i]
        b = NEON_PALETTE[i + 1]
        if hf >= a[0] and hf <= b[0]:
            return mix(a[1], b[1], (hf - a[0]) / (b[0] - a[0]))
    return NEON_PALETTE[0][1]

def neon_shape(now, use_24h):
    """Lit pixels plus the inner and outer glow rings for the current time."""
    digits, colon, ampm, _ = big_time_cells(now, use_24h)
    lit = {}
    for c in digits:
        lit[c] = True
    if now.second % 2 == 0:
        for c in colon:
            lit[c] = True
    inner = {}
    outer = {}
    for (x, y) in lit:
        for dy in range(-2, 3):
            for dx in range(-2, 3):
                key = (x + dx, y + dy)
                if key in lit:
                    continue
                if max(abs(dx), abs(dy)) == 1:
                    inner[key] = True
                else:
                    outer[key] = True
    return lit.keys(), inner.keys(), [k for k in outer if k not in inner], ampm

def frame_neon(now, use_24h, base_rgb, sec_frac, show_seconds, memo):
    # The glow only changes when the time or colon does, so reuse it between frames
    key = time_label(now, use_24h, now.second % 2 == 0)
    if key not in memo:
        memo[key] = neon_shape(now, use_24h)
    lit, inner, outer, ampm = memo[key]
    color = base_rgb if base_rgb else neon_color(now)
    buf = new_buf((0, 0, 0))

    # Glow: dim halo around lit pixels, breathing slightly with the second
    pulse = 0.8 + 0.2 * math.cos(sec_frac * 2 * math.pi)
    glow_in = scale_rgb(color, 0.5 * pulse)
    glow_out = scale_rgb(color, 0.13 * pulse)
    for (x, y) in outer:
        put(buf, x, y, glow_out)
    for (x, y) in inner:
        put(buf, x, y, glow_in)

    # Tube: a pale, hot stroke inside the colored glow
    core = mix(color, (255, 255, 255), 0.5)
    for (x, y) in lit:
        put(buf, x, y, core)

    # Seconds as a thin scan line along the bottom
    if show_seconds:
        sx = int(now.second * W / 60)
        for x in range(sx):
            put(buf, x, H - 1, scale_rgb(color, 0.35))
        put(buf, sx, H - 1, core)

    if ampm:
        draw_small(buf, ampm, W - 8, 0, scale_rgb(color, 0.6))
    return buf

SKY = [
    # hour, top, bottom
    (0.0, (2, 3, 16), (8, 12, 40)),
    (4.5, (2, 3, 16), (10, 14, 44)),
    (6.0, (26, 30, 90), (240, 120, 80)),
    (7.5, (40, 100, 200), (250, 190, 140)),
    (10.0, (25, 105, 215), (130, 195, 250)),
    (16.0, (25, 105, 215), (130, 195, 250)),
    (18.5, (60, 50, 140), (255, 120, 70)),
    (20.0, (20, 16, 60), (90, 40, 90)),
    (21.5, (2, 3, 16), (8, 12, 40)),
    (24.0, (2, 3, 16), (8, 12, 40)),
]

def sky_at(hf):
    for i in range(len(SKY) - 1):
        a = SKY[i]
        b = SKY[i + 1]
        if hf >= a[0] and hf <= b[0]:
            t = (hf - a[0]) / (b[0] - a[0])
            return mix(a[1], b[1], t), mix(a[2], b[2], t)
    return SKY[0][1], SKY[0][2]

def hills_height(x):
    # Two layered sine hills
    far = 24 + 2.2 * math.sin(x * 0.19 + 1.3) + 1.2 * math.sin(x * 0.07)
    near = 27 + 1.8 * math.sin(x * 0.13 + 4.0) + 1.0 * math.sin(x * 0.31)
    return int(far), int(near)

def rnd(n):
    return ((n * 1103515245 + 12345) // 65536) % 32768

def frame_horizon(now, use_24h, sec_index):
    hf = now.hour + now.minute / 60.0 + now.second / 3600.0
    top, bottom = sky_at(hf)
    buf = new_buf((0, 0, 0))
    for y in range(H):
        c = mix(top, bottom, y / (H - 1.0))
        for x in range(W):
            buf[y][x] = c

    night = hf < 5.5 or hf > 20.5
    dusky = hf < 6.5 or hf > 19.5

    # Stars twinkle at night
    if dusky:
        for i in range(22):
            sx = rnd(i * 7 + 1) % W
            sy = rnd(i * 13 + 5) % 18
            tw = (rnd(i * 31 + sec_index * 17) % 10) / 10.0
            k = (0.35 + 0.65 * tw) * (1.0 if night else 0.4)
            put(buf, sx, sy, mix(buf[sy][sx], (255, 255, 230), k))

    # Sun by day (6-20h), moon by night, travelling an arc
    if hf >= 6 and hf <= 20:
        p = (hf - 6) / 14.0
        body = (255, 220, 90)
        glow = (255, 170, 60)
        r = 2
    else:
        p = ((hf - 20) % 24) / 10.0
        body = (235, 235, 255)
        glow = (140, 150, 220)
        r = 2
    cx = int(3 + p * (W - 7))
    cy = int(21 - 17 * math.sin(p * math.pi))
    for dy in range(-r - 2, r + 3):
        for dx in range(-r - 2, r + 3):
            d = math.sqrt(dx * dx + dy * dy)
            x = cx + dx
            y = cy + dy
            if x < 0 or x >= W or y < 0 or y >= H:
                continue
            if d <= r:
                put(buf, x, y, body)
            elif d <= r + 2:
                put(buf, x, y, mix(buf[y][x], glow, 0.45 * (1 - (d - r) / 2.5)))

    # Moon crescent: carve a shadow disc
    if not (hf >= 6 and hf <= 20):
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                if (dx - 1) * (dx - 1) + (dy + 1) * (dy + 1) <= r * r - 1:
                    x = cx + dx
                    y = cy + dy
                    if x >= 0 and x < W and y >= 0 and y < H:
                        buf[y][x] = mix(top, bottom, y / (H - 1.0))

    # Hills: far layer tinted by the sky, near layer darker
    far_c = mix(bottom, (10, 20, 18), 0.7)
    near_c = mix(bottom, (4, 8, 8), 0.88)
    for x in range(W):
        fy, ny = hills_height(x)
        for y in range(fy, H):
            buf[y][x] = far_c
        for y in range(ny, H):
            buf[y][x] = near_c

    # Time resting on the hills, small so the sky gets the room
    hs, ms, ampm = time_parts(now, use_24h)
    hcells, hw, gh = glyph_cells(hs, GLYPHS, 5, 9, 1, 1, 0)
    mcells, mw, _ = glyph_cells(ms, GLYPHS, 5, 9, 1, 1, 0)
    total = hw + 3 + mw + (13 if ampm else 0)
    x0 = (W - total) // 2
    y0 = H - gh - 1
    cells = [(x + x0, y + y0) for (x, y) in hcells] + [(x + x0 + hw + 3, y + y0) for (x, y) in mcells]
    if now.second % 2 == 0:
        cells += [(x0 + hw + 1, y0 + 2), (x0 + hw + 1, y0 + 6)]
    ink = mix(bottom, (255, 255, 255), 0.85)
    for (x, y) in cells:
        put(buf, x, y, ink)
    if ampm:
        draw_small(buf, ampm, x0 + hw + 3 + mw + 2, y0 + 4, mix(ink, near_c, 0.3))
    return buf

def frame_prism(now, use_24h, t, show_seconds):
    digits, colon, ampm, _ = big_time_cells(now, use_24h)
    buf = new_buf((0, 0, 0))

    # Faint diagonal shimmer in the background
    for y in range(H):
        for x in range(W):
            v = math.sin((x + y) * 0.35 - t * 4.0)
            if v > 0.92:
                buf[y][x] = hsv((x + y) / 80.0 - t * 0.1, 0.8, 0.12)

    show_colon = int(t * 2) % 2 == 0
    cells = digits + (colon if show_colon else [])
    for (x, y) in cells:
        h = (x * 0.9 + y * 0.6) / 64.0 - t * 0.25
        put(buf, x, y, hsv(h, 0.9, 1.0))
    if ampm:
        draw_small(buf, ampm, W - 8, 0, (180, 180, 180))

    # Seconds as a rainbow dot travelling along the bottom edge
    if show_seconds:
        sx = int(now.second * (W - 1) / 59)
        put(buf, sx, H - 1, hsv(sx / 64.0 - t * 0.25, 0.9, 1.0))
    return buf

def frame_flap(now, use_24h, base_rgb, flip_t, show_seconds):
    hs, ms, ampm = time_parts(now, use_24h)
    if len(hs) == 1:
        hs = " " + hs
    buf = new_buf((0, 0, 0))
    ink = base_rgb if base_rgb else (245, 240, 225)
    card_top = (38, 38, 44)
    card_bot = (28, 28, 33)

    # Four cards: 14x22 each, 1px gaps, wider gap in the middle for the colon
    xs = [1, 16, 34, 49]
    chars = [hs[0], hs[1], ms[0], ms[1]]
    y0 = 4
    cw = 14
    ch = 22
    for i in range(4):
        cx = xs[i]
        for y in range(ch):
            for x in range(cw):
                # Rounded corners
                if (x == 0 or x == cw - 1) and (y == 0 or y == ch - 1):
                    continue
                put(buf, cx + x, y0 + y, card_top if y < ch // 2 else card_bot)
        c = chars[i]
        if c != " ":
            g = GLYPHS[c]
            for gy in range(9):
                for gx in range(5):
                    if g[gy][gx] == "#":
                        for dy in range(2):
                            for dx in range(2):
                                put(buf, cx + 2 + gx * 2 + dx, y0 + 2 + gy * 2 + dy, ink)

        # Split line and hinge dots
        for x in range(cw):
            put(buf, cx + x, y0 + ch // 2, (0, 0, 0))
        put(buf, cx - 1, y0 + ch // 2, (70, 70, 78))
        put(buf, cx + cw, y0 + ch // 2, (70, 70, 78))

    # Flip animation on the minute's last card: top half folds down briefly
    if flip_t < 1.0:
        cx = xs[3]
        fold = int((ch // 2) * flip_t)
        for y in range(fold):
            for x in range(cw):
                put(buf, cx + x, y0 + y, (12, 12, 14))

    # Colon between hours and minutes
    col = (130, 125, 115) if now.second % 2 == 0 else (60, 58, 55)
    for cy in (y0 + 7, y0 + 14):
        for dy in range(2):
            for dx in range(2):
                put(buf, 31 + dx, cy + dy, col)

    # Seconds as a thin line under the cards
    if show_seconds:
        sx = int(now.second * 62 / 60)
        for x in range(1, 1 + sx):
            put(buf, x, 28, (70, 68, 64))
    if ampm:
        draw_small(buf, ampm, 28, 28 - 1, (120, 115, 105))
    return buf

def draw_small(buf, text, x, y, color):
    for ch in text.elems():
        g = SMALL[ch]
        for gy in range(5):
            for gx in range(3):
                if g[gy][gx] == "#":
                    put(buf, x + gx, y + gy, color)
        x += 4

# ---------- more styles ----------

# 3x5 letters for the Words style (N and W are wider)
LETTERS = {
    "A": [".#.", "#.#", "###", "#.#", "#.#"],
    "C": [".##", "#..", "#..", "#..", ".##"],
    "E": ["###", "#..", "##.", "#..", "###"],
    "F": ["###", "#..", "##.", "#..", "#.."],
    "G": [".##", "#..", "#.#", "#.#", ".##"],
    "H": ["#.#", "#.#", "###", "#.#", "#.#"],
    "I": ["###", ".#.", ".#.", ".#.", "###"],
    "K": ["#.#", "#.#", "##.", "#.#", "#.#"],
    "L": ["#..", "#..", "#..", "#..", "###"],
    "N": ["#..#", "##.#", "#.##", "#..#", "#..#"],
    "O": [".#.", "#.#", "#.#", "#.#", ".#."],
    "P": ["##.", "#.#", "##.", "#..", "#.."],
    "Q": [".#.", "#.#", "#.#", "##.", ".##"],
    "R": ["##.", "#.#", "##.", "#.#", "#.#"],
    "S": [".##", "#..", ".#.", "..#", "##."],
    "T": ["###", ".#.", ".#.", ".#.", ".#."],
    "U": ["#.#", "#.#", "#.#", "#.#", "###"],
    "V": ["#.#", "#.#", "#.#", "#.#", ".#."],
    "W": ["#...#", "#...#", "#.#.#", "##.##", "#...#"],
    "X": ["#.#", "#.#", ".#.", "#.#", "#.#"],
    "Y": ["#.#", "#.#", ".#.", ".#.", ".#."],
    "'": ["#", "#", ".", ".", "."],
}

HOUR_WORDS = ["TWELVE", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN"]
MINUTE_WORDS = {5: "FIVE", 10: "TEN", 15: "QUARTER", 20: "TWENTY", 25: "TWENTY FIVE", 30: "HALF"}

def text_width(text, sc):
    w = 0
    for i, ch in enumerate(text.elems()):
        w += (2 if ch == " " else len(LETTERS[ch][0])) * sc
        if i < len(text) - 1:
            w += sc
    return w

def draw_text(buf, text, x, y, sc, color):
    for ch in text.elems():
        if ch == " ":
            x += 3 * sc
            continue
        g = LETTERS[ch]
        for gy in range(5):
            for gx in range(len(g[0])):
                if g[gy][gx] == "#":
                    for dy in range(sc):
                        for dx in range(sc):
                            put(buf, x + gx * sc + dx, y + gy * sc + dy, color)
        x += (len(g[0]) + 1) * sc

def frame_words(now, base_rgb):
    m = now.minute
    five = m - m % 5
    hour = now.hour % 12
    accent = base_rgb if base_rgb else neon_color(now)
    white = (240, 236, 228)
    dim = (110, 108, 104)

    # Lines are (text, scale, color); the hour word is always big
    if five == 0:
        lines = [("IT'S", 1, dim), (HOUR_WORDS[hour], 2, accent), ("O'CLOCK", 1, white)]
    elif five <= 30:
        lines = [(MINUTE_WORDS[five], 1, white), ("PAST", 1, dim), (HOUR_WORDS[hour], 2, accent)]
    else:
        lines = [(MINUTE_WORDS[60 - five], 1, white), ("TO", 1, dim), (HOUR_WORDS[(hour + 1) % 12], 2, accent)]

    buf = new_buf((0, 0, 0))
    total = 0
    for (_, sc, _) in lines:
        total += 5 * sc + 2
    y = (H - total + 2) // 2
    for (text, sc, color) in lines:
        draw_text(buf, text, (W - text_width(text, sc)) // 2, y, sc, color)
        y += 5 * sc + 2

    # Extra minutes past the five as dots in the corner
    for i in range(m % 5):
        put(buf, W - 2 - i * 2, H - 2, accent)
    return buf

def ring_cells(cells):
    lit = {}
    for c in cells:
        lit[c] = True
    ring = {}
    for (x, y) in cells:
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                k = (x + dx, y + dy)
                if k not in lit:
                    ring[k] = True
    return ring.keys()

def frame_outline(now, use_24h, base_rgb, show_seconds):
    hs, ms, ampm = time_parts(now, use_24h)
    hcells, hw, gh = glyph_cells(hs, GLYPHS, 5, 9, 2, 3, 0)
    mcells, mw, _ = glyph_cells(ms, GLYPHS, 5, 9, 2, 5, 0)
    colon_w = 8
    total = hw + colon_w + mw
    x0 = (W - total) // 2
    y0 = (H - gh) // 2
    solid = (245, 240, 230)
    accent = base_rgb if base_rgb else neon_color(now)
    buf = new_buf((0, 0, 0))
    for (x, y) in hcells:
        put(buf, x + x0, y + y0, solid)
    mx = x0 + hw + colon_w
    for (x, y) in ring_cells(mcells):
        put(buf, x + mx, y + y0, accent)
    for (x, y) in mcells:
        put(buf, x + mx, y + y0, scale_rgb(accent, 0.18))
    if now.second % 2 == 0:
        for (x, y) in colon_cells(x0 + hw + 2, y0, 2, gh):
            put(buf, x, y, scale_rgb(solid, 0.7))
    if show_seconds:
        sx = int(now.second * W / 60)
        for x in range(sx):
            put(buf, x, H - 1, scale_rgb(accent, 0.4))
    if ampm:
        draw_small(buf, ampm, W - 8, 0, scale_rgb(solid, 0.5))
    return buf

def frame_binary(now, use_24h):
    hh = now.hour
    if not use_24h:
        hh = hh % 12
        if hh == 0:
            hh = 12
    groups = [(hh, (255, 80, 160)), (now.minute, (40, 210, 255)), (now.second, (255, 180, 40))]
    buf = new_buf((0, 0, 0))

    # Six columns of 4 bits (tens and ones per group), 4x4 dots with 1px gaps
    dot = 4
    step = dot + 1
    group_gap = 4
    width = 6 * step - 1 + 2 * group_gap
    x = (W - width) // 2
    top = 1
    for (value, color) in groups:
        for d in (value // 10, value % 10):
            for bit in range(4):
                y = top + (3 - bit) * step
                on = (d >> bit) & 1 == 1
                c = color if on else scale_rgb(color, 0.13)
                for dy in range(dot):
                    for dx in range(dot):
                        # Round the corners a little
                        if (dx == 0 or dx == dot - 1) and (dy == 0 or dy == dot - 1):
                            continue
                        put(buf, x + dx, y + dy, c)
            x += step

        # Label the group with its decimal value
        lx = x - 2 * step + (2 * step - 1 - 7) // 2
        draw_small(buf, pad2(value), lx, 26, scale_rgb(color, 0.75))
        x += group_gap
    return buf

def noise(a, b, c):
    n = (a * 73856093) ^ (b * 19349663) ^ (c * 83492791)
    n = (n ^ (n >> 13)) * 1274126177
    return ((n ^ (n >> 16)) & 1023) / 1023.0

def frame_matrix(now, use_24h, frame):
    digits, colon, ampm, _ = big_time_cells(now, use_24h)
    buf = new_buf((0, 0, 0))

    # Code rain on every other column, each with its own speed and trail
    for col in range(0, W, 2):
        speed = 0.35 + 0.65 * noise(col, 1, 7)
        trail = 6 + int(10 * noise(col, 2, 7))
        cycle = H + trail + int(20 * noise(col, 3, 7))
        head = int(noise(col, 4, 7) * cycle + frame * speed) % cycle
        for d in range(trail):
            y = head - d
            if y < 0 or y >= H:
                continue
            k = 1.0 - d / float(trail)
            flicker = 0.7 + 0.3 * noise(col, y, frame // 2)
            buf[y][col] = (200, 255, 200) if d == 0 else (20 * k, 220 * k * flicker, 70 * k * flicker)

    # Digits: pale green with a black keep-out ring so they read through the rain
    cells = digits + (colon if now.second % 2 == 0 else [])
    for (x, y) in ring_cells(cells):
        put(buf, x, y, (0, 0, 0))
    for (x, y) in cells:
        put(buf, x, y, (170, 255, 170))
    if ampm:
        draw_small(buf, ampm, W - 8, 0, (60, 180, 80))
    return buf

FIRE_STOPS = [
    (0.0, (0, 0, 0)),
    (0.18, (50, 0, 0)),
    (0.38, (170, 25, 0)),
    (0.58, (255, 100, 0)),
    (0.78, (255, 190, 40)),
    (1.0, (255, 250, 200)),
]

def fire_color(h):
    if h <= 0:
        return (0, 0, 0)
    for i in range(len(FIRE_STOPS) - 1):
        a = FIRE_STOPS[i]
        b = FIRE_STOPS[i + 1]
        if h <= b[0]:
            return mix(a[1], b[1], (h - a[0]) / (b[0] - a[0]))
    return FIRE_STOPS[-1][1]

def fire_step(heat, seeds, f):
    # Classic "doom fire": each cell takes heat from below, drifting sideways and cooling
    bottom = heat[H]
    for x in range(W):
        bottom[x] = 0.7 + 0.3 * noise(x, 99, f)
    seed = (f * 2654435761 + 12345) & 0x7fffffff
    for y in range(H):
        row = heat[y]
        below = heat[y + 1]
        for x in range(W):
            # Cheap LCG: low bits pick the drift, high bits the cooling
            seed = (seed * 1103515245 + 12345) & 0x7fffffff
            sx = x + (seed >> 4) % 3 - 1
            if sx < 0:
                sx = 0
            elif sx >= W:
                sx = W - 1
            v = below[sx] - 0.035 - ((seed >> 16) & 255) * 0.00026
            row[x] = v if v > 0 else 0
    for (x, y) in seeds:
        if y >= 0 and y < H and x >= 0 and x < W:
            heat[y][x] = max(heat[y][x], 0.45 + 0.25 * noise(x, y, f + 5))

def frame_fire(now, use_24h, heat, f):
    digits, colon, ampm, _ = big_time_cells(now, use_24h, oy = 9)
    cells = digits + (colon if now.second % 2 == 0 else [])

    # Flames also lick off the top edges of the digits
    lit = {}
    for c in cells:
        lit[c] = True
    seeds = [(x, y - 1) for (x, y) in cells if (x, y - 1) not in lit]
    fire_step(heat, seeds, f)

    buf = [[fire_color(heat[y][x]) for x in range(W)] for y in range(H)]
    for (x, y) in ring_cells(cells):
        put(buf, x, y, (25, 4, 0))
    for (x, y) in cells:
        put(buf, x, y, (255, 245, 215))
    if ampm:
        draw_small(buf, ampm, W - 8, 0, (255, 200, 120))
    return buf

# Seven-segment digits for the Morph style
def seg_rects(w, h, t):
    """Segment rectangles (x0, y0, x1, y1), inclusive, for a w x h digit with strokes t px thick."""
    mid = h // 2 - t // 2
    return {
        "a": (1, 0, w - 2, t - 1),
        "b": (w - t, 1, w - 1, h // 2),
        "c": (w - t, h // 2, w - 1, h - 2),
        "d": (1, h - t, w - 2, h - 1),
        "e": (0, h // 2, t - 1, h - 2),
        "f": (0, 1, t - 1, h // 2),
        "g": (1, mid, w - 2, mid + t - 1),
    }

# With seconds: 8x17 digits, 2px strokes. Without: bigger 12x24 digits, 3px strokes.
SEG_SMALL = (8, 17, 2)
SEG_BIG = (12, 24, 3)

DIGIT_SEGMENTS = {
    "0": "abcdef",
    "1": "bc",
    "2": "abged",
    "3": "abgcd",
    "4": "fgbc",
    "5": "afgcd",
    "6": "afgedc",
    "7": "abc",
    "8": "abcdefg",
    "9": "abcdfg",
    " ": "",
}

def draw_segment(buf, ox, oy, rect, p, color):
    """Draw a segment scaled to fraction p (0..1) of its length, around its center."""
    x0, y0, x1, y1 = rect
    if p <= 0:
        return
    if x1 - x0 > y1 - y0:
        length = x1 - x0 + 1
        keep = max(1, int(length * p + 0.5))
        x0 = x0 + (length - keep) // 2
        x1 = x0 + keep - 1
    else:
        length = y1 - y0 + 1
        keep = max(1, int(length * p + 0.5))
        y0 = y0 + (length - keep) // 2
        y1 = y0 + keep - 1
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(buf, ox + x, oy + y, color)

def ease(t):
    t = clamp(t, 0.0, 1.0)
    return t * t * (3 - 2 * t)

def draw_morph_digit(buf, ox, oy, rects, old, new, t, color):
    old_segs = DIGIT_SEGMENTS[old]
    new_segs = DIGIT_SEGMENTS[new]
    for seg in "abcdefg".elems():
        was = seg in old_segs
        now_on = seg in new_segs
        if was and now_on:
            draw_segment(buf, ox, oy, rects[seg], 1.0, color)
        elif now_on:
            # Grow in during the second half of the morph
            draw_segment(buf, ox, oy, rects[seg], ease(t * 2 - 1), color)
        elif was:
            # Shrink away during the first half
            draw_segment(buf, ox, oy, rects[seg], 1 - ease(t * 2), color)

def morph_text(now, use_24h):
    hs, ms, ampm = time_parts(now, use_24h)
    if len(hs) == 1:
        hs = " " + hs
    return hs + ms + pad2(now.second), ampm

def frame_morph(now, use_24h, base_rgb, sub, show_secs):
    """sub is the fraction of the current second elapsed (0..1)."""
    text, ampm = morph_text(now, use_24h)
    prev, _ = morph_text(now - time.parse_duration("1s"), use_24h)
    t = sub / 0.6
    color = base_rgb if base_rgb else neon_color(now)
    sec_color = scale_rgb(color, 0.6)
    colon_color = scale_rgb(color, 0.55)
    buf = new_buf((0, 0, 0))

    # HH:MM:SS (small digits) or HH:MM (big digits); pairs 1-2px apart, a colon between pairs
    sw, sh, st = SEG_BIG if not show_secs else SEG_SMALL
    rects = seg_rects(sw, sh, st)
    count = 6 if show_secs else 4
    pair_gap = 1 if show_secs else 2
    colon_w = 4 if show_secs else 6
    dot = st
    total = count * sw + (count // 2) * pair_gap + (count // 2 - 1) * colon_w
    x = (W - total) // 2
    oy = (H - sh) // 2

    # Leave room for the AM/PM tag above the big digits
    if ampm and not show_secs:
        oy += 2
    for i in range(count):
        c = color if i < 4 else sec_color
        old = prev[i]
        new = text[i]
        if old == new:
            draw_morph_digit(buf, x, oy, rects, new, new, 1.0, c)
        else:
            draw_morph_digit(buf, x, oy, rects, old, new, t, c)
        x += sw
        if i % 2 == 0:
            x += pair_gap
        elif i < count - 1:
            cx = x + (colon_w - dot) // 2
            for cy in (oy + sh // 3 - dot // 2, oy + (2 * sh) // 3 - dot // 2):
                for dy in range(dot):
                    for dx in range(dot):
                        put(buf, cx + dx, cy + dy, colon_color)
            x += colon_w
    if ampm:
        draw_small(buf, ampm, W - 8, 0, scale_rgb(color, 0.5))
    return buf

# ---------- even more styles ----------

EXTRA_LETTERS = {
    "B": ["##.", "#.#", "##.", "#.#", "##."],
    "D": ["##.", "#.#", "#.#", "#.#", "##."],
    "J": ["..#", "..#", "..#", "#.#", ".#."],
    "M": ["#...#", "##.##", "#.#.#", "#...#", "#...#"],
    "Z": ["###", "..#", ".#.", "#..", "###"],
    "%": ["#.#", "..#", ".#.", "#..", "#.#"],
    ":": [".", "#", ".", "#", "."],
    "+": ["...", ".#.", "###", ".#.", "..."],
    "-": ["...", "...", "###", "...", "..."],
}

# Every 3x5 glyph in one table: letters, digits, and punctuation
TINY = dict(LETTERS.items() + SMALL.items() + EXTRA_LETTERS.items())

WEEKDAYS = {"Mon": 0, "Tue": 1, "Wed": 2, "Thu": 3, "Fri": 4, "Sat": 5, "Sun": 6}

def tiny_width(text, sc = 1):
    w = 0
    for i, ch in enumerate(text.elems()):
        w += 2 if ch == " " else len(TINY[ch][0])
        if i < len(text) - 1:
            w += 1
    return w * sc

def draw_tiny(buf, text, x, y, color, sc = 1):
    for ch in text.elems():
        if ch == " ":
            x += 3 * sc
            continue
        g = TINY[ch]
        for gy in range(5):
            for gx in range(len(g[0])):
                if g[gy][gx] == "#":
                    for dy in range(sc):
                        for dx in range(sc):
                            put(buf, x + gx * sc + dx, y + gy * sc + dy, color)
        x += (len(g[0]) + 1) * sc

def draw_tiny_centered(buf, text, cx, y, color, sc = 1):
    draw_tiny(buf, text, cx - tiny_width(text, sc) // 2, y, color, sc)

def iround(v):
    return int(math.floor(v + 0.5))

def draw_line(buf, x0, y0, x1, y1, color):
    # Bresenham
    dx = abs(x1 - x0)
    dy = -abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx + dy
    for _ in range(256):
        put(buf, x0, y0, color)
        if x0 == x1 and y0 == y1:
            break
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy

def time_label(now, use_24h, colon = True):
    hs, ms, _ = time_parts(now, use_24h)
    return hs + (":" if colon else " ") + ms

def draw_mid_time(buf, now, use_24h, x, y, color, colon = True, sc = 1):
    """5x9 time (HH:MM) at the given scale, top-left at (x, y). Returns its width."""
    hs, ms, _ = time_parts(now, use_24h)
    hcells, hw, _ = glyph_cells(hs, GLYPHS, 5, 9, sc, sc, 0)
    mcells, mw, _ = glyph_cells(ms, GLYPHS, 5, 9, sc, sc, 0)
    for (cx, cy) in hcells:
        put(buf, x + cx, y + cy, color)
    for (cx, cy) in mcells:
        put(buf, x + hw + 3 * sc + cx, y + cy, color)
    if colon:
        for cy in (2, 6):
            for dy in range(sc):
                for dx in range(sc):
                    put(buf, x + hw + sc + dx, y + cy * sc + dy, color)
    return hw + 3 * sc + mw

def mid_time_width(now, use_24h, sc = 1):
    hs, ms, _ = time_parts(now, use_24h)
    return glyph_cells(hs, GLYPHS, 5, 9, sc, sc, 0)[1] + 3 * sc + glyph_cells(ms, GLYPHS, 5, 9, sc, sc, 0)[1]

def draw_big_time(buf, now, use_24h, color, ring = None, oy = None):
    digits, colon, ampm, box = big_time_cells(now, use_24h, oy = oy)
    cells = digits + (colon if now.second % 2 == 0 else [])
    if ring:
        for (x, y) in ring_cells(cells):
            put(buf, x, y, ring)
    for (x, y) in cells:
        put(buf, x, y, color)
    if ampm:
        draw_small(buf, ampm, W - 8, 0, scale_rgb(color, 0.6))
    return box

# --- Analog ---

def frame_analog(now, use_24h, base_rgb, sub):
    accent = base_rgb if base_rgb else neon_color(now)
    buf = new_buf((0, 0, 0))
    cx = 15.5
    cy = 15.5

    # Faint rim and hour ticks
    for i in range(120):
        a = i * math.pi / 60
        put(buf, iround(cx + 15 * math.sin(a) - 0.5), iround(cy - 15 * math.cos(a) - 0.5), (30, 30, 38))
    for h in range(12):
        a = h * math.pi / 6
        major = h % 3 == 0
        for r in ([13.0, 12.0] if major else [13.0]):
            put(buf, iround(cx + r * math.sin(a) - 0.5), iround(cy - r * math.cos(a) - 0.5), (200, 200, 205) if major else (90, 90, 100))

    def hand(angle, length, color):
        x1 = iround(cx + length * math.sin(angle) - 0.5)
        y1 = iround(cy - length * math.cos(angle) - 0.5)
        draw_line(buf, 15, 15, x1, y1, color)

    secs = now.second + sub
    hand((now.hour % 12 + now.minute / 60.0) * math.pi / 6, 7, (240, 236, 228))
    hand((now.minute + secs / 60.0) * math.pi / 30, 11, (240, 236, 228))
    hand(secs * math.pi / 30, 12, accent)
    put(buf, 15, 15, accent)

    # Digital time and date on the right
    right = 48
    tw = mid_time_width(now, use_24h)
    draw_mid_time(buf, now, use_24h, right - tw // 2, 6, (240, 236, 228), now.second % 2 == 0)
    date = now.format("Mon").upper() + " " + str(now.day)
    draw_tiny_centered(buf, date, right, 20, accent)
    _, _, ampm = time_parts(now, use_24h)
    if ampm:
        draw_tiny_centered(buf, ampm, right, 26, (110, 108, 104))
    return buf

# --- Big hour ---

def frame_bighour(now, use_24h, base_rgb, sub):
    accent = base_rgb if base_rgb else neon_color(now)
    hs, _, ampm = time_parts(now, use_24h)
    buf = new_buf((0, 0, 0))

    # The hour, huge
    cells, hw, gh = glyph_cells(hs, GLYPHS, 5, 9, 3, 3, 0)
    x0 = (40 - hw) // 2
    y0 = (H - gh) // 2
    for (x, y) in cells:
        put(buf, x0 + x, y0 + y, (245, 240, 230))
    if ampm:
        draw_tiny(buf, ampm, 40, 26, (110, 108, 104))

    # Minutes as a 6x10 grid of dots that fills up; the next one pulses
    gx0 = W - 18
    gy0 = 1
    pulse = 0.25 + 0.5 * (0.5 + 0.5 * math.cos(sub * 2 * math.pi))
    for i in range(60):
        col = i % 6
        row = i // 6
        if i < now.minute:
            c = accent
        elif i == now.minute:
            c = scale_rgb(accent, pulse)
        else:
            c = scale_rgb(accent, 0.12)
        for dy in range(2):
            for dx in range(2):
                put(buf, gx0 + col * 3 + dx, gy0 + row * 3 + dy, c)
    return buf

# --- Dot grid ---

def frame_dotgrid(now, use_24h, base_rgb):
    on = base_rgb if base_rgb else (255, 170, 40)
    off = scale_rgb(on, 0.12)
    hs, ms, ampm = time_parts(now, use_24h)
    hcells, hw, _ = glyph_cells(hs, GLYPHS, 5, 9, 1, 1, 0)
    mcells, mw, _ = glyph_cells(ms, GLYPHS, 5, 9, 1, 1, 0)

    # The time in 5x9 glyphs on a 32x16 grid of dots
    lit = {}
    col0 = (32 - (hw + 3 + mw)) // 2
    row0 = 3
    for (x, y) in hcells:
        lit[(col0 + x, row0 + y)] = True
    for (x, y) in mcells:
        lit[(col0 + hw + 3 + x, row0 + y)] = True
    if now.second % 2 == 0:
        lit[(col0 + hw + 1, row0 + 2)] = True
        lit[(col0 + hw + 1, row0 + 6)] = True

    buf = new_buf((0, 0, 0))
    for row in range(16):
        for col in range(32):
            put(buf, col * 2, row * 2, on if (col, row) in lit else off)
    if ampm:
        draw_tiny(buf, ampm, W - 8, H - 6, scale_rgb(on, 0.6))
    return buf

# --- Moon ---

MOON_PHASES = [
    (0.03, "NEW", "MOON"),
    (0.22, "WAXING", "CRESCENT"),
    (0.28, "FIRST", "QUARTER"),
    (0.47, "WAXING", "GIBBOUS"),
    (0.53, "FULL", "MOON"),
    (0.72, "WANING", "GIBBOUS"),
    (0.78, "LAST", "QUARTER"),
    (0.97, "WANING", "CRESCENT"),
    (1.01, "NEW", "MOON"),
]

def moon_phase(now):
    # Days since a known new moon (2000-01-06 18:14 UTC) over the synodic month
    days = (now.unix - 947182440) / 86400.0
    return (days % 29.530588853) / 29.530588853

def moon_cells(p):
    cells = []
    cx = 15.5
    cy = 16.0
    r = 12.0
    k = math.cos(2 * math.pi * p)
    craters = [(-4.0, -3.0, 2.0), (3.0, 2.0, 2.5), (-2.0, 5.0, 1.5), (5.0, -5.0, 1.5)]
    for y in range(3, 30):
        for x in range(2, 30):
            nx = (x + 0.5 - cx) / r
            ny = (y + 0.5 - cy) / r
            d2 = nx * nx + ny * ny
            if d2 > 1:
                continue
            w = math.sqrt(1 - ny * ny)
            u = nx / w if w > 0 else 0
            lit = u > k if p < 0.5 else u < -k
            if lit:
                c = scale_rgb((238, 234, 214), 0.72 + 0.28 * math.sqrt(1 - d2))
                for (qx, qy, qr) in craters:
                    if (x + 0.5 - cx - qx) * (x + 0.5 - cx - qx) + (y + 0.5 - cy - qy) * (y + 0.5 - cy - qy) <= qr * qr:
                        c = scale_rgb(c, 0.8)
            else:
                c = (20, 22, 32)
            cells.append((x, y, c))
    return cells

def frame_moon(now, use_24h, p, frame):
    buf = new_buf((0, 0, 0))

    # Twinkling stars behind everything
    for i in range(14):
        sx = rnd(i * 7 + 3) % W
        sy = rnd(i * 13 + 9) % H
        tw = noise(i, frame // 2, 11)
        put(buf, sx, sy, scale_rgb((255, 255, 230), 0.15 + 0.5 * tw))

    right = 47
    tw = mid_time_width(now, use_24h)
    draw_mid_time(buf, now, use_24h, right - tw // 2, 4, (240, 236, 228), now.second % 2 == 0)
    for (limit, a, b) in MOON_PHASES:
        if p < limit:
            draw_tiny_centered(buf, a, right, 18, (200, 196, 180))
            draw_tiny_centered(buf, b, right, 24, (140, 138, 128))
            break
    return buf

# --- Day progress ---

def frame_dayprogress(now, use_24h, tz):
    buf = new_buf((0, 0, 0))
    secs = now.hour * 3600 + now.minute * 60 + now.second
    day_frac = secs / 86400.0
    wd = WEEKDAYS.get(now.format("Mon"), 0)
    week_frac = (wd + day_frac) / 7.0
    month_start = time.time(year = now.year, month = now.month, day = 1, location = tz)
    next_month = time.time(year = now.year + (1 if now.month == 12 else 0), month = 1 if now.month == 12 else now.month + 1, day = 1, location = tz)
    month_frac = (now.unix - month_start.unix) / float(next_month.unix - month_start.unix)
    year_start = time.time(year = now.year, month = 1, day = 1, location = tz)
    next_year = time.time(year = now.year + 1, month = 1, day = 1, location = tz)
    year_frac = (now.unix - year_start.unix) / float(next_year.unix - year_start.unix)

    draw_mid_time(buf, now, use_24h, 1, 1, (240, 236, 228), now.second % 2 == 0)
    date = now.format("Mon").upper() + " " + str(now.day)
    draw_tiny(buf, date, W - 1 - tiny_width(date), 3, (140, 138, 128))

    bars = [
        ("DAY", day_frac, (255, 180, 40)),
        ("WK", week_frac, (40, 210, 255)),
        ("MO", month_frac, (255, 80, 160)),
        ("YR", year_frac, (90, 230, 120)),
    ]
    y = 12
    for (label, frac, color) in bars:
        draw_tiny(buf, label, 1, y, scale_rgb(color, 0.8))
        bx0 = 14
        bx1 = 49
        fill = int((bx1 - bx0 + 1) * frac)
        for x in range(bx0, bx1 + 1):
            c = color if x - bx0 < fill else scale_rgb(color, 0.14)
            for dy in range(1, 4):
                put(buf, x, y + dy, c)
        pct = str(int(frac * 100)) + "%"
        draw_tiny(buf, pct, W - tiny_width(pct), y, scale_rgb(color, 0.8))
        y += 5
    return buf

# --- World clocks ---

WORLD_ZONES = [
    # code shown on the display, time zone, name shown in the settings
    ("NYC", "America/New_York", "New York"),
    ("CHI", "America/Chicago", "Chicago"),
    ("LAX", "America/Los_Angeles", "Los Angeles"),
    ("MEX", "America/Mexico_City", "Mexico City"),
    ("SAO", "America/Sao_Paulo", "São Paulo"),
    ("BUE", "America/Argentina/Buenos_Aires", "Buenos Aires"),
    ("LON", "Europe/London", "London"),
    ("MAD", "Europe/Madrid", "Madrid"),
    ("PAR", "Europe/Paris", "Paris"),
    ("BER", "Europe/Berlin", "Berlin"),
    ("DXB", "Asia/Dubai", "Dubai"),
    ("DEL", "Asia/Kolkata", "New Delhi"),
    ("SGP", "Asia/Singapore", "Singapore"),
    ("HKG", "Asia/Hong_Kong", "Hong Kong"),
    ("TYO", "Asia/Tokyo", "Tokyo"),
    ("SYD", "Australia/Sydney", "Sydney"),
    ("UTC", "UTC", "UTC"),
]

def frame_world(now, use_24h, base_rgb, zones):
    accent = base_rgb if base_rgb else neon_color(now)
    buf = new_buf((0, 0, 0))
    draw_big_time(buf, now, use_24h, (245, 240, 230), oy = 1)

    # Up to three other cities underneath: code on top, time below
    for i, (code, zone) in enumerate(zones):
        cx = 10 + i * 22
        other = now.in_location(zone)
        draw_tiny_centered(buf, code, cx, 21, accent)
        draw_tiny_centered(buf, time_label(other, use_24h), cx, 27, (200, 196, 188))
    return buf

# --- Pong ---

def pong_frames(now, use_24h, count, step):
    bx = 32.0
    by = 8.0 + 16 * noise(now.second, 1, 5)
    vx = 2.0 if now.second % 2 == 0 else -2.0
    vy = 1.1 if now.minute % 2 == 0 else -1.1
    lp = 13.0
    rp = 13.0
    ph = 6
    bufs = []
    for i in range(count):
        fnow = now + time.parse_duration("%dms" % (i * step))

        # The hour side lets the ball through as the minute turns over
        miss = fnow.second >= 57

        def track(p, toward):
            target = by - ph / 2.0 if toward else 13.0
            if miss and toward and vx < 0:
                target = 0 if by > 16 else 26
            return p + clamp(target - p, -1.3, 1.3)

        lp = clamp(track(lp, vx < 0), 0, H - ph)
        rp = clamp(track(rp, vx > 0), 0, H - ph)

        bx += vx
        by += vy
        if by < 0:
            by = -by
            vy = -vy
        elif by > H - 1:
            by = 2 * (H - 1) - by
            vy = -vy
        if vx < 0 and bx <= 2 and bx > 0:
            if by >= lp - 1 and by <= lp + ph:
                bx = 2 + (2 - bx)
                vx = -vx
                vy = clamp(vy + (by - (lp + ph / 2.0)) * 0.25, -1.8, 1.8)
        elif vx > 0 and bx >= 61 and bx < 63:
            if by >= rp - 1 and by <= rp + ph:
                bx = 61 - (bx - 61)
                vx = -vx
                vy = clamp(vy + (by - (rp + ph / 2.0)) * 0.25, -1.8, 1.8)
        if bx < -2 or bx > W + 1:
            # Point scored: serve again from the middle
            bx = 32.0
            by = 16.0
            vx = -vx

        buf = new_buf((0, 0, 0))
        for y in range(0, H, 4):
            put(buf, 31, y, (60, 60, 60))
            put(buf, 31, y + 1, (60, 60, 60))
        hs, ms, _ = time_parts(fnow, use_24h)
        for (text, center) in ((hs, 16), (ms, 47)):
            cells, tw, _ = glyph_cells(text, GLYPHS, 5, 9, 1, 1, 0)
            for (x, y) in cells:
                put(buf, center - tw // 2 + x, 2 + y, (120, 120, 120))
        for dy in range(ph):
            put(buf, 1, int(lp) + dy, (240, 240, 240))
            put(buf, 62, int(rp) + dy, (240, 240, 240))
        put(buf, iround(bx), iround(by), (255, 255, 255))
        bufs.append(buf)
    return bufs

# --- Tetris ---

TETRIS_COLORS = [(0, 220, 230), (240, 220, 0), (170, 60, 240), (40, 220, 60), (240, 60, 60), (50, 90, 240), (250, 150, 0)]

def tetris_blocks(now, use_24h):
    """Returns blocks (tx, ty, color) on a 2px grid, bottom rows first."""
    hs, ms, _ = time_parts(now, use_24h)
    text = hs + ms
    x0 = (W - (len(text) * 12 + 4)) // 2
    blocks = []
    for i, ch in enumerate(text.elems()):
        g = GLYPHS[ch]
        dx = x0 + i * 12 + (4 if i >= len(hs) else 0)
        color = TETRIS_COLORS[(int(ch) * 3 + i) % len(TETRIS_COLORS)]
        for gy in range(9):
            for gx in range(5):
                if g[gy][gx] == "#":
                    blocks.append((dx + gx * 2, 7 + gy * 2, color))
    return sorted(blocks, key = lambda b: (-b[1], b[0])), x0 + len(hs) * 12

def draw_block(buf, x, y, color):
    put(buf, x, y, mix(color, (255, 255, 255), 0.45))
    put(buf, x + 1, y, color)
    put(buf, x, y + 1, color)
    put(buf, x + 1, y + 1, scale_rgb(color, 0.6))

def frame_tetris(now, blocks, colon_x, t):
    buf = new_buf((0, 0, 0))

    # Well walls
    for y in range(H):
        put(buf, 0, y, (50, 50, 60))
        put(buf, W - 1, y, (50, 50, 60))

    # Blocks drop in one after another, bottom rows first
    for k, (tx, ty, color) in enumerate(blocks):
        start = k * 0.035
        if t < start:
            break
        y = min(ty, iround(-2 + (t - start) * 60))
        draw_block(buf, tx, y, color)
    built = t > len(blocks) * 0.035 + 0.6
    if built and now.second % 2 == 0:
        draw_block(buf, colon_x, 12, (200, 200, 210))
        draw_block(buf, colon_x, 20, (200, 200, 210))
    return buf

# --- Aquarium ---

FISH = [
    # y, speed px/s, direction, color, start offset
    (13, 6.0, 1, (255, 140, 30), 5),
    (18, 4.0, -1, (240, 220, 60), 40),
    (22, 8.0, 1, (80, 200, 255), 60),
    (16, 5.0, -1, (255, 90, 150), 20),
]
FISH_SPRITE = ["#.##.", "####+", "#.##."]

def frame_aquarium(now, use_24h, t):
    buf = new_buf((0, 0, 0))
    for y in range(H):
        c = mix((12, 50, 110), (4, 16, 44), y / (H - 1.0))
        for x in range(W):
            buf[y][x] = c

    # Sand
    for x in range(W):
        for y in range(29, H):
            buf[y][x] = mix((190, 160, 100), (150, 120, 70), noise(x, y, 3))

    # Seaweed swaying
    for (sx, height, seed) in ((6, 11, 1), (20, 8, 2), (45, 12, 3), (57, 9, 4)):
        for i in range(height):
            y = 28 - i
            x = sx + iround(math.sin(t * 1.6 + i * 0.5 + seed) * (i / float(height)) * 1.5)
            put(buf, x, y, (30, 150 + i * 6, 70))

    # Bubbles
    for b in range(6):
        speed = 3 + 3 * noise(b, 1, 9)
        y = 29 - ((t * speed + noise(b, 2, 9) * 34) % 34)
        x = int(8 + noise(b, 3, 9) * 48) + iround(math.sin(t * 3 + b))
        put(buf, x, iround(y), (150, 200, 255))

    # Fish
    for (fy, speed, direction, color, offset) in FISH:
        span = W + 12
        pos = (offset + t * speed) % span - 6
        x0 = iround(pos if direction > 0 else W - pos)
        for ry in range(3):
            for rx in range(5):
                ch = FISH_SPRITE[ry][rx if direction > 0 else 4 - rx]
                if ch == "#":
                    put(buf, x0 + rx, fy + ry, color)
                elif ch == "+":
                    put(buf, x0 + rx, fy + ry, (20, 20, 20))

    # Time floating at the top
    tw = mid_time_width(now, use_24h)
    x = (W - tw) // 2
    draw_mid_time(buf, now, use_24h, x + 1, 2, (5, 20, 50), now.second % 2 == 0)
    draw_mid_time(buf, now, use_24h, x, 1, (235, 245, 255), now.second % 2 == 0)
    return buf

# ---------- native 2x (128x64) versions ----------

W2 = 128
H2 = 64

def thick_line(buf, x0, y0, x1, y1, color, width):
    # Parallel Bresenham lines for 2px-wide hands
    offsets = [(0, 0)] if width == 1 else [(0, 0), (1, 0), (0, 1), (1, 1)]
    for (ox, oy) in offsets:
        draw_line(buf, x0 + ox, y0 + oy, x1 + ox, y1 + oy, color)

def frame_analog_2x(now, use_24h, base_rgb, sub):
    accent = base_rgb if base_rgb else neon_color(now)
    buf = new_buf((0, 0, 0), W2, H2)
    cx = 31.5
    cy = 31.5

    def at(r, a):
        return iround(cx + r * math.sin(a) - 0.5), iround(cy - r * math.cos(a) - 0.5)

    # Rim, minute ticks and hour ticks
    for i in range(360):
        x, y = at(30.5, i * math.pi / 180)
        put(buf, x, y, (38, 38, 48))
    for m in range(60):
        a = m * math.pi / 30
        if m % 5 == 0:
            major = m % 15 == 0
            x0, y0 = at(28.0, a)
            x1, y1 = at(24.0 if major else 25.5, a)
            thick_line(buf, x0, y0, x1, y1, (225, 225, 230) if major else (150, 150, 160), 2 if major else 1)
        else:
            x, y = at(28.0, a)
            put(buf, x, y, (70, 70, 82))

    secs = now.second + sub
    ha = (now.hour % 12 + now.minute / 60.0) * math.pi / 6
    ma = (now.minute + secs / 60.0) * math.pi / 30
    sa = secs * math.pi / 30
    hx, hy = at(15.0, ha)
    mx, my = at(23.0, ma)
    sx, sy = at(26.0, sa)
    tx, ty = at(-6.0, sa)
    thick_line(buf, 31, 31, hx, hy, (240, 236, 228), 2)
    thick_line(buf, 31, 31, mx, my, (240, 236, 228), 2)
    draw_line(buf, tx, ty, sx, sy, accent)
    for dy in range(-1, 2):
        for dx in range(-1, 2):
            put(buf, 31 + dx, 31 + dy, accent)
    put(buf, 31, 31, (0, 0, 0))

    # Digital time and date on the right
    right = 96
    tw = mid_time_width(now, use_24h, 2)
    draw_mid_time(buf, now, use_24h, right - tw // 2, 10, (240, 236, 228), now.second % 2 == 0, 2)
    date = now.format("Mon").upper() + " " + str(now.day)
    draw_tiny_centered(buf, date, right, 38, accent, 2)
    _, _, ampm = time_parts(now, use_24h)
    if ampm:
        draw_tiny_centered(buf, ampm, right, 52, (110, 108, 104), 2)
    return buf

def moon_cells_2x(p):
    cells = []
    cx = 31.5
    cy = 32.0
    r = 25.0
    k = math.cos(2 * math.pi * p)
    craters = [
        (-8.0, -6.0, 4.0),
        (6.0, 4.0, 5.0),
        (-4.0, 10.0, 3.0),
        (10.0, -10.0, 3.0),
        (-13.0, 4.0, 2.5),
        (2.0, -14.0, 2.0),
        (13.0, 12.0, 2.0),
        (-1.0, 1.0, 1.5),
    ]
    dark = (20, 22, 32)
    for y in range(5, 60):
        for x in range(5, 59):
            nx = (x + 0.5 - cx) / r
            ny = (y + 0.5 - cy) / r
            d2 = nx * nx + ny * ny
            if d2 > 1:
                continue
            w = math.sqrt(1 - ny * ny)
            u = nx / w if w > 0 else 0

            # Soft terminator: blend across the shadow line instead of a hard edge
            edge = (u - k) if p < 0.5 else (-k - u)
            blend = clamp(edge * 4 + 0.5, 0.0, 1.0)
            lit = scale_rgb((238, 234, 214), 0.7 + 0.3 * math.sqrt(1 - d2))
            for (qx, qy, qr) in craters:
                dd = (x + 0.5 - cx - qx) * (x + 0.5 - cx - qx) + (y + 0.5 - cy - qy) * (y + 0.5 - cy - qy)
                if dd <= qr * qr:
                    # Crater floor darker, with a lighter rim on the lower-right
                    lit = scale_rgb(lit, 0.78 if dd < (qr - 0.8) * (qr - 0.8) else 0.9)
            cells.append((x, y, mix(dark, lit, blend)))
    return cells

def frame_moon_2x(now, use_24h, p, frame):
    buf = new_buf((0, 0, 0), W2, H2)

    # Twinkling stars; a few bright ones get a small cross
    for i in range(34):
        sx = rnd(i * 7 + 3) % W2
        sy = rnd(i * 13 + 9) % H2
        tw = noise(i, frame // 2, 11)
        c = scale_rgb((255, 255, 230), 0.15 + 0.55 * tw)
        put(buf, sx, sy, c)
        if i % 9 == 0 and tw > 0.6:
            for (dx, dy) in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                put(buf, sx + dx, sy + dy, scale_rgb(c, 0.4))

    right = 94
    tw = mid_time_width(now, use_24h, 2)
    draw_mid_time(buf, now, use_24h, right - tw // 2, 8, (240, 236, 228), now.second % 2 == 0, 2)
    for (limit, a, b) in MOON_PHASES:
        if p < limit:
            draw_tiny_centered(buf, a, right, 34, (200, 196, 180), 2)
            draw_tiny_centered(buf, b, right, 48, (140, 138, 128), 2)
            break
    return buf

# Right-facing fish: # body, s stripe, o eye; two tail poses for a little wiggle
FISH_SPRITES_2X = [
    [
        ".....###....",
        "#..#######..",
        "##.###s###o#",
        "######s#####",
        "#..#######..",
        ".....##.....",
    ],
    [
        ".....###....",
        "...#######..",
        "#####s####o#",
        "######s#####",
        "...#######..",
        ".....##.....",
    ],
]

AQUARIUM_RAY_PHASES = 12

def aquarium_backgrounds():
    """Water with slow diagonal light rays, pre-drawn for a cycle of ray positions."""
    backgrounds = []
    for k in range(AQUARIUM_RAY_PHASES):
        phase = k * 2 * math.pi / AQUARIUM_RAY_PHASES
        rays = [math.sin(d * 0.09 - phase) > 0.7 for d in range(W2 + H2)]
        bg = []
        for y in range(H2):
            base = mix((12, 50, 110), (4, 16, 44), y / (H2 - 1.0))
            lit = mix(base, (40, 110, 170), 0.18 * (1 - y / 64.0))
            shift = int(y * 0.6)
            bg.append([lit if rays[x + shift] else base for x in range(W2)])
        backgrounds.append(bg)
    return backgrounds

def aquarium_sand_2x():
    sand = new_buf(None, W2, H2)
    for x in range(W2):
        top = 57 + iround(math.sin(x * 0.12) * 1.2)
        for y in range(top, H2):
            n = noise(x, y, 3)
            sand[y][x] = mix((196, 166, 106), (150, 120, 70), n) if n < 0.93 else (110, 100, 90)
    return buf_to_widget(sand)

def frame_aquarium_2x(now, use_24h, t, backgrounds):
    # The rays drift one step every ~0.9s
    bg = backgrounds[int(t / 0.9) % AQUARIUM_RAY_PHASES]
    buf = [list(row) for row in bg]

    # Seaweed: 2px stems with leaves, swaying more toward the tip
    for (sx, height, seed) in ((10, 24, 1), (38, 17, 2), (86, 26, 3), (112, 19, 4), (122, 12, 5)):
        for i in range(height):
            y = 56 - i
            sway = math.sin(t * 1.6 + i * 0.25 + seed) * (i / float(height)) * 3
            x = sx + iround(sway)
            c = (30, 140 + i * 3, 70)
            put(buf, x, y, c)
            put(buf, x + 1, y, scale_rgb(c, 0.75))
            if i % 5 == 3:
                side = 1 if (i // 5) % 2 == 0 else -1
                put(buf, x + (2 if side > 0 else -1), y - 1, c)
                put(buf, x + (3 if side > 0 else -2), y - 2, scale_rgb(c, 0.85))

    # Bubbles: little rings that wobble on the way up
    for b in range(9):
        speed = 6 + 6 * noise(b, 1, 9)
        y = iround(56 - ((t * speed + noise(b, 2, 9) * 68) % 68))
        x = int(14 + noise(b, 3, 9) * 100) + iround(math.sin(t * 3 + b) * 1.5)
        c = (150, 200, 255)
        if b % 3 == 0:
            for (dx, dy) in ((0, -1), (1, 0), (0, 1), (-1, 0)):
                put(buf, x + dx, y + dy, c)
        else:
            put(buf, x, y, c)

    # Fish
    for (fy, speed, direction, color, offset) in FISH:
        span = W2 + 24
        pos = (offset * 2 + t * speed * 1.5) % span - 12
        x0 = iround(pos if direction > 0 else W2 - pos)
        sprite = FISH_SPRITES_2X[int(t * 4 + offset) % 2]
        stripe = mix(color, (255, 255, 255), 0.45)
        for ry in range(6):
            for rx in range(12):
                ch = sprite[ry][rx if direction > 0 else 11 - rx]
                if ch == "#":
                    put(buf, x0 + rx, fy * 2 + ry, color)
                elif ch == "s":
                    put(buf, x0 + rx, fy * 2 + ry, stripe)
                elif ch == "o":
                    put(buf, x0 + rx, fy * 2 + ry, (15, 15, 20))

    # Time floating at the top
    tw = mid_time_width(now, use_24h, 2)
    x = (W2 - tw) // 2
    draw_mid_time(buf, now, use_24h, x + 2, 4, (5, 20, 50), now.second % 2 == 0, 2)
    draw_mid_time(buf, now, use_24h, x, 2, (235, 245, 255), now.second % 2 == 0, 2)
    return buf

# --- Snow ---

def snow_frames(now, use_24h, count, step):
    digits, colon, ampm, _ = big_time_cells(now, use_24h, oy = 11)
    solid = {}
    for c in digits + colon:
        solid[c] = True

    # Height of the first solid pixel in each column (digits or the ground)
    top = []
    for x in range(W):
        t = H
        for y in range(H):
            if (x, y) in solid:
                t = y
                break
        top.append(t)
    base_top = list(top)
    settled = {}
    flakes = []
    for i in range(36):
        flakes.append([noise(i, 1, 4) * W, noise(i, 2, 4) * H - H, 0.25 + 0.35 * noise(i, 3, 4), i])

    # Run a while before the first frame so there's already some snow on the digits
    bufs = []
    for f in range(count + 120):
        for fl in flakes:
            fl[1] += fl[2]
            x = int(fl[0] + math.sin(f * 0.15 + fl[3]) * 0.8) % W
            if fl[1] >= top[x] - 1:
                limit = base_top[x] - 2 if base_top[x] < H else 27
                if top[x] > limit:
                    top[x] -= 1
                    settled[(x, top[x])] = True
                fl[0] = noise(fl[3], f, 6) * W
                fl[1] = -1 - noise(fl[3], f, 7) * 4
        if f < 120:
            continue
        fnow = now + time.parse_duration("%dms" % ((f - 120) * step))
        buf = new_buf((0, 0, 0))
        for y in range(H):
            c = mix((4, 6, 18), (16, 22, 44), y / (H - 1.0))
            for x in range(W):
                buf[y][x] = c
        cells = digits + (colon if fnow.second % 2 == 0 else [])
        for (x, y) in cells:
            put(buf, x, y, (200, 215, 245))
        for (x, y) in settled:
            put(buf, x, y, (235, 240, 255))
        for fl in flakes:
            x = int(fl[0] + math.sin(f * 0.15 + fl[3]) * 0.8) % W
            put(buf, x, int(fl[1]), (255, 255, 255))
        if ampm:
            draw_small(buf, ampm, W - 8, 0, (140, 150, 180))
        bufs.append(buf)
    return bufs

# --- Lava lamp ---

LAVA_BLOBS = [
    # radius, x speed, y speed, x phase, y phase (half-resolution 32x16 space)
    (4.0, 0.21, 0.33, 0.0, 1.0),
    (3.2, 0.29, 0.23, 2.0, 0.0),
    (5.0, 0.17, 0.27, 4.0, 3.0),
    (3.6, 0.33, 0.19, 1.0, 5.0),
    (2.8, 0.25, 0.37, 3.0, 2.0),
]

def frame_lava(now, use_24h, t):
    buf = new_buf((0, 0, 0))
    hue_shift = (now.hour * 60 + now.minute) / 1440.0
    centers = []
    for (r, ax, ay, px_, py_) in LAVA_BLOBS:
        centers.append((16 + 13 * math.sin(t * ax + px_), 8 + 6.5 * math.sin(t * ay + py_), r * r))
    for hy in range(16):
        for hx in range(32):
            f = 0.0
            for (cx, cy, r2) in centers:
                dx = hx - cx
                dy = hy - cy
                f += r2 / (dx * dx + dy * dy + 0.6)
            if f < 0.75:
                c = mix((18, 4, 26), (40, 8, 40), hy / 15.0)
            elif f < 1.0:
                c = hsv(0.92 + hue_shift, 0.9, 0.35 + (f - 0.75) * 1.6)
            else:
                c = hsv(0.92 + hue_shift + min(f - 1.0, 1.5) * 0.06, 0.85, 1.0)
            x = hx * 2
            y = hy * 2
            buf[y][x] = c
            buf[y][x + 1] = c
            buf[y + 1][x] = c
            buf[y + 1][x + 1] = c
    draw_big_time(buf, now, use_24h, (255, 245, 235), ring = (25, 0, 20))
    return buf

# --- Starfield ---

def frame_starfield(now, use_24h, frame):
    buf = new_buf((0, 0, 0))
    for k in range(120):
        phase = noise(k, 0, 3) + frame * 0.012
        gen = int(phase)
        z = 1.0 - (phase - gen)
        if z < 0.06:
            continue
        sx = noise(k, gen, 1) * 2 - 1
        sy = noise(k, gen, 2) * 2 - 1
        x = 32 + sx / z * 14
        y = 16 + sy / z * 8
        if x < 0 or x >= W or y < 0 or y >= H:
            continue
        z2 = z + 0.03
        x2 = 32 + sx / z2 * 14
        y2 = 16 + sy / z2 * 8
        b = clamp(1.1 - z, 0.15, 1.0)
        draw_line(buf, iround(x2), iround(y2), iround(x), iround(y), scale_rgb((200, 210, 255), b * 0.6))
        put(buf, iround(x), iround(y), scale_rgb((255, 255, 255), b))
    draw_big_time(buf, now, use_24h, (230, 235, 255), ring = (0, 0, 0))
    return buf

# --- Pac-Man ---

PAC_OPEN = [".###.", "###..", "##...", "###..", ".###."]
PAC_SHUT = [".###.", "#####", "#####", "#####", ".###."]
GHOST = [".###.", "#####", "#o#o#", "#####", "#.#.#"]
GHOST_COLORS = [(255, 40, 40), (255, 170, 220), (60, 230, 255), (255, 170, 60)]

def draw_sprite(buf, sprite, x, y, color):
    for ry in range(len(sprite)):
        for rx in range(len(sprite[0])):
            ch = sprite[ry][rx]
            if ch == "#":
                put(buf, x + rx, y + ry, color)
            elif ch == "o":
                put(buf, x + rx, y + ry, (255, 255, 255))

def frame_pacman(now, use_24h, frame, sub):
    buf = new_buf((0, 0, 0))
    draw_big_time(buf, now, use_24h, (240, 240, 250), oy = 0)

    # Maze lane
    for x in range(W):
        put(buf, x, 20, (33, 33, 222))
        put(buf, x, 31, (33, 33, 222))

    # Pac-Man eats one dot per second; the lane refills every 16 seconds
    secs = now.second + sub
    lap = secs % 16
    pac_x = -3 + lap * 4
    for i in range(16):
        dx = 2 + i * 4
        if dx > pac_x + 2:
            put(buf, dx, 25, (255, 190, 170))
            put(buf, dx + 1, 25, (255, 190, 170))
    sprite = PAC_OPEN if (frame // 2) % 2 == 0 else PAC_SHUT
    draw_sprite(buf, sprite, iround(pac_x), 23, (255, 230, 0))

    # Right after the minute changes, the ghosts give chase
    if now.second < 8:
        for g in range(4):
            gx = iround(pac_x - 9 - g * 7)
            draw_sprite(buf, GHOST, gx, 23, GHOST_COLORS[g])
    return buf

# ---------- main ----------

def main(config):
    tz = config.get("$tz", time.tz())
    now = time.now().in_location(tz)
    style = config.get("style", "neon")
    if style == "random":
        style = pick_random_style(config)
    use_24h = config.bool("use_24h", True)
    show_seconds = config.bool("show_seconds", True)
    morph_seconds = config.bool("morph_seconds", True)
    base_rgb = None
    if config.get("color", "auto") != "auto":
        base_rgb = parse_hex(config.get("color"))
    seconds = DEFAULT_SECONDS

    frames = []
    if style == "prism":
        # Smooth animation: 10 fps
        step = 100
        for i in range(seconds * 10):
            t = i / 10.0
            fnow = now + time.parse_duration("%dms" % (i * step))
            frames.append(buf_to_widget(frame_prism(fnow, use_24h, t, show_seconds)))
        delay = step
    elif style == "flap":
        # 4 fps so the flip reads as motion
        step = 250
        for i in range(seconds * 4):
            fnow = now + time.parse_duration("%dms" % (i * step))
            since_minute = fnow.second + (fnow.nanosecond / 1e9)
            flip_t = since_minute / 0.75 if since_minute < 0.75 else 1.0
            frames.append(buf_to_widget(frame_flap(fnow, use_24h, base_rgb, flip_t, show_seconds)))
        delay = step
    elif style == "matrix":
        step = 100
        for i in range(seconds * 10):
            fnow = now + time.parse_duration("%dms" % (i * step))
            frames.append(buf_to_widget(frame_matrix(fnow, use_24h, i)))
        delay = step
    elif style == "fire":
        step = 100
        heat = [[0.0 for _ in range(W)] for _ in range(H + 1)]

        # Let the flames build up before the first frame
        for i in range(24):
            fire_step(heat, [], -i - 1)
        for i in range(seconds * 10):
            fnow = now + time.parse_duration("%dms" % (i * step))
            frames.append(buf_to_widget(frame_fire(fnow, use_24h, heat, i)))
        delay = step
    elif style == "morph":
        step = 100
        for i in range(seconds * 10):
            fnow = now + time.parse_duration("%dms" % (i * step))
            frames.append(buf_to_widget(frame_morph(fnow, use_24h, base_rgb, fnow.nanosecond / 1e9, morph_seconds)))
        delay = step
    elif style == "pong":
        step = 100
        frames = [buf_to_widget(b) for b in pong_frames(now, use_24h, seconds * 10, step)]
        delay = step
    elif style == "snow":
        step = 100
        frames = [buf_to_widget(b) for b in snow_frames(now, use_24h, seconds * 10, step)]
        delay = step
    elif style == "tetris":
        step = 100
        blocks, colon_x = tetris_blocks(now, use_24h)
        shown = time_label(now, use_24h)
        t0 = 0.0
        for i in range(seconds * 10):
            fnow = now + time.parse_duration("%dms" % (i * step))
            label = time_label(fnow, use_24h)
            if label != shown:
                blocks, colon_x = tetris_blocks(fnow, use_24h)
                shown = label
                t0 = i / 10.0
            frames.append(buf_to_widget(frame_tetris(fnow, blocks, colon_x, i / 10.0 - t0)))
        delay = step
    elif style == "moon":
        step = 250
        p = moon_phase(now)
        native2x = canvas.is2x()
        cells = moon_cells_2x(p) if native2x else moon_cells(p)

        # The moon doesn't change during a render: draw it once as a layer over the stars
        disc = new_buf(None, W2, H2) if native2x else new_buf(None)
        for (x, y, c) in cells:
            disc[y][x] = c
        disc_layer = buf_to_widget(disc)
        for i in range(seconds * 4):
            fnow = now + time.parse_duration("%dms" % (i * step))
            if native2x:
                layer = buf_to_widget(frame_moon_2x(fnow, use_24h, p, i))
            else:
                layer = buf_to_widget(frame_moon(fnow, use_24h, p, i))
            frames.append(render.Stack(children = [layer, disc_layer]))
        delay = step
    elif style in ("analog", "bighour", "aquarium", "lava", "starfield", "pacman"):
        step = 250 if style in ("analog", "bighour") else 100

        # The 2x aquarium is the heaviest to draw: 5 fps keeps it quick to render
        if style == "aquarium" and canvas.is2x():
            step = 200
        aquarium_bgs = aquarium_backgrounds() if style == "aquarium" and canvas.is2x() else None
        sand_layer = aquarium_sand_2x() if aquarium_bgs else None
        for i in range(seconds * 1000 // step):
            fnow = now + time.parse_duration("%dms" % (i * step))
            sub = fnow.nanosecond / 1e9
            t = i * step / 1000.0
            if style == "analog":
                buf = frame_analog_2x(fnow, use_24h, base_rgb, sub) if canvas.is2x() else frame_analog(fnow, use_24h, base_rgb, sub)
            elif style == "bighour":
                buf = frame_bighour(fnow, use_24h, base_rgb, sub)
            elif style == "aquarium":
                buf = frame_aquarium_2x(fnow, use_24h, t, aquarium_bgs) if canvas.is2x() else frame_aquarium(fnow, use_24h, t)
            elif style == "lava":
                buf = frame_lava(fnow, use_24h, t)
            elif style == "starfield":
                buf = frame_starfield(fnow, use_24h, i)
            else:
                buf = frame_pacman(fnow, use_24h, i, sub)
            widget = buf_to_widget(buf)
            frames.append(render.Stack(children = [widget, sand_layer]) if sand_layer else widget)
        delay = step
    elif style in ("dotgrid", "dayprogress", "world"):
        step = 1000
        zones = []
        for key, default in (("world_1", "NYC"), ("world_2", "LON"), ("world_3", "TYO")):
            code = config.get(key, default)
            for (c, z, _) in WORLD_ZONES:
                if c == code:
                    zones.append((c, z))
        for i in range(seconds):
            fnow = now + time.parse_duration("%ds" % i)
            if style == "dotgrid":
                buf = frame_dotgrid(fnow, use_24h, base_rgb)
            elif style == "dayprogress":
                buf = frame_dayprogress(fnow, use_24h, tz)
            else:
                buf = frame_world(fnow, use_24h, base_rgb, zones)
            frames.append(buf_to_widget(buf))
        delay = step
    elif style == "words":
        # Only changes once a minute: one frame is enough
        frames.append(buf_to_widget(frame_words(now, base_rgb)))
        delay = 1000
    elif style == "binary":
        step = 1000
        for i in range(seconds):
            fnow = now + time.parse_duration("%ds" % i)
            frames.append(buf_to_widget(frame_binary(fnow, use_24h)))
        delay = step
    elif style == "outline":
        step = 500
        for i in range(seconds * 2):
            fnow = now + time.parse_duration("%dms" % (i * step))
            frames.append(buf_to_widget(frame_outline(fnow, use_24h, base_rgb, show_seconds)))
        delay = step
    else:
        step = 250
        neon_memo = {}
        for i in range(seconds * 4):
            fnow = now + time.parse_duration("%dms" % (i * step))
            sec_frac = (fnow.nanosecond / 1e9)
            if style == "horizon":
                buf = frame_horizon(fnow, use_24h, i // 4)
            else:
                buf = frame_neon(fnow, use_24h, base_rgb, sec_frac, show_seconds, neon_memo)
            frames.append(buf_to_widget(buf))
        delay = step

    return render.Root(
        delay = delay,
        show_full_animation = True,
        child = render.Animation(children = frames),
    )

STYLES = [
    ("Neon", "neon"),
    ("Horizon", "horizon"),
    ("Prism", "prism"),
    ("Split-flap", "flap"),
    ("Morph", "morph"),
    ("Outline", "outline"),
    ("Words", "words"),
    ("Binary", "binary"),
    ("Matrix", "matrix"),
    ("Fire", "fire"),
    ("Analog", "analog"),
    ("Big hour", "bighour"),
    ("Dot grid", "dotgrid"),
    ("Moon", "moon"),
    ("Day progress", "dayprogress"),
    ("World clocks", "world"),
    ("Pong", "pong"),
    ("Tetris", "tetris"),
    ("Aquarium", "aquarium"),
    ("Snow", "snow"),
    ("Lava lamp", "lava"),
    ("Starfield", "starfield"),
    ("Pac-Man", "pacman"),
]

def random_style_options(style):
    # When Random is picked, show one toggle per style to choose what to cycle through
    if style != "random":
        return []
    return [
        schema.Toggle(
            id = "random_" + v,
            name = d,
            desc = "Include " + d + " in the random rotation.",
            icon = "shuffle",
            default = True,
        )
        for (d, v) in STYLES
    ]

def pick_random_style(config):
    enabled = [v for (_, v) in STYLES if config.bool("random_" + v, True)]
    if not enabled:
        enabled = [v for (_, v) in STYLES]
    return enabled[random.number(0, len(enabled) - 1)]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "style",
                name = "Style",
                desc = "How the clock looks. Random picks a different style each time the clock is shown.",
                icon = "palette",
                default = "neon",
                options = [schema.Option(display = "Random", value = "random")] + [
                    schema.Option(display = d, value = v)
                    for (d, v) in STYLES
                ],
            ),
            schema.Generated(
                id = "random_styles",
                source = "style",
                handler = random_style_options,
            ),
            schema.Toggle(
                id = "use_24h",
                name = "24-hour time",
                desc = "Show 24-hour time instead of 12-hour with AM/PM.",
                icon = "clock",
                default = True,
            ),
            schema.Toggle(
                id = "show_seconds",
                name = "Seconds bar",
                desc = "Show a thin seconds bar along the bottom (Neon, Prism, Split-flap and Outline).",
                icon = "stopwatch",
                default = True,
            ),
            schema.Toggle(
                id = "morph_seconds",
                name = "Morph: show seconds",
                desc = "Show HH:MM:SS in the Morph style. Turn off for bigger HH:MM digits.",
                icon = "stopwatch",
                default = True,
            ),
            schema.Dropdown(
                id = "world_1",
                name = "World clock 1",
                desc = "First city for the World clocks style.",
                icon = "earthAmericas",
                default = "NYC",
                options = [schema.Option(display = name, value = c) for (c, _, name) in WORLD_ZONES],
            ),
            schema.Dropdown(
                id = "world_2",
                name = "World clock 2",
                desc = "Second city for the World clocks style.",
                icon = "earthEurope",
                default = "LON",
                options = [schema.Option(display = name, value = c) for (c, _, name) in WORLD_ZONES],
            ),
            schema.Dropdown(
                id = "world_3",
                name = "World clock 3",
                desc = "Third city for the World clocks style.",
                icon = "earthAsia",
                default = "TYO",
                options = [schema.Option(display = name, value = c) for (c, _, name) in WORLD_ZONES],
            ),
            schema.Dropdown(
                id = "color",
                name = "Color",
                desc = "Accent color for most styles. Auto follows the time of day.",
                icon = "brush",
                default = "auto",
                options = [
                    schema.Option(display = "Auto", value = "auto"),
                    schema.Option(display = "Cyan", value = "#20e0ff"),
                    schema.Option(display = "Magenta", value = "#ff2fb0"),
                    schema.Option(display = "Amber", value = "#ffb020"),
                    schema.Option(display = "Green", value = "#40ff70"),
                    schema.Option(display = "White", value = "#ffffff"),
                ],
            ),
        ],
    )
