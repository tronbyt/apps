"""
Applet: Super Mario Kart
Summary: Super Mario Kart Animation
Description: Animated characters & items from the 1992 Super Mario Kart game.
Author: Kevin Connell
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/img_007ec3af.png", IMG_007ec3af_ASSET = "file")
load("images/img_029c428b.png", IMG_029c428b_ASSET = "file")
load("images/img_031b5697.png", IMG_031b5697_ASSET = "file")
load("images/img_032d4505.png", IMG_032d4505_ASSET = "file")
load("images/img_03d89056.png", IMG_03d89056_ASSET = "file")
load("images/img_064ccfc1.png", IMG_064ccfc1_ASSET = "file")
load("images/img_06912528.png", IMG_06912528_ASSET = "file")
load("images/img_07259643.png", IMG_07259643_ASSET = "file")
load("images/img_0a8e48fc.png", IMG_0a8e48fc_ASSET = "file")
load("images/img_0c6dbaee.png", IMG_0c6dbaee_ASSET = "file")
load("images/img_0d1fabb1.png", IMG_0d1fabb1_ASSET = "file")
load("images/img_114265f6.png", IMG_114265f6_ASSET = "file")
load("images/img_121cf711.png", IMG_121cf711_ASSET = "file")
load("images/img_16aba0c2.png", IMG_16aba0c2_ASSET = "file")
load("images/img_16e1daf4.png", IMG_16e1daf4_ASSET = "file")
load("images/img_186f4bf7.png", IMG_186f4bf7_ASSET = "file")
load("images/img_198b3665.png", IMG_198b3665_ASSET = "file")
load("images/img_1ba27eb5.png", IMG_1ba27eb5_ASSET = "file")
load("images/img_1e6e13a1.png", IMG_1e6e13a1_ASSET = "file")
load("images/img_216e8866.png", IMG_216e8866_ASSET = "file")
load("images/img_25d4d7d8.png", IMG_25d4d7d8_ASSET = "file")
load("images/img_28203010.png", IMG_28203010_ASSET = "file")
load("images/img_2d71d90e.png", IMG_2d71d90e_ASSET = "file")
load("images/img_2dffa9d2.png", IMG_2dffa9d2_ASSET = "file")
load("images/img_31bf7f8e.png", IMG_31bf7f8e_ASSET = "file")
load("images/img_32da92e2.png", IMG_32da92e2_ASSET = "file")
load("images/img_338ca150.png", IMG_338ca150_ASSET = "file")
load("images/img_33cb541b.png", IMG_33cb541b_ASSET = "file")
load("images/img_35123530.png", IMG_35123530_ASSET = "file")
load("images/img_3532d48e.png", IMG_3532d48e_ASSET = "file")
load("images/img_3585a1f1.png", IMG_3585a1f1_ASSET = "file")
load("images/img_368da659.png", IMG_368da659_ASSET = "file")
load("images/img_381e73de.png", IMG_381e73de_ASSET = "file")
load("images/img_385bc34e.png", IMG_385bc34e_ASSET = "file")
load("images/img_388c64a0.png", IMG_388c64a0_ASSET = "file")
load("images/img_3aba9437.png", IMG_3aba9437_ASSET = "file")
load("images/img_3c47c904.png", IMG_3c47c904_ASSET = "file")
load("images/img_3d99e7a8.png", IMG_3d99e7a8_ASSET = "file")
load("images/img_3e37d9bb.png", IMG_3e37d9bb_ASSET = "file")
load("images/img_4179bcaa.png", IMG_4179bcaa_ASSET = "file")
load("images/img_43433611.png", IMG_43433611_ASSET = "file")
load("images/img_43d89510.png", IMG_43d89510_ASSET = "file")
load("images/img_4a67538d.png", IMG_4a67538d_ASSET = "file")
load("images/img_4b311ffb.png", IMG_4b311ffb_ASSET = "file")
load("images/img_4c7b751d.png", IMG_4c7b751d_ASSET = "file")
load("images/img_52763f2f.png", IMG_52763f2f_ASSET = "file")
load("images/img_531293a3.png", IMG_531293a3_ASSET = "file")
load("images/img_54d8fb16.png", IMG_54d8fb16_ASSET = "file")
load("images/img_5b2aa21f.png", IMG_5b2aa21f_ASSET = "file")
load("images/img_5f236294.png", IMG_5f236294_ASSET = "file")
load("images/img_632656aa.png", IMG_632656aa_ASSET = "file")
load("images/img_64e03ee2.png", IMG_64e03ee2_ASSET = "file")
load("images/img_67658d38.png", IMG_67658d38_ASSET = "file")
load("images/img_6eaa383d.png", IMG_6eaa383d_ASSET = "file")
load("images/img_70c89813.png", IMG_70c89813_ASSET = "file")
load("images/img_7520936e.png", IMG_7520936e_ASSET = "file")
load("images/img_771297f9.png", IMG_771297f9_ASSET = "file")
load("images/img_7dc10722.png", IMG_7dc10722_ASSET = "file")
load("images/img_7ffd88ae.png", IMG_7ffd88ae_ASSET = "file")
load("images/img_81977005.png", IMG_81977005_ASSET = "file")
load("images/img_82705ccb.png", IMG_82705ccb_ASSET = "file")
load("images/img_8706acf7.png", IMG_8706acf7_ASSET = "file")
load("images/img_89524f31.png", IMG_89524f31_ASSET = "file")
load("images/img_8e565c98.png", IMG_8e565c98_ASSET = "file")
load("images/img_90d82637.png", IMG_90d82637_ASSET = "file")
load("images/img_9182b4d4.png", IMG_9182b4d4_ASSET = "file")
load("images/img_919e1a31.png", IMG_919e1a31_ASSET = "file")
load("images/img_92e00dba.png", IMG_92e00dba_ASSET = "file")
load("images/img_9327e475.png", IMG_9327e475_ASSET = "file")
load("images/img_98aa1785.png", IMG_98aa1785_ASSET = "file")
load("images/img_99b459a7.png", IMG_99b459a7_ASSET = "file")
load("images/img_9a3cee4d.png", IMG_9a3cee4d_ASSET = "file")
load("images/img_9be7a069.png", IMG_9be7a069_ASSET = "file")
load("images/img_9c648764.png", IMG_9c648764_ASSET = "file")
load("images/img_9cf63590.png", IMG_9cf63590_ASSET = "file")
load("images/img_9ebe2ca1.png", IMG_9ebe2ca1_ASSET = "file")
load("images/img_a2bbb391.png", IMG_a2bbb391_ASSET = "file")
load("images/img_a9eb0e7d.png", IMG_a9eb0e7d_ASSET = "file")
load("images/img_aaff4fcb.png", IMG_aaff4fcb_ASSET = "file")
load("images/img_ab02488e.png", IMG_ab02488e_ASSET = "file")
load("images/img_ab8e45a8.png", IMG_ab8e45a8_ASSET = "file")
load("images/img_b1ab07c1.png", IMG_b1ab07c1_ASSET = "file")
load("images/img_b37bc56c.png", IMG_b37bc56c_ASSET = "file")
load("images/img_b54e2fb2.png", IMG_b54e2fb2_ASSET = "file")
load("images/img_b561fa18.png", IMG_b561fa18_ASSET = "file")
load("images/img_b7859973.png", IMG_b7859973_ASSET = "file")
load("images/img_b7f81634.png", IMG_b7f81634_ASSET = "file")
load("images/img_b8e8a433.png", IMG_b8e8a433_ASSET = "file")
load("images/img_bec624e0.png", IMG_bec624e0_ASSET = "file")
load("images/img_c0c724c8.png", IMG_c0c724c8_ASSET = "file")
load("images/img_c2962012.png", IMG_c2962012_ASSET = "file")
load("images/img_c29c23cf.png", IMG_c29c23cf_ASSET = "file")
load("images/img_c7132eca.png", IMG_c7132eca_ASSET = "file")
load("images/img_d04c57d7.png", IMG_d04c57d7_ASSET = "file")
load("images/img_d46162dc.png", IMG_d46162dc_ASSET = "file")
load("images/img_d88be0b3.png", IMG_d88be0b3_ASSET = "file")
load("images/img_d8c3cfe6.png", IMG_d8c3cfe6_ASSET = "file")
load("images/img_db38d4ae.png", IMG_db38d4ae_ASSET = "file")
load("images/img_dcef5d65.png", IMG_dcef5d65_ASSET = "file")
load("images/img_de8b2744.png", IMG_de8b2744_ASSET = "file")
load("images/img_e43b8e85.png", IMG_e43b8e85_ASSET = "file")
load("images/img_e565610b.png", IMG_e565610b_ASSET = "file")
load("images/img_eb24bc2a.png", IMG_eb24bc2a_ASSET = "file")
load("images/img_eb58b05a.png", IMG_eb58b05a_ASSET = "file")
load("images/img_ed37bbe3.png", IMG_ed37bbe3_ASSET = "file")
load("images/img_ee23d865.png", IMG_ee23d865_ASSET = "file")
load("images/img_f0994452.png", IMG_f0994452_ASSET = "file")
load("images/img_f4406707.png", IMG_f4406707_ASSET = "file")
load("images/img_f6545bfb.png", IMG_f6545bfb_ASSET = "file")
load("images/img_fbdbdd6d.png", IMG_fbdbdd6d_ASSET = "file")
load("images/img_fd16d45f.png", IMG_fd16d45f_ASSET = "file")
load("images/img_fd88d243.png", IMG_fd88d243_ASSET = "file")

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
            IMG_c29c23cf_ASSET.readall(),
            IMG_029c428b_ASSET.readall(),
            IMG_a2bbb391_ASSET.readall(),
            IMG_70c89813_ASSET.readall(),
            IMG_f4406707_ASSET.readall(),
            IMG_b7859973_ASSET.readall(),
            IMG_8e565c98_ASSET.readall(),
            IMG_33cb541b_ASSET.readall(),
            IMG_5f236294_ASSET.readall(),
            IMG_2d71d90e_ASSET.readall(),
            IMG_43433611_ASSET.readall(),
            IMG_b54e2fb2_ASSET.readall(),
            IMG_9be7a069_ASSET.readall(),
            IMG_67658d38_ASSET.readall(),
        ]

    elif character_id == "bowser":
        FRAMES = [
            IMG_03d89056_ASSET.readall(),
            IMG_9cf63590_ASSET.readall(),
            IMG_aaff4fcb_ASSET.readall(),
            IMG_54d8fb16_ASSET.readall(),
            IMG_d88be0b3_ASSET.readall(),
            IMG_b8e8a433_ASSET.readall(),
            IMG_007ec3af_ASSET.readall(),
            IMG_f0994452_ASSET.readall(),
            IMG_031b5697_ASSET.readall(),
            IMG_92e00dba_ASSET.readall(),
            IMG_121cf711_ASSET.readall(),
            IMG_89524f31_ASSET.readall(),
            IMG_9327e475_ASSET.readall(),
            IMG_ed37bbe3_ASSET.readall(),
        ]

    elif character_id == "toad":
        FRAMES = [
            IMG_c7132eca_ASSET.readall(),
            IMG_d8c3cfe6_ASSET.readall(),
            IMG_28203010_ASSET.readall(),
            IMG_fd16d45f_ASSET.readall(),
            IMG_ee23d865_ASSET.readall(),
            IMG_a9eb0e7d_ASSET.readall(),
            IMG_d46162dc_ASSET.readall(),
            IMG_4c7b751d_ASSET.readall(),
            IMG_fbdbdd6d_ASSET.readall(),
            IMG_368da659_ASSET.readall(),
            IMG_82705ccb_ASSET.readall(),
            IMG_e43b8e85_ASSET.readall(),
            IMG_5b2aa21f_ASSET.readall(),
            IMG_216e8866_ASSET.readall(),
        ]

    elif character_id == "koopa":
        FRAMES = [
            IMG_3c47c904_ASSET.readall(),
            IMG_064ccfc1_ASSET.readall(),
            IMG_6eaa383d_ASSET.readall(),
            IMG_0c6dbaee_ASSET.readall(),
            IMG_198b3665_ASSET.readall(),
            IMG_0d1fabb1_ASSET.readall(),
            IMG_b561fa18_ASSET.readall(),
            IMG_4a67538d_ASSET.readall(),
            IMG_ab8e45a8_ASSET.readall(),
            IMG_c0c724c8_ASSET.readall(),
            IMG_25d4d7d8_ASSET.readall(),
            IMG_186f4bf7_ASSET.readall(),
            IMG_ab02488e_ASSET.readall(),
            IMG_32da92e2_ASSET.readall(),
        ]

    elif character_id == "dk":
        FRAMES = [
            IMG_388c64a0_ASSET.readall(),
            IMG_16e1daf4_ASSET.readall(),
            IMG_9ebe2ca1_ASSET.readall(),
            IMG_16aba0c2_ASSET.readall(),
            IMG_3585a1f1_ASSET.readall(),
            IMG_64e03ee2_ASSET.readall(),
            IMG_1e6e13a1_ASSET.readall(),
            IMG_f6545bfb_ASSET.readall(),
            IMG_919e1a31_ASSET.readall(),
            IMG_52763f2f_ASSET.readall(),
            IMG_b37bc56c_ASSET.readall(),
            IMG_9a3cee4d_ASSET.readall(),
            IMG_9c648764_ASSET.readall(),
            IMG_d04c57d7_ASSET.readall(),
        ]

    elif character_id == "yoshi":
        FRAMES = [
            IMG_1ba27eb5_ASSET.readall(),
            IMG_114265f6_ASSET.readall(),
            IMG_9182b4d4_ASSET.readall(),
            IMG_3e37d9bb_ASSET.readall(),
            IMG_99b459a7_ASSET.readall(),
            IMG_e565610b_ASSET.readall(),
            IMG_eb24bc2a_ASSET.readall(),
            IMG_dcef5d65_ASSET.readall(),
            IMG_385bc34e_ASSET.readall(),
            IMG_7dc10722_ASSET.readall(),
            IMG_c2962012_ASSET.readall(),
            IMG_3532d48e_ASSET.readall(),
            IMG_bec624e0_ASSET.readall(),
            IMG_2dffa9d2_ASSET.readall(),
        ]

    elif character_id == "luigi":
        FRAMES = [
            IMG_90d82637_ASSET.readall(),
            IMG_531293a3_ASSET.readall(),
            IMG_3d99e7a8_ASSET.readall(),
            IMG_07259643_ASSET.readall(),
            IMG_4179bcaa_ASSET.readall(),
            IMG_7ffd88ae_ASSET.readall(),
            IMG_3aba9437_ASSET.readall(),
            IMG_35123530_ASSET.readall(),
            IMG_338ca150_ASSET.readall(),
            IMG_43d89510_ASSET.readall(),
            IMG_de8b2744_ASSET.readall(),
            IMG_7520936e_ASSET.readall(),
            IMG_31bf7f8e_ASSET.readall(),
            IMG_4b311ffb_ASSET.readall(),
        ]

    else:  #Default: Mario
        FRAMES = [
            IMG_b7f81634_ASSET.readall(),
            IMG_032d4505_ASSET.readall(),
            IMG_381e73de_ASSET.readall(),
            IMG_0a8e48fc_ASSET.readall(),
            IMG_eb58b05a_ASSET.readall(),
            IMG_fd88d243_ASSET.readall(),
            IMG_b1ab07c1_ASSET.readall(),
            IMG_8706acf7_ASSET.readall(),
            IMG_632656aa_ASSET.readall(),
            IMG_81977005_ASSET.readall(),
            IMG_771297f9_ASSET.readall(),
            IMG_db38d4ae_ASSET.readall(),
            IMG_06912528_ASSET.readall(),
            IMG_98aa1785_ASSET.readall(),
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
