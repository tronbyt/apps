"""
Applet: Air Gradient Graphs
Summary: AirGradient history as bar charts
Description: Bar charts of recent readings from an AirGradient monitor via Home Assistant or the AirGradient cloud API. Show up to six metrics on one screen, or one full-screen chart per slide.
Author: tscott98
"""

# Based on the AirGradient app by Brombomb, which shows the current readings.

load("http.star", "http")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

# Default AirGradient cloud API (https://api.airgradient.com/public/docs/api/v1/)
DEFAULT_AG_CLOUD_API = "https://api.airgradient.com/public/api/v1"

# The past-measures endpoint returns 5-minute buckets (hourly for older data)
BUCKET_SECONDS = 300

# Ranges longer than a day re-fetch every 15 minutes instead of every 5:
# each bar covers hours, so the chart barely changes between fetches.
LONG_RANGE_REFRESH_SECONDS = 900

# A latest reading older than this (beyond the refresh interval) is shown dimmed
STALE_SECONDS = 1800

# The monitor or the API is down briefly; skip this render rather than show an error
TRANSIENT_STATUSES = [0, 429, 500, 502, 503, 504]

# Level colors, matching the AirGradient LED bar
COLOR_GREEN = "#00E640"
COLOR_YELLOW = "#FFE600"
COLOR_ORANGE = "#FF8C00"
COLOR_RED = "#FF2828"
COLOR_PURPLE = "#B418FF"

COLOR_BG = "#000000"
COLOR_DIVIDER = "#24272D"
COLOR_LABEL = "#9AA0A6"
COLOR_STALE = "#555A60"
COLOR_BASELINE = "#8A929B"
COLOR_ABOVE_AVG = "#FF3B30"
COLOR_ERROR = "#FF8C00"

# Metric definitions.
#   short:    name used when the full name doesn't fit a small cell
#   fields:   API fields to read, first non-null wins (corrected values preferred)
#   color:    bar color when not colored by level
#   min_span: smallest y-range for Auto scale, so sensor noise isn't magnified
#   health:   y-range for the Fixed scale (Celsius for temperature)
#   floor:    values can't go below zero
METRICS = {
    "co2": {"name": "CO2", "short": "C", "fields": ["rco2_corrected", "rco2"], "color": "#4FC3F7", "min_span": 200, "health": (400, 2000), "floor": True},
    "pm25": {"name": "PM2.5", "short": "PM", "fields": ["pm02_corrected", "pm02"], "color": "#B39DDB", "min_span": 10, "health": (0, 55), "floor": True},
    "pm1": {"name": "PM1", "short": "P1", "fields": ["pm01_corrected", "pm01"], "color": "#9FA8DA", "min_span": 10, "health": (0, 55), "floor": True},
    "pm10": {"name": "PM10", "short": "P10", "fields": ["pm10_corrected", "pm10"], "color": "#CE93D8", "min_span": 20, "health": (0, 150), "floor": True},
    "temp": {"name": "Temp", "short": "T", "fields": ["atmp_corrected", "atmp"], "color": "#FFB74D", "min_span": 2, "health": (15, 30), "floor": False},
    "hum": {"name": "RH", "short": "H", "fields": ["rhum_corrected", "rhum"], "color": "#4DD0E1", "min_span": 10, "health": (0, 100), "floor": True},
    "voc": {"name": "VOC", "short": "V", "fields": ["tvocIndex"], "color": "#AED581", "min_span": 50, "health": (0, 400), "floor": True},
    "nox": {"name": "NOx", "short": "N", "fields": ["noxIndex"], "color": "#F48FB1", "min_span": 5, "health": (0, 50), "floor": True},
}

METRIC_OPTIONS = [
    ("co2", "CO2"),
    ("pm25", "PM2.5"),
    ("pm1", "PM1.0"),
    ("pm10", "PM10"),
    ("temp", "Temperature"),
    ("hum", "Humidity"),
    ("voc", "VOC Index"),
    ("nox", "NOx Index"),
]

DEFAULT_CHARTS = ["co2", "pm25", "temp", "hum", "none", "none"]

# --- Air quality levels (same thresholds as the AirGradient app) ---

def co2_color(v):
    if v <= 800:
        return COLOR_GREEN
    elif v <= 1000:
        return COLOR_YELLOW
    elif v <= 1500:
        return COLOR_ORANGE
    elif v <= 2000:
        return COLOR_RED
    return COLOR_PURPLE

def pm25_color(v):
    if v <= 9:
        return COLOR_GREEN
    elif v <= 35:
        return COLOR_YELLOW
    elif v <= 55:
        return COLOR_ORANGE
    elif v <= 125:
        return COLOR_RED
    return COLOR_PURPLE

def pm10_color(v):
    if v <= 20:
        return COLOR_GREEN
    elif v <= 50:
        return COLOR_YELLOW
    elif v <= 100:
        return COLOR_ORANGE
    elif v <= 150:
        return COLOR_RED
    return COLOR_PURPLE

def voc_color(v):
    if v <= 100:
        return COLOR_GREEN
    elif v <= 150:
        return COLOR_YELLOW
    elif v <= 250:
        return COLOR_ORANGE
    elif v <= 350:
        return COLOR_RED
    return COLOR_PURPLE

def nox_color(v):
    if v <= 1:
        return COLOR_GREEN
    elif v <= 5:
        return COLOR_YELLOW
    elif v <= 15:
        return COLOR_ORANGE
    elif v <= 30:
        return COLOR_RED
    return COLOR_PURPLE

def level_color(key, v):
    if key == "co2":
        return co2_color(v)
    elif key == "pm25" or key == "pm1":
        return pm25_color(v)
    elif key == "pm10":
        return pm10_color(v)
    elif key == "voc":
        return voc_color(v)
    elif key == "nox":
        return nox_color(v)

    # Temperature and humidity have no air quality level
    return METRICS[key]["color"]

# --- Data Helpers ---

def parse_number(s):
    if type(s) == "int" or type(s) == "float":
        return float(s)
    if type(s) != "string":
        return None
    raw = s.strip()
    if not raw or raw in ["unavailable", "unknown", "none"]:
        return None
    stripped = raw
    if stripped.startswith("-") or stripped.startswith("+"):
        stripped = stripped[1:]
    if not stripped:
        return None
    parts = stripped.split(".")
    if len(parts) == 1:
        return float(raw) if parts[0].isdigit() else None
    elif len(parts) == 2:
        p0 = parts[0]
        p1 = parts[1]
        if (p0 == "" or p0.isdigit()) and (p1 == "" or p1.isdigit()) and (p0 != "" or p1 != ""):
            return float(raw)
    return None

def to_display_unit(key, v, temp_unit):
    if key == "temp" and temp_unit == "f":
        return v * 9.0 / 5.0 + 32.0
    return v

def health_range(key, temp_unit):
    lo, hi = METRICS[key]["health"]
    return float(to_display_unit(key, lo, temp_unit)), float(to_display_unit(key, hi, temp_unit))

def fetch_history(api_base, location_id, api_key, hours, end_unix, refresh_seconds):
    base = api_base.strip().rstrip("/") if api_base and api_base.strip() else DEFAULT_AG_CLOUD_API
    start_unix = end_unix - hours * 3600
    resp = http.get(
        "%s/locations/%s/measures/past" % (base, location_id),
        params = {
            "token": api_key,
            "from": time.from_timestamp(start_unix).in_location("UTC").format("20060102T150405Z"),
            "to": time.from_timestamp(end_unix).in_location("UTC").format("20060102T150405Z"),
        },
        ttl_seconds = refresh_seconds,
    )
    if resp.status_code != 200:
        return None, resp.status_code

    records = resp.json()
    if type(records) != "list":
        return None, 0
    return records, 200

def get_ha_candidate_entities(config, metric_key, prefix):
    p = prefix if prefix else "airgradient_one"
    ov_key = "ha_%s_entity" % ("pm25" if metric_key == "pm25" else metric_key)
    override = (config.get(ov_key) or "").strip()
    if override:
        return [override]
    if metric_key == "co2":
        return ["sensor.%s_co2" % p]
    elif metric_key == "pm25":
        return ["sensor.%s_pm2_5" % p, "sensor.%s_pm2_5_density" % p]
    elif metric_key == "pm1":
        return ["sensor.%s_pm1_0" % p, "sensor.%s_pm1_density" % p, "sensor.%s_pm01" % p]
    elif metric_key == "pm10":
        return ["sensor.%s_pm10" % p, "sensor.%s_pm10_density" % p]
    elif metric_key == "temp":
        return ["sensor.%s_temperature" % p]
    elif metric_key == "hum":
        return ["sensor.%s_humidity" % p]
    elif metric_key == "voc":
        return ["sensor.%s_tvoc_index" % p, "sensor.%s_tvoc" % p]
    elif metric_key == "nox":
        return ["sensor.%s_nox_index" % p, "sensor.%s_nox" % p]
    return []

def fetch_ha_history(ha_url, ha_token, entity_ids, hours, end_unix, refresh_seconds):
    if not ha_url or not ha_token:
        return None, 0
    base_url = ha_url.strip().rstrip("/")
    start_unix = end_unix - hours * 3600
    start_iso = time.from_timestamp(start_unix).in_location("UTC").format("2006-01-02T15:04:05Z")
    end_iso = time.from_timestamp(end_unix).in_location("UTC").format("2006-01-02T15:04:05Z")

    url = "%s/api/history/period/%s" % (base_url, start_iso)
    params = {
        "filter_entity_id": ",".join(entity_ids),
        "end_time": end_iso,
        "minimal_response": "true",
        "no_attributes": "true",
    }
    headers = {
        "Authorization": "Bearer " + ha_token.strip(),
        "Content-Type": "application/json",
    }
    resp = http.get(url, params = params, headers = headers, ttl_seconds = refresh_seconds)
    if resp.status_code != 200:
        return None, resp.status_code

    raw = resp.json()
    if type(raw) != "list":
        return None, 0
    return raw, 200

def extract_ha_series(raw, keys, config, prefix, temp_unit):
    by_entity = {}
    for entity_history in raw:
        if type(entity_history) == "list" and len(entity_history) > 0:
            eid = entity_history[0].get("entity_id")
            if eid:
                by_entity[eid] = entity_history

    series = {k: [] for k in keys}
    for k in keys:
        candidates = get_ha_candidate_entities(config, k, prefix)
        entity_history = None
        for cand in candidates:
            if cand in by_entity:
                entity_history = by_entity[cand]
                break
        if not entity_history:
            continue

        points = []
        for entry in entity_history:
            state_str = entry.get("state")
            val = parse_number(state_str)
            if val == None:
                continue
            ts = entry.get("last_changed") or entry.get("last_updated")
            if not ts:
                continue
            t = time.parse_time(ts).unix
            if k == "temp":
                if val > 45:
                    if temp_unit == "c":
                        val = (val - 32.0) * 5.0 / 9.0
                elif temp_unit == "f":
                    val = val * 9.0 / 5.0 + 32.0
            points.append((t, float(val)))

        series[k] = sorted(points, key = lambda p: p[0])
    return series

def demo_history(hours, end_unix):
    # Synthetic but plausible readings, used for previews before credentials are set
    step = BUCKET_SECONDS if hours <= 48 else 3600
    records = []
    count = hours * 3600 // step
    for i in range(count):
        t = end_unix - (count - 1 - i) * step
        day = 2 * math.pi * ((t % 86400) / 86400.0)
        wobble = math.sin(i * 0.7) + math.sin(i * 0.31)
        records.append({
            "timestamp": time.from_timestamp(t).in_location("UTC").format("2006-01-02T15:04:05Z"),
            "rco2_corrected": 650 + 250 * math.sin(day - 1.2) + 40 * wobble,
            "pm02_corrected": max(0.5, 6 + 4 * math.sin(day * 2 + 0.5) + 1.5 * wobble),
            "pm01_corrected": max(0.2, 3 + 2 * math.sin(day * 2 + 0.5) + wobble),
            "pm10_corrected": max(0.5, 9 + 5 * math.sin(day * 2 + 0.5) + 2 * wobble),
            "atmp_corrected": 21.5 + 1.8 * math.sin(day - 2.0) + 0.2 * wobble,
            "rhum_corrected": 42 + 6 * math.sin(day + 1.0) + wobble,
            "tvocIndex": 100 + 40 * math.sin(day * 3) + 10 * wobble,
            "noxIndex": 1 + max(0, 2 * math.sin(day * 4)),
        })
    return records

def extract_series(records, keys, temp_unit):
    # Returns {key: [(unix_seconds, value)]} in time order, parsing each timestamp once
    series = {k: [] for k in keys}
    for rec in records:
        ts = rec.get("timestamp")
        if not ts:
            continue
        t = None
        for k in keys:
            v = None
            for f in METRICS[k]["fields"]:
                if rec.get(f) != None:
                    v = rec.get(f)
                    break
            if v == None:
                continue
            if t == None:
                t = time.parse_time(ts).unix
            series[k].append((t, float(to_display_unit(k, v, temp_unit))))
    return {k: sorted(s, key = lambda p: p[0]) for k, s in series.items()}

def bucket_series(series, start_unix, end_unix, n, forward_fill = True):
    # Average the series into n equal time slots with optional forward-fill
    span = float(end_unix - start_unix)
    sums = [0.0] * n
    counts = [0] * n
    last_in_slot = [None] * n

    last_val = None
    for t, v in series:
        if t <= start_unix:
            last_val = v
        elif t <= end_unix:
            idx = int((t - start_unix) / span * n)
            if idx >= n:
                idx = n - 1
            sums[idx] += v
            counts[idx] += 1
            last_in_slot[idx] = v

    buckets = []
    for i in range(n):
        if counts[i] > 0:
            val = sums[i] / counts[i]
            if last_in_slot[i] != None:
                last_val = last_in_slot[i]
            buckets.append(val)
        elif forward_fill and last_val != None:
            buckets.append(last_val)
        else:
            buckets.append(None)
    return buckets

def average_since(series, since_unix, now_unix):
    if not series:
        return None
    total_sec = max(1, now_unix - since_unix)
    buckets = bucket_series(series, since_unix, now_unix, max(1, total_sec // BUCKET_SECONDS), forward_fill = True)
    present = [v for v in buckets if v != None]
    if not present:
        return None
    total = 0.0
    for v in present:
        total += v
    return total / len(present)

def y_range(key, values, baseline, scale, temp_unit):
    present = [v for v in values if v != None]
    if baseline != None:
        present.append(baseline)
    lo = min(present)
    hi = max(present)
    floor = METRICS[key]["floor"]

    if scale == "zero":
        lo = min(0.0, lo)
        hi = max(hi, lo + METRICS[key]["min_span"])
    elif scale == "health":
        h_lo, h_hi = health_range(key, temp_unit)
        lo = min(lo, h_lo)
        hi = max(hi, h_hi)
    else:
        # Auto: zoom to the data, but never tighter than the metric's minimum span.
        # The lowest bar keeps a sliver of height so it stays visible.
        span = max(hi - lo, METRICS[key]["min_span"])
        mid = (hi + lo) / 2.0
        lo = mid - span / 2.0
        hi = mid + span / 2.0
        if floor and lo < 0:
            hi = hi - lo
            lo = 0.0
        lo = lo - span * 0.08

    if hi <= lo:
        hi = lo + 1
    return lo, hi

def format_value(key, v, rounded = False):
    if key == "temp":
        return "%d°" % int(math.round(v))
    elif key == "hum":
        return "%d%%" % int(math.round(v))
    elif key in ["pm25", "pm1", "pm10"] and v < 10 and not rounded:
        r = math.round(v * 10) / 10.0
        s = str(r)
        if s.endswith(".0"):
            s = s[:-2]
        return s
    return str(int(math.round(v)))

def format_range(hours):
    if hours % 24 == 0 and hours >= 48:
        return "%dd" % (hours // 24)
    return "%dh" % hours

# --- Rendering ---

def bar_color(key, v, color_mode, baseline):
    if color_mode == "levels":
        return level_color(key, v)
    elif color_mode == "average":
        if baseline != None and v > baseline:
            return COLOR_ABOVE_AVG
        return METRICS[key]["color"]
    return METRICS[key]["color"]

def render_label(chart, w, opts):
    # Try the clearest label that fits the cell: full name and value first, then a
    # rounded value, then the short name, and finally the value on its own.
    font = opts["font"]
    space = 2 * opts["scale"]
    names = [chart["name"]] if chart["short"] == chart["name"] else [chart["name"], chart["short"]]
    values = [chart["value_str"]] if chart["value_short"] == chart["value_str"] else [chart["value_str"], chart["value_short"]]

    for name_str in names:
        for value_str in values:
            name = render.Text(name_str, font = font, color = COLOR_LABEL)
            value = render.Text(value_str, font = font, color = chart["value_color"])
            used = name.size()[0] + space + value.size()[0]
            if used > w:
                continue

            left = render.Row(children = [name, render.Box(width = space, height = 1), value])
            range_text = render.Text(opts["range_str"], font = font, color = COLOR_LABEL)
            if opts["show_range"] and used + 2 * space + range_text.size()[0] <= w:
                return render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [left, range_text],
                )
            return left

    return render.Text(chart["value_short"], font = font, color = chart["value_color"])

def render_bars(chart, w, h, opts):
    gap = opts["gap"]
    min_bar = opts["min_bar"]

    # As many bars as fit, but no more than there are data buckets in the range
    n = (w + gap) // (min_bar + gap)
    n = max(1, min(n, opts["max_buckets"]))
    bar_w = (w + gap) // n - gap
    used = n * bar_w + (n - 1) * gap

    values = bucket_series(chart["series"], opts["start_unix"], opts["end_unix"], n, forward_fill = True)
    present = [v for v in values if v != None]
    if not present:
        return render.Box(
            width = w,
            height = h,
            child = render.Text("no data", font = opts["font"], color = COLOR_LABEL),
        )

    lo, hi = y_range(chart["key"], values, chart["baseline"], opts["y_scale"], opts["temp_unit"])

    children = []
    if used < w:
        # Right-align so the newest bar sits at the right edge
        children.append(render.Box(width = w - used, height = h))
    for i in range(n):
        v = values[i]
        if v == None:
            children.append(render.Box(width = bar_w, height = h))
        else:
            bh = int(math.round((v - lo) / (hi - lo) * h))
            bh = max(1, min(h, bh))
            bar = render.Box(width = bar_w, height = bh, color = bar_color(chart["key"], v, opts["color_mode"], chart["baseline"]))
            if bh < h:
                children.append(render.Column(children = [render.Box(width = bar_w, height = h - bh), bar]))
            else:
                children.append(bar)

        # A zero-width Box would expand to fill the row, so only add real gaps
        if gap > 0 and i < n - 1:
            children.append(render.Box(width = gap, height = h))

    layers = []
    if opts["color_mode"] == "average" and chart["baseline"] != None:
        # Baseline sits behind the bars, so it shows above short bars and is hidden by tall ones
        by = int(math.round((chart["baseline"] - lo) / (hi - lo) * h))
        by = max(1, min(h, by))
        layers.append(render.Padding(
            pad = (0, h - by, 0, 0),
            child = render.Box(width = w, height = 1, color = COLOR_BASELINE),
        ))
    layers.append(render.Row(children = children))

    return render.Stack(children = layers)

def render_chart(chart, w, h, opts):
    label_h = opts["label_h"]
    if not opts["show_labels"] or h < label_h + 4:
        return render.Box(width = w, height = h, child = render_bars(chart, w, h, opts))

    return render.Box(
        width = w,
        height = h,
        child = render.Column(
            children = [
                render.Box(width = w, height = label_h, child = render.Padding(pad = (0, 0, 0, 1), child = render_label(chart, w, opts))),
                render_bars(chart, w, h - label_h, opts),
            ],
        ),
    )

def split(total, parts):
    # Split a length into parts separated by 1px dividers; the last part takes the remainder
    size = (total - (parts - 1)) // parts
    sizes = [size] * parts
    sizes[parts - 1] = total - (parts - 1) - size * (parts - 1)
    return sizes

def vdivider(h):
    return render.Box(width = 1, height = h, color = COLOR_DIVIDER)

def hdivider(w):
    return render.Box(width = w, height = 1, color = COLOR_DIVIDER)

def render_grid(charts, width, height, opts):
    n = len(charts)
    if n == 1:
        return render_chart(charts[0], width, height, opts)

    if n == 2:
        ws = split(width, 2)
        return render.Row(children = [
            render_chart(charts[0], ws[0], height, opts),
            vdivider(height),
            render_chart(charts[1], ws[1], height, opts),
        ])

    if n == 3:
        # Left cell spans both rows; two cells stacked on the right
        ws = split(width, 2)
        hs = split(height, 2)
        return render.Row(children = [
            render_chart(charts[0], ws[0], height, opts),
            vdivider(height),
            render.Column(children = [
                render_chart(charts[1], ws[1], hs[0], opts),
                hdivider(ws[1]),
                render_chart(charts[2], ws[1], hs[1], opts),
            ]),
        ])

    # 4 → 2x2, 5 or 6 → 3x2 (with 5, the last cell stays empty)
    cols = 2 if n == 4 else 3
    ws = split(width, cols)
    hs = split(height, 2)
    rows = []
    for r in range(2):
        cells = []
        for c in range(cols):
            idx = r * cols + c
            if idx < n:
                cells.append(render_chart(charts[idx], ws[c], hs[r], opts))
            else:
                cells.append(render.Box(width = ws[c], height = hs[r]))
            if c < cols - 1:
                cells.append(vdivider(hs[r]))
        rows.append(render.Row(children = cells))
        if r == 0:
            rows.append(hdivider(width))
    return render.Column(children = rows)

def render_message(title, lines, color):
    is2x = canvas.is2x()
    font = "tb-8" if is2x else "tom-thumb"
    children = [render.Text(title, font = font, color = COLOR_LABEL)]
    for line in lines:
        children.append(render.Text(line, font = font, color = color))
    return render.Root(
        max_age = 300,
        child = render.Box(
            child = render.Column(main_align = "center", cross_align = "center", children = children),
        ),
    )

def error_screen(status, is_ha = False):
    if is_ha:
        if status == 401 or status == 403:
            return render_message("HomeAssistant", ["Check your", "HA token"], COLOR_ERROR)
        elif status == 404:
            return render_message("HomeAssistant", ["HA API endpoint", "not found (404)"], COLOR_ERROR)
        return render_message("HomeAssistant", ["HA error", str(status) if status else "unreachable"], COLOR_ERROR)

    if status == 401 or status == 403:
        return render_message("AirGradient", ["Check your", "API key"], COLOR_ERROR)
    elif status == 404:
        return render_message("AirGradient", ["No data for", "Location ID"], COLOR_ERROR)
    return render_message("AirGradient", ["API error", str(status) if status else "bad reply"], COLOR_ERROR)

# --- Main ---

def int_option(config, key, default):
    v = config.get(key, str(default))
    if v and v.isdigit():
        return int(v)
    return default

def main(config):
    source = config.get("source", "cloud")
    location_id = (config.get("ag_location_id") or "").strip()
    api_key = (config.get("ag_api_key") or "").strip()
    cloud_url = (config.get("ag_cloud_url") or "").strip()

    ha_url = (config.get("ha_url") or "http://homeassistant.local:8123").strip()
    ha_token = (config.get("ha_token") or "").strip()
    ha_prefix = (config.get("ha_prefix") or "airgradient_one").strip()

    layout = config.get("layout", "grid")
    range_h = int_option(config, "range_hours", 24)
    y_scale = config.get("y_scale", "auto")
    color_mode = config.get("color_mode", "levels")
    avg_h = int_option(config, "avg_hours", 24)
    bar_style = config.get("bar_style", "gaps")
    temp_unit = config.get("temp_unit", "f")
    show_labels = config.bool("show_labels", True)
    slide_s = int_option(config, "slide_seconds", 5)

    # Selected metrics, in order, without repeats
    keys = []
    for i in range(6):
        k = config.get("chart%d" % (i + 1), DEFAULT_CHARTS[i])
        if k in METRICS and k not in keys:
            keys.append(k)
    if not keys:
        keys = ["co2"]

    now_unix = time.now().unix

    # Snap the request window to the refresh interval so repeated renders share one cached response
    refresh = BUCKET_SECONDS if range_h <= 24 else LONG_RANGE_REFRESH_SECONDS
    end_unix = now_unix - now_unix % refresh + refresh
    fetch_h = range_h
    if color_mode == "average" and avg_h > fetch_h:
        fetch_h = avg_h

    if source == "homeassistant":
        if not ha_token or ha_token == "APIKEY":
            records = demo_history(fetch_h, end_unix)
            all_series = extract_series(records, keys, temp_unit)
        else:
            needed_entities = []
            for k in keys:
                for eid in get_ha_candidate_entities(config, k, ha_prefix):
                    if eid not in needed_entities:
                        needed_entities.append(eid)
            raw, status = fetch_ha_history(ha_url, ha_token, needed_entities, fetch_h, end_unix, refresh)
            if raw == None:
                if status in TRANSIENT_STATUSES:
                    return []
                return error_screen(status, is_ha = True)
            all_series = extract_ha_series(raw, keys, config, ha_prefix, temp_unit)
    else:
        # Default: cloud
        if not location_id or not api_key:
            records = demo_history(fetch_h, end_unix)
            all_series = extract_series(records, keys, temp_unit)
        elif not location_id.isdigit():
            return render_message("AirGradient", ["Location ID", "must be a", "number"], COLOR_ERROR)
        else:
            records, status = fetch_history(cloud_url, location_id, api_key, fetch_h, end_unix, refresh)
            if records == None:
                if status in TRANSIENT_STATUSES:
                    # Keep showing the last good frame until the API recovers
                    return []
                return error_screen(status, is_ha = False)
            all_series = extract_series(records, keys, temp_unit)

    charts = []
    for k in keys:
        series = all_series[k]
        if not series:
            # e.g. CO2 on an Open Air monitor
            continue
        latest_t, latest = series[-1]
        baseline = average_since(series, now_unix - avg_h * 3600, now_unix) if color_mode == "average" else None
        if now_unix - latest_t > refresh + STALE_SECONDS:
            # The monitor has stopped reporting; don't present an old reading as current
            value_color = COLOR_STALE
        elif color_mode == "levels":
            value_color = level_color(k, latest)
        elif color_mode == "average" and baseline != None and latest > baseline:
            value_color = COLOR_ABOVE_AVG
        else:
            value_color = "#FFFFFF"
        charts.append({
            "key": k,
            "name": METRICS[k]["name"],
            "series": series,
            "baseline": baseline,
            "short": METRICS[k]["short"],
            "value_str": format_value(k, latest),
            "value_short": format_value(k, latest, True),
            "value_color": value_color,
        })

    if not charts:
        return render_message("AirGradient", ["No readings", "in the last", format_range(range_h)], COLOR_ERROR)

    width, height = canvas.size()
    scale = 2 if canvas.is2x() else 1

    opts = {
        "scale": scale,
        "font": "tb-8" if scale == 2 else "tom-thumb",
        "label_h": 9 if scale == 2 else 6,
        "gap": scale if bar_style == "gaps" else 0,
        "min_bar": (2 if bar_style == "gaps" else 1) * scale,
        "max_buckets": max(1, range_h * 3600 // BUCKET_SECONDS),
        "start_unix": now_unix - range_h * 3600,
        "end_unix": now_unix,
        "y_scale": y_scale,
        "color_mode": color_mode,
        "temp_unit": temp_unit,
        "show_labels": show_labels,
        "range_str": format_range(range_h),
        "show_range": False,
    }

    if layout == "slides" or len(charts) == 1:
        slide_opts = dict(opts)
        slide_opts["show_range"] = True
        slides = [render_chart(c, width, height, slide_opts) for c in charts]
        if len(slides) == 1:
            return render.Root(max_age = 600, child = slides[0])
        return render.Root(
            max_age = 600,
            delay = slide_s * 1000,
            show_full_animation = True,
            child = render.Animation(children = slides),
        )

    return render.Root(max_age = 600, child = render_grid(charts, width, height, opts))

def get_schema():
    metric_choices = [schema.Option(display = label, value = value) for value, label in METRIC_OPTIONS]
    chart_fields = []
    for i in range(6):
        options = metric_choices if i == 0 else [schema.Option(display = "None", value = "none")] + metric_choices
        chart_fields.append(schema.Dropdown(
            id = "chart%d" % (i + 1),
            name = "Chart %d" % (i + 1),
            desc = "Metric for chart %d. Metrics your monitor doesn't measure are skipped." % (i + 1),
            icon = "chartColumn",
            default = DEFAULT_CHARTS[i],
            options = options,
        ))

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "source",
                name = "Data Source",
                desc = "Choose how to retrieve history for your AirGradient monitor",
                icon = "plug",
                default = "cloud",
                options = [
                    schema.Option(display = "AirGradient Cloud (API Key)", value = "cloud"),
                    schema.Option(display = "Home Assistant (Local Network)", value = "homeassistant"),
                ],
            ),
            schema.Text(
                id = "ag_location_id",
                name = "Location ID (Cloud mode)",
                desc = "Numeric ID from app.airgradient.com/settings/location. Not the Place ID.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "ag_api_key",
                name = "API Key (Cloud mode)",
                desc = "Place API key from app.airgradient.com/settings/place (API tab)",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "ag_cloud_url",
                name = "Cloud / Server URL (optional)",
                desc = "Custom server base URL (default: https://api.airgradient.com/public/api/v1)",
                icon = "server",
                default = "https://api.airgradient.com/public/api/v1",
            ),
            schema.Text(
                id = "ha_url",
                name = "HA URL (Home Assistant mode)",
                desc = "Base URL of Home Assistant (e.g. http://homeassistant.local:8123)",
                icon = "server",
                default = "http://homeassistant.local:8123",
            ),
            schema.Text(
                id = "ha_token",
                name = "HA Token (Home Assistant mode)",
                desc = "Long-Lived Access Token for Home Assistant",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "ha_prefix",
                name = "HA Entity Prefix (Home Assistant mode)",
                desc = "Prefix for sensors (e.g. airgradient_one for sensor.airgradient_one_co2)",
                icon = "tag",
                default = "airgradient_one",
            ),
            schema.Text(
                id = "ha_co2_entity",
                name = "HA Custom CO2 Entity (optional)",
                desc = "Override entity ID for CO2 (e.g. sensor.living_room_co2)",
                icon = "smog",
            ),
            schema.Text(
                id = "ha_pm25_entity",
                name = "HA Custom PM2.5 Entity (optional)",
                desc = "Override entity ID for PM2.5 (e.g. sensor.living_room_pm2_5)",
                icon = "wind",
            ),
            schema.Text(
                id = "ha_pm1_entity",
                name = "HA Custom PM1.0 Entity (optional)",
                desc = "Override entity ID for PM1.0",
                icon = "wind",
            ),
            schema.Text(
                id = "ha_pm10_entity",
                name = "HA Custom PM10 Entity (optional)",
                desc = "Override entity ID for PM10",
                icon = "wind",
            ),
            schema.Text(
                id = "ha_temp_entity",
                name = "HA Custom Temp Entity (optional)",
                desc = "Override entity ID for Temperature",
                icon = "temperatureHalf",
            ),
            schema.Text(
                id = "ha_hum_entity",
                name = "HA Custom Humidity Entity (optional)",
                desc = "Override entity ID for Humidity",
                icon = "droplet",
            ),
            schema.Text(
                id = "ha_voc_entity",
                name = "HA Custom TVOC Entity (optional)",
                desc = "Override entity ID for TVOC",
                icon = "flask",
            ),
            schema.Text(
                id = "ha_nox_entity",
                name = "HA Custom NOx Entity (optional)",
                desc = "Override entity ID for NOx",
                icon = "biohazard",
            ),
            schema.Dropdown(
                id = "layout",
                name = "Layout",
                desc = "Show every chart on one screen, or one full-screen chart at a time",
                icon = "tableCellsLarge",
                default = "grid",
                options = [
                    schema.Option(display = "All on one screen", value = "grid"),
                    schema.Option(display = "One per slide (full screen)", value = "slides"),
                ],
            ),
        ] + chart_fields + [
            schema.Dropdown(
                id = "range_hours",
                name = "Time Range",
                desc = "How far back the charts go",
                icon = "clock",
                default = "24",
                options = [
                    schema.Option(display = "1 hour", value = "1"),
                    schema.Option(display = "3 hours", value = "3"),
                    schema.Option(display = "6 hours", value = "6"),
                    schema.Option(display = "12 hours", value = "12"),
                    schema.Option(display = "24 hours", value = "24"),
                    schema.Option(display = "2 days", value = "48"),
                    schema.Option(display = "7 days", value = "168"),
                ],
            ),
            schema.Dropdown(
                id = "y_scale",
                name = "Y-Axis Scale",
                desc = "Auto zooms in on changes; From zero shows true proportions; Fixed uses the same healthy range every time",
                icon = "rulerVertical",
                default = "auto",
                options = [
                    schema.Option(display = "Auto (zoom to data)", value = "auto"),
                    schema.Option(display = "From zero", value = "zero"),
                    schema.Option(display = "Fixed health range", value = "health"),
                ],
            ),
            schema.Dropdown(
                id = "color_mode",
                name = "Bar Colors",
                desc = "How the bars are colored",
                icon = "palette",
                default = "levels",
                options = [
                    schema.Option(display = "Air quality level (green to purple)", value = "levels"),
                    schema.Option(display = "Highlight above average", value = "average"),
                    schema.Option(display = "One color per metric", value = "metric"),
                ],
            ),
            schema.Dropdown(
                id = "avg_hours",
                name = "Average Window",
                desc = "For 'Highlight above average': bars above the average of the last X hours turn red",
                icon = "chartLine",
                default = "24",
                options = [
                    schema.Option(display = "1 hour", value = "1"),
                    schema.Option(display = "3 hours", value = "3"),
                    schema.Option(display = "6 hours", value = "6"),
                    schema.Option(display = "12 hours", value = "12"),
                    schema.Option(display = "24 hours", value = "24"),
                    schema.Option(display = "7 days", value = "168"),
                ],
            ),
            schema.Dropdown(
                id = "bar_style",
                name = "Bar Style",
                desc = "Separate bars, or solid columns with no gaps",
                icon = "gripLinesVertical",
                default = "gaps",
                options = [
                    schema.Option(display = "Bars with gaps", value = "gaps"),
                    schema.Option(display = "Solid (no gaps)", value = "solid"),
                ],
            ),
            schema.Toggle(
                id = "show_labels",
                name = "Show Labels",
                desc = "Metric name and latest value above each chart",
                icon = "font",
                default = True,
            ),
            schema.Dropdown(
                id = "temp_unit",
                name = "Temperature Unit",
                desc = "Unit for the temperature chart",
                icon = "temperatureHalf",
                default = "f",
                options = [
                    schema.Option(display = "Fahrenheit (°F)", value = "f"),
                    schema.Option(display = "Celsius (°C)", value = "c"),
                ],
            ),
            schema.Dropdown(
                id = "slide_seconds",
                name = "Seconds per Slide",
                desc = "For the 'One per slide' layout. The app asks Tronbyt to play every slide, even past the display time.",
                icon = "stopwatch",
                default = "5",
                options = [
                    schema.Option(display = "3 seconds", value = "3"),
                    schema.Option(display = "5 seconds", value = "5"),
                    schema.Option(display = "8 seconds", value = "8"),
                    schema.Option(display = "10 seconds", value = "10"),
                ],
            ),
        ],
    )
