"""
Applet: Dome Watch
Summary: US House Floor activity
Description: Show current US House floor activity in real-time, include live vote counts.
Author: Shaun Brown
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("time.star", "time")
load("images/img_5f17f821.png", IMG_5f17f821_ASSET = "file")
load("images/img_6bb25a47.png", IMG_6bb25a47_ASSET = "file")

DEFAULT_TIMEZONE = "America/New_York"
DOME_WATCH_API_URL = "https://api3.domewatch.us"
API_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IlRpZEJ5dCIsImlhdCI6MTUxNjIzOTAyMn0.uXwcFp_oWP5bGXEJLJN8texjF9NYjGd_9wDMRIP7Aug"

# Mock mode configuration
MOCK_MODE = False
MOCK_TIMER_VALUE = "0:00"  # Test values: "15:00", "2:30", "0:00", "-1:45", "-5:00"

def main(config):
    """
    Main entry point for the applet.
    """
    print("Running applet")
    floor = getFloorActivityFromAPI()
    return getRoot(config, floor)

def getRoot(config, floor):
    """
    Determines which screen to display based on the floor status.
    """

    # Use .get() for safety in case the API response is malformed
    if floor.get("now", {}).get("value") == "voting":
        return renderVotingRoot(config, floor)
    else:
        return renderNonVotingRoot(floor)

def renderVotingRoot(config, floor):
    """
    Renders the main screen for when a vote is active.
    This version includes a continuously scrolling marquee.
    """
    timezone = config.get("timezone") or DEFAULT_TIMEZONE
    now = time.now().in_location(timezone)

    # --- NEW ---
    # Get the original question text.
    question_text = floor.get("roll_call", {}).get("question", "Loading...")

    # Repeat the text 10 times to create a very long, continuous scroll.
    # This will feel like an endless loop to the user.
    scroll_text = (question_text + " ") * 10

    return render.Root(
        delay = 125,
        show_full_animation = True,
        child = render.Column(
            main_align = "space_around",
            cross_align = "space_around",
            children = [
                render.Marquee(
                    width = 64,
                    height = 20,
                    child = render.Text(
                        # Use the new, long, repeating text here
                        content = scroll_text,
                        font = "CG-pixel-4x5-mono",
                    ),
                ),
                # The rest of the voting grid and timer remains exactly the same...
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Column(
                            main_align = "space_around",
                            cross_align = "space_around",
                            children = [
                                render.Padding(pad = (0, 1, 0, 1), child = render.Text(content = "", font = "CG-pixel-4x5-mono")),
                                render.Padding(pad = (0, 1, 0, 1), child = render.Text(content = "D", font = "CG-pixel-4x5-mono")),
                                render.Padding(pad = (0, 1, 0, 1), child = render.Text(content = "R", font = "CG-pixel-4x5-mono")),
                            ],
                        ),
                        render.Column(
                            main_align = "space_around",
                            cross_align = "center",
                            children = [
                                render.Padding(pad = 1, child = render.Text(content = "Y", font = "CG-pixel-4x5-mono")),
                                render.Padding(pad = 1, child = render.Text(content = str(floor.get("votes", {}).get("counts", {}).get("blue", {}).get("yeas", 0)), font = "CG-pixel-4x5-mono", color = "#00FF00")),
                                render.Padding(pad = 1, child = render.Text(content = str(floor.get("votes", {}).get("counts", {}).get("red", {}).get("yeas", 0)), font = "CG-pixel-4x5-mono", color = "#00FF00")),
                            ],
                        ),
                        render.Column(
                            main_align = "space_around",
                            cross_align = "center",
                            children = [
                                render.Padding(pad = 1, child = render.Text(content = "N", font = "CG-pixel-4x5-mono")),
                                render.Padding(pad = 1, child = render.Text(content = str(floor.get("votes", {}).get("counts", {}).get("blue", {}).get("nays", 0)), font = "CG-pixel-4x5-mono", color = "#FF0000")),
                                render.Padding(pad = 1, child = render.Text(content = str(floor.get("votes", {}).get("counts", {}).get("red", {}).get("nays", 0)), font = "CG-pixel-4x5-mono", color = "#FF0000")),
                            ],
                        ),
                        render.Column(
                            main_align = "space_around",
                            cross_align = "center",
                            children = [
                                render.Padding(pad = 1, child = render.Text(content = "P", font = "CG-pixel-4x5-mono")),
                                render.Padding(pad = 1, child = render.Text(content = str(floor.get("votes", {}).get("counts", {}).get("blue", {}).get("present", 0)), font = "CG-pixel-4x5-mono")),
                                render.Padding(pad = 1, child = render.Text(content = str(floor.get("votes", {}).get("counts", {}).get("red", {}).get("present", 0)), font = "CG-pixel-4x5-mono")),
                            ],
                        ),
                        render.Column(
                            main_align = "space_around",
                            cross_align = "center",
                            children = [
                                render.Padding(pad = 1, child = render.Text(content = "NV", font = "CG-pixel-4x5-mono")),
                                render.Padding(pad = 1, child = render.Text(content = str(floor.get("votes", {}).get("counts", {}).get("blue", {}).get("not_voting", 0)), font = "CG-pixel-4x5-mono")),
                                render.Padding(pad = 1, child = render.Text(content = str(floor.get("votes", {}).get("counts", {}).get("red", {}).get("not_voting", 0)), font = "CG-pixel-4x5-mono")),
                            ],
                        ),
                    ],
                ),
                render.Box(
                    child = renderVotingTimer(now, floor),
                ),
            ],
        ),
    )

def renderVotingTimer(now, floor):
    """
    Timer function that formats overtime to include hours (H:MM:SS)
    after one hour has passed.
    """

    # First check if we have a valid "value" field
    timer_value = floor.get("timer", {}).get("value", "")

    if timer_value and timer_value != "0:00":
        is_negative = timer_value.startswith("-")
        clean_value = timer_value.lstrip("-")

        if ":" in clean_value:
            parts = clean_value.split(":")
            if len(parts) == 2 and parts[0].isdigit() and parts[1].isdigit():
                minutes = int(parts[0])
                seconds = int(parts[1])
                total_seconds = minutes * 60 + seconds

                if is_negative:
                    # Already in overtime - generate count-up from this point
                    frames = []
                    for i in range(total_seconds, total_seconds + 301):
                        # --- MODIFICATION FOR H:MM:SS FORMAT ---
                        if i < 3600:
                            # Less than 1 hour: -MM:SS
                            min = i // 60
                            sec = i % 60
                            sec_str = str(sec)
                            if sec < 10:
                                sec_str = "0" + sec_str
                            content_str = "-" + str(min) + ":" + sec_str
                        else:
                            # 1+ hour: -H:MM:SS
                            hr = i // 3600
                            rem_sec = i % 3600
                            min = rem_sec // 60
                            sec = rem_sec % 60
                            min_str = str(min)
                            if min < 10:
                                min_str = "0" + min_str
                            sec_str = str(sec)
                            if sec < 10:
                                sec_str = "0" + sec_str
                            content_str = "-" + str(hr) + ":" + min_str + ":" + sec_str

                        # --- END MODIFICATION ---

                        for _ in range(8):
                            frames.append(render.Text(content = content_str, color = "#FF0000"))
                    return render.Animation(children = frames)
                else:
                    # Counting down - generate countdown to 0:00 then overtime
                    frames = []

                    # Countdown to 0:00
                    for i in range(total_seconds, -1, -1):
                        min = i // 60
                        sec = i % 60
                        sec_str = str(sec)
                        if sec < 10:
                            sec_str = "0" + sec_str
                        content_str = str(min) + ":" + sec_str
                        for _ in range(8):
                            frames.append(render.Text(content = content_str, color = "#FFFFFF"))

                    # Continue into overtime
                    for i in range(1, 301):
                        # --- MODIFICATION FOR H:MM:SS FORMAT ---
                        if i < 3600:
                            # Less than 1 hour: -MM:SS
                            min = i // 60
                            sec = i % 60
                            sec_str = str(sec)
                            if sec < 10:
                                sec_str = "0" + sec_str
                            content_str = "-" + str(min) + ":" + sec_str
                        else:
                            # 1+ hour: -H:MM:SS (unlikely to be hit in this 5-min animation, but good practice)
                            hr = i // 3600
                            rem_sec = i % 3600
                            min = rem_sec // 60
                            sec = rem_sec % 60
                            min_str = str(min)
                            if min < 10:
                                min_str = "0" + min_str
                            sec_str = str(sec)
                            if sec < 10:
                                sec_str = "0" + sec_str
                            content_str = "-" + str(hr) + ":" + min_str + ":" + sec_str

                        # --- END MODIFICATION ---

                        for _ in range(8):
                            frames.append(render.Text(content = content_str, color = "#FF0000"))
                    return render.Animation(children = frames)

    # If value is "0:00" or unavailable, use timestamp-based calculation
    timestamp = floor.get("timer", {}).get("timestamp")
    if not timestamp:
        return render.Text("ERR: NO TIME")

    voting_ends = time.parse_time(timestamp)
    duration = now - voting_ends
    seconds_elapsed = int(duration.seconds)

    # Generate overtime animation from current point
    frames = []
    for i in range(seconds_elapsed, seconds_elapsed + 301):
        # --- MODIFICATION FOR H:MM:SS FORMAT ---
        if i < 3600:
            # Less than 1 hour: -MM:SS
            min = i // 60
            sec = i % 60
            sec_str = str(sec)
            if sec < 10:
                sec_str = "0" + sec_str
            content_str = "-" + str(min) + ":" + sec_str
        else:
            # 1+ hour: -H:MM:SS
            hr = i // 3600
            rem_sec = i % 3600
            min = rem_sec // 60
            sec = rem_sec % 60
            min_str = str(min)
            if min < 10:
                min_str = "0" + min_str
            sec_str = str(sec)
            if sec < 10:
                sec_str = "0" + sec_str
            content_str = "-" + str(hr) + ":" + min_str + ":" + sec_str

        # --- END MODIFICATION ---

        for _ in range(8):
            frames.append(render.Text(content = content_str, color = "#FF0000"))

    return render.Animation(children = frames)

def renderNonVotingRoot(floor):
    """
    Renders the screen for when there is no active vote.
    """
    return render.Root(
        delay = 300,
        child = render.Column(
            expanded = True,
            main_align = "space_around",
            children = getNonVotingChildren(floor),
        ),
    )

def getNonVotingChildren(floor):
    """
    Builds the widgets for the non-voting screen.
    """
    children = [
        render.Row(
            main_align = "space_evenly",
            cross_align = "center",
            expanded = True,
            children = [
                render.Column(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        # NOTE: You will need to add your getStatusIcon function back
                        render.Image(src = getStatusIcon(floor), height = 23),
                    ],
                ),
                render.Column(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.WrappedText(
                            align = "center",
                            font = getFloorStatusFont(floor),
                            color = "#FFFFFF",
                            content = floor.get("now", {}).get("text", "No activity"),
                        ),
                    ],
                ),
            ],
        ),
    ]

    if "timeline" in floor and floor["timeline"]:
        children.append(getNonVotingMarquee(floor))
    return children

def getNonVotingMarquee(floor):
    """
    Builds the vertical marquee for the non-voting screen timeline.
    """
    marqueeText = []

    # THE CORRECTED LINE: Use type() to check if the value is a dictionary.
    if type(floor.get("timeline")) == "dict":
        for key in floor["timeline"]:
            marqueeText.append(floor["timeline"][key].get("text", ""))

    full_text = " • ".join(marqueeText)

    return render.Marquee(
        child = render.WrappedText(
            content = full_text,
            font = "tom-thumb",
            color = "#FFFFFF",
            align = "center",
            width = 64,
        ),
        align = "center",
        scroll_direction = "vertical",
        height = 5,
        width = 64,
        delay = 5,
    )

def getStatusIcon(floor):
    if floor["now"]["value"] == "voting":
        return IMG_6bb25a47_ASSET.readall()

    elif floor["now"]["value"] != "adjourned":
        return IMG_6bb25a47_ASSET.readall()

    else:
        return IMG_5f17f821_ASSET.readall()

def getFloorStatusFont(floor):
    """
    Returns a smaller font for the "adjourned" status to ensure it fits.
    """
    if floor.get("now", {}).get("value") == "adjourned":
        return "tom-thumb"
    else:
        return "5x8"

def getFloorActivityFromAPI():
    """
    Fetches floor activity from the Dome Watch API, with caching.
    """

    # Return mock data if in mock mode
    if MOCK_MODE:
        print("Using mock data with timer: " + MOCK_TIMER_VALUE)
        return {
            "now": {"text": "Voting", "value": "voting"},
            "roll_call": {
                "bill": {"id": "566", "number": "566"},
                "number": "187",
                "question": "H RES 566 - MOCK TEST - On Ordering the Previous Question (Timer: " + MOCK_TIMER_VALUE + ")",
            },
            "timeline": {"next_votes": {"text": "Next votes: Later this afternoon"}},
            "timer": {
                "seconds_remaining": 1 if not MOCK_TIMER_VALUE.startswith("-") else 0,
                "timestamp": "2025-07-04T16:15:29.017Z",
                "value": MOCK_TIMER_VALUE,
            },
            "votes": {
                "counts": {
                    "blue": {"nays": "82", "not_voting": "130", "present": "", "yeas": ""},
                    "red": {"nays": "", "not_voting": "193", "present": "", "yeas": "27"},
                    "totals": {"nays": "82", "not_voting": "323", "present": "", "yeas": "27"},
                    "white": {"nays": "", "not_voting": "", "present": "", "yeas": ""},
                },
                "roll_call": {
                    "bill": {"id": "566", "number": "566"},
                    "number": "187",
                    "question": "H RES 566 - MOCK TEST - Timer: " + MOCK_TIMER_VALUE,
                },
                "timer": {
                    "seconds_remaining": 1 if not MOCK_TIMER_VALUE.startswith("-") else 0,
                    "timestamp": "2025-07-02T13:33:39.949Z",
                    "value": MOCK_TIMER_VALUE,
                },
            },
        }
    floor_cached = cache.get("floor")
    if floor_cached != None:
        print("Using cached floor activity")
        return json.decode(floor_cached)

    print("Getting floor activity from API")
    response = http.get(DOME_WATCH_API_URL + "/floor", headers = {
        "Authorization": "Bearer " + API_TOKEN,
    })

    if response.status_code != 200:
        fail("DomeWatch API error: %d %s" % (response.status_code, response.body()))

    floor = response.json()

    if floor.get("now", {}).get("value") == "voting":
        ttl = 1
    else:
        ttl = 20

    cache.set("floor", json.encode(floor), ttl_seconds = ttl)
    return floor
