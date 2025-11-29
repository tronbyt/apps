"""
Applet: Gen Con Countdown
Summary: Counts down to Gen Con
Description: Counts down the days until the next Gen Con.
Author: nikmd23
"""

load("humanize.star", "humanize")
load("images/gencon_logo.png", GENCON_LOGO_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("time.star", "time")

GENCON_LOGO = GENCON_LOGO_ASSET.readall()

NOW = time.now().in_location("Etc/UTC")
START_DATES = [
    1659589200,  #2022
    1691038800,  #2023
    1722488400,  #2024
    1753938000,  #2025
    1785387600,  #2026
]

def main():
    GENCON_START = None
    for start_date in START_DATES:
        if start_date > NOW.unix:
            GENCON_START = time.from_timestamp(start_date)
            break

    DIFF = GENCON_START - NOW
    DAYS = math.ceil(DIFF.hours / 24)

    if DAYS <= 360:
        OUTPUT = render.WrappedText("{} more {}".format(DAYS, humanize.plural_word(DAYS, "day!", "days")), align = "center")
    else:
        OUTPUT = render.WrappedText("Go now!", align = "center")

    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Padding(pad = 2, child = render.Image(src = GENCON_LOGO)),
                OUTPUT,
            ],
        ),
    )
