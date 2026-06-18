"""
Applet: AA Daily Reflections
Summary: Display the AA Daily Reflection
Description: Display AA Daily Refelection
Author: jvivona
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")

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
REFLECTION_BODY_COLOR = "#ffffff"
SPACER_COLOR = "#000"
REFLECTION_LINESPACING = 0

# 2x footer alternates the article title and the reference. Each is held for
# this many frames; at delay = 75ms that is ~3s per swap.
FOOTER_HOLD_FRAMES = 40

# daily reflection data is published as clean JSON, refreshed once per day
DATA_URL = "https://raw.githubusercontent.com/jvivona/tidbyt-data/refs/heads/main/aa/dailyreflection.json"

#data changes once per day, but cache for 2 hours so updates are picked up sooner
CACHE_TTL_SECONDS = 7200

def main():
    data = get_data()
    if not data["ok"]:
        return render.Root(child = render.WrappedText("An error has occurred getting the daily reflection.", width = 128 if canvas.is2x() else 64))
    if canvas.is2x():
        return render_2x(data)
    return render_1x(data)

def get_data():
    daily_reflection = json.decode(get_cachable_data(DATA_URL))

    data = {
        "title": daily_reflection.get("title", "").title(),
        "date": daily_reflection.get("date", ""),
        "summary": daily_reflection.get("summary", ""),
        "expanded": daily_reflection.get("expanded_text", ""),
        "fourth": daily_reflection.get("fourth_paragraph", ""),
        "reference": daily_reflection.get("reference", "").title().replace("Pp.", "pp.").replace("P.", "p."),
    }
    data["ok"] = len(data["title"]) > 0 and len(data["summary"]) > 0
    return data

def get_cachable_data(url):
    res = http.get(url = url, ttl_seconds = CACHE_TTL_SECONDS)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

def render_1x(data):
    # 64x32 layout (unchanged): scroll title / summary / reference up top, with
    # a fixed "Daily Reflection" label pinned to the bottom.
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
                            children = [
                                render.WrappedText(data["title"], font = REFLECTION_SUB_TITLE_FONT, color = REFLECTION_SUB_TITLE_COLOR, linespacing = REFLECTION_LINESPACING),
                                render.Box(width = 64, height = 3, color = SPACER_COLOR),
                                render.WrappedText(data["summary"], font = REFLECTION_FONT, color = REFLECTION_COLOR, linespacing = REFLECTION_LINESPACING),
                                render.Box(width = 64, height = 3, color = SPACER_COLOR),
                                render.WrappedText(data["reference"], font = REFLECTION_SUB_TITLE_FONT, color = REFLECTION_SUB_TITLE_COLOR, linespacing = REFLECTION_LINESPACING),
                            ],
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

def render_2x(data):
    # 128x64 layout: fixed "AA Daily Reflection" + date header, a scrolling
    # summary + expanded-text body, and a fixed footer that alternates between
    # the article title and the reference.
    #
    # Footer is two text lines tall. A pull of 30 days of aa.org data showed
    # ~40% of references (e.g. "Twelve Steps and Twelve Traditions, p. NN") and
    # a couple of titles overflow one 128px tb-8 line -- and that book title
    # overflows even on its own -- so a fixed two-line, word-wrapped footer is
    # what reliably fits them. The body is a scrolling viewport, so spending the
    # extra line on the footer costs no readability.
    footer_h = 16
    body_h = 64 - 10 - 1 - footer_h - 1  # canvas - header - line - footer - line

    body_children = [
        render.WrappedText(data["summary"], font = REFLECTION_FONT, color = REFLECTION_COLOR, linespacing = 1, width = 128),
        render.Box(width = 128, height = 4, color = SPACER_COLOR),
        render.WrappedText(data["expanded"], font = REFLECTION_FONT, color = REFLECTION_BODY_COLOR, linespacing = 1, width = 128),
    ]
    if data["fourth"] != "":
        body_children.append(render.Box(width = 128, height = 4, color = SPACER_COLOR))
        body_children.append(render.WrappedText(data["fourth"], font = REFLECTION_FONT, color = REFLECTION_BODY_COLOR, linespacing = 1, width = 128))

    footer_frames = ([footer_line(data["title"])] * FOOTER_HOLD_FRAMES +
                     [footer_line(data["reference"])] * FOOTER_HOLD_FRAMES)

    return render.Root(
        delay = 75,
        show_full_animation = True,
        child = render.Column(
            children = [
                # fixed header: app title + today's date
                render.Padding(
                    pad = (2, 1, 2, 1),
                    child = render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                        children = [
                            render.Text("AA Daily Reflection", font = REFLECTION_FONT, color = APPTITLE_TEXT_COLOR),
                            render.Text(short_date(data["date"]), font = REFLECTION_FONT, color = REFLECTION_SUB_TITLE_COLOR),
                        ],
                    ),
                ),
                render.Box(width = 128, height = 1, color = APPTITLE_BKG_COLOR),
                # scrolling body: summary + expanded text
                render.Marquee(
                    height = body_h,
                    scroll_direction = "vertical",
                    offset_start = body_h,
                    child = render.Column(children = body_children),
                ),
                render.Box(width = 128, height = 1, color = APPTITLE_BKG_COLOR),
                # fixed footer: alternate article title <-> reference
                render.Box(
                    width = 128,
                    height = footer_h,
                    color = "#000",
                    child = render.Animation(children = footer_frames),
                ),
            ],
        ),
    )

def short_date(date):
    # Abbreviate the month so the header fits next to "AA Daily Reflection":
    # the full "September 30" (~58px) would collide with the 85px title on a
    # 128px line, but "Sep 30" (~27px) leaves comfortable room.
    parts = date.split(" ")
    if len(parts) == 2:
        return parts[0][:3] + " " + parts[1]
    return date

def footer_line(text):
    # Word-wraps to a second line when a title/reference is too long for one
    # 128px line (centred, so short lines stay on a single centred line).
    return render.WrappedText(
        content = text,
        font = REFLECTION_FONT,
        color = REFLECTION_SUB_TITLE_COLOR,
        align = "center",
        width = 128,
        linespacing = 0,
    )
