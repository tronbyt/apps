"""
Applet: Air Series
Summary: Kinetic air quality & wind art
Description: A kinetic atmospheric particle matrix visualizing Air Quality Index (AQI), PM2.5 particle density, and wind vectors in real time across global atmospheric basins. Inspired by BREAKFAST's artwork series.
Author: brombomb
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")

DEFAULT_LOCATION = {
    "lat": 34.0522,
    "lng": -118.2437,
    "locality": "Los Angeles, CA",
    "timezone": "America/Los_Angeles",
}

FAMOUS_CITIES = {
    "losangeles": {"lat": 34.0522, "lng": -118.2437, "locality": "Los Angeles, CA"},
    "chicago": {"lat": 41.8781, "lng": -87.6298, "locality": "Chicago, IL"},
    "beijing": {"lat": 39.9042, "lng": 116.4074, "locality": "Beijing, China"},
    "newdelhi": {"lat": 28.6139, "lng": 77.2090, "locality": "New Delhi, India"},
    "mexicocity": {"lat": 19.4326, "lng": -99.1332, "locality": "Mexico City, Mexico"},
    "reykjavik": {"lat": 64.1466, "lng": -21.9426, "locality": "Reykjavik, Iceland"},
}

HEX_CHARS = "0123456789abcdef"
N_FRAMES = 80

PALETTE_ALPINE_BREEZE = [
    (0.00, (3, 27, 38)),
    (0.35, (11, 79, 108)),
    (0.70, (1, 186, 239)),
    (1.00, (32, 191, 107)),
]

PALETTE_OCEAN_MIST = [
    (0.00, (3, 20, 36)),
    (0.35, (0, 119, 182)),
    (0.70, (72, 202, 228)),
    (1.00, (173, 232, 244)),
]

PALETTE_MODERATE_HAZE = [
    (0.00, (31, 29, 3)),
    (0.35, (87, 78, 2)),
    (0.70, (217, 119, 6)),
    (1.00, (245, 158, 11)),
]

PALETTE_SMOG_WARNING = [
    (0.00, (38, 3, 23)),
    (0.35, (92, 6, 50)),
    (0.70, (147, 51, 234)),
    (1.00, (225, 29, 72)),
]

PALETTE_ALTITUDE_VIOLET = [
    (0.00, (18, 3, 36)),
    (0.35, (59, 7, 100)),
    (0.70, (126, 34, 206)),
    (1.00, (168, 85, 247)),
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
        return "City Air"

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
    return "City Air"

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

def get_air_data(config):
    demo_mode = config.get("demo_mode", "live")
    if demo_mode == "clean_breeze":
        return 22, 12.0, "Good", "Crisp Breeze"
    if demo_mode == "moderate_haze":
        return 75, 8.0, "Moderate", "Hazy Sky"
    if demo_mode == "unhealthy_smog":
        return 165, 4.0, "Unhealthy", "Smog Alert"
    if demo_mode == "gusty_gale":
        return 45, 28.0, "Good", "Gusty Wind"

    famous_key = config.get("famous_city", "custom")
    if famous_key != "custom" and famous_key in FAMOUS_CITIES:
        c = FAMOUS_CITIES[famous_key]
        lat = c["lat"]
        lng = c["lng"]
        locality = c["locality"]
    else:
        loc = parse_location(config)
        lat = float(loc.get("lat", DEFAULT_LOCATION["lat"]))
        lng = float(loc.get("lng", DEFAULT_LOCATION["lng"]))
        locality = format_locality(loc)

    aqi_url = "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=%s&longitude=%s&current=us_aqi,pm2_5" % (lat, lng)
    res_aq = http.get(aqi_url, ttl_seconds = 1800)

    aqi_val = 35
    if res_aq.status_code == 200:
        body = res_aq.json()
        curr = body.get("current", {})
        if curr.get("us_aqi") != None:
            aqi_val = int(curr.get("us_aqi"))

    w_url = "https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&current=wind_speed_10m" % (lat, lng)
    res_w = http.get(w_url, ttl_seconds = 1800)

    wind_speed = 10.0
    if res_w.status_code == 200:
        body_w = res_w.json()
        curr_w = body_w.get("current", {})
        if curr_w.get("wind_speed_10m") != None:
            wind_speed = float(curr_w.get("wind_speed_10m"))

    status_str = "Good"
    if aqi_val > 100:
        status_str = "Unhealthy"
    elif aqi_val > 50:
        status_str = "Moderate"

    return aqi_val, wind_speed, status_str, locality

def select_air_palette(config, aqi_val):
    p_choice = config.get("palette_choice", "auto")
    if p_choice == "alpine":
        return PALETTE_ALPINE_BREEZE
    if p_choice == "mist":
        return PALETTE_OCEAN_MIST
    if p_choice == "haze":
        return PALETTE_MODERATE_HAZE
    if p_choice == "smog":
        return PALETTE_SMOG_WARNING
    if p_choice == "violet":
        return PALETTE_ALTITUDE_VIOLET

    if aqi_val <= 50:
        return PALETTE_ALPINE_BREEZE
    elif aqi_val <= 100:
        return PALETTE_MODERATE_HAZE
    else:
        return PALETTE_SMOG_WARNING

def main(config):
    width, height = canvas.size()
    scale = 2 if canvas.is2x() else 1

    aqi_val, wind_speed, _, locality = get_air_data(config)
    hide_text = config.bool("hide_text")

    palette = select_air_palette(config, aqi_val)
    loc_seed = hash_seed(locality)

    aqi_ratio = aqi_val / 200.0
    if aqi_ratio < 0.0:
        aqi_ratio = 0.0
    elif aqi_ratio > 1.0:
        aqi_ratio = 1.0

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

    num_blobs = int(2 + aqi_ratio * 4)
    if num_blobs > len(METABALL_SEEDS):
        num_blobs = len(METABALL_SEEDS)

    frames = []
    px_step = 2 * scale

    cols = width // px_step
    rows = height // px_step

    wind_factor = (wind_speed / 20.0)
    if wind_factor < 0.5:
        wind_factor = 0.5

    for f in range(num_frames):
        phase = (f / float(num_frames)) * 2.0 * math.pi
        palette_lut = [get_gradient_rgb(palette, i / 31.0) for i in range(32)]

        # Calculate moving 2D metaball centers for frame f
        centers = []
        for i in range(num_blobs):
            r_base, ax, ay, px_, py_ = METABALL_SEEDS[i]
            loc_px = px_ + pseudo_rand(i, 0, loc_seed) * 6.28
            loc_py = py_ + pseudo_rand(i, 1, loc_seed) * 6.28
            cx = 16.0 + 13.0 * math.sin(phase * ax * wind_factor + loc_px)
            cy = 8.0 + 6.5 * math.sin(phase * ay + loc_py)
            centers.append((cx, cy, r_base * r_base))

        row_children = []

        for r in range(rows):
            col_boxes = []
            for c in range(cols):
                # Smooth fluid atmospheric wind vector mechanics for background
                wind_phase = (phase * wind_factor) + (c * 0.12) + (r * 0.08)
                fluid_vector = math.cos(wind_phase) * math.sin(r * 0.15 - phase * 0.3)
                fluid_val = (fluid_vector + 1.0) / 2.0 * 0.4
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
                    # Fluid atmospheric background pixel
                    col_boxes.append(render.Box(width = px_step, height = px_step, color = rgb_to_hex(bg_rgb)))
                else:
                    # Atmospheric wind particle metaball blob
                    rand_val = pseudo_rand(c, r, loc_seed)
                    shimmer = (math.sin(phase * 2.0 + rand_val * 6.28 + c * 0.3 + r * 0.3) + 1.0) / 2.0
                    particle_rgb = get_gradient_rgb(palette, 0.3 + 0.7 * shimmer)

                    if f_val < 1.0:
                        # Silky smooth anti-aliased edge contour
                        t_edge = (f_val - 0.70) / 0.30
                        cell_rgb = lerp_rgb(bg_rgb, particle_rgb, t_edge)
                    else:
                        # Core particle density with specular shine
                        if f_val > 1.4:
                            t_shine = min((f_val - 1.4) / 0.6, 1.0)
                            cell_rgb = lerp_rgb(particle_rgb, WHITE_RGB, t_shine * 0.40)
                        else:
                            cell_rgb = particle_rgb

                    col_boxes.append(render.Box(width = px_step, height = px_step, color = rgb_to_hex(cell_rgb)))

            row_children.append(render.Row(children = col_boxes))

        stack_layers = [
            render.Column(children = row_children),
        ]

        if not hide_text:
            aqi_text = "AQI %d" % aqi_val
            font = "terminus-12" if scale == 2 else "tom-thumb"
            bar_h = 14 if scale == 2 else 8
            bar_y = height - bar_h

            char_w = 6 if scale == 2 else 4
            vis_len = len(aqi_text)
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
                                    render.Text(content = aqi_text, font = font, color = "#ffffff"),
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
                name = "Air Palette",
                desc = "Select atmospheric AQI gradient palette.",
                icon = "palette",
                default = "auto",
                options = [
                    schema.Option(display = "Auto (Based on AQI Level)", value = "auto"),
                    schema.Option(display = "Crisp Alpine Breeze", value = "alpine"),
                    schema.Option(display = "Ocean Mist", value = "mist"),
                    schema.Option(display = "Moderate Haze", value = "haze"),
                    schema.Option(display = "Smog Warning", value = "smog"),
                    schema.Option(display = "High Altitude Violet", value = "violet"),
                ],
            ),
            schema.Dropdown(
                id = "famous_city",
                name = "Famous Air City",
                desc = "Select a famous city featured in atmospheric art.",
                icon = "wind",
                default = "custom",
                options = [
                    schema.Option(display = "Use Custom Location Below", value = "custom"),
                    schema.Option(display = "Los Angeles, CA", value = "losangeles"),
                    schema.Option(display = "Chicago, IL (Windy City)", value = "chicago"),
                    schema.Option(display = "Beijing, China", value = "beijing"),
                    schema.Option(display = "New Delhi, India", value = "newdelhi"),
                    schema.Option(display = "Mexico City, Mexico", value = "mexicocity"),
                    schema.Option(display = "Reykjavik, Iceland", value = "reykjavik"),
                ],
            ),
            schema.Location(
                id = "location",
                name = "Custom Location",
                desc = "Location (when 'Use Custom Location Below' is selected).",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "hide_text",
                name = "Hide Text Overlay",
                desc = "Hide AQI metric and location text overlay for pure artwork mode.",
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
                    schema.Option(display = "Clean Breeze", value = "clean_breeze"),
                    schema.Option(display = "Moderate Haze", value = "moderate_haze"),
                    schema.Option(display = "Unhealthy Smog", value = "unhealthy_smog"),
                    schema.Option(display = "Gusty Gale", value = "gusty_gale"),
                ],
            ),
        ],
    )
