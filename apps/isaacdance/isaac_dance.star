"""
Applet: Isaac Dance
Summary: Isaac Specialist Dance
Description: This app presents the character Isaac from the franchise The Binding of Isaac doing the popular specialist dance.
Author: Dylan Nashawaty
"""

load("images/gif_content.gif", GIF_CONTENT_ASSET = "file")
load("render.star", "render")

GIF_CONTENT = GIF_CONTENT_ASSET.readall()

def main():
    image_instance = render.Image(src = GIF_CONTENT, width = 64, height = 32)
    return render.Root(image_instance)
