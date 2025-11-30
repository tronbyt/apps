"""
Applet: NES Clock
Summary: NES Game Themed Clock
Description: Short animations of various Nintendo characters with a clock in the background.
Author: hx009
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("images/smb3_colon_img.png", SMB3_COLON_IMG_ASSET = "file")
load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/img_019b1534.png", IMG_019b1534_ASSET = "file")
load("images/img_01f81e5e.png", IMG_01f81e5e_ASSET = "file")
load("images/img_02b8a170.png", IMG_02b8a170_ASSET = "file")
load("images/img_05bb1cfc.png", IMG_05bb1cfc_ASSET = "file")
load("images/img_06c5812e.png", IMG_06c5812e_ASSET = "file")
load("images/img_07679ad5.png", IMG_07679ad5_ASSET = "file")
load("images/img_09e3b7ca.png", IMG_09e3b7ca_ASSET = "file")
load("images/img_0a2d9c6b.png", IMG_0a2d9c6b_ASSET = "file")
load("images/img_0a7ca2ef.png", IMG_0a7ca2ef_ASSET = "file")
load("images/img_0b65e38a.png", IMG_0b65e38a_ASSET = "file")
load("images/img_0fb7fb12.png", IMG_0fb7fb12_ASSET = "file")
load("images/img_11c267b3.png", IMG_11c267b3_ASSET = "file")
load("images/img_12973e97.png", IMG_12973e97_ASSET = "file")
load("images/img_1dfebfa8.png", IMG_1dfebfa8_ASSET = "file")
load("images/img_2431d478.png", IMG_2431d478_ASSET = "file")
load("images/img_26eadb44.png", IMG_26eadb44_ASSET = "file")
load("images/img_2921da27.png", IMG_2921da27_ASSET = "file")
load("images/img_2bcae432.png", IMG_2bcae432_ASSET = "file")
load("images/img_2f62d7ef.png", IMG_2f62d7ef_ASSET = "file")
load("images/img_2ff77c1a.png", IMG_2ff77c1a_ASSET = "file")
load("images/img_31b786ba.png", IMG_31b786ba_ASSET = "file")
load("images/img_31d445e8.png", IMG_31d445e8_ASSET = "file")
load("images/img_33bda527.png", IMG_33bda527_ASSET = "file")
load("images/img_360704ba.png", IMG_360704ba_ASSET = "file")
load("images/img_37435224.png", IMG_37435224_ASSET = "file")
load("images/img_3746fb9e.png", IMG_3746fb9e_ASSET = "file")
load("images/img_38925660.png", IMG_38925660_ASSET = "file")
load("images/img_418cd57d.png", IMG_418cd57d_ASSET = "file")
load("images/img_44a8301b.png", IMG_44a8301b_ASSET = "file")
load("images/img_480fd046.png", IMG_480fd046_ASSET = "file")
load("images/img_4a8f0074.png", IMG_4a8f0074_ASSET = "file")
load("images/img_4c3e17b4.png", IMG_4c3e17b4_ASSET = "file")
load("images/img_4c76a818.png", IMG_4c76a818_ASSET = "file")
load("images/img_503d9e02.png", IMG_503d9e02_ASSET = "file")
load("images/img_53869b3a.png", IMG_53869b3a_ASSET = "file")
load("images/img_572b3c68.png", IMG_572b3c68_ASSET = "file")
load("images/img_59c02290.png", IMG_59c02290_ASSET = "file")
load("images/img_5bb2b7a6.png", IMG_5bb2b7a6_ASSET = "file")
load("images/img_6701b8af.png", IMG_6701b8af_ASSET = "file")
load("images/img_67b64e06.png", IMG_67b64e06_ASSET = "file")
load("images/img_67e31060.png", IMG_67e31060_ASSET = "file")
load("images/img_68335b06.png", IMG_68335b06_ASSET = "file")
load("images/img_68acd74d.png", IMG_68acd74d_ASSET = "file")
load("images/img_6af5bf4c.png", IMG_6af5bf4c_ASSET = "file")
load("images/img_6cc18832.png", IMG_6cc18832_ASSET = "file")
load("images/img_6cd55f5c.png", IMG_6cd55f5c_ASSET = "file")
load("images/img_6df90569.png", IMG_6df90569_ASSET = "file")
load("images/img_6fd19ab3.png", IMG_6fd19ab3_ASSET = "file")
load("images/img_730176c3.png", IMG_730176c3_ASSET = "file")
load("images/img_73bbf92a.png", IMG_73bbf92a_ASSET = "file")
load("images/img_75184f40.png", IMG_75184f40_ASSET = "file")
load("images/img_76ce9345.png", IMG_76ce9345_ASSET = "file")
load("images/img_7a5f0736.png", IMG_7a5f0736_ASSET = "file")
load("images/img_7cecc161.png", IMG_7cecc161_ASSET = "file")
load("images/img_8024c415.png", IMG_8024c415_ASSET = "file")
load("images/img_80519bc0.png", IMG_80519bc0_ASSET = "file")
load("images/img_8141ea11.png", IMG_8141ea11_ASSET = "file")
load("images/img_81cf28ea.png", IMG_81cf28ea_ASSET = "file")
load("images/img_81dcc3fc.png", IMG_81dcc3fc_ASSET = "file")
load("images/img_81f7110b.png", IMG_81f7110b_ASSET = "file")
load("images/img_81f970b9.png", IMG_81f970b9_ASSET = "file")
load("images/img_84709572.png", IMG_84709572_ASSET = "file")
load("images/img_8474d7e3.png", IMG_8474d7e3_ASSET = "file")
load("images/img_84d86b71.png", IMG_84d86b71_ASSET = "file")
load("images/img_89843bb5.png", IMG_89843bb5_ASSET = "file")
load("images/img_8a5f4770.png", IMG_8a5f4770_ASSET = "file")
load("images/img_8c12eb3c.png", IMG_8c12eb3c_ASSET = "file")
load("images/img_8fa3dfa7.png", IMG_8fa3dfa7_ASSET = "file")
load("images/img_909b1d3c.png", IMG_909b1d3c_ASSET = "file")
load("images/img_912200d9.png", IMG_912200d9_ASSET = "file")
load("images/img_92305251.png", IMG_92305251_ASSET = "file")
load("images/img_92883064.png", IMG_92883064_ASSET = "file")
load("images/img_9348be0a.png", IMG_9348be0a_ASSET = "file")
load("images/img_9386a9b2.png", IMG_9386a9b2_ASSET = "file")
load("images/img_951ecb98.png", IMG_951ecb98_ASSET = "file")
load("images/img_96fc27d4.png", IMG_96fc27d4_ASSET = "file")
load("images/img_979df11a.png", IMG_979df11a_ASSET = "file")
load("images/img_9895f339.png", IMG_9895f339_ASSET = "file")
load("images/img_98d2bfd3.png", IMG_98d2bfd3_ASSET = "file")
load("images/img_98f761fb.png", IMG_98f761fb_ASSET = "file")
load("images/img_9b09996f.png", IMG_9b09996f_ASSET = "file")
load("images/img_9b56379e.png", IMG_9b56379e_ASSET = "file")
load("images/img_9d4af1ca.png", IMG_9d4af1ca_ASSET = "file")
load("images/img_9dbba56a.png", IMG_9dbba56a_ASSET = "file")
load("images/img_a4e152d4.png", IMG_a4e152d4_ASSET = "file")
load("images/img_a4f80e17.png", IMG_a4f80e17_ASSET = "file")
load("images/img_a5559e91.png", IMG_a5559e91_ASSET = "file")
load("images/img_a69639cf.png", IMG_a69639cf_ASSET = "file")
load("images/img_a6ba330e.png", IMG_a6ba330e_ASSET = "file")
load("images/img_a72f2008.png", IMG_a72f2008_ASSET = "file")
load("images/img_a8e470b2.png", IMG_a8e470b2_ASSET = "file")
load("images/img_a93ba4a0.png", IMG_a93ba4a0_ASSET = "file")
load("images/img_aaa1f330.png", IMG_aaa1f330_ASSET = "file")
load("images/img_abbe5b14.png", IMG_abbe5b14_ASSET = "file")
load("images/img_addc34de.png", IMG_addc34de_ASSET = "file")
load("images/img_affc823c.png", IMG_affc823c_ASSET = "file")
load("images/img_b5bffdbb.png", IMG_b5bffdbb_ASSET = "file")
load("images/img_b62e8d48.png", IMG_b62e8d48_ASSET = "file")
load("images/img_b7713dd7.png", IMG_b7713dd7_ASSET = "file")
load("images/img_ba1de49a.png", IMG_ba1de49a_ASSET = "file")
load("images/img_bd264dc1.png", IMG_bd264dc1_ASSET = "file")
load("images/img_c015fc36.png", IMG_c015fc36_ASSET = "file")
load("images/img_c169250e.png", IMG_c169250e_ASSET = "file")
load("images/img_c1dd6457.png", IMG_c1dd6457_ASSET = "file")
load("images/img_c2b3e096.png", IMG_c2b3e096_ASSET = "file")
load("images/img_c53969c2.png", IMG_c53969c2_ASSET = "file")
load("images/img_c604c127.png", IMG_c604c127_ASSET = "file")
load("images/img_c7c4821e.png", IMG_c7c4821e_ASSET = "file")
load("images/img_cd9d357c.png", IMG_cd9d357c_ASSET = "file")
load("images/img_d20e9db6.png", IMG_d20e9db6_ASSET = "file")
load("images/img_d3506872.png", IMG_d3506872_ASSET = "file")
load("images/img_d3caf80f.png", IMG_d3caf80f_ASSET = "file")
load("images/img_d477542e.png", IMG_d477542e_ASSET = "file")
load("images/img_d5909d94.png", IMG_d5909d94_ASSET = "file")
load("images/img_d60557d0.png", IMG_d60557d0_ASSET = "file")
load("images/img_d6937786.png", IMG_d6937786_ASSET = "file")
load("images/img_d85d44fe.png", IMG_d85d44fe_ASSET = "file")
load("images/img_e1005c11.png", IMG_e1005c11_ASSET = "file")
load("images/img_e146f208.png", IMG_e146f208_ASSET = "file")
load("images/img_e223a62b.png", IMG_e223a62b_ASSET = "file")
load("images/img_e6c9177a.png", IMG_e6c9177a_ASSET = "file")
load("images/img_e7087ce4.png", IMG_e7087ce4_ASSET = "file")
load("images/img_ef81a872.png", IMG_ef81a872_ASSET = "file")
load("images/img_f3df6310.png", IMG_f3df6310_ASSET = "file")
load("images/img_f483363d.png", IMG_f483363d_ASSET = "file")
load("images/img_f5f15aac.png", IMG_f5f15aac_ASSET = "file")
load("images/img_f75a2f8a.png", IMG_f75a2f8a_ASSET = "file")
load("images/img_f8e99fde.png", IMG_f8e99fde_ASSET = "file")
load("images/img_fbfae61b.png", IMG_fbfae61b_ASSET = "file")
load("images/img_fcfa1dcd.png", IMG_fcfa1dcd_ASSET = "file")
load("images/img_fda881c8.png", IMG_fda881c8_ASSET = "file")

SMB3_COLON_IMG = SMB3_COLON_IMG_ASSET.readall()

FRAME_HEIGHT = 32
FRAME_WIDTH = 64
DEFAULT_HAS_LEADING_ZERO = False
DEFAULT_IS_24_HOUR_FORMAT = False
DEFAULT_LOCATION = {
    "lat": 41.505550,
    "lng": -81.691498,
    "locality": "Cleveland, OH",
}
DEFAULT_GAME = "0"
DEFAULT_SPEED = "30"
DEFAULT_TIMEZONE = "US/Eastern"
MAX_SPEED = 10
MIN_SPEED = 50
SECONDS_TO_RENDER = 15
SPEED_LIST = {
    "Snail": "50",
    "Slow": "40",
    "Medium": "30",
    "Fast": "20",
    "Turbo": "10",
    "Random": "-1",
}

GAME_LIST = {
    "Random": "0",
    "Bionic Commando": "11",
    "Contra": "5",
    "Bubble Bobble": "9",
    "Castlevania": "14",
    "Chip 'n Dale: Rescue Rangers": "10",
    "Double Dragon": "15",
    "DuckTales": "8",
    "Excitebike": "6",
    "Final Fantasy": "13",
    "Kid Icarus": "12",
    "Kirby's Adventure": "3",
    "Little Nemo": "7",
    "Mega Man": "2",
    "Ninja Gaiden": "16",
    "Super Mario Bros. 3": "1",
    "The Legend of Zelda": "4",
}

GAME_CONFIGS = [
    {"SPRITE_WIDTH": 0, "DIST_BETWEEN_SPRITES": 0, "SPRITE_MIN_X": 0, "SPRITE_Y_POS": 0, "SPRITE_MOVE_SPEED": 0, "SPRITE_FRAMES_PER_FRAME": 0},
    # 1 - Super Mario Bros. 3
    {
        "BACKGROUND_IMGS": [
            IMG_a72f2008_ASSET.readall(),
            IMG_6cd55f5c_ASSET.readall(),
            IMG_d3506872_ASSET.readall(),
        ],
        "COLON_IMG": """""",
        "NUMBER_IMG_HEIGHT": 0,
        "NUMBER_IMG_WIDTH": 0,
        "NUMBER_IMGS": [],
        "SPRITE_WIDTH": 16,
        "DIST_BETWEEN_SPRITES": 10,
        "SPRITE_MIN_X": -42,
        "SPRITE_Y_POS": 10,
        "SPRITE_MOVE_SPEED": 1,
        "SPRITE_FRAMES_PER_FRAME": 1,
        "SPRITE_SETS": [
            [
                # Mario walking
                IMG_8024c415_ASSET.readall(),
                IMG_81cf28ea_ASSET.readall(),
            ],
            [
                # Mario swimming
                IMG_f483363d_ASSET.readall(),
                IMG_aaa1f330_ASSET.readall(),
                IMG_92883064_ASSET.readall(),
                IMG_9b56379e_ASSET.readall(),
            ],
        ],
    },
    # 2 - Mega Man
    {
        "BACKGROUND_IMGS": [
            IMG_76ce9345_ASSET.readall(),
        ],
        "COLON_IMG": """""",
        "NUMBER_IMG_HEIGHT": 0,
        "NUMBER_IMG_WIDTH": 0,
        "NUMBER_IMGS": [],
        "SPRITE_WIDTH": 24,
        "DIST_BETWEEN_SPRITES": 60,
        "SPRITE_MIN_X": -108,
        "SPRITE_Y_POS": 2,
        "SPRITE_MOVE_SPEED": 2,
        "SPRITE_FRAMES_PER_FRAME": 1,
        "SPRITE_SETS": [
            [
                # Mega Man
                IMG_d20e9db6_ASSET.readall(),
                IMG_418cd57d_ASSET.readall(),
                IMG_6701b8af_ASSET.readall(),
            ],
        ],
    },
    # 3 - Kirby's Adventure
    {
        "BACKGROUND_IMGS": [
            IMG_951ecb98_ASSET.readall(),
            IMG_979df11a_ASSET.readall(),
            IMG_9348be0a_ASSET.readall(),
        ],
        "COLON_IMG": """""",
        "NUMBER_IMG_HEIGHT": 0,
        "NUMBER_IMG_WIDTH": 0,
        "NUMBER_IMGS": [],
        "SPRITE_WIDTH": 16,
        "DIST_BETWEEN_SPRITES": 5,
        "SPRITE_MIN_X": -37,
        "SPRITE_Y_POS": 11,
        "SPRITE_MOVE_SPEED": 2,
        "SPRITE_FRAMES_PER_FRAME": 1,
        "SPRITE_SETS": [
            [
                # Kirby
                IMG_53869b3a_ASSET.readall(),
                IMG_84709572_ASSET.readall(),
                IMG_0a2d9c6b_ASSET.readall(),
                IMG_9b09996f_ASSET.readall(),
            ],
        ],
    },
    # 4 - The Legend of Zelda
    {
        "BACKGROUND_IMGS": [
            IMG_6af5bf4c_ASSET.readall(),
            IMG_0b65e38a_ASSET.readall(),
            IMG_c604c127_ASSET.readall(),
        ],
        "COLON_IMG": """""",
        "NUMBER_IMG_HEIGHT": 0,
        "NUMBER_IMG_WIDTH": 0,
        "NUMBER_IMGS": [],
        "SPRITE_WIDTH": 16,
        "DIST_BETWEEN_SPRITES": 10,
        "SPRITE_MIN_X": -42,
        "SPRITE_Y_POS": 8,
        "SPRITE_MOVE_SPEED": 1,
        "SPRITE_FRAMES_PER_FRAME": 1,
        "SPRITE_SETS": [
            [
                # Link
                IMG_730176c3_ASSET.readall(),
                IMG_59c02290_ASSET.readall(),
            ],
        ],
    },
    # 5 - Contra
    {
        "BACKGROUND_IMGS": [
            IMG_c7c4821e_ASSET.readall(),
            IMG_4c3e17b4_ASSET.readall(),
            IMG_02b8a170_ASSET.readall(),
        ],
        "COLON_IMG": IMG_c015fc36_ASSET.readall(),
        "NUMBER_IMG_HEIGHT": 7,
        "NUMBER_IMG_WIDTH": 7,
        "NUMBER_IMGS": [
            IMG_572b3c68_ASSET.readall(),
            IMG_33bda527_ASSET.readall(),
            IMG_a69639cf_ASSET.readall(),
            IMG_6df90569_ASSET.readall(),
            IMG_4a8f0074_ASSET.readall(),
            IMG_e1005c11_ASSET.readall(),
            IMG_98d2bfd3_ASSET.readall(),
            IMG_38925660_ASSET.readall(),
            IMG_7a5f0736_ASSET.readall(),
            IMG_f3df6310_ASSET.readall(),
        ],
        "SPRITE_WIDTH": 4,
        "DIST_BETWEEN_SPRITES": 10,
        "SPRITE_MIN_X": 19,
        "SPRITE_Y_POS": 17,
        "SPRITE_MOVE_SPEED": 5,
        "SPRITE_FRAMES_PER_FRAME": 1,
        "SPRITE_SETS": [
            [
                # A single bullet
                IMG_e146f208_ASSET.readall(),
            ],
        ],
    },
    # 6 - Excitebike
    {
        "BACKGROUND_IMGS": [
            IMG_31b786ba_ASSET.readall(),
            IMG_d6937786_ASSET.readall(),
            IMG_bd264dc1_ASSET.readall(),
        ],
        "COLON_IMG": """""",
        "NUMBER_IMG_HEIGHT": 0,
        "NUMBER_IMG_WIDTH": 0,
        "NUMBER_IMGS": [],
        "SPRITE_WIDTH": 20,
        "DIST_BETWEEN_SPRITES": 10,
        "SPRITE_MIN_X": -50,
        "SPRITE_Y_POS": 6,
        "SPRITE_MOVE_SPEED": 5,
        "SPRITE_FRAMES_PER_FRAME": 1,
        "SPRITE_SETS": [
            [
                IMG_d5909d94_ASSET.readall(),
                IMG_b5bffdbb_ASSET.readall(),
                IMG_73bbf92a_ASSET.readall(),
            ],
        ],
    },
    # 7 - Little Nemo
    {
        "BACKGROUND_IMGS": [
            IMG_44a8301b_ASSET.readall(),
            IMG_cd9d357c_ASSET.readall(),
        ],
        "COLON_IMG": """""",
        "NUMBER_IMG_HEIGHT": 0,
        "NUMBER_IMG_WIDTH": 0,
        "NUMBER_IMGS": [],
        "SPRITE_WIDTH": 20,
        "DIST_BETWEEN_SPRITES": 10,
        "SPRITE_MIN_X": -50,
        "SPRITE_Y_POS": 5,
        "SPRITE_MOVE_SPEED": 3,
        "SPRITE_FRAMES_PER_FRAME": 1,
        "SPRITE_SETS": [
            [
                # Nemo
                IMG_fda881c8_ASSET.readall(),
                IMG_26eadb44_ASSET.readall(),
                IMG_d85d44fe_ASSET.readall(),
            ],
        ],
    },
    # 8 - DuckTales
    {
        "BACKGROUND_IMGS": [
            IMG_6cc18832_ASSET.readall(),
            IMG_92305251_ASSET.readall(),
        ],
        "COLON_IMG": """""",
        "NUMBER_IMG_HEIGHT": 0,
        "NUMBER_IMG_WIDTH": 0,
        "NUMBER_IMGS": [],
        "SPRITE_WIDTH": 23,
        "DIST_BETWEEN_SPRITES": 10,
        "SPRITE_MIN_X": -56,
        "SPRITE_Y_POS": 1,
        "SPRITE_MOVE_SPEED": 5,
        "SPRITE_FRAMES_PER_FRAME": 1,
        "SPRITE_SETS": [
            [
                # Scrooge McDuck
                IMG_909b1d3c_ASSET.readall(),
                IMG_2bcae432_ASSET.readall(),
                IMG_05bb1cfc_ASSET.readall(),
            ],
        ],
    },
    # 9 - Bubble Bobble
    {
        "BACKGROUND_IMGS": [
            IMG_d3caf80f_ASSET.readall(),
            IMG_67e31060_ASSET.readall(),
            IMG_9d4af1ca_ASSET.readall(),
            IMG_68acd74d_ASSET.readall(),
        ],
        "COLON_IMG": IMG_0fb7fb12_ASSET.readall(),
        "NUMBER_IMG_HEIGHT": 8,
        "NUMBER_IMG_WIDTH": 4,
        "NUMBER_IMGS": [
            IMG_c53969c2_ASSET.readall(),
            IMG_e7087ce4_ASSET.readall(),
            IMG_affc823c_ASSET.readall(),
            IMG_4c76a818_ASSET.readall(),
            IMG_6fd19ab3_ASSET.readall(),
            IMG_2431d478_ASSET.readall(),
            IMG_e6c9177a_ASSET.readall(),
            IMG_c1dd6457_ASSET.readall(),
            IMG_37435224_ASSET.readall(),
            IMG_e223a62b_ASSET.readall(),
        ],
        "SPRITE_WIDTH": 16,
        "DIST_BETWEEN_SPRITES": 5,
        "SPRITE_MIN_X": -37,
        "SPRITE_Y_POS": 8,
        "SPRITE_MOVE_SPEED": 2,
        "SPRITE_FRAMES_PER_FRAME": 1,
        "SPRITE_SETS": [
            [
                # Bub
                IMG_ba1de49a_ASSET.readall(),
                IMG_8fa3dfa7_ASSET.readall(),
                IMG_480fd046_ASSET.readall(),
                IMG_360704ba_ASSET.readall(),
            ],
            [
                # Bob
                IMG_12973e97_ASSET.readall(),
                IMG_019b1534_ASSET.readall(),
                IMG_abbe5b14_ASSET.readall(),
                IMG_2f62d7ef_ASSET.readall(),
            ],
        ],
    },
    # 10 - Chip 'n Dale: Rescue Rangers
    {
        "BACKGROUND_IMGS": [
            IMG_01f81e5e_ASSET.readall(),
            IMG_2ff77c1a_ASSET.readall(),
            IMG_addc34de_ASSET.readall(),
        ],
        "COLON_IMG": """""",
        "NUMBER_IMG_HEIGHT": 0,
        "NUMBER_IMG_WIDTH": 0,
        "NUMBER_IMGS": [],
        "SPRITE_WIDTH": 18,
        "DIST_BETWEEN_SPRITES": 10,
        "SPRITE_MIN_X": -46,
        "SPRITE_Y_POS": 4,
        "SPRITE_MOVE_SPEED": 5,
        "SPRITE_FRAMES_PER_FRAME": 1,
        "SPRITE_SETS": [
            [
                # Chip
                IMG_3746fb9e_ASSET.readall(),
                IMG_31d445e8_ASSET.readall(),
                IMG_75184f40_ASSET.readall(),
            ],
            [
                # Dale
                IMG_b7713dd7_ASSET.readall(),
                IMG_06c5812e_ASSET.readall(),
                IMG_07679ad5_ASSET.readall(),
            ],
        ],
    },
    # 11 - Bionic Commando
    {
        "BACKGROUND_IMGS": [
            IMG_8474d7e3_ASSET.readall(),
            IMG_f8e99fde_ASSET.readall(),
        ],
        "COLON_IMG": """""",
        "NUMBER_IMG_HEIGHT": 0,
        "NUMBER_IMG_WIDTH": 0,
        "NUMBER_IMGS": [],
        "SPRITE_WIDTH": 7,
        "DIST_BETWEEN_SPRITES": 10,
        "SPRITE_MIN_X": 15,
        "SPRITE_Y_POS": 9,
        "SPRITE_MOVE_SPEED": 5,
        "SPRITE_FRAMES_PER_FRAME": 1,
        "SPRITE_SETS": [
            [
                # Ladd 'Rad' Spencer
                IMG_2921da27_ASSET.readall(),
            ],
        ],
    },
    # 12 - Kid Icarus
    {
        "BACKGROUND_IMGS": [
            IMG_f75a2f8a_ASSET.readall(),
            IMG_81f7110b_ASSET.readall(),
        ],
        "COLON_IMG": """""",
        "NUMBER_IMG_HEIGHT": 0,
        "NUMBER_IMG_WIDTH": 0,
        "NUMBER_IMGS": [],
        "SPRITE_WIDTH": 16,
        "DIST_BETWEEN_SPRITES": 5,
        "SPRITE_MIN_X": -37,
        "SPRITE_Y_POS": 4,
        "SPRITE_MOVE_SPEED": 2,
        "SPRITE_FRAMES_PER_FRAME": 1,
        "SPRITE_SETS": [
            [
                # Pit walking
                IMG_11c267b3_ASSET.readall(),
                IMG_81f970b9_ASSET.readall(),
                IMG_8a5f4770_ASSET.readall(),
            ],
        ],
    },
    # 13 - Final Fantasy
    {
        "BACKGROUND_IMGS": [
            IMG_a8e470b2_ASSET.readall(),
            IMG_a5559e91_ASSET.readall(),
        ],
        "COLON_IMG": """""",
        "NUMBER_IMG_HEIGHT": 0,
        "NUMBER_IMG_WIDTH": 0,
        "NUMBER_IMGS": [],
        "SPRITE_WIDTH": 16,
        "DIST_BETWEEN_SPRITES": 5,
        "SPRITE_MIN_X": -37,
        "SPRITE_Y_POS": 4,
        "SPRITE_MOVE_SPEED": 2,
        "SPRITE_FRAMES_PER_FRAME": 1,
        "SPRITE_SETS": [
            [
                # Light warrior red walking
                IMG_f5f15aac_ASSET.readall(),
                IMG_1dfebfa8_ASSET.readall(),
            ],
            [
                # Light warrior brown walking
                IMG_d477542e_ASSET.readall(),
                IMG_503d9e02_ASSET.readall(),
            ],
            [
                # Light warrior white walking
                IMG_8c12eb3c_ASSET.readall(),
                IMG_09e3b7ca_ASSET.readall(),
            ],
        ],
    },
    # 14 - Castlevania
    {
        "BACKGROUND_IMGS": [
            IMG_fbfae61b_ASSET.readall(),
            IMG_ef81a872_ASSET.readall(),
        ],
        "COLON_IMG": """""",
        "NUMBER_IMG_HEIGHT": 0,
        "NUMBER_IMG_WIDTH": 0,
        "NUMBER_IMGS": [],
        "SPRITE_WIDTH": 16,
        "DIST_BETWEEN_SPRITES": 5,
        "SPRITE_MIN_X": -42,
        "SPRITE_Y_POS": 0,
        "SPRITE_MOVE_SPEED": 4,
        "SPRITE_FRAMES_PER_FRAME": 1,
        "SPRITE_SETS": [
            [
                # Simon Belmont walking
                IMG_a6ba330e_ASSET.readall(),
                IMG_7cecc161_ASSET.readall(),
                IMG_b62e8d48_ASSET.readall(),
            ],
        ],
    },
    # 15 - Double Dragon
    {
        "BACKGROUND_IMGS": [
            IMG_89843bb5_ASSET.readall(),
            IMG_fcfa1dcd_ASSET.readall(),
            IMG_80519bc0_ASSET.readall(),
        ],
        "COLON_IMG": """""",
        "NUMBER_IMG_HEIGHT": 0,
        "NUMBER_IMG_WIDTH": 0,
        "NUMBER_IMGS": [],
        "SPRITE_WIDTH": 16,
        "DIST_BETWEEN_SPRITES": 10,
        "SPRITE_MIN_X": -42,
        "SPRITE_Y_POS": 0,
        "SPRITE_MOVE_SPEED": 4,
        "SPRITE_FRAMES_PER_FRAME": 1,
        "SPRITE_SETS": [
            [
                # Billy Lee walking
                IMG_0a7ca2ef_ASSET.readall(),
                IMG_5bb2b7a6_ASSET.readall(),
                IMG_68335b06_ASSET.readall(),
            ],
        ],
    },
    # 16 - Ninja Gaiden
    {
        "BACKGROUND_IMGS": [
            IMG_98f761fb_ASSET.readall(),
            IMG_a4e152d4_ASSET.readall(),
            IMG_d60557d0_ASSET.readall(),
        ],
        "COLON_IMG": """""",
        "NUMBER_IMG_HEIGHT": 0,
        "NUMBER_IMG_WIDTH": 0,
        "NUMBER_IMGS": [],
        "SPRITE_WIDTH": 22,
        "DIST_BETWEEN_SPRITES": 10,
        "SPRITE_MIN_X": -54,
        "SPRITE_Y_POS": 0,
        "SPRITE_MOVE_SPEED": 4,
        "SPRITE_FRAMES_PER_FRAME": 1,
        "SPRITE_SETS": [
            [
                # Ryu Hayabusa Lee walking
                IMG_84d86b71_ASSET.readall(),
                IMG_a93ba4a0_ASSET.readall(),
                IMG_81dcc3fc_ASSET.readall(),
            ],
        ],
    },
]

SMB3_NUMBER_IMGS = [
    IMG_8141ea11_ASSET.readall(),
    IMG_9386a9b2_ASSET.readall(),
    IMG_96fc27d4_ASSET.readall(),
    IMG_67b64e06_ASSET.readall(),
    IMG_a4f80e17_ASSET.readall(),
    IMG_9895f339_ASSET.readall(),
    IMG_c2b3e096_ASSET.readall(),
    IMG_912200d9_ASSET.readall(),
    IMG_c169250e_ASSET.readall(),
    IMG_9dbba56a_ASSET.readall(),
]

def main(config):
    """App entry point

    Args:
        config: User configuration values

    Returns:
        The rendered app
    """

    # Get the current time in 24 hour format
    location = config.get("location")
    loc = json.decode(location) if location else DEFAULT_LOCATION
    timezone = loc.get("timezone", time.tz())  # Utilize special timezone variable
    now = time.now()

    # Because the times returned by this API do not include the date, we need to
    # strip the date from "now" to get the current time in order to perform
    # acurate comparissons.
    # Local time must be localized with a timezone
    current_time = time.parse_time(now.in_location(timezone).format("3:04:05 PM"), format = "3:04:05 PM", location = timezone)

    # Get config values
    is_24_hour_format = config.bool("is_24_hour_format", DEFAULT_IS_24_HOUR_FORMAT)
    has_leading_zero = config.bool("has_leading_zero", DEFAULT_HAS_LEADING_ZERO)

    print_time = current_time

    speed = int(config.str("speed", DEFAULT_SPEED))
    if speed < 0:
        speed = rand(MIN_SPEED + MAX_SPEED + 1) + MAX_SPEED

    speed = speed * 5
    delay = speed * time.millisecond

    selected_game = int(config.str("game", DEFAULT_GAME))
    level_number = 1
    if selected_game == 0:
        selected_game = random.number(1, len(GAME_LIST) - 1)

    level_number = random.number(0, len(GAME_CONFIGS[selected_game]["BACKGROUND_IMGS"]) - 1)
    time_box = get_bg_image(selected_game, level_number, print_time, is_24_hour_format = is_24_hour_format, has_leading_zero = has_leading_zero, has_seperator = True)

    app_cycle_speed = SECONDS_TO_RENDER * time.second
    num_frames = math.ceil(app_cycle_speed // delay)

    all_frames = []
    frames = render.Text(content = "")

    for _ in range(1, 1000):
        frames = sprite_get_frames(selected_game, level_number, time_box)
        all_frames.extend(frames)

        if len(all_frames) >= num_frames:
            break

    return render.Root(
        max_age = 120,
        delay = delay.milliseconds,
        child = render.Animation(all_frames),
    )

def get_num_image(selected_game, num):
    """Gets the requested numeric image

    Args:
        selected_game: Integer that corresponds to one of the available games
        num: Integer of the image to be returned

    Returns:
        An image of the requested number
    """
    if len(GAME_CONFIGS[selected_game]["NUMBER_IMGS"]) > 0:
        return render.Padding(
            pad = (1, 0, 0, 0),
            child = render.Box(
                width = GAME_CONFIGS[selected_game]["NUMBER_IMG_WIDTH"],
                height = GAME_CONFIGS[selected_game]["NUMBER_IMG_HEIGHT"],
                child = render.Image(src = base64.decode(GAME_CONFIGS[selected_game]["NUMBER_IMGS"][int(num)])),
            ),
        )
    else:
        return render.Box(
            width = 8,
            height = 7,
            child = render.Image(src = base64.decode(SMB3_NUMBER_IMGS[int(num)])),
        )

def get_bg_image(selected_game, level_number, t, is_24_hour_format = True, has_leading_zero = False, has_seperator = True):
    """Overlays the current time onto a game background image in the user specified format

    Args:
        selected_game: Integer that corresponds to one of the available games
        level_number: Integer that corresponds to the level within a game (most have only one)
        t: The current time
        is_24_hour_format: Boolean indication if the time should display in 24 hour format
        has_leading_zero: Boolean indication if single digit hours should include a leading zero
        has_seperator: Boolean indication if a separator character should display between the hour and minutes

    Returns:
        A background image of the requested game and level that includes the current time overlay
    """
    hh = t.format("03")  # Format for 12 hour time
    if is_24_hour_format == True:
        hh = t.format("15")  # Format for 24 hour time
    mm = t.format("04")  # Format for minutes
    # ss = t.format("05")  # Format for seconds

    seperator = render.Box(
        width = 5,
        height = 7,
        child = render.Image(src = SMB3_COLON_IMG),
    )

    if selected_game == int(GAME_LIST["Contra"]):
        seperator = render.Box(
            width = 3,
            height = 7,
            child = render.Image(src = base64.decode(GAME_CONFIGS[selected_game]["COLON_IMG"])),
        )
    elif selected_game == int(GAME_LIST["Bubble Bobble"]):
        seperator = render.Box(
            width = 4,
            height = 8,
            child = render.Image(src = base64.decode(GAME_CONFIGS[selected_game]["COLON_IMG"])),
        )

    if not has_seperator:
        seperator = render.Box(
            width = 3,
        )

    hh0 = get_num_image(selected_game, int(hh[0]))
    if int(hh[0]) == 0 and has_leading_zero == False:
        hh0 = render.Box(
            width = 7,
        )

    bg_img = render.Image(base64.decode(GAME_CONFIGS[selected_game]["BACKGROUND_IMGS"][level_number]))

    return render.Stack(
        children = [
            bg_img,
            render.Box(
                child = render.Row(
                    cross_align = "center",
                    children = [
                        hh0,
                        get_num_image(selected_game, int(hh[1])),
                        seperator,
                        get_num_image(selected_game, int(mm[0])),
                        get_num_image(selected_game, int(mm[1])),
                    ],
                ),
            ),
        ],
    )

def rand(ceiling):
    return random.number(0, ceiling - 1)

def sprite_get_frames(selected_game, level_number, time_box):
    """Gets an array of sprite animation frames

    Args:
        selected_game: Integer corresponding to the selected game
        level_number: Integer corresponding to the selected level within a game
        time_box: A background image to display under the sprite animation frames

    Returns:
        An array of sprite animation frames
    """
    y_pos = GAME_CONFIGS[selected_game]["SPRITE_Y_POS"]
    begin_x = GAME_CONFIGS[selected_game]["SPRITE_MIN_X"]
    end_x = FRAME_WIDTH
    step = GAME_CONFIGS[selected_game]["SPRITE_MOVE_SPEED"]
    sprite_set_index = random.number(0, len(GAME_CONFIGS[selected_game]["SPRITE_SETS"]) - 1)

    # Super Mario Bros. 3 is a special case where certain sprite sets must be used with certain levels/backgrounds. Refactor later?
    if selected_game == int(GAME_LIST["Super Mario Bros. 3"]) and level_number != 2:
        sprite_set_index = 0
    elif selected_game == int(GAME_LIST["Super Mario Bros. 3"]) and level_number == 2:
        sprite_set_index = 1

    frames = [
        sprite_get_frame(selected_game, time_box, x_pos, y_pos, sprite_set_index)
        for x_pos in range(begin_x, end_x, step)
    ]

    return frames

def sprite_get_frame(selected_game, time_box, x_pos, y_pos, sprite_set_index):
    """Gets a single sprite animation frame

    Args:
        selected_game: Integer corresponding to the selected game
        time_box: A background image to display under the sprite animation frames
        x_pos: Integer representing the X position to render the sprite
        y_pos: Integer representing the Y position to render the sprite
        sprite_set_index: TBD

    Returns:
        A single sprite animation frame
    """
    frame_index = x_pos // GAME_CONFIGS[selected_game]["SPRITE_MOVE_SPEED"]
    sprite_frame_index = (frame_index // GAME_CONFIGS[selected_game]["SPRITE_FRAMES_PER_FRAME"]) % len(GAME_CONFIGS[selected_game]["SPRITE_SETS"][sprite_set_index])
    sprite_image = GAME_CONFIGS[selected_game]["SPRITE_SETS"][sprite_set_index][sprite_frame_index]

    return render.Stack(
        children = [
            time_box,
            render.Padding(
                pad = (x_pos, y_pos, 0, 0),
                child =
                    render.Row(
                        expanded = True,
                        children = [
                            render.Image(base64.decode(sprite_image)),
                        ],
                    ),
            ),
        ],
    )

def get_schema():
    speed_options = [
        schema.Option(display = key, value = value)
        for key, value in SPEED_LIST.items()
    ]

    game_options = [
        schema.Option(display = key, value = value)
        for key, value in GAME_LIST.items()
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "speed",
                name = "Speed",
                desc = "Change the speed of the animation.",
                icon = "gear",
                default = DEFAULT_SPEED,
                options = speed_options,
            ),
            schema.Dropdown(
                id = "game",
                name = "Game",
                desc = "Change the game displayed",
                icon = "gear",
                default = DEFAULT_GAME,
                options = game_options,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location defining time to display and daytime/nighttime colors",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "is_24_hour_format",
                name = "24 hour format",
                icon = "clock",
                desc = "Display the time in 24 hour format.",
                default = DEFAULT_IS_24_HOUR_FORMAT,
            ),
            schema.Toggle(
                id = "has_leading_zero",
                name = "Add leading zero",
                icon = "creativeCommonsZero",
                desc = "Ensure the clock always displays with a leading zero.",
                default = DEFAULT_HAS_LEADING_ZERO,
            ),
        ],
    )
