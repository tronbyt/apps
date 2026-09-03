"""
RainRadar - Pixlet weather radar for a 64x32 Tronbyt.
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
ALERTS_TTL = 300
EARTH_HALF = 20037508.342789244
IMAGE_URL = "%s%s/256/%d/%s/%s/%d/1_1.png"

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
    frame_count = _clamp_int(config.get("frames", "2"), 2, 12, 2)
    delay = _clamp_int(config.get("delay", "400"), 150, 1200, 400)
    marker_style = config.get("marker", "red")
    time_format = config.get("time_format", "15:04")

    maps = http.get(MAPS_URL, ttl_seconds = MAPS_TTL)
    if maps.status_code != 200:
        return _error("Radar unavailable")

    alert_text = _nws_alert(loc["lat"], loc["lng"])

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
        rf = _radar_widget(host, path, zoom, loc["lat"], loc["lng"], color)
        if not rf:
            continue
        stamp = _stamp(frame.get("time"), loc["timezone"], time_format)
        images.append(_hud_frame(rf, loc["label"], stamp, alert_text))

    if not images:
        return _error("No radar image")

    # Hold the latest scan a beat so the current picture is readable.
    anim_children = images + [images[-1], images[-1]]

    marker_w = _marker(32, 16, marker_style)
    stack_children = [
        render.Box(width = 64, height = 32, color = "#020617"),
        _satellite_crop(loc["lat"], loc["lng"], zoom),
        render.Animation(children = anim_children),
    ]
    if marker_w:
        stack_children.append(marker_w)
    if alert_text:
        stack_children.append(render.Box(width = 64, height = 1, color = "#EF4444"))
        stack_children.append(render.Padding(pad = (0, 31, 0, 0), child = render.Box(width = 64, height = 1, color = "#EF4444")))
        stack_children.append(render.Box(width = 1, height = 32, color = "#EF4444"))
        stack_children.append(render.Padding(pad = (63, 0, 0, 0), child = render.Box(width = 1, height = 32, color = "#EF4444")))

    return render.Root(
        delay = delay,
        max_age = 600,
        child = render.Box(width = 64, height = 32, child = render.Stack(children = stack_children)),
    )

def _hud_frame(radar, label, stamp, alert_text):
    right = stamp if stamp else "RADAR"
    if alert_text:
        left = render.Marquee(
            width = 40,
            child = render.Text(alert_text, font = "tom-thumb", color = "#FCA5A5"),
        )
    else:
        left = render.Text(label, font = "tom-thumb", color = "#86EFAC")
    return render.Box(
        width = 64,
        height = 32,
        child = render.Stack(
            children = [
                radar,
                render.Column(
                    expanded = True,
                    main_align = "start",
                    children = [
                        render.Padding(
                            pad = (1, 1, 1, 0),
                            child = render.Box(
                                height = 7,
                                color = "#0001",
                                child = render.Padding(
                                    pad = (1, 0, 1, 0),
                                    child = render.Row(
                                        expanded = True,
                                        main_align = "space_between",
                                        cross_align = "center",
                                        children = [
                                            left,
                                            render.Text(right, font = "tom-thumb", color = "#E5E7EB"),
                                        ],
                                    ),
                                ),
                            ),
                        ),
                    ],
                ),
            ],
        ),
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

def _fmt_coord(value):
    # Starlark has no "%.4f"; RainViewer widget URLs require a decimal point.
    scaled = int(math.round(value * 10000.0))
    sign = ""
    if scaled < 0:
        sign = "-"
        scaled = -scaled
    whole = scaled // 10000
    frac = scaled % 10000
    frac_s = ("0000" + str(frac))[-4:]
    return sign + str(whole) + "." + frac_s

def _crop64(src):
    return render.Padding(
        pad = (0, -16, 0, 0),
        child = render.Image(src = src, width = 64, height = 64),
    )

def _radar_widget(host, path, zoom, lat, lng, color):
    url = IMAGE_URL % (host, path, zoom, _fmt_coord(lat), _fmt_coord(lng), color)
    tile = http.get(url, ttl_seconds = TILE_TTL)
    if tile.status_code != 200 or not tile.body():
        return None
    return _crop64(tile.body())

def _web_mercator(lat, lng, zoom):
    n = math.pow(2.0, zoom)
    tile_m = (2 * EARTH_HALF) / n
    half = tile_m / 2
    mx = lng * EARTH_HALF / 180.0
    my = math.log(math.tan((90.0 + lat) * math.pi / 360.0)) / (math.pi / 180.0) * EARTH_HALF / 180.0
    return mx, my, half

def _satellite_crop(lat, lng, zoom):
    mx, my, half = _web_mercator(lat, lng, zoom)
    xmin = mx - half
    ymin = my - half
    xmax = mx + half
    ymax = my + half
    url = "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/export?bbox=%f,%f,%f,%f&bboxSR=3857&imageSR=3857&size=64,64&format=jpg&f=image" % (xmin, ymin, xmax, ymax)
    res = http.get(
        url,
        ttl_seconds = BASEMAP_TTL,
        headers = {"User-Agent": "RainRadar-Pixlet/1.0 (personal)"},
    )
    if res.status_code != 200 or not res.body():
        return render.Box(width = 64, height = 32, color = "#020617")
    return _crop64(res.body())

def _nws_alert(lat, lng):
    url = "https://api.weather.gov/alerts/active?point=%s,%s&status=actual" % (
        _fmt_coord(lat),
        _fmt_coord(lng),
    )
    res = http.get(
        url,
        ttl_seconds = ALERTS_TTL,
        headers = {
            "User-Agent": "RainRadar-Pixlet/1.0 (sgmorton@gmail.com)",
            "Accept": "application/geo+json",
        },
    )
    if res.status_code != 200 or not res.body():
        return ""
    data = res.json()
    if type(data) != "dict":
        return ""
    features = data.get("features")
    if type(features) != "list" or len(features) < 1:
        return ""
    first = features[0]
    if type(first) != "dict":
        return "ALERT"
    props = first.get("properties")
    if type(props) != "dict":
        return "ALERT"
    headline = props.get("headline") or props.get("event") or "ALERT"
    if type(headline) != "string" or not headline:
        return "ALERT"
    return headline

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

    loc_key = locality.strip().upper()
    skip_geo = loc_key == "HOUSTON" or loc_key == "HOUSTON, TX"

    if not skip_geo:
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
                desc = "How many ~10-minute radar scans to loop. 2 is about 20 minutes.",
                icon = "clapperboard",
                default = "2",
                options = [
                    schema.Option(display = "2 (20 min)", value = "2"),
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
