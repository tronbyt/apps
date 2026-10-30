"""
Applet: Aquarium
Summary: Digital Aquarium
Description: A digital aquarium.
Author: Robert Ison
"""

load("images/anchor.png", ANCHOR_ASSET = "file")
load("images/anglerfish.png", ANGLERFISH_ASSET = "file")
load("images/blowfish.png", BLOWFISH_ASSET = "file")
load("images/blue_tang.png", BLUE_TANG_ASSET = "file")
load("images/clownfish.png", CLOWNFISH_ASSET = "file")
load("images/coral_brain.png", CORAL_BRAIN_ASSET = "file")
load("images/coral_finger.png", CORAL_FINGER_ASSET = "file")
load("images/coral_tubes.png", CORAL_TUBES_ASSET = "file")
load("images/crab.png", CRAB_ASSET = "file")
load("images/cuttlefish.png", CUTTLEFISH_ASSET = "file")
load("images/diver.png", DIVER_ASSET = "file")
load("images/helmet.png", HELMET_ASSET = "file")
load("images/lionfish.png", LIONFISH_ASSET = "file")
load("images/shark.png", SHARK_ASSET = "file")
load("images/shipwreck.png", SHIPWRECK_ASSET = "file")
load("images/treasure.png", TREASURE_ASSET = "file")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")

def make_fish(name, direction, width, height, asset):
    return {
        "name": name,
        "direction": direction,
        "width": width,
        "height": height,
        "image": asset.readall(),
    }

def make_decoration(name, width, height, asset):
    return {
        "name": name,
        "width": width,
        "height": height,
        "image": asset.readall(),
    }

sealife = [
    make_fish("Clownfish", "left", 27, 15, CLOWNFISH_ASSET),
    make_fish("AnglerFish", "left", 22, 12, ANGLERFISH_ASSET),
    make_fish("Blue Tang", "right", 25, 14, BLUE_TANG_ASSET),
    make_fish("Lionfish", "right", 25, 14, LIONFISH_ASSET),
    make_fish("Shark", "left", 29, 11, SHARK_ASSET),
    make_fish("Blowfish", "right", 25, 16, BLOWFISH_ASSET),
    make_fish("Cuttlefish", "right", 30, 14, CUTTLEFISH_ASSET),
]

ocean_floor = [
    make_decoration("Brain", 20, 12, CORAL_BRAIN_ASSET),
    make_decoration("Finger", 17, 15, CORAL_FINGER_ASSET),
    make_decoration("Tubes", 17, 18, CORAL_TUBES_ASSET),
    make_decoration("shipwreck", 25, 20, SHIPWRECK_ASSET),
    make_decoration("helmet", 15, 17, HELMET_ASSET),
    make_decoration("anchor", 12, 12, ANCHOR_ASSET),
    make_decoration("crab", 25, 12, CRAB_ASSET),
    make_decoration("treasure", 22, 16, TREASURE_ASSET),
]

water = [
    {
        "name": "Aqua",
        "html": "#33b5cc",
        "include_in_random": True,
    },
    {
        "name": "Deep Sky Blue",
        "html": "#0099cc",
        "include_in_random": True,
    },
    {
        "name": "Aquamarine",
        "html": "#40d6a5",
        "include_in_random": False,
    },
    {
        "name": "Light Blue",
        "html": "#ADD8E6",
        "include_in_random": False,
    },
    {
        "name": "Very Dark Blue",
        "html": "#04034d",
        "include_in_random": True,
    },
    {
        "name": "Dark Turquoise",
        "html": "#00ced1",
        "include_in_random": True,
    },
    {
        "name": "Turquoise",
        "html": "#30c2b3",
        "include_in_random": False,
    },
    {
        "name": "Ocean Blue",
        "html": "#006994",
        "include_in_random": True,
    },
    {
        "name": "Deep Teal",
        "html": "#005F66",
        "include_in_random": True,
    },
    {
        "name": "Midnight Ocean",
        "html": "#001F3F",
        "include_in_random": True,
    },
    {
        "name": "Lagoon",
        "html": "#007F86",
        "include_in_random": True,
    },
    {
        "name": "Kelp Forest",
        "html": "#164F43",
        "include_in_random": True,
    },
    {
        "name": "Black",
        "html": "#000000",
        "include_in_random": True,
    },
]

def main(config):
    active_sealife = list(sealife)

    # Keep the original setting ID so existing preferences still apply.
    if config.bool("include_diver", True):
        active_sealife.append(
            make_fish("Diver", "right", 25, 15, DIVER_ASSET),
        )

    return render.Root(
        get_frames(
            active_sealife,
            config.str("color", "Random"),
            canvas.width(),
            canvas.height(),
        ),
        show_full_animation = True,
        delay = 120,
    )

def safe_random(low, high):
    if high <= low:
        return low

    return random.number(low, high)

def pick_random_items(items, count):
    remaining = list(items)
    selected = []

    for _ in range(min(count, len(remaining))):
        index = safe_random(0, len(remaining) - 1)
        selected.append(remaining.pop(index))

    return selected

def position(element, left = 0, top = 0):
    return render.Padding(
        pad = (left, top, 0, 0),
        child = element,
    )

# ---------- Water colors and gradient ----------

HEX_DIGITS = "0123456789abcdef"

def parse_rgb(color):
    return [
        int(color[1:3], 16),
        int(color[3:5], 16),
        int(color[5:7], 16),
    ]

def hex_byte(value):
    value = max(0, min(255, value))
    return HEX_DIGITS[value // 16] + HEX_DIGITS[value % 16]

def rgb_color(rgb):
    return "#" + "".join([hex_byte(value) for value in rgb])

def shade_color(color, percent):
    rgb = parse_rgb(color)

    return rgb_color([
        value * percent // 100
        for value in rgb
    ])

def mix_color(color, target, percent):
    source_rgb = parse_rgb(color)
    target_rgb = parse_rgb(target)

    return rgb_color([
        (
            source_rgb[index] * (100 - percent) +
            target_rgb[index] * percent
        ) // 100
        for index in range(3)
    ])

def get_water_background(color, width, height):
    # Black is intentionally exempt from the gradient.
    if color.lower() == "#000000":
        return render.Box(
            color = "#000000",
            width = width,
            height = height,
        )

    children = []
    band_count = min(8, max(1, height))

    for band in range(band_count):
        top = height * band // band_count
        bottom = height * (band + 1) // band_count

        # Base color at the top, 20 percent darker at the bottom.
        brightness = 100 - 20 * band // max(1, band_count - 1)

        children.append(
            position(
                render.Box(
                    color = shade_color(color, brightness),
                    width = width,
                    height = bottom - top,
                ),
                0,
                top,
            ),
        )

    return render.Stack(children = children)

# ---------- Main swimming subjects ----------

def get_fish_speed(fish_number):
    return 1 if fish_number == 1 else 2

def get_fish_start_x(fish, fish_number, width):
    stagger = 10 * fish_number * fish_number

    if fish["direction"] == "right":
        return -(fish["width"] + 1) - stagger

    return width + stagger

def get_fish_x(fish, frame, fish_number, width):
    start = get_fish_start_x(fish, fish_number, width)
    movement = frame * get_fish_speed(fish_number)

    if fish["direction"] == "right":
        return start + movement

    return start - movement

def get_animation_frame_count(selected_sealife, width):
    last_exit_frame = 0

    for fish_number in range(len(selected_sealife)):
        fish = selected_sealife[fish_number]
        speed = get_fish_speed(fish_number)
        start = get_fish_start_x(fish, fish_number, width)

        if fish["direction"] == "right":
            distance = width - start
        else:
            distance = start + fish["width"] + 1

        exit_frame = (distance + speed - 1) // speed
        last_exit_frame = max(last_exit_frame, exit_frame)

    return max(2, last_exit_frame + 1)

def get_motion(fish, frame, fish_number):
    phase = fish_number * 2
    name = fish["name"]

    bob_pattern = [0, 0, 1, 1, 0, 0, -1, -1]
    bob_step = 3
    wiggle_step = 2

    if name == "Shark":
        # Keep the shark level, with a slower width pulse.
        bob_pattern = [0]
        wiggle_step = 4
    elif name == "Blowfish":
        # Spend more time at the upper and lower points.
        bob_pattern = [0, 1, 1, 1, 0, -1, -1, -1]
        bob_step = 4
        wiggle_step = 3
    elif name == "Cuttlefish":
        bob_step = 5
        wiggle_step = 4
    elif name == "Diver":
        bob_step = 5
        wiggle_step = 6

    bob = bob_pattern[((frame // bob_step) + phase) % len(bob_pattern)]

    if name == "Diver":
        # Brief width pulse rather than continuous stretching.
        wiggle = 1 if ((frame // wiggle_step) + phase) % 4 == 0 else 0
    else:
        wiggle = ((frame // wiggle_step) + fish_number) % 2

    return (bob, wiggle)

def get_fish_top(fish, frame, fish_number, height):
    base = (
        height * (fish_number + 1) // 4 -
        fish["height"] // 2
    )

    bob, _ = get_motion(fish, frame, fish_number)

    return base + bob

def get_fish_frame(fish, frame, fish_number, width, height):
    _, wiggle = get_motion(fish, frame, fish_number)

    return position(
        render.Image(
            src = fish["image"],
            width = fish["width"] + wiggle,
            height = fish["height"],
        ),
        get_fish_x(fish, frame, fish_number, width),
        get_fish_top(fish, frame, fish_number, height),
    )

# ---------- Floor decorations ----------

def select_floor_decorations():
    selected = pick_random_items(ocean_floor, 3)

    # Tallest decoration is the rear object.
    return sorted(
        selected,
        key = lambda decoration: decoration["height"],
    )

def overlap_width(x, object_width, other_x, other_width):
    return max(
        0,
        min(x + object_width, other_x + other_width) -
        max(x, other_x),
    )

def get_floor_offsets(decorations, width):
    if len(decorations) == 0:
        return []

    offsets = []

    # Place foreground objects first, favoring low overlap.
    foreground_count = max(0, len(decorations) - 1)

    for index in range(foreground_count):
        item = decorations[index]
        max_left = max(0, width - item["width"])

        if index == 0:
            best_x = safe_random(0, max_left)
        else:
            best_x = 0
            best_score = None

            # Exhaustive search is small on a pixel display.
            for candidate in range(max_left + 1):
                overlap = 0

                for previous in range(index):
                    overlap += overlap_width(
                        candidate,
                        item["width"],
                        offsets[previous],
                        decorations[previous]["width"],
                    )

                # Overlap dominates; random tie-breaking adds variety.
                score = overlap * 100 + safe_random(0, 20)

                if best_score == None or score < best_score:
                    best_score = score
                    best_x = candidate

        offsets.append(best_x)

    # Rear object may overlap foreground objects for depth.
    rear = decorations[len(decorations) - 1]
    offsets.append(
        safe_random(0, max(0, width - rear["width"])),
    )

    return offsets

def get_floor_element(decoration, left, height):
    return position(
        render.Image(
            src = decoration["image"],
            width = decoration["width"],
            height = decoration["height"],
        ),
        left,
        height - decoration["height"],
    )

# ---------- Seamlessly looping ambient bubbles ----------

def create_bubbles(width, height):
    travel = height + 2

    return [
        {
            "x": safe_random(1, max(1, width - 2)),
            "phase": travel * index // 3,
            "drift_phase": index * 2,
        }
        for index in range(3)
    ]

def get_bubble_elements(
        bubbles,
        frame,
        frame_count,
        width,
        height,
        color):
    children = []
    travel = height + 2

    # An exact number of complete rises per animation.
    # At the loop boundary, motion continues rather than resetting.
    cycles = max(1, frame_count // max(1, travel * 3))
    progress = frame * travel * cycles // frame_count

    drift_pattern = [0, 0, 1, 1, 0, 0, -1, -1]
    drift_progress = frame * len(drift_pattern) // frame_count

    for bubble in bubbles:
        top = height - ((progress + bubble["phase"]) % travel)

        drift = drift_pattern[(drift_progress + bubble["drift_phase"]) % len(drift_pattern)]

        left = max(0, min(width - 1, bubble["x"] + drift))

        if top >= 0 and top < height:
            children.append(
                position(
                    render.Box(color = color, width = 1, height = 1),
                    left,
                    top,
                ),
            )

    return children

# ---------- Occasional diver bubbles ----------

def get_diver_bubbles(
        selected_sealife,
        frame,
        frame_count,
        width,
        height,
        color):
    children = []
    lifetime = 16

    for fish_number in range(len(selected_sealife)):
        fish = selected_sealife[fish_number]

        if fish["name"] != "Diver":
            continue

        # Fixed emission times let bubbles drift independently.
        for emitted_at in range(12, frame_count, 24):
            # Do not leave bubbles hanging at the animation boundary.
            if emitted_at + lifetime >= frame_count:
                continue

            age = frame - emitted_at

            if age < 0 or age >= lifetime:
                continue

            origin_x = get_fish_x(
                fish,
                emitted_at,
                fish_number,
                width,
            ) + fish["width"] - 4

            origin_y = get_fish_top(
                fish,
                emitted_at,
                fish_number,
                height,
            ) + 3

            # Only release bubbles while the diver's head is visible.
            if origin_x < 0 or origin_x >= width:
                continue

            left = origin_x + (age // 4) % 2
            top = origin_y - age // 2

            if left >= 0 and left < width and top >= 0 and top < height:
                children.append(
                    position(
                        render.Box(color = color, width = 1, height = 1),
                        left,
                        top,
                    ),
                )

    return children

# ---------- Assemble the animation ----------

def get_frames(available_sealife, water_color, width, height):
    sand_color = "#C2B280"

    selected_sealife = pick_random_items(available_sealife, 3)
    selected_floor = select_floor_decorations()
    floor_offsets = get_floor_offsets(selected_floor, width)

    if water_color == "" or water_color == "Random":
        random_colors = [
            color
            for color in water
            if color.get("include_in_random", False)
        ]

        # Fall back to the full palette if every flag is disabled.
        if not random_colors:
            random_colors = water

        water_color = random_colors[safe_random(0, len(random_colors) - 1)]["html"]

    background = get_water_background(water_color, width, height)

    # Muted colors derived from the selected water color.
    bubble_color = mix_color(water_color, "#FFFFFF", 28)

    frame_count = get_animation_frame_count(selected_sealife, width)
    bubbles = create_bubbles(width, height)

    rear_index = len(selected_floor) - 1
    frames = []

    for frame_number in range(frame_count):
        children = [background]

        children.extend(
            get_bubble_elements(
                bubbles,
                frame_number,
                frame_count,
                width,
                height,
                bubble_color,
            ),
        )

        children.append(
            position(
                render.Box(
                    color = sand_color,
                    width = width,
                    height = 1,
                ),
                0,
                height - 2,
            ),
        )

        if rear_index >= 0:
            children.append(
                get_floor_element(
                    selected_floor[rear_index],
                    floor_offsets[rear_index],
                    height,
                ),
            )

        children.extend(
            get_diver_bubbles(
                selected_sealife,
                frame_number,
                frame_count,
                width,
                height,
                bubble_color,
            ),
        )

        for fish_number in range(len(selected_sealife)):
            children.append(
                get_fish_frame(
                    selected_sealife[fish_number],
                    frame_number,
                    fish_number,
                    width,
                    height,
                ),
            )

        for index in range(max(0, rear_index)):
            children.append(
                get_floor_element(
                    selected_floor[index],
                    floor_offsets[index],
                    height,
                ),
            )

        children.append(
            position(
                render.Box(
                    color = sand_color,
                    width = width,
                    height = 1,
                ),
                0,
                height - 1,
            ),
        )

        frames.append(
            render.Stack(children = children),
        )

    return render.Animation(children = frames)

# ---------- Configuration ----------

def get_color_options(colors):
    sorted_colors = sorted(
        colors,
        key = lambda color: color["name"],
    )

    options = [
        schema.Option(
            display = color["name"],
            value = color["html"],
        )
        for color in sorted_colors
    ]

    options.append(
        schema.Option(
            display = "Random",
            value = "Random",
        ),
    )

    return options

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "color",
                name = "Water Color",
                desc = "What water color do you prefer?",
                icon = "water",
                options = get_color_options(water),
                default = "Random",
            ),
            schema.Toggle(
                id = "include_diver",
                name = "Allow Diver",
                desc = "Allow a diver to be randomly selected?",
                icon = "personSwimming",
                default = True,
            ),
        ],
    )
