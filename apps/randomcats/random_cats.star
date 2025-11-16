"""
Applet: Random Cats
Summary: Shows pictures of cats
Description: Shows random pictures of cats/gifs of cats from Cats as a Service (cataas.com).
Author: mrrobot245
"""

load("cache.star", "cache")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")

def main(config):
    height = canvas.height()

    if config.bool("gifs", True):
        url = "https://cataas.com/cat/gif?height=" + str(height)
    else:
        url = "https://cataas.com/cat?height=" + str(height)

    # Preview
    # url = https://cataas.com/cat/vHWxUr3RH8Gp0bke?height=" + str(height)

    imgSrc = get_cached(url)

    return render.Root(
        child = render.Box(
            child = render.Image(
                src = imgSrc,
                height = height,
            ),
        ),
    )

def get_cached(url, ttl_seconds = 20):
    res = http.get(url, ttl_seconds = ttl_seconds)
    if res.status_code != 200:
        fail("status %d from %s: %s" % (res.status_code, url, res.body()))

    return res.body()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "gifs",
                name = "Animated Gifs",
                desc = "Show Animated Gifs",
                icon = "codeFork",
                default = True,
            ),
        ],
    )
