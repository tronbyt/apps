"""
Applet: Shopify Animation
Summary: Displays fun animations
Description: Shoppy, the Shopify shopping bag would like to visit your TidByt.
Author: Shopify
"""

load("images/shoppy_animation.gif", SHOPPY_ANIMATION_ASSET = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")

SHOPPY_ANIMATION = SHOPPY_ANIMATION_ASSET.readall()

def is_square():
    """True on a 64x64 panel.

    Panels are told apart by SHAPE, never by size: the 128x64 wide panel is
    also 64 tall.
    """
    w, h = canvas.size()
    return h == w

def main():
    return render.Root(
        # Centre the block on the square (64x64); other panels unchanged.
        (render.Box(width = canvas.width(), height = canvas.height(), child = render.Image(SHOPPY_ANIMATION))) if is_square() else render.Image(SHOPPY_ANIMATION),
        delay = 120,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
