"""
Applet: Warming Sea Series
Summary: Kinetic ocean temperature art
Description: A kinetic ocean data matrix visualizing real-time sea temperatures through motion and reflection, translating rising sea temperatures into shimmering patterns of gold across blue-green under-sea fields. Inspired by BREAKFAST's Warming Seas series.
Author: brombomb
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")

DEFAULT_LOCATION = {
    "lat": 25.7617,
    "lng": -80.1918,
    "locality": "Miami, FL",
    "timezone": "America/New_York",
}

FAMOUS_SEAS = {
    "monterey_bay": {"lat": 36.6002, "lng": -121.8947, "locality": "Monterey Bay, CA"},
    "great_barrier_reef": {"lat": -18.2871, "lng": 147.6992, "locality": "Great Barrier Reef"},
    "coral_sea": {"lat": -16.0000, "lng": 150.0000, "locality": "Coral Sea"},
    "gulf_of_mexico": {"lat": 25.0000, "lng": -90.0000, "locality": "Gulf of Mexico"},
    "mediterranean": {"lat": 35.0000, "lng": 18.0000, "locality": "Mediterranean Sea"},
    "caribbean": {"lat": 15.0000, "lng": -75.0000, "locality": "Caribbean Sea"},
    "north_sea": {"lat": 56.0000, "lng": 3.0000, "locality": "North Sea"},
    "red_sea": {"lat": 20.0000, "lng": 38.0000, "locality": "Red Sea"},
}

HEX_CHARS = "0123456789abcdef"
N_FRAMES = 80

# 5 Custom Under-Sea Gradients (Fluid Blue-Green / Teal / Turquoise / Emerald Tones)
PALETTE_DEEP_TEAL = [
    (0.00, (1, 9, 18)),
    (0.25, (5, 35, 45)),
    (0.50, (9, 72, 86)),
    (0.75, (16, 123, 138)),
    (1.00, (47, 181, 192)),
]

PALETTE_EMERALD_REEF = [
    (0.00, (1, 14, 18)),
    (0.25, (5, 50, 43)),
    (0.50, (12, 99, 82)),
    (0.75, (21, 156, 127)),
    (1.00, (72, 209, 179)),
]

PALETTE_TURQUOISE_TRENCH = [
    (0.00, (3, 10, 28)),
    (0.25, (10, 46, 76)),
    (0.50, (0, 95, 115)),
    (0.75, (10, 147, 150)),
    (1.00, (148, 210, 189)),
]

PALETTE_ABYSSAL_SEAFOAM = [
    (0.00, (1, 8, 16)),
    (0.25, (12, 34, 51)),
    (0.50, (20, 69, 82)),
    (0.75, (43, 122, 120)),
    (1.00, (100, 223, 223)),
]

PALETTE_BIOLUMINESCENT = [
    (0.00, (2, 8, 19)),
    (0.25, (9, 29, 52)),
    (0.50, (15, 76, 92)),
    (0.75, (30, 136, 229)),
    (1.00, (86, 197, 150)),
]

PALETTE_GOLD_FOIL = [
    (0.00, (198, 146, 20)),
    (0.35, (229, 184, 11)),
    (0.70, (255, 215, 0)),
    (0.90, (255, 234, 0)),
    (1.00, (255, 245, 157)),
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
    """Generate a deterministic seed per location so every sea has its own unique gold bubble distribution pattern."""
    h = 0
    for i in range(len(text)):
        h = (h * 31 + ord(text[i])) % 1000003
    return h

def pseudo_rand(x, y, seed):
    """Deterministic pseudo-random hash generator for Starlark."""
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
        return "Miami, FL"

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
    return "Miami, FL"

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

def get_ocean_data(config):
    demo_mode = config.get("demo_mode", "live")
    if demo_mode == "cool_deep":
        return 14.5, 0.8, "Cool Ocean"
    if demo_mode == "moderate_warm":
        return 23.5, 1.5, "Warm Current"
    if demo_mode == "extreme_heat":
        return 32.0, 2.4, "Heat Anomaly"
    if demo_mode == "storm_wave":
        return 21.0, 4.2, "Storm Swell"

    famous_key = config.get("famous_sea", "custom")
    if famous_key != "custom" and famous_key in FAMOUS_SEAS:
        sea = FAMOUS_SEAS[famous_key]
        lat = sea["lat"]
        lng = sea["lng"]
        locality = sea["locality"]
    else:
        loc = parse_location(config)
        lat = float(loc.get("lat", DEFAULT_LOCATION["lat"]))
        lng = float(loc.get("lng", DEFAULT_LOCATION["lng"]))
        locality = format_locality(loc)

    marine_url = "https://marine-api.open-meteo.com/v1/marine?latitude=%s&longitude=%s&current=wave_height,ocean_current_velocity" % (lat, lng)
    res = http.get(marine_url, ttl_seconds = 1800)

    wave_h = 1.2
    if res.status_code == 200:
        body = res.json()
        curr = body.get("current", {})
        if curr.get("wave_height") != None:
            wave_h = float(curr.get("wave_height"))

    weather_url = "https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&current=temperature_2m" % (lat, lng)
    res_w = http.get(weather_url, ttl_seconds = 1800)

    temp_c = 22.0
    if res_w.status_code == 200:
        body_w = res_w.json()
        curr_w = body_w.get("current", {})
        if curr_w.get("temperature_2m") != None:
            temp_c = float(curr_w.get("temperature_2m"))

    return temp_c, wave_h, locality

def select_undersea_palette(config, temp_c):
    p_choice = config.get("palette_choice", "auto")
    if p_choice == "deep_teal":
        return PALETTE_DEEP_TEAL
    if p_choice == "emerald_reef":
        return PALETTE_EMERALD_REEF
    if p_choice == "turquoise_trench":
        return PALETTE_TURQUOISE_TRENCH
    if p_choice == "abyssal_seafoam":
        return PALETTE_ABYSSAL_SEAFOAM
    if p_choice == "bioluminescent":
        return PALETTE_BIOLUMINESCENT

    if temp_c < 18.0:
        return PALETTE_DEEP_TEAL
    elif temp_c < 22.0:
        return PALETTE_TURQUOISE_TRENCH
    elif temp_c < 26.0:
        return PALETTE_EMERALD_REEF
    elif temp_c < 30.0:
        return PALETTE_ABYSSAL_SEAFOAM
    else:
        return PALETTE_BIOLUMINESCENT

def main(config):
    width, height = canvas.size()
    scale = 2 if canvas.is2x() else 1

    temp_c, wave_h, locality = get_ocean_data(config)
    hide_text = config.bool("hide_text")

    palette = select_undersea_palette(config, temp_c)
    loc_seed = hash_seed(locality)

    # Heat density controls how many gold bubbles emerge across the sea
    heat_density = (temp_c - 12.0) / 22.0
    if heat_density < 0.05:
        heat_density = 0.05
    elif heat_density > 0.85:
        heat_density = 0.85

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

    frames = []
    px_step = 2 * scale

    cols = width // px_step
    rows = height // px_step

    num_blobs = int(2 + heat_density * 4)
    if num_blobs > len(METABALL_SEEDS):
        num_blobs = len(METABALL_SEEDS)

    for f in range(num_frames):
        phase = (f / float(num_frames)) * 2.0 * math.pi
        palette_lut = [get_gradient_rgb(palette, i / 31.0) for i in range(32)]

        # Calculate moving 2D metaball centers for frame f
        centers = []
        for i in range(num_blobs):
            r_base, ax, ay, px_, py_ = METABALL_SEEDS[i]
            loc_px = px_ + pseudo_rand(i, 0, loc_seed) * 6.28
            loc_py = py_ + pseudo_rand(i, 1, loc_seed) * 6.28
            cx = 16.0 + 13.0 * math.sin(phase * ax + loc_px)
            cy = 8.0 + 6.5 * math.sin(phase * ay + loc_py)
            centers.append((cx, cy, r_base * r_base))

        row_children = []

        for r in range(rows):
            col_boxes = []
            for c in range(cols):
                # Smooth fluid undersea wave mechanics for background
                fluid_stream = math.sin(c * 0.25 + math.sin(r * 0.12 * (0.8 + 0.2 * wave_h) + phase * 0.5) * 1.5)
                fluid_ripple = math.cos(r * 0.20 - c * 0.10 + phase * 0.3)
                fluid_val = (fluid_stream + fluid_ripple + 2.0) / 4.0
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
                    # Ocean fluid background pixel
                    col_boxes.append(render.Box(width = px_step, height = px_step, color = rgb_to_hex(bg_rgb)))
                else:
                    # Gold metaball bubble disc
                    rand_val = pseudo_rand(c, r, loc_seed)
                    shimmer = (math.sin(phase * 2.0 + rand_val * 6.28 + c * 0.3 + r * 0.3) + 1.0) / 2.0
                    gold_rgb = get_gradient_rgb(PALETTE_GOLD_FOIL, 0.2 + 0.8 * shimmer)

                    if f_val < 1.0:
                        # Silky smooth anti-aliased edge contour
                        t_edge = (f_val - 0.70) / 0.30
                        cell_rgb = lerp_rgb(bg_rgb, gold_rgb, t_edge)
                    else:
                        # Core gold metaball bubble with specular shine
                        if f_val > 1.4:
                            t_shine = min((f_val - 1.4) / 0.6, 1.0)
                            cell_rgb = lerp_rgb(gold_rgb, WHITE_RGB, t_shine * 0.40)
                        else:
                            cell_rgb = gold_rgb

                    col_boxes.append(render.Box(width = px_step, height = px_step, color = rgb_to_hex(cell_rgb)))

            row_children.append(render.Row(children = col_boxes))

            row_children.append(render.Row(children = col_boxes))

        stack_layers = [
            render.Column(children = row_children),
        ]

        if not hide_text:
            use_f = config.bool("use_fahrenheit")
            if use_f:
                disp_temp = "%d°F" % int(temp_c * 9.0 / 5.0 + 32.0)
            else:
                disp_temp = "%d°C" % int(temp_c)

            font = "terminus-12" if scale == 2 else "tom-thumb"
            bar_h = 14 if scale == 2 else 8
            bar_y = height - bar_h

            char_w = 6 if scale == 2 else 4
            vis_len = len(disp_temp.replace("°", "o"))
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
                                    render.Text(content = disp_temp, font = font, color = "#ffd700"),
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
                name = "Undersea Palette",
                desc = "Select blue-green undersea gradient palette.",
                icon = "palette",
                default = "auto",
                options = [
                    schema.Option(display = "Auto (Based on Ocean Temp)", value = "auto"),
                    schema.Option(display = "Deep Ocean Teal", value = "deep_teal"),
                    schema.Option(display = "Emerald Reef", value = "emerald_reef"),
                    schema.Option(display = "Turquoise Trench", value = "turquoise_trench"),
                    schema.Option(display = "Abyssal Seafoam", value = "abyssal_seafoam"),
                    schema.Option(display = "Bioluminescent Abyss", value = "bioluminescent"),
                ],
            ),
            schema.Dropdown(
                id = "famous_sea",
                name = "Famous Sea",
                desc = "Select a famous sea featured in environmental art.",
                icon = "water",
                default = "custom",
                options = [
                    schema.Option(display = "Use Custom Location Below", value = "custom"),
                    schema.Option(display = "Monterey Bay, CA", value = "monterey_bay"),
                    schema.Option(display = "Great Barrier Reef", value = "great_barrier_reef"),
                    schema.Option(display = "Coral Sea", value = "coral_sea"),
                    schema.Option(display = "Gulf of Mexico", value = "gulf_of_mexico"),
                    schema.Option(display = "Mediterranean Sea", value = "mediterranean"),
                    schema.Option(display = "Caribbean Sea", value = "caribbean"),
                    schema.Option(display = "North Sea", value = "north_sea"),
                    schema.Option(display = "Red Sea", value = "red_sea"),
                ],
            ),
            schema.Location(
                id = "location",
                name = "Custom Location",
                desc = "Ocean / Coastal location (when 'Use Custom Location Below' is selected).",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "hide_text",
                name = "Hide Text Overlay",
                desc = "Hide temperature and location text overlay for pure artwork mode.",
                icon = "eyeSlash",
            ),
            schema.Toggle(
                id = "use_fahrenheit",
                name = "Use Fahrenheit",
                desc = "Display temperature in Fahrenheit.",
                icon = "temperatureHigh",
            ),
            schema.Dropdown(
                id = "demo_mode",
                name = "Demo Preset",
                desc = "Select a preset scenario for testing.",
                icon = "flask",
                default = "live",
                options = [
                    schema.Option(display = "Live API Data", value = "live"),
                    schema.Option(display = "Cool Deep Ocean", value = "cool_deep"),
                    schema.Option(display = "Warm Current", value = "moderate_warm"),
                    schema.Option(display = "Heat Anomaly", value = "extreme_heat"),
                    schema.Option(display = "Storm Swell", value = "storm_wave"),
                ],
            ),
        ],
    )
