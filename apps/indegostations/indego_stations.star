"""
Applet: Indego Stations
Summary: Indego station availability
Description: The user selects an Indego (Philadelphia BIKE share) station and Tidbyt will regularly display the number of regular and electric bikes available.
Author: RayPatt
"""

load("http.star", "http")
load("images/bike.png", BIKE_ASSET = "file")
load("images/ebike.png", EBIKE_ASSET = "file")
load("images/lightning.png", LIGHTNING_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

BIKE = BIKE_ASSET.readall()
EBIKE = EBIKE_ASSET.readall()
LIGHTNING = LIGHTNING_ASSET.readall()

url = "https://kiosks.bicycletransit.workers.dev/phl"

def main(config):
    rep = http.get(url)
    if rep.status_code != 200:
        fail("Request failed with status %d", rep.status_code)

    station_no = int(config.get("Station", 1))

    all = rep.json()["features"]

    name = all[(station_no)]["properties"]["name"]

    bikes = rep.json()["features"][station_no]["properties"]["classicBikesAvailable"]
    ebikes = rep.json()["features"][station_no]["properties"]["electricBikesAvailable"]
    reward = rep.json()["features"][station_no]["properties"]["rewardBikesAvailable"]
    if (reward > 0):
        reward = "+"
    else:
        reward = "-"

    return render.Root(
        child = render.Column(
            children = [
                render.Marquee(child = render.Text(name), width = 64),
                render.Row(
                    expanded = False,
                    children = [
                        render.Column(
                            expanded = True,
                            children = [
                                render.Image(src = BIKE),
                            ],
                        ),
                        render.Row(
                            cross_align = "start",
                            children = [
                                render.Column(
                                    cross_align = "end",
                                    children = [
                                        render.Text(" " + str(int(bikes))),
                                        render.Text(" " + str(int(ebikes))),
                                    ],
                                ),
                                render.Column(
                                    cross_align = "Start",
                                    children = [
                                        render.Text(" Bikes"),
                                        render.Row(
                                            children = [
                                                render.Image(src = LIGHTNING),
                                                render.Text("Bikes"),
                                            ],
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    rep = http.get(url)
    if rep.status_code != 200:
        fail("Request failed with status %d", rep.status_code)

    all = rep.json()["features"]

    tmp = []
    tmp2 = []

    no_stations = len(all) - 1

    i = 0
    for _ in range(0, no_stations):
        tmp.append(all[i]["properties"]["name"])
        tmp2.append(str(i))
        i = i + 1

    tmp, tmp2 = zip(*sorted(zip(tmp, tmp2)))

    options = []
    for idx, i in enumerate(tmp):
        options.append(
            schema.Option(display = i, value = tmp2[idx]),
        )

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "Station",
                name = "Station Name",
                desc = "The desired station to display",
                icon = "brush",
                default = options[0].value,
                options = options,
            ),
        ],
    )
