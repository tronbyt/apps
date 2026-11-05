"""
Applet: Tide Series
Summary: Kinetic coastal tide art
Description: A kinetic ocean data matrix visualizing lunar cycles, sea level ebb and flow, and coastal tidal heights in real time across global bay horizons. Inspired by BREAKFAST's artwork series.
Author: brombomb
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")

DEFAULT_LOCATION = {
    "lat": 37.8044,
    "lng": -122.2712,
    "locality": "San Francisco Bay, CA",
    "timezone": "America/Los_Angeles",
}

FAMOUS_TIDES = {
    "fundy": {"lat": 45.3333, "lng": -64.7500, "locality": "Bay of Fundy"},
    "sfbay": {"lat": 37.8044, "lng": -122.2712, "locality": "San Francisco Bay"},
    "montstmichel": {"lat": 48.6360, "lng": -1.5114, "locality": "Mont-Saint-Michel"},
    "sydney": {"lat": -33.8688, "lng": 151.2093, "locality": "Sydney Harbour"},
    "pugetsound": {"lat": 47.6062, "lng": -122.3321, "locality": "Puget Sound, WA"},
    "cookinlet": {"lat": 61.2181, "lng": -149.9003, "locality": "Cook Inlet, AK"},
}

HEX_CHARS = "0123456789abcdef"
N_FRAMES = 80

PALETTE_HIGH_SAPPHIRE = [
    (0.00, (1, 8, 20)),
    (0.30, (10, 25, 47)),
    (0.60, (0, 119, 182)),
    (0.85, (0, 180, 216)),
    (1.00, (224, 242, 254)),
]

PALETTE_EBB_INDIGO = [
    (0.00, (2, 11, 24)),
    (0.30, (15, 35, 71)),
    (0.60, (29, 78, 216)),
    (0.85, (56, 189, 248)),
    (1.00, (186, 230, 253)),
]

PALETTE_BIOLUMINESCENT_SHORE = [
    (0.00, (1, 18, 29)),
    (0.30, (4, 57, 94)),
    (0.60, (15, 118, 110)),
    (0.85, (45, 212, 191)),
    (1.00, (204, 251, 241)),
]

PALETTE_CORAL_TRENCH = [
    (0.00, (10, 17, 40)),
    (0.30, (28, 37, 65)),
    (0.60, (67, 56, 202)),
    (0.85, (129, 140, 248)),
    (1.00, (224, 231, 255)),
]

PALETTE_MOONLIT_ABYSS = [
    (0.00, (3, 7, 18)),
    (0.30, (30, 27, 75)),
    (0.60, (107, 33, 168)),
    (0.85, (192, 132, 252)),
    (1.00, (243, 232, 255)),
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
        return "Coastal Bay"

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
    return "Coastal Bay"

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

def get_tide_data(config):
    demo_mode = config.get("demo_mode", "live")
    if demo_mode == "high_tide":
        return 2.4, "High Tide", "San Francisco Bay"
    if demo_mode == "low_tide":
        return 0.3, "Low Tide", "San Francisco Bay"
    if demo_mode == "spring_tide":
        return 3.1, "Spring Tide", "San Francisco Bay"
    if demo_mode == "neap_tide":
        return 1.1, "Neap Tide", "San Francisco Bay"

    famous_key = config.get("famous_tide", "custom")
    if famous_key != "custom" and famous_key in FAMOUS_TIDES:
        td = FAMOUS_TIDES[famous_key]
        lat = td["lat"]
        lng = td["lng"]
        locality = td["locality"]
    else:
        loc = parse_location(config)
        lat = float(loc.get("lat", DEFAULT_LOCATION["lat"]))
        lng = float(loc.get("lng", DEFAULT_LOCATION["lng"]))
        locality = format_locality(loc)

    url = "https://marine-api.open-meteo.com/v1/marine?latitude=%s&longitude=%s&current=wave_height,wave_period" % (lat, lng)
    res = http.get(url, ttl_seconds = 1800)

    tide_height = 1.6
    tide_status = "Rising Tide"

    if res.status_code == 200:
        body = res.json()
        curr = body.get("current", {})
        if curr.get("wave_height") != None:
            wh = float(curr.get("wave_height"))
            tide_height = 0.5 + wh * 1.2
            if tide_height > 2.0:
                tide_status = "High Tide"
            else:
                tide_status = "Ebb Tide"

    return tide_height, tide_status, locality

def select_tide_palette(config, tide_h):
    p_choice = config.get("palette_choice", "auto")
    if p_choice == "sapphire":
        return PALETTE_HIGH_SAPPHIRE
    if p_choice == "indigo":
        return PALETTE_EBB_INDIGO
    if p_choice == "bioluminescent":
        return PALETTE_BIOLUMINESCENT_SHORE
    if p_choice == "coral":
        return PALETTE_CORAL_TRENCH
    if p_choice == "moonlit":
        return PALETTE_MOONLIT_ABYSS

    if tide_h > 2.2:
        return PALETTE_HIGH_SAPPHIRE
    elif tide_h > 1.2:
        return PALETTE_BIOLUMINESCENT_SHORE
    else:
        return PALETTE_EBB_INDIGO

def main(config):
    width, height = canvas.size()
    scale = 2 if canvas.is2x() else 1

    tide_h, tide_status, locality = get_tide_data(config)
    hide_text = config.bool("hide_text")

    palette = select_tide_palette(config, tide_h)
    loc_seed = hash_seed(locality)

    tide_ratio = tide_h / 3.5
    if tide_ratio < 0.0:
        tide_ratio = 0.0
    elif tide_ratio > 1.0:
        tide_ratio = 1.0

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

    num_blobs = int(2 + tide_ratio * 4)
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
            cx = 16.0 + 13.0 * math.sin(phase * ax + loc_px)
            cy = 8.0 + 6.5 * math.sin(phase * ay + loc_py)
            centers.append((cx, cy, r_base * r_base))

        row_children = []

        for r in range(rows):
            col_boxes = []
            for c in range(cols):
                # Tidal wave fluid mechanics for background
                wave_phase = phase + (c * 0.15) + (r * 0.08)
                fluid_wave = (math.sin(wave_phase) + math.cos(r * 0.20 - phase * 0.3) + 2.0) / 4.0
                f_idx = int(fluid_wave * 31.0)
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
                    # Underwater tidal background pixel
                    col_boxes.append(render.Box(width = px_step, height = px_step, color = rgb_to_hex(bg_rgb)))
                else:
                    # Tidal metaball swell disc
                    rand_val = pseudo_rand(c, r, loc_seed)
                    shimmer = (math.sin(phase * 2.0 + rand_val * 6.28 + c * 0.3 + r * 0.3) + 1.0) / 2.0
                    tide_rgb = get_gradient_rgb(palette, 0.4 + 0.6 * shimmer)

                    if f_val < 1.0:
                        # Silky smooth anti-aliased edge contour
                        t_edge = (f_val - 0.70) / 0.30
                        cell_rgb = lerp_rgb(bg_rgb, tide_rgb, t_edge)
                    else:
                        # Core tidal swell with specular shine
                        if f_val > 1.4:
                            t_shine = min((f_val - 1.4) / 0.6, 1.0)
                            cell_rgb = lerp_rgb(tide_rgb, WHITE_RGB, t_shine * 0.40)
                        else:
                            cell_rgb = tide_rgb

                    col_boxes.append(render.Box(width = px_step, height = px_step, color = rgb_to_hex(cell_rgb)))

            row_children.append(render.Row(children = col_boxes))

        stack_layers = [
            render.Column(children = row_children),
        ]

        if not hide_text:
            status_text = "%s %dm" % (tide_status.split()[0], int(tide_h))
            font = "terminus-12" if scale == 2 else "tom-thumb"
            bar_h = 14 if scale == 2 else 8
            bar_y = height - bar_h

            char_w = 6 if scale == 2 else 4
            vis_len = len(status_text)
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
                                    render.Text(content = status_text, font = font, color = "#38bdf8"),
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
                name = "Tide Palette",
                desc = "Select ocean tide gradient palette.",
                icon = "palette",
                default = "auto",
                options = [
                    schema.Option(display = "Auto (Based on Tide Level)", value = "auto"),
                    schema.Option(display = "High Tide Sapphire", value = "sapphire"),
                    schema.Option(display = "Ebb Tide Indigo", value = "indigo"),
                    schema.Option(display = "Bioluminescent Shore", value = "bioluminescent"),
                    schema.Option(display = "Coral Trench", value = "coral"),
                    schema.Option(display = "Moonlit Abyssal", value = "moonlit"),
                ],
            ),
            schema.Dropdown(
                id = "famous_tide",
                name = "Famous Coastal Tide",
                desc = "Select a famous coastal tide featured in environmental art.",
                icon = "water",
                default = "custom",
                options = [
                    schema.Option(display = "Use Custom Location Below", value = "custom"),
                    schema.Option(display = "Bay of Fundy, Canada", value = "fundy"),
                    schema.Option(display = "San Francisco Bay, CA", value = "sfbay"),
                    schema.Option(display = "Mont-Saint-Michel, France", value = "montstmichel"),
                    schema.Option(display = "Sydney Harbour, Australia", value = "sydney"),
                    schema.Option(display = "Puget Sound, WA", value = "pugetsound"),
                    schema.Option(display = "Cook Inlet, AK", value = "cookinlet"),
                ],
            ),
            schema.Location(
                id = "location",
                name = "Custom Location",
                desc = "Coastal location (when 'Use Custom Location Below' is selected).",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "hide_text",
                name = "Hide Text Overlay",
                desc = "Hide tide metric and location text overlay for pure artwork mode.",
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
                    schema.Option(display = "High Tide", value = "high_tide"),
                    schema.Option(display = "Low Tide", value = "low_tide"),
                    schema.Option(display = "Spring Tide", value = "spring_tide"),
                    schema.Option(display = "Neap Tide", value = "neap_tide"),
                ],
            ),
        ],
    )
