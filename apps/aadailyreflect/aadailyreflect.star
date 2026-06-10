"""
Applet: AA Daily Reflections
Summary: Display the AA Daily Reflection
Description: Display AA Daily Refelection
Author: jvivona
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")

VERSION = 23132

APPTITLE_TEXT_COLOR = "#fff"
APPTITLE_BKG_COLOR = "#0000ff"
APPTITLE_FONT = "tom-thumb"
APPTITLE_HEIGHT = 5
APPTITLE_WIDTH = 64

REFLECTION_AREA_HEIGHT = 26
REFLECTION_SUB_TITLE_FONT = "tom-thumb"
REFLECTION_SUB_TITLE_COLOR = "#ff8c00"
REFLECTION_FONT = "tb-8"
REFLECTION_COLOR = "#00eeff"
SPACER_COLOR = "#000"
REFLECTION_LINESPACING = 0

# daily reflection data is published as clean JSON, refreshed once per day
DATA_URL = "https://raw.githubusercontent.com/jvivona/tidbyt-data/refs/heads/main/aa/dailyreflection.json"

#data changes once per day, but cache for 2 hours so updates are picked up sooner
CACHE_TTL_SECONDS = 7200

def main():
    return render.Root(
        delay = 75,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Marquee(
                    height = REFLECTION_AREA_HEIGHT,
                    scroll_direction = "vertical",
                    offset_start = 16,
                    child =
                        render.Column(
                            main_align = "space_between",
                            children = render_text(),
                        ),
                ),
                render.Box(
                    width = APPTITLE_WIDTH,
                    height = 1,
                    padding = 0,
                    color = APPTITLE_BKG_COLOR,
                ),
                render.Box(
                    width = APPTITLE_WIDTH,
                    height = APPTITLE_HEIGHT,
                    padding = 0,
                    color = "#000",
                    child = render.Text("Daily Reflection", color = APPTITLE_TEXT_COLOR, font = APPTITLE_FONT, offset = -1),
                ),
            ],
        ),
    )

def get_cachable_data(url):
    res = http.get(url = url, ttl_seconds = CACHE_TTL_SECONDS)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

def render_text():
    daily_reflection = json.decode(get_cachable_data(DATA_URL))

    title = daily_reflection.get("title", "").title()
    teaser = daily_reflection.get("summary", "")
    reference = daily_reflection.get("reference", "").title().replace("Pp.", "pp.").replace("P.", "p.")

    if len(title) == 0 or len(teaser) == 0:
        return error()

    return [
        render.WrappedText(title, font = REFLECTION_SUB_TITLE_FONT, color = REFLECTION_SUB_TITLE_COLOR, linespacing = REFLECTION_LINESPACING),
        render.Box(width = 64, height = 3, color = SPACER_COLOR),
        render.WrappedText(teaser, font = REFLECTION_FONT, color = REFLECTION_COLOR, linespacing = REFLECTION_LINESPACING),
        render.Box(width = 64, height = 3, color = SPACER_COLOR),
        render.WrappedText(reference, font = REFLECTION_SUB_TITLE_FONT, color = REFLECTION_SUB_TITLE_COLOR, linespacing = REFLECTION_LINESPACING),
    ]

def error():
    return [render.WrappedText("An error has occurred getting the daily reflection.", width = 64)]
