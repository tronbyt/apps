"""
Applet: Antarctic Ice Series
Summary: Kinetic polar glacial art
Description: A kinetic glacial artwork depicting a floating iceberg. Over 24 hours, the iceberg gradually melts in height, shedding ice chunks into the polar ocean with dynamic water splash ripples. Resets to full mass at midnight. Inspired by BREAKFAST's polar artwork.
Author: brombomb
"""

load("http.star", "http")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

POLAR_STATIONS = {
    "mcmurdo": {"name": "McMurdo Station", "lat": -77.846, "lng": 166.676, "timezone": "Antarctica/McMurdo"},
    "southpole": {"name": "South Pole", "lat": -90.000, "lng": 0.000, "timezone": "Antarctica/South_Pole"},
    "palmer": {"name": "Palmer Station", "lat": -64.774, "lng": -64.053, "timezone": "Antarctica/Palmer"},
    "vostok": {"name": "Vostok Station", "lat": -78.464, "lng": 106.837, "timezone": "Antarctica/Vostok"},
    "casey": {"name": "Casey Station", "lat": -66.282, "lng": 110.528, "timezone": "Antarctica/Casey"},
}

HEX_CHARS = "0123456789abcdef"

# Polar Ice & Ocean Color Palette LUT (RGB tuples)
COLOR_SKY_DEEP = (5, 12, 30)
COLOR_SKY_HORIZON = (23, 59, 92)
COLOR_AURORA_GREEN = (6, 214, 160)

COLOR_ICE_SUNLIT = (255, 255, 255)
COLOR_ICE_PEAK = (224, 247, 250)
COLOR_ICE_MID = (178, 235, 242)
COLOR_ICE_SHADOW = (77, 208, 225)
COLOR_ICE_SUBMERGED = (0, 119, 182)

COLOR_WATER_SURFACE = (0, 180, 216)
COLOR_WATER_RIPPLE = (144, 224, 239)
COLOR_WATER_MID = (2, 62, 138)
COLOR_WATER_DEEP = (3, 4, 94)

def hash_seed(text):
    h = 0
    for i in range(len(text)):
        h = (h * 31 + ord(text[i])) % 1000003
    return h

def pseudo_rand(x, y, seed):
    v = math.sin(float(x) * 12.9898 + float(y) * 78.233 + float(seed) * 43.123) * 43758.5453
    return v - math.floor(v)

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
    if t <= 0.0:
        return rgb1
    if t >= 1.0:
        return rgb2
    return (
        int(rgb1[0] + (rgb2[0] - rgb1[0]) * t),
        int(rgb1[1] + (rgb2[1] - rgb1[1]) * t),
        int(rgb1[2] + (rgb2[2] - rgb1[2]) * t),
    )

def get_polar_data(config):
    demo_mode = config.get("demo_mode", "live")
    if demo_mode == "full_morning":
        return -28.0, 15.0, 0.02, "McMurdo"
    if demo_mode == "midday_melt":
        return -22.0, 18.0, 0.50, "McMurdo"
    if demo_mode == "evening_thaw":
        return -12.0, 25.0, 0.85, "McMurdo"
    if demo_mode == "midnight_reset":
        return -35.0, 10.0, 0.99, "McMurdo"

    station_key = config.get("station", "mcmurdo")
    st = POLAR_STATIONS.get(station_key, POLAR_STATIONS["mcmurdo"])
    lat = st["lat"]
    lng = st["lng"]
    station_name = st["name"].split()[0]
    tz = st.get("timezone", "UTC")

    url = "https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&current=temperature_2m,wind_speed_10m" % (lat, lng)
    res = http.get(url, ttl_seconds = 1800)

    temp_c = -32.0
    wind_spd = 18.0

    if res.status_code == 200:
        body = res.json()
        curr = body.get("current", {})
        if curr.get("temperature_2m") != None:
            temp_c = float(curr.get("temperature_2m"))
        if curr.get("wind_speed_10m") != None:
            wind_spd = float(curr.get("wind_speed_10m"))

    # 24-hour diurnal melt ratio (0.0 at midnight 00:00 -> 1.0 at 23:59 -> resets at 00:00)
    now = time.now().in_location(tz)
    secs_today = now.hour * 3600 + now.minute * 60 + now.second
    melt_ratio = secs_today / 86400.0

    return temp_c, wind_spd, melt_ratio, station_name

def main(config):
    width, height = canvas.size()
    scale = 2 if canvas.is2x() else 1

    temp_c, wind_spd, melt_ratio, station_name = get_polar_data(config)
    hide_text = config.bool("hide_text")

    station_seed = hash_seed(station_name)

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

    # Iceberg height melts gradually across 24 hours (100% height at 00:00 -> 0% height at 23:59 -> resets at 00:00)
    ice_scale = math.pow(max(0.02, 1.0 - melt_ratio), 0.75)
    keel_scale = math.pow(max(0.02, 1.0 - melt_ratio), 0.50)
    ice_percent = int(ice_scale * 100)

    frames = []
    px_step = 2 * scale

    cols = width // px_step
    rows = height // px_step
    waterline = int(rows * 0.56)

    # 1. Solid Iceberg Height Profile per Column (Gradually melts in height over 24h)
    top_y = [rows + 1.0] * cols
    sub_y = [-1.0] * cols

    for c in range(cols):
        c_norm = (c / float(cols)) * 64.0

        # Multi-peaked iceberg geometry
        dx1 = (c_norm - 30.0) / 18.0
        h1 = max(0.0, 1.0 - dx1 * dx1) * 14.0

        dx2 = (c_norm - 44.0) / 12.0
        h2 = max(0.0, 1.0 - dx2 * dx2) * 8.5

        dx3 = (c_norm - 16.0) / 10.0
        h3 = max(0.0, 1.0 - dx3 * dx3) * 6.5

        h_total = max(h1, max(h2, h3))
        if h_total > 0.0:
            facet_noise = math.sin(c_norm * 0.9 + pseudo_rand(c, 0, station_seed) * 2.0) * 0.7
            h_total = max(0.5, h_total + facet_noise)

        h_melted = h_total * ice_scale
        if h_melted > 0.3:
            top_y[c] = waterline - h_melted
            sub_y[c] = waterline + (h_melted * 0.40 * keel_scale)

    for f in range(num_frames):
        phase = (f / float(num_frames)) * 2.0 * math.pi
        cycle_step = num_frames // 5
        half_cycle = num_frames // 2

        # 2. Shedding Ice Particles falling from the iceberg surface into water
        shed_drops = []
        ripple_impacts = []

        if melt_ratio > 0.05:
            for k in range(5):
                k_seed = station_seed + k * 17
                x_spawn = int(14 + pseudo_rand(k, 1, k_seed) * 36)
                y_spawn = int(top_y[min(cols - 1, max(0, x_spawn))])

                if y_spawn < waterline:
                    fall_progress = ((f + k * cycle_step) % half_cycle) / float(half_cycle)
                    y_fall = int(y_spawn + fall_progress * (waterline - y_spawn))
                    x_fall = int(x_spawn + math.sin(fall_progress * math.pi + k) * 1.2)

                    if y_fall < waterline:
                        shed_drops.append((x_fall, y_fall))
                    else:
                        ripple_impacts.append((x_fall, fall_progress))

        row_children = []

        for r in range(rows):
            col_boxes = []
            for c in range(cols):
                is_shed_drop = False
                for (sx, sy) in shed_drops:
                    if c == sx and r == sy:
                        is_shed_drop = True

                # 1. Sky Region & Solid Iceberg (above waterline)
                if r < waterline:
                    t_sky = r / float(waterline)
                    sky_rgb = lerp_rgb(COLOR_SKY_DEEP, COLOR_SKY_HORIZON, t_sky)

                    # Aurora shimmer in upper sky
                    if r < waterline // 2:
                        aurora_wave = (math.sin(phase + c * 0.20 + r * 0.15) + 1.0) / 2.0
                        if aurora_wave > 0.75:
                            sky_rgb = lerp_rgb(sky_rgb, COLOR_AURORA_GREEN, (aurora_wave - 0.75) * 0.35)

                    if is_shed_drop:
                        # Falling shedding ice crystal block
                        col_boxes.append(render.Box(width = px_step, height = px_step, color = rgb_to_hex(COLOR_ICE_PEAK)))
                    elif r >= top_y[c]:
                        # Solid ice facet structure (No holes!)
                        h_factor = (waterline - r) / float(waterline - top_y[c] + 0.1)
                        if c < cols // 2:
                            ice_rgb = lerp_rgb(COLOR_ICE_MID, COLOR_ICE_SUNLIT, h_factor)
                            if h_factor > 0.8:
                                ice_rgb = COLOR_ICE_PEAK
                        else:
                            ice_rgb = lerp_rgb(COLOR_ICE_SHADOW, COLOR_ICE_MID, h_factor)

                        col_boxes.append(render.Box(width = px_step, height = px_step, color = rgb_to_hex(ice_rgb)))
                    else:
                        # Sky background
                        col_boxes.append(render.Box(width = px_step, height = px_step, color = rgb_to_hex(sky_rgb)))

                    # 2. Ocean Water Region & Water Ripples (below waterline)
                else:
                    t_ocean = (r - waterline) / float(rows - waterline)

                    # Ocean wave dynamics driven by wind speed
                    wave_offset = math.sin(phase * (wind_spd / 15.0) + c * 0.25 + r * 0.15) * 0.15
                    water_rgb = lerp_rgb(COLOR_WATER_SURFACE, COLOR_WATER_DEEP, t_ocean + wave_offset)

                    # Dynamic water splash ripples from falling ice shed impacts
                    ripple_intensity = 0.0
                    for (ix, i_prog) in ripple_impacts:
                        dist = abs(c - ix)
                        if dist < 6:
                            r_wave = math.sin((dist * 0.8) - (phase * 3.0)) * math.exp(-dist * 0.35)
                            if r_wave > 0.0:
                                ripple_intensity += r_wave * (1.0 - i_prog * 0.5)

                    if ripple_intensity > 0.20 and r < waterline + 3:
                        water_rgb = lerp_rgb(water_rgb, COLOR_WATER_RIPPLE, min(0.85, ripple_intensity))

                    if r <= sub_y[c]:
                        # Submerged iceberg keel
                        rel_depth = (r - waterline) / float(sub_y[c] - waterline + 0.1)
                        keel_rgb = lerp_rgb(COLOR_ICE_SHADOW, COLOR_ICE_SUBMERGED, rel_depth)
                        pixel_rgb = lerp_rgb(water_rgb, keel_rgb, 0.65)
                        col_boxes.append(render.Box(width = px_step, height = px_step, color = rgb_to_hex(pixel_rgb)))
                    else:
                        # Polar ocean water with splash ripples
                        col_boxes.append(render.Box(width = px_step, height = px_step, color = rgb_to_hex(water_rgb)))

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

            disp_str = "%s Ice %d%%" % (disp_temp, ice_percent)
            font = "terminus-12" if scale == 2 else "tom-thumb"
            bar_h = 14 if scale == 2 else 8
            bar_y = height - bar_h

            char_w = 6 if scale == 2 else 4
            vis_len = len(disp_str.replace("°", "o"))
            metric_w = vis_len * char_w
            gap_w = 3 * scale
            left_pad = 2 * scale
            avail_w = width - left_pad - metric_w - gap_w
            if avail_w < 10 * scale:
                avail_w = 10 * scale

            loc_w = len(station_name) * char_w
            if loc_w <= avail_w:
                loc_child = render.Text(content = station_name, font = font, color = "#eef4f8")
            else:
                max_scroll = loc_w - avail_w + (14 * scale)
                scroll_x = int((f / float(num_frames)) * max_scroll)
                loc_child = render.Box(
                    width = avail_w,
                    height = bar_h,
                    child = render.Padding(
                        pad = (-scroll_x, 0, 0, 0),
                        child = render.Text(content = station_name, font = font, color = "#eef4f8"),
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
                                    render.Text(content = disp_str, font = font, color = "#8da9c4"),
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
                id = "station",
                name = "Antarctic Station",
                desc = "Select Antarctic polar station.",
                icon = "snowflake",
                default = "mcmurdo",
                options = [
                    schema.Option(display = "McMurdo Station", value = "mcmurdo"),
                    schema.Option(display = "Amundsen-Scott South Pole", value = "southpole"),
                    schema.Option(display = "Palmer Station", value = "palmer"),
                    schema.Option(display = "Vostok Station", value = "vostok"),
                    schema.Option(display = "Casey Station", value = "casey"),
                ],
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
                desc = "Select a preset scenario for testing diurnal iceberg melt state.",
                icon = "flask",
                default = "live",
                options = [
                    schema.Option(display = "Live 24h Melt Cycle", value = "live"),
                    schema.Option(display = "00:00 Morning (Full Iceberg)", value = "full_morning"),
                    schema.Option(display = "12:00 Midday (50% Melted)", value = "midday_melt"),
                    schema.Option(display = "20:00 Evening (85% Melted)", value = "evening_thaw"),
                    schema.Option(display = "23:59 Midnight (Pre-Reset)", value = "midnight_reset"),
                ],
            ),
        ],
    )
