"""
Applet: Pixel Art Clock
Summary: Clock & pixel-art weather
Description: Displays a clock, the coming 24 hours' high and low temperatures, and a pixel-art illustration by @abipixel matching the local forecast from OpenWeatherMap. Get a free API key at https://home.openweathermap.org/api_keys — the standard free tier is all this app needs (new keys can take up to two hours to activate; the app shows sample data until then).
Author: JavierM42
"""

# Based on the AccuWeather Forecast app by sudeepban.
# OpenWeatherMap port: uses the free 5 day / 3 hour forecast API
# (https://openweathermap.org/forecast5) instead of AccuWeather.

load("animation.star", "animation")
load("encoding/json.star", "json")
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

# Free-tier 5 day / 3 hour forecast. cnt=8 limits the response to the next
# 24 hours — the window the displayed high/low covers. units=imperial keeps
# the internal pipeline in °F like the original app; get_temp converts for
# display.
OPENWEATHER_FORECAST_URL = "https://api.openweathermap.org/data/2.5/forecast?lat={lat}&lon={lon}&appid={api_key}&units=imperial&cnt=8"

DEFAULT_LOCATION = json.encode({
    "lat": "40.678",
    "lng": "-73.944",
    "description": "Brooklyn, NY, USA",
    "locality": "Brooklyn",
    "place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
    "timezone": "America/New_York",
})

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

def get_result_forecast(temp_min, temp_max, condition_id, is_day, display_celsius):
    return {
        "temp_min": get_temp(temp_min, display_celsius),
        "temp_max": get_temp(temp_max, display_celsius),
        "condition_id": condition_id,
        "is_day": is_day,
    }

# Maps an OpenWeatherMap condition id (https://openweathermap.org/weather-conditions)
# to one of the nine illustrations. Rain/thunder/snow reuse the day art at
# night, matching the original app's handling of AccuWeather night icons.
def get_weather(condition_id, is_day):
    if condition_id >= 200 and condition_id < 300:
        # thunderstorm
        return "thunderstorm"
    elif condition_id == 511:
        # freezing rain — OWM's icon taxonomy gives 511 the snow icon (13d),
        # and the AccuWeather original showed snow art for freezing rain
        return "snowy"
    elif condition_id >= 300 and condition_id < 600:
        # drizzle and rain
        return "rainy"
    elif condition_id >= 600 and condition_id < 700:
        # snow and sleet
        return "snowy"
    elif condition_id == 771 or condition_id == 781:
        # squall / tornado — OWM has no plain "windy" condition,
        # these are the only wind-driven codes
        return "windy"
    elif condition_id >= 700 and condition_id < 800:
        # atmosphere: mist, haze, fog, dust, ash
        return "cloudy" if is_day else "cloudy_night"
    elif condition_id == 800:
        # clear sky
        return "sunny" if is_day else "clear_night"
    elif condition_id == 801:
        # few clouds (11-25%)
        return "sunnyish" if is_day else "clear_night"
    elif condition_id == 802:
        # scattered clouds (25-50%)
        return "sunnyish" if is_day else "cloudy_night"
    elif condition_id == 803 or condition_id == 804:
        # broken / overcast clouds
        return "cloudy" if is_day else "cloudy_night"
    else:
        # default to clear, but should never happen
        return "sunny" if is_day else "clear_night"

def main(config):
    api_key = config.get("owmApiKey", None)
    temp_units = config.get("tempUnits", "F")
    raw_location = config.get("location")
    location = json.decode(raw_location or DEFAULT_LOCATION)

    # clock — a user-picked location's timezone wins; otherwise the device's
    # own timezone ($tz, supplied by the server); otherwise Eastern
    timezone = (location.get("timezone") if raw_location else None) or config.get("$tz") or "America/New_York"
    now = time.now().in_location(timezone)

    # get weather info
    display_sample = not api_key
    display_celsius = (temp_units == "C")

    result_forecast = None
    if not display_sample:
        url = OPENWEATHER_FORECAST_URL.format(
            lat = location["lat"],
            lon = location["lng"],
            api_key = api_key,
        )
        resp = http.get(url, ttl_seconds = 3600)
        if resp.status_code == 401:
            # a fresh OWM key can take up to ~2 hours to activate (and a
            # leftover key from the AccuWeather era is also a 401 here) —
            # show the sample display rather than a hard error
            display_sample = True
        elif resp.status_code != 200:
            # other failures are transient; fail() keeps the last good render
            fail("OpenWeatherMap forecast request failed with status", resp.status_code)
        else:
            resp_json = resp.json()

            # day/night
            rise_epoch = int(resp_json["city"]["sunrise"])
            set_epoch = int(resp_json["city"]["sunset"])
            now_epoch = now.unix
            is_day = (rise_epoch <= now_epoch) and (now_epoch <= set_epoch)

            # high/low across the coming 24 hours (8 x 3h slices). The free
            # forecast API only carries future slices, so a true calendar-day
            # range isn't available; a rolling 24h window stays meaningful at
            # any hour of the day.
            entries = resp_json["list"]
            temp_min = entries[0]["main"]["temp_min"]
            temp_max = entries[0]["main"]["temp_max"]
            for entry in entries:
                if entry["main"]["temp_min"] < temp_min:
                    temp_min = entry["main"]["temp_min"]
                if entry["main"]["temp_max"] > temp_max:
                    temp_max = entry["main"]["temp_max"]

            result_forecast = get_result_forecast(
                int(math.round(temp_min)),
                int(math.round(temp_max)),
                int(entries[0]["weather"][0]["id"]),
                is_day,
                display_celsius,
            )

    if display_sample:
        # sample data when no (working) API key is available, also useful for testing
        result_forecast = get_result_forecast(65, 75, 800, True, display_celsius)

    weather = get_weather(result_forecast["condition_id"], result_forecast["is_day"])

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
    twelve_hour = (config.get("clockFormat", "24") == "12")
    blink_colon = config.bool("blinkColon", True)
    colon_dots = render.Column(
        children = [
            render.Box(width = 3 * SCALE, height = 2 * SCALE, color = clock_color),
            render.Box(width = 3 * SCALE, height = 3 * SCALE),
            render.Box(width = 3 * SCALE, height = 2 * SCALE, color = clock_color),
        ],
    )
    clock_children = [
        render.Box(
            child = render.Text(
                # 12-hour mode drops the leading zero, clock-style
                content = now.format("3" if twelve_hour else "15"),
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
                    colon_dots,
                    render.Box(width = 3 * SCALE, height = 7 * SCALE),
                ],
            ) if blink_colon else colon_dots,
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
    ]
    clock = render.Box(
        width = 45 * SCALE,
        height = 15 * SCALE,
        child = render.Row(
            children = clock_children,
            cross_align = "center",
        ),
    )
    if twelve_hour:
        # AM/PM sits under the minutes, alarm-clock style, so it stays
        # clear of the top-right art (e.g. the sun) on 64-wide displays
        clock = render.Column(
            children = [
                clock,
                render.Box(
                    width = 45 * SCALE,
                    height = 7 * SCALE,
                    child = render.Row(
                        children = [
                            render.Text(
                                content = now.format("PM"),
                                font = TEMP_FONT,
                                color = clock_color,
                            ),
                        ],
                        main_align = "end",
                        expanded = True,
                    ),
                ),
            ],
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
    clockFormatOptions = [
        schema.Option(
            display = "24-hour",
            value = "24",
        ),
        schema.Option(
            display = "12-hour with AM/PM",
            value = "12",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                # deliberately NOT reusing the old "apiKey" field id: configs
                # from the AccuWeather era hold a key that's meaningless here,
                # and a fresh id lets those installs degrade to sample mode
                id = "owmApiKey",
                name = "OpenWeatherMap API Key",
                desc = "Free API key from https://home.openweathermap.org/api_keys",
                icon = "gear",
                secret = True,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for the weather forecast and clock timezone",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "clockFormat",
                name = "Clock format",
                desc = "24-hour or 12-hour time",
                icon = "clock",
                default = clockFormatOptions[0].value,
                options = clockFormatOptions,
            ),
            schema.Toggle(
                id = "blinkColon",
                name = "Blinking colon",
                desc = "Whether the clock's colon blinks",
                icon = "clock",
                default = True,
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
