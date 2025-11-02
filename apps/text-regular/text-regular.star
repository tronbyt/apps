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
            child = render.Row(
                main_align = "space_evenly",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Emoji(emoji, height = 20) if emoji else None,
                    render.WrappedText(
                        content = content,
                        font = font,
                        color = color,
                    ),
                ],
            ),
        ),
    )
