"""
Applet: NauticalFlags
Summary: Display nautical flags
Description: Displays nautical flags.
Author: Robert Ison
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/img_06d41a6e.png", IMG_06d41a6e_ASSET = "file")
load("images/img_08979567.png", IMG_08979567_ASSET = "file")
load("images/img_09cd1795.png", IMG_09cd1795_ASSET = "file")
load("images/img_0ce6b50c.png", IMG_0ce6b50c_ASSET = "file")
load("images/img_10321aaa.png", IMG_10321aaa_ASSET = "file")
load("images/img_171021ca.png", IMG_171021ca_ASSET = "file")
load("images/img_1e4dd24f.png", IMG_1e4dd24f_ASSET = "file")
load("images/img_25fcc367.png", IMG_25fcc367_ASSET = "file")
load("images/img_2b3e1c33.png", IMG_2b3e1c33_ASSET = "file")
load("images/img_4fe5ac8e.png", IMG_4fe5ac8e_ASSET = "file")
load("images/img_5ad5c86f.png", IMG_5ad5c86f_ASSET = "file")
load("images/img_696b45aa.png", IMG_696b45aa_ASSET = "file")
load("images/img_6a456f93.png", IMG_6a456f93_ASSET = "file")
load("images/img_707f5c87.png", IMG_707f5c87_ASSET = "file")
load("images/img_7c5621d7.png", IMG_7c5621d7_ASSET = "file")
load("images/img_7e3bea22.png", IMG_7e3bea22_ASSET = "file")
load("images/img_7f3dbd31.png", IMG_7f3dbd31_ASSET = "file")
load("images/img_b6768953.png", IMG_b6768953_ASSET = "file")
load("images/img_b7149aab.png", IMG_b7149aab_ASSET = "file")
load("images/img_d41d80aa.png", IMG_d41d80aa_ASSET = "file")
load("images/img_d9c20f83.png", IMG_d9c20f83_ASSET = "file")
load("images/img_dc21fca6.png", IMG_dc21fca6_ASSET = "file")
load("images/img_e0d88004.png", IMG_e0d88004_ASSET = "file")
load("images/img_e1955924.png", IMG_e1955924_ASSET = "file")
load("images/img_e3a1208f.png", IMG_e3a1208f_ASSET = "file")
load("images/img_ede0610f.png", IMG_ede0610f_ASSET = "file")
load("images/img_fb9eb262.png", IMG_fb9eb262_ASSET = "file")

flags = {
    " ": {
        "name": " ",
        "flag": IMG_7e3bea22_ASSET.readall(),
    },
    "a": {
        "name": "Alfa",
        "flag": IMG_6a456f93_ASSET.readall(),
    },
    "b": {
        "name": "Bravo",
        "flag": IMG_171021ca_ASSET.readall(),
    },
    "c": {
        "name": "Charlie",
        "flag": IMG_dc21fca6_ASSET.readall(),
    },
    "d": {
        "name": "Delta",
        "flag": IMG_d41d80aa_ASSET.readall(),
    },
    "e": {
        "name": "Echo",
        "flag": IMG_08979567_ASSET.readall(),
    },
    "f": {
        "name": "Foxtrot",
        "flag": IMG_25fcc367_ASSET.readall(),
    },
    "g": {
        "name": "Golf",
        "flag": IMG_7f3dbd31_ASSET.readall(),
    },
    "h": {
        "name": "Hotel",
        "flag": IMG_7c5621d7_ASSET.readall(),
    },
    "i": {
        "name": "India",
        "flag": IMG_09cd1795_ASSET.readall(),
    },
    "j": {
        "name": "Juliet",
        "flag": IMG_e3a1208f_ASSET.readall(),
    },
    "k": {
        "name": "Kilo",
        "flag": IMG_b7149aab_ASSET.readall(),
    },
    "l": {
        "name": "Lima",
        "flag": IMG_e1955924_ASSET.readall(),
    },
    "m": {
        "name": "Mike",
        "flag": IMG_5ad5c86f_ASSET.readall(),
    },
    "n": {
        "name": "November",
        "flag": IMG_e0d88004_ASSET.readall(),
    },
    "o": {
        "name": "Oscar",
        "flag": IMG_4fe5ac8e_ASSET.readall(),
    },
    "p": {
        "name": "Papa",
        "flag": IMG_b6768953_ASSET.readall(),
    },
    "q": {
        "name": "Quebec",
        "flag": IMG_0ce6b50c_ASSET.readall(),
    },
    "r": {
        "name": "Romeo",
        "flag": IMG_2b3e1c33_ASSET.readall(),
    },
    "s": {
        "name": "Sierra",
        "flag": IMG_06d41a6e_ASSET.readall(),
    },
    "t": {
        "name": "Tango",
        "flag": IMG_fb9eb262_ASSET.readall(),
    },
    "u": {
        "name": "Uniform",
        "flag": IMG_707f5c87_ASSET.readall(),
    },
    "v": {
        "name": "Victor",
        "flag": IMG_696b45aa_ASSET.readall(),
    },
    "w": {
        "name": "Whiskey",
        "flag": IMG_d9c20f83_ASSET.readall(),
    },
    "x": {
        "name": "X-ray",
        "flag": IMG_10321aaa_ASSET.readall(),
    },
    "y": {
        "name": "Yankee",
        "flag": IMG_1e4dd24f_ASSET.readall(),
    },
    "z": {
        "name": "Zulu",
        "flag": IMG_ede0610f_ASSET.readall(),
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
        children.append(render.Image(width = 32, height = 32, src = base64.decode(flags[" "]["flag"])))

    text = text.lower()
    for i in range(0, len(text)):
        if text[i] in flags:
            children.append(render.Image(width = 32, height = 32, src = base64.decode(flags[text[i]]["flag"])))

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
