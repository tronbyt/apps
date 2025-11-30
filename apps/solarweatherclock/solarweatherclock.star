"""
Applet: SolarWeatherClock
Summary: Grid power, weather & time
Description: Retrieves the output or input to the grid obtained from home assistant and displays this along with a weather icon and the time.
Author: shmauk
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("images/export.png", EXPORT_ASSET = "file")
load("images/import.png", IMPORT_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/img_00556125.png", IMG_00556125_ASSET = "file")
load("images/img_0c789d62.png", IMG_0c789d62_ASSET = "file")
load("images/img_0f98ff25.png", IMG_0f98ff25_ASSET = "file")
load("images/img_5fde32e4.png", IMG_5fde32e4_ASSET = "file")
load("images/img_7719fd13.png", IMG_7719fd13_ASSET = "file")
load("images/img_82d9eb1d.bin", IMG_82d9eb1d_ASSET = "file")
load("images/img_8938f152.png", IMG_8938f152_ASSET = "file")
load("images/img_a2285224.png", IMG_a2285224_ASSET = "file")
load("images/img_b462ca70.png", IMG_b462ca70_ASSET = "file")
load("images/img_c4e0a08a.png", IMG_c4e0a08a_ASSET = "file")
load("images/img_c7b85522.png", IMG_c7b85522_ASSET = "file")
load("images/img_e3ac226b.png", IMG_e3ac226b_ASSET = "file")
load("images/img_eb567ea4.png", IMG_eb567ea4_ASSET = "file")
load("images/img_f40ba5e2.png", IMG_f40ba5e2_ASSET = "file")
load("images/img_f4d4aeee.png", IMG_f4d4aeee_ASSET = "file")

EXPORT = EXPORT_ASSET.readall()
IMPORT = IMPORT_ASSET.readall()

CLOCK_FORMAT = "03:04 PM"

def main(config):
    now = time.now()

    clock = now.format(CLOCK_FORMAT)

    if (config.str("hass", "") == "" or config.str("sol", "") == "" or config.str("attr", "") == "" or
        config.str("wthr", "") == "" or config.str("key", "") == ""):
        return render.Root(
            child = render.Box(
                render.Column(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "space_around",
                            cross_align = "center",
                            children = [
                                render.Text("0.0" + " " + "kW"),
                                render.Image(src = EXPORT),
                            ],
                        ),
                        render.Box(
                            width = 64,
                            height = 1,
                            color = "3AE",
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_around",
                            cross_align = "center",
                            children = [
                                render.Image(src = getImage("sunny")),
                                render.Text(clock),
                            ],
                        ),
                    ],
                ),
            ),
        )

    headers = {
        "Authorization": config.str("key", ""),
    }

    solar = http.get(config.str("hass", "") + "/api/states/" + config.str("sol", ""), headers = headers, ttl_seconds = 60)
    solar_j = solar.json()
    uom = "kW"
    sol = solar_j["attributes"][config.str("attr", "")]

    sol_n = float(sol)
    sol_d = math.round(sol_n / 1000 * 10) / 10
    sol = str(sol_d)

    if sol_n > 0:
        sol_i = EXPORT
    else:
        sol_i = IMPORT

    weather = http.get(config.str("hass", "") + "/api/states/" + config.str("wthr", ""), headers = headers, ttl_seconds = 60)
    weather_j = weather.json()
    wth = weather_j["state"]

    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_around",
                        cross_align = "center",
                        children = [
                            render.Text(sol + " " + uom),
                            render.Image(src = sol_i),
                        ],
                    ),
                    render.Box(
                        width = 64,
                        height = 1,
                        color = "3AE",
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_around",
                        cross_align = "center",
                        children = [
                            render.Image(src = getImage(wth)),
                            render.Text(clock),
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
            schema.Text(
                id = "hass",
                name = "Hass URL",
                desc = "Where to find home assistant installation.",
                icon = "globe",
            ),
            schema.Text(
                id = "sol",
                name = "Solar Entity",
                desc = "The name of the entity to query for solar production.",
                icon = "sun",
            ),
            schema.Text(
                id = "attr",
                name = "Grid Attribute",
                desc = "The name of the attribute on the solar entity.",
                icon = "plug",
            ),
            schema.Text(
                id = "wthr",
                name = "Weather Entity",
                desc = "The name of the entity to query for the weather.",
                icon = "cloud",
            ),
            schema.Text(
                id = "key",
                name = "Bearer Token for Home Assistant",
                desc = "The long lasting token for home assistant authentication.",
                icon = "key",
                secret = True,
            ),
        ],
    )

def getImage(weather):
    if weather == "clear-night":
        return IMG_a2285224_ASSET.readall()
    elif weather == "cloudy":
        return IMG_b462ca70_ASSET.readall()
    elif weather == "fog":
        return IMG_c4e0a08a_ASSET.readall()
    elif weather == "hail":
        return IMG_e3ac226b_ASSET.readall()
    elif weather == "lightning":
        return IMG_f40ba5e2_ASSET.readall()
    elif weather == "lightning-rainy":
        return IMG_00556125_ASSET.readall()
    elif weather == "partlycloudy":
        return IMG_7719fd13_ASSET.readall()
    elif weather == "pouring":
        return IMG_c7b85522_ASSET.readall()
    elif weather == "rainy":
        return IMG_0f98ff25_ASSET.readall()
    elif weather == "snowy":
        return IMG_eb567ea4_ASSET.readall()
    elif weather == "snowy-rainy":
        return IMG_0c789d62_ASSET.readall()
    elif weather == "sunny":
        return IMG_5fde32e4_ASSET.readall()
    elif weather == "windy":
        return IMG_f4d4aeee_ASSET.readall()
    elif weather == "windy-variant":
        return IMG_82d9eb1d_ASSET.readall()
    elif weather == "exceptional":
        return IMG_8938f152_ASSET.readall()
    else:
        return IMG_5fde32e4_ASSET.readall()
