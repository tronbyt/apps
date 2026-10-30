"""
Applet: CandyStatus
Summary: Trick-Or-Treat Status
Description: Shows trick-or-treaters whether you still have candy or not!
Author: nbohling
"""

load("animation.star", "animation")
load("images/ban_icon.png", BAN_ICON_ASSET = "file")
load("images/candy_icon.png", CANDY_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

BAN_ICON = BAN_ICON_ASSET.readall()
CANDY_ICON = CANDY_ICON_ASSET.readall()

DEFAULT_MESSAGE = "BoOoOoO! Trick-or-treat if you dare!"

def main(config):
    message = config.str("candyMessage") if config.bool("haveCandy", True) else config.str("noCandyMessage")
    message = message if message else DEFAULT_MESSAGE
    marquee = render.Marquee(
        child = render.Text(
            content = message,
            font = "6x13",
            color = "#f94",
        ),
        width = 64,
        offset_start = 0,
        offset_end = 0,
    )

    dancing_candy = animation.Transformation(
        child = render.Image(src = CANDY_ICON, width = 24, height = 24),
        keyframes = [
            animation.Keyframe(
                percentage = 0.0,
                transforms = [animation.Rotate(-10)],
            ),
            animation.Keyframe(
                percentage = 0.25,
                transforms = [animation.Rotate(10)],
            ),
            animation.Keyframe(
                percentage = 0.5,
                transforms = [animation.Rotate(-10)],
            ),
            animation.Keyframe(
                percentage = 0.75,
                transforms = [animation.Rotate(10)],
            ),
            animation.Keyframe(
                percentage = 1,
                transforms = [animation.Rotate(-10)],
            ),
        ],
        fill_mode = "forwards",
        origin = animation.Origin(0.5, 0.5),
        duration = marquee.frame_count() if marquee.frame_count() > 1 else 60,
        delay = 0,
    )

    icon = dancing_candy if config.bool("haveCandy", True) else render.Image(src = BAN_ICON, width = 20, height = 20)

    return render.Root(
        child = render.Box(
            child = render.Row(
                cross_align = "center",
                expanded = True,
                children = [
                    render.Box(
                        width = 24,
                        height = 24,
                        child = icon,
                    ),
                    marquee,
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "haveCandy",
                name = "Do you still have candy?",
                desc = "If you still have candy to give out, enable this. Once you run out, turn it off to show the 'Out of Candy' message.",
                icon = "ghost",
            ),
            schema.Text(
                id = "candyMessage",
                name = "Candy Message",
                desc = "The message to display while you still have candy.",
                icon = "message",
                default = DEFAULT_MESSAGE,
            ),
            schema.Text(
                id = "noCandyMessage",
                name = "No Candy Message",
                desc = "The message to display when you run out of candy.",
                icon = "ban",
                default = "Sorry, Out of Candy!",
            ),
        ],
    )
