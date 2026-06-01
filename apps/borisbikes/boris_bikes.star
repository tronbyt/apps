"""
Applet: Boris Bikes
Summary: London street bikes
Description: Availability for a Santander bicycle dock in London.
Author: dinosaursrarr
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/bike_image.png", BIKE_IMAGE_ASSET = "file")
load("images/lightning_image.png", LIGHTNING_IMAGE_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

BIKE_IMAGE = BIKE_IMAGE_ASSET.readall()
LIGHTNING_IMAGE = LIGHTNING_IMAGE_ASSET.readall()

# Unceremoniously nicked from Martin Strauss's baywheels app

# Hackney is for cycling.
DEFAULT_DOCK_ID = "BikePoints_614"

# Allows 500 queries per minute
LIST_DOCKS_URL = "https://api.tfl.gov.uk/BikePoint"
DOCK_URL = "https://api.tfl.gov.uk/BikePoint/%s"
USER_AGENT = "Tidbyt boris_bikes"

def app_key(config):
    return config.get("tfl_app_key") or ""  # Fall back to freebie quota

def fetch_docks(config):
    resp = http.get(
        LIST_DOCKS_URL,
        params = {
            "app_key": app_key(config),
        },
        headers = {
            "User-Agent": USER_AGENT,
        },
        ttl_seconds = 86400,  # Bike docks don't move often
    )
    if resp.status_code != 200:
        print("TFL BikePoint query failed with status ", resp.status_code)
        return None
    return resp.json()

# API gives errors when searching for locations outside the United Kingdom.
def outside_uk_bounds(loc):
    lat = float(loc["lat"])
    lng = float(loc["lng"])
    if lat <= 49.9 or lat >= 58.7 or lng <= -11.05 or lng >= 1.78:
        return True
    return False

def list_docks(location, config):
    loc = json.decode(location)
    if outside_uk_bounds(loc):
        return [schema.Option(
            display = "Default option - location is outside the UK",
            value = DEFAULT_DOCK_ID,
        )]

    docks = fetch_docks(config)
    if not docks:
        return []
    options = []
    for dock in docks:
        id = dock["id"]
        name = dock["commonName"]
        lat = dock["lat"]
        lon = dock["lon"]
        if None in (id, name, lat, lon):
            print("TFL Bikepoint query missing required field: ", dock)
            continue
        option = schema.Option(
            display = name,
            value = id,
        )
        distance = math.pow(lat - float(loc["lat"]), 2) + math.pow(lon - float(loc["lng"]), 2)
        options.append((option, distance))
    options = sorted(options, key = lambda x: x[1])
    return [option[0] for option in options]

def fetch_dock(dock_id, config):
    resp = http.get(
        DOCK_URL % dock_id,
        params = {
            "app_key": app_key(config),
        },
        headers = {
            "User-Agent": USER_AGENT,
        },
        ttl_seconds = 30,
    )
    if resp.status_code != 200:
        print("TFL BikePoint request failed with status ", resp.status_code)
        return None
    return resp.json()

def tidy_name(name):
    if not name:
        print("TFL BikePoint request did not contain dock name")
        return "Unknown dock"

    # Don't need the bit of town, user chose the location.
    comma = name.rfind(",")
    name = name[:comma].strip()

    # Abbreviate some common words to fit on screen better.
    words = name.split(" ")
    for i in range(len(words)):
        if words[i] == "Street":
            words[i] = "St"
        if words[i] == "Road":
            words[i] = "Rd"
        if words[i] == "Avenue":
            words[i] = "Ave"

    return " ".join(words)

def get_dock(dock_id, config):
    resp = fetch_dock(dock_id, config)
    if not resp:
        return "No data", "?", "?"
    name = tidy_name(resp["commonName"])
    acoustic_count = 0
    electric_count = 0
    for property in resp["additionalProperties"]:
        if property["key"] == "NbStandardBikes":
            acoustic_count = int(property["value"])
        if property["key"] == "NbEBikes":
            electric_count = int(property["value"])
    return name, acoustic_count, electric_count

def main(config):
    dock = config.get("dock")
    if dock:
        dock_id = json.decode(dock)["value"]
    else:
        dock_id = DEFAULT_DOCK_ID
    dock_name, acoustic_count, electric_count = get_dock(dock_id, config)

    return render.Root(
        max_age = 120,
        child = render.Stack(
            children = [
                render.Padding(
                    pad = (1, 0, 0, 0),
                    child = render.Marquee(
                        child = render.Text(dock_name),
                        scroll_direction = "horizontal",
                        width = 62,
                        height = 8,
                    ),
                ),

                # Bike picture
                render.Padding(
                    pad = (1, 7, 0, 0),
                    child = render.Image(BIKE_IMAGE),
                ),

                # Bike stats
                render.Padding(
                    pad = (44, 8, 0, 0),
                    child = render.Stack(
                        children = [
                            # Acoustic bikes
                            render.Padding(
                                pad = (9, 4, 0, 0),
                                child = render.WrappedText(
                                    content = "{}".format(acoustic_count),
                                    width = 10,
                                    align = "right",
                                ),
                            ),
                            # Electric bikes
                            render.Padding(
                                pad = (0, 14, 0, 0),
                                child = render.Image(
                                    src = LIGHTNING_IMAGE,
                                    width = 8,
                                    height = 8,
                                ),
                            ),
                            render.Padding(
                                pad = (9, 14, 0, 0),
                                child = render.WrappedText(
                                    content = "{}".format(electric_count),
                                    width = 10,
                                    align = "right",
                                ),
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "tfl_app_key",
                name = "TfL App Key",
                desc = "Your TfL app key. See https://api-portal.tfl.gov.uk/",
                icon = "key",
                secret = True,
            ),
            schema.LocationBased(
                id = "dock",
                name = "Dock",
                desc = "The bike dock to check capacity for",
                icon = "bicycle",
                handler = list_docks,
            ),
        ],
    )
