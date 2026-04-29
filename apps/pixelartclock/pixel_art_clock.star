"""
Applet: Pixel Art Clock
Summary: Clock & pixel-art weather
Description: Displays a clock, today's max and min temperatures, with a pixel-art illustration by @abipixel matching today's forecast from AccuWeather. To request an AccuWeather API key, see https://developer.accuweather.com/getting-started. To determine AccuWeather location key, search https://www.accuweather.com for a location and extract trailing number, e.g. 2191987 for https://www.accuweather.com/en/us/lavallette/08735/weather-forecast/2191987.
Author: JavierM42
"""

# Based on the AccuWeather Forecast app by sudeepban

load("animation.star", "animation")
load("http.star", "http")
load("images/clear_night_background.png", CLEAR_NIGHT_BACKGROUND_ASSET = "file")
load("images/clear_night_background@2x.png", CLEAR_NIGHT_BACKGROUND_ASSET_2X = "file")
load("images/cloudy_background.png", CLOUDY_BACKGROUND_ASSET = "file")
load("images/cloudy_background@2x.png", CLOUDY_BACKGROUND_ASSET_2X = "file")
load("images/cloudy_night_background.png", CLOUDY_NIGHT_BACKGROUND_ASSET = "file")
load("images/cloudy_night_background@2x.png", CLOUDY_NIGHT_BACKGROUND_ASSET_2X = "file")
load("images/large_lightning.png", LARGE_LIGHTNING_ASSET = "file")
load("images/large_lightning@2x.png", LARGE_LIGHTNING_ASSET_2X = "file")
load("images/rain_for_animation.png", RAIN_FOR_ANIMATION_ASSET = "file")
load("images/rain_for_animation@2x.png", RAIN_FOR_ANIMATION_ASSET_2X = "file")
load("images/rainy_background.png", RAINY_BACKGROUND_ASSET = "file")
load("images/rainy_background@2x.png", RAINY_BACKGROUND_ASSET_2X = "file")
load("images/rainy_foreground.png", RAINY_FOREGROUND_ASSET = "file")
load("images/rainy_foreground@2x.png", RAINY_FOREGROUND_ASSET_2X = "file")
load("images/small_lightning.png", SMALL_LIGHTNING_ASSET = "file")
load("images/small_lightning@2x.png", SMALL_LIGHTNING_ASSET_2X = "file")
load("images/snowy_background.png", SNOWY_BACKGROUND_ASSET = "file")
load("images/snowy_background@2x.png", SNOWY_BACKGROUND_ASSET_2X = "file")
load("images/sun.png", SUN_ASSET = "file")
load("images/sun@2x.png", SUN_ASSET_2X = "file")
load("images/sun_with_rays.png", SUN_WITH_RAYS_ASSET = "file")
load("images/sun_with_rays@2x.png", SUN_WITH_RAYS_ASSET_2X = "file")
load("images/sunny_background.png", SUNNY_BACKGROUND_ASSET = "file")
load("images/sunny_background@2x.png", SUNNY_BACKGROUND_ASSET_2X = "file")
load("images/sunny_foreground.png", SUNNY_FOREGROUND_ASSET = "file")
load("images/sunny_foreground@2x.png", SUNNY_FOREGROUND_ASSET_2X = "file")
load("images/sunnyish_background.png", SUNNYISH_BACKGROUND_ASSET = "file")
load("images/sunnyish_background@2x.png", SUNNYISH_BACKGROUND_ASSET_2X = "file")
load("images/thunderstorm_background.png", THUNDERSTORM_BACKGROUND_ASSET = "file")
load("images/thunderstorm_background@2x.png", THUNDERSTORM_BACKGROUND_ASSET_2X = "file")
load("images/thunderstorm_foreground.png", THUNDERSTORM_FOREGROUND_ASSET = "file")
load("images/thunderstorm_foreground@2x.png", THUNDERSTORM_FOREGROUND_ASSET_2X = "file")
load("images/windy_background.png", WINDY_BACKGROUND_ASSET = "file")
load("images/windy_background@2x.png", WINDY_BACKGROUND_ASSET_2X = "file")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

IS_2X = canvas.is2x()
SCALE = 2 if IS_2X else 1
CLOCK_FONT = "terminus-32" if IS_2X else "10x20"
TEMP_FONT = "6x13" if IS_2X else "tom-thumb"
SAMPLE_FONT = "terminus-24" if IS_2X else "6x13"

LARGE_LIGHTNING = (LARGE_LIGHTNING_ASSET_2X if IS_2X else LARGE_LIGHTNING_ASSET).readall()
RAIN_FOR_ANIMATION = (RAIN_FOR_ANIMATION_ASSET_2X if IS_2X else RAIN_FOR_ANIMATION_ASSET).readall()
SMALL_LIGHTNING = (SMALL_LIGHTNING_ASSET_2X if IS_2X else SMALL_LIGHTNING_ASSET).readall()
SUN = (SUN_ASSET_2X if IS_2X else SUN_ASSET).readall()
SUN_WITH_RAYS = (SUN_WITH_RAYS_ASSET_2X if IS_2X else SUN_WITH_RAYS_ASSET).readall()

ACCUWEATHER_FORECAST_URL = "http://dataservice.accuweather.com/forecasts/v1/daily/1day/{location_key}?apikey={api_key}&details=true"

max_temp_color = "#fcc"
min_temp_color = "#ccf"

clock_colors = {
    "sunny": "#fff",
    "sunnyish": "#000",
    "rainy": "#000",
    "thunderstorm": "#fff",
    "cloudy": "#000",
    "clear_night": "#fff",
    "cloudy_night": "#fff",
    "windy": "#000",
    "snowy": "#fff",
}

sunny = {
    "background": render.Image(src = (SUNNY_BACKGROUND_ASSET_2X if canvas.is2x() else SUNNY_BACKGROUND_ASSET).readall()),
    "foreground": render.Stack(children = [
        render.Image(src = (SUNNY_FOREGROUND_ASSET_2X if canvas.is2x() else SUNNY_FOREGROUND_ASSET).readall()),
        render.Animation(
            children = [
                render.Image(src = SUN),
                render.Image(src = SUN),
                render.Image(src = SUN_WITH_RAYS),
                render.Image(src = SUN_WITH_RAYS),
            ],
        ),
    ]),
}

sunnyish = {
    "background": render.Image(src = (SUNNYISH_BACKGROUND_ASSET_2X if canvas.is2x() else SUNNYISH_BACKGROUND_ASSET).readall()),
    "foreground": None,
}

rainy = {
    "background": render.Image(src = (RAINY_BACKGROUND_ASSET_2X if IS_2X else RAINY_BACKGROUND_ASSET).readall()),
    "foreground": render.Stack(children = [
        render.Image(src = (RAINY_FOREGROUND_ASSET_2X if IS_2X else RAINY_FOREGROUND_ASSET).readall()),
        animation.Transformation(
            child = render.Image(src = RAIN_FOR_ANIMATION, width = 124 * SCALE, height = 63 * SCALE),
            duration = 8,
            delay = 0,
            keyframes = [
                animation.Keyframe(
                    percentage = 0.0,
                    transforms = [animation.Translate(15 * SCALE, -15 * SCALE)],
                    curve = "linear",
                ),
                animation.Keyframe(
                    percentage = 1.0,
                    transforms = [animation.Translate(-15 * SCALE, 15 * SCALE)],
                ),
            ],
        ),
    ]),
}

thunderstorm = {
    "background": render.Image(src = (THUNDERSTORM_BACKGROUND_ASSET_2X if IS_2X else THUNDERSTORM_BACKGROUND_ASSET).readall()),
    "foreground": render.Stack(children = [
        render.Animation(
            children = [
                render.Box(width = 1 * SCALE, height = 1 * SCALE),
                render.Box(width = 1 * SCALE, height = 1 * SCALE),
                render.Image(src = SMALL_LIGHTNING),
                render.Box(width = 1 * SCALE, height = 1 * SCALE),
                render.Box(width = 1 * SCALE, height = 1 * SCALE),
                render.Box(width = 1 * SCALE, height = 1 * SCALE),
                render.Image(src = SMALL_LIGHTNING),
                render.Image(src = LARGE_LIGHTNING),
            ],
        ),
        render.Image(src = (THUNDERSTORM_FOREGROUND_ASSET_2X if IS_2X else THUNDERSTORM_FOREGROUND_ASSET).readall()),
    ]),
}

cloudy = {
    "background": render.Image(src = (CLOUDY_BACKGROUND_ASSET_2X if canvas.is2x() else CLOUDY_BACKGROUND_ASSET).readall()),
    "foreground": None,
}

clear_night = {
    "background": render.Image(src = (CLEAR_NIGHT_BACKGROUND_ASSET_2X if canvas.is2x() else CLEAR_NIGHT_BACKGROUND_ASSET).readall()),
    "foreground": None,
}

cloudy_night = {
    "background": render.Image(src = (CLOUDY_NIGHT_BACKGROUND_ASSET_2X if canvas.is2x() else CLOUDY_NIGHT_BACKGROUND_ASSET).readall()),
    "foreground": None,
}

windy = {
    "background": render.Image(src = (WINDY_BACKGROUND_ASSET_2X if canvas.is2x() else WINDY_BACKGROUND_ASSET).readall()),
    "foreground": None,
}

snowy = {
    "background": render.Image(src = (SNOWY_BACKGROUND_ASSET_2X if canvas.is2x() else SNOWY_BACKGROUND_ASSET).readall()),
    "foreground": None,
}

illustrations = {
    "sunny": sunny,
    "sunnyish": sunnyish,
    "rainy": rainy,
    "thunderstorm": thunderstorm,
    "cloudy": cloudy,
    "clear_night": clear_night,
    "cloudy_night": cloudy_night,
    "windy": windy,
    "snowy": snowy,
}

def get_temp(f_temp, display_celsius):
    if display_celsius:
        return int(math.round((f_temp - 32) / 1.8))
    return f_temp

def get_result_forecast(temp_min, temp_max, icon_num, display_celsius):
    return {
        "temp_min": get_temp(temp_min, display_celsius),
        "temp_max": get_temp(temp_max, display_celsius),
        "icon_num": icon_num,
    }

def main(config):
    api_key = config.get("apiKey", None)
    location_key = config.get("locationKey", None)
    temp_units = config.get("tempUnits", "F")

    # clock
    timezone = config.get("timezone", "America/New_York")
    now = time.now().in_location(timezone)

    # get weather info
    display_sample = not (api_key and location_key)
    display_celsius = (temp_units == "C")

    if display_sample:
        # sample data to display if user-specified API / location key are not available, also useful for testing
        result_forecast = get_result_forecast(65, 75, 1, display_celsius)
    else:
        resp = http.get(ACCUWEATHER_FORECAST_URL.format(location_key = location_key, api_key = api_key), ttl_seconds = 3600)
        if resp.status_code != 200:
            fail("AccuWeather forecast request failed with status", resp.status_code)

        resp_json = resp.json()

        raw_forecast = resp_json["DailyForecasts"][0]

        # day/night
        rise_epoch = int(raw_forecast["Sun"]["EpochRise"])
        set_epoch = int(raw_forecast["Sun"]["EpochSet"])
        now_epoch = now.unix
        is_day = (rise_epoch <= now_epoch) and (now_epoch <= set_epoch)
        day_or_night = "Day" if is_day else "Night"

        result_forecast = get_result_forecast(
            int(raw_forecast["Temperature"]["Minimum"]["Value"]),
            int(raw_forecast["Temperature"]["Maximum"]["Value"]),
            int(raw_forecast[day_or_night]["Icon"]),
            display_celsius,
        )

    # # weather icon, see https://developer.accuweather.com/weather-icons
    icon_num = result_forecast["icon_num"]

    if icon_num == 1:
        # sunny
        weather = "sunny"
    elif icon_num >= 2 and icon_num <= 5:
        # mostly sunny
        weather = "sunnyish"
    elif (icon_num >= 6 and icon_num <= 8) or icon_num == 11:
        # cloudy
        weather = "cloudy"
    elif (icon_num >= 12 and icon_num <= 14) or icon_num == 18 or icon_num == 39 or icon_num == 40:
        # rainy
        weather = "rainy"
    elif icon_num >= 15 and icon_num <= 17 or icon_num == 41 or icon_num == 42:
        # thunderstorm
        weather = "thunderstorm"
    elif (icon_num >= 19 and icon_num <= 26) or icon_num == 29 or icon_num == 43 or icon_num == 44:
        # snow
        weather = "snowy"
    elif icon_num == 32:
        # wind
        weather = "windy"
    elif (icon_num >= 33 and icon_num <= 34):
        # clear night
        weather = "clear_night"
    elif (icon_num >= 35 and icon_num <= 38):
        # cloudy night
        weather = "cloudy_night"
    else:
        # default to sunny, but should never happen
        weather = "sunny"

    # temperatures
    temperatures = render.Column(
        children = [
            render.Text(str(result_forecast["temp_max"]), font = TEMP_FONT, color = max_temp_color, height = 7 * SCALE, offset = -1 * SCALE),
            render.Text(str(result_forecast["temp_min"]), font = TEMP_FONT, color = min_temp_color, height = 7 * SCALE, offset = -1 * SCALE),
        ],
        main_align = "center",
        cross_align = "end",
    )

    clock_color = clock_colors[weather]
    clock = render.Box(
        width = 45 * SCALE,
        height = 15 * SCALE,
        child = render.Row(
            children = [
                render.Box(
                    child = render.Text(
                        content = now.format("15"),
                        font = CLOCK_FONT,
                        color = clock_color,
                    ),
                    width = 18 * SCALE,
                    height = 14 * SCALE,
                ),
                render.Box(
                    width = 9 * SCALE,
                    height = 7 * SCALE,
                    child = render.Animation(
                        children = [
                            render.Column(
                                children = [
                                    render.Box(width = 3 * SCALE, height = 2 * SCALE, color = clock_color),
                                    render.Box(width = 3 * SCALE, height = 3 * SCALE),
                                    render.Box(width = 3 * SCALE, height = 2 * SCALE, color = clock_color),
                                ],
                            ),
                            render.Box(width = 3 * SCALE, height = 7 * SCALE),
                        ],
                    ),
                ),
                render.Box(
                    child = render.Text(
                        content = now.format("04"),
                        font = CLOCK_FONT,
                        color = clock_color,
                    ),
                    width = 19 * SCALE,
                    height = 14 * SCALE,
                ),
            ],
            cross_align = "center",
        ),
    )

    # illustration
    illustration = illustrations[weather]

    # arrange elements
    return render.Root(
        delay = 500,
        child = render.Stack(
            children = [
                illustration["background"],
                render.Box(
                    padding = 2 * SCALE,
                    child = render.Row(children = [
                        render.Column(children = [clock], main_align = "start", cross_align = "start", expanded = True),
                    ], main_align = "start", cross_align = "start", expanded = True),
                ),
                illustration["foreground"],
                render.Box(
                    padding = 2 * SCALE,
                    child = render.Row(children = [
                        render.Column(children = [temperatures], main_align = "end", cross_align = "start", expanded = True),
                    ], main_align = "start", cross_align = "end", expanded = True),
                ),
                render.Row(
                    children = [render.Text("SAMPLE" if display_sample else "", font = SAMPLE_FONT, color = "#FF0000", height = 22 * SCALE)],
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
            schema.Text(
                id = "locationKey",
                name = "AccuWeather Location Key",
                desc = "Location key for AccuWeather data access",
                icon = "locationDot",
                secret = True,
            ),
            schema.Text(
                id = "timezone",
                name = "Timezone",
                desc = "Timezone for clock",
                icon = "clock",
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
