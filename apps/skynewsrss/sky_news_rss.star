"""
Applet: Sky News RSS
Summary: Display Sky News RSS
Description: Sky New RSS.
Author: jvivona
"""

load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

VERSION = 23222

# Devices reject a webp over 460,000 bytes (firmware HTTP_BUFFER_SIZE_MAX) and
# show an "oversize" screen instead. File size grows with scroll length, so cap
# the marquee at a frame budget: ~690 bytes/frame worst case at 2x and ~430 on
# 64x64 keeps the render under ~400 KB.
MAX_SCROLL_FRAMES = 500 if canvas.is2x() else 900

# pixlet's marquee silently clips content taller than 20x its height, so treat
# that as not fitting either and drop whole items instead of cutting mid-list.
MARQUEE_MAX_SCALE = 20

# cache data for 15 minutes
CACHE_TTL_SECONDS = 900

DEFAULT_NEWS = "world"
DEFAULT_ARTICLE_COUNT = "3"
TEXT_COLOR = "#fff"
TITLE_TEXT_COLOR = "#fff"
TITLE_BKG_COLOR = "#ff0000aa"
TITLE_FONT = "tom-thumb"
TITLE_HEIGHT = 8
TITLE_WIDTH = 64

ARTICLE_SUB_TITLE_FONT = "tom-thumb"
ARTICLE_SUB_TITLE_COLOR = "#65d0e6"
ARTICLE_FONT = "tb-8"
ARTICLE_COLOR = "#65d0e6"
SPACER_COLOR = "#000"
ARTICLE_LINESPACING = 0
ARTICLE_AREA_HEIGHT = 24

RSS_STUB = "http://feeds.skynews.com/feeds/rss/{}.xml"

SECTION_TITLE = {
    "home": "Home",
    "uk": "UK",
    "world": "World",
    "us": "US",
    "business": "Biz",
    "politics": "Pol",
    "technology": "Tech",
    "entertainment": "Ent",
    "strange": "Odd",
}

def main(config):
    edition = config.get("news_edition", DEFAULT_NEWS)

    articlecount = int(config.get("articlecount", DEFAULT_ARTICLE_COUNT))
    articles = get_cacheable_data(edition.lower(), articlecount)

    if canvas.is2x():
        return render_2x(articles, edition)
    return render_1x(articles, edition)

def render_1x(articles, edition):
    # 64x32 layout (unchanged): "Sky News (section)" title bar with
    # headlines-only scrolling beneath it.
    articles = fit_articles(articles, render_article, canvas.height() - TITLE_HEIGHT)

    return render.Root(
        delay = 100,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Box(
                    width = TITLE_WIDTH,
                    height = TITLE_HEIGHT,
                    padding = 0,
                    color = TITLE_BKG_COLOR,
                    child = render.Text("Sky News (" + SECTION_TITLE[edition] + ")", color = TITLE_TEXT_COLOR, font = TITLE_FONT, offset = 0),
                ),
                render.Marquee(
                    # the rows under the title: 24 on 64x32, 56 on square
                    height = canvas.height() - TITLE_HEIGHT,
                    scroll_direction = "vertical",
                    offset_start = canvas.height() - TITLE_HEIGHT,
                    child =
                        render.Column(
                            main_align = "space_between",
                            children = render_article(articles),
                        ),
                ),
            ],
        ),
    )

def render_2x(articles, edition):
    # 128x64 layout: fixed "Sky News" + section header, then each article as a
    # white headline followed by its description in the roomier canvas.
    articles = fit_articles(articles, rows_2x, 55)

    return render.Root(
        delay = 100,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Box(
                    width = 128,
                    height = 9,
                    color = TITLE_BKG_COLOR,
                    child = render.Row(
                        cross_align = "center",
                        children = [
                            render.Text("Sky News", color = TITLE_TEXT_COLOR, font = ARTICLE_FONT),
                            render.Box(width = 6, height = 1),
                            render.Text(SECTION_TITLE[edition], color = ARTICLE_SUB_TITLE_COLOR, font = ARTICLE_FONT),
                        ],
                    ),
                ),
                render.Marquee(
                    height = 55,
                    scroll_direction = "vertical",
                    offset_start = 55,
                    child = render.Column(children = rows_2x(articles)),
                ),
            ],
        ),
    )

def render_article(news):
    #formats color and font of text
    news_text = []

    for article in news:
        news_text.append(render.WrappedText(article[0], color = ARTICLE_SUB_TITLE_COLOR, font = ARTICLE_SUB_TITLE_FONT))

        #news_text.append(render.WrappedText(article[1], font = ARTICLE_SUB_TITLE_FONT, color = ARTICLE_COLOR, linespacing = ARTICLE_LINESPACING))
        news_text.append(render.Box(width = 64, height = 8, color = SPACER_COLOR))

    return (news_text)

def rows_2x(articles):
    body = []
    for article in articles:
        body.append(render.WrappedText(content = clean_text(article[0]), color = TEXT_COLOR, font = ARTICLE_FONT, width = 128, linespacing = ARTICLE_LINESPACING))
        body.append(render.Box(width = 128, height = 2, color = SPACER_COLOR))
        desc = clean_text(article[1])
        if desc != "":
            body.append(render.WrappedText(content = desc, color = ARTICLE_COLOR, font = ARTICLE_SUB_TITLE_FONT, width = 128, linespacing = ARTICLE_LINESPACING))
        body.append(render.Box(width = 128, height = 9, color = SPACER_COLOR))
    return body

def fit_articles(articles, rows_for, height):
    # Drop trailing articles until the scroll fits MAX_SCROLL_FRAMES (always
    # keeping the first), so the render stays under the device's webp size cap.
    budget = min(MAX_SCROLL_FRAMES, MARQUEE_MAX_SCALE * height)
    for _ in range(len(articles) - 1):
        marquee = render.Marquee(
            height = height,
            scroll_direction = "vertical",
            offset_start = height,
            child = render.Column(children = rows_for(articles)),
        )

        # frame_count() lays out on a 64x32 canvas unless given real bounds
        if marquee.frame_count((0, 0, canvas.width(), canvas.height())) <= budget:
            break
        articles = articles[:-1]
    return articles

def clean_text(s):
    if not s:
        return ""

    # RSS text comes through with HTML entities (e.g. &apos; &quot;); unescape
    # the common ones. &amp; is handled first so double-escaped entities resolve.
    for entity, char in [("&amp;", "&"), ("&apos;", "'"), ("&#39;", "'"), ("&quot;", "\""), ("&#34;", "\""), ("&lt;", "<"), ("&gt;", ">"), ("&nbsp;", " ")]:
        s = s.replace(entity, char)
    return s.strip()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "news_edition",
                name = "News Section",
                desc = "Select which section to display",
                icon = "newspaper",
                default = "world",
                options = [
                    schema.Option(
                        display = "Home Page",
                        value = "home",
                    ),
                    schema.Option(
                        display = "UK News",
                        value = "uk",
                    ),
                    schema.Option(
                        display = "World News",
                        value = "world",
                    ),
                    schema.Option(
                        display = "US News",
                        value = "us",
                    ),
                    schema.Option(
                        display = "Politics",
                        value = "politics",
                    ),
                    schema.Option(
                        display = "Technology",
                        value = "technology",
                    ),
                    schema.Option(
                        display = "Business",
                        value = "business",
                    ),
                    schema.Option(
                        display = "Entertainment",
                        value = "entertainment",
                    ),
                    schema.Option(
                        display = "Strange News",
                        value = "strange",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "articlecount",
                name = "Article Count",
                desc = "Select number of articles to display",
                icon = "hashtag",
                default = "3",
                options = [
                    schema.Option(
                        display = "1",
                        value = "1",
                    ),
                    schema.Option(
                        display = "2",
                        value = "2",
                    ),
                    schema.Option(
                        display = "3",
                        value = "3",
                    ),
                ],
            ),
        ],
    )

def get_cacheable_data(url, articlecount):
    articles = []

    res = http.get(RSS_STUB.format(url), ttl_seconds = CACHE_TTL_SECONDS)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))
    data = res.body()

    data_xml = xpath.loads(data)

    for i in range(1, articlecount + 1):
        title_query = "//item[{}]/title".format(str(i))
        desc_query = "//item[{}]/description".format(str(i))
        articles.append((data_xml.query(title_query), str(data_xml.query(desc_query)).replace("None", "")))

    return articles
