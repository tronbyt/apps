"""
Applet: Arc Raiders Stats
Summary: Arc Raiders stats
Description: Shows current Arc Raiders player count and active event timers with map information. Canvas-based rendering with timeline animation system.
Author: Chris Nourse
"""

load("ArcRaidersTitle.webp", ARC_RAIDERS_LOGO_1X = "file")
load("ArcRaidersTitle@2x.webp", ARC_RAIDERS_LOGO_2X = "file")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

ARC_RAIDERS_LOGO = ARC_RAIDERS_LOGO_2X.readall() if canvas.is2x() else ARC_RAIDERS_LOGO_1X.readall()

# API URLs
STEAM_API_URL = "https://api.steampowered.com/ISteamUserStats/GetNumberOfCurrentPlayers/v1/?appid=1808500"
ARCRAIDERSHUB_API_URL = "https://arcraidershub.com/data/events.json"

# Brand colors
COLOR_RED = "#F10E12"
COLOR_BLACK = "#17111A"
COLOR_GREEN = "#34F186"
COLOR_YELLOW = "#FACE0D"
COLOR_CYAN = "#81EEE6"
COLOR_WHITE = "#FFFFFF"

# Cache TTL values (in seconds)
PLAYER_CACHE_TTL = 600  # 10 minutes (http.get cache)
EVENTS_TABLE_CACHE_TTL = 43200  # 12 hours (cache full event table)

# Screen constants (resolution-aware)
SCALE = 2 if canvas.is2x() else 1
SCREEN_WIDTH = canvas.width()
SCREEN_HEIGHT = canvas.height()
PLAYER_COUNT_HEIGHT = 6 * SCALE
EVENT_CONTENT_HEIGHT = 36 if canvas.is2x() else 18
CHAR_WIDTH = 6 if canvas.is2x() else 4  # Width of FONT_EVENT characters

# Fonts (resolution-aware)
FONT_HEADER = "6x10" if canvas.is2x() else "tom-thumb"
FONT_EVENT = "terminus-12" if canvas.is2x() else "CG-pixel-3x5-mono"

# Animation constants - Percentage-based values
PERCENT_PAUSE = 0.75  # % of each event's time spent paused
PERCENT_SCROLL_OUT = 0.15  # % of each event's time for scroll out animation
PERCENT_FINAL_PAUSE = 0.02  # % of total time for final pause before loop restart

# Remaing percent for Scroll in
FRAMES_PER_SECOND = 20  # Frame rate for countdown calculations
HORIZONTAL_SCROLL_MULTIPLIER = 0.75  # Multiplier for horizontal scroll speed (increase to scroll faster)

# Animation timing constraints
MIN_PAUSE_FRAMES_ABSOLUTE = 10  # Minimum frames to pause on each event (0.5 seconds at 20fps)
MIN_FRAME_DELAY_MS = 20  # 50 fps maximum
MAX_FRAME_DELAY_MS = 200  # 5 fps minimum

# Default display time and timing (used as fallback)
DEFAULT_DISPLAY_TIME = 15  # Default display time in seconds
DEFAULT_PAUSE_FRAMES = 30  # Default pause duration
DEFAULT_HORIZONTAL_SCROLL_SPEED = 1.5  # Default scroll speed
DEFAULT_FRAME_DELAY_MS = 100  # Default delay between frames in milliseconds

# ============================================================================
# Dynamic Timing Calculation
# ============================================================================

def calculate_animation_timing(display_time_seconds, num_events):
    """Calculate optimal animation timing based on display time and event count.

    Uses percentage-based allocation to dynamically calculate frame counts for
    scroll-in, pause, and scroll-out phases based on available time.

    Args:
        display_time_seconds: Available display time in seconds
        num_events: Number of events to display

    Returns:
        Dictionary with timing parameters:
        - scroll_in_frames: Frames for scroll in animation
        - pause_frames: Frames to pause on each event
        - scroll_out_frames: Frames for scroll out animation
        - final_pause_frames: Frames to pause before loop restart
        - horizontal_scroll_speed: Characters per frame for horizontal scrolling
        - frame_delay_ms: Milliseconds per frame
        - max_frames: Maximum frames for the entire animation
    """
    if num_events <= 0:
        return {
            "scroll_in_frames": 5,
            "pause_frames": DEFAULT_PAUSE_FRAMES,
            "scroll_out_frames": 8,
            "final_pause_frames": 5,
            "horizontal_scroll_speed": DEFAULT_HORIZONTAL_SCROLL_SPEED,
            "frame_delay_ms": DEFAULT_FRAME_DELAY_MS,
            "max_frames": 2400,
        }

    # Calculate total available frames
    total_available_frames = display_time_seconds * FRAMES_PER_SECOND

    # Reserve frames for final pause (percentage of total time)
    final_pause_frames = max(1, int(total_available_frames * PERCENT_FINAL_PAUSE))

    # Calculate frames available per event
    frames_for_events = total_available_frames - final_pause_frames
    frames_per_event = frames_for_events / num_events

    # Distribute frames per event based on percentages
    pause_frames = max(MIN_PAUSE_FRAMES_ABSOLUTE, int(frames_per_event * PERCENT_PAUSE))
    scroll_out_frames = max(1, int(frames_per_event * PERCENT_SCROLL_OUT))

    # Scroll-in gets the remainder
    percent_scroll_in = 1.0 - PERCENT_PAUSE - PERCENT_SCROLL_OUT
    scroll_in_frames = max(1, int(frames_per_event * percent_scroll_in))

    # Calculate horizontal scroll speed
    # We want to scroll through the text 1-2 times maximum during the pause
    # This prevents the "rapid looping" effect where text wraps many times
    # Assuming average text length of 20 characters, scroll ~25 chars total (1.25x through)
    chars_to_scroll = 25  # Scroll through text about once with some buffer
    base_speed = max(0.1, min(1.0, chars_to_scroll / float(pause_frames)))
    horizontal_scroll_speed = base_speed * HORIZONTAL_SCROLL_MULTIPLIER

    # Calculate total frames for the animation
    total_frames_estimate = (num_events * (scroll_in_frames + pause_frames + scroll_out_frames)) + final_pause_frames

    # Calculate frame delay to fit animation within display time
    frame_delay_ms = int((display_time_seconds * 1000) / total_frames_estimate) if total_frames_estimate > 0 else DEFAULT_FRAME_DELAY_MS

    # Clamp frame delay to reasonable bounds
    frame_delay_ms = max(MIN_FRAME_DELAY_MS, min(MAX_FRAME_DELAY_MS, frame_delay_ms))

    # Set max_frames based on actual animation duration (with some buffer)
    max_frames = int(total_frames_estimate * 1.2)  # 20% buffer for safety

    return {
        "scroll_in_frames": scroll_in_frames,
        "pause_frames": pause_frames,
        "scroll_out_frames": scroll_out_frames,
        "final_pause_frames": final_pause_frames,
        "horizontal_scroll_speed": horizontal_scroll_speed,
        "frame_delay_ms": frame_delay_ms,
        "max_frames": max_frames,
    }

# ============================================================================
# Data Fetching Functions (Phase 2)
# ============================================================================

def get_player_count():
    """Fetch current player count from Steam API"""
    response = http.get(STEAM_API_URL, ttl_seconds = PLAYER_CACHE_TTL)
    if response.status_code != 200:
        return None

    data = response.json()
    if data != None and data.get("response") != None and data["response"].get("player_count") != None:
        player_count = int(data["response"]["player_count"])
        return player_count

    return None

def get_current_events():
    """Fetch currently active events from ARCRaidersHub API with 12-hour cache.

    Parses hourly schedule data and returns events active in the current UTC hour.

    Note: Arc Raiders events are global - they happen at the same UTC time for everyone.
    Events are scheduled on an hourly basis (e.g., hour 14 = 14:00-15:00 UTC).
    """

    # Fetch from API (http.get handles caching with ttl_seconds)
    response = http.get(ARCRAIDERSHUB_API_URL, ttl_seconds = EVENTS_TABLE_CACHE_TTL)
    if response.status_code != 200:
        return None  # Return None to indicate API error

    response_data = response.json()
    if not response_data:
        return None  # Return None to indicate API error

    # Get schedule array
    schedule = response_data.get("schedule", [])
    if not schedule or type(schedule) != "list":
        return []  # Return empty list - no schedule data

    # Get current time in UTC
    now_utc = time.now().in_location("UTC")
    current_hour = now_utc.hour

    # Calculate end of current hour (start of next hour)
    # This gives us the timestamp when current events will end
    year = now_utc.year
    month = now_utc.month
    day = now_utc.day
    next_hour = (current_hour + 1) % 24
    next_day_offset = 1 if next_hour == 0 else 0

    # Create time at end of current hour
    end_of_hour = time.time(
        year = year,
        month = month,
        day = day + next_day_offset,
        hour = next_hour,
        minute = 0,
        second = 0,
        location = "UTC",
    )
    end_timestamp = int(end_of_hour.unix)

    # Find schedule entry for current hour
    current_schedule = None
    for entry in schedule:
        if type(entry) == "dict" and entry.get("hour") == current_hour:
            current_schedule = entry
            break

    if not current_schedule:
        return []  # No schedule for current hour

    # Extract events from each map
    active_events = []
    maps = response_data.get("maps", [])

    for map_name in maps:
        if type(map_name) != "string":
            continue

        map_data = current_schedule.get(map_name)
        if not map_data or type(map_data) != "dict":
            continue

        # Check for minor event
        minor_event = map_data.get("minor")
        if minor_event and type(minor_event) == "string":
            active_events.append({
                "name": minor_event,
                "map": map_name,
                "end_timestamp": end_timestamp,
            })

        # Check for major event
        major_event = map_data.get("major")
        if major_event and type(major_event) == "string":
            active_events.append({
                "name": major_event,
                "map": map_name,
                "end_timestamp": end_timestamp,
            })

    return active_events

def format_number(num):
    """Format number in K format (e.g., 286.2K)"""
    if num == None:
        return "N/A"

    if num >= 1000:
        thousands = num / 1000.0

        # Round to 1 decimal place by multiplying by 10, converting to int, then dividing by 10
        rounded = int(thousands * 10) / 10.0
        formatted = str(rounded)

        # Remove unnecessary .0 suffix
        if formatted.endswith(".0"):
            formatted = formatted[:-2]
        return "%sK" % formatted

    return str(num)

# ============================================================================
# Text Manipulation Functions (Phase 3)
# ============================================================================

def apply_horizontal_scroll(text, scroll_offset_float, viewport_width_chars):
    """Apply horizontal scrolling by manipulating text content with wrapping.

    This simulates horizontal scrolling by showing a substring of the text.
    Canvas stays at X=0, but content changes to create scrolling illusion.
    When scrolling past the end, the beginning wraps around to appear on the right.

    Args:
        text: Full text string
        scroll_offset_float: Number of characters scrolled as float (preserves sub-character precision)
        viewport_width_chars: How many characters fit on screen

    Returns:
        Substring of text to display for this scroll position (may wrap)
    """
    text_len = len(text)

    # If text fits, no scrolling needed
    if text_len <= viewport_width_chars:
        return text

    # Add spacing between wrapped text for clear visual separation
    wrapped_text = text + "  " + text + "  "  # 3 spaces
    wrapped_len = len(wrapped_text)

    # Convert float offset to int only when determining character position
    # This preserves smoothness by allowing fractional progress between characters
    scroll_offset = int(scroll_offset_float)

    # Use modulo to create infinite wrapping effect
    start_pos = scroll_offset % wrapped_len
    end_pos = start_pos + viewport_width_chars

    # Handle case where viewport spans beyond wrapped_text length
    if end_pos > wrapped_len:
        # Wrap around: take end of wrapped_text + beginning
        part1 = wrapped_text[start_pos:]
        part2 = wrapped_text[:end_pos - wrapped_len]
        return part1 + part2

    return wrapped_text[start_pos:end_pos]

def render_positioned_text(text, x, y, font, color):
    """Render text at absolute position with specified styling.

    Args:
        text: Text string to display
        x: X coordinate for padding
        y: Y coordinate for padding
        font: Font name to use
        color: Text color

    Returns:
        render.Padding with positioned Text child
    """
    return render.Padding(
        pad = (x, y, 0, 0),
        child = render.Text(
            content = text,
            font = font,
            color = color,
        ),
    )

def format_time_adaptive(remaining_seconds):
    """Format time string with adaptive resolution based on duration.

    Chooses the most appropriate time format to display meaningful information
    within the available screen space.

    Args:
        remaining_seconds: Number of seconds remaining

    Returns:
        Formatted string like:
        - "Ends In 02d 14h" for >= 100 hours
        - "Ends In 12h 34m" for >= 100 minutes
        - "Ends In 45m 23s" for < 100 minutes
        - "ended" for <= 0 seconds
    """
    if remaining_seconds <= 0:
        return "Ended"

    total_minutes = remaining_seconds // 60
    seconds = remaining_seconds % 60
    total_hours = total_minutes // 60
    minutes = total_minutes % 60
    days = total_hours // 24
    hours = total_hours % 24

    # Choose format based on what fits in available space with best resolution
    if total_hours >= 100:  # >= 100 hours, use days and hours
        d_str = ("0" + str(days)) if days < 10 else str(days)
        h_str = ("0" + str(hours)) if hours < 10 else str(hours)
        return "Ends In %sd %sh" % (d_str, h_str)
    elif total_minutes >= 100:  # >= 100 minutes, use hours and minutes
        h_str = ("0" + str(total_hours)) if total_hours < 10 else str(total_hours)
        m_str = ("0" + str(minutes)) if minutes < 10 else str(minutes)
        return "Ends In %sh %sm" % (h_str, m_str)
    else:  # < 100 minutes, use minutes and seconds
        m_str = ("0" + str(total_minutes)) if total_minutes < 10 else str(total_minutes)
        s_str = ("0" + str(seconds)) if seconds < 10 else str(seconds)
        return "Ends In %sm %ss" % (m_str, s_str)

def get_event_row_text(event, row_index, frame, animation_start_time, scroll_in_start, horizontal_scroll_speed):
    """Generate text content for an event row at a specific frame.

    Args:
        event: Event dictionary with name, map, end_timestamp
        row_index: Which row to generate (0=map, 1=name, 2=countdown)
        frame: Current frame number
        animation_start_time: Unix timestamp when animation generation started
        scroll_in_start: Frame when this event's animation started
        horizontal_scroll_speed: Characters to scroll per frame

    Returns:
        Text string for this row (with horizontal scroll applied if needed)
    """

    # Determine base text based on row
    base_text = ""
    if row_index == 0:
        # Map name
        base_text = event.get("map", "Unknown")
    elif row_index == 1:
        # Event name
        base_text = event.get("name", "Unknown")
    elif row_index == 2:
        # Countdown timer - calculate based on animation start time + frame offset
        # This allows countdown to continue accurately even when cycling through events
        seconds_since_start = frame / float(FRAMES_PER_SECOND)
        current_timestamp = animation_start_time + seconds_since_start
        end_timestamp = event.get("end_timestamp", 0)
        remaining_seconds = int(end_timestamp - current_timestamp)

        # Format time string using adaptive formatting
        base_text = format_time_adaptive(remaining_seconds)

    # Apply horizontal scrolling throughout all phases if text is too long
    viewport_chars = SCREEN_WIDTH // CHAR_WIDTH

    # Check if text needs scrolling (accounting for padding)
    usable_width = SCREEN_WIDTH - (4 * SCALE)  # 2px padding on each side (scaled)
    text_width = len(base_text) * CHAR_WIDTH
    if text_width > usable_width:
        frames_since_event_start = frame - scroll_in_start

        # Keep float precision for smoother scrolling
        scroll_offset_float = frames_since_event_start * horizontal_scroll_speed
        return apply_horizontal_scroll(base_text, scroll_offset_float, viewport_chars)

    return base_text

# ============================================================================
# Timeline System (Phase 4)
# ============================================================================

def build_timeline(events, scroll_in_frames, pause_frames, scroll_out_frames):
    """Build timeline showing frame ranges for each event's animation phases.

    Args:
        events: List of event dictionaries
        scroll_in_frames: Number of frames for scroll in animation
        pause_frames: Number of frames to pause on each event
        scroll_out_frames: Number of frames for scroll out animation

    Returns:
        List of timeline entries with frame ranges for each event
    """
    timeline = []
    current_frame = 0

    for event in events:
        # Calculate total duration per event (scroll in + pause + scroll out)
        event_duration = scroll_in_frames + pause_frames + scroll_out_frames

        timeline.append({
            "event": event,
            "scroll_in_start": current_frame,
            "scroll_in_frames": scroll_in_frames,
            "pause_start": current_frame + scroll_in_frames,
            "scroll_out_start": current_frame + scroll_in_frames + pause_frames,
            "scroll_out_frames": scroll_out_frames,
            "scroll_out_end": current_frame + event_duration,
        })

        current_frame += event_duration

    return timeline

def get_vertical_position(timeline_entry, frame, header_height):
    """Calculate Y coordinate for event content based on animation phase.

    Args:
        timeline_entry: Timeline entry dict with frame ranges and dynamic frame counts
        frame: Current frame number
        header_height: Height of header in pixels (event stops here during pause)

    Returns:
        Y coordinate in pixels
    """
    if frame < timeline_entry["pause_start"]:
        # Scroll in: bottom to top (stop at header_height)
        scroll_in_frames = timeline_entry["scroll_in_frames"]
        progress = (frame - timeline_entry["scroll_in_start"]) / float(scroll_in_frames)
        return int(SCREEN_HEIGHT - (progress * (SCREEN_HEIGHT - header_height)))
    elif frame < timeline_entry["scroll_out_start"]:
        # Pause: static at header_height
        return header_height
    else:
        # Scroll out: header_height to above screen (uses dynamic scroll_out_frames)
        scroll_out_frames = timeline_entry["scroll_out_frames"]
        progress = (frame - timeline_entry["scroll_out_start"]) / float(scroll_out_frames)

        # Smoothly move from header_height to fully off-screen (negative Y)
        # Add extra pixels to ensure content is completely offscreen
        distance_to_travel = header_height + EVENT_CONTENT_HEIGHT + (2 * SCALE)
        return int(header_height - (progress * distance_to_travel))

def get_current_event(timeline, frame):
    """Find which event is active at the current frame.

    Args:
        timeline: List of timeline entries
        frame: Current frame number

    Returns:
        Timeline entry dict or None if no event is active
    """
    for entry in timeline:
        if frame >= entry["scroll_in_start"] and frame < entry["scroll_out_end"]:
            return entry
    return None

# ============================================================================
# Frame Rendering (Phase 5)
# ============================================================================

def render_event_content(event, frame, timeline_entry, animation_start_time, vertical_y, horizontal_scroll_speed):
    """Render the content for a single event at a specific frame with absolute positioning.

    Args:
        event: Event dictionary with map, name, end_timestamp
        frame: Current frame number
        timeline_entry: Timeline entry with frame ranges
        animation_start_time: Unix timestamp when animation started
        vertical_y: Base Y position for the event content
        horizontal_scroll_speed: Characters to scroll per frame

    Returns:
        List of positioned children to add to the main Stack
    """

    # Generate text for each row
    row_height = 12 if canvas.is2x() else 6  # Height for each text row
    row_x = 2 * SCALE  # Left padding

    # Build content children with absolute positioning from base Y
    content_children = []

    # Row 0: Map name (white, tom-thumb)
    map_text = get_event_row_text(event, 0, frame, animation_start_time, timeline_entry["scroll_in_start"], horizontal_scroll_speed)
    row_y = vertical_y + 0
    content_children.append(render_positioned_text(map_text, row_x, row_y, FONT_EVENT, COLOR_WHITE))

    # Row 1: Event name (yellow, CG-pixel-3x5)
    event_text = get_event_row_text(event, 1, frame, animation_start_time, timeline_entry["scroll_in_start"], horizontal_scroll_speed)
    row_y = vertical_y + row_height
    content_children.append(render_positioned_text(event_text, row_x, row_y, FONT_EVENT, COLOR_YELLOW))

    # Row 2: Countdown (red, CG-pixel-3x5)
    time_text = get_event_row_text(event, 2, frame, animation_start_time, timeline_entry["scroll_in_start"], horizontal_scroll_speed)
    row_y = vertical_y + (row_height * 2)
    content_children.append(render_positioned_text(time_text, row_x, row_y, FONT_EVENT, COLOR_RED))

    # Return list of positioned children (no wrapping Box!)
    return content_children

def generate_animation_frames(events, header_height, timing):
    """Generate all animation frames for events with dynamic countdowns.

    Frames contain only event content; header is overlaid separately in render_display.

    Args:
        events: List of event dictionaries
        header_height: Height of header in pixels
        timing: Dictionary with animation timing parameters from calculate_animation_timing

    Returns:
        List of rendered frames (WITHOUT header - header added in Stack later)
    """
    if not events:
        return []

    # Extract timing parameters
    scroll_in_frames = timing["scroll_in_frames"]
    pause_frames = timing["pause_frames"]
    scroll_out_frames = timing["scroll_out_frames"]
    final_pause_frames = timing["final_pause_frames"]
    horizontal_scroll_speed = timing["horizontal_scroll_speed"]
    max_frames = timing["max_frames"]

    # Capture the animation start time once
    # This timestamp + frame offset = simulated "current time" for each frame
    animation_start_time = int(time.now().in_location("UTC").unix)

    frames = []

    # Build timeline for events with dynamic frame counts
    timeline = build_timeline(events, scroll_in_frames, pause_frames, scroll_out_frames)
    total_event_frames = timeline[-1]["scroll_out_end"] if timeline else 0

    # MAIN EVENT ANIMATION - generate frames without header (header overlaid later)
    for i in range(0, total_event_frames):
        # Get current event for this frame
        current_entry = get_current_event(timeline, i)
        if not current_entry:
            # No event active at this frame - empty frame
            frame = render.Stack(children = [])
            frames.append(frame)
            continue

        # Get vertical position
        vertical_y = get_vertical_position(current_entry, i, header_height)

        # Render event content - returns list of positioned children
        event_children = render_event_content(current_entry["event"], i, current_entry, animation_start_time, vertical_y, horizontal_scroll_speed)

        # Create frame with Stack of positioned children (no background box)
        frame = render.Stack(children = event_children)
        frames.append(frame)

        # Stop if we're approaching max_frames
        if len(frames) >= max_frames:
            break

    # Add final static frames (empty frames - header overlaid in Stack)
    # Brief pause before looping
    final_frame = render.Stack(children = [])

    # Add final pause frames before looping
    for _ in range(final_pause_frames):
        frames.append(final_frame)

    return frames

# ============================================================================
# Header & Display Assembly (Phase 6)
# ============================================================================

def build_header(player_count, show_player_count):
    """Build header children (logo and player count).

    Args:
        player_count: Player count number or None
        show_player_count: Whether to show player count

    Returns:
        List of render children for header
    """
    header_children = []

    # Add logo
    header_children.append(render.Image(src = ARC_RAIDERS_LOGO))

    # Add player count if enabled
    if show_player_count:
        player_text = format_number(player_count) if player_count != None else "N/A"
        header_children.append(
            render.Box(
                width = SCREEN_WIDTH,
                height = PLAYER_COUNT_HEIGHT,
                child = render.Padding(
                    pad = (SCALE, 0, 0, 0),
                    child = render.Row(
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(
                                content = "Players:",
                                font = FONT_HEADER,
                                color = COLOR_CYAN,
                            ),
                            render.Text(
                                content = player_text,
                                font = FONT_HEADER,
                                color = COLOR_GREEN,
                            ),
                        ],
                    ),
                ),
            ),
        )

    return header_children

def render_display(player_count, events, show_player_count, show_events, display_time_seconds, events_error = False):
    """Render the complete display based on available data.

    Args:
        player_count: Player count number or None
        events: List of event dictionaries
        show_player_count: Whether to show player count
        show_events: Whether to show events
        display_time_seconds: Display time in seconds (from server config)
        events_error: Whether there was an API error

    Returns:
        render.Root with complete display
    """

    # Calculate header height
    header_height = 8 * SCALE  # Logo height
    if show_player_count:
        header_height += PLAYER_COUNT_HEIGHT

    # Build header children
    header_children = build_header(player_count, show_player_count)

    # Calculate dynamic timing based on display time and number of events
    timing = calculate_animation_timing(display_time_seconds, len(events))
    delay = timing["frame_delay_ms"] // 2 if canvas.is2x() else timing["frame_delay_ms"]

    # Create display based on events state
    if show_events:
        if len(events) > 0:
            # Generate animation frames for events with dynamic timing
            frames = generate_animation_frames(events, header_height, timing)

            if frames:
                # Overlay header on top of animation using Stack
                return render.Root(
                    delay = delay,
                    child = render.Stack(
                        children = [
                            render.Animation(children = frames),  # Background: scrolling events
                            render.Box(
                                width = SCREEN_WIDTH,
                                height = header_height,
                                color = COLOR_BLACK,
                                child = render.Column(children = header_children),  # Foreground: fixed header
                            ),
                        ],
                    ),
                )

        # No events or empty frames - show message
        if events_error:
            message = "API Error: Invalid data"
            message_color = COLOR_RED
        else:
            message = "No active events"
            message_color = COLOR_CYAN

        # Create static display with message and header overlay
        return render.Root(
            delay = delay,
            child = render.Stack(
                children = [
                    render.Box(
                        width = SCREEN_WIDTH,
                        height = SCREEN_HEIGHT,
                        child = render.Padding(
                            pad = (2 * SCALE, header_height + 2 * SCALE, 2 * SCALE, 0),
                            child = render.WrappedText(
                                content = message,
                                font = FONT_HEADER,
                                color = message_color,
                            ),
                        ),
                    ),
                    render.Box(
                        width = SCREEN_WIDTH,
                        height = header_height,
                        color = COLOR_BLACK,
                        child = render.Column(children = header_children),
                    ),
                ],
            ),
        )

    # Events disabled, just show header
    return render.Root(
        delay = delay,
        child = render.Column(children = header_children),
    )

# ============================================================================
# Configuration & Entry Point (Phase 7)
# ============================================================================

def main(config):
    """Main entry point for the applet.

    Args:
        config: Configuration object

    Returns:
        render.Root with complete display
    """

    # Always show both player count and events
    show_player_count = True
    show_events = True

    # Get display time from server config (passed as $display_time)
    # Note: This is set by the Tidbyt server based on user's rotation settings
    # and is not directly configurable by the user in the app schema
    # Falls back to default if not provided
    display_time_seconds = int(config.get("$display_time", str(DEFAULT_DISPLAY_TIME)))

    # Get player count
    player_count = None
    if show_player_count:
        player_count = get_player_count()

    # Get event timers
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

    return render_display(player_count, current_events, show_player_count, show_events, display_time_seconds, events_error)

def get_schema():
    """Define configuration schema for the applet.

    Returns:
        schema.Schema with no configuration options
    """
    return schema.Schema(
        version = "1",
        fields = [],
    )
