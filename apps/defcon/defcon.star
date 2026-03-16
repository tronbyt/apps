"""
Applet: DefCon
Summary: Displays DefCon Status
Description: Displays the estimated DefCon (Defense Condition) alert level for the U.S. The source of this is DefConLevel.com.
Author: Robert Ison
"""

load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")

DEF_CON_URL = "https://www.defconlevel.com/current-level"
CACHE_TTL_SECONDS = 3 * 24 * 60 * 60
SCALE = 2 if canvas.is2x() else 1
FONT = "terminus-32-light" if canvas.is2x() else "6x13"
DEF_CON_COLORS = ["#fff", "#ff0000", "#ffff00", "#00ff00", "#0000ff"]

display_options = [
    schema.Option(value = "5", display = "DEFCON 5 - Normal Readiness"),
    schema.Option(value = "4", display = "DEFCON 4 - Above Normal Readiness"),
    schema.Option(value = "3", display = "DEFCON 3 - High Caution"),
    schema.Option(value = "2", display = "DEFCON 2 - Risk of Impending Attack"),
    schema.Option(value = "1", display = "DEFCON 1 - Maximum Readiness"),
    schema.Option(value = "0", display = "Actual DEFCON Level"),
]

def trim_left(text):
    """Remove leading whitespace recursively."""
    if not text or text[0] != " ":
        return text
    return trim_left(text[1:])

def trim_right(text):
    """Remove trailing whitespace recursively."""
    if not text or text[-1] != " ":
        return text
    return trim_right(text[:-1])

def extract_defcon_level(html):
    """Extract DEFCON number (int) from badge-number span."""
    if not html:
        return 0

    start_marker = '<span class="badge-number">'
    start_pos = html.find(start_marker)
    if start_pos == -1:
        return 0

    content_start = start_pos + len(start_marker)
    end_tag_pos = html.find("</span>", content_start)
    if end_tag_pos == -1:
        return 0

    # Extract raw content
    defcon_text = html[content_start:end_tag_pos]
    defcon_text = trim_left(defcon_text)
    defcon_text = trim_right(defcon_text)

    # Extract just the number after "DEFCON "
    if defcon_text.startswith("DEFCON "):
        number_str = defcon_text[6:]  # Skip "DEFCON "
    else:
        number_str = defcon_text

    return int(number_str.strip())

def main(config):
    show_instructions = config.bool("instructions", False)
    if show_instructions:
        return display_instructions()

    position = config.get("list", display_options[0].value)

    if position == "0":
        res = http.get(url = DEF_CON_URL, ttl_seconds = CACHE_TTL_SECONDS, headers = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36", "Accept": "text/html"})
        if res.status_code != 200:
            fail("request to %s failed with status code: %d - %s" % (DEF_CON_URL, res.status_code, res.body()))

        position = extract_defcon_level(res.body())

    width, height = canvas.size()
    defcon_height = height // 2 - 1

    return render.Root(
        delay = 1000,
        child = render.Column(
            expanded = True,
            main_align = "space_between",
            children = [
                render.Box(
                    width = width,
                    height = defcon_height,
                    color = "#fff",
                    child = render.Box(
                        width = width - 2 * SCALE,
                        height = defcon_height - 2 * SCALE,
                        color = "#000",
                        child = render.Text("DEFCON", color = "#fff", font = FONT),
                    ),
                ),
                render_defcon_display(config.bool("animate", True), position),
            ],
        ),
    )

def render_defcon_display(animate, position):
    if animate:
        return render.Animation(children = get_defcon_display(position))
    else:
        children = get_defcon_display(position)
        return children.pop()

def render_box(i, width, height, color):
    return render.Box(
        width = width,
        height = height,
        color = color,
        child = render.Box(
            width = width - 2 * SCALE,
            height = height - 2 * SCALE,
            color = "#000",
            child = render.Padding(
                pad = (0 if canvas.is2x() else 1, 0, 0, 0),
                child = render.Text(str(i), color = color, font = FONT),
            ),
        ),
    )

def get_defcon_display(position):
    children = []
    position = int(position)
    width = (canvas.width() // 5) - (1 if canvas.is2x() else 0)
    height = canvas.height() // 2

    # Render grey outlines
    grey_children = []
    for i in range(5):
        grey_children.append(render_box(i + 1, width, height, "#333"))

    grey_box = render.Row(
        expanded = True,
        main_align = "space_between",
        children = grey_children,
    )
    children.append(grey_box)

    # Render colored boxes
    color_box = None
    for i in range(4, position - 2, -1):
        color_children = []
        for j in range(5):
            if i == j and j >= position - 1:
                color_children.append(render_box(j + 1, width, height, DEF_CON_COLORS[j]))
            else:
                color_children.append(grey_children[j])

        color_box = render.Row(
            expanded = True,
            main_align = "space_between",
            children = color_children,
        )
        children.append(color_box)

    # Flash current
    for _ in range(3):
        children.append(grey_box)
        children.append(color_box)

    # Hold current for a while longer
    for _ in range(3):
        children.append(color_box)

    return children

def display_instructions():
    width = canvas.width()
    font = "terminus-16" if canvas.is2x() else "5x8"
    instructions_1 = "For security reasons, the U.S. military does not release the current DEFCON level. "
    instructions_2 = "The source for this app is defconlevel.com which uses Open Source Intelligence to estimate the DEFCON level.  Default is to use the actual estimated DefCon level, but you can pick a level if you want. "
    instructions_3 = "Defcon level 5 is the lowest alert level. The highest level reached was level 2 during the Cuban Missle Crisis. This display is based on the movie War Games (1983)."
    return render.Root(
        render.Column(
            children = [
                render.Marquee(
                    width = width,
                    child = render.Text("DEFCON", color = DEF_CON_COLORS[0], font = font),
                ),
                render.Marquee(
                    width = width,
                    child = render.Text(instructions_1, color = DEF_CON_COLORS[1]),
                ),
                render.Marquee(
                    offset_start = len(instructions_1) * 5,
                    width = width,
                    child = render.Text(instructions_2, color = DEF_CON_COLORS[2]),
                ),
                render.Marquee(
                    offset_start = (len(instructions_2) + len(instructions_1)) * 5,
                    width = width,
                    child = render.Text(instructions_3, color = DEF_CON_COLORS[3]),
                ),
            ],
        ),
        show_full_animation = True,
        delay = 25 if canvas.is2x() else 45,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "list",
                name = "Defcon List",
                desc = "Defcon Level",
                icon = "list",
                default = display_options[0].value,
                options = display_options,
            ),
            schema.Toggle(
                id = "animate",
                name = "Animate Display",
                desc = "Do you want to see the display go from 5 to the current level or simply have a static display of the current level?",
                icon = "play",  #"info",
                default = True,
            ),
            schema.Toggle(
                id = "instructions",
                name = "Display Instructions",
                desc = "",
                icon = "book",  #"info",
                default = False,
            ),
        ],
    )
