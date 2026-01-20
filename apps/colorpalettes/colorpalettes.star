"""
Applet: Color Palettes
Summary: User made color palettes
Description: Shows random user-submitted color palettes from Colourpod (www.colourpod.com).
Author: frame-shift
"""

load("math.star", "math")
load("palettes.star", "PALETTES")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

HEX_VALUES = ("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f")
COLORS = ["red", "orange", "yellow", "green", "blue", "purple", "pink", "brown"]
DISPLAY_W = 64

def main(config):
    """
    Render everything for display.

    Args:
        config: Configurations set in get_schema().

    Returns:
        render.Root: Main display output.
    """

    # --- gather list of colors user wants to see ---
    allowed_colors = []
    for c in COLORS:
        if config.bool(c):
            allowed_colors.append(c)

    if not allowed_colors:  # if every color is toggled off, then fallback to all colors
        allowed_colors = COLORS

    # --- fetch palette info ---
    palette_id, hex_codes, palette_colors = get_index(allowed_colors)

    print("FILTER PALETTES FOR: " + ", ".join(allowed_colors))
    print("URL: https://www.colourpod.com/post/" + palette_id)
    print("HEX CODES: " + ", ".join(hex_codes))
    print("COLORS: " + ", ".join(palette_colors))

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

def get_index(allowed_colors):
    """
    Generate a random index number (int) for PALETTES.

    Args:
        allowed_colors (list of str): A list of strings of allowed colors. Accepted values are in COLORS.

    Returns:
        get_palette(index, allowed_colors) : Fetches the palette.
    """

    index = random.number(0, len(PALETTES) - 1)
    return get_palette(index, allowed_colors)

def get_palette(index, allowed_colors):
    """
    Filter for palettes that contain at least one the allowed colors.

    Args:
        index (int): Index number of PALETTES.
        allowed_colors (list of str): A list of strings of allowed colors. Accepted values are in COLORS.

    Returns:
        If the palette has one of the colors in allowed_colors:
            palette_id (str): The ID of the palette that matches the URL for Colourpod.
            hex_codes (list of str): A list of hex codes that make up the palette, formatted as '#a1b2c3'
            palette_colors (list of str): A list of colors found in the palette. Values are found in COLORS.
        If the palette does not have one of the colors in allowed_colors:
            get_index(allowed_colors): Retry for another palette by getting a new index number.
    """

    palette_id = PALETTES[index]["id"]
    hex_codes = PALETTES[index]["codes"]
    palette_colors = PALETTES[index]["colors"]

    # --- check if the palette has one of the allowed_colors ---
    good_colors = []
    for c in allowed_colors:
        if c in palette_colors:
            good_colors.append(c)

    if len(good_colors) > 0:
        return palette_id, hex_codes, palette_colors
    else:
        return get_index(allowed_colors)

def get_schema():
    """
    User options.

    Defaults all colors to True.
    """
    return schema.Schema(
        version = "1",
        fields = [
            # --- filter by color options ---
            # RED
            schema.Toggle(
                id = "red",
                name = "Red",
                desc = "Show palettes that contain red",
                icon = "paintbrush",
                default = True,
            ),
            # ORANGE
            schema.Toggle(
                id = "orange",
                name = "Orange",
                desc = "Show palettes that contain orange",
                icon = "paintbrush",
                default = True,
            ),
            # YELLOW
            schema.Toggle(
                id = "yellow",
                name = "Yellow",
                desc = "Show palettes that contain yellow",
                icon = "paintbrush",
                default = True,
            ),
            # GREEN
            schema.Toggle(
                id = "green",
                name = "Green",
                desc = "Show palettes that contain green",
                icon = "paintbrush",
                default = True,
            ),
            # BLUE
            schema.Toggle(
                id = "blue",
                name = "Blue",
                desc = "Show palettes that contain blue",
                icon = "paintbrush",
                default = True,
            ),
            # PURPLE
            schema.Toggle(
                id = "purple",
                name = "Purple",
                desc = "Show palettes that contain purple",
                icon = "paintbrush",
                default = True,
            ),
            # PINK
            schema.Toggle(
                id = "pink",
                name = "Pink",
                desc = "Show palettes that contain pink",
                icon = "paintbrush",
                default = True,
            ),
            # BROWN
            schema.Toggle(
                id = "brown",
                name = "Brown",
                desc = "Show palettes that contain brown",
                icon = "paintbrush",
                default = True,
            ),
        ],
    )
