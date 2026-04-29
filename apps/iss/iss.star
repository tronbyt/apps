"""
Applet: ISS
Summary: Show next ISS pass
Description: Displays the time, starting direction and magnitude of the next International Space Station visible pass.
Author: Diogo Ribeiro Machado @ diogodh
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/eye_img.png", EYE_IMG_ASSET = "file")
load("images/iss_img.png", ISS_IMG_ASSET = "file")
load("images/mag_img.png", MAG_IMG_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

EYE_IMG = EYE_IMG_ASSET.readall()
ISS_IMG = ISS_IMG_ASSET.readall()
MAG_IMG = MAG_IMG_ASSET.readall()

DEFAULT_LOCATION = """
{
    "lat": 38.736946,
    "lng": -9.142685,
    "locality": "Lisbon, PT",
    "timezone": "GMT"
} """

DEFAULT_24_HOUR = True
MIN_ELEVATION = 10  # minimum elevation is 10º
MIN_MAGNITUDE = 1  # minimum magnitude is 1
ALTITUDE = 0  # location altitude
SAT_ID = "25544"  # ISS code
NUM_DAYS = "1"  # passes for the next 2 days
MIN_DURATION = "10"  # minimum time of visible pass

def main(config):
    api_key = config.get("n2yo_api_key")
    ttl_time = 5200
    display24hour = config.bool("24_hour", DEFAULT_24_HOUR)
    location = json.decode(config.get("location", DEFAULT_LOCATION))
    lat = float(location["lat"])
    lng = float(location["lng"])
    timezone = location["timezone"]

    url = "https://api.n2yo.com/rest/v1/satellite/visualpasses/%s/%s/%s/%s/%s/%s/&apiKey=%s" % (SAT_ID, lat, lng, ALTITUDE, NUM_DAYS, MIN_DURATION, api_key)

    data = get_data(url, ttl_time)

    if "error" in data:
        return render.Root(
            child = render.WrappedText("API error", align = "center", font = "tb-8", color = "#FF0000"),
        )

    else:
        filtered_passes = [pass_data for pass_data in data["passes"] if pass_data["maxEl"] > MIN_ELEVATION and pass_data["mag"] < MIN_MAGNITUDE]

    if filtered_passes:  # Check if there are any filtered passes
        # Take information only from the first pass
        first_pass_data = filtered_passes[0]
        utc_time_seconds = int(first_pass_data["startUTC"])  # Convert to integer
        ttl_time = utc_time_seconds - time.now().unix + 2
        start_compass = first_pass_data["startAzCompass"]
        magnitude = first_pass_data["mag"]

        # Convert UTC time to human-readable format
        utc_time = time.from_timestamp(utc_time_seconds)
        final_time = utc_time.in_location(timezone)

        if display24hour:
            time_human_readable = final_time.format("15:04")  # Adjust format string
        else:
            time_human_readable = final_time.format("3:04 PM")  # Adjust format string

        col1 = render.Column(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Image(src = ISS_IMG),
                render.Image(src = MAG_IMG),
                render.Image(src = EYE_IMG),
            ],
        )

        col2 = render.Column(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",  # Center align text vertically
            children = [
                render.Text("%s" % time_human_readable, color = "#FF0000", font = "tb-8"),
                render.Text("%s" % start_compass, color = "#FFFFFF", font = "tb-8"),
                render.Text("%s" % magnitude, color = "#FFFF00", font = "tb-8"),
            ],
        )

        return render.Root(
            child = render.Row(
                main_align = "center",
                cross_align = "center",
                children = [
                    col1,
                    render.Box(child = col2, width = 46),
                ],
            ),
        )
    else:
        # No filtered passes found
        ttl_time = 86400
        return render.Root(
            child = render.WrappedText("No passes found", align = "center", font = "tb-8", color = "#FF0000"),
        )

def get_data(url, ttl_time):
    res = http.get(url, ttl_seconds = ttl_time)  # cache for 1 hour
    if res.status_code != 200:
        fail("GET %s failed with status %d: %s", url, res.status_code, res.body())
    return res.json()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display the ISS passes.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "n2yo_api_key",
                name = "N2YO API Key",
                desc = "A N2YO API key to access the N2YO API.",
                icon = "key",
                secret = True,
            ),
            schema.Toggle(
                id = "24_hour",
                name = "24 hour clock",
                desc = "Display the time in 24 hour format.",
                icon = "clock",
            ),
        ],
    )
