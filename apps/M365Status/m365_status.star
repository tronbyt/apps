"""
Applet: M365 Status
Summary: Shows current status of M365
Description: Simple app that looks at the Microsoft Admin Center Status RSS feed and shows the latest status and time of the last update. Visit https://status.cloud.microsoft for more info!
Author: Author: M0ntyP

v1.0
First edition!
"""

load("http.star", "http")
load("render.star", "render")
load("time.star", "time")
load("xpath.star", "xpath")

RSS_URL = "https://status.cloud.microsoft/api/feed/mac"
DEFAULT_TIMEZONE = time.tz()
CACHE_TIMEOUT = 15 * 60  # 15 mins

def main():
    timezone = time.tz()
    feed = get_cachable_data(RSS_URL, CACHE_TIMEOUT)
    rss = xpath.loads(feed)
    channel = rss.query_node("//rss/channel")
    title = "M365 Status"
    lastupdate = channel.query("/lastBuildDate")
    itemcolor = "#59d657"

    # time formatting
    lastupdate = lastupdate[5:]
    MyTime = time.parse_time(lastupdate, format = "02 Jan 2006 15:04:05 Z").in_location(timezone)
    Time = MyTime.format("15:04")
    Date = MyTime.format("Jan 2")

    item = channel.query("/item/status")

    if item == "ServiceInterruption":
        itemcolor = "#f00"
        item = "Service Interruption"

    if item == "Advisory":
        itemcolor = "#f3c650"
        item = "Advisory           "

    if item == "Investigation":
        itemcolor = "#fff"
        item = "Investigation      "

    if item == "ServiceDegradation":
        itemcolor = "#fd874a"
        item = "Service Degradation"

    if item == "Available":
        item = "No issues reported"

    return render.Root(
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Box(width = 64, height = 9, color = "#4a3665", child = render.Text(content = title, font = "CG-pixel-4x5-mono")),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(width = 64, height = 10, child = render.Marquee(width = 64, child = render.Text(content = item, color = itemcolor))),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(width = 64, height = 6, color = "#4a3665", child = render.Text(content = "Last update", font = "CG-pixel-3x5-mono")),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(width = 64, height = 8, color = "#4a3665", child = render.Text(content = Date + " " + Time, font = "CG-pixel-3x5-mono")),
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
