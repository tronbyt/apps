"""
Applet: Price Is Right
Summary: Turn the display into a bid
Description: Use the display to show a contestant bid screen like on the show, for use as a standalone display or part of a costume.
Author: Blkhwks19
"""

load("images/eight.png", EIGHT_ASSET = "file")
load("images/five.png", FIVE_ASSET = "file")
load("images/four.png", FOUR_ASSET = "file")
load("images/nine.png", NINE_ASSET = "file")
load("images/one.png", ONE_ASSET = "file")
load("images/seven.png", SEVEN_ASSET = "file")
load("images/six.png", SIX_ASSET = "file")
load("images/three.png", THREE_ASSET = "file")
load("images/two.png", TWO_ASSET = "file")
load("images/zero.png", ZERO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

EIGHT = EIGHT_ASSET.readall()
FIVE = FIVE_ASSET.readall()
FOUR = FOUR_ASSET.readall()
NINE = NINE_ASSET.readall()
ONE = ONE_ASSET.readall()
SEVEN = SEVEN_ASSET.readall()
SIX = SIX_ASSET.readall()
THREE = THREE_ASSET.readall()
TWO = TWO_ASSET.readall()
ZERO = ZERO_ASSET.readall()

def main(config):
    amount = "%s" % config.str("bid_amount", "799")
    bg = "%s" % config.str("bg_color", "#FF0000")
    row = ""

    if len(amount) == 0:
        row = render.Row(
            expanded = True,
            main_align = "end",
            children = [
                # nothing
            ],
        )
    elif len(amount) == 1:
        row = render.Row(
            expanded = True,
            main_align = "end",
            children = [
                render.Image(src = getImg(amount[0])),
                render.Box(width = 2, height = 32, color = bg),
            ],
        )
    elif len(amount) == 2:
        row = render.Row(
            expanded = True,
            main_align = "end",
            children = [
                render.Image(src = getImg(amount[0])),
                render.Box(width = 2, height = 32, color = bg),
                render.Image(src = getImg(amount[1])),
                render.Box(width = 2, height = 32, color = bg),
            ],
        )
    elif len(amount) == 3:
        row = render.Row(
            expanded = True,
            main_align = "space_evenly",
            children = [
                render.Image(src = getImg(amount[0])),
                render.Image(src = getImg(amount[1])),
                render.Image(src = getImg(amount[2])),
            ],
        )

    return render.Root(
        child = render.Stack(
            children = [
                render.Box(width = 64, height = 32, color = bg),
                render.Column(
                    expanded = True,
                    children = [
                        render.Box(width = 64, height = 1, color = bg),
                        row,
                    ],
                ),
            ],
        ),
    )

def getImg(num):
    if num == "0":
        return ZERO
    if num == "1":
        return ONE
    if num == "2":
        return TWO
    if num == "3":
        return THREE
    if num == "4":
        return FOUR
    if num == "5":
        return FIVE
    if num == "6":
        return SIX
    if num == "7":
        return SEVEN
    if num == "8":
        return EIGHT
    if num == "9":
        return NINE
    return 0

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "bid_amount",
                name = "Bid amount",
                desc = "0 - 9999",
                icon = "dollarSign",
                default = "799",
            ),
            schema.Color(
                id = "bg_color",
                name = "Background Color",
                desc = "Background color",
                icon = "palette",
                default = "#FF0000",
                palette = [
                    "#FF0000",  #red
                    "#00FF00",  #green
                    "#0000FF",  #blue
                    "#FFFF00",  #yellow
                    "#FFAA00",  #orange
                    "#00AAFF",  #light blue
                ],
            ),
        ],
    )
