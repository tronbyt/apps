"""
Applet: Nyan Cat
Summary: Nyan Cat Animation
Description: An animated cartoon cat with a Pop-Tart for a torso.
Author: Mack Ward
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")
load("images/img_0f4fd75a.png", IMG_0f4fd75a_ASSET = "file")
load("images/img_26549305.png", IMG_26549305_ASSET = "file")
load("images/img_4e3a2fbd.png", IMG_4e3a2fbd_ASSET = "file")
load("images/img_5caf1a56.png", IMG_5caf1a56_ASSET = "file")
load("images/img_67345d29.png", IMG_67345d29_ASSET = "file")
load("images/img_86b1422d.png", IMG_86b1422d_ASSET = "file")
load("images/img_88567051.png", IMG_88567051_ASSET = "file")
load("images/img_a1faa424.png", IMG_a1faa424_ASSET = "file")
load("images/img_b02bd9cb.png", IMG_b02bd9cb_ASSET = "file")
load("images/img_ba828c8e.png", IMG_ba828c8e_ASSET = "file")
load("images/img_e75f37bc.png", IMG_e75f37bc_ASSET = "file")
load("images/img_f19535da.png", IMG_f19535da_ASSET = "file")

FRAMES = [
    IMG_ba828c8e_ASSET.readall(),
    IMG_a1faa424_ASSET.readall(),
    IMG_b02bd9cb_ASSET.readall(),
    IMG_0f4fd75a_ASSET.readall(),
    IMG_f19535da_ASSET.readall(),
    IMG_e75f37bc_ASSET.readall(),
    IMG_26549305_ASSET.readall(),
    IMG_86b1422d_ASSET.readall(),
    IMG_88567051_ASSET.readall(),
    IMG_67345d29_ASSET.readall(),
    IMG_5caf1a56_ASSET.readall(),
    IMG_4e3a2fbd_ASSET.readall(),
]

def main():
    return render.Root(
        child = render.Animation(
            children = [render.Image(src = base64.decode(f)) for f in FRAMES],
        ),
    )

def get_schema():
    return schema.Schema(version = "1", fields = [])
