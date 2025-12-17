"""
Applet: Tarot Cards
Summary: Draw tarot cards
Description: Displays random tarot card spreads with their images, names, and meanings.
Author: frame-shift

==================================================
ATTRIBUTION FOR CARD IMAGES:

'The Arcade Arcanum' by Rose Frye 
https://modernmodron.itch.io/the-arcade-arcanum

Used under CC BY 4.0 / Resized from original
https://creativecommons.org/licenses/by/4.0/
==================================================
"""

load("animation.star", "animation")
load("http.star", "http")
load("images/back_a.gif", BACK_A_ASSET = "file")
load("images/back_b.gif", BACK_B_ASSET = "file")
load("images/back_c.gif", BACK_C_ASSET = "file")
load("images/back_d.gif", BACK_D_ASSET = "file")
load("images/face_0fool.gif", FACE_0FOOL_ASSET = "file")
load("images/face_10wheel.gif", FACE_10WHEEL_ASSET = "file")
load("images/face_11justice.gif", FACE_11JUSTICE_ASSET = "file")
load("images/face_12hangedman.gif", FACE_12HANGEDMAN_ASSET = "file")
load("images/face_13death.gif", FACE_13DEATH_ASSET = "file")
load("images/face_14tempance.gif", FACE_14TEMPANCE_ASSET = "file")
load("images/face_15devil.gif", FACE_15DEVIL_ASSET = "file")
load("images/face_16tower.gif", FACE_16TOWER_ASSET = "file")
load("images/face_17star.gif", FACE_17STAR_ASSET = "file")
load("images/face_18moon.gif", FACE_18MOON_ASSET = "file")
load("images/face_19sun.gif", FACE_19SUN_ASSET = "file")
load("images/face_1magician.gif", FACE_1MAGICIAN_ASSET = "file")
load("images/face_20judgement.gif", FACE_20JUDGEMENT_ASSET = "file")
load("images/face_21world.gif", FACE_21WORLD_ASSET = "file")
load("images/face_2priestess.gif", FACE_2PRIESTESS_ASSET = "file")
load("images/face_3empress.gif", FACE_3EMPRESS_ASSET = "file")
load("images/face_4emperor.gif", FACE_4EMPEROR_ASSET = "file")
load("images/face_5herophant.gif", FACE_5HEROPHANT_ASSET = "file")
load("images/face_6lovers.gif", FACE_6LOVERS_ASSET = "file")
load("images/face_7chariot.gif", FACE_7CHARIOT_ASSET = "file")
load("images/face_8strength.gif", FACE_8STRENGTH_ASSET = "file")
load("images/face_9hermit.gif", FACE_9HERMIT_ASSET = "file")
load("images/face_cup10.gif", FACE_CUP10_ASSET = "file")
load("images/face_cup2.gif", FACE_CUP2_ASSET = "file")
load("images/face_cup3.gif", FACE_CUP3_ASSET = "file")
load("images/face_cup4.gif", FACE_CUP4_ASSET = "file")
load("images/face_cup5.gif", FACE_CUP5_ASSET = "file")
load("images/face_cup6.gif", FACE_CUP6_ASSET = "file")
load("images/face_cup7.gif", FACE_CUP7_ASSET = "file")
load("images/face_cup8.gif", FACE_CUP8_ASSET = "file")
load("images/face_cup9.gif", FACE_CUP9_ASSET = "file")
load("images/face_cupace.gif", FACE_CUPACE_ASSET = "file")
load("images/face_cupking.gif", FACE_CUPKING_ASSET = "file")
load("images/face_cupknight.gif", FACE_CUPKNIGHT_ASSET = "file")
load("images/face_cuppage.gif", FACE_CUPPAGE_ASSET = "file")
load("images/face_cupqueen.gif", FACE_CUPQUEEN_ASSET = "file")
load("images/face_pen10.gif", FACE_PEN10_ASSET = "file")
load("images/face_pen2.gif", FACE_PEN2_ASSET = "file")
load("images/face_pen3.gif", FACE_PEN3_ASSET = "file")
load("images/face_pen4.gif", FACE_PEN4_ASSET = "file")
load("images/face_pen5.gif", FACE_PEN5_ASSET = "file")
load("images/face_pen6.gif", FACE_PEN6_ASSET = "file")
load("images/face_pen7.gif", FACE_PEN7_ASSET = "file")
load("images/face_pen8.gif", FACE_PEN8_ASSET = "file")
load("images/face_pen9.gif", FACE_PEN9_ASSET = "file")
load("images/face_penace.gif", FACE_PENACE_ASSET = "file")
load("images/face_penking.gif", FACE_PENKING_ASSET = "file")
load("images/face_penknight.gif", FACE_PENKNIGHT_ASSET = "file")
load("images/face_penpage.gif", FACE_PENPAGE_ASSET = "file")
load("images/face_penqueen.gif", FACE_PENQUEEN_ASSET = "file")
load("images/face_sword10.gif", FACE_SWORD10_ASSET = "file")
load("images/face_sword2.gif", FACE_SWORD2_ASSET = "file")
load("images/face_sword3.gif", FACE_SWORD3_ASSET = "file")
load("images/face_sword4.gif", FACE_SWORD4_ASSET = "file")
load("images/face_sword5.gif", FACE_SWORD5_ASSET = "file")
load("images/face_sword6.gif", FACE_SWORD6_ASSET = "file")
load("images/face_sword7.gif", FACE_SWORD7_ASSET = "file")
load("images/face_sword8.gif", FACE_SWORD8_ASSET = "file")
load("images/face_sword9.gif", FACE_SWORD9_ASSET = "file")
load("images/face_swordace.gif", FACE_SWORDACE_ASSET = "file")
load("images/face_swordking.gif", FACE_SWORDKING_ASSET = "file")
load("images/face_swordknight.gif", FACE_SWORDKNIGHT_ASSET = "file")
load("images/face_swordpage.gif", FACE_SWORDPAGE_ASSET = "file")
load("images/face_swordqueen.gif", FACE_SWORDQUEEN_ASSET = "file")
load("images/face_wand10.gif", FACE_WAND10_ASSET = "file")
load("images/face_wand2.gif", FACE_WAND2_ASSET = "file")
load("images/face_wand3.gif", FACE_WAND3_ASSET = "file")
load("images/face_wand4.gif", FACE_WAND4_ASSET = "file")
load("images/face_wand5.gif", FACE_WAND5_ASSET = "file")
load("images/face_wand6.gif", FACE_WAND6_ASSET = "file")
load("images/face_wand7.gif", FACE_WAND7_ASSET = "file")
load("images/face_wand8.gif", FACE_WAND8_ASSET = "file")
load("images/face_wand9.gif", FACE_WAND9_ASSET = "file")
load("images/face_wandace.gif", FACE_WANDACE_ASSET = "file")
load("images/face_wandking.gif", FACE_WANDKING_ASSET = "file")
load("images/face_wandknight.gif", FACE_WANDKNIGHT_ASSET = "file")
load("images/face_wandpage.gif", FACE_WANDPAGE_ASSET = "file")
load("images/face_wandqueen.gif", FACE_WANDQUEEN_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

# Set default user values
DEFAULT_BACK = "C"
DEFAULT_MAX = "77"
DEFAULT_COLOR = "#cd90f9"
DEFAULT_DRAW = "single"
DEFAULT_FREQ = "throughout"

# Set URL for once-daily draws
URL_DRAWN = "https://raw.githubusercontent.com/frame-shift/tarot/main/draws.json"
CACHE_TTL = 3600  # 1 hour

# Set card backs and fronts (19x32 images, see attribution above), names, and keywords
CARD_BACKS = {
    "A": BACK_A_ASSET.readall(),
    "B": BACK_B_ASSET.readall(),
    "C": BACK_C_ASSET.readall(),
    "D": BACK_D_ASSET.readall(),
}
CARD_FACES = {
    "0Fool": FACE_0FOOL_ASSET.readall(),
    "10wheel": FACE_10WHEEL_ASSET.readall(),
    "11Justice": FACE_11JUSTICE_ASSET.readall(),
    "12Hangedman": FACE_12HANGEDMAN_ASSET.readall(),
    "13Death": FACE_13DEATH_ASSET.readall(),
    "14Tempance": FACE_14TEMPANCE_ASSET.readall(),
    "15Devil": FACE_15DEVIL_ASSET.readall(),
    "16Tower": FACE_16TOWER_ASSET.readall(),
    "17Star": FACE_17STAR_ASSET.readall(),
    "18Moon": FACE_18MOON_ASSET.readall(),
    "19Sun": FACE_19SUN_ASSET.readall(),
    "1Magician": FACE_1MAGICIAN_ASSET.readall(),
    "20Judgement": FACE_20JUDGEMENT_ASSET.readall(),
    "21World": FACE_21WORLD_ASSET.readall(),
    "2Priestess": FACE_2PRIESTESS_ASSET.readall(),
    "3Empress": FACE_3EMPRESS_ASSET.readall(),
    "4Emperor": FACE_4EMPEROR_ASSET.readall(),
    "5Herophant": FACE_5HEROPHANT_ASSET.readall(),
    "6Lovers": FACE_6LOVERS_ASSET.readall(),
    "7Chariot": FACE_7CHARIOT_ASSET.readall(),
    "8Strength": FACE_8STRENGTH_ASSET.readall(),
    "9Hermit": FACE_9HERMIT_ASSET.readall(),
    "cup10": FACE_CUP10_ASSET.readall(),
    "cup2": FACE_CUP2_ASSET.readall(),
    "cup3": FACE_CUP3_ASSET.readall(),
    "cup4": FACE_CUP4_ASSET.readall(),
    "cup5": FACE_CUP5_ASSET.readall(),
    "cup6": FACE_CUP6_ASSET.readall(),
    "cup7": FACE_CUP7_ASSET.readall(),
    "cup8": FACE_CUP8_ASSET.readall(),
    "cup9": FACE_CUP9_ASSET.readall(),
    "cupAce": FACE_CUPACE_ASSET.readall(),
    "cupKing": FACE_CUPKING_ASSET.readall(),
    "cupKnight": FACE_CUPKNIGHT_ASSET.readall(),
    "cupPage": FACE_CUPPAGE_ASSET.readall(),
    "cupQueen": FACE_CUPQUEEN_ASSET.readall(),
    "pen10": FACE_PEN10_ASSET.readall(),
    "pen2": FACE_PEN2_ASSET.readall(),
    "pen3": FACE_PEN3_ASSET.readall(),
    "pen4": FACE_PEN4_ASSET.readall(),
    "pen5": FACE_PEN5_ASSET.readall(),
    "pen6": FACE_PEN6_ASSET.readall(),
    "pen7": FACE_PEN7_ASSET.readall(),
    "pen8": FACE_PEN8_ASSET.readall(),
    "pen9": FACE_PEN9_ASSET.readall(),
    "penAce": FACE_PENACE_ASSET.readall(),
    "penKing": FACE_PENKING_ASSET.readall(),
    "penKnight": FACE_PENKNIGHT_ASSET.readall(),
    "penPage": FACE_PENPAGE_ASSET.readall(),
    "penQueen": FACE_PENQUEEN_ASSET.readall(),
    "sword10": FACE_SWORD10_ASSET.readall(),
    "sword2": FACE_SWORD2_ASSET.readall(),
    "sword3": FACE_SWORD3_ASSET.readall(),
    "sword4": FACE_SWORD4_ASSET.readall(),
    "sword5": FACE_SWORD5_ASSET.readall(),
    "sword6": FACE_SWORD6_ASSET.readall(),
    "sword7": FACE_SWORD7_ASSET.readall(),
    "sword8": FACE_SWORD8_ASSET.readall(),
    "sword9": FACE_SWORD9_ASSET.readall(),
    "swordAce": FACE_SWORDACE_ASSET.readall(),
    "swordKing": FACE_SWORDKING_ASSET.readall(),
    "swordKnight": FACE_SWORDKNIGHT_ASSET.readall(),
    "swordPage": FACE_SWORDPAGE_ASSET.readall(),
    "swordQueen": FACE_SWORDQUEEN_ASSET.readall(),
    "wand10": FACE_WAND10_ASSET.readall(),
    "wand2": FACE_WAND2_ASSET.readall(),
    "wand3": FACE_WAND3_ASSET.readall(),
    "wand4": FACE_WAND4_ASSET.readall(),
    "wand5": FACE_WAND5_ASSET.readall(),
    "wand6": FACE_WAND6_ASSET.readall(),
    "wand7": FACE_WAND7_ASSET.readall(),
    "wand8": FACE_WAND8_ASSET.readall(),
    "wand9": FACE_WAND9_ASSET.readall(),
    "wandAce": FACE_WANDACE_ASSET.readall(),
    "wandKing": FACE_WANDKING_ASSET.readall(),
    "wandKnight": FACE_WANDKNIGHT_ASSET.readall(),
    "wandPage": FACE_WANDPAGE_ASSET.readall(),
    "wandQueen": FACE_WANDQUEEN_ASSET.readall(),
}
CARD_NAMES = {
    # Index 0-21 = Major Arcana; 0-77 = all cards
    "0Fool": "The Fool",
    "10wheel": "Wheel of Fortune",
    "11Justice": "Justice",
    "12Hangedman": "The\nHanged Man",
    "13Death": "Death",
    "14Tempance": "Temperance",
    "15Devil": "The Devil",
    "16Tower": "The Tower",
    "17Star": "The Star",
    "18Moon": "The Moon",
    "19Sun": "The Sun",
    "1Magician": "The Magician",
    "20Judgement": "Judgement",
    "21World": "The World",
    "2Priestess": "The High Priestess",
    "3Empress": "The Empress",
    "4Emperor": "The Emperor",
    "5Herophant": "The Hierophant",
    "6Lovers": "The Lovers",
    "7Chariot": "The Chariot",
    "8Strength": "Strength",
    "9Hermit": "The Hermit",
    "cup10": "Ten\nof Cups",
    "cup2": "Two\nof Cups",
    "cup3": "Three\nof Cups",
    "cup4": "Four\nof Cups",
    "cup5": "Five\nof Cups",
    "cup6": "Six\nof Cups",
    "cup7": "Seven\nof Cups",
    "cup8": "Eight\nof Cups",
    "cup9": "Nine\nof Cups",
    "cupAce": "Ace\nof Cups",
    "cupKing": "King\nof Cups",
    "cupKnight": "Knight\nof Cups",
    "cupPage": "Page\nof Cups",
    "cupQueen": "Queen\nof Cups",
    "pen10": "Ten\nof Coins",
    "pen2": "Two\nof Coins",
    "pen3": "Three\nof Coins",
    "pen4": "Four\nof Coins",
    "pen5": "Five\nof Coins",
    "pen6": "Six\nof Coins",
    "pen7": "Seven\nof Coins",
    "pen8": "Eight\nof Coins",
    "pen9": "Nine\nof Coins",
    "penAce": "Ace\nof Coins",
    "penKing": "King\nof Coins",
    "penKnight": "Knight\nof Coins",
    "penPage": "Page\nof Coins",
    "penQueen": "Queen\nof Coins",
    "sword10": "Ten\nof Swords",
    "sword2": "Two\nof Swords",
    "sword3": "Three\nof Swords",
    "sword4": "Four\nof Swords",
    "sword5": "Five\nof Swords",
    "sword6": "Six\nof Swords",
    "sword7": "Seven\nof Swords",
    "sword8": "Eight\nof Swords",
    "sword9": "Nine\nof Swords",
    "swordAce": "Ace\nof Swords",
    "swordKing": "King\nof Swords",
    "swordKnight": "Knight\nof Swords",
    "swordPage": "Page\nof Swords",
    "swordQueen": "Queen\nof Swords",
    "wand10": "Ten\nof Wands",
    "wand2": "Two\nof Wands",
    "wand3": "Three\nof Wands",
    "wand4": "Four\nof Wands",
    "wand5": "Five\nof Wands",
    "wand6": "Six\nof Wands",
    "wand7": "Seven\nof Wands",
    "wand8": "Eight\nof Wands",
    "wand9": "Nine\nof Wands",
    "wandAce": "Ace\nof Wands",
    "wandKing": "King\nof Wands",
    "wandKnight": "Knight\nof Wands",
    "wandPage": "Page\nof Wands",
    "wandQueen": "Queen\nof Wands",
}
CARD_WORDS = {
    # Max character length per word = 11
    "0Fool": ["beginnings", "innocence", "spontaneity"],
    "10wheel": ["destiny", "change", "cycles"],
    "11Justice": ["truth", "law", "fairness"],
    "12Hangedman": ["surrender", "acceptance", "sacrifice"],
    "13Death": ["rebirth", "endings", "change"],
    "14Tempance": ["balance", "moderation", "realignment"],
    "15Devil": ["pleasure", "addiction", "materialism"],
    "16Tower": ["revelation", "upheaval", "disaster"],
    "17Star": ["hope", "healing", "inspiration"],
    "18Moon": ["illusion", "distortion", "intuition"],
    "19Sun": ["joy", "optimism", "wellness"],
    "1Magician": ["talent", "potential", "willpower"],
    "20Judgement": ["absolution", "calling", "awakening"],
    "21World": ["unity", "harmony", "completion"],
    "2Priestess": ["inner voice", "mystery", "intuition"],
    "3Empress": ["femininity", "nurturing", "creativity"],
    "4Emperor": ["masculinity", "authority", "duty"],
    "5Herophant": ["tradition", "society", "legacy"],
    "6Lovers": ["intimacy", "choices", "union"],
    "7Chariot": ["action", "control", "discipline"],
    "8Strength": ["compassion", "composure", "endurance"],
    "9Hermit": ["solitude", "insight", "awareness"],
    "cup10": ["soulmates", "harmony", "alignment"],
    "cup2": ["partnership", "attraction", "harmony"],
    "cup3": ["friendship", "solidarity", "socializing"],
    "cup4": ["evaluation", "jealousy", "boredom"],
    "cup5": ["remorse", "failure", "depression"],
    "cup6": ["memory", "nostalgia", "childhood"],
    "cup7": ["choices", "confusion", "fantasizing"],
    "cup8": ["escapism", "withdrawal", "letting go"],
    "cup9": ["fulfillment", "gratitude", "acclaim"],
    "cupAce": ["love", "creativity", "joy"],
    "cupKing": ["diplomacy", "tolerance", "devotion"],
    "cupKnight": ["charm", "romance", "beauty"],
    "cupPage": ["admiration", "sensitivity", "epiphany"],
    "cupQueen": ["empathy", "compassion", "nurturing"],
    "pen10": ["family", "windfall", "legacy"],
    "pen2": ["balance", "adaptation", "decisions"],
    "pen3": ["cooperation", "learning", "talent"],
    "pen4": ["investment", "security", "frugality"],
    "pen5": ["poverty", "loss", "isolation"],
    "pen6": ["giving", "altruism", "sharing"],
    "pen7": ["results", "persistence", "vision"],
    "pen8": ["hard work", "practice", "diligence"],
    "pen9": ["property", "luxury", "gratitude"],
    "penAce": ["opportunity", "career", "prosperity"],
    "penKing": ["bounty", "leadership", "provider"],
    "penKnight": ["reliability", "patience", "routine"],
    "penPage": ["potential", "thrift", "ambition"],
    "penQueen": ["steadiness", "generosity", "nurturing"],
    "sword10": ["fatalism", "crisis", "melodrama"],
    "sword2": ["denial", "stalemate", "choices"],
    "sword3": ["heartbreak", "trauma", "grief"],
    "sword4": ["self-care", "rest", "meditation"],
    "sword5": ["abuse", "sneakiness", "pride"],
    "sword6": ["moving on", "regret", "progress"],
    "sword7": ["secrets", "cunning", "stealth"],
    "sword8": ["restriction", "isolation", "victim"],
    "sword9": ["anxiety", "despair", "nightmares"],
    "swordAce": ["truth", "assertion", "new ideas"],
    "swordKing": ["logic", "wisdom", "objectivity"],
    "swordKnight": ["initiative", "courage", "activism"],
    "swordPage": ["curiosity", "eagerness", "vigilance"],
    "swordQueen": ["principles", "complexity", "lucid"],
    "wand10": ["obligation", "overload", "burden"],
    "wand2": ["waiting", "options", "discovery"],
    "wand3": ["enthusiasm", "progress", "fruition"],
    "wand4": ["home", "celebration", "commitment"],
    "wand5": ["competition", "chaos", "conflict"],
    "wand6": ["recognition", "victory", "pride"],
    "wand7": ["challenge", "defiance", "courage"],
    "wand8": ["travel", "haste", "impulse"],
    "wand9": ["resilience", "resolve", "fatigue"],
    "wandAce": ["inspiration", "ideation", "creativity"],
    "wandKing": ["leadership", "charm", "innovation"],
    "wandKnight": ["passion", "adventure", "action"],
    "wandPage": ["free spirit", "discovery", "play"],
    "wandQueen": ["boldness", "ambition", "passion"],
}

def main(config):
    # Main function
    # Define user choices
    card_back = CARD_BACKS[config.str("choice_back", DEFAULT_BACK)]  # Decodes chosen card back for image src
    card_color = config.str("choice_color", DEFAULT_COLOR)  # Returns desired color hex code
    card_max = int(config.str("choice_max", DEFAULT_MAX))  # Returns Major Arcana cards or all cards
    card_draw = config.str("choice_draw", DEFAULT_DRAW)  # Returns single card or three-card spread
    card_freq = config.str("choice_freq", DEFAULT_FREQ)  # Returns how often to draw new cards
    card_draw = "spread"  # For testing
    card_freq = "once"  # For testing
    card_max = 21  #  For testing

    # Calculates which function to run depending on single card or three-card spread
    if card_draw == "single":
        return draw_single(card_back, card_color, card_max, card_freq)
    elif card_draw == "spread":
        return draw_spread(card_back, card_color, card_max, card_freq)
    else:
        return render.Root(
            child = render.Box(
                color = "#000",
            ),
        )

def draw_single(back, color, maxdraw, freq):
    # Single card draw funciton
    # Define variables from user choices
    card_back = back
    card_color = color
    card_max = maxdraw
    card_freq = freq

    # Determine whether to pull random cards throughout the day or only once per day
    # For throughout the day:
    if card_freq == DEFAULT_FREQ:
        card_num = random.number(0, card_max)  # Generate a random number for the card draw
        # print("SINGLE - THROUGHOUT\n")  # For testing

        # For only once per day:
    else:
        res = http.get(URL_DRAWN, ttl_seconds = CACHE_TTL)

        if res.status_code != 200:
            print("Request to %s failed with status code: %d - %s" % (URL_DRAWN, res.status_code, res.body()))
            return render_error("Could not reach range_x.json\n:(")

        draw_from = res.json()
        print(draw_from)  # For testing

        if card_max == 77:  # All cards
            card_num = int(draw_from["all"]["single"])
        else:  # Major Arcana only
            card_num = int(draw_from["major"]["single"])
        print(card_num)  # For testing

    # Define card properties
    card_name = list(CARD_NAMES.values())[card_num]  # Gets card name (string)
    card_keywords = list(CARD_WORDS.values())[card_num]  # Gets card keywords (list)
    card_face = list(CARD_FACES.values())[card_num]  # Gets card face (for src)
    # print("MAX: " + str(card_max) + "\nNUM: " + str(card_num) + "\nNAM: " + card_name + "\nWDS: " + str(card_keywords))  # For testing

    # Create animation delay for single card render
    ani_delay = delay_list(card_face)

    # Send everything to renderer
    return render_single(card_name, card_keywords, card_face, card_back, card_color, ani_delay)

def delay_list(face):
    # Set up a list for animation frames during single card render
    # Set variables
    card_face = face
    output = []

    for x in range(240):
        if x < 111:
            output.append(render.Box(width = 19, height = 32, color = "#00000000"))
            continue
        elif x < 239:
            output.append(render.Image(src = card_face))
            continue
        elif x == 239:
            output.append(render.Image(src = card_face))
            return output

    return None

def render_single(name, words, face, back, color, delay):
    # Render and display animation for single card option
    # Define variables passed from functions
    card_name = name
    card_keywords = words
    card_face = face
    card_back = back
    card_color = color
    ani_delay = delay

    # Display the animation
    return render.Root(
        show_full_animation = True,
        child = render.Stack(
            children = [
                render.Sequence(
                    # The card flip and slide sequence
                    children = [
                        # Show card back
                        animation.Transformation(
                            child =
                                render.Column(
                                    cross_align = "center",
                                    main_align = "space_between",
                                    children = [
                                        render.Row(
                                            expanded = True,
                                            main_align = "center",
                                            children = [
                                                render.Image(src = card_back),
                                            ],
                                        ),
                                    ],
                                ),
                            duration = 16,
                            delay = 0,
                            keyframes = [
                                animation.Keyframe(
                                    percentage = 0.0,
                                    transforms = [animation.Scale(1.0, 1.0)],
                                ),
                                animation.Keyframe(
                                    percentage = 1.0,
                                    transforms = [animation.Scale(1.0, 1.0)],
                                ),
                            ],
                        ),

                        # Flip card back
                        animation.Transformation(
                            child =
                                render.Column(
                                    cross_align = "center",
                                    main_align = "space_between",
                                    children = [
                                        render.Row(
                                            expanded = True,
                                            main_align = "center",
                                            children = [
                                                render.Image(src = card_back),
                                            ],
                                        ),
                                    ],
                                ),
                            duration = 16,
                            delay = 0,
                            keyframes = [
                                animation.Keyframe(
                                    percentage = 0.0,
                                    transforms = [animation.Scale(1.0, 1.0)],
                                    curve = "ease_in",
                                ),
                                animation.Keyframe(
                                    percentage = 1.0,
                                    transforms = [animation.Scale(0.0, 1.0)],
                                ),
                            ],
                        ),

                        # Flip card front
                        animation.Transformation(
                            child =
                                render.Column(
                                    cross_align = "center",
                                    main_align = "space_between",
                                    children = [
                                        render.Row(
                                            expanded = True,
                                            main_align = "center",
                                            children = [
                                                render.Image(src = card_face),
                                            ],
                                        ),
                                    ],
                                ),
                            duration = 16,
                            delay = 0,
                            keyframes = [
                                animation.Keyframe(
                                    percentage = 0.0,
                                    transforms = [animation.Scale(0.0, 1.0)],
                                    curve = "ease_out",
                                ),
                                animation.Keyframe(
                                    percentage = 1.0,
                                    transforms = [animation.Scale(1.0, 1.0)],
                                ),
                            ],
                        ),

                        # Show card face
                        animation.Transformation(
                            child =
                                render.Column(
                                    cross_align = "center",
                                    main_align = "space_between",
                                    children = [
                                        render.Row(
                                            expanded = True,
                                            main_align = "center",
                                            children = [
                                                render.Image(src = card_face),
                                            ],
                                        ),
                                    ],
                                ),
                            duration = 32,
                            delay = 0,
                            keyframes = [
                                animation.Keyframe(
                                    percentage = 0.0,
                                    transforms = [animation.Translate(0, 0)],
                                ),
                                animation.Keyframe(
                                    percentage = 1.0,
                                    transforms = [animation.Translate(0, 0)],
                                ),
                            ],
                        ),

                        # Slide card left
                        animation.Transformation(
                            child =
                                render.Column(
                                    cross_align = "center",
                                    main_align = "space_between",
                                    children = [
                                        render.Row(
                                            expanded = True,
                                            main_align = "center",
                                            children = [
                                                render.Image(src = card_face),
                                            ],
                                        ),
                                    ],
                                ),
                            duration = 32,
                            delay = 0,
                            keyframes = [
                                animation.Keyframe(
                                    percentage = 0.0,
                                    transforms = [animation.Translate(0, 0)],
                                    curve = "ease_in_out",
                                ),
                                animation.Keyframe(
                                    percentage = 1.0,
                                    transforms = [animation.Translate(-22, 0)],
                                ),
                            ],
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    children = [
                        render.Padding(
                            child = render.Animation(children = ani_delay),  # Prevents card face from showing until flip/slide completed
                            pad = (0, 0, 1, 0),
                        ),
                        render.Column(
                            children = [
                                render.Stack(
                                    # Children listed from back to front
                                    children = [
                                        render.Column(
                                            children = [
                                                animation.Transformation(
                                                    child =
                                                        render.Column(
                                                            main_align = "start",
                                                            children = [
                                                                # Card name
                                                                render.Box(
                                                                    width = 45,
                                                                    height = 13,
                                                                    color = card_color + "25",
                                                                    child =
                                                                        render.WrappedText(
                                                                            content = card_name,
                                                                            align = "center",
                                                                            color = card_color,
                                                                            font = "CG-pixel-3x5-mono",
                                                                            linespacing = 0,
                                                                        ),
                                                                ),

                                                                # Card keywords
                                                                render.Padding(
                                                                    child =
                                                                        render.WrappedText(
                                                                            content = "\n".join(card_keywords),
                                                                            align = "center",
                                                                            color = "#fff",
                                                                            font = "tom-thumb",
                                                                            width = 45,
                                                                        ),
                                                                    pad = (0, 1, 0, 0),
                                                                ),
                                                            ],
                                                        ),
                                                    duration = 112,
                                                    delay = 0,
                                                    keyframes = [
                                                        animation.Keyframe(
                                                            percentage = 0.0,
                                                            transforms = [animation.Scale(0.0, 0.0)],
                                                        ),
                                                        animation.Keyframe(
                                                            percentage = 0.9999,
                                                            transforms = [animation.Scale(0.0, 0.0)],
                                                        ),
                                                        animation.Keyframe(
                                                            percentage = 1.0,
                                                            transforms = [animation.Scale(1.0, 1.0)],
                                                        ),
                                                    ],
                                                ),
                                            ],
                                        ),

                                        # Box that covers text
                                        animation.Transformation(
                                            child = render.Box(width = 45, height = 32, color = "#000"),
                                            duration = 240,
                                            delay = 0,
                                            keyframes = [
                                                animation.Keyframe(
                                                    percentage = 0.0,
                                                    transforms = [animation.Scale(0.0, 0.0)],
                                                ),
                                                animation.Keyframe(
                                                    percentage = 0.458333,
                                                    transforms = [animation.Scale(0.0, 0.0)],
                                                ),
                                                animation.Keyframe(
                                                    percentage = 0.4625,  # Box pops in right before text revealed
                                                    transforms = [animation.Scale(1.0, 1.0)],
                                                ),
                                                animation.Keyframe(
                                                    percentage = 0.466667,  # Box starts slide to reveal name
                                                    transforms = [animation.Translate(0, 0)],
                                                    curve = "ease_out",
                                                ),
                                                animation.Keyframe(
                                                    percentage = 0.533333,  # Box ends slide to reveal name
                                                    transforms = [animation.Translate(0, 13)],
                                                ),
                                                animation.Keyframe(
                                                    percentage = 0.625,  # Box holds for 2 seconds
                                                    transforms = [animation.Translate(0, 13)],
                                                    curve = "ease_out",
                                                ),
                                                animation.Keyframe(
                                                    percentage = 0.691667,  # Box slides to reveal keywords
                                                    transforms = [animation.Translate(0, 32)],
                                                ),
                                                animation.Keyframe(
                                                    percentage = 1.0,  # Box remains off screen until end
                                                    transforms = [animation.Translate(0, 32)],
                                                ),
                                            ],
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def draw_spread(back, color, maxdraw, freq):
    # Three-card spread function
    # Define variables from user choices
    card_back = back
    card_color = color
    card_max = maxdraw
    card_freq = freq

    # Determine whether to pull random cards throughout the day or only once per day
    # For throughout the day:
    if card_freq == DEFAULT_FREQ:
        # Pull three cards
        draw_pile = list(range(0, card_max + 1))  # Creates a list of all possible card indicies
        card_1 = draw_pile[random.number(0, len(draw_pile)) - 1]  # Draws first card
        draw_pile.remove(card_1)  # Removes first card from draw pile
        card_2 = draw_pile[random.number(0, len(draw_pile)) - 1]  # Draws second card
        draw_pile.remove(card_2)  # Removes second card from draw pile
        card_3 = draw_pile[random.number(0, len(draw_pile)) - 1]  # Draws third card
        # print("SPREAD - THROUGHOUT\n")  # For testing

        # For only once per day:
    else:
        res = http.get(URL_DRAWN, ttl_seconds = CACHE_TTL)

        if res.status_code != 200:
            print("Request to %s failed with status code: %d - %s" % (URL_DRAWN, res.status_code, res.body()))
            return render_error("Could not reach range_x.json\n:(")

        draw_from = res.json()
        print(draw_from)  # For testing

        if card_max == 77:  # All cards
            card_1 = int(draw_from["all"]["spread"]["card1"])
            card_2 = int(draw_from["all"]["spread"]["card2"])
            card_3 = int(draw_from["all"]["spread"]["card3"])
        else:  # Major Arcana only
            card_1 = int(draw_from["major"]["spread"]["card1"])
            card_2 = int(draw_from["major"]["spread"]["card2"])
            card_3 = int(draw_from["major"]["spread"]["card3"])
        print(card_1, card_2, card_3)  # For testing

    #Define each card
    card_name1 = list(CARD_NAMES.values())[card_1]  # Gets card name (str)
    card_name2 = list(CARD_NAMES.values())[card_2]
    card_name3 = list(CARD_NAMES.values())[card_3]
    card_face1 = list(CARD_FACES.values())[card_1]  # Gets card face (for src)
    card_face2 = list(CARD_FACES.values())[card_2]
    card_face3 = list(CARD_FACES.values())[card_3]
    # print("MAX: " + str(card_max) + "\nC1: " + str(card_1) + ", " + card_name1 + "\nC2: " + str(card_2) + ", " + card_name2 + "\nC3: " + str(card_3) + ", " + card_name3)  # For testing

    # Send everything to renderer
    return render_spread(card_name1, card_name2, card_name3, card_face1, card_face2, card_face3, card_back, card_color)

def render_spread(name1, name2, name3, face1, face2, face3, back, color):
    # Render and display animation for three-card spread option
    # Define passed card properties
    card_name1 = name1
    card_name2 = name2
    card_name3 = name3
    card_face1 = face1
    card_face2 = face2
    card_face3 = face3
    card_back = back
    card_color = color
    card_font = "CG-pixel-3x5-mono"
    num_font = "tb-8"

    # Display the animation
    return render.Root(
        show_full_animation = True,
        child = render.Stack(
            # Children are sorted from bottom to top with 7 different children in total
            children = [
                # 1/7: Single card back
                animation.Transformation(
                    child = render.Box(
                        child = render.Image(src = card_back),
                    ),
                    duration = 240,  # Durations must be 240, the entire 15s length of the animation (at 16 fps)
                    delay = 0,  # Delays must be 0, because delays occur at start AND end of animations (why?); thus render.Sequence can't be used
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                        animation.Keyframe(
                            # Show for 1s
                            percentage = 0.0667,
                            transforms = [animation.Translate(0, 0)],
                            curve = "ease_out",
                        ),
                        animation.Keyframe(
                            # Move card up for 1s
                            percentage = 0.1333,
                            transforms = [animation.Translate(0, -32)],
                        ),
                        animation.Keyframe(
                            # Keep card out
                            percentage = 1.0,
                            transforms = [animation.Translate(0, -32)],
                        ),
                    ],
                ),

                # 2/7: Card 1 face
                animation.Transformation(
                    child = render.Box(
                        child = render.Image(src = card_face1),
                    ),
                    duration = 240,
                    delay = 0,
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, -32), animation.Scale(0.0, 1.0)],
                        ),
                        animation.Keyframe(
                            # Keep card hidden for 1.5s
                            percentage = 0.1000,
                            transforms = [animation.Translate(0, -32), animation.Scale(0.0, 1.0)],
                            curve = "ease_out",
                        ),
                        animation.Keyframe(
                            # Deal and flip card for 1.5s
                            percentage = 0.2000,
                            transforms = [animation.Translate(-23, 0), animation.Scale(1.0, 1.0)],
                        ),
                        animation.Keyframe(
                            # Keep card in place for rest of animation
                            percentage = 1.0,
                            transforms = [animation.Translate(-23, 0), animation.Scale(1.0, 1.0)],
                        ),
                    ],
                ),

                # 3/7: Card 2 face
                animation.Transformation(
                    child = render.Box(
                        child = render.Image(src = card_face2),
                    ),
                    duration = 240,
                    delay = 0,
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, -32), animation.Scale(0.0, 1.0)],
                        ),
                        animation.Keyframe(
                            # Keep card hidden for 3s
                            percentage = 0.2000,
                            transforms = [animation.Translate(0, -32), animation.Scale(0.0, 1.0)],
                            curve = "ease_out",
                        ),
                        animation.Keyframe(
                            # Deal and flip card for 1.5s
                            percentage = 0.3000,
                            transforms = [animation.Translate(0, 0), animation.Scale(1.0, 1.0)],
                        ),
                        animation.Keyframe(
                            # Keep card in place for rest of animation
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0), animation.Scale(1.0, 1.0)],
                        ),
                    ],
                ),

                # 4/7: Card 3 face
                animation.Transformation(
                    child = render.Box(
                        child = render.Image(src = card_face3),
                    ),
                    duration = 240,
                    delay = 0,
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, -32), animation.Scale(0.0, 1.0)],
                        ),
                        animation.Keyframe(
                            # Keep card hidden for 4.5s
                            percentage = 0.3000,
                            transforms = [animation.Translate(0, -32), animation.Scale(0.0, 1.0)],
                            curve = "ease_out",
                        ),
                        animation.Keyframe(
                            # Flip card for 0.5s
                            percentage = 0.4000,
                            transforms = [animation.Translate(22, 0), animation.Scale(1.0, 1.0)],
                        ),
                        animation.Keyframe(
                            # Keep card in place for rest of animation
                            percentage = 1.0,
                            transforms = [animation.Translate(22, 0), animation.Scale(1.0, 1.0)],
                        ),
                    ],
                ),

                # 5/7: Card name 1
                animation.Transformation(
                    child = render.Row(
                        children = [
                            render.Box(
                                height = 11,
                                width = 10,
                                color = "#00000099",
                                child = render.WrappedText(
                                    content = "1.",
                                    width = 10,
                                    align = "center",
                                    font = num_font,
                                    color = card_color,
                                ),
                            ),
                            render.Box(
                                height = 11,
                                width = 54,
                                color = "#00000099",
                                child = render.WrappedText(
                                    content = card_name1,
                                    align = "center",
                                    font = card_font,
                                    color = card_color,
                                ),
                            ),
                        ],
                    ),
                    duration = 240,
                    delay = 0,
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(-64, 0)],
                        ),
                        animation.Keyframe(
                            # Keep name hidden for 7.5s
                            percentage = 0.5000,
                            transforms = [animation.Translate(-64, 0)],
                            curve = "ease_in_out",
                        ),
                        animation.Keyframe(
                            # Reveal over 1s
                            percentage = 0.5667,
                            transforms = [animation.Translate(0, 0)],
                        ),
                        animation.Keyframe(
                            # Keep name in place for rest of animation
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                    ],
                ),

                # 6/7: Card name 2
                animation.Transformation(
                    child = render.Row(
                        children = [
                            render.Box(
                                height = 11,
                                width = 10,
                                color = "#00000099",
                                child = render.WrappedText(
                                    content = "2.",
                                    width = 10,
                                    align = "center",
                                    font = num_font,
                                    color = card_color,
                                ),
                            ),
                            render.Box(
                                height = 11,
                                width = 54,
                                color = "#00000099",
                                child = render.WrappedText(
                                    content = card_name2,
                                    align = "center",
                                    font = card_font,
                                    color = card_color,
                                ),
                            ),
                        ],
                    ),
                    duration = 240,
                    delay = 0,
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(-64, 11)],
                        ),
                        animation.Keyframe(
                            # Keep name hidden for 8.5s
                            percentage = 0.5667,
                            transforms = [animation.Translate(-64, 11)],
                            curve = "ease_in_out",
                        ),
                        animation.Keyframe(
                            # Reveal over 1s
                            percentage = 0.6333,
                            transforms = [animation.Translate(0, 11)],
                        ),
                        animation.Keyframe(
                            # Keep name in place for rest of animation
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 11)],
                        ),
                    ],
                ),

                # 7/7: Card name 3
                animation.Transformation(
                    child = render.Row(
                        children = [
                            render.Box(
                                height = 11,
                                width = 10,
                                color = "#00000099",
                                child = render.WrappedText(
                                    content = "3.",
                                    width = 10,
                                    align = "center",
                                    font = num_font,
                                    color = card_color,
                                ),
                            ),
                            render.Box(
                                height = 11,
                                width = 54,
                                color = "#00000099",
                                child = render.WrappedText(
                                    content = card_name3,
                                    align = "center",
                                    font = card_font,
                                    color = card_color,
                                ),
                            ),
                        ],
                    ),
                    duration = 240,
                    delay = 0,
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(-64, 22)],
                        ),
                        animation.Keyframe(
                            # Keep name hidden for 9.5s
                            percentage = 0.6333,
                            transforms = [animation.Translate(-64, 22)],
                            curve = "ease_in_out",
                        ),
                        animation.Keyframe(
                            # Reveal over 1s
                            percentage = 0.7000,
                            transforms = [animation.Translate(0, 22)],
                        ),
                        animation.Keyframe(
                            # Keep name in place for rest of animation
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 22)],
                        ),
                    ],
                ),
            ],
        ),
    )

def render_error(code):
    # Display if an error is received
    return render.Root(
        render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.WrappedText(
                    color = "#ff00ff",
                    content = "Tarot Card\nerror",
                    font = "CG-pixel-4x5-mono",
                    align = "center",
                ),
                render.Box(
                    width = 64,
                    height = 1,
                    color = "#ff00ff",
                ),
                render.Box(
                    width = 64,
                    height = 3,
                    color = "#000",
                ),
                render.WrappedText(
                    content = code,
                    font = "tom-thumb",
                    align = "center",
                ),
            ],
        ),
    )

def get_schema():
    # User options
    return schema.Schema(
        version = "1",
        fields = [
            # Select card back
            schema.Dropdown(
                id = "choice_back",
                name = "Card back",
                desc = "Choose a card back",
                icon = "paintRoller",
                options = [
                    schema.Option(display = "Style A", value = "A"),
                    schema.Option(display = "Style B", value = "B"),
                    schema.Option(display = "Style C", value = DEFAULT_BACK),
                    schema.Option(display = "Style D", value = "D"),
                ],
                default = DEFAULT_BACK,
            ),

            # Select card name color
            schema.Color(
                id = "choice_color",
                name = "Card name color",
                desc = "Choose a color for card names",
                icon = "palette",
                palette = [
                    DEFAULT_COLOR,  # purple
                    "#f9e890",  # yellow
                    "#90f9aa",  # green
                    "#f99090",  # red
                    "#90c6f9",  # blue
                ],
                default = DEFAULT_COLOR,
            ),

            # Select single card draw or three-card spread
            schema.Dropdown(
                id = "choice_draw",
                name = "Card draw",
                desc = "Choose to draw only one card or a spread of three cards",
                icon = "layerGroup",
                options = [
                    schema.Option(display = "Draw only one card", value = DEFAULT_DRAW),
                    schema.Option(display = "Draw three-card spread", value = "spread"),
                ],
                default = DEFAULT_DRAW,
            ),

            # Select card range
            schema.Dropdown(
                id = "choice_max",
                name = "Card range",
                desc = "Choose to draw from all cards or only the Marjor Arcana",
                icon = "handSparkles",
                options = [
                    schema.Option(display = "Pull from all cards", value = DEFAULT_MAX),
                    schema.Option(display = "Pull from Major Arcana only", value = "21"),
                ],
                default = DEFAULT_MAX,
            ),

            # Select daily or per display
            schema.Dropdown(
                id = "choice_freq",
                name = "Draw frequency",
                desc = "Choose to draw random cards throughout the day or only once per day",
                icon = "shuffle",
                options = [
                    schema.Option(display = "Draw throughout the day", value = DEFAULT_FREQ),
                    schema.Option(display = "Draw only once per day", value = "once"),
                ],
                default = DEFAULT_FREQ,
            ),
        ],
    )
