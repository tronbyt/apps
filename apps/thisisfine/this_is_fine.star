"""
Applet: This Is Fine
Summary: This Is Fine meme
Description: A meme based on a webcomic series Gunshow illustrated by K.C. Green.
Author: zhaostu
"""

load("images/frame1.png", FRAME1_ASSET = "file")
load("images/frame2.png", FRAME2_ASSET = "file")
load("images/frame3.png", FRAME3_ASSET = "file")
load("render.star", "render")

FRAME1 = FRAME1_ASSET.readall()
FRAME2 = FRAME2_ASSET.readall()
FRAME3 = FRAME3_ASSET.readall()

def main():
    return render.Root(
        child = render.Animation(
            children = [
                render.Image(src = FRAME1),
                render.Image(src = FRAME2),
                render.Image(src = FRAME3),
            ],
        ),
        delay = 4000,
    )
