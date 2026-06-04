"""
Applet: NationalDay
Summary: National Day Calendar
Description: Show what national day celebrations are today. 
Author: jvivona
"""
# API Data is derived from National Day Calendar at https://www.nationaldaycalendar.com/

load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("time.star", "time")

VERSION = 24314

TEXT_COLOR = "#fff"
TITLE_TEXT_COLOR = "#fff"
TITLE_BKG_COLOR = "#6666ff88"
TITLE_FONT = "tom-thumb"
TITLE_HEIGHT = 7
FULL_WIDTH = 64

ARTICLE_SUB_TITLE_FONT = "tom-thumb"
ARTICLE_SUB_TITLE_COLOR = ["#ff8c00", "#00eeff"]
ARTICLE_COLOR = "#00eeff"
SPACER_COLOR = "#000"
ARTICLE_AREA_HEIGHT = 24
SPACER_HEIGHT = 4

DEFAULT_TIMEZONE = "America/New_York"
CACHE_TTL_SECONDS = 3600

def main(config):
    now_unformatted = time.now().in_location(config.get("$tz", DEFAULT_TIMEZONE))
    json_data = ""
    rc, data = getData()

    # default the displayed date to the device clock; override with the
    # date the data is actually for, sourced from the JSON metadata, so the
    # header always matches the content shown below it
    display_date = now_unformatted.format("Jan 2")
    if rc == 0:
        json_data = data["today"]
        metadata = data.get("metadata") or {}
        day_str = metadata.get("day") or ""
        if day_str != "":
            display_date = format_day(day_str, display_date)
    else:
        json_data = data

    if not config.bool("$widget", False):
        return render.Root(
            delay = 100,
            show_full_animation = True,
            child = render.Column(
                children = [
                    title(display_date),
                    render.Marquee(
                        height = ARTICLE_AREA_HEIGHT,
                        scroll_direction = "vertical",
                        offset_start = ARTICLE_AREA_HEIGHT,
                        child =
                            render.Column(
                                main_align = "space_between",
                                cross_align = "center",
                                children =
                                    displayItem(json_data),
                            ),
                    ) if rc == 0 and len(json_data) > 0 else error(json_data if rc != 0 else "No national days today"),
                ],
            ),
        )
    else:
        return render.Root(
            child = render.Column(
                children = [
                    title(display_date),
                    render.Column(
                        children = [render.WrappedText(json_data[getRandomItem(len(json_data))], font = ARTICLE_SUB_TITLE_FONT, color = ARTICLE_COLOR, align = "center", width = FULL_WIDTH) if rc == 0 and len(json_data) > 0 else error(json_data if rc != 0 else "No national days today")],
                        main_align = "center",
                        cross_align = "center",
                        expanded = True,
                    ),
                ],
            ),
        )

def title(display_date):
    return render.Box(
        width = FULL_WIDTH,
        height = TITLE_HEIGHT,
        padding = 0,
        color = TITLE_BKG_COLOR,
        child = render.Text("Nat'l Day {}".format(display_date), color = TITLE_TEXT_COLOR, font = TITLE_FONT, offset = -1),
    )

def format_day(day_str, fallback):
    # metadata "day" looks like "June 3, 2026"; reformat to the compact
    # "Jun 3" style the title used previously. Done with plain string ops
    # because time.parse_time raises (uncatchable in Starlark) on bad input;
    # fall back to the device-clock date if the value isn't shaped as expected.
    parts = day_str.split(" ")
    if len(parts) < 2:
        return fallback
    return "{} {}".format(parts[0][:3], parts[1].replace(",", ""))

def getRandomItem(length):
    return random.number(0, length - 1)

def error(errtext):
    return render.WrappedText(errtext, font = ARTICLE_SUB_TITLE_FONT, color = ARTICLE_COLOR)

def getData():
    # go get the data
    url = "https://raw.githubusercontent.com/jvivona/tidbyt-data/refs/heads/main/nationalday/nationalday.json"
    response = http.get(url = url, ttl_seconds = CACHE_TTL_SECONDS)
    if response.status_code != 200:
        return -1, "Data retreival error {}".format(str(response.status_code))
    else:
        json_data = response.json()

    return 0, json_data

def displayItem(json_data):
    item = []

    for i in range(len(json_data)):
        item.append(render.WrappedText(json_data[i], font = ARTICLE_SUB_TITLE_FONT, color = ARTICLE_SUB_TITLE_COLOR[i % 2], align = "center"))
        item.append(render.Box(width = FULL_WIDTH, height = SPACER_HEIGHT, color = SPACER_COLOR))

    return item
