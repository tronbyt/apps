"""
Applet: Skylines
Summary: City Skylines
Description: Displays animated city skylines with optional stars and text.
Author: Robert Ison
"""

load("render.star", "canvas", "render")
load("schema.star", "schema")
load("skylines_data.star", "CITIES")
load("time.star", "time")

def is_square():
    """True on a 64x64 panel.

    Panels are told apart by SHAPE, never by size: the 128x64 wide panel is
    also 64 tall.
    """
    w, h = canvas.size()
    return h == w

def center_on_square(child, width = None, height = None):
    """Centre `child` on the square (64x64); other panels get it unchanged.

    A scene hand-laid for 64x32 passes its size so the Box that centres it
    has the scene's bounds rather than the panel's.
    """
    if not is_square():
        return child
    if width != None and height != None:
        child = render.Box(width = width, height = height, child = child)
    return render.Box(width = canvas.width(), height = canvas.height(), child = child)

SCREEN_WIDTH = canvas.width()
SCREEN_HEIGHT = canvas.height()

BASE_WIDTH = 64
BASE_HEIGHT = 32

SCALE = max(
    1,
    min(
        SCREEN_WIDTH // BASE_WIDTH,
        SCREEN_HEIGHT // BASE_HEIGHT,
    ),
)

# Skyline, red details, green details, text, star, alternate star.
DEFAULT_COLORS = [
    "#fff",
    "#f00",
    "#00A550",
    "#0057B7",
    "#CCD9FF",
    "#FFECC2",
]

NUMBER_OF_STARS = 5
STAR_MIN_SPACING = 4
STAR_CLEARANCE = 3
TWINKLE_FRAME_SPACING = 12

SKYLINE_HOLD_FRAMES = 100
TEXT_HOLD_FRAMES = 80

DEFAULT_FRAME_DELAY = 70

display_type = [
    schema.Option(
        display = "Display a Random City",
        value = "Random",
    ),
    schema.Option(
        display = "Pick from Selected",
        value = "List",
    ),
]

text_display_choices = [
    schema.Option(
        display = "Display City Name",
        value = "City",
    ),
    schema.Option(
        display = "Display No Text",
        value = "Nothing",
    ),
    schema.Option(
        display = "Display Custom Text",
        value = "Custom",
    ),
]

def randomize(minimum, maximum):
    if maximum <= minimum:
        return minimum

    now = time.now()
    value = (
        now.unix * 1000000000 +
        now.nanosecond +
        SCREEN_WIDTH * SCREEN_HEIGHT
    )

    value = value ^ (value >> 11)
    value = (value * 48271) % 2147483647
    value = value ^ (value >> 13)

    return minimum + value % (maximum - minimum + 1)

def add_padding_to_child_element(
        element,
        left = 0,
        top = 0,
        right = 0,
        bottom = 0):
    return render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )

def create_dot(x, y, color = "#fff"):
    return render.Padding(
        pad = (x * SCALE, y * SCALE, 0, 0),
        child = render.Box(
            width = SCALE,
            height = SCALE,
            color = color,
        ),
    )

def create_star(x, y, color):
    return render.Padding(
        pad = (x * SCALE, y * SCALE, 0, 0),
        child = render.Box(
            width = 1,
            height = 1,
            color = color,
        ),
    )

def start_from_top(y_top, y_bottom, current_pen_y):
    distance_to_top = abs(current_pen_y - y_top)
    distance_to_bottom = abs(current_pen_y - y_bottom)

    return distance_to_top <= distance_to_bottom

def get_column_bounds(screen, x, height):
    y_top = None
    y_bottom = None

    for y in range(height):
        if screen[y][x] > 0:
            if y_top == None:
                y_top = y

            y_bottom = y

    return (y_top, y_bottom)

def validate_dataset(data):
    if len(data) == 0:
        fail("Skyline dataset must contain at least one row.")

    width = len(data[0])

    if width == 0:
        fail("Skyline dataset rows must not be empty.")

    for row in data:
        if len(row) != width:
            fail("All skyline dataset rows must have the same width.")

        for pixel in row:
            if pixel not in [0, 1, 2, 3]:
                fail("Skyline pixel values must be 0, 1, 2, or 3.")

def pseudo_shuffle(coords, seed):
    items = []

    for coordinate in coords:
        x = coordinate[0]
        y = coordinate[1]

        key = (
            x * 73856093
        ) ^ (
            y * 19349663
        ) ^ (
            seed * 83492791
        )

        key = ((key ^ (key >> 13)) * 1274126177) % 2147483647
        key = key ^ (key >> 16)

        items.append((key, coordinate))

    items = sorted(items)

    return [item[1] for item in items]

def pick_stars(coords, num_stars, seed = 0, min_spacing = 2):
    if num_stars <= 0:
        return []

    shuffled = pseudo_shuffle(coords, seed)
    chosen = []

    for coordinate in shuffled:
        acceptable = True

        for other in chosen:
            if (
                abs(coordinate[0] - other[0]) < min_spacing and
                abs(coordinate[1] - other[1]) < min_spacing
            ):
                acceptable = False
                break

        if acceptable:
            chosen.append(coordinate)

            if len(chosen) >= num_stars:
                break

    return chosen

def get_star_locations(column_tops, height):
    candidates = []

    # Leave a one-column margin at each side.
    for x in range(1, len(column_tops) - 1):
        top = column_tops[x]

        # Empty columns have open sky down to the bottom margin.
        if top == None:
            maximum_y = height - 1 - STAR_CLEARANCE
        else:
            maximum_y = top - 1 - STAR_CLEARANCE

        if maximum_y >= 0:
            candidates.append(
                (x, randomize(0, maximum_y)),
            )

    return pick_stars(
        candidates,
        NUMBER_OF_STARS,
        randomize(0, 2147483646),
        STAR_MIN_SPACING,
    )

def create_completed_frame(skyline_dots, star_locations, frame_idx):
    layers = list(skyline_dots)

    twinkle_colors = [
        "#526080",  # Dim blue
        "#8A9ABB",  # Medium blue
        "#CCD9FF",  # Bright cool white
        "#FFFFFF",  # Peak brightness
        "#FFECC2",  # Warm white
        "#8A9ABB",  # Fade down
        "#526080",  # Dim blue
        None,  # Briefly off
    ]

    for index in range(len(star_locations)):
        star = star_locations[index]

        # Different speeds and offsets keep stars out of sync.
        frames_per_step = 10 + (index % 3) * 2
        phase = (
            (frame_idx // frames_per_step) +
            index * 3
        ) % len(twinkle_colors)

        color = twinkle_colors[phase]

        if color != None:
            layers.append(
                create_star(star[0], star[1], color),
            )

    return render.Stack(children = layers)

def draw_skyline(data, show_stars, colors):
    validate_dataset(data)

    animation_frames = []
    skyline_dots = []
    column_tops = []
    pixels = []

    width = len(data[0])
    height = len(data)
    current_pen_y = height

    for x in range(width):
        bounds = get_column_bounds(data, x, height)

        y_top = bounds[0]
        y_bottom = bounds[1]

        column_tops.append(y_top)

        if y_top == None:
            continue

        if start_from_top(y_top, y_bottom, current_pen_y):
            rows = range(height)
        else:
            rows = reversed(range(height))

        for y in rows:
            pixel_value = data[y][x]

            if pixel_value > 0:
                pixels.append(
                    (x, y, colors[pixel_value - 1]),
                )
                current_pen_y = y

    for pixel in pixels:
        skyline_dots.append(
            create_dot(pixel[0], pixel[1], pixel[2]),
        )

        animation_frames.append(
            render.Stack(children = list(skyline_dots)),
        )

    star_locations = []

    if show_stars:
        star_locations = get_star_locations(column_tops, height)

    return (animation_frames, skyline_dots, star_locations)

def create_text_overlay(text, color):
    if SCALE == 2:
        font = "terminus-16"
        text_height = 16
    else:
        font = "5x8"
        text_height = 8

    text_y = max(0, SCREEN_HEIGHT - text_height)

    return render.Stack(
        children = [
            add_padding_to_child_element(
                render.Box(
                    width = SCREEN_WIDTH,
                    height = text_height,
                    color = "#000",
                ),
                top = text_y,
            ),
            add_padding_to_child_element(
                render.Marquee(
                    width = SCREEN_WIDTH,
                    child = render.Text(
                        text,
                        font = font,
                        color = color,
                    ),
                ),
                top = text_y,
            ),
        ],
    )

def get_safe_name(name):
    return name.lower().replace(" ", "_").replace(".", "")

def choose_city(config):
    if len(CITIES) == 0:
        fail("No cities were found in skylines_data.star.")

    display = config.get("display_type", display_type[0].value)
    available_cities = []

    if display == "List":
        for city in CITIES:
            safe_name = get_safe_name(city["name"])

            if config.bool("city_" + safe_name, True):
                available_cities.append(city)

    # Random mode, or fallback when every city is deselected.
    if len(available_cities) == 0:
        available_cities = list(CITIES)

    return available_cities[randomize(0, len(available_cities) - 1)]

def get_display_text(config, city_name):
    text_display = config.get(
        "text_display",
        text_display_choices[0].value,
    )

    if text_display == "City":
        return city_name

    if text_display == "Custom":
        custom_text = (config.get("custom_text") or "").strip()

        if len(custom_text) > 0:
            return custom_text

        return city_name

    return ""

def main(config):
    selected_city = choose_city(config)

    skyline_color = config.get(
        "skyline_outline_color",
        DEFAULT_COLORS[0],
    )

    text_color = config.get(
        "text_color",
        DEFAULT_COLORS[3],
    )

    show_stars = config.bool("stars", True)

    text_to_display = get_display_text(
        config,
        selected_city["name"],
    )

    drawing = draw_skyline(
        selected_city["dataset"],
        show_stars,
        [
            skyline_color,
            DEFAULT_COLORS[1],
            DEFAULT_COLORS[2],
        ],
    )

    animation_frames = drawing[0]
    skyline_dots = drawing[1]
    star_locations = drawing[2]

    text_overlay = None

    if len(text_to_display) > 0:
        text_overlay = create_text_overlay(
            text_to_display,
            text_color,
        )

    total_hold_frames = SKYLINE_HOLD_FRAMES + TEXT_HOLD_FRAMES

    for frame_idx in range(total_hold_frames):
        completed_frame = create_completed_frame(
            skyline_dots,
            star_locations,
            frame_idx,
        )

        if (
            frame_idx >= SKYLINE_HOLD_FRAMES and
            text_overlay != None
        ):
            completed_frame = render.Stack(
                children = [
                    completed_frame,
                    text_overlay,
                ],
            )

        animation_frames.append(completed_frame)

    return render.Root(
        delay = int(config.get("scroll", DEFAULT_FRAME_DELAY)),
        child = center_on_square(render.Stack(
            children = [
                render.Animation(children = animation_frames),
            ],
        ), BASE_WIDTH * SCALE, BASE_HEIGHT * SCALE),
        show_full_animation = True,
    )

def get_city_options(display):
    display_data = sorted(
        CITIES,
        key = lambda city: city["name"],
    )

    if display != "List":
        return []

    city_checkboxes = []

    for city in display_data:
        safe_name = get_safe_name(city["name"])

        city_checkboxes.append(
            schema.Toggle(
                id = "city_" + safe_name,
                name = city["name"],
                desc = city.get("description", ""),
                default = True,
                icon = "city",
            ),
        )

    return city_checkboxes

def get_schema():
    scroll_speed_options = [
        schema.Option(
            display = "Slow Scroll",
            value = "70",
        ),
        schema.Option(
            display = "Medium Scroll",
            value = "45",
        ),
        schema.Option(
            display = "Fast Scroll",
            value = "20",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "scroll",
                name = "Speed",
                desc = "Speed of the drawing and animation.",
                icon = "clock",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
            schema.Toggle(
                id = "stars",
                name = "Display Stars",
                desc = "Show twinkling stars above the skyline.",
                icon = "star",
                default = True,
            ),
            schema.Color(
                id = "skyline_outline_color",
                name = "Skyline",
                desc = "Skyline color.",
                icon = "brush",
                default = DEFAULT_COLORS[0],
            ),
            schema.Color(
                id = "text_color",
                name = "Text",
                desc = "Text color.",
                icon = "brush",
                default = DEFAULT_COLORS[3],
            ),
            schema.Dropdown(
                id = "text_display",
                icon = "tv",
                name = "Text Overlay",
                desc = "Choose the text displayed over the skyline.",
                options = text_display_choices,
                default = text_display_choices[0].value,
            ),
            schema.Text(
                id = "custom_text",
                name = "Custom Text",
                desc = "Text to display instead of the city name.",
                icon = "pencil",
            ),
            schema.Dropdown(
                id = "display_type",
                icon = "tv",
                name = "What to display",
                desc = "Choose from all cities or selected cities.",
                options = display_type,
                default = display_type[0].value,
            ),
            schema.Generated(
                id = "generated",
                source = "display_type",
                handler = get_city_options,
            ),
        ],
    )
