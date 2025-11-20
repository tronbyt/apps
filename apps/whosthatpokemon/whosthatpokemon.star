"""
Applet: WhosThatPokemon
Summary: Pokemon Quiz Game
Description: Test your Pokemon Master knowledge with this rendition of "Who's That Pokemon?". Turn off classic mode to crank up the difficulty. Set your Tidbyt speed to ensure the animation takes up exactly half the time is has displayed.
Author: Nicole Brooks
"""

load("background.png", BACKGROUND = "file")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

ALL_POKEMON = 1000
CLASSIC_POKEMON = 386
POKEAPI_URL = "https://pokeapi.co/api/v2/pokemon/{}"
IMGIX_URL = "https://pokesprites.imgix.net/{}.png?bri=-100"
CACHE_TTL_SECONDS = 3600 * 24 * 60  # 60 days in seconds.

def main(config):
    print("Let's play...WHO'S. THAT. POKEMON?!")

    allPokemon = howManyPokemon(config)
    chosenId = random.number(1, allPokemon)
    pokemon = json.decode(getPokemon(chosenId))
    speed = getSpeed(config)

    if pokemon == None:
        return []

    sprite_url = pokemon["sprites"]["front_default"]

    # Variables that will be used by the render.
    name = formatName(pokemon["name"])
    revealedImage = getImage(sprite_url)
    silhouette = getImage(IMGIX_URL.format(chosenId))

    # If something went wrong with the API, skip the app completely.
    if revealedImage == None or silhouette == None:
        return []

    frames = compileFrames(name, silhouette, revealedImage, speed)
    print("The game is afoot. The secret Pokemon is: " + name)

    return render.Root(
        delay = 125,
        show_full_animation = True,
        child = render.Stack(
            children = [
                render.Image(
                    src = BACKGROUND.readall(),
                ),
                render.Animation(
                    children = frames,
                ),
            ],
        ),
    )

# Gets new Pokemon from API and caches.
def getPokemon(id):
    url = POKEAPI_URL.format(id)
    res = http.get(url, ttl_seconds = CACHE_TTL_SECONDS)
    if res.status_code != 200:
        print("ERROR: " + str(res.status_code))
        return None

    return res.body()

# Formats all names. Removes all hyphens that don't belong for forms and spaces.
# Also capitalizes appropriately.
def formatName(name):
    namesWithSpaces = ["mr-mime", "mime-jr", "type-null", "tapu-koko", "tapu-lele", "tapu-bulu", "tapu-fini", "mr-rime", "great-tusk", "scream-tail", "brute-bonnet", "flutter-mane", "slither-wing", "sandy-shocks", "iron-treads", "iron-bundle", "iron-hands", "iron-jugulis", "iron-moth", "iron-thorns", "roaring-moon", "iron-valiant", "walking-wake", "iron-leaves"]
    namesWithHyphens = ["ho-oh", "porygon-z", "jangmo-o", "hakamo-o", "kommo-o", "wo-chien", "chien-pao", "chi-yu"]
    if name in namesWithHyphens:
        return name.capitalize()
    elif name in namesWithSpaces:
        return name.replace("-", " ").title()
    elif "-" in name:
        return name.split("-")[0].capitalize()
    else:
        return name.capitalize()

# Gets requested image
# Returns image encoded and ready for use.
def getImage(url):
    res = http.get(url, ttl_seconds = CACHE_TTL_SECONDS)
    if res.status_code != 200:
        print("Failed to pull pokemon image: " + str(res.status_code))
        return None

    return res.body()

# Returns the number of pokemon to pull from.
def howManyPokemon(config):
    allPokemon = ALL_POKEMON
    if config.bool("classics_only", False) == True:
        allPokemon = CLASSIC_POKEMON
    return allPokemon

# Returns the speed of the tidbyt in float format.
def getSpeed(config):
    strSpeed = float(config.get("speed", "15"))
    return strSpeed

# Gets all frames needed for the animation.
def compileFrames(name, silhouette, revealedImage, speed):
    frames = []
    frameCount = int(speed * 8)
    startTransition = frameCount / 2 - 4
    endTransition = frameCount / 2 + 4
    transitionFrame = 0
    for frame in range(1, frameCount):
        if frame < startTransition:
            frames.append(fullLayoutHidden(silhouette, 30))
        elif frame >= endTransition:
            frames.append(fullLayoutRevealed(revealedImage, 30, name))
        else:
            # if it's transitioning, get transition width
            width = getTransitionWidth(transitionFrame)
            if transitionFrame > 3:
                frames.append(fullLayoutRevealed(revealedImage, width, name))
            else:
                frames.append(fullLayoutHidden(silhouette, width))
            transitionFrame += 1

    return frames

# Layout function with text on side.
def fullLayoutHidden(image, width):
    return render.Row(
        expanded = True,
        main_align = "center",
        children = [
            render.Box(
                width = 30,
                height = 30,
                child = render.Padding(
                    pad = (5, 0, 0, 0),
                    child = render.Image(
                        src = image,
                        width = width,
                        height = 30,
                    ),
                ),
            ),
            render.Box(
                width = 32,
                height = 32,
                child = render.Column(
                    cross_align = "center",
                    children = [
                        render.Text(
                            content = "Who's",
                            color = "#3B0301",
                            font = "tom-thumb",
                        ),
                        render.Box(
                            height = 3,
                        ),
                        render.Text(
                            content = "That",
                            color = "#3B0301",
                            font = "tom-thumb",
                        ),
                        render.Box(
                            height = 3,
                        ),
                        render.Text(
                            content = "Pokemon?",
                            color = "#3B0301",
                            font = "tom-thumb",
                        ),
                    ],
                ),
            ),
        ],
    )

# Layout function with text on bottom.
def fullLayoutRevealed(image, width, text):
    return render.Stack(
        children = [
            render.Box(
                width = 38,
                height = 30,
                child = render.Image(
                    src = image,
                    width = width,
                    height = 30,
                ),
            ),
            render.Padding(
                pad = (0, 24, 0, 0),
                child = render.Box(
                    height = 9,
                    child = render.Text(
                        content = text,
                        offset = 0,
                        color = "#240109",
                    ),
                ),
            ),
        ],
    )

# Gets the width the image has to be at this frame of the transition.
def getTransitionWidth(frame):
    widths = [18, 12, 6, 1, 1, 6, 12, 18]
    return widths[frame]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "classics_only",
                name = "Classic Mode",
                desc = "Only use Pokemon from generations 1-3. On by default.",
                icon = "dragon",
                default = True,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Speed",
                desc = "Speed of your Tidbyt. This determines how long the silhouette is displayed.",
                icon = "stopwatch",
                default = "15",
                options = [
                    schema.Option(
                        display = "Normal",
                        value = "15",
                    ),
                    schema.Option(
                        display = "Quick",
                        value = "10",
                    ),
                    schema.Option(
                        display = "Turbo",
                        value = "7.5",
                    ),
                    schema.Option(
                        display = "Plaid",
                        value = "5",
                    ),
                ],
            ),
        ],
    )
