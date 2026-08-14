"""
Applet: Lake Lanier Level
Summary: Lake Lanier water levels
Description: Live Lake Lanier water level relative to full pool, with alert-zone colors, trend, water temp, and a scrolling ticker.
Author: jspeigner
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# ── API ──────────────────────────────────────────────────────────────
API_BASE = "https://attrhlvatssgurlriewu.supabase.co/functions/v1/water-level-api"

# Public anon key — safe to embed in client apps per the Lanier Level docs.
# Row Level Security enforces read-only public access.
ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF0dHJobHZhdHNzZ3VybHJpZXd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc0Mjk3NDgsImV4cCI6MjA3MzAwNTc0OH0._CZ809RYQ9AVbovN6-bv-SH762FIopprd0dqkftFhT8"

# API refreshes hourly; cache 10 min to play nice with the app cycle.
CACHE_TTL = 600
DEFAULT_TIMEZONE = "America/New_York"

# ── Palette ──────────────────────────────────────────────────────────
WATER_DARK = "#3F4F2C"
COLOR_DIM = "#444444"
COLOR_MIDDIM = "#666666"
COLOR_CYAN = "#33CCDD"
COLOR_YELLOW = "#FFCC33"
COLOR_WHITE = "#EEEEEE"
COLOR_GREEN = "#3DDD66"
COLOR_RED = "#FF3344"
COLOR_AMBER = "#FF9933"
COLOR_BLUE = "#3399EE"
COLOR_BLACK = "#000000"

# ── Geometry ─────────────────────────────────────────────────────────
WAVE_FRAMES = 8  # frames in the wave loop (~0.8 s @ 100 ms)
WAVE_TOP = 14  # first row of the water window
BOTTOM_BAND_Y = 23  # first row of the divider/ticker/zone band

# ── Data fetch ───────────────────────────────────────────────────────
def fetch_latest():
    resp = http.get(
        API_BASE + "?endpoint=latest",
        headers = {
            "apikey": ANON_KEY,
            "Authorization": "Bearer " + ANON_KEY,
        },
        ttl_seconds = CACHE_TTL,
    )
    if resp.status_code != 200:
        return None
    body = resp.json()
    if not body or not body.get("data"):
        return None
    return body["data"]

# ── Helpers ──────────────────────────────────────────────────────────
def zone_color(diff):
    if diff > 0:
        return COLOR_BLUE  # above full pool
    if diff > -1:
        return COLOR_GREEN  # within 1 ft
    if diff > -3:
        return COLOR_YELLOW  # 1–3 ft below
    if diff > -6:
        return COLOR_AMBER  # 3–6 ft below
    return COLOR_RED  # > 6 ft below

def trend_color(trend):
    if trend == "up":
        return COLOR_GREEN
    return COLOR_RED

def fmt_diff(v):
    neg = v < 0
    abs_v = -v if neg else v
    whole = int(abs_v)
    frac = int(abs_v * 100 + 0.5) % 100
    frac_str = "%d" % frac
    if len(frac_str) < 2:
        frac_str = "0" + frac_str
    if neg:
        return "-%d.%s" % (whole, frac_str)
    return "+%d.%s" % (whole, frac_str)

def get_timezone(config):
    loc = config.get("location")
    if loc:
        return json.decode(loc)["timezone"]
    return DEFAULT_TIMEZONE

def fmt_time(iso, timezone):
    if not iso:
        return "--"
    t = time.parse_time(iso)
    return t.in_location(timezone).format("3:04PM").replace("AM", "A").replace("PM", "P")

# ── Wave layer ───────────────────────────────────────────────────────
def wave_column(x, t, accent):
    """One 1×9 column: transparent sky on top, accent surface pixel, dark body."""
    wave = math.sin(x * 0.35 + t * 1.6) * 1.1 + math.sin(x * 0.18 - t * 1.0) * 0.6
    surf = int(2.0 + wave + 0.5)
    if surf < 0:
        surf = 0
    if surf > 8:
        surf = 8
    body = 9 - surf

    parts = []
    if surf > 0:
        parts.append(render.Box(width = 1, height = surf))  # transparent
    parts.append(render.Box(width = 1, height = 1, color = accent))
    if body > 1:
        parts.append(render.Box(width = 1, height = body - 1, color = WATER_DARK))
    return render.Column(children = parts)

def wave_frame(t, accent):
    return render.Row(children = [wave_column(x, t, accent) for x in range(64)])

# ── Zone bar (bottom row, 1px tall) ──────────────────────────────────
def zone_bar():
    cells = []
    for x in range(64):
        frac = float(x) / 63.0
        if frac < 0.15:
            c = "#552222"
        elif frac < 0.50:
            c = "#553311"
        elif frac < 0.85:
            c = "#225522"
        else:
            c = "#223355"
        cells.append(render.Box(width = 1, height = 1, color = c))
    return render.Row(children = cells)

# ── Dotted divider row ───────────────────────────────────────────────
def dotted_divider():
    cells = []
    for x in range(64):
        c = COLOR_DIM if x % 2 == 0 else COLOR_BLACK
        cells.append(render.Box(width = 1, height = 1, color = c))
    return render.Row(children = cells)

# ── Main ─────────────────────────────────────────────────────────────
def main(config):
    data = fetch_latest()
    if not data:
        return []

    animate = config.bool("animate", True)
    show_ticker = config.bool("show_ticker", True)

    diff = float(data.get("feet_above_full") or 0.0)
    trend = data.get("trend") or "down"
    temp_raw = data.get("water_temp_f")
    updated_iso = data.get("usgs_timestamp") or data.get("created_at") or ""
    timezone = get_timezone(config)

    accent = zone_color(diff)
    tc = trend_color(trend)
    diff_str = fmt_diff(diff)
    temp_str = ("%dF" % int(temp_raw + 0.5)) if temp_raw != None else ""
    updated = fmt_time(updated_iso, timezone)

    # ── Water (positioned at row 14); optional ripple ────────────────
    if animate:
        water_child = render.Animation(children = [
            wave_frame(f * 0.18, accent)
            for f in range(WAVE_FRAMES)
        ])
    else:
        water_child = wave_frame(0, accent)
    water_layer = render.Padding(pad = (0, WAVE_TOP, 0, 0), child = water_child)

    # ── Header (rows 0-4): LANIER · temp ─────────────────────────────
    header = render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "start",
        children = [
            render.Text("LANIER", font = "CG-pixel-3x5-mono", color = COLOR_CYAN),
            render.Text(temp_str, font = "CG-pixel-3x5-mono", color = COLOR_YELLOW),
        ],
    )

    # ── Hero row (rows 7-13): -5.28 FT centered ──────────────────────
    hero = render.Row(
        expanded = True,
        main_align = "center",
        cross_align = "end",
        children = [
            render.Text(diff_str, font = "tb-8", color = tc),
            render.Box(width = 2, height = 1),
            render.Padding(
                pad = (0, 0, 0, 1),
                child = render.Text("FT", font = "CG-pixel-3x5-mono", color = COLOR_MIDDIM),
            ),
        ],
    )

    text_overlay = render.Column(children = [
        header,
        render.Box(width = 64, height = 1),
        hero,
    ])

    # ── Bottom band (rows 23-31): divider · ticker · zone bar ────────
    ticker_pieces = ["LAKE LANIER", " " + diff_str + " FT FROM FULL"]
    if temp_str:
        ticker_pieces.append(" WATER " + temp_str)
    ticker_pieces.append(" UPDATED " + updated)
    ticker_text = "  ·  ".join(ticker_pieces) + "  ·  "

    if show_ticker:
        ticker_row = render.Marquee(
            width = 64,
            child = render.Text(
                ticker_text,
                font = "CG-pixel-3x5-mono",
                color = COLOR_WHITE,
            ),
        )
    else:
        ticker_row = render.Row(
            expanded = True,
            main_align = "center",
            children = [
                render.Text(
                    "UPDATED " + updated,
                    font = "CG-pixel-3x5-mono",
                    color = COLOR_WHITE,
                ),
            ],
        )

    bottom = render.Column(children = [
        render.Box(width = 64, height = BOTTOM_BAND_Y),  # transparent spacer
        dotted_divider(),
        render.Box(width = 64, height = 1),
        ticker_row,
        render.Box(width = 64, height = 1),
        zone_bar(),
    ])

    stack = render.Stack(children = [
        water_layer,
        text_overlay,
        bottom,
    ])
    if animate or show_ticker:
        return render.Root(delay = 100, child = stack)
    return render.Root(child = stack)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Timezone used for the last-update time in the ticker.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "animate",
                name = "Animate waves",
                desc = "Ripple the water surface. Turn off for a static display.",
                icon = "water",
                default = True,
            ),
            schema.Toggle(
                id = "show_ticker",
                name = "Scrolling ticker",
                desc = "Scroll extra status text. Off shows only the last-update time.",
                icon = "textWidth",
                default = True,
            ),
        ],
    )
