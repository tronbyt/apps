"""
Applet: Birdbyt
Summary: Show nearby bird sightings
Description: Displays a random bird sighting near a specific location.
Author: Becky Sweger
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/purple_bird_idle.gif", PURPLE_BIRD_IDLE_ASSET = "file")
load("images/purple_bird_jump.gif", PURPLE_BIRD_JUMP_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

PURPLE_BIRD_IDLE = PURPLE_BIRD_IDLE_ASSET.readall()
PURPLE_BIRD_JUMP = PURPLE_BIRD_JUMP_ASSET.readall()

EBIRD_URL = "https://api.ebird.org/v2"
MAX_API_RESULTS = "300"

# Config defaults
DEFAULT_LOCATION = {
    # Easthampton, MA
    "lat": "42.266",
    "lng": "-72.668",
    "timezone": "America/New_York",
}
DEFAULT_DISTANCE = "5"
DEFAULT_BACK = "2"
DEFAULT_PROVISIONAL = False

# When there are no birds
NO_BIRDS = {
    "bird": "No birds found",
    "loc": "Try increasing search distance",
}

def get_params(config):
    """Get params for e-birds request.

    Args:
      config: config dict passed from the app
    Returns:
      params: dict
    """

    params = {}

    location = config.get("location")
    loc = json.decode(location) if location else DEFAULT_LOCATION
    params["lat"] = loc["lat"]
    params["lng"] = loc["lng"]
    params["tz"] = loc["timezone"] if time.is_valid_timezone(loc["timezone"]) else DEFAULT_LOCATION["timezone"]

    params["dist"] = config.get("distance") or DEFAULT_DISTANCE
    params["back"] = config.get("back") or DEFAULT_BACK
    params["includeProvisional"] = str(config.get("provisional") or DEFAULT_PROVISIONAL)
    params["maxResults"] = MAX_API_RESULTS

    return params

def get_notable_sightings(params, ebird_key):
    """Request a list of recent notable bird sightings.

    Args:
      params: dictionary of parameters for the ebird API call
      ebird_key: ebird API key

    Returns:
      a list of notable sightings species codes
    """

    notable_params = params
    notable_params.pop("maxResults", None)

    ebird_recent_notable_route = "/data/obs/geo/recent/notable"
    url = EBIRD_URL + ebird_recent_notable_route
    headers = {"X-eBirdApiToken": ebird_key}

    response = http.get(url, params = params, headers = headers, ttl_seconds = 10800)
    log(ebird_recent_notable_route + " cache status " + response.headers.get("Tidbyt-Cache-Status"))

    # e-bird API request failed
    if response.status_code != 200:
        return []

    notable_sightings = response.json()
    notable_list = [s.get("speciesCode") for s in notable_sightings]
    log("number of notable sightings: " + str(len(notable_list)))

    return notable_list

def get_recent_birds(params, ebird_key):
    """Request a list of recent birds.

    Args:
      params: dictionary of parameters for the ebird API call
      ebird_key: ebird API key

    Returns:
      ebird sightings data
    """

    ebird_recent_obs_route = "/data/obs/geo/recent"
    url = EBIRD_URL + ebird_recent_obs_route
    headers = {"X-eBirdApiToken": ebird_key}

    log(ebird_recent_obs_route + " params: " + str(params))
    response = http.get(url, params = params, headers = headers, ttl_seconds = 10800)
    log(ebird_recent_obs_route + " cache status " + response.headers.get("Tidbyt-Cache-Status"))

    # e-bird API request failed
    if response.status_code != 200:
        return [{
            "comName": "Bird error!",
            "locName": "API status code = " + str(response.status_code),
        }]

    sightings = response.json()
    return sightings

def parse_birds(sightings, tz):
    """Parse ebird response data.

    Args:
      sightings: list of ebird sightings
      tz: application's timezone

    Returns:
      a dictionary representing a single bird sighting
    """

    sighting = {}

    number_of_sightings = len(sightings)
    log("number of sightings: " + str(number_of_sightings))

    # request succeeded, but no birds found
    if number_of_sightings == 0:
        sighting = NO_BIRDS
        return sighting

    # grab a random bird sighting from ebird response
    random_sighting = random.number(0, number_of_sightings - 1)
    data = sightings[random_sighting]

    sighting["bird"] = data.get("comName") or "Unknown bird"
    sighting["loc"] = data.get("locName") or "Location unknown"
    sighting["species"] = data.get("speciesCode") or "Unknown species code"
    if data.get("obsDt"):
        sighting["date"] = time.parse_time(data.get("obsDt"), format = "2006-01-02 15:04", location = tz)

    return sighting

def main(config):
    """Update config.

    Args:
      config: config dict passed from the app

    Returns:
      rendered WebP image for Tidbyt display
    """
    random.seed(time.now().unix // 10)

    ebird_key = config.get("ebird_api_key")
    if not ebird_key:
        ebird_key = "BIRDERROR-NO-API-KEY"
        log("unable to retrieve from local config")

    params = get_params(config)
    timezone = params.pop("tz")
    response = get_recent_birds(params, ebird_key)
    sighting = parse_birds(response, timezone)
    bird_formatted, bird_font = format_bird_name(sighting.get("bird"))

    # if this is a notable sighting, render an excitable bird
    notable_list = get_notable_sightings(params, ebird_key)
    if sighting.get("species") in notable_list:
        bird_image = PURPLE_BIRD_JUMP
        sighting["notable"] = True
    else:
        bird_image = PURPLE_BIRD_IDLE

    return render.Root(
        render.Column(
            children = [
                render.Row(
                    children = [
                        render.Column(
                            children = [
                                render.Box(
                                    width = 18,
                                    height = 25,
                                    child = render.Image(src = bird_image),
                                ),
                            ],
                        ),
                        render.Box(
                            height = 25,
                            padding = 1,
                            child = render.Marquee(
                                scroll_direction = "vertical",
                                align = "center",
                                height = 25,
                                child = render.WrappedText(
                                    align = "left",
                                    font = bird_font,
                                    content = bird_formatted,
                                ),
                            ),
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    cross_align = "end",
                    children = [
                        render.Box(
                            color = "043927",
                            child = render.Marquee(
                                width = 64,
                                child = render.Text(
                                    color = "fefbbd",
                                    font = "tom-thumb",
                                    offset = -1,
                                    content = get_scroll_text(sighting),
                                ),
                            ),
                        ),
                    ],
                ),
            ],
        ),
        show_full_animation = True,
    )

def get_schema():
    """Return the schema needed for Tidybyt community app installs.

    Returns:
      Tidbyt schema
    """

    list_back = ["1", "2", "3", "4", "5", "6"]
    options_back = [
        schema.Option(display = item, value = item)
        for item in list_back
    ]

    list_distance = ["1", "2", "5", "10", "25", "50"]
    options_distance = [
        schema.Option(display = item, value = item)
        for item in list_distance
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location to search for bird sightings.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "ebird_api_key",
                name = "eBird API Key",
                desc = "Enter your eBird API Key. Generate one at https://ebird.org/api/keygen",
                icon = "gear",
                secret = True,
            ),
            schema.Dropdown(
                id = "distance",
                name = "Search radius (km)",
                desc = "Search radius from location (km)",
                icon = "feather",
                default = DEFAULT_DISTANCE,
                options = options_distance,
            ),
            schema.Dropdown(
                id = "back",
                name = "Days back",
                desc = "Number of days back to fetch bird sightings.",
                icon = "calendarDays",
                default = DEFAULT_BACK,
                options = options_back,
            ),
            schema.Toggle(
                id = "provisional",
                name = "Include unverified",
                desc = "Include sightings not yet reviewed.",
                icon = "clipboardCheck",
                default = DEFAULT_PROVISIONAL,
            ),
        ],
    )

#------------------------------------------------------------------------
# Formatting functions for display text
#------------------------------------------------------------------------

def get_scroll_text(sighting):
    """Return a text string to scroll in the bottom marquee.

    Args:
      sighting: a dictionary representing a single bird sighting

    Returns:
      text to scroll at the bottom of the Tidbyt display
    """

    days = {
        0: "Sun",
        1: "Mon",
        2: "Tues",
        3: "Wed",
        4: "Thur",
        5: "Fri",
        6: "Sat",
    }

    sighting_date = sighting.get("date")

    if sighting_date:
        day_of_week = humanize.day_of_week(sighting_date)

        # local timezone should = bird sighting timezone since both are derived from location config
        sighting_day = "Today" if day_of_week == humanize.day_of_week(time.now()) else days[day_of_week]
        scroll_text = sighting_day + ": " + sighting.get("loc")
    else:
        scroll_text = sighting.get("loc")

    if sighting.get("notable"):
        scroll_text = "!Notable sighting! " + scroll_text

    return scroll_text

def format_bird_name(bird):
    """Format bird name for display.

    Args:
      bird: name of the bird returned from API

    Returns:
      bird name modified for Tidbyt display
      Tidbyt font to use for bird name display
    """

    # Hard code hyphens into bird names that exceed a single
    # line on the Tidbyt display. This is an incomplete list.
    log("bird name: " + bird)
    bird = bird.replace("Apostlebird", "Apostle-bird")
    bird = bird.replace("Australasian", "Austra-lasian")
    bird = bird.replace("Australian", "Austra-lian")
    bird = bird.replace("Blackburnian", "Black-burnian")
    bird = bird.replace("Butcherbird", "Butcher-bird")
    bird = bird.replace("Currawong", "Curra-wong")
    bird = bird.replace("Honeyeater", "Honey-eater")
    bird = bird.replace("Hummingbird", "Humming-bird")
    bird = bird.replace("Mockingbird", "Mocking-bird")
    bird = bird.replace("Yellowthroat", "Yellow-throat")
    bird = bird.replace("catcher", "-catcher")
    bird = bird.replace("pecker", "-pecker")
    bird = bird.replace("thrush", "-thrush")

    # Wrapped text widget doesn't break on a hyphen, so force a newline
    # if a hyphenated bird name will exceed 9 characters
    bird_parts = bird.split()
    split_bird = [
        b.replace("-", "-\n", 1) if len(b) > 9 else b
        for b in bird_parts
    ]
    bird = " ".join(split_bird)

    # Setting an explicit bird name font here lays groundwork for a future
    # enhancement that can return a smaller font when bird names are long
    # (9 letters is max size of a word that displays w/o cutting off)
    font = "tb-8"

    return bird, font

def log(message):
    """Format "log" messages for debugging.

    Args:
      message: base message to print
    """

    print(time.now(), " - ", message)  # buildifier: disable=print

#------------------------------------------------------------------------
# Assets
# (until Tidbyt/pixlet has the concept of a separate assets folder,
# images and gifs are stored in the .star file as encoded binary data)
#------------------------------------------------------------------------
