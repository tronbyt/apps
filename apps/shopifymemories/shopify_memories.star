"""
Applet: Shopify Memories
Summary: Remember your journey
Description: Showcase some of your store’s most significant memories like your first sale, anniversaries, and more.
Author: Shopify
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/animated_shopify_bag.gif", IMAGE_ANIMATED_SHOPIFY_BAG_ASSET = "file")
load("images/animation_background.gif", ANIMATION_BACKGROUND_ASSET = "file")
load("images/image_alien_error.gif", IMAGE_ALIEN_ERROR_ASSET = "file")
load("images/image_starfield.gif", IMAGE_STARFIELD_ASSET = "file")
load("images/picture_frame_bg.gif", PICTURE_FRAME_BG_ASSET = "file")
load("images/recent_orders.png", RECENT_ORDERS_ASSET = "file")
load("images/recent_sales.png", RECENT_SALES_ASSET = "file")
load("images/trends_animated.gif", TRENDS_ANIMATED_ASSET = "file")
load("images/trends_container.png", TRENDS_CONTAINER_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

ANIMATION_BACKGROUND = ANIMATION_BACKGROUND_ASSET.readall()
IMAGE_ALIEN_ERROR = IMAGE_ALIEN_ERROR_ASSET.readall()
IMAGE_STARFIELD = IMAGE_STARFIELD_ASSET.readall()

# CONFIG
SHOPIFY_COUNTER_API_HOST = "https://www.shopcounter.app"
CACHE_TTL = 30

# COLORS
COLOR_LIME = "#D0F224"
COLOR_ALOE = "#4BFE85"
COLOR_JALAPENO = "#008060"
COLOR_KALE = "#054A49"
COLOR_CURRANT = "#1238BF"
COLOR_AGAVE = "#79DFFF"
COLOR_MANDARIN = "#ED6C31"
COLOR_DRAGONFRUIT = "#ED6BF8"
COLOR_BANANA = "#FCF3B0"
COLOR_WARNING = "#F0D504"
COLOR_BLACK = "#000"
COLOR_WHITE = "#FFF"

# FONTS
FONT_TOM_THUMB = "tom-thumb"
FONT_5_8 = "5x8"

# IMAGES
IMAGE_PICTURE_FRAME_BG = PICTURE_FRAME_BG_ASSET.readall()

IMAGE_TRENDS_CONTAINER = TRENDS_CONTAINER_ASSET.readall()

IMAGE_RECENT_ORDERS = RECENT_ORDERS_ASSET.readall()

IMAGE_ANIMATED_SHOPIFY_BAG = IMAGE_ANIMATED_SHOPIFY_BAG_ASSET.readall()

IMAGE_RECENT_SALES = RECENT_SALES_ASSET.readall()

TRENDS_ANIMATED_BACKGROUND = TRENDS_ANIMATED_ASSET.readall()

APP_ID = "shopify_memories"

def api_fetch(counter_id, request_config):
    cache_key = "{}/{}/{}".format(counter_id, APP_ID, base64.encode(json.encode(request_config)))
    cached_value = cache.get(cache_key)
    if cached_value != None:
        print("Hit! Displaying cached data.")
        api_response = json.decode(cached_value)
        return api_response
    else:
        print("Miss! Calling Counter API.")
        url = "{}/tidbyt/api/{}/{}".format(SHOPIFY_COUNTER_API_HOST, counter_id, APP_ID)
        rep = http.post(url, body = json.encode({"config": request_config}), headers = {"Content-Type": "application/json"})
        if rep.status_code != 200:
            print("Counter API request failed with status {}".format(rep.status_code))
            return None
        api_response = rep.json()

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(cache_key, json.encode(api_response), ttl_seconds = CACHE_TTL)
        return api_response

# Error View
# Renders an error message
# -----------------------------------------------------------------------------------------
# message: A message to display as a rendered error
# Returns: A Pixlet root element
def error_view():
    return render.Root(
        render.Stack(
            children = [
                render.Image(IMAGE_STARFIELD),
                render.Column(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        animation.Transformation(
                            child = render.Image(IMAGE_ALIEN_ERROR),
                            width = 25,
                            height = 18,
                            duration = 150,
                            direction = "alternate",
                            fill_mode = "forwards",
                            keyframes = [
                                animation.Keyframe(
                                    percentage = 0.0,
                                    transforms = [animation.Translate(0, 0)],
                                ),
                                animation.Keyframe(
                                    percentage = 0.25,
                                    transforms = [animation.Translate(0, 1)],
                                ),
                                animation.Keyframe(
                                    percentage = 0.50,
                                    transforms = [animation.Translate(0, 0)],
                                ),
                                animation.Keyframe(
                                    percentage = 0.75,
                                    transforms = [animation.Translate(0, 1)],
                                ),
                            ],
                        ),
                        render.Marquee(
                            width = 64,
                            offset_start = 64,
                            child = render.Text(content = "We hit a snag. Please check your app.", color = "#FF0"),
                        ),
                    ],
                ),
            ],
        ),
    )

def main(config):
    counter_id = config.get("counterId")
    request_config = {}
    api_response = api_fetch(counter_id, request_config)
    if not api_response:
        return error_view()

    api_data = api_response["data"]
    text_color = config.get("textColor")
    background_color = config.get("backgroundColor")
    title = api_data["title"]
    memory = api_data["memory"]
    content = api_data["content"]

    return render.Root(
        child = render.Stack(
            children = [
                render.Image(
                    src = ANIMATION_BACKGROUND,
                ),
                animation.Transformation(
                    child = render_title_frame(title, text_color),
                    duration = 0,
                    delay = 70,
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(64, 0)],
                        ),
                    ],
                ),
                animation.Transformation(
                    child = render_memory_frame(memory, text_color, background_color),
                    duration = 0,
                    delay = 100,
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(64, 0)],
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                    ],
                ),
                animation.Transformation(
                    child = render_memory_frame(content, text_color, background_color),
                    duration = 0,
                    delay = 200,
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(64, 0)],
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                    ],
                ),
            ],
        ),
    )

def render_title_frame(message, text_color):
    return render.Column(
        children = [
            render.Padding(
                child = render.WrappedText(
                    content = message,
                    width = 64,
                    font = FONT_TOM_THUMB,
                    align = "center",
                    color = text_color,
                ),
                pad = (0, 5, 0, 0),
            ),
        ],
        expanded = True,
    )

def render_memory_frame(message, text_color, background_color):
    return render.Row(
        children = [
            render.Box(
                width = 32,
                height = 32,
            ),
            render.Column(
                children = [
                    render.Box(
                        child = render.WrappedText(
                            content = message,
                            width = 32,
                            font = FONT_TOM_THUMB,
                            align = "center",
                            color = text_color,
                        ),
                        color = background_color,
                    ),
                ],
                expanded = True,
                main_align = "space_around",
            ),
        ],
        expanded = True,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "counterId",
                name = "Counter ID",
                desc = "Unique ID of the counter set up in the Counter app for Shopify",
                icon = "shopify",
            ),
            schema.Text(
                id = "textColor",
                name = "Text color",
                desc = "Color of the text used to display the information",
                icon = "palette",
                default = "#D0F224",
            ),
            schema.Text(
                id = "backgroundColor",
                name = "Background color",
                desc = "Color of the background behind the information",
                icon = "palette",
                default = "#000000",
            ),
        ],
    )
