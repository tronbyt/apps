"""
Applet: Tesla Solar
Summary: Tesla Solar Panel Monitor
Description: Energy production and consumption monitor for your Tesla solar panels.
Author: jweier & marcusb
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/dots_ltr.gif", DOTS_LTR_ASSET = "file")
load("images/dots_rtl.gif", DOTS_RTL_ASSET = "file")
load("images/grid.png", GRID_ASSET = "file")
load("images/house.png", HOUSE_ASSET = "file")
load("images/solar_panel.png", SOLAR_PANEL_ASSET = "file")
load("images/solar_panel_off.png", SOLAR_PANEL_OFF_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

DOTS_LTR = DOTS_LTR_ASSET.readall()
DOTS_RTL = DOTS_RTL_ASSET.readall()
GRID = GRID_ASSET.readall()
HOUSE = HOUSE_ASSET.readall()
SOLAR_PANEL = SOLAR_PANEL_ASSET.readall()
SOLAR_PANEL_OFF = SOLAR_PANEL_OFF_ASSET.readall()

TESLA_AUTH_URL = "https://auth.tesla.com/oauth2/v3/token"
URL = "https://owner-api.teslamotors.com/api/1/energy_sites/{}/live_status?language=en"

IMG = ""

CACHE_TTL = 25200

DUMMY_DATA = {
    "response": {
        "solar_power": 1920,
        "load_power": 799.800048828125,
        "grid_status": "Unknown",
        "grid_power": -1120.199951171875,
        "grid_services_power": 0,
        "generator_power": 0,
        "island_status": "island_status_unknown",
        "timestamp": "2023-03-17T14:46:12-04:00",
        "wall_connectors": [],
    },
}

def get_access_token(refresh_token, site_id):
    #Try to load access token from cache
    access_token_cached = cache.get(site_id)

    if access_token_cached != None:
        print("Hit! Using cached access token " + access_token_cached)
        return {"status_code": "Cached", "access_token": str(access_token_cached)}
    else:
        print("Miss! Getting new access token from Tesla API.")

        auth_rep = http.post(TESLA_AUTH_URL, json_body = {
            "grant_type": "refresh_token",
            "client_id": "ownerapi",
            "refresh_token": refresh_token,
            "scope": "openid email offline_access",
        })

        #Check the HTTP response code
        if auth_rep.status_code != 200:
            return {"status_code": str(auth_rep.status_code), "access_token": "None"}
        else:
            access_token = auth_rep.json()["access_token"]

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set(site_id, access_token, ttl_seconds = CACHE_TTL)
            return {"status_code": str(auth_rep.status_code), "access_token": str(access_token)}

def main(config):
    print("-------Starting new update-------")

    site_id = humanize.url_encode(config.str("site_id", ""))
    refresh_token = config.str("refresh_token")
    error_in_http_calls = False
    error_details = {}
    o = ""
    unit = ""

    if refresh_token and site_id:
        url = URL.format(site_id)
        print("Refresh Token: " + refresh_token)
        print("Site ID: " + site_id)
        print("Tesla Auth URL: " + TESLA_AUTH_URL)
        print("Tesla Data URL: " + url)

        #Generate a new access token from the refresh token
        access_token = get_access_token(refresh_token, site_id)

        if access_token["access_token"] == "None":
            error_details = {"error_section": "refresh_token", "error": "HTTP error " + str(access_token["status_code"])}
            error_in_http_calls = True
        else:
            rep = http.get(url, headers = {"Authorization": "Bearer " + access_token["access_token"]})
            if rep.status_code != 200:
                response_error = rep.json()
                error_details = {"error_section": "site_id", "error": "Error " + response_error["error"]}
                error_in_http_calls = True
            else:
                unit = "kW"
            data = rep.body()
            o = json.decode(data)
    else:
        print("Using Dummy Data")
        o = DUMMY_DATA
        unit = "DEMO"

    if error_in_http_calls == False:
        o = o["response"]

        points = []
        flows = []
        if o["solar_power"] > 0:
            IMG = SOLAR_PANEL
            dir = 1
        else:
            IMG = SOLAR_PANEL_OFF
            dir = 0
        points.append((IMG, o["solar_power"] / 1000))
        flows.append(dir)

        points.append((HOUSE, o["load_power"] / 1000))
        points.append((GRID, o["grid_power"] / 1000))

        if o["grid_power"] < 0:
            dir = 1
        elif o["grid_power"] > 0:
            dir = -1
        else:
            dir = 0

        flows.append(dir)

        columns = []
        for p in points:
            IMG, power = p
            columns.append(
                render.Column(
                    main_align = "space_between",
                    cross_align = "center",
                    children = [
                        render.Image(src = IMG),
                        render.Text(
                            content = format_power(power),
                            height = 8,
                            font = "tb-8",
                            color = "#ffd11a",
                        ),
                        render.Text(
                            content = unit,
                            height = 8,
                            font = "tb-8",
                            color = "#ffd11a",
                        ),
                    ],
                ),
            )
        dots = [render.Box(width = 18)]
        for dir in flows:
            if dir:
                el = render.Image(src = DOTS_LTR if dir == 1 else DOTS_RTL)
            else:
                el = render.Box(width = 10)
            dots.append(
                render.Stack(children = [render.Box(width = 21), el]),
            )
        return render.Root(
            child = render.Stack(
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        children = columns,
                    ),
                    render.Column(
                        children = [
                            render.Box(height = 8),
                            render.Row(expanded = True, children = dots),
                        ],
                    ),
                ],
            ),
        )
    else:
        error_message = "Check " + error_details["error_section"] + ". " + error_details["error"]
        return render.Root(
            child = render.Marquee(
                width = 64,
                child = render.Text(error_message),
            ),
        )

def format_power(p):
    if p:
        return humanize.float("#,###.##", p)
    else:
        return "0"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "refresh_token",
                name = "Refresh Token",
                desc = "Refresh Token for the Tesla Owner API.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "site_id",
                name = "Site ID",
                desc = "The site ID that should be monitored.",
                icon = "solarPanel",
            ),
        ],
    )
