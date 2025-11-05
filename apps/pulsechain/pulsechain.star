"""
Applet: PulseChain
Summary: Price of PLS, PLSX, and HEX
Description: Display the price of PLS, PLSX, and HEX. Choose between testnet and mainnet prices. After PulseChain mainnet launch, an update will be pushed to this app to display the correct mainnet price.
Author: bretep
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

NO_PRICE = "$  ------- "

POST_HEADERS = {
    "Content-Type": "application/json",
}

PLS_ICON_SM = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAkAAAAICAYAAAArzdW1AAAACXBIWXMAAAWJAAAF
iQFtaJ36AAABC0lEQVQYlT3Ku07CUACA4b/0ioA9saE5MSTA4mQURyZ8CQcfwUkX
Z+oLGB/AgcfQURdXXVwcLAmBg6GxEi5p0R4HE4dv+wytNbVLokWDPrvwr8oX0NJ1
UnN8G7WqSwalFd48Y1isEayBAo8K5ajGnXX0sbmRyvalAqlI4xaMEpokQMK5kTCw
9itLEeTOQxA7HaksIRVp/JfT2QyYcWztueNeYNcJ7M1LkLkifHWQqiSk4jBW8N7m
2ewbbtszfzo7Xii3TC3KZnFfXdPzRya1uUFtwalRGNsic7tx7nT93Omysg6Gk9xp
TnKHSeZeneV2hNYaDRffZkOvyic69a/1NHzSb+E0fhSfQmvNL6VjbO/VkT3+AAAA
AElFTkSuQmCC
""")
PLSX_ICON_SM = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAJCAYAAAAPU20uAAAACXBIWXMAAAWJAAAF
iQFtaJ36AAABLklEQVQYlT3KTSiDAQAG4Hd8tljL/qSV5KeWvoxYc6CViIOQ5mYO
kiaHTbIkcpCi2VKUA2scNKJxctFSDg67TVlJS+SgNdKW2k/bvteJ69Mj2xocawEg
e9HrX/1Bfw4ADNH1zUSHeln9lmnFU21jgJBLD3XGPZIwH7hNoKcgK26nu71uORZt
kzX5clWSUBW8Q6OdlV9r9+AGG+5WnCRR5rs8+QyLptWSrCJza9cNZ3VSjyKdixqv
s/sAIADAqbk98GjS5MPjWh9QKIpXpdkb744EACAJktDGXUegi/VR56HDPqP9c5BE
W3DeCjpKQmbu46K/zxMzdB3/h4GlBUGRmo6BU7SEHBM/cjFOiNJur81KEsLzSM6c
r86GlMkqnyaiPDs3N0cs799NYiKVBoBfQPqMHBohfUwAAAAASUVORK5CYII=
""")
HEX_ICON_SM = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAkAAAAICAYAAAArzdW1AAAACXBIWXMAAAsTAAAL
EwEAmpwYAAABG0lEQVQYlQXBPUsCYQDA8f+dz6WXr3cqZlpkkSCBBI2NITSI0NTi
B2jpOzT1CRqipYjmliKiJQiioWhoiYqIuDDMzJcwz7vTp99PkZUNeJw3qNkPuIko
6hTSmwBftqPkkkV0qyUQEtTbA/yjLNok9L9QlDTSqYelld9VCoF1RVZXy1jdE37N
bZr+OF7cxUsU+AmvIGdgLr/o26qo10THTmGQR/4to7kxDO0IpzuN3Uxh2yXBgrrD
Z7uENooRDn7z0V9i4KjMpo55aRWRzpggIw7RB0XG3XuS/SbpyCvP1hpDLuj72hjB
qiCuvxHqnOM19ghEwBT7xMQZ77UyunKHkbkSjDzImpeojRZtt05v0CMyfMIMpQnl
Nrlx+AeJZmcOHgyOkAAAAABJRU5ErkJggg==
""")

def hasData(json):
    return "data" in json

def main(config):
    PULSE_URL = config.get("pulse_url")
    PULSE_TESTNET_URL = config.get("pulse_testnet_url")
    PULSE_QUERY = config.get("pulse_query")
    ETH_MAINNET_URL = "https://api.thegraph.com/subgraphs/name/toihoang12/uniswapv3"
    ETH_MAINNET_HEX_QUERY_ENC = "eyJxdWVyeSI6IntcbiAgZXRoOiBidW5kbGUoaWQ6IFwiMVwiKSB7ICAgIFxuICAgIGV0aFByaWNlVVNEXG4gIGh1eDogdG9rZW4oaWQ6IFwiMHgyYjU5MWU5OWFmZTlmMzJlYWE2MjE0ZjdiNzYyOTc2OGM0MGVlYjM5XCIpIHtcbiAgICBzeW1ib2xcbiAgICBkZXJpdmVkRVRIXG4gIFxuICB9XG4gIH0iLCJ2YXJpYWJsZXMiOm51bGx9Cg=="
    ETH_MAINNET_HEX_QUERY = base64.decode(ETH_MAINNET_HEX_QUERY_ENC)

    cached_pls = cache.get("pls_price")
    cached_plsx = cache.get("plsx_price")
    cached_eth_hex = cache.get("eth_hex_price")
    cached_testnet_pls = cache.get("pls_testnet_price")
    cached_testnet_plsx = cache.get("plsx_testnet_price")

    if cached_pls != None:
        print("Using cached data.")
        if config.bool("testnet"):
            display_pls_price = cached_testnet_pls
            display_plsx_price = cached_testnet_plsx
            display_eth_hex_price = cached_eth_hex
        else:
            display_pls_price = cached_pls
            display_plsx_price = cached_plsx
            display_eth_hex_price = cached_eth_hex
    else:
        print("Cache miss, updating price...")

        mainnetResponse = http.post(PULSE_URL, body = PULSE_QUERY, headers = POST_HEADERS)
        if mainnetResponse.status_code != 200:
            fail("Mainnet request failed with status %d", mainnetResponse.status_code)

        testnetResponse = http.post(PULSE_TESTNET_URL, body = PULSE_QUERY, headers = POST_HEADERS)
        if testnetResponse.status_code != 200:
            fail("Testnet request failed with status %d", testnetResponse.status_code)

        ethMainnetResponse = http.post(ETH_MAINNET_URL, body = ETH_MAINNET_HEX_QUERY, headers = POST_HEADERS)
        if testnetResponse.status_code != 200:
            fail("Eth Mainnet request failed with status %d", ethMainnetResponse.status_code)

        if hasData(mainnetResponse.json()):
            PLS = mainnetResponse.json()["data"]["pls"]["derivedUSD"]
            PLSX = mainnetResponse.json()["data"]["plsx"]["derivedUSD"]
            mainnet_pls = str("$%f" % float(PLS))
            mainnet_plsx = str("$%f" % float(PLSX))
        else:
            mainnet_pls = NO_PRICE
            mainnet_plsx = NO_PRICE

        if hasData(ethMainnetResponse.json()):
            ETH_HEX_DERIVED_ETH = ethMainnetResponse.json()["data"]["hex"]["derivedETH"]
            ETH_HEX_ETH_PRICE_USD = ethMainnetResponse.json()["data"]["eth"]["ethPriceUSD"]
            ETH_HEX_DERIVED_PRICE = float(ETH_HEX_DERIVED_ETH) * float(ETH_HEX_ETH_PRICE_USD)
            eth_hex = str("$%f" % ETH_HEX_DERIVED_PRICE)
        else:
            eth_hex = NO_PRICE

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("pls_price", mainnet_pls, ttl_seconds = 30)

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("plsx_price", mainnet_plsx, ttl_seconds = 30)

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("eth_hex_price", eth_hex, ttl_seconds = 30)

        PLS_TESTNET = testnetResponse.json()["data"]["pls"]["derivedUSD"]
        PLSX_TESTNET = testnetResponse.json()["data"]["plsx"]["derivedUSD"]
        testnet_pls = str("$%f" % float(PLS_TESTNET))
        testnet_plsx = str("$%f" % float(PLSX_TESTNET))

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("pls_testnet_price", testnet_pls, ttl_seconds = 30)

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("plsx_testnet_price", testnet_plsx, ttl_seconds = 30)

        if config.bool("testnet"):
            display_pls_price = testnet_pls
            display_plsx_price = testnet_plsx
            display_eth_hex_price = eth_hex
        else:
            display_pls_price = mainnet_pls
            display_plsx_price = mainnet_plsx
            display_eth_hex_price = eth_hex

    defaultDisplayRows = [
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = PLS_ICON_SM),
                render.Text(display_pls_price),
            ],
        ),
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = PLSX_ICON_SM),
                render.Text(display_plsx_price),
            ],
        ),
    ]

    displayRows = []

    if config.bool("hex"):
        displayRows.append(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = HEX_ICON_SM),
                    render.Text(display_eth_hex_price),
                ],
            ),
        )

    displayRows.extend(defaultDisplayRows)

    return render.Root(
        child = render.Stack(
            children = [
                render.Column(
                    main_align = "space_evenly",  # this controls position of children, start = top
                    expanded = True,
                    cross_align = "center",
                    children = displayRows,
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "pulse_url",
                name = "PulseChain Mainnet API URL",
                desc = "The API URL for PulseChain mainnet. Obtain this from a trusted source.",
                icon = "link",
                default = "https://api.thegraph.com/subgraphs/name/pulsechaincom/pulsechain-main",
            ),
            schema.Text(
                id = "pulse_testnet_url",
                name = "PulseChain Testnet API URL",
                desc = "The API URL for PulseChain testnet. Obtain this from a trusted source.",
                icon = "link",
                default = "https://api.thegraph.com/subgraphs/name/pulsechaincom/pulsechain-testnet-v4",
            ),
            schema.Text(
                id = "pulse_query",
                name = "PulseChain GraphQL Query",
                desc = "The GraphQL query for PulseChain data. Do not modify unless you know what you're doing.",
                icon = "code",
                default = """{"query":"{\n  pls: bundle(id: \"1\") {\n    derivedUSD\n  }\n  plsx: token(id: \"0x07890c29ed6dcf8cc59a686b24a317924d63a923\") {\n    derivedUSD\n  }\n}","variables":null}""",
            ),
            schema.Toggle(
                id = "testnet",
                name = "Testnet",
                desc = "Turn on to see testnet tickers",
                icon = "flaskVial",
                default = False,
            ),
            schema.Toggle(
                id = "hex",
                name = "Show HEX",
                desc = "Display price of HEX",
                icon = "star",
                default = True,
            ),
        ],
    )
