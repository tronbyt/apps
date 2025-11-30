"""
Applet: Visible Planets
Summary: Displays visible planets
Description: Displays direction and degrees above the horizon for the selected planet.
Author: Robert Ison
"""

# Notes:
# Pulls down data every 15 minutes near sunrise/sunset because the inner planets move a lot during this time
# Pulls down data every hour starting 30 minutes after sunset until 30 minutes befor sunrise
# Pulls down the expected evening sky during the day -- when it is sunny, there are no 'visible planets' so we'll display what you can expect in the evening.

load("cache.star", "cache")
load("encoding/base64.star", "base64")  #to encode/decode json data going to and from cache
load("encoding/json.star", "json")  #Used to figure out timezone
load("http.star", "http")  #for calling to astronomyapi.com
load("humanize.star", "humanize")  #for easy reading numbers and times
load("math.star", "math")  #for calculating distance to planets
load("render.star", "render")
load("schema.star", "schema")
load("sunrise.star", "sunrise")  #to calcuate day/night and when planets will be visible
load("time.star", "time")  #Used to display time and calcuate lenght of TTL cache

app_hash = "M2IxYmY2OWUtZWIzMS00NTM0LTkyOWItMmRiMDlhMWVkYjI5OmZhN2YxOTM2M2I2N2QzZDNiYjEzNmNkMDhjMzM3YmUzZTQwMjE3ODg1MjIzY2QyYTNiNzFkZDlhYzU1YzBkODdkOWE0YjFiODkwMWUxN2JkZDU3YmZjOTBmZWI4NmE5MjdlMTBjNjZhYWFkYzFhMjE1NjdiOGYxNTUxOGNmMDU1ZGMwOTFhNzg5Nzc5M2FhNDE5OTUyMDAzNTUyY2U2ZWQ5NWUxNDZmMjkxZWQ0M2RhYzNjNGRmMjNmYTc5NTU2OTQ0MGVlNWY1N2NhOTJmYjNmYTg4OWYxOWFlNWQxMzU2"
time_display_format = "3:04 PM"
application_delimiter = ":"

#planet images
planet_images = {
    "mercury": MERCURY_ASSET.readall(),
    "venus": VENUS_ASSET.readall(),
    "mars": MARS_ASSET.readall(),
    "jupiter": JUPITER_ASSET.readall(),
    "saturn": SATURN_ASSET.readall(),
    "uranus": URANUS_ASSET.readall(),
    "neptune": NEPTUNE_ASSET.readall(),
}

#color of text used to display planet name
#colors are picked from the planet images
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

#Used to convert bearing and altitude to a point on 2D display
compass_position = [6, 7, 8, 9, 10, 11, 12, 1, 2, 3, 4, 5, 6, 6]
altitude_position = [4, 3, 2, 1, 0]

def main(config):
    """ Visible Planets

    Args:
        config: Configuration Items to control how the app is displayed
    Returns:
        Display for Tidbyt
    """

    #settings:
    system = config.get("system") or "metric"
    hide_quiet = config.get("hide_quiet")
    location = json.decode(config.get("location", default_location))

    planet = config.get("planet", "mercury")  #default to mercury

    #get locations sunrise/sunset
    now = time.now()
    sunrise_time = sunrise.sunrise(float(location["lat"]), float(location["lng"]), now).in_location(location["timezone"])
    sunset_time = sunrise.sunset(float(location["lat"]), float(location["lng"]), now).in_location(location["timezone"])

    near_sunrise_now = True if ((now - sunrise_time).hours) < 0.5 else False
    near_sunset_now = True if ((now - sunset_time).hours) < 0.5 else False

    is_after_sunrise = now > sunrise_time
    is_before_sunset = now < sunset_time

    #print("Now: %s Sunrise:%s Sunset: %s Near Sunrise: %s Near Sunset: %s IsAfterSunrise: %s IsBeforeSunset: %s" % (now, sunrise_time, sunset_time, near_sunrise_now, near_sunset_now, is_after_sunrise, is_before_sunset))

    cache_ttl_seconds = 1 * 60 * 60  #default to one hour
    check_offset = 0  #by default we will check for the planets right now
    if near_sunrise_now or near_sunset_now:
        cache_ttl_seconds = 15 * 60  #Let's check each 15 minutes around sunset and sunrise as inner planets move quite a bit then
    elif is_before_sunset and is_after_sunrise:
        #during the day you can't see much so let's get the early evening's sky and present that.
        #so during the day your Tidbyt will tell you what you can see this evening.
        check_offset = abs((now - sunset_time).hours) - 0.5
        cache_ttl_seconds = check_offset * 60 * 60

    #we've calculated sunset and sunrise with the exact gps coordinates, but now we will round the coordinates to one decimal
    #place for two reasons:
    #1) We don't give the API host the exact position of any Tidbyt user, and
    #2) We can reduce api calls by grouping people that live close enough to share the same rounded coordinates

    location["lng"] = str((math.round(float(location["lng"]) * 10)) * math.pow(10, -1))
    location["lat"] = str((math.round(float(location["lat"]) * 10)) * math.pow(10, -1))

    if planet == "all":
        return get_summary_of_night_sky(location, check_offset)
    else:
        visibility_disclaimer = ""
        is_inner_planet = planet == "mercury" or planet == "venus"
        if (is_after_sunrise == True and is_before_sunset == True):
            #Daytime
            if ((abs((now - sunrise_time).hours) < abs((now - sunset_time).hours)) and is_inner_planet):
                # closer to sunrise
                visibility_disclaimer = "around sunrise at %s" % sunrise_time.format(time_display_format)
            else:
                # closer to sunset
                # since we can't see this till sunset, let's cache this until
                # 30 minutes before sunset, save a few API calls

                if is_inner_planet:
                    # let's check visibility of inner planets at sunset instead of now
                    # to avoid telling folks the planet will be visible in the evening, when it might
                    # dip below the horizon before then.
                    visibility_disclaimer = "around sunset at %s" % sunset_time.format(time_display_format)
                else:
                    visibility_disclaimer = "after sunset at %s" % sunset_time.format(time_display_format)
        elif (abs((now - sunrise_time).hours) < abs((now - sunset_time).hours)):
            # Nighttime closer to sunrise
            visibility_disclaimer = "before sunrise at %s" % sunrise_time.format(time_display_format)
        else:
            # Nighttime closer to sunset
            visibility_disclaimer = "after sunset at %s" % sunset_time.format(time_display_format)

        # planet image of the selected planet
        image = base64.decode(planet_images[planet])

        # initialize row 1 and row 2 display data
        row1 = ""
        row2 = ""

        # JSon Data holding all planetary positioning data
        position_json = get_all_planet_information(location, check_offset, cache_ttl_seconds)
        planet_element = get_planet_element(planet, position_json)

        # pull data from json dataset
        constellation = position_json["data"]["table"]["rows"][planet_element]["cells"][0]["position"]["constellation"]["name"]
        altitude = position_json["data"]["table"]["rows"][planet_element]["cells"][0]["position"]["horizontal"]["altitude"]["degrees"]
        altitude = math.floor(float(altitude))
        bearing = position_json["data"]["table"]["rows"][planet_element]["cells"][0]["position"]["horizontal"]["azimuth"]["degrees"]
        magnitude = float(position_json["data"]["table"]["rows"][planet_element]["cells"][0]["extraInfo"]["magnitude"])
        distance = position_json["data"]["table"]["rows"][planet_element]["cells"][0]["distance"]["fromEarth"]["km"]

        if system == "metric":
            distance_display = "%s KMs away" % get_readable_large_number(distance)
        else:
            distance_display = "%s miles away" % get_readable_large_number(math.floor(float(distance) * 0.6213712))

        show_display = True

        if altitude < 0:
            # below horizon
            if hide_quiet == True or hide_quiet == "true":
                show_display = False
            else:
                row1 = "Not Visible as it is below the horizon."
                row2 = "%s" % distance_display
        else:
            # above horizon
            row1 = "%s at %s°" % (get_cardinal_position_from_degrees(float(bearing)), altitude)
            if is_inner_planet:
                row2 = "Mag %s in %s %s" % (humanize.float("#.#", magnitude), constellation, distance_display)
            else:
                row2 = "Mag %s %s %s in %s %s" % (humanize.float("#.#", magnitude), get_magnitude_description(magnitude), visibility_disclaimer, constellation, distance_display)

        if show_display == True:
            return get_display(image, planet, row1, row2, config)
        else:
            # hiding if the planet is below horizon and user checked
            # to hide when nothing to show
            return []

def get_planet_element(planet, position_json):
    planet_list = position_json["data"]["table"]["rows"]
    for i in range(0, len(planet_list)):
        if planet_list[i]["entry"]["name"].lower() == planet:
            return i

    #this should never happen
    return 0

def get_all_planet_information(location, check_offset, cache_ttl_seconds):
    """ Gets the information on a particular planet based on location and time

    Args:
        planet: the name of the planet we are displaying
        location: the location of the user
        check_offset: How much further in time do we want to check?
        cache_ttl_seconds: How long to we keep this data before refreshing
    Returns:
        JSON data of planet from perspective of given location and time
    """
    position_json = None

    # Cache Name based on planet and location
    cache_name = "AllPlanets_%s_%s" % (location["lng"], location["lat"])
    cache_contents = cache.get(cache_name)

    # Check now or include an offset
    check_time = get_local_time(location, check_offset)

    if cache_contents == None:
        position_json = get_all_body_positions(location, check_time)
        #print(position_json)

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(cache_name, json.encode(position_json), ttl_seconds = cache_ttl_seconds)
    else:
        position_json = json.decode(cache_contents)

    return position_json

def degrees_to_x(degrees):
    if (degrees > 180):
        return int(degrees - 180)
    else:
        return int(degrees + 180)

def nexty(y, difference):
    """ Gets the next y coordinate based on the direction we want to go

    Args:
        y: the current coordinate
        difference: The direction and steps we want to move to look for a blank
    Returns:
        The next y coordinate to check
    """
    nexty = y + difference

    #if we scroll off the page along the horizon, let's go to the other side
    if (nexty > 12):
        nexty = 0
    elif (nexty < 0):
        nexty = 12

    return nexty

def nextx(x, difference):
    """ Gets the next x coordinate based on the direction we want to go

    Args:
        x: the current coordinate
        difference: The direction and steps we want to move to look for a blank
    Returns:
        The next x coordinate to check
    """
    nextx = x + difference

    #if we scroll off the top or bottom, let's just stay there, and find a blank to the left or right instead
    if (nextx > 4):
        nextx = 4
    elif (nextx < 0):
        nextx = 0

    return nextx

def get_planet_code(object):
    """ Gets the single character planet code based on the object's name

    Args:
        object: the name of the celestial object

    Returns:
        The single letter code for display
    """

    planet_code = object[0]
    if object == "mercury":
        planet_code = "E"
    elif object == "moon":
        planet_code = "O"
    elif object == "sun":
        planet_code = "*"

    return planet_code

def place_in_next_slot(summary, existing_item, new_item, magnitude):
    """ When the slot we want to place a planet is occupied, we'll use this function to figure out the next best place to put it.

    Args:
        summary: the summary contains all the planet names in the position on the 2d array
        existing_item: information on the item that is in the spot of:
        new_item: the new item that we are looking to place
        magnitude: the apparent magnitude (brightness) of an object
    """
    ynew = new_item[2]
    yexist = existing_item[2]
    ydirection = 0
    if (ynew > yexist):
        ydirection = +1
    else:
        ydirection = -1

    xnew = degrees_to_x(new_item[1])
    xexist = degrees_to_x(existing_item[1])

    xdirection = 0
    if (xnew > xexist):
        #new is to the right of the existing
        xdirection = 1
    else:
        #new is to the left of the existing
        xdirection = -1

    #loop through summary, one step at a time looking for an empty space ... go up/down then left/right
    testx = new_item[3]
    testy = new_item[4]
    alt = False
    planet_code = get_planet_code(new_item[0])

    # Loop until we find a blank spot nearest the correct spot.
    # There are 5 x 12 = 60 slots, and at most
    for _ in range(100):
        if (summary[testx][testy] == " "):
            summary[testx][testy] = "%s%s%s" % (planet_code, application_delimiter, get_magnitude_color(magnitude))
            break
        else:
            alt = not alt
            if (alt):
                testx = nextx(testx, xdirection)
            else:
                testy = nexty(testy, ydirection)

def place_duplicate(summary, display_items, x, y, magnitude):
    """ We need to find an empty spot in the summary to place this code. It should be in the same approximate order as it appears in real life. So, if Mars and Venus are in the same slot, but Mars is slightly west of Venus, Mars should appear in that direction

    Args:
        summary: summary is the 2d array summarizing the night sky
        display_items: information on all the display items (planets) with coordinates, bearing, altitude needed to figure out where to plot
        x: x coordinate
        y: y coordinate
        magnitude: apparent magnitude (brightness) of object
    """

    #find first duplicate
    for item in display_items:
        if (display_items[item][3] == x and display_items[item][4] == y):
            place_in_next_slot(summary, display_items[item], display_items[len(display_items) - 1], magnitude)
            break

def update_summary(summary, display_items, planet, x, y, magnitude):
    """ Updates the Summary 2d array with a new planet

    Args:
        summary: summary is the 2d array summarizing the night sky
        display_items: information on all the display items (planets) with coordinates, bearing, altitude needed to figure out where to plot
        planet: the current planet to plot
        x: x coordinate
        y: y coordinate
        magnitude: apparent magnitude (brightness) of object
    """

    planet_code = get_planet_code(planet).upper()

    if (summary[x][y] == " "):
        summary[x][y] = "%s%s%s" % (planet_code, application_delimiter, get_magnitude_color(magnitude))
    else:
        place_duplicate(summary, display_items, x, y, magnitude)

def concatenate(items):
    return_value = ""
    for letter in items:
        return_value = return_value + letter

    return return_value

def get_summary_of_night_sky(location, check_offset):
    """ Gets a summary of the entire night sky

    Args:
        location: location of user
        check_offset: the time offset to grab night sky info

    Returns:
        The tidbyt display
    """

    # initialize the summary 2D array meant to hold the letter of the visible planet in the right spot on the 2D display
    summary = [[" ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " "], [" ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " "], [" ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " "], [" ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " "], [" ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " "]]

    # place to store visible items info
    display_items = {}
    i = 0
    cache_ttl_seconds = 60 * 60 * 1  #1 hour x 60 minutes per hour * 60 seconds per minute
    object_list = ["mercury", "venus", "mars", "jupiter", "saturn", "uranus", "neptune", "moon"]
    for object in object_list:
        if (object == "venus" or object == "mercury"):
            cache_ttl_seconds = 15 * 60
        position_json = get_all_planet_information(location, check_offset, cache_ttl_seconds)
        planet_element = get_planet_element(object, position_json)
        altitude = position_json["data"]["table"]["rows"][planet_element]["cells"][0]["position"]["horizontal"]["altitude"]["degrees"]
        altitude = math.floor(float(altitude))
        bearing = float(position_json["data"]["table"]["rows"][planet_element]["cells"][0]["position"]["horizontal"]["azimuth"]["degrees"])
        magnitude = float(position_json["data"]["table"]["rows"][planet_element]["cells"][0]["extraInfo"]["magnitude"])

        if altitude > 0:
            x = altitude_position[int(math.round(float(altitude) // 18))]
            y = compass_position[int(math.round(float(bearing) // 30))]
            display_items[i] = [object, bearing, altitude, x, y, magnitude]
            update_summary(summary, display_items, object, x, y, magnitude)

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
                        render.Text(content = "S  W  N  E  S", color = "#ffffff", font = "CG-pixel-4x5-mono"),
                    ],
                ),
            ],
        ),
    )

def get_render_row_children(items):
    """ Returns the children of a display row based on the simply 2D summary array of celestial objects and their relative positions and magnitude

    Args:
        items: The "Items" are the letters indicating celestial objects in that layer of the sky
    Returns:
        The Children of a dispplay row
    """
    children = []

    for item in items:
        items = item.split(application_delimiter)
        itemcolor = "#000000"
        if len(items) == 2:
            itemcolor = items[1]
        children.append(render.Text(content = items[0], font = "CG-pixel-4x5-mono", color = itemcolor))

    return children

def get_display(image, planet, row1, row2, config):
    """ Gets the display based on the selected image, planet and calculated describtion

    Args:
        image: the image of the given planet
        planet: the name of the planet we are displaying
        row1: Row1 Text is generally the direction and degrees above horizon to view the planet
        row2: Row2 Gives additional information on when to look, which constellation, and distance from earth
        config: The config object to figure out what display speed to present
    Returns:
        The display information for your Tidbyt
    """
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
                                render.Text(" %s" % planet.capitalize(), color = planet_colors[planet], font = "6x13"),
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
                                    child = render.Text(row1, color = "#ffff00", font = "5x8"),
                                ),
                                render.Marquee(
                                    width = 64,
                                    child = render.Text(row2, color = "#ffff00", font = "5x8"),
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
    """ Gets a description of the visibility based on the magnitude

    Args:
        magnitude: scale used to determine relative brightness of objects
    Returns:
        Color code for display color representing brightness
    """

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
    """ Gets a description of the visibility based on the magnitude

    Args:
        magnitude: scale used to determine relative brightness of objects
    Returns:
        Description of that brightness
    """
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

def get_readable_large_number(number):
    """ Gets a readable version of a large number 25B instead of 25,123,345,345 for example.

    Args:
        number: The actual number
    Returns:
        Readable display number as a string
    """

    abbreviation = ("", "thousand", "million", "billion", "trillion")
    checkval = float(number)
    returnval = ""
    for i in range(0, 5):
        returnval = "%s %s" % (humanize.float("#.", checkval), abbreviation[i])
        if checkval < 1000:
            break

        # buildifier: disable=integer-division
        checkval = checkval / 1000

    return returnval

def get_all_body_positions(location, check_time):
    """ Gets the JSon Data from astronomyapi

    Args:

        location: Location of the observer
        check_time: Time to get the data for the given planet
    Returns:
        JSon Data
    """

    date_code = "%s-%s-%s" % (two_character_time_date_part(check_time.year), two_character_time_date_part(check_time.month), two_character_time_date_part(check_time.day))
    tomorrow_date_code = check_time + time.parse_duration("24h")
    tomorrow_date_code = "%s-%s-%s" % (two_character_time_date_part(tomorrow_date_code.year), two_character_time_date_part(tomorrow_date_code.month), two_character_time_date_part(tomorrow_date_code.day))
    time_code = "%s:%s:%s" % (two_character_time_date_part(check_time.hour), two_character_time_date_part(check_time.minute), two_character_time_date_part(check_time.second))

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
    )

    if res.status_code == 200:
        return res.json()
    else:
        return None

def two_character_time_date_part(number):
    """ Returns two characters to represent an hour/minute/second needed when puttin together a timestamp 03:01:04

    Args:
        number: number we need to represent in two characters
    Returns:
        A two character string that represents the given number
    """
    if len(str(number)) == 1:
        return "0" + str(number)
    else:
        return str(number)

def get_local_time(config, offset_hours):
    """ Returns the local time based on the configuration of the app

    Args:
        config: the config object provided by the Tidbyt platform
        offset_hours: it will add this many hours (subtrack if negative) to the current local time
    Returns:
        The local time
    """
    timezone = json.decode(config.get("location", default_location))["timezone"]
    offset_hours = offset_hours

    #local_time = time.now().in_location(timezone)
    local_time = time.now() + time.parse_duration("%sh" % offset_hours)
    local_time = local_time.in_location(timezone)
    return local_time

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
                icon = "globe",  #skyatlas #moon, globe, mars, marsandvenus satelliteDish
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
