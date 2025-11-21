"""
Applet: Archer Dog
Summary: Archer Dog Animation
Description: Displays our favorite dog, Archer!
Author: Jeremy Harnden
"""

load("images/1.png", FRAME1 = "file")
load("images/2.png", FRAME2 = "file")
load("images/3.png", FRAME3 = "file")
load("images/4.png", FRAME4 = "file")
load("images/5.png", FRAME5 = "file")
load("images/6.png", FRAME6 = "file")
load("images/7.png", FRAME7 = "file")
load("images/8.png", FRAME8 = "file")
load("render.star", "render")
load("schema.star", "schema")

FRAMES = [f.readall() for f in [FRAME1, FRAME2, FRAME3, FRAME4, FRAME5, FRAME6, FRAME7, FRAME8]]

def main():
    return render.Root(
        child = render.Animation(
            children = [render.Image(src = f) for f in FRAMES],
        ),
    )

def get_schema():
    return schema.Schema(version = "1", fields = [])
