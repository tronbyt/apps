"""
Applet: Coinbase
Summary: Coinbase Balance Tracker
Description: Displays your current Coinbase holdings and balances.
Author: harrywynn
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/coinbase_logo.png", COINBASE_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

COINBASE_LOGO = COINBASE_LOGO_ASSET.readall()

COINBASE_CLIENT_SECRET = secret.decrypt("AV6+xWcEIOP/Rql2nyueyFjL9f51E2W1wDvcqtKyvXWRuSZwf7pNagbGLNridKAHG4Nw4oW2FZssbHNfsGwWAmSqXG3VN8oSvw0UY+4AB2LU3HMl5eEN9A139V08wU3/vOX7ouCUtHWwNkhHRngkQHqQiZSTK0KNOYTaIO9aeb7uzFwLdMdATDEQ2ypUjrvOt4l8UM1HIpXaIjn8T5bE+q7AYgaLww==")
COINBASE_CLIENT_ID = secret.decrypt("AV6+xWcEVIfI5lKs4wUCRh+CyWiA2VJ8Jngv8g/klexY7x7qR4KGIopsbZOIq/syABtfSToDA/nx5J8Mhy+XakIUjxESmr3V9fKOeymlJd7G/0VImVbAJYoZoTU2PMgzHcr7+HUV3SVUGrmZk62eMH5y77pWPb6MXIeLXAwTYFL6ZBk3NQCkP6EIN0dOP9h+ubvvBWMLE1U3Imc9ZdqxC4XPEQmPPg==")

def main(config):
    if config.get("token") == None:
        return render.Root(
            child = render.Text("Please login"),
        )

    AUTH_TOKEN = config.get("token")

    # load exchange rates
    # get current exchange rates
    res = http.get("https://api.coinbase.com/v2/exchange-rates", ttl_seconds = 900)

    if res.status_code != 200:
        return render.Root(
            child = render.Text("Rates unavailable!"),
        )
    else:
        # cache for 15 minutes
        rates = res.json()["data"]["rates"]

    # load account balances
    res = http.get("https://coinbase.com/api/v3/brokerage/accounts?limit=250", headers = {
        "Authorization": "Bearer " + AUTH_TOKEN,
    }, ttl_seconds = 900)

    if res.status_code != 200:
        return render.Root(
            child = render.Text("Accounts unavailable!"),
        )
    else:
        # cache for 15 minutes
        accounts = res.json()["accounts"]

    if accounts == None:
        return render.Root(
            child = render.Text("Accounts unavailable!"),
        )

    # for display
    currencies = []
    balance = 0.0

    # match account balances to rates
    for x in accounts:
        available = float(x["available_balance"]["value"])

        # only count if we have a balance
        if available > 0.0:
            balance += float(x["available_balance"]["value"]) // float(rates[x["currency"]])
            currencies.append(x["currency"])

    return render.Root(
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.Row(
                    main_align = "space_evenly",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Padding(
                            pad = (0, 2, 0, 3),
                            child = render.Text(
                                content = ("$" + humanize.ftoa(num = balance, digits = 2)),
                                font = "6x13",
                            ),
                        ),
                    ],
                ),
                render.Row(
                    main_align = "space_evenly",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Image(src = COINBASE_LOGO, width = 9),
                        render.Padding(
                            pad = (0, 2, 0, 0),
                            child = render.Marquee(
                                width = 52,
                                align = "center",
                                child = render.Text(
                                    content = " | ".join(currencies),
                                    font = "tom-thumb",
                                ),
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def oauth_handler(params):
    params = json.decode(params)

    params["client_secret"] = COINBASE_CLIENT_SECRET or "fake-client-secret"

    res = http.post("https://api.coinbase.com/oauth/token", params = params)

    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" % (res.status_code, res.body()))

    return res.json()["access_token"]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "token",
                name = "Coinbase Account",
                desc = "",
                icon = "",
                handler = oauth_handler,
                client_id = COINBASE_CLIENT_ID or "fake-client-id",
                authorization_endpoint = "https://www.coinbase.com/oauth/authorize",
                scopes = [
                    "wallet:accounts:read",
                ],
            ),
        ],
    )
