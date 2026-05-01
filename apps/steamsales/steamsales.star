load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Steam API Endpoints
SALES_URL = "https://partner.steam-api.com/IPartnerFinancialsService/GetDetailedSales/v001/"
WISHLIST_URL = "https://partner.steam-api.com/IPartnerFinancialsService/GetAppWishlistReporting/v001/"

def rgb_to_hex(r, g, b):
    return "#" + str("%x" % ((1 << 24) + (r << 16) + (g << 8) + b))[1:]

def get_color_intensity(val, max_val, base_color_rgb):
    """Calculates intensity and returns hex using the safe individual formatter."""
    if max_val == 0 or val == 0:
        return "#222222"

    # Ensure float math for the ratio
    intensity = float(val) / float(max_val)
    r, g, b = base_color_rgb

    # Calculate and clamp values to 0-255
    ir = int(r * intensity)
    ig = int(g * intensity)
    ib = int(b * intensity)

    return rgb_to_hex(ir, ig, ib)

def sum(lst):
    total = 0
    for num in lst:
        total += num
    return total

def make_activity_row(data, max_val, rgb):
    return render.Row(
        main_align = "center",
        children = [
            render.Box(
                width = 8,
                height = 8,
                color = get_color_intensity(v, max_val, rgb),
                # margin=render.Box(width=1, height=0)
            )
            for v in data
        ],
    )

def main(config):
    game_name = config.get("game_name", "Your Game")
    api_key = config.get("api_key")
    app_id = config.get("app_id")

    if not api_key or not app_id:
        return render.Root(
            child = render.Padding(
                pad = (1, 1, 1, 1),
                child = render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Text("bad config", color = "#ffaa00", font = "6x10"),

                        # Sales Stack
                        render.Stack(
                            children = [
                                render.Padding(pad = (3, 1, 0, 0), child = make_activity_row([], 1, (64, 196, 99))),
                                render.Box(width = 64, height = 10, child = render.Row(
                                    main_align = "center",
                                    children = [
                                        render.Text("Sales: ", color = "#fff"),
                                        render.Text(str(1), color = "#fff"),
                                    ],
                                )),
                            ],
                        ),

                        # Wishlist Stack
                        render.Stack(
                            children = [
                                render.Padding(pad = (3, 1, 0, 0), child = make_activity_row([], 1, (0, 170, 255))),
                                render.Box(width = 64, height = 10, child = render.Row(
                                    main_align = "center",
                                    children = [
                                        render.Text("Wish: ", color = "#fff"),
                                        render.Text(str(2), color = "#fff"),
                                    ],
                                )),
                            ],
                        ),
                    ],
                ),
            ),
        )

    daily_sales = []
    daily_wish = []

    # Loop 7 times to make 1 request per day
    for i in range(6, -1, -1):
        # FIX: Use string concatenation to avoid interpolation errors
        # Convert i * 24 to a string followed by "h"
        hours_ago = str(i * 24) + "h"
        target_date = (time.now() - time.parse_duration(hours_ago)).format("2006-01-02")

        # 1. Fetch Sales
        s_res = http.get(SALES_URL, params = {
            "key": api_key,
            "appid": app_id,
            "date": target_date,
            "highwatermark_id": "0",
        }, ttl_seconds = 3600)

        day_sales_sum = 0
        if s_res.status_code == 200:
            res_list = s_res.json()["response"].get("results")
            if res_list:  # Ensure it's not None
                for res in res_list:
                    day_sales_sum += res.get("gross_units_sold", 0)
        daily_sales.append(day_sales_sum)

        # 2. Fetch Wishlists
        w_res = http.get(WISHLIST_URL, params = {
            "key": api_key,
            "appid": app_id,
            "date": target_date,
        }, ttl_seconds = 3600)

        day_wish_sum = 0
        if w_res.status_code == 200:
            res_list = w_res.json()["response"]
            day_wish_sum += res_list.get("wishlist_summary", {}).get("wishlist_adds", 0)
        daily_wish.append(day_wish_sum)

    # Calculate max values (avoid division by zero)
    max_s = 0
    for s in daily_sales:
        if s > max_s:
            max_s = s
    if max_s == 0:
        max_s = 1

    max_w = 0
    for w in daily_wish:
        if w > max_w:
            max_w = w
    if max_w == 0:
        max_w = 1

    return render.Root(
        child = render.Padding(
            pad = (1, 1, 1, 1),
            child = render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text(game_name, color = "#ffaa00", font = "6x10"),

                    # Sales Stack
                    render.Stack(
                        children = [
                            render.Padding(pad = (3, 1, 0, 0), child = make_activity_row(daily_sales, max_s, (64, 196, 99))),
                            render.Box(width = 64, height = 10, child = render.Row(
                                main_align = "center",
                                children = [
                                    render.Text("Sales: ", color = "#fff"),
                                    render.Text(str(sum(daily_sales)), color = "#fff"),
                                ],
                            )),
                        ],
                    ),

                    # Wishlist Stack
                    render.Stack(
                        children = [
                            render.Padding(pad = (3, 1, 0, 0), child = make_activity_row(daily_wish, max_w, (0, 170, 255))),
                            render.Box(width = 64, height = 10, child = render.Row(
                                main_align = "center",
                                children = [
                                    render.Text("Wish: ", color = "#fff"),
                                    render.Text(str(sum(daily_wish)), color = "#fff"),
                                ],
                            )),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(id = "game_name", name = "Game Name", desc = "Game Name", icon = "gamepad"),
            schema.Text(id = "api_key", name = "API Key", desc = "Steam API Key", icon = "key"),
            schema.Text(id = "app_id", name = "App ID", desc = "Steam App ID", icon = "gamepad"),
        ],
    )
