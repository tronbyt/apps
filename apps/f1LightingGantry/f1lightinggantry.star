"""
Applet: F1 Lighting Gantry
Summary: F1 Starting Lights
Description: Displays starting light countdown to a race.
Author: Robert Ison
"""

load("files/black.png", BLACK_LIGHT_FILE = "file")
load("files/red.png", RED_LIGHT_FILE = "file")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")

def main():
    animation = []
    append_stacks(animation, [
        create_light_frame(0),
        create_light_frame(0),
        create_light_frame(0),
        create_light_frame(1),
        create_light_frame(2),
        create_light_frame(3),
        create_light_frame(4),
        create_light_frame(5),
    ])

    for _ in range(random.number(1, 5)):
        append_stacks(animation, [create_light_frame(5)])

    return render.Root(
        delay = 1000 if canvas.is2x() else 650,
        child = render.Animation(
            children = animation,
        ),
        show_full_animation = True,
    )

def append_stacks(animation, stacks):
    for s in stacks:
        animation.append(s)

def create_light_frame(step):
    children = []

    if canvas.is2x():
        children.append(get_light_row(0))
        children.append(get_light_row(0))

    children.append(get_light_row(step))
    children.append(get_light_row(step))

    return render.Stack(
        children = [
            render.Column(
                children = children,
            ),
        ],
    )

def get_light_row(step):
    children = []

    if canvas.is2x():
        width_spacer = int((canvas.width() - (5 * 16)) // 2)
        image_pixel_width = 16
        children.append(render.Box(width = width_spacer, height = image_pixel_width, color = "#000000"))

    else:
        image_pixel_width = 12

    for i in range(1, 6):
        children.append(render.Image(width = image_pixel_width, src = RED_LIGHT_FILE.readall() if step >= i else BLACK_LIGHT_FILE.readall()))

    return render.Row(
        children = children,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
        ],
    )
