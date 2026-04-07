"""
F1 Driver Standings for Tidbyt
===============================
Displays the current Formula 1 World Driver Championship standings,
scrolling through the top drivers on your Tidbyt display.

Settings:
  - update_timing: How quickly standings refresh after a race weekend
  - num_drivers:   How many drivers to show in the list
  - scroll_speed:  How fast the driver list scrolls (slow / medium / fast)

Data source: Jolpica F1 API (successor to Ergast)
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# ── API ───────────────────────────────────────────────────────────────────────
F1_API_URL = "https://api.jolpi.ca/ergast/f1/current/driverStandings.json"

# ── Cache TTLs (in seconds) ───────────────────────────────────────────────────
TTL_RIGHT_AFTER = 3600  # 1 hour  – picks up new results quickly after a race
TTL_DAY_AFTER = 86400  # 24 hours – refreshes once per day

# ── Colors ────────────────────────────────────────────────────────────────────
F1_RED = "#E10600"  # Official F1 red
WHITE = "#FFFFFF"
GREY = "#AAAAAA"
GOLD = "#FFD700"  # P1 highlight
SILVER = "#C0C0C0"  # P2 highlight
BRONZE = "#CD7F32"  # P3 highlight

# ── Font ──────────────────────────────────────────────────────────────────────
FONT = "CG-pixel-3x5-mono"  # Small pixel font (3×5 chars), fits lots on screen

# ── Scroll speeds (ms delay between animation frames — higher = slower) ───────
SPEED_SLOW = 150
SPEED_MEDIUM = 80
SPEED_FAST = 35

# ── Layout ────────────────────────────────────────────────────────────────────
HEADER_HEIGHT = 8  # px — fixed banner at the top
SCROLL_HEIGHT = 24  # px — remaining space for the scrolling driver list (32 - 8)

# ─────────────────────────────────────────────────────────────────────────────
# Data fetching
# ─────────────────────────────────────────────────────────────────────────────

def get_standings(ttl_seconds):
    """Fetch driver standings from the API, using cache to avoid repeat calls."""
    cache_key = "f1_driver_standings_v1"

    # Try cache first
    cached = cache.get(cache_key)
    if cached != None:
        return json.decode(cached)

    # Fetch from API
    resp = http.get(F1_API_URL, ttl_seconds = ttl_seconds)
    if resp.status_code != 200:
        print("F1 API error: status %d" % resp.status_code)
        return None

    data = resp.json()
    standings_lists = data.get("MRData", {}) \
        .get("StandingsTable", {}) \
        .get("StandingsLists", [])

    if len(standings_lists) == 0:
        print("F1 API: no standings data found (season may not have started)")
        return None

    standings = standings_lists[0].get("DriverStandings", [])
    cache.set(cache_key, json.encode(standings), ttl_seconds = ttl_seconds)
    return standings

# ─────────────────────────────────────────────────────────────────────────────
# Rendering helpers
# ─────────────────────────────────────────────────────────────────────────────

def position_color(pos_str):
    """Return a highlight color per position: gold / white / bronze / grey."""
    if pos_str == "1":
        return GOLD
    elif pos_str == "2":
        return WHITE
    elif pos_str == "3":
        return BRONZE
    return GREY

def driver_row(pos, code, pts):
    """Render a single driver row: position · code · points."""
    label = pos + ". " + code + " " + pts
    return render.Box(
        width = 64,
        height = 7,
        child = render.Padding(
            pad = (2, 1, 0, 0),
            child = render.Text(
                content = label,
                color = position_color(pos),
                font = FONT,
            ),
        ),
    )

def error_screen(message):
    """Fallback screen shown when data cannot be loaded."""
    return render.Root(
        child = render.Box(
            width = 64,
            height = 32,
            child = render.Column(
                children = [
                    render.Text("F1", color = F1_RED, font = "6x13"),
                    render.Text(message, color = GREY, font = FONT),
                ],
                main_align = "center",
                cross_align = "center",
                expanded = True,
            ),
        ),
    )

# ─────────────────────────────────────────────────────────────────────────────
# Main entry point
# ─────────────────────────────────────────────────────────────────────────────

def main(config):
    # Read settings (fall back to sensible defaults if not configured yet)
    update_timing = config.str("update_timing", "day_after")
    num_drivers = int(config.str("num_drivers", "5"))
    scroll_speed = config.str("scroll_speed", "medium")

    # Choose cache TTL based on user's preferred update timing
    ttl = TTL_DAY_AFTER if update_timing == "day_after" else TTL_RIGHT_AFTER

    # Choose frame delay based on scroll speed setting
    if scroll_speed == "slow":
        delay = SPEED_SLOW
    elif scroll_speed == "fast":
        delay = SPEED_FAST
    else:
        delay = SPEED_MEDIUM

    # Fetch standings
    standings = get_standings(ttl)
    if standings == None:
        return error_screen("No data")

    # ── Fixed header (stays pinned at the top, outside the scroll area) ──
    header = render.Box(
        width = 64,
        height = HEADER_HEIGHT,
        color = F1_RED,
        child = render.Text(
            content = "F1 STANDINGS",
            color = WHITE,
            font = FONT,
        ),
    )

    # ── Scrolling driver rows ──
    driver_rows = []
    count = num_drivers if num_drivers < len(standings) else len(standings)
    for i in range(count):
        d = standings[i]
        pos = d.get("position", str(i + 1))
        code = d.get("Driver", {}).get("code", "???")
        pts = d.get("points", "0")
        driver_rows.append(driver_row(pos, code, pts))

    # ── Assemble: fixed header on top, marquee below ──
    # offset_end=SCROLL_HEIGHT ensures the last row fully scrolls into view
    return render.Root(
        max_age = ttl,
        delay = delay,
        child = render.Column(
            children = [
                header,
                render.Marquee(
                    height = SCROLL_HEIGHT,
                    scroll_direction = "vertical",
                    offset_start = SCROLL_HEIGHT,
                    offset_end = SCROLL_HEIGHT,
                    child = render.Column(
                        children = driver_rows,
                    ),
                ),
            ],
        ),
    )

# ─────────────────────────────────────────────────────────────────────────────
# Schema (settings visible in the Tidbyt mobile app)
# ─────────────────────────────────────────────────────────────────────────────

def get_schema():
    timing_options = [
        schema.Option(display = "Day after race", value = "day_after"),
        schema.Option(display = "Right after race", value = "right_after"),
    ]

    driver_options = [
        schema.Option(display = "Top 3", value = "3"),
        schema.Option(display = "Top 5", value = "5"),
        schema.Option(display = "Top 10", value = "10"),
        schema.Option(display = "All drivers (20)", value = "20"),
    ]

    speed_options = [
        schema.Option(display = "Slow", value = "slow"),
        schema.Option(display = "Medium", value = "medium"),
        schema.Option(display = "Fast", value = "fast"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "update_timing",
                name = "Update Timing",
                desc = "How soon after a race weekend to refresh the standings.",
                icon = "clock",
                default = timing_options[0].value,
                options = timing_options,
            ),
            schema.Dropdown(
                id = "num_drivers",
                name = "Drivers to Show",
                desc = "How many drivers to scroll through on your display.",
                icon = "listOl",
                default = driver_options[1].value,
                options = driver_options,
            ),
            schema.Dropdown(
                id = "scroll_speed",
                name = "Scroll Speed",
                desc = "How fast the driver list scrolls across your display.",
                icon = "gauge",
                default = speed_options[1].value,
                options = speed_options,
            ),
        ],
    )
