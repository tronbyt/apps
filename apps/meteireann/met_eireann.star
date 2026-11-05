load("animation.star", "animation")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/icon_cloud.svg", ICON_CLOUD_ASSET = "file")
load("images/icon_drizzle.svg", ICON_DRIZZLE_ASSET = "file")
load("images/icon_drizzlesun.png", ICON_DRIZZLESUN_ASSET = "file")
load("images/icon_drop.svg", ICON_DROP_ASSET = "file")
load("images/icon_fallback.svg", ICON_FALLBACK_ASSET = "file")
load("images/icon_fog.png", ICON_FOG_ASSET = "file")
load("images/icon_lightcloud.svg", ICON_LIGHTCLOUD_ASSET = "file")
load("images/icon_lightrain.svg", ICON_LIGHTRAIN_ASSET = "file")
load("images/icon_lightrainsun.png", ICON_LIGHTRAINSUN_ASSET = "file")
load("images/icon_partlycloud.svg", ICON_PARTLYCLOUD_ASSET = "file")
load("images/icon_rain.svg", ICON_RAIN_ASSET = "file")
load("images/icon_sleet.png", ICON_SLEET_ASSET = "file")
load("images/icon_snow.svg", ICON_SNOW_ASSET = "file")
load("images/icon_sun.svg", ICON_SUN_ASSET = "file")
load("images/icon_thunder.svg", ICON_THUNDER_ASSET = "file")
load("images/thumb_cloud.png", THUMB_CLOUD_ASSET = "file")
load("images/thumb_drizzle.png", THUMB_DRIZZLE_ASSET = "file")
load("images/thumb_drizzlesun.png", THUMB_DRIZZLESUN_ASSET = "file")
load("images/thumb_fog.png", THUMB_FOG_ASSET = "file")
load("images/thumb_lightcloud.png", THUMB_LIGHTCLOUD_ASSET = "file")
load("images/thumb_lightrain.png", THUMB_LIGHTRAIN_ASSET = "file")
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
        src = icon,
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
                                            src = ICONS.get("Drop"),
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
    "Cloud": ICON_CLOUD_ASSET.readall(),
    "Drizzle": ICON_DRIZZLE_ASSET.readall(),
    "DrizzleSun": ICON_DRIZZLESUN_ASSET.readall(),
    "Drop": ICON_DROP_ASSET.readall(),
    "Fallback": ICON_FALLBACK_ASSET.readall(),
    "Fog": ICON_FOG_ASSET.readall(),
    "LightCloud": ICON_LIGHTCLOUD_ASSET.readall(),
    "LightRain": ICON_LIGHTRAIN_ASSET.readall(),
    "LightRainSun": ICON_LIGHTRAINSUN_ASSET.readall(),
    "PartlyCloud": ICON_PARTLYCLOUD_ASSET.readall(),
    "Rain": ICON_RAIN_ASSET.readall(),
    "Sleet": ICON_SLEET_ASSET.readall(),
    "Snow": ICON_SNOW_ASSET.readall(),
    "Sun": ICON_SUN_ASSET.readall(),
    "Thunder": ICON_THUNDER_ASSET.readall(),
}
MET_EIREANN_URL = "http://openaccess.pf.api.met.ie/metno-wdb2ts/locationforecast?lat={lat};long={long}"
THUMBNAILS = {
    "Cloud": THUMB_CLOUD_ASSET.readall(),
    "Drizzle": THUMB_DRIZZLE_ASSET.readall(),
    "DrizzleSun": THUMB_DRIZZLESUN_ASSET.readall(),
    "Fog": THUMB_FOG_ASSET.readall(),
    "LightCloud": THUMB_LIGHTCLOUD_ASSET.readall(),
    "LightRain": THUMB_LIGHTRAIN_ASSET.readall(),
    "LightRainSun": THUMB_LIGHTRAIN_ASSET.readall(),
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
