"""
Applet: Holidays
Summary: Date + holidays/birthdays
Description: Shows the current date along with icons for US national holidays and customizable birthdays.
Author: Andrey Goder
"""

load("humanize.star", "humanize")
load("images/icon_cake.png", ICON_CAKE_ASSET = "file")
load("images/icon_calendar.png", ICON_CALENDAR_ASSET = "file")
load("images/icon_clover.png", ICON_CLOVER_ASSET = "file")
load("images/icon_columbus.png", ICON_COLUMBUS_ASSET = "file")
load("images/icon_confetti.png", ICON_CONFETTI_ASSET = "file")
load("images/icon_fireworks.png", ICON_FIREWORKS_ASSET = "file")
load("images/icon_heart.png", ICON_HEART_ASSET = "file")
load("images/icon_labor.png", ICON_LABOR_ASSET = "file")
load("images/icon_memorial.png", ICON_MEMORIAL_ASSET = "file")
load("images/icon_mlk.png", ICON_MLK_ASSET = "file")
load("images/icon_new_year.png", ICON_NEW_YEAR_ASSET = "file")
load("images/icon_president.png", ICON_PRESIDENT_ASSET = "file")
load("images/icon_pumpkin.png", ICON_PUMPKIN_ASSET = "file")
load("images/icon_tree.png", ICON_TREE_ASSET = "file")
load("images/icon_turkey.png", ICON_TURKEY_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TIMEZONE = "America/Los_Angeles"

def main(config):
    HOLIDAYS = {
        "Jan 1": NEW_YEAR,
        "Feb 14": HEART,
        "Mar 17": CLOVER,
        "Jul 4": FIREWORKS,
        "Oct 31": PUMPKIN,
        "Dec 25": TREE,
        "Dec 31": CONFETTI,
    }

    timezone = time.tz()

    now = time.now().in_location(timezone)
    date = now.format("Jan 2")

    # Handle special holidays that don't fall on a specific date
    if now.month == 1 and now.day == get_nth_dow(now, 3, 1).day:
        icon = MLK
    elif now.month == 2 and now.day == get_nth_dow(now, 3, 1).day:
        icon = PRESIDENT
    elif now.month == 5 and now.day == get_nth_dow(now, -1, 1).day:
        icon = MEMORIAL
    elif now.month == 9 and now.day == get_nth_dow(now, 1, 1).day:
        icon = LABOR
    elif now.month == 10 and now.day == get_nth_dow(now, 2, 1).day:
        icon = COLUMBUS
    elif now.month == 11 and now.day == get_nth_dow(now, 4, 4).day:
        icon = TURKEY
    elif date in HOLIDAYS:
        icon = HOLIDAYS[date]
    else:
        icon = CALENDAR

    # Handle birthday overrides
    num_birthdays = config.str("num_birthdays")
    if num_birthdays:
        num_birthdays = int(num_birthdays)
    else:
        num_birthdays = 0
    if num_birthdays > 0:
        for x in range(num_birthdays):
            val = config.str("birthday-" + str(x))
            if val and len(val) > 4:
                d = time.parse_time(val, "Jan 2")
                if d and d.month == now.month and d.day == now.day:
                    icon = CAKE
                    break

    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = [
                render.Column(
                    cross_align = "center",
                    main_align = "center",
                    children = [
                        render.Text(date),
                        render.Text(now.format("2006")),
                    ],
                ),
                render.Column(
                    expanded = True,
                    main_align = "center",
                    children = [
                        render.Image(src = icon, height = 28, width = 28),
                    ],
                ),
            ],
        ),
    )

# Gets the n-th day of week of the given month. For example:
# get_nth_dow(now, 4, 4) gets the 4th Thursday in November
def get_nth_dow(now, n, dow):
    counter = 0
    for day in range(1, 31):
        t = time.time(year = now.year, month = now.month, day = day)
        day = humanize.day_of_week(t)
        if day == dow:
            counter += 1
            if n == -1 and 31 - t.day < 7:
                return t
        if counter == n:
            return t
    return None

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "num_birthdays",
                name = "Number of Birthdays",
                desc = "Specify the number of birthdays to add",
                icon = "cakeCandles",
            ),
            schema.Generated(
                id = "generated",
                source = "num_birthdays",
                handler = more_options,
            ),
        ],
    )

def more_options(num):
    l = []
    if not num:
        return l
    for x in range(int(num)):
        l.append(
            schema.Text(
                id = "birthday-" + str(x),
                name = "Birthday " + str(x + 1),
                desc = "Specify the birthday as a month and day, like 'Jan 22'",
                icon = "cakeCandles",
                default = "",
            ),
        )
    return l

# Icons from https://www.flaticon.com/free-icons/
# (free with attribution)
CALENDAR = ICON_CALENDAR_ASSET.readall()
FIREWORKS = ICON_FIREWORKS_ASSET.readall()
HEART = ICON_HEART_ASSET.readall()
TREE = ICON_TREE_ASSET.readall()
CAKE = ICON_CAKE_ASSET.readall()
CONFETTI = ICON_CONFETTI_ASSET.readall()
NEW_YEAR = ICON_NEW_YEAR_ASSET.readall()
PUMPKIN = ICON_PUMPKIN_ASSET.readall()
CLOVER = ICON_CLOVER_ASSET.readall()
TURKEY = ICON_TURKEY_ASSET.readall()
MLK = ICON_MLK_ASSET.readall()
PRESIDENT = ICON_PRESIDENT_ASSET.readall()
COLUMBUS = ICON_COLUMBUS_ASSET.readall()
MEMORIAL = ICON_MEMORIAL_ASSET.readall()
LABOR = ICON_LABOR_ASSET.readall()
