"""
Applet: DefCon
Summary: Displays the estimated DEFCON status
Description: Displays the unofficial estimated DEFCON (Defense Condition) alert level for the U.S. from DefConLevel.com, or a manually selected level.
Author: Robert Ison
"""

load("html.star", "html")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")

DEF_CON_URL = "https://www.defconlevel.com/current-level"
CACHE_TTL_SECONDS = 12 * 60 * 60
DEFAULT_LEVEL = "0"

IS_2X = canvas.is2x()
SCALE = 2 if IS_2X else 1
FONT = "terminus-32-light" if IS_2X else "6x13"
INSTRUCTIONS_FONT = "terminus-16" if IS_2X else "5x8"

DEF_CON_COLORS = ["#fff", "#ff0000", "#ffff00", "#00ff00", "#0000ff"]
VALID_LEVELS = ["1", "2", "3", "4", "5"]

display_options = [
    schema.Option(value = "5", display = "DEFCON 5 - Normal Readiness"),
    schema.Option(value = "4", display = "DEFCON 4 - Above Normal Readiness"),
    schema.Option(value = "3", display = "DEFCON 3 - High Caution"),
    schema.Option(value = "2", display = "DEFCON 2 - Risk of Impending Attack"),
    schema.Option(value = "1", display = "DEFCON 1 - Maximum Readiness"),
    schema.Option(value = "0", display = "Automatic - Website Estimate"),
]

def fail_debug(step, message):
    fail("DEFCON app error [" + step + "]: " + message)

def normalize_level_text(text):
    if text == None:
        fail_debug("parse", "badge text was empty")

    original = str(text)
    normalized = " ".join(original.upper().split())

    if normalized == "":
        fail_debug("parse", "badge text was blank")

    if normalized.startswith("DEFCON "):
        normalized = normalized[len("DEFCON "):].strip()

    if normalized not in VALID_LEVELS:
        fail_debug("parse", "unexpected badge text: " + original)

    return int(normalized)

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
        fail_debug(
            "http",
            "GET " + DEF_CON_URL + " returned status " + str(res.status_code),
        )

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

    return normalize_level_text(badge.text())

def get_selected_level(config):
    level = str(config.get("list", DEFAULT_LEVEL)).strip()

    if level == "0":
        return get_defcon_level()

    if level not in VALID_LEVELS:
        fail_debug("config", "invalid selected level: " + level)

    return int(level)

def main(config):
    if config.bool("instructions", False):
        return display_instructions()

    level = get_selected_level(config)

    width, height = canvas.size()
    defcon_height = height // 2 - SCALE

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
                        child = render.Text(
                            "DEFCON",
                            color = "#fff",
                            font = FONT,
                        ),
                    ),
                ),
                render_defcon_display(
                    config.bool("animate", True),
                    level,
                ),
            ],
        ),
    )

def render_defcon_display(animate, level):
    if str(level) not in VALID_LEVELS:
        fail_debug("render", "invalid render level: " + str(level))

    level = int(level)
    width = (canvas.width() // 5) - (1 if IS_2X else 0)
    height = canvas.height() // 2

    # Static mode builds only the five boxes it needs.
    if not animate:
        return render_defcon_row(level, width, height)

    return render.Animation(
        children = get_defcon_animation(level, width, height),
    )

def render_box(level, width, height, color):
    return render.Box(
        width = width,
        height = height,
        color = color,
        child = render.Box(
            width = width - 2 * SCALE,
            height = height - 2 * SCALE,
            color = "#000",
            child = render.Padding(
                pad = (0 if IS_2X else 1, 0, 0, 0),
                child = render.Text(
                    str(level),
                    color = color,
                    font = FONT,
                ),
            ),
        ),
    )

def render_defcon_row(level, width, height, grey_boxes = None):
    boxes = []

    for i in range(5):
        if i + 1 == level:
            boxes.append(
                render_box(i + 1, width, height, DEF_CON_COLORS[i]),
            )
        elif grey_boxes != None:
            boxes.append(grey_boxes[i])
        else:
            boxes.append(
                render_box(i + 1, width, height, "#333"),
            )

    return render.Row(
        expanded = True,
        main_align = "space_between",
        children = boxes,
    )

def get_defcon_animation(level, width, height):
    grey_boxes = [
        render_box(i + 1, width, height, "#333")
        for i in range(5)
    ]

    grey_row = render.Row(
        expanded = True,
        main_align = "space_between",
        children = grey_boxes,
    )

    frames = [grey_row]
    selected_row = None

    # Highlight one level at a time, from 5 to the selected level.
    for current_level in range(5, level - 1, -1):
        selected_row = render_defcon_row(
            current_level,
            width,
            height,
            grey_boxes,
        )
        frames.append(selected_row)

    # Blink the selected level three times.
    for _ in range(3):
        frames.append(grey_row)
        frames.append(selected_row)

    # Hold the selected level.
    for _ in range(3):
        frames.append(selected_row)

    return frames

def display_instructions():
    width = canvas.width()

    instructions_1 = (
        "This app does not display an official U.S. military DEFCON level. "
    )
    instructions_2 = (
        "The source is defconlevel.com, which uses open-source intelligence " +
        "to estimate the DEFCON level. Automatic mode is the default, " +
        "and the website response is cached for 12 hours. " +
        "You can also select a level manually. "
    )
    instructions_3 = (
        "DEFCON 5 is the lowest alert level; DEFCON 1 is the highest. " +
        "This display is based on the movie WarGames (1983)."
    )

    text_1 = render.Text(
        instructions_1,
        color = DEF_CON_COLORS[1],
        font = INSTRUCTIONS_FONT,
    )
    text_2 = render.Text(
        instructions_2,
        color = DEF_CON_COLORS[2],
        font = INSTRUCTIONS_FONT,
    )
    text_3 = render.Text(
        instructions_3,
        color = DEF_CON_COLORS[3],
        font = INSTRUCTIONS_FONT,
    )

    text_1_width, _ = text_1.size()
    text_2_width, _ = text_2.size()

    return render.Root(
        child = render.Column(
            children = [
                render.Marquee(
                    width = width,
                    child = render.Text(
                        "DEFCON",
                        color = DEF_CON_COLORS[0],
                        font = INSTRUCTIONS_FONT,
                    ),
                ),
                render.Marquee(
                    width = width,
                    child = text_1,
                ),
                render.Marquee(
                    offset_start = text_1_width,
                    width = width,
                    child = text_2,
                ),
                render.Marquee(
                    offset_start = text_1_width + text_2_width,
                    width = width,
                    child = text_3,
                ),
            ],
        ),
        show_full_animation = True,
        delay = 25 if IS_2X else 45,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "list",
                name = "DEFCON Level",
                desc = "Use the website estimate or select a level manually.",
                icon = "list",
                default = DEFAULT_LEVEL,
                options = display_options,
            ),
            schema.Toggle(
                id = "animate",
                name = "Animate Display",
                desc = (
                    "Count down from DEFCON 5 to the selected level " +
                    "and blink, or show a static display."
                ),
                icon = "play",
                default = True,
            ),
            schema.Toggle(
                id = "instructions",
                name = "Display Instructions",
                desc = "Show information about the source and display.",
                icon = "book",
                default = False,
            ),
        ],
    )
