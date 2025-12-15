"""
Applet: Arc Raiders Stats
Summary: Arc Raiders stats
Description: Shows current Arc Raiders player count and active event timers with map information.
Author: Chris Nourse
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

STEAM_API_URL = "https://api.steampowered.com/ISteamUserStats/GetNumberOfCurrentPlayers/v1/?appid=1808500"
METAFORGE_API_URL = "https://metaforge.app/api/arc-raiders/event-timers"

# Embedded ARC Raiders title logo (64x8 WebP)
ARC_RAIDERS_LOGO_BASE64 = "UklGRo4AAABXRUJQVlA4TIIAAAAvP8ABAC+gEAACJIMw8jcI7DTIBCy2/JKI6EImYLEKiy+gDj7zH4D/cbKjVBpwFUmSVGVz/Pc4QAISkIB/PbxTQUT/FSZtwCQdv/jd6z4PIBNjBgjAtq8LNGmF0FfeXpIUfZmqvDmVUUSnJkn6GI+beUxU2kpEsLGvS0lqeO0k9QcB"
ARC_RAIDERS_LOGO = base64.decode(ARC_RAIDERS_LOGO_BASE64)

# Brand colors
COLOR_RED = "#F10E12"
COLOR_BLACK = "#17111A"
COLOR_GREEN = "#34F186"
COLOR_YELLOW = "#FACE0D"
COLOR_CYAN = "#81EEE6"
COLOR_WHITE = "#FFFFFF"

# Cache TTL values (in seconds)
PLAYER_CACHE_TTL = 600  # 10 minutes
EVENTS_CACHE_TTL = 300  # 5 minutes

# Animation constants
ANIMATION_SCROLL_STEPS = 10  # Number of frames for scroll in/out animation
ANIMATION_PAUSE_FRAMES = 30  # Frames to pause (at 100ms = 3 seconds)

# Scroll speed mapping (in milliseconds)
SCROLL_SPEED_MAP = {
    "slow": 150,
    "medium": 100,
    "fast": 50,
}

# Font names
FONT_TOM_THUMB = "tom-thumb"
FONT_CG_PIXEL_3X5 = "CG-pixel-3x5-mono"

def main(config):
    show_player_count = config.bool("show_player_count", True)
    show_events = config.bool("show_events", True)
    scroll_speed = config.get("scroll_speed", "medium")

    # Get player count
    player_count = None
    if show_player_count:
        player_count = get_player_count()

    # Get event timers (with pre-calculated time remaining)
    # Note: Events are global and timezone-independent
    current_events = []
    events_error = False
    if show_events:
        events_result = get_current_events()
        if events_result == None:
            # API error occurred
            events_error = True
            current_events = []
        else:
            current_events = events_result

    return render_display(player_count, current_events, show_player_count, show_events, scroll_speed, events_error)

def get_player_count():
    """Fetch current player count from Steam API"""
    cached_data = cache.get("arc_raiders_players")
    if cached_data != None:
        # Cache stores as string, convert via float to handle decimal strings
        return int(float(cached_data))

    response = http.get(STEAM_API_URL, ttl_seconds = PLAYER_CACHE_TTL)
    if response.status_code != 200:
        print("[ARC RAIDERS] Failed to fetch player count from Steam API - Status: {}".format(response.status_code))
        return None

    data = response.json()
    if data and data.get("response") and data["response"].get("player_count") != None:
        player_count = data["response"]["player_count"]
        print("[ARC RAIDERS] Successfully fetched player count: {}".format(player_count))

        # Store as string in cache
        cache.set("arc_raiders_players", str(player_count), ttl_seconds = PLAYER_CACHE_TTL)

        # Return as int
        return int(player_count)

    return None

def get_current_events():
    """Fetch event timers from MetaForge API and filter for currently active events

    Note: Arc Raiders events are global - they happen at the same UTC time for everyone.
    Time remaining is calculated in UTC and is the same for all players worldwide.
    """
    cached_data = cache.get("arc_raiders_events")
    if cached_data != None:
        return json.decode(cached_data)

    response = http.get(METAFORGE_API_URL, ttl_seconds = EVENTS_CACHE_TTL)
    if response.status_code != 200:
        print("[ARC RAIDERS] Failed to fetch events from MetaForge API - Status: {}".format(response.status_code))
        return None  # Return None to indicate API error

    response_data = response.json()
    if not response_data:
        print("[ARC RAIDERS] Empty response from MetaForge API")
        return None  # Return None to indicate API error

    # The API returns {"data": [...]} structure
    events = response_data.get("data", [])
    if not events:
        print("[ARC RAIDERS] No events data found in MetaForge API response")
        return []  # Return empty list - API worked but no events

    # Handle if events is not a list
    if type(events) != "list":
        print("[ARC RAIDERS] Events response is not a list - Type: {}".format(type(events)))
        return None  # Return None to indicate API error

    # Get current time in UTC
    now_utc = time.now()
    current_hour = now_utc.hour
    current_minute = now_utc.minute

    # Filter for events happening now
    active_events = []
    for event in events:
        # Skip if event is not a dict
        if type(event) != "dict":
            continue

        times = event.get("times")
        if times and type(times) == "list":
            for time_slot in times:
                if type(time_slot) != "dict":
                    continue

                start_time = parse_time(time_slot.get("start", ""))
                end_time = parse_time(time_slot.get("end", ""))

                if is_event_active(current_hour, current_minute, start_time, end_time):
                    # Create a proper UTC datetime for the end time
                    # Determine if end time is tomorrow in UTC (for midnight-spanning events)
                    end_minutes_utc = time_to_minutes(end_time["hour"], end_time["minute"])
                    current_minutes_utc = time_to_minutes(current_hour, current_minute)
                    end_is_tomorrow_utc = end_minutes_utc <= current_minutes_utc

                    # Build full UTC datetime for end time
                    end_day = now_utc.day + (1 if end_is_tomorrow_utc else 0)
                    end_datetime_utc = time.time(
                        year = now_utc.year,
                        month = now_utc.month,
                        day = end_day,
                        hour = end_time["hour"],
                        minute = end_time["minute"],
                        location = "UTC",
                    )

                    # Calculate time remaining in UTC (same for all players globally)
                    remaining_seconds = (end_datetime_utc.unix - now_utc.unix)
                    remaining_minutes = int(remaining_seconds / 60)

                    # Format the time remaining string
                    if remaining_minutes < 0:
                        time_str = "0min"
                    elif remaining_minutes > 1440:  # More than 24 hours
                        time_str = "24h+"
                    else:
                        hours = remaining_minutes // 60
                        minutes = remaining_minutes % 60
                        if hours > 0:
                            time_str = "{}hr".format(hours)
                        else:
                            time_str = "{}min".format(minutes)

                    # Store event with pre-calculated time remaining
                    active_events.append({
                        "name": event.get("name", "Unknown"),
                        "map": event.get("map", "Unknown"),
                        "start": time_slot.get("start", ""),
                        "end": time_slot.get("end", ""),
                        "time_remaining": "Ends in {}".format(time_str),
                    })
                    break  # Only add each event once

    print("[ARC RAIDERS] Successfully fetched events - Active: {}".format(len(active_events)))
    cache.set("arc_raiders_events", json.encode(active_events), ttl_seconds = EVENTS_CACHE_TTL)
    return active_events

def parse_time(time_str):
    """Parse time string like '14:00' into hour and minute"""
    if not time_str or ":" not in time_str:
        return None

    parts = time_str.split(":")
    if len(parts) != 2:
        return None

    hour = int(parts[0])
    minute = int(parts[1]) if parts[1] else 0
    return {"hour": hour, "minute": minute}

def time_to_minutes(hour, minute):
    """Convert hour and minute to total minutes since midnight"""
    return hour * 60 + minute

def is_event_active(current_hour, current_minute, start_time, end_time):
    """Check if an event is currently active"""
    if not start_time or not end_time:
        return False

    current_minutes = time_to_minutes(current_hour, current_minute)
    start_minutes = time_to_minutes(start_time["hour"], start_time["minute"])
    end_minutes = time_to_minutes(end_time["hour"], end_time["minute"])

    # Handle events that span midnight
    if end_minutes < start_minutes:
        return current_minutes >= start_minutes or current_minutes < end_minutes

    return start_minutes <= current_minutes and current_minutes < end_minutes

def generate_event_animation(events, header_height):
    """Generate animation frames for events with scroll-pause-scroll effect

    Args:
        events: List of event dictionaries
        header_height: Height of the header section in pixels

    Returns:
        render.Animation with frames for all events
    """
    frames = []
    full_height = 32  # Events use full screen height (32px)
    event_content_height = 18  # Height of event content

    for _, event in enumerate(events):
        # Scroll in: create frames that slide the event into view from bottom
        for step in range(ANIMATION_SCROLL_STEPS + 1):
            # Start completely below screen (full_height + event_content_height), end at header_height
            start_offset = full_height + event_content_height
            offset = start_offset + (header_height - start_offset) * step // ANIMATION_SCROLL_STEPS
            frames.append(
                render.Box(
                    width = 64,
                    height = full_height,
                    child = render.Padding(
                        pad = (0, offset, 0, 0),
                        child = render_event(event),
                    ),
                ),
            )

        # Pause: display event statically
        # Hold for ~3 seconds (ANIMATION_PAUSE_FRAMES frames at 100ms delay = 3s)
        for _ in range(ANIMATION_PAUSE_FRAMES):
            frames.append(
                render.Box(
                    width = 64,
                    height = full_height,
                    child = render.Padding(
                        pad = (0, header_height, 0, 0),
                        child = render_event(event),
                    ),
                ),
            )

        # Scroll out: slide event out of view upward
        for step in range(1, ANIMATION_SCROLL_STEPS + 1):
            # Move from header_height up to negative (off screen top)
            offset = header_height - (header_height + 18) * step // ANIMATION_SCROLL_STEPS
            frames.append(
                render.Box(
                    width = 64,
                    height = full_height,
                    child = render.Padding(
                        pad = (0, offset, 0, 0),
                        child = render_event(event),
                    ),
                ),
            )

    return render.Animation(children = frames)

def render_event(event):
    """Render a single event with all text left-aligned within a globally centered group"""

    # Wrap the column in a Box to globally center it while keeping text left-aligned within
    return render.Box(
        width = 64,
        height = 18,  # Height of event content (3 lines of text)
        child = render.Row(
            main_align = "center",
            expanded = True,
            children = [
                render.Column(
                    cross_align = "start",
                    children = [
                        render.Text(
                            content = event["map"],
                            font = FONT_TOM_THUMB,
                            color = COLOR_WHITE,
                        ),
                        render.Text(
                            content = event["name"],
                            font = FONT_CG_PIXEL_3X5,
                            color = COLOR_YELLOW,
                        ),
                        render.Text(
                            content = event.get("time_remaining", ""),
                            font = FONT_CG_PIXEL_3X5,
                            color = COLOR_RED,
                        ),
                    ],
                ),
            ],
        ),
    )

def format_number(num):
    """Format number in K format (e.g., 286.2K)"""
    if num == None:
        return "N/A"

    if num >= 1000:
        thousands = num / 1000.0

        # Format with 1 decimal place
        formatted = str(int(thousands * 10) / 10.0)

        # Remove unnecessary .0
        if formatted.endswith(".0"):
            formatted = formatted[:-2]
        return "{}K".format(formatted)

    return str(num)

def render_display(player_count, current_events, show_player_count, show_events, scroll_speed, events_error = False):
    """Render the display based on what data is available"""

    # Calculate header height (logo + optional player count)
    header_height = 8  # Logo height
    if show_player_count:
        header_height += 6  # Player count height

    # Create header overlay (title and player count)
    header_children = []
    header_children.append(render.Image(src = ARC_RAIDERS_LOGO))

    if show_player_count:
        player_text = format_number(player_count) if player_count != None else "N/A"
        header_children.append(
            render.Box(
                width = 64,
                height = 6,
                child = render.Padding(
                    pad = (1, 0, 0, 0),
                    child = render.Row(
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(
                                content = "Players:",
                                font = FONT_TOM_THUMB,
                                color = COLOR_CYAN,
                            ),
                            render.Text(
                                content = player_text,
                                font = FONT_TOM_THUMB,
                                color = COLOR_GREEN,
                            ),
                        ],
                    ),
                ),
            ),
        )

    # Create events background layer
    events_layer = None
    if show_events:
        if len(current_events) > 0:
            # Generate animation frames for events
            events_layer = generate_event_animation(current_events, header_height)
        else:
            # Show different message for API error vs no events
            if events_error:
                message = "API Error"
                message_color = COLOR_RED
            else:
                message = "No active events"
                message_color = COLOR_CYAN

            events_layer = render.Box(
                width = 64,
                height = 32,
                child = render.Padding(
                    pad = (2, header_height, 0, 0),
                    child = render.WrappedText(
                        content = message,
                        font = FONT_TOM_THUMB,
                        color = message_color,
                    ),
                ),
            )

    # Map scroll speed to delay value
    delay = SCROLL_SPEED_MAP.get(scroll_speed, 100)

    # Use Stack to overlay header on top of events
    if show_events and events_layer:
        return render.Root(
            delay = delay,
            child = render.Stack(
                children = [
                    events_layer,  # Background: scrolling events
                    render.Box(
                        width = 64,
                        height = header_height,
                        color = COLOR_BLACK,
                        child = render.Column(children = header_children),  # Foreground: fixed header with opaque background
                    ),
                ],
            ),
        )
    else:
        # No events, just show header
        return render.Root(
            delay = delay,
            child = render.Column(children = header_children),
        )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "show_player_count",
                name = "Show Player Count",
                desc = "Display current player count from Steam",
                icon = "users",
                default = True,
            ),
            schema.Toggle(
                id = "show_events",
                name = "Show Events",
                desc = "Display currently active event timers",
                icon = "calendar",
                default = True,
            ),
            schema.Dropdown(
                id = "scroll_speed",
                name = "Scroll Speed",
                desc = "Speed of event scrolling",
                icon = "gauge",
                default = "medium",
                options = [
                    schema.Option(
                        display = "Slow",
                        value = "slow",
                    ),
                    schema.Option(
                        display = "Medium",
                        value = "medium",
                    ),
                    schema.Option(
                        display = "Fast",
                        value = "fast",
                    ),
                ],
            ),
        ],
    )
