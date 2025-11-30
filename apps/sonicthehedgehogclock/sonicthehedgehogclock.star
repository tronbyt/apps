"""
Applet: Sonic Clock
Summary: Sonic Clock
Description: A customizable clock featuring characters from Sonic the Hedgehog
Author: RichardALeon
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/angel_island_zone_l1_f1_0972fd3a.png", ANGEL_ISLAND_ZONE_L1_F1_0972fd3a_ASSET = "file")
load("images/carnival_night_zone_l1_f1_dcbbd781.png", CARNIVAL_NIGHT_ZONE_L1_F1_dcbbd781_ASSET = "file")
load("images/ghz_8bit_l1_f1_7b697aa0.png", GHZ_8BIT_L1_F1_7b697aa0_ASSET = "file")
load("images/green_hill_zone_l1_f1_164a1282.png", GREEN_HILL_ZONE_L1_F1_164a1282_ASSET = "file")
load("images/knuckles_sth3_l1_f10_0490bf36.png", KNUCKLES_STH3_L1_F10_0490bf36_ASSET = "file")
load("images/knuckles_sth3_l1_f11_fe5c155d.png", KNUCKLES_STH3_L1_F11_fe5c155d_ASSET = "file")
load("images/knuckles_sth3_l1_f1_c8fab96f.png", KNUCKLES_STH3_L1_F1_c8fab96f_ASSET = "file")
load("images/knuckles_sth3_l1_f2_c146e7e0.png", KNUCKLES_STH3_L1_F2_c146e7e0_ASSET = "file")
load("images/knuckles_sth3_l1_f3_99a13491.png", KNUCKLES_STH3_L1_F3_99a13491_ASSET = "file")
load("images/knuckles_sth3_l1_f4_589c5054.png", KNUCKLES_STH3_L1_F4_589c5054_ASSET = "file")
load("images/knuckles_sth3_l1_f5_56d79cef.png", KNUCKLES_STH3_L1_F5_56d79cef_ASSET = "file")
load("images/knuckles_sth3_l1_f6_570167ea.png", KNUCKLES_STH3_L1_F6_570167ea_ASSET = "file")
load("images/knuckles_sth3_l1_f7_c2a2bcd7.png", KNUCKLES_STH3_L1_F7_c2a2bcd7_ASSET = "file")
load("images/knuckles_sth3_l1_f8_c5a89e28.png", KNUCKLES_STH3_L1_F8_c5a89e28_ASSET = "file")
load("images/knuckles_sth3_l1_f9_4ee4bfb0.png", KNUCKLES_STH3_L1_F9_4ee4bfb0_ASSET = "file")
load("images/sonic_sth1_l1_f1_102a34b0.png", SONIC_STH1_L1_F1_102a34b0_ASSET = "file")
load("images/sonic_sth1_l1_f2_1699edcc.png", SONIC_STH1_L1_F2_1699edcc_ASSET = "file")
load("images/sonic_sth1_l1_f3_102a34b0.png", SONIC_STH1_L1_F3_102a34b0_ASSET = "file")
load("images/sonic_sth1_l1_f4_02860816.png", SONIC_STH1_L1_F4_02860816_ASSET = "file")
load("images/sonic_sth3_l1_f1_84752010.png", SONIC_STH3_L1_F1_84752010_ASSET = "file")
load("images/sonic_sth3_l1_f2_bd2febd0.png", SONIC_STH3_L1_F2_bd2febd0_ASSET = "file")
load("images/sonic_sth3_l1_f3_03f47fe6.png", SONIC_STH3_L1_F3_03f47fe6_ASSET = "file")
load("images/sonic_sth3_l1_f4_48220b15.png", SONIC_STH3_L1_F4_48220b15_ASSET = "file")
load("images/sonic_sth3_l1_f5_9e06f173.png", SONIC_STH3_L1_F5_9e06f173_ASSET = "file")
load("images/sonic_sth3_l1_f6_a66f9505.png", SONIC_STH3_L1_F6_a66f9505_ASSET = "file")
load("images/sonic_sth3_l1_f7_9e06f173.png", SONIC_STH3_L1_F7_9e06f173_ASSET = "file")
load("images/tails_sth3_l1_f1_19c406e8.png", TAILS_STH3_L1_F1_19c406e8_ASSET = "file")
load("images/tails_sth3_l1_f2_eb6f4094.png", TAILS_STH3_L1_F2_eb6f4094_ASSET = "file")
load("images/tails_sth3_l1_f3_b789e1bb.png", TAILS_STH3_L1_F3_b789e1bb_ASSET = "file")
load("images/tails_sth3_l1_f4_e9d82e73.png", TAILS_STH3_L1_F4_e9d82e73_ASSET = "file")
load("images/tails_sth3_l1_f5_028c6eb9.png", TAILS_STH3_L1_F5_028c6eb9_ASSET = "file")
load("images/tails_sth3_l1_f6_66c5533f.png", TAILS_STH3_L1_F6_66c5533f_ASSET = "file")
load("images/tails_sth3_l1_f7_6ba4781d.png", TAILS_STH3_L1_F7_6ba4781d_ASSET = "file")
load("images/tails_sth3_l1_f8_028c6eb9.png", TAILS_STH3_L1_F8_028c6eb9_ASSET = "file")
load("images/tails_sth3_l2_f1_5934d534.png", TAILS_STH3_L2_F1_5934d534_ASSET = "file")
load("images/tails_sth3_l2_f2_11afa94f.png", TAILS_STH3_L2_F2_11afa94f_ASSET = "file")
load("images/tails_sth3_l2_f3_250e5659.png", TAILS_STH3_L2_F3_250e5659_ASSET = "file")
load("images/tails_sth3_l2_f4_57aa2b8e.png", TAILS_STH3_L2_F4_57aa2b8e_ASSET = "file")
load("images/tails_sth3_l2_f5_55ab5d18.png", TAILS_STH3_L2_F5_55ab5d18_ASSET = "file")

def animate(layerSpecs):
    layers = []

    for layerSpec in layerSpecs:
        frames = []

        for animationSpec in layerSpec:
            for _x in range(animationSpec["loops"]):
                for frameSpec in animationSpec["frames"]:
                    src = base64.decode(frameSpec["src"])
                    for _y in range(frameSpec["duration"]):
                        frames.append(
                            render.Image(
                                src = src,
                                width = animationSpec["width"],
                                height = animationSpec["height"],
                            ),
                        )
        layers.append(
            render.Animation(
                children = frames,
            ),
        )

    return render.Stack(
        children = layers,
    )

def get_character(character):
    return animate(CHARACTERS[character])

def get_background(background):
    return animate(BACKGROUNDS[background])

def get_clock(timezone, color):
    now = time.now().in_location(timezone)

    frames = []
    for _i in range(5):
        frames.append(
            render.Text(
                content = now.format("3:04"),
                font = "6x13",
                color = color,
            ),
        )

    for _i in range(5):
        frames.append(
            render.Text(
                content = now.format("3 04"),
                font = "6x13",
                color = color,
            ),
        )

    return render.Column(
        main_align = "center",
        children = [
            render.Padding(
                pad = (0, 0, 1, 0),
                child = render.Row(
                    main_align = "end",
                    cross_align = "start",
                    children = [
                        render.Animation(
                            children = frames,
                        ),
                        render.Padding(
                            pad = (0, 2, 0, 0),
                            child = render.Text(
                                content = now.format("PM"),
                                color = color,
                            ),
                        ),
                    ],
                ),
            ),
        ],
    )

def main(config):
    bg_id = config.get("background") or DEFAULT_BACKGROUND
    c_id = config.get("character") or DEFAULT_CHARACTER
    location = json.decode(config.get("location") or DEFAULT_LOCATION)
    timezone = location["timezone"]
    font_color = config.get("color") or DEFAULT_FONT_COLOR[bg_id]

    clock = get_clock(timezone, font_color)
    character = get_character(c_id)
    background = get_background(bg_id)

    pad_character = render.Padding(
        pad = CHARACTER_PADDING[bg_id],
        child = character,
    )

    pad_clock = render.Padding(
        pad = CLOCK_PADDING[bg_id],
        child = clock,
    )

    stack = render.Stack(
        children = [background, pad_clock, pad_character],
    )

    return render.Root(
        child = stack,
        delay = 100,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "character",
                name = "Character",
                desc = "Which character to display",
                default = DEFAULT_CHARACTER,
                icon = "user",
                options = [
                    schema.Option(
                        display = "Sonic (Sonic 3)",
                        value = C_SONIC_STH3,
                    ),
                    schema.Option(
                        display = "Knuckles (Sonic 3)",
                        value = C_KNUCKLES_STH3,
                    ),
                    schema.Option(
                        display = "Tails (Sonic 3)",
                        value = C_TAILS_STH3,
                    ),
                    schema.Option(
                        display = "Sonic (Sonic 1)",
                        value = C_SONIC_STH1,
                    ),
                ],
            ),
            schema.Dropdown(
                id = "background",
                name = "Background",
                desc = "Which background to display",
                default = DEFAULT_BACKGROUND,
                icon = "map",
                options = [
                    schema.Option(
                        display = "None",
                        value = BG_NONE,
                    ),
                    schema.Option(
                        display = "Green Hill Zone",
                        value = BG_GREEN_HILL_ZONE,
                    ),
                    schema.Option(
                        display = "Green Hill Zone (8 Bit)",
                        value = BG_GHZ_8_BIT,
                    ),
                    schema.Option(
                        display = "Angel Island Zone",
                        value = BG_ANGEL_ISLAND_ZONE,
                    ),
                    schema.Option(
                        display = "Carnival Night Zone",
                        value = BG_CARNIVAL_NIGHT_ZONE,
                    ),
                ],
            ),
            schema.Color(
                id = "color",
                name = "Clock Color",
                desc = "Color of the clock.",
                icon = "clock",
                default = "#FFF",
                palette = [
                    "#FFF",
                    "#000",
                    "#F00",
                    "#FF0",
                    "#0F0",
                    "#0FF",
                    "#F0F",
                    "#00F",
                ],
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time",
                icon = "locationDot",
            ),
        ],
    )

# Character Options
C_SONIC_STH3 = "sonic_sth3"
C_KNUCKLES_STH3 = "knuckles_sth3"
C_TAILS_STH3 = "tails_sth3"
C_SONIC_STH1 = "sonic_sth1"

# Background Options
BG_NONE = "none"
BG_GREEN_HILL_ZONE = "green_hill_zone"
BG_GHZ_8_BIT = "ghz_8bit"
BG_ANGEL_ISLAND_ZONE = "angel_island_zone"
BG_CARNIVAL_NIGHT_ZONE = "carnival_night_zone"

# Image Sources

# Sonic (Sonic 3)
SONIC_STH3_L1_F1 = SONIC_STH3_L1_F1_84752010_ASSET.readall()
SONIC_STH3_L1_F2 = SONIC_STH3_L1_F2_bd2febd0_ASSET.readall()
SONIC_STH3_L1_F3 = SONIC_STH3_L1_F3_03f47fe6_ASSET.readall()
SONIC_STH3_L1_F4 = SONIC_STH3_L1_F4_48220b15_ASSET.readall()
SONIC_STH3_L1_F5 = SONIC_STH3_L1_F5_9e06f173_ASSET.readall()
SONIC_STH3_L1_F6 = SONIC_STH3_L1_F6_a66f9505_ASSET.readall()
SONIC_STH3_L1_F7 = SONIC_STH3_L1_F7_9e06f173_ASSET.readall()

# Knuckles (Sonic 3)
KNUCKLES_STH3_L1_F1 = KNUCKLES_STH3_L1_F1_c8fab96f_ASSET.readall()
KNUCKLES_STH3_L1_F2 = KNUCKLES_STH3_L1_F2_c146e7e0_ASSET.readall()
KNUCKLES_STH3_L1_F3 = KNUCKLES_STH3_L1_F3_99a13491_ASSET.readall()
KNUCKLES_STH3_L1_F4 = KNUCKLES_STH3_L1_F4_589c5054_ASSET.readall()
KNUCKLES_STH3_L1_F5 = KNUCKLES_STH3_L1_F5_56d79cef_ASSET.readall()
KNUCKLES_STH3_L1_F6 = KNUCKLES_STH3_L1_F6_570167ea_ASSET.readall()
KNUCKLES_STH3_L1_F7 = KNUCKLES_STH3_L1_F7_c2a2bcd7_ASSET.readall()
KNUCKLES_STH3_L1_F8 = KNUCKLES_STH3_L1_F8_c5a89e28_ASSET.readall()
KNUCKLES_STH3_L1_F9 = KNUCKLES_STH3_L1_F9_4ee4bfb0_ASSET.readall()
KNUCKLES_STH3_L1_F10 = KNUCKLES_STH3_L1_F10_0490bf36_ASSET.readall()
KNUCKLES_STH3_L1_F11 = KNUCKLES_STH3_L1_F11_fe5c155d_ASSET.readall()

# Tails (Sonic 3)
TAILS_STH3_L1_F1 = TAILS_STH3_L1_F1_19c406e8_ASSET.readall()
TAILS_STH3_L1_F2 = TAILS_STH3_L1_F2_eb6f4094_ASSET.readall()
TAILS_STH3_L1_F3 = TAILS_STH3_L1_F3_b789e1bb_ASSET.readall()
TAILS_STH3_L1_F4 = TAILS_STH3_L1_F4_e9d82e73_ASSET.readall()
TAILS_STH3_L1_F5 = TAILS_STH3_L1_F5_028c6eb9_ASSET.readall()
TAILS_STH3_L1_F6 = TAILS_STH3_L1_F6_66c5533f_ASSET.readall()
TAILS_STH3_L1_F7 = TAILS_STH3_L1_F7_6ba4781d_ASSET.readall()
TAILS_STH3_L1_F8 = TAILS_STH3_L1_F8_028c6eb9_ASSET.readall()

TAILS_STH3_L2_F1 = TAILS_STH3_L2_F1_5934d534_ASSET.readall()
TAILS_STH3_L2_F2 = TAILS_STH3_L2_F2_11afa94f_ASSET.readall()
TAILS_STH3_L2_F3 = TAILS_STH3_L2_F3_250e5659_ASSET.readall()
TAILS_STH3_L2_F4 = TAILS_STH3_L2_F4_57aa2b8e_ASSET.readall()
TAILS_STH3_L2_F5 = TAILS_STH3_L2_F5_55ab5d18_ASSET.readall()

# Sonic (Sonic 1)
SONIC_STH1_L1_F1 = SONIC_STH1_L1_F1_102a34b0_ASSET.readall()
SONIC_STH1_L1_F2 = SONIC_STH1_L1_F2_1699edcc_ASSET.readall()
SONIC_STH1_L1_F3 = SONIC_STH1_L1_F3_102a34b0_ASSET.readall()
SONIC_STH1_L1_F4 = SONIC_STH1_L1_F4_02860816_ASSET.readall()

# Green Hill Zone
GREEN_HILL_ZONE_L1_F1 = GREEN_HILL_ZONE_L1_F1_164a1282_ASSET.readall()

# Green Hill Zone (8-Bit)
GHZ_8BIT_L1_F1 = GHZ_8BIT_L1_F1_7b697aa0_ASSET.readall()

# Angel Island Zone
ANGEL_ISLAND_ZONE_L1_F1 = ANGEL_ISLAND_ZONE_L1_F1_0972fd3a_ASSET.readall()

# Carnival Night Zone
CARNIVAL_NIGHT_ZONE_L1_F1 = CARNIVAL_NIGHT_ZONE_L1_F1_dcbbd781_ASSET.readall()

# Each character is a collection of images in an animation
CHARACTERS = {
    C_SONIC_STH1: [
        # Layer 1 - Sonic
        [
            # Frame 1 x20
            {
                "frames": [
                    {
                        "src": SONIC_STH1_L1_F1,
                        "duration": 2,
                    },
                ],
                "loops": 10,
                "width": 24,
                "height": 24,
            },
            # Frame 2
            {
                "frames": [
                    {
                        "src": SONIC_STH1_L1_F2,
                        "duration": 2,
                    },
                ],
                "loops": 1,
                "width": 24,
                "height": 24,
            },
            # Frame 3-4 x10
            {
                "frames": [
                    {
                        "src": SONIC_STH1_L1_F3,
                        "duration": 2,
                    },
                    {
                        "src": SONIC_STH1_L1_F4,
                        "duration": 2,
                    },
                ],
                "loops": 20,
                "width": 24,
                "height": 24,
            },
        ],
    ],
    C_SONIC_STH3: [
        # Layer 1 - Sonic
        [
            # Frame 1-2 x20
            {
                "frames": [
                    {
                        "src": SONIC_STH3_L1_F1,
                        "duration": 2,
                    },
                    {
                        "src": SONIC_STH3_L1_F2,
                        "duration": 2,
                    },
                ],
                "loops": 20,
                "width": 24,
                "height": 24,
            },
            # Frames 3-7
            {
                "frames": [
                    {
                        "src": SONIC_STH3_L1_F3,
                        "duration": 4,
                    },
                    {
                        "src": SONIC_STH3_L1_F4,
                        "duration": 4,
                    },
                    {
                        "src": SONIC_STH3_L1_F5,
                        "duration": 1,
                    },
                    {
                        "src": SONIC_STH3_L1_F6,
                        "duration": 3,
                    },
                    {
                        "src": SONIC_STH3_L1_F7,
                        "duration": 1,
                    },
                ],
                "loops": 1,
                "width": 24,
                "height": 24,
            },
        ],
    ],
    C_KNUCKLES_STH3: [
        # Layer 1 - Knuckles
        [
            # frame 1 and 2 x8
            {
                "frames": [
                    {
                        "src": KNUCKLES_STH3_L1_F1,
                        "duration": 2,
                    },
                    {
                        "src": KNUCKLES_STH3_L1_F2,
                        "duration": 2,
                    },
                ],
                "loops": 8,
                "width": 24,
                "height": 24,
            },
            # frame 3-4
            {
                "frames": [
                    {
                        "src": KNUCKLES_STH3_L1_F3,
                        "duration": 2,
                    },
                    {
                        "src": KNUCKLES_STH3_L1_F4,
                        "duration": 2,
                    },
                ],
                "loops": 1,
                "width": 24,
                "height": 24,
            },
            # frame 5-8 x8
            {
                "frames": [
                    {
                        "src": KNUCKLES_STH3_L1_F5,
                        "duration": 1,
                    },
                    {
                        "src": KNUCKLES_STH3_L1_F6,
                        "duration": 1,
                    },
                    {
                        "src": KNUCKLES_STH3_L1_F7,
                        "duration": 1,
                    },
                    {
                        "src": KNUCKLES_STH3_L1_F8,
                        "duration": 1,
                    },
                ],
                "loops": 8,
                "width": 24,
                "height": 24,
            },
            # frame 9-10 x3
            {
                "frames": [
                    {
                        "src": KNUCKLES_STH3_L1_F9,
                        "duration": 1,
                    },
                    {
                        "src": KNUCKLES_STH3_L1_F10,
                        "duration": 1,
                    },
                ],
                "loops": 3,
                "width": 24,
                "height": 24,
            },
            # frame 11 to 5 to 4
            {
                "frames": [
                    {
                        "src": KNUCKLES_STH3_L1_F11,
                        "duration": 2,
                    },
                    {
                        "src": KNUCKLES_STH3_L1_F5,
                        "duration": 2,
                    },
                    {
                        "src": KNUCKLES_STH3_L1_F4,
                        "duration": 2,
                    },
                ],
                "loops": 1,
                "width": 24,
                "height": 24,
            },
        ],
    ],
    C_TAILS_STH3: [
        # Layer 1 - Body
        [
            # Frame 1
            {
                "frames": [
                    {
                        "src": TAILS_STH3_L1_F1,
                        "duration": 2,
                    },
                ],
                "loops": 20,
                "width": 24,
                "height": 24,
            },
            # Frame 2-3 x2
            {
                "frames": [
                    {
                        "src": TAILS_STH3_L1_F2,
                        "duration": 4,
                    },
                    {
                        "src": TAILS_STH3_L1_F3,
                        "duration": 4,
                    },
                ],
                "loops": 2,
                "width": 24,
                "height": 24,
            },
            # Frame 1, 4-5
            {
                "frames": [
                    {
                        "src": TAILS_STH3_L1_F1,
                        "duration": 2,
                    },
                    {
                        "src": TAILS_STH3_L1_F4,
                        "duration": 2,
                    },
                    {
                        "src": TAILS_STH3_L1_F5,
                        "duration": 2,
                    },
                ],
                "loops": 1,
                "width": 24,
                "height": 24,
            },
            # Frame 6-7 x5
            {
                "frames": [
                    {
                        "src": TAILS_STH3_L1_F6,
                        "duration": 2,
                    },
                    {
                        "src": TAILS_STH3_L1_F7,
                        "duration": 1,
                    },
                ],
                "loops": 5,
                "width": 24,
                "height": 24,
            },
            # Frame 8, 1
            {
                "frames": [
                    {
                        "src": TAILS_STH3_L1_F8,
                        "duration": 2,
                    },
                    {
                        "src": TAILS_STH3_L1_F1,
                        "duration": 2,
                    },
                ],
                "loops": 1,
                "width": 24,
                "height": 24,
            },
        ],
        # Layer 2 - Tails
        [
            # Frames 1-5
            {
                "frames": [
                    {
                        "src": TAILS_STH3_L2_F1,
                        "duration": 2,
                    },
                    {
                        "src": TAILS_STH3_L2_F2,
                        "duration": 2,
                    },
                    {
                        "src": TAILS_STH3_L2_F3,
                        "duration": 2,
                    },
                    {
                        "src": TAILS_STH3_L2_F4,
                        "duration": 2,
                    },
                    {
                        "src": TAILS_STH3_L2_F5,
                        "duration": 2,
                    },
                ],
                "loops": 1,
                "width": 24,
                "height": 24,
            },
        ],
    ],
}

BACKGROUNDS = {
    BG_NONE: [
        [
            {
                "frames": [],
                "loops": 0,
            },
        ],
    ],
    BG_GREEN_HILL_ZONE: [
        [
            {
                "frames": [
                    {
                        "src": GREEN_HILL_ZONE_L1_F1,
                        "duration": 1,
                    },
                ],
                "loops": 1,
                "width": 64,
                "height": 32,
            },
        ],
    ],
    BG_GHZ_8_BIT: [
        [
            {
                "frames": [
                    {
                        "src": GHZ_8BIT_L1_F1,
                        "duration": 1,
                    },
                ],
                "loops": 1,
                "width": 64,
                "height": 32,
            },
        ],
    ],
    BG_ANGEL_ISLAND_ZONE: [
        [
            {
                "frames": [
                    {
                        "src": ANGEL_ISLAND_ZONE_L1_F1,
                        "duration": 1,
                    },
                ],
                "loops": 1,
                "width": 64,
                "height": 32,
            },
        ],
    ],
    BG_CARNIVAL_NIGHT_ZONE: [
        [
            {
                "frames": [
                    {
                        "src": CARNIVAL_NIGHT_ZONE_L1_F1,
                        "duration": 1,
                    },
                ],
                "loops": 1,
                "width": 64,
                "height": 32,
            },
        ],
    ],
}

DEFAULT_FONT_COLOR = {
    BG_NONE: "#FFF",
    BG_GREEN_HILL_ZONE: "#000",
    BG_GHZ_8_BIT: "#000",
    BG_ANGEL_ISLAND_ZONE: "#FFF",
    BG_CARNIVAL_NIGHT_ZONE: "#FFF",
}

CHARACTER_PADDING = {
    BG_NONE: (1, 2, 0, 0),
    BG_GREEN_HILL_ZONE: (1, 5, 0, 0),
    BG_GHZ_8_BIT: (1, 7, 0, 0),
    BG_ANGEL_ISLAND_ZONE: (1, 5, 0, 0),
    BG_CARNIVAL_NIGHT_ZONE: (0, 0, 0, 0),
}

CLOCK_PADDING = {
    BG_NONE: (23, 9, 0, 0),
    BG_GREEN_HILL_ZONE: (23, 9, 0, 0),
    BG_GHZ_8_BIT: (23, 9, 0, 0),
    BG_ANGEL_ISLAND_ZONE: (23, 9, 0, 0),
    BG_CARNIVAL_NIGHT_ZONE: (23, 9, 0, 0),
}

DEFAULT_CHARACTER = C_SONIC_STH3
DEFAULT_BACKGROUND = BG_GREEN_HILL_ZONE
DEFAULT_LOCATION = """
{
  "timezone": "America/New_York"
}
"""
