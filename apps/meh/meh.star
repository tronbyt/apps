"""
Applet: Meh
Summary: Meh Deal
Description: Current deal on meh.com.
Author: hoop33
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("images/img_f649742d.png", IMG_f649742d_ASSET = "file")

MEH_CACHE = "meh"
MEH_IMAGE_CACHE = "meh-image"
MEH_URL = "https://meh.com/api/1/current.json?apikey="
TTL_SECONDS = 600

NO_DEAL_IMAGE = IMG_f649742d_ASSET.readall()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "meh_api_key",
                name = "Meh API Key",
                desc = "Your Meh.com API key. See https://meh.com/developers for details.",
                icon = "key",
                secret = True,
            ),
        ],
    )

def main(config):
    api_key = config.get("meh_api_key")

    deal = get_deal(api_key)
    image = base64.decode(get_image(deal))

    return render.Root(
        delay = 150,
        child = render.Row(
            children = [
                render.Box(
                    width = 32,
                    height = 32,
                    child = render.Image(
                        src = image,
                        width = 32,
                        height = 32,
                    ),
                ),
                render.Box(
                    width = 32,
                    height = 32,
                    child = render.Padding(
                        pad = (1, 0, 0, 0),
                        child = render.Column(
                            main_align = "space_around",
                            children = [
                                render.WrappedText(
                                    content = deal["title"],
                                    font = "tom-thumb",
                                    color = "#0ff",
                                    width = 32,
                                    height = 24,
                                ),
                                render.Text(
                                    content = "$" + str(deal["items"][0]["price"]),
                                    font = "tom-thumb",
                                    color = "#f00",
                                ),
                            ],
                        ),
                    ),
                ),
            ],
        ),
    )

def get_deal(api_key):
    deal = {"title": "No Deal", "items": [{"price": 0}]}

    deal_cached = cache.get(MEH_CACHE)
    if deal_cached != None:
        deal = json.decode(deal_cached)
    elif api_key != None:
        response = http.get(MEH_URL + api_key)
        if response.status_code == 200:
            deal = response.json()["deal"]

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set(MEH_CACHE, json.encode(deal), ttl_seconds = TTL_SECONDS)

    return deal

def get_image(deal):
    image = NO_DEAL_IMAGE

    image_cached = cache.get(MEH_IMAGE_CACHE)
    if image_cached != None:
        image = image_cached
    else:
        item = deal["items"][0]
        if "photo" in item.keys():
            photo_url = item["photo"]
            response = http.get(photo_url)
            if response.status_code == 200:
                image = base64.encode(response.body())

                # TODO: Determine if this cache call can be converted to the new HTTP cache.
                cache.set(MEH_IMAGE_CACHE, image, ttl_seconds = TTL_SECONDS)

    return image
