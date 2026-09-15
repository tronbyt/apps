"""
Applet: Jimothy
Summary: Run, Jimothy, run
Description: Displays an animated image of Jimothy running away.
Author: andyrak
"""

load("jimothy.gif", JIMOTHY_FILE = "file")
load("render.star", "canvas", "render")

JIMOTHY_GIF = JIMOTHY_FILE.readall("rb")

SCALE = 2 if canvas.is2x() else 1

def main():
    return render.Root(
        child = render.Image(
            src = JIMOTHY_GIF,
            width = 64 * SCALE,
            height = 32 * SCALE,
        ),
    )
