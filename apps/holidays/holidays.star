"""
Applet: Holidays
Summary: Date + holidays/birthdays
Description: Shows the current date along with icons for US national holidays and customizable birthdays.
Author: Andrey Goder
"""

load("encoding/base64.star", "base64")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/img_15c4b116.png", IMG_15c4b116_ASSET = "file")
load("images/img_1eabcf71.png", IMG_1eabcf71_ASSET = "file")
load("images/img_41bd8a2a.png", IMG_41bd8a2a_ASSET = "file")
load("images/img_548cc0d5.png", IMG_548cc0d5_ASSET = "file")
load("images/img_7eb84c6d.png", IMG_7eb84c6d_ASSET = "file")
load("images/img_92e4cea3.png", IMG_92e4cea3_ASSET = "file")
load("images/img_99b8cddf.png", IMG_99b8cddf_ASSET = "file")
load("images/img_9c4be22b.png", IMG_9c4be22b_ASSET = "file")
load("images/img_a313ccef.png", IMG_a313ccef_ASSET = "file")
load("images/img_b1a1c3ab.png", IMG_b1a1c3ab_ASSET = "file")
load("images/img_b30e2cb6.png", IMG_b30e2cb6_ASSET = "file")
load("images/img_bdac0df3.png", IMG_bdac0df3_ASSET = "file")
load("images/img_c45a7f86.png", IMG_c45a7f86_ASSET = "file")
load("images/img_d57404ed.png", IMG_d57404ed_ASSET = "file")
load("images/img_f2509c56.png", IMG_f2509c56_ASSET = "file")

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
CALENDAR = base64.decode(
    IMG_b1a1c3ab_ASSET.readall(),
)

FIREWORKS = base64.decode(
    IMG_9c4be22b_ASSET.readall(),
)

HEART = base64.decode(
    IMG_b30e2cb6_ASSET.readall(),
)

TREE = base64.decode(
    IMG_c45a7f86_ASSET.readall(),
)

CAKE = base64.decode(
    IMG_1eabcf71_ASSET.readall(),
)

CONFETTI = base64.decode(
    IMG_99b8cddf_ASSET.readall(),
)

NEW_YEAR = base64.decode(
    IMG_15c4b116_ASSET.readall(),
)

PUMPKIN = base64.decode(
    IMG_548cc0d5_ASSET.readall(),
)

CLOVER = base64.decode(
    IMG_7eb84c6d_ASSET.readall(),
)

TURKEY = base64.decode(
    IMG_41bd8a2a_ASSET.readall(),
)

MLK = base64.decode(
    IMG_bdac0df3_ASSET.readall(),
)

PRESIDENT = base64.decode(
    IMG_d57404ed_ASSET.readall(),
)

COLUMBUS = base64.decode(
    IMG_f2509c56_ASSET.readall(),
)

MEMORIAL = base64.decode(
    IMG_a313ccef_ASSET.readall(),
)

LABOR = base64.decode(
    IMG_92e4cea3_ASSET.readall(),
)
