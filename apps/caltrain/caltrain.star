"""
Applet: Caltrain
Summary: Caltrain Departures
Description: Check the departures for your nearest Caltrain stop, the one near your work, or anywhere in between.
Author: quacksire
"""

# Using [MTC's Open Data API](https://511.org/open-data/transit) with a BYOK (Bring Your Own Key) system as there is throttling for the API.
#
# You don't want to cache the time sensitive responses
#
# Caltrain stop ids are 5 digits long, however there's two ids for each stop, XXXX1 for northbound and XXXX2 for southbound

load("caltrain_logo.webp", CT_LOGO_FILE = "file")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
#

STATIC_STATIONS = [
    {"id": "7002", "Name": "22nd Street"},
    {"id": "7003", "Name": "Bayshore"},
    {"id": "7012", "Name": "Belmont"},
    {"id": "7029", "Name": "Blossom Hill"},
    {"id": "7007", "Name": "Broadway"},
    {"id": "7008", "Name": "Burlingame"},
    {"id": "7019", "Name": "California Avenue"},
    {"id": "7028", "Name": "Capitol"},
    {"id": "7025", "Name": "College Park"},
    {"id": "7032", "Name": "Gilroy"},
    {"id": "7010", "Name": "Hayward Park"},
    {"id": "7011", "Name": "Hillsdale"},
    {"id": "7023", "Name": "Lawrence"},
    {"id": "7016", "Name": "Menlo Park"},
    {"id": "7006", "Name": "Millbrae"},
    {"id": "7030", "Name": "Morgan Hill"},
    {"id": "7021", "Name": "Mountain View"},
    {"id": "7017", "Name": "Palo Alto"},
    {"id": "7014", "Name": "Redwood City"},
    {"id": "7020", "Name": "San Antonio"},
    {"id": "7005", "Name": "San Bruno"},
    {"id": "7013", "Name": "San Carlos"},
    {"id": "7001", "Name": "San Francisco"},
    {"id": "7026", "Name": "San Jose"},
    {"id": "7031", "Name": "San Martin"},
    {"id": "7009", "Name": "San Mateo"},
    {"id": "7024", "Name": "Santa Clara"},
    {"id": "7004", "Name": "South San Francisco"},
    {"id": "7022", "Name": "Sunnyvale"},
    {"id": "253774", "Name": "Stanford"},
    {"id": "7027", "Name": "Tamien"},
]

# Function to fetch raw Caltrain departure data
def get_caltrain_departures(stop_id, key):
    FUTURE_ETAS = []
    print(stop_id, key)

    if (len(stop_id) == 4):
        northbound_stop_id = stop_id + "1"
        southbound_stop_id = stop_id + "2"

        # --- Northbound departures ---
        url = "http://api.511.org/transit/StopMonitoring?api_key=%s&agency=CT&stopCode=%s&format=json" % (key, northbound_stop_id)
        print(url)
        response = http.get(url, ttl_seconds = 1)
        if response.status_code != 200:
            print("Nope")
            fail("Rate Limit")

        cleaned_content = clean_response(response.body())
        monitored_stop = json.decode(cleaned_content)
        monitored_stop_visits = monitored_stop["ServiceDelivery"]["StopMonitoringDelivery"]["MonitoredStopVisit"]

        for visit in monitored_stop_visits:
            stop = visit["MonitoredVehicleJourney"]
            if (humanize.time(time.parse_time(stop["MonitoredCall"]["AimedDepartureTime"]))).find("from") != -1:
                FUTURE_ETAS.append(visit)

        # --- Southbound departures ---
        url = "http://api.511.org/transit/StopMonitoring?api_key=%s&agency=CT&stopCode=%s&format=json" % (key, southbound_stop_id)
        print(url)
        response = http.get(url, ttl_seconds = 1)
        if response.status_code != 200:
            print("Nope")
            fail("Rate Limit")

        cleaned_content = clean_response(response.body())
        monitored_stop = json.decode(cleaned_content)
        monitored_stop_visits = monitored_stop["ServiceDelivery"]["StopMonitoringDelivery"]["MonitoredStopVisit"]

        for visit in monitored_stop_visits:
            stop = visit["MonitoredVehicleJourney"]
            if (humanize.time(time.parse_time(stop["MonitoredCall"]["AimedDepartureTime"]))).find("from") != -1:
                FUTURE_ETAS.append(visit)

        FUTURE_ETAS = manual_sort(FUTURE_ETAS, compare_departures)

    if (len(stop_id) == 5):
        url = "http://api.511.org/transit/StopMonitoring?api_key=%s&agency=CT&stopCode=%s&format=json" % (key, stop_id)
        print(url)
        response = http.get(url, ttl_seconds = 1)
        if response.status_code != 200:
            print("Nope")
            fail("Rate Limit")

        cleaned_content = clean_response(response.body())
        monitored_stop = json.decode(cleaned_content)
        monitored_stop_visits = monitored_stop["ServiceDelivery"]["StopMonitoringDelivery"]["MonitoredStopVisit"]

        for visit in monitored_stop_visits:
            stop = visit["MonitoredVehicleJourney"]
            if (humanize.time(time.parse_time(stop["MonitoredCall"]["AimedDepartureTime"]))).find("from") != -1:
                FUTURE_ETAS.append(visit)

    return FUTURE_ETAS

# Render a single departure row for the default view
def render_departure_row(visit, color_train, color_scheme = "classic"):
    journey = visit["MonitoredVehicleJourney"]
    train_num = journey["FramedVehicleJourneyRef"]["DatedVehicleJourneyRef"]
    train_color = get_train_color(train_num, color_scheme) if color_train else "#fff"
    return render.Row(
        expanded = True,
        cross_align = "center",
        children = [
            render.Text(content = train_num, color = train_color, font = "tom-thumb"),
            render.Text(content = "|", color = "#000", font = "tom-thumb"),
            render.Text(content = get_first_8_chars(stationNameCleaner(journey["DestinationName"])), color = "#F00", font = "tom-thumb"),
            render.Text(content = "|", color = "#000", font = "tom-thumb"),
            render.Text(content = simplify_time_duration(humanize.time(time.parse_time(journey["MonitoredCall"]["AimedDepartureTime"]))), font = "tom-thumb"),
        ],
    )

# Render default view: up to 3 departure rows
def render_default(departures, color_train, color_scheme = "classic"):
    rows = []
    for i in range(len(departures)):
        if i >= 3:
            break
        rows.append(render_departure_row(departures[i], color_train, color_scheme))

    # Pad to 3 rows
    for _ in range(3 - len(rows)):
        rows.append(
            render.Row(
                expanded = True,
                cross_align = "center",
                children = [
                    render.Text(content = "|", color = "#000", font = "tom-thumb"),
                    render.Text(content = "|", color = "#000", font = "tom-thumb"),
                    render.Text(content = "|", color = "#000", font = "tom-thumb"),
                ],
            ),
        )
    return rows

# Render "Times by type" view: group departures by train type, show comma-separated times
def render_times_by_type(departures, color_scheme = "classic"):
    # Collect times per type, preserving insertion order via a list of type keys
    type_order = []
    type_times = {}
    for visit in departures:
        journey = visit["MonitoredVehicleJourney"]
        train_num = journey["FramedVehicleJourneyRef"]["DatedVehicleJourneyRef"]
        train_type = get_train_type(train_num)
        time_str = simplify_time_duration(humanize.time(time.parse_time(journey["MonitoredCall"]["AimedDepartureTime"])))
        if train_type not in type_times:
            type_order.append(train_type)
            type_times[train_type] = []
        type_times[train_type].append(time_str)

    rows = []
    for t in type_order:
        if len(rows) >= 3:
            break
        color = "#fff"
        if t == "LCL":
            color = get_train_color("1XX", color_scheme)
        elif t == "LTD":
            color = get_train_color("4XX", color_scheme)
        elif t == "EXP":
            color = get_train_color("5XX", color_scheme)
        elif t == "WKD":
            color = get_train_color("6XX", color_scheme)
        elif t == "SCC":
            color = get_train_color("8XX", color_scheme)
        elif t == "OTH":
            color = get_train_color("9XX", color_scheme)
        times_str = ", ".join(type_times[t])
        rows.append(
            render.Row(
                expanded = True,
                cross_align = "center",
                children = [
                    render.Text(content = ljust(t, 4), color = color, font = "tom-thumb"),
                    render.Text(content = times_str, font = "tom-thumb"),
                ],
            ),
        )

    # Pad to 3 rows
    for _ in range(3 - len(rows)):
        rows.append(render.Row(expanded = True, children = [render.Text(content = "", font = "tom-thumb")]))
    return rows

# Manually implement sorting
def manual_sort(lst, compare_func):
    for i in range(len(lst)):
        for j in range(i + 1, len(lst)):
            if compare_func(lst[j], lst[i]):
                lst[i], lst[j] = lst[j], lst[i]
    return lst

# Comparison function for sorting departures by time
def compare_departures(a, b):
    time_a = a["MonitoredVehicleJourney"]["MonitoredCall"]["AimedDepartureTime"]
    time_b = b["MonitoredVehicleJourney"]["MonitoredCall"]["AimedDepartureTime"]
    return time_a < time_b

# Function to clean the response by removing unwanted characters
def clean_response(content):
    # Find the position of the first '{' character
    start_index = content.find("{")

    # Return the substring starting from the first '{' character
    return content[start_index:] if start_index != -1 else content

def stationNameCleaner(station_name):
    return station_name.replace(" Northbound", "").replace(" Southbound", "").replace("Caltrain Station", "").replace("Caltrain", "")

# Function to filter and modify Caltrain stops
def filter_and_modify_stops(caltrain_stops):
    processed_stations = set()
    filtered_stops = []

    for stop in caltrain_stops:
        # Extract station name without "Northbound" or "Southbound"

        station_name = stationNameCleaner(stop["Name"])
        print(stop["Name"])

        # Trim the last digit of the stop ID
        stop["id"] = stop["id"][:-1]

        # If the station name is in the set, skip it
        if station_name in processed_stations:
            continue

        # Add the modified stop to the result
        filtered_stops.append({
            "id": stop["id"],
            "Name": station_name,
        })

        # Add the station name to the set
        processed_stations.add(station_name)

    return filtered_stops

def ljust(input_string, width, fillchar = " "):
    return input_string + fillchar * (width - len(input_string))

def get_first_8_chars(input_string):
    if len(input_string) < 8:
        input_string = ljust(input_string, 8)
    return input_string[:8]

# Map train number prefix to type abbreviation
def get_train_type(train_number):
    prefix = train_number[0]
    if prefix == "1":
        return "LCL"
    if prefix == "4":
        return "LTD"
    if prefix == "5":
        return "EXP"
    if prefix == "6":
        return "WKD"
    if prefix == "8":
        return "SCC"
    return "OTH"

# Original color scheme for train numbers
CLASSIC_COLORS = {
    "1": "#888",
    "4": "#0ff",
    "5": "#f00",
    "6": "#888",
    "8": "#ff0",
    "9": "#f0f",
}

# Updated color scheme with more distinct, accessible colors
UPDATED_COLORS = {
    "1": "#888",
    "4": "#0ff",
    "5": "#c23b22",
    "6": "#aaa",
    "8": "#f0d68c",
    "9": "#f0f",
}

# function to get color of train number, according to the caltrain website
def get_train_color(train_number, color_scheme = "classic"):
    prefix = train_number[0]
    colors = UPDATED_COLORS if color_scheme == "updated" else CLASSIC_COLORS
    return colors.get(prefix, "#f0f")

# Function to convert time duration string to simplified format
def simplify_time_duration(duration_string):
    # Split the input string to extract the numeric value and unit
    parts = duration_string.split()
    print(parts)

    # only return the duration in minutes

    # ["5", "minutes", "from", "now"] => 5
    # ["1", "hour", "from", "now"] => 60
    # ["1", "hour", "and", "5", "minutes", "from", "now"] => 65
    # ["1", "second", "from", "now"] => 1
    # ["1", "minute", "from", "now"] => 1

    #now create it
    # if it only contains the word "minutes" then return the number
    if len(parts) == 4 and parts[1] == "minutes":
        return parts[0]

    # if it contains the word "hour" then return the number * 60
    if len(parts) == 4 and parts[1] == "hour":
        return str(int(parts[0]) * 60)

    # if it contains the word "hour" and "minutes" then return the number * 60 + the number of minutes
    if len(parts) == 7 and parts[1] == "hour" and parts[3] == "minutes":
        return str(int(parts[0]) * 60 + int(parts[2]))

    # if it contains the word "second" then return "now"
    if len(parts) == 4 and parts[1] == "second":
        return "now"

    # if it contains the word "minute" then return "now"
    if len(parts) == 4 and parts[1] == "minute":
        return "now"

    # If the input string doesn't match the expected format, return the original string
    return duration_string

# Build a fake visit object matching the API structure for demo/preview
def _demo_visit(train_num, destination, departure_time):
    return {
        "MonitoredVehicleJourney": {
            "FramedVehicleJourneyRef": {
                "DatedVehicleJourneyRef": train_num,
            },
            "DestinationName": destination,
            "MonitoredCall": {
                "AimedDepartureTime": departure_time.format("2006-01-02T15:04:05Z07:00"),
            },
        },
    }

def main(config):
    stationID = config.get("stop", STATIC_STATIONS[11]["id"])
    direction = config.get("direction", "south")
    api_key = config.get("apiKey", "")
    display_format = config.get("display_format", "default")
    color_train = config.bool("color_train", False)
    color_scheme = config.get("color_scheme", "classic")
    minimum_time_string = config.get("minimum_time", "0")
    minimum_time = int(minimum_time_string) if minimum_time_string.isdigit() else 0
    demo_mode = config.bool("demo_mode", False)
    logo_style = config.get("logo_style", "classic")

    if logo_style == "updated":
        CT_LOGO = CT_LOGO_FILE.readall()
    else:
        CT_LOGO_RQ = http.get("https://agency-logos.sfbatransit.community/caltrain-circle.png")
        CT_LOGO = CT_LOGO_RQ.body()

    # Demo mode uses fake data for preview; otherwise require API key
    if demo_mode:
        now = time.now()
        departures = [
            _demo_visit("102", "San Jose", now + time.minute * 4),
            _demo_visit("512", "Tamien", now + time.minute * 13),
            _demo_visit("416", "Gilroy", now + time.minute * 18),
            _demo_visit("148", "San Jose", now + time.minute * 25),
            _demo_visit("802", "Gilroy", now + time.minute * 32),
            _demo_visit("604", "San Jose", now + time.minute * 41),
            _demo_visit("520", "Tamien", now + time.minute * 55),
        ]
        stop_name = "Hillsdale"
    elif api_key == "":
        return render.Root(
            child = render.Column(
                expanded = True,
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        children = [
                            render.Text(content = "No 511 API token", offset = 2, height = 10, color = "#F00", font = "tom-thumb"),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        children = [
                            render.Text(content = "Get one from", offset = 2, height = 10, font = "tom-thumb"),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        children = [
                            render.Text(content = "ducks.win/511", offset = 2, height = 10, font = "tom-thumb"),
                        ],
                    ),
                ],
            ),
        )
    else:
        # Caltrain stop ids are 5 digits long, however there's two ids for each stop, XXXX1 for northbound and XXXX2 for southbound
        etaID = ""
        if direction == "north":
            etaID = stationID + "1"
        if direction == "south":
            etaID = stationID + "2"
        departures = get_caltrain_departures(etaID, api_key)
        stop_name = ""
        for stop in STATIC_STATIONS:
            if stop["id"] == stationID:
                stop_name = stop["Name"]

    # Filter out departures closer than minimum_time
    if minimum_time > 0:
        filtered = []
        for visit in departures:
            journey = visit["MonitoredVehicleJourney"]
            mins_str = simplify_time_duration(humanize.time(time.parse_time(journey["MonitoredCall"]["AimedDepartureTime"])))
            if mins_str.isdigit() and int(mins_str) >= minimum_time:
                filtered.append(visit)
        departures = filtered

    children = [
        render.Row(
            expanded = True,
            main_align = "left",
            children = [
                render.Padding(
                    pad = (1, 1, 0, 1),
                    child = render.Image(
                        src = CT_LOGO,
                        width = 8,
                        height = 8,
                    ),
                ),
                render.Padding(
                    pad = (1, 0, 0, 0),
                    child = render.Text(content = stop_name, offset = 2, height = 10, font = "tom-thumb"),
                ),
            ],
        ),
    ]

    if len(departures) == 0:
        children.append(
            render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Text(content = "No trains :(", offset = 2, height = 10, font = "tom-thumb"),
                ],
            ),
        )
    elif display_format == "times_by_type":
        for row in render_times_by_type(departures, color_scheme):
            children.append(row)
    else:
        for row in render_default(departures, color_train, color_scheme):
            children.append(row)

    return render.Root(
        child = render.Column(
            expanded = True,
            children = children,
        ),
    )

def get_schema():
    # apiKey has a value here
    stops = STATIC_STATIONS

    agency_list_chooser = []
    for stop in stops:
        agency_list_chooser.append(
            schema.Option(
                display = "%s" % stop["Name"],
                value = "%s" % stop["id"],
            ),
        )

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "apiKey",
                name = "511 API Token",
                desc = "Request from https://ducks.win/511 then find key in your second email",
                icon = "gears",
                secret = True,
            ),
            schema.Dropdown(
                id = "stop",
                name = "Stop",
                desc = "The stop to see departures for",
                icon = "train",
                default = agency_list_chooser[0].value,
                options = agency_list_chooser,
            ),
            schema.Dropdown(
                id = "direction",
                name = "Direction",
                desc = "Which direction to see",
                icon = "rightLeft",
                default = "north",
                options = [
                    schema.Option(
                        display = "Northbound",
                        value = "north",
                    ),
                    schema.Option(
                        display = "Southbound",
                        value = "south",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "display_format",
                name = "Display format",
                desc = "How to display departures",
                icon = "tableColumns",
                default = "default",
                options = [
                    schema.Option(
                        display = "Default",
                        value = "default",
                    ),
                    schema.Option(
                        display = "Times by type",
                        value = "times_by_type",
                    ),
                ],
            ),
            schema.Toggle(
                id = "color_train",
                name = "Color train type",
                desc = "Color the train number by type",
                icon = "palette",
                default = False,
            ),
            schema.Dropdown(
                id = "color_scheme",
                name = "Color scheme",
                desc = "Classic uses original colors, Updated uses refined colors",
                icon = "swatchbook",
                default = "classic",
                options = [
                    schema.Option(
                        display = "Classic",
                        value = "classic",
                    ),
                    schema.Option(
                        display = "Updated",
                        value = "updated",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "logo_style",
                name = "Logo style",
                desc = "Classic uses the original remote logo, Updated uses a bundled logo",
                icon = "image",
                default = "classic",
                options = [
                    schema.Option(
                        display = "Classic",
                        value = "classic",
                    ),
                    schema.Option(
                        display = "Updated",
                        value = "updated",
                    ),
                ],
            ),
            schema.Text(
                id = "minimum_time",
                name = "Minimum time to show",
                desc = "Don't show departures nearer than this many minutes",
                icon = "clock",
                default = "0",
            ),
            schema.Toggle(
                id = "demo_mode",
                name = "Demo mode",
                desc = "Show fake data for preview (no API key needed)",
                icon = "flask",
                default = False,
            ),
        ],
    )
