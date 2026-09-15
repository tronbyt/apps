"""
Applet: Season Clock
Summary: Countdown to the next season
Description: Shows a lively seasonal scene with a countdown to the next astronomical season, or the current day of the season, for either hemisphere. Stack two instances to see both at once.
Author: Joe Vivona
"""

load("encoding/json.star", "json")
load("images/ball.png", BALL_1X = "file")
load("images/ball@2x.png", BALL_2X = "file")
load("images/bfly.png", BFLY_1X = "file")
load("images/bfly@2x.png", BFLY_2X = "file")
load("images/flower0.png", FLOWER0_1X = "file")
load("images/flower0@2x.png", FLOWER0_2X = "file")
load("images/flower1.png", FLOWER1_1X = "file")
load("images/flower1@2x.png", FLOWER1_2X = "file")
load("images/flower2.png", FLOWER2_1X = "file")
load("images/flower2@2x.png", FLOWER2_2X = "file")
load("images/flower3.png", FLOWER3_1X = "file")
load("images/flower3@2x.png", FLOWER3_2X = "file")
load("images/flower4.png", FLOWER4_1X = "file")
load("images/flower4@2x.png", FLOWER4_2X = "file")
load("images/leaf_gold.png", LEAF_GOLD_1X = "file")
load("images/leaf_gold@2x.png", LEAF_GOLD_2X = "file")
load("images/leaf_org.png", LEAF_ORG_1X = "file")
load("images/leaf_org@2x.png", LEAF_ORG_2X = "file")
load("images/leaf_red.png", LEAF_RED_1X = "file")
load("images/leaf_red@2x.png", LEAF_RED_2X = "file")
load("images/leafpile.png", LEAFPILE_1X = "file")
load("images/leafpile@2x.png", LEAFPILE_2X = "file")
load("images/snow.png", SNOW_1X = "file")
load("images/snow@2x.png", SNOW_2X = "file")

# Sprites (1x + @2x). The matching set is chosen at render time via canvas.is2x().
load("images/snowman.png", SNOWMAN_1X = "file")
load("images/snowman@2x.png", SNOWMAN_2X = "file")
load("images/sun.png", SUN_1X = "file")
load("images/sun@2x.png", SUN_2X = "file")
load("images/tree.png", TREE_1X = "file")
load("images/tree@2x.png", TREE_2X = "file")
load("math.star", "math")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

# --- Resolution ---
IS2X = canvas.is2x()
SCALE = 2 if IS2X else 1
LW, LH = 64, 32  # logical canvas; physical = LW*SCALE x LH*SCALE

def pick(a1, a2):
    return a2.readall() if IS2X else a1.readall()

SPR = {
    "snowman": pick(SNOWMAN_1X, SNOWMAN_2X),
    "snow": pick(SNOW_1X, SNOW_2X),
    "tree": pick(TREE_1X, TREE_2X),
    "leafpile": pick(LEAFPILE_1X, LEAFPILE_2X),
    "leaf_red": pick(LEAF_RED_1X, LEAF_RED_2X),
    "leaf_org": pick(LEAF_ORG_1X, LEAF_ORG_2X),
    "leaf_gold": pick(LEAF_GOLD_1X, LEAF_GOLD_2X),
    "sun": pick(SUN_1X, SUN_2X),
    "ball": pick(BALL_1X, BALL_2X),
    "flower0": pick(FLOWER0_1X, FLOWER0_2X),
    "flower1": pick(FLOWER1_1X, FLOWER1_2X),
    "flower2": pick(FLOWER2_1X, FLOWER2_2X),
    "flower3": pick(FLOWER3_1X, FLOWER3_2X),
    "flower4": pick(FLOWER4_1X, FLOWER4_2X),
    "bfly": pick(BFLY_1X, BFLY_2X),
}
FLOWER_STAGES = [SPR["flower%d" % i] for i in range(5)]
LEAF_SPRITES = [SPR["leaf_red"], SPR["leaf_org"], SPR["leaf_gold"]]

# --- Timing ---
FRAME_COUNT = 30
DELAY_MS = 90
GROUND_Y = 26  # logical row where ground starts

# --- Season palette / metadata ---
# v1 Tidbyt panels run noticeably brighter than later hardware, so the full
# broad sky/ground fills glare. BG_DIM scales those fills toward black; sprites
# and text keep full brightness so they still pop against the calmer backdrop.
BG_DIM = 0.1

_HEXD = "0123456789abcdef"

def _hex2(n):
    n = 0 if n < 0 else (255 if n > 255 else n)
    return _HEXD[n // 16] + _HEXD[n % 16]

def dim_hex(hex_color, factor = BG_DIM):
    # Scale an "#rrggbb" color's channels toward black by `factor` (0..1).
    h = hex_color[1:]
    r = int(int(h[0:2], 16) * factor)
    g = int(int(h[2:4], 16) * factor)
    b = int(int(h[4:6], 16) * factor)
    return "#" + _hex2(r) + _hex2(g) + _hex2(b)

_RAW_SEASON = {
    "spring": {"label": "SPRING", "sky": "#79c7e8", "ground": "#5aa72e"},
    "summer": {"label": "SUMMER", "sky": "#3fa9f5", "ground": "#36b6c7"},
    "autumn": {"label": "AUTUMN", "sky": "#e29a44", "ground": "#7c5a32"},
    "winter": {"label": "WINTER", "sky": "#2b4a72", "ground": "#e6eef8"},
}
SEASON = {
    k: {"label": v["label"], "sky": dim_hex(v["sky"]), "ground": dim_hex(v["ground"])}
    for k, v in _RAW_SEASON.items()
}

# Summer beach palette. Kept brighter than the dimmed seasons so the sand/sea
# actually read as a beach; the sun, ball, and text still pop on top.
SUMMER_SKY = "#2d5a82"
SUMMER_SEA = "#1f6f9c"
SUMMER_SEAFOAM = "#5fb0d8"
SUMMER_SAND = "#9c7f3e"
SUMMER_FOAM = "#cdeeff"

# Astronomical event -> season, by hemisphere.
EVENT_SEASON = {
    "northern": {
        "mar_equinox": "spring",
        "jun_solstice": "summer",
        "sep_equinox": "autumn",
        "dec_solstice": "winter",
    },
    "southern": {
        "mar_equinox": "autumn",
        "jun_solstice": "winter",
        "sep_equinox": "spring",
        "dec_solstice": "summer",
    },
}

# Equinox/solstice instants in UTC (Meeus, validated to the minute vs published
# 2025 values). Covers 2024-2036; outside that range the app shows a notice.
BOUNDARIES = [
    ("2024-03-20T03:06:30Z", "mar_equinox"),
    ("2024-06-20T20:50:50Z", "jun_solstice"),
    ("2024-09-22T12:43:39Z", "sep_equinox"),
    ("2024-12-21T09:20:21Z", "dec_solstice"),
    ("2025-03-20T09:01:31Z", "mar_equinox"),
    ("2025-06-21T02:42:17Z", "jun_solstice"),
    ("2025-09-22T18:19:28Z", "sep_equinox"),
    ("2025-12-21T15:03:05Z", "dec_solstice"),
    ("2026-03-20T14:45:30Z", "mar_equinox"),
    ("2026-06-21T08:24:50Z", "jun_solstice"),
    ("2026-09-23T00:05:25Z", "sep_equinox"),
    ("2026-12-21T20:50:07Z", "dec_solstice"),
    ("2027-03-20T20:24:48Z", "mar_equinox"),
    ("2027-06-21T14:10:36Z", "jun_solstice"),
    ("2027-09-23T06:01:12Z", "sep_equinox"),
    ("2027-12-22T02:42:11Z", "dec_solstice"),
    ("2028-03-20T02:17:02Z", "mar_equinox"),
    ("2028-06-20T20:01:28Z", "jun_solstice"),
    ("2028-09-22T11:45:01Z", "sep_equinox"),
    ("2028-12-21T08:20:00Z", "dec_solstice"),
    ("2029-03-20T08:01:35Z", "mar_equinox"),
    ("2029-06-21T01:48:14Z", "jun_solstice"),
    ("2029-09-22T17:37:48Z", "sep_equinox"),
    ("2029-12-21T14:14:17Z", "dec_solstice"),
    ("2030-03-20T13:51:46Z", "mar_equinox"),
    ("2030-06-21T07:31:14Z", "jun_solstice"),
    ("2030-09-22T23:27:06Z", "sep_equinox"),
    ("2030-12-21T20:09:26Z", "dec_solstice"),
    ("2031-03-20T19:40:59Z", "mar_equinox"),
    ("2031-06-21T13:17:06Z", "jun_solstice"),
    ("2031-09-23T05:15:19Z", "sep_equinox"),
    ("2031-12-22T01:55:56Z", "dec_solstice"),
    ("2032-03-20T01:22:04Z", "mar_equinox"),
    ("2032-06-20T19:08:37Z", "jun_solstice"),
    ("2032-09-22T11:10:40Z", "sep_equinox"),
    ("2032-12-21T07:56:03Z", "dec_solstice"),
    ("2033-03-20T07:22:53Z", "mar_equinox"),
    ("2033-06-21T01:00:54Z", "jun_solstice"),
    ("2033-09-22T16:51:42Z", "sep_equinox"),
    ("2033-12-21T13:45:33Z", "dec_solstice"),
    ("2034-03-20T13:17:29Z", "mar_equinox"),
    ("2034-06-21T06:44:22Z", "jun_solstice"),
    ("2034-09-22T22:39:39Z", "sep_equinox"),
    ("2034-12-21T19:33:52Z", "dec_solstice"),
    ("2035-03-20T19:03:18Z", "mar_equinox"),
    ("2035-06-21T12:32:43Z", "jun_solstice"),
    ("2035-09-23T04:38:43Z", "sep_equinox"),
    ("2035-12-22T01:30:49Z", "dec_solstice"),
    ("2036-03-20T01:02:36Z", "mar_equinox"),
    ("2036-06-20T18:31:28Z", "jun_solstice"),
    ("2036-09-22T10:23:26Z", "sep_equinox"),
    ("2036-12-21T07:12:42Z", "dec_solstice"),
]

# Pre-parse the static boundary instants once at load so find_seasons doesn't
# re-parse ~52 ISO strings on every render.
PARSED_BOUNDARIES = [(time.parse_time(iso), event) for iso, event in BOUNDARIES]

DEFAULT_LOCATION = """
{
	"lat": "40.6781784",
	"lng": "-73.9441579",
	"description": "Brooklyn, NY, USA",
	"locality": "Brooklyn",
	"timezone": "America/New_York"
}
"""

# Fonts
NUM_FONT_BIG = "terminus-32" if IS2X else "10x20"
NUM_FONT_SM = "terminus-22" if IS2X else "6x13"
LBL_FONT = "6x13" if IS2X else "tom-thumb"
NUM_ADVANCE = 8 if IS2X else 10  # logical px per digit (x SCALE -> physical), for placing the ordinal suffix

COLOR_TEXT = "#ffffff"
COLOR_SHADOW = "#00000099"

def julian_day(y, m, d):
    # Julian Day Number for a Gregorian date; difference gives whole calendar days.
    a = (14 - m) // 12
    yy = y + 4800 - a
    mm = m + 12 * a - 3
    return d + (153 * mm + 2) // 5 + 365 * yy + yy // 4 - yy // 100 + yy // 400 - 32045

def ordinal_suffix(n):
    if 11 <= (n % 100) and (n % 100) <= 13:
        return "th"
    last = n % 10
    if last == 1:
        return "st"
    elif last == 2:
        return "nd"
    elif last == 3:
        return "rd"
    return "th"

def find_seasons(now_unix):
    # Return (current_event, current_start_time, next_event, next_start_time) or None.
    current = None
    next = None
    for bt, event in PARSED_BOUNDARIES:
        if bt.unix <= now_unix:
            current = (event, bt)
        elif next == None:
            next = (event, bt)
            break
    if current == None or next == None:
        return None
    return current[0], current[1], next[0], next[1]

# ---------- scene drawing ----------

def place(sprite, lx, ly):
    # Padding insets must be >= 0; clamp so off-screen particles don't error.
    return render.Padding(
        pad = (max(0, int(lx * SCALE)), max(0, int(ly * SCALE)), 0, 0),
        child = render.Image(src = sprite),
    )

def box(lx, ly, lw, lh, color):
    return render.Padding(
        pad = (int(lx * SCALE), int(ly * SCALE), 0, 0),
        child = render.Box(width = int(lw * SCALE), height = int(lh * SCALE), color = color),
    )

def make_falling(sprites, count, cycles, sway):
    # Particles that fall top->bottom and loop seamlessly over FRAME_COUNT.
    ps = []
    for _ in range(count):
        ps.append({
            "x": random.number(0, LW - 1),
            "y0": random.number(0, LH + 3),
            "k": cycles[random.number(0, len(cycles) - 1)],
            "phase": random.number(0, 100) / 100.0 * 2 * math.pi,
            "amp": sway,
            "spr": sprites[random.number(0, len(sprites) - 1)],
        })
    return ps

def draw_falling(ps, f):
    period = LH + 4
    widgets = []
    for p in ps:
        y = (p["y0"] + p["k"] * period * f / FRAME_COUNT) % period
        x = p["x"] + p["amp"] * math.sin(2 * math.pi * f / FRAME_COUNT + p["phase"])
        widgets.append(place(p["spr"], int(x), int(y)))
    return widgets

def winter_scene(f):
    w = [box(0, 0, LW, LH, SEASON["winter"]["sky"])]
    w.append(box(0, GROUND_Y, LW, LH - GROUND_Y, SEASON["winter"]["ground"]))
    w.append(place(SPR["snowman"], 43, 31 - 25))
    w.extend(draw_falling(WINTER_SNOW, f))
    return w

def autumn_scene(f):
    w = [box(0, 0, LW, LH, SEASON["autumn"]["sky"])]
    w.append(box(0, GROUND_Y, LW, LH - GROUND_Y, SEASON["autumn"]["ground"]))
    w.append(place(SPR["tree"], 39, 31 - 24))
    w.append(place(SPR["leafpile"], 41, GROUND_Y))  # raked pile at the trunk base
    w.extend(draw_falling(AUTUMN_LEAVES, f))
    return w

def summer_scene(f):
    ph = 2 * math.pi * f / FRAME_COUNT
    w = [box(0, 0, LW, LH, SUMMER_SKY)]

    # sea below the horizon; the sand overdraws its lower part at the waterline
    sea_top = 13
    w.append(box(0, sea_top, LW, LH - sea_top, SUMMER_SEA))

    # lighter swells drifting down the sea for a touch of motion
    w.append(box(0, sea_top + 2 + int((math.sin(ph) + 1) * 1.5), LW, 1, SUMMER_SEAFOAM))
    w.append(box(0, sea_top + 6 + int((math.sin(ph + 2.1) + 1) * 1.5), LW, 1, SUMMER_SEAFOAM))

    # the waterline washes in and out over the sand. Sample the foam edge per
    # 1px column from two offset sine waves so the shoreline curves in rounded
    # humps (a base sand box covers the always-wet rows; only the crest band and
    # the foam cap are drawn per column). It also drifts in/out over time.
    base = 22 + math.sin(ph) * 1.5
    edges = [int(base + math.sin(i * 0.28 + ph) * 2.0 + math.sin(i * 0.08 + ph) * 1.0 + 0.5) for i in range(LW)]
    mx = max(edges)
    w.append(box(0, mx, LW, LH - mx, SUMMER_SAND))
    for i in range(LW):
        ey = edges[i]
        if ey < mx:
            w.append(box(i, ey, 1, mx - ey, SUMMER_SAND))
        w.append(box(i, ey - 1, 1, 1, SUMMER_FOAM))

    # sun bobbing (kept as-is)
    sun_y = 1 + int(math.sin(ph) * 1.5 + 1.5)
    w.append(place(SPR["sun"], 46, sun_y))

    # beach ball rolling back and forth along the beach (clear of the left text)
    ball_x = 32 + int((math.sin(ph + 1.5) * 0.5 + 0.5) * 20)
    ball_y = 21 + int((math.sin(ph * 2) + 1) * 0.5)
    w.append(place(SPR["ball"], ball_x, ball_y))
    return w

def spring_scene(f):
    w = [box(0, 0, LW, LH, SEASON["spring"]["sky"])]
    w.append(box(0, GROUND_Y, LW, LH - GROUND_Y, SEASON["spring"]["ground"]))

    # flowers growing (staggered growth cycles)
    for fl in SPRING_FLOWERS:
        t = ((f / FRAME_COUNT) + fl["phase"]) % 1.0
        stage = int(t * len(FLOWER_STAGES))
        stage = min(stage, len(FLOWER_STAGES) - 1)
        w.append(place(FLOWER_STAGES[stage], fl["x"], 31 - 17))

    # butterflies drifting
    for b in SPRING_BFLY:
        x = b["x"] + b["ax"] * math.sin(2 * math.pi * f / FRAME_COUNT + b["phase"])
        y = b["y"] + b["ay"] * math.cos(2 * math.pi * f / FRAME_COUNT + b["phase"])
        w.append(place(SPR["bfly"], int(x), int(y)))
    return w

SCENE_FN = {
    "winter": winter_scene,
    "autumn": autumn_scene,
    "summer": summer_scene,
    "spring": spring_scene,
}

# ---------- text overlay ----------

def outline_text(content, font, lx, ly):
    # White text with a 1px black outline so it reads on any seasonal background.
    bx, by = int(lx * SCALE), int(ly * SCALE)
    layers = []
    for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
        layers.append(render.Padding(
            pad = (max(0, bx + dx), max(0, by + dy), 0, 0),
            child = render.Text(content = content, font = font, color = COLOR_SHADOW),
        ))
    layers.append(render.Padding(
        pad = (bx, by, 0, 0),
        child = render.Text(content = content, font = font, color = COLOR_TEXT),
    ))
    return render.Stack(children = layers)

LBL_Y1 = 19 if IS2X else 20
LBL_Y2 = 26

def text_overlay(big, suffix, line1, line2):
    # big number on the left; two small label lines beneath it.
    num_font = NUM_FONT_BIG if len(big) <= 2 else NUM_FONT_SM
    widgets = [outline_text(big, num_font, 2, 0)]
    if suffix != "":
        # ordinal suffix tucked next to the number, small
        widgets.append(outline_text(suffix, LBL_FONT, 3 + len(big) * NUM_ADVANCE, 1))
    widgets.append(outline_text(line1, LBL_FONT, 2, LBL_Y1))
    widgets.append(outline_text(line2, LBL_FONT, 2, LBL_Y2))
    return widgets

def notice(msg):
    return render.Root(
        child = render.Box(
            color = "#101820",
            child = render.WrappedText(content = msg, font = "tb-8", color = "#ffcc00", align = "center"),
        ),
    )

# ---------- main ----------

def main(config):
    location = json.decode(config.get("location") or DEFAULT_LOCATION)
    timezone = location.get("timezone", time.tz())
    hemisphere = "southern" if float(location.get("lat", "0")) < 0 else "northern"
    mode = config.get("mode") or "countdown"

    # "dev_date" is a hidden test hook (not in the schema). When set to an
    # RFC3339 instant it overrides "now", letting the test harness force any
    # season / hemisphere / day deterministically.
    dev_date = config.get("dev_date") or ""
    if dev_date != "":
        now = time.parse_time(dev_date)
    else:
        now = time.now()
    seasons = find_seasons(now.unix)
    if seasons == None:
        return notice("Season Clock needs an update (out of date range).")
    cur_event, cur_start, nxt_event, nxt_start = seasons

    now_local = now.in_location(timezone)
    jd_now = julian_day(now_local.year, now_local.month, now_local.day)

    if mode == "dayof":
        s_local = cur_start.in_location(timezone)
        jd_start = julian_day(s_local.year, s_local.month, s_local.day)
        day_of = jd_now - jd_start + 1
        season = EVENT_SEASON[hemisphere][cur_event]
        big = str(day_of)
        suffix = ordinal_suffix(day_of)
        line1 = "DAY OF"
        line2 = SEASON[season]["label"]
    else:
        n_local = nxt_start.in_location(timezone)
        jd_next = julian_day(n_local.year, n_local.month, n_local.day)
        days = jd_next - jd_now
        season = EVENT_SEASON[hemisphere][nxt_event]
        suffix = ""
        if days <= 0:
            big = "0"
            line1 = "STARTS"
            line2 = SEASON[season]["label"]
        else:
            big = str(days)
            line1 = "DAY TO" if days == 1 else "DAYS TO"
            line2 = SEASON[season]["label"]

    scene_fn = SCENE_FN[season]
    overlay = text_overlay(big, suffix, line1, line2)

    frames = []
    for f in range(FRAME_COUNT):
        children = scene_fn(f) + overlay
        frames.append(render.Stack(children = children))

    return render.Root(
        child = render.Animation(children = frames),
        delay = DELAY_MS,
    )

# Particle systems (seeded once per render for variety, stable within the render).
random.seed(int(time.now().unix // 21600))
WINTER_SNOW = make_falling([SPR["snow"]], 26, [1, 2], 2.0)
AUTUMN_LEAVES = make_falling(LEAF_SPRITES, 22, [1, 2], 3.0)
SPRING_FLOWERS = [{"x": 2 + i * 12, "phase": random.number(0, 100) / 100.0} for i in range(5)]
SPRING_BFLY = [
    {
        "x": random.number(30, LW - 8),
        "y": random.number(2, 14),
        "ax": random.number(3, 8),
        "ay": random.number(2, 5),
        "phase": random.number(0, 100) / 100.0 * 2 * math.pi,
    }
    for _ in range(3)
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Used for your hemisphere and timezone.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "mode",
                name = "Display",
                desc = "Countdown to the next season, or the current day of the season.",
                icon = "calendarDays",
                default = "countdown",
                options = [
                    schema.Option(display = "Countdown to next season", value = "countdown"),
                    schema.Option(display = "Current day of season", value = "dayof"),
                ],
            ),
        ],
    )
