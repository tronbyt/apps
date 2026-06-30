"""
Applet: AccuWeather Forecast
Summary: Display AccuWeather three day forecast
Description: Display AccuWeather three day forecast based on AccuWeather location key. To request an AccuWeather API key, see 
https://developer.accuweather.com/getting-started. To determine AccuWeather location key, search https://www.accuweather.com for
a location and extract trailing number, e.g. 2191987 for https://www.accuweather.com/en/us/lavallette/08735/weather-forecast/2191987.
Author: sudeepban
"""

load("http.star", "http")
load("images/cloudy.png", CLOUDY_CLOUDY_ASSET = "file")
load("images/foggy.png", FOGGY_FOGGY_ASSET = "file")
load("images/haily.png", HAILY_HAILY_ASSET = "file")
load("images/moony.png", MOONY_MOONY_ASSET = "file")
load("images/moonyish.png", MOONYISH_MOONYISH_ASSET = "file")
load("images/rainy.png", RAINY_RAINY_ASSET = "file")
load("images/sleety.png", SLEETY_SLEETY_ASSET = "file")
load("images/sleety2.png", SLEETY2_SLEETY2_ASSET = "file")
load("images/snowy.png", SNOWY_SNOWY_ASSET = "file")
load("images/snowy2.png", SNOWY2_SNOWY2_ASSET = "file")
load("images/sunny.png", SUNNY_SUNNY_ASSET = "file")
load("images/sunnyish.png", SUNNYISH_SUNNYISH_ASSET = "file")
load("images/thundery.png", THUNDERY_THUNDERY_ASSET = "file")
load("images/tornady.png", TORNADY_TORNADY_ASSET = "file")
load("images/wind_e.png", WIND_E_WIND_E_ASSET = "file")
load("images/wind_n.png", WIND_N_WIND_N_ASSET = "file")
load("images/wind_ne.png", WIND_NE_WIND_NE_ASSET = "file")
load("images/wind_nw.png", WIND_NW_WIND_NW_ASSET = "file")
load("images/wind_s.png", WIND_S_WIND_S_ASSET = "file")
load("images/wind_se.png", WIND_SE_WIND_SE_ASSET = "file")
load("images/wind_sw.png", WIND_SW_WIND_SW_ASSET = "file")
load("images/wind_w.png", WIND_W_WIND_W_ASSET = "file")
load("images/windy.png", WINDY_WINDY_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

ACCUWEATHER_FORECAST_URL = "http://dataservice.accuweather.com/forecasts/v1/daily/5day/{location_key}?apikey={api_key}&details=true"

# weather icons borrowed from stock Tidbyt Weather app
WEATHER_ICONS = {
    "cloudy.png": CLOUDY_CLOUDY_ASSET.readall(),
    "foggy.png": FOGGY_FOGGY_ASSET.readall(),
    "haily.png": HAILY_HAILY_ASSET.readall(),
    "moony.png": MOONY_MOONY_ASSET.readall(),
    "moonyish.png": MOONYISH_MOONYISH_ASSET.readall(),
    "rainy.png": RAINY_RAINY_ASSET.readall(),
    "sleety.png": SLEETY_SLEETY_ASSET.readall(),
    "sleety2.png": SLEETY2_SLEETY2_ASSET.readall(),
    "snowy.png": SNOWY_SNOWY_ASSET.readall(),
    "snowy2.png": SNOWY2_SNOWY2_ASSET.readall(),
    "sunny.png": SUNNY_SUNNY_ASSET.readall(),
    "sunnyish.png": SUNNYISH_SUNNYISH_ASSET.readall(),
    "thundery.png": THUNDERY_THUNDERY_ASSET.readall(),
    "tornady.png": TORNADY_TORNADY_ASSET.readall(),
    "windy.png": WINDY_WINDY_ASSET.readall(),
}

# wind icons representing wind direction as arrows
WIND_ICONS = {
    "E": WIND_E_WIND_E_ASSET.readall(),
    "N": WIND_N_WIND_N_ASSET.readall(),
    "NE": WIND_NE_WIND_NE_ASSET.readall(),
    "NW": WIND_NW_WIND_NW_ASSET.readall(),
    "S": WIND_S_WIND_S_ASSET.readall(),
    "SE": WIND_SE_WIND_SE_ASSET.readall(),
    "SW": WIND_SW_WIND_SW_ASSET.readall(),
    "W": WIND_W_WIND_W_ASSET.readall(),
}

def get_temp(f_temp, display_celsius):
    if display_celsius:
        return int(math.round((f_temp - 32) / 1.8))
    return f_temp

def get_result_forecast(dow, temp_min, temp_max, icon_num, wind_dir, display_celsius):
    result_forecast = {}
    result_forecast["dow"] = dow
    result_forecast["temp_min"] = get_temp(temp_min, display_celsius)
    result_forecast["temp_max"] = get_temp(temp_max, display_celsius)
    result_forecast["icon_num"] = icon_num
    result_forecast["wind_dir"] = wind_dir
    return result_forecast

def main(config):
    api_key = config.get("apiKey", None)
    location_key = config.get("locationKey", None)
    temp_units = config.get("tempUnits", "F")

    display_sample = not (api_key and location_key)
    display_celsius = (temp_units == "C")

    result_forecasts = []

    if display_sample:
        # sample data to display if user-specified API / location key are not available, also useful for testing
        result_forecasts.append(get_result_forecast("Mon", 65, 75, 1, "N", display_celsius))
        result_forecasts.append(get_result_forecast("Tue", 66, 74, 12, "NE", display_celsius))
        result_forecasts.append(get_result_forecast("Wed", 68, 78, 15, "E", display_celsius))
    else:
        resp = http.get(ACCUWEATHER_FORECAST_URL.format(location_key = location_key, api_key = api_key), ttl_seconds = 3600)
        if resp.status_code != 200:
            fail("AccuWeather forecast request failed with status", resp.status_code)

        resp_json = resp.json()

        raw_forecasts = resp_json["DailyForecasts"]

        for raw_forecast in raw_forecasts[:3]:
            result_forecasts.append(get_result_forecast(
                time.parse_time(raw_forecast["Date"]).format("Mon").upper(),
                int(raw_forecast["Temperature"]["Minimum"]["Value"]),
                int(raw_forecast["Temperature"]["Maximum"]["Value"]),
                int(raw_forecast["Day"]["Icon"]),
                raw_forecast["Day"]["Wind"]["Direction"]["English"],
                display_celsius,
            ))

    disp_forecasts = []

    for result_forecast in result_forecasts:
        rows = []

        # weather icon, reduce AccuWeather icons to smaller set, see https://developer.accuweather.com/weather-icons
        icon_num = result_forecast["icon_num"]

        if icon_num == 1:
            # sunny
            icon = WEATHER_ICONS["sunny.png"]
        elif icon_num >= 2 and icon_num <= 5:
            # mostly sunny
            icon = WEATHER_ICONS["sunnyish.png"]
        elif (icon_num >= 6 and icon_num <= 8) or icon_num == 11:
            # cloudy
            icon = WEATHER_ICONS["cloudy.png"]
        elif (icon_num >= 12 and icon_num <= 14) or icon_num == 18:
            # rain
            icon = WEATHER_ICONS["rainy.png"]
        elif icon_num >= 15 and icon_num <= 17:
            # thunderstorm
            icon = WEATHER_ICONS["thundery.png"]
        elif (icon_num >= 19 and icon_num <= 26) or icon_num == 29:
            # snow
            icon = WEATHER_ICONS["snowy2.png"]
        elif icon_num == 32:
            # wind
            icon = WEATHER_ICONS["windy.png"]
        else:
            icon = None

        if icon:
            rows.append(render.Image(width = 13, height = 13, src = icon))
        else:
            rows.append(render.Box(width = 13, height = 13))

        # day of week and high / low temperature
        rows.append(render.Text(result_forecast["dow"], font = "CG-pixel-3x5-mono", color = "#ffffff"))
        rows.append(render.Box(width = 1, height = 1))
        col = render.Row(
            children = [
                render.Text(str(result_forecast["temp_max"]), font = "tom-thumb", color = "#FA8072"),
                render.Box(width = 1, height = 1),
                render.Text(str(result_forecast["temp_min"]), font = "tom-thumb", color = "#0096FF"),
            ],
            main_align = "center",
        )
        rows.append(col)

        # wind direction, reduce to cardinal and ordinal directions only
        wind_dir = str(result_forecast["wind_dir"])

        if wind_dir == "NNE" or wind_dir == "ENE":
            wind_dir = "NE"
        elif wind_dir == "ESE" or wind_dir == "SSE":
            wind_dir = "SE"
        elif wind_dir == "SSW" or wind_dir == "WSW":
            wind_dir = "SW"
        elif wind_dir == "WNW" or wind_dir == "NNW":
            wind_dir = "NW"

        arrow_src = WIND_ICONS[wind_dir]
        if arrow_src:
            rows.append(render.Image(width = 7, height = 7, src = arrow_src))
        else:
            rows.append(render.Box(width = 7, height = 7))

        disp_forecasts.append(rows)

    return render.Root(
        child = render.Stack(
            children = [
                render.Row(
                    children = [
                        render.Column(
                            children = disp_forecasts[0],
                            main_align = "center",
                            cross_align = "center",
                        ),
                        render.Column(
                            children = [render.Box(width = 1, height = 32, color = "#5A5A5A")],
                        ),
                        render.Column(
                            children = disp_forecasts[1],
                            main_align = "center",
                            cross_align = "center",
                        ),
                        render.Column(
                            children = [render.Box(width = 1, height = 32, color = "#5A5A5A")],
                        ),
                        render.Column(
                            children = disp_forecasts[2],
                            main_align = "center",
                            cross_align = "center",
                        ),
                    ],
                    main_align = "space_evenly",
                    expanded = True,
                ),
                render.Row(
                    children = [render.Text("SAMPLE" if display_sample else "", font = "6x13", color = "#FF0000", height = 22)],
                    main_align = "center",
                    expanded = True,
                ),
            ],
        ),
    )

def get_schema():
    tempUnitsOptions = [
        schema.Option(
            display = "Fahrenheit",
            value = "F",
        ),
        schema.Option(
            display = "Celsius",
            value = "C",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "apiKey",
                name = "AccuWeather API Key",
                desc = "API key for AccuWeather data access",
                icon = "gear",
                secret = True,
            ),
            # would prefer to use https://developer.accuweather.com/accuweather-locations-api/apis/get/locations/v1/cities/geoposition/search
            # with LocationBased to determine AccuWeather location key, but geoposition search API will require user-specified AccuWeather API key
            schema.Text(
                id = "locationKey",
                name = "AccuWeather Location Key",
                desc = "Location key for AccuWeather data access",
                icon = "locationDot",
                secret = True,
            ),
            schema.Dropdown(
                id = "tempUnits",
                name = "Temperature units",
                desc = "The units for temperature display",
                icon = "gear",
                default = tempUnitsOptions[0].value,
                options = tempUnitsOptions,
            ),
        ],
    )
