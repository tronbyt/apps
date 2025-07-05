load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("time.star", "time")
load("schema.star", "schema")


def fetch_data(station):
    url = "http://wildc.net/wind/{}?time={}".format(station,time.now().unix)
    print(url)
    rep = http.get(url, ttl_seconds = 10)
    if rep.status_code != 200:
        fail("request failed with status %d", rep.status_code)
    data = rep.json()
    return data

def main(config):

    station = config.get("station", None) or "kanaha_simple.json"
    wind_units = config.get("wind_units", "mph")
    custom_label = config.get("custom_label", "")
    label_color = config.get("label_color", "#FFFFFF")
    data = fetch_data(station)
    print(data)
    wind_avg = int(data["avg"] + 0.5)
    wind_gust = int(data["gust"] + 0.5)
    wind_dir = data["dir_card"]
    wind_dir_degrees = int(data["dir_deg"] + 0.5)

    # Convert to knots if needed
    display_units = "mph"
    if wind_units == "kts":
        wind_avg = int(wind_avg / 1.15078 + 0.5)
        wind_gust = int(wind_gust / 1.15078 + 0.5)
        display_units = "kts"

    color_light = "#00FFFF" #cyan
    color_medium = "#AAEEDD" #??
    color_strong = "#00FF00" #green
    color_beast = "#FF0000" # red
    wind_color = color_medium
    if (wind_avg < 10):
        wind_color = color_light
    elif (wind_avg < 25):
        wind_color = color_medium
    elif (wind_avg < 30):
        wind_color = color_strong
    elif (wind_avg >= 30):
        wind_color = color_beast

    label = custom_label if custom_label != "" else data.get("label", "Wind")

    return render.Root(
        child = render.Box(
            render.Column(
                cross_align="center",
                main_align = "center",
                children = [
                    render.Text(
                        content = label,
                        font = "tb-8",
                        color = label_color,
                    ),
                    render.Text(
                        content = "%dg%d %s" % (wind_avg, wind_gust, display_units),
                        font = "6x13",
                        color = wind_color
                    ),
                    render.Text(
                        content = "%s %d°" % (wind_dir, wind_dir_degrees),
                        color = "#FFAA00",
                    ),
                ],
            ),
        ),
    )

def get_schema():
    station_options = [
        schema.Option(display = "Kanaha", value = "kanaha_simple.json"),
        schema.Option(display = "Ukumehame", value = "meco_ukumehame.json"),
        schema.Option(display = "Kihei", value = "kihei.json"),
        schema.Option(display = "Kailua", value = "kailua.json"),
    ]
    wind_unit_options = [
        schema.Option(display = "mph", value = "mph"),
        schema.Option(display = "kts", value = "kts"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Station",
                icon = "flag",
                desc = "Select wind station",
                options = station_options,
                default = "kanaha",
            ),
            schema.Dropdown(
                id = "wind_units",
                name = "Wind Units",
                icon = "wind",
                desc = "mph or kts",
                options = wind_unit_options,
                default = "mph"
            ),
            schema.Text(
                id = "custom_label",
                name = "Custom Label",
                icon = "edit",
                desc = "Override the display label (optional)",
                default = "",
            ),
            schema.Color(
                id = "label_color",
                name = "Label Color",
                icon = "palette",
                desc = "Pick a color for the label",
                default = "#FFFFFF",
            ),
        ]
    )

