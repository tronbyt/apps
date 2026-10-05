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
        "Airport Terminal A",
        "Airport Terminal B",
        "Airport Terminal C D",
        "Airport Terminal E F",
        "Allegheny",
        "Allen Lane",
        "Ambler",
        "Angora",
        "Ardmore",
        "Ardsley",
        "Bala",
        "Berwyn",
        "Bethayres",
        "Bridesburg",
        "Bristol",
        "Bryn Mawr",
        "Carpenter",
        "Chalfont",
        "Chelten Avenue",
        "Cheltenham",
        "Chester TC",
        "Chestnut Hill East",
        "Chestnut Hill West",
        "Churchmans Crossing",
        "Claymont",
        "Clifton-Aldan",
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
        "Delaware Valley College",
        "Devon",
        "Downingtown",
        "Doylestown",
        "East Falls",
        "Eastwick",
        "Eddington",
        "Eddystone",
        "Elkins Park",
        "Elm St",
        "Elwyn",
        "Exton",
        "Fern Rock TC",
        "Fernwood-Yeadon",
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
        "Holmesburg Jct",
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

API_BASE = "https://www3.septa.org/api"
API_SCHEDULE = API_BASE + "/Arrivals"
DEFAULT_STATION = "Wayne Junction"
DEFAULT_DIRECTION = "S"

# Every train's "line" field is one of these 13 names (confirmed against
# live Arrivals data). Each gets its own toggle, checked by default, so
# riders can hide lines they don't use — useful at a hub station like
# Suburban Station or Jefferson Station where every line's trains show up
# in the same departure board.
REGIONAL_RAIL_LINES = [
    ("air", "Airport"),
    ("che", "Chestnut Hill East"),
    ("chw", "Chestnut Hill West"),
    ("cyn", "Cynwyd"),
    ("fox", "Fox Chase"),
    ("lan", "Lansdale/Doylestown"),
    ("med", "Media/Wawa"),
    ("nor", "Manayunk/Norristown"),
    ("pao", "Paoli/Thorndale"),
    ("tre", "Trenton"),
    ("war", "Warminster"),
    ("wil", "Wilmington/Newark"),
    ("wtr", "West Trenton"),
]

def enabled_lines_from_config(config):
    enabled = {}
    for suffix, name in REGIONAL_RAIL_LINES:
        enabled[name] = config.bool("line_" + suffix, True)
    return enabled

def line_toggle_fields():
    fields = []
    for suffix, name in REGIONAL_RAIL_LINES:
        fields.append(
            schema.Toggle(
                id = "line_" + suffix,
                name = name,
                desc = "Show " + name + " Line departures.",
                icon = "train",
                default = True,
            ),
        )
    return fields

# Maps a station to which compass direction ("N" or "S") its Arrivals API
# result labels as Inbound (toward Center City). Determined by cross-checking
# live trip origin/destination against each of the 13 lines' known direction
# (SEPTA's ex-Reading-heritage lines run Inbound=Southbound; ex-PRR lines run
# the opposite) — not derivable from compass direction alone, since lines
# radiate from Center City in every direction. Stations on Cynwyd or Fox
# Chase are omitted (couldn't get a live sample to confirm — both had zero
# scheduled trains at verification time), as are the handful of core hub
# stations (30th Street, Suburban, Jefferson, Temple University, Penn
# Medicine) where every line converges and "inbound/outbound" stops being
# a meaningful distinction; both fall back to plain compass labels.
STATION_INBOUND_DIRECTION = {
    "49th Street": "N",
    "Airport Terminal A": "N",
    "Airport Terminal B": "N",
    "Airport Terminal C D": "N",
    "Airport Terminal E F": "N",
    "Allegheny": "S",
    "Allen Lane": "N",
    "Ambler": "S",
    "Angora": "N",
    "Ardmore": "N",
    "Ardsley": "S",
    "Berwyn": "N",
    "Bethayres": "S",
    "Bridesburg": "N",
    "Bristol": "N",
    "Bryn Mawr": "N",
    "Carpenter": "N",
    "Chalfont": "S",
    "Chelten Avenue": "N",
    "Chester TC": "N",
    "Chestnut Hill East": "S",
    "Chestnut Hill West": "N",
    "Churchmans Crossing": "N",
    "Claymont": "N",
    "Clifton-Aldan": "N",
    "Colmar": "S",
    "Conshohocken": "S",
    "Cornwells Heights": "N",
    "Crestmont": "S",
    "Croydon": "N",
    "Crum Lynne": "N",
    "Curtis Park": "N",
    "Darby": "N",
    "Daylesford": "N",
    "Delaware Valley College": "S",
    "Devon": "N",
    "Downingtown": "N",
    "Doylestown": "S",
    "East Falls": "S",
    "Eastwick": "N",
    "Eddington": "N",
    "Eddystone": "N",
    "Elkins Park": "S",
    "Elm St": "S",
    "Elwyn": "N",
    "Exton": "N",
    "Fern Rock TC": "S",
    "Fernwood-Yeadon": "N",
    "Folcroft": "N",
    "Forest Hills": "S",
    "Fort Washington": "S",
    "Fortuna": "S",
    "Germantown": "S",
    "Gladstone": "N",
    "Glenolden": "N",
    "Glenside": "S",
    "Gravers": "S",
    "Gwynedd Valley": "S",
    "Hatboro": "S",
    "Haverford": "N",
    "Highland": "N",
    "Highland Avenue": "N",
    "Holmesburg Jct": "N",
    "Ivy Ridge": "S",
    "Jenkintown Wyncote": "S",
    "Langhorne": "S",
    "Lansdale": "S",
    "Lansdowne": "N",
    "Levittown": "N",
    "Link Belt": "S",
    "Main Street": "S",
    "Malvern": "N",
    "Manayunk": "S",
    "Marcus Hook": "N",
    "Meadowbrook": "S",
    "Media": "N",
    "Melrose Park": "S",
    "Merion": "N",
    "Miquon": "S",
    "Morton": "N",
    "Mount Airy": "S",
    "Moylan-Rose Valley": "N",
    "Narberth": "N",
    "Neshaminy Falls": "S",
    "New Britain": "S",
    "Newark": "N",
    "Noble": "S",
    "Norristown TC": "S",
    "North Broad": "S",
    "North Hills": "S",
    "North Philadelphia": "N",
    "North Wales": "S",
    "Norwood": "N",
    "Oreland": "S",
    "Overbrook": "N",
    "Paoli": "N",
    "Penllyn": "S",
    "Pennbrook": "S",
    "Philmont": "S",
    "Primos": "N",
    "Prospect Park": "N",
    "Queen Lane": "N",
    "Radnor": "N",
    "Ridley Park": "N",
    "Rosemont": "N",
    "Roslyn": "S",
    "Rydal": "S",
    "Secane": "N",
    "Sedgwick": "S",
    "Sharon Hill": "N",
    "Somerton": "S",
    "Spring Mill": "S",
    "St. Davids": "N",
    "St. Martins": "N",
    "Stenton": "S",
    "Strafford": "N",
    "Swarthmore": "N",
    "Tacony": "N",
    "Thorndale": "N",
    "Torresdale": "N",
    "Trenton": "N",
    "Trevose": "S",
    "Tulpehocken": "N",
    "Upsal": "N",
    "Villanova": "N",
    "Wallingford": "N",
    "Warminster": "S",
    "Washington Lane": "S",
    "Wawa": "N",
    "Wayne": "N",
    "Wayne Junction": "S",
    "West Trenton": "S",
    "Whitford": "N",
    "Willow Grove": "S",
    "Wilmington": "N",
    "Wissahickon": "S",
    "Wister": "S",
    "Woodbourne": "S",
    "Wyndmoor": "S",
    "Wynnewood": "N",
    "Yardley": "S",
}

def select_direction(station):
    inbound = STATION_INBOUND_DIRECTION.get(station)
    if inbound == None:
        options = [
            schema.Option(display = "Northbound", value = "N"),
            schema.Option(display = "Southbound", value = "S"),
        ]
    elif inbound == "N":
        options = [
            schema.Option(display = "Inbound (toward Center City)", value = "N"),
            schema.Option(display = "Outbound", value = "S"),
        ]
    else:
        options = [
            schema.Option(display = "Inbound (toward Center City)", value = "S"),
            schema.Option(display = "Outbound", value = "N"),
        ]

    return [
        schema.Dropdown(
            id = "direction",
            name = "Direction",
            desc = "Select a direction",
            icon = "compass",
            default = options[0].value,
            options = options,
        ),
    ]

def call_schedule_api(direction, station):
    # Over-fetch beyond the 4 we display: once a line filter is applied,
    # the first 4 raw results may not include 4 that survive it.
    r = http.get(API_SCHEDULE, params = {"station": station, "direction": direction, "results": "20"}, ttl_seconds = 30)

    # SEPTA returns HTTP 400 with {"error": "..."} for a station name it
    # doesn't recognize, and HTTP 200 with a normal-looking payload otherwise
    # — but that payload's shape still varies: a nested empty list [[]] when
    # there are simply no upcoming trains for this station/direction right
    # now (common for branch termini, or late at night), vs.
    # [{"Northbound": [...]}] / [{"Southbound": [...]}] when there are.
    # Every level below is checked before indexing so none of these shapes
    # can crash the render.
    if r.status_code != 200:
        return []

    schedule_raw = r.json()
    if type(schedule_raw) != "dict":
        return []

    day_values = schedule_raw.values()
    if len(day_values) < 1 or type(day_values[0]) != "list" or len(day_values[0]) < 1:
        return []

    direction_group = day_values[0][0]
    if type(direction_group) != "dict":
        return []

    dir_values = direction_group.values()
    if len(dir_values) < 1 or type(dir_values[0]) != "list":
        return []

    return dir_values[0]

def parse_status_delay(status):
    # SEPTA's regional rail "status" is either "On Time" or "N min" — and
    # that N is how late the train is running, *not* a countdown to
    # departure (verified against sched_time, which doesn't move regardless
    # of this value; two trains scheduled tens of minutes apart have shown
    # the identical "N min" at the same moment). "999 min" is the same
    # bogus/no-data sentinel pattern SEPTA uses on the bus side.
    if status == "On Time":
        return 0
    if status.endswith(" min"):
        prefix = status[:-4]
        if prefix.isdigit():
            mins = int(prefix)
            if mins < 900:
                return mins
    return None

def get_schedule(direction, station, scale, enabled_lines):
    schedule = call_schedule_api(direction, station)

    # Only keep trains on a line the rider has enabled. A line name we don't
    # recognize (a gap in our list, or SEPTA adding a new one) fails open
    # rather than silently hiding real service.
    schedule = [i for i in schedule if enabled_lines.get(i.get("line"), True)]
    schedule = schedule[:4]

    list_of_departures = []

    row_font = "tom-thumb" if scale == 1 else "terminus-12"
    row_height = 6 * scale
    time_width = 25 * scale
    text_width = 39 * scale
    min_rows = 4

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

        # Color the time itself by lateness (matching the bus apps' live
        # indicator), and only append a status label when we actually trust
        # it — the 999-sentinel case shows no delay info rather than a
        # fabricated one.
        delay_mins = parse_status_delay(i["status"])
        if delay_mins == None:
            time_color = text
            status_text = ""
        else:
            time_color = "#f00" if delay_mins > 5 else "#0f0"
            status_text = " - On time" if delay_mins == 0 else " - %dm late" % delay_mins

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
                            color = time_color,
                        ),
                    ),
                    render.Marquee(
                        child = render.Text(
                            i["train_id"] + " " + i["service_type"] + " to " + i["destination"] + status_text,
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
        list_of_departures = [render.Box(
            height = row_height,
            width = 64 * scale,
            color = "#000",
            child = render.Text("No departures", font = "tom-thumb" if scale == 1 else "tb-8"),
        )]

    # Pad with blank rows so the schedule always fills min_rows — otherwise
    # the accent bar below it rides up under a short departure list instead
    # of staying pinned to the bottom of the display.
    for i in range(len(list_of_departures), min_rows):
        background = "#222" if i % 2 == 1 else "#000"
        list_of_departures.append(render.Box(height = row_height, width = 64 * scale, color = background))

    return list_of_departures

def main(config):
    scale = 2 if canvas.is2x() else 1
    station = config.str("station", DEFAULT_STATION)
    direction = config.str("direction", DEFAULT_DIRECTION)
    user_text = config.str("banner", "")
    enabled_lines = enabled_lines_from_config(config)
    schedule = get_schedule(direction, station, scale, enabled_lines)
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
            schema.Generated(
                id = "direction",
                source = "station",
                handler = select_direction,
            ),
        ] + line_toggle_fields() + [
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
