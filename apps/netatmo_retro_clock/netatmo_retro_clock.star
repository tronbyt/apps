"""
Applet: Netatmo Retro Clock
Summary: Clock with Netatmo temperatures and OpenWeather icon
Description: Displays a clean clock with Netatmo indoor/outdoor temperatures and an OpenWeather weather icon.
Author: Arnaud
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("icons.star", "THREE_DAY_ICO")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

DEFAULT_LOCATION = """
{
    "lat": 48.8534951,
    "lng": 2.3483915,
    "locality": "Paris",
    "timezone": "Europe/Paris"
}
"""

OPENWEATHER_CURRWEATHER_URL = "https://api.openweathermap.org/data/2.5/weather?lat={latitude}&lon={longitude}&appid={api_key}&units={units}&lang=en"

OAUTH2_CLIENT_SECRET = secret.decrypt("AV6+xWcEY+xlza5nc6Vx3IhSZOD+MGdeVROlRBYrpIwypN5EIIncp7hyCiIQMGVnPS0Q1SlVfHZXB92095MTfHew3wzuEJ14ihbjpxbZNQJhuYA+4O3fR4GFjOTy98EfJobFvxLguAtnNE149hITsJeIxyKfnI2yHZFVgg2Y2pYHoHzSqA==")
CLIENT_ID = "622106585db6d223df25fdf8"

def format_two_digits(value):
    v = int(value)
    if v < 10:
        return "0" + str(v)
    return str(v)

def select_outdoor_module(modules):
    for m in modules:
        if "data_type" in m and "type" in m:
            if m["data_type"] == ["Temperature", "Humidity"] and m["type"] == "NAModule1":
                return m
    return None

def oauth_handler(params):
    params = json.decode(params)

    res = http.post(
        url = "https://api.netatmo.com/oauth2/token",
        headers = {"Accept": "application/json"},
        form_body = dict(
            params,
            client_secret = OAUTH2_CLIENT_SECRET,
            scope = "read_station",
        ),
        form_encoding = "application/x-www-form-urlencoded",
    )

    if res.status_code != 200:
        fail("token request failed")

    token_params = res.json()
    refresh_token = token_params["refresh_token"]

    cache.set(
        refresh_token,
        token_params["access_token"],
        ttl_seconds = int(token_params["expires_in"] - 30),
    )
    return refresh_token

def get_access_token(refresh_token):
    res = http.post(
        url = "https://api.netatmo.com/oauth2/token",
        headers = {"Accept": "application/json"},
        form_body = dict(
            refresh_token = refresh_token,
            client_secret = OAUTH2_CLIENT_SECRET,
            grant_type = "refresh_token",
            client_id = CLIENT_ID,
        ),
        form_encoding = "application/x-www-form-urlencoded",
    )

    if res.status_code != 200:
        fail("token refresh failed")

    token_params = res.json()
    cache.set(
        refresh_token,
        token_params["access_token"],
        ttl_seconds = int(token_params["expires_in"] - 30),
    )
    return token_params["access_token"]

def get_current_weather_conditions(url, ttl):
    res = http.get(url, ttl_seconds = ttl)
    if res.status_code != 200:
        fail("weather request failed")
    return res.json()

def get_weather_icon(config):
    api_key = config.get("weather_api", "")
    if api_key == "":
        return base64.decode(THREE_DAY_ICO["sunny.png"])

    location_raw = config.get("location", "") or DEFAULT_LOCATION
    location = json.decode(location_raw)

    request_url = OPENWEATHER_CURRWEATHER_URL.format(
        latitude = location["lat"],
        longitude = location["lng"],
        api_key = api_key,
        units = "metric",
    )

    data = get_current_weather_conditions(request_url, 300)
    icon_num = int(data["weather"][0]["id"])
    icon_code = str(data["weather"][0]["icon"])

    if icon_num == 800 and "n" in icon_code:
        icon_ref = "moony.png"
    elif icon_num == 800:
        icon_ref = "sunny.png"
    elif icon_num >= 801 and icon_num <= 802 and "n" in icon_code:
        icon_ref = "moonyish.png"
    elif icon_num >= 801 and icon_num <= 802:
        icon_ref = "sunnyish.png"
    elif icon_num >= 803:
        icon_ref = "cloudy.png"
    elif icon_num >= 600:
        icon_ref = "snowy2.png"
    elif icon_num >= 500:
        icon_ref = "rainy.png"
    elif icon_num >= 200:
        icon_ref = "thundery.png"
    else:
        icon_ref = "sunny.png"

    return base64.decode(THREE_DAY_ICO[icon_ref])

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Netatmo",
                desc = "Connect your Netatmo account",
                icon = "cloud",
                handler = oauth_handler,
                client_id = CLIENT_ID,
                authorization_endpoint = "https://api.netatmo.com/oauth2/authorize",
                scopes = ["read_station"],
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Choose the city for the weather icon",
                icon = "locationDot",
            ),
            schema.Text(
                id = "weather_api",
                name = "OpenWeather API Key",
                desc = "Enter your OpenWeather API key",
                icon = "gear",
            ),
            schema.Toggle(
                id = "fahrenheit",
                name = "Fahrenheit",
                desc = "Display temperatures in fahrenheit",
                icon = "temperatureHigh",
            ),
        ],
    )

def main(config):
    refresh_token = config.get("auth")
    fahrenheit = config.bool("fahrenheit")

    if refresh_token:
        token = cache.get(refresh_token) or get_access_token(refresh_token)
        res = http.get(
            url = "https://api.netatmo.com/api/getstationsdata",
            headers = {"Authorization": "Bearer %s" % token},
        )
        if res.status_code != 200:
            fail("Netatmo station request failed")
        body = res.json()
    else:
        body = json.decode(EXAMPLE_DATA)

    indoor = body["body"]["devices"][0]
    outdoor = select_outdoor_module(indoor["modules"])

    indoor_temp = indoor["dashboard_data"]["Temperature"]
    outdoor_temp = outdoor["dashboard_data"]["Temperature"] if outdoor else indoor_temp

    if fahrenheit:
        indoor_temp = indoor_temp * 1.8 + 32
        outdoor_temp = outdoor_temp * 1.8 + 32

    indoor_display = format_two_digits(indoor_temp) + "°"
    outdoor_display = format_two_digits(outdoor_temp) + "°"

    outdoor_color = "#7FB3FF"
    indoor_color = "#FFC857"

    location_raw = config.get("location", "") or DEFAULT_LOCATION
    location = json.decode(location_raw)
    now = time.now().in_location(location.get("timezone", "Europe/Paris"))
    current_time = now.format("15:04")

    icon = get_weather_icon(config)

    return render.Root(
        child = render.Box(
            width = 64,
            height = 32,
            color = "#000000",
            child = render.Column(
                children = [
                    render.Box(
                        width = 64,
                        height = 20,
                        child = render.Row(
                            children = [
                                render.Box(
                                    width = 32,
                                    height = 20,
                                    child = render.Column(
                                        main_align = "center",
                                        cross_align = "start",
                                        children = [
                                            render.Image(
                                                src = icon,
                                                width = 20,
                                                height = 20,
                                            ),
                                        ],
                                    ),
                                ),
                                render.Box(
                                    width = 32,
                                    height = 20,
                                    child = render.Column(
                                        main_align = "center",
                                        cross_align = "start",
                                        children = [
                                            render.Text(
                                                content = current_time,
                                                font = "tb-8",
                                                color = "#ffffff",
                                            ),
                                        ],
                                    ),
                                ),
                            ],
                        ),
                    ),
                    render.Box(
                        width = 64,
                        height = 12,
                        child = render.Row(
                            children = [
                                render.Box(
                                    width = 32,
                                    height = 12,
                                    child = render.Column(
                                        main_align = "center",
                                        cross_align = "start",
                                        children = [
                                            render.Row(
                                                children = [
                                                    render.Box(width = 2, height = 1),
                                                    render.Text(
                                                        content = outdoor_display,
                                                        color = outdoor_color,
                                                    ),
                                                ],
                                            ),
                                        ],
                                    ),
                                ),
                                render.Box(
                                    width = 32,
                                    height = 12,
                                    child = render.Column(
                                        main_align = "center",
                                        cross_align = "start",
                                        children = [
                                            render.Text(
                                                content = indoor_display,
                                                color = indoor_color,
                                            ),
                                        ],
                                    ),
                                ),
                            ],
                        ),
                    ),
                ],
            ),
        ),
    )

EXAMPLE_DATA = """{"body":{"devices":[{"dashboard_data":{"Temperature":23},"modules":[{"type":"NAModule1","data_type":["Temperature","Humidity"],"dashboard_data":{"Temperature":8}}]}]}}"""
