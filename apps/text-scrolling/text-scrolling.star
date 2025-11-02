load("render.star", "render")

def main(config):
    content = config.get("content", "text")
    font = config.get("font", "tb-8")
    background_color = config.get("background_color", "#000")
    color = config.get("color", "#fff")

    return render.Root(
        child = render.Box(
            color = background_color,
            child = render.Row(
                expanded = True,  # Use as much horizontal space as possible
                main_align = "space_evenly",  # Controls horizontal alignment
                cross_align = "center",  # Controls vertical alignment
                children = [
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
