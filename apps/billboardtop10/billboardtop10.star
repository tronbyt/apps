"""
Applet: BillboardTop10
Summary: Display top 10 songs
Description: Displays top 10 songs from Billboard.
Author: Robert Ison
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/billboard_icon.png", BILLBOARD_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BILLBOARD_ICON = BILLBOARD_ICON_ASSET.readall()

BILLBOARD_SAMPLE_DATA = """{"info": {"category": "Billboard", "chart": "HOT 100", "date": "1983-05-14", "source": "Billboard-API"}, "content": {"1": {"rank": "1", "title": "Beat It", "artist": "Michael Jackson", "weeks at no.1": "3", "last week": "1", "peak position": "1", "weeks on chart": "12", "detail": "same"}, "2": {"rank": "2", "title": "Let's Dance", "artist": "David Bowie", "last week": "3", "peak position": "2", "weeks on chart": "8", "detail": "up"}, "3": {"rank": "3", "title": "Jeopardy", "artist": "Greg Kihn Band", "last week": "2", "peak position": "2", "weeks on chart": "16", "detail": "down"}, "4": {"rank": "4", "title": "Overkill", "artist": "Men At Work", "last week": "6", "peak position": "4", "weeks on chart": "6", "detail": "up"}, "5": {"rank": "5", "title": "She Blinded Me With Science", "artist": "Thomas Dolby", "last week": "7", "peak position": "5", "weeks on chart": "13", "detail": "up"}, "6": {"rank": "6", "title": "Come On Eileen", "artist": "Dexy's Midnight Runners", "last week": "4", "peak position": "1", "weeks on chart": "17", "detail": "down"}, "7": {"rank": "7", "title": "Flashdance...What A Feeling", "artist": "Irene Cara", "last week": "13", "peak position": "7", "weeks on chart": "7", "detail": "up"}, "8": {"rank": "8", "title": "Little Red Corvette", "artist": "Prince", "last week": "9", "peak position": "8", "weeks on chart": "12", "detail": "up"}, "9": {"rank": "9", "title": "Solitaire", "artist": "Laura Branigan", "last week": "11", "peak position": "9", "weeks on chart": "9", "detail": "up"}, "10": {"rank": "10", "title": "Der Kommissar", "artist": "After The Fire", "last week": "5", "peak position": "5", "weeks on chart": "14", "detail": "down"}}}"""

DEFAULT_COLORS = ["#FFF", "#f41b1c", "#ffe400", "#00b5f8"]

CACHE_TTL_SECONDS = 3 * 24 * 60 * 60  # 3 days in seconds

list_options = [
    schema.Option(
        display = "U.S. Songs",
        value = "hot-100",
    ),
    schema.Option(
        display = "Global Songs",
        value = "billboard-global-200",
    ),
]

def main(config):
    #cache Time 3 Days x 24 hours x 60 minutes x 60 seconds = 259200 seconds
    top10_data = None
    api_key = config.get("api_key")
    selected_list = config.get("list")

    if api_key:
        top10_data = get_top10_information(api_key, selected_list)

    sample_data = top10_data == None
    if sample_data:
        if api_key:
            print("Failed to get data from the api")

        # Use sample data if no API key or if API call fails
        top10_data = json.decode(BILLBOARD_SAMPLE_DATA)
    else:
        top10_data["DateFetched"] = time.now().format("2006-01-02T15:04:05Z07:00")

    fetched_time = None
    if ("DateFetched" in top10_data):
        fetched_time = time.parse_time(top10_data["DateFetched"])

    display_count = int(config.get("count", 10))
    if display_count not in [5,10]:
        display_count = 10

    row1 = "%s - Top %s" % (getListDisplayFromListValue(selected_list), display_count)
    row2 = getDisplayInfo(top10_data["content"]["1"])

    if (display_count == 10):
        row3 = getDisplayInfoMulti(top10_data["content"], 2, 5)
        row4 = getDisplayInfoMulti(top10_data["content"], 6, 10)
    else:
        row3 = getDisplayInfoMulti(top10_data["content"], 2, 3)
        row4 = getDisplayInfoMulti(top10_data["content"], 4, 5)

    if fetched_time != None:
        row4 = "%s -- %s" % (row4, fetched_time.format("Mon Jan 2 2006 15:04"))
    elif sample_data:
        row4 = "%s -- %s" % (row4, "Sample Data")

    return render.Root(
        render.Column(
            children = [
                render.Row(
                    children = [
                        render.Image(src = BILLBOARD_ICON),
                        render.Box(width = 1, height = 6, color = "#000000"),
                        render.Marquee(
                            width = 57,
                            height = 8,
                            child = render.Text(row1, font = "tb-8", color = config.get("color_1", DEFAULT_COLORS[0])),
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Marquee(
                            width = 64,
                            offset_start = 15,
                            child = render.Text(row2, font = "5x8", color = config.get("color_2", DEFAULT_COLORS[1])),
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Marquee(
                            width = 64,
                            offset_start = len(row2) * 5,# Assumes 5px/char
                            child = render.Text(row3, font = "5x8", color = config.get("color_3", DEFAULT_COLORS[2])),
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Marquee(
                            width = 64,
                            offset_start = (len(row2) + len(row3)) * 5,# Assumes 5px/char
                            child = render.Text(row4, font = "5x8", color = config.get("color_4", DEFAULT_COLORS[3])),
                        ),
                    ],
                ),
            ],
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def get_top10_information(top10_alive_key, list):
    thetime = most_recent_saturday(time.now())
    url = "https://billboard-api2.p.rapidapi.com/%s" % list
    res = http.get(
        url = url,
        params = {"date": thetime, "range": "1-10"},
        headers = {
            "X-RapidAPI-Host": "billboard-api2.p.rapidapi.com",
            "X-RapidAPI-Key": top10_alive_key,
        },
        ttl_seconds = CACHE_TTL_SECONDS,
    )

    if res.status_code == 200:
        return res.json()
    else:
        print(res.status_code)
        return None

def getMovementIndicator(this, last):
    movementIndicator = ""
    if (last != "" and last > 0):
        if this < last:
            movementIndicator = " (↑%s)" % (last - this)
        elif last < this:
            movementIndicator = " (↓%s)" % (this - last)

    return movementIndicator

def getListDisplayFromListValue(listValue):
    for item in list_options:
        if item.value == listValue:
            return item.display

    return ""

def getDisplayInfo(item):
    current = int(item["rank"])
    lastweek = item["last week"]
    if lastweek == "None":
        lastweek = 0
    else:
        lastweek = int(lastweek)

    display = "%s by %s #%s%s %s weeks on charts" % (item["title"], item["artist"], item["rank"], getMovementIndicator(current, lastweek), item["weeks on chart"])
    return display

def getDisplayInfoMulti(items, start, end):
    display = ""  # Initialize before starting the loop
    for i in range(start - 1, end):  # Only loop the needed range
        key = str(i + 1)
        item = items[key]
        current = int(item["rank"])
        lastweek = "" if item["last week"] == "None" else int(item["last week"])

        divider = "" if i + 1 == end else " * "
        display += "%s by %s is #%s%s%s" % (
            item["title"],
            item["artist"],
            item["rank"],
            getMovementIndicator(current, lastweek),
            divider,
        )

    return display

def _is_leap_year(y):
    return (y % 4 == 0 and y % 100 != 0) or (y % 400 == 0)

# Days before month m (1-based)
def _days_before_month(y, m):
    days = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
    d = days[m - 1]
    if m > 2 and _is_leap_year(y):
        d += 1
    return d

# Days since 1970-01-01
def _days_since_epoch(y, m, d):
    days = 0
    for yr in range(1970, y):
        days += 366 if _is_leap_year(yr) else 365
    days += _days_before_month(y, m)
    days += d - 1
    return days

# Inverse of days_since_epoch
def _date_from_days(days):
    y = 1970
    for yr in range(1970, 3000):
        year_days = 366 if _is_leap_year(yr) else 365
        if days >= year_days:
            days -= year_days
            y += 1
        else:
            break

    leap = _is_leap_year(y)
    month_lengths = [
        31,
        29 if leap else 28,
        31,
        30,
        31,
        30,
        31,
        31,
        30,
        31,
        30,
        31,
    ]

    m = 1
    for ml in month_lengths:
        if days >= ml:
            days -= ml
            m += 1
        else:
            break

    d = days + 1
    return (y, m, d)

def _pad2(n):
    s = str(n)
    return s if len(s) == 2 else "0" + s

def _pad4(n):
    s = str(n)
    return s if len(s) == 4 else "0" * (4 - len(s)) + s

def most_recent_saturday(t):
    today = _days_since_epoch(t.year, t.month, t.day)

    # 1970-01-01 was a Thursday → weekday = 4 if Sunday=0
    weekday = (today + 4) % 7

    # Saturday = 6
    delta = (weekday - 6) % 7

    y, m, d = _date_from_days(today - delta)

    return _pad4(y) + "-" + _pad2(m) + "-" + _pad2(d)

def get_schema():
    scroll_speed_options = [
        schema.Option(
            display = "Slow",
            value = "60",
        ),
        schema.Option(
            display = "Medium",
            value = "45",
        ),
        schema.Option(
            display = "Fast",
            value = "30",
        ),
    ]

    song_count_options = [
        schema.Option(
            display = "5",
            value = "5",
        ),
        schema.Option(
            display = "10",
            value = "10",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "RapidAPI Key",
                desc = "Your RapidAPI Key for the Billboard API.",
                icon = "key",
                secret = True,
            ),
            schema.Dropdown(
                id = "list",
                name = "Billboard Listing",
                desc = "",
                icon = "list",
                default = list_options[0].value,
                options = list_options,
            ),
            schema.Dropdown(
                id = "count",
                name = "Number of Songs",
                desc = "Number of songs to display",
                icon = "plusMinus",
                default = song_count_options[len(song_count_options) - 1].value,
                options = song_count_options,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
            schema.Color(
                id = "color_1",
                name = "Color",
                desc = "Line 1 Color",
                icon = "brush",
                default = DEFAULT_COLORS[0],
            ),
            schema.Color(
                id = "color_2",
                name = "Color",
                desc = "Line 2 Color",
                icon = "brush",
                default = DEFAULT_COLORS[1],
            ),
            schema.Color(
                id = "color_3",
                name = "Color",
                desc = "Line 3 Color",
                icon = "brush",
                default = DEFAULT_COLORS[2],
            ),
            schema.Color(
                id = "color_4",
                name = "Color",
                desc = "Line 4 Color",
                icon = "brush",
                default = DEFAULT_COLORS[3],
            ),
        ],
    )
