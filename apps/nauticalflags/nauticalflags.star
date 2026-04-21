"""
Applet: NauticalFlags
Summary: Display nautical flags
Description: Displays nautical flags.
Author: Robert Ison
"""

load("images/alfa.png", ALFA_FLAG = "file")
load("images/bravo.png", BRAVO_FLAG = "file")
load("images/charlie.png", CHARLIE_FLAG = "file")
load("images/delta.png", DELTA_FLAG = "file")
load("images/echo.png", ECHO_FLAG = "file")
load("images/foxtrot.png", FOXTROT_FLAG = "file")
load("images/golf.png", GOLF_FLAG = "file")
load("images/hotel.png", HOTEL_FLAG = "file")
load("images/india.png", INDIA_FLAG = "file")
load("images/juliet.png", JULIET_FLAG = "file")
load("images/kilo.png", KILO_FLAG = "file")
load("images/lima.png", LIMA_FLAG = "file")
load("images/mike.png", MIKE_FLAG = "file")
load("images/november.png", NOVEMBER_FLAG = "file")
load("images/oscar.png", OSCAR_FLAG = "file")
load("images/papa.png", PAPA_FLAG = "file")
load("images/quebec.png", QUEBEC_FLAG = "file")
load("images/romeo.png", ROMEO_FLAG = "file")
load("images/sierra.png", SIERRA_FLAG = "file")
load("images/space.png", SPACE_FLAG = "file")
load("images/tango.png", TANGO_FLAG = "file")
load("images/uniform.png", UNIFORM_FLAG = "file")
load("images/victor.png", VICTOR_FLAG = "file")
load("images/whiskey.png", WHISKEY_FLAG = "file")
load("images/xray.png", XRAY_FLAG = "file")
load("images/yankee.png", YANKEE_FLAG = "file")
load("images/zulu.png", ZULU_FLAG = "file")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")

display_defaults = {
    "screen_width": 64,
    "screen_height": 32,
    "icon_width": 32,
    "icon_height": 32,
}

flags = {
    " ": {
        "name": " ",
        "flag": SPACE_FLAG.readall(),
    },
    "a": {
        "name": "Alfa",
        "flag": ALFA_FLAG.readall(),
    },
    "b": {
        "name": "Bravo",
        "flag": BRAVO_FLAG.readall(),
    },
    "c": {
        "name": "Charlie",
        "flag": CHARLIE_FLAG.readall(),
    },
    "d": {
        "name": "Delta",
        "flag": DELTA_FLAG.readall(),
    },
    "e": {
        "name": "Echo",
        "flag": ECHO_FLAG.readall(),
    },
    "f": {
        "name": "Foxtrot",
        "flag": FOXTROT_FLAG.readall(),
    },
    "g": {
        "name": "Golf",
        "flag": GOLF_FLAG.readall(),
    },
    "h": {
        "name": "Hotel",
        "flag": HOTEL_FLAG.readall(),
    },
    "i": {
        "name": "India",
        "flag": INDIA_FLAG.readall(),
    },
    "j": {
        "name": "Juliet",
        "flag": JULIET_FLAG.readall(),
    },
    "k": {
        "name": "Kilo",
        "flag": KILO_FLAG.readall(),
    },
    "l": {
        "name": "Lima",
        "flag": LIMA_FLAG.readall(),
    },
    "m": {
        "name": "Mike",
        "flag": MIKE_FLAG.readall(),
    },
    "n": {
        "name": "November",
        "flag": NOVEMBER_FLAG.readall(),
    },
    "o": {
        "name": "Oscar",
        "flag": OSCAR_FLAG.readall(),
    },
    "p": {
        "name": "Papa",
        "flag": PAPA_FLAG.readall(),
    },
    "q": {
        "name": "Quebec",
        "flag": QUEBEC_FLAG.readall(),
    },
    "r": {
        "name": "Romeo",
        "flag": ROMEO_FLAG.readall(),
    },
    "s": {
        "name": "Sierra",
        "flag": SIERRA_FLAG.readall(),
    },
    "t": {
        "name": "Tango",
        "flag": TANGO_FLAG.readall(),
    },
    "u": {
        "name": "Uniform",
        "flag": UNIFORM_FLAG.readall(),
    },
    "v": {
        "name": "Victor",
        "flag": VICTOR_FLAG.readall(),
    },
    "w": {
        "name": "Whiskey",
        "flag": WHISKEY_FLAG.readall(),
    },
    "x": {
        "name": "X-ray",
        "flag": XRAY_FLAG.readall(),
    },
    "y": {
        "name": "Yankee",
        "flag": YANKEE_FLAG.readall(),
    },
    "z": {
        "name": "Zulu",
        "flag": ZULU_FLAG.readall(),
    },
}

common_pairings = ["AC", "AD", "AN", "BR", "CD", "DV", "dx", "EF", "EL", "FA", "GM", "GN", "GW", "IT", "JA", "JL", "MAA", "MAB", "MAC", "MAD", "LO", "NC", "PD", "PP", "QD", "QT", "QQ", "QU", "QX", "UM", "UP"]

display_options = [
    schema.Option(value = "phrases", display = "Display Random Maritime Messages"),
    schema.Option(value = "letters", display = "Flags in Alphabetical Order"),
    schema.Option(value = "randomletters", display = "Flags in Random Order"),
    schema.Option(value = "custom", display = "Custom Phrase"),
]

speed_options = [
    schema.Option(value = "100", display = "Slow"),
    schema.Option(value = "60", display = "Medium"),
    schema.Option(value = "35", display = "Fast"),
]

def get_display_config():
    return {
        "screen_width": display_defaults["screen_width"],
        "screen_height": display_defaults["screen_height"],
        "icon_width": display_defaults["icon_width"],
        "icon_height": display_defaults["icon_height"],
    }

def main(config):
    display = get_display_config()

    display_type = config.get("type", display_options[0].value)
    speed = int(config.get("speed", speed_options[1].value))

    # Future 2x example:
    if canvas.is2x():
        display["screen_width"] = 128
        display["screen_height"] = 64
        display["icon_width"] = 64
        display["icon_height"] = 64
        speed = int(speed / 2)

    display_text = "TIDBYT ROCKS"

    if display_type == display_options[0].value:
        display_text = get_random_phrases()
    elif display_type == display_options[1].value:
        display_text = get_random_alphabetical_order_flags()
    elif display_type == display_options[2].value:
        display_text = get_random_letters()
    elif display_type == display_options[3].value:
        custom_text = config.get("phrase")
        if custom_text != None and custom_text != "":
            display_text = custom_text

    return render.Root(
        delay = speed,
        child = get_smooth_scroll(display_text, display),
    )

def get_random_phrases():
    remaining_pairings = []
    display_text = ""

    for item in common_pairings:
        remaining_pairings.append(item)

    for i in range(0, 5):
        random_number = random.number(0, len(remaining_pairings) - 1)
        if i > 0:
            display_text = display_text + " "
        display_text = display_text + remaining_pairings[random_number]
        remaining_pairings.remove(remaining_pairings[random_number])

    return display_text

def get_random_letters():
    lowest_letter = 97
    highest_letter = 122

    remaining_letters = []
    for i in range(lowest_letter, highest_letter + 1):
        remaining_letters.append(chr(i))

    display_text = ""
    for i in range(0, 9):
        random_item = random.number(0, len(remaining_letters) - 1)
        random_letter = remaining_letters[random_item]

        if i > 0:
            display_text = display_text + " "
        display_text = display_text + random_letter

        remaining_letters.remove(random_letter)

    return display_text

def get_random_alphabetical_order_flags():
    lowest_letter = 97
    highest_letter = 122

    starting_point = random.number(lowest_letter, highest_letter)

    display_text = ""
    for i in range(0, 9):
        if i > 0:
            display_text = display_text + " "

        display_text = display_text + chr(starting_point)
        starting_point = starting_point + 1

        if starting_point > highest_letter:
            starting_point = lowest_letter

    return display_text

def normalize_text(text):
    chars = []
    text = text.lower()

    for i in range(0, len(text)):
        if text[i] in flags:
            chars.append(text[i])

    if len(chars) == 0:
        chars.append(" ")

    return chars

def make_flag_strip(text, display):
    chars = normalize_text(text)
    children = []

    for ch in chars:
        children.append(
            render.Image(
                width = display["icon_width"] if ch != " " else int(display["icon_width"] // 3),
                height = display["icon_height"],
                src = flags[ch]["flag"],
            ),
        )

    return render.Row(children = children)

def get_strip_width(text, display):
    chars = normalize_text(text)
    return len(chars) * display["icon_width"]

def get_smooth_scroll(text, display):
    strip = make_flag_strip(text, display)
    strip_width = get_strip_width(text, display)

    return render.Marquee(
        width = display["screen_width"],
        child = strip,
        offset_start = display["screen_width"],
        offset_end = -strip_width,
    )

def get_custom(type):
    if type == "custom":
        return [
            schema.Text(
                id = "phrase",
                name = "Custom Phrase",
                desc = "Custom Phrase",
                icon = "message",
            ),
        ]
    else:
        return []

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "type",
                name = "Display",
                desc = "What to Display?",
                icon = "flag",
                options = display_options,
                default = display_options[0].value,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Speed",
                desc = "Scroll speed?",
                icon = "forwardFast",
                options = speed_options,
                default = speed_options[1].value,
            ),
            schema.Generated(
                id = "custom",
                source = "type",
                handler = get_custom,
            ),
        ],
    )
