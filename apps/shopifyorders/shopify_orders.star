"""
Applet: Shopify Orders
Summary: Show Shopify orders count
Description: Show your Shopify store orders count over a specific time period.
Author: Shopify
"""

load("animation.star", "animation")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/animated_shopify_bag.gif", IMAGE_ANIMATED_SHOPIFY_BAG_ASSET = "file")
load("images/image_alien_error.gif", IMAGE_ALIEN_ERROR_ASSET = "file")
load("images/picture_frame_bg.gif", IMAGE_PICTURE_FRAME_BG_ASSET = "file")
load("images/image_starfield.gif", IMAGE_STARFIELD_ASSET = "file")
load("images/recent_orders.png", IMAGE_RECENT_ORDERS_ASSET = "file")
load("images/recent_sales.png", IMAGE_RECENT_SALES_ASSET = "file")
load("images/trends_animated.gif", TRENDS_ANIMATED_ASSET = "file")
load("images/trends_container.png", IMAGE_TRENDS_CONTAINER_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

IMAGE_ANIMATED_SHOPIFY_BAG = IMAGE_ANIMATED_SHOPIFY_BAG_ASSET.readall()
IMAGE_ALIEN_ERROR = IMAGE_ALIEN_ERROR_ASSET.readall()
IMAGE_PICTURE_FRAME_BG = IMAGE_PICTURE_FRAME_BG_ASSET.readall()
IMAGE_STARFIELD = IMAGE_STARFIELD_ASSET.readall()
TRENDS_ANIMATED_BACKGROUND = TRENDS_ANIMATED_ASSET.readall()

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

IMAGE_TRENDS_CONTAINER = IMAGE_TRENDS_CONTAINER_ASSET.readall()

IMAGE_RECENT_ORDERS = IMAGE_RECENT_ORDERS_ASSET.readall()

IMAGE_RECENT_SALES = IMAGE_RECENT_SALES_ASSET.readall()

APP_ID = "shopify_orders"

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
    relative_date = config.get("relativeDate")
    request_config = {
        "relativeDate": relative_date,
        "startDate": config.get("startDate"),
        "endDate": config.get("endDate"),
    }
    api_response = api_fetch(counter_id, request_config)
    if not api_response:
        return error_view()

    api_data = api_response["data"]
    value = api_data["orders"]
    start_date = api_data.get("startDate")
    end_date = api_data.get("endDate")

    if relative_date == "last_day":
        rendered_text = render_single_label("orders last 24 hours")
    elif relative_date == "last_7_days":
        rendered_text = render_single_label("orders last 7 days")
    elif relative_date == "last_30_days":
        rendered_text = render_single_label("orders last 30 days")
    elif relative_date == "last_60_days":
        rendered_text = render_single_label("orders last 60 days")
    elif relative_date == "last_90_days":
        rendered_text = render_single_label("orders last 90 days")
    elif relative_date == "last_365_days":
        rendered_text = render_single_label("orders last 365 days")
    elif relative_date == "current_day" or relative_date == "today":
        rendered_text = render_single_label("orders today")
    elif relative_date == "week_to_date":
        rendered_text = render_single_label("orders this week")
    elif relative_date == "month_to_date":
        rendered_text = render_single_label("orders this month")
    elif relative_date == "year_to_date":
        rendered_text = render_single_label("orders this year")
    elif relative_date == "quarter_to_date":
        rendered_text = render_single_label("orders this quarter")
    else:
        rendered_text = render_double_label("{} to {}".format(start_date, end_date))

    return render.Root(
        child = render.Stack(
            children = [
                render.Image(src = IMAGE_PICTURE_FRAME_BG),
                render.Box(
                    padding = 7,
                    child = render.Column(
                        cross_align = "center",
                        children = [
                            render.WrappedText(
                                align = "center",
                                content = value,
                                color = COLOR_ALOE,
                                font = FONT_TOM_THUMB,
                            ),
                            rendered_text,
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
                content = "orders",
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

date_range_options = [
    schema.Option(
        display = "Today",
        value = "current_day",
    ),
    schema.Option(
        display = "Week to date",
        value = "week_to_date",
    ),
    schema.Option(
        display = "Month to date",
        value = "month_to_date",
    ),
    schema.Option(
        display = "Year to date",
        value = "year_to_date",
    ),
    schema.Option(
        display = "Past 24 hours",
        value = "last_day",
    ),
    schema.Option(
        display = "Past 7 days",
        value = "last_7_days",
    ),
    schema.Option(
        display = "Past 30 days",
        value = "last_30_days",
    ),
    schema.Option(
        display = "Past 90 days",
        value = "last_90_days",
    ),
    schema.Option(
        display = "Past 365 days",
        value = "last_365_days",
    ),
    schema.Option(
        display = "Custom date range",
        value = "custom",
    ),
]

def date_range_custom_options(relativeDate):
    if relativeDate == "custom":
        return [
            schema.DateTime(
                id = "startDate",
                name = "Start Date",
                desc = "Start date for the orders data",
                icon = "gear",
            ),
            schema.DateTime(
                id = "endDate",
                name = "End Date",
                desc = "End date for the orders data",
                icon = "gear",
            ),
        ]
    else:
        return []

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
            schema.Dropdown(
                id = "relativeDate",
                name = "Date",
                desc = "The date range for the orders data",
                icon = "gear",
                default = date_range_options[0].value,
                options = date_range_options,
            ),
            schema.Generated(
                id = "generated",
                source = "relativeDate",
                handler = date_range_custom_options,
            ),
        ],
    )
