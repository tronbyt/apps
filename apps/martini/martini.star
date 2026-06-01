"""
Applet: Martini
Summary: Displays your martini order
Description: Displays your martini order based on your preferences.
Author: Robert Ison
"""

load("images/martini_lemon.png", MARTINI_LEMON_ASSET = "file")
load("images/martini_olives.png", MARTINI_OLIVES_ASSET = "file")
load("images/martini_onions.png", MARTINI_ONIONS_ASSET = "file")
load("images/martini_orange.png", MARTINI_ORANGE_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

MARTINI_LEMON = MARTINI_LEMON_ASSET.readall()
MARTINI_OLIVES = MARTINI_OLIVES_ASSET.readall()
MARTINI_ONIONS = MARTINI_ONIONS_ASSET.readall()
MARTINI_ORANGE = MARTINI_ORANGE_ASSET.readall()

PHRASES = ["I would like %s.", "Pour me %s please.", "Fix me %s please.", "I'll have %s.", "Could I get %s please?", "I'm feeling %s."]

FONT = "5x8"

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )
    return padded_element

#handy little function that let's you print out a bunch of variables
#def display_variables(*args):
#    i = 0
#    for var in args:
#        i = i + 1
#        print("%s: %s" % (i, var))

def main(config):
    base = config.get("base", base_options[len(base_options) - 1].value)
    preparation = config.get("preparation", preparation_options[1].value)
    vermouth_type = config.get("vermouthtypeof", vermouth_options[2].value)
    garnish = config.get("garnish", garnish_options[0].value)
    dirty = " dirty " if garnish == "dirty" else ""
    drink = "Gibson" if garnish == "Onion" else "martini"
    garnish_description = "" if drink == "Gibson" or garnish == "dirty" else ", %s" % garnish
    vermouth_description = ", "

    if vermouth_type == "Sweet" or vermouth_type == "White":
        if vermouth_type == "Sweet":
            vermouth_description = " with sweet vermouth, "
        elif vermouth_type == "White":
            vermouth_description = " with white vermouth, " if random.number(0, 1) == 1 else " with bianco vermouth, "
        vermouth_type = ""
    else:
        vermouth_type = vermouth_type + " "

    #default image
    selected_image = render.Image(src = MARTINI_OLIVES)

    if "twist" in garnish or "peel" in garnish:
        if "orange" in garnish:
            selected_image = render.Image(src = MARTINI_ORANGE)
        else:
            selected_image = render.Image(src = MARTINI_LEMON)
    elif drink == "Gibson" or garnish == "au naturel":
        selected_image = render.Image(src = MARTINI_ONIONS)

    #display_variables(base, preparation, vermouth_type, garnish, dirty, drink, vermouth_description)

    if base == "Vesper":
        vermouth_type = ""
        vermouth_description = ", "

    if vermouth_type == "Dry":
        vermouth_type = ""

    spacer = " "
    if base == "Gin" and config.bool("oldschool"):
        base = ""
        spacer = ""

    article = "an" if vermouth_type == "Extra Dry " and dirty == "" else "a"

    if len(dirty) == 0:
        article = article + " "

    message = "%s%s%s%s%s%s%s%s%s" % (article, dirty.lower(), vermouth_type.lower(), base.lower(), spacer, drink.lower(), vermouth_description.lower(), preparation.lower(), garnish_description.lower())
    message = "     " + PHRASES[random.number(0, len(PHRASES) - 1)] % message

    return render.Root(
        render.Stack(
            children = [
                selected_image,
                add_padding_to_child_element(render.Marquee(width = 50, child = render.Text(content = message, color = "#fff", font = FONT)), 12, 20),
            ],
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def get_vermouth_options(base):
    if base == "Vesper":
        return []
    else:
        return [
            schema.Dropdown(
                id = "vermouthtypeof",
                name = "Vermouth",
                desc = "Choose your type of vermouth for your martini.",
                icon = "wineBottle",  #guage, glassWater
                options = vermouth_options,
                default = vermouth_options[0].value,
            ),
        ]

scroll_speed_options = [
    schema.Option(display = "Slow", value = "60"),
    schema.Option(display = "Medium", value = "45"),
    schema.Option(display = "Fast", value = "30"),
]

base_options = [
    schema.Option(value = "Gin", display = "Gin"),
    schema.Option(value = "Vodka", display = "Vodka"),
    schema.Option(value = "Vesper", display = "Vesper (Gin, Vodka and Lillet Blanc)"),
]

vermouth_options = [
    schema.Option(value = "Naked", display = "None"),
    schema.Option(value = "Extra Dry", display = "Very little dry vermouth"),
    schema.Option(value = "Dry", display = "About 1/4 Ounce of dry vermouth"),
    schema.Option(value = "Wet", display = "Even more vermouth"),
    schema.Option(value = "Sweet", display = "Some sweet vermouth"),
    schema.Option(value = "Perfect", display = "Equal Mix of Sweet and Dry vermouth"),
    schema.Option(value = "White", display = "White (bianco) Vermouth"),
]

garnish_options = [
    schema.Option(value = "au naturel", display = "Nothing"),
    schema.Option(value = "with an olive", display = "Olive with no brine"),
    schema.Option(value = "dirty", display = "Olive with some brine"),
    schema.Option(value = "with a twist", display = "Twist of Lemon Peel"),
    schema.Option(value = "with an orange twist", display = "Twist of Orange Peel"),
    schema.Option(value = "with a lemon peel", display = "Larger piece of Lemon Peel"),
    schema.Option(value = "with an orange peel", display = "Larger piece of Orange Peel"),
    schema.Option(value = "with Caper Berries", display = "Caper Berries"),
    schema.Option(value = "Onion", display = "Cocktail Onion"),
]

preparation_options = [
    schema.Option(value = "Shaken", display = "Shaken in a mixing tin adding ice shards."),
    schema.Option(value = "Stirred", display = "Stirred in a mixing tin with ice shards less likely to appear."),
    schema.Option(value = "Up", display = "Chilled, but let the bartender decide to shake, stir or throw."),
    schema.Option(value = "Thrown", display = "Thrown from one mixing tin to another."),
    schema.Option(value = "On the Rocks", display = "Mixed with Ice Cubes in the glass."),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
            schema.Toggle(
                id = "oldschool",
                name = "Old School Bartender?",
                desc = "Is your bartender an experience 'old school' mixologist?",
                icon = "personChalkboard",  #"user", #"person",
                default = True,
            ),
            schema.Dropdown(
                id = "base",
                name = "Base Spirit",
                desc = "Choose your base spirit for your Martini.",
                icon = "flask",  #"martiniGlassEmpty",
                default = base_options[0].value,
                options = base_options,
            ),
            schema.Dropdown(
                id = "preparation",
                name = "Preparation",
                desc = "How would you like your martini prepared?",
                icon = "spoon",
                default = preparation_options[0].value,
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
                desc = "What would you like added to your Martini?",
                icon = "martiniGlassCitrus",
                default = garnish_options[0].value,
                options = garnish_options,
            ),
        ],
    )
