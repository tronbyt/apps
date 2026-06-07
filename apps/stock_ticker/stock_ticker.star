load("render.star", "render")
load("http.star", "http")
load("schema.star", "schema")

CHART_WIDTH = 52
CHART_HEIGHT = 16
TRADING_MINUTES = 390

INDEX_NAMES = {
    "^DJI": "DOW",
    "^GSPC": "S&P",
    "^IXIC": "NDQ",
    "^RUT": "RUT",
}

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "symbol",
                name = "Ticker Symbol",
                desc = "Stock or index ticker (e.g. AAPL, ^GSPC, ^DJI, ^IXIC, ^RUT)",
                icon = "chartLine",
                default = "SPOT",
            ),
        ],
    )

def add_commas(s):
    n = len(s)
    result = ""
    for i in range(n):
        if i > 0 and (n - i) % 3 == 0:
            result += ","
        result += s[i]
    return result

def fmt_float(val, decimals):
    negative = val < 0
    val = -val if negative else val
    factor = 10 if decimals == 1 else 100
    rounded = int(val * factor + 0.5)
    whole = rounded // factor
    frac = rounded % factor
    frac_str = str(frac)
    if len(frac_str) < decimals:
        frac_str = "0" + frac_str
    if len(frac_str) < decimals:
        frac_str = "0" + frac_str
    result = "%s.%s" % (add_commas(str(whole)), frac_str)
    if negative:
        result = "-" + result
    return result

def main(config):
    symbol = (config.get("symbol") or "SPOT").upper().strip()
    is_index = symbol.startswith("^")
    display_name = INDEX_NAMES.get(symbol) or symbol
    url = "https://query1.finance.yahoo.com/v8/finance/chart/%s?interval=5m&range=1d" % symbol

    rep = http.get(url, headers = {"User-Agent": "Mozilla/5.0"}, ttl_seconds = 300)
    if rep.status_code != 200:
        return error_screen(display_name, "HTTP %d" % rep.status_code)

    data = rep.json()
    results = (data.get("chart") or {}).get("result") or []
    if not results:
        return error_screen(display_name, "no data")

    result = results[0]
    meta = result["meta"]
    price = meta["regularMarketPrice"]
    prev = meta.get("previousClose") or meta.get("chartPreviousClose") or price
    change = price - prev
    pct = (change / prev) * 100

    sign = "+" if change >= 0 else "-"
    abs_change = change if change >= 0 else -change
    abs_pct = pct if pct >= 0 else -pct
    change_color = "#00DD55" if change >= 0 else "#FF4444"
    fill_color = "#004418" if change >= 0 else "#3D0000"

    if is_index:
        price_str = fmt_float(price, 2)
        change_str = "%s%s" % (sign, fmt_float(abs_change, 2))
    else:
        price_str = "$%s" % fmt_float(price, 2)
        change_str = "%s$%s" % (sign, fmt_float(abs_change, 2))

    pct_str = "%s%s%%" % (sign, fmt_float(abs_pct, 1))

    timestamps = result.get("timestamp") or []
    quotes = ((result.get("indicators") or {}).get("quote") or [{}])[0]
    closes = quotes.get("close") or []

    market_open_ts = timestamps[0] if timestamps else None

    plot_data = []
    if market_open_ts and timestamps and closes:
        for i in range(len(timestamps)):
            if i < len(closes) and closes[i] != None:
                x = (timestamps[i] - market_open_ts) / 60
                if x >= 0 and x <= TRADING_MINUTES:
                    plot_data.append((x, closes[i]))

    if len(plot_data) > 1:
        y_vals = [pt[1] for pt in plot_data]
        y_min_val = y_vals[0]
        y_max_val = y_vals[0]
        for v in y_vals:
            if v < y_min_val:
                y_min_val = v
            if v > y_max_val:
                y_max_val = v
        y_margin = (y_max_val - y_min_val) * 0.1
        if y_margin == 0:
            y_margin = y_min_val * 0.002
        y_lim = (y_min_val - y_margin, y_max_val + y_margin)

        chart = render.Row(
            children = [
                render.Box(width = 6, height = CHART_HEIGHT),
                render.Plot(
                    data = plot_data,
                    width = CHART_WIDTH,
                    height = CHART_HEIGHT,
                    color = change_color,
                    fill_color = fill_color,
                    x_lim = (0, TRADING_MINUTES),
                    y_lim = y_lim,
                    fill = True,
                ),
                render.Box(width = 6, height = CHART_HEIGHT),
            ],
        )
    else:
        chart = render.Box(width = 64, height = CHART_HEIGHT)

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Text(content = display_name, color = "#FFFFFF", font = "tb-8"),
                        render.Text(content = change_str, color = change_color, font = "tb-8"),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Text(content = price_str, color = "#FFFFFF", font = "tb-8"),
                        render.Text(content = pct_str, color = change_color, font = "tb-8"),
                    ],
                ),
                chart,
            ],
        ),
    )

def error_screen(display_name, msg):
    return render.Root(
        child = render.Column(
            children = [
                render.Text(content = display_name, color = "#FFFFFF", font = "tb-8"),
                render.Text(content = "error", color = "#FF4444", font = "tb-8"),
                render.Text(content = msg, color = "#888888", font = "tb-8"),
            ],
        ),
    )
