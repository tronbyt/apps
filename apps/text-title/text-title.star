load("render.star", "canvas", "render")
load("schema.star", "schema")

FONT_DEFAULT = "default"
DEFAULT_CONTENT = "Text"
DEFAULT_FONT = "tb-8"
DEFAULT_FONT_2X = "terminus-12"
DEFAULT_BACKGROUND_COLOR = "#000"
DEFAULT_COLOR = "#fff"
DEFAULT_TITLE = "TITLE"
DEFAULT_TITLE_FONT = "6x10"
DEFAULT_TITLE_FONT_2X = "terminus-16"
DEFAULT_TITLE_COLOR = "#00f"

def main(config):
    width, is2x = canvas.width(), canvas.is2x()

    content = config.get("content", DEFAULT_CONTENT)
    font = config.get("font")
    if not font or font == FONT_DEFAULT:
        font = DEFAULT_FONT_2X if is2x else DEFAULT_FONT
    background_color = config.get("background_color", DEFAULT_BACKGROUND_COLOR)
    color = config.get("color", DEFAULT_COLOR)
    title = config.get("title", DEFAULT_TITLE)
    titlefont = config.get("titlefont")
    if not titlefont or titlefont == FONT_DEFAULT:
        titlefont = DEFAULT_TITLE_FONT_2X if is2x else DEFAULT_TITLE_FONT
    titlecolor = config.get("titlecolor", DEFAULT_TITLE_COLOR)
    emoji = config.get("emoji")

    pad = 4 if is2x else 2
    emoji_height = 30 if is2x else 20
    text_width = (width - emoji_height - (width // 16)) if emoji else width

    return render.Root(
        delay = 25 if is2x else 50,
        show_full_animation = True,
        child = render.Box(
            color = background_color,
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Padding(
                        pad = pad,
                        child = render.Emoji(emoji, height = emoji_height),
                    ) if emoji else None,
                    render.Column(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Marquee(
                                width = text_width,
                                offset_start = text_width,
                                offset_end = text_width,
                                align = "center",
                                child = render.Text(
                                    content = title,
                                    font = titlefont,
                                    color = titlecolor,
                                ),
                            ) if title else None,
                            render.Marquee(
                                width = text_width,
                                offset_start = text_width,
                                offset_end = text_width,
                                align = "center",
                                child = render.Text(
                                    content = content,
                                    font = font,
                                    color = color,
                                ),
                            ) if content else None,
                        ],
                    ) if title or content else None,
                ],
            ),
        ),
    )

def get_schema():
    fonts = [
        schema.Option(display = "Default", value = FONT_DEFAULT),
    ]
    fonts.extend([
        schema.Option(display = key, value = value)
        for key, value in sorted(render.fonts.items())
    ])

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "title",
                name = "Title",
                desc = "Headline text shown above the content",
                icon = "font",
                default = DEFAULT_TITLE,
            ),
            schema.Dropdown(
                id = "titlefont",
                name = "Title Font",
                desc = "Change the font of the title.",
                icon = "font",
                options = fonts,
                default = FONT_DEFAULT,
            ),
            schema.Color(
                id = "titlecolor",
                name = "Title Color",
                desc = "Color of the title text",
                icon = "palette",
                default = DEFAULT_TITLE_COLOR,
            ),
            schema.Text(
                id = "content",
                name = "Content",
                desc = "Scrolling body text",
                icon = "message",
                default = DEFAULT_CONTENT,
            ),
            schema.Dropdown(
                id = "font",
                name = "Content Font",
                desc = "Change the font of the body text.",
                icon = "font",
                options = fonts,
                default = FONT_DEFAULT,
            ),
            schema.Color(
                id = "background_color",
                name = "Background",
                desc = "Background color",
                icon = "palette",
                default = DEFAULT_BACKGROUND_COLOR,
            ),
            schema.Color(
                id = "color",
                name = "Content Color",
                desc = "Color of the body text",
                icon = "palette",
                default = DEFAULT_COLOR,
            ),
            schema.Text(
                id = "emoji",
                name = "Emoji",
                desc = "Optional emoji to show next to the title",
                icon = "faceSmile",
            ),
        ],
    )
