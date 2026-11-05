"""
Applet: ComEd Price
Summary: ComEd Hourly Pricing
Description: Pulls the current hour average price from hourlypricing.comed.com.
Author: Andrew Hill
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("images/comed_icon.png", COMED_ICON_ASSET = "file")
load("render.star", "render")

COMED_ICON = COMED_ICON_ASSET.readall()

CURRENT_HOUR_AVG = "https://hourlypricing.comed.com/api?type=currenthouraverage&format=text"

def main():
    rep = http.get(CURRENT_HOUR_AVG, ttl_seconds = 360)
    if rep.status_code != 200:
        fail("ComEd request failed with status %d", rep.status_code)

    price = float(rep.body().split(":")[1].split(",")[0])

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Image(src = COMED_ICON, width = 17, height = 17),
                        render.Text(content = "%s¢" % humanize.float("0.#", price), font = "6x13"),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "end",
                    children = [
                        render.Text(content = "ComEd Price", offset = -1, font = "tb-8"),
                    ],
                ),
            ],
            main_align = "center",
            cross_align = "center",
            expanded = True,
        ),
    )
