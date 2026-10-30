"""
Applet: Homer Hiding
Summary: A simple gif of Homer hide
Description: This iconic awkward Simpsons moment appears in season five, episode 16, “Homer Loves Flanders”; it’s Homer’s reaction to finding out that the Flanders family wants some non-Homer time to themselves.
Author: masonwongcs
"""

load("images/animation.gif", ANIMATION_ASSET = "file")
load("render.star", "canvas", "render")

ANIMATION = ANIMATION_ASSET.readall()

# Original video can be found here:
# https://www.pexels.com/video/cold-relaxing-winter-photography-6507518/
#
# The liscense can be found here:
# https://www.pexels.com/license/

def main():
    return render.Root(
        # Centre the block on taller panels (64x64).
        child = render.Box(width = canvas.width(), height = canvas.height(), child = render.Image(src = ANIMATION)),
    )
