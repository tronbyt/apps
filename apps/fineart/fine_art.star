"""
Applet: Fine Art
Summary: Paintings and Fine Art
Description: The masterpieces of van Gogh, Picasso, Monet, and more.
Author: chrisbateman
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("images/basquiat_untitled_1982_.png", BASQUIAT_UNTITLED_1982__ASSET = "file")
load("images/bloch_in_a_roman_osteria.png", BLOCH_IN_A_ROMAN_OSTERIA_ASSET = "file")
load("images/bosch_the_garden_of_earthly_delights.png", BOSCH_THE_GARDEN_OF_EARTHLY_DELIGHTS_ASSET = "file")
load("images/botticelli_the_birth_of_venus.png", BOTTICELLI_THE_BIRTH_OF_VENUS_ASSET = "file")
load("images/c_zanne_mont_sainte_victoire.png", C_ZANNE_MONT_SAINTE_VICTOIRE_ASSET = "file")
load("images/constable_the_hay_wain.png", CONSTABLE_THE_HAY_WAIN_ASSET = "file")
load("images/da_vinci_mona_lisa.png", DA_VINCI_MONA_LISA_ASSET = "file")
load("images/da_vinci_the_last_supper.png", DA_VINCI_THE_LAST_SUPPER_ASSET = "file")
load("images/dali_the_persistence_of_memory.png", DALI_THE_PERSISTENCE_OF_MEMORY_ASSET = "file")
load("images/david_the_death_of_marat.png", DAVID_THE_DEATH_OF_MARAT_ASSET = "file")
load("images/degas_the_absinthe_drinker.png", DEGAS_THE_ABSINTHE_DRINKER_ASSET = "file")
load("images/delacroix_liberty_leading_the_people.png", DELACROIX_LIBERTY_LEADING_THE_PEOPLE_ASSET = "file")
load("images/delaroche_the_execution_of_lady_jane_grey.png", DELAROCHE_THE_EXECUTION_OF_LADY_JANE_GREY_ASSET = "file")
load("images/friedrich_wanderer_above_the_sea_of_fog.png", FRIEDRICH_WANDERER_ABOVE_THE_SEA_OF_FOG_ASSET = "file")
load("images/gentileschi_judith_slaying_holofernes.png", GENTILESCHI_JUDITH_SLAYING_HOLOFERNES_ASSET = "file")
load("images/goya_the_third_of_may_1808.png", GOYA_THE_THIRD_OF_MAY_1808_ASSET = "file")
load("images/hokusai_the_great_wave_off_kanagawa.png", HOKUSAI_THE_GREAT_WAVE_OFF_KANAGAWA_ASSET = "file")
load("images/hopper_nighthawks.png", HOPPER_NIGHTHAWKS_ASSET = "file")
load("images/kahlo_the_two_fridas.png", KAHLO_THE_TWO_FRIDAS_ASSET = "file")
load("images/kandinsky_the_blue_rider.png", KANDINSKY_THE_BLUE_RIDER_ASSET = "file")
load("images/kandinsky_transverse_line.png", KANDINSKY_TRANSVERSE_LINE_ASSET = "file")
load("images/klimt_the_kiss.png", KLIMT_THE_KISS_ASSET = "file")
load("images/lam_the_jungle.png", LAM_THE_JUNGLE_ASSET = "file")
load("images/leighton_flaming_june.png", LEIGHTON_FLAMING_JUNE_ASSET = "file")
load("images/leutze_washington_crossing_the_delaware.png", LEUTZE_WASHINGTON_CROSSING_THE_DELAWARE_ASSET = "file")
load("images/magritte_the_son_of_man.png", MAGRITTE_THE_SON_OF_MAN_ASSET = "file")
load("images/manet_a_bar_at_the_folies_berg_re.png", MANET_A_BAR_AT_THE_FOLIES_BERG_RE_ASSET = "file")
load("images/matejko_sta_czyk.png", MATEJKO_STA_CZYK_ASSET = "file")
load("images/michelangelo_the_creation_of_adam.png", MICHELANGELO_THE_CREATION_OF_ADAM_ASSET = "file")
load("images/millet_the_gleaners.png", MILLET_THE_GLEANERS_ASSET = "file")
load("images/mondrian_composition_with_red_blue_and_yellow.png", MONDRIAN_COMPOSITION_WITH_RED_BLUE_AND_YELLOW_ASSET = "file")
load("images/monet_impression_sunrise.png", MONET_IMPRESSION_SUNRISE_ASSET = "file")
load("images/monet_san_giorgio_maggiore_at_dusk.png", MONET_SAN_GIORGIO_MAGGIORE_AT_DUSK_ASSET = "file")
load("images/monet_water_lilies.png", MONET_WATER_LILIES_ASSET = "file")
load("images/monet_woman_with_a_parasol.png", MONET_WOMAN_WITH_A_PARASOL_ASSET = "file")
load("images/munch_the_scream.png", MUNCH_THE_SCREAM_ASSET = "file")
load("images/picasso_guernica.png", PICASSO_GUERNICA_ASSET = "file")
load("images/picasso_les_demoiselles_d_avignon.png", PICASSO_LES_DEMOISELLES_D_AVIGNON_ASSET = "file")
load("images/picasso_portrait_of_dora_maar.png", PICASSO_PORTRAIT_OF_DORA_MAAR_ASSET = "file")
load("images/picasso_three_musicians.png", PICASSO_THREE_MUSICIANS_ASSET = "file")
load("images/pollock_untitled.png", POLLOCK_UNTITLED_ASSET = "file")
load("images/raphael_the_school_of_athens.png", RAPHAEL_THE_SCHOOL_OF_ATHENS_ASSET = "file")
load("images/rembrandt_the_anatomy_lesson_of_dr_nicolaes_tulp.png", REMBRANDT_THE_ANATOMY_LESSON_OF_DR_NICOLAES_TULP_ASSET = "file")
load("images/rembrandt_the_night_watch.png", REMBRANDT_THE_NIGHT_WATCH_ASSET = "file")
load("images/renoir_dance_at_le_moulin_de_la_galette.png", RENOIR_DANCE_AT_LE_MOULIN_DE_LA_GALETTE_ASSET = "file")
load("images/renoir_luncheon_of_the_boating_party.png", RENOIR_LUNCHEON_OF_THE_BOATING_PARTY_ASSET = "file")
load("images/rivera_the_flower_carrier.png", RIVERA_THE_FLOWER_CARRIER_ASSET = "file")
load("images/seurat_a_sunday_afternoon_on_the_island_of_la_grande_jatte.png", SEURAT_A_SUNDAY_AFTERNOON_ON_THE_ISLAND_OF_LA_GRANDE_JATTE_ASSET = "file")
load("images/tanner_the_banjo_lesson.png", TANNER_THE_BANJO_LESSON_ASSET = "file")
load("images/thomas_the_eclipse.png", THOMAS_THE_ECLIPSE_ASSET = "file")
load("images/turner_the_fighting_temeraire.png", TURNER_THE_FIGHTING_TEMERAIRE_ASSET = "file")
load("images/van_eyck_arnolfini_portrait.png", VAN_EYCK_ARNOLFINI_PORTRAIT_ASSET = "file")
load("images/van_gogh_caf_terrace_at_night.png", VAN_GOGH_CAF_TERRACE_AT_NIGHT_ASSET = "file")
load("images/van_gogh_self_portrait_1889_.png", VAN_GOGH_SELF_PORTRAIT_1889__ASSET = "file")
load("images/van_gogh_starry_night.png", VAN_GOGH_STARRY_NIGHT_ASSET = "file")
load("images/van_gogh_starry_night_over_the_rh_ne.png", VAN_GOGH_STARRY_NIGHT_OVER_THE_RH_NE_ASSET = "file")
load("images/van_gogh_the_night_caf_.png", VAN_GOGH_THE_NIGHT_CAF_ASSET = "file")
load("images/van_gogh_the_red_vineyard.png", VAN_GOGH_THE_RED_VINEYARD_ASSET = "file")
load("images/van_gogh_wheat_field_with_cypresses.png", VAN_GOGH_WHEAT_FIELD_WITH_CYPRESSES_ASSET = "file")
load("images/van_gogh_wheatfield_with_crows.png", VAN_GOGH_WHEATFIELD_WITH_CROWS_ASSET = "file")
load("images/vel_zquez_las_meninas.png", VEL_ZQUEZ_LAS_MENINAS_ASSET = "file")
load("images/vermeer_girl_with_a_pearl_earring.png", VERMEER_GIRL_WITH_A_PEARL_EARRING_ASSET = "file")
load("images/vermeer_the_milkmaid.png", VERMEER_THE_MILKMAID_ASSET = "file")
load("images/whistler_whistler_s_mother.png", WHISTLER_WHISTLER_S_MOTHER_ASSET = "file")
load("images/wood_american_gothic.png", WOOD_AMERICAN_GOTHIC_ASSET = "file")
load("images/wyeth_christina_s_world.png", WYETH_CHRISTINA_S_WORLD_ASSET = "file")
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

    image = render.Image(src = painting["binary"].readall())
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
        "binary": VAN_GOGH_STARRY_NIGHT_ASSET,
        "title": "Starry Night",
        "artistFirst": "Vincent",
        "artistLast": "van Gogh",
        "width": 64,
        "height": 51,
        "framing": 8,
    },
    {
        "binary": MONDRIAN_COMPOSITION_WITH_RED_BLUE_AND_YELLOW_ASSET,
        "title": "Composition with Red Blue and Yellow",
        "artistFirst": "Piet",
        "artistLast": "Mondrian",
        "width": 64,
        "height": 64,
        "framing": 32,
    },
    {
        "binary": SEURAT_A_SUNDAY_AFTERNOON_ON_THE_ISLAND_OF_LA_GRANDE_JATTE_ASSET,
        "title": "A Sunday Afternoon on the Island of La Grande Jatte",
        "artistFirst": "Georges",
        "artistLast": "Seurat",
        "width": 64,
        "height": 43,
        "framing": 4,
    },
    {
        "binary": MUNCH_THE_SCREAM_ASSET,
        "title": "The Scream",
        "artistFirst": "Edvard",
        "artistLast": "Munch",
        "width": 64,
        "height": 79,
        "framing": 28,
    },
    {
        "binary": GOYA_THE_THIRD_OF_MAY_1808_ASSET,
        "title": "The Third of May 1808",
        "artistFirst": "Francisco ",
        "artistLast": "Goya",
        "width": 64,
        "height": 49,
        "framing": 14,
    },
    {
        "binary": RAPHAEL_THE_SCHOOL_OF_ATHENS_ASSET,
        "title": "The School of Athens",
        "artistFirst": "",
        "artistLast": "Raphael",
        "width": 64,
        "height": 46,
        "framing": 11,
    },
    {
        "binary": RENOIR_DANCE_AT_LE_MOULIN_DE_LA_GALETTE_ASSET,
        "title": "Dance at Le moulin de la Galette",
        "artistFirst": "Pierre-Auguste",
        "artistLast": "Renoir",
        "width": 64,
        "height": 48,
        "framing": 10,
    },
    {
        "binary": VAN_GOGH_SELF_PORTRAIT_1889__ASSET,
        "title": "Self-Portrait (1889)",
        "artistFirst": "Vincent",
        "artistLast": "van Gogh",
        "width": 64,
        "height": 77,
        "framing": 16,
    },
    {
        "binary": WOOD_AMERICAN_GOTHIC_ASSET,
        "title": "American Gothic",
        "artistFirst": "Grant",
        "artistLast": "Wood",
        "width": 64,
        "height": 77,
        "framing": 10,
    },
    {
        "binary": PICASSO_THREE_MUSICIANS_ASSET,
        "title": "Three Musicians",
        "artistFirst": "Pablo",
        "artistLast": "Picasso",
        "width": 64,
        "height": 58,
        "framing": 4,
    },
    {
        "binary": DALI_THE_PERSISTENCE_OF_MEMORY_ASSET,
        "title": "The Persistence of Memory",
        "artistFirst": "Salvador",
        "artistLast": "Dali",
        "width": 64,
        "height": 47,
        "framing": 9,
    },
    {
        "binary": MONET_IMPRESSION_SUNRISE_ASSET,
        "title": "Impression, Sunrise",
        "artistFirst": "Claude",
        "artistLast": "Monet",
        "width": 64,
        "height": 50,
        "framing": 9,
    },
    {
        "binary": HOPPER_NIGHTHAWKS_ASSET,
        "title": "Nighthawks",
        "artistFirst": "Edward",
        "artistLast": "Hopper",
        "width": 64,
        "height": 32,
    },
    {
        "binary": DELACROIX_LIBERTY_LEADING_THE_PEOPLE_ASSET,
        "title": "Liberty Leading the People",
        "artistFirst": "Eugène",
        "artistLast": "Delacroix",
        "width": 64,
        "height": 51,
        "framing": 0,
    },
    {
        "binary": VAN_EYCK_ARNOLFINI_PORTRAIT_ASSET,
        "title": "Arnolfini Portrait",
        "artistFirst": "Jan",
        "artistLast": "van Eyck",
        "width": 64,
        "height": 88,
        "framing": 12,
    },
    {
        "binary": VAN_GOGH_CAF_TERRACE_AT_NIGHT_ASSET,
        "title": "Café Terrace at Night",
        "artistFirst": "Vincent",
        "artistLast": "van Gogh",
        "width": 64,
        "height": 80,
        "framing": 35,
    },
    {
        "binary": BASQUIAT_UNTITLED_1982__ASSET,
        "title": "Untitled (1982)",
        "artistFirst": "Jean-Michel",
        "artistLast": "Basquiat",
        "width": 64,
        "height": 68,
        "framing": 18,
    },
    {
        "binary": WHISTLER_WHISTLER_S_MOTHER_ASSET,
        "title": "Whistler's Mother",
        "artistFirst": "James",
        "artistLast": "Whistler",
        "width": 64,
        "height": 57,
        "framing": 6,
    },
    {
        "binary": MAGRITTE_THE_SON_OF_MAN_ASSET,
        "title": "The Son of Man",
        "artistFirst": "René",
        "artistLast": "Magritte",
        "width": 64,
        "height": 90,
        "framing": 9,
    },
    {
        "binary": REMBRANDT_THE_NIGHT_WATCH_ASSET,
        "title": "The Night Watch",
        "artistFirst": "",
        "artistLast": "Rembrandt",
        "width": 64,
        "height": 53,
        "framing": 20,
    },
    {
        "binary": PICASSO_LES_DEMOISELLES_D_AVIGNON_ASSET,
        "title": "Les Demoiselles d'Avignon",
        "artistFirst": "Pablo",
        "artistLast": "Picasso",
        "width": 64,
        "height": 66,
        "framing": 5,
    },
    {
        "binary": VEL_ZQUEZ_LAS_MENINAS_ASSET,
        "title": "Las Meninas",
        "artistFirst": "Diego",
        "artistLast": "Velázquez",
        "width": 64,
        "height": 74,
        "framing": 38,
    },
    {
        "binary": KANDINSKY_TRANSVERSE_LINE_ASSET,
        "title": "Transverse Line",
        "artistFirst": "Wassily",
        "artistLast": "Kandinsky",
        "width": 64,
        "height": 44,
        "framing": 8,
    },
    {
        "binary": FRIEDRICH_WANDERER_ABOVE_THE_SEA_OF_FOG_ASSET,
        "title": "Wanderer above the Sea of Fog",
        "artistFirst": "Caspar",
        "artistLast": "Friedrich",
        "width": 64,
        "height": 82,
        "framing": 25,
    },
    {
        "binary": VAN_GOGH_STARRY_NIGHT_OVER_THE_RH_NE_ASSET,
        "title": "Starry Night Over the Rhône",
        "artistFirst": "Vincent",
        "artistLast": "van Gogh",
        "width": 64,
        "height": 50,
        "framing": 4,
    },
    {
        "binary": MONET_SAN_GIORGIO_MAGGIORE_AT_DUSK_ASSET,
        "title": "San Giorgio Maggiore at Dusk",
        "artistFirst": "Claude",
        "artistLast": "Monet",
        "width": 64,
        "height": 45,
        "framing": 0,
    },
    {
        "binary": VERMEER_THE_MILKMAID_ASSET,
        "title": "The Milkmaid",
        "artistFirst": "Johannes",
        "artistLast": "Vermeer",
        "width": 64,
        "height": 72,
        "framing": 13,
    },
    {
        "binary": HOKUSAI_THE_GREAT_WAVE_OFF_KANAGAWA_ASSET,
        "title": "The Great Wave off Kanagawa",
        "artistFirst": "Katsushika",
        "artistLast": "Hokusai",
        "width": 64,
        "height": 43,
        "framing": 5,
    },
    {
        "binary": BOTTICELLI_THE_BIRTH_OF_VENUS_ASSET,
        "title": "The Birth of Venus",
        "artistFirst": "Sandro",
        "artistLast": "Botticelli",
        "width": 64,
        "height": 40,
        "framing": 2,
    },
    {
        "binary": DA_VINCI_THE_LAST_SUPPER_ASSET,
        "title": "The Last Supper",
        "artistFirst": "Leonardo",
        "artistLast": "da Vinci",
        "width": 64,
        "height": 32,
    },
    {
        "binary": RIVERA_THE_FLOWER_CARRIER_ASSET,
        "title": "The Flower Carrier",
        "artistFirst": "Diego",
        "artistLast": "Rivera",
        "width": 64,
        "height": 64,
        "framing": 9,
    },
    {
        "binary": PICASSO_GUERNICA_ASSET,
        "title": "Guernica",
        "artistFirst": "Pablo",
        "artistLast": "Picasso",
        "width": 70,
        "height": 32,
        "framing": 0,
    },
    {
        "binary": VAN_GOGH_WHEAT_FIELD_WITH_CYPRESSES_ASSET,
        "title": "Wheat Field with Cypresses",
        "artistFirst": "Vincent",
        "artistLast": "van Gogh",
        "width": 64,
        "height": 50,
        "framing": 10,
    },
    {
        "binary": POLLOCK_UNTITLED_ASSET,
        "title": "Untitled",
        "artistFirst": "Jackson",
        "artistLast": "Pollock",
        "width": 64,
        "height": 46,
    },
    {
        "binary": KLIMT_THE_KISS_ASSET,
        "title": "The Kiss",
        "artistFirst": "Gustav",
        "artistLast": "Klimt",
        "width": 64,
        "height": 64,
        "framing": 0,
    },
    {
        "binary": MICHELANGELO_THE_CREATION_OF_ADAM_ASSET,
        "title": "The Creation of Adam",
        "artistFirst": "",
        "artistLast": "Michelangelo",
        "width": 64,
        "height": 32,
    },
    {
        "binary": MONET_WOMAN_WITH_A_PARASOL_ASSET,
        "title": "Woman with a Parasol",
        "artistFirst": "Claude",
        "artistLast": "Monet",
        "width": 64,
        "height": 79,
        "framing": 28,
    },
    {
        "binary": PICASSO_PORTRAIT_OF_DORA_MAAR_ASSET,
        "title": "Portrait of Dora Maar",
        "artistFirst": "Pablo",
        "artistLast": "Picasso",
        "width": 64,
        "height": 89,
        "framing": 10,
    },
    {
        "binary": KAHLO_THE_TWO_FRIDAS_ASSET,
        "title": "The Two Fridas",
        "artistFirst": "Frida",
        "artistLast": "Kahlo",
        "width": 64,
        "height": 64,
        "framing": 3,
    },
    {
        "binary": VAN_GOGH_THE_RED_VINEYARD_ASSET,
        "title": "The Red Vineyard",
        "artistFirst": "Vincent",
        "artistLast": "van Gogh",
        "width": 64,
        "height": 50,
        "framing": 0,
    },
    {
        "binary": VERMEER_GIRL_WITH_A_PEARL_EARRING_ASSET,
        "title": "Girl with a Pearl Earring",
        "artistFirst": "Johannes",
        "artistLast": "Vermeer",
        "width": 64,
        "height": 76,
        "framing": 18,
    },
    {
        "binary": MANET_A_BAR_AT_THE_FOLIES_BERG_RE_ASSET,
        "title": "A Bar at the Folies-Bergère",
        "artistFirst": "Édouard",
        "artistLast": "Manet",
        "width": 64,
        "height": 47,
        "framing": 2,
    },
    {
        "binary": MILLET_THE_GLEANERS_ASSET,
        "title": "The Gleaners",
        "artistFirst": "Jean-François",
        "artistLast": "Millet",
        "width": 64,
        "height": 48,
        "framing": 11,
    },
    {
        "binary": BLOCH_IN_A_ROMAN_OSTERIA_ASSET,
        "title": "In a Roman Osteria",
        "artistFirst": "Carl",
        "artistLast": "Bloch",
        "width": 64,
        "height": 51,
        "framing": 9,
    },
    {
        "binary": TURNER_THE_FIGHTING_TEMERAIRE_ASSET,
        "title": "The Fighting Temeraire",
        "artistFirst": "J. M. W.",
        "artistLast": "Turner",
        "width": 64,
        "height": 48,
        "framing": 16,
    },
    {
        "binary": C_ZANNE_MONT_SAINTE_VICTOIRE_ASSET,
        "title": "Mont Sainte-Victoire",
        "artistFirst": "Paul",
        "artistLast": "Cézanne",
        "width": 64,
        "height": 42,
        "framing": 4,
    },
    {
        "binary": MONET_WATER_LILIES_ASSET,
        "title": "Water Lilies",
        "artistFirst": "Claude",
        "artistLast": "Monet",
        "width": 64,
        "height": 32,
    },
    {
        "binary": VAN_GOGH_WHEATFIELD_WITH_CROWS_ASSET,
        "title": "Wheatfield with Crows",
        "artistFirst": "Vincent",
        "artistLast": "van Gogh",
        "width": 64,
        "height": 32,
    },
    {
        "binary": KANDINSKY_THE_BLUE_RIDER_ASSET,
        "title": "The Blue Rider",
        "artistFirst": "Wassily",
        "artistLast": "Kandinsky",
        "width": 64,
        "height": 60,
        "framing": 15,
    },
    {
        "binary": BOSCH_THE_GARDEN_OF_EARTHLY_DELIGHTS_ASSET,
        "title": "The Garden of Earthly Delights",
        "artistFirst": "Hieronymus",
        "artistLast": "Bosch",
        "width": 64,
        "height": 32,
    },
    {
        "binary": RENOIR_LUNCHEON_OF_THE_BOATING_PARTY_ASSET,
        "title": "Luncheon of the Boating Party",
        "artistFirst": "Pierre-Auguste",
        "artistLast": "Renoir",
        "width": 64,
        "height": 47,
        "framing": 3,
    },
    {
        "binary": DEGAS_THE_ABSINTHE_DRINKER_ASSET,
        "title": "The Absinthe Drinker",
        "artistFirst": "Edgar",
        "artistLast": "Degas",
        "width": 64,
        "height": 88,
        "framing": 10,
    },
    {
        "binary": DA_VINCI_MONA_LISA_ASSET,
        "title": "Mona Lisa",
        "artistFirst": "Leonardo",
        "artistLast": "da Vinci",
        "width": 64,
        "height": 95,
        "framing": 10,
    },
    {
        "binary": DELAROCHE_THE_EXECUTION_OF_LADY_JANE_GREY_ASSET,
        "title": "The Execution of Lady Jane Grey",
        "artistFirst": "Paul",
        "artistLast": "Delaroche",
        "width": 64,
        "height": 53,
        "framing": 13,
    },
    {
        "binary": TANNER_THE_BANJO_LESSON_ASSET,
        "title": "The Banjo Lesson",
        "artistFirst": "Henry Ossawa",
        "artistLast": "Tanner",
        "width": 64,
        "height": 91,
        "framing": 15,
    },
    {
        "binary": CONSTABLE_THE_HAY_WAIN_ASSET,
        "title": "The Hay Wain",
        "artistFirst": "John",
        "artistLast": "Constable",
        "width": 64,
        "height": 44,
        "framing": 10,
    },
    {
        "binary": LEUTZE_WASHINGTON_CROSSING_THE_DELAWARE_ASSET,
        "title": "Washington Crossing the Delaware",
        "artistFirst": "Emanuel",
        "artistLast": "Leutze",
        "width": 64,
        "height": 32,
        "framing": 4,
    },
    {
        "binary": MATEJKO_STA_CZYK_ASSET,
        "title": "Stańczyk",
        "artistFirst": "Jan",
        "artistLast": "Matejko",
        "width": 64,
        "height": 47,
        "framing": 8,
    },
    {
        "binary": WYETH_CHRISTINA_S_WORLD_ASSET,
        "title": "Christina's World",
        "artistFirst": "Andrew",
        "artistLast": "Wyeth",
        "width": 64,
        "height": 43,
        "framing": 4,
    },
    {
        "binary": VAN_GOGH_THE_NIGHT_CAF_ASSET,
        "title": "The Night Café",
        "artistFirst": "Vincent",
        "artistLast": "van Gogh",
        "width": 64,
        "height": 51,
        "framing": 5,
    },
    {
        "binary": LAM_THE_JUNGLE_ASSET,
        "title": "The Jungle",
        "artistFirst": "Wilfredo",
        "artistLast": "Lam",
        "width": 64,
        "height": 67,
        "framing": 10,
    },
    {
        "binary": REMBRANDT_THE_ANATOMY_LESSON_OF_DR_NICOLAES_TULP_ASSET,
        "title": "The Anatomy Lesson of Dr. Nicolaes Tulp",
        "artistFirst": "",
        "artistLast": "Rembrandt",
        "width": 64,
        "height": 48,
        "framing": 7,
    },
    {
        "binary": DAVID_THE_DEATH_OF_MARAT_ASSET,
        "title": "The Death of Marat",
        "artistFirst": "Jacques-Louis",
        "artistLast": "David",
        "width": 64,
        "height": 51,
        "framing": 0,
    },
    {
        "binary": GENTILESCHI_JUDITH_SLAYING_HOLOFERNES_ASSET,
        "title": "Judith Slaying Holofernes",
        "artistFirst": "Artemisia",
        "artistLast": "Gentileschi",
        "width": 64,
        "height": 78,
        "framing": 25,
    },
    {
        "binary": LEIGHTON_FLAMING_JUNE_ASSET,
        "title": "Flaming June",
        "artistFirst": "Frederic",
        "artistLast": "Leighton",
        "width": 64,
        "height": 65,
        "framing": 11,
    },
    {
        "binary": THOMAS_THE_ECLIPSE_ASSET,
        "title": "The Eclipse",
        "artistFirst": "Alma",
        "artistLast": "Thomas",
        "width": 64,
        "height": 79,
        "framing": 23,
    },
]
