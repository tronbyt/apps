"""
Applet: Spectro Cloud Clock
Summary: Spectro Cloud images
Description: A collection of Spectro Cloud images with a clock.
Author: karl-cardenas-coding
"""

load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

SPECTRO_FONT_COLOR_BLUE = "#3575CF"
PALETTE_FONT_COLOR_PURPLE = "#6a5d9d"

IMAGES = [
    SPECTRO_CLOUD_1_ASSET.readall(),
    SPECTRO_CLOUD_2_ASSET.readall(),
    SPECTRO_CLOUD_3_ASSET.readall(),
    SPECTRO_CLOUD_4_ASSET.readall(),
    SPECTRO_CLOUD_5_ASSET.readall(),
]

def main(config):
    message = "Spectro"
    message2 = "Cloud"
    timezone = config.get("timezone") or "America/Phoenix"
    now = time.now().in_location(timezone)

    use_24hour = config.bool("24hour", False)
    time_format_colon = "3:04 PM"
    time_format_blank = "3 04 PM"
    if (use_24hour):
        time_format_colon = "15:04"
        time_format_blank = "15 04"

    return getDisplay(config.bool("clock"), message, message2, now, time_format_colon, time_format_blank)

def get_schema():
    return schema.Schema(
        fields = [
            schema.Toggle(
                id = "clock",
                name = "Display Clock",
                desc = "Display the clock",
                icon = "clock",
                default = True,
            ),
            schema.Toggle(
                id = "24hour",
                name = "24 Hour Time",
                icon = "clock",
                desc = "Choose whether to display 12-hour time (off) or 24-hour time (on). Requires Display Clock to be enabled.",
                default = False,
            ),
        ],
        version = "1",
    )

# This function returns a random image from the list of images
# The seed is by default updated every 15 seconds
def getRandomImage(images):
    num = random.number(0, len(images) - 1)
    return render.Image(src = images[num])

# This function returns the display based on the clock value
# If clock is true, it will display the clock
# If clock is false, it will not display the clock
# The message and message2 are the text that will be displayed
# The now is the current time
def getDisplay(clock, message, message2, now, time_format_colon, time_format_blank):
    img = getRandomImage(IMAGES)

    if (clock):
        return render.Root(
            delay = 500,
            child = render.Box(
                render.Row(
                    expanded = True,  # Use as much horizontal space as possible
                    main_align = "space_evenly",  # Controls horizontal alignment
                    cross_align = "center",  # Controls vertical alignment
                    children = [
                        img,
                        render.Column(
                            main_align = "space_around",
                            children = [
                                render.Text(
                                    message,
                                    font = "5x8",
                                    color = SPECTRO_FONT_COLOR_BLUE,
                                ),
                                render.Text(
                                    message2,
                                    font = "5x8",
                                    color = SPECTRO_FONT_COLOR_BLUE,
                                ),
                                render.Animation(
                                    children = [
                                        render.Text(
                                            content = now.format(time_format_colon),
                                            font = "CG-pixel-3x5-mono",
                                            color = PALETTE_FONT_COLOR_PURPLE,
                                        ),
                                        render.Text(
                                            content = now.format(time_format_blank),
                                            font = "CG-pixel-3x5-mono",
                                            color = PALETTE_FONT_COLOR_PURPLE,
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
            ),
        )
    else:
        return render.Root(
            delay = 500,
            child = render.Box(
                render.Row(
                    expanded = True,  # Use as much horizontal space as possible
                    main_align = "space_evenly",  # Controls horizontal alignment
                    cross_align = "center",  # Controls vertical alignment
                    children = [
                        img,
                        render.Column(
                            main_align = "space_around",
                            children = [
                                render.Text(
                                    message,
                                    font = "5x8",
                                    color = SPECTRO_FONT_COLOR_BLUE,
                                ),
                                render.Text(
                                    message2,
                                    font = "5x8",
                                    color = SPECTRO_FONT_COLOR_BLUE,
                                ),
                            ],
                        ),
                    ],
                ),
            ),
        )
