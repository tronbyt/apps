"""
Applet: Acidwarp
Summary: Acidwarp
Description: Classic Acidwarp Animations.
Author: tavdog
"""

load("images/a1.webp", A1 = "file")
load("images/a10.webp", A10 = "file")
load("images/a11.webp", A11 = "file")
load("images/a12.webp", A12 = "file")
load("images/a13.webp", A13 = "file")
load("images/a2.webp", A2 = "file")
load("images/a3.webp", A3 = "file")
load("images/a4.webp", A4 = "file")
load("images/a5.webp", A5 = "file")
load("images/a6.webp", A6 = "file")
load("images/a7.webp", A7 = "file")
load("images/a8.webp", A8 = "file")
load("images/a9.webp", A9 = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

scenes = [A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13]

def main():
    scene = random.number(0, len(scenes) - 1)
    file = scenes[scene]
    return render.Root(
        render.Box(
            render.Image(
                src = file.readall(),
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
        ],
    )
