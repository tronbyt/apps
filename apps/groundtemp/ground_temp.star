"""
Applet: Ground Temperature
Summary: Lawn-focused weather conditions
Description: Displays soil temperature with air temperature, humidity, and rainfall metrics.
Author: Codex
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

WEATHER_API_URL = "https://api.open-meteo.com/v1/forecast"

DEFAULT_LOCATION = """
{
  "lat": "40.7128",
  "lng": "-74.0060",
  "locality": "New York",
  "timezone": "America/New_York"
}
"""

DEFAULT_UNITS = "F"
DEFAULT_SOIL_DEPTH = "0cm"

SOIL_VAR_BY_DEPTH = {
    "0cm": "soil_temperature_0cm",
    "6cm": "soil_temperature_6cm",
    "18cm": "soil_temperature_18cm",
}

def main(config):
    location = json.decode(config.get("location") or DEFAULT_LOCATION)
    units = config.get("units") or DEFAULT_UNITS
    soil_depth = config.get("soil_depth") or DEFAULT_SOIL_DEPTH

    temperature_unit = "fahrenheit" if units == "F" else "celsius"
    precipitation_unit = "inch" if units == "F" else "mm"
    degree_unit = "F" if units == "F" else "C"
    precip_unit_symbol = "\"" if units == "F" else ""

    soil_var = SOIL_VAR_BY_DEPTH.get(soil_depth) or "soil_temperature_0cm"

    weather = get_weather(location, soil_var, temperature_unit, precipitation_unit)
    if weather == None:
        return []

    now = time.now().in_location(location.get("timezone") or "UTC")
    next_hour = now + time.parse_duration("1h")
    hour_key = next_hour.format("2006-01-02T15")

    hourly = weather.get("hourly") or {}
    hourly_times = hourly.get("time") or []
    index = find_hour_index(hourly_times, hour_key)

    soil_temp = get_hourly_value(hourly, soil_var, index)
    air_temp = get_hourly_value(hourly, "temperature_2m", index)
    rain_series = hourly.get("rain") or hourly.get("precipitation") or []
    rain_next_6h = sum_hours(rain_series, index, 6)
    rain_next_12h = sum_hours(rain_series, index, 12)
    rain_next_24h = sum_hours(rain_series, index, 24)

    # Prefer NWS QPF for US precipitation totals; fallback to Open-Meteo if unavailable.
    nws_precip = get_nws_precip_totals(location, next_hour, units)
    if nws_precip != None:
        rain_next_6h = nws_precip["6"]
        rain_next_12h = nws_precip["12"]
        rain_next_24h = nws_precip["24"]

    soil_value = "%d°%s" % (int(math.round(soil_temp)), degree_unit)
    air_value = "%d°%s" % (int(math.round(air_temp)), degree_unit)
    rain_6h_value = format_rain_short(rain_next_6h)
    rain_12h_value = format_rain_short(rain_next_12h)
    rain_24h_value = format_rain_short(rain_next_24h)

    soil_y = 2
    air_y = 9

    children = [
        render.Box(width = 64, height = 32, color = "#091a13"),
        render.Box(width = 64, height = 2, color = "#123325"),
        render.Padding(
            pad = (1, soil_y, 1, 0),
            child = render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Text("SOIL", color = "#f7ff9e"),
                    render.Text(soil_value, color = "#f7ff9e"),
                ],
            ),
        ),
        render.Padding(
            pad = (1, air_y, 1, 0),
            child = render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Text("AIR", color = "#ffffff"),
                    render.Text(air_value, color = "#ffffff"),
                ],
            ),
        ),
        render.Padding(
            pad = (0, 17, 0, 0),
            child = render.Box(width = 64, height = 15, color = "#123325"),
        ),
        render.Padding(
            pad = (0, 19, 0, 0),
            child = render.Stack(children = [
                render.Padding(
                    pad = (1, 0, 0, 0),
                    child = rain_column("6H", rain_6h_value, precip_unit_symbol),
                ),
                render.Padding(
                    pad = (23, 0, 0, 0),
                    child = rain_column("12H", rain_12h_value, precip_unit_symbol),
                ),
                render.Padding(
                    pad = (45, 0, 0, 0),
                    child = rain_column("24H", rain_24h_value, precip_unit_symbol),
                ),
                render.Padding(
                    pad = (21, 0, 0, 0),
                    child = render.Box(width = 1, height = 10, color = "#2d6f4f"),
                ),
                render.Padding(
                    pad = (43, 0, 0, 0),
                    child = render.Box(width = 1, height = 10, color = "#2d6f4f"),
                ),
            ]),
        ),
    ]

    return render.Root(
        child = render.Stack(
            children = children,
        ),
    )

def get_weather(location, soil_var, temperature_unit, precipitation_unit):
    url = "%s?latitude=%s&longitude=%s&hourly=temperature_2m,relative_humidity_2m,rain,precipitation,%s&daily=precipitation_sum&temperature_unit=%s&precipitation_unit=%s&timezone=auto&forecast_days=8" % (
        WEATHER_API_URL,
        str(location["lat"]),
        str(location["lng"]),
        soil_var,
        temperature_unit,
        precipitation_unit,
    )

    response = http.get(url, ttl_seconds = 900)
    if response.status_code != 200:
        fail("failed to fetch weather %d", response.status_code)
    return response.json()

def get_nws_precip_totals(location, start_time, units):
    points_url = "https://api.weather.gov/points/%s,%s" % (str(location["lat"]), str(location["lng"]))
    points_response = http.get(points_url, headers = nws_headers(), ttl_seconds = 1800)
    if points_response.status_code != 200:
        return None

    points_props = points_response.json().get("properties")
    if points_props == None:
        return None

    grid_url = points_props.get("forecastGridData")
    if grid_url == None:
        return None

    grid_response = http.get(grid_url, headers = nws_headers(), ttl_seconds = 1800)
    if grid_response.status_code != 200:
        return None

    grid_props = grid_response.json().get("properties")
    if grid_props == None:
        return None

    qpf = grid_props.get("quantitativePrecipitation")
    if qpf == None:
        return None
    qpf_values = qpf.get("values") or []
    if len(qpf_values) == 0:
        return None

    source_uom = qpf.get("uom") or "wmoUnit:mm"

    return {
        "6": sum_nws_qpf_window(qpf_values, source_uom, units, start_time, 6),
        "12": sum_nws_qpf_window(qpf_values, source_uom, units, start_time, 12),
        "24": sum_nws_qpf_window(qpf_values, source_uom, units, start_time, 24),
    }

def sum_nws_qpf_window(values, source_uom, target_units, start_time, hours):
    window_end = start_time + time.parse_duration("%dh" % hours)
    total = 0.0

    for entry in values:
        amount = entry.get("value")
        if amount == None:
            continue

        interval = parse_nws_interval(entry.get("validTime") or "")
        if interval == None:
            continue

        interval_start = interval["start"]
        interval_end = interval_start + time.parse_duration("%dh" % interval["hours"])
        overlap_hours = overlap_duration_hours(start_time, window_end, interval_start, interval_end)
        if overlap_hours <= 0:
            continue

        converted = convert_precip_units(amount, source_uom, target_units)
        total += converted * (overlap_hours / float(interval["hours"]))

    return total

def overlap_duration_hours(start_a, end_a, start_b, end_b):
    start_unix = start_a.unix if start_a.unix > start_b.unix else start_b.unix
    end_unix = end_a.unix if end_a.unix < end_b.unix else end_b.unix
    if end_unix <= start_unix:
        return 0
    return (end_unix - start_unix) / 3600.0

def parse_nws_interval(valid_time):
    parts = valid_time.split("/")
    if len(parts) != 2:
        return None

    start = time.parse_time(parts[0])
    hours = parse_iso_duration_hours(parts[1])
    if hours <= 0:
        return None

    return {
        "start": start,
        "hours": hours,
    }

def parse_iso_duration_hours(duration):
    if not duration.startswith("P"):
        return 0

    remain = duration[1:]
    total = 0

    d_idx = remain.find("D")
    if d_idx >= 0:
        day_str = remain[:d_idx]
        if day_str != "":
            total += int(day_str) * 24
        remain = remain[d_idx + 1:]

    if remain.startswith("T"):
        remain = remain[1:]

    h_idx = remain.find("H")
    if h_idx >= 0:
        hour_str = remain[:h_idx]
        if hour_str != "":
            total += int(hour_str)

    return total

def convert_precip_units(value, source_uom, target_units):
    # NWS may report QPF as mm or kg/m^2 (water equivalent). Both map 1:1 to mm depth.
    mm_like = (source_uom == "wmoUnit:mm" or
               source_uom == "wmoUnit:kg.m-2" or
               source_uom == "unit:kg.m-2")

    if mm_like and target_units == "F":
        return value / 25.4
    if source_uom == "wmoUnit:in" and target_units == "C":
        return value * 25.4
    return value

def nws_headers():
    return {
        "User-Agent": "tronbyt-groundtemp/1.0",
        "Accept": "application/geo+json",
    }

def find_hour_index(times, hour_prefix):
    if len(times) == 0:
        return 0

    for i in range(len(times)):
        if str(times[i]).find(hour_prefix) == 0:
            return i

    return 0

def get_hourly_value(hourly_data, key, index):
    values = hourly_data.get(key) or []
    if len(values) == 0:
        return 0

    i = index
    if i < 0:
        i = 0
    if i >= len(values):
        i = len(values) - 1

    return values[i]

def sum_hours(values, start_index, count):
    if len(values) == 0:
        return 0

    start = start_index
    if start < 0:
        start = 0
    if start >= len(values):
        start = len(values) - 1

    end = start + count
    if end > len(values):
        end = len(values)

    total = 0.0
    for i in range(start, end):
        total += values[i]

    return total

def rain_column(label, value, unit_symbol):
    return render.Column(
        main_align = "space_between",
        cross_align = "center",
        children = [
            render.Text(label, color = "#8dd5af", font = "CG-pixel-3x5-mono"),
            render.Box(width = 1, height = 1, color = "#123325"),
            render.Text(value + unit_symbol, color = "#93f7c5", font = "CG-pixel-3x5-mono"),
        ],
    )

def format_rain_short(value):
    rounded = int(math.round(value * 100))
    whole = int(rounded / 100)
    frac = rounded % 100
    if frac < 10:
        return "%d.0%d" % (whole, frac)
    return "%d.%d" % (whole, frac)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location used for your ground and weather readings.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "units",
                name = "Units",
                desc = "Choose Fahrenheit or Celsius.",
                default = DEFAULT_UNITS,
                icon = "temperatureThreeQuarters",
                options = [
                    schema.Option(display = "Fahrenheit", value = "F"),
                    schema.Option(display = "Celsius", value = "C"),
                ],
            ),
            schema.Dropdown(
                id = "soil_depth",
                name = "Soil Depth",
                desc = "Depth used for the ground temperature reading.",
                default = DEFAULT_SOIL_DEPTH,
                icon = "arrowsDownToLine",
                options = [
                    schema.Option(display = "Surface (0in)", value = "0cm"),
                    schema.Option(display = "Root Zone (2in)", value = "6cm"),
                    schema.Option(display = "Deep Soil (7in)", value = "18cm"),
                ],
            ),
        ],
    )
