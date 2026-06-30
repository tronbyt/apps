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
COLORS = ("red", "orange", "yellow", "green", "blue", "purple", "pink", "brown")
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
    allowed_colors = [c for c in COLORS if config.bool(c)]

    if not allowed_colors:  # if every color is toggled off, then fallback to all colors
        allowed_colors = COLORS

    # --- fetch palette info; print results ---
    palette_id, hex_codes, palette_colors = get_palette_info(tuple(allowed_colors))

    print("FIND PALETTES WITH ONE OF: " + ", ".join(allowed_colors))
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

def get_palette_info(allowed_colors):
    """
    Selects a random palette that contains at least one of the allowed colors.

    Args:
        allowed_colors (list of str): A list of strings of allowed colors.

    Returns:
        tuple: (palette_id, hex_codes, palette_colors) for a matching palette.
    """

    # --- compile palettes that match allowed_colors ---
    matching_palettes = []

    if allowed_colors == COLORS:  # if all colors selected, then skip compiling
        search_list = PALETTES
    else:
        allowed_colors_set = set(allowed_colors)
        seen_ids = set()
        for palette in PALETTES:
            if set(palette["colors"]).intersection(allowed_colors_set) and palette["id"] not in seen_ids:
                matching_palettes.append(palette)
                seen_ids.add(palette["id"])
        search_list = matching_palettes

    if not matching_palettes:  # fallback to all palettes if no color match
        search_list = PALETTES

    # --- select and return palette ---
    idx = random.number(0, len(search_list) - 1)
    selected_palette = search_list[idx]

    return selected_palette["id"], selected_palette["codes"], selected_palette["colors"]

def get_schema():
    """
    User options. Defaults every color to True.
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
