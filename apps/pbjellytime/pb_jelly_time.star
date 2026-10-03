"""
Applet: PB Jelly Time
Summary: Banana Dancing
Description: The Peanut Butter Jelly Time Dancing Banana.
Author: jay-medina
"""

load("images/banana.gif", BANANA_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_SPEED = 80

def main(config):
    speed = config.get("speed", DEFAULT_SPEED)

    return render.Root(
        delay = int(speed),
        child = render.Image(BANANA_ASSET.readall()),
    )

def get_schema():
    options = [
        schema.Option(
            display = "Normal",
            value = "100",
        ),
        schema.Option(
            display = "Fast",
            value = "80",
        ),
        schema.Option(
            display = "Fastest",
            value = "65",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "speed",
                name = "Dance Speed",
                desc = "The speed in which the banana dances",
                icon = "bolt",
                default = options[1].value,
                options = options,
            ),
        ],
    )
