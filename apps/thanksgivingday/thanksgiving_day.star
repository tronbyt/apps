"""
Applet: Thanksgiving Day
Summary: Thanksgiving countdown
Description: Simple daily countdown until Thanksgiving Day holiday in the U.S.
Author: J. Alex Cooney
"""

load("humanize.star", "humanize")
load("images/trk_icon.gif", TRK_ICON_ASSET = "file")
load("render.star", "render")
load("time.star", "time")

TRK_ICON = TRK_ICON_ASSET.readall()

# Load Turkey icon from base64 encoded data

def main():
    def getthanksgivingday(year):
        nov30 = time.time(year = year, month = 11, day = 30, location = timezone)
        day_of_week = humanize.day_of_week(nov30)
        calc = day_of_week - 4
        if calc >= 0:
            day = 30 - calc
        else:
            day = 30 - (calc + 7)

        return day

    timezone = time.tz()
    now = time.time(year = time.now().year, month = time.now().month, day = time.now().day, location = timezone)

    day = getthanksgivingday(now.year)
    thanksgiving_day = time.time(year = now.year, month = 11, day = day, location = timezone)
    if now >= thanksgiving_day:
        next_year = now.year + 1
        day = getthanksgivingday(next_year)
        thanksgiving_day = time.time(year = next_year, month = 11, day = day, location = timezone)

    diff = thanksgiving_day - now
    diff_days = abs(int(diff.hours / 24))
    days_til_thanksgiving = diff_days

    return render.Root(
        delay = 1000,
        child = render.Row(
            # Row lays out its children horizontally
            main_align = "space_evenly",
            cross_align = "center",
            expanded = True,
            children = [
                render.Image(src = TRK_ICON),
                render.WrappedText(
                    content = "%s\ndays!" % days_til_thanksgiving,
                    font = "Dina_r400-6",
                    color = "#a60e00",
                    align = "center",
                ),
            ],
        ),
    )
