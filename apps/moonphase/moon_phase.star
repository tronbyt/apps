"""
Applet: Moon Phase
Summary: Shows current moon phase
Description: Shows phase of moon based on location.
Author: Chris Wyman
"""

# Moon Phase
#
# Copyright (c) 2022 Chris Wyman
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

load("encoding/json.star", "json")
load("images/black_pixel.png", BLACK_PIXEL_ASSET = "file")
load("images/clear_pixel.png", CLEAR_PIXEL_ASSET = "file")
load("images/dark01_pixel.png", DARK01_PIXEL_ASSET = "file")
load("images/dark02_pixel.png", DARK02_PIXEL_ASSET = "file")
load("images/dark03_pixel.png", DARK03_PIXEL_ASSET = "file")
load("images/dark04_pixel.png", DARK04_PIXEL_ASSET = "file")
load("images/dark05_pixel.png", DARK05_PIXEL_ASSET = "file")
load("images/dark06_pixel.png", DARK06_PIXEL_ASSET = "file")
load("images/dark07_pixel.png", DARK07_PIXEL_ASSET = "file")
load("images/dark08_pixel.png", DARK08_PIXEL_ASSET = "file")
load("images/dark09_pixel.png", DARK09_PIXEL_ASSET = "file")
load("images/dark10_pixel.png", DARK10_PIXEL_ASSET = "file")
load("images/dark11_pixel.png", DARK11_PIXEL_ASSET = "file")
load("images/dark12_pixel.png", DARK12_PIXEL_ASSET = "file")
load("images/dark13_pixel.png", DARK13_PIXEL_ASSET = "file")
load("images/dark14_pixel.png", DARK14_PIXEL_ASSET = "file")
load("images/moon_img.png", MOON_IMG_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BLACK_PIXEL = BLACK_PIXEL_ASSET.readall()
CLEAR_PIXEL = CLEAR_PIXEL_ASSET.readall()
DARK01_PIXEL = DARK01_PIXEL_ASSET.readall()
DARK02_PIXEL = DARK02_PIXEL_ASSET.readall()
DARK03_PIXEL = DARK03_PIXEL_ASSET.readall()
DARK04_PIXEL = DARK04_PIXEL_ASSET.readall()
DARK05_PIXEL = DARK05_PIXEL_ASSET.readall()
DARK06_PIXEL = DARK06_PIXEL_ASSET.readall()
DARK07_PIXEL = DARK07_PIXEL_ASSET.readall()
DARK08_PIXEL = DARK08_PIXEL_ASSET.readall()
DARK09_PIXEL = DARK09_PIXEL_ASSET.readall()
DARK10_PIXEL = DARK10_PIXEL_ASSET.readall()
DARK11_PIXEL = DARK11_PIXEL_ASSET.readall()
DARK12_PIXEL = DARK12_PIXEL_ASSET.readall()
DARK13_PIXEL = DARK13_PIXEL_ASSET.readall()
DARK14_PIXEL = DARK14_PIXEL_ASSET.readall()
MOON_IMG = MOON_IMG_ASSET.readall()

#
# Default location
#

DEFAULT_LOCATION = """
{
    "lat": 47.606,
    "lng": -122.332,
    "locality": "Seattle, WA, USA",
    "timezone": "America/Los_Angeles"
}
"""

#
# Time formats used in get_schema
#

TIME_FORMATS = {
    "None": None,
    "12 hour": ("3:04", "3 04", True),
    "24 hour": ("15:04", "15 04", False),
}

#
# moon image constants
#

MOONIMG_WIDTH = 32  # Width of moon image
MOONIMG_HEIGHT = 32  # Height of moon image

#
# background MOON_IMG constants
#

X_C = MOONIMG_WIDTH / 2.0 - 0.5  # X-center of MOON_IMG in pixel coordinates, - 0.5 so it's middle of the pixel
Y_C = MOONIMG_HEIGHT / 2.0 - 0.5  # Y-center of MOON_IMG in pixel coordinates, - 0.5 so it's middle of the pixel
R = (MOONIMG_HEIGHT - 2) / 2.0  # radius of MOON_IMG in pixel coordinates, HEIGHT - 2 because of the 1 pixel margin about disc (specific to MOON_IMG)

#
# moon cycle constants
#

LUNATION = 2551443  # lunar cycle in seconds (29 days 12 hours 44 minutes 3 seconds)
REF_NEWMOON = time.parse_time("30-Apr-2022 20:28:00", format = "02-Jan-2006 15:04:05").unix

#
# geometric/graphic constants
#

SHADOW_LEVEL = 0.15
FADE_LNG = math.pi / 6  # 30 degrees in moon longitude, but fade is non-linear (see comment in percent_illuminated())
FONT = "tom-thumb"
CLOCK_PADDING = 24  # y-offset of clock in pixels

def main(config):
    location = json.decode(config.get("location", DEFAULT_LOCATION))
    latitude = float(location["lat"])
    tz = location.get("timezone")

    currtime = time.now("UTC")
    #currtime = time.parse_time("16-Sep-2022 20:17:00", format="02-Jan-2006 15:04:05")    # pick any date to debug/unit test

    currsecofmooncycle = (currtime.unix - REF_NEWMOON) % LUNATION

    moon_phase = (currsecofmooncycle / LUNATION) * 2 * math.pi
    #moon_phase = (currtime.unix % 60) / 60 * 2*math.pi    # debug/unit test with fake 60 second lunar cycle

    #print(moon_phase)

    time_format = TIME_FORMATS.get(config.get("time_format"))
    blink_time = config.bool("blink_time")

    disp_time = time.now().in_location(tz).format(time_format[0]) if time_format else None
    disp_time_blink = time.now().in_location(tz).format(time_format[1]) if time_format else None

    return render.Root(
        delay = 1000,
        child = render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "left",
            children = [
                render.Stack([
                    render.Image(src = MOON_IMG),
                    # Stack below is a dynamically generated shadow mask built one pixel at a time
                    render.Stack([
                        # Each child of Stack is a row of pixels
                        render.Row([
                            # Each Row is a 1 pixel tall stack at height "y"
                            render.Padding(
                                # This element represents the mask pixel at (x, y)
                                pad = (0, y, 0, 0),
                                child = render.Image(
                                    src = getmaskpixel(x, y, moon_phase, latitude),
                                ),
                            )
                            for x in range(MOONIMG_WIDTH)
                        ])
                        for y in range(MOONIMG_HEIGHT)
                    ]),
                ]),
                # optional clock below
                render.Animation(
                    children = [
                        render.Padding(
                            pad = (0, CLOCK_PADDING, 0, 0),
                            child = render.Stack(
                                children = [
                                    render.Padding(
                                        # render extra pixels to the right to push time closer to moon
                                        pad = (3, 0, 0, 0),
                                        child = render.Text(
                                            content = disp_time,
                                            font = FONT,
                                            color = "#000",
                                        ),
                                    ),
                                    render.Padding(
                                        # faint shadow right
                                        pad = (1, 0, 0, 0),
                                        child = render.Text(
                                            content = disp_time,
                                            font = FONT,
                                            color = "#222",
                                        ),
                                    ),
                                    render.Padding(
                                        # faint shadow down
                                        pad = (0, 1, 0, 0),
                                        child = render.Text(
                                            content = disp_time,
                                            font = FONT,
                                            color = "#222",
                                        ),
                                    ),
                                    render.Padding(
                                        # medium shadow diagonal down-right
                                        pad = (1, 1, 0, 0),
                                        child = render.Text(
                                            content = disp_time,
                                            font = FONT,
                                            color = "#444",
                                        ),
                                    ),
                                    render.Text(
                                        # bright time
                                        content = disp_time,
                                        font = FONT,
                                        color = "#AAA",
                                    ),
                                ],
                            ),
                        ),
                        render.Padding(
                            pad = (0, CLOCK_PADDING, 0, 0),
                            child = render.Stack(
                                children = [
                                    render.Padding(
                                        pad = (3, 0, 0, 0),
                                        child = render.Text(
                                            content = disp_time_blink,
                                            font = FONT,
                                            color = "#000",
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (1, 0, 0, 0),
                                        child = render.Text(
                                            content = disp_time_blink,
                                            font = FONT,
                                            color = "#222",
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (0, 1, 0, 0),
                                        child = render.Text(
                                            content = disp_time_blink,
                                            font = FONT,
                                            color = "#222",
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (1, 1, 0, 0),
                                        child = render.Text(
                                            content = disp_time_blink,
                                            font = FONT,
                                            color = "#444",
                                        ),
                                    ),
                                    render.Text(
                                        content = disp_time_blink,
                                        font = FONT,
                                        color = "#AAA",
                                    ),
                                ],
                            ),
                        ) if blink_time else None,
                    ],
                ) if time_format else None,
            ],
        ),
    )

#######
#
# return specific mask 1x1 pixel image from array sorted by alpha percentage
#
#######
def getmaskpixel(x, y, phase, latitude):
    return mask_images[select_mask_image(percent_illuminated(x, y, phase, latitude))]

#######
#
# return percent illumination of moon image based on pixel coordinates, moon phase, and user's (earth) latitude
#
#######
def percent_illuminated(x, y, phase, latitude):
    # Offset x and y so that (0, 0) is center of moon
    x -= X_C
    y -= Y_C

    # Rotate x and y by latitude so that crescents look as at user's latitude
    # (crescents look vertical at poles, horizontal at equator)
    rot = math.pi / 2 - math.radians(latitude)
    xr = x * math.cos(rot) - y * math.sin(rot)
    yr = x * math.sin(rot) + y * math.cos(rot)

    lambda_0 = phase  # lambda_0 represents lunar longitude offset in orthographic projection onto plane, in this case treating lunar longitude as moon phase, where 0 is new, pi is full

    # following equations are simplified from the inverse functions in https://en.wikipedia.org/wiki/Orthographic_map_projection, specifically phi_0 = 0 (phi_0 representing latitude tilt of moon, so phi_0 = 0 represents equator-centric view, i.e., just the crescent/gibbous view of the longitude lines)
    rho = math.sqrt(xr * xr + yr * yr)
    c = math.asin(rho / R)
    moon_lng = lambda_0 + math.atan2(xr * math.sin(c), rho * math.cos(c))

    illum = 0.0  # default

    # logic: if moon_lng < 90 or > 270, it's fully in shadow (meaning start fade at 90/270, don't center fade around those angles)
    # reason: don't want time around new moon to have extended appearance of new moon, new moon should be as close to instantaneous as possible
    # reason #2: totally ok and desirable to have day or two around full moon to change fading around edges of moon and still look basically full - moon does this in real life

    # logic: within FADE_LNG, take 4th root of delta to determine brightness
    # reason: make line between light/shadow crisp, sharp at the dark side, soften the curve towards maximum brightness, no other reason than it looked good to me and made time near full moon look good shading-wise

    if (moon_lng < math.pi / 2 or moon_lng > 3 * math.pi / 2):
        illum = SHADOW_LEVEL
    elif (moon_lng - math.pi / 2 > 0 and moon_lng - math.pi / 2 <= FADE_LNG):
        illum = SHADOW_LEVEL + math.sqrt(math.sqrt(1 - SHADOW_LEVEL) * ((moon_lng - math.pi / 2) / FADE_LNG))
    elif (3 * math.pi / 2 - moon_lng > 0 and 3 * math.pi / 2 - moon_lng <= FADE_LNG):
        illum = SHADOW_LEVEL + math.sqrt(math.sqrt(1 - SHADOW_LEVEL) * ((3 * math.pi / 2 - moon_lng) / FADE_LNG))
    elif (moon_lng > math.pi / 2 + FADE_LNG or moon_lng < 3 * math.pi / 2 - FADE_LNG):
        illum = 1.0

    return illum

#######
#
# convert illumination percentage (0 <= illumination_percent <= 1) to index into mask_images array
#
#######
def select_mask_image(illumination_percent):
    val = min(15, math.floor(math.round(illumination_percent * 16)))
    return val

#######
#
# get_schema
#
#######
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
            schema.Dropdown(
                id = "time_format",
                name = "Time Format",
                desc = "The format used for the time.",
                icon = "clock",
                default = "None",
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
        ],
    )

#######
#
# image data and array of images follows
#
#######

# Moon image is taken from NASA video at https://svs.gsfc.nasa.gov/4310, retouched by Chris Wyman

#######
#
# array of 1x1 pixel images from opaque black to transparent black in equal transparency jumps
#
#######
mask_images = [
    BLACK_PIXEL,
    DARK01_PIXEL,
    DARK02_PIXEL,
    DARK03_PIXEL,
    DARK04_PIXEL,
    DARK05_PIXEL,
    DARK06_PIXEL,
    DARK07_PIXEL,
    DARK08_PIXEL,
    DARK09_PIXEL,
    DARK10_PIXEL,
    DARK11_PIXEL,
    DARK12_PIXEL,
    DARK13_PIXEL,
    DARK14_PIXEL,
    CLEAR_PIXEL,
]
