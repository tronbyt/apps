"""
Weather Diorama — Hourly
Now, +3 hours and +6 hours as one living landscape: the sky blends left to right
through time, each third acts out its weather (sun, moon phase, clouds, fog, rain,
showers, storms, snow), with wind and wildfire smoke layered on top. Each temperature
is tinted by where it falls in that day's range: warm white at the high, blue at the low.

Weather + sunrise/sunset: Open-Meteo forecast API (free, no key)
Smoke: Open-Meteo air-quality API, PM2.5 (free, no key)
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

FRAMES = 48  # 120 ms each; every scene loop below has a period that divides 16
HILO_FRAMES = 64  # 3-day loop (~7.7 s), split in two mirrored halves: high -> low, then low -> high
HILO_STYLES = ["count", "fade", "crossfade", "roll", "cascade", "flip"]
HOLD = 18
COUNT = 14
COLS = [(0, 22), (22, 22), (44, 20)]
CENTERS = [11, 33, 54]
WARM = "#FFD9B0"  # warm white: softer than pure white on LEDs
PALE_LOW = "#9FD4FF"
LABEL = "#E0C890"
HEX = "0123456789ABCDEF"

# ── color helpers ────────────────────────────────────────────────────────────
def h2(n):
    n = max(0, min(255, int(n)))
    return HEX[n // 16] + HEX[n % 16]

def rgb(c):
    return [int(c[1:3], 16), int(c[3:5], 16), int(c[5:7], 16)]

def mix(a, b, f):
    x = rgb(a)
    y = rgb(b)
    return "#" + "".join([h2(x[i] + (y[i] - x[i]) * f) for i in range(3)])

# ── sky: (top, bottom) per time of day, clear vs overcast ───────────────────
CLEAR_SKY = {
    "dawn": ("#1E2A5A", "#D07A58"),
    "day": ("#0E3F80", "#3E86C8"),
    "dusk": ("#2A1840", "#B0505A"),
    "night": ("#02040C", "#0E1834"),
}
GREY_SKY = {
    "dawn": ("#2A2E40", "#7A6670"),
    "day": ("#2E3846", "#6A7684"),
    "dusk": ("#22202E", "#5A4450"),
    "night": ("#05070C", "#151B26"),
}

def sky_stops(s):
    top, bot = base_sky(s)
    if s.get("smoke"):
        tint = "#2A1408" if s["tod"] == "night" else "#7A4A28"
        return (mix(top, tint, 0.6), mix(bot, tint, 0.6))
    return (top, bot)

def base_sky(s):
    c = s["c"]
    tod = s["tod"]
    if c in ("clear", "partly", "showers"):
        return CLEAR_SKY[tod]
    top, bot = GREY_SKY[tod]
    if c == "storm":
        return (mix(top, "#000000", 0.4), mix(bot, "#000000", 0.4))
    if c == "fog":
        return (mix(top, bot, 0.5), bot)
    return (top, bot)

def sky(slots):
    stops = [sky_stops(s) for s in slots]
    cols = []
    for x in range(64):
        if x <= CENTERS[0]:
            a, b, t = 0, 0, 0.0
        elif x >= CENTERS[2]:
            a, b, t = 2, 2, 0.0
        elif x < CENTERS[1]:
            a, b, t = 0, 1, (x - CENTERS[0]) / (CENTERS[1] - CENTERS[0])
        else:
            a, b, t = 1, 2, (x - CENTERS[1]) / (CENTERS[2] - CENTERS[1])
        top = mix(stops[a][0], stops[b][0], t)
        bot = mix(stops[a][1], stops[b][1], t)
        bands = [render.Box(width = 1, height = 5, color = mix(top, bot, k / 4.0)) for k in range(5)]

        # ground under the labels: the sky's own bottom color, darkened so the labels stay readable
        bands.append(render.Box(width = 1, height = 7, color = mix(bot, "#000000", 0.55)))
        cols.append(render.Column(children = bands))
    return render.Row(children = cols)

# ── pixel art ────────────────────────────────────────────────────────────────
CLOUD = [
    "......WWWW.........",
    "....WWWWWWW..WWW...",
    "..WWWWWWWWWWWWWWWW.",
    ".WWWWWWWWWWWWWWWWWW",
    "WWWWWWWWWWWWWWWWWWW",
    ".GGGGGGGGGGGGGGGGG.",
]
SMALL_CLOUD = [
    "....WWWW......",
    "..WWWWWWW.WW..",
    ".WWWWWWWWWWWWW",
    "WWWWWWWWWWWWWW",
    ".GGGGGGGGGGGG.",
]
BOLT = [
    "..YY",
    ".YY.",
    "YYYY",
    "..YY",
    ".YY.",
    ".Y..",
    "Y...",
]

# light cloud (partly/cloudy) and heavy cloud (precip) per time of day
LIGHT_CLOUD = {
    "dawn": {"W": "#F0CFC0", "G": "#A08090"},
    "day": {"W": "#E8EEF2", "G": "#8A97A6"},
    "dusk": {"W": "#D8A0A8", "G": "#705068"},
    "night": {"W": "#4A5468", "G": "#2A3242"},
}
HEAVY_CLOUD = {
    "dawn": {"W": "#A89098", "G": "#6A5A68"},
    "day": {"W": "#9AA4B0", "G": "#5A6470"},
    "dusk": {"W": "#806878", "G": "#4A3A50"},
    "night": {"W": "#3A4252", "G": "#22283A"},
}
FOG = {"dawn": "#B8A0A0", "day": "#A8B2BC", "dusk": "#8A6A7A", "night": "#2E3440"}
RAIN = {"dawn": "#7AB8F0", "day": "#6AB8FF", "dusk": "#7AA0E0", "night": "#4A80C0"}

def pixart(rows, pal):
    out = []
    for r in rows:
        cells = []
        prev = None
        n = 0
        for i in range(len(r) + 1):
            ch = r[i] if i < len(r) else None
            if ch == prev:
                n += 1
                continue
            if prev != None:
                if prev == ".":
                    cells.append(render.Box(width = n, height = 1))
                else:
                    cells.append(render.Box(width = n, height = 1, color = pal[prev]))
            prev = ch
            n = 1
        out.append(render.Row(children = cells))
    return render.Column(children = out)

def moon_rows(phase):
    # lit side follows the Northern Hemisphere view: waxing lights the right
    p = phase / 8.0
    c = math.cos(2 * math.pi * p)
    rows = []
    for y in range(9):
        dy = y - 4
        hw = math.sqrt(max(0.0, 20.25 - dy * dy))
        row = ""
        for x in range(9):
            dx = x - 4
            if dx * dx + dy * dy > 20:
                row += "."
            elif (p <= 0.5 and dx > c * hw) or (p > 0.5 and dx < -c * hw):
                row += "L"
            else:
                row += "D"
        rows.append(row)
    return rows

MOON_PAL = {"L": "#F2EBD0", "D": "#1C2438"}

def at(x, y, child):
    return render.Padding(pad = (x, y, 0, 0), child = child)

def txt(s, color, font = "tom-thumb"):
    return render.Text(str(s), font = font, color = color)

# ── scene pieces ─────────────────────────────────────────────────────────────
STARS = [(1, 2), (19, 1), (17, 7), (3, 9), (20, 11), (8, 0), (13, 10), (2, 15)]

def stars(x0, w, f, count):
    out = []
    for k in range(count):
        sx, sy = STARS[k]
        if sx >= w:
            continue
        bright = (f + k * 3) % 8 < 5
        out.append(at(x0 + sx, sy, render.Box(width = 1, height = 1, color = "#C8D0E8" if bright else "#4A5470")))
    return out

def sky_pos(x0, w, tod):
    # one fixed spot per time of day for the 9px sun/moon, whatever the condition:
    # dawn low on the left, day high in the middle, dusk low on the right, night moon in the middle
    if tod == "dawn":
        return (x0 + 2, 2)
    if tod == "dusk":
        return (x0 + w - 11, 2)
    if tod == "night":
        return (x0 + w // 2 - 4, 1)
    return (x0 + w // 2 - 4, 0)

def sun(x0, w, tod, f, smoke = False):
    x, y = sky_pos(x0, w, tod)
    if smoke:
        # a dim red disk with no glow, the way the sun looks through wildfire smoke
        return [at(x + 1, y + 1, render.Circle(diameter = 7, color = "#C8402A"))]
    if tod == "day":
        ring, core = "#7A6420", "#FFC830"
    elif tod == "dawn":
        ring, core = "#7A3A20", "#FF9A3C"
    else:
        ring, core = "#6A2A30", "#FF7040"
    glow = "#FFF0A0" if f % 8 < 4 else "#FFE070"
    return [
        at(x, y, render.Circle(diameter = 9, color = ring)),
        at(x + 1, y + 1, render.Circle(diameter = 7, color = core)),
        at(x + 3, y + 3, render.Circle(diameter = 3, color = glow if tod == "day" else core)),
    ]

def sun_or_moon(x0, w, tod, f, ph, smoke, star_count):
    if tod == "night":
        x, y = sky_pos(x0, w, tod)
        return stars(x0, w, f, star_count) + [moon(x, y, ph, smoke)]
    return sun(x0, w, tod, f, smoke)

def moon(x, y, phase, smoke = False):
    return at(x, y, pixart(moon_rows(phase), {"L": "#F0A060", "D": "#2A1810"} if smoke else MOON_PAL))

def drift(f, wind = False):
    if wind:
        return [0, 1, 2, 3, 3, 2, 1, 0][(f // 2) % 8]
    d = (f // 4) % 4
    return d if d < 3 else 1

def falling(x0, w, f, n, top, span, speed, color, h = 1, sway = False, slant = False):
    out = []
    for k in range(n):
        dx = (k * 3 + (k % 2) + k // 7) % (w - 2) + 1
        if sway:
            dx += ((f // 4 + k) % 4) // 2
        dy = top + ((k * 5 + f * speed) % span)
        if slant:
            # wind pushes everything right as it falls
            dx = 1 + (dx - 1 + (dy - top) // 2) % (w - 2)
            if h > 1:
                out.append(at(x0 + dx, dy, render.Box(width = 1, height = 1, color = color)))
                out.append(at(x0 + (dx + 1) % w, dy + 1, render.Box(width = 1, height = 1, color = color)))
                continue
        out.append(at(x0 + dx, dy, render.Box(width = 1, height = h, color = color)))
    return out

COUNTS = {
    "rain": {"light": 4, "mod": 7, "heavy": 12},
    "showers": {"light": 3, "mod": 5, "heavy": 9},
    "snow": {"light": 4, "mod": 8, "heavy": 14},
    "drizzle": {"light": 4, "mod": 4, "heavy": 6},
    "storm": {"light": 9, "mod": 9, "heavy": 12},
}

def wind_streaks(x0, w, tod, f, smoke):
    col = "#C0A080" if smoke else "#5A6478" if tod == "night" else "#C8D4E0"
    out = []
    for k, row in enumerate([3, 10, 23]):
        x = (f * 3 + k * 9) % 24 - 2
        lo = max(0, x)
        hi = min(w, x + 4)
        if hi > lo:
            out.append(at(x0 + lo, row, render.Box(width = hi - lo, height = 1, color = col)))
    return out

def scene(s, x0, w, f):
    c = s["c"]
    tod = s["tod"]
    ph = int(s.get("ph", 4))
    wind = bool(s.get("wind"))
    smoke = bool(s.get("smoke"))
    heavy = s.get("i", "mod") == "heavy"
    n = COUNTS.get(c, {}).get(s.get("i", "mod"), 0)
    d = drift(f, wind)
    els = []
    if c == "clear":
        els += sun_or_moon(x0, w, tod, f, ph, smoke, 3 if smoke else 8)
    elif c == "partly":
        # cloud sits across the lower half of the sun/moon, wherever it is
        els += sun_or_moon(x0, w, tod, f, ph, smoke, 4)
        cy = 4 if tod == "day" else 5
        els.append(at(x0 + 1 + d, cy, pixart(CLOUD, LIGHT_CLOUD[tod])))
    elif c == "showers":
        # on-and-off rain: sun or moon still out, one small cloud raining beside it
        els += sun_or_moon(x0, w, tod, f, ph, smoke, 3)
        cx = x0 + w - 15 if tod == "dawn" else x0 + 1 if tod == "dusk" else x0 + 4
        cy = 4 if tod in ("dawn", "dusk") else 5
        els += falling(cx + 1, 12, f, n, cy + 4, 16, 2, RAIN[tod], h = 2, slant = wind)
        pal = HEAVY_CLOUD[tod]
        if heavy:
            pal = {"W": mix(pal["W"], "#000000", 0.25), "G": mix(pal["G"], "#000000", 0.25)}
        els.append(at(cx + d // 2, cy, pixart(SMALL_CLOUD, pal)))
    elif c == "cloudy":
        back = {"W": LIGHT_CLOUD[tod]["G"], "G": HEAVY_CLOUD[tod]["G"]}
        els.append(at(x0 + 3 - d, 0, pixart(CLOUD, back)))
        els.append(at(x0 + d, 3, pixart(CLOUD, LIGHT_CLOUD[tod])))
    elif c == "fog":
        col = FOG[tod]
        for row in [2, 5, 8, 22, 24]:
            shift = (f // 2 + row * 3) % 8 if row % 2 else (8 - (f // 2) % 8 + row) % 8
            for x in range(x0, x0 + w):
                if (x + shift) % 8 < 6:
                    els.append(at(x, row, render.Box(width = 1, height = 1, color = col)))
    elif c in ("drizzle", "rain", "storm", "snow"):
        pal = HEAVY_CLOUD[tod]
        flash = c == "storm" and f % 16 in (6, 7, 9)
        if heavy and c != "storm":
            pal = {"W": mix(pal["W"], "#000000", 0.25), "G": mix(pal["G"], "#000000", 0.25)}
        if c == "storm":
            pal = {"W": "#C8C8D8", "G": "#8A8AA0"} if flash else {"W": mix(pal["W"], "#000000", 0.25), "G": mix(pal["G"], "#000000", 0.25)}
        if c == "snow":
            els += falling(x0, w, f, n, 7, 16, 1, "#FFFFFF", sway = not wind, slant = wind)
        elif c == "drizzle":
            els += falling(x0, w, f, n, 7, 16, 1, RAIN[tod], slant = wind)
        else:
            els += falling(x0, w, f, n, 7, 16, 2, RAIN[tod], h = 2, slant = wind)
        els.append(at(x0 + 1 + d // 2, 0, pixart(CLOUD, pal)))
        if flash:
            els.append(at(x0 + w - 7, 5, pixart(BOLT, {"Y": "#FFF4A0"})))
    if wind:
        els += wind_streaks(x0, w, tod, f, smoke)
    return els

def big_temp(t, color):
    # 6x13 digits occupy rows 2-10 of the line; degree box aligns with digit tops.
    # Three-character temps (100+, -10) drop the degree mark to fit the slot.
    digits = txt(t, color, "6x13")
    if len(str(t)) >= 3:
        return digits
    return render.Row(children = [digits, at(1, 2, render.Box(width = 2, height = 2, color = color))])

# ── live data: Open-Meteo forecast + air quality (free, no key) ──────────────
DEFAULT_LAT = "34.2478"  # Ventura, CA
DEFAULT_LON = "-119.2620"

# Pixlet can't catch a request that times out (the whole app errors and Tronbyt skips
# it that round), so keep responses cached long enough to make that rare.
CACHE_TTL = 900  # forecast: 15 min
AQ_CACHE_TTL = 3600  # air quality changes slowly: 1 h

WIND_MPH = 20  # sustained wind that turns on the windy look
GUST_MPH = 30  # ...or gusts at/above this
SMOKE_PM25 = 35.5  # µg/m³; US AQI "unhealthy for sensitive groups" starts here

# WMO weather code -> (condition, intensity). Freezing drizzle/rain draw as plain
# drizzle/rain; snow grains and snow showers draw as snow.
WMO = {
    0: ("clear", "mod"),
    1: ("clear", "mod"),
    2: ("partly", "mod"),
    3: ("cloudy", "mod"),
    45: ("fog", "mod"),
    48: ("fog", "mod"),
    51: ("drizzle", "light"),
    53: ("drizzle", "mod"),
    55: ("drizzle", "heavy"),
    56: ("drizzle", "light"),
    57: ("drizzle", "heavy"),
    61: ("rain", "light"),
    63: ("rain", "mod"),
    65: ("rain", "heavy"),
    66: ("rain", "light"),
    67: ("rain", "heavy"),
    71: ("snow", "light"),
    73: ("snow", "mod"),
    75: ("snow", "heavy"),
    77: ("snow", "light"),
    80: ("showers", "light"),
    81: ("showers", "mod"),
    82: ("showers", "heavy"),
    85: ("snow", "light"),
    86: ("snow", "heavy"),
    95: ("storm", "mod"),
    96: ("storm", "heavy"),
    99: ("storm", "heavy"),
}

SYNODIC_DAYS = 29.530588853
NEW_MOON_UNIX = 947182440  # 2000-01-06 18:14 UTC, a known new moon

def location(config):
    raw = config.get("location")
    if raw:
        loc = json.decode(raw)
        return loc["lat"], loc["lng"]
    return DEFAULT_LAT, DEFAULT_LON

def fetch_json(url, ttl = CACHE_TTL):
    resp = http.get(url, ttl_seconds = ttl)
    if resp.status_code != 200:
        return None
    return resp.json()

def fetch_pm25(lat, lon):
    # hourly PM2.5 keyed by local "YYYY-MM-DDTHH:00"; empty if the air-quality API is down
    data = fetch_json(
        "https://air-quality-api.open-meteo.com/v1/air-quality" +
        "?latitude=" + lat + "&longitude=" + lon +
        "&hourly=pm2_5&timezone=auto&forecast_days=3",
        AQ_CACHE_TTL,
    )
    if data == None or "hourly" not in data:
        return {}
    h = data["hourly"]
    return {t: v for t, v in zip(h["time"], h["pm2_5"]) if v != None}

def local_secs(s):
    # Open-Meteo local time "YYYY-MM-DDTHH:MM" -> seconds on a local (not UTC) clock
    return time.parse_time(s, format = "2006-01-02T15:04").unix

def iround(x):
    return int(math.floor(x + 0.5))

def condition(code):
    return WMO.get(int(code), ("cloudy", "mod"))

def is_windy(speed, gust):
    return (speed or 0) >= WIND_MPH or (gust or 0) >= GUST_MPH

def moon_phase(utc_secs):
    # 0 new … 4 full … 7 waning crescent
    age = ((utc_secs - NEW_MOON_UNIX) / 86400.0) % SYNODIC_DAYS
    return int(math.floor(age / SYNODIC_DAYS * 8 + 0.5)) % 8

def time_of_day(t, rise, sset):
    # dawn/dusk are the ~1.75 h windows around sunrise and sunset
    if rise - 2700 <= t and t < rise + 3600:
        return "dawn"
    if sset - 3600 <= t and t < sset + 2700:
        return "dusk"
    if rise + 3600 <= t and t < sset - 3600:
        return "day"
    return "night"

def render_unavailable():
    # "Weather unavailable" screen: a foggy sky with a dark clearing behind the words.
    fog = [{"c": "fog", "i": "mod", "tod": "day", "l": "", "t": 0} for _ in range(3)]
    bg = sky(fog)
    clearing = at(0, 1, render.Box(width = 64, height = 22, color = "#2E3640"))
    words = []
    for dx, dy, color in [(1, 1, "#1A2028"), (0, 0, WARM)]:  # shadow, then text
        words.append(at(dx, dy, render.Box(width = 64, height = 13, child = txt("WEATHER", color, "6x13"))))
        words.append(at(dx, 13 + dy, render.Box(width = 64, height = 8, child = txt("UNAVAILABLE", color, "5x8"))))
    frames = []
    for f in range(FRAMES):
        layers = [bg, clearing]

        # fog drifts along the top edge and above the ground, clear of the words
        for row in [0, 23, 24]:
            shift = (f // 2 + row * 3) % 8 if row % 2 else (8 - (f // 2) % 8 + row) % 8
            for x in range(64):
                if (x + shift) % 8 < 6:
                    layers.append(at(x, row, render.Box(width = 1, height = 1, color = FOG["day"])))
        frames.append(render.Stack(children = layers + words))
    return render.Root(delay = 120, child = render.Box(width = 64, height = 32, color = "#000000", child = render.Animation(children = frames)))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Where to show the weather for (defaults to Ventura, CA)",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "units",
                name = "Units",
                desc = "Temperature units",
                icon = "temperatureHalf",
                default = "F",
                options = [
                    schema.Option(display = "Fahrenheit", value = "F"),
                    schema.Option(display = "Celsius", value = "C"),
                ],
            ),
        ],
    )

def low_amount(f, style):
    # 0 = showing the high, 1 = showing the low. "flip" switches halfway through the
    # loop; "count" eases between the holds with a cosine curve (slow, fast, slow),
    # shared by every slot so all three start and land together.
    if style == "flip":
        return 0.0 if f < HILO_FRAMES // 2 else 1.0
    if f < HOLD:
        return 0.0
    if f < HOLD + COUNT:
        p = (f - HOLD + 1) / COUNT
    elif f < 2 * HOLD + COUNT:
        return 1.0
    else:
        p = 1 - (f - 2 * HOLD - COUNT + 1) / COUNT
    return 0.5 - 0.5 * math.cos(math.pi * p)

def eased(p):
    p = min(1.0, max(0.0, p))
    return 0.5 - 0.5 * math.cos(math.pi * p)

def phase(f, start, length):
    # 0 -> 1 eased across [start, start + length) in the first half of the loop,
    # then 1 -> 0 across the same window in the second half
    half = HILO_FRAMES // 2
    if f < half:
        return eased((f - start + 1) / length)
    return 1.0 - eased((f - half - start + 1) / length)

def alpha(color, a):
    return color + h2(255 * min(1.0, max(0.0, a)))

def hilo_number(s, w, f, style, i):
    # the big number for one 3-day slot at frame f; placed at y=10 (rows 12-20),
    # except "roll", which is a 9-row window placed at y=12
    hi, lo = s["t"], s["lo"]
    if style in ("fade", "cascade"):
        # fade through: the high fades out to the sky, then the low fades in;
        # cascade staggers the slots left to right
        start, length = (16, 16) if style == "fade" else (14 + 4 * i, 12)
        e = phase(f, start, length)
        if e < 0.5:
            child = big_temp(hi, alpha(WARM, 1 - 2 * e))
        else:
            child = big_temp(lo, alpha(PALE_LOW, 2 * e - 1))
        return render.Box(width = w, height = 13, child = child)
    if style == "crossfade":
        e = phase(f, 16, 16)
        return render.Stack(children = [
            render.Box(width = w, height = 13, child = big_temp(hi, alpha(WARM, 1 - e))),
            render.Box(width = w, height = 13, child = big_temp(lo, alpha(PALE_LOW, e))),
        ])
    if style == "roll":
        # odometer: the low rolls up from below, then everything rolls back down
        off = iround(11 * phase(f, 16, 14))
        return render.Box(width = w, height = 9, child = render.Stack(children = [
            at(0, -2 - off, render.Box(width = w, height = 13, child = big_temp(hi, WARM))),
            at(0, 9 - off, render.Box(width = w, height = 13, child = big_temp(lo, PALE_LOW))),
        ]))
    e = low_amount(f, style)  # count or flip
    t = iround(hi + (lo - hi) * e) if style == "count" else (lo if e else hi)
    return render.Box(width = w, height = 13, child = big_temp(t, mix(WARM, PALE_LOW, e)))

def draw(slots, hilo = None):
    # hilo: None (hourly, single temp) or a 3-day high/low transition from HILO_STYLES
    bg = sky(slots)
    frames = []
    for f in range(HILO_FRAMES if hilo else FRAMES):
        layers = [bg]
        for i, s in enumerate(slots):
            layers += scene(s, COLS[i][0], COLS[i][1], f)
        for i, s in enumerate(slots):
            x0, w = COLS[i]

            # big digits on rows 12-20; darkened ground rows 25-31, labels on 26-30, row 31 empty
            if hilo:
                layers.append(at(x0, 12 if hilo == "roll" else 10, hilo_number(s, w, f, hilo, i)))
            else:
                number = big_temp(s["t"], mix(WARM, PALE_LOW, s.get("shade", 0.0)))
                layers.append(at(x0, 10, render.Box(width = w, height = 13, child = number)))
            layers.append(at(x0, 26, render.Box(width = w, height = 6, child = txt(s["l"], LABEL))))
        frames.append(render.Stack(children = layers))
    return render.Root(delay = 120, child = render.Box(width = 64, height = 32, color = "#000000", child = render.Animation(children = frames)))

def temp_shade(temp, hi, lo):
    # where this temp sits in its day's range: 0 at the high (warm white), 1 at the low (blue)
    if hi == None or lo == None or hi <= lo:
        return 0.0
    return min(1.0, max(0.0, (hi - temp) / (hi - lo)))

def hour_label(s):
    h = int(s[11:13])
    return str(h % 12 or 12) + ("AM" if h < 12 else "PM")

def main(config):
    lat, lon = location(config)
    unit = "celsius" if config.get("units", "F") == "C" else "fahrenheit"
    wx = fetch_json(
        "https://api.open-meteo.com/v1/forecast" +
        "?latitude=" + lat + "&longitude=" + lon +
        "&current=temperature_2m,weather_code,wind_speed_10m,wind_gusts_10m" +
        "&hourly=temperature_2m,weather_code,wind_speed_10m,wind_gusts_10m" +
        "&daily=sunrise,sunset,temperature_2m_max,temperature_2m_min" +
        "&temperature_unit=" + unit + "&wind_speed_unit=mph&timezone=auto&forecast_days=3",
    )
    if wx == None or "current" not in wx or "hourly" not in wx:
        return render_unavailable()
    offset = wx.get("utc_offset_seconds", 0)
    pm25 = fetch_pm25(lat, lon)
    sun_times = {
        d: (local_secs(r), local_secs(ss))
        for d, r, ss in zip(wx["daily"]["time"], wx["daily"]["sunrise"], wx["daily"]["sunset"])
    }
    day_range = {
        d: (hi, lo)
        for d, hi, lo in zip(wx["daily"]["time"], wx["daily"]["temperature_2m_max"], wx["daily"]["temperature_2m_min"])
    }

    cur = wx["current"]
    hourly = wx["hourly"]
    hour_key = cur["time"][:13] + ":00"
    if hour_key not in hourly["time"]:
        return render_unavailable()
    base = hourly["time"].index(hour_key) + (1 if int(cur["time"][14:16]) >= 30 else 0)

    picks = [("NOW", cur["time"], cur["temperature_2m"], cur["weather_code"], cur["wind_speed_10m"], cur["wind_gusts_10m"])]
    for step in (3, 6):
        i = base + step
        if i >= len(hourly["time"]):
            return render_unavailable()
        ts = hourly["time"][i]
        picks.append((hour_label(ts), ts, hourly["temperature_2m"][i], hourly["weather_code"][i], hourly["wind_speed_10m"][i], hourly["wind_gusts_10m"][i]))

    slots = []
    for label, ts, temp, code, wind, gust in picks:
        if temp == None or code == None:
            return render_unavailable()
        t = local_secs(ts)
        rise, sset = sun_times.get(ts[:10], (t, t))
        c, intensity = condition(code)
        hi, lo = day_range.get(ts[:10], (None, None))
        slots.append({
            "c": c,
            "i": intensity,
            "tod": time_of_day(t, rise, sset),
            "ph": moon_phase(t - offset),
            "wind": is_windy(wind, gust),
            "smoke": pm25.get(ts[:13] + ":00", 0) >= SMOKE_PM25,
            "l": label,
            "t": iround(temp),
            "shade": temp_shade(temp, hi, lo),
        })
    return draw(slots)
