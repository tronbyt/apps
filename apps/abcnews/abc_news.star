"""
Applet: ABC News
Summary: Displays ABC News Headlines
Description: Displays headlines from ABC News Australia. Select the topic from the dropdown and it will display the latest 5 headlines.
Author: M0ntyP

v1.0
First release

v1.1
Added handling for when less than 5 stories in the feed
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

RSS_FEED_PREFIX = "https://www.abc.net.au/news/feed/"
RSS_FEED_SUFFIX = "/rss.xml"

def main(config):
    NewsSelection = config.get("news", "10719986")
    RSS_FEED = RSS_FEED_PREFIX + NewsSelection + RSS_FEED_SUFFIX

    # Update feed every 30 mins
    feed = get_cachable_data(RSS_FEED, 30 * 60)
    rss = xpath.loads(feed)

    topic = rss.query_all("//rss/channel/title")
    title = rss.query_all("//rss/channel/item/title")
    description = []

    # just in case less than 5 stories in the feed
    feed_length = min(len(title), 5)

    for i in range(0, feed_length, 1):
        desc = title[i]
        description.append(desc)

    return render.Root(
        delay = 90,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 7,
                    padding = 1,
                    color = "#1e5aeb",
                    child = render.Text("ABC NEWS", color = "#fff", font = "CG-pixel-4x5-mono", offset = 0),
                ),
                render.Marquee(
                    height = 24,
                    scroll_direction = "vertical",
                    offset_start = 24,
                    child =
                        render.Column(
                            main_align = "space_between",
                            children = articles(topic, description),
                        ),
                ),
            ],
        ),
    )

def articles(topic, description):
    articles = []
    content_color = "#fff"

    articles.append(render.Text(content = topic[0], color = content_color, font = "CG-pixel-3x5-mono", offset = 0))
    articles.append(render.Box(width = 64, height = 1, color = "#000"))
    articles.append(render.Box(width = 64, height = 1, color = "#fff"))
    articles.append(render.Box(width = 64, height = 1, color = "#000"))

    for i in range(0, len(description), 1):
        articles.append(render.WrappedText(content = description[i], color = content_color, font = "CG-pixel-3x5-mono", linespacing = 1))
        articles.append(render.Box(width = 64, height = 3, color = "#000"))

    return articles

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "news",
                name = "News Feed",
                desc = "Select your news feed",
                icon = "gear",
                default = NewsOptions[0].value,
                options = NewsOptions,
            ),
        ],
    )

NewsOptions = [
    schema.Option(
        display = "Top Stories",
        value = "10719986",
    ),
    schema.Option(
        display = "World News",
        value = "104217382",
    ),
    schema.Option(
        display = "Sport",
        value = "103728570",
    ),
    schema.Option(
        display = "Politics",
        value = "104217372",
    ),
    schema.Option(
        display = "Business",
        value = "104217374",
    ),
    schema.Option(
        display = "ACT News",
        value = "5512668",
    ),
    schema.Option(
        display = "NSW News",
        value = "5555986",
    ),
    schema.Option(
        display = "NT News",
        value = "5555990",
    ),
    schema.Option(
        display = "QLD News",
        value = "5555988",
    ),
    schema.Option(
        display = "SA News",
        value = "5633084",
    ),
    schema.Option(
        display = "Tas News",
        value = "5512674",
    ),
    schema.Option(
        display = "Vic News",
        value = "5470430",
    ),
    schema.Option(
        display = "WA News",
        value = "5313390",
    ),
]

def get_cachable_data(url, timeout):
    res = http.get(url = url, ttl_seconds = timeout)

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()
