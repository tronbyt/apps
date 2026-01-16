"""
Applet: Color Palettes
Summary: User made color palettes
Description: Shows random user-submitted color palettes from Colourpod (www.colourpod.com).
Author: frame-shift

If any errors when fetching palette, this app will generate a random monochromatic palette.
"""

load("bsoup.star", "bsoup")
load("http.star", "http")
load("math.star", "math")
load("random.star", "random")
load("re.star", "re")
load("render.star", "render")

HEX_VALUES = ("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f")
DISPLAY_W = 64
URL = "https://www.colourpod.com/random"

def main():
    """
    Render everything for display.
    """

    hex_codes = get_codes()

    # --- generate color boxes ---
    color_count = len(hex_codes)
    box_width = DISPLAY_W / color_count
    remainder = DISPLAY_W % color_count
    color_boxes = []

    if remainder == 0:  # if all boxes can fit display with equal width
        for c in hex_codes:
            box = render.Box(color = c, width = int(box_width))
            color_boxes.append(box)

    else:  # if boxes need differing widths to fill display
        box_width = math.floor(DISPLAY_W / color_count)

        for c in range(color_count):
            box_add = 1 if c in range(remainder) else 0
            box = render.Box(color = hex_codes[c], width = box_width + box_add)
            color_boxes.append(box)

    # --- render for display ---
    return render.Root(
        child = render.Row(children = color_boxes),
    )

def get_codes():
    """
    Fetch a list of hex codes from URL. If codes cannot be found, generate a backup palette.

    Returns:
        hex_codes (list of str): List of hex codes, each formatted as '#abc123'.
        generate_palette(): Only if error in interpreting hex codes from URL.
    """

    # --- fetch colourpod post ---
    page = http.get(URL)

    if page.status_code != 200:
        print("Cannot reach URL - generating random monochromatic palette...")
        return generate_palette()

    print("POST URL: " + page.url)

    soup = bsoup.parseHtml(page.body())

    # --- extract post id ---
    post_id_search = re.match(r"post\/(\d{4,})\/", page.url)

    if not post_id_search:
        print("Post ID not found - generating random monochromatic palette...")
        return generate_palette()

    post_id = re.match(r"post\/(\d{4,})\/", page.url)[0][1]

    # --- extract caption ---
    caption_search = soup.find(id = post_id).find_all("p")

    if not caption_search:
        print("Caption not found - generating random monochromatic palette...")
        return generate_palette()

    caption_str = " ".join([str(r) for r in caption_search])
    caption = re.sub(r"<.+?>", "", caption_str)

    # --- extract hex codes ---
    hex_search = re.findall(r"#.+#\w{6}", caption)

    if not hex_search:
        print("Hex codes not found - generating random monochromatic palette...")
        return generate_palette()

    # hex codes not always properly formatted; this block ensures uniformity
    hex_fix_a = re.sub(r"[^[\w]", "@", hex_search[0].lower())
    hex_fix_b = re.sub(r"@{1,}", " ", hex_fix_a).strip()
    hex_extract = re.sub(r"(\w{6})", "#$1", hex_fix_b)
    good_codes = len(hex_extract) > 1 and re.match(r"#\w{6}", hex_extract)

    if not good_codes:
        print("Cannot format hex codes - generating random monochromatic palette...")
        return generate_palette()

    print("HEX CODES: " + hex_extract)

    hex_codes = hex_extract.split(" ")

    return hex_codes

def generate_palette():
    """
    Generates a random 5-color monochromatic palette.

    Returns:
        colors_hex (list of str): List of 5 hex codes, each formatted as '#abc123'.
    """

    # --- generate base color as hsl---
    lum_shift = 0.15  # breaks above certain value
    lum_a = int(((2 * lum_shift) + lum_shift) * 1000)
    lum_b = int(abs(1000 - lum_a))
    hue = random.number(0, 360)
    sat = random.number(225, 1000) / 1000  # want some minimum level of saturation so its colorful
    lum = random.number(min(lum_a, lum_b), max(lum_a, lum_b)) / 1000

    base = [hue, sat, lum]

    # --- generate surrounding colors as hsl ---
    lum_left1 = lum - lum_shift
    lum_left2 = lum - (2 * lum_shift)
    lum_right1 = lum + lum_shift
    lum_right2 = lum + (2 * lum_shift)

    color_left1 = [hue, sat, lum_left1]
    color_left2 = [hue, sat, lum_left2]
    color_right1 = [hue, sat, lum_right1]
    color_right2 = [hue, sat, lum_right2]

    colors_hsl = [color_left2, color_left1, base, color_right1, color_right2]

    # --- convert hsl to rgb ---
    # formulas from RapidTables: https://web.archive.org/web/20251227035922/https://www.rapidtables.com/convert/color/hsl-to-rgb.html
    colors_rgb = []

    for color in colors_hsl:
        hue, sat, lum = color[0], color[1], color[2]

        # set c
        c_x = (2 * lum) - 1
        c = (1 - abs(c_x)) * sat

        # set x
        x_x = (hue / 60) % 2
        x_y = 1 - abs(x_x - 1)
        x = c * x_y

        # set m
        m = lum - (c / 2)

        # set rgb_r
        if hue >= 0 and hue < 60:
            rgb_r = [c, x, 0]
        elif hue >= 60 and hue < 120:
            rgb_r = [x, c, 0]
        elif hue >= 120 and hue < 180:
            rgb_r = [0, c, x]
        elif hue >= 180 and hue < 240:
            rgb_r = [0, x, c]
        elif hue >= 240 and hue < 300:
            rgb_r = [x, 0, c]
        elif hue >= 300 and hue < 360:
            rgb_r = [c, 0, x]
        else:
            rgb_r = [0, 0, 0]

        # set rgb
        rgb = [int(math.round((chan + m) * 255)) for chan in rgb_r]
        colors_rgb.append(rgb)

    # --- convert rgb to hex ---
    colors_hex = []

    for color in colors_rgb:
        x = []

        for chan in color:
            h_1 = str(HEX_VALUES[int(chan // 16)])
            h_2 = str(HEX_VALUES[chan % 16])
            x.append(h_1 + h_2)

        hex = "#" + "".join(x)
        colors_hex.append(hex)

    print("HEX CODES: " + " ".join(colors_hex))

    return colors_hex
