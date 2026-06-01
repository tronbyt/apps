"""
Applet: Days to Xmas
Summary: Displays Days to Xmas
Description: Display a countdown of days left til Christmas Day.
Author: Godfrey Systems Web Development
"""

load("images/present_icon.gif", PRESENT_ICON_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("time.star", "time")

PRESENT_ICON = PRESENT_ICON_ASSET.readall()

def main():
    timezone = time.tz()  # Utilize special timezone variable
    now = time.now().in_location(timezone)
    today = time.time(year = now.year, month = now.month, day = now.day, location = timezone)
    current_xmas = time.time(year = today.year, month = 12, day = 25, location = timezone)

    if today > current_xmas:
        current_xmas = time.time(year = today.year + 1, month = 12, day = 25, location = timezone)

    xmas_datestring = current_xmas.format("Jan 02, 2006")

    date_diff = current_xmas - now
    days = math.ceil(date_diff.hours / 24)

    description = "{} left".format("Day" if days == 1 else "Days")

    return render.Root(
        child = render.Stack(
            children = [
                render.Padding(
                    pad = (0, 0, 0, 0),
                    child = render.Box(
                        width = 32,
                        height = 16,
                        child = render.Image(
                            src = PRESENT_ICON,
                        ),
                    ),
                ),
                render.Padding(
                    pad = (32, 0, 0, 0),
                    child = render.Box(
                        width = 32,
                        height = 16,
                        child = render.Text(
                            content = str(days),
                            color = "#FFFFFF",
                            font = "10x20",
                            height = 0,
                            offset = 0,
                        ),
                    ),
                ),
                render.Padding(
                    pad = (0, 16, 0, 0),
                    child = render.Box(
                        width = 64,
                        height = 8,
                        child = render.Text(
                            content = description,
                            color = "#FFFFFF",
                            font = "CG-pixel-3x5-mono",
                        ),
                    ),
                ),
                render.Padding(
                    pad = (0, 24, 0, 0),
                    child = render.Box(
                        width = 64,
                        height = 8,
                        child = render.Text(
                            content = xmas_datestring,
                            color = "#FFFFFF",
                            font = "CG-pixel-4x5-mono",
                        ),
                    ),
                ),
            ],
        ),
    )
