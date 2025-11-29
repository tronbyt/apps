"""
Applet: Wiki Page Today
Summary: Wikipedia Featured Article
Description: Display Wikipedia's Featured Article of the Day in a Tidbyt format.
Author: UnBurn
"""

load("http.star", "http")
load("images/wikipedia_icon.png", WIKIPEDIA_ICON_ASSET = "file")
load("images/wikipedia_thumbnail.png", WIKIPEDIA_THUMBNAIL_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

WIKIPEDIA_ICON = WIKIPEDIA_ICON_ASSET.readall()
WIKIPEDIA_THUMBNAIL = WIKIPEDIA_THUMBNAIL_ASSET.readall()

WIKIPEDIA_URL = "https://api.wikimedia.org/feed/v1/wikipedia/%s/featured/%s"

TTL_TIME = 86400
MARQUEE_DELAY = 150

DEFAULT_LANG = "en"
DEFAULT_COLOR = "#FFFFFF"

def get_featured_article_json(lang, date):
    url = WIKIPEDIA_URL % (lang, date)

    article_json = http.get(url, ttl_seconds = TTL_TIME).json()
    return article_json

def extract_article_information(article_json):
    article = article_json["tfa"]
    title = article["normalizedtitle"]
    extract = article["extract"]
    description = get_reduced_extract(extract)
    if "thumbnail" in article and "source" in article["thumbnail"]:
        image = http.get(article["thumbnail"]["source"], ttl_seconds = TTL_TIME).body()
    else:
        image = WIKIPEDIA_THUMBNAIL
    return (title, description, image)

def has_featured_article(article_json):
    return "tfa" in article_json.keys() and "extract" in article_json["tfa"].keys()

def get_reduced_extract(extract):
    MAX_LENGTH = 100

    sentences = extract.split(".")
    ret = sentences[0] + "."
    for s in sentences[1:]:
        new_sentence = ret + s + "."
        if s != "" and len(new_sentence) <= MAX_LENGTH:
            ret = new_sentence
        else:
            break

    return ret

def main(config):
    CURRENT_ARTICLE_UNAVAILABLE = False
    PREVIOUS_ARTICLE_UNAVAILABLE = False

    lang = config.str("lang", DEFAULT_LANG)
    today = time.now().format("2006/01/02")
    article_json = get_featured_article_json(lang, today)
    title = ""
    image = ""
    description = ""

    # Check if the current day's article is present in the JSON
    if has_featured_article(article_json):
        title, description, image = extract_article_information(article_json)
    else:
        # Otherwise, get yesterday's article
        CURRENT_ARTICLE_UNAVAILABLE = True
        yesterday = (time.now() - time.parse_duration("24h")).format("2006/01/02")
        article_json = get_featured_article_json(lang, yesterday)
        if has_featured_article(article_json):
            title, description, image = extract_article_information(article_json)
        else:
            PREVIOUS_ARTICLE_UNAVAILABLE = True

    # If neither the current nor previous article can be found, fail
    if CURRENT_ARTICLE_UNAVAILABLE and PREVIOUS_ARTICLE_UNAVAILABLE:
        fail("Featured article is currently unavailable")

    top_bar = render.Stack(
        children = [
            render.Box(width = 64, height = 6, color = "#3f3f3f"),
            render.Row(
                children = [
                    render.Padding(child = render.Image(src = WIKIPEDIA_ICON, width = 7, height = 6), pad = (1, 0, 1, 0)),
                    render.Marquee(
                        width = 56,
                        delay = MARQUEE_DELAY,
                        child = render.Text(
                            title,
                            font = "tom-thumb",
                        ),
                    ),
                ],
            ),
        ],
    )

    body = render.Row(
        children = [
            render.Padding(child = render.Image(src = image, width = 16, height = 25), pad = (0, 0, 1, 0)),
            render.Marquee(
                height = 25,
                delay = MARQUEE_DELAY,
                scroll_direction = "vertical",
                child = (
                    render.WrappedText(
                        content = description,
                        font = "tb-8",
                        color = config.str("color", DEFAULT_COLOR),
                    )
                ),
            ),
        ],
    )

    return render.Root(
        show_full_animation = True,
        delay = 20,
        child = render.Column(
            children = [top_bar, render.Box(color = "#fff", width = 64, height = 1), body],
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = "Deutsch",
            value = "de",
        ),
        schema.Option(
            display = "English",
            value = "en",
        ),
        schema.Option(
            display = "Magyar",
            value = "hu",
        ),
        schema.Option(
            display = "Latina",
            value = "la",
        ),
        schema.Option(
            display = "Svenska",
            value = "sv",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "lang",
                name = "Language",
                desc = "The language of the article",
                icon = "language",
                default = "en",
                options = options,
            ),
            schema.Color(
                id = "color",
                name = "Color",
                desc = "The color of the font",
                icon = "brush",
                default = DEFAULT_COLOR,
            ),
        ],
    )
