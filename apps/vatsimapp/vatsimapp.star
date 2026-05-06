load("http.star", "http")
load("images/offline_icon.png", OFFLINE_ICON_ASSET = "file")
load("images/online_icon.png", ONLINE_ICON_ASSET = "file")
load("render.star", "render")

OFFLINE_ICON = OFFLINE_ICON_ASSET.readall()
ONLINE_ICON = ONLINE_ICON_ASSET.readall()

def main():
    ICAO = "WIEE"
    NUM_OF_DEP = 0
    NUM_OF_ARR = 0

    DEL_ACTIVE = False
    GND_ACTIVE = False
    TWR_ACTIVE = False
    APP_ACTIVE = False

    suffixes = ["_DEL", "_GND", "_TWR", "_APP"]

    response = http.get("https://data.vatsim.net/v3/vatsim-data.json")
    data = response.json()

    for pilot in data["pilots"]:
        if "flight_plan" in pilot and pilot["flight_plan"]:
            if "departure" in pilot["flight_plan"] and pilot["flight_plan"]["departure"] == ICAO:
                NUM_OF_DEP += 1
            if "arrival" in pilot["flight_plan"] and pilot["flight_plan"]["arrival"] == ICAO:
                NUM_OF_ARR += 1

    for controller in data["controllers"]:
        if ICAO in controller["callsign"]:
            for suffix in suffixes:
                if suffix in controller["callsign"]:
                    if suffix == "_DEL":
                        DEL_ACTIVE = True
                    elif suffix == "_GND":
                        GND_ACTIVE = True
                    elif suffix == "_TWR":
                        TWR_ACTIVE = True
                    elif suffix == "_APP":
                        APP_ACTIVE = True

    return render.Root(
        delay = 500,
        child = render.Box(
            padding = 1,
            child =
                render.Animation(
                    children = [
                        render.Column(children = [
                            render.Text(font = "tom-thumb", content = ICAO),
                            render.Text(font = "tom-thumb", content = "DEP:%s|ARR:%s" % (NUM_OF_DEP, NUM_OF_ARR)),
                            render.Text(font = "tom-thumb", content = "--------------------------------"),
                            render.Row(children = [
                                render.Text(font = "tom-thumb", content = "DEL"),
                                render.Image(height = 5, width = 5, src = ONLINE_ICON) if DEL_ACTIVE else render.Image(height = 5, width = 5, src = OFFLINE_ICON),
                                render.Text(font = "tom-thumb", content = "   "),
                                render.Text(font = "tom-thumb", content = "GND"),
                                render.Image(height = 5, width = 5, src = ONLINE_ICON) if GND_ACTIVE else render.Image(height = 5, width = 5, src = OFFLINE_ICON),
                            ]),
                            render.Row(children = [
                                render.Text(font = "tom-thumb", content = "TWR"),
                                render.Image(height = 5, width = 5, src = ONLINE_ICON) if TWR_ACTIVE else render.Image(height = 5, width = 5, src = OFFLINE_ICON),
                                render.Text(font = "tom-thumb", content = "   "),
                                render.Text(font = "tom-thumb", content = "APP"),
                                render.Image(height = 5, width = 5, src = ONLINE_ICON) if APP_ACTIVE else render.Image(height = 5, width = 5, src = OFFLINE_ICON),
                            ]),
                        ]),
                    ],
                ),
        ),
    )
