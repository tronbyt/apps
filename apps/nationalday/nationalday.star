"""
Applet: National Day/Week/Month
Summary: Day, Week & Month Calendar
Description: Show what national day, week, or month celebrations are happening.
Author: jvivona
"""
# API Data is derived from National Day Calendar at https://www.nationaldaycalendar.com/

load("http.star", "http")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

VERSION = 24316

# 2x (128x64) uses the wider canvas and a larger font; 1x is unchanged.
IS2X = canvas.is2x()

TEXT_COLOR = "#fff"
TITLE_TEXT_COLOR = "#fff"
TITLE_BKG_COLOR = "#6666ff88"
TITLE_FONT = "tb-8" if IS2X else "tom-thumb"
TITLE_HEIGHT = 9 if IS2X else 7
FULL_WIDTH = 128 if IS2X else 64

# tb-8 centers cleanly with no offset (matches the news apps); tom-thumb at 1x
# still wants the -1 nudge.
TITLE_OFFSET = 0 if IS2X else -1

ARTICLE_SUB_TITLE_FONT = "tb-8" if IS2X else "tom-thumb"
ARTICLE_SUB_TITLE_COLOR = ["#ff8c00", "#00eeff"]
ARTICLE_COLOR = "#00eeff"
SPACER_COLOR = "#000"
ARTICLE_AREA_HEIGHT = 55 if IS2X else 24
SPACER_HEIGHT = 6 if IS2X else 4

DEFAULT_TIMEZONE = "America/New_York"
CACHE_TTL_SECONDS = 3600

BASE_URL = "https://raw.githubusercontent.com/jvivona/tidbyt-data/refs/heads/main/nationalday/"

# Each calendar mode: which feed file to pull, the header label, and the
# device-clock format string used as a fallback when the feed's metadata date
# is missing/malformed. All three feeds share the same JSON shape.
# 2x has room for the full word; 1x keeps "Nat'l" so "<label> <date>" fits the
# 64px title bar.
MODES = {
    "day": {"file": "nationalday.json", "label": "National Day" if IS2X else "Nat'l Day", "fallback": "Jan 2"},
    "week": {"file": "nationalweek.json", "label": "National Week" if IS2X else "Nat'l Week", "fallback": "1/2"},
    "month": {"file": "nationalmonth.json", "label": "National Month" if IS2X else "Nat'l Month", "fallback": "Jan"},
}
DEFAULT_MODE = "day"

# Keyed by the lowercased first three letters of the month name so the week
# lookup is robust to casing and to full-name vs abbreviated feed values
# ("June" / "june" / "Jun" / "JUN" all resolve via month_name[:3].lower()).
MONTH_NUM = {
    "jan": "1",
    "feb": "2",
    "mar": "3",
    "apr": "4",
    "may": "5",
    "jun": "6",
    "jul": "7",
    "aug": "8",
    "sep": "9",
    "oct": "10",
    "nov": "11",
    "dec": "12",
}

def main(config):
    mode = config.get("type", DEFAULT_MODE)
    if mode not in MODES:
        mode = DEFAULT_MODE
    mode_cfg = MODES[mode]

    now_unformatted = time.now().in_location(config.get("$tz", DEFAULT_TIMEZONE))
    rc, data = getData(mode_cfg["file"])

    # default the displayed date to the device clock; override with the date the
    # data is actually for, sourced from the JSON metadata, so the header always
    # matches the content shown below it
    date_str = now_unformatted.format(mode_cfg["fallback"])
    if rc == 0:
        json_data = data.get("today") or []
        metadata = data.get("metadata") or {}
        day_str = metadata.get("day") or ""
        if day_str != "":
            date_str = format_header_date(mode, day_str, date_str)
    else:
        json_data = data

    header = "{} {}".format(mode_cfg["label"], date_str)
    empty_msg = "No national {}s".format(mode)

    if not config.bool("$widget", False):
        return render.Root(
            delay = 100,
            show_full_animation = True,
            child = render.Column(
                children = [
                    title(header),
                    render.Marquee(
                        height = ARTICLE_AREA_HEIGHT,
                        scroll_direction = "vertical",
                        offset_start = ARTICLE_AREA_HEIGHT,
                        # only takes effect on short lists that fit without
                        # scrolling; the marquee ignores it once it scrolls
                        align = "center",
                        child =
                            render.Column(
                                main_align = "space_between",
                                cross_align = "center",
                                children =
                                    displayItem(json_data),
                            ),
                    ) if rc == 0 and len(json_data) > 0 else error(json_data if rc != 0 else empty_msg),
                ],
            ),
        )
    else:
        return render.Root(
            child = render.Column(
                children = [
                    title(header),
                    render.Column(
                        children = [render.WrappedText(json_data[getRandomItem(len(json_data))], font = ARTICLE_SUB_TITLE_FONT, color = ARTICLE_COLOR, align = "center", width = FULL_WIDTH) if rc == 0 and len(json_data) > 0 else error(json_data if rc != 0 else empty_msg)],
                        main_align = "center",
                        cross_align = "center",
                        expanded = True,
                    ),
                ],
            ),
        )

def title(header):
    return render.Box(
        width = FULL_WIDTH,
        height = TITLE_HEIGHT,
        padding = 0,
        color = TITLE_BKG_COLOR,
        child = render.Text(header, color = TITLE_TEXT_COLOR, font = TITLE_FONT, offset = TITLE_OFFSET),
    )

def format_header_date(mode, day_str, fallback):
    # metadata "day" looks like "June 3, 2026". Reformat per mode using plain
    # string ops (not time.parse_time, which raises uncatchably on bad input in
    # Starlark); fall back to the device-clock date if it isn't shaped as
    # expected.  day -> "Jun 3"   week -> "6/3"   month -> "Jun"
    parts = day_str.split(" ")
    if len(parts) < 2:
        return fallback
    month_name = parts[0]
    day_num = parts[1].replace(",", "")
    if mode == "week":
        month_num = MONTH_NUM.get(month_name[:3].lower())
        if month_num == None:
            return fallback
        return "{}/{}".format(month_num, day_num)
    elif mode == "month":
        return month_name[:3]
    else:  # day
        return "{} {}".format(month_name[:3], day_num)

def getRandomItem(length):
    return random.number(0, length - 1)

def error(errtext):
    return render.WrappedText(errtext, font = ARTICLE_SUB_TITLE_FONT, color = ARTICLE_COLOR)

def getData(filename):
    # go get the data
    url = BASE_URL + filename
    response = http.get(url = url, ttl_seconds = CACHE_TTL_SECONDS)
    if response.status_code != 200:
        return -1, "Data retreival error {}".format(str(response.status_code))
    else:
        json_data = response.json()

    return 0, json_data

def displayItem(json_data):
    item = []

    for i in range(len(json_data)):
        # spacer goes between items, never after the last one: a trailing
        # spacer is measured as part of the column and would push a centered
        # short list up by half its height
        if i > 0:
            item.append(render.Box(width = FULL_WIDTH, height = SPACER_HEIGHT, color = SPACER_COLOR))
        item.append(render.WrappedText(json_data[i], font = ARTICLE_SUB_TITLE_FONT, color = ARTICLE_SUB_TITLE_COLOR[i % 2], align = "center"))

    return item

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "type",
                name = "Calendar",
                desc = "Show national days, weeks, or months.",
                icon = "calendarDay",
                default = DEFAULT_MODE,
                options = [
                    schema.Option(display = "Day", value = "day"),
                    schema.Option(display = "Week", value = "week"),
                    schema.Option(display = "Month", value = "month"),
                ],
            ),
        ],
    )
