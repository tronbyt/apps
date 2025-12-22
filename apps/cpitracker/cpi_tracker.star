"""
Applet: CPI Tracker
Summary: Track monthly CPI trends
Description: Track monthly CPI trends as well as the current CPI value today!
Author: Robert Ison
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")


SAMPLE_DATA = """
{"Results":{"series":[{"seriesID":"CUUR0000SA0","data":[{"period":"M03","periodName":"March","value":"319.799","year":"2025"},{"period":"M02","periodName":"February","value":"319.082","year":"2025"},{"period":"M01","periodName":"January","value":"317.671","year":"2025"},{"period":"M12","periodName":"December","value":"315.605","year":"2024"},{"period":"M11","periodName":"November","value":"315.493","year":"2024"},{"period":"M10","periodName":"October","value":"315.664","year":"2024"}]},{"seriesID":"CUUR0000SA0E","data":[{"period":"M03","periodName":"March","value":"275.734","year":"2025"},{"period":"M02","periodName":"February","value":"275.867","year":"2025"},{"period":"M01","periodName":"January","value":"273.045","year":"2025"},{"period":"M12","periodName":"December","value":"267.963","year":"2024"},{"period":"M11","periodName":"November","value":"268.213","year":"2024"},{"period":"M10","periodName":"October","value":"272.807","year":"2024"}]},{"seriesID":"CUUR0000SAC","data":[{"period":"M03","periodName":"March","value":"223.871","year":"2025"},{"period":"M02","periodName":"February","value":"223.591","year":"2025"},{"period":"M01","periodName":"January","value":"222.490","year":"2025"},{"period":"M12","periodName":"December","value":"220.949","year":"2024"},{"period":"M11","periodName":"November","value":"221.466","year":"2024"},{"period":"M10","periodName":"October","value":"222.483","year":"2024"}]},{"seriesID":"CUUR0000SAD","data":[{"period":"M03","periodName":"March","value":"122.428","year":"2025"},{"period":"M02","periodName":"February","value":"122.327","year":"2025"},{"period":"M01","periodName":"January","value":"122.260","year":"2025"},{"period":"M12","periodName":"December","value":"121.747","year":"2024"},{"period":"M11","periodName":"November","value":"122.061","year":"2024"},{"period":"M10","periodName":"October","value":"122.180","year":"2024"}]},{"seriesID":"CUUR0000SAF1","data":[{"period":"M03","periodName":"March","value":"337.751","year":"2025"},{"period":"M02","periodName":"February","value":"336.274","year":"2025"},{"period":"M01","periodName":"January","value":"335.517","year":"2025"},{"period":"M12","periodName":"December","value":"333.566","year":"2024"},{"period":"M11","periodName":"November","value":"332.904","year":"2024"},{"period":"M10","periodName":"October","value":"332.678","year":"2024"}]},{"seriesID":"CUUR0000SAH","data":[{"period":"M03","periodName":"March","value":"343.512","year":"2025"},{"period":"M02","periodName":"February","value":"342.398","year":"2025"},{"period":"M01","periodName":"January","value":"340.875","year":"2025"},{"period":"M12","periodName":"December","value":"338.883","year":"2024"},{"period":"M11","periodName":"November","value":"338.048","year":"2024"},{"period":"M10","periodName":"October","value":"337.470","year":"2024"}]},{"seriesID":"CUUR0000SAI","data":[{"period":"M03","periodName":"March","value":"270.061","year":"2025"},{"period":"M02","periodName":"February","value":"271.040","year":"2025"},{"period":"M01","periodName":"January","value":"270.384","year":"2025"},{"period":"M12","periodName":"December","value":"267.606","year":"2024"},{"period":"M11","periodName":"November","value":"268.450","year":"2024"},{"period":"M10","periodName":"October","value":"269.724","year":"2024"}]}]}}
"""

TIME_OUT_IN_SECONDS = 172800  # No need to get data more often than 2 days
CPI_DATA_SET_KEY_NAME = "cpi_tracker_CPIDataSetKeyName"
CPI_CON_COLORS = ["#B31942", "#FFFFFF", "#0A3161", "#B31942", "#FFFFFF"]
SELECTED_SERIES_DATA = [["CUUR0000SA0", "All Items", "#FFD700", "Gold"], ["CUUR0000SA0E", "Energy", "#FFFF00", "Yellow"], ["CUUR0000SAC", "Commodities", "#8B4513", "Earthy Brown"], ["CUUR0000SAD", "Durables", "#4682B4", "Steel Blue"], ["CUUR0000SAF1", "Food", "#32CD32", "Green"], ["CUUR0000SAH", "Housing", "#B22222", "Brick Red"], ["CUUR0000SAT", "Transportation", "#FF8C00", "Orange"], ["CUUR0000SAM", "Medical", "#FFFFFF", "White"], ["CUUR0000SAE1", "Education", "#1E90FF", "Academic Blue"]]

SCREEN_HEIGHT = canvas.height()
SCREEN_WIDTH = canvas.width()

display_type = [
    schema.Option(display = "Display The Main CPI Index", value = "CPI"),
    schema.Option(display = "Display selected categories of CPI", value = "Categories"),
]

display_time_period = [
    schema.Option(display = "3 Months", value = "3"),
    schema.Option(display = "6 Months", value = "6"),
    schema.Option(display = "1 Year", value = "12"),
    schema.Option(display = "2 Years", value = "24"),
    schema.Option(display = "3 Years", value = "36"),
    schema.Option(display = "4 Years", value = "48"),
    schema.Option(display = "5 Years", value = "60"),
]

def get_category_options(display_type):
    display_options = []

    # Loop through each item and print the values
    if (display_type == "Categories"):
        for item in SELECTED_SERIES_DATA:
            display_options.append(schema.Toggle(id = item[0], name = item[1], desc = "%s  (in %s)" % (item[1], item[3]), icon = "check", default = False))

    return display_options

def get_category_list():
    # Initialize an empty list for the results
    first_elements = []

    # Loop through the data
    for item in SELECTED_SERIES_DATA:
        first_elements.append(item[0])

    return first_elements

def display_instructions(config):
    ##############################################################################################################################################################################################################################
    title = "Consumer Price Index (CPI) Data"
    instructions_1 = "You can select the main CPI Index, or selected categories, including the general index. Adding additional categories makes the display a little crowded, but suit yourself."
    instructions_2 = "The source for this app is the U.S. Bureau of Labor Statistics, see www.bls.gov for more information. The data presented here is not to scale, only shows relative changes over the time period. "
    instructions_3 = "In addition to categories, you may also select the time period displayed from 3 months, to 5 years. "
    return render.Root(
        render.Column(
            children = [
                render.Marquee(
                    width = SCREEN_WIDTH,
                    child = render.Text(title, color = CPI_CON_COLORS[0], font = "5x8"),
                ),
                render.Marquee(
                    width = SCREEN_WIDTH,
                    child = render.Text(instructions_1, color = CPI_CON_COLORS[1]),
                    offset_start = len(title) * 5,
                ),
                render.Marquee(
                    offset_start = (len(title) + len(instructions_1)) * 5,
                    width = SCREEN_WIDTH,
                    child = render.Text(instructions_2, color = CPI_CON_COLORS[2]),
                ),
                render.Marquee(
                    offset_start = (len(title) + len(instructions_2) + len(instructions_1)) * 5,
                    width = SCREEN_WIDTH,
                    child = render.Text(instructions_3, color = CPI_CON_COLORS[3]),
                ),
            ],
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)) // 2 if canvas.is2x() else int(config.get("scroll", 45)),
    )

def get_cpi_data(api_key):
    url = "https://api.bls.gov/publicAPI/v2/timeseries/data/"
    headers = {"Content-Type": "application/json"}

    now = time.now().in_location("UTC")
    current_year = now.year
    start_year = current_year - 5

    payload = {
        "seriesid": get_category_list(),
        "startyear": str(start_year),
        "endyear": str(current_year),
        "registrationkey": api_key,
    }

    response = http.post(
        url = url,
        headers = headers,
        body = json.encode(payload),
        ttl_seconds = TIME_OUT_IN_SECONDS,
    )

    if response.status_code != 200:
        return json.encode({"status": "ERROR", "message": "HTTP %d" % response.status_code})

    data = response.json()  # ✅ already decoded

    if data.get("status") != "REQUEST_SUCCEEDED":
        return json.encode({"status": "ERROR", "message": data.get("message", "API error")})

    return json.encode(data)  # ✅ encode once, at the boundary
def plot_cpi_data(formatted_data, color, show_info_bar):
    months = []
    for i in range(len(formatted_data), 0, -1):
        months.append(i)

    # Example CPI data for the past 6 months (replace with actual data from your API response)
    cpi_values = formatted_data

    # Combine months and values into a list of data points
    data = [(month, value) for month, value in zip(months, cpi_values)]

    height = SCREEN_HEIGHT - 7 if show_info_bar else SCREEN_HEIGHT

    # Use render.plot to create a line graph
    return render.Plot(
        data = data,
        color = color,
        width = SCREEN_WIDTH,
        height = height,
    )

def get_series_data_by_name(parsed_data, series_name):
    # Loop through the series list
    if "Results" not in parsed_data:
        return None

    for series in parsed_data["Results"]["series"]:
        # Check if the seriesID matches the desired name
        if series["seriesID"] == series_name:
            # Return the "data" for the matching series
            return series["data"]

    # Return None if the series name is not found
    return None

def extract_filtered_data(json_data, series_name, months):
    # Decode the JSON string into a Starlark dictionary
    parsed_data = json.decode(json_data)

    # Access the series data
    series_data = get_series_data_by_name(parsed_data, series_name)

    if not series_data:
        return []

    # Extract the last N months (assuming data is ordered with most recent first)
    relevant_dates = series_data[:months]  # Take the first N records

    # Format the data as a list of tuples (month, value)
    formatted_data = []
    for item in relevant_dates:
        if item["value"] == "-" or "Data unavailable" in str(item.get("footnotes", [])):
            formatted_data.append(0.0)  # or None/skip
        else:
            formatted_data.append(float(item["value"]))

    return formatted_data

def get_series_item(series_id, item_number):
    # Iterate over each item in the array
    for item in SELECTED_SERIES_DATA:
        # Check if the first element matches the given series ID
        if item[0] == series_id:
            # Return the third element (color code)
            return item[item_number]

    # Return None if no match is found
    return None

def get_series_color(series_id):
    return get_series_item(series_id, 2)

def get_series_name(series_id):
    return get_series_item(series_id, 1)

def get_series_color_name(series_id):
    return get_series_item(series_id, 3)

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )

    return padded_element

def main(config):
    show_instructions = config.bool("instructions", False)
    if show_instructions:
        return display_instructions(config)

    show_info_bar = config.bool("info_bar", False)

    # store the items we add to the display in children
    animation_frames = []  #
    children = []  #Items that go into a stack
    messages = []  #building up the string to display

    # default to sample data
    data = SAMPLE_DATA

    api_key = config.get("api_key", "")
    if (api_key != ""):
        data = get_cpi_data(config.get("api_key"))

    #store the series to display, default it to the main CPI dataset
    series_data_sets_to_display = []
    series_data_sets_to_display.append(SELECTED_SERIES_DATA[0][0])

    if (config.get("display_type") != "CPI"):
        individual_series = []
        for item in SELECTED_SERIES_DATA:
            if (config.bool(item[0], False)):
                individual_series.append(item[0])

        if (len(individual_series) > 0):
            series_data_sets_to_display = individual_series

    # let's plot them in reverse order to make "Everything" overlap the individual items
    for item in series_data_sets_to_display[::-1]:
        plot_data = extract_filtered_data(data, item, int(config.get("display_time_period", display_time_period[0].value)))
        children.append(plot_cpi_data(plot_data, get_series_color(item), show_info_bar))

    #snapshot of just the chart display lines
    chart_display_children = list(children)

    # I have the chart display, but I want to expose it one pixel column at a time
    current_scene = render.Box(color = "#000", width = SCREEN_WIDTH, height = SCREEN_HEIGHT)
    for i in range(SCREEN_WIDTH + 1):  #range(SCREEN_WIDTH):
        #Create animation images of the stack chart, and a box so that the animation works

        current_scene = render.Stack(
            children = [
                render.Stack(children = chart_display_children),
                add_padding_to_child_element(
                    render.Box(color = "#000", width = SCREEN_WIDTH - i, height = SCREEN_HEIGHT),
                    i,
                ),
            ],
        )

        animation_frames.append(current_scene)

    # Hold for a few frames
    HOLD_FRAMES = 25
    for i in range(HOLD_FRAMES):
        animation_frames.append(current_scene)

    #Reset Children for the overlay of info
    children = []

    # Add some generic info on the time period from the first data set
    parsed = json.decode(data)
    first_series_id = series_data_sets_to_display[0]
    series_data = get_series_data_by_name(parsed, first_series_id)
    first_item = series_data[0]
    year = first_item["year"]
    period_name = first_item["periodName"]

    message = "     %s months CPI data to %s %s " % (int(config.get("display_time_period", display_time_period[0].value)), period_name, year)
    messages.append(render.Text(message, color = "#fff"))

    # but let's list the selected item in order
    for item in series_data_sets_to_display:
        message = "%s in %s " % (get_series_name(item), get_series_color_name(item))
        messages.append(render.Text(message, color = get_series_color(item)))

    if show_info_bar:
        children.append(add_padding_to_child_element(render.Marquee(
            width = SCREEN_WIDTH,
            child = render.Row(messages),
            offset_start = 0,
            offset_end = 0,
            align = "start",
        ), 0, 25))
    else:
        #display some data
        message = "%s months" % (int(config.get("display_time_period", display_time_period[0].value)))
        children.append(add_padding_to_child_element(render.Text(message, color = "#666", font = "CG-pixel-3x5-mono"), SCREEN_WIDTH - (len(message) * 4), SCREEN_HEIGHT - 5))

    all_elements = [
        render.Animation(children = animation_frames),
    ]

    all_elements.append(render.Stack(children = children))

    return render.Root(
        child = render.Stack(children = all_elements),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def get_schema():
    scroll_speed_options = [
        schema.Option(
            display = "Slow Scroll",
            value = "60",
        ),
        schema.Option(
            display = "Medium Scroll",
            value = "45",
        ),
        schema.Option(
            display = "Fast Scroll",
            value = "30",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "BLS API Key",
                desc = "Your Bureau of Labor Statistics (BLS) API key. See https://www.bls.gov/developers/ for details.",
                icon = "key",
                secret = True,
            ),
            schema.Toggle(
                id = "instructions",
                name = "Display Instructions",
                desc = "",
                icon = "book",  #"info",
                default = False,
            ),
            schema.Toggle(
                id = "info_bar",
                name = "Information Bar",
                desc = "Show the Information bar across the bottom of the screen?",
                icon = "info",  #"info",
                default = True,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "scroll",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
            schema.Dropdown(
                id = "display_time_period",
                icon = "timeline",
                name = "Time Period",
                desc = "Which time period would you like the chart to represent?",
                options = display_time_period,
                default = display_time_period[0].value,
            ),
            schema.Dropdown(
                id = "display_type",
                icon = "tv",
                name = "What to display",
                desc = "What do you want this to display?",
                options = display_type,
                default = display_type[0].value,
            ),
            schema.Generated(
                id = "generated",
                source = "display_type",
                handler = get_category_options,
            ),
        ],
    )
