"""
Applet: Halloween CountDn
Summary: Days until Halloween
Description: Displays the number of days until Halloween.
Author: Anthony Rocchio
"""

load("images/ghost_gif.gif", GHOST_GIF_ASSET = "file")
load("images/jack_gif.gif", JACK_GIF_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("time.star", "time")

GHOST_GIF = GHOST_GIF_ASSET.readall()
JACK_GIF = JACK_GIF_ASSET.readall()

def main():
    timezone = time.tz()
    now = time.now().in_location(timezone)

    halloween_year = now.year
    if now.month > 10:
        halloween_year = now.year + 1

    halloween = time.time(year = halloween_year, month = 10, day = 31, hour = 0, minute = 0, location = timezone)
    days_til_halloween = math.ceil(time.parse_duration(halloween - now).seconds / 86400)

    display_content = ""
    font_size = "6x13"
    if days_til_halloween == 0:
        display_content = "HALL\n-O-\nWEEN!"
        font_size = "5x8"
    else:
        display_content = "%s\ndays" % days_til_halloween

    return render.Root(
        delay = 500,
        child = render.Row(
            main_align = "center",
            cross_align = "center",
            expanded = True,
            children = [
                render.Image(
                    src = GHOST_GIF,
                    width = 20,
                    height = 35,
                ),
                render.WrappedText(
                    content = display_content,
                    font = font_size,
                    color = "#ff751a",
                    align = "center",
                ),
                render.Image(
                    src = JACK_GIF,
                    width = 20,
                    height = 35,
                ),
            ],
        ),
    )
