"""
Applet: Unsplash
Summary: Shows random photos
Description: Displays a random image from Unsplash.
Author: zephyern, gabe565
"""

load("cache.star", "cache")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")

DEFAULT_CACHE_MINS = 5

UNSPLASH_URL = "https://api.unsplash.com"
DEFAULT_IMAGE_URL = "https://images.unsplash.com/photo-1645069258059-6f5a71256c4a"

def get_topic_id(slug, key):
    cache_key = "topic:" + slug
    id = cache.get(cache_key)
    if id:
        return id

    res = http.get(
        UNSPLASH_URL + "/topics/" + slug,
        headers = {
            "Accept-Version": "v1",
            "Authorization": "Client-ID %s" % key,
        },
        ttl_seconds = 60,
    )

    if res.status_code != 200:
        fail("HTTP request failed with status %d" % res.status_code)

    id = res.json()["id"]
    cache.set(cache_key, id, ttl_seconds = 86400)
    return id

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
        topics_raw = config.get("topics")
        topics = [get_topic_id(v, key) for v in topics_raw.split(",") if v] if topics_raw else []
        params = {
            "orientation": "landscape",
            "collections": config.get("collections"),
            "topics": ",".join(topics),
            "username": config.get("username"),
            "query": config.get("query"),
            "content_filter": config.get("content_filter"),
        }
        params = {k: v for k, v in params.items() if v}
        print("Params:", params)

        res = http.get(
            UNSPLASH_URL + "/photos/random",
            headers = {
                "Accept-Version": "v1",
                "Authorization": "Client-ID %s" % key,
            },
            params = params,
            ttl_seconds = cache_sec,
        )

        if res.status_code == 200:
            json = res.json()
            image_url = json["urls"]["raw"]
            print("Image URL:", image_url)
            image = get_image(image_url, ttl_seconds = cache_sec)

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
                name = "Access Key",
                desc = "Your Unsplash API Access Key. See https://unsplash.com/developers for details.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "query",
                name = "Query",
                desc = "Limit selection to photos matching a search term.",
                icon = "magnifyingGlass",
                default = "",
            ),
            schema.Text(
                id = "username",
                name = "Username",
                desc = "Limit selection to a single user.",
                icon = "user",
                default = "",
            ),
            schema.Text(
                id = "collections",
                name = "Collections",
                desc = "Comma-separated collection IDs to filter selection. To find the ID, open a collection and copy the numbers in the URL.",
                icon = "folderTree",
                default = "",
            ),
            schema.Text(
                id = "topics",
                name = "Topics",
                desc = "Comma-separated topic slugs to filter selection. To find the slug, open a topic and copy the last part of the URL.",
                icon = "shapes",
                default = "",
            ),
            schema.Dropdown(
                id = "content_filter",
                name = "Content Filter",
                desc = "Limit results by content safety. See https://unsplash.com/documentation#content-safety for details.",
                icon = "filter",
                default = "low",
                options = [
                    schema.Option(
                        display = "Low",
                        value = "low",
                    ),
                    schema.Option(
                        display = "High",
                        value = "high",
                    ),
                ],
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
