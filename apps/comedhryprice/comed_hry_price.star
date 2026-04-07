"""
ComEd 5-Minute Energy Pricing — Tidbyt App
Author: SecurePath / Adam
Description:
    Displays the current 5-minute spot price from ComEd's Hourly Pricing API.
    Color-codes the price: green (cheap), yellow (moderate), red (expensive).
    Also shows a mini sparkline of the last 12 readings (~1 hour of data).

API used:
    https://hourlypricing.comed.com/api?type=5minutefeed&format=json
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# ── constants ──────────────────────────────────────────────────────────────────
API_URL = "https://hourlypricing.comed.com/api?type=5minutefeed&format=json"
CACHE_KEY = "comed_5min_feed"
CACHE_TTL = 270  # seconds — refresh every ~4.5 min, data updates every 5 min
SPARKLINE_BARS = 12  # last 12 readings ≈ 1 hour

# price thresholds in ¢/kWh
THRESH_LOW = 3.0  # ≤ low  → green
THRESH_MED = 8.0  # ≤ med  → yellow  (> med → red)

# display colours
COLOR_GREEN = "#00C800"
COLOR_YELLOW = "#FFD700"
COLOR_RED = "#FF3C00"
COLOR_LABEL = "#9AAABF"
COLOR_UNIT = "#7F8FA6"
COLOR_BG = "#0A0F1E"

# ── helpers ────────────────────────────────────────────────────────────────────
def price_color(price_float):
    if price_float <= THRESH_LOW:
        return COLOR_GREEN
    elif price_float <= THRESH_MED:
        return COLOR_YELLOW
    else:
        return COLOR_RED

def format_price(price_float):
    """Format a float to one decimal place as a string, e.g. 4.2"""
    whole = int(price_float)
    decimal = int((price_float - whole) * 10)
    return "%d.%d" % (whole, decimal)

def fetch_prices():
    cached = cache.get(CACHE_KEY)
    if cached != None:
        return json.decode(cached)

    resp = http.get(API_URL)
    if resp.status_code != 200:
        return None

    raw = resp.json()
    if raw == None or len(raw) == 0:
        return None

    prices = []
    for entry in raw:
        prices.append(float(entry["price"]))

    cache.set(CACHE_KEY, json.encode(prices), ttl_seconds = CACHE_TTL)
    return prices

def render_sparkline(prices, bar_count, width, height, current_color):
    sample = prices[:bar_count]
    sample = sample[::-1]

    if len(sample) == 0:
        return render.Box(width = width, height = height)

    lo = sample[0]
    hi = sample[0]
    for p in sample:
        if p < lo:
            lo = p
        if p > hi:
            hi = p

    price_range = hi - lo
    if price_range == 0:
        price_range = 1.0

    bar_width = int(width / bar_count)
    bar_gap = 1
    usable_w = bar_width - bar_gap if bar_width > 1 else 1

    bars = []
    for i, p in enumerate(sample):
        norm = (p - lo) / price_range
        bar_h = int(norm * (height - 1)) + 1
        bar_color = current_color if i == len(sample) - 1 else "#3A4A6A"

        bar = render.Padding(
            pad = (i * bar_width, height - bar_h, 0, 0),
            child = render.Box(
                width = usable_w,
                height = bar_h,
                color = bar_color,
            ),
        )
        bars.append(bar)

    return render.Stack(children = bars)

# ── schema ─────────────────────────────────────────────────────────────────────
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )

# ── main ───────────────────────────────────────────────────────────────────────
def main(_):
    prices = fetch_prices()

    if prices == None or len(prices) == 0:
        return render.Root(
            child = render.Box(
                color = COLOR_BG,
                child = render.Column(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Text("ComEd", color = COLOR_LABEL, font = "CG-pixel-3x5-mono"),
                        render.Text("No Data", color = COLOR_RED, font = "6x13"),
                    ],
                ),
            ),
        )

    current_price = prices[0]
    price_str = format_price(current_price)
    color = price_color(current_price)
    spark = render_sparkline(prices, SPARKLINE_BARS, 64, 10, color)

    return render.Root(
        child = render.Box(
            color = COLOR_BG,
            child = render.Column(
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Row(
                        main_align = "space_between",
                        cross_align = "center",
                        expanded = True,
                        children = [
                            render.Padding(
                                pad = (2, 0, 0, 0),
                                child = render.Text(
                                    content = "ComEd",
                                    color = COLOR_LABEL,
                                    font = "CG-pixel-3x5-mono",
                                ),
                            ),
                            render.Padding(
                                pad = (0, 0, 2, 0),
                                child = render.Text(
                                    content = "¢/kWh",
                                    color = COLOR_UNIT,
                                    font = "CG-pixel-3x5-mono",
                                ),
                            ),
                        ],
                    ),
                    render.Text(
                        content = price_str,
                        color = color,
                        font = "6x13",
                    ),
                    render.Padding(
                        pad = (2, 0, 2, 2),
                        child = render.Box(
                            width = 60,
                            height = 10,
                            child = spark,
                        ),
                    ),
                ],
            ),
        ),
    )
