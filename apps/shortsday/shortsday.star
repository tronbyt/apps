load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "zip_code",
                name = "ZIP code",
                icon = "locationDot",
                desc = "US ZIP code for today's forecast",
                default = "10001",
            ),
            schema.Text(
                id = "threshold_f",
                name = "Shorts temperature",
                icon = "temperatureHigh",
                desc = "Temperature in Fahrenheit at or above which it is a shorts day",
                default = "80",
            ),
        ],
    )

def _fail(msg):
    fail("shortsday: " + msg)

def _get_lat_lon(zip_code):
    geo_url = "https://geocoding-api.open-meteo.com/v1/search?name=%s&count=1&language=en&format=json" % zip_code
    geo_resp = http.get(geo_url, ttl_seconds = 86400)

    if geo_resp.status_code != 200:
        _fail("geocoding request failed: %d" % geo_resp.status_code)

    geo_data = json.decode(geo_resp.body())
    results = geo_data.get("results", [])

    if len(results) == 0:
        _fail("could not find ZIP code: %s" % zip_code)

    place = results[0]
    return (place["latitude"], place["longitude"])

def _get_today_high_f(lat, lon):
    weather_url = "https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&daily=temperature_2m_max&temperature_unit=fahrenheit&forecast_days=1&timezone=auto" % (lat, lon)
    weather_resp = http.get(weather_url, ttl_seconds = 1800)

    if weather_resp.status_code != 200:
        _fail("forecast request failed: %d" % weather_resp.status_code)

    weather_data = json.decode(weather_resp.body())
    daily = weather_data.get("daily", None)

    if daily == None:
        _fail("missing daily forecast data")

    highs = daily.get("temperature_2m_max", [])

    if len(highs) == 0:
        _fail("missing daily high temperature")

    return highs[0]

def _answer_text(is_shorts_day):
    if is_shorts_day:
        return "Yes"
    return "No"

def _threshold_text(value):
    if value == "":
        _fail("threshold_f is required")

    return int(value)

def main(config):
    zip_code = config.get("zip_code", "10001").strip()
    threshold_f = _threshold_text(config.get("threshold_f", "80").strip())

    if zip_code == "":
        _fail("ZIP code is required")

    lat, lon = _get_lat_lon(zip_code)
    high_f = _get_today_high_f(lat, lon)
    answer = _answer_text(high_f >= threshold_f)
    temp_text = "%dF" % int(high_f + 0.5)

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(
                    "Shorts day?",
                    font = "tb-8",
                    color = "#FFFFFF",
                ),
                render.Text(
                    answer,
                    font = "tb-8",
                    color = "#FFFFFF",
                ),
                render.Text(
                    temp_text,
                    font = "tb-8",
                    color = "#FFFFFF",
                ),
            ],
        ),
    )
