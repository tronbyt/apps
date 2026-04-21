"""
Applet: Amtrak
Summary: Amtrak train arrivals
Description: Shows arriving and departing Amtrak trains at a station using RailRat data.
Author: tavdog
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

FONT_1X = "tom-thumb"
FONT_2X = "terminus-12"

API_URL = "https://api.amtraker.com/v3/all"

STATIONS = {
    "PDX": "Portland, OR",
    "SEA": "Seattle, WA",
    "LAX": "Los Angeles, CA",
    "CHI": "Chicago, IL",
    "WAS": "Washington, DC",
    "SAC": "Sacramento, CA",
    "EUG": "Eugene, OR",
    "SPK": "Spokane, WA",
    "BOS": "Boston, MA",
    "DEN": "Denver, CO",
    "VAC": "Vancouver, BC",
}

def font():
    return FONT_2X if canvas.is2x() else FONT_1X

def fetch_train_data():
    response = http.get(API_URL, ttl_seconds = 300)
    if response.status_code != 200:
        return None
    body = response.body()
    return json.decode(body)

def parse_trains(data, station_code):
    if data == None:
        return [], []

    arriving = []
    departing = []

    trains = data.get("trains", {})
    for train_list in trains.values():
        for train in train_list:
            stations = train.get("stations", [])
            origin = stations[0].get("code") if stations else ""
            dest = stations[-1].get("code") if stations else ""

            for stop in stations:
                if stop.get("code") != station_code:
                    continue

                status = stop.get("status", "")
                sch_arr = stop.get("schArr")
                sch_dep = stop.get("schDep")
                arr = stop.get("arr")
                dep = stop.get("dep")

                arriving.append({
                    "train": train.get("trainNum"),
                    "route": train.get("routeName"),
                    "origin": origin,
                    "destination": dest,
                    "status": status,
                    "sched_arr": sch_arr,
                    "sched_dep": sch_dep,
                    "actual_arr": arr,
                    "actual_dep": dep,
                })
                departing.append({
                    "train": train.get("trainNum"),
                    "route": train.get("routeName"),
                    "origin": origin,
                    "destination": dest,
                    "status": status,
                    "sched_arr": sch_arr,
                    "sched_dep": sch_dep,
                    "actual_arr": arr,
                    "actual_dep": dep,
                })

    arriving = sorted(arriving, key = lambda x: x["sched_arr"] or "9999-12-31")
    departing = sorted(departing, key = lambda x: x["sched_dep"] or "9999-12-31")

    return arriving, departing

def format_time(iso_str):
    if not iso_str:
        return "—"
    dt = time.parse_time(iso_str, "2006-01-02T15:04:05-07:00", time.tz())
    if dt:
        h = dt.hour
        m = dt.minute
        hour_str = "0" + str(h) if h < 10 else str(h)
        min_str = "0" + str(m) if m < 10 else str(m)
        return hour_str + ":" + min_str
    return "—"

def variance_str(sched_iso, actual_iso):
    if not sched_iso or not actual_iso:
        return ""
    sched = time.parse_time(sched_iso, "2006-01-02T15:04:05-07:00", time.tz())
    actual = time.parse_time(actual_iso, "2006-01-02T15:04:05-07:00", time.tz())
    if not sched or not actual:
        return ""
    diff = (actual.minute - sched.minute + (actual.hour - sched.hour) * 60)
    if diff == 0:
        return "on time"
    elif diff < 0:
        return str(abs(diff)) + "m early"
    else:
        return "+" + str(diff) + "m late"

def render_train(train, section_type, mins_text):
    color = "#0f0" if section_type == "arriving" else "#f80"
    label = "ARRIVING" if section_type == "arriving" else "DEPARTED"
    route = train.get("route", "")
    route_last = route.split(" ")[-1] if route else ""
    train_num = str(train.get("train", ""))

    sched_arr = train.get("sched_arr", "")
    actual_arr = train.get("actual_arr", "")
    sched_dep = train.get("sched_dep", "")
    actual_dep = train.get("actual_dep", "")

    time_str = format_time(actual_arr) if section_type == "arriving" else format_time(actual_dep)
    if time_str == "—":
        time_str = format_time(sched_arr) if section_type == "arriving" else format_time(sched_dep)

    variance = variance_str(sched_arr if section_type == "arriving" else sched_dep, actual_arr if section_type == "arriving" else actual_dep)

    return [
        render.Row(
            expanded = True,
            main_align = "center",
            children = [
                render.Text(content = train_num + " " + route_last, font = font(), color = "#0af"),
            ],
        ),
        render.Row(
            expanded = True,
            main_align = "center",
            children = [
                render.Text(content = label, font = font(), color = color),
                render.Text(content = " " + time_str, font = font(), color = "#fff"),
            ],
        ),
        render.Row(
            expanded = True,
            main_align = "center",
            children = [
                render.Text(content = mins_text + (" min" if section_type == "arriving" else " min ago"), font = font(), color = "#888"),
            ],
        ),
        render.Row(
            expanded = True,
            main_align = "center",
            children = [
                render.Text(content = variance if variance else "", font = font(), color = "#080"),
            ],
        ),
        render.Row(
            expanded = True,
            main_align = "center",
            children = [
                render.Text(content = train.get("origin", ""), font = font(), color = "#aaa"),
                render.Text(content = " -> ", font = font(), color = "#888"),
                render.Text(content = train.get("destination", ""), font = font(), color = "#aaa"),
            ],
        ),
    ]

def main(config):
    station = config.get("station", "PDX")
    threshold = int(config.get("threshold", "60"))
    manual_station = config.get("manual_station", "")
    if manual_station:
        station = manual_station

    data = fetch_train_data()
    if not data:
        return render.Root(
            child = render.Column(
                expanded = True,
                main_align = "center",
                children = [
                    render.Text(content = "Failed to fetch data", font = font(), color = "#f00"),
                    render.Text(content = "for " + station, font = font()),
                ],
            ),
        )

    now = time.now().in_location(time.tz())

    arriving, departing = parse_trains(data, station)

    def time_to_minutes(iso_str):
        if not iso_str:
            return None
        dt = time.parse_time(iso_str, "2006-01-02T15:04:05-07:00", time.tz())
        if not dt:
            return None
        diff = (dt.hour * 60 + dt.minute) - (now.hour * 60 + now.minute)
        if dt.year < now.year or (dt.year == now.year and dt.month < now.month) or (dt.year == now.year and dt.month == now.month and dt.day < now.day):
            diff -= 24 * 60
        elif diff < -12 * 60:
            diff += 24 * 60
        if diff > 12 * 60:
            diff -= 24 * 60
        return diff

    best_arriving = None
    best_arriving_mins = None
    best_departing = None
    best_departing_mins = None

    for train in arriving:
        arr = train.get("actual_arr") or train.get("sched_arr")
        dep = train.get("actual_dep") or train.get("sched_dep")
        mins = time_to_minutes(arr)
        if mins != None and mins >= 0 and mins <= threshold:
            if best_arriving_mins == None or mins < best_arriving_mins:
                best_arriving = train
                best_arriving_mins = mins

    for train in departing:
        arr = train.get("actual_arr") or train.get("sched_arr")
        dep = train.get("actual_dep") or train.get("sched_dep")
        mins = time_to_minutes(dep)
        if mins != None:
            if mins > 0:
                mins = -mins
            if mins >= -threshold and mins <= 0:
                if best_departing_mins == None or mins > best_departing_mins:
                    best_departing = train
                    best_departing_mins = mins

    if not best_arriving and not best_departing:
        return []

    best_train = None
    best_mins = None
    best_type = None

    if best_arriving and best_arriving_mins != None:
        best_train = best_arriving
        best_mins = best_arriving_mins
        best_type = "arriving"

    if best_departing and best_departing_mins != None:
        abs_departing = abs(best_departing_mins)
        if best_train == None or abs_departing < best_mins:
            best_train = best_departing
            best_mins = abs_departing
            best_type = "departed"

    if not best_train:
        return []

    print("DEBUG: %s %s actual=%s/%s sched=%s/%s variance=%s" % (
        best_train.get("train"),
        best_type,
        best_train.get("actual_arr") or "—",
        best_train.get("actual_dep") or "—",
        best_train.get("sched_arr") or "—",
        best_train.get("sched_dep") or "—",
        variance_str(best_train.get("sched_arr"), best_train.get("actual_arr")) if best_type == "arriving" else variance_str(best_train.get("sched_dep"), best_train.get("actual_dep")),
    ))

    children = [
        render.Row(
            expanded = True,
            main_align = "center",
            children = [
                render.Text(content = "Am", font = font(), color = "#9a0303"),
                render.Text(content = "trak", font = font(), color = "#02028c"),
                render.Text(content = " " + station, font = font(), color = "#888"),
            ],
        ),
    ]

    mins_text = str(best_mins) if best_mins != None else ""
    children.extend(render_train(best_train, best_type, mins_text))

    return render.Root(
        child = render.Column(
            expanded = True,
            children = children,
        ),
    )

def get_schema():
    station_options = [
        schema.Option(display = name, value = code)
        for code, name in STATIONS.items()
    ]

    threshold_options = [
        schema.Option(display = "5 minutes", value = "5"),
        schema.Option(display = "10 minutes", value = "10"),
        schema.Option(display = "30 minutes", value = "30"),
        schema.Option(display = "60 minutes", value = "60"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Station",
                desc = "Amtrak station code to display",
                icon = "train",
                default = "PDX",
                options = station_options,
            ),
            schema.Text(
                id = "manual_station",
                name = "Manual Station ID",
                desc = "Override station with a custom 3-letter station code",
                icon = "pen",
                default = "",
            ),
            schema.Dropdown(
                id = "threshold",
                name = "Time window",
                desc = "Show trains arriving within this many minutes",
                icon = "clock",
                default = "60",
                options = threshold_options,
            ),
        ],
    )
