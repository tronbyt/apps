"""
Applet: LaunchCountdown
Summary: Displays next world launch
Description: Displays the next rocket launch in the world.
Author: Robert Ison
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/rocket_icon.png", ROCKET_ICON_ASSET = "file")
load("images/rocket_icon_b.png", ROCKET_ICON_B_ASSET = "file")
load("images/rocket_icon_c.png", ROCKET_ICON_C_ASSET = "file")
load("images/rocket_icon_d.png", ROCKET_ICON_D_ASSET = "file")
load("images/rocket_icon_e.png", ROCKET_ICON_E_ASSET = "file")
load("images/rocket_icon_f.png", ROCKET_ICON_F_ASSET = "file")
load("images/rocket_icon_g.png", ROCKET_ICON_G_ASSET = "file")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

ROCKET_ICON = ROCKET_ICON_ASSET.readall()
ROCKET_ICON_B = ROCKET_ICON_B_ASSET.readall()
ROCKET_ICON_C = ROCKET_ICON_C_ASSET.readall()
ROCKET_ICON_D = ROCKET_ICON_D_ASSET.readall()
ROCKET_ICON_E = ROCKET_ICON_E_ASSET.readall()
ROCKET_ICON_F = ROCKET_ICON_F_ASSET.readall()
ROCKET_ICON_G = ROCKET_ICON_G_ASSET.readall()

#Constants
ROCKET_LAUNCH_URL = "https://fdo.rocketlaunch.live/json/launches/next/5"
ROCKET_LAUNCH_CACHE_NAME = "LaunchCountdownCache"
MINIMUM_CACHE_TIME_IN_SECONDS = 600
MAXIMUM_CACHE_TIME_IN_SECONDS = 400000

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

#Rocket Icons to loop through

period_options = [
    schema.Option(value = "1", display = "1 hour"),
    schema.Option(value = "2", display = "2 hours"),
    schema.Option(value = "3", display = "3 hours"),
    schema.Option(value = "4", display = "4 hours"),
    schema.Option(value = "5", display = "5 hours"),
    schema.Option(value = "6", display = "6 hours"),
    schema.Option(value = "12", display = "12 hours"),
    schema.Option(value = "24", display = "1 day"),
    schema.Option(value = "48", display = "2 days"),
    schema.Option(value = "72", display = "3 days"),
    schema.Option(value = "168", display = "1 week"),
    schema.Option(value = "0", display = "Always Display Next Sighting if known"),
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

#Get the json from cache, or download a new copy and save that in cache
def get_rocket_launch_json():
    """ Get the Rocket Launch json from the API call

    Returns:
        The json info
    """
    cached_encoded_json = cache.get(ROCKET_LAUNCH_CACHE_NAME)
    if (cached_encoded_json != None):
        rocket_launch_data = json.decode(cached_encoded_json)
    else:
        rocket_launch_data = None

    if (rocket_launch_data == None):
        rocket_launch_http = http.get(ROCKET_LAUNCH_URL)

        if rocket_launch_http.status_code != 200:
            fail("RocketLaunch.live feed failed: %d", rocket_launch_http.status_code)
        else:
            rocket_launch_data = rocket_launch_http.json()

            if (rocket_launch_data != None):
                window_open_text = rocket_launch_data["result"][0]["win_open"]
                cache_time_seconds = MINIMUM_CACHE_TIME_IN_SECONDS
                if window_open_text != None:
                    #Current Json doesn't include seconds and throws error when parsing
                    if (len(window_open_text) == 17):
                        window_open_text = window_open_text.replace("Z", ":00Z")

                    #If the JSON feed updates to include the seconds, or if the fix above did it,
                    #we'll parse the time now
                    window_open_time = None
                    if (len(window_open_text) == 20):
                        window_open_time = time.parse_time(window_open_text)

                    if (window_open_time != None):
                        date_diff = window_open_time - time.now().in_location("GMT")

                        days = math.floor(date_diff.hours // 24)
                        hours = math.floor(date_diff.hours - days * 24)
                        minutes = math.floor(date_diff.minutes - (days * 24 * 60 + hours * 60))
                        seconds_this_json_is_valid_for = minutes * 60 + hours * 60 * 60 + days * 24 * 60 * 60

                        cache_time_seconds = seconds_this_json_is_valid_for

                cache_time_seconds = max(MINIMUM_CACHE_TIME_IN_SECONDS, min(MAXIMUM_CACHE_TIME_IN_SECONDS, cache_time_seconds))

                cache.set(ROCKET_LAUNCH_CACHE_NAME, json.encode(rocket_launch_data), ttl_seconds = cache_time_seconds)
                # Filter out any providers in ignoredProviders

    return (rocket_launch_data)

def filter_rocket_launches(rocket_launch_data, filter_for_providers_string, filter_for_countries_string):
    """ Filter Included Providers and Countries
    Args:
        rocket_launch_data: the rocket launch data with all the info on future launches
        filter_for_providers_string: comma separated list of providers to filter for
        filter_for_countries_string: comma separated list of countries to filter for
    Returns:
        rocket_launch_data but only with the included providers & countries
    """
    included_providers = [provider.strip().lower() for provider in filter_for_providers_string.split(",")] if filter_for_providers_string.strip() else []
    included_countries = [country.strip().lower() for country in filter_for_countries_string.split(",")] if filter_for_countries_string.strip() else []

    if not included_providers and not included_countries:  # if both lists are empty, return all data
        return rocket_launch_data

    filtered_data = [
        launch
        for launch in rocket_launch_data["result"]
        if (not included_providers or launch["provider"]["name"].lower() in included_providers) and
           (not included_countries or launch["pad"]["location"]["country"].lower() in included_countries)
    ]

    rocket_launch_data["result"] = filtered_data
    return rocket_launch_data

#Since not all launches supply values for all these, this makes it easy to add items to a marquee
def get_launch_details(rocket_launch_data, locallaunch):
    """ Get Launch Details
    Args:
        rocket_launch_data: the rocket launch data with all the info on future launches
    Returns:
        Display info of launch details
    """

    #SpaceX has a launch pad called launch pad ... looks stupid to display that.
    pad_name = None if rocket_launch_data["pad"]["name"] == "Launch Pad" else rocket_launch_data["pad"]["name"]

    countdownDisplay = ""

    potential_display_items = [
        rocket_launch_data["provider"]["name"],
        pad_name,
        rocket_launch_data["pad"]["location"]["name"],
        rocket_launch_data["pad"]["location"]["state"],
        rocket_launch_data["pad"]["location"]["country"],
    ]

    if locallaunch != None:
        countdown = (locallaunch - time.now())
        potential_display_items.append(locallaunch.format("Monday Jan 2 2006"))
        potential_display_items.append(locallaunch.format("3:04 PM MST"))

        if countdown.hours >= 1.5:
            whole_hours = math.floor(countdown.hours)
            countdownDisplay = ("In %s %s %s minutes, " % (int(whole_hours), "hours" if whole_hours > 1 else "hour", int(math.round(countdown.minutes - (whole_hours * 60)))))
        elif countdown.minutes > 0:
            countdownDisplay = ("%s minutes from now, " % int(math.round(countdown.minutes)))

    display_items_format = [
        "%s will launch",
        "from %s",
        "%s",
        "in %s",
        "%s",
        "on %s",
        "at %s",
    ]

    display_text = countdownDisplay

    for i in range(len(potential_display_items)):
        if (potential_display_items[i] != None):
            display_text += " " + (display_items_format[i] % potential_display_items[i]).strip()

    return display_text

def display_instructions(config):
    ##############################################################################################################################################################################################################################
    instructions_1 = "Launch information is provided by RocketLaunch.live. You can filter these results by country or provider. "
    instructions_2 = "Examples of country include 'United States', 'Canada' and 'China'. Examples of provider include 'NASA', 'SpaceX', 'ABL Space' and 'Virgin Galactic'."
    instructions_3 = "The country and provider information should appear in the third row of information of each upcoming flight."
    app_title = "Launch Countdown"

    return render.Root(
        render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    child = render.Text(app_title, color = "#65d0e6", font = "5x8"),
                ),
                render.Marquee(
                    width = 64,
                    offset_start = len(app_title) * 5,
                    child = render.Text(instructions_1, color = "#f4a306"),
                ),
                render.Marquee(
                    offset_start = len(instructions_1) * 5,
                    width = 64,
                    child = render.Text(instructions_2, color = "#f4a306"),
                ),
                render.Marquee(
                    offset_start = (len(instructions_2) + len(instructions_1)) * 5,
                    width = 64,
                    child = render.Text(instructions_3, color = "#f4a306"),
                ),
            ],
        ),
        delay = int(config.get("scroll", 45)),
        show_full_animation = True,
    )

def replace_local_time_into_description(description, local_time, utc_time):
    if local_time == None or utc_time == None:
        return description

    # Get timezone abbreviation like "EST" directly from local_time
    timezone_abbr = local_time.format("MST")

    # Extract individual time components that work reliably
    utc_hour_raw = utc_time.format("15")  # 18 (24hr)
    utc_min_raw = utc_time.format("04")  # 03
    utc_hour_12 = int(utc_hour_raw) % 12  # 6
    if utc_hour_12 == 0:
        utc_hour_12 = 12
    utc_ampm = "PM" if int(utc_hour_raw) >= 12 else "AM"

    local_hour_raw = local_time.format("15")  # 13 (24hr)
    local_min_raw = local_time.format("04")  # 03
    local_hour_12 = int(local_hour_raw) % 12  # 1
    if local_hour_12 == 0:
        local_hour_12 = 12
    local_ampm = "PM" if int(local_hour_raw) >= 12 else "AM"

    # Build exact strings to match/replace
    utc_part = "%d:%s\u202f%s (UTC)" % (utc_hour_12, utc_min_raw, utc_ampm)
    local_part = "%d:%s %s (%s)" % (local_hour_12, local_min_raw, local_ampm, timezone_abbr)

    return description.replace(utc_part, local_part)

def main(config):
    show_instructions = config.bool("instructions", False)
    hide_when_nothing_to_display = config.bool("hide", True)

    if show_instructions:
        return display_instructions(config)

    # 1. Initialize variables
    row1 = ""
    row2 = ""
    row3 = ""
    row4 = ""

    location = json.decode(config.get("location", default_location))
    rocket_launch_data = get_rocket_launch_json()

    # 2. Filter data
    rocket_launch_data = filter_rocket_launches(rocket_launch_data, config.get("filter_for_providers", ""), config.get("filter_for_countries", ""))
    rocket_launch_count = len(rocket_launch_data["result"]) if rocket_launch_data else 0

    if rocket_launch_data == None:
        row1 = "Error"
        row2 = "API Feed Failed"
    elif rocket_launch_count == 0:
        row1 = "No Launches"
        row2 = "Filtered or None"
    else:
        # 3. Process the first available launch
        for i in range(0, rocket_launch_count):
            localtime = time.now().in_location(location["timezone"])
            launch_item = rocket_launch_data["result"][i]

            t0 = launch_item.get("t0")
            win_open = launch_item.get("win_open")
            utc_t0 = None

            # Handle time parsing safely
            if t0 != None:
                utc_t0 = time.parse_time(t0.replace("Z", ":00Z"))
            elif win_open != None:
                utc_t0 = time.parse_time(win_open.replace("Z", ":00Z"))

            if utc_t0 != None:
                locallaunch = utc_t0.in_location(location["timezone"])

                # Notice Period Logic
                hours_notice = int(config.get("notice_period", period_options[-1].value))  # Default to 1 hour
                hours_until = (locallaunch - localtime).hours

                if (hours_notice == 0 or hours_notice > hours_until):
                    row1 = launch_item["vehicle"]["name"]
                    row2 = locallaunch.format("Jan 2 '06")
                    row3 = get_launch_details(launch_item, locallaunch)
                    row4 = replace_local_time_into_description(launch_item["launch_description"], locallaunch, utc_t0)
                    break  # Found a valid launch to show
            else:
                # Fallback for launches with no specific time (Estimated dates)
                month_names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
                row1 = launch_item["vehicle"]["name"]
                est = launch_item["est_date"]
                if est["month"] != None and est["day"] != None:
                    row2 = "%s %s '%s" % (month_names[int(est["month"]) - 1], est["day"], str(est["year"])[-2:])
                row3 = get_launch_details(launch_item, None).strip()
                row4 = launch_item["launch_description"].strip()
                break

    # 4. Final Blank Screen Guard & Notice Period Message
    if row1 == "":
        if hide_when_nothing_to_display:
            return []

        # Lookup the display name for the notice period
        selected_val = config.get("notice_period", "1")
        display_name = "1 hour"  # Default
        for opt in period_options:
            if opt.value == selected_val:
                display_name = opt.display
                break

        row1 = "No launches found"
        row2 = "within %s" % display_name

    # 5. Render (Keep your existing render.Root code here)

    delay = int(config.get("scroll", 45))
    if canvas.is2x:
        delay = int(delay / 2)

    return render.Root(
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
        child = render.Column(
            children = [
                render.Column(
                    children = [
                        render.Row(
                            children = [
                                render.Column(
                                    children = [
                                        render.Marquee(width = canvas.width() - 16, child = render.Text(row1, color = "#65d0e6")),
                                        render.Marquee(width = canvas.width() - 16, child = render.Text(row2, color = "#FFFFFF")),
                                    ],
                                ),
                                render.Animation(
                                    children = [render.Image(src = ROCKET_ICON), render.Image(src = ROCKET_ICON_B), render.Image(src = ROCKET_ICON_C), render.Image(src = ROCKET_ICON_D), render.Image(src = ROCKET_ICON_E), render.Image(src = ROCKET_ICON_F), render.Image(src = ROCKET_ICON_G)],
                                ),
                            ],
                        ),
                    ],
                ),
                render.Marquee(width = canvas.width(), child = render.Text(row3, color = "#fff")),
                render.Marquee(width = canvas.width(), child = render.Text(row4, color = "#ff0")),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location to calculate local launch time.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "notice_period",
                name = "Notice Period",
                desc = "Display when launch is within...",
                icon = "userClock",
                options = period_options,
                default = period_options[-1].value,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
            schema.Text(
                id = "filter_for_providers",
                name = "Only Show these providers",
                desc = "Comma Seperated List of Providers to Show",
                icon = "industry",
            ),
            schema.Text(
                id = "filter_for_countries",
                name = "Only Show these countries",
                desc = "Comma Seperated List of Countries to Show",
                icon = "globe",
            ),
            schema.Toggle(
                id = "hide",
                name = "Hide if no data?",
                desc = "",
                icon = "gear",
                default = True,
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
