"""
Applet: CycleCast
Summary: Weather Data for Cyclists
Description: Hourly cycling weather with animated wind, validated forecasts, and bounded caching.
Author: Robert Ison
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/cloud_icon.png", CLOUD_ICON_ASSET = "file")
load("images/directional_arrow.png", DIRECTIONAL_ARROW_ASSET = "file")
load("images/flag_base.png", FLAG_BASE_ASSET = "file")
load("images/moon_0.png", MOON_0_ASSET = "file")
load("images/moon_1.png", MOON_1_ASSET = "file")
load("images/moon_2.png", MOON_2_ASSET = "file")
load("images/moon_3.png", MOON_3_ASSET = "file")
load("images/moon_4.png", MOON_4_ASSET = "file")
load("images/moon_5.png", MOON_5_ASSET = "file")
load("images/moon_6.png", MOON_6_ASSET = "file")
load("images/moon_7.png", MOON_7_ASSET = "file")
load("images/rain_icon.png", RAIN_ICON_ASSET = "file")
load("images/sun_icon.png", SUN_ICON_ASSET = "file")
load("images/windrose_icon.png", WINDROSE_ICON_ASSET = "file")
load("images/windsock_1.png", WINDSOCK_1_ASSET = "file")
load("images/windsock_2.png", WINDSOCK_2_ASSET = "file")
load("images/windsock_3.png", WINDSOCK_3_ASSET = "file")
load("images/windsock_4.png", WINDSOCK_4_ASSET = "file")
load("images/windsock_5.png", WINDSOCK_5_ASSET = "file")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("sunrise.star", "sunrise")
load("time.star", "time")

CLOUD_ICON = CLOUD_ICON_ASSET.readall()
DIRECTIONAL_ARROW = DIRECTIONAL_ARROW_ASSET.readall()
FLAG_BASE = FLAG_BASE_ASSET.readall()
RAIN_ICON = RAIN_ICON_ASSET.readall()
SUN_ICON = SUN_ICON_ASSET.readall()
WINDROSE_ICON = WINDROSE_ICON_ASSET.readall()

WINDSOCKS = [
    WINDSOCK_1_ASSET.readall(),
    WINDSOCK_2_ASSET.readall(),
    WINDSOCK_3_ASSET.readall(),
    WINDSOCK_4_ASSET.readall(),
    WINDSOCK_5_ASSET.readall(),
]
MOON_ICONS = [
    MOON_0_ASSET.readall(),
    MOON_1_ASSET.readall(),
    MOON_2_ASSET.readall(),
    MOON_3_ASSET.readall(),
    MOON_4_ASSET.readall(),
    MOON_5_ASSET.readall(),
    MOON_6_ASSET.readall(),
    MOON_7_ASSET.readall(),
]

DEFAULT_LOCATION = '{"lat":"28.53933","lng":"-81.38325","timezone":"America/New_York","description":"Orlando, FL, USA"}'
API_URL = "https://api.open-meteo.com/v1/forecast"
REFRESH_SECONDS = 3600
ERROR_RETRY_SECONDS = 900
MAX_FALLBACK_AGE = 3 * 3600
STATE_TTL = 24 * 3600

FIELDS = [
    "temperature_2m",
    "apparent_temperature",
    "wind_speed_10m",
    "wind_gusts_10m",
    "wind_direction_10m",
    "precipitation",
    "precipitation_probability",
    "relative_humidity_2m",
    "cloud_cover",
    "uv_index",
    "is_day",
]
REQUIRED_FIELDS = ["temperature_2m", "wind_speed_10m", "wind_direction_10m"]
SCROLL_OPTIONS = [
    schema.Option(display = "Slow Scroll", value = "60"),
    schema.Option(display = "Medium Scroll", value = "45"),
    schema.Option(display = "Fast Scroll", value = "30"),
]

def clean_text(value):
    return "" if value == None else " ".join(str(value).split())

def numeric(value):
    return type(value) == "int" or type(value) == "float"

def rounded_coordinate(value):
    return math.round(float(value) * 10) / 10.0

def get_delay(config):
    value = config.str("scroll", "60")
    return int(value) if value in ["60", "45", "30"] else 60

def scaled_image(src, scale):
    image = render.Image(src = src)
    if scale == 1:
        return image
    width, height = image.size()
    return render.Image(src = src, width = width * scale, height = height * scale)

def place(child, x, y, scale):
    return render.Padding(pad = (x * scale, y * scale, 0, 0), child = child)

def choose_color(value, thresholds, colors):
    if value == None:
        return "#666666"
    for index in range(len(thresholds)):
        if value <= thresholds[index]:
            return colors[index]
    return colors[-1]

def uv_value(value):
    return None if value == None else max(0, int(math.round(value)))

def uv_label(value):
    if value == None:
        return "Unavailable"
    labels = ["Low", "Moderate", "High", "Very High", "Extreme"]
    for index in range(4):
        if value <= [2, 5, 7, 10][index]:
            return labels[index]
    return labels[-1]

def uv_color(value):
    return choose_color(value, [2, 5, 7, 10], ["#8FC93A", "#FFD700", "#FF8C00", "#FF4500", "#800080"])

def temperature_color(value):
    return choose_color(value, [32, 50, 65, 75, 85, 95], ["#00A8E8", "#66D3FA", "#5BC8AC", "#8FC93A", "#FFD700", "#FF8C00", "#D62828"])

def humidity_color(value):
    return choose_color(value, [20, 40, 60, 75, 85, 95], ["#FF4500", "#FF8C00", "#FFD700", "#8FC93A", "#5BC8AC", "#66D3FA", "#00A8E8"])

def cardinal_direction(bearing):
    directions = ["North", "NNE", "NE", "ENE", "East", "ESE", "SE", "SSE", "South", "SSW", "SW", "WSW", "West", "WNW", "NW", "NNW"]
    return directions[int(((bearing % 360) + 11.25) // 22.5) % 16]

def moon_index(year, month, day):
    if month <= 2:
        year -= 1
        month += 12
    century = year // 100
    correction = 2 - century + century // 4
    julian = int(365.25 * (year + 4716)) + int(30.6001 * (month + 1)) + day + correction - 1524.5
    phase = ((julian - 2451550.1) % 29.53058867) / 29.53058867
    return int(phase * 8 + 0.5) % 8

def windsock_category(speed):
    for index in range(4):
        if speed <= [6.91, 10.36, 13.81, 17.26][index]:
            return index
    return 4

def animated_windsock(wind, gusts, scale):
    low = windsock_category(max(0, wind))
    high = windsock_category(
        max(wind, gusts if gusts != None else wind),
    )

    frames = []

    for _ in range(2):
        for _ in range(10):
            frames.append(scaled_image(WINDSOCKS[low], scale))

        for category in range(low, high + 1):
            for _ in range(2):
                frames.append(
                    scaled_image(WINDSOCKS[category], scale),
                )

        for category in range(high, low - 1, -1):
            for _ in range(6):
                frames.append(
                    scaled_image(WINDSOCKS[category], scale),
                )

    return render.Animation(children = frames)

def animated_arrow(direction, scale):
    direction = (direction + 180) % 360
    keyframes = [animation.Keyframe(
        percentage = 0.0,
        transforms = [animation.Rotate(direction)],
        curve = "ease_in_out",
    )]
    for step in range(1, 20):
        fraction = step / 20.0
        swing = (1.0 - fraction) * 10 * (1 if step % 2 else -1)
        keyframes.append(animation.Keyframe(
            percentage = fraction,
            transforms = [animation.Rotate(direction + swing)],
            curve = "ease_in_out",
        ))
    keyframes.append(animation.Keyframe(
        percentage = 1.0,
        transforms = [animation.Rotate(direction)],
        curve = "ease_in_out",
    ))
    return animation.Transformation(
        child = scaled_image(DIRECTIONAL_ARROW, scale),
        duration = 250,
        delay = 5,
        origin = animation.Origin(0.5, 0.5),
        keyframes = keyframes,
    )

def select_conditions(data, now):
    if type(data) != "dict" or data.get("error"):
        return None
    hourly = data.get("hourly")
    if type(hourly) != "dict":
        return None
    timestamps = hourly.get("time")
    if type(timestamps) != "list":
        return None
    selected = None
    selected_time = None
    for index in range(len(timestamps)):
        stamp = timestamps[index]
        if numeric(stamp) and stamp <= now:
            if selected_time == None or stamp > selected_time:
                selected = index
                selected_time = stamp
    if selected == None or now - selected_time > 3600:
        return None
    conditions = {"timestamp": selected_time}
    for field in FIELDS:
        values = hourly.get(field)
        value = None
        if type(values) == "list" and selected < len(values):
            candidate = values[selected]
            if numeric(candidate):
                value = candidate
        conditions[field] = value
    for field in REQUIRED_FIELDS:
        if conditions[field] == None:
            return None
    if conditions["wind_speed_10m"] < 0:
        return None
    conditions["wind_direction_10m"] %= 360
    return conditions

def weather_error(status):
    if status == 429:
        return "Weather API rate limited"
    if status == 400:
        return "Weather API rejected location or parameters"
    return "Weather API HTTP %s" % status

def get_weather(latitude, longitude, timezone, now):
    key = "cyclecast-v3-%s-%s-%s" % (latitude, longitude, timezone)
    stored = cache.get(key)
    state = json.decode(stored) if stored else {}
    if type(state) != "dict":
        state = {}
    data = state.get("data")
    fetched = state.get("fetched", 0)
    age = now - fetched
    previous = select_conditions(data, now)
    if now < state.get("next_check", 0):
        if previous != None and age >= 0 and age <= MAX_FALLBACK_AGE:
            return {"conditions": previous, "stale": age >= REFRESH_SECONDS or bool(state.get("error")), "error": state.get("error", "")}
        return {"conditions": None, "stale": False, "error": state.get("error") or "No recent weather available; retry pending"}

    # Best-effort reservation. Cache operations are not an atomic lock.
    state["next_check"] = now + ERROR_RETRY_SECONDS
    state["error"] = "Weather refresh interrupted"
    cache.set(key, json.encode(state), ttl_seconds = STATE_TTL)
    response = http.get(
        url = API_URL,
        params = {
            "latitude": str(latitude),
            "longitude": str(longitude),
            "timezone": timezone,
            "timeformat": "unixtime",
            "forecast_days": "2",
            "hourly": ",".join(FIELDS),
            "wind_speed_unit": "mph",
            "temperature_unit": "fahrenheit",
            "precipitation_unit": "mm",
        },
        ttl_seconds = 300,
    )
    error = ""
    if response.status_code == 200:
        fresh = response.json()
        conditions = select_conditions(fresh, now)
        if conditions != None:
            state = {"data": fresh, "fetched": now, "next_check": now + REFRESH_SECONDS, "error": ""}
            cache.set(key, json.encode(state), ttl_seconds = STATE_TTL)
            return {"conditions": conditions, "stale": False, "error": ""}
        error = "Weather response missing current-hour coverage or required fields"
    else:
        error = weather_error(response.status_code)
    state["error"] = error
    cache.set(key, json.encode(state), ttl_seconds = STATE_TTL)
    if previous != None and age >= 0 and age <= MAX_FALLBACK_AGE:
        return {"conditions": previous, "stale": True, "error": error}
    return {"conditions": None, "stale": False, "error": error}

def sample_conditions(now):
    return {
        "timestamp": now - now % 3600,
        "temperature_2m": 78.0,
        "apparent_temperature": 80.0,
        "wind_speed_10m": 9.0,
        "wind_gusts_10m": 18.0,
        "wind_direction_10m": 65.0,
        "precipitation": 0.0,
        "precipitation_probability": 15,
        "relative_humidity_2m": 58,
        "cloud_cover": 25,
        "uv_index": 4.6,
        "is_day": 1,
    }

def number_text(value, units = "", decimals = False):
    if value == None:
        return "unavailable"
    number = math.round(value * 10) / 10.0 if decimals else int(math.round(value))
    return "%s%s" % (number, units)

def hour_label(conditions, local_time, now, sample):
    if sample:
        return "Sample forecast"
    minutes = (local_time.hour * 60 + local_time.minute - int((now - conditions["timestamp"]) // 60)) % 1440
    hour = minutes // 60
    minute = minutes % 60
    minute_text = "0" + str(minute) if minute < 10 else str(minute)
    return "%s:%s %s forecast" % (hour % 12 or 12, minute_text, "AM" if hour < 12 else "PM")

def information_message(conditions, label):
    c = conditions
    uv = uv_value(c["uv_index"])
    return "%s: %s; feels like %s. Clouds %s; humidity %s. Precipitation probability %s; preceding-hour precipitation %s. UV %s (%s). Wind from %s at %s; gusts %s. Open-Meteo." % (
        label,
        number_text(c["temperature_2m"], "°F", True),
        number_text(c["apparent_temperature"], "°F", True),
        number_text(c["cloud_cover"], "%"),
        number_text(c["relative_humidity_2m"], "%"),
        number_text(c["precipitation_probability"], "%"),
        number_text(c["precipitation"], " mm", True),
        number_text(c["uv_index"], "", True),
        uv_label(uv),
        cardinal_direction(c["wind_direction_10m"]),
        number_text(c["wind_speed_10m"], " mph", True),
        number_text(c["wind_gusts_10m"], " mph", True),
    )

def info_box(items, value, color, x, y, scale):
    text = "--" if value == None else str(int(math.round(value)))
    items.append(place(render.Box(width = 14 * scale, height = 9 * scale, color = color), x, y, scale))
    items.append(place(render.Box(width = 10 * scale, height = 5 * scale, color = "#000000"), x + 2, y + 2, scale))
    label = render.Text(text, font = "5x8" if scale == 2 else "CG-pixel-3x5-mono", color = "#FFFFFF")
    width, height = label.size()
    left = x * scale + max(0, (14 * scale - width) // 2)
    top = y * scale + max(0, (9 * scale - height) // 2)
    items.append(render.Padding(pad = (left, top, 0, 0), child = label))

def display_error(config, message):
    if config.bool("hide_on_error", False):
        return []
    return render.Root(
        child = render.Column(children = [
            render.Text("CycleCast", font = "5x8", color = "#FF7300"),
            render.Marquee(width = canvas.width(), child = render.Text(message, font = "5x8", color = "#FFFF00")),
        ]),
        show_full_animation = True,
        delay = get_delay(config),
    )

def display_instructions(config):
    messages = [
        "CycleCast by Robert Ison",
        "Hourly forecast from Open-Meteo. Location is rounded to 0.1 degree before weather requests; this reduces precision but does not anonymize it.",
        "The arrow flutters around the wind's reported source direction. The windsock varies between sustained wind and gusts.",
        "Boxes show UV, temperature in °F, and humidity. Colors are separate indicators, not a riding-safety score. Cached fallback data is labeled. Enable Sample Mode for previews.",
    ]
    children = []
    offset = 0
    for message in messages:
        children.append(render.Marquee(width = canvas.width(), offset_start = offset, child = render.Text(message, font = "5x8", color = "#FFAA00")))
        offset += len(message) * 5
    return render.Root(child = render.Column(children = children), show_full_animation = True, delay = get_delay(config))

def main(config):
    if config.bool("instructions", False):
        return display_instructions(config)
    raw_location = config.str("location", "") or ""
    sample = config.bool("sample_mode", False) or not raw_location.strip()
    location = json.decode(raw_location if raw_location.strip() else DEFAULT_LOCATION)
    if type(location) != "dict":
        return display_error(config, "Invalid location setting")
    if not location.get("lat") or not location.get("lng") or not location.get("timezone"):
        return display_error(config, "Choose a location with a timezone")
    latitude = float(location["lat"])
    longitude = float(location["lng"])
    if latitude < -90 or latitude > 90 or longitude < -180 or longitude > 180:
        return display_error(config, "Latitude or longitude out of range")
    timezone = location["timezone"]
    instant = time.now()
    now = int(instant.unix)
    local_time = instant.in_location(timezone)
    if sample:
        result = {"conditions": sample_conditions(now), "stale": False, "error": ""}
    else:
        result = get_weather(rounded_coordinate(latitude), rounded_coordinate(longitude), timezone, now)
    c = result["conditions"]
    if c == None:
        return display_error(config, result["error"])

    scale = 2 if canvas.is2x() else 1

    # Always expose sample/fallback status, even if the info-bar toggle is off.
    show_bar = config.bool("show_info_bar", False) or sample or result["stale"]
    offset = 0 if show_bar else 5
    label = hour_label(c, local_time, now, sample)
    if result["stale"]:
        label = "CACHED FORECAST - " + label
    message = information_message(c, label)
    if result["error"]:
        message += " Refresh issue: " + result["error"] + "."
    items = []

    daytime = c["is_day"] == 1
    if sample:
        daytime = True
    elif abs(latitude) < 65:
        # Preserve precise-coordinate local sunrise/sunset calculations.
        # At high latitudes use the API's is_day to avoid polar-event errors.
        rise = sunrise.sunrise(latitude, longitude, local_time).in_location(timezone)
        setting = sunrise.sunset(latitude, longitude, local_time).in_location(timezone)
        daytime = local_time >= rise and local_time < setting
    if daytime:
        items.append(render.Box(width = 64 * scale, height = (26 if show_bar else 32) * scale, color = "#004764"))
        items.append(place(scaled_image(SUN_ICON, scale), 48, 0, scale))
    else:
        phase = 2 if sample else moon_index(local_time.year, local_time.month, local_time.day)
        items.append(place(scaled_image(MOON_ICONS[phase], scale), 43, -2, scale))

    if c["precipitation"] != None and c["precipitation"] > 0:
        items.append(place(scaled_image(RAIN_ICON, scale), 40, 6, scale))
    elif c["cloud_cover"] != None and c["cloud_cover"] > 15:
        items.append(place(scaled_image(CLOUD_ICON, scale), 40, 6, scale))
    items.append(place(animated_windsock(c["wind_speed_10m"], c["wind_gusts_10m"], scale), 0, 0, scale))
    if c["wind_speed_10m"] > 0:
        items.append(place(scaled_image(WINDROSE_ICON, scale), 16, 6 + offset, scale))
        items.append(place(animated_arrow(c["wind_direction_10m"], scale), 16, 6 + offset, scale))
    uv = uv_value(c["uv_index"])
    info_box(items, uv, uv_color(uv), 29, 1, scale)
    info_box(items, c["temperature_2m"], temperature_color(c["temperature_2m"]), 29, 17 + offset, scale)
    info_box(items, c["relative_humidity_2m"], humidity_color(c["relative_humidity_2m"]), 49, 17 + offset, scale)
    if show_bar:
        marquee = render.Marquee(width = 64 * scale, child = render.Text(message, font = "5x8" if scale == 2 else "CG-pixel-3x5-mono", color = "#FFFF00"))
        items.append(place(marquee, 0, 27, scale))
    else:
        items.append(place(scaled_image(FLAG_BASE, scale), 0, 24, scale))
    return render.Root(child = render.Stack(children = items), show_full_animation = True, delay = get_delay(config))

def get_schema():
    return schema.Schema(version = "1", fields = [
        schema.Toggle(id = "instructions", name = "Display Instructions", desc = "Show setup and interpretation notes.", icon = "book", default = False),
        schema.Location(id = "location", name = "Location", desc = "Weather location. With no location, a sample is displayed.", icon = "locationDot"),
        schema.Toggle(id = "sample_mode", name = "Sample Mode", desc = "Deterministic daytime weather for previews; no weather API calls.", icon = "eye", default = False),
        schema.Toggle(id = "show_info_bar", name = "Information Bar", desc = "Show forecast-hour and weather details. Automatically shown for samples and cached fallback data.", icon = "gear", default = False),
        schema.Toggle(id = "hide_on_error", name = "Hide on Error", desc = "Hide if no usable recent forecast is available.", icon = "eye", default = False),
        schema.Dropdown(id = "scroll", name = "Scroll", desc = "Frame delay; affects the marquee and windsock playback.", icon = "scroll", options = SCROLL_OPTIONS, default = "60"),
    ])
