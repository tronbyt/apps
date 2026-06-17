"""
Applet: Fox News
Summary: Fox News display
Description: Display Fox News headlines.
Author: jvivona
"""

load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

VERSION = 23132

# cache data for 15 minutes
CACHE_TTL_SECONDS = 900

DEFAULT_NEWS = "latest"
DEFAULT_ARTICLE_COUNT = "3"
TEXT_COLOR = "#fff"
TITLE_TEXT_COLOR = "#fff"
TITLE_BKG_COLOR = "#003366aa"
TITLE_FONT = "tom-thumb"
TITLE_HEIGHT = 8
TITLE_WIDTH = 64

ARTICLE_SUB_TITLE_FONT = "tom-thumb"
ARTICLE_SUB_TITLE_COLOR = "#ccd0e6"
ARTICLE_FONT = "tb-8"
ARTICLE_COLOR = "#65d0e6"
SPACER_COLOR = "#000"
ARTICLE_LINESPACING = 0
ARTICLE_AREA_HEIGHT = 24

RSS_STUB = "https://moxie.foxnews.com/google-publisher/{}.xml"

def main(config):
    edition = config.get("news_edition", DEFAULT_NEWS)

    articlecount = int(config.get("articlecount", DEFAULT_ARTICLE_COUNT))
    articles = get_cacheable_data(edition.lower(), articlecount)

    if canvas.is2x():
        return render_2x(articles, edition)
    return render_1x(articles)

def render_1x(articles):
    # 64x32 layout (unchanged): "FOX News" title bar with headlines-only
    # scrolling beneath it.
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
                    child = render.Text("FOX News", color = TITLE_TEXT_COLOR, font = TITLE_FONT, offset = 0),
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

def render_article(news):
    #formats color and font of text
    news_text = []
    for article in news:
        news_text.append(render.WrappedText(content = article[0], color = ARTICLE_SUB_TITLE_COLOR, font = ARTICLE_SUB_TITLE_FONT))

        #news_text.append(render.WrappedText(content = article[1], font = ARTICLE_SUB_TITLE_FONT, color = ARTICLE_COLOR, linespacing = ARTICLE_LINESPACING))
        news_text.append(render.Box(width = 64, height = 8, color = SPACER_COLOR))

    return (news_text)

def render_2x(articles, edition):
    # 128x64 layout: a fixed Fox-blue "FOX News" + section header, then each
    # article scrolling as a white headline followed by its description (the
    # description that 1x has no room for).
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
                # fixed header: FOX News + selected section
                render.Box(
                    width = 128,
                    height = 9,
                    color = TITLE_BKG_COLOR,
                    child = render.Row(
                        cross_align = "center",
                        children = [
                            render.Text("FOX News", color = TITLE_TEXT_COLOR, font = ARTICLE_FONT),
                            render.Box(width = 6, height = 1),
                            render.Text(edition.upper(), color = ARTICLE_SUB_TITLE_COLOR, font = ARTICLE_FONT),
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
                default = "latest",
                options = [
                    schema.Option(
                        display = "Latest Headlines",
                        value = "latest",
                    ),
                    schema.Option(
                        display = "Health",
                        value = "health",
                    ),
                    schema.Option(
                        display = "Opinion",
                        value = "opinion",
                    ),
                    schema.Option(
                        display = "Politics",
                        value = "politics",
                    ),
                    schema.Option(
                        display = "Science",
                        value = "science",
                    ),
                    schema.Option(
                        display = "Sports",
                        value = "sports",
                    ),
                    schema.Option(
                        display = "Technology",
                        value = "tech",
                    ),
                    schema.Option(
                        display = "Travel",
                        value = "travel",
                    ),
                    schema.Option(
                        display = "US",
                        value = "us",
                    ),
                    schema.Option(
                        display = "World",
                        value = "world",
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
