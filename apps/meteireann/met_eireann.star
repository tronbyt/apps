load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/icon_drizzlesun.png", ICON_DRIZZLESUN_ASSET = "file")
load("images/icon_fog.png", ICON_FOG_ASSET = "file")
load("images/icon_lightrainsun.png", ICON_LIGHTRAINSUN_ASSET = "file")
load("images/icon_sleet.png", ICON_SLEET_ASSET = "file")
load("images/thumb_cloud.png", THUMB_CLOUD_ASSET = "file")
load("images/thumb_drizzle.png", THUMB_DRIZZLE_ASSET = "file")
load("images/thumb_fog.png", THUMB_FOG_ASSET = "file")
load("images/thumb_lightcloud.png", THUMB_LIGHTCLOUD_ASSET = "file")
load("images/thumb_lightrain.png", THUMB_LIGHTRAIN_ASSET = "file")
load("images/thumb_lightrainsun.png", THUMB_LIGHTRAINSUN_ASSET = "file")
load("images/thumb_partlycloud.png", THUMB_PARTLYCLOUD_ASSET = "file")
load("images/thumb_rain.png", THUMB_RAIN_ASSET = "file")
load("images/thumb_sleet.png", THUMB_SLEET_ASSET = "file")
load("images/thumb_snow.png", THUMB_SNOW_ASSET = "file")
load("images/thumb_sun.png", THUMB_SUN_ASSET = "file")
load("images/thumb_thunder.png", THUMB_THUNDER_ASSET = "file")
load("images/wind_e.png", WIND_E_ASSET = "file")
load("images/wind_n.png", WIND_N_ASSET = "file")
load("images/wind_ne.png", WIND_NE_ASSET = "file")
load("images/wind_nw.png", WIND_NW_ASSET = "file")
load("images/wind_s.png", WIND_S_ASSET = "file")
load("images/wind_se.png", WIND_SE_ASSET = "file")
load("images/wind_sw.png", WIND_SW_ASSET = "file")
load("images/wind_w.png", WIND_W_ASSET = "file")
load("math.star", "math")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("xpath.star", "xpath")

def main(config):
    location = json.decode(config.get("location", DEFAULT_LOCATION))
    hourly, daily, error = fetch_forecast(location)
    if error:
        return render.Root(render.WrappedText(color = "#5c0800", content = error))

    return render.Root(
        child = animation.Transformation(
            child = render_today(location, hourly, daily, config),
            duration = 260,
            delay = 50,
            height = 96,
            keyframes = [
                animation.Keyframe(percentage = 0.0, transforms = [animation.Translate(0, 0)]),
                animation.Keyframe(curve = "ease_in_out", percentage = 0.03, transforms = [animation.Translate(0, -32)]),
                animation.Keyframe(percentage = 0.5, transforms = [animation.Translate(0, -32)]),
                animation.Keyframe(curve = "ease_in_out", percentage = 0.53, transforms = [animation.Translate(0, -64)]),
                animation.Keyframe(percentage = 1.0, transforms = [animation.Translate(0, -64)]),
            ],
            width = 64,
        ),
    )

def consolidate_hours(hourly_forecasts):
    consolidated_forecasts = {}
    for entry in hourly_forecasts:
        hour = entry["hour"]
        if hour not in consolidated_forecasts:
            consolidated_forecasts[hour] = {}

        if entry["precipitation"] != None:
            consolidated_forecasts[hour]["precipitation"] = entry["precipitation"]
        if entry["temperature"] != None:
            consolidated_forecasts[hour]["temperature"] = entry["temperature"]
        if entry["weather_symbol"] != None:
            consolidated_forecasts[hour]["weather_symbol"] = entry["weather_symbol"]
        if entry["wind_speed"] != None:
            consolidated_forecasts[hour]["wind_speed"] = entry["wind_speed"]
        if entry["wind_direction"] != None:
            consolidated_forecasts[hour]["wind_direction"] = entry["wind_direction"]

    consolidated_forecasts = {hour: data for hour, data in consolidated_forecasts.items() if "temperature" in data and "weather_symbol" in data}

    return consolidated_forecasts

def convert_to_12_hour(hour):
    if hour == 0:
        return "12", "AM"
    elif hour == 12:
        return "12", "PM"
    elif int(hour) > 12:
        return str(int(hour) - 12), "PM"
    return str(hour), "AM"

def daily_forecast(time_nodes, location):
    daily_forecasts = []
    current_date = None
    day_temperature_sum = 0.0
    day_temperature_count = 0
    day_wind_speed_sum = 0.0
    wind_direction_values = []
    weather_symbols = []

    rain_total = rain_totals(time_nodes)
    sorted_time_nodes = filter_nodes(time_nodes, location)
    for node in sorted_time_nodes:
        from_time = node.query("@from")
        date = from_time.split("T")[0]

        if current_date == None:
            current_date = date
        elif date != current_date:
            avg_temperature = math.round(day_temperature_sum / day_temperature_count) if day_temperature_count > 0 else None
            avg_wind_speed = int(math.round(day_wind_speed_sum / day_temperature_count)) if day_temperature_count > 0 else None
            mode_wind_dir = mode(wind_direction_values) if wind_direction_values else None
            mode_weather_sym = mode(weather_symbols) if weather_symbols else None
            rain_total_rounded = math.round(rain_total.get(current_date, 0.0) * 10) / 10.0

            daily_forecasts.append({
                "date": current_date,
                "rain_total": rain_total_rounded,
                "temperature": avg_temperature,
                "wind_speed": avg_wind_speed,
                "wind_direction": mode_wind_dir,
                "weather_symbol": mode_weather_sym,
            })

            current_date = date
            day_temperature_sum = 0.0
            day_temperature_count = 0
            day_wind_speed_sum = 0.0
            wind_direction_values = []
            weather_symbols = []

        _, temperature_value, weather_symbol, wind_speed_value, wind_direction_value = get_values(node)
        if temperature_value != None:
            day_temperature_sum += temperature_value
            day_temperature_count += 1
        if wind_speed_value != None:
            day_wind_speed_sum += wind_speed_value
        if wind_direction_value != None:
            wind_direction_values.append(wind_direction_value)
        if weather_symbol != None:
            weather_symbols.append(weather_symbol)

    avg_temperature = math.round(day_temperature_sum / day_temperature_count) if day_temperature_count > 0 else None
    avg_wind_speed = math.round(day_wind_speed_sum / day_temperature_count) if day_temperature_count > 0 else None
    mode_wind_dir = mode(wind_direction_values) if wind_direction_values else None
    mode_weather_sym = mode(weather_symbols) if weather_symbols else None

    daily_forecasts.append({
        "date": current_date,
        "rain_total": rain_total.get(current_date, 0.0),
        "temperature": avg_temperature,
        "wind_speed": avg_wind_speed,
        "wind_direction": mode_wind_dir,
        "weather_symbol": mode_weather_sym,
    })

    return (daily_forecasts)

def fetch_forecast(location):
    url = get_forecast_url(location)
    rep = http.get(url, ttl_seconds = 900)
    if rep.status_code != 200:
        return [], [], "Error fetching forecast: " + str(rep.status_code)

    return parse_weather_data(rep.body(), location)

def filter_nodes(time_nodes, location):
    now = time.now().in_location(location["timezone"])
    today_str = now.format("2006-01-02")
    filtered_time_nodes = [
        node
        for node in time_nodes
        if node.query("@from").split("T")[0] > today_str and (
            (6 <= int(node.query("@from").split("T")[1][:2])) and (int(node.query("@from").split("T")[1][:2]) <= 12) or
            (12 <= int(node.query("@from").split("T")[1][:2])) and (int(node.query("@from").split("T")[1][:2]) <= 18)
        )
    ]
    return sorted(filtered_time_nodes, key = lambda node: node.query("@from"))

def format_weekday(date_str):
    parsed_time = time.parse_time(date_str, "2006-01-02")
    formatted_weekday = parsed_time.format("Mon")
    return formatted_weekday

def get_forecast_url(location):
    return MET_EIREANN_URL.format(lat = location["lat"], long = location["lng"])

def get_image_for_condition(condition, width, height, thumbnail = False):
    iconset = THUMBNAILS if thumbnail else ICONS
    patterns = {
        "Snow": re.compile(r"(?i)snow"),
        "Sleet": re.compile(r"(?i)sleet"),
        "Thunder": re.compile(r"(?i)thunder"),
    }

    icon = None
    for key, pattern in patterns.items():
        if pattern.search(condition):
            icon = iconset.get(key)
            break

    if condition == "RainSun":
        icon = iconset["LightRainSun"]

    if icon == None:
        icon = iconset.get(condition, ICONS["Fallback"])
        if icon == ICONS["Fallback"]:
            print("Unknown weather condition: " + condition)

    return render.Image(
        src = base64.decode(icon),
        width = width,
        height = height,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display forecast.",
                icon = "locationDot",
            ),
            schema.Color(
                id = "warm-colour",
                default = "#f59542",
                desc = "Colour for warmer temperatures (above 10).",
                icon = "brush",
                name = "Warm Colour",
            ),
            schema.Color(
                id = "cold-colour",
                default = "#84c2f5",
                desc = "Colour for colder temperatures (10 or below).",
                icon = "brush",
                name = "Cold colour",
            ),
        ],
    )

def get_values(time_node):
    precipitation = time_node.query("location/precipitation/@value")
    temperature = time_node.query("location/temperature/@value")
    weather_symbol = time_node.query("location/symbol/@id")
    wind_speed = time_node.query("location/windSpeed/@mps")
    wind_direction = time_node.query("location/windDirection/@deg")

    precipitation_value = precipitation if precipitation else None
    temperature_value = math.round(float(temperature)) if temperature else None
    weather_symbol_id = weather_symbol if weather_symbol else None
    wind_speed_value = int(math.round(float(wind_speed) * 3.6)) if wind_speed else None
    wind_direction_value = float(wind_direction) if wind_direction else None

    return precipitation_value, temperature_value, weather_symbol_id, wind_speed_value, wind_direction_value

def get_wind_icon(degrees, width, height):
    dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW", "N"]
    ix = int((degrees * len(dirs) + 180) // 360)
    cardinal = dirs[ix % len(dirs)]
    return render.Image(
        src = WIND_ICONS.get(cardinal),
        width = width,
        height = height,
    )

def hourly_forecast(time_nodes):
    sorted_time_nodes = sorted(time_nodes, key = lambda node: node.query("@from"))
    hourly_forecasts = []

    # Get the next 7 hours (two nodes per hour, skipping the first)
    for i in range(min(15, len(sorted_time_nodes))):
        time_node = sorted_time_nodes[i]
        from_time = time_node.query("@from")
        hour = from_time.split("T")[1][:2]

        precipitation_value, temperature_value, weather_symbol_id, wind_speed_value, wind_direction_value = get_values(time_node)

        hourly_forecasts.append({
            "hour": hour,
            "precipitation": precipitation_value,
            "temperature": temperature_value,
            "weather_symbol": weather_symbol_id,
            "wind_speed": wind_speed_value,
            "wind_direction": wind_direction_value,
        })

    return consolidate_hours(hourly_forecasts)

def mode(data_list):
    if not data_list:
        return None

    counts = {}
    for item in data_list:
        if item in counts:
            counts[item] += 1
        else:
            counts[item] = 1

    mode_item = max(counts, key = counts.get)
    return mode_item

def parse_weather_data(data, location):
    x = xpath.loads(data)
    time_nodes = x.query_all_nodes("//time")
    return hourly_forecast(time_nodes), daily_forecast(time_nodes, location), None

def rain_totals(time_nodes):
    rain_totals = {}
    for node in time_nodes:
        from_time = node.query("@from")
        date = from_time.split("T")[0]
        precipitation = node.query("location/precipitation/@value")
        if date not in rain_totals:
            rain_totals[date] = 0.0
        if precipitation:
            rain_totals[date] += float(precipitation)
    return rain_totals

def render_blocks(forecast, config, is_hourly = True):
    blocks = []
    items = (forecast)
    days_rendered = 0
    if is_hourly:
        items = list(forecast.keys())[1:]

    for item in items:
        if days_rendered >= 6:
            break

        if is_hourly:
            precipitation = forecast[item]["precipitation"]
            temperature = forecast[item]["temperature"]
            condition = forecast[item]["weather_symbol"]
            wind_speed = forecast[item]["wind_speed"]
            wind_direction = forecast[item]["wind_direction"]
            hour_label, am_pm = convert_to_12_hour(item)
            label = render.Box(
                child = render.Row(
                    children = [
                        render.Text(content = hour_label, font = "CG-pixel-3x5-mono"),
                        render.Text(color = "#827d7d", content = am_pm, font = "CG-pixel-3x5-mono"),
                    ],
                    main_align = "center",
                ),
                height = 5,
                width = 21,
            )
        else:
            days_rendered += 1
            precipitation = item["rain_total"]
            temperature = item["temperature"]
            condition = item["weather_symbol"]
            wind_speed = item["wind_speed"]
            wind_direction = item["wind_direction"]
            label = render.Box(
                child = render.Text(
                    content = format_weekday(item["date"]),
                    font = "CG-pixel-3x5-mono",
                ),
                height = 5,
                width = 21,
            )
        colour_temperature = config.get("warm-colour", "#f59542") if temperature > 10 else config.get("cold-colour", "#4a90e2")
        image = get_image_for_condition(condition, 8, 8, True)
        spacer = None
        if item != items[-1]:
            spacer = render.Box(
                color = "#827d7d",
                width = 1,
                height = 32,
            )

        blocks.append(
            render.Row(
                children = [
                    render.Column(
                        children = [
                            label,
                            image,
                            render.Text(
                                color = colour_temperature,
                                content = str(int(temperature)) + "°C",
                                font = "tom-thumb",
                                height = 7,
                            ),
                            render.Row(
                                children = [
                                    render.Text(
                                        content = str(wind_speed),
                                        font = "tom-thumb",
                                        height = 6,
                                    ),
                                    get_wind_icon(wind_direction, 5, 5),
                                ],
                            ),
                            render.Row(
                                children = [
                                    render.Text(
                                        content = str(precipitation),
                                        height = 7,
                                    ),
                                ],
                            ),
                        ],
                        cross_align = "center",
                    ),
                    spacer,
                ],
            ),
        )

    return render.Row(
        children = blocks,
        expanded = True,
    )

def render_today(location, hourly, daily, config):
    keys = hourly.keys()
    current_rain = hourly[keys[0]]["precipitation"]
    current_temperature = hourly[keys[0]]["temperature"]
    current_condition = hourly[keys[0]]["weather_symbol"]
    current_wind_speed = hourly[keys[0]]["wind_speed"]
    current_wind_direction = hourly[keys[0]]["wind_direction"]
    image = get_image_for_condition(current_condition, 22, 22)
    colour_temperature = config.get("warm-colour", "#f59542") if current_temperature > 10 else config.get("cold-colour", "#84c2f5")
    hourly_row = render_blocks(hourly, config)
    daily_row = render_blocks(daily, config, False)
    return render.Column(
        children = [
            render.Box(
                child = render.Row(
                    main_align = "space_between",
                    children = [
                        image,
                        render.Column(
                            children = [
                                render.Text(
                                    content = location["locality"],
                                    font = "tom-thumb",
                                    height = 7,
                                ),
                                render.Text(
                                    color = colour_temperature,
                                    content = str(int(current_temperature)) + " °C",
                                    font = "tom-thumb",
                                ),
                                render.Row(
                                    children = [
                                        render.Text(
                                            content = str(current_wind_speed) + " km/h",
                                            font = "tom-thumb",
                                            height = 7,
                                        ),
                                        get_wind_icon(current_wind_direction, 7, 7),
                                    ],
                                    expanded = True,
                                    main_align = "end",
                                ),
                                render.Row(
                                    children = [
                                        render.Image(
                                            src = base64.decode(ICONS.get("Drop")),
                                            width = 7,
                                            height = 7,
                                        ),
                                        render.Text(
                                            content = str(current_rain) + " mm",
                                            font = "tom-thumb",
                                            height = 7,
                                        ),
                                    ],
                                    expanded = True,
                                    main_align = "end",
                                ),
                            ],
                            cross_align = "end",
                        ),
                    ],
                    cross_align = "center",
                ),
                height = 32,
            ),
            animation.Transformation(
                child = hourly_row,
                duration = 190,
                delay = 120,
                height = 32,
                keyframes = [
                    animation.Keyframe(percentage = 0.0, transforms = [animation.Translate(0, 0)]),
                    animation.Keyframe(curve = "ease_in_out", percentage = 0.0258, transforms = [animation.Translate(-66, 0)]),
                    animation.Keyframe(percentage = 1.0, transforms = [animation.Translate(-66, 0)]),
                ],
                width = 128,
            ),
            animation.Transformation(
                child = daily_row,
                duration = 70,
                delay = 240,
                height = 32,
                keyframes = [
                    animation.Keyframe(percentage = 0.0, transforms = [animation.Translate(0, 0)]),
                    animation.Keyframe(curve = "ease_in_out", percentage = 0.07, transforms = [animation.Translate(-66, 0)]),
                    animation.Keyframe(percentage = 1.0, transforms = [animation.Translate(-66, 0)]),
                ],
                width = 128,
            ),
        ],
        expanded = True,
    )

DEFAULT_LOCATION = """
{
  "lat": 51.890901,
  "lng": -8.467712,
  "locality": "Cork",
  "timezone": "Europe/Dublin"
}
"""
ICONS = {
    "Cloud": "PHN2ZyB2ZXJzaW9uPSIxLjEiIGlkPSJMYXllcl8xIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiB2aWV3Qm94PSIwIDAgNTEyIDUxMiIgeG1sOnNwYWNlPSJwcmVzZXJ2ZSIgZmlsbD0iIzAwMDAwMCI+PGcgaWQ9IlNWR1JlcG9fYmdDYXJyaWVyIiBzdHJva2Utd2lkdGg9IjAiPjwvZz48ZyBpZD0iU1ZHUmVwb190cmFjZXJDYXJyaWVyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjwvZz48ZyBpZD0iU1ZHUmVwb19pY29uQ2FycmllciI+IDxwb2x5Z29uIHN0eWxlPSJmaWxsOiNFNkU2RTY7IiBwb2ludHM9IjQ3OC42MDksMjY3LjEzIDQ3OC42MDksMjMzLjczOSA0NDUuMjE3LDIzMy43MzkgNDQ1LjIxLDIwMC4zNDggMzg5LjU2NSwyMDAuMzQ4IDM4OS41NTcsMTIyLjQzNSAzNTYuMTY2LDEyMi40MzUgMzU2LjE2Niw4OS4wNDMgMzIyLjc4Myw4OS4wNDMgMzIyLjc4Myw1NS42NTIgMTg5LjIxNyw1NS42NTIgMTg5LjIxNyw4OS4wNDMgMTU1LjgyNiw4OS4wNDMgMTU1LjgyNiwxMjIuNDM1IDEyMi40MzUsMTIyLjQzNSAxMjIuNDM1LDIwMC4zNDggNjYuNzc1LDIwMC4zNDggNjYuNzc1LDIzMy43MzkgMzMuMzkxLDIzMy43MzkgMzMuMzkxLDI2Ny4xMyAzMy4zODQsMjY3LjEzIDMzLjM4NCwyNjcuMTMgMCwyNjcuMTMgMCwzMDAuNTIyIDAsMzAwLjUyNSAwLDM4OS41NjUgMzMuMzkxLDM4OS41NjUgMzMuMzkxLDQyMi45NTcgNjYuNzgzLDQyMi45NTcgNjYuNzgzLDQ1Ni4zNDggMzU2LjE3NCw0NTYuMzQ4IDQ0NS4yMSw0NTYuMzQ4IDQ0NS4yMTcsNDU2LjM0OCA0NDUuMjE3LDQyMi45NTcgNDc4LjYwOSw0MjIuOTU3IDQ3OC42MDksMzg5LjU2NSA1MTIsMzg5LjU2NSA1MTIsMzAwLjUyMiA1MTIsMjY3LjEzICI+PC9wb2x5Z29uPiA8cmVjdCB4PSIxNTUuODI2IiB5PSI4OS4wNDMiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjMyMi43ODMiIHk9IjIzMy43MzkiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjMzLjM5MSIgeT0iMzg5LjU2NSIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iMTg5LjIxNyIgeT0iNTUuNjUyIiB3aWR0aD0iMTMzLjU2NSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHBvbHlnb24gcG9pbnRzPSIxMjIuNDM1LDIzMy43MzkgMTU1LjgyNiwyMzMuNzM5IDE1NS44MjYsMjY3LjEzIDE4OS4yMTcsMjY3LjEzIDE4OS4yMTcsMjMzLjczOSAxNTUuODI2LDIzMy43MzkgMTU1LjgyNiwyMDAuMzQ4IDE1NS44MjYsMTIyLjQzNSAxMjIuNDM1LDEyMi40MzUgMTIyLjQzNSwyMDAuMzQ4IDY2Ljc4MywyMDAuMzQ4IDY2Ljc4MywyMzMuNzM5ICI+PC9wb2x5Z29uPiA8cG9seWdvbiBwb2ludHM9IjMzLjM5MSwyNjcuMTMgNjYuNzgzLDI2Ny4xMyA2Ni43ODMsMjMzLjczOSAzMy4zOTEsMjMzLjczOSAzMy4zOTEsMjY3LjEzIDAsMjY3LjEzIDAsMzg5LjU2NSAzMy4zOTEsMzg5LjU2NSAiPjwvcG9seWdvbj4gPHBvbHlnb24gcG9pbnRzPSIzODkuNTY1LDIwMC4zNDggMzg5LjU2NSwxMjIuNDM1IDM1Ni4xNzQsMTIyLjQzNSAzNTYuMTc0LDg5LjA0MyAzMjIuNzgzLDg5LjA0MyAzMjIuNzgzLDEyMi40MzUgMzU2LjE3NCwxMjIuNDM1IDM1Ni4xNzQsMjAwLjM0OCAzNTYuMTc0LDIzMy43MzkgMzU2LjE3NCwyMzMuNzM5IDQ0NS4yMTcsMjMzLjczOSA0NDUuMjE3LDIwMC4zNDggIj48L3BvbHlnb24+IDxyZWN0IHg9IjQ0NS4yMTciIHk9IjM4OS41NjUiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjQ0NS4yMTciIHk9IjIzMy43MzkiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjQ3OC42MDkiIHk9IjI2Ny4xMyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIxMjIuNDM1Ij48L3JlY3Q+IDxyZWN0IHg9IjY2Ljc4MyIgeT0iNDIyLjk1NyIgd2lkdGg9IjM3OC40MzUiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDwvZz48L3N2Zz4K",
    "Drizzle": "CjxzdmcgdmVyc2lvbj0iMS4xIiBpZD0iTGF5ZXJfMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczp4bGluaz0iaHR0cDovL3d3dy53My5vcmcvMTk5OS94bGluayIgdmlld0JveD0iMCAwIDUxMiA1MTIiIHhtbDpzcGFjZT0icHJlc2VydmUiIGZpbGw9IiMwMDAwMDAiPjxnIGlkPSJTVkdSZXBvX2JnQ2FycmllciIgc3Ryb2tlLXdpZHRoPSIwIj48L2c+PGcgaWQ9IlNWR1JlcG9fdHJhY2VyQ2FycmllciIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIj48L2c+PGcgaWQ9IlNWR1JlcG9faWNvbkNhcnJpZXIiPiA8Zz4gPHJlY3QgeD0iNTUuNjUyIiB5PSI0MTEuODI2IiBzdHlsZT0iZmlsbDojMDA2REYwOyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iMTc4LjA4NyIgeT0iNDExLjgyNiIgc3R5bGU9ImZpbGw6IzAwNkRGMDsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjI4OS4zOTEiIHk9IjQxMS44MjYiIHN0eWxlPSJmaWxsOiMwMDZERjA7IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSI0MjIuOTU3IiB5PSI0MTEuODI2IiBzdHlsZT0iZmlsbDojMDA2REYwOyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeT0iNDc4LjYwOSIgc3R5bGU9ImZpbGw6IzAwNkRGMDsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjIzMy43MzkiIHk9IjQ3OC42MDkiIHN0eWxlPSJmaWxsOiMwMDZERjA7IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSIxMjIuNDM1IiB5PSI0NzguNjA5IiBzdHlsZT0iZmlsbDojMDA2REYwOyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iMzU2LjE3NCIgeT0iNDc4LjYwOSIgc3R5bGU9ImZpbGw6IzAwNkRGMDsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjQ3OC42MDkiIHk9IjQ3OC42MDkiIHN0eWxlPSJmaWxsOiMwMDZERjA7IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8L2c+IDxwb2x5Z29uIHN0eWxlPSJmaWxsOiM4OTg4OTA7IiBwb2ludHM9IjQ3OC42MDksMTg5LjIxNCA0NzguNjA5LDE1NS44MjMgNDQ1LjIxNywxNTUuODIzIDQ0NS4yMSwxNTUuODIzIDQ0NS4yMTcsMTIyLjcxMyAzODkuNTU3LDEyMi43MTMgMzg5LjU1Nyw2Ni43ODMgMzU2LjE2Niw2Ni43ODMgMzU2LjE2NiwzMy4zOTEgMzIyLjc4MywzMy4zOTEgMzIyLjc4MywwIDE4OS4yMTcsMCAxODkuMjE3LDMzLjM5MSAxNTUuODI2LDMzLjM5MSAxNTUuODI2LDY2Ljc4MyAxMjIuNDM1LDY2Ljc4MyAxMjIuNDM1LDEyMi40MzUgNjYuNzc1LDEyMi40MzUgNjYuNzc1LDE1NS44MjMgMzMuMzkxLDE1NS44MjMgMzMuMzkxLDE4OS4yMTQgMzMuMzg0LDE4OS4yMTQgMzMuMzg0LDE4OS4yMTQgMCwxODkuMjE0IDAsMjIyLjYwNSAwLDIyMi42MDkgMCwyNzguMjYxIDMzLjM5MSwyNzguMjYxIDMzLjM5MSwzMTEuNjUyIDY2Ljc4MywzMTEuNjUyIDY2Ljc4MywzNDUuMDQzIDM1Ni4xNzQsMzQ1LjA0MyA0NDUuMjEsMzQ1LjA0MyA0NDUuMjE3LDM0NS4wNDMgNDQ1LjIxNywzMTEuNjUyIDQ3OC42MDksMzExLjY1MiA0NzguNjA5LDI3OC4yNjEgNTEyLDI3OC4yNjEgNTEyLDIyMi42MDUgNTEyLDE4OS4yMTQgIj48L3BvbHlnb24+IDxyZWN0IHg9IjE1NS44MjYiIHk9IjMzLjM5MSIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iMzMuMzkxIiB5PSIxNTUuODI2IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cG9seWdvbiBwb2ludHM9IjMzLjM5MSwyNzguMjYxIDMzLjM5MSwxODkuMjE3IDAsMTg5LjIxNyAwLDI3OC4yNjEgMzMuMzkxLDI3OC4yNjEgMzMuMzkxLDMxMS42NTIgNjYuNzgzLDMxMS42NTIgNjYuNzgzLDI3OC4yNjEgIj48L3BvbHlnb24+IDxyZWN0IHg9IjE4OS4yMTciIHdpZHRoPSIxMzMuNTY1IiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cG9seWdvbiBwb2ludHM9IjEyMi40MzUsMTU1LjgyNiAxNTUuODI2LDE1NS44MjYgMTU1LjgyNiwxODkuMjE3IDE4OS4yMTcsMTg5LjIxNyAxODkuMjE3LDE1NS44MjYgMTU1LjgyNiwxNTUuODI2IDE1NS44MjYsMTIyLjQzNSAxNTUuODI2LDY2Ljc4MyAxMjIuNDM1LDY2Ljc4MyAxMjIuNDM1LDEyMi40MzUgNjYuNzgzLDEyMi40MzUgNjYuNzgzLDE1NS44MjYgIj48L3BvbHlnb24+IDxwb2x5Z29uIHBvaW50cz0iNDc4LjYwOSwxODkuMjE3IDQ3OC42MDksMjc4LjI2MSA0NDUuMjE3LDI3OC4yNjEgNDQ1LjIxNywzMTEuNjUyIDQ3OC42MDksMzExLjY1MiA0NzguNjA5LDI3OC4yNjEgNTEyLDI3OC4yNjEgNTEyLDE4OS4yMTcgIj48L3BvbHlnb24+IDxyZWN0IHg9IjY2Ljc4MyIgeT0iMzExLjY1MiIgd2lkdGg9IjM3OC40MzUiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxwb2x5Z29uIHBvaW50cz0iMzU2LjE3NCw2Ni43ODMgMzU2LjE3NCwxMjIuNDM1IDM1Ni4xNzQsMTU1LjgyNiAzNTYuMTc0LDE1NS44MjYgNDQ1LjIxNywxNTUuODI2IDQ0NS4yMTcsMTIyLjQzNSAzODkuNTY1LDEyMi40MzUgMzg5LjU2NSw2Ni43ODMgMzU2LjE3NCw2Ni43ODMgMzU2LjE3NCwzMy4zOTEgMzIyLjc4MywzMy4zOTEgMzIyLjc4Myw2Ni43ODMgIj48L3BvbHlnb24+IDxyZWN0IHg9IjQ0NS4yMTciIHk9IjE1NS44MjYiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjMyMi43ODMiIHk9IjE1NS44MjYiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDwvZz48L3N2Zz4K",
    "DrizzleSun": ICON_DRIZZLESUN_ASSET.readall(),
    "Drop": "PHN2ZyB2ZXJzaW9uPSIxLjEiIGlkPSJMYXllcl8xIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiB2aWV3Qm94PSIwIDAgNTEyLjAwNCA1MTIuMDA0IiB4bWw6c3BhY2U9InByZXNlcnZlIiBmaWxsPSIjMDAwMDAwIj48ZyBpZD0iU1ZHUmVwb19iZ0NhcnJpZXIiIHN0cm9rZS13aWR0aD0iMCI+PC9nPjxnIGlkPSJTVkdSZXBvX3RyYWNlckNhcnJpZXIiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIgc3Ryb2tlLWxpbmVqb2luPSJyb3VuZCI+PC9nPjxnIGlkPSJTVkdSZXBvX2ljb25DYXJyaWVyIj4gPHBvbHlnb24gc3R5bGU9ImZpbGw6I0ZGRkZGRjsiIHBvaW50cz0iNDExLjgyNywyNjcuMTI3IDQxMS44MjcsMjAwLjM0NSA0MTEuODI3LDIwMC4zNDUgMzc4LjQzNiwyMDAuMzQ1IDM3OC40MzYsMTMzLjU2MyAzNzguNDM2LDEzMy41NjMgMzQ1LjA0NSwxMzMuNTYzIDM0NS4wNDUsNjYuNzgyIDM0NS4wNDUsNjYuNzgyIDMxMS42NTUsNjYuNzgyIDMxMS42NTUsMzMuMzkxIDMxMS42NTQsMzMuMzkxIDMxMS42NTQsMzMuMzkxIDI3OC4yNjQsMzMuMzkxIDI3OC4yNjQsMCAyNzguMjYzLDAgMjMzLjc0MywwIDIzMy43NDIsMCAyMzMuNzQyLDMzLjM5MSAyMDAuMzUyLDMzLjM5MSAyMDAuMzUyLDMzLjM5MSAyMDAuMzUxLDMzLjM5MSAyMDAuMzUxLDY2Ljc4MiAxNjYuOTYyLDY2Ljc4MiAxNjYuOTYsNjYuNzgyIDE2Ni45NiwxMzMuNTYzIDEzMy41NzEsMTMzLjU2MyAxMzMuNTcsMTMzLjU2MyAxMzMuNTcsMjAwLjM0NSAxMDAuMTgsMjAwLjM0NSAxMDAuMTc5LDIwMC4zNDUgMTAwLjE3OSwyNjcuMTI3IDY2Ljc4OCwyNjcuMTI3IDY2Ljc4OCwyNjcuMTI3IDY2Ljc4OCw0MTEuODIxIDY2Ljc4OCw0MTEuODIxIDEwMC4xNzksNDExLjgyMSAxMDAuMTc5LDQxMS44MjEgMTAwLjE3OSw0NDUuMjEyIDEwMC4xOCw0NDUuMjEyIDEzMy41NjYsNDQ1LjIxMiAxMzMuNTY2LDQ3OC42MDEgMTMzLjU3LDQ3OC42MDEgMTMzLjU3LDQ3OC42MDIgMTY2Ljk2LDQ3OC42MDIgMTY2Ljk2LDQ3OC42MDEgMTY2Ljk3Nyw0NzguNjAxIDE2Ni45NzcsNTEyIDIwMC4zNSw1MTIgMzExLjY1NSw1MTIgMzQ1LjAyOCw1MTIgMzQ1LjAyOCw0NzguNjAxIDM0NS4wNDUsNDc4LjYwMSAzNDUuMDQ1LDQ3OC42MDIgMzc4LjQzNiw0NzguNjAyIDM3OC40MzYsNDc4LjYwMSAzNzguNDM5LDQ3OC42MDEgMzc4LjQzOSw0NDUuMjEyIDQxMS44MjcsNDQ1LjIxMiA0MTEuODI3LDQ0NS4yMTIgNDExLjgyNyw0MTEuODIxIDQxMS44MjgsNDExLjgyMSA0NDUuMjE4LDQxMS44MjEgNDQ1LjIxOCw0MTEuODIxIDQ0NS4yMTgsMjY3LjEyNyA0NDUuMjE4LDI2Ny4xMjcgIj48L3BvbHlnb24+IDxyZWN0IHg9IjEwMC4xNzUiIHk9IjIwMC4zNDUiIHN0eWxlPSJmaWxsOiMwMDZERjA7IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjY2Ljc4MiI+PC9yZWN0PiA8cGF0aCBzdHlsZT0iZmlsbDojNTdBNEZGOyIgZD0iTTY2Ljc4OCw0MTEuODIxaDMzLjM5MWwwLDBsMCwwdjMzLjM5MWgzMy4zOTFoMC4wMDNoLTAuMDAzdjMzLjM5MWgzMy4zOTF2LTAuMDAxaDAuMDAxVjUxMmgxNzguMDY4IHYtMzMuMzk5aDMzLjQxMXYtMzMuMzloMzMuMzg4di0zMy4zOTFoMzMuMzkyVjI2Ny4xMjdoLTMzLjM5MnYtNjYuNzgyaC0zMy4zOTF2LTY2Ljc4MmgtMzMuMzkxaC0wLjAxN2gwLjAxN1Y2Ni43ODJoLTMzLjM5MVYzMy4zOTEgaC0zMy4zOTFWMGgtNDQuNTIxdjMzLjM5MWgtMzMuMzkxdjMzLjM5MWgtMzMuMzkxdjY2Ljc4MmgzMy4zOTFWNjYuNzgyaDMzLjM5MXY2Ni43ODJoLTMzLjM5MXY2Ni43ODJoLTMzLjM5di02Ni43ODJoLTMzLjM5MSB2NjYuNzgyaDMzLjM5MXY2Ni43ODJoLTMzLjM5djQ0LjUyMWgtMzMuMzkxdi00NC41MjFINjYuNzkxdjE0NC42OTRINjYuNzg4eiBNMTAwLjE3OSwzNzguNDN2LTMzLjM5MWgzMy4zOTF2MzMuMzkxSDEwMC4xNzl6Ij48L3BhdGg+IDxyZWN0IHg9IjEwMC4xNzUiIHk9IjIwMC4zNTYiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iNjYuNzgyIj48L3JlY3Q+IDxyZWN0IHg9IjEzMy41NjYiIHk9IjEzMy41NzUiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iNjYuNzgyIj48L3JlY3Q+IDxyZWN0IHg9IjE2Ni45NTciIHk9IjY2Ljc5MyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSI2Ni43ODIiPjwvcmVjdD4gPHJlY3QgeD0iMjAwLjM0OCIgeT0iMzMuNDAyIiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSIyMzMuNzM5IiB5PSIwLjAwNyIgd2lkdGg9IjQ0LjUyMSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iMzc4LjQzMyIgeT0iMjAwLjM1NiIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSI2Ni43ODIiPjwvcmVjdD4gPHJlY3QgeD0iMzQ1LjA0MiIgeT0iMTMzLjU3NSIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSI2Ni43ODIiPjwvcmVjdD4gPHJlY3QgeD0iMzExLjY1MSIgeT0iNjYuNzkzIiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjY2Ljc4MiI+PC9yZWN0PiA8cmVjdCB4PSIyNzguMjYiIHk9IjMzLjQwMiIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iMzQ1LjA0MiIgeT0iNDQ1LjIyMyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iMzc4LjQzMyIgeT0iNDExLjgzMiIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iMTY2Ljk1NyIgeT0iNDc4LjYxNCIgd2lkdGg9IjE3OC4wODUiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjQxMS44MjMiIHk9IjI2Ny4xMzgiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMTQ0LjY5NCI+PC9yZWN0PiA8cmVjdCB4PSIxMzMuNTY2IiB5PSI0NDUuMjIzIiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSIxMDAuMTc1IiB5PSI0MTEuODMyIiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSI2Ni43ODUiIHk9IjI2Ny4xMzgiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMTQ0LjY5NCI+PC9yZWN0PiA8L2c+PC9zdmc+Cg==",
    "Fallback": "PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0Ij4KICA8bGluZSB4MT0iMSIgeTE9IjEiIHgyPSIyMyIgeTI9IjIzIiBzdHJva2U9ImJsYWNrIiBzdHJva2Utd2lkdGg9IjIiLz4KICA8bGluZSB4MT0iMjMiIHkxPSIxIiB4Mj0iMSIgeTI9IjIzIiBzdHJva2U9ImJsYWNrIiBzdHJva2Utd2lkdGg9IjIiLz4KPC9zdmc+",
    "Fog": ICON_FOG_ASSET.readall(),
    "LightCloud": "PHN2ZyB2ZXJzaW9uPSIxLjEiIGlkPSJMYXllcl8xIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiB2aWV3Qm94PSIwIDAgNTEyIDUxMiIgeG1sOnNwYWNlPSJwcmVzZXJ2ZSIgZmlsbD0iIzAwMDAwMCI+PGcgaWQ9IlNWR1JlcG9fYmdDYXJyaWVyIiBzdHJva2Utd2lkdGg9IjAiPjwvZz48ZyBpZD0iU1ZHUmVwb190cmFjZXJDYXJyaWVyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjwvZz48ZyBpZD0iU1ZHUmVwb19pY29uQ2FycmllciI+IDxwb2x5Z29uIHN0eWxlPSJmaWxsOiNGRkZGRkY7IiBwb2ludHM9IjQ3OC42MDksMTMzLjU2NSA0NzguNjA5LDEwMC4xNzQgNDc4LjYwMywxMDAuMTc0IDQ3OC42MDMsMTAwLjE3NCA0NDUuMjEyLDEwMC4xNzQgNDQ1LjIxMiw2Ni43ODMgNDExLjgyOSw2Ni43ODMgNDExLjgyOSw1NS42NTIgNDExLjgyNiw1NS42NTIgNDExLjgyNiwzMy4zOTEgMzc4LjQzNSwzMy4zOTEgMzc4LjQzNSwwIDIyMi42MDksMCAyMjIuNjA5LDMzLjM5MSAyMjIuNjA5LDMzLjM5MSAxODkuMjE3LDMzLjM5MSAxODkuMjIyLDU1LjY1MiAxODkuMjIyLDY2Ljc4MyAxODkuMjE3LDY2Ljc4MyAxODkuMjEyLDY2Ljc4MyAxNTUuODIxLDY2Ljc4MyAxNTUuODIxLDEwMC4xNzQgMTIyLjQyOSwxMDAuMTc0IDEyMi40MjksMTMzLjU2NSA4OS4wNDMsMTMzLjU2NSA4OS4wNDMsMjAwLjM0OCAxMjIuNDM1LDIwMC4zNDggMTIyLjQzNSwyMzMuNzM5IDMyMi43ODMsMjMzLjczOSAzNTYuMTc0LDIzMy43MzkgMzU2LjE3NCwyNjcuMTMgNDc4LjYwOSwyNjcuMTMgNDc4LjYwOSwyMzMuNzM5IDUxMiwyMzMuNzM5IDUxMiwyMDAuMzQ4IDUxMiwxNTUuODI2IDUxMiwxMzMuNTY1ICI+PC9wb2x5Z29uPiA8cG9seWdvbiBzdHlsZT0iZmlsbDojRTZFNkU2OyIgcG9pbnRzPSI0NzguNjA5LDM1Ni4xNzQgNDc4LjYwOSwzMjIuNzgzIDQ0NS4yMTcsMzIyLjc4MyA0NDUuMjEsMjg5LjM5MSAzODkuNTY1LDI4OS4zOTEgMzg5LjU1NywyMzMuNzM5IDM1Ni4xNjYsMjMzLjczOSAzNTYuMTY2LDIwMC4zNDggMzIyLjc4MywyMDAuMzQ4IDMyMi43ODMsMTY2Ljk1NyAxODkuMjE3LDE2Ni45NTcgMTg5LjIxNywyMDAuMzQ4IDE1NS44MjYsMjAwLjM0OCAxNTUuODI2LDIzMy43MzkgMTIyLjQzNSwyMzMuNzM5IDEyMi40MzUsMjg5LjM5MSA2Ni43NzUsMjg5LjM5MSA2Ni43NzUsMzIyLjc4MyAzMy4zOTEsMzIyLjc4MyAzMy4zOTEsMzU2LjE3NCAzMy4zODQsMzU2LjE3NCAzMy4zODQsMzU2LjE3NCAwLDM1Ni4xNzQgMCwzODkuNTY1IDAsMzg5LjU2OSAwLDQ0NS4yMTcgMzMuMzkxLDQ0NS4yMTcgMzMuMzkxLDQ3OC42MDkgNjYuNzgzLDQ3OC42MDkgNjYuNzgzLDUxMiAzNTYuMTc0LDUxMiA0NDUuMjEsNTEyIDQ0NS4yMTcsNTEyIDQ0NS4yMTcsNDc4LjYwOSA0NzguNjA5LDQ3OC42MDkgNDc4LjYwOSw0NDUuMjE3IDUxMiw0NDUuMjE3IDUxMiwzODkuNTY1IDUxMiwzNTYuMTc0ICI+PC9wb2x5Z29uPiA8cmVjdCBpZD0iU1ZHQ2xlYW5lcklkXzAiIHg9IjE1NS44MjYiIHk9IjIwMC4zNDgiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IGlkPSJTVkdDbGVhbmVySWRfMSIgeD0iMzIyLjc4MyIgeT0iMzIyLjc4MyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iMzMuMzkxIiB5PSI0NDUuMjE3IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCBpZD0iU1ZHQ2xlYW5lcklkXzIiIHg9IjE4OS4yMTciIHk9IjE2Ni45NTciIHdpZHRoPSIxMzMuNTY1IiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cG9seWdvbiBwb2ludHM9IjEyMi40MzUsMzIyLjc4MyAxNTUuODI2LDMyMi43ODMgMTU1LjgyNiwzNTYuMTc0IDE4OS4yMTcsMzU2LjE3NCAxODkuMjE3LDMyMi43ODMgMTU1LjgyNiwzMjIuNzgzIDE1NS44MjYsMjg5LjM5MSAxNTUuODI2LDIzMy43MzkgMTIyLjQzNSwyMzMuNzM5IDEyMi40MzUsMjg5LjM5MSA2Ni43ODMsMjg5LjM5MSA2Ni43ODMsMzIyLjc4MyAiPjwvcG9seWdvbj4gPHBvbHlnb24gcG9pbnRzPSIzMy4zOTEsMzU2LjE3NCA2Ni43ODMsMzU2LjE3NCA2Ni43ODMsMzIyLjc4MyAzMy4zOTEsMzIyLjc4MyAzMy4zOTEsMzU2LjE3NCAwLDM1Ni4xNzQgMCw0NDUuMjE3IDMzLjM5MSw0NDUuMjE3ICI+PC9wb2x5Z29uPiA8cG9seWdvbiBwb2ludHM9IjM4OS41NjUsMjg5LjM5MSAzODkuNTY1LDIzMy43MzkgMzU2LjE3NCwyMzMuNzM5IDM1Ni4xNzQsMjAwLjM0OCAzMjIuNzgzLDIwMC4zNDggMzIyLjc4MywyMzMuNzM5IDM1Ni4xNzQsMjMzLjczOSAzNTYuMTc0LDI4OS4zOTEgMzU2LjE3NCwzMjIuNzgzIDM1Ni4xNzQsMzIyLjc4MyA0NDUuMjE3LDMyMi43ODMgNDQ1LjIxNywyODkuMzkxICI+PC9wb2x5Z29uPiA8cmVjdCB4PSI0NDUuMjE3IiB5PSI0NDUuMjE3IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCBpZD0iU1ZHQ2xlYW5lcklkXzMiIHg9IjQ0NS4yMTciIHk9IjMyMi43ODMiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjQ3OC42MDkiIHk9IjM1Ni4xNzQiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iODkuMDQzIj48L3JlY3Q+IDxyZWN0IGlkPSJTVkdDbGVhbmVySWRfNCIgeD0iNjYuNzgzIiB5PSI0NzguNjA5IiB3aWR0aD0iMzc4LjQzNSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPGc+IDxyZWN0IGlkPSJTVkdDbGVhbmVySWRfMF8xXyIgeD0iMTU1LjgyNiIgeT0iMjAwLjM0OCIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPC9nPiA8cmVjdCB4PSIzMy4zOTEiIHk9IjMyMi43ODMiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxwb2x5Z29uIHBvaW50cz0iMTU1LjgyNiwzNTYuMTc0IDE4OS4yMTcsMzU2LjE3NCAxODkuMjE3LDMyMi43ODMgMTU1LjgyNiwzMjIuNzgzIDE1NS44MjYsMzIyLjc4MyAiPjwvcG9seWdvbj4gPHBvbHlnb24gcG9pbnRzPSIzMy4zOTEsNDQ1LjIxNyAzMy4zOTEsMzU2LjE3NCAwLDM1Ni4xNzQgMCw0NDUuMjE5IDMzLjM5MSw0NDUuMjE5IDMzLjM5MSw0NzguNjA5IDY2Ljc4Myw0NzguNjA5IDY2Ljc4Myw0NDUuMjE3ICI+PC9wb2x5Z29uPiA8Zz4gPHJlY3QgaWQ9IlNWR0NsZWFuZXJJZF8yXzFfIiB4PSIxODkuMjE3IiB5PSIxNjYuOTU3IiB3aWR0aD0iMTMzLjU2NSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPC9nPiA8cG9seWdvbiBwb2ludHM9IjEyMi40MzUsMzIyLjc4MyAxNTUuODI2LDMyMi43ODMgMTU1LjgyNiwzMjIuNzgzIDE1NS44MjYsMzIyLjc4MyAxNTUuODI2LDI4OS4zOTEgMTU1LjgyNiwyODkuMzkxIDE1NS44MjYsMjMzLjczOSAxMjIuNDM1LDIzMy43MzkgMTIyLjQzNSwyODkuMzkxIDY2Ljc4MywyODkuMzkxIDY2Ljc4MywzMjIuNzgzICI+PC9wb2x5Z29uPiA8cG9seWdvbiBwb2ludHM9IjQ3OC42MDksNDQ1LjIxNyA0NDUuMjE3LDQ0NS4yMTcgNDQ1LjIxNyw0NzguNjA5IDQ3OC42MDksNDc4LjYwOSA0NzguNjA5LDQ0NS4yMTkgNTEyLDQ0NS4yMTkgNTEyLDM1Ni4xNzUgNDc4LjYwOSwzNTYuMTc1ICI+PC9wb2x5Z29uPiA8Zz4gPHJlY3QgaWQ9IlNWR0NsZWFuZXJJZF80XzFfIiB4PSI2Ni43ODMiIHk9IjQ3OC42MDkiIHdpZHRoPSIzNzguNDM1IiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8L2c+IDxwb2x5Z29uIHBvaW50cz0iMzU2LjE3NCwyMzMuNzM5IDM1Ni4xNzQsMjg5LjM5MSAzNTYuMTc0LDMyMi43ODMgMzU2LjE3NCwzMjIuNzgzIDQ0NS4yMTcsMzIyLjc4MyA0NDUuMjE3LDI4OS4zOTEgMzg5LjU2NSwyODkuMzkxIDM4OS41NjUsMjMzLjczOSAzNTYuMTc0LDIzMy43MzkgMzU2LjE3NCwyMDAuMzQ4IDMyMi43ODMsMjAwLjM0OCAzMjIuNzgzLDIzMy43MzkgIj48L3BvbHlnb24+IDxnPiA8cmVjdCBpZD0iU1ZHQ2xlYW5lcklkXzNfMV8iIHg9IjQ0NS4yMTciIHk9IjMyMi43ODMiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDwvZz4gPGc+IDxyZWN0IGlkPSJTVkdDbGVhbmVySWRfMV8xXyIgeD0iMzIyLjc4MyIgeT0iMzIyLjc4MyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPC9nPiA8cmVjdCB4PSIyMjIuNjA5IiB5PSIxMDAuMTc0IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cG9seWdvbiBwb2ludHM9IjE4OS4yMTcsMTAwLjE3NCAyMjIuNjA5LDEwMC4xNzQgMjIyLjYwOSwxMDAuMTc0IDIyMi42MDksMTAwLjE3NCAyMjIuNjA5LDY2Ljc4MyAyMjIuNjA5LDY2Ljc4MyAyMjIuNjA5LDMzLjM5MSAxODkuMjE3LDMzLjM5MSAxODkuMjE3LDY2Ljc4MyAxNTUuODI2LDY2Ljc4MyAxNTUuODI2LDEwMC4xNzQgIj48L3BvbHlnb24+IDxwb2x5Z29uIHBvaW50cz0iMTIyLjQzNSwxMzMuNTY1IDE1NS44MjYsMTMzLjU2NSAxNTUuODI2LDEwMC4xNzQgMTIyLjQzNSwxMDAuMTc0IDEyMi40MzUsMTMzLjU2NSA4OS4wNDMsMTMzLjU2NSA4OS4wNDMsMjAwLjM0OCAxMjIuNDM1LDIwMC4zNDggIj48L3BvbHlnb24+IDxwb2x5Z29uIHBvaW50cz0iNDc4LjYwOSwxMzMuNTY1IDQ3OC42MDksMTAwLjE3NCA0NDUuMjE3LDEwMC4xNzQgNDQ1LjIxNyw2Ni43ODMgNDExLjgyNiw2Ni43ODMgNDExLjgyNiwzMy4zOTEgMzc4LjQzNSwzMy4zOTEgMzc4LjQzNSwwIDIyMi42MDksMCAyMjIuNjA5LDMzLjM5MSAzNzguNDM1LDMzLjM5MSAzNzguNDM1LDY2Ljc4MyAzNzguNDM1LDEwMC4xNzQgMzc4LjQzNSwxMDAuMTc0IDQ0NS4yMTcsMTAwLjE3NCA0NDUuMjE3LDEzMy41NjUgNDc4LjYwOSwxMzMuNTY1IDQ3OC42MDksMjMzLjczOSA1MTIsMjMzLjczOSA1MTIsMTMzLjU2NSAiPjwvcG9seWdvbj4gPHJlY3QgeD0iNDQ1LjIxNyIgeT0iMjMzLjczOSIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iMzQ1LjA0MyIgeT0iMTAwLjE3NCIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPC9nPjwvc3ZnPgo=",
    "LightRain": "PHN2ZyB2ZXJzaW9uPSIxLjEiIGlkPSJMYXllcl8xIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiB2aWV3Qm94PSIwIDAgNTEyIDUxMiIgeG1sOnNwYWNlPSJwcmVzZXJ2ZSIgZmlsbD0iIzAwMDAwMCI+PGcgaWQ9IlNWR1JlcG9fYmdDYXJyaWVyIiBzdHJva2Utd2lkdGg9IjAiPjwvZz48ZyBpZD0iU1ZHUmVwb190cmFjZXJDYXJyaWVyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjwvZz48ZyBpZD0iU1ZHUmVwb19pY29uQ2FycmllciI+IDxnPiA8cmVjdCB4PSI1NS42NTIiIHk9IjQxMS44MjYiIHN0eWxlPSJmaWxsOiMwMDZERjA7IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSIxNzguMDg3IiB5PSI0MTEuODI2IiBzdHlsZT0iZmlsbDojMDA2REYwOyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iMjg5LjM5MSIgeT0iNDExLjgyNiIgc3R5bGU9ImZpbGw6IzAwNkRGMDsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjQyMi45NTciIHk9IjQxMS44MjYiIHN0eWxlPSJmaWxsOiMwMDZERjA7IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB5PSI0NzguNjA5IiBzdHlsZT0iZmlsbDojMDA2REYwOyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iMjMzLjczOSIgeT0iNDc4LjYwOSIgc3R5bGU9ImZpbGw6IzAwNkRGMDsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjEyMi40MzUiIHk9IjQ3OC42MDkiIHN0eWxlPSJmaWxsOiMwMDZERjA7IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSIzNTYuMTc0IiB5PSI0NzguNjA5IiBzdHlsZT0iZmlsbDojMDA2REYwOyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iNDc4LjYwOSIgeT0iNDc4LjYwOSIgc3R5bGU9ImZpbGw6IzAwNkRGMDsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDwvZz4gPHBvbHlnb24gc3R5bGU9ImZpbGw6I0QzRDNEMzsiIHBvaW50cz0iNDc4LjYwOSwxODkuMjE0IDQ3OC42MDksMTU1LjgyMyA0NDUuMjE3LDE1NS44MjMgNDQ1LjIxLDE1NS44MjMgNDQ1LjIxNywxMjIuNzEzIDM4OS41NTcsMTIyLjcxMyAzODkuNTU3LDY2Ljc4MyAzNTYuMTY2LDY2Ljc4MyAzNTYuMTY2LDMzLjM5MSAzMjIuNzgzLDMzLjM5MSAzMjIuNzgzLDAgMTg5LjIxNywwIDE4OS4yMTcsMzMuMzkxIDE1NS44MjYsMzMuMzkxIDE1NS44MjYsNjYuNzgzIDEyMi40MzUsNjYuNzgzIDEyMi40MzUsMTIyLjQzNSA2Ni43NzUsMTIyLjQzNSA2Ni43NzUsMTU1LjgyMyAzMy4zOTEsMTU1LjgyMyAzMy4zOTEsMTg5LjIxNCAzMy4zODQsMTg5LjIxNCAzMy4zODQsMTg5LjIxNCAwLDE4OS4yMTQgMCwyMjIuNjA1IDAsMjIyLjYwOSAwLDI3OC4yNjEgMzMuMzkxLDI3OC4yNjEgMzMuMzkxLDMxMS42NTIgNjYuNzgzLDMxMS42NTIgNjYuNzgzLDM0NS4wNDMgMzU2LjE3NCwzNDUuMDQzIDQ0NS4yMSwzNDUuMDQzIDQ0NS4yMTcsMzQ1LjA0MyA0NDUuMjE3LDMxMS42NTIgNDc4LjYwOSwzMTEuNjUyIDQ3OC42MDksMjc4LjI2MSA1MTIsMjc4LjI2MSA1MTIsMjIyLjYwNSA1MTIsMTg5LjIxNCAiPjwvcG9seWdvbj4gPHJlY3QgeD0iMTU1LjgyNiIgeT0iMzMuMzkxIiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSIzMy4zOTEiIHk9IjE1NS44MjYiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxwb2x5Z29uIHBvaW50cz0iMzMuMzkxLDI3OC4yNjEgMzMuMzkxLDE4OS4yMTcgMCwxODkuMjE3IDAsMjc4LjI2MSAzMy4zOTEsMjc4LjI2MSAzMy4zOTEsMzExLjY1MiA2Ni43ODMsMzExLjY1MiA2Ni43ODMsMjc4LjI2MSAiPjwvcG9seWdvbj4gPHJlY3QgeD0iMTg5LjIxNyIgd2lkdGg9IjEzMy41NjUiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxwb2x5Z29uIHBvaW50cz0iMTIyLjQzNSwxNTUuODI2IDE1NS44MjYsMTU1LjgyNiAxNTUuODI2LDE4OS4yMTcgMTg5LjIxNywxODkuMjE3IDE4OS4yMTcsMTU1LjgyNiAxNTUuODI2LDE1NS44MjYgMTU1LjgyNiwxMjIuNDM1IDE1NS44MjYsNjYuNzgzIDEyMi40MzUsNjYuNzgzIDEyMi40MzUsMTIyLjQzNSA2Ni43ODMsMTIyLjQzNSA2Ni43ODMsMTU1LjgyNiAiPjwvcG9seWdvbj4gPHBvbHlnb24gcG9pbnRzPSI0NzguNjA5LDE4OS4yMTcgNDc4LjYwOSwyNzguMjYxIDQ0NS4yMTcsMjc4LjI2MSA0NDUuMjE3LDMxMS42NTIgNDc4LjYwOSwzMTEuNjUyIDQ3OC42MDksMjc4LjI2MSA1MTIsMjc4LjI2MSA1MTIsMTg5LjIxNyAiPjwvcG9seWdvbj4gPHJlY3QgeD0iNjYuNzgzIiB5PSIzMTEuNjUyIiB3aWR0aD0iMzc4LjQzNSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHBvbHlnb24gcG9pbnRzPSIzNTYuMTc0LDY2Ljc4MyAzNTYuMTc0LDEyMi40MzUgMzU2LjE3NCwxNTUuODI2IDM1Ni4xNzQsMTU1LjgyNiA0NDUuMjE3LDE1NS44MjYgNDQ1LjIxNywxMjIuNDM1IDM4OS41NjUsMTIyLjQzNSAzODkuNTY1LDY2Ljc4MyAzNTYuMTc0LDY2Ljc4MyAzNTYuMTc0LDMzLjM5MSAzMjIuNzgzLDMzLjM5MSAzMjIuNzgzLDY2Ljc4MyAiPjwvcG9seWdvbj4gPHJlY3QgeD0iNDQ1LjIxNyIgeT0iMTU1LjgyNiIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iMzIyLjc4MyIgeT0iMTU1LjgyNiIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPC9nPjwvc3ZnPgo=",
    "LightRainSun": ICON_LIGHTRAINSUN_ASSET.readall(),
    "PartlyCloud": "PHN2ZyB2ZXJzaW9uPSIxLjEiIGlkPSJMYXllcl8xIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiB2aWV3Qm94PSIwIDAgNTEyIDUxMiIgeG1sOnNwYWNlPSJwcmVzZXJ2ZSIgZmlsbD0iIzAwMDAwMCI+PGcgaWQ9IlNWR1JlcG9fYmdDYXJyaWVyIiBzdHJva2Utd2lkdGg9IjAiPjwvZz48ZyBpZD0iU1ZHUmVwb190cmFjZXJDYXJyaWVyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjwvZz48ZyBpZD0iU1ZHUmVwb19pY29uQ2FycmllciI+IDxwb2x5Z29uIHN0eWxlPSJmaWxsOiNGRkZGRkY7IiBwb2ludHM9IjQ3OC42MDksMzY3LjMwMSA0NzguNjA5LDMzMy45MSA0NDUuMjE3LDMzMy45MSA0NDUuMjEsMzMzLjkxIDQ0NS4yMDgsMzMzLjkxIDQxMS44MjYsMzMzLjkxIDQxMS44MjYsMjg5LjM5MSAzNzguNDI3LDI4OS4zOTEgMzc4LjQyNywyNTYgMzQ1LjAzNiwyNTYgMzQ1LjAzNiwyMjIuNjA5IDE2Ni45NTcsMjIyLjYwOSAxNjYuOTU3LDI1NiAxMzMuNTY1LDI1NiAxMzMuNTY1LDI4OS4zOTEgMTAwLjE3NCwyODkuMzkxIDEwMC4xNzQsMzMzLjkxIDY2Ljc3NSwzMzMuOTEgNjYuNzc1LDMzMy45MSAzMy4zOTEsMzMzLjkxIDMzLjM5MSwzNjcuMzAxIDMzLjM4NCwzNjcuMzAxIDMzLjM4NCwzNjcuMzAxIDAsMzY3LjMwMSAwLDQwMC42OTIgMCw0MDAuNjk2IDAsNDQ1LjIxNyAwLDQ0NS4yMjEgMCw0NzguNjA5IDMzLjM4NCw0NzguNjA5IDMzLjM5MSw0NzguNjA5IDMzLjM5MSw1MTIgNjYuNzc1LDUxMiA2Ni43ODMsNTEyIDM1Ni4xNzQsNTEyIDQ0NS4yMSw1MTIgNDQ1LjIxNyw1MTIgNDc4LjYwOSw1MTIgNDc4LjYwOSw0NzguNjA5IDUxMiw0NzguNjA5IDUxMiw0NDUuMjE3IDUxMiw0MDAuNjkyIDUxMiwzNjcuMzAxICI+PC9wb2x5Z29uPiA8cG9seWdvbiBzdHlsZT0iZmlsbDojRkZEQTQ0OyIgcG9pbnRzPSIzNzguNDM1LDEzMy41NjUgMzc4LjQzNSwxMDAuMTc0IDI0NC44NywxMDAuMTc0IDI0NC44NywxMzMuNTY1IDIxMS40NzgsMTMzLjU2NSAyMTEuNDc4LDI1NiAyNDQuODcsMjU2IDM0NS4wNDMsMjU2IDM0NS4wNDMsMjg5LjM5MSAzNzguNDM1LDI4OS4zOTEgMzc4LjQzNSwyNTYgNDExLjgyNiwyNTYgNDExLjgyNiwxMzMuNTY1ICI+PC9wb2x5Z29uPiA8cmVjdCB4PSIxMzMuNTY1IiB5PSIyNTYiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxwb2x5Z29uIHBvaW50cz0iMzMuMzkyLDM2Ny4zMDQgMTAwLjE3NCwzNjcuMzA0IDEwMC4xNzQsMzY3LjMwNCAxMzMuNTY1LDM2Ny4zMDQgMTMzLjU2NSw0MDAuNjk2IDE2Ni45NTcsNDAwLjY5NiAxNjYuOTU3LDM2Ny4zMDQgMTMzLjU2NSwzNjcuMzA0IDEzMy41NjUsMzMzLjkxMyAxMzMuNTY1LDI4OS4zOTEgMTAwLjE3NCwyODkuMzkxIDEwMC4xNzQsMzMzLjkxMyAzMy4zOTEsMzMzLjkxMyAzMy4zOTEsMzY3LjMwNCAwLjAwMSwzNjcuMzA0IDAuMDAxLDQ3OC42MDkgMzMuMzkyLDQ3OC42MDkgIj48L3BvbHlnb24+IDxyZWN0IHg9IjQ3OC42MDkiIHk9IjM2Ny4zMDQiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMTExLjMwNCI+PC9yZWN0PiA8cmVjdCB4PSIzMy4zOTEiIHk9IjQ3OC42MDkiIHdpZHRoPSI0NDUuMjE3IiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cG9seWdvbiBwb2ludHM9IjM3OC40MzUsMjg5LjM5MSAzNzguNDM1LDMzMy45MTMgMzc4LjQzNSwzNjcuMzA0IDM3OC40MzUsMzY3LjMwNCA0NzguNjA5LDM2Ny4zMDQgNDc4LjYwOSwzMzMuOTEzIDQxMS44MjYsMzMzLjkxMyA0MTEuODI2LDI4OS4zOTEgMzc4LjQzNSwyODkuMzkxIDM3OC40MzUsMjU2IDQxMS44MjYsMjU2IDQxMS44MjYsMTMzLjU2NSAzNzguNDM1LDEzMy41NjUgMzc4LjQzNSwyNTYgMzQ1LjA0MywyNTYgMzQ1LjA0MywyODkuMzkxICI+PC9wb2x5Z29uPiA8cmVjdCB4PSIzNDUuMDQzIiB5PSIzNjcuMzA0IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSI0MTEuODI2IiB5PSI2Ni43ODMiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjQ0NS4yMTciIHk9IjMzLjM5MSIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iMTc4LjA4NyIgeT0iNjYuNzgzIiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSIxNDQuNjk2IiB5PSIzMy4zOTEiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxwb2x5Z29uIHBvaW50cz0iMjExLjQ3OCwyMjIuNjA5IDE2Ni45NTcsMjIyLjYwOSAxNjYuOTU3LDI1NiAzNDUuMDQzLDI1NiAzNDUuMDQzLDIyMi42MDkgMjQ0Ljg3LDIyMi42MDkgMjQ0Ljg3LDEzMy41NjUgMjExLjQ3OCwxMzMuNTY1ICI+PC9wb2x5Z29uPiA8cmVjdCB4PSIyNDQuODciIHk9IjEwMC4xNzQiIHdpZHRoPSIxMzMuNTY1IiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSIyODkuMzkxIiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjY2Ljc4MyI+PC9yZWN0PiA8cmVjdCB4PSI0NDUuMjE3IiB5PSIxNTUuODI2IiB3aWR0aD0iNjYuNzgzIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSIxMTEuMzA0IiB5PSIxNTUuODI2IiB3aWR0aD0iNjYuNzgzIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8L2c+PC9zdmc+Cg==",
    "Rain": "PHN2ZyB2ZXJzaW9uPSIxLjEiIGlkPSJMYXllcl8xIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiB2aWV3Qm94PSIwIDAgNTEyIDUxMiIgeG1sOnNwYWNlPSJwcmVzZXJ2ZSIgZmlsbD0iIzAwMDAwMCI+PGcgaWQ9IlNWR1JlcG9fYmdDYXJyaWVyIiBzdHJva2Utd2lkdGg9IjAiPjwvZz48ZyBpZD0iU1ZHUmVwb190cmFjZXJDYXJyaWVyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjwvZz48ZyBpZD0iU1ZHUmVwb19pY29uQ2FycmllciI+IDxnPiA8cmVjdCB4PSIxMzMuNTY1IiB5PSIzNzguNDM1IiBzdHlsZT0iZmlsbDojMDA2REYwOyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iMTAwLjE3NCIgeT0iNDExLjgyNiIgc3R5bGU9ImZpbGw6IzAwNkRGMDsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjY2Ljc4MyIgeT0iNDQ1LjIxNyIgc3R5bGU9ImZpbGw6IzAwNkRGMDsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjMzLjM5MSIgeT0iNDc4LjYwOSIgc3R5bGU9ImZpbGw6IzAwNkRGMDsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjI0NC44NyIgeT0iMzc4LjQzNSIgc3R5bGU9ImZpbGw6IzAwNkRGMDsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjIxMS40NzgiIHk9IjQxMS44MjYiIHN0eWxlPSJmaWxsOiMwMDZERjA7IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSIxNzguMDg3IiB5PSI0NDUuMjE3IiBzdHlsZT0iZmlsbDojMDA2REYwOyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iMTQ0LjY5NiIgeT0iNDc4LjYwOSIgc3R5bGU9ImZpbGw6IzAwNkRGMDsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjM2Ny4zMDQiIHk9IjM3OC40MzUiIHN0eWxlPSJmaWxsOiMwMDZERjA7IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSIzMzMuOTEzIiB5PSI0MTEuODI2IiBzdHlsZT0iZmlsbDojMDA2REYwOyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iMzAwLjUyMiIgeT0iNDQ1LjIxNyIgc3R5bGU9ImZpbGw6IzAwNkRGMDsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjI2Ny4xMyIgeT0iNDc4LjYwOSIgc3R5bGU9ImZpbGw6IzAwNkRGMDsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjMzLjM5MSIgeT0iMzc4LjQzNSIgc3R5bGU9ImZpbGw6IzAwNkRGMDsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHk9IjQxMS44MjYiIHN0eWxlPSJmaWxsOiMwMDZERjA7IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSI0NzguNjA5IiB5PSIzNzguNDM1IiBzdHlsZT0iZmlsbDojMDA2REYwOyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iNDQ1LjIxNyIgeT0iNDExLjgyNiIgc3R5bGU9ImZpbGw6IzAwNkRGMDsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjQxMS44MjYiIHk9IjQ0NS4yMTciIHN0eWxlPSJmaWxsOiMwMDZERjA7IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSIzNzguNDM1IiB5PSI0NzguNjA5IiBzdHlsZT0iZmlsbDojMDA2REYwOyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPC9nPiA8cG9seWdvbiBzdHlsZT0iZmlsbDojODk4ODkwOyIgcG9pbnRzPSI0NzguNjA5LDE4OS4yMTQgNDc4LjYwOSwxNTUuODIzIDQ0NS4yMTcsMTU1LjgyMyA0NDUuMjEsMTU1LjgyMyA0NDUuMjE3LDEyMi43MTMgMzg5LjU1NywxMjIuNzEzIDM4OS41NTcsNjYuNzgzIDM1Ni4xNjYsNjYuNzgzIDM1Ni4xNjYsMzMuMzkxIDMyMi43ODMsMzMuMzkxIDMyMi43ODMsMCAxODkuMjE3LDAgMTg5LjIxNywzMy4zOTEgMTU1LjgyNiwzMy4zOTEgMTU1LjgyNiw2Ni43ODMgMTIyLjQzNSw2Ni43ODMgMTIyLjQzNSwxMjIuNDM1IDY2Ljc3NSwxMjIuNDM1IDY2Ljc3NSwxNTUuODIzIDMzLjM5MSwxNTUuODIzIDMzLjM5MSwxODkuMjE0IDMzLjM4NCwxODkuMjE0IDMzLjM4NCwxODkuMjE0IDAsMTg5LjIxNCAwLDIyMi42MDUgMCwyMjIuNjA5IDAsMjc4LjI2MSAzMy4zOTEsMjc4LjI2MSAzMy4zOTEsMzExLjY1MiA2Ni43ODMsMzExLjY1MiA2Ni43ODMsMzQ1LjA0MyAzNTYuMTc0LDM0NS4wNDMgNDQ1LjIxLDM0NS4wNDMgNDQ1LjIxNywzNDUuMDQzIDQ0NS4yMTcsMzExLjY1MiA0NzguNjA5LDMxMS42NTIgNDc4LjYwOSwyNzguMjYxIDUxMiwyNzguMjYxIDUxMiwyMjIuNjA1IDUxMiwxODkuMjE0ICI+PC9wb2x5Z29uPiA8cmVjdCB4PSIxNTUuODI2IiB5PSIzMy4zOTEiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjMzLjM5MSIgeT0iMTU1LjgyNiIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHBvbHlnb24gcG9pbnRzPSIzMy4zOTEsMjc4LjI2MSAzMy4zOTEsMTg5LjIxNyAwLDE4OS4yMTcgMCwyNzguMjYxIDMzLjM5MSwyNzguMjYxIDMzLjM5MSwzMTEuNjUyIDY2Ljc4MywzMTEuNjUyIDY2Ljc4MywyNzguMjYxICI+PC9wb2x5Z29uPiA8cmVjdCB4PSIxODkuMjE3IiB3aWR0aD0iMTMzLjU2NSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHBvbHlnb24gcG9pbnRzPSIxMjIuNDM1LDE1NS44MjYgMTU1LjgyNiwxNTUuODI2IDE1NS44MjYsMTg5LjIxNyAxODkuMjE3LDE4OS4yMTcgMTg5LjIxNywxNTUuODI2IDE1NS44MjYsMTU1LjgyNiAxNTUuODI2LDEyMi40MzUgMTU1LjgyNiw2Ni43ODMgMTIyLjQzNSw2Ni43ODMgMTIyLjQzNSwxMjIuNDM1IDY2Ljc4MywxMjIuNDM1IDY2Ljc4MywxNTUuODI2ICI+PC9wb2x5Z29uPiA8cG9seWdvbiBwb2ludHM9IjQ3OC42MDksMTg5LjIxNyA0NzguNjA5LDI3OC4yNjEgNDQ1LjIxNywyNzguMjYxIDQ0NS4yMTcsMzExLjY1MiA0NzguNjA5LDMxMS42NTIgNDc4LjYwOSwyNzguMjYxIDUxMiwyNzguMjYxIDUxMiwxODkuMjE3ICI+PC9wb2x5Z29uPiA8cmVjdCB4PSI2Ni43ODMiIHk9IjMxMS42NTIiIHdpZHRoPSIzNzguNDM1IiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cG9seWdvbiBwb2ludHM9IjM1Ni4xNzQsNjYuNzgzIDM1Ni4xNzQsMTIyLjQzNSAzNTYuMTc0LDE1NS44MjYgMzU2LjE3NCwxNTUuODI2IDQ0NS4yMTcsMTU1LjgyNiA0NDUuMjE3LDEyMi40MzUgMzg5LjU2NSwxMjIuNDM1IDM4OS41NjUsNjYuNzgzIDM1Ni4xNzQsNjYuNzgzIDM1Ni4xNzQsMzMuMzkxIDMyMi43ODMsMzMuMzkxIDMyMi43ODMsNjYuNzgzICI+PC9wb2x5Z29uPiA8cmVjdCB4PSI0NDUuMjE3IiB5PSIxNTUuODI2IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSIzMjIuNzgzIiB5PSIxNTUuODI2IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8L2c+PC9zdmc+Cg==",
    "Sleet": ICON_SLEET_ASSET.readall(),
    "Snow": "PHN2ZyB2ZXJzaW9uPSIxLjEiIGlkPSJMYXllcl8xIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiB2aWV3Qm94PSIwIDAgNTEyIDUxMiIgeG1sOnNwYWNlPSJwcmVzZXJ2ZSIgZmlsbD0iIzAwMDAwMCI+PGcgaWQ9IlNWR1JlcG9fYmdDYXJyaWVyIiBzdHJva2Utd2lkdGg9IjAiPjwvZz48ZyBpZD0iU1ZHUmVwb190cmFjZXJDYXJyaWVyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjwvZz48ZyBpZD0iU1ZHUmVwb19pY29uQ2FycmllciI+IDxnPiA8cG9seWdvbiBzdHlsZT0iZmlsbDojRTZFNkU2OyIgcG9pbnRzPSI0NzguNjA5LDE4OS4yMTQgNDc4LjYwOSwxNTUuODIzIDQ0NS4yMTcsMTU1LjgyMyA0NDUuMjEsMTU1LjgyMyA0NDUuMjE3LDEyMi43MTMgMzg5LjU1NywxMjIuNzEzIDM4OS41NTcsNjYuNzgzIDM1Ni4xNjYsNjYuNzgzIDM1Ni4xNjYsMzMuMzkxIDMyMi43ODMsMzMuMzkxIDMyMi43ODMsMCAxODkuMjE3LDAgMTg5LjIxNywzMy4zOTEgMTU1LjgyNiwzMy4zOTEgMTU1LjgyNiw2Ni43ODMgMTIyLjQzNSw2Ni43ODMgMTIyLjQzNSwxMjIuNDM1IDY2Ljc3NSwxMjIuNDM1IDY2Ljc3NSwxNTUuODIzIDMzLjM5MSwxNTUuODIzIDMzLjM5MSwxODkuMjE0IDMzLjM4NCwxODkuMjE0IDMzLjM4NCwxODkuMjE0IDAsMTg5LjIxNCAwLDIyMi42MDUgMCwyMjIuNjA5IDAsMjc4LjI2MSAzMy4zOTEsMjc4LjI2MSAzMy4zOTEsMzExLjY1MiA2Ni43ODMsMzExLjY1MiA2Ni43ODMsMzQ1LjA0MyAzNTYuMTc0LDM0NS4wNDMgNDQ1LjIxLDM0NS4wNDMgNDQ1LjIxNywzNDUuMDQzIDQ0NS4yMTcsMzExLjY1MiA0NzguNjA5LDMxMS42NTIgNDc4LjYwOSwyNzguMjYxIDUxMiwyNzguMjYxIDUxMiwyMjIuNjA1IDUxMiwxODkuMjE0ICI+PC9wb2x5Z29uPiA8cG9seWdvbiBzdHlsZT0iZmlsbDojRTZFNkU2OyIgcG9pbnRzPSIxMzMuNTY1LDQxMS44MjYgMTAwLjE3NCw0MTEuODI2IDEwMC4xNzQsMzc4LjQzNSAxMDAuMTc0LDM3OC40MzUgMzMuMzkxLDM3OC40MzUgMzMuMzkxLDM3OC40MzUgMzMuMzkxLDQxMS44MjYgMCw0MTEuODI2IDAsNDExLjgyNiAwLDQ3OC42MDkgMCw0NzguNjA5IDMzLjM5MSw0NzguNjA5IDMzLjM5MSw1MTIgMzMuMzkxLDUxMiAxMDAuMTc0LDUxMiAxMDAuMTc0LDUxMiAxMDAuMTc0LDQ3OC42MDkgMTMzLjU2NSw0NzguNjA5IDEzMy41NjUsNDc4LjYwOSAiPjwvcG9seWdvbj4gPHBvbHlnb24gc3R5bGU9ImZpbGw6I0U2RTZFNjsiIHBvaW50cz0iMzIyLjc4Myw0MTEuODI2IDI4OS4zOTEsNDExLjgyNiAyODkuMzkxLDM3OC40MzUgMjg5LjM5MSwzNzguNDM1IDIyMi42MDksMzc4LjQzNSAyMjIuNjA5LDM3OC40MzUgMjIyLjYwOSw0MTEuODI2IDE4OS4yMTcsNDExLjgyNiAxODkuMjE3LDQxMS44MjYgMTg5LjIxNyw0NzguNjA5IDE4OS4yMTcsNDc4LjYwOSAyMjIuNjA5LDQ3OC42MDkgMjIyLjYwOSw1MTIgMjIyLjYwOSw1MTIgMjg5LjM5MSw1MTIgMjg5LjM5MSw1MTIgMjg5LjM5MSw0NzguNjA5IDMyMi43ODMsNDc4LjYwOSAzMjIuNzgzLDQ3OC42MDkgIj48L3BvbHlnb24+IDxwb2x5Z29uIHN0eWxlPSJmaWxsOiNFNkU2RTY7IiBwb2ludHM9IjUxMiw0MTEuODI2IDQ3OC42MDksNDExLjgyNiA0NzguNjA5LDM3OC40MzUgNDc4LjYwOSwzNzguNDM1IDQxMS44MjYsMzc4LjQzNSA0MTEuODI2LDM3OC40MzUgNDExLjgyNiw0MTEuODI2IDM3OC40MzUsNDExLjgyNiAzNzguNDM1LDQxMS44MjYgMzc4LjQzNSw0NzguNjA5IDM3OC40MzUsNDc4LjYwOSA0MTEuODI2LDQ3OC42MDkgNDExLjgyNiw1MTIgNDExLjgyNiw1MTIgNDc4LjYwOSw1MTIgNDc4LjYwOSw1MTIgNDc4LjYwOSw0NzguNjA5IDUxMiw0NzguNjA5IDUxMiw0NzguNjA5ICI+PC9wb2x5Z29uPiA8L2c+IDxyZWN0IHg9IjE1NS44MjYiIHk9IjMzLjM5MSIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iMzMuMzkxIiB5PSIxNTUuODI2IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSIzMy4zOTEiIHk9IjI3OC4yNjEiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjE4OS4yMTciIHdpZHRoPSIxMzMuNTY1IiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cG9seWdvbiBwb2ludHM9IjEyMi40MzUsMTU1LjgyNiAxNTUuODI2LDE1NS44MjYgMTU1LjgyNiwxODkuMjE3IDE4OS4yMTcsMTg5LjIxNyAxODkuMjE3LDE1NS44MjYgMTU1LjgyNiwxNTUuODI2IDE1NS44MjYsMTIyLjQzNSAxNTUuODI2LDY2Ljc4MyAxMjIuNDM1LDY2Ljc4MyAxMjIuNDM1LDEyMi40MzUgNjYuNzgzLDEyMi40MzUgNjYuNzgzLDE1NS44MjYgIj48L3BvbHlnb24+IDxyZWN0IHk9IjE4OS4yMTciIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iODkuMDQzIj48L3JlY3Q+IDxwb2x5Z29uIHBvaW50cz0iNDc4LjYwOSwyNzguMjYxIDUxMiwyNzguMjYxIDUxMiwxODkuMjE3IDQ3OC42MDksMTg5LjIxNyA0NzguNjA5LDE1NS44MjYgNDQ1LjIxNywxNTUuODI2IDQ0NS4yMTcsMTg5LjIxNyA0NzguNjA5LDE4OS4yMTcgIj48L3BvbHlnb24+IDxyZWN0IHg9IjY2Ljc4MyIgeT0iMzExLjY1MiIgd2lkdGg9IjM3OC40MzUiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxwb2x5Z29uIHBvaW50cz0iMzU2LjE3NCw2Ni43ODMgMzU2LjE3NCwxMjIuNDM1IDM1Ni4xNzQsMTU1LjgyNiAzNTYuMTc0LDE1NS44MjYgNDQ1LjIxNywxNTUuODI2IDQ0NS4yMTcsMTIyLjQzNSAzODkuNTY1LDEyMi40MzUgMzg5LjU2NSw2Ni43ODMgMzU2LjE3NCw2Ni43ODMgMzU2LjE3NCwzMy4zOTEgMzIyLjc4MywzMy4zOTEgMzIyLjc4Myw2Ni43ODMgIj48L3BvbHlnb24+IDxyZWN0IHg9IjMyMi43ODMiIHk9IjE1NS44MjYiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjQ0NS4yMTciIHk9IjI3OC4yNjEiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHk9IjQxMS44MjYiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iNjYuNzgzIj48L3JlY3Q+IDxyZWN0IHg9IjMzLjM5MSIgeT0iMzc4LjQzNSIgd2lkdGg9IjY2Ljc4MyIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHBvbHlnb24gcG9pbnRzPSIxMDAuMTc0LDQ3OC42MDkgMzMuMzkxLDQ3OC42MDkgMzMuMzkxLDUxMiAxMDAuMTc0LDUxMiAxMDAuMTc0LDQ3OC42MDkgMTMzLjU2NSw0NzguNjA5IDEzMy41NjUsNDExLjgyNiAxMDAuMTc0LDQxMS44MjYgIj48L3BvbHlnb24+IDxyZWN0IHg9IjE4OS4yMTciIHk9IjQxMS44MjYiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iNjYuNzgzIj48L3JlY3Q+IDxyZWN0IHg9IjIyMi42MDkiIHk9IjM3OC40MzUiIHdpZHRoPSI2Ni43ODMiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxwb2x5Z29uIHBvaW50cz0iMjg5LjM5MSw0NzguNjA5IDIyMi42MDksNDc4LjYwOSAyMjIuNjA5LDUxMiAyODkuMzkxLDUxMiAyODkuMzkxLDQ3OC42MDkgMzIyLjc4Myw0NzguNjA5IDMyMi43ODMsNDExLjgyNiAyODkuMzkxLDQxMS44MjYgIj48L3BvbHlnb24+IDxyZWN0IHg9IjM3OC40MzUiIHk9IjQxMS44MjYiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iNjYuNzgzIj48L3JlY3Q+IDxyZWN0IHg9IjQxMS44MjYiIHk9IjM3OC40MzUiIHdpZHRoPSI2Ni43ODMiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxwb2x5Z29uIHBvaW50cz0iNDc4LjYwOSw0MTEuODI2IDQ3OC42MDksNDc4LjYwOSA0MTEuODI2LDQ3OC42MDkgNDExLjgyNiw1MTIgNDc4LjYwOSw1MTIgNDc4LjYwOSw0NzguNjA5IDUxMiw0NzguNjA5IDUxMiw0MTEuODI2ICI+PC9wb2x5Z29uPiA8L2c+PC9zdmc+Cg==",
    "Sun": "PHN2ZyB2ZXJzaW9uPSIxLjEiIGlkPSJMYXllcl8xIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiB2aWV3Qm94PSIwIDAgNTEyIDUxMiIgeG1sOnNwYWNlPSJwcmVzZXJ2ZSIgZmlsbD0iIzAwMDAwMCI+PGcgaWQ9IlNWR1JlcG9fYmdDYXJyaWVyIiBzdHJva2Utd2lkdGg9IjAiPjwvZz48ZyBpZD0iU1ZHUmVwb190cmFjZXJDYXJyaWVyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjwvZz48ZyBpZD0iU1ZHUmVwb19pY29uQ2FycmllciI+IDxnPiA8cG9seWdvbiBzdHlsZT0iZmlsbDojRkZEQTQ0OyIgcG9pbnRzPSI1MTIsMjExLjQ3OCA1MTIsMTc4LjA4NyA0MzQuMDg3LDE3OC4wODcgNDM0LjA4NywxNzguMDg3IDQwMC42OTYsMTc4LjA4NyA0MDAuNjk2LDE3OC4wODcgNDAwLjY5NiwxNzguMDg3IDQwMC42OTYsMTQ0LjY5NiA0MDAuNjk2LDE0NC42OTYgNDAwLjY5NiwxMTEuMzA0IDMzMy45MTMsMTExLjMwNCAzMzMuOTEzLDg5LjA0MyAzMzMuOTEzLDg5LjA0MyAzMzMuOTEzLDAgMzAwLjUyMiwwIDMwMC41MjIsNzcuOTEzIDIxMS40NzgsNzcuOTEzIDIxMS40NzgsMCAxNzguMDg3LDAgMTc4LjA4Nyw3Ny45MTMgMTc4LjA4Nyw3Ny45MTMgMTc4LjA4NywxMTEuMzA0IDE0NC42OTYsMTExLjMwNCAxNDQuNjk2LDExMS4zMDQgMTExLjMwNCwxMTEuMzA0IDExMS4zMDQsMTQ0LjY5NiAxMTEuMzA0LDE0NC42OTYgMTExLjMwNCwxNzguMDg3IDg5LjA0MywxNzguMDg3IDg5LjA0MywxNzguMDg3IDAsMTc4LjA4NyAwLDIxMS40NzggNzcuOTE5LDIxMS40NzggNzcuOTE5LDMwMC41MjIgMCwzMDAuNTIyIDAsMzMzLjkxMyA3Ny45MTksMzMzLjkxMyA3Ny45MTksMzMzLjkxMyAxMTEuMzA0LDMzMy45MTMgMTExLjMwNCwzNjcuMzA0IDExMS4zMDQsMzY3LjMwNCAxMTEuMzA0LDQwMC42OTYgMTQ0LjY5Niw0MDAuNjk2IDE0NC42OTYsNDAwLjY5NiAxNzguMDg3LDQwMC42OTYgMTc4LjA4Nyw0MzQuMDg3IDE3OC4wODcsNDM0LjA4NyAxNzguMDg3LDQzNC4wODcgMTc4LjA4Nyw1MTIgMjExLjQ3OCw1MTIgMjExLjQ3OCw0MzQuMDg3IDMwMC41MjIsNDM0LjA4NyAzMDAuNTIyLDUxMiAzMzMuOTEzLDUxMiAzMzMuOTEzLDQyMi45NTcgMzMzLjkxMyw0MjIuOTU3IDMzMy45MTMsNDAwLjY5NiAzNjcuMzA0LDQwMC42OTYgMzY3LjMwNCw0MDAuNjk2IDQwMC42OTYsNDAwLjY5NiA0MDAuNjk2LDM2Ny4zMDQgNDAwLjY5NiwzNjcuMzA0IDQwMC42OTYsMzMzLjkxMyA0MzQuMDkxLDMzMy45MTMgNDM0LjA5MSwzMzMuOTEzIDUxMiwzMzMuOTEzIDUxMiwzMDAuNTIyIDQzNC4wOTEsMzAwLjUyMiA0MzQuMDkxLDIxMS40NzggIj48L3BvbHlnb24+IDxyZWN0IHg9IjQwMC42OTYiIHk9Ijc3LjkxMyIgc3R5bGU9ImZpbGw6I0ZGREE0NDsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjQzNC4wODciIHk9IjQ0LjUyMiIgc3R5bGU9ImZpbGw6I0ZGREE0NDsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9Ijc3LjkxMyIgeT0iNzcuOTEzIiBzdHlsZT0iZmlsbDojRkZEQTQ0OyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iNDQuNTIyIiB5PSI0NC41MjIiIHN0eWxlPSJmaWxsOiNGRkRBNDQ7IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSI3Ny45MTMiIHk9IjQwMC42OTYiIHN0eWxlPSJmaWxsOiNGRkRBNDQ7IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSI0NC41MjIiIHk9IjQzNC4wODciIHN0eWxlPSJmaWxsOiNGRkRBNDQ7IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSI0MDAuNjk2IiB5PSI0MDAuNjk2IiBzdHlsZT0iZmlsbDojRkZEQTQ0OyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iNDM0LjA4NyIgeT0iNDM0LjA4NyIgc3R5bGU9ImZpbGw6I0ZGREE0NDsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDwvZz4gPHBvbHlnb24gcG9pbnRzPSI1MTIsMjExLjQ3OCA1MTIsMTc4LjA4NyA0MzQuMDg3LDE3OC4wODcgNDAwLjY5NiwxNzguMDg3IDQwMC42OTYsMzMzLjkxMyA0MjIuOTU3LDMzMy45MTMgNDM0LjA4NywzMzMuOTEzIDUxMiwzMzMuOTEzIDUxMiwzMDAuNTIyIDQzNC4wODcsMzAwLjUyMiA0MzQuMDg3LDIxMS40NzggIj48L3BvbHlnb24+IDxyZWN0IHg9IjQwMC42OTYiIHk9Ijc3LjkxMyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iNDM0LjA4NyIgeT0iNDQuNTIyIiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSI3Ny45MTMiIHk9Ijc3LjkxMyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iNDQuNTIyIiB5PSI0NC41MjIiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9Ijc3LjkxMyIgeT0iNDAwLjY5NiIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iNDQuNTIyIiB5PSI0MzQuMDg3IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSI0MDAuNjk2IiB5PSI0MDAuNjk2IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSI0MzQuMDg3IiB5PSI0MzQuMDg3IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cG9seWdvbiBwb2ludHM9IjE0NC42OTYsMzY3LjMwNCAxNDQuNjk2LDM2Ny4zMDQgMTQ0LjY5NiwzMzMuOTEzIDExMS4zMDQsMzMzLjkxMyAxMTEuMzA0LDE3OC4wODcgMTQ0LjY5NiwxNzguMDg3IDE0NC42OTYsMTQ0LjY5NiAxNDQuNjk2LDE0NC42OTYgMTc4LjA4NywxNDQuNjk2IDE3OC4wODcsMTExLjMwNCAxNDQuNjk2LDExMS4zMDQgMTExLjMwNCwxMTEuMzA0IDExMS4zMDQsMTQ0LjY5NiAxMTEuMzA0LDE0NC42OTYgMTExLjMwNCwxNzguMDg3IDc3LjkxMywxNzguMDg3IDAsMTc4LjA4NyAwLDIxMS40NzggNzcuOTEzLDIxMS40NzggNzcuOTEzLDMwMC41MjIgMCwzMDAuNTIyIDAsMzMzLjkxMyA3Ny45MTMsMzMzLjkxMyA4OS4wNDMsMzMzLjkxMyAxMTEuMzA0LDMzMy45MTMgMTExLjMwNCwzNjcuMzA0IDExMS4zMDQsMzY3LjMwNCAxMTEuMzA0LDQwMC42OTYgMTQ0LjY5Niw0MDAuNjk2IDE0NC42OTYsNDAwLjY5NiAxNzguMDg3LDQwMC42OTYgMTc4LjA4NywzNjcuMzA0ICI+PC9wb2x5Z29uPiA8cG9seWdvbiBwb2ludHM9IjMzMy45MTMsODkuMDQzIDMzMy45MTMsODkuMDQzIDMzMy45MTMsMCAzMDAuNTIyLDAgMzAwLjUyMiw3Ny45MTMgMjExLjQ3OCw3Ny45MTMgMjExLjQ3OCwwIDE3OC4wODcsMCAxNzguMDg3LDc3LjkxMyAxNzguMDg3LDc3LjkxMyAxNzguMDg3LDExMS4zMDQgMzMzLjkxMywxMTEuMzA0ICI+PC9wb2x5Z29uPiA8cG9seWdvbiBwb2ludHM9IjE3OC4wODcsNDM0LjA4NyAxNzguMDg3LDQzNC4wODcgMTc4LjA4Nyw1MTIgMjExLjQ3OCw1MTIgMjExLjQ3OCw0MzQuMDg3IDMwMC41MjIsNDM0LjA4NyAzMDAuNTIyLDUxMiAzMzMuOTEzLDUxMiAzMzMuOTEzLDQyMi45NTcgMzMzLjkxMyw0MjIuOTU3IDMzMy45MTMsNDAwLjY5NiAxNzguMDg3LDQwMC42OTYgIj48L3BvbHlnb24+IDxwb2x5Z29uIHBvaW50cz0iMzMzLjkxMywxNDQuNjk2IDM2Ny4zMDQsMTQ0LjY5NiAzNjcuMzA0LDE3OC4wODcgNDAwLjY5NiwxNzguMDg3IDQwMC42OTYsMTQ0LjY5NiA0MDAuNjk2LDE0NC42OTYgNDAwLjY5NiwxMTEuMzA0IDM2Ny4zMDQsMTExLjMwNCAzNjcuMzA0LDExMS4zMDQgMzMzLjkxMywxMTEuMzA0IDMzMy45MTMsMTExLjMwNCAiPjwvcG9seWdvbj4gPHBvbHlnb24gcG9pbnRzPSI0MDAuNjk2LDM2Ny4zMDQgNDAwLjY5NiwzMzMuOTEzIDM2Ny4zMDQsMzMzLjkxMyAzNjcuMzA0LDM2Ny4zMDQgMzMzLjkxMywzNjcuMzA0IDMzMy45MTMsMzY3LjMwNCAzMzMuOTEzLDQwMC42OTYgMzMzLjkxMyw0MDAuNjk2IDM2Ny4zMDQsNDAwLjY5NiAzNjcuMzA0LDQwMC42OTYgNDAwLjY5Niw0MDAuNjk2ICI+PC9wb2x5Z29uPiA8L2c+PC9zdmc+Cg==",
    "Thunder": "PHN2ZyB2ZXJzaW9uPSIxLjEiIGlkPSJMYXllcl8xIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiB2aWV3Qm94PSIwIDAgNTEyIDUxMiIgeG1sOnNwYWNlPSJwcmVzZXJ2ZSIgZmlsbD0iIzAwMDAwMCI+PGcgaWQ9IlNWR1JlcG9fYmdDYXJyaWVyIiBzdHJva2Utd2lkdGg9IjAiPjwvZz48ZyBpZD0iU1ZHUmVwb190cmFjZXJDYXJyaWVyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjwvZz48ZyBpZD0iU1ZHUmVwb19pY29uQ2FycmllciI+IDxnPiA8cmVjdCB4PSI2Ni43ODMiIHk9IjQ0NS4yMTciIHN0eWxlPSJmaWxsOiMwMDZERjA7IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSIzMy4zOTEiIHk9IjQ3OC42MDkiIHN0eWxlPSJmaWxsOiMwMDZERjA7IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSIxMzMuNTY1IiB5PSI0NzguNjA5IiBzdHlsZT0iZmlsbDojMDA2REYwOyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iMzY3LjMwNCIgeT0iMzc4LjQzNSIgc3R5bGU9ImZpbGw6IzAwNkRGMDsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjMzLjM5MSIgeT0iMzc4LjQzNSIgc3R5bGU9ImZpbGw6IzAwNkRGMDsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHk9IjQxMS44MjYiIHN0eWxlPSJmaWxsOiMwMDZERjA7IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSI0NzguNjA5IiB5PSIzNzguNDM1IiBzdHlsZT0iZmlsbDojMDA2REYwOyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iNDQ1LjIxNyIgeT0iNDExLjgyNiIgc3R5bGU9ImZpbGw6IzAwNkRGMDsiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjQxMS44MjYiIHk9IjQ0NS4yMTciIHN0eWxlPSJmaWxsOiMwMDZERjA7IiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSIzNzguNDM1IiB5PSI0NzguNjA5IiBzdHlsZT0iZmlsbDojMDA2REYwOyIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPC9nPiA8cG9seWdvbiBzdHlsZT0iZmlsbDojODk4ODkwOyIgcG9pbnRzPSI0NzguNjA5LDE3OC4wODcgNDc4LjYwOSwxNDQuNjk2IDQ0NS4yMSwxNDQuNjk2IDQ0NS4yMTcsMTExLjMwNCAzODkuNTU3LDExMS4zMDQgMzg5LjU1Nyw2Ni43ODMgMzU2LjE2Niw2Ni43ODMgMzU2LjE2NiwzMy4zOTEgMzIyLjc4MywzMy4zOTEgMzIyLjc4MywwIDE4OS4yMTcsMCAxODkuMjE3LDMzLjM5MSAxNTUuODI2LDMzLjM5MSAxNTUuODI2LDY2Ljc4MyAxMjIuNDM1LDY2Ljc4MyAxMjIuNDM1LDExMS4zMDQgNjYuNzgzLDExMS4zMDQgNjYuNzgzLDE0NC42OTYgMzMuMzkxLDE0NC42OTYgMzMuMzkxLDE3OC4wODcgMzMuMzg0LDE3OC4wODcgMzMuMzg0LDE3OC4wODcgMCwxNzguMDg3IDAsMjc4LjI2MSAzMy4zOTEsMjc4LjI2MSAzMy4zOTEsMzExLjY1MiA2Ni43ODMsMzExLjY1MiA2Ni43ODMsMzQ1LjA0MyAxMzMuNTY1LDM0NS4wNDMgMzY3LjMwNCwzNDUuMDQzIDQ0NS4yMSwzNDUuMDQzIDQ0NS4yMTcsMzQ1LjA0MyA0NDUuMjE3LDMxMS42NTIgNDc4LjYwOSwzMTEuNjUyIDQ3OC42MDksMjc4LjI2MSA1MTIsMjc4LjI2MSA1MTIsMTc4LjA4NyAiPjwvcG9seWdvbj4gPHJlY3QgeD0iMTU1LjgyNiIgeT0iMzMuMzkxIiB3aWR0aD0iMzMuMzkxIiBoZWlnaHQ9IjMzLjM5MSI+PC9yZWN0PiA8cmVjdCB4PSIzMy4zOTEiIHk9IjE0NC42OTYiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjMzLjM5MSIgeT0iMjc4LjI2MSIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHJlY3QgeD0iMTg5LjIxNyIgd2lkdGg9IjEzMy41NjUiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxwb2x5Z29uIHBvaW50cz0iMTU1LjgyNiwxNDQuNjk2IDE1NS44MjYsMTc4LjA4NyAxODkuMjE3LDE3OC4wODcgMTg5LjIxNywxNDQuNjk2IDE1NS44MjYsMTQ0LjY5NiAxNTUuODI2LDExMS4zMDQgMTU1LjgyNiw2Ni43ODMgMTIyLjQzNSw2Ni43ODMgMTIyLjQzNSwxMTEuMzA0IDY2Ljc4MywxMTEuMzA0IDY2Ljc4MywxNDQuNjk2IDEyMi40MzUsMTQ0LjY5NiAxMjIuNDM1LDE0NC42OTYgIj48L3BvbHlnb24+IDxyZWN0IHk9IjE3OC4wODciIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMTAwLjE3NCI+PC9yZWN0PiA8cG9seWdvbiBwb2ludHM9IjM4OS41NjUsMTExLjMwNCAzODkuNTY1LDY2Ljc4MyAzNTYuMTc0LDY2Ljc4MyAzNTYuMTc0LDMzLjM5MSAzMjIuNzgzLDMzLjM5MSAzMjIuNzgzLDY2Ljc4MyAzNTYuMTc0LDY2Ljc4MyAzNTYuMTc0LDExMS4zMDQgMzU2LjE3NCwxNDQuNjk2IDM1Ni4xNzQsMTQ0LjY5NiA0NDUuMjE3LDE0NC42OTYgNDQ1LjIxNywxMTEuMzA0ICI+PC9wb2x5Z29uPiA8cG9seWdvbiBwb2ludHM9IjQ3OC42MDksMTc4LjA4NyA0NzguNjA5LDE0NC42OTYgNDQ1LjIxNywxNDQuNjk2IDQ0NS4yMTcsMTc4LjA4NyA0NzguNjA5LDE3OC4wODcgNDc4LjYwOSwyNzguMjYxIDUxMiwyNzguMjYxIDUxMiwxNzguMDg3ICI+PC9wb2x5Z29uPiA8cmVjdCB4PSI2Ni43ODMiIHk9IjMxMS42NTIiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjQwMC42OTYiIHk9IjMxMS42NTIiIHdpZHRoPSI0NC41MjIiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjMyMi43ODMiIHk9IjE0NC42OTYiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxyZWN0IHg9IjQ0NS4yMTciIHk9IjI3OC4yNjEiIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxwYXRoIHN0eWxlPSJmaWxsOiNGRkRBNDQ7IiBkPSJNMzY3LjMwNCwyMTEuNDc4SDE2Ni45NTd2MTMzLjU2NWgtMzMuMzkxdjEwMC4xNzRsMCwwaDY2Ljc4M1Y1MTJsMCwwaDY2Ljc4M3YtMzMuMzkxbDAsMGwwLDBoMzMuMzkxIHYtMzMuMzkxbDAsMGwwLDBoMzMuMzkxdi02Ni43ODNsMCwwbDAsMGgtMzMuMzkxdi0zMy4zOTFsMCwwbDAsMGgzMy4zOTF2LTMzLjM5MWwwLDBsMCwwaDMzLjM5MVYyMTEuNDc4eiI+PC9wYXRoPiA8cmVjdCB4PSIyNjcuMTMiIHk9IjQ0NS4yMTciIHdpZHRoPSIzMy4zOTEiIGhlaWdodD0iMzMuMzkxIj48L3JlY3Q+IDxwb2x5Z29uIHBvaW50cz0iMjMzLjczOSw0NDUuMjE3IDIzMy43MzksNDExLjgyNiAxNjYuOTU3LDQxMS44MjYgMTY2Ljk1NywzNzguNDM1IDE2Ni45NTcsMzQ1LjA0MyAxMzMuNTY1LDM0NS4wNDMgMTMzLjU2NSwzNzguNDM1IDEzMy41NjUsNDExLjgyNiAxMzMuNTY1LDQ0NS4yMTcgMjAwLjM0OCw0NDUuMjE3IDIwMC4zNDgsNTEyIDIzMy43MzksNTEyIDI2Ny4xMyw1MTIgMjY3LjEzLDQ3OC42MDkgMjMzLjczOSw0NzguNjA5ICI+PC9wb2x5Z29uPiA8cG9seWdvbiBwb2ludHM9IjI2Ny4xMywzNzguNDM1IDI2Ny4xMyw0MTEuODI2IDMwMC41MjIsNDExLjgyNiAzMDAuNTIyLDQ0NS4yMTcgMzMzLjkxMyw0NDUuMjE3IDMzMy45MTMsNDExLjgyNiAzMzMuOTEzLDM3OC40MzUgMzAwLjUyMiwzNzguNDM1IDMwMC41MjIsMzQ1LjA0MyAyNjcuMTMsMzQ1LjA0MyAiPjwvcG9seWdvbj4gPHJlY3QgeD0iMzAwLjUyMiIgeT0iMzExLjY1MiIgd2lkdGg9IjMzLjM5MSIgaGVpZ2h0PSIzMy4zOTEiPjwvcmVjdD4gPHBvbHlnb24gcG9pbnRzPSIxNjYuOTU3LDI0NC44NyAxNjYuOTU3LDMxMS42NTIgMTY2Ljk1NywzNDUuMDQzIDIwMC4zNDgsMzQ1LjA0MyAyMDAuMzQ4LDMxMS42NTIgMjAwLjM0OCwyNDQuODcgMzMzLjkxMywyNDQuODcgMzMzLjkxMywzMTEuNjUyIDM2Ny4zMDQsMzExLjY1MiAzNjcuMzA0LDI0NC44NyAzNjcuMzA0LDIxMS40NzggMTY2Ljk1NywyMTEuNDc4ICI+PC9wb2x5Z29uPiA8L2c+PC9zdmc+Cg==",
}
MET_EIREANN_URL = "http://openaccess.pf.api.met.ie/metno-wdb2ts/locationforecast?lat={lat};long={long}"
THUMBNAILS = {
    "Cloud": THUMB_CLOUD_ASSET.readall(),
    "Drizzle": THUMB_DRIZZLE_ASSET.readall(),
    "DrizzleSun": THUMB_LIGHTRAINSUN_ASSET.readall(),
    "Fog": THUMB_FOG_ASSET.readall(),
    "LightCloud": THUMB_LIGHTCLOUD_ASSET.readall(),
    "LightRain": THUMB_LIGHTRAIN_ASSET.readall(),
    "LightRainSun": THUMB_LIGHTRAINSUN_ASSET.readall(),
    "PartlyCloud": THUMB_PARTLYCLOUD_ASSET.readall(),
    "Rain": THUMB_RAIN_ASSET.readall(),
    "Sleet": THUMB_SLEET_ASSET.readall(),
    "Snow": THUMB_SNOW_ASSET.readall(),
    "Sun": THUMB_SUN_ASSET.readall(),
    "Thunder": THUMB_THUNDER_ASSET.readall(),
}
WIND_ICONS = {
    "N": WIND_N_ASSET.readall(),
    "NE": WIND_NE_ASSET.readall(),
    "E": WIND_E_ASSET.readall(),
    "SE": WIND_SE_ASSET.readall(),
    "S": WIND_S_ASSET.readall(),
    "SW": WIND_SW_ASSET.readall(),
    "W": WIND_W_ASSET.readall(),
    "NW": WIND_NW_ASSET.readall(),
}
