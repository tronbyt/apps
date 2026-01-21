"""
Applet: Polygon Bounce
Summary: A colorful bouncing polygon
Description: Nostalgia screensaver of a bouncing polygon with trails.
Author: Brombomb
"""

load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_SIDES = "4"
DEFAULT_COLOR = "#00ff00"
DEFAULT_MODE = "Fixed"
DEFAULT_SPEED = "Medium"
DEFAULT_HISTORY = "4"

SPEEDS = {
    "Slow": 100,
    "Medium": 60,
    "Fast": 40,
    "Ludacris": 20,
    "Plaid": 15,
}

# Helper for hex conversion since %02x is not supported
def to_hex(val):
    val = int(val)

    # Clamp to 0-255
    if val < 0:
        val = 0
    if val > 255:
        val = 255

    hex_chars = "0123456789abcdef"
    return hex_chars[(val >> 4) & 0xF] + hex_chars[val & 0xF]

def get_hsv_color(h, s, v):
    """
    Convert HSV to RGB hex string.
    h: 0-1, s: 0-1, v: 0-1
    """
    i = int(h * 6)
    f = h * 6 - i
    p = v * (1 - s)
    q = v * (1 - f * s)
    t = v * (1 - (1 - f) * s)

    r, g, b = 0, 0, 0
    if i % 6 == 0:
        r, g, b = v, t, p
    elif i % 6 == 1:
        r, g, b = q, v, p
    elif i % 6 == 2:
        r, g, b = p, v, t
    elif i % 6 == 3:
        r, g, b = p, q, v
    elif i % 6 == 4:
        r, g, b = t, p, v
    elif i % 6 == 5:
        r, g, b = v, p, q

    return "#" + to_hex(r * 255) + to_hex(g * 255) + to_hex(b * 255)

def main(config):
    # Use unix seconds to be safe
    random.seed(int(time.now().unix))

    scale = 2 if canvas.is2x() else 1
    width = 64 * scale
    height = 32 * scale

    num_sides = int(config.get("side_count", DEFAULT_SIDES))
    color_mode = config.get("color_mode", DEFAULT_MODE)
    fixed_color = config.get("color", DEFAULT_COLOR)
    history_length = min(int(config.get("history_length", DEFAULT_HISTORY)), 10)
    speed = config.get("speed", DEFAULT_SPEED)
    frame_delay = SPEEDS.get(speed, 60)

    # Initialize vertices
    vertices = []
    for _ in range(num_sides):
        # Scale velocity slightly with resolution so it doesn't look too slow on 2x
        vel_scale = scale

        # Ensure we don't start exactly at 0 to avoid clamping issues immediately
        vx = float(random.number(0, 200) - 100) / 50.0 + 0.5
        vy = float(random.number(0, 200) - 100) / 50.0 + 0.5

        # Avoid zero velocity
        if abs(vx) < 0.1:
            vx = 1.0
        if abs(vy) < 0.1:
            vy = 1.0

        vertices.append({
            "x": float(random.number(5 * scale, width - 5 * scale)),
            "y": float(random.number(5 * scale, height - 5 * scale)),
            "vx": vx * vel_scale,
            "vy": vy * vel_scale,
        })

    history = []
    frames = []

    # Simulation loop for 300 frames (approx 15 seconds)
    for frame_idx in range(300):
        # Update positions
        current_poly = []
        for v in vertices:
            v["x"] += v["vx"]
            v["y"] += v["vy"]

            # Bounce logic
            if v["x"] <= 0:
                v["x"] = 0.0
                v["vx"] = -v["vx"]
            elif v["x"] >= width:
                v["x"] = float(width)
                v["vx"] = -v["vx"]

            if v["y"] <= 0:
                v["y"] = 0.0
                v["vy"] = -v["vy"]
            elif v["y"] >= height:
                v["y"] = float(height)
                v["vy"] = -v["vy"]

            current_poly.append((v["x"], v["y"]))

        history.append(current_poly)
        if len(history) > history_length:
            history.pop(0)

        # Select color
        if color_mode == "Rainbow":
            # Cycle hue based on frame index
            draw_color = get_hsv_color((frame_idx % 100) / 100.0, 1.0, 1.0)
        else:
            draw_color = fixed_color

        # Draw frame
        children = []

        # Draw trails and current frame
        for poly_points in history:
            # Draw lines connecting vertices
            for i in range(len(poly_points)):
                p1 = poly_points[i]
                p2 = poly_points[(i + 1) % len(poly_points)]

                # Normalize coordinates to handle widget shrink-wrapping
                x1, y1 = int(p1[0]), int(p1[1])
                x2, y2 = int(p2[0]), int(p2[1])

                left = min(x1, x2)
                top = min(y1, y2)

                # Check bounds to avoid negative padding or off-screen drawing issues
                if left < 0:
                    left = 0
                if top < 0:
                    top = 0

                local_x1 = x1 - left
                local_y1 = y1 - top
                local_x2 = x2 - left
                local_y2 = y2 - top

                line = render.Line(
                    x1 = local_x1,
                    y1 = local_y1,
                    x2 = local_x2,
                    y2 = local_y2,
                    color = draw_color,
                    width = 1 * scale,
                )

                children.append(render.Padding(
                    pad = (left, top, 0, 0),
                    child = line,
                ))

        frames.append(render.Stack(children = children))

    return render.Root(
        delay = frame_delay,
        child = render.Animation(children = frames),
    )

def get_schema():
    side_options = [
        schema.Option(display = str(i), value = str(i))
        for i in range(3, 9)
    ]

    speed_options = [
        schema.Option(display = "Slow", value = "Slow"),
        schema.Option(display = "Medium", value = "Medium"),
        schema.Option(display = "Fast", value = "Fast"),
        schema.Option(display = "Ludacris", value = "Ludacris"),
        schema.Option(display = "Plaid", value = "Plaid"),
    ]

    history_options = [
        schema.Option(display = str(i), value = str(i))
        for i in range(1, 11)
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "side_count",
                name = "Number of Sides",
                desc = "How many edges the polygon has.",
                icon = "shapes",
                default = DEFAULT_SIDES,
                options = side_options,
            ),
            schema.Dropdown(
                id = "color_mode",
                name = "Color Mode",
                desc = "Choose fixed color or rainbow cycling.",
                icon = "palette",
                default = DEFAULT_MODE,
                options = [
                    schema.Option(display = "Fixed Color", value = "Fixed"),
                    schema.Option(display = "Rainbow", value = "Rainbow"),
                ],
            ),
            schema.Color(
                id = "color",
                name = "Color",
                desc = "Color of the polygon (if Fixed mode).",
                icon = "brush",
                default = DEFAULT_COLOR,
            ),
            schema.Dropdown(
                id = "history_length",
                name = "History Length",
                desc = "Length of the trail (1-10)",
                icon = "clock",
                default = DEFAULT_HISTORY,
                options = history_options,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Speed",
                desc = "Animation speed.",
                icon = "gear",
                default = DEFAULT_SPEED,
                options = speed_options,
            ),
        ],
    )
