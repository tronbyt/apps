"""
Applet: Javelexi
Summary: Javelexi Animation
Description: An animated javelina girl who is happy to see you!
Author: Nicholas Mejia
"""

load("images/javelexi.gif", JAVELEXI_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

JAVELEXI = JAVELEXI_ASSET.readall()

def main():
    return render.Root(
        child = render.Image(src = JAVELEXI),
    )

def get_schema():
    return schema.Schema(version = "1", fields = [])
