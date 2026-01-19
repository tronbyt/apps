"""
Applet: Color Palettes
Summary: User made color palettes
Description: Shows random user-submitted color palettes from Colourpod (www.colourpod.com).
Author: frame-shift
"""

load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("palettes.star", "PALETTES")

HEX_VALUES = ("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f")
DISPLAY_W = 64

def main():
    """
    Render everything for display.
    """

    index = random.number(0, len(PALETTES) - 1)
    palette_id, hex_codes = PALETTES[index]["id"], PALETTES[index]["codes"]
    print("URL: https://www.colourpod.com/post/" + palette_id)
    print("HEX CODES: " + " ".join(hex_codes))

    # --- generate color boxes ---
    color_count = len(hex_codes)
    box_width = math.floor(DISPLAY_W / color_count)
    remainder = DISPLAY_W % color_count
    color_boxes = []

    for c in range(color_count):
        box_add = 1 if c in range(remainder) else 0
        box = render.Box(color = hex_codes[c], width = box_width + box_add)
        color_boxes.append(box)

    # --- render for display ---
    return render.Root(
        child = render.Row(children = color_boxes),
    )


