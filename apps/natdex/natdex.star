"""
Applet: National Pokedex
Summary: Display a random Pokemon from Gen I - VII
Description: Display a random Pokemon from your region of choice
Author: Lauren Kopac
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

POKEAPI_URL = "https://pokeapi.co/api/v2/pokemon/{}"
REGIONAL_DEX_ID = "regional_dex_code"
CACHE_TTL_SECONDS = 3600 * 24 * 7  # 7 days in seconds.

def get_regions():
    regions = ["National", "Kanto", "Johto", "Hoenn", "Sinnoh", "Unova", "Kalos", "Alola"]
    region_options = []
    for x in regions:
        region_options.append(
            schema.Option(
                display = x,
                value = x,
            ),
        )
    return region_options

def get_schema():
    regions = get_regions()
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = REGIONAL_DEX_ID,
                name = "Regional Pokedex",
                desc = "Which Pokedex do you want to pull from?",
                icon = "book",
                default = regions[0].value,
                options = regions,
            ),
        ],
    )

def main(config):
    MIN, MAX = 1, 809
    dex_region = config.get(REGIONAL_DEX_ID)
    if dex_region == "National":
        pass
    elif dex_region == "Kanto":
        MIN, MAX = 1, 151
    elif dex_region == "Johto":
        MIN, MAX = 152, 251
    elif dex_region == "Hoenn":
        MIN, MAX = 252, 386
    elif dex_region == "Sinnoh":
        MIN, MAX = 387, 493
    elif dex_region == "Unova":
        MIN, MAX = 494, 649
    elif dex_region == "Kalos":
        MIN, MAX = 650, 721
    elif dex_region == "Alola":
        MIN, MAX = 722, 809

    random.seed(time.now().unix // 15)
    dex_number = random.number(MIN, MAX)
    pokemon = get_pokemon(dex_number)
    name = pokemon["name"].title()

    sprite_url = pokemon["sprites"]["versions"]["generation-vii"]["icons"]["front_default"]
    sprite = get_cachable_data(sprite_url)
    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "start",
                cross_align = "center",
                children = [
                    render.Image(src = sprite),
                    render.Padding(
                        pad = (0, 0, 0, 0),
                        child = render.Marquee(
                            child = render.Row(
                                main_align = "start",
                                cross_align = "center",
                                expanded = True,
                                children = [
                                    render.Text(
                                        content = name,
                                        font = "CG-pixel-4x5-mono",
                                    ),
                                    render.Text(
                                        content = " | #",
                                    ),
                                    render.Text(
                                        content = dex_number,
                                    ),
                                ],
                            ),
                            width = 64,
                            scroll_direction = "horizontal",
                        ),
                    ),
                ],
            ),
        ),
    )

def round(num):
    """Rounds floats to a single decimal place."""
    return float(int(num * 10) / 10)

def get_pokemon(id):
    url = POKEAPI_URL.format(id)
    data = get_cachable_data(url)
    return json.decode(data)

def get_region(dex_number):
    if int(dex_number) < 152:
        return "Kanto"
    elif int(dex_number) < 252:
        return "Johto"
    elif int(dex_number) < 387:
        return "Hoenn"
    elif int(dex_number) < 494:
        return "Sinnoh"
    elif int(dex_number) < 650:
        return "Unova"
    elif int(dex_number) < 722:
        return "Kalos"
    elif int(dex_number) < 810:
        return "Alola"
    else:
        return "Habitat Unknown"

def get_cachable_data(url, ttl_seconds = CACHE_TTL_SECONDS):
    res = http.get(url = url, ttl_seconds = ttl_seconds)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()
