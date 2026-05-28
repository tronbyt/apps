"""
Applet: SEPTA Regional Rail
Summary: SEPTA Regional Rail Departures
Description: Displays departure times for SEPTA regional rail trains.
Author: radiocolin
"""

load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

def regional_rail_station_options():
    regional_rail_stations = [
        "30th Street Station",
        "49th Street",
        "9th Street",
        "Airport Terminal A",
        "Airport Terminal B",
        "Airport Terminal C D",
        "Airport Terminal E F",
        "Allegheny",
        "Ambler",
        "Angora",
        "Ardmore",
        "Ardsley",
        "Berwyn",
        "Bethayres",
        "Bridesburg",
        "Bristol",
        "Bryn Mawr",
        "Carpenter",
        "Chalfont",
        "Chelten Avenue",
        "Cheltenham",
        "Chester Transportation Center",
        "Chestnut Hill East",
        "Chestnut Hill West",
        "Churchmans Crossing",
        "Claymont",
        "Clifton–Aldan",
        "Colmar",
        "Conshohocken",
        "Cornwells Heights",
        "Crestmont",
        "Croydon",
        "Crum Lynne",
        "Curtis Park",
        "Cynwyd",
        "Darby",
        "Daylesford",
        "Delaware Valley University",
        "Devon",
        "Downingtown",
        "Doylestown",
        "East Falls",
        "Eastwick",
        "Eddington",
        "Eddystone",
        "Elkins Park",
        "Elm Street",
        "Elwyn",
        "Exton",
        "Fern Rock Transportation Center",
        "Fernwood–Yeadon",
        "Folcroft",
        "Forest Hills",
        "Fort Washington",
        "Fortuna",
        "Fox Chase",
        "Germantown",
        "Gladstone",
        "Glenolden",
        "Glenside",
        "Gravers",
        "Gwynedd Valley",
        "Hatboro",
        "Haverford",
        "Highland",
        "Highland Avenue",
        "Holmesburg Junction",
        "Ivy Ridge",
        "Jefferson Station",
        "Jenkintown Wyncote",
        "Langhorne",
        "Lansdale",
        "Lansdowne",
        "Lawndale",
        "Levittown",
        "Link Belt",
        "Main Street",
        "Malvern",
        "Manayunk",
        "Marcus Hook",
        "Meadowbrook",
        "Media",
        "Melrose Park",
        "Merion",
        "Miquon",
        "Morton",
        "Mount Airy",
        "Moylan-Rose Valley",
        "Narberth",
        "Neshaminy Falls",
        "New Britain",
        "Newark",
        "Noble",
        "Norristown TC",
        "North Broad",
        "North Hills",
        "North Philadelphia",
        "North Wales",
        "Norwood",
        "Olney",
        "Oreland",
        "Overbrook",
        "Paoli",
        "Penllyn",
        "Penn Medicine Station",
        "Pennbrook",
        "Philmont",
        "Primos",
        "Prospect Park",
        "Queen Lane",
        "Radnor",
        "Richard Allen Lane",
        "Ridley Park",
        "Rosemont",
        "Roslyn",
        "Rydal",
        "Ryers",
        "Secane",
        "Sedgwick",
        "Sharon Hill",
        "Somerton",
        "Spring Mill",
        "St. Davids",
        "St. Martins",
        "Stenton",
        "Strafford",
        "Suburban Station",
        "Swarthmore",
        "Tacony",
        "Temple University",
        "Thorndale",
        "Torresdale",
        "Trenton",
        "Trevose",
        "Tulpehocken",
        "Upsal",
        "Villanova",
        "Wallingford",
        "Warminster",
        "Washington Lane",
        "Wawa",
        "Wayne",
        "Wayne Junction",
        "West Trenton",
        "Whitford",
        "Willow Grove",
        "Wilmington",
        "Wissahickon",
        "Wister",
        "Woodbourne",
        "Wyndmoor",
        "Wynnefield Avenue",
        "Wynnewood",
        "Yardley",
    ]

    station_options = []
    for i in regional_rail_stations:
        station_options.append(
            schema.Option(
                display = i,
                value = i,
            ),
        )
    return station_options

API_BASE = "http://www3.septa.org/api"
API_ROUTES = API_BASE + "/Routes"
API_SCHEDULE = API_BASE + "/Arrivals"
DEFAULT_STATION = "Wayne Junction"
DEFAULT_DIRECTION = "S"

def call_schedule_api(direction, station):
    r = http.get(API_SCHEDULE, params = {"station": station, "direction": direction, "results": "4"}, ttl_seconds = 30)
    schedule_raw = r.json()
    schedule = schedule_raw.values()[0][0].values()[0]
    return schedule

def get_schedule(direction, station, scale):
    schedule = call_schedule_api(direction, station)
    list_of_departures = []

    for i in schedule:
        parsed_departure = time.parse_time(i["sched_time"], "2006-01-02 15:04:05.000", "America/New_York").format("3:04")
        if int(time.parse_time(i["sched_time"], "2006-01-02 15:04:05.000", "America/New_York").format("15")) < 12:
            parsed_departure = parsed_departure + "a"
        else:
            parsed_departure = parsed_departure + "p"

        if len(list_of_departures) % 2 == 1:
            background = "#222"
            text = "#fff"
        else:
            background = "#000"
            text = "#ffc72c"
        if len(parsed_departure) == 5:
            departure = " " + parsed_departure
        else:
            departure = parsed_departure

        row_font = "tom-thumb" if scale == 1 else "terminus-12"
        row_height = 6 * scale
        time_width = 25 * scale
        text_width = 39 * scale

        item = render.Box(
            height = row_height,
            width = 64 * scale,
            color = background,
            child = render.Row(
                cross_align = "right",
                children = [
                    render.Box(
                        width = time_width,
                        child = render.Text(
                            departure,
                            font = row_font,
                            color = text,
                        ),
                    ),
                    render.Marquee(
                        child = render.Text(
                            i["train_id"] + " " + i["service_type"] + " to " + i["destination"] + " - " + i["status"],
                            font = row_font,
                            color = text,
                        ),
                        width = text_width,
                        offset_start = text_width + 1,
                        offset_end = text_width + 1,
                    ),
                ],
            ),
        )
        list_of_departures.append(item)

    if len(list_of_departures) < 1:
        return [render.Box(
            height = 6 * scale,
            width = 64 * scale,
            color = "#000",
            child = render.Text("Select a stop", font = "tom-thumb" if scale == 1 else "tb-8"),
        )]
    else:
        return list_of_departures

def main(config):
    scale = 2 if canvas.is2x() else 1
    station = config.str("station", DEFAULT_STATION)
    direction = config.str("direction", DEFAULT_DIRECTION)
    user_text = config.str("banner", "")
    schedule = get_schedule(direction, station, scale)
    left_pad = 1 * scale

    if config.bool("use_custom_banner_color"):
        banner_bg_color = config.str("custom_banner_color")
    else:
        banner_bg_color = "#45637A"

    if config.bool("use_custom_text_color"):
        banner_text_color = config.str("custom_text_color")
    else:
        banner_text_color = "#FFFFFF"

    if user_text == "":
        banner_text = station
    else:
        banner_text = user_text

    banner_font = "tom-thumb" if scale == 1 else "terminus-14"
    banner_height = 6 if scale == 1 else 14
    bottom_pad = 2 if scale == 1 else 2

    return render.Root(
        delay = 100,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Column(
                    children = [
                        render.Stack(children = [
                            render.Box(height = banner_height, width = 64 * scale, color = banner_bg_color),
                            render.Padding(pad = (left_pad, 0, 0, 0), child = render.Text(banner_text, font = banner_font, color = banner_text_color)),
                        ]),
                    ],
                ),
                render.Padding(pad = (0, 0, 0, bottom_pad), color = banner_bg_color, child = render.Column(children = schedule)),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Station",
                desc = "Select a station",
                icon = "signsPost",
                default = DEFAULT_STATION,
                options = regional_rail_station_options(),
            ),
            schema.Dropdown(
                id = "direction",
                name = "Direction",
                desc = "Select a direction",
                icon = "compass",
                default = DEFAULT_DIRECTION,
                options = [
                    schema.Option(
                        display = "N",
                        value = "N",
                    ),
                    schema.Option(
                        display = "S",
                        value = "S",
                    ),
                ],
            ),
            schema.Text(
                id = "banner",
                name = "Custom banner text",
                desc = "Custom text for the top bar. Leave blank to show the selected route.",
                icon = "penNib",
                default = "",
            ),
            schema.Toggle(
                id = "use_custom_banner_color",
                name = "Use custom banner color",
                desc = "Use a custom background color for the top banner.",
                icon = "palette",
                default = False,
            ),
            schema.Color(
                id = "custom_banner_color",
                name = "Custom banner color",
                desc = "A custom background color for the top banner.",
                icon = "brush",
                default = "#7AB0FF",
            ),
            schema.Toggle(
                id = "use_custom_text_color",
                name = "Use custom text color",
                desc = "Use a custom text color for the top banner.",
                icon = "palette",
                default = False,
            ),
            schema.Color(
                id = "custom_text_color",
                name = "Custom text color",
                desc = "A custom text color for the top banner.",
                icon = "brush",
                default = "#FFFFFF",
            ),
        ],
    )
