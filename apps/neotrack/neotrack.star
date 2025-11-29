"""
Applet: NEOTrack
Summary: Near Earth Object Tracker
Description: Shows the closest object on approach to Earth today according to NASA's NeoW API.
Author: brettohland
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/asteroid.gif", ASTEROID_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

ASTEROID = ASTEROID_ASSET.readall()

CACHE_KEY = "neo_response"

def main(config):
    # NASA's API requires that the date be in a specific format
    today = humanize.time_format("yyyy-MM-dd", time.now())

    # Check the cace for data before proceeding. The cache is set with a TTL of 1 day (in seconds)
    cached_response = cache.get(CACHE_KEY)
    if cached_response != None:
        print("Returning cached data")
        data = json.decode(cached_response)
    else:
        print("Fetching data")
        data = fetch_and_cache_neos(today, config)

    neos = data["near_earth_objects"][today]

    # Sort by the closest approach data's astronomicl units measurement. We want the closest number.
    closest_neo = sorted(neos, key = lambda x: x["close_approach_data"][0]["miss_distance"]["astronomical"])[0]

    # Generate the display name
    name = "Asteroid" + closest_neo["name"]

    # Get the estimated max diameter value (for dramatic effect)
    diameter_km = closest_neo["estimated_diameter"]["kilometers"]["estimated_diameter_max"]

    # Figure out if KM or M are going to fit in a 5 character length
    km_string = str(diameter_km)[:3]  # First 3 characters because "KM" is two characters.

    # Only use the metre value if the diameter is smaller than 0.1 KM
    if km_string == "0.0":
        diameter_m = closest_neo["estimated_diameter"]["meters"]["estimated_diameter_max"]
        m_string = str(diameter_m)[:4]
        m_string = strip_trailing_zeros(m_string)
        diameter = m_string + "M"
    else:
        km_string = strip_trailing_zeros(km_string)
        diameter = km_string + "KM"

    # Hazardous colour border
    potentially_hazardous = closest_neo["is_potentially_hazardous_asteroid"]
    if potentially_hazardous:
        border_color = "#F60"
    else:
        border_color = "#0F0"

    # Velocity display
    relative_velocity = closest_neo["close_approach_data"][0]["relative_velocity"]["kilometers_per_second"]
    velocity_string = str(relative_velocity)[:3] + "K/s"

    # Miss distance
    miss_distance = closest_neo["close_approach_data"][0]["miss_distance"]["lunar"]
    miss_distance_string = strip_trailing_zeros(miss_distance[:4]) + "LU"

    # Orbiting Body
    orbiting_body = closest_neo["close_approach_data"][0]["orbiting_body"]

    return render.Root(
        child = render.Row(
            children = [
                render_image_and_scale(border_color, diameter),
                render.Padding(
                    pad = (2, 0, 0, 0),
                    child = render.Column(
                        children = [
                            make_data_scroll(None, name),
                            make_data_scroll("V:", velocity_string),
                            make_data_scroll("D:", miss_distance_string),
                            make_data_scroll("O:", orbiting_body),
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
                id = "api_key",
                name = "NASA API Key",
                desc = "NASA API key for NeoW API.",
                icon = "key",
                secret = True,
            ),
        ],
    )

# Fetch data from NASA's API, cache the result.
def fetch_and_cache_neos(today_string, config):
    base_url = "https://api.nasa.gov/neo/rest/v1/feed"
    today = today_string
    api_key = config.get("api_key") or "DEMO_KEY"  # NASA's demo key has a 50 req/hr limit.
    final_url = base_url + "?start_date=" + today + "&end_date=" + today + "&api_key=" + api_key
    response = http.get(final_url)
    if response.status_code != 200:
        fail("Call to NASA API failed", base_url)
    data = response.json()

    # TODO: Determine if this cache call can be converted to the new HTTP cache.
    cache.set(CACHE_KEY, json.encode(data), ttl_seconds = 86400)
    return data

# Creates the data display component with the prefix (fixed) and the data (scrolling)
def make_data_scroll(prefix, data_string):
    font = "5x8"
    if prefix == None:
        width = 42
    else:
        width = 33
    return render.Row(
        children = [
            render.Text(prefix or "", font = font),
            render.Marquee(
                width = width,
                align = "end",
                child = render.Text(data_string, font = font),
            ),
        ],
    )

# Builds out the righthand column with the image of the asteroid, and scale.
def render_image_and_scale(highlight_color, size_string):
    return render.Column(
        expanded = True,
        # main_align = "end",
        children = [
            render.Box(width = 1, height = 1),
            render.Stack(
                children = [
                    render.Box(width = 20, height = 20, color = highlight_color),
                    render.Padding(
                        pad = 1,
                        child = render.Image(ASTEROID, width = 18, height = 18),
                    ),
                ],
            ),
            render.Box(width = 1, height = 2),
            render.Row(
                children = [
                    render.Box(width = 1, height = 2, color = "#fff"),
                    render.Column(
                        children = [
                            render.Box(width = 18, height = 1, color = "#000"),
                            render.Box(width = 18, height = 1, color = "#FFF"),
                        ],
                    ),
                    render.Box(width = 1, height = 2, color = "#fff"),
                ],
            ),
            render.Padding(
                pad = (0, 1, 0, 0),
                child = render.Marquee(
                    width = 20,
                    align = "center",
                    child = render.Text(size_string, font = "CG-pixel-3x5-mono"),
                ),
            ),
        ],
    )

# Convets numerical strings with trailing zero characters ("0") to whole numbers.
# eg. "8.00" becomes "8", "9.01" will remain "9.01".
def strip_trailing_zeros(value):
    # Loop through and remove any and all trailing "0" characters
    for _ in range(len(value)):
        value = value.removesuffix("0")

    # Remove a trailing decimal separator if present
    value = value.removesuffix(".")
    return value
