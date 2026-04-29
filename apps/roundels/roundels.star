"""
Applet: Roundels
Summary: See air force roundels
Description: Display Air Force roundels of world.
Author: Robert Ison
"""

load("images/australia.png", AUSTRALIA_ASSET = "file")
load("images/australia_flag.webp", AUSTRALIA_FLAG_ASSET = "file")
load("images/brazil.png", BRAZIL_ASSET = "file")
load("images/brazil_flag.webp", BRAZIL_FLAG_ASSET = "file")
load("images/china.png", CHINA_ASSET = "file")
load("images/china_flag.webp", CHINA_FLAG_ASSET = "file")
load("images/egypt.png", EGYPT_ASSET = "file")
load("images/egypt_flag.webp", EGYPT_FLAG_ASSET = "file")
load("images/finland.png", FINLAND_ASSET = "file")
load("images/finland_flag.webp", FINLAND_FLAG_ASSET = "file")
load("images/france.png", FRANCE_ASSET = "file")
load("images/france_flag.webp", FRANCE_FLAG_ASSET = "file")
load("images/germany.png", GERMANY_ASSET = "file")
load("images/germany_flag.webp", GERMANY_FLAG_ASSET = "file")
load("images/greece.png", GREECE_ASSET = "file")
load("images/greece_flag.webp", GREECE_FLAG_ASSET = "file")
load("images/india.png", INDIA_ASSET = "file")
load("images/india_flag.webp", INDIA_FLAG_ASSET = "file")
load("images/indonesia.png", INDONESIA_ASSET = "file")
load("images/indonesia_flag.webp", INDONESIA_FLAG_ASSET = "file")
load("images/iran.png", IRAN_ASSET = "file")
load("images/iran_flag.webp", IRAN_FLAG_ASSET = "file")
load("images/israel.png", ISRAEL_ASSET = "file")
load("images/israel_flag.webp", ISRAEL_FLAG_ASSET = "file")
load("images/italy.png", ITALY_ASSET = "file")
load("images/italy_flag.webp", ITALY_FLAG_ASSET = "file")
load("images/japan.png", JAPAN_ASSET = "file")
load("images/japan_flag.webp", JAPAN_FLAG_ASSET = "file")
load("images/mexico.png", MEXICO_ASSET = "file")
load("images/mexico_flag.webp", MEXICO_FLAG_ASSET = "file")
load("images/norway.png", NORWAY_ASSET = "file")
load("images/norway_flag.webp", NORWAY_FLAG_ASSET = "file")
load("images/pakistan.png", PAKISTAN_ASSET = "file")
load("images/pakistan_flag.webp", PAKISTAN_FLAG_ASSET = "file")
load("images/russia.png", RUSSIA_ASSET = "file")
load("images/russia_flag.webp", RUSSIA_FLAG_ASSET = "file")
load("images/saudi_arabia.png", SAUDI_ARABIA_ASSET = "file")
load("images/saudi_arabia_flag.webp", SAUDI_ARABIA_FLAG_ASSET = "file")
load("images/south_korea.png", SOUTH_KOREA_ASSET = "file")
load("images/south_korea_flag.webp", SOUTH_KOREA_FLAG_ASSET = "file")
load("images/spain.png", SPAIN_ASSET = "file")
load("images/spain_flag.webp", SPAIN_FLAG_ASSET = "file")
load("images/sweden.png", SWEDEN_ASSET = "file")
load("images/sweden_flag.webp", SWEDEN_FLAG_ASSET = "file")
load("images/switzerland.png", SWITZERLAND_ASSET = "file")
load("images/switzerland_flag.webp", SWITZERLAND_FLAG_ASSET = "file")
load("images/thailand.png", THAILAND_ASSET = "file")
load("images/thailand_flag.webp", THAILAND_FLAG_ASSET = "file")
load("images/turkey.png", TURKEY_ASSET = "file")
load("images/turkey_flag.webp", TURKEY_FLAG_ASSET = "file")
load("images/uae.png", UAE_ASSET = "file")
load("images/uae_flag.webp", UAE_FLAG_ASSET = "file")
load("images/ukraine.png", UKRAINE_ASSET = "file")
load("images/ukraine_flag.webp", UKRAINE_FLAG_ASSET = "file")
load("images/united_kingdom.png", UNITED_KINGDOM_ASSET = "file")
load("images/united_kingdom_flag.webp", UNITED_KINGDOM_FLAG_ASSET = "file")
load("images/united_states.png", UNITED_STATES_ASSET = "file")
load("images/united_states_flag.webp", UNITED_STATES_FLAG_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

SCREEN_WIDTH = 64
SCREEN_HEIGHT = 32

DATA = {
    "United States": {
        "order": 1,
        "roundel": UNITED_STATES_ASSET.readall(),
        "flag": UNITED_STATES_FLAG_ASSET.readall(),
    },
    "Russia": {
        "order": 2,
        "roundel": RUSSIA_ASSET.readall(),
        "flag": RUSSIA_FLAG_ASSET.readall(),
    },
    "China": {
        "order": 3,
        "roundel": CHINA_ASSET.readall(),
        "flag": CHINA_FLAG_ASSET.readall(),
    },
    "India": {
        "order": 4,
        "roundel": INDIA_ASSET.readall(),
        "flag": INDIA_FLAG_ASSET.readall(),
    },
    "Japan": {
        "order": 5,
        "roundel": JAPAN_ASSET.readall(),
        "flag": JAPAN_FLAG_ASSET.readall(),
    },
    "Israel": {
        "order": 6,
        "roundel": ISRAEL_ASSET.readall(),
        "flag": ISRAEL_FLAG_ASSET.readall(),
    },
    "France": {
        "order": 7,
        "roundel": FRANCE_ASSET.readall(),
        "flag": FRANCE_FLAG_ASSET.readall(),
    },
    "United Kingdom": {
        "order": 8,
        "roundel": UNITED_KINGDOM_ASSET.readall(),
        "flag": UNITED_KINGDOM_FLAG_ASSET.readall(),
    },
    "South Korea": {
        "order": 9,
        "roundel": SOUTH_KOREA_ASSET.readall(),
        "flag": SOUTH_KOREA_FLAG_ASSET.readall(),
    },
    "Italy": {
        "order": 10,
        "roundel": ITALY_ASSET.readall(),
        "flag": ITALY_FLAG_ASSET.readall(),
    },
    "Australia": {
        "order": 11,
        "roundel": AUSTRALIA_ASSET.readall(),
        "flag": AUSTRALIA_FLAG_ASSET.readall(),
    },
    "Brazil": {
        "order": 12,
        "roundel": BRAZIL_ASSET.readall(),
        "flag": BRAZIL_FLAG_ASSET.readall(),
    },
    "Saudi Arabia": {
        "order": 13,
        "roundel": SAUDI_ARABIA_ASSET.readall(),
        "flag": SAUDI_ARABIA_FLAG_ASSET.readall(),
    },
    "Pakistan": {
        "order": 14,
        "roundel": PAKISTAN_ASSET.readall(),
        "flag": PAKISTAN_FLAG_ASSET.readall(),
    },
    "Germany": {
        "order": 15,
        "roundel": GERMANY_ASSET.readall(),
        "flag": GERMANY_FLAG_ASSET.readall(),
    },
    "Turkey": {
        "order": 16,
        "roundel": TURKEY_ASSET.readall(),
        "flag": TURKEY_FLAG_ASSET.readall(),
    },
    "Egypt": {
        "order": 17,
        "roundel": EGYPT_ASSET.readall(),
        "flag": EGYPT_FLAG_ASSET.readall(),
    },
    "Spain": {
        "order": 19,
        "roundel": SPAIN_ASSET.readall(),
        "flag": SPAIN_FLAG_ASSET.readall(),
    },
    "Indonesia": {
        "order": 20,
        "roundel": INDONESIA_ASSET.readall(),
        "flag": INDONESIA_FLAG_ASSET.readall(),
    },
    "Ukraine": {
        "order": 21,
        "roundel": UKRAINE_ASSET.readall(),
        "flag": UKRAINE_FLAG_ASSET.readall(),
    },
    "Iran": {
        "order": 22,
        "roundel": IRAN_ASSET.readall(),
        "flag": IRAN_FLAG_ASSET.readall(),
    },
    "Thailand": {
        "order": 23,
        "roundel": THAILAND_ASSET.readall(),
        "flag": THAILAND_FLAG_ASSET.readall(),
    },
    "Mexico": {
        "order": 24,
        "roundel": MEXICO_ASSET.readall(),
        "flag": MEXICO_FLAG_ASSET.readall(),
    },
    "Sweden": {
        "order": 25,
        "roundel": SWEDEN_ASSET.readall(),
        "flag": SWEDEN_FLAG_ASSET.readall(),
    },
    "Greece": {
        "order": 26,
        "roundel": GREECE_ASSET.readall(),
        "flag": GREECE_FLAG_ASSET.readall(),
    },
    "Norway": {
        "order": 27,
        "roundel": NORWAY_ASSET.readall(),
        "flag": NORWAY_FLAG_ASSET.readall(),
    },
    "Finland": {
        "order": 28,
        "roundel": FINLAND_ASSET.readall(),
        "flag": FINLAND_FLAG_ASSET.readall(),
    },
    "Switzerland": {
        "order": 29,
        "roundel": SWITZERLAND_ASSET.readall(),
        "flag": SWITZERLAND_FLAG_ASSET.readall(),
    },
    "UAE": {
        "order": 30,
        "roundel": UAE_ASSET.readall(),
        "flag": UAE_FLAG_ASSET.readall(),
    },
}

def get_country_options():
    country_options = []

    sorted_by_country = sorted(DATA, key = lambda m: m, reverse = False)

    country_options.append(schema.Option(display = "Random", value = "Random"))

    for country in sorted_by_country:
        country_options.append(schema.Option(display = country, value = country))

    return country_options

def display_instructions(config):
    ##############################################################################################################################################################################################################################
    title = "Roundels"
    instructions_1 = "You can pick a country and a random country will be compared head-to-head. You'll see the roundels (symbol on their aircraft) "
    instructions_2 = "then the flag of the two countries to help identify them. Then you'll see the roundels once more, then the stronger air force will have its roundel and "
    instructions_3 = "flag displayed.  You also have the choice to display the names of the countries in addition to the roundels and flags for even more clarity."
    return render.Root(
        render.Column(
            children = [
                render.Marquee(
                    width = SCREEN_WIDTH,
                    child = render.Text(title, color = "#60A5FA", font = "5x8"),
                ),
                render.Marquee(
                    width = SCREEN_WIDTH,
                    child = render.Text(instructions_1, color = "#93C5FD"),
                    offset_start = len(title) * 5,
                ),
                render.Marquee(
                    offset_start = (len(title) + len(instructions_1)) * 5,
                    width = SCREEN_WIDTH,
                    child = render.Text(instructions_2, color = "#93C5FD"),
                ),
                render.Marquee(
                    offset_start = (len(title) + len(instructions_2) + len(instructions_1)) * 5,
                    width = SCREEN_WIDTH,
                    child = render.Text(instructions_3, color = "#93C5FD"),
                ),
            ],
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )

    return padded_element

def circle_diameter(square_width):
    # Calculate the circle diameter to completely cover a square of the given width
    return square_width * math.sqrt(2)

def display_winner(flag, roundel):
    animated_frames = []
    item_width = int(SCREEN_WIDTH / 2)

    snapshot = render.Text("")

    for i in range(-SCREEN_HEIGHT, 0, 1):
        snapshot = render.Stack(
            children = [
                add_padding_to_child_element(flag, 0, i),
                add_padding_to_child_element(roundel, item_width, -i),
            ],
        )

        animated_frames.append(snapshot)

    for _ in range(10):
        animated_frames.append(snapshot)

    return animated_frames

def transition_effect_crossover(item_one, item_two):
    animated_frames = []
    snapshot = render.Text("")
    item_width = int(SCREEN_WIDTH / 2)

    for i in range(-item_width, item_width + 1, 1):
        snapshot = render.Stack(
            children = [
                add_padding_to_child_element(item_one, i),
                add_padding_to_child_element(item_two, item_width - i),
            ],
        )

        animated_frames.append(snapshot)

    for _ in range(10):
        animated_frames.append(snapshot)

    return animated_frames

def transition_effect_two_squares(static_item, item_width):
    animated_frames = []
    item_width = int(item_width)
    for i in range(int(item_width), 1, -2):
        offset = int((item_width - i) / 2)
        snapshot = render.Stack(
            children = [
                static_item,
                add_padding_to_child_element(render.Box(width = i, height = i, color = "#000"), offset, offset),
                add_padding_to_child_element(render.Box(width = i, height = i, color = "#000"), item_width + offset, offset),
            ],
        )

        animated_frames.append(snapshot)

    for _ in range(10):
        animated_frames.append(static_item)

    return animated_frames

def transition_effect_two_circles(static_item, item_width):
    animated_frames = []
    item_width = int(item_width)
    for i in range(int(circle_diameter(item_width)), 1, -2):
        offset = math.floor((item_width - i) / 2)

        snapshot = render.Stack(
            children = [
                static_item,
                add_padding_to_child_element(render.Circle(diameter = i, color = "#000"), offset, offset),
                add_padding_to_child_element(render.Circle(diameter = i, color = "#000"), item_width + offset, offset),
            ],
        )

        animated_frames.append(snapshot)

    for _ in range(10):
        animated_frames.append(static_item)

    return animated_frames

def append_stacks(animation, stacks):
    for s in stacks:
        animation.append(s)

def randomize(min, max):
    now = time.now()
    base = now.unix * 1000000000 + now.nanosecond
    rand = ((base ^ (base >> 11)) % 1000) / 1000.0
    return int(rand * (max + 1 - min) + min)

def pick_two_countries(pick):
    n = len(DATA)
    i = randomize(0, n - 1)

    first = DATA.keys()[i] if pick == "Random" or pick == None else pick
    rest = [x for x in DATA if x != first]

    second = rest[randomize(0, len(rest) - 1)]
    return (first, second)

def main(config):
    show_instructions = config.bool("instructions", False)
    if show_instructions:
        return display_instructions(config)

    item_width = int(SCREEN_WIDTH / 2)

    #Pick Two Countries from the list
    first_name, second_name = pick_two_countries(config.get("always_pick"))

    first = DATA[first_name]
    second = DATA[second_name]

    if (int(first["order"]) < int(second["order"])):
        winner = first_name
        loser = second_name
        winner_roundel = render.Image(src = first["roundel"], width = item_width, height = item_width)
        winner_flag = render.Image(src = first["flag"], width = item_width, height = item_width)
    else:
        winner = second_name
        loser = first_name
        winner_roundel = render.Image(src = second["roundel"], width = item_width, height = item_width)
        winner_flag = render.Image(src = second["flag"], width = item_width, height = item_width)

    #Store each frame
    animated_frames = []

    snapshot_roundels = render.Stack(
        children = [
            render.Image(
                src = first["roundel"],
            ),
            add_padding_to_child_element(render.Image(
                src = second["roundel"],
                width = item_width,
                height = item_width,
            ), item_width),
        ],
    )

    snapshot_flags = render.Stack(
        children = [
            render.Image(
                src = first["flag"],
            ),
            add_padding_to_child_element(render.Image(
                src = second["flag"],
                width = item_width,
                height = item_width,
            ), item_width),
        ],
    )

    append_stacks(animated_frames, transition_effect_crossover(render.Image(src = second["roundel"]), render.Image(src = first["roundel"])))
    append_stacks(animated_frames, transition_effect_two_circles(snapshot_flags, SCREEN_WIDTH / 2))
    append_stacks(animated_frames, transition_effect_two_squares(snapshot_roundels, SCREEN_WIDTH / 2))
    append_stacks(animated_frames, display_winner(winner_roundel, winner_flag))

    if config.get("display_text", False) == "true":
        items = []
        for _ in range(25):
            items.append(render.Stack(
                children = [
                    add_padding_to_child_element(render.Text(winner), int(SCREEN_WIDTH / 2 - len(winner * 5) / 2), 0),
                    add_padding_to_child_element(render.Text("over"), int(SCREEN_WIDTH / 2 - (2 * 5)), 12),
                    add_padding_to_child_element(render.Text(loser), int(SCREEN_WIDTH / 2 - len(loser * 5) / 2), 24),
                ],
            ))
        append_stacks(animated_frames, items)

    # Black for a for a frames
    for _ in range(5):
        animated_frames.append(render.Box(width = SCREEN_WIDTH, height = SCREEN_HEIGHT, color = "#000"))

    return render.Root(
        delay = int(config.get("scroll", 45)),
        child = render.Animation(
            children = animated_frames,
        ),
        show_full_animation = True,
    )

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
            value = "30",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "instructions",
                name = "Display Instructions",
                desc = "",
                icon = "book",
                default = False,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Speed",
                desc = "Speed of the drawing",
                icon = "clock",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
            schema.Toggle(
                id = "display_text",
                name = "Display Names?",
                desc = "Display names of countries",
                icon = "info",
                default = False,
            ),
            schema.Dropdown(
                id = "always_pick",
                name = "Country vs.",
                desc = "Pick a country to always display.",
                icon = "globe",
                default = "United States",
                options = get_country_options(),
            ),
        ],
    )
