"""
Applet: Marketstack
Summary: Track stock price
Description: Allows you to track the value of a stock that you currently own historical (week or months) or intraday price as a plot, this app include Stocks of various countries.
Author: kanroot
"""

load("http.star", "http")
load("images/marketstack_data.jpg", MARKETSTACK_DATA_ASSET = "file")
load("math.star", "math")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

MARKETSTACK_DATA = MARKETSTACK_DATA_ASSET.readall()

ERROR_404 = "404"
ERROR_401 = "401"
ERROR_429 = "429"
ERROR_422 = "422"
ERROR_UNKNOWN = "Unknown"

MARKETSTACK_ICON_IMAGE = MARKETSTACK_DATA
MARKETSTACK_PRICE_URL = "http://api.marketstack.com/v1/"
MARKETSTACK_PRICE_URL_KEY = "access_key="

def main(config):
    api_token = config.get("api_token")
    company_name = config.get("company_name")
    select_period = config.get("select_period")
    missing_parameter = check_inputs(api_token, company_name)
    color_profit = get_preferences(config)
    query_timer = config.get("time_query")
    type_query_to_make = config.get("type_query_option")
    if missing_parameter:
        data_raw = None
        return error_view(missing_parameter)

    data_raw = make_marketstack_request(type_query_to_make, api_token, company_name, int(query_timer))
    is_error = is_response_error(data_raw)

    if is_error == True:
        return error_view(data_raw)
    return get_data_select_period(data_raw, color_profit, select_period, company_name)

def check_inputs(api_token, company_name):
    missing_parameter = None
    if not api_token:
        missing_parameter = "Missing API Token"
        return missing_parameter
    elif not company_name:
        missing_parameter = "Missing Company Name"
        return missing_parameter
    return missing_parameter

def error_view(message):
    return render.Root(
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = MARKETSTACK_ICON_IMAGE, width = 27, height = 24),
                render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.WrappedText(
                            font = "tb-8",
                            align = "center",
                            content = message.upper(),
                        ),
                    ],
                ),
            ],
        ),
    )

def get_percentage_with_two_decimals(last_price, previus_last_price):
    minus = last_price - previus_last_price
    difference_percentage = (minus / previus_last_price) * 100
    v = str(int(math.round(difference_percentage * 100)))
    v = v[0:-2] + "." + v[-2:]
    return v

def get_color_percentage_change(price):
    if float(price) > 0:
        return "#00ff00"
    else:
        return "#ff0000"

def get_data_select_period(request, colors, select_period, company_name):
    list_data = []
    i = 0
    for entry in request["data"]:
        i += 1
        list_data.append(entry["close"])

    data_filter = list_data[0:int(select_period)]
    min_period = data_filter[int(select_period) - 1]

    data_reconvert = []
    for entry in data_filter:
        value = entry - min_period
        data_reconvert.append(value)

    min_yield = min(data_reconvert)
    max_yield = max(data_reconvert)
    last_price = list_data[0]
    int_select_period = int(select_period) - 1
    previus_last_price = list_data[int_select_period]

    select_period_data = []
    k = 0
    for i in range(int(select_period), 0, -1):
        object = (i, data_reconvert[k])
        select_period_data.append(object)
        k += 1

    price_change = get_percentage_with_two_decimals(last_price, previus_last_price)
    color_price_change = get_color_percentage_change(price_change)
    pattern_company_name = r"[^.]*"
    company_name = re.findall(pattern_company_name, company_name)
    company_name = company_name[0]

    return render.Root(
        render.Column(
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "end",
                    children = [
                        render.Column(
                            cross_align = "space_around",
                            children = [
                                render.Text(
                                    font = "CG-pixel-3x5-mono",
                                    content = company_name,
                                ),
                                render.Text(
                                    font = "CG-pixel-3x5-mono",
                                    content = "$" + str(last_price),
                                ),
                            ],
                        ),
                        render.Row(
                            expanded = False,
                            main_align = "space_between",
                            cross_align = "end",
                            children = [
                                render.Text(
                                    font = "CG-pixel-3x5-mono",
                                    content = str(price_change) + "%",
                                    color = color_price_change,
                                ),
                            ],
                        ),
                    ],
                ),
                render.Plot(
                    data = select_period_data,
                    width = 64,
                    height = 22,
                    chart_type = "line",
                    color = colors[0],
                    fill_color = colors[0],
                    color_inverted = colors[1],
                    fill_color_inverted = colors[1],
                    y_lim = (min_yield, max_yield),
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
            display = "7",
            value = "7",
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
    ]
    type_query = [
        schema.Option(
            display = "Intraday (short as one minute, US ONLY)",
            value = "intraday?",
        ),
        schema.Option(
            display = "Historical Data (end-of-day price)",
            value = "eod?",
        ),
    ]
    query = [
        schema.Option(
            display = "1 minute",
            value = "60",
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
            value = "3600",
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
                id = "company_name",
                name = "Company Name",
                desc = "The company name to display",
                icon = "sackDollar",
            ),
            schema.Text(
                id = "api_token",
                name = "API Token",
                desc = "The API Token for your MarketStack",
                icon = "key",
                secret = True,
            ),
            schema.Dropdown(
                id = "select_period",
                name = "Time lapse",
                desc = "Period of time to show",
                icon = "calendarDays",
                default = days[0].value,
                options = days,
            ),
            schema.Dropdown(
                id = "time_query",
                name = "Time to refresh ",
                desc = "Time to refresh data",
                icon = "clock",
                default = query[5].value,
                options = query,
            ),
            schema.Dropdown(
                id = "type_query_option",
                name = "Type data",
                desc = "Query to intraday or historical ",
                icon = "clipboardQuestion",
                default = type_query[1].value,
                options = type_query,
            ),
            schema.Dropdown(
                id = "color_profit",
                name = "Profit's Color",
                desc = "The color of graph to be displayed profits.",
                icon = "brush",
                default = options[7].value,
                options = options,
            ),
            schema.Dropdown(
                id = "color_looses",
                name = "Loss color",
                desc = "The color of the loss graph",
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
    chart_color_loss = re.findall(color_regex, config.get("color_looses") or "")
    chart_color_profit = chart_color_profit[0] if chart_color_profit else "#008000"
    chart_color_loss = chart_color_loss[0] if chart_color_loss else "#ff0000"
    colors.append(chart_color_profit)
    colors.append(chart_color_loss)
    return colors

def make_marketstack_request(type_query, api_token, company, ttl_seconds):
    url = MARKETSTACK_PRICE_URL + type_query + MARKETSTACK_PRICE_URL_KEY + api_token + "&symbols=" + company
    response = http.get(url, ttl_seconds = ttl_seconds)
    if response.status_code == 404:
        return ERROR_404
    elif response.status_code == 429:
        return ERROR_429
    elif response.status_code == 401:
        return ERROR_401
    elif response.status_code == 422:
        return ERROR_422
    elif response.status_code != 200:
        return ERROR_UNKNOWN

    return response.json()

def is_response_error(response):
    if (
        response == ERROR_404 or
        response == ERROR_429 or
        response == ERROR_401 or
        response == ERROR_422 or
        response == ERROR_UNKNOWN
    ):
        return True
    else:
        return False
