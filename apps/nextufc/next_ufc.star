"""
Applet: Next UFC
Summary: Next UFC event
Description: Shows next upcoming UFC event with date and time.
Author: Stephen So
"""

load("html.star", "html")
load("http.star", "http")
load("images/icon.png", ICON_ASSET = "file")
load("render.star", "render")
load("time.star", "time")

ICON = ICON_ASSET.readall()

now = time.now()
nowyear = now.year
url = "https://www.espn.com/mma/schedule/_/year/" + str(nowyear)

def main():
    rep = http.get(url, ttl_seconds = 3600)

    if rep.status_code != 200:
        fail("get failed with status %d", rep.status_code)

    doc = html(rep.body())

    def check_year():
        title_element = doc.find(".Table__Title")
        if title_element:
            return title_element.text()
        else:
            return None

    if check_year() == "Past Results":
        nowyear_plus_one = nowyear + 1

        url1 = "https://www.espn.com/mma/schedule/_/year/" + str(nowyear_plus_one)
        rep1 = http.get(url1, ttl_seconds = 3600)

        if rep1.status_code != 200:
            fail("get failed with status %d", rep1.status_code)

        doc = html(rep1.body())

    def check_event(i = 1):
        check = doc.find("tbody").children().find("a").eq(i)
        if "UFC" in check.text():
            return check
        else:
            i += 1
            return check_event(i)

    event_node = check_event()
    event = event_node.text()

    date = event_node.parent().siblings().eq(0).text()
    time = event_node.parent().siblings().eq(1).text()

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Padding(
                            render.Image(
                                src = ICON,
                            ),
                            pad = (1, 7, 0, 0),
                        ),
                        render.Padding(
                            render.Column(
                                children = [
                                    render.WrappedText(
                                        content = date,
                                        align = "center",
                                    ),
                                    render.WrappedText(
                                        content = time,
                                        align = "center",
                                    ),
                                ],
                            ),
                            pad = (1, 3, 1, 1),
                        ),
                    ],
                ),
                render.Padding(
                    render.Box(
                        width = 64,
                        height = 9,
                        color = "#a61212",
                        child = render.Marquee(
                            width = 64,
                            offset_start = 64,
                            offset_end = 64,
                            align = "center",
                            child = render.Text(
                                content = event,
                            ),
                        ),
                    ),
                    pad = (0, 0, 0, 0),
                ),
            ],
        ),
    )
