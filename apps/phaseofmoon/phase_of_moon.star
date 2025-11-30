"""
Applet: Phase of Moon
Summary: Shows the phase of the moon
Description: Shows the current phase of the moon.
Author: Alan Fleming
"""

# Phase of Moon App
#
# Copyright (c) 2022 Alan Fleming
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# See comments in the code for further attribution
#

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/img_0a5354c3.png", IMG_0a5354c3_ASSET = "file")
load("images/img_20a08d13.png", IMG_20a08d13_ASSET = "file")
load("images/img_5086a72c.png", IMG_5086a72c_ASSET = "file")
load("images/img_88f66c2c.png", IMG_88f66c2c_ASSET = "file")
load("images/img_943edf3a.png", IMG_943edf3a_ASSET = "file")
load("images/img_99fb6de6.png", IMG_99fb6de6_ASSET = "file")
load("images/img_9dc538e0.png", IMG_9dc538e0_ASSET = "file")
load("images/img_a1bbaaff.png", IMG_a1bbaaff_ASSET = "file")
load("images/img_a8f3b29b.png", IMG_a8f3b29b_ASSET = "file")
load("images/img_cdd0e8c3.png", IMG_cdd0e8c3_ASSET = "file")
load("images/img_d280a3d8.png", IMG_d280a3d8_ASSET = "file")
load("images/img_e99f33dc.png", IMG_e99f33dc_ASSET = "file")
load("images/img_e9ab0947.png", IMG_e9ab0947_ASSET = "file")
load("images/img_ee4edaf4.png", IMG_ee4edaf4_ASSET = "file")
load("images/img_eeb0f7be.png", IMG_eeb0f7be_ASSET = "file")
load("images/img_f7ceb13c.png", IMG_f7ceb13c_ASSET = "file")

# Default location

DEFAULT_LOCATION = """
{
    "lat": 55.861111,
    "lng": -4.25,
    "locality": "Glasgow, UK",
    "timezone": "GMT"
}
"""

#
# Time formats used in get_schema
#

TIME_FORMATS = {
    "No clock": None,
    "12 hour": ("3:04", "3 04", True),
    "24 hour": ("15:04", "15 04", False),
}

# Constants
LUNARDAYS = 29.53058770576
LUNARSECONDS = LUNARDAYS * (24 * 60 * 60)
FIRSTMOON = 947182440  # Saturday, 6 January 2000 18:14:00 in unix epoch time

# Moon Images
# Rendered to 30x30 from NASA images at https://spaceplace.nasa.gov/oreo-moon/en/
PHASE_IMAGES = [
    IMG_ee4edaf4_ASSET.readall(),
    IMG_cdd0e8c3_ASSET.readall(),
    IMG_e9ab0947_ASSET.readall(),
    IMG_a8f3b29b_ASSET.readall(),
    IMG_943edf3a_ASSET.readall(),
    IMG_f7ceb13c_ASSET.readall(),
    IMG_a1bbaaff_ASSET.readall(),
    IMG_99fb6de6_ASSET.readall(),
    IMG_ee4edaf4_ASSET.readall(),
]

# Phase of the moon data.
# Dates in phase changes give 2 days for key phases and lengthen others to match. Removes over-display of key phases.
# Idea, data and calculation from https://minkukel.com/en/various/calculating-moon-phase/
NUM_PHASES = 8
MOON_PHASES = {
    "en": ["New Moon", "Waxing Crescent", "First Quarter", "Waxing Gibbous", "Full Moon", "Waning Gibbous", "Last Quarter", "Waning Crescent", "New Moon"],
}
PHASE_CHANGES = [0, 1, 6.38264692644, 8.38264692644, 13.76529385288, 15.76529385288, 21.14794077932, 23.14794077932, 28.53058770576, 29.53058770576]

# Moon phases in Chinese (simplified).
MOON_PHASES_ZH = [
    IMG_88f66c2c_ASSET.readall(),
    IMG_5086a72c_ASSET.readall(),
    IMG_e99f33dc_ASSET.readall(),
    IMG_d280a3d8_ASSET.readall(),
    IMG_20a08d13_ASSET.readall(),
    IMG_eeb0f7be_ASSET.readall(),
    IMG_0a5354c3_ASSET.readall(),
    IMG_9dc538e0_ASSET.readall(),
]

def main(config):
    # Get latitude from location
    location = json.decode(config.get("location", DEFAULT_LOCATION))
    lat = float(location["lat"])
    tz = location.get("timezone")

    # use latitude to work out which hemisphere we're in
    hemisphere = 1 if lat >= 0 else 0

    # Get the current time
    currtime = time.now("UTC")
    # currtime = time.parse_time("16-Sep-2022 20:17:00", format="02-Jan-2006 15:04:05")  # pick any date to debug/unit test

    # Get the current fraction of the moon cycle
    currentfrac = math.mod(currtime.unix - FIRSTMOON, LUNARSECONDS) / LUNARSECONDS

    # Calculate current day of the cycle from there
    currentday = currentfrac * LUNARDAYS

    displayText = config.get("display_text", "en")

    moonPhase = (MOON_PHASES[displayText][0] if displayText != "zh" else MOON_PHASES_ZH[0]) if displayText != "none" else ""
    phaseImage = PHASE_IMAGES[0]

    for x in range(0, NUM_PHASES):
        if currentday > PHASE_CHANGES[x] and currentday <= PHASE_CHANGES[x + 1]:
            moonPhase = (MOON_PHASES[displayText][x] if displayText != "zh" else MOON_PHASES_ZH[x]) if displayText != "none" else ""
            phaseImage = PHASE_IMAGES[x]
            if hemisphere == 0:
                phaseImage = PHASE_IMAGES[NUM_PHASES - x]

    # phaseImage = PHASE_IMAGES[4]  # pick any index from 0 to 7 to debug/unit test

    time_format = TIME_FORMATS.get(config.get("time_format"))
    blink_time = config.bool("blink_time")
    clock_has_shadow = config.bool("has_shadow")

    disp_time = time.now().in_location(tz).format(time_format[0]) if time_format else None
    disp_time_blink = time.now().in_location(tz).format(time_format[1]) if time_format else None

    # Got what we need to render.
    if displayText == "none":
        phaseText = render.WrappedText("")
    elif displayText == "zh":
        phaseText = render.Image(
            src = base64.decode(moonPhase),
        )
    else:
        phaseText = render.WrappedText(
            content = moonPhase,
            font = "tom-thumb",
        )

    phaseIndex = PHASE_IMAGES.index(phaseImage)

    align = "center"
    if displayText != "none" and phaseIndex <= 4:
        align = "start"
    elif displayText == "none" and time_format != None and phaseIndex <= 4:
        # align = "space_evenly"
        align = "space_around"

    displaycomplete = render.Box(
        render.Row(
            expanded = True,
            main_align = align,
            cross_align = "center",
            children = [
                render.Padding(
                    pad = (0, 0, 2, 0) if align == "start" else 0,
                    child = render.Image(src = base64.decode(phaseImage)),
                ),
                render.Column(
                    expanded = True,
                    main_align = "space_evenly" if time_format != None and displayText != "none" else "center",
                    cross_align = "start",
                    children = [
                        render.Padding(
                            pad = 0,
                            child = phaseText,
                        ),

                        # optional clock below
                        render.Animation(
                            children = [
                                # both w/ & w/out drop-shadow
                                render.Padding(
                                    pad = (0, 2, 0, 0),
                                    child = render.Stack(
                                        children = [
                                            render.Padding(
                                                # render extra pixels to the right to push time closer to moon
                                                pad = (3, 0, 0, 0),
                                                child = render.Text(
                                                    content = disp_time,
                                                    font = "tom-thumb",
                                                    color = "#000",
                                                ),
                                            ),
                                            render.Padding(
                                                # faint shadow right
                                                pad = (1, 0, 0, 0),
                                                child = render.Text(
                                                    content = disp_time,
                                                    font = "tom-thumb",
                                                    color = "#222",
                                                ),
                                            ),
                                            render.Padding(
                                                # faint shadow down
                                                pad = (0, 1, 0, 0),
                                                child = render.Text(
                                                    content = disp_time,
                                                    font = "tom-thumb",
                                                    color = "#222",
                                                ),
                                            ),
                                            render.Padding(
                                                # medium shadow diagonal down-right
                                                pad = (1, 1, 0, 0),
                                                child = render.Text(
                                                    content = disp_time,
                                                    font = "tom-thumb",
                                                    color = "#444",
                                                ),
                                            ),
                                            render.Text(
                                                # bright time
                                                content = disp_time,
                                                font = "tom-thumb",
                                                color = "#AAA",
                                            ),
                                        ],
                                    ),
                                ) if clock_has_shadow else render.Padding(
                                    pad = (0, 0, 0, 0),
                                    child = render.Text(
                                        content = disp_time,
                                        font = "tom-thumb",
                                        color = "#fff",
                                    ),
                                ),

                                # optional clock blink (w/ drop-shadow)
                                render.Padding(
                                    pad = (0, 2, 0, 0),
                                    child = render.Stack(
                                        children = [
                                            render.Padding(
                                                pad = (3, 0, 0, 0),
                                                child = render.Text(
                                                    content = disp_time_blink,
                                                    font = "tom-thumb",
                                                    color = "#000",
                                                ),
                                            ),
                                            render.Padding(
                                                pad = (1, 0, 0, 0),
                                                child = render.Text(
                                                    content = disp_time_blink,
                                                    font = "tom-thumb",
                                                    color = "#222",
                                                ),
                                            ),
                                            render.Padding(
                                                pad = (0, 1, 0, 0),
                                                child = render.Text(
                                                    content = disp_time_blink,
                                                    font = "tom-thumb",
                                                    color = "#222",
                                                ),
                                            ),
                                            render.Padding(
                                                pad = (1, 1, 0, 0),
                                                child = render.Text(
                                                    content = disp_time_blink,
                                                    font = "tom-thumb",
                                                    color = "#444",
                                                ),
                                            ),
                                            render.Text(
                                                content = disp_time_blink,
                                                font = "tom-thumb",
                                                color = "#AAA",
                                            ),
                                        ],
                                    ),
                                ) if blink_time and clock_has_shadow == True else None,

                                # optional clock blink
                                render.Padding(
                                    pad = (0, 0, 0, 0),
                                    child = render.Text(
                                        content = disp_time_blink,
                                        font = "tom-thumb",
                                        color = "#fff",
                                    ),
                                ) if blink_time and clock_has_shadow != True else None,
                            ],
                        ) if time_format else None,
                    ],
                ),
            ],
        ),
    )

    return render.Root(
        delay = 1000,
        child = displaycomplete,
    )

def more_options(time_format):
    if time_format != "No clock":
        return [
            schema.Toggle(
                id = "blink_time",
                name = "Blinking Time Separator",
                desc = "Whether to blink the colon between hours and minutes.",
                icon = "asterisk",
                default = False,
            ),
            schema.Toggle(
                id = "has_shadow",
                name = "Shadow",
                desc = "Whether clock has drop-shadow.",
                icon = "umbrella-beach",
                default = False,
            ),
        ]
    else:
        return []

def get_schema():
    langs = [
        schema.Option(
            display = "Chinese (simplified)",
            value = "zh",
        ),
        schema.Option(
            display = "English",
            value = "en",
        ),
        schema.Option(
            display = "None",
            value = "none",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display the moon phase.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "display_text",
                name = "Display Text",
                desc = "Display the text description of the moon phase.",
                icon = "font",
                default = langs[1].value,
                options = langs,
            ),
            schema.Dropdown(
                id = "time_format",
                name = "Time Format",
                desc = "The format used for the time.",
                icon = "clock",
                default = "No clock",
                options = [
                    schema.Option(
                        display = format,
                        value = format,
                    )
                    for format in TIME_FORMATS
                ],
            ),
            schema.Generated(
                id = "generated",
                source = "time_format",
                handler = more_options,
            ),
        ],
    )
