load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# WMO weather codes by precipitation type
SNOW_CODES = [71, 73, 75, 77, 85, 86]
RAIN_CODES = [51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82, 95, 96, 99]

# Colors
SNOW_WHITE = "#FFFFFF"
DIM_GRAY = "#666666"
ERROR_RED = "#FF4444"

# Severity colors: light → moderate → heavy
SEVERITY_SNOW = ["#4488FF", "#FFAA00", "#FF4444"]  # blue, amber, red
SEVERITY_RAIN = ["#44AAFF", "#FFAA00", "#FF6633"]  # cyan, amber, orange-red

# Supporting text gray by severity (Lines 2-3)
GRAY_BY_SEVERITY = ["#777777", "#888888", "#999999"]  # light, moderate, heavy

CACHE_TTL = 1800  # 30 minutes

# Animation settings
ANIM_FRAMES = 32  # frames per event (~3.2s at 100ms delay)
ANIM_DELAY = 100  # ms per frame

# Particle colors (dim so they don't compete with text)
PARTICLE_SNOW = "#334466"
PARTICLE_RAIN = "#334455"

# Particle data: (x, y, speed, phase) - phase for sine wave offset
SNOW_PARTICLES = [
    (5, 2, 0.5, 0),
    (15, 22, 0.6, 2),
    (28, 8, 0.4, 1),
    (42, 28, 0.7, 3),
    (55, 14, 0.5, 4),
    (10, 18, 0.6, 5),
    (35, 5, 0.4, 2),
    (50, 25, 0.8, 1),
    (20, 12, 0.5, 3),
    (60, 20, 0.6, 0),
    (8, 28, 0.7, 4),
    (48, 10, 0.5, 2),
]
RAIN_PARTICLES = [
    (3, 1, 1.5, 0),
    (12, 9, 1.8, 0),
    (22, 17, 1.4, 0),
    (30, 5, 2.0, 0),
    (38, 25, 1.6, 0),
    (46, 13, 1.9, 0),
    (54, 21, 1.5, 0),
    (8, 29, 1.7, 0),
    (18, 7, 2.0, 0),
    (33, 15, 1.8, 0),
    (48, 3, 1.4, 0),
    (58, 23, 1.6, 0),
    (26, 11, 1.9, 0),
    (41, 19, 1.5, 0),
    (10, 25, 1.7, 0),
    (52, 8, 2.0, 0),
]

# Interval options: value is hours, forecast_days is API param
INTERVAL_OPTIONS = {
    "24": 1,
    "48": 2,
    "72": 3,
    "120": 5,
    "168": 7,
}

# ─── Pixel art icons (8x8 base64-encoded PNGs) ───

ICON_SNOW_LIGHT = """iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAGklEQVR4nGNgQAL/gYABF/iPBPAqwik5mAEA2w4T7X2e/9EAAAAASUVORK5CYII="""

ICON_SNOW_MEDIUM = """iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAJklEQVR4nGNgQAL/gYABF/iPBPAqwimJF6DrROGj243VLXhNIAQAAqw7xYlDpPsAAAAASUVORK5CYII="""

ICON_SNOW_HEAVY = """iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAKklEQVR4nGNggIJp06b9R8YMyABdEkURLkmsJuEE/4GAEBu7AC5BkhQCAMFiUXPU/Pu7AAAAAElFTkSuQmCC"""

ICON_RAIN_LIGHT = """iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAIklEQVR4nGNgQAIpq/7/Z8AFQJIuHf//41REUAFBKwYQAACc3Bfd0qQO/gAAAABJRU5ErkJggg=="""

ICON_RAIN_MEDIUM = """iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAJUlEQVR4nGNgQAIuHf//M+ACIEkYxqmIaIBiCrqRGFZRz15cAABYzx6vpJUFKQAAAABJRU5ErkJggg=="""

ICON_RAIN_HEAVY = """iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAKUlEQVR4nGNggIJp06b9R8YMyABdEkURLkmsJuEELh3//2OjiVdAkSkApxZTC1LzE2gAAAAASUVORK5CYII="""

# ─── Frog sprite (13x11 pixels) for All Clear screen ───

FROG_COLORS = {
    "D": "#2B7A2B",  # Dark green (body, head, outline)
    "G": "#45A845",  # Green (lighter body sides)
    "Y": "#E2BB38",  # Yellow (belly)
    "K": "#1E5E1E",  # Eyelid (heavy drooping lids)
    "E": "#CCCC55",  # Eye (exposed eye slit)
    "P": "#111111",  # Pupil dot
    "T": "#3D9E3D",  # Toe pads
}

# Frog sprite states (13 chars wide × 11 rows)
FROG_IDLE = [
    "000DDDDDDD000",
    "0KDDDDDDDDDK0",
    "0KKDDDDDDDKK0",
    "0EPEDDDDDEPE0",
    "0DDDDDDDDDDD0",
    "0DDDDDDDDDDD0",
    "DGGYYYYYYYGGD",
    "DGGYYYYYYYGGD",
    "DGGYYYYYYYGGD",
    "0DDDDDDDDDDD0",
    "0TT00DDD00TT0",
]

FROG_BLINK = [
    "000DDDDDDD000",
    "0KDDDDDDDDDK0",
    "0KKDDDDDDDKK0",
    "0KKDDDDDDDKK0",  # Lids shut
    "0DDDDDDDDDDD0",
    "0DDDDDDDDDDD0",
    "DGGYYYYYYYGGD",
    "DGGYYYYYYYGGD",
    "DGGYYYYYYYGGD",
    "0DDDDDDDDDDD0",
    "0TT00DDD00TT0",
]

FROG_PUFF = [
    "000DDDDDDD000",
    "0KDDDDDDDDDK0",
    "0KKDDDDDDDKK0",
    "0EPEDDDDDEPE0",
    "0DDDDDDDDDDD0",
    "0DDYYYYYYYDD0",  # Yellow creeps up
    "DGGYYYYYYYGGD",
    "DGGYYYYYYYGGD",
    "DGGYYYYYYYGGD",
    "0DDDDDDDDDDD0",
    "0TT00DDD00TT0",
]

def main(config):
    # Test mode: inject fake data for development/testing
    test_mode = config.get("test_mode")
    if test_mode:
        return handle_test_mode(test_mode)

    # Parse location from schema picker
    location = config.get("location")
    if not location:
        return render_no_location()

    loc = json.decode(location)
    lat = loc.get("lat")
    lng = loc.get("lng")
    tz = loc.get("timezone", "UTC")

    if not lat or not lng:
        return render_no_location()

    # Parse forecast interval
    interval_hours = int(config.get("interval", "48"))
    forecast_days = INTERVAL_OPTIONS.get(str(interval_hours), 2)

    forecast = get_forecast(lat, lng, tz, forecast_days)
    if not forecast:
        return render_error()

    events = parse_precip_events(forecast, interval_hours)

    if not events:
        return render_no_precip(interval_hours)

    return render_events(events)

# ─── Test mode ───

def handle_test_mode(mode):
    if mode == "snow_light":
        forecast = fake_snow_light()
        events = parse_precip_events(forecast, 48)
    elif mode == "snow_moderate":
        forecast = fake_snow_moderate()
        events = parse_precip_events(forecast, 48)
    elif mode == "snow_heavy":
        forecast = fake_snow_heavy()
        events = parse_precip_events(forecast, 48)
    elif mode == "snow_now":
        forecast = fake_snow_now()
        events = parse_precip_events(forecast, 48)
    elif mode == "rain_light":
        forecast = fake_rain_light()
        events = parse_precip_events(forecast, 48)
    elif mode == "rain_moderate":
        forecast = fake_rain_moderate()
        events = parse_precip_events(forecast, 48)
    elif mode == "rain_heavy":
        forecast = fake_rain_heavy()
        events = parse_precip_events(forecast, 48)
    elif mode == "rain_now":
        forecast = fake_rain_now()
        events = parse_precip_events(forecast, 48)
    elif mode == "mixed":
        forecast = fake_mixed_forecast()
        events = parse_precip_events(forecast, 72)
    elif mode == "clear":
        return render_no_precip(48)
    elif mode == "error":
        return render_error()
        # Legacy test modes (backwards compatibility)

    elif mode == "snow":
        forecast = fake_snow_moderate()
        events = parse_precip_events(forecast, 48)
    elif mode == "rain":
        forecast = fake_rain_moderate()
        events = parse_precip_events(forecast, 48)
    else:
        return render_error()

    if not events:
        return render_no_precip(48)
    return render_events(events)

def fake_snow_light():
    """Light snow - 6h away, dusting, 40%"""
    return {
        "hourly": {
            "time": ["2026-02-13T20:00", "2026-02-13T21:00", "2026-02-13T22:00"],
            "snowfall": [0.2, 0.3, 0.2],
            "rain": [0, 0, 0],
            "precipitation_probability": [30, 40, 35],
            "weathercode": [71, 71, 71],
        },
    }

def fake_snow_moderate():
    """Moderate snow - tomorrow, 3-6", 85%"""
    return {
        "hourly": {
            "time": [
                "2026-02-14T14:00",
                "2026-02-14T15:00",
                "2026-02-14T16:00",
                "2026-02-14T17:00",
                "2026-02-14T18:00",
                "2026-02-14T19:00",
            ],
            "snowfall": [0.8, 1.2, 1.5, 0.9, 0.6, 0.3],
            "rain": [0, 0, 0, 0, 0, 0],
            "precipitation_probability": [70, 80, 85, 80, 70, 60],
            "weathercode": [73, 73, 75, 73, 73, 71],
        },
    }

def fake_snow_heavy():
    """Heavy snow - 12h away, 12"+, 95%"""
    return {
        "hourly": {
            "time": [
                "2026-02-14T02:00",
                "2026-02-14T03:00",
                "2026-02-14T04:00",
                "2026-02-14T05:00",
                "2026-02-14T06:00",
                "2026-02-14T07:00",
                "2026-02-14T08:00",
                "2026-02-14T09:00",
                "2026-02-14T10:00",
            ],
            "snowfall": [1.5, 2.0, 2.5, 2.0, 1.8, 1.5, 1.2, 1.0, 0.8],
            "rain": [0, 0, 0, 0, 0, 0, 0, 0, 0],
            "precipitation_probability": [90, 95, 95, 95, 95, 90, 85, 80, 75],
            "weathercode": [75, 75, 75, 75, 75, 75, 73, 73, 73],
        },
    }

def fake_snow_now():
    """Snow happening now - ends at 8pm, 6-12", 100%"""
    return {
        "hourly": {
            "time": [
                "2026-02-13T13:00",
                "2026-02-13T14:00",
                "2026-02-13T15:00",
                "2026-02-13T16:00",
                "2026-02-13T17:00",
                "2026-02-13T18:00",
                "2026-02-13T19:00",
                "2026-02-13T20:00",
            ],
            "snowfall": [1.2, 1.5, 1.8, 1.5, 1.2, 0.9, 0.6, 0.3],
            "rain": [0, 0, 0, 0, 0, 0, 0, 0],
            "precipitation_probability": [100, 100, 100, 100, 95, 90, 80, 70],
            "weathercode": [75, 75, 75, 75, 73, 73, 71, 71],
        },
    }

def fake_rain_light():
    """Light rain - 2d away, light, 25%"""
    return {
        "hourly": {
            "time": ["2026-02-15T10:00", "2026-02-15T11:00", "2026-02-15T12:00"],
            "snowfall": [0, 0, 0],
            "rain": [0.1, 0.15, 0.1],
            "precipitation_probability": [20, 25, 20],
            "weathercode": [61, 61, 61],
        },
    }

def fake_rain_moderate():
    """Moderate rain - 18h away (tomorrow), moderate, 70%"""
    return {
        "hourly": {
            "time": [
                "2026-02-14T08:00",
                "2026-02-14T09:00",
                "2026-02-14T10:00",
                "2026-02-14T11:00",
                "2026-02-14T12:00",
            ],
            "snowfall": [0, 0, 0, 0, 0],
            "rain": [0.4, 0.6, 0.5, 0.4, 0.3],
            "precipitation_probability": [60, 70, 70, 65, 55],
            "weathercode": [63, 63, 63, 61, 61],
        },
    }

def fake_rain_heavy():
    """Heavy rain - 4h away (today), heavy, 90%"""
    return {
        "hourly": {
            "time": [
                "2026-02-13T18:00",
                "2026-02-13T19:00",
                "2026-02-13T20:00",
                "2026-02-13T21:00",
                "2026-02-13T22:00",
                "2026-02-13T23:00",
            ],
            "snowfall": [0, 0, 0, 0, 0, 0],
            "rain": [0.8, 1.2, 1.5, 1.0, 0.8, 0.5],
            "precipitation_probability": [85, 90, 90, 85, 80, 70],
            "weathercode": [65, 65, 65, 63, 63, 61],
        },
    }

def fake_rain_now():
    """Rain happening now - ends at 3pm, heavy, 100%"""
    return {
        "hourly": {
            "time": [
                "2026-02-13T11:00",
                "2026-02-13T12:00",
                "2026-02-13T13:00",
                "2026-02-13T14:00",
                "2026-02-13T15:00",
            ],
            "snowfall": [0, 0, 0, 0, 0],
            "rain": [1.0, 1.2, 1.0, 0.8, 0.5],
            "precipitation_probability": [100, 100, 100, 95, 85],
            "weathercode": [65, 65, 65, 63, 63],
        },
    }

def fake_mixed_forecast():
    return {
        "hourly": {
            "time": [
                "2026-02-13T08:00",
                "2026-02-13T09:00",
                "2026-02-13T10:00",
                "2026-02-13T11:00",
                "2026-02-13T12:00",
                "2026-02-13T13:00",
                "2026-02-13T14:00",
                "2026-02-13T15:00",
                "2026-02-13T16:00",
                # gap then snow the next day
                "2026-02-14T02:00",
                "2026-02-14T03:00",
                "2026-02-14T04:00",
                "2026-02-14T05:00",
                "2026-02-14T06:00",
                "2026-02-14T07:00",
                "2026-02-14T08:00",
                "2026-02-14T09:00",
                "2026-02-14T10:00",
            ],
            "snowfall": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0.8, 1.5, 2.0, 1.2, 0.5, 0.3, 0.1, 0, 0],
            "rain": [0.3, 0.8, 1.5, 2.0, 1.0, 0.5, 0.2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            "precipitation_probability": [50, 65, 80, 85, 70, 55, 40, 10, 0, 60, 75, 90, 80, 65, 50, 30, 10, 0],
            "weathercode": [61, 63, 65, 65, 63, 61, 51, 0, 0, 73, 75, 75, 73, 71, 71, 71, 0, 0],
        },
    }

# ─── API ───

def get_forecast(lat, lng, tz, forecast_days):
    cache_key = "sky_know_%s_%s_%d" % (lat, lng, forecast_days)
    cached = cache.get(cache_key)
    if cached:
        return json.decode(cached)

    url = (
        "https://api.open-meteo.com/v1/forecast" +
        "?latitude=%s&longitude=%s" % (lat, lng) +
        "&hourly=snowfall,rain,precipitation_probability,weathercode" +
        "&temperature_unit=fahrenheit" +
        "&timezone=%s" % tz +
        "&forecast_days=%d" % forecast_days
    )

    resp = http.get(url)
    if resp.status_code != 200:
        return None

    data = resp.json()
    cache.set(cache_key, json.encode(data), ttl_seconds = CACHE_TTL)
    return data

# ─── Event parsing ───

def parse_precip_events(forecast, hours_limit):
    """Parse hourly data into discrete precipitation events."""
    hourly = forecast.get("hourly", {})
    times = hourly.get("time", [])
    snowfall = hourly.get("snowfall", [])
    rain = hourly.get("rain", [])
    probs = hourly.get("precipitation_probability", [])
    codes = hourly.get("weathercode", [])

    limit = hours_limit if len(times) > hours_limit else len(times)

    # Classify each hour
    hours = []
    for i in range(limit):
        code = codes[i] if i < len(codes) else 0
        sf = snowfall[i] if i < len(snowfall) else 0
        rf = rain[i] if i < len(rain) else 0
        prob = probs[i] if i < len(probs) else 0

        precip_type = classify_hour(code, sf, rf)
        if precip_type:
            hours.append({
                "time": times[i],
                "type": precip_type,
                "snowfall": sf,
                "rain": rf,
                "probability": prob,
            })

    if not hours:
        return []

    # Group consecutive hours into events (allow 2-hour gaps)
    events = []
    current = new_event(hours[0])

    for i in range(1, len(hours)):
        h = hours[i]
        gap = hours_between(hours[i - 1]["time"], h["time"])

        if h["type"] == current["type"] and gap <= 3:
            extend_event(current, h)
        else:
            events.append(current)
            current = new_event(h)

    events.append(current)
    return events

def classify_hour(code, snowfall, rain):
    """Classify an hour as snow, rain, or None."""
    if code in SNOW_CODES or snowfall > 0:
        return "snow"
    if code in RAIN_CODES or rain > 0:
        return "rain"
    return None

def new_event(hour):
    return {
        "type": hour["type"],
        "start": hour["time"],
        "end": hour["time"],
        "max_prob": hour["probability"],
        "total_snow": hour["snowfall"],
        "total_rain": hour["rain"],
    }

def extend_event(event, hour):
    event["end"] = hour["time"]
    event["total_snow"] += hour["snowfall"]
    event["total_rain"] += hour["rain"]
    if hour["probability"] > event["max_prob"]:
        event["max_prob"] = hour["probability"]

def hours_between(time_a, time_b):
    """Estimate hour gap between two ISO time strings."""
    ha = int(time_a.split("T")[1].split(":")[0])
    hb = int(time_b.split("T")[1].split(":")[0])
    da = time_a.split("T")[0]
    db = time_b.split("T")[0]

    if da == db:
        return hb - ha

    # Different days — approximate
    return (24 - ha) + hb

# ─── Rendering ───

def render_events(events):
    """Render one or more precipitation events with particle animation."""
    frames = []
    for event in events:
        frames.extend(render_event_frames(event))

    return render.Root(
        delay = ANIM_DELAY,
        child = render.Animation(
            children = frames,
        ),
    )

def render_event_frames(event):
    """Generate animated frames for a single event with falling particles."""
    precip_type = event["type"]
    text_content = render_event_text(event)

    particles = SNOW_PARTICLES if precip_type == "snow" else RAIN_PARTICLES
    color = PARTICLE_SNOW if precip_type == "snow" else PARTICLE_RAIN

    frames = []
    for i in range(ANIM_FRAMES):
        particle_layer = render_particles(particles, color, i, precip_type)
        frames.append(
            render.Stack(
                children = [
                    particle_layer,
                    text_content,
                ],
            ),
        )
    return frames

def render_particles(particles, color, frame, precip_type):
    """Render a single frame of falling particles with variable speeds."""
    children = []
    for p in particles:
        base_x = p[0]
        base_y = p[1]
        speed = p[2]
        phase = p[3]

        # Calculate Y position with individual speed
        y = int((base_y + frame * speed)) % 32

        # Snow drifts with sine wave motion
        if precip_type == "snow":
            # Sine wave approximation using modulo (period ~16 frames)
            wave = ((frame + phase * 4) % 16) - 8  # Range: -8 to +7
            if wave < -4:
                drift = -1
            elif wave > 4:
                drift = 1
            else:
                drift = 0
            x = (base_x + drift) % 64
        else:
            # Rain falls straight down
            x = base_x

        # Snow: 1x1 dot, Rain: 1x2 streak
        h = 1 if precip_type == "snow" else 2

        children.append(
            render.Padding(
                pad = (x, y, 0, 0),
                child = render.Box(width = 1, height = h, color = color),
            ),
        )

    return render.Stack(children = children)

def render_event_text(event):
    """Render the static text overlay for an event (3-line hero countdown layout)."""
    precip_type = event["type"]
    accum = event["total_snow"] if precip_type == "snow" else event["total_rain"]
    severity = get_severity(precip_type, accum)
    icon = get_icon(precip_type, severity)
    header_color = get_severity_color(precip_type, severity)
    gray_color = GRAY_BY_SEVERITY[severity]
    label = "SNOW" if precip_type == "snow" else "RAIN"
    duration = format_duration(event["start"], event["end"])
    day_label = format_day_label(event["start"], event["end"], duration)
    prob_str = "%d%%" % event["max_prob"]
    accum_str = format_snow_accum(accum) if precip_type == "snow" else format_rain_accum(accum)

    return render.Column(
        expanded = True,
        main_align = "space_evenly",
        children = [
            # Line 1: Icon + TYPE + Countdown (severity colored)
            render.Row(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Image(src = base64.decode(icon), width = 8, height = 8),
                    render.Box(width = 2, height = 1),
                    render.Text("%s %s" % (label, duration), color = header_color, font = "tom-thumb"),
                ],
            ),
            # Line 2: Day label (dimmed gray)
            render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Text(day_label, color = gray_color, font = "tom-thumb"),
                ],
            ),
            # Line 3: Prob + Accum (dimmed gray)
            render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Text("%s %s" % (prob_str, accum_str), color = gray_color, font = "tom-thumb"),
                ],
            ),
        ],
    )

def render_frog_sprite(sprite_data):
    """Render a single frog sprite frame from string data."""
    children = []
    for y in range(len(sprite_data)):
        row = sprite_data[y]
        for x in range(len(row)):
            char = row[x]
            if char != "0":  # 0 = transparent
                color = FROG_COLORS.get(char, "#000000")
                children.append(
                    render.Padding(
                        pad = (x, y, 0, 0),
                        child = render.Box(width = 1, height = 1, color = color),
                    ),
                )
    return render.Stack(children = children)

def render_frog_animation():
    """Generate animated frog frames (idle → blink → idle → puff → idle)."""
    frames = []

    # Frames 0-49: Idle (5.0s)
    for _ in range(50):
        frames.append(render_frog_sprite(FROG_IDLE))

    # Frames 50-53: Blink (0.4s)
    for _ in range(4):
        frames.append(render_frog_sprite(FROG_BLINK))

    # Frames 54-73: Idle (2.0s)
    for _ in range(20):
        frames.append(render_frog_sprite(FROG_IDLE))

    # Frames 74-79: Throat Puff (0.6s)
    for _ in range(6):
        frames.append(render_frog_sprite(FROG_PUFF))

    # Frames 80-89: Idle (1.0s)
    for _ in range(10):
        frames.append(render_frog_sprite(FROG_IDLE))

    return frames

def render_no_precip(interval_hours):
    """Render All Clear screen with animated frog."""
    if interval_hours >= 24:
        days = interval_hours // 24
        label = "NEXT %dD" % days
    else:
        label = "NEXT %dHR" % interval_hours

    frog_frames = render_frog_animation()
    full_frames = []

    for frog in frog_frames:
        full_frames.append(
            render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Box(height = 2, width = 1),  # Top spacer
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        children = [frog],
                    ),
                    render.Box(height = 2, width = 1),  # Spacer between frog and text
                    render.Text("ALL CLEAR", color = "#445566", font = "tom-thumb"),
                    render.Text(label, color = "#334455", font = "tom-thumb"),
                ],
            ),
        )

    return render.Root(
        delay = 100,
        child = render.Animation(
            children = full_frames,
        ),
    )

def render_no_location():
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text("SKY KNOW", color = SEVERITY_SNOW[0], font = "tom-thumb"),
                render.Text("SET LOCATION", color = DIM_GRAY, font = "tom-thumb"),
            ],
        ),
    )

def render_error():
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text("SKY KNOW", color = ERROR_RED, font = "tom-thumb"),
                render.Text("API ERROR", color = ERROR_RED, font = "tom-thumb"),
            ],
        ),
    )

# ─── Icons ───

def get_severity(precip_type, accum):
    """Return severity level 0 (light), 1 (moderate), 2 (heavy)."""
    if precip_type == "snow":
        if accum < 1:
            return 0
        elif accum < 4:
            return 1
        else:
            return 2
    elif accum < 0.25:
        return 0
    elif accum < 1:
        return 1
    else:
        return 2

def get_severity_color(precip_type, severity):
    """Get color based on precip type and severity level."""
    if precip_type == "snow":
        return SEVERITY_SNOW[severity]
    return SEVERITY_RAIN[severity]

def get_icon(precip_type, severity):
    """Pick the right icon based on precip type and severity."""
    if precip_type == "snow":
        return [ICON_SNOW_LIGHT, ICON_SNOW_MEDIUM, ICON_SNOW_HEAVY][severity]
    return [ICON_RAIN_LIGHT, ICON_RAIN_MEDIUM, ICON_RAIN_HEAVY][severity]

# ─── Formatting helpers ───

def format_duration(start_str, end_str):
    """Format event duration like 'NOW', '2h', '1d3h' based on event length."""
    now = time.now()
    start = time.parse_time(start_str.replace("T", " "), format = "2006-01-02 15:04")
    end = time.parse_time(end_str.replace("T", " "), format = "2006-01-02 15:04")

    # Check if event is happening now
    if start <= now and end >= now:
        return "NOW"

    # Calculate duration of event
    duration = end - start
    hours = int(duration.hours)

    if hours < 1:
        return "1h"  # Minimum 1 hour
    elif hours < 24:
        return "%dh" % hours
    else:
        days = hours // 24
        remaining_hours = hours % 24
        if remaining_hours > 0:
            return "%dd%dh" % (days, remaining_hours)
        return "%dd" % days

def format_day_label(start_str, end_str, duration):
    """Format smart day label: Today/Tonight/Tomorrow/Wed or 'Thru 8pm' for NOW."""
    if duration == "NOW":
        # Show end time for currently happening events
        end_parts = end_str.split("T")
        end_hour = int(end_parts[1].split(":")[0])
        return "Thru %s" % format_hour(end_hour)

    now = time.now()
    start = time.parse_time(start_str.replace("T", " "), format = "2006-01-02 15:04")

    diff = start - now
    hours = int(diff.hours)

    # Parse start hour to determine if it's "tonight"
    start_parts = start_str.split("T")
    start_hour = int(start_parts[1].split(":")[0])

    if hours < 12:
        # Within 12 hours
        if start_hour >= 18 or start_hour < 6:
            return "Tonight"
        return "Today"
    elif hours < 36:
        # Tomorrow
        return "Tomorrow"
    else:
        # 2+ days out, use day abbreviation
        return start.format("Mon")

def format_time_window(start_str, end_str):
    start_parts = start_str.split("T")
    end_parts = end_str.split("T")

    start_date = start_parts[0]
    start_hour = int(start_parts[1].split(":")[0])
    end_date = end_parts[0]
    end_hour = int(end_parts[1].split(":")[0])

    start_day = get_day_abbr(start_date)
    end_day = get_day_abbr(end_date)

    start_fmt = "%s %s" % (start_day, format_hour(start_hour))
    end_fmt = "%s %s" % (end_day, format_hour(end_hour))

    return "%s-%s" % (start_fmt, end_fmt)

def format_hour(h):
    if h == 0:
        return "12am"
    elif h < 12:
        return "%dam" % h
    elif h == 12:
        return "12pm"
    else:
        return "%dpm" % (h - 12)

def get_day_abbr(date_str):
    t = time.parse_time(date_str + "T00:00:00Z", format = "2006-01-02T15:04:05Z")
    return t.format("Mon")

def format_snow_accum(total):
    if total < 0.5:
        return "Dusting"
    elif total < 1:
        return "<1\""
    elif total < 3:
        return "1-3\""
    elif total < 6:
        return "3-6\""
    elif total < 12:
        return "6-12\""
    else:
        return "12\"+"

def format_rain_accum(total):
    if total < 0.1:
        return "Trace"
    elif total < 0.25:
        return "Light"
    elif total < 0.5:
        return "Moderate"
    elif total < 1:
        return "Heavy"
    else:
        whole = int(total)
        frac = int((total - whole) * 10)
        return "%d.%d\"" % (whole, frac)

# ─── Schema ───

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for weather forecast",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "interval",
                name = "Forecast Window",
                desc = "How far ahead to check for precipitation",
                icon = "clock",
                default = "48",
                options = [
                    schema.Option(display = "24 hours", value = "24"),
                    schema.Option(display = "48 hours", value = "48"),
                    schema.Option(display = "3 days", value = "72"),
                    schema.Option(display = "5 days", value = "120"),
                    schema.Option(display = "7 days", value = "168"),
                ],
            ),
        ],
    )
