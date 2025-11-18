"""
Applet: StockData
Summary: Track stock price
Description: Allows you to track stock prices (intraday, week, or month) using data from stockdata.org.
Author: ingmarstein
"""

load("demo_response_eod.json", DEMO_RESPONSE_EOD = "file")
load("demo_response_intraday.json", DEMO_RESPONSE_INTRADAY = "file")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/stockdata_logo.png", STOCKDATA_LOGO_IMAGE = "file")
load("re.star", "re")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

API_FIELDS = {
    "stockdata": {
        "data": "data",
        "date": "date",
        "meta": "meta",
        "open": "open",
        "close": "close",
        "data_order_asc": True,
        "time_format_intraday": "2006-01-02T15:04:05Z07:00",
        "time_format_eod": "2006-01-02T15:04:05Z07:00",
    },
    "apistocks": {
        "data": "Results",
        "date": "Date",
        "meta": "Metadata",
        "open": "Open",
        "close": "Close",
        "data_order_asc": False,
        "time_format_intraday": "2006-01-02 15:04",
        "time_format_eod": "2006-01-02",
    },
}

def main(config):
    api_token = config.get("api_token")
    symbol = config.get("symbol")
    select_period = int(config.get("select_period", "1"))
    missing_parameter = check_inputs(api_token, symbol)
    extended_hours = config.bool("extended_hours", False)
    color_profit = get_preferences(config)
    ttl = int(config.get("ttl", "86400"))
    query_type = config.get("query_type", "intraday")
    provider = config.get("provider", "stockdata")
    if missing_parameter:
        symbol = "AAPL"
        provider = "stockdata"
        if query_type == "intraday":
            data_raw = json.decode(DEMO_RESPONSE_INTRADAY.readall())
        else:
            data_raw = json.decode(DEMO_RESPONSE_EOD.readall())
    else:
        if provider == "stockdata":
            data_raw, status_code = make_stockdata_request(query_type, api_token, symbol, extended_hours, select_period, ttl)
        else:
            data_raw, status_code = make_apistocks_request(query_type, api_token, symbol, select_period, ttl)
        if status_code != 200:
            return error_view(str(status_code))

    return get_data_select_period(data_raw, provider, query_type, color_profit, select_period, symbol)

def check_inputs(api_token, symbol):
    missing_parameter = None
    if not api_token:
        missing_parameter = "Missing API Token"
        return missing_parameter
    elif not symbol:
        missing_parameter = "Missing ticker symbol"
        return missing_parameter
    return missing_parameter

def error_view(message):
    scale = 2 if canvas.is2x() else 1
    return render.Root(
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = STOCKDATA_LOGO_IMAGE.readall(), width = 32 * scale, height = 32 * scale),
                render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.WrappedText(
                            font = "terminus-16" if canvas.is2x() else "tb-8",
                            align = "center",
                            content = message.upper(),
                        ),
                    ],
                ),
            ],
        ),
    )

def display_price_change(last_price, previous_last_price):
    difference = last_price - previous_last_price
    return humanize.float("#,###.##", difference)

def display_percentage_change(last_price, previous_last_price):
    difference = last_price - previous_last_price
    difference_percentage = (difference / previous_last_price) * 100
    return humanize.float("#,###.##", difference_percentage)

def get_data_select_period(response, provider, query_type, colors, select_period, symbol):
    scale = 2 if canvas.is2x() else 1
    scaled_font = "terminus-16" if canvas.is2x() else "tb-8"
    data = response[API_FIELDS[provider]["data"]]

    if not API_FIELDS[provider]["data_order_asc"]:
        data = reversed(data)

    time_format = API_FIELDS[provider]["time_format_%s" % query_type]
    start_date = time.parse_time(data[0][API_FIELDS[provider]["date"]], time_format)
    start_date = time.parse_time(start_date.format("2006-01-02"), "2006-01-02")
    start_date -= (select_period - 1) * 24 * time.hour

    list_data = []
    previous_last_price = None
    for entry in data:
        if "data" in entry:
            record = entry["data"]
        else:
            record = entry
        if time.parse_time(entry[API_FIELDS[provider]["date"]], time_format) < start_date:
            previous_last_price = record[API_FIELDS[provider]["close"]]
            break
        list_data.append(record)

    list_data = reversed(list_data)

    # If we don't know the previous close (e.g. because we display the full time
    # range like 7 days of intraday data), compare against the first open.
    if not previous_last_price:
        previous_last_price = list_data[0][API_FIELDS[provider]["open"]]

    prices = []
    for entry in list_data:
        value = entry[API_FIELDS[provider]["close"]] - previous_last_price
        prices.append(value)

    min_price = min(prices)
    max_price = max(prices)
    last_price = list_data[-1][API_FIELDS[provider]["close"]]

    # Print the entire last price data line
    last_data_entry = list_data[-1]

    chart_data = []
    i = 0
    for p in prices:
        chart_data.append((i, p))
        i += 1

    price_change = display_price_change(last_price, previous_last_price)
    pattern_symbol = r"[^.]*"
    symbol = re.findall(pattern_symbol, symbol)
    symbol = symbol[0]

    color_price_change = colors[0]
    if float(price_change) < 0:
        color_price_change = colors[1]

    return render.Root(
        render.Column(
            children = [
                render.Column(
                    children = [
                        render.Row(
                            children = [
                                render.Padding(
                                    render.Marquee(
                                        width = 34 * scale,
                                        child = render.Text(
                                            content = symbol,
                                            offset = 0,
                                            font = scaled_font,
                                        ),
                                        offset_start = 0,
                                        offset_end = 0,
                                    ),
                                    pad = (1 * scale, 0, 0, 0),
                                ),
                                render.Padding(
                                    render.Marquee(
                                        width = 30 * scale,
                                        child = render.Text(
                                            content = price_change,
                                            color = color_price_change,
                                            offset = 0,
                                            font = scaled_font,
                                        ),
                                        offset_start = 0,
                                        offset_end = 0,
                                    ),
                                    pad = (1 * scale, 0, 0, 0),
                                ),
                            ],
                        ),
                        render.Row(
                            children = [
                                render.Padding(
                                    render.Marquee(
                                        width = 34 * scale,
                                        child = render.Text(
                                            content = "$" + humanize.float("#,###.##", last_price),
                                            offset = 1,
                                            font = scaled_font,
                                        ),
                                        offset_start = 1,
                                        offset_end = 0,
                                    ),
                                    pad = (1 * scale, 0, 0, 0),
                                ),
                                render.Padding(
                                    render.Marquee(
                                        width = 30 * scale,
                                        child = render.Text(
                                            content = display_percentage_change(last_price, previous_last_price) + "%",
                                            color = color_price_change,
                                            offset = 1,
                                            font = scaled_font,
                                        ),
                                        offset_start = 0,
                                        offset_end = 0,
                                    ),
                                    pad = (1 * scale, 0, 0, 0),
                                ),
                            ],
                        ),
                    ],
                ),
                render.Plot(
                    data = chart_data,
                    width = canvas.width(),
                    height = 16 * scale,
                    chart_type = "line",
                    color = colors[0],
                    fill_color = colors[0],
                    color_inverted = colors[1],
                    fill_color_inverted = colors[1],
                    y_lim = (min_price, max_price),
                    fill = True,
                ),
            ],
        ),
    )

def get_schema():
    options = [
        schema.Option(display = "White", value = "#ffffff"),
        schema.Option(display = "Silver", value = "#c0c0c0"),
        schema.Option(display = "Gray", value = "#808080"),
        schema.Option(display = "Red", value = "#ff0000"),
        schema.Option(display = "Maroon", value = "#800000"),
        schema.Option(display = "Yellow", value = "#ffff00"),
        schema.Option(display = "Olive", value = "#808000"),
        schema.Option(display = "Lime", value = "#00ff00"),
        schema.Option(display = "Green", value = "#008000"),
        schema.Option(display = "Aqua", value = "#00ffff"),
        schema.Option(display = "Teal", value = "#008080"),
        schema.Option(display = "Blue", value = "#0000ff"),
        schema.Option(display = "Navy", value = "#000080"),
        schema.Option(display = "Fuchsia", value = "#ff00ff"),
        schema.Option(display = "Purple", value = "#800080"),
    ]
    days = [
        schema.Option(
            display = "1",
            value = "1",
        ),
        schema.Option(
            display = "5",
            value = "5",
        ),
        schema.Option(
            display = "15",
            value = "15",
        ),
        schema.Option(
            display = "30",
            value = "30",
        ),
        schema.Option(
            display = "45",
            value = "45",
        ),
        schema.Option(
            display = "60",
            value = "60",
        ),
        schema.Option(
            display = "100",
            value = "100",
        ),
        schema.Option(
            display = "180",
            value = "180",
        ),
    ]
    query_type = [
        schema.Option(
            display = "Intraday",
            value = "intraday",
        ),
        schema.Option(
            display = "Historical Data (end-of-day close)",
            value = "eod",
        ),
    ]
    query = [
        schema.Option(
            display = "1 minute",
            value = "60",
        ),
        schema.Option(
            display = "5 minutes",
            value = "300",
        ),
        schema.Option(
            display = "10 minutes",
            value = "600",
        ),
        schema.Option(
            display = "15 minutes",
            value = "900",
        ),
        schema.Option(
            display = "30 minutes",
            value = "1800",
        ),
        schema.Option(
            display = "1 hour",
            value = "3600",
        ),
        schema.Option(
            display = "2 hours",
            value = "7200",
        ),
        schema.Option(
            display = "1 day",
            value = "86400",
        ),
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
            schema.Text(
                id = "api_token",
                name = "API Token",
                desc = "The API token",
                icon = "key",
                secret = True,
            ),
            schema.Dropdown(
                id = "provider",
                name = "Data provider",
                desc = "API",
                icon = "database",
                default = "stockdata",
                options = [
                    schema.Option(
                        display = "stockdata.org",
                        value = "stockdata",
                    ),
                    schema.Option(
                        display = "apistocks.com",
                        value = "apistocks",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "select_period",
                name = "Time range",
                desc = "Number of days to show",
                icon = "calendarDays",
                default = days[0].value,
                options = days,
            ),
            schema.Dropdown(
                id = "ttl",
                name = "Time to refresh ",
                desc = "Time to refresh data",
                icon = "clock",
                default = query[5].value,
                options = query,
            ),
            schema.Dropdown(
                id = "query_type",
                name = "Data type",
                desc = "Request intraday or historical data",
                icon = "clipboardQuestion",
                default = query_type[0].value,
                options = query_type,
            ),
            schema.Toggle(
                id = "extended_hours",
                name = "Extended hours",
                desc = "Show extended trading hours (StockData only)",
                icon = "plugCircleBolt",
                default = False,
            ),
            schema.Dropdown(
                id = "color_profit",
                name = "Profit Color",
                desc = "The fill color for profits",
                icon = "brush",
                default = options[7].value,
                options = options,
            ),
            schema.Dropdown(
                id = "color_loss",
                name = "Loss color",
                desc = "The fill color for losses",
                icon = "brush",
                default = options[3].value,
                options = options,
            ),
        ],
    )

def get_preferences(config):
    colors = []
    color_regex = r"#[a-zA-Z0-9]{6}"
    chart_color_profit = re.findall(color_regex, config.get("color_profit") or "")
    chart_color_loss = re.findall(color_regex, config.get("color_loss") or "")
    chart_color_profit = chart_color_profit[0] if chart_color_profit else "#008000"
    chart_color_loss = chart_color_loss[0] if chart_color_loss else "#ff0000"
    colors.append(chart_color_profit)
    colors.append(chart_color_loss)
    return colors

def make_stockdata_request(query_type, api_token, symbol, extended_hours, select_period, ttl):
    if query_type == "eod":
        interval = "day"
    elif select_period > 7:
        interval = "hour"
    else:
        interval = "minute"

    url = "https://api.stockdata.org/v1/data/{endpoint}?api_token={token}&symbols={symbol}&interval={interval}".format(
        endpoint = query_type,
        token = api_token,
        symbol = symbol,
        interval = interval,
    )
    if query_type == "intraday":
        if extended_hours:
            url += "&extended_hours=true"
        else:
            url += "&extended_hours=false"

    response = http.get(url, ttl_seconds = ttl)
    if response.status_code != 200:
        return None, response.status_code

    return response.json(), 200

def make_apistocks_request(query_type, api_token, symbol, select_period, ttl):
    if query_type == "eod":
        query_type = "daily"

    url = "https://apistocks.p.rapidapi.com/{endpoint}?symbol={symbol}".format(
        endpoint = query_type,
        symbol = symbol,
    )
    if query_type == "daily":
        date_end = time.now().in_location("America/New_York")
        date_start = date_end - select_period * 24 * time.hour
        url += "&dateStart=%s&dateEnd=%s" % (date_start.format("2006-01-02"), date_end.format("2006-01-02"))

    headers = {
        "x-rapidapi-host": "apistocks.p.rapidapi.com",
        "x-rapidapi-key": api_token,
    }
    response = http.get(url, headers = headers, ttl_seconds = ttl)
    if response.status_code != 200:
        return None, response.status_code

    return response.json(), 200
