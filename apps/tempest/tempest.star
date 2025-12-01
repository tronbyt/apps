"""
Applet: Tempest
Summary: Display your Tempest Weather data
Description: Overview of your Tempest Weather Station. Supports standard (64x32) and wide (128x64) displays.
Author: epifinygirl
Adapted for Tronbyt: tavdog
Enhanced with wide display support and additional options
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/cloudy.png", CLOUDY_ASSET = "file")
load("images/foggy.png", FOGGY_ASSET = "file")
load("images/haily.png", HAILY_ASSET = "file")
load("images/moony.png", MOONY_ASSET = "file")
load("images/moonyish.png", MOONYISH_ASSET = "file")
load("images/rainy.png", RAINY_ASSET = "file")
load("images/sleety.png", SLEETY_ASSET = "file")
load("images/snowy.png", SNOWY_ASSET = "file")
load("images/sunny.png", SUNNY_ASSET = "file")
load("images/sunnyish.png", SUNNYISH_ASSET = "file")
load("images/thundery.png", THUNDERY_ASSET = "file")
load("images/tornady.png", TORNADY_ASSET = "file")
load("images/windy.png", WINDY_ASSET = "file")
load("render.star", "canvas", "render")
load("sample_forecast_response.json", SAMPLE_FORECAST_RESPONSE = "file")
load("sample_station_response.json", SAMPLE_STATION_RESPONSE = "file")
load("schema.star", "schema")

TEMPEST_STATIONS_URL = "https://swd.weatherflow.com/swd/rest/stations?token=%s"
TEMPEST_FORECAST_URL = "https://swd.weatherflow.com/swd/rest/better_forecast?token=%s"
TEMPEST_OBSERVATION_URL = "https://swd.weatherflow.com/swd/rest/observations/station/%s?token=%s"

def main(config):
    # Detect wide display (S3 Wide is 128x64)
    is_wide = canvas.is2x()

    # Adjust delay for animation speed
    delay = 35 if is_wide else 50

    if not "station" in config or not "token" in config:
        station_res = json.decode(SAMPLE_STATION_RESPONSE.readall())
        forecast_res = json.decode(SAMPLE_FORECAST_RESPONSE.readall())
        units = station_res["station_units"]
    else:
        station_id = config["station"]
        token = config["token"]
        if "." in station_id:
            station_id = station_id.split(".")[0]

        res = http.get(
            url = TEMPEST_OBSERVATION_URL % (station_id, token),
        )
        if res.status_code != 200:
            fail("station observation request failed with status code: %d - %s" %
                 (res.status_code, res.body()))

        station_res = res.json()
        units = station_res["station_units"]
        res = http.get(
            url = TEMPEST_FORECAST_URL % token,
            params = {
                "station_id": station_id,
                "units_temp": units["units_temp"],
                "units_wind": units["units_wind"],
                "units_distance": units["units_distance"],
                "units_pressure": units["units_pressure"],
                "units_precip": units["units_precip"],
            },
        )
        if res.status_code != 200:
            fail("forecast request failed with status code: %d - %s" %
                 (res.status_code, res.body()))

        forecast_res = res.json()

    if len(station_res["obs"]) == 0:
        return []

    # Get config options (with backward compatibility for old Feels_Dew key)
    secondary_temp_choice = config.get("secondary_temp", config.get("Feels_Dew", "1"))
    show_labels = config.bool("show_labels", True)
    show_conditions = config.bool("show_conditions", False)
    show_highlow = config.bool("show_highlow", True)

    conditions = forecast_res["current_conditions"]

    # Get forecast data for high/low temps
    forecast_daily = forecast_res.get("forecast", {}).get("daily", [])
    if len(forecast_daily) > 0:
        today_forecast = forecast_daily[0]
        high_temp = "%d°" % today_forecast.get("air_temp_high", 0)
        low_temp = "%d°" % today_forecast.get("air_temp_low", 0)
    else:
        high_temp = "--"
        low_temp = "--"

    # Extract all weather data
    temp = "%d°" % conditions["air_temperature"]
    humidity = "%d%%" % conditions["relative_humidity"]
    wind_speed = "%d" % conditions["wind_avg"]
    wind_dir = conditions["wind_direction_cardinal"]
    wind_unit = units["units_wind"]
    wind = "%s %d%s" % (wind_dir, conditions["wind_avg"], wind_unit)
    pressure = "%g" % conditions["sea_level_pressure"]
    rain = "%g" % conditions.get("precip_accum_local_day", 0.0)
    feels = "%d°" % conditions["feels_like"]
    dew_pt = "%d°" % conditions["dew_point"]
    pressure_trend = conditions["pressure_trend"]
    icon = ICON_MAP.get(conditions["icon"], ICON_MAP["cloudy"])
    condition_text = conditions.get("conditions", "")
    rain_units = units["units_precip"]

    # Pressure trend icon
    if pressure_trend == "falling":
        pressure_icon = "↓"
    elif pressure_trend == "rising":
        pressure_icon = "↑"
    else:
        pressure_icon = "→"

    # Build secondary temperature display
    secondary_temp_text = None
    if secondary_temp_choice == "1":
        secondary_temp_text = ("F:" if show_labels else "") + feels
    elif secondary_temp_choice == "2":
        secondary_temp_text = ("D:" if show_labels else "") + dew_pt
    elif secondary_temp_choice == "4":
        secondary_temp_text = high_temp + "/" + low_temp

    # Choose layout based on display width
    if is_wide:
        return render_wide_layout(
            delay = delay,
            icon = icon,
            temp = temp,
            secondary_temp_text = secondary_temp_text,
            high_temp = high_temp,
            low_temp = low_temp,
            humidity = humidity,
            rain = rain,
            rain_units = rain_units,
            pressure = pressure,
            pressure_icon = pressure_icon,
            wind_dir = wind_dir,
            wind_speed = wind_speed,
            wind_unit = wind_unit,
            condition_text = condition_text,
            show_labels = show_labels,
            show_conditions = show_conditions,
            show_highlow = show_highlow,
        )
    else:
        return render_standard_layout(
            delay = delay,
            icon = icon,
            temp = temp,
            secondary_temp_text = secondary_temp_text,
            humidity = humidity,
            rain = rain,
            rain_units = rain_units,
            pressure = pressure,
            pressure_icon = pressure_icon,
            wind = wind,
            condition_text = condition_text,
            show_conditions = show_conditions,
        )

def render_standard_layout(delay, icon, temp, secondary_temp_text, humidity, rain, rain_units, pressure, pressure_icon, wind, condition_text, show_conditions):
    """Render layout for standard 64x32 display"""

    # Build left column children
    left_children = [
        render.Text(
            content = temp,
            color = "#22AA22",
        ),
    ]

    if secondary_temp_text:
        left_children.append(
            render.Text(
                content = secondary_temp_text,
                color = "#FFFF00",
            ),
        )

    left_children.append(render.Image(icon))

    # Build right column children
    right_children = [
        render.Text(
            content = humidity,
            color = "#6666FF",
        ),
        render.Text(
            content = rain + " " + rain_units,
            color = "#808080",
        ),
        render.Text(
            content = pressure + " " + pressure_icon,
        ),
    ]

    if show_conditions and condition_text:
        right_children.append(
            render.Marquee(
                width = 32,
                offset_start = 16,
                offset_end = 16,
                child = render.Text(
                    content = condition_text,
                    color = "#AAAAAA",
                    font = "CG-pixel-3x5-mono",
                ),
            ),
        )
    else:
        right_children.append(
            render.Text(
                content = wind,
                font = "CG-pixel-3x5-mono",
            ),
        )

    main_content = render.Row(
        expanded = True,
        main_align = "space_evenly",
        children = [
            render.Column(
                cross_align = "start",
                children = left_children,
            ),
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "end",
                children = right_children,
            ),
        ],
    )

    return render.Root(
        delay = delay,
        child = render.Box(
            padding = 1,
            child = main_content,
        ),
    )

def render_wide_layout(delay, icon, temp, secondary_temp_text, high_temp, low_temp, humidity, rain, rain_units, pressure, pressure_icon, wind_dir, wind_speed, wind_unit, condition_text, show_labels, show_conditions, show_highlow):
    """
    Render layout for wide 128x64 display (S3 Wide)

    With labels (3 rows):
    Row 1: Icon | Temp | Feels | H:xx L:xx
    Row 2: HUM xx% | Rain: x.xx in | Pres: xx.x
    Row 3: Wind: DIR xxmph | [Conditions if enabled]

    Without labels (2 rows):
    Row 1: Icon | Temp | Feels | H:xx L:xx | xx% | DIR xxmph
    Row 2: Rain: x.xx in | Pres: xx.x | [Conditions]
    """

    # Larger fonts for 128x64 display
    font_large = "10x20"  # For main temp - height 20
    font_med = "6x13"  # For secondary values - height 13
    font_small = "6x10"  # For labels - height 10

    # Build row 1 (common elements: icon, temp, secondary temp, high/low)
    row1_children = _build_main_row(
        icon, temp, secondary_temp_text, high_temp, low_temp,
        show_labels, show_highlow, font_large, font_med, font_small,
    )

    # Add humidity and wind to row 1 if no labels (2-row layout)
    if not show_labels:
        row1_children.append(
            render.Padding(
                pad = (4, 0, 0, 0),
                child = render.Text(content = humidity, color = "#6666FF", font = font_med),
            ),
        )
        row1_children.append(
            render.Padding(
                pad = (4, 0, 0, 0),
                child = render.Column(
                    cross_align = "center",
                    children = [
                        render.Text(content = wind_dir, color = "#66AA66", font = font_small),
                        render.Text(content = wind_speed + wind_unit, color = "#88FF88", font = font_small),
                    ],
                ),
            ),
        )

    row1 = render.Row(
        expanded = True,
        main_align = "start",
        cross_align = "center",
        children = row1_children,
    )

    if show_labels:
        # 3-row layout
        row2 = _build_stats_row(humidity, rain, rain_units, pressure, pressure_icon, font_med, font_small)
        row3 = _build_wind_row(wind_dir, wind_speed, wind_unit, condition_text, show_conditions, font_med, font_small)
        rows = [row1, row2, row3]
    else:
        # 2-row layout
        row2 = _build_secondary_row(rain, rain_units, pressure, pressure_icon, condition_text, show_conditions, font_med)
        rows = [row1, row2]

    return render.Root(
        delay = delay,
        child = render.Padding(
            pad = 2,
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "start",
                children = rows,
            ),
        ),
    )

def _build_main_row(icon, temp, secondary_temp_text, high_temp, low_temp, show_labels, show_highlow, font_large, font_med, font_small):
    """Build the main row with icon, temp, secondary temp, and high/low."""
    children = [
        render.Padding(
            pad = (2, 0, 4, 0),
            child = render.Image(icon),
        ),
        render.Text(content = temp, color = "#22DD22", font = font_large),
    ]

    if secondary_temp_text:
        pad_left = 6 if show_labels else 4
        children.append(
            render.Padding(
                pad = (pad_left, 0, 0, 0),
                child = render.Text(content = secondary_temp_text, color = "#FFFF00", font = font_med),
            ),
        )

    if show_highlow:
        pad_left = 6 if show_labels else 4
        high_text = ("H:" + high_temp) if show_labels else high_temp
        low_text = ("L:" + low_temp) if show_labels else low_temp
        children.append(
            render.Padding(
                pad = (pad_left, 0, 0, 0),
                child = render.Column(
                    cross_align = "start",
                    children = [
                        render.Text(content = high_text, color = "#FF6644", font = font_small),
                        render.Text(content = low_text, color = "#44AAFF", font = font_small),
                    ],
                ),
            ),
        )

    return children

def _build_stats_row(humidity, rain, rain_units, pressure, pressure_icon, font_med, font_small):
    """Build the stats row with humidity, rain, and pressure (3-row layout)."""
    return render.Row(
        expanded = True,
        main_align = "start",
        cross_align = "center",
        children = [
            render.Row(
                cross_align = "center",
                children = [
                    render.Text(content = "HUM ", color = "#4444AA", font = font_small),
                    render.Text(content = humidity, color = "#6666FF", font = font_med),
                ],
            ),
            render.Padding(
                pad = (8, 0, 0, 0),
                child = render.Row(
                    cross_align = "center",
                    children = [
                        render.Text(content = "Rain: ", color = "#666666", font = font_small),
                        render.Text(content = rain + " " + rain_units, color = "#888888", font = font_med),
                    ],
                ),
            ),
            render.Padding(
                pad = (8, 0, 0, 0),
                child = render.Row(
                    cross_align = "center",
                    children = [
                        render.Text(content = "Pres: ", color = "#666666", font = font_small),
                        render.Text(content = pressure + pressure_icon, color = "#FFFFFF", font = font_med),
                    ],
                ),
            ),
        ],
    )

def _build_wind_row(wind_dir, wind_speed, wind_unit, condition_text, show_conditions, font_med, font_small):
    """Build the wind row with optional conditions (3-row layout)."""
    children = [
        render.Row(
            cross_align = "center",
            children = [
                render.Text(content = "Wind: ", color = "#446644", font = font_small),
                render.Text(content = wind_dir + " " + wind_speed + wind_unit, color = "#88FF88", font = font_med),
            ],
        ),
    ]

    if show_conditions and condition_text:
        children.append(
            render.Padding(
                pad = (8, 0, 0, 0),
                child = render.Marquee(
                    width = 60,
                    offset_start = 30,
                    offset_end = 30,
                    child = render.Text(content = condition_text, color = "#AAAAAA", font = font_med),
                ),
            ),
        )

    return render.Row(
        expanded = True,
        main_align = "start",
        cross_align = "center",
        children = children,
    )

def _build_secondary_row(rain, rain_units, pressure, pressure_icon, condition_text, show_conditions, font_med):
    """Build the secondary row with rain, pressure, and conditions (2-row layout)."""
    children = [
        render.Text(content = rain + " " + rain_units, color = "#888888", font = font_med),
        render.Padding(
            pad = (8, 0, 0, 0),
            child = render.Text(content = pressure + " " + pressure_icon, color = "#FFFFFF", font = font_med),
        ),
    ]

    if show_conditions and condition_text:
        children.append(
            render.Padding(
                pad = (8, 0, 0, 0),
                child = render.Marquee(
                    width = 50,
                    offset_start = 25,
                    offset_end = 25,
                    child = render.Text(content = condition_text, color = "#AAAAAA", font = font_med),
                ),
            ),
        )

    return render.Row(
        expanded = True,
        main_align = "start",
        cross_align = "center",
        children = children,
    )

def get_schema():
    secondary_temp_options = [
        schema.Option(
            display = "Feels Like",
            value = "1",
        ),
        schema.Option(
            display = "Dew Point",
            value = "2",
        ),
        schema.Option(
            display = "None (hide)",
            value = "3",
        ),
        schema.Option(
            display = "High/Low",
            value = "4",
        ),
    ]

    return [
        {
            "id": "token",
            "name": "Tempest Token",
            "description": "Connect your Tempest weather station",
            "icon": "cloud",
            "type": "text",
        },
        {
            "id": "station",
            "type": "generated",
            "source": "token",
            "handler": "get_stations",
        },
        {
            "id": "secondary_temp",
            "name": "Secondary Temperature",
            "description": "Show Feels Like, Dew Point, or High/Low next to current temp",
            "type": "dropdown",
            "options": secondary_temp_options,
            "default": "1",
        },
        {
            "id": "show_labels",
            "name": "Show Labels (Wide only)",
            "description": "Show labels like H:/L:, HUM, RAIN, PRES on wide displays",
            "type": "onoff",
            "default": "true",
        },
        {
            "id": "show_highlow",
            "name": "Show High/Low (Wide only)",
            "description": "Show today's forecast high and low on wide displays",
            "type": "onoff",
            "default": "true",
        },
        {
            "id": "show_conditions",
            "name": "Show Conditions",
            "description": "Show scrolling weather condition text (replaces wind on standard display)",
            "type": "onoff",
            "default": "false",
        },
    ]

def get_stations(token):
    if not token:
        return []

    res = http.get(
        url = TEMPEST_STATIONS_URL % token,
    )
    if res.status_code != 200:
        fail("stations request failed with status code: %d" % res.status_code)

    options = [
        schema.Option(
            display = station["name"],
            value = str(int(station["station_id"])),
        )
        for station in res.json()["stations"]
    ]

    return [
        schema.Dropdown(
            id = "station",
            name = "Station",
            icon = "temperatureHigh",
            desc = "Tempest weather station",
            options = options,
            default = options[0].value if options else "",
        ),
    ]

# Home made weather icons
HOMEMADE_ICON = {
    "cloudy.png": CLOUDY_ASSET.readall(),
    "foggy.png": FOGGY_ASSET.readall(),
    "haily.png": HAILY_ASSET.readall(),
    "moony.png": MOONY_ASSET.readall(),
    "rainy.png": RAINY_ASSET.readall(),
    "sleety.png": SLEETY_ASSET.readall(),
    "snowy.png": SNOWY_ASSET.readall(),
    "sunny.png": SUNNY_ASSET.readall(),
    "thundery.png": THUNDERY_ASSET.readall(),
    "tornady.png": TORNADY_ASSET.readall(),
    "windy.png": WINDY_ASSET.readall(),
    "moonyish.png": MOONYISH_ASSET.readall(),
    "sunnyish.png": SUNNYISH_ASSET.readall(),
}

ICON_MAP = {
    "clear-day": HOMEMADE_ICON["sunny.png"],
    "clear-night": HOMEMADE_ICON["moony.png"],
    "cloudy": HOMEMADE_ICON["cloudy.png"],
    "foggy": HOMEMADE_ICON["foggy.png"],
    "partly-cloudy-day": HOMEMADE_ICON["sunnyish.png"],
    "partly-cloudy-night": HOMEMADE_ICON["moonyish.png"],
    "possibly-rainy-day": HOMEMADE_ICON["rainy.png"],
    "possibly-rainy-night": HOMEMADE_ICON["rainy.png"],
    "rainy": HOMEMADE_ICON["rainy.png"],
    "sleet": HOMEMADE_ICON["sleety.png"],
    "snow": HOMEMADE_ICON["snowy.png"],
    "thunderstorm": HOMEMADE_ICON["thundery.png"],
    "windy": HOMEMADE_ICON["windy.png"],
}
