"""
Applet: Congress Watch
Summary: Updates from U.S. Congress
Description: Displays updates from U.S. Congress.
Author: Robert Ison
"""

load("encoding/json.star", "json")  #JSON Data from congress.gov API site
load("http.star", "http")  #HTTP Client
load("images/congress_icon.png", CONGRESS_ICON_ASSET = "file")
load("render.star", "canvas", "render")  #Render the display for Tidbyt
load("sample_congress_body.star", "SAMPLE_CONGRESS_BODY")
load("sample_congress_data.star", "SAMPLE_CONGRESS_DATA")
load("schema.star", "schema")  #Keep Track of Settings
load("time.star", "time")  #Ensure Timely display of congressional actions

CONGRESS_ICON = CONGRESS_ICON_ASSET.readall()
CONGRESS_API_URL = "https://api.congress.gov/v3/"
CONGRESS_SESSION_LENGTH_IN_DAYS = 720  #730, but we'll shorten it some to make sure we don't miss
CONGRESS_BILL_TTL = 12 * 60 * 60  #12 hours * 60 mins/hour * 60 seconds/min
MAX_ITEMS = 50
SCREEN_WIDTH = canvas.width()

period_options = [
    schema.Option(
        display = "Today",
        value = "1",
    ),
    schema.Option(
        display = "This Week",
        value = "7",
    ),
    schema.Option(
        display = "This Month",
        value = "31",
    ),
    schema.Option(
        display = "Last 90 Days",
        value = "90",
    ),
]

source = [
    schema.Option(
        display = "House of Representatives",
        value = "House",
    ),
    schema.Option(
        display = "Senate",
        value = "Senate",
    ),
    schema.Option(
        display = "House and Senate",
        value = "Both",
    ),
]

scroll_speed_options = [
    schema.Option(
        display = "Slow Scroll",
        value = "60",
    ),
    schema.Option(
        display = "Medium Scroll",
        value = "45",
    ),
    schema.Option(
        display = "Fast Scroll",
        value = "30",
    ),
]

def main(config):
    api_key = config.get("congress_api_key")

    font_type = "5x8"
    if canvas.is2x():
        font_type = "terminus-16"

    #initialize
    senate_start = None
    house_start = None
    congress_number = ""

    if not api_key:

        #test environment or app preview
        congress_session_body = SAMPLE_CONGRESS_BODY
        congress_data = SAMPLE_CONGRESS_DATA

        #Congress Session Info
        congress_number = congress_session_body["congress"]["number"]
    else:
        #Get the current congress
        congress_session_url = "{}congress/current".format(CONGRESS_API_URL)
        congress_session_res = http.get(url = congress_session_url, params = {"api_key": api_key, "format": "json"}, ttl_seconds = 21600) # Cache for 6 hours
        congress_session_body = json.decode(congress_session_res.body())
        if "congress" not in congress_session_body:
            fail("Invalid congress session data")

        #Congress Session Info
        congress_number = congress_session_body["congress"]["number"]

        for i in range(0, len(congress_session_body["congress"]["sessions"])):
            current_start_date = time.parse_time(congress_session_body["congress"]["sessions"][i]["startDate"], format = "2006-01-02")

            if congress_session_body["congress"]["sessions"][i]["chamber"] == "House of Representatives":
                if house_start == None or house_start < current_start_date:
                    house_start = current_start_date
            elif congress_session_body["congress"]["sessions"][i]["chamber"] == "Senate":
                if senate_start == None or senate_start < current_start_date:
                    senate_start = current_start_date

        session_duration_days = (time.now() - senate_start).hours / 24

        cache_ttl = int((CONGRESS_SESSION_LENGTH_IN_DAYS - session_duration_days) * 60 * 60 * 24)

        #Get Bill Data for past X days where X = the most days we search based on period options
        period_days = int(config.get("period", "7"))

        bill_data_from_date = time.now() - time.parse_duration("%dh" % (period_days * 24))

        # 1. Define the parameters as a dictionary (Replaces the long string formatting)
        query_params = {
            "limit": str(MAX_ITEMS),
            "api_key": api_key,
            "format": "json",
            "fromDateTime": bill_data_from_date.format("2006-01-02") + "T00:00:00Z",
        }

        # 2. Define the Base URL (without the '?' or any query params)
        base_url = "{}/bill/{}".format(CONGRESS_API_URL, congress_number)

        # 3. Pass the params dictionary into your helper function
        congress_data = get_cachable_data(base_url, cache_ttl, params = query_params)

    #We have either live or test data, now display it.

    filtered_congress_data = filter_bills(congress_data, config.get("period", period_options[len(period_options) - 1].value), config.get("source", source[-1].value))
    number_filtered_items = len(filtered_congress_data)

    if number_filtered_items == 0:
        return render.Root(
            render.Marquee(width = SCREEN_WIDTH, child = render.Text("No recent bills", font = font_type)),
        )

    #let's diplay a random bill from the filtered list
    random_number = randomize(0, number_filtered_items)

    row1 = filtered_congress_data[random_number]["originChamber"]
    row2 = "%s%s %s" % (filtered_congress_data[random_number]["type"], filtered_congress_data[random_number]["number"], filtered_congress_data[random_number]["title"])
    bill = filtered_congress_data[random_number]
    if bill["latestAction"] != None and "text" in bill["latestAction"]:
        row3 = bill["latestAction"]["text"]
    else:
        row3 = "No recent action"

    return render.Root(
        render.Column(
            children = [
                render.Row(
                    children = [
                        render.Marquee(
                            width = SCREEN_WIDTH - 17,
                            height = 8,
                            child = add_padding_to_child_element(render.Text(row1, font = font_type, color = "#fff"), 1),
                        ),
                        render.Image(CONGRESS_ICON),
                        render.Box(width = 1, height = 16, color = "#000"),
                    ],
                ),
                render.Row(
                    children = [
                        render.Marquee(
                            width = SCREEN_WIDTH,
                            offset_start = 15,
                            child = render.Text(row2, font = font_type, color = "#ff0"),
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Marquee(
                            width = SCREEN_WIDTH,
                            offset_start = len(row2) * (8 if canvas.is2x() else 5),
                            child = render.Text(row3, font = font_type, color = "#f4a306"),
                        ),
                    ],
                ),
            ],
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)) // 2 if canvas.is2x() else int(config.get("scroll", 45)),
    )

def filter_bills(data, period, source):
    # Safe JSON decode
    if "bills" not in data or not data["bills"]:
        return []

    bills = data["bills"]

    filtered_data = []
    period_days = int(period)

    for bill in bills:
        # Skip if not dict or missing required fields
        if not bill or "originChamberCode" not in bill or "updateDate" not in bill:
            continue

        # Chamber filter
        match_chamber = (
            source == "Both" or
            (source == "Senate" and bill["originChamberCode"] == "S") or
            (source == "House" and bill["originChamberCode"] == "H")
        )

        if not match_chamber:
            continue

        # Time filter (safe parse)
        update_time = time.parse_time(bill["updateDate"], "2006-01-02")
        if update_time == None:
            continue

        duration = time.now() - update_time
        days_old = duration.hours / 24  # ✓ Property access

        if days_old < period_days:
            filtered_data.append(bill)

    return filtered_data

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )
    return padded_element

def randomize(min, max):
    now = time.now()
    rand = int(str(now.nanosecond)[-6:-3]) / 1000
    return int(rand * (max - min) + min)

def get_cachable_data(url, ttl, params={}):
    # Pass the params dict directly into the http call
    res = http.get(url = url, params = params, ttl_seconds = ttl)
    if res.status_code != 200:
        fail("Request failed with status %d" % res.status_code)
    return res.body()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "congress_api_key",
                name = "Congress API Key",
                desc = "Your Congress.gov API key. See https://api.congress.gov/ for details.",
                icon = "key",
                secret = True,
            ),
            schema.Dropdown(
                id = "period",
                name = "Period",
                desc = "Display Items",
                icon = "calendar",
                options = period_options,
                default = period_options[3].value,
            ),
            schema.Dropdown(
                id = "source",
                name = "Source",
                desc = "Chamber",
                icon = "landmarkDome",
                options = source,
                default = source[-1].value,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
        ],
    )
