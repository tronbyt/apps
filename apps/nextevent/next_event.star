load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TIMEZONE = "America/New_York"
LAMBDA_URL = "https://ozjgejjru4.execute-api.us-east-1.amazonaws.com/prod/"
DEFAULT_ICS_URL = "https://ics.calendarlabs.com/76/8d23255e/US_Holidays.ics"
DEFAULT_TITLE = "Next event"

def is_square():
    """True on a 64x64 panel.

    Panels are told apart by SHAPE, never by size: the 128x64 wide panel is
    also 64 tall.
    """
    w, h = canvas.size()
    return h == w

def main(config):
    location = config.str("loc")
    location = json.decode(location) if location else {}
    timezone = location.get(
        "timezone",
        time.tz(),
    )
    ics_url = config.str("url", DEFAULT_ICS_URL)
    if (ics_url == None):
        fail("Calendar URL is missing")

    lambda_api_key = config.get("lambda_api_key")

    # API Key will be returned if running on Tidbyt's prodution environment. If running local or in CI/CD,
    # the value will return as None. In that case, don't attempt to contact the Lambda function and
    # return demo content instead.
    if lambda_api_key:
        response = http.post(
            url = LAMBDA_URL,
            headers = {"x-api-key": lambda_api_key},
            json_body = {"ics_url": ics_url, "tz": timezone},
        )
        next_event = response.json()
    else:
        next_event = {
            "has_next_event": True,
            "title": "Memorial Day",
            "begin": "2024-05-26T20:00:00-04:00",
            "end": "2024-05-26T20:00:00-04:00",
            "location": "United States",
            "is_today": False,
            "is_tomorrow": False,
        }

    return render.Root(
        # Centre the block on the square (64x64); other panels unchanged.
        child = (render.Box(width = canvas.width(), height = canvas.height(), child = render.Column(
            cross_align = "center",
            main_align = "space_around",
            children = render_top(config) + render_bottom(next_event),
        ))) if is_square() else render.Column(
            cross_align = "center",
            main_align = "space_around",
            children = render_top(config) + render_bottom(next_event),
        ),
    )

def render_top(config):
    return [
        render.Marquee(
            child = render.Text(
                content = config.str("title", DEFAULT_TITLE),
                color = "#ffea00",
            ),
            width = 64,
            align = "center",
        ),
        render.Box(
            color = "#ffea00",
            height = 1,
        ),
    ]

def render_bottom(next_event):
    has_next_event = next_event["has_next_event"]

    if has_next_event:
        is_today = next_event["is_today"]
        is_tomorrow = next_event["is_tomorrow"]

        # The Lambda API will calculate if the date is today or
        # tomorrow so the frontend can display relative dates
        if is_today:
            pretty_date = "Today"
        elif is_tomorrow:
            pretty_date = "Tomorrow"
        else:
            display_month = time.parse_time(next_event["begin"]).format("Jan")
            display_day = time.parse_time(next_event["begin"]).day
            pretty_date = "{} {}".format(display_month, display_day)

        return [
            render.Box(
                color = "#000",
                height = 3,
            ),
            render.Marquee(
                child = render.Text(
                    content = next_event["title"],
                ),
                width = 64,  # Full width
                align = "center",
            ),
            render.Box(
                color = "#000",
                height = 1,
            ),
            render.Text(
                # Date
                content = pretty_date,
            ),
        ]

    else:
        return [
            render.Box(
                color = "#000",
                height = 3,
            ),
            render.Text(
                content = "No more",
            ),
            render.Text(
                content = "events",
            ),
        ]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "loc",
                name = "Location",
                desc = "Location for timezone awareness",
                icon = "locationDot",
            ),
            schema.Text(
                id = "url",
                name = "iCalendar URL",
                desc = "The URL of the iCalendar file.",
                icon = "calendar",
                default = DEFAULT_ICS_URL,
            ),
            schema.Text(
                id = "title",
                name = "The title displayed above the next event",
                desc = "What are the events on this calendar?",
                icon = "calendar",
                default = DEFAULT_TITLE,
            ),
            schema.Text(
                id = "lambda_api_key",
                name = "Lambda API Key",
                desc = "A Lambda API key to access the Lambda API.",
                icon = "key",
                secret = True,
            ),
        ],
    )
