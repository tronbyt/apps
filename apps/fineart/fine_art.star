"""
Applet: Fine Art
Summary: Paintings and Fine Art
Description: The masterpieces of van Gogh, Picasso, Monet, and more.
Author: chrisbateman
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

MS_PER_FRAME = 32
FRAMES_PER_SECOND = 1000 / MS_PER_FRAME
MAX_APP_TIME = 15
MARQUEE_OFFSET_START = 10
MARQUEE_OFFSET_END = 10
PAN_SPEED = 12

def main(config):
    caption = config.bool("caption", False)
    rotate_daily = config.bool("rotate_daily", True)
    configIndex = config.str("index")

    # Tidbyt animates slower than pixlet serve does
    dev = config.bool("dev", False)
    set_prod_adjust_ratio(1 if dev else 0.44)
    frame_delay = math.round(MS_PER_FRAME * get_prod_adjust_ratio())

    if rotate_daily:
        # rotate at 2am
        timezone = time.tz()
        now = time.now().in_location(timezone)
        two_hours_back = time.from_timestamp(now.unix - (2 * 60 * 60)).in_location(timezone)
        start_of_day_utc = time.time(year = two_hours_back.year, month = two_hours_back.month, day = two_hours_back.day, hour = 0, minute = 0, second = 0)
        unix_day = int(math.round(start_of_day_utc.unix / 60 / 60 / 24))

        index = unix_day % len(PAINTINGS)
    else:
        index = random.number(0, len(PAINTINGS) - 1)

    # for dev
    if configIndex:
        index = int(configIndex)

    painting = PAINTINGS[index]

    transform_start, transform_final, padding_final = get_transforms(painting)

    image = render.Image(src = painting["binary"])
    finalFrame = render.Padding(
        child = image,
        pad = padding_final,
    )

    pan_animation, pan_time = get_simple_pan(image, transform_start, transform_final)

    if caption:
        title = painting["title"] + " - " + painting["artistLast"]
        caption_animation, caption_time = get_caption(title)

        animations = [
            pan_animation,
            render.Stack(
                children = [
                    finalFrame,
                    caption_animation,
                ],
            ),
            get_still_frames(finalFrame, MAX_APP_TIME - pan_time - caption_time + 1),
        ]
    else:
        animations = [
            pan_animation,
            get_still_frames(finalFrame, MAX_APP_TIME - pan_time + 1),
        ]

    return render.Root(
        delay = int(frame_delay),
        child = render.Sequence(children = animations),
    )

####

def set_prod_adjust_ratio(val):
    # Using cache as a mutable global
    cache.set("PROD_ADJUST_RATIO", str(val))

def get_prod_adjust_ratio():
    return float(cache.get("PROD_ADJUST_RATIO"))

def get_caption(text):
    # 4 pixels/character for monospaced tom-thumb
    text_length = len(text) * 4

    pos_start = 64 - MARQUEE_OFFSET_START
    pos_end = -text_length + MARQUEE_OFFSET_END
    distance = pos_start - pos_end
    duration = int(distance / 1.75)
    pos_increment = distance / duration

    if (text_length < 65):
        pos_start = 0
        pos_increment = 0
        duration = 220

    frames = []

    for i in range(duration):
        pos = pos_start - int(math.round(pos_increment * i))

        opacity_percent = get_fade_opacity(i, duration)
        box_opacity = to_hex(opacity_percent * 0.5 * 255)
        text_opacity = to_hex(opacity_percent * 255)

        frames.append(
            render.Padding(
                child = render.Stack(children = [
                    render.Box(
                        width = 64,
                        height = 6,
                        color = "000000%s" % box_opacity,
                    ),
                    render.Padding(
                        child = render.Text(text, font = "tom-thumb", color = "#ffffff%s" % text_opacity),
                        pad = (pos, 0, 0, 0),
                    ),
                ]),
                pad = (0, 32 - 6, 0, 0),
            ),
        )

    return render.Animation(children = frames), duration / FRAMES_PER_SECOND

def get_fade_opacity(i, duration):
    if i < 10:
        return i * 0.1
    elif i > duration - 10:
        return (duration - i) * 0.1
    else:
        return 1

def to_hex(i):
    hex = "%x" % i

    if len(hex) == 1:
        hex = "0" + hex

    return hex

def get_still_frames(child, seconds):
    frame_count = get_frame_count_still(seconds)

    return render.Animation(
        children = [child for x in range(frame_count)],
    )

def get_transforms(painting):
    framing_offset = -abs(painting.get("framing")) if "framing" in painting else 0

    if painting["height"] > 32:
        transform_start = get_start_transform(painting, framing_offset, "vertical")
        transform_final = animation.Translate(0, framing_offset)
        final_framing = (0, framing_offset, 0, 0)
    elif painting["width"] > 64:
        transform_start = get_start_transform(painting, framing_offset, "horizontal")
        transform_final = animation.Translate(framing_offset, 0)
        final_framing = (framing_offset, 0, 0, 0)
    else:
        transform_start = animation.Translate(0, 0)
        transform_final = animation.Translate(0, 0)
        final_framing = (0, 0, 0, 0)

    return transform_start, transform_final, final_framing

def get_start_transform(painting, framing_offset, orientation):
    if orientation == "vertical":
        center = abs(framing_offset) + (32 / 2)

        if center / painting["height"] > 0.5:
            return animation.Translate(0, 0)
        else:
            return animation.Translate(0, -abs(painting["height"] - 32))
    else:
        center = abs(framing_offset) + (64 / 2)

        if center / painting["width"] > 0.5:
            return animation.Translate(0, 0)
        else:
            return animation.Translate(-abs(painting["width"] - 64), 0)

def get_simple_pan(child, transform_start, transform_final):
    delay_seconds = 0.25
    pan_distance = abs((transform_start.x or transform_start.y) - (transform_final.x or transform_final.y))
    pan_time = max(3, pan_distance / PAN_SPEED)

    return animation.Transformation(
        child = child,
        duration = get_frame_count(pan_time),
        delay = get_frame_count_still(delay_seconds),
        keyframes = [
            animation.Keyframe(
                percentage = 0,
                curve = "ease_in_out",
                transforms = [transform_start],
            ),
            animation.Keyframe(
                percentage = 1,
                curve = "ease_in_out",
                transforms = [transform_final],
            ),
        ],
    ), pan_time

def get_frame_count(seconds):
    return int(math.round(seconds * FRAMES_PER_SECOND))

def get_frame_count_still(seconds):
    return int(math.round(seconds * FRAMES_PER_SECOND / get_prod_adjust_ratio()))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "caption",
                name = "Show caption",
                desc = "Show title and artist",
                icon = "tag",
                default = True,
            ),
            schema.Toggle(
                id = "rotate_daily",
                name = "Rotate daily",
                desc = "Rotate paintings daily, instead of constantly",
                icon = "calendarDay",
                default = True,
            ),
        ],
    )

PAINTINGS = [
    {
        "binary": VAN_GOGH_STARRY_NIGHT_ASSET.readall(),
        "title": "Starry Night",
        "artistFirst": "Vincent",
        "artistLast": "van Gogh",
        "width": 64,
        "height": 51,
        "framing": 8,
    },
    {
        "binary": MONDRIAN_COMPOSITION_WITH_RED_BLUE_AND_YELLOW_ASSET.readall(),
        "title": "Composition with Red Blue and Yellow",
        "artistFirst": "Piet",
        "artistLast": "Mondrian",
        "width": 64,
        "height": 64,
        "framing": 32,
    },
    {
        "binary": SEURAT_A_SUNDAY_AFTERNOON_ON_THE_ISLAND_OF_LA_GRANDE_JATTE_ASSET.readall(),
        "title": "A Sunday Afternoon on the Island of La Grande Jatte",
        "artistFirst": "Georges",
        "artistLast": "Seurat",
        "width": 64,
        "height": 43,
        "framing": 4,
    },
    {
        "binary": MUNCH_THE_SCREAM_ASSET.readall(),
        "title": "The Scream",
        "artistFirst": "Edvard",
        "artistLast": "Munch",
        "width": 64,
        "height": 79,
        "framing": 28,
    },
    {
        "binary": GOYA_THE_THIRD_OF_MAY_1808_ASSET.readall(),
        "title": "The Third of May 1808",
        "artistFirst": "Francisco ",
        "artistLast": "Goya",
        "width": 64,
        "height": 49,
        "framing": 14,
    },
    {
        "binary": RAPHAEL_THE_SCHOOL_OF_ATHENS_ASSET.readall(),
        "title": "The School of Athens",
        "artistFirst": "",
        "artistLast": "Raphael",
        "width": 64,
        "height": 46,
        "framing": 11,
    },
    {
        "binary": RENOIR_DANCE_AT_LE_MOULIN_DE_LA_GALETTE_ASSET.readall(),
        "title": "Dance at Le moulin de la Galette",
        "artistFirst": "Pierre-Auguste",
        "artistLast": "Renoir",
        "width": 64,
        "height": 48,
        "framing": 10,
    },
    {
        "binary": VAN_GOGH_SELF_PORTRAIT_1889__ASSET.readall(),
        "title": "Self-Portrait (1889)",
        "artistFirst": "Vincent",
        "artistLast": "van Gogh",
        "width": 64,
        "height": 77,
        "framing": 16,
    },
    {
        "binary": WOOD_AMERICAN_GOTHIC_ASSET.readall(),
        "title": "American Gothic",
        "artistFirst": "Grant",
        "artistLast": "Wood",
        "width": 64,
        "height": 77,
        "framing": 10,
    },
    {
        "binary": PICASSO_THREE_MUSICIANS_ASSET.readall(),
        "title": "Three Musicians",
        "artistFirst": "Pablo",
        "artistLast": "Picasso",
        "width": 64,
        "height": 58,
        "framing": 4,
    },
    {
        "binary": DALI_THE_PERSISTENCE_OF_MEMORY_ASSET.readall(),
        "title": "The Persistence of Memory",
        "artistFirst": "Salvador",
        "artistLast": "Dali",
        "width": 64,
        "height": 47,
        "framing": 9,
    },
    {
        "binary": MONET_IMPRESSION_SUNRISE_ASSET.readall(),
        "title": "Impression, Sunrise",
        "artistFirst": "Claude",
        "artistLast": "Monet",
        "width": 64,
        "height": 50,
        "framing": 9,
    },
    {
        "binary": HOPPER_NIGHTHAWKS_ASSET.readall(),
        "title": "Nighthawks",
        "artistFirst": "Edward",
        "artistLast": "Hopper",
        "width": 64,
        "height": 32,
    },
    {
        "binary": DELACROIX_LIBERTY_LEADING_THE_PEOPLE_ASSET.readall(),
        "title": "Liberty Leading the People",
        "artistFirst": "Eugène",
        "artistLast": "Delacroix",
        "width": 64,
        "height": 51,
        "framing": 0,
    },
    {
        "binary": VAN_EYCK_ARNOLFINI_PORTRAIT_ASSET.readall(),
        "title": "Arnolfini Portrait",
        "artistFirst": "Jan",
        "artistLast": "van Eyck",
        "width": 64,
        "height": 88,
        "framing": 12,
    },
    {
        "binary": VAN_GOGH_CAF_TERRACE_AT_NIGHT_ASSET.readall(),
        "title": "Café Terrace at Night",
        "artistFirst": "Vincent",
        "artistLast": "van Gogh",
        "width": 64,
        "height": 80,
        "framing": 35,
    },
    {
        "binary": BASQUIAT_UNTITLED_1982__ASSET.readall(),
        "title": "Untitled (1982)",
        "artistFirst": "Jean-Michel",
        "artistLast": "Basquiat",
        "width": 64,
        "height": 68,
        "framing": 18,
    },
    {
        "binary": WHISTLER_WHISTLER_S_MOTHER_ASSET.readall(),
        "title": "Whistler's Mother",
        "artistFirst": "James",
        "artistLast": "Whistler",
        "width": 64,
        "height": 57,
        "framing": 6,
    },
    {
        "binary": MAGRITTE_THE_SON_OF_MAN_ASSET.readall(),
        "title": "The Son of Man",
        "artistFirst": "René",
        "artistLast": "Magritte",
        "width": 64,
        "height": 90,
        "framing": 9,
    },
    {
        "binary": REMBRANDT_THE_NIGHT_WATCH_ASSET.readall(),
        "title": "The Night Watch",
        "artistFirst": "",
        "artistLast": "Rembrandt",
        "width": 64,
        "height": 53,
        "framing": 20,
    },
    {
        "binary": PICASSO_LES_DEMOISELLES_D_AVIGNON_ASSET.readall(),
        "title": "Les Demoiselles d'Avignon",
        "artistFirst": "Pablo",
        "artistLast": "Picasso",
        "width": 64,
        "height": 66,
        "framing": 5,
    },
    {
        "binary": VEL_ZQUEZ_LAS_MENINAS_ASSET.readall(),
        "title": "Las Meninas",
        "artistFirst": "Diego",
        "artistLast": "Velázquez",
        "width": 64,
        "height": 74,
        "framing": 38,
    },
    {
        "binary": KANDINSKY_TRANSVERSE_LINE_ASSET.readall(),
        "title": "Transverse Line",
        "artistFirst": "Wassily",
        "artistLast": "Kandinsky",
        "width": 64,
        "height": 44,
        "framing": 8,
    },
    {
        "binary": FRIEDRICH_WANDERER_ABOVE_THE_SEA_OF_FOG_ASSET.readall(),
        "title": "Wanderer above the Sea of Fog",
        "artistFirst": "Caspar",
        "artistLast": "Friedrich",
        "width": 64,
        "height": 82,
        "framing": 25,
    },
    {
        "binary": VAN_GOGH_STARRY_NIGHT_OVER_THE_RH_NE_ASSET.readall(),
        "title": "Starry Night Over the Rhône",
        "artistFirst": "Vincent",
        "artistLast": "van Gogh",
        "width": 64,
        "height": 50,
        "framing": 4,
    },
    {
        "binary": MONET_SAN_GIORGIO_MAGGIORE_AT_DUSK_ASSET.readall(),
        "title": "San Giorgio Maggiore at Dusk",
        "artistFirst": "Claude",
        "artistLast": "Monet",
        "width": 64,
        "height": 45,
        "framing": 0,
    },
    {
        "binary": VERMEER_THE_MILKMAID_ASSET.readall(),
        "title": "The Milkmaid",
        "artistFirst": "Johannes",
        "artistLast": "Vermeer",
        "width": 64,
        "height": 72,
        "framing": 13,
    },
    {
        "binary": HOKUSAI_THE_GREAT_WAVE_OFF_KANAGAWA_ASSET.readall(),
        "title": "The Great Wave off Kanagawa",
        "artistFirst": "Katsushika",
        "artistLast": "Hokusai",
        "width": 64,
        "height": 43,
        "framing": 5,
    },
    {
        "binary": BOTTICELLI_THE_BIRTH_OF_VENUS_ASSET.readall(),
        "title": "The Birth of Venus",
        "artistFirst": "Sandro",
        "artistLast": "Botticelli",
        "width": 64,
        "height": 40,
        "framing": 2,
    },
    {
        "binary": DA_VINCI_THE_LAST_SUPPER_ASSET.readall(),
        "title": "The Last Supper",
        "artistFirst": "Leonardo",
        "artistLast": "da Vinci",
        "width": 64,
        "height": 32,
    },
    {
        "binary": RIVERA_THE_FLOWER_CARRIER_ASSET.readall(),
        "title": "The Flower Carrier",
        "artistFirst": "Diego",
        "artistLast": "Rivera",
        "width": 64,
        "height": 64,
        "framing": 9,
    },
    {
        "binary": PICASSO_GUERNICA_ASSET.readall(),
        "title": "Guernica",
        "artistFirst": "Pablo",
        "artistLast": "Picasso",
        "width": 70,
        "height": 32,
        "framing": 0,
    },
    {
        "binary": VAN_GOGH_WHEAT_FIELD_WITH_CYPRESSES_ASSET.readall(),
        "title": "Wheat Field with Cypresses",
        "artistFirst": "Vincent",
        "artistLast": "van Gogh",
        "width": 64,
        "height": 50,
        "framing": 10,
    },
    {
        "binary": POLLOCK_UNTITLED_ASSET.readall(),
        "title": "Untitled",
        "artistFirst": "Jackson",
        "artistLast": "Pollock",
        "width": 64,
        "height": 46,
    },
    {
        "binary": KLIMT_THE_KISS_ASSET.readall(),
        "title": "The Kiss",
        "artistFirst": "Gustav",
        "artistLast": "Klimt",
        "width": 64,
        "height": 64,
        "framing": 0,
    },
    {
        "binary": MICHELANGELO_THE_CREATION_OF_ADAM_ASSET.readall(),
        "title": "The Creation of Adam",
        "artistFirst": "",
        "artistLast": "Michelangelo",
        "width": 64,
        "height": 32,
    },
    {
        "binary": MONET_WOMAN_WITH_A_PARASOL_ASSET.readall(),
        "title": "Woman with a Parasol",
        "artistFirst": "Claude",
        "artistLast": "Monet",
        "width": 64,
        "height": 79,
        "framing": 28,
    },
    {
        "binary": PICASSO_PORTRAIT_OF_DORA_MAAR_ASSET.readall(),
        "title": "Portrait of Dora Maar",
        "artistFirst": "Pablo",
        "artistLast": "Picasso",
        "width": 64,
        "height": 89,
        "framing": 10,
    },
    {
        "binary": KAHLO_THE_TWO_FRIDAS_ASSET.readall(),
        "title": "The Two Fridas",
        "artistFirst": "Frida",
        "artistLast": "Kahlo",
        "width": 64,
        "height": 64,
        "framing": 3,
    },
    {
        "binary": VAN_GOGH_THE_RED_VINEYARD_ASSET.readall(),
        "title": "The Red Vineyard",
        "artistFirst": "Vincent",
        "artistLast": "van Gogh",
        "width": 64,
        "height": 50,
        "framing": 0,
    },
    {
        "binary": VERMEER_GIRL_WITH_A_PEARL_EARRING_ASSET.readall(),
        "title": "Girl with a Pearl Earring",
        "artistFirst": "Johannes",
        "artistLast": "Vermeer",
        "width": 64,
        "height": 76,
        "framing": 18,
    },
    {
        "binary": MANET_A_BAR_AT_THE_FOLIES_BERG_RE_ASSET.readall(),
        "title": "A Bar at the Folies-Bergère",
        "artistFirst": "Édouard",
        "artistLast": "Manet",
        "width": 64,
        "height": 47,
        "framing": 2,
    },
    {
        "binary": MILLET_THE_GLEANERS_ASSET.readall(),
        "title": "The Gleaners",
        "artistFirst": "Jean-François",
        "artistLast": "Millet",
        "width": 64,
        "height": 48,
        "framing": 11,
    },
    {
        "binary": BLOCH_IN_A_ROMAN_OSTERIA_ASSET.readall(),
        "title": "In a Roman Osteria",
        "artistFirst": "Carl",
        "artistLast": "Bloch",
        "width": 64,
        "height": 51,
        "framing": 9,
    },
    {
        "binary": TURNER_THE_FIGHTING_TEMERAIRE_ASSET.readall(),
        "title": "The Fighting Temeraire",
        "artistFirst": "J. M. W.",
        "artistLast": "Turner",
        "width": 64,
        "height": 48,
        "framing": 16,
    },
    {
        "binary": C_ZANNE_MONT_SAINTE_VICTOIRE_ASSET.readall(),
        "title": "Mont Sainte-Victoire",
        "artistFirst": "Paul",
        "artistLast": "Cézanne",
        "width": 64,
        "height": 42,
        "framing": 4,
    },
    {
        "binary": MONET_WATER_LILIES_ASSET.readall(),
        "title": "Water Lilies",
        "artistFirst": "Claude",
        "artistLast": "Monet",
        "width": 64,
        "height": 32,
    },
    {
        "binary": VAN_GOGH_WHEATFIELD_WITH_CROWS_ASSET.readall(),
        "title": "Wheatfield with Crows",
        "artistFirst": "Vincent",
        "artistLast": "van Gogh",
        "width": 64,
        "height": 32,
    },
    {
        "binary": KANDINSKY_THE_BLUE_RIDER_ASSET.readall(),
        "title": "The Blue Rider",
        "artistFirst": "Wassily",
        "artistLast": "Kandinsky",
        "width": 64,
        "height": 60,
        "framing": 15,
    },
    {
        "binary": BOSCH_THE_GARDEN_OF_EARTHLY_DELIGHTS_ASSET.readall(),
        "title": "The Garden of Earthly Delights",
        "artistFirst": "Hieronymus",
        "artistLast": "Bosch",
        "width": 64,
        "height": 32,
    },
    {
        "binary": RENOIR_LUNCHEON_OF_THE_BOATING_PARTY_ASSET.readall(),
        "title": "Luncheon of the Boating Party",
        "artistFirst": "Pierre-Auguste",
        "artistLast": "Renoir",
        "width": 64,
        "height": 47,
        "framing": 3,
    },
    {
        "binary": DEGAS_THE_ABSINTHE_DRINKER_ASSET.readall(),
        "title": "The Absinthe Drinker",
        "artistFirst": "Edgar",
        "artistLast": "Degas",
        "width": 64,
        "height": 88,
        "framing": 10,
    },
    {
        "binary": DA_VINCI_MONA_LISA_ASSET.readall(),
        "title": "Mona Lisa",
        "artistFirst": "Leonardo",
        "artistLast": "da Vinci",
        "width": 64,
        "height": 95,
        "framing": 10,
    },
    {
        "binary": DELAROCHE_THE_EXECUTION_OF_LADY_JANE_GREY_ASSET.readall(),
        "title": "The Execution of Lady Jane Grey",
        "artistFirst": "Paul",
        "artistLast": "Delaroche",
        "width": 64,
        "height": 53,
        "framing": 13,
    },
    {
        "binary": TANNER_THE_BANJO_LESSON_ASSET.readall(),
        "title": "The Banjo Lesson",
        "artistFirst": "Henry Ossawa",
        "artistLast": "Tanner",
        "width": 64,
        "height": 91,
        "framing": 15,
    },
    {
        "binary": CONSTABLE_THE_HAY_WAIN_ASSET.readall(),
        "title": "The Hay Wain",
        "artistFirst": "John",
        "artistLast": "Constable",
        "width": 64,
        "height": 44,
        "framing": 10,
    },
    {
        "binary": LEUTZE_WASHINGTON_CROSSING_THE_DELAWARE_ASSET.readall(),
        "title": "Washington Crossing the Delaware",
        "artistFirst": "Emanuel",
        "artistLast": "Leutze",
        "width": 64,
        "height": 32,
        "framing": 4,
    },
    {
        "binary": MATEJKO_STA_CZYK_ASSET.readall(),
        "title": "Stańczyk",
        "artistFirst": "Jan",
        "artistLast": "Matejko",
        "width": 64,
        "height": 47,
        "framing": 8,
    },
    {
        "binary": WYETH_CHRISTINA_S_WORLD_ASSET.readall(),
        "title": "Christina's World",
        "artistFirst": "Andrew",
        "artistLast": "Wyeth",
        "width": 64,
        "height": 43,
        "framing": 4,
    },
    {
        "binary": VAN_GOGH_THE_NIGHT_CAF__ASSET.readall(),
        "title": "The Night Café",
        "artistFirst": "Vincent",
        "artistLast": "van Gogh",
        "width": 64,
        "height": 51,
        "framing": 5,
    },
    {
        "binary": LAM_THE_JUNGLE_ASSET.readall(),
        "title": "The Jungle",
        "artistFirst": "Wilfredo",
        "artistLast": "Lam",
        "width": 64,
        "height": 67,
        "framing": 10,
    },
    {
        "binary": REMBRANDT_THE_ANATOMY_LESSON_OF_DR_NICOLAES_TULP_ASSET.readall(),
        "title": "The Anatomy Lesson of Dr. Nicolaes Tulp",
        "artistFirst": "",
        "artistLast": "Rembrandt",
        "width": 64,
        "height": 48,
        "framing": 7,
    },
    {
        "binary": DAVID_THE_DEATH_OF_MARAT_ASSET.readall(),
        "title": "The Death of Marat",
        "artistFirst": "Jacques-Louis",
        "artistLast": "David",
        "width": 64,
        "height": 51,
        "framing": 0,
    },
    {
        "binary": GENTILESCHI_JUDITH_SLAYING_HOLOFERNES_ASSET.readall(),
        "title": "Judith Slaying Holofernes",
        "artistFirst": "Artemisia",
        "artistLast": "Gentileschi",
        "width": 64,
        "height": 78,
        "framing": 25,
    },
    {
        "binary": LEIGHTON_FLAMING_JUNE_ASSET.readall(),
        "title": "Flaming June",
        "artistFirst": "Frederic",
        "artistLast": "Leighton",
        "width": 64,
        "height": 65,
        "framing": 11,
    },
    {
        "binary": THOMAS_THE_ECLIPSE_ASSET.readall(),
        "title": "The Eclipse",
        "artistFirst": "Alma",
        "artistLast": "Thomas",
        "width": 64,
        "height": 79,
        "framing": 23,
    },
]
