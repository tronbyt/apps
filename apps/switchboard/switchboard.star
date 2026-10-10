"""
Applet: Switchboard
Summary: Display Switchboard data
Description: Displays data from Switchboard on your Tidbyt.
Author: bguggs
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/sb_icon.png", SB_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

SB_ICON = SB_ICON_ASSET.readall()

BASE_API_URL = "https://secure.oneswitchboard.com/api/handle_tidbyt/"

LOGO_WIDTH = 16
LOGO_HEIGHT = 16
FULL_WIDTH = 64
FULL_HEIGHT = 32

DEFAULT_LOCATION = """
    {
        "lat": "40.6781784",
        "lng": "-73.9441579",
        "description": "Brooklyn, NY, USA",
        "locality": "Brooklyn",
        "place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
        "timezone": "America/New_York"
    }
"""  # From https://github.com/tidbyt/pixlet/blob/main/examples/sunrise.star, works as a default for us too

def render_failure(failure_message, current_time_str):
    return render_layout(failure_message, current_time_str, FULL_WIDTH)

def render_top_row(top_text = ""):
    return render.Row(
        children = [
            render.Row(children = [render.Image(src = SB_ICON)]),
            render.Box(
                render.Row(
                    expanded = True,
                    children = [
                        render.Box(
                            render.Text(top_text),
                        ),
                    ],
                ),
                height = FULL_HEIGHT - LOGO_HEIGHT,
                width = FULL_WIDTH - LOGO_WIDTH,
            ),
        ],
    )

def render_bottom_row(marquee_text, thermometer_width):
    return render.Stack(
        children = [
            render.Box(height = LOGO_HEIGHT, color = "#00054d", width = thermometer_width),
            render.Row(
                children = [
                    render.Box(
                        render.Marquee(
                            align = "start",
                            width = FULL_WIDTH,
                            child = render.Text(marquee_text, color = "#FFF"),
                        ),
                        height = LOGO_HEIGHT,
                        width = FULL_WIDTH,
                    ),
                ],
            ),
        ],
    )

def render_layout(marquee_text, top_text, thermometer_width):
    return render.Root(
        child = render.Box(
            child = render.Column(
                expanded = True,
                cross_align = "start",
                children = [
                    render_top_row(top_text),
                    render_bottom_row(marquee_text, int(thermometer_width)),
                ],
            ),
        ),
    )

def main(config):
    # Load config values
    sb_api_token = config.get("sb_api_token") or ""
    location = config.get("location", DEFAULT_LOCATION)
    timezone = json.decode(location)["timezone"]

    # Format current time early for failure rendering
    current_time_str = time.now().in_location(timezone).format("3:04 PM")

    if not sb_api_token:
        return render_failure("API TOKEN REQUIRED", current_time_str)

    # Load layout data
    res = http.get(BASE_API_URL, auth = ("Switchboard", sb_api_token), ttl_seconds = 60)
    if res.status_code != 200:
        # Something went wrong with the API request
        return render_failure("REQUEST FAILED: " + str(res.status_code), current_time_str)

    # Store the retrieved data in cache
    res_json = res.json()

    # Retrieve values from json blob
    marquee_text = res_json.get("marquee_text")
    top_text = res_json.get("top_text")
    thermometer_width = res_json.get("thermometer_width")

    # Use some sensible defaults
    if not top_text:
        # Show current time
        top_text = current_time_str
    if not thermometer_width:
        # Use full width
        thermometer_width = FULL_WIDTH
    if not marquee_text:
        marquee_text = "Welcome to your Tidbyt Switchboard display"

    return render_layout(marquee_text, top_text, thermometer_width)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "sb_api_token",
                name = "Switchboard API Token",
                desc = "The API Token found in your Organization Settings",
                icon = "key",
                secret = True,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "locationDot",
            ),
        ],
    )
