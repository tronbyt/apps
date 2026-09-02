"""
RainRadar — Pixlet weather radar for a 64x32 Tronbyt.
Pick a location (or lat/lon). Loops recent RainViewer scans on a dark map.
Radar data: RainViewer Weather Maps API (personal/educational use).
https://www.rainviewer.com/
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

MAPS_URL = "https://api.rainviewer.com/public/weather-maps.json"
MAPS_TTL = 120
TILE_TTL = 600
BASEMAP_TTL = 86400

DEFAULT_LOCATION = """{
    "lat": "29.7604",
    "lng": "-95.3698",
    "description": "Houston, TX",
    "locality": "Houston",
    "timezone": "America/Chicago"
}"""

def main(config):
    loc = _location(config)
    zoom = _clamp_int(config.get("zoom", "7"), 4, 9, 7)
    color = _clamp_int(config.get("color", "6"), 0, 8, 6)
    frame_count = _clamp_int(config.get("frames", "6"), 3, 12, 6)
    delay = _clamp_int(config.get("delay", "400"), 150, 1200, 400)
    marker_style = config.get("marker", "red")
    time_format = config.get("time_format", "15:04")
    x0, y0, ox, oy, x1, y1, ox2, oy2 = _deg2num(loc["lat"], loc["lng"], zoom)

    maps = http.get(MAPS_URL, ttl_seconds = MAPS_TTL)
    if maps.status_code != 200:
        return _error("Radar unavailable")

    data = maps.json()
    host = data.get("host") or "https://tilecache.rainviewer.com"
    past = data.get("radar", {}).get("past", [])
    if not past:
        return _error("No radar frames")

    selected = past[-frame_count:]
    images = []
    for frame in selected:
        path = frame.get("path")
        if not path:
            continue
        rf = _radar_frame_centered(host, path, zoom, x0, y0, ox, oy, x1, y1, ox2, oy2, color)
        if not rf:
            continue
        stamp = _stamp(frame.get("time"), loc["timezone"], time_format)
        images.append(_hud_frame(rf, loc["label"], stamp))

    if not images:
        return _error("No radar image")

    # Hold the latest scan a beat so the current picture is readable.
    anim_children = images + [images[-1], images[-1]]

    marker_w = _marker(32, 16, marker_style)
    stack_children = [
        render.Box(width = 64, height = 32, color = "#020617"),
        _basemap_centered(zoom, x0, y0, ox, oy, x1, y1, ox2, oy2),
        render.Animation(children = anim_children),
    ]
    if marker_w:
        stack_children.append(marker_w)
    return render.Root(
        delay = delay,
        max_age = 600,
        child = render.Stack(children = stack_children),
    )

def _hud_frame(radar, label, stamp):
    right = stamp if stamp else "RADAR"
    return render.Stack(
        children = [
            radar,
            render.Column(
                expanded = True,
                main_align = "start",
                children = [
                    render.Box(
                        height = 7,
                        color = "#0007",
                        child = render.Padding(
                            pad = (1, 0, 1, 0),
                            child = render.Row(
                                expanded = True,
                                main_align = "space_between",
                                cross_align = "center",
                                children = [
                                    render.Text(label, font = "tom-thumb", color = "#86EFAC"),
                                    render.Text(right, font = "tom-thumb", color = "#E5E7EB"),
                                ],
                            ),
                        ),
                    ),
                ],
            ),
        ],
    )
MARKER_COLORS = {
    "red": "#EF4444",
    "white": "#FFFFFF",
    "cyan": "#06B6D4",
    "yellow": "#FACC15",
    "green": "#22C55E",
}

def _marker(px, py, style):
    if style == "off" or style not in MARKER_COLORS:
        return None
    color = MARKER_COLORS[style]

    left = px - 1
    top = py - 1
    if left < 0:
        left = 0
    if top < 7:
        top = 7

    return render.Padding(
        pad = (left, top, 0, 0),
        child = render.Stack(
            children = [
                render.Box(width = 3, height = 3, color = "#00000088"),
                render.Padding(
                    pad = (1, 0, 0, 0),
                    child = render.Box(width = 1, height = 3, color = color),
                ),
                render.Padding(
                    pad = (0, 1, 0, 0),
                    child = render.Box(width = 3, height = 1, color = color),
                ),
            ],
        ),
    )

def _fetch_basemap_tile(zoom, x, y):
    url = "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/%d/%d/%d" % (zoom, y, x)
    res = http.get(
        url,
        ttl_seconds = BASEMAP_TTL,
        headers = {"User-Agent": "RainRadar-Pixlet/1.0 (personal)"},
    )
    if res.status_code != 200 or not res.body():
        return None
    return render.Image(src = res.body(), width = 64, height = 32)

def _basemap_centered(zoom, x0, y0, ox, oy, x1, y1, ox2, oy2):
    b00 = _fetch_basemap_tile(zoom, x0, y0)
    b10 = _fetch_basemap_tile(zoom, x1, y0)
    b01 = _fetch_basemap_tile(zoom, x0, y1)
    b11 = _fetch_basemap_tile(zoom, x1, y1)

    tiles = []
    if b00:
        tiles.append(render.Padding(pad = (ox, oy, 0, 0), child = b00))
    if b10:
        tiles.append(render.Padding(pad = (ox2, oy, 0, 0), child = b10))
    if b01:
        tiles.append(render.Padding(pad = (ox, oy2, 0, 0), child = b01))
    if b11:
        tiles.append(render.Padding(pad = (ox2, oy2, 0, 0), child = b11))

    if not tiles:
        return render.Box(width = 64, height = 32, color = "#020617")
    return render.Stack(children = tiles)

def _fetch_radar_tile(host, path, zoom, x, y, color):
    url = "%s%s/256/%d/%d/%d/%d/1_1.png" % (host, path, zoom, x, y, color)
    tile = http.get(url, ttl_seconds = TILE_TTL)
    if tile.status_code != 200 or not tile.body():
        return None
    return render.Image(src = tile.body(), width = 64, height = 32)

def _radar_frame_centered(host, path, zoom, x0, y0, ox, oy, x1, y1, ox2, oy2, color):
    t00 = _fetch_radar_tile(host, path, zoom, x0, y0, color)
    t10 = _fetch_radar_tile(host, path, zoom, x1, y0, color)
    t01 = _fetch_radar_tile(host, path, zoom, x0, y1, color)
    t11 = _fetch_radar_tile(host, path, zoom, x1, y1, color)

    tiles = []
    if t00:
        tiles.append(render.Padding(pad = (ox, oy, 0, 0), child = t00))
    if t10:
        tiles.append(render.Padding(pad = (ox2, oy, 0, 0), child = t10))
    if t01:
        tiles.append(render.Padding(pad = (ox, oy2, 0, 0), child = t01))
    if t11:
        tiles.append(render.Padding(pad = (ox2, oy2, 0, 0), child = t11))

    if not tiles:
        return None
    return render.Stack(children = tiles)

def _is_num_str(s):
    if not s:
        return False
    has_digit = False
    for i in range(len(s)):
        ch = s[i]
        if ch >= "0" and ch <= "9":
            has_digit = True
        elif ch not in [".", "-", "+"]:
            return False
    return has_digit

def _location(config):
    lat = 29.7604
    lng = -95.3698
    label = "HOUSTON"
    tz = config.get("timezone", "America/Chicago")

    # 1. Check Latitude Longitude Override first
    override_raw = config.get("override", "").strip()
    if not override_raw:
        # Also check lat/lng legacy overrides
        lat_override = config.get("lat", "").strip()
        lng_override = config.get("lng", "").strip()
        if lat_override and lng_override:
            override_raw = "%s, %s" % (lat_override, lng_override)

    if override_raw:
        parts = override_raw.replace(",", " ").split()
        if len(parts) == 2 and _is_num_str(parts[0]) and _is_num_str(parts[1]):
            lat = float(parts[0])
            lng = float(parts[1])
            label = "OVERRIDE"
            return {
                "lat": lat,
                "lng": lng,
                "label": label,
                "timezone": tz,
            }

    # 2. Check Locality setting
    locality = config.get("locality", "").strip()
    if not locality:
        raw = config.get("location")
        if raw and str(raw).strip() != "":
            if type(raw) == "string" and raw.startswith("{"):
                loc_data = json.decode(raw)
                if type(loc_data) == "dict":
                    locality = loc_data.get("locality") or loc_data.get("description") or ""
                    tz = loc_data.get("timezone") or tz
            elif type(raw) == "string":
                locality = raw.strip()

    if not locality:
        locality = "Houston, TX"

    # Format clean display label (e.g. "BAYTOWN" from "Baytown, TX")
    clean_label = locality.split(",")[0].strip().upper()

    # Geocode locality (e.g. "Dallas, TX", "Lufkin, TX", "77520")
    geo_url = "https://nominatim.openstreetmap.org/search?q=%s&format=json&limit=1" % (locality.replace(" ", "+"))
    res = http.get(
        geo_url,
        ttl_seconds = 86400,
        headers = {"User-Agent": "RainRadar-Pixlet/1.0 (personal)"},
    )
    if res.status_code == 200:
        geo_data = res.json()
        if type(geo_data) == "list" and len(geo_data) > 0:
            first = geo_data[0]
            lat = float(str(first.get("lat", lat)))
            lng = float(str(first.get("lon", lng)))
            if clean_label.isdigit() or not clean_label:
                city_name = first.get("name") or locality
                clean_label = city_name.split(",")[0].strip().upper()

    label = clean_label[:10] if clean_label else "LOCATION"

    return {
        "lat": lat,
        "lng": lng,
        "label": label,
        "timezone": tz,
    }

def _deg2num(lat, lon, zoom):
    lat_rad = lat * math.pi / 180.0
    n = math.pow(2.0, zoom)
    x_exact = (lon + 180.0) / 360.0 * n
    y_exact = (1.0 - math.log(math.tan(lat_rad) + (1.0 / math.cos(lat_rad))) / math.pi) / 2.0 * n

    x0 = int(math.floor(x_exact))
    y0 = int(math.floor(y_exact))

    px = int(math.floor((x_exact - x0) * 64.0))
    py = int(math.floor((y_exact - y0) * 32.0))

    ox = 32 - px
    oy = 16 - py

    if ox > 0:
        x1 = x0 - 1
        ox2 = ox - 64
    else:
        x1 = x0 + 1
        ox2 = ox + 64

    if oy > 0:
        y1 = y0 - 1
        oy2 = oy - 32
    else:
        y1 = y0 + 1
        oy2 = oy + 32

    max_tile = int(n) - 1
    x0 = _clamp_int(x0, 0, max_tile, 0)
    y0 = _clamp_int(y0, 0, max_tile, 0)
    x1 = _clamp_int(x1, 0, max_tile, 0)
    y1 = _clamp_int(y1, 0, max_tile, 0)

    return x0, y0, ox, oy, x1, y1, ox2, oy2

def _stamp(unix, timezone, fmt):
    if not unix or fmt == "off":
        return ""
    t = time.from_timestamp(int(unix)).in_location(timezone)
    return t.format(fmt)

def _clamp_int(value, lo, hi, default):
    n = int(value) if value else default
    if n < lo:
        return lo
    if n > hi:
        return hi
    return n

def _error(msg):
    return render.Root(
        child = render.Box(
            color = "#020617",
            child = render.Column(
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text("RADAR", font = "tom-thumb", color = "#F87171"),
                    render.Text(msg, font = "tom-thumb", color = "#E5E7EB"),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "locality",
                name = "Locality",
                desc = "City name, zip code, or address (e.g. Dallas, TX or 75201).",
                icon = "locationDot",
                default = "Houston, TX",
            ),
            schema.Dropdown(
                id = "timezone",
                name = "Timezone",
                desc = "Timezone for displayed timestamp.",
                icon = "clock",
                default = "America/Chicago",
                options = [
                    schema.Option(display = "Central US (America/Chicago)", value = "America/Chicago"),
                    schema.Option(display = "Eastern US (America/New_York)", value = "America/New_York"),
                    schema.Option(display = "Mountain US (America/Denver)", value = "America/Denver"),
                    schema.Option(display = "Pacific US (America/Los_Angeles)", value = "America/Los_Angeles"),
                    schema.Option(display = "London / UK (Europe/London)", value = "Europe/London"),
                    schema.Option(display = "Bahrain / Gulf (Asia/Bahrain)", value = "Asia/Bahrain"),
                    schema.Option(display = "UTC", value = "UTC"),
                ],
            ),
            schema.Dropdown(
                id = "time_format",
                name = "Time overlay",
                desc = "How each radar frame shows its scan time. Same options as Weather Map.",
                icon = "clock",
                default = "15:04",
                options = [
                    schema.Option(display = "Off", value = "off"),
                    schema.Option(display = "12-hour", value = "3:04 PM"),
                    schema.Option(display = "24-hour", value = "15:04"),
                ],
            ),
            schema.Text(
                id = "override",
                name = "Latitude Longitude Override",
                desc = "Optional. Type lat, lon to override location (e.g. 29.7604, -95.3698).",
                icon = "mapPin",
                default = "",
            ),
            schema.Dropdown(
                id = "zoom",
                name = "Map width (Miles)",
                desc = "Approximate width of visible radar map in miles.",
                icon = "magnifyingGlass",
                default = "7",
                options = [
                    schema.Option(display = "~1,200 miles (Multi-State)", value = "4"),
                    schema.Option(display = "~600 miles (State)", value = "5"),
                    schema.Option(display = "~300 miles (Region)", value = "6"),
                    schema.Option(display = "~150 miles (Metro)", value = "7"),
                    schema.Option(display = "~75 miles (County)", value = "8"),
                    schema.Option(display = "~35 miles (City)", value = "9"),
                ],
            ),
            schema.Dropdown(
                id = "frames",
                name = "Animation frames",
                desc = "How many ~10-minute radar scans to loop. 6 is about an hour.",
                icon = "clapperboard",
                default = "6",
                options = [
                    schema.Option(display = "3 (30 min)", value = "3"),
                    schema.Option(display = "6 (1 hour)", value = "6"),
                    schema.Option(display = "9 (90 min)", value = "9"),
                ],
            ),
            schema.Dropdown(
                id = "color",
                name = "Color scheme",
                desc = "RainViewer radar color palette.",
                icon = "palette",
                default = "6",
                options = [
                    schema.Option(display = "NEXRAD", value = "6"),
                    schema.Option(display = "Universal Blue", value = "2"),
                    schema.Option(display = "Original", value = "1"),
                    schema.Option(display = "The Weather Channel", value = "4"),
                    schema.Option(display = "Rainbow", value = "7"),
                    schema.Option(display = "Dark Sky", value = "8"),
                ],
            ),
            schema.Dropdown(
                id = "delay",
                name = "Animation speed",
                desc = "How long each radar frame stays on screen.",
                icon = "gaugeHigh",
                default = "400",
                options = [
                    schema.Option(display = "Slow", value = "700"),
                    schema.Option(display = "Normal", value = "400"),
                    schema.Option(display = "Fast", value = "250"),
                ],
            ),
            schema.Dropdown(
                id = "marker",
                name = "Location marker",
                desc = "Style/color of marker on target location.",
                icon = "locationCrosshairs",
                default = "red",
                options = [
                    schema.Option(display = "Red +", value = "red"),
                    schema.Option(display = "White +", value = "white"),
                    schema.Option(display = "Cyan +", value = "cyan"),
                    schema.Option(display = "Yellow +", value = "yellow"),
                    schema.Option(display = "Green +", value = "green"),
                    schema.Option(display = "Off", value = "off"),
                ],
            ),
        ],
    )
