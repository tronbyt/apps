"""
Sky Today - a living pixel diorama of the actual sky above you.

Layers (back to front):
  1. Sky gradient   - palette driven by real sun elevation (dawn/day/dusk/night)
  2. Stars          - twinkle at night
  3. Sun or Moon    - positioned along a real arc; moon shows current phase
  4. Weather sprites- drifting clouds, falling rain/snow (fog greys the sky)
  5. Wind effects   - streaks/debris/cloud-race that stack as wind climbs
  6. Temperature    - tiny optional readout + wind flag on a ground bar

APIs: Open-Meteo (free, no key) for current weather.
Sun math: pixlet's built-in sunrise module (no network needed).
Moon phase: computed locally from the date.
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("sunrise.star", "sunrise")
load("time.star", "time")

WIDTH = 64
HEIGHT = 32
N_FRAMES = 60  # ~7.2s loop @ FRAME_DELAY; longer loop = gentler cloud drift
FRAME_DELAY = 120  # ms per frame

DEFAULT_LOCATION = """
{
    "lat": "37.0298687",
    "lng": "-76.3452218",
    "description": "Hampton, VA, USA",
    "locality": "Hampton",
    "place_id": "",
    "timezone": "America/New_York"
}
"""

WEATHER_URL = "https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&current=weather_code,temperature_2m,wind_speed_10m,wind_direction_10m,precipitation,snowfall,cloud_cover&hourly=weather_code&forecast_hours=4&temperature_unit=%s&windspeed_unit=%s"

# US National Weather Service active alerts (free, no key, US-only). Filtered to
# the serious tiers server-side; requires a User-Agent per NWS policy.
NWS_ALERTS_URL = "https://api.weather.gov/alerts/active?status=actual&severity=Severe,Extreme&point=%s,%s"
NWS_USER_AGENT = "SkyToday Tidbyt app (github.com/evan-vandyke/SkyToday)"
NWS_HEADERS = {"User-Agent": NWS_USER_AGENT, "Accept": "application/geo+json"}

# NWS current-observation crawl: point -> nearest station -> latest observation.
# US-only; gives real station (METAR) conditions instead of a forecast nowcast.
NWS_POINTS_URL = "https://api.weather.gov/points/%s,%s"
NWS_OBS_URL = "https://api.weather.gov/stations/%s/observations/latest"

# ===========================================================================
# LOCAL PREVIEW FALLBACK -- MUST BE False IN PRODUCTION.
# `pixlet serve` auto-fills schema.Location with a fixed Brooklyn default when
# nothing is chosen, which bypasses DEFAULT_LOCATION. When this flag is True we
# detect that exact sentinel and substitute the Hampton home default so local
# previews aren't stuck on New York. In PROD this MUST be False, otherwise real
# Brooklyn users sitting on those coordinates would be silently moved to
# Hampton. Run `bash tests/check_prod_ready.sh` before publishing -- it fails
# if this is still True.
# ===========================================================================
LOCAL_PREVIEW_FALLBACK = False

PIXLET_DEFAULT_LAT = 40.6781784
PIXLET_DEFAULT_LNG = -73.9441579

def _is_pixlet_sentinel(lat, lng):
    return abs(lat - PIXLET_DEFAULT_LAT) < 0.0005 and abs(lng - PIXLET_DEFAULT_LNG) < 0.0005

def _use_home_fallback(lat, lng):
    """Only swap in the home default when the local-preview flag is on AND the
    incoming coords are pixlet serve's Brooklyn sentinel. In prod the flag is
    False, so real locations (Brooklyn included) are always respected."""
    return LOCAL_PREVIEW_FALLBACK and _is_pixlet_sentinel(lat, lng)

# ---------------------------------------------------------------------------
# Sky palettes: 4 bands, top -> bottom, chosen by sun elevation (degrees).
# ---------------------------------------------------------------------------

PALETTES = [
    # (min_elevation, [top, upper-mid, lower-mid, bottom])
    (25, ["#1d6ee0", "#2f83ec", "#4a9bf5", "#7cc0ff"]),  # high day
    (10, ["#2a72d8", "#3f8be8", "#65a8f2", "#9ccdff"]),  # day
    (3, ["#3a6bbf", "#6f86c9", "#d98a5f", "#f2b25c"]),  # golden hour
    (-3, ["#2b3a6e", "#6e4a7e", "#c95f63", "#e8975a"]),  # sunset/sunrise
    (-9, ["#141b3d", "#2a2a5e", "#54356b", "#7c4a63"]),  # civil twilight
    (-15, ["#0a0e24", "#13183b", "#1d1f4a", "#2a2750"]),  # nautical twilight
    (-90, ["#05071d", "#06081f", "#070a22", "#080b25"]),  # night (flattened: subtle panels turn a soft top-to-bottom shift into visible banding, so the deltas here are ~1/3 of what they were)
]

# Fog/whiteout: the sky color is gone, so the whole background goes flat grey
# (light by day, dark by night) instead of a colored gradient with haze lines.
# FOG_DAY is a bright whiteout (like OVERCAST_DAY, a touch lighter/flatter); the
# warm sun_glow_widget still blends through it, so foggy mornings keep a soft sun.
FOG_DAY = ["#eceef0", "#e4e6e9", "#dcdfe3", "#d4d8dd"]
FOG_NIGHT = ["#363b45", "#31363f", "#2c3139", "#282c34"]

# Overcast: a flat, light grey so the dark storm clouds read clearly against it
# (the contrast lives in the sky being light, not in bright cloud rims).
OVERCAST_DAY = ["#e6e9ed", "#dde0e5", "#d4d8de", "#cbd0d7"]
OVERCAST_NIGHT = ["#1f222a", "#22252e", "#252934", "#282c37"]

# Daytime precip under a grey sky (overcast/storm/fog): the overcast/fog skies are
# bright near-whiteouts, so falling rain/snow/ice/hail -- and the dark clouds --
# wash out against them. A darker steel-grey backdrop gives every animation
# something to read against. (Night skies are already dark, so this is day-only.)
PRECIP_DAY = ["#9aa4b4", "#929cac", "#8a94a4", "#828c9c"]

# Wildfire smoke / heavy haze: the sky is gone, replaced by an eerie orange-brown
# murk (a warm cousin of the fog whiteout). Day is a hazy tan-orange; night a dark
# smoky brown. The sun shows as a dim red ember through it (see sun_ember_widget).
SMOKE_DAY = ["#a8693a", "#b3743f", "#bd8049", "#c69257"]
SMOKE_NIGHT = ["#2c1f17", "#31241a", "#35281d", "#392b1f"]

def pick_palette(elev):
    for min_elev, colors in PALETTES:
        if elev >= min_elev:
            return colors
    return PALETTES[-1][1]

def sky_palette(elev, is_day, fog, clouds, storm, precip, smoke):
    """Choose the background palette: wildfire smoke orange > daytime-snow steel >
    fog whiteout > overcast grey > the normal elevation-driven gradient. Smoke and
    fog replace the sky color entirely; overcast/storm flatten the blue to grey;
    daytime snow gets a darker backdrop so white flakes don't vanish."""
    if smoke:
        return SMOKE_DAY if is_day else SMOKE_NIGHT
    if is_day and precip != None and (fog or clouds >= 4 or storm):
        return PRECIP_DAY
    if fog:
        return FOG_DAY if is_day else FOG_NIGHT
    if clouds >= 4 or storm:
        return OVERCAST_DAY if is_day else OVERCAST_NIGHT
    return pick_palette(elev)

def sky_background(colors):
    return render.Column(
        children = [
            render.Box(width = WIDTH, height = 8, color = colors[0]),
            render.Box(width = WIDTH, height = 8, color = colors[1]),
            render.Box(width = WIDTH, height = 8, color = colors[2]),
            render.Box(width = WIDTH, height = 8, color = colors[3]),
        ],
    )

# ---------------------------------------------------------------------------
# Stars (night only): fixed scatter, gentle twinkle.
# ---------------------------------------------------------------------------

STARS = [
    (4, 3),
    (11, 9),
    (17, 4),
    (24, 12),
    (30, 2),
    (36, 7),
    (43, 11),
    (49, 5),
    (55, 9),
    (60, 3),
    (8, 15),
    (27, 17),
    (46, 16),
    (58, 14),
    (20, 20),
    (38, 21),
]

def star_layer(frame, brightness):
    # brightness 0.0-1.0 fades stars in through twilight
    if brightness <= 0:
        return render.Box(width = 1, height = 1)
    dots = []
    for i, pos in enumerate(STARS):
        x, y = pos

        # each star twinkles on its own cycle
        on = (frame + i * 3) % 12 < 9
        if not on:
            continue
        c = "#ffffff" if brightness > 0.7 else "#9aa3c0"
        dots.append(render.Padding(
            pad = (x, y, 0, 0),
            child = render.Box(width = 1, height = 1, color = c),
        ))
    if len(dots) == 0:
        return render.Box(width = 1, height = 1)
    return render.Stack(children = dots)

# Aurora: translucent green curtains (8-digit RGBA so stars/sky show through).
# A vertical fade -- bright green at the bottom, dissolving up through dim green
# to faint purple at the wispy top -- pulsing as the curtains wave sideways.
AURORA_GREEN = [
    "#3cf0991c",
    "#40f29a36",
    "#48f49b50",
    "#52f69d6a",
    "#5cf89e86",
    "#68fba6a2",
    "#80ffb8c0",
]
AURORA_PURP = ["#9a64ff20", "#aa70ff3c"]

def aurora_layer(frame):
    """Shimmering night aurora: overlapping vertical curtains that wave sideways
    and pulse, each fading from a bright green base up to faint purple wisps.
    Translucent (RGBA) so stars twinkle through. Night-only (caller gates it)."""
    step = 2.0 * math.pi / N_FRAMES
    bands = []
    x = 0
    k = 0
    for _i in range(20):
        if x > WIDTH - 5:
            break
        phase = frame * step + k * 0.6
        sway = _rnd(2.0 * math.sin(phase))
        cx = x + sway
        base_y = 17 + _rnd(2.0 * math.sin(phase * 1.3))  # ragged bottom edge
        height = 9 + _rnd(3.0 * (1.0 + math.sin(phase * 1.1 + 1.0)))  # 9..15
        pulse = 0.45 + 0.55 * (math.sin(phase * 0.8) + 1.0) * 0.5  # 0.45..1.0
        for r in range(height):
            y = base_y - r
            if y < 0:
                break
            if cx < 0 or cx > WIDTH - 5:
                continue
            frac = r / float(height)  # 0 bottom -> ~1 top
            if frac > 0.82:
                col = AURORA_PURP[1] if pulse > 0.7 else AURORA_PURP[0]
            else:
                bright = (1.0 - frac) * pulse
                idx = int(bright * (len(AURORA_GREEN) - 1) + 0.5)
                idx = 0 if idx < 0 else (len(AURORA_GREEN) - 1 if idx > len(AURORA_GREEN) - 1 else idx)
                col = AURORA_GREEN[idx]
            bands.append(render.Padding(pad = (cx, y, 0, 0), child = render.Box(width = 5, height = 1, color = col)))
        x += 4
        k += 1
    if len(bands) == 0:
        return render.Box(width = 1, height = 1)
    return render.Stack(children = bands)

# ---------------------------------------------------------------------------
# Sun and moon
# ---------------------------------------------------------------------------

def arc_position(fraction):
    """Map progress (0..1) across the sky to an (x, y) pixel position."""
    x = int(2 + fraction * (WIDTH - 11))
    y = int(24 - 18 * math.sin(math.pi * fraction))
    return x, max(2, y)

def sun_widget():
    return render.Stack(
        children = [
            # soft glow
            render.Padding(pad = (0, 0, 0, 0), child = render.Circle(diameter = 7, color = "#ffdf80")),
            render.Padding(pad = (1, 1, 0, 0), child = render.Circle(diameter = 5, color = "#ffd23f")),
            render.Padding(pad = (2, 2, 0, 0), child = render.Circle(diameter = 3, color = "#fff3b0")),
        ],
    )

def sun_ember_widget():
    """A dim, hard sun disc seen through wildfire smoke: a deep blood-orange
    circle with a muted red rim and no bright glow or rays -- the apocalyptic sun."""
    return render.Stack(
        children = [
            render.Padding(pad = (0, 0, 0, 0), child = render.Circle(diameter = 7, color = "#9c3a18")),
            render.Padding(pad = (1, 1, 0, 0), child = render.Circle(diameter = 5, color = "#c2552a")),
            render.Padding(pad = (2, 2, 0, 0), child = render.Circle(diameter = 3, color = "#e0743a")),
        ],
    )

def sun_glow_widget():
    """A diffuse sun behind fog: concentric translucent discs (~11px) that fade
    outward, so the sun reads as a soft glowing patch rather than a hard disc."""
    return render.Stack(
        children = [
            # warmer amber outward (holds its color over the bright fog instead of
            # washing to white), fading to a hot near-white core
            render.Padding(pad = (0, 0, 0, 0), child = render.Circle(diameter = 11, color = "#ffc06a30")),
            render.Padding(pad = (1, 1, 0, 0), child = render.Circle(diameter = 9, color = "#ffc87852")),
            render.Padding(pad = (2, 2, 0, 0), child = render.Circle(diameter = 7, color = "#ffd5917e")),
            render.Padding(pad = (3, 3, 0, 0), child = render.Circle(diameter = 5, color = "#ffe6b2aa")),
            render.Padding(pad = (4, 4, 0, 0), child = render.Circle(diameter = 3, color = "#fff3d0cc")),
        ],
    )

def _rnd(v):
    """Round to nearest int, away from zero on .5 (Starlark int() truncates)."""
    return int(v + 0.5) if v >= 0 else int(v - 0.5)

def sun_rays_layer(frame, cx, cy, n, base, amp):
    """A shimmering warm sunburst radiating from the sun center (cx, cy). Drawn
    behind the sun disc. `n` rays, `base` reach, `amp` shimmer breadth are set by
    the caller from sun elevation + the Off/Subtle/Bold mode: low sun -> short
    soft orb, high sun -> longer beaming. Each ray's length 'breathes' on its own
    phase so the burst feels alive (gentle shimmer) without spinning."""
    start = 4  # begin just outside the 7px disc
    step = 2.0 * math.pi / N_FRAMES  # one cycle per loop (slowest seamless rate)
    rays = []
    for k in range(n):
        ang = 2.0 * math.pi * k / n
        ca = math.cos(ang)
        sa = math.sin(ang)

        # smaller phase spread -> rays breathe more together (less busy flicker)
        length = base + _rnd(amp * math.sin(frame * step + k * 0.35))
        for r in range(start, start + length):
            px = cx + _rnd(r * ca)
            py = cy + _rnd(r * sa)
            if px < 0 or px >= WIDTH or py < 0 or py >= HEIGHT:
                continue
            t = (r - start) / float(length)  # 0 at sun, ~1 at tip
            if t < 0.4:
                col = "#ffe9a8d8"
            elif t < 0.72:
                col = "#ffd591a0"
            else:
                col = "#ffc06a66"
            rays.append(render.Padding(pad = (px, py, 0, 0), child = render.Box(width = 1, height = 1, color = col)))
    if len(rays) == 0:
        return render.Box(width = 1, height = 1)
    return render.Stack(children = rays)

def _hex2(n):
    """Clamp 0-255 and format as a 2-digit hex byte (Starlark % has no %02x)."""
    n = 0 if n < 0 else (255 if n > 255 else n)
    d = "0123456789abcdef"
    return d[n // 16] + d[n % 16]

def sunrise_orb_widget(strength, big):
    """A soft warm glow bloom around a low sun (sunrise/sunset). Concentric warm
    discs fading outward; overall opacity scales with `strength` (1 at the
    horizon -> 0 by mid-sky), so the sun reads as a big radiant orb low and hands
    off to the beaming rays as it climbs. `big` = the Bold mode (wider, warmer)."""
    if big:
        specs = [(15, "#ff9866", 0x30), (13, "#ffa86a", 0x48), (11, "#ffbc78", 0x68), (9, "#ffd28e", 0x92), (7, "#ffe6b4", 0xbe)]
    else:
        specs = [(13, "#ff9e6b", 0x33), (11, "#ffac6a", 0x4d), (9, "#ffc07a", 0x70), (7, "#ffd594", 0x99), (5, "#ffe7b8", 0xc2)]
    outer = specs[0][0]
    kids = []
    for d, rgb, a in specs:
        inset = (outer - d) // 2
        alpha = _rnd(a * strength)
        if alpha <= 0:
            continue
        kids.append(render.Padding(pad = (inset, inset, 0, 0), child = render.Circle(diameter = d, color = rgb + _hex2(alpha))))
    if len(kids) == 0:
        return None
    return render.Stack(children = kids)

def sky_body_kind(is_day, fog, clouds, precip, smoke):
    """What to render for the celestial body: a crisp 'sun', a diffuse 'glow'
    (sun behind fog), a dim red 'ember' (sun behind wildfire smoke), the 'moon',
    or 'none' (hidden by overcast/fog/smoke/heavy snow)."""
    if is_day:
        # wildfire smoke dims the sun to a hard red ember (overrides clouds/fog)
        if smoke:
            return "ember"

        # heavy daytime snow (blizzard / snowstorm) is a whiteout -- hide the sun
        if precip == "snow" and (fog or clouds >= 4):
            return "none"
        if fog:
            return "glow"
        if clouds >= 4:
            return "none"
        return "sun"
    if smoke or fog or clouds >= 4:
        return "none"
    return "moon"

def moon_phase_fraction(now):
    """0 = new moon, 0.5 = full, approaching 1 = back to new."""

    # Reference new moon: 2000-01-06 18:14 UTC
    ref = time.time(year = 2000, month = 1, day = 6, hour = 18, minute = 14, location = "UTC")
    days = (now.unix - ref.unix) / 86400.0
    synodic = 29.530588
    frac = (days % synodic) / synodic
    return frac

def moon_widget(phase, sky_color):
    """Pixel moon with a shadow disc offset to suggest the phase. The shadow is
    painted in `sky_color` (the sky band behind the moon) so the unlit part
    blends into the background instead of reading as a black disc."""
    base = render.Circle(diameter = 7, color = "#e8e8d8")
    crater = render.Padding(pad = (2, 3, 0, 0), child = render.Box(width = 1, height = 1, color = "#c9c9b8"))

    # true illuminated fraction: 0 at new, 1 at full
    lit = (1 - math.cos(2 * math.pi * phase)) / 2
    if lit > 0.92:
        return render.Stack(children = [base, crater])  # essentially full

    # the shadow disc slides aside just far enough to leave a lit sliver
    # `shadow_off` pixels wide, so the offset tracks illumination
    shadow_off = min(6, max(1, int(lit * 7 + 0.5)))
    if phase < 0.5:
        # waxing: lit on the right, shadow shifted left
        shadow = _shadow_disc(-shadow_off, sky_color)
    else:
        # waning: lit on the left, shadow shifted right
        shadow = _shadow_disc(shadow_off, sky_color)
    return render.Stack(children = [base, crater, shadow])

def _shadow_disc(offset, color):
    """Sky-colored circle shifted horizontally by offset pixels to carve the
    crescent (can't pad negative, so negative offsets are simulated with column
    slicing). `color` matches the sky band so the unlit moon blends in."""
    if offset >= 0:
        return render.Padding(pad = (offset, 0, 0, 0), child = render.Circle(diameter = 7, color = color))

    # negative offset: draw boxes column by column approximating a shifted circle
    cols = []
    for x in range(7):
        sx = x - offset  # source column in the un-shifted circle
        h = _circle_col_height(sx)
        if h <= 0:
            cols.append(render.Box(width = 1, height = 1))
        else:
            cols.append(render.Padding(
                pad = (0, (7 - h) // 2, 0, 0),
                child = render.Box(width = 1, height = h, color = color),
            ))
    return render.Row(children = cols)

def _circle_col_height(x):
    """Height of column x in a 7px circle."""
    if x < 0 or x > 6:
        return 0
    heights = [3, 5, 7, 7, 7, 5, 3]
    return heights[x]

# ---------------------------------------------------------------------------
# Weather sprites
# ---------------------------------------------------------------------------

# Cloud sprite variants as box templates: (x, y, w, h, kind, leans).
#   kind  "h" = highlight, "c" = main color
#   leans  True = top puff shifts with the wind `lean`
CLOUD_SHAPES = [
    # 0: small (~9x5)
    [(2, 0, 5, 2, "h", True), (0, 2, 9, 3, "c", False), (1, 1, 3, 1, "h", True)],
    # 1: medium (~13x6)
    [(3, 0, 7, 3, "h", True), (0, 2, 13, 4, "c", False), (2, 1, 4, 2, "h", True)],
    # 2: large (~18x7)
    [(4, 0, 9, 3, "h", True), (0, 3, 18, 4, "c", False), (2, 1, 6, 2, "h", True), (11, 1, 5, 2, "h", True)],
]

def _cloud_boxes(shape, color, highlight, lean):
    """Boxes (x, y, w, h, color) for a shape, with `lean` applied to the top
    puffs (clamped >= 0 so left padding never goes negative)."""
    boxes = []
    for bx, by, bw, bh, kind, leans in CLOUD_SHAPES[shape]:
        x = max(0, bx + lean) if leans else bx
        boxes.append((x, by, bw, bh, highlight if kind == "h" else color))
    return boxes

def _draw_cloud(x, y, shape, color, highlight, lean):
    """Render a cloud whose left edge is at x (may be negative when entering
    from the left). Boxes are clipped against the left edge — Padding can't be
    negative — so clouds slide in smoothly instead of freezing at x=0. The right
    edge is clipped by the display."""
    children = []
    for bx, by, bw, bh, c in _cloud_boxes(shape, color, highlight, lean):
        ax = x + bx
        w = bw
        if ax < 0:
            w = bw + ax  # drop the columns left of the screen
            ax = 0
        if w <= 0 or ax >= WIDTH:
            continue
        children.append(render.Padding(pad = (ax, y + by, 0, 0), child = render.Box(width = w, height = bh, color = c)))
    if len(children) == 0:
        return None
    return render.Stack(children = children)

# A pool of candidate cloud placements: (home_x on-screen, y, shape index).
# More slots than max clouds so the set + arrangement can vary day to day.
CLOUD_SLOTS = [
    (4, 4, 1),
    (40, 6, 2),
    (22, 13, 0),
    (52, 3, 0),
    (14, 9, 2),
    (34, 2, 1),
]
CLOUD_MARGIN = 18  # widest shape; off-screen margin so clouds enter/exit cleanly
CLOUD_WRAP = WIDTH + CLOUD_MARGIN

def build_cloud_plan(count, seed):
    """Pick `count` slots from the pool, rotated by `seed`, so the chosen
    clouds (positions + shapes) shift over time instead of always the same one.
    Returns a list of (home_x, y, shape)."""
    n = len(CLOUD_SLOTS)
    if count > n:
        count = n
    plan = []
    for i in range(count):
        plan.append(CLOUD_SLOTS[(seed + i) % n])
    return plan

def _cloud_x(frame, home_x, speed, wraps, dx):
    """Cloud left-edge x for a frame. With wraps == 0 (calm) the cloud sits
    still at home_x. Otherwise it advances exactly speed*wraps full wraps over
    the loop, so frame 0 == frame N_FRAMES (seamless) and it crosses the screen;
    a moving cloud's frame 0 also lands on home_x."""
    if wraps <= 0:
        return home_x
    travel = frame * speed * wraps * CLOUD_WRAP // N_FRAMES
    if dx >= 0:
        return (home_x + CLOUD_MARGIN + travel) % CLOUD_WRAP - CLOUD_MARGIN
    return (home_x + CLOUD_MARGIN - travel) % CLOUD_WRAP - CLOUD_MARGIN

def cloud_layer(frame, plan, color, highlight, wraps, lean, dx):
    """Draw the planned clouds: static when wraps == 0 (calm), else drifting in
    the wind direction (dx), faster at higher tiers, with a sideways lean."""
    children = []
    for home_x, y, shape in plan:
        x = _cloud_x(frame, home_x, 1, wraps, dx)
        c = _draw_cloud(x, y, shape, color, highlight, lean * dx)
        if c != None:
            children.append(c)
    if len(children) == 0:
        return render.Box(width = 1, height = 1)
    return render.Stack(children = children)

# Drop columns by intensity level (1 light/drizzle, 2 moderate, 3 heavy/downpour).
# Denser at higher levels.
PRECIP_COLS = {
    1: [8, 26, 44, 60],
    2: [5, 13, 22, 30, 39, 47, 56, 61],
    3: [2, 8, 14, 20, 26, 32, 38, 44, 50, 56, 61],
}

ICE_CORE = "#ffffff"
ICE_ARM = "#cdeeff"
ICE_TIP = "#8fd2ec"

def _ice_crystal(x, y, big, lit):
    """A tiny faceted ice crystal: a white core with light-blue arms forming a
    4-point star (3x3), with diagonal facet tips when `big` (5x5). `lit`
    brightens the arms for a twinkle. All offsets >= 0 so Padding stays valid."""
    arm = ICE_ARM if lit else ICE_TIP
    if not big:
        pts = [(1, 1, ICE_CORE), (1, 0, arm), (1, 2, arm), (0, 1, arm), (2, 1, arm)]
    else:
        pts = [
            (2, 2, ICE_CORE),
            (2, 0, arm),
            (2, 1, ICE_CORE),
            (2, 3, ICE_CORE),
            (2, 4, arm),
            (0, 2, arm),
            (1, 2, ICE_CORE),
            (3, 2, ICE_CORE),
            (4, 2, arm),
            (1, 1, ICE_TIP),
            (3, 1, ICE_TIP),
            (1, 3, ICE_TIP),
            (3, 3, ICE_TIP),
        ]
    out = []
    for dx, dy, c in pts:
        out.append(render.Padding(pad = (x + dx, y + dy, 0, 0), child = render.Box(width = 1, height = 1, color = c)))
    return out

def precip_layer(frame, kind, level):
    """Falling precipitation, scaled by intensity `level` (1-3): higher = more
    drops, faster, longer streaks. Five kinds with distinct looks:
    rain (blue streaks), snow (slow fat flakes), ice/freezing-rain (glassy cyan
    streaks + glints), sleet (faceted ice crystals), hail (fat pellets that ricochet)."""
    if level < 1:
        return render.Box(width = 1, height = 1)
    if level > 3:
        level = 3
    cols = PRECIP_COLS[level]
    drops = []
    if kind == "snow":
        speed = 1 if level < 3 else 2
        color = "#dfe9ff" if level == 1 else "#eef4ff"
        flake = 1 if level == 1 else 2  # fine specks for a flurry, fat flakes for heavier snow
        for i, x in enumerate(cols):
            # scatter each column's start height (not a linear i*offset) so the
            # flakes fall evenly across the sky instead of forming a diagonal line
            off = (x * 7 + i * 13) % HEIGHT
            y = (frame * speed + off) % HEIGHT
            drops.append(render.Padding(pad = (x, y, 0, 0), child = render.Box(width = flake, height = flake, color = color)))
    elif kind == "ice":
        # freezing rain / glaze: glassy cyan streaks with a bright glint head and
        # a few sparkling crystals, so it reads as icy glaze rather than blue rain
        speed = 2
        length = level
        color = "#d2f1ff" if level == 1 else "#a8e4f7"
        for i, x in enumerate(cols):
            y = (frame * speed + i * 7) % HEIGHT
            drops.append(render.Padding(pad = (x, y, 0, 0), child = render.Box(width = 1, height = length, color = color)))

            # a bright white glint sparkles at the head of every other streak
            if i % 2 == 0:
                drops.append(render.Padding(pad = (x, y, 0, 0), child = render.Box(width = 1, height = 1, color = ICE_CORE)))

            # an occasional small crystal drifting among the streaks
            if i % 4 == 1 and x < WIDTH - 3:
                cy = (frame * speed + i * 19) % HEIGHT
                drops.extend(_ice_crystal(x, cy, False, ((frame // 4 + i) % 2) == 0))
    elif kind == "sleet":
        # ice crystals: small faceted 4-point stars that twinkle as they fall
        speed = 2
        for i, x in enumerate(cols):
            off = (x * 5 + i * 11) % HEIGHT
            y = (frame * speed + off) % HEIGHT
            big = level >= 2 and i % 3 == 0 and x < WIDTH - 5
            lit = (frame // 3 + i) % 3 != 0
            drops.extend(_ice_crystal(x, y, big, lit))
    elif kind == "hail":
        # hail: fat fast pellets that ricochet just above the ground bar
        speed = 4
        color = "#eef4ff"
        gy = 24
        for i, x in enumerate(cols):
            off = (x * 7 + i * 13) % HEIGHT
            y = (frame * speed + off) % HEIGHT
            drops.append(render.Padding(pad = (x, y, 0, 0), child = render.Box(width = 2, height = 2, color = color)))

            # ricochet: a pellet hops up off the ground on its own short arc
            bphase = (frame * 2 + i * 5) % 16
            if bphase < 4:
                bx = x + (bphase if i % 2 == 0 else -bphase)
                by = gy - bphase
                if bx >= 0 and bx < WIDTH:
                    drops.append(render.Padding(pad = (max(0, bx), by, 0, 0), child = render.Box(width = 1, height = 1, color = color)))
    else:
        speed = 2 if level < 3 else 3
        length = level  # 1px drizzle, 2px rain, 3px downpour streaks
        color = "#9fd1ff" if level == 1 else "#6fb7ff"
        for i, x in enumerate(cols):
            y = (frame * speed + i * 7) % HEIGHT
            drops.append(render.Padding(pad = (x, y, 0, 0), child = render.Box(width = 1, height = length, color = color)))
    return render.Stack(children = drops)

# Condition badge: a tiny 7x6 glyph for the ground bar that names the weather --
# intensity-aware, so drizzle != rain, snow != blizzard, ice != hail. "#" = pixel.
_ICON_RAIN = [
    "#  #  #",
    "#  #  #",
    "#  #  #",
    "       ",
    "#  #  #",
    "#  #  #",
]
_ICON_DRIZZLE = [
    "       ",
    "#     #",
    "       ",
    "   #   ",
    "       ",
    "#     #",
]
_ICON_SNOW = [
    " #   # ",
    "   #   ",
    "#   # #",
    "   #   ",
    " #   # ",
    "#  #   ",
]
_ICON_BLIZZARD = [
    "  #  ##",
    " #  ## ",
    "#  ##  ",
    "  ##  #",
    " ##  # ",
    "##  #  ",
]
_ICON_ICE = [
    " #   # ",
    "#######",
    " #   # ",
    "#######",
    " #   # ",
    "#######",
]
_ICON_HAIL = [
    "##  ## ",
    "##  ## ",
    "       ",
    " ##  ##",
    " ##  ##",
    "       ",
]
_ICON_SLEET = [
    "# # # #",
    "       ",
    " # # # ",
    "       ",
    "# # # #",
    "       ",
]
_ICON_BOLT = [
    "   ##  ",
    "  ##   ",
    " ####  ",
    "  ###  ",
    "   ##  ",
    "  #    ",
]
_ICON_FOG = [
    "       ",
    " ##### ",
    "       ",
    "###### ",
    "       ",
    " ##### ",
]
_ICON_SMOKE = [
    " ##### ",
    "       ",
    "###### ",
    "       ",
    " ##### ",
    "       ",
]

def _draw_icon(rows, color, x0, y0):
    """Render a "#"-bitmap as 1px boxes at (x0, y0)."""
    out = []
    for dy in range(len(rows)):
        row = rows[dy]
        for dx in range(len(row)):
            if row[dx] != " ":
                out.append(render.Padding(pad = (x0 + dx, y0 + dy, 0, 0), child = render.Box(width = 1, height = 1, color = color)))
    return render.Stack(children = out)

def condition_icon(wx, tier):
    """Pick the ground-bar weather glyph as (rows, color), or None when there's
    nothing notable. Intensity-aware: light rain -> drizzle, windy/foggy/heavy
    snow -> blizzard. Hail and thunderstorm outrank plain precip."""
    if wx.precip == "hail":
        return _ICON_HAIL, "#ffffff"
    if wx.storm and (wx.precip == "rain" or wx.precip == None):
        return _ICON_BOLT, "#fdf6c8"
    if wx.precip == "ice":
        return _ICON_ICE, "#a8e4f7"
    if wx.precip == "sleet":
        return _ICON_SLEET, "#cdeeff"
    if wx.precip == "snow":
        if wx.fog or tier >= 2 or wx.precip_level >= 3:
            return _ICON_BLIZZARD, "#eef4ff"
        return _ICON_SNOW, "#eef4ff"
    if wx.precip == "rain":
        if wx.precip_level <= 1:
            return _ICON_DRIZZLE, "#9fd1ff"
        return _ICON_RAIN, "#6fb7ff"
    if wx.smoke:
        return _ICON_SMOKE, "#d99a5a"
    if wx.fog:
        return _ICON_FOG, "#c8cdd6"
    return None

def weather_kind(code):
    """Map WMO weather code -> sprite plan. `storm` adds the lightning layer."""
    if code == None:
        return struct(clouds = 0, precip = None, fog = False, storm = False)
    if code == 0:
        return struct(clouds = 0, precip = None, fog = False, storm = False)
    if code in [1, 2]:
        return struct(clouds = 1 if code == 1 else 2, precip = None, fog = False, storm = False)
    if code == 3:
        return struct(clouds = 3, precip = None, fog = False, storm = False)
    if code in [45, 48]:
        return struct(clouds = 1, precip = None, fog = True, storm = False)
    if code in [56, 57, 66, 67]:  # freezing drizzle / freezing rain -> ice/glaze
        return struct(clouds = 3, precip = "ice", fog = False, storm = False)
    if code >= 51 and code <= 67:
        return struct(clouds = 2, precip = "rain", fog = False, storm = False)
    if code >= 71 and code <= 77:
        return struct(clouds = 2, precip = "snow", fog = False, storm = False)
    if code >= 80 and code <= 82:
        return struct(clouds = 3, precip = "rain", fog = False, storm = False)
    if code in [85, 86]:
        return struct(clouds = 3, precip = "snow", fog = False, storm = False)
    if code in [96, 99]:  # thunderstorm with hail
        return struct(clouds = 3, precip = "hail", fog = False, storm = True)
    if code >= 95:
        return struct(clouds = 3, precip = "rain", fog = False, storm = True)
    return struct(clouds = 1, precip = None, fog = False, storm = False)

def clouds_from_cover(pct):
    """Map real cloud-cover percent to the 0-4 sprite count."""
    if pct < 10:
        return 0
    if pct < 30:
        return 1
    if pct < 55:
        return 2
    if pct < 80:
        return 3
    return 4

def precip_from_obs(base_precip, precip_mm, snow_mm):
    """Turn precip ON from actual observed amounts (mm rain / cm snow), since
    the weathercode nowcast lags real precipitation. Snow wins when present;
    otherwise any measurable precip is rain. Never removes code-based precip."""
    if snow_mm > 0:
        return "snow"
    if precip_mm > 0:
        return "rain"
    return base_precip

def _level_from_code(code):
    """Fallback precip intensity from WMO code when no amount is available."""
    if code == None:
        return 2
    if code in [51, 53, 56, 71, 80, 85]:  # drizzle / light / light showers
        return 1
    if code in [55, 65, 67, 75, 82, 86, 95, 96, 99]:  # heavy / violent
        return 3
    return 2

def precip_level(precip, precip_mm, snow_mm, code):
    """Intensity 1-3 (light/drizzle, moderate, heavy/downpour), 0 if no precip.
    Prefers measured amounts (preceding-hour mm rain / cm snow); falls back to
    the WMO code when the amount is unknown."""
    if precip == None:
        return 0
    if precip == "snow":
        if snow_mm > 0:
            return 1 if snow_mm < 0.5 else (2 if snow_mm < 2.0 else 3)
    elif precip_mm > 0:
        return 1 if precip_mm < 0.5 else (2 if precip_mm < 4.0 else 3)
    return _level_from_code(code)

# NWS METAR cloud-cover codes -> 0-4 sprite count.
_NWS_CLOUD_RANK = {"CLR": 0, "SKC": 0, "FEW": 2, "SCT": 2, "BKN": 3, "OVC": 4, "VV": 4}
_NWS_SNOW = ["snow", "snow_showers", "snow_grains", "ice_crystals", "blowing_snow"]
_NWS_RAIN = ["rain", "rain_showers", "drizzle"]
_NWS_ICE = ["freezing_rain", "freezing_drizzle"]
_NWS_SLEET = ["ice_pellets"]
_NWS_HAIL = ["hail", "small_hail"]
_NWS_SMOKE = ["smoke", "haze"]
_NWS_FOG = ["fog", "freezing_fog", "mist", "dust", "sand"]

def _intensity_level(inten):
    """NWS presentWeather intensity string -> 1-3."""
    if inten == "light":
        return 1
    if inten == "heavy":
        return 3
    return 2

def nws_scene(amounts, weathers):
    """Map NWS observation fields to our scene struct. `weathers` is a list of
    (weather, intensity) tuples. Thunderstorms set storm + rain; snow beats
    rain; `level` is the strongest precip intensity seen."""
    clouds = 0
    for a in amounts:
        v = _NWS_CLOUD_RANK.get(a, 0)
        if v > clouds:
            clouds = v
    precip = None
    fog = False
    storm = False
    smoke = False
    level = 0
    for w, inten in weathers:
        lv = 0
        if w == "thunderstorms":
            storm = True
            if precip == None:
                precip = "rain"
            lv = 3
        elif w in _NWS_HAIL:
            if precip == None:
                precip = "hail"
            lv = _intensity_level(inten)
        elif w in _NWS_ICE:
            if precip == None:
                precip = "ice"
            lv = 1 if w == "freezing_drizzle" else _intensity_level(inten)
        elif w in _NWS_SLEET:
            if precip == None:
                precip = "sleet"
            lv = _intensity_level(inten)
        elif w in _NWS_SNOW:
            if precip == None:
                precip = "snow"
            lv = _intensity_level(inten)
        elif w in _NWS_RAIN:
            if precip == None:
                precip = "rain"
            lv = 1 if w == "drizzle" else _intensity_level(inten)
        elif w in _NWS_SMOKE:
            smoke = True
        elif w in _NWS_FOG:
            fog = True
        if lv > level:
            level = lv
    return struct(clouds = clouds, precip = precip, fog = fog, storm = storm, smoke = smoke, level = level)

def _bolt():
    """A small jagged lightning bolt, drawn as stacked offset boxes."""
    segs = [
        (41, 1, 2, 4),
        (40, 5, 2, 3),
        (42, 7, 2, 4),
        (41, 11, 2, 3),
        (40, 14, 2, 4),
    ]
    cols = []
    for x, y, w, h in segs:
        cols.append(render.Padding(
            pad = (x, y, 0, 0),
            child = render.Box(width = w, height = h, color = "#fdf6c8"),
        ))
    return render.Stack(children = cols)

# frame -> translucent white overlay; the brightest frames also draw a bolt.
# Several strikes spread across the (longer) loop so storms stay lively.
LIGHTNING_FLASHES = {
    2: "#ffffffcc",
    3: "#ffffff99",
    4: "#ffffff44",
    18: "#ffffff88",
    19: "#ffffff33",
    34: "#ffffffcc",
    35: "#ffffff88",
    36: "#ffffff33",
    52: "#ffffff77",
    53: "#ffffff33",
}
LIGHTNING_BOLTS = [2, 3, 34, 35]

def lightning_layer(frame):
    """Quick double-flash with a bolt, overlaid on the whole scene."""
    if frame not in LIGHTNING_FLASHES:
        return render.Box(width = 1, height = 1)
    children = [render.Box(width = WIDTH, height = HEIGHT, color = LIGHTNING_FLASHES[frame])]
    if frame in LIGHTNING_BOLTS:
        children.append(_bolt())
    return render.Stack(children = children)

# ---------------------------------------------------------------------------
# Heat haze: wavy shimmer rising off hot ground on a bright, clear-enough day.
# Real per-pixel distortion isn't possible with flat boxes, so it's faked with
# faint warm horizontal streaks that wobble side to side at different heights
# and speeds -- brightest low (near the "pavement"), fading out as they rise
# through the lower-middle of the scene.
# ---------------------------------------------------------------------------

HEAT_HAZE_TEMP_F = 90.0  # Fahrenheit-equivalent trigger threshold

def _heat_haze_auto(is_day, temp_f, clouds, fog, storm, smoke, precip):
    """True when it's hot, bright daytime air -- heavy cloud/fog/smoke/storm/
    precip all block the sun-baked-ground look a mirage needs."""
    if not is_day or temp_f == None:
        return False
    return temp_f >= HEAT_HAZE_TEMP_F and clouds < 4 and not fog and not storm and not smoke and precip == None

# (y, alpha hex) rows from low/near (brightest) to high/far (faintest).
HEAT_HAZE_ROWS = [(23, "70"), (21, "58"), (19, "46"), (17, "36"), (15, "26")]

def heat_haze_layer(frame):
    """Shimmering heat-mirage lines. Each row's wobble uses an integer
    harmonic of the loop length so it wraps seamlessly at frame N_FRAMES."""
    step = 2.0 * math.pi / N_FRAMES
    children = []
    for i, (y, alpha) in enumerate(HEAT_HAZE_ROWS):
        freq = 1 + i % 3
        phase = frame * step * freq + i * 1.3
        off = _rnd(2.0 * math.sin(phase))
        col = "#fff2c0" + alpha
        for seg in range(6):
            x = 6 + off + seg * 13
            if x < 0 or x >= WIDTH:
                continue
            w = min(5, WIDTH - x)
            if w > 0:
                children.append(render.Padding(pad = (x, y, 0, 0), child = render.Box(width = w, height = 1, color = col)))
    return render.Stack(children = children)

# ---------------------------------------------------------------------------
# Seasonal tree: an always-on scenery accent standing at the left edge of the
# ground bar, showing the real meteorological season (or a demo override).
# Spring/summer/fall share one leafy canopy shape recolored per season; winter
# swaps in a bare, veiny branch silhouette with a static snow dusting that
# never falls off. Fall and spring also keep a static scatter of fallen
# leaves/petals at the trunk's base. Particles: in calm weather 1-2 leaves
# (fall) / petals (spring) flutter from the canopy underside to the ground;
# strong wind instead strips them off and streams them across the screen.
# ---------------------------------------------------------------------------

def season_from_month(month, southern):
    """Meteorological season from a 1-12 month. Southern Hemisphere is offset
    6 months from Northern (e.g. December is summer, not winter)."""
    m = ((month - 1 + 6) % 12) + 1 if southern else month
    if m == 12 or m <= 2:
        return "winter"
    if m <= 5:
        return "spring"
    if m <= 8:
        return "summer"
    return "fall"

# sprite anchor: 10 wide x 16 tall, canopy rows 9..17, trunk 18..24, base
# meeting the ground bar at y=25. All box/pixel tables below are tree-local
# (col, row) with row 0 = screen y TREE_Y0.
TREE_X0 = 0
TREE_Y0 = 9
TREE_TRUNK_COLOR = "#5b3a22"

# trunk is two-toned to match the crown's light source (upper right): shadow
# column on the left, lit column on the right, an asymmetric root flare
# (wider on the left), and a couple of bare limb stubs poking out of the
# crown's underside so the trunk visibly continues into the foliage.
TREE_TRUNK_BOXES = [
    (4, 9, 1, 6, "#4a2f1c"),  # shadow side
    (5, 9, 1, 6, "#6f4a2a"),  # lit side
    (2, 15, 5, 1, "#5b3a22"),  # root flare, wider left
    (3, 9, 1, 1, "#5b3a22"),  # stub reaching into the crown's left underside
    (6, 11, 1, 1, "#5b3a22"),  # low bare limb poking out to the right
    (7, 10, 1, 1, "#5b3a22"),
]

# ground detail on the last row above the bar: a faint shadow strip under the
# crown's spread (narrower for winter's bare tree) and a few grass-tuft
# pixels flanking the trunk, tinted per season
TREE_SHADOW_LEAFY = (0, 15, 10, 1)
TREE_SHADOW_WINTER = (2, 15, 6, 1)
TREE_SHADOW_COLOR = "#0d133040"
TREE_GRASS_PX = [(1, 14), (1, 15), (8, 15)]
TREE_GRASS_COLS = {
    "spring": "#4a9a4a",
    "summer": "#3f8f3f",
    "fall": "#9a8a3a",
    "winter": "#7a7568",
}

# leafy canopy (spring/summer/fall): one span (or two, where a notch or lump
# breaks the outline) per row, deliberately asymmetric -- two top tufts, a
# fuller left shoulder, a small low lump on the right -- so the crown reads
# organic instead of a symmetric stacked dome.
TREE_CANOPY_BOXES = [
    (3, 0, 2, 1),
    (6, 0, 1, 1),
    (2, 1, 6, 1),
    (1, 2, 8, 1),
    (0, 3, 9, 1),
    (0, 4, 10, 1),
    (1, 5, 9, 1),
    (1, 6, 8, 1),
    (2, 7, 5, 1),
    (8, 7, 1, 1),
    (3, 8, 3, 1),
]

# directional shading, light from the upper right: shade boxes darken the
# crown's lower-left underside, rim boxes brighten the top-right edge
TREE_CANOPY_SHADE = [(0, 4, 1, 1), (1, 5, 1, 1), (1, 6, 2, 1), (2, 7, 2, 1), (3, 8, 3, 1)]
TREE_CANOPY_RIM = [(6, 0, 1, 1), (6, 1, 2, 1), (7, 2, 2, 1), (8, 3, 1, 1), (8, 4, 2, 1), (9, 5, 1, 1)]

# (shade, base, highlight) per season -- shade for the lower-left underside,
# highlight for the sunlit top-right rim. Winter's trio colors the bare
# branches instead: base wood plus lighter twig tips (shade unused).
TREE_SEASON_COLORS = {
    "spring": ("#d9a0bc", "#ffc9de", "#ffe0ee"),
    "summer": ("#2e6b2e", "#3f8f3f", "#5aa85a"),
    "fall": ("#a8551a", "#d97a26", "#e8a33d"),
    "winter": ("#4a3c2e", "#5b4a3a", "#7a6a58"),
}

# fall only: mottled color patches (x, y, w, h, color) drawn over the base
# canopy instead of the generic highlights -- golds, ambers, and deep reds so
# the crown reads as mixed turning leaves, not one flat orange.
TREE_FALL_PATCHES = [
    (3, 0, 2, 1, "#f0c040"),
    (2, 1, 2, 1, "#c8531f"),
    (6, 1, 2, 1, "#f0c040"),
    (1, 3, 2, 1, "#a83a28"),
    (5, 2, 2, 1, "#e8a33d"),
    (0, 4, 2, 1, "#f0c040"),
    (4, 4, 2, 1, "#b5451f"),
    (7, 5, 2, 1, "#e8a33d"),
    (2, 6, 2, 1, "#c8531f"),
    (5, 7, 2, 1, "#f0c040"),
]

# ground-scatter and airborne-leaf palettes (fall mixes the turning colors;
# spring stays in the blossom pinks)
TREE_LEAF_COLS = {
    "fall": ["#e0742a", "#f0c040", "#b5451f", "#e8a33d"],
    "spring": ["#ffc9de", "#ffe0ee"],
}

# winter: bare 1px branches -- a center leader and two arcing limbs forking
# off the trunk top, with twigs, drawn pixel-by-pixel so the silhouette reads
# veiny rather than blobby.
TREE_BRANCH_PX = [
    # left limb + twigs
    (3, 8), (3, 7), (2, 6), (2, 5), (1, 4), (1, 3), (0, 2),
    (3, 4), (3, 3), (2, 2),
    # center leader (wiggles as it climbs)
    (4, 8), (5, 8), (4, 7), (4, 6), (4, 5), (4, 4), (5, 3), (5, 2), (4, 1), (4, 0),
    # right limb + twigs
    (6, 8), (6, 7), (7, 6), (7, 5), (8, 4), (8, 3), (9, 2), (9, 1),
    (6, 4), (6, 3), (7, 2),
]
TREE_BRANCH_TIPS = [(0, 2), (2, 2), (4, 0), (9, 1), (7, 2)]

# static snow dusting resting on top of winter branches (it never falls off)
TREE_SNOW_PX = [(1, 2), (3, 2), (5, 1), (8, 2), (2, 4), (7, 4)]

# fallen leaves/petals scattered at the trunk base (fall + spring only), on
# the last row above the ground bar, flanking the root flare
TREE_SCATTER_PX = [(0, 15), (2, 15), (7, 15), (9, 15)]

def _tree_box(x, y, w, h, col):
    return render.Padding(pad = (TREE_X0 + x, TREE_Y0 + y, 0, 0), child = render.Box(width = w, height = h, color = col))

def _tree_lean_box(x, y, w, h, col, lean):
    """A crown box shifted `lean` px downwind, clipped at the left edge."""
    nx = x + lean
    if nx < 0:
        w += nx
        nx = 0
    if w <= 0:
        return None
    return _tree_box(nx, y, w, h, col)

def tree_widget(season, lean = 0, hide_tips = False):
    """Static trunk + seasonal crown (built once; identical every frame).
    `lean` shifts the crown (not the trunk) 1px downwind at windy tier+;
    `hide_tips` omits winter's twig-tip pixels so tree_tip_sway_layer can
    draw them animated instead."""
    shade_col, main_col, hi_col = TREE_SEASON_COLORS[season]
    shx, shy, shw, shh = TREE_SHADOW_WINTER if season == "winter" else TREE_SHADOW_LEAFY
    children = [_tree_box(shx, shy, shw, shh, TREE_SHADOW_COLOR)]
    for (x, y, w, h, col) in TREE_TRUNK_BOXES:
        children.append(_tree_box(x, y, w, h, col))
    for (x, y) in TREE_GRASS_PX:
        children.append(_tree_box(x, y, 1, 1, TREE_GRASS_COLS[season]))
    if season == "winter":
        for (x, y) in TREE_BRANCH_PX:
            is_tip = (x, y) in TREE_BRANCH_TIPS
            if is_tip and hide_tips:
                continue
            b = _tree_lean_box(x, y, 1, 1, hi_col if is_tip else main_col, lean)
            if b != None:
                children.append(b)
        for (x, y) in TREE_SNOW_PX:
            b = _tree_lean_box(x, y, 1, 1, "#eef3fa", lean)
            if b != None:
                children.append(b)
    else:
        for (x, y, w, h) in TREE_CANOPY_BOXES:
            b = _tree_lean_box(x, y, w, h, main_col, lean)
            if b != None:
                children.append(b)
        for (x, y, w, h) in TREE_CANOPY_SHADE:
            b = _tree_lean_box(x, y, w, h, shade_col, lean)
            if b != None:
                children.append(b)
        if season == "fall":
            for (x, y, w, h, col) in TREE_FALL_PATCHES:
                b = _tree_lean_box(x, y, w, h, col, lean)
                if b != None:
                    children.append(b)
        for (x, y, w, h) in TREE_CANOPY_RIM:
            b = _tree_lean_box(x, y, w, h, hi_col, lean)
            if b != None:
                children.append(b)
        if season != "summer":
            cols = TREE_LEAF_COLS[season]
            for i, (x, y) in enumerate(TREE_SCATTER_PX):
                children.append(_tree_box(x, y, 1, 1, cols[i % len(cols)]))
    return render.Stack(children = children)

def tree_tip_sway_layer(frame, lean):
    """Winter wind: the bare twig tips flick 1px side to side occasionally
    (drawn here instead of in the static widget -- see hide_tips). Each tip
    gates on its own integer-harmonic sin, so the rattle loops seamlessly."""
    hi = TREE_SEASON_COLORS["winter"][2]
    step = 2.0 * math.pi / N_FRAMES
    children = []
    for i, (x, y) in enumerate(TREE_BRANCH_TIPS):
        s = math.sin(frame * step * (2 + i % 2) + i * 1.9)
        flick = 1 if s > 0.55 else (-1 if s < -0.55 else 0)
        nx = x + lean + flick
        if nx < 0 or nx >= WIDTH:
            continue
        children.append(_tree_box(nx, y, 1, 1, hi))
    if len(children) == 0:
        return render.Box(width = 1, height = 1)
    return render.Stack(children = children)

# breeze rustle: a few crown pixels flicker to the highlight color once the
# wind reaches breeze tier (1+), so the foliage reads alive without moving
# the silhouette. Winter's bare branches never rustle.
TREE_RUSTLE_PX = [(3, 1), (6, 2), (2, 4), (7, 4), (5, 6), (8, 5)]

def tree_rustle_layer(frame, season, lean):
    hi = TREE_SEASON_COLORS[season][2]
    step = 2.0 * math.pi / N_FRAMES
    children = []
    for i, (x, y) in enumerate(TREE_RUSTLE_PX):
        # integer-harmonic sin per pixel, so each flicker wraps seamlessly
        if math.sin(frame * step * (2 + i % 3) + i * 2.1) < 0.35:
            continue
        col = "#f0c040" if season == "fall" and i % 2 == 0 else hi
        nx = x + lean
        if nx < 0 or nx >= WIDTH:
            continue
        children.append(_tree_box(nx, y, 1, 1, col))
    if len(children) == 0:
        return render.Box(width = 1, height = 1)
    return render.Stack(children = children)

# calm drop zone: canopy underside down to the ground bar edge. Each slot is
# airborne only while its exact-wrap travel is inside the span (half its
# cycle), so usually a single leaf/petal is falling at a time.
TREE_DROP_Y0 = 18
TREE_DROP_SPAN = 7  # rows 18..24
TREE_DROP_SLOTS = [(3, 0), (6, 27)]  # (x0, frame phase)

# blow-off launch rows: the canopy band the leaves tear away from; below
# hurricane strength they sink as they cross, so they land lower than this
TREE_BLOW_ROWS = [9, 12, 14, 10, 13, 15, 11]

def tree_particle_layer(frame, season, tier, dx, drop_ok):
    """Season + wind decide what leaves the tree: winter sheds nothing (snow
    stays put); fall/spring drop 1-2 leaves/petals in calm air but stream them
    across the screen at windy tier (2+); summer's green only lets go in a
    gale (tier 3+). `drop_ok` is False when a low sun sits behind the tree --
    a leaf fluttering through the sun disc and rays reads awkwardly, so the
    calm drop is skipped (the fast screen-wide blow-off is unaffected)."""
    if season == "winter":
        return render.Box(width = 1, height = 1)
    blow_tier = 3 if season == "summer" else 2
    if tier >= blow_tier:
        return _tree_blowoff_layer(frame, season, tier, dx)
    if season == "summer" or not drop_ok:
        return render.Box(width = 1, height = 1)
    return _tree_calm_drop_layer(frame, season, dx)

def _tree_calm_drop_layer(frame, season, dx):
    """A leaf/petal detaches from the canopy underside and flutters the few
    pixels down to the ground. Travel is `f*period // N_FRAMES` (exact-wrap,
    like `_cloud_x`) over 2x the span; the second half is parked off-screen,
    which is what keeps the drop sparse."""
    cols = TREE_LEAF_COLS[season]
    step = 2.0 * math.pi / N_FRAMES
    period = TREE_DROP_SPAN * 2
    children = []
    for i, (x0, phase) in enumerate(TREE_DROP_SLOTS):
        f = (frame + phase) % N_FRAMES
        travel = f * period // N_FRAMES
        if travel >= TREE_DROP_SPAN:
            continue  # parked half of the cycle
        y = TREE_DROP_Y0 + travel
        wob = _rnd(1.0 * math.sin(f * step * 4 + i * 2))
        lean = dx if travel > TREE_DROP_SPAN // 2 else 0
        x = x0 + wob + lean
        if x < 0 or x >= WIDTH or y < 0 or y >= HEIGHT:
            continue
        children.append(render.Padding(pad = (x, y, 0, 0), child = render.Box(width = 1, height = 1, color = cols[i % len(cols)])))
    if len(children) == 0:
        return render.Box(width = 1, height = 1)
    return render.Stack(children = children)

def _tree_blowoff_layer(frame, season, tier, dx):
    """Wind strips leaves/petals off the tree and sends them streaming across
    the whole screen (the canopy itself stays full -- the flyers sell it).
    Horizontal travel is exact-wrap (`f*reps*period // N_FRAMES`) so the
    stream loops seamlessly; vertical flutter uses integer-harmonic sin.
    Below hurricane strength the leaves also sink as they cross -- steeper at
    windy tier, flatter at gale -- so the flight reads as falling-and-drifting
    rather than a flat horizontal streak; only tier 4 (55+ mph) pins them
    straight across."""
    if season == "summer":  # summer gale: green leaves torn loose
        cols = ["#5aa85a", "#3f8f3f"]
    else:
        cols = TREE_LEAF_COLS[season]
    n = 4 if tier == 2 else (5 if tier == 3 else 7)
    reps = 2 + tier  # full screen crossings per loop
    drop = 0 if tier >= 4 else (9 if tier == 2 else 5)  # sink over one crossing
    period = WIDTH + 6
    step = 2.0 * math.pi / N_FRAMES
    children = []
    for i in range(n):
        f = (frame + i * 9) % N_FRAMES
        travel = (f * reps * period // N_FRAMES) % period
        x = travel - 3 if dx >= 0 else WIDTH + 2 - travel
        sink = _rnd(drop * float(travel) / float(period))
        y = TREE_BLOW_ROWS[i % len(TREE_BLOW_ROWS)] + sink + _rnd(1.2 * math.sin(f * step * 3 + i * 2))
        if x < 0 or x >= WIDTH or y < 0 or y > 24:  # 25+ is behind the ground bar
            continue
        col = cols[i % len(cols)]
        children.append(render.Padding(pad = (x, y, 0, 0), child = render.Box(width = 1, height = 1, color = col)))
    if len(children) == 0:
        return render.Box(width = 1, height = 1)
    return render.Stack(children = children)

# ---------------------------------------------------------------------------
# Wind: one intensity scale (internal mph). Effects stack as the tier climbs:
#   0 calm   (<13)  - nothing extra; flag droops
#   1 breeze (13-24)- clouds race + lean
#   2 windy  (25-38)- + horizontal speed streaks
#   3 gale   (39-54)- + tumbling debris
#   4 hurricane(55+)- + rotating eye spiral
# ---------------------------------------------------------------------------

WIND_BREEZE = 13
WIND_WINDY = 25
WIND_GALE = 39
WIND_HURRICANE = 55

def wind_tier(mph):
    if mph >= WIND_HURRICANE:
        return 4
    if mph >= WIND_GALE:
        return 3
    if mph >= WIND_WINDY:
        return 2
    if mph >= WIND_BREEZE:
        return 1
    return 0

def wind_dx(direction):
    """Horizontal blow sign from a meteorological bearing (degrees the wind
    comes FROM): +1 = blows rightward (toward east), -1 = leftward."""
    if direction == None:
        return 1
    s = math.sin(direction * math.pi / 180.0)
    return 1 if s <= 0 else -1

# Cloud wraps-per-loop and lean magnitude per tier. Tier 0 (calm, <13 mph) =
# 0 wraps: clouds sit still, because a seamless loop can't drift slower than
# one full screen pass. Drift only begins at breeze and speeds up from there.
WIND_WRAPS = [0, 1, 2, 3, 4]
WIND_LEAN = [0, 1, 1, 2, 2]

STREAK_ROWS = [3, 9, 15, 20, 24]

def wind_streak_layer(frame, tier, dx):
    """Horizontal gust streaks blowing across the sky (tier >= 2)."""
    if tier < 2:
        return render.Box(width = 1, height = 1)
    n = 2 if tier == 2 else (4 if tier == 3 else 5)
    speed = 4 + tier * 2
    length = 6 + tier * 2
    streaks = []
    for i in range(n):
        y = STREAK_ROWS[i]
        travel = (frame * speed + i * 11) % (WIDTH + length)
        if dx >= 0:
            x = travel - length
        else:
            x = WIDTH - travel
        if x <= -length or x >= WIDTH:
            continue
        streaks.append(render.Padding(
            pad = (max(0, x), y, 0, 0),
            child = render.Box(width = length, height = 1, color = "#e6eeffaa"),
        ))
    if len(streaks) == 0:
        return render.Box(width = 1, height = 1)
    return render.Stack(children = streaks)

DEBRIS_COLORS = ["#8a6a4a", "#6f5a3a", "#7a7f8c"]

def debris_layer(frame, tier, dx):
    """Small specks tumbling across at speed (tier >= 3)."""
    if tier < 3:
        return render.Box(width = 1, height = 1)
    count = 4 if tier == 3 else 7
    speed = 5 + tier
    bits = []
    for i in range(count):
        travel = (frame * speed + i * 13) % (WIDTH + 8)
        if dx >= 0:
            x = travel - 4
        else:
            x = WIDTH - travel
        if x < 0 or x > WIDTH - 2:
            continue
        base_y = (i * 9 + 2) % HEIGHT
        y = (base_y + (frame // 2 + i) % 5) % HEIGHT
        col = DEBRIS_COLORS[i % len(DEBRIS_COLORS)]
        bits.append(render.Padding(
            pad = (x, y, 0, 0),
            child = render.Box(width = 2, height = 1, color = col),
        ))
    if len(bits) == 0:
        return render.Box(width = 1, height = 1)
    return render.Stack(children = bits)

def hurricane_spiral_layer(frame):
    """A rotating eye + spiral bands, drawn dot-by-dot (tier 4)."""
    cx0 = 31
    cy0 = 12
    children = [render.Padding(pad = (cx0 - 1, cy0 - 1, 0, 0), child = render.Box(width = 2, height = 2, color = "#20242e"))]
    arms = 3

    # 2 full rotations per loop, tied to N_FRAMES so the spin stays seamless
    spin = frame * 2.0 * math.pi * 2.0 / N_FRAMES
    for a in range(arms):
        for r in range(1, 6):
            ang = (a * 2.0 * math.pi / arms) + r * 0.6 + spin
            x = int(cx0 + r * math.cos(ang) * 1.3)
            y = int(cy0 + r * math.sin(ang))
            if x < 0 or x > WIDTH - 1 or y < 0 or y > HEIGHT - 1:
                continue
            shade = "#cfd6e0" if r < 3 else "#9aa6b8"
            children.append(render.Padding(pad = (x, y, 0, 0), child = render.Box(width = 1, height = 1, color = shade)))
    return render.Stack(children = children)

TORNADO_BODY = "#5b6373"
TORNADO_DARK = "#3f4654"
TORNADO_LITE = "#828b9c"

def tornado_layer(frame, dx):
    """A swaying, rotating funnel from the cloud base to the ground. Pivots at the
    top (anchored to the clouds) and whips wider at the bottom, with a 1px bright
    streak sliding across each row to suggest spin, plus dust kicking up at the base.
    `dx` leans the funnel downwind."""
    y_top = 3
    y_bot = 24
    wide = 9.0
    narrow = 2.0
    base_x = 30
    step = 2.0 * math.pi / N_FRAMES
    swing = 5.0 * math.sin(frame * step * 2.0)  # bottom whips back and forth
    children = []
    for y in range(y_top, y_bot + 1):
        t = float(y - y_top) / float(y_bot - y_top)  # 0 top -> 1 bottom

        # concave funnel: narrows quickly near the top, then tapers to the ground
        w = _rnd(narrow + (wide - narrow) * (1.0 - t) * (1.0 - t))
        if w < 1:
            w = 1

        # pivot at the top: horizontal sway + a curl grows toward the bottom,
        # and the whole funnel leans downwind
        off = swing * t + 2.0 * math.sin(frame * step + t * 3.5) * t + dx * 3.0 * t
        x0 = base_x + _rnd(off) - w // 2
        children.append(render.Padding(pad = (max(0, x0), y, 0, 0), child = render.Box(width = w, height = 1, color = TORNADO_BODY)))

        # spin highlight: a bright pixel sliding across the funnel each frame
        hx = x0 + (frame + y) % w
        if hx >= 0 and hx < WIDTH:
            children.append(render.Padding(pad = (max(0, hx), y, 0, 0), child = render.Box(width = 1, height = 1, color = TORNADO_LITE)))

    # dust/debris kicking up around the base
    for i in range(6):
        ang = frame * 0.5 + i * 1.2
        x = base_x + _rnd(swing) + _rnd(math.cos(ang) * (3 + i))
        yb = y_bot - _rnd(abs(math.sin(ang)) * 2)
        if x >= 0 and x < WIDTH and yb >= 0 and yb < HEIGHT:
            children.append(render.Padding(pad = (x, yb, 0, 0), child = render.Box(width = 1, height = 1, color = TORNADO_DARK)))
    return render.Stack(children = children)

WINDSOCK_ORANGE = "#ff7a30"
WINDSOCK_WHITE = "#e8ecf4"
WINDSOCK_POLE = "#aab6d4"  # dimmer than the digits so the readout pops

def wind_flag(frame, tier, dx, mph):
    """Airport-style windsock for the ground bar, drawn as 1px-wide segments
    (x, y, h, color) in a 7x6 local grid with the pole at x=0, mirrored for
    leftward wind. The sock is a chunky tapered cone -- a 3px-tall mouth ring
    thinning to a 1px tip -- in orange/white bands, and its lift angle maps
    to the tier: hanging (calm), ~45 deg (breeze), near-horizontal with sag
    (windy), taut and full-length with a whipping tip (gale/hurricane). A
    sine bump travels out along the sock (integer-harmonic speed, so the
    ripple loops seamlessly). The calm tier spans 0-12 mph, so it splits on
    actual `mph`: dead-still air hangs limp with just a slow tip drift, but
    light air (3+) swings the hanging sock like a pendulum -- bottom rows
    swinging wider than the top, on two mixed integer harmonics so the
    flutter reads as continuous, not a single flip per loop."""
    step = 2.0 * math.pi / N_FRAMES
    segs = [(0, 0, 6, WINDSOCK_POLE)]
    if tier <= 0:
        segs += [
            (1, 0, 2, WINDSOCK_ORANGE),
            (2, 0, 1, WINDSOCK_ORANGE),
        ]
        if mph >= 3:
            # light air: a gentle pendulum swing traveling down the sock
            s = 0.7 * math.sin(frame * step * 2) + 0.5 * math.sin(frame * step * 3)
            segs += [
                (1 + (1 if s > 0.5 else 0), 2, 1, WINDSOCK_WHITE),
                (1 + (1 if s > 0.1 else 0), 3, 1, WINDSOCK_ORANGE),
                (1 + (2 if s > 0.6 else (1 if s > -0.3 else 0)), 4, 1, WINDSOCK_WHITE),
            ]
        else:
            # dead still: limp hang, tip drifting once across the loop
            tip_x = 1 if math.sin(frame * step) >= 0 else 2
            segs += [
                (1, 2, 1, WINDSOCK_WHITE),
                (1, 3, 1, WINDSOCK_ORANGE),
                (tip_x, 4, 1, WINDSOCK_WHITE),
            ]
    else:
        # traveling ripple: a bump moving out along the sock, faster per tier
        speed = 1 + tier
        r = []
        for c in range(7):
            r.append(1 if math.sin(frame * step * speed - c * 1.1) > 0.35 else 0)
        if tier == 1:
            # breeze: lifted ~45 deg, gently wiggling
            segs += [
                (1, 0, 3, WINDSOCK_ORANGE),
                (2, 1 + r[2], 2, WINDSOCK_WHITE),
                (3, 2 + r[3], 2, WINDSOCK_ORANGE),
                (4, 4 + r[4], 1, WINDSOCK_WHITE),
            ]
        elif tier == 2:
            # windy: streaming near-horizontal, sagging where the ripple runs
            segs += [
                (1, 0, 3, WINDSOCK_ORANGE),
                (2, 0 + r[2], 2, WINDSOCK_WHITE),
                (3, 1 + r[3], 2, WINDSOCK_ORANGE),
                (4, 1 + r[4], 1, WINDSOCK_WHITE),
                (5, 2 + r[5], 1, WINDSOCK_ORANGE),
            ]
        else:
            # gale/hurricane: fully inflated and taut, tip whipping
            whip = _rnd(1.0 + 1.4 * math.sin(frame * step * (3 + tier)))
            whip = 0 if whip < 0 else (2 if whip > 2 else whip)
            segs += [
                (1, 0, 3, WINDSOCK_ORANGE),
                (2, 0, 2, WINDSOCK_WHITE),
                (3, 0 + r[3], 2, WINDSOCK_ORANGE),
                (4, r[4], 1, WINDSOCK_WHITE),
                (5, r[5], 1, WINDSOCK_ORANGE),
                (6, whip, 1, WINDSOCK_WHITE),
            ]
    children = []
    for (x, y, h, col) in segs:
        nx = 6 - x if dx < 0 else x
        children.append(render.Padding(pad = (nx, y, 0, 0), child = render.Box(width = 1, height = h, color = col)))
    return render.Stack(children = children)

# ---------------------------------------------------------------------------
# Severe-weather alerts: a pulsing corner badge, color by level.
#   1 yellow - storm approaching (Open-Meteo hourly peek, no official alert)
#   2 orange - NWS "Severe" alert active
#   3 red    - NWS "Extreme" alert active
# ---------------------------------------------------------------------------

def alert_level_from_severity(severities):
    """Highest NWS severity -> level. Extreme=3, Severe=2, otherwise 0."""
    level = 0
    for s in severities:
        if s == "Extreme":
            return 3
        if s == "Severe" and level < 2:
            level = 2
    return level

def alert_from_features(features):
    """NWS alert GeoJSON features -> (level, event headline). The headline is
    the `event` field (e.g. "Tornado Warning") of the alert matching the
    highest severity found; ("", 0) if nothing serious is active."""
    sevs = []
    for ft in features:
        sevs.append(ft.get("properties", {}).get("severity", ""))
    level = alert_level_from_severity(sevs)
    if level == 0:
        return 0, ""
    want = "Extreme" if level == 3 else "Severe"
    for ft in features:
        props = ft.get("properties", {})
        if props.get("severity", "") == want:
            return level, props.get("event", "")
    return level, ""

def storm_incoming(codes):
    """True if any upcoming hourly WMO code is a thunderstorm (>= 95)."""
    for c in codes:
        if c != None and c >= 95:
            return True
    return False

def _fmt4(v):
    """Format a float to 4 decimal places. Starlark's % operator has no %.4f,
    and NWS rejects coordinates with more than 4 decimals (301 redirect)."""
    neg = v < 0
    if neg:
        v = -v
    scaled = int(v * 10000 + 0.5)
    whole = scaled // 10000
    frac_s = str(scaled % 10000)
    frac_s = "0" * (4 - len(frac_s)) + frac_s
    out = str(whole) + "." + frac_s
    if neg:
        return "-" + out
    return out

# API throttle: snap coordinates to a coarse grid before building weather/NWS
# URLs. Nearby or rapidly-dragged lat/lng then collapse to the same URL, which
# the http cache (ttl_seconds) already de-dupes -- so micro-adjustments don't
# each fire a fresh call. Grid step is 1/API_SNAP degrees: 100 -> ~1.1 km,
# 22 -> ~5 km (one cache entry per ~5 km tile), 10 -> ~11 km. Coarser = more
# neighbors share one fetch, at the cost of weather granularity.
API_SNAP = 22.0

def _snap(v):
    """Round a coordinate to the API grid (see API_SNAP) for cache-friendly URLs."""
    return float(int(v * API_SNAP + (0.5 if v >= 0 else -0.5))) / API_SNAP

ALERT_BRIGHT = [None, "#ffd23f", "#ff8a3d", "#ff3b30"]
ALERT_DIM = [None, "#8a7320", "#8a4a20", "#7a1d18"]

# triangle rows: (left_pad, width) centered in a 7px box, apex on top
_ALERT_TRI = [(3, 1), (2, 3), (2, 3), (1, 5), (1, 5), (0, 7)]

def alert_badge(frame, level):
    """A pulsing warning triangle (with !) for the top-right corner."""
    if level <= 0:
        return render.Box(width = 1, height = 1)
    col = ALERT_BRIGHT[level] if (frame % 12) < 8 else ALERT_DIM[level]
    rows = []
    for pad_l, w in _ALERT_TRI:
        rows.append(render.Padding(pad = (pad_l, 0, 0, 0), child = render.Box(width = w, height = 1, color = col)))
    triangle = render.Column(children = rows)
    exclaim = render.Stack(children = [
        render.Padding(pad = (3, 1, 0, 0), child = render.Box(width = 1, height = 2, color = "#2a1c00")),
        render.Padding(pad = (3, 4, 0, 0), child = render.Box(width = 1, height = 1, color = "#2a1c00")),
    ])
    return render.Stack(children = [triangle, exclaim])

# Last slice of the loop: the scene dims and the alert headline fades in on
# top, so the pixels "fade away" to reveal what the advisory actually says,
# then the loop wraps back to the normal live scene.
ALERT_FADE_FRAMES = 30

def alert_fade_progress(frame):
    """0..1 ramp over the last ALERT_FADE_FRAMES frames of the loop; 0 before that."""
    start = N_FRAMES - ALERT_FADE_FRAMES
    if frame < start:
        return 0.0
    span = ALERT_FADE_FRAMES - 1
    return (frame - start) / float(span) if span > 0 else 1.0

def alert_reveal_layer(frame, alert_text):
    """Dims the whole scene and fades in the alert headline, centered, near
    the end of the loop. Both ramps finish early in the window (dim by 20%,
    text by 35%) so the headline holds at full legibility for most of the
    window instead of just flashing on the last frame or two.

    Uses `render.WrappedText` in "tb-8" rather than hand-rolling a char-budget
    wrap in "tom-thumb": tom-thumb draws N and M almost identically at this
    pixel size (confirmed by rendering "NM MN" in it -- both read as "MM MM"),
    which made headlines like "WARNING" misread as "WARMING". WrappedText
    also wraps by actual glyph width instead of a guessed character count, so
    it centers correctly even though tb-8 isn't monospace."""
    t = alert_fade_progress(frame)
    if t <= 0.0 or alert_text == "":
        return render.Box(width = 1, height = 1)
    dim_t = t / 0.2
    dim_t = 1.0 if dim_t > 1.0 else dim_t
    dim = _hex2(_rnd(dim_t * 210))
    children = [render.Box(width = WIDTH, height = HEIGHT, color = "#000000" + dim)]
    text_t = (t - 0.1) / 0.25
    text_t = 0.0 if text_t < 0.0 else (1.0 if text_t > 1.0 else text_t)
    if text_t > 0.0:
        col = "#ffe28a" + _hex2(_rnd(text_t * 255))
        children.append(render.Box(
            width = WIDTH,
            height = HEIGHT,
            child = render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [render.WrappedText(content = alert_text, font = "tb-8", color = col, width = WIDTH - 2, align = "center", linespacing = 1)],
            ),
        ))
    return render.Stack(children = children)

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def _arc_fraction(now, rise, sett, is_day):
    """Progress 0..1 of the sun (day) or moon (night) across its arc."""
    if rise != None and sett != None and is_day:
        span = sett.unix - rise.unix
        frac = (now.unix - rise.unix) / span if span > 0 else 0.5
    elif rise != None and sett != None:
        # night: estimate progress between today's sunset and ~next sunrise
        night_len = 86400 - (sett.unix - rise.unix)
        if now.unix > sett.unix:
            frac = (now.unix - sett.unix) / night_len
        else:
            frac = (now.unix - (sett.unix - 86400)) / night_len
    else:
        frac = 0.5  # polar edge case: park it overhead
    return min(1.0, max(0.0, frac))

def _fetch_open_meteo(lat, lng):
    """Open-Meteo current= block + hourly storm peek. Fail-soft: ok=False.
    Always fetched in canonical metric (celsius/kmh) so the URL -- and thus the
    shared http cache entry -- is identical for °F and °C users; temp/wind are
    converted to display units by the caller (raw float carried out here)."""
    resp = http.get(WEATHER_URL % (lat, lng, "celsius", "kmh"), ttl_seconds = 600)
    if resp.status_code != 200:
        return struct(ok = False, code = None, temp = None, wind = None, wind_dir = None, cloud_pct = None, precip_mm = 0.0, snow_mm = 0.0, incoming = False)
    data = resp.json()
    code = None
    temp = None
    wind = None
    wind_dir = None
    cloud_pct = None
    precip_mm = 0.0
    snow_mm = 0.0
    cur = data.get("current")
    if cur != None:
        code = int(cur.get("weather_code", 0))
        temp = float(cur.get("temperature_2m", 0))  # raw °C; caller converts+rounds
        wind = float(cur.get("wind_speed_10m", 0))  # raw km/h; caller converts
        wind_dir = float(cur.get("wind_direction_10m", 0))
        cloud_pct = float(cur.get("cloud_cover", 0))
        precip_mm = float(cur.get("precipitation", 0))
        snow_mm = float(cur.get("snowfall", 0))
    incoming = False
    hourly = data.get("hourly")
    if hourly != None:
        incoming = storm_incoming(hourly.get("weather_code", [])[1:4])
    return struct(ok = True, code = code, temp = temp, wind = wind, wind_dir = wind_dir, cloud_pct = cloud_pct, precip_mm = precip_mm, snow_mm = snow_mm, incoming = incoming)

def _nws_val(obj):
    """NWS wraps measurements as {value, unitCode}; pull value, tolerate null."""
    if obj == None:
        return None
    return obj.get("value")

NWS_STATION_TRIES = 3  # nearby stations to try if the closest one's latest
# reading is temporarily incomplete (common METAR gap between report cycles)

def _fetch_nws_obs(lat, lng, units):
    """US station observation (real conditions). Crawl point -> station ->
    latest, trying up to NWS_STATION_TRIES nearby stations in case the
    closest one's latest reading is missing its temperature (a station can
    report on schedule with a null value between cycles -- not a network
    failure, just an incomplete observation). Returns a scene+temp+wind
    struct, or None to fall back."""
    pt = http.get(NWS_POINTS_URL % (_fmt4(lat), _fmt4(lng)), headers = NWS_HEADERS, ttl_seconds = 86400)
    if pt.status_code != 200:
        return None
    stations_url = pt.json().get("properties", {}).get("observationStations")
    if stations_url == None:
        return None
    st = http.get(stations_url, headers = NWS_HEADERS, ttl_seconds = 86400)
    if st.status_code != 200:
        return None
    feats = st.json().get("features", [])
    if len(feats) == 0:
        return None

    for feat in feats[:NWS_STATION_TRIES]:
        sid = feat.get("properties", {}).get("stationIdentifier")
        if sid == None:
            continue
        ob = http.get(NWS_OBS_URL % sid, headers = NWS_HEADERS, ttl_seconds = 300)
        if ob.status_code != 200:
            continue
        props = ob.json().get("properties")
        if props == None:
            continue
        t = _nws_val(props.get("temperature"))
        if t == None:
            continue  # this station's latest reading is incomplete -- try the next
        temp = int(t * 9.0 / 5.0 + 32 + 0.5) if units == "fahrenheit" else int(t + 0.5)

        ws = _nws_val(props.get("windSpeed"))  # km/h
        wind = 0.0
        if ws != None:
            wind = ws * 0.621371 if units == "fahrenheit" else ws
        wd = _nws_val(props.get("windDirection"))
        wind_dir = wd if wd != None else 0.0

        amounts = []
        for cl in props.get("cloudLayers", []):
            a = cl.get("amount")
            if a != None:
                amounts.append(a)
        weathers = []
        for pw in props.get("presentWeather", []):
            w = pw.get("weather")
            if w != None:
                weathers.append((w, pw.get("intensity")))
        sc = nws_scene(amounts, weathers)
        return struct(clouds = sc.clouds, precip = sc.precip, fog = sc.fog, storm = sc.storm, smoke = sc.smoke, level = sc.level, temp = temp, wind = wind, wind_dir = wind_dir)

    return None  # none of the tried stations had a usable reading -> fall back

def _live_inputs(config, units):
    """Real sky: sun math (local) + weather (network, fail-soft).
    Source is NWS station obs in the US (Auto/NWS), else Open-Meteo -- and
    Open-Meteo is only fetched when NWS didn't cover it, so an Open-Meteo
    outage can't take down a render NWS already handled.
    Returns (elev, frac, is_day, wx, temp, phase)."""
    loc = json.decode(config.get("location", DEFAULT_LOCATION))
    lat = float(loc["lat"])
    lng = float(loc["lng"])
    tz = loc.get("timezone", "America/New_York")

    # local preview (pixlet serve) hands us the Brooklyn sentinel -> use home.
    # Gated by LOCAL_PREVIEW_FALLBACK so prod never moves real Brooklyn users.
    if _use_home_fallback(lat, lng):
        home = json.decode(DEFAULT_LOCATION)
        lat = float(home["lat"])
        lng = float(home["lng"])
        tz = home.get("timezone", "America/New_York")

    now = time.now().in_location(tz)

    elev = sunrise.elevation(lat, lng, now)
    rise = sunrise.sunrise(lat, lng, now)
    sett = sunrise.sunset(lat, lng, now)
    is_day = elev > 0
    frac = _arc_fraction(now, rise, sett, is_day)
    phase = moon_phase_fraction(now)

    source = config.get("weather_source", "auto")

    # Snap coords for all network calls so jittery lat/lng reuse cached requests
    # (sun/moon math above still uses the exact location).
    qlat = _snap(lat)
    qlng = _snap(lng)

    # Scene/temp/wind: prefer real US station obs (NWS), else Open-Meteo.
    # Open-Meteo is only fetched when it's actually needed -- NWS failed (or
    # covers nothing at this location), or the user explicitly picked it --
    # NOT unconditionally like before. Starlark has no try/except: a hard
    # network failure inside http.get (DNS, timeout, connection refused)
    # aborts the whole script, status_code checks never get a chance to run.
    # So the only real defense against a down endpoint is to not call it when
    # its data isn't needed, which also means a healthy NWS path now survives
    # an Open-Meteo outage instead of crashing on a fetch nothing uses.
    nws = None
    if source != "openmeteo":
        nws = _fetch_nws_obs(qlat, qlng, units)

    om = None
    if nws == None:
        om = _fetch_open_meteo(qlat, qlng)
        if not om.ok and source == "openmeteo":
            # explicit Open-Meteo pick came back with a clean HTTP error (a
            # hard network failure would have aborted above already) --
            # failover to NWS rather than show nothing.
            nws = _fetch_nws_obs(qlat, qlng, units)

    # official NWS alerts (US-only, fail-soft). Network errors -> no alert.
    alert = 0
    alert_text = ""
    ar = http.get(NWS_ALERTS_URL % (_fmt4(qlat), _fmt4(qlng)), headers = NWS_HEADERS, ttl_seconds = 300)
    if ar.status_code == 200:
        alert, alert_text = alert_from_features(ar.json().get("features", []))
    if alert == 0 and om != None and om.incoming:
        alert = 1  # softer "storm approaching" cue -- an Open-Meteo-only
        # signal, so it's unavailable on the render passes where NWS already
        # covered the scene and Open-Meteo was skipped entirely (see above).

    if nws != None:
        clouds = nws.clouds
        precip = nws.precip
        plevel = nws.level
        fog = nws.fog
        storm = nws.storm
        smoke = nws.smoke
        temp = nws.temp
        wind = nws.wind
        wind_dir = nws.wind_dir
    else:
        # Open-Meteo: weathercode classifies fog/storm/base; real observations
        # refine the cloud count and turn precip on when it's actually falling.
        base = weather_kind(om.code)
        clouds = clouds_from_cover(om.cloud_pct) if om.cloud_pct != None else base.clouds
        precip = precip_from_obs(base.precip, om.precip_mm, om.snow_mm)
        plevel = precip_level(precip, om.precip_mm, om.snow_mm, om.code)
        fog = base.fog
        storm = base.storm
        smoke = False  # Open-Meteo's weather code has no smoke category

        # convert canonical metric -> display units, rounding only after convert
        temp = None if om.temp == None else (int(om.temp * 9.0 / 5.0 + 32 + 0.5) if units == "fahrenheit" else int(om.temp + 0.5))
        wind = None if om.wind == None else (om.wind * 0.621371 if units == "fahrenheit" else om.wind)
        wind_dir = om.wind_dir

    # seed for cloud arrangement; changes hourly so the sky isn't always identical
    cloud_seed = (now.month * 31 + now.day) * 24 + now.hour

    # heat haze: hot, bright, clear-enough daytime air (Fahrenheit-equivalent
    # regardless of display units, since the trigger threshold is fixed).
    temp_f = None if temp == None else (float(temp) if units == "fahrenheit" else temp * 9.0 / 5.0 + 32)
    heat_haze = _heat_haze_auto(is_day, temp_f, clouds, fog, storm, smoke, precip)

    # seasonal tree: real meteorological season, hemisphere-aware from latitude
    season = season_from_month(now.month, lat < 0)

    wx = struct(clouds = clouds, precip = precip, precip_level = plevel, fog = fog, storm = storm, smoke = smoke, wind = wind, wind_dir = wind_dir, alert = alert, alert_text = alert_text, cloud_seed = cloud_seed, tornado = False, aurora = False, heat_haze = heat_haze, season = season)
    return elev, frac, is_day, wx, temp, phase

def _num(config, key, default):
    """Parse a numeric config string, returning `default` if blank/invalid.
    (Starlark float() raises on bad input, so we validate first.)"""
    s = config.get(key, "")
    if s == None:
        return default
    s = s.strip()
    if s == "":
        return default
    body = s[1:] if s[0] == "-" else s
    if len(body) == 0:
        return default
    dots = 0
    for i in range(len(body)):
        ch = body[i]
        if ch == ".":
            dots += 1
        elif ch < "0" or ch > "9":
            return default
    if dots > 1:
        return default
    return float(s)

# One-click recipes that fill every demo dial at once.
# Fields: elev (°), arc (0-100), phase (0-100), clouds (0-4),
#         precip ("none"/"rain"/"snow"), precip_level (1 light/2 mod/3 heavy),
#         fog, storm, temp (°F), wind (mph),
#         alert (0 none / 1 approaching / 2 severe / 3 extreme),
#         season (optional: the season the tree implies while the Season dial
#         is Auto; neutral presets omit it and leave season to the Month dial).
PRESETS = {
    "thunderstorm": struct(elev = 2, arc = 55, phase = 50, clouds = 4, precip = "rain", precip_level = 3, fog = False, storm = True, temp = 66, wind = 30, alert = 2, alert_text = "Severe Thunderstorm Warning"),
    "night_thunderstorm": struct(elev = -16, arc = 55, phase = 50, clouds = 4, precip = "rain", precip_level = 3, fog = False, storm = True, temp = 61, wind = 28, alert = 2, alert_text = "Severe Thunderstorm Warning"),
    "blizzard": struct(elev = 8, arc = 50, phase = 50, clouds = 4, precip = "snow", precip_level = 3, fog = True, storm = False, temp = 14, wind = 36, alert = 2, alert_text = "Winter Storm Warning", season = "winter"),
    "gentle_snow": struct(elev = -18, arc = 50, phase = 30, clouds = 2, precip = "snow", precip_level = 1, fog = False, storm = False, temp = 27, wind = 6, alert = 0, season = "winter"),
    "overcast_drizzle": struct(elev = 14, arc = 45, phase = 50, clouds = 4, precip = "rain", precip_level = 1, fog = False, storm = False, temp = 54, wind = 16, alert = 0),
    "foggy_morning": struct(elev = 5, arc = 18, phase = 50, clouds = 2, precip = "none", precip_level = 0, fog = True, storm = False, temp = 47, wind = 3, alert = 0),
    "sunrise": struct(elev = 1, arc = 10, phase = 50, clouds = 1, precip = "none", precip_level = 0, fog = False, storm = False, temp = 51, wind = 5, alert = 0),
    "golden_hour": struct(elev = 3, arc = 84, phase = 50, clouds = 1, precip = "none", precip_level = 0, fog = False, storm = False, temp = 72, wind = 7, alert = 0),
    "heatwave": struct(elev = 72, arc = 50, phase = 50, clouds = 0, precip = "none", precip_level = 0, fog = False, storm = False, temp = 101, wind = 4, alert = 0, season = "summer"),
    "starry_night": struct(elev = -45, arc = 50, phase = 50, clouds = 0, precip = "none", precip_level = 0, fog = False, storm = False, temp = 44, wind = 2, alert = 0),
    "crescent_moon": struct(elev = -30, arc = 68, phase = 10, clouds = 0, precip = "none", precip_level = 0, fog = False, storm = False, temp = 49, wind = 3, alert = 0),
    "harvest_moon": struct(elev = -6, arc = 88, phase = 50, clouds = 1, precip = "none", precip_level = 0, fog = False, storm = False, temp = 58, wind = 5, alert = 0, season = "fall"),
    "hurricane": struct(elev = 6, arc = 50, phase = 50, clouds = 4, precip = "rain", precip_level = 3, fog = False, storm = True, temp = 79, wind = 90, alert = 3, alert_text = "Hurricane Warning", season = "summer"),
    "tornado": struct(elev = 7, arc = 50, phase = 50, clouds = 4, precip = "rain", precip_level = 2, fog = False, storm = True, temp = 74, wind = 46, alert = 3, tornado = True, alert_text = "Tornado Warning", season = "spring"),
    "ice_storm": struct(elev = 10, arc = 45, phase = 50, clouds = 4, precip = "ice", precip_level = 3, fog = False, storm = False, temp = 30, wind = 18, alert = 2, alert_text = "Ice Storm Warning", season = "winter"),
    "sleet": struct(elev = 12, arc = 50, phase = 50, clouds = 4, precip = "sleet", precip_level = 2, fog = False, storm = False, temp = 33, wind = 14, alert = 0, season = "winter"),
    "hailstorm": struct(elev = 5, arc = 55, phase = 50, clouds = 4, precip = "hail", precip_level = 3, fog = False, storm = True, temp = 68, wind = 28, alert = 2, alert_text = "Severe Thunderstorm Warning"),
    "wildfire": struct(elev = 18, arc = 60, phase = 50, clouds = 1, precip = "none", precip_level = 0, fog = False, storm = False, temp = 96, wind = 8, alert = 1, smoke = True, season = "summer"),
    "aurora": struct(elev = -30, arc = 50, phase = 8, clouds = 0, precip = "none", precip_level = 0, fog = False, storm = False, temp = 18, wind = 4, alert = 0, aurora = True, season = "winter"),
}

def _demo_season(config, implied = None):
    """Season dial: an explicit choice wins outright; on 'auto' a seasonal
    preset's implied season (blizzard -> winter, heatwave -> summer, ...)
    applies if one was given, else it derives from the Month dial (Southern
    Hemisphere if a negative override latitude is set)."""
    choice = config.get("demo_season", "auto")
    if choice != "auto":
        return choice
    if implied != None:
        return implied
    month = int(_num(config, "demo_month", 6.0))
    lat_s = config.get("demo_lat", "").strip()
    southern = _num(config, "demo_lat", 0.0) < 0 if lat_s != "" else False
    return season_from_month(month, southern)

def _demo_inputs(config, units):
    """Simulator: deterministic, offline overrides for every render input.
    Returns (elev, frac, is_day, wx, temp, phase).

    Three ways to drive the sky:
      * Preset: a named recipe fills every dial at once (overrides all below).
      * Manual dials: set sun elevation, arc position, moon phase, weather.
      * Real astronomy: fill demo_lat AND demo_lng and the sun/moon are
        computed for that place at demo_month / demo_hour (location + season).
    """
    preset = config.get("demo_preset", "custom")
    if preset != "custom" and preset in PRESETS:
        p = PRESETS[preset]
        season = _demo_season(config, getattr(p, "season", None))
        frac = min(1.0, max(0.0, p.arc / 100.0))
        phase = min(1.0, max(0.0, p.phase / 100.0))
        precip = None if p.precip == "none" else p.precip

        # preset wind is stored in mph; show it in the user's display unit
        wind_disp = p.wind if units == "fahrenheit" else p.wind / 0.621371
        plevel = p.precip_level if precip != None else 0

        # heat haze: auto from the preset's own temp/sky, OR forced by the demo
        # toggle (so you can preview the shimmer over any preset/dial combo).
        temp_f = p.temp if units == "fahrenheit" else p.temp * 9.0 / 5.0 + 32
        heat_haze = _heat_haze_auto(p.elev > 0, temp_f, p.clouds, p.fog, p.storm, getattr(p, "smoke", False), precip) or config.bool("demo_heat_haze", False)

        wx = struct(clouds = p.clouds, precip = precip, precip_level = plevel, fog = p.fog, storm = p.storm, smoke = getattr(p, "smoke", False), wind = wind_disp, wind_dir = 270.0, alert = p.alert, alert_text = getattr(p, "alert_text", ""), cloud_seed = 0, tornado = getattr(p, "tornado", False), aurora = getattr(p, "aurora", False), heat_haze = heat_haze, season = season)
        return p.elev, frac, p.elev > 0, wx, p.temp, phase

    season = _demo_season(config)
    lat_s = config.get("demo_lat", "").strip()
    lng_s = config.get("demo_lng", "").strip()
    if lat_s != "" and lng_s != "":
        lat = _num(config, "demo_lat", 0.0)
        lng = _num(config, "demo_lng", 0.0)
        month = int(_num(config, "demo_month", 6.0))
        hour = int(_num(config, "demo_hour", 12.0))
        now = time.time(year = 2026, month = month, day = 15, hour = hour, minute = 0, second = 0, location = "UTC")
        elev = sunrise.elevation(lat, lng, now)
        rise = sunrise.sunrise(lat, lng, now)
        sett = sunrise.sunset(lat, lng, now)
        is_day = elev > 0
        frac = _arc_fraction(now, rise, sett, is_day)
        phase = moon_phase_fraction(now)
    else:
        elev = _num(config, "demo_elev", 20.0)
        frac = min(1.0, max(0.0, _num(config, "demo_arc", 50.0) / 100.0))
        is_day = elev > 0
        phase = min(1.0, max(0.0, _num(config, "demo_phase", 50.0) / 100.0))

    clouds = int(_num(config, "demo_clouds", 1.0))
    precip = config.get("demo_precip", "none")
    precip = None if precip == "none" else precip
    plevel = int(_num(config, "demo_precip_level", 2.0)) if precip != None else 0
    fog = config.bool("demo_fog", False)
    storm = config.bool("demo_storm", False)
    smoke = config.bool("demo_smoke", False)
    tornado = config.bool("demo_tornado", False)
    aurora = config.bool("demo_aurora", False)
    wind = _num(config, "demo_wind", 10.0)
    wind_dir = _num(config, "demo_wind_dir", 270.0)
    alert = int(_num(config, "demo_alert", 0.0))
    alert_text = config.get("demo_alert_text", "").strip() if alert >= 2 else ""
    cloud_seed = int(_num(config, "demo_cloud_seed", 0.0))
    temp = int(_num(config, "demo_temp", 63.0))

    # heat haze: auto from the dialed temp/sky, OR forced by the demo toggle.
    temp_f = float(temp) if units == "fahrenheit" else temp * 9.0 / 5.0 + 32
    heat_haze = _heat_haze_auto(is_day, temp_f, clouds, fog, storm, smoke, precip) or config.bool("demo_heat_haze", False)

    wx = struct(clouds = clouds, precip = precip, precip_level = plevel, fog = fog, storm = storm, smoke = smoke, wind = wind, wind_dir = wind_dir, alert = alert, alert_text = alert_text, cloud_seed = cloud_seed, tornado = tornado, aurora = aurora, heat_haze = heat_haze, season = season)
    return elev, frac, is_day, wx, temp, phase

def main(config):
    units = config.get("units", "fahrenheit")
    show_temp = config.bool("show_temp", True)
    show_wind = config.bool("show_wind", True)
    rays_mode = config.get("sun_rays", "subtle")  # off / subtle / bold
    demo = config.bool("demo_mode", False)

    if demo:
        elev, frac, is_day, wx, temp, phase = _demo_inputs(config, units)
    else:
        elev, frac, is_day, wx, temp, phase = _live_inputs(config, units)

    # wind: convert to mph (display unit may be km/h) and pick an intensity tier
    have_wind = show_wind and wx.wind != None
    if wx.wind != None:
        wind_mph = wx.wind if units == "fahrenheit" else wx.wind * 0.621371
    else:
        wind_mph = 0.0
    tier = wind_tier(wind_mph)
    dx = wind_dx(wx.wind_dir)
    cloud_wraps = WIND_WRAPS[tier]
    lean = WIND_LEAN[tier]
    cloud_plan = build_cloud_plan(wx.clouds, wx.cloud_seed)

    # star brightness fades in below the horizon
    star_bright = 0.0
    if elev < 0:
        star_bright = min(1.0, -elev / 12.0)

    # hide stars under heavy cloud, fog, smoke, OR any falling precip -- otherwise
    # white snow/rain at night reads as "falling stars" (can't see stars through it)
    if wx.clouds >= 3 or wx.fog or wx.smoke or wx.precip != None:
        star_bright = 0.0

    palette = sky_palette(elev, is_day, wx.fog, wx.clouds, wx.storm, wx.precip, wx.smoke)
    cloud_color = "#e9edf2" if is_day else "#3c4258"
    cloud_hi = "#ffffff" if is_day else "#565e78"

    # Flat-grey-sky scenes (clouds >= 4 or storm -> see sky_palette): the sky is
    # light grey, so dark storm clouds with only a muted (non-white) highlight
    # read clearly without bright rims -- overcast/thunderstorm/blizzard/hurricane.
    if wx.smoke:
        # wildfire murk: clouds are smoke-stained brown-grey, not bright white
        cloud_color = "#8a6a4e" if is_day else "#3a2c20"
        cloud_hi = "#9c7a5a" if is_day else "#473628"
    elif wx.clouds >= 4 or wx.storm:
        cloud_color = "#565d6b" if is_day else "#444b5a"
        cloud_hi = "#636b7a" if is_day else "#525a6b"
    elif wx.precip != None or wx.clouds >= 3:
        # rain/showers under a still-blue sky: moody darkened clouds
        cloud_color = "#8d96a6" if is_day else "#2e3346"
        cloud_hi = "#aab3c2" if is_day else "#454c64"

    # celestial body: hidden under overcast/fog; a diffuse glow when foggy
    cx, cy = arc_position(frac)
    body = None
    bx, by = cx, cy
    kind = sky_body_kind(is_day, wx.fog, wx.clouds, wx.precip, wx.smoke)
    if kind == "sun":
        body = sun_widget()
    elif kind == "ember":
        body = sun_ember_widget()
    elif kind == "glow":
        body = sun_glow_widget()
        bx, by = max(0, cx - 2), max(0, cy - 2)  # center the wider glow on the sun
    elif kind == "moon":
        # match the shadow to the sky band the moon sits in (bands are 8px tall)
        moon_band = (cy + 3) // 8
        moon_band = 0 if moon_band < 0 else (3 if moon_band > 3 else moon_band)
        body = moon_widget(phase, palette[moon_band])

    # temperature readout sits on a translucent "ground" bar across the bottom,
    # so it reads as foreground instead of a label floating on the sky. Static
    # across frames, so build it once. The number is tinted by temperature
    # (cold blue -> mild white -> hot orange); the 1px top edge keeps the bar
    # legible even on a dark night sky.
    have_temp = show_temp and temp != None
    bar_static = None
    if have_temp or have_wind:
        bar_kids = [
            render.Padding(pad = (0, 25, 0, 0), child = render.Box(width = WIDTH, height = 7, color = "#0d1330e6")),
            render.Padding(pad = (0, 25, 0, 0), child = render.Box(width = WIDTH, height = 1, color = "#48568a")),
        ]
        temp_w = 0
        if have_temp:
            unit_mark = "F" if units == "fahrenheit" else "C"
            label = "%d°%s" % (temp, unit_mark)
            temp_w = len(label)
            tf = temp if units == "fahrenheit" else temp * 9.0 / 5.0 + 32
            if tf >= 90:
                tint = "#ff9e6b"
            elif tf >= 75:
                tint = "#ffd79e"
            elif tf >= 55:
                tint = "#ffffff"
            elif tf >= 35:
                tint = "#cfe7ff"
            else:
                tint = "#9fd1ff"
            bar_kids.append(render.Padding(pad = (2, 26, 0, 0), child = render.Text(label, font = "tom-thumb", color = tint)))

        # weather glyph just right of the temperature (or far left if temp hidden)
        spec = condition_icon(wx, tier)
        if spec != None:
            irows, icol = spec
            ix = 2 + temp_w * 4 + 1 if have_temp else 2
            ix = 24 if ix > 24 else ix
            bar_kids.append(_draw_icon(irows, icol, ix, 26))
        if have_wind:
            # number first at a fixed x, sock after it with a constant 2px
            # gap -- the sock streams into open space instead of crowding the
            # digits (which it did when it sat between icon and number).
            wnum = str(int(wx.wind + 0.5))
            bar_kids.append(render.Padding(pad = (33, 26, 0, 0), child = render.Text(wnum, font = "tom-thumb", color = "#bcd0ee")))
            sock_x = 33 + 4 * len(wnum) + 1
        bar_static = render.Stack(children = bar_kids)

    # Sun rays: only on the crisp daytime sun, scaled by elevation so a low
    # sunrise/sunset sun is a short soft orb and a high midday sun beams. The
    # Off/Subtle/Bold mode sets ray count, base reach, and shimmer breadth.
    draw_rays = rays_mode != "off" and kind == "sun"

    # aurora is a night phenomenon: only paint it once the sun is down and the
    # sky isn't washed out by cloud/fog/smoke/precip (same conditions as stars)
    show_aurora = wx.aurora and not is_day and not (wx.clouds >= 3 or wx.fog or wx.smoke or wx.precip != None)
    ray_n, ray_base, ray_amp = 0, 0, 0
    orb = None
    orb_px, orb_py = 0, 0
    if draw_rays:
        ef = (elev - 5.0) / 50.0  # 0 near horizon -> 1 by ~55 degrees
        ef = 0.0 if ef < 0 else (1.0 if ef > 1 else ef)
        if rays_mode == "bold":
            ray_n = 16
            ray_base = 5 + _rnd(ef * 5)  # 5 (low orb) -> 10 (high beaming)
            ray_amp = 2
        else:  # subtle
            ray_n = 12
            ray_base = 3 + _rnd(ef * 3)  # 3 (low orb) -> 6 (high beaming)
            ray_amp = 1

        # low-sun warm orb: strongest at the horizon, gone by ~18 degrees
        og = (18.0 - elev) / 18.0
        og = 0.0 if og < 0 else (1.0 if og > 1 else og)
        if og > 0.04:
            orb = sunrise_orb_widget(og, rays_mode == "bold")
            outer = 15 if rays_mode == "bold" else 13
            orb_px = max(0, bx + 3 - outer // 2)  # center the orb on the sun disc
            orb_py = max(0, by + 3 - outer // 2)

    # severe alerts (level >= 2, i.e. an official NWS Severe/Extreme warning)
    # carry a real headline for the end-of-loop reveal; WrappedText does its
    # own wrapping, so just uppercase it (capped defensively -- it's an
    # external API field -- though real NWS event names are always short).
    alert_text = ""
    if wx.alert >= 2 and wx.alert_text != "":
        alert_text = wx.alert_text.upper()[:60]

    # seasonal tree: static trunk+crown built once; particles animate per
    # frame. At windy tier+ the crown leans 1px downwind; in winter wind the
    # twig tips leave the static widget and rattle in tree_tip_sway_layer.
    tree_lean = dx if tier >= 2 else 0
    winter_sway = wx.season == "winter" and tier >= 1
    tree = tree_widget(wx.season, tree_lean, winter_sway)

    # a low sun (or its foggy/smoky stand-in) sitting behind the tree: skip the
    # calm leaf drop -- a leaf fluttering through the disc and rays looks odd.
    # The body is 7x7 at (bx, by); pad ~4px for the ray reach, then test overlap
    # with the tree's airspace (x 0..9, y TREE_Y0..24).
    drop_ok = not (kind in ("sun", "ember", "glow") and bx <= 13 and by + 10 >= TREE_Y0 and by <= 28)

    # --- build animation frames ---
    frames = []
    for f in range(N_FRAMES):
        layers = [
            sky_background(palette),
            star_layer(f, star_bright),
        ]
        if show_aurora:
            layers.append(aurora_layer(f))
        if orb != None:
            layers.append(render.Padding(pad = (orb_px, orb_py, 0, 0), child = orb))
        if draw_rays:
            layers.append(sun_rays_layer(f, bx + 3, by + 3, ray_n, ray_base, ray_amp))
        if body != None:
            layers.append(render.Padding(pad = (bx, by, 0, 0), child = body))
        if wx.clouds > 0:
            layers.append(cloud_layer(f, cloud_plan, cloud_color, cloud_hi, cloud_wraps, lean, dx))
        if wx.precip != None:
            layers.append(precip_layer(f, wx.precip, wx.precip_level))
        if wx.heat_haze:
            layers.append(heat_haze_layer(f))
        layers.append(tree)
        if winter_sway:
            layers.append(tree_tip_sway_layer(f, tree_lean))
        elif tier >= 1:
            layers.append(tree_rustle_layer(f, wx.season, tree_lean))
        layers.append(tree_particle_layer(f, wx.season, tier, dx, drop_ok))
        if tier >= 2:
            layers.append(wind_streak_layer(f, tier, dx))
        if tier >= 3:
            layers.append(debris_layer(f, tier, dx))
        if tier >= 4:
            layers.append(hurricane_spiral_layer(f))
        if wx.tornado:
            layers.append(tornado_layer(f, dx))
        if wx.storm:
            layers.append(lightning_layer(f))
        if bar_static != None:
            layers.append(bar_static)
        if have_wind:
            layers.append(render.Padding(pad = (sock_x, 26, 0, 0), child = wind_flag(f, tier, dx, wind_mph)))
        if wx.alert > 0:
            layers.append(render.Padding(pad = (WIDTH - 8, 26, 0, 0), child = alert_badge(f, wx.alert)))
        if alert_text != "":
            layers.append(alert_reveal_layer(f, alert_text))
        frames.append(render.Stack(children = layers))

    return render.Root(
        delay = FRAME_DELAY,
        child = render.Animation(children = frames),
    )

def _demo_fields(demo_on):
    """Generated: reveal the simulator dials only when demo mode is on."""
    if demo_on != "true":
        return []
    return [
        schema.Dropdown(
            id = "demo_preset",
            name = "Preset",
            desc = "A one-click scene. Anything other than Custom overrides all the dials below.",
            icon = "wandMagicSparkles",
            default = "custom",
            options = [
                schema.Option(display = "Custom (use dials)", value = "custom"),
                schema.Option(display = "⛈ Thunderstorm", value = "thunderstorm"),
                schema.Option(display = "🌩 Night thunderstorm", value = "night_thunderstorm"),
                schema.Option(display = "❄ Blizzard", value = "blizzard"),
                schema.Option(display = "🌨 Gentle snow", value = "gentle_snow"),
                schema.Option(display = "🌧 Overcast drizzle", value = "overcast_drizzle"),
                schema.Option(display = "🌫 Foggy morning", value = "foggy_morning"),
                schema.Option(display = "🌅 Sunrise", value = "sunrise"),
                schema.Option(display = "🌇 Golden hour", value = "golden_hour"),
                schema.Option(display = "🔥 Heatwave", value = "heatwave"),
                schema.Option(display = "✨ Starry night", value = "starry_night"),
                schema.Option(display = "🌙 Crescent moon", value = "crescent_moon"),
                schema.Option(display = "🌕 Harvest moon", value = "harvest_moon"),
                schema.Option(display = "🌀 Hurricane", value = "hurricane"),
                schema.Option(display = "🌪 Tornado", value = "tornado"),
                schema.Option(display = "🧊 Ice storm", value = "ice_storm"),
                schema.Option(display = "🌨 Sleet", value = "sleet"),
                schema.Option(display = "🧊 Hail", value = "hailstorm"),
                schema.Option(display = "🔥 Wildfire smoke", value = "wildfire"),
                schema.Option(display = "🌌 Aurora", value = "aurora"),
            ],
        ),
        schema.Text(
            id = "demo_elev",
            name = "Sun elevation (°)",
            desc = "Sky look: -90 deep night, 0 horizon, 90 high noon. Ignored if lat+lng set below.",
            icon = "solidSun",
            default = "20",
        ),
        schema.Text(
            id = "demo_arc",
            name = "Arc position (0-100)",
            desc = "Where the sun/moon sits along its arc. 0 = left edge, 50 = top, 100 = right edge.",
            icon = "arrowsLeftRight",
            default = "50",
        ),
        schema.Text(
            id = "demo_phase",
            name = "Moon phase (0-100)",
            desc = "0 = new, 50 = full, 100 = new again. Visible when elevation is below 0.",
            icon = "moon",
            default = "50",
        ),
        schema.Dropdown(
            id = "demo_season",
            name = "Season (tree)",
            desc = "Auto follows a seasonal preset's implied season (blizzard = winter, heatwave = summer, ...) or else the Month dial below (Southern Hemisphere if a negative override latitude is set); pick one directly to preview it regardless of preset or month.",
            icon = "tree",
            default = "auto",
            options = [
                schema.Option(display = "Auto (from month)", value = "auto"),
                schema.Option(display = "🌸 Spring", value = "spring"),
                schema.Option(display = "☀️ Summer", value = "summer"),
                schema.Option(display = "🍂 Fall", value = "fall"),
                schema.Option(display = "❄️ Winter", value = "winter"),
            ],
        ),
        schema.Dropdown(
            id = "demo_clouds",
            name = "Cloud cover",
            desc = "How many clouds drift across.",
            icon = "cloud",
            default = "1",
            options = [
                schema.Option(display = "0 - clear", value = "0"),
                schema.Option(display = "1 - few", value = "1"),
                schema.Option(display = "2 - scattered", value = "2"),
                schema.Option(display = "3 - broken", value = "3"),
                schema.Option(display = "4 - overcast", value = "4"),
            ],
        ),
        schema.Text(
            id = "demo_cloud_seed",
            name = "Cloud arrangement",
            desc = "Changes which clouds/positions show (any number). Live, this shifts hourly.",
            icon = "shuffle",
            default = "0",
        ),
        schema.Dropdown(
            id = "demo_precip",
            name = "Precipitation",
            desc = "Falling rain, snow, ice (freezing rain), sleet, or hail.",
            icon = "cloudRain",
            default = "none",
            options = [
                schema.Option(display = "None", value = "none"),
                schema.Option(display = "Rain", value = "rain"),
                schema.Option(display = "Snow", value = "snow"),
                schema.Option(display = "Ice (freezing rain)", value = "ice"),
                schema.Option(display = "Sleet (ice pellets)", value = "sleet"),
                schema.Option(display = "Hail", value = "hail"),
            ],
        ),
        schema.Dropdown(
            id = "demo_precip_level",
            name = "Precip intensity",
            desc = "How hard it's coming down.",
            icon = "cloudShowersHeavy",
            default = "2",
            options = [
                schema.Option(display = "1 - light / drizzle", value = "1"),
                schema.Option(display = "2 - moderate", value = "2"),
                schema.Option(display = "3 - heavy / downpour", value = "3"),
            ],
        ),
        schema.Toggle(
            id = "demo_fog",
            name = "Fog",
            desc = "Drifting haze bands.",
            icon = "smog",
            default = False,
        ),
        schema.Toggle(
            id = "demo_smoke",
            name = "Wildfire smoke",
            desc = "Eerie orange smoke haze with a dim red sun.",
            icon = "fire",
            default = False,
        ),
        schema.Toggle(
            id = "demo_storm",
            name = "Lightning",
            desc = "Overlay a flashing lightning bolt (thunderstorm).",
            icon = "boltLightning",
            default = False,
        ),
        schema.Toggle(
            id = "demo_tornado",
            name = "Tornado",
            desc = "Drop a swaying funnel cloud from the sky to the ground.",
            icon = "tornado",
            default = False,
        ),
        schema.Toggle(
            id = "demo_aurora",
            name = "Aurora (night)",
            desc = "Shimmering green northern-lights curtains. Visible only at night with a clear sky.",
            icon = "wandSparkles",
            default = False,
        ),
        schema.Toggle(
            id = "demo_heat_haze",
            name = "Heat haze",
            desc = "Force the shimmer on, even if the dialed temp/sky wouldn't trigger it (it fires on its own at 90°F+ on a clear-enough day).",
            icon = "temperatureHigh",
            default = False,
        ),
        schema.Text(
            id = "demo_wind",
            name = "Wind speed",
            desc = "In the same units as temperature (mph / km/h). ~13 breeze, 25 windy, 39 gale, 55+ hurricane.",
            icon = "wind",
            default = "10",
        ),
        schema.Dropdown(
            id = "demo_wind_dir",
            name = "Wind direction",
            desc = "Which way it blows across the sky.",
            icon = "compass",
            default = "270",
            options = [
                schema.Option(display = "N", value = "0"),
                schema.Option(display = "NE", value = "45"),
                schema.Option(display = "E", value = "90"),
                schema.Option(display = "SE", value = "135"),
                schema.Option(display = "S", value = "180"),
                schema.Option(display = "SW", value = "225"),
                schema.Option(display = "W", value = "270"),
                schema.Option(display = "NW", value = "315"),
            ],
        ),
        schema.Dropdown(
            id = "demo_alert",
            name = "Severe-weather alert",
            desc = "Corner warning badge: storm approaching (yellow), severe (orange), extreme (red).",
            icon = "triangleExclamation",
            default = "0",
            options = [
                schema.Option(display = "None", value = "0"),
                schema.Option(display = "⚠ Storm approaching", value = "1"),
                schema.Option(display = "⚠ Severe", value = "2"),
                schema.Option(display = "⚠ Extreme", value = "3"),
            ],
        ),
        schema.Text(
            id = "demo_alert_text",
            name = "Alert headline",
            desc = "The advisory text revealed near the end of the loop when the alert is Severe or Extreme (mimics the real NWS event name).",
            icon = "commentDots",
            default = "Severe Thunderstorm Warning",
        ),
        schema.Text(
            id = "demo_temp",
            name = "Temperature readout",
            desc = "Number shown in the corner (needs Show temperature on).",
            icon = "temperatureHalf",
            default = "63",
        ),
        schema.Text(
            id = "demo_lat",
            name = "Override latitude",
            desc = "Real astronomy mode: fill BOTH lat and lng to compute the real sky for a place/season instead of the dials above.",
            icon = "locationDot",
            default = "",
        ),
        schema.Text(
            id = "demo_lng",
            name = "Override longitude",
            desc = "Used with override latitude.",
            icon = "locationDot",
            default = "",
        ),
        schema.Dropdown(
            id = "demo_month",
            name = "Month (season)",
            desc = "Season for real-astronomy mode.",
            icon = "calendar",
            default = "6",
            options = [
                schema.Option(display = "Jan", value = "1"),
                schema.Option(display = "Feb", value = "2"),
                schema.Option(display = "Mar", value = "3"),
                schema.Option(display = "Apr", value = "4"),
                schema.Option(display = "May", value = "5"),
                schema.Option(display = "Jun", value = "6"),
                schema.Option(display = "Jul", value = "7"),
                schema.Option(display = "Aug", value = "8"),
                schema.Option(display = "Sep", value = "9"),
                schema.Option(display = "Oct", value = "10"),
                schema.Option(display = "Nov", value = "11"),
                schema.Option(display = "Dec", value = "12"),
            ],
        ),
        schema.Text(
            id = "demo_hour",
            name = "Hour (0-23 UTC)",
            desc = "Time of day for real-astronomy mode.",
            icon = "clock",
            default = "12",
        ),
    ]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "The sky above this location.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "units",
                name = "Units",
                desc = "Temperature units.",
                icon = "temperatureHalf",
                default = "fahrenheit",
                options = [
                    schema.Option(display = "Fahrenheit", value = "fahrenheit"),
                    schema.Option(display = "Celsius", value = "celsius"),
                ],
            ),
            schema.Toggle(
                id = "show_temp",
                name = "Show temperature",
                desc = "Display the current temperature.",
                icon = "eye",
                default = True,
            ),
            schema.Toggle(
                id = "show_wind",
                name = "Show wind",
                desc = "Display wind speed + a fluttering flag on the bottom bar.",
                icon = "wind",
                default = True,
            ),
            schema.Dropdown(
                id = "weather_source",
                name = "Weather source",
                desc = "Auto uses real US station observations (NWS) when available, else Open-Meteo.",
                icon = "satelliteDish",
                default = "auto",
                options = [
                    schema.Option(display = "Auto (NWS in US, else Open-Meteo)", value = "auto"),
                    schema.Option(display = "NWS station obs (US only)", value = "nws"),
                    schema.Option(display = "Open-Meteo (global)", value = "openmeteo"),
                ],
            ),
            schema.Dropdown(
                id = "sun_rays",
                name = "Sun rays",
                desc = "Shimmering sunburst on clear days — short orb low, beaming high. Bold exaggerates it.",
                icon = "sun",
                default = "subtle",
                options = [
                    schema.Option(display = "Subtle", value = "subtle"),
                    schema.Option(display = "Bold", value = "bold"),
                    schema.Option(display = "Off", value = "off"),
                ],
            ),
            schema.Toggle(
                id = "demo_mode",
                name = "Demo / simulator mode",
                desc = "Override the real sky with manual dials to test every look.",
                icon = "flask",
                default = False,
            ),
            schema.Generated(
                id = "demo_generated",
                source = "demo_mode",
                handler = _demo_fields,
            ),
        ],
    )
