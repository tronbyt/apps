"""
Applet: VNStat Network Monitor
Summary: Network usage statistics
Description: Display network usage statistics from VNStat via OPNsense API including total and monthly data transfer amounts.
Author: StarrLord
"""

load("http.star", "http")
load("math.star", "math")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

# Constants
DEFAULT_CACHE_TTL = 300  # 5 minutes
DEFAULT_BASE_URL = "http://192.168.1.1"

# Colors
COLOR_PRIMARY = "#00FF00"
COLOR_SECONDARY = "#FFFF00"
COLOR_TEXT = "#FFFFFF"
COLOR_ERROR = "#FF0000"
COLOR_BACKGROUND = "#000000"
COLOR_HEADER = "#333333"

# Fonts
FONT_SMALL = "tom-thumb"
FONT_MEDIUM = "tb-8"
FONT_LARGE = "6x13"

def main(config):
    """Main function that renders the Tidbyt display"""

    # Get configuration - handle empty strings properly
    base_url = config.get("baseUrl", DEFAULT_BASE_URL)
    api_key = config.get("apiKey", "")
    api_secret = config.get("apiSecret", "")
    cache_ttl = int(config.get("cacheTtl") or DEFAULT_CACHE_TTL)
    animation_type = config.get("animationType", "slide")

    # Clean up configuration values (strip whitespace, treat empty as None)
    if base_url:
        base_url = base_url.strip()
        if not base_url:
            base_url = None
    if api_key:
        api_key = api_key.strip()
        if not api_key:
            api_key = None
    if api_secret:
        api_secret = api_secret.strip()
        if not api_secret:
            api_secret = None

    # Check for required configuration
    missing_fields = []
    if not base_url:
        missing_fields.append("Base URL")
    if not api_key:
        missing_fields.append("API Key")
    if not api_secret:
        missing_fields.append("API Secret")

    # If missing credentials, use demo data for preview
    if missing_fields:
        data = {
            "total_received": 2.5,  # 2.5 GB today received
            "total_transmitted": 1.8,  # 1.8 GB today transmitted
            "monthly_received": 45.2,  # 45.2 GB monthly received
            "monthly_transmitted": 32.1,  # 32.1 GB monthly transmitted
        }
        status_message = "DEMO"
    else:
        # Fetch real data
        data, error = fetch_vnstat_data(base_url, api_key, api_secret, cache_ttl)
        if error:
            # Fall back to demo data on API error
            data = {
                "total_received": 2.5,
                "total_transmitted": 1.8,
                "monthly_received": 45.2,
                "monthly_transmitted": 32.1,
            }
            status_message = "ERROR"
        elif not data or (data["total_received"] == 0 and data["total_transmitted"] == 0):
            # Fall back to demo data when no data available
            data = {
                "total_received": 2.5,
                "total_transmitted": 1.8,
                "monthly_received": 45.2,
                "monthly_transmitted": 32.1,
            }
            status_message = "NO DATA"
        else:
            status_message = "LIVE"

    # Create animation based on selected type
    frames = create_animation_frames(data, status_message, animation_type)
    delay = get_animation_delay(animation_type)

    return render.Root(
        max_age = cache_ttl,
        delay = delay,
        child = render.Animation(
            children = frames,
        ),
    )

def get_animation_delay(animation_type):
    """Get appropriate delay for animation type"""
    delays = {
        "slide": 100,
        "counter": 80,
        "particle": 60,
        "matrix": 50,
        "fade": 120,
        "zoom": 90,
        "wave": 70,
    }
    return delays.get(animation_type, 100)

def create_animation_frames(data, status_message, animation_type):
    """Create animation frames based on selected type"""
    if animation_type == "slide":
        return create_simple_sliding_frames(data, status_message)
    elif animation_type == "counter":
        return create_counter_frames(data, status_message)
    elif animation_type == "particle":
        return create_particle_frames(data, status_message)
    elif animation_type == "matrix":
        return create_matrix_frames(data, status_message)
    elif animation_type == "fade":
        return create_fade_frames(data, status_message)
    elif animation_type == "zoom":
        return create_zoom_frames(data, status_message)
    elif animation_type == "wave":
        return create_wave_frames(data, status_message)
    else:
        return create_simple_sliding_frames(data, status_message)

def create_simple_sliding_frames(data, status_message):
    """Create simple sliding animation frames"""
    frames = []

    # Create the 4 metric displays
    displays = [
        create_metric_display("Today RX", format_bytes(data["total_received"]), COLOR_PRIMARY, status_message),
        create_metric_display("Today TX", format_bytes(data["total_transmitted"]), COLOR_SECONDARY, status_message),
        create_metric_display("Month RX", format_bytes(data["monthly_received"]), COLOR_PRIMARY, status_message),
        create_metric_display("Month TX", format_bytes(data["monthly_transmitted"]), COLOR_SECONDARY, status_message),
    ]

    static_frames = 30  # 3 seconds static
    slide_frames = 8  # 0.8 seconds sliding

    for i in range(len(displays)):
        current_display = displays[i]
        next_display = displays[(i + 1) % len(displays)]

        # Static frames showing current display
        for _ in range(static_frames):
            frames.append(current_display)

        # Sliding frames to next display
        for frame in range(slide_frames):
            slide_progress = (frame + 1) / slide_frames
            slide_distance = int(64 * slide_progress)

            frames.append(render.Stack(
                children = [
                    # Current display sliding out left
                    render.Padding(
                        pad = (-slide_distance, 0, 0, 0),
                        child = current_display,
                    ),
                    # Next display sliding in from right
                    render.Padding(
                        pad = (64 - slide_distance, 0, 0, 0),
                        child = next_display,
                    ),
                ],
            ))

    return frames

def create_counter_frames(data, status_message):
    """Create counter effect animation frames"""
    frames = []

    metrics = [
        {"label": "Today RX", "value": data["total_received"], "color": COLOR_PRIMARY},
        {"label": "Today TX", "value": data["total_transmitted"], "color": COLOR_SECONDARY},
        {"label": "Month RX", "value": data["monthly_received"], "color": COLOR_PRIMARY},
        {"label": "Month TX", "value": data["monthly_transmitted"], "color": COLOR_SECONDARY},
    ]

    static_frames = 15  # 1.2 seconds static
    counter_frames = 25  # 2 seconds counting

    for metric in metrics:
        target_value = metric["value"]
        formatted_target = format_bytes(target_value)

        # Counter animation frames
        for frame in range(counter_frames):
            progress = frame / (counter_frames - 1)
            current_value = target_value * progress
            current_formatted = format_bytes(current_value)

            frames.append(create_metric_display(
                metric["label"],
                current_formatted,
                metric["color"],
                status_message,
            ))

        # Static frames showing final value
        for _ in range(static_frames):
            frames.append(create_metric_display(
                metric["label"],
                formatted_target,
                metric["color"],
                status_message,
            ))

    return frames

def create_particle_frames(data, status_message):
    """Create particle explosion animation frames"""
    frames = []

    metrics = [
        {"label": "Today RX", "value": data["total_received"], "color": COLOR_PRIMARY},
        {"label": "Today TX", "value": data["total_transmitted"], "color": COLOR_SECONDARY},
        {"label": "Month RX", "value": data["monthly_received"], "color": COLOR_PRIMARY},
        {"label": "Month TX", "value": data["monthly_transmitted"], "color": COLOR_SECONDARY},
    ]

    static_frames = 20  # 1.2 seconds static
    particle_frames = 30  # 1.8 seconds particles

    for metric in metrics:
        target_value = format_bytes(metric["value"])

        # Particle explosion frames
        for frame in range(particle_frames):
            progress = frame / (particle_frames - 1)
            frames.append(create_particle_background_display(
                metric["label"],
                target_value,
                metric["color"],
                status_message,
                progress,
            ))

        # Static frames - keep particle background
        for _ in range(static_frames):
            frames.append(create_particle_background_display(
                metric["label"],
                target_value,
                metric["color"],
                status_message,
                1.0,  # Full progress for final state
            ))

    return frames

def create_matrix_frames(data, status_message):
    """Create matrix rain animation frames"""
    frames = []

    metrics = [
        {"label": "Today RX", "value": data["total_received"], "color": COLOR_PRIMARY},
        {"label": "Today TX", "value": data["total_transmitted"], "color": COLOR_SECONDARY},
        {"label": "Month RX", "value": data["monthly_received"], "color": COLOR_PRIMARY},
        {"label": "Month TX", "value": data["monthly_transmitted"], "color": COLOR_SECONDARY},
    ]

    static_frames = 20  # 1 second static
    matrix_frames = 40  # 2 seconds matrix effect

    for metric in metrics:
        target_value = format_bytes(metric["value"])

        # Matrix rain frames
        for frame in range(matrix_frames):
            progress = frame / (matrix_frames - 1)
            frames.append(create_matrix_background_display(
                metric["label"],
                target_value,
                metric["color"],
                status_message,
                progress,
            ))

        # Static frames - keep matrix background
        for _ in range(static_frames):
            frames.append(create_matrix_background_display(
                metric["label"],
                target_value,
                metric["color"],
                status_message,
                1.0,  # Full progress for final state
            ))

    return frames

def create_fade_frames(data, status_message):
    """Create fade transition animation frames"""
    frames = []

    displays = [
        {"label": "Today RX", "value": format_bytes(data["total_received"]), "color": COLOR_PRIMARY},
        {"label": "Today TX", "value": format_bytes(data["total_transmitted"]), "color": COLOR_SECONDARY},
        {"label": "Month RX", "value": format_bytes(data["monthly_received"]), "color": COLOR_PRIMARY},
        {"label": "Month TX", "value": format_bytes(data["monthly_transmitted"]), "color": COLOR_SECONDARY},
    ]

    static_frames = 25  # 3 seconds static
    fade_frames = 10  # 1.2 seconds fade

    for i in range(len(displays)):
        current = displays[i]
        next_display = displays[(i + 1) % len(displays)]

        # Static frames
        for _ in range(static_frames):
            frames.append(create_metric_display(
                current["label"],
                current["value"],
                current["color"],
                status_message,
            ))

        # Fade transition frames
        for frame in range(fade_frames):
            progress = (frame + 1) / fade_frames
            frames.append(create_fade_display(
                current,
                next_display,
                status_message,
                progress,
            ))

    return frames

def create_zoom_frames(data, status_message):
    """Create zoom effect animation frames"""
    frames = []

    metrics = [
        {"label": "Today RX", "value": data["total_received"], "color": COLOR_PRIMARY},
        {"label": "Today TX", "value": data["total_transmitted"], "color": COLOR_SECONDARY},
        {"label": "Month RX", "value": data["monthly_received"], "color": COLOR_PRIMARY},
        {"label": "Month TX", "value": data["monthly_transmitted"], "color": COLOR_SECONDARY},
    ]

    static_frames = 20  # 1.8 seconds static
    zoom_frames = 15  # 1.35 seconds zoom

    for metric in metrics:
        target_value = format_bytes(metric["value"])

        # Zoom in frames
        for frame in range(zoom_frames):
            progress = frame / (zoom_frames - 1)
            frames.append(create_zoom_display(
                metric["label"],
                target_value,
                metric["color"],
                status_message,
                progress,
            ))

        # Static frames
        for _ in range(static_frames):
            frames.append(create_metric_display(
                metric["label"],
                target_value,
                metric["color"],
                status_message,
            ))

    return frames

def create_wave_frames(data, status_message):
    """Create wave pattern animation frames"""
    frames = []

    metrics = [
        {"label": "Today RX", "value": data["total_received"], "color": COLOR_PRIMARY},
        {"label": "Today TX", "value": data["total_transmitted"], "color": COLOR_SECONDARY},
        {"label": "Month RX", "value": data["monthly_received"], "color": COLOR_PRIMARY},
        {"label": "Month TX", "value": data["monthly_transmitted"], "color": COLOR_SECONDARY},
    ]

    static_frames = 20  # 1.4 seconds static
    wave_frames = 25  # 1.75 seconds wave

    for metric in metrics:
        target_value = format_bytes(metric["value"])

        # Wave animation frames
        for frame in range(wave_frames):
            progress = frame / (wave_frames - 1)
            frames.append(create_wave_display(
                metric["label"],
                target_value,
                metric["color"],
                status_message,
                progress,
            ))

        # Static frames
        for _ in range(static_frames):
            frames.append(create_metric_display(
                metric["label"],
                target_value,
                metric["color"],
                status_message,
            ))

    return frames

def create_slide_frame(current_metric, next_metric, slide_progress, status_message):
    """Create a single frame of the sliding animation"""
    slide_distance = int(64 * slide_progress)  # How far to slide (0 to 64 pixels)

    return render.Stack(
        children = [
            # Current metric sliding out to the left
            render.Padding(
                pad = (-slide_distance, 0, 0, 0),
                child = create_metric_display(
                    current_metric["label"],
                    current_metric["value"],
                    current_metric["color"],
                    status_message,
                ),
            ),
            # Next metric sliding in from the right
            render.Padding(
                pad = (64 - slide_distance, 0, 0, 0),
                child = create_metric_display(
                    next_metric["label"],
                    next_metric["value"],
                    next_metric["color"],
                    status_message,
                ),
            ),
        ],
    )

def create_metric_display(label, value, color, status):
    """Create a display for a single metric"""
    return render.Column(
        expanded = True,
        main_align = "space_between",
        children = [
            # Header
            render.Box(
                height = 8,
                color = COLOR_HEADER,
                child = render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Padding(
                            pad = (2, 1, 0, 0),
                            child = render.Text(
                                content = label,
                                font = FONT_SMALL,
                                color = COLOR_TEXT,
                            ),
                        ),
                        render.Padding(
                            pad = (0, 1, 2, 0),
                            child = render.Text(
                                content = status,
                                font = FONT_SMALL,
                                color = COLOR_TEXT,
                            ),
                        ),
                    ],
                ),
            ),
            # Main content
            render.Box(
                height = 24,
                color = COLOR_BACKGROUND,
                child = render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Text(
                            content = value,
                            font = FONT_LARGE,
                            color = color,
                        ),
                    ],
                ),
            ),
        ],
    )

def create_particle_scatter_display(label, text_length, color, status):
    """Create scattered particles effect"""

    # Generate simple scattered characters
    scatter_chars = "oO*+x.-"
    random_text = ""
    for i in range(text_length):
        char_index = (i * 3 + 5) % len(scatter_chars)  # Pseudo-random
        random_text += scatter_chars[char_index]

    return render.Column(
        expanded = True,
        main_align = "space_between",
        children = [
            # Header
            render.Box(
                height = 8,
                color = COLOR_HEADER,
                child = render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Padding(
                            pad = (2, 1, 0, 0),
                            child = render.Text(
                                content = label,
                                font = FONT_SMALL,
                                color = COLOR_TEXT,
                            ),
                        ),
                        render.Padding(
                            pad = (0, 1, 2, 0),
                            child = render.Text(
                                content = status,
                                font = FONT_SMALL,
                                color = COLOR_TEXT,
                            ),
                        ),
                    ],
                ),
            ),
            # Scattered particles
            render.Box(
                height = 24,
                color = COLOR_BACKGROUND,
                child = render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Text(
                            content = random_text,
                            font = FONT_LARGE,
                            color = color,
                        ),
                    ],
                ),
            ),
        ],
    )

def create_particle_background_display(label, target_value, color, status, progress):
    """Create full-screen particle explosion effect"""

    # Create background particle field
    particle_elements = []

    # Generate particles across the entire screen
    for y in range(0, 32, 4):  # Every 4 pixels vertically
        for x in range(0, 64, 6):  # Every 6 pixels horizontally
            # Particle animation based on distance from center and progress
            center_x, center_y = 32, 16
            dx = x - center_x
            dy = y - center_y
            distance = math.sqrt(dx * dx + dy * dy)

            # Particles appear at different times based on distance
            appear_time = (distance / 30.0) * 0.6  # Normalize distance

            if progress >= appear_time:
                # Choose particle character based on position
                particles = "*+.ox"
                char_index = (x + y + int(progress * 20)) % len(particles)
                particle_char = particles[char_index]

                # Particle fades as explosion progresses
                particle_color = color if progress < 0.7 else "#666666"

                particle_elements.append(
                    render.Padding(
                        pad = (x, y, 0, 0),
                        child = render.Text(
                            content = particle_char,
                            font = FONT_SMALL,
                            color = particle_color,
                        ),
                    ),
                )

    # Create main content overlay
    main_content = create_metric_display(label, target_value, color, status)

    # Stack background particles with main content
    return render.Stack(
        children = particle_elements + [main_content],
    )

def create_matrix_background_display(label, target_value, color, status, progress):
    """Create full-screen matrix rain effect"""

    # Create matrix rain background
    matrix_elements = []
    matrix_chars = "01ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

    # Create falling columns of text
    for x in range(0, 64, 4):  # Columns every 4 pixels
        for y in range(0, 32, 3):  # Rows every 3 pixels
            # Calculate animation offset
            fall_offset = int((progress * 50 + x * 3) % 35) - 3
            actual_y = y + fall_offset

            # Only show if within screen bounds
            if actual_y >= 0 and actual_y <= 29:
                # Character changes over time
                char_index = int((progress * 30 + x + y) % len(matrix_chars))
                matrix_char = matrix_chars[char_index]

                # Fade characters based on position in fall
                char_color = color if actual_y < 20 else "#006600"

                matrix_elements.append(
                    render.Padding(
                        pad = (x, actual_y, 0, 0),
                        child = render.Text(
                            content = matrix_char,
                            font = FONT_SMALL,
                            color = char_color,
                        ),
                    ),
                )

    # Create main content overlay with semi-transparent background
    content_background = render.Box(
        width = 60,
        height = 28,
        color = "#001100",  # Dark background
        child = render.Column(
            expanded = True,
            main_align = "space_between",
            children = [
                # Header
                render.Box(
                    height = 8,
                    color = "#002200",
                    child = render.Row(
                        expanded = True,
                        main_align = "space_between",
                        children = [
                            render.Padding(
                                pad = (2, 1, 0, 0),
                                child = render.Text(
                                    content = label,
                                    font = FONT_SMALL,
                                    color = color,
                                ),
                            ),
                            render.Padding(
                                pad = (0, 1, 2, 0),
                                child = render.Text(
                                    content = status,
                                    font = FONT_SMALL,
                                    color = color,
                                ),
                            ),
                        ],
                    ),
                ),
                # Main content
                render.Box(
                    height = 18,
                    child = render.Column(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(
                                content = target_value,
                                font = FONT_LARGE,
                                color = color,
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

    # Stack matrix rain with content overlay
    return render.Stack(
        children = matrix_elements + [
            render.Padding(
                pad = (2, 2, 0, 0),
                child = content_background,
            ),
        ],
    )

def create_matrix_display(label, target_value, color, status, progress):
    """Create matrix rain effect"""

    # Simple left-to-right reveal with falling effect
    result_text = ""
    reveal_count = int(len(target_value) * progress)

    if reveal_count > len(target_value):
        reveal_count = len(target_value)

    for i in range(len(target_value)):
        if i < reveal_count:
            result_text += target_value[i]
        else:
            # Cycle through matrix characters
            if (i + int(progress * 10)) % 3 == 0:
                result_text += "0"
            elif (i + int(progress * 10)) % 3 == 1:
                result_text += "1"
            else:
                result_text += "X"

    return render.Column(
        expanded = True,
        main_align = "space_between",
        children = [
            # Header
            render.Box(
                height = 8,
                color = COLOR_HEADER,
                child = render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Padding(
                            pad = (2, 1, 0, 0),
                            child = render.Text(
                                content = label,
                                font = FONT_SMALL,
                                color = COLOR_TEXT,
                            ),
                        ),
                        render.Padding(
                            pad = (0, 1, 2, 0),
                            child = render.Text(
                                content = status,
                                font = FONT_SMALL,
                                color = COLOR_TEXT,
                            ),
                        ),
                    ],
                ),
            ),
            # Matrix text
            render.Box(
                height = 24,
                color = COLOR_BACKGROUND,
                child = render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Text(
                            content = result_text,
                            font = FONT_LARGE,
                            color = color,
                        ),
                    ],
                ),
            ),
        ],
    )

def create_fade_display(current, next_display, status, progress):
    """Create fade transition between displays"""

    # Simple fade by showing current until midpoint, then next
    if progress < 0.5:
        return create_metric_display(
            current["label"],
            current["value"],
            current["color"],
            status,
        )
    else:
        return create_metric_display(
            next_display["label"],
            next_display["value"],
            next_display["color"],
            status,
        )

def create_zoom_display(label, target_value, color, status, progress):
    """Create zoom effect using different font sizes"""

    # Start small and grow to normal size
    if progress < 0.3:
        font = FONT_SMALL
    elif progress < 0.7:
        font = FONT_MEDIUM
    else:
        font = FONT_LARGE

    return render.Column(
        expanded = True,
        main_align = "space_between",
        children = [
            # Header
            render.Box(
                height = 8,
                color = COLOR_HEADER,
                child = render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Padding(
                            pad = (2, 1, 0, 0),
                            child = render.Text(
                                content = label,
                                font = FONT_SMALL,
                                color = COLOR_TEXT,
                            ),
                        ),
                        render.Padding(
                            pad = (0, 1, 2, 0),
                            child = render.Text(
                                content = status,
                                font = FONT_SMALL,
                                color = COLOR_TEXT,
                            ),
                        ),
                    ],
                ),
            ),
            # Zooming text
            render.Box(
                height = 24,
                color = COLOR_BACKGROUND,
                child = render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Text(
                            content = target_value,
                            font = font,
                            color = color,
                        ),
                    ],
                ),
            ),
        ],
    )

def create_wave_display(label, target_value, color, status, progress):
    """Create wave pattern effect"""

    # Simple wave effect - characters appear in groups
    result_text = ""
    wave_position = int(progress * len(target_value) * 2)

    for i in range(len(target_value)):
        # Show character if wave has passed this position
        if i <= wave_position or progress > 0.9:
            result_text += target_value[i]
        else:
            # Show dots before the wave
            result_text += "."

    return render.Column(
        expanded = True,
        main_align = "space_between",
        children = [
            # Header
            render.Box(
                height = 8,
                color = COLOR_HEADER,
                child = render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Padding(
                            pad = (2, 1, 0, 0),
                            child = render.Text(
                                content = label,
                                font = FONT_SMALL,
                                color = COLOR_TEXT,
                            ),
                        ),
                        render.Padding(
                            pad = (0, 1, 2, 0),
                            child = render.Text(
                                content = status,
                                font = FONT_SMALL,
                                color = COLOR_TEXT,
                            ),
                        ),
                    ],
                ),
            ),
            # Wave text
            render.Box(
                height = 24,
                color = COLOR_BACKGROUND,
                child = render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Text(
                            content = result_text,
                            font = FONT_LARGE,
                            color = color,
                        ),
                    ],
                ),
            ),
        ],
    )

def fetch_vnstat_data(base_url, api_key, api_secret, cache_ttl):
    """Fetch network statistics from VNStat API"""

    # Construct the API URL
    endpoint = "/api/vnstat/service/daily"
    url = base_url.rstrip("/") + endpoint

    # Make the API request with basic authentication
    response = http.get(
        url = url,
        auth = (api_key, api_secret),
        ttl_seconds = cache_ttl,
    )

    if response.status_code != 200:
        return None, "API Error: {}".format(response.status_code)

    # Parse the JSON response first
    json_data = response.json()
    if not json_data:
        return None, "Invalid JSON response"

    if "response" not in json_data:
        return None, "No 'response' field in JSON"

    raw_data = json_data["response"]
    return parse_vnstat_response(raw_data), None

def parse_vnstat_response(raw_data):
    """Parse VNStat response text and extract statistics"""

    # Clean up the raw text - handle escaped characters from JSON
    clean_text = raw_data.replace("\\n", "\n").replace("\\/", "/")
    lines = clean_text.strip().split("\n")

    # Initialize totals for monthly data (sum of all daily entries)
    monthly_received = 0.0
    monthly_transmitted = 0.0

    # Initialize today's estimated data
    today_received = 0.0
    today_transmitted = 0.0

    # Process data lines to calculate monthly totals
    for line in lines:
        # Skip non-data lines - only process lines with dates
        if not line or "estimated" in line or line.startswith("---") or "day" in line:
            continue

        # Look for lines with date pattern MM/DD/YY (this matches daily data lines)
        if re.search(r"\d{2}/\d{2}/\d{2}", line) and "GiB" in line:
            # Split by pipe and extract GiB values using string manipulation
            parts = line.split("|")
            if len(parts) >= 3:
                # Extract RX value (first part after date)
                rx_part = parts[0].strip()
                if "GiB" in rx_part:
                    # Find the number before " GiB"
                    rx_text = rx_part.split("GiB")[0].strip()
                    rx_words = rx_text.split()
                    if rx_words:
                        rx_str = rx_words[-1]
                        if "." in rx_str or rx_str.isdigit():
                            monthly_received += float(rx_str)

                # Extract TX value (second part)
                tx_part = parts[1].strip()
                if "GiB" in tx_part:
                    # Find the number before " GiB"
                    tx_text = tx_part.split("GiB")[0].strip()
                    tx_words = tx_text.split()
                    if tx_words:
                        tx_str = tx_words[-1]
                        if "." in tx_str or tx_str.isdigit():
                            monthly_transmitted += float(tx_str)

    # Find and parse estimated line for today's usage
    for line in lines:
        if "estimated" in line:
            # Split by pipe and extract GiB values using string manipulation
            parts = line.split("|")
            if len(parts) >= 3:
                # Extract RX value (first part after "estimated")
                rx_part = parts[0].strip()
                if "GiB" in rx_part:
                    # Find the number before " GiB"
                    rx_text = rx_part.split("GiB")[0].strip()
                    rx_words = rx_text.split()
                    if rx_words:
                        rx_str = rx_words[-1]
                        if "." in rx_str or rx_str.isdigit():
                            today_received = float(rx_str)

                # Extract TX value (second part)
                tx_part = parts[1].strip()
                if "GiB" in tx_part:
                    # Find the number before " GiB"
                    tx_text = tx_part.split("GiB")[0].strip()
                    tx_words = tx_text.split()
                    if tx_words:
                        tx_str = tx_words[-1]
                        if "." in tx_str or tx_str.isdigit():
                            today_transmitted = float(tx_str)
            break

    # Return the four metrics to display: Today's estimated usage and Total monthly usage
    return {
        "total_received": today_received,  # Today's estimated RX (from estimated line)
        "total_transmitted": today_transmitted,  # Today's estimated TX (from estimated line)
        "monthly_received": monthly_received,  # Total month RX (sum of all daily data)
        "monthly_transmitted": monthly_transmitted,  # Total month TX (sum of all daily data)
    }

def format_bytes(gb_value):
    """Format bytes for display"""
    if gb_value >= 1000:
        tb_value = math.round(gb_value / 100) / 10  # Round to 1 decimal place
        return "{}TB".format(tb_value)
    elif gb_value >= 1:
        gb_rounded = math.round(gb_value * 10) / 10  # Round to 1 decimal place
        return "{}GB".format(gb_rounded)
    else:
        mb_value = math.round(gb_value * 1000)
        return "{}MB".format(mb_value)

def error_display(message):
    """Display an error message"""
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(
                    content = "VNStat ERROR",
                    font = FONT_MEDIUM,
                    color = COLOR_ERROR,
                ),
                render.Text(
                    content = message,
                    font = FONT_SMALL,
                    color = COLOR_ERROR,
                ),
            ],
        ),
    )

def get_schema():
    """Define the configuration schema"""

    cache_options = [
        schema.Option(
            display = "5 minutes",
            value = "300",
        ),
        schema.Option(
            display = "15 minutes",
            value = "900",
        ),
        schema.Option(
            display = "30 minutes",
            value = "1800",
        ),
        schema.Option(
            display = "1 hour",
            value = "3600",
        ),
        schema.Option(
            display = "4 hours",
            value = "14400",
        ),
    ]

    animation_options = [
        schema.Option(
            display = "Sliding (Classic)",
            value = "slide",
        ),
        schema.Option(
            display = "Counter Effect",
            value = "counter",
        ),
        schema.Option(
            display = "Particle Explosion",
            value = "particle",
        ),
        schema.Option(
            display = "Matrix Rain",
            value = "matrix",
        ),
        schema.Option(
            display = "Fade Transition",
            value = "fade",
        ),
        schema.Option(
            display = "Zoom Effect",
            value = "zoom",
        ),
        schema.Option(
            display = "Wave Pattern",
            value = "wave",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "baseUrl",
                name = "Base URL",
                desc = "The base URL of your OPNsense router (e.g., http://192.168.1.1)",
                icon = "link",
                default = DEFAULT_BASE_URL,
            ),
            schema.Text(
                id = "apiKey",
                name = "API Key",
                desc = "Your OPNsense API key for VNStat access",
                icon = "key",
            ),
            schema.Text(
                id = "apiSecret",
                name = "API Secret",
                desc = "Your OPNsense API secret for VNStat access",
                icon = "lock",
            ),
            schema.Dropdown(
                id = "cacheTtl",
                name = "Refresh Interval",
                desc = "How often to fetch new data",
                icon = "clock",
                default = cache_options[1].value,
                options = cache_options,
            ),
            schema.Dropdown(
                id = "animationType",
                name = "Animation Effect",
                desc = "Choose the visual animation style",
                icon = "wandMagicSparkles",
                default = animation_options[0].value,
                options = animation_options,
            ),
        ],
    )
