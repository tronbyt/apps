"""
Applet: Visible Planets
Summary: Displays visible planets
Description: Displays direction and degrees above the horizon for the selected planet.
Author: Robert Ison
"""

# Notes:
# Fetches all body positions once per render.
# Requests a 15-minute cache duration near sunrise/sunset.
# Requests a one-hour cache duration at night outside those windows.
# During the day, calculates the expected sky 30 minutes after sunset.
# Nighttime request timestamps use stable 15-minute or hourly buckets.
# Single-planet labels show the actual requested calculation time.
# Summary placement uses bounded coordinates and nearest empty cells.


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


# Colors are picked from the planet images.
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
    """Displays the selected planet or a summary of the night sky."""

    system = config.get("system") or "metric"
    hide_quiet = config.get("hide_quiet")
    location = json.decode(config.get("location", default_location))
    planet = config.get("planet", "mercury")

    # Capture the current time once in the selected location's timezone.
    now = time.now().in_location(location["timezone"])

    sunrise_time = sunrise.sunrise(
        float(location["lat"]),
        float(location["lng"]),
        now,
    ).in_location(location["timezone"])

    sunset_time = sunrise.sunset(
        float(location["lat"]),
        float(location["lng"]),
        now,
    ).in_location(location["timezone"])

    near_sunrise_now = abs((now - sunrise_time).hours) <= 0.5
    near_sunset_now = abs((now - sunset_time).hours) <= 0.5
    near_solar_event = near_sunrise_now or near_sunset_now

    is_daytime = now > sunrise_time and now < sunset_time

    cache_ttl_seconds = 60 * 60

    if is_daytime:
        # Forecast the sky 30 minutes after sunset.
        check_time = sunset_time + time.parse_duration("30m")

        # Set the cache duration to reach 30 minutes before sunset.
        cache_ttl_seconds = max(
            60,
            int(((sunset_time - now).hours - 0.5) * 60 * 60),
        )

        time_label = "Tonight at %s" % check_time.format(time_display_format)
    else:
        # Stable request times allow repeated renders to reuse responses.
        bucket_minutes = 15 if near_solar_event else 60
        check_time = get_bucketed_time(now, bucket_minutes)

        time_label = "As of %s" % check_time.format(time_display_format)

    if near_solar_event:
        cache_ttl_seconds = 15 * 60

    # Calculate solar events with exact coordinates, then round for the API.
    location["lng"] = str(
        math.round(float(location["lng"]) * 10) * math.pow(10, -1),
    )
    location["lat"] = str(
        math.round(float(location["lat"]) * 10) * math.pow(10, -1),
    )

    # Fetch once for either display mode.
    position_json = get_all_planet_information(
        location,
        check_time,
        cache_ttl_seconds,
    )

    if position_json == None:
        return []

    if planet == "all":
        return get_summary_of_night_sky(position_json)

    is_inner_planet = planet == "mercury" or planet == "venus"
    image = planet_images[planet]

    planet_element = get_planet_element(planet, position_json)
    cell = position_json["data"]["table"]["rows"][planet_element]["cells"][0]

    constellation = cell["position"]["constellation"]["name"]
    altitude = float(cell["position"]["horizontal"]["altitude"]["degrees"])
    bearing = float(cell["position"]["horizontal"]["azimuth"]["degrees"])
    magnitude = float(cell["extraInfo"]["magnitude"])
    distance = cell["distance"]["fromEarth"]["km"]

    # Preserve raw altitude for the horizon check.
    display_altitude = int(math.floor(altitude))

    if system == "metric":
        distance_display = "%s KMs away" % get_readable_large_number(distance)
    else:
        distance_display = "%s miles away" % get_readable_large_number(
            math.floor(float(distance) * 0.6213712),
        )

    if altitude < 0:
        if hide_quiet == True or hide_quiet == "true":
            return []

        row1 = "%s: Below the horizon" % time_label
        row2 = distance_display
    else:
        row1 = "%s: %s at %s°" % (
            time_label,
            get_cardinal_position_from_degrees(bearing),
            display_altitude,
        )

        if is_inner_planet:
            row2 = "Mag %s in %s %s" % (
                humanize.float("#.#", magnitude),
                constellation,
                distance_display,
            )
        else:
            row2 = "Mag %s %s in %s %s" % (
                humanize.float("#.#", magnitude),
                get_magnitude_description(magnitude),
                constellation,
                distance_display,
            )

    return get_display(image, planet, row1, row2, config)


def get_bucketed_time(local_time, bucket_minutes):
    """Rounds a local timestamp down to a stable minute bucket."""

    seconds_into_bucket = (
        (local_time.minute % bucket_minutes) * 60 +
        local_time.second
    )

    return local_time - time.parse_duration("%ss" % seconds_into_bucket)


def get_planet_element(planet, position_json):
    planet_list = position_json["data"]["table"]["rows"]

    for i in range(len(planet_list)):
        if planet_list[i]["entry"]["name"].lower() == planet:
            return i

    # Original fallback retained.
    return 0


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
    """Maps altitude and bearing to bounded chart coordinates.

    Rows run from high altitude at the top to the horizon at the bottom.
    Columns follow the existing S-W-N-E-S chart.

    Returns:
        Desired row, desired column, fractional row, fractional column.
    """

    bounded_altitude = max(0.0, min(90.0, altitude))

    # Preserve five 18-degree altitude bands.
    # Clamp the band so 90 degrees cannot produce an invalid index.
    altitude_band = min(
        summary_row_count - 1,
        int(bounded_altitude // 18),
    )

    row = summary_row_count - 1 - altitude_band

    # Convert azimuth to the S-W-N-E-S chart:
    # South = either edge, West = 3, North = 6, East = 9.
    chart_degrees = (bearing + 180.0) % 360.0
    fractional_column = chart_degrees / 30.0

    # Select the nearest 30-degree column rather than flooring first.
    column = int(math.floor(fractional_column + 0.5))
    column = max(0, min(summary_column_count - 1, column))

    # Fractional positions help choose a nearby slot when objects overlap.
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
    """Places an object in its desired cell or the nearest empty cell.

    Searches every chart cell if the desired cell is occupied.
    No coordinate wrapping or unbounded collision loop is needed.

    Returns:
        True if placed, or False if the chart is full.
    """

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


def get_summary_of_night_sky(position_json):
    """Displays a sky summary using the already-fetched body positions."""

    # Create independent rows rather than sharing one mutable row.
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

    # Every object uses the same response and calculation timestamp.
    for object_name in object_list:
        planet_element = get_planet_element(object_name, position_json)
        cell = position_json["data"]["table"]["rows"][planet_element]["cells"][0]

        altitude = float(
            cell["position"]["horizontal"]["altitude"]["degrees"],
        )
        bearing = float(
            cell["position"]["horizontal"]["azimuth"]["degrees"],
        )
        magnitude = float(cell["extraInfo"]["magnitude"])

        # Check the raw altitude, not a floored display value.
        if altitude > 0:
            place_summary_object(
                summary,
                object_name,
                altitude,
                bearing,
                magnitude,
            )

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
                render.Box(
                    width = 64,
                    height = 1,
                    color = "#009900",
                ),
                render.Box(
                    width = 64,
                    height = 1,
                    color = "#000000",
                ),
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
        delay = int(config.get("scroll", 45)),
    )


def get_magnitude_color(magnitude):
    """Gets the display color associated with apparent magnitude."""

    color = "#ffffff"

    if magnitude < 0:
        color = "#ffff00"
    elif magnitude < 2:
        color = "#ffff66"
    elif magnitude < 4:
        color = "#ffffcc"
    elif magnitude < 6:
        color = "#999900"
    elif magnitude < 8:
        color = "#666600"
    else:
        color = "#ffffff"

    return color


def get_magnitude_description(magnitude):
    """Gets the original visibility description for a magnitude."""

    description = ""

    if magnitude < 0:
        description = "easily visible"
    elif magnitude < 4:
        description = "visible to naked eye"
    elif magnitude < 5:
        description = "visible w/ binoculars"
    elif magnitude < 6:
        description = "near limit of naked eye"
    elif magnitude < 10:
        description = "visible with small telescope"
    elif magnitude < 30:
        description = "near limit of Hubble telescope"
    else:
        description = "you might need the James Webb Space telescope"

    return description


def get_cardinal_position_from_degrees(bearing):
    """Returns the nearest of sixteen compass directions."""

    compass_brackets = [
        "North",
        "NNE",
        "NE",
        "ENE",
        "East",
        "ESE",
        "SE",
        "SSE",
        "South",
        "SSW",
        "SW",
        "WSW",
        "West",
        "WNW",
        "NW",
        "NNW",
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
    """Gets body-position data for the supplied calculation timestamp."""

    date_code = "%s-%s-%s" % (
        two_character_time_date_part(check_time.year),
        two_character_time_date_part(check_time.month),
        two_character_time_date_part(check_time.day),
    )

    tomorrow_date_code = check_time + time.parse_duration("24h")
    tomorrow_date_code = "%s-%s-%s" % (
        two_character_time_date_part(tomorrow_date_code.year),
        two_character_time_date_part(tomorrow_date_code.month),
        two_character_time_date_part(tomorrow_date_code.day),
    )

    time_code = "%s:%s:%s" % (
        two_character_time_date_part(check_time.hour),
        two_character_time_date_part(check_time.minute),
        two_character_time_date_part(check_time.second),
    )

    params = {
        "longitude": location["lng"],
        "latitude": location["lat"],
        "elevation": "0",
        "from_date": date_code,
        "to_date": tomorrow_date_code,
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

    if res.status_code == 200:
        return res.json()
    else:
        return None


def two_character_time_date_part(number):
    """Pads a single-digit date or time component with a leading zero."""

    if len(str(number)) == 1:
        return "0" + str(number)
    else:
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
        schema.Option(value = "all", display = "All Visible Planets"),
    ]

    measurement_options = [
        schema.Option(value = "metric", display = "Metric"),
        schema.Option(value = "imperial", display = "Imperial"),
    ]

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

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "planet",
                name = "Planet",
                desc = "Pick the planet you want to track.",
                icon = "globe",
                options = planet_options,
                default = planet_options[7].value,
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
                default = scroll_speed_options[0].value,
            ),
            schema.Toggle(
                id = "hide_quiet",
                name = "Hide if not visible",
                desc = "Skip displaying this app when the selected planet is below the horizon?",
                icon = "gear",
                default = True,
            ),
        ],
    )