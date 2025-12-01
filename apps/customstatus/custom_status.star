"""
Applet: Custom Status
Summary: Share a custom status
Description: Share a custom status with coworkers.
Author: Brian Bell
"""

load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("images/icon_check.png", ICON_CHECK_ASSET = "file")
load("images/icon_clock.png", ICON_CLOCK_ASSET = "file")
load("images/icon_do_not_enter.png", ICON_DO_NOT_ENTER_ASSET = "file")
load("images/icon_exclamation.png", ICON_EXCLAMATION_ASSET = "file")
load("images/icon_heart.png", ICON_HEART_ASSET = "file")
load("images/icon_house.png", ICON_HOUSE_ASSET = "file")
load("images/icon_lightning.png", ICON_LIGHTNING_ASSET = "file")
load("images/icon_music.png", ICON_MUSIC_ASSET = "file")
load("images/icon_plane.png", ICON_PLANE_ASSET = "file")
load("images/icon_question.png", ICON_QUESTION_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_NAME = "Jane Smith"
DEFAULT_STATUS = "Focusing"
DEFAULT_COLOR = "#FFFF00"
DEFAULT_ICON = ICON_CHECK_ASSET.readall()
DEFAULT_MESSAGE = "Until later"

def main(config):
    name = config.str("name", DEFAULT_NAME)
    status = config.get("status", DEFAULT_STATUS)
    color = config.get("color", DEFAULT_COLOR)
    icon_setting = config.get("icon")
    message = config.get("message", DEFAULT_MESSAGE)
    animations = config.bool("animation", False)

    icon = base64.decode(icon_setting) if icon_setting != None else DEFAULT_ICON

    if config.bool("hide_app", False):  ## hide app
        return []

    if not animations:
        return render.Root(
            child = render.Row(
                children = [
                    render.Box(
                        color = color,
                        width = 10,
                        child = render.Image(src = icon, width = 10),
                    ),
                    render.Padding(
                        pad = (1, 2, 0, 1),
                        child = render.Column(
                            expanded = True,
                            main_align = "space_between",
                            children = [
                                render.Marquee(
                                    child = render.Text(
                                        content = name + " is",
                                        font = "tom-thumb",
                                    ),
                                    offset_start = 0,
                                    offset_end = 0,
                                    width = 53,
                                ),
                                render.Marquee(
                                    child = render.Text(
                                        content = status.upper(),
                                        font = "6x13",
                                    ),
                                    offset_start = 0,
                                    offset_end = 0,
                                    width = 53,
                                ),
                                render.Marquee(
                                    child = render.Text(
                                        content = message,
                                        font = "tom-thumb",
                                    ),
                                    offset_start = 0,
                                    offset_end = 0,
                                    width = 53,
                                ),
                            ],
                        ),
                    ),
                ],
            ),
        )
    else:
        return render.Root(
            child = render.Stack(
                children = [
                    # Left side color indicator
                    animation.Transformation(
                        child = render.Box(
                            color = color,
                            width = 10,
                            child = render.Image(src = icon, width = 10),
                        ),
                        duration = 282,
                        delay = 0,
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(-64, 0)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.16,
                                transforms = [animation.Translate(0, 0)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.80,
                                transforms = [animation.Translate(0, 0)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(-64, 0)],
                            ),
                        ],
                    ),
                    # Name row
                    animation.Transformation(
                        child = render.Marquee(
                            child = render.Text(
                                content = name + " is",
                                font = "tom-thumb",
                            ),
                            offset_start = 80,
                            offset_end = 0,
                            width = 53,
                        ),
                        duration = 250,
                        delay = 30,
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(11, 34)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.10,
                                transforms = [animation.Translate(11, 2)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.81,
                                transforms = [animation.Translate(11, 2)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(-53, 2)],
                            ),
                        ],
                    ),
                    # Status row
                    animation.Transformation(
                        child = render.Marquee(
                            child = render.Text(
                                content = status.upper(),
                                font = "6x13",
                            ),
                            offset_start = 0,
                            offset_end = 0,
                            width = 53,
                        ),
                        duration = 250,
                        delay = 30,
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(11, 42)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.17,
                                transforms = [animation.Translate(11, 10)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.83,
                                transforms = [animation.Translate(11, 10)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(-53, 10)],
                            ),
                        ],
                    ),
                    # Message row
                    animation.Transformation(
                        child = render.Marquee(
                            child = render.Text(
                                content = message,
                                font = "tom-thumb",
                            ),
                            offset_start = 80,
                            offset_end = 0,
                            width = 53,
                        ),
                        duration = 250,
                        delay = 30,
                        wait_for_child = True,
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(11, 57)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.20,
                                transforms = [animation.Translate(11, 25)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.85,
                                transforms = [animation.Translate(11, 25)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(-53, 25)],
                            ),
                        ],
                    ),
                ],
            ),
        )

def get_schema():
    color_options = [
        schema.Option(
            display = "Red",
            value = "#FF0000",
        ),
        schema.Option(
            display = "Cyan",
            value = "#00FFFF",
        ),
        schema.Option(
            display = "Blue",
            value = "#0000FF",
        ),
        schema.Option(
            display = "Light Blue",
            value = "#ADD8E6",
        ),
        schema.Option(
            display = "Dark Blue",
            value = "#0000A0",
        ),
        schema.Option(
            display = "Purple",
            value = "#800080",
        ),
        schema.Option(
            display = "Yellow",
            value = "#FFFF00",
        ),
        schema.Option(
            display = "Lime",
            value = "#00FF00",
        ),
        schema.Option(
            display = "Magenta",
            value = "#FF00FF",
        ),
        schema.Option(
            display = "White",
            value = "#FFFFFF",
        ),
        schema.Option(
            display = "Silver",
            value = "#C0C0C0",
        ),
        schema.Option(
            display = "Gray",
            value = "#808080",
        ),
        schema.Option(
            display = "Orange",
            value = "#FFA500",
        ),
        schema.Option(
            display = "Brown",
            value = "#A52A2A",
        ),
        schema.Option(
            display = "Maroon",
            value = "#800000",
        ),
        schema.Option(
            display = "Green",
            value = "#008000",
        ),
        schema.Option(
            display = "Olive",
            value = "#808000",
        ),
    ]

    icon_options = [
        schema.Option(
            display = "Check",
            value = ICON_CHECK_ASSET.readall(),
        ),
        schema.Option(
            display = "Clock",
            value = ICON_CLOCK_ASSET.readall(),
        ),
        schema.Option(
            display = "Do Not Enter",
            value = ICON_DO_NOT_ENTER_ASSET.readall(),
        ),
        schema.Option(
            display = "Exclamation",
            value = ICON_EXCLAMATION_ASSET.readall(),
        ),
        schema.Option(
            display = "Heart",
            value = ICON_HEART_ASSET.readall(),
        ),
        schema.Option(
            display = "House",
            value = ICON_HOUSE_ASSET.readall(),
        ),
        schema.Option(
            display = "Lightning",
            value = ICON_LIGHTNING_ASSET.readall(),
        ),
        schema.Option(
            display = "Music",
            value = ICON_MUSIC_ASSET.readall(),
        ),
        schema.Option(
            display = "Plane",
            value = ICON_PLANE_ASSET.readall(),
        ),
        schema.Option(
            display = "Question",
            value = ICON_QUESTION_ASSET.readall(),
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "name",
                name = "Name",
                desc = "Enter the name you want to display.",
                icon = "user",
            ),
            schema.Text(
                id = "status",
                name = "Status",
                desc = "Enter a custom status.",
                icon = "font",
            ),
            schema.Dropdown(
                id = "color",
                name = "Color",
                desc = "Select a custom status color.",
                icon = "palette",
                default = color_options[1].value,
                options = color_options,
            ),
            schema.Dropdown(
                id = "icon",
                name = "Icon",
                desc = "Select a custom status icon.",
                icon = "icons",
                default = icon_options[6].value,
                options = icon_options,
            ),
            schema.Text(
                id = "message",
                name = "Message",
                desc = "Enter a custom status message.",
                icon = "font",
            ),
            schema.Toggle(
                id = "animation",
                name = "Show Animations",
                desc = "Turn on entry and exit animations.",
                icon = "arrowsRotate",
                default = False,
            ),
            schema.Toggle(
                id = "hide_app",
                name = "Hide App",
                desc = "Hide this app so that the custom status is not shown.",
                icon = "eyeSlash",
                default = False,
            ),
        ],
    )
