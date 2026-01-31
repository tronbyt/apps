"""
Applet: Planet Views
Summary: Planets in their Orbits
Description: Show where the planets are in their orbits.
Author: Brombomb
"""

load("math.star", "math")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

COLORS = {
    "Sun": "#FFFF00",
    "Mercury": "#AAAAAA",  # Gray
    "Venus": "#F4A460",  # SandyBrown
    "Earth": "#2f6a69",  # Blue
    "Mars": "#993d00",  # Red
    "Jupiter": "#b07f35",  # SaddleBrown
    "Saturn": "#F0E68C",  # Khaki
    "Uranus": "#5580aa",  # LightSkyBlue
    "Neptune": "#366896",  # DeepSkyBlue (Sea blue-ish)
    "Pluto": "#556B2F",  # DarkOliveGreen (Moss green-ish)
}

EMOJIS = ["🚀", "👾", "🛸", "🌠"]

# Orbital Elements (Approximate J2000)
# Period in days, L0 (Mean Longitude at J2000) in degrees, a (Semi-major axis) in AU
PLANETS = [
    {"name": "Mercury", "P": 87.969, "L0": 252.25, "a": 0.387, "color": COLORS["Mercury"]},
    {"name": "Venus", "P": 224.701, "L0": 181.98, "a": 0.723, "color": COLORS["Venus"]},
    {"name": "Earth", "P": 365.256, "L0": 100.46, "a": 1.000, "color": COLORS["Earth"]},
    {"name": "Mars", "P": 686.980, "L0": 355.45, "a": 1.524, "color": COLORS["Mars"]},
    {"name": "Jupiter", "P": 4332.59, "L0": 34.40, "a": 5.203, "color": COLORS["Jupiter"]},
    {"name": "Saturn", "P": 10759.22, "L0": 49.94, "a": 9.537, "color": COLORS["Saturn"]},
    {"name": "Uranus", "P": 30685.4, "L0": 313.23, "a": 19.191, "color": COLORS["Uranus"]},
    {"name": "Neptune", "P": 60189.0, "L0": 304.88, "a": 30.069, "color": COLORS["Neptune"]},
    {"name": "Pluto", "P": 90560.0, "L0": 238.93, "a": 39.482, "color": COLORS["Pluto"]},
]

J2000_EPOCH = time.time(year = 2000, month = 1, day = 1, hour = 12)

# --- Math Helpers ---

def get_days_since_j2000(now):
    # time subtraction returns a duration
    diff = now - J2000_EPOCH

    # duration.hours / 24 = days
    return diff.hours / 24.0

def deg_to_rad(deg):
    return deg * math.pi / 180.0

def fast_mod(a, b):
    return a - (math.floor(a / b) * b)

def get_planet_pos_helio(planet, days):
    # Mean anomaly / Mean longitude approximation
    # n = 360 / Period
    n = 360.0 / planet["P"]
    L = planet["L0"] + n * days
    L_norm = fast_mod(L, 360.0)
    rad = deg_to_rad(L_norm)

    # Calculate x, y in AU
    x = planet["a"] * math.cos(rad)
    y = planet["a"] * math.sin(rad)

    return {"x": x, "y": y, "angle": L_norm, "color": planet["color"], "name": planet["name"]}

# --- Rendering ---

def render_stars(width, height):
    # Random starfield
    random.seed(int(time.now().unix))

    stars = []

    # Density: ~10 stars for 64x32. Scale roughly with area?
    # Area ratio = (w*h) / (64*32).
    # num_stars = 10 * area_ratio ?
    # Let's keep it simple: 10 stars is sparse.
    # Maybe 10 is enough? Let's bump it slightly for larger screens.
    area = width * height
    count = int(10 * (area / 2048.0))  # 2048 = 64*32
    if count < 10:
        count = 10

    for _ in range(count):
        x = random.number(0, width - 1)
        y = random.number(0, height - 1)
        stars.append(render.Padding(
            pad = (int(x), int(y), 0, 0),
            child = render.Box(width = 1, height = 1, color = "#555"),  # Dim white/gray
        ))
    return render.Stack(children = stars)

def render_clock(now, is_24h, flash_colon):
    # Format
    format_str = "15:04" if is_24h else "3:04"
    time_str = now.format(format_str)

    parts = time_str.split(":")
    hours = parts[0]
    minutes = parts[1]

    colon_color = "#fff"
    if flash_colon and now.second % 2 == 0:
        colon_color = "#0000"  # Transparent to maintain width

    return render.Column(
        expanded = True,
        main_align = "end",  # Bottom
        cross_align = "start",  # Left
        children = [
            render.Row(
                main_align = "start",
                cross_align = "baseline",
                children = [
                    render.Text(content = hours, font = "tb-8", color = "#fff"),
                    render.Text(content = ":", font = "tb-8", color = colon_color),
                    render.Text(content = minutes, font = "tb-8", color = "#fff"),
                ],
            ),
        ],
    )

def render_helio(planets, show_pluto, width, height, scale, rotation_offset = 0):
    children = []

    # Sun in center
    sun_diam = 6 * scale
    children.append(render.Padding(
        pad = (int(width / 2 - sun_diam / 2), int(height / 2 - sun_diam / 2), 0, 0),
        child = render.Circle(
            color = COLORS["Sun"],
            diameter = sun_diam,
        ),
    ))

    # Concentric rings
    # We have up to 9 planets.
    # Radius step: 16 pixels height.
    # If we want to fit all, step might be very small.
    # Let's say max radius is ~15.
    # 9 planets: step = 1.5? That's tight.
    # Maybe we don't draw rings for all, or we space them diagrammatically.
    # "diagrammatical view (i.e. all the planets in nice neat, equally separated, circular orbits)"

    num_planets = len(planets)
    if not show_pluto:
        num_planets -= 1

    start_r = 4 * scale

    # Scale max_r based on available space
    # min(height/2, width/4) ensures it fits both vertically and horizontally (since x is scaled by 2)
    max_val = height / 2
    if (width / 4) < max_val:
        max_val = width / 4
    max_r = int(max_val - 1)

    step = (max_r - start_r) / max(num_planets - 1, 1) if num_planets > 0 else 1

    center_x = width / 2
    center_y = height / 2

    for i, p in enumerate(planets):
        if p["name"] == "Pluto" and not show_pluto:
            continue

        ry = start_r + i * step
        rx = ry * 2.0  # Elliptical scaling for 64x32 screen

        # Determine planetary angle with animation offset
        angle_deg = p["angle"] + rotation_offset
        angle_rad = deg_to_rad(angle_deg)

        # Position (y is flipped in screen coords compared to standard math usually?
        # Actually standard math: +y up. Screen: +y down.
        # But for orbit visualization, rotation direction is usually CCW from "Right".
        # If we just map cos/sin to x/y, it's fine, just coordinate system choice.)
        px = center_x + rx * math.cos(angle_rad)
        py = center_y - ry * math.sin(angle_rad)

        # Draw Planet
        size = 2 * scale
        if p["name"] == "Jupiter" or p["name"] == "Saturn":
            size = 4 * scale

        children.append(render.Padding(
            pad = (int(px - size / 2), int(py - size / 2), 0, 0),
            child = render.Circle(diameter = size, color = p["color"]),
        ))

    # Place Sun at exact center again on top if needed, but earlier is fine.
    # Actually, let's use a Stack.

    return render.Stack(children = children)

def render_geo(planets, show_pluto, width, height, scale, rotation_offset = 0):
    # Geocentric: Earth is center.
    # We need relative positions.
    # Earth pos:
    earth = None
    for p in planets:
        if p["name"] == "Earth":
            earth = p
            break

    if not earth:
        return render.Text("Error")

    children = []

    center_x = width / 2
    center_y = height / 2

    # Earth in Center
    earth_diam = 4 * scale
    children.append(render.Padding(
        pad = (int(width / 2 - earth_diam / 2), int(height / 2 - earth_diam / 2), 0, 0),
        child = render.Circle(diameter = earth_diam, color = COLORS["Earth"]),
    ))

    # Project others
    # We want direction.
    # Vector Earth -> Planet = (Px - Ex, Py - Ey)
    # We only care about Angle of this vector.
    # Then we place them at fixed radius R_draw.

    # Scale r_draw
    min_dim = width if width < height else height
    r_draw = int((min_dim / 2) * 0.9)

    for p in planets:
        if p["name"] == "Earth":
            continue
        if p["name"] == "Pluto" and not show_pluto:
            continue

        # Calculate vector
        dx = p["x"] - earth["x"]
        dy = p["y"] - earth["y"]

        # Angle with animation offset
        # For Geocentric, does the rotation affect the projection?
        # "They should stay on their orbits" -> Implying visual rotation of the system.
        # But Geocentric is relative to Earth. If everything rotates, Earth rotates too?
        # Or do only planets move?
        # "Animate the planets one rotation... they should stay on their orbits".
        # In Helio, simple rotation of all planets by offset is visual rotation of the system (or planets moving along orbit).
        # In Geo, planets move along their projected path?
        # If we just add offset to the 'angle' derived from atan2(dy, dx), that rotates the visual representation around Earth at center.
        # This seems consistent with "visual rotation".

        angle = math.atan2(dy, dx) + deg_to_rad(rotation_offset)

        # Position on screen
        px = center_x + r_draw * math.cos(angle)
        py = center_y - r_draw * math.sin(angle)

        # SPECIAL CASE: The Sun
        # We calculate Sun position for Geocentric too.
        # Sun is at (0,0) in Helio.
        # Vector Earth -> Sun = (0 - Ex, 0 - Ey) = (-Ex, -Ey).
        # We need to add Sun to list of things to draw.

        size = 2 * scale
        if p["name"] == "Jupiter" or p["name"] == "Saturn":
            size = 4 * scale

        children.append(render.Padding(
            pad = (int(px - size / 2), int(py - size / 2), 0, 0),
            child = render.Circle(diameter = size, color = p["color"]),
        ))

    # Add Sun explicitly
    dx_sun = 0.0 - earth["x"]
    dy_sun = 0.0 - earth["y"]
    angle_sun = math.atan2(dy_sun, dx_sun)
    sx = center_x + r_draw * math.cos(angle_sun)
    sy = center_y - r_draw * math.sin(angle_sun)

    sun_diam = 6 * scale
    children.append(render.Padding(
        pad = (int(sx - sun_diam / 2), int(sy - sun_diam / 2), 0, 0),
        child = render.Circle(diameter = sun_diam, color = COLORS["Sun"]),
    ))

    return render.Stack(children = children)

def main(config):
    show_pluto = config.bool("show_pluto", False)
    view_mode = config.str("view_mode", "Heliocentric")
    show_stars = config.bool("show_stars", True)
    show_clock = config.bool("show_clock", True)
    show_clock_24h = config.bool("clock_24h", True)
    show_clock_flash = config.bool("clock_flash", False)

    now = time.now()

    width = canvas.width()
    height = canvas.height()

    scale = int(width / 64)
    if scale < 1:
        scale = 1

    days = get_days_since_j2000(now)

    # Calculate all positions with configurable colors
    calculated_planets = []
    for p in PLANETS:
        # Override color if configured
        # config ID format: "color_<lowercase_name>"
        color_id = "color_" + p["name"].lower()
        new_color = config.get(color_id, p["color"])

        # Create a copy with new color (shallow copy of dict is fine)
        p_mod = dict(p)
        p_mod["color"] = new_color

        calculated_planets.append(get_planet_pos_helio(p_mod, days))

    animation_speed = config.str("animation_speed", "Medium")

    # Determine frame count and delay
    # We want 1 full rotation (360 degrees).
    # Then 5s pause.
    # Pixlet animation frames have delay.
    # Let's say 50ms per frame for smooth animation? Or 100ms.
    # 100ms = 10fps.
    frame_delay = 100  # ms

    rotation_duration = 10000  # Default Medium 10s
    if animation_speed == "Slow":
        rotation_duration = 15000
    elif animation_speed == "Fast":
        rotation_duration = 5000

    enable_pause = config.bool("enable_pause", True)

    rotation_frames = int(rotation_duration / frame_delay)
    pause_frames = int(5000 / frame_delay) if enable_pause else 0

    total_frames = rotation_frames + pause_frames

    frames = []

    # Pre-calculate starfield once (static background)
    starfield = render_stars(width, height) if show_stars else None

    # Easter Egg Calculation

    egg_chance_str = config.str("egg_chance", "0%")
    egg_chance = int(egg_chance_str.replace("%", ""))

    show_egg = False
    if egg_chance > 0:
        # Seed logic is already time based
        if random.number(0, 100) < egg_chance:
            show_egg = True

    egg_emoji = ""
    egg_start_x = 0
    egg_start_y = 0
    egg_end_x = 0
    egg_end_y = 0

    if show_egg:
        egg_emoji = EMOJIS[random.number(0, len(EMOJIS) - 1)]

        # Randomize Direction: 0=L->R, 1=R->L, 2=T->B, 3=B->T
        direction = random.number(0, 3)

        # Helper margins
        off_x = 12  # Width of emoji roughly
        off_y = 12

        if direction == 0:  # Left -> Right
            egg_start_x = -off_x
            egg_end_x = width + off_x
            egg_start_y = random.number(0, height + off_y) - off_y
            egg_end_y = random.number(0, height + off_y) - off_y
        elif direction == 1:  # Right -> Left
            egg_start_x = width + off_x
            egg_end_x = -off_x
            egg_start_y = random.number(0, height + off_y) - off_y
            egg_end_y = random.number(0, height + off_y) - off_y
        elif direction == 2:  # Top -> Bottom
            egg_start_x = random.number(0, width + off_x) - off_x
            egg_end_x = random.number(0, width + off_x) - off_x
            egg_start_y = -off_y
            egg_end_y = height + off_y
        else:  # Bottom -> Top
            egg_start_x = random.number(0, width + off_x) - off_x
            egg_end_x = random.number(0, width + off_x) - off_x
            egg_start_y = height + off_y
            egg_end_y = -off_y

    for i in range(total_frames):
        # Calculate rotation progress
        progress = 0.0
        if i < rotation_frames:
            progress = i / float(rotation_frames)
            rotation_offset = progress * 360.0  # Degrees
        else:
            rotation_offset = 0.0  # Reset to 0 during pause? Or stay at 360 (which is 0)?

            # "After completing an orbit it should pause" -> usually implies pausing at the end state (360/0)
            rotation_offset = 0.0

        # Time for clock (advance by frame_delay?)
        # Or just use current time?
        # If we want the clock to blink realistically, we should add (i * frame_delay) to 'now'.
        frame_time = now + time.parse_duration("{}ms".format(i * frame_delay))

        frame_children = []

        # 1. Stars
        if starfield:
            frame_children.append(starfield)

        # 2. Clock
        if show_clock:
            frame_children.append(render_clock(frame_time, show_clock_24h, show_clock_flash))

        # 3. Planets
        if view_mode == "Heliocentric":
            frame_children.append(render_helio(calculated_planets, show_pluto, width, height, scale, rotation_offset))
        else:
            frame_children.append(render_geo(calculated_planets, show_pluto, width, height, scale, rotation_offset))

        # 4. Easter Egg
        if show_egg and i < rotation_frames:
            # Linear interpolation of position
            # We already calculated start/end x/y in main logic block
            curr_x = int(egg_start_x + (egg_end_x - egg_start_x) * progress)
            curr_y = int(egg_start_y + (egg_end_y - egg_start_y) * progress)

            frame_children.append(render.Padding(
                pad = (curr_x, curr_y, 0, 0),
                child = render.Text(content = egg_emoji),
            ))

        frames.append(render.Stack(children = frame_children))

    return render.Root(
        delay = frame_delay,
        child = render.Animation(children = frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "view_mode",
                name = "View Mode",
                desc = "Choose the perspective",
                icon = "eye",
                default = "Heliocentric",
                options = [
                    schema.Option(display = "Heliocentric", value = "Heliocentric"),
                    schema.Option(display = "Geocentric", value = "Geocentric"),
                ],
            ),
            schema.Toggle(
                id = "show_stars",
                name = "Show Stars",
                desc = "Show Starfield Background",
                icon = "star",
                default = True,
            ),
            schema.Toggle(
                id = "show_clock",
                name = "Show Clock",
                desc = "Show Digital Clock Overlay",
                icon = "clock",
                default = True,
            ),
            schema.Toggle(
                id = "clock_24h",
                name = "24 Hour Clock",
                desc = "Use 24 hour format",
                icon = "clock",
                default = True,
            ),
            schema.Toggle(
                id = "clock_flash",
                name = "Blinking Colon",
                desc = "Flash the colon separator",
                icon = "clock",
                default = False,
            ),
            schema.Dropdown(
                id = "animation_speed",
                name = "Animation Speed",
                desc = "Speed of rotation",
                icon = "stopwatch",
                default = "Medium",
                options = [
                    schema.Option(display = "Slow (15s)", value = "Slow"),
                    schema.Option(display = "Medium (10s)", value = "Medium"),
                    schema.Option(display = "Fast (5s)", value = "Fast"),
                ],
            ),
            schema.Toggle(
                id = "enable_pause",
                name = "Pause Animation",
                desc = "Pause after each rotation",
                icon = "pause",
                default = True,
            ),
            schema.Color(
                id = "color_mercury",
                name = "Mercury Color",
                desc = "Color for Mercury",
                icon = "brush",
                default = COLORS["Mercury"],
            ),
            schema.Color(
                id = "color_venus",
                name = "Venus Color",
                desc = "Color for Venus",
                icon = "brush",
                default = COLORS["Venus"],
            ),
            schema.Color(
                id = "color_earth",
                name = "Earth Color",
                desc = "Color for Earth",
                icon = "brush",
                default = COLORS["Earth"],
            ),
            schema.Color(
                id = "color_mars",
                name = "Mars Color",
                desc = "Color for Mars",
                icon = "brush",
                default = COLORS["Mars"],
            ),
            schema.Color(
                id = "color_jupiter",
                name = "Jupiter Color",
                desc = "Color for Jupiter",
                icon = "brush",
                default = COLORS["Jupiter"],
            ),
            schema.Color(
                id = "color_saturn",
                name = "Saturn Color",
                desc = "Color for Saturn",
                icon = "brush",
                default = COLORS["Saturn"],
            ),
            schema.Color(
                id = "color_uranus",
                name = "Uranus Color",
                desc = "Color for Uranus",
                icon = "brush",
                default = COLORS["Uranus"],
            ),
            schema.Color(
                id = "color_neptune",
                name = "Neptune Color",
                desc = "Color for Neptune",
                icon = "brush",
                default = COLORS["Neptune"],
            ),
            schema.Color(
                id = "color_pluto",
                name = "Pluto Color",
                desc = "Color for Pluto",
                icon = "brush",
                default = COLORS["Pluto"],
            ),
            schema.Toggle(
                id = "show_pluto",
                name = "Show Pluto",
                desc = "Include Pluto",
                icon = "globe",
                default = False,
            ),
            schema.Dropdown(
                id = "egg_chance",
                name = "Easter Egg Chance",
                desc = "Chance for space emojis",
                icon = "rocket",
                default = "0%",
                options = [
                    schema.Option(display = "0%", value = "0%"),
                    schema.Option(display = "10%", value = "10%"),
                    schema.Option(display = "25%", value = "25%"),
                    schema.Option(display = "50%", value = "50%"),
                    schema.Option(display = "100%", value = "100%"),
                ],
            ),
        ],
    )
