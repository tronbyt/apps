load("http.star", "http")
load("images/pokt_icon.png", POKT_ICON_ASSET = "file")
load("render.star", "render")

POKT_ICON = POKT_ICON_ASSET.readall()

COINSTATS_PRICE_URL = "https://api.coinstats.app/public/v1/coins/pocket-network"
PNI_HEIGHT_URL = "https://supply.research.pokt.network:8192/height"

def main():
    print("calling coinstats API")
    rep = http.get(COINSTATS_PRICE_URL, ttl_seconds = 7200)
    if rep.status_code != 200:
        fail("Coinstats request failed with status %d", rep.status_code)
    price = rep.json().get("coin", {}).get("price", "0.00")

    print("calling PNI API")
    rep = http.get(PNI_HEIGHT_URL, ttl_seconds = 600)
    if rep.status_code != 200:
        fail("PNI Height request failed with status %d", rep.status_code)
    height = rep.body()

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
                            render.Text("%s" % height),
                        ],
                    ),
                ],
            ),
        ),
    )
