"""
Applet: Solar Elevation
Summary: How high is the sun
Description: A clock for when you cannot look out of the window or at an actual clock. How high is the sun above or below the horizon right now?
Author: dinosaursrarr
"""

load("encoding/json.star", "json")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("sunrise.star", "sunrise")
load("time.star", "time")

DEFAULT_LOCATION = """
 {
     "lat": 52.0406,
     "lng": -0.7594,
     "locality": "Milton Keynes, UK",
     "timezone": "Europe/London"
 }
 """

# Sunrise and sunset occur when the center of the sun is 50 arc minutes
# below the horizon, due to a) refraction and b) us caring about when
# the top is over the horizon, rather than the middle.
# https://en.wikipedia.org/wiki/Sunrise#Angle
SUNRISE_ELEVATION = -50.0 / 60.0

# Sun is about half a degree across in the sky.
SOLAR_ANGULAR_RADIUS = 0.25

def draw(elevation):
    rounded_elevation = str(int(math.round(math.fabs(elevation) * 100)))
    rounded_degrees = rounded_elevation[0:-2] + "." + rounded_elevation[-2:]

    direction = "above" if elevation >= 0 else "below"

    horizon_pad = 29 if elevation >= -SOLAR_ANGULAR_RADIUS else 0

    if elevation > SOLAR_ANGULAR_RADIUS:
        # There are 13 possible states between the sun being at its highest
        # and being entirely above the horizon.
        angle_per_frame = (90.0 - SOLAR_ANGULAR_RADIUS) / 12.0
        sun_pad = int(math.round((90.0 - elevation) / angle_per_frame))
    elif elevation >= -SOLAR_ANGULAR_RADIUS:
        # There are 16 possible states where the sun is partially overlapping
        # the horizon
        angle_per_frame = (2.0 * SOLAR_ANGULAR_RADIUS) / 16.0
        sun_pad = 13 + int(math.round((SOLAR_ANGULAR_RADIUS - elevation) / angle_per_frame))
    else:
        # There are 13 possible states where the sun is entirely below the horizon
        angle_per_frame = (-90.0 + SOLAR_ANGULAR_RADIUS) / 13.0
        sun_pad = 14 - int(math.round((-90.0 - elevation) / angle_per_frame))

    # TODO: Background colours? Blue during day, sunset/sunrise gradient, dark at night?
    # The sun dial and the reading sit side by side on a 64x32 panel; a
    # square panel has the rows to stack them, each in its own half.
    layout = render.Column if is_square() else render.Row

    # Stacked, each half is centred by a full-width Box rather than by
    # cross_align, which an expanded Column does not apply to fixed-size
    # children.
    def half(widget):
        if is_square():
            return render.Box(width = 62, height = 30, child = widget)
        return widget

    return render.Padding(
        pad = (1, 1, 1, 1),
        child = layout(
            main_align = "space_evenly" if is_square() else "center",
            cross_align = "center",
            expanded = True,
            children = [
                half(render.Box(
                    width = 30,
                    height = 30,
                    color = "#000",
                    child = render.Stack(
                        children = [
                            render.Box(
                                width = 30,
                                height = 30,
                                color = "#000",
                            ),
                            render.Padding(
                                pad = (7, sun_pad, 0, 0),
                                child = render.Circle(
                                    diameter = 16,
                                    color = "#ff0",
                                ),
                            ),
                            render.Padding(
                                pad = (0, horizon_pad, 0, 0),
                                child = render.Box(
                                    width = 30,
                                    height = 1,
                                    color = "#fff",
                                ),
                            ),
                        ],
                    ),
                )),
                # the gap between the dial and the reading when they sit
                # side by side; stacked, the two 30px boxes already fill the
                # 62 padded rows and there is none
                None if is_square() else render.Box(
                    width = 2,
                    height = 30,
                    color = "#000",
                ),
                half(render.Box(
                    width = 30,
                    height = 30,
                    color = "#000",
                    child = render.Column(
                        main_align = "center",
                        children = [
                            render.WrappedText(
                                content = "{}° {}".format(rounded_degrees, direction),
                                width = 28,
                                align = "center",
                            ),
                        ],
                    ),
                )),
            ],
        ),
    )

def is_square():
    """True on a 64x64 panel.

    Panels are told apart by SHAPE, never by size: the 128x64 wide panel is
    also 64 tall.
    """
    w, h = canvas.size()
    return h == w

def main(config):
    location = json.decode(config.get("location", DEFAULT_LOCATION))
    latitude = float(location["lat"])
    longitude = float(location["lng"])

    now = time.now()
    elevation = sunrise.elevation(latitude, longitude, now)

    return render.Root(
        max_age = 120,
        child = draw(elevation),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display the solar elevation",
                icon = "locationDot",
            ),
        ],
    )
