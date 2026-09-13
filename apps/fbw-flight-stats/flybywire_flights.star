"""
Applet: FlyByWire Flights
Summary: FlyByWire Number of Flights
Description: Shows a count of the number of flights using the FlyByWire Simulations systems.
Author: Philippe Dellaert (pdellaert)
"""

load("animation.star", "animation")
load("http.star", "http")
load("images/fbw_icon.png", FBW_ICON_ASSET = "file")
load("render.star", "render")

FBW_ICON = FBW_ICON_ASSET.readall()

FBW_COUNT_API = "https://api.flybywiresim.com/txcxn/_count"

def getCount():
    response = http.get(FBW_COUNT_API, ttl_seconds = 60)
    if response.status_code == 200:
        return response.body()
    else:
        print("Failed to fetch data from API. Status code:", response.status_code)
        return "N/A"

def main():
    return render.Root(
        child = animation.Transformation(
            child = render.Row(
                expanded = True,
                cross_align = "center",
                main_align = "space_around",
                children = [
                    render.Padding(
                        child = render.Image(
                            src = FBW_ICON,
                            width = 32,
                            height = 30,
                        ),
                        pad = (0, 1, 0, 0),
                    ),
                    render.Text(
                        content = "%s" % getCount(),
                        font = "6x13",
                        color = "#00c2cc",
                    ),
                ],
            ),
            keyframes = [
                animation.Keyframe(
                    percentage = 0.0,
                    curve = "ease_in",
                    transforms = [
                        animation.Translate(
                            x = 64,
                            y = 0,
                        ),
                    ],
                ),
                animation.Keyframe(
                    percentage = 0.1,
                    transforms = [
                        animation.Translate(
                            x = 0,
                            y = 0,
                        ),
                    ],
                ),
                animation.Keyframe(
                    percentage = 0.9,
                    transforms = [],
                ),
                animation.Keyframe(
                    percentage = 1.0,
                    transforms = [
                        animation.Translate(
                            x = -64,
                            y = 0,
                        ),
                    ],
                ),
            ],
            origin = animation.Origin(x = 1, y = 0),
            duration = 250,
            delay = 0,
        ),
    )
