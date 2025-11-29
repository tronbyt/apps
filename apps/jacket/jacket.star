load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

REFRESH_RATE = 3600
OPEN_WEATHER_URL = "https://api.openweathermap.org/data/3.0/onecall"
NOAA_POINTS_URL = "https://api.weather.gov/points"
NOAA_USER_AGENT = "JacketApp/1.0 (tidbyt; contact@example.com)"

ADVERBS = [
    "damn cold",
    "darn cold",
    "bone chilling",
    "glacial",
    "frigid",
    "freezing",
    "frosty",
    "pretty cold",
    "chilly",
    "brisk",
    "cool",
    "quite temperate",
    "rather mild",
    "pretty nice",
    "positively balmy",
    "extra warm",
    "kinda hot",
    "roasting",
    "scorching",
    "oven-like",
    "your hair is on FIRE",
]
RANGE_MIN = -10
RANGE_MAX = 110
DEFAULT_JACKET_LIMIT = 60
DEFAULT_COAT_LIMIT = 35

# Weather provider constants
PROVIDER_OPENWEATHER = "openweather"
PROVIDER_NOAA = "noaa"

def ktof(k):
    return c2f(k - 273.15)

def f2c(f):
    return (((f - 32) * 5) / 9)

def c2f(c):
    return (((c * 9) / 5) + 32)

def normalize(value, min, max):
    excess = min < 0 and 0 - min or 0
    return value + excess, min + excess, max + excess

def clamp(value, min, max):
    clamped = value
    if value < min:
        clamped = min
    elif value > max:
        clamped = max
    return clamped

def percentOfRange(value, min, max):
    # normalize
    value, min, max = normalize(value, min, max)

    # maths
    percent = value / max - min

    # clamping
    return clamp(percent, 0, 1)

def getTempWord(temp, unit = "f"):
    # convert our range bounds to c if necessary
    tmin = unit == "f" and RANGE_MIN or f2c(RANGE_MIN)
    tmax = unit == "f" and RANGE_MAX or f2c(RANGE_MAX)

    # % of our temp range
    tempPer = percentOfRange(temp, tmin, tmax)

    # index in array of desc, based on that percentage
    index = math.floor(tempPer * len(ADVERBS))

    # ensure temp is not outside of our range
    index = max(0, index)
    index = min(len(ADVERBS) - 1, index)

    # return that word
    return ADVERBS[index]

def getMainString(temp, jacketLimit, coatLimit):
    negation = (temp > jacketLimit) and " don't" or ""
    outerwear = (temp < coatLimit) and "coat" or "jacket"
    return "You%s need a %s" % (negation, outerwear)

def getSubString(temp, unit = "f", widgetMode = False):
    if widgetMode:
        return getTempWord(temp, unit)
    return "It's %s outside" % getTempWord(temp, unit)

def main(config):
    widgetMode = config.bool("$widget")
    
    # Get weather data - returns feels_like temp in Fahrenheit
    feels_like = get_feels_like_temp(config)
    
    jacketLimit = config.get("jacketLimit", DEFAULT_JACKET_LIMIT)
    coatLimit = config.get("coatLimit", DEFAULT_COAT_LIMIT)
    jacketLimit = int(jacketLimit)
    coatLimit = int(coatLimit)

    mainString = getMainString(feels_like, jacketLimit, coatLimit)
    show_description = config.get("show_description")
    subString = ""

    weather_info = []

    weather_info.append(
        render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.WrappedText("%s" % mainString, "tb-8", align = "center"),
            ],
        ),
    )
    if show_description != "false":
        subString = getSubString(feels_like, widgetMode = widgetMode)
        weather_info.append(render.Box(width = 64, height = 1, color = config.get("divider_color", "#1167B1")))
        weather_info.append(
            render.Row(
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Marquee(
                        width = 64,
                        child = render.Text("%s" % subString, "CG-pixel-3x5-mono"),
                    ),
                ],
            ),
        )

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = weather_info,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                icon = "locationDot",
                desc = "Location for which to display time and weather",
            ),
            schema.Dropdown(
                id = "weather_provider",
                name = "Weather Provider",
                desc = "Choose weather data source",
                icon = "cloud",
                default = PROVIDER_OPENWEATHER,
                options = [
                    schema.Option(
                        display = "OpenWeather (requires API key)",
                        value = PROVIDER_OPENWEATHER,
                    ),
                    schema.Option(
                        display = "NOAA (US only, no API key needed)",
                        value = PROVIDER_NOAA,
                    ),
                ],
            ),
            schema.Text(
                id = "api_key",
                name = "OpenWeather API Key",
                desc = "OpenWeather API Key (not needed for NOAA)",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "jacketLimit",
                name = "Jacket Limit (default 60F)",
                desc = "Below this value will suggest a jacket",
                icon = "gear",
            ),
            schema.Text(
                id = "coatLimit",
                name = "Coat Limit (default 35F, should be lower than jacket limit)",
                desc = "Below this value will suggest a coat",
                icon = "gear",
            ),
            schema.Toggle(
                id = "show_description",
                name = "Show Description",
                desc = "Show description of weather",
                icon = "gear",
                default = True,
            ),
            schema.Color(
                id = "divider_color",
                name = "Divider Color",
                desc = "The color of the divider",
                icon = "brush",
                default = "#1167B1",
            ),
        ],
    )

def get_feels_like_temp(config):
    """Get feels like temperature in Fahrenheit from configured provider"""
    provider = config.get("weather_provider", PROVIDER_OPENWEATHER)
    
    if provider == PROVIDER_NOAA:
        return get_noaa_feels_like(config)
    else:
        # Default to OpenWeather for backward compatibility
        current_data = get_openweather_data(config)
        return ktof(current_data["feels_like"])

def get_noaa_feels_like(config):
    """Get feels like temperature from NOAA API (returns Fahrenheit)"""
    location = config.get("location", None)
    
    if location == None:
        return SAMPLE_NOAA_TEMP
    
    location = json.decode(location)
    lat = location["lat"]
    lng = location["lng"]
    
    # Create cache key based on location
    cache_key = "noaa_weather_%s_%s" % (lat, lng)
    cached_data = cache.get(cache_key)
    
    if cached_data != None:
        return float(cached_data)
    
    # Step 1: Get the grid point info from coordinates
    points_url = "%s/%s,%s" % (NOAA_POINTS_URL, lat, lng)
    points_res = http.get(
        url = points_url,
        headers = {"User-Agent": NOAA_USER_AGENT},
        ttl_seconds = REFRESH_RATE,
    )
    
    if points_res.status_code != 200:
        # NOAA only works for US locations
        return SAMPLE_NOAA_TEMP
    
    points_data = points_res.json()
    
    # Get the hourly forecast URL from the points response
    forecast_hourly_url = points_data["properties"]["forecastHourly"]
    
    # Step 2: Get the hourly forecast
    forecast_res = http.get(
        url = forecast_hourly_url,
        headers = {"User-Agent": NOAA_USER_AGENT},
        ttl_seconds = REFRESH_RATE,
    )
    
    if forecast_res.status_code != 200:
        return SAMPLE_NOAA_TEMP
    
    forecast_data = forecast_res.json()
    
    # Get the first period (current hour) temperature
    # NOAA returns temperature in Fahrenheit by default
    periods = forecast_data["properties"]["periods"]
    if len(periods) == 0:
        return SAMPLE_NOAA_TEMP
    
    current_period = periods[0]
    temp = current_period["temperature"]
    
    # NOAA doesn't provide a separate "feels like" temperature in the hourly forecast
    # The temperature returned is the actual temperature, but for simplicity we use it
    # as the effective temperature (feels like would require additional calculation
    # based on wind chill / heat index which NOAA doesn't directly provide in this endpoint)
    feels_like = float(temp)
    
    # Cache the result
    cache.set(cache_key, str(feels_like), ttl_seconds = REFRESH_RATE)
    
    return feels_like

def get_openweather_data(config):
    """Get weather data from OpenWeather API (original implementation)"""
    api_key = config.get("api_key", None)
    location = config.get("location", None)
    cached_data = cache.get("weather_data-{0}".format(api_key))

    if cached_data != None:
        cache_res = json.decode(cached_data)
        return cache_res

    else:
        if api_key == None:
            return SAMPLE_STATION_RESPONSE["current"]
        if location == None:
            return SAMPLE_STATION_RESPONSE["current"]

        location = json.decode(location)
        query = "%s?exclude=minutely,hourly,daily,alerts&lat=%s&lon=%s&appid=%s" % (OPEN_WEATHER_URL, location["lat"], location["lng"], api_key)
        res = http.get(
            url = query,
            ttl_seconds = REFRESH_RATE,
        )
        if res.status_code != 200:
            return SAMPLE_STATION_RESPONSE["current"]

        current_data = res.json()["current"]

        cache.set("weather_data-{0}".format(api_key), json.encode(current_data), ttl_seconds = REFRESH_RATE)
        return current_data

# Sample temperature for NOAA fallback (in Fahrenheit)
SAMPLE_NOAA_TEMP = 65.0

SAMPLE_STATION_RESPONSE = {
    "lat": 40.678,
    "lon": -73.944,
    "timezone": "America/New_York",
    "timezone_offset": -14400,
    "current": {
        "dt": 1685459950,
        "sunrise": 1685438891,
        "sunset": 1685492324,
        "temp": 291.72,
        "feels_like": 291.02,
        "pressure": 1024,
        "humidity": 53,
        "dew_point": 281.97,
        "uvi": 6.51,
        "clouds": 0,
        "visibility": 10000,
        "wind_speed": 7.2,
        "wind_deg": 40,
        "weather": [
            {
                "id": 711,
                "main": "Smoke",
                "description": "smoke",
                "icon": "50d",
            },
        ],
    },
}

def add_row(title, font):
    return render.Row(
        main_align = "center",
        cross_align = "center",
        children = [
            render.Marquee(
                width = 64,
                child = render.Text("%s" % title, font),
            ),
        ],
    )
