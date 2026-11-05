"""
Applet: DC Metro Arrivals
Summary: WMATA trains and buses
Description: Live Metrorail and Metrobus arrivals from WMATA's own API, merged into one list sorted by time. Filter by line, route or destination, and hide anything you can't walk to in time.
Author: Nick Baumann
"""

load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")

RAIL_URL = "https://api.wmata.com/StationPrediction.svc/json/GetPrediction/"
BUS_URL = "https://api.wmata.com/NextBusService.svc/json/jPredictions"
CACHE_TTL = 30
MAX_BUS_STOPS = 3

LINES = {
    "RD": ("#BF0D3E", "#FFFFFF"),
    "OR": ("#ED8B00", "#000000"),
    "YL": ("#FFD100", "#000000"),
    "GR": ("#00B140", "#000000"),
    "BL": ("#009CDE", "#000000"),
    "SV": ("#919D9D", "#000000"),
}
BUS_BADGE = ("#3A3A3A", "#FFFFFF")

DEST_COLOR = "#FFFFFF"
MIN_COLOR = "#FFB000"
NOW_COLOR = "#FF5050"
NOTE_COLOR = "#9AA0A6"

ABBREVIATIONS = [
    (" Station", " Sta"),
    (" Street", " St"),
    (" Avenue", " Ave"),
    (" Road", " Rd"),
    (" Boulevard", " Blvd"),
    (" Parkway", " Pkwy"),
    (" Pike", " Pk"),
    (" Center", " Ctr"),
    (" Heights", " Hts"),
]

DEMO_ROWS = [
    {"badge": "RD", "bg": LINES["RD"][0], "fg": LINES["RD"][1], "dest": "Glenmont", "sort": -1, "label": "BRD"},
    {"badge": "C53", "bg": BUS_BADGE[0], "fg": BUS_BADGE[1], "dest": "Congress Hts", "sort": 3, "label": "3"},
    {"badge": "RD", "bg": LINES["RD"][0], "fg": LINES["RD"][1], "dest": "Shady Gr", "sort": 6, "label": "6"},
    {"badge": "D10", "bg": BUS_BADGE[0], "fg": BUS_BADGE[1], "dest": "Union Sta", "sort": 9, "label": "9"},
    {"badge": "SV", "bg": LINES["SV"][0], "fg": LINES["SV"][1], "dest": "Ashburn", "sort": 11, "label": "11"},
    {"badge": "BL", "bg": LINES["BL"][0], "fg": LINES["BL"][1], "dest": "Franconia", "sort": 14, "label": "14"},
    {"badge": "C53", "bg": BUS_BADGE[0], "fg": BUS_BADGE[1], "dest": "Congress Hts", "sort": 17, "label": "17"},
]

def layout():
    width, height = canvas.size()
    if canvas.is2x():
        return struct(
            width = width,
            height = height,
            row_h = 16,
            font = "terminus-16",
            badge_font = "terminus-12",
            pad = 2,
            gap = 3,
            delay = 25,
        )
    return struct(
        width = width,
        height = height,
        row_h = 8,
        font = "tb-8",
        badge_font = "CG-pixel-3x5-mono",
        pad = 1,
        gap = 2,
        delay = 50,
    )

def split_list(value):
    if not value:
        return []
    out = []
    for part in value.replace(";", ",").split(","):
        part = part.strip()
        if part:
            out.append(part)
    return out

def to_int(value, default):
    if value == None:
        return default
    if type(value) in ("int", "float"):
        return int(value)
    s = str(value).strip()
    if s.isdigit():
        return int(s)
    return default

def shorten(text):
    for long, short in ABBREVIATIONS:
        text = text.replace(long, short)
    return text.strip()

def fetch_rail(station, api_key, line_filter, dest_filters, walk):
    """Returns (rows, error)."""
    resp = http.get(RAIL_URL + station, headers = {"api_key": api_key}, ttl_seconds = CACHE_TTL)
    if resp.status_code != 200:
        return [], resp.status_code
    body = resp.json()
    trains = []
    if type(body) == "dict" and body.get("Trains"):
        trains = body["Trains"]

    rows = []
    for t in trains:
        line = t.get("Line") or ""
        if line not in LINES:
            continue  # "No Passenger" trains, specials, "--"
        if line_filter and line_filter != "ALL" and line != line_filter:
            continue

        short_dest = t.get("Destination") or ""
        long_dest = t.get("DestinationName") or short_dest
        if dest_filters:
            hay = (short_dest + " " + long_dest).lower()
            matched = False
            for f in dest_filters:
                if f.lower() in hay:
                    matched = True
                    break
            if not matched:
                continue

        mins = (t.get("Min") or "").strip()
        if mins == "BRD":
            sort, label = -1, "BRD"
        elif mins == "ARR":
            sort, label = 0, "ARR"
        elif mins.isdigit():
            sort, label = int(mins), mins
        else:
            continue  # "---" or blank: no prediction
        if max(sort, 0) < walk:
            continue

        rows.append({
            "badge": line,
            "bg": LINES[line][0],
            "fg": LINES[line][1],
            "dest": short_dest or long_dest,
            "sort": sort,
            "label": label,
        })
    return rows, None

def fetch_bus(stop_id, api_key, route_filters, walk):
    """Returns (rows, error)."""
    resp = http.get(BUS_URL, params = {"StopID": stop_id}, headers = {"api_key": api_key}, ttl_seconds = CACHE_TTL)
    if resp.status_code != 200:
        return [], resp.status_code
    body = resp.json()
    preds = []
    if type(body) == "dict" and body.get("Predictions"):
        preds = body["Predictions"]

    wanted = [r.upper() for r in route_filters]
    rows = []
    for p in preds:
        route = str(p.get("RouteID") or "").strip()
        if not route:
            continue
        if wanted and route.upper() not in wanted:
            continue
        mins = to_int(p.get("Minutes"), -100)
        if mins == -100 or mins < walk:
            continue

        direction = str(p.get("DirectionText") or "")

        # "North to Silver Spring Station" -> "Silver Spring Sta"
        if " to " in direction:
            direction = direction.split(" to ", 1)[1]

        rows.append({
            "badge": route,
            "bg": BUS_BADGE[0],
            "fg": BUS_BADGE[1],
            "dest": shorten(direction) or route,
            "sort": mins,
            "label": "NOW" if mins == 0 else str(mins),
        })
    return rows, None

def error_text(code):
    if code in (401, 403):
        return "WMATA rejected the API key. Check it in settings."
    if code == 429:
        return "WMATA rate limit hit. Try a longer refresh."
    return "WMATA unavailable (%s)" % code

def render_row(row, l, badge_w, min_w):
    dest_w = l.width - badge_w - l.gap - min_w - l.gap
    label_color = NOW_COLOR if row["sort"] <= 0 else MIN_COLOR
    return render.Row(
        cross_align = "center",
        children = [
            render.Box(
                width = badge_w,
                height = l.row_h - 1,
                color = row["bg"],
                child = render.Text(row["badge"], font = l.badge_font, color = row["fg"]),
            ),
            render.Box(width = l.gap, height = l.row_h),
            render.Marquee(
                width = dest_w,
                child = render.Text(row["dest"], font = l.font, color = DEST_COLOR),
            ),
            render.Box(width = l.gap, height = l.row_h),
            render.Box(
                width = min_w,
                height = l.row_h,
                child = render.Row(
                    expanded = True,
                    main_align = "end",
                    children = [render.Text(row["label"], font = l.font, color = label_color)],
                ),
            ),
        ],
    )

def render_message(l, message, rows = []):
    """Any rows that fit, then a scrolling message on the last line."""
    max_rows = l.height // l.row_h
    shown = rows[:max_rows - 1]
    children = render_rows(l, shown)
    children.append(
        render.Box(
            height = l.row_h,
            child = render.Marquee(
                width = l.width,
                align = "center",
                child = render.Text(message, font = l.font, color = NOTE_COLOR),
            ),
        ),
    )
    return render.Root(
        delay = l.delay,
        child = render.Column(
            main_align = "start" if shown else "center",
            expanded = True,
            children = children,
        ),
    )

def render_rows(l, rows):
    if not rows:
        return []

    # Size the badge and minutes columns to their widest entry so the
    # destination gets every remaining pixel and columns line up.
    badge_w = 0
    min_w = 0
    for r in rows:
        badge_w = max(badge_w, render.Text(r["badge"], font = l.badge_font).size()[0])
        min_w = max(min_w, render.Text(r["label"], font = l.font).size()[0])
    badge_w += 2 * l.pad
    return [render_row(r, l, badge_w, min_w) for r in rows]

def sort_key(r):
    return (r["sort"], r["badge"])

def pick_fairly(groups, limit):
    """Take the soonest arrival from each source in turn until the display is
    full (so every source gets a row when there's room), then sort by time."""
    queues = [sorted(g, key = sort_key) for g in groups if g]
    picked = []
    for _ in range(limit):
        if len(picked) >= limit or not queues:
            break
        for q in queues:
            if q and len(picked) < limit:
                picked.append(q.pop(0))
        queues = [q for q in queues if q]
    return sorted(picked, key = sort_key)

def main(config):
    l = layout()
    max_rows = l.height // l.row_h

    api_key = (config.get("api_key") or "").strip()
    station = config.get("station") or ""
    if station == "NONE":
        station = ""
    stops = []
    for s in split_list(config.get("bus_stops") or ""):
        if s.isdigit() and s not in stops:
            stops.append(s)
    stops = stops[:MAX_BUS_STOPS]

    if not api_key:
        return render_message(l, "Demo data - add a free WMATA API key in settings", DEMO_ROWS)
    if not station and not stops:
        return render_message(l, "Pick a Metro station or bus stop in settings")

    walk_rail = to_int(config.get("walk_rail"), 0)
    walk_bus = to_int(config.get("walk_bus"), 0)

    # One group per source (the station, each bus stop) so a busy source
    # can't crowd the others off a small display.
    groups = []
    errors = []
    if station:
        got, err = fetch_rail(
            station,
            api_key,
            config.get("line") or "ALL",
            split_list(config.get("train_dest") or ""),
            walk_rail,
        )
        groups.append(got)
        if err:
            errors.append(err)
    for stop in stops:
        got, err = fetch_bus(stop, api_key, split_list(config.get("bus_routes") or ""), walk_bus)
        groups.append(got)
        if err:
            errors.append(err)

    rows = pick_fairly(groups, max_rows)

    if errors and not rows:
        return render_message(l, error_text(errors[0]))
    if not rows:
        return render_message(l, "No trains or buses predicted right now")

    return render.Root(
        delay = l.delay,
        max_age = 60,
        child = render.Column(children = render_rows(l, rows)),
    )

def walk_options():
    opts = [schema.Option(display = "0 min (show everything)", value = "0")]
    for m in [1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 15, 20]:
        opts.append(schema.Option(display = "%d min" % m, value = str(m)))
    return opts

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "WMATA API key",
                desc = "Free at developer.wmata.com: sign up, then subscribe to the Default Tier product and copy the primary key.",
                icon = "key",
                secret = True,
            ),
            schema.Dropdown(
                id = "station",
                name = "Metro station",
                desc = "Station for train predictions. Transfer stations include every platform.",
                icon = "trainSubway",
                default = "NONE",
                options = STATION_OPTIONS,
            ),
            schema.Dropdown(
                id = "line",
                name = "Line",
                desc = "Only show trains on this line.",
                icon = "codeMerge",
                default = "ALL",
                options = LINE_OPTIONS,
            ),
            schema.Text(
                id = "train_dest",
                name = "Only trains to",
                desc = "Optional, comma-separated. Matches part of the destination, e.g. 'Glenmont, Silver Spr' to see one direction.",
                icon = "arrowRight",
            ),
            schema.Dropdown(
                id = "walk_rail",
                name = "Walk time to station",
                desc = "Hide trains arriving sooner than you could make it.",
                icon = "personWalking",
                default = "0",
                options = walk_options(),
            ),
            schema.Text(
                id = "bus_stops",
                name = "Bus stop IDs",
                desc = "Up to 3, comma-separated. The 7-digit number on the stop sign or at buseta.wmata.com, e.g. 1001195.",
                icon = "bus",
            ),
            schema.Text(
                id = "bus_routes",
                name = "Only these bus routes",
                desc = "Optional, comma-separated route names as shown on the bus, e.g. 'C53, D10'.",
                icon = "route",
            ),
            schema.Dropdown(
                id = "walk_bus",
                name = "Walk time to bus stop",
                desc = "Hide buses arriving sooner than you could make it.",
                icon = "personWalking",
                default = "0",
                options = walk_options(),
            ),
        ],
    )

LINE_OPTIONS = [
    schema.Option(display = "All lines", value = "ALL"),
    schema.Option(display = "Red", value = "RD"),
    schema.Option(display = "Orange", value = "OR"),
    schema.Option(display = "Yellow", value = "YL"),
    schema.Option(display = "Green", value = "GR"),
    schema.Option(display = "Blue", value = "BL"),
    schema.Option(display = "Silver", value = "SV"),
]

# Transfer stations have one code per platform level; the API accepts both
# comma-separated, so they appear once here with every platform included.
STATIONS = [
    ("Addison Road", "G03"),
    ("Anacostia", "F06"),
    ("Archives-Navy Memorial-Penn Quarter", "F02"),
    ("Arlington Cemetery", "C06"),
    ("Ashburn", "N12"),
    ("Ballston-MU", "K04"),
    ("Benning Road", "G01"),
    ("Bethesda", "A09"),
    ("Braddock Road", "C12"),
    ("Branch Ave", "F11"),
    ("Brookland-CUA", "B05"),
    ("Capitol Heights", "G02"),
    ("Capitol South", "D05"),
    ("Cheverly", "D11"),
    ("Clarendon", "K02"),
    ("Cleveland Park", "A05"),
    ("College Park-U of Md", "E09"),
    ("Columbia Heights", "E04"),
    ("Congress Heights", "F07"),
    ("Court House", "K01"),
    ("Crystal City", "C09"),
    ("Deanwood", "D10"),
    ("Downtown Largo", "G05"),
    ("Dunn Loring-Merrifield", "K07"),
    ("Dupont Circle", "A03"),
    ("East Falls Church", "K05"),
    ("Eastern Market", "D06"),
    ("Eisenhower Avenue", "C14"),
    ("Farragut North", "A02"),
    ("Farragut West", "C03"),
    ("Federal Center SW", "D04"),
    ("Federal Triangle", "D01"),
    ("Foggy Bottom-GWU", "C04"),
    ("Forest Glen", "B09"),
    ("Fort Totten", "B06,E06"),
    ("Franconia-Springfield", "J03"),
    ("Friendship Heights", "A08"),
    ("Gallery Place-Chinatown", "B01,F01"),
    ("Georgia Ave-Petworth", "E05"),
    ("Glenmont", "B11"),
    ("Greenbelt", "E10"),
    ("Greensboro", "N03"),
    ("Grosvenor-Strathmore", "A11"),
    ("Herndon", "N08"),
    ("Huntington", "C15"),
    ("Hyattsville Crossing", "E08"),
    ("Innovation Center", "N09"),
    ("Judiciary Square", "B02"),
    ("King St-Old Town", "C13"),
    ("Landover", "D12"),
    ("L'Enfant Plaza", "D03,F03"),
    ("Loudoun Gateway", "N11"),
    ("McLean", "N01"),
    ("McPherson Square", "C02"),
    ("Medical Center", "A10"),
    ("Metro Center", "A01,C01"),
    ("Minnesota Ave", "D09"),
    ("Morgan Boulevard", "G04"),
    ("Mt Vernon Sq/7th St-Convention Center", "E01"),
    ("Navy Yard-Ballpark", "F05"),
    ("Naylor Road", "F09"),
    ("New Carrollton", "D13"),
    ("NoMa-Gallaudet U", "B35"),
    ("North Bethesda", "A12"),
    ("Pentagon", "C07"),
    ("Pentagon City", "C08"),
    ("Potomac Ave", "D07"),
    ("Potomac Yard", "C11"),
    ("Reston Town Center", "N07"),
    ("Rhode Island Ave-Brentwood", "B04"),
    ("Rockville", "A14"),
    ("Ronald Reagan Washington National Airport", "C10"),
    ("Rosslyn", "C05"),
    ("Shady Grove", "A15"),
    ("Shaw-Howard U", "E02"),
    ("Silver Spring", "B08"),
    ("Smithsonian", "D02"),
    ("Southern Avenue", "F08"),
    ("Spring Hill", "N04"),
    ("Stadium-Armory", "D08"),
    ("Suitland", "F10"),
    ("Takoma", "B07"),
    ("Tenleytown-AU", "A07"),
    ("Twinbrook", "A13"),
    ("Tysons", "N02"),
    ("U Street/African-Amer Civil War Memorial/Cardozo", "E03"),
    ("Union Station", "B03"),
    ("Van Dorn Street", "J02"),
    ("Van Ness-UDC", "A06"),
    ("Vienna/Fairfax-GMU", "K08"),
    ("Virginia Square-GMU", "K03"),
    ("Washington Dulles International Airport", "N10"),
    ("Waterfront", "F04"),
    ("West Falls Church", "K06"),
    ("West Hyattsville", "E07"),
    ("Wheaton", "B10"),
    ("Wiehle-Reston East", "N06"),
    ("Woodley Park-Zoo/Adams Morgan", "A04"),
]

STATION_OPTIONS = [schema.Option(display = "None (buses only)", value = "NONE")] + [
    schema.Option(display = name, value = code)
    for name, code in STATIONS
]
