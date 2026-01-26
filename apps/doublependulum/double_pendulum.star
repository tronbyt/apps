load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("simulations.star", "ALL_SIMULATIONS")
load("time.star", "time")

# API endpoint for fetching simulations
API_URL = "https://wildc.net/dp/api.py"

# Cache TTL in seconds
CACHE_TTL = 15

# Display constants (matching generate_pixlet.py)
# Pendulum length constraints (matching API defaults)
LENGTH_1_MAX = 6.0
LENGTH_2_MAX = 7.2

# Use slightly smaller extent for better variety (allows some off-screen for large pendulums)
MAX_EXTENT = 11.0  # More aggressive than actual max (13.2) for better visual variety

def get_layout(width, height):
    """Calculate layout parameters based on screen dimensions."""
    origin_x = int(width / 2)
    origin_y = int(height * 0.35)  # 35% down from top

    padding = 0
    scale_y = (float(height) * 0.65 - padding) / MAX_EXTENT
    scale = int(scale_y * 10) / 10.0

    return struct(
        origin_x = origin_x,
        origin_y = origin_y,
        scale = scale,
        width = width,
        height = height,
    )

def fetch_simulation(seed, layout, generation_id = None):
    """Fetch a simulation from the API and transform coordinates to pixel space."""
    cache_key = ("gen_" + str(generation_id) if generation_id else "sim_" + str(seed)) + "_" + str(layout.width)

    # Try to get from cache first
    cached = cache.get(cache_key)
    if cached != None:
        return json.decode(cached)

    # Build URL - either from specific generation or random API
    if generation_id:
        url = "https://wildc.net/dp/generations/" + str(generation_id) + ".json"
    else:
        # Request a simulation with specific seed for reproducibility
        url = API_URL + "?mode=random&duration=20&step_size=0.033&seed=" + str(seed)

    # Fetch from API
    response = http.get(url, ttl_seconds = CACHE_TTL)
    if response.status_code != 200:
        print("API request failed: " + str(response.status_code))
        return None

    # Parse JSON response
    data = response.json()
    trajectory = data.get("trajectory", [])
    sim_name = data.get("name", "api")

    # Calculate max Y for second bob only (lower pendulum)
    y2_max = -MAX_EXTENT
    for point in trajectory:
        if len(point) >= 4:
            y2 = point[3]  # y2 is the Y coordinate of the second bob
            if y2 > y2_max:
                y2_max = y2

    # Determine optimal origin Y position based on energy level
    # If second bob never goes above origin (low energy), adjust origin upward
    origin_y = layout.origin_y
    if y2_max <= 0:
        # Low energy: all motion is below the fixed origin
        # Move origin to top of screen to maximize visible area
        # Leave small padding at top
        padding_top = 3
        origin_y = padding_top
        print("Low-energy pendulum detected, moving origin to Y=" + str(origin_y))

    # Transform coordinates from physics space to pixel space
    # trajectory contains [x1, y1, x2, y2] arrays
    pixel_frames = []
    for point in trajectory:
        if len(point) >= 4:
            # Map physics coordinates to pixels
            # Physics origin (0,0) maps to (ORIGIN_X, origin_y)
            # Note: Y-axis is inverted (physics +y is up, screen +y is down)
            x1_pixel = layout.origin_x + int(point[0] * layout.scale)
            y1_pixel = origin_y - int(point[1] * layout.scale)
            x2_pixel = layout.origin_x + int(point[2] * layout.scale)
            y2_pixel = origin_y - int(point[3] * layout.scale)

            pixel_frames.append([x1_pixel, y1_pixel, x2_pixel, y2_pixel])

    # Return the transformed data along with origin_y and name
    return {
        "frames": pixel_frames,
        "origin_y": origin_y,
        "name": sim_name,
    }

def main(config):
    width, height = canvas.width(), canvas.height()
    layout = get_layout(width, height)

    # Get animation selection and speed from config
    animation = config.get("animation", "random")
    speed = config.get("speed", "fast")

    # Handle "random from all sources" by randomly picking a source
    if animation == "random_all":
        # Randomly pick between: embedded (0), api random params (1), api random generation (2)
        source = time.now().unix % 3
        if source == 0:
            # Use random embedded simulation (excluding the API sentinel)
            animation = "random"
        elif source == 1:
            # Use API with random params
            animation = "api"
        else:
            # Use random generation from API
            animation = "api_random"

    # Determine which simulation to use
    if animation == "api" or animation == "api_random":
        sim_idx = len(ALL_SIMULATIONS) - 1  # Use last index for API mode
    elif animation == "random" or animation == "":
        sim_idx = time.now().unix % len(ALL_SIMULATIONS)
    else:
        # Parse the number
        sim_num = int(animation)
        if sim_num >= 1 and sim_num <= len(ALL_SIMULATIONS):
            sim_idx = sim_num - 1
        else:
            # Out of range, use random
            sim_idx = time.now().unix % len(ALL_SIMULATIONS)

    # Check if the selected simulation is the API sentinel (last simulation)
    if sim_idx == len(ALL_SIMULATIONS) - 1:
        # Check if we should use a random generation from the collection
        if animation == "api_random":
            # Check if a specific generation ID was provided
            generation_id = config.get("generation_id", "")
            if generation_id and generation_id != "":
                print("Fetching specific generation: " + generation_id)
                sim_data = fetch_simulation(0, layout, generation_id)
            else:
                # Randomly pick a generation from 1 to 1630
                generation_id = str((time.now().unix % 1630) + 1)
                print("Fetching random generation: " + generation_id)
                sim_data = fetch_simulation(0, layout, generation_id)
        else:
            # Fetch from API with random seed (ignore generation_id field)
            seed = time.now().unix  # Changes every second
            print("Fetching simulation from API with seed: " + str(seed))
            sim_data = fetch_simulation(seed, layout)

        # Handle fetch failure
        if sim_data == None:
            print("API request failed, falling back to random embedded simulation")
            sim_idx = time.now().unix % (len(ALL_SIMULATIONS) - 1)
            simulation = ALL_SIMULATIONS[sim_idx]
            api_origin_y = None
            api_name = None
            is_api_mode = False
        else:
            simulation = sim_data.get("frames", [])
            api_origin_y = sim_data.get("origin_y", layout.origin_y)
            api_name = sim_data.get("name", "api")

            # Check if we have valid frames
            if len(simulation) == 0:
                print("API returned empty frames, falling back to random embedded simulation")
                sim_idx = time.now().unix % (len(ALL_SIMULATIONS) - 1)
                simulation = ALL_SIMULATIONS[sim_idx]
                api_origin_y = None
                api_name = None
                is_api_mode = False
            else:
                is_api_mode = True
    else:
        # Use embedded simulation
        print("Picked simulation no." + str(sim_idx + 1) + " (out of " + str(len(ALL_SIMULATIONS)) + ")")
        simulation = ALL_SIMULATIONS[sim_idx]
        api_origin_y = None  # Not used for embedded simulations
        api_name = None  # Not used for embedded simulations
        is_api_mode = False

    # Set delay based on speed (slow = 33ms, fast = 16ms)
    if speed == "fast":
        delay = 16  # Fast: twice as fast (~60fps)
    else:
        delay = 33  # Slow: normal speed (~30fps)

    # Create cached hsv_to_rgb function for performance
    hsv_to_rgb = make_hsv_to_rgb()

    # Render all frames from the selected simulation
    all_frames = []
    for frame_idx in range(len(simulation)):
        if is_api_mode:
            all_frames.append(render_frame_simple(simulation, frame_idx, hsv_to_rgb, api_origin_y, api_name, config, layout))
        else:
            all_frames.append(render_frame(config, sim_idx, frame_idx, hsv_to_rgb, layout))

    return render.Root(
        delay = delay,
        show_full_animation = config.bool("show_full_animation", True),
        child = render.Animation(
            children = all_frames,
        ),
    )

def make_hsv_to_rgb():
    """Returns a memoized hsv_to_rgb function"""

    cache = {}

    # Convert digits to hex chars
    def to_hex(val):
        digits = "0123456789ABCDEF"
        return digits[val // 16] + digits[val % 16]

    def hsv_to_rgb(h, s, v):
        """Convert HSV to RGB color. H in [0,360], S and V in [0,1]"""
        cache_key = (h, s, v)
        if cache_key in cache:
            return cache[cache_key]

        c = v * s
        x = c * (1 - abs((h / 60.0) % 2 - 1))
        m = v - c

        if h < 60:
            r, g, b = c, x, 0
        elif h < 120:
            r, g, b = x, c, 0
        elif h < 180:
            r, g, b = 0, c, x
        elif h < 240:
            r, g, b = 0, x, c
        elif h < 300:
            r, g, b = x, 0, c
        else:
            r, g, b = c, 0, x

        r = int((r + m) * 255)
        g = int((g + m) * 255)
        b = int((b + m) * 255)

        result = "#" + to_hex(r) + to_hex(g) + to_hex(b)
        cache[cache_key] = result
        return result

    return hsv_to_rgb

def draw_line_bresenham(x0, y0, x1, y1, width, height):
    """Draw a line using Bresenham's line algorithm, returns list of (x, y) points."""
    points = []
    dx = abs(x1 - x0)
    dy = abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx - dy

    # Starlark doesn't support while loops, so iterate max(dx, dy) times
    for _ in range(max(dx, dy) + 1):
        if x0 >= 0 and x0 < width and y0 >= 0 and y0 < height:
            points.append((x0, y0))

        if x0 == x1 and y0 == y1:
            break

        e2 = 2 * err
        if e2 > -dy:
            err = err - dy
            x0 = x0 + sx
        if e2 < dx:
            err = err + dx
            y0 = y0 + sy

    return points

def draw_line_widget(x1, y1, x2, y2, color):
    """Draws a line using absolute coordinates by wrapping render.Line in Padding."""

    # Determine bounding box
    min_x = min(x1, x2)
    min_y = min(y1, y2)

    # Normalize coordinates to be relative to the bounding box
    lx1 = x1 - min_x
    ly1 = y1 - min_y
    lx2 = x2 - min_x
    ly2 = y2 - min_y

    return render.Padding(
        pad = (min_x, min_y, 0, 0),
        child = render.Line(
            x1 = lx1,
            y1 = ly1,
            x2 = lx2,
            y2 = ly2,
            width = 1,
            color = color,
        ),
    )

def render_lines(line_style, origin_x, origin_y, x1, y1, x2, y2, color, layout):
    """Render the pendulum arm lines based on the selected style."""
    if line_style == "none":
        # No lines
        return []
    elif line_style == "bresenham":
        # Classic Bresenham algorithm - render as 1x1 boxes
        line1_points = draw_line_bresenham(origin_x, origin_y, x1, y1, layout.width, layout.height)
        line2_points = draw_line_bresenham(x1, y1, x2, y2, layout.width, layout.height)
        return [
            render.Stack(
                children = [
                    render.Padding(
                        pad = (pt[0], pt[1], 0, 0),
                        child = render.Box(width = 1, height = 1, color = color),
                    )
                    for pt in line1_points
                ],
            ),
            render.Stack(
                children = [
                    render.Padding(
                        pad = (pt[0], pt[1], 0, 0),
                        child = render.Box(width = 1, height = 1, color = color),
                    )
                    for pt in line2_points
                ],
            ),
        ]
    else:
        # Default: widget (render.Line)
        return [
            draw_line_widget(origin_x, origin_y, x1, y1, color),
            draw_line_widget(x1, y1, x2, y2, color),
        ]

def to_hex(value):
    """Convert integer to 2-digit lowercase hex string"""
    value = max(0, min(255, int(value)))
    hex_chars = "0123456789abcdef"
    return hex_chars[value // 16] + hex_chars[value % 16]

def fade_color(color, index, total_points, fade_power):
    """Fade a color based on its position in the trail (older = more faded)"""
    opacity = float(index) / float(total_points - 1) if total_points > 1 else 1.0

    # Apply fade_power by multiplying opacity by itself fade_power times
    # Starlark doesn't have pow(), so implement for small integer powers
    result = opacity
    for _ in range(int(fade_power) - 1):
        result = result * opacity
    opacity = result

    if color.startswith("#"):
        color = color[1:]

    r = int(color[0:2], 16)
    g = int(color[2:4], 16)
    b = int(color[4:6], 16)

    # Apply opacity by blending with black
    r = int(r * opacity)
    g = int(g * opacity)
    b = int(b * opacity)

    return "#" + to_hex(r) + to_hex(g) + to_hex(b)

def render_frame_simple(simulation, frame_idx, hsv_to_rgb, origin_y, sim_name, config, layout):
    """Render frame for API-fetched simulation (displays simulation hash name)."""
    frame = simulation[frame_idx]
    x1, y1, x2, y2 = frame[0], frame[1], frame[2], frame[3]

    # Fixed origin (anchor point) - matches the physics origin (0,0)
    # Note: origin_y is passed in and matches what was used during coordinate transformation
    origin_x = layout.origin_x

    # Calculate color based on time progression within THIS simulation
    # Cycle through full rainbow over the course of one simulation
    hue = (frame_idx * 360.0 / len(simulation)) % 360
    bob2_color = hsv_to_rgb(hue, 1.0, 1.0)

    # Build list of plot points for trails (all previous frames in this simulation)
    trail_points = []
    trail_fade_enabled = config.bool("trail_fade", False)
    fade_speed = int(config.get("fade_speed", "2"))

    # Map fade_speed to actual trail length in frames
    # Slower fade = longer window, faster fade = shorter window
    fade_lengths = {1: 300, 2: 200, 3: 100, 4: 50}
    trail_length = fade_lengths.get(fade_speed, 200)

    for i in range(frame_idx):
        f = simulation[i]
        trail_hue = (i * 360.0 / len(simulation)) % 360
        trail_color = hsv_to_rgb(trail_hue, 1.0, 0.5)  # Dimmer for trail

        # Apply fade if enabled
        if trail_fade_enabled:
            # Calculate how far back this point is from current frame
            distance_from_current = frame_idx - i

            # Only fade the last 'trail_length' frames, older points are fully faded
            if distance_from_current <= trail_length:
                # Normalize index to the visible window
                normalized_idx = max(0, i - (frame_idx - trail_length))
                trail_color = fade_color(trail_color, normalized_idx, trail_length, fade_speed)
            else:
                # Too old, make it nearly invisible
                trail_color = "#000000"

        trail_points.append((f[2], f[3], trail_color))  # x2, y2, color

    label = sim_name if config.bool("show_label", False) else ""
    line_style = config.get("line_style", "widget")

    # Build the children list dynamically based on line style
    children = [
        # Black background
        render.Box(
            width = layout.width,
            height = layout.height,
            color = "#000",
        ),

        # Display simulation hash name in top left corner
        render.Padding(
            pad = (1, 1, 0, 0),
            child = render.Text(
                content = label,
                color = "#888",
                font = "tom-thumb",
            ),
        ),

        # Fixed origin point (white dot)
        render.Padding(
            pad = (origin_x - 1, origin_y - 1, 0, 0),
            child = render.Circle(
                color = "#FFFFFF",
                diameter = 2,
            ),
        ),

        # Trail dots for second bob (with color gradient)
        render.Stack(
            children = [
                render.Padding(
                    pad = (pt[0], pt[1], 0, 0),
                    child = render.Box(width = 1, height = 1, color = pt[2]),
                ) if (pt[0] >= 0 and pt[0] < layout.width and pt[1] >= 0 and pt[1] < layout.height) else render.Box(width = 0, height = 0)
                for pt in trail_points
            ],
        ),
    ]

    # Add lines based on selected style
    children.extend(render_lines(line_style, origin_x, origin_y, x1, y1, x2, y2, "#FFFFFF", layout))

    # Add bobs
    children.append(
        # First bob (cyan)
        render.Padding(
            pad = (x1 - 1, y1 - 1, 0, 0),
            child = render.Circle(
                color = "#00FFFF",
                diameter = 2,
            ),
        ) if (x1 >= 0 and x1 < layout.width and y1 >= 0 and y1 < layout.height) else render.Box(width = 0, height = 0),
    )
    children.append(
        # Second bob (color changes over time)
        render.Padding(
            pad = (x2 - 1, y2 - 1, 0, 0),
            child = render.Circle(
                color = bob2_color,
                diameter = 3,
            ),
        ) if (x2 >= 0 and x2 < layout.width and y2 >= 0 and y2 < layout.height) else render.Box(width = 0, height = 0),
    )

    return render.Stack(children = children)

def render_frame(config, sim_idx, frame_idx, hsv_to_rgb, layout):
    """Render frame for embedded simulation (with simulation number displayed)."""
    simulation = ALL_SIMULATIONS[sim_idx]
    frame = simulation[frame_idx]

    # Scale factor for embedded simulations (assuming 64x32 original)
    scale_factor = layout.width / 64.0

    # Scale coordinates
    x1 = int(frame[0] * scale_factor)
    y1 = int(frame[1] * scale_factor)
    x2 = int(frame[2] * scale_factor)
    y2 = int(frame[3] * scale_factor)

    # Fixed origin (anchor point) - matches the physics origin (0,0) of embedded sims
    # Embedded sims were recorded with origin at (32, 13)
    origin_x = int(32 * scale_factor)
    origin_y = int(13 * scale_factor)

    # Calculate color based on time progression within THIS simulation
    # Cycle through full rainbow over the course of one simulation
    hue = (frame_idx * 360.0 / len(simulation)) % 360
    bob2_color = hsv_to_rgb(hue, 1.0, 1.0)

    # Build list of plot points for trails (all previous frames in this simulation)
    trail_points = []
    trail_fade_enabled = config.bool("trail_fade", False)
    fade_speed = int(config.get("fade_speed", "2"))

    # Map fade_speed to actual trail length in frames
    # Slower fade = longer window, faster fade = shorter window
    fade_lengths = {1: 300, 2: 200, 3: 100, 4: 50}
    trail_length = fade_lengths.get(fade_speed, 200)

    for i in range(frame_idx):
        f = simulation[i]
        trail_hue = (i * 360.0 / len(simulation)) % 360
        trail_color = hsv_to_rgb(trail_hue, 1.0, 0.5)  # Dimmer for trail

        # Apply fade if enabled
        if trail_fade_enabled:
            # Calculate how far back this point is from current frame
            distance_from_current = frame_idx - i

            # Only fade the last 'trail_length' frames, older points are fully faded
            if distance_from_current <= trail_length:
                # Normalize index to the visible window
                normalized_idx = max(0, i - (frame_idx - trail_length))
                trail_color = fade_color(trail_color, normalized_idx, trail_length, fade_speed)
            else:
                # Too old, make it nearly invisible
                trail_color = "#000000"

        trail_points.append((int(f[2] * scale_factor), int(f[3] * scale_factor), trail_color))  # x2, y2, color

    label = "no." + str(sim_idx + 1) if config.bool("show_label", False) else ""
    line_style = config.get("line_style", "widget")

    # Build the children list dynamically based on line style
    children = [
        # Black background
        render.Box(
            width = layout.width,
            height = layout.height,
            color = "#000",
        ),

        # Display simulation number in top left corner
        render.Padding(
            pad = (1, 1, 0, 0),
            child = render.Text(
                content = label,
                color = "#888",
                font = "tom-thumb",
            ),
        ),

        # Fixed origin point (white dot)
        render.Padding(
            pad = (origin_x - 1, origin_y - 1, 0, 0),
            child = render.Circle(
                color = "#FFFFFF",
                diameter = 2,
            ),
        ),

        # Trail dots for second bob (with color gradient)
        render.Stack(
            children = [
                render.Padding(
                    pad = (pt[0], pt[1], 0, 0),
                    child = render.Box(width = 1, height = 1, color = pt[2]),
                ) if (pt[0] >= 0 and pt[0] < layout.width and pt[1] >= 0 and pt[1] < layout.height) else render.Box(width = 0, height = 0)
                for pt in trail_points
            ],
        ),
    ]

    # Add lines based on selected style
    children.extend(render_lines(line_style, origin_x, origin_y, x1, y1, x2, y2, "#FFFFFF", layout))

    # Add bobs
    children.append(
        # First bob (cyan)
        render.Padding(
            pad = (x1 - 1, y1 - 1, 0, 0),
            child = render.Circle(
                color = "#00FFFF",
                diameter = 2,
            ),
        ) if (x1 >= 0 and x1 < layout.width and y1 >= 0 and y1 < layout.height) else render.Box(width = 0, height = 0),
    )
    children.append(
        # Second bob (color changes over time)
        render.Padding(
            pad = (x2 - 1, y2 - 1, 0, 0),
            child = render.Circle(
                color = bob2_color,
                diameter = 3,
            ),
        ) if (x2 >= 0 and x2 < layout.width and y2 >= 0 and y2 < layout.height) else render.Box(width = 0, height = 0),
    )

    return render.Stack(children = children)

def get_schema():
    # Build animation options dynamically
    animation_options = [
        schema.Option(display = "Random from all sources", value = "random_all"),
        schema.Option(display = "Random from built in list", value = "random"),
        schema.Option(display = "Random params from API (new generation)", value = "api"),
        schema.Option(display = "Random generation from API (previously generated)", value = "api_random"),
    ]
    for i in range(1, len(ALL_SIMULATIONS) + 1):
        animation_options.append(
            schema.Option(display = "no." + str(i), value = str(i)),
        )

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "speed",
                name = "Speed",
                desc = "Animation playback speed",
                icon = "gauge",
                default = "slow",
                options = [
                    schema.Option(
                        display = "Fast (2x speed)",
                        value = "fast",
                    ),
                    schema.Option(
                        display = "Slow (normal)",
                        value = "slow",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "animation",
                name = "Animation",
                desc = "Select which animation to display",
                icon = "film",
                default = "random_all",
                options = animation_options,
            ),
            schema.Text(
                id = "generation_id",
                name = "Generation ID",
                desc = "Enter a specific generation ID between 1 and 4664 (only used with 'Random generation from API' mode)",
                icon = "hashtag",
                default = "",
            ),
            schema.Toggle(
                id = "show_full_animation",
                name = "Show Full Animation",
                desc = "Renders the full animation before moving to the next app.",
                icon = "hourglass",
                default = True,
            ),
            schema.Toggle(
                id = "show_label",
                name = "Show Label",
                desc = "Displays a label for the current animation.",
                icon = "tag",
                default = False,
            ),
            schema.Toggle(
                id = "trail_fade",
                name = "Trail Fade",
                desc = "Enable fading effect on the trail.",
                icon = "paintbrush",
                default = False,
            ),
            schema.Dropdown(
                id = "fade_speed",
                name = "Fade Speed",
                desc = "How quickly the trail fades (higher = faster fade)",
                icon = "sliders",
                default = "3",
                options = [
                    schema.Option(display = "Very Fast", value = "4"),
                    schema.Option(display = "Fast", value = "3"),
                    schema.Option(display = "Medium", value = "2"),
                    schema.Option(display = "Slow", value = "1"),
                ],
            ),
            schema.Dropdown(
                id = "line_style",
                name = "Line Style",
                desc = "How to draw the pendulum arm lines",
                icon = "penNib",
                default = "widget",
                options = [
                    schema.Option(display = "Pixlet render.Line", value = "widget"),
                    schema.Option(display = "Classic (Bresenham)", value = "bresenham"),
                    schema.Option(display = "No lines", value = "none"),
                ],
            ),
        ],
    )
