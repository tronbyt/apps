"""
Applet: Weather Clock With Date OG
Summary: Time and local weather
Description: Displays the current time alongside local weather conditions
fetched from OpenWeather or the National Weather Service.
Author: alustig
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/cloudy.png", CLOUDY_ASSET = "file")
load("images/foggy.png", FOGGY_ASSET = "file")
load("images/haily.png", HAILY_ASSET = "file")
load("images/moony.png", MOONY_ASSET = "file")
load("images/moonyish.png", MOONYISH_ASSET = "file")
load("images/rainy.png", RAINY_ASSET = "file")
load("images/sleety.png", SLEETY_ASSET = "file")
load("images/sleety2.png", SLEETY2_ASSET = "file")
load("images/snowy.png", SNOWY_ASSET = "file")
load("images/snowy2.png", SNOWY2_ASSET = "file")
load("images/sunny.png", SUNNY_ASSET = "file")
load("images/sunnyish.png", SUNNYISH_ASSET = "file")
load("images/thundery.png", THUNDERY_ASSET = "file")
load("images/tornady.png", TORNADY_ASSET = "file")
load("images/windy.png", WINDY_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

WEATHER_ICONS = {
    "cloudy.png": CLOUDY_ASSET.readall(),
    "foggy.png": FOGGY_ASSET.readall(),
    "haily.png": HAILY_ASSET.readall(),
    "moony.png": MOONY_ASSET.readall(),
    "moonyish.png": MOONYISH_ASSET.readall(),
    "rainy.png": RAINY_ASSET.readall(),
    "sleety.png": SLEETY_ASSET.readall(),
    "sleety2.png": SLEETY2_ASSET.readall(),
    "snowy.png": SNOWY_ASSET.readall(),
    "snowy2.png": SNOWY2_ASSET.readall(),
    "sunny.png": SUNNY_ASSET.readall(),
    "sunnyish.png": SUNNYISH_ASSET.readall(),
    "thundery.png": THUNDERY_ASSET.readall(),
    "tornady.png": TORNADY_ASSET.readall(),
    "windy.png": WINDY_ASSET.readall(),
}

# ── Constants ────────────────────────────────────────────────────────────

HUMIDITY_FONT = "5x8"
TEMP_FONT = "5x8"
TIME_FONT = "6x13"
DAY_FONT = "CG-pixel-3x5-mono"

DEFAULT_TIME_COLOR = "#FFFFFF"
DEFAULT_TEMP_COLOR = "#FFFFFF"
DEFAULT_HUMIDITY_COLOR = "#4499FF"  # blue
DAY_COLOR = "#888888"  # dim gray
NIGHT_DIM_COLOR = "#555555"
BLINK_DELAY_MS = 1000  # ms each frame is held; slower than the original 500ms

DEFAULT_LAT = "39.0"
DEFAULT_LNG = "-77.0"
DEFAULT_TZ = "America/New_York"

# ── Schema ───────────────────────────────────────────────────────────────

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                icon = "locationDot",
                desc = "Location for time and weather.",
            ),
            schema.Toggle(
                id = "is_24hour",
                name = "24 hour clock",
                icon = "clock",
                desc = "Enable for 24-hour time format.",
                default = False,
            ),
            schema.Color(
                id = "time_color",
                name = "Time color",
                icon = "palette",
                desc = "Change the color of the time.",
                default = DEFAULT_TIME_COLOR,
            ),
            schema.Dropdown(
                id = "weather_service",
                name = "Weather API Service",
                icon = "cloud",
                desc = "Select your preferred Weather API.",
                default = "nws",
                options = [
                    schema.Option(display = "National Weather Service (US only, no key needed)", value = "nws"),
                    schema.Option(display = "OpenWeather", value = "openweather"),
                ],
            ),
            schema.Text(
                id = "api_key",
                name = "API Key",
                icon = "key",
                desc = "OpenWeather API key (not needed for NWS).",
                default = "",
            ),
            schema.Dropdown(
                id = "unit_system",
                name = "System of measurement",
                icon = "ruler",
                desc = "Imperial or Metric units.",
                default = "imperial",
                options = [
                    schema.Option(display = "Imperial", value = "imperial"),
                    schema.Option(display = "Metric", value = "metric"),
                ],
            ),
            schema.Color(
                id = "temp_color",
                name = "Temperature color",
                icon = "palette",
                desc = "Color for temperature display.",
                default = DEFAULT_TEMP_COLOR,
            ),
            schema.Color(
                id = "humidity_color",
                name = "Humidity color",
                icon = "palette",
                desc = "Color for humidity display.",
                default = DEFAULT_HUMIDITY_COLOR,
            ),
            schema.Toggle(
                id = "show_temp_unit",
                name = "Show temperature unit",
                icon = "thermometer",
                desc = "Display °F or °C suffix.",
                default = True,
            ),
            schema.Toggle(
                id = "show_day_date",
                name = "Show day and date",
                icon = "calendar",
                desc = "Show the day of week and date next to the weather. When off, the weather is centered instead.",
                default = True,
            ),
            schema.Toggle(
                id = "blink_separator",
                name = "Blinking separator",
                icon = "gear",
                desc = "Blink the colon between hours and minutes.",
                default = True,
            ),
            schema.Toggle(
                id = "night_mode",
                name = "Night Mode",
                icon = "moon",
                desc = "Dim display and show only clock at night.",
                default = False,
            ),
            schema.Text(
                id = "night_start",
                name = "Night Mode Start",
                icon = "moon",
                desc = "24-hour format (HHmm), e.g. 2300.",
                default = "2300",
            ),
            schema.Text(
                id = "night_end",
                name = "Night Mode End",
                icon = "sun",
                desc = "24-hour format (HHmm), e.g. 0700.",
                default = "0700",
            ),
        ],
    )

# ── Main entry point ────────────────────────────────────────────────────

def main(config):
    location_str = config.get("location")
    if location_str:
        loc = json.decode(location_str)
    else:
        loc = {}
    lat = loc.get("lat", DEFAULT_LAT)
    lng = loc.get("lng", DEFAULT_LNG)
    timezone = loc.get("timezone", DEFAULT_TZ)

    is_24hour = config.bool("is_24hour") or False
    time_color = config.get("time_color") or DEFAULT_TIME_COLOR
    temp_color = config.get("temp_color") or DEFAULT_TEMP_COLOR
    humidity_color = config.get("humidity_color") or DEFAULT_HUMIDITY_COLOR
    blink = config.bool("blink_separator")
    if blink == None:
        blink = True
    night_mode = config.bool("night_mode") or False
    night_start = config.get("night_start") or "2300"
    night_end = config.get("night_end") or "0700"
    unit_system = config.get("unit_system") or "imperial"
    show_unit = config.bool("show_temp_unit")
    if show_unit == None:
        show_unit = True
    show_day_date = config.bool("show_day_date")
    if show_day_date == None:
        show_day_date = True

    now = time.now().in_location(timezone)

    if night_mode and is_night(now, night_start, night_end):
        return render_night_mode(now, is_24hour, blink)

    weather = get_weather(config, lat, lng, unit_system)

    frame_a = build_frame(now, is_24hour, time_color, temp_color, humidity_color, show_unit, unit_system, True, weather, show_day_date)
    if blink:
        frame_b = build_frame(now, is_24hour, time_color, temp_color, humidity_color, show_unit, unit_system, False, weather, show_day_date)
    else:
        frame_b = frame_a

    return render.Root(
        delay = BLINK_DELAY_MS,
        child = render.Animation(children = [frame_a, frame_b]),
    )

# ── Time display ─────────────────────────────────────────────────────────

def build_time_row(now, is_24hour, time_color, show_colon):
    if is_24hour:
        hour = now.hour
        ampm = ""
    else:
        hour = now.hour % 12
        if hour == 0:
            hour = 12
        ampm = " AM" if now.hour < 12 else " PM"

    hour_str = "%d" % hour
    minute_str = "%d" % now.minute
    if now.minute < 10:
        minute_str = "0" + minute_str

    return render.Row(
        main_align = "center",
        cross_align = "center",
        expanded = True,
        children = [
            build_digit_text(hour_str, TIME_FONT, time_color, {"0": custom_zero_time}),
            build_colon(time_color, show_colon),
            build_digit_text(minute_str, TIME_FONT, time_color, {"0": custom_zero_time}),
            render.Text(content = ampm, font = TIME_FONT, color = time_color),
        ],
    )

def build_colon(time_color, show_colon):
    # Two hand-drawn dots instead of the font's ":" glyph, which renders
    # as a cross-like shape at this resolution in some fonts.
    dot_color = time_color if show_colon else "#000000"
    dot = render.Box(width = 1, height = 1, color = dot_color)
    gap = render.Box(width = 2, height = 4)
    return render.Padding(
        pad = (1, 1, 1, 0),
        child = render.Column(
            cross_align = "center",
            children = [dot, gap, dot],
        ),
    )

# ── Widened "0" glyph ────────────────────────────────────────────────────
# The 5x8 font's "0" is only 3px wide (cols 1-3 of its 5px cell) while every
# other digit is 4px wide (cols 0-3), which makes it look thinner/misaligned.
# Hand-drawn 4px-wide replacement matching the 5x8 cell (5 wide x 8 tall,
# ink on rows 1-6) and reusing "8"'s column positions for a consistent look.
ZERO_GLYPH = [
    "00000",
    "01100",
    "10010",
    "10010",
    "10010",
    "10010",
    "01100",
    "00000",
]

def custom_zero(color):
    return build_glyph(ZERO_GLYPH, color)

# Hand-drawn "9" for the same 5x8 cell (5 wide x 8 tall, ink on rows 1-6).
NINE_GLYPH = [
    "00000",
    "01100",
    "10010",
    "10010",
    "01110",
    "00010",
    "01100",
    "00000",
]

def custom_nine(color):
    return build_glyph(NINE_GLYPH, color)

# The 6x13 time font inks digits on rows 2-10 (9 rows) of its 13-row cell,
# with a blank column on the right (col 5), matching the 5x8 font's layout
# style. This custom "0" is 6 wide x 13 tall so it drops in exactly like a
# normal render.Text digit.
TIME_ZERO_GLYPH = [
    "000000",
    "000000",
    "011100",
    "100010",
    "100010",
    "100010",
    "100010",
    "100010",
    "100010",
    "100010",
    "011100",
    "000000",
    "000000",
]

def custom_zero_time(color):
    return build_glyph(TIME_ZERO_GLYPH, color)

def build_glyph(glyph_rows, color):
    rows = []
    for pattern in glyph_rows:
        cells = []
        for i in range(len(pattern)):
            lit = pattern[i] == "1"
            cells.append(render.Box(width = 1, height = 1, color = color if lit else "#000000"))
        rows.append(render.Row(children = cells))
    return render.Column(children = rows)

def build_digit_text(s, font, color, overrides):
    # Renders each character individually so specific digits (per the
    # `overrides` dict, e.g. {"0": custom_zero}) can be swapped for widened
    # custom glyphs while every other character still uses the font.
    # Uses .codepoints() rather than indexing/len(), which are byte-based in
    # Starlark and would split multi-byte characters like "°".
    children = []
    for ch in s.codepoints():
        widget_fn = overrides.get(ch)
        if widget_fn:
            children.append(widget_fn(color))
        else:
            children.append(render.Text(content = ch, font = font, color = color))
    return render.Row(children = children)

# ── Weather row ──────────────────────────────────────────────────────────

def build_weather_row(weather, temp_color, humidity_color, show_unit, unit_system, now, show_day_date):
    temp_val = weather.get("temp")
    humidity = weather.get("humidity")
    condition = weather.get("condition", "cloudy")

    if temp_val == None:
        temp_str = "--"
        humidity_str = weather.get("description", "no key")

        # No API key means no real weather data — the "no key" placeholder
        # is already wide, so skip day/date regardless of the toggle to
        # avoid a cramped/ugly layout.
        show_day_date = False
    else:
        if show_unit:
            suffix = "F" if unit_system == "imperial" else "C"
            temp_str = "%d°%s" % (temp_val, suffix)
        else:
            temp_str = "%d" % temp_val
        humidity_str = "%d%%" % (humidity if humidity != None else 0)

    icon_key = condition_to_icon_key(condition, is_daytime(now))
    weather_icon = get_weather_icon(icon_key)

    weather_group = render.Row(
        children = [
            render.Padding(
                pad = (1, 1, 2, 0),
                child = weather_icon,
            ),
            render.Column(
                cross_align = "start",
                children = [
                    build_digit_text(temp_str, TEMP_FONT, temp_color, {"0": custom_zero, "9": custom_nine}),
                    build_digit_text(humidity_str, HUMIDITY_FONT, humidity_color, {"0": custom_zero, "9": custom_nine}),
                ],
            ),
        ],
    )

    if not show_day_date:
        return render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [weather_group],
        )

    day_str = now.format("Mon").upper()
    date_str = now.format("1/2")

    return render.Row(
        expanded = True,
        main_align = "start",
        cross_align = "center",
        children = [
            render.Box(width = 3, height = 1),
            weather_group,
            render.Box(width = 3, height = 1),
            render.Padding(
                pad = (0, 0, 1, 0),
                child = render.Column(
                    cross_align = "center",
                    children = [
                        render.Padding(
                            pad = (0, 0, 0, 0),
                            child = render.Text(content = day_str, font = DAY_FONT, color = DAY_COLOR),
                        ),
                        render.Padding(
                            pad = (0, 2, 0, 0),
                            child = render.Text(content = date_str, font = DAY_FONT, color = DAY_COLOR),
                        ),
                    ],
                ),
            ),
        ],
    )

def get_weather_icon(icon_key):
    img_data = WEATHER_ICONS.get(icon_key, WEATHER_ICONS["cloudy.png"])
    return render.Image(src = img_data)

def condition_to_icon_key(condition, daytime):
    if condition == "clear":
        return "sunny.png" if daytime else "moony.png"
    elif condition == "partly_cloudy":
        return "sunnyish.png" if daytime else "moonyish.png"
    elif condition == "cloudy":
        return "cloudy.png"
    elif condition == "rain":
        return "rainy.png"
    elif condition == "thunderstorm":
        return "thundery.png"
    elif condition == "snow":
        return "snowy.png"
    elif condition == "heavy_snow":
        return "snowy2.png"
    elif condition == "sleet":
        return "sleety.png"
    elif condition == "hail":
        return "haily.png"
    elif condition == "fog":
        return "foggy.png"
    elif condition == "wind":
        return "windy.png"
    elif condition == "tornado":
        return "tornady.png"
    else:
        return "cloudy.png"

def is_daytime(now):
    return now.hour >= 6 and now.hour < 20

# ── Full frame builder ───────────────────────────────────────────────────

def build_frame(now, is_24hour, time_color, temp_color, humidity_color, show_unit, unit_system, show_colon, weather, show_day_date):
    return render.Box(
        width = 64,
        height = 32,
        child = render.Column(
            main_align = "center",
            children = [
                build_time_row(now, is_24hour, time_color, show_colon),
                build_weather_row(weather, temp_color, humidity_color, show_unit, unit_system, now, show_day_date),
            ],
        ),
    )

# ── Night mode ───────────────────────────────────────────────────────────

def parse_hhmm(s, default):
    # Only accept a strict 4-digit HHmm string with valid hour/minute ranges
    # (e.g. "2300"). Anything else - wrong length, non-digits, out-of-range
    # hour/minute like "11pm" or "23:00" - falls back to `default` rather
    # than crashing int(), since Starlark has no try/catch.
    if not s or len(s) != 4 or not s.isdigit():
        return default
    hour = int(s[0:2])
    minute = int(s[2:4])
    if hour > 23 or minute > 59:
        return default
    return hour * 100 + minute

def is_night(now, start_str, end_str):
    current = now.hour * 100 + now.minute
    start = parse_hhmm(start_str, 2300)
    end = parse_hhmm(end_str, 700)
    if start > end:
        return current >= start or current < end
    return current >= start and current < end

def render_night_mode(now, is_24hour, blink):
    frame_a = render.Box(
        width = 64,
        height = 32,
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [build_time_row(now, is_24hour, NIGHT_DIM_COLOR, True)],
        ),
    )
    if blink:
        frame_b = render.Box(
            width = 64,
            height = 32,
            child = render.Column(
                main_align = "center",
                cross_align = "center",
                children = [build_time_row(now, is_24hour, NIGHT_DIM_COLOR, False)],
            ),
        )
    else:
        frame_b = frame_a

    return render.Root(
        delay = BLINK_DELAY_MS,
        child = render.Animation(children = [frame_a, frame_b]),
    )

# ── Weather API integration ─────────────────────────────────────────────

def get_weather(config, lat, lng, unit_system):
    service = config.get("weather_service") or "nws"
    api_key = config.get("api_key") or ""

    if service == "nws":
        return fetch_nws(lat, lng, unit_system)
    else:
        if not api_key:
            return no_api_key_weather()
        return fetch_openweather(lat, lng, api_key, unit_system)

def default_weather():
    return {"temp": None, "humidity": None, "condition": "cloudy", "description": "unavailable"}

def no_api_key_weather():
    return {"temp": None, "humidity": None, "condition": "cloudy", "description": "no key"}

# -- OpenWeather --

def fetch_openweather(lat, lng, api_key, unit_system):
    cache_key = "ow_%s_%s_%s" % (lat, lng, unit_system)
    cached = cache.get(cache_key)
    if cached:
        return json.decode(cached)

    units = "imperial" if unit_system == "imperial" else "metric"
    url = (
        "https://api.openweathermap.org/data/2.5/weather" +
        "?lat=%s&lon=%s&appid=%s&units=%s" % (lat, lng, api_key, units)
    )
    resp = http.get(url, ttl_seconds = 600)
    if resp.status_code != 200:
        print("OpenWeather error: %d" % resp.status_code)
        return default_weather()

    data = resp.json()
    result = {
        "temp": int(math.round(data["main"]["temp"])),
        "humidity": int(data["main"]["humidity"]),
        "condition": ow_code_to_condition(data["weather"][0]["id"]),
        "description": data["weather"][0]["description"],
    }
    cache.set(cache_key, json.encode(result), ttl_seconds = 600)
    return result

def ow_code_to_condition(code):
    if code >= 200 and code < 300:
        return "thunderstorm"
    elif code >= 300 and code < 400:
        return "rain"
    elif code >= 500 and code < 600:
        return "rain"
    elif code == 611 or code == 612 or code == 613:
        return "sleet"
    elif code >= 600 and code < 700:
        return "snow"
    elif code >= 700 and code < 800:
        return "fog"
    elif code == 800:
        return "clear"
    elif code == 801 or code == 802:
        return "partly_cloudy"
    else:
        return "cloudy"

# -- NWS (National Weather Service) --

def fetch_nws(lat, lng, unit_system):
    # Step 1: resolve grid point + observation stations URL
    meta_key = "nws_meta_%s_%s" % (lat, lng)
    meta_cached = cache.get(meta_key)
    if meta_cached:
        meta = json.decode(meta_cached)
    else:
        resp = http.get(
            "https://api.weather.gov/points/%s,%s" % (lat, lng),
            ttl_seconds = 86400,
        )
        if resp.status_code != 200:
            print("NWS /points error: %d - try OpenWeather instead" % resp.status_code)
            return default_weather()
        props = resp.json()["properties"]
        meta = {
            "stations_url": props["observationStations"],
            "forecast_hourly": props["forecastHourly"],
        }
        cache.set(meta_key, json.encode(meta), ttl_seconds = 86400)

    # Step 2: get nearby station IDs
    stations_key = "nws_stids_%s_%s" % (lat, lng)
    stations_cached = cache.get(stations_key)
    if stations_cached:
        station_ids = json.decode(stations_cached)
    else:
        resp = http.get(meta["stations_url"] + "?limit=5", ttl_seconds = 86400)
        if resp.status_code != 200:
            return default_weather()
        station_ids = [
            f["properties"]["stationIdentifier"]
            for f in resp.json()["features"]
        ]
        cache.set(stations_key, json.encode(station_ids), ttl_seconds = 86400)

    # Step 3: try each station's latest observation
    for sid in station_ids:
        obs_key = "nws_obs_%s" % sid
        obs_cached = cache.get(obs_key)
        if obs_cached:
            return json.decode(obs_cached)

        resp = http.get(
            "https://api.weather.gov/stations/%s/observations/latest" % sid,
            ttl_seconds = 600,
        )
        if resp.status_code != 200:
            continue

        props = resp.json()["properties"]
        temp_c = props.get("temperature", {}).get("value")
        humidity = props.get("relativeHumidity", {}).get("value")
        if temp_c == None:
            continue

        temp = temp_c * 9.0 / 5.0 + 32.0 if unit_system == "imperial" else temp_c
        result = {
            "temp": int(math.round(temp)),
            "humidity": int(math.round(humidity)) if humidity != None else 0,
            "condition": nws_raw_to_condition(props.get("rawMessage", "")),
            "description": "",
        }
        cache.set(obs_key, json.encode(result), ttl_seconds = 600)
        return result

    # Step 4: fallback to hourly forecast
    print("All NWS stations failed - falling back to hourly forecast")
    return fetch_nws_hourly_fallback(meta["forecast_hourly"], unit_system)

def fetch_nws_hourly_fallback(url, unit_system):
    cache_key = "nws_hourly_%s" % url
    cached = cache.get(cache_key)
    if cached:
        return json.decode(cached)

    resp = http.get(url, ttl_seconds = 600)
    if resp.status_code != 200:
        return default_weather()

    period = resp.json()["properties"]["periods"][0]
    temp_f = period["temperature"]
    temp = temp_f if unit_system == "imperial" else (temp_f - 32) * 5.0 / 9.0
    humidity = period.get("relativeHumidity", {}).get("value", 0) or 0

    result = {
        "temp": int(math.round(temp)),
        "humidity": int(math.round(humidity)),
        "condition": nws_icon_url_to_condition(period.get("icon", "")),
        "description": period.get("shortForecast", ""),
    }
    cache.set(cache_key, json.encode(result), ttl_seconds = 600)
    return result

def nws_raw_to_condition(raw):
    raw = raw.upper()
    if "TS" in raw:
        return "thunderstorm"
    if "GR" in raw:
        return "hail"
    if "RA" in raw or "DZ" in raw:
        return "rain"
    if "SN" in raw or "SG" in raw or "IC" in raw:
        return "snow"
    if "PL" in raw or "ZR" in raw:
        return "sleet"
    if "FG" in raw or "BR" in raw or "HZ" in raw or "FU" in raw:
        return "fog"
    if "OVC" in raw or "BKN" in raw:
        return "cloudy"
    if "SCT" in raw or "FEW" in raw:
        return "partly_cloudy"
    if "SKC" in raw or "CLR" in raw:
        return "clear"
    return "partly_cloudy"

def nws_icon_url_to_condition(url):
    url = url.lower()
    if "tsra" in url or "thunder" in url:
        return "thunderstorm"
    if "fzra" in url or "sleet" in url:
        return "sleet"
    if "rain" in url or "shower" in url:
        return "rain"
    if "blizzard" in url or "snow" in url:
        return "snow"
    if "fog" in url or "smoke" in url:
        return "fog"
    if "ovc" in url or "cloudy" in url:
        return "cloudy"
    if "sct" in url or "bkn" in url or "few" in url:
        return "partly_cloudy"
    if "skc" in url or "sunny" in url:
        return "clear"
    return "partly_cloudy"
