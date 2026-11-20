"""
Applet: Azure Status
Summary: Shows Azure Status messages
Description: Simple app that looks at the Azure Status RSS feed and shows the latest incident and time of the last update. Visit https://status.azure.com/en-us/status/ for more info!
Author: M0ntyP

v1.1
Updated cache function
"""

load("http.star", "http")
load("render.star", "canvas", "render")
load("time.star", "time")
load("xpath.star", "xpath")

RSS_URL = "https://rssfeed.azure.status.microsoft/en-au/status/feed/"
DEFAULT_TIMEZONE = "Australia/Adelaide"
CACHE_TIMEOUT = 1800  # 30 mins

def is_square():
    """True on a 64x64 panel.

    Panels are told apart by SHAPE, never by size: the 128x64 wide panel is
    also 64 tall.
    """
    w, h = canvas.size()
    return h == w

def main():
    timezone = time.tz()
    feed = get_cachable_data(RSS_URL, CACHE_TIMEOUT)
    rss = xpath.loads(feed)
    channel = rss.query_node("//rss/channel")
    title = channel.query("/title")
    lastupdate = channel.query("/lastBuildDate")

    # time formatting
    lastupdate = lastupdate[5:]
    MyTime = time.parse_time(lastupdate, format = "02 Jan 2006 15:04:05 Z").in_location(timezone)
    Time = MyTime.format("15:04")
    Date = MyTime.format("Jan 2")

    item = channel.query("/item/title")
    itemcolor = "#f00"

    if item == None:
        item = "No issues reported"
        itemcolor = "#59d657"

    return render.Root(
        show_full_animation = True,
        # Four bands totalling 33 rows; on a square panel the column expands
        # and spreads them down the panel.
        child = render.Column(
            expanded = is_square(),
            main_align = "space_evenly" if is_square() else "start",
            children = [
                render.Row(
                    children = [
                        render.Box(width = 64, height = 9, color = "#243a5e", child = render.Text(content = title, font = "CG-pixel-4x5-mono")),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(width = 64, height = 10, child = render.Marquee(width = 64, child = render.Text(content = item, color = itemcolor))),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(width = 64, height = 6, color = "#243a5e", child = render.Text(content = "Last update", font = "CG-pixel-3x5-mono")),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(width = 64, height = 8, color = "#243a5e", child = render.Text(content = Date + " " + Time, font = "CG-pixel-3x5-mono")),
                    ],
                ),
            ],
        ),
    )

def get_cachable_data(url, timeout):
    res = http.get(url = url, ttl_seconds = timeout)

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()
