"""
Applet: NWS Live Forecast
Summary: Weather forecast from NWS
Description:  National Weather Service data showing the current temperature and weather forecast for today and tomorrow.
Author: Andrey Goder
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/cloudy.png", CLOUDY_ASSET = "file")
load("images/fog.png", FOG_ASSET = "file")
load("images/partly_sunny.png", PARTLY_SUNNY_ASSET = "file")
load("images/rainy.png", RAINY_ASSET = "file")
load("images/snowy.png", SNOWY_ASSET = "file")
load("images/stormy.png", STORMY_ASSET = "file")
load("images/sunny.png", SUNNY_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CLOUDY = CLOUDY_ASSET.readall()
FOG = FOG_ASSET.readall()
PARTLY_SUNNY = PARTLY_SUNNY_ASSET.readall()
RAINY = RAINY_ASSET.readall()
SNOWY = SNOWY_ASSET.readall()
STORMY = STORMY_ASSET.readall()
SUNNY = SUNNY_ASSET.readall()

# Free API from National Weather Service
WEATHER_URL = "https://api.weather.gov/points/"

# This is how many fit comfortaly on the screen
MAX_DAYS_TO_SHOW = 3

DEFAULT_UNITS = "F"

DEFAULT_LOCATION = """
{
  "lat": "37.27",
  "lng": "-121.9272",
  "timezone": "America/Los_Angeles"
}
"""

DAY_LABELS = [
    "Sun",
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat",
    "Sun",
]

def main(config):
    # Config
    location = json.decode(config.get("location") or DEFAULT_LOCATION)
    units = config.get("units") or DEFAULT_UNITS

    response = http.get(WEATHER_URL + str(location["lat"]) + "," + str(location["lng"]), ttl_seconds = 300)
    if response.status_code != 200:
        fail("failed to fetch weather %d", response.status_code)

    forecast = http.get(response.json()["properties"]["forecastHourly"], ttl_seconds = 300)
    if forecast.status_code != 200:
        fail("failed to fetch forecast %d", forecast.status_code)

    periods = forecast.json()["properties"]["periods"]
    now = time.now()

    days = []
    rightNow = None
    prevDay = None
    for period in periods:
        if rightNow == None and time.parse_time(period["endTime"]) > now:
            rightNow = period
        day = time.parse_time(period["startTime"]).format("2006-01-02")
        if prevDay == None or day != prevDay:
            days.append([])
            prevDay = day
        days[len(days) - 1].append(period)

    if units == "C":
        nowTemp = int(math.round(convert_fahrenheit_to_celsius(rightNow["temperature"])))
    elif units == "K":
        nowTemp = int(math.round(convert_fahrenheit_to_kelvin(rightNow["temperature"])))
    else:
        nowTemp = int(math.round(rightNow["temperature"]))

    cols = [render.Column(
        cross_align = "center",
        children = [
            render.Text("Now"),
            render.Image(src = get_icon(rightNow["shortForecast"])),
            render.Text(" %d\u00B0" % nowTemp),
        ],
    )]

    for day in days:
        if len(cols) >= MAX_DAYS_TO_SHOW:
            break
        dayStart = time.parse_time(day[0]["startTime"])
        if units == "C":
            temps = [convert_fahrenheit_to_celsius(p["temperature"]) for p in day]
        elif units == "K":
            temps = [convert_fahrenheit_to_kelvin(p["temperature"]) for p in day]
        else:
            temps = [p["temperature"] for p in day]

        high = int(math.round(max(temps)))
        forecast = mode([p["shortForecast"] for p in day])

        if dayStart < now:
            # Only show today's temp if it's higher, e.g. in the morning
            if high <= nowTemp:
                continue
            label = "Today"
        else:
            label = DAY_LABELS[humanize.day_of_week(dayStart)]

        cols.append(render.Column(
            cross_align = "center",
            children = [
                render.Text(label),
                render.Image(src = get_icon(forecast)),
                render.Text(" %d\u00B0" % high),
            ],
        ))

    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = cols,
        ),
    )

def convert_fahrenheit_to_celsius(temperature):
    return (temperature - 32) / 1.8

def convert_fahrenheit_to_kelvin(temperature):
    return (temperature + 459.67) / 1.8

def mode(lst):
    count = {}
    for item in lst:
        if item not in count:
            count[item] = 0
        count[item] += 1
    m = 0
    mitem = None
    for item in count:
        if count[item] > m:
            m = count[item]
            mitem = item
    return mitem

def get_icon(fc):
    if fc == "Partly Sunny" or fc == "Partly Cloudy":
        return PARTLY_SUNNY
    if fc.find("Sunny") >= 0 or fc == "Clear":
        return SUNNY
    if fc.find("Cloudy") >= 0:
        return CLOUDY
    if fc.find("Fog") >= 0 or fc.find("Haze") >= 0:
        return FOG
    if fc.find("Rain") >= 0:
        return RAINY
    if fc.find("Snow") >= 0 or fc.find("Frost"):
        return SNOWY
    if fc.find("storm") >= 0:
        return STORMY
    return SUNNY  # not ideal as the default

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display weather data.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "units",
                name = "Units",
                desc = "Units to display temperature in, either Fahrenheit, Celsius, or Kelvin.",
                default = DEFAULT_UNITS,
                icon = "calendar",
                options = [
                    schema.Option(display = "Fahrenheit", value = "F"),
                    schema.Option(display = "Celsius", value = "C"),
                    schema.Option(display = "Kelvin", value = "K"),
                ],
            ),
        ],
    )

# Weather icons from https://www.flaticon.com/free-icons/weather
# (free with attribution)
