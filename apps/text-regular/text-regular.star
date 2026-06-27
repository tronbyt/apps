load("render.star", "canvas", "render")
load("schema.star", "schema")

FONT_DEFAULT = "default"
DEFAULT_CONTENT = "Text"
DEFAULT_FONT = "tb-8"
DEFAULT_FONT_2X = "terminus-12"
DEFAULT_BACKGROUND_COLOR = "#000"
DEFAULT_COLOR = "#fff"

def main(config):
    width, height, is2x = canvas.width(), canvas.height(), canvas.is2x()

    content = config.get("content", DEFAULT_CONTENT)
    font = config.get("font")
    if not font or font == FONT_DEFAULT:
        font = DEFAULT_FONT_2X if is2x else DEFAULT_FONT
    background_color = config.get("background_color", DEFAULT_BACKGROUND_COLOR)
    color = config.get("color", DEFAULT_COLOR)
    emoji = config.get("emoji")

    pad = 4 if is2x else 2
    emoji_height = 30 if is2x else 20
    text_width = 0
    if emoji:
        text_width = (width - emoji_height - (width // 16))

    return render.Root(
        delay = 25 if is2x else 50,
        show_full_animation = True,
        child = render.Box(
            color = background_color,
            child = render.Row(
                main_align = "space_evenly",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Padding(
                        pad = pad,
                        child = render.Emoji(emoji, height = emoji_height),
                    ) if emoji else None,
                    render.Marquee(
                        height = height,
                        offset_start = height,
                        offset_end = height,
                        align = "center",
                        scroll_direction = "vertical",
                        child = render.WrappedText(
                            width = text_width,
                            content = content,
                            font = font,
                            color = color,
                        ),
                    ) if content else None,
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
                id = "content",
                name = "Content",
                desc = "Text to display",
                icon = "message",
                default = DEFAULT_CONTENT,
            ),
            schema.Dropdown(
                id = "font",
                name = "Font",
                desc = "Change the font of the text.",
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
                name = "Text Color",
                desc = "Text color",
                icon = "palette",
                default = DEFAULT_COLOR,
            ),
            schema.Text(
                id = "emoji",
                name = "Emoji",
                desc = "Optional emoji to show",
                icon = "faceSmile",
            ),
        ],
    )
