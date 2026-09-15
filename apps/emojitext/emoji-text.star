load("render.star", "render")
load("schema.star", "schema")

main_font = "6x13"
subtext_font = "tom-thumb"
MarqueeWidth = 44

def main(config):
    main_text = config.get("main_text", "Main Text")
    main_color = config.get("main_color", "#FFA500")
    subtext = config.get("subtext", "Subtext")
    subtext_color = config.get("subtext_color", "#FFFFFF")
    emoji = config.get("emoji", "🟢")
    background_color = config.get("background_color", "#000000")

    return render.Root(
        child = render.Box(
            color = background_color,
            child = render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Padding(
                        pad = (2, 0, 2, 0),
                        child = render.Emoji(emoji = emoji, height = 24),
                    ),
                    render.Column(
                        expanded = True,
                        main_align = "center",
                        cross_align = "start",
                        children = [
                            render.Marquee(
                                width = MarqueeWidth,
                                child = render.Text(
                                    content = main_text,
                                    font = main_font,
                                    color = main_color,
                                ),
                            ),
                            render.Marquee(
                                width = 44,
                                child = render.Text(
                                    content = subtext,
                                    font = subtext_font,
                                    color = subtext_color,
                                ),
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "main_text",
                name = "Main Text",
                desc = "Primary text to display",
                icon = "font",
                default = "Main Text",
            ),
            schema.Color(
                id = "main_color",
                name = "Main Text Color",
                desc = "Color for main text",
                icon = "palette",
                default = "#FFA500",
            ),
            schema.Text(
                id = "subtext",
                name = "Subtext",
                desc = "Secondary text to display",
                icon = "font",
                default = "Subtext",
            ),
            schema.Color(
                id = "subtext_color",
                name = "Subtext Color",
                desc = "Color for subtext",
                icon = "palette",
                default = "#FFFFFF",
            ),
            schema.Text(
                id = "emoji",
                name = "Emoji",
                desc = "Emoji to display",
                icon = "faceSmile",
                default = "🟢",
            ),
            schema.Color(
                id = "background_color",
                name = "Background Color",
                desc = "Background color of the app",
                icon = "palette",
                default = "#000000",
            ),
        ],
    )
