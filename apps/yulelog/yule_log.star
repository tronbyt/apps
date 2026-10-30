"""
Applet: Yule Log
Summary: A pixel fireplace
Description: A pixel fireplace to add some warmth to your Tidbyt.
Author: Tidbyt
"""

load("images/animation.gif", ANIMATION_ASSET = "file")
load("images/slowfire.webp", SLOWFIRE_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

# Original video can be found here:
# https://www.pexels.com/video/cold-relaxing-winter-photography-6507518/
#
# The liscense can be found here:
# https://www.pexels.com/license/

def main(config):
    fire_choice = config.get("fire_choice", "fast")

    animation_data = ANIMATION if fire_choice == "fast" else SLOWFIRE

    return render.Root(
        child = render.Image(src = animation_data),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "fire_choice",
                name = "Fire Animation",
                desc = "Choose which fire animation to display",
                icon = "fire",
                default = "fast",
                options = [
                    schema.Option(
                        display = "Fast Fire",
                        value = "fast",
                    ),
                    schema.Option(
                        display = "Slow Fire",
                        value = "slow",
                    ),
                ],
            ),
        ],
    )

SLOWFIRE = SLOWFIRE_ASSET.readall()

ANIMATION = ANIMATION_ASSET.readall()
