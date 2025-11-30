"""
Applet: Buienradar
Summary: Buienradar (BE/NL)
Description: Shows the rain radar of Belgium or The Netherlands.
Author: PMK (@pmk)
"""

load("animation.star", "animation")
load("encoding/json.star", "json")
load("html.star", "html")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/weather_a.png", WEATHER_A_ASSET = "file")
load("images/weather_aa.png", WEATHER_AA_ASSET = "file")
load("images/weather_bb.png", WEATHER_BB_ASSET = "file")
load("images/weather_cc.png", WEATHER_CC_ASSET = "file")
load("images/weather_dd.png", WEATHER_DD_ASSET = "file")
load("images/weather_f.png", WEATHER_F_ASSET = "file")
load("images/weather_ff.png", WEATHER_FF_ASSET = "file")
load("images/weather_g.png", WEATHER_G_ASSET = "file")
load("images/weather_gg.png", WEATHER_GG_ASSET = "file")
load("images/weather_h.png", WEATHER_H_ASSET = "file")
load("images/weather_hh.png", WEATHER_HH_ASSET = "file")
load("images/weather_ii.png", WEATHER_II_ASSET = "file")
load("images/weather_j.png", WEATHER_J_ASSET = "file")
load("images/weather_jj.png", WEATHER_JJ_ASSET = "file")
load("images/weather_ll.png", WEATHER_LL_ASSET = "file")
load("images/weather_m.png", WEATHER_M_ASSET = "file")
load("images/weather_n.png", WEATHER_N_ASSET = "file")
load("images/weather_nn.png", WEATHER_NN_ASSET = "file")
load("images/weather_o.png", WEATHER_O_ASSET = "file")
load("images/weather_q.png", WEATHER_Q_ASSET = "file")
load("images/weather_r.png", WEATHER_R_ASSET = "file")
load("images/weather_rr.png", WEATHER_RR_ASSET = "file")
load("images/weather_s.png", WEATHER_S_ASSET = "file")
load("images/weather_ss.png", WEATHER_SS_ASSET = "file")
load("images/weather_t.png", WEATHER_T_ASSET = "file")
load("images/weather_tt.png", WEATHER_TT_ASSET = "file")
load("images/weather_u.png", WEATHER_U_ASSET = "file")
load("images/weather_uu.png", WEATHER_UU_ASSET = "file")
load("images/weather_v.png", WEATHER_V_ASSET = "file")
load("images/weather_vv.png", WEATHER_VV_ASSET = "file")
load("images/weather_w.png", WEATHER_W_ASSET = "file")
load("images/weather_ww.png", WEATHER_WW_ASSET = "file")
load("images/wind_n.png", WIND_N_ASSET = "file")
load("images/wind_nno.png", WIND_NNO_ASSET = "file")
load("images/wind_nnw.png", WIND_NNW_ASSET = "file")
load("images/wind_no.png", WIND_NO_ASSET = "file")
load("images/wind_nw.png", WIND_NW_ASSET = "file")
load("images/wind_o.png", WIND_O_ASSET = "file")
load("images/wind_w.png", WIND_W_ASSET = "file")
load("images/wind_z.png", WIND_Z_ASSET = "file")
load("images/wind_zo.png", WIND_ZO_ASSET = "file")
load("images/wind_zw.png", WIND_ZW_ASSET = "file")
load("images/wind_zzo.png", WIND_ZZO_ASSET = "file")
load("images/wind_zzw.png", WIND_ZZW_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

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
                                src = get_icon(today["iconcode"]).readall(),
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
                        src = get_icon(data["iconcode"].readall()),
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
        return WEATHER_WW_ASSET
    if icon_code == "vv":
        return WEATHER_VV_ASSET
    if icon_code == "uu":
        return WEATHER_UU_ASSET
    if icon_code == "tt":
        return WEATHER_TT_ASSET
    if icon_code == "ss":
        return WEATHER_SS_ASSET
    if icon_code == "qq":
        return WEATHER_LL_ASSET
    if icon_code == "rr":
        return WEATHER_RR_ASSET
    if icon_code == "pp":
        return WEATHER_LL_ASSET
    if icon_code == "nn":
        return WEATHER_NN_ASSET
    if icon_code == "oo":
        return WEATHER_BB_ASSET
    if icon_code == "mm":
        return WEATHER_M_ASSET
    if icon_code == "ll":
        return WEATHER_LL_ASSET
    if icon_code == "kk":
        return WEATHER_FF_ASSET
    if icon_code == "jj":
        return WEATHER_JJ_ASSET
    if icon_code == "ii":
        return WEATHER_II_ASSET
    if icon_code == "hh":
        return WEATHER_HH_ASSET
    if icon_code == "gg":
        return WEATHER_GG_ASSET
    if icon_code == "ff":
        return WEATHER_FF_ASSET
    if icon_code == "dd":
        return WEATHER_DD_ASSET
    if icon_code == "cc":
        return WEATHER_CC_ASSET
    if icon_code == "bb":
        return WEATHER_BB_ASSET
    if icon_code == "aa":
        return WEATHER_AA_ASSET

    if icon_code == "w":
        return WEATHER_W_ASSET
    if icon_code == "v":
        return WEATHER_V_ASSET
    if icon_code == "u":
        return WEATHER_U_ASSET
    if icon_code == "t":
        return WEATHER_T_ASSET
    if icon_code == "s":
        return WEATHER_S_ASSET
    if icon_code == "r":
        return WEATHER_R_ASSET
    if icon_code == "q":
        return WEATHER_Q_ASSET
    if icon_code == "p":
        return WEATHER_LL_ASSET
    if icon_code == "o":
        return WEATHER_O_ASSET
    if icon_code == "n":
        return WEATHER_N_ASSET
    if icon_code == "m":
        return WEATHER_M_ASSET
    if icon_code == "l":
        return WEATHER_LL_ASSET
    if icon_code == "k":
        return WEATHER_F_ASSET
    if icon_code == "j":
        return WEATHER_J_ASSET
    if icon_code == "i":
        return WEATHER_II_ASSET
    if icon_code == "h":
        return WEATHER_H_ASSET
    if icon_code == "g":
        return WEATHER_G_ASSET
    if icon_code == "f":
        return WEATHER_F_ASSET
    if icon_code == "d":
        return WEATHER_DD_ASSET
    if icon_code == "c":
        return WEATHER_CC_ASSET
    if icon_code == "b":
        return WEATHER_BB_ASSET
    if icon_code == "a":
        return WEATHER_A_ASSET

    return WEATHER_A_ASSET

def get_wind_icon(direction):
    d = direction.upper()
    if d == "N":
        return WIND_N_ASSET.readall()
    if d == "NO":
        return WIND_NO_ASSET.readall()
    if d == "NNO":
        return WIND_NNO_ASSET.readall()
    if d == "O":
        return WIND_O_ASSET.readall()
    if d == "Z":
        return WIND_Z_ASSET.readall()
    if d == "ZO":
        return WIND_ZO_ASSET.readall()
    if d == "ZZO":
        return WIND_ZZO_ASSET.readall()
    if d == "W":
        return WIND_W_ASSET.readall()
    if d == "ZW":
        return WIND_ZW_ASSET.readall()
    if d == "ZZW":
        return WIND_ZZW_ASSET.readall()
    if d == "NW":
        return WIND_NW_ASSET.readall()
    if d == "NNW":
        return WIND_NNW_ASSET.readall()

    return WIND_NNW_ASSET.readall()
