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

load("encoding/json.star", "json")
load("images/phase_first_quarter.png", PHASE_FIRST_QUARTER_ASSET_1X = "file")
load("images/phase_first_quarter_zh.png", PHASE_FIRST_QUARTER_ZH_ASSET_1X = "file")
load("images/phase_full_moon.png", PHASE_FULL_MOON_ASSET_1X = "file")
load("images/phase_full_moon_zh.png", PHASE_FULL_MOON_ZH_ASSET_1X = "file")
load("images/phase_last_quarter.png", PHASE_LAST_QUARTER_ASSET_1X = "file")
load("images/phase_last_quarter_zh.png", PHASE_LAST_QUARTER_ZH_ASSET_1X = "file")
load("images/phase_new_moon.png", PHASE_NEW_MOON_ASSET_1X = "file")
load("images/phase_new_moon_zh.png", PHASE_NEW_MOON_ZH_ASSET_1X = "file")
load("images/phase_waning_crescent.png", PHASE_WANING_CRESCENT_ASSET_1X = "file")
load("images/phase_waning_crescent_zh.png", PHASE_WANING_CRESCENT_ZH_ASSET_1X = "file")
load("images/phase_waning_gibbous.png", PHASE_WANING_GIBBOUS_ASSET_1X = "file")
load("images/phase_waning_gibbous_zh.png", PHASE_WANING_GIBBOUS_ZH_ASSET_1X = "file")
load("images/phase_waxing_crescent.png", PHASE_WAXING_CRESCENT_ASSET_1X = "file")
load("images/phase_waxing_crescent_zh.png", PHASE_WAXING_CRESCENT_ZH_ASSET_1X = "file")
load("images/phase_waxing_gibbous.png", PHASE_WAXING_GIBBOUS_ASSET_1X = "file")
load("images/phase_waxing_gibbous_zh.png", PHASE_WAXING_GIBBOUS_ZH_ASSET_1X = "file")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

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
    PHASE_NEW_MOON_ASSET_1X,
    PHASE_WAXING_CRESCENT_ASSET_1X,
    PHASE_FIRST_QUARTER_ASSET_1X,
    PHASE_WAXING_GIBBOUS_ASSET_1X,
    PHASE_FULL_MOON_ASSET_1X,
    PHASE_WANING_GIBBOUS_ASSET_1X,
    PHASE_LAST_QUARTER_ASSET_1X,
    PHASE_WANING_CRESCENT_ASSET_1X,
    PHASE_NEW_MOON_ASSET_1X,
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
    PHASE_NEW_MOON_ZH_ASSET_1X,
    PHASE_WAXING_CRESCENT_ZH_ASSET_1X,
    PHASE_FIRST_QUARTER_ZH_ASSET_1X,
    PHASE_WAXING_GIBBOUS_ZH_ASSET_1X,
    PHASE_FULL_MOON_ZH_ASSET_1X,
    PHASE_WANING_GIBBOUS_ZH_ASSET_1X,
    PHASE_LAST_QUARTER_ZH_ASSET_1X,
    PHASE_WANING_CRESCENT_ZH_ASSET_1X,
    PHASE_NEW_MOON_ZH_ASSET_1X,
]

def scaled_pad(left, top, right, bottom, scale):
    return (left * scale, top * scale, right * scale, bottom * scale)

def main(config):
    scale = 2 if canvas.is2x() else 1

    # Get latitude from location
    location = json.decode(config.get("location", DEFAULT_LOCATION))
    lat = float(location["lat"])
    tz = location.get("timezone")

    # use latitude to work out which hemisphere we're in
    hemisphere = 1 if lat >= 0 else 0

    # Get the current time
    currtime = time.now("UTC")

    # Get the current fraction of the moon cycle
    currentfrac = math.mod(currtime.unix - FIRSTMOON, LUNARSECONDS) / LUNARSECONDS

    # Calculate current day of the cycle from there
    currentday = currentfrac * LUNARDAYS

    displayText = config.get("display_text", "en")

    moonPhase = (MOON_PHASES[displayText][0] if displayText != "zh" else MOON_PHASES_ZH[0]) if displayText != "none" else ""
    phaseImage = PHASE_IMAGES[0]

    for x in range(0, NUM_PHASES):
        if currentday > PHASE_CHANGES[x] and currentday <= PHASE_CHANGES[x + 1]:
            phase_idx = x
            if hemisphere == 0:
                phase_idx = NUM_PHASES - x
            moonPhase = (MOON_PHASES[displayText][phase_idx] if displayText != "zh" else MOON_PHASES_ZH[phase_idx]) if displayText != "none" else ""
            phaseImage = PHASE_IMAGES[phase_idx]

    time_format = TIME_FORMATS.get(config.get("time_format", "No clock"))
    clock_position = config.get("clock_position", "Center")
    blink_time = config.bool("blink_time")
    clock_has_shadow = config.bool("has_shadow")

    disp_time = time.now().in_location(tz).format(time_format[0]) if time_format else None
    disp_time_blink = time.now().in_location(tz).format(time_format[1]) if time_format else None

    # Got what we need to render.
    if displayText == "none":
        phaseText = render.WrappedText("")
    elif displayText == "zh":
        phaseText = render.Image(
            src = moonPhase.readall(),
        )
    else:
        phaseText = render.WrappedText(
            content = moonPhase,
            font = "terminus-12" if canvas.is2x() else "tom-thumb",
        )

    phaseIndex = PHASE_IMAGES.index(phaseImage)

    rowAlign = "center"

    if displayText != "none" and phaseIndex <= 4:
        rowAlign = "space_evenly"
    elif displayText == "none" and time_format != None and phaseIndex <= 4:
        rowAlign = "space_around"

    clockAlignment = "center"
    if time_format != None and displayText != "none":
        clockAlignment = "space_evenly"
    elif time_format != None and clock_position == "Top":
        clockAlignment = "start"
    elif time_format != None and clock_position == "Center":
        clockAlignment = "center"
    elif time_format != None and clock_position == "Bottom":
        clockAlignment = "end"

    clockFont = "terminus-12" if canvas.is2x() else "tom-thumb"

    displaycomplete = render.Box(
        render.Row(
            expanded = True,
            main_align = rowAlign,
            cross_align = "center",
            children = [
                render.Image(
                    src = phaseImage.readall(),
                    width = 60 if canvas.is2x() else 30,
                ),
                render.Padding(
                    pad = (1, 0, 0, 0),
                    child = render.Column(
                        expanded = True,
                        main_align = clockAlignment,
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
                                        pad = scaled_pad(0, 2, 0, 0, scale),
                                        child = render.Stack(
                                            children = [
                                                render.Padding(
                                                    # render extra pixels to the right to push time closer to moon
                                                    pad = (3, 0, 0, 0),
                                                    child = render.Text(
                                                        content = disp_time,
                                                        font = clockFont,
                                                        color = "#000",
                                                    ),
                                                ),
                                                render.Padding(
                                                    # faint shadow right
                                                    pad = (1, 0, 0, 0),
                                                    child = render.Text(
                                                        content = disp_time,
                                                        font = clockFont,
                                                        color = "#222",
                                                    ),
                                                ),
                                                render.Padding(
                                                    # faint shadow down
                                                    pad = (0, 1, 0, 0),
                                                    child = render.Text(
                                                        content = disp_time,
                                                        font = clockFont,
                                                        color = "#222",
                                                    ),
                                                ),
                                                render.Padding(
                                                    # medium shadow diagonal down-right
                                                    pad = (1, 1, 0, 0),
                                                    child = render.Text(
                                                        content = disp_time,
                                                        font = clockFont,
                                                        color = "#444",
                                                    ),
                                                ),
                                                render.Text(
                                                    # bright time
                                                    content = disp_time,
                                                    font = clockFont,
                                                    color = "#AAA",
                                                ),
                                            ],
                                        ),
                                    ) if clock_has_shadow else render.Padding(
                                        pad = (0, 1, 0, 0),
                                        child = render.Text(
                                            content = disp_time,
                                            font = clockFont,
                                            color = "#fff",
                                        ),
                                    ),

                                    # optional clock blink (w/ drop-shadow)
                                    render.Padding(
                                        pad = scaled_pad(0, 2, 0, 0, scale),
                                        child = render.Stack(
                                            children = [
                                                render.Padding(
                                                    pad = (3, 0, 0, 0),
                                                    child = render.Text(
                                                        content = disp_time_blink,
                                                        font = clockFont,
                                                        color = "#000",
                                                    ),
                                                ),
                                                render.Padding(
                                                    pad = (1, 0, 0, 0),
                                                    child = render.Text(
                                                        content = disp_time_blink,
                                                        font = clockFont,
                                                        color = "#222",
                                                    ),
                                                ),
                                                render.Padding(
                                                    pad = (0, 1, 0, 0),
                                                    child = render.Text(
                                                        content = disp_time_blink,
                                                        font = clockFont,
                                                        color = "#222",
                                                    ),
                                                ),
                                                render.Padding(
                                                    pad = (1, 1, 0, 0),
                                                    child = render.Text(
                                                        content = disp_time_blink,
                                                        font = clockFont,
                                                        color = "#444",
                                                    ),
                                                ),
                                                render.Text(
                                                    content = disp_time_blink,
                                                    font = clockFont,
                                                    color = "#AAA",
                                                ),
                                            ],
                                        ),
                                    ) if blink_time and clock_has_shadow else None,

                                    # optional clock blink
                                    render.Padding(
                                        pad = (0, 1, 0, 0),
                                        child = render.Text(
                                            content = disp_time_blink,
                                            font = clockFont,
                                            color = "#fff",
                                        ),
                                    ) if blink_time and not clock_has_shadow else None,
                                ],
                            ) if time_format else None,
                        ],
                    ),
                ),
            ],
        ),
        width = canvas.width(),
        height = canvas.height(),
        padding = scale,
    )

    return render.Root(
        delay = 1000,
        child = displaycomplete,
    )

def more_options(time_format):
    if time_format != "No clock":
        return [
            schema.Dropdown(
                id = "clock_position",
                name = "Clock Position",
                desc = "Specify the positioning of the clock when only the clock is shown.",
                icon = "up-down",
                default = "Center",
                options = [
                    schema.Option(
                        display = "Top",
                        value = "Top",
                    ),
                    schema.Option(
                        display = "Center",
                        value = "Center",
                    ),
                    schema.Option(
                        display = "Bottom",
                        value = "Bottom",
                    ),
                ],
            ),
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
