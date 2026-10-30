"""
Applet: Javelexi
Summary: Javelexi Animation
Description: An animated javelina girl who is happy to see you!
Author: Nicholas Mejia
"""

load("images/javelexi.gif", JAVELEXI_ASSET = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")

JAVELEXI = JAVELEXI_ASSET.readall()

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
        child = (render.Box(width = canvas.width(), height = canvas.height(), child = render.Image(src = JAVELEXI))) if is_square() else render.Image(src = JAVELEXI),
    )

def get_schema():
    return schema.Schema(version = "1", fields = [])
