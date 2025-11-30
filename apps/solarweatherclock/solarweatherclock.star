"""
Applet: SolarWeatherClock
Summary: Grid power, weather & time
Description: Retrieves the output or input to the grid obtained from home assistant and displays this along with a weather icon and the time.
Author: shmauk
"""

load("http.star", "http")
load("images/export.png", EXPORT_ASSET = "file")
load("images/img_82d9eb1d.bin", WINDY_VARIANT_ASSET = "file")
load("images/import.png", IMPORT_ASSET = "file")
load("images/solarweatherclock_generic_1.png", SOLARWEATHERCLOCK_GENERIC_1_ASSET = "file")
load("images/solarweatherclock_generic_2.png", SOLARWEATHERCLOCK_GENERIC_2_ASSET = "file")
load("images/solarweatherclock_generic_3.png", SOLARWEATHERCLOCK_GENERIC_3_ASSET = "file")
load("images/solarweatherclock_generic_4.png", SOLARWEATHERCLOCK_GENERIC_4_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

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
        return SOLARWEATHERCLOCK_GENERIC_3_ASSET.readall()
    elif weather == "cloudy":
        return CLOUDY_ASSET.readall()
    elif weather == "fog":
        return FOG_ASSET.readall()
    elif weather == "hail":
        return HAIL_ASSET.readall()
    elif weather == "lightning":
        return LIGHTNING_ASSET.readall()
    elif weather == "lightning-rainy":
        return LIGHTNING_RAINY_ASSET.readall()
    elif weather == "partlycloudy":
        return PARTLYCLOUDY_ASSET.readall()
    elif weather == "pouring":
        return POURING_ASSET.readall()
    elif weather == "rainy":
        return RAINY_ASSET.readall()
    elif weather == "snowy":
        return SNOWY_ASSET.readall()
    elif weather == "snowy-rainy":
        return SNOWY_RAINY_ASSET.readall()
    elif weather == "sunny":
        return SOLARWEATHERCLOCK_GENERIC_1_ASSET.readall()
    elif weather == "windy":
        return SOLARWEATHERCLOCK_GENERIC_4_ASSET.readall()
    elif weather == "windy-variant":
        return WINDY_VARIANT_ASSET.readall()()
    elif weather == "exceptional":
        return SOLARWEATHERCLOCK_GENERIC_2_ASSET.readall()
    else:
        return SOLARWEATHERCLOCK_GENERIC_1_ASSET.readall()
