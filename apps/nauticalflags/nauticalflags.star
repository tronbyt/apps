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
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

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

DISPLAY_OPTIONS = [
    schema.Option(value = "phrases", display = "Display Random Maritime Messages"),
    schema.Option(value = "letters", display = "Flags in Alphabetical Order"),
    schema.Option(value = "randomletters", display = "Flags in Random Order"),
    schema.Option(value = "custom", display = "Custom Phrase"),
]

SPEED_OPTIONS = [
    schema.Option(value = "2200", display = "Slow"),
    schema.Option(value = "1600", display = "Medium"),
    schema.Option(value = "1000", display = "Fast"),
]

def main(config):
    display_type = config.get("type", DISPLAY_OPTIONS[0])
    speed = config.get("speed", 1000)

    #default
    display_text = "TIDBYT ROCKS"

    if (display_type == DISPLAY_OPTIONS[0].value):
        display_text = get_random_phrases()
    elif (display_type == DISPLAY_OPTIONS[1].value):
        display_text = get_random_alphabetical_order_flags()
    elif (display_type == DISPLAY_OPTIONS[2].value):
        display_text = get_random_letters()
    elif (display_type == DISPLAY_OPTIONS[3].value):
        custom_text = config.get("phrase")
        if custom_text != None:
            display_text = custom_text

    return render.Root(
        delay = int(speed),
        child = render.Row(
            children = get_animation_flags(display_text, 2),
        ),
    )

def get_random_phrases():
    remaining_pairings = []
    display_text = ""
    for item in common_pairings:
        remaining_pairings.append(item)

    for _ in range(0, 5):
        random_number = randomize(0, len(remaining_pairings) - 1)
        display_text = display_text + " " + remaining_pairings[random_number]
        remaining_pairings.remove(remaining_pairings[random_number])

    return display_text

def get_random_letters():
    lowest_letter = 97
    highest_letter = 122

    remaining_letters = []
    for i in range(lowest_letter, highest_letter):
        remaining_letters.append(chr(i))

    display_text = " "
    for _ in range(0, 9):
        random_item = randomize(0, len(remaining_letters) - 1)
        random_letter = remaining_letters[random_item]
        display_text = display_text + " " + random_letter
        remaining_letters.remove(random_letter)

    return display_text

def get_random_alphabetical_order_flags():
    lowest_letter = 97
    highest_letter = 122

    starting_point = randomize(lowest_letter, highest_letter)

    display_text = " "
    for _ in range(0, 9):
        display_text = display_text + " " + chr(starting_point)
        starting_point = starting_point + 1
        if starting_point > highest_letter:
            display_text = display_text + " "
            starting_point = lowest_letter

    return display_text

def get_animation_flags(text, positions):
    children = []

    for i in range(0, positions):
        children.append(render.Animation(get_word_in_flag(text, positions - i)))

    return children

def get_word_in_flag(text, position):
    children = []

    for i in range(0, position):
        children.append(render.Image(width = 32, height = 32, src = flags[" "]["flag"]))

    text = text.lower()
    for i in range(0, len(text)):
        if text[i] in flags:
            children.append(render.Image(width = 32, height = 32, src = flags[text[i]]["flag"]))

    return children

def randomize(min, max):
    now = time.now()
    rand = int(str(now.nanosecond)[-6:-3]) / 1000
    return int(rand * (max + 1 - min) + min)

def get_custom(type):
    if (type == "custom"):
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
                options = DISPLAY_OPTIONS,
                default = DISPLAY_OPTIONS[0].value,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Speed",
                desc = "Display speed?",
                icon = "forwardFast",
                options = SPEED_OPTIONS,
                default = SPEED_OPTIONS[0].value,
            ),
            schema.Generated(
                id = "custom",
                source = "type",
                handler = get_custom,
            ),
        ],
    )
