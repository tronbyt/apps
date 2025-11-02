load("render.star", "render")

def main(config):
    content = config.get("content", "text")
    font = config.get("font", "tb-8")
    background_color = config.get("background_color", "#000")
    color = config.get("color", "#fff")
    emoji = config.get("emoji")

    return render.Root(
        child = render.Box(
            color = background_color,
            child = render.Column(
                main_align = "space_evenly",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Emoji(emoji) if emoji else None,
                    render.Marquee(
                        width = 50,
                        offset_start = 49,
                        offset_end = 49,
                        align = "center",
                        child = render.Text(
                            content = content,
                            font = font,
                            color = color,
                        ),
                    ),
                ],
            ),
        ),
    )
