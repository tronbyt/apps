"""
Applet: Congress Watch
Summary: Updates from U.S. Congress
Description: Displays updates from U.S. Congress.
Author: Robert Ison
"""

load("cache.star", "cache")  #Caching
load("encoding/json.star", "json")  #JSON Data from congress.gov API site
load("http.star", "http")  #HTTP Client
load("images/congress_icon.png", CONGRESS_ICON_ASSET = "file")
load("render.star", "render")  #Render the display for Tidbyt
load("schema.star", "schema")  #Keep Track of Settings
load("time.star", "time")  #Ensure Timely display of congressional actions

CONGRESS_ICON = CONGRESS_ICON_ASSET.readall()

CONGRESS_API_URL = "https://api.congress.gov/v3/"
CONGRESS_SESSION_LENGTH_IN_DAYS = 720  #730, but we'll shorten it some to make sure we don't miss
CONGRESS_BILL_TTL = 12 * 60 * 60  #12 hours * 60 mins/hour * 60 seconds/min
MAX_ITEMS = 50
SAMPLE_CONGRESS_BODY = """{"congress": {"endYear": "2024", "name": "118th Congress", "number": 118, "sessions": [{"chamber": "House of Representatives", "endDate": "2024-01-03", "number": 1, "startDate": "2023-01-03", "type": "R"}, {"chamber": "Senate", "endDate": "2024-01-03", "number": 1, "startDate": "2023-01-03", "type": "R"}, {"chamber": "Senate", "number": 2, "startDate": "2024-01-03", "type": "R"}, {"chamber": "House of Representatives", "number": 2, "startDate": "2024-01-03", "type": "R"}], "startYear": "2023", "updateDate": "2023-01-03T17:43:32Z", "url": "https://api.congress.gov/v3/congress/118?format=json"}, "request": {"contentType": "application/json", "format": "json"}}"""
SAMPLE_CONGRESS_DATA = """{"bills":[{"congress":118,"latestAction":{"actionDate":"2024-09-10","text":"TEST DATA: Referred to the House Committee on Ways and Means."},"number":"9518","originChamber":"House","originChamberCode":"H","title":"TEST DATA: BRAVE Act of 2024","type":"HR","updateDate":"2024-11-05","updateDateIncludingText":"2024-11-05","url":"https://api.congress.gov/v3/bill/118/hr/9518?format=json"},{"congress":118,"latestAction":{"actionDate":"2024-09-10","text":"TEST DATA: Referred to the House Committee on Ways and Means."},"number":"9522","originChamber":"House","originChamberCode":"H","title":"TEST DATA: To amend the Internal Revenue Code of 1986 to modify the railroad track maintenance credit.","type":"HR","updateDate":"2024-11-05","updateDateIncludingText":"2024-11-05","url":"https://api.congress.gov/v3/bill/118/hr/9522?format=json"}],"pagination":{"count":88,"next":"https://api.congress.gov/v3/bill/118?sort=updateDate desc&fromDateTime=2024-11-04T00:00:00Z&offset=50&limit=50&format=json"},"request":{"congress":"118","contentType":"application/json","format":"json"}}"""

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

    #initialize
    senate_start = None
    house_start = None
    congress_number = ""

    if not api_key:
        #test environment or app preview
        congress_session_body = json.decode(SAMPLE_CONGRESS_BODY)
        congress_data = json.decode(SAMPLE_CONGRESS_DATA)

        #Congress Session Info
        congress_number = congress_session_body["congress"]["number"]
    else:
        #Get the current congress
        congress_session_url = "%scongress/current?API_KEY=%s&format=json" % (CONGRESS_API_URL, api_key)
        congress_session_body = cache.get(congress_session_url)

        if congress_session_body == None:
            congress_session_body = http.get(url = congress_session_url).body()

        congress_session_body = json.decode(congress_session_body)

        if congress_session_body == None:
            #Error getting data
            fail("Error: Failed to get data from cache or http get calling")

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

        #let's cache this for what should be the rest of the session
        cache.set(congress_session_url, json.encode(congress_session_body), ttl_seconds = cache_ttl)

        #Get Bill Data for past X days where X = the most days we search based on period options
        bill_data_from_date = (time.now() - time.parse_duration("%sh" % config.get("period", period_options[-1].value) * 24))
        congress_bill_url = "%sbill/%s?limit=%s&sort=updateDate+desc&api_key=%s&format=json&fromDateTime=%sT00:00:00Z" % (CONGRESS_API_URL, congress_number, MAX_ITEMS, api_key, bill_data_from_date.format("2006-01-02"))

        congress_data = json.decode(get_cachable_data(congress_bill_url, CONGRESS_BILL_TTL, config))

    #We have either live or test data, now display it.

    filtered_congress_data = filter_bills(congress_data, config.get("period", period_options[0].value), config.get("source", source[-1].value))

    number_filtered_items = len(filtered_congress_data)
    if (number_filtered_items == 0):
        return []

    #let's diplay a random bill from the filtered list
    random_number = randomize(0, number_filtered_items)

    row1 = filtered_congress_data[random_number]["originChamber"]
    row2 = "%s%s %s" % (filtered_congress_data[random_number]["type"], filtered_congress_data[random_number]["number"], filtered_congress_data[random_number]["title"])
    row3 = (filtered_congress_data[random_number]["latestAction"]["text"])

    #Fonts: 10x20 5x8 6x10-rounded 6x10 6x13 CG-pixel-3x5-mono CG-pixel-4x5-mono Dina_r400 tb-8 tom-thumb

    return render.Root(
        render.Column(
            children = [
                render.Row(
                    children = [
                        render.Marquee(
                            width = 47,
                            height = 8,
                            child = add_padding_to_child_element(render.Text(row1, font = "6x10", color = "#fff"), 1),
                        ),
                        render.Image(CONGRESS_ICON),
                        render.Box(width = 1, height = 16, color = "#000"),
                    ],
                ),
                render.Row(
                    children = [
                        render.Marquee(
                            width = 64,
                            offset_start = 15,
                            child = render.Text(row2, font = "5x8", color = "#ff0"),
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Marquee(
                            width = 64,
                            offset_start = len(row2) * 5,
                            child = render.Text(row3, font = "5x8", color = "#f4a306"),
                        ),
                    ],
                ),
            ],
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def filter_bills(data, period, source):
    filtered_data = [
        bill
        for bill in data["bills"]
        if (source == "Senate" and bill["originChamberCode"] == "S") or (source == "Both") or (source == "House" and bill["originChamberCode"] == "H")
        if ((time.now() - time.parse_time(bill["updateDate"], format = "2006-01-02")).hours / 24 < int(period))
    ]

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

def get_cachable_data(url, timeout, config):
    res = http.get(url = url, ttl_seconds = timeout, headers = {"API_KEY": config.get("congress_api_key")})

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

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
                default = period_options[0].value,
            ),
            schema.Dropdown(
                id = "source",
                name = "Source",
                desc = "Chamber",
                icon = "landmarkDome",
                options = source,
                default = source[0].value,
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
