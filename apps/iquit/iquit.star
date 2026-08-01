"""
Applet: HAIM's I Quit
Summary: HAIM's I Quit
Description: Based on the HAIM band's I Quit album cover
Author: Kyle Stark @kaisle51
"""

load("images/frame_1_ca5f1a79.png", FRAME_1_ca5f1a79_ASSET = "file")
load("images/frame_2_b469aea7.png", FRAME_2_b469aea7_ASSET = "file")
load("images/frame_3_84d79be5.png", FRAME_3_84d79be5_ASSET = "file")
load("images/frame_4_ac70f5ba.png", FRAME_4_ac70f5ba_ASSET = "file")
load("images/frame_5_cf5868e4.png", FRAME_5_cf5868e4_ASSET = "file")
load("images/frame_6_289fa720.png", FRAME_6_289fa720_ASSET = "file")
load("images/frame_7_4677f412.png", FRAME_7_4677f412_ASSET = "file")
load("images/frame_8_340c5e61.png", FRAME_8_340c5e61_ASSET = "file")
load("images/frame_9_5964adb8.png", FRAME_9_5964adb8_ASSET = "file")
load("render.star", "render")

def main():
    def getFrames(animationName):
        FRAMES = []
        for i in range(0, len(animationName[0])):
            FRAMES.extend([
                render.Column(
                    children = [
                        render.Box(
                            width = animationName[1],
                            height = animationName[2],
                            child = render.Image(animationName[0][i], width = animationName[1], height = animationName[2]),
                        ),
                    ],
                ),
            ])
        return FRAMES

    def getIQuit(animationName):
        setDelay(animationName)
        return render.Padding(
            pad = (animationName[3], animationName[4], 0, 0),
            child = render.Animation(
                getFrames(animationName),
            ),
        )

    def setDelay(animationName):
        FRAME_DELAY = animationName[5]
        return FRAME_DELAY

    def action():
        return IQUIT

    return render.Root(
        delay = setDelay(action()),
        child = render.Stack(
            children = [
                render.Box(
                    width = 64,
                    height = 32,
                ),
                getIQuit(action()),
            ],
        ),
    )

# Animation frames:
FRAME_1 = FRAME_1_ca5f1a79_ASSET.readall()
FRAME_2 = FRAME_2_b469aea7_ASSET.readall()
FRAME_3 = FRAME_3_84d79be5_ASSET.readall()
FRAME_4 = FRAME_4_ac70f5ba_ASSET.readall()
FRAME_5 = FRAME_5_cf5868e4_ASSET.readall()
FRAME_6 = FRAME_6_289fa720_ASSET.readall()
FRAME_7 = FRAME_7_4677f412_ASSET.readall()
FRAME_8 = FRAME_8_340c5e61_ASSET.readall()
FRAME_9 = FRAME_9_5964adb8_ASSET.readall()

# Animations list: [[frames], width, height, xPosition, yPosition, frameMilliseconds]
IQUIT = [
    [FRAME_1, FRAME_2, FRAME_3, FRAME_4, FRAME_5, FRAME_6, FRAME_7, FRAME_8, FRAME_9],
    64,
    32,
    0,
    0,
    100,
]
