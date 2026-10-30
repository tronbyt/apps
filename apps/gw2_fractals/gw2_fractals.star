load("animation.star", "animation")
load("images/daily_fotm_icon.png", DAILY_FOTM_ICON_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DAILY_FOTM_ICON = DAILY_FOTM_ICON_ASSET.readall()

NIGHTMARE = {
    "name_without_label": "Nightmare",
    "name_with_label": "Nightmare",
    "has_cm": True,
}
SNOWBLIND = {
    "name_without_label": "Snowblind",
    "name_with_label": "Snowblind",
    "has_cm": False,
}
VOLCANIC = {
    "name_without_label": "Volcanic",
    "name_with_label": "Volcanic",
    "has_cm": False,
}
AETHERBLADE = {
    "name_without_label": "Aetherblade",
    "name_with_label": "Aetherblade",
    "has_cm": False,
}
THAUMANOVA_REACTOR = {
    "name_without_label": "Thaumanova",
    "name_with_label": "Thaumanova",
    "has_cm": False,
}
UNCATEGORIZED = {
    "name_without_label": "Uncategorized",
    "name_with_label": "Uncategorized",
    "has_cm": False,
}
CHAOS = {
    "name_without_label": "Chaos",
    "name_with_label": "Chaos",
    "has_cm": False,
}
CLIFFSIDE = {
    "name_without_label": "Cliffside",
    "name_with_label": "Cliffside",
    "has_cm": False,
}
TWILIGHT_OASIS = {
    "name_without_label": "Twilight Oasis",
    "name_with_label": "Twilight Oas.",
    "has_cm": False,
}
CAPTAIN_MAI_TRIN_BOSS = {
    "name_without_label": "Mai Trin",
    "name_with_label": "Mai Trin",
    "has_cm": False,
}
DEEPSTONE = {
    "name_without_label": "Deepstone",
    "name_with_label": "Deepstone",
    "has_cm": False,
}
SILENT_SURF = {
    "name_without_label": "Silent Surf",
    "name_with_label": "Silent Surf",
    "has_cm": True,
}
SOLID_OCEAN = {
    "name_without_label": "Solid Ocean",
    "name_with_label": "Solid Ocean",
    "has_cm": False,
}
URBAN_BATTLEGROUND = {
    "name_without_label": "Urban Btlgrnd",
    "name_with_label": "Urban Btlgrnd",
    "has_cm": False,
}
MOLTEN_FURNACE = {
    "name_without_label": "Molten Furnace",
    "name_with_label": "Molten Furn.",
    "has_cm": False,
}
SIRENS_REEF = {
    "name_without_label": "Siren's Reef",
    "name_with_label": "Siren's Reef",
    "has_cm": False,
}
UNDERGROUND_FACILITY = {
    "name_without_label": "Undrgrnd Fac.",
    "name_with_label": "Undrgrnd Fac.",
    "has_cm": False,
}
MOLTEN_BOSS = {
    "name_without_label": "Molten Boss",
    "name_with_label": "Molten Boss",
    "has_cm": False,
}
SWAMPLAND = {
    "name_without_label": "Swampland",
    "name_with_label": "Swampland",
    "has_cm": False,
}
AQUATIC_RUINS = {
    "name_without_label": "Aquatic Ruins",
    "name_with_label": "Aquatic Ruins",
    "has_cm": False,
}
LONELY_TOWER = {
    "name_without_label": "Lonely Tower",
    "name_with_label": "Lonely Tower",
    "has_cm": True,
}
SUNQUA_PEAK = {
    "name_without_label": "Sunqua Peak",
    "name_with_label": "Sunqua Peak",
    "has_cm": True,
}
SHATTERED_OBSERVATORY = {
    "name_without_label": "Shattered",
    "name_with_label": "Shattered",
    "has_cm": True,
}
KINFALL = {
    "name_without_label": "Kinfall",
    "name_with_label": "Kinfall",
    "has_cm": False,
}

DAILY_FRACTALS = [
    (NIGHTMARE, SNOWBLIND, VOLCANIC),
    (AETHERBLADE, THAUMANOVA_REACTOR, UNCATEGORIZED),
    (CHAOS, CLIFFSIDE, TWILIGHT_OASIS),
    (CAPTAIN_MAI_TRIN_BOSS, DEEPSTONE, SILENT_SURF),
    (NIGHTMARE, SNOWBLIND, SOLID_OCEAN),
    (CHAOS, UNCATEGORIZED, URBAN_BATTLEGROUND),
    (DEEPSTONE, MOLTEN_FURNACE, SIRENS_REEF),
    (MOLTEN_BOSS, TWILIGHT_OASIS, UNDERGROUND_FACILITY),
    (SILENT_SURF, SWAMPLAND, VOLCANIC),
    (AQUATIC_RUINS, LONELY_TOWER, THAUMANOVA_REACTOR),
    (SUNQUA_PEAK, UNDERGROUND_FACILITY, URBAN_BATTLEGROUND),
    (AETHERBLADE, CHAOS, NIGHTMARE),
    (CLIFFSIDE, LONELY_TOWER, KINFALL),
    (DEEPSTONE, SOLID_OCEAN, SWAMPLAND),
    (CAPTAIN_MAI_TRIN_BOSS, MOLTEN_BOSS, SHATTERED_OBSERVATORY),
]

RECOMMENDED_FRACTALS = [
    (
        {"scale": 2, "fractal": UNCATEGORIZED},
        {"scale": 37, "fractal": SIRENS_REEF},
        {"scale": 53, "fractal": UNDERGROUND_FACILITY},
    ),
    (
        {"scale": 6, "fractal": CLIFFSIDE},
        {"scale": 28, "fractal": VOLCANIC},
        {"scale": 61, "fractal": AQUATIC_RUINS},
    ),
    (
        {"scale": 10, "fractal": MOLTEN_BOSS},
        {"scale": 32, "fractal": SWAMPLAND},
        {"scale": 65, "fractal": AETHERBLADE},
    ),
    (
        {"scale": 14, "fractal": AETHERBLADE},
        {"scale": 34, "fractal": THAUMANOVA_REACTOR},
        {"scale": 74, "fractal": SUNQUA_PEAK},
    ),
    (
        {"scale": 19, "fractal": VOLCANIC},
        {"scale": 50, "fractal": LONELY_TOWER},
        {"scale": 70, "fractal": KINFALL},
    ),
    (
        {"scale": 15, "fractal": THAUMANOVA_REACTOR},
        {"scale": 48, "fractal": SHATTERED_OBSERVATORY},
        {"scale": 60, "fractal": SOLID_OCEAN},
    ),
    (
        {"scale": 24, "fractal": SUNQUA_PEAK},
        {"scale": 35, "fractal": SOLID_OCEAN},
        {"scale": 66, "fractal": SILENT_SURF},
    ),
    (
        {"scale": 21, "fractal": SILENT_SURF},
        {"scale": 36, "fractal": UNCATEGORIZED},
        {"scale": 75, "fractal": LONELY_TOWER},
    ),
    (
        {"scale": 7, "fractal": AQUATIC_RUINS},
        {"scale": 40, "fractal": MOLTEN_BOSS},
        {"scale": 67, "fractal": DEEPSTONE},
    ),
    (
        {"scale": 8, "fractal": UNDERGROUND_FACILITY},
        {"scale": 31, "fractal": URBAN_BATTLEGROUND},
        {"scale": 54, "fractal": SIRENS_REEF},
    ),
    (
        {"scale": 11, "fractal": DEEPSTONE},
        {"scale": 39, "fractal": MOLTEN_FURNACE},
        {"scale": 59, "fractal": TWILIGHT_OASIS},
    ),
    (
        {"scale": 18, "fractal": CAPTAIN_MAI_TRIN_BOSS},
        {"scale": 27, "fractal": SNOWBLIND},
        {"scale": 64, "fractal": THAUMANOVA_REACTOR},
    ),
    (
        {"scale": 4, "fractal": URBAN_BATTLEGROUND},
        {"scale": 30, "fractal": CHAOS},
        {"scale": 58, "fractal": MOLTEN_FURNACE},
    ),
    (
        {"scale": 16, "fractal": TWILIGHT_OASIS},
        {"scale": 42, "fractal": CAPTAIN_MAI_TRIN_BOSS},
        {"scale": 62, "fractal": UNCATEGORIZED},
    ),
    (
        {"scale": 5, "fractal": SWAMPLAND},
        {"scale": 47, "fractal": NIGHTMARE},
        {"scale": 68, "fractal": CLIFFSIDE},
    ),
]

THEME = {
    "bg": "#2a173b",
    "text": "#F5DBFD",
    "text_cm": "#ff0000",
    "text_secondary": "#CA8DF0",
}

FRAMES_PER_SCREEN = 125

# The length of the months, in days. We use this for calculating the DOY index.
# The DOY index is static -- March 1 is always 60, whether it's a leap year or
# not. When not in a leap year, the index skips from 58 -> 60. Therefore, for
# the purposes of calculating our index, February always has 29 days.
CALENDAR_MONTH_DURATIONS_FOR_INDICES = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

# Returns a day of year index (0-365) that is fixed to a given month and day. Meaning that for every combination
# of month and day the index will be the same in both leap and non leap years. Notably this will skip the index
# value of 59 (February 29) in non leap years.
#
# Corresponds to https://wiki.guildwars2.com/wiki/Template:Day_of_year_index
def get_day_of_year_index():
    utc = time.now().in_location("UTC")

    index = 0
    for month in range(utc.month - 1):
        index += CALENDAR_MONTH_DURATIONS_FOR_INDICES[month]
    index += utc.day - 1

    return index

# Corresponds to the math logic from https://wiki.guildwars2.com/wiki/Template:Daily_Fractal_Schedule
def get_fractal_index():
    doy_index = get_day_of_year_index()
    fotm_index = int(math.mod(doy_index, 15))
    return fotm_index

def make_fotm(highlight_cm, label, fotm):
    FONT = "CG-pixel-3x5-mono"

    name_color = THEME["text_cm" if highlight_cm and fotm["has_cm"] else "text"]

    if label == None:
        # If we have no label, let's center-align the name and take up full row
        return render.Text(
            content = fotm["name_without_label"].upper(),
            font = FONT,
            color = name_color,
        )

    # If we have a label, let's left-align the name using all space not reserved by the two-length label
    return render.Row(
        children = [
            render.Padding(
                child = render.Text(
                    content = label.upper(),
                    font = FONT,
                    color = THEME["text_secondary"],
                ),
                pad = (1, 0, 1, 0),
            ),
            render.WrappedText(
                content = fotm["name_with_label"].upper(),
                font = FONT,
                color = name_color,
            ),
        ],
        expanded = True,
    )

def two_digit_str(num):
    return ("00" + str(num))[-2:]

def make_screen(highlight_cm, header, fractals, icon_align):
    FOTM_ICON_SIZE = 32
    FOTM_ICON_HORIZONTAL_OFFSCREEN = 8  # amount of pixels icon should go offscreen by

    if icon_align == "right":
        fotm_icon_padding_left = 64 - FOTM_ICON_SIZE + FOTM_ICON_HORIZONTAL_OFFSCREEN
    else:
        fotm_icon_padding_left = -FOTM_ICON_HORIZONTAL_OFFSCREEN

    return animation.Transformation(
        child = render.Stack(
            children = [
                render.Box(color = THEME["bg"]),
                render.Padding(
                    child = render.Image(
                        src = DAILY_FOTM_ICON,
                        width = FOTM_ICON_SIZE,
                        height = FOTM_ICON_SIZE,
                    ),
                    pad = (fotm_icon_padding_left, -10, 0, 0),
                ),
                render.Column(
                    children = [
                        render.WrappedText(
                            content = header,
                            font = "5x8",
                            color = "#ff0",
                            align = "center",
                            width = 64,
                        ),
                    ] + [render.Padding(
                        child = make_fotm(
                            highlight_cm,
                            label = x["label"],
                            fotm = x["fotm"],
                        ),
                        pad = (0, 1, 0, 0),
                    ) for x in fractals],
                    main_align = "center",
                    cross_align = "center",
                    expanded = True,
                ),
            ],
        ),
        duration = FRAMES_PER_SCREEN,
        keyframes = [],
    )

def main(config):
    fotm_index = get_fractal_index()

    screens = []

    # Daily Fractals
    if config.bool("show_dailies"):
        screens.append(
            make_screen(
                highlight_cm = config.bool("highlight_cm"),
                header = "DAILY T4",
                fractals = [{"label": None, "fotm": fotm} for fotm in DAILY_FRACTALS[fotm_index]],
                icon_align = "left",
            ),
        )

    # Recommended Fractals
    if config.bool("show_recs"):
        screens.append(
            make_screen(
                highlight_cm = False,
                header = "RECS",
                fractals = [{"label": two_digit_str(rec["scale"]), "fotm": rec["fractal"]} for rec in RECOMMENDED_FRACTALS[fotm_index]],
                icon_align = "right",
            ),
        )

    # Render
    if len(screens) == 0:
        return []

    return render.Root(
        child = render.Sequence(children = screens),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "show_dailies",
                name = "Daily T4s",
                desc = "Show today's Daily T4 Fractals",
                icon = "eye",
                default = True,
            ),
            schema.Toggle(
                id = "show_recs",
                name = "Recommended Fractals",
                desc = "Show today's Recommended Fractals",
                icon = "eye",
                default = True,
            ),
            schema.Toggle(
                id = "highlight_cm",
                name = "Highlight CMs",
                desc = "Display T4 fractals with challenge modes in red font.",
                icon = "skullCrossbones",
                default = True,
            ),
        ],
    )
