load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
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

# Screen positioning
ORIGIN_X = 32  # Horizontally centered
ORIGIN_Y = 11  # 35% down from top (32 * 0.35 ≈ 11)

# Calculate scale to fit pendulum on screen
# Available space: left=32px, right=32px, up=11px, down=21px
PADDING = 0
SCALE_X = (32.0 - PADDING) / MAX_EXTENT  # Horizontal scale ≈ 2.9
SCALE_Y = (21.0 - PADDING) / MAX_EXTENT  # Vertical scale ≈ 1.9
SCALE = int(SCALE_Y * 10) / 10.0  # Use smaller scale, round to 1 decimal ≈ 1.9

def fetch_simulation(seed, generation_id = None):
    """Fetch a simulation from the API and transform coordinates to pixel space."""
    cache_key = "gen_" + str(generation_id) if generation_id else "sim_" + str(seed)

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
    origin_y = ORIGIN_Y
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
            x1_pixel = ORIGIN_X + int(point[0] * SCALE)
            y1_pixel = origin_y - int(point[1] * SCALE)
            x2_pixel = ORIGIN_X + int(point[2] * SCALE)
            y2_pixel = origin_y - int(point[3] * SCALE)

            pixel_frames.append([x1_pixel, y1_pixel, x2_pixel, y2_pixel])

    # Return the transformed data along with origin_y and name
    return {
        "frames": pixel_frames,
        "origin_y": origin_y,
        "name": sim_name,
    }

def main(config):
    # Get animation selection and speed from config
    animation = config.get("animation", "random")
    speed = config.get("speed", "fast")

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
            # Randomly pick a generation from 1 to 1630
            generation_id = str((time.now().unix % 1630) + 1)
            print("Fetching random generation: " + generation_id)
            sim_data = fetch_simulation(0, generation_id)
        else:
            # Check if a specific generation ID was provided
            generation_id = config.get("generation_id", "")
            if generation_id and generation_id != "":
                print("Fetching specific generation: " + generation_id)
                sim_data = fetch_simulation(0, generation_id)
            else:
                # Fetch from API with random seed
                seed = time.now().unix  # Changes every second
                print("Fetching simulation from API with seed: " + str(seed))
                sim_data = fetch_simulation(seed)

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
            api_origin_y = sim_data.get("origin_y", ORIGIN_Y)
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
            all_frames.append(render_frame_simple(simulation, frame_idx, hsv_to_rgb, api_origin_y, api_name, config))
        else:
            all_frames.append(render_frame(config, sim_idx, frame_idx, hsv_to_rgb))

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

def draw_line(x0, y0, x1, y1):
    """Draw a line using simple linear interpolation"""
    points = []
    dx = abs(x1 - x0)
    dy = abs(y1 - y0)

    # If the line is just a point, return it
    if dx == 0 and dy == 0:
        if (x0 >= 0 and x0 < 64 and y0 >= 0 and y0 < 32):
            points.append((x0, y0))
        return points

    # Use simple linear interpolation for simplicity
    steps = max(dx, dy)
    for i in range(steps + 1):
        t = i / float(steps)
        x = int(x0 + t * (x1 - x0))
        y = int(y0 + t * (y1 - y0))
        if (x >= 0 and x < 64 and y >= 0 and y < 32):
            points.append((x, y))

    return points

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

def render_frame_simple(simulation, frame_idx, hsv_to_rgb, origin_y, sim_name, config):
    """Render frame for API-fetched simulation (displays simulation hash name)."""
    frame = simulation[frame_idx]
    x1, y1, x2, y2 = frame[0], frame[1], frame[2], frame[3]

    # Fixed origin (anchor point) - matches the physics origin (0,0)
    # Note: origin_y is passed in and matches what was used during coordinate transformation
    origin_x = ORIGIN_X

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

    return render.Stack(
        children = [
            # Black background
            render.Box(
                width = 64,
                height = 32,
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
                    ) if (pt[0] >= 0 and pt[0] < 64 and pt[1] >= 0 and pt[1] < 32) else render.Box(width = 0, height = 0)
                    for pt in trail_points
                ],
            ),

            # Lines connecting origin -> bob1 -> bob2
            # Line from origin to first bob
            render.Stack(
                children = [
                    render.Padding(
                        pad = (pt[0], pt[1], 0, 0),
                        child = render.Box(width = 1, height = 1, color = "#FFFFFF"),
                    )
                    for pt in draw_line(origin_x, origin_y, x1, y1)
                ],
            ),
            # Line from first bob to second bob
            render.Stack(
                children = [
                    render.Padding(
                        pad = (pt[0], pt[1], 0, 0),
                        child = render.Box(width = 1, height = 1, color = "#FFFFFF"),
                    )
                    for pt in draw_line(x1, y1, x2, y2)
                ],
            ),

            # First bob (cyan)
            render.Padding(
                pad = (x1 - 1, y1 - 1, 0, 0),
                child = render.Circle(
                    color = "#00FFFF",
                    diameter = 2,
                ),
            ) if (x1 >= 0 and x1 < 64 and y1 >= 0 and y1 < 32) else render.Box(width = 0, height = 0),

            # Second bob (color changes over time)
            render.Padding(
                pad = (x2 - 1, y2 - 1, 0, 0),
                child = render.Circle(
                    color = bob2_color,
                    diameter = 3,
                ),
            ) if (x2 >= 0 and x2 < 64 and y2 >= 0 and y2 < 32) else render.Box(width = 0, height = 0),
        ],
    )

def render_frame(config, sim_idx, frame_idx, hsv_to_rgb):
    """Render frame for embedded simulation (with simulation number displayed)."""
    simulation = ALL_SIMULATIONS[sim_idx]
    frame = simulation[frame_idx]
    x1, y1, x2, y2 = frame[0], frame[1], frame[2], frame[3]

    # Fixed origin (anchor point) - matches the physics origin (0,0)
    origin_x = 32
    origin_y = 13

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

    label = "no." + str(sim_idx + 1) if config.bool("show_label", False) else ""

    return render.Stack(
        children = [
            # Black background
            render.Box(
                width = 64,
                height = 32,
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
                    ) if (pt[0] >= 0 and pt[0] < 64 and pt[1] >= 0 and pt[1] < 32) else render.Box(width = 0, height = 0)
                    for pt in trail_points
                ],
            ),

            # Lines connecting origin -> bob1 -> bob2
            # Line from origin to first bob
            render.Stack(
                children = [
                    render.Padding(
                        pad = (pt[0], pt[1], 0, 0),
                        child = render.Box(width = 1, height = 1, color = "#FFFFFF"),
                    )
                    for pt in draw_line(origin_x, origin_y, x1, y1)
                ],
            ),
            # Line from first bob to second bob
            render.Stack(
                children = [
                    render.Padding(
                        pad = (pt[0], pt[1], 0, 0),
                        child = render.Box(width = 1, height = 1, color = "#FFFFFF"),
                    )
                    for pt in draw_line(x1, y1, x2, y2)
                ],
            ),

            # First bob (cyan)
            render.Padding(
                pad = (x1 - 1, y1 - 1, 0, 0),
                child = render.Circle(
                    color = "#00FFFF",
                    diameter = 2,
                ),
            ) if (x1 >= 0 and x1 < 64 and y1 >= 0 and y1 < 32) else render.Box(width = 0, height = 0),

            # Second bob (color changes over time)
            render.Padding(
                pad = (x2 - 1, y2 - 1, 0, 0),
                child = render.Circle(
                    color = bob2_color,
                    diameter = 3,
                ),
            ) if (x2 >= 0 and x2 < 64 and y2 >= 0 and y2 < 32) else render.Box(width = 0, height = 0),
        ],
    )

def get_schema():
    # Build animation options dynamically
    animation_options = [
        schema.Option(display = "Random", value = "random"),
        schema.Option(display = "Random params from API", value = "api"),
        schema.Option(display = "Random generation from API", value = "api_random"),
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
                default = "random",
                options = animation_options,
            ),
            schema.Text(
                id = "generation_id",
                name = "Generation ID",
                desc = "Enter a specific generation ID like 1588 (only used with 'Random params from API' mode, ignored by 'Random generation from API')",
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
        ],
    )
