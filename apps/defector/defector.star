"""
Applet: Defector
Summary: Display a Defector headline
Description: Displays a recent headline from Defector.com.
Author: Rory Sawyer
"""

load("http.star", "http")
load("images/defector_logo.png", DEFECTOR_LOGO_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("xpath.star", "xpath")

DEFECTOR_RSS_URL = "https://defector.com/feed"

DEFECTOR_LOGO = DEFECTOR_LOGO_ASSET.readall()

def get_item_from_rss(rss_xml):
    root = xpath.loads(rss_xml)
    titles = root.query_all("/rss/channel/item/title")
    idx = random.number(0, len(titles) - 1)
    return titles[idx]

def main():
    # refresh the rss feed every 15 minutes
    resp = http.get(DEFECTOR_RSS_URL, ttl_seconds = 900)
    if resp.status_code != 200:
        fail("unable to get defector rss feed")

    body = resp.body()
    title = get_item_from_rss(body)

    logo = render.Image(src = DEFECTOR_LOGO, height = 16)
    header_text = render.Padding(child = render.WrappedText("Defector Media"), pad = (4, 0, 0, 0))
    row = render.Row(
        children = [logo, header_text],
        cross_align = "center,",
    )

    marq = render.Padding(
        child = render.Marquee(width = 64, child = render.Text(title)),
        pad = (0, 2, 0, 0),
    )

    column = render.Column(children = [row, marq], main_align = "space_evenly")

    return render.Root(child = column)
