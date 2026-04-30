load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Your specific Game Info
DATES_URL = "https://partner.steam-api.com/IPartnerFinancialsService/GetChangedDatesForPartner/v001/"
SALES_URL = "https://partner.steam-api.com/IPartnerFinancialsService/GetDetailedSales/v001/"
WISHLIST_URL = "https://partner.steam-api.com/IPartnerFinancialsService/GetAppWishlistReporting/v001/"

def main(config):
    salesData = []
    wishlistData = []

    today = time.now().format("2006-01-02")

    game_name = config.get("game_name", "Your Game")
    api_key = config.get("api_key")
    app_id = config.get("app_id")
    if not api_key:
        return render.Root(
            child = render.Column(
                expanded = True,
                main_align = "space_around",
                cross_align = "center",
                children = [
                    render.Text("set api key", color = "#ffaa00", font = "6x10"),
                    render.Row(
                        children = [
                            render.Text("Sales: ", color = "#fff"),
                            render.Text(str(0), color = "#00ff00"),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Text("Wishlists: ", color = "#fff"),
                            render.Text(str(0), color = "#00aaff"),
                        ],
                    ),
                ],
            ),
        )
    if not app_id:
        return render.Root(
            child = render.Column(
                expanded = True,
                main_align = "space_around",
                cross_align = "center",
                children = [
                    render.Text("set app id", color = "#ffaa00", font = "6x10"),
                    render.Row(
                        children = [
                            render.Text("Sales: ", color = "#fff"),
                            render.Text(str(0), color = "#00ff00"),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Text("Wishlists: ", color = "#fff"),
                            render.Text(str(0), color = "#00aaff"),
                        ],
                    ),
                ],
            ),
        )

    params = {
        "key": api_key,
        "appid": app_id,
        "date": today,
        "highwatermark_id": "0",
    }
    res = http.get(SALES_URL, params = params, ttl_seconds=300)
    if res.status_code == 200:
        data = res.json()["response"]
        for result in data.get("results", []):
            salesData.append(result)

    params = {
        "key": api_key,
        "appid": app_id,
        "date": today,
    }
    res = http.get(WISHLIST_URL, params = params, ttl_seconds=300)
    if res.status_code == 200:
        data = res.json()["response"]
        for result in data.get("results", []):
            wishlistData.append(result)

    sales = 0
    wishlistAdds = 0
    for sale in salesData:
        sales += sale.get("gross_units_sold", 0)
    for wishlist in wishlistData:
        wishlistAdds += wishlist.get("wishlist_summary", {}).get("wishlist_adds", 0)

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = [
                render.Text(game_name, color = "#ffaa00", font = "6x10"),
                render.Row(
                    children = [
                        render.Text("Sales: ", color = "#fff"),
                        render.Text(str(sales), color = "#00ff00"),
                    ],
                ),
                render.Row(
                    children = [
                        render.Text("Wishlists: ", color = "#fff"),
                        render.Text(str(wishlistAdds), color = "#00aaff"),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "game_name",
                name = "Game Name",
                desc = "The name of your game",
                icon = "gamepad",
            ),
            schema.Text(
                id = "api_key",
                name = "Steam Partner API Key",
                desc = "Your IPartnerFinancialsService compatible key",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "app_id",
                name = "Steam App ID",
                desc = "The App ID of your game on Steam",
                icon = "gamepad",
            ),
        ],
    )
