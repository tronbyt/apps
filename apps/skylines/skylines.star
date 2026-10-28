"""
Applet: Skylines
Summary: City Skylines
Description: Animated city skylines with outlined, fading city names.
Author: Robert Ison
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("skylines_data.star", "CITIES")
load("time.star", "time")

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

SCENE_HEIGHT = BASE_HEIGHT * SCALE

FRAME_DELAY_MS = 50
FADE_STEPS = 10
CACHE_TTL_SECONDS = 2592000

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

def is_square():
    w, h = canvas.size()
    return w == h

def center_on_square(child, width = None, height = None):
    if not is_square():
        return child

    if width != None and height != None:
        child = render.Box(
            width = width,
            height = height,
            child = child,
        )

    return render.Box(
        width = SCREEN_WIDTH,
        height = SCREEN_HEIGHT,
        child = child,
    )

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

def milliseconds_to_frames(milliseconds):
    return max(
        1,
        (milliseconds + FRAME_DELAY_MS // 2) // FRAME_DELAY_MS,
    )

def setting_ms(config, name, default):
    return max(
        0,
        int(config.get(name, str(default))),
    )

def create_dot(x, y, color = "#fff"):
    return add_padding_to_child_element(
        render.Box(
            width = SCALE,
            height = SCALE,
            color = color,
        ),
        left = x * SCALE,
        top = y * SCALE,
    )

def create_star(x, y, color):
    return add_padding_to_child_element(
        render.Box(
            width = 1,
            height = 1,
            color = color,
        ),
        left = x * SCALE,
        top = y * SCALE,
    )

def scene(layers):
    # Keep every frame the same size.
    return render.Stack(
        children = [
            render.Box(
                width = SCREEN_WIDTH,
                height = SCENE_HEIGHT,
            ),
        ] + layers,
    )

def start_from_top(y_top, y_bottom, current_pen_y):
    return (
        abs(current_pen_y - y_top) <=
        abs(current_pen_y - y_bottom)
    )

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
    if len(data) == 0 or len(data[0]) == 0:
        fail("Skyline dataset must contain nonempty rows.")

    width = len(data[0])

    for row in data:
        if len(row) != width:
            fail("All skyline dataset rows must have the same width.")

        for pixel in row:
            if pixel not in [0, 1, 2, 3]:
                fail("Skyline pixel values must be 0, 1, 2, or 3.")

def pseudo_shuffle(coords, seed):
    items = []

    for coordinate in coords:
        x, y = coordinate

        key = (
            (x * 73856093) ^
            (y * 19349663) ^
            (seed * 83492791)
        )

        key = (
            ((key ^ (key >> 13)) * 1274126177) %
            2147483647
        )

        key = key ^ (key >> 16)

        items.append((key, coordinate))

    return [item[1] for item in sorted(items)]

def pick_stars(coords, num_stars, seed = 0, min_spacing = 2):
    if num_stars <= 0:
        return []

    chosen = []

    for coordinate in pseudo_shuffle(coords, seed):
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

    for x in range(1, len(column_tops) - 1):
        top = column_tops[x]

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

def create_completed_frame(
        skyline_dots,
        star_locations,
        frame_idx):
    layers = list(skyline_dots)

    twinkle_colors = [
        "#526080",
        "#8A9ABB",
        "#CCD9FF",
        "#FFFFFF",
        "#FFECC2",
        "#8A9ABB",
        "#526080",
        None,
    ]

    for index in range(len(star_locations)):
        star = star_locations[index]

        frames_per_step = 14 + (index % 3) * 3

        phase = (
            (frame_idx // frames_per_step) +
            index * 3
        ) % len(twinkle_colors)

        color = twinkle_colors[phase]

        if color != None:
            layers.append(
                create_star(
                    star[0],
                    star[1],
                    color,
                ),
            )

    return scene(layers)

def draw_skyline(
        data,
        show_stars,
        colors,
        drawing_frames):
    validate_dataset(data)

    column_tops = []
    pixels = []

    width = len(data[0])
    height = len(data)

    current_pen_y = height

    for x in range(width):
        y_top, y_bottom = get_column_bounds(
            data,
            x,
            height,
        )

        column_tops.append(y_top)

        if y_top == None:
            continue

        if start_from_top(
            y_top,
            y_bottom,
            current_pen_y,
        ):
            rows = range(height)
        else:
            rows = reversed(range(height))

        for y in rows:
            value = data[y][x]

            if value > 0:
                pixels.append(
                    (x, y, colors[value - 1]),
                )

                current_pen_y = y

    dots = [
        create_dot(pixel[0], pixel[1], pixel[2])
        for pixel in pixels
    ]

    frames = [scene([])]

    # Preserve the tracing order while normalizing drawing time.
    for index in range(1, drawing_frames):
        count = (
            index * len(dots)
        ) // max(1, drawing_frames - 1)

        frames.append(
            scene(dots[:count]),
        )

    if show_stars:
        stars = get_star_locations(
            column_tops,
            height,
        )
    else:
        stars = []

    return (frames, dots, stars)

def color_with_opacity(color, opacity):
    digits = "0123456789abcdef"
    value = color[1:]

    if len(value) == 3 or len(value) == 4:
        value = (
            value[0] + value[0] +
            value[1] + value[1] +
            value[2] + value[2]
        )
    else:
        value = value[:6]

    opacity = max(0, min(255, opacity))

    return (
        "#" +
        value +
        digits[opacity // 16] +
        digits[opacity % 16]
    )

def text_style():
    if SCALE == 2:
        return ("terminus-16", 16)

    return ("5x8", 8)

def outlined_text(text, color, opacity):
    font, _ = text_style()

    layers = []

    for x, y in [(0, 1), (2, 1), (1, 0), (1, 2)]:
        layers.append(
            add_padding_to_child_element(
                render.Text(
                    text,
                    font = font,
                    color = color_with_opacity(
                        "#000",
                        opacity,
                    ),
                ),
                left = x,
                top = y,
            ),
        )

    layers.append(
        add_padding_to_child_element(
            render.Text(
                text,
                font = font,
                color = color_with_opacity(
                    color,
                    opacity,
                ),
            ),
            left = 1,
            top = 1,
        ),
    )

    return render.Stack(children = layers)

def outlined_text_size(text):
    font, _ = text_style()

    width, height = render.Text(
        text,
        font = font,
    ).size()

    return (width + 2, height + 2)

def create_text_overlay(
        text,
        color,
        opacity = 255,
        scroll_offset = 0):
    _, text_height = text_style()

    child = outlined_text(
        text,
        color,
        opacity,
    )

    width, _ = outlined_text_size(text)

    if width <= SCREEN_WIDTH:
        left = (SCREEN_WIDTH - width) // 2
    else:
        left = -scroll_offset

    return add_padding_to_child_element(
        child,
        left = left,
        top = max(
            0,
            SCENE_HEIGHT - text_height - 2,
        ),
    )

def get_safe_name(name):
    return (
        name.lower()
            .replace(" ", "_")
            .replace(".", "")
    )

def choose_city(config):
    if len(CITIES) == 0:
        fail("No cities were found in skylines_data.star.")

    available = []

    if config.get(
        "display_type",
        display_type[0].value,
    ) == "List":
        for city in CITIES:
            if config.bool(
                "city_" + get_safe_name(city["name"]),
                True,
            ):
                available.append(city)

    if len(available) == 0:
        available = list(CITIES)

    names = [city["name"] for city in available]

    # Keep a separate shuffle bag for each selected city set.
    key = "skylines_shuffle_v3:" + json.encode(names)

    raw = cache.get(key)

    if raw != None:
        state = json.decode(raw)
    else:
        state = {}

    remaining = [
        name
        for name in state.get("remaining", [])
        if name in names
    ]

    last = state.get("last", "")

    if len(remaining) == 0:
        remaining = list(names)

        for i in reversed(range(1, len(remaining))):
            j = randomize(0, i)

            remaining[i], remaining[j] = (
                remaining[j],
                remaining[i],
            )

        # Avoid repeating the last city across shuffle boundaries.
        if len(remaining) > 1 and remaining[0] == last:
            remaining[0], remaining[1] = (
                remaining[1],
                remaining[0],
            )

    selected_name = remaining[0]

    cache.set(
        key,
        json.encode({
            "remaining": remaining[1:],
            "last": selected_name,
        }),
        ttl_seconds = CACHE_TTL_SECONDS,
    )

    for city in available:
        if city["name"] == selected_name:
            return city

    return available[0]

def get_display_text(config, city_name):
    mode = config.get(
        "text_display",
        text_display_choices[0].value,
    )

    if mode == "City":
        return city_name

    if mode == "Custom":
        custom = (
            config.get("custom_text") or ""
        ).strip()

        if len(custom) > 0:
            return custom

        return city_name

    return ""

def append_hold(frames, dots, stars, count):
    for _ in range(count):
        frames.append(
            create_completed_frame(
                dots,
                stars,
                len(frames),
            ),
        )

def append_text_frame(
        frames,
        dots,
        stars,
        text,
        color,
        opacity,
        offset):
    background = create_completed_frame(
        dots,
        stars,
        len(frames),
    )

    frames.append(
        scene([
            background,
            create_text_overlay(
                text,
                color,
                opacity,
                offset,
            ),
        ]),
    )

def append_fade(
        frames,
        dots,
        stars,
        text,
        color,
        fade_ms,
        offset,
        fade_out = False):
    count = max(
        FADE_STEPS,
        milliseconds_to_frames(fade_ms),
    )

    for index in range(count):
        step = min(
            FADE_STEPS - 1,
            (index * FADE_STEPS) // count,
        )

        if fade_out:
            opacity = (
                (FADE_STEPS - 1 - step) * 255
            ) // FADE_STEPS
        else:
            opacity = (
                (step + 1) * 255
            ) // FADE_STEPS

        append_text_frame(
            frames,
            dots,
            stars,
            text,
            color,
            opacity,
            offset,
        )

def main(config):
    city = choose_city(config)

    skyline_color = config.get(
        "skyline_outline_color",
        DEFAULT_COLORS[0],
    )

    text_color = config.get(
        "text_color",
        DEFAULT_COLORS[3],
    )

    text = get_display_text(
        config,
        city["name"],
    )

    draw_ms = max(
        500,
        setting_ms(config, "drawing_ms", 4000),
    )

    before_ms = setting_ms(
        config,
        "skyline_hold_ms",
        1500,
    )

    text_ms = setting_ms(
        config,
        "text_hold_ms",
        3000,
    )

    fade_ms = setting_ms(
        config,
        "fade_ms",
        1000,
    )

    after_ms = setting_ms(
        config,
        "final_hold_ms",
        1500,
    )

    scroll_ms = max(
        20,
        setting_ms(config, "scroll_pixel_ms", 100),
    )

    frames, dots, stars = draw_skyline(
        city["dataset"],
        config.bool("stars", True),
        [
            skyline_color,
            DEFAULT_COLORS[1],
            DEFAULT_COLORS[2],
        ],
        max(
            2,
            milliseconds_to_frames(draw_ms),
        ),
    )

    if before_ms > 0:
        append_hold(
            frames,
            dots,
            stars,
            milliseconds_to_frames(before_ms),
        )

    if len(text) > 0:
        width, _ = outlined_text_size(text)

        distance = max(
            0,
            width - SCREEN_WIDTH,
        )

        if fade_ms > 0:
            append_fade(
                frames,
                dots,
                stars,
                text,
                text_color,
                fade_ms,
                0,
            )

        if distance == 0:
            for _ in range(
                milliseconds_to_frames(text_ms),
            ):
                append_text_frame(
                    frames,
                    dots,
                    stars,
                    text,
                    text_color,
                    255,
                    0,
                )
        else:
            # Pause at the start, pan to the end, then pause again.
            pause_frames = milliseconds_to_frames(
                max(750, text_ms // 2),
            )

            for _ in range(pause_frames):
                append_text_frame(
                    frames,
                    dots,
                    stars,
                    text,
                    text_color,
                    255,
                    0,
                )

            scroll_frames = milliseconds_to_frames(
                distance * scroll_ms,
            )

            for index in range(scroll_frames):
                offset = min(
                    distance,
                    ((index + 1) * distance) // scroll_frames,
                )

                append_text_frame(
                    frames,
                    dots,
                    stars,
                    text,
                    text_color,
                    255,
                    offset,
                )

            for _ in range(pause_frames):
                append_text_frame(
                    frames,
                    dots,
                    stars,
                    text,
                    text_color,
                    255,
                    distance,
                )

        if fade_ms > 0:
            append_fade(
                frames,
                dots,
                stars,
                text,
                text_color,
                fade_ms,
                distance,
                fade_out = True,
            )

    if after_ms > 0:
        append_hold(
            frames,
            dots,
            stars,
            milliseconds_to_frames(after_ms),
        )

    return render.Root(
        delay = FRAME_DELAY_MS,
        child = center_on_square(
            render.Animation(children = frames),
            SCREEN_WIDTH,
            SCENE_HEIGHT,
        ),
        show_full_animation = True,
    )

def get_city_options(display):
    if display != "List":
        return []

    return [
        schema.Toggle(
            id = "city_" + get_safe_name(city["name"]),
            name = city["name"],
            desc = city.get("description", ""),
            default = True,
            icon = "city",
        )
        for city in sorted(
            CITIES,
            key = lambda city: city["name"],
        )
    ]

def timing_dropdown(
        id,
        name,
        desc,
        values,
        default):
    return schema.Dropdown(
        id = id,
        name = name,
        desc = desc,
        icon = "clock",
        options = [
            schema.Option(
                display = label,
                value = str(value),
            )
            for label, value in values
        ],
        default = str(default),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            timing_dropdown(
                "drawing_ms",
                "Drawing Duration",
                "Same tracing duration for every city.",
                [
                    ("Quick - 2 seconds", 2000),
                    ("Classic - 4 seconds", 4000),
                    ("Relaxed - 6 seconds", 6000),
                    ("Slow - 8 seconds", 8000),
                ],
                4000,
            ),
            timing_dropdown(
                "skyline_hold_ms",
                "Skyline Hold",
                "Pause before the name appears.",
                [
                    ("0.5 seconds", 500),
                    ("1.5 seconds", 1500),
                    ("3 seconds", 3000),
                    ("5 seconds", 5000),
                ],
                1500,
            ),
            timing_dropdown(
                "text_hold_ms",
                "Name Hold",
                "Short names stay still; long names add scrolling time between two pauses.",
                [
                    ("2 seconds", 2000),
                    ("3 seconds", 3000),
                    ("5 seconds", 5000),
                    ("8 seconds", 8000),
                ],
                3000,
            ),
            timing_dropdown(
                "fade_ms",
                "Name Fade Duration",
                "Duration of each ten-step fade, in and out.",
                [
                    ("Instant", 0),
                    ("0.5 seconds", 500),
                    ("1 second", 1000),
                    ("1.5 seconds", 1500),
                    ("2 seconds", 2000),
                ],
                1000,
            ),
            timing_dropdown(
                "final_hold_ms",
                "Final Skyline Hold",
                "Pause after the name disappears.",
                [
                    ("None", 0),
                    ("0.5 seconds", 500),
                    ("1.5 seconds", 1500),
                    ("3 seconds", 3000),
                ],
                1500,
            ),
            timing_dropdown(
                "scroll_pixel_ms",
                "Long Name Scroll Speed",
                "Scrolling speed does not affect tracing or hold times.",
                [
                    ("Fast - 50 ms per pixel", 50),
                    ("Medium - 100 ms per pixel", 100),
                    ("Slow - 150 ms per pixel", 150),
                ],
                100,
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
                desc = "Shuffle all cities or only selected cities.",
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
