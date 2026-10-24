"""
Applet: River Oxygen Series
Summary: Kinetic river vitality art
Description: A kinetic fluid data matrix visualizing river health, dissolved oxygen levels, and water currents in real time across blue-green river basins. Inspired by BREAKFAST's ecological artwork series.
Author: brombomb
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")

DEFAULT_LOCATION = {
    "lat": 44.5000,
    "lng": -73.2121,
    "locality": "Winooski River, VT",
    "timezone": "America/New_York",
}

FAMOUS_RIVERS = {
    "amazon": {"lat": -3.4653, "lng": -62.2159, "locality": "Amazon River"},
    "mississippi": {"lat": 29.9511, "lng": -90.0715, "locality": "Mississippi River"},
    "danube": {"lat": 48.2082, "lng": 16.3738, "locality": "Danube River"},
    "rhine": {"lat": 50.9375, "lng": 6.9603, "locality": "Rhine River"},
    "hudson": {"lat": 40.7128, "lng": -74.0060, "locality": "Hudson River"},
    "thames": {"lat": 51.5074, "lng": -0.1278, "locality": "Thames River"},
    "colorado": {"lat": 36.1069, "lng": -112.1129, "locality": "Colorado River"},
    "winooski": {"lat": 44.5000, "lng": -73.2121, "locality": "Winooski River"},
}

HEX_CHARS = "0123456789abcdef"
N_FRAMES = 80

PALETTE_PRISTINE = [
    (0.00, (3, 23, 22)),
    (0.30, (10, 58, 64)),
    (0.60, (0, 180, 216)),
    (0.85, (144, 224, 239)),
    (1.00, (202, 240, 248)),
]

PALETTE_EMERALD_BASIN = [
    (0.00, (2, 28, 30)),
    (0.35, (0, 75, 73)),
    (0.70, (46, 196, 182)),
    (1.00, (203, 243, 240)),
]

PALETTE_TEAL_CURRENT = [
    (0.00, (2, 22, 37)),
    (0.35, (10, 56, 84)),
    (0.70, (29, 154, 156)),
    (1.00, (118, 234, 215)),
]

PALETTE_CYAN_FLOW = [
    (0.00, (3, 18, 33)),
    (0.35, (0, 95, 115)),
    (0.70, (10, 147, 150)),
    (1.00, (148, 210, 189)),
]

PALETTE_HYPOXIC = [
    (0.00, (25, 2, 4)),
    (0.35, (74, 4, 4)),
    (0.70, (128, 15, 47)),
    (1.00, (255, 77, 109)),
]

WHITE_RGB = (255, 255, 255)

METABALL_SEEDS = [
    (3.2, 0.40, 0.25, 0.0, 1.2),
    (2.6, 0.25, 0.50, 2.1, 0.4),
    (3.5, 0.15, 0.30, 4.2, 2.5),
    (2.2, 0.50, 0.20, 1.5, 3.8),
    (2.8, 0.35, 0.40, 3.1, 1.7),
    (2.4, 0.60, 0.25, 5.0, 0.9),
    (3.0, 0.20, 0.35, 0.8, 4.3),
]

def hash_seed(text):
    h = 0
    for i in range(len(text)):
        h = (h * 31 + ord(text[i])) % 1000003
    return h

def pseudo_rand(x, y, seed):
    v = math.sin(float(x) * 12.9898 + float(y) * 78.233 + float(seed) * 43.123) * 43758.5453
    return v - math.floor(v)

def parse_location(config):
    loc_val = config.get("location")
    if not loc_val:
        return DEFAULT_LOCATION
    if type(loc_val) == "dict":
        return loc_val
    if type(loc_val) == "string":
        decoded = json.decode(loc_val, default = None)
        if decoded and type(decoded) == "dict":
            return decoded
    return DEFAULT_LOCATION

def format_locality(loc):
    if not loc or type(loc) != "dict":
        return "River Basin"

    city = loc.get("city") or loc.get("locality") or ""
    state = loc.get("state") or loc.get("admin_area") or loc.get("province") or ""
    country = loc.get("country") or loc.get("country_code") or ""
    description = loc.get("description") or loc.get("place_name") or loc.get("locality") or ""

    if "," in city:
        description = city
        city = ""

    if not city and description and "," in description:
        parts = [p.strip() for p in description.split(",")]
        if len(parts) >= 3:
            city = parts[0]
            state = parts[1]
            country = parts[-1]
        elif len(parts) == 2:
            city = parts[0]
            country = parts[1]

    country_upper = country.upper()
    is_us = country_upper in ["US", "USA", "UNITED STATES", "UNITED STATES OF AMERICA"] or (state != "" and country == "")

    if city != "" and is_us and state != "":
        return "%s, %s" % (city, state)
    elif city != "" and country != "":
        return "%s, %s" % (city, country)
    elif city != "":
        return city
    elif description != "":
        return description
    return "River Basin"

HEX_CACHE = [HEX_CHARS[i // 16] + HEX_CHARS[i % 16] for i in range(256)]

def rgb_to_hex(rgb):
    r = rgb[0]
    g = rgb[1]
    b = rgb[2]
    r = 0 if r < 0 else (255 if r > 255 else r)
    g = 0 if g < 0 else (255 if g > 255 else g)
    b = 0 if b < 0 else (255 if b > 255 else b)
    return "#" + HEX_CACHE[r] + HEX_CACHE[g] + HEX_CACHE[b]

def lerp_rgb(rgb1, rgb2, t):
    return (
        int(rgb1[0] + (rgb2[0] - rgb1[0]) * t),
        int(rgb1[1] + (rgb2[1] - rgb1[1]) * t),
        int(rgb1[2] + (rgb2[2] - rgb1[2]) * t),
    )

def get_gradient_rgb(palette, t):
    if t <= 0.0:
        return palette[0][1]
    if t >= 1.0:
        return palette[-1][1]
    for i in range(len(palette) - 1):
        p1, c1 = palette[i]
        p2, c2 = palette[i + 1]
        if p1 <= t and t <= p2:
            span = p2 - p1
            local_t = (t - p1) / span if span > 0 else 0.0
            return lerp_rgb(c1, c2, local_t)
    return palette[-1][1]

def get_river_data(config):
    demo_mode = config.get("demo_mode", "live")
    if demo_mode == "pristine_stream":
        return 9.8, 1.2, "Pristine Stream"
    if demo_mode == "healthy_river":
        return 7.5, 0.8, "Healthy River"
    if demo_mode == "hypoxic_alert":
        return 3.2, 0.3, "Hypoxic Alert"
    if demo_mode == "surge_flow":
        return 8.2, 2.5, "Surge Flow"

    famous_key = config.get("famous_river", "custom")
    if famous_key != "custom" and famous_key in FAMOUS_RIVERS:
        riv = FAMOUS_RIVERS[famous_key]
        lat = riv["lat"]
        lng = riv["lng"]
        locality = riv["locality"]
    else:
        loc = parse_location(config)
        lat = float(loc.get("lat", DEFAULT_LOCATION["lat"]))
        lng = float(loc.get("lng", DEFAULT_LOCATION["lng"]))
        locality = format_locality(loc)

    url = "https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&current=precipitation,rain,soil_moisture_0_to_1cm,temperature_2m" % (lat, lng)
    res = http.get(url, ttl_seconds = 1800)

    do_level = 8.0
    flow_speed = 1.0

    if res.status_code == 200:
        body = res.json()
        curr = body.get("current", {})
        temp = float(curr.get("temperature_2m", 15.0))
        precip = float(curr.get("precipitation", 0.0))

        do_level = 14.6 - (0.35 * temp) + (precip * 0.8)
        if do_level < 2.0:
            do_level = 2.0
        elif do_level > 12.0:
            do_level = 12.0

        flow_speed = 0.5 + (precip * 1.5)
        if flow_speed > 3.0:
            flow_speed = 3.0

    return do_level, flow_speed, locality

def select_river_palette(config, do_level):
    p_choice = config.get("palette_choice", "auto")
    if p_choice == "pristine":
        return PALETTE_PRISTINE
    if p_choice == "emerald":
        return PALETTE_EMERALD_BASIN
    if p_choice == "teal":
        return PALETTE_TEAL_CURRENT
    if p_choice == "cyan":
        return PALETTE_CYAN_FLOW
    if p_choice == "hypoxic":
        return PALETTE_HYPOXIC

    if do_level < 4.0:
        return PALETTE_HYPOXIC
    elif do_level < 6.5:
        return PALETTE_TEAL_CURRENT
    elif do_level < 8.5:
        return PALETTE_EMERALD_BASIN
    else:
        return PALETTE_PRISTINE

def main(config):
    width, height = canvas.size()
    scale = 2 if canvas.is2x() else 1

    do_level, flow_speed, locality = get_river_data(config)
    hide_text = config.bool("hide_text")

    palette = select_river_palette(config, do_level)
    loc_seed = hash_seed(locality)

    oxygen_idx = (do_level - 2.0) / 10.0
    if oxygen_idx < 0.0:
        oxygen_idx = 0.0
    elif oxygen_idx > 1.0:
        oxygen_idx = 1.0

    anim_dur = config.get("anim_duration", "medium")
    if anim_dur == "short":
        num_frames = 40
        frame_delay = 100
    elif anim_dur == "long":
        num_frames = 80
        frame_delay = 150
    else:
        num_frames = 60
        frame_delay = 133

    num_blobs = int(2 + oxygen_idx * 4)
    if num_blobs > len(METABALL_SEEDS):
        num_blobs = len(METABALL_SEEDS)

    frames = []
    px_step = 2 * scale

    cols = width // px_step
    rows = height // px_step

    for f in range(num_frames):
        phase = (f / float(num_frames)) * 2.0 * math.pi
        palette_lut = [get_gradient_rgb(palette, i / 31.0) for i in range(32)]

        # Calculate moving 2D metaball centers for frame f
        centers = []
        for i in range(num_blobs):
            r_base, ax, ay, px_, py_ = METABALL_SEEDS[i]
            loc_px = px_ + pseudo_rand(i, 0, loc_seed) * 6.28
            loc_py = py_ + pseudo_rand(i, 1, loc_seed) * 6.28
            cx = 16.0 + 13.0 * math.sin(phase * ax * flow_speed + loc_px)
            cy = 8.0 + 6.5 * math.sin(phase * ay + loc_py)
            centers.append((cx, cy, r_base * r_base))

        row_children = []

        for r in range(rows):
            col_boxes = []
            for c in range(cols):
                # Smooth fluid river flow mechanics for background
                flow_phase = (phase * flow_speed) + (c * 0.15) + (r * 0.10)
                fluid_stream = math.sin(flow_phase) * math.cos(r * 0.20 - phase * 0.3)
                fluid_val = (fluid_stream + 1.0) / 2.0 * 0.5
                f_idx = int(fluid_val * 31.0)
                if f_idx < 0:
                    f_idx = 0
                elif f_idx > 31:
                    f_idx = 31
                bg_rgb = palette_lut[f_idx]

                # Metaball potential field calculation (Chromaclock Lava Lamp physics)
                f_val = 0.0
                for (cx, cy, r2) in centers:
                    dx = c - cx
                    dy = r - cy
                    f_val += r2 / (dx * dx + dy * dy + 0.6)

                if f_val < 0.70:
                    # Undersea river stream background pixel
                    col_boxes.append(render.Box(width = px_step, height = px_step, color = rgb_to_hex(bg_rgb)))
                else:
                    # Glowing bioluminescent oxygen bubble metaball
                    rand_val = pseudo_rand(c, r, loc_seed)
                    shimmer = (math.sin(phase * 2.0 + rand_val * 6.28 + c * 0.3 + r * 0.3) + 1.0) / 2.0
                    bubble_rgb = get_gradient_rgb(palette, 0.4 + 0.6 * shimmer)

                    if f_val < 1.0:
                        # Silky smooth anti-aliased edge contour
                        t_edge = (f_val - 0.70) / 0.30
                        cell_rgb = lerp_rgb(bg_rgb, bubble_rgb, t_edge)
                    else:
                        # Core oxygen bubble with specular shine
                        if f_val > 1.4:
                            t_shine = min((f_val - 1.4) / 0.6, 1.0)
                            cell_rgb = lerp_rgb(bubble_rgb, WHITE_RGB, t_shine * 0.40)
                        else:
                            cell_rgb = bubble_rgb

                    col_boxes.append(render.Box(width = px_step, height = px_step, color = rgb_to_hex(cell_rgb)))

            row_children.append(render.Row(children = col_boxes))

        stack_layers = [
            render.Column(children = row_children),
        ]

        if not hide_text:
            do_str = "%d mg/L" % int(do_level)
            font = "terminus-12" if scale == 2 else "tom-thumb"
            bar_h = 14 if scale == 2 else 8
            bar_y = height - bar_h

            char_w = 6 if scale == 2 else 4
            vis_len = len(do_str)
            metric_w = vis_len * char_w
            gap_w = 3 * scale
            left_pad = 2 * scale
            avail_w = width - left_pad - metric_w - gap_w
            if avail_w < 10 * scale:
                avail_w = 10 * scale

            loc_w = len(locality) * char_w
            if loc_w <= avail_w:
                loc_child = render.Text(content = locality, font = font, color = "#e2e8f0")
            else:
                max_scroll = loc_w - avail_w + (14 * scale)
                scroll_x = int((f / float(num_frames)) * max_scroll)
                loc_child = render.Box(
                    width = avail_w,
                    height = bar_h,
                    child = render.Padding(
                        pad = (-scroll_x, 0, 0, 0),
                        child = render.Text(content = locality, font = font, color = "#e2e8f0"),
                    ),
                )

            text_layer = render.Padding(
                pad = (0, bar_y, 0, 0),
                child = render.Stack(
                    children = [
                        render.Box(width = width, height = bar_h, color = "#000000a0"),
                        render.Padding(
                            pad = (left_pad, 1 * scale, 0, 0),
                            child = render.Row(
                                children = [
                                    render.Text(content = do_str, font = font, color = "#00f5d4"),
                                    render.Box(width = gap_w, height = 1),
                                    render.Box(
                                        width = avail_w,
                                        height = bar_h,
                                        child = loc_child,
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
            )
            stack_layers.append(text_layer)

        frame_stack = render.Stack(children = stack_layers)
        frames.append(frame_stack)

    return render.Root(
        delay = frame_delay,
        child = render.Animation(children = frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "anim_duration",
                name = "Animation Duration",
                desc = "Select animation duration.",
                icon = "clock",
                default = "medium",
                options = [
                    schema.Option(display = "Short (~4s)", value = "short"),
                    schema.Option(display = "Medium (~8s)", value = "medium"),
                    schema.Option(display = "Long (~12s)", value = "long"),
                ],
            ),
            schema.Dropdown(
                id = "palette_choice",
                name = "River Palette",
                desc = "Select water health gradient palette.",
                icon = "palette",
                default = "auto",
                options = [
                    schema.Option(display = "Auto (Based on Oxygen Level)", value = "auto"),
                    schema.Option(display = "Pristine Stream", value = "pristine"),
                    schema.Option(display = "Emerald Basin", value = "emerald"),
                    schema.Option(display = "Teal Current", value = "teal"),
                    schema.Option(display = "Cyan Flow", value = "cyan"),
                    schema.Option(display = "Hypoxic Alert", value = "hypoxic"),
                ],
            ),
            schema.Dropdown(
                id = "famous_river",
                name = "Famous River",
                desc = "Select a famous river featured in ecological art.",
                icon = "water",
                default = "custom",
                options = [
                    schema.Option(display = "Use Custom Location Below", value = "custom"),
                    schema.Option(display = "Amazon River", value = "amazon"),
                    schema.Option(display = "Mississippi River", value = "mississippi"),
                    schema.Option(display = "Danube River", value = "danube"),
                    schema.Option(display = "Rhine River", value = "rhine"),
                    schema.Option(display = "Hudson River", value = "hudson"),
                    schema.Option(display = "Thames River", value = "thames"),
                    schema.Option(display = "Colorado River", value = "colorado"),
                    schema.Option(display = "Winooski River", value = "winooski"),
                ],
            ),
            schema.Location(
                id = "location",
                name = "Custom Location",
                desc = "River basin location (when 'Use Custom Location Below' is selected).",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "hide_text",
                name = "Hide Text Overlay",
                desc = "Hide oxygen metric and location text overlay for pure artwork mode.",
                icon = "eyeSlash",
            ),
            schema.Dropdown(
                id = "demo_mode",
                name = "Demo Preset",
                desc = "Select a preset scenario for testing.",
                icon = "flask",
                default = "live",
                options = [
                    schema.Option(display = "Live API Data", value = "live"),
                    schema.Option(display = "Pristine Stream", value = "pristine_stream"),
                    schema.Option(display = "Healthy River", value = "healthy_river"),
                    schema.Option(display = "Hypoxic Alert", value = "hypoxic_alert"),
                    schema.Option(display = "Surge Flow", value = "surge_flow"),
                ],
            ),
        ],
    )
