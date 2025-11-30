"""
Applet: Nyan Cat
Summary: Nyan Cat Animation
Description: An animated cartoon cat with a Pop-Tart for a torso.
Author: Mack Ward
"""

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
