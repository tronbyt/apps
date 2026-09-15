"""
Applet: Peanuts Pictures
Summary: Peanuts Pixel Art
Description: Shows a specific or random pixel art piece of characters from the Peanuts comics series.
Author: michaelalbinson
"""

load("images/fancy_snoopy.png", FANCY_SNOOPY_ASSET = "file")
load("images/lucy_classic.png", LUCY_CLASSIC_ASSET = "file")
load("images/lucy_cool.png", LUCY_COOL_ASSET = "file")
load("images/red_barron.png", RED_BARRON_ASSET = "file")
load("images/snoopy_and_woodstock.png", SNOOPY_AND_WOODSTOCK_ASSET = "file")
load("images/snoopy_and_woodstock_walking.gif", SNOOPY_AND_WOODSTOCK_WALKING_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_SPEED = 500
OPT_RANDOM = "random"
OPT_FANCY_SNOOPY = "Fancy Snoopy"
OPT_LUCY_CLASSIC = "Lucy Classic"
OPT_LUCY_COOL = "Lucy Cool"
OPT_RED_BARRON = "Red Barron"
OPT_SNOOPY_AND_WOODSTOCK = "Snoopy and Woodstock"
OPT_SNOOPY_AND_WOODSTOCK_WALKING = "Snoopy and Woodstock Walking"
all_opts = [
    OPT_FANCY_SNOOPY,
    OPT_LUCY_CLASSIC,
    OPT_LUCY_COOL,
    OPT_RED_BARRON,
    OPT_SNOOPY_AND_WOODSTOCK,
    OPT_SNOOPY_AND_WOODSTOCK_WALKING,
]

def main(config):
    image_opt = config.get("image")
    if image_opt == OPT_RANDOM or image_opt == None:
        image_opt = all_opts[random.number(0, len(all_opts) - 1)]

    if OPT_FANCY_SNOOPY == image_opt:
        img_to_display = fancy_snoopy()
    elif OPT_LUCY_CLASSIC == image_opt:
        img_to_display = lucy_classic()
    elif OPT_LUCY_COOL == image_opt:
        img_to_display = lucy_cool()
    elif OPT_RED_BARRON == image_opt:
        img_to_display = red_barron()
    elif OPT_SNOOPY_AND_WOODSTOCK == image_opt:
        img_to_display = snoopy_and_woodstock()
    elif OPT_SNOOPY_AND_WOODSTOCK_WALKING == image_opt:
        img_to_display = snoopy_and_woodstock_walking()
    else:
        fail("Couldn't find an image to render")

    return render.Root(
        delay = int(DEFAULT_SPEED),
        child = render.Image(img_to_display),
    )

def fancy_snoopy():
    return FANCY_SNOOPY_ASSET.readall()

def lucy_classic():
    return LUCY_CLASSIC_ASSET.readall()

def lucy_cool():
    return LUCY_COOL_ASSET.readall()

def red_barron():
    return RED_BARRON_ASSET.readall()

def snoopy_and_woodstock():
    return SNOOPY_AND_WOODSTOCK_ASSET.readall()

def snoopy_and_woodstock_walking():
    return SNOOPY_AND_WOODSTOCK_WALKING_ASSET.readall()

def get_schema():
    options = [
        schema.Option(
            display = "Random",
            value = OPT_RANDOM,
        ),
        schema.Option(
            display = "Fancy Snoopy",
            value = OPT_FANCY_SNOOPY,
        ),
        schema.Option(
            display = "Lucy Classic",
            value = OPT_LUCY_CLASSIC,
        ),
        schema.Option(
            display = "Lucy Cool",
            value = OPT_LUCY_COOL,
        ),
        schema.Option(
            display = "Red Barron",
            value = OPT_RED_BARRON,
        ),
        schema.Option(
            display = "Snoopy and Woodstock",
            value = OPT_SNOOPY_AND_WOODSTOCK,
        ),
        schema.Option(
            display = "Snoopy and Woodstock Walking",
            value = OPT_SNOOPY_AND_WOODSTOCK_WALKING,
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "image",
                name = "Image",
                desc = "The image to display",
                icon = "bolt",
                default = options[0].value,
                options = options,
            ),
        ],
    )
