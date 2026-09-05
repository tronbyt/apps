"""
Applet: Astro Pic of Day
Summary: New pic from NASA each day
Description: Displays the astronomy picture of the day from NASA.
Author: Brian Bell
"""

load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("images/nasa_logo.png", NASA_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

NASA_LOGO = NASA_LOGO_ASSET.readall()

APOD_URL = "https://api.nasa.gov/planetary/apod"
DEVELOPER_API_KEY = "TZpCjZ84E9ClE93Utu4c5BnfhGXvBEOfcWyJ2OaR"  # Limited key for development

# Register with NASA for a key to encrypt for prod: https://api.nasa.gov

TTL_SECONDS = 3600

def main(config):
    display_info = config.bool("display_info")
    apod = get_apod(
        APOD_URL,
        DEVELOPER_API_KEY,
        TTL_SECONDS,
    )
    title = apod["title"]
    image_src = base64.decode(apod["image_src"])

    children = [
        render.Column(
            cross_align = "center",
            main_align = "space_between",
            children = [
                render.Row(
                    expanded = True,
                    main_align = "center",
                    children = [
                        render.Image(
                            src = image_src,
                            height = 32,
                        ),
                    ],
                ),
            ],
        ),
    ]

    if display_info:
        children.append(
            animation.Transformation(
                child = render.Box(
                    child = render.Box(
                        color = "#00000099",
                        width = 64,
                        child = render.Column(
                            cross_align = "center",
                            children = [
                                render.Image(
                                    src = NASA_LOGO,
                                    height = 8,
                                ),
                                render.Padding(
                                    pad = (1, 2, 1, 0),
                                    child = render.WrappedText(
                                        align = "center",
                                        content = title,
                                        font = "tom-thumb",
                                    ),
                                ),
                            ],
                        ),
                    ),
                ),
                delay = 70,
                direction = "alternate",
                duration = 50,
                fill_mode = "forwards",
                origin = animation.Origin(0.5, 0.5),
                keyframes = [
                    animation.Keyframe(
                        percentage = 0.0,
                        transforms = [animation.Translate(0, 32)],
                        curve = "ease_in_out",
                    ),
                    animation.Keyframe(
                        percentage = 1.0,
                        transforms = [animation.Translate(0, 0)],
                    ),
                ],
            ),
        )
    return render.Root(
        child = render.Stack(
            children = children,
        ),
    )

def get_apod(url, api_key, ttl_seconds):
    # Return astronomy picture of the day
    params = {"api_key": api_key, "thumbs": "True"}
    response = http.get(url = url, params = params, ttl_seconds = ttl_seconds)
    if response.status_code != 200:
        fail("status %d from %s: %s" % (response.status_code, url, response.body()))
    apod = response.json()
    apod["image_src"] = base64.encode(get_image_src(apod["url"], ttl_seconds))

    return apod

def get_image_src(url, ttl_seconds):
    # Return and cache image data from url provided
    response = http.get(url, ttl_seconds = ttl_seconds)
    if response.status_code != 200:
        fail("status %d from %s: %s" % (response.status_code, url, response.body()))
    image_src = response.body()
    return image_src

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "display_info",
                name = "Display Info?",
                desc = "if available",
                icon = "gear",
                default = True,
            ),
        ],
    )
