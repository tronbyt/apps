"""
Applet: WoW Token
Summary: Display WoW Token Price
Description: Displays the current price of the World of Warcraft token in various regions. Data provided by wowtoken.app.
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("images/gold_icon.jpg", GOLD_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

GOLD_ICON = GOLD_ICON_ASSET.readall()

print("----------------------------------------------------------------------------------------")

WOW_TOKEN_URL = "https://data.wowtoken.app/v2/current/retail.json"
REGION_LIST = ["us", "eu", "kr", "tw"]

def get_schema():
    region_options = [
        schema.Option(display = region, value = region)
        for region in REGION_LIST
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "region",
                name = "Region",
                desc = "Choose the World of Warcraft region.",
                icon = "moneyBill",
                default = "us",
                options = region_options,
            ),
        ],
    )

def main(config):
    region = config.get("region", "us")

    print("Cache miss")

    query = http.get(WOW_TOKEN_URL, ttl_seconds = 600)
    if query.status_code != 200:
        fail("API request failed with status %d", query.status_code)
    else:
        token_price = float(query.json()[region][1])
        print("Got price " + str(token_price))
        data_available = True

    display = []

    if data_available:
        display.append(render.Row(
            children = [
                render.Text("{}".format(humanize.comma(token_price))),
            ],
        ))

    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = GOLD_ICON),
                    render.Column(
                        main_align = "space_evenly",
                        expanded = True,
                        children = display,
                    ),
                ],
            ),
        ),
    )
