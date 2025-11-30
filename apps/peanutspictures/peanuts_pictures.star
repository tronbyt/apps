"""
Applet: Peanuts Pictures
Summary: Peanuts Pixel Art
Description: Shows a specific or random pixel art piece of characters from the Peanuts comics series.
Author: michaelalbinson
"""

load("encoding/base64.star", "base64")
load("images/fancy_snoopy.png", FANCY_SNOOPY_ASSET = "file")
load("images/lucy_classic.png", LUCY_CLASSIC_ASSET = "file")
load("images/lucy_cool.png", LUCY_COOL_ASSET = "file")
load("images/red_barron.png", RED_BARRON_ASSET = "file")
load("images/snoopy_and_woodstock.png", SNOOPY_AND_WOODSTOCK_ASSET = "file")
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
        child = render.Image(base64.decode(img_to_display)),
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
    return """
R0lGODlhQAAgAPIAAAAAAP/yAAC377S0tP///wAAAAAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQAMgD/ACwAAAAAQAAgAAAD
yyi63P4wyjmJtTTrva73nPOF0GdipHCi5LqG7tXGJkeP2TXsxND7OM0tSBkSZrxbahnR+YBEplT0mlqv2Ky2ARB0t2AAQfwFY8We
slmK/nTfaxKg7R6P45t52kLn4ylzdGh9d38SgTRtagxqi1eBhGl6hYwKX46PkDGKDwABc59mkJORfp0BqKiYU6OKJ6tenqqfsEut
F2R2sLKpvLUpkF64XsSHqcehW3OWMhq8x8t4nBmy1b9naRqhntePbs6WydKveaqGkd1e0CQJACH5BAAyAP8ALAAAAABAACAAAAPM
KLrc/jDKSau9mJG9s/8LJ4qgMpbaqBLg2n2um8WcR6/YfVbc4BMDYHBn0REpRtZMaEQ5Q5vf8PisxqoPgECL7ToABDDX6wWLxuSn
eaRtp0GANTscfmfi541cb7fE5WZ7dX0UfzdraAxoiVV/gmd4g4oKXIyNjjSIWQFxnG+OkY98mwGlnmSgiCuWlACmrnGooBxidKxb
pqWuurKxmm4Su7m8spQ1fsO6t1iaFbvPy12AFp6whAt70diUp4SP2tjE3qvIr9eBZ8664hcJACH5BAAyAP8ALAAAAABAACAAAAPI
KLrc/jDKGYm1NOu9rvec84XQZ2KkcKLkuobu1cYmR4/ZNezE0Ps4zS1IGRJmvFtqWbHwgESmVPSaWq/YrPYBEHS3YABB/AVjxZ6y
WYr+dN9rEqDtHo/jm3naQufjKXN0aH13fxKBNG1qDGqLV4GEaXqFjApfjo+QMYpcAXOeZpCTkX6dAaegW6KKJ5iWAKiwc6qiF2R2
rl6op7C8tLOccIe7u7lMs14yGr3EyHGcGb3SxlmCGqCyhslpy5apeJHUjL5/4cvFJAkAIfkEADIA/wAsAAAAAEAAIAAAA8woutz+
MMoZibU0672u95zzhdBnYqRwouS6hu7VxiZHj9k17MTQ+zjNLUgZEma8W2pZsfCARKZU9Jpar1aAQIvtOgAEMNfrBXvG5OxJy04v
AWaTOOwOwc+W+AVdl8D1Znp5fRl/NHF8C2iJWYYujolckm5/d497DwABcJuUlYGPEJoBpJ1kn4hrEZykmnCnn3ths4wKo6W3tUyV
W5htfqXBpmWSMhq3wa+EiMetrbplZxqdroSKH9AMksN9goPN3HXedIXJ1qCYFKPrJAkAOw==
"""

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
