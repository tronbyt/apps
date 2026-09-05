"""
Applet: Water Boiling Point
Summary: Boiling point of H2O by location
Desc: Displays the current boiling point of water given the set location's ground level air pressure. You can get a free OpenWeather API key at https://home.openweathermap.org/users/sign_up.
Author: frame-shift
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/boil_16x32.gif", boil_img = "file")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")

# Default settings
DEFAULT_UNIT = "C"
DEFAULT_API_KEY = None
DEFAULT_LOCATION = None

# API settings
REFRESH_RATE = 3600  # 1 hour
OW_URL = "https://api.openweathermap.org/data/2.5/weather"

# Valid parameters
VALID_UNITS = ["K", "C", "F"]
VALID_NUMS = ["int", "float"]

def main(config):
    """Display the current boiling point of water for the configured location.

    Args:
        config: A schema config dict containing the API key, location, and unit preference.

    Returns:
        A render.Root object displaying the boiling point, or an error display on failure.
    """
    air_pressure = get_air_pressure(config)

    if type(air_pressure) not in VALID_NUMS:
        return air_pressure

    unit = config.get("unit", DEFAULT_UNIT)
    bp = calc_boiling_point(air_pressure, unit)
    unit_suffix = unit if unit == "K" else "°" + unit
    bp_text = str(bp) + " " + unit_suffix

    scale = 2 if canvas.is2x() else 1
    font = "terminus-16" if canvas.is2x() else "tb-8"

    return render.Root(
        child = render.Row(
            expanded = True,
            children = [
                render.Image(
                    src = boil_img.readall(),
                    width = 16 * scale,
                    height = 32 * scale,
                ),
                render.Box(
                    child = render.Text(
                        content = bp_text,
                        font = font,
                        color = "#BEE8F6",
                    ),
                ),
            ],
        ),
    )

def round_n(n):
    """Round a number to two decimal places.

    Args:
        n: An int or float to round.

    Returns:
        The rounded value as an int when the fractional part is zero, otherwise a float.
    """
    if type(n) not in VALID_NUMS:
        print("round_n requires n to be an int or float")
        return None

    rounded = math.round(n * 100) / 100

    if str(rounded).endswith(".0"):
        rounded = int(rounded)

    return rounded

def get_air_pressure(config):
    """Fetch the local ground air pressure for the configured location.

    Args:
        config: A schema config dict containing the OpenWeather API key and a
            JSON-encoded location object with "lat" and "lng" values.

    Returns:
        An int air pressure value in hPa when the API request succeeds, or a
        render.Root error display if configuration or the API request fails.
    """
    api_key = config.get("api_key", DEFAULT_API_KEY)
    location = config.get("location", DEFAULT_LOCATION)

    if api_key == None or api_key == "":
        print("get_air_pressure requires config to have a valid OpenWeather API key")
        print("Free plan is available at https://home.openweathermap.org/users/sign_up")
        return render_error("Missing valid API key in config")
    if location == None:
        print("get_air_pressure requires config to have location set")
        return render_error("Missing location in config")

    location = json.decode(location)
    query = OW_URL + "?lat=%s&lon=%s&appid=%s" % (location["lat"], location["lng"], api_key)
    resp = http.get(url = query, ttl_seconds = REFRESH_RATE)

    if resp.status_code != 200:
        print("OpenWeather request failed with status %s", str(resp.status_code))
        return render_error("OpenWeather API not reachable")

    decoded = resp.json()

    if "main" not in decoded:
        print("get_air_pressure cannot find 'main' in OpenWeather data")
        return render_error("Cannot decode OpenWeather data")
    if "grnd_level" not in decoded["main"]:
        print("get_air_pressure cannot find 'grnd_level' in OpenWeather data")
        return render_error("Cannot decode OpenWeather data")

    grnd_level = decoded["main"]["grnd_level"]

    if type(grnd_level) not in VALID_NUMS or grnd_level <= 0:
        print("get_air_pressure received an invalid 'grnd_level' in OpenWeather data")
        return render_error("Cannot decode OpenWeather data")

    return int(grnd_level)

def convert_temp(temp, unit):
    """Convert temperature between different units (Kelvin, Celsius, Fahrenheit).

    Args:
        temp: The numeric temperature value to convert.
        unit: The input temperature unit ('K', 'C', or 'F').

    Returns:
        A dict with keys 'K', 'C', 'F' containing the temperature in each unit,
        or None if inputs are invalid.
    """
    if type(temp) not in VALID_NUMS:
        print("convert_temp requires temp to be an int or float")
        return None
    if unit not in VALID_UNITS:
        print("convert_temp requires unit to be one of 'K', 'C', or 'F'")
        return None

    if unit == "K":
        k_deg = temp
        c_deg = k_deg - 273.15
        f_deg = (1.8 * c_deg) + 32
    elif unit == "C":
        c_deg = temp
        k_deg = c_deg + 273.15
        f_deg = (1.8 * c_deg) + 32
    else:
        f_deg = temp
        c_deg = (f_deg - 32) / 1.8
        k_deg = c_deg + 273.15

    ts = [round_n(t) for t in [k_deg, c_deg, f_deg]]

    return {"K": ts[0], "C": ts[1], "F": ts[2]}

def calc_boiling_point(p, unit):
    """Calculate the boiling point of water given air pressure using the Antoine equation.

    Args:
        p: Air pressure in hPa (hectopascals).
        unit: Desired temperature unit for the result ('K', 'C', or 'F').

    Returns:
        The boiling point temperature as a float in the specified unit,
        or None if inputs are invalid.
    """
    if type(p) not in VALID_NUMS or p <= 0:
        print("calc_boiling_point requires p to be a positive int or float")
        return None
    if unit not in VALID_UNITS:
        print("calc_boiling_point requires unit to be one of 'K', 'C', or 'F'")
        return None

    # Constants for the Antoine equation for water (in °C, mmHg)
    # Source: https://en.wikipedia.org/wiki/Antoine_equation#Example_parameters
    a = 8.07131
    b = 1730.63
    c = 233.426

    p_mmhg = p * 0.750061683  # Air pressure from OpenWeather is in hPa; this converts it to mmHg
    q = math.log(p_mmhg, 10)

    boil_c = (b / (a - q)) - c
    boil_temps = convert_temp(boil_c, "C")

    return boil_temps[unit]

def render_error(code):
    """Render error display with error code message.

    Args:
        code: A string containing the error code or message to display

    Returns:
        A render.Root object displaying the error message with magenta formatting
    """
    scale = 2 if canvas.is2x() else 1
    font = "terminus-14" if canvas.is2x() else "tom-thumb"
    width, _ = canvas.size()

    return render.Root(
        render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.WrappedText(
                    color = "#ff00ff",
                    content = "WATER BOILING POINT ERROR",
                    font = font,
                    align = "center",
                ),
                render.Box(
                    width = width,
                    height = 1 * scale,
                    color = "#ff00ff",
                ),
                render.Box(
                    width = width,
                    height = 1 * scale,
                    color = "#000",
                ),
                render.WrappedText(
                    content = code,
                    font = font,
                    align = "center",
                ),
            ],
        ),
    )

def get_schema():
    unit_options = [
        schema.Option(
            display = "Celsius (°C)",
            value = "C",
        ),
        schema.Option(
            display = "Fahrenheit (°F)",
            value = "F",
        ),
        schema.Option(
            display = "Kelvin (K)",
            value = "K",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "OpenWeather API Key",
                desc = "Enter your OpenWeather API key",
                icon = "key",
                secret = True,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                icon = "locationDot",
                desc = "Set your location",
            ),
            schema.Dropdown(
                id = "unit",
                name = "Units",
                desc = "Select the temperature unit to display",
                icon = "temperatureHalf",
                default = DEFAULT_UNIT,
                options = unit_options,
            ),
        ],
    )
