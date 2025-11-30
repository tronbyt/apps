"""
Applet: Fortnite Store
Summary: Preview the Fortnite store
Description: See items currently featured in the Fortnite store.
Author: naomi-nori
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("images/img_bc696d5d.png", IMG_bc696d5d_ASSET = "file")

color_key = {
    "handmade": "#fff",
    "uncommon": "#31923b",
    "rare": "#4e51f4",
    "epic": "#9c4cb9",
    "legendary": "#f1af2c",
    "mythic": "#fcd03e",
    "exotic": "#0abfd0",
    "transcendent": "#da505d",
}

default_item = {
    "vBucks": 800.00,
    "rarity": "uncommon",
    "name": "Tinseltoes",
    "image": IMG_bc696d5d_ASSET.readall(),
}

def main(config):
    api_key = config.get("api_key")
    if api_key:
        store_api = "https://api.fortnitetracker.com/v1/store"
        items_resp = http.get(store_api, headers = {"TRN-Api-Key": api_key}, ttl_seconds = 120)
        items = items_resp.json()

        picked = random.number(0, len(items) - 1)
        picked_item = items[picked]
    else:
        picked_item = default_item

    color = color_key.get(picked_item["rarity"].lower())
    if color == None:
        color = "#fff"

    if "imageUrl" in picked_item:
        image = get_cachable_data(picked_item["imageUrl"])
    else:
        image = picked_item["image"]

    return render.Root(
        render.Stack(
            children = [
                render.Column(
                    main_align = "end",
                    children = [render.Image(src = image, height = 32)],
                ),
                render.Marquee(
                    width = 64,
                    offset_start = 32,
                    offset_end = 32,
                    align = "end",
                    child = render.Padding(
                        pad = (0, 2, 2, 0),
                        child = render.Text(
                            content = picked_item["name"],
                            color = color,
                        ),
                    ),
                ),
                render.Column(
                    expanded = True,
                    main_align = "end",
                    children = [
                        render.Padding(
                            pad = (0, 0, 2, 2),
                            child = render.Row(
                                expanded = True,
                                main_align = "end",
                                children = [
                                    render.Text(content = "V", color = "#34c0eb"),
                                    render.Text(content = str(picked_item["vBucks"])[0:-2]),
                                ],
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def get_cachable_data(url, ttl_seconds = 3600):
    res = http.get(url = url, ttl_seconds = ttl_seconds)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "Your Fortnite Tracker API key.",
                icon = "key",
                secret = True,
            ),
        ],
    )
