"""
Applet: Amtrak
Summary: Amtrak train arrivals
Description: Shows arriving and departing Amtrak trains at a station using RailRat data.
Author: tavdog
"""

load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

FONT_1X = "tom-thumb"
FONT_2X = "terminus-12"

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

def fetch_station_data(station_code):
    url = "https://railrat.net/stations/" + station_code + "/"
    response = http.get(url, ttl_seconds = 60)
    if response.status_code != 200:
        return None
    return response.body()

def parse_trains(html_content, current_date):
    arriving = []
    departing = []

    content = html_content

    arriving_start = content.find("Arriving Trains")
    departing_start = content.find("Departed Trains")

    arriving_section = ""
    departing_section = ""

    if arriving_start > 0:
        if departing_start > arriving_start:
            arriving_section = content[arriving_start:departing_start]
        else:
            arriving_section = content[arriving_start:arriving_start + 5000]

    if departing_start > 0:
        end_marker = content.find("Connecting Services", departing_start)
        if end_marker > 0:
            departing_section = content[departing_start:end_marker]
        else:
            departing_section = content[departing_start:departing_start + 5000]

    def extract_train(text, section_date):
        trains = []

        train_blocks = []
        parts = text.split("<a href=\"/trains/")
        for part in parts[1:]:
            end_idx = part.find("</ul></div></li>")
            if end_idx > 0:
                block = "<a href=\"/trains/" + part[:end_idx]
                train_blocks.append(block)

        for block in train_blocks:
            time_str = ""
            time_match = block.split("<a")[0].strip().split("\n")[-1].strip()
            if ":" in time_match and time_match[0].isdigit():
                time_parts = time_match.split(":")
                if len(time_parts) >= 2:
                    time_str = time_parts[0] + ":" + time_parts[1].split(" ")[0]

            name_str = ""
            name_start = block.find(">", block.find("<a href=\"/trains/"))
            name_end = block.find("</a>", name_start)
            if name_start > 0 and name_end > 0:
                name_str = block[name_start + 1:name_end]

            origin = ""
            dest = ""
            sched_time = ""
            if "&rarr;" in block:
                route_parts = block.split("&rarr;")
                origin = route_parts[0].split("[")[-1].replace("]", "").strip()
                dest = route_parts[1].split("[")[1].split("]")[0].strip()

            if "est." in block:
                est_match = block.split("est.")[1]
                parts = est_match.split(",")[0].split(" ")
                for p in parts:
                    if ":" in p:
                        sched_time = p
            elif "act." in block:
                act_match = block.split("act.")[1]
                parts = act_match.split(",")[0].split(" ")
                for p in parts:
                    if ":" in p:
                        sched_time = p
            elif "Ar sch." in block:
                ar_match = block.split("Ar sch.")[1].split(",")[0].split("<")[0].split(">")[-1].strip()
                sched_time = ar_match
            elif "Dp sch." in block:
                ar_match = block.split("Dp sch.")[1].split(",")[0].split("<")[0].split(">")[-1].strip()
                sched_time = ar_match

            if name_str and sched_time:
                date_str = "/" + section_date
                if date_str in block:
                    trains.append({
                        "time": time_str,
                        "name": name_str,
                        "from": origin,
                        "to": dest,
                        "sched_time": sched_time,
                    })

        return trains

    arriving = extract_train(arriving_section, current_date)
    departing = extract_train(departing_section, current_date)

    arriving = [arriving[len(arriving) - 1 - i] for i in range(len(arriving))]
    departing = [departing[len(departing) - 1 - i] for i in range(len(departing))]

    return arriving, departing

def render_train(train, section_type, mins_text):
    color = "#0f0" if section_type == "arriving" else "#f80"
    label = "ARRIVING" if section_type == "arriving" else "DEPARTED"
    time_str = train.get("sched_time", "")
    name_parts = train.get("name", "").split()
    name = " ".join(name_parts[-2:]) if len(name_parts) >= 2 else train.get("name", "")

    return [
        render.Row(
            expanded = True,
            main_align = "center",
            children = [
                render.Text(content = name, font = font(), color = "#0af"),
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
                render.Text(content = train.get("from", ""), font = font(), color = "#aaa"),
                render.Text(content = " -> ", font = font(), color = "#888"),
                render.Text(content = train.get("to", ""), font = font(), color = "#aaa"),
            ],
        ),
    ]

def main(config):
    station = config.get("station", "PDX")
    threshold = int(config.get("threshold", "60"))
    manual_station = config.get("manual_station", "")
    if manual_station:
        station = manual_station

    html = fetch_station_data(station)
    if not html:
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
    current_date = now.format("02")

    arriving, departing = parse_trains(html, current_date)

    def time_to_minutes(time_str):
        if not time_str:
            return None
        parts = time_str.split(":")
        if len(parts) >= 2:
            hours = int(parts[0])
            mins = int(parts[1])
            now_h = now.hour
            now_m = now.minute
            diff = (hours * 60 + mins) - (now_h * 60 + now_m)
            if diff < -12 * 60:
                diff += 24 * 60
            if diff > 12 * 60:
                diff -= 24 * 60
            return diff
        return None

    best_arriving = None
    best_arriving_mins = None
    best_departing = None
    best_departing_mins = None

    for train in arriving:
        mins = time_to_minutes(train.get("sched_time", ""))
        if mins != None and mins >= 0 and mins <= threshold:
            if best_arriving_mins == None or mins < best_arriving_mins:
                best_arriving = train
                best_arriving_mins = mins

    for train in departing:
        mins = time_to_minutes(train.get("sched_time", ""))
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
