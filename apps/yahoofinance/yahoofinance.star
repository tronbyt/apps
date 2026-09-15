"""
Applet: YahooFinance
Summary: Track stock price
Description: Tracks a stock price and chart using free data from Yahoo Finance (no API key needed).
Author: petergCA
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "canvas", "render")
load("schema.star", "schema")

RANGE_INTERVALS = {
    "1d": "5m",
    "5d": "30m",
    "1mo": "1d",
    "3mo": "1d",
    "6mo": "1d",
    "1y": "1wk",
}

def main(config):
    symbol = config.get("symbol", "AAPL").upper().strip()
    select_range = config.get("select_range", "1d")
    ttl = int(config.get("ttl", "900"))
    color_profit = config.get("color_profit", "#00ff00")
    color_loss = config.get("color_loss", "#ff0000")

    interval = RANGE_INTERVALS.get(select_range, "5m")
    url = "https://query1.finance.yahoo.com/v8/finance/chart/{s}?range={r}&interval={i}&includePrePost=false".format(
        s = symbol,
        r = select_range,
        i = interval,
    )
    response = http.get(url, headers = {"User-Agent": "Mozilla/5.0"}, ttl_seconds = ttl)
    if response.status_code != 200:
        return error_view(symbol, "HTTP %d" % response.status_code)

    body = response.json()
    chart = body.get("chart", {})
    results = chart.get("result")
    if not results:
        return error_view(symbol, "NO DATA")

    result = results[0]
    meta = result.get("meta", {})
    quotes = result.get("indicators", {}).get("quote", [{}])[0]
    raw_closes = quotes.get("close") or []

    closes = []
    for c in raw_closes:
        if c != None:
            closes.append(float(c))

    last_price = meta.get("regularMarketPrice")
    if last_price == None:
        if not closes:
            return error_view(symbol, "NO DATA")
        last_price = closes[-1]
    last_price = float(last_price)

    previous_close = meta.get("chartPreviousClose")
    if previous_close == None:
        previous_close = closes[0] if closes else last_price
    previous_close = float(previous_close)

    if not closes:
        closes = [last_price]

    # chart values relative to previous close, like the stockdata app
    chart_data = []
    for i, c in enumerate(closes):
        chart_data.append((i, c - previous_close))
    if len(chart_data) == 1:
        chart_data.append((1, chart_data[0][1]))

    values = [p[1] for p in chart_data]
    y_min = min(values)
    y_max = max(values)
    if y_min == y_max:
        y_min -= 0.01
        y_max += 0.01

    change = last_price - previous_close
    pct = (change / previous_close) * 100 if previous_close != 0 else 0.0
    color_change = color_profit if change >= 0 else color_loss

    scale = 2 if canvas.is2x() else 1
    scaled_font = "terminus-16" if canvas.is2x() else "tb-8"

    return render.Root(
        render.Column(
            children = [
                render.Row(
                    children = [
                        cell(symbol, "#ffffff", 34, scale, scaled_font),
                        cell(humanize.float("#,###.##", change), color_change, 30, scale, scaled_font),
                    ],
                ),
                render.Row(
                    children = [
                        cell("$" + humanize.float("#,###.##", last_price), "#ffffff", 34, scale, scaled_font),
                        cell(humanize.float("#,###.##", pct) + "%", color_change, 30, scale, scaled_font),
                    ],
                ),
                render.Plot(
                    data = chart_data,
                    width = canvas.width(),
                    height = 16 * scale,
                    chart_type = "line",
                    color = color_profit,
                    fill_color = color_profit,
                    color_inverted = color_loss,
                    fill_color_inverted = color_loss,
                    y_lim = (y_min, y_max),
                    fill = True,
                ),
            ],
        ),
    )

def cell(content, color, width, scale, font):
    return render.Padding(
        render.Marquee(
            width = width * scale,
            child = render.Text(
                content = content,
                color = color,
                font = font,
            ),
            offset_start = 0,
            offset_end = 0,
        ),
        pad = (1 * scale, 0, 0, 0),
    )

def error_view(symbol, message):
    scaled_font = "terminus-16" if canvas.is2x() else "tb-8"
    return render.Root(
        render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(content = symbol, font = scaled_font),
                render.WrappedText(
                    font = scaled_font,
                    align = "center",
                    content = message,
                    color = "#ff0000",
                ),
            ],
        ),
    )

def get_schema():
    colors = [
        schema.Option(display = "White", value = "#ffffff"),
        schema.Option(display = "Red", value = "#ff0000"),
        schema.Option(display = "Yellow", value = "#ffff00"),
        schema.Option(display = "Lime", value = "#00ff00"),
        schema.Option(display = "Green", value = "#008000"),
        schema.Option(display = "Aqua", value = "#00ffff"),
        schema.Option(display = "Blue", value = "#0000ff"),
        schema.Option(display = "Fuchsia", value = "#ff00ff"),
        schema.Option(display = "Purple", value = "#800080"),
    ]
    ranges = [
        schema.Option(display = "1 day", value = "1d"),
        schema.Option(display = "5 days", value = "5d"),
        schema.Option(display = "1 month", value = "1mo"),
        schema.Option(display = "3 months", value = "3mo"),
        schema.Option(display = "6 months", value = "6mo"),
        schema.Option(display = "1 year", value = "1y"),
    ]
    ttls = [
        schema.Option(display = "5 minutes", value = "300"),
        schema.Option(display = "15 minutes", value = "900"),
        schema.Option(display = "30 minutes", value = "1800"),
        schema.Option(display = "1 hour", value = "3600"),
        schema.Option(display = "1 day", value = "86400"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "symbol",
                name = "Ticker symbol",
                desc = "The ticker symbol to display (e.g. AAPL)",
                icon = "sackDollar",
            ),
            schema.Dropdown(
                id = "select_range",
                name = "Time range",
                desc = "Chart time range",
                icon = "calendarDays",
                default = ranges[0].value,
                options = ranges,
            ),
            schema.Dropdown(
                id = "ttl",
                name = "Refresh interval",
                desc = "How often to fetch new data",
                icon = "clock",
                default = ttls[1].value,
                options = ttls,
            ),
            schema.Dropdown(
                id = "color_profit",
                name = "Profit color",
                desc = "Color when the price is up",
                icon = "brush",
                default = colors[3].value,
                options = colors,
            ),
            schema.Dropdown(
                id = "color_loss",
                name = "Loss color",
                desc = "Color when the price is down",
                icon = "brush",
                default = colors[1].value,
                options = colors,
            ),
        ],
    )
