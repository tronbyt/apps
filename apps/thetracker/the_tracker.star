"""
Applet: The Tracker
Summary: Show your internet stats
Description: Flexible counter to display your numbers via ilo.so: X, YouTube, TikTok, Bluesky, Ghost, Kit, and more!
Author: Steve Rybka
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")  # Added to parse JSON responses
load("http.star", "http")
load("humanize.star", "humanize")
load("images/default_icon_6585b711.png", DEFAULT_ICON_6585b711_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

CACHE_TTL = 300
DEFAULT_CODE = "n1bmw0og"  # Updated to a sample ilo.so counter ID
DEFAULT_COLOR = "#1DA1F2"
DEFAULT_LAYOUT = "Number"
DEFAULT_FONT = "tb-8"
DEFAULT_BANNER = "Followers"
DEFAULT_FORMAT = "Full"
DEFAULT_ICON = DEFAULT_ICON_6585b711_ASSET.readall()
DEFAULT_MULTIPLY_BY_12 = False
DEFAULT_ADD_DOLLAR_SIGN = False
DEFAULT_SHOW_COMMA = True

def render_error():
    return render.Root(
        render.WrappedText("Something went wrong!"),
    )

def main(config):
    # Load the Counter ID from the config
    code = config.str("code", DEFAULT_CODE).strip()

    # If the Counter ID is blank, show an error message
    if code == "":
        return render.Root(
            render.WrappedText(
                content = "Error: Counter ID is blank.",
            ),
        )

    # Load user settings from Tidbyt app, or grab defaults
    layout = config.str("layout", DEFAULT_LAYOUT)
    color = config.str("color", DEFAULT_COLOR)
    code = config.str("code", DEFAULT_CODE)
    banner = config.str("banner", DEFAULT_BANNER)
    font = config.str("font", DEFAULT_FONT)
    icon = base64.decode(config.get("icon", DEFAULT_ICON))
    multiply_by_12 = config.str("multiply_by_12", "false") == "true"
    add_dollar_sign = config.str("add_dollar_sign", "false") == "true"  # New toggle for dollar sign
    show_comma = config.str("show_comma", "true") == "true"  # New toggle for commas

    # Cache checker
    cache_key = code + "_multiplier_" + str(multiply_by_12) + str(add_dollar_sign) + "_comma_" + str(show_comma)  # Create a unique cache key based on multiplier
    cached_data = cache.get(cache_key)

    if cached_data != None:
        print("Cache hit!")
        body_content = cached_data
    else:
        print("Cache miss! Getting Data...")

        # Get data from ilo.so API with user's counter ID
        ILO_URL = "https://api.ilo.so/v2/counters/" + code + "/"
        response = http.get(ILO_URL)

        # Attempt to parse JSON response
        data = json.decode(response.body())

        if "count" in data:
            # Extract the count value as an integer
            count_value = int(data["count"])

            # Apply the multiplier if enabled
            if multiply_by_12:
                count_value *= 12

            # Format the count with or without commas based on the toggle
            if show_comma:
                formatted_count = humanize.comma(count_value)
            else:
                formatted_count = str(count_value)

            # Prepend the dollar sign if the toggle is enabled
            if add_dollar_sign:
                formatted_count = "$" + formatted_count

            # Use the formatted count as the body content
            body_content = formatted_count

            # Cache the result with a unique key
            cache.set(cache_key, body_content, CACHE_TTL)
        else:
            print("Error: 'count' key missing in API response")
            body_content = "Error"

    # Use the final content
    final_content = body_content

    # If user has entered a bad or empty counter ID
    if code == "" or code.strip() == "":
        final_content = "no ID"
    elif body_content == "No counter":
        final_content = "bad ID"

    print(final_content)

    # Top & bottom layout
    if layout == "Top":
        return render.Root(
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Text(
                        content = banner,
                        font = font,
                    ),
                    render.Box(
                        width = 64,
                        height = 1,
                        color = color,
                    ),
                    render.Text(
                        content = final_content,
                        font = font,
                    ),
                ],
            ),
        )
        # Side by side layout

    elif layout == "Side":
        return render.Root(
            child = render.Box(
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Image(src = icon),
                        render.Text(
                            content = final_content,
                            color = "#fff",
                            font = font,
                        ),
                    ],
                ),
            ),
        )
        # Number only layout

    elif layout == "Number":
        return render.Root(
            child = render.Box(
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Text(
                            content = final_content,
                            font = font,
                        ),
                    ],
                ),
            ),
        )
        # Fallback layout

    else:
        return render.Root(
            render.WrappedText(content = "Error: Invalid layout"),
        )

def get_schema():
    colors = [
        schema.Option(display = "Ghost White", value = "#FFFFFF"),
        schema.Option(display = "Twitter Blue", value = "#1DA1F2"),
        schema.Option(display = "Instagram Purple", value = "#833AB4"),
        schema.Option(display = "YouTube Red", value = "#FF0000"),
        schema.Option(display = "Gumroad Pink", value = "#FF90E8"),
        schema.Option(display = "Paddle Yellow", value = "#FFE450"),
        schema.Option(display = "Money Green", value = "#2E7E74"),
        schema.Option(display = "Slime Orange", value = "#FE4D00"),
    ]
    icons = [
        schema.Option(display = "Logo - X", value = LOGO_X_ASSET.readall()),
        schema.Option(display = "Logo - X Verified", value = LOGO_X_VERIFIED_ASSET.readall()),
        schema.Option(display = "Logo - BlueSky", value = LOGO_BLUESKY_ASSET.readall()),
        schema.Option(display = "Logo - Instagram", value = LOGO_INSTAGRAM_ASSET.readall()),
        schema.Option(display = "Logo - YouTube", value = LOGO_YOUTUBE_ASSET.readall()),
        schema.Option(display = "Logo - Ghost", value = LOGO_GHOST_ASSET.readall()),
        schema.Option(display = "Logo - Paddle", value = LOGO_PADDLE_ASSET.readall()),
        schema.Option(display = "Logo - Gumroad", value = LOGO_GUMROAD_ASSET.readall()),
        schema.Option(display = "Logo - ChartMogul", value = LOGO_CHARTMOGUL_ASSET.readall()),
        schema.Option(display = "Logo - Twitter Bird", value = LOGO_TWITTER_BIRD_ASSET.readall()),
        schema.Option(display = "Fire", value = FIRE_ASSET.readall()),
        schema.Option(display = "Lightning", value = LIGHTNING_ASSET.readall()),
        schema.Option(display = "Checkmark", value = CHECKMARK_ASSET.readall()),
        schema.Option(display = "Lightbulb", value = LIGHTBULB_ASSET.readall()),
        schema.Option(display = "Money", value = MONEY_ASSET.readall()),
        schema.Option(display = "USD", value = USD_ASSET.readall()),
        schema.Option(display = "Plant", value = PLANT_ASSET.readall()),
        schema.Option(display = "Potted Plant", value = POTTED_PLANT_ASSET.readall()),
        schema.Option(display = "Bubbly", value = BUBBLY_ASSET.readall()),
        schema.Option(display = "Confetti", value = CONFETTI_ASSET.readall()),
        schema.Option(display = "Balloons", value = BALLOONS_ASSET.readall()),
        schema.Option(display = "Heart", value = HEART_ASSET.readall()),
        schema.Option(display = "Storefront", value = STOREFRONT_ASSET.readall()),
        schema.Option(display = "Megaphone", value = MEGAPHONE_ASSET.readall()),
        schema.Option(display = "Green Box", value = GREEN_BOX_ASSET.readall()),
        schema.Option(display = "The Letter P", value = THE_LETTER_P_ASSET.readall()),
        schema.Option(display = "Hands - Finger Gun", value = HANDS_FINGER_GUN_ASSET.readall()),
        schema.Option(display = "Hands - Pray", value = HANDS_PRAY_ASSET.readall()),
        schema.Option(display = "Hands - Peace", value = HANDS_PEACE_ASSET.readall()),
        schema.Option(display = "Hands - Shaka", value = HANDS_SHAKA_ASSET.readall()),
    ]
    layouts = [
        schema.Option(display = "Top and Bottom (With Banner and Divider)", value = "Top"),
        schema.Option(display = "Side by Side (With Icon)", value = "Side"),
        schema.Option(display = "Number Only", value = "Number"),
    ]
    fonts = [
        schema.Option(display = "Small", value = "tom-thumb"),
        schema.Option(display = "Medium (Default)", value = "tb-8"),
        schema.Option(display = "Large", value = "Dina_r400-6"),
        schema.Option(display = "XL", value = "6x13"),
        schema.Option(display = "XXL", value = "10x20"),
        schema.Option(display = "Mono Small", value = "CG-pixel-3x5-mono"),
        schema.Option(display = "Mono Medium", value = "CG-pixel-4x5-mono"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "code",
                icon = "fingerprint",
                name = "Counter ID",
                desc = "Enter your ilo.so counter ID",
                default = DEFAULT_CODE,
            ),
            schema.Dropdown(
                id = "layout",
                icon = "grip",
                name = "Layout",
                desc = "The layout of your display",
                options = layouts,
                default = DEFAULT_LAYOUT,
            ),
            schema.Dropdown(
                id = "font",
                icon = "font",
                name = "Font",
                desc = "Font used for text and numbers",
                options = fonts,
                default = DEFAULT_FONT,
            ),
            schema.Text(
                id = "banner",
                icon = "message",
                name = "Banner",
                desc = "Text to display in banner",
                default = DEFAULT_BANNER,
            ),
            schema.Dropdown(
                id = "color",
                icon = "eyeDropper",
                name = "Divider Color",
                desc = "The color of the divider",
                options = colors,
                default = DEFAULT_COLOR,
            ),
            schema.Dropdown(
                id = "icon",
                icon = "icons",
                name = "Icon",
                desc = "The icon to display",
                options = icons,
                default = DEFAULT_ICON,
            ),
            schema.Toggle(
                id = "show_comma",
                icon = "toggleOn",
                name = "Show Comma",
                desc = "Enable commas in the number display",
                default = DEFAULT_SHOW_COMMA,
            ),
            schema.Toggle(
                id = "multiply_by_12",
                icon = "toggleOn",
                name = "Annual Multiplier",
                desc = "Multiply the counter by 12",
                default = DEFAULT_MULTIPLY_BY_12,
            ),
            schema.Toggle(
                id = "add_dollar_sign",
                icon = "toggleOn",
                name = "Add Dollar Sign",
                desc = "Add a dollar sign to the number",
                default = DEFAULT_ADD_DOLLAR_SIGN,
            ),
        ],
    )
