"""
Applet: Nyan Cat
Summary: Nyan Cat Animation
Description: An animated cartoon cat with a Pop-Tart for a torso.
Author: Mack Ward
"""

load("images/nyan_cat_frame_1.png", NYAN_CAT_FRAME_1_ASSET = "file")
load("images/nyan_cat_frame_10.png", NYAN_CAT_FRAME_10_ASSET = "file")
load("images/nyan_cat_frame_11.png", NYAN_CAT_FRAME_11_ASSET = "file")
load("images/nyan_cat_frame_12.png", NYAN_CAT_FRAME_12_ASSET = "file")
load("images/nyan_cat_frame_2.png", NYAN_CAT_FRAME_2_ASSET = "file")
load("images/nyan_cat_frame_3.png", NYAN_CAT_FRAME_3_ASSET = "file")
load("images/nyan_cat_frame_4.png", NYAN_CAT_FRAME_4_ASSET = "file")
load("images/nyan_cat_frame_5.png", NYAN_CAT_FRAME_5_ASSET = "file")
load("images/nyan_cat_frame_6.png", NYAN_CAT_FRAME_6_ASSET = "file")
load("images/nyan_cat_frame_7.png", NYAN_CAT_FRAME_7_ASSET = "file")
load("images/nyan_cat_frame_8.png", NYAN_CAT_FRAME_8_ASSET = "file")
load("images/nyan_cat_frame_9.png", NYAN_CAT_FRAME_9_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

FRAMES = [
    NYAN_CAT_FRAME_1_ASSET.readall(),
    NYAN_CAT_FRAME_2_ASSET.readall(),
    NYAN_CAT_FRAME_3_ASSET.readall(),
    NYAN_CAT_FRAME_4_ASSET.readall(),
    NYAN_CAT_FRAME_5_ASSET.readall(),
    NYAN_CAT_FRAME_6_ASSET.readall(),
    NYAN_CAT_FRAME_7_ASSET.readall(),
    NYAN_CAT_FRAME_8_ASSET.readall(),
    NYAN_CAT_FRAME_9_ASSET.readall(),
    NYAN_CAT_FRAME_10_ASSET.readall(),
    NYAN_CAT_FRAME_11_ASSET.readall(),
    NYAN_CAT_FRAME_12_ASSET.readall(),
]

def main():
    return render.Root(
        child = render.Animation(
            children = [render.Image(src = f) for f in FRAMES],
        ),
    )

def get_schema():
    return schema.Schema(version = "1", fields = [])
