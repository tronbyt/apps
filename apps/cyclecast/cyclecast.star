"""
Applet: CycleCast
Summary: Weather Data for Cyclists
Description: Displays weather data important for cyclists.
Author: Robert Ison
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/cloud_icon.png", CLOUD_ICON_ASSET = "file")
load("images/directional_arrow.png", DIRECTIONAL_ARROW_ASSET = "file")
load("images/flag_base.png", FLAG_BASE_ASSET = "file")
load("images/rain_icon.png", RAIN_ICON_ASSET = "file")
load("images/sun_icon.png", SUN_ICON_ASSET = "file")
load("images/windrose_icon.png", WINDROSE_ICON_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("sunrise.star", "sunrise")
load("time.star", "time")
load("images/img_3f786ec0.png", IMG_3f786ec0_ASSET = "file")
load("images/img_4072ddf6.png", IMG_4072ddf6_ASSET = "file")
load("images/img_4227b260.png", IMG_4227b260_ASSET = "file")
load("images/img_744d8f83.png", IMG_744d8f83_ASSET = "file")
load("images/img_9a2cfc00.png", IMG_9a2cfc00_ASSET = "file")
load("images/img_a2afcb9f.png", IMG_a2afcb9f_ASSET = "file")
load("images/img_a61fcf56.png", IMG_a61fcf56_ASSET = "file")
load("images/img_ca8077db.png", IMG_ca8077db_ASSET = "file")
load("images/img_ca864a35.png", IMG_ca864a35_ASSET = "file")
load("images/img_caafdcbd.png", IMG_caafdcbd_ASSET = "file")
load("images/img_e19e6f1f.png", IMG_e19e6f1f_ASSET = "file")
load("images/img_e2d03193.png", IMG_e2d03193_ASSET = "file")
load("images/img_f149c019.png", IMG_f149c019_ASSET = "file")

CLOUD_ICON = CLOUD_ICON_ASSET.readall()
DIRECTIONAL_ARROW = DIRECTIONAL_ARROW_ASSET.readall()
FLAG_BASE = FLAG_BASE_ASSET.readall()
RAIN_ICON = RAIN_ICON_ASSET.readall()
SUN_ICON = SUN_ICON_ASSET.readall()
WINDROSE_ICON = WINDROSE_ICON_ASSET.readall()

SAMPLE_DATA = """{"latitude":28.375,"longitude":81.25,"generationtime_ms":0.091552734375,"utc_offset_seconds":-14400,"timezone":"America/New_York","timezone_abbreviation":"GMT-4","elevation":167.0,"hourly_units":{"time":"iso8601","temperature_2m":"°F","wind_speed_10m":"mp/h","rain":"mm","wind_gusts_10m":"mp/h","uv_index":"","showers":"mm","apparent_temperature":"°F","precipitation_probability":"%","relative_humidity_2m":"%","cloud_cover":"%"},"hourly":{"time":["2025-04-14T00:00","2025-04-14T01:00","2025-04-14T02:00","2025-04-14T03:00","2025-04-14T04:00","2025-04-14T05:00","2025-04-14T06:00","2025-04-14T07:00","2025-04-14T08:00","2025-04-14T09:00","2025-04-14T10:00","2025-04-14T11:00","2025-04-14T12:00","2025-04-14T13:00","2025-04-14T14:00","2025-04-14T15:00","2025-04-14T16:00","2025-04-14T17:00","2025-04-14T18:00","2025-04-14T19:00","2025-04-14T20:00","2025-04-14T21:00","2025-04-14T22:00","2025-04-14T23:00"],"temperature_2m":[84.8,87.9,90.7,93.1,94.6,95.1,94.7,93.4,91.5,87.2,83.9,82.0,79.0,77.8,76.9,76.2,75.6,75.0,74.4,74.2,73.8,74.4,78.6,83.2],"wind_speed_10m":[3.8,5.9,6.0,6.2,6.0,6.4,6.1,5.8,5.4,3.8,2.2,2.4,3.5,3.8,3.3,3.0,2.5,2.2,2.1,1.8,1.3,0.9,0.4,0.3],"rain":[0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00],"wind_gusts_10m":[9.2,12.8,13.2,13.6,13.2,13.6,13.6,12.8,12.1,10.7,6.9,3.8,6.0,6.9,6.7,5.8,5.1,4.0,3.8,3.6,2.7,1.8,1.6,2.0],"uv_index":[4.55,6.15,7.30,7.75,7.45,6.40,4.85,3.00,1.35,0.25,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.10,1.00,2.70],"showers":[0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00],"apparent_temperature":[88.4,92.0,95.6,97.3,97.9,97.4,95.4,93.7,92.0,89.2,86.9,85.2,81.9,80.5,80.0,79.7,79.2,78.8,78.3,78.3,78.4,79.5,84.5,88.3],"precipitation_probability":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"relative_humidity_2m":[47,41,37,32,29,28,29,31,33,41,47,51,57,59,62,64,65,67,68,70,72,72,66,53],"cloud_cover":[0,0,0,0,5,2,9,31,20,0,9,54,51,38,0,50,44,56,65,84,81,71,54,52]},"daily_units":{"time":"iso8601","sunrise":"iso8601","sunset":"iso8601"},"daily":{"time":["2025-04-14"],"sunrise":["2025-04-13T20:10"],"sunset":["2025-04-14T08:59"]}}"""
DEFAULT_LOCATION = """{"lat": "28.53933",	"lng": "-81.38325",	"description": "Orlando, FL, USA",	"locality": "Orlando",	"place_id": "???",	"timezone": "America/New_York"}"""
API_URL = "https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&daily=sunrise,sunset&hourly=wind_direction_10m,temperature_2m,wind_speed_10m,rain,wind_gusts_10m,uv_index,showers,apparent_temperature,precipitation_probability,relative_humidity_2m,cloud_cover&timezone=%s&forecast_days=1&wind_speed_unit=mph&temperature_unit=fahrenheit"
CACHE_NAME = "%s_%s_CycleCast_Cache_%s"

#Weather Icons

WINDSOCKS = {
    "1": IMG_a61fcf56_ASSET.readall(),
    "2": IMG_e2d03193_ASSET.readall(),
    "3": IMG_9a2cfc00_ASSET.readall(),
    "4": IMG_4227b260_ASSET.readall(),
    "5": IMG_e19e6f1f_ASSET.readall(),
}

MOON_ICONS = {
    "0": IMG_caafdcbd_ASSET.readall(),
    "1": IMG_4072ddf6_ASSET.readall(),
    "2": IMG_3f786ec0_ASSET.readall(),
    "3": IMG_ca864a35_ASSET.readall(),
    "4": IMG_ca8077db_ASSET.readall(),
    "5": IMG_a2afcb9f_ASSET.readall(),
    "6": IMG_744d8f83_ASSET.readall(),
    "7": IMG_f149c019_ASSET.readall(),
}

# Parameters for Setting Options
scroll_speed_options = [
    schema.Option(
        display = "Slow Scroll",
        value = "60",
    ),
    schema.Option(
        display = "Medium Scroll",
        value = "45",
    ),
    schema.Option(
        display = "Fast Scroll",
        value = "30",
    ),
]

def round(num, precision):
    return math.round(num * math.pow(10, precision)) / math.pow(10, precision)

def seconds_remaining_in_day(timezone):
    # Get the current time
    current_time = time.now().in_location(timezone)

    # Extract the hour, minute, and second components of the current time
    hour = current_time.hour
    minute = current_time.minute
    second = current_time.second

    # Calculate the seconds elapsed today
    elapsed_seconds = hour * 3600 + minute * 60 + second

    # Total seconds in a day (24 hours)
    total_seconds_in_day = 86400

    # Calculate the remaining seconds in the day
    remaining_seconds = total_seconds_in_day - elapsed_seconds

    return remaining_seconds

def get_weather_data(latitude, longitude, timezone):
    local_cache_name = CACHE_NAME % (latitude, longitude, timezone)
    local_api_url = API_URL % (latitude, longitude, timezone)

    local_weather_data = cache.get(local_cache_name)

    # We need to make sure we don't keep this dataset past the end of the day, but we also want to clear it a little more often to
    # get updated data. So we'll set a max cache in seconds
    max_cache_in_seconds = 10800  #3 Hours

    seconds_xml_valid_for = seconds_remaining_in_day(timezone)

    if seconds_xml_valid_for > max_cache_in_seconds:
        seconds_xml_valid_for = max_cache_in_seconds

    if local_weather_data == None:
        # print("New Data")
        response = http.get(local_api_url, ttl_seconds = seconds_xml_valid_for)

        if response.status_code != 200:
            fail("request to %s failed with status code: %d - %s" % (local_api_url, response.status_code, response.body()))
        else:
            local_weather_data = response.json()
            cache.set(local_cache_name, json.encode(local_weather_data), ttl_seconds = seconds_xml_valid_for)
    else:
        # print("From Cache")
        local_weather_data = json.decode(local_weather_data)

    return local_weather_data

def get_two_digit_string(number):
    if (number >= 10):
        return number
    else:
        return "0%s" % number

def get_current_condition(data, element, item_name, add_units = True):
    if add_units:
        units = data["hourly_units"][item_name]
        display_tempate = "%s%s" if units == "mm" or units == "%" or units == "°F" else "%s %s"

        return display_tempate % (data["hourly"][item_name][element], units)
    else:
        return data["hourly"][item_name][element]

def to_hex(n):
    """Converts an integer (0-255) to a two-character hex string."""
    hex_chars = "0123456789ABCDEF"
    return hex_chars[n // 16] + hex_chars[n % 16]

def most_contrasting_color(hex_color):
    """Returns the most contrasting color by inverting the input color."""
    hex_color = hex_color.lstrip("#")
    r = int(hex_color[0:2], 16)
    g = int(hex_color[2:4], 16)
    b = int(hex_color[4:6], 16)

    # Invert colors
    inverted_r = 255 - r
    inverted_g = 255 - g
    inverted_b = 255 - b

    # Convert back to hex
    return "#" + to_hex(inverted_r) + to_hex(inverted_g) + to_hex(inverted_b)

def luminance(r, g, b):
    """Calculates the relative luminance of an RGB color."""
    return (0.299 * r + 0.587 * g + 0.114 * b)

def best_contrast_color(hex_color):
    """Returns black (#000000) or white (#FFFFFF) based on the best contrast."""
    hex_color = hex_color.lstrip("#")
    r = int(hex_color[:2], 16)
    g = int(hex_color[2:4], 16)
    b = int(hex_color[4:6], 16)

    # Determine luminance and choose contrast color
    if luminance(r, g, b) > 128:
        return "#000000"  # Dark text for light backgrounds
    else:
        return "#FFFFFF"  # Light text for dark backgrounds

def get_uv_index_category(index, color = False):
    index = float(index)

    # Define thresholds and corresponding values
    thresholds = [2, 5, 7, 10]
    colors = ["#8FC93A", "#FFD700", "#FF8C00", "#FF4500", "#800080"]
    labels = ["Low", "Moderate", "High", "Very High", "Extreme"]

    # Select appropriate category
    for i, threshold in enumerate(thresholds):
        if index <= threshold:
            return colors[i] if color else labels[i]

    return colors[-1] if color else labels[-1]  # Highest category if above all thresholds

def get_temperature_color_code(index):
    index = float(index)

    # Define thresholds and corresponding color codes
    thresholds = [32, 50, 65, 75, 85, 95]
    colors = ["#00A8E8", "#66D3FA", "#5BC8AC", "#8FC93A", "#FFD700", "#FF8C00", "#D62828"]

    # Find the correct color
    for i, threshold in enumerate(thresholds):
        if index <= threshold:
            return colors[i]

    return colors[-1]  # Return highest category if above all thresholds

def get_humidity_color_code(index):
    index = float(index)

    # Define thresholds and corresponding color codes
    thresholds = [20, 40, 60, 75, 85, 95]
    colors = ["#FF4500", "#FF8C00", "#FFD700", "#8FC93A", "#5BC8AC", "#66D3FA", "#00A8E8"]

    # Find the correct color
    for i, threshold in enumerate(thresholds):
        if index <= threshold:
            return colors[i]

    return colors[-1]  # Return highest category if above all threshold

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )

    return padded_element

def get_information_marquee(message):
    marquee = render.Marquee(
        width = 64,
        child = render.Text(message, color = "#ffff00", font = "CG-pixel-3x5-mono"),
    )

    return marquee

def moon_phase(year, month, day, show_description = True):
    # Constants for improved accuracy
    known_new_moon_julian = 2451550.1  # Julian date for January 6, 2000
    synodic_month = 29.53058867  # Average length of a lunar month in days

    # Convert the current date to Julian date
    julian_date = calculate_julian_date(year, month, day)

    # Calculate days since the known new moon
    days_since_new_moon = julian_date - known_new_moon_julian

    # Determine the phase of the moon as a fraction of the synodic month
    phase = days_since_new_moon % synodic_month
    phase = float(phase)

    # Define thresholds with corresponding descriptions and indexes
    phase_map = [
        (1.84566, "New Moon", 0),
        (5.53699, "Waxing Crescent", 1),
        (9.22831, "First Quarter", 2),
        (12.91963, "Waxing Gibbous", 3),
        (16.61096, "Full Moon", 4),
        (20.30228, "Waning Gibbous", 5),
        (23.99361, "Last Quarter", 6),
        (27.68493, "Waning Crescent", 7),
    ]

    # Iterate through the mapped phases
    for threshold, description, index in phase_map:
        if phase < threshold:
            return description if show_description else index

    return "New Moon" if show_description else 0  # Default to "New Moon" or index 0

def calculate_julian_date(year, month, day):
    # Convert Gregorian date to Julian date
    if month <= 2:
        year -= 1
        month += 12

    A = year // 100
    B = 2 - A + (A // 4)
    julian_date = (int(365.25 * (year + 4716)) + int(30.6001 * (month + 1)) + day + B - 1524.5)
    return julian_date

def get_wind_sock_category(wind_speed):
    thresholds = [6.91, 10.36, 13.81, 17.26]

    # Iterate through thresholds and return appropriate category
    for i in range(len(thresholds)):
        if wind_speed <= thresholds[i]:
            return i + 1

    return len(thresholds) + 1  # Highest category if above all thresholds

def get_wind_rose_display(direction):
    #Start and Stop at the correct spot on the windrose
    #Simulate a little variability in the breeze in the windrose by having it move about the correct direction just a little.

    keyframes = []

    keyframes.append(animation.Keyframe(
        percentage = 0.0,
        transforms = [animation.Rotate(direction)],
        curve = "ease_in_out",
    ))

    for i in range(0, 100, 5):
        rotation = direction + ((100 - i) / 100 * 10 * (1 if i % 2 == 0 else -1))
        rotation = 360 if rotation > 360 else rotation

        keyframes.append(
            animation.Keyframe(
                percentage = i / 100,
                transforms = [animation.Rotate(rotation)],
                curve = "ease_in_out",
            ),
        )

    keyframes.append(animation.Keyframe(
        percentage = 1.0,
        transforms = [animation.Rotate(direction)],
        curve = "ease_in_out",
    ))

    return animation.Transformation(
        child = render.Image(src = DIRECTIONAL_ARROW),
        duration = 250,
        delay = 5,
        origin = animation.Origin(0.5, 0.5),
        keyframes = keyframes,
    )

def get_cardinal_position_from_degrees(bearing):
    """ Returns the cardinal position for a given bearing

    Args:
        bearing: in degrees
    Returns:
        The Cardinal position (N, NW, NE, S, SW, SE, E, W)
    """

    if bearing < 0:
        bearing = 360 + bearing

    # have bearning in degrees, now convert to cardinal point
    compass_brackets = ["North", "NNE", "NE", "ENE", "East", "ESE", "SE", "SSE", "South", "SSW", "SW", "WSW", "West", "WNW", "NW", "NNW", "North"]
    display_cardinal_point = compass_brackets[int(math.round(bearing // 22.5))]
    return display_cardinal_point

def display_instructions(config):
    ##############################################################################################################################################################################################################################
    title = "CycleCast by Robert Ison"

    instructions_1 = "CycleCast uses Open Meteo data (open-meteo.com/) to show current conditions for cyclists and outdoor enthusiasts. "
    instructions_2 = "It features a wind rose for direction, a windsock for speed (fluctuating between wind speed and gusts), and sun/moon phases with cloud and rain icons. "
    instructions_3 = "Color-coded boxes indicate UV index, temperature, and humidity—more green means better riding conditions!"

    return render.Root(
        render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    child = render.Text(title, color = "#FF7300", font = "5x8"),
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(instructions_1, color = "#E3D8C5"),
                    offset_start = len(title) * 5,
                ),
                render.Marquee(
                    offset_start = (len(title) + len(instructions_1)) * 5,
                    width = 64,
                    child = render.Text(instructions_2, color = "#8F9779"),
                ),
                render.Marquee(
                    offset_start = (len(title) + len(instructions_2) + len(instructions_1)) * 5,
                    width = 64,
                    child = render.Text(instructions_3, color = "#FF7300"),
                ),
            ],
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def get_animated_windsock(wind, gusts):
    children = []

    for _ in range(1, 3):
        for _ in range(0, 10):
            children.append(render.Image(src = base64.decode(WINDSOCKS[str(get_wind_sock_category(float(wind)))])))

        for j in range(get_wind_sock_category(float(wind)), get_wind_sock_category(float(gusts)) + 1):
            for _ in range(0, 2):
                children.append(render.Image(src = base64.decode(WINDSOCKS[str(j)])))

        for k in range(get_wind_sock_category(float(gusts)), get_wind_sock_category(float(wind)) - 1, -1):
            for _ in range(0, 6):
                children.append(render.Image(src = base64.decode(WINDSOCKS[str(k)])))

    return render.Animation(
        children = children,
    )

def main(config):
    show_instructions = config.bool("instructions", False)
    if show_instructions:
        return display_instructions(config)

    # Get location needed for local weather
    location = json.decode(config.get("location", DEFAULT_LOCATION))

    # Round lat and lng to 1 decimal to make data available to more people (within about 11km x 11km area) and to not give away our users position exactly
    latitude = round(float(location["lat"]), 1)
    longitude = round(float(location["lng"]), 1)
    timezone = location["timezone"]
    current_time = time.now().in_location(timezone)

    # use the real lat and long to get a more accurate sunrise/sunet time. This info isn't shared with anyone but the user
    sunrise_time = sunrise.sunrise(float(location["lat"]), float(location["lng"]), current_time).in_location(location["timezone"])
    sunset_time = sunrise.sunset(float(location["lat"]), float(location["lng"]), current_time).in_location(location["timezone"])

    #Dumb Down the current Time to work with the simpler time format of the API
    simple_current_time = time.parse_time("%s-%s-%sT%s:%s" % (current_time.year, get_two_digit_string(current_time.month), get_two_digit_string(current_time.day), get_two_digit_string(current_time.hour), get_two_digit_string(current_time.minute)), format = "2006-01-02T15:04")
    local_data = get_weather_data(latitude, longitude, timezone)

    # Let's look for the closest entry in 'time' to pull out current conditions
    hour_periods = local_data["hourly"]
    closest_element_to_now = 0
    smallest_difference = 24  #Just need to seed this with a high number (only 24 hours in a day)

    # in the stored data, let's find the closest time period to now
    for i in range(0, len(hour_periods["time"])):
        time_difference = simple_current_time - time.parse_time(hour_periods["time"][i], format = "2006-01-02T15:04")
        if abs(time_difference.hours) < smallest_difference:
            smallest_difference = abs(time_difference.hours)
            closest_element_to_now = i

    # based on the time period, pull out the current conditions
    current_cloud_cover = get_current_condition(local_data, closest_element_to_now, "cloud_cover")
    current_humidity = get_current_condition(local_data, closest_element_to_now, "relative_humidity_2m")
    current_humidity_value = get_current_condition(local_data, closest_element_to_now, "relative_humidity_2m", False)
    current_probability_precipitation = get_current_condition(local_data, closest_element_to_now, "precipitation_probability")
    current_temperature = get_current_condition(local_data, closest_element_to_now, "temperature_2m")
    current_temperature_value = get_current_condition(local_data, closest_element_to_now, "temperature_2m", False)
    current_apparent_temperature = get_current_condition(local_data, closest_element_to_now, "apparent_temperature")
    current_showers = get_current_condition(local_data, closest_element_to_now, "showers")
    current_uv_index = get_current_condition(local_data, closest_element_to_now, "uv_index", False)
    current_wind_gusts = get_current_condition(local_data, closest_element_to_now, "wind_gusts_10m")
    current_wind_gusts_value = get_current_condition(local_data, closest_element_to_now, "wind_gusts_10m", False)
    current_wind = get_current_condition(local_data, closest_element_to_now, "wind_speed_10m")
    current_wind_value = get_current_condition(local_data, closest_element_to_now, "wind_speed_10m", False)

    # current_rain = get_current_condition(local_data, closest_element_to_now, "rain")
    current_wind_direction = get_current_condition(local_data, closest_element_to_now, "wind_direction_10m", False)

    message = "It is %s but feels like %s with cloud cover of %s and humidity of %s. The probability of precipitation is %s, expect %s of rain. The UV index is %s (%s) with winds from the %s at %s gusting to %s." % (current_temperature, current_apparent_temperature, current_cloud_cover, current_humidity, current_probability_precipitation, current_showers, current_uv_index, get_uv_index_category(current_uv_index), get_cardinal_position_from_degrees(current_wind_direction), current_wind, current_wind_gusts)

    display_items = []
    show_info_bar = config.bool("show_info_bar", False)

    if current_time > sunrise_time and current_time < sunset_time:
        # print("Daytime")
        display_items.append(render.Box(width = 64, height = 26 if show_info_bar else 32, color = "#004764"))
        display_items.append(add_padding_to_child_element(render.Image(src = SUN_ICON), 48))
    else:
        # print("NightTime")
        display_items.append(add_padding_to_child_element(render.Image(src = base64.decode(MOON_ICONS[str(moon_phase(current_time.year, current_time.month, current_time.day, False))])), 43, -2))

    #Display Rain if Raining
    if get_current_condition(local_data, closest_element_to_now, "rain", False) > 0:
        display_items.append(add_padding_to_child_element(render.Image(src = RAIN_ICON), 40, 6))
    elif get_current_condition(local_data, closest_element_to_now, "cloud_cover", False) > 15:
        display_items.append(add_padding_to_child_element(render.Image(src = CLOUD_ICON), 40, 6))

    # Display The Windsock
    display_items.append(add_padding_to_child_element(get_animated_windsock(current_wind_value, current_wind_gusts_value), 0))

    # To make room for an info bar if requested, need an offset of height of 5 pixels
    height_offset = 0 if show_info_bar else 5

    # Marquee
    if show_info_bar:
        display_items.append(add_padding_to_child_element(get_information_marquee(message), 0, 27))
    else:
        display_items.append(add_padding_to_child_element(render.Image(src = FLAG_BASE), 0, 24))

    # Wind Direction
    if (get_current_condition(local_data, closest_element_to_now, "wind_speed_10m", False) > 0):
        display_items.append(add_padding_to_child_element(render.Image(src = WINDROSE_ICON), 16, 6 + height_offset))
        display_items.append(add_padding_to_child_element(get_wind_rose_display(current_wind_direction), 16, 6 + height_offset))

    # Initialize Info Box Settings
    info_box_height = 9
    info_box_width = 14

    # UV Index Warning
    display_items.append(add_padding_to_child_element(render.Box(color = get_uv_index_category(current_uv_index, True), height = info_box_height, width = info_box_width), 29, 1))
    display_uv_score = str(int(current_uv_index))
    centering_additional_offet = int((info_box_width - (3 * len(display_uv_score)) - len(display_uv_score)) / 2)
    display_items.append(add_padding_to_child_element(render.Box(color = "#000", height = info_box_height - 4, width = info_box_width - 4), 31, 3))
    display_items.append(add_padding_to_child_element(render.Text(str(int(display_uv_score)), font = "CG-pixel-3x5-mono", color = "#fff"), 29 + centering_additional_offet, 3))

    # Current Temperature
    display_items.append(add_padding_to_child_element(render.Box(color = get_temperature_color_code(current_temperature_value), height = info_box_height, width = info_box_width), 29, 17 + height_offset))
    display_temp = str(int(current_temperature_value))

    # To center the numbers, we need to have an offset based on the number of characters to display
    centering_additional_offet = int((info_box_width - (3 * len(display_temp)) - len(display_temp)) / 2)
    display_items.append(add_padding_to_child_element(render.Box(color = "#000", height = info_box_height - 4, width = info_box_width - 4), 31, 19 + height_offset))
    display_items.append(add_padding_to_child_element(render.Text(str(int(current_temperature_value)), font = "CG-pixel-3x5-mono", color = "#fff"), 29 + centering_additional_offet, 19 + height_offset))

    # Humidity Box
    display_items.append(add_padding_to_child_element(render.Box(color = get_humidity_color_code(current_humidity_value), height = info_box_height, width = info_box_width), 49, 17 + height_offset))
    display_humidity = str(int(current_humidity_value))
    centering_additional_offet = int((info_box_width - (3 * len(display_humidity)) - len(display_humidity)) / 2)
    display_items.append(add_padding_to_child_element(render.Box(color = "#000", height = info_box_height - 4, width = info_box_width - 4), 51, 19 + height_offset))
    display_items.append(add_padding_to_child_element(render.Text(display_humidity, font = "CG-pixel-3x5-mono", color = "#fff"), 49 + centering_additional_offet, 19 + height_offset))

    return render.Root(
        render.Stack(
            children = display_items,
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "instructions",
                name = "Display Instructions",
                desc = "Show instructions on this app when first installing.",
                icon = "book",  #"info",
                default = False,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "The location used for gathering weather data.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "show_info_bar",
                name = "Information Bar",
                desc = "Add an information bar at the bottom that provides more weather info.",
                icon = "gear",
                default = False,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "scroll",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
        ],
    )
