"""
Applet: Culver's
Summary: Today's Culver's flavor
Description: Get today's flavor at Culver's Frozen Custard.
Author: Josiah Winslow
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/image_placeholder.gif", IMAGE_PLACEHOLDER_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

IMAGE_PLACEHOLDER = IMAGE_PLACEHOLDER_ASSET.readall()

WIDTH = 64
HEIGHT = 32
DELAY = 35
TTL_SECONDS = 60 * 30  # 30 minutes

WHITE = "#ffffff"
CULVERS_BLUE = "#005696"
LIGHT_BLUE = "#7fb5d0"

NAME_HEIGHT = 6
FLAVOR_HEIGHT = HEIGHT - 6
FLAVOR_TARGET_WIDTH = 42
IMAGE_HEIGHT = 40
IMAGE_PAD = (-8, -1, 0, 0)
FONTS = ["10x20", "6x10-rounded", "tb-8", "tom-thumb"]

# Default location is "Culver's of Sauk City, WI - Phillips Blvd"
DEFAULT_RESTAURANT_LOCATION = "-89.729866027832,43.2706871032715"
DEFAULT_BG_COLOR = WHITE

def get_image(url):
    rep = http.get(url, ttl_seconds = TTL_SECONDS)
    if rep.status_code != 200:
        return None

    return rep.body()

def get_flavor_info(restaurant_location):
    # HACK The Culver's locator API also returns the flavor of the day
    # at each Culver's location it returns. We can therefore feed the
    # lat/long of the Culver's location back into this API to get the
    # flavor of the day at that location.
    # REVIEW This code doesn't validate that we have the correct
    # restaurant; should it? Each restaurant has a unique "slug" (i.e.
    # ID), and an earlier version of this app used to save it instead of
    # the lat/long.
    lng, lat = restaurant_location.split(",")
    rep = http.get(
        (
            "https://culvers.com/api/locator/getLocations?lat=%s&long=%s&" +
            "radius=100&limit=1"
        ) % (lat, lng),
        ttl_seconds = TTL_SECONDS,
    )
    if rep.status_code != 200:
        return {
            "error": "Culver's status code: %s" % rep.status_code,
        }
    j = rep.json()

    # Check whether restaurant exists
    restaurants = j["data"]["geofences"]
    if not restaurants:
        return {
            "error": "Restaurant not found",
        }

    restaurant = restaurants[0]
    restaurant_name = "Culver's of " + restaurant["description"]

    # Check whether flavor exists
    # REVIEW The only time I've seen a blank flavor name is with a store
    # that's "coming soon".
    fotd_name = restaurant["metadata"]["flavorOfDayName"]
    if not fotd_name:
        return {
            "error": "Flavor not found",
        }

    fotd_image = "https://cdn.culvers.com/menu-item-detail/%s?h=%d" % (
        restaurant["metadata"]["flavorOfDaySlug"],
        IMAGE_HEIGHT,
    )

    return {
        "restaurant": restaurant_name,
        "flavor": fotd_name,
        "image": fotd_image,
    }

def render_shrink_wrapped_text(
        content,
        font = "tb-8",
        width = 0,
        height = 0,
        linespacing = 0,
        color = "#ffffff",
        align = "left"):
    # The text width should be at least as wide as the widest word
    min_width = max([
        render.Text(content = word, font = font).size()[0]
        for word in content.split()
    ])

    # Use min width if width is uninitialized
    if width <= 0:
        width = min_width

    # Clamp the text width in between the calculated minimum and the
    # device's maximum
    width = min(max(width, min_width), WIDTH)

    return render.WrappedText(
        content = content,
        font = font,
        width = width,
        height = height,
        linespacing = linespacing,
        color = color,
        align = align,
    )

def get_wrapped_text_height(wrapped_text):
    content = wrapped_text.content
    font = wrapped_text.font
    width = wrapped_text.width
    linespacing = wrapped_text.linespacing

    # Set initial height to height of one line
    height = render.Text(content = "", font = font).size()[1]
    if width <= 0:
        return height

    words = []

    # For each word in the text
    for word in content.split():
        # Add that word to this line and render it
        words.append(word)
        line = " ".join(words)
        rendered_line = render.Text(content = line, font = font)
        line_width, line_height = rendered_line.size()

        # If the line is longer than the allowed width
        if line_width > width:
            # Move this word to the next line
            words = [word]
            height += linespacing + line_height

    return height

def main(config):
    if "restaurant_location" in config:
        restaurant_location = json.decode(
            config["restaurant_location"],
        )["value"]
    else:
        restaurant_location = DEFAULT_RESTAURANT_LOCATION

    bg_color = config.get("bg_color", DEFAULT_BG_COLOR)

    flavor_info = get_flavor_info(restaurant_location)

    if "error" in flavor_info:
        # Render "ERROR" with scrolling error message
        return render.Root(
            delay = DELAY,
            child = render.Box(
                color = bg_color,
                child = render.Column(
                    cross_align = "center",
                    children = [
                        render.Text(
                            content = "ERROR",
                            font = "tb-8",
                            color = CULVERS_BLUE,
                        ),
                        render.Marquee(
                            width = WIDTH,
                            align = "center",
                            delay = 20,
                            child = render.Text(
                                content = flavor_info["error"],
                                font = "tom-thumb",
                                color = CULVERS_BLUE,
                            ),
                        ),
                    ],
                ),
            ),
        )

    # Try rendering flavor text in each font in order of decreasing size
    flavor_texts = [
        render_shrink_wrapped_text(
            content = flavor_info["flavor"],
            font = font,
            width = FLAVOR_TARGET_WIDTH,
            color = CULVERS_BLUE,
            align = "center",
        )
        for font in FONTS
    ]

    # Find the first flavor text that fits within the desired space
    # (falling back to the smallest one if none fit)
    flavor_text = flavor_texts[-1]
    for flavor_text in flavor_texts:
        if (
            flavor_text.width <= FLAVOR_TARGET_WIDTH and
            get_wrapped_text_height(flavor_text) <= FLAVOR_HEIGHT
        ):
            break

    flavor_image = get_image(flavor_info["image"]) or IMAGE_PLACEHOLDER

    return render.Root(
        delay = DELAY,
        child = render.Stack(
            children = [
                # Background
                render.Box(color = bg_color),
                # Flavor of the day image
                render.Padding(
                    pad = IMAGE_PAD,
                    child = render.Image(
                        src = flavor_image,
                        height = IMAGE_HEIGHT,
                    ),
                ),
                # Restaurant name
                render.Marquee(
                    width = WIDTH,
                    child = render.Text(
                        content = flavor_info["restaurant"],
                        font = "tom-thumb",
                        color = CULVERS_BLUE,
                        height = NAME_HEIGHT,
                    ),
                ),
                # Flavor of the day name
                render.Padding(
                    pad = (WIDTH - flavor_text.width, 6, 0, 0),
                    child = render.Marquee(
                        width = flavor_text.width,
                        height = FLAVOR_HEIGHT,
                        scroll_direction = "vertical",
                        align = "center",
                        delay = 40,
                        child = flavor_text,
                    ),
                ),
            ],
        ),
    )

def get_restaurants(location):
    loc = json.decode(location)

    # Search for all Culver's restaurants within 40,233 m (25 mi)
    rep = http.get(
        (
            "https://culvers.com/api/locator/getLocations?lat=%s&long=%s&" +
            "radius=40233&limit=10"
        ) % (loc["lat"], loc["lng"]),
        ttl_seconds = TTL_SECONDS,
    )
    if rep.status_code != 200:
        return []
    j = rep.json()

    return [
        schema.Option(
            display = restaurant["description"],
            value = ",".join([
                str(v)
                for v in restaurant["geometryCenter"]["coordinates"]
            ]),
        )
        for restaurant in j["data"]["geofences"]
    ]

def get_schema():
    options_bg_color = [
        schema.Option(
            display = "White",
            value = WHITE,
        ),
        schema.Option(
            display = "Light blue",
            value = LIGHT_BLUE,
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "restaurant_location",
                name = "Culver's location",
                desc = "The location of the Culver's restaurant.",
                icon = "iceCream",
                handler = get_restaurants,
            ),
            schema.Dropdown(
                id = "bg_color",
                name = "Background color",
                desc = "The color of the background.",
                icon = "brush",
                default = options_bg_color[0].value,
                options = options_bg_color,
            ),
        ],
    )
