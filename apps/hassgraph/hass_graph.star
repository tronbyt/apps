load("animation.star", "animation")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/img_2274bcef.bin", IMG_2274bcef_ASSET = "file")
load("images/img_7b76fdf3.bin", IMG_7b76fdf3_ASSET = "file")
load("images/img_adff806b.svg", IMG_adff806b_ASSET = "file")
load("images/img_fbe29b76.svg", IMG_fbe29b76_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_COLOURS = {
    "line_positive": "#FFA500",
    "line_negative": "#344FEB",
    "fill_positive": "#FFCC66",
    "fill_negative": "#87CEFA",
}

ICONS = {
    "thermometer": IMG_2274bcef_ASSET.readall(),
    "wind": IMG_7b76fdf3_ASSET.readall(),
    "ha": IMG_fbe29b76_ASSET.readall(),
    "drop": IMG_adff806b_ASSET.readall(),
    "car": """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" fill="#ffffff"><!--!Font Awesome Free 6.6.0 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free Copyright 2024 Fonticons, Inc.--><path d="M135.2 117.4L109.1 192l293.8 0-26.1-74.6C372.3 104.6 360.2 96 346.6 96L165.4 96c-13.6 0-25.7 8.6-30.2 21.4zM39.6 196.8L74.8 96.3C88.3 57.8 124.6 32 165.4 32l181.2 0c40.8 0 77.1 25.8 90.6 64.3l35.2 100.5c23.2 9.6 39.6 32.5 39.6 59.2l0 144 0 48c0 17.7-14.3 32-32 32l-32 0c-17.7 0-32-14.3-32-32l0-48L96 400l0 48c0 17.7-14.3 32-32 32l-32 0c-17.7 0-32-14.3-32-32l0-48L0 256c0-26.7 16.4-49.6 39.6-59.2zM128 288a32 32 0 1 0 -64 0 32 32 0 1 0 64 0zm288 32a32 32 0 1 0 0-64 32 32 0 1 0 0 64z"/></svg>
""",
}

PLACEHOLDER_DATA = [
    {
        "attributes": {
            "unit_of_measurement": "°C",
        },
        "state": "23",
        "last_changed": "2024-01-06T12:00:00Z",
    },
    {
        "state": "18",
        "last_changed": "2024-01-06T13:00:00Z",
    },
    {
        "state": "22",
        "last_changed": "2024-01-06T14:00:00Z",
    },
    {
        "state": "24",
        "last_changed": "2024-01-06T15:00:00Z",
    },
    {
        "state": "12",
        "last_changed": "2024-01-06T16:00:00Z",
    },
]

MAX_TIME_PERIOD = 24

TIME_FORMAT = "2006-01-02T15:04:05Z"

def main(config):
    timezone = None
    location = config.get("location")
    if location:
        loc = json.decode(location)
        timezone = loc["timezone"]

    if not config.str("ha_instance") or not config.str("ha_entity") or not config.str("ha_token"):
        print("Using placeholder data, please configure the app")
        data = PLACEHOLDER_DATA
        error = None
    else:
        time_period = get_time_period(config.str("time_period"))
        if time_period == None:
            return render_error_message("Invalid time period")

        start_time = time.now() - time.hour * time_period
        data, error = get_entity_data(config, start_time)

    if data == None:
        return render_error_message("Error: received status " + str(error))
    elif len(data) < 1:
        return render_error_message("No data available")

    unit = data[0]["attributes"]["unit_of_measurement"]
    points = calculate_hourly_average(data)
    current_value = data[-1]["state"]
    stats = calc_stats(timezone, data)

    return render_app(config, current_value, points, stats, unit)

def calculate_hourly_average(data):
    hourly_averages = {}
    current_hour = None
    hour_total = 0
    hour_count = 0
    index = 0

    for entry in data:
        if entry["state"] == "unavailable" or entry["state"] == "unknown":
            continue

        timestamp = entry["last_changed"]
        hour = int(timestamp.split("T")[1].split(":")[0])
        value = float(entry["state"])

        if hour != current_hour:
            if current_hour != None:
                hourly_averages[index] = hour_total / hour_count if hour_count != 0 else 0
                index += 1
            current_hour = hour
            hour_total = 0
            hour_count = 0

        hour_total += value
        hour_count += 1

    if current_hour != None:
        hourly_averages[index] = hour_total / hour_count if hour_count != 0 else 0

    return list(hourly_averages.items())

def localize_timestamp(timezone, timestamp):
    return time.parse_time(timestamp).in_location(timezone).format(TIME_FORMAT)

def calc_stats(timezone, data):
    highest_value = float("-inf")
    highest_timestamp = None
    lowest_value = float("inf")
    lowest_timestamp = None
    total_value = 0
    count = 0

    for entry in data:
        if entry["state"] == "unavailable" or entry["state"] == "unknown":
            continue

        value = float(entry["state"])
        total_value += value
        count += 1
        if value < lowest_value:
            lowest_value = value
            lowest_timestamp = entry["last_changed"]
        if value > highest_value:
            highest_value = value
            highest_timestamp = entry["last_changed"]

    average_value = total_value / count if count else 0
    average_value = (average_value * 10) // 1 / 10

    if timezone:
        lowest_timestamp = localize_timestamp(timezone, lowest_timestamp)
        highest_timestamp = localize_timestamp(timezone, highest_timestamp)

    return {
        "lowest_value": str(lowest_value),
        "lowest_time": lowest_timestamp.split("T")[1][:5] if lowest_value != float("inf") else "N/A",
        "highest_value": str(highest_value),
        "highest_time": highest_timestamp.split("T")[1][:5] if highest_value != float("-inf") else "N/A",
        "average": str(average_value),
    }

def get_entity_data(config, start_time):
    start_time_str = start_time.format(TIME_FORMAT)
    url = config.str("ha_instance") + "/api/history/period/" + start_time_str + "?filter_entity_id=" + config.str("ha_entity")
    headers = {
        "Authorization": "Bearer " + config.str("ha_token"),
        "Content-Type": "application/json",
    }

    rep = http.get(url, ttl_seconds = 240, headers = headers)
    if rep.status_code != 200:
        return None, rep.status_code

    data = rep.json()
    return (data[0], None) if data else ([], None)

def get_icon(config):
    icon = config.str("icon")
    return ICONS[icon] if icon in ICONS else ICONS["thermometer"]

def get_time_period(input_str):
    if not input_str.isdigit():
        return None
    time_period = int(input_str)
    if time_period < 2 or time_period > MAX_TIME_PERIOD:
        return None

    return time_period

def render_app(config, current_value, points, stats, unit):
    if config.bool("show_history"):
        return render.Root(
            child = animation.Transformation(
                child = render.Row(
                    children = [
                        render_graph_column(config, current_value, points, unit),
                        render_stats_column(stats, unit),
                    ],
                ),
                width = 107,
                duration = 100,
                delay = 100,
                keyframes = [
                    animation.Keyframe(percentage = 0.0, transforms = [animation.Translate(0, 0)]),
                    animation.Keyframe(curve = "ease_in", percentage = 0.2, transforms = [animation.Translate(-43, 0)]),
                    animation.Keyframe(curve = "ease_in", percentage = 1.0, transforms = [animation.Translate(-43, 0)]),
                ],
            ),
        )
    else:
        return render.Root(
            child = render_graph_column(config, current_value, points, unit),
        )

def render_graph_column(config, current_value, points, unit):
    return render.Column(
        children = [
            render.Box(
                child = render.Row(
                    children = [
                        render.Box(
                            child = render.Image(src = get_icon(config), width = 10, height = 10),
                            width = 12,
                            height = 12,
                        ),
                        render.Text(content = current_value + unit, font = "6x13"),
                    ],
                    expanded = True,
                    cross_align = "center",
                    main_align = "end",
                ),
                width = 64,
                height = 13,
            ),
            render.Plot(
                data = points,
                width = 64,
                height = 18,
                color = config.str("line_positive", DEFAULT_COLOURS["line_positive"]),
                color_inverted = config.str("line_negative", DEFAULT_COLOURS["line_negative"]),
                fill_color = config.str("fill_positive", DEFAULT_COLOURS["fill_positive"]),
                fill_color_inverted = config.str("fill_negative", DEFAULT_COLOURS["fill_negative"]),
                fill = True,
            ),
        ],
    )

def render_stats_column(stats, unit):
    return render.Column(
        children = [
            render.Row(
                children = [
                    render.Box(width = 1),
                    render.Box(color = "#525252", width = 1),
                    render.Box(width = 1),
                    render.Column(
                        children = [
                            render.Text(content = "Low " + stats["lowest_time"], font = "CG-pixel-3x5-mono"),
                            render.Text(content = stats["lowest_value"] + unit, font = "tom-thumb", color = "#b5a962"),
                            render.Text(content = "High " + stats["highest_time"], font = "CG-pixel-3x5-mono"),
                            render.Text(content = stats["highest_value"] + unit, font = "tom-thumb", color = "#b5a962"),
                            render.Text(content = "Average", font = "CG-pixel-3x5-mono"),
                            render.Text(content = stats["average"] + unit, font = "tom-thumb", color = "#b5a962"),
                        ],
                    ),
                ],
            ),
        ],
        expanded = True,
    )

def render_error_message(message):
    return render.Root(
        child = render.Column(
            children = [
                render.Box(child = render.Image(src = ICONS["ha"], width = 15, height = 15), height = 15),
                render.WrappedText(
                    align = "center",
                    font = "tom-thumb",
                    content = message,
                    color = "#FF0000",
                    width = 64,
                ),
            ],
        ),
    )

def get_schema():
    icons = [
        schema.Option(
            display = "Raindrop",
            value = "drop",
        ),
        schema.Option(
            display = "Thermometer",
            value = "thermometer",
        ),
        schema.Option(
            display = "Wind",
            value = "wind",
        ),
        schema.Option(
            display = "Car",
            value = "car",
        ),
        schema.Option(
            display = "Home Assistant Icon",
            value = "ha",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ha_instance",
                desc = "Home Assistant URL. The address of your HomeAssistant instance, as a full URL.",
                icon = "globe",
                name = "Home Assistant URL",
            ),
            schema.Text(
                id = "ha_token",
                desc = "Home Assistant token. Navigate to User Settings > Long-lived access tokens.",
                icon = "key",
                name = "Home Assistant Token",
                secret = True,
            ),
            schema.Text(
                id = "ha_entity",
                desc = "Entity name of the sensor to display, e.g. 'sensor.temperature'.",
                icon = "ruler",
                name = "Entity name",
            ),
            schema.Text(
                id = "time_period",
                default = "24",
                desc = "In hours, how far back to look for data. Enter a number from 2 to %s." % str(MAX_TIME_PERIOD),
                icon = "timeline",
                name = "Time period",
            ),
            schema.Toggle(
                id = "show_history",
                name = "Display historical values",
                desc = "Show the highest, lowest and average values",
                icon = "list",
                default = True,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                icon = "locationDot",
                desc = "Location for which to display time",
            ),
            schema.Dropdown(
                id = "icon",
                default = icons[0].value,
                desc = "Icon to display for the entity.",
                icon = "icons",
                name = "Icon",
                options = icons,
            ),
            schema.Color(
                id = "line_positive",
                default = DEFAULT_COLOURS["line_positive"],
                desc = "Colour of the graph line for positive values.",
                icon = "chartLine",
                name = "Graph line for positive values",
            ),
            schema.Color(
                id = "line_negative",
                default = DEFAULT_COLOURS["line_negative"],
                desc = "Colour of the graph line for negative values.",
                icon = "chartLine",
                name = "Graph line for negative values",
            ),
            schema.Color(
                id = "fill_positive",
                default = DEFAULT_COLOURS["fill_positive"],
                desc = "Fill colour of the graph for positive values.",
                icon = "chartLine",
                name = "Fill colour for positive values",
            ),
            schema.Color(
                id = "fill_negative",
                default = DEFAULT_COLOURS["fill_negative"],
                desc = "Fill colour of the graph for negative values.",
                icon = "chartLine",
                name = "Fill colour for negative values",
            ),
        ],
    )
