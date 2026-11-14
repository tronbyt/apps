"""
Applet: Minecraft Art
Summary: Display Minecraft Paintings
Description: Cycles through all 4x2 Minecraft paintings like an art gallery.
Author: Michael Maxwell
"""

load("images/changing.png", CHANGING_ASSET = "file")
load("images/fighters.png", FIGHTERS_ASSET = "file")
load("images/finding.png", FINDING_ASSET = "file")
load("images/lowmist.png", LOWMIST_ASSET = "file")
load("images/passage.png", PASSAGE_ASSET = "file")
load("render.star", "render")

CHANGING = CHANGING_ASSET.readall()
FIGHTERS = FIGHTERS_ASSET.readall()
FINDING = FINDING_ASSET.readall()
LOWMIST = LOWMIST_ASSET.readall()
PASSAGE = PASSAGE_ASSET.readall()

def main():
    return render.Root(
        delay = 3000,
        child = render.Box(
            child = render.Animation(
                children = [
                    render.Image(
                        src = FIGHTERS,
                        width = 64,
                        height = 32,
                    ),
                    render.Image(
                        src = CHANGING,
                        width = 64,
                        height = 32,
                    ),
                    render.Image(
                        src = FINDING,
                        width = 64,
                        height = 32,
                    ),
                    render.Image(
                        src = LOWMIST,
                        width = 64,
                        height = 32,
                    ),
                    render.Image(
                        src = PASSAGE,
                        width = 64,
                        height = 32,
                    ),
                ],
            ),
        ),
    )
