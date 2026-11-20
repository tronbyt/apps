"""
Applet: Custom Animation
Summary: Display custom animated GIFs and images
Description: Display a single custom image with full support for animated GIFs.
Author: tronbyt
"""

#custom_animation.star
#Created 20250110

load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    #get image
    img_data = config.get("image")
    if img_data == None:
        return render.Root(
            child = render.Box(render.WrappedText(
                width = 64,
                align = "center",
                content = "No image selected!!!!",
            )),
        )

    img = render.Image(
        src = base64.decode(img_data),
        width = 64,
        height = 32,
    )

    return render.Root(
        delay = img.delay,
        child = img,
        show_full_animation = True,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.PhotoSelect(
                id = "image",
                name = "Image",
                desc = "Supports PNG, JPG, GIF (animated), GIFs recommended for animations. Previews may not display.",
                icon = "image",
            ),
        ],
    )
