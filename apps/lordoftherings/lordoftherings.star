"""
Applet: LordOfTheRings
Summary: Displays LOTR quotes
Description: Displays random quotes from LOTR trilogy.
Author: Jake Manske
"""

load("http.star", "http")
load("images/aragorn_img.png", ARAGORN_IMG_ASSET = "file")
load("images/arwen_img.png", ARWEN_IMG_ASSET = "file")
load("images/bilbo_img.png", BILBO_IMG_ASSET = "file")
load("images/boromir_img.png", BOROMIR_IMG_ASSET = "file")
load("images/elrond_img.png", ELROND_IMG_ASSET = "file")
load("images/eomer_img.png", EOMER_IMG_ASSET = "file")
load("images/frodo_img.png", FRODO_IMG_ASSET = "file")
load("images/galadirel_img.png", GALADIREL_IMG_ASSET = "file")
load("images/gandalf_img.png", GANDALF_IMG_ASSET = "file")
load("images/gimli_img.png", GIMLI_IMG_ASSET = "file")
load("images/gollum_img.png", GOLLUM_IMG_ASSET = "file")
load("images/legolas_img.png", LEGOLAS_IMG_ASSET = "file")
load("images/samwise_img.png", SAMWISE_IMG_ASSET = "file")
load("images/saruman_img.png", SARUMAN_IMG_ASSET = "file")
load("images/sauron_img.png", SAURON_IMG_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

ARAGORN_IMG = ARAGORN_IMG_ASSET.readall()
ARWEN_IMG = ARWEN_IMG_ASSET.readall()
BILBO_IMG = BILBO_IMG_ASSET.readall()
BOROMIR_IMG = BOROMIR_IMG_ASSET.readall()
ELROND_IMG = ELROND_IMG_ASSET.readall()
EOMER_IMG = EOMER_IMG_ASSET.readall()
FRODO_IMG = FRODO_IMG_ASSET.readall()
GALADIREL_IMG = GALADIREL_IMG_ASSET.readall()
GANDALF_IMG = GANDALF_IMG_ASSET.readall()
GIMLI_IMG = GIMLI_IMG_ASSET.readall()
GOLLUM_IMG = GOLLUM_IMG_ASSET.readall()
LEGOLAS_IMG = LEGOLAS_IMG_ASSET.readall()
SAMWISE_IMG = SAMWISE_IMG_ASSET.readall()
SARUMAN_IMG = SARUMAN_IMG_ASSET.readall()
SAURON_IMG = SAURON_IMG_ASSET.readall()

MOVIE_FONT = "CG-pixel-3x5-mono"
MOVIE_COLOR = "#701010"

LOTR_URL = "https://the-one-api.dev/v2"

HTTP_OK = 200

CACHE_TIMEOUT = 600  # ten minutes

def main(config):
    char_id = config.get("character") or RANDOM

    # if character is set to random, choose one at random based on timestamp
    if char_id == RANDOM:
        rand_char = int(time.now().nanosecond / 1000) % len(CHARACTER_LOOKUP)
        char_id = CHARACTER_LOOKUP.keys()[rand_char]

    # set up web request
    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer {0}".format(config.get("lotr_api_key")),
    }
    resp = http.get("https://the-one-api.dev/v2/character/{0}/quote".format(char_id), headers = headers, ttl_seconds = CACHE_TIMEOUT)

    # check the HTTP response code
    # if we fail, send back "shall not pass"
    status_code = resp.status_code
    if (status_code != HTTP_OK):
        char_id = GANDALF_ID
        quote = SHALL_NOT_PASS_QUOTE.format(status_code, resp.json()["message"])
        movie = SHALL_NOT_PASS_MOVIE
    else:
        quotes = resp.json()["docs"]

        # get a "random" quote_id based on the current timestamp
        quote_id = int(time.now().nanosecond / 1000) % len(quotes)

        quote = quotes[quote_id].get("dialog")

        # clean up the quote if necessary, the db is not perfect
        if not quote_has_punctuation(quote):
            quote = quote + "."

        # map it to the right movie
        movie = MOVIE_LOOKUP[quotes[quote_id].get("movie")]

    # get the character we are using out of the character metadata dictionary
    character_to_use = CHARACTER_LOOKUP[char_id]

    # render the image
    return render.Root(
        delay = 200,
        child = render.Column(
            main_align = "start",
            children = [
                render.Box(
                    height = 16,
                    width = 64,
                    child = render.Marquee(
                        child = render.WrappedText(
                            content = quote,
                            font = MOVIE_FONT,
                            linespacing = 1,
                            width = 64,
                        ),
                        height = 16,
                        scroll_direction = "vertical",
                        offset_start = 16,
                        align = "center",
                    ),
                ),
                render.Row(
                    main_align = "start",
                    children = [
                        render.Image(
                            src = character_to_use.Img,
                        ),
                        render.Column(
                            cross_align = "start",
                            children = [
                                render.Text(
                                    content = character_to_use.Name,
                                    font = character_to_use.Font,
                                    color = character_to_use.Color,
                                ),
                                render.WrappedText(
                                    content = movie,
                                    font = MOVIE_FONT,
                                    color = MOVIE_COLOR,
                                    linespacing = 1,
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def quote_has_punctuation(quote):
    """make sure the quote ends with some punctuation

    Args:
        quote (string): the quote to check
    """
    if quote.endswith(".") or quote.endswith("!") or quote.endswith("?"):
        return True
    return False

def struct_Char(name, id, font, color, img):
    return struct(Name = name, Id = id, Font = font, Color = color, Img = img)

# failed to ping endpoint quote info
GANDALF_ID = "5cd99d4bde30eff6ebccfea0"
SHALL_NOT_PASS_QUOTE = "HTTP response code {0}: {1}"
SHALL_NOT_PASS_MOVIE = "YOU SHALL NOT PASS"

### images

CHARACTER_LOOKUP = {
    "5cd99d4bde30eff6ebccfc07": struct_Char("Arwen", "5cd99d4bde30eff6ebccfc07", MOVIE_FONT, "#9d9ea0", ARWEN_IMG),
    "5cd99d4bde30eff6ebccfbe6": struct_Char("Aragorn", "5cd99d4bde30eff6ebccfbe6", MOVIE_FONT, "#d0ad39", ARAGORN_IMG),
    "5cd99d4bde30eff6ebccfc38": struct_Char("Bilbo", "5cd99d4bde30eff6ebccfc38", MOVIE_FONT, "#703a07", BILBO_IMG),
    "5cd99d4bde30eff6ebccfc57": struct_Char("Boromir", "5cd99d4bde30eff6ebccfc57", MOVIE_FONT, "#d0ad39", BOROMIR_IMG),
    "5cd99d4bde30eff6ebccfcc8": struct_Char("Elrond", "5cd99d4bde30eff6ebccfcc8", MOVIE_FONT, "#eadede", ELROND_IMG),
    "5cdbdecb6dc0baeae48cfa5a": struct_Char("Eomer", "5cdbdecb6dc0baeae48cfa5a", MOVIE_FONT, "#b9941a", EOMER_IMG),
    "5cd99d4bde30eff6ebccfc15": struct_Char("Frodo", "5cd99d4bde30eff6ebccfc15", MOVIE_FONT, "#703a07", FRODO_IMG),
    "5cd99d4bde30eff6ebccfd06": struct_Char("Galadriel", "5cd99d4bde30eff6ebccfd06", MOVIE_FONT, "#eadede", GALADIREL_IMG),
    "5cd99d4bde30eff6ebccfea0": struct_Char("Gandalf", "5cd99d4bde30eff6ebccfea0", MOVIE_FONT, "#807f7f", GANDALF_IMG),
    "5cd99d4bde30eff6ebccfd23": struct_Char("Gimli", "5cd99d4bde30eff6ebccfd23", MOVIE_FONT, "#9c2200", GIMLI_IMG),
    "5cd99d4bde30eff6ebccfe9e": struct_Char("Gollum", "5cd99d4bde30eff6ebccfe9e", MOVIE_FONT, "#b2a569", GOLLUM_IMG),
    "5cd99d4bde30eff6ebccfd81": struct_Char("Legolas", "5cd99d4bde30eff6ebccfd81", MOVIE_FONT, "#21471c", LEGOLAS_IMG),
    "5cd99d4bde30eff6ebccfd0d": struct_Char("Samwise", "5cd99d4bde30eff6ebccfd0d", MOVIE_FONT, "#ffd1a9", SAMWISE_IMG),
    "5cd99d4bde30eff6ebccfea4": struct_Char("Saruman", "5cd99d4bde30eff6ebccfea4", MOVIE_FONT, "#FFFFFF", SARUMAN_IMG),
    "5cd99d4bde30eff6ebccfea5": struct_Char("Sauron", "5cd99d4bde30eff6ebccfea5", MOVIE_FONT, "#c90000", SAURON_IMG),
}

MOVIE_LOOKUP = {
    "5cd95395de30eff6ebccde5b": "The Two Towers",
    "5cd95395de30eff6ebccde5c": "Fellowship of the Ring",
    "5cd95395de30eff6ebccde5d": "The Return of the King",
}

RANDOM = "Random"

def get_schema():
    options = []
    for character in CHARACTER_LOOKUP.values():
        options.append(
            schema.Option(
                display = character.Name,
                value = character.Id,
            ),
        )

    # add a "random" option
    options.append(
        schema.Option(
            display = RANDOM,
            value = RANDOM,
        ),
    )
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "lotr_api_key",
                name = "Lord of the Rings API Key",
                desc = "Your The One API key. See https://the-one-api.dev/ for details.",
                icon = "key",
                secret = True,
            ),
            schema.Dropdown(
                id = "character",
                name = "Character",
                desc = "The character to display a quote for.",
                icon = "quoteRight",
                default = RANDOM,  # random default
                options = options,
            ),
        ],
    )
