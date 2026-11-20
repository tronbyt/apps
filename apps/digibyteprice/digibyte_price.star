"""
Applet: DigiByte Price
Summary: Display DigiByte Price
Description: Displays the current DigiByte price in up to four currencies, including Satoshis. Data provided by CoinGecko. Updated every 10 minutes. If you would like an additional currency supported, please let me know in the Tronbyt Discord.
Author: DigiNode Tools
Thanks: drudge, inxi, whyamihere, Amillion Air
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/dgb_icon.png", DGB_ICON_ASSET = "file")
load("images/dgb_icon@2x.png", DGB_ICON_2X_ASSET = "file")
load("images/dgb_icon_24.png", DGB_ICON_24_ASSET = "file")
load("images/dgb_icon_28.png", DGB_ICON_28_ASSET = "file")
load("images/dgb_icon_32.png", DGB_ICON_32_ASSET = "file")
load("images/dgb_icon_36.png", DGB_ICON_36_ASSET = "file")
load("images/dgb_icon_40.png", DGB_ICON_40_ASSET = "file")
load("images/sats_symbol.png", SATS_SYMBOL_ASSET = "file")
load("images/sats_symbol@2x.png", SATS_SYMBOL_2X_ASSET = "file")
load("images/sats_symbol_stale.png", SATS_SYMBOL_STALE_ASSET = "file")
load("images/sats_symbol_stale@2x.png", SATS_SYMBOL_STALE_2X_ASSET = "file")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

DGB_ICON = DGB_ICON_ASSET.readall()
DGB_ICON_2X = DGB_ICON_2X_ASSET.readall()
SATS_SYMBOL = SATS_SYMBOL_ASSET.readall()
SATS_SYMBOL_2X = SATS_SYMBOL_2X_ASSET.readall()
SATS_SYMBOL_STALE = SATS_SYMBOL_STALE_ASSET.readall()
SATS_SYMBOL_STALE_2X = SATS_SYMBOL_STALE_2X_ASSET.readall()

# Logos for square displays, largest first: (size in pixels, image)
SQUARE_ICONS = [
    (40, DGB_ICON_40_ASSET.readall()),
    (36, DGB_ICON_36_ASSET.readall()),
    (32, DGB_ICON_32_ASSET.readall()),
    (28, DGB_ICON_28_ASSET.readall()),
    (24, DGB_ICON_24_ASSET.readall()),
]

print("----------------------------------------------------------------------------------------")

DIGIBYTE_PRICE_URL = "https://api.coingecko.com/api/v3/simple/price?ids=digibyte&vs_currencies=aud%2Ccad%2Ceur%2Cgbp%2Csats%2Cusd"

# The last prices are kept for a day, and shown if CoinGecko can't be reached
PRICE_CACHE_KEY = "dgb_prices"
PRICE_CACHE_SECONDS = 86400

# If CoinGecko can't be reached and the last prices are older than this, they are shown in amber
PRICE_STALE_SECONDS = 1800
PRICE_COLOR = "#ffffff"
STALE_PRICE_COLOR = "#ffa500"

# Symbol and country code for each fiat currency
FIAT_CURRENCIES = {
    "aud": ("$", "AU"),
    "cad": ("$", "CA"),
    "eur": ("€", "EU"),
    "gbp": ("£", "UK"),
    "usd": ("$", "US"),
}

COUNTRY_COLOR = "#2962fe"

# Price fonts: (country code font, space before the country code, 2x SATS symbol)
PRICE_FONTS = {
    "terminus-16": ("tb-8", 2, True),
    "terminus-14": ("tb-8", 2, True),
    "terminus-12": ("CG-pixel-3x5-mono", 1, False),
    "tb-8": ("CG-pixel-3x5-mono", 1, False),
}

#this list contains the currently supported fiat currencies
MAIN_CURRENCY_LIST = {
    "AUD": "aud",
    "CAD": "cad",
    "EUR": "eur",
    "GBP": "gbp",
    "USD": "usd",
    "SATS": "sats",
}

#this list contains the currently supported fiat currencies, plus the None option, for when the currency won't be displayed
ALT_CURRENCY_LIST = {
    "None": "none",
    "AUD": "aud",
    "CAD": "cad",
    "EUR": "eur",
    "GBP": "gbp",
    "USD": "usd",
    "SATS": "sats",
}

# Set applet defaults
DEFAULT_MAIN_CURRENCY = "USD"
DEFAULT_SECOND_CURRENCY = "EUR"
DEFAULT_THIRD_CURRENCY = "SATS"
DEFAULT_FOURTH_CURRENCY = "None"
DEFAULT_SHOW_COUNTRY = True

def get_schema():
    main_currency_options = [
        schema.Option(display = main_currency, value = main_currency)
        for main_currency in MAIN_CURRENCY_LIST
    ]

    alt_currency_options = [
        schema.Option(display = alt_currency, value = alt_currency)
        for alt_currency in ALT_CURRENCY_LIST
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "main_currency",
                name = "Main Currency",
                desc = "Choose the main currency to display the DigiByte price in.",
                icon = "moneyBill",
                default = DEFAULT_MAIN_CURRENCY,
                options = main_currency_options,
            ),
            schema.Dropdown(
                id = "second_currency",
                name = "Second Currency",
                desc = "Choose an additional currency to display the price in.",
                icon = "moneyBill",
                default = DEFAULT_SECOND_CURRENCY,
                options = alt_currency_options,
            ),
            schema.Dropdown(
                id = "third_currency",
                name = "Third Currency",
                desc = "Choose an additional currency to display the price in.",
                icon = "moneyBill",
                default = DEFAULT_THIRD_CURRENCY,
                options = alt_currency_options,
            ),
            schema.Dropdown(
                id = "fourth_currency",
                name = "Fourth Currency",
                desc = "Choose an additional currency to display the price in.",
                icon = "moneyBill",
                default = DEFAULT_FOURTH_CURRENCY,
                options = alt_currency_options,
            ),
            schema.Toggle(
                id = "country_toggle",
                name = "Display Country",
                desc = "Toggle displaying country code. Useful when displaying two dollar currencies together (e.g. USD and AUD).",
                icon = "toggleOn",
                default = DEFAULT_SHOW_COUNTRY,
            ),
        ],
    )

def main(config):
    currencies = [
        MAIN_CURRENCY_LIST.get(config.get("main_currency"), MAIN_CURRENCY_LIST[DEFAULT_MAIN_CURRENCY]),
        ALT_CURRENCY_LIST.get(config.get("second_currency"), ALT_CURRENCY_LIST[DEFAULT_SECOND_CURRENCY]),
        ALT_CURRENCY_LIST.get(config.get("third_currency"), ALT_CURRENCY_LIST[DEFAULT_THIRD_CURRENCY]),
        ALT_CURRENCY_LIST.get(config.get("fourth_currency"), ALT_CURRENCY_LIST[DEFAULT_FOURTH_CURRENCY]),
    ]
    country_toggle = config.bool("country_toggle", DEFAULT_SHOW_COUNTRY)

    prices, stale = get_prices()
    if prices == None:
        print("Error: No price data available")
        rows = None
    else:
        rows = [price_row(currency, prices, country_toggle) for currency in currencies if currency != "none"]
        for row in rows:
            row["stale"] = stale

    width, height = canvas.size()
    if width == height:
        return render_square(rows, width, height)
    if canvas.is2x():
        return render_wide(rows, DGB_ICON_2X, 36, ["terminus-16", "terminus-14", "terminus-12"], width, height)
    return render_wide(rows, DGB_ICON, 18, ["tb-8"], width, height)

def get_prices():
    # Returns the prices, and whether they are stale: the last prices fetched, shown because CoinGecko can't be
    # reached, and older than PRICE_STALE_SECONDS
    now = time.now().unix
    res = http.get(DIGIBYTE_PRICE_URL, ttl_seconds = 600)
    if res.status_code == 200:
        prices = res.json().get("digibyte")
        if prices and prices.get("usd") != None:
            cache.set(PRICE_CACHE_KEY, json.encode({"prices": prices, "time": now}), ttl_seconds = PRICE_CACHE_SECONDS)
            return prices, False
    print("CoinGecko request failed with status %d" % res.status_code)

    # Fall back to the last prices that were fetched
    cached = cache.get(PRICE_CACHE_KEY)
    if cached != None:
        saved = json.decode(cached)
        age = now - int(saved["time"])
        print("Showing the last prices fetched, %d seconds ago" % age)
        return saved["prices"], age > PRICE_STALE_SECONDS
    return None, False

def price_row(currency, prices, country_toggle):
    # Returns the price text, the country code (or "") and whether it is the SATS price
    price = prices.get(currency)
    if price == None:
        return {"text": "?", "country": "", "sats": currency == "sats"}

    if currency == "sats":
        sats = str(int(math.round(price * 100)))
        return {"text": sats[0:-2] + "." + sats[-2:], "country": "", "sats": True}

    symbol, country = FIAT_CURRENCIES[currency]

    # Round price to nearest whole number (used to decide how many decimal places to leave)
    integer_digits = len(str(int(math.round(float(price)))))
    if integer_digits <= 2:
        text = str(int(math.round(price * 1000)))
        text = "0" * (4 - len(text)) + text
        text = text[0:-3] + "." + text[-3:]
    elif integer_digits == 3:
        text = str(int(math.round(price * 100)))
        text = text[0:-2] + "." + text[-2:]
    elif integer_digits == 4:
        text = str(int(math.round(price * 10)))
        text = text[0:-1] + "." + text[-1:]
    else:
        text = str(int(math.round(price)))
        if integer_digits >= 7:
            country_toggle = False

    return {"text": symbol + text, "country": country if country_toggle else "", "sats": False}

def font_height(font):
    return render.Text("0", font = font).size()[1]

def row_width(row, font):
    country_font, gap, big_sats = PRICE_FONTS[font]
    width = render.Text(row["text"], font = font).size()[0]
    if row["sats"]:
        width += 12 if big_sats else 6
    if row["country"]:
        width += gap + render.Text(row["country"], font = country_font).size()[0]
    return width

def fits(rows, font, max_width, max_height):
    if len(rows) * font_height(font) > max_height:
        return False
    for row in rows:
        if row_width(row, font) > max_width:
            return False
    return True

def render_row(row, font):
    country_font, gap, big_sats = PRICE_FONTS[font]
    stale = row.get("stale", False)
    color = STALE_PRICE_COLOR if stale else PRICE_COLOR
    if row["sats"]:
        if stale:
            symbol = SATS_SYMBOL_STALE_2X if big_sats else SATS_SYMBOL_STALE
        else:
            symbol = SATS_SYMBOL_2X if big_sats else SATS_SYMBOL
        return render.Row(
            cross_align = "center",
            children = [
                render.Image(src = symbol),
                render.Text(row["text"], font = font, color = color),
            ],
        )
    if row["country"]:
        return render.Row(
            cross_align = "center",
            children = [
                render.Text(row["text"], font = font, color = color),
                render.Box(width = gap, height = 1),
                render.Text(row["country"], font = country_font, color = COUNTRY_COLOR),
            ],
        )
    return render.Text(row["text"], font = font, color = color)

def render_error():
    return render.Column(
        cross_align = "center",
        children = [
            render.Text("ERROR:", font = "CG-pixel-3x5-mono", color = "#FF0000"),
            render.Text("CoinGecko", font = "CG-pixel-3x5-mono"),
            render.Text("unavailable", font = "CG-pixel-3x5-mono"),
        ],
    )

def render_wide(rows, icon, icon_size, fonts, width, height):
    # 64x32 and 128x64: the prices go in a column beside the DigiByte logo, in the largest font that fits
    if rows == None:
        prices = [render_error()]
    else:
        font = fonts[-1]
        for candidate in fonts:
            if fits(rows, candidate, width - icon_size - 4, height):
                font = candidate
                break
        prices = [render_row(row, font) for row in rows]

    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = icon),

                    # Column to hold pricing text evenly distrubuted accross 1-4 rows
                    render.Column(
                        main_align = "space_evenly",
                        expanded = True,
                        children = prices,
                    ),
                ],
            ),
        ),
    )

def render_square(rows, width, height):
    # 64x64: the DigiByte logo goes at the top in the middle, with the prices beneath it. Use the largest font
    # that leaves room for a logo, then the largest logo that fits above the prices.
    gaps = 6  # Space above the logo, between the logo and the prices, and below the prices
    if rows == None:
        font, prices, prices_height = None, render_error(), 18
    else:
        font = "tb-8"
        for candidate in PRICE_FONTS:
            text_height = len(rows) * font_height(candidate)
            if fits(rows, candidate, width, height) and height - gaps - text_height >= SQUARE_ICONS[-1][0]:
                font = candidate
                break
        prices_height = len(rows) * font_height(font)
        prices = render.Column(children = [render_row(row, font) for row in rows])

    icon = SQUARE_ICONS[-1][1]
    for size, image in SQUARE_ICONS:
        if size + prices_height + gaps <= height:
            icon = image
            break

    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [render.Image(src = icon), prices],
            ),
        ),
    )
