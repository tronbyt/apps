"""
Applet: HA Calendar
Summary: Events from Home Assistant Calendar
Description: Shows events from Home Assistant Calendar entities.
Author: radiocolin
"""

load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ha_url",
                name = "Home Assistant URL",
                desc = "The root URL of your Home Assistant instance (e.g., https://homeassistant.my.domain.com or http://192.168.1.5:8123. Trailing slashes don't matter.)",
                icon = "house",
                default = "http://192.168.1.5:8123",
            ),
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "Your Home Assistant API key (Long-Lived Access Token)",
                icon = "key",
                default = "",
            ),
            schema.Text(
                id = "calendar",
                name = "Calendar Entity ID",
                desc = "The calendar entity ID (e.g., calendar.default_calendar)",
                icon = "calendar",
                default = "calendar.default_calendar",
            ),
            schema.Color(
                id = "header_color",
                name = "Header Color",
                desc = "Color for the event header background",
                icon = "palette",
                default = "#800080",
            ),
        ],
    )

def parse_events(events):
    parsed_events = []
    now = time.now().in_location("America/New_York")
    tomorrow = now + time.parse_duration("24h")
    for event in events:
        if len(parsed_events) < 6:
            if event.get("start").get("date"):
                event_start = time.parse_time(event.get("start").get("date"), "2006-01-02", "America/New_York")
                if event_start.day == now.day:
                    parsed_events.append(("All-day", event.get("summary")))
            if event.get("start").get("dateTime"):
                parse_format = "2006-01-02T15:04:05-07:00"
                event_start = time.parse_time(event.get("start").get("dateTime"), parse_format, "America/New_York")
                event_end = time.parse_time(event.get("end").get("dateTime"), parse_format, "America/New_York")
                if event_start.day == now.day and event_end > now:
                    parsed_events.append((event_start.format("03:04pm"), event.get("summary")))
    for event in events:
        if len(parsed_events) < 6:
            if event.get("start").get("date"):
                event_start = time.parse_time(event.get("start").get("date"), "2006-01-02", "America/New_York")
                if event_start.day == tomorrow.day:
                    parsed_events.append(("Tomorrow", event.get("summary")))
            if event.get("start").get("dateTime"):
                parse_format = "2006-01-02T15:04:05-07:00"
                event_start = time.parse_time(event.get("start").get("dateTime"), parse_format, "America/New_York")
                if event_start.day == tomorrow.day:
                    parsed_events.append((event_start.format("Mon 03:04pm"), event.get("summary")))
    return parsed_events

def render_events(events, header_color, scale):
    rows = []
    header_font = "CG-pixel-4x5-mono" if scale == 1 else "terminus-12"
    event_font = "tom-thumb" if scale == 1 else "terminus-14"

    for start, event in events:
        rows.append(
            render.Column(
                children = [
                    render.Box(
                        color = header_color,
                        width = 64 * scale,
                        height = 7 * scale,
                        child = render.Row(
                            children = [
                                render.Padding(
                                    child = render.Text(
                                        start,
                                        font = header_font,
                                        color = "#fff",
                                    ),
                                    pad = (1 * scale, 0, 0, 0),
                                ),
                            ],
                            main_align = "start",
                            expanded = True,
                        ),
                    ),
                    render.Padding(
                        child = render.WrappedText(
                            content = event,
                            font = event_font,
                            width = 64 * scale,
                        ),
                        pad = (1 * scale, 0, 0, 0),
                    ),
                ],
            ),
        )

    return rows

def main(config):
    scale = 2 if canvas.is2x() else 1
    today = time.now().in_location("America/New_York")
    header_color = config.str("header_color", "#800080")

    ha_url = config.str("ha_url", "").strip()
    calendar_id = config.str("calendar", "")
    api_key = config.str("api_key", "")

    # Check if required config values are present
    if not ha_url or not calendar_id or not api_key:
        return render.Root(
            child = render.Box(
                child = render.WrappedText(
                    content = "Please configure Home Assistant URL, API Key, and Calendar",
                    font = "tom-thumb" if scale == 1 else "terminus-14",
                    width = 64 * scale,
                ),
            ),
        )

    if ha_url.endswith("/"):
        ha_url = ha_url[:-1]

    plustwodays = today + time.parse_duration("48h")
    url = ha_url + "/api/calendars/" + calendar_id

    params = {"start": today.format("2006-01-02"), "end": plustwodays.format("2006-01-02")}
    headers = {"Authorization": "Bearer " + api_key}
    r = http.get(url, params = params, headers = headers)

    events = parse_events(r.json())
    rows = render_events(events, header_color, scale)

    if len(rows) > 0:
        delay = int(10000 / len(rows))
    else:
        delay = 10000
        rows.append(
            render.Column(
                children = [
                    render.Box(
                        color = header_color,
                        width = 64 * scale,
                        height = 7 * scale,
                    ),
                    render.Padding(
                        child = render.WrappedText(
                            content = "No more events today",
                            font = "tom-thumb" if scale == 1 else "terminus-14",
                            width = 64 * scale,
                        ),
                        pad = (1 * scale, 0, 0, 0),
                    ),
                ],
            ),
        )

    date_font = "tb-8" if scale == 1 else "terminus-18"

    return render.Root(
        delay = delay,
        child = render.Column(
            children = [
                render.Padding(
                    child = render.Text(content = today.format("Mon, Jan 02"), font = date_font),
                    pad = (1 * scale, 0, 0, 0),
                ),
                render.Animation(
                    children = rows,
                ),
            ],
        ),
    )
