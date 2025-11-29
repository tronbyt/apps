"""
Applet: Stock Value
Summary: Portfolio value
Description: This app will allow you track the value of your portfolio for a single stock.
Author: gshipley
"""

load("cache.star", "cache")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/dollar_icon.png", DOLLAR_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

DOLLAR_ICON = DOLLAR_ICON_ASSET.readall()

STOCK_PRICE_URL = "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol="
DEFAULT_SHARES = 1
DEFAULT_SYMBOL = "IBM"

def main(config):
    price_cached = cache.get("price")

    if price_cached != None:
        price = float(price_cached)
    else:
        rep = http.get(STOCK_PRICE_URL + config.str("symbol", DEFAULT_SYMBOL) + "&apikey=" + config.str("alphavantage", "demo"))

        if rep.status_code != 200:
            fail("Request failed with status %d", rep.status_code)
        price = rep.json()["Global Quote"]["05. price"]

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("price", str(float(price)), ttl_seconds = 43200)

    value = (float(price) * int(config.str("shares", DEFAULT_SHARES)))
    total = humanize.float("#,###.", value)

    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = DOLLAR_ICON),
                    render.Text(total),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "symbol",
                name = "Symbol?",
                desc = "What stock symbol to track?",
                icon = "chartLine",
            ),
            schema.Text(
                id = "shares",
                name = "Number of shares",
                desc = "How many shares do you have?",
                icon = "hashtag",
            ),
            schema.Text(
                id = "alphavantage",
                name = "API KEY",
                desc = "API key for Alpha Vantage (https://www.alphavantage.co)",
                icon = "key",
                secret = True,
            ),
        ],
    )
