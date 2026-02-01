"""
Applet: Skylines
Summary: City Skylines
Description: Displays city skylines.
Author: Robert Ison
"""

load("render.star", "canvas", "render")
load("schema.star", "schema")
load("skylines_data.star", "CITIES")
load("time.star", "time")

SCREEN_WIDTH = canvas.width()
SCREEN_HEIGHT = canvas.height()

BASE_WIDTH = 64
BASE_HEIGHT = 32

SCALE = SCREEN_HEIGHT // BASE_HEIGHT

DEFAULT_COLORS = ["#fff", "#f00", "#00A550", "#0057B7", "#CCD9FF", "#FFECC2"]  #1 Skyline, 2 Red Dots, 3 Green Trees, 4 Text Color, 5 Star color, 6 alt star color
NUMBER_OF_STARS = 5

display_type = [
    schema.Option(display = "Display a Random City", value = "Random"),
    schema.Option(display = "Select a City", value = "Pick"),
]

text_display_choices = [
    schema.Option(display = "Display City Name", value = "City"),
    schema.Option(display = "Display No Text", value = "Nothing"),
    schema.Option(display = "Display Custom Text", value = "Custom"),
]

def randomize(min, max):
    now = time.now()
    base = now.unix * 1000000000 + now.nanosecond
    rand = ((base ^ (base >> 11)) % 1000) / 1000.0
    return int(rand * (max + 1 - min) + min)

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )

    return padded_element

def create_dot(x, y, color = "#fff"):
    return render.Padding(
        pad = (x * SCALE, y * SCALE, 0, 0),
        child = render.Box(
            width = SCALE,
            height = SCALE,
            color = color,
        ),
    )

def start_from_top(y_top, y_bottom, current_pen_y):
    """
    Returns true if the next pass should start from the top, otherwise false

    y_top: What is the y value of the top pixel to be painted in this column
    y_bottom: What is the y value of the bottom pixel to be painted in this column
    current_pen_y: What y value did we leave off painting the last column

    returns true or false where true means you should paint from the top
    """

    # Distance if we start from the top
    dist_to_top = abs(current_pen_y - y_top)

    # Distance if we start from the bottom
    dist_to_bottom = abs(current_pen_y - y_bottom)

    # Choose whichever is closer to where the pen already is
    if dist_to_top <= dist_to_bottom:
        return True
    else:
        return False

def get_column_bounds(screen, x, height):
    """
    screen: 2D array [y][x] of pixels (1 = building, 0 = empty sky)
    x: current column
    height: total screen height (32 for your case)

    returns (y_top, y_bottom) for this column
    """
    y_top = 0
    y_bottom = 0

    for y in range(height):
        if screen[y][x] > 0:  # hit building
            if y_top == 0:
                y_top = y  # first building pixel
            y_bottom = y  # keep updating until last pixel

    return (y_top, y_bottom)

def draw_skyline(data, show_stars, colors):
    animation_frames = []
    stacked_dots = []
    width = len(data[0])
    height = len(data)
    current_pen_y = height
    pixels = []
    visible_sky = []

    for x in range(width):
        #to determine if the line should be written from the top or bottom,
        #it depends on where we left off last time, and if we're closer to the top or bottom

        bounds = get_column_bounds(data, x, height)

        # keep track of pixels of sky for each column with a 3 pixel buffer
        visible_sky.append(bounds[0] - 3)

        if start_from_top(bounds[0], bounds[1], current_pen_y):
            for y in range(height):
                if data[y][x] > 0:
                    pixels.append((x, y, colors[data[y][x] - 1]))
                    current_pen_y = y
        else:
            for y in reversed(range(height)):
                if data[y][x] > 0:
                    pixels.append((x, y, colors[data[y][x] - 1]))
                    current_pen_y = y

    for pixel in pixels:
        x, y, color = pixel
        stacked_dots.append(create_dot(x, y, color))
        animation_frames.append(render.Stack(children = stacked_dots))

    # add stars
    if show_stars:
        potential_star_locations = []
        for i in range(len(visible_sky)):
            if (i > 0 and i < len(visible_sky) - 1):
                # let's avoid putting a star right on a building, it's a design choice, not based on reality, but dots aren't exactly clear enough to distinguish a star from part of a building

                if (visible_sky[i - 1] >= visible_sky[i] and visible_sky[i + 1] >= visible_sky[i]):
                    potential_star_locations.append((i, randomize(0, visible_sky[i] - 1)))

        potential_star_location = pick_stars(potential_star_locations, NUMBER_OF_STARS, randomize(0, 1000), 4 * SCALE)

        for star in potential_star_location:
            color_number = 4 if star[0] % 2 else 5
            stacked_dots.append(create_dot(star[0], star[1], DEFAULT_COLORS[color_number]))
            animation_frames.append(render.Stack(children = stacked_dots))

    # Add some Frames to hold the finished product
    for _ in range(40):
        animation_frames.append(render.Stack(children = stacked_dots))

    return animation_frames

# Pseudo-shuffle: compute a deterministic "random" key from x,y and seed,
# attach as (key, coord), sort by key, and return coords in that order.
def pseudo_shuffle(coords, seed):
    items = []
    for c in coords:
        x = c[0]
        y = c[1]

        # mixing constants are large primes — just a simple integer hash mixer
        key = (x * 73856093 + y * 19349663 + seed * 83492791) % 1000000007
        items.append((key, c))
    items = sorted(items)  # sorts by key (first tuple element)
    out = []
    for it in items:
        out.append(it[1])
    return out

# Choose up to num_stars from potential coords (already shuffled by pseudo_shuffle),
# enforcing a minimum spacing (chebyshev / box distance) so stars spread out.
def pick_stars(coords, num_stars, seed = 0, min_spacing = 2):
    shuffled = pseudo_shuffle(coords, seed)
    chosen = []
    for c in shuffled:
        ok = True
        for ch in chosen:
            # use absolute distance on x and y
            if abs(c[0] - ch[0]) < min_spacing and abs(c[1] - ch[1]) < min_spacing:
                ok = False
                break
        if ok:
            chosen.append(c)
            if len(chosen) >= num_stars:
                break
    return chosen

def main(config):
    CITIES_BY_NAME = {city["name"]: city for city in CITIES}
    city_names = CITIES_BY_NAME.keys()

    #configuration settings
    skyline_color = config.get("skyline_outline_color", DEFAULT_COLORS[0])
    display = config.get("display_type", display_type[0].value)
    custom_text = config.get("custom_text")
    text_display = config.get("text_display", text_display_choices[0].value)
    text_color = config.get("text_color", DEFAULT_COLORS[3])

    selected_city_dataset = None  #Cheap default
    selected_city = None  #Cheap default

    if (display == display_type[0].value):
        selected_city = city_names[randomize(0, len(city_names) - 1)]
        selected_city_dataset = CITIES_BY_NAME[selected_city]["dataset"]
    else:
        selected_city = config.get("city", city_names[1])
        selected_city_dataset = CITIES_BY_NAME[selected_city]["dataset"]

    text_to_display = ""
    if (text_display == "City"):
        text_to_display = selected_city
    elif (text_display == "Custom"):
        if (custom_text != None and len(custom_text) > 0):
            text_to_display = custom_text.strip()
        else:
            text_to_display = selected_city

    show_stars = config.bool("stars", True)
    animation_frames = draw_skyline(selected_city_dataset, show_stars, [skyline_color, DEFAULT_COLORS[1], DEFAULT_COLORS[2]])

    if (len(text_to_display) > 0):
        if SCALE == 2:
            font = "terminus-16"
        else:
            font = "5x8"

        text_w = 5 * len(text_to_display) * SCALE
        text_h = 8 * SCALE

        final_frame_plus_text = render.Stack(
            children = [
                animation_frames[len(animation_frames) - 1],
                add_padding_to_child_element(
                    render.Box(width = text_w, height = text_h, color = "#000"),
                    SCREEN_WIDTH - text_w,
                    SCREEN_HEIGHT - text_h,
                ),
                add_padding_to_child_element(
                    render.Marquee(
                        width = BASE_WIDTH * SCALE,
                        child = render.Text(text_to_display, font = font, color = text_color),
                    ),
                    SCREEN_WIDTH - text_w,
                    SCREEN_HEIGHT - text_h,
                ),
            ],
        )

        for _ in range(80):
            animation_frames.append(final_frame_plus_text)
    else:
        # we were going to hold the text for 60 frames, but we skipped the text display, so let's just add 60 frames of the last frame from before
        for _ in range(80):
            animation_frames.append(animation_frames[len(animation_frames) - 1])

    return render.Root(
        delay = int(config.get("scroll", 45)),
        child = render.Stack(
            children =
                [
                    render.Animation(children = animation_frames),
                ],
        ),
        show_full_animation = True,
    )

def get_city_options(type):
    display_data = sorted(CITIES, key = lambda m: m["name"], reverse = False)

    # Loop through each item and print the values
    if (type == "Pick"):
        choice_cities = []

        for city in display_data:
            choice_cities.append(schema.Option(display = "%s - %s" % (city["name"], city["description"]), value = city["name"]))

        return [
            schema.Dropdown(
                id = "city",
                name = "City",
                desc = "Select City to Display",
                icon = "city",
                options = choice_cities,
                default = choice_cities[0].value,
            ),
        ]
    else:
        return []

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
                desc = "Speed of the drawing",
                icon = "clock",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
            schema.Toggle(
                id = "stars",
                name = "Display Stars",
                desc = "Do you want stars to appear on the screen?",
                icon = "star",
                default = True,
            ),
            schema.Color(
                id = "skyline_outline_color",
                name = "Skyline",
                desc = "Skyline Color",
                icon = "brush",
                default = DEFAULT_COLORS[0],
            ),
            schema.Color(
                id = "text_color",
                name = "Text",
                desc = "Text Color",
                icon = "brush",
                default = DEFAULT_COLORS[3],
            ),
            schema.Dropdown(
                id = "text_display",
                icon = "tv",
                name = "Text Overlay",
                desc = "What text do you want to display?",
                options = text_display_choices,
                default = text_display_choices[0].value,
            ),
            schema.Text(
                id = "custom_text",
                name = "Custom Text",
                desc = "Text you want to appear over the skyline.",
                icon = "pencil",
            ),
            schema.Dropdown(
                id = "display_type",
                icon = "tv",
                name = "What to display",
                desc = "What do you want this to display?",
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
