load("render.star", "render")

def main(config):
    content = config.get("content", "text")
    font = config.get("font", "tb-8")
    background_color = config.get("background_color", "#000")
    color = config.get("color", "#fff")

    return render.Root(
        child = render.Box(
            color = background_color,
            child = render.WrappedText(
                content = content,
                font = font,
                color = color,
            ),
        ),
    )
