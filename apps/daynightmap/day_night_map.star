"""
Applet: Day Night Map
Summary: Day & Night World Map
Description: A map of the Earth showing the day and the night. The map is based on Equirectangular (0°) by Tobias Jung (CC BY-SA 4.0).
Author: Henry So, Jr.
"""

# Day & Night World Map
# Version 1.1.0
#
# Copyright (c) 2022 Henry So, Jr.
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

# See comments in the code for further attribution

load("encoding/json.star", "json")
load("images/map.png", MAP_ASSET = "file")
load("images/pixel.png", PIXEL_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

MAP = MAP_ASSET.readall()
PIXEL = PIXEL_ASSET.readall()

WIDTH = 64
HALF_W = WIDTH // 2
HEIGHT = 32
HALF_H = HEIGHT // 2
HDIV = 360 / WIDTH
HALF_HDIV = HDIV / 2
COEF = 360 / 365.24
DATE_H = 7

CHAR_W = 9
SEP_W = 3

def main(config):
    location = config.get("location")

    #print(location)
    location = json.decode(location) if location else {}
    time_format = TIME_FORMATS.get(config.get("time_format"))
    blink_time = config.bool("blink_time")
    show_date = config.bool("show_date")

    tz = location.get(
        "timezone",
        time.tz(),
    )

    tm = config.get("force_time")
    if tm:
        tm = time.parse_time(tm).in_location(tz)
    else:
        tm = time.now().in_location(tz)

    if config.bool("center_location"):
        map_offset = -round(float(location.get("lng", "0")) * HALF_W / 180)
    else:
        map_offset = 0

    #print(map_offset)

    formatted_date = tm.format("Mon 2 Jan 2006")
    date_shadow = render.Row(
        main_align = "center",
        expanded = True,
        children = [
            render.Text(
                content = formatted_date,
                font = "tom-thumb",
                color = "#000",
            ),
        ],
    )

    night_above, sunrise = sunrise_plot(tm)
    return render.Root(
        delay = 1000,
        child = render.Stack([
            render.Padding(
                pad = (map_offset, 0, 0, 0),
                child = render.Image(MAP),
            ),
            render.Padding(
                pad = (
                    map_offset + (-WIDTH if map_offset > 0 else WIDTH),
                    0,
                    0,
                    0,
                ),
                child = render.Image(MAP),
            ) if map_offset != 0 else None,
            render.Row([
                render.Padding(
                    pad = (0, y if night_above else 0, 0, 0),
                    child = render.Image(
                        src = PIXEL,
                        width = 1,
                        height = HEIGHT - y if night_above else y,
                    ),
                )
                for i in range(WIDTH)
                for y in [sunrise[(i - map_offset) % WIDTH]]
            ]),
            render.Column(
                main_align = "center",
                expanded = True,
                children = [
                    render.Row(
                        main_align = "center",
                        expanded = True,
                        children = [
                            render.Animation([
                                render_time(tm, time_format[0]),
                                render_time(tm, time_format[1]) if blink_time else None,
                            ]),
                            render.Padding(
                                pad = (1, 9, 0, 0),
                                child = render.Image(AM_PM[tm.hour < 12]),
                            ) if time_format[2] else None,
                        ],
                    ),
                    render.Box(
                        width = WIDTH,
                        height = 3,
                    ) if show_date else None,
                ],
            ) if time_format else None,
            render.Padding(
                pad = (0, HEIGHT - DATE_H, 0, 0),
                child = render.Stack([
                    render.Padding(
                        pad = (-1, 1, 0, 0),
                        child = date_shadow,
                    ),
                    render.Padding(
                        pad = (2, 1, 0, 0),
                        child = date_shadow,
                    ),
                    render.Padding(
                        pad = (0, 0, 0, 0),
                        child = date_shadow,
                    ),
                    render.Padding(
                        pad = (0, 2, 0, 0),
                        child = date_shadow,
                    ),
                    render.Padding(
                        pad = (0, 1, 0, 0),
                        child = render.Row(
                            main_align = "center",
                            expanded = True,
                            children = [
                                render.Text(
                                    content = formatted_date,
                                    font = "tom-thumb",
                                    color = "#ff0",
                                ),
                            ],
                        ),
                    ),
                ]),
            ) if show_date else None,
        ]),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for the display of date/time.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "center_location",
                name = "Center On Location",
                desc = "Whether to center the map on the location.",
                icon = "compress",
                default = False,
            ),
            schema.Dropdown(
                id = "time_format",
                name = "Time Format",
                desc = "The format used for the time.",
                icon = "clock",
                default = "omit",
                options = [
                    schema.Option(
                        display = format,
                        value = format,
                    )
                    for format in TIME_FORMATS
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
                id = "show_date",
                name = "Date Overlay",
                desc = "Whether the date overlay should be shown.",
                icon = "calendarCheck",
                default = False,
            ),
        ],
    )

def sunrise_plot(tm):
    tm = tm.in_location("UTC")
    anchor = time.time(
        year = tm.year,
        month = 1,
        day = 1,
        location = "UTC",
    )
    days = int((tm - anchor).hours // 24)

    tan_dec = TAN_DEC[days]
    tau = 15 * (tm.hour + tm.minute / 60) - 180

    # Use the sunrise equation to compute the latitude
    # See https://en.wikipedia.org/wiki/Position_of_the_Sun
    def lat(lon):
        return atan(-cos(lon + tau) / tan_dec)

    return (
        tan_dec > 0,
        [
            HALF_H - round(lat(lon) * HALF_H / 90)
            #lat(lon)
            for lon in LONGITUDES
        ],
    )

def sin(degrees):
    return math.sin(math.radians(degrees))

def cos(degrees):
    return math.cos(math.radians(degrees))

def tan(degrees):
    return math.tan(math.radians(degrees))

def asin(x):
    return math.degrees(math.asin(x))

def atan(x):
    return math.degrees(math.atan(x))

def round(x):
    return int(math.round(x))

def render_time(tm, format):
    formatted_time = tm.format(format)
    offset = 5 - len(formatted_time)
    offset_pad = pad_of(offset)
    return render.Stack([
        render.Padding(
            pad = (pad_of(i + offset) - offset_pad, 0, 0, 0),
            child = render.Image(CHARS[c]),
        )
        for i, c in enumerate(formatted_time.elems())
        if c != " "
    ])

def pad_of(i):
    if i > 2:
        return (i - 1) * CHAR_W + SEP_W
    elif i > 0:
        return i * CHAR_W
    else:
        return 0

# Pre-compute the tangent to the declination of the sun
# See https://en.wikipedia.org/wiki/Position_of_the_Sun
TAN_DEC = [
    tan(asin(sin(-23.44) * cos(
        COEF * (d + 10) +
        (360 / math.pi * 0.0167 * sin(COEF * (d - 2))),
    )))
    for d in range(366)
]

LONGITUDES = [
    (x - HALF_W) * HDIV + HALF_HDIV
    for x in range(WIDTH)
]

DEFAULT_TIMEZONE = "America/New_York"

TIME_FORMATS = {
    "omit": None,
    "12-hour": ("3:04", "3 04", True),
    "24-hour": ("15:04", "15 04", False),
}

CHARS = {
    "0": CHAR_0_ASSET.readall(),
    "1": CHAR_1_ASSET.readall(),
    "2": CHAR_2_ASSET.readall(),
    "3": CHAR_3_ASSET.readall(),
    "4": CHAR_4_ASSET.readall(),
    "5": CHAR_5_ASSET.readall(),
    "6": CHAR_6_ASSET.readall(),
    "7": CHAR_7_ASSET.readall(),
    "8": CHAR_8_ASSET.readall(),
    "9": CHAR_9_ASSET.readall(),
    ":": COLON_ASSET.readall(),
}

AM_PM = {
    True: AM_ASSET.readall(),
    False: PM_ASSET.readall(),
}

# The following Base64-encoded image is a scaled-down version of
# Equirectangular (0°) by Tobias Jung
# found at https://map-projections.net/single-view/rectang-0:flat-stf
# This image released under the CC BY-SA 4.0 International license
