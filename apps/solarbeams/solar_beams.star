"""
Applet: Solar Beams
Summary: Sunlight kinetic art
Description: A kinetic visualization of how much sunlight is hitting the ground, inspired by Breakfast's "Under the Sun" flip-disc artwork. The beams of light shift in density and speed based on real-time solar irradiance.
Author: brombomb
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_LOCATION = {
    "lat": 40.7028,
    "lng": -73.9897,
    "locality": "Brooklyn, NY",
    "timezone": "America/New_York",
}

HEX_CHARS = "0123456789abcdef"
N_FRAMES = 32

# Preset Color Palettes for the Background Sky Gradient
PALETTE_DAYBREAK = [
    (0.00, "#1e293b"),
    (0.30, "#334155"),
    (0.55, "#64748b"),
    (0.75, "#fda4af"),
    (1.00, "#fef08a"),
]

PALETTE_MORNING_GLOW = [
    (0.00, "#0f172a"),
    (0.25, "#1e3a8a"),
    (0.50, "#0284c7"),
    (0.75, "#fbbf24"),
    (1.00, "#fef3c7"),
]

PALETTE_OCEAN = [
    (0.00, "#03071e"),
    (0.25, "#001e3d"),
    (0.50, "#004369"),
    (0.75, "#01949a"),
    (1.00, "#e5dcc5"),
]

PALETTE_MIDDAY_ZENITH = [
    (0.00, "#03071e"),
    (0.20, "#03045e"),
    (0.40, "#0077b6"),
    (0.65, "#00b4d8"),
    (0.85, "#90e0ef"),
    (1.00, "#fffbeb"),
]

PALETTE_GOLDEN = [
    (0.00, "#261105"),
    (0.25, "#6d2605"),
    (0.50, "#cf5600"),
    (0.75, "#ff9100"),
    (1.00, "#ffd166"),
]

PALETTE_SUNSET = [
    (0.00, "#3b1c3b"),
    (0.20, "#852b57"),
    (0.40, "#c9383f"),
    (0.55, "#f47035"),
    (0.70, "#9e3b6d"),
    (0.85, "#4e285a"),
    (1.00, "#1b1433"),
]

PALETTE_TWILIGHT = [
    (0.00, "#0a0d24"),
    (0.25, "#1e1b4b"),
    (0.50, "#4c1d95"),
    (0.75, "#86198f"),
    (1.00, "#c026d3"),
]

PALETTE_DARK = [
    (0.00, "#121620"),
    (0.50, "#181d2a"),
    (1.00, "#0a0c12"),
]

PALETTE_OVERCAST = [
    (0.00, "#1f242d"),
    (0.50, "#3a4150"),
    (1.00, "#151820"),
]

PALETTE_RAIN = [
    (0.00, "#0b1d3a"),
    (0.35, "#153a6b"),
    (0.70, "#1e5399"),
    (1.00, "#0f2b52"),
]

PALETTE_SNOW = [
    (0.00, "#475569"),
    (0.35, "#7895b2"),
    (0.70, "#bfdbfe"),
    (1.00, "#e2e8f0"),
]

PALETTE_FOG = [
    (0.00, "#334155"),
    (0.50, "#64748b"),
    (1.00, "#94a3b8"),
]

PALETTE_GALLERY = [
    (0.00, "#000000"),
    (0.50, "#050505"),
    (1.00, "#000000"),
]

PALETTE_CYBERPUNK = [
    (0.00, "#05051a"),
    (0.25, "#280659"),
    (0.50, "#6d0c74"),
    (0.75, "#c70039"),
    (1.00, "#11002c"),
]

BEAM_PALETTE_COLORS = [
    "#FFDF64",  # Metallic Gold (Under the Sun)
    "#FFF8E7",  # Warm Sunlight White
    "#FFA000",  # Radiant Amber
    "#00E5FF",  # Neon Cyan
    "#FF8DA1",  # Rose Gold
    "#FFFFFF",  # Pure White
]

# Track candidate definitions across the 32 rows:
# (base_y, base_len, speed_mult, init_x, min_intensity, is_double)
TRACK_DEFINITIONS = [
    # Ambient / Night (always active: serene rays)
    (3, 14, 1, 10, 0.00, False),
    (15, 18, 1, 36, 0.00, True),
    (27, 16, 1, 20, 0.00, False),

    # Low sun / Overcast (intensity >= 0.15, e.g. 150-250 W/m²)
    (7, 16, 1, 48, 0.15, False),
    (12, 20, 1, 4, 0.15, True),
    (20, 18, 1, 32, 0.15, False),
    (24, 14, 1, 16, 0.15, False),

    # Moderate sun / Partly sunny (intensity >= 0.35, e.g. 350-550 W/m²)
    (1, 12, 1, 24, 0.35, False),
    (9, 22, 1, 14, 0.35, True),
    (14, 24, 1, 42, 0.35, False),
    (18, 20, 1, 0, 0.35, True),
    (29, 14, 1, 30, 0.35, False),

    # Bright sun (intensity >= 0.60, e.g. 600-800 W/m²)
    (5, 18, 1, 38, 0.60, False),
    (11, 26, 1, 18, 0.60, True),
    (22, 22, 1, 52, 0.60, False),
    (25, 18, 1, 8, 0.60, True),

    # Peak midday sun (intensity >= 0.80, e.g. 800-1000+ W/m²)
    (8, 20, 1, 6, 0.80, False),
    (17, 28, 1, 28, 0.80, True),
    (21, 24, 1, 8, 0.80, False),
    (28, 16, 1, 46, 0.80, False),
]

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

def to_hex_digit(val):
    v = int(val)
    if v < 0:
        v = 0
    elif v > 255:
        v = 255
    return HEX_CHARS[v // 16] + HEX_CHARS[v % 16]

def rgb_to_hex(r, g, b):
    return "#" + to_hex_digit(r) + to_hex_digit(g) + to_hex_digit(b)

def hex_to_rgb(hex_color):
    h = hex_color[1:] if hex_color.startswith("#") else hex_color
    if len(h) == 3:
        h = h[0] + h[0] + h[1] + h[1] + h[2] + h[2]
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))

def lerp_color(c1, c2, t):
    rgb1 = hex_to_rgb(c1)
    rgb2 = hex_to_rgb(c2)
    r = rgb1[0] + (rgb2[0] - rgb1[0]) * t
    g = rgb1[1] + (rgb2[1] - rgb1[1]) * t
    b = rgb1[2] + (rgb2[2] - rgb1[2]) * t
    return rgb_to_hex(r, g, b)

def track_ease(t, ease_type):
    """Per-track kinetic easing curves."""
    if t <= 0.0:
        return 0.0
    if t >= 1.0:
        return 1.0
    if ease_type == 0:
        # Smoothstep
        return t * t * (3.0 - 2.0 * t)
    elif ease_type == 1:
        # Smootherstep
        return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
    else:
        # Kinetic quadratic ease blend
        if t < 0.5:
            return 2.0 * t * t
        else:
            t2 = t - 1.0
            return 1.0 - 2.0 * t2 * t2

def get_gradient_color(palette, t):
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
            return lerp_color(c1, c2, local_t)
    return palette[-1][1]

def make_beam_segment(x, y, seg_len, height, color, width):
    """Render a beam segment bounded strictly by screen width [0, width] without wrap-around."""
    if seg_len <= 0:
        return []

    # Left edge clipping: x < 0
    if x < 0:
        visible_len = seg_len + x
        if visible_len <= 0:
            return []
        start_x = 0
        seg_len = visible_len
    else:
        start_x = x

    # Right edge clipping: start_x + seg_len > width
    if start_x >= width:
        return []
    if start_x + seg_len > width:
        seg_len = width - start_x

    if seg_len <= 0:
        return []

    return [
        render.Padding(
            pad = (start_x, y, 0, 0),
            child = render.Box(width = seg_len, height = height, color = color),
        ),
    ]

def get_solar_data(config):
    demo_mode = config.get("demo_mode", "live")
    if demo_mode == "noon":
        return 1000.0, 0, 0
    if demo_mode == "moderate":
        return 600.0, 45, 1
    if demo_mode == "overcast":
        return 200.0, 95, 3
    if demo_mode == "rain":
        return 150.0, 90, 61
    if demo_mode == "snow":
        return 180.0, 85, 71
    if demo_mode == "fog":
        return 120.0, 75, 45
    if demo_mode == "dawn":
        return 50.0, 20, 0
    if demo_mode == "night":
        return 0.0, 10, 0

    loc = parse_location(config)
    lat = float(loc.get("lat", DEFAULT_LOCATION["lat"]))
    lng = float(loc.get("lng", DEFAULT_LOCATION["lng"]))

    url = "https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&current=is_day,cloud_cover,weather_code,direct_radiation,diffuse_radiation,shortwave_radiation" % (lat, lng)
    res = http.get(url, ttl_seconds = 900)
    if res.status_code == 200:
        data = res.json()
        curr = data.get("current", {})
        watts = float(curr.get("shortwave_radiation", 0.0))
        clouds = int(curr.get("cloud_cover", 0))
        wcode = int(curr.get("weather_code", curr.get("weathercode", 0)))
        return watts, clouds, wcode

    return 500.0, 30, 0

def get_solar_elevation(lat, lng, now):
    """Calculate sine of solar elevation angle accurately from UTC time and longitude."""
    utc_now = now.in_location("UTC")
    month = utc_now.month
    day = utc_now.day
    utc_hour = utc_now.hour + (utc_now.minute / 60.0) + (utc_now.second / 3600.0)

    days_before = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
    doy = days_before[month - 1] + day

    gamma = 2.0 * math.pi / 365.0 * (doy - 1 + (utc_hour - 12.0) / 24.0)
    decl = 0.006918 - 0.399912 * math.cos(gamma) + 0.070257 * math.sin(gamma)

    solar_hour = (utc_hour + (lng / 15.0)) % 24.0
    ha = (solar_hour - 12.0) * (15.0 * math.pi / 180.0)

    lat_rad = lat * math.pi / 180.0
    sin_elev = math.sin(lat_rad) * math.sin(decl) + math.cos(lat_rad) * math.cos(decl) * math.cos(ha)
    return sin_elev

def get_weather_overlay_color(weather_code, cloud_cover):
    # Fog: WMO codes 45, 48 - misty slate opacity layer
    if weather_code == 45 or weather_code == 48:
        return "#64748b66"

    # Snow: WMO codes 71-77, 85, 86 - crisp ice white opacity layer
    if (weather_code >= 71 and weather_code <= 77) or weather_code == 85 or weather_code == 86:
        return "#bfdbfe66"

    # Drizzle / Rain / Showers / Thunderstorm: WMO codes 51-67, 80-82, 95-99 - storm blue opacity layer
    if (weather_code >= 51 and weather_code <= 67) or (weather_code >= 80 and weather_code <= 82) or (weather_code >= 95 and weather_code <= 99):
        return "#0b1d3a77"

    # Overcast: WMO code 3 or cloud_cover >= 80 - dark cloudy grey opacity layer
    if weather_code == 3 or cloud_cover >= 80:
        return "#1f242d77"

    return None

def get_time_of_day_palette(config):
    loc = parse_location(config)
    lat = float(loc.get("lat", DEFAULT_LOCATION["lat"]))
    lng = float(loc.get("lng", DEFAULT_LOCATION["lng"]))

    now = time.now()
    sin_elev = get_solar_elevation(lat, lng, now)

    if sin_elev > 0.55:
        return PALETTE_MIDDAY_ZENITH
    elif sin_elev > 0.35:
        return PALETTE_OCEAN
    elif sin_elev > 0.18:
        return PALETTE_MORNING_GLOW
    elif sin_elev > 0.02:
        return PALETTE_DAYBREAK
    elif sin_elev > -0.10:
        return PALETTE_SUNSET
    elif sin_elev > -0.25:
        return PALETTE_TWILIGHT
    else:
        return PALETTE_DARK

def get_palette(config):
    bg_preset = config.get("bg_preset", "time_of_day_weather")
    if bg_preset == "time_of_day_weather" or bg_preset == "time_of_day":
        return get_time_of_day_palette(config)
    if bg_preset == "gallery_gold":
        return PALETTE_GALLERY
    if bg_preset == "daybreak":
        return PALETTE_DAYBREAK
    if bg_preset == "morning_glow":
        return PALETTE_MORNING_GLOW
    if bg_preset == "ocean":
        return PALETTE_OCEAN
    if bg_preset == "midday_zenith":
        return PALETTE_MIDDAY_ZENITH
    if bg_preset == "golden_hour":
        return PALETTE_GOLDEN
    if bg_preset == "sunset":
        return PALETTE_SUNSET
    if bg_preset == "twilight":
        return PALETTE_TWILIGHT
    if bg_preset == "dark":
        return PALETTE_DARK
    if bg_preset == "overcast":
        return PALETTE_OVERCAST
    if bg_preset == "rain":
        return PALETTE_RAIN
    if bg_preset == "snow":
        return PALETTE_SNOW
    if bg_preset == "fog":
        return PALETTE_FOG
    if bg_preset == "cyberpunk":
        return PALETTE_CYBERPUNK
    if bg_preset == "custom":
        top = config.get("bg_top_color", "#3b1c3b")
        bot = config.get("bg_bottom_color", "#1b1433")
        return [(0.0, top), (1.0, bot)]
    return PALETTE_SUNSET

def main(config):
    WIDTH, HEIGHT = canvas.size()
    SCALE = 2 if canvas.is2x() else 1

    # Retrieve solar irradiance and weather
    solar_watts, clouds, weather_code = get_solar_data(config)
    if solar_watts == None or solar_watts < 0.0:
        solar_watts = 0.0

    # Normalized intensity from 0.0 (night) to 1.0 (midday sun)
    intensity = solar_watts / 1000.0
    if intensity > 1.0:
        intensity = 1.0
    elif intensity < 0.0:
        intensity = 0.0

    # Speed scaling:
    # Normal (1.0x) = half of original current speed
    # Turtle (0.5x), Slow (0.75x), Normal (1.0x), Fast (1.5x), Rabbit (2.0x = original speed)
    speed_setting = config.get("speed", "normal")
    speed_map = {
        "turtle": 0.5,
        "slow": 0.75,
        "normal": 1.0,
        "fast": 1.5,
        "rabbit": 2.0,
    }
    speed_factor = speed_map.get(speed_setting, 1.0)

    # Serene night delay (450ms at night -> 130ms at peak midday)
    base_delay = int(450 - 320 * intensity)
    delay = int(base_delay / speed_factor)

    # Background gradient
    palette = get_palette(config)
    bg_rows = [get_gradient_color(palette, y / (HEIGHT - 1)) for y in range(HEIGHT)]
    bg_column = render.Column(
        children = [
            render.Box(width = WIDTH, height = 1, color = bg_rows[y])
            for y in range(HEIGHT)
        ],
    )

    # Weather alpha overlay layer if "Match Time of Day & Weather" is active
    bg_preset = config.get("bg_preset", "time_of_day_weather")
    weather_overlay_box = None
    if bg_preset == "time_of_day_weather":
        loc = parse_location(config)
        lat = float(loc.get("lat", DEFAULT_LOCATION["lat"]))
        lng = float(loc.get("lng", DEFAULT_LOCATION["lng"]))
        now = time.now()
        sin_elev = get_solar_elevation(lat, lng, now)

        if sin_elev > 0.02:
            ov_color = get_weather_overlay_color(weather_code, clouds)
            if ov_color != None:
                weather_overlay_box = render.Box(width = WIDTH, height = HEIGHT, color = ov_color)

    # Beam base colors & specular tip dimensions
    beam_color_base = config.get("beam_color", "#FFDF64")
    tip_len = 4 * SCALE
    beam_thickness = 1 * SCALE

    # Filter matching tracks based on solar intensity and density preference
    matching_tracks = [t for t in TRACK_DEFINITIONS if t[4] <= intensity]
    density_setting = config.get("density", "full")

    # Sparse: half density; Medium: 3/4 density; Full: 100%
    if density_setting == "sparse":
        max_tracks = len(matching_tracks) // 2
        if max_tracks < 3:
            max_tracks = 3
        matching_tracks = matching_tracks[:max_tracks]
    elif density_setting == "medium":
        max_tracks = (len(matching_tracks) * 3) // 4
        if max_tracks < 3:
            max_tracks = 3
        matching_tracks = matching_tracks[:max_tracks]

    motion_mode = config.get("motion", "eased_ltr")

    frames = []
    for f in range(N_FRAMES):
        beam_widgets = []
        for i, tr in enumerate(matching_tracks):
            base_y, base_len, _, init_x, _, is_double = tr

            # Scale layout parameters for 2x mode
            y1 = base_y * SCALE
            y2 = (base_y + 1) * SCALE
            length = base_len * SCALE

            # Distinct kinetic phase, duration, and pause per track
            phase_offset = ((i * 7 + (i * i) * 3) % 17) / 17.0
            track_ease_type = i % 3

            t_raw = ((f / float(N_FRAMES)) + phase_offset) % 1.0

            dir_mult = 1 if (i % 2 == 0) else -1
            center_x = (WIDTH - length) // 2
            start_off = -length
            end_off = WIDTH

            if motion_mode == "stationary":
                start_x = (init_x * SCALE) % WIDTH
            elif motion_mode == "flow_ltr":
                total_len = WIDTH + length
                start_x = start_off + int(t_raw * total_len)
            elif motion_mode == "flow" or motion_mode == "flow_dual":
                total_len = WIDTH + length
                if dir_mult > 0:
                    start_x = start_off + int(t_raw * total_len)
                else:
                    start_x = end_off - int(t_raw * total_len)
            elif motion_mode == "dual_pause":
                entry_end = 0.35
                exit_start = 0.65
                if dir_mult > 0:
                    if t_raw < entry_end:
                        m_frac = t_raw / entry_end
                        eased_m = track_ease(m_frac, track_ease_type)
                        start_x = start_off + int(eased_m * (center_x - start_off))
                    elif t_raw < exit_start:
                        start_x = center_x
                    else:
                        m_frac = (t_raw - exit_start) / (1.0 - exit_start)
                        eased_m = track_ease(m_frac, track_ease_type)
                        start_x = center_x + int(eased_m * (end_off - center_x))
                elif t_raw < entry_end:
                    m_frac = t_raw / entry_end
                    eased_m = track_ease(m_frac, track_ease_type)
                    start_x = end_off - int(eased_m * (end_off - center_x))
                elif t_raw < exit_start:
                    start_x = center_x
                else:
                    m_frac = (t_raw - exit_start) / (1.0 - exit_start)
                    eased_m = track_ease(m_frac, track_ease_type)
                    start_x = center_x - int(eased_m * (center_x - start_off))
            else:
                # Eased Left-to-Right with midpoint pause
                entry_end = 0.35
                exit_start = 0.65
                if t_raw < entry_end:
                    m_frac = t_raw / entry_end
                    eased_m = track_ease(m_frac, track_ease_type)
                    start_x = start_off + int(eased_m * (center_x - start_off))
                elif t_raw < exit_start:
                    start_x = center_x
                else:
                    m_frac = (t_raw - exit_start) / (1.0 - exit_start)
                    eased_m = track_ease(m_frac, track_ease_type)
                    start_x = center_x + int(eased_m * (end_off - center_x))

            # Metallic shimmer effect for specular beam tip
            shimmer = (f * 5 + i * 11) % 25
            r_c, g_c, b_c = hex_to_rgb(beam_color_base)
            tip_r = min(255, r_c + 40 + shimmer)
            tip_g = min(255, g_c + 40 + shimmer)
            tip_b = min(255, b_c + 40 + shimmer)
            accent_color = rgb_to_hex(tip_r, tip_g, tip_b)
            beam_color = beam_color_base

            # Render primary track beam
            if length > tip_len:
                body_len = length - tip_len
                beam_widgets.extend(make_beam_segment(start_x, y1, body_len, beam_thickness, beam_color, WIDTH))
                beam_widgets.extend(make_beam_segment(start_x + body_len, y1, tip_len, beam_thickness, accent_color, WIDTH))
            else:
                beam_widgets.extend(make_beam_segment(start_x, y1, length, beam_thickness, accent_color, WIDTH))

            # Render secondary offset track beam if double-layered
            if is_double:
                len2 = length - 3 * SCALE
                if len2 >= 4 * SCALE:
                    s2 = start_x + 2 * SCALE
                    if len2 > tip_len:
                        body_len2 = len2 - tip_len
                        beam_widgets.extend(make_beam_segment(s2, y2, body_len2, beam_thickness, beam_color, WIDTH))
                        beam_widgets.extend(make_beam_segment(s2 + body_len2, y2, tip_len, beam_thickness, accent_color, WIDTH))
                    else:
                        beam_widgets.extend(make_beam_segment(s2, y2, len2, beam_thickness, accent_color, WIDTH))

        base_layers = [bg_column]
        if weather_overlay_box != None:
            base_layers.append(weather_overlay_box)
        frame_children = base_layers + beam_widgets
        frames.append(render.Stack(children = frame_children))

    return render.Root(
        delay = delay,
        child = render.Animation(children = frames),
    )

def get_schema():
    bg_options = [
        schema.Option(display = "Match Time of Day & Weather", value = "time_of_day_weather"),
        schema.Option(display = "Match Time of Day Only", value = "time_of_day"),
        schema.Option(display = "Gallery Flip-Disc (Black & Gold)", value = "gallery_gold"),
        schema.Option(display = "Daybreak / Dawn", value = "daybreak"),
        schema.Option(display = "Morning Glow", value = "morning_glow"),
        schema.Option(display = "Ocean Sky (Mid-Morning)", value = "ocean"),
        schema.Option(display = "Midday Zenith (High Noon)", value = "midday_zenith"),
        schema.Option(display = "Golden Hour", value = "golden_hour"),
        schema.Option(display = "Sunset Horizon (Under the Sun)", value = "sunset"),
        schema.Option(display = "Twilight Dusk", value = "twilight"),
        schema.Option(display = "Dark Studio", value = "dark"),
        schema.Option(display = "Overcast Sky", value = "overcast"),
        schema.Option(display = "Rainy Slate", value = "rain"),
        schema.Option(display = "Snowy Frost", value = "snow"),
        schema.Option(display = "Misty Fog", value = "fog"),
        schema.Option(display = "Cyberpunk", value = "cyberpunk"),
        schema.Option(display = "Custom Gradient", value = "custom"),
    ]

    density_options = [
        schema.Option(display = "Full Density (Default)", value = "full"),
        schema.Option(display = "Medium Density", value = "medium"),
        schema.Option(display = "Sparse (Half Density)", value = "sparse"),
    ]

    speed_options = [
        schema.Option(display = "Turtle (.5x)", value = "turtle"),
        schema.Option(display = "Slow (.75x)", value = "slow"),
        schema.Option(display = "Normal (1x - Half Speed)", value = "normal"),
        schema.Option(display = "Fast (1.5x)", value = "fast"),
        schema.Option(display = "Rabbit (2x - Original Speed)", value = "rabbit"),
    ]

    motion_options = [
        schema.Option(display = "Left to Right Eased Pause", value = "eased_ltr"),
        schema.Option(display = "Continuous Flow (Left to Right)", value = "flow_ltr"),
        schema.Option(display = "Dual Sided Pause", value = "dual_pause"),
        schema.Option(display = "Continuous Flow (Dual Directional)", value = "flow"),
        schema.Option(display = "Stationary Rays", value = "stationary"),
    ]

    demo_options = [
        schema.Option(display = "Live Weather (Open-Meteo)", value = "live"),
        schema.Option(display = "Demo: Peak Midday Sun (1000 W/m²)", value = "noon"),
        schema.Option(display = "Demo: Partly Sunny (600 W/m²)", value = "moderate"),
        schema.Option(display = "Demo: Rainy Day (150 W/m²)", value = "rain"),
        schema.Option(display = "Demo: Snowy Day (180 W/m²)", value = "snow"),
        schema.Option(display = "Demo: Misty Fog (120 W/m²)", value = "fog"),
        schema.Option(display = "Demo: Overcast (200 W/m²)", value = "overcast"),
        schema.Option(display = "Demo: Twilight / Dawn (50 W/m²)", value = "dawn"),
        schema.Option(display = "Demo: Night / Moonbeams (0 W/m²)", value = "night"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "bg_preset",
                name = "Background Theme",
                desc = "Sky gradient color scheme",
                icon = "palette",
                default = "time_of_day_weather",
                options = bg_options,
            ),
            schema.Dropdown(
                id = "density",
                name = "Beam Density",
                desc = "Maximum active beams during peak sun",
                icon = "barsStaggered",
                default = "full",
                options = density_options,
            ),
            schema.Color(
                id = "beam_color",
                name = "Beam Color",
                desc = "Color of the solar beams of light",
                icon = "sun",
                default = "#FFDF64",
                palette = BEAM_PALETTE_COLORS,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Animation Speed",
                desc = "Overall motion speed multiplier",
                icon = "gauge",
                default = "normal",
                options = speed_options,
            ),
            schema.Dropdown(
                id = "motion",
                name = "Beam Motion",
                desc = "Kinetic movement behavior",
                icon = "sliders",
                default = "eased_ltr",
                options = motion_options,
            ),
            schema.Color(
                id = "bg_top_color",
                name = "Custom Top BG Color",
                desc = "Top color when Custom Gradient is selected",
                icon = "paintbrush",
                default = "#3B1C3B",
            ),
            schema.Color(
                id = "bg_bottom_color",
                name = "Custom Bottom BG Color",
                desc = "Bottom color when Custom Gradient is selected",
                icon = "paintbrush",
                default = "#1B1433",
            ),
            schema.Dropdown(
                id = "demo_mode",
                name = "Data Source / Demo Mode",
                desc = "Live weather data or preview sunlight levels",
                icon = "cloudSun",
                default = "live",
                options = demo_options,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for live solar radiation data",
                icon = "locationDot",
            ),
        ],
    )
