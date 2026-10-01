"""
Applet: Isaac Dance
Summary: Isaac Specialist Dance
Description: This app presents the character Isaac from the franchise The Binding of Isaac doing the popular specialist dance.
Author: Dylan Nashawaty
"""

load("images/gif_content.gif", GIF_CONTENT_ASSET = "file")
load("render.star", "canvas", "render")

GIF_CONTENT = GIF_CONTENT_ASSET.readall()

def is_square():
    """True on a 64x64 panel.

    Panels are told apart by SHAPE, never by size: the 128x64 wide panel is
    also 64 tall.
    """
    w, h = canvas.size()
    return h == w

def main():
    image_instance = render.Image(src = GIF_CONTENT, width = 64, height = 32)

    # Centre the 64x32 animation on the square (64x64); other panels unchanged.
    return render.Root((render.Box(width = canvas.width(), height = canvas.height(), child = image_instance)) if is_square() else image_instance)
