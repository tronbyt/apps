"""
Applet: ShipWeatherClock
Summary: Ship scene w time/weather
Description: Clock with ship on the ocean scene that changes with weather.
Author: Peter Uth
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/clouds_heavy_day.png", CLOUDS_HEAVY_DAY_ASSET = "file")
load("images/clouds_heavy_night.png", CLOUDS_HEAVY_NIGHT_ASSET = "file")
load("images/clouds_light_day.png", CLOUDS_LIGHT_DAY_ASSET = "file")
load("images/clouds_light_night.png", CLOUDS_LIGHT_NIGHT_ASSET = "file")
load("images/lightning.png", LIGHTNING_ASSET = "file")
load("images/moon.png", MOON_ASSET = "file")
load("images/moon_clouds.png", MOON_CLOUDS_ASSET = "file")
load("images/rain_heavy_day.png", RAIN_HEAVY_DAY_ASSET = "file")
load("images/rain_heavy_night.png", RAIN_HEAVY_NIGHT_ASSET = "file")
load("images/rain_light_day.png", RAIN_LIGHT_DAY_ASSET = "file")
load("images/rain_light_night.png", RAIN_LIGHT_NIGHT_ASSET = "file")
load("images/ship_day.png", SHIP_DAY_ASSET = "file")
load("images/ship_night.png", SHIP_NIGHT_ASSET = "file")
load("images/snow_day.png", SNOW_DAY_ASSET = "file")
load("images/snow_night.png", SNOW_NIGHT_ASSET = "file")
load("images/stars.png", STARS_ASSET = "file")
load("images/whale1.png", WHALE1_ASSET = "file")
load("images/whale2.png", WHALE2_ASSET = "file")
load("images/whale3.png", WHALE3_ASSET = "file")
load("images/whale4.png", WHALE4_ASSET = "file")
load("images/whale5.png", WHALE5_ASSET = "file")
load("images/whale6.png", WHALE6_ASSET = "file")
load("images/whale7.png", WHALE7_ASSET = "file")
load("images/whale8.png", WHALE8_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CLOUDS_HEAVY_DAY = CLOUDS_HEAVY_DAY_ASSET.readall()
CLOUDS_HEAVY_NIGHT = CLOUDS_HEAVY_NIGHT_ASSET.readall()
CLOUDS_LIGHT_DAY = CLOUDS_LIGHT_DAY_ASSET.readall()
CLOUDS_LIGHT_NIGHT = CLOUDS_LIGHT_NIGHT_ASSET.readall()
LIGHTNING = LIGHTNING_ASSET.readall()
MOON = MOON_ASSET.readall()
MOON_CLOUDS = MOON_CLOUDS_ASSET.readall()
RAIN_HEAVY_DAY = RAIN_HEAVY_DAY_ASSET.readall()
RAIN_HEAVY_NIGHT = RAIN_HEAVY_NIGHT_ASSET.readall()
RAIN_LIGHT_DAY = RAIN_LIGHT_DAY_ASSET.readall()
RAIN_LIGHT_NIGHT = RAIN_LIGHT_NIGHT_ASSET.readall()
SHIP_DAY = SHIP_DAY_ASSET.readall()
SHIP_NIGHT = SHIP_NIGHT_ASSET.readall()
SNOW_DAY = SNOW_DAY_ASSET.readall()
SNOW_NIGHT = SNOW_NIGHT_ASSET.readall()
STARS = STARS_ASSET.readall()
WHALE1 = WHALE1_ASSET.readall()
WHALE2 = WHALE2_ASSET.readall()
WHALE3 = WHALE3_ASSET.readall()
WHALE4 = WHALE4_ASSET.readall()
WHALE5 = WHALE5_ASSET.readall()
WHALE6 = WHALE6_ASSET.readall()
WHALE7 = WHALE7_ASSET.readall()
WHALE8 = WHALE8_ASSET.readall()

TTL_SECONDS = 20 * 60  # 20 minutes API pull interval
DEFAULT_LOCATION = {
    "lat": "47.60",
    "lng": "-122.33",
    "locality": "Seattle",
    "timezone": "America/Los_Angeles",
}

# define custom pixel art

def main(config):
    # get coordinates and current time
    location = config.get("location")
    loc = json.decode(location) if location else json.decode(str(DEFAULT_LOCATION))
    timezone = loc["timezone"]
    lat = loc["lat"]
    lng = loc["lng"]
    now = time.now().in_location(timezone)
    now_unix = time.now().unix

    # get 24 vs. 12 hour clock selection
    clock24_bool = config.bool("24hour", False)
    if clock24_bool:
        clock_format = "15:04"
    else:
        clock_format = "3:04 PM"

    # get Celsius vs. Fahrenheait selection
    celsius_bool = config.bool("celsius", False)
    if celsius_bool:
        unit_temp = "C"
    else:
        unit_temp = "F"

    # wind thresholds for wave animations
    wind_medium_threshold_mps = 3 * 0.44704  # [mph] to [m/s]
    wind_heavy_threshold_mps = 10 * 0.44704  # [mph] to [m/s]

    # pull weather data from API or cache
    weather_url = "https://api.open-meteo.com/v1/forecast?latitude=" + str(lat) + "&longitude=" + str(lng) + "&current=temperature_2m,weather_code,cloud_cover,wind_speed_10m&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset&timeformat=unixtime&timezone=" + timezone
    res = http.get(url = weather_url, ttl_seconds = TTL_SECONDS)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (weather_url, res.status_code, res.body()))

    # DEVELOPMENT: check if result was served from API pull or cache
    if res.headers.get("Tidbyt-Cache-Status") == "HIT":
        print("Displaying cached data.")
    else:
        print("Calling Open Meteo API.")

    # get data values of interest from pulled data
    sunrise = res.json()["daily"]["sunrise"][0]
    sunset = res.json()["daily"]["sunset"][0]
    low_temp_C = res.json()["daily"]["temperature_2m_min"][0]
    now_temp_C = res.json()["current"]["temperature_2m"]
    high_temp_C = res.json()["daily"]["temperature_2m_max"][0]
    windspeed_kmph = res.json()["current"]["wind_speed_10m"]
    weather_code = res.json()["current"]["weather_code"]

    # convert times to unix and windspeed to m/s
    sunrise_unix = int(sunrise)
    sunset_unix = int(sunset)
    windspeed_mps = windspeed_kmph * 1000 / 60 / 60

    # convert temperature units
    low_temp = low_temp_C
    now_temp = now_temp_C
    high_temp = high_temp_C
    if unit_temp == "F":
        low_temp = low_temp_C * 9 / 5 + 32
        now_temp = now_temp_C * 9 / 5 + 32
        high_temp = high_temp_C * 9 / 5 + 32
    low_temp = int(low_temp)
    now_temp = int(now_temp)
    high_temp = int(high_temp)

    # set wind animation strength
    if windspeed_mps > wind_heavy_threshold_mps:
        wind = 2
    elif windspeed_mps > wind_medium_threshold_mps:
        wind = 1
    else:
        wind = 0

    # determine day/night and ratios for sun/moon heights
    min_height = 22
    max_height = 1
    if sunrise_unix <= now_unix and now_unix <= sunset_unix:
        day = True
        day_ratio = (now_unix - sunrise_unix) / (sunset_unix - sunrise_unix)
        night_ratio = 1
    else:
        day = False
        day_ratio = 1
        if now_unix > sunset_unix:
            # assume next sunrise is the same
            sunrise_unix = sunrise_unix + 24 * 60 * 60
        else:
            # assume previous sunset is the same
            sunset_unix = sunset_unix - 24 * 60 * 60
        night_ratio = (now_unix - sunset_unix) / (sunrise_unix - sunset_unix)
    sun_height = int(min_height * abs(0.5 - day_ratio) / 0.5) + max_height
    moon_height = int(min_height * abs(0.5 - night_ratio) / 0.5) + max_height

    # determine weather conditions
    weather_table = [
        # code, clouds, rain, snow, lightning,   # description
        [0, 0, 0, 0, 0],  # Clear sky
        [1, 1, 0, 0, 0],  # Mainly clear
        [2, 2, 0, 0, 0],  # Partly cloudy
        [3, 3, 0, 0, 0],  # Overcast
        [45, 3, 0, 0, 0],  # Fog
        [48, 3, 0, 0, 0],  # Depositing rime fog
        [51, 3, 1, 0, 0],  # Drizzle: light
        [53, 3, 1, 0, 0],  # Drizzle: moderate
        [55, 3, 2, 0, 0],  # Drizzle: dense
        [56, 3, 1, 0, 0],  # Freezing drizzle: light
        [57, 3, 2, 0, 0],  # Freezing drizzle: dense
        [61, 3, 1, 0, 0],  # Rain: slight
        [63, 3, 2, 0, 0],  # Rain: moderate
        [65, 3, 2, 0, 0],  # Rain: heavy
        [66, 3, 1, 0, 0],  # Freezing rain: light
        [67, 3, 2, 0, 0],  # Freezing rain: heavy
        [71, 3, 0, 1, 0],  # Snow fall: slight
        [73, 3, 0, 1, 0],  # Snow fall: moderate
        [75, 3, 0, 1, 0],  # Snow fall: heavy
        [77, 3, 0, 1, 0],  # Snow grains
        [80, 3, 1, 0, 0],  # Rain showers: slight
        [81, 3, 2, 0, 0],  # Rain showers: moderate
        [82, 3, 2, 0, 0],  # Rain showers: violent
        [85, 3, 0, 1, 0],  # Snow showers: slight
        [86, 3, 0, 1, 0],  # Snow showers: heavy
        [95, 3, 2, 0, 1],  # Thunderstorm: Slight or moderate
        [96, 3, 1, 0, 1],  # Thunderstorm with slight hail
        [99, 3, 2, 0, 1],  # Thunderstorm with heavy hail
    ]

    w = [0, 0, 0, 0, 0]
    for w in weather_table:
        if w[0] == weather_code:
            break
    cloud_scale = w[1]
    rain_scale = w[2]
    snow_scale = w[3]
    lightning_scale = w[4]

    # whale
    num = random.number(0, 100)
    if num > 90:
        enable_whale = True
    else:
        enable_whale = False

    # animation timing
    t_end = 15
    t_delay_ms = int(5000 / 24)  # 24 is slowest for seemless repeat
    t_delay = t_delay_ms / 1000
    pps = 1 / t_delay  # pixels per second
    offset = int(t_end * pps)  # offset number of pixels for seemless repeat

    # individual render components
    sky = draw_sky(day, day_ratio, sun_height, cloud_scale)
    sun = draw_sun(sun_height, cloud_scale)
    moon = draw_moon(moon_height, cloud_scale)
    ship = draw_ship(day, wind)
    ocean = draw_ocean(day)
    wave1 = draw_wave(day, wind, 0, 64, 20, 0, 21, [1, 1, 0, 0, 0, 0, 0, 0])
    wave2 = draw_wave(day, wind, 0, 64, 28, 0, 22, [1, 1, 1, 1, 0, 0, 1, 1])
    wave3 = draw_wave(day, wind, 50, 32, 22, 21, 21, [0, 0, 0, 0, 1, 1, 0, 0])
    wave4 = draw_wave(day, wind, 42, 32, 22, 22, 22, [0, 0, 1, 1, 1, 1, 1, 1])
    stream1_1 = draw_stream(day, wind, 50, 24, 20, 0)
    stream1_2 = draw_stream(day, wind, 50, 24, 20, offset)
    stream2_1 = draw_stream(day, wind, 10, 26, 20, 0)
    stream2_2 = draw_stream(day, wind, 10, 26, 20, offset)
    stream3_1 = draw_stream(day, wind, 35, 28, 20, 0)
    stream3_2 = draw_stream(day, wind, 35, 28, 20, offset)
    stream4_1 = draw_stream(day, wind, 5, 30, 20, 0)
    stream4_2 = draw_stream(day, wind, 5, 30, 20, offset)
    text_time = print_time(day, now, clock_format)
    text_low_temp = print_temp(day, str(low_temp), 50, 6)
    text_high_temp = print_temp(day, str(high_temp), 64, 6)
    text_now_temp = print_temp(day, str(now_temp) + " " + unit_temp, 64, 12)
    deg = draw_deg(day, 57, 12)
    stars = draw_stars(day, cloud_scale)
    clouds_heavy = draw_clouds(day, cloud_scale, 1, CLOUDS_HEAVY_DAY, CLOUDS_HEAVY_NIGHT)
    clouds_light = draw_clouds(day, cloud_scale, 0, CLOUDS_LIGHT_DAY, CLOUDS_LIGHT_NIGHT)
    rain_heavy = draw_rain_heavy(day, rain_scale)
    rain_light = draw_rain_light(day, rain_scale)
    snow = draw_snow(day, snow_scale)
    lightning = draw_lightning(lightning_scale)
    whale = draw_whale(enable_whale, 29, 13)

    # top-level render
    return render.Root(delay = t_delay_ms, child = render.Stack(children = [
        sky,
        stars,
        sun,
        moon,
        ship,
        snow,
        rain_heavy,
        rain_light,
        lightning,
        ocean,
        wave1,
        wave2,
        wave3,
        wave4,
        stream1_1,
        stream1_2,
        stream2_1,
        stream2_2,
        stream3_1,
        stream3_2,
        stream4_1,
        stream4_2,
        clouds_heavy,
        clouds_light,
        whale,
        text_time,
        text_low_temp,
        text_high_temp,
        text_now_temp,
        deg,
    ]))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                icon = "locationDot",
                desc = "Determines location for time and weather.",
            ),
            schema.Toggle(
                id = "24hour",
                name = "24 Hour Time",
                icon = "clock",
                desc = "Display 12-hour time (off) or 24-hour time (on).",
                default = False,
            ),
            schema.Toggle(
                id = "celsius",
                name = "Celsius Temperature",
                icon = "thermometer",
                desc = "Display temperature in Fahrenheit (off) or Celsius (on).",
                default = False,
            ),
        ],
    )

def draw_sun(sun_height, cloud_scale):
    if cloud_scale > 2:
        sun_color = "#ffffc5"
    else:
        sun_color = "#FFFF00"
    sun = render.Column(children = [
        render.Box(height = sun_height),
        render.Row(children = [
            render.Box(width = 22),
            render.Circle(color = sun_color, diameter = 8),
        ]),
    ])
    return sun

def draw_moon(moon_height, cloud_scale):
    if cloud_scale > 2:
        img = MOON_CLOUDS
    else:
        img = MOON
    moon = render.Column(children = [
        render.Box(height = moon_height),
        render.Row(children = [
            render.Box(width = 22),
            render.Image(src = img),
        ]),
    ])
    return moon

def draw_sky(day, day_ratio, sun_height, cloud_scale):
    if day:
        if cloud_scale > 2:
            sky = render.Box(width = 64, height = 32, color = "#aaaaaa")
        elif sun_height > 20:
            if day_ratio < 0.5:
                sky = render.Column(children = [
                    render.Box(width = 64, height = 5, color = "#87CEEB"),
                    render.Box(width = 64, height = 8, color = "#FFFF8c"),
                    render.Box(width = 64, height = 6, color = "#ff724c"),
                    render.Box(width = 64, height = 4, color = "#AA336A"),
                ])
            else:
                sky = render.Column(children = [
                    render.Box(width = 64, height = 5, color = "#87CEEB"),
                    render.Box(width = 64, height = 8, color = "#FFFF00"),
                    render.Box(width = 64, height = 6, color = "#FFA500"),
                    render.Box(width = 64, height = 4, color = "#ff0000"),
                ])
        else:
            sky = render.Box(width = 64, height = 32, color = "#87CEEB")
    elif cloud_scale > 2:
        sky = render.Box(width = 64, height = 32, color = "#202020")
    else:
        sky = render.Box(width = 64, height = 32, color = "#000000")
    return sky

def draw_ship(day, wind):
    height1 = 8
    height2 = 9
    height3 = 10
    left_space = 4
    if day:
        ship = SHIP_DAY
    else:
        ship = SHIP_NIGHT
    if wind == 2:
        ship = render.Column(children = [
            render.Animation(children = [
                render.Box(height = height1),
                render.Box(height = height1),
                render.Box(height = height2),
                render.Box(height = height2),
                render.Box(height = height3),
                render.Box(height = height3),
                render.Box(height = height2),
                render.Box(height = height2),
            ]),
            render.Row(children = [
                render.Box(width = left_space),
                render.Image(src = ship),
            ]),
        ])
    else:
        ship = render.Column(children = [
            render.Box(height = height3),
            render.Row(children = [
                render.Box(width = left_space),
                render.Image(src = ship),
            ]),
        ])
    return ship

def draw_ocean(day):
    if day:
        ocean_color = "#0000FF"
    else:
        ocean_color = "#131862"
    ocean = render.Column(children = [
        render.Box(width = 64, height = 23),
        render.Box(width = 64, height = 9, color = ocean_color),
    ])
    return ocean

def draw_wave(day, wind, w1, w2, w3, h1, h2, seq):
    if day:
        ocean_color = "#0000FF"
    else:
        ocean_color = "#131862"
    colors = []
    for s in seq:
        if s == 0:
            colors.append("")
        else:
            colors.append(ocean_color)
    if wind == 2:
        if w1 == 0:
            wave = render.Column(children = [
                render.Box(width = w2, height = h2),
                render.Animation(children = [
                    render.Box(width = w3, height = 1, color = colors[0]),
                    render.Box(width = w3, height = 1, color = colors[1]),
                    render.Box(width = w3, height = 1, color = colors[2]),
                    render.Box(width = w3, height = 1, color = colors[3]),
                    render.Box(width = w3, height = 1, color = colors[4]),
                    render.Box(width = w3, height = 1, color = colors[5]),
                    render.Box(width = w3, height = 1, color = colors[6]),
                    render.Box(width = w3, height = 1, color = colors[7]),
                ]),
            ])
        else:
            wave = render.Row(children = [
                render.Box(width = w1, height = h1),
                render.Column(children = [
                    render.Box(width = w2, height = h2),
                    render.Animation(children = [
                        render.Box(width = w3, height = 1, color = colors[0]),
                        render.Box(width = w3, height = 1, color = colors[1]),
                        render.Box(width = w3, height = 1, color = colors[2]),
                        render.Box(width = w3, height = 1, color = colors[3]),
                        render.Box(width = w3, height = 1, color = colors[4]),
                        render.Box(width = w3, height = 1, color = colors[5]),
                        render.Box(width = w3, height = 1, color = colors[6]),
                        render.Box(width = w3, height = 1, color = colors[7]),
                    ]),
                ]),
            ])
    else:
        wave = render.Box()
    return wave

def draw_stream(day, wind, start_width, start_height, width, offset):
    if day:
        stream_color = "#00008B"
    else:
        stream_color = "#00094b"
    if wind > 0:
        stream = render.Column(children = [
            render.Box(height = start_height),
            render.Marquee(
                width = 64,
                offset_start = offset,
                offset_end = 0,
                child = render.Row(children = [
                    render.Box(width = start_width, height = 1),
                    render.Box(width = width, height = 1, color = stream_color),
                    render.Box(width = 65 - start_width - width, height = 1),
                ]),
            ),
        ])
    else:
        stream = render.Box()
    return stream

def print_time(day, now, clock_format):
    if day:
        text_color = "#000000"
    else:
        text_color = "#ffffff"
    text = render.WrappedText(
        align = "right",
        width = 64,
        color = text_color,
        content = now.format(clock_format),
        font = "tom-thumb",
    )
    return text

def print_temp(day, temperature, x, y):
    if day:
        text_color = "#000000"
    else:
        text_color = "#ffffff"
    text = render.Column(children = [
        render.Box(height = y),
        render.WrappedText(
            align = "right",
            width = x,
            color = text_color,
            content = temperature,
            font = "tom-thumb",
        ),
    ])
    return text

def draw_deg(day, x, y):
    if day:
        deg_color = "#000000"
    else:
        deg_color = "#ffffff"
    deg = render.Column(children = [
        render.Box(height = y),
        render.Row(children = [
            render.Box(width = x),
            render.Box(width = 2, height = 2, color = deg_color),
        ]),
    ])
    return deg

def draw_stars(day, cloud_scale):
    if day or cloud_scale > 2:
        star = render.Box()
    else:
        star = render.Image(src = STARS)
    return star

def draw_clouds(day, cloud_scale, threshold, img_day, img_night):
    if day:
        img = img_day
    else:
        img = img_night
    if cloud_scale > threshold:
        clouds = render.Image(src = img)
    else:
        clouds = render.Box()
    return clouds

def draw_rain_light(day, rain_scale):
    if day:
        img = RAIN_LIGHT_DAY
    else:
        img = RAIN_LIGHT_NIGHT
    if rain_scale > 0:
        rain = render.Column(children = [
            render.Animation(children = [
                render.Box(height = 1),
                render.Box(height = 1),
                render.Box(height = 1),
                render.Box(height = 1),
                render.Box(height = 5),
                render.Box(height = 5),
                render.Box(height = 5),
                render.Box(height = 5),
            ]),
            render.Image(src = img),
        ])
    else:
        rain = render.Box()
    return rain

def draw_rain_heavy(day, rain_scale):
    if day:
        img = RAIN_HEAVY_DAY
    else:
        img = RAIN_HEAVY_NIGHT
    if rain_scale > 1:
        rain = render.Column(children = [
            render.Animation(children = [
                render.Box(height = 1),
                render.Box(height = 1),
                render.Box(height = 5),
                render.Box(height = 5),
            ]),
            render.Image(src = img),
        ])
    else:
        rain = render.Box()
    return rain

def draw_snow(day, snow_scale):
    if day:
        img = SNOW_DAY
    else:
        img = SNOW_NIGHT
    if snow_scale > 0:
        snow = render.Column(children = [
            render.Animation(children = [
                render.Box(height = 1),
                render.Box(height = 1),
                render.Box(height = 1),
                render.Box(height = 1),
                render.Box(height = 5),
                render.Box(height = 5),
                render.Box(height = 5),
                render.Box(height = 5),
            ]),
            render.Image(src = img),
        ])
    else:
        snow = render.Box()
    return snow

def draw_lightning(lightning_scale):
    if lightning_scale > 0:
        lightning = render.Animation(children = [
            render.Box(),
            render.Box(),
            render.Image(src = LIGHTNING),
            render.Image(src = LIGHTNING),
            render.Box(),
            render.Box(),
            render.Box(),
            render.Box(),
            render.Box(),
            render.Box(),
            render.Box(),
            render.Box(),
            render.Box(),
            render.Box(),
            render.Box(),
            render.Box(),
        ])
    else:
        lightning = render.Box()
    return lightning

def draw_whale(enable, x, y):
    if enable:
        whale = render.Column(children = [
            render.Box(height = y),
            render.Row(children = [
                render.Box(width = x),
                render.Animation(children = [
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Image(src = WHALE1),
                    render.Image(src = WHALE1),
                    render.Image(src = WHALE2),
                    render.Image(src = WHALE2),
                    render.Image(src = WHALE3),
                    render.Image(src = WHALE3),
                    render.Image(src = WHALE3),
                    render.Image(src = WHALE3),
                    render.Image(src = WHALE3),
                    render.Image(src = WHALE4),
                    render.Image(src = WHALE5),
                    render.Image(src = WHALE6),
                    render.Image(src = WHALE7),
                    render.Image(src = WHALE8),
                    render.Image(src = WHALE3),
                    render.Image(src = WHALE3),
                    render.Image(src = WHALE3),
                    render.Image(src = WHALE3),
                    render.Image(src = WHALE3),
                    render.Image(src = WHALE3),
                    render.Image(src = WHALE3),
                    render.Image(src = WHALE3),
                    render.Image(src = WHALE3),
                    render.Image(src = WHALE2),
                    render.Image(src = WHALE2),
                    render.Image(src = WHALE1),
                    render.Image(src = WHALE1),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                    render.Box(),
                ]),
            ]),
        ])
    else:
        whale = render.Box()
    return whale
