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

    return render.Root(
        child = render.Box(
            color = background_color,
            child = render.Column(
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
                        width = 60,
                        offset_start = 59,
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
