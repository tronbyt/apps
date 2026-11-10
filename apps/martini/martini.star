"""
Applet: Martini
Summary: Displays your martini order
Description: Displays a personalized martini order with garnish artwork.
Author: Robert Ison
"""

load("images/martini_lemon.png", MARTINI_LEMON_ASSET = "file")
load("images/martini_olives.png", MARTINI_OLIVES_ASSET = "file")
load("images/martini_onions.png", MARTINI_ONIONS_ASSET = "file")
load("images/martini_orange.png", MARTINI_ORANGE_ASSET = "file")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")

MARTINI_LEMON = MARTINI_LEMON_ASSET.readall()
MARTINI_OLIVES = MARTINI_OLIVES_ASSET.readall()
MARTINI_ONIONS = MARTINI_ONIONS_ASSET.readall()
MARTINI_ORANGE = MARTINI_ORANGE_ASSET.readall()

DEFAULT_BASE = "Gin"
DEFAULT_PREPARATION = "Shaken"
DEFAULT_VERMOUTH = "Naked"
DEFAULT_GARNISH = "au naturel"
DEFAULT_SCROLL = "60"

SCENE_WIDTH = 64
SCENE_HEIGHT = 32

PHRASES = [
    "I would like %s.",
    "Pour me %s please.",
    "Fix me %s please.",
    "I'll have %s.",
    "Could I get %s please?",
    "I'm in the mood for %s.",
]

scroll_speed_options = [
    schema.Option(display = "Slow", value = "60"),
    schema.Option(display = "Medium", value = "45"),
    schema.Option(display = "Fast", value = "30"),
]

base_options = [
    schema.Option(value = "Gin", display = "Gin"),
    schema.Option(value = "Vodka", display = "Vodka"),
    schema.Option(
        value = "Vesper",
        display = "Vesper (Gin, Vodka and Lillet Blanc)",
    ),
]

vermouth_options = [
    schema.Option(value = "Naked", display = "None"),
    schema.Option(
        value = "Extra Dry",
        display = "Very little dry vermouth",
    ),
    schema.Option(
        value = "Dry",
        display = "About 1/4 ounce of dry vermouth",
    ),
    schema.Option(value = "Wet", display = "Even more vermouth"),
    schema.Option(value = "Sweet", display = "Some sweet vermouth"),
    schema.Option(
        value = "Perfect",
        display = "Equal mix of sweet and dry vermouth",
    ),
    schema.Option(value = "White", display = "White (bianco) vermouth"),
]

garnish_options = [
    schema.Option(value = "au naturel", display = "Nothing"),
    schema.Option(value = "with an olive", display = "Olive with no brine"),
    schema.Option(value = "dirty", display = "Olive with some brine"),
    schema.Option(value = "with a twist", display = "Twist of lemon peel"),
    schema.Option(
        value = "with an orange twist",
        display = "Twist of orange peel",
    ),
    schema.Option(
        value = "with a lemon peel",
        display = "Larger piece of lemon peel",
    ),
    schema.Option(
        value = "with an orange peel",
        display = "Larger piece of orange peel",
    ),
    schema.Option(value = "with Caper Berries", display = "Caper berries"),
    schema.Option(value = "Onion", display = "Cocktail onion"),
]

preparation_options = [
    schema.Option(
        value = "Shaken",
        display = "Shaken in a mixing tin, adding ice shards.",
    ),
    schema.Option(
        value = "Stirred",
        display = "Stirred with ice; ice shards are less likely.",
    ),
    schema.Option(
        value = "Up",
        display = "Chilled; let the bartender choose the mixing method.",
    ),
    schema.Option(
        value = "Thrown",
        display = "Thrown from one mixing tin to another.",
    ),
    schema.Option(
        value = "On the Rocks",
        display = "Served over ice cubes in the glass.",
    ),
]

def position(child, left = 0, top = 0):
    return render.Padding(
        pad = (left, top, 0, 0),
        child = child,
    )

def option_value(config, setting_id, options, default):
    value = config.get(setting_id)

    for option in options:
        if value == option.value:
            return value

    return default

def random_index(count):
    if count <= 1:
        return 0

    return min(int(random.float() * count), count - 1)

def get_preferences(config):
    return {
        "base": option_value(
            config,
            "base",
            base_options,
            DEFAULT_BASE,
        ),
        "preparation": option_value(
            config,
            "preparation",
            preparation_options,
            DEFAULT_PREPARATION,
        ),
        "vermouth": option_value(
            config,
            "vermouthtypeof",
            vermouth_options,
            DEFAULT_VERMOUTH,
        ),
        "garnish": option_value(
            config,
            "garnish",
            garnish_options,
            DEFAULT_GARNISH,
        ),
        "oldschool": config.bool("oldschool", True),
        "scroll": option_value(
            config,
            "scroll",
            scroll_speed_options,
            DEFAULT_SCROLL,
        ),
    }

def build_order(preferences):
    base = preferences["base"]
    preparation = preferences["preparation"]
    vermouth = preferences["vermouth"]
    garnish = preferences["garnish"]

    is_vesper = base == "Vesper"
    is_gibson = not is_vesper and garnish == "Onion"

    words = []
    clauses = []

    if garnish == "dirty":
        words.append("dirty")

    # Vesper ignores any previously saved vermouth preference.
    if not is_vesper:
        if vermouth in ["Naked", "Extra Dry", "Wet", "Perfect"]:
            words.append(vermouth.lower())
        elif vermouth == "Sweet":
            clauses.append("with sweet vermouth")
        elif vermouth == "White":
            white_name = (
                "white" if random_index(2) == 0 else "bianco"
            )
            clauses.append("with " + white_name + " vermouth")

        # Standard Dry intentionally adds no modifier.
        if base == "Vodka":
            words.append("vodka")
        elif base == "Gin" and not preferences["oldschool"]:
            words.append("gin")

    if is_vesper:
        words.append("Vesper")
    elif is_gibson:
        words.append("Gibson")
    else:
        words.append("martini")

    drink_text = " ".join(words)
    article = (
        "an" if drink_text.lower().startswith("extra dry ") else "a"
    )

    clauses.append(preparation.lower())

    if garnish == "Onion":
        # A Gibson already implies its onion garnish.
        if is_vesper:
            clauses.append("with a cocktail onion")
    elif garnish not in ["dirty", "au naturel"]:
        clauses.append(garnish.lower())

    order = article + " " + drink_text

    if clauses:
        order += ", " + ", ".join(clauses)

    return order

def scaled_asset(asset, scale):
    image = render.Image(src = asset)

    if scale == 1:
        return image

    width, height = image.size()

    return render.Image(
        src = asset,
        width = width * scale,
        height = height * scale,
    )

def glass_rectangle(x, y, width, height, color, scale):
    return position(
        render.Box(
            width = width * scale,
            height = height * scale,
            color = color,
        ),
        x * scale,
        y * scale,
    )

def ungarnished_glass(scale):
    # Self-contained artwork: no additional image asset required.
    glass_color = "#D9F3FF"
    liquid_color = "#A6DAD0"
    children = [
        render.Box(
            width = SCENE_WIDTH * scale,
            height = SCENE_HEIGHT * scale,
            color = "#000000",
        ),
        glass_rectangle(1, 3, 31, 1, glass_color, scale),
    ]

    for row in range(1, 14):
        left = 1 + row
        right = 31 - row

        if row >= 4 and right - left > 1:
            children.append(
                glass_rectangle(
                    left + 1,
                    3 + row,
                    right - left - 1,
                    1,
                    liquid_color,
                    scale,
                ),
            )

        children.append(
            glass_rectangle(left, 3 + row, 1, 1, glass_color, scale),
        )
        children.append(
            glass_rectangle(right, 3 + row, 1, 1, glass_color, scale),
        )

    children.extend([
        glass_rectangle(15, 17, 3, 1, glass_color, scale),
        glass_rectangle(16, 18, 1, 11, glass_color, scale),
        glass_rectangle(11, 29, 11, 1, glass_color, scale),
        glass_rectangle(9, 30, 15, 1, glass_color, scale),
    ])

    return render.Stack(children = children)

def garnish_artwork(garnish, scale):
    if garnish == "au naturel":
        return ungarnished_glass(scale)

    if garnish == "Onion":
        return scaled_asset(MARTINI_ONIONS, scale)

    if "orange" in garnish:
        return scaled_asset(MARTINI_ORANGE, scale)

    if "twist" in garnish or "peel" in garnish:
        return scaled_asset(MARTINI_LEMON, scale)

    # Olive artwork also approximates caper berries.
    return scaled_asset(MARTINI_OLIVES, scale)

def build_scene(preferences, message, scale):
    font = "terminus-16" if scale == 2 else "5x8"

    return render.Box(
        width = SCENE_WIDTH * scale,
        height = SCENE_HEIGHT * scale,
        child = render.Stack(
            children = [
                garnish_artwork(preferences["garnish"], scale),
                position(
                    render.Marquee(
                        width = 50 * scale,
                        child = render.Text(
                            content = message,
                            color = "#FFFFFF",
                            font = font,
                        ),
                    ),
                    12 * scale,
                    20 * scale,
                ),
            ],
        ),
    )

def main(config):
    preferences = get_preferences(config)
    order = build_order(preferences)
    phrase = PHRASES[random_index(len(PHRASES))]
    message = "     " + phrase % order

    scale = 2 if canvas.is2x() else 1
    scene = build_scene(preferences, message, scale)

    # Standard scene fills 64x32; 2x fills 128x64.
    # Taller panels center the bounded scene.
    return render.Root(
        child = render.Box(
            width = canvas.width(),
            height = canvas.height(),
            child = scene,
        ),
        show_full_animation = True,
        delay = int(preferences["scroll"]),
    )

def get_vermouth_options(base):
    if base == "Vesper":
        return []

    return [
        schema.Dropdown(
            id = "vermouthtypeof",
            name = "Vermouth",
            desc = "Choose your vermouth preference.",
            icon = "wineBottle",
            options = vermouth_options,
            default = DEFAULT_VERMOUTH,
        ),
    ]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Text scrolling speed.",
                icon = "stopwatch",
                options = scroll_speed_options,
                default = DEFAULT_SCROLL,
            ),
            schema.Toggle(
                id = "oldschool",
                name = "Old School Bartender?",
                desc = (
                    "Omit 'gin' from gin-based orders. Vodka orders still name the spirit."
                ),
                icon = "personChalkboard",
                default = True,
            ),
            schema.Dropdown(
                id = "base",
                name = "Base Spirit",
                desc = "Choose your martini base or a Vesper.",
                icon = "flask",
                default = DEFAULT_BASE,
                options = base_options,
            ),
            schema.Dropdown(
                id = "preparation",
                name = "Preparation",
                desc = "How would you like your drink prepared?",
                icon = "spoon",
                default = DEFAULT_PREPARATION,
                options = preparation_options,
            ),
            schema.Generated(
                id = "vermouthtype",
                source = "base",
                handler = get_vermouth_options,
            ),
            schema.Dropdown(
                id = "garnish",
                name = "Garnish",
                desc = (
                    "Choose a garnish. Cocktail onions name gin/vodka orders Gibson; a Vesper keeps its name."
                ),
                icon = "martiniGlassCitrus",
                default = DEFAULT_GARNISH,
                options = garnish_options,
            ),
        ],
    )
