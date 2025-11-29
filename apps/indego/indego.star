"""
Applet: Indego
Summary: Indego bike share
Description: Shows available bikes and docks at an Indego station.
Author: radiocolin
"""

load("http.star", "http")
load("images/bike_dock.png", BIKE_DOCK_ASSET = "file")
load("images/bike_dock_gray.png", BIKE_DOCK_GRAY_ASSET = "file")
load("images/electric_bike.png", ELECTRIC_BIKE_ASSET = "file")
load("images/electric_bike_gray.png", ELECTRIC_BIKE_GRAY_ASSET = "file")
load("images/regular_bike.png", REGULAR_BIKE_ASSET = "file")
load("images/regular_bike_gray.png", REGULAR_BIKE_GRAY_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

BIKE_DOCK = BIKE_DOCK_ASSET.readall()
BIKE_DOCK_GRAY = BIKE_DOCK_GRAY_ASSET.readall()
ELECTRIC_BIKE = ELECTRIC_BIKE_ASSET.readall()
ELECTRIC_BIKE_GRAY = ELECTRIC_BIKE_GRAY_ASSET.readall()
REGULAR_BIKE = REGULAR_BIKE_ASSET.readall()
REGULAR_BIKE_GRAY = REGULAR_BIKE_GRAY_ASSET.readall()

indego_api_endpoint = "https://bts-status.bicycletransit.workers.dev/phl"
indego_green = "#93D500"
indego_blue = "#0082CA"
white = "#fff"
default_dock = "3162.0"

def get_indego_data():
    r = http.get(indego_api_endpoint, ttl_seconds = 600)
    if r.status_code != 200:
        fail("GET %s failed with status %d: %s", r.status_code, r.body())
    return r.json()

def populate_schema():
    data = get_indego_data()
    sorted_features = sorted(data["features"], key = lambda f: f["properties"]["name"])
    result = []
    for feature in sorted_features:
        properties = feature["properties"]
        formatted_feature = schema.Option(display = properties["name"], value = str(properties["id"]))
        result.append(formatted_feature)
    return result

def get_dock_info(selected_dock):
    data = get_indego_data()
    r = {}
    for dock in data["features"]:
        if str(dock["properties"]["id"]) == selected_dock:
            r["name"] = dock["properties"]["name"]
            r["docksAvailable"] = int(dock["properties"]["docksAvailable"])
            r["classicBikesAvailable"] = int(dock["properties"]["classicBikesAvailable"])
            r["electricBikesAvailable"] = int(dock["properties"]["electricBikesAvailable"])
    return r

def main(config):
    selected_dock = config.str("dock", default_dock)
    dock_data = get_dock_info(selected_dock)

    if dock_data.get("classicBikesAvailable") > 0:
        regular_bike_color = "#FF9400"
        regular_bike_image = REGULAR_BIKE
    else:
        regular_bike_color = "#999999"
        regular_bike_image = REGULAR_BIKE_GRAY

    if dock_data.get("electricBikesAvailable") > 0:
        electric_bike_color = "#1EB100"
        electric_bike_image = ELECTRIC_BIKE
    else:
        electric_bike_color = "#999999"
        electric_bike_image = ELECTRIC_BIKE_GRAY

    if dock_data.get("docksAvailable") > 0:
        dock_color = "#00A1FE"
        dock_image = BIKE_DOCK
    else:
        dock_color = "#999999"
        dock_image = BIKE_DOCK_GRAY

    return render.Root(
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Column(
                    children = [
                        render.Stack(children = [
                            render.Box(height = 7, width = 64, color = "#8C189A", child = render.Padding(pad = (0, 1, 0, 1), child = render.Marquee(width = 64, offset_start = 64, offset_end = 64, child = render.Text(dock_data["name"], font = "CG-pixel-4x5-mono")))),
                        ]),
                        render.Row(children = [
                            render.Column(children = [
                                render.Box(width = 21, height = 15, child = render.Image(src = regular_bike_image)),
                                render.Box(width = 21, height = 11, child = render.Text(str(dock_data["classicBikesAvailable"]), font = "Dina_r400-6", color = regular_bike_color)),
                            ]),
                            render.Column(children = [
                                render.Box(width = 21, height = 15, child = render.Image(src = electric_bike_image)),
                                render.Box(width = 21, height = 11, child = render.Text(str(dock_data["electricBikesAvailable"]), font = "Dina_r400-6", color = electric_bike_color)),
                            ]),
                            render.Column(children = [
                                render.Box(width = 21, height = 15, child = render.Image(src = dock_image)),
                                render.Box(width = 21, height = 11, child = render.Text(str(dock_data["docksAvailable"]), font = "Dina_r400-6", color = dock_color)),
                            ]),
                        ]),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "dock",
                name = "Dock",
                desc = "The dock to display data for.",
                icon = "bicycle",
                default = default_dock,
                options = populate_schema(),
            ),
        ],
    )
