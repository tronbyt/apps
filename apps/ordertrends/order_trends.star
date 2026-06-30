"""
Applet: Order Trends
Summary: Show trending order counts
Description: Show daily, weekly, monthly and/or yearly order counts.
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
load("images/trends_animated_background.gif", TRENDS_ANIMATED_BACKGROUND_ASSET = "file")
load("images/trends_container.png", TRENDS_CONTAINER_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

IMAGE_ALIEN_ERROR = IMAGE_ALIEN_ERROR_ASSET.readall()
IMAGE_STARFIELD = IMAGE_STARFIELD_ASSET.readall()
TRENDS_ANIMATED_BACKGROUND = TRENDS_ANIMATED_BACKGROUND_ASSET.readall()

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
IMAGE_PICTURE_FRAME_BG = IMAGE_PICTURE_FRAME_BG_ASSET.readall()
IMAGE_TRENDS_CONTAINER = TRENDS_CONTAINER_ASSET.readall()

IMAGE_RECENT_ORDERS = RECENT_ORDERS_ASSET.readall()

IMAGE_ANIMATED_SHOPIFY_BAG = IMAGE_ANIMATED_SHOPIFY_BAG_ASSET.readall()
IMAGE_RECENT_SALES = RECENT_SALES_ASSET.readall()

APP_ID = "shopify_order_trends"

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

def main(config):
    counter_id = config.get("counterId")
    request_config = {
    }
    api_response = api_fetch(counter_id, request_config)
    if not api_response:
        return error_view()

    api_data = api_response["data"]
    daily = api_data["daily"]
    weekly = api_data["weekly"]
    monthly = api_data["monthly"]
    yearly = api_data["yearly"]

    return render.Root(
        child = render.Stack(
            children = [
                render.Image(TRENDS_ANIMATED_BACKGROUND),
                animation.Transformation(
                    child = render_order_count_for_period(daily, "daily"),
                    duration = 0,
                    delay = 0,
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
                    child = render_order_count_for_period(weekly, "weekly"),
                    duration = 0,
                    delay = 75,
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
                    child = render_order_count_for_period(monthly, "monthly"),
                    duration = 0,
                    delay = 150,
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
                    child = render_order_count_for_period(yearly, "yearly"),
                    duration = 0,
                    delay = 225,
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

def period_label(period):
    if period == "daily":
        return "DAILY"
    if period == "weekly":
        return "WEEKLY"
    if period == "monthly":
        return "MONTHLY"
    if period == "yearly":
        return "YEARLY"
    return "DAILY"

def period_color(period):
    if period == "daily":
        return COLOR_DRAGONFRUIT
    if period == "weekly":
        return COLOR_ALOE
    if period == "monthly":
        return COLOR_LIME
    if period == "yearly":
        return COLOR_AGAVE
    return COLOR_DRAGONFRUIT

def render_order_count_for_period(orders, period):
    color = period_color(period)
    label = period_label(period)

    return render.Column(
        children = [
            render_header(label, color),
            render_separator(color),
            render_content(orders, color),
        ],
    )

def render_header(label, color):
    return render.Box(
        width = 64,
        height = 10,
        child = render.Box(
            padding = 2,
            child = render.Padding(
                pad = (10, 0, 10, 0),
                child = render.Box(
                    color = "#000",
                    child = render.Text(
                        content = label,
                        font = FONT_5_8,
                        color = color,
                    ),
                ),
            ),
        ),
    )

def render_separator(color):
    return render.Box(
        width = 64,
        height = 1,
        color = color,
    )

def render_content(orders, color):
    return render.Box(
        width = 64,
        padding = 2,
        color = COLOR_KALE,
        child = render.Column(
            children = [
                render.Text(
                    content = orders,
                    font = FONT_5_8,
                    color = color,
                ),
                render.Box(
                    height = 1,
                ),
                render.Text(
                    content = "orders",
                    font = FONT_5_8,
                ),
            ],
            main_align = "center",
            cross_align = "center",
        ),
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
        ],
    )
