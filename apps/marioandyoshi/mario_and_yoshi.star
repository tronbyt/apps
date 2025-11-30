"""
Applet: Mario And Yoshi
Summary: Mario and Yoshi Gif
Description: A gif with Mario and Yoshi with text saying "It's a me, Mario".
Author: BriHen
"""

load("encoding/base64.star", "base64")
load("images/frame_0.png", FRAME_0_ASSET = "file")
load("images/frame_1.png", FRAME_1_ASSET = "file")
load("images/frame_2.png", FRAME_2_ASSET = "file")
load("images/frame_3.png", FRAME_3_ASSET = "file")
load("images/frame_4.png", FRAME_4_ASSET = "file")
load("images/frame_5.png", FRAME_5_ASSET = "file")
load("images/frame_6.png", FRAME_6_ASSET = "file")
load("render.star", "render")

FRAMES = [
    FRAME_0_ASSET.readall(),
    FRAME_1_ASSET.readall(),
    FRAME_2_ASSET.readall(),
    FRAME_3_ASSET.readall(),
    FRAME_4_ASSET.readall(),
    FRAME_5_ASSET.readall(),
    FRAME_6_ASSET.readall(),
]

def main():
    return render.Root(
        child = render.Animation(
            children = [render.Image(src = base64.decode(f)) for f in FRAMES],
        ),
    )
