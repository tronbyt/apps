"""OK Mesonet - current conditions for one Oklahoma Mesonet station.

Pure parse/format logic lives in mesonet.star (loaded by the tests too);
this file owns fetching, rendering, and the config schema.

Data courtesy of the Oklahoma Mesonet (Oklahoma State University /
University of Oklahoma). Personal, non-commercial use.
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load(
    "mesonet.star",
    "BLUE",
    "DEFAULT_STATION",
    "DIM",
    "STATIONS",
    "build_view",
    "no_report_view",
    "offline_view",
    "parse_current_csv",
    "station_name",
    "wind_fit",
)
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CSV_URL = "https://www.mesonet.org/data/public/mesonet/current/current.csv.txt"
TTL_SECONDS = 300  # match the feed's 5-minute cadence; do not lower
USER_AGENT = "tronbyt-okmesonet/1.0 (github.com/jonfishr/tronbyt-okmesonet; personal non-commercial display)"

ICON_DROP = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAYAAACAcVaiAAAAG0lEQVR4nGNgAIKEpb/+M8AAnANiwDAqB1kZABP4Gu9o5QC5AAAAAElFTkSuQmCC")
ICON_RAIN = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAMAAAAFCAYAAACAcVaiAAAAFUlEQVR4nGNIWPrrPwMQwGhMBn4ZAAGeF/HFBXQpAAAAAElFTkSuQmCC")
ICON_PRES = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAGklEQVR4nGNgwAbmLF7/Hx1jSGDowGoUDAAAV4caVkE5XMYAAAAASUVORK5CYII=")

def metric_row(icon, text, color):
    children = []
    if icon != None:
        children.append(render.Padding(pad = (0, 0, 1, 0), child = render.Image(src = icon)))
    children.append(render.Text(content = text, font = "tom-thumb", color = color))
    return render.Row(children = children, cross_align = "center")

def render_frame(view):
    header = render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            render.Marquee(
                width = 58,
                child = render.Text(content = view["name"].upper(), font = "tom-thumb", color = DIM),
            ),
            render.Padding(pad = (0, 0, 1, 0), child = render.Circle(color = view["dot"], diameter = 3)),
        ],
    )
    right = render.Column(children = [
        metric_row(None, wind_fit(view["wind"]), view["wind_color"]),
        metric_row(ICON_DROP, view["secondary"], BLUE),
        metric_row(ICON_RAIN, view["rain"], BLUE),
        metric_row(ICON_PRES, view["pressure"], DIM),
    ])
    body = render.Row(children = [
        render.Box(
            width = 26,
            height = 25,
            child = render.Text(content = view["temp"], font = "6x13", color = view["temp_color"]),
        ),
        right,
    ])
    return render.Root(
        child = render.Column(children = [
            render.Box(height = 7, child = header),
            body,
        ]),
    )

def main(config):
    stid = config.get("station") or DEFAULT_STATION
    secondary = config.get("secondary") or "humidity"
    colorize = config.bool("colorize", True)
    name = station_name(stid)

    rep = http.get(CSV_URL, ttl_seconds = TTL_SECONDS, headers = {"User-Agent": USER_AGENT})
    if rep.status_code != 200 or len(rep.body()) == 0:
        return render_frame(offline_view(name))

    row = parse_current_csv(rep.body(), stid)
    if row == None:
        return render_frame(no_report_view(name))

    return render_frame(build_view(row, name, secondary, colorize, time.now()))

def get_schema():
    options = [
        schema.Option(display = "%s (%s)" % (name, stid), value = stid)
        for stid, name in STATIONS
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Station",
                desc = "Oklahoma Mesonet station to display.",
                icon = "locationDot",
                default = DEFAULT_STATION,
                options = options,
            ),
            schema.Dropdown(
                id = "secondary",
                name = "Secondary metric",
                desc = "Middle-right line: relative humidity or dewpoint.",
                icon = "droplet",
                default = "humidity",
                options = [
                    schema.Option(display = "Humidity (RH)", value = "humidity"),
                    schema.Option(display = "Dewpoint", value = "dewpoint"),
                ],
            ),
            schema.Toggle(
                id = "colorize",
                name = "Color temperature",
                desc = "Color the temperature by value; off shows plain white.",
                icon = "palette",
                default = True,
            ),
        ],
    )
