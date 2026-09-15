"""
Applet: SolarEdge Monitor
Summary: PV system monitor
Description: Energy production and consumption monitor for your SolarEdge solar panels.
Author: marcusb
"""

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

URL = "https://monitoringapi.solaredge.com/site/{}/currentPowerFlow"

# SolarEdge API limit is 300 requests per day, which is about
# one per 5 minutes
CACHE_TTL = 300

DUMMY_DATA = {
    "siteCurrentPowerFlow": {
        "updateRefreshRate": 3,
        "unit": "kW",
        "connections": [
            {"from": "GRID", "to": "Load"},
            {"from": "PV", "to": "Load"},
        ],
        "GRID": {"status": "Active", "currentPower": 1.57},
        "LOAD": {"status": "Active", "currentPower": 4.71},
        "PV": {"status": "Active", "currentPower": 3.14},
    },
}

def main(config):
    api_key = config.str("api_key")
    site_id = humanize.url_encode(config.str("site_id", ""))

    if api_key and site_id:
        url = URL.format(site_id)
        rep = http.get(url, params = {"api_key": api_key}, ttl_seconds = CACHE_TTL)
        if rep.status_code != 200:
            fail("SolarEdge API request failed with status {}".format(rep.status_code))
        data = rep.body()
        o = json.decode(data)
    else:
        o = DUMMY_DATA

    o = o["siteCurrentPowerFlow"]
    unit = o["unit"]
    connections = o["connections"]
    points = []
    flows = []
    if o["PV"]:
        img = SOLAR_PANEL if o["PV"]["status"] == "Active" else SOLAR_PANEL_OFF
        points.append((img, o["PV"]["currentPower"]))
        if {"from": "PV", "to": "Load"} in connections:
            dir = 1
        else:
            dir = 0
        flows.append(dir)
    if o["LOAD"]:
        points.append((HOUSE, o["LOAD"]["currentPower"]))
        if {"from": "GRID", "to": "Load"} in connections:
            dir = -1
        elif {"from": "LOAD", "to": "Grid"} in connections:
            dir = 1
        else:
            dir = 0
        flows.append(dir)
    if o["GRID"]:
        points.append((GRID, o["GRID"]["currentPower"]))
    columns = []
    for p in points:
        img, power = p
        columns.append(
            render.Column(
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Image(src = img),
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
                id = "api_key",
                name = "API key",
                desc = "API key for the SolarEdge monitoring API.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "site_id",
                name = "Site ID",
                desc = "The site ID, available from the monitoring portal.",
                icon = "solarPanel",
            ),
        ],
    )
