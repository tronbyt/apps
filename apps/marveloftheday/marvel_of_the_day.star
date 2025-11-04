"""
Applet: Marvel of the Day
Summary: A Marvel character a day
Description: Shows the name and image of a Marvel Comics character using the Marvel API.
Author: flynnt
"""

load("hash.star", "hash")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BASE_URL = "https://gateway.marvel.com/v1/public/characters"

def main(config):
    """
    App entrypoint.
    Retrieves and parses a single Marvel character.
    Returns rendered application root.
    """
    if config.get("public_key") == None or config.get("private_key") == None:
        image = http.get("http://i.annihil.us/u/prod/marvel/i/mg/2/60/537bcaef0f6cf.jpg").body()
        name = "Something went wrong, enjoy this image of Wolverine while we fix it."

        return render_data(image, name)
    else:
        random.seed(time.now().unix // 86400)
        characterId = get_random_character_id(config)
        params = get_auth_params(config)
        req = http.get(BASE_URL + "/" + str(characterId), ttl_seconds = 86400, params = params)
        if req.status_code != 200:
            fail("API request failed with status:", req.status_code)

        item = req.json()["data"]["results"][0]
        name = item["name"]
        imageUrlSegments = item["thumbnail"]
        imageUrl = imageUrlSegments["path"] + "." + imageUrlSegments["extension"]
        image = http.get(imageUrl).body()

        return render_data(image, name)

def render_data(image, name):
    return render.Root(
        render.Row(
            children = [
                render.Box(
                    height = 32,
                    width = 28,
                    child = render.Image(
                        src = image,
                        height = 28,
                    ),
                ),
                render.Box(
                    height = 32,
                    child = render.Marquee(
                        align = "center",
                        width = 35,
                        child = render.Text(name),
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "public_key",
                name = "Marvel API Public Key",
                desc = "Your Marvel API public key.",
                icon = "key",
            ),
            schema.Text(
                id = "private_key",
                name = "Marvel API Private Key",
                desc = "Your Marvel API private key.",
                icon = "key",
            ),
        ],
    )

def get_auth_params(config):
    """
    Returns Marvel API authentication params.
    """
    timestamp = str(1699392191)
    params = {
        "ts": timestamp,
        "apikey": config.get("public_key"),
        "hash": hash.md5(timestamp + config.get("private_key") + config.get("public_key")),
    }

    return params

def get_random_character_id(config):
    """
    Get a single, random character.
    Only return a character if the character has an image.
    """
    limit = 1
    maxOffset = 1562
    offset = random.number(0, maxOffset)
    baseParams = {"limit": str(limit), "offset": str(offset)}
    params = baseParams | get_auth_params(config)

    req = http.get(BASE_URL, ttl_seconds = 82800, params = params)
    if req.status_code != 200:
        fail("API request failed with status:", req.status_code)

    responseCharacter = req.json()["data"]["results"][0]
    imagePath = responseCharacter["thumbnail"]["path"]
    hasImage = imagePath != "http://i.annihil.us/u/prod/marvel/i/mg/b/40/image_not_available"
    characterId = responseCharacter["id"]

    if not hasImage:
        print("Seeking...")
        return get_random_character_id()

    print("Character found...")
    return int(characterId)
