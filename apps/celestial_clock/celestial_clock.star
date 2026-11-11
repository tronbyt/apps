"""
Applet: Celestial Clock
Summary: Sky clock by time of day
Description: A clock over a sky that follows the time of day. A sun arcs across by day, a crescent moon and twinkling stars come out at night, and a bar along the bottom shows how much of the day has passed.
Author: gcrft123
"""

load("encoding/json.star", "json")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

FRAME_MS = 250
FRAMES = 120  # 30 s; Tronbyt cuts the animation to the app's display time
TWINKLE_FRAMES = 8  # one twinkle every 2 s

SUNRISE = 6.0
SUNSET = 18.5

WHITE = "#ffffff"
BAR = "#ffd24a"
BAR_TRACK = "#ffffff30"
SHADOW = "#000000a0"
DATE_SHADOW = "#000000b0"

SUN_CORE = (255, 224, 120)
SUN_GLOW = (255, 180, 70)
MOON = (235, 238, 255)
MOON_GLOW = "#96a0d220"

# Sky keyframes across the day: (hour, top color, bottom color).
SKY_KEYFRAMES = [
    (0.0, (8, 10, 40), (20, 16, 56)),  # deep night
    (5.0, (24, 20, 60), (60, 40, 80)),  # pre-dawn
    (6.5, (70, 60, 110), (240, 130, 90)),  # sunrise glow
    (8.0, (60, 130, 210), (180, 220, 255)),  # morning
    (12.0, (40, 120, 220), (150, 210, 255)),  # midday
    (17.0, (50, 110, 190), (200, 200, 230)),  # late afternoon
    (18.5, (50, 50, 110), (250, 120, 70)),  # sunset glow
    (20.0, (20, 20, 70), (70, 45, 95)),  # twilight
    (24.0, (8, 10, 40), (20, 16, 56)),  # deep night again
]

# The 64x32 star field: (x, y, twinkle phase).
STARS_1X = [
    (5, 3, 0),
    (14, 6, 2),
    (22, 2, 4),
    (31, 5, 1),
    (40, 3, 3),
    (49, 6, 5),
    (57, 2, 0),
    (9, 10, 4),
    (27, 9, 2),
    (45, 11, 3),
    (60, 9, 1),
    (3, 7, 5),
    (35, 7, 0),
    (52, 9, 4),
    (18, 4, 1),
]

# ---------------------------------------------------------------- layout

def is_square():
    w, h = canvas.size()
    return h == w

def layout():
    """Sizes and fonts for the display: 64x32, 128x64 (2x), or 64x64 (square)."""
    w, h = canvas.size()
    if canvas.is2x():
        return struct(
            w = w,
            h = h,
            s = 2,
            clock = "terminus-32",
            clock_top = 17,
            zero = "O",  # Terminus slashes its zero; its capital O is the same width
            date = "terminus-16",
            date_top = h - 19,
            sun = 18,
            moon = 16,
            arc_low = 30,
            arc_high = 4,
            stars = scatter_stars(w, 26, 40),
        )
    if is_square():
        return struct(
            w = w,
            h = h,
            s = 1,
            clock = "10x20",
            clock_top = 26,
            zero = "0",
            date = "tb-8",
            date_top = 49,
            sun = 11,
            moon = 10,
            arc_low = 20,
            arc_high = 2,
            stars = scatter_stars(w, 22, 24),
        )
    return struct(
        w = w,
        h = h,
        s = 1,
        clock = "6x13",
        clock_top = 11,
        zero = "0",
        date = "tom-thumb",
        date_top = h - 8,
        sun = 9,
        moon = 8,
        arc_low = 15,
        arc_high = 3,
        stars = STARS_1X,
    )

def scatter_stars(w, band, count):
    """A fixed, evenly spread star field across the top `band` rows."""
    stars = []
    seed = 7
    for i in range(count):
        seed = (seed * 1103515245 + 12345) % 2147483648
        x = (i * w // count + seed % (w // count)) % w
        seed = (seed * 1103515245 + 12345) % 2147483648
        y = 1 + seed % (band - 1)
        stars.append((x, y, i % TWINKLE_FRAMES))
    return stars

# ---------------------------------------------------------------- color

HEX = "0123456789abcdef"

def to_hex(n):
    n = max(0, min(255, int(n)))
    return HEX[n // 16] + HEX[n % 16]

def rgb(c):
    return "#" + to_hex(c[0]) + to_hex(c[1]) + to_hex(c[2])

def lerp(a, b, t):
    return a + (b - a) * t

def lerp_color(c1, c2, t):
    return (lerp(c1[0], c2[0], t), lerp(c1[1], c2[1], t), lerp(c1[2], c2[2], t))

def sky_colors(hour):
    """The (top, bottom) colors of the sky at a fractional hour."""
    for i in range(len(SKY_KEYFRAMES) - 1):
        h0, top0, bot0 = SKY_KEYFRAMES[i]
        h1, top1, bot1 = SKY_KEYFRAMES[i + 1]
        if hour >= h0 and hour <= h1:
            t = (hour - h0) / (h1 - h0)
            return (lerp_color(top0, top1, t), lerp_color(bot0, bot1, t))
    return (SKY_KEYFRAMES[0][1], SKY_KEYFRAMES[0][2])

def sky_at(hour, y, h):
    top, bottom = sky_colors(hour)
    return lerp_color(top, bottom, y / float(h - 1))

def darkness_at(hour):
    """How dark the sky is, 0 to 1. Fades the stars in at dusk and out at dawn."""
    if hour < 5.0 or hour >= 20.0:
        return 1.0
    if hour < 6.5:
        return (6.5 - hour) / 1.5
    if hour >= 18.5:
        return (hour - 18.5) / 1.5
    return 0.0

# ---------------------------------------------------------------- drawing

def at(x, y, child):
    return render.Padding(pad = (x, y, 0, 0), child = child)

def sky(hour, L):
    return render.Column(children = [
        render.Box(width = L.w, height = 1, color = rgb(sky_at(hour, y, L.h)))
        for y in range(L.h)
    ])

def star_layer(frame, hour, darkness, L):
    """Twinkling stars, faded into the sky color as it gets light."""
    if darkness <= 0.02:
        return None
    pixels = []
    for x, y, phase in L.stars:
        wave = (math.sin((frame + phase) / float(TWINKLE_FRAMES) * 2.0 * math.pi) + 1.0) / 2.0
        b = 90 + wave * 165
        color = lerp_color(sky_at(hour, y, L.h), (b, b, b), darkness)
        pixels.append(at(x, y, render.Box(width = 1, height = 1, color = rgb(color))))
    return render.Stack(children = pixels)

def crescent(d, color):
    """A crescent moon as rows of pixels: the disc minus a disc offset up and to the right."""
    r = d / 2.0
    ox = 3.0 * d / 8.0
    oy = -d / 8.0
    runs = []
    for y in range(d):
        cy = y + 0.5 - r
        start = None
        for x in range(d + 1):
            cx = x + 0.5 - r
            lit = x < d and cx * cx + cy * cy <= r * r and (cx - ox) * (cx - ox) + (cy - oy) * (cy - oy) > r * r
            if lit and start == None:
                start = x
            elif not lit and start != None:
                runs.append(at(start, y, render.Box(width = x - start, height = 1, color = color)))
                start = None
    return render.Stack(children = [render.Box(width = d, height = d)] + runs)

def celestial_body(hour, L):
    """The sun by day or the moon by night, on an arc across the sky."""
    is_day = hour >= SUNRISE and hour <= SUNSET
    if is_day:
        frac = (hour - SUNRISE) / (SUNSET - SUNRISE)
        d = L.sun
    else:
        night = 24.0 - SUNSET + SUNRISE
        frac = (hour - SUNSET if hour > SUNSET else hour + 24.0 - SUNSET) / night
        d = L.moon

    margin = 4 * L.s
    x = int(margin + frac * (L.w - 2 * margin - d))
    y = max(L.s, int(L.arc_low - math.sin(frac * math.pi) * (L.arc_low - L.arc_high)))
    halo = 2 * L.s

    if is_day:
        return render.Stack(children = [
            at(x - halo, y - halo, render.Circle(diameter = d + 2 * halo, color = rgb(SUN_GLOW))),
            at(x, y, render.Circle(diameter = d, color = rgb(SUN_CORE))),
        ])
    return render.Stack(children = [
        at(x - halo, y - halo, render.Circle(diameter = d + 2 * halo, color = MOON_GLOW)),
        at(x, y, crescent(d, rgb(MOON))),
    ])

def time_block(hh, mm, colon_on, L):
    """The time, centered, with a drop shadow so it reads over a bright sky."""

    hh = hh.replace("0", L.zero)
    mm = mm.replace("0", L.zero)

    def row(color, colon_color, dx, dy):
        return at(dx, L.clock_top + dy, render.Row(
            main_align = "center",
            expanded = True,
            children = [
                render.Text(content = hh, font = L.clock, color = color),
                render.Text(content = ":", font = L.clock, color = colon_color),
                render.Text(content = mm, font = L.clock, color = color),
            ],
        ))

    return render.Stack(children = [
        row(SHADOW, SHADOW if colon_on else "#00000000", L.s, L.s),
        row(WHITE, WHITE if colon_on else "#ffffff00", 0, 0),
    ])

def date_label(text, L):
    def banner(color, dy):
        return at(0, L.date_top + dy, render.Row(
            main_align = "center",
            expanded = True,
            children = [render.Text(content = text, font = L.date, color = color)],
        ))

    return render.Stack(children = [banner(DATE_SHADOW, L.s), banner(WHITE, 0)])

def day_bar(hour, L):
    """A bar along the bottom edge showing how much of the day has passed."""
    filled = max(1, min(L.w, int(hour / 24.0 * L.w)))
    return at(0, L.h - L.s, render.Row(children = [
        render.Box(width = filled, height = L.s, color = BAR),
        render.Box(width = L.w - filled, height = L.s, color = BAR_TRACK),
    ]))

# ---------------------------------------------------------------- app

def clock_digits(t, use_24h):
    if use_24h:
        return t.format("15"), t.format("04")
    return t.format("3"), t.format("04")

def main(config):
    L = layout()

    location = config.get("location")
    loc = json.decode(location) if location else {}
    tz = loc.get("timezone") or config.get("$tz", time.tz())
    now = time.now()

    # For previews: test_time=2026-01-02T15:04:05Z renders a fixed time.
    test_time = config.get("test_time")
    if test_time:
        now = time.parse_time(test_time)
    now = now.in_location(tz)

    use_24h = config.bool("military", False)
    hour = now.hour + now.minute / 60.0 + now.second / 3600.0
    darkness = darkness_at(hour)

    bg = sky(hour, L)
    body = celestial_body(hour, L)
    bar = day_bar(hour, L)

    frames = []
    for i in range(FRAMES):
        t = now + time.parse_duration("%dms" % (i * FRAME_MS))
        hh, mm = clock_digits(t, use_24h)
        colon_on = t.nanosecond < 500000000
        layers = [bg]
        stars = star_layer(i, hour, darkness, L)
        if stars != None:
            layers.append(stars)
        layers.append(body)
        layers.append(time_block(hh, mm, colon_on, L))
        layers.append(date_label(t.format("Mon Jan 2").upper(), L))
        layers.append(bar)
        frames.append(render.Stack(children = layers))

    return render.Root(delay = FRAME_MS, child = render.Animation(children = frames))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Sets the timezone. Leave blank to use the device's.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "military",
                name = "24-hour clock",
                desc = "Show the time in 24-hour format.",
                icon = "clock",
                default = False,
            ),
        ],
    )
