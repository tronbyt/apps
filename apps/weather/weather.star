"""
Applet: Weather
Summary: Weather forecast
Description: Weather forecasts for your location.
Authors: JeffLac, RichardD012 (Recreation of Tidbyt Original)

"""

load("encoding/json.star", "json")
load("http.star", "http")
load("i18n.star", "tr")
load("images/clear.png", CLEAR_IMAGE = "file")
load("images/clear@2x.png", CLEAR_IMAGE_2X = "file")
load("images/clear_full.png", CLEAR_FULL_IMAGE = "file")
load("images/clear_full@2x.png", CLEAR_FULL_IMAGE_2X = "file")
load("images/clouds.png", CLOUDS_IMAGE = "file")
load("images/clouds@2x.png", CLOUDS_IMAGE_2X = "file")
load("images/clouds_full.png", CLOUDS_FULL_IMAGE = "file")
load("images/clouds_full@2x.png", CLOUDS_FULL_IMAGE_2X = "file")
load("images/drizzle.png", DRIZZLE_IMAGE = "file")
load("images/drizzle@2x.png", DRIZZLE_IMAGE_2X = "file")
load("images/drizzle_full.png", DRIZZLE_FULL_IMAGE = "file")
load("images/drizzle_full@2x.png", DRIZZLE_FULL_IMAGE_2X = "file")
load("images/fog.png", FOG_IMAGE = "file")
load("images/fog@2x.png", FOG_IMAGE_2X = "file")
load("images/hail.png", HAIL_IMAGE = "file")
load("images/hail@2x.png", HAIL_IMAGE_2X = "file")
load("images/mist.png", MIST_IMAGE = "file")
load("images/mist@2x.png", MIST_IMAGE_2X = "file")
load("images/mist_full.png", MIST_FULL_IMAGE = "file")
load("images/mist_full@2x.png", MIST_FULL_IMAGE_2X = "file")
load("images/moon.png", MOON_IMAGE = "file")
load("images/moon@2x.png", MOON_IMAGE_2X = "file")
load("images/moonish.png", MOONISH_IMAGE = "file")
load("images/moonish@2x.png", MOONISH_IMAGE_2X = "file")
load("images/partly_sun.png", PARTLY_SUN_IMAGE = "file")
load("images/partly_sun@2x.png", PARTLY_SUN_IMAGE_2X = "file")
load("images/partly_sun_full.png", PARTLY_SUN_FULL_IMAGE = "file")
load("images/partly_sun_full@2x.png", PARTLY_SUN_FULL_IMAGE_2X = "file")
load("images/rain.png", RAIN_IMAGE = "file")
load("images/rain@2x.png", RAIN_IMAGE_2X = "file")
load("images/rain_full.png", RAIN_FULL_IMAGE = "file")
load("images/rain_full@2x.png", RAIN_FULL_IMAGE_2X = "file")
load("images/sleet.png", SLEET_IMAGE = "file")
load("images/sleet@2x.png", SLEET_IMAGE_2X = "file")
load("images/snow.png", SNOW_IMAGE = "file")
load("images/snow@2x.png", SNOW_IMAGE_2X = "file")
load("images/snow_full.png", SNOW_FULL_IMAGE = "file")
load("images/snow_full@2x.png", SNOW_FULL_IMAGE_2X = "file")
load("images/squall.png", SQUALL_IMAGE = "file")
load("images/squall@2x.png", SQUALL_IMAGE_2X = "file")
load("images/thunderstorm.png", THUNDERSTORM_IMAGE = "file")
load("images/thunderstorm@2x.png", THUNDERSTORM_IMAGE_2X = "file")
load("images/thunderstorm_full.png", THUNDERSTORM_FULL_IMAGE = "file")
load("images/thunderstorm_full@2x.png", THUNDERSTORM_FULL_IMAGE_2X = "file")
load("images/tornado.png", TORNADO_IMAGE = "file")
load("images/tornado@2x.png", TORNADO_IMAGE_2X = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_LOCATION = """
{
	"lat": "40.6781784",
	"lng": "-73.9441579",
	"description": "Brooklyn, NY, USA",
	"locality": "Brooklyn",
	"place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
	"timezone": "America/New_York"
}
"""

DEFAULT_CACHE_MINS = 5

WEATHER_FULL_IMAGE = {
    "Thunderstorm": THUNDERSTORM_FULL_IMAGE,
    "Clear": CLEAR_FULL_IMAGE,
    "Clouds": CLOUDS_FULL_IMAGE,
    "Snow": SNOW_FULL_IMAGE,
    "Partly_Sun": PARTLY_SUN_FULL_IMAGE,
    "Mist": MIST_FULL_IMAGE,
    "Drizzle": DRIZZLE_FULL_IMAGE,
    "Rain": RAIN_FULL_IMAGE,
}

WEATHER_FULL_IMAGE_2X = {
    "Thunderstorm": THUNDERSTORM_FULL_IMAGE_2X,
    "Clear": CLEAR_FULL_IMAGE_2X,
    "Clouds": CLOUDS_FULL_IMAGE_2X,
    "Snow": SNOW_FULL_IMAGE_2X,
    "Partly_Sun": PARTLY_SUN_FULL_IMAGE_2X,
    "Mist": MIST_FULL_IMAGE_2X,
    "Drizzle": DRIZZLE_FULL_IMAGE_2X,
    "Rain": RAIN_FULL_IMAGE_2X,
}

def main(config):
    # Get configuration values with defaults
    scale = 2 if canvas.is2x() else 1
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)

    # don't need locality anymore because we are using lat and lng
    # locality = loc["locality"]
    lat = loc["lat"]
    lng = loc["lng"]
    units = config.get("units", "imperial")
    showthreeday = config.bool("showthreeday", False)  # Add new config option

    # Get API keys - check for both V3 and V2.5
    api_v3_key = config.get("api_v3", "")
    api_v2_key = config.get("api_v2", config.get("api", ""))  # fallback to original field for backward compatibility

    cache_mins_str = config.str("cache_mins", str(DEFAULT_CACHE_MINS))
    cache_mins = int(cache_mins_str) if cache_mins_str.isdigit() else DEFAULT_CACHE_MINS
    cache_sec = cache_mins * 60

    # Determine which API to use - prefer V3 if available, fallback to V2.5
    if api_v3_key and api_v3_key != "":
        # Use One Call API 3.0
        url = "https://api.openweathermap.org/data/3.0/onecall?lat={}&lon={}&units={}&appid={}".format(lat, lng, units, api_v3_key)

        # Fetch weather data
        rep = http.get(url, ttl_seconds = cache_sec)
        if rep.status_code != 200:
            return error_display("Weather API Error")

        weather_data = json.decode(rep.body())

        # Process forecast data using One Call API 3.0 processing
        daily_data = process_forecast_onecall(weather_data)
    elif api_v2_key and api_v2_key != "":
        # Use Standard Forecast API 2.5
        url = "https://api.openweathermap.org/data/2.5/forecast?lat={}&lon={}&units={}&appid={}".format(lat, lng, units, api_v2_key)

        # Fetch weather data
        rep = http.get(url, ttl_seconds = cache_sec)
        if rep.status_code != 200:
            return error_display("Weather API Error")

        weather_data = json.decode(rep.body())

        # Process forecast data using Standard API 2.5 processing
        daily_data = process_forecast(weather_data["list"])
    else:
        return error_display("No API Key Provided", scale)

    # Create the display
    if showthreeday:
        return render_weather(daily_data, scale)
    else:
        return render_single_day(daily_data, scale)

def render_single_day(daily_data, scale = 1):
    if len(daily_data) < 2:  # If we don't have at least 2 days
        return error_display("Weather API Error")

    day = daily_data[0]
    tomorrow = daily_data[1]

    # Get day abbreviation
    day_abbr = _get_day_abbr(day["date"])
    tomorrow_abbr = _get_day_abbr(tomorrow["date"])
    slide_percentage = get_slide_percentage(day["weather"])
    should_render_day_at_top = get_should_render_day_at_top(day["weather"])

    # TIMING CALCULATIONS
    slide_start_seconds = 2
    delay_ms = int(100 / scale)
    static_frames_before = int(slide_start_seconds * 1000 / delay_ms)
    slide_distance = int(64 * slide_percentage / 100) * scale
    static_frames_after = 100 * scale

    # Animation parameters
    today_width_start = 63 * scale
    today_width_end = 42 * scale
    slide_distance_start = 0
    slide_distance_end = slide_distance

    # STUTTER ANIMATION PARAMETERS
    stutter_distance = 3 * scale  # How far to move in first step
    stutter_width_change = 3 * scale  # How much today_width shrinks in first step
    stutter_frames = 3 * scale  # How many frames for the initial stutter movement
    stutter_pause_frames = 6 * scale  # How long to pause after stutter (0.5 seconds)
    finish_frames = 7 * scale  # How many frames to complete the rest

    # BACKGROUND ANIMATION PARAMETERS (moves faster)
    bg_stutter_frames = 2 * scale  # Background moves faster in stutter
    bg_finish_frames = 5 * scale  # Background finishes faster

    return render.Root(
        delay = delay_ms,
        child = render.Animation(
            children = [
                # PHASE 1: STATIC
                render_frame(
                    slide_distance_start,
                    today_width_start,
                    day,
                    day_abbr,
                    tomorrow,
                    tomorrow_abbr,
                    should_render_day_at_top,
                    scale,
                ),
            ] * static_frames_before + [
                # PHASE 2A: STUTTER MOVEMENT
                render_frame(
                    # Background moves faster during stutter
                    int((min(i + 1, bg_stutter_frames)) * stutter_distance / bg_stutter_frames),
                    # Width changes at normal pace
                    today_width_start - int((i + 1) * stutter_width_change / stutter_frames),
                    day,
                    day_abbr,
                    tomorrow,
                    tomorrow_abbr,
                    should_render_day_at_top,
                    scale,
                )
                for i in range(stutter_frames)
            ] + [
                # PHASE 2B: PAUSE on the stutter position
                render_frame(
                    stutter_distance,
                    today_width_start - stutter_width_change,
                    day,
                    day_abbr,
                    tomorrow,
                    tomorrow_abbr,
                    should_render_day_at_top,
                    scale,
                ),
            ] * stutter_pause_frames + [
                # PHASE 2C: COMPLETE the rest of the animation
                render_frame(
                    # Background finishes faster
                    stutter_distance + int((min(i + 1, bg_finish_frames)) * (slide_distance_end - stutter_distance) / bg_finish_frames),
                    # Width changes at normal pace
                    (today_width_start - stutter_width_change) + int((i + 1) * ((today_width_end) - (today_width_start - stutter_width_change)) / finish_frames),
                    day,
                    day_abbr,
                    tomorrow,
                    tomorrow_abbr,
                    should_render_day_at_top,
                    scale,
                )
                for i in range(finish_frames)
            ] + [
                # PHASE 3: STATIC AFTER
                render_frame(
                    slide_distance_end,
                    today_width_end,
                    day,
                    day_abbr,
                    tomorrow,
                    tomorrow_abbr,
                    should_render_day_at_top,
                    scale,
                ),
            ] * static_frames_after,
        ),
    )

def get_should_render_day_at_top(forecast):
    if forecast == "Snow":
        return True
    return False

def get_slide_percentage(forecast):
    """
    Returns the slide percentage based on weather forecast.
    Default is 33% for most weather types, with Clear being 10%.
    """
    slide_map = {
        "Clear": 10,
        "Clouds": 40,
        "Rain": 33,
        "Snow": 40,
        "Thunderstorm": 33,
        "Drizzle": 33,
        "Mist": 40,
        "Partly_Sun": 33,
    }
    return slide_map.get(forecast, 40)

def _get_day_abbr(date):
    abbr = date.format("Mon")[:3].upper()
    return tr(abbr)

def get_weather_image(forecast, scale = 1):
    image = None
    if scale == 2:
        image = WEATHER_FULL_IMAGE_2X.get(forecast)
    if not image:
        image = WEATHER_FULL_IMAGE.get(forecast)
    return image.readall() if image else ""

def render_frame(slide_distance, today_width, day, day_abbr, tomorrow, tomorrow_abbr, day_top = False, scale = 1):
    tomorrow_width = get_forecast_width(tomorrow["high"], False) * scale if scale == 2 else 16
    return render.Stack(
        children = [
            # BACKGROUND IMAGE - In final slid position
            render.Padding(
                pad = (-slide_distance, 0, 0, 0),  # Final negative padding (background fully slid left)
                child = render.Image(
                    src = get_weather_image(day["weather"], scale),
                    width = 64 * scale,
                    height = 32 * scale,
                ),
            ),
            # Primary Box
            render.Box(
                width = 64 * scale,
                height = 32 * scale,
                #PRIMARY ROW
                child = render.Row(
                    main_align = "start",
                    cross_align = "start",
                    expanded = True,
                    children = [
                        render_today_forecast_column(day, day_abbr, today_width, day_top, scale),  #end row
                        render.Row(
                            children = [
                                render.Padding(
                                    pad = (scale, 3 * scale, scale, 3 * scale),
                                    child = render.Box(
                                        width = 1 * scale,
                                        height = 26 * scale,
                                        color = "#FFFFFF1A",
                                    ),
                                ),
                            ],
                        ),
                        render.Column(
                            main_align = "start",
                            cross_align = "start",
                            expanded = True,
                            children = [
                                render.Row(
                                    main_align = "start",
                                    cross_align = "start",
                                    expanded = True,
                                    children = [
                                        render.Box(
                                            width = tomorrow_width,
                                            height = 13 * scale,
                                            child = render.Column(
                                                main_align = "start",
                                                cross_align = "center",
                                                expanded = True,
                                                children = [
                                                    render.Padding(
                                                        pad = (0, scale, 0, 0),
                                                        child = render.Text(
                                                            tomorrow_abbr,
                                                            font = "5x8" if scale == 1 else "terminus-16",
                                                            color = "#FFF",
                                                        ),
                                                    ),
                                                ],
                                            ),
                                        ),
                                    ],
                                ),
                                render_forecast(tomorrow, False, scale),
                            ],
                        ),
                    ],
                ),
            ),
        ],
    )

def render_today_forecast_column(day, day_abbr, today_width, day_top = False, scale = 1):
    day_offset = get_day_offset(day["high"]) * scale
    if day_top == True:
        return render.Column(
            expanded = True,
            main_align = "start",
            cross_align = "start",
            children = [
                render.Row(
                    children = [
                        render.Box(
                            width = 20 * scale,
                            height = 13 * scale,
                            child = render.Padding(
                                pad = (-scale, 0, scale, 2 * scale),  # (left, top, right, bottom) padding
                                child = render.Box(
                                    width = 20 * scale,
                                    height = 8 * scale,
                                    color = "#00000000",
                                    child = render.Text(
                                        day_abbr,
                                        font = "5x8" if scale == 1 else "terminus-16",
                                        color = "#FFF",
                                    ),
                                ),
                            ),
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(
                            width = today_width,
                            height = 19 * scale,
                            child = render_today_forecast(day, "", today_width - day_offset, "#00000000", scale),
                        ),
                    ],
                ),  #end column
            ],
        )

    return render.Column(
        expanded = True,
        main_align = "start",
        cross_align = "center",
        children = [
            render.Row(
                children = [
                    render.Box(
                        width = 1 * scale,
                        height = 13 * scale,
                    ),
                ],
            ),
            render.Row(
                children = [
                    render.Box(
                        width = today_width,
                        height = 19 * scale,  #63 -> 42
                        child = render_today_forecast(day, day_abbr, today_width - day_offset, scale = scale),
                    ),  #33 -> 12
                ],
            ),  #end column
        ],
    )

def render_today_forecast(day, day_abbr, padding, color = "#000000CC", scale = 1):
    return render.Row(
        expanded = True,
        main_align = "space_evenly",  # Spreads items to opposite ends
        cross_align = "end",  # Aligns items to bottom
        children = [
            # DAY NAME - Left side of display
            render.Padding(
                pad = (scale, 0, padding, 2 * scale),  # (left, top, right, bottom) padding
                child = render.Box(
                    width = 14 * scale,
                    height = 8 * scale,
                    color = color,
                    child = render.Text(
                        day_abbr,
                        font = "5x8" if scale == 1 else "terminus-16",
                        color = "#FFF",
                    ),
                ),
            ),
            render_forecast(day, True, scale),
        ],
    )

def render_forecast(day, is_today, scale = 1):
    forecast_width = get_forecast_width(day["high"], is_today) * scale
    forecast_padding = get_forecast_padding(day["high"], is_today) * scale
    return render.Row(
        main_align = "center",
        cross_align = "start",
        expanded = True,
        children = [
            render.Box(
                width = forecast_width,
                height = 19 * scale,
                child =  #containing box
                    render.Column(
                        main_align = "start",
                        cross_align = "start",
                        expanded = True,
                        children = [
                            render.Padding(
                                pad = (0, scale, forecast_padding, 2 * scale),
                                child = render.Column(
                                    cross_align = "end",
                                    children = [
                                        #column children
                                        render.Text(
                                            "%d°" % round_temp(day["high"]),
                                            font = "tb-8" if scale == 1 else "terminus-16",
                                            color = "#FFF",
                                        ),
                                        render.Text(
                                            "%d°" % round_temp(day["low"]),
                                            font = "tb-8" if scale == 1 else "terminus-16",
                                            color = "#888",
                                        ),
                                    ],  #end column children
                                ),  #end column
                            ),
                        ],
                    ),  #end padding, #end column children, #end column
            ),  #end containing box
        ],  #end row children
    )

def get_forecast_padding(temp, is_today):
    temp = round_temp(temp)
    if temp >= 100 or temp <= -10:
        return 4
    if is_today:
        return 0
    return 0

def get_day_offset(temp):
    temp = round_temp(temp)
    if temp >= 100 or temp <= -10:
        return 38
    return 30

def get_forecast_width(temp, is_today):
    temp = round_temp(temp)
    if temp >= 100 or temp <= -10:
        return 24
    if is_today:
        return 16
    return 20

def round_temp(temp):
    return (temp * 10 + 5) // 10

def process_forecast_onecall(weather_data):
    """
    Process One Call API 3.0 response data.
    The One Call API provides daily forecasts directly.
    """
    daily_forecasts = []

    # Get current weather for today
    if "current" in weather_data:
        current = weather_data["current"]
        current_time = time.from_timestamp(current["dt"])

        # Get main weather and icon code
        weather_main = current["weather"][0]["main"]
        weather_icon = current["weather"][0]["icon"]

        # Check if icon starts with 02 or 03 and override weather_main
        if weather_icon.startswith(("02", "03")):
            weather_main = "Partly_Sun"

        # Check if weather is some atmospheric condition that can be represented as fog
        if weather_main == "Haze" or weather_main == "Smoke" or weather_main == "Ash":
            weather_main = "Mist"

        daily_forecasts.append({
            "high": current["temp"],
            "low": current["temp"],
            "weather": weather_main,
            "date": current_time,
        })

    # Process daily forecasts
    if "daily" in weather_data:
        for i, day in enumerate(weather_data["daily"]):
            if i >= 3:  # Limit to 3 days total
                break

            # Skip today if we already added current weather
            if len(daily_forecasts) > 0 and i == 0:
                # Update today's data with daily high/low
                daily_forecasts[0]["high"] = day["temp"]["max"]
                daily_forecasts[0]["low"] = day["temp"]["min"]
                continue

            day_time = time.from_timestamp(day["dt"])

            # Get main weather and icon code
            weather_main = day["weather"][0]["main"]
            weather_icon = day["weather"][0]["icon"]

            # Check if icon starts with 02 or 03 and override weather_main
            if weather_icon.startswith(("02", "03")):
                weather_main = "Partly_Sun"

            # Check if weather is some atmospheric condition that can be represented as fog
            if weather_main == "Haze" or weather_main == "Smoke" or weather_main == "Ash":
                weather_main = "Mist"

            daily_forecasts.append({
                "high": day["temp"]["max"],
                "low": day["temp"]["min"],
                "weather": weather_main,
                "date": day_time,
            })

    return daily_forecasts[:3]

def process_forecast(forecast_list):
    # Group forecasts by day and find high/low temps
    # This function processes Standard API 2.5 forecast data
    days = {}

    for item in forecast_list:
        # Convert timestamp to day
        day_time = time.from_timestamp(item["dt"])
        day_key = day_time.format("2006-01-02")

        temp = item["main"]["temp"]

        # Get both main weather and icon code
        weather_main = item["weather"][0]["main"]
        weather_icon = item["weather"][0]["icon"]

        # Check if icon starts with 02 or 03 and override weather_main
        if weather_icon.startswith(("02", "03")):
            weather_main = "Partly_Sun"

        # Check if weather is some atmospheric condition that can be represented as fog
        if weather_main == "Haze" or weather_main == "Smoke" or weather_main == "Ash":
            weather_main = "Mist"

        if day_key not in days:
            days[day_key] = {
                "high": temp,
                "low": temp,
                "weather": weather_main,
                "date": day_time,
            }
        else:
            days[day_key]["high"] = max(days[day_key]["high"], temp)
            days[day_key]["low"] = min(days[day_key]["low"], temp)

    # Sort and take first 3 days
    sorted_days = sorted(days.values(), key = lambda x: x["date"])[:3]
    return sorted_days

WEATHER_ICONS = {
    "Clear": CLEAR_IMAGE,
    "Clouds": CLOUDS_IMAGE,
    "Drizzle": DRIZZLE_IMAGE,
    "Fog": FOG_IMAGE,
    "Hail": HAIL_IMAGE,
    "Mist": MIST_IMAGE,
    "Moon": MOON_IMAGE,
    "Moonish": MOONISH_IMAGE,
    "Partly_Sun": PARTLY_SUN_IMAGE,
    "Rain": RAIN_IMAGE,
    "Sleet": SLEET_IMAGE,
    "Snow": SNOW_IMAGE,
    "Squall": SQUALL_IMAGE,
    "Thunderstorm": THUNDERSTORM_IMAGE,
    "Tornado": TORNADO_IMAGE,
}

WEATHER_ICONS_2X = {
    "Clear": CLEAR_IMAGE_2X,
    "Clouds": CLOUDS_IMAGE_2X,
    "Drizzle": DRIZZLE_IMAGE_2X,
    "Fog": FOG_IMAGE_2X,
    "Hail": HAIL_IMAGE_2X,
    "Mist": MIST_IMAGE_2X,
    "Moon": MOON_IMAGE_2X,
    "Moonish": MOONISH_IMAGE_2X,
    "Partly_Sun": PARTLY_SUN_IMAGE_2X,
    "Rain": RAIN_IMAGE_2X,
    "Sleet": SLEET_IMAGE_2X,
    "Snow": SNOW_IMAGE_2X,
    "Squall": SQUALL_IMAGE_2X,
    "Thunderstorm": THUNDERSTORM_IMAGE_2X,
    "Tornado": TORNADO_IMAGE_2X,
}

def get_weather_icon(forecast, scale = 1):
    icon = None
    if scale == 2:
        icon = WEATHER_ICONS_2X.get(forecast)
    if not icon:
        icon = WEATHER_ICONS.get(forecast)
    return icon.readall() if icon else ""

def render_weather(daily_data, scale = 1):
    # Create weather icons mapping

    # Calculate dimensions
    DAY_WIDTH = 20 * scale
    DIVIDER_WIDTH = scale
    TOTAL_WIDTH = (DAY_WIDTH * 3) + (DIVIDER_WIDTH * 2)
    HEIGHT = 32 * scale
    SUFFIX = "°" if scale == 2 else ""

    # Create columns first
    columns = []
    for i, day in enumerate(daily_data):
        # Get day abbreviation
        day_abbr = day["date"].format("Mon")[:3].upper()
        day_abbr = tr(day_abbr)

        # Create day column
        day_column = render.Column(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = [
                # Weather icon
                render.Image(
                    src = get_weather_icon(day["weather"], scale),
                    width = 12 * scale,
                    height = 12 * scale,
                ),
                # Day abbreviation
                render.Text(
                    day_abbr,
                    font = "CG-pixel-4x5-mono" if scale == 1 else "terminus-12",
                    color = "#FF0",
                ),
                # High temp
                render.Text(
                    "%d" % round_temp(day["high"]) + SUFFIX,
                    font = "CG-pixel-4x5-mono" if scale == 1 else "terminus-12",
                    color = "#FFF",
                ),
                # Low temp
                render.Text(
                    "%d" % round_temp(day["low"]) + SUFFIX,
                    font = "CG-pixel-4x5-mono" if scale == 1 else "terminus-12",
                    color = "#FFF",
                ),
            ],
        )

        columns.append(day_column)

        # Add divider if not last column
        if i < 2:
            columns.append(
                render.Box(
                    width = DIVIDER_WIDTH,
                    height = HEIGHT,
                    color = "#444",
                ),
            )

    # Create the display with ALL children at once
    weather_display = render.Root(
        child = render.Stack(
            children = [
                render.Box(
                    width = TOTAL_WIDTH,
                    height = HEIGHT,
                    color = "#000",
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    children = columns,
                ),
            ],
        ),
    )

    return weather_display

def error_display(message, scale = 1):
    return render.Root(
        child = render.Text(message, font = "tb-8" if scale == 1 else "terminus-12"),
    )

def get_schema():
    options = [
        schema.Option(
            display = "Fahrenheit",
            value = "imperial",
        ),
        schema.Option(
            display = "Celsius",
            value = "metric",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for the display of the weather.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "showthreeday",  # Add new toggle for display format
                name = "Show Three Day Forecast",
                desc = "Toggle between three day and single day display.",
                default = True,
                icon = "calendar",
            ),
            schema.Dropdown(
                id = "units",
                name = "Units",
                desc = "Display units.",
                default = options[0].value,
                options = options,
                icon = "calendar",
            ),
            schema.Text(
                id = "api_v3",
                name = "OpenWeather One Call API 3.0 Key (Optional)",
                desc = "One Call API 3.0 key for enhanced features. Requires 'One Call by Call' subscription with 1000 free calls/day.",
                icon = "gear",
                secret = True,
            ),
            schema.Text(
                id = "api_v2",
                name = "OpenWeather API 2.5 Key",
                desc = "Standard API 2.5 key for basic weather data (free tier available). Go to OpenWeatherMap.org to get your free API key.",
                icon = "gear",
                secret = True,
            ),
            schema.Text(
                id = "cache_mins",
                name = "Cache Duration",
                desc = "How long to cache weather data (in minutes)",
                icon = "clock",
                default = str(DEFAULT_CACHE_MINS),
            ),
        ],
    )
