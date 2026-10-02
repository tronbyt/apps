"""
Applet: World Skies
Summary: Kinetic atmospheric sky art
Description: A kinetic atmospheric data matrix visualizing cloud density waves, global sky visibility, and celestial light transit in real time across global skylines. Inspired by BREAKFAST's artwork series.
Author: brombomb
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")

DEFAULT_LOCATION = {
    "lat": 51.5074,
    "lng": -0.1278,
    "locality": "London, UK",
    "timezone": "Europe/London",
}

FAMOUS_SKIES = {
    "london": {"lat": 51.5074, "lng": -0.1278, "locality": "London Sky"},
    "paris": {"lat": 48.8566, "lng": 2.3522, "locality": "Paris Sky"},
    "tokyo": {"lat": 35.6762, "lng": 139.6503, "locality": "Tokyo Sky"},
    "newyork": {"lat": 40.7128, "lng": -74.0060, "locality": "New York Sky"},
    "sydney": {"lat": -33.8688, "lng": 151.2093, "locality": "Sydney Harbour"},
    "cairo": {"lat": 30.0444, "lng": 31.2357, "locality": "Cairo Sky"},
    "reykjavik": {"lat": 64.1466, "lng": -21.9426, "locality": "Reykjavik Aurora"},
}

HEX_CHARS = "0123456789abcdef"
N_FRAMES = 80

PALETTE_CLEAR_DAY = [
    (0.00, (3, 4, 94)),
    (0.30, (0, 119, 182)),
    (0.60, (0, 180, 216)),
    (0.85, (144, 224, 239)),
    (1.00, (255, 251, 235)),
]

PALETTE_GOLDEN_HOUR = [
    (0.00, (43, 9, 56)),
    (0.30, (106, 27, 82)),
    (0.60, (201, 56, 63)),
    (0.85, (244, 112, 53)),
    (1.00, (255, 183, 3)),
]

PALETTE_OVERCAST_SKY = [
    (0.00, (17, 24, 39)),
    (0.35, (31, 41, 55)),
    (0.70, (75, 85, 99)),
    (1.00, (156, 163, 175)),
]

PALETTE_POLAR_AURORA = [
    (0.00, (3, 23, 22)),
    (0.30, (13, 59, 46)),
    (0.65, (6, 214, 160)),
    (1.00, (118, 234, 215)),
]

PALETTE_NIGHT_SKY = [
    (0.00, (3, 7, 18)),
    (0.40, (15, 23, 42)),
    (0.75, (30, 27, 75)),
    (1.00, (49, 46, 129)),
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
        return "Global Sky"

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
    return "Global Sky"

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

def get_sky_data(config):
    demo_mode = config.get("demo_mode", "live")
    if demo_mode == "clear_dawn":
        return 1, 10, "Dawn Sky"
    if demo_mode == "blue_zenith":
        return 1, 20, "Clear Zenith"
    if demo_mode == "golden_sunset":
        return 1, 45, "Golden Sunset"
    if demo_mode == "overcast_storm":
        return 1, 92, "Storm Clouds"
    if demo_mode == "starry_night":
        return 0, 15, "Starry Night"

    famous_key = config.get("famous_sky", "custom")
    if famous_key != "custom" and famous_key in FAMOUS_SKIES:
        sky = FAMOUS_SKIES[famous_key]
        lat = sky["lat"]
        lng = sky["lng"]
        locality = sky["locality"]
    else:
        loc = parse_location(config)
        lat = float(loc.get("lat", DEFAULT_LOCATION["lat"]))
        lng = float(loc.get("lng", DEFAULT_LOCATION["lng"]))
        locality = format_locality(loc)

    url = "https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&current=is_day,cloud_cover" % (lat, lng)
    res = http.get(url, ttl_seconds = 1800)

    is_day = 1
    cloud_cover = 35

    if res.status_code == 200:
        body = res.json()
        curr = body.get("current", {})
        if curr.get("is_day") != None:
            is_day = int(curr.get("is_day"))
        if curr.get("cloud_cover") != None:
            cloud_cover = int(curr.get("cloud_cover"))

    return is_day, cloud_cover, locality

def select_sky_palette(config, is_day, cloud_cover):
    p_choice = config.get("palette_choice", "auto")
    if p_choice == "clear_day":
        return PALETTE_CLEAR_DAY
    if p_choice == "golden_hour":
        return PALETTE_GOLDEN_HOUR
    if p_choice == "overcast":
        return PALETTE_OVERCAST_SKY
    if p_choice == "aurora":
        return PALETTE_POLAR_AURORA
    if p_choice == "night":
        return PALETTE_NIGHT_SKY

    if is_day == 0:
        return PALETTE_NIGHT_SKY
    elif cloud_cover > 75:
        return PALETTE_OVERCAST_SKY
    elif cloud_cover > 30:
        return PALETTE_GOLDEN_HOUR
    else:
        return PALETTE_CLEAR_DAY

def main(config):
    width, height = canvas.size()
    scale = 2 if canvas.is2x() else 1

    is_day, cloud_cover, locality = get_sky_data(config)
    hide_text = config.bool("hide_text")

    palette = select_sky_palette(config, is_day, cloud_cover)
    loc_seed = hash_seed(locality)

    cloud_ratio = cloud_cover / 100.0
    if cloud_ratio < 0.0:
        cloud_ratio = 0.0
    elif cloud_ratio > 1.0:
        cloud_ratio = 1.0

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

    num_blobs = int(2 + cloud_ratio * 4)
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
                # Atmospheric fluid canopy wave physics for background
                sky_wave = math.sin(phase + c * 0.15 + r * 0.10)
                sky_ripple = math.cos(r * 0.20 - c * 0.08 + phase * 0.4)
                fluid_val = (sky_wave + sky_ripple + 2.0) / 4.0 * 0.4
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
                    # Clear sky background pixel
                    col_boxes.append(render.Box(width = px_step, height = px_step, color = rgb_to_hex(bg_rgb)))
                else:
                    # Cloud canopy metaball blob
                    rand_val = pseudo_rand(c, r, loc_seed)
                    shimmer = (math.sin(phase * 2.0 + rand_val * 6.28 + c * 0.3 + r * 0.3) + 1.0) / 2.0
                    cloud_rgb = get_gradient_rgb(palette, 0.3 + 0.7 * shimmer)

                    if f_val < 1.0:
                        # Silky smooth anti-aliased edge contour
                        t_edge = (f_val - 0.70) / 0.30
                        cell_rgb = lerp_rgb(bg_rgb, cloud_rgb, t_edge)
                    else:
                        # Core cloud canopy with specular shine
                        if f_val > 1.4:
                            t_shine = min((f_val - 1.4) / 0.6, 1.0)
                            cell_rgb = lerp_rgb(cloud_rgb, WHITE_RGB, t_shine * 0.40)
                        else:
                            cell_rgb = cloud_rgb

                    col_boxes.append(render.Box(width = px_step, height = px_step, color = rgb_to_hex(cell_rgb)))

            row_children.append(render.Row(children = col_boxes))

        stack_layers = [
            render.Column(children = row_children),
        ]

        if not hide_text:
            sky_text = "Cloud %d%%" % cloud_cover
            font = "terminus-12" if scale == 2 else "tom-thumb"
            bar_h = 14 if scale == 2 else 8
            bar_y = height - bar_h

            char_w = 6 if scale == 2 else 4
            vis_len = len(sky_text)
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
                                    render.Text(content = sky_text, font = font, color = "#90e0ef"),
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
                name = "Sky Palette",
                desc = "Select atmospheric sky gradient palette.",
                icon = "palette",
                default = "auto",
                options = [
                    schema.Option(display = "Auto (Based on Cloud & Day/Night)", value = "auto"),
                    schema.Option(display = "Clear Day Zenith", value = "clear_day"),
                    schema.Option(display = "Golden Hour Sunset", value = "golden_hour"),
                    schema.Option(display = "Overcast Storm Canopy", value = "overcast"),
                    schema.Option(display = "Polar Aurora Sky", value = "aurora"),
                    schema.Option(display = "Starry Night Sky", value = "night"),
                ],
            ),
            schema.Dropdown(
                id = "famous_sky",
                name = "Famous Sky",
                desc = "Select a famous skyline featured in atmospheric art.",
                icon = "cloud",
                default = "custom",
                options = [
                    schema.Option(display = "Use Custom Location Below", value = "custom"),
                    schema.Option(display = "London Sky, UK", value = "london"),
                    schema.Option(display = "Paris Sky, France", value = "paris"),
                    schema.Option(display = "Tokyo Sky, Japan", value = "tokyo"),
                    schema.Option(display = "New York Sky, USA", value = "newyork"),
                    schema.Option(display = "Sydney Harbour, Australia", value = "sydney"),
                    schema.Option(display = "Cairo Sky, Egypt", value = "cairo"),
                    schema.Option(display = "Reykjavik Aurora, Iceland", value = "reykjavik"),
                ],
            ),
            schema.Location(
                id = "location",
                name = "Custom Location",
                desc = "Sky location (when 'Use Custom Location Below' is selected).",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "hide_text",
                name = "Hide Text Overlay",
                desc = "Hide cloud metric and location text overlay for pure artwork mode.",
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
                    schema.Option(display = "Clear Dawn", value = "clear_dawn"),
                    schema.Option(display = "Blue Zenith", value = "blue_zenith"),
                    schema.Option(display = "Golden Sunset", value = "golden_sunset"),
                    schema.Option(display = "Overcast Storm", value = "overcast_storm"),
                    schema.Option(display = "Starry Night", value = "starry_night"),
                ],
            ),
        ],
    )
