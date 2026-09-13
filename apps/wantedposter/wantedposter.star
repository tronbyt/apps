"""
Applet: WantedPoster
Summary: Display Wanted Poster
Description: Displays a custom wanted poster based on an image you upload.
Author: Robert Ison
"""

load("encoding/base64.star", "base64")
load("images/default_criminal.png", DEFAULT_CRIMINAL_ASSET = "file")
load("images/wanted_bottom.png", WANTED_BOTTOM_ASSET = "file")
load("images/wanted_header.png", WANTED_HEADER_ASSET = "file")
load("images/wanted_side.png", WANTED_SIDE_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_CRIMINAL = DEFAULT_CRIMINAL_ASSET.readall()
WANTED_BOTTOM = WANTED_BOTTOM_ASSET.readall()
WANTED_HEADER = WANTED_HEADER_ASSET.readall()
WANTED_SIDE = WANTED_SIDE_ASSET.readall()

def main(config):
    photo = config.get("photo")

    #Use the uploaded photo if it exists, otherwise default to Steve
    if photo == None:
        print("Using Default")
        photo = DEFAULT_CRIMINAL
    else:
        print("Using your photo")
        photo = base64.decode(config.get("photo"))

    sidewidth = 17
    picturewidth = 64 - 2 * sidewidth

    return render.Root(
        render.Column(
            children = [
                render.Image(src = WANTED_HEADER),
                render.Row(
                    children = [
                        render.Image(src = WANTED_SIDE),
                        render.Image(src = photo, width = picturewidth, height = 20),
                        render.Image(src = WANTED_SIDE),
                    ],
                ),
                render.Row(
                    children = [
                        render.Image(src = WANTED_BOTTOM),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.PhotoSelect(
                id = "photo",
                name = "Photo",
                desc = "Upload a photo you want displayed on the wanted poster.",
                icon = "user",
            ),
        ],
    )
