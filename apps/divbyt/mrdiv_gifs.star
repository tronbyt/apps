"""
Applet: Divbyt
Summary: Displays gifs from mrdiv 
Description: Looping geometric animations from animated GIF artist Mr. Div, designed specifically for Tidbyt. A random animation will play each time from a (possibly) expanding pool of GIFs.
Author: imnotdannorton
"""

load("images/helixer.webp", helixer = "file")
load("images/tri_circle.webp", tri_circle = "file")
load("images/tri_grid.webp", tri_grid = "file")
load("images/tri_waves_v2.webp", tri_waves_v2 = "file")
load("images/vortex_v2.webp", vortex_v2 = "file")
load("random.star", "random")
load("render.star", "render")
load("time.star", "time")

images = [helixer, tri_circle, tri_grid, tri_waves_v2, vortex_v2]

def main():
    random.seed(time.now().unix // 60)
    image = images[random.number(0, len(images) - 1)].readall()
    return render.Root(render.Box(render.Image(src = image)))
