"""
Applet: Sky News
Summary: Latest news
Description: The current top story (and a short blurb) from SkyNews.com.
Author: meejle
"""

load("animation.star", "animation")
load("http.star", "http")
load("images/blue_background.png", BLUE_BACKGROUND_ASSET = "file")
load("images/glass_highlight.png", GLASS_HIGHLIGHT_ASSET = "file")
load("images/gradient_line.png", GRADIENT_LINE_ASSET = "file")
load("images/splash_screen.gif", SPLASH_SCREEN_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

BLUE_BACKGROUND = BLUE_BACKGROUND_ASSET.readall()
GLASS_HIGHLIGHT = GLASS_HIGHLIGHT_ASSET.readall()
GRADIENT_LINE = GRADIENT_LINE_ASSET.readall()
SPLASH_SCREEN = SPLASH_SCREEN_ASSET.readall()

# Animated splash screen

# Blue gradient background

# Transparent "glass" highlight

# Dividing line

def main(config):
    feedchoice = config.get("feedchoice", "home")
    fontsize = config.get("fontsize", "tb-8")
    articles = get_cacheable_data(feedchoice, 1, config)

    if fontsize == "tb-8":
        return render.Root(
            show_full_animation = True,
            child = render.Stack(
                children = [
                    render.Image(width = 64, height = 32, src = BLUE_BACKGROUND),
                    animation.Transformation(
                        render.Image(width = 64, height = 32, src = SPLASH_SCREEN),
                        duration = 0,
                        delay = 66,
                        origin = animation.Origin(1, 1),
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(0, 0)],
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(0, -32)],
                            ),
                        ],
                    ),
                    render.Marquee(
                        height = 32,
                        scroll_direction = "vertical",
                        offset_start = 91,
                        offset_end = 32,
                        child =
                            render.Column(
                                main_align = "space_between",
                                children = render_shadow_larger(articles),
                            ),
                    ),
                    render.Marquee(
                        height = 32,
                        scroll_direction = "vertical",
                        offset_start = 90,
                        offset_end = 32,
                        child =
                            render.Column(
                                main_align = "space_between",
                                children = render_article_larger(articles),
                            ),
                    ),
                    animation.Transformation(
                        render.Image(width = 64, height = 19, src = GLASS_HIGHLIGHT),
                        duration = 125,
                        delay = 66,
                        origin = animation.Origin(1, 1),
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(0, -19)],
                                curve = "ease_out",
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(0, 0)],
                                curve = "ease_out",
                            ),
                        ],
                    ),
                ],
            ),
        )

    else:
        return render.Root(
            show_full_animation = True,
            child = render.Stack(
                children = [
                    render.Image(width = 64, height = 32, src = BLUE_BACKGROUND),
                    animation.Transformation(
                        render.Image(width = 64, height = 32, src = SPLASH_SCREEN),
                        duration = 0,
                        delay = 66,
                        origin = animation.Origin(1, 1),
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(0, 0)],
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(0, -32)],
                            ),
                        ],
                    ),
                    render.Marquee(
                        height = 32,
                        scroll_direction = "vertical",
                        offset_start = 91,
                        offset_end = 32,
                        child =
                            render.Column(
                                main_align = "space_between",
                                children = render_shadow_smaller(articles),
                            ),
                    ),
                    render.Marquee(
                        height = 32,
                        scroll_direction = "vertical",
                        offset_start = 90,
                        offset_end = 32,
                        child =
                            render.Column(
                                main_align = "space_between",
                                children = render_article_smaller(articles),
                            ),
                    ),
                    animation.Transformation(
                        render.Image(width = 64, height = 19, src = GLASS_HIGHLIGHT),
                        duration = 125,
                        delay = 66,
                        origin = animation.Origin(1, 1),
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(0, -19)],
                                curve = "ease_out",
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(0, 0)],
                                curve = "ease_out",
                            ),
                        ],
                    ),
                ],
            ),
        )

def render_article_larger(news):
    #formats color and font of text
    news_text = []

    for article in news:
        news_text.append(render.WrappedText("%s" % article[0], color = "#FFFFFF", font = "tb-8", linespacing = 1, width = 64, align = "center"))
        news_text.append(render.Box(width = 64, height = 2))
        news_text.append(render.Image(width = 64, height = 2, src = GRADIENT_LINE))
        news_text.append(render.Box(width = 64, height = 2))
        news_text.append(render.WrappedText("%s" % article[1], color = "#FFFFFF", font = "tb-8", linespacing = 1, width = 64, align = "center"))
        news_text.append(render.Box(width = 64, height = 2))
        news_text.append(render.WrappedText("More at SkyNews.com", color = "#FFFFFF", font = "tb-8", linespacing = 1, width = 64, align = "center"))

    return (news_text)

def render_shadow_larger(news):
    #formats color and font of text
    news_text = []

    for article in news:
        news_text.append(render.WrappedText("%s" % article[0], color = "#000000", font = "tb-8", linespacing = 1, width = 64, align = "center"))
        news_text.append(render.Box(width = 64, height = 6))
        news_text.append(render.WrappedText("%s" % article[1], color = "#000000", font = "tb-8", linespacing = 1, width = 64, align = "center"))
        news_text.append(render.Box(width = 64, height = 2))
        news_text.append(render.WrappedText("More at SkyNews.com", color = "#000000", font = "tb-8", linespacing = 1, width = 64, align = "center"))

    return (news_text)

def render_article_smaller(news):
    #formats color and font of text
    news_text = []

    for article in news:
        news_text.append(render.WrappedText("%s" % article[0], color = "#FFFFFF", font = "tom-thumb", linespacing = 1, width = 64, align = "center"))
        news_text.append(render.Box(width = 64, height = 2))
        news_text.append(render.Image(width = 64, height = 2, src = GRADIENT_LINE))
        news_text.append(render.Box(width = 64, height = 2))
        news_text.append(render.WrappedText("%s" % article[1], color = "#FFFFFF", font = "tom-thumb", linespacing = 1, width = 64, align = "center"))
        news_text.append(render.Box(width = 64, height = 2))
        news_text.append(render.WrappedText("More at SkyNews.com", color = "#FFFFFF", font = "tom-thumb", linespacing = 1, width = 64, align = "center"))

    return (news_text)

def render_shadow_smaller(news):
    #formats color and font of text
    news_text = []

    for article in news:
        news_text.append(render.WrappedText("%s" % article[0], color = "#000000", font = "tom-thumb", linespacing = 1, width = 64, align = "center"))
        news_text.append(render.Box(width = 64, height = 6))
        news_text.append(render.WrappedText("%s" % article[1], color = "#000000", font = "tom-thumb", linespacing = 1, width = 64, align = "center"))
        news_text.append(render.Box(width = 64, height = 2))
        news_text.append(render.WrappedText("More at SkyNews.com", color = "#000000", font = "tom-thumb", linespacing = 1, width = 64, align = "center"))

    return (news_text)

def connectionError(config):
    fontsize = config.get("fontsize", "tb-8")
    return render.Root(
        show_full_animation = True,
        child = render.Stack(
            children = [
                render.Image(width = 64, height = 32, src = BLUE_BACKGROUND),
                animation.Transformation(
                    render.Image(width = 64, height = 32, src = SPLASH_SCREEN),
                    duration = 0,
                    delay = 66,
                    origin = animation.Origin(1, 1),
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, -32)],
                        ),
                    ],
                ),
                render.Marquee(
                    height = 32,
                    scroll_direction = "vertical",
                    offset_start = 91,
                    offset_end = 32,
                    child =
                        render.Column(
                            main_align = "space_between",
                            children = [
                                render.WrappedText("Error: Couldn't load the top stories", color = "#FFFFFF", font = fontsize, linespacing = 1, width = 64, align = "center"),
                                render.Box(width = 64, height = 6),
                                render.WrappedText("For the latest headlines, visit SkyNews.com", color = "#FFFFFF", font = fontsize, linespacing = 1, width = 64, align = "center"),
                            ],
                        ),
                ),
                render.Marquee(
                    height = 32,
                    scroll_direction = "vertical",
                    offset_start = 90,
                    offset_end = 32,
                    child =
                        render.Column(
                            main_align = "space_between",
                            children = [
                                render.WrappedText("Error: Couldn't load the top stories", color = "#000000", font = fontsize, linespacing = 1, width = 64, align = "center"),
                                render.Box(width = 64, height = 6),
                                render.WrappedText("For the latest headlines, visit SkyNews.com", color = "#000000", font = fontsize, linespacing = 1, width = 64, align = "center"),
                            ],
                        ),
                ),
                animation.Transformation(
                    render.Image(width = 64, height = 19, src = GLASS_HIGHLIGHT),
                    duration = 125,
                    delay = 66,
                    origin = animation.Origin(1, 1),
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, -19)],
                            curve = "ease_out",
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                            curve = "ease_out",
                        ),
                    ],
                ),
            ],
        ),
    )

def get_cacheable_data(url, articlecount, config):
    articles = []

    res = http.get("https://feeds.skynews.com/feeds/rss/" + url + ".xml".format(url), ttl_seconds = 900)
    if res.status_code != 200:
        return connectionError(config)
    data = res.body()

    data_xml = xpath.loads(data)

    for i in range(1, articlecount + 1):
        title_query = "//item[{}]/title".format(str(i))
        desc_query = "//item[{}]/description".format(str(i))
        articles.append((data_xml.query(title_query), str(data_xml.query(desc_query)).replace("None", "")))

    return articles

def get_schema():
    fsfeedchoice = [
        schema.Option(
            display = "Top stories",
            value = "home",
        ),
        schema.Option(
            display = "UK",
            value = "uk",
        ),
        schema.Option(
            display = "World",
            value = "world",
        ),
        schema.Option(
            display = "US",
            value = "us",
        ),
        schema.Option(
            display = "Business",
            value = "business",
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
            display = "Entertainment",
            value = "entertainment",
        ),
        schema.Option(
            display = "Strange news",
            value = "strange",
        ),
    ]
    fsoptions = [
        schema.Option(
            display = "Larger",
            value = "tb-8",
        ),
        schema.Option(
            display = "Smaller",
            value = "tom-thumb",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "feedchoice",
                name = "Choose your favourite feed",
                desc = "Get news that’s tailored to you.",
                icon = "newspaper",
                default = fsfeedchoice[0].value,
                options = fsfeedchoice,
            ),
            schema.Dropdown(
                id = "fontsize",
                name = "Change the text size",
                desc = "Prevent long words being cut off.",
                icon = "textHeight",
                default = fsoptions[0].value,
                options = fsoptions,
            ),
        ],
    )
