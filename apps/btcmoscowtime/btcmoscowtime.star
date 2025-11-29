"""
Applet: BtcMoscowTime
Summary: Shows satoshis per USD
Description: Shows how many satoshis for 1 USD.
Author: PMK (@pmk)
"""

load("http.star", "http")
load("images/background.gif", BACKGROUND_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

BACKGROUND = BACKGROUND_ASSET.readall()

DEFAULT_SHOW_MSAT = False

def get_data(ttl_seconds = 60 * 5):
    url = "https://api.coingecko.com/api/v3/simple/price?ids=tether&vs_currencies=sats"
    response = http.get(url = url, ttl_seconds = ttl_seconds)
    if response.status_code != 200:
        fail("Coingecko request failed with status %d", response.status_code)
    json = response.json()
    return json["tether"]["sats"]

def print_moscowtime(show_msat = DEFAULT_SHOW_MSAT):
    data = get_data()
    sats = str(int(data // 1))
    msat = str(int((data % 1) * 100)) if show_msat else 0

    moscowtime = [render.Text(sats)]
    if (msat != 0):
        moscowtime.append(
            render.Animation(
                children = [
                    render.Text(content = ".", color = "#fff"),
                    render.Text(content = ".", color = "#000"),
                ],
            ),
        )
        moscowtime.append(render.Text(msat))
    return moscowtime

def main(config):
    show_msat = config.bool("show_msat", DEFAULT_SHOW_MSAT)

    return render.Root(
        delay = 1000,
        child = render.Stack(
            children = [
                render.Image(
                    src = BACKGROUND,
                    width = 64,
                    height = 32,
                ),
                render.Padding(
                    pad = (3, 5, 0, 0),
                    child = render.Row(
                        children = print_moscowtime(show_msat),
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "show_msat",
                name = "Show msat",
                desc = "Show the decimal of a satoshi?",
                icon = "coins",
                default = DEFAULT_SHOW_MSAT,
            ),
        ],
    )
