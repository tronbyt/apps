load("render.star", "render")

default_title = "TITLE"
default_font = "6x10"
default_color = "#00f"

def main(config):
    content = config.get("content", "text")
    font = config.get("font", "tb-8")
    background_color = config.get("background_color", "#000")
    color = config.get("color", "#fff")
    title = config.get("title", default_title)
    titlefont = config.get("titlefont", default_font)
    titlecolor = config.get("titlecolor", default_color)
    emoji = config.get("emoji")

    return render.Root(
        child = render.Box(
            color = background_color,
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Emoji(emoji, height = 20) if emoji else None,
                    render.Column(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.WrappedText(
                                content = title,
                                font = titlefont,
                                color = titlecolor,
                                align = "center",
                                linespacing = 0,
                            ),
                            render.Marquee(
                                width = 60 if not emoji else 40,
                                offset_start = 59 if not emoji else 39,
                                offset_end = 59 if not emoji else 39,
                                child = render.Text(
                                    content = content,
                                    font = font,
                                    color = color,
                                ),
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )
