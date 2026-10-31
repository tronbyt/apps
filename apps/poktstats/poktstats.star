load("http.star", "http")
load("humanize.star", "humanize")
load("images/pokt_icon.png", POKT_ICON_ASSET = "file")
load("render.star", "render")

POKT_ICON = POKT_ICON_ASSET.readall()

# The price is from CoinGecko (free, no key). Pocket Network moved to its Shannon chain in 2025, so the block height
# comes from Polkachu's public Shannon RPC node; the old PNI height endpoint and CoinStats' public API have gone.
PRICE_URL = "https://api.coingecko.com/api/v3/simple/price?ids=pocket-network&vs_currencies=usd"
HEIGHT_URL = "https://pocket-rpc.polkachu.com/status"

def get_price():
    rep = http.get(PRICE_URL, ttl_seconds = 1800)
    if rep.status_code != 200:
        print("CoinGecko request failed with status %d" % rep.status_code)
        return None
    price = rep.json().get("pocket-network", {}).get("usd")
    return humanize.float("#.####", price) if price != None else None

def get_height():
    rep = http.get(HEIGHT_URL, ttl_seconds = 600)
    if rep.status_code != 200:
        print("Pocket Network RPC request failed with status %d" % rep.status_code)
        return None
    return rep.json().get("result", {}).get("sync_info", {}).get("latest_block_height")

def main():
    price = get_price()
    height = get_height()
    if price == None and height == None:
        return []
    price = price or "--"
    height = height or "--"

    return render.Root(
        child = render.Box(
            # This Box exists to provide vertical centering
            render.Row(
                expanded = True,  # Use as much horizontal space as possible
                main_align = "space_evenly",  # Controls horizontal alignment
                cross_align = "center",  # Controls vertical alignment
                children = [
                    render.Padding(
                        # Pad a LR border around the POKT logo
                        pad = (5, 0, 5, 0),
                        child = render.Image(src = POKT_ICON),
                    ),
                    render.Column(
                        # Arrange price above height beside the logo
                        main_align = "space_evenly",  # Controls horizontal alignment
                        cross_align = "start",  # Controls vertical alignment
                        children = [
                            render.Text(content = "POKT", font = "Dina_r400-6"),
                            render.Text("$%s" % price),
                            render.Text(height),
                        ],
                    ),
                ],
            ),
        ),
    )
