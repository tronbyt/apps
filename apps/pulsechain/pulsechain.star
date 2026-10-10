"""
Applet: PulseChain
Summary: Price of PLS, PLSX, and HEX
Description: Display the price of PLS, PLSX, and HEX. Choose between testnet and mainnet prices. After PulseChain mainnet launch, an update will be pushed to this app to display the correct mainnet price.
Author: bretep
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("images/hex_icon_sm.png", HEX_ICON_SM_ASSET = "file")
load("images/pls_icon_sm.png", PLS_ICON_SM_ASSET = "file")
load("images/plsx_icon_sm.png", PLSX_ICON_SM_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

HEX_ICON_SM = HEX_ICON_SM_ASSET.readall()
PLSX_ICON_SM = PLSX_ICON_SM_ASSET.readall()
PLS_ICON_SM = PLS_ICON_SM_ASSET.readall()

NO_PRICE = "$  ------- "

POST_HEADERS = {
    "Content-Type": "application/json",
}

def hasData(json):
    return "data" in json

def main(config):
    PULSE_URL = config.str("pulse_url", "https://api.thegraph.com/subgraphs/name/pulsechaincom/pulsechain-main")
    PULSE_TESTNET_URL = config.str("pulse_testnet_url", "https://api.thegraph.com/subgraphs/name/pulsechaincom/pulsechain-testnet-v4")
    PULSE_QUERY = config.str("pulse_query", """{"query":"{\n  pls: bundle(id: \"1\") {\n    derivedUSD\n  }\n  plsx: token(id: \"0x07890c29ed6dcf8cc59a686b24a317924d63a923\") {\n    derivedUSD\n  }\n}","variables":null}""")
    ETH_MAINNET_URL = "https://api.thegraph.com/subgraphs/name/toihoang12/uniswapv3"
    ETH_MAINNET_HEX_QUERY_ENC = "eyJxdWVyeSI6IntcbiAgZXRoOiBidW5kbGUoaWQ6IFwiMVwiKSB7ICAgIFxuICAgIGV0aFByaWNlVVNEXG4gIGh1eDogdG9rZW4oaWQ6IFwiMHgyYjU5MWU5OWFmZTlmMzJlYWE2MjE0ZjdiNzYyOTc2OGM0MGVlYjM5XCIpIHtcbiAgICBzeW1ib2xcbiAgICBkZXJpdmVkRVRIXG4gIFxuICB9XG4gIH0iLCJ2YXJpYWJsZXMiOm51bGx9Cg=="
    ETH_MAINNET_HEX_QUERY = base64.decode(ETH_MAINNET_HEX_QUERY_ENC)

    print("Cache miss, updating price...")

    mainnetResponse = http.post(PULSE_URL, body = PULSE_QUERY, headers = POST_HEADERS, ttl_seconds = 30)
    if mainnetResponse.status_code != 200:
        fail("Mainnet request failed with status %d", mainnetResponse.status_code)

    testnetResponse = http.post(PULSE_TESTNET_URL, body = PULSE_QUERY, headers = POST_HEADERS, ttl_seconds = 30)
    if testnetResponse.status_code != 200:
        fail("Testnet request failed with status %d", testnetResponse.status_code)

    ethMainnetResponse = http.post(ETH_MAINNET_URL, body = ETH_MAINNET_HEX_QUERY, headers = POST_HEADERS, ttl_seconds = 30)
    if ethMainnetResponse.status_code != 200:
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

    if hasData(testnetResponse.json()):
        PLS_TESTNET = testnetResponse.json()["data"]["pls"]["derivedUSD"]
        PLSX_TESTNET = testnetResponse.json()["data"]["plsx"]["derivedUSD"]
        testnet_pls = str("$%f" % float(PLS_TESTNET))
        testnet_plsx = str("$%f" % float(PLSX_TESTNET))
    else:
        testnet_pls = NO_PRICE
        testnet_plsx = NO_PRICE

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
