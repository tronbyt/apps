"""
Applet: Visible Planets
Summary: Displays visible planets
Description: Displays direction and degrees above the horizon for the selected planet.
Author: Robert Ison
"""

# Notes:
# Requests a 15-minute cache duration near sunrise/sunset.
# Requests a one-hour cache duration at night outside those windows.
# During the day, calculates the expected sky 30 minutes after sunset.
# Single-planet displays identify the time their coordinates apply to.


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


# Used to convert bearing and altitude to a point on the 2D display.
compass_position = [6, 7, 8, 9, 10, 11, 12, 1, 2, 3, 4, 5, 6, 6]
altitude_position = [4, 3, 2, 1, 0]


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

    is_daytime = now > sunrise_time and now < sunset_time

    # Default: calculate the current sky using this explicit timestamp.
    check_time = now
    cache_ttl_seconds = 60 * 60
    time_label = "As of %s" % check_time.format(time_display_format)

    if is_daytime:
        # Forecast the sky 30 minutes after sunset.
        check_time = sunset_time + time.parse_duration("30m")
        time_label = "Tonight at %s" % check_time.format(time_display_format)

        # Set the cache duration to reach 30 minutes before sunset.
        cache_ttl_seconds = max(
            60,
            int(((sunset_time - now).hours - 0.5) * 60 * 60),
        )

    # Near sunrise/sunset, override the cache duration to 15 minutes.
    if near_sunrise_now or near_sunset_now:
        cache_ttl_seconds = 15 * 60

    # Sunrise/sunset were calculated with the exact GPS coordinates.
    # Round coordinates before sending them to the API:
    # 1) Avoid sending the user's exact position.
    # 2) Allow nearby users to share rounded coordinates.
    location["lng"] = str(
        math.round(float(location["lng"]) * 10) * math.pow(10, -1),
    )
    location["lat"] = str(
        math.round(float(location["lat"]) * 10) * math.pow(10, -1),
    )

    if planet == "all":
        return get_summary_of_night_sky(location, check_time)
    else:
        is_inner_planet = planet == "mercury" or planet == "venus"

        image = planet_images[planet]
        row1 = ""
        row2 = ""

        position_json = get_all_planet_information(
            location,
            check_time,
            cache_ttl_seconds,
        )
        planet_element = get_planet_element(planet, position_json)

        constellation = position_json["data"]["table"]["rows"][planet_element]["cells"][0]["position"]["constellation"]["name"]
        altitude = position_json["data"]["table"]["rows"][planet_element]["cells"][0]["position"]["horizontal"]["altitude"]["degrees"]
        altitude = math.floor(float(altitude))
        bearing = position_json["data"]["table"]["rows"][planet_element]["cells"][0]["position"]["horizontal"]["azimuth"]["degrees"]
        magnitude = float(position_json["data"]["table"]["rows"][planet_element]["cells"][0]["extraInfo"]["magnitude"])
        distance = position_json["data"]["table"]["rows"][planet_element]["cells"][0]["distance"]["fromEarth"]["km"]

        if system == "metric":
            distance_display = "%s KMs away" % get_readable_large_number(distance)
        else:
            distance_display = "%s miles away" % get_readable_large_number(
                math.floor(float(distance) * 0.6213712),
            )

        show_display = True

        if altitude < 0:
            if hide_quiet == True or hide_quiet == "true":
                show_display = False
            else:
                row1 = "%s: Below the horizon" % time_label
                row2 = distance_display
        else:
            row1 = "%s: %s at %s°" % (
                time_label,
                get_cardinal_position_from_degrees(float(bearing)),
                altitude,
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

        if show_display == True:
            return get_display(image, planet, row1, row2, config)
        else:
            return []


def get_planet_element(planet, position_json):
    planet_list = position_json["data"]["table"]["rows"]

    for i in range(0, len(planet_list)):
        if planet_list[i]["entry"]["name"].lower() == planet:
            return i

    # Original fallback retained.
    return 0


def get_all_planet_information(location, check_time, cache_ttl_seconds):
    """Gets planetary positions for an explicit calculation time.

    Args:
        location: Decoded observer location.
        check_time: Timestamp for which positions should be calculated.
        cache_ttl_seconds: Requested HTTP cache duration.

    Returns:
        Planetary position data from AstronomyAPI.
    """

    return get_all_body_positions(
        location,
        check_time,
        cache_ttl_seconds,
    )


def degrees_to_x(degrees):
    if degrees > 180:
        return int(degrees - 180)
    else:
        return int(degrees + 180)


def nexty(y, difference):
    """Gets the next horizontal coordinate, wrapping at the edges."""

    nexty = y + difference

    if nexty > 12:
        nexty = 0
    elif nexty < 0:
        nexty = 12

    return nexty


def nextx(x, difference):
    """Gets the next vertical coordinate, clamping at the edges."""

    nextx = x + difference

    if nextx > 4:
        nextx = 4
    elif nextx < 0:
        nextx = 0

    return nextx


def get_planet_code(object):
    """Gets a single-character code for a celestial object."""

    planet_code = object[0]

    if object == "mercury":
        planet_code = "E"
    elif object == "moon":
        planet_code = "O"
    elif object == "sun":
        planet_code = "*"

    return planet_code


def place_in_next_slot(summary, existing_item, new_item, magnitude):
    """Looks for an available slot when the requested slot is occupied."""

    ynew = new_item[2]
    yexist = existing_item[2]
    ydirection = 0

    if ynew > yexist:
        ydirection = +1
    else:
        ydirection = -1

    xnew = degrees_to_x(new_item[1])
    xexist = degrees_to_x(existing_item[1])
    xdirection = 0

    if xnew > xexist:
        xdirection = 1
    else:
        xdirection = -1

    testx = new_item[3]
    testy = new_item[4]
    alt = False
    planet_code = get_planet_code(new_item[0])

    for _ in range(100):
        if summary[testx][testy] == " ":
            summary[testx][testy] = "%s%s%s" % (
                planet_code,
                application_delimiter,
                get_magnitude_color(magnitude),
            )
            break
        else:
            alt = not alt

            if alt:
                testx = nextx(testx, xdirection)
            else:
                testy = nexty(testy, ydirection)


def place_duplicate(summary, display_items, x, y, magnitude):
    """Finds the existing item occupying a requested summary position."""

    for item in display_items:
        if display_items[item][3] == x and display_items[item][4] == y:
            place_in_next_slot(
                summary,
                display_items[item],
                display_items[len(display_items) - 1],
                magnitude,
            )
            break


def update_summary(summary, display_items, planet, x, y, magnitude):
    """Adds a planet to the summary grid."""

    planet_code = get_planet_code(planet).upper()

    if summary[x][y] == " ":
        summary[x][y] = "%s%s%s" % (
            planet_code,
            application_delimiter,
            get_magnitude_color(magnitude),
        )
    else:
        place_duplicate(summary, display_items, x, y, magnitude)


def concatenate(items):
    return_value = ""

    for letter in items:
        return_value = return_value + letter

    return return_value


def get_summary_of_night_sky(location, check_time):
    """Displays a sky summary for the supplied calculation timestamp."""

    summary = [
        [" ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " "],
        [" ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " "],
        [" ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " "],
        [" ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " "],
        [" ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " "],
    ]

    display_items = {}
    i = 0
    cache_ttl_seconds = 60 * 60 * 1

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

    for object in object_list:
        if object == "venus" or object == "mercury":
            cache_ttl_seconds = 15 * 60

        position_json = get_all_planet_information(
            location,
            check_time,
            cache_ttl_seconds,
        )
        planet_element = get_planet_element(object, position_json)

        altitude = position_json["data"]["table"]["rows"][planet_element]["cells"][0]["position"]["horizontal"]["altitude"]["degrees"]
        altitude = math.floor(float(altitude))
        bearing = float(position_json["data"]["table"]["rows"][planet_element]["cells"][0]["position"]["horizontal"]["azimuth"]["degrees"])
        magnitude = float(position_json["data"]["table"]["rows"][planet_element]["cells"][0]["extraInfo"]["magnitude"])

        if altitude > 0:
            x = altitude_position[int(math.round(float(altitude) // 18))]
            y = compass_position[int(math.round(float(bearing) // 30))]

            display_items[i] = [
                object,
                bearing,
                altitude,
                x,
                y,
                magnitude,
            ]

            update_summary(
                summary,
                display_items,
                object,
                x,
                y,
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
        items = item.split(application_delimiter)
        itemcolor = "#000000"

        if len(items) == 2:
            itemcolor = items[1]

        children.append(
            render.Text(
                content = items[0],
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
    """Returns the compass direction for a bearing."""

    if bearing < 0:
        bearing = 360 + bearing

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
        "North",
    ]

    display_cardinal_point = compass_brackets[
        int(math.round(bearing // 22.5))
    ]

    return display_cardinal_point


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