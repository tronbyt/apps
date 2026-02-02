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

    # 1. Initial Pause (All Black)
    for _ in range(3):
        animation.append(create_light_frame(0))

    # 2. Sequential Lighting (1 to 5)
    for i in range(1, 6):
        animation.append(create_light_frame(i))

    # 3. The Random Hold (Keep 5 lights on)
    for _ in range(random.number(2, 6)):
        animation.append(create_light_frame(5))

    # 4. LIGHTS OUT (Race Start)
    # Adding multiple frames of '0' at the end ensures the
    # screen stays black for a moment before the loop restarts.
    for _ in range(5):
        animation.append(create_light_frame(0))

    return render.Root(
        delay = 1000 if canvas.is2x() else 650,
        child = render.Animation(
            children = animation,
        ),
        show_full_animation = True,
    )

def create_light_frame(step):
    children = []

    # Vertical centering for 2x displays
    if canvas.is2x():
        children.append(get_light_row(0))
        children.append(get_light_row(0))

    children.append(get_light_row(step))
    children.append(get_light_row(step))

    return render.Column(
        children = children,
    )

def get_light_row(step):
    light_images = []

    if canvas.is2x():
        image_pixel_width = 16
    else:
        image_pixel_width = 12

    # Just build the list of 5 images first
    for i in range(1, 6):
        img_data = RED_LIGHT_FILE.readall() if step >= i else BLACK_LIGHT_FILE.readall()
        light_images.append(render.Image(width = image_pixel_width, src = img_data))

    # Wrap the images in a Row with 'center' alignment,
    # and put that inside a Box that is the full width of the screen.
    return render.Box(
        width = canvas.width(),
        height = image_pixel_width,
        child = render.Row(
            expanded = True,  # Make the row fill the Box width
            main_align = "center",  # This centers the children horizontally
            children = light_images,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
