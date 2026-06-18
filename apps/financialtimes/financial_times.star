"""
Applet: Financial Times News
Author: jvivona
Summary: Financial Times News Headlines
Description: Gets latest new articles from Financial Time and displays up to 3 articles
    for selected edition.
"""

load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

VERSION = 23132

# cache data for 15 minutes
CACHE_TTL_SECONDS = 900

DEFAULT_NEWS = "home"
DEFAULT_ARTICLE_COUNT = "3"
TEXT_COLOR = "#fff"
TITLE_TEXT_COLOR = "#fff1e5"
TITLE_BKG_COLOR = "#fff1e533"
TITLE_FONT = "tom-thumb"
TITLE_HEIGHT = 7
TITLE_WIDTH = 64

ARTICLE_SUB_TITLE_FONT = "tom-thumb"
ARTICLE_SUB_TITLE_COLOR = "#ff8c00"
ARTICLE_FONT = "tb-8"
ARTICLE_COLOR = "#00eeff"
SPACER_COLOR = "#000"
ARTICLE_LINESPACING = 0
ARTICLE_AREA_HEIGHT = 24

RSS_STUB = "https://www.ft.com/{}?format=rss"

# short section labels for the 2x header
SECTION_TITLE = {
    "home": "Home",
    "world": "World",
    "us": "US",
    "companies": "Companies",
    "technology": "Tech",
    "markets": "Markets",
    "opinion": "Opinion",
}

def main(config):
    edition = config.get("news_edition", DEFAULT_NEWS)

    articlecount = int(config.get("articlecount", DEFAULT_ARTICLE_COUNT))
    articles = get_cacheable_data(edition.lower(), articlecount)

    if canvas.is2x():
        return render_2x(articles, edition)
    return render_1x(articles)

def render_1x(articles):
    # 64x32 layout (unchanged): "Financial Times" title bar over the scrolling
    # headline + description body.
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
                    child = render.Text("Financial Times", color = TITLE_TEXT_COLOR, font = TITLE_FONT, offset = -1),
                ),
                render.Marquee(
                    height = ARTICLE_AREA_HEIGHT,
                    scroll_direction = "vertical",
                    offset_start = 24,
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
    # 128x64 layout: fixed "FT" + section header, then each article as a
    # white headline followed by its description in the roomier canvas.
    body = []
    for article in articles:
        body.append(render.WrappedText(content = clean_text(article[0]), color = TEXT_COLOR, font = ARTICLE_FONT, width = 128, linespacing = ARTICLE_LINESPACING))
        body.append(render.Box(width = 128, height = 2, color = SPACER_COLOR))
        desc = clean_text(article[1])
        if desc != "":
            body.append(render.WrappedText(content = desc, color = ARTICLE_COLOR, font = ARTICLE_SUB_TITLE_FONT, width = 128, linespacing = ARTICLE_LINESPACING))
        body.append(render.Box(width = 128, height = 9, color = SPACER_COLOR))

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
                            render.Text("FT", color = TITLE_TEXT_COLOR, font = ARTICLE_FONT),
                            render.Box(width = 6, height = 1),
                            render.Text(SECTION_TITLE.get(edition, edition), color = ARTICLE_SUB_TITLE_COLOR, font = ARTICLE_FONT),
                        ],
                    ),
                ),
                render.Marquee(
                    height = 55,
                    scroll_direction = "vertical",
                    offset_start = 55,
                    child = render.Column(children = body),
                ),
            ],
        ),
    )

def render_article(news):
    #formats color and font of text
    news_text = []

    for article in news:
        news_text.append(render.WrappedText("%s:" % article[0], color = ARTICLE_SUB_TITLE_COLOR, font = ARTICLE_SUB_TITLE_FONT))
        news_text.append(render.WrappedText("%s" % article[1], font = ARTICLE_SUB_TITLE_FONT, color = ARTICLE_COLOR, linespacing = ARTICLE_LINESPACING))
        news_text.append(render.Box(width = 64, height = 3, color = SPACER_COLOR))

    return (news_text)

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
                name = "News Page",
                desc = "Select which page to display",
                icon = "newspaper",
                default = "home",
                options = [
                    schema.Option(
                        display = "Home Page",
                        value = "home",
                    ),
                    schema.Option(
                        display = "World",
                        value = "world",
                    ),
                    schema.Option(
                        display = "United States",
                        value = "us",
                    ),
                    schema.Option(
                        display = "Companies",
                        value = "companies",
                    ),
                    schema.Option(
                        display = "Technology",
                        value = "technology",
                    ),
                    schema.Option(
                        display = "Markets",
                        value = "markets",
                    ),
                    schema.Option(
                        display = "Opinion",
                        value = "opinion",
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
