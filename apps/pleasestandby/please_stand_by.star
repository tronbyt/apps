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

def box_row(size, row_height):
    return render.Row(
        children = [
            render.Box(width = size, height = row_height, color = LIGHT_GREY),
            render.Box(width = size, height = row_height, color = YELLOW),
            render.Box(width = size, height = row_height, color = LIGHT_BLUE),
            render.Box(width = size, height = row_height, color = GREEN),
            render.Box(width = size, height = row_height, color = PINK),
            render.Box(width = size, height = row_height, color = RED),
            render.Box(width = size, height = row_height, color = BLUE),
            render.Box(width = size, height = row_height, color = DARK_PINK),
        ],
    )

def ani_image():
    is2x = canvas.is2x()
    scale = 2 if is2x else 1
    full = 8 * scale
    half = 4 * scale
    text_width = 48 * scale

    # The square panel is 64 wide like 1x but twice as tall: keep the column
    # widths and double every row height so the card fills it.
    vs = 2 if is_square() else 1
    row_h = full * vs
    half_h = half * vs

    return render.Column(
        children = [
            box_row(full, row_h),
            render.Row(
                children = [
                    render.Box(width = full, height = row_h, color = LIGHT_GREY),
                    render.Box(
                        width = text_width,
                        height = row_h,
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
                    render.Box(width = full, height = row_h, color = DARK_PINK),
                ],
            ),
            box_row(full, row_h),
            render.Row(
                children = [
                    render.Box(width = full, height = half_h, color = LIGHT_BLUE),
                    render.Box(width = full, height = half_h, color = BLACK),
                    render.Box(width = full, height = half_h, color = PINK),
                    render.Box(width = full, height = half_h, color = MID_GREY),
                    render.Box(width = full, height = half_h, color = LIGHT_BLUE),
                    render.Box(width = full, height = half_h, color = DARK_GREY),
                    render.Box(width = full, height = half_h, color = WHITE),
                    render.Box(width = full, height = half_h, color = RED),
                ],
            ),
            render.Row(
                children = [
                    render.Box(width = 9 * scale, height = half_h, color = BLUE),
                    render.Box(width = 9 * scale, height = half_h, color = WHITE),
                    render.Box(width = 10 * scale, height = half_h, color = PURPLE),
                    render.Box(width = 10 * scale, height = half_h, color = MID_GREY),
                    render.Box(width = 2 * scale, height = half_h, color = BLACK),
                    render.Box(width = 2 * scale, height = half_h, color = DARK_GREY),
                    render.Box(width = 4 * scale, height = half_h, color = MID_GREY),
                    render.Box(width = full, height = half_h, color = DARK_GREY),
                    render.Box(width = full, height = half_h, color = ORANGE),
                    render.Box(width = 2 * scale, height = half_h, color = LIGHT_GREY),
                ],
            ),
        ],
    )

def is_square():
    """True on a 64x64 panel.

    Panels are told apart by SHAPE, never by size: the 128x64 wide panel is
    also 64 tall.
    """
    w, h = canvas.size()
    return h == w

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
