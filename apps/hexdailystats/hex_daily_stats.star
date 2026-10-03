"""
Applet: HEX Daily Stats
Summary: HEX Daily Stats
Description: Displays HEX price, Payout per T-Share and T-Share rate
Author: kmphua
Thanks: aschober, bretep, codeakk
"""

load("http.star", "http")
load("images/hex_icon_sm.png", HEX_ICON_SM_ASSET = "file")
load("math.star", "math")
load("render.star", "render")

HEX_ICON_SM = HEX_ICON_SM_ASSET.readall()

COINGECKO_PRICE_URL = "https://api.coingecko.com/api/v3/coins/{}?localization=false&tickers=false&community_data=false&developer_data=false"

NO_DATA = "---------- "

HEX_LIVE_DATA_URL = "https://hexdailystats.com/livedata"

def main():
    # Get coin data for selected coin from CoinGecko
    coin_data = get_json_from_cache_or_http(COINGECKO_PRICE_URL.format("hex"), ttl_seconds = 600)

    # Check for catastrophic data failure (i.e. failed to get data from CoinGecko and no cache data is available to fall back on)
    if coin_data == None:
        display_error = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Text("ERROR:", font = "CG-pixel-3x5-mono", color = "#FF0000"),
                render.Text("CoinGecko API", font = "CG-pixel-3x5-mono"),
                render.Text("unvailable", font = "CG-pixel-3x5-mono"),
            ],
        )
        print("Error: No CoinGecko data available")
        return render.Root(
            child = render.Box(
                display_error,
            ),
        )

    hex_price = str("$%f" % float(coin_data["market_data"]["current_price"]["usd"]))

    # Get HEX live data
    live_data = get_json_from_cache_or_http(HEX_LIVE_DATA_URL, ttl_seconds = 600)

    payout_per_tshare = NO_DATA
    share_rate = NO_DATA

    if live_data != None:
        # Payout
        payout = live_data.get("payoutPerTshare")
        if payout == None:
            payout = live_data.get("payoutPerTshare_Pulsechain")

        if payout != None:
            payout_per_tshare = str("%g" % float(payout))

        # Share Rate
        rate = live_data.get("tshareRateHEX")
        if rate == None:
            rate = live_data.get("tshareRateHEX_Pulsechain")

        if rate != None:
            share_rate = str(rate)

    # Setup display rows
    displayRows = []

    displayRows.append(
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Image(src = HEX_ICON_SM),
                render.Text(hex_price),
            ],
        ),
    )

    displayRows.append(
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Text("Payout"),
                render.Text(format_float_string(float(payout_per_tshare)) if payout_per_tshare != NO_DATA else NO_DATA),
            ],
        ),
    )

    displayRows.append(
        render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Text("ShRt"),
                render.Text(share_rate),
            ],
        ),
    )

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

def get_json_from_cache_or_http(url, ttl_seconds):
    print("HTTP JSON Request: {}".format(url))
    http_response = http.get(url, ttl_seconds = ttl_seconds)
    if http_response.status_code != 200:
        print("HTTP Request failed with status: {}".format(http_response.status_code))
        return None

    data = http_response.json()

    return data

def format_float_string(float_value):
    # Round price to nearest whole number (used to decide how many decimal places to leave)
    float_value_integer = str(int(math.round(float(float_value))))

    # Trim and format price
    if len(float_value_integer) <= 1:
        float_value = str(int(math.round(float_value * 1000)))
        if len(float_value) < 4:
            float_value = "0" + float_value
        if len(float_value) < 4:
            float_value = "0" + float_value
        if len(float_value) < 4:
            float_value = "0" + float_value
        if len(float_value) < 4:
            float_value = "0" + float_value
        float_value = (float_value[0:-3] + "." + float_value[-3:])
    elif len(float_value_integer) == 2:
        float_value = str(int(math.round(float_value * 1000)))
        float_value = (float_value[0:-3] + "." + float_value[-3:])
    elif len(float_value_integer) == 3:
        float_value = str(int(math.round(float_value * 100)))
        float_value = (float_value[0:-2] + "." + float_value[-2:])
    elif len(float_value_integer) == 4:
        float_value = str(int(math.round(float_value * 10)))
        float_value = (float_value[0:-1] + "." + float_value[-1:])
    elif len(float_value_integer) == 5:
        float_value = str(int(math.round(float_value)))
    elif len(float_value_integer) >= 6:
        float_value = str(int(math.round(float_value)))

    return float_value
