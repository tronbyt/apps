"""
Applet: Vital Occupancy
Summary: Vital Gym Current Occupancy
Description: The Current Occupancy of Vital Climbing's Brooklyn, NY location.
Author: flip-z
"""

load("http.star", "http")
load("images/logo.png", LOGO_ASSET = "file")
load("render.star", "render")

GYM_URL = "https://display.safespace.io/value/live/a7796f34"

def main():
    req = http.get(GYM_URL, ttl_seconds = 60)
    if req.status_code != 200:
        fail("Gym Request failed with status %d", req.status_code)

    currocc = req.body()

    color = "#cd0800"  # red
    if int(currocc) < 120:
        color = "#26ff7b"  # green
    elif int(currocc) < 150:
        color = "#ffd766"  # yellow

    if int(currocc) == 69:
        currocc_child = render.Animation(
            children = [
                render.Text(currocc, font = "10x20", color = color),
                render.Text(currocc, font = "10x20", color = "#aa39d3"),
                render.Text(currocc, font = "10x20", color = "#d2b1ea"),
                render.Text(currocc, font = "10x20", color = "#d6daff"),
            ],
        )
    else:
        currocc_child = render.Text(currocc, font = "10x20", color = color)

    return render.Root(
        child = render.Box(
            child = render.Column(
                expanded = True,
                main_align = "space_around",
                cross_align = "center",
                children = [
                    currocc_child,
                    render.Image(src = LOGO_ASSET.readall()),
                ],
            ),
        ),
    )
