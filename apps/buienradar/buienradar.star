"""
Applet: Buienradar
Summary: Buienradar (BE/NL)
Description: Shows the rain radar of Belgium or The Netherlands.
Author: PMK (@pmk)
"""

load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("html.star", "html")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/img_03ffccb0.png", IMG_03ffccb0_ASSET = "file")
load("images/img_0489534a.png", IMG_0489534a_ASSET = "file")
load("images/img_0e23884e.png", IMG_0e23884e_ASSET = "file")
load("images/img_0e915f20.png", IMG_0e915f20_ASSET = "file")
load("images/img_10a4ce88.png", IMG_10a4ce88_ASSET = "file")
load("images/img_1646288d.png", IMG_1646288d_ASSET = "file")
load("images/img_19ca3fd6.png", IMG_19ca3fd6_ASSET = "file")
load("images/img_22f880aa.png", IMG_22f880aa_ASSET = "file")
load("images/img_25159af9.png", IMG_25159af9_ASSET = "file")
load("images/img_25b2084c.png", IMG_25b2084c_ASSET = "file")
load("images/img_282c0f28.png", IMG_282c0f28_ASSET = "file")
load("images/img_2fd7f174.png", IMG_2fd7f174_ASSET = "file")
load("images/img_30b449d6.png", IMG_30b449d6_ASSET = "file")
load("images/img_3594951f.png", IMG_3594951f_ASSET = "file")
load("images/img_3a1c6a6e.png", IMG_3a1c6a6e_ASSET = "file")
load("images/img_3be304ee.png", IMG_3be304ee_ASSET = "file")
load("images/img_4cab80f1.png", IMG_4cab80f1_ASSET = "file")
load("images/img_4e8cad9e.png", IMG_4e8cad9e_ASSET = "file")
load("images/img_573f64b7.png", IMG_573f64b7_ASSET = "file")
load("images/img_58baa058.png", IMG_58baa058_ASSET = "file")
load("images/img_60f468b6.png", IMG_60f468b6_ASSET = "file")
load("images/img_75ea090f.png", IMG_75ea090f_ASSET = "file")
load("images/img_79c7994a.png", IMG_79c7994a_ASSET = "file")
load("images/img_7b0652db.png", IMG_7b0652db_ASSET = "file")
load("images/img_7dc545cc.png", IMG_7dc545cc_ASSET = "file")
load("images/img_82cbb27b.png", IMG_82cbb27b_ASSET = "file")
load("images/img_91a510fe.png", IMG_91a510fe_ASSET = "file")
load("images/img_9469ae8a.png", IMG_9469ae8a_ASSET = "file")
load("images/img_9b8ca8cf.png", IMG_9b8ca8cf_ASSET = "file")
load("images/img_a32c3fa1.png", IMG_a32c3fa1_ASSET = "file")
load("images/img_a8573711.png", IMG_a8573711_ASSET = "file")
load("images/img_ab46d489.png", IMG_ab46d489_ASSET = "file")
load("images/img_ab84862d.png", IMG_ab84862d_ASSET = "file")
load("images/img_abf0f1e8.png", IMG_abf0f1e8_ASSET = "file")
load("images/img_b201c517.png", IMG_b201c517_ASSET = "file")
load("images/img_b3297dfd.png", IMG_b3297dfd_ASSET = "file")
load("images/img_c4c0d427.png", IMG_c4c0d427_ASSET = "file")
load("images/img_c97bb50d.png", IMG_c97bb50d_ASSET = "file")
load("images/img_cda743e8.png", IMG_cda743e8_ASSET = "file")
load("images/img_d0617c84.png", IMG_d0617c84_ASSET = "file")
load("images/img_d7ccce9a.png", IMG_d7ccce9a_ASSET = "file")
load("images/img_d868f264.png", IMG_d868f264_ASSET = "file")
load("images/img_e690a807.png", IMG_e690a807_ASSET = "file")
load("images/img_eeda651b.png", IMG_eeda651b_ASSET = "file")
load("images/img_f53f325e.png", IMG_f53f325e_ASSET = "file")
load("images/img_f67896b5.png", IMG_f67896b5_ASSET = "file")
load("images/img_f993e539.png", IMG_f993e539_ASSET = "file")

DEFAULT_COUNTRY = "NL"
DEFAULT_DISPLAYING = "radar"
DEFAULT_LOCATION = "{\"value\": \"2757783\"}"

COLOR_DIMMED = "#fff6"
DAYS_SHORT = ["Zo", "Ma", "Di", "Wo", "Do", "Vr", "Za"]

def day_of_week(date):
    num = humanize.day_of_week(time.parse_time(date + "Z"))
    return DAYS_SHORT[num]

def is_outside_benl(location):
    lat = float(location["lat"])
    lng = float(location["lng"])
    return lat <= 49.49 or lat >= 53.57 or lng <= 2.57 or lng >= 7.20

def convert_locations_to_options(locations):
    filtered_locations = []
    for location in locations:
        if (location["countrycode"] != "BE" or location["countrycode"] != "NL") and ("hidefromsearch" in location and location["hidefromsearch"] == "False"):
            filtered_locations.append(location)

    options = []
    for option in filtered_locations:
        options.append(
            schema.Option(
                display = "{}, {}".format(option["name"], option["country"]),
                value = "{}".format(int(option["id"])),
            ),
        )
    return options

def location_handler(place):
    location = json.decode(place)
    if is_outside_benl(location):
        return [
            schema.Option(
                display = "Locatie is buiten België en Nederland",
                value = "error",
            ),
        ]

    data = get_locations(humanize.url_encode(location.get("locality")))
    return convert_locations_to_options(data) or []

def get_data(url, ttl_seconds):
    response = http.get(url = url, ttl_seconds = ttl_seconds)
    if response.status_code != 200:
        fail("Buienradar request failed with status %d @ %s", response.status_code, url)
    return response

def get_locations(query, ttl_seconds = 60 * 60):
    url = "https://location.buienradar.nl/1.1/location/search?query={}".format(query)
    response = get_data(url, ttl_seconds)
    return response.json()

def get_forecast(location_id, ttl_seconds = 60 * 60):
    url = "https://forecast.buienradar.nl/2.0/forecast/{}".format(location_id)
    response = get_data(url, ttl_seconds)
    return response.json()

def get_radar(country = DEFAULT_COUNTRY, ttl_seconds = 60 * 15):
    url = "https://image.buienradar.nl/2.0/image/animation/RadarMapRainWebMercator{}?width=64&height=64&renderBackground=True&renderBranding=False&renderText=False".format(country)
    response = get_data(url, ttl_seconds)
    return response.body()

def get_weather_news_page(ttl_seconds = 60 * 15):
    url = "https://www.buienradar.nl/nederland/weerbericht/weerbericht#readarea"
    response = get_data(url, ttl_seconds)
    return response.body()

def get_rain_data(lat, lon, ttl_seconds = 60 * 5):
    # url = "https://graphdata.buienradar.nl/2.0/forecast/geo/RainEU3Hour?lat={}&lon={}".format(lat, lon)
    url = "https://graphdata.buienradar.nl/2.0/forecast/geo/RainHistoryForecast?lat={}&lon={}".format(lat, lon)
    response = get_data(url, ttl_seconds)
    return response.json()

def render_radar(country):
    radar = get_radar(country)
    radar_image = render.Image(
        src = radar,
        width = 64,
        height = 64,
    )

    return render.Root(
        delay = radar_image.delay,
        child = render.Stack(
            children = [
                render.Box(
                    child = radar_image,
                ),
                render.Padding(
                    pad = (1, 1, 1, 1),
                    child = render.WrappedText(
                        width = 24,
                        linespacing = 1,
                        content = "Buien- radar",
                        color = "#fff",
                        font = "CG-pixel-3x5-mono",
                    ),
                ),
            ],
        ),
    )

def render_today(location):
    forecast = get_forecast(location)
    today = forecast["days"][0]

    page = get_weather_news_page()
    message = html(page).find("#readarea > p:first-child").text().strip()

    return render.Root(
        show_full_animation = True,
        delay = 25,
        child = render.Stack(
            children = [
                render.Padding(
                    pad = (0, 3, 0, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(
                                src = get_icon(today["iconcode"]),
                                width = 19,
                                height = 19,
                            ),
                            render.Column(
                                main_align = "center",
                                cross_align = "center",
                                children = [
                                    render.Text(
                                        content = "{}°".format(int(today["maxtemperature"])),
                                        font = "tb-8",
                                        color = "#ff8164",
                                        offset = -1,
                                    ),
                                    render.Text(
                                        content = "{}°".format(int(today["mintemperature"])),
                                        font = "tb-8",
                                        color = "#59bfff",
                                        offset = -1,
                                    ),
                                ],
                            ),
                            render.Column(
                                main_align = "center",
                                cross_align = "center",
                                children = [
                                    render.Row(
                                        cross_align = "center",
                                        children = [
                                            render.Text(
                                                content = "{}".format(int(today["beaufort"])),
                                                font = "tom-thumb",
                                                color = "#00ffc0",
                                            ),
                                            render.Image(
                                                src = get_wind_icon(today["winddirection"]),
                                                width = 11,
                                                height = 11,
                                            ),
                                        ],
                                    ),
                                    render.Text(
                                        content = "{}%".format(int(today["humidity"])),
                                        font = "tom-thumb",
                                        color = "#ff00cc",
                                    ),
                                ],
                            ),
                        ],
                    ),
                ),
                render.Padding(
                    pad = (0, 26, 0, 0),
                    child = render.Marquee(
                        child = render.Text(
                            content = message,
                            font = "tom-thumb",
                            color = "#bbb",
                        ),
                        width = 64,
                        offset_start = 64,
                        offset_end = 64,
                    ),
                ),
            ],
        ),
    )

def render_forecast(location):
    forecast = get_forecast(location)

    return render.Root(
        child = render.Row(
            children = [
                render_weather_column(forecast["days"][0]),
                animation.Transformation(
                    child = render.Row(
                        children = [render_weather_column(forecast["days"][i + 1]) for i in range(4)],
                    ),
                    duration = 60,
                    delay = 60,
                    origin = animation.Origin(0, 0),
                    height = 32,
                    width = 83,
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, 0)],
                            curve = "ease_in_out",
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(-41, 0)],
                            curve = "ease_in_out",
                        ),
                    ],
                ),
            ],
        ),
    )

def render_rain_graph(location):
    forecast = get_forecast(location)
    rain_data = get_rain_data(lat = forecast["location"]["lat"], lon = forecast["location"]["lon"])

    rain = []
    for idx, d in enumerate(rain_data["forecasts"]):
        rain.append((idx, d["value"]))

    return render.Root(
        child = render.Stack(
            children = [
                # Graph
                render.Padding(
                    pad = (1, 0, 0, 0),
                    child = render.Plot(
                        width = 62,
                        height = 24,
                        color = rain_data["color"],
                        fill = True,
                        fill_color = rain_data["color"],
                        y_lim = (0, 100),
                        data = rain,
                    ),
                ),
                # Grid line vertical left
                render.Padding(
                    pad = (0, 0, 0, 0),
                    child = render.Box(
                        width = 1,
                        height = 24,
                        color = "#666",
                    ),
                ),
                # Grid line vertical middle-left
                render.Padding(
                    pad = (21, 0, 0, 0),
                    child = render.Box(
                        width = 1,
                        height = 24,
                        color = "#fff6",
                    ),
                ),
                # Grid line vertical middle-right
                render.Padding(
                    pad = (42, 0, 0, 0),
                    child = render.Box(
                        width = 1,
                        height = 24,
                        color = "#fff6",
                    ),
                ),
                # Grid line vertical right
                render.Padding(
                    pad = (63, 0, 0, 0),
                    child = render.Box(
                        width = 1,
                        height = 24,
                        color = "#666",
                    ),
                ),
                # Grid line horizontal middle
                render.Padding(
                    pad = (1, 12, 0, 0),
                    child = render.Box(
                        width = 62,
                        height = 1,
                        color = "#fff6",
                    ),
                ),
                # Grid line horizontal top
                render.Padding(
                    pad = (0, 0, 0, 0),
                    child = render.Box(
                        width = 64,
                        height = 1,
                        color = "#666",
                    ),
                ),
                # Grid line horizontal bottom
                render.Padding(
                    pad = (0, 23, 0, 0),
                    child = render.Box(
                        width = 64,
                        height = 1,
                        color = "#666",
                    ),
                ),
                # Now line
                render.Padding(
                    pad = (8, 6, 0, 0),
                    child = render.Box(
                        width = 1,
                        height = 18,
                        color = "#e88504",
                    ),
                ),
                # Now text
                render.Padding(
                    pad = (8, 0, 0, 0),
                    child = render.Text(
                        content = "nu",
                        font = "tom-thumb",
                        color = "#e88504",
                    ),
                ),
                # Time text bottom
                render.Padding(
                    pad = (0, 27, 0, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "space_between",
                        children = [
                            render.Text(
                                content = "{}".format(humanize.time_format("HH:mm", time.parse_time(rain_data["forecasts"][0]["datetime"] + "Z"))),
                                font = "tom-thumb",
                                color = "#666",
                            ),
                            render.Text(
                                content = "t/m",
                                font = "tom-thumb",
                                color = "#666",
                            ),
                            render.Text(
                                content = "{}".format(humanize.time_format("HH:mm", time.parse_time(rain_data["forecasts"][len(rain_data["forecasts"]) - 1]["datetime"] + "Z"))),
                                font = "tom-thumb",
                                color = "#666",
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def render_weather_column(data):
    border = render.Box(
        width = 1,
        height = 32,
        color = COLOR_DIMMED,
    )

    column = render.Box(
        width = 20,
        height = 32,
        color = "#000",
        child = render.Padding(
            pad = (1, 0, 1, 0),
            child = render.Column(
                expanded = True,
                main_align = "center",
                children = [
                    render.Image(
                        src = get_icon(data["iconcode"]),
                        width = 19,
                        height = 19,
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        children = [
                            render.Text(
                                content = "{}".format(day_of_week(data["date"])),
                                font = "tb-8",
                                color = "#fff",
                                offset = 1,
                            ),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        children = [
                            render.Text(
                                content = "{}".format(int(data["maxtemperature"])),
                                font = "tom-thumb",
                                color = "#ff8164",
                            ),
                            render.Padding(
                                pad = (0, 0, 1, 0),
                                child = render.Text(
                                    content = "|",
                                    font = "tb-8",
                                    color = COLOR_DIMMED,
                                    offset = 2,
                                ),
                            ),
                            render.Text(
                                content = "{}".format(int(data["mintemperature"])),
                                font = "tom-thumb",
                                color = "#59bfff",
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

    return render.Row(
        children = [column, border],
    )

def main(config):
    country = config.str("country", DEFAULT_COUNTRY)
    displaying = config.str("displaying", DEFAULT_DISPLAYING)
    location_id = config.get("location", DEFAULT_LOCATION)
    location = int(json.decode(location_id)["value"])

    if displaying == "radar":
        return render_radar(country)
    elif displaying == "today":
        return render_today(location)
    elif displaying == "forecast":
        return render_forecast(location)
    elif displaying == "rain_graph":
        return render_rain_graph(location)
    else:
        return []

def get_schema():
    options_countries = [
        schema.Option(
            display = "Nederland",
            value = "NL",
        ),
        schema.Option(
            display = "België",
            value = "BE",
        ),
    ]

    options_displaying = [
        schema.Option(
            display = "Buienradar map",
            value = "radar",
        ),
        schema.Option(
            display = "Weerbericht van vandaag",
            value = "today",
        ),
        schema.Option(
            display = "Verwachting komende dagen",
            value = "forecast",
        ),
        schema.Option(
            display = "Verwachte neerslag",
            value = "rain_graph",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "country",
                name = "Land",
                desc = "Welk land weergegeven moet worden.",
                icon = "globe",
                default = DEFAULT_COUNTRY,
                options = options_countries,
            ),
            schema.LocationBased(
                id = "location",
                name = "Locatie",
                desc = "Locatie weerbericht.",
                icon = "locationDot",
                handler = location_handler,
            ),
            schema.Dropdown(
                id = "displaying",
                name = "Weergave",
                desc = "Wat weer te geven.",
                icon = "sun",
                default = DEFAULT_DISPLAYING,
                options = options_displaying,
            ),
        ],
    )

def get_icon(icon_code):
    if icon_code == "ww":
        return IMG_7dc545cc_ASSET.readall()
    if icon_code == "vv":
        return IMG_10a4ce88_ASSET.readall()
    if icon_code == "uu":
        return IMG_f993e539_ASSET.readall()
    if icon_code == "tt":
        return IMG_c4c0d427_ASSET.readall()
    if icon_code == "ss":
        return IMG_573f64b7_ASSET.readall()
    if icon_code == "qq":
        return IMG_a32c3fa1_ASSET.readall()
    if icon_code == "rr":
        return IMG_30b449d6_ASSET.readall()
    if icon_code == "pp":
        return IMG_91a510fe_ASSET.readall()
    if icon_code == "nn":
        return IMG_f53f325e_ASSET.readall()
    if icon_code == "oo":
        return IMG_19ca3fd6_ASSET.readall()
    if icon_code == "mm":
        return IMG_b201c517_ASSET.readall()
    if icon_code == "ll":
        return IMG_a32c3fa1_ASSET.readall()
    if icon_code == "kk":
        return IMG_282c0f28_ASSET.readall()
    if icon_code == "jj":
        return IMG_2fd7f174_ASSET.readall()
    if icon_code == "ii":
        return IMG_a8573711_ASSET.readall()
    if icon_code == "hh":
        return IMG_3be304ee_ASSET.readall()
    if icon_code == "gg":
        return IMG_b3297dfd_ASSET.readall()
    if icon_code == "ff":
        return IMG_282c0f28_ASSET.readall()
    if icon_code == "dd":
        return IMG_cda743e8_ASSET.readall()
    if icon_code == "cc":
        return IMG_91a510fe_ASSET.readall()
    if icon_code == "bb":
        return IMG_19ca3fd6_ASSET.readall()
    if icon_code == "aa":
        return IMG_7b0652db_ASSET.readall()

    if icon_code == "w":
        return IMG_58baa058_ASSET.readall()
    if icon_code == "v":
        return IMG_0e915f20_ASSET.readall()
    if icon_code == "u":
        return IMG_4cab80f1_ASSET.readall()
    if icon_code == "t":
        return IMG_60f468b6_ASSET.readall()
    if icon_code == "s":
        return IMG_3594951f_ASSET.readall()
    if icon_code == "r":
        return IMG_82cbb27b_ASSET.readall()
    if icon_code == "q":
        return IMG_4e8cad9e_ASSET.readall()
    if icon_code == "p":
        return IMG_91a510fe_ASSET.readall()
    if icon_code == "o":
        return IMG_f67896b5_ASSET.readall()
    if icon_code == "n":
        return IMG_e690a807_ASSET.readall()
    if icon_code == "m":
        return IMG_b201c517_ASSET.readall()
    if icon_code == "l":
        return IMG_a32c3fa1_ASSET.readall()
    if icon_code == "k":
        return IMG_9469ae8a_ASSET.readall()
    if icon_code == "j":
        return IMG_abf0f1e8_ASSET.readall()
    if icon_code == "i":
        return IMG_22f880aa_ASSET.readall()
    if icon_code == "h":
        return IMG_3a1c6a6e_ASSET.readall()
    if icon_code == "g":
        return IMG_75ea090f_ASSET.readall()
    if icon_code == "f":
        return IMG_9469ae8a_ASSET.readall()
    if icon_code == "d":
        return IMG_ab84862d_ASSET.readall()
    if icon_code == "c":
        return IMG_91a510fe_ASSET.readall()
    if icon_code == "b":
        return IMG_f67896b5_ASSET.readall()
    if icon_code == "a":
        return IMG_25b2084c_ASSET.readall()

    return IMG_25b2084c_ASSET.readall()

def get_wind_icon(direction):
    d = direction.upper()
    if d == "N":
        return IMG_d7ccce9a_ASSET.readall()
    if d == "NO":
        return IMG_d0617c84_ASSET.readall()
    if d == "NNO":
        return IMG_0489534a_ASSET.readall()
    if d == "O":
        return IMG_c97bb50d_ASSET.readall()
    if d == "Z":
        return IMG_ab46d489_ASSET.readall()
    if d == "ZO":
        return IMG_eeda651b_ASSET.readall()
    if d == "ZZO":
        return IMG_0e23884e_ASSET.readall()
    if d == "W":
        return IMG_79c7994a_ASSET.readall()
    if d == "ZW":
        return IMG_25159af9_ASSET.readall()
    if d == "ZZW":
        return IMG_1646288d_ASSET.readall()
    if d == "NW":
        return IMG_03ffccb0_ASSET.readall()
    if d == "NNW":
        return IMG_9b8ca8cf_ASSET.readall()

    return IMG_d868f264_ASSET.readall()
