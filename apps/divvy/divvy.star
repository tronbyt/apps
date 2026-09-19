"""
Applet: Divvy
Summary: Divvy Bike availability
Description: Shows the availability of bikes and e-bikes at a Divvy Bike station.
Author: Andy Day (@adayNU)
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/lyft_icon.png", LYFT_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

LYFT_ICON = LYFT_ICON_ASSET.readall()

STATIONS_URL = "https://gbfs.lyft.com/gbfs/1.1/chi/en/station_information.json"
STATION_STATUS_URL = "https://gbfs.lyft.com/gbfs/1.1/chi/en/station_status.json"
DEFAULT_STATION = '{"id":"1789242536879942642","name":"Halsted St & Fulton St"}'

def main(config):
    resp = http.get(STATION_STATUS_URL, ttl_seconds = 60)
    if resp.status_code != 200:
        fail("gbfs status request failed with status %d", resp.status_code)

    station_data = resp.json()["data"]["stations"]
    station = json.decode(config.get("station_id", DEFAULT_STATION))

    text = ""

    for _index, value in enumerate(station_data):
        if value["station_id"] == station["id"]:
            text = "Bikes:" + str(int(value["num_bikes_available"] - value["num_ebikes_available"])) + "\nE-Bikes:" + str(int(value["num_ebikes_available"]))
            break

    return render.Root(
        child = render.Column(
            children = [
                render.Column(
                    children = [
                        render.Marquee(
                            width = 64,
                            child = render.Text(station["name"]),
                        ),
                        render.Box(width = 64, height = 1, color = "#4338ca"),
                    ],
                ),
                render.Box(
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(src = LYFT_ICON, width = 20),
                            render.WrappedText(content = text, font = "tb-8"),
                        ],
                    ),
                ),
            ],
        ),
    )

def toOption(station):
    return schema.Option(
        display = station["name"],
        value = '{"id":"' + station["station_id"] + '", "name":"' + station["name"] + '"}',
    )

def get_schema():
    resp = http.get(STATIONS_URL, ttl_seconds = 60 * 60 * 24)
    if resp.status_code != 200:
        fail("gbfs station request failed with status %d", resp.status_code)

    options = sorted([toOption(x) for x in resp.json()["data"]["stations"]], key = lambda x: x.display)

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station_id",
                name = "Station",
                desc = "Which station's data to show",
                icon = "bicycle",
                default = options[0].value,
                options = options,
            ),
        ],
    )
