"""
Applet: Art Deco Clock
Summary: Clock with art deco themes
Description: A clock framed in art deco ornament. Choose from Gatsby gold, Sunburst, Skyline, Emerald fan and Miami streamline themes, or a random one each time.
Author: Jeremy Blaker
"""

load("math.star", "math")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TIMEZONE = "America/New_York"
DEFAULT_THEME = "gatsby"

WIDTH, HEIGHT = canvas.size()
S = 2 if canvas.is2x() else 1

# Ornaments are drawn at native resolution: S scales their size and spacing,
# while lines stay 1px wide so they are as fine as the text on 2x panels.

def is_square():
    w, h = canvas.size()
    return h == w

def fonts():
    if canvas.is2x():
        return "terminus-28", "terminus-12"
    if is_square():
        return "10x20", "tb-8"
    return "6x13", "tom-thumb"

TIME_FONT, DATE_FONT = fonts()

# Drawing helpers ---------------------------------------------------------------

def rect(x, y, w, h, color):
    x0, y0 = max(x, 0), max(y, 0)
    x1, y1 = min(x + w, WIDTH), min(y + h, HEIGHT)
    if x1 <= x0 or y1 <= y0:
        return []
    return [render.Padding(
        pad = (x0, y0, 0, 0),
        child = render.Box(width = x1 - x0, height = y1 - y0, color = color),
    )]

def outline(x, y, w, h, color):
    return rect(x, y, w, 1, color) + rect(x, y + h - 1, w, 1, color) + \
           rect(x, y, 1, h, color) + rect(x + w - 1, y, 1, h, color)

def dots(points, color):
    # Turn a list of (x, y) pixels into one box per horizontal run.
    rows = {}
    for x, y in points:
        if x >= 0 and x < WIDTH and y >= 0 and y < HEIGHT:
            rows.setdefault(y, {})[x] = True
    out = []
    for y in sorted(rows.keys()):
        xs = sorted(rows[y].keys())
        start = xs[0]
        prev = start
        for x in xs[1:] + [None]:
            if x != None and x == prev + 1:
                prev = x
                continue
            out += rect(start, y, prev - start + 1, 1, color)
            if x != None:
                start = x
                prev = x
    return out

def line_points(x1, y1, x2, y2):
    n = max(abs(x2 - x1), abs(y2 - y1))
    if n == 0:
        return [(x1, y1)]
    return [
        (int(math.round(x1 + (x2 - x1) * i / n)), int(math.round(y1 + (y2 - y1) * i / n)))
        for i in range(n + 1)
    ]

def arc_points(cx, cy, r, start, end):
    steps = max(int(r * abs(end - start) * 2), 8)
    return [
        (
            int(math.round(cx + r * math.cos(start + (end - start) * i / steps))),
            int(math.round(cy + r * math.sin(start + (end - start) * i / steps))),
        )
        for i in range(steps + 1)
    ]

PI = math.pi

# Themes ------------------------------------------------------------------------

def gatsby_decor(theme, box, _frame):
    gold, dim = theme["accent"], theme["accent2"]
    mid = HEIGHT // 2

    # Double frame with stepped corners.
    out = []
    for inset, step, color in [(0, 4 * S, gold), (2 * S, 2 * S, dim)]:
        l, t, r, b = inset, inset, WIDTH - 1 - inset, HEIGHT - 1 - inset
        out += dots(
            line_points(l + step, t, r - step, t) + line_points(l + step, b, r - step, b) +
            line_points(l, t + step, l, b - step) + line_points(r, t + step, r, b - step) +
            line_points(l + step, t, l + step, t + step) + line_points(l, t + step, l + step, t + step) +
            line_points(r - step, t, r - step, t + step) + line_points(r, t + step, r - step, t + step) +
            line_points(l + step, b, l + step, b - step) + line_points(l, b - step, l + step, b - step) +
            line_points(r - step, b, r - step, b - step) + line_points(r, b - step, r - step, b - step),
            color,
        )

    # Chevrons pointing in towards the time: above and below on square panels, otherwise beside it.
    # Chevron i reaches x = (6 + 3i)S, so fit as many as leave a 2S gap before the text
    # (a two-digit date like "MON NOV 10" leaves room for only two).
    beside = 0 if is_square() else min(3, (box[0] - 8 * S) // (3 * S) + 1)
    pts = []
    cx = WIDTH // 2
    arm = 2 * S
    for i in range(beside if beside > 0 else 3):
        if beside > 0:
            for x, d in [((6 + 3 * i) * S, 1), (WIDTH - 1 - (6 + 3 * i) * S, -1)]:
                pts += line_points(x - arm * d, mid - arm, x, mid) + line_points(x, mid, x - arm * d, mid + arm)
        else:
            for y, d in [((6 + 3 * i) * S, 1), (HEIGHT - 1 - (6 + 3 * i) * S, -1)]:
                pts += line_points(cx - arm, y - arm * d, cx, y) + line_points(cx, y, cx + arm, y - arm * d)
    out += dots(pts, gold)

    # Diamond clasps on the inner frame, top and bottom.
    for y in [2 * S, HEIGHT - 1 - 2 * S]:
        out += dots([
            (cx + dx, y + dy)
            for dx in range(-S, S + 1)
            for dy in range(-S, S + 1)
            if abs(dx) + abs(dy) <= S
        ], gold)
    return out

def sunburst_decor(theme, box, _frame):
    ray, gold = theme["accent2"], theme["accent"]
    cx, cy = WIDTH // 2, HEIGHT // 2

    # Rays from the centre to evenly spaced points around the edge.
    pts = []
    for x in range(0, WIDTH + 1, 8):
        pts += line_points(cx, cy, x, 0) + line_points(cx, cy, x, HEIGHT - 1)
    side = HEIGHT // (4 * S)
    for y in range(side, HEIGHT, side):
        pts += line_points(cx, cy, 0, y) + line_points(cx, cy, WIDTH - 1, y)
    out = dots(pts, ray)

    # Panel behind the time, with stepped gold tabs on each side.
    l, t, r, b = box[0] - 3 * S, box[1] - 2 * S, box[2] + 3 * S, box[3] + 2 * S
    out += rect(l, t, r - l + 1, b - t + 1, theme["bg"])
    out += outline(l, t, r - l + 1, b - t + 1, gold)
    mid = (t + b) // 2
    for x1, x2 in [(l - 2 * S, l - 4 * S), (r + 1, r + 1 + 2 * S)]:
        out += rect(x1, mid - 3 * S, 2 * S, 6 * S + 1, gold)
        out += rect(x2, mid - S, 2 * S, 2 * S + 1, gold)
    return out

def tower(x, w, top, color, window, beacon, frame, seed):
    # A stepped skyscraper with three tiers and a spire.
    # frame is None for a still image; otherwise windows flicker and the beacon blinks.
    out = []
    for inset, rise in [(0, 0), (2 * S, 4 * S), (4 * S, 8 * S)]:
        y = top + 8 * S - rise
        out += rect(x + inset, y, w - 2 * inset, HEIGHT - y, color)
    sx = x + (w - S) // 2
    out += rect(sx, top - 5 * S, S, 5 * S, color)
    if frame == None or frame % 4 < 2:
        out += rect(sx, top - 5 * S, S, S, beacon)

    # Windows stay single pixels, so a 2x tower gets more of them.
    # Start so the columns sit centred under the spire.
    lit = []
    k = seed
    for wx in range(x + 2 * S - 1, x + w - S, S + 1):
        for wy in range(top + 11 * S, HEIGHT - 2 * S, 3):
            # Each window goes dark for a few frames, starting at its own point in the loop.
            phase = (k * 7 + k * k // 3) % SKYLINE_FRAMES
            if frame == None or (frame - phase) % SKYLINE_FRAMES >= SKYLINE_DARK:
                lit.append((wx, wy))
            k += 1
    out += dots(lit, window)
    return out

SKYLINE_FRAMES = 16
SKYLINE_DARK = 4

def skyline_decor(theme, _box, frame):
    body, window = theme["accent"], theme["accent2"]
    tw = 11 * S

    # On square panels the time is wider, so the towers stand below it.
    top = HEIGHT - 18 if is_square() else HEIGHT // 4
    out = rect(0, HEIGHT - 1, WIDTH, 1, body)
    out += tower(S, tw, top, body, window, theme["beacon"], frame, 0)
    out += tower(WIDTH - S - tw, tw, top, body, window, theme["beacon"], frame, 5)
    return out

EMERALD_RINGS = [6, 9, 12]

def emerald_decor(theme, _box, frame):
    # frame is None for a still image; otherwise a gold ripple runs out through the rings.
    gold, dim = theme["accent"], theme["accent2"]
    w, h = WIDTH - 1, HEIGHT - 1
    out = rect(0, 0, WIDTH, 1, gold) + rect(0, HEIGHT - 1, WIDTH, 1, gold)

    pts = []
    glow = []
    inner, outer = EMERALD_RINGS[0] * S, EMERALD_RINGS[-1] * S
    corners = [(0, 0, 0), (w, 0, PI / 2), (w, h, PI), (0, h, 3 * PI / 2)]
    for cx, cy, a in corners:
        for i, r in enumerate(EMERALD_RINGS):
            ring = arc_points(cx, cy, r * S, a, a + PI / 2)
            if frame == i:
                glow += ring
            else:
                pts += ring

        # Spokes between the rings.
        for k in [1, 2, 3]:
            ang = a + PI / 2 * k / 4
            pts += line_points(
                int(math.round(cx + inner * math.cos(ang))),
                int(math.round(cy + inner * math.sin(ang))),
                int(math.round(cx + outer * math.cos(ang))),
                int(math.round(cy + outer * math.sin(ang))),
            )
    out += dots(pts, dim)
    out += dots(glow, gold)

    disc = []
    for cx, cy, a in corners:
        for r in range(4 * S):
            disc += arc_points(cx, cy, r, a, a + PI / 2)
    out += dots(disc, gold)
    return out

def miami_decor(theme, _box, _frame):
    pink, teal = theme["accent"], theme["accent2"]
    out = []

    # Streamline speed lines, sweeping in from the left at the top and the right at the bottom.
    for i, length in enumerate([18, 13, 8]):
        color = teal if i % 2 else pink
        y = (3 + i * 3) * S
        out += rect(0, y, length * S, 1, color)
        out += rect(WIDTH - length * S, HEIGHT - 1 - y, length * S, 1, color)

    # Porthole rings in the open corners.
    c = 6 * S
    out += dots(arc_points(WIDTH - 1 - c, c, 3 * S, 0, 2 * PI), teal)
    out += dots(arc_points(c, HEIGHT - 1 - c, 3 * S, 0, 2 * PI), pink)
    return out

THEMES = {
    "gatsby": {
        "name": "Gatsby Gold",
        "bg": "#000",
        "time": "#f5d77a",
        "date": "#b8912f",
        "accent": "#d4af37",
        "accent2": "#6b5414",
        "decor": gatsby_decor,
    },
    "sunburst": {
        "name": "Sunburst",
        "bg": "#0b1630",
        "time": "#fbe7a1",
        "date": "#d9a441",
        "accent": "#e0a530",
        "accent2": "#4a3a20",
        "decor": sunburst_decor,
    },
    "skyline": {
        "name": "Skyline",
        "bg": "#0a0f1f",
        "time": "#e8eef5",
        "date": "#9fb0c4",
        "accent": "#3b4a63",
        "accent2": "#f3c969",
        "beacon": "#ff3b30",
        "decor": skyline_decor,
        "frames": SKYLINE_FRAMES,
        "delay": 400,
    },
    "emerald": {
        "name": "Emerald Fan",
        "bg": "#022418",
        "time": "#f1d58a",
        "date": "#7fcfa8",
        "accent": "#c9a227",
        "accent2": "#1f7a55",
        "decor": emerald_decor,
        "frames": len(EMERALD_RINGS) + 3,
        "delay": 250,
    },
    "miami": {
        "name": "Miami Streamline",
        "bg": "#06292e",
        "time": "#ffb3c6",
        "date": "#5fd4c8",
        "accent": "#ff7aa2",
        "accent2": "#3cc4b8",
        "decor": miami_decor,
    },
}

THEME_ORDER = ["gatsby", "sunburst", "skyline", "emerald", "miami"]

# Main --------------------------------------------------------------------------

def main(config):
    theme_id = config.get("theme", DEFAULT_THEME)
    if theme_id == "random":
        theme_id = THEME_ORDER[random.number(0, len(THEME_ORDER) - 1)]
    theme = THEMES.get(theme_id, THEMES[DEFAULT_THEME])
    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)

    time_str = now.format("15:04" if config.bool("24hour", False) else "3:04")
    lines = [render.Text(time_str, font = TIME_FONT, color = theme["time"])]
    if config.bool("show_date", True):
        lines.append(render.Text(now.format("Mon Jan 2").upper(), font = DATE_FONT, color = theme["date"]))

    # Bounding box of the centred text: (left, top, right, bottom).
    text_w = max([t.size()[0] for t in lines])
    text_h = 0
    for t in lines:
        text_h += t.size()[1]
    left, top = (WIDTH - text_w) // 2, (HEIGHT - text_h) // 2
    box = (left, top, left + text_w - 1, top + text_h - 1)

    text = render.Box(
        width = WIDTH,
        height = HEIGHT,
        child = render.Column(cross_align = "center", children = lines),
    )

    def scene(frame):
        bg = render.Box(width = WIDTH, height = HEIGHT, color = theme["bg"])
        return render.Stack(children = [bg] + theme["decor"](theme, box, frame) + [text])

    frames = theme.get("frames", 1) if config.bool("animate", True) else 1
    if frames == 1:
        return render.Root(max_age = 60, child = scene(None))
    return render.Root(
        max_age = 60,
        delay = theme["delay"],
        child = render.Animation(children = [scene(f) for f in range(frames)]),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "theme",
                name = "Theme",
                desc = "The art deco style to display.",
                icon = "palette",
                default = DEFAULT_THEME,
                options = [schema.Option(display = THEMES[k]["name"], value = k) for k in THEME_ORDER] +
                          [schema.Option(display = "Random", value = "random")],
            ),
            schema.Toggle(
                id = "animate",
                name = "Animate",
                desc = "Animate the Skyline and Emerald Fan themes.",
                icon = "film",
                default = True,
            ),
            schema.Toggle(
                id = "24hour",
                name = "24-hour time",
                desc = "Show the time in 24-hour format.",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = "show_date",
                name = "Show date",
                desc = "Show the date below the time.",
                icon = "calendar",
                default = True,
            ),
        ],
    )
