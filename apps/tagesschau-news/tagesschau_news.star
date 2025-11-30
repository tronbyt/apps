load("http.star", "http")
load("images/ard_logo_white.png", ARD_LOGO_WHITE = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")

def is_breaking(newsEntry):
    if "breakingNews" in newsEntry and newsEntry["breakingNews"]:
        return True

    # if "tags" in newsEntry and any([("tag" in tag and tag["tag"] == "Eilmeldung") for tag in newsEntry["tags"]]):
    #     return True
    return False

def format_text(original_text, chars_per_line):
    lines = []
    for line in original_text.split("\n"):
        new_line_words = []
        for word in line.split(" "):
            if len(word) <= chars_per_line:
                new_line_words.append(word)
            else:
                for i in range(0, len(word), chars_per_line):
                    new_line_words.append(word[i:i + chars_per_line])
        lines.append(" ".join(new_line_words))
    return "\n".join(lines)

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
    TEXT_HEIGHT = canvas.height() - HEADING_HEIGHT - (4 * scale)
    chars_per_line = 13 if scale == 1 else 16

    # Fonts
    font_small = "CG-pixel-3x5-mono" if scale == 1 else "terminus-12"
    font_normal = "5x8" if scale == 1 else "terminus-16"

    headline = get_most_important_headline()
    if not headline:
        return render.Root(render.Text(
            "Cannot refresh news",
            # font family
            font = font_small,
        ))
    title = headline["title"]
    topline = headline["topline"]
    date = headline["date"]
    formatted_date = format_time(date) if date else "No time available"
    news_is_urgent = is_breaking(headline)

    if config and not news_is_urgent and config.bool("hide_if_not_urgent"):
        return []

    return render.Root(
        render.Stack([
            render.Box(
                color = "#1e283f",
                width = canvas.width(),
                height = canvas.height(),
            ),
            render.Padding(pad = scale, child =
                                            render.Column(
                                                expanded = True,
                                                children = [
                                                    render.Padding(
                                                        child =
                                                            render.Row(
                                                                expanded = True,
                                                                main_align = "space_between",
                                                                children = [
                                                                    render.Image(height = HEADING_HEIGHT, src = ARD_LOGO_WHITE.readall()),
                                                                    render.Text(
                                                                        formatted_date,
                                                                        # font family
                                                                        font = font_small,
                                                                    ),
                                                                ],
                                                                cross_align = "center",
                                                            ),
                                                        pad = scale,
                                                    ),
                                                    render.Marquee(
                                                        height = TEXT_HEIGHT,
                                                        scroll_direction = "vertical",
                                                        delay = 20,
                                                        child = render.Column(children = [
                                                            render.WrappedText(
                                                                content = ("+++ " if news_is_urgent else "") + format_text(topline, chars_per_line) + ":",
                                                                color = "#FFFF00" if news_is_urgent else "#FFFFFF",
                                                                font = font_normal,
                                                            ),
                                                            render.Padding(
                                                                render.WrappedText(
                                                                    content = format_text(title, chars_per_line) + (" +++" if news_is_urgent else ""),
                                                                    color = "#FFFF00" if news_is_urgent else "#FFFFFF",
                                                                    font = font_normal,
                                                                ),
                                                                pad = (0, 2 * scale, 0, 0),
                                                            ),
                                                        ]),
                                                    ),
                                                ],
                                            )),
        ]),
        delay = 100 // scale,
        show_full_animation = True,
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
