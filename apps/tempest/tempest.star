"""
Applet: Tempest
Summary: Display your Tempest Weather data
Description: Overview of your Tempest Weather Station, including current temperature, wind chill, pressure, inches of rain, and wind.
Author: epifinygirl
Adapted for Tronbyt: tavdog
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
load("render.star", "render")
load("sample_forecast_response.json", SAMPLE_FORECAST_RESPONSE = "file")
load("sample_station_response.json", SAMPLE_STATION_RESPONSE = "file")
load("schema.star", "schema")

TEMPEST_STATIONS_URL = "https://swd.weatherflow.com/swd/rest/stations?token=%s"

TEMPEST_FORECAST_URL = "https://swd.weatherflow.com/swd/rest/better_forecast?token=%s"

TEMPEST_OBSERVATION_URL = "https://swd.weatherflow.com/swd/rest/observations/station/%s?token=%s"

def main(config):
    if not "station" in config or not "token" in config:
        station_res = json.decode(SAMPLE_STATION_RESPONSE.readall())
        forecast_res = json.decode(SAMPLE_FORECAST_RESPONSE.readall())
        units = station_res["station_units"]
        token = "blah"
    else:
        # ensure we have the station ID in the correct format
        station_id = config["station"]
        token = config["token"]
        if "." in station_id:
            station_id = station_id.split(".")[0]
        print("station id in main : " + str(station_id))
        url = TEMPEST_OBSERVATION_URL % (station_id, token)
        print(url)
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

    # If we can't get an observation, we should just skip it in the rotation.
    if len(station_res["obs"]) == 0:
        return []
    feel_dew_choice = config.get("Feels_Dew", "1")
    conditions = forecast_res["current_conditions"]

    temp = "%d°" % conditions["air_temperature"]
    humidity = "%d%%" % conditions["relative_humidity"]
    wind = "%s %d %s" % (
        conditions["wind_direction_cardinal"],
        conditions["wind_avg"],
        units["units_wind"],
    )
    pressure = "%g" % conditions["sea_level_pressure"]
    rain = "%g" % conditions.get("precip_accum_local_day", 0.0)
    feels = "%d°" % conditions["feels_like"]
    dew_pt = "%d°" % conditions["dew_point"]
    pressure_trend = conditions["pressure_trend"]
    icon = ICON_MAP.get(conditions["icon"], ICON_MAP["cloudy"])
    if feel_dew_choice == "1":
        updated_temp = (feels)
    elif feel_dew_choice == "2":
        updated_temp = (dew_pt)
    else:
        updated_temp = (" ")

    if pressure_trend == "falling":
        pressure_icon = ("↓")

    elif pressure_trend == "rising":
        pressure_icon = ("↑")

    else:
        pressure_icon = ("→")
    rain_units = units["units_precip"]

    return render.Root(
        delay = 500,
        child = render.Box(
            padding = 1,
            child = render.Column(
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        children = [
                            render.Column(
                                cross_align = "start",
                                children = [
                                    render.Text(
                                        content = temp,
                                        color = "#2a2",
                                    ),
                                    render.Text(
                                        content = updated_temp,
                                        color = "#FFFF00",
                                    ),
                                    render.Image(icon),
                                    render.Box(width = 2, height = 1),
                                ],
                            ),
                            render.Column(
                                expanded = True,
                                main_align = "space_evenly",
                                cross_align = "end",
                                children = [
                                    render.Text(
                                        content = humidity,
                                        color = "#66f",
                                    ),
                                    render.Text(
                                        content = rain + " " + rain_units,
                                        color = "#808080",
                                    ),
                                    render.Text(
                                        content = pressure + " " + pressure_icon,
                                    ),
                                    render.Text(
                                        content = wind,
                                        font = "CG-pixel-3x5-mono",
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = "Feels Like",
            value = "1",
        ),
        schema.Option(
            display = "Dew Point",
            value = "2",
        ),
        schema.Option(
            display = "None",
            value = "3",
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
            "id": "Feels_Dew",
            "name": "Feels Like or Dew Point Temperature",
            "type": "dropdown",
            "options": options,
            "default": "1",
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

# def oauth_handler(params):
#     # deserialize oauth2 parameters
#     params = json.decode(params)

#     # exchange parameters and client secret for an access token
#     res = http.post(
#         url = TEMPEST_TOKEN_URL,
#         headers = {
#             "Accept": "application/json",
#         },
#         form_body = dict(
#             params,
#             client_secret = OAUTH2_CLIENT_SECRET,
#         ),
#         form_encoding = "application/x-www-form-urlencoded",
#     )
#     if res.status_code != 200:
#         fail("token request failed with status code: %d - %s" %
#              (res.status_code, res.body()))

#     token_params = res.json()
#     access_token = token_params["access_token"]

#     return access_token

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

def wind_direction(heading):
    if heading <= 360 and heading >= 348.75:
        return "N"
    elif heading >= 0 and heading <= 11.25:
        return "N"
    elif heading >= 11.25 and heading <= 33.75:
        return "NNE"
    elif heading >= 33.75 and heading <= 56.25:
        return "NE"
    elif heading >= 56.25 and heading <= 78.75:
        return "ENE"
    elif heading >= 78.75 and heading <= 101.25:
        return "E"
    elif heading >= 101.25 and heading <= 123.75:
        return "ESE"
    elif heading >= 123.75 and heading <= 146.25:
        return "SE"
    elif heading >= 146.25 and heading <= 168.75:
        return "SSE"
    elif heading >= 168.75 and heading <= 191.25:
        return "S"
    elif heading >= 191.25 and heading <= 213.75:
        return "SSW"
    elif heading >= 213.75 and heading <= 236.25:
        return "SW"
    elif heading >= 236.25 and heading <= 258.75:
        return "WSW"
    elif heading >= 258.75 and heading <= 281.25:
        return "W"
    elif heading >= 281.25 and heading <= 303.75:
        return "WNW"
    elif heading >= 303.75 and heading <= 326.25:
        return "NW"
    elif heading >= 326.25 and heading <= 348.74:
        return "NNW"

    return "-"
