"""
Applet: Paraland
Summary: Shows hand drawn landscapes
Description: See cool hand drawn pixel art landscapes from your Tidbyt.
Author: yonodactyl
"""

load("images/arizona_day.gif", ARIZONA_DAY_ASSET = "file")
load("images/default_morning.gif", DEFAULT_MORNING_ASSET = "file")
load("images/north_carolina_morning.gif", NORTH_CAROLINA_MORNING_ASSET = "file")
load("images/seattle_morning.gif", SEATTLE_MORNING_ASSET = "file")

# LOAD MODULES
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

# MAIN
def main(config):
    # Grab the configuration information and adjust variables
    selected_img_id = config.get("image", DEFAULT_MORNING_ID)
    if selected_img_id == "random":
        image_keys = IMAGES.keys()
        idx = random.number(0, len(image_keys) - 1)  #-1 because indices start at zero
        selected_img_id = image_keys[idx]
    selected_img = IMAGES[selected_img_id]
    selected_speed = int(config.get("scroll_delay", DEFAULT_DELAY))

    # Render an image with a slight delay
    return render.Root(
        delay = selected_speed,
        child = render.Image(src = selected_img),
    )

def get_schema():
    # Landscape options
    options = [
        schema.Option(
            display = "Random",
            value = "random",
        ),
        schema.Option(
            display = "Default - Morning",
            value = DEFAULT_MORNING_ID,
        ),
        schema.Option(
            display = "North Carolina - Morning",
            value = NORTH_CAROLINA_MORNING_ID,
        ),
        schema.Option(
            display = "Seattle - Morning",
            value = SEATTLE_MORNING_ID,
        ),
        schema.Option(
            display = "Arizona - Day",
            value = ARIZONA_DAY_ID,
        ),
    ]

    # Speed options for the parallax
    speed_options = [
        schema.Option(
            display = "Default",
            value = "150",
        ),
        schema.Option(
            display = "Slow",
            value = "400",
        ),
        schema.Option(
            display = "Fast",
            value = "10",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "image",
                name = "Landscape",
                desc = "The Landscape GIF to be looped",
                icon = "mountain",
                default = options[1].value,
                options = options,
            ),
            schema.Dropdown(
                id = "scroll_delay",
                name = "Delay",
                desc = "The speed to scroll the landscape at",
                icon = "gauge",
                default = speed_options[0].value,
                options = speed_options,
            ),
        ],
    )

# CONFIG
DEFAULT_DELAY = "150"

# Image Constants
# This concent takes up a lot of realestate so anything below the fold here will just be Base64 Strings

# Arizona Desert - Day GIF

ARIZONA_DAY_ID = "arizona_day"
ARIZONA_DAY = ARIZONA_DAY_ASSET.readall()

# Seattle - Morning GIF

SEATTLE_MORNING_ID = "seattle_morning"
SEATTLE_MORNING = SEATTLE_MORNING_ASSET.readall()

# NC Blue Ridge Mountain - Morning GIF

NORTH_CAROLINA_MORNING_ID = "north_carolina_morning"
NORTH_CAROLINA_MORNING = NORTH_CAROLINA_MORNING_ASSET.readall()

# Default Image

DEFAULT_MORNING_ID = "default_morning"
DEFAULT_MORNING = DEFAULT_MORNING_ASSET.readall()

IMAGES = {
    ARIZONA_DAY_ID: ARIZONA_DAY,
    DEFAULT_MORNING_ID: DEFAULT_MORNING,
    NORTH_CAROLINA_MORNING_ID: NORTH_CAROLINA_MORNING,
    SEATTLE_MORNING_ID: SEATTLE_MORNING,
}
