"""
Applet: CPI Tracker
Summary: Track monthly CPI trends
Description: Track monthly CPI trends as well as the current CPI value today!
Author: Robert Ison
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

SAMPLE_DATA = """{"Results":{"series":[{"seriesID":"CUUR0000SA0","data":[{"period":"M03","periodName":"March","value":"319.799","year":"2025"},{"period":"M02","periodName":"February","value":"319.082","year":"2025"},{"period":"M01","periodName":"January","value":"317.671","year":"2025"},{"period":"M12","periodName":"December","value":"315.605","year":"2024"},{"period":"M11","periodName":"November","value":"315.493","year":"2024"},{"period":"M10","periodName":"October","value":"315.664","year":"2024"}]}]}}"""

TIME_OUT_IN_SECONDS = 172800
CPI_DATA_SET_KEY_NAME = "cpi_tracker_CPIDataSetKeyName"
CPI_CON_COLORS = ["#B31942", "#FFFFFF", "#0A3161", "#B31942", "#FFFFFF"]

SELECTED_SERIES_DATA = [
    ["CUUR0000SA0", "All Items", "#FFD700", "Gold"],
    ["CUUR0000SA0E", "Energy", "#FFFF00", "Yellow"],
    ["CUUR0000SAC", "Commodities", "#8B4513", "Earthy Brown"],
    ["CUUR0000SAD", "Durables", "#4682B4", "Steel Blue"],
    ["CUUR0000SAF1", "Food", "#32CD32", "Green"],
    ["CUUR0000SAH", "Housing", "#B22222", "Brick Red"],
    ["CUUR0000SAT", "Transportation", "#FF8C00", "Orange"],
    ["CUUR0000SAM", "Medical", "#FFFFFF", "White"],
    ["CUUR0000SAE1", "Education", "#1E90FF", "Academic Blue"],
]

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

# ------------------------- Helpers -------------------------

def get_category_options(display_type):
    if display_type != "Categories":
        return []
    return [
        schema.Toggle(id = item[0], name = item[1], desc = "%s  (in %s)" % (item[1], item[3]), icon = "check", default = False)
        for item in SELECTED_SERIES_DATA
    ]

def get_category_list():
    return [item[0] for item in SELECTED_SERIES_DATA]

def get_series_item(series_id, index):
    for item in SELECTED_SERIES_DATA:
        if item[0] == series_id:
            return item[index]
    return None

def get_series_color(series_id):
    return get_series_item(series_id, 2)

def get_series_name(series_id):
    return get_series_item(series_id, 1)

def get_series_color_name(series_id):
    return get_series_item(series_id, 3)

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    return render.Padding(pad = (left, top, right, bottom), child = element)

# ------------------------- Data Fetching -------------------------

def get_cpi_data(api_key):
    url = "https://api.bls.gov/publicAPI/v2/timeseries/data/"
    headers = {"Content-Type": "application/json"}

    now = time.now().in_location("UTC")
    start_year = now.year - 5

    payload = {
        "seriesid": get_category_list(),
        "startyear": str(start_year),
        "endyear": str(now.year),
        "registrationkey": api_key,
    }

    response = http.post(url = url, headers = headers, body = json.encode(payload), ttl_seconds = TIME_OUT_IN_SECONDS)

    if response.status_code != 200:
        return json.encode({"status": "ERROR", "message": "HTTP %d" % response.status_code})

    data = response.json()
    if data.get("status") != "REQUEST_SUCCEEDED":
        return json.encode({"status": "ERROR", "message": data.get("message", "API error")})

    return json.encode(data)

def get_series_data_by_name(parsed_data, series_name):
    if "Results" not in parsed_data:
        return None
    for series in parsed_data["Results"]["series"]:
        if series["seriesID"] == series_name:
            return series["data"]
    return None

def extract_filtered_data(parsed_data, series_name, months):
    series_data = get_series_data_by_name(parsed_data, series_name)
    if not series_data:
        return []
    formatted = []
    for item in series_data[:months]:
        value = item.get("value")
        if value == "-" or "Data unavailable" in str(item.get("footnotes", [])):
            formatted.append(0.0)
        else:
            formatted.append(float(value))
    return formatted

# ------------------------- Rendering -------------------------

def display_instructions(config):
    title = "Consumer Price Index (CPI) Data"
    instructions = [
        "You can select the main CPI Index, or selected categories, including the general index. Adding additional categories makes the display a little crowded, but suit yourself.",
        "The source for this app is the U.S. Bureau of Labor Statistics, see www.bls.gov for more information. The data presented here is not to scale, only shows relative changes over the time period.",
        "In addition to categories, you may also select the time period displayed from 3 months, to 5 years.",
    ]
    return render.Root(
        render.Column(children = [
            render.Marquee(width = SCREEN_WIDTH, child = render.Text(title, color = CPI_CON_COLORS[0], font = "5x8")),
            render.Marquee(width = SCREEN_WIDTH, child = render.Text(instructions[0], color = CPI_CON_COLORS[1]), offset_start = len(title) * 5),
            render.Marquee(width = SCREEN_WIDTH, child = render.Text(instructions[1], color = CPI_CON_COLORS[2]), offset_start = (len(title) + len(instructions[0])) * 5),
            render.Marquee(width = SCREEN_WIDTH, child = render.Text(instructions[2], color = CPI_CON_COLORS[3]), offset_start = (len(title) + len(instructions[0]) + len(instructions[1])) * 5),
        ]),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)) // 2 if canvas.is2x() else int(config.get("scroll", 45)),
    )

def plot_cpi_data(values, color, show_info_bar):
    months = list(range(len(values), 0, -1))
    data = [(m, v) for m, v in zip(months, values)]
    height = SCREEN_HEIGHT - 7 if show_info_bar else SCREEN_HEIGHT
    return render.Plot(data = data, color = color, width = SCREEN_WIDTH, height = height)

# ------------------------- Main -------------------------

def main(config):
    show_instructions = config.bool("instructions", False)
    if show_instructions:
        return display_instructions(config)

    show_info_bar = config.bool("info_bar", False)
    animation_frames = []
    children = []
    messages = []

    # Fetch data (use sample if API key missing)
    data_json = SAMPLE_DATA
    api_key = config.get("api_key", "")
    if api_key != "":
        data_json = get_cpi_data(api_key)
    parsed_data = json.decode(data_json)

    # Determine series to display
    series_data_sets = [SELECTED_SERIES_DATA[0][0]] if config.get("display_type") == "CPI" else [item[0] for item in SELECTED_SERIES_DATA if config.bool(item[0], False)]
    if not series_data_sets:
        series_data_sets = [SELECTED_SERIES_DATA[0][0]]

    # Plot series in reverse order
    time_period = int(config.get("display_time_period", display_time_period[0].value))
    for series_id in series_data_sets[::-1]:
        values = extract_filtered_data(parsed_data, series_id, time_period)
        children.append(plot_cpi_data(values, get_series_color(series_id), show_info_bar))

    chart_children = list(children)
    current_scene = render.Box(color = "#000", width = SCREEN_WIDTH, height = SCREEN_HEIGHT)
    HOLD_FRAMES = 25

    # Animate chart
    for i in range(SCREEN_WIDTH + 1):
        current_scene = render.Stack(children = [
            render.Stack(children = chart_children),
            add_padding_to_child_element(render.Box(color = "#000", width = SCREEN_WIDTH - i, height = SCREEN_HEIGHT), i),
        ])
        animation_frames.append(current_scene)
    for _ in range(HOLD_FRAMES):
        animation_frames.append(current_scene)

    # Build info bar / messages
    first_series = series_data_sets[0]
    series_data = get_series_data_by_name(parsed_data, first_series)
    first_item = series_data[0]
    messages.append(render.Text("     %s months CPI data to %s %s " % (time_period, first_item["periodName"], first_item["year"]), color = "#fff"))
    for s in series_data_sets:
        messages.append(render.Text("%s in %s " % (get_series_name(s), get_series_color_name(s)), color = get_series_color(s)))

    if show_info_bar:
        children = [add_padding_to_child_element(render.Marquee(width = SCREEN_WIDTH, child = render.Row(messages), offset_start = 0, offset_end = 0, align = "start"), 0, 25)]
    else:
        msg = "%s months" % time_period
        children = [add_padding_to_child_element(render.Text(msg, color = "#666", font = "CG-pixel-3x5-mono"), SCREEN_WIDTH - (len(msg) * 4), SCREEN_HEIGHT - 5)]

    all_elements = [render.Animation(children = animation_frames), render.Stack(children = children)]
    return render.Root(child = render.Stack(children = all_elements), show_full_animation = True, delay = int(config.get("scroll", 45)))

# ------------------------- Schema -------------------------

def get_schema():
    scroll_speed_options = [schema.Option(display = d, value = v) for d, v in [("Slow Scroll", "60"), ("Medium Scroll", "45"), ("Fast Scroll", "30")]]
    return schema.Schema(version = "1", fields = [
        schema.Text(id = "api_key", name = "BLS API Key", desc = "Your Bureau of Labor Statistics API key", icon = "key", secret = True),
        schema.Toggle(id = "instructions", name = "Display Instructions", desc = "", icon = "book", default = False),
        schema.Toggle(id = "info_bar", name = "Information Bar", desc = "Show the info bar?", icon = "info", default = True),
        schema.Dropdown(id = "scroll", name = "Scroll", desc = "Scroll Speed", icon = "scroll", options = scroll_speed_options, default = scroll_speed_options[0].value),
        schema.Dropdown(id = "display_time_period", icon = "timeline", name = "Time Period", desc = "Which time period to show?", options = display_time_period, default = display_time_period[0].value),
        schema.Dropdown(id = "display_type", icon = "tv", name = "What to display", desc = "Choose main CPI or categories", options = display_type, default = display_type[0].value),
        schema.Generated(id = "generated", source = "display_type", handler = get_category_options),
    ])
