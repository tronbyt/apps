"""
Applet: Transitions
Summary: Add cool transition effects
Description: Useful for transitions between apps or notifications.
Author: Brombomb
"""

load("math.star", "math")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")

EFFECT_HORIZONTAL = "horizontal_wipe"
EFFECT_VERTICAL = "vertical_wipe"
EFFECT_DIAGONAL = "diagonal_wipe"
EFFECT_CHECKER = "diagonal_checker"
EFFECT_PIXEL_FLOOD = "pixel_flood"
EFFECT_SCATTER = "pixel_scatter"
EFFECT_BLINK = "blink"
EFFECT_STAR = "star_burst"
EFFECT_DOOM = "doom_wipe"
EFFECT_FADE = "fade"
EFFECT_CYLON = "cylon_eye"
EFFECT_RANDOM_PICK = "random"

DEFAULT_EFFECT = "random"
DEFAULT_DIRECTION = "ltr"
DEFAULT_PRIMARY = "#4af2a1"
DEFAULT_SECONDARY = "#050505"

ALL_EFFECTS = [
    EFFECT_HORIZONTAL,
    EFFECT_VERTICAL,
    EFFECT_DIAGONAL,
    EFFECT_CHECKER,
    EFFECT_PIXEL_FLOOD,
    EFFECT_SCATTER,
    EFFECT_BLINK,
    EFFECT_STAR,
    EFFECT_DOOM,
    EFFECT_FADE,
    EFFECT_CYLON,
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "effect",
                name = "Effect",
                desc = "Pick the transition or notifier to play.",
                icon = "wandMagicSparkles",
                default = DEFAULT_EFFECT,
                options = [
                    schema.Option(display = "Random", value = EFFECT_RANDOM_PICK),
                    schema.Option(display = "Blinking Color", value = EFFECT_BLINK),
                    schema.Option(display = "Cylon Eye", value = EFFECT_CYLON),
                    schema.Option(display = "Diagonal Checker", value = EFFECT_CHECKER),
                    schema.Option(display = "Diagonal Wipe", value = EFFECT_DIAGONAL),
                    schema.Option(display = "Doom Wipe", value = EFFECT_DOOM),
                    schema.Option(display = "Fade", value = EFFECT_FADE),
                    schema.Option(display = "Horizontal Wipe", value = EFFECT_HORIZONTAL),
                    schema.Option(display = "Pixel Flood", value = EFFECT_PIXEL_FLOOD),
                    schema.Option(display = "Pixel Scatter", value = EFFECT_SCATTER),
                    schema.Option(display = "Star Burst", value = EFFECT_STAR),
                    schema.Option(display = "Vertical Wipe", value = EFFECT_VERTICAL),
                ],
            ),
            schema.Dropdown(
                id = "direction",
                name = "Direction",
                desc = "Used by wipes to decide which way the fill moves.",
                icon = "arrowsLeftRight",
                default = DEFAULT_DIRECTION,
                options = [
                    schema.Option(display = "Left to Right", value = "ltr"),
                    schema.Option(display = "Right to Left", value = "rtl"),
                    schema.Option(display = "Top to Bottom", value = "ttb"),
                    schema.Option(display = "Bottom to Top", value = "btt"),
                    schema.Option(display = "Top-Left to Bottom-Right", value = "tlbr"),
                    schema.Option(display = "Bottom-Right to Top-Left", value = "brtl"),
                ],
            ),
            schema.Color(
                id = "primary_color",
                name = "Primary Color",
                desc = "Foreground color used in the transition.",
                icon = "palette",
                default = DEFAULT_PRIMARY,
            ),
            schema.Color(
                id = "secondary_color",
                name = "Secondary Color",
                desc = "Background color before the transition completes.",
                icon = "paintRoller",
                default = DEFAULT_SECONDARY,
            ),
        ],
    )

def main(config):
    effect = config.get("effect", DEFAULT_EFFECT)
    direction = config.get("direction", DEFAULT_DIRECTION)
    primary_color = config.get("primary_color", DEFAULT_PRIMARY)
    secondary_color = config.get("secondary_color", DEFAULT_SECONDARY)

    chosen_effect = effect
    chosen_direction = direction
    if effect == EFFECT_RANDOM_PICK:
        chosen_effect = ALL_EFFECTS[random.number(0, len(ALL_EFFECTS) - 1)]
        dir_options = ["ltr", "rtl", "ttb", "btt", "tlbr", "brtl"]
        chosen_direction = dir_options[random.number(0, len(dir_options) - 1)]

    frames = []
    delay = 100

    if chosen_effect == EFFECT_BLINK:
        frames = blink_frames(primary_color, secondary_color)
        delay = 180
    elif chosen_effect == EFFECT_VERTICAL:
        vertical_direction = chosen_direction if chosen_direction == "btt" else "ttb"
        frames = vertical_wipe_frames(primary_color, secondary_color, vertical_direction)
        delay = 80
    elif chosen_effect == EFFECT_DIAGONAL:
        diagonal_direction = chosen_direction if chosen_direction == "brtl" else "tlbr"
        frames = diagonal_wipe_frames(primary_color, secondary_color, diagonal_direction)
        delay = 80
    elif chosen_effect == EFFECT_CHECKER:
        frames = diagonal_checker_frames(primary_color, secondary_color)
        delay = 80
    elif chosen_effect == EFFECT_PIXEL_FLOOD:
        frames = pixel_flood_frames(primary_color)
        delay = 50
    elif chosen_effect == EFFECT_SCATTER:
        frames = pixel_scatter_frames(primary_color, secondary_color)
        delay = 90
    elif chosen_effect == EFFECT_CYLON:
        frames = cylon_eye_frames(primary_color, secondary_color)
        delay = 60
    elif chosen_effect == EFFECT_STAR:
        frames = star_frames(primary_color, secondary_color)
        delay = 90
    elif chosen_effect == EFFECT_DOOM:
        frames = doom_wipe_frames(primary_color, secondary_color, chosen_direction)
        delay = 90
    elif chosen_effect == EFFECT_FADE:
        frames = fade_frames(primary_color, secondary_color)
        delay = 120
    else:
        frames = horizontal_wipe_frames(primary_color, secondary_color, chosen_direction)
        delay = 80

    return render.Root(
        child = render.Animation(children = frames),
        delay = delay,
    )

def full_frame(color):
    return render.Box(
        width = canvas.width(),
        height = canvas.height(),
        color = color,
    )

def blink_frames(primary, secondary):
    frames = []
    cycles = 7
    for i in range(cycles):
        frames.append(full_frame(primary if i % 2 == 0 else secondary))

    frames.append(full_frame(primary))
    frames.append(full_frame(primary))
    return frames

def horizontal_wipe_frames(primary, secondary, direction):
    width = canvas.width()
    height = canvas.height()
    step = max(2, width // 12)
    frames = []

    for current in range(0, width + step, step):
        wipe_width = min(width, current)
        left = 0 if direction == "ltr" else width - wipe_width
        right = max(0, width - left - wipe_width)
        frames.append(
            render.Stack(
                children = [
                    full_frame(secondary),
                    render.Padding(
                        pad = (left, 0, right, 0),
                        child = render.Box(
                            width = wipe_width,
                            height = height,
                            color = primary,
                        ),
                    ),
                ],
            ),
        )

    frames.append(full_frame(primary))
    return frames

def vertical_wipe_frames(primary, secondary, direction):
    width = canvas.width()
    height = canvas.height()
    step = max(2, height // 10)
    frames = []

    for current in range(0, height + step, step):
        wipe_height = min(height, current)
        top = 0 if direction != "btt" else height - wipe_height
        bottom = max(0, height - top - wipe_height)
        frames.append(
            render.Stack(
                children = [
                    full_frame(secondary),
                    render.Padding(
                        pad = (0, top, 0, bottom),
                        child = render.Box(
                            width = width,
                            height = wipe_height,
                            color = primary,
                        ),
                    ),
                ],
            ),
        )

    frames.append(full_frame(primary))
    return frames

def diagonal_checker_frames(primary, secondary):
    width = canvas.width()
    height = canvas.height()
    span = width + height
    stripe = 4
    step = max(2, span // 18)
    frames = []

    for progress in range(0, span + step, step):
        children = [full_frame(secondary)]
        for y in range(height):
            max_x = min(width, progress - y + 1)
            if max_x <= 0:
                continue
            for x in range(max_x):
                if ((x + y) // stripe) % 2 != 0:
                    continue
                right = width - x - 1
                bottom = height - y - 1
                children.append(
                    render.Padding(
                        pad = (x, y, right, bottom),
                        child = render.Box(width = 1, height = 1, color = primary),
                    ),
                )

        frames.append(render.Stack(children = children))

    frames.append(full_frame(primary))
    return frames

def pixel_flood_frames(primary):
    width = canvas.width()
    height = canvas.height()
    coords = []
    for y in range(height):
        for x in range(width):
            coords.append((x, y))

    # Fisher-Yates shuffle
    for i in range(len(coords) - 1, 0, -1):
        j = random.number(0, i)
        coords[i], coords[j] = coords[j], coords[i]

    batch_size = max(10, (width * height) // 50)
    frames = [full_frame("#000000")]

    for idx in range(0, len(coords), batch_size):
        children = [frames[-1]]
        for x, y in coords[idx:idx + batch_size]:
            right = width - x - 1
            bottom = height - y - 1
            children.append(
                render.Padding(
                    pad = (x, y, right, bottom),
                    child = render.Box(width = 1, height = 1, color = primary),
                ),
            )

        frames.append(render.Stack(children = children))

    frames.append(full_frame(primary))
    return frames

def pixel_scatter_frames(primary, secondary):
    width = canvas.width()
    height = canvas.height()
    particles = 24
    start_x, start_y = random_origin(width, height)
    vectors = [random_vector() for _ in range(particles)]
    steps = max([v["life"] for v in vectors])

    frames = [full_frame(secondary)]

    for step_idx in range(steps):
        children = [full_frame(secondary)]
        for v in vectors:
            if step_idx > v["life"]:
                continue
            x = int(clamp(math.round(start_x + v["dx"] * step_idx), 0, width - 1))
            y = int(clamp(math.round(start_y + v["dy"] * step_idx), 0, height - 1))
            right = width - x - 1
            bottom = height - y - 1
            children.append(
                render.Padding(
                    pad = (x, y, right, bottom),
                    child = render.Box(width = 1, height = 1, color = primary),
                ),
            )

        frames.append(render.Stack(children = children))

    frames.append(full_frame(primary))
    return frames

def cylon_eye_frames(primary, secondary):
    width = canvas.width()
    height = canvas.height()
    beam_width = 5
    core_width = 3 if width >= 10 else 2
    edge_width = max(1, (beam_width - core_width) // 2)
    dim = interpolate_color(secondary, primary, 0.45)
    positions = list(range(-beam_width, width + beam_width, 2))
    positions.extend(positions[-2:0:-1])

    def add_strip(children, start, strip_w, color):
        if strip_w <= 0:
            return
        start_int = int(start)
        end_int = int(start + strip_w)
        if end_int <= 0 or start_int >= width:
            return
        left = clamp(start_int, 0, width - 1)
        right_bound = clamp(end_int, 0, width)
        actual_w = right_bound - left
        if actual_w <= 0:
            return
        pad_right = width - left - actual_w
        children.append(
            render.Padding(
                pad = (left, 0, pad_right, 0),
                child = render.Box(width = actual_w, height = height, color = color),
            ),
        )

    frames = []
    for pos in positions:
        children = [full_frame(secondary)]
        add_strip(children, pos, edge_width, dim)
        add_strip(children, pos + edge_width, core_width, primary)
        add_strip(children, pos + edge_width + core_width, edge_width, dim)
        frames.append(render.Stack(children = children))

    return frames

def random_vector():
    angle_deg = random.number(0, 359)
    speed = random.number(1, 3)
    life = random.number(5, 12)
    rad = angle_deg * math.pi / 180
    return {
        "dx": math.cos(rad) * speed,
        "dy": math.sin(rad) * speed,
        "life": life,
    }

def random_origin(width, height):
    margin = 2
    cx = width // 2
    cy = height // 2
    min_offset = max(3, min(width, height) // 4)
    for _ in range(12):
        x = random.number(margin, width - margin - 1)
        y = random.number(margin, height - margin - 1)
        if abs(x - cx) + abs(y - cy) >= min_offset:
            return x, y
    return cx, cy + 2

def rect_layer(total_w, total_h, rect_w, rect_h, color, left = None, top = None):
    rect_w = min(rect_w, total_w)
    rect_h = min(rect_h, total_h)
    left = (total_w - rect_w) // 2 if left == None else left
    top = (total_h - rect_h) // 2 if top == None else top
    right = max(0, total_w - left - rect_w)
    bottom = max(0, total_h - top - rect_h)

    return render.Padding(
        pad = (left, top, right, bottom),
        child = render.Box(
            width = rect_w,
            height = rect_h,
            color = color,
        ),
    )

def circle_layer(total_w, total_h, diameter, color):
    diameter = min(diameter, total_w, total_h)
    left = (total_w - diameter) // 2
    top = (total_h - diameter) // 2
    right = total_w - left - diameter
    bottom = total_h - top - diameter

    return render.Padding(
        pad = (left, top, right, bottom),
        child = render.Circle(color = color, diameter = diameter),
    )

def clamp(value, min_v, max_v):
    if value < min_v:
        return min_v
    if value > max_v:
        return max_v
    return value

def star_frames(primary, secondary):
    width = canvas.width()
    height = canvas.height()
    max_size = max(width, height)
    step = max(3, max_size // 10)
    frames = []

    for size in range(2, max_size + step, step):
        cross_thickness = max(2, size // 8)
        circle_size = max(2, min(size, min(width, height)))
        layers = [
            full_frame(secondary),
            circle_layer(width, height, circle_size, primary),
            rect_layer(width, height, width, cross_thickness, primary, top = (height - cross_thickness) // 2),
            rect_layer(width, height, cross_thickness, height, primary, left = (width - cross_thickness) // 2),
        ]
        frames.append(render.Stack(children = layers))

    frames.append(full_frame(primary))
    frames.append(full_frame(primary))
    return frames

def diagonal_wipe_frames(primary, secondary, direction):
    width = canvas.width()
    height = canvas.height()
    span = width + height
    step = max(2, span // 18)
    frames = []

    for progress in range(0, span + step, step):
        children = [full_frame(secondary)]
        for y in range(height):
            offset = y if direction == "tlbr" else (height - 1 - y)
            row_fill = progress - offset
            if row_fill <= 0:
                continue
            row_fill = min(width, row_fill)
            left = 0 if direction == "tlbr" else width - row_fill
            right = max(0, width - left - row_fill)
            children.append(
                render.Padding(
                    pad = (left, y, right, height - y - 1),
                    child = render.Box(
                        width = row_fill,
                        height = 1,
                        color = primary,
                    ),
                ),
            )

        frames.append(render.Stack(children = children))

    frames.append(full_frame(primary))
    return frames

def doom_wipe_frames(primary, secondary, direction):
    width = canvas.width()
    height = canvas.height()
    strips = 8
    strip_width = int(math.ceil(float(width) / strips))
    start_offsets = [random.number(0, 4) for _ in range(strips)]
    step = max(2, height // 8)
    total_frames = max(start_offsets) + math.ceil(height / step) + 2
    frames = []

    for frame_index in range(total_frames):
        children = [full_frame(secondary)]
        for idx in range(strips):
            progress = (frame_index - start_offsets[idx]) * step
            if progress <= 0:
                continue

            strip_height = min(height, progress)
            left = strip_width * idx if direction != "rtl" else width - (idx + 1) * strip_width
            strip_actual_width = min(strip_width, width - left)
            right = max(0, width - left - strip_actual_width)
            bottom = max(0, height - strip_height)

            children.append(
                render.Padding(
                    pad = (left, 0, right, bottom),
                    child = render.Box(
                        width = strip_actual_width,
                        height = strip_height,
                        color = primary,
                    ),
                ),
            )

        frames.append(render.Stack(children = children))

    frames.append(full_frame(primary))
    frames.append(full_frame(primary))
    return frames

def fade_frames(primary, secondary):
    steps = 14
    frames = []

    for i in range(0, steps + 1):
        factor = float(i) / float(steps)
        frames.append(full_frame(interpolate_color(secondary, primary, factor)))

    frames.append(full_frame(primary))
    return frames

def interpolate_color(color1, color2, factor):
    rgb1 = hex_to_rgb(color1)
    rgb2 = hex_to_rgb(color2)
    return rgb_to_hex(
        (
            int(rgb1[0] + (rgb2[0] - rgb1[0]) * factor),
            int(rgb1[1] + (rgb2[1] - rgb1[1]) * factor),
            int(rgb1[2] + (rgb2[2] - rgb1[2]) * factor),
        ),
    )

def hex_to_rgb(hex_color):
    color = hex_color.lstrip("#")
    if len(color) == 8:
        color = color[2:]
    return (int(color[0:2], 16), int(color[2:4], 16), int(color[4:6], 16))

def rgb_to_hex(rgb_color):
    return "#" + int_to_hex(rgb_color[0]) + int_to_hex(rgb_color[1]) + int_to_hex(rgb_color[2])

def int_to_hex(value):
    chars = "0123456789abcdef"
    return chars[(value >> 4) & 0xF] + chars[value & 0xF]
