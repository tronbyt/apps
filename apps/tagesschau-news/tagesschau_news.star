load("http.star", "http")
load("images/ard_logo_white.svg", ARD_LOGO_WHITE = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")

def is_breaking(newsEntry):
    if "breakingNews" in newsEntry and newsEntry["breakingNews"]:
        return True

    # if "tags" in newsEntry and any([("tag" in tag and tag["tag"] == "Eilmeldung") for tag in newsEntry["tags"]]):
    #     return True
    return False

def format_time(original_time):
    if "T" in original_time:
        time_part = original_time.split("T")[1].split(":")
        formatted_time = time_part[0] + ":" + time_part[1]
        return formatted_time
    return "n/a"

def get_most_important_headline():
    response = http.get(
        "https://www.tagesschau.de/api2u/homepage/",
        headers = {"accept": "application/json"},
        ttl_seconds = 300,
    )

    data = response.json()
    if "news" in data:
        for entry in data["news"]:
            if is_breaking(entry):
                return entry
        return data["news"][0]
    return None

def main(config):
    scale = 2 if canvas.is2x() else 1

    # Layout constants
    HEADING_HEIGHT = 12 * scale
    TEXT_TOP_OFFSET = HEADING_HEIGHT + 3 * scale  # Offset where scrollable text starts
    TEXT_HEIGHT = canvas.height() - TEXT_TOP_OFFSET - scale  # Available height for scrollable text
    TEXT_DRAW_WIDTH = canvas.width() - (2 * scale)  # Width available for wrapped text

    # Fonts
    font_small = "CG-pixel-3x5-mono" if scale == 1 else "terminus-12"
    font_normal = "5x8" if scale == 1 else "terminus-16"

    headline = get_most_important_headline()
    if not headline:
        return render.Root(render.Text(
            "Cannot refresh news",
            font = font_small,
        ))
    title = headline["title"]
    topline = headline["topline"]
    date = headline["date"]
    formatted_date = format_time(date) if date else "No time available"
    news_is_urgent = is_breaking(headline)

    if config and not news_is_urgent and config.bool("hide_if_not_urgent", False):
        return []

    text_color = "#FFFF00" if news_is_urgent else "#FFFFFF"
    text_content = render.Column(children = [
        render.WrappedText(
            content = ("+++ " if news_is_urgent else "") + topline + ":",
            color = text_color,
            font = font_normal,
            width = TEXT_DRAW_WIDTH,
            wordbreak = True,
        ),
        render.Padding(
            render.WrappedText(
                content = title + (" +++" if news_is_urgent else ""),
                color = text_color,
                font = font_normal,
                width = TEXT_DRAW_WIDTH,
                wordbreak = True,
            ),
            pad = (0, 2 * scale, 0, 0),
        ),
    ])

    return render.Root(
        render.Stack([
            # 1. Background
            render.Box(
                color = "#1e283f",
                width = canvas.width(),
                height = canvas.height(),
            ),

            # 2. Scrolling Text Layer
            render.Padding(
                pad = (scale, TEXT_TOP_OFFSET, scale, scale),
                child = render.Box(
                    width = TEXT_DRAW_WIDTH,
                    height = TEXT_HEIGHT,
                    child = render.Marquee(
                        height = TEXT_HEIGHT,
                        scroll_direction = "vertical",
                        offset_start = 0,
                        offset_end = 16 * scale,
                        delay = 40,
                        child = text_content,
                    ),
                ),
            ),

            # 3. Header Layer
            render.Padding(
                pad = scale,
                child = render.Box(
                    color = "#1e283f",
                    width = TEXT_DRAW_WIDTH,
                    height = HEADING_HEIGHT + 2 * scale,
                    child = render.Padding(
                        pad = scale,
                        child = render.Row(
                            expanded = True,
                            main_align = "space_between",
                            children = [
                                render.Image(height = HEADING_HEIGHT, src = ARD_LOGO_WHITE.readall()),
                                render.Text(
                                    formatted_date,
                                    font = font_small,
                                ),
                            ],
                            cross_align = "center",
                        ),
                    ),
                ),
            ),
        ]),
        delay = 100 // scale,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "hide_if_not_urgent",
                name = "Don't show if not urgent",
                desc = "Don't show the news if it's not an urgent headline",
                default = False,
                icon = "eyeSlash",
            ),
        ],
    )
