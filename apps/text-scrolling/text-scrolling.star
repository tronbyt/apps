load("render.star", "render")
load("schema.star", "schema")

DEFAULT_CONTENT = "Text"
DEFAULT_FONT = "tb-8"
DEFAULT_BACKGROUND_COLOR = "#000"
DEFAULT_COLOR = "#fff"

def main(config):
    content = config.get("content", DEFAULT_CONTENT)
    font = config.get("font", DEFAULT_FONT)
    background_color = config.get("background_color", DEFAULT_BACKGROUND_COLOR)
    color = config.get("color", DEFAULT_COLOR)
    emoji = config.get("emoji")

    return render.Root(
        show_full_animation = True,
        child = render.Box(
            color = background_color,
            child = render.Column(
                main_align = "space_evenly",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Emoji(emoji) if emoji else None,
                    render.Marquee(
                        width = 60,
                        offset_start = 59,
                        offset_end = 59,
                        align = "center",
                        child = render.Text(
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
        schema.Option(display = key, value = value)
        for key, value in sorted(render.fonts.items())
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "content",
                name = "Content",
                desc = "Text that scrolls across the display",
                icon = "message",
                default = DEFAULT_CONTENT,
            ),
            schema.Dropdown(
                id = "font",
                name = "Font",
                desc = "Change the font of the text.",
                icon = "font",
                default = DEFAULT_FONT,
                options = fonts,
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
