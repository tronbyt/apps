"""
Applet: Mario And Yoshi
Summary: Mario and Yoshi Gif
Description: A gif with Mario and Yoshi with text saying "It's a me, Mario".
Author: BriHen
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("images/img_15344a36.png", IMG_15344a36_ASSET = "file")
load("images/img_48f2d107.png", IMG_48f2d107_ASSET = "file")
load("images/img_89e723ea.png", IMG_89e723ea_ASSET = "file")
load("images/img_b1f8eed9.png", IMG_b1f8eed9_ASSET = "file")
load("images/img_cc9e5fc9.png", IMG_cc9e5fc9_ASSET = "file")
load("images/img_cd34ad5f.png", IMG_cd34ad5f_ASSET = "file")
load("images/img_d89d10ba.png", IMG_d89d10ba_ASSET = "file")

FRAMES = [
    IMG_48f2d107_ASSET.readall(),
    IMG_d89d10ba_ASSET.readall(),
    IMG_15344a36_ASSET.readall(),
    IMG_b1f8eed9_ASSET.readall(),
    IMG_cc9e5fc9_ASSET.readall(),
    IMG_cd34ad5f_ASSET.readall(),
    IMG_89e723ea_ASSET.readall(),
]

def main():
    return render.Root(
        child = render.Animation(
            children = [render.Image(src = base64.decode(f)) for f in FRAMES],
        ),
    )
