"""
Applet: Octopus Agile
Summary: Octopus Energy Agile Rates
Description: Gets the latest Agile Rates for Octopus Energy and shows the current price.
Author: sandeepb1
"""

load("http.star", "http")
load("images/img.png", IMG_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

IMG = IMG_ASSET.readall()

DEFAULT_PROD_CODE = "AGILE-24-04-03"
DEFAULT_TARIFF_CODE = "E-1R-AGILE-24-04-03-A"

def main(config):
    now = time.now().in_location("Etc/UTC")
    nowISO = now.format("2006-01-02T15:04:05Z")
    #2024-04-15T13:19:00Z

    OCTOPUS_AGILE_URL = "https://api.octopus.energy/v1/products/" + config.str("PROD_CODE", DEFAULT_PROD_CODE) + "/electricity-tariffs/" + config.str("TARIFF_CODE", DEFAULT_TARIFF_CODE) + "/standard-unit-rates/?period_from=" + nowISO

    octo = http.get(OCTOPUS_AGILE_URL)

    if octo.status_code != 200:
        fail(nowISO + octo.body())

    data = octo.json()
    count = data["count"]
    count = int(count) - 1
    nextRate = data["results"][count]["value_inc_vat"]

    color = "#FFF"

    if nextRate < int(config.str("PLUNGE_NUMBER", "1")):
        color = config.str("PLUNGE_COLOUR", "#A3BE8C")

    if nextRate < int(config.str("GOOD_NUMBER", "4")):
        color = config.str("GOOD_COLOUR", "#81A1C1")

    if nextRate > int(config.str("BAD_NUMBER", "17")):
        color = config.str("BAD_COLOUR", "#BF616A")

    return render.Root(
        delay = 60000,
        child = render.Box(
            child = render.Column(
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Image(
                        src = IMG,
                        width = 16,
                        height = 16,
                    ),
                    render.Text(
                        content = str((math.round(nextRate * 100) / 100)) + "p",
                        font = "tb-8",
                        color = color,
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
                id = "PROD_CODE",
                name = "Product Code",
                desc = "The code of the product to be retrieved, for example VAR-17-01-11.",
                icon = "user",
                default = "AGILE-24-04-03",
            ),
            schema.Text(
                id = "TARIFF_CODE",
                name = "Tariff Code",
                desc = "The code of the tariff to be retrieved, for example E-1R-VAR-17-01-11-A.",
                icon = "user",
                default = "E-1R-AGILE-24-04-03-A",
            ),
            schema.Text(
                id = "PLUNGE_NUMBER",
                name = "Plunge Threshold",
                desc = "The rate to determine extremely low rates. Check to see if the rate is below the defined number.",
                icon = "0",
                default = "1",
            ),
            schema.Text(
                id = "GOOD_NUMBER",
                name = "Good Rate Threshold",
                desc = "The rate to determine rates at a good level. Check to see if the rate is below the defined number.",
                icon = "0",
                default = "4",
            ),
            schema.Text(
                id = "BAD_NUMBER",
                name = "Bad Rate Threshold",
                desc = "The rate to determine rates that are at a high level. Check to see if the rate is above the defined number.",
                icon = "0",
                default = "17",
            ),
            schema.Color(
                id = "PLUNGE_COLOUR",
                name = "Plunge Colour",
                desc = "The colour used when plunge pricing or extremely low rates are in effect",
                icon = "brush",
                default = "#A3BE8C",
            ),
            schema.Color(
                id = "GOOD_COLOUR",
                name = "Good Rate Colour",
                desc = "The colour used when rates are at a good level",
                icon = "brush",
                default = "#81A1C1",
            ),
            schema.Color(
                id = "BAD_COLOUR",
                name = "Bad Rate Colour",
                desc = "The colour used when rates are at a high level",
                icon = "brush",
                default = "#BF616A",
            ),
        ],
    )
