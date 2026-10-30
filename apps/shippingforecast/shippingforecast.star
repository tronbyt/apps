"""
Applet: Shipping Forecast
Summary: Bespoke shipping forecasts
Description: Provides the weather for a location in a nice, pleasant, calming, shipping forecast style. All the vibes without the shortwave static. Displays wind, conditions, and visability.
Author: lumberbarons
"""

load("http.star", "http")
load("images/lh1_icon.png", LH1_ICON_ASSET = "file")
load("images/lh2_icon.png", LH2_ICON_ASSET = "file")
load("images/lh3_icon.png", LH3_ICON_ASSET = "file")
load("images/lh4_icon.png", LH4_ICON_ASSET = "file")
load("images/lh5_icon.png", LH5_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

LH1_ICON = LH1_ICON_ASSET.readall()
LH2_ICON = LH2_ICON_ASSET.readall()
LH3_ICON = LH3_ICON_ASSET.readall()
LH4_ICON = LH4_ICON_ASSET.readall()
LH5_ICON = LH5_ICON_ASSET.readall()

FORECAST_URL = "https://weather.lmbrn.ca/v1/forecast"

DEFAULT_LAT = "57.5979648"
DEFAULT_LON = "-13.6939501"

DEFAULT_FORECAST = "North 0. Clear. Something is not right."

def is_proper_float(s):
    s = s.strip()
    if not s:
        return False
    if s.startswith("-"):
        s = s[1:]
    parts = s.split(".")
    if len(parts) not in [1, 2]:
        return False
    for part in parts:
        if not part.isdigit():
            return False
    return True

def round_to_two_decimals(number):
    return int(number * 100 + 0.5) / 100.0

def parse_location(location):
    splitLocation = location.split(",")

    if len(splitLocation) != 2:
        print("invalid location: " + location)
        return DEFAULT_LAT, DEFAULT_LON

    lat = splitLocation[0].strip()
    lon = splitLocation[1].strip()

    if not is_proper_float(lat):
        print("invalid lat: " + lat)
        return DEFAULT_LAT, DEFAULT_LON
    elif not is_proper_float(lon):
        print("invalid lon: " + lon)
        return DEFAULT_LAT, DEFAULT_LON

    print("latitude: " + lat + " longitude: " + lon)

    # reduce to 2 decimal places
    roundedLat = round_to_two_decimals(float(lat))
    roundedLon = round_to_two_decimals(float(lon))

    return roundedLat, roundedLon

def main(config):
    location = config.get("location", "")
    lat, lon = parse_location(location)

    api_key = config.get("shipping_forecast_api_key")

    if api_key != None:
        url = FORECAST_URL + "?lat=" + str(lat) + "&lon=" + str(lon)
        headers = {"authorization": "Bearer " + api_key}
        rep = http.get(url, headers = headers, ttl_seconds = 1200)
        if rep.status_code == 200:
            print("got forecast")
            forecast = rep.json()["forecast"]
        else:
            print("request failed with status %d, using default forecast", rep.status_code)
            forecast = DEFAULT_FORECAST
    else:
        print("no api key, using default forecast")
        forecast = DEFAULT_FORECAST

    return render.Root(
        delay = 140,
        child = render.Box(
            render.Row(
                main_align = "space_between",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Animation(
                        children = [
                            render.Image(src = LH1_ICON),
                            render.Image(src = LH1_ICON),
                            render.Image(src = LH2_ICON),
                            render.Image(src = LH2_ICON),
                            render.Image(src = LH3_ICON),
                            render.Image(src = LH3_ICON),
                            render.Image(src = LH4_ICON),
                            render.Image(src = LH4_ICON),
                            render.Image(src = LH5_ICON),
                            render.Image(src = LH5_ICON),
                            render.Image(src = LH4_ICON),
                            render.Image(src = LH4_ICON),
                            render.Image(src = LH3_ICON),
                            render.Image(src = LH3_ICON),
                            render.Image(src = LH2_ICON),
                            render.Image(src = LH2_ICON),
                        ],
                    ),
                    render.Marquee(
                        child = render.WrappedText(
                            content = forecast,
                            color = "#fff",
                            width = 49,
                            font = "tom-thumb",
                        ),
                        height = 32,
                        scroll_direction = "vertical",
                        align = "center",
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "shipping_forecast_api_key",
                name = "Shipping Forecast API Key",
                desc = "Your Shipping Forecast API key. See https://weather.lmbrn.ca/ for details.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "location",
                name = "Location",
                desc = "The forecast location's coordinates in decimal degrees (latitude, longitude). For example: 57.59, -13.69",
                icon = "compass",
            ),
        ],
    )
