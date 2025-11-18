"""
Applet: AirNowAQI
Summary: Air Now AQI
Description: Displays the current AQI value and level by location using data provided by AirNow.gov.
Author: mjc-gh
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "canvas", "render")
load("schema.star", "schema")

# original tidbyt api key
DEFAULT_API_KEY = "EAC9C956-3EDE-4955-A5BE-53492091A0DE"
ACCURACY = "#.###"

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

def get_alert_colors(category_num):
    if category_num == 1:
        return ("#009966", "#FFF")
    elif category_num == 2:
        return ("#ffde33", "#000")
    elif category_num == 3:
        return ("#ff9933", "#000")
    elif category_num == 4:
        return ("#cc0033", "#FFF")
    elif category_num == 5:
        return ("#660099", "#FFF")
    else:
        return ("#7e0023", "#FFF")

def get_current_observation_url(api_key, lat, lng):
    return "https://www.airnowapi.org/aq/forecast/latLong/?format=application/json&latitude={lat}&longitude={lng}&api_key={api_key}".format(
        lat = lat,
        lng = lng,
        api_key = api_key,
    )

def get_current_observation(api_key, lat, lng):
    response = http.get(url = get_current_observation_url(api_key, lat, lng), ttl_seconds = 30 * 60)
    if response.status_code != 200:
        fail("HTTP request failed with status %d" % response.status_code)

    data = response.json()

    for obj in data:
        if obj["ParameterName"] == "PM2.5":
            return obj

    return None

def render_alert_circle(aqi, alert_colors):
    scale = 2 if canvas.is2x() else 1

    bg_color, txt_color = alert_colors
    font = "terminus-32" if scale == 2 else "10x20"

    if aqi > 99:
        font = "terminus-28" if scale == 2 else "6x13"

    return render.Box(
        width = 26 * scale,
        height = 32 * scale,
        padding = 1 * scale,
        child = render.Circle(
            color = bg_color,
            diameter = 24 * scale,
            child = render.Text("%d" % (aqi), font = font, color = txt_color),
        ),
    )

def render_category_text(category_name, reporting_area, alert_colors):
    scale = 2 if canvas.is2x() else 1

    bg_color, _ = alert_colors
    font = "terminus-14" if scale == 2 else "tom-thumb"

    if category_name == "Unhealthy for Sensitive Groups":
        category_name = "Unhealthy for Sensitive"

    return render.Box(
        width = 38 * scale,
        height = 32 * scale,
        child = render.Column(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = [
                render.WrappedText(
                    category_name,
                    align = "center",
                    color = bg_color,
                    font = font,
                ),
                render.Marquee(
                    width = 30 * scale,
                    offset_start = 30 * scale,
                    offset_end = 30 * scale,
                    child = render.Text(
                        reporting_area,
                        color = "#DDD",
                        font = font,
                    ),
                ),
            ],
        ),
    )

def main(config):
    location = json.decode(config.get("location", DEFAULT_LOCATION))
    api_key = config.get("api_key", DEFAULT_API_KEY)
    hide_below = config.get("hide_below", "0")

    lat = humanize.float(ACCURACY, float(location["lat"]))
    lng = humanize.float(ACCURACY, float(location["lng"]))

    observation = get_current_observation(api_key, lat, lng)
    if not observation:
        return render.Root(
            child = render.Box(
                child = render.WrappedText(
                    content = "No PM2.5 data for this location",
                    width = canvas.width(),
                    align = "center",
                    color = "#f66",
                ),
            ),
        )

    category_num = observation["Category"]["Number"]
    category_name = observation["Category"]["Name"]
    reporting_area = observation["ReportingArea"]
    aqi = observation["AQI"]

    if category_num < int(hide_below):
        return []

    alert_colors = get_alert_colors(category_num)

    return render.Root(
        delay = 25 if canvas.is2x() else 50,
        child = render.Row(
            main_align = "start",
            expanded = True,
            children = [
                render_alert_circle(aqi, alert_colors),
                render_category_text(category_name, reporting_area, alert_colors),
            ],
        ),
    )

def get_schema():
    hide_options = [
        schema.Option(
            display = "Always Show",
            value = "0",
        ),
        schema.Option(
            display = "Moderate (100)",
            value = "2",
        ),
        schema.Option(
            display = "Unhealthy for Sensitive Groups (150)",
            value = "3",
        ),
        schema.Option(
            display = "Unhealthy (200)",
            value = "4",
        ),
        schema.Option(
            display = "Very Unhealthy (300)",
            value = "5",
        ),
        schema.Option(
            display = "Hazardous (500)",
            value = "6",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display weather radar.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "API Key, freely available at airnowapi.org",
                icon = "key",
                secret = True,
            ),
            schema.Dropdown(
                id = "hide_below",
                name = "Hide Below",
                desc = "Hide this app if the AQI is below the chosen value.",
                icon = "eye",
                default = hide_options[0].value,
                options = hide_options,
            ),
        ],
    )
