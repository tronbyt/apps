"""
Applet: SpotTheStation
Summary: Next ISS visit overhead
Description: Displays the next time the International Space Station will appear.
Author: Robert Ison
"""

load("encoding/json.star", "json")
load("http.star", "http")  #HTTP Client
load("images/iss_icon.png", ISS_ICON_ASSET = "file")
load("images/iss_icon2.png", ISS_ICON2_ASSET = "file")
load("images/iss_icon3.png", ISS_ICON3_ASSET = "file")
load("images/iss_icon4.png", ISS_ICON4_ASSET = "file")
load("images/iss_icon5.png", ISS_ICON5_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

ISS_ICON = ISS_ICON_ASSET.readall()
ISS_ICON2 = ISS_ICON2_ASSET.readall()
ISS_ICON3 = ISS_ICON3_ASSET.readall()
ISS_ICON4 = ISS_ICON4_ASSET.readall()
ISS_ICON5 = ISS_ICON5_ASSET.readall()

CACHE_DURATION = 1 * 86400  # 86400 seconds = 1 days

SPACE_STATION_ID = 25544
STATION_LOCATION_API = "https://api.n2yo.com/rest/v1/satellite/visualpasses/{space_station_id}/{latitude}/{longitude}/0/10/60/&apiKey={api_key}"

SAMPLE_DATA = """{"info":{"satid":25544,"satname":"SPACE STATION","transactionscount":2,"passescount":1},"passes":[{"startAz":332.18,"startAzCompass":"NNW","startEl":2.54,"startUTC":1767095020,"maxAz":40.05,"maxAzCompass":"NE","maxEl":19.95,"maxUTC":1767095320,"endAz":107.07,"endAzCompass":"ESE","endEl":0.3,"endUTC":1767095615,"mag":-0.4,"duration":555,"startVisibility":1767095060}]}"""

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

def magnitude_description(mag):
    if mag < -3:
        return "extremely bright, like Venus"
    elif mag < -1:
        return "very bright, brighter than any star"
    elif mag < 0:
        return "bright and easy to spot"
    elif mag < 2:
        return "clearly visible to the naked eye"
    elif mag < 4:
        return "visible in dark skies"
    elif mag < 6:
        return "faint but observable"
    else:
        return "very faint (binoculars recommended)"

def is_within_notice_period(startUTC, endUTC, current_time, hours):
    notice_seconds = hours * 3600
    return (startUTC >= current_time and startUTC <= current_time + notice_seconds) or \
           (startUTC <= current_time and endUTC >= current_time)

def format_duration_display(seconds):
    total_secs = int(seconds)
    hours = total_secs // 3600
    minutes = (total_secs % 3600) // 60
    secs = total_secs % 60

    if hours > 0:
        return str(hours) + " hours, " + str(minutes) + " minutes, " + str(secs) + " seconds"
    elif minutes > 0:
        if secs > 0:
            return str(minutes) + " minutes and " + str(secs) + " seconds"
        else:
            return str(minutes) + " minutes"
    else:
        return str(secs) + " seconds"

def two_character_time_date_part(number):
    if len(str(number)) == 1:
        return "0" + str(number)
    else:
        return number

def two_character_numeric_month_from_month_string(month):
    dict = {
        "Jan": "01",
        "Feb": "02",
        "Mar": "03",
        "Apr": "04",
        "May": "05",
        "Jun": "06",
        "Jul": "07",
        "Aug": "08",
        "Sep": "09",
        "Oct": "10",
        "Nov": "11",
        "Dec": "12",
    }

    return dict.get(month)

def get_local_time(config):
    timezone = json.decode(config.get("location", DEFAULT_LOCATION))["timezone"]
    local_time = time.now().in_location(timezone)
    return local_time

def main(config):
    """ Main

    Args:
        config: Configuration Items to control how the app is displayed
    Returns:
        The display inforamtion for the Tidbyt
    """

    # Display Instructions and end if that's the setting
    show_instructions = config.bool("instructions", False)
    if show_instructions:
        return display_instructions()

    # Get Configuration Environment Data
    location = json.decode(config.get("location", DEFAULT_LOCATION))
    current_time = time.now().unix  # get current UTC time

    # Get Configuration Items
    api_key = config.get("api_key", None)
    minimum_duration = int(config.get("minimum_duration", 0))
    notice_hours = int(config.get("notice_period", 0))
    minimum_maxEl = int(config.get("minimum_elevation", 10))

    # Set Defaults
    sighting_to_display = None
    is_sample_data = True
    station_data = json.decode(SAMPLE_DATA)

    # If we have an API key, let's get real data
    if api_key:
        resp = http.get(STATION_LOCATION_API.format(space_station_id = SPACE_STATION_ID, latitude = location["lat"], longitude = location["lng"], api_key = api_key), ttl_seconds = CACHE_DURATION)

        resp_json = resp.json()
        if resp.status_code == 200 and "error" not in resp_json:
            is_sample_data = False
            station_data = resp_json
        else:
            # Notify that their API failed
            error_msg = resp_json.get("error", resp.status_code)
            return render.Root(
                child=render.Marquee(
                    width=64,
                    child=render.Text("API request failed: {}".format(error_msg))
                )
            )

    if station_data and "passes" in station_data:
        passes = station_data["passes"]
        if passes and len(passes) > 0:
            for p in passes:
                # 1️⃣ Check duration
                if "duration" in p and int(p["duration"]) >= minimum_duration:
                    # 2️⃣ Check notice window
                    if notice_hours == 0 or is_within_notice_period(p["startUTC"], p["endUTC"], current_time, notice_hours):
                        # 3️⃣ Check max elevation
                        if "maxEl" in p and p["maxEl"] >= minimum_maxEl:
                            # This pass meets all criteria
                            sighting_to_display = p
                            break  # stop at first qualifying pass

    if sighting_to_display == None:
        return []
    else:
        event_start_time = time.from_timestamp(int(sighting_to_display["startUTC"]), 0).in_location(time.tz())

        details_text = "ISS appears from the {}, peaks at {}° in the {} for {} and disappears in the {}, {}.".format(
            sighting_to_display["startAzCompass"],
            int(sighting_to_display["maxEl"]),
            sighting_to_display["maxAzCompass"],
            format_duration_display(sighting_to_display["duration"]),
            sighting_to_display["endAzCompass"],
            magnitude_description(sighting_to_display["mag"]),
        )
        display_text = ("Sample: " if is_sample_data else "") + details_text

        print(display_text)

        return get_display(format_locality(location["locality"], 10) if "locality" in location else "Unknown", event_start_time.format("3:04 PM"), event_start_time.format("Jan 2, 2006"), display_text, config)

def format_locality(locality, idealLength):
    """Format locality: full string if <= idealLength, else town name before first comma."""
    if len(locality) <= idealLength:
        return locality

    # No commas? Return full string
    if "," not in locality:
        return locality

    # Return everything before first comma (town name)
    return locality.split(",")[0].strip()

def display_instructions():
    ##############################################################################################################################################################################################################################
    title = "Spot the Station"
    instructions_1 = "Goto N2yo.com and create a free account. Then go to 'More Stuff', then 'Edit/change your location'."
    instructions_2 = "Create your API key here and use it in your configuration as your N2YO.com API Key"
    instructions_3 = "You can adjust settings to be made aware of the passes you can see, and how early you're made aware of them."
    return render.Root(
        render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    child = render.Text(title, color = "#65d0e6", font = "5x8"),
                ),
                render.Marquee(
                    offset_start = len(title) * 5,
                    width = 64,
                    child = render.Text(instructions_1, color = "#f4a306"),
                ),
                render.Marquee(
                    offset_start = (len(title) + len(instructions_1)) * 5,
                    width = 64,
                    child = render.Text(instructions_2, color = "#f4a306"),
                ),
                render.Marquee(
                    offset_start = (len(title) + len(instructions_1) + len(instructions_2)) * 5,
                    width = 64,
                    child = render.Text(instructions_3, color = "#f4a306"),
                ),
            ],
        ),
        show_full_animation = True,
    )

def get_display(location, row1, row2, row3, config):
    return render.Root(
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
        child = render.Column(
            children = [
                render.Column(
                    children = [
                        render.Row(
                            children = [
                                render.Animation(
                                    children = [
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON2),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON3),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON4),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON5),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON5),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON5),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON5),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON5),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON4),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON3),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON2),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON),
                                        render.Image(src = ISS_ICON),
                                    ],
                                ),
                                render.Column(
                                    children = [
                                        render.Marquee(
                                            width = 48,
                                            child = render.Text(location, color = "#0099FF"),
                                        ),
                                        render.Marquee(
                                            width = 35,
                                            child = render.Text(row1, color = "#fff"),
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(row2, color = "#fff"),
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(row3, color = "#ff0"),
                ),
            ],
        ),
    )

def get_schema():
    notice_period_options = [
        schema.Option(value = "1", display = "1 hour"),
        schema.Option(value = "2", display = "2 hours"),
        schema.Option(value = "3", display = "3 hours"),
        schema.Option(value = "4", display = "4 hours"),
        schema.Option(value = "5", display = "5 hours"),
        schema.Option(value = "12", display = "12 hours"),
        schema.Option(value = "24", display = "1 day"),
        schema.Option(value = "48", display = "2 days"),
        schema.Option(value = "72", display = "3 days"),
        schema.Option(value = "168", display = "1 week"),
        schema.Option(value = "0", display = "Always Display Next Sighting if known"),
    ]

    minimum_duration_options = [
        schema.Option(value = "60", display = "1 minute"),
        schema.Option(value = "120", display = "2 minutes"),
        schema.Option(value = "180", display = "3 minutes"),
        schema.Option(value = "240", display = "4 minutes"),
        schema.Option(value = "300", display = "5 minutes"),
        schema.Option(value = "360", display = "6 minutes"),
        schema.Option(value = "420", display = "7 minutes"),
        schema.Option(value = "480", display = "8 minutes"),
        schema.Option(value = "540", display = "9 minutes"),
        schema.Option(value = "600", display = "10 minutes"),
        schema.Option(value = "0", display = "Display regardless of duration"),
    ]

    minimum_degrees_above_horizon = [
        schema.Option(value = "5", display = "Very low passes near horizon or higher"),
        schema.Option(value = "20", display = "Moderate elevation or higher"),
        schema.Option(value = "40", display = "High passes, easily visible"),
        schema.Option(value = "60", display = "Very high passes, right overhead"),
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
            schema.Text(
                id = "api_key",
                name = "N2YO.com API Key",
                icon = "locationArrow",
                desc = "Get a free N2YO.com account. Go to More Stuff, then Edit Location. Create your API key here.",
                secret = True,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location needed to calculate local time and get pass information for your location.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "notice_period",
                name = "Notice Period",
                desc = "Display when sighting is within...",
                icon = "userClock",
                options = notice_period_options,
                default = notice_period_options[len(notice_period_options) - 1].value,
            ),
            schema.Dropdown(
                id = "minimum_duration",
                name = "Minimum Duration",
                desc = "Display sightings that are at least...",
                icon = "stopwatch",
                options = minimum_duration_options,
                default = minimum_duration_options[len(minimum_duration_options) - 1].value,
            ),
            schema.Dropdown(
                id = "minimum_elevation",
                name = "Types of Passes",
                desc = "What types of passes do you want to be notified of?",
                icon = "mountainSun",
                options = minimum_degrees_above_horizon,
                default = minimum_degrees_above_horizon[0].value,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "scroll",
                options = scroll_speed_options,
                default = scroll_speed_options[1].value,
            ),
            schema.Toggle(
                id = "instructions",
                name = "Display Instructions",
                desc = "",
                icon = "book",  #"info",
                default = False,
            ),
        ],
    )
