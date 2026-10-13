"""
Applet: Visible Planets
Summary: Displays visible planets
Description: Displays direction and degrees above the horizon for the selected planet.
Author: Robert Ison
"""

# Notes:
# Fetches all body positions once per render.
# Requests only the calculation date.
# Requests a 15-minute cache duration near sunrise/sunset.
# Requests a one-hour cache duration at night outside those windows.
# During the day, calculates the expected sky 30 minutes after sunset.
# Nighttime request timestamps use stable 15-minute or hourly buckets.
# Single-planet labels show the actual requested calculation time.
# Summary placement uses bounded coordinates and nearest empty cells.
# Missing or incomplete body data never selects another body as a fallback.
# A valid summary always displays, even when no objects are above the horizon.
# The hide toggle applies only to individual planets.


load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/jupiter.png", JUPITER_ASSET = "file")
load("images/mars.png", MARS_ASSET = "file")
load("images/mercury.png", MERCURY_ASSET = "file")
load("images/neptune.png", NEPTUNE_ASSET = "file")
load("images/saturn.png", SATURN_ASSET = "file")
load("images/uranus.png", URANUS_ASSET = "file")
load("images/venus.png", VENUS_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("sunrise.star", "sunrise")
load("time.star", "time")


app_hash = "M2IxYmY2OWUtZWIzMS00NTM0LTkyOWItMmRiMDlhMWVkYjI5OmZhN2YxOTM2M2I2N2QzZDNiYjEzNmNkMDhjMzM3YmUzZTQwMjE3ODg1MjIzY2QyYTNiNzFkZDlhYzU1YzBkODdkOWE0YjFiODkwMWUxN2JkZDU3YmZjOTBmZWI4NmE5MjdlMTBjNjZhYWFkYzFhMjE1NjdiOGYxNTUxOGNmMDU1ZGMwOTFhNzg5Nzc5M2FhNDE5OTUyMDAzNTUyY2U2ZWQ5NWUxNDZmMjkxZWQ0M2RhYzNjNGRmMjNmYTc5NTU2OTQ0MGVlNWY1N2NhOTJmYjNmYTg4OWYxOWFlNWQxMzU2"
time_display_format = "3:04 PM"
application_delimiter = ":"

summary_row_count = 5
summary_column_count = 13


planet_images = {
    "mercury": MERCURY_ASSET.readall(),
    "venus": VENUS_ASSET.readall(),
    "mars": MARS_ASSET.readall(),
    "jupiter": JUPITER_ASSET.readall(),
    "saturn": SATURN_ASSET.readall(),
    "uranus": URANUS_ASSET.readall(),
    "neptune": NEPTUNE_ASSET.readall(),
}


planet_colors = {
    "mercury": "#bc6700",
    "venus": "#c19e5e",
    "mars": "#e93305",
    "jupiter": "#c9ab8d",
    "saturn": "#ecb872",
    "uranus": "#3a68ff",
    "neptune": "#121178",
}


default_location = """
{
    "lat": "28.53933",
    "lng": "-81.38325",
    "description": "Orlando, FL, USA",
    "locality": "Orlando",
    "place_id": "???",
    "timezone": "America/New_York"
}
"""


def main(config):
    """Displays the selected planet or a planets-and-Moon sky summary."""

    system = config.get("system") or "metric"
    hide_quiet = config.get("hide_quiet")
    planet = config.get("planet", "all")

    # Reject unexpected selections before indexing the image dictionary.
    if planet != "all" and planet not in planet_images:
        return []

    location = json.decode(config.get("location", default_location))

    if type(location) != "dict":
        return []

    latitude = parse_number(location.get("lat"))
    longitude = parse_number(location.get("lng"))
    timezone = location.get("timezone")

    if latitude == None or longitude == None:
        return []

    if latitude < -90 or latitude > 90:
        return []

    if longitude < -180 or longitude > 180:
        return []

    if type(timezone) != "string" or timezone.strip() == "":
        return []

    # Capture the current time once in the selected timezone.
    now = time.now().in_location(timezone)

    sunrise_time = sunrise.sunrise(
        latitude,
        longitude,
        now,
    ).in_location(timezone)

    sunset_time = sunrise.sunset(
        latitude,
        longitude,
        now,
    ).in_location(timezone)

    near_sunrise_now = abs((now - sunrise_time).hours) <= 0.5
    near_sunset_now = abs((now - sunset_time).hours) <= 0.5
    near_solar_event = near_sunrise_now or near_sunset_now

    is_daytime = now > sunrise_time and now < sunset_time
    cache_ttl_seconds = 60 * 60

    if is_daytime:
        check_time = sunset_time + time.parse_duration("30m")

        cache_ttl_seconds = max(
            60,
            int(((sunset_time - now).hours - 0.5) * 60 * 60),
        )

        time_label = "Tonight at %s" % check_time.format(time_display_format)
    else:
        bucket_minutes = 15 if near_solar_event else 60
        check_time = get_bucketed_time(now, bucket_minutes)

        time_label = "As of %s" % check_time.format(time_display_format)

    if near_solar_event:
        cache_ttl_seconds = 15 * 60

    # Round coordinates only after calculating sunrise/sunset.
    location["lng"] = str(
        math.round(longitude * 10) * math.pow(10, -1),
    )
    location["lat"] = str(
        math.round(latitude * 10) * math.pow(10, -1),
    )

    position_json = get_all_planet_information(
        location,
        check_time,
        cache_ttl_seconds,
    )

    rows = get_body_rows(position_json)

    if rows == None or len(rows) == 0:
        return []

    # Summary mode does not use the hide toggle.
    # An empty chart still displays when no valid objects are above the horizon.
    if planet == "all":
        return get_summary_of_night_sky(rows)

    body = get_body_information(planet, rows)

    # Never substitute another body for a missing planet.
    if body == None:
        return []

    altitude = body["altitude"]
    bearing = body["bearing"]
    magnitude = body["magnitude"]
    constellation = body["constellation"]
    distance = body["distance"]

    distance_display = get_distance_display(distance, system)
    display_altitude = int(math.floor(altitude))

    if altitude < 0:
        if hide_quiet == True or hide_quiet == "true":
            return []

        row1 = "%s: Below the horizon" % time_label

        if distance_display != "":
            row2 = distance_display
        else:
            row2 = "Distance unavailable"
    else:
        row1 = "%s: %s at %s°" % (
            time_label,
            get_cardinal_position_from_degrees(bearing),
            display_altitude,
        )

        details = []

        if magnitude != None:
            details.append("Mag %s" % humanize.float("#.#", magnitude))

            if planet != "mercury" and planet != "venus":
                details.append(get_magnitude_description(magnitude))

        if constellation != "":
            details.append("in %s" % constellation)

        if distance_display != "":
            details.append(distance_display)

        if len(details) == 0:
            row2 = "Additional details unavailable"
        else:
            row2 = " ".join(details)

    return get_display(
        planet_images[planet],
        planet,
        row1,
        row2,
        config,
    )


def get_bucketed_time(local_time, bucket_minutes):
    """Rounds a local timestamp down to a stable minute bucket."""

    seconds_into_bucket = (
        (local_time.minute % bucket_minutes) * 60 +
        local_time.second
    )

    return local_time - time.parse_duration("%ss" % seconds_into_bucket)


def get_nested_value(value, keys):
    """Reads nested dictionary keys, returning None if any are missing."""

    current = value

    for key in keys:
        if type(current) != "dict":
            return None

        current = current.get(key)

    return current


def is_digit_string(value):
    """Checks for one or more ASCII digits."""

    if value == "":
        return False

    for i in range(len(value)):
        character = value[i]

        if character < "0" or character > "9":
            return False

    return True


def parse_number(value):
    """Parses a bounded decimal number without converting invalid strings.

    Accepts numeric values and decimal strings, including scientific notation.
    Returns None for missing, malformed, or excessively large values.
    """

    value_type = type(value)

    if value_type == "int" or value_type == "float":
        number = float(value)

        if number != number or abs(number) > 1e100:
            return None

        return number

    if value_type != "string":
        return None

    text = value.strip().lower()

    if text == "" or len(text) > 100:
        return None

    exponent_parts = text.split("e")

    if len(exponent_parts) > 2:
        return None

    mantissa = exponent_parts[0]

    if mantissa == "":
        return None

    if mantissa[0] == "+" or mantissa[0] == "-":
        mantissa = mantissa[1:]

    decimal_parts = mantissa.split(".")

    if len(decimal_parts) > 2:
        return None

    digits = "".join(decimal_parts)

    if not is_digit_string(digits):
        return None

    if len(exponent_parts) == 2:
        exponent = exponent_parts[1]

        if exponent == "":
            return None

        if exponent[0] == "+" or exponent[0] == "-":
            exponent = exponent[1:]

        if not is_digit_string(exponent):
            return None

        if len(exponent) > 3 or int(exponent) > 100:
            return None

    number = float(text)

    if number != number or abs(number) > 1e100:
        return None

    return number


def get_body_rows(position_json):
    """Validates the response's body-row container."""

    rows = get_nested_value(
        position_json,
        ["data", "table", "rows"],
    )

    if type(rows) != "list":
        return None

    return rows


def get_body_cell(body_name, rows):
    """Finds the requested body's first cell without a fallback body."""

    for row in rows:
        if type(row) != "dict":
            continue

        entry = row.get("entry")

        if type(entry) != "dict":
            continue

        entry_id = entry.get("id")
        entry_name = entry.get("name")

        matches = False

        if type(entry_id) == "string":
            matches = entry_id.lower() == body_name

        if not matches and type(entry_name) == "string":
            matches = entry_name.lower() == body_name

        if not matches:
            continue

        cells = row.get("cells")

        if type(cells) != "list" or len(cells) == 0:
            continue

        if type(cells[0]) != "dict":
            continue

        return cells[0]

    return None


def get_body_information(body_name, rows):
    """Extracts required coordinates and optional display information."""

    cell = get_body_cell(body_name, rows)

    if cell == None:
        return None

    altitude = parse_number(
        get_nested_value(
            cell,
            ["position", "horizontal", "altitude", "degrees"],
        ),
    )

    bearing = parse_number(
        get_nested_value(
            cell,
            ["position", "horizontal", "azimuth", "degrees"],
        ),
    )

    if altitude == None or bearing == None:
        return None

    if altitude < -90 or altitude > 90:
        return None

    bearing = bearing % 360.0

    magnitude = parse_number(
        get_nested_value(cell, ["extraInfo", "magnitude"]),
    )

    constellation = get_nested_value(
        cell,
        ["position", "constellation", "name"],
    )

    if type(constellation) != "string":
        constellation = ""
    else:
        constellation = constellation.strip()

    distance = parse_number(
        get_nested_value(cell, ["distance", "fromEarth", "km"]),
    )

    if distance != None and distance < 0:
        distance = None

    return {
        "altitude": altitude,
        "bearing": bearing,
        "magnitude": magnitude,
        "constellation": constellation,
        "distance": distance,
    }


def get_distance_display(distance, system):
    """Formats an available distance, or returns an empty string."""

    if distance == None:
        return ""

    if system == "metric":
        return "%s KMs away" % get_readable_large_number(distance)

    return "%s miles away" % get_readable_large_number(
        math.floor(distance * 0.6213712),
    )


def get_all_planet_information(location, check_time, cache_ttl_seconds):
    """Gets planetary positions for an explicit calculation time."""

    return get_all_body_positions(
        location,
        check_time,
        cache_ttl_seconds,
    )


def get_planet_code(object_name):
    """Gets an uppercase, single-character celestial object code."""

    if object_name == "mercury":
        return "E"
    elif object_name == "moon":
        return "O"
    elif object_name == "sun":
        return "*"

    return object_name[0].upper()


def get_summary_coordinates(altitude, bearing):
    """Maps altitude and bearing to bounded S-W-N-E-S chart coordinates."""

    bounded_altitude = max(0.0, min(90.0, altitude))

    altitude_band = min(
        summary_row_count - 1,
        int(bounded_altitude // 18),
    )

    row = summary_row_count - 1 - altitude_band

    chart_degrees = (bearing + 180.0) % 360.0
    fractional_column = chart_degrees / 30.0

    column = int(math.floor(fractional_column + 0.5))
    column = max(0, min(summary_column_count - 1, column))

    fractional_row = (
        summary_row_count - 1 -
        bounded_altitude / 18.0
    )
    fractional_row = max(
        0.0,
        min(float(summary_row_count - 1), fractional_row),
    )

    return row, column, fractional_row, fractional_column


def place_summary_object(summary, object_name, altitude, bearing, magnitude):
    """Places an object in its desired cell or the nearest empty cell."""

    row, column, fractional_row, fractional_column = get_summary_coordinates(
        altitude,
        bearing,
    )

    content = "%s%s%s" % (
        get_planet_code(object_name),
        application_delimiter,
        get_magnitude_color(magnitude),
    )

    if summary[row][column] == " ":
        summary[row][column] = content
        return True

    best_row = -1
    best_column = -1
    best_distance = None

    for candidate_row in range(summary_row_count):
        for candidate_column in range(summary_column_count):
            if summary[candidate_row][candidate_column] != " ":
                continue

            row_distance = candidate_row - fractional_row
            column_distance = candidate_column - fractional_column

            distance = (
                row_distance * row_distance +
                column_distance * column_distance
            )

            if best_distance == None or distance < best_distance:
                best_distance = distance
                best_row = candidate_row
                best_column = candidate_column

    if best_row < 0:
        return False

    summary[best_row][best_column] = content
    return True


def get_summary_of_night_sky(rows):
    """Always renders a summary chart from valid, already-fetched rows."""

    summary = [
        [" " for _ in range(summary_column_count)]
        for _ in range(summary_row_count)
    ]

    object_list = [
        "mercury",
        "venus",
        "mars",
        "jupiter",
        "saturn",
        "uranus",
        "neptune",
        "moon",
    ]

    for object_name in object_list:
        body = get_body_information(object_name, rows)

        if body == None:
            continue

        if body["altitude"] > 0:
            place_summary_object(
                summary,
                object_name,
                body["altitude"],
                body["bearing"],
                body["magnitude"],
            )

    # Render even if no objects were placed.
    return render.Root(
        render.Column(
            children = [
                render.Row(
                    children = get_render_row_children(summary[0]),
                ),
                render.Row(
                    children = get_render_row_children(summary[1]),
                ),
                render.Row(
                    children = get_render_row_children(summary[2]),
                ),
                render.Row(
                    children = get_render_row_children(summary[3]),
                ),
                render.Row(
                    children = get_render_row_children(summary[4]),
                ),
                render.Box(width = 64, height = 1, color = "#009900"),
                render.Box(width = 64, height = 1, color = "#000000"),
                render.Row(
                    children = [
                        render.Text(
                            content = "S  W  N  E  S",
                            color = "#ffffff",
                            font = "CG-pixel-4x5-mono",
                        ),
                    ],
                ),
            ],
        ),
    )


def get_render_row_children(items):
    """Converts a summary row into renderable text elements."""

    children = []

    for item in items:
        parts = item.split(application_delimiter)
        itemcolor = "#000000"

        if len(parts) == 2:
            itemcolor = parts[1]

        children.append(
            render.Text(
                content = parts[0],
                font = "CG-pixel-4x5-mono",
                color = itemcolor,
            ),
        )

    return children


def get_display(image, planet, row1, row2, config):
    """Renders the selected planet and its information."""

    return render.Root(
        render.Column(
            children = [
                render.Row(
                    children = [
                        render.Column(
                            children = [
                                render.Image(src = image),
                            ],
                        ),
                        render.Column(
                            children = [
                                render.Text(
                                    " %s" % planet.capitalize(),
                                    color = planet_colors[planet],
                                    font = "6x13",
                                ),
                            ],
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Column(
                            children = [
                                render.Marquee(
                                    width = 64,
                                    child = render.Text(
                                        row1,
                                        color = "#ffff00",
                                        font = "5x8",
                                    ),
                                ),
                                render.Marquee(
                                    width = 64,
                                    child = render.Text(
                                        row2,
                                        color = "#ffff00",
                                        font = "5x8",
                                    ),
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 60)),
    )


def get_magnitude_color(magnitude):
    """Gets the magnitude color, using white when magnitude is unknown."""

    if magnitude == None:
        return "#ffffff"

    if magnitude < 0:
        return "#ffff00"
    elif magnitude < 2:
        return "#ffff66"
    elif magnitude < 4:
        return "#ffffcc"
    elif magnitude < 6:
        return "#999900"
    elif magnitude < 8:
        return "#666600"

    return "#ffffff"


def get_magnitude_description(magnitude):
    """Gets the original visibility description for a magnitude."""

    if magnitude == None:
        return ""

    if magnitude < 0:
        return "easily visible"
    elif magnitude < 4:
        return "visible to naked eye"
    elif magnitude < 5:
        return "visible w/ binoculars"
    elif magnitude < 6:
        return "near limit of naked eye"
    elif magnitude < 10:
        return "visible with small telescope"
    elif magnitude < 30:
        return "near limit of Hubble telescope"

    return "you might need the James Webb Space telescope"


def get_cardinal_position_from_degrees(bearing):
    """Returns the nearest of sixteen compass directions."""

    compass_brackets = [
        "North", "NNE", "NE", "ENE",
        "East", "ESE", "SE", "SSE",
        "South", "SSW", "SW", "WSW",
        "West", "WNW", "NW", "NNW",
    ]

    normalized_bearing = bearing % 360.0
    index = int((normalized_bearing + 11.25) // 22.5) % 16

    return compass_brackets[index]


def get_readable_large_number(number):
    """Formats a large number using thousand/million/billion suffixes."""

    abbreviation = ("", "thousand", "million", "billion", "trillion")
    checkval = float(number)
    returnval = ""

    for i in range(0, 5):
        returnval = "%s %s" % (
            humanize.float("#.", checkval),
            abbreviation[i],
        )

        if checkval < 1000:
            break

        # buildifier: disable=integer-division
        checkval = checkval / 1000

    return returnval


def get_all_body_positions(location, check_time, ttl_seconds = 3600):
    """Gets body positions for the calculation date and timestamp."""

    date_code = "%s-%s-%s" % (
        two_character_time_date_part(check_time.year),
        two_character_time_date_part(check_time.month),
        two_character_time_date_part(check_time.day),
    )

    time_code = "%s:%s:%s" % (
        two_character_time_date_part(check_time.hour),
        two_character_time_date_part(check_time.minute),
        two_character_time_date_part(check_time.second),
    )

    # Request only the date whose first cell we display.
    params = {
        "longitude": location["lng"],
        "latitude": location["lat"],
        "elevation": "0",
        "from_date": date_code,
        "to_date": date_code,
        "time": time_code,
    }

    res = http.get(
        url = "https://api.astronomyapi.com/api/v2/bodies/positions",
        params = params,
        headers = {
            "Authorization": "Basic %s" % app_hash,
        },
        ttl_seconds = int(ttl_seconds),
    )

    if res.status_code != 200:
        return None

    position_json = res.json()

    if get_body_rows(position_json) == None:
        return None

    return position_json


def two_character_time_date_part(number):
    """Pads a single-digit date or time component with a leading zero."""

    if len(str(number)) == 1:
        return "0" + str(number)

    return str(number)


def get_schema():
    planet_options = [
        schema.Option(value = "mercury", display = "Mercury"),
        schema.Option(value = "venus", display = "Venus"),
        schema.Option(value = "mars", display = "Mars"),
        schema.Option(value = "jupiter", display = "Jupiter"),
        schema.Option(value = "saturn", display = "Saturn"),
        schema.Option(value = "uranus", display = "Uranus"),
        schema.Option(value = "neptune", display = "Neptune"),
        schema.Option(value = "all", display = "Planets + Moon"),
    ]

    measurement_options = [
        schema.Option(value = "metric", display = "Metric"),
        schema.Option(value = "imperial", display = "Imperial"),
    ]

    scroll_speed_options = [
        schema.Option(display = "Slow Scroll", value = "60"),
        schema.Option(display = "Medium Scroll", value = "45"),
        schema.Option(display = "Fast Scroll", value = "30"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "planet",
                name = "Planet",
                desc = "Pick a planet or the planets-and-Moon summary.",
                icon = "globe",
                options = planet_options,
                default = "all",
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Your location to determine if the selected planet is visible.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "system",
                name = "Measurement",
                desc = "Choose Imperial or Metric",
                icon = "ruler",
                options = measurement_options,
                default = "metric",
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = scroll_speed_options,
                default = "60",
            ),
            schema.Toggle(
                id = "hide_quiet",
                name = "Hide if not visible",
                desc = "Hide an individual planet below the horizon. The summary stays visible.",
                icon = "gear",
                default = True,
            ),
        ],
    )