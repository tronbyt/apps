"""imports"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

FONT = "CG-pixel-4x5-mono"
TIMEZONE = "America/New_York"
GREEN = "#30BF4C"
RED = "#F5413B"
BLUE = "#2F87EB"
ORANGE = "#CC6C1B"

TO_NY = "TO_NY"
TO_NJ = "TO_NJ"

STATION_NAME_KEY = "station_name_key"
TRAIN_TIME_KEY = "train_time_key"

# The Port Authority's live PATH arrivals for every station (path.api.razza.dev, used before, has gone)
RIDEPATH_URL = "https://www.panynj.gov/bin/portauthority/ridepath.json"

# Station codes used by the Port Authority, their names, and the names the old API used, so saved settings still work
STATIONS = [
    ("NWK", "Newark", "NEWARK"),
    ("HAR", "Harrison", "HARRISON"),
    ("JSQ", "Journal Square", "JOURNAL_SQUARE"),
    ("GRV", "Grove Street", "GROVE_STREET"),
    ("EXP", "Exchange Place", "EXCHANGE_PLACE"),
    ("NEW", "Newport", "NEWPORT"),
    ("HOB", "Hoboken", "HOBOKEN"),
    ("WTC", "World Trade Center", "WORLD_TRADE_CENTER"),
    ("CHR", "Christopher Street", "CHRISTOPHER_STREET"),
    ("09S", "9th Street", "NINTH_STREET"),
    ("14S", "14th Street", "FOURTEENTH_STREET"),
    ("23S", "23rd Street", "TWENTY_THIRD_STREET"),
    ("33S", "33rd Street", "THIRTY_THIRD_STREET"),
]
OLD_STATION_NAMES = {old: code for code, _, old in STATIONS}

DEFAULT_STATION = "JSQ"
TRUNCATE_LINE_NAMES = {
    "33rd Street via Hoboken": "33rd St.",
    "33rd Street": "33rd St.",
    "Hoboken": "Hoboken",
    "Journal Square via Hoboken": "Journal Sq.",
    "Journal Square": "Journal Sq.",
    "Newark": "Newark",
    "World Trade Center": "World Trade",
}

def main(config):
    station = config.get("station") or DEFAULT_STATION
    station = OLD_STATION_NAMES.get(station, station)
    all_trains = getTrainDataFromApi(station)
    if all_trains == None:
        return []

    return render.Root(
        delay = 200,
        child = render.Marquee(
            height = 32,
            offset_start = 16,
            offset_end = 16,
            scroll_direction = "vertical",
            child = render.Column(children = renderTrainMarquee(all_trains)),
        ),
    )

# FUNCTIONS FOR MAIN APP
def getTrainsAtStation(station):
    """ gets the upcoming trains at a station from the Port Authority's live data

    Args:
        station: station code, e.g. JSQ

    Returns:
        list: trains as dicts with name, direction and minutes, or None if the data isn't available
    """
    resp = http.get(RIDEPATH_URL, ttl_seconds = 30)
    if resp.status_code != 200:
        print("PATH request failed with status {}".format(resp.status_code))
        return None
    trains = []
    for result in resp.json().get("results", []):
        if result.get("consideredStation") != station:
            continue
        for destination in result.get("destinations", []):
            direction = TO_NY if destination.get("label") == "ToNY" else TO_NJ
            for message in destination.get("messages", []):
                head_sign = message.get("headSign", "")
                trains.append({
                    "name": TRUNCATE_LINE_NAMES.get(head_sign, head_sign),
                    "direction": direction,
                    "minutes": int(message.get("secondsToArrival", "0")) // 60,
                })
    return trains

def getAllInboundAndOutbound(trains):
    """ gets all available trains in direction, or null

    Args:
        trains: list of trains

    Returns:
        dict: first trains headed to nj and ny
    """
    upcoming_ny_trains = getUpcomingTrainsInDirection(trains, TO_NY)
    upcoming_nj_trains = getUpcomingTrainsInDirection(trains, TO_NJ)
    return {
        TO_NY: upcoming_ny_trains,
        TO_NJ: upcoming_nj_trains,
    }

def getUpcomingTrainsInDirection(trains, direction):
    upcoming_trains = []
    for t in trains:
        if t["direction"] == direction:
            upcoming_trains.append(t)
    return upcoming_trains if len(upcoming_trains) > 0 else None

def firstInboundAndOutbound(trains):
    """ gets first train in direction, or null

    Args:
        trains: list of trains

    Returns:
        dict: first trains headed to nj and ny
    """
    to_ny_train = getFirstTrainInDirection(trains, TO_NY)
    to_nj_train = getFirstTrainInDirection(trains, TO_NJ)
    return {
        TO_NY: to_ny_train,
        TO_NJ: to_nj_train,
    }

def getFirstTrainInDirection(trains, direction):
    """ gets first train in direction, or null

    Args:
        trains: list of trains
        direction: direction to headed

    Returns:
        dict: first train headed in direction
    """
    for t in trains:
        if t["direction"] == direction:
            return t
    return None

def getTrainDataFromApi(station_name):
    """ gets train data

    Args:
        station_name: station code.

    Returns:
        dict: upcoming trains in each direction, or None if the data isn't available
    """
    trains = getTrainsAtStation(station_name)
    if trains == None:
        return None
    return getAllInboundAndOutbound(trains)

def renderTrainMarquee(trains):
    """ renders marquee for given train

    Args:
        train: train to show
        direction: direction the train is going

    Returns:
        column: the train marquee
    """
    train_marquee = []
    for direction in (TO_NY, TO_NJ):
        direction_text = "NY" if direction == TO_NY else "NJ"
        if (trains[direction] == None):
            train_marquee.append(createNoTrainDisplayRow(direction_text))
        else:
            aggregated_train_data = aggregateTrainData(trains[direction])
            for train in aggregated_train_data:
                train_marquee.append(createTrainDisplayRow(direction_text, train))

    return train_marquee

def aggregateTrainData(trains):
    aggregated_train_data = {}
    for t in trains:
        if t["name"] not in aggregated_train_data:
            aggregated_train_data[t["name"]] = {
                "name": t["name"],
                "direction": t["direction"],
                "minutes": [],
            }
        aggregated_train_data[t["name"]]["minutes"].append(str(t["minutes"]))

    return [train for train in aggregated_train_data.values()]

def createNoTrainDisplayRow(direction_text):
    return render.Column(
        children = [
            render.Row(
                main_align = "start",
                cross_align = "center",
                children = [
                    render.Text(
                        direction_text,
                        color = BLUE,
                        font = FONT,
                    ),
                    render.Text("No Trains", color = RED),
                ],
            ),
            renderDivider(),
        ],
    )

def createTrainDisplayRow(direction_text, train):
    # status = train["status"]
    # status_color = GREEN if status == "ON TIME" else RED
    time_string = "{mins} mins".format(mins = ",".join(train["minutes"]))
    time_text = render.Text(time_string, color = GREEN, font = FONT)

    # status_text = render.WrappedText(train["status"], color = status_color, font = FONT)
    # status_array = [time_text, status_text] if status == "ON TIME" else [status_text]

    display_row = render.Column(
        children = [
            render.Row(
                main_align = "start",
                cross_align = "center",
                children = [
                    render.Text(
                        direction_text,
                        color = BLUE,
                        font = FONT,
                        # width = 16
                    ),
                    render.Box(
                        width = 1,
                        height = 1,
                    ),
                    render.Text(train["name"]),
                ],
            ),
            render.Row(
                main_align = "space_between",
                expanded = True,
                children = [time_text],
            ),
            renderDivider(),
        ],
    )

    return display_row

def renderDivider():
    return render.Box(
        color = ORANGE,
        width = 64,
        height = 1,
    )

# FUNCTIONS FOR SCHEMA

def getAllStations():
    """ maps stations to options

    Returns:
        list: list of options for schema
    """
    return [schema.Option(display = name, value = code) for code, name, _ in STATIONS]

# OPTIONS FOR USER
def get_schema():
    path_stations = getAllStations()
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Station",
                desc = "Station for arrival times.",
                icon = "trainSubway",
                default = DEFAULT_STATION,
                options = path_stations,
            ),
        ],
    )
