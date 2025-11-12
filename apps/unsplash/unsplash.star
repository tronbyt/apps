"""
Applet: Unsplash
Summary: Shows random photos
Description: Displays a random image from Unsplash.
Author: zephyern, gabe565
"""

load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")

DEFAULT_CACHE_MINS = 5

UNSPLASH_URL = "https://api.unsplash.com/photos/random"
DEFAULT_IMAGE_URL = "https://images.unsplash.com/photo-1645069258059-6f5a71256c4a"

def get_image(url, ttl_seconds = DEFAULT_CACHE_MINS * 60):
    res = http.get(
        url,
        params = {
            "fit": "crop",
            "crop": "edges",
            "w": str(canvas.width()),
            "h": str(canvas.height()),
            "fm": "png",
        },
        ttl_seconds = ttl_seconds,
    )

    if res.status_code != 200:
        fail("HTTP request failed with status %d" % res.status_code)

    return res.body()

def main(config):
    cache_mins_str = config.str("cache_mins", str(DEFAULT_CACHE_MINS))
    cache_mins = int(cache_mins_str) if cache_mins_str.isdigit() else DEFAULT_CACHE_MINS
    cache_sec = cache_mins * 60

    image = None

    key = config.get("unsplash_access_key")
    if key:
        print("Querying for image.")
        res = http.get(
            UNSPLASH_URL,
            headers = {
                "Accept-Version": "v1",
                "Authorization": "Client-ID %s" % key,
            },
            params = {
                "orientation": "landscape",
            },
            ttl_seconds = cache_sec,
        )

        if res.status_code == 200:
            json = res.json()
            thumb_url = json["urls"]["thumb"]
            image = get_image(thumb_url, ttl_seconds = cache_sec)

    if not image:
        image = get_image(DEFAULT_IMAGE_URL, ttl_seconds = cache_sec)

    return render.Root(
        child = render.Image(src = image),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "unsplash_access_key",
                name = "Unsplash Access Key",
                desc = "Your Unsplash API Access Key. See https://unsplash.com/developers for details.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "cache_mins",
                name = "Cache Duration",
                desc = "How long to cache images (in minutes)",
                icon = "clock",
                default = str(DEFAULT_CACHE_MINS),
            ),
        ],
    )
