"""
Applet: Shopify Animation
Summary: Displays fun animations
Description: Shoppy, the Shopify shopping bag would like to visit your TidByt.
Author: Shopify
"""

load("images/shoppy_animation.gif", SHOPPY_ANIMATION_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

SHOPPY_ANIMATION = SHOPPY_ANIMATION_ASSET.readall()

def main():
    return render.Root(
        render.Image(SHOPPY_ANIMATION),
        delay = 120,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
