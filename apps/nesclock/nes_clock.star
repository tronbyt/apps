"""
Applet: NES Clock
Summary: NES Game Themed Clock
Description: Short animations of various Nintendo characters with a clock in the background.
Author: hx009
"""

load("encoding/json.star", "json")
load("images/bionic_bg_1.png", BIONIC_BG_1_ASSET = "file")
load("images/bionic_bg_2.png", BIONIC_BG_2_ASSET = "file")
load("images/bionic_rad.png", BIONIC_RAD_ASSET = "file")
load("images/bubblebobble_bg_1.png", BUBBLEBOBBLE_BG_1_ASSET = "file")
load("images/bubblebobble_bg_2.png", BUBBLEBOBBLE_BG_2_ASSET = "file")
load("images/bubblebobble_bg_3.png", BUBBLEBOBBLE_BG_3_ASSET = "file")
load("images/bubblebobble_bg_4.png", BUBBLEBOBBLE_BG_4_ASSET = "file")
load("images/bubblebobble_bob_1.png", BUBBLEBOBBLE_BOB_1_ASSET = "file")
load("images/bubblebobble_bob_2.png", BUBBLEBOBBLE_BOB_2_ASSET = "file")
load("images/bubblebobble_bob_3.png", BUBBLEBOBBLE_BOB_3_ASSET = "file")
load("images/bubblebobble_bob_4.png", BUBBLEBOBBLE_BOB_4_ASSET = "file")
load("images/bubblebobble_bub_1.png", BUBBLEBOBBLE_BUB_1_ASSET = "file")
load("images/bubblebobble_bub_2.png", BUBBLEBOBBLE_BUB_2_ASSET = "file")
load("images/bubblebobble_bub_3.png", BUBBLEBOBBLE_BUB_3_ASSET = "file")
load("images/bubblebobble_bub_4.png", BUBBLEBOBBLE_BUB_4_ASSET = "file")
load("images/bubblebobble_colon.png", BUBBLEBOBBLE_COLON_ASSET = "file")
load("images/bubblebobble_num_0.png", BUBBLEBOBBLE_NUM_0_ASSET = "file")
load("images/bubblebobble_num_1.png", BUBBLEBOBBLE_NUM_1_ASSET = "file")
load("images/bubblebobble_num_2.png", BUBBLEBOBBLE_NUM_2_ASSET = "file")
load("images/bubblebobble_num_3.png", BUBBLEBOBBLE_NUM_3_ASSET = "file")
load("images/bubblebobble_num_4.png", BUBBLEBOBBLE_NUM_4_ASSET = "file")
load("images/bubblebobble_num_5.png", BUBBLEBOBBLE_NUM_5_ASSET = "file")
load("images/bubblebobble_num_6.png", BUBBLEBOBBLE_NUM_6_ASSET = "file")
load("images/bubblebobble_num_7.png", BUBBLEBOBBLE_NUM_7_ASSET = "file")
load("images/bubblebobble_num_8.png", BUBBLEBOBBLE_NUM_8_ASSET = "file")
load("images/bubblebobble_num_9.png", BUBBLEBOBBLE_NUM_9_ASSET = "file")
load("images/castlevania_bg_1.png", CASTLEVANIA_BG_1_ASSET = "file")
load("images/castlevania_bg_2.png", CASTLEVANIA_BG_2_ASSET = "file")
load("images/castlevania_simon_1.png", CASTLEVANIA_SIMON_1_ASSET = "file")
load("images/castlevania_simon_2.png", CASTLEVANIA_SIMON_2_ASSET = "file")
load("images/castlevania_simon_3.png", CASTLEVANIA_SIMON_3_ASSET = "file")
load("images/chipndale_bg_1.png", CHIPNDALE_BG_1_ASSET = "file")
load("images/chipndale_bg_2.png", CHIPNDALE_BG_2_ASSET = "file")
load("images/chipndale_bg_3.png", CHIPNDALE_BG_3_ASSET = "file")
load("images/chipndale_chip_1.png", CHIPNDALE_CHIP_1_ASSET = "file")
load("images/chipndale_chip_2.png", CHIPNDALE_CHIP_2_ASSET = "file")
load("images/chipndale_chip_3.png", CHIPNDALE_CHIP_3_ASSET = "file")
load("images/chipndale_dale_1.png", CHIPNDALE_DALE_1_ASSET = "file")
load("images/chipndale_dale_2.png", CHIPNDALE_DALE_2_ASSET = "file")
load("images/chipndale_dale_3.png", CHIPNDALE_DALE_3_ASSET = "file")
load("images/contra_bg_1.png", CONTRA_BG_1_ASSET = "file")
load("images/contra_bg_2.png", CONTRA_BG_2_ASSET = "file")
load("images/contra_bg_3.png", CONTRA_BG_3_ASSET = "file")
load("images/contra_bullet.png", CONTRA_BULLET_ASSET = "file")
load("images/contra_num_0.png", CONTRA_NUM_0_ASSET = "file")
load("images/contra_num_1.png", CONTRA_NUM_1_ASSET = "file")
load("images/contra_num_2.png", CONTRA_NUM_2_ASSET = "file")
load("images/contra_num_3.png", CONTRA_NUM_3_ASSET = "file")
load("images/contra_num_4.png", CONTRA_NUM_4_ASSET = "file")
load("images/contra_num_5.png", CONTRA_NUM_5_ASSET = "file")
load("images/contra_num_6.png", CONTRA_NUM_6_ASSET = "file")
load("images/contra_num_7.png", CONTRA_NUM_7_ASSET = "file")
load("images/contra_num_8.png", CONTRA_NUM_8_ASSET = "file")
load("images/contra_num_9.png", CONTRA_NUM_9_ASSET = "file")
load("images/doubledragon_bg_1.png", DOUBLEDRAGON_BG_1_ASSET = "file")
load("images/doubledragon_bg_2.png", DOUBLEDRAGON_BG_2_ASSET = "file")
load("images/doubledragon_bg_3.png", DOUBLEDRAGON_BG_3_ASSET = "file")
load("images/doubledragon_billy_1.png", DOUBLEDRAGON_BILLY_1_ASSET = "file")
load("images/doubledragon_billy_2.png", DOUBLEDRAGON_BILLY_2_ASSET = "file")
load("images/doubledragon_billy_3.png", DOUBLEDRAGON_BILLY_3_ASSET = "file")
load("images/ducktales_bg_1.png", DUCKTALES_BG_1_ASSET = "file")
load("images/ducktales_bg_2.png", DUCKTALES_BG_2_ASSET = "file")
load("images/ducktales_scrooge_1.png", DUCKTALES_SCROOGE_1_ASSET = "file")
load("images/ducktales_scrooge_2.png", DUCKTALES_SCROOGE_2_ASSET = "file")
load("images/ducktales_scrooge_3.png", DUCKTALES_SCROOGE_3_ASSET = "file")
load("images/excitebike_bg_1.png", EXCITEBIKE_BG_1_ASSET = "file")
load("images/excitebike_bg_2.png", EXCITEBIKE_BG_2_ASSET = "file")
load("images/excitebike_bg_3.png", EXCITEBIKE_BG_3_ASSET = "file")
load("images/excitebike_ride_1.png", EXCITEBIKE_RIDE_1_ASSET = "file")
load("images/excitebike_ride_2.png", EXCITEBIKE_RIDE_2_ASSET = "file")
load("images/excitebike_ride_3.png", EXCITEBIKE_RIDE_3_ASSET = "file")
load("images/finalfantasy_bg_1.png", FINALFANTASY_BG_1_ASSET = "file")
load("images/finalfantasy_bg_2.png", FINALFANTASY_BG_2_ASSET = "file")
load("images/finalfantasy_brown_1.png", FINALFANTASY_BROWN_1_ASSET = "file")
load("images/finalfantasy_brown_2.png", FINALFANTASY_BROWN_2_ASSET = "file")
load("images/finalfantasy_red_1.png", FINALFANTASY_RED_1_ASSET = "file")
load("images/finalfantasy_red_2.png", FINALFANTASY_RED_2_ASSET = "file")
load("images/finalfantasy_white_1.png", FINALFANTASY_WHITE_1_ASSET = "file")
load("images/finalfantasy_white_2.png", FINALFANTASY_WHITE_2_ASSET = "file")
load("images/kidicarus_bg_1.png", KIDICARUS_BG_1_ASSET = "file")
load("images/kidicarus_bg_2.png", KIDICARUS_BG_2_ASSET = "file")
load("images/kidicarus_pit_1.png", KIDICARUS_PIT_1_ASSET = "file")
load("images/kidicarus_pit_2.png", KIDICARUS_PIT_2_ASSET = "file")
load("images/kidicarus_pit_3.png", KIDICARUS_PIT_3_ASSET = "file")
load("images/kirby_bg_1.png", KIRBY_BG_1_ASSET = "file")
load("images/kirby_bg_2.png", KIRBY_BG_2_ASSET = "file")
load("images/kirby_bg_3.png", KIRBY_BG_3_ASSET = "file")
load("images/kirby_walk_1.png", KIRBY_WALK_1_ASSET = "file")
load("images/kirby_walk_2.png", KIRBY_WALK_2_ASSET = "file")
load("images/kirby_walk_3.png", KIRBY_WALK_3_ASSET = "file")
load("images/kirby_walk_4.png", KIRBY_WALK_4_ASSET = "file")
load("images/megaman_bg_1.png", MEGAMAN_BG_1_ASSET = "file")
load("images/megaman_run_1.png", MEGAMAN_RUN_1_ASSET = "file")
load("images/megaman_run_2.png", MEGAMAN_RUN_2_ASSET = "file")
load("images/megaman_run_3.png", MEGAMAN_RUN_3_ASSET = "file")
load("images/nemo_bg_1.png", NEMO_BG_1_ASSET = "file")
load("images/nemo_bg_2.png", NEMO_BG_2_ASSET = "file")
load("images/nemo_walk_1.png", NEMO_WALK_1_ASSET = "file")
load("images/nemo_walk_2.png", NEMO_WALK_2_ASSET = "file")
load("images/nemo_walk_3.png", NEMO_WALK_3_ASSET = "file")
load("images/ninjagaiden_bg_1.png", NINJAGAIDEN_BG_1_ASSET = "file")
load("images/ninjagaiden_bg_2.png", NINJAGAIDEN_BG_2_ASSET = "file")
load("images/ninjagaiden_bg_3.png", NINJAGAIDEN_BG_3_ASSET = "file")
load("images/ninjagaiden_ryu_1.png", NINJAGAIDEN_RYU_1_ASSET = "file")
load("images/ninjagaiden_ryu_2.png", NINJAGAIDEN_RYU_2_ASSET = "file")
load("images/ninjagaiden_ryu_3.png", NINJAGAIDEN_RYU_3_ASSET = "file")
load("images/smb3_bg_1.png", SMB3_BG_1_ASSET = "file")
load("images/smb3_bg_2.png", SMB3_BG_2_ASSET = "file")
load("images/smb3_bg_3.png", SMB3_BG_3_ASSET = "file")
load("images/smb3_colon_img.png", SMB3_COLON_IMG_ASSET = "file")
load("images/smb3_mario_swim_1.png", SMB3_MARIO_SWIM_1_ASSET = "file")
load("images/smb3_mario_swim_2.png", SMB3_MARIO_SWIM_2_ASSET = "file")
load("images/smb3_mario_swim_3.png", SMB3_MARIO_SWIM_3_ASSET = "file")
load("images/smb3_mario_swim_4.png", SMB3_MARIO_SWIM_4_ASSET = "file")
load("images/smb3_mario_walk_1.png", SMB3_MARIO_WALK_1_ASSET = "file")
load("images/smb3_mario_walk_2.png", SMB3_MARIO_WALK_2_ASSET = "file")
load("images/smb3_num_0.png", SMB3_NUM_0_ASSET = "file")
load("images/smb3_num_1.png", SMB3_NUM_1_ASSET = "file")
load("images/smb3_num_2.png", SMB3_NUM_2_ASSET = "file")
load("images/smb3_num_3.png", SMB3_NUM_3_ASSET = "file")
load("images/smb3_num_4.png", SMB3_NUM_4_ASSET = "file")
load("images/smb3_num_5.png", SMB3_NUM_5_ASSET = "file")
load("images/smb3_num_6.png", SMB3_NUM_6_ASSET = "file")
load("images/smb3_num_7.png", SMB3_NUM_7_ASSET = "file")
load("images/smb3_num_8.png", SMB3_NUM_8_ASSET = "file")
load("images/smb3_num_9.png", SMB3_NUM_9_ASSET = "file")
load("images/zelda_bg_1.png", ZELDA_BG_1_ASSET = "file")
load("images/zelda_bg_2.png", ZELDA_BG_2_ASSET = "file")
load("images/zelda_bg_3.png", ZELDA_BG_3_ASSET = "file")
load("images/zelda_link_walk_1.png", ZELDA_LINK_WALK_1_ASSET = "file")
load("images/zelda_link_walk_2.png", ZELDA_LINK_WALK_2_ASSET = "file")
load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

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
            SMB3_BG_1_ASSET.readall(),
            SMB3_BG_2_ASSET.readall(),
            SMB3_BG_3_ASSET.readall(),
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
                SMB3_MARIO_WALK_1_ASSET.readall(),
                SMB3_MARIO_WALK_2_ASSET.readall(),
            ],
            [
                # Mario swimming
                SMB3_MARIO_SWIM_1_ASSET.readall(),
                SMB3_MARIO_SWIM_2_ASSET.readall(),
                SMB3_MARIO_SWIM_3_ASSET.readall(),
                SMB3_MARIO_SWIM_4_ASSET.readall(),
            ],
        ],
    },
    # 2 - Mega Man
    {
        "BACKGROUND_IMGS": [
            MEGAMAN_BG_1_ASSET.readall(),
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
                MEGAMAN_RUN_1_ASSET.readall(),
                MEGAMAN_RUN_2_ASSET.readall(),
                MEGAMAN_RUN_3_ASSET.readall(),
            ],
        ],
    },
    # 3 - Kirby's Adventure
    {
        "BACKGROUND_IMGS": [
            KIRBY_BG_1_ASSET.readall(),
            KIRBY_BG_2_ASSET.readall(),
            KIRBY_BG_3_ASSET.readall(),
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
                KIRBY_WALK_1_ASSET.readall(),
                KIRBY_WALK_2_ASSET.readall(),
                KIRBY_WALK_3_ASSET.readall(),
                KIRBY_WALK_4_ASSET.readall(),
            ],
        ],
    },
    # 4 - The Legend of Zelda
    {
        "BACKGROUND_IMGS": [
            ZELDA_BG_1_ASSET.readall(),
            ZELDA_BG_2_ASSET.readall(),
            ZELDA_BG_3_ASSET.readall(),
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
                ZELDA_LINK_WALK_1_ASSET.readall(),
                ZELDA_LINK_WALK_2_ASSET.readall(),
            ],
        ],
    },
    # 5 - Contra
    {
        "BACKGROUND_IMGS": [
            CONTRA_BG_1_ASSET.readall(),
            CONTRA_BG_2_ASSET.readall(),
            CONTRA_BG_3_ASSET.readall(),
        ],
        "COLON_IMG": CONTRA_COLON_ASSET.readall(),
        "NUMBER_IMG_HEIGHT": 7,
        "NUMBER_IMG_WIDTH": 7,
        "NUMBER_IMGS": [
            CONTRA_NUM_0_ASSET.readall(),
            CONTRA_NUM_1_ASSET.readall(),
            CONTRA_NUM_2_ASSET.readall(),
            CONTRA_NUM_3_ASSET.readall(),
            CONTRA_NUM_4_ASSET.readall(),
            CONTRA_NUM_5_ASSET.readall(),
            CONTRA_NUM_6_ASSET.readall(),
            CONTRA_NUM_7_ASSET.readall(),
            CONTRA_NUM_8_ASSET.readall(),
            CONTRA_NUM_9_ASSET.readall(),
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
                CONTRA_BULLET_ASSET.readall(),
            ],
        ],
    },
    # 6 - Excitebike
    {
        "BACKGROUND_IMGS": [
            EXCITEBIKE_BG_1_ASSET.readall(),
            EXCITEBIKE_BG_2_ASSET.readall(),
            EXCITEBIKE_BG_3_ASSET.readall(),
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
                EXCITEBIKE_RIDE_1_ASSET.readall(),
                EXCITEBIKE_RIDE_2_ASSET.readall(),
                EXCITEBIKE_RIDE_3_ASSET.readall(),
            ],
        ],
    },
    # 7 - Little Nemo
    {
        "BACKGROUND_IMGS": [
            NEMO_BG_1_ASSET.readall(),
            NEMO_BG_2_ASSET.readall(),
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
                NEMO_WALK_1_ASSET.readall(),
                NEMO_WALK_2_ASSET.readall(),
                NEMO_WALK_3_ASSET.readall(),
            ],
        ],
    },
    # 8 - DuckTales
    {
        "BACKGROUND_IMGS": [
            DUCKTALES_BG_1_ASSET.readall(),
            DUCKTALES_BG_2_ASSET.readall(),
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
                DUCKTALES_SCROOGE_1_ASSET.readall(),
                DUCKTALES_SCROOGE_2_ASSET.readall(),
                DUCKTALES_SCROOGE_3_ASSET.readall(),
            ],
        ],
    },
    # 9 - Bubble Bobble
    {
        "BACKGROUND_IMGS": [
            BUBBLEBOBBLE_BG_1_ASSET.readall(),
            BUBBLEBOBBLE_BG_2_ASSET.readall(),
            BUBBLEBOBBLE_BG_3_ASSET.readall(),
            BUBBLEBOBBLE_BG_4_ASSET.readall(),
        ],
        "COLON_IMG": BUBBLEBOBBLE_COLON_ASSET.readall(),
        "NUMBER_IMG_HEIGHT": 8,
        "NUMBER_IMG_WIDTH": 4,
        "NUMBER_IMGS": [
            BUBBLEBOBBLE_NUM_0_ASSET.readall(),
            BUBBLEBOBBLE_NUM_1_ASSET.readall(),
            BUBBLEBOBBLE_NUM_2_ASSET.readall(),
            BUBBLEBOBBLE_NUM_3_ASSET.readall(),
            BUBBLEBOBBLE_NUM_4_ASSET.readall(),
            BUBBLEBOBBLE_NUM_5_ASSET.readall(),
            BUBBLEBOBBLE_NUM_6_ASSET.readall(),
            BUBBLEBOBBLE_NUM_7_ASSET.readall(),
            BUBBLEBOBBLE_NUM_8_ASSET.readall(),
            BUBBLEBOBBLE_NUM_9_ASSET.readall(),
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
                BUBBLEBOBBLE_BUB_1_ASSET.readall(),
                BUBBLEBOBBLE_BUB_2_ASSET.readall(),
                BUBBLEBOBBLE_BUB_3_ASSET.readall(),
                BUBBLEBOBBLE_BUB_4_ASSET.readall(),
            ],
            [
                # Bob
                BUBBLEBOBBLE_BOB_1_ASSET.readall(),
                BUBBLEBOBBLE_BOB_2_ASSET.readall(),
                BUBBLEBOBBLE_BOB_3_ASSET.readall(),
                BUBBLEBOBBLE_BOB_4_ASSET.readall(),
            ],
        ],
    },
    # 10 - Chip 'n Dale: Rescue Rangers
    {
        "BACKGROUND_IMGS": [
            CHIPNDALE_BG_1_ASSET.readall(),
            CHIPNDALE_BG_2_ASSET.readall(),
            CHIPNDALE_BG_3_ASSET.readall(),
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
                CHIPNDALE_CHIP_1_ASSET.readall(),
                CHIPNDALE_CHIP_2_ASSET.readall(),
                CHIPNDALE_CHIP_3_ASSET.readall(),
            ],
            [
                # Dale
                CHIPNDALE_DALE_1_ASSET.readall(),
                CHIPNDALE_DALE_2_ASSET.readall(),
                CHIPNDALE_DALE_3_ASSET.readall(),
            ],
        ],
    },
    # 11 - Bionic Commando
    {
        "BACKGROUND_IMGS": [
            BIONIC_BG_1_ASSET.readall(),
            BIONIC_BG_2_ASSET.readall(),
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
                BIONIC_RAD_ASSET.readall(),
            ],
        ],
    },
    # 12 - Kid Icarus
    {
        "BACKGROUND_IMGS": [
            KIDICARUS_BG_1_ASSET.readall(),
            KIDICARUS_BG_2_ASSET.readall(),
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
                KIDICARUS_PIT_1_ASSET.readall(),
                KIDICARUS_PIT_2_ASSET.readall(),
                KIDICARUS_PIT_3_ASSET.readall(),
            ],
        ],
    },
    # 13 - Final Fantasy
    {
        "BACKGROUND_IMGS": [
            FINALFANTASY_BG_1_ASSET.readall(),
            FINALFANTASY_BG_2_ASSET.readall(),
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
                FINALFANTASY_RED_1_ASSET.readall(),
                FINALFANTASY_RED_2_ASSET.readall(),
            ],
            [
                # Light warrior brown walking
                FINALFANTASY_BROWN_1_ASSET.readall(),
                FINALFANTASY_BROWN_2_ASSET.readall(),
            ],
            [
                # Light warrior white walking
                FINALFANTASY_WHITE_1_ASSET.readall(),
                FINALFANTASY_WHITE_2_ASSET.readall(),
            ],
        ],
    },
    # 14 - Castlevania
    {
        "BACKGROUND_IMGS": [
            CASTLEVANIA_BG_1_ASSET.readall(),
            CASTLEVANIA_BG_2_ASSET.readall(),
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
                CASTLEVANIA_SIMON_1_ASSET.readall(),
                CASTLEVANIA_SIMON_2_ASSET.readall(),
                CASTLEVANIA_SIMON_3_ASSET.readall(),
            ],
        ],
    },
    # 15 - Double Dragon
    {
        "BACKGROUND_IMGS": [
            DOUBLEDRAGON_BG_1_ASSET.readall(),
            DOUBLEDRAGON_BG_2_ASSET.readall(),
            DOUBLEDRAGON_BG_3_ASSET.readall(),
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
                DOUBLEDRAGON_BILLY_1_ASSET.readall(),
                DOUBLEDRAGON_BILLY_2_ASSET.readall(),
                DOUBLEDRAGON_BILLY_3_ASSET.readall(),
            ],
        ],
    },
    # 16 - Ninja Gaiden
    {
        "BACKGROUND_IMGS": [
            NINJAGAIDEN_BG_1_ASSET.readall(),
            NINJAGAIDEN_BG_2_ASSET.readall(),
            NINJAGAIDEN_BG_3_ASSET.readall(),
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
                NINJAGAIDEN_RYU_1_ASSET.readall(),
                NINJAGAIDEN_RYU_2_ASSET.readall(),
                NINJAGAIDEN_RYU_3_ASSET.readall(),
            ],
        ],
    },
]

SMB3_NUMBER_IMGS = [
    SMB3_NUM_0_ASSET.readall(),
    SMB3_NUM_1_ASSET.readall(),
    SMB3_NUM_2_ASSET.readall(),
    SMB3_NUM_3_ASSET.readall(),
    SMB3_NUM_4_ASSET.readall(),
    SMB3_NUM_5_ASSET.readall(),
    SMB3_NUM_6_ASSET.readall(),
    SMB3_NUM_7_ASSET.readall(),
    SMB3_NUM_8_ASSET.readall(),
    SMB3_NUM_9_ASSET.readall(),
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
                child = render.Image(src = GAME_CONFIGS[selected_game]["NUMBER_IMGS"][int(num)]),
            ),
        )
    else:
        return render.Box(
            width = 8,
            height = 7,
            child = render.Image(src = SMB3_NUMBER_IMGS[int(num)]),
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
            child = render.Image(src = GAME_CONFIGS[selected_game]["COLON_IMG"]),
        )
    elif selected_game == int(GAME_LIST["Bubble Bobble"]):
        seperator = render.Box(
            width = 4,
            height = 8,
            child = render.Image(src = GAME_CONFIGS[selected_game]["COLON_IMG"]),
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

    bg_img = render.Image(GAME_CONFIGS[selected_game]["BACKGROUND_IMGS"][level_number])

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
                            render.Image(sprite_image),
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
