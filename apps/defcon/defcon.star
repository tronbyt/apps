"""
Applet: DefCon
Summary: Displays DefCon Status
Description: Displays the estimated DefCon (Defense Condition) alert level for the U.S. The source of this is DefConLevel.com.
Author: Robert Ison
"""

load("html.star", "html")
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

VALID_LEVELS = ["1", "2", "3", "4", "5"]

def fail_debug(step, message):
    fail("DEFCON app error [" + step + "]: " + message)

def normalize_level_text(text):
    if text == None:
        fail_debug("parse", "badge text was empty")

    text = str(text).strip()

    if text == "":
        fail_debug("parse", "badge text was blank")

    if text.startswith("DEFCON "):
        text = text[len("DEFCON "):]

    text = text.strip()

    if text not in VALID_LEVELS:
        fail_debug("parse", "unexpected badge text: " + text)

    return int(text)

def get_defcon_level():
    res = http.get(
        url = DEF_CON_URL,
        ttl_seconds = CACHE_TTL_SECONDS,
        headers = {
            "User-Agent": "Mozilla/5.0 (compatible; DefConTidbyt/1.0)",
            "Accept": "text/html",
        },
    )

    if res.status_code != 200:
        fail_debug("http", "GET " + DEF_CON_URL + " returned status " + str(res.status_code))

    body = res.body()
    if body == None:
        fail_debug("http", "response body was None")

    body = str(body)
    if body.strip() == "":
        fail_debug("http", "response body was empty")

    page = html(body)
    badge = page.find("span.badge-number")
    if not badge:
        fail_debug("html", "selector span.badge-number not found")

    badge_text = badge.text()
    return normalize_level_text(badge_text)

def get_selected_position(config):
    position = config.get("list", display_options[0].value)

    if position == "0":
        return get_defcon_level()

    if str(position) not in VALID_LEVELS:
        fail_debug("config", "invalid selected level: " + str(position))

    return int(position)

def main(config):
    show_instructions = config.bool("instructions", False)
    if show_instructions:
        return display_instructions()

    position = get_selected_position(config)

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
    children = get_defcon_display(position)

    if animate:
        return render.Animation(children = children)

    return children[-1]

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
    if str(position) not in VALID_LEVELS:
        fail_debug("render", "invalid render position: " + str(position))

    children = []
    position = int(position)
    width = (canvas.width() // 5) - (1 if canvas.is2x() else 0)
    height = canvas.height() // 2

    grey_children = []
    for i in range(5):
        grey_children.append(render_box(i + 1, width, height, "#333"))

    grey_box = render.Row(
        expanded = True,
        main_align = "space_between",
        children = grey_children,
    )
    children.append(grey_box)

    color_box = grey_box
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

    for _ in range(3):
        children.append(grey_box)
        children.append(color_box)

    for _ in range(3):
        children.append(color_box)

    return children

def display_instructions():
    width = canvas.width()
    font = "terminus-16" if canvas.is2x() else "5x8"
    instructions_1 = "For security reasons, the U.S. military does not release the current DEFCON level. "
    instructions_2 = "The source for this app is defconlevel.com which uses Open Source Intelligence to estimate the DEFCON level. Default is to use the actual estimated DefCon level, but you can pick a level if you want. "
    instructions_3 = "Defcon level 5 is the lowest alert level. The highest level reached was level 2 during the Cuban Missile Crisis. This display is based on the movie War Games (1983)."
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
                icon = "play",
                default = True,
            ),
            schema.Toggle(
                id = "instructions",
                name = "Display Instructions",
                desc = "",
                icon = "book",
                default = False,
            ),
        ],
    )
