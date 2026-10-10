"""
Applet: Park Wait Times
Summary: Park Wait Times
Description: Displays theme park ride wait times at various theme parks.
Author: hx009
"""

load("http.star", "http")
load("images/icon_cedar_fair.png", ICON_CEDAR_FAIR_ASSET = "file")
load("images/icon_disney.png", ICON_DISNEY_ASSET = "file")
load("images/icon_sea_world.png", ICON_SEA_WORLD_ASSET = "file")
load("images/icon_six_flags.png", ICON_SIX_FLAGS_ASSET = "file")
load("images/icon_universal.png", ICON_UNIVERSAL_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

ICON_CEDAR_FAIR = ICON_CEDAR_FAIR_ASSET.readall()
ICON_DISNEY = ICON_DISNEY_ASSET.readall()
ICON_SEA_WORLD = ICON_SEA_WORLD_ASSET.readall()
ICON_SIX_FLAGS = ICON_SIX_FLAGS_ASSET.readall()
ICON_UNIVERSAL = ICON_UNIVERSAL_ASSET.readall()

COLOR_GREEN = "#4CFF00"
COLOR_YELLOW = "#FFD800"
COLOR_RED = "#FF0000"
COLOR_GRAY = "#A0A0A0"
CACHE_TIME_SECONDS = 300  # cache for 5 minutes per https://queue-times.com/en-US/pages/api
PARKS_URL = "https://queue-times.com/parks.json"

DEFAULT_PARK = "5"
DEFAULT_SHOW_ACTUAL_WAIT_TIMES = False
DEFAULT_SHOW_CLOSED_RIDES = True
DEFAULT_LITTLE_OR_NO_WAIT_MAX_MINUTES = "15"
DEFAULT_MODERATE_WAIT_MAX_MINUTES = "30"
DEFAULT_FONT = "tom-thumb"
DEFAULT_PIXELS_BETWEEN_RIDES = "2"

def main(config):
    """App entry point

    Args:
        config: User configuration values

    Returns:
        The rendered app
    """
    show_actual_wait_times = config.bool("show_actual_wait_times", DEFAULT_SHOW_ACTUAL_WAIT_TIMES)
    show_closed_rides = config.bool("show_closed_rides", DEFAULT_SHOW_CLOSED_RIDES)
    little_or_no_wait_max_minutes = int(config.get("little_or_no_wait_max_minutes", DEFAULT_LITTLE_OR_NO_WAIT_MAX_MINUTES))
    moderate_wait_max_minutes = int(config.get("moderate_wait_max_minutes", DEFAULT_MODERATE_WAIT_MAX_MINUTES))
    selected_font = config.get("font", DEFAULT_FONT)
    pixels_between_rides = int(config.get("pixels_between_rides", DEFAULT_PIXELS_BETWEEN_RIDES))

    park_list = get_http_data(PARKS_URL)
    park_details = get_http_data("https://queue-times.com/parks/" + config.get("park", DEFAULT_PARK) + "/queue_times.json")
    park_name = "park name"
    operator_name = "operator name"

    for x in range(len(park_list)):
        for y in range(len(park_list[x]["parks"])):
            if str(int(park_list[x]["parks"][y]["id"])) == config.get("park", DEFAULT_PARK):
                park_name = park_list[x]["parks"][y]["name"]
                operator_name = park_list[x]["name"]

    if len(park_details["lands"]) == 0 and len(park_details["rides"]) == 0:
        return render.Root(
            child = render.Column(
                children = [
                    render.WrappedText(content = park_name, font = selected_font),
                    render.WrappedText(content = "Data not available", font = selected_font, color = COLOR_GRAY),
                ],
            ),
        )
    else:
        at_least_one_ride_open = False
        wait_times = []
        wait_times.append(render.WrappedText(content = "Powered by Queue-Times.com", font = selected_font))
        wait_times.append(render.Box(width = 64, height = pixels_between_rides))
        wait_times.append(get_operator_logo(operator_name))
        wait_times.append(render.WrappedText(content = park_name, font = selected_font))
        wait_times.append(render.Box(width = 64, height = pixels_between_rides))

        for land_index in range(len(park_details["lands"])):
            for land_ride_index in range(len(park_details["lands"][land_index]["rides"])):
                if park_details["lands"][land_index]["rides"][land_ride_index]["is_open"]:
                    at_least_one_ride_open = True
                    ride_name = park_details["lands"][land_index]["rides"][land_ride_index]["name"]

                    if show_actual_wait_times:
                        ride_name += " (" + str(int(park_details["lands"][land_index]["rides"][land_ride_index]["wait_time"])) + "min)"

                    if park_details["lands"][land_index]["rides"][land_ride_index]["wait_time"] <= little_or_no_wait_max_minutes:
                        wait_times.append(render.WrappedText(content = ride_name, font = selected_font, color = COLOR_GREEN))
                    elif park_details["lands"][land_index]["rides"][land_ride_index]["wait_time"] <= moderate_wait_max_minutes:
                        wait_times.append(render.WrappedText(content = ride_name, font = selected_font, color = COLOR_YELLOW))
                    else:
                        wait_times.append(render.WrappedText(content = ride_name, font = selected_font, color = COLOR_RED))

                    wait_times.append(render.Box(width = 64, height = pixels_between_rides))
                elif show_closed_rides:
                    wait_times.append(render.WrappedText(content = park_details["lands"][land_index]["rides"][land_ride_index]["name"], font = selected_font, color = COLOR_GRAY))
                    wait_times.append(render.Box(width = 64, height = pixels_between_rides))

        for ride_index in range(len(park_details["rides"])):
            if park_details["rides"][ride_index]["is_open"]:
                at_least_one_ride_open = True
                ride_name = park_details["rides"][ride_index]["name"]

                if show_actual_wait_times:
                    ride_name += " (" + str(int(park_details["rides"][ride_index]["wait_time"])) + "min)"

                if park_details["rides"][ride_index]["wait_time"] <= little_or_no_wait_max_minutes:
                    wait_times.append(render.WrappedText(content = ride_name, font = selected_font, color = COLOR_GREEN))
                elif park_details["rides"][ride_index]["wait_time"] <= moderate_wait_max_minutes:
                    wait_times.append(render.WrappedText(content = ride_name, font = selected_font, color = COLOR_YELLOW))
                else:
                    wait_times.append(render.WrappedText(content = ride_name, font = selected_font, color = COLOR_RED))

                wait_times.append(render.Box(width = 64, height = pixels_between_rides))
            elif show_closed_rides:
                wait_times.append(render.WrappedText(content = park_details["rides"][ride_index]["name"], font = selected_font, color = COLOR_GRAY))
                wait_times.append(render.Box(width = 64, height = pixels_between_rides))

        if at_least_one_ride_open:
            wait_times.append(render.Box(width = 64, height = 1))
        else:
            wait_times.clear()
            wait_times.append(render.WrappedText(content = park_name, font = selected_font))
            wait_times.append(render.WrappedText(content = "Park is closed", font = selected_font, color = COLOR_GRAY))

        return render.Root(
            delay = 100,
            show_full_animation = True,
            child = render.Column(
                children = [
                    render.Marquee(
                        height = 32,
                        width = 64,
                        offset_start = 32,
                        scroll_direction = "vertical",
                        child = render.Column(
                            main_align = "space_between",
                            children = wait_times,
                        ),
                    ),
                ],
            ),
        )

def get_operator_logo(operator_name):
    """Attempts to retrieve a logo image for a given park operator name

    Args:
        operator_name: A park operator name

    Returns:
        The park operator logo if available, otherwise a 1x1 box
    """
    if operator_name == "Cedar Fair Entertainment Company":
        return render.Image(src = ICON_CEDAR_FAIR)
    elif operator_name == "SeaWorld Parks \u0026 Entertainment":
        return render.Image(src = ICON_SEA_WORLD)
    elif operator_name == "Six Flags Entertainment Corporation":
        return render.Image(src = ICON_SIX_FLAGS)
    elif operator_name == "Universal Parks \u0026 Resorts":
        return render.Image(src = ICON_UNIVERSAL)
    elif operator_name == "Walt Disney Attractions":
        return render.Image(src = ICON_DISNEY)
    else:
        return render.Box(height = 1, width = 1)

def get_http_data(url):
    """Attempts to retrieve JSON data from a remote URL

    Args:
        url: The url to retrieve JSON data from

    Returns:
        JSON data from the specified url
    """
    res = http.get(url, ttl_seconds = CACHE_TIME_SECONDS)
    if res.status_code != 200:
        fail("GET %s failed with status %d: %s", url, res.status_code, res.body())
    return res.json()

def get_schema():
    """App configuration

    Returns:
        Application configuration options
    """
    park_json = get_http_data(PARKS_URL)
    parks = []
    parks.append(schema.Option(display = "None", value = "0"))

    for x in range(len(park_json)):
        for y in range(len(park_json[x]["parks"])):
            parks.append(schema.Option(display = park_json[x]["name"] + " - " + park_json[x]["parks"][y]["name"], value = str(int(park_json[x]["parks"][y]["id"]))))

    little_or_no_wait_options = []
    for minutes in range(1, 60):
        little_or_no_wait_options.append(schema.Option(display = str(minutes), value = str(minutes)))

    moderate_wait_options = []
    for minutes in range(1, 120):
        moderate_wait_options.append(schema.Option(display = str(minutes), value = str(minutes)))

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "park",
                name = "Park",
                desc = "The park to retrieve wait times for.",
                icon = "gear",
                default = DEFAULT_PARK,
                options = parks,
            ),
            schema.Toggle(
                id = "show_actual_wait_times",
                name = "Show Actual Wait Times",
                desc = "A toggle to enable showing actual wait times",
                icon = "clock",
                default = DEFAULT_SHOW_ACTUAL_WAIT_TIMES,
            ),
            schema.Toggle(
                id = "show_closed_rides",
                name = "Show Closed Rides",
                desc = "A toggle to enable showing or hiding closed rides",
                icon = "gear",
                default = DEFAULT_SHOW_CLOSED_RIDES,
            ),
            schema.Dropdown(
                id = "little_or_no_wait_max_minutes",
                name = "Little Or No Wait Max Minutes",
                desc = "The max minutes a wait is considered little wait",
                icon = "clock",
                default = DEFAULT_LITTLE_OR_NO_WAIT_MAX_MINUTES,
                options = little_or_no_wait_options,
            ),
            schema.Dropdown(
                id = "moderate_wait_options",
                name = "Moderate Wait Max Minutes",
                desc = "The max minutes a wait is considered moderate",
                icon = "clock",
                default = DEFAULT_MODERATE_WAIT_MAX_MINUTES,
                options = moderate_wait_options,
            ),
            schema.Dropdown(
                id = "font",
                name = "Font",
                desc = "Select font",
                icon = "font",
                default = DEFAULT_FONT,
                options = [
                    schema.Option(
                        display = "10x20",
                        value = "10x20",
                    ),
                    schema.Option(
                        display = "5x8",
                        value = "5x8",
                    ),
                    schema.Option(
                        display = "6x13",
                        value = "6x13",
                    ),
                    schema.Option(
                        display = "CG-pixel-3x5-mono",
                        value = "CG-pixel-3x5-mono",
                    ),
                    schema.Option(
                        display = "CG-pixel-4x5-mono",
                        value = "CG-pixel-4x5-mono",
                    ),
                    schema.Option(
                        display = "Dina_r400-6",
                        value = "Dina_r400-6",
                    ),
                    schema.Option(
                        display = "tb-8",
                        value = "tb-8",
                    ),
                    schema.Option(
                        display = "tom-thumb",
                        value = "tom-thumb",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "pixels_between_rides",
                name = "Pixel Buffer",
                desc = "Pixels to pad between rides displayed",
                icon = "buffer",
                default = DEFAULT_PIXELS_BETWEEN_RIDES,
                options = [
                    schema.Option(
                        display = "0",
                        value = "0",
                    ),
                    schema.Option(
                        display = "1",
                        value = "1",
                    ),
                    schema.Option(
                        display = "2",
                        value = "2",
                    ),
                    schema.Option(
                        display = "3",
                        value = "3",
                    ),
                    schema.Option(
                        display = "4",
                        value = "4",
                    ),
                    schema.Option(
                        display = "5",
                        value = "5",
                    ),
                    schema.Option(
                        display = "6",
                        value = "6",
                    ),
                    schema.Option(
                        display = "7",
                        value = "7",
                    ),
                    schema.Option(
                        display = "8",
                        value = "8",
                    ),
                    schema.Option(
                        display = "9",
                        value = "9",
                    ),
                    schema.Option(
                        display = "10",
                        value = "10",
                    ),
                ],
            ),
        ],
    )
