"""
Morphing Clock for Tronbyt / Pixlet
------------------------------------
A port of the digit-morphing animation from gquiring/MorphingClockQ
(itself a remix of Hari Wiguna's Morphing Clock for ESP8266 + PxMatrix).

WHAT CHANGED FROM THE ARDUINO VERSION:
The original runs on an ESP8266 that redraws the matrix continuously in
real time, using delay(animSpeed) between pixel pushes. Tronbyt/Pixlet
apps don't run continuously on the device -- a server re-executes this
script periodically and bakes the result into a short looping WebP that
the device displays until the next refresh. So instead of animating
live every second, this app:

  1. Remembers the digits it last displayed (via the `cache` module).
  2. On each render, diffs old vs. new digits for hour/minute.
  3. Generates the morph animation ONLY for digits that changed,
     reusing the exact segment-sliding logic from Digit.cpp.
  4. Holds on the settled digits for a while so the clip doesn't loop
     back and re-morph pointlessly before the next server refresh.

How often you actually see a fresh morph therefore depends on how often
your Tronbyt server re-renders this app -- there is no way to get a true
per-second tick without configuring very frequent re-renders, which is a
real load consideration on a self-hosted server.

Geometry, segment layout and all 10 Morph0()..Morph9() transition
functions below are a direct, line-by-line translation of Digit.cpp.
"""

load("render.star", "render")
load("time.star", "time")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("schema.star", "schema")

# ---------------------------------------------------------------------------
# Digit geometry (matches Digit.cpp: segHeight = segWidth = 6)
# Local coordinate system is Y-UP (y=0 is the bottom row), same as the
# original Arduino code, to keep the transliteration exact. We flip to
# screen (Y-DOWN) coordinates only when compositing the final frame.
# ---------------------------------------------------------------------------

SEG_H = 6
SEG_W = 6
DIGIT_W = SEG_W + 2       # 8
DIGIT_H = SEG_H * 2 + 3   # 15

# Segment endpoints: (x1, y1, x2, y2), axis-aligned only (as in the original)
SEGMENTS = {
    "A": (1, SEG_H * 2 + 2, SEG_W, SEG_H * 2 + 2),
    "B": (SEG_W + 1, SEG_H * 2 + 1, SEG_W + 1, SEG_H + 2),
    "C": (SEG_W + 1, 1, SEG_W + 1, SEG_H),
    "D": (1, 0, SEG_W, 0),
    "E": (0, 1, 0, SEG_H),
    "F": (0, SEG_H * 2 + 1, 0, SEG_H + 2),
    "G": (1, SEG_H + 1, SEG_W, SEG_H + 1),
}

DIGIT_SEGS = {
    0: "ABCDEF",
    1: "BC",
    2: "ABDEG",
    3: "ABCDG",
    4: "BCFG",
    5: "ACDFG",
    6: "ACDEFG",
    7: "ABC",
    8: "ABCDEFG",
    9: "ABCDFG",
}

# ---------------------------------------------------------------------------
# Low-level buffer ops (stand-ins for drawPixel / drawLine on a PxMATRIX)
# The buffer is a dict of "x,y" -> True (lit) / False (unlit).
# ---------------------------------------------------------------------------

def draw_pixel(buf, x, y, on):
    buf["%d,%d" % (x, y)] = on

def draw_line(buf, x1, y1, x2, y2, on):
    if x1 == x2:
        lo = min(y1, y2)
        hi = max(y1, y2)
        for y in range(lo, hi + 1):
            draw_pixel(buf, x1, y, on)
    else:
        lo = min(x1, x2)
        hi = max(x1, x2)
        for x in range(lo, hi + 1):
            draw_pixel(buf, x, y1, on)

def snapshot(buf):
    return dict(buf)

def draw_digit_static(buf, value):
    lit = DIGIT_SEGS[value]
    for seg in SEGMENTS:
        x1, y1, x2, y2 = SEGMENTS[seg]
        draw_line(buf, x1, y1, x2, y2, seg in lit)

# ---------------------------------------------------------------------------
# Morph functions -- direct translation of Digit.cpp's Morph0()..Morph9().
# Every "delay(animSpeed)" becomes "take a snapshot for the next frame".
# ---------------------------------------------------------------------------

def morph1(buf, frames):
    for i in range(0, SEG_W + 2):
        draw_line(buf, i - 1, 1, i - 1, SEG_H, False)
        draw_line(buf, i, 1, i, SEG_H, True)
        draw_line(buf, i - 1, SEG_H * 2 + 1, i - 1, SEG_H + 2, False)
        draw_line(buf, i, SEG_H * 2 + 1, i, SEG_H + 2, True)
        draw_pixel(buf, 1 + i, SEG_H * 2 + 2, False)
        draw_pixel(buf, 1 + i, 0, False)
        draw_pixel(buf, 1 + i, SEG_H + 1, False)
        frames.append(snapshot(buf))

def morph2(buf, frames):
    for i in range(0, SEG_W + 1):
        if i < SEG_W:
            draw_pixel(buf, SEG_W - i, SEG_H * 2 + 2, True)
            draw_pixel(buf, SEG_W - i, SEG_H + 1, True)
            draw_pixel(buf, SEG_W - i, 0, True)
        draw_line(buf, SEG_W + 1 - i, 1, SEG_W + 1 - i, SEG_H, False)
        draw_line(buf, SEG_W - i, 1, SEG_W - i, SEG_H, True)
        frames.append(snapshot(buf))

def morph3(buf, frames):
    for i in range(0, SEG_W + 1):
        draw_line(buf, 0 + i, 1, 0 + i, SEG_H, False)
        draw_line(buf, 1 + i, 1, 1 + i, SEG_H, True)
        frames.append(snapshot(buf))

def morph4(buf, frames):
    for i in range(0, SEG_W):
        draw_pixel(buf, SEG_W - i, SEG_H * 2 + 2, False)
        draw_pixel(buf, 0, SEG_H * 2 + 1 - i, True)
        draw_pixel(buf, 1 + i, 0, False)
        frames.append(snapshot(buf))

def morph5(buf, frames):
    for i in range(0, SEG_W):
        draw_pixel(buf, SEG_W + 1, SEG_H + 2 + i, False)
        draw_pixel(buf, SEG_W - i, SEG_H * 2 + 2, True)
        draw_pixel(buf, SEG_W - i, 0, True)
        frames.append(snapshot(buf))

def morph6(buf, frames):
    for i in range(0, SEG_W + 1):
        draw_line(buf, SEG_W - i, 1, SEG_W - i, SEG_H, True)
        if i > 0:
            draw_line(buf, SEG_W - i + 1, 1, SEG_W - i + 1, SEG_H, False)
        frames.append(snapshot(buf))

def morph7(buf, frames):
    for i in range(0, SEG_W + 2):
        draw_line(buf, i - 1, 1, i - 1, SEG_H, False)
        draw_line(buf, i, 1, i, SEG_H, True)
        draw_line(buf, i - 1, SEG_H * 2 + 1, i - 1, SEG_H + 2, False)
        draw_line(buf, i, SEG_H * 2 + 1, i, SEG_H + 2, True)
        draw_pixel(buf, 1 + i, 0, False)
        draw_pixel(buf, 1 + i, SEG_H + 1, False)
        frames.append(snapshot(buf))

def morph8(buf, frames):
    for i in range(0, SEG_W + 1):
        draw_line(buf, SEG_W - i, SEG_H * 2 + 1, SEG_W - i, SEG_H + 2, True)
        if i > 0:
            draw_line(buf, SEG_W - i + 1, SEG_H * 2 + 1, SEG_W - i + 1, SEG_H + 2, False)
        draw_line(buf, SEG_W - i, 1, SEG_W - i, SEG_H, True)
        if i > 0:
            draw_line(buf, SEG_W - i + 1, 1, SEG_W - i + 1, SEG_H, False)
        if i < SEG_W:
            draw_pixel(buf, SEG_W - i, 0, True)
            draw_pixel(buf, SEG_W - i, SEG_H + 1, True)
        frames.append(snapshot(buf))

def morph9(buf, frames):
    for i in range(0, SEG_W + 2):
        draw_line(buf, i - 1, 1, i - 1, SEG_H, False)
        draw_line(buf, i, 1, i, SEG_H, True)
        frames.append(snapshot(buf))

def morph0(buf, frames, old_value):
    for i in range(0, SEG_W + 1):
        if old_value == 1:
            draw_line(buf, SEG_W - i, SEG_H * 2 + 1, SEG_W - i, SEG_H + 2, True)
            if i > 0:
                draw_line(buf, SEG_W - i + 1, SEG_H * 2 + 1, SEG_W - i + 1, SEG_H + 2, False)
            draw_line(buf, SEG_W - i, 1, SEG_W - i, SEG_H, True)
            if i > 0:
                draw_line(buf, SEG_W - i + 1, 1, SEG_W - i + 1, SEG_H, False)
            if i < SEG_W:
                draw_pixel(buf, SEG_W - i, SEG_H * 2 + 2, True)
                draw_pixel(buf, SEG_W - i, 0, True)
        if old_value == 2:
            draw_line(buf, SEG_W - i, SEG_H * 2 + 1, SEG_W - i, SEG_H + 2, True)
            if i > 0:
                draw_line(buf, SEG_W - i + 1, SEG_H * 2 + 1, SEG_W - i + 1, SEG_H + 2, False)
            draw_pixel(buf, 1 + i, SEG_H + 1, False)
            if i < SEG_W:
                draw_pixel(buf, SEG_W + 1, SEG_H + 1 - i, True)
        if old_value == 3:
            draw_line(buf, SEG_W - i, SEG_H * 2 + 1, SEG_W - i, SEG_H + 2, True)
            if i > 0:
                draw_line(buf, SEG_W - i + 1, SEG_H * 2 + 1, SEG_W - i + 1, SEG_H + 2, False)
            draw_line(buf, SEG_W - i, 1, SEG_W - i, SEG_H, True)
            if i > 0:
                draw_line(buf, SEG_W - i + 1, 1, SEG_W - i + 1, SEG_H, False)
            draw_pixel(buf, SEG_W - i, SEG_H + 1, False)
        if old_value == 5:
            if i < SEG_W:
                if i > 0:
                    draw_line(buf, 1 + i, SEG_H * 2 + 1, 1 + i, SEG_H + 2, False)
                draw_line(buf, 2 + i, SEG_H * 2 + 1, 2 + i, SEG_H + 2, True)
        if old_value == 5 or old_value == 9:
            if i < SEG_W:
                draw_pixel(buf, SEG_W - i, SEG_H + 1, False)
                draw_pixel(buf, 0, SEG_H - i, True)
        frames.append(snapshot(buf))

def morph(buf, frames, old_value, new_value):
    if new_value == 0:
        morph0(buf, frames, old_value)
    elif new_value == 1:
        morph1(buf, frames)
    elif new_value == 2:
        morph2(buf, frames)
    elif new_value == 3:
        morph3(buf, frames)
    elif new_value == 4:
        morph4(buf, frames)
    elif new_value == 5:
        morph5(buf, frames)
    elif new_value == 6:
        morph6(buf, frames)
    elif new_value == 7:
        morph7(buf, frames)
    elif new_value == 8:
        morph8(buf, frames)
    elif new_value == 9:
        morph9(buf, frames)

def build_digit_frames(old_value, new_value):
    buf = {}
    draw_digit_static(buf, old_value)
    frames = [snapshot(buf)]
    if old_value != new_value:
        morph(buf, frames, old_value, new_value)
    return frames

# ---------------------------------------------------------------------------
# Weather (Open-Meteo) -- no API key required.
#
# Top row layout (rows 0-7, above the digits), matching the original
# ESP8266 layout: left = wind/humidity (alternating), center = condition,
# right = temperature.
#
# NOTE ON THE ALTERNATION: the Arduino version flips wind/humidity every
# 10 seconds in real time. This app doesn't run continuously, so instead
# it flips which one is shown EACH TIME THE APP RE-RENDERS (tracked via
# `cache`). To get something close to a 10-second rotation, set this
# app's refresh interval on your Tronbyt server to ~10s. If it refreshes
# less often, the two will still alternate, just on that slower cadence.
# ---------------------------------------------------------------------------

WX_LABELS = {
    0: "CLEAR",
    1: "MCLR",
    2: "PCLDY",
    3: "OVER",
    45: "FOG",
    48: "FOG",
    51: "DRZL",
    53: "DRZL",
    55: "DRZL",
    56: "FDRZ",
    57: "FDRZ",
    61: "RAIN",
    63: "RAIN",
    65: "RAIN",
    66: "FRAIN",
    67: "FRAIN",
    71: "SNOW",
    73: "SNOW",
    75: "SNOW",
    77: "SNOW",
    80: "SHWRS",
    81: "SHWRS",
    82: "SHWRS",
    85: "SNOW",
    86: "SNOW",
    95: "TSTM",
    96: "TSTM",
    99: "TSTM",
}

WX_CACHE_TTL = 900  # 15 minutes -- Open-Meteo is free/keyless, but no need to hammer it
WX_FONT = "tom-thumb"
COLOR_WX = "#aaaaaa"

def get_weather(lat, lon, units):
    cache_key = "wx_%s_%s_%s" % (lat, lon, units)
    cached = cache.get(cache_key)
    if cached != None:
        return json.decode(cached)

    if units == "metric":
        temp_unit = "celsius"
        wind_unit = "kmh"
    else:
        temp_unit = "fahrenheit"
        wind_unit = "mph"

    url = "https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&current=temperature_2m,relative_humidity_2m,wind_speed_10m,wind_direction_10m,weather_code&temperature_unit=%s&wind_speed_unit=%s" % (lat, lon, temp_unit, wind_unit)

    res = http.get(url)
    if res.status_code != 200:
        return None

    data = res.json()
    current = data.get("current", {})
    if current == None:
        return None

    result = {
        "temp": current.get("temperature_2m"),
        "humidity": current.get("relative_humidity_2m"),
        "wind": current.get("wind_speed_10m"),
        "wind_dir": current.get("wind_direction_10m"),
        "code": current.get("weather_code"),
    }

    cache.set(cache_key, json.encode(result), ttl_seconds = WX_CACHE_TTL)
    return result

COMPASS_POINTS = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]

def degrees_to_compass(deg):
    # 8-point compass: N/E/S/W are naturally single-letter, the diagonals
    # (NE, SE, SW, NW) are two-letter -- matches how compass directions
    # are normally abbreviated.
    idx = int((deg + 22.5) // 45) % 8
    return COMPASS_POINTS[idx]

def weather_row(lat, lon, units, show_wind_dir):
    wx = get_weather(lat, lon, units)

    toggle_raw = cache.get("wx_toggle")
    toggle = int(toggle_raw) if toggle_raw != None else 0
    cache.set("wx_toggle", str(1 - toggle), ttl_seconds = 3600)

    temp_color = COLOR_WX
    left_color = "#ffff00"  # yellow default for wind/humidity

    if wx == None:
        left_str = "N/A"
        center_str = "N/A"
        right_str = "N/A"
    else:
        unit_letter = "F" if units != "metric" else "C"
        wind_unit_str = "mph" if units != "metric" else "kmh"

        wind_str = "%d%s" % (int(wx["wind"]), degrees_to_compass(wx["wind_dir"]) if show_wind_dir else wind_unit_str)
        humidity_str = "%d%%" % int(wx["humidity"])
        left_str = wind_str if toggle == 0 else humidity_str

        # Thresholds below are on a mph / raw-percent basis, so convert
        # wind speed first if the display is set to metric.
        wind_mph = wx["wind"] if units != "metric" else (wx["wind"] * 0.621371)
        if toggle == 0:
            left_color = "#ff0000" if wind_mph > 50 else "#ffff00"
        else:
            left_color = "#ff0000" if wx["humidity"] > 90 else "#ffff00"

        center_str = WX_LABELS.get(int(wx["code"]), "N/A")

        right_str = "%d%s" % (int(wx["temp"]), unit_letter)

        # Thresholds are on a Fahrenheit scale, so convert first if the
        # display is set to metric -- the color bands should mean the same
        # real-world temperature either way.
        temp_f = wx["temp"] if units != "metric" else (wx["temp"] * 9 / 5 + 32)
        if temp_f > 90:
            temp_color = "#ff0000"  # red
        elif temp_f > 70:
            temp_color = "#00cc00"  # green
        elif temp_f > 33:
            temp_color = "#3399ff"  # blue
        else:
            temp_color = "#ffffff"  # white

    def col(x, w, text, color, font = WX_FONT, pad_y = 1, height = 6):
        return render.Padding(
            pad = (x, pad_y, 0, 0),
            child = render.Box(
                width = w,
                height = height,
                child = render.Row(
                    expanded = True,
                    main_align = "center",
                    children = [render.Text(content = text, font = font, color = color)],
                ),
            ),
        )

    # The compass-direction letters (esp. N) are hard to tell apart from W
    # at tom-thumb's tiny 3x5 size, so use the larger 5x8 font specifically
    # when a direction is being shown -- it has enough pixels to make N and
    # W look genuinely different.
    left_font = "5x8" if (show_wind_dir and toggle == 0 and wx != None) else WX_FONT
    left_pad_y = 0 if left_font == "5x8" else 1
    left_height = 8 if left_font == "5x8" else 6

    return render.Stack(
        children = [
            col(0, 22, left_str, left_color, font = left_font, pad_y = left_pad_y, height = left_height),
            col(22, 20, center_str, COLOR_WX),
            col(46, 18, right_str, temp_color),
        ],
    )

# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------

FRAME_DELAY_MS = 45   # ~ the original's animSpeed

# How long (in frames) to hold on the settled digits before the WebP would
# loop back to frame 0 and replay the morph. This needs to comfortably
# outlast however often your Tronbyt server actually re-renders this app --
# otherwise the device keeps looping a short clip and you see the same
# digit "re-morph" over and over until the next real refresh arrives.
# 20 seconds covers most refresh intervals people use for a clock app;
# bump HOLD_SECONDS up if your server's refresh interval is longer than that.
HOLD_SECONDS = 20
HOLD_FRAMES = (HOLD_SECONDS * 1000) // FRAME_DELAY_MS

COLOR_ON = "#33aaff"
COLOR_COLON = "#33aaff"

# x offset (left edge) of each of the 4 digits on the 64-wide canvas.
# Layout (2px gaps throughout, including around the colon), centered on 64:
#   [11]digit0(8) [2] digit1(8) [2] colon(2) [2] digit2(8) [2] digit3(8) -> ends at 53, margins 11/11
DIGIT_X = [11, 21, 35, 45]
COLON_X = 31
TOP_Y = 8  # top of the 15px-tall digit area (digits occupy rows 8-22)
AMPM_X = 56  # a couple px to the right of the last minute digit (ends at x=53)
COLOR_AMPM = "#33aaff"  # matches the default digit color

# Bottom row: day-of-week + date
DATE_ROW_Y = 25       # leaves a couple of rows of breathing room below the digits
DATE_FONT = "tom-thumb"  # tiny 3x5 pixel font, fits comfortably in the remaining space
COLOR_DATE = "#33cc33"

# Default location shown before the user configures their own -- same
# format Tidbyt/Tronbyt's schema.Location field always returns.
DEFAULT_LOCATION = """
{
    "lat": "40.6781784",
    "lng": "-73.9441579",
    "description": "Brooklyn, NY, USA",
    "locality": "Brooklyn",
    "place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
    "timezone": "America/New_York"
}
"""

def main(config):
    loc = json.decode(config.get("location", DEFAULT_LOCATION))
    lat = str(loc["lat"])
    lon = str(loc["lng"])
    tz = loc["timezone"]

    now = time.now().in_location(tz)

    hour24 = config.bool("hour_24", False)
    hh = now.hour
    is_pm = hh >= 12
    if not hour24:
        hh = hh % 12
        if hh == 0:
            hh = 12
    mm = now.minute

    digits_now = [hh // 10, hh % 10, mm // 10, mm % 10]

    cache_key = "morphclock_last_digits"
    prev_raw = cache.get(cache_key)
    if prev_raw != None:
        digits_prev = json.decode(prev_raw)
    else:
        digits_prev = digits_now

    cache.set(cache_key, json.encode(digits_now), ttl_seconds = 3600)

    color = config.get("color") or COLOR_ON

    per_digit = []
    max_len = 1
    for i in range(4):
        f = build_digit_frames(int(digits_prev[i]), int(digits_now[i]))
        per_digit.append(f)
        if len(f) > max_len:
            max_len = len(f)

    # Pad every digit's frame list to max_len by repeating its last frame,
    # then append HOLD_FRAMES more copies so the settled time is what's
    # shown most of the time.
    for i in range(4):
        last = per_digit[i][len(per_digit[i]) - 1]
        while len(per_digit[i]) < max_len:
            per_digit[i].append(last)
        for _n in range(HOLD_FRAMES):
            per_digit[i].append(last)

    total_len = max_len + HOLD_FRAMES

    anim_frames = []
    for t in range(total_len):
        children = []
        for i in range(4):
            buf = per_digit[i][t]
            for key in buf:
                if buf[key]:
                    xy = key.split(",")
                    lx = int(xy[0])
                    ly = int(xy[1])
                    sx = DIGIT_X[i] + lx
                    sy = TOP_Y + (DIGIT_H - 1 - ly)  # flip Y (buffer is Y-up)
                    children.append(
                        render.Padding(
                            pad = (sx, sy, 0, 0),
                            child = render.Box(width = 1, height = 1, color = color),
                        ),
                    )

        # Colon between hour and minute pairs
        children.append(
            render.Padding(pad = (COLON_X, TOP_Y + 3, 0, 0), child = render.Box(width = 2, height = 2, color = COLOR_COLON)),
        )
        children.append(
            render.Padding(pad = (COLON_X, TOP_Y + 9, 0, 0), child = render.Box(width = 2, height = 2, color = COLOR_COLON)),
        )

        anim_frames.append(render.Stack(children = children))

    clock_widget = render.Stack(children = anim_frames[0:1]) if total_len == 1 else render.Animation(children = anim_frames)

    # Date / day-of-week row along the bottom. Static, so it's drawn once
    # and layered under the clock animation rather than baked into every
    # morph frame. "Mon Jan 2" is Go's reference-time layout string (as
    # used by time.star) -- e.g. "Sun Sep 7". Swap it for "Mon Jan 02" if
    # you want the day zero-padded ("Sun Sep 07").
    date_str = now.format(config.get("date_format") or "Mon Jan 2")

    date_row = render.Padding(
        pad = (0, DATE_ROW_Y, 0, 0),
        child = render.Box(
            width = 64,
            height = 7,
            child = render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Text(content = date_str, font = DATE_FONT, color = config.get("date_color") or COLOR_DATE),
                ],
            ),
        ),
    )

    units = config.get("units") or "imperial"
    show_wind_dir = config.bool("show_wind_direction", False)
    wx_row = weather_row(lat, lon, units, show_wind_dir)

    # AM/PM indicator, small (5px tall, tom-thumb) like the original --
    # sits in the free space to the right of the last minute digit, only
    # shown when using 12-hour time.
    ampm_widget = render.Padding(
        pad = (AMPM_X, TOP_Y + DIGIT_H - 5, 0, 0),
        child = render.Text(content = "PM" if is_pm else "AM", font = DATE_FONT, color = COLOR_AMPM),
    )

    return render.Root(
        delay = FRAME_DELAY_MS,
        child = render.Stack(children = [clock_widget, date_row, wx_row] + ([ampm_widget] if not hour24 else [])),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Used for the clock's timezone and the weather readout.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "units",
                name = "Units",
                desc = "Temperature and wind speed units.",
                icon = "temperatureHalf",
                default = "imperial",
                options = [
                    schema.Option(display = "Imperial (F, mph)", value = "imperial"),
                    schema.Option(display = "Metric (C, km/h)", value = "metric"),
                ],
            ),
            schema.Toggle(
                id = "hour_24",
                name = "24-hour clock",
                desc = "Show time in 24-hour format instead of 12-hour.",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = "show_wind_direction",
                name = "Show wind direction",
                desc = "Replace the wind speed unit (mph/km/h) with a compass direction (e.g. NE) instead.",
                icon = "compass",
                default = False,
            ),
        ],
    )
