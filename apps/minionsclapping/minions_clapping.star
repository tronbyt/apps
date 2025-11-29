"""
Applet: Minions Clapping
Summary: Animation of minions
Description: A fun animation showing minions clapping enthusiastically.
Author: mal5z
"""

load("images/frame1.png", FRAME1_ASSET = "file")
load("images/frame10.png", FRAME10_ASSET = "file")
load("images/frame2.png", FRAME2_ASSET = "file")
load("images/frame3.png", FRAME3_ASSET = "file")
load("images/frame4.png", FRAME4_ASSET = "file")
load("images/frame5.png", FRAME5_ASSET = "file")
load("images/frame6.png", FRAME6_ASSET = "file")
load("images/frame7.png", FRAME7_ASSET = "file")
load("images/frame8.png", FRAME8_ASSET = "file")
load("images/frame9.png", FRAME9_ASSET = "file")
load("render.star", "render")

FRAME1 = FRAME1_ASSET.readall()
FRAME10 = FRAME10_ASSET.readall()
FRAME2 = FRAME2_ASSET.readall()
FRAME3 = FRAME3_ASSET.readall()
FRAME4 = FRAME4_ASSET.readall()
FRAME5 = FRAME5_ASSET.readall()
FRAME6 = FRAME6_ASSET.readall()
FRAME7 = FRAME7_ASSET.readall()
FRAME8 = FRAME8_ASSET.readall()
FRAME9 = FRAME9_ASSET.readall()

DEFAULT_WHO = "world"

def main():
    return render.Root(
        delay = 100,
        child = render.Animation(
            children = [
                render.Image(src = FRAME1),
                render.Image(src = FRAME2),
                render.Image(src = FRAME3),
                render.Image(src = FRAME4),
                render.Image(src = FRAME5),
                render.Image(src = FRAME6),
                render.Image(src = FRAME7),
                render.Image(src = FRAME8),
                render.Image(src = FRAME9),
                render.Image(src = FRAME10),
            ],
        ),
    )
