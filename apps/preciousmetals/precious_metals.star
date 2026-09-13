"""
Applet: Precious Metals
Summary: Quotes on precious metals
Description: Quotes for gold, platinum and silver.
Author: threeio
"""

load("http.star", "http")
load("images/image.png", IMAGE_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

IMAGE = IMAGE_ASSET.readall()

#METALS_PRICE_URL = "https://api.metals.live/v1/spot"
METALS_PRICE_URL = "https://data-asg.goldprice.org/dbXRates/USD"

def main():
    rep = http.get(METALS_PRICE_URL, ttl_seconds = 300)  # 5 minutes cache.
    if rep.status_code != 200:
        fail("data-asg.goldprice.org/dbXRates/USD request failed with status %d", rep.status_code)

    print(rep.json())
    gold = rep.json()["items"][0]["xauPrice"]
    silver = rep.json()["items"][0]["xagPrice"]
    #platinum = rep.json()[2]["platinum"]

    return render.Root(
        child = render.Box(
            color = "#0b0e28",
            child = render.Row(
                children = [
                    render.Box(
                        width = 14,
                        child = render.Image(src = IMAGE),
                    ),
                    render.Column(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(height = 10, color = "#C0C0C0", font = "tom-thumb", content = "Ag %s" % silver),
                            render.Text(height = 10, color = "#FFD700", font = "tom-thumb", content = "Au %s" % gold),
                            #render.Text(height = 10, color = "#E5E4E2", font = "tom-thumb", content = "Pt %s" % platinum),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
