"""
Applet: Super Mario Kart
Summary: Super Mario Kart Animation
Description: Animated characters & items from the 1992 Super Mario Kart game.
Author: Kevin Connell
"""

load("encoding/base64.star", "base64")
load("images/smk_generic_1.png", SMK_GENERIC_1_ASSET = "file")
load("images/smk_generic_10.png", SMK_GENERIC_10_ASSET = "file")
load("images/smk_generic_11.png", SMK_GENERIC_11_ASSET = "file")
load("images/smk_generic_12.png", SMK_GENERIC_12_ASSET = "file")
load("images/smk_generic_13.png", SMK_GENERIC_13_ASSET = "file")
load("images/smk_generic_14.png", SMK_GENERIC_14_ASSET = "file")
load("images/smk_generic_2.png", SMK_GENERIC_2_ASSET = "file")
load("images/smk_generic_3.png", SMK_GENERIC_3_ASSET = "file")
load("images/smk_generic_4.png", SMK_GENERIC_4_ASSET = "file")
load("images/smk_generic_5.png", SMK_GENERIC_5_ASSET = "file")
load("images/smk_generic_6.png", SMK_GENERIC_6_ASSET = "file")
load("images/smk_generic_7.png", SMK_GENERIC_7_ASSET = "file")
load("images/smk_generic_8.png", SMK_GENERIC_8_ASSET = "file")
load("images/smk_generic_9.png", SMK_GENERIC_9_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CHARACTER_LIST = {
    "Mario": "mario",
    "Peach": "peach",
    "Bowser": "bowser",
    "Toad": "toad",
    "Koopa": "koopa",
    "Donkey Kong": "dk",
    "Yoshi": "yoshi",
    "Luigi": "luigi",
    "Random": "random",
}

def main(config):
    seed = int(time.now().unix)
    seed = [seed]

    character_id = config.get("character")

    #Gets random character animation
    if character_id == "random":
        character_id = CHARACTER_LIST.values()[rand(seed, len(CHARACTER_LIST) - 1)]

    #Gets frames for animation based on the character selected
    if character_id == "peach":
        FRAMES = [
            SMK_GENERIC_13_ASSET.readall(),
            SMK_GENERIC_1_ASSET.readall(),
            SMK_GENERIC_10_ASSET.readall(),
            SMK_GENERIC_7_ASSET.readall(),
            SMK_GENERIC_14_ASSET.readall(),
            SMK_GENERIC_12_ASSET.readall(),
            SMK_GENERIC_8_ASSET.readall(),
            SMK_GENERIC_3_ASSET.readall(),
            SMK_GENERIC_5_ASSET.readall(),
            SMK_GENERIC_2_ASSET.readall(),
            SMK_GENERIC_4_ASSET.readall(),
            SMK_GENERIC_11_ASSET.readall(),
            SMK_GENERIC_9_ASSET.readall(),
            SMK_GENERIC_6_ASSET.readall(),
        ]

    elif character_id == "bowser":
        FRAMES = [
            BOWSER_FRAME_1_ASSET.readall(),
            BOWSER_FRAME_2_ASSET.readall(),
            BOWSER_FRAME_3_ASSET.readall(),
            BOWSER_FRAME_4_ASSET.readall(),
            BOWSER_FRAME_5_ASSET.readall(),
            BOWSER_FRAME_6_ASSET.readall(),
            BOWSER_FRAME_7_ASSET.readall(),
            BOWSER_FRAME_8_ASSET.readall(),
            BOWSER_FRAME_9_ASSET.readall(),
            BOWSER_FRAME_10_ASSET.readall(),
            BOWSER_FRAME_11_ASSET.readall(),
            BOWSER_FRAME_12_ASSET.readall(),
            BOWSER_FRAME_13_ASSET.readall(),
            BOWSER_FRAME_14_ASSET.readall(),
        ]

    elif character_id == "toad":
        FRAMES = [
            TOAD_FRAME_1_ASSET.readall(),
            TOAD_FRAME_2_ASSET.readall(),
            TOAD_FRAME_3_ASSET.readall(),
            TOAD_FRAME_4_ASSET.readall(),
            TOAD_FRAME_5_ASSET.readall(),
            TOAD_FRAME_6_ASSET.readall(),
            TOAD_FRAME_7_ASSET.readall(),
            TOAD_FRAME_8_ASSET.readall(),
            TOAD_FRAME_9_ASSET.readall(),
            TOAD_FRAME_10_ASSET.readall(),
            TOAD_FRAME_11_ASSET.readall(),
            TOAD_FRAME_12_ASSET.readall(),
            TOAD_FRAME_13_ASSET.readall(),
            TOAD_FRAME_14_ASSET.readall(),
        ]

    elif character_id == "koopa":
        FRAMES = [
            KOOPA_FRAME_1_ASSET.readall(),
            KOOPA_FRAME_2_ASSET.readall(),
            KOOPA_FRAME_3_ASSET.readall(),
            KOOPA_FRAME_4_ASSET.readall(),
            KOOPA_FRAME_5_ASSET.readall(),
            KOOPA_FRAME_6_ASSET.readall(),
            KOOPA_FRAME_7_ASSET.readall(),
            KOOPA_FRAME_8_ASSET.readall(),
            KOOPA_FRAME_9_ASSET.readall(),
            KOOPA_FRAME_10_ASSET.readall(),
            KOOPA_FRAME_11_ASSET.readall(),
            KOOPA_FRAME_12_ASSET.readall(),
            KOOPA_FRAME_13_ASSET.readall(),
            KOOPA_FRAME_14_ASSET.readall(),
        ]

    elif character_id == "dk":
        FRAMES = [
            DK_FRAME_1_ASSET.readall(),
            DK_FRAME_2_ASSET.readall(),
            DK_FRAME_3_ASSET.readall(),
            DK_FRAME_4_ASSET.readall(),
            DK_FRAME_5_ASSET.readall(),
            DK_FRAME_6_ASSET.readall(),
            DK_FRAME_7_ASSET.readall(),
            DK_FRAME_8_ASSET.readall(),
            DK_FRAME_9_ASSET.readall(),
            DK_FRAME_10_ASSET.readall(),
            DK_FRAME_11_ASSET.readall(),
            DK_FRAME_12_ASSET.readall(),
            DK_FRAME_13_ASSET.readall(),
            DK_FRAME_14_ASSET.readall(),
        ]

    elif character_id == "yoshi":
        FRAMES = [
            YOSHI_FRAME_1_ASSET.readall(),
            YOSHI_FRAME_2_ASSET.readall(),
            YOSHI_FRAME_3_ASSET.readall(),
            YOSHI_FRAME_4_ASSET.readall(),
            YOSHI_FRAME_5_ASSET.readall(),
            YOSHI_FRAME_6_ASSET.readall(),
            YOSHI_FRAME_7_ASSET.readall(),
            YOSHI_FRAME_8_ASSET.readall(),
            YOSHI_FRAME_9_ASSET.readall(),
            YOSHI_FRAME_10_ASSET.readall(),
            YOSHI_FRAME_11_ASSET.readall(),
            YOSHI_FRAME_12_ASSET.readall(),
            YOSHI_FRAME_13_ASSET.readall(),
            YOSHI_FRAME_14_ASSET.readall(),
        ]

    elif character_id == "luigi":
        FRAMES = [
            LUIGI_FRAME_1_ASSET.readall(),
            LUIGI_FRAME_2_ASSET.readall(),
            LUIGI_FRAME_3_ASSET.readall(),
            LUIGI_FRAME_4_ASSET.readall(),
            LUIGI_FRAME_5_ASSET.readall(),
            LUIGI_FRAME_6_ASSET.readall(),
            LUIGI_FRAME_7_ASSET.readall(),
            LUIGI_FRAME_8_ASSET.readall(),
            LUIGI_FRAME_9_ASSET.readall(),
            LUIGI_FRAME_10_ASSET.readall(),
            LUIGI_FRAME_11_ASSET.readall(),
            LUIGI_FRAME_12_ASSET.readall(),
            LUIGI_FRAME_13_ASSET.readall(),
            LUIGI_FRAME_14_ASSET.readall(),
        ]

    else:  #Default: Mario
        FRAMES = [
            MARIO_FRAME_1_ASSET.readall(),
            MARIO_FRAME_2_ASSET.readall(),
            MARIO_FRAME_3_ASSET.readall(),
            MARIO_FRAME_4_ASSET.readall(),
            MARIO_FRAME_5_ASSET.readall(),
            MARIO_FRAME_6_ASSET.readall(),
            MARIO_FRAME_7_ASSET.readall(),
            MARIO_FRAME_8_ASSET.readall(),
            MARIO_FRAME_9_ASSET.readall(),
            MARIO_FRAME_10_ASSET.readall(),
            MARIO_FRAME_11_ASSET.readall(),
            MARIO_FRAME_12_ASSET.readall(),
            MARIO_FRAME_13_ASSET.readall(),
            MARIO_FRAME_14_ASSET.readall(),
        ]

    return render.Root(
        child = render.Animation(
            children = [render.Image(src = base64.decode(f)) for f in FRAMES],
        ),
        delay = 125,
    )

def rand(seed, max):
    seed[0] = (seed[0] * 1103515245 + 12345) & 0xffffffff
    return (seed[0] >> 16) % max

def get_schema():
    character_options = [
        schema.Option(display = key, value = value)
        for key, value in CHARACTER_LIST.items()
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "character",
                name = "Super Mario Characters",
                desc = "Select a Character",
                icon = "gear",
                default = character_options[0].value,
                options = character_options,
            ),
        ],
    )
