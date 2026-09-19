"""
Applet: Please Stand By
Summary: Displays Please Stand By
Description: Displays Please Stand By message.
Author: Ethan Fuerst (@ethanfuerst)
"""

load("render.star", "canvas", "render")
load("schema.star", "schema")

RED = "#FF3333"
ORANGE = "#FF9933"
YELLOW = "#FFFF33"
LIGHT_GREEN = "#99FF33"
GREEN = "#33FF33"
LIGHT_BLUE = "#33FFFF"
BLUE = "#3399FF"
PURPLE = "#3333FF"
VIOLET = "#9933FF"
PINK = "#FF33FF"
DARK_PINK = "#FF3399"
LIGHT_GREY = "#C0C0C0"
MID_GREY = "#404040"
DARK_GREY = "#808080"
BLACK = "#000000"
WHITE = "#FFFFFF"

def box_row(size):
    return render.Row(
        children = [
            render.Box(width = size, height = size, color = LIGHT_GREY),
            render.Box(width = size, height = size, color = YELLOW),
            render.Box(width = size, height = size, color = LIGHT_BLUE),
            render.Box(width = size, height = size, color = GREEN),
            render.Box(width = size, height = size, color = PINK),
            render.Box(width = size, height = size, color = RED),
            render.Box(width = size, height = size, color = BLUE),
            render.Box(width = size, height = size, color = DARK_PINK),
        ],
    )

def ani_image():
    is2x = canvas.is2x()
    scale = 2 if is2x else 1
    full = 8 * scale
    half = 4 * scale
    text_width = 48 * scale

    return render.Column(
        children = [
            box_row(full),
            render.Row(
                children = [
                    render.Box(width = full, height = full, color = LIGHT_GREY),
                    render.Box(
                        width = text_width,
                        height = full,
                        child = render.Padding(
                            pad = (0, 2 if is2x else 0, 0, 0),
                            child = render.Marquee(
                                width = text_width,
                                offset_start = text_width,
                                offset_end = text_width,
                                child = render.Text(
                                    content = "PLEASE STAND BY",
                                    font = "terminus-16" if is2x else "tb-8",
                                ),
                            ),
                        ),
                    ),
                    render.Box(width = full, height = full, color = DARK_PINK),
                ],
            ),
            box_row(full),
            render.Row(
                children = [
                    render.Box(width = full, height = half, color = LIGHT_BLUE),
                    render.Box(width = full, height = half, color = BLACK),
                    render.Box(width = full, height = half, color = PINK),
                    render.Box(width = full, height = half, color = MID_GREY),
                    render.Box(width = full, height = half, color = LIGHT_BLUE),
                    render.Box(width = full, height = half, color = DARK_GREY),
                    render.Box(width = full, height = half, color = WHITE),
                    render.Box(width = full, height = half, color = RED),
                ],
            ),
            render.Row(
                children = [
                    render.Box(width = 9 * scale, height = half, color = BLUE),
                    render.Box(width = 9 * scale, height = half, color = WHITE),
                    render.Box(width = 10 * scale, height = half, color = PURPLE),
                    render.Box(width = 10 * scale, height = half, color = MID_GREY),
                    render.Box(width = 2 * scale, height = half, color = BLACK),
                    render.Box(width = 2 * scale, height = half, color = DARK_GREY),
                    render.Box(width = 4 * scale, height = half, color = MID_GREY),
                    render.Box(width = full, height = half, color = DARK_GREY),
                    render.Box(width = full, height = half, color = ORANGE),
                    render.Box(width = 2 * scale, height = half, color = LIGHT_GREY),
                ],
            ),
        ],
    )

def main():
    return render.Root(
        delay = 50 if canvas.is2x() else 100,
        child = ani_image(),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
