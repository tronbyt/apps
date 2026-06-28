"""Overhead — the single closest aircraft to a location, from an Airplanes.live feed.

Personal, non-commercial use against api.airplanes.live (no key). Renders one readable
plane on a 64x32 display; never raises on bad/empty data — shows a tidy frame instead.
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")

API_URL = "https://api.airplanes.live/v2/point"

# Oklahoma City metro center — a neutral default; the user sets their own location.
DEFAULT_LAT = 35.4676
DEFAULT_LON = -97.5164
DEFAULT_LOCATION = '{"lat": "35.4676", "lng": "-97.5164", "locality": "Oklahoma City"}'

DEFAULT_RADIUS = "10"  # nautical miles
TTL_SECONDS = 45  # >=30 so a device's refresh never approaches the 1 req/sec limit
STALE_SECONDS = 60  # drop records whose position is older than this

EARTH_NM = 3440.065  # mean earth radius in nautical miles
NM_TO_MI = 1.15078
NM_TO_KM_FT = 0.3048  # feet -> meters

# Legible on an LED matrix: amber callsign, dim blue-grey details, red for emergencies.
ACCENT = "#ffb733"
DETAIL = "#8aa0c0"
EMERG = "#ff3b30"

GLYPH = 10  # px box for the plane icon (1x); scaled by `scale` at render time

# Fonts per render scale: 1x for 64x32, 2x for 128x64 (a 2x/"wide" display).
# (big = callsign/title, small = detail lines.)
_FONTS = {
    1: {"big": "tb-8", "small": "tom-thumb"},
    2: {"big": "6x13", "small": "5x8"},
}

# Top-view airliner pointing up (north), rotated in-SVG by heading. Kept within a
# center circle of the 16x16 viewBox so any rotation never clips the corners.
# Format args: (rotation degrees, fill color).
_PLANE_SVG = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16"><g transform="rotate(%d 8 8)"><path fill="%s" d="M8 2 L8.8 7 L14 9.5 L14 10.3 L8.8 9.2 L8.8 12.5 L10.6 13.8 L10.6 14.4 L8 13.4 L5.4 14.4 L5.4 13.8 L7.2 12.5 L7.2 9.2 L2 10.3 L2 9.5 L7.2 7 Z"/></g></svg>'

COMPASS = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
EMERG_LABELS = {"7500": "7500 HIJACK", "7600": "7600 RADIO", "7700": "7700 EMERG"}

def _isnum(v):
    return type(v) == "int" or type(v) == "float"

def _isnum_str(s):
    if type(s) != "string" or not s:
        return False
    has_digit = False
    for c in s.elems():
        if c >= "0" and c <= "9":
            has_digit = True
        elif c != "." and c != "-":
            return False
    return has_digit

def _to_float(v, default):
    if _isnum(v):
        return float(v)
    if _isnum_str(v):
        return float(v)
    return default

def _haversine(lat1, lon1, lat2, lon2):
    p1 = math.radians(lat1)
    p2 = math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lon2 - lon1)
    s1 = math.sin(dp / 2)
    s2 = math.sin(dl / 2)
    a = s1 * s1 + math.cos(p1) * math.cos(p2) * s2 * s2
    return 2 * EARTH_NM * math.asin(math.sqrt(a))

def _bearing(lat1, lon1, lat2, lon2):
    p1 = math.radians(lat1)
    p2 = math.radians(lat2)
    dl = math.radians(lon2 - lon1)
    y = math.sin(dl) * math.cos(p2)
    x = math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl)
    return (math.degrees(math.atan2(y, x)) + 360) % 360

def _compass(deg):
    return COMPASS[int(math.round(deg / 45.0)) % 8]

def _is_emergency(ac):
    if ac.get("squawk") in EMERG_LABELS:
        return True
    em = ac.get("emergency")
    return type(em) == "string" and em != "" and em != "none"

def _emerg_label(ac):
    return EMERG_LABELS.get(ac.get("squawk"), "EMERGENCY")

def _callsign(ac):
    flight = ac.get("flight")
    if type(flight) == "string" and flight.strip():
        return flight.strip()
    reg = ac.get("r")
    if type(reg) == "string" and reg.strip():
        return reg.strip()
    hex = ac.get("hex")
    if type(hex) == "string" and hex:
        return hex.upper()
    return "UNKNOWN"

def _fmt_alt(ac, unit):
    alt = ac.get("alt_baro")
    if alt == "ground":
        return "GND"
    if not _isnum(alt):
        return None
    if unit == "m":
        return "%dm" % int(math.round(alt * NM_TO_KM_FT))
    return "%dft" % int(alt)

def _fmt_speed(ac, unit):
    gs = ac.get("gs")
    if not _isnum(gs):
        return None
    if unit == "mph":
        return "%dmph" % int(math.round(gs * NM_TO_MI))
    return "%dkt" % int(math.round(gs))

def _one_dp(x):
    v = int(math.round(x * 10))
    return "%d.%d" % (v // 10, v % 10)

def _fmt_dist(nm, speed_unit):
    if speed_unit == "mph":
        return _one_dp(nm * NM_TO_MI) + "mi"
    return _one_dp(nm) + "nm"

def _glyph(track, color, scale):
    angle = int(math.round(track)) if _isnum(track) else 0  # heading up = north
    return render.Image(src = _PLANE_SVG % (angle, color), width = GLYPH * scale, height = GLYPH * scale)

def _select(aclist, lat, lon, only_airborne, highlight_emergency):
    best = None
    best_dist = 1e9
    emerg = None
    emerg_dist = 1e9
    for ac in aclist:
        if type(ac) != "dict":
            continue
        aclat = ac.get("lat")
        aclon = ac.get("lon")
        if not _isnum(aclat) or not _isnum(aclon):
            continue
        seen = ac.get("seen")
        seen_pos = ac.get("seen_pos")
        if (_isnum(seen) and seen > STALE_SECONDS) or (_isnum(seen_pos) and seen_pos > STALE_SECONDS):
            continue
        if only_airborne and ac.get("alt_baro") == "ground":
            continue

        dist = _haversine(lat, lon, aclat, aclon)
        rec = (dist, _bearing(lat, lon, aclat, aclon), ac)
        if dist < best_dist:
            best, best_dist = rec, dist
        if highlight_emergency and _is_emergency(ac) and dist < emerg_dist:
            emerg, emerg_dist = rec, dist

    return emerg if emerg != None else best

def _line(text, font, color, scale):
    # Centered when it fits the display width, scrolls horizontally when it overflows.
    return render.Marquee(width = 64 * scale, child = render.Text(text, font = font, color = color))

def _render_aircraft(target, alt_unit, speed_unit, highlight_emergency, scale):
    dist, brg, ac = target
    em = highlight_emergency and _is_emergency(ac)
    accent = EMERG if em else ACCENT
    fonts = _FONTS[scale]

    type_code = ac.get("t")
    alt = _fmt_alt(ac, alt_unit)
    line2 = " · ".join([p for p in [type_code if type(type_code) == "string" and type_code else None, alt] if p])

    if em:
        line3 = _emerg_label(ac)
    else:
        line3 = "%s %s" % (_fmt_dist(dist, speed_unit), _compass(brg))
        spd = _fmt_speed(ac, speed_unit)
        if spd:
            line3 += " · " + spd

    children = [_line(_callsign(ac), fonts["big"], accent, scale)]
    if line2:
        children.append(_line(line2, fonts["small"], DETAIL, scale))
    children.append(_line(line3, fonts["small"], EMERG if em else DETAIL, scale))
    children.append(_glyph(ac.get("track"), accent, scale))

    return render.Root(
        child = render.Column(
            main_align = "space_between",
            cross_align = "center",
            children = children,
        ),
    )

def _frame_message(title, sub, scale):
    fonts = _FONTS[scale]
    children = [render.Text(title, font = fonts["big"], color = DETAIL)]
    if sub:
        children.append(render.Text(sub, font = fonts["small"], color = DETAIL))
    children.append(_glyph(None, DETAIL, scale))
    return render.Root(
        child = render.Box(
            child = render.Column(
                main_align = "center",
                cross_align = "center",
                children = children,
            ),
        ),
    )

def main(config):
    scale = 2 if canvas.is2x() else 1

    loc = json.decode(config.get("location", DEFAULT_LOCATION))
    if type(loc) != "dict":
        loc = {}
    lat = _to_float(loc.get("lat"), DEFAULT_LAT)
    lon = _to_float(loc.get("lng"), DEFAULT_LON)

    radius = _to_float(config.get("radius") or DEFAULT_RADIUS, 10.0)
    radius = int(math.round(max(1.0, min(250.0, radius))))

    alt_unit = config.get("alt_units", "ft")
    speed_unit = config.get("speed_units", "kt")
    only_airborne = config.bool("only_airborne", False)
    highlight_emergency = config.bool("highlight_emergency", True)
    skip_if_empty = config.bool("skip_if_empty", False)

    url = "%s/%s/%s/%d" % (API_URL, lat, lon, radius)
    resp = http.get(url, ttl_seconds = TTL_SECONDS)
    if resp.status_code != 200:
        return _frame_message("NO SIGNAL", None, scale)

    data = resp.json()
    aclist = data.get("ac") if type(data) == "dict" else None
    if type(aclist) != "list":
        return [] if skip_if_empty else _frame_message("NO AIRCRAFT", "in range", scale)

    target = _select(aclist, lat, lon, only_airborne, highlight_emergency)
    if target == None:
        return [] if skip_if_empty else _frame_message("NO AIRCRAFT", "in range", scale)

    return _render_aircraft(target, alt_unit, speed_unit, highlight_emergency, scale)

def get_schema():
    units_alt = [
        schema.Option(display = "Feet", value = "ft"),
        schema.Option(display = "Meters", value = "m"),
    ]
    units_speed = [
        schema.Option(display = "Knots", value = "kt"),
        schema.Option(display = "MPH", value = "mph"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Center point to search around.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "radius",
                name = "Radius (nm)",
                desc = "Search radius in nautical miles (1-250).",
                icon = "rulerHorizontal",
                default = DEFAULT_RADIUS,
            ),
            schema.Dropdown(
                id = "alt_units",
                name = "Altitude units",
                desc = "Units for altitude.",
                icon = "ruler",
                default = "ft",
                options = units_alt,
            ),
            schema.Dropdown(
                id = "speed_units",
                name = "Speed units",
                desc = "Units for speed; distance follows it (kt -> nm, mph -> mi).",
                icon = "gaugeHigh",
                default = "kt",
                options = units_speed,
            ),
            schema.Toggle(
                id = "only_airborne",
                name = "Airborne only",
                desc = "Skip aircraft on the ground.",
                icon = "planeUp",
                default = False,
            ),
            schema.Toggle(
                id = "highlight_emergency",
                name = "Highlight emergencies",
                desc = "Surface any 7500/7600/7700 squawk ahead of the closest plane.",
                icon = "triangleExclamation",
                default = True,
            ),
            schema.Toggle(
                id = "skip_if_empty",
                name = "Hide when no aircraft",
                desc = "Skip this app in rotation when no aircraft are in range.",
                icon = "eyeSlash",
                default = False,
            ),
        ],
    )
