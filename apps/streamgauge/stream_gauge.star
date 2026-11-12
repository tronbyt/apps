"""
Applet: Stream Gauge
Summary: River level history and forecast
Description: Water level at one or two USGS stream gauges: the last few days of readings, the National Weather Service forecast where there is one, and a flood screen that takes over when the river is forecast to reach flood stage.
Author: tscott98
"""

load("encoding/csv.star", "csv")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

# Readings: USGS Water Data API (https://api.waterdata.usgs.gov/)
USGS_API = "https://api.waterdata.usgs.gov/ogcapi/v0/collections"
USGS_SQUID = "https://api.waterdata.usgs.gov/squid/monitoring-locations"

# Nearby-gauge picker (schema.LocationBased)
GAUGE_SEARCH_RADIUS_KM = 25
GAUGE_PICKER_LIMIT = 50
GAUGE_PICKER_TTL = 86400
STREAM_SITE_TYPES = ["ST", "ST-CA", "ST-DCH", "ST-TS", "LK"]

# LocationBased handlers run on Tronbyt only; pixlet serve uses a fixed-location dropdown.
production = True
debug_site_selection = False
default_location = """{
	"lat": "30.674",
	"lng": "-96.370",
	"description": "Bryan, TX, USA",
	"timezone": "America/Chicago"
}"""

def debug_site(msg):
    if debug_site_selection:
        print("streamgauge site: " + msg)

# Forecasts and flood stages: NOAA National Water Prediction Service (https://api.water.noaa.gov/nwps/v1/docs/)
NWPS_API = "https://api.water.noaa.gov/nwps/v1"

DEFAULT_SITE = "08108700"  # Brazos River near Bryan, TX

# USGS parameter codes
PARAM_STAGE = "00065"  # gage height, ft
PARAM_FLOW = "00060"  # discharge, cfs

# Gauges report every 5-15 minutes; NWS forecasts are issued a few times a day
READINGS_TTL = 900
FORECAST_TTL = 1800
NAME_TTL = 86400

# A latest reading older than this is shown dimmed
STALE_SECONDS = 3 * 3600

# Rising or falling: change over this window larger than TREND_FT
TREND_SECONDS = 3 * 3600
TREND_FT = 0.1

# Smallest y-range for the chart, so a few hundredths of a foot of noise doesn't look like a flood
MIN_SPAN_FT = 0.5

# Seconds per screen when there's more than one (two gauges, or a flood screen)
SLIDE_SECONDS = 7

# The gauge or an API is down briefly; skip this render rather than show an error
TRANSIENT_STATUSES = [0, 429, 500, 502, 503, 504]

COLOR_LABEL = "#9AA0A6"
COLOR_VALUE = "#FFFFFF"
COLOR_STALE = "#555A60"
COLOR_TREND = "#7FD1FF"
COLOR_OBS_LINE = "#4FB3FF"
COLOR_OBS_FILL = "#0B3A66"
COLOR_FORECAST = "#FFB020"
COLOR_NOW = "#5F6368"
COLOR_DIVIDER = "#24272D"
COLOR_ERROR = "#FF8C00"
COLOR_BAND_TEXT = "#000000"
COLOR_CLEAR = "#00000000"

# NWS flood categories, lowest first, with the colors NWS hydrographs use
FLOOD_LEVELS = [
    {"rank": 0, "key": "action", "name": "NEAR FLOOD", "color": "#FFE14D"},
    {"rank": 1, "key": "minor", "name": "MINOR FLOOD", "color": "#FF8C00"},
    {"rank": 2, "key": "moderate", "name": "MODERATE FLOOD", "color": "#FF2828"},
    {"rank": 3, "key": "major", "name": "MAJOR FLOOD", "color": "#C040FF"},
]

# NWPS reports POSIX time zones; used for crest times only when the device has none set
NWPS_ZONES = {
    "EST5EDT": "America/New_York",
    "CST6CDT": "America/Chicago",
    "MST7MDT": "America/Denver",
    "MST7": "America/Phoenix",
    "PST8PDT": "America/Los_Angeles",
    "AKST9AKDT": "America/Anchorage",
    "HST10": "Pacific/Honolulu",
}

# Words shortened or dropped when making a label from the gauge name
NAME_WORDS = {
    "RIVER": "",
    "RV": "",
    "R": "",
    "THE": "",
    "NEAR": "NR",
    "CREEK": "CK",
    "FORK": "FK",
    "NORTH": "N",
    "SOUTH": "S",
    "EAST": "E",
    "WEST": "W",
}

# --- Formatting ---

def fixed(v, decimals):
    # "%.2f" without relying on format precision support
    p = [1, 10, 100][decimals]
    neg = v < 0
    n = int(math.round(abs(v) * p))
    s = str(n // p)
    if decimals > 0:
        frac = str(n % p)
        s += "." + "0" * (decimals - len(frac)) + frac
    return ("-" + s) if neg and n > 0 else s

def format_stage(v):
    if abs(v) < 10:
        return fixed(v, 2)
    elif abs(v) < 100:
        return fixed(v, 1)
    return fixed(v, 0)

def format_flow(cfs):
    if cfs < 10000:
        return str(int(math.round(cfs)))
    elif cfs < 100000:
        return fixed(cfs / 1000.0, 1) + "K"
    return str(int(math.round(cfs / 1000.0))) + "K"

def text_width(s, font):
    return render.Text(s, font = font).size()[0]

def fit_text(candidates, font, max_w):
    # First candidate that fits, else the last one
    for s in candidates:
        if text_width(s, font) <= max_w:
            return s
    return candidates[-1]

def fit_label(label, font, max_w):
    # Drop trailing words, then trailing characters, until the label fits
    words = label.split(" ")
    for _ in range(len(words)):
        if len(words) == 1 or text_width(" ".join(words), font) <= max_w:
            break
        words = words[:-1]
    s = " ".join(words)
    for _ in range(len(s)):
        if len(s) <= 1 or text_width(s, font) <= max_w:
            break
        s = s[:-1]
    return s

def short_name(name):
    # "Brazos River near Bryan" -> "BRAZOS NR BRYAN"; "BRAZOS RV AT SH 21 NR BRYAN, TX" -> "BRAZOS AT SH 21 NR BRYAN"
    words = []
    for w in name.split(",")[0].upper().replace(".", "").split(" "):
        if not w:
            continue
        w = NAME_WORDS.get(w, w)
        if w:
            words.append(w)
    return " ".join(words) if words else name.upper()

# --- Site IDs ---

def parse_site_id(raw):
    # Accepts "08108700", "USGS-08108700", or a waterdata.usgs.gov page link
    s = (raw or "").strip().upper()
    i = s.find("USGS-")
    if i >= 0:
        s = s[i + 5:]
    run = ""
    for c in s.elems():
        if c.isdigit():
            run += c
        elif run:
            if len(run) >= 8:
                break
            run = ""
    if len(run) >= 8 and len(run) <= 15:
        return run
    return None

def gauge_bounding_box(lat, lng, radius_km):
    R = 6371.0
    lat_r = math.radians(lat)
    dlat = math.degrees(radius_km / R)
    dlng = math.degrees(radius_km / R / math.cos(lat_r))
    return (lng - dlng, lat - dlat, lng + dlng, lat + dlat)

def haversine_km(lat1, lng1, lat2, lng2):
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = math.pow(math.sin(dlat / 2), 2) + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.pow(math.sin(dlng / 2), 2)
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

def has_stage_reading(props):
    for p in props.get("observedParameters") or []:
        if p == PARAM_STAGE:
            return True
    return False

def build_squid_gauge_url(bbox, since_date):
    min_lng, min_lat, max_lng, max_lat = bbox
    query = "mimeType=application/json&pageSize=%d" % GAUGE_PICKER_LIMIT
    query += "&boundingBox=%s,%s,%s,%s" % (min_lng, min_lat, max_lng, max_lat)
    query += "&dataCollectedSinceDatetime=" + since_date
    query += "&dataType=Continuous%20values"
    for code in STREAM_SITE_TYPES:
        query += "&siteTypeCode=" + code
    return USGS_SQUID + "?" + query

def fetch_squid_gauges(lat, lng):
    since_date = (time.now() - time.parse_duration("8760h")).format("2006-01-02")
    bbox = gauge_bounding_box(lat, lng, GAUGE_SEARCH_RADIUS_KM)
    resp = http.get(build_squid_gauge_url(bbox, since_date), ttl_seconds = GAUGE_PICKER_TTL)
    if resp.status_code != 200:
        return []

    seen = {}
    rows = []
    for f in (resp.json() or {}).get("features") or []:
        props = f.get("properties") or {}
        if not has_stage_reading(props):
            continue
        site = parse_site_id(props.get("monitoringLocationIdentifier"))
        if not site or site in seen:
            continue
        geom = f.get("geometry") or {}
        coords = geom.get("coordinates") or []
        if len(coords) < 2:
            continue
        glng = float(coords[0])
        glat = float(coords[1])
        name = props.get("monitoringLocationName") or ("USGS " + site)
        rows.append({
            "site": site,
            "name": name,
            "dist": haversine_km(lat, lng, glat, glng),
        })
        seen[site] = True
    return sorted(rows, key = lambda r: r["dist"])

def gauge_picker_label(site, name):
    label = short_name(name)
    if not label:
        label = name
    if len(label) > 36:
        label = label[:36]
    return site + " — " + label

def get_nearby_gauges(location):
    loc = json.decode(location)
    lat = float(loc["lat"])
    lng = float(loc["lng"])
    place = loc.get("description") or (loc.get("lat") + "," + loc.get("lng"))
    rows = fetch_squid_gauges(lat, lng)
    if not rows:
        debug_site('picker search at "%s": no gauges in bbox' % place)
        return [
            schema.Option(
                display = "No gauges found — use site number below",
                value = "",
            ),
        ]
    options = []
    for row in rows:
        options.append(schema.Option(
            display = gauge_picker_label(row["site"], row["name"]),
            value = row["site"],
        ))
    debug_site('picker search at "%s": %d gauge(s)' % (place, len(options)))
    return options

def picker_site_value(raw):
    raw = (raw or "").strip()
    if not raw:
        return None
    if raw.startswith("{"):
        raw = (json.decode(raw).get("value") or "").strip()
    if not raw:
        return None
    return parse_site_id(raw)

def resolve_site(config, manual_key, picker_key, default):
    manual = (config.get(manual_key) or "").strip()
    if manual:
        site = parse_site_id(manual)
        if site == None:
            debug_site("%s: invalid manual entry %r" % (picker_key, manual))
            return None, True
        debug_site("%s: manual override -> %s" % (picker_key, site))
        return site, False
    picker_raw = (config.get(picker_key) or "").strip()
    site = picker_site_value(picker_raw)
    if site:
        display = ""
        if picker_raw.startswith("{"):
            display = (json.decode(picker_raw).get("display") or "").strip()
        if display:
            debug_site('%s: picker -> %s ("%s")' % (picker_key, site, display))
        else:
            debug_site("%s: picker -> %s" % (picker_key, site))
        return site, False
    if default:
        debug_site("%s: default -> %s" % (picker_key, default))
        return default, False
    debug_site("%s: none selected" % picker_key)
    return None, False

# --- Data ---

def parse_time_csv(s):
    # "2026-11-02 00:00:00+00:00" today; also accepts the JSON form ("T" separator, "Z")
    # and fractional seconds. Returns None for anything else, since a parse error would
    # fail the whole render (Starlark can't catch it).
    s = s.strip()
    if len(s) < 20 or s[4] != "-" or s[7] != "-" or s[10] not in " T" or s[13] != ":" or s[16] != ":":
        return None
    if not (s[:4] + s[5:7] + s[8:10] + s[11:13] + s[14:16] + s[17:19]).isdigit():
        return None
    zone = s[19:].lstrip(".0123456789")
    if zone != "Z" and not (len(zone) == 6 and zone[0] in "+-" and zone[3] == ":" and (zone[1:3] + zone[4:6]).isdigit()):
        return None
    return time.parse_time(s[:10] + " " + s[11:], format = "2006-01-02 15:04:05Z07:00").unix

def is_number(s):
    # Plain decimal like "8.17" or "-0.5"; float() would fail the render on anything else
    body = s[1:] if s.startswith("-") else s
    parts = body.split(".")
    if len(parts) > 2 or not "".join(parts).isdigit():
        return False
    return True

def fetch_usgs_series(site, param, period):
    # Returns ([(unix, value)], status). CSV is a tenth the size of the GeoJSON.
    resp = http.get(
        "%s/continuous/items" % USGS_API,
        params = {
            "f": "csv",
            "monitoring_location_id": "USGS-" + site,
            "parameter_code": param,
            "time": period,
            "limit": "5000",
            "properties": "time,value",
            "skipGeometry": "true",
        },
        ttl_seconds = READINGS_TTL,
    )
    if resp.status_code != 200:
        return None, resp.status_code

    rows = csv.read_all(resp.body()) if resp.body() else []
    if len(rows) < 2:
        return [], 200
    header = rows[0]
    if "time" not in header or "value" not in header:
        return [], 200
    ti = header.index("time")
    vi = header.index("value")

    points = []
    for row in rows[1:]:
        if len(row) <= ti or len(row) <= vi or not row[ti] or not row[vi]:
            continue
        v = row[vi].strip()
        t = parse_time_csv(row[ti])
        if t == None or not is_number(v):
            continue
        points.append((t, float(v)))
    return sorted(points, key = lambda p: p[0]), 200

def fetch_usgs_name(site):
    resp = http.get(
        "%s/monitoring-locations/items/USGS-%s" % (USGS_API, site),
        params = {"f": "json", "skipGeometry": "true"},
        ttl_seconds = NAME_TTL,
    )
    if resp.status_code != 200:
        return None
    props = resp.json().get("properties") or {}
    return props.get("monitoring_location_name")

def fetch_nwps_gauge(site):
    # Returns (gauge, status). NWPS looks gauges up by USGS site number. 404 means NWS
    # doesn't track this gauge: no forecast and no flood stages, but the readings still work.
    resp = http.get("%s/gauges/%s" % (NWPS_API, site), ttl_seconds = READINGS_TTL)
    if resp.status_code != 200:
        return None, resp.status_code
    return resp.json(), 200

def fetch_nwps_forecast(lid):
    resp = http.get("%s/gauges/%s/stageflow/forecast" % (NWPS_API, lid), ttl_seconds = FORECAST_TTL)
    if resp.status_code != 200:
        return []
    points = []
    for d in resp.json().get("data") or []:
        v = d.get("primary")
        t = d.get("validTime")
        if v == None or t == None or v < -900:
            continue
        points.append((time.parse_time(t).unix, float(v)))
    return sorted(points, key = lambda p: p[0])

def flood_levels(nwps):
    # [(stage_ft, level)] for the categories this gauge has, lowest first
    cats = (((nwps or {}).get("flood") or {}).get("categories")) or {}
    if ((nwps or {}).get("flood") or {}).get("stageUnits", "ft") != "ft":
        return []
    levels = []
    for lvl in FLOOD_LEVELS:
        stage = (cats.get(lvl["key"]) or {}).get("stage")
        if stage != None and stage > -900:
            levels.append((float(stage), lvl))
    return levels

def nwps_flow(nwps):
    obs = (((nwps or {}).get("status") or {}).get("observed")) or {}
    v = obs.get("secondary")
    if v == None or v < 0:
        return None
    unit = obs.get("secondaryUnit", "")
    if unit == "kcfs":
        return v * 1000.0
    elif unit == "cfs":
        return float(v)
    return None

def load_gauge(site, label, days, now_unix):
    # Returns (gauge, status). gauge is None when there's nothing to show.
    obs, status = fetch_usgs_series(site, PARAM_STAGE, "P%dD" % days)
    if obs == None:
        return None, status
    if not obs:
        return None, 404

    nwps, nwps_status = fetch_nwps_gauge(site)
    if nwps_status in TRANSIENT_STATUSES:
        # NWPS is down, not "this gauge has no forecast". Showing the readings alone would
        # silently drop the flood stages and change the label, so treat it like any other
        # brief outage.
        return None, nwps_status
    forecast = []
    if nwps and nwps.get("lid"):
        forecast = fetch_nwps_forecast(nwps["lid"])

    flow = nwps_flow(nwps)
    if flow == None:
        flows, _ = fetch_usgs_series(site, PARAM_FLOW, "PT3H")
        if flows:
            flow = flows[-1][1]

    name = (nwps or {}).get("name") or fetch_usgs_name(site) or ("USGS " + site)
    return make_gauge(
        site = site,
        label = label or short_name(name),
        obs = obs,
        forecast = forecast,
        flow = flow,
        levels = flood_levels(nwps),
        zone = NWPS_ZONES.get((nwps or {}).get("timeZone", "")),
        now_unix = now_unix,
    ), 200

def make_gauge(site, label, obs, forecast, flow, levels, zone, now_unix):
    latest_t, latest = obs[-1]
    stale = now_unix - latest_t > STALE_SECONDS

    # Forecast points after the latest reading. The chart shows no more forecast than it
    # shows history; the crest and flood alert use all of it.
    forecast = [p for p in forecast if p[0] > latest_t]
    horizon = latest_t + max(latest_t - obs[0][0], 86400)
    chart_forecast = [p for p in forecast if p[0] <= horizon]

    # Trend over the last few hours
    before = None
    for t, v in obs:
        if t <= latest_t - TREND_SECONDS:
            before = v
    trend = 0
    if before != None and latest - before > TREND_FT:
        trend = 1
    elif before != None and before - latest > TREND_FT:
        trend = -1

    # Highest forecast point still ahead of the clock, if it's above the current level.
    # When the gauge has stopped reporting, forecast points between its last reading and
    # now have already happened, so they can't be the crest.
    crest = None
    for p in forecast:
        if p[0] > now_unix and p[1] > latest + 0.05 and (crest == None or p[1] > crest[1]):
            crest = p

    return {
        "site": site,
        "label": label,
        "obs": obs,
        "forecast": forecast,
        "chart_forecast": chart_forecast,
        "latest_t": latest_t,
        "latest": latest,
        "stale": stale,
        "trend": trend,
        "crest": crest,
        "flow": flow,
        "levels": levels,
        "zone": zone,
    }

def category(stage, levels):
    # Highest flood level at or below this stage, or None
    found = None
    for lvl_stage, lvl in levels:
        if stage >= lvl_stage:
            found = (lvl_stage, lvl)
    return found

def alert_rank(gauge):
    # 0 for action stage up to 3 for major flooding; -1 when there's no alert
    cat = alert_category(gauge)
    return cat[1]["rank"] if cat != None else -1

def alert_category(gauge):
    # Worst flood level now or in the forecast. A stale reading isn't "now", so it only
    # counts while it's fresh.
    peak = None if gauge["stale"] else gauge["latest"]
    if gauge["crest"] != None and (peak == None or gauge["crest"][1] > peak):
        peak = gauge["crest"][1]
    if peak == None:
        return None
    return category(peak, gauge["levels"])

def demo_gauge(now_unix, days):
    # Synthetic flood, for previewing the flood screen: `pixlet render stream_gauge.star demo=flood`
    step = 900
    count = days * 86400 // step
    obs = []
    for i in range(count):
        t = now_unix - (count - 1 - i) * step
        x = i / float(count - 1)
        v = 12.0 + 0.3 * math.sin(i / 40.0)
        if x > 0.6:
            r = (x - 0.6) / 0.4
            v += 27.0 * r * r
        obs.append((t, v))
    forecast = []
    for h in range(6, 5 * 24 + 1, 6):
        if h <= 60:
            v = 39.0 + 15.2 * math.sin(h / 60.0 * math.pi / 2)
        else:
            v = 54.2 - 0.18 * (h - 60)
        forecast.append((now_unix + h * 3600, v))
    levels = [(37.0, FLOOD_LEVELS[0]), (52.0, FLOOD_LEVELS[1]), (60.0, FLOOD_LEVELS[2]), (66.0, FLOOD_LEVELS[3])]
    return make_gauge("08108700", "BRAZOS NR BRYAN", obs, forecast, 61200.0, levels, "America/Chicago", now_unix)

# --- Drawing ---

def layout():
    if canvas.is2x():
        return {
            "s": 2,
            "small": "terminus-12",
            "small_h": 12,
            "small_ascent": 10,
            "mid": "terminus-16",
            "big": "terminus-24",
            "big_h": 24,
            "big_ascent": 19,
        }
    return {
        "s": 1,
        "small": "tom-thumb",
        "small_h": 6,
        "small_ascent": 5,
        "mid": "tb-8",
        "big": "6x13",
        "big_h": 13,
        "big_ascent": 11,
    }

def arrow(direction, color, s):
    # 5x5 arrow (scaled); a short dash when steady
    if direction > 0:
        widths = [1, 3, 5, 1, 1]
    elif direction < 0:
        widths = [1, 1, 5, 3, 1]
    else:
        widths = [0, 0, 3, 0, 0]
        color = COLOR_LABEL
    rows = []
    for n in widths:
        if n == 0:
            rows.append(render.Box(width = 5 * s, height = s))
        else:
            rows.append(render.Box(width = 5 * s, height = s, child = render.Box(width = n * s, height = s, color = color)))
    return render.Column(children = rows)

def hline(w, color, dashed):
    if not dashed:
        return render.Box(width = w, height = 1, color = color)

    # Transparent gaps, so a line drawn behind the readings stays hidden under the water
    segs = []
    for i in range(w):
        segs.append(render.Box(width = 1, height = 1, color = color if i % 3 == 0 else COLOR_CLEAR))
    return render.Row(children = segs)

def vline_dotted(h, color):
    return render.Column(children = [render.Box(width = 1, height = 1, color = color if i % 2 == 0 else COLOR_CLEAR) for i in range(h)])

def downsample(points, t0, t1, n):
    # Average into n time slots so the plot has at most one point per column
    span = float(t1 - t0)
    if span <= 0:
        # A single reading (or several at one instant): nothing to spread across columns
        return [p for p in points if p[0] == t0]
    sums = [0.0] * n
    counts = [0] * n
    for t, v in points:
        if t < t0 or t > t1:
            continue
        i = min(n - 1, int((t - t0) / span * n))
        sums[i] += v
        counts[i] += 1
    out = []
    for i in range(n):
        if counts[i] > 0:
            out.append((t0 + (i + 0.5) * span / n, sums[i] / counts[i]))
    return out

def value_color(gauge, now_unix):
    if now_unix - gauge["latest_t"] > STALE_SECONDS:
        return COLOR_STALE
    cat = category(gauge["latest"], gauge["levels"])
    if cat != None:
        return cat[1]["color"]
    return COLOR_VALUE

def chart(gauge, w, h, flood_view = False):
    # Hydrograph: readings filled blue, forecast in amber, dotted "now" line, dashed flood stages
    # The flood view shows the whole forecast, so the crest is on the chart even when
    # it's further out than the history goes back
    t_now = gauge["latest_t"]
    t0 = gauge["obs"][0][0]
    upcoming = gauge["forecast"] if flood_view else gauge["chart_forecast"]
    t1 = upcoming[-1][0] if upcoming else t_now
    if t1 <= t0:
        t1 = t0 + 1

    obs = downsample(gauge["obs"], t0, t_now, w)
    obs.append((t_now, gauge["latest"]))
    forecast = [(t_now, gauge["latest"])] + upcoming

    values = [v for _, v in obs] + [v for _, v in forecast]
    lo = min(values)
    hi = max(values)

    if flood_view:
        # Show the flood stages already reached, and the next one up
        for lvl_stage, _ in gauge["levels"]:
            if lvl_stage <= hi:
                lo = min(lo, lvl_stage)
            else:
                hi = lvl_stage
                break

    span = max(hi - lo, MIN_SPAN_FT)
    mid = (hi + lo) / 2.0
    lo = mid - span * 0.6
    hi = mid + span * 0.6

    def x(t):
        return (t - t0) / 3600.0

    # Flood stages go behind the readings, so the water hides the stages it has passed
    layers = []
    for lvl_stage, lvl in gauge["levels"]:
        if lvl_stage > lo and lvl_stage < hi:
            y = int(math.round((hi - lvl_stage) / (hi - lo) * (h - 1)))
            layers.append(render.Padding(pad = (0, y, 0, 0), child = hline(w, lvl["color"], True)))

    layers.append(
        render.Plot(
            data = [(x(t), v) for t, v in obs],
            width = w,
            height = h,
            color = COLOR_OBS_LINE,
            fill = True,
            fill_color = COLOR_OBS_FILL,
            x_lim = (0, x(t1)),
            y_lim = (lo, hi),
        ),
    )

    if len(forecast) > 1:
        now_x = int(math.round(x(t_now) / x(t1) * (w - 1)))
        layers.append(render.Padding(pad = (now_x, 0, 0, 0), child = vline_dotted(h, COLOR_NOW)))
        layers.append(render.Plot(
            data = [(x(t), v) for t, v in forecast],
            width = w,
            height = h,
            color = COLOR_FORECAST,
            x_lim = (0, x(t1)),
            y_lim = (lo, hi),
        ))

    return render.Stack(children = layers)

def glance_screen(gauge, now_unix):
    # Screen A: label, big stage with trend, flow, and the hydrograph strip
    L = layout()
    s = L["s"]
    w, h = canvas.size()

    label = render.Text(fit_label(gauge["label"], L["small"], w), font = L["small"], color = COLOR_LABEL)

    stage = render.Text(format_stage(gauge["latest"]), font = L["big"], color = value_color(gauge, now_unix))
    unit_top = L["big_ascent"] - L["small_ascent"]
    unit = render.Column(children = [
        render.Box(width = 5 * s, height = unit_top, child = arrow(gauge["trend"], COLOR_TREND, s)),
        render.Text("FT", font = L["small"], color = COLOR_LABEL),
    ])
    left = render.Row(cross_align = "start", children = [stage, render.Box(width = s, height = 1), unit])

    right = render.Box(width = 1, height = 1)
    if gauge["flow"] != None:
        # Flow sits in the same rows as the arrow and FT; a zero-size Box would expand, so pad only when needed
        value_top = max(0, unit_top - L["small_h"])
        flow_rows = [
            render.Text(format_flow(gauge["flow"]), font = L["small"], color = COLOR_VALUE),
            render.Text("CFS", font = L["small"], color = COLOR_LABEL),
        ]
        if value_top > 0:
            flow_rows = [render.Box(width = 1, height = value_top)] + flow_rows
        right = render.Column(cross_align = "end", children = flow_rows)

    chart_h = h - L["small_h"] - L["big_h"] - s
    return render.Column(children = [
        render.Box(width = w, height = L["small_h"], child = render.Row(expanded = True, children = [label])),
        render.Box(width = w, height = L["big_h"], child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "start",
            children = [left, right],
        )),
        render.Box(width = w, height = s),
        chart(gauge, w, chart_h),
    ])

def flood_screen(gauge, now_unix, tz):
    # Screen C: gauge name on a band in the flood color, flood level, crest, and the hydrograph with flood stages
    L = layout()
    s = L["s"]
    w, h = canvas.size()
    cat = alert_category(gauge)
    lvl = cat[1]
    band_h = L["small_h"] + s

    band = render.Box(
        width = w,
        height = band_h,
        color = lvl["color"],
        child = render.Text(fit_label(gauge["label"], L["small"], w - 2 * s), font = L["small"], color = COLOR_BAND_TEXT),
    )

    level_text = render.Text(fit_label(lvl["name"], L["small"], w), font = L["small"], color = lvl["color"])

    crest = gauge["crest"]
    if crest != None and crest[1] >= cat[0]:
        when = time.from_timestamp(int(crest[0])).in_location(tz)
        today = time.from_timestamp(now_unix).in_location(tz)
        day = "TODAY" if when.format("2006-01-02") == today.format("2006-01-02") else when.format("Mon").upper()
        hour = when.format("3PM")
        v = format_stage(crest[1])
        detail_str = fit_text([
            "CREST %s %s %s" % (v, day, hour),
            "CREST %s %s" % (v, day),
            "%s %s %s" % (v, day, hour),
            "%s %s" % (v, day),
        ], L["small"], w)
        detail = render.Text(detail_str, font = L["small"], color = COLOR_VALUE)
    else:
        detail = render.Row(cross_align = "center", children = [
            render.Text("NOW %s FT" % format_stage(gauge["latest"]), font = L["small"], color = value_color(gauge, now_unix)),
            render.Box(width = s, height = 1),
            arrow(gauge["trend"], COLOR_TREND, s),
        ])

    chart_h = h - band_h - s - 2 * L["small_h"] - s
    return render.Column(children = [
        band,
        render.Box(width = w, height = s),
        render.Box(width = w, height = L["small_h"], child = render.Row(expanded = True, children = [level_text])),
        render.Box(width = w, height = L["small_h"], child = render.Row(expanded = True, children = [detail])),
        render.Box(width = w, height = s),
        chart(gauge, w, chart_h, flood_view = True),
    ])

def stub_message(status):
    if status == 404:
        return "NO READINGS"
    elif status in TRANSIENT_STATUSES:
        return "NO RESPONSE"
    return "ERROR %d" % status

def pair_row(gauge, w, h, now_unix):
    # One half of screen D: label and stage on the left, sparkline on the right
    L = layout()
    s = L["s"]
    left_w = w // 2
    chart_w = w - left_w - s

    if gauge.get("error"):
        return render.Box(width = w, height = h, child = render.Padding(pad = (0, s, 0, 0), child = render.Column(expanded = True, children = [
            render.Row(expanded = True, children = [render.Text(fit_label(gauge["label"], L["small"], w), font = L["small"], color = COLOR_LABEL)]),
            render.Box(width = 1, height = s),
            render.Row(expanded = True, children = [render.Text(stub_message(gauge["error"]), font = L["small"], color = COLOR_STALE)]),
        ])))

    value = render.Row(cross_align = "center", children = [
        render.Text(format_stage(gauge["latest"]), font = L["mid"], color = value_color(gauge, now_unix)),
        render.Box(width = s, height = 1),
        arrow(gauge["trend"], COLOR_TREND, s),
    ])
    left = render.Column(children = [
        render.Text(fit_label(gauge["label"], L["small"], left_w - s), font = L["small"], color = COLOR_LABEL),
        render.Box(width = 1, height = s),
        value,
    ])
    return render.Row(children = [
        render.Box(width = left_w, height = h, child = render.Padding(pad = (0, s, 0, 0), child = render.Row(expanded = True, children = [left]))),
        render.Box(width = s, height = h),
        render.Padding(pad = (0, s, 0, s), child = chart(gauge, chart_w, h - 2 * s)),
    ])

def pair_screen(gauges, now_unix):
    # Screen D: two gauges, one per row
    s = layout()["s"]
    w, h = canvas.size()
    top_h = (h - s) // 2
    return render.Column(children = [
        pair_row(gauges[0], w, top_h, now_unix),
        render.Box(width = w, height = s, color = COLOR_DIVIDER),
        pair_row(gauges[1], w, h - top_h - s, now_unix),
    ])

def render_message(title, lines):
    L = layout()
    children = [render.Text(title, font = L["small"], color = COLOR_LABEL)]
    for line in lines:
        children.append(render.Text(line, font = L["small"], color = COLOR_ERROR))
    return render.Root(
        max_age = 300,
        child = render.Box(child = render.Column(main_align = "center", cross_align = "center", children = children)),
    )

# --- Main ---

def main(config):
    days_str = config.get("history_days") or "7"
    days = int(days_str) if days_str.isdigit() and int(days_str) > 0 else 7
    alert = config.get("alert_level", "action")
    now_unix = time.now().unix

    tz = config.get("$tz")
    pair = None

    if config.get("demo") == "flood":
        gauges = [demo_gauge(now_unix, days)]
    else:
        label1 = (config.get("label1") or "").strip().upper()
        label2 = (config.get("label2") or "").strip().upper()
        site1, bad1 = resolve_site(config, "site1", "site1_picker", DEFAULT_SITE)
        if bad1:
            return render_message("Stream Gauge", ["Site 1 should", "be a USGS", "site number"])
        site2, bad2 = resolve_site(config, "site2", "site2_picker", "")
        if bad2:
            return render_message("Stream Gauge", ["Site 2 should", "be a USGS", "site number"])

        sites = []
        if site1 and site1 not in [s[0] for s in sites]:
            sites.append((site1, label1))
        if site2 and site2 not in [s[0] for s in sites]:
            sites.append((site2, label2))
        if not sites:
            sites = [(DEFAULT_SITE, "")]

        for i, (site, label) in enumerate(sites):
            debug_site("using site %d: %s (label=%r)" % (i + 1, site, label))

        rows = []
        for site, label in sites:
            gauge, status = load_gauge(site, label, days, now_unix)
            if gauge == None:
                # A wrong site number, a gauge with no water level readings, or an API that's
                # briefly down. The other gauge, if any, still shows.
                gauge = {"error": status, "label": label or ("USGS " + site), "site": site}
            rows.append(gauge)

        gauges = [g for g in rows if not g.get("error")]
        if not gauges:
            g = rows[0]
            if g["error"] in TRANSIENT_STATUSES:
                # Keep showing the last good frame until the API recovers
                return []
            if g["error"] == 404:
                return render_message("USGS " + g["site"], ["No water level", "readings in", "%d days" % days])
            return render_message("USGS " + g["site"], ["API error", str(g["error"])])
        if len(rows) == 2:
            pair = rows

    if not tz:
        tz = gauges[0]["zone"] or "America/Chicago"

    # Which gauges get the flood screen
    min_alert = {"action": 0, "minor": 1}.get(alert, 99)
    flooding = [g for g in gauges if alert_rank(g) >= min_alert]

    if pair != None:
        screens = [pair_screen(pair, now_unix)] + [flood_screen(g, now_unix, tz) for g in flooding]
    elif flooding:
        screens = [flood_screen(gauges[0], now_unix, tz)]
    else:
        screens = [glance_screen(gauges[0], now_unix)]

    if len(screens) == 1:
        return render.Root(max_age = READINGS_TTL, child = screens[0])
    return render.Root(
        max_age = READINGS_TTL,
        delay = SLIDE_SECONDS * 1000,
        show_full_animation = True,
        child = render.Animation(children = screens),
    )

def gauge_picker_field(id, name, desc, optional = False):
    if production:
        return schema.LocationBased(
            id = id,
            name = name,
            desc = desc,
            icon = "locationDot",
            handler = get_nearby_gauges,
        )
    options = get_nearby_gauges(default_location)
    if not options:
        options = [schema.Option(display = DEFAULT_SITE, value = DEFAULT_SITE)]
    if optional:
        options = [schema.Option(display = "None", value = "")] + options
    return schema.Dropdown(
        id = id,
        name = name,
        desc = desc + " (local preview uses gauges near Bryan, TX).",
        icon = "locationDot",
        default = "" if optional else options[0].value,
        options = options,
    )

def get_schema():
    picker_desc = "Stream or lake gauges with recent stage data within about %d km of your location." % GAUGE_SEARCH_RADIUS_KM
    return schema.Schema(
        version = "1",
        fields = [
            gauge_picker_field(
                "site1_picker",
                "Nearby Gauge",
                picker_desc,
            ),
            schema.Text(
                id = "site1",
                name = "USGS Site Number",
                desc = "Optional override. 8 to 15 digits from waterdata.usgs.gov (for example 08108700), or paste the gauge page link.",
                icon = "water",
            ),
            schema.Text(
                id = "label1",
                name = "Label",
                desc = "Optional short name to show instead of the gauge's name",
                icon = "tag",
            ),
            gauge_picker_field(
                "site2_picker",
                "Second Nearby Gauge",
                "Optional. " + picker_desc,
                optional = True,
            ),
            schema.Text(
                id = "site2",
                name = "Second Site Number",
                desc = "Optional override for the second gauge.",
                icon = "water",
            ),
            schema.Text(
                id = "label2",
                name = "Second Label",
                desc = "Optional short name for the second gauge",
                icon = "tag",
            ),
            schema.Dropdown(
                id = "history_days",
                name = "History",
                desc = "How many days of readings the chart shows. The forecast, where there is one, adds up to as many days again.",
                icon = "calendarDays",
                default = "7",
                options = [
                    schema.Option(display = "3 days", value = "3"),
                    schema.Option(display = "7 days", value = "7"),
                    schema.Option(display = "14 days", value = "14"),
                ],
            ),
            schema.Dropdown(
                id = "alert_level",
                name = "Flood Screen",
                desc = "When to switch to the flood screen. Uses the gauge's National Weather Service flood stages, now or in the forecast.",
                icon = "houseFloodWater",
                default = "action",
                options = [
                    schema.Option(display = "Near flood stage (action stage)", value = "action"),
                    schema.Option(display = "Flood stage (minor flooding)", value = "minor"),
                    schema.Option(display = "Never", value = "off"),
                ],
            ),
        ],
    )
