"""
Applet: WSJ News
Summary: Wall Street Journal News
Description: Display Wall Street Journal news headlines.
Author: jvivona
"""

# 20250304 - fix URL for RSS thanks to find from @shimonsavitsky
#          - added more sections

load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

VERSION = 25063

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

DEFAULT_NEWS = "RSSWorldNews"
DEFAULT_ARTICLE_COUNT = "3"
TEXT_COLOR = "#fff"
TITLE_TEXT_COLOR = "#fff"
TITLE_BKG_COLOR = "#cccccc33"
TITLE_FONT = "tom-thumb"
TITLE_HEIGHT = 7
TITLE_WIDTH = 64

ARTICLE_SUB_TITLE_FONT = "tom-thumb"
ARTICLE_SUB_TITLE_COLOR = "#65d0e6"
ARTICLE_FONT = "tb-8"
ARTICLE_COLOR = "#65d0e6"
SPACER_COLOR = "#000"
ARTICLE_LINESPACING = 0
ARTICLE_AREA_HEIGHT = 24

RSS_STUB = "https://feeds.content.dowjones.io/public/rss/{}"

# short section labels for the 2x header (the schema display names are too long
# to fit beside the title at 128px)
SECTION_TITLE = {
    "RSSWorldNews": "World",
    "RSSUSnews": "US News",
    "WSJcomUSBusiness": "US Biz",
    "RSSMarketsMain": "Markets",
    "RSSOpinion": "Opinion",
    "RSSWSJD": "Tech",
    "RSSLifestyle": "Life",
    "RSSStyle": "Style",
    "RSSArtsCulture": "Arts",
    "rsssportsfeed": "Sports",
    "socialhealth": "Health",
    "socialeconomyfeed": "Economy",
    "socialpoliticsfeed": "Politics",
    "RSSPersonalFinance": "Money",
    "latestnewsrealestate": "Realty",
}

def main(config):
    edition = config.get("news_edition", DEFAULT_NEWS)

    articlecount = int(config.get("articlecount", DEFAULT_ARTICLE_COUNT))
    articles = get_cacheable_data(edition, articlecount)

    if canvas.is2x():
        return render_2x(articles, edition)
    return render_1x(articles)

def render_1x(articles):
    # 64x32 layout (unchanged): "Wall Street Jrnl" title bar with headlines-only
    # scrolling beneath it.
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
                    child = render.Text("Wall Street Jrnl", color = TITLE_TEXT_COLOR, font = TITLE_FONT, offset = -1),
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
    # 128x64 layout: fixed "WSJ" + section header, then each article as a
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
                            render.Text("WSJ", color = TITLE_TEXT_COLOR, font = ARTICLE_FONT),
                            render.Box(width = 6, height = 1),
                            render.Text(SECTION_TITLE.get(edition, edition), color = ARTICLE_SUB_TITLE_COLOR, font = ARTICLE_FONT),
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
                default = "RSSWorldNews",
                options = [
                    schema.Option(display = "Arts & Culture", value = "RSSArtsCulture"),
                    schema.Option(display = "Economy", value = "socialeconomyfeed"),
                    schema.Option(display = "Health", value = "socialhealth"),
                    schema.Option(display = "Lifestyle", value = "RSSLifestyle"),
                    schema.Option(display = "Markets", value = "RSSMarketsMain"),
                    schema.Option(display = "Opinion", value = "RSSOpinion"),
                    schema.Option(display = "Personal Finance", value = "RSSPersonalFinance"),
                    schema.Option(display = "Politics", value = "socialpoliticsfeed"),
                    schema.Option(display = "Real Estate", value = "latestnewsrealestate"),
                    schema.Option(display = "Sports", value = "rsssportsfeed"),
                    schema.Option(display = "Style", value = "RSSStyle"),
                    schema.Option(display = "Technology", value = "RSSWSJD"),
                    schema.Option(display = "U.S. Business", value = "WSJcomUSBusiness"),
                    schema.Option(display = "U.S. News", value = "RSSUSnews"),
                    schema.Option(display = "World News", value = "RSSWorldNews"),
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
                    schema.Option(
                        display = "4",
                        value = "4",
                    ),
                    schema.Option(
                        display = "5",
                        value = "5",
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
