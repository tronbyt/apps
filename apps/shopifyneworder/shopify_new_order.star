"""
Applet: Shopify New Order
Summary: Display recent orders
Description: Display recent orders for your Shopify store.
Author: Shopify
"""

load("animation.star", "animation")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/animated_shopify_bag.gif", IMAGE_ANIMATED_SHOPIFY_BAG_ASSET = "file")
load("images/image_alien_error.gif", IMAGE_ALIEN_ERROR_ASSET = "file")
load("images/image_starfield.gif", IMAGE_STARFIELD_ASSET = "file")
load("images/picture_frame_bg.gif", IMAGE_PICTURE_FRAME_BG_ASSET = "file")
load("images/recent_orders.png", RECENT_ORDERS_ASSET = "file")
load("images/recent_sales.png", RECENT_SALES_ASSET = "file")
load("images/trends_animated.gif", TRENDS_ANIMATED_ASSET = "file")
load("images/trends_container.png", TRENDS_CONTAINER_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

IMAGE_ANIMATED_SHOPIFY_BAG = IMAGE_ANIMATED_SHOPIFY_BAG_ASSET.readall()
IMAGE_ALIEN_ERROR = IMAGE_ALIEN_ERROR_ASSET.readall()
IMAGE_PICTURE_FRAME_BG = IMAGE_PICTURE_FRAME_BG_ASSET.readall()
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
IMAGE_TRENDS_CONTAINER = TRENDS_CONTAINER_ASSET.readall()

IMAGE_RECENT_ORDERS = RECENT_ORDERS_ASSET.readall()

IMAGE_RECENT_SALES = RECENT_SALES_ASSET.readall()

TRENDS_ANIMATED_BACKGROUND = TRENDS_ANIMATED_ASSET.readall()

APP_ID = "shopify_new_orders"

def api_fetch(counter_id, request_config):
    print("Calling Counter API.")
    url = "{}/tidbyt/api/{}/{}".format(SHOPIFY_COUNTER_API_HOST, counter_id, APP_ID)
    rep = http.post(url, body = json.encode({"config": request_config}), headers = {"Content-Type": "application/json"}, ttl_seconds = CACHE_TTL)
    if rep.status_code != 200:
        print("Counter API request failed with status {}".format(rep.status_code))
        return None
    api_response = rep.json()

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

HEX_DIGITS = "0123456789ABCDEF"

def int_to_hex(decimal):
    hex = ""
    i = int(decimal)
    if i == 0:
        return "00"
    for _ in range(0, 100):
        if i <= 0:
            break
        hex = HEX_DIGITS[i % 16] + hex
        i = i // 16
    if (len(hex) == 1):
        hex = "0" + hex
    return hex

def hex_to_normalized_rgb(hex):
    r = float(int(str(hex[0:2]), 16)) / 255.0
    g = float(int(str(hex[2:4]), 16)) / 255.0
    b = float(int(str(hex[4:6]), 16)) / 255.0
    return (r, g, b)

def rgb_to_hex(normalized_rgb):
    return ("{}{}{}").format(int_to_hex(normalized_rgb[0] * 255), int_to_hex(normalized_rgb[1] * 255), int_to_hex(normalized_rgb[2] * 255))

def lerp_gradient(c1, c2, steps):
    c1 = hex_to_normalized_rgb(c1)
    c2 = hex_to_normalized_rgb(c2)
    diff = (c2[0] - c1[0], c2[1] - c1[1], c2[2] - c1[2])
    return [rgb_to_hex((c1[0] + (diff[0] * (i / steps)), c1[1] + (diff[1] * (i / steps)), c1[2] + (diff[2] * (i / steps)))) for i in range(steps)]

def render_gradient(width, height, start_color, end_color):
    columns = []
    colors = lerp_gradient(start_color, end_color, width)
    for color in colors:
        columns.append(
            render.Box(
                color = "#{}".format(color),
                width = 1,
            ),
        )

    return render.Box(
        child = render.Row(
            children = columns,
        ),
        height = height,
    )

def main(config):
    counter_id = config.get("counterId")
    request_config = {}
    api_response = api_fetch(counter_id, request_config)
    if not api_response:
        return error_view()

    api_config = api_response["config"]
    api_data = api_response["data"]
    orders = api_data["orders"]
    text_color = api_config.get("textColor")
    background_color = api_config.get("backgroundColor")
    logo = api_config.get("logo", IMAGE_RECENT_ORDERS)

    return render.Root(
        delay = 100,
        child = render.Column(
            expanded = True,
            children = [
                render_header_row(logo, text_color, background_color),
                render.Box(
                    width = 64,
                    height = 1,
                    color = COLOR_WHITE,
                ),
                render.Column(
                    expanded = True,
                    children = [
                        render_marquee(orders),
                    ],
                ),
            ],
        ),
    )

def render_marquee(orders):
    order_views = []
    for order in orders:
        order_views.append(
            render.Padding(
                child = render.Text(
                    content = order["line_item_count"],
                    font = FONT_TOM_THUMB,
                    color = COLOR_WHITE,
                ),
                pad = (7, 0, 4, 0),
            ),
        )
        order_views.append(
            render.Text(
                content = order["current_total_price"],
                font = FONT_TOM_THUMB,
                color = COLOR_ALOE,
            ),
        )
    return render.Stack(
        children = [
            render.Box(
                child = render.Marquee(
                    width = 64,
                    offset_start = 8,
                    child = render.Row(
                        children = order_views,
                        expanded = True,
                    ),
                ),
                height = 10,
            ),
        ],
    )

def render_header_row(image, text_color, background_color):
    return render.Box(
        child = render.Row(
            children = [
                render.Box(
                    width = 1,
                ),
                render.Box(
                    width = 20,
                    child = render.Image(
                        src = image,
                    ),
                ),
                render.Box(
                    width = 1,
                ),
                render.WrappedText(
                    content = "new orders\nthis month",
                    font = FONT_TOM_THUMB,
                    align = "center",
                    color = text_color,
                ),
            ],
            main_align = "start",
            cross_align = "center",
            expanded = True,
        ),
        height = 22,
        color = background_color,
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
                default = "#054A49",
            ),
            schema.PhotoSelect(
                id = "logo",
                name = "Logo",
                desc = "Logo to use above the data",
                icon = "image",
            ),
        ],
    )
