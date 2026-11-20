"""
Applet: Events List
Summary: List of upcoming events
Description: Displays a list of upcoming events from a Google Calendar iCal URL.
Author: jblaker
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEBUG_URL = ""

def main(config):
    url = config.str("calendar_url", "")
    if url == "":
        return render.Root(
            render.Padding(
                pad = (1, 1, 1, 1),
                child = render.WrappedText("Enter a Google Calender iCal URL", font = "tom-thumb"),
            ),
        )
    rep = http.get(url)
    if rep.status_code != 200:
        fail("Google Calender request failed with status %d", rep.status_code)

    # Unfold continuation lines (RFC 5545: lines starting with a space/tab continue the previous line)
    body = rep.body().replace("\r\n ", "").replace("\r\n\t", "").replace("\n ", "").replace("\n\t", "")
    lines = body.split("\n")

    events = []
    event = {}
    creatingEvent = False

    for line in lines:
        if line.startswith("BEGIN:VEVENT"):
            creatingEvent = True
            event = {}

        if line.startswith("END:VEVENT"):
            creatingEvent = False
            date = event.get("date")
            if date != None:
                if date >= time.now():
                    events.append(event)

        if creatingEvent:
            if line.startswith("SUMMARY:"):
                event["name"] = ":".join(line.split(":")[1:])

            if line.startswith("LOCATION:") or line.startswith("LOCATION;"):
                location = ":".join(line.split(":")[1:]).replace("\x0d", "")
                location = location.replace("\\n", " ").replace("\\,", ",").replace("\\;", ";")

                # Keep only the venue name (Google Calendar formats locations as "Venue, Street, City, ...")
                location = location.split(",")[0].strip()
                if location != "":
                    event["location"] = location

            if line.startswith("DTSTART:"):
                timestamp = line.split(":")[1].replace("\x0d", "")

                dateFormat = "20060102T150405Z"
                eventDate = time.parse_time(timestamp, dateFormat, "UTC")

                # For display, convert to local timezone
                timezone = config.get("timezone") or "America/New_York"
                localEventDate = eventDate.in_location(timezone)

                event["date"] = eventDate  # Keep as UTC for comparison
                event["formattedDate"] = localEventDate.format("01/02")  # Display in local timezone
                event["formattedTime"] = eventDate.in_location(timezone).format("15:04")
                event["formattedLongDate"] = localEventDate.format("Mon 01/02")

            if line.startswith("DTSTART;VALUE=DATE:"):
                dateString = line.split(":")[1].replace("\x0d", "")

                year = int(dateString[0:4])
                month = int(dateString[4:6])
                day = int(dateString[6:8])

                # For all-day events, create a timestamp at noon local time to avoid timezone issues
                timezone = config.get("timezone") or "America/New_York"

                # Create timestamp string manually (avoiding % formatting)
                yearStr = str(year)
                monthStr = str(month)
                dayStr = str(day)

                # Pad with zeros if needed
                if len(yearStr) < 4:
                    yearStr = "0" * (4 - len(yearStr)) + yearStr
                if len(monthStr) < 2:
                    monthStr = "0" + monthStr
                if len(dayStr) < 2:
                    dayStr = "0" + dayStr

                timestamp = yearStr + monthStr + dayStr + "T120000"

                # Parse in local timezone to avoid date shifting
                dateFormat = "20060102T150405"
                eventDate = time.parse_time(timestamp, dateFormat, timezone)

                event["date"] = eventDate
                event["formattedDate"] = eventDate.in_location(timezone).format("01/02")
                event["formattedTime"] = eventDate.in_location(timezone).format("15:04")
                event["formattedLongDate"] = eventDate.in_location(timezone).format("Mon 01/02")
                event["allDay"] = True

    maxEvents = int(config.get("number_of_events", "5"))
    events = sorted(events, key = lambda x: x["date"])[:maxEvents]

    if config.bool("next_event_only") and len(events) > 0:
        return render_next_event(events[0], config)

    layout = []

    counter = 0

    if len(events) > 0:
        for event in events:
            rowColor = "#ffc300" if ((counter % 2) == 0) else "#a2d9ce"
            altRowColor = "#a2d9ce" if ((counter % 2) == 0) else "#ffc300"
            layout.append(
                render.Padding(
                    pad = (0, 0, 0, 3),
                    child = render.Row(
                        children = [
                            render.Column(
                                children = [
                                    render.WrappedText(content = event["name"], font = "tom-thumb", color = str(rowColor), width = 42),
                                ],
                            ),
                            render.Column(
                                children = [
                                    render.Padding(
                                        pad = (1, 0, 0, 0),
                                        child = render.Text(content = event["formattedDate"], font = "tom-thumb"),
                                    ),
                                    render.Padding(
                                        pad = (1, 0, 0, 0),
                                        child = render.Text(content = event["formattedTime"], font = "tom-thumb", color = str(altRowColor)),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ),
            )
            counter += 1

    else:
        return render.Root(
            render.Padding(
                pad = (1, 1, 1, 1),
                child = render.WrappedText("Could not parse calender data.", font = "tom-thumb"),
            ),
        )

    scroll_opt = config.str("speed", "100")
    return render.Root(
        delay = int(scroll_opt),  #speed up scroll text
        show_full_animation = True,
        child = render.Padding(
            pad = (1, 1, 1, 1),
            child = render.Marquee(
                scroll_direction = "vertical",
                width = 60,
                height = 30,
                child = render.Column(
                    children = layout,
                ),
            ),
        ),
    )

def render_next_event(event, config):
    whenText = event["formattedLongDate"] + " " + ("All day" if event.get("allDay") else event["formattedTime"])

    # Count calendar days (in local time) from today until the event
    timezone = config.get("timezone") or "America/New_York"
    now = time.now().in_location(timezone)
    eventDate = event["date"].in_location(timezone)
    today = time.time(year = now.year, month = now.month, day = now.day, location = timezone)
    eventDay = time.time(year = eventDate.year, month = eventDate.month, day = eventDate.day, location = timezone)
    days = int((eventDay - today).hours + 12) // 24  # +12 absorbs DST shifts

    if days == 0:
        headerText = "TODAY:"
    elif days == 1:
        headerText = "1 DAY UNTIL:"
    else:
        headerText = str(days) + " DAYS UNTIL:"

    children = [
        render.Padding(
            pad = (0, 0, 0, 1),
            child = render.Text(content = headerText, font = "CG-pixel-3x5-mono", color = "#888888"),
        ),
        render.Marquee(
            width = 62,
            child = render.Text(content = event.get("name", "").replace("\x0d", ""), font = "tb-8", color = "#ffc300"),
        ),
        render.Padding(
            pad = (0, 1, 0, 1),
            child = render.Text(content = whenText, font = "tom-thumb"),
        ),
    ]

    location = event.get("location")
    if location:
        children.append(
            render.Marquee(
                width = 62,
                child = render.Text(content = location, font = "tom-thumb", color = "#a2d9ce"),
            ),
        )

    return render.Root(
        delay = int(config.str("speed", "100")),
        show_full_animation = True,
        child = render.Padding(
            pad = (1, 1, 1, 1),
            child = render.Column(children = children),
        ),
    )

def get_schema():
    scroll_speed = [
        schema.Option(display = "Slow", value = "200"),
        schema.Option(display = "Normal (Default)", value = "100"),
        schema.Option(display = "Fast", value = "30"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "calendar_url",
                name = "Calendar URL",
                desc = "Your Google Calendar iCal URL",
                icon = "calendar",
            ),
            schema.Text(
                id = "number_of_events",
                name = "Number of Events",
                desc = "The number of events you want to see.",
                icon = "gear",
                default = "5",
            ),
            schema.Toggle(
                id = "next_event_only",
                name = "Next Event Only",
                desc = "Show only the next event in more detail, including its location.",
                icon = "calendarDay",
                default = False,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Scroll Speed",
                desc = "Change speed that text scrolls.",
                icon = "gear",
                default = scroll_speed[1].value,
                options = scroll_speed,
            ),
        ],
    )
