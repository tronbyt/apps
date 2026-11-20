"""
Applet: Dense Time Temp
Summary: Dense weather and time info
Description: Shows lots of information about the weather and time, including sunrise and sunset.
Author: jordan-p
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/broken_clouds.png", BROKEN_CLOUDS_ASSET = "file")
load("images/clear_sky.png", CLEAR_SKY_ASSET = "file")
load("images/drizzle.png", DRIZZLE_ASSET = "file")
load("images/dust.png", DUST_ASSET = "file")
load("images/few_clouds.png", FEW_CLOUDS_ASSET = "file")
load("images/fog.png", FOG_ASSET = "file")
load("images/freezing_rain.png", FREEZING_RAIN_ASSET = "file")
load("images/gust.png", GUST_ASSET = "file")
load("images/haze.png", HAZE_ASSET = "file")
load("images/night_broken_clouds.png", NIGHT_BROKEN_CLOUDS_ASSET = "file")
load("images/night_clear_sky.png", NIGHT_CLEAR_SKY_ASSET = "file")
load("images/night_drizzle.png", NIGHT_DRIZZLE_ASSET = "file")
load("images/night_dust.png", NIGHT_DUST_ASSET = "file")
load("images/night_few_clouds.png", NIGHT_FEW_CLOUDS_ASSET = "file")
load("images/night_fog.png", NIGHT_FOG_ASSET = "file")
load("images/night_freezing_rain.png", NIGHT_FREEZING_RAIN_ASSET = "file")
load("images/night_gust.png", NIGHT_GUST_ASSET = "file")
load("images/night_overcast_clouds.png", NIGHT_OVERCAST_CLOUDS_ASSET = "file")
load("images/night_rain_shower.png", NIGHT_RAIN_SHOWER_ASSET = "file")
load("images/night_rain_snow.png", NIGHT_RAIN_SNOW_ASSET = "file")
load("images/night_scattered_clouds.png", NIGHT_SCATTERED_CLOUDS_ASSET = "file")
load("images/night_sleet.png", NIGHT_SLEET_ASSET = "file")
load("images/night_smoke.png", NIGHT_SMOKE_ASSET = "file")
load("images/night_snow.png", NIGHT_SNOW_ASSET = "file")
load("images/night_thunderstorm.png", NIGHT_THUNDERSTORM_ASSET = "file")
load("images/night_tornado.png", NIGHT_TORNADO_ASSET = "file")
load("images/overcast_clouds.png", OVERCAST_CLOUDS_ASSET = "file")
load("images/rain_shower.png", RAIN_SHOWER_ASSET = "file")
load("images/rain_snow.png", RAIN_SNOW_ASSET = "file")
load("images/scattered_clouds.png", SCATTERED_CLOUDS_ASSET = "file")
load("images/sleet.png", SLEET_ASSET = "file")
load("images/smoke.png", SMOKE_ASSET = "file")
load("images/snow.png", SNOW_ASSET = "file")
load("images/sunrise.png", SUNRISE_ASSET = "file")
load("images/sunset.png", SUNSET_ASSET = "file")
load("images/suntracker.png", SUNTRACKER_ASSET = "file")
load("images/thunderstorm.png", THUNDERSTORM_ASSET = "file")
load("images/tornado.png", TORNADO_ASSET = "file")
load("images/unknown.png", UNKNOWN_ASSET = "file")
load("images/wind_e.png", WIND_E_ASSET = "file")
load("images/wind_n.png", WIND_N_ASSET = "file")
load("images/wind_ne.png", WIND_NE_ASSET = "file")
load("images/wind_nw.png", WIND_NW_ASSET = "file")
load("images/wind_s.png", WIND_S_ASSET = "file")
load("images/wind_se.png", WIND_SE_ASSET = "file")
load("images/wind_sw.png", WIND_SW_ASSET = "file")
load("images/wind_w.png", WIND_W_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("sunrise.star", "sunrise")
load("time.star", "time")

SUNRISE = SUNRISE_ASSET.readall()
SUNSET = SUNSET_ASSET.readall()
SUNTRACKER = SUNTRACKER_ASSET.readall()

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
    "lat": 42.9634,
    "lng": -85.670006,
    "locality": "Grand Rapids, MI",
    "timezone": "America/New_York",
}
DEFAULT_API = {
    "appID": "ffef7893280358cd9f42fca8216140b0",
}

t_DEFAULT_LOCATION = """
{
     "lat": "42.9634",
     "lng": "-85.670006",
     "description": "Grand Rapids",
     "locality": "Grand Rapids, MI",
     "place_id": "GR",
     "timezone": "America/New_York"
}
"""

# wind icons representing wind direction as arrows
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

def main(config):
    dt = 0

    # sunrise = 0
    dn = True
    icon = ""
    sTemps = ""
    sHumidity = ""

    w_sunrise = 0
    w_sunset = 0
    feels_like = 0
    temp = 0
    temp_content = ""
    temp_color = ""
    arrow_src = ""
    wind_speed = 0
    box_width = 0

    location = config.get("location")
    loc = json.decode(location) if location else json.decode(str(DEFAULT_LOCATION))
    timezone = loc["timezone"]
    lat = loc["lat"]
    lon = loc["lng"]

    now = time.now().in_location(timezone)
    rise = sunrise.sunrise(lat, lon, now)
    set = sunrise.sunset(lat, lon, now)

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

            # sMessage = "No weather API Key"
            wind_speed = 99
            wind_deg = 0
        elif weather.status_code != 200 or "error" in weather.json():
            wID = 0
            sTemps = "--- * ---"
            sHumidity = "---%"
            dn = True

            # sMessage = "No weather data"
            wind_speed = 99
            wind_deg = 0
            # wind_gust = 99

        else:
            wID = int(weather.json()["weather"][0]["id"])
            if DEBUG:
                print("ID: ", wID)

            dt = int(weather.json()["dt"])
            if DEBUG:
                print("Date: ", dt)

            w_sunrise = int(weather.json()["sys"]["sunrise"])
            if DEBUG:
                print("Sunrise: ", w_sunrise)

            w_sunset = int(weather.json()["sys"]["sunset"])
            if DEBUG:
                print("Sunset: ", w_sunset)

            wind_speed = int(weather.json()["wind"]["speed"])
            if DEBUG:
                print("Wind Speed: ", wind_speed)

            wind_deg = int(weather.json()["wind"]["deg"])
            if DEBUG:
                print("Wind Degree: ", wind_deg)

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
                if dt >= w_sunrise and dt < w_sunset:
                    dn = True
                    if DEBUG:
                        print("Day")
                else:
                    dn = False
                    if DEBUG:
                        print("Night")

        icon_str = get_icon(wID, dn)
        icon = icon_str

        # elapsed_seconds = now.hour * 3600 + now.minute * 60 + now.second
        # sunrise_seconds = rise.hour * 3600 + rise.minute * 60 + rise.second
        # sunset_seconds = set.hour * 3600 + set.minute * 60 + set.second

        # Calculate the total number of seconds in a day
        # total_seconds_in_day = 24 * 60 * 60
        # total_seconds_sunlight = sunset_seconds - sunrise_seconds

        # Map the elapsed time to a value between 0 and 1
        if w_sunset - w_sunrise != 0:
            time_ratio = ((dt - w_sunrise) / (w_sunset - w_sunrise))
        else:
            time_ratio = 0.5

        # time_ratio = elapsed_seconds / total_seconds_in_day
        # Scale the time ratio to the width of the box
        if dn:
            box_width = math.floor(time_ratio * 52)
        else:
            box_width = 0

        if wind_deg > 337.5:
            wind_dir = "N"
        elif wind_deg <= 22.25:
            wind_dir = "N"
        elif (wind_deg > 22.25) and (wind_deg <= 67.5):
            wind_dir = "NE"
        elif (wind_deg > 67.5) and (wind_deg <= 112.5):
            wind_dir = "E"
        elif (wind_deg > 112.5) and (wind_deg <= 157.5):
            wind_dir = "SE"
        elif (wind_deg > 157.5) and (wind_deg <= 202.5):
            wind_dir = "S"
        elif (wind_deg > 202.5) and (wind_deg <= 247.5):
            wind_dir = "SW"
        elif (wind_deg > 247.5) and (wind_deg <= 292.5):
            wind_dir = "W"
        elif (wind_deg > 292.5) and (wind_deg <= 337.5):
            wind_dir = "NW"
        else:
            wind_dir = "UNK"

        arrow_src = WIND_ICONS[wind_dir]

        if (feels_like < (temp - 5)):
            temp_content = "%dF" % temp + " (%dF" % feels_like + ")"
        else:
            temp_content = "%dF" % temp

        if (temp < 60):
            temp_color = "#3498DB"
        elif temp > 80:
            temp_color = "#C0392B"
        else:
            temp_color = "#F39C12"

    return render.Root(
        delay = 1000,
        child = render.Stack(
            children = [
                render.Column(
                    main_align = "start",
                    expanded = True,
                    children = [
                        render.Row(
                            main_align = "center",
                            expanded = True,
                            children = [
                                render.Animation(
                                    children = [
                                        render.Text(
                                            content = now.format("3:04 PM"),
                                            font = "Dina_r400-6",
                                            color = "#7D3C98",
                                        ),
                                        render.Text(
                                            content = now.format("3 04 PM"),
                                            font = "Dina_r400-6",
                                            color = "#7D3C98",
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
                render.Column(
                    main_align = "center",
                    expanded = True,
                    children = [
                        render.Row(
                            main_align = "space_between",
                            cross_align = "center",
                            expanded = True,
                            children = [
                                render.Box(
                                    width = 18,
                                    height = 18,
                                    child = render.Image(
                                        src = icon,
                                    ),
                                ),
                                render.Box(
                                    width = 24,
                                    height = 24,
                                    child = render.WrappedText(
                                        content = temp_content,
                                        color = temp_color,
                                        font = "5x8",
                                        align = "center",
                                    ),
                                ),
                                render.Row(
                                    children = [
                                        render.Box(
                                            height = 8,
                                            width = 8,
                                            child =
                                                render.Padding(
                                                    pad = (1, 1, 3, 0),
                                                    child = render.Image(
                                                        src = arrow_src,
                                                    ),
                                                ),
                                        ),
                                        render.Padding(
                                            pad = (1, 2, 0, 0),
                                            child = render.Text(
                                                content = "%d" % wind_speed,
                                                font = "tom-thumb",
                                            ),
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
                render.Column(
                    main_align = "end",
                    cross_align = "end",
                    expanded = True,
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "end",
                            children = [
                                render.Image(
                                    src = SUNRISE,
                                ),
                                render.Text(
                                    content = "%s" % rise.in_location(loc["timezone"]).format("3:04"),
                                    font = "tom-thumb",
                                    color = "#F4D03F",
                                ),
                                render.Text(
                                    content = "%s" % set.in_location(loc["timezone"]).format("3:04"),
                                    font = "tom-thumb",
                                    color = "#BA4A00",
                                ),
                                render.Image(
                                    src = SUNSET,
                                ),
                            ],
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "start",
                            children = [
                                render.Padding(
                                    pad = (6, 0, 6, 0),
                                    child = render.Box(
                                        width = box_width,
                                        height = 1,
                                        child = render.Image(
                                            src = SUNTRACKER,
                                        ),
                                    ),
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "weatherAPI",
                name = "Open Weather API Key",
                desc = "Enter API key",
                icon = "certificate",
                default = "ffef7893280358cd9f42fca8216140b0",
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
        ],
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
        UNKNOWN_ASSET.readall()
    )

def get_clear_sky():
    # Clear sky graphic

    return CLEAR_SKY_ASSET.readall()

def get_night_clear_sky():
    # Night clear sky graphic

    return NIGHT_CLEAR_SKY_ASSET.readall()

def get_thunderstorm():
    # Thunderstorm day

    return THUNDERSTORM_ASSET.readall()

def get_night_thunderstorm():
    # Thunderstorm night

    return NIGHT_THUNDERSTORM_ASSET.readall()

def get_drizzle():
    # Drizzle day

    return DRIZZLE_ASSET.readall()

def get_night_drizzle():
    # Drizzle night

    return NIGHT_DRIZZLE_ASSET.readall()

def get_freezing_rain():
    # Freezing rain

    return FREEZING_RAIN_ASSET.readall()

def get_night_freezing_rain():
    # Freezing rain at night

    return NIGHT_FREEZING_RAIN_ASSET.readall()

def get_few_clouds():
    # Few clouds

    return FEW_CLOUDS_ASSET.readall()

def get_night_few_clouds():
    # Few clouds at night

    return NIGHT_FEW_CLOUDS_ASSET.readall()

def get_scattered_clouds():
    # Scattered clouds

    return SCATTERED_CLOUDS_ASSET.readall()

def get_night_scattered_clouds():
    # Scattered clouds at night

    return NIGHT_SCATTERED_CLOUDS_ASSET.readall()

def get_broken_clouds():
    # Broken clouds

    return BROKEN_CLOUDS_ASSET.readall()

def get_night_broken_clouds():
    # Broken clouds at night

    return NIGHT_BROKEN_CLOUDS_ASSET.readall()

def get_overcast_clouds():
    # Overcast clouds

    return OVERCAST_CLOUDS_ASSET.readall()

def get_night_overcast_clouds():
    # Overcast clouds at night

    return NIGHT_OVERCAST_CLOUDS_ASSET.readall()

def get_rain_shower():
    # Rain showers

    return RAIN_SHOWER_ASSET.readall()

def get_night_rain_shower():
    # Rain shower at night

    return NIGHT_RAIN_SHOWER_ASSET.readall()

def get_snow():
    # Snow

    return SNOW_ASSET.readall()

def get_night_snow():
    # Snow at night

    return NIGHT_SNOW_ASSET.readall()

def get_sleet():
    # Sleet

    return SLEET_ASSET.readall()

def get_night_sleet():
    # Sleet at night

    return NIGHT_SLEET_ASSET.readall()

def get_rain_snow():
    # Rain and snow

    return RAIN_SNOW_ASSET.readall()

def get_night_rain_snow():
    # Rain and snow at night

    return NIGHT_RAIN_SNOW_ASSET.readall()

def get_smoke():
    # Smoke

    return SMOKE_ASSET.readall()

def get_night_smoke():
    # Smoke at night

    return NIGHT_SMOKE_ASSET.readall()

def get_haze():
    # Haze

    return HAZE_ASSET.readall()

def get_dust():
    # Dust

    return DUST_ASSET.readall()

def get_night_dust():
    # Dust at night

    return NIGHT_DUST_ASSET.readall()

def get_fog():
    # Fog

    return FOG_ASSET.readall()

def get_night_fog():
    # Fog at night

    return NIGHT_FOG_ASSET.readall()

def get_gust():
    # Gusts

    return GUST_ASSET.readall()

def get_night_gust():
    # Night gusts

    return NIGHT_GUST_ASSET.readall()

def get_tornado():
    # Tornado

    return TORNADO_ASSET.readall()

def get_night_tornado():
    # Tornado at night

    return NIGHT_TORNADO_ASSET.readall()
