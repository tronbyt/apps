"""
Applet: Partnermetrics
Summary: Show Partnermetrics app data
Description: Show your Partnermetrics app data.
Author: Rishabh Tayal
"""

load("animation.star", "animation")
load("http.star", "http")
load("images/animated_shopify_bag.gif", IMAGE_ANIMATED_SHOPIFY_BAG_ASSET = "file")
load("images/image_alien_error.gif", IMAGE_ALIEN_ERROR_ASSET = "file")
load("images/image_starfield.gif", IMAGE_STARFIELD_ASSET = "file")
load("images/picture_frame_bg.gif", IMAGE_PICTURE_FRAME_BG_ASSET = "file")
load("images/recent_orders.png", RECENT_ORDERS_ASSET = "file")
load("images/trends_animated.gif", TRENDS_ANIMATED_ASSET = "file")
load("images/trends_container.png", TRENDS_CONTAINER_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

IMAGE_ANIMATED_SHOPIFY_BAG = IMAGE_ANIMATED_SHOPIFY_BAG_ASSET.readall()
IMAGE_ALIEN_ERROR = IMAGE_ALIEN_ERROR_ASSET.readall()
IMAGE_PICTURE_FRAME_BG = IMAGE_PICTURE_FRAME_BG_ASSET.readall()
IMAGE_STARFIELD = IMAGE_STARFIELD_ASSET.readall()

# CONFIG
SHOPIFY_COUNTER_API_HOST = "https://www.partnermetrics.io/chart_data?chart_type%5Bcalculation%5D=sum&chart_type%5Bcolumn%5D=revenue&chart_type%5Bdirection_good%5D=up&chart_type%5Bdisplay%5D=currency&chart_type%5Bmetric_type%5D=recurring_revenue&chart_type%5Btitle%5D=Revenue&chart_type%5Btype%5D=recurring_revenue&date="

CACHE_TTL = 3600  # 1 hour

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

TRENDS_ANIMATED_BACKGROUND = TRENDS_ANIMATED_ASSET.readall()

APP_ID = "shopify_sales"

def api_fetch(partnermetricsCookie, request_config):
    now = request_config["now"]
    print("Calling Counter API.")
    url = "{}{}&period=30".format(SHOPIFY_COUNTER_API_HOST, now)
    rep = http.get(url, headers = {"Cookie": "_PartnerMetrics_session={}".format(partnermetricsCookie)}, ttl_seconds = CACHE_TTL)
    if rep.status_code != 200:
        print("Counter API request failed with status {}".format(rep))
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
    partnermetricsCookie = config.get("partnermetricsCookie")
    timezone = time.tz()
    now = time.now().in_location(timezone)
    date = "{}-0{}-0{}".format(now.year, now.month, now.day - 1)
    request_config = {
        "now": date,
    }
    api_response = api_fetch(partnermetricsCookie, request_config)
    if not api_response:
        return error_view()
    print("API response: {}".format(api_response))
    api_data = api_response[date]
    value = api_data

    return render.Root(
        child = render.Stack(
            children = [
                render.Image(src = IMAGE_PICTURE_FRAME_BG),
                render.Box(
                    padding = 7,
                    child = render.Column(
                        cross_align = "center",
                        children = [
                            render_single_label("TrustReviews"),
                            render.WrappedText(
                                align = "center",
                                content = "$" + value,
                                color = COLOR_ALOE,
                                font = FONT_TOM_THUMB,
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def render_single_label(label):
    return render.WrappedText(
        align = "center",
        content = label,
        font = FONT_TOM_THUMB,
    )

def render_double_label(label):
    return render.Column(
        cross_align = "center",
        children = [
            render.Text(
                content = "sales",
                font = FONT_TOM_THUMB,
            ),
            render.Marquee(
                child = render.Row(
                    children = [
                        render.Text(
                            content = label,
                            font = FONT_TOM_THUMB,
                        ),
                        render.Box(
                            width = 15,
                        ),
                        render.Text(
                            content = label,
                            font = FONT_TOM_THUMB,
                        ),
                        render.Box(
                            width = 15,
                        ),
                        render.Text(
                            content = label,
                            font = FONT_TOM_THUMB,
                        ),
                        render.Box(
                            width = 15,
                        ),
                        render.Text(
                            content = label,
                            font = FONT_TOM_THUMB,
                        ),
                    ],
                ),
                offset_start = 15,
                width = 50,
            ),
        ],
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "partnermetricsCookie",
                name = "PartnerMetrics.io cookie",
                desc = "Cookie from PartnerMetrics.io",
                icon = "shopify",
                secret = True,
            ),
        ],
    )
