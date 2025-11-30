"""
Applet: Weather Clock
Summary: Time and weather
Description: Display current time and weather.
Author: J. Keybl
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/broken_clouds_day.png", BROKEN_CLOUDS_DAY_ICON = "file")
load("images/broken_clouds_night.png", BROKEN_CLOUDS_NIGHT_ICON = "file")
load("images/clear_day.png", CLEAR_DAY_ICON = "file")
load("images/clear_night.png", CLEAR_NIGHT_ICON = "file")
load("images/drizzle_day.png", DRIZZLE_DAY_ICON = "file")
load("images/drizzle_night.png", DRIZZLE_NIGHT_ICON = "file")
load("images/dust_day.png", DUST_DAY_ICON = "file")
load("images/dust_night.png", DUST_NIGHT_ICON = "file")
load("images/few_clouds_day.png", FEW_CLOUDS_DAY_ICON = "file")
load("images/few_clouds_night.png", FEW_CLOUDS_NIGHT_ICON = "file")
load("images/fog_day.png", FOG_DAY_ICON = "file")
load("images/fog_night.png", FOG_NIGHT_ICON = "file")
load("images/freezing_rain_day.png", FREEZING_RAIN_DAY_ICON = "file")
load("images/freezing_rain_night.png", FREEZING_RAIN_NIGHT_ICON = "file")
load("images/gust_day.png", GUST_DAY_ICON = "file")
load("images/gust_night.png", GUST_NIGHT_ICON = "file")
load("images/haze.png", HAZE_ICON = "file")
load("images/overcast_clouds_day.png", OVERCAST_CLOUDS_DAY_ICON = "file")
load("images/overcast_clouds_night.png", OVERCAST_CLOUDS_NIGHT_ICON = "file")
load("images/rain_shower_day.png", RAIN_SHOWER_DAY_ICON = "file")
load("images/rain_shower_night.png", RAIN_SHOWER_NIGHT_ICON = "file")
load("images/rain_snow_day.png", RAIN_SNOW_DAY_ICON = "file")
load("images/rain_snow_night.png", RAIN_SNOW_NIGHT_ICON = "file")
load("images/scattered_clouds_day.png", SCATTERED_CLOUDS_DAY_ICON = "file")
load("images/scattered_clouds_night.png", SCATTERED_CLOUDS_NIGHT_ICON = "file")
load("images/sleet_day.png", SLEET_DAY_ICON = "file")
load("images/sleet_night.png", SLEET_NIGHT_ICON = "file")
load("images/smoke_day.png", SMOKE_DAY_ICON = "file")
load("images/smoke_night.png", SMOKE_NIGHT_ICON = "file")
load("images/snow_day.png", SNOW_DAY_ICON = "file")
load("images/snow_night.png", SNOW_NIGHT_ICON = "file")
load("images/thunderstorm_day.png", THUNDERSTORM_DAY_ICON = "file")
load("images/thunderstorm_night.png", THUNDERSTORM_NIGHT_ICON = "file")
load("images/tornado_day.png", TORNADO_DAY_ICON = "file")
load("images/tornado_night.png", TORNADO_NIGHT_ICON = "file")
load("images/unknown.png", UNKNOWN_ICON = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEBUG = False
TIME_FONT = "6x13"
WEATHER_FONT = "CG-pixel-3x5-mono"
TIME_NIGHT_COLOR = "#333333"
TEMPS_COLOR = "#FFFFFF"
HUMIDITY_COLOR = "#0000FF"
MESSAGE_COLOR = "#E60000"
TIME_FORMAT_SEPARATOR = "3:04 PM"
TIME_FORMAT_NO_SEPARATOR = "3 04 PM"
TTL_SECONDS = 60
DEFAULT_LOCATION = {
    "lat": 38.9072,
    "lng": -77.0369,
    "locality": "Washington, D.C.",
    "timezone": "America/New_York",
}
DEFAULT_API = {
    "appID": "",
}

def main(config):
    dt = 0
    sunrise = 0
    sunset = 0
    dn = True
    icon = ""
    sTemps = ""
    sHumidity = ""
    sMessage = ""

    location = config.get("location")
    loc = json.decode(location) if location else json.decode(str(DEFAULT_LOCATION))
    timezone = loc["timezone"]
    lat = loc["lat"]
    lon = loc["lng"]

    weatherAPI = config.get("weatherAPI")
    if weatherAPI == None:
        api = json.decode(str(DEFAULT_API))
        weatherAPI = api["appID"]

    nightMode = config.bool("night_mode", False)
    if nightMode == False:
        dayModeSec = 0
        nightModeSec = 1439
    else:
        nightModeStr = config.get("nightModeStart")
        if nightModeStr == None:
            nightModeStartHr = 23
            nightModeStartMin = 0
        else:
            nightModeStartHr = int(nightModeStr[0:2])
            if nightModeStartHr >= 24:
                nightModeStartHr = 0
            nightModeStartMin = int(nightModeStr[2:4])
        dayModeStr = config.get("nightModeEnd")
        if nightModeStr == None:
            dayModeEndHr = 7
            dayModeEndMin = 0
        else:
            dayModeEndHr = int(dayModeStr[0:2])
            dayModeEndMin = int(dayModeStr[2:4])
        nightModeSec = nightModeStartHr * 60 + nightModeStartMin
        dayModeSec = dayModeEndHr * 60 + dayModeEndMin

    openWeatherURL = "https://api.openweathermap.org/data/2.5/weather?lat=" + str(lat) + "&lon=" + str(lon) + "&APPID=" + str(weatherAPI) + "&units=imperial"

    now = time.now().in_location(timezone)
    ss = now.hour * 60 + now.minute
    if DEBUG:
        print(now)
        print(now.format(TIME_FORMAT_SEPARATOR))

    if ss >= dayModeSec and ss < nightModeSec:
        # Get new weather data and cache it
        if DEBUG:
            print("Getting DATA")

        weather = None
        if weatherAPI != "":
            weather = http.get(openWeatherURL, ttl_seconds = TTL_SECONDS)  # Using the new HTTP Caching Client

        if weatherAPI == "" or weather.status_code != 200 or "error" in weather.json():
            wID = 801
            sTemps = "68 * 64"
            sHumidity = "48%"
            dn = True
            sMessage = "No weather API Key"
        elif weather.status_code != 200 or "error" in weather.json():
            wID = 0
            sTemps = "--- * ---"
            sHumidity = "---%"
            dn = True
            sMessage = "No weather data"
        else:
            wID = int(weather.json()["weather"][0]["id"])
            if DEBUG:
                print("ID: ", wID)

            dt = int(weather.json()["dt"])
            if DEBUG:
                print("Date: ", dt)

            sunrise = int(weather.json()["sys"]["sunrise"])
            if DEBUG:
                print("Sunrise: ", sunrise)

            sunset = int(weather.json()["sys"]["sunset"])
            if DEBUG:
                print("Sunset: ", sunset)

            temp = int(weather.json()["main"]["temp"])
            if DEBUG:
                print("Temp: ", temp)

            feels_like = int(weather.json()["main"]["feels_like"])
            if DEBUG:
                print("Feels like: ", feels_like)

            humidity = int(weather.json()["main"]["humidity"])
            if DEBUG:
                print("Humidity: ", humidity)

            sTemps = "%d" % temp + " * %d" % feels_like
            sHumidity = "%d" % humidity + "%"
            if DEBUG:
                print(sTemps)
                print(sHumidity)

            if wID != 0:
                if dt >= sunrise and dt < sunset:
                    dn = True
                    if DEBUG:
                        print("Day")
                else:
                    dn = False
                    if DEBUG:
                        print("Night")

        icon_str = get_icon(wID, dn)
        icon = base64.decode(icon_str)

    if ss >= nightModeSec or ss < dayModeSec:
        # NIGHT MODE
        return nightScreen(now)

    else:
        # DAY MODE
        return dayScreen(now, icon, sTemps, sHumidity, sMessage)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "weatherAPI",
                name = "Open Weather API Key",
                desc = "Enter API key",
                icon = "certificate",
                secret = True,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                icon = "locationDot",
                desc = "Location for which to display time and weather",
            ),
            schema.Toggle(
                id = "night_mode",
                name = "Night Mode",
                desc = "Enable night mode",
                icon = "gear",
                default = False,
            ),
            schema.Generated(
                id = "night_mode_schema",
                source = "night_mode",
                handler = nightModeTimesSchema,
            ),
        ],
    )

def nightModeTimesSchema(night_mode):
    if night_mode:
        return [
            schema.Text(
                id = "nightModeStart",
                name = "Night Mode Start",
                icon = "clock",
                desc = "Use 24-hour format (HHmm), e.g. 2300",
                default = "2300",
            ),
            schema.Text(
                id = "nightModeEnd",
                name = "Night Mode End",
                icon = "clock",
                desc = "Use 24-hour format (HHmm), e.g. 0730",
                default = "0700",
            ),
        ]
    else:
        return []

def dayScreen(now, icon, sTemps, sHumidity, sMessage):
    return render.Root(
        delay = 500,
        max_age = 120,
        child = render.Stack(
            children = [
                render.Padding(
                    pad = (0, 0, 0, 0),
                    child = render.Column(
                        expanded = True,
                        cross_align = "center",
                        children = [
                            render.Box(width = 64, height = 1),
                            render.Animation(
                                children = [
                                    render.Text(
                                        content = now.format(TIME_FORMAT_SEPARATOR),
                                        font = TIME_FONT,
                                    ),
                                    render.Text(
                                        content = now.format(TIME_FORMAT_NO_SEPARATOR),
                                        font = TIME_FONT,
                                    ),
                                ],
                            ),
                        ],
                    ),
                ),
                render.Padding(
                    pad = (1, 15, 0, 0),
                    child = render.Box(
                        width = 16,
                        height = 16,
                        child = render.Image(
                            src = icon,
                        ),
                    ),
                ),
                render.Padding(
                    pad = (20, 16, 0, 0),
                    child = render.Box(
                        width = 44,
                        height = 8,
                        child = render.WrappedText(
                            content = sTemps,
                            color = TEMPS_COLOR,
                            font = WEATHER_FONT,
                            align = "left",
                            width = 44,
                        ),
                    ),
                ),
                render.Padding(
                    pad = (20, 11, 0, 0),
                    child = render.Box(
                        width = 44,
                        height = 8,
                        child = render.Marquee(
                            width = 44,
                            child = render.Text(
                                content = sMessage,
                                color = MESSAGE_COLOR,
                                font = WEATHER_FONT,
                            ),
                        ),
                    ),
                ),
                render.Padding(
                    pad = (20, 22, 0, 0),
                    child = render.Box(
                        width = 44,
                        height = 8,
                        child = render.WrappedText(
                            content = sHumidity,
                            color = HUMIDITY_COLOR,
                            font = WEATHER_FONT,
                            align = "left",
                            width = 44,
                        ),
                    ),
                ),
            ],
        ),
    )

def nightScreen(now):
    return render.Root(
        delay = 500,
        max_age = 120,
        child = render.Padding(
            pad = (0, 8, 0, 0),
            child = render.Column(
                expanded = True,
                cross_align = "center",
                children = [
                    render.Box(width = 64, height = 1),
                    render.Animation(
                        children = [
                            render.Text(
                                content = now.format(TIME_FORMAT_SEPARATOR),
                                font = TIME_FONT,
                                color = TIME_NIGHT_COLOR,
                            ),
                            render.Text(
                                content = now.format(TIME_FORMAT_NO_SEPARATOR),
                                font = TIME_FONT,
                                color = TIME_NIGHT_COLOR,
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_icon(wID, dn):
    # Get icon data
    icon_str = ""
    if wID >= 200 and wID < 300:  # THUNDERSTORM
        icon_str = get_thunderstorm() if dn else get_night_thunderstorm()
    elif wID >= 300 and wID < 400:  # DRIZZLE
        icon_str = get_drizzle() if dn else get_night_drizzle()
    elif wID >= 500 and wID <= 504:  # RAIN - same as for drizzle
        icon_str = get_drizzle() if dn else get_night_drizzle()
    elif wID == 511:  # FREEZING RAIN
        icon_str = get_freezing_rain() if dn else get_night_freezing_rain()
    elif wID >= 520 and wID < 600:  # RAIN SHOWER
        icon_str = get_rain_shower() if dn else get_night_rain_shower()
    elif wID >= 600 and wID < 610:  # SNOW
        icon_str = get_snow() if dn else get_night_snow()
    elif wID >= 610 and wID < 616:  # SLEET
        icon_str = get_sleet() if dn else get_night_sleet()
    elif wID >= 616 and wID < 700:  # RAIN AND SNOW
        icon_str = get_rain_snow() if dn else get_night_rain_snow()
    elif wID == 701:  # MIST
        icon_str = get_drizzle() if dn else get_night_drizzle()
    elif wID == 711:  # SMOKE
        icon_str = get_smoke() if dn else get_night_smoke()
    elif wID == 721:  # HAZE
        icon_str = get_haze() if dn else get_unknown()
    elif wID == 731 or (wID >= 751 and wID <= 762):  # DUST
        icon_str = get_dust() if dn else get_night_dust()
    elif wID == 741:  # FOG
        icon_str = get_fog() if dn else get_night_fog()
    elif wID == 771:  # GUST
        icon_str = get_gust() if dn else get_night_gust()
    elif wID == 781:  # TORNADO
        icon_str = get_tornado() if dn else get_night_tornado()
    elif wID == 800:  # CLEAR SKY
        icon_str = get_clear_sky() if dn else get_night_clear_sky()
    elif wID == 801:  # FEW CLOUDS
        icon_str = get_few_clouds() if dn else get_night_few_clouds()
    elif wID == 802:  # SCATTERED CLOUDS
        icon_str = get_scattered_clouds() if dn else get_night_scattered_clouds()
    elif wID == 803:  # BROKEN CLOUDS
        icon_str = get_broken_clouds() if dn else get_night_broken_clouds()
    elif wID == 804:  # BROKEN CLOUDS
        icon_str = get_overcast_clouds() if dn else get_night_overcast_clouds()
    else:
        icon_str = get_unknown()  # NO INFORMATION TO CHOOSE ICON

    return (icon_str)

def get_unknown():
    # no graphic available

    return (
        UNKNOWN_ICON.readall()
    )

def get_clear_sky():
    # Clear sky graphic

    return (
        CLEAR_DAY_ICON.readall()
    )

def get_night_clear_sky():
    # Night clear sky graphic

    return (
        CLEAR_NIGHT_ICON.readall()
    )

def get_thunderstorm():
    # Thunderstorm day

    return (THUNDERSTORM_DAY_ICON.readall())

def get_night_thunderstorm():
    # Thunderstorm night

    return (THUNDERSTORM_NIGHT_ICON.readall())

def get_drizzle():
    # Drizzle day

    return (DRIZZLE_DAY_ICON.readall())

def get_night_drizzle():
    # Drizzle night

    return (DRIZZLE_NIGHT_ICON.readall())

def get_freezing_rain():
    # Freezing rain

    return (FREEZING_RAIN_DAY_ICON.readall())

def get_night_freezing_rain():
    # Freezing rain at night

    return (FREEZING_RAIN_NIGHT_ICON.readall())

def get_few_clouds():
    # Few clouds

    return (FEW_CLOUDS_DAY_ICON.readall())

def get_night_few_clouds():
    # Few clouds at night

    return (FEW_CLOUDS_NIGHT_ICON.readall())

def get_scattered_clouds():
    # Scattered clouds

    return (SCATTERED_CLOUDS_DAY_ICON.readall())

def get_night_scattered_clouds():
    # Scattered clouds at night

    return (SCATTERED_CLOUDS_NIGHT_ICON.readall())

def get_broken_clouds():
    # Broken clouds

    return (BROKEN_CLOUDS_DAY_ICON.readall())

def get_night_broken_clouds():
    # Broken clouds at night

    return (BROKEN_CLOUDS_NIGHT_ICON.readall())

def get_overcast_clouds():
    # Overcast clouds

    return (OVERCAST_CLOUDS_DAY_ICON.readall())

def get_night_overcast_clouds():
    # Overcast clouds at night

    return (OVERCAST_CLOUDS_NIGHT_ICON.readall())

def get_rain_shower():
    # Rain showers

    return (RAIN_SHOWER_DAY_ICON.readall())

def get_night_rain_shower():
    # Rain shower at night

    return (RAIN_SHOWER_NIGHT_ICON.readall())

def get_snow():
    # Snow

    return (SNOW_DAY_ICON.readall())

def get_night_snow():
    # Snow at night

    return (SNOW_NIGHT_ICON.readall())

def get_sleet():
    # Sleet

    return (SLEET_DAY_ICON.readall())

def get_night_sleet():
    # Sleet at night

    return (SLEET_NIGHT_ICON.readall())

def get_rain_snow():
    # Rain and snow

    return (RAIN_SNOW_DAY_ICON.readall())

def get_night_rain_snow():
    # Rain and snow at night

    return (RAIN_SNOW_NIGHT_ICON.readall())

def get_smoke():
    # Smoke

    return (SMOKE_DAY_ICON.readall())

def get_night_smoke():
    # Smoke at night

    return (SMOKE_NIGHT_ICON.readall())

def get_haze():
    # Haze

    return (HAZE_ICON.readall())

def get_dust():
    # Dust

    return (DUST_DAY_ICON.readall())

def get_night_dust():
    # Dust at night

    return (DUST_NIGHT_ICON.readall())

def get_fog():
    # Fog

    return (FOG_DAY_ICON.readall())

def get_night_fog():
    # Fog at night

    return (FOG_NIGHT_ICON.readall())

def get_gust():
    # Gusts

    return (GUST_DAY_ICON.readall())

def get_night_gust():
    # Night gusts

    return (GUST_NIGHT_ICON.readall())

def get_tornado():
    # Tornado

    return (TORNADO_DAY_ICON.readall())

def get_night_tornado():
    # Tornado at night

    return (TORNADO_NIGHT_ICON.readall())
