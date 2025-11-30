"""
Applet: Party Parrot
Summary: Animated party parrot
Description: 12 different party parrots to choose from.
Author: tobyxdd
"""

load("images/img_28055a15.gif", IMG_28055a15_ASSET = "file")
load("images/img_36a3ea86.gif", IMG_36a3ea86_ASSET = "file")
load("images/img_3bea0be5.gif", IMG_3bea0be5_ASSET = "file")
load("images/img_5b92a5a1.gif", IMG_5b92a5a1_ASSET = "file")
load("images/img_68d959ca.gif", IMG_68d959ca_ASSET = "file")
load("images/img_b4062861.gif", IMG_b4062861_ASSET = "file")
load("images/img_bf57ad70.gif", IMG_bf57ad70_ASSET = "file")
load("images/img_d0c28740.gif", IMG_d0c28740_ASSET = "file")
load("images/img_d0fe078e.gif", IMG_d0fe078e_ASSET = "file")
load("images/img_de666e51.gif", IMG_de666e51_ASSET = "file")
load("images/img_f139e258.gif", IMG_f139e258_ASSET = "file")
load("images/img_f9caea9d.gif", IMG_f9caea9d_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

GIFs = {
    "normal": IMG_de666e51_ASSET.readall(),
    "fast": IMG_d0fe078e_ASSET.readall(),
    "stoked": IMG_f139e258_ASSET.readall(),
    "sassy": IMG_68d959ca_ASSET.readall(),
    "meld": IMG_f9caea9d_ASSET.readall(),
    "thug": IMG_bf57ad70_ASSET.readall(),
    "conga": IMG_36a3ea86_ASSET.readall(),
    "moonwalk": IMG_d0c28740_ASSET.readall(),
    "pair": IMG_5b92a5a1_ASSET.readall(),
    "usa": IMG_28055a15_ASSET.readall(),
    "cloud": IMG_b4062861_ASSET.readall(),
    "blob": IMG_3bea0be5_ASSET.readall(),
}

def main(config):
    gif = GIFs[config.str("type", "normal")]
    return render.Root(
        render.Box(
            child = render.Image(src = gif),
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = "Normal",
            value = "normal",
        ),
        schema.Option(
            display = "Fast",
            value = "fast",
        ),
        schema.Option(
            display = "Stoked",
            value = "stoked",
        ),
        schema.Option(
            display = "Sassy",
            value = "sassy",
        ),
        schema.Option(
            display = "Meld",
            value = "meld",
        ),
        schema.Option(
            display = "Thug life",
            value = "thug",
        ),
        schema.Option(
            display = "Conga line",
            value = "conga",
        ),
        schema.Option(
            display = "Moonwalk",
            value = "moonwalk",
        ),
        schema.Option(
            display = "Pair",
            value = "pair",
        ),
        schema.Option(
            display = "USA",
            value = "usa",
        ),
        schema.Option(
            display = "Cloud",
            value = "cloud",
        ),
        schema.Option(
            display = "Blob",
            value = "blob",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "type",
                name = "Type",
                desc = "Choose your parrot",
                icon = "feather",
                default = options[0].value,
                options = options,
            ),
        ],
    )
