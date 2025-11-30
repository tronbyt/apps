"""
Applet: Costco Gas
Summary: Costco Gas Display
Description: Displays gas prices from a selected Costco warehouse in the US.
Author: Dan Adam
"""
# Revised: 2022-09-15
# Thanks: Portions of the code were adapted from the sf_next_muni applet written by Martin Strauss
# Attribution: Gas Icon from "https://www.iconfinder.com/icons/111078/gas_icon", Costco Icon from "https://play-lh.googleusercontent.com/gqOziTbVWioRJtHh7OvfOq07NCTcAHKWBYPQKJOZqNcczpOz5hdrnQNY7i2OatJxmuY=w240-h480-rw"

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/costco.png", COSTCO_ICON_ASSET = "file")
load("images/gas.png", GAS_ICON_ASSET = "file")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_LOCATION = """
{
    "lat": "37.7844",
    "lng": "-122.4080",
    "description": "San Francisco, CA, USA",
	"locality": "San Francisco",
	"timezone": "America/Los_Angeles"
}
"""

DEFAULT_CONFIG = {
    "warehouse": "1216",
    "timezone": "America/Los_Angeles",
    "price_colour": "white",
    "icon_display": "costco-icon",
    "time_format": "24-hours",
    "show_hours": False,
}

DUMMY_WAREHOUSE = [
    {
        "locationName": "Dummy Warehouse",
        "identifier": "0",
        "gasPrices": {
            "regular": "0.009",
            "premium": "0.009",
            "diesel": "0.009",
        },
        "gasStationHours": [
            {
                "title": "Mon-Fri. ",
                "code": "open",
                "time": "10:00am - 8:00pm",
            },
            {
                "title": "Sat. ",
                "code": "open",
                "time": "6:00am - 7:00pm",
            },
            {
                "title": "Sun. ",
                "code": "open",
                "time": "9:00am - 6:00pm",
            },
        ],
    },
]

ICONS = {
    "gas-icon": GAS_ICON_ASSET.readall(),
    "costco-icon": COSTCO_ICON_ASSET.readall(),
}

PRICE_COLOURS = {
    "white": {
        "petrolColour": "#FFFFFF",
        "dieselColour": "#FFFFFF",
    },
    "red-green": {
        "petrolColour": "#ff0000",
        "dieselColour": "#00FF00",
    },
    "green-red": {
        "petrolColour": "#00FF00",
        "dieselColour": "#ff0000",
    },
}

DAY_MAP = {
    "Mon": "Mon-Fri. ",
    "Tue": "Mon-Fri. ",
    "Wed": "Mon-Fri. ",
    "Thu": "Mon-Fri. ",
    "Fri": "Mon-Fri. ",
    "Sat": "Sat. ",
    "Sun": "Sun. ",
}

TIME_FORMAT_MAP = {
    "24-hours": "15:04 ",
    "12-hours": "3:04pm",
}

API_HEADERS = {
    "Accept": "*/*",
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",  # Only product directive is needed, others can be stripped
    "Accept-Encoding": "identity",
    "Connection": "keep-alive",
}

# Note - These API GET calls are flaky at best. You can only make 1-2 calls per day before the server stops responding
API_WAREHOUSE_SEARCH = "https://www.costco.com/AjaxWarehouseBrowseLookupView?numOfWarehouses=20&countryCode=US&hasGas=true&populateWarehouseDetails=false{}"
API_WAREHOUSE_DETAILS = "https://www.costco.com/AjaxWarehouseBrowseLookupView?numOfWarehouses=1&countryCode=US&hasGas=true&populateWarehouseDetails=true&warehouseNumber={}"

def get_schema():
    icons = [
        schema.Option(
            display = "Costco Logo",
            value = "costco-icon",
        ),
        schema.Option(
            display = "Gas Pump",
            value = "gas-icon",
        ),
    ]

    price_colours = [
        schema.Option(
            display = "White",
            value = "white",
        ),
        schema.Option(
            display = "Red Gas, Green Diesel",
            value = "red-green",
        ),
        schema.Option(
            display = "Green Gas, Red Diesel",
            value = "green-red",
        ),
    ]

    time_formats = [
        schema.Option(
            display = "24 Hour Clock",
            value = "24-hours",
        ),
        schema.Option(
            display = "12 Hour Clock",
            value = "12-hours",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "warehouse_by_loc",
                name = "Warehouse",
                desc = "A list of warehouses by location",
                icon = "locationDot",
                handler = get_warehouses,
            ),
            schema.Toggle(
                id = "show_hours",
                name = "Show Hours",
                desc = "Show open hours for the current day. If enabled, icon won't show.",
                icon = "businessTime",
                default = DEFAULT_CONFIG["show_hours"],
            ),
            schema.Dropdown(
                id = "time_format",
                name = "Time Format",
                desc = "24 or 12 hour clock for hours display",
                icon = "clock",
                default = DEFAULT_CONFIG["time_format"],
                options = time_formats,
            ),
            schema.Dropdown(
                id = "icon_display",
                name = "Icon",
                desc = "Icon to display",
                icon = "icons",
                default = DEFAULT_CONFIG["icon_display"],
                options = icons,
            ),
            schema.Dropdown(
                id = "price_colour",
                name = "Price Colour",
                desc = "Colour scheme for price display",
                icon = "palette",
                default = DEFAULT_CONFIG["price_colour"],
                options = price_colours,
            ),
        ],
    )

def get_cached_data(url, ttl):
    cached_data = cache.get(url)

    if cached_data != None:
        response_data = json.decode(cached_data)
    else:
        http_data = http.get(url, headers = API_HEADERS)
        if http_data.status_code != 200:
            fail("HTTP request failed with status {} for URL {}".format(http_data.status_code, url))
        response_data = [x for x in http_data.json() if type(x) == "dict"]

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(url, json.encode(response_data), ttl_seconds = ttl)

    return response_data

def get_warehouses(location):
    loc = json.decode(location)
    warehouses = get_cached_data(API_WAREHOUSE_SEARCH.format("&latitude=" + humanize.float("#.#", float(loc["lat"])) + "&longitude=" + humanize.float("#.#", float(loc["lng"]))), 86400)

    return [
        schema.Option(
            display = warehouse["locationName"] + " #" + warehouse["identifier"],
            value = warehouse["identifier"],
        )
        for warehouse in warehouses
    ]

def get_gas_prices(config):
    warehouse = DEFAULT_CONFIG["warehouse"]
    warehouse_cfg = config.get("warehouse_by_loc")
    if warehouse_cfg:
        warehouse = json.decode(warehouse_cfg)["value"]

    warehouse_data = get_cached_data(API_WAREHOUSE_DETAILS.format(warehouse), 3600)

    if type(warehouse_data) != "list" or len(warehouse_data) == 0:
        warehouse_data = DUMMY_WAREHOUSE

    gas_prices = {}

    gas_prices["warehouse_name"] = warehouse_data[0].get("locationName", "ERROR") + " #" + warehouse_data[0].get("identifier", "ERROR")
    gas_prices["regular"] = warehouse_data[0]["gasPrices"].get("regular", "")
    gas_prices["premium"] = warehouse_data[0]["gasPrices"].get("premium", "")
    gas_prices["diesel"] = warehouse_data[0]["gasPrices"].get("diesel", "")
    gas_prices["gasStationHours"] = warehouse_data[0].get("gasStationHours", [])

    return gas_prices

def get_gas_hours(raw_gas_hours, config):
    gas_render = []

    time_long = "2006-01-02 3:04pm"
    date_short = "2006-01-02"

    gas_hours = get_gas_hours_dictionary(raw_gas_hours)

    # We will use the user's device time zone with $tz variable as the user's device will likely correspond to the warehouse timezone
    timezone = time.tz()

    current_time = time.now().in_location(timezone)
    current_day = current_time.format("Mon")
    current_date = current_time.format(date_short)

    hours_known = type(gas_hours.get(DAY_MAP[current_day], "")) == "dict"

    if hours_known:
        is_open = current_time >= time.parse_time(current_date + " " + gas_hours[DAY_MAP[current_day]]["open"], time_long, timezone) and current_time < time.parse_time(current_date + " " + gas_hours[DAY_MAP[current_day]]["closed"], time_long, timezone)
        if is_open:
            gas_render.append(
                render.Padding(
                    child = render.Text("OPEN", font = "tom-thumb", color = "#04AF45"),
                    pad = (18, 0, 0, 0),
                ),
            )
        else:
            gas_render.append(
                render.Padding(
                    child = render.Text("CLOSED", font = "tom-thumb", color = "#C90000"),
                    pad = (10, 0, 0, 0),
                ),
            )
        gas_render.append(
            render.Text(time.parse_time(current_date + " " + gas_hours[DAY_MAP[current_day]]["open"], time_long, timezone).format(TIME_FORMAT_MAP[config.get("time_format", DEFAULT_CONFIG["time_format"])])[:-1], font = "tom-thumb"),
        )
        gas_render.append(
            render.Text(time.parse_time(current_date + " " + gas_hours[DAY_MAP[current_day]]["closed"], time_long, timezone).format(TIME_FORMAT_MAP[config.get("time_format", DEFAULT_CONFIG["time_format"])])[:-1], font = "tom-thumb"),
        )
    else:
        gas_render.append(
            render.Padding(
                child = render.Text("Hours", font = "tom-thumb", color = "#C90000"),
                pad = (0, 0, 0, 0),
            ),
        )
        gas_render.append(
            render.Padding(
                child = render.Text("Unknown", font = "tom-thumb", color = "#C90000"),
                pad = (6, 0, 0, 0),
            ),
        )

    return gas_render

def get_gas_hours_dictionary(raw_gas_hours):
    regex_hours = r"(1?[0-9]:[0-5][0-9][ap]m) - (1?[0-9]:[0-5][0-9][ap]m)"
    regex_time = r"1?[0-9]:[0-5][0-9][ap]m"
    gas_hours = {}
    for hours in raw_gas_hours:
        if hours.get("title", "") != "" and hours.get("code", "") == "open" and re.search(regex_hours, hours.get("time", "")):
            gas_hours[hours["title"]] = {"open": re.findall(regex_time, hours["time"])[0], "closed": re.findall(regex_time, hours["time"])[1]}
    return gas_hours

def get_hours_or_icon(raw_gas_hours, config):
    render_children = []
    if config.bool("show_hours", DEFAULT_CONFIG["show_hours"]):
        render_children = get_gas_hours(raw_gas_hours, config)
    else:
        render_children.append(
            render.Padding(
                child = render.Image(ICONS[config.get("icon_display", DEFAULT_CONFIG["icon_display"])], width = 20, height = 20),
                pad = (5, 0, 0, 0),
            ),
        )

    return render_children

def format_gas_price(gas_price):
    regex = r"^[\d]+\.\d\d9$"
    price_check = re.search(regex, gas_price)

    if price_check != None:
        return gas_price[:-1]

    return gas_price

def get_display(gas_prices, config):
    labels = []
    prices = []

    if gas_prices.get("regular", "") != "":
        labels.append(
            render.Text("R: "),
        )
        prices.append(
            render.Text(format_gas_price(gas_prices["regular"]), color = PRICE_COLOURS[config.get("price_colour", DEFAULT_CONFIG["price_colour"])]["petrolColour"]),
        )

    if gas_prices.get("premium", "") != "":
        labels.append(
            render.Text("P: "),
        )
        prices.append(
            render.Text(format_gas_price(gas_prices["premium"]), color = PRICE_COLOURS[config.get("price_colour", DEFAULT_CONFIG["price_colour"])]["petrolColour"]),
        )

    if gas_prices.get("diesel", "") != "":
        labels.append(
            render.Text("D: "),
        )
        prices.append(
            render.Text(format_gas_price(gas_prices["diesel"]), color = PRICE_COLOURS[config.get("price_colour", DEFAULT_CONFIG["price_colour"])]["dieselColour"]),
        )

    return labels, prices

def main(config):
    gas_prices = get_gas_prices(config)
    labels, prices = get_display(gas_prices, config)

    return render.Root(
        child = render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    child = render.Text(gas_prices["warehouse_name"], color = "#0073A6"),
                ),
                render.Row(
                    children = [
                        render.Column(
                            children = labels,
                            cross_align = "start",
                        ),
                        render.Column(
                            children = prices,
                            cross_align = "end",
                        ),
                        render.Column(
                            children = get_hours_or_icon(gas_prices["gasStationHours"], config),
                            expanded = True,
                            main_align = "center",
                            cross_align = "end",
                        ),
                    ],
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                ),
            ],
        ),
    )
