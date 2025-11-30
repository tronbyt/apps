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
load("render.star", "render")
load("schema.star", "schema")
load("images/default_icon_6585b711.png", DEFAULT_ICON_6585b711_ASSET = "file")
load("images/img_0d36f67a.png", IMG_0d36f67a_ASSET = "file")
load("images/img_19b40cfe.png", IMG_19b40cfe_ASSET = "file")
load("images/img_1a1c9f15.png", IMG_1a1c9f15_ASSET = "file")
load("images/img_1b9f9f55.png", IMG_1b9f9f55_ASSET = "file")
load("images/img_24800038.png", IMG_24800038_ASSET = "file")
load("images/img_285aff67.png", IMG_285aff67_ASSET = "file")
load("images/img_29625966.png", IMG_29625966_ASSET = "file")
load("images/img_3360aaf8.png", IMG_3360aaf8_ASSET = "file")
load("images/img_34bb8105.png", IMG_34bb8105_ASSET = "file")
load("images/img_377935ff.png", IMG_377935ff_ASSET = "file")
load("images/img_37bd6832.png", IMG_37bd6832_ASSET = "file")
load("images/img_3afe938c.png", IMG_3afe938c_ASSET = "file")
load("images/img_401b3fe5.png", IMG_401b3fe5_ASSET = "file")
load("images/img_49c321c0.png", IMG_49c321c0_ASSET = "file")
load("images/img_6585b711.png", IMG_6585b711_ASSET = "file")
load("images/img_69861f79.png", IMG_69861f79_ASSET = "file")
load("images/img_7793e876.png", IMG_7793e876_ASSET = "file")
load("images/img_844d879d.png", IMG_844d879d_ASSET = "file")
load("images/img_913bc7e2.png", IMG_913bc7e2_ASSET = "file")
load("images/img_b17d012d.png", IMG_b17d012d_ASSET = "file")
load("images/img_b371f2f4.png", IMG_b371f2f4_ASSET = "file")
load("images/img_b604a328.png", IMG_b604a328_ASSET = "file")
load("images/img_b98c71c2.png", IMG_b98c71c2_ASSET = "file")
load("images/img_ba22ad78.png", IMG_ba22ad78_ASSET = "file")
load("images/img_cbf9c077.png", IMG_cbf9c077_ASSET = "file")
load("images/img_d5dbbefd.png", IMG_d5dbbefd_ASSET = "file")
load("images/img_d75a9021.png", IMG_d75a9021_ASSET = "file")
load("images/img_f1a27796.png", IMG_f1a27796_ASSET = "file")
load("images/img_f1bd6389.png", IMG_f1bd6389_ASSET = "file")
load("images/img_f5797c05.png", IMG_f5797c05_ASSET = "file")

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
        schema.Option(display = "Logo - X", value = IMG_6585b711_ASSET.readall()),
        schema.Option(display = "Logo - X Verified", value = IMG_f1a27796_ASSET.readall()),
        schema.Option(display = "Logo - BlueSky", value = IMG_1b9f9f55_ASSET.readall()),
        schema.Option(display = "Logo - Instagram", value = IMG_34bb8105_ASSET.readall()),
        schema.Option(display = "Logo - YouTube", value = IMG_24800038_ASSET.readall()),
        schema.Option(display = "Logo - Ghost", value = IMG_19b40cfe_ASSET.readall()),
        schema.Option(display = "Logo - Paddle", value = IMG_7793e876_ASSET.readall()),
        schema.Option(display = "Logo - Gumroad", value = IMG_d75a9021_ASSET.readall()),
        schema.Option(display = "Logo - ChartMogul", value = IMG_401b3fe5_ASSET.readall()),
        schema.Option(display = "Logo - Twitter Bird", value = IMG_0d36f67a_ASSET.readall()),
        schema.Option(display = "Fire", value = IMG_3afe938c_ASSET.readall()),
        schema.Option(display = "Lightning", value = IMG_285aff67_ASSET.readall()),
        schema.Option(display = "Checkmark", value = IMG_b98c71c2_ASSET.readall()),
        schema.Option(display = "Lightbulb", value = IMG_49c321c0_ASSET.readall()),
        schema.Option(display = "Money", value = IMG_b371f2f4_ASSET.readall()),
        schema.Option(display = "USD", value = IMG_377935ff_ASSET.readall()),
        schema.Option(display = "Plant", value = IMG_d5dbbefd_ASSET.readall()),
        schema.Option(display = "Potted Plant", value = IMG_29625966_ASSET.readall()),
        schema.Option(display = "Bubbly", value = IMG_cbf9c077_ASSET.readall()),
        schema.Option(display = "Confetti", value = IMG_ba22ad78_ASSET.readall()),
        schema.Option(display = "Balloons", value = IMG_b604a328_ASSET.readall()),
        schema.Option(display = "Heart", value = IMG_69861f79_ASSET.readall()),
        schema.Option(display = "Storefront", value = IMG_37bd6832_ASSET.readall()),
        schema.Option(display = "Megaphone", value = IMG_f5797c05_ASSET.readall()),
        schema.Option(display = "Green Box", value = IMG_844d879d_ASSET.readall()),
        schema.Option(display = "The Letter P", value = IMG_913bc7e2_ASSET.readall()),
        schema.Option(display = "Hands - Finger Gun", value = IMG_1a1c9f15_ASSET.readall()),
        schema.Option(display = "Hands - Pray", value = IMG_b17d012d_ASSET.readall()),
        schema.Option(display = "Hands - Peace", value = IMG_3360aaf8_ASSET.readall()),
        schema.Option(display = "Hands - Shaka", value = IMG_f1bd6389_ASSET.readall()),
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
