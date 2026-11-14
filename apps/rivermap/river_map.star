"""
Applet: River Map
Summary: River levels along a US river
Description: A map of a major US river, coloured along its length by the water level at USGS stream gauges: how today's level compares with normal, how close it is to flood stage, or whether it is rising or falling. State or county lines optional.
Author: tscott98
"""

load("encoding/csv.star", "csv")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

# Live readings: USGS Water Data API (https://api.waterdata.usgs.gov/)
USGS_API = "https://api.waterdata.usgs.gov/ogcapi/v0/collections"
PARAM_STAGE = "00065"  # gage height, ft
PARAM_FLOW = "00060"  # discharge, cfs

# River shapes (NHDPlus V2 mainstems via geoconnex.us), the gauges on each river, their
# historical percentiles and NWS flood stages are worked out ahead of time by
# gen_rivers.py and stored at the end of this file (RIVERS).

DEFAULT_RIVER = "brazos"

# Gauges report every 5-15 minutes
READINGS_TTL = 900

# A reading older than this is ignored, and the river is interpolated around that gauge
STALE_SECONDS = 6 * 3600

# Rising/falling compares now with this long ago
TREND_SECONDS = 24 * 3600

# The API is down briefly; skip this render rather than show an error
TRANSIENT_STATUSES = [0, 429, 500, 502, 503, 504]

COLOR_STATE = "#3A4250"
COLOR_COUNTY = "#1C2129"
COLOR_NO_DATA = "#4A5058"
COLOR_LABEL = "#9AA0A6"
COLOR_LABEL_BG = "#000000"

# Level vs normal: the gauge's percentile over the last five years
NORMAL_RAMP = [
    (0.0, (0xB0, 0x70, 0x38)),  # very low: tan
    (15.0, (0xA8, 0x98, 0x30)),  # low: olive
    (30.0, (0x30, 0xC0, 0x50)),  # normal: green
    (70.0, (0x30, 0xC0, 0x50)),
    (85.0, (0x20, 0xB0, 0xE0)),  # high: cyan
    (100.0, (0x30, 0x60, 0xFF)),  # very high: blue
]

# Flood stage: share of the way from low water (10th percentile) to action stage
FLOOD_RAMP = [
    (0.0, (0x10, 0x30, 0x90)),
    (60.0, (0x20, 0x80, 0xFF)),
    (100.0, (0x70, 0xE0, 0xFF)),
]

# Rising/falling: 24 h change as a share of half the gauge's normal range, -1 to 1
TREND_RAMP = [
    (-1.0, (0x30, 0x70, 0xFF)),  # falling fast
    (-0.15, (0x80, 0x90, 0xA8)),
    (0.15, (0x80, 0x90, 0xA8)),  # steady
    (0.5, (0xFF, 0xA0, 0x20)),
    (1.0, (0xFF, 0x30, 0x30)),  # rising fast
]

# Without percentiles, a rise of this many feet counts as "fast"
TREND_FALLBACK_FT = 3.0

# NWS flood categories, lowest first, with the colors NWS hydrographs use. A gauge at or
# above one scores 100 + 25 * rank (+ how far towards the next).
FLOOD_LEVELS = [
    ("#FFE14D", "action"),
    ("#FF8C00", "minor"),
    ("#FF2828", "moderate"),
    ("#C040FF", "major"),
]

# Chain-code steps (gen_rivers.py DIRS)
STEP_X = [1, 1, 0, -1, -1, -1, 0, 1]
STEP_Y = [0, 1, 1, 1, 0, -1, -1, -1]

B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
B64_INDEX = {c: i for i, c in enumerate(B64.elems())}

# --- Formatting helpers ---

def hex2(v):
    v = int(v)
    v = 0 if v < 0 else (255 if v > 255 else v)
    return "0123456789ABCDEF"[v // 16] + "0123456789ABCDEF"[v % 16]

def rgb(c):
    return "#" + hex2(c[0]) + hex2(c[1]) + hex2(c[2])

def ramp_color(ramp, v):
    if v <= ramp[0][0]:
        return rgb(ramp[0][1])
    for i in range(1, len(ramp)):
        x1, c1 = ramp[i]
        if v <= x1:
            x0, c0 = ramp[i - 1]
            t = (v - x0) / (x1 - x0) if x1 > x0 else 1.0
            return rgb([c0[k] + (c1[k] - c0[k]) * t for k in range(3)])
    return rgb(ramp[-1][1])

# --- Data ---

def river_for(key):
    for r in RIVERS:
        if r["key"] == key:
            return r
    for r in RIVERS:
        if r["key"] == DEFAULT_RIVER:
            return r
    return RIVERS[0]

def is_number(s):
    # Plain decimal like "8.17" or "-0.5"; float() would fail the render on anything else
    body = s[1:] if s.startswith("-") else s
    parts = body.split(".")
    if len(parts) > 2 or not "".join(parts).isdigit():
        return False
    return True

def parse_time_csv(s):
    # "2026-11-14 01:15:00+00:00"; None for anything else, since a parse error would fail
    # the whole render (Starlark can't catch it)
    s = s.strip()
    if len(s) < 20 or s[4] != "-" or s[7] != "-" or s[10] not in " T" or s[13] != ":" or s[16] != ":":
        return None
    if not (s[:4] + s[5:7] + s[8:10] + s[11:13] + s[14:16] + s[17:19]).isdigit():
        return None
    zone = s[19:].lstrip(".0123456789")
    if zone != "Z" and not (len(zone) == 6 and zone[0] in "+-" and zone[3] == ":" and (zone[1:3] + zone[4:6]).isdigit()):
        return None
    return time.parse_time(s[:10] + " " + s[11:], format = "2006-01-02 15:04:05Z07:00").unix

def read_csv_rows(body):
    # [(site, parameter, unix, value)] from monitoring_location_id,[parameter_code,]time,value CSV
    rows = csv.read_all(body) if body else []
    if len(rows) < 2:
        return []
    header = rows[0]
    if "monitoring_location_id" not in header or "time" not in header or "value" not in header:
        return []
    si = header.index("monitoring_location_id")
    ti = header.index("time")
    vi = header.index("value")
    pi = header.index("parameter_code") if "parameter_code" in header else -1
    out = []
    for row in rows[1:]:
        if len(row) <= max(si, ti, vi, pi):
            continue
        site = row[si].strip()
        v = row[vi].strip()
        t = parse_time_csv(row[ti])
        if not site.startswith("USGS-") or t == None or not is_number(v):
            continue
        param = row[pi].strip() if pi >= 0 else PARAM_STAGE
        out.append((site[5:], param, t, float(v)))
    return out

def site_param(ids):
    return ",".join(["USGS-" + s for s in ids])

def fetch_latest(ids, params):
    # Returns ({site: {parameter: (unix, value)}}, status)
    resp = http.get(
        "%s/latest-continuous/items" % USGS_API,
        params = {
            "f": "csv",
            "parameter_code": ",".join(params),
            "monitoring_location_id": site_param(ids),
            "properties": "monitoring_location_id,parameter_code,time,value",
            "skipGeometry": "true",
            "limit": "500",
        },
        ttl_seconds = READINGS_TTL,
    )
    if resp.status_code != 200:
        return None, resp.status_code
    out = {}
    for site, param, t, v in read_csv_rows(resp.body()):
        by = out.setdefault(site, {})
        if param not in by or t > by[param][0]:
            by[param] = (t, v)
    return out, 200

def iso_utc(unix):
    return time.from_timestamp(unix).in_location("UTC").format("2006-01-02T15:04:05Z")

def fetch_past(ids, now_unix):
    # Readings from about TREND_SECONDS ago: {site: ft}. The window snaps to the refresh
    # period so the cache key repeats between renders.
    target = (now_unix // READINGS_TTL) * READINGS_TTL - TREND_SECONDS
    resp = http.get(
        "%s/continuous/items" % USGS_API,
        params = {
            "f": "csv",
            "parameter_code": PARAM_STAGE,
            "monitoring_location_id": site_param(ids),
            "time": "%s/%s" % (iso_utc(target - 3600), iso_utc(target)),
            "properties": "monitoring_location_id,time,value",
            "skipGeometry": "true",
            "limit": "5000",
        },
        ttl_seconds = READINGS_TTL,
    )
    if resp.status_code != 200:
        return None, resp.status_code
    best = {}
    for site, _, t, v in read_csv_rows(resp.body()):
        if site not in best or t > best[site][0]:
            best[site] = (t, v)
    return {s: best[s][1] for s in best}, 200

# --- Scores ---
# Every gauge gets one number; the river is coloured by interpolating it between gauges.

def percentile_of(stage, p):
    # p: stage at the 5, 10, 25, 50, 75, 90 and 95th percentiles
    pcts = [5.0, 10.0, 25.0, 50.0, 75.0, 90.0, 95.0]
    if stage <= p[0]:
        span = max(p[1] - p[0], 0.01)
        return max(0.0, 5.0 - 5.0 * (p[0] - stage) / span)
    if stage >= p[6]:
        span = max(p[6] - p[5], 0.01)
        return min(100.0, 95.0 + 5.0 * (stage - p[6]) / span)
    for i in range(1, len(p)):
        if stage <= p[i]:
            span = p[i] - p[i - 1]
            t = (stage - p[i - 1]) / span if span > 0 else 1.0
            return pcts[i - 1] + (pcts[i] - pcts[i - 1]) * t
    return 100.0

def flood_score(stage, f):
    # 100+ when at or above a flood stage, else None
    if not f:
        return None
    levels = [(i, f[i]) for i in range(len(f)) if f[i] != None]
    rank = None
    for i, v in levels:
        if stage >= v:
            rank = i
    if rank == None:
        return None
    nxt = [v for i, v in levels if i > rank]
    frac = 0.0
    if nxt:
        span = nxt[0] - f[rank]
        frac = min(0.99, (stage - f[rank]) / span) if span > 0 else 0.0
    return 100.0 + 25.0 * rank + 24.0 * frac

def first_flood_stage(f):
    for v in (f or []):
        if v != None:
            return v
    return None

def gauge_score(mode, stage, flow, past, p, f, q):
    if mode == "trend":
        if past == None:
            return None
        delta = stage - past
        if stage == None:
            return None
        if p:
            half_range = max((p[5] - p[1]) / 2.0, 0.25)
            rel = delta / half_range
        else:
            rel = delta / TREND_FALLBACK_FT
        return max(-1.0, min(1.0, rel))

    fs = flood_score(stage, f) if stage != None else None
    if fs != None:
        return fs

    if mode == "flood":
        top = first_flood_stage(f)
        if top == None or stage == None:
            return None
        low = p[1] if p else 0.0
        if top <= low:
            return 0.0
        return max(0.0, min(99.9, 100.0 * (stage - low) / (top - low)))

    if p and stage != None:
        return percentile_of(stage, p)
    if q and flow != None:
        # No gage-height statistics for this gauge: flow percentile instead
        return percentile_of(flow, q)
    return None

def score_color(mode, s):
    if s == None:
        return COLOR_NO_DATA
    if mode == "trend":
        return ramp_color(TREND_RAMP, s)
    if s >= 100.0:
        rank = min(3, int((s - 100.0) // 25.0))
        return FLOOD_LEVELS[rank][0]
    if mode == "flood":
        return ramp_color(FLOOD_RAMP, s)
    return ramp_color(NORMAL_RAMP, s)

def interpolate(points, n):
    # points: [(pixel index, score)] sorted by index. Returns a score for each of n pixels,
    # holding the end values beyond the first and last gauge.
    if not points:
        return [None] * n
    out = []
    j = 0
    for k in range(n):
        for _ in range(len(points)):
            if j + 1 < len(points) and points[j + 1][0] <= k:
                j += 1
            else:
                break
        i0, s0 = points[j]
        if k <= i0 or j + 1 >= len(points):
            out.append(s0)
        else:
            i1, s1 = points[j + 1]
            t = (k - i0) / (i1 - i0) if i1 > i0 else 0.0
            out.append(s0 + (s1 - s0) * t)
    return out

# --- Drawing ---

def decode_line(spec):
    x, y, chain = spec
    pts = [(x, y)]
    for c in chain.elems():
        d = int(c)
        x += STEP_X[d]
        y += STEP_Y[d]
        pts.append((x, y))
    return pts

def decode_bits(s, w, h, color, grid):
    # Row-major bitmap, 6 bits per character; sets grid[(x, y)] for each set bit
    n = w * h
    i = 0
    for c in s.elems():
        v = B64_INDEX.get(c, 0)
        for b in range(6):
            if v & (32 >> b) and i + b < n:
                p = i + b
                grid[(p % w, p // w)] = color
        i += 6

def rows_widget(grid, w, h, y_off):
    rows = []
    for y in range(h):
        children = []
        run_color = None
        run_len = 0
        for x in range(w):
            c = grid.get((x, y - y_off))
            if c == run_color:
                run_len += 1
                continue
            if run_len > 0:
                children.append(render.Box(width = run_len, height = 1, color = run_color) if run_color else render.Box(width = run_len, height = 1))
            run_color = c
            run_len = 1
        if run_len > 0:
            children.append(render.Box(width = run_len, height = 1, color = run_color) if run_color else render.Box(width = run_len, height = 1))
        rows.append(render.Row(children = children))
    return render.Column(children = rows)

def place_label(texts, font, river_pts, w, h):
    # The first text that fits in a corner without covering the river, else the shortest
    # one in the corner covering least of it
    taken = {p: True for p in river_pts}
    best = None
    for text in texts:
        tw, th = render.Text(text, font = font).size()
        for cx, cy in [(0, 0), (w - tw - 2, 0), (0, h - th - 1), (w - tw - 2, h - th - 1)]:
            hits = 0
            for x in range(cx, cx + tw + 2):
                for y in range(cy, cy + th + 1):
                    if taken.get((x, y)):
                        hits += 1
            if hits == 0:
                return (text, cx, cy, tw, th)
            if best == None or hits < best[0] or (hits == best[0] and len(text) < len(best[1][0])):
                best = (hits, (text, cx, cy, tw, th))
    return best[1] if best else None

def render_map(river, colors, outlines, show_name):
    width, height = canvas.size()
    s2 = canvas.is2x()
    key = "2" if s2 else "1"
    mw, mh = (128, 64) if s2 else (64, 32)
    y_off = max(0, (height - mh) // 2)

    grid = {}
    if outlines == "counties":
        decode_bits(river["counties" + key], mw, mh, COLOR_COUNTY, grid)
    if outlines in ["states", "counties"]:
        decode_bits(river["states" + key], mw, mh, COLOR_STATE, grid)

    pts = decode_line(river["line" + key])
    for i, p in enumerate(pts):
        grid[p] = colors[i] if i < len(colors) else COLOR_NO_DATA

    layers = [rows_widget(grid, width, height, y_off)]
    if show_name:
        font = "tb-8" if s2 else "tom-thumb"
        label = place_label([river["label"], river["short"]], font, pts, mw, mh)
        if label:
            text, lx, ly, tw, th = label
            layers.append(render.Padding(
                pad = (lx, ly + y_off, 0, 0),
                child = render.Box(
                    width = tw + 2,
                    height = th + 1,
                    color = COLOR_LABEL_BG,
                    child = render.Padding(
                        pad = (1, 1, 1, 0),
                        child = render.Text(text, font = font, color = COLOR_LABEL),
                    ),
                ),
            ))
    return render.Stack(children = layers)

def river_colors(river, mode, readings, past, now_unix):
    key = "2" if canvas.is2x() else "1"
    n = len(decode_line(river["line" + key]))
    points = []
    for site, i1, i2, p, f, q in river["gauges"]:
        r = readings.get(site) or {}
        stage = r.get(PARAM_STAGE)
        flow = r.get(PARAM_FLOW)
        stage = stage[1] if stage and now_unix - stage[0] <= STALE_SECONDS else None
        flow = flow[1] if flow and now_unix - flow[0] <= STALE_SECONDS else None
        if stage == None and flow == None:
            continue
        s = gauge_score(mode, stage, flow, (past or {}).get(site), p, f, q)
        if s != None:
            points.append((i2 if key == "2" else i1, s))
    points = sorted(points, key = lambda q: q[0])
    return [score_color(mode, s) for s in interpolate(points, n)], len(points)

def demo_readings(river, now_unix):
    # Synthetic readings for previews (config demo=1): low upstream, high downstream, the
    # last gauge with a flood stage in minor flood, alternating rises and falls
    gauges = river["gauges"]
    n = len(gauges)
    readings = {}
    past = {}
    flooded = [g[0] for g in gauges if g[4] and g[4][1] != None]
    for k, (site, _, _, p, f, q) in enumerate(gauges):
        t = k / (n - 1.0) if n > 1 else 0.5
        flow = None
        stage = None
        if p:
            stage = p[0] + (p[6] - p[0]) * t
        elif f and f[1] != None:
            stage = f[1] * 0.4
        if q:
            flow = q[0] + (q[6] - q[0]) * t
        if stage == None and flow == None:
            continue
        if flooded and site == flooded[-1]:
            stage = f[1] + 0.5
        readings[site] = {}
        if stage != None:
            readings[site][PARAM_STAGE] = (now_unix - 600, stage)
            past[site] = stage + (1.0 if k % 3 == 0 else -1.0) * (k % 4) * 0.4
        if flow != None:
            readings[site][PARAM_FLOW] = (now_unix - 600, flow)
    return readings, past

def main(config):
    river = river_for(config.get("river") or DEFAULT_RIVER)
    mode = config.get("color_by") or "normal"
    if mode not in ["normal", "flood", "trend"]:
        mode = "normal"
    outlines = config.get("outlines") or "states"
    show_name = config.bool("show_name", True)
    now_unix = time.now().unix

    ids = [g[0] for g in river["gauges"]]
    readings = {}
    past = None
    if config.get("demo"):
        readings, past = demo_readings(river, now_unix)
    elif ids:
        params = [PARAM_STAGE]
        if mode == "normal" and [g for g in river["gauges"] if g[5]]:
            params.append(PARAM_FLOW)
        readings, status = fetch_latest(ids, params)
        if readings == None:
            if status in TRANSIENT_STATUSES:
                # Keep showing the last good frame until the API recovers
                return []
            print("river map: USGS latest readings returned %d" % status)
            readings = {}
        if mode == "trend" and readings:
            past, status = fetch_past(ids, now_unix)
            if past == None and status in TRANSIENT_STATUSES:
                return []

    colors, used = river_colors(river, mode, readings, past, now_unix)
    print("river map: %s, %d of %d gauges coloured (%s)" % (river["key"], used, len(ids), mode))

    return render.Root(
        max_age = READINGS_TTL,
        child = render_map(river, colors, outlines, show_name),
    )

def get_schema():
    rivers = sorted(RIVERS, key = lambda r: r["label"])
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "river",
                name = "River",
                desc = "The river to map.",
                icon = "water",
                default = DEFAULT_RIVER,
                options = [schema.Option(display = r["label"], value = r["key"]) for r in rivers],
            ),
            schema.Dropdown(
                id = "color_by",
                name = "Colour By",
                desc = "What the colour of the river shows, worked out at each USGS gauge and blended between them.",
                icon = "palette",
                default = "normal",
                options = [
                    schema.Option(display = "Level vs normal (low tan, normal green, high blue; flood colours above flood stage)", value = "normal"),
                    schema.Option(display = "Flood stage (blue to yellow, orange, red, purple)", value = "flood"),
                    schema.Option(display = "Rising or falling over 24 hours (blue falling, red rising)", value = "trend"),
                ],
            ),
            schema.Dropdown(
                id = "outlines",
                name = "Outlines",
                desc = "Boundaries drawn behind the river.",
                icon = "map",
                default = "states",
                options = [
                    schema.Option(display = "None", value = "none"),
                    schema.Option(display = "States", value = "states"),
                    schema.Option(display = "States and counties", value = "counties"),
                ],
            ),
            schema.Toggle(
                id = "show_name",
                name = "Show Name",
                desc = "Show the river's name in a corner.",
                icon = "font",
                default = True,
            ),
        ],
    )

# --- GENERATED by gen_rivers.py; do not edit by hand ---

RIVERS = [
    {
        "key": "mississippi",
        "label": "Mississippi",
        "short": "Miss.",
        "line1": (28, 1, "00242111121242321202122323222321201"),
        "states1": "wACAQHIAAADgAIBgYYAAB5AAgGGwQAAJmAD/4RwwABGYAIAhBwgAIQf/gCEDCAPhBwCAIIIIDNYBAIA/wgjw2IEA/+BCCIDw/wCAYH4T/fARAIAQZ/4HeBH/8BBGQgP4ECAQH4ZCBwAQIB/4xEP+ABAgEAhEZP4AECAQCCTcnAAQIBAIJwmMABAgEAg8HwQAn///////+ABQICQIMAgIADAgJgggEAQAECAmDD//CAAQICfsRImQABAgIHxEiGAAMCAgB8yEgADwICAESMUAAAwv4AKIwgAAA/IAAv/GAAAAAQACHHwAAAABOAQfJAAAAACkBwjSAAAAAEQY8BIAAA",
        "counties1": "",
        "line2": (56, 3, "6001022432111110112220113244123422210220032112124223223232322213232122100210"),
        "states2": "sAAAAEAAEABnHAAAAAAAAJAAAABAABAAAgMAAAAAAACQAAAAQAAQADwAwAAAAAAkjAAAAEAAEADkACAAAAAAWoMAAABAABgBiAAgAAAAAIKBAAAAQAAIAQwAGAAAAACCgwAAAEAACAEDgA4AAAABAkOAAAB///gCAGAEAAAAAQJDgAAAQAAQAgA8AwAAAAEBgEAAAEAACAIAEwCAAAAGAYBD///AAAgCAAIAgAAP/AAALwAAQAAIAQACAIAAMIwBgDkAAEAACACABABAAMCUBoABAABAAAgAQAQAQAEAkgiAAQAAQAAIAEAEAEAHAJLwgAEAAEAAD//gBABAeACigIABAAB//wgAIAwAgEAAowCAAQAAQD/4ADAMAIBAAP8AgAEAAEAAHAAf/AEPgAGBAP//AABAAAQADAwBNf/x/YABAQAAQAAGAAwf/8QAEYxAAQEAAEAABgA4ECAEABkfgAEBAABAAAYAMBAgBAANe4ABAf///gACABAQIAQAG/gAAQAIAAIAA//gECAEABeAAAEACAACAAMAQBAgBAAaAAABAAgAA///gGAQIAwP8gAAAQAIAAIAAIBgECAf/+IAAAEACAACAADAMBAgMNxkAAABAAgAAgAAQDgQMGCueAAAAQAIAAIAAEAcEG9gQzAAAAEACAACAABADBCBwYIwAAABAAgAAgAAQAgigIEBMAAAAQAIAAIAAEAEPwDCANAAAAEACAACAABAAmAAZgAgAAABAAgAAgAAQAPAAPgAIAAAgf///////8ADQAMAAEAAAEEACAAP8AB////////AAAAhAAgACBAAQA4AAGAAQAAAEwAIAAgQAEAOAADAACAAAAoACAAIEABABgADgAAgAAAGAAgACBAAQAQABgAAIAAAAgAIAAgQAEAP///4ACAAAAIACAAIEABACOCDBwBAAAABAAgACBwAQBgggQCHgAAAAQAIAAgDgEAQIECARAAAAAMACAAIAHnAMCBAQDgAAAACAAgACAAOcDAgQEBAAAAAAgAIAAgAABAgYEAggAAAAAIACAAIAAAf4GAgEIAAAAD+AAgACAAAECBAIBEAAAAAAYAIAAgAABAwQCAKAAAAAABwCD/4AAAQIEBgDAAAAAAADAvwAAAAEEBAQAQAAAAAAAP+CAAAAAhAQEAIAAAAAAAAAAQAAAAIfl/gCAAAAAAAAAACAAAACAJQPDAAAAAAAAAAAQAAAAgCUAPQAAAAAAAAAAEAAAAQA/4ACAAAAAAAAAAAh4AAEACBmAgAAAAAAAAAAIhAAD+AgGQIAAAAAAAAAABoQABAZwACBAAAAAAAAAAAECAAgBsAAQQAAAAAAAAAAAAQAwAAAAEEAAAAAA",
        "counties2": "",
        "gauges": [
            ("05200510", 1, 2, None, None, [63.48, 74.06, 117.0, 188.0, 268.0, 429.2, 612.6]),
            ("05227500", 4, 7, None, [12.0, 13.0, 15.0, 18.0], [565.97, 747.89, 1116.25, 2308.75, 4044.75, 6652.5, 8501.5]),
            ("05355250", 7, 14, None, [12.0, 14.0, 15.0, 16.0], [7880.0, 8515.0, 10700.0, 18600.0, 36675.0, 61200.0, 80475.0]),
            ("05420400", 11, 25, None, [15.0, 16.0, 18.0, 20.0], None),
            ("05587450", 18, 40, [15.02, 15.13, 15.32, 15.79, 16.75, 21.54, 24.76], [18.0, 20.0, 24.0, 29.0], None),
            ("07020500", 21, 44, [0.92, 1.7, 5.24, 13.57, 24.11, 31.55, 34.92], [25.0, 27.0, 35.0, 40.0], None),
            ("07374000", 32, 69, [5.0, 5.97, 11.1, 20.89, 31.98, 40.8, 42.96], None, None),
        ],
    },
    {
        "key": "missouri",
        "label": "Missouri",
        "short": "Mo.",
        "line1": (9, 12, "4546760765677710001070060000000001002022122223110221100010212222120031107020100702"),
        "states1": "AAAAIABADMQAAAAgACADOwAAACAAIAAwAAAAIAAgAeDAAAAgACAHYCAAACAAEAxgIAAAIAAQCBggAAA///AIBjAAACAAIBACKAAAIAAQEAEMP//gABAQAQRgACAAEBAAA+AAIAAQDAAAIAAgABAGAAAgACAAEAIAACAAIAAf/wAAIAAgABABAAAgAD//8AEAACAAIABwAP8AIAAgABAAQP/gACAAEABBECAAIAAIAMEQIAAgAAgBgRA///4ACAEBEAIAAgAP/wEQAgACAAQCARACAAP//gMBEAIAAgACAwEQAgACAAMBgRACAAIAAQCBEAIAAgABAEEQAgACAAEAQw",
        "counties1": "",
        "line2": (18, 24, "5444456767670076665566770677070120000010002700700760000000001070000003102000022002221122212312241321012002222110110070101102212220222221212010331117107071032001207000100761"),
        "states2": "AAAAAAAACAAAABgAAaAAAAAAAAAAAAgAAAAYAABZgHgAAAAAAAAIAAAAGAAABv+GAAAAAAAACAAAAAgAAAACAQAAAAAAAAgAAAAIAAAABAAAAAAAAAAIAAAADAAAAAQAgAAAAAAACAAAAAQAAAAIAMAAAAAAAAgAAAAEAAAA+ABgAAAAAAAIAAAABAAAAxgAIAAAAAAACAAAAAQAAAwQADAAAAAAAAgAAAAEAAAwMAAcAAAAAAAIAAAABAAAYCAABAAAAAAACAAAAAYAAEAwAAQAAAAAAAgAAAACAABAHwAEAAAAAAAIAAAAAgAAQAPgCAAAAAAAD/////4AAIAAOAgAAAAAAAgAAAACAACAAAwLAAAAAAAIAAAABAABAAAGD4AAAAAACAAAAAYAAIAABgCAAAAAAAgAAAACAACAAAYAwAAAAAAIAAAAAgAAgAACAEAP////+AAAAAIAAQAAAQBgCAAAAAgAAAACAAEAAAAAMBgAAAAIAAAAAgABAAAAAB/oAAAACAAAAAIAAMAAAAAOCAAAAAgAAAACAABgAAAAAAgAAAAIAAAAAgAAOAAAAAAIAAAACAAAAAIAAAwAAAAACAAAAAgAAAACAAAEAAAAAAgAAAAIAAAAAgAABgAAAAAIAAAACAAAAAIAAAIAAAAACAAAAAgAAAAD////AAAAAAgAAAAIAAAAAgAAAQAAAAAIAAAACAAAAAIAAAIAAAAACAAAAA////7iAAACAAAAAAgAAAAIAAADugAAAQAAAAAIAAAACAAAAA4AAACAAAAACAAAAAgAAAADAAAAf/8AAAgAAAAIAAAAAQAAACAAAAAIAAAACAAAAACAAAAQAP//+AAAAAgAAAAAgAAAEAABAAgAAAAIAAAAAIAAADABAQAIAAAACAAAAACAAAAwAQEACAAAAAgAAAAAwAAA4AEBAAgAAAAIAAAAAEAAAYABAQAIAAAACAAAAABAAAEAAQEAD//////8AAAAQAABAAEBAAAEAAAABAAAAEAAAQABAQAABAAAAAQAAABAAAMAAQEAAAQAAAAEAAAAf//+AAEBAAAEAAAABAAAACAABAABAQAABAAAAAQAAAAwAAQAAQEAAAQAAAAH////+AAEAAEBAAAEAAAABAAAAAwABAABAQAABAAAAAQAAAAGAAQAAQEAAAQAAAAEAAAADAACAAEBAAAEAAAABAAAAAQAAQABAQAABAAAAAQAAAACAACAAwEAAAQAAAAEAAAAAQAAwAIBAAAEAAAABAAAAAEAAGADAQAABAAAAAQAAAABAAAQAQEAAAQAAAAEAAAAAQAAEAIBAAAEAAAABAAAAAEAACACAQAABAAAAAQAAAABAAAgBA",
        "counties2": "EG3UEIQIeEfF8hAvgqAAADA8d/CECAhCJSf/4IJZgHijHjwwhH//8iU+k3iCF/+G/pngE4zhCD///Ivo/hEGAQy4eD8Powj4Dmf56IIRBAAN/8xh/CPIjYp9LCiCEQ8A5dOHwHAiOI+aJafv4hEI4N7QhuHgIj/H3//8qjIQ+L9vuFwhMD4aRnJER/o+E5CM7ChmITARuv/iRESKIhyYfBh8Y+///GqGEkRE/uPdqGw/1/H8EDP//Z///4qiZezo5ZPYjD4wzES5ERUKo8XW+AmeSIr6MI/k6f/3D7pFX44IvF//ijDoXMkRE/nufyvKDO5kmh0wv/////9pLqX4uwz7xJojP4hEDIkT//8kX64LDDS2IaCIRA/51yjf/9C+H4Qc7+CgiEf8iXco/6Rf1giCHNEAoQhEhIkf/++n8nb4whzh4OEPxQf/+/qf/R/6GEMf////+H3MiS7b/ynxvxJhmAEwEQhEX/k7/1/vIfs/Mf4BEBEIRfjPq/n3Ob//Td/rgQ/xD8dfyP7/P/+tesBuaIECEQoMTsiSp+r+5U/geMhB/hH5HH////7//v//cHeIQ+IRD/fF0qqfm3+sVHw9+HLiEQ/kZH/////+r/+7ZNhsMhEIfH/LcpKSS+3IKMf4RhoRCHRE6taSkkp//yTPCOH////H/P//////9Jw/8O+wCBCIRES3K/8/6X//KPAqEAgQiEREif5VKv/4rKj/+hgIEI////9X///rKKj//QoMCBCKJAfv/lUr6T//P/K6BAgT+iQEoi////+qXyeS+gQP/kvkBKPvNS6pf/8kH6v/+BZJJASivzKr/+rIJBEoQAgSSSf//v///1S/////+EAIEk/85Kurp1VX/KwBAShACBJJJKSqq////PetAQCvwDgTzyf//v+2rVe//QEA6EAgEnnklCvf///++TsBAfhAIDIPJ/w/+8qlV+krAQb4QCAiCTyEKuv///2//QH/////////x///1VKv748BA+H8BbCCJERKu////6uJAQF3fASQgj////pVUqv/+QEB7EQImZ8kkqqv////rT8BAeRECPmR/////qnf9K8dAQEUR/6PESS0qqv92X//9f8BFEQGjf8n///////U/9UB/8xEP+/EJJS0pV/Z/f/fAQH/x+J//CSUpKVf/39r9QH/eFwCL/////////3Kft0BAd////NEhJKcrL3Xfde/AQGQxA5iRISSl+7v/+/19wEB8IQf4/z///y//+r+93+BAZDEa/MMhJKX/n9/q/93wQMQhIhWiIf//Kvfyu/3/z/+EET4f4j9VJX5dXv/vr4h5///i/D/xVSXr3/O7PfvIQJARHoPi////KVXS/y/vw",
        "gauges": [
            ("06018500", 5, 9, None, [6.0, 7.0, 8.0, 9.0], [44.61, 72.58, 160.0, 299.0, 558.4, 777.52, 871.45]),
            ("06054500", 8, 16, None, [10.0, 10.5, 11.0, 12.0], [1594.3, 2045.3, 2853.88, 3997.5, 5439.5, 9552.45, 14964.75]),
            ("06078200", 12, 25, None, [13.0, 13.5, 15.0, 17.0], [3064.75, 3240.0, 3600.0, 5140.0, 7115.0, 10206.15, 16381.0]),
            ("06115200", 19, 39, None, [26.0, 27.0, 29.0, 33.0], [3729.8, 4003.8, 5021.5, 7206.0, 9980.0, 16802.0, 24900.0]),
            ("06177000", 26, 55, None, [21.0, 23.0, 26.5, 27.5], [1702.15, 2894.7, 4383.5, 8200.0, 13840.0, 19138.0, 21729.0]),
            ("06330000", 31, 64, [2.59, 2.94, 4.61, 13.96, 18.38, 20.05, 21.31], [20.0, 22.0, 24.0, 26.0], None),
            ("06342500", 39, 84, [0.55, 1.08, 2.99, 6.21, 9.09, 11.31, 12.41], [12.5, 14.5, 16.0, 18.0], None),
            ("06440000", 47, 100, [6.21, 6.42, 6.96, 7.87, 8.92, 10.68, 11.38], [12.0, 13.0, 15.0, 17.0], None),
            ("06453020", 53, 113, [21.11, 21.62, 23.16, 25.35, 27.01, 29.85, 31.11], [29.0, 30.0, 31.0, 32.0], None),
            ("06467500", 56, 118, [8.83, 9.84, 10.57, 11.88, 15.36, 17.34, 18.44], [18.0, 20.0, 21.0, 23.0], None),
            ("06601200", 59, 126, None, [33.0, 35.0, 38.0, 41.0], [12200.0, 13600.0, 22375.0, 28400.0, 39100.0, 70210.0, 85205.0]),
            ("06610000", 62, 131, None, [21.0, 27.0, 32.0, 40.0], [7841.25, 9745.2, 18112.5, 29860.0, 44687.5, 65393.5, 76516.0]),
            ("06810070", 65, 137, None, [33.0, 34.0, 38.5, 43.0], [20120.0, 22000.0, 31800.0, 36000.0, 40400.0, 44900.0, 52780.0]),
            ("06818000", 68, 142, [2.33, 3.14, 6.15, 8.78, 13.93, 19.21, 21.05], [14.0, 17.0, 21.0, 27.0], None),
            ("06893000", 71, 147, [4.89, 5.53, 8.72, 11.71, 18.3, 23.81, 26.67], [29.0, 32.0, 35.0, 49.0], None),
            ("06906500", 74, 155, [6.15, 6.79, 9.84, 12.26, 19.34, 25.73, 28.43], [22.0, 25.0, 27.0, 32.0], None),
            ("06910450", 77, 162, [1.85, 3.12, 5.31, 9.07, 15.9, 21.5, 25.11], [21.0, 23.0, 25.0, 30.0], None),
            ("06935965", 80, 170, [5.83, 7.0, 9.31, 13.91, 20.57, 25.35, 27.55], [23.0, 25.0, 30.0, 36.0], None),
        ],
    },
    {
        "key": "ohio",
        "label": "Ohio",
        "short": "Ohio",
        "line1": (57, 2, "3457444243234121334544123232325332252324553444644564412345223432532535442523244225432"),
        "states1": "QACAAEA8gAAgAYAAQMT//yABAABjBAAfYAP//5wEAADAAgAgAAQAAAACACAABAAAAAIAIAAEAAAAAgAgAAQAAAACACAABAAAAAIAIAAMAAAAAgAgAAwAAAACACAADAAAAAIAIAAcAAAAAgAgABwAAAACACAAFAAAAAIAIAAX//8AAgAgAGArYAACACAAgDPggAQAcAGAInDABgA4AwAEHCACAexiAAgIIAQBA9YAUAhABAIADADgGEAIFgAYAIAUMAgUABgBgAMYH3gACAEAAAQdoAAEAwAABBAAAAYGAAAEcAAAB3gAAAXAAAAJ4AAAB8AAABAAAAADAAAAIAAAAA",
        "counties1": "",
        "line2": (114, 5, "344557544434224433224342411214103233345464444212232323213333453243222366432312432445645634354444545466446453413124435442123433323546441422445342545352254424321243442134544332"),
        "states2": "YAAAAIAAAAAYAADwQAAAADAAAACAAAAAEAAPIEAAAAAYAAABgAAAABAAMCBAAAAACAAAAQAAAAAQAMAgf////wgAAAEAAAAAEAEAIAAAA/8IAAABAAAAACgGACAAAAAAGAAAD///+ABGGAAgAAAAABAAAAgAAP//geAAIAAAAAAQAAAIAAAIAAAAACAAAAAA4AAACAAACAAAAAAgAAAAAIAAAAgAAAgAAAAAIAAAAAAAAAAIAAAIAAAAACAAAAAAAAAACAAACAAAAAAgAAAAAAAAAAgAAAgAAAAAIAAAAAAAAAAIAAAIAAAAACAAAAAAAAAACAAACAAAAAAgAAAAAAAAAAgAAAgAAAAAIAAAAAAAAAAIAAAIAAAAACAAAAAAAAAACAAACAAAAAAgAAAAAAAAAAgAAAgAAAAAYAAAAAAAAAAIAAAIAAAAAGAAAAAAAAAACAAACAAAAABgAAAAAAAAAAgAAAgAAAAAIAAAAAAAAAAIAAAIAAAAACAAAAAAAAAACAAACAAAAAAgAAAAAAAAAAgAAAgAAAAAYAAAAAAAAAAIAAAIAAAAAGAAAAAAAAAACAAACAAAAADgAAAAAAAAAAgAAAgAAAAAoAAAAAAAAAAIAAAIAAAAAKAAAAAAAAAACAAACAAAAAE//////wAAAAgAAAgAAAABAAgm4AAAAAAIAAAIAAAAAgAIXDAAAAAACAAACAAAACQACYIQAAAAAAgAAAgAAAB4AAoDGAAAAAAQAAAIAAAAwAAMBJYAAAAAEAAADAAAAYAACARmAIAAABAAAB8AAAEAAAAIJgDgAAAYAAAQgAAHAAAAEAPg2AAACAAAGIAACwAAABAA8EQAAAgAAAhgAAoAAACgAGAEAAAIAAMYHAQQAAABQABgCAAAEAAD4AfeGAAAAQAAwAgAABAAAQAAcxgAADIAAIAIAAAgAAIAAAGwAAA6AAGACAAAIAAEAAAA4AAAZAABwBAAAEAAGAAAAIAAAEAAAeAQAACAAhAAAAGAAABAAAAwCAAAgAYgAAABAAAAgAAADAQAAYAFoAAAAIAAAQAAAAMCAAEcZMAAAADAAAMAAAABAwAB/9QAAAAAQAACAAAAAADAAbGIAAAAAGAABAAAAAAAIAMAAAAAAAAgAAgAAAAAACACAAAAAAAAGAAEAAAAAAAwAwAAAAAAAA4AGAAAAAAAEAcAAAAAAAAMAXAAAAAAABAcAAAAAAAAMhHAAAAAAAAgEAAAAAAAAGN7AAAAAAAAM9AAAAAAAADAzAAAAAAAABxwAAAAAAABAAAAAAAAAAAcAAAAAAAAAgAAAAAAAAAABgAAAAAAAAYAAAAAAAAAAAIAAAAAAAAMAAAAAAAAAA",
        "counties2": "ohFCAIAYhCEQAABwQQIQfz/9QgD/GIQhEAAHoEECED4Ih///gQiEP/AAOiBBAhAi+IEkAIH///RwAOIgf////w/xJ4GBCIiEEAMiICBByCAIfySBARCIhCgEIj/gQQggiEEkj///+IROHCIgIIEIEHhBP4lESE//keQmICCBCBA//+XJRExIifMkPiD//wj/8QQkSUfH+P7zpDP/EIT/+yEEPHlOfE/M/iQSIR+HZAjhDCQJdERISIImfiEbwcYHIfwl+8RH/0j/59IhEn+jBz98Jw5/zIn/giyT/eIg8TziX/wKREkIiIJ4si8iIIzcI/MH+kT/D4j/z74mPiGHjiI/Bgp/rfiYkUjn5iPjA34iIQIKyKUo/5FohD4iIg+SPjnjD5ylL4j/KI8iIj+9l+NuPwiWvyv4x7/5I+Rl//whzBEI8/P5HIX4meR8RZ7mI4gR/5ISSfP5D4l4LMi7JSaIH4if/4mQvRDPbGOZtiTk//CLkRT/HbOQWWdBnx52OERQjv/0ifez+PFhw3cflz/EUIyRFIkQ/h+f4M4Q1GzuR9CMkRe5H6IYiPy0ESXGwvxQj5/87/Ej+LiziDFjYf8EX/zyJMl5Inj/oIgiQiHiHPCMkifJNz4vkaCIIsLgohbTjJI8+SPiZMj///////Ijn4+f5KnyInT5Hkim54p/4nCJmST/vzuPhteJ3bTayKIR+fkniJFPH655iads0ci+Hwrf/IiRw/N35o5D3P6YhBEekkn/+kIxySf9xNfO+I//8/JPrNx/v5C03PXib8iIiJITel+YQuGpzsWbpxD/+IiaH/J7n+J9z0v9F+Pp+Ej4j/ET+9I+X3prHTba+WxPz/vRHF/yI9pr8hOmlel4fESKUfn/+i3TT5ZRS85P38REkl8m3V/+d8488Spp/RiEf/NRP+37cj/17LIVpu3w/8K/8SPXPzm8mcc6VTcNPMRCtp/3l3lu5QtERc650ieEQuKRW/304r8OaEja/fE3/H///3ElnzO1jhjoryOwnEfI+aYjv5tvE1somaPG/PxGSak3rt79+J4xxwjvNOrWfEk/dvPfzp7+cIOWYwzVo0f//910/f+d812G86XOzpbESfO42aU/f6nnRWs583+MZEtmOY8/J+/+s3mttz/v///+P28X/qW89xSHKMPbX0k6T8yZljr/HI/KiR5i379JEl+/mP/p7TeOOXM3tfb9ST/c873KZz/TkhH9Q90zvfk/dsTmysf5V3N+P4ZXn/4J/7tmTn+syb3Rz+fEeX9/C516v19OUEW53xsn70+jxw6cvqPwykiPv399Ojvk43v49/fymMu1+f3xkOQxaHYz2OaTNI/c49KP55+v8R5O1w",
        "gauges": [
            ("03010500", 3, 5, None, [17.0, 23.0, 25.0, 27.0], [48.83, 72.03, 205.15, 572.6, 1537.0, 3012.0, 3736.0]),
            ("03011020", 6, 10, None, [9.0, 12.0, 14.0, 21.0], [181.42, 249.05, 600.4, 1634.5, 4297.0, 8529.2, 11199.0]),
            ("03015310", 9, 15, None, [12.0, 14.0, 15.0, 17.0], [1428.4, 1602.5, 2005.0, 4022.0, 10600.0, 17280.0, 21282.0]),
            ("03025500", 12, 24, None, [13.0, 17.0, 19.0, 21.0], [814.93, 1220.0, 2871.88, 7091.25, 18143.75, 30058.0, 36667.5]),
            ("03033000", 15, 31, [9.33, 9.45, 9.77, 10.57, 11.19, 12.19, 12.93], [14.0, 19.0, 21.0, 23.0], None),
            ("03049500", 18, 35, None, [17.2, 21.0, 24.0, 26.0], [1990.95, 2914.0, 5921.75, 14025.0, 32650.0, 53095.5, 64664.75]),
            ("03108500", 21, 42, [12.63, 12.75, 12.97, 13.19, 14.02, 15.85, 17.57], [23.3, 33.0, 36.0, 38.0], None),
            ("03111520", 25, 51, None, [26.4, 37.0, 39.0, 43.0], None),
            ("03114280", 28, 57, None, [24.8, 35.0, 37.0, 40.0], None),
            ("03150700", 31, 62, None, [33.0, 35.0, 38.0, 40.0], None),
            ("03201500", 37, 75, None, [38.0, 40.0, 44.0, 48.0], None),
            ("03206000", 40, 82, None, [48.0, 50.0, 55.0, 59.0], None),
            ("03238000", 46, 96, [33.46, 33.57, 33.84, 34.34, 35.85, 40.31, 44.83], [48.0, 50.0, 58.0, 66.0], None),
            ("03255000", 51, 105, [26.17, 26.27, 26.6, 27.9, 33.73, 42.9, 47.42], [40.0, 52.0, 56.0, 65.0], None),
            ("03292000", 58, 118, None, None, None),
            ("03293551", 62, 126, [12.61, 12.68, 12.78, 12.89, 13.05, 15.12, 16.79], [21.0, 23.0, 30.0, 38.0], None),
            ("03303280", 67, 140, [10.75, 10.95, 11.74, 15.26, 25.06, 35.61, 40.19], [40.0, 42.0, 46.0, 50.0], None),
            ("03304300", 71, 147, [12.95, 13.32, 14.27, 17.49, 23.86, 32.39, 38.63], [35.0, 38.0, 48.0, 56.0], None),
            ("03322420", 75, 156, [13.06, 13.49, 14.73, 18.2, 25.18, 33.04, 37.62], [33.0, 37.0, 49.0, 60.0], None),
            ("03384500", 79, 164, None, [36.0, 40.0, 49.0, 55.0], [22000.0, 32680.0, 65370.0, 134000.0, 323425.0, 545600.0, 633680.0]),
            ("03612600", 83, 172, None, [34.0, 36.0, 42.0, 47.0], None),
        ],
    },
    {
        "key": "arkansas",
        "label": "Arkansas",
        "short": "Ark.",
        "line1": (1, 1, "221210010001000000001007010010767000101021220222021010011207270171200210121012"),
        "states1": "AAAgAAABAAQAACAAAAMAAwAAIAAAAYAAAAAgAAAAgAAAACAAAACAAAAAIAAAAIAAAAAgAAAAgAAAACAAAACAAAAAIAAAAIAAAAAgAAAAgAAAACAAAACAAAAAIAAAAIAAAAAgAAAAgAD///////+AAAACAAAAAIAAAAIAAAAAgAAAA//gAAD//wACACAAAIAAAAIAIAAAwAAAAgAgAABAAAACACAAAEAAAAIAIAAAQAAAAgAgAABAAAACACAAAEAAAAIAIAAAQAAAAgAgAABAAAACADQAAEAAAAIAHwAAQAEAAgAB4ABAAwACAAA/j0ABAAIAAALxwAMAAgAAAABgAw",
        "counties1": "",
        "line2": (2, 3, "222121221107001010010010000107000000001000010007001001010010767767070001010101011212212410212442031710201101200200020301210007100670127011100172201102212111010022"),
        "states2": "AAAAAAgAAAAAAAADAAAAEAAAAAAIAAAAAAAABgAAAAgAAAAACAAAAAAAAAQAAAAGAAAAAAgAAAAAAAACAAAAAQAAAAAIAAAAAAAAAwAAAAAAAAAACAAAAAAAAAHAAAAAAAAAAAgAAAAAAAAAQAAAAAAAAAAIAAAAAAAAAEAAAAAAAAAADAAAAAAAAABAAAAAAAAAAAwAAAAAAAAAQAAAAAAAAAAMAAAAAAAAAEAAAAAAAAAADAAAAAAAAABAAAAAAAAAAAQAAAAAAAAAQAAAAAAAAAAEAAAAAAAAAEAAAAAAAAAABAAAAAAAAABAAAAAAAAAAAQAAAAAAAAAQAAAAAAAAAAEAAAAAAAAAEAAAAAAAAAABAAAAAAAAABAAAAAAAAAAAQAAAAAAAAAQAAAAAAAAAAEAAAAAAAAAEAAAAAAAAAABAAAAAAAAABAAAAAAAAAAAQAAAAAAAAAQAAAAAAAAAAEAAAAAAAAAEAAAAAAAAAABAAAAAAAAABAAAAAAAAAAAQAAAAAAAAAQAAAAAAAAAAEAAAAAAAAAEAAAAAAAAAABAAAAAAAAABAAAAA////////////////wAAAAAAAAAQAAAAAAAAAAEAAAAAAAAAEAAAAAAAAAABAAAAAAAAABAAAAAAAAAAAQAAAAAAAAAQAAAAAAAAAAEAAAAAAAAAP///8AAAAAAB/////AAAADAAABAAAAAAAQAAAAAAAAAwAAAQAAAAAAEAAAAAAAAAMAAAEAAAAAABAAAAAAAAADAAABAAAAAAAYAAAAAAAAAwAAAQAAAAAAGAAAAAAAAAMAAAEAAAAAAAgAAAAAAAADAAABAAAAAAAIAAAAAAAAAwAAAQAAAAAACAAAAAAAAAMAAAEAAAAAAAgAAAAAAAADAAABAAAAAAAIAAAAAAAAAwAAAQAAAAAACAAAAAAAAAMAAAEAAAAAAAgAAAAAAAADAAABAAAAAAAIAAAAAAAAAwAAAQAAAAAACAAAAAAAAAMAAAEAAAAAAAgAAAAAAAADAAABAAAAAAAIAAAAAAAAAwAAAQAAAAAACAAAAAAAAAMAAAEAAAAAAAgAAAAAAAACAAABAAAAAAAIAAAAAAAAAgAAAQAAAAAACAAAAAAAAAIAAADIAAAAAAgAAAAAAAACAAAAPAAAAAAIAAAAAAAAAgAAAAMAAAAACAAAAMAAAAIAAAAA7gAAAAgAAADAAAACAAAAABkAAAAIAAABQAAAAgAAAAABv6A6CAAAAYAAAAIAAAAAAc9x7YgAAAGAAAACAAAAAAACGgBoAAABgAAAAgAAAAAAAAQAGAAAA4AAAAIAAAAAAAAAAAcAAAMAAAACAAAAAAAAAAABAAADg",
        "counties2": "LE//AgghCIRD4Qn/SJ+f/BPP/////////j//Rkj4+Iw0TQEICCEIhEIixEf/iJC2+FEBCAghCIRCIoR+SIyeo9BRARgIIQiEQ+LES0j78/HQYQEYCCEIhH4jf8v58yx38H/5GP/////CP+Z75yNH+MgoCR/oQgiEQ+JiP8QnxEhsKA8QCEIIhH4jw+R3/GRfZCwIEAxCCIRCImIkXCR4Wkf0CBAP////wiI+P8Qn2fJEPAgf/IkQhEP+EmRH5Z9fLAf/8AiJkIR+I/JEdDymU/gECEAEiJCEQiET/9wkdFAH/Ah//////8IhEkREJF/QAQgIwQRIEEJ/+R5ER+fIfwGID8EESBBiQI/yRHQ8aGQAmAhBBEjwfkCIQ//cJD/kAO+IQQRIn8Rg+EJER8/SJIfAeEEESJBH4IhCREX58/T/wFhBB/+QfD+IQ//ESRMfCPDP//xIkEQhCH5Ef8kPnwiQgAgESP/H4f/CRERP+Jj5lwAIB/+IfD8IQ/xEfIj8DxwACASIiEQhCH5H/8SIRAMQAAgEiIhEIQhCREREiEaBEAAIBIiIRCEIQkREf8hO/////////////////HE/ywgQBAQEBAQgaCEHJkfRBHgIEAQEBAQEEEghBSZ0X/xPDDAEBAQEBBxIJgUmXFCERAQgBAQEBAf0T/4F98RQhEQEIAQP///8h0gnBTx/////BCAEDAiIRIX4JsckQRFkMAggBAgIiESECCZ1JEGRRGgGP/wICIhEnAgvPSRfUSfYA0BH6AiIRP///f3343+4l++AIC////4giJiFPUMifJF5ACAoCIhFYIiPhRliIhf/cfH8KAiIRL+IiI+9IiJzGiEfhjgIiEQgn/iJdT///5MhAAIv///8IJCI+IfmiQiSIQADKAiIRODwiIX0JIkI8iEAAegIiEe/kI/nFj356XshAADIEIhEIJ/5Pn//+T8+4T//i9CIRCCIySPrJjkkEiEgDA////3/iOlnMiTn5HM/4AgIEIhHIIypRn4vh8/+8CAIOBCIRxCEn+RCOIz0l/AgCCgQiEW5/P7kRCCf5JRAIHnP///97QSCPEQ5/kSWQCfPCEREJI8Pz2f+JxMmt0AmBQhERCeZmHvJh+IzuvrAJAUIREQncOhSeQQiOv/OQDwF/////PiIXiEEL/6Ign/kBAiIhERPj8IhDCo+iOcEBAQIiIRGQ/hz//g/J+jnBAf+CIiERcJkfkIIJZE//QQEAgiIhERCIvrD7DdzIj4MBAMP/////+d/x7c/O/IiCAQBCIiERMImSnkR5y9f7ngEAciIhERCJEIxEOMkkiZABAH4iIREQiRCIRCfpJI/wAQBCIiEREI//6fwhPyTLg",
        "gauges": [
            ("07081200", 1, 1, None, [8.5, 9.0, 10.0, 12.0], [11.0, 12.65, 17.13, 24.49, 63.31, 196.53, 362.87]),
            ("07109500", 10, 21, None, [6.0, 7.0, 10.0, 12.0], [203.5, 230.36, 298.5, 567.12, 991.1, 2277.75, 3320.38]),
            ("07124000", 15, 31, None, None, [8.72, 10.72, 18.4, 89.22, 288.75, 550.04, 1276.35]),
            ("07133000", 18, 36, None, [9.0, 11.0, 13.0, 15.0], [2.0, 2.22, 4.1, 20.17, 145.06, 537.18, 814.71]),
            ("07138000", 21, 43, [2.62, 2.74, 3.21, 3.89, 4.83, 5.78, 6.68], [9.0, 10.0, 12.0, 14.0], None),
            ("07138070", 24, 48, None, [13.0, 14.0, None, None], None),
            ("07139500", 28, 57, [5.66, 5.83, 5.89, 6.0, 7.23, 7.34, 7.67], [10.0, 11.0, 13.0, 15.0], None),
            ("07141300", 34, 69, [0.62, 0.66, 0.9, 1.52, 2.79, 3.98, 4.92], [10.0, 12.0, 16.0, 18.0], None),
            ("07143330", 38, 77, [1.83, 1.89, 2.1, 3.0, 3.94, 5.13, 5.94], [8.0, 10.0, 11.0, 12.0], None),
            ("07144550", 41, 82, [0.77, 0.93, 1.29, 2.25, 3.22, 4.89, 6.12], [10.0, 12.0, 15.0, 16.2], None),
            ("07146500", 45, 89, [3.14, 3.28, 3.77, 9.67, 11.11, 12.98, 14.2], [9.0, 11.0, 17.0, 21.0], None),
            ("07152500", 49, 100, None, [16.0, 16.0, 18.0, 21.0], [220.55, 301.19, 600.0, 2197.5, 8972.5, 19738.0, 26827.75]),
            ("07164500", 52, 107, None, [15.0, 18.0, 20.0, 22.0], [184.0, 272.14, 794.1, 3130.0, 12900.0, 26990.0, 37542.5]),
            ("07194500", 55, 115, None, [27.0, 28.0, 32.0, 34.0], [646.84, 1022.02, 2578.75, 12650.0, 48450.0, 96265.0, 119087.5]),
            ("07250500", 60, 126, [19.05, 19.13, 19.23, 19.35, 19.48, 19.64, 19.91], [22.0, 22.0, 26.0, 31.0], None),
            ("07258000", 67, 138, None, [32.0, 32.0, 36.0, 40.0], None),
            ("07263500", 72, 148, None, [18.0, 23.0, 25.0, 27.0], [2251.2, 3044.2, 6542.0, 20800.0, 73270.0, 136040.0, 186820.0]),
            ("07265280", 76, 158, None, [30.0, 31.0, 32.0, 33.0], None),
        ],
    },
    {
        "key": "redsouth",
        "label": "Red",
        "short": "Red",
        "line1": (4, 2, "000007010100000100100171206100276117000071110701232212121110127003222121132"),
        "states1": "BAAQAAAIAAAEABAAAAgAAwQAEAAACAADBAAQAAAIAAIEAA4AAAgAAgQAAZAACAAMBAAAbkHIABgEAAAP7jgAGAQAAACQGgAYBAAAAAAOABAEAAAAAAIACAQAAAAAA/gYBAAAAAACP/AEAAAAAAIAEAQAAAAAAgAYBAAAAAACAAgEAAAAAAIAGPwAAAAAAgAQAAAAAAACADAAAAAAAAEAYAAAAAAAAQAgAAAAAAAAgEAAAAAAAACAfwAAAAAAAIAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAABAAAAwAAAAAMAAAE4AAAAAngAAQQAAAAHh4CCAgAAABgAYA",
        "counties1": "",
        "line2": (9, 4, "01007000006007110101001000000001106106112010701710612021761017022776117200271760170000710120010270107121324212320212112121011121001217006103232122211212211232"),
        "states2": "ABAAAAIAAAAAAABAAAAAAQAQAAACAAAAAAAAQAAAAAEAEAAAAgAAAAAAAEAAAAADABAAAAIAAAAAAABAAAAABQAQAAACAAAAAAAAQAAAAA4AEAAAAgAAAAAAAEAAAAAMABAAAAIAAAAAAABAAAAADAAwAAACAAAAAAAAQAAAAAgAMAAAAYgAAAAAAIAAAAAIADAAAAB8AAAAAACAAAAAKAAgAAAABgAAAAAAgAAAAPAAIAAAAAO/AAAAAIAAAADgACAAAAAA7YAAAACAAAAAwAAgAAAAAADQIAAggAAAAcAAIAAAAAAAbdwH0IAAAAGAACAAAAAAACPO/AiAAAABgAAgAAAAAAAAg4AHgAAAA4AAIAAAAAAAAAAAAdgAAAEAACAAAAAAAAAAAAB4AAACAAAgAAAAAAAAAAAACAAAAwAAIAAAAAAAAAAAAAgAAAEAACAAAAAAAAAAAAAIAAABgAAgAAAAAAAAAAAACAAAAwAAIAAAAAAAAAAAAA//gAEAACAAAAAAAAAAAAAIH///AAAgAAAAAAAAAAAACAAAAwAAIAAAAAAAAAAAAAgAAAIAACAAAAAAAAAAAAAIAAABAAAgAAAAAAAAAAAACAAAAYAAIAAAAAAAAAAAAAgAAAGAACAAAAAAAAAAAAAIAAAAwAAgAAAAAAAAAAAACAAAAMAAIAAAAAAAAAAAAAgAAAOAACAAAAAAAAAAAAAIAAADgP/gAAAAAAAAAAAACAAAAwAAAAAAAAAAAAAAAAgAAAMAAAAAAAAAAAAAAAAEAAAGAAAAAAAAAAAAAAAAAgAABgAAAAAAAAAAAAAAAAIAABgAAAAAAAAAAAAAAAACAAAIAAAAAAAAAAAAAAAAAQAAEAAAAAAAAAAAAAAAAACAABgAAAAAAAAAAAAAAAAAgAAwAAAAAAAAAAAAAAAAAEAAIAAAAAAAAAAAAAAAAABAABAAAAAAAAAAAAAAAAAAQAA//wAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAIAAAAAAABAAAAAAAAAAAACAAAAAAABv8AAAAAAAAAABAAAAAAAAgAgAAAAAAAAAAf8AAAAAAIAIAAAAAAAAAAeAwAAAAAEABAAAAAAAAAAYAD+AACABAAMAAAAAAAAAYAAAQAAYAgAAgAAAAAAAAEAAADwAA",
        "counties2": "7B////4IERyRH4xMe2IIiUAQIQhC//EWkjCIeYfjGP1AECEIQ4gQkpIh+H8IRv8HQPAhCEPMEJP/IQhxGPpt/0GQIQhCXn+f7yEQQRfSLQ/DH////nJAkCHhEHP+YiUNfhEIQiJDQfjjOfhOIzMt/SgRCEIjxuMPvk8fxCGNPYsoEQhCIswtChPEEMQj3+OPLxEIQiJ8MQvxBBD//uRBtS/////+FhH4IQQw5F5EYeQgEhCEQxP3CD//4P5H9HHk8BIQhEPw34/vkCDKYR/795AyEIRCEITYNBAgi+MxH9wQMhCEQhCEbf4/8M47GROUGD/////f/Ef96Fy+P/n5lwgiEIRCcIREo0hHjmRPO5cOIxCEQhCERCEIQ/JkSQk0D+EQhEIQhEQhCEJ9RJkP5Qg//////////z9+CfxZ+yUIIRCEQ5DkQhHv7gmn+QsvCCEQhEIQhEIQjGX54h8JtgghEIRCEIhCEIhlC0IGCzIIIRCEQhCIQhCIfQ//wgl2+D//////////n/UKyf//1wggIQiEIhCEQvI/+miCH/wIICEIhCIQjEOuI2tpwh6wCCAhCIQiEIhCIiP5aTO58QggIQiEIhD//iPmCS8d+/YIP///////iEIiegmpcY/fCCAhCIQiCMhCIQ/YudG42QggIRCEIgh4Q/+O++CfaNAIICEQhCIwe8bBiIz5DZ+xCD///+Qi6Hc4IfkMT/iT4f/kQhE//43EID+JDCcJk/88hEIRCETHxhB8ifw9D7IhMIRCEQhEQUNNkI/D8Ql34CyEQhMIRH5j9hiIQiJ5Pucn///z+EZ4NiEMTHEz0V8/YgRCHg/GxOgxHeYvGYmb8UEEQhOEd4WMMOc/JQnN0hFB9EIQhDrihGiCCK2/d9//QD9CEIQiHIeLgjxoxwf5yUAgwhCEIhhejIZkP8EFcQlAQP///+IIcLC+xhpBBDEJoIAwBAQiD+D4w4nyQRx//xkADAQEP/wxic7REn/sckoFAAYEBBCMTQ544RpCT/ZLAgACB//wiMMOSHEKgkTfyQEAfwQEEIzBPkzYioZERHnGwEMEBBCF4ONvnPuEeF6JOGBCBAQf/z/Rqc/LZ/36jQgQQQQEBBEHich6C/5H/8UIDcP///wThMd4IQ8CZxj/CAcCAICH8kxcWxF5A2+JeQgDAgCDwIood/yx6f/z79cIAIIAgkCNFMY4WE8AQT7fCABiAIJ+jWKOaA/CAEFrfQgBn8CCIbDxCVwIZgBDzeUIAgAhgiB9l5i3CGP8Q4PzCAIAIf//xgjwY9n+A0LjGQgEABGECMMQiOC+YAD+NAmIBAAJhAhDEQmxIIAAARIEaAQAB4QIQ+MGFxMAAAD0Ag",
        "gauges": [
            ("07295500", 5, 10, [-0.13, -0.13, -0.05, 0.08, 0.6, 1.39, 1.85], [13.0, None, None, None], None),
            ("07297910", 9, 17, [4.9, 5.03, 5.38, 5.74, 6.04, 6.74, 7.0], [9.5, 10.0, 15.0, 20.0], None),
            ("07299540", 14, 28, [6.8, 6.88, 7.09, 7.59, 8.27, 8.64, 8.77], [10.0, 10.0, 14.0, 20.0], None),
            ("07308500", 22, 47, [2.25, 2.44, 2.83, 3.65, 5.68, 6.66, 7.41], [7.0, 9.0, 12.0, 14.0], None),
            ("07315500", 25, 55, [5.55, 5.72, 6.24, 7.24, 9.62, 11.91, 13.7], [20.0, 22.0, 25.0, 28.0], None),
            ("07315650", 28, 60, [11.26, 11.33, 11.62, 11.95, 12.68, 14.28, 15.74], None, None),
            ("07316000", 31, 65, None, [22.0, 25.0, 28.0, 34.0], [63.7, 93.96, 207.0, 360.0, 807.5, 2260.0, 5835.0]),
            ("07331600", 35, 72, None, None, [42.6, 46.25, 60.1, 861.0, 2960.0, 8675.0, 17000.0]),
            ("07335500", 39, 84, None, [25.0, 27.0, 30.0, 33.0], [364.5, 431.0, 823.0, 2250.0, 5190.0, 13100.0, 27375.0]),
            ("07336820", 43, 92, None, [23.5, 24.0, 27.0, 30.0], [716.0, 843.0, 1530.0, 3480.0, 9085.0, 24650.0, 39275.0]),
            ("07337000", 46, 99, None, [19.5, 25.0, 26.0, 28.0], [964.6, 1150.0, 1920.0, 4060.0, 9940.0, 23860.0, 39740.0]),
            ("07344370", 50, 107, [10.62, 11.22, 12.59, 16.29, 25.0, 30.73, 32.5], [33.0, 37.0, 39.0, 41.0], None),
            ("07344405", 53, 114, [10.47, 10.59, 11.09, 13.46, 19.34, 25.84, 28.31], None, None),
            ("07355500", 60, 130, [19.92, 19.97, 20.08, 20.26, 21.3, 23.8, 24.64], None, None),
            ("073556009", 65, 138, [4.88, 5.56, 7.85, 14.33, 25.52, 33.76, 35.84], [40.0, 43.0, 46.0, 49.0], None),
            ("07381500", 69, 146, [-0.36, -0.08, 0.78, 4.08, 10.61, 16.62, 17.81], None, None),
            ("073815450", 72, 153, [1.11, 1.47, 2.35, 4.51, 7.96, 10.01, 11.08], None, None),
        ],
    },
    {
        "key": "tennessee",
        "label": "Tennessee",
        "short": "Tenn.",
        "line1": (55, 21, "17775656554454344443424446432333232346344233323354544454545434554646660607566764766656665665444"),
        "states1": "vAAAAAAAAEAMAAAAAAAAgIAAAAAAAAGAgAAAAAAAAwCAAAAAAAAMAAB///gAADAAAEAAD///////wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPAAAAAAAAAHAAAAAAAAAB4AAAAAAAAAMAAAAAAAAABgAAAAAAAAAYAAAAAAAAAOAAAAAAAAADgAAAAAAAAAQAAAAAAAAADAAAAAAAAAAYAB8AAAAAABAB4P//8AAAEP4A/8D//////AAAQAABAAAMAABAAAEAABgAAEAAAIAAEAAAQAAAgAAMAABAAACAAAMAAIAAAIAAAYAAgAAAgAAAgA",
        "counties1": "",
        "line2": (110, 43, "0107706067566665657445654444546563252252443463525364422424424253525365633432322423253232224234336523634442233332323443232464454564444454554544545434344545645456644666056006607105765666676764566776565656666656665656544345"),
        "states2": "hggAAAAAAAAAAAAAAAAwAAGYAAAAAAAAAAAAAAAAIAAAcAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAABgAIAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAYAAAAAAAAAAAAAAAAAAAA8AAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAADAAAAAAOAAAAAAAAAAAAAPAAAAAAC////////8AAAAcAAAAAAAgAAAAAAAD/////////wAAIAAAAAAAAAAAAAAAAAD//+AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADwAAAAAAAAAAAAAAAAAAABnAAAAAAAAAAAAAAAAAAAZgAAAAAAAAAAAAAAAAAAAZwAAAAAAAAAAAAAAAAAAAMwAAAAAAAAAAAAAAAAAAAFAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAwAAAAAAAAAAAAAAAAAAAAwAAAAAAAAAAAAAAAAAAAAwAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAYAAAAAAAAAAAAAAAAAAAH4AAAAAAAAAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAPAAAAAAAAAAAAAAAAAAAACAAAAAP8AAAAAAAAAAAAAAgAAAAcAAAAAAAAAAAAAAAIAAAAcAAAAAAAAAAAAAAACAAAD4AD//////wAAAAAAAgB//gAA///AAP////////////AAAAAAQAAAAAACAAAAAAAQAAAAACAAAAAAAgAAAAAAIAAAAAAgAAAAAAEAAAAAAEAAAAAAIAAAAAABAAAAAACAAAAAACAAAAAAAQAAAAABgAAAAAAgAAAAAAEAAAAAAQAAAAAAQAAAAAABAAAAAAGAAAAAAEAAAAAAAQAAAAAAYAAAAABAAAAAAACAAAAAABAAAAAAQAAAAAAAgAAAAAAIAAAAAEAAAAAAAIAAAAAABwAAAABAAAAAAACAAAAAAACAAAAAQAAAAAAAgAAAAAAAgAAAAEAAAAAAAIAAAAAAAEAAAABAAAAAAABAAAAAAABAAA",
        "counties2": "mxnIZ4MJwvNg2AMEGEg+CAjZiFzDmDoRgTACBhBoIg0IfwTAf5AGEIMQAgcQKCMOBDOFwEhwBBDCCAIV2D9BsJ/xB2DIGAgIRjcP+HjZjMD0ELggiAgOCHxgsqAfgJngBBDgIIgMNgmGwOIgLg+PwwQQwCCIH+MfB4BEEMgI8Ib8EGBAiBCBYYRBxAmIEEBMBB/gQQgQgIDIQwYHDDGAeAQQeEEIIICAiEICBgfDAGQEECf/////+P+mAwgeAgAsxBAwIBAECP/p/////////zQQMCAQCBAQDH4BCAIHCAD//+AgEAgQHn7GBwwCCAgBBCAgMBAYHhNBgwQEAzAThzwgEBBsMBHwwQEGDwdgPL0gIDhww9BxMIEDBg39gOjyICAv38FX+jCBB4YY8OMIISAgKAgzD5wwwIzEGEPWCEBgIC/QIgwEH7CIZ/iCGAhw8CBEMBYEAhcOkD0OliAIURA/xBAWBgIQA/gYF6/wD70O4IgQPAID+AeMCBBgaAxnA4CIGD3Hgw3kBgQgYEwc4gEAkB8ufMEDPAIM4DDEfXsBAZgZ5Bg/AgQD88Aogs4bAQGMYCAIDIQCAYMAx4HDBYEBjEAgDAyGAgIHGYGBAYXhf+3AeAwIfnwEDeeAQwHHP8CewE8YCEP82gjAgF4HTCCAkMBBmAiDB/MQgMDzeGiggJCAwH4YgwgnsMBAwYAwwICQ2YBJd4MYRP9AQaGAIIDBkG8AyJDBMMVhwEYwwCCAoRhhgJAQwfGNMDH4ECATgLEIwECQED+hijAWAGAgf4MdH+f5EBAhs74QD4GwWfD8Bzgc/wgQIN7cEBjxGGcwCHz4GCEPfiDOTAgQIQRQPASEEBAhjpvhjDgIMG+CkCIFBBgQYPEQx4g2cHB5gQhBBgQIEGDgoHR4I///wMMIQAQECBBAgKA4MGEGDMBCBP8EBAgQQIBgICBBAgPgRA8QBAQIEECAYCAwQgIHMDYcEAQECBBAgCAgMGICBBAt/BAEBf///IAgIGAmAggIfwYQ///AACf///////////oCEEQEYAAgQDACFEyAhzATAhBEBDgAIEBAASTEgENgYQEQRgQkPCBAQAEniPxBcMGBGMIEIufgQEADIwjCYdiAhwyD/CGC8EBABUMIgiMtgRkGggRgBDhAQAXDmIFOYwGxC4MEQAQMQEAIwLCB8kGAwYn/BkAMG0B8EID/gIJCQYGIAgZ/+Bn8RGD/gf+CIjEAkAPiQAgYBmbAgYCGw+YaAFAHP8AIEAeDgYOAg3Z/7wAgBCDACBAEBgPHB8EYMgmAcMQgwAgQBAQC3fz/CCIQgbB8IIAIEAQEBHBAgfxDEMJoBCD/////BBhgQIEEIxBEJA",
        "gauges": [
            ("03439000", 1, 3, [1.9, 1.94, 2.11, 2.38, 2.85, 3.39, 3.85], [7.0, 9.0, 13.0, 14.0], None),
            ("03447687", 4, 11, [3.41, 3.68, 4.22, 5.1, 6.44, 8.32, 9.48], [10.0, 13.0, 17.0, 20.0], None),
            ("03453500", 8, 19, [0.83, 0.97, 1.37, 2.0, 3.06, 4.23, 4.86], [7.5, 8.0, 10.0, 13.0], None),
            ("03455000", 13, 30, None, [8.0, 10.0, 16.0, 20.0], [818.0, 995.7, 1402.5, 2035.0, 3060.0, 4500.0, 6304.5]),
        ],
    },
    {
        "key": "cumberland",
        "label": "Cumberland",
        "short": "Cumb.",
        "line1": (59, 15, "00066444325544242525446764446434425336425242424132414252414252525644363533425354546564632435546566656642566442"),
        "states1": "DAAAAAAAAAAIAAAAAAAAAAwAAAAAAAAADAAAAAAAAAAwAAAAAAAAAMAAAAAAAAAAgAAAAAAAAADAAAAAAAAAAEAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBgAAAAAAAAYH/////4AAOAQAAAAA/////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAYAAAAAAAAADA",
        "counties1": "TEYeEGx/iM9If7+wv8aIuf2E4/kweV+wTxyCDTxw8+D/YoIH/9jRs/HDx4xwjQn+o4at+GmHjbzWxhBES0T3HtxmE8fseCIT0nuyPHDwYRHywd4MWZBjkfHhRhhNnP7/nyFDHHtj7DicIkX88cNEUPxCRMczRGKZj0JIQhpkIQ6F//////8yGIQggxCCe////DCCGP/cYgyEEMQ/mYRDjYf7fP6IhmJ7hheT6IiaREMHkKII/pF+RPlxoQ2B8bfd8RFhh9mYzGMSGfPmbwjIYh8fTj4jB/ByG2ECC2MGdt7/wcIZ/xhdggpBchIj/NjDHE8PejYv6EMcfh/2FE94TQ",
        "line2": (119, 31, "000700666454344242435456534642422523642536634546050666444636363663524344425435233544252253320542254135210232324134252244144225631452545225764452256334635335325631225234563522466445545456566466333433555534656665656666565653255676454423"),
        "states2": "AGAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAADgAAAAAAAAAAAAAAAAAAAHAAAAAAAAAAAAAAAAAAAAKAAAAAAAAAAAAAAAAAAAAFAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAADAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAYAAAAAAAAAAAAAAAAAAAAMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAABgA4AAAAAAAAAAAAAAAAABgAJwAB/////4AAAAAAAAPgADH//gADAAD/////4AAOAAAQAAAAAAAAAAAAA/////8AEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAP/wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAADAAAAAAAAAAAAAAAAAAAABgAAAAAAAAAAAAAAAAAAABwAAAAAAAAAAAAAAAAAAABoAAAAAAAAAAAAAAAAAAAAwA",
        "counties2": "ECAgEADIAQAYIBP3gEBgDBBAIDABPAMALHAeEIBA2HwQgCP4AYwCAETfEDjAQI/OEMA8hgYJBgBGj/AYQIGBgf/AQOOIB94AhYAwaCD5AwAgWYAw8A4xwQUAP4Yh5gIAIDsAcCAMAGEHAD8DvwI+ACAuAZCgCAAjAeAhAOMD5AAn7gYYwAQAPw/7oQBhAwICfAOcGMAEAB/8DmEAgQECB1gB8A9ABgAwCwDAwIEBgomEAcAM8BmA4AiAgCMAgctQhANAGMiw/8AQQYAlAYG3YIIEwBAIwMBAEEHAKINCB9DDGEAwDQBAYBAvIDBCPgOQQSAgGAYAQCAQOCAgJgQBGGFwMAgCB6AgcDAgwBQIAQahyBgYBgTgP/jgcYAICAICw4ge/AcEGCBPgE4ADAYCAsIEG4YODAcgQQDGAAwDAgG+BDAD84gA4EGAggAIAwMBxQIwAiBoAMBBgYMACATDAYMC8AIgGADAYMEBsAw4MQaDA5gEIAgBgCBzBmh74A8ZgR4IBCAEAYAgjggMyEAHYIHwCAQgDAbgJIYQB4ggCcCAwAgEIBYMYHMDoAYYIBGAgIAIBCAT8CD8AmAEGBAhAIBAEAQgICAzBgQQCBAIwQD/wBAIICAgHgMEEBAYCQEDgGAQCCAgIAgBhBAwCA0AnoA4EAggQCAEAIQQIAgGAPiAJz///////ADIGGAEDAPggBHIAEACAf//////BAwOAIAQDACABAEAQAQfR/////+AEAQAwAQCAIAEOeAECABg/BAEAEAIAgDwHiBgHAwAIIPwBABACAMAvmNgIBAEACGAIAYAQBAG8IHAwBAQB4BigBACAaAwBB+AgMAQGA9A84AQHgIXYAQxgIDAOBgMQ5yAPGPGD9BeYYCAwFgQCD4JgCuBP4QTvcEAgMBIEDgQBwAkAQGEDQDBgcBDhhA4EB4AJ/IBDA4AgOFgQgIj6CAoAEQeAYwEAED+OEYDvuggwADCBgCIAgBAwA5+AMYH4sH/ggIAiAMAQIAD7gBAG6/7AQICAZgBAG+AA4MAIDAcDwEEAwGQAYAxccIBgCBAMAYBDAEB98NgIB4+AEAQIBAGAQgBATn2EDAIDABAeMAYBAEYAfEQPA7wCAwAIcmADgQBDgYPAAQH+BgGACcOADN4AQIYAQAEAIgQAgAYBgBhmAEGEAEABACEGAIAMB4cgAgB9vABgAQAg/gGAMAT88AE/52wA2AEAYYf/gPAIeBADACIMAIeDAEEBwfvYCGAQAgAmCACB5ABCAQHHGBBgCAPAZAwBgH8AwgEBAh9gQAgBgEQIAwAj5uIBAgQZ9iAEB8BEBc4AIj2eAQQME+8gBA6ARAc+AEIIgwEICDbBwAQwg",
        "gauges": [
            ("03400785", 3, 5, None, None, [2.15, 2.96, 5.62, 18.4, 40.5, 83.08, 127.0]),
            ("03400986", 6, 11, None, None, [20.0, 24.13, 39.6, 78.25, 222.75, 429.7, 583.35]),
            ("03403500", 13, 28, None, [21.5, 27.0, 33.0, 38.0], None),
            ("03404000", 19, 41, None, [17.0, 21.0, 27.5, 32.0], [202.0, 246.2, 458.5, 1170.0, 2620.0, 4926.0, 8003.0]),
            ("03404500", 23, 50, None, None, [205.0, 257.3, 513.0, 1330.0, 3160.0, 6175.0, 9491.5]),
            ("03414002", 38, 82, None, None, None),
            ("03414100", 44, 91, None, [43.0, 46.0, 55.0, 64.0], [2731.5, 3250.0, 4190.0, 6155.0, 9232.5, 19500.0, 24040.0]),
            ("03417500", 49, 108, None, [30.0, 40.0, 45.0, 50.0], None),
            ("03418420", 63, 132, None, None, None),
            ("03426490", 74, 161, [16.59, 16.95, 17.85, 19.71, 24.09, 30.74, 33.58], [42.0, 49.0, 55.0, 60.0], None),
            ("03431514", 78, 171, [15.4, 15.58, 15.93, 16.38, 17.47, 20.39, 22.6], [30.0, 34.0, 40.0, 44.0], None),
        ],
    },
    {
        "key": "wabash",
        "label": "Wabash",
        "short": "Wabash",
        "line1": (43, 6, "00547445654444344444333434322122232321231323234132241"),
        "states1": "AAABAAAQAAAAAAEAABAAAAAAAQAAEAAAAAABAAAQAAAAAAEAABAAAAAAAQAAEAAAAAABAAAQAAAAAAEAABAAAAAAAQAAEAAAAAABAAAQAAAAAAEAABAAAAAAAQAAEAAAAAABAAAQAAAAAAEAABAAAAAAAQAAEAAAAAABAAAQAAAAAAMAABAAAAAAAgAAGAAAAAADAAA+AADgAAEAACEAALAAAQAAEQABEAABAAMw8CEgAAIAA8Ae4SAAAgABAAOzIAAEAAIAAB5AAAQAAgAACEAAGAAcAAAQMAAIAZAAABAYABAD4AAAGAQAH4pgAAAICgA/1AAAAAQBABBgAAAABA",
        "counties1": "",
        "line2": (87, 12, "107544766444654565445444443434444444443332343244334343222212222222322332231221321223413244123424312330322241"),
        "states2": "AAAAAAACAAAAAAEAAAAAAAAAAAAAAgAAAAABAAAAAAAAAAAAAAIAAAAAAQAAAAAAAAAAAAACAAAAAAEAAAAAAAAAAAAAAgAAAAABAAAAAAAAAAAAAAIAAAAAAQAAAAAAAAAAAAACAAAAAAEAAAAAAAAAAAAAAgAAAAABAAAAAAAAAAAAAAIAAAAAAQAAAAAAAAAAAAACAAAAAAEAAAAAAAAAAAAAAgAAAAABAAAAAAAAAAAAAAIAAAAAAQAAAAAAAAAAAAACAAAAAAEAAAAAAAAAAAAAAgAAAAABAAAAAAAAAAAAAAIAAAAAAQAAAAAAAAAAAAACAAAAAAEAAAAAAAAAAAAAAgAAAAABAAAAAAAAAAAAAAIAAAAAAQAAAAAAAAAAAAACAAAAAAEAAAAAAAAAAAAAAgAAAAABAAAAAAAAAAAAAAIAAAAAAQAAAAAAAAAAAAACAAAAAAEAAAAAAAAAAAAAAgAAAAABAAAAAAAAAAAAAAIAAAAAAQAAAAAAAAAAAAACAAAAAAEAAAAAAAAAAAAAAgAAAAABAAAAAAAAAAAAAAIAAAAAAQAAAAAAAAAAAAACAAAAAAEAAAAAAAAAAAAAAgAAAAABAAAAAAAAAAAAAAIAAAAAAQAAAAAAAAAAAAACAAAAAAEAAAAAAAAAAAAABgAAAAABAAAAAAAAAAAAAAwAAAAAAQAAAAAAAAAAAAAMAAAAAAEAAAAAAAAAAAAABAAAAAABAAAAAAAAAAAAAAgAAAAAAYAAAAAAAAAAAAAMAAAAAANYAAAAAAAAAAAABAAAAAAENAAAAAAAAAAAAAYAAAAABgIAAAAAMAAAAAACAAAAAAIDAAAAAUwAAAAABgAAAAADAQAAAAGDAAAAAAQAAAAAAQGAAAADAgAAAAAGAAAAAA8A4AAAAgIAAAAAAgAAAAewABwAOAIEAAAAAAQAAAAEQAAGcEgCBgAAAAAIAAAABgAAA9xIAgIAAAAACAAAAAIAAAAHjAYEAAAAAAgAAAACAAAAAAMEBAAAAAA4AAAADAAAAAABCAgAAAAAIAAAABAAAAAAAPgIAAAAAGAAAAAQAAAAAADAEAAAAABAAAAAIAAAAAAAgBAAAAAAwAAAAeAAAAAAAIAQAAAAAYAAAAMAAAAAAAGACAAAAACAAAGCAAAAAAABAAQAAAABAAADwgAAAAAAAIACAAAAAwAAAkIAAAAAAADAAYAAAAIAAAQ2AAAAAAAAQABgAAACBAGEDAAAAAAAACAAcAAAAo+GXAAAAAAAAABAAGwAAAb8ZDgAAAAAAAAAMAACAAAHiDgQAAAAAAAAABAAAgAAAwAIAAAAAAAAAAAIAAEAAAQAAAAAAAAAAAAACA",
        "counties2": "IH/BQBQCIQIiIQEEBBCCMSBA/8AUAiP/4iH/BnwwghEgQIBAFAIuCCIhEQPEIIIRIEEAQBQCKAgiIREGB/CCESBB8P4UA/h8IiER/AQQghk/wRCCFAIITyIhEQ+EH/+Z4GITghQCCEEj/xEIfAgYiyAiHgP0AghBIQQRCAQIEJ4gPggAhAIP4f8H/wgfiBH+IDAIAIf/+CEBBEEL8f4xAiB8CACAggg/gQRBChAj4QMgxAgA/4IIIP//wQ4QIhECIYf4AICCCCBBEEH4ECIfAuEBD/+AgjggQRB/CB4iA8IjAQQGgILP4H8QQQgR8wJ+PgEEBICDCD/BEEEP8DECAxz/BAyAg4ggQRBBCDA5/gI7wQQYgIKIIEEfwQgwJwYCbkEH8ICDCCBBEEEMP+MGAsBHhBCAg4ggQRB/DCAiBgLATPwQgIP4P//wQf/gYgf///gIEP/+j+CCEEEIYGIEI4BACBCAgoIgghBBCDxDxDPwQHQfgIKCIII/wQgjwjwQEEBmMIGCgiCCIX8IYPIMEBAgQ+D/AoIgg+ERCECeDDCIIIEggQP+P/4hEQhAggj8iCCBOIECEhBCIRH//8IPg///gQyBAhIgQiH/BBBD4gGCBIEDg/4T8EI/AQQQRD4HggSBAIICMRBCIQECEEQCBIIE/wD+Bicf/+EBAhB4A/wCBAIAgwwkM4ghf/4QiAIEBgQCAIMP5DEIIZED/QwGBA4ED/+BBCQxCCYRAxYHh8/6BAgQ//g/8QgsEYEUBPx8ggQIEEEMIBEI9CPbFAgEOIIECBBBBCAR/4QmdhT8BDyP//gQQQYgH8CELmoXwgQ/eAIIEEECIBDAhPorIIP+IFwCCB/BA//wQI//KSCCAiGXAwgIf/4ZEECYQ6ugggPhMwML+BCCMRB48E/94QIBwkYB/ggwgiEQxyf90X0COmKGAQIIIIYhH4IU7xGPcmo6B/8GCCCMIRyDFI0Ym97OCg4EBA//zCEQgfxxCbDHzg4EBHQIDTn58IEGyM7YgYcH7gf/+Ak/B5CHDZh4y0HDiDoEBAgJHIQR/hEEcHxjxrgZBAQICTDEH8+xhtjIOzzhEQQECAkgRBDI/f+JhB8MtxDkBAgJwEQYzecMj08thY4Q//wP/8B8eIUCCIxpx4+EGIEECED/z8+HBBjeOcd5BA2BB/hBEQRDwg4fdnxmCQQ/AQIIQxEcQ8J9nmfifhCG8YEGCEIRGER3iGNDMvnwQhhh/AhCHTDGDg7DchMQ8OcwchwP/t+nfYcTb9sfEB7vIG4H+E78ZzjEsPnP8TDxuRDGBAhHyHmQLOFR+Hj5IREIggQIQ2AokBhhENAujhcJB4EECEQgwNAwIhf4QQsfmA",
        "gauges": [
            ("03322900", 8, 15, None, [9.0, 11.0, 14.0, 17.0], [6.4, 9.87, 16.7, 66.9, 305.0, 1006.0, 1706.0]),
            ("03323500", 12, 22, None, [18.0, 20.0, 21.0, 23.0], None),
            ("03325000", 15, 28, None, [10.0, 14.0, 19.0, 23.0], [94.2, 126.0, 203.0, 509.0, 1375.0, 4110.0, 5777.0]),
            ("03329000", 19, 36, None, [12.0, 15.0, 19.0, 21.0], [330.0, 396.8, 761.0, 1510.0, 3370.0, 8392.0, 12480.0]),
            ("03335500", 23, 46, None, [7.0, 11.0, 18.0, 26.0], [965.2, 1144.0, 1760.0, 3100.0, 6610.0, 13860.0, 20000.0]),
            ("03336000", 28, 55, None, [11.0, 16.0, 24.0, 29.0], [1170.0, 1464.0, 2120.0, 3700.0, 7470.0, 15760.0, 23360.0]),
            ("03340500", 31, 62, None, [10.0, 14.0, 24.0, 31.0], [1362.0, 1700.0, 2490.0, 4760.0, 10300.0, 21300.0, 29700.0]),
            ("03341500", 34, 68, None, [11.5, 16.5, 24.5, 30.0], [1650.0, 1950.0, 2950.0, 5260.0, 11150.0, 21780.0, 31600.0]),
            ("03342000", 38, 76, None, [10.0, 15.0, 22.0, 26.0], [1850.0, 2160.0, 3180.0, 6080.0, 12800.0, 25200.0, 35500.0]),
            ("03343010", 42, 83, None, [10.0, 16.0, 22.0, 28.0], [2210.0, 2470.0, 3440.0, 6570.0, 14200.0, 28360.0, 35780.0]),
            ("03377500", 45, 92, [2.52, 2.7, 4.09, 7.5, 12.24, 16.52, 20.36], [11.0, 19.0, 25.0, 32.0], None),
            ("03378500", 48, 99, None, [10.0, 15.0, 20.0, 23.0], [4427.5, 5035.0, 7860.0, 17800.0, 38100.0, 65400.0, 80800.0]),
        ],
    },
    {
        "key": "illinois",
        "label": "Illinois",
        "short": "Ill.",
        "line1": (48, 1, "0233334533444454564344444442232323234323343232122322120"),
        "states1": "AABAAAD///4AAMAAAIAAAwABgAAAgAACAAcAAACAAAIAGAAAAIAAAgAwAAAAgAACACAAAACAAAIAEAAAAIAAAgAQAAAAgAACABAAAACAAAIAEAAAAIAAAgAgAAAAgAAC/GAAAACAAAICwAAAAIAAAgOAAAAAgAACAYAAAACAAAIBgAAAAIAAAgEAAAAAgAACAQAAAACAAAIBAAAAAIAAAgGAAAAAgAACAIAAAACAAAIAgAAAAIAAAgBAAAAAgAACACAAAACAAAIAEAAAAIAAAgAIAAAAgAACAAQAAACAAAIABAAAAQAAAwAGAAABAAADAAOAAAGAAAIAA0AAAIAAAg",
        "counties1": "iI/iC/z///6IiGJ/LKSJE4j8/+EmpIkS/4/IIeOk+f4RnIghIKXPExH/iGEvvkn+ESCOoXjv+SP/8Pv/4ORJIkSfkhg/pF/j/LSf+DCv9T5HpJGIMLiVKkRk8c8w85crRH+bcfCTV+r+6I5gkJ9+fpOIjkCf8eJSkYiSQPiRP/P/D5P/iPEinp344yKI3/6SkQ7fIojRIvKRC/e+iNEinv+LnuL/8f+TiY9wY4jfJfKI+5jmiMknPv/Cybz4+f0qhGP/F4ipJT+FmiMRj68l4v0eI/D5rf8i744iIInpyT8j/+J//z9J6z5DIkRJIX9LIkP/5Emh7k4if8NnyP8i/g",
        "line2": (97, 2, "02233333234345434343444443455454665534343445444444444322223232322224422343423432323434323323133121232222222212200"),
        "states2": "AAAAABgAAAAAAAQAAAAAAAAAAAAwAAAAAAD///////wAAAAAIAAAAAAAgAAAAAAHAAAAAEAAAAAAAIAAAAAABAAAAABAAAAAAACAAAAAAAQAAAABgAAAAAAAgAAAAAAEAAAABwAAAAAAAIAAAAAABAAAAHgAAAAAAACAAAAAAAQAAAPAAAAAAAAAgAAAAAAEAAACAAAAAAAAAIAAAAAABAAABgAAAAAAAACAAAAAAAQAAAQAAAAAAAAAgAAAAAAEAAAEAAAAAAAAAIAAAAAABAAAAgAAAAAAAACAAAAAAAQAAAIAAAAAAAAAgAAAAAAEAAABAAAAAAAAAIAAAAAABAAAAQAAAAAAAACAAAAAAAQAAAEAAAAAAAAAgAAAAAAEAAABAAAAAAAAAIAAAAAABAAAAwAAAAAAAACAAAAAAAQAAAIAAAAAAAAAgAAAAAAEAAAEAAAAAAAAAIAAAAAABAAABAAAAAAAAACAAAAAAAQAAAgAAAAAAAAAgAAAAAAEAAAYAAAAAAAAAIAAAAAABP/gYAAAAAAAAACAAAAAAAQAEMAAAAAAAAAAgAAAAAAEAAiAAAAAAAAAAIAAAAAABAAEgAAAAAAAAACAAAAAAAQAAoAAAAAAAAAAgAAAAAAEAAOAAAAAAAAAAIAAAAAABAABgAAAAAAAAACAAAAAAAQAAQAAAAAAAAAAgAAAAAAEAAIAAAAAAAAAAIAAAAAABAACAAAAAAAAAACAAAAAAAQAAgAAAAAAAAAAgAAAAAAEAAIAAAAAAAAAAIAAAAAABAACAAAAAAAAAACAAAAAAAQAAgAAAAAAAAAAgAAAAAAEAAMAAAAAAAAAAIAAAAAABAABAAAAAAAAAACAAAAAAAQAAQAAAAAAAAAAgAAAAAAEAAEAAAAAAAAAAIAAAAAABAABgAAAAAAAAACAAAAAAAQAAIAAAAAAAAAAgAAAAAAEAACAAAAAAAAAAIAAAAAABAAAQAAAAAAAAACAAAAAAAQAADAAAAAAAAAAgAAAAAAEAAAIAAAAAAAAAIAAAAAABAAABAAAAAAAAACAAAAAAAQAAAYAAAAAAAAAgAAAAAAEAAACAAAAAAAAAIAAAAAABAAAAQAAAAAAAACAAAAAAAQAAADAAAAAAAABgAAAAAAEAAAAIAAAAAAAAwAAAAAABAAAABAAAAAAAAMAAAAAAAQAAAAQAAAAAAABAAAAAAAEAAAAGAAAAAAAAwAAAAAABgAAABgAAAAAAAIAAAAAAAUAAAAYAAAAAAABAAAAAAAIAAAACAAAAAAAAQAAAAAADAAAAAiAAAAAAAEAAAAAAAQAAAANYAAAAAAAgAAAAAAIAAAABhgAAAAAAIAAAAAABA",
        "counties2": "QECAxxgEAEIIIAQAAgQEBEBAgLzwBABD/+D///////xAQICAMAQAQgjAhCBAgQEHQECAgEgEB/4I4IQgQIEBBEBA/+BP//wCCCCEIECBAQRAQIAhmEAEAgg4hCBAgQEE//6AJ2BABAIICIQgQIH//AEDgPyAQAQD+A+EIH+BAQQBA4PAgEAEAggAhCHg/wEHAQOGAIBABAIIAIQiIIEBBAED//+AQBwCCACEJCCBAQQBAgQAgEA0Agj/h7gggf/8AQIEAIB85AIIgIxwIIEEBwOCAgCARIQCD4D4P/+BBAT//4EA/8fkAggAyCAggQQEEBD/AIEEP3/4AIggIMEIBBAQgf+BBAFACACIICB/CAQQEIEggQQBQA//iCAh4fgHEBCBIIH/gUAKAIggISEIBP/wgSCBAf/ACgCIf/8hD/wQEIIggQEAQAoAiECBIQhEEB+EIIEDAEAKAInAgSEIRBAQZCCBAgD/CgCJAIEhCEQQEDwg/wPggQoA/wfBIQhHEBAMIIECIYEKAIEEcSEIRBBwP/+BxjMB+gCBBBE/+ET/8HiAgEQcAEIAgQQR+D/8gQiAgIB8EABCAIH+H+ghBIEEgICA4BAAQ///AhAIIQSBAoCAgPgQAEBAgQP4CBIEgQOAgIGIEAB/wIECD/gSBIEBgICDCBAAQECDAgQP/gf/AQCAhg/wAEBAhwIECIP8gf4A/4QCH//AQIkCBAiCBIED4ICMAgQDQECx/gf4ggSBAh+A+A4EAkBA4QP8CIIEgQIAgGH2BAZAQOECBAiCBIECAPjnggQMQEChAgQI/gSBAgCNuYIH+EBA4QIECIIEgQMAh4EPhAhAQMECBAiD/P//gIIBCOQIQED/A///gwRAQQCH4fh8CH//sQIIIIIHQEEA/j8ACAhAQJH+CCCCBEBBgIcBABwPwECQQggh/wRAQP+NwQBkGIBAkEIIIQUEQECACEGARBCAQKBCCD8F/F//wAhAgMfw/8CgQgghBETwEDAEIIGBEIBA/8P/4QREQBAYBCCBARiAQIRDBCEER0AQNAf//wEOgECEQgQhB/xAEMYGBAkBA4D/hH8EIQQEQBEDxAQJAQGAgIQhBCH8BEARAfwECQEA/4CEIQQhBAR/+QDEBAn/AICBhOP//wQEQH+AZAQIBACAgwSCEIEH//gBgDQMCAQAgIP8ghCBDEQIAJ/3PAgf/4CBBIIQghBECA/wHuQIEBD//gf+EIIwRggIIA4ECBAQIEIEAhCH0IUP+CAWBAgYECBDBAIfhBCICAggEgQL+BAgQQQCCPwQnBgIMAuf/hgQIEEEA/wEEPQQCDw/cAQYH+BAhgIMBH/sEAgn9jgGGAQgQP/+BATB/A",
        "gauges": [
            ("05515500", 4, 7, None, [9.0, 10.0, 12.0, 13.0], [256.0, 292.2, 370.0, 463.0, 629.0, 824.6, 964.0]),
            ("05517500", 7, 13, None, [9.5, 10.0, 12.0, 13.0], [482.0, 563.0, 747.0, 1030.0, 1530.0, 2310.0, 2898.5]),
            ("05518000", 10, 19, None, [9.5, 10.5, 11.5, 12.5], [609.0, 719.9, 985.0, 1420.0, 2187.5, 3171.0, 3735.5]),
            ("05520500", 13, 25, [1.24, 1.37, 1.66, 2.12, 2.85, 3.51, 3.85], [4.5, 5.0, 6.5, 9.0], None),
            ("05527500", 17, 35, [0.99, 1.07, 1.34, 1.8, 2.49, 3.44, 4.14], [5.0, 6.5, 8.0, 10.0], None),
            ("05543010", 21, 42, [20.24, 20.33, 20.48, 20.63, 20.94, 21.74, 22.55], [26.0, None, None, None], None),
            ("05558300", 29, 58, [14.27, 14.36, 14.59, 15.04, 16.32, 20.22, 21.33], [22.0, 23.0, 24.0, 31.0], None),
            ("05568500", 36, 73, [2.24, 2.68, 3.42, 5.63, 10.45, 14.9, 15.95], None, None),
            ("05585500", 45, 93, [2.04, 2.41, 3.16, 5.4, 9.89, 14.21, 15.59], [14.0, 17.0, 22.0, 24.0], None),
        ],
    },
    {
        "key": "wisconsin",
        "label": "Wisconsin",
        "short": "Wis.",
        "line1": (39, 1, "442234123432112322124423221212002333445443343"),
        "states1": "AABAAHgAAAAAAEAAB4AAAAABgAAA8AAAAAIAAAAMAAAABgAAAAYAAAAEAAAAAwAAAAQAAAABAAAAAgAAAAIPAAAGAAAAA5HAAAQAAAABsGAABAAAAAGgQAAEAAAAAEDAAAQAAAAAAIAABAAAAAABAAAEAAAAAAEAAAIAAAAAAgAAAcAAAAACAAAAMAAAAAQAAAAQAAAABAAAABAAAAAIAAAADAAAAAgAAAAGAAAACAAAAAEAAAAIAAAAAIAAAAgAAAAAgAAAEAAAAACAAAAQAP///4AAABAAAAAAgAAAEAAAAABAAAAQAAAAAMAAABAAAAAAgAAAEAAAAACAAAAYAA",
        "counties1": "X/B/7nkHn49CUOIiR4SQiELRoj/BdPCIQ9IiCP9MoIn//CIIgWagjgmf//iBfaCID5YiCPkROPwE6iIIjxIPhs++Ij+J+5nC+c//4IhIkGGR/iQh/emgQZE8JD8HJkCB/5wkIgXjgIMk/+fiBHmBA32uPCP/7QP+cyc/4kR//ghD/eKyZEkH//6J5p4kSQQIPokWgiRL/Agf/76///4H//FKZvqQlAQSEUojIt+UCBL///8i0//4EhELia50hA//EQiJ+//0CBIRCIiPER/4Ev////kRFB/zJIkkyTEUGBLn/+RJ/xQIHySLpF/B///8JIk/9EEkCAT//+TEQSQIBA",
        "line2": (78, 2, "44432032343211324344132321012302232311321144432422232222211212030000232342334435454444342343434"),
        "states2": "AAAAACAAAAAHgAAAAAAAAAAAAAAgAAAAAPAAAAAAAAAAAAAAIAAAAAAOAAAAAAAAAAAAACAAAAAAA4AAAAAAAAAAAAHAAAAAAADuAAAAAAAAAAAHAAAAAAAAOYAAAAAAAAAADAAAAAAAAABgAAAAAAAAABgAAAAAAAAAEAAAAAAAAAAQAAAAAAAAADgAAAAAAAAAMAAAAAAAAAAOAAAAAAAAACAAAAAAAAAAAQAAAAAAAAAgAAAAAAAAAAIAAAAAAAAAMAAAAAAAAAABAAAAAAAAABgAAAAAAAAAAgAAAAAAAAAMAAAAAAAAAAEAAAAAAAAABAAAAAAAAAACAPwAAAAAAAgAAAAAAAAAA4EDAAAAAAAIAAAAAAAAAAaCAMAAAAAAEAAAAAAAAAABggAwAAAAABAAAAAAAAAAAQQACAAAAAAIAAAAAAAAAAEIADAAAAAACAAAAAAAAAAA2ABgAAAAABAAAAAAAAAAADAAgAAAAAAQAAAAAAAAAAAAAYAAAAAACAAAAAAAAAAAAAEAAAAAAAgAAAAAAAAAAAADAAAAAAAIAAAAAAAAAAAAAgAAAAAAEAAAAAAAAAAAAAIAAAAAABAAAAAAAAAAAAAEAAAAAAAIAAAAAAAAAAAABAAAAAAADAAAAAAAAAAAAAQAAAAAAAQAAAAAAAAAAAAIAAAAAAADwAAAAAAAAAAACAAAAAAAACAAAAAAAAAAABgAAAAAAAAYAAAAAAAAAAAQAAAAAAAABgAAAAAAAAAAEAAAAAAAAAIAAAAAAAAAACAAAAAAAAADAAAAAAAAAAAgAAAAAAAAAQAAAAAAAAAAIAAAAAAAAAEAAAAAAAAAAEAAAAAAAAAAwAAAAAAAAABAAAAAAAAAACAAAAAAAAAAQAAAAAAAAAAcAAAAAAAAAEAAAAAAAAAADgAAAAAAAABAAAAAAAAAAAIAAAAAAAAAgAAAAAAAAAABAAAAAAAAAIAAAAAAAAAAAQAAAAAAAACAAAAAAAAAAACAAAAAAAAAgAAAAAAAAAAAgAAAAAAAAIAAAAAAAAAAAIAAAAAAAACAAAAAAAAAAACAAAAAAAAAgAAAAAAAAAAAgAAAAAAAAQAAAP///////4AAAAAAAAEAAAAAAAAAAACAAAAAAAABAAAAAAAAAAAAgAAAAAAAAQAAAAAAAAAAAMAAAAAAAAEAAAAAAAAAAABAAAAAAAABAAAAAAAAAAAAIAAAAAAAAQAAAAAAAAAAAGAAAAAAAAEAAAAAAAAAAABAAAAAAAAAgAAAAAAAAAAAQAAAAAAAAIAAAAAAAAAAAEAAAAAAAACAAAAAAAAAAABAAAAAAAAAgAAAAAAAAAAAQAAAAAAAAIAAAA",
        "counties2": "JgfhACAICHAvggA/wIEAfyP8PwA///gcIfIAIEP/gEAgBCEAJAgIBCA+ACBCAIBAIAQhAGQICAQgB8AgQgCAQCAEIQDECAgEIAH+IEIAgEAgBmMDBAgP/+ADOaB+AIBAIAZCDAQIAID/7hBgzACAQCACQggECACAgDoQEIwAwF8j/kIQBAgAgIACECCMAMBw/wJ/kAQIAICAAhAehADAQACCQuH8CACAgAIf94QAQEAAgkI/D///gIACAgIEAEBAAIJCMAgIAICAAgIBBAB/wAD/w5gICACA/8ICAgeAQCAAQECICAgAgIBCAgEAgEAQACB4hAgIAICAfwICAPxACIBYR4wICA//gEH/g4GDQAj8TECMCAgIAIBAEIZDAMAEh4PA+AgP+ACAQBCAggAwBIEAwJ//+AgAgEAQgIQACAOBAbCICCAIAIBAEMEIADACgQEPmAggCAP/8fxAyABgAoECDJAIIAgCABEEIDAAgAOBAg6QCCAP/gAfBDgwAYAFj/4GkAggCAQAEeQHUAEABfgjw5gIIAgEABAkAUADAAcIIEaf+D/4BAAQP4GAAgAHCBD4kAggCAQAEACBgAYACAgQiPAIIAgEABAAwQAH//g5+YgYD+AIB///+PEABABALw8IHAggCAQQEAh///gAQCAMCBQP//gEEBA/wQAIAEAgD/gz/AhIBBAQIEEAEABAIAhPwGQITgQYECBBAB/////4QID0CEP8CBAgQQAQAEBgGECDjAhADAgQIEEAMABAHBhAggMIQAgEECBH/+AAQAcQQIIBCEAIBBAgRAAgAEAD/kCCAQhAD/////wAIABAAvP//8eQR/wiAIIQAH////4CEIR82E+EQgCCEABgAgQCAhCEBDn4BIIAghAAQAIEAgIQhAQJCASCAIIQAEACBAICEIwEBwgEw/+CEADAAgQCAhCMBAMIBEII////wAIE/////f//CARCCIAgAIACBAEBAI+AQQgEIgiAIAD///8BAQCAgEGJ/DIYgCAAgAIEAQEAgIBB/+QSEIAgAIACBAEBAICAQIAH///+IAGAAgQBAQCAgECABAgCAiABgAIEAQEAgIBAgP4OAgP//4ACBP///////4CCAgICEAH+AgcEEECCBBD/ggICAhABgf4EBBBAggQQgIICAgIQAYACBAQQQIIEEMCCBAICEAGAAgQEEECCBBBAgg/+AhAAgAP//B////wQIL44AgIQAIAA4AQQQIIEEGH/cAP///+AAKAEEECCBBBDEZACBBAA//+gBBBAggf/zBAQAgQQAIAAIAQQQIIEEHAQEAIEEACAACAEEECCBBBAEBACBBAAgAAg//////wQQBAQAgQQAMAAIA",
        "gauges": [
            ("05390100", 1, 2, [79.59, 79.66, 79.91, 80.33, 80.59, 80.73, 80.77], None, None),
            ("05391000", 6, 11, None, [4.0, 6.0, 7.5, 9.0], [266.2, 305.4, 425.0, 571.0, 706.0, 812.6, 1090.0]),
            ("05395000", 13, 27, None, [10.0, 11.0, 13.5, 15.0], [1060.0, 1270.0, 1590.0, 1920.0, 2450.0, 4440.0, 6226.0]),
            ("05400760", 22, 46, None, None, [1840.0, 2070.0, 2530.0, 3230.0, 5490.0, 11300.0, 16125.0]),
            ("05404000", 30, 62, None, [13.0, 16.0, 17.6, 18.9], [2790.0, 3020.0, 3820.0, 5390.0, 8270.0, 15300.0, 21560.0]),
            ("05407000", 40, 84, None, [7.0, 9.0, 10.0, 11.0], [4132.0, 4614.0, 5730.0, 7830.0, 11000.0, 17860.0, 24700.0]),
        ],
    },
    {
        "key": "minnesota",
        "label": "Minnesota",
        "short": "Minn.",
        "line1": (6, 1, "0001311012120012100101121101111010101101011010067657667077600177"),
        "states1": "//8AAAAAAAEAAQAAAAAAAgABAAAAAAACAAIAAAAAAAQABAAAAAAABAAIAAAAAAAEAAwAAAAAAAYABAAAAAAAAwAGAAAAAAABAAOAAAAAAAEAAMAAAAAAAgAAQAAAAAACAABAAAAAAAIAAEAAAAAAAgAAQAAAAAACAABAAAAAAAIAAEAAAAAAAgAAQAAAAAACAABAAAAAAAIAAEAAAAAABAAAQAAAAAAEAABAAAAAAAMAAEAAAAAAAQAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAA",
        "counties1": "//8QQEEAZEEBARBAQQAkQwEBEEB//+RCAQIf/8AIJ/wBBBBAQAgkRAEPEEBADCRP/w/wQEAH/HYBBBBAQAQEEwEEEEBAAgQRAQMf//wDh/EBD8QBB+bEEwH4ZAEEfDweAQB8AYYIHhP/+E//hggzEggIQQCCCCHyCAhBgIIIINIID8DAgn/gUggYQGCCQSByCBhA9//BPPMP+H+MAEEPlggQQAQAQRseCBBAAgHP8QaIEH/zgXjgg4gQRBJhAICC///EHjEA/56AQEQQD/+E8IBARBALAIQQgMBEEAjAhBCAwEQQeGEEEICARBBAMeQQ/////8AtP/+CEEIEf+YiEQ",
        "line2": (12, 3, "70000002213121012722012121200010121201010101011121110101111202101020011101001011102001001211101720011766676756767650667007706667000010070767"),
        "states2": "/////wAAAAAAAAAAAAAAAQAAAAEAAAAAAAAAAAAAAAMAAAABAAAAAAAAAAAAAAACAAAAAQAAAAAAAAAAAAAABAAAAAEAAAAAAAAAAAAAAAQAAAACAAAAAAAAAAAAAAAIAAAAAgAAAAAAAAAAAAAAGAAAAAQAAAAAAAAAAAAAADAAAAAYAAAAAAAAAAAAAAAgAAAAMAAAAAAAAAAAAAAAIAAAAEAAAAAAAAAAAAAAACAAAACAAAAAAAAAAAAAAAAgAAAAQAAAAAAAAAAAAAAAMAAAAEAAAAAAAAAAAAAAAAwAAAAgAAAAAAAAAAAAAAAGAAAAIAAAAAAAAAAAAAAAAgAAABAAAAAAAAAAAAAAAAMAAAAQAAAAAAAAAAAAAAABAAAADgAAAAAAAAAAAAAAAQAAAAOAAAAAAAAAAAAAAAMAAAAAQAAAAAAAAAAAAAACAAAAAEAAAAAAAAAAAAAABgAAAAAgAAAAAAAAAAAAAAQAAAAAIAAAAAAAAAAAAAAEAAAAACAAAAAAAAAAAAAABAAAAAAgAAAAAAAAAAAAAAQAAAAAIAAAAAAAAAAAAAAEAAAAACAAAAAAAAAAAAAABAAAAAAgAAAAAAAAAAAAAAQAAAAAIAAAAAAAAAAAAAAMAAAAACAAAAAAAAAAAAAACAAAAAAgAAAAAAAAAAAAAAQAAAAAIAAAAAAAAAAAAAAEAAAAACAAAAAAAAAAAAAABAAAAAAgAAAAAAAAAAAAAAQAAAAAIAAAAAAAAAAAAAAEAAAAACAAAAAAAAAAAAAACAAAAAAgAAAAAAAAAAAAAAgAAAAAIAAAAAAAAAAAAAAIAAAAACAAAAAAAAAAAAAACAAAAAAgAAAAAAAAAAAAABAAAAAAIAAAAAAAAAAAAAAQAAAAACAAAAAAAAAAAAAADAAAAAAgAAAAAAAAAAAAAAMAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAA",
        "counties2": "/////wEAEAAgAgAACCAQAAABAAEBABAAIAIAAAggEAMAAQABAQAQACACAAAIIBACAAEAAQEAEAAgAgAACCAQBAABAAEBABAAIAID//ggEAwAAQACAQAQAD///4AIIBAIAAEAAgH////gAACACCAQCAABAAQBABAAIAAAQAg///AAAQAYAQAQACAAAGAIIBAgAAEAMAEAEAAgAAAgCCAQYAABAEABABAAIAAAYAggEH8AAQCAAQAQACAAAEAIIBAg//kAf/8AEAAgAAAgCCAQOAAPAGABABAAIAAAP//gHhwAAQAgAQAQACAAABAAIAIEAAEAMAEAEAAgAAAQACACAgABABABABAAIAAACAAgAgIAAQAYAQAQACAAAAQAIAIBAAEADgH/////8AAEAD/+AQABAAOAIAABABAAC4AgAgMAAQAAwCAAAQAQAAhgIAICAAEH/+AgAAEAH/xQMCACBgAB+AAgIAABABAHoA/gA/wAAQAAOBAAAYAQAIAAYAIEAAEAAC8QAAGAGACAAOACBAABAAAg0AABgBgAgAGYAg8AAQAAIDAAAYAYAIABBgIM////gCAP//+AGACAAgECDABAAIAgBAAAgBgAgAQB/wQAQACAIAIAAIAIAIAIAMEMAEAAgCABAACACACACADBCABAAIAgAIAAgAgAgAgA4QwAQACAIABAAIAIAIAIACEMAEAA/+AAYACACD//+AAhBABAAYAgADgAgAggAggAIQwAQAGAIAAcAIAIIAIIAD0MAEABgCAAfj///+ACD+AzDABAAYAgAEEgAAAgAgAgIg8AQAGAIABAoAAAIAIAIEIIAH//gD//wGAAACACAHnCGABAAYAgAABgAAAgAgGHA/gAQAEAIAAAMAAAIAIBAQA4AEABACAAABgAAeD/wYEADABAAQAgAAAGAAEggFsBAAcAQAEAIAAABYABIIBsAQAFgEABAD///wRAAT+AOAGADIBAAQAgEAEEIAEAAEAAgAiAQAEAIBABBBgBAABAAIAI/////+AQAfwHAQAA//+AeIAAIAAgEAEAAcEAAEAgg4CAACAAIBABAABhAADAIP4AgAAgACAQAQAAX///gCACAIAAIAAgEAEAAEwAAYAgAgCAACAAIBABAABHAAEAIAIAgABgACAQAQAAQOABgCACAIAAYAAgEAEAAEAQAIAgAgCAAGAAIBABAABAEAEAIAIAgABgACAQAQAfwAgBACACAIAAQAAgEAEAEAAGA4AgAgCAAEAAIBABABAABYP4IAIA///////////wAARiD////4AIAQAgCAAgEAAEOggEAgGACAEAIAgAIBAABAwIBAIBgAgBACAIACAf//wACAQCAQ",
        "gauges": [
            ("05290000", 8, 19, None, [16.0, 17.0, 22.0, 24.0], [2.64, 3.87, 9.16, 23.5, 82.5, 276.6, 465.0]),
            ("05292000", 15, 34, None, [9.0, 10.0, None, None], [17.46, 23.72, 54.5, 99.7, 226.0, 768.0, 1660.0]),
            ("05311000", 26, 53, None, [12.0, 14.0, 16.0, 17.5], [180.0, 259.3, 447.5, 978.5, 2550.0, 6196.0, 8497.0]),
            ("05316580", 34, 75, None, [18.0, 21.0, 23.0, 26.0], [289.0, 341.0, 538.0, 1250.0, 4052.5, 9882.0, 12305.0]),
            ("05316770", 42, 90, None, [796.0, 800.0, 804.0, 806.0], [327.35, 437.7, 603.0, 1480.0, 4340.0, 9923.0, 13465.0]),
            ("05325000", 47, 102, None, [15.0, 22.0, 25.0, 30.0], [498.4, 585.0, 1040.0, 2510.0, 8160.0, 17800.0, 25200.0]),
            ("05326450", 53, 115, None, None, None),
            ("05330000", 57, 124, None, [18.0, 25.0, 28.0, 34.0], [641.2, 719.4, 1320.0, 2970.0, 9370.0, 20460.0, 28200.0]),
            ("05330713", 60, 130, None, None, None),
            ("05330920", 64, 139, None, None, None),
        ],
    },
    {
        "key": "rednorth",
        "label": "Red of the North",
        "short": "Red N",
        "line1": (35, 30, "44634766665656764666666656566666756"),
        "states1": "AAAAAACQAAD//////4gAAAAAAAwACAAAAAAABAAOAAAAAAAEAAHPAAAAAAQAAHGAAAAACAAAAHAAAAAIAAAAaAAAAAgAAAAkAAAACAAAAAMAAAAEAAAAAAAAAAQAAAAAAAAAAgAAAAAAAAACAAAAAAAAAAIAAAAAAAAAAgAAAAAAAAACAAAAAAAAAAIAAAAAAAAAAgAAAAAAAAACAAAAAQAAAAIAAAAGAAAAAgAAABgAAAACAAAAIAAAAAMAAAAgAAAAAQAAACAAAAABgAAAIAAAAACAAAAgAAAAAIAAACD/////gAAAwAAAAAGAAAEAAAAAAQAAAgAAAAACAAACAA",
        "counties1": "AAAAAACQAAD//////9AAACAiQQxA0AAAoCJBDEHfAACvokEIQQTOAPj+f///hHWACE/ECAL8BNAMSIQIAgQEaARIj//+BAQkBCjoiIOEBAcEKHiE/oQEBP//+ITOh/wEASEInnqEBAQBIf/+AoQEBOERCSP+hwQEMxEJIhL9hAT7///+EpDEBI4iCEP/kEQEnCIIQiCYfAT+IghCIJhEBwYiCEIg/8QHgyIIQj+UR/1x////4JREMREQQREglkQhHxBBEaD+R+ENH//44Mx0IRkIQQjgz9w/sYhBCP/IVHH/////pEhU0QDEEQmkT9WJAEQRCT/+X3kA//HL5EJX3w",
        "line2": (71, 61, "4345576434666666666556665666765666666666666565665656666666667656656"),
        "states2": "AAAAAAAAAAAAAEEAAAAAAAAAAAAAAAAAAABBAAAAAAD/////////////wQAAAAAAAAAAAAAAAIAAAAEAAAAAAAAAAAAAAABAAAAAgAAAAAAAAAAAAAAAQAAAAIAAAAAAAAAAAAAAACAAAADAAAAAAAAAAAAAAAAgAAAAOAAAAAAAAAAAAAAAYAAAAAfg/AAAAAAAAAAAAEAAAAAAIwMAAAAAAAAAAABAAAAAAD4AgAAAAAAAAAAAQAAAAAAAAcAAAAAAAAAAAEAAAAAAAAAwAAAAAAAAAABAAAAAAAAAFwAAAAAAAAAAQAAAAAAAABSAAAAAAAAAAEAAAAAAAAAMYAAAAAAAAABAAAAAAAAACBgAAAAAAAAAQAAAAAAAAAAIAAAAAAAAAEAAAAAAAAAADgAAAAAAAAAgAAAAAAAAAAcAAAAAAAAAIAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAABAAAAAAAAAAIAAAAAAAAAAgAAAAAAAAACAAAAAAAAAAwAAAAAAAAAAgAAAAAAAAAQAAAAAAAAAAQAAAAAAAABYAAAAAAAAAAEAAAAAAAAA4AAAAAAAAAABAAAAAAAAAYAAAAAAAAAAAQAAAAAAAAEAAAAAAAAAAAGAAAAAAAABAAAAAAAAAAAAgAAAAAAAAQAAAAAAAAAAAIAAAAAAAAEAAAAAAAAAAABAAAAAAAADAAAAAAAAAAAAIAAAAAAAAgAAAAAAAAAAACAAAAAAAAIAAAAAAAAAAAAgAAAAAAACAAAAAAAAAAAAIAAAAAAAAgAAAAAAAAAAACAAAAAAAAIAAAAAAAAAAAAgAAAAAAAGAAAAAAAAAAAAIAAAAAAAGAA//////////+AAAAAAADAAAAAAAAAAAAAgAAAAAABAAAAAAAAAAAAAIAAAAAAAgAAAAAAAAAAAAEAAAAAAAIAAAAAAAAAAAADAAAAAAAEAAAAAAAAAAAAAgAAAAAABAAAAAAAAAAAAAQAAAAAAAYAAA",
        "counties2": "AAAAAAAAAAAAAEIAAAAAAAAAAAAAAAAAAABCAAAAAAD/////////////wQAAAAAACAAICCABAIAgAeEAAAAAAAgACAggAQBAIADhAAAAAAAIAAgIIAEAQCAAIQAAAAAACAAICCABAGAgACGAAAAAAIgACAgQAQAgIAHgfgAAAACIf8gIEAEAICABACHg/AAAiEBICBABAEAgAQAgIxMAAI/Af/gf///////AID4QgAD/wBAIEBAAQAAIQCAAEIAAAEAQCBAQAEAACEAgABDwAABAEP/wEABAAAh/4AAQFwAAYBCAgBAAQAAIACAAEBSAACAQgIAQAEAACAAgABAMYAAgEICAf/////gAIAAQCBgAIBiAgECAQEAIACAAEAAYACAIgEBAgCBACAAgABAAHgAgCIBswIAgQA/AIAAQABcAIAiAPoCAIH/4wCAAEAAQACAIgAGAgBBB+IAwPhAAEP//////gIAQcHhAP+HwABAAAQQBAICAGBBIQDAAEAAQAAEEAQCAgAgfyEAwABAAEAADBAEAgIP4AAhAMAAQABAAAgQBAP///AAMQBAAEAAQAAIGAf+BBAwABEAQABAAEDwCAgEAgQQMAARAEAAQABDoAgIBAIEEB//8QBYAEAAQBAICAQDBBAQCBH//ABAAEAQCAgEAwQQEAgRBAYAQABACx////8EEBAIEQQDgEAAQ/6QECAB///wCBEEAIBAAEIAkBAgAQCAEAgRBACAQABCAPAQIAEAgB///wQAgEAAQgBAECABAIAQEAECAIBAAEIAQBAgAQCAEBABAgD/wABD/8AQMAEAgBAQAQIAgEAARABAEDABAIAIEAECAIBAAEwAQBAwAQCACBABAgCAQAB4ACAQEAEAgAgQAf5/gEAAeAAgEBABAIAQEAEIQIB/5csAKBAQAQCAEB//CECAQC8J+B/////////wAQhAgEA4CAgEBACACAQYIAEIQIBAMAgIBAQAgAgECCABCCCAQBAICAQEAIAIBAggAQgggEAQCAhMBACACAQIIAEIIIB/8AgP/AQAgAgEBCAB/yCAQDAIAYQEAIAIBAIgAYPggEAwCAGEB/////4CIAGCQPxAMAgBDAIAgAQCAiABgkCEQCAIAggCAIAEAgIgAYJ/h8A//AwMAgCABAICP/+CAIRAJAswBAIAgAQCA+CAggCEQGQIwAYCAIAEAgIggIIAjMGEC//////////+IICCAIiDBAgAAQCACAQCAiCAggDIhgIIAAEAgAgEAgIggIJ/yIwCCAAAgIAIBAIEP///4MiMAggAAICACAQCDCCAgBDP+PoIAAEAgAgEAggggIAQSJ+P/AAB///4B8If4ICAGEiYCAg",
        "gauges": [
            ("05049000", 4, 9, None, [90.0, 92.0, None, None], [34.34, 55.26, 87.5, 173.0, 510.0, 1096.0, 1669.0]),
            ("05051500", 10, 18, [3.79, 3.96, 4.38, 5.17, 7.19, 8.88, 10.29], [9.5, 11.0, 13.0, 15.0], None),
            ("05051522", 13, 25, [10.02, 10.12, 10.46, 11.06, 12.86, 15.39, 18.59], [28.0, 30.0, 34.0, 38.0], None),
            ("05064500", 20, 37, [3.89, 4.16, 4.94, 6.04, 9.09, 13.89, 19.17], [24.0, 26.0, 32.0, 37.5], None),
            ("05082500", 26, 49, [15.59, 15.69, 16.0, 16.48, 17.83, 21.72, 27.14], [27.0, 28.0, 40.0, 46.0], None),
            ("05092000", 32, 60, [11.69, 11.81, 12.23, 13.11, 14.58, 23.65, 31.56], [28.0, 32.0, 38.0, 42.0], None),
            ("05102490", 35, 67, [11.01, 11.23, 11.81, 13.7, 17.87, 29.38, 38.89], [35.0, 39.0, 44.0, 49.0], None),
        ],
    },
    {
        "key": "platte",
        "label": "Platte",
        "short": "Platte",
        "line1": (1, 24, "020106767676765670000017076770707000000000100110100000700776770700010122000"),
        "states1": "AAQAAAAAAAwABAAAAAAADAAEAAAAAAAEAAQAAAAAAAQABAAAAAAABAAEAAAAAAAGAAQAAAAAAAIABAAAAAAAAgAEAAAAAAAD////wAAAAAEAAABAAAAAAQAAAEAAAAACAAAAQAAAAAMAAABAAAAAAQAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAH//////AAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAA",
        "counties1": "QiREf///n+9CJ//nTqaSvEIkQkRIpPKnQiRCf///n/RD58JkSCSSnEI8QmRIJPrfwgf+f/g/n76CBEPCCDT+ioIEQkIIJLKP/////g/////AgIJCCESSk0CAg///X/+fYICCQkP8kpExh//CRpSS//GERH////+UDwREQkSUkp8JBERCRJSSkg3/xH//////v2EERESRIkn9/wRERJEiSV3/////////5aEQRESRIuLHIRBERJE+4sYhEEREkeL/w/0f////I/5DBRBERJE+kqOHEEREkeLzPoQQf///Ip6jhB/JKIk/iuD/8EkoieL7MIRASSj7Ikofhv///4//Tg",
        "line2": (2, 48, "200200010176766767676676767666657070100107010007077767607070700707070000000000700001011001011010100000000000700707777777770700007001000112222107000"),
        "states2": "AAAAEAAAAAAAAAAAAAAAgAAAABAAAAAAAAAAAAAAAMAAAAAQAAAAAAAAAAAAAABgAAAAEAAAAAAAAAAAAAAAcAAAABAAAAAAAAAAAAAAACAAAAAQAAAAAAAAAAAAAAAwAAAAEAAAAAAAAAAAAAAAEAAAABAAAAAAAAAAAAAAABAAAAAQAAAAAAAAAAAAAAAQAAAAEAAAAAAAAAAAAAAAEAAAABAAAAAAAAAAAAAAABgAAAAQAAAAAAAAAAAAAAAMAAAAEAAAAAAAAAAAAAAABAAAABAAAAAAAAAAAAAAAAQAAAAQAAAAAAAAAAAAAAAGAAAAEAAAAAAAAAAAAAAABAAAABAAAAAAAAAAAAAAAAIAAAAQAAAAAAAAAAAAAAACAAAAEAAAAAAAAAAAAAAAAv////////AAAAAAAAAAAAIAAAAAAAAQAAAAAAAAAAACAAAAAAAAEAAAAAAAAAAAAgAAAAAAABAAAAAAAAAAAAQAAAAAAAAQAAAAAAAAAAAEAAAAAAAAEAAAAAAAAAAAAgAAAAAAABAAAAAAAAAAAAEAAAAAAAAQAAAAAAAAAAABAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAB////////////8AAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAA",
        "counties2": "EAgIEDAQGAAAIIQAgggg/xAICBAwEB///////4P//MAQCAgQEBAIECB4hByCCIXAEAgIH///+BAgQIQQggiHcBAICBAQCBAQIECEEP4IhCAQCAgQEAgQECBAhBCCCIQ/EAgIEBAIEBAgQIQQggiEEBAICBAQCB///////8P//xAQD/gf8AgIEBBABBBCBEHwEAgIEBAICBAQQAQQQgRBEBAID/AQCAgQEEAEEEeEQRgQCAAQEAgIEBBABBB4hHkf8AgAH//4H///wAf/wM3P/MAIABAQCBAEAEAGEEH+QQSACAAQEAgQBABABhB/yEGGgAgAEBAP8AQAQAQQQQhAhIAIABAQCBAEAEAEEEIIQP+ACAAQEAgQBABABBBGCECagAgAEBAIEAQAf///2///5v/////////8AEAQEHIIQWZgAIAAQAgQBABAEBBiCEEDIACAAEAIEAQAQBAQQghBAjAAgABACBAEAEAQEEIIQf4QAIAAQA/////+Ef///8EGGACAAEAIEAgQC//wQghBAwgAgABACBAIEAiCEEIIQQEMAIA/4AgQCBAIghBCCH//BgCAID//8AgQGIIQQghBEA8AgCAgIBAIEBCCEEIIQRD5AYAgICAf/////////8EQAP8AICAgEAgQIIIQQghB/wCBACAgIBAIECCCEEIIQQgAgQAgICAQCBAgghBCCEEIAIEAICAgEAgQIIIQQghBCACB///gIB////////////8B84ABACAQEBAggQPECCBB4R8cAQAgEBAQIIECBAggQTfReAEAIBAQECCBAgQIIEEccf//ACAQEBAggQIECCBB3BHAAQAgEBAQIIECBAggQSYTYAEAIBAQECCBAgf4IEFn8f/////////////8D///RBHIAQIAEBAQIEECBAhICEgSCAECABAQECBBAgQIWAjwEggBAgAQEBAgQQIECFgIoBQIAQIAEBAQIEECB/hMCCAUCAECABAQECBBAgQIRAhgGAgBAgAQEBAgQQP8CGf/YB//8QIAH//////+BA/hiOAJABED//AgICBBAgQIfwRgCQARAgAQICAgQQIECEIEMAkAEQIAECAgIEECB/hCBIwJAB8CABAgICBBA/wIfgcECYAQAgAQICAgQQIECEcEDAiAEAIAECAgIEECBAhB/A/8gBACAB///////gQIQYQEB4AQA//wQghAQIIH/8CEhACAEAIAEEIIQECCBAhAhIwA///+ABBCCEBAg/wIf4T4AIAQIAAQQghAQIIECCCHDACAECAAEEIIQH+CBAgghAYAgBAgABBCCEBAggQIIIQD/4AQP///////wP4ECCCEAYEAHPAQEEEAQEBD//4g/A",
        "gauges": [
            ("06710247", 11, 22, None, [15.5, 16.0, 17.0, 18.5], [14.0, 18.54, 25.7, 44.5, 86.9, 185.0, 451.0]),
            ("06721000", 15, 30, None, [10.0, 11.0, 13.0, 15.0], [126.0, 155.2, 225.0, 292.0, 367.5, 673.8, 1139.0]),
            ("06759500", 23, 45, None, [15.0, 17.5, 19.5, 21.5], [66.6, 95.34, 175.0, 269.0, 419.0, 696.2, 1048.0]),
            ("06764880", 37, 74, [1.83, 2.04, 2.43, 2.84, 3.3, 3.95, 4.51], [7.0, 9.0, 11.0, 13.0], None),
            ("06768000", 50, 98, [2.42, 2.51, 2.66, 3.04, 3.42, 3.73, 3.89], [6.5, 7.5, 12.0, 14.0], None),
            ("06770500", 58, 114, [2.98, 3.14, 3.35, 3.66, 4.04, 4.33, 4.56], [5.5, 6.5, 7.0, 7.5], None),
            ("06774000", 63, 123, [2.75, 2.98, 3.3, 3.66, 4.01, 4.28, 4.47], [7.0, 8.0, 9.0, 10.0], None),
            ("06796000", 67, 132, [2.44, 2.66, 3.04, 3.39, 3.71, 4.25, 4.67], [7.0, 8.0, 10.0, 11.5], None),
            ("06796500", 70, 136, [3.54, 3.69, 3.97, 4.24, 4.54, 5.05, 5.37], [7.5, 8.0, 10.0, 12.0], None),
            ("06805500", 73, 143, [2.31, 2.57, 3.0, 3.36, 3.74, 4.27, 4.59], [8.0, 9.0, 11.0, 12.0], None),
        ],
    },
    {
        "key": "kansas",
        "label": "Kansas",
        "short": "Kan.",
        "line1": (1, 16, "0070000000101000070000010070000101010766070070707170100001017070"),
        "states1": "CAAAAAAAAgAIAAAAAAADAAgAAAAAAAGACAAAAAAAAIAP////////4AgAAAAAAAB4CAAAAAAAAAwIAAAAAAAADAgAAAAAAAAYCAAAAAAAABAIAAAAAAAACAgAAAAAAAAMCAAAAAAAAAYIAAAAAAAAAwgAAAAAAAABCAAAAAAAAAEIAAAAAAAAAQgAAAAAAAABCAAAAAAAAAEIAAAAAAAAAQgAAAAAAAABCAAAAAAAAAMIAAAAAAAAAwgAAAAAAAADCAAAAAAAAAMIAAAAAAAAAwgAAAAAAAACCAAAAAAAAAIIAAAAAAAAAggAAAAAAAACCAAAAAAAAAIIAAAAAAAAAg",
        "counties1": "+CIJEiRIkiMP//////j/8QgiERIkSImRCCIREiRIiJ8P////////8QhBEQiIRCR5CEERCIhEJE8IQREIiEQkXf/////////xCEERCIxLER8IQREIhEoR+QhBEQiHyxEpCEERCPxN/y0P////hH/ZK/hCEQiEScn/CEIRCP/Pj7EIQhEIhEjIkw////+ESHj++JEgiIf4SZIIkSCI/E/JEwiJIIiERE/+CIkg+4RESRL///+P//R5EgiIEMSCH8kSCInw/IIQj/8IiR+Ig/CJEgiJEI+CEYkSD/8Q+P4Rj/74iRCIhBH5EwiJ/IiH/4kSD/8T//wRj/IIiRCIRBH5Hw",
        "line2": (2, 32, "00070701070100007170101100010000000700000000010001060107700000000100127030100300077666600060000607007707072702700100100107207010110700600700"),
        "states2": "AEAAAAAAAAAAAAAAAAQAAABAAAAAAAAAAAAAAAAEAAAAQAAAAAAAAAAAAAAABgAAAEAAAAAAAAAAAAAAAAMAAABAAAAAAAAAAAAAAAAAgAAAQAAAAAAAAAAAAAAAAIAAAEAAAAAAAAAAAAAAAABAAABAAAAAAAAAAAAAAAAAQAAAQAAAAAAAAAAAAAAAAGAAAH/////////////////wAABAAAAAAAAAAAAAAAAAHAAAQAAAAAAAAAAAAAAAAAeAAEAAAAAAAAAAAAAAAAAAwABAAAAAAAAAAAAAAAAAAMAAQAAAAAAAAAAAAAAAAADgAEAAAAAAAAAAAAAAAAABgABAAAAAAAAAAAAAAAAAAQAAQAAAAAAAAAAAAAAAAAMAAEAAAAAAAAAAAAAAAAACAABAAAAAAAAAAAAAAAAAAQAAQAAAAAAAAAAAAAAAAAEAAEAAAAAAAAAAAAAAAAAAwABAAAAAAAAAAAAAAAAAAEAAQAAAAAAAAAAAAAAAAABgAEAAAAAAAAAAAAAAAAAAMABAAAAAAAAAAAAAAAAAABwAQAAAAAAAAAAAAAAAAAAGAEAAAAAAAAAAAAAAAAAAAgBAAAAAAAAAAAAAAAAAAAIAQAAAAAAAAAAAAAAAAAACAEAAAAAAAAAAAAAAAAAAAgBAAAAAAAAAAAAAAAAAAAIAQAAAAAAAAAAAAAAAAAACAEAAAAAAAAAAAAAAAAAAAgBAAAAAAAAAAAAAAAAAAAIAQAAAAAAAAAAAAAAAAAACAEAAAAAAAAAAAAAAAAAAAgBAAAAAAAAAAAAAAAAAAAIAQAAAAAAAAAAAAAAAAAACAEAAAAAAAAAAAAAAAAAAAgBAAAAAAAAAAAAAAAAAAAIAQAAAAAAAAAAAAAAAAAAGAEAAAAAAAAAAAAAAAAAABgBAAAAAAAAAAAAAAAAAAAYAQAAAAAAAAAAAAAAAAAAGAEAAAAAAAAAAAAAAAAAABgBAAAAAAAAAAAAAAAAAAAYAQAAAAAAAAAAAAAAAAAAGAEAAAAAAAAAAAAAAAAAABgBAAAAAAAAAAAAAAAAAAAYAQAAAAAAAAAAAAAAAAAAGAEAAAAAAAAAAAAAAAAAABgBAAAAAAAAAAAAAAAAAAAYAQAAAAAAAAAAAAAAAAAAEAEAAAAAAAAAAAAAAAAAABABAAAAAAAAAAAAAAAAAAAQAQAAAAAAAAAAAAAAAAAAEAEAAAAAAAAAAAAAAAAAABABAAAAAAAAAAAAAAAAAAAQAQAAAAAAAAAAAAAAAAAAEAEAAAAAAAAAAAAAAAAAABABAAAAAAAAAAAAAAAAAAAQAQAAAAAAAAAAAAAAAAAAEAEAAAAAAAAAAAAAAAAAABA",
        "counties2": "/8AIBADBAgQIECBAgQwMBABACAQAgQIECBAgQIEGBAcAf////////////8CBBgQCAEAIBAIBAgQIECBA///+AgBACAQCAQIECBAgQICHggIAQAgEAgECBAgQIECAgIMCAEAIBAIBAgQIECBAgIBD/gBACAQCAQIECBAgQICAQwIAQAgEAgECBAgQIECAgGEDAH/////////////////xAgBAEAICAQCAQEAgEAgQLQIAQBACAgEAgEBAIBAIECeCAEAQAgIBAIBAQCAQCBAg/gBAEAICAQCAQEAgEAgQIMIAQBACAgEAgEBAIBAIECDjAEAQAgIBAIBAQCAQCBAhAgBAEAICAQCAQH/gEAgf/wL////////////gP///8QMCAEAQAgEBAIBAYCBCAQMD/gBAEAIBAQCAQGAgRgEDAQIAQBACAQEAgEAgIEwBA/+DAEAQAgEBAIBAICBMAQIEwgBAEAIBAQCAQCAgRgECBEIAQBACAQEAgEA/4EIBAgRCAEAQAgEBAIB/4CBhAf4EIgBAEAIBAQCAQCAgYf8CDHoAf////////8AgP+BjAghPAEAgCAEBAIBAICB/oMIIQv/AIAgBAQCAQCAgQ+BD+H4AQCAIAQEAgEAgIECAQIvCAEAgCAEBAIBAP+BAgECOAgBAIAgBAQCAf+Agf4B/ggIAQCAIAQEAgEAgIGDgQIIHAEAgCAEBAIBAICBgIECCBABAIAgBAQCAQCAgYD/A//wAf////////8AgIEAgQIIEAEBBAgQAgIBAICBAIEGCBP/AQQIEAICAQD//wCBBggQAQEECBACAgH/gIH/gQQIEAEBBAgQAgIBAICAQIEECBwBAQIIEAICAQCAgECB/AgQAQECCBACAgEAgIBAgQf/8AEBAggQA/4BAICAQIEECBABAQIIEAICAQCAgECBBAgT///////+A/8AgIBAgwQIEAEBAgAIAgCB///4QP4ECBABAQIACAIAgQAQCECCBAgQAQECAAgDwIEAEA//ggQIEAEBAgAIAkCBABAIAgP///wBAQIH+AJ/gQAQCAICBAgQAQECBAgCAgEAEAgCAgQIEAEBAgQP/gIBAB/4AgIECBABAQIECAID/wAQCAYCBAgQAQECBAgCAQEAEAgGAgQIEAH///wIA/8B//AIBgP/+BABAQIECAIBAQBACAYCBA/z/wECBAgCAQEAQAgGAgQIHAEBAgQIAgEBAEAIB/4ECBABAQIECAIBAQBACAYCBAgQAQECB//CAQEAf//+AgQIEAEBAgQEfgH/AEAIBgIECBAB///8BAP/Af/ACAYD//gQAQECBAQCAQBAQAgGAgQP/AEBAgQEAgEAQEAIB/4ECBA",
        "gauges": [
            ("06860000", 13, 26, [3.89, 3.89, 3.9, 3.93, 4.23, 4.38, 4.63], [8.0, 9.0, 11.0, 13.0], None),
            ("06861000", 19, 39, [-0.2, -0.19, -0.1, 0.07, 0.3, 0.45, 0.69], [6.0, 7.0, 9.0, 11.0], None),
            ("06862850", 25, 50, [1.65, 1.65, 1.82, 2.37, 2.68, 3.09, 3.36], [10.0, 11.0, 14.0, 17.0], None),
            ("06864000", 28, 58, None, [16.0, 18.0, 20.0, 38.0], [1.95, 3.63, 8.16, 13.7, 25.3, 50.2, 62.09]),
            ("06864500", 33, 68, [1.06, 1.11, 1.23, 1.47, 1.7, 2.05, 2.53], [18.0, 20.0, 24.0, 27.0], None),
            ("06866000", 37, 82, None, [19.0, 21.0, 29.0, 33.9], [16.61, 19.5, 25.4, 47.6, 98.35, 203.0, 373.6]),
            ("06870200", 41, 89, None, [25.0, 27.0, 30.0, 33.1], None),
            ("06877600", 44, 95, [5.59, 5.67, 5.91, 6.43, 7.04, 8.36, 10.92], [21.0, 26.0, 27.0, 40.0], None),
            ("06879100", 47, 101, [4.14, 4.23, 4.44, 4.86, 5.29, 6.47, 7.54], [17.0, 21.0, 26.0, 33.0], None),
            ("06887500", 50, 111, [3.16, 3.23, 3.37, 3.66, 4.5, 6.26, 7.63], [15.0, 19.0, 26.0, 38.0], None),
            ("06889000", 55, 121, [4.97, 5.07, 5.27, 5.68, 6.74, 8.82, 10.49], [15.0, 26.0, 27.0, 44.0], None),
            ("06891080", 59, 129, [13.16, 13.31, 13.45, 13.6, 13.73, 13.82, 13.88], [15.0, 18.0, 20.0, 29.0], None),
            ("06892518", 63, 137, None, [23.0, 26.0, 33.0, 38.0], [1030.0, 1130.0, 1290.0, 1950.0, 4107.5, 8958.0, 14500.0]),
        ],
    },
    {
        "key": "canadian",
        "label": "Canadian",
        "short": "Can.",
        "line1": (1, 7, "101222212321022000000006000000076070700010702070171110101002120001617007707177"),
        "states1": "AAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAQAAAAAAD//////////wAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAH//+AAAAAAAQAAIAAAAAABAAAgAAAAAAEAACAAAAAAAQAAIAAAAAABAAAgAAAAAAEAACAAAAAAAQAAIAAAAAABAAAgAAAAAAEAACAAAAAAAQAAIAAAAAABAAAgAAAAAAEAACAAAAAAAQAAIAAAAAABAAAgAAAAAAEAADAAAAAAAQAAHgAAAAABAAADAAAAAAEAAAH+AAAAAQAAADuAAAABAAAAA1UHg",
        "counties1": "8REST/dD5Ep/ERJKE8IkSgv///sefiR/iAQSSRJEJ8qwBB/////8fsAEEkkSJifLgAQSSRIiJEr//////////4EEECCYaIhpgQQQIIxIiGkBBBAgnkiwfQEH///zT/hvAQQSSKP4rGn/BBJIogi/aQ30Eki//+//DBf//9iS/KYEFBJEv5I17v8cEkSIv+U6AJf//4jiJz8AVBJE/6I+5QB0IkSIv+/P/sf//5iLKn0DBCJE/4uuzwIMIkToiv6LBhQiRK37/4oOZ///vx82zzvEiSTnsfz5IUSJJLzx36Hhf///nJ8yIyEEkkTX+Z/+P4SSRPJv9GIghJJEki3c/w",
        "line2": (2, 15, "01010102223222121212322241102220027100717000000066170000000010007677007707070000010010707612100676011177611211110011011601001121210007101600270600077070707010777"),
        "states2": "AAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAA/////////////////////wAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAf/////4AAAAAAAAAAAAAAEAAAAACAAAAAAAAAAAAAABAAAAAAgAAAAAAAAAAAAAAQAAAAAIAAAAAAAAAAAAAAEAAAAACAAAAAAAAAAAAAABAAAAAAgAAAAAAAAAAAAAAQAAAAAIAAAAAAAAAAAAAAEAAAAACAAAAAAAAAAAAAABAAAAAAgAAAAAAAAAAAAAAQAAAAAIAAAAAAAAAAAAAAEAAAAACAAAAAAAAAAAAAABAAAAAAgAAAAAAAAAAAAAAQAAAAAIAAAAAAAAAAAAAAEAAAAACAAAAAAAAAAAAAABAAAAAAgAAAAAAAAAAAAAAQAAAAAIAAAAAAAAAAAAAAEAAAAACAAAAAAAAAAAAAABAAAAAAgAAAAAAAAAAAAAAQAAAAAIAAAAAAAAAAAAAAEAAAAACAAAAAAAAAAAAAABAAAAAAgAAAAAAAAAAAAAAQAAAAAIAAAAAAAAAAAAAAEAAAAACAAAAAAAAAAAAAABAAAAAAgAAAAAAAAAAAAAAQAAAAAIAAAAAAAAAAAAAAEAAAAACAAAAAAAAAAAAAABAAAAAAgAAAAAAAAAAAAAAQAAAAAIAAAAAAAAAAAAAAEAAAAACAAAAAAAAAAAAAADAAAAAAwAAAAAAAAAAAAAAwAAAAAKAAAAAAAAAAAAAAMAAAAAAQgAAAAAAAAAAAADAAAAAAD8AAAAAAAAAAAAAwAAAAAAAgAAAAAAAAAAAAMAAAAAAAIAAAAAAAAAAAACAAAAAAAD4AAAAAAAAAAAAgAAAAAAAB74AAAAAAAAAAIAAAAAAAABiAAAAAAAAAACAAAAAAAAAA5AAAAAAAAAAgAAAAAAAAAG+SIAEcAAAAIAAAAAAAAABz//B39w",
        "counties2": "oAICAgEEEPwC/hAECBAghGeCAgIBBBCH/ggQB/gQIIQ44gICAQQQhAIIEAQIECCEADoCAgEEEIQCD/AECBAghABGAgIB//+EA/wf/AgQP/wAQ////wQQhgIEEBAIECCHgIAAIAEEEIICBBAQCB/ghIEAACABBBCCAgQQEAgQIIRBAAAgAQQQ//4H8B//8CCERgAAIAH//4ED/B/4CBA//PgAACABBBCBAgQEGAgQIIfgAAAgAQQQgQIEBBgIH+CEQAAAIAEEEIECBAQICBAghIAAACABBBCBAgQECAgQIISAAAAgAQQQgQIEBAgIECCE/////////////////////4ABABABAAQAgIAggIBAKEKAAQAQAQAEAICAIICAQChCgAEAEAEABACAYCCAgEAoQoABABABAAQAgHAggIHAKEIAAQAQAQAEAIBIIICHAChDAAEAEAEABACBxCCAjwAv4gABABABAAQA/wQg//fAKCIAAQAf/////4QHIICHwCh+AAEAEAIIEECEBP+AhkA4QgABABACCBBAhARAgIY4KEIAAQAQAggQQIQEAICCFihC//8AEAIIEECEBACAj4EoQgB5wBACCBBAh/////j/7kcAIH8QAggQQICAQgRAI8X8ACABH/////+ggEIEQCBECAAQARACCBAg8YBCBH/gRBAAEAMQAggQIJqAQgQIIEwQgCADEAIIECCM/8IECCH+fP//AxACCBAggIBCBAghBeQAAIPwAggQIICAR//4IQQEAACCH/////+AgEQECD8EBwAAQhACCBAggIB8BAghz+QAAEIQAggQIIeARAQIIEgkAAAyEAIIECD8/8QED/hQIgAAHhAECBAggIBH5/j4cCUAABAQBAgQIICAQP4Ij+Do//zwEAQIECCAgECHCIgj0AAHgB//////gIBAhQiILuEABgAQBAgQIJ//wISIiDAhAAQAEAQIECDwQECEyIhA/wAEABAECBAgoEBAhHqIQIEABADwBAgQILhAQIQf/ECDAAQDkAQIECCIcf+H/nxAhgAcBhAECBAgiPEAhAIHwIQAFAQf/////48RAIQCBECEAHQ8EECCBBCIHQH+Bhxw/w/H4BBAggQQyB8BAhuQX4EIASAQQIIEEPgRwwP58MYDCAEgEECCBBCQoF0CQZCEAggBIBBAggQQj+BhAnEfhAL4AT4f/////4EgQQIPBAQCCAE/8IIEECCBIEH+AgQEDggBABCCBBAgwT5BAgOMBAgIAQAQggQQIOEH74ID///4DAfAEIIEECCfBDiD/hAwCA/8QBCCBBAggQQI5gIgEAgIAEAQggQQIIEECG+TMBscCABAEIIEECCBBAhz//A/9w",
        "gauges": [
            ("07211500", 7, 15, None, [35.0, 38.0, 43.0, 48.0], [0.0, 0.0, 0.02, 1.42, 8.06, 22.69, 74.09]),
            ("07221500", 12, 26, None, [21.0, 22.0, 26.0, 30.0], [0.0, 2.36, 6.52, 29.6, 72.6, 210.0, 345.6]),
            ("07223500", 15, 31, None, None, None),
            ("07227000", 20, 42, None, None, [1.94, 2.16, 2.4, 2.76, 3.3, 3.64, 4.11]),
            ("07227500", 30, 63, [0.7, 0.76, 0.9, 1.08, 1.27, 1.81, 2.32], [6.0, 7.0, 10.0, 15.0], None),
            ("07228000", 40, 83, [0.74, 0.85, 1.1, 1.24, 1.37, 1.53, 1.88], [7.0, 8.0, 10.0, 20.0], None),
            ("07228500", 54, 115, None, [12.0, 14.0, 16.0, 17.0], [5.44, 10.3, 28.25, 109.0, 153.5, 190.0, 240.5]),
            ("07228940", 58, 122, None, [21.0, 22.0, 24.0, 26.0], [16.12, 41.5, 101.0, 156.0, 256.0, 426.8, 659.8]),
            ("07229200", 62, 129, None, [11.0, 12.0, 13.0, 14.0], [38.63, 63.63, 133.0, 236.0, 389.25, 774.6, 1420.0]),
            ("07231500", 70, 146, None, [18.0, 20.0, 23.0, 25.0], [77.5, 96.4, 226.0, 418.0, 790.0, 1860.0, 4250.0]),
            ("07245000", 76, 158, None, None, [103.0, 183.5, 777.5, 2250.0, 4547.5, 11000.0, 24900.0]),
        ],
    },
    {
        "key": "yellowstone",
        "label": "Yellowstone",
        "short": "Yellow.",
        "line1": (19, 31, "556565764456706600772010007076000770000000776700776707675"),
        "states1": "AAAAAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAAB//wAAAAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAQACAAAAAAABAAIAH/////8AAwAQAAAAAQABgFAAAAABAACPsAAAAAEAAHgQAAAAAQAAQBAAAAABAAAAEAAAAAEAAAAQAAAAAQAAABAAAAABAAA",
        "counties1": "MPAMYIf57MgwEAjBihBAfzAQH4GSMEDg/n4Qf+Y+Q7DjgzAUBCNCP6EB4DQGIf4RsYJwZAPhWhdQyhBEA6DSFFB3EEQCONf/3GEQR//fVBAmIf/8AmdUHCPwRQYCPv//I8xFB+IGQRk+RESeIgR/yWxf//EiD0F53GJMg6IJQQ614kyN5gn//9/iSIgn+EEICDJZiDYIQQgIFnP4FghBDwQUZEAWCEEJhBRseBYIfwuGFHgYHghBCoMX/////8H7wZQARgEIQQhh9wBDAQhBCSPtwGH/CH8PvmRAIEEISDzQhCAgQQhIKPCEID/BD//orwQg4EEIQA/5/DywQQh/iA",
        "line2": (38, 62, "564656565665477564545657776766710670701201001000070707767000007077770010000000700767007675007170776767776766706056"),
        "states2": "AAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAf////AAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAACAAAAAAAAAAAAAAAAQAAAAQAAAAAAAAAAAAAAAEAAAAEAAAD////////////AAAABAAAAgAAAAAAAAAAAQAAAAQAAAIAAAAAAAAAAAEAAAAHAAACAAAAAAAAAAABAAAAAoAAIgAAAAAAAAAAAQAAAACAAHIAAAAAAAAAAAEAAAAAwABKAAAAAAAAAAABAAAAAEB9xgAAAAAAAAAAAQAAAABPggIAAAAAAAAAAAEAAAAAOAACAAAAAAAAAAABAAAAABAAAgAAAAAAAAAAAQAAAAAAAAIAAAAAAAAAAAEAAAAAAAACAAAAAAAAAAABAAAAAAAAAgAAAAAAAAAAAQAAAAAAAAIAAAAAAAAAAAEAAAAAAAACAAAAAAAAAAABAAAAAAAAAgAAAAAAAAAAAQAAAAAAAAIAAAAAAAAAAAEAAAAA",
        "counties2": "AgMCAABgBACAPL/d97jAQAMB/gAAYBwAgCfBAHTwIEAOAAIAAGDwAIBwAQAYAGBADgACAABAgAGAWAMAEABP/wYAAgAAT4ABgYgHABAAbAAKAAIAA/DAAYYIBgAQAFwACmAf4AIAeAf8CAfAEAfEAPmQcDACADfrABgEfBAEBgCICcAMAgAPcAAQBAYQBAOOjAfABwwAAiAAEAQCEAQCeoQBAAPwAAIgABAEAjAEAgOEAQAGMAAOIAAcBAP//AMBhAEACBwAOCAABAQAkQQBAecBgAgHACAgAAf8AJEEAR8hAOAEAQAgIAAFhACRBAEQIQAgRgEAMDAABYQAkQQBECEAJ/IBABAQAAQHAJEf//8hACQaAQAQEAAEAYEREAEAIQA8DgEAED///wB/ERABAPHgDAYDABAoAAfgBBEQAQCcIAwBHx//+AAEMAQREAHwBDgKAPPxABgABBgPERABEAQICwAgEYAYAAQIOPf//58ECfkAIBCACAAED8gcAgGBBA4hwCAQgA/gBAA4EAIBgQQMIKAgEMA8OAwAIBABAIEEMCBgIBBAZAgMACAQAQCBD+AgQCAQQcIICAAgH//wgDwgIf8/8EcCCAgAIBACH4Ag4CMH4J/8AQwIAH4QAgCAIaAyBCBQgAEECABDEAIA48MgFgQgcIAPhAgAQRACAJ6CEBQEIDCAGeQIAEH/////nhHYCCBggHA8CABAMAIAgHMbMAggQIBABA//wBACAIBAnhAIIECAQAQIAEAQAgCAAGAICCBAgEAHCABAEAIAgABABwghw8BAAQgAQBACAIAAQAEQJwZgwAEYAEAQAgCAAGABECQMPwABGABAEAIA/wBwARAkMBAAAxgAQBACAIIAEAEwLGAwAAIYAIAQAgCCABABICjAIAACGACAEAIAggAQASAogD+AAhgAgB/+AISAEAMgP4AAgAP4AIAQAgCEQBgCIAEAAQAACACAEAIAhEAOAj////////////AD/4fAAgIgAAAfEAAD8IAQAgCAwAICIAAAEBAAAgCAEAIAgHADAiAAABAYAAIAgBACAIAoAeIgAAAQDAACAIAQAgCACAA/PgAAEAcAAgCAEAIAgQwABKIAABABgAIAgBP+AJoEB9xj4AAYAP/+AIAfgAD0xPg4ICAACABgAgCAEIAAwMOAOCAgAAgAIAIAgBCAB4AhACAgMAAIACACAIAQgASAIQBAIBAACAAgAgCAEMAMgH8AwCAQAAgAIAIAgBBACIBEAYAgGAAP//ACAP////iARH8AIAgAeAAwAgCAEAAAgERCACAIAMwAMAIAgBAAAP9Hw8fgDmCEADACAIAQAACAQEC/IAuzhwAQAgCAH//AgA",
        "gauges": [
            ("06186500", 5, 10, None, [8.0, 9.0, 10.0, 11.0], [257.2, 324.4, 451.0, 667.0, 1490.0, 3116.0, 3916.0]),
            ("06191500", 11, 21, None, [None, 11.0, 12.0, 13.0], [539.2, 683.8, 917.0, 1350.0, 3040.0, 7108.0, 10070.0]),
            ("06192500", 15, 28, None, [None, 10.0, 10.5, 11.0], [937.8, 1050.0, 1300.0, 1690.0, 3370.0, 8432.0, 12300.0]),
            ("06214500", 28, 54, None, [12.5, 13.5, 14.5, 15.0], [1900.0, 2110.0, 2500.0, 3290.0, 5550.0, 15900.0, 25060.0]),
            ("06295000", 39, 73, None, [None, 14.0, None, None], [3982.0, 4452.0, 5150.0, 6030.0, 9200.0, 20480.0, 31990.0]),
            ("06309000", 43, 82, None, [None, 14.0, None, None], [3840.0, 4560.0, 5370.0, 6460.0, 9800.0, 21240.0, 33940.0]),
            ("06327500", 50, 99, None, [51.5, 53.5, 60.0, 65.0], [4320.0, 4930.0, 5770.0, 6840.0, 9860.0, 23640.0, 36280.0]),
            ("06329500", 55, 108, None, [17.0, 19.0, 20.0, 21.7], [3530.0, 4282.0, 5720.0, 6870.0, 10400.0, 22700.0, 35500.0]),
        ],
    },
    {
        "key": "snake",
        "label": "Snake",
        "short": "Snake",
        "line1": (54, 19, "53422032223555553132343324443444544646444445555567654667676767665465664543454333"),
        "states1": "AAAQAgAAAAAAABABwAAAAAAAEABAAAAAAAAQAIAAAAAAABAAgAAAAAAACADAAAAAD//8AEAAAAD/AAYAgAAAADAAAgC4AAAAAAACAOgAAAAAAAQACAAAAAAABAAMAAAAAAAIAAQAAAAAAAgABAA//wAAEAAHAKAAAAAQAAEB4AAAACAAAP8gAAAAIAAAsCAAAAAwAAAAIAAAABgAAAAgAAAAGAAAACAAAAAQAAAAIAAAABAAAAAgAAAAEAAAACAAAAAQAAAAIAAAABAAAAAgAAAAEAAAACAAAAAQAAAAIAAAABAAAAAgAAAAEAAAACAAAAAQAAAAIAAAABAAAAAgAA",
        "counties1": "Pf4RA4dhj78P79MH+TeH6AyXPzzRHkYoBKT34JESJCQEwvfgi+L/5fxizwDKYxR/B//+AEWTFGh/A4oAm34UROkChgCwwZbcqIaCAfhAs7/ImIQAiCCjYuyQR/8MIKOD/I99gQQwoIAn/MmDRhi//+IEHQdnDKACIggXD5ED8ALiBBOIjP+sAj4PoYgG8yICDg7x9APGIgICPB/MBvwhB4fEHw8E7+FtZAQfE8ZE4fjcBBKjtH/hGPwEGkWIYGEOBAQWRM64J4MEBBJH/4c+gAwEEcSLgShACAQQ9I7/6EAIBBAX/ugoMI8EEB+2PCgYgQQQBPu16AiBBBAEYPcoCA",
        "line2": (108, 38, "453432220032323213234565455645455321234223433242332343454432444445444544646663466344444542454565645556544676765755466677677666767676765645465657656644654544343454443224333"),
        "states2": "AAAAAAEAAAwAAAAAAAAAAAAAAAABAAAFAAAAAAAAAAAAAAAAAQAAAuAAAAAAAAAAAAAAAAEAAAAgAAAAAAAAAAAAAAABAAAAIAAAAAAAAAAAAAAAAQAAAGAAAAAAAAAAAAAAAAEAAABAAAAAAAAAAAAAAAABAAAAQAAAAAAAAAAAAAAAAYAAAEAAAAAAAAAAAAAAAACAAADAAAAAAAAAAAAAAAABAAAAwAAAAAAAAAAAAAAAAYAAAEAAAAAAAAAAAAAf//+AAABgAAAAAAAAAAAH4AAAwAAAIAAAAAAAAAAAOAAAAHAAAEAAAAAAAAAAc+AAAAAYAACAAAAAAAAAAJ4AAAAADAAAQwAAAAAAAAAAAAAAAAQAAM2AAAAAAAAAAAAAAAAMAADYgAAAAAAAAAAAAAAACAAAIIAAAAAAAAAAAAAAABgAAABAAAAAAAAAAAAAAAAQAAAAQAAAAAAAAAAAAAAAMAAAAEAAAAAAAAAAAAAAACAAAAAgAAAAAAAAAAAAAABgAAAAIAAAAAAAAAAAAAAAQAAAABAAAAAAAAAAAAAAAEAAAAAQAAAP////AAAAAABAAAAAEAAACAAAAAAAAAAAgAAAABYAAAgAAAAAAAAAAIAAAAALAACIAAAAAAAAAAEAAAAAAQAByAAAAAAAAAADAAAAAAEAASgAAAAAAAAAAgAAAAAAgbcYAAAAAAAAAAYAAAAAALvoCAAAAAAAAAAEAAAAAADuAAgAAAAAAAAABAAAAAAAQAAIAAAAAAAAAAYAAAAAAAAACAAAAAAAAAADAAAAAAAAAAgAAAAAAAAAAIAAAAAAAAAIAAAAAAAAAAEAAAAAAAAACAAAAAAAAAAAgAAAAAAAAAgAAAAAAAAAAYAAAAAAAAAIAAAAAAAAAAEAAAAAAAAACAAAAAAAAAABAAAAAAAAAAgAAAAAAAAAAQAAAAAAAAAIAAAAAAAAAAEAAAAAAAAACAAAAAAAAAABAAAAAAAAAAgAAAAAAAAAAQAAAAAAAAAIAAAAAAAAAAEAAAAAAAAACAAAAAAAAAABAAAAAAAAAAgAAAAAAAAAAQAAAAAAAAAIAAAAAAAAAAEAAAAAAAAACAAAAAAAAAABAAAAAAAAAAgAAAAAAAAAAQAAAAAAAAAIAAAAAAAAAAEAAAAAAAAACAAAAAAAAAABAAAAAAAAAAgAAAAAAAAAAQAAAAAAAAAIAAAAAAAAAAEAAAAAAAAACAAAAAAAAAABAAAAAAAAAAgAAAAAAAAAAQAAAAAAAAAIAAAAAAAAAAEAAAAAAAAACAAAAAAAAAABAAAAAAAAAAgAAAAAAAAAAQAAAAAAAAAIAAAAAAAAAAEAAAAAAAAACAAAAA",
        "counties2": "OEEABgECAASAHDwDAIDACA/D//wBAgAHgHMEA4BPR/8AbwAR4QIAA//BBwKAOPyAADEA/xkeAA+hAQE+QAgMYAAggR0F5gD8YQEByGAIDCAAIIMRhwYHAGEBAYgwGAwgACCCEN0PxABBgQMICBAIMAAghBhRPvgAQIEECBgQCBAAIMgIUaBYAECH+AgQH/gRACAwDFCngADAhBwIf/AgEQAgGARhpAAAwIQ0CMIQL///4AgEYLgAAEDMZAyCEDhAACAf//+oAABgeMIFghAYQAAn4AQA4AAAIDPCBwIQEGAAeQAHgGAAAEDtw3wCEBAgc8EADYAYAACBiGeMAhgQIN5BAA0ADAAAQwAYAgIYECAIQYAJAAQAAM2AEAHCCHHwhEDACIAMAADYgBAARgnBGIhAQBiACAADoIAYAEQJAw8YQEBgQBgAAwBADABECQwIEEBDwEAQAAGAQAQATAsQCBBgQgAgPgABgEAEAEgKYAjYMEOAPCJ//wAgBADID8APWBBAgARjwAMAIAcAiACAAH/wQIo/wIADABABAIgAgAAIH//14ECAAgAQAYCP////CAgAEADBgAIQEACAiAAACPwIADAA8QAEEBYAwIgAAAgECABgAREAPDwLAHiIAAAIBAgAwAMRADoiAQAPz4AACAQIAEACCQBDQwEAASiAAAj8CAAgBgiAwMEAgbeY8AAMhAgAYAQNgEAAwLvuCBAABAfoAEfkB4BAAHDuDggQAAQAKADMJAOAwAAIYAgICAAEADgA+DwDAaAACCAQCAQABAAIABAHA/8gAA/gEAgEAAQACAAQAP+AEAAIgCAIBgAHAAgH8AENAFAAGJ/gCAIAHgAIBBABuQBsABDw8DgCAHLAH/wQALEA32AQED/oA7jDfBAAEAGhAwywEBAuiALsgAYQABABfwQPHhgQIIgCh4AD8AAQAQiEGQ0gEDiIAgMA4CAAEAGIWBkBQB//6AIBgP/gABAByDARgMAUACgCAHAAIAAQAWggEMBANAA4AgAcACAAEAFoIBDAQOfACAPABwAgABABOCAQgHiAOAgeQAAAIAAQAQwgEOAPgA4O8CAAAGAAEAEEIB//+IACC4AgAABgABABAiAQgEiAAgiAIAAAQAAQAQPgEIBPgAIIgBAAAEAAEAEBsBCATJ//+IAYAABAABABAF8QgNy8QAiADAAAQAAQAQABGeDU9EAIgAQAAEAAEAEAARkclgRACIACAIB/ABABAAH9h5YGYAiAAwCAAQAQAQAAF4IeAmAIgACAgAEAEAEAABDyJ4IzqIAAgIABABABAAAQP8CGEniAAICAAQAQAQAAEAwAhRM4QACAgAEAEAEAABAcAJ0fCEAAgA",
        "gauges": [
            ("13010065", 3, 5, None, [9.0, 10.0, 11.0, None], [211.0, 227.0, 260.0, 315.0, 498.0, 1776.0, 3136.0]),
            ("13011000", 6, 9, None, [15.0, None, None, None], [259.2, 266.0, 280.0, 316.0, 1980.0, 2740.0, 4890.0]),
            ("13018750", 9, 17, None, [9.0, 10.0, 12.0, None], [1030.0, 1090.0, 1190.0, 1640.0, 3840.0, 7312.0, 8774.0]),
            ("13032500", 12, 24, None, [11.0, None, None, None], [881.0, 897.0, 921.75, 3700.0, 10225.0, 12300.0, 13100.0]),
            ("13038500", 15, 32, None, [9.0, None, None, None], [616.0, 663.0, 776.0, 1930.0, 5270.0, 7016.0, 8258.0]),
            ("13057155", 18, 36, None, [12.6, 13.2, None, None], [2140.0, 2265.0, 2570.0, 3405.0, 6390.0, 8450.0, 10300.0]),
            ("13062500", 21, 43, None, [9.5, 10.5, 11.5, 13.0], [1372.0, 1614.0, 1970.0, 2330.0, 3290.0, 5426.0, 7388.0]),
            ("13077000", 24, 50, None, [8.9, 9.5, None, None], [276.0, 283.0, 312.0, 3190.0, 9640.0, 11700.0, 14100.0]),
            ("13081500", 28, 57, None, [10.2, 11.5, None, None], [373.6, 398.0, 435.0, 3290.0, 7790.0, 9250.0, 11600.0]),
            ("13090500", 33, 68, None, None, [311.6, 329.0, 404.0, 503.0, 594.0, 2028.0, 3360.0]),
            ("13154500", 38, 81, None, None, [5720.0, 5840.0, 6070.0, 6420.0, 6960.0, 8020.0, 8889.5]),
            ("13171500", 43, 90, None, None, None),
            ("13213100", 49, 108, None, None, [5539.0, 6230.0, 7160.0, 7920.0, 8750.0, 11200.0, 13300.0]),
            ("13269000", 52, 113, None, [11.5, 12.0, 13.5, 14.5], [7446.0, 8304.0, 9230.0, 10200.0, 12600.0, 20600.0, 25800.0]),
            ("13334300", 67, 143, [3.34, 3.44, 3.79, 4.68, 6.73, 9.84, 11.14], [19.0, 20.0, 23.0, 24.0], None),
            ("13344550", 75, 160, None, None, None),
        ],
    },
    {
        "key": "columbia",
        "label": "Columbia",
        "short": "Col.",
        "line1": (62, 27, "6566655444545534655005545655454435465666643423222232544543452333211222217012211344434344434544434454665546434"),
        "states1": "AAAAAAAAAAAAAAAAAAAAAA//////////BgAAAAIQAAAEAAAAAhAAAAQAAAACEAAABAAAAAIQAACEAAAAAhAAAHwAAAACEAAAAAAAAAIQAAAAAAAAAhAAAAAAAAACCAAAAAAAAAIEAAAAAAAAAgQAAAAAAAACBgAAAAAAAAICAAAAAAAAAgEAAAAAAAACAIAAAAAAAAIAwAAAAAAAAgBAAIAAAAACADwAgAAAAAIADACAAAAAAgAIAOAAAAACABgAXAAAAAIAEABDAAAAAQAYAEEAAP//gAgAQYAT4ADAEABBj24AAMASAEDxgAAAQBUAQAAAAABACYBAAAAAAIAAgA",
        "counties1": "AAAAAAAAAAAAAAAAAAAAAA//////////BgAgCJsQM4AHADAIkxAQgAT/4AiLEHDABIDwCIvwQGPH/9AIihAgPj/ASAiKHGAQA+DFuJ4+QR8D4IPdk/LPmP/AgzvyaficAX+GKCIkEJT+QMxIIiQf9nPBacgi58ZREWIeCCOiZVATMwYP/iE3fB6PgghD4J8khMPzOEI/2CT//hM/wiBwZo/hH/+6ID+TiAEDo+fg/RGP/wMmpnOJEf8iASya/BkfXCIBGFrwETZLI/8YWcAZ7oniAf//wAjZ/yIHwGFAEPebv/5A4MATDo176nCQQD8En/46EZDAOIabhnMWGOAQgg",
        "line2": (125, 54, "0564546667666554455434546544455525434665545710056464545466554565454546444423454546666565667664443343224232221232234123546435465644424434653223243413232100220232121232107071112222111233444443444334444443443465444444334344545466666564544456434345"),
        "states2": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB///////////////////8AIAAAAAAAAAAEAQAAAAAAABgAAAAAAAAABAEAAAAAAAAEAAAAAAAAAAQBAAAAAAAADAAAAAAAAAAEAQAAAAAAADAAAAAAAAAABAEAAAAAAAAgAAAAAAAAAAQBAAAAAAAAEAAAAAAAAAAEAQAAAAAAABAAAAAAAAAABAEAAAAAAAAQAAAAAAAAAAQBAAAAAACAEAAAAAAAAAAEAQAAAAAAcCAAAAAAAAAABAEAAAAAAA/gAAAAAAAAAAQBAAAAAAAAAAAAAAAAAAAEAQAAAAAAAAAAAAAAAAAABAEAAAAAAAAAAAAAAAAAAAQBAAAAAAAAAAAAAAAAAAAEAQAAAAAAAAAAAAAAAAAABACAAAAAAAAAAAAAAAAAAAQAQAAAAAAAAAAAAAAAAAAEAEAAAAAAAAAAAAAAAAAABAAgAAAAAAAAAAAAAAAAAAwAEAAAAAAAAAAAAAAAAAAIABAAAAAAAAAAAAAAAAAACAAwAAAAAAAAAAAAAAAAAAgAGAAAAAAAAAAAAAAAAAAIADAAAAAAAAAAAAAAAAAACAAYAAAAAAAAAAAAAAAAAAgABgAAAAAAAAAAAAAAAAAIAAMAAAAAAAAAAAAAAAAACAAAgAAAAAAAAAAAAAAAAAgAAMAAAAAAAAAAAAAAAAAIAABAAAAAAAAAAAAAAAAACAAAIAAAAAAAAAAAAAAAAAgAABAAAACAAAAAAAAAAAAIAAAQAAAAgAAAAAAAAAAACAAAHAAAAIAAAAAAAAAAAAgAAAYAAACAAAAAAAAAAAAIAAAH4AAAgAAAAAAAAAAACAAAACAAAIAAAAAAAAAAAAgAAABAAACAAAAAAAAAAAAIAAAAQAAAgAAAAAAAAAAACAAAAEAAAIAAAAAAAAAAAAgAAACAAADnAAAAAAAAAAAEAAAAgAAAXIAAAAAAAAAABAAAAIAAAEB4AAAAAAAAAAIAAAGAAAAgDgAAAAAAAAAEAAABgAAAIAIAAAAAAAAABAAAAIAAAEADAAAAAAH///4AAADAAABAAwAAAAB/AAACAAAAQAAAQAEAAAABgAAAAYAAAIAAACABAAADHgAAAABgAAEAAAAgAQB+DfgAAAAAIAAAhAAAIAHBg7AAAAAAABAAAY4AACAA+wBAAAAAAAAQAAGZAAAgABwAAAAAAAAAIAAA8QAAIAAAAAAAAAAAACAAAEEAACAAAAAAAAAAAABAAAABgAAgAAAAAAAAAAAAQAAAAIAAIAAAAAAAAAAAAIAAAACAAA",
        "counties2": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB////4Af////////////8AMAAAH/4AQICEAQACCAAAAAgAAAQAAECAhAEABgcAAAAGAAAGAABAwYcBAAQGgAAADQAAAgAAQMMFAQACAIAAADGAAAIAAEBCBQEAAgCAAAAg///8AABAQ4UBAB4AwAAAEYAAHAAAQECFAQAQADAAABGAAG4AAECAif8AEAAQDwARwABiAABAgIgBAAgAGAiAE6AAQgAAQICIAQAIAAgIcC4//+IAAEBAiAEACAAP+Ax2MAAhgABAQIgBIDgABAADhRAAMEAAQECIAdAgAAYAAAKYADBhD0CAiAGQIAAD/wAG2ABgM7nBgfgFCCAGAMAABMgAQBpAwwEP6whgDQDAAARoAIAOA9uBCCmOoP0BgP/8eACAAgS33wg4wz+AgYAAAJAAQAQEgn0ICMABgIHAAACf/8AcDIAICAhgAQDCQAADEABAMAiACAgIMAEAQkAB/hAAQCAYgAgICBAB5/444QwQAKBgMIAICAgwAGQSBj8PEAEgQCCACAgIH4BmEwEBAeACGGPggAgI+DDgYhEAAQEgBA4+AIAID4gYMHIRAAEDOAID7ACACAgIBhgSEQABAx4CAPwA///4CAMPEREAAQcBeQAMAIAQCAgAhtcZ4AE9gN8ADACAEAwIAEI+CCAB+IAHgAwAgBAL+ABBgAggABBAAkAMAIAQCAgAIYAMIIAQYAQ+BA+AEAgP//EADCCAEDgEAgYIABAICAARABw8///ePgEGCB/gCAgAHQAUBIBf/8IB/C//wAgIAAcA8wSAQAACAAbYAI+ICAAH/4EHgEAABAADiAe4SHgAD2EBAYBAAAQAAgQI6C+QAfjCAQGAQAAGAAIECIw4GA4AwgEBgP///gACBBCGeAwQAMEBA4f/BAQAAgQQgoj7kACBAQbvoAQEAAIEIMKEg2AAgIH4X+AEBAACAsBihJsAAIEHCEB4BAQAAgEAIoa8AAGBhDwgRgQEAAIBgCKEsAABgIQkQEIED//+AIAiguAAAIGMZEBBfAgAAgH///6gAADAcMJAQcQIAAJ/ACADgAAAQHeCQEEECAADkAA8AYAAAIDdw3/5BAwCDhAALABgAAEDmGcgxwR+B/QQAGgAIAAAhgAoIcWFhbkEEABIABAAAY4AGCBj94TQhBwARAAQAAGbABAgwJyECEQGAEQAMAAN8QAQIYD/5AmEAgPGACAABkEAHCH44BQRBAICAgBgAAYAgARBh4AUIQQCHgMAQAACAIAEQIeAHCEGAhABAPgAAQCABA",
        "gauges": [
            ("12323233", 1, 3, None, [None, 8.7, None, None], [4.11, 4.77, 5.97, 7.52, 11.7, 18.86, 26.58]),
            ("12324200", 4, 12, None, [5.0, 6.0, None, None], [61.32, 83.96, 131.0, 177.0, 218.0, 268.0, 400.6]),
            ("12331800", 8, 20, None, [7.0, 8.0, 10.0, 11.5], [217.0, 244.0, 410.0, 505.0, 628.0, 844.0, 1210.0]),
            ("12340500", 11, 27, None, [7.0, 7.5, 11.0, 13.0], [782.1, 897.2, 1130.0, 1470.0, 2690.0, 5508.0, 7358.0]),
            ("12354500", 19, 43, None, [18.0, 19.0, 21.0, 22.0], [1844.0, 2084.0, 2430.0, 3050.0, 6700.0, 13800.0, 17900.0]),
            ("12389000", 22, 49, None, [15.0, 16.0, 18.0, 19.5], [7090.0, 7434.0, 8480.0, 11100.0, 18600.0, 31260.0, 40940.0]),
            ("12391950", 29, 66, None, None, [5112.0, 6010.0, 8390.0, 12800.0, 22200.0, 36500.0, 46800.0]),
            ("12395500", 34, 78, None, None, [7791.0, 8941.0, 11700.0, 18050.0, 24200.0, 35960.0, 43700.0]),
            ("12396500", 39, 89, [83.94, 84.75, 86.11, 87.69, 89.76, 93.06, 95.49], None, None),
            ("12399500", 42, 96, [92.24, 93.43, 95.86, 98.83, 102.11, 105.43, 107.63], None, None),
            ("12472800", 72, 168, [8.32, 9.49, 10.92, 13.36, 16.2, 18.35, 19.4], None, None),
            ("14105700", 91, 206, None, None, [86400.0, 92000.0, 106000.0, 128000.0, 158000.0, 212800.0, 242900.0]),
            ("14128870", 96, 216, [7.84, 8.53, 11.48, 12.89, 16.13, 18.83, 20.75], None, None),
        ],
    },
    {
        "key": "willamette",
        "label": "Willamette",
        "short": "Will.",
        "line1": (37, 30, "544666554554466657567057576605671706665"),
        "states1": "AAAQAQP8z4AAABABzwMAAAAAEAB8AAAAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAgAAAAAAAAACAAAAAAAAAAIAAAAAAAAAAgAAAAAAAAACAAAAAAAAAAIAAAAAAAAAAgAAAAAAAAACAAAAAAAAAAIAAAAAAAAAAgAAAAAAAAACAAAAAAAAAAIAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAgAAAAAAAAACAAAAAAAAAAIAAAAAAAAAAgAAAAAAAAAEAAAAAAAAAAQAAAAAAAA",
        "counties1": "AAAQzwn870IAABBjzxOEQwAAEEM9EMZAAAAQwf+QTEAAABD5wFCIQAAAII8AUIhAAAAnjwBxiGAAACQNAIBkMAAAJ/0AQD/wAAA+CICACB8AACIIfMAECAAAIhA/wAQIAAAiCcD//ggAACP+P4ACCAAAQRgAgAYIAABBMACAfAgAAEEgAIDECAAAQyAA/4foAABGEACBACgAAH/zn4EAOAAAQBzggQAIAABAAACBgAgAAEAAAYCACAAATgABAOAfAABxAAMAPBAAAEDAAgAHEAAAgDACAAEQAACAEAIAAfAAAPgQA///4AAAiB8ECAAgAAEEAfwIACAAAQQABggAIA",
        "line2": (74, 61, "455444666666456554545654464475656656766567670566754767064667050560571070006756665457"),
        "states2": "AAAAAAIAAAIAAP/gBo8AAAAAAAACAAACAAPw8Bh4AAAAAAAAAgAAAwAMABvgAAAAAAAAAAIAAAHgOAAMAAAAAAAAAAAEAAAAPuAAAAAAAAAAAAAABAAAAAOAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAA",
        "counties2": "AAAAAAIA8D4AgP/gDf8QBAAAAAACAIASAIPhcDDwEAQAAAAAAgBgE4COAR/AIBAEAAAAAAIAGAj8ugEMQBAQBwAAAAAEADAEP+IBAGAQEAAAAAAABABAAgODAwAwCCAAAAAAAAQAQAIAAQIAEDggAAAAAAAEAIAC//+CABBwIAAAAAAAAgD/w4AAQgAwQCAAAAAAAAQAwGIAACIAIEAgAAAAAAAEAMA+AAAiAECAIAAAAAAABABAOAAAIgGAgCAAAAAAAAQAQD4AAD4BAIA8AAAAAAACH8BiAAAwAYBABAAAAAAAAhAAQgAAYABgQAQAAAAAAAIQACIAACAAGCAHAAAAAAACEABiAAAgAATgAQAAAAAABB//wQAAEAAH//8AAAAAAAf4AICAAGAAAEABAAAAAAAECABAQACAAABAAf8AAAAABAgAwCAAgAAAIABAAAAAAAQIAYAYAMAAACAAQAAAAAAECAMAD//gAAAgAEAAAAAACAgDAAAAYAAAMABAAAAAAAgIAYAAAP////gAQAAAAAAICAEH4ABAAAAQAEAAAAAACAwDmD9wgAAAEABAAAAAAAgP/+AA34AAABAAQAAAAAAIAgGAAACAAAAQAEAAAAAACAIDAAAAgAAAEABAAAAAAAgCAgAAAIAAABAAQAAAAAAIAgQAAACAAB/wAEAAAAAACAIEAAAAgAAQEABAAAAAABACAgAAAYAA8BAAQAAAAAAQDgIAAAGAAIAf4EAAAAAAEAgCAAAB//+AADxAAAAAABAYBAAAAIACAAAEQAAAAAAQMAQAAACAAgAABEAAAAAAH//+DwAAgAIAAAfAAAAAABAAAhjD/8ACAAAAQAAAAAAQAAPwPADAAgAAAEAAAAAAEAAAAAAAwAIAAABAAAAAABAAAAAAAEADgAAAQAAAAAAQAAAAAABAAIAAAEAAAAAAIAAAAAAAwACAAABAAAAAACAAAAAAAIAAgAAAQAAAAAAgAAAAAACAAIAAAEAAAAAAIDwAAAABAAD4AAH/AAAAACBCAAAAAwAACAABAAAAAAA/gQAAAAYAAA/wAQAAAAAAIACAAAAEAAAAEAEAAAAAACAAeAAABAAAAB4BAAAAAAAgAA8AAAQAAAACAQAAAAAAQAABAAAEAAAAAgEAAAAAAEAAAQAABAAAAAP/AAAAAABAAAEAAAQAAAAABAAAAAAAf8ABAAAH//////wAAAAAAEBAAQAAGABAAAAEAAAAAACAQAH+ACAAQAAABAAAAAAAgGAAAgAgAEAAAAQAAAAAAIAgAAIAIABAAAAEAAAAAAEAMAAD//AAQAAABAAAAAABABAAAAAQAEAAAAQAAAAAAgAQAAAACABAAAAEAA",
        "gauges": [
            ("14144790", 3, 7, [4.7, 4.74, 4.87, 5.08, 5.94, 6.46, 7.0], None, None),
            ("14145110", 6, 12, [1223.64, 1223.71, 1223.96, 1224.62, 1225.49, 1226.23, 1227.16], None, None),
            ("14152000", 11, 23, None, [9.4, 10.0, 13.0, 15.0], [1780.0, 1910.0, 2210.0, 2830.0, 4100.0, 6457.0, 9205.5]),
            ("14166000", 16, 34, None, [10.8, 14.0, 16.0, 17.0], [3871.5, 4110.0, 5010.0, 6750.0, 11100.0, 20800.0, 26600.0]),
            ("14171600", 20, 41, None, [26.0, 30.0, 33.0, 36.0], [4074.0, 4364.0, 5410.0, 7870.0, 13500.0, 24560.0, 34080.0]),
            ("14191000", 26, 55, None, [21.2, 28.0, 30.0, 32.0], [6362.0, 6690.0, 8160.0, 14000.0, 25500.0, 45860.0, 62120.0]),
            ("14197900", 32, 68, None, None, [6346.0, 6840.0, 8800.0, 15900.0, 30100.0, 54560.0, 70920.0]),
            ("14207740", 36, 76, [54.07, 54.6, 55.67, 56.07, 56.88, 58.44, 59.76], [62.0, 64.0, 65.0, 67.0], None),
        ],
    },
    {
        "key": "sacramento",
        "label": "Sacramento",
        "short": "Sac.",
        "line1": (38, 4, "666444322352444423441212311222222122103122233"),
        "states1": "AAIAAABAAAAAAgAAAEAAAAAEAAAAQAAAAAQAAABAAAAABAAAAEAAAAAEAAAAQAAAAAQAAABAAAAACAAAAEAAAAAIAAAAQAAAABAAAABAAAAAEAAAAEAAAAAIAAAAQAAAAAgAAABAAAAABAAAAEAAAAACAAAAQAAAAAEAAABAAAAAAQAAAEAAAAABAAAAQAAAAAEAAABAAAAAAIAAAEAAAAAAgAAAQAAAAACAAABAAAAAAIAAAEAAAAAAgAAAIAAAAABAAAAQAAAAACAAAAgAAAAAIAAABAAAAAAQAAACAAAAAAgAAAEAAAAABAAAAIAAAAAEAAAAYAAAAAYAAAAQAA",
        "counties1": "AARAAIBCAAQAA8AAgEIABAAEYcCAQgAEAAQz///CAAQABD5AgEIABAAEdsCAQ+AHAARggMBCP8QACEGAQEIARAAIQQBAQgB8ABBDAEBCAAgAECZ/4EIAEAAIJ+CsQgAQAAQkAZNCABAABCYBgMIAIAAD/geAQ//gAAED/sjBACAAAIPIX8OAIAAAgwgwT4AgAACHDHffACAAAIX9uF0AQAAAhYdn+MDAAACEz1h4Z/8AAIRF/c5/gAAAhn22JIMAAAB/YyBcwQAAACHj4M5BgAAAENc3zkDAAAAQ2x//wEAAAA97PvmAoAAABfPZjMEwAAAEfxkGcxAAAAR/GgIeCA",
        "line2": (76, 9, "76566654254342442222232553245434542224424443412022102230311222121222232222121122110321032022314225323"),
        "states2": "AAAAEAAAAAAAABAAAAAAAAAAAAgAAAAAAAAQAAAAAAAAAAAIAAAAAAAAEAAAAAAAAAAACAAAAAAAABAAAAAAAAAAADAAAAAAAAAQAAAAAAAAAAAQAAAAAAAAEAAAAAAAAAAAEAAAAAAAABAAAAAAAAAAACAAAAAAAAAQAAAAAAAAAAAgAAAAAAAAEAAAAAAAAAAAIAAAAAAAABAAAAAAAAAAABAAAAAAAAAQAAAAAAAAAAAQAAAAAAAAEAAAAAAAAAAAEAAAAAAAABAAAAAAAAAAACAAAAAAAAAQAAAAAAAAAAAgAAAAAAAAEAAAAAAAAAAAQAAAAAAAABAAAAAAAAAAAEAAAAAAAAAQAAAAAAAAAACAAAAAAAAAEAAAAAAAAAAAgAAAAAAAABAAAAAAAAAAAQAAAAAAAAAQAAAAAAAAAAEAAAAAAAAAEAAAAAAAAAABAAAAAAAAABAAAAAAAAAAAIAAAAAAAAAQAAAAAAAAAACAAAAAAAAAEAAAAAAAAAAAgAAAAAAAABAAAAAAAAAAAGAAAAAAAAAQAAAAAAAAAAAYAAAAAAAAEAAAAAAAAAAABAAAAAAAABAAAAAAAAAAAAQAAAAAAAAQAAAAAAAAAAACAAAAAAAAEAAAAAAAAAAAAgAAAAAAABAAAAAAAAAAAAEAAAAAAAAQAAAAAAAAAAABAAAAAAAAEAAAAAAAAAAAAIAAAAAAABAAAAAAAAAAAACAAAAAAAAQAAAAAAAAAAAAgAAAAAAAEAAAAAAAAAAAAIAAAAAAABAAAAAAAAAAAAEAAAAAAAAQAAAAAAAAAAABAAAAAAAAEAAAAAAAAAAAAQAAAAAAABAAAAAAAAAAAAEAAAAAAAAQAAAAAAAAAAAAgAAAAAAAEAAAAAAAAAAAAIAAAAAAABAAAAAAAAAAAABAAAAAAAAQAAAAAAAAAAAAQAAAAAAAEAAAAAAAAAAAAEAAAAAAABAAAAAAAAAAAABAAAAAAAAIAAAAAAAAAAAAQAAAAAAABAAAAAAAAAAAACAAAAAAAAIAAAAAAAAAAAAQAAAAAAABAAAAAAAAAAAACAAAAAAAAMAAAAAAAAAAAAQAAAAAAAAgAAAAAAAAAAAEAAAAAAAAEAAAAAAAAAAAAgAAAAAAAAgAAAAAAAAAAAEAAAAAAAAEAAAAAAAAAAAAgAAAAAAAAgAAAAAAAAAAAEAAAAAAAAEAAAAAAAAAAAAgAAAAAAAAgAAAAAAAAAAAIAAAAAAAAEAAAAAAAAAAABAAAAAAAAAgAAAAAAAAAAAQAAAAAAAAGAAAAAAAAAAAEAAAAAAAAAwAAAAAAAAAACAAAAAAAAACAAAAAAAAAAA8AAAAAAAAAQAAAA",
        "counties2": "AAAACEAAAACAABAIAAAAEAAAAAggAAAAgAAQCAAAABAAAAAP0AAAAIAAEAgAAAAQAAAACHAAAACAABAIAAAAEAAAADAMAGAAgAAQCAAAABAAAAAQBACgAIAAEAgAAAAQAAAAEAYBYACAABAIAAAAEAAAACACDn/////wCAAAABAAAAAgBwggAEAAEAgAAAAQAAAAIAboQABAABAIAAAAEAAAABACGEAAQAAQCAAAAB8AAAAQHgCAAEAAEA/4AAAQAAAAEBwAgABAABAMCAAAEAAAACAYAIAAYAAQDA//8BAAAAAgCACAACAAEAwAABAQAAAAQAgBAAAgABAIAAAQEAAAAEAIAgAAIAAQCAAAH/AAAACACAMAACAAEAgAAACAAAAAgAgDAAAgABAIAAABgAAAAQAIDgAAIAAQCAAAAYAAAAEACBgB//wAEAgAAAEAAAABAAg/f4CEABAIAAADAAAAAIAIPYAARHAQCAAAAgAAAACACDAAAEaYEAgAAAIAAAAAQAgQAADDBBAIAAAGAAAAADAIEAABwAMQCAAABAAAAAAICBgAA0AB0AgAAAQAAAAACAgIAARAAFAIAAAIAAAAAA//+AAMgABwD///+AAAAAAEAAgAOIAAMAIAAAQAAAAAAgAIAPjAADADAAAEAAAAAAEAD//AYIBwAQAABAAAAAAAgAgAwCHB8AGAAAQAAAAAAIAIAEARf/ADgAAEAAAAAACABABACgAQDoAABAAAAAAAgAcAQAYAEHmAAAQAAAAAAQA9AGA8OBHJAAAMAAAAAAEAIQAgRvfxkQAAGAAAAAABACP/4E8AEJEAABAAAAAAAQAyACeQABCggAAgAAAAAAEAEwA/ID/xwEAAIAAAAAAAgBHAZiDAEwAgACAAAAAAAIAgYEYhgB7AMABv/wAAAABAICBCIgAfwBgf/AAAAAAAQCAgInYAcHw//8AAAAAAAEAwEBPM4/AcYAwAAAAAAABAEB/zg7QMEEAIAAAAAAAAQAgfGoYIBhBACAAAAAAAACP+HAkEAAsQYAQAAAAAAAAeAzQHCAARkCACAAAAAAAACAHiB/gAIFggAwAAAAAAAAQAwgYMAGDoIAEAAAAAAAACAIIDBACgmCAAgAAAAAAAAgDBewfHIEggAEAAAAAAAAEAQYsDP+AmIAAgAAAAAAAAgCENAg87Q+AAUAAAAAAAAEAxhQIYbsGAAJgAAAAAAAB4E4YGMICAwACIAAAAAAAAJhoCmuCAwGABBAAAAAAAACHaA2OBAMAwAgIAAAAAAAAQfgUBAQBgHAQBAAAAAAAAEDz+AQIAGA4IAQAAAAAAACAfmgGGAAwDCACAAAAAAAAoEAIBRAAEAZAAQA",
        "gauges": [
            ("11348500", 5, 12, None, [7.5, 8.5, 9.0, 10.0], [0.44, 0.95, 2.93, 44.1, 147.0, 462.6, 653.0]),
            ("11355010", 13, 28, None, None, [895.0, 939.4, 1020.0, 1150.0, 1570.0, 2840.0, 3336.0]),
            ("11370500", 21, 47, None, None, [3120.0, 3260.0, 4010.0, 6150.0, 10100.0, 13200.0, 14300.0]),
            ("11377100", 24, 55, None, [22.0, 27.0, 29.5, 31.0], [4240.0, 4388.0, 5950.0, 8770.0, 12600.0, 15700.0, 23700.0]),
            ("11389500", 33, 74, None, [63.0, 70.0, 72.0, 73.0], [3460.0, 3724.0, 5060.0, 7660.0, 11400.0, 22400.0, 34080.0]),
            ("11425500", 38, 83, None, [None, 41.3, 45.0, 46.0], [6301.5, 6970.0, 9025.0, 15000.0, 23025.0, 41400.0, 55285.0]),
            ("11447650", 41, 90, None, None, None),
        ],
    },
    {
        "key": "sanjoaquin",
        "label": "San Joaquin",
        "short": "S. Joaq.",
        "line1": (54, 9, "012223432322224243642242523334344343454656565645456545565654665474665665545442444"),
        "states1": "AAAAAAAAAAIAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAGAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAACAAAAAAAAAAIAAAAAAAAAA",
        "counties1": "ACgBgEAA8AaH+AGAgAA4A/joAMGAAAgAAAgA4QAACAAACACyAAAMAIAIAKwAAMYAwAwAnAABcgB4HACMBYYaAA3sBoYK+A4ABwwfgzAAF4CACDAA4AAggMAIYADwAEDAYAjAA2AAgGAgDYAMIAEAsDH/ADAwAQEcf4IAwBACAg9AAgMAGA4EBkABAQAIEAgCYAECAAwgCAMwAgQABEAYAHACCAACgBAAiAPQAAcAEAAGASAAPADgAAGAIADAAMAAAMAQAwABgACAQjAHAAYAAMA34A8ADAAAMHwwEYAIAAAI+BAggBgAAA+YCCBB8AAACAwGQG8AAAAIAgGAOAAAPw",
        "line2": (109, 19, "7111222224343413233233222222334432563522032434234323323443444344434425344255246654567565654665644654445656564445646647546565554656635664745665756765654545554644442234444446"),
        "states2": "AAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAwAAAAAAAAAAAAAAAAAAAADAAAAAAAAAAAAAAAAAAAAAMAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAA",
        "counties2": "AAAEQAADAAAQAAAAcAAAGAAACIAAAQAAMAAAABYAAAQAAB/AAAGAACAAAAAJgAACAfPswAAAgABgAAAAAIAAAfeNGIAAAMAAQAAAAABAAAAcAODAAACgAMAAAAAAQAAAAAAAgAAAoAGAAAAAAEAAAAAAAIAAAJAGAAAAAABAAAAAAADAAACIAgAAAAAAQAAAAAAAQAAAhAYAAAAAADAAAIAAAEAAAIIEAAAAAEAYAABAAADAAACBCAAAAACgBAAAYAAAwAAAgRAAAAADLAwAACAAAGAAAICgAAAABh8MAAAcAADAAACAQAACAAwCiAAAA4AHQAAAgCAANYAYAIQAAABAHEAAAIAQADhuYABIAAAAYOBAAAaACADgG4AA8AAAACcAQAB5gAYPAAAAATeAAAAYAEABwAADCAAAAAIIwACAAABABwAAAJQAAAAEACAAgAAAQAgAAAB8AAAACAAgAEAAAEAQAAAANgAAABAAIAAgAABAIAAAADAAAAAgABAAEAAAQEAAAAHYAAAAQAAQABAAAECAAAAHCAAAAIAAGAAIAABBgAAAPAwAAAEAAC8ABAAAcwAAAPAEAAABAABBgAYAAB4AAAPABgAAAQAAgMACA//8AAAOAAIAAAMAAQBwA/QACAAAOAADAAAGAAIAbxwIAAgAAOAAAgAABAAEAAwQAAAEAAOAAAMAAHwACAAYMAAABAAGAAABAACAABAAECAAAAIABgAAAYABAAAgABggAAACAAIAAACAAgAAQAAIEAAAAwAEAAAAwAQAAMAAChAAAAMACAAAAEAIAACAAAUIAAAGABAAAABgGAAAgAABDAAABAAgAAAAIDAAAIAAAAoAAAYAYAAAABBgAACAAAF5gAACAEAAAAAMwAAAgAABwMAAAgCAAAAAA4AAAIAAAQBAAAH5AAAAAB8AAAEAAAAAMAABDgAAAAfgAAAmAAAAAAwAAAQAAAAcAAAA+AAAAAAHAAAMAAAAcAAAANAAAAAAAYAADAAAAMAAAADAAAAAAADAAAYAAAMAAAABgAAAAAAAIAAMAAAEAAAABwAAAACAABAABAAACgAAAB4AAAAAgAAQBAwAABIAAAAwAAAAAEAACA4IAAAZAAAAIAAAAAAwAAQT/AAAeIAAAGAAAAAADAADsAQAAICAAABAAAAAAAMAP+ACAAEAQAAAwAAAAAABAGJAAQACAIAAAIAAAAAAAIBBAAEABACAAA+AAAAAAACPgQAAgAwAYAAzAAAAAAAA+ADAAGAIABAHwAAAAAAAAIAAIAAYEAAYeAAAAAAAAACAABgADiAAHaAAAAAAAAAAgAAEAANAAAMAAAAAAAf/AEAABAAAgAAAAAAAAAAEAA",
        "gauges": [
            ("11224000", 3, 6, None, None, [7.34, 10.2, 18.68, 39.75, 143.0, 345.0, 669.35]),
            ("11251000", 27, 50, None, None, [222.0, 272.4, 395.0, 449.0, 649.0, 1680.0, 6466.0]),
            ("11274000", 54, 114, None, [63.0, 69.4, 70.7, 71.7], [44.5, 140.4, 278.0, 580.0, 1170.0, 3856.0, 12680.0]),
            ("11303500", 64, 135, None, [24.5, 29.0, 32.0, 37.3], [322.6, 554.0, 874.0, 1450.0, 2982.5, 7920.0, 22085.0]),
            ("11337190", 78, 164, None, None, None),
        ],
    },
    {
        "key": "colorado",
        "label": "Colorado",
        "short": "Colo.",
        "line1": (45, 1, "243434443253332342323423244643425444222221132241232"),
        "states1": "IAAIABAAAIAgAAgAEAAAgCAACAAQAAD/IAAIABAAAIAgAAgAEAAAgCAACAAQAACAIAAIABAAAIAQAAgAEAAAwAgACAAQAABABAAIABAAAEACAAgAEAAAQAEACAAQAABAAIAIABAAAEAAYAgAEAAAQAAwD///////AAgIABAAA/8ABAgAEAACAQACOAAQAAIBAAEgABAAAgEAAKAAEAACAQAAYAAQAAIBgAAgABAAAgGAADAAEAACAcAAEAAQAAYB/AAIABAABAB7ABAAEAAEAAEAMAAQAAQAB8AgABAABAAboDAAEAAEAAEQEAAQAAQAAB/wABAABAAAADAAEAAEAA",
        "counties1": "LPYIf1D8uf+sJgg+X9+v/+/n+PbQU/r/5yUP/9//8qr8ZQ/3/E////Z/CCSf+1Su//CIPJP99/9+wHhsl4+1//5gT//8vv/23qBP/9/nv//ZEcjAnffqd+yRDoEf///+/9EL/xL/BH97MQiGErUEdvMR////////nwkIwpCNE/+5hwmCkO/yteiDOwKf/n////+iApBf/vUQQOMCkEwb/xBAYsKX/fv//EBictx/NrVPwDIa0Hl7/3pAEg5f8fNt5kAeHlEf3/9///P70QS3/wGgMgzxGJ/tB3/+PfH/l/8bojo/PxuVrQESMiM5eff/AB/j/x/Zl/8AABoB9lCUvg",
        "line2": (91, 2, "22344434432444344323454332333233343232422444323321235452574434342225455354422212223221121332222322122432"),
        "states2": "BAAAAABAAAABAAAAAABAAAQAAAAAQAAAAQAAAAAAQAAEAAAAAEAAAAEAAAAAAEAABAAAAABAAAABAAAAAABAAAQAAAAAQAAAAQAAAAAAQAAEAAAAAEAAAAEAAAAAAH//BAAAAABAAAABAAAAAABAAAQAAAAAQAAAAQAAAAAAQAAEAAAAAEAAAAEAAAAAAEAABAAAAABAAAABAAAAAABAAAQAAAAAQAAAAQAAAAAAQAAEAAAAAEAAAAEAAAAAAEAABAAAAABAAAABAAAAAABAAAQAAAAAQAAAAQAAAAAAQAACAAAAAEAAAAEAAAAAAGAAAQAAAABAAAABAAAAAABgAACAAAAAQAAAAQAAAAAAYAAAQAAAAEAAAAEAAAAAACAAACAAAABAAAABAAAAAAAgAAAQAAAAQAAAAQAAAAAAIAAADAAAAEAAAAEAAAAAACAAAAYAAABAAAABAAAAAAAgAAABAAAAQAAAAQAAAAAAIAAAAIAAAEAAAAEAAAAAACAAAABAAABAAAABAAAAAAAgAAAAIAAAQAAAAQAAAAAAIAAAABAAAEAAAAEAAAAAACAAAAAIAABAAAABAAAAAAAgAAAABAAAf/////////////8AAAIAAEAAAAEAAAAACAAAAAABAABAAAABAAAAAAgAAAAAAIAAQAAAAQAAAAAP//4AAABAAEAAAAEAAAAACAACAAAAIABAAAABAAAAAAgAAgAAABAHQAAAAQAAAAAIAAIAAAAMBIAAAAEAAAAACAACAAAABgQAAAABAAAAAAgAAgAAAAEEAAAAAQAAAAAIAAIAAAAAhgAAAAEAAAAACAACAAAAAEYAAAABAAAAAAgAAgAAAAAmAAAAAQAAAAAIAAIAAAAAFgAAAAEAAAAACAACwAAAAA4AAAABAAAAAAgAAkAAAAAEAAAAAQAAAAAIAAJAAAAABAAAAAEAAAAACAACQAAAAAIAAAABAAAAAAgAAkAAAAADAAAAAQAAAAAYAAM/AAAAAQAAAAEAAAAAGAABAIAAAACAAAABAAAAABAAAHxAAAABAAAAAQAAAAAQAAAz/gAAAQAAAAEAAAAAEAAADAIAAAMAAAABAAAAABAAAAADgAACAAAAAQAAAAAQAAAAAEAAAgAAAAEAAAAAEAAAADcgAAIAAAABAAAAABAAAACTEAAEAAAAAQAAAAAQAAABw4gABAAAAAEAAAAAEAAAAAYIAAQAAAABAAAAABAAAAAGBAACAAAAAQAAAAAQAAAAAwQAAgAAAAEAAAAAEAAAAAICA/4AAAABAAAAABAAAAAAA/wIAAAAAQAAAAAQAAAAAAAADAAAAAEAAAAAEAAAAAAAAAOAAAABAAAAABAAAA",
        "counties2": "BEAfKABACN8hACQggIJ//wRABiwAQAu4IQBCMIfCQkYEQAQkAEAOyCEAQ/GEf///5EAMJABACGgh//LfBERCRDxACCf/wAgoIQAyCQREQkQMf/giAEAOKCEAcgn/xH//DCAIIgB////hA9+fYQRERPwwCCIAQAWh4X4Q7f8EREQE8AgiAEP5MEHgEF3/////feAQIgB+CT//ABDloRBEJP2gICIAQA8gQf//xyEQRCSHEC/+AEAEIIEA48YhEEQk/9/8AQBAB+CBA/fD/R///+aQwADAQARgwQxP4wUQREQGiEAAIEAIYIEQQaOHEGREDchgAB/AEEBBH8E/hBH///3IMAAQf/////DB4P//SSh/eBAAEEAzAHkAz+CEQCkomRAoABBAEgAhB8g/hH///5HIxAAQf///4f74GQfEJQigRYID8EAgAEECmBkERCU4TaMCAgBAIAGB/dYP/EQlLz9hggIAQEADAQdX/BxEP+hwkEICAHhABgH/1E8n/+Uk6S/iAgBP//4BBHRJwBAlP45oEgIAQIAMAQRf8YAQP+QcxAoCAECACAEIQhEAECkkMIYGAgBAgBgBCEIRABApJHECAgIAf/////////////+eAQED/8AgBEEAgCICCCCCgH8AggBAYARBAIAmAggggsHBAEIAQEAEQQCAJgIP//9GgIAyAEBABEEAgCYCCEkSxICAGgBBwARBAPhH/ghJEsSAgA4HRwAEQQCINBvoSRIogMAGBIQABEH/7/gYL///EIBAAwQEAARBACHcGGhJEv////+EBAAEQQAgl/54SRIMABAAxgQABGEAIJABT//+BgAQAGYGAAQhACCQAchJGwIAEAAmBcAEIR/gkADISRIDgBAAFgQwBCEQP5P9j//+zoAQAAwEEAQhEDD+BghJE3PgEAAEBB8EIfAzQgQ4SRNA//AABgQBhCEAP8IMSEkSQIgQAAIEAIQhACECDc///kCMEAADBACEMf/9AvcJJJM4hBAAAQQA9DEBBwKDCSSSB4QQAADMAYwxAQH/g////nhIMAABvAGEMQEAIMIKSJM3/j///wePx/EBACC/CkiSD4JwAAMEeEBxAQBggR9f/wAC2AADBABAdwEAQIEa6JIAAYQAAgQAIH8BAcCB8kiSADdv//7kAPDdA/8AgRJIkgCTGAQEnAiRiQIB/oEf//8Bw4QEBIQPiQn+AYKBEkiSAAYEBAeECAsJAgGDgRJIkgAGBAgCBAgFBQMHgn8f//8AAwQIAgQIAQWBPYJBEEkkAAICCHwECAEDgaGCQRBJJAAAA/+MB///A+/hg8Ef//8AAAAAAwQAAf8oIQBBEEkkAAAAAADEAAEBKCEAQRBJJA",
        "gauges": [
            ("09010500", 0, 1, None, [7.6, 8.0, 8.5, 9.0], [7.06, 7.82, 10.2, 16.2, 44.0, 147.6, 270.0]),
            ("09058000", 3, 6, None, [13.5, 15.0, 17.0, 18.0], [352.0, 377.0, 413.0, 620.0, 1000.0, 1326.0, 2504.0]),
            ("09095500", 9, 19, None, [12.0, 12.5, 13.5, 14.5], [1150.0, 1250.0, 1450.0, 1880.0, 2570.0, 5594.0, 10300.0]),
            ("09163500", 12, 24, None, [12.5, 15.0, 16.0, 17.0], [1852.0, 2070.0, 2440.0, 3000.0, 3920.0, 8056.0, 15500.0]),
            ("09328990", 17, 34, [3566.65, 3568.06, 3570.0, 3579.1, 3584.3, 3588.67, 3589.1], None, None),
            ("09380000", 22, 46, None, None, [7492.5, 7760.0, 8267.5, 9640.0, 11300.0, 12400.0, 17800.0]),
            ("09402500", 26, 53, None, None, [8000.0, 8334.0, 8980.0, 10300.0, 11800.0, 13500.0, 18300.0]),
            ("09404200", 32, 67, None, None, [8431.5, 8670.0, 9300.0, 10600.0, 12300.0, 13900.0, 18600.0]),
            ("09421500", 36, 76, None, None, [4684.0, 5820.0, 7610.0, 10300.0, 13700.0, 16400.0, 17600.0]),
            ("09422500", 40, 82, None, None, None),
            ("09429000", 45, 94, None, None, [358.75, 467.0, 662.0, 967.0, 1280.0, 1460.0, 1540.0]),
            ("09429495", 49, 100, None, None, None),
        ],
    },
    {
        "key": "coloradotx",
        "label": "Colorado (TX)",
        "short": "Colo. TX",
        "line1": (13, 1, "10001011210100121070100220222200200101101102200221222"),
        "states1": "AQAAAAAAAAQBAAAAAAAABAEAAAAAAAAEAQAAAAAAAAQBAAAAAAAABAEAAAAAAAAE/wAAAAAAAAQAAAAAAAAAAgAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAABwAAAAAAAEAc8AAAAAAAgBAIAAAAAAHgEAgAAAAABhAgBAAAAAAICCACAAAAABAGQAEAAAAAIAGAAQAAAABAAAAAgAAAAYAAAACAAAAGAAAAAIAAABgAA",
        "counties1": "4f////SS7/0hCSSJJJPZfSEJJIkn0k9dMf////y/S+URCSSRN7H8/xEJJJFj3seW/////9bIfKZkkiiSml30/nSSTpJrbyTzX//P8veNN5+Mknxf3o3924PSREl8d4n/gvJEySfnm9+EH//5Pzz8vmgGEI/z9f8qEAIQiJbn9y4MHx/4li69p5YREI/2/dz/YRMQhC3n08cg8//8Lr79PyBiBHfpm/e7IBIEXr9zUPsgf8RL/2VwiiBAJ/752My7IIAkR80k59zggBxEziM6YCCADERxVjmAGQAH//adcQAGAARESXSbAAAAAkRN5IwAAAACf/8nmAAAAAJEVr2gAA",
        "line2": (27, 2, "10101070010200302222012101010100020201271017000010612021203122203220000202020020027202713000101111720212210021212321222"),
        "states2": "AAIAAAAAAAAAAAAAAAAAEAACAAAAAAAAAAAAAAAAABAAAgAAAAAAAAAAAAAAAAAQAAIAAAAAAAAAAAAAAAAAEAACAAAAAAAAAAAAAAAAABAAAgAAAAAAAAAAAAAAAAAQAAIAAAAAAAAAAAAAAAAAEAACAAAAAAAAAAAAAAAAABAAAgAAAAAAAAAAAAAAAAAQAAIAAAAAAAAAAAAAAAAAEAACAAAAAAAAAAAAAAAAABAAAgAAAAAAAAAAAAAAAAAQAAIAAAAAAAAAAAAAAAAAEP/+AAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAQAAAAAAAAAAAAAAAAIAAAHMgAAAAAAAAAAAAAAEAAA+M+AAAAAAAAAAAAAABAAAIAAgAAAAAAAAAAAAAAMAAEAAGAAAAAAAAAAAAAAeAABAABgAAAAAAAAAAAAA4IAAQAAGAAAAAAAAAAAAAwBAAIAAAQAAAAAAAAAAAAwAMACAAACAAAAAAAAAAAAIAAwAgAAAQAAAAAAAAAAACAACA4AAACAAAAAAAAAAADAAAYIAAAAQAAAAAAAAAADAAABkAAAAEAAAAAAAAAABAAAAHAAAAAgAAAAAAAAAAgAAAAAAAAAIAAAAAAAAAAQAAAAAAAAACAAAAAAAAAAIAAAAAAAAAAgAAAAAAAAAMAAAAAAAAAAEAAAAAAAAAMAAAAAAAAAABAAAAAAAAAMAAAAAAAAAAAIAAAAAAAAMAAAAAAAAAAADAAAAAAAAMAAAAA",
        "counties2": "/AP////////+EEEEiP44EgQCAIIEEECCCBBBBPiD//IEAgCCBBBAgggQQQeWghASBAIAggQQQIIIMEEEEYIc8gQCAIIEEECCCCBBBBBCE5EEAgCCBBBAggg/8QQQfnARBgP/////////4I/8EE+QEQICAIIEEEECBDCCAhBAmBECAgCCBBBBAgIQggP/4P8xAgIAggQQQQICH4YBgCCD0gICAIIEEEECDAy5BuAgghwCAgCCBBBBAjYP4RhgP4YQAgP////////CDGDgMHCEGP/+QQQIQIIEwzBg4B/whBgwIEEECECCBEHoMCB8MIf4KCBBBAhAggRgyBMxmCDyCCwgQQQQQIIEIEQevggg3wcmIEEEEPiCBD2FGMMEEMMGI/////D/gwQyB+BBAwjB4iCAQQQQgP8EIwyAQYc+wL5AwEEEH+AhBMEwwCCZ4XCJQHBBBBAgIO+h4EDg4QGcmUAOQQQQICDycaBjEMGAhphABfEEECBggh8wLBOAgUGQQAjdBBAgYIIMENQMgQJAkEAIBQQQIECCDAuEMEEEYF9AEAP/////ggYOAkBPmFj0sCABwAEAQIID+AOgefCPxBhAAHABAED+PgwHIOHxCEQMQAAYAQBAR/4HzBHvnghEA4AACAEAQECDCfgbfAwIJAGAAAQBAEBAgxgYCmYKCCQAwAB8Af//wIIQCDRGG4w0AOADxwEAQECCGAzuRxHEFQEYAgEBAEBAgTQHgyPwZ/XiDAICAQBAf/+lzkEiOH81HAYCAgEAQBAI4zgz0gnQJQQBggMBAEAQCGAsHqIHCCUEAM4H////8AhwIhA+Agg/BABoBAAgAhAIyEJ4bsEMcQQAGAQAIB4f+IaBz083B5EEAAwEACAXAIWBgQ/0CQENBAAGBAAgEQCDQ0IEFACBAwQAAwQAIDH8hiQmDiQA/4IEAAGEgCAgg4gcFBMiAECEBAA+f+AgIIDfPBgQvgBAhAQAIAAgICCAeeN0INGAwIMEACAAGD///+GAw8BwbIOeBABAABggICFgwQQgsB//4IQAQAAGICAgYCIEEJA2Y4BEAEAAASAgIGB+CAkIZgwANACAAAGgICAg9hQGD0IIAAwAgAAAYCAgMYIyCAaDCAAGA4AAACAgID0BYzQMATAAAYIAAAAgICAmBoHiHAPAAABkAAAAH///4QkDgWIDAAAAHAAAABAgICCyBkCDggAAAAAAAAAIICAgwXQggMwAAAAAAAAACCAgIGDcMIBwAAAAAAAAAAggICAhhBCAIAAAAAAAAAAEICAg3gQfgMAAAAAAAAAABD///zMEcIMAAAAAAAAAAAIgICERh8CMAAAAAAAAAAADICAhEOnBsAAAAA",
        "gauges": [
            ("08117995", 4, 8, [-0.02, -0.01, 0.0, 0.25, 0.56, 0.78, 1.5], None, None),
            ("08121000", 7, 17, [3.04, 3.22, 3.38, 3.56, 4.05, 4.22, 4.36], [12.0, 15.0, 20.0, 26.0], None),
            ("08124000", 11, 26, [0.77, 0.77, 0.83, 1.01, 1.11, 1.2, 1.22], [8.0, 33.0, 35.0, 37.0], None),
            ("08136700", 16, 40, [3.58, 3.62, 3.68, 3.9, 4.31, 4.54, 4.63], [18.0, 40.0, 45.0, 50.0], None),
            ("08147000", 24, 56, [1.42, 1.67, 1.9, 2.09, 2.35, 2.96, 3.85], [25.0, 30.0, 34.0, 38.0], None),
            ("08158000", 36, 80, [10.98, 11.09, 11.36, 12.05, 13.0, 14.0, 14.45], [25.0, 33.0, 38.0, 42.0], None),
            ("08159500", 39, 91, [1.12, 1.18, 1.32, 1.55, 1.93, 2.36, 2.65], [10.0, 20.0, 23.0, 28.0], None),
            ("08161000", 43, 100, [9.14, 9.24, 9.39, 9.66, 10.13, 10.8, 11.59], [30.0, 34.0, 39.0, 43.0], None),
            ("08162000", 47, 108, [7.04, 7.21, 7.57, 7.97, 8.58, 9.84, 11.06], [20.0, 39.0, 41.0, 43.0], None),
            ("08162500", 50, 113, [2.13, 2.28, 2.54, 2.96, 3.52, 4.67, 6.52], [23.0, 44.0, 45.0, 46.0], None),
        ],
    },
    {
        "key": "gila",
        "label": "Gila",
        "short": "Gila",
        "line1": (63, 9, "333222324442223435556434445564544343255443444544456544434212454343434343524453"),
        "states1": "IAAAAAAACAAgAAAAAAAIABAAAAAAAAgACAAAAAAACAAQAAAAAAAIACAAAAAAAAgAYAAAAAAACABAAAAAAAAIAEAAAAAAAAgAQAAAAAAACABAAAAAAAAIAEAAAAAAAAgAgAAAAAAACAAAAAAAAAAIAAAAAAAAAAgAAAAAAAAACAAAAAAAAAAIAMAAAAAAAAgAQAAAAAAACABAAAAAAAAIAMAAAAAAAAgAAAAAAAAACAAAAAAAAAAIAAAAAAAAAAgA4AAAAAAACAAYAAAAAAAIAAcAAAAAAAgAAOAAAAAACAAAGAAAAAAIAAAHAAAAAAgAAADgAAAACAAAABgAAAAIHw",
        "counties1": "IAgACAgID/8gCAAPiAgIABgIAB5oCAgADjgAEBgICAARyAAQCAgIAOAIABwICAgAYA/h/A/4CABACBsEABgIAEAIBgIAGAgAQAgAAgAYeABACAADgBmIAEAIAAHAG4gA3ggAD8B1iAeT+AAIYcEIBBAIAgghAQgEEAgD+DMBD/+QCAIAFwEIAfAIAgAdAQgBQAgCAAkAiAFACAIAAQDIAMAIAgABAEwAAAgCAAEAbAAACAIAAQAvAwAP////ACme4AgAAAH/+JAYCAAAAQAIkAcIAAABAAiQAOgAAAEACFAAHAAAAQAIUAADAAABAAhQAADgAAEACHAAABgAAQAIHw",
        "line2": (126, 19, "33433312223223324444423222232343454554566654434234444545565645544542443443223545544345434345454454445454656444434434212222355444633443434434343443354243455434"),
        "states2": "DAAAAAAAAAAAAAAAAIAAAAQAAAAAAAAAAAAAAACAAAAEAAAAAAAAAAAAAAAAgAAABgAAAAAAAAAAAAAAAIAAAAOAAAAAAAAAAAAAAACAAAAAwAAAAAAAAAAAAAAAgAAAAEAAAAAAAAAAAAAAAIAAAABAAAAAAAAAAAAAAACAAAAAgAAAAAAAAAAAAAAAgAAAAwAAAAAAAAAAAAAAAIAAAAQAAAAAAAAAAAAAAACAAAAIAAAAAAAAAAAAAAAAgAAACAAAAAAAAAAAAAAAAIAAAAgAAAAAAAAAAAAAAACAAAAQAAAAAAAAAAAAAAAAgAAAIAAAAAAAAAAAAAAAAIAAACAAAAAAAAAAAAAAAACAAAAgAAAAAAAAAAAAAAAAgAAAEAAAAAAAAAAAAAAAAIAAABAAAAAAAAAAAAAAAACAAAAwAAAAAAAAAAAAAAAAgAAAIAAAAAAAAAAAAAAAAIAAACAAAAAAAAAAAAAAAACAAAAgAAAAAAAAAAAAAAAAgAAAQAAAAAAAAAAAAAAAAIAAAEAAAAAAAAAAAAAAAACAAACAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAIAAAAAAAAAAAAAAAACAAADgAAAAAAAAAAAAAAAAgAAAEAAAAAAAAAAAAAAAAIAAABAAAAAAAAAAAAAAAACAAAAQAAAAAAAAAAAAAAAAgAAAEAAAAAAAAAAAAAAAAIAAADAAAAAAAAAAAAAAAACAAADgAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAwAAAAAAAAAAAAAAAAIAAADAAAAAAAAAAAAAAAACAAAAOAAAAAAAAAAAAAAAAgAAAAcAAAAAAAAAAAAAAAIAAAAA4AAAAAAAAAAAAAACAAAAABgAAAAAAAAAAAAAAgAAAAAHAAAAAAAAAAAAAAIAAAAAAOAAAAAAAAAAAAACAAAAAAAcAAAAAAAAAAAAAgAAAAAAAwAAAAAAAAAAAAIAAAAAAADgAAAAAAAAAAACAAAAAAAAHAAAAAAAAAAAAgAAAAAAAAOAAAAAAAAAAAIAAAAAAAAAcAAAAAAAAAACAAAAAAAAAAwAAAAAAAAAAgAH/AAAAAADgAAAAAAAAAIABAA",
        "counties2": "CAAAgAAAAEAAgADAAP///wwAAIAAAABAAIAAwACAAAAEAACAAAAAYACAAMAAgAAABAAAgAAAAHsAgADAAIAAAAMAAIAAAAD8oIAAwACAAAABgACAAAABCHCAAMAAgAAAAOAGgAAAAQAfgADAAIAAAABcCYAAAAEAA4AAwACAAAAAx9CAAAACAACAAMAAgAAAAYBggAAAAgAAgADAAIAAAAcAAIAAAAPwAIAAwACAAAD8AACAAAAAEACAAMAAgAAACAAAgAAD+DAAgADAAIAAAAgAAP/4BgfwAP/+wACAAAAQAACABwQAEAAAAsAAgAAAIAAAgADsABgAAALAAIAAACAAAIAAGAAIAAACwACAAAAgAACAAAAADAAAAsAAgAAAEAAAgAAAAAwAAALAP4AAABAAAIAAAAAIAAACgGCAAAAwAACAAAAABEAAAoDAgAAAIAAAgAAAAALAAAKDgIAAACAAAIAAAAABIAADj4CAAAAgAACAAAAAACAAA5mAgAAAQAAAgAAAAAAQAAJZgIAAAEH8AIAAAAB/8AA+MYCAAB+BBACAAAAAQBgAwAEAgAAQAQf/gAAAAEAIAwABAIAAEAEAAIAAAABADAIAAQCAABABAACAAAQAQAQCAAEAgAAQAQAAgAAGAEAEAwABAIAAEAEAAIAAB//AAgcAAQD///4BAACAAAQAAAI6AAEAgAACAQAAgAAEAAABYgABAIAAAgEAAIAABAAAAUIAAQCAAAL/AACAAAQAAADCAACAgAACEAAAgAAEAAAAggAAgIAAAxAAAIAABAAAAAIAAECAAAEQAACAAAQAAAACAAAggAABEAAAgAAEAAAAAgAAMIAAATAAAIAABAAAAAIAABDwAADgAACAAAQAAAACAAAIkAAAAAAAgAAEAAAAAgAACJAAAAAAAIAABAAAAAIAAASQAAAAAACAAAQAAAACAAAEnwAHAAAAgAAEAAAAAgAADIEABAAAAP////////4AAAiBwfwAAACAAAAAAAACAAAGgEEAwAAAgAAAAAAAA////4BBADAAAIAAAAAAAAIAAACAQQAOAACAAAAAAAACAAAAgEEAAcAAgAAAAAAAAgAAAIBBAAAwAIAAAAAAAAIAAACAQQAADgCAAAAAAAACAAAAgEEAAAHAgAAAAAAAAgAAAIAhAAAAMIAAAAAAAAIAAACAIQAAAA6AAAAAAAACAAAAgCEAAAABwAAAAAAAAgAAAIAhAAAAADgAAAAAAAIAAACAIQAAAAAHAAAAAAACAAAAgCEAAAAAAMAAAAAAAgAAAIAhAAAAAAA4AAAAAAIAAACAPwAAAAAABwAAAAACAAAAgAH/AAAAAADgAAAAAgAAAIABAA",
        "gauges": [
            ("09430030", 7, 14, None, None, [26.88, 30.8, 40.0, 48.0, 58.95, 121.0, 201.0]),
            ("09430500", 11, 21, None, [9.0, 11.0, 13.0, 15.0], [16.39, 22.08, 40.3, 60.0, 151.0, 312.0, 456.6]),
            ("09431500", 15, 29, None, [15.0, 20.0, 25.0, 29.0], [12.3, 16.36, 23.9, 59.6, 176.0, 409.2, 533.0]),
            ("09439000", 19, 37, None, [16.0, 20.0, 21.0, 22.0], [0.0, 0.0, 2.92, 47.75, 195.75, 411.9, 656.95]),
            ("09448500", 23, 48, None, [19.0, 21.0, 22.5, 24.0], [24.21, 36.6, 52.8, 101.0, 236.0, 850.0, 1498.0]),
            ("09466500", 32, 64, None, [15.0, 20.0, 24.0, 27.0], [8.77, 11.1, 17.7, 45.5, 185.0, 879.6, 1684.0]),
            ("09474000", 39, 81, None, [25.0, 27.0, 31.0, 35.0], [2.71, 13.5, 66.4, 214.0, 397.0, 605.0, 661.0]),
            ("09479350", 49, 100, None, [5.0, 6.0, 7.0, 8.0], None),
            ("09514100", 54, 109, None, None, [0.0, 0.0, 0.0, 0.0, 0.0, 6.76, 59.94]),
            ("09519000", 58, 117, None, None, [7.58, 7.91, 8.58, 9.16, 9.77, 10.7, 12.08]),
            ("09519800", 63, 128, None, None, [0.0, 0.0, 0.0, 0.0, 1.77, 3.64, 60.65]),
            ("09520280", 68, 138, None, [8.0, 9.0, 10.0, 11.0], None),
            ("09520500", 77, 156, None, [20.0, 24.0, 26.0, 30.0], [4.02, 5.14, 6.93, 9.31, 12.2, 16.1, 25.48]),
        ],
    },
    {
        "key": "riogrande",
        "label": "Rio Grande",
        "short": "Rio Gr.",
        "line1": (21, 1, "00122323222232212110112117700112112120100"),
        "states1": "AQBAAIAAgGMBAEAAgACANwEAQACAAIAcgf//////gBhDAEAD+AD/3ycAQAIIAIBgFABAAggAgCAMAEACCACAQAQAQAIIAIB/AgBAAg4AgIYCAEACAfOAhgYAQAIAfMGGBgBAAgAAQQSeAEACAAB/hOYAQAIAAECEAYBD/gAAQYQAcF8AAABBBAAP8IAAACMEAAAAQAAAI+UAAAAgAAAgNQAAABAAACA/AAAAEcAAeAgAAAAKIACGcAAAAAQQAwGQAAAAABAMAAAAAAAACBAAAAAAAAAEEAAAAAAAAAQgAAAAAAAAAiAAAAAAAAADEAAAAAAAAADwAAAAAAAAAAAAAA",
        "counties1": "nf9+7f////+R/n/f/////5FEV+L/7///3/////////9zY0zr/////zbDf////////MNFn/////8M8////////wSbx9//////Ao//////////+8i//f///4eN36f//////5/75/////+ukm9///////b//W//////AYJ3//////8Abl+v/////wAf8Lv/////AAAAdP////8AAAA7/////wAAABlf////AAAAGt////gAAAAKP/8DeAAAAAYf7gDQAAAAAA/4AAAAAAAAD/AAAAAAAAAF8AAAAAAAAAfgAAAAAAAAA+AAAAAAAAADYAAAAAAAAADgAAAAAAAAAAAAAA",
        "line2": (42, 2, "00001012222233232322322223232210212211011112121210101076760601001111212112121221200101000"),
        "states2": "AAIAABAAAABAAAAAgAAwDAACAAAQAAAAQAAAAIAAHA8AAgAAEAAAAEAAAACAAAYLAAIAABAAAABAAAAAgAACGAACAAAQAAAAQAAAAIAAAjAAAgAAEAAAAEAAAACAAAPggAP/////////////gAABgEACAAAQAAAEAAAAAIAAAY8gAgAAEAAAD//AAAD///P4EAYAABAAAAwAQAAAgAASAAgeAAAQAAAMAEAAAIAANAAEHAAAEAAADABAAABAADwAAhAAABAAAAwAQAAAQAAIAAGQAAAQAAAMAEAAAEAACAAAUAAAEAAADABAAABAABAAADAAABAAAAwAQAAAQAAQAAAQAAAQAAAMAEAAAEAAP/8ACAAAEAAADABAAABAAGAYAAgAABAAAAgAaAAAQABAGAAEAAAQAAAIAD4AAEAAQBgACAAAEAAACAAHwABAAIAQAAgAABAAAAgAAD+OQAGAEAAIAAAQAAAIAAAN8cABgBAACAAAEAAACAAAAABwAwAQABAAABAAAAgAAAAAMAMAMAAYAAAQAAAIAAAAADABADAACAAAEAAACAAAAAA//wAwg/gAABAAAAgAAAAAMAEAIPwwAAAQAAAIAAAAABABgCAADAAAEAAACAAAAAAQAIAgAAOAABAAAAgAAAAAEAEAIAAAcAAQB//4AAAAABADACAAAAwAE/4AAAAAAAAQAgAgAAADgBIBAAAAAAAACAYAIAAAAH/+AIAAAAAAAAgCACAAAAAAAABAAAAAAAAEBAAgAAAAAAAAIAAAAAAABAf8EwAAAAAAABAAAAAAAAwACBIAAAAAAAAIAAAAAAAIAAwRAAAAAAAACAAAAAAACAAEEQAAAAAAAAQAAAAAAAgAB/8AAAAAAAAEAYAAAAAYAABAAAAAAAAAAgJwAAAAF4AAgAAAAAAAAAICCAAAADhwAIAAAAAAAAABhAQAAADADAEAAAAAAAAAAGwCAAADAAMcgAAAAAAAAAAQAQAABAAA4wAAAAAAAAAAAAEAABgAAAAAAAAAAAAAAAAAgAAgAAAAAAAAAAAAAAAAAIAAQAAAAAAAAAAAAAAAAABAAYAAAAAAAAAAAAAAAAAAIAIAAAAAAAAAAAAAAAAAACACAAAAAAAAAAAAAAAAAAAQAgAAAAAAAAAAAAAAAAAAEAQAAAAAAAAAAAAAAAAAAAgEAAAAAAAAAAAAAAAAAAAIBAAAAAAAAAAAAAAAAAAACAQAAAAAAAAAAAAAAAAAAAQEAAAAAAAAAAAAAAAAAAAGAgAAAAAAAAAAAAAAAAAAAeIAAAAAAAAAAAAAAAAAAAAeAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        "counties2": "A+P//x/4aPJUnv/q///f34ICCAYc3HySV/ecv/X9b/+CAhAME//jkn+f9L/v3/3fggP/+B/0sv/V95/q+/v//4ICEBgRP/wIf170//+v+/eCAhAwEiZQCFVSlKrv/d/7wvP/////////////vzd//2P+CAkQQJCERE3LN+/11/8yAggJEECQj//7/z7/////GgYYCRBAvIylU862m9/+7wYcYAkQeGf//9////f///4CHEAJH+/5GKV5V//VX/9f/xBACZAjT5zlX/zff/vv/wCQcAmQMUBf/9+X//rvPv8AUFwJl/FAeKVp/e/+////ADBECJQfX+//3123fdP12gAQRwicH/CYpX/f70v///8AGEGIkBIRv//+e39/d/3/AAhA6Z/+FulU/++51/9//gAGwPmQR/x//937e37p9/8H+cPJkECHy5137/59///6/Ah/z5BAhGqVUr+/f3fvXwAYQGHwQ4Qv//+v9ff///rgH0Dz0f4IOpVa6vz+s/f///XDllED+C///7/////39QQUQ5xfghhqlUqpX7U77dyEHEIMcIYX7///////////hPBCBDj6FGiqVSr+/vf9n/8wf/w/4hxv////r7//7/8ADEAH9iIEKKpV9v3+/d2/AANABBYiBC///v9/3///+wAA4AQWJ//8qrf/dfc/Xe4AABg8E/6I//u339X99//7AAAHZBIBiLOu//F/87/ergAAAP/+AIieqlX/U9///+8AAAAAAABJif/1N//8v397AAAAAAAAL3DEX/v+9///6wAAAAAAAB4wZ/Kt9rV//+sAAAAAAAAOOeRf///+7ve5AAAAAAAACc8/+V/3v3/1WwAAAAAAAARCIn/7+/////8AAAAAAAAEQSJb+//Z1/xAAAAAAAAAAkLyV/35V1+9gAAAAAAAAANEC/7fd/j9W4AAAAAAAAAAxAZKZ9uADzkAAAAAAAAAAGgD/7vyAAM+gAAAAAAAAAAYAUr9fAAA4wAAAAAAAAAAAAFv/cgAAAAAAAAAAAAAAAAA379wAAAAAAAAAAAAAAAAAMqrQAAAAAAAAAAAAAAAAAD//4AAAAAAAAAAAAAAAAAASn8AAAAAAAAAAAAAAAAAACJ2AAAAAAAAAAAAAAAAAAASfAAAAAAAAAAAAAAAAAAAH+wAAAAAAAAAAAAAAAAAAAu0AAAAAAAAAAAAAAAAAAAGpAAAAAAAAAAAAAAAAAAAB+QAAAAAAAAAAAAAAAAAAAW8AAAAAAAAAAAAAAAAAAADvAAAAAAAAAAAAAAAAAAAAGQAAAAAAAAAAAAAAAAAAAAeAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        "gauges": [
            ("08263500", 4, 10, None, [15.0, 16.0, 17.5, 20.0], [45.95, 66.26, 120.75, 254.0, 368.0, 555.0, 793.25]),
            ("08317400", 7, 15, None, [6.0, 6.6, 7.5, 9.0], [131.2, 206.4, 411.0, 609.0, 925.0, 1830.0, 3040.0]),
            ("08354900", 11, 23, None, [21.0, 23.0, 25.0, 33.0], [1.57, 15.29, 46.15, 493.0, 774.5, 1512.0, 2866.5]),
            ("08374550", 24, 52, [1.46, 1.72, 2.03, 2.4, 3.06, 4.02, 6.3], [13.0, 15.0, 19.0, 24.0], None),
        ],
    },
    {
        "key": "pecos",
        "label": "Pecos",
        "short": "Pecos",
        "line1": (23, 1, "22101021132222222212101210011012203202"),
        "states1": "AEAAAGACAAAAQAAAYAIAAABAAABgAgAAAEAAAGACAAAAQAAAYAIAAABAAABgAgAAAEAAAGACAAAAQAAAYAMAAABAAABAAcAAAEAAAEAAdAAAQAAAQAAf8QBAAABAAAPeAEAAAEAAAAAAQAAAQAAAAABAAABAAAAAAEAAAEAAAAAAQAAAQAAAAABAAABAAAAAAEAAAEAAAAAAQB//wAAAAABAH+AAAAAAAEf4AAAAAAAARAQAAAAAAP/8AwAAAAAAAAAAgAAAAAAAAABAAAAAAAAAACAAAAAAAAAAIAAAAAAAAAAQAAAAAAAAABAAAAAAAAAACB+AAAAAAAAIEEAAAA",
        "counties1": "JH+/i/////8kQI/+xVP19yZAxQP//p/dJkDFAcVb//8iT/3/f/6X3yJ4Z4RFU/X+IkB8jP///fwif/i/cqtn/+JBGON//v3t4kEPo93O/7++QQI+VU2r88fBBiN///v/x8P8IdVKrqptQg+hf//7/zl/CONVyqqvOMMYv3////8I4eijRVVVrf/3iON////9CFSIIUVVX/8IVI/////vtwhcmieqZX/+eEf+Jf/9W//IRAIk+nf//3/8ASR6VV/ZAAABJM//T3cAAAC7BiX73wAAAHmPP6p/AAAAL00m/f8AAAAiOf/+3wAAABIZE+9/AAAAEh+X/78AAAASEF/9Zw",
        "line2": (47, 2, "3222101100102121030123212232322122222211124211201022000012710201010221032210223012"),
        "states2": "AAAQAAAAAAAYAAAIAAAAAAAAEAAAAAAAGAAACAAAAAAAABAAAAAAABgAAAgAAAAAAAAQAAAAAAAYAAAIAAAAAAAAEAAAAAAAGAAACAAAAAAAABAAAAAAABgAAAgAAAAAAAAQAAAAAAAYAAAIAAAAAAAAEAAAAAAAGAAACAAAAAAAABAAAAAAABgAAAgAAAAAAAAQAAAAAAAYAAAIAAAAAAAAEAAAAAAAGAAACAAAAAAAABAAAAAAABgAAAgAAAAAAAAQAAAAAAAYAAAIAAAAAAAAEAAAAAAAGAAACAAAAAAAABAAAAAAABgAAAgAAAAAAAAQAAAAAAAQAAAIAAAAAAAAEAAAAAAAEAAABEAAAAAAABAAAAAAABAAAAPgAAAAAAAQAAAAAAAQAAAAOAAAAAAAEAAAAAAAEAAAAA9wAAAAABAAAAAAABAAAAABmQAAAAAQAAAAAAAQAAAAAAvtAwAAEAAAAAAAEAAAAAAM/p4AABAAAAAAABAAAAAAABBgAAAQAAAAAAAQAAAAAAAAAAAAEAAAAAAAEAAAAAAAAAAAABAAAAAAABAAAAAAAAAAAAAQAAAAAAAQAAAAAAAAAAAAEAAAAAAAEAAAAAAAAAAAABAAAAAAABAAAAAAAAAAAAAQAAAAAAAQAAAAAAAAAAAAEAAAAAAAEAAAAAAAAAAAABAAAAAAABAAAAAAAAAAAAAQAAAAAAAQAAAAAAAAAAAAEAAAAAAAEAAAAAAAAAAAABAAAAAAABAAAAAAAAAAAAAQAAAAAAAQAAAAAAAAAAAAEAAAAAAAEAAAAAAAAAAAABAAAAAAABAAAAAAAAAAAAAQAAH////wAAAAAAAAAAAAEAADAAAAAAAAAAAAAAAAABAAAwAAAAAAAAAAAAAAAAAQP/+AAAAAAAAAAAAAAAAAECAAQAAAAAAAAAAAAAAAABAgACAAAAAAAAAAAAAAwAAQIAAQAAAAAAAAAAAAAD///+AACAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAADAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAQAAAAAAAAAAAAAAAAACAA//AAAAAAAAAAAAAAAAAgAIAIAAAAAAAAAAAAAAAAGACACAAAAAAAA",
        "counties2": "BBAQAggGgI/QIREJ///3/wQQH//P/wBAX////EEiYQwEEBAAQPPAQFAhEQrBIx8MBBAQAEDiI/hQIREJfyERPwQcEABAYh8McCERCEF/8SIEBBAAQCIABF////hBQRHiBAQQAEAiAAZQIREJ/8EflwQEEABAIgAD0CERD0F985wEBBD/4CIAD5AhEQhBH5L5BAQQgD/if/sf///4QRHSjwQEEIAwP8AQECERC/8RUpgEBB+AMCBAEHAhEQ5BEX/QBAQQAD/gQBBQIREKd/H/0AQEEAAggEBwn///+/QRCHAEDBAAIIBA05EIiIocHzjcBAgf//6AT54RCIiOPzH/l8QIEAIBgEgKEQiIjmHRRPK0CBACAIB4C5////vhEXxCDAgQAgD/yAvxERCYvR8IwoQIEAIACAgIEREQnI9xz/+H+BACAAgP/BEREJOImfmIgBgQAgAICAQRERCQiIvtj4AYcAIAGAgGH////v+M/1/gGZACABAIAhEREImIiJj0YBuQAgBwCAPxERCIiIiIRPA3kA//wAgCEREQiIj4iEcQwRAIAH4IAh//////n//fCIEQCABDyAYRERCIiIhEdwmBH/wAQEgEEREQiIiIRCQHgRAEAEB4BBEREIiIiEQkBICQBAHAR/wf////////7wCA0AIGQEQEECIiER0QiLkAgFwCeEBEBBAiIhEREYj3AIA0A0BARAQQIiIREREIkQCANg/AQEQEECe/kREf/5H///M8QEB8Ah/+4v//8RCRAIARIEBABAIQIiIREZ8Q/wCAESBAQAQCECIiERGNcbAAgBEgQEAEAhAiIhEfj88YAIARIEH/////////+IyMDwCAESBDCAgeREQkIiR8xj4AgBHgQ4gIFEREJCIkFH/IP4AQP/9ICBZERCfiI+bszCCAECAASAgR///kIiXHhEbggBAgACgIEIJEPj+8WYR/wIAQIAA4CBD6RCIR/iCaMT///+AABAgQH0QiERHQ8sEAAAAAAAIIEDHEIhERG+PDAAAAAAACCBAg////EY4ePwAAAAAAAQhoQDAIERD8GjEAAAAAAACJhoAMCBH/hyJ3AAAAAAAAbwEABAgQiM3B/AAAAAAAAB4AgA4P/4iIJyQAAAAAAAAOAUB/CBCIWC3mAAAAAAAABeIgQwgQ/9W0dwAAAAAAAAQcGEIIEEEy4nYAAAAAAAACBA3D///BOLGeAAAAAAAAAgQDAgICf22fKwAAAAAAAAIEAQICDgjjDf4AAAAAAAACBACCAguI5pGcAAAAAAAAAgQAYgIb+ZSi3AAAAAAAAAEEA9/CGR/K4l4AAAAAAAABBAIAI//+cbw7AAAAAAAAAIQEACIQTmIyMA",
        "gauges": [
            ("08378500", 1, 2, None, [4.5, 5.0, 6.0, 7.5], [23.4, 26.2, 32.58, 52.85, 119.0, 247.1, 357.2]),
            ("08379500", 4, 9, None, [12.0, 15.0, 20.0, 24.0], [0.71, 1.92, 11.7, 35.4, 114.0, 294.0, 466.0]),
            ("08383500", 7, 16, None, [10.0, 11.0, 15.0, 19.0], [62.4, 66.0, 73.2, 82.9, 90.5, 124.2, 734.6]),
            ("08385630", 10, 23, None, None, [23.2, 25.9, 30.4, 38.4, 57.3, 85.6, 111.0]),
            ("08386000", 13, 28, None, [12.0, 13.0, 14.5, 16.0], [9.98, 15.3, 20.4, 27.9, 52.8, 170.6, 785.4]),
            ("08395500", 16, 34, None, [17.5, 20.0, 22.0, 25.0], [23.28, 30.69, 44.5, 57.55, 101.0, 267.1, 791.1]),
            ("08405200", 19, 39, None, [12.0, 14.0, 17.0, 20.0], [15.1, 17.9, 23.8, 28.0, 34.6, 43.4, 49.58]),
            ("08419000", 24, 51, [2.56, 2.56, 2.57, 2.57, 2.73, 3.44, 3.9], [12.0, None, None, None], None),
            ("08446500", 28, 62, [1.0, 1.02, 1.04, 1.08, 1.13, 1.18, 1.22], [15.0, 17.0, 20.0, 21.0], None),
            ("08447000", 31, 70, [2.41, 2.43, 2.48, 2.55, 2.65, 2.71, 2.78], [23.0, 28.0, 29.0, 30.0], None),
        ],
    },
    {
        "key": "brazos",
        "label": "Brazos",
        "short": "Brazos",
        "line1": (15, 1, "1171167177000012021161102210311121212101320221012212"),
        "states1": "AgAAAAIwDAACAAAAAAAHAAIAAAAAAAEAAgAAAAAAAQACAAAAAAAB/wIAAAAAAAEAAgAAAAAAAQACAAAAAAABAAIAAAAAAAEAAgAAAAAAAQACAAAAAAABAP4AAAAAAAEAAAAAAAAAAIAAAAAAAAAAgAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAIAAAAAAAAAAgAAAAAAAAACAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAABAADgAAAAAAMAA5wAAAAAAvACAgAAAAAPDgQBAAAAADABhACAAAAAQABkAEAAAACAABgAQAAAAQAAAAAgAAAGAAA",
        "counties1": "GlJJZSs8naseSkkl6S6X+hP///9///tfEkpJJSS236QySkkl//b5//P///9JP//qMhKSSUk73+sz/////+n5fTISkknpf79/EhKSSz9xpfoT/////d/pL/6kpJTk3q88dKSkk/f0vPVf///XvbbX1kyk8v7vn3/bQ+SSS8eyP39Efr/JO97T5qgf+nvhm66iEAQiLx5/y78IDj/p7vbppZQ6Ij/nvb/7YyYiEt768f0g5//+q/9PxSBEEZ+Z/u//ICQT935sPIEg/xNf9L4kvSCAn/ybi//DoQByJHL72ABhADIml8ZgABkAH/8p7mAABgASJNaSwAAAAAokftEAAA",
        "line2": (31, 3, "1200200720021776712160667007000020022011021610303002713016101212210032021120211221122112201022270123310314122001611221321022"),
        "states2": "AAQAAAAAAAAABAIAA6AAAAAEAAAAAAAAAAAAAABgAAAABAAAAAAAAAAAAAAAHwAAAAQAAAAAAAAAAAAAAAEAAAAEAAAAAAAAAAAAAAABAAAABAAAAAAAAAAAAAAAAQAAAAQAAAAAAAAAAAAAAAEAAAAEAAAAAAAAAAAAAAABAAAABAAAAAAAAAAAAAAAAQAAAAQAAAAAAAAAAAAAAAH//wAEAAAAAAAAAAAAAAABAAAABAAAAAAAAAAAAAAAAQAAAAQAAAAAAAAAAAAAAAEAAAAEAAAAAAAAAAAAAAABAAAABAAAAAAAAAAAAAAAAQAAAAQAAAAAAAAAAAAAAAEAAAAEAAAAAAAAAAAAAAABAAAABAAAAAAAAAAAAAAAAQAAAAQAAAAAAAAAAAAAAAEAAAAEAAAAAAAAAAAAAAABAAAABAAAAAAAAAAAAAAAAQAAAAQAAAAAAAAAAAAAAAEAAP/8AAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAMAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAADAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAABgAAAABgAAAAAAAAAAAAAAQAAAABn/AAAAAAAAAAAAAIAAAABgAQAAAAAAAAAAAAD/wAAAQADAAAAAAAAAAAADwDgAAIAAwAAAAAAAAAAADAAHgACAADAAAAAAAAAAADAAAEABAAAIAAAAAAAAAADAAAAwAQAABAAAAAAAAAAAgAAADAEAAAQAAAAAAAAAAwAAAAOCAAACAAAAAAAAAAwAAAAARAAAAQAAAAAAAAAQAAAAADgAAAEAAAAAAAAAIAAAAAAAAAAAgAAAAAAAACAAAAAAAAAAAIAAAAAAAADAAAAAAAAAAABAAAAAAAADAAAAAA",
        "counties2": "AgQhBBCCGCEIRQcQQ6PEQgOEIQQQggghCEEEEEFgxEYD/CCEEIIIIQhBBBBBP+REAgQghBCCCCH4QQQfQQE/xgIH////////H//88f8BN38CBCCEEIPIIQQQh59TNxInBgQghBCCCCEEEIIYUv0mIAQEIIQQggghBCCCEFKBZCAEBCCEEIIIIQQgghBegUQgBAQghBCCCCH///48WoH///wH////////EEIKJ/+BTIQEBAIIQQQgghBCC+QT/0SEBAQCCEEMIIIQQg5eEN1kjwQEAghBCCCCEEIIThH/JIkEBAIIQQggghBCCEPzgyTwBgf///////////hCfoMkkQIEAghBCCCBEIIMQwSBNJ4CBAIIQQgggQiCD/+H5zeEAgQCCEEIIIMLhg8AhD18DAIEAghBCCCODLs7gQQhn4gCBAIIQQggvwfh4IH8QQj/Agf///////EGYYDfhEEMWP/8hBCEEEER2HBB+IR/BMgsIIQQhBBBEPwwR2CEIIcYJCCEEIQQQQgkHjwgh/B8EyYghBCEEEELxh3MMEQwZDIj////h/BhDwNxBBhGHCY+IICEEPwf4RCOwIY99gvCGCDAhBD/BD9guMDC7w8JI4YgcIQQgQQ/6GBjwYwM6SCfIB7EEIEEILzQLiYEBDkT8yAJtBCBBCCFkFguBB4ZHBggEAwQgQQgggmMMggyDfgYICAP+I//4IMKBEE4ww+MGNAgB///hCCB/AfB54T8jAgMQAHACAQ/jwYGIYeI9IgIBoAAYAgECf8HyCe+8MSP/wEAACAIBAhAjPgd8HDCmCIAgAAwD//4QYg4FZBQwpAiAEAB+AgECEEYCH0QmEOwIgGgBwgIBAhBnA2HHI5BoGLjGAQQCAQP/7fOgpuH/6ZPHAwEEAgEAgTjOE/YXwO/8gQCBAgIBAIEICw+yDiDoCIEATwf///+BDAiIPgQg+AjBACgEAEAQvxMQuErGMYgMwQAYBABA8OiQoO/vLh7Mf8EADAQAQJAIsNCHGBIIf/+BAAYEAECeCGmZBjQDCBgAgQABhABBC+nFCgukAfwwAIEABn/AQQg6h4QYfAEEIACBABgAQEEID/jaEFsBBB/wgQAgADB///wgIeAw2w3wDoEAIAAwQQEUGEMQcH/+AAHhAEAADMEBBAzCGFDtjAAAEQBAAATBAQQfggiIxDAAAA0AQAADwQEEEIUHC4QgAAADgEAAAYEBBiBJnAQCwAAAAGCAAACBAQeg8LYcBwAAAAARAAAAf//8w2DjcgQAAAAADgAAAEEBBDSBsMIEAAAAAAAAAAAhAQQYWxiBmAAAAAAAAAAAIQEEDDcIgGAAAAAAAAAAABEBBAVhD4BAAAAAA",
        "gauges": [
            ("08082000", 7, 18, [2.19, 2.26, 2.65, 2.76, 2.87, 3.33, 3.64], [10.0, 12.0, 24.0, 25.0], None),
            ("08082500", 13, 32, [0.54, 0.76, 0.95, 1.16, 1.55, 2.36, 3.17], [10.0, 12.0, 15.0, 20.0], None),
            ("08088000", 18, 43, [2.82, 3.04, 3.3, 3.6, 4.28, 5.91, 7.58], [19.0, 21.0, 28.0, 34.0], None),
            ("08089000", 21, 53, [0.95, 1.02, 1.12, 1.38, 1.61, 2.24, 3.07], [14.0, 16.0, 18.0, 22.0], None),
            ("08091000", 26, 65, [4.02, 4.07, 4.12, 4.19, 4.67, 6.09, 8.18], [22.0, 29.0, 30.0, 34.0], None),
            ("08093100", 30, 74, [5.85, 5.88, 6.01, 6.18, 6.9, 8.22, 12.72], [27.0, 29.0, 32.0, 35.0], None),
            ("08098290", 34, 83, [1.44, 1.6, 1.8, 2.04, 2.68, 4.83, 8.34], [33.0, 35.0, 38.0, 40.0], None),
            ("08108700", 37, 89, [6.77, 7.14, 7.51, 8.33, 10.5, 15.96, 20.8], [37.0, 52.0, 60.0, 66.0], None),
            ("08111500", 42, 101, [9.65, 9.76, 10.14, 11.09, 14.04, 20.4, 26.18], [25.0, 50.0, 53.0, 55.0], None),
            ("08114000", 47, 113, [8.22, 8.41, 8.87, 9.97, 12.91, 18.75, 24.73], [20.0, 45.0, 48.0, 50.0], None),
            ("08116850", 50, 120, None, [20.0, 26.0, 27.0, 28.0], None),
        ],
    },
    {
        "key": "trinity",
        "label": "Trinity",
        "short": "Trinity",
        "line1": (18, 1, "00100101120000112210121121231201721202132212"),
        "states1": "AAAAAAAA4AAAAAAAAAAgAAAAAAAAACAAAAAAAAAAIAAAAAAAAAA//wAAAAAAACAAAAAAAAAAIAAAAAAAAAAgAAAAAAAAACAAAAAAAAAAIAAAAAAAAAAgAAAAAAAAACAAAAAAAAAAIAAAAAAAAAAwAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAAAgAAAAAAAAADAAAAAAAAAAEAAAAAAAAAAIAAAAAAAAABgAAAAAAAAAEAAAAAAAAAAwAAAAAAAAACAAAAAAAAAAIAAAAAAAAAAgAAAAAAAAACAAAAAAAAAAIAAAAAAAAABgAAAAAAAAAEACAAAAAAAB/wA",
        "counties1": "JEiPIi9EfpT///v//Pwr/CRIiREnf+pHJEiJESRmOkP+SI//5/4//0n/+iR9v/cRSIkSJG8n97FIiRIkSe3qr//////JfCrsSJETRH+fb7ZIkTHMcJH/s0iR8ffY8ib+//+Low+T4uKREk+3PJMzJ5ESRpvEnx58nxJ48ybJk3b5/4vjL/z5M4iP7i8xG6u/iIk6OOEZpuOIiRPPk2z8Iv/5Hwcf09QmII/4yb9yV/8giJmw/mJ0Sz/4ixvXcjxLII/7b3rf+v4ggj65ejx/7v/+FizeInhJCBP3p5+y6HsIcJzG93Ov/QhfiqjaH5gICMmxuW4IkAiP///uHRD/yA",
        "line2": (36, 2, "0000010110001011212202070001701111212200210112302021202202212322410221701270122102102122313221212"),
        "states2": "AAAAAAAAAAAAAAAB+AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAD////wAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABgAAAAAAAAAAAAAAAAAAAAMAAAAAAAAAAAAAAAAAAAADAAAAAAAAAAAAAAAAAAAAAYAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAMAAAAAAAAAAAAAAAAAAAADAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAMAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAADf8AAwAAAAAAAAAAAAAAAHYAwAA",
        "counties2": "CBAgQECCBAgIEBARr4hDCAgQIEBA/gQICB+QEAj4Qhj//////4////jw89AIj8GYCBAgQHiBAgIPk//wCER/0AgQIEBAgQICBB4UPzhMEDgIECBAQIECAgQYFCzoSBANCBAgQECBAgIEEBQoCYgQAwgQIEBAgQICBBAUKAkIEAIIECBAQIECAgQQF6gJCBAD//4gQED////8P/5oD////yBH////hAgQJGPH+AkJAgEgQICBAgQIECfCBH/4iQIBIECAgQIECBA88gQQCYkCACBAgIECBAgQIJ4EHNkJh4EgQICBAgQIECCBhDM4iIRzIECAgQIECBAggXzwCISMHCBAgIECB///4IEfkAjE+Bj///////wQIDCBARAIRMjwIECBAgEEECAQgIEYCEfPkCBAgQIBAhAgH//B/zjnAhAgQIECAQLwIBgAQQPp9AIIIECBAgYDEOB2AIEECT+EDyBAgQIdARcRwQCBBA4QhAggQIEC8QHsFwCA/wQMEP/4/////8CBhAwAz8EEDAhQCEEBAgQgpgYGAPhBB/wFyAhBAQIEIFkEAgNAQQIGBwgfQQECBBAZAzMMYEEDAgcYGEEBAgQIGIHx8CBB/wP8EPhDAQIECGCBjhAwIIEBBBCQQ/8CBB+AYwgQGDCBAIYfmMIBAgQQgdwECBwwgeOCCBh+Af4EIMcQBAht/ED9ggYIf8BBx0BcCAIEt8bwRMMDDkBAQP/IcAQNBcQDnETBB35AQECZPGgEMQYGAIbIZ/njQEBAgQ/IAuCcAgOBiER4B0BAQIEHBA2AtAQEwYh8DARAQECBAgYwQMQECEDI8AQEQEBAgQECwGOCDDBwL7AEBP///4EDAwAuAn5AnnoQBAQEAECBAf8AEQPDwQvhGAQaBABA//+BgGEHAyIIIRAEJgQAQECBgPCAjz88CCEf/8QEAEBAgME9gJvwOAgREBCHBABAQIDDAwBxGBQIESAQggf//8CAwgGB4Rg0CBEgEIYEAEBAgIYAg2EYJwQJQBCGBABAQICHAIwxHiGECkBwhAQAQH//yLB0CYng//rMQ7wEAEAIB/hsxgyIMNASTE7+BABACAIYAwIPiBMYEv/wggQAQAgCEALBPYgMCBKAIIP////4AhwEIMC4BAgfwDCCAEACCAISBCEA6AIIOEAQhABAAg/+MQg3gTuCBHhAGI8AQB4AQSDQHP++bgfYQBnwAEASAEFgaBBwkBIBDv//kABAIgBA0MQgYJABAQOAAIAAQCP+QYmEQKCQAf+BAACAAEAgg8EFgoEciAGAgwAAgABAQIDHA4MBBNgAgIIAAIAAQECAP85uwgJmAICCf8CAwH///7D4GDwDwYEAnYAwgA",
        "gauges": [
            ("08042800", 4, 8, [3.47, 3.49, 3.55, 3.68, 3.97, 4.86, 6.31], [18.0, 20.0, 22.0, 29.0], None),
            ("08044500", 8, 16, [4.16, 5.07, 5.42, 5.9, 6.47, 7.11, 9.04], [14.0, 16.0, 20.0, 24.0], None),
            ("08049500", 13, 28, [2.35, 2.4, 2.56, 2.91, 3.87, 5.76, 7.85], [25.0, 27.0, 30.0, 33.0], None),
            ("08062500", 17, 36, [2.94, 3.06, 3.33, 4.05, 6.79, 13.18, 16.88], [20.0, 31.0, 36.0, 38.0], None),
            ("08062700", 21, 44, None, [31.0, 33.0, 40.0, 46.0], [688.2, 742.0, 948.0, 1590.0, 4900.0, 11960.0, 17880.0]),
            ("08065000", 24, 55, [3.78, 3.95, 4.9, 6.83, 13.13, 22.81, 28.54], [30.0, 35.0, 40.0, 45.0], None),
            ("08065350", 27, 61, [2.65, 6.36, 7.12, 8.32, 11.2, 19.77, 26.16], [35.0, 41.0, 45.0, 48.0], None),
            ("08066000", 32, 74, [128.63, 129.17, 130.19, 130.68, 131.16, 132.45, 134.06], [132.0, 133.5, 136.0, 140.0], None),
            ("08066250", 36, 83, [4.44, 4.55, 4.8, 5.56, 11.29, 18.73, 23.93], [33.0, 36.0, 38.0, 41.0], None),
            ("08067000", 41, 92, [6.45, 6.58, 6.93, 8.0, 14.65, 22.89, 26.69], [21.0, 26.0, 27.0, 29.0], None),
            ("08067252", 44, 96, [0.39, 0.76, 1.17, 1.73, 2.45, 3.23, 3.76], None, None),
        ],
    },
    {
        "key": "sabine",
        "label": "Sabine",
        "short": "Sabine",
        "line1": (21, 1, "111101000011001022012121212322322222322"),
        "states1": "AAAAAAIAAAgAAAAAAgAAEAAAAAAD///wAAAAAAIAABgAAAAAAgAAGAAAAAACAAAYAAAAAAIAABgAAAAAAgAAGAAAAAACAAAMAAAAAAIAABgAAAAAAgAAGAAAAAACAAAIAAAAAAMAADAAAAAAAQAAYAAAAAABAADAAAAAAAGAAMAAAAAAAMAAwAAAAAAAQADAAAAAAABgAQAAAAAAACAAgAAAAAAAIAD/AAAAAABAAAAAAAAAAEAAAAAAAAAAgAAAAAAAAACAAAAAAAAAAIAAAAAAAAAAgAAAAAAAAACAAAAAAAAAAIAAAAAAAAABgAAAAAAAAAEAAAAAAAAAAfwAAA",
        "counties1": "JkRE6/7yNEsmRESKw6IYUyfkRI/D/////J/8/98pCH1IiI+icykI3kiIiXr/qezfSP/5P8auN/7/kQkhYuvmXYR5D/H/+TXOjH8eESN5H/r0bOE/Im/y37PEw/k+Lhabk+TnkfH6P7KeM/mJ0SLl7p42RNyZs6b/4uhl/s+ZttHxiaMjaon/0U6HPCKafh7/SF48ZMvjFchH4eP5P2MRiP5ho/pJQTP/JDsv7G1/35UkbhrOZUKb/SLDe+knhpsv/tmNeP+18fkJt29HR/6f7AnJOcZnhpy/+2ny+zyCvd8nEN7vFv/v/6ctG0HzgIX3bOYrwREAh3Y+/WexEfyHPw",
        "line2": (43, 2, "212110110100110010000102712701002120022120112121221202221220313223232223202223232322"),
        "states2": "AAAAAAAAAAAACAAAAAABAAAAAAAAAAAAAAgAAAAAAYAAAAAAAAAAAAAIAAAAAAEAAAAAAAAAAAAACAAAAAADgAAAAAAAAAAAAAgAAAAAAQAAAAAAAAAAAAAP//////8AAAAAAAAAAAAACAAAAAADgAAAAAAAAAAAAAgAAAAAA4AAAAAAAAAAAAAIAAAAAAEAAAAAAAAAAAAACAAAAAADAAAAAAAAAAAAAAgAAAAAA4AAAAAAAAAAAAAIAAAAAAGAAAAAAAAAAAAACAAAAAABwAAAAAAAAAAAAAgAAAAAAYAAAAAAAAAAAAAIAAAAAAHAAAAAAAAAAAAACAAAAAAAwAAAAAAAAAAAAAgAAAAAAHAAAAAAAAAAAAAIAAAAAABgAAAAAAAAAAAACAAAAAAAQAAAAAAAAAAAAAgAAAAAA8AAAAAAAAAAAAAIAAAAAAHAAAAAAAAAAAAACAAAAAABwAAAAAAAAAAAAAgAAAAAAYAAAAAAAAAAAAAIAAAAAAMAAAAAAAAAAAAABAAAAAACAAAAAAAAAAAAAAYAAAAADAAAAAAAAAAAAAACAAAAAAwAAAAAAAAAAAAAAQAAAAAcAAAAAAAAAAAAAAEAAAAAEAAAAAAAAAAAAAABAAAAAHAAAAAAAAAAAAAAAYAAAAAwAAAAAAAAAAAAAADAAAAAYAAAAAAAAAAAAAAAgAAAAEAAAAAAAAAAAAAAAEAAAADgAAAAAAAAAAAAAAAgAAAA4AAAAAAAAAAAAAAAYAAAAMAAAAAAAAAAAAAAADAAAAGAAAAAAAAAAAAAAAAYAAAAgAAAAAAAAAAAAAAAEAAAAIAAAAAAAAAAAAAAAAgAAABAAAAAAAAAAAAAAAAQAAAA//8AAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAMAAAAAAAAAAAAAAAAAAAADAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACB8AAAAAAAAAAAAAAAAAAAfg4AAAAAA",
        "counties2": "CAgQEBAwSEhnOCQIFhAhCQgYEBAQEHBIXNhMCA9gIY8IGBAQEBBASFAISAgBwCECCBAQEBAQQEhQCcgIAMAjgggQEBAQEEBLUAkICACAIT4IH/4QEBBATdAP///////i//BD///w//hQCYiBAEAnojxAQECAkYgP8fmEgQBAa6MgQEBAgJ+MCD8IhIEAQEnsIEBAQIDy5AggCYSBAEBbTCBAQICAghwIOfkEw/Bwk8QgQECAgYIGCCf4hEIY8JH+IEBAgIGCBehgCIRGCJGxzCBAf///ggQ/4AjEfA8e/9///8EBAYIEAiAIRER4HCHRQBBhAQCCAgI4CETHyBgg8UAQIQEAQgID/zhngQwx4HJAECeBAH//AgXo9AEGMyB2QDAdhwD4AQIICzwDA+ZHZEDwEbyDDAECCAw/gwIkfcxDEA7wjAYB/ggIGP/+HCP8/BgYYHACA4IICBBIAggh5IQIMGBwA3yCCAgIbAIQYYeEDvAQEA+Bgg/4BOQCGOMEggcQIBgZAQIEBAeEB/vGBIIBGBmIYYED/gP9DAQkz8SBBggPx4GAgwIBBAh8IMx8gTwMDFhAQMECAQQIRCH8BIHQBhhgQGBiAQCGD8QjHAeCCB1gMCBwYQH7ggYEJnf+hAgxgDAht/EAjYIDAiQxAogEwMAYEt8YwITDgIIsYQL8BYBAaBcQDXiEgIOHrkECJwaAYYwcGAcMiECG/OzhAiHMgCcEcAgDgogj+AFof/8g8EB8B/AQDIGIbAQB/OGAIEBhlAOwEBiAyBgCATfggCAgMgQOMBAgwG/4AgEBgIAgMDQCOBDwQTh6EAIBA4CAIB/4AvgbnYIPgwgCAQNAgCAYEAGIDAuGE8EQAg0H////+AgDCDgehBBBCAILBeIRCBAPhAQ9/OgYIR//8wXEEQgIE+wGZ0BQGCEQCEH9xBEIGDA4AsRgSAgREAhBhvwRCBggDA+MYEgIETAIYIIP8QgQYAQfDGBODAkgCGGCCD8ICHAEcch4QwwLQDhhAhhBCAjYA8BkJ8GH+kAgTgI2Qf/+iccgNCHA/wpOIf8D5kEAQYY8MB4gYyAS+/9BnxRgAEGAPBD0IDwwEsAwQPGWcABBgCIPBiAYEBKAEECQj8gAQ0BhBAPgBBAfwBhBkODLAEIwQRwEpgQYcEAIIzAgh//CCIC2CP2MD/BADHfbIf4IJAUAwvxw1AIYf/zcOzn0CBQGgYOCQCYCDIP/wBz+JAgLDEIBAkACAgOAAEAQ/CaIEZgiA4RAA/8BAABAETYfaCBYFATkIAMBAwAAQBITIBhgeAgMI2ABAQIAAEA0GbgH/GY2CBGYAQECB8BAOAf0BgmD5RAbBAMBAfg4QD4Awg",
        "gauges": [
            ("08017250", 1, 3, None, None, None),
            ("08018500", 6, 14, [0.69, 0.78, 1.24, 2.17, 6.96, 14.43, 16.31], [13.5, 14.0, 18.0, 21.0], None),
            ("08020000", 10, 22, [4.97, 5.08, 5.56, 6.54, 10.27, 19.43, 26.08], [25.0, 26.0, 33.0, 36.0], None),
            ("08022040", 14, 33, [6.52, 6.63, 7.36, 8.44, 11.73, 18.63, 22.63], [25.5, 26.0, 30.0, 35.0], None),
            ("08022500", 19, 42, [19.91, 20.06, 20.35, 21.62, 23.53, 24.98, 26.12], [27.0, 28.0, 32.0, 34.0], None),
            ("08026000", 27, 59, [11.03, 11.28, 11.62, 13.15, 20.43, 24.18, 25.69], [30.0, 36.0, 40.0, 44.0], None),
            ("08028500", 30, 65, [11.95, 12.06, 12.57, 14.75, 21.24, 24.91, 27.16], [30.0, 30.0, 33.0, 36.0], None),
            ("08030500", 34, 73, [13.39, 13.85, 14.9, 18.38, 23.88, 24.67, 24.85], [23.0, 24.0, 26.0, 28.0], None),
        ],
    },
    {
        "key": "neches",
        "label": "Neches",
        "short": "Neches",
        "line1": (23, 1, "01222222102012112101072122022222211312"),
        "states1": "AAAAAAIAAAAAAAAAAgAAAAAAAAACAAAAAAAAAAIAAAAAAAAAAgAAAAAAAAACAAAAAAAAAAIAAAAAAAAAAQAAAAAAAAAAgAABAAAAAACAAAEAAAAAAIAABgAAAAAAQAAEAAAAAABAAAYAAAAAAGAABgAAAAAAIAAMAAAAAAAQAAwAAAAAABAABAAAAAAAEAAPAAAAAAAgAAAAAAAAACAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAIAAAAAAAAABAAAAAAAAAAGPAAAAAAAAA/DAAA",
        "counties1": "//+In4JLxzciIIiCwmp8YjIg/8P+fiReHmHgQiO+Q/UXlhB+YhP+Zx0IG/JCGYJk8YwfYn4LQizRlHxiIQxD/ND/xGPw+N5FDYzCMhCM9k8+DEd7HIRmd3MMf8+PRjN2wxo5hmtCX1bh8uCGO2/B5ybDwYsKcEF+OCZjEY/wQQzwLD/ifRBBHBgyc+RNEEc/D0LfOEUf+/wTwZIYRzCRFzBHEjxjoJERMGnTJyLhnxt/dHvj/tl/H83G+j+C/9H/oTPaHELBGcWRFh7EX8CbQg4b9yx6R/v6DhHWFhP//P+JYZoD8MAQT1CC3gIRgBBaLUQtghGPEPPCPDjGd/DQ+A",
        "line2": (46, 2, "0101122221232132021112010220112121201001002700212221201321322222222101014323111"),
        "states2": "AAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAIAAAAAAAQAAAAAAAAAAAADAAAAAAAIAAAAAAAAAAAAAQAAAAAADAAAAAAAAAAAAAEAAAAAAAwAAAAAAAAAAAABAAAAAAAYAAAAAAAAAAAAAQAAAAAAcAAAAAAAAAAAAAEAAAAAAHAAAAAAAAAAAAAAgAAAAAAgAAAAAAAAAAAAAEAAAAAAQAAAAAAAAAAAAADAAAAAAMAAAAAAAAAAAAAAYAAAAADgAAAAAAAAAAAAACAAAAAA4AAAAAAAAAAAAABgAAAAAEAAAAAAAAAAAAAAMAAAAAPAAAAAAAAAAAAAABAAAAABAAAAAAAAAAAAAAAYAAAAAIAAAAAAAAAAAAAACAAAAAEAAAAAAAAAAAAAAAgAAAAAgAAAAAAAAAAAAAAMAAAAAYAAAAAAAAAAAAAAGAAAAAH8AAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAMAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAYAAAAAAAAAAAAAAAAAAAACA/AAAAAAAAAAAAAAAAAAA/wOAAAAAAAAAAAAAAAAAD8AAYAAAAA",
        "counties2": "D4QCAICAQ2NABDCH4B4bPPh///+AgEDcQAQwhCAQDA8MCAQAgIBACEAEEIQh8BgIBAgEAICAIAhgBBiMPxAQCAQIBABAgCAPHjwc+AgQMHgECAQAf//wD//kNoAIGCGYBvgEANgAEAgIBF+ACA/jGAMIPAMEABAIGASH+AgPIjACD+IGAwAQCBAHBgwYCDY/AzsDGAMAH/gQBAMH//gcEAHGAXABAB8IEAQDBEAIDBADAgDAAI/4CBAEAQZACBgQDAMAIAH/yAgQBACCIAgIELoAgCAD8AgIH/wATiAIDPBiAQAQDEAQCAgCAPggD/2wYQDCEBhgEAgEAQCwYAgiIWEALQ5gIBgP/AD/gEAIIDLAgHkzgDAIDAQAgIDB+CAzAIBg4EAYBAgGAEDggQgg/wBxgIBADAYIAgBAIP8IIYcB/gBAIAYDBAP4QCBwGCMdA4gAYBAfB4QBhcAgGAwlDA4MACAQYnxCAINgOAwEIhwYBAAwCIOAJcCCEAgGByYQYAYA8AsDADh4gjAIGv8nMPADA4gMAQAYDIQYCGfhpigQAo4IGACAGAaECH/AAOQ/GAG4BHABgCQDhBDAYAP8HAwGYAWQAwBGAYQPgBACPvgMGBAGEAIBggCEBgAQAjt4BmAQGAgCAwMAZ/4AEAIB4AbACCAIBgYDwD0CABACAMADAATQCP8IBHnxAgAQAgEg/wAFEAcAmAgvwIMAEAID4AEABggEAWgQI0CGABAeAv8BgBgIHgPIICAgggAQZAbgAPwgBDJ/i0AgIIf//8IG8AEHIAQj/A+AICCCAIED/vACAcACYggCQCAghACBAQIwAgBgAsIIAkAQEIQAgQEDPwQAIA2CCAZAEBiMAIGBAQMMABAyAggEcBAMmACBgwEDDgAQYeIMBBAQDJgDgIMBAwsAEYByCwQfCAiwAgCeAQcZDA5AEQz8A//8scIBsAH90LMYIBkMBg6ACJFCD/4BdHBA4CAOjAMYQAi/f/kDHcYwAbAQHwwB4EAIsAMBAXPCMAEMDfuEAYBACKABAQDQYWgDAgeBhADAIAiQAQEBkDBGAgIMAfwAQCAP8ACBAxAYwwQCGAMkIGAgeBAAgIYYCICIASYDPPjgENgQAOGHyYiAUAHC/zcVoB+MEADjWHuMACgBA8EQAhACBh///3A8f4BEAgEAkAAQAgGgAAEAMABgwgwBAZAACAIAwAABADB/EYEYAoCYAA//AMAAAQAQhAmAoATBCAAMAQCAAAEAEYIOwEAIMMgABAEBAAABABMGBMCgCAj2AAwBAIAAAQAmBxhjEBAIQ4AIAQCA/AEALAAwHBggBsDADAEAfwOBAD8A4BgP4APAcxgDD8AAYQAggA",
        "gauges": [
            ("08032000", 7, 15, [2.9, 3.1, 3.55, 4.9, 8.44, 12.41, 13.88], [11.5, 12.0, 18.0, 24.0], None),
            ("08032500", 12, 23, None, [15.5, 16.0, 18.0, 20.0], None),
            ("08033000", 17, 35, [1.16, 1.54, 2.18, 4.39, 9.84, 12.88, 13.92], [11.5, 12.0, 17.0, 20.0], None),
            ("08033500", 21, 44, [2.73, 2.96, 3.44, 4.84, 8.21, 15.47, 19.46], [25.0, 26.0, 30.0, 33.0], None),
            ("08041000", 31, 62, [4.83, 5.14, 5.7, 7.24, 13.35, 16.18, 16.65], [15.0, 16.0, 20.0, 24.0], None),
        ],
    },
    {
        "key": "guadalupe",
        "label": "Guadalupe",
        "short": "Guad.",
        "line1": (9, 1, "00000000120070102710271710141201202071016106020022312320014111212122116"),
        "states1": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQ",
        "counties1": "AQP/4gZgLY8PgAgSA8A4/wiACBUBwGBgCIAICIMwgGAY/4gQRBiAsBAgeBAsBQCcECAccDoCAQQwIAP8MY0CAjAgAwTg8YID///3B8DA/AAgBAsDAYECASAEAwGBAQECIAQCAEIBAIYgBAIA3gEARCAEAgH2AoA4IAQCAwIEQOAgBAMCAQhhgCAEAvYCsCJAIAQCDARAFCD///4CGIAoGCAEAgMhAEQFIAQCAUCAggIgBAIAgM0CAiAEAgDAdwEGIAQCAGBhgQQgBAIArYCA/CAEAgE2AIMMP////iEAhgQgBAICEMDoBCAEAgIQYRwMIAQCAggyDgggBAICCAwCCw",
        "line2": (18, 2, "00027200700270000011121000700002717022200661307117100605027101022031022112217022701702016011710270616120270222024224221222320000124102120202021303112211211217"),
        "states2": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAADA",
        "counties2": "AAEAB///+AIAEBAACD5AAQABAAAAQAQCAAgwAAhwQPwA/8AAAEAEBAAGYAAEwD/HAIBAAABAAgQAAeAABwAgAQCAQAAAQAEKAAGQAAwAIAAAgEAAAEAAkQADCAAQABAAAQBAAABAAKDABgQAIAAQAAEAQAAAQABAYAgCAEAAOAABAH//AEAAgBAQAQDAAGgAAQAIf+BAAQAIIACAgABGAAIACAA4QAIABDAAQQAAgwADAAgADkAEAARwACIAAQHwAQAIAAPACAAGyAAUAAMAEAIACAAA4BwAA4wAGAACAAgDAAgAABjzsAIEAHQABAAIBwAIAAAHAFgEAgHDAAgACAMACAAABAAwGAMHAYAYAAQBAAgAAAwAOHAB/ABAEAAG//////8cABnAAHAAf+AAAQgAACABFAAfAABAAMAwAAEIAAAgAKQABAAAgAEAGAACCAAAIADEAAcAAQABAAQABAgAACAABAAAgAEAAQACAAgIAAAgAAQAAEACAAEAAQAYCAAAIAAEAABgBgADAACAEAgAACAABAAAMAwAAwAAgDAIAAAgAAQAAGAIAAIAAEAgCAAAIAAEAADT+AACAAAgwAgAACAABAAAnxAABQAAEQAIAAAgAAQAAYAIAAiAAA4ACAAAIAAEAAMABAAQQAA4AAgAACAABAACAAYAYGAAcAAIAAAgAAYABAADAMAgAOAACAAAIAAFgAgAAQGAEAEgAAgAACAABHAIAAKDAAgCEAAIAAAgAAQOEAAMRgAEDAgACAAAIAAEAZAAECgAAhgEAAgAACAABABgACAQAAMgAwD///////wAEABAYAADQAGACAAAIAAEABgBgMAADMAAQAgAACAABAAIAgEAABAwACEIAAAgAAQABAQCAAAgEAAWCAAAIAAEAAIIAQAAQBgACAgAACAABAADMACAAIAIAAgIAAAgAAQAAUAAQGMACAAICAAAIAAEAACAAEC8AAYAGAgAACAABAAAQAAjDwABABgIAAAgAAQAAGAAFAyAAQAYCAAAIAAEAAAwAAgAgAGAEAgAACAABAAAEAAwAEAAgBAIAAAgAAQAACgAQABAAMAQCAAAIAAEAADEwYAAQABwUAgAACAABAABhzMAAMABn9AIAAAgAAQAAgwOAADABgBwD/////////wIAwAAgBgAEAgAACAABAAIBAEAAIBgABAIAAAgAAQACAQAgADAgAAQCAAAIAAEAAgCAOAAeEAAMAgAACAABAAIAgA4AJZAACAIAAAgAAQACAEACAED4AAgCAAAIAAEAAgBAAQGANAAIAgAACAABAAIAIAGCAAcACAIAAAgAAQACACAAZAADAAjCAAAIAAEAAgAwABgAAQALA",
        "gauges": [
            ("08165500", 5, 14, [7.58, 7.59, 7.65, 7.71, 7.76, 7.81, 7.89], [10.0, 10.0, 12.0, 22.0], None),
            ("08166200", 8, 19, [0.56, 0.75, 1.12, 1.33, 1.53, 1.67, 1.73], [7.0, 9.0, 12.0, 20.0], None),
            ("08167000", 13, 28, [2.77, 2.83, 3.02, 3.21, 3.32, 3.45, 3.52], [10.0, 21.0, 26.0, 28.0], None),
            ("08167200", 17, 39, None, None, [0.0, 3.38, 19.85, 38.8, 64.3, 113.7, 196.0]),
            ("08167500", 23, 52, [-1.2, -1.19, 1.48, 1.79, 2.16, 2.51, 2.94], [25.0, 30.0, 36.0, 39.0], None),
            ("08167800", 26, 63, [4.12, 4.14, 4.18, 4.24, 4.36, 4.49, 4.52], [8.0, 9.0, 10.0, 12.0], None),
            ("08168500", 30, 70, [1.54, 1.57, 1.62, 1.7, 1.89, 2.1, 2.16], [6.0, 7.0, 10.0, 14.0], None),
            ("08169740", 34, 77, [-2.59, -2.41, -2.19, -1.78, -0.81, -0.61, -0.54], None, None),
            ("08169845", 41, 94, [5.14, 5.23, 5.47, 5.89, 6.21, 6.94, 7.38], None, None),
            ("08173900", 44, 100, [10.72, 10.8, 10.95, 11.2, 11.53, 12.01, 12.29], [17.0, 31.0, 37.0, 43.0], None),
            ("08174700", 51, 114, None, [23.0, None, None, None], None),
            ("08175800", 55, 123, [6.42, 6.56, 6.76, 7.11, 7.62, 8.45, 9.05], [19.0, 24.0, 33.0, 37.0], None),
            ("08176500", 63, 143, [4.07, 4.21, 4.51, 4.98, 5.78, 6.9, 7.86], [12.0, 21.0, 27.0, 29.5], None),
            ("08177520", 66, 148, [7.23, 7.47, 8.17, 9.08, 10.86, 13.25, 15.56], [20.0, 20.0, 24.0, 27.0], None),
            ("08188810", 69, 155, [9.93, 10.2, 10.51, 10.86, 11.35, 12.09, 13.13], None, None),
        ],
    },
    {
        "key": "nueces",
        "label": "Nueces",
        "short": "Nueces",
        "line1": (18, 1, "23222222122211223212200170110212000767007701211212010"),
        "states1": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAEAAAAAAAAAAYAAAAAAAAAAgAAAAAAAAACAAAAAAAAAAGAAAAAAAAAAEAAAAAAAAAAIAAAAAAAAAAQAAAAAAAAAAgAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAIAAAAAAAAAAgAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAIAAAAAAAAAAgAAAAAAAAABAAAAAAAAwAEAAAAAAAEAAIAAAAAAAgAAgAAAAAAEAABAAAAAABgAACAAAAAAIAAAEAAAAABAAAAIAAAAAIAAAAgAAAABAAAACAAAAAIAA",
        "counties1": "AEB8f+QWD/8AQEQCFAoMcQBARAILERBhAECH+hCgoKGAQIIeIPDBmUBAggP526EMYH///wsGHgcgQICHBgghBSBAgIEDGCCFGECAgQEQIEgEQICBA+AgMAOAgIECENDgAICAgcQLCcAAQICBODYOMAB///8ETBwbAECAgQWQMgQAIICBAg2hBAAggIEDAuEMABCAgQGMIIgAEICBAvAh+AAI///8mCcIAAiAgQRMPgkABICBBEdPCgAEgIEEIYEMAAKAgQQghwwAAoCBBBEdCAAD/4EEHxswAAEAgQQn88AAAMD///AjAAAAIAECODIAAAAgAQJP+gAAACABAkMkAA",
        "line2": (36, 2, "22342222222122321321022122221113131331122212000110070101101212120100707676070070770717121202002202221022201016100"),
        "states2": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwAAAAAAAAAAAAAAAAAAAAMAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAADwAAAAAAAAAAAAAAAAAAAAMAAAAAAAAAAAAAAAAAAAADAAAAAAAAAAAAAAAAAAAAAcAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAMAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAABgAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAwAAAAAAAAAAAAAAADAAAAIAAAAAAAAAAAAAAADAAAABAAAAAAAAAAAAAAABAAAAAQAAAAAAAAAAAAAAAgAAAAEAAAAAAAAAAAAAAAQAAAAAgAAAAAAAAAAAAAAIAAAAAIAAAAAAAAAAAAAAMAAAAABAAAAAAAAAAAAAAEAAAAAAIAAAAAAAAAAAAAGAAAAAABgAAAAAAAAAAAACAAAAAAAEAAAAAAAAAAAADAAAAAAAAgAAAAAAAAAAABAAAAAAAAIAAAAAAAAAAAAgAAAAAAABAAAAAAAAAAAAQAAAAAAAAIAAAAAAAAAAAEAAAAAAAACAAAAAAAAAAACAAAAAAAAAgAAAAAAAAAABAAAAAAAAAEAAAAAAAAAAAgAAAAAAAABAAAAAAAAAAAIAAAAAAAAAcAAAAAAAAAAEAAAA",
        "counties2": "AAAgAACAH//4CAQYAI2gDAAAIAAf4AAIBBADMABwP/YAACAAECAACAIQAPAAQDAOAAAgABAgAAgCKADIAIAQAQAAIAAQIAAIAUYBhAEAEAMAACAAICAACACDAgICACgCAAAgACA//ggDAIQBBABMAwAAIAAgCAGIBgBMAIgARgMAACAAIAgAaAgATABQAIPDwAAgACAIABgQADIAIAEAYcAAIAAgCAAGfsAjANACACBAACAAYAgAAeNgQYMIAgAwIAAgACAIAAMAQYDsBAQAGTwAP//////jAC4AMAP4AAYMACAAgACANQAwAEAEBAAJDAAgAIAAgBkAGABACAIAEQcAIACAAIABABwAgAgBACABACAAgACAAQAHAQAIAIAhAMAgAIAAgAEAAwMACABAQAAgIACAAIABAAcCAAgAIEAAECAAgACAAQAH/gAIABGAAAxgAIAAgAEADAQAFAAKAAACQACAAIABAAgCAGIANAAAAcAAgACAAQAQAQCDAHgAAADAAIAAgAGAMACBAQDgAAAAgACAAIABcCABRgCBkAAAAIAAgACAAQ5ABigAQggAAABgAIAAgAEBgAgQAGQEAAAAH///////AEAQYAB4AwMAABAAgACAAQAgIIABmACGAAAQAIAAgAEAMEEAAwwAWAAAEACAAIABABGAgAYCACAAABAAgACAAQAKAEEIAgAgAAAQAIAAgAEABAAi0AEAIAAACACAAIABAAYAFDgBgGAAAAQAgACAAQADAAgMAIBgAAACAIAAgAEAAYAwBADAQAAAAgCAAIABAAKAYAQAQEAAAAEAgACAAQAMXMAEAH9AAAABAIAAgAEAGOMABAGBwAAAAID///////CBgAQGAEAAAABAgABAAQAgQIAEGABAAAAAQIAAQAEAIEDAB4gAQAAAAECAAEABACAgeAloAMAAAAAwgABAAQAgIAgQPADDAAAAIIAAQAEAIBAMIAYAhAAAABCAAEABACAQB0ADAIgAAAAQgABAAQAgCAGAAQCQAAAAEIAAQAEAIAgBAAMAoAAAAAiAAEABACAEAQA+AMAAAAAIgABAAQAgBAID4gGAAAAABIAAQAEAIAIGAYIGAAAAAAf//8ABACADBgDCGAAAAAABgABAAQAgBO0BhiAAAAAAAEAAQAEAIAgY5gRAAAAAAAAgAEABACAMABwEgAAAAAAAIAB//////gAYBQAAAAAAABAAAAEACAMACAIAAAAAAAAIAAABAAgGAAUEAAAAAAAACAAAAQAIC8AHCAAAAAAAAAgAAAEACBDi8pAAAAAAAAAEAAABAAgQP26gAAAAAAAABAAAAQAIEAYEYAAAAAAAAAcAAAEACBAAACAAAA",
        "gauges": [
            ("0818999010", 4, 10, [12.43, 12.51, 12.56, 12.9, 13.27, 13.44, 13.61], None, None),
            ("08190000", 8, 18, [0.81, 0.85, 0.95, 1.04, 1.23, 1.64, 2.05], [7.0, 10.0, 14.0, 21.0], None),
            ("08192000", 12, 27, [0.56, 0.57, 1.16, 1.64, 1.75, 1.82, 1.86], [10.0, 11.0, 15.0, 17.0], None),
            ("08193000", 22, 45, [0.77, 0.78, 0.79, 0.82, 1.09, 2.38, 3.66], [18.0, 20.0, 24.0, 27.0], None),
            ("08194000", 27, 55, [3.58, 3.65, 3.8, 3.92, 4.04, 5.01, 5.73], [9.0, 15.0, 15.0, 17.0], None),
            ("08194500", 38, 77, [1.02, 1.02, 1.05, 1.68, 2.41, 3.94, 7.41], [11.0, 14.0, 16.0, 19.0], None),
            ("08210000", 42, 85, [1.27, 1.29, 1.35, 1.4, 1.57, 2.91, 7.05], [20.0, 25.0, 27.0, 35.0], None),
            ("08211000", 48, 101, [-0.02, 0.11, 0.48, 0.75, 1.09, 1.46, 2.55], [16.0, 25.0, 26.0, 28.0], None),
            ("08211500", 52, 110, [3.12, 3.43, 3.87, 4.24, 4.54, 4.71, 4.93], [6.0, 7.0, 7.5, 8.5], None),
        ],
    },
    {
        "key": "hudson",
        "label": "Hudson",
        "short": "Hudson",
        "line1": (31, 1, "33101222012323222223222222122322"),
        "states1": "AACAACAQIAAAAQAAIBAgAAABAAAgICAAAAIAABAgIAsAAgAAEGAgNH/8AAAwQCBAgAAAAAhAIIAAAAAACEAjAAAAAAAIQBQAAAAAAAjACgAAAAAAGIAMAAAAAAAYgBwAAAAAABiAeAAAAAAAH/+MAAAAAAAIAAQAAAAAABAABAAAAAAAEAAIAAAAAAAwAAgAAAAAACAAD4D///4AP/+AgAAAAQAgBIBAAAAAgCAEwEAAAACAIARAQAAAAIAgBGGAAAAAwCAEZsAAAABgIB+fwAAAAFgh7xHAAAAAhl4HAAAAAAEBYAwAAAAAAIMAMAAAAAABggHAAAAAAAEHBgAAAA",
        "counties1": "AACHFh7x7v0AAQX8E9G/9AACDUQTEbfkAAIZRv/zOP8AD/Gn+yE8dH/2EaRxfubApEYbpkleYQAkRh3Hy0viACRHUb7P0NQAPkW5ok5++gDm/SU6TFO8ACeNFf9ykZwAPp3z/9KZeAAk7J8X3//IAGXvkjKeJ2QA/zyS9/fjJAARFvOOl+P4ABEf3hGW4/gAEQpCH6UxNwD///5xf//mgAkIRZkiJKSACYhEkSI1/EDoiHyZPv/YQDj/1N97Z//AN4a18b+t/oAcg85z/P8fgPpHj8s55xHAjX7Z338HAACI793fcAwAAJB/t+fgcAAA//+d/6GAAACv/jW/rgAAAA",
        "line2": (62, 2, "4224232002101212322200602122323222322222223232222222232212321212322232"),
        "states2": "AAAAAIAAAAADAAEABAAAAAAAAAEAAAAAAgABAAQAAAAAAAABAAAAAAYAAQAEAAAAAAAAAgAAAAAEAAEABAAAAAAAAAIAAAAABAADAAQAAAAAAAAEAAAAAAQAAwAEAAAAAAAACAAAAAACAAYABAAAAgAAAAgAAAAAAgAGAAQAAF0AAAAQAAAAAAIADAAEAACxAAAAEAAAAAACAAwABAAHID///+AAAAAABwAYAAQAGADAAAAAAAAAAAeAGAAEAGAAAAAAAAAAAAAAgBAABACAAAAAAAAAAAAAAIAQAAQBAAAAAAAAAAAAAACAEAAEAQAAAAAAAAAAAAAAgBAABAIAAAAAAAAAAAAAAIAwAAIMAAAAAAAAAAAAAACAIAABEAAAAAAAAAAAAAAAgCAAARgAAAAAAAAAAAAAAYAgAAGYAAAAAAAAAAAAAAGAIAAA6AAAAAAAAAAAAAABgCAAAFAAAAAAAAAAAAAAAYBAAABwAAAAAAAAAAAAAAGAQAADYAAAAAAAAAAAAAABgEAAD4AAAAAAAAAAAAAAAYBgABiAAAAAAAAAAAAAAAH//8Bg8AAAAAAAAAAAAAAAgAf/wBAAAAAAAAAAAAAAAQAAAAAQAAAAAAAAAAAAAAEAAAAAEAAAAAAAAAAAAAABAAAAACAAAAAAAAAAAAAAAwAAAAAgAAAAAAAAAAAAAAIAAAAAIAAAAAAAAAAAAAAGAAAAAEAAAAAAAAAAAAAABgAAAABAAAAAAAAAAAAAAAYAAAAAQAAAAAAAAAAAAAAMAAAAAH+AAAAAAAAAAAAADAAAAAAAQAAAAAAAAAAAAA///+AAACAA///////8AAAMBAH/gAAgAAAAAAAABAAADAAAIIAAEAAAAAAAAAMAAAwAACCAABAAAAAAAAAAgAAMAAAggAAQAAAAAAAAAIAADAAAIEAAEAAAAAAAAACAAAwAACAgABAAAAAAAAAAgAAIAAAgEAAQAAAAAAAAAIAACAAAIBAA0AAAAAAAAADAAAgAACAYB7AAAAAAAAAAcAAIAAAgCBjAAAAAAAAAABwACAAAIBgH4AAAAAAAAAAEAAgAAGDmBKAAAAAAAAAACwAIAAPHAnwQAAAAAAAAABjADAAfPgJDMAAAAAAAAAAQIAQA8BoDgMAAAAAAAAAAMBgYDwAaAAAAAAAAAAAAAGAGIHgAJAAAAAAAAAAAAAGAASeAAGAAAAAAAAAAAAABAAE4AAGAAAAAAAAAAAAAAIACAAAGAAAAAAAAAAAAAACAAgAAOAAAAAAAAAAAAAABgAIAAMAAAAAAAAAAAAAAAQAEAAcAAAAAAAAAAAAAAAEABgAYAAAAAAAAAAAAAAABABgAYAAAAAAAAA",
        "counties2": "AAAAAMAYAQQDGDkB/ARCYgAAAAEAPgEcAhjnAcRsPiEAAAABACMf8AYIoQCFqH4QAAAAAgAR/jAED4EAhTooEAAAAAIAcRAQBAMBAISdRCAAAAAEAeEQIAQHAgGEgfRgAAAABAOBEDACHMIGBYCUQgAAAAgCAZAcHvo2BgeAFH0AAAAIAwGYD/+GDAIHwBK5AAAAH48AiBwKBwwPBHATID////j5AIgQDwEICMQIPADIECAYAQGIEA+CHjB0GEAACBAgGAEHiBgQghP4PA6AAAgQIBgBnIgYEIEQijwDAAAIECAYA3CYC5CDEQcUAgAACCAgGAIAmA6QhiEA1AQAAAggEBgCAI4IsPwhACIIAAAIIBAfcgGH+PiH4YAhEAAACCAQE/4BBHgYhC/AURgAAA/4EBIHgQgMGJw7OEuYAAB4GBASBEIIBBiQIQ6O6AAAiBh/8gQiDgQRkCEBgFAAAAgfwJIEIwv+PxBBgIBwAAAIGYCSAjPYBzEYQIEDYAAAD/iAk4IPbwnxCEDBD4AAAAgQg5B+AgP3oQhgQNiAAAAIEJzQQ/4CPCH///xg8AAACBDQyEIEAgghmAxnwBAAAAgQUM/CBAIYIRgEODAQAAAcI/x8QgQEEEMcBA4IEAAAb/8HUEIIHBBPHgwOCCAAAIIOB9BCCOI38xN4BgwgAAACAgIQ/gvB/kIx2AQLwAAAAgICEdIPAMBCGBwG/sAAAAICA//SCAGARhycBn/AAAACAgCcE/gBAIYv/AbTQAAAAgIAhBAIAOaEIx4DhjAAAAICAIQQCAM9hCACARwPgAACAgCEEAgOAW///+J4BEAA///////8PAEcBgQ/zARAAACBAIAgFOcBBAgEIIQIIAAAgQCAIBOBgQQIBCCEGCAAAIEAgDAQgYEMCAYwzjAQAACBgEAQEIEDCAgGMc5gEAAAgIBAEBCAgw44Bj/hYBAA+ICAQD/wwLMO6Mvx0cAQAB+AgP8hkMB/C494f5GB0AAEYP/n4RHAwzmOODGbnrAABD+AEEMRf4PJngghH2jAAAcQgBBPEhwDCNOIITwIwAABEIAI8ZYEAvjghGPGD6AAgSBgB8CUGwfJ4MfPAnggAH8oMAKA/zCGBmBfdgFHMABj3BAUgEEwawZA8DoBgMAAwGMI/EDB4JkZLwAqAAAAAMAhj/xBoOGfIfgAFAAAAADAYNxkIaHx8zeAAGAAAAAAgMB4fjcxmzk8AAGAAAAAAIGAC+ZcI445pAAGAAAAAACBAD4jxDyQe8QAGAAAAAAAgwD4Y4JxuE/kAGAAAAAAAP/vkE4B4W9/JAGAAAAAAACE+x/4BjnF36QGAAAAAAAADIJjyA0PhPzE+AAAAAAAAA",
        "gauges": [
            ("01312000", 1, 4, None, [9.0, 12.5, None, None], [59.66, 82.58, 130.0, 242.0, 486.0, 997.2, 1410.0]),
            ("01315500", 4, 11, None, [8.0, 10.0, 11.0, 13.0], [333.6, 385.0, 559.0, 1060.0, 1950.0, 3466.0, 5070.0]),
            ("01318500", 8, 19, None, [8.5, 14.0, 17.0, 19.0], [505.4, 656.0, 1010.0, 2080.0, 4150.0, 6856.0, 9158.0]),
            ("01335754", 13, 33, None, [33.0, 34.0, 35.0, 37.0], [2820.0, 3006.0, 3760.0, 7050.0, 11600.0, 15800.0, 20300.0]),
        ],
    },
    {
        "key": "delaware",
        "label": "Delaware",
        "short": "Del.",
        "line1": (35, 1, "343434121022200233313220221134323432211"),
        "states1": "AAAAAAAIAAAAAAAAAAgAAQAAAAAACAABAAAAAAAQAAEAAAAAAB/gAP////4AED/gAAAAAwAQASAAAAABgBABIAAAAACAEAEYAAAAAIAQARgAAAAAwBABGAAAAABwEAflAAAAAFwwfcIAAAAAh2fxwAAAAAEBvAMAAAAAAICAHAAAAAABgQBgAAAAAAEBA4AAAAAAAQJ8AAAAAAAAh4AAAAAAAACAgAAAAAAAAECAAAAAAAAAIIAAAAAAAABBAAAAAAAAAYEAAAAAAAAPAQAAAP////QBAAAAhNgAFAIAAACPCAAcAgAAAJiEABgEAAAA4OYAFAgAAACAvwAUEAAAAA",
        "counties1": "H/x9JHT5GMgfREnln8v4nxBEf7YYy1h/EEQkjB2b/O8QRCSEP9/+WP////7wsQv4CEIgh5iRCSgIQjCEkZMN7f/CEPyJn3d7iaP/td+98e/4/gll+d/TXbxyB5Yx/k/lJ+kHH08+fcImPL2Zi+/hwOQm/b1duAcAPCP97qbwGABkR9ct19BgAEf//D2v0YAAyel01a/WAADpKusKv/gAADt/ORz2gAAAH8f323iAAADiPj4s/oAAAGJq5GfTgAAARFOiR4iAAABE0SLPSQAAAP////bpAAAAnPuUn3kAAACfalbbjgAAAJzeX//GAAAA9Pb9nnwAAAD9/69y0AAAAA",
        "line2": (70, 2, "3434323434342102271141222120200023333233123232220022201112144334322434332322201212"),
        "states2": "AAAAAAAAAAAAAABAAAAAAQAAAAAAAAAAAAAAgAAAAAEAAAAAAAAAAAAAAIAAAAABAAAAAAAAAAAAAACAAAAAAgAAAAAAAAAAAAABgAAAAAIAAAAAAAAAAAAAAQAAAAACAAAAAAAAAAAAAAEAAAAAAgAAAAAAAAAAAAADAAAAAAEAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAP//+AAAP/////////4AAACAID/+AAAAAAAAAAACAAAAgAAAggAAAAAAAAAAAYAAAIAAAIMAAAAAAAAAAAFAAACAAACBAAAAAAAAAAAAIAAAgAAAgQAAAAAAAAAAACAAAIAAAIDAAAAAAAAAAAAgAAEAAACAYAAAAAAAAAAAIAABAAAAgCAAAAAAAAAAACAAAQAAAIAgAAAAAAAAAAAQAAEAAACAIAAAAAAAAAAAHAABAAAAgCAAAAAAAAAAAAcAAQAAAIBgAAAAAAAAAAABAAEAAAGHnAAAAAAAAAAAAsABAAAHOATAAAAAAAAAAAQwAYAAPdQCgAAAAAAAAAAMDACAAcCkAwAAAAAAAAAACAYDAA8AqAAAAAAAAAAAABABhAD4AJgAAAAAAAAAAAAgAGYHgAGAAAAAAAAAAAAAQAASeAAGAAAAAAAAAAAAAGAAMYAAGAAAAAAAAAAAAAAgACAAAOAAAAAAAAAAAAAAQABgAAMAAAAAAAAAAAAAAEAAQAAMAAAAAAAAAAAAAACAAMAAcAAAAAAAAAAAAAAAgAGAAYAAAAAAAAAAAAAAAIADAAYAAAAAAAAAAAAAAADABgD4AAAAAAAAAAAAAAAAYAT/AAAAAAAAAAAAAAAAACAD0AAAAAAAAAAAAAAAAAAwABAAAAAAAAAAAAAAAAAACAAQAAAAAAAAAAAAAAAAAAQAEAAAAAAAAAAAAAAAAAAEACAAAAAAAAAAAAAAAAAAAgAgAAAAAAAAAAAAAAAAAAMAIAAAAAAAAAAAAAAAAAAOACAAAAAAAAAAAAAAAAAAOAAgAAAAAAAAAAAAAAAAAGAAIAAAAAAAAAAAAAAAAABAAEAAAAAAAAAAAAAAAAABwABAAAAAAAAAAAAAAAAAPwAAQAAAAAAAAAAAAAAAAEwAAEAAAAAAAD////////+MAACAAAAAAAAQBAWAAAAAmAAAgAAAAAAAEAw4cAAAAJAAAQAAAAAAABAPICAAAACIAAEAAAAAAAAQGcAwAAAAmAACAAAAAAAAEPAQEAAAAJAAAgAAAAAAABCAHAgAAACIAAQAAAAAAAARABYIAAAAjAAYAAAAAAAAFgARDwAAAIQAIAAAAAAAABgAIMmAAACCACAAAAAAAAAQACBxgAAAgQBAAAAAAAAAA",
        "counties2": "AYP/sCPhCBAcGCfDAIDgQQH8IOA+QQQQbhn8h4GAIEEBcCAgMEP8EYMfoIR/ACBjAQAgIBBDRBYA8CCMAwBB3wEAICAQR0QYAIAgjwPAd/cBACAgH/xHkACAIQWQwHXeAQAgIARQQPABgEEFf4BsngEAICAEEEAQAONBDCLgMDEBACAgBBBAEAG+gwwAIBDgAQAgIAQQQBAGAPP///4TQP/////////4DACeAYDP/EAAQB8IBABALDMAggMAwgggAEAQCAQAQCTAwIICAIIMIABAEAgEAEAnAICCAgDDBCAAQBAIBgBAIYCAggIAQxxwAEAQCAIAQCCBAYIPAOP/EQBAEAgCAEAggIGDuQGzB4r///AIAgD/8IBRgqMZDx6OQECICH/8gzHAb4Lj7gf4hMCAjA/5H4Ixw8GOYccHCJrBgIf4AIEGMn4B9mdBAhjx/YDyDACBPjI8AYY0YQIZwGeAEgQAQ+M8BAE+PCCGFjDGYBICADcBOAsD5ngQjPgRBB/UgwAaAb8Qw4KYEPdQCgQc/YGAMgD5MDSCiA/CkAwEEALAh+EBgeBIzMh8AqAABBAEME6hAoDAjlBPgAFgAAwQBBhzoYJAofPYeAADAAD8EAQNwxCGITE4ycAADAAABBAMBsPw3EOaHM8AADAAAAfwEAC/EXBsjDa6AADAAAAEECAD4R8IcRA/sgAHAAAABBBgDwMOBcEzJ/IAGAAAAAgf/PmCeANCT72TAGAAAAAYMJ+h9+AMMoTP0QGAAAAAkCCYJx8gFBME7nEOAAAAAKBhGEw4EeMPhLvhcAAAAABgQQiIzC8BiIhfv4AAAAAAeMIImYREAFCIjMAAAAAAAB2CGZYIQgDgzxhAAAAAAAAHAhDsDkEAmDYwQAAAAAAAAcbwOX4jwYwRQEAAAAAAAAJ98DfCPmOGGYBAAAAAAAACDBg4BzAWQY5gQAAAAAAAxAgOSA7ADGBPsoAAAAAAALwYC0wwYBA68Q+AAAAAAAAYEBCEeDAQH8EAgAAAAAAAEBAQh4gIEDWAgQAAAAAAACAQIQIECBBlQIEAAAAAAAAgECECBAQQx2BBAAAAAAAAMBAiAggCIP2gQQAAAAAAADAQQgIIAiEwuGIAAAAAAAD////////+OERiAAAAAAAAQNB2BIEggi4sYgAAAAAAAEC474hBEMJjE0QAAAAAAABBvoiIIhBCZKDEAAAAAAAAQW+YyBIIIkvAOAAAAAAAAEPQ0NgSBCJQoBgAAAAAAABGMHGwIvJ+MBAQAAAAAAAATCBZMH7SwnAcEAAAAAAAAF9ARz3x0wPQF+AAAAAAAADxwIJnGPI+CCCAAAAAAAAAeLCfxgjecgxhAAAAAAAAAA",
        "gauges": [
            ("01421900", 2, 4, None, [7.0, 8.0, 9.5, 10.5], [17.62, 27.98, 68.7, 147.0, 295.0, 523.6, 741.8]),
            ("01426500", 6, 13, None, [9.0, 11.0, 13.0, 15.0], [243.0, 286.0, 525.0, 671.0, 1060.0, 1960.0, 2650.0]),
            ("01427510", 10, 22, None, [9.0, 12.0, 13.0, 14.8], [918.0, 1030.0, 1310.0, 1980.0, 3690.0, 6290.0, 8710.0]),
            ("01428500", 13, 26, None, [15.0, 17.0, 22.0, 26.0], [1010.0, 1160.0, 1460.0, 2240.0, 4110.0, 6810.0, 9340.0]),
            ("01434000", 16, 33, None, [16.0, 18.0, 20.0, 21.5], [1440.0, 1600.0, 2140.0, 3770.0, 6300.0, 10400.0, 14360.0]),
            ("01440200", 19, 39, None, [20.0, 21.0, 23.0, 25.0], None),
            ("01446995", 22, 46, None, [20.0, 22.0, 26.0, 30.0], None),
            ("01461500", 26, 54, None, [17.0, 18.0, 20.0, 24.0], None),
            ("01467200", 31, 65, [-0.42, -0.01, 0.56, 0.89, 1.23, 1.58, 1.84], None, None),
        ],
    },
    {
        "key": "susquehanna",
        "label": "Susquehanna",
        "short": "Susq.",
        "line1": (39, 1, "2323433224564353221011233243442323211111211"),
        "states1": "ABAAAAAAIwAAYAAAAAA/gACAAAAAACf/AwAAAAAAQAAcAAAAAABAAOQAAAAAAEAAhAAAAAAAwACEAAAAAACAAIf////4AP//gAAAAAgAgAmAAAAABACACYAAAAAEAIAIgAAAAAIAgBiAAAAAAwCAGYAAAAABgIA+gAAAAAFgg96AAAAAAhk/DoAAAAAEBeAYgAAAAAQEAGCAAAAABAgDgIAAAAAICAwAgAAAAAgR8ACAAAAABB4AAIAAAAAEBAAAgAAAAAMEAACAAAAAAIQAAIAAAAADCAAAgAAAAAwIAACAAAAAMAgAAP/////wCAAAAQ9wAKAQAAABNxAAoBAAAA",
        "counties1": "ABP8qJ+N6iIAMmvvi/8qEgDCbmT4nz//A2ZvfJiaaIwcP/nll9/ZxOQhGLecOl7HhCEQ/vBGX8eEIRCSEHyWwof////7h///ghCIQh5kiEn+EIhCFGSIS4IQiEP2RPv/h/+P/vZ8753583xnv8ffiol5xD55x7J3m0/iHH1s8f7+TFL2Zl1/DpvIS/bnffgwk3hH/62/wMDyyI9tvf5DAJ6P/3D+/UwAs5PU013/cADD0l/sO//AALR2veR39AAAnD+fX09kAACPxNy5p7wAAIvMtxEexAAA+Immmz5oAACIiaSKP2gAAP/////66AAAfTvmOq1wAADJN7lLfjAAAA",
        "line2": (78, 2, "232223243433433242124465644345432542222111010201202232434224344344343223231231210131001211121121"),
        "states2": "AAACAAAAAAAAAAAACAIAAAAAAQAAAAAAAAAAAAgGAAAAAAIAAAAAAAAAAAAIBAAAAAAMAAAAAAAAAAAAD//AAAAAMAAAAAAAAAAAAAg///8AAMAAAAAAAAAAAAAIAAAAAAMAAAAAAAAAAAAAEAAAAAAMAAAAAAAAAAAAABAAAAAAEAAAAAAAAAAAAAAQAAAAAHAAAAAAAAAAAAAAEAAAAAeQAAAAAAAAAAAAACAAAAD4EAAAAAAAAAAAAAAgAAAAQBAAAAAAAAAAAAAAIAAAAEAQAAAAAAAAAAAAACAAAABAEAAAAAAAAAAAAABAAAAAQBAAAAAAAAAAAAAAQAAAAEAQAAAAAAAAAAAAAH//+ABAH/////////+AAABAID/+QAAAAAAAAAAAgAAAQAAAgkAAAAAAAAAAAGAAAEAAAIJAAAAAAAAAAAAQAABAAACCQAAAAAAAAAAAEAAAQAAAgkAAAAAAAAAAABAAAEAAAIFAAAAAAAAAAAAQAACAAACAQAAAAAAAAAAAEAAAgAABgEAAAAAAAAAAABgAAIAAAYBAAAAAAAAAAAAOAACAAAGAQAAAAAAAAAAAA4AAgAABgEAAAAAAAAAAAACAAIAAAYdAAAAAAAAAAAABgACAAAc4QAAAAAAAAAAAAWAAgAA/0EAAAAAAAAAAAAIYAEAD4ahAAAAAAAAAAAACBgGAHwDIQAAAAAAAAAAABAGCAPgAuEAAAAAAAAAAAAwAYg+AAYBAAAAAAAAAAAAwABJ4AAYAQAAAAAAAAAAAIAARgAAYAEAAAAAAAAAAABAAIAAAYABAAAAAAAAAAAAQACAAA4AAQAAAAAAAAAAAIAAgAAwAAEAAAAAAAAAAAEAAQAAwAABAAAAAAAAAAABAAMAAwAAAwAAAAAAAAAAAYAGAAwAAAEAAAAAAAAAAADADAHwAAADAAAAAAAAAAAAQAn+AAAAAwAAAAAAAAAAAEAHwAAAAAMAAAAAAAAAAABwAEAAAAADAAAAAAAAAAAACABAAAAAAwAAAAAAAAAAAAgAgAAAAAEAAAAAAAAAAAAEAIAAAAABAAAAAAAAAAAABgCAAAAAAQAAAAAAAAAAAA4AgAAAAAEAAAAAAAAAAAAcAIAAAAABAAAAAAAAAAAAcACAAAAAAQAAAAAAAAAAAMAAgAAAAAEAAAAAAAAAAACAAQAAAAABAAAAAAAAAAAzAAEAAAAAAQAAAAAAAAAAzAABAAAAAAH//////////4gAAQAAAAAAAAQAAQAAAAEQAAEAAAAAAAAEAR74AAABEAACAAAAAAAABAPYMAAAARAAAgAAAAAAAAQEcBgAAAEQAAQAAAAAAAAEOAQIAAABkAAEAAAAAAA",
        "counties2": "AAADBAngRICGQQDz+YIMBgAAAQf4QESAg/uA0wiGBAQAAAEECEBE4IBM548IhAYEAAAGBAhH5B+AwF5+DIICAwAAGAQITCQQ/4BDwg////8AAGAECGwmEICAQYIJgGMBAAGYBBj4J/CAgEECGIAh4AAGBg45/z8QgICDBBDAYHAAGAd3/wGkEIEDgwTx4CAQAHAFwQEBZBPBHEL/sRvAEAeQBAEBAIQ+w/A3xCEcwBD4EAQBAQCEdMPADAQhwOA7QBAEAQEA//RzABAEYURgG0AQBAEBAEMEfwAwCGJ/4BZAEAQBAQBBBAIAHmhCGPAIQBAEAQEAQQQCADfQQwAQCEAQBAEBAEEEAgDAHP///wlAH/////////+BgBPAYCP/QAQBAIBAIAQChmAQQMAggkAEAQCAQCAEAngYEECAIIJ//AEAgEAgBAIwEDDAgDCCQAQCAIBAEAQCEBAwwIAQjkAEAgCAQBAEAhAgIIPAKP9ABAIAgEAQD/4YGCDuxn+HQD///4BAPwgiGA/gqJ/B/0BBAgJAf/P4QjgYIJjxwYT/gQICI8AYGEIu8D+YccGEQIH2Ah5gCBPCQ4AgidhAjECBngOQIAgeI8CAM4UIIYxAhxmAkBAEcBKBwD6dBCc7QIQQQKAYA+ATg3Bg5wQ/3ECIEH/kDAGgD+Yc8GID4ahA+BBAHgR+MBg0DpGiHwDI/wwQwDGCZxAwHBmSE/gAuEEMMMAgw/0QKBwb8h+AAIBCD/DAIG4ZiGQyLzN4AAMAQg7QgGAyH43MM2OT4AAMAMIIH4DABPmXBHHGnkAAMAB+CBCBgB8Y8IeSB7RAAcAAQggQgQB8EOBeJ2T+QAYAAEIIIP/3yBOAPE334mAYAABD/ECG/Q8uAMZ4mdogYAAAwg5BBkEx8gFBUJ/eI4AAAMQSgQxiQ8GOMfCTdCwAAADICQMIJM5i8BmRC//wAAAA8AjiCES4JGAFEbOQAAAAAMgYNhBN4EQwCh/iEAAAAADGEAwQh8BmGAmGRBAAAAAAw5AHPoGPojwQwjwQAAAAAEDwCeeBuDPmOGE4EAAAAADAYAggY8ArAWQZziAAAAAAQHmQQFpAzAGGD/HgAAAAAEBu8EDGY4cBA34gYAAAAADfYGBAhD6AgQPYMCAAAAAAY8BAQYgwQIEE+BAgAAAAAEBAgEGIMEBBDGQYQAAAAABAQIBBEBBAIRz2GEAAAAAAQEDAwxAQQCIzEwhAAAAAAP//////////4wiIQAAAAAAwEQEDYCYJCETFiEAAAAAAPiECR7xEEQxEYmiAAAAAAEEhBuZ8QhGEZFQ4gAAAAABA4QW8RsEgxiy4DwAAAAAA+MEPR4aBIEItFAMAAAAAAA",
        "gauges": [
            ("01500500", 5, 11, None, [9.0, 11.0, 13.0, 14.5], [181.0, 274.0, 502.5, 1080.0, 2242.5, 3814.0, 5126.5]),
            ("01503000", 11, 24, None, [10.0, 12.0, 15.0, 20.0], [437.2, 706.0, 1180.0, 2460.0, 4750.0, 7962.0, 10900.0]),
            ("01513831", 15, 31, None, [29.0, 30.0, 32.0, 33.0], [934.4, 1294.0, 2160.0, 4470.0, 8960.0, 16000.0, 20780.0]),
            ("01531500", 18, 40, None, [14.0, 16.0, 18.0, 25.1], [1260.0, 1664.0, 3040.0, 6470.0, 13500.0, 24000.0, 33100.0]),
            ("01533400", 21, 45, None, [25.0, 27.0, 31.0, 40.0], [1391.5, 1820.0, 3330.0, 7355.0, 15600.0, 27300.0, 37770.0]),
            ("01536500", 24, 54, None, [10.0, 22.0, 28.0, 30.0], [1930.0, 2520.0, 4510.0, 9050.0, 17300.0, 30360.0, 42160.0]),
            ("01538700", 28, 63, None, [16.0, 19.0, 22.0, 28.0], [2030.0, 2604.0, 4870.0, 10100.0, 19200.0, 32400.0, 43780.0]),
            ("01554000", 31, 69, [6.13, 6.5, 7.49, 8.93, 10.75, 12.73, 14.08], [20.0, 24.0, 26.0, 34.0], None),
            ("01570500", 36, 79, None, [11.0, 17.0, 20.0, 23.0], [5590.0, 7134.0, 11500.0, 23500.0, 44700.0, 71440.0, 95320.0]),
            ("01578310", 42, 94, None, [21.5, 23.5, 24.8, 28.5], [5980.0, 7030.0, 13900.0, 26800.0, 48200.0, 80180.0, 106000.0]),
        ],
    },
    {
        "key": "potomac",
        "label": "Potomac",
        "short": "Potomac",
        "line1": (9, 23, "777676667600076767676076176007010002410213000122201020012222423322207012110001111"),
        "states1": "//////////4AEAgOAAAABAAQGHPAAAAEABAeQMAAAAQAEPOAYAAABAAx4CAgAAAGADEAOBAAAAIANgAkPAAAAgA4AGImAAACADAAQaIAAAIAAABARgAAAgAAAIADAAACAAAAgAHAAAIAAAEAAGgAAgAABgAANAACAAAIAAAKAAIAAHgAAAwAAwAAsAAACAABAACAAAAIAAEAAQAAADAAAQDBAAAAYAABAOIAAADAAAEBGgAAAIAAAQEMAAAA2AAAAQAAAAB4AAACAAAAAEwAAAYAAAAABAAADAAAAAAHAAAIAAAAAADgABgAAAAAADAAEAAAAAAAEAAQAAAAAAAMMw",
        "counties1": "//////////4CEGg+BkCQhMIQXHfEgRDEJBDfRMRhGEYcEPfMaBIMIpwh6GjoEgQi9CMYOZAicv5EJxAlPH9Tg127oGIv0dMPY3zgR6MIejLCHF5MRgTGYsIIgazGAwPGd4yB9oOHg4o8+ME/wexHmjAcRjI7NkRyMDbIJB7+T1ogIXhrFtxMi+IgsbkbCGgSg+CLsY7IeC6GwIchyHtLm0TBBnpHbMxhROEEXGXAzAN5mhNMLMDEB+ENuMY4ySQEgQRg5/j6EggCCCEnHssOCweYGzwj7QMcDfDE+ENvgTgIMMwfghrhoDgwOFDmPzDA8DgwkDwS2IEYRjgsHjpvNw",
        "line2": (18, 46, "77077777667666667606671700767776767676766006706050107057616061076000012100617123417220220132001001210232210010102200011212222234223433232221200707021211110100000121111010"),
        "states2": "AAAAAAAAAAAAAAAAAAAADP////////////////////gAAAIAAAAA+AAAAAAAAAAQAAACAABAB4QAAAAAAAAAEAAAAgAA4B8E4AAAAAAAABAAAAIAAMA4A/AAAAAAAAAQAAACAADgMAAwAAAAAAAAEAAAAgABHjAAcAAAAAAAABAAAAIAAgPAADAAAAAAAAAQAAACAOQAAAAcAAAAAAAAGAAAAgCUAAQACAAAAAAAAAgAAAYCiAAGAAwAAAAAAAAIAAAGAwAABYAGAAAAAAAACAAABgQAAAhABgAAAAAAAAgAAAYIAAAEIAcAAAAAAAAIAAAGGAAACBgD4AAAAAAACAAABnAAAAgMBjAAAAAAAAgAAAaAAAAQAgQYAAAAAAAIAAAHAAAAEAEMDAAAAAAACAAABgAAACAAyAwAAAAAAAgAAAAAAAAQADgIAAAAAAAIAAAAAAAAIAAQGAAAAAAACAAAAAAAAEAAAAgAAAAAAAgAAAAAAABAAAAOAAAAAAAMAAAAAAAAgAAAB+AAAAAADAAAAAAAAQAAAAAwAAAAAAQAAAAAAAEAAAAAEEAAAAAEAAAAAAAGAAAAAB6gAAAABAAAAAAAGAAAAAABMAAAAAQAAAAAADAAAAAAAZAAAAAEAAAAAABQAAAAAACIAAAABAAAAAAAgAAAAAAAUAAAAAQAAAAAEIAAAAAAAHAAAAAEAAAAACkAAAAAAABgAAAABAAAAABlAAAAAAAAQAAAAAQAAAAAQgAAAAAAAEAAAAAEAAAAAIAAAAAAAADAAAAABAAAAACAAAAAAAABgAAAAAQAAAABgAAAAAAAAwAAAAAGAAAAAQAAAAAAAAIAAAAAAgAAAAIAAAAAAAAMAAAAAAIAAGACAAAAAAAAEAAAAAACAABYAgAAAAAAACAAAAAAAgAAxAQAAAAAAAAgAAAAAAIAAIQEAAAAAAAAQAAAAAACAACDCAAAAAAAAEAAAAAAAwAAgMgAAAAAAABAAAAAAAAAAYAwAAAAAAAAYMAAAAAAAAEAAAAAAAAAAGOgAAAAAAADAAAAAAAAAAA+IAAAAAAABgAAAAAAAAAAMEAAAAAAAAQAAAAAAAAAAABgAAAAAAAEAAAAAAAAAAAAMAAAAAAAGAAAAAAAAAAAABAAAAAAADAAAAAAAAAAAAAQAAAAAABAAAAAAAAAAAAADAAAAAAAQAAAAAAAAAAAAAP8AAAAAEAAAAAAAAAAAAAABAAAAABAAAAAAAAAAAAAAAYAAAAAwAAAAAAAAAAAAAADAAAAAIAAAAAAAAAAAAAAAQAAAAGAAAAAAAAAAAAAAAEAAAABAAAAAAAAAAAAAAAAwAAAAgAAAAAAAAAAAAAAADAPAw",
        "counties2": "ACAA/wDACAQABAAgAAJwDP////////////////////gAAgIACAAG+AAMEACCAIAQAAQCAAhAD4QAGBABAgCAEAAEAgAQ4B8GoDBgAQMAQBDwCAIAEMA4H9AgMAEBAGAQCAgCACHwMDhwYBgCAQAgGAQQAgAjHjAgcEAEAgGAEBgDEAIAQhPgYDBAAgIAYBAYAaACAOQgOEAcQAEEADAICADgBgC8QAxAOIABBAAwCAjDoAQCiMAHgCyAAgQAEBgIfiAEAwCABYDGgAIEABgYCCAgBAQBgAjBhoAH5D8ML/ggIAQIAQAEIwUADj4hBEAIICAEHwIACBID4DwDoQWACSDgBHDEAAgOBjDiAKELAA4zmcSAaAAQBAQbgwCRBgP4HAY3ABgAEAcMBgHAfQQGCCAEDvAWACBoiAwAYGfECAhgDAOwIYAQWHgIADDAOAgIQAgAICBgIHgQGAAYgAgQGOAIAGBAH0BQIBAADwAIYDiwDABgQACcEGAIAAsADsBIGBQAMIABtDBAB+ALAA7ATA4XACCAAWI8gADwEMAKgIwCIfBgwAMH58ABEFBgG4CMAuAfwEAGBAI8AR6gIBABDAcAAOBgGAYGA4IBMCAQHQwEAAOwIDAGDAHkA5gQIBcMDAAPGEBQDAwBGASIECJxDAwACAzQgAgYAxhi0BAlwQQIAAgCuIAQLAIYY/AwZYCHCAAMAS0APCIBDgNgIHgBhAgABADnAGbCAQ8AwDhAAwR4BggAQ4FBggCPAEA4QAYEgA0YAMHDggMAnMDAP8AEBIAPcACAYwQAwEgxgCBAAvyAGeABgDYGAUBAG74gR4EMQBggAQAeBAIgIA5hoEjiBkAYIAIADAYEICAMQHBIOgZAEGACAAgJCCAcEABQcAwCIBBYAgAYGZAQGzAAcGAABiBgxAYAGDDgECHgADAgAB4gwIQEAgwgQAhAYADwIAAyLwCDDAMGICAMgEABEDAAI1AAgNsHg/AQB4BAAwwQACBgAYAwx4DwGAOAYMIDEAAgwAEAIGYAkBjmwCPkAIgAIIADAEAYAJATm+B+ZgCIAEAABgBADAMYHgZcUEIAXACAAAQAgAIODBgMHsBDAHQBiQAEAIABjAdwCA+AcQAGAZYAGgCAANsFwBAB+HIAAgGgADHjACAw5AAwAzjaAAIDwABAPADwIBwAYAYWj8ADBgAAQA8AoEADHEAEA4B8AQQAAEACAGBAAOPACAPEBAEIAABABgAHQACAMBgGfwYAiAAHgAcAC8BhgAgwBBmDAPAA/IAFgAeA4QAEIAIIQQCAAQEACEADgMIAB0ADiMOAgAABABAwBIAHgAGAAYx8wIAAA8AQGALABGACYAeCHDEPAw",
        "gauges": [
            ("01605500", 3, 8, None, [6.0, 7.0, 9.0, 11.0], [23.8, 28.5, 38.2, 66.9, 138.0, 251.2, 392.2]),
            ("01606500", 11, 22, None, [12.0, 14.0, 15.0, 17.0], [78.58, 95.08, 146.0, 298.0, 671.0, 1212.0, 1920.0]),
            ("01608070", 15, 29, None, None, None),
            ("01608500", 22, 44, None, [12.0, 15.0, 19.0, 25.0], [115.0, 139.4, 233.0, 496.0, 1140.0, 2216.0, 3474.0]),
            ("01610000", 26, 53, None, [22.5, 25.0, 30.0, 37.0], [458.0, 508.4, 707.0, 1280.0, 2930.0, 5802.0, 8458.0]),
            ("01613000", 30, 66, None, [21.0, 25.0, 33.0, 35.0], [542.2, 605.0, 834.0, 1550.0, 3570.0, 6796.0, 10000.0]),
            ("01618000", 40, 88, None, [8.0, 15.0, 22.0, 25.0], [916.4, 1010.0, 1370.0, 2430.0, 5350.0, 9652.0, 14280.0]),
            ("01638500", 46, 99, None, [11.0, 16.0, 20.0, 27.0], [1480.0, 1680.0, 2180.0, 3900.0, 8180.0, 14900.0, 21680.0]),
            ("01644148", 49, 106, None, [12.25, 15.0, 17.0, 24.0], None),
            ("01646500", 55, 118, None, [5.0, 10.0, 12.0, 14.0], [1350.0, 1580.0, 2307.5, 4350.0, 9422.5, 16170.0, 23140.0]),
        ],
    },
    {
        "key": "james",
        "label": "James",
        "short": "James",
        "line1": (8, 1, "23233233223220701421221770001200120076706600606007110701201761200100021210200027101027021210200"),
        "states1": "ARoAAAAEAAABBgAAAAJgAAMAAAAAA6AABgAAAAAAMAAGAAAAAAAQAAwAAAAAAB4AGAAAAAAAA8AQAAAAAAAAYDAAAAAAAAAgIAAAAAAAABhAAAAAAAAABkAAAAAAAAABgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        "counties1": "YRqMcIOCBIgBBkg4z8LoTAEEMHhxd+gsBggYzsI8NBwHGA13BA80AgnwYxwEG2wCGDDiA/gwz8MQMG4CPCC8YfA4HDIDQMwhIGYMNgGAS1lwwxIPgWDl587A4hjBEeJjgcCCEHIesjM2m8EwigzfeTsOQf2PBmPFEQxxh8nzG0ZhCBcCfJHFP/DQDAZ2/NK/EDgOBMH7PushZxsM8TiKnmLDsQnaGeeQ5ANg2wwPPZA6A5DzCAIbiOwDEK3Fj/tEfAYJAXveeecWBAeBB3x8320IBOEMCEOo0Y6ENwgJwZ/A+fgdiA9zUMDwWhDoDB47gMBOMD84HBwAgIMgIeB0PQ",
        "line2": (17, 2, "31232323232343233432203314222227077001242421221272032100607707002712121072011210060076706600065066000606005760000721001010770102210010667111001010000117122220210102010070227011100001270012212110112007"),
        "states2": "AAEDBAAAAAAAAAAQAAAAAAABAOwAAAAAAAAAEAAAAAAAAgAYAAAAAAAAABgIAAAAAAIAAAAAAAAAAAAYNAAAAAAGAAAAAAAAAAAACcQAAAAACAAAAAAAAAAAAA+IAAAAABAAAAAAAAAAAAAACAAAAAAYAAAAAAAAAAAAAAYAAAAACAAAAAAAAAAAAAABAAAAADAAAAAAAAAAAAAAAQAAAABgAAAAAAAAAAAAAAGAAAAAgAAAAAAAAAAAAAAA4AAAAYAAAAAAAAAAAAAAAD/gAAEAAAAAAAAAAAAAAAAAIAABAAAAAAAAAAAAAAAAADAAAQAAAAAAAAAAAAAAAAAYAAIAAAAAAAAAAAAAAAAADAACAAAAAAAAAAAAAAAAAAQABAAAAAAAAAAAAAAAAAADAAQAAAAAAAAAAAAAAAAAAIAIAAAAAAAAAAAAAAAAAABgEAAAAAAAAAAAAAAAAAAAECAAAAAAAAAAAAAAAAAAAA1AAAAAAAAAAAAAAAAAAAADgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        "counties2": "mAEDBYDgcwCADEAQABDAQAABAOzAkA8AQAXAGAAQcCAAAwA4MOAHAGACwBgIIBggAAIAMBzADQBg7uAIHEAEEAAGACAOAAkAY5vwHPRABhAACABAA4AQwDYCLheMIAJ4ABAAQAHAYGA4BAswCCAB2AAYAIAAIMA4wAwHIAYQAAgAGACAABCwHYAIAvQPEAAMADwAgAALDjYAEAB+CRAABABDwwAIBgOgACAAhxkwAAQAgDwAPAQA8ABAAQXY4AAEAYAPAGwIABx4QAEAeH/gAgEAAwA4CAADj4ACADBAIAIBAAIACIgAAgPgBABOoDADAQAGAAHoAAYAGAgAj5AYAT4ABwABcAcEAAQQAMGIDAHyAATAAOAHCAAEEABAhBwBBAAIYABgDhgAB6AAcIYjAQQAEDAAkAA+AAHAABDDoYEfABAIAJAAI4ACcADwYODiMIAgBgGIAEDgAjAAmCA4MmCAQAMyCADAMAIYA4wQCA9AfMAAzAQAgBwCBwfMCAgDgALgAIAEAQAnBACEyAQIAgABQACAAgIAIYQAiEcEHwIGAEACwAICAEDEANBhAiGBBhyDh/ABBABAhADwIflAQQYngygQAf8AgMgAGBANwGEEQQBwEAHBwMA4ABwQB2BhAMGAcBgAQHtgD+AODAQwQAGBgGAGAcAOIIBfAwOCEDAPAQAgAgMABjFAgQHgwxgfHACAwAEeAAQdIIGAYGEMAGQAYYABEAAIFxxAgGAxh4CEADPAATAACCADT8DaGOB/AgALQACQABAgAP65D+y4AAIABiAA8AAQIAE4RgN8js8EAAw0AMgAICADDMEAaIOwBAEQHgGEAEBGBgTAgAzBAAgC8AMCBABATYgGgcAGwQAYBGAMhgIAgfB4A4E4P4EAcAgABNwBwYMAcADDB2EBgOwQAAJ0AGECAGAAbgHAgECCCAAG5AAzBgBAADQBw8BABxAAB4IAKgYAMAAMAMZgIB3wAA4CAEWaAAgAL/BEIBBoYAAIAQDAc4AbgDceQ5AQLOAAGAEAgAL4D+H8GkPIHx6gABAA4wACDwD52AdD5uADOAAwAC8AAgHjH6AF8DOAAE4AIAARwAIAHAEQDA3YHxyDAGAAEGACAHAA4BgGZGA3AYBAACA4AgDAAEBgAMSAwgDA9gAgBA4AgABAwADCz0AAwNtAQAT6AIAAQeAB4fBgAGGB4EADgQCAAEc4ATGAIAAvgbOAAQDAQABMBgMRACAANgAtgAMAbEAAcAIMCYNAACIAIIQCAB5wAGADMAROwABAAED8AgAHzAGAAeACOIAAQABACgIABAQCAAEgA/EAAEAAQAYGAAQCDAAGMAvxAABAAEACBAAEA/AADBAU0Q",
        "gauges": [
            ("02011400", 7, 16, None, [8.0, 10.0, 14.0, 16.0], [18.3, 20.33, 27.4, 55.5, 125.0, 227.4, 361.7]),
            ("02012500", 10, 25, None, [9.0, None, None, None], None),
            ("02013100", 13, 29, None, [14.0, 17.0, 20.0, 23.0], [189.0, 210.4, 265.0, 328.0, 496.0, 953.2, 1594.0]),
            ("02016500", 17, 39, None, [12.0, 16.0, 22.0, 25.0], [355.2, 380.0, 450.0, 673.0, 1270.0, 2284.0, 3722.0]),
            ("02019500", 23, 56, None, None, [469.0, 500.0, 619.0, 1050.0, 1970.0, 3558.0, 5610.0]),
            ("02024750", 28, 67, None, None, None),
            ("02025500", 31, 74, None, [18.0, 22.0, 24.0, 28.0], [656.4, 716.0, 918.0, 1530.0, 3010.0, 5166.0, 8310.0]),
            ("02026000", 40, 93, None, [15.0, 16.0, 18.0, 22.0], [739.0, 832.8, 1120.0, 1790.0, 3590.0, 6206.0, 9300.0]),
            ("02029000", 50, 114, None, [11.0, 20.0, 22.0, 24.0], [922.2, 1050.0, 1410.0, 2540.0, 4800.0, 8010.0, 11780.0]),
            ("02035000", 57, 130, None, [15.0, 20.0, 23.0, 26.4], [1150.0, 1260.0, 1730.0, 3210.0, 5920.0, 9830.0, 14740.0]),
            ("02037500", 67, 149, None, [9.0, 12.0, 15.0, 22.0], [1120.0, 1223.0, 1700.0, 3315.0, 6450.0, 10670.0, 16185.0]),
        ],
    },
    {
        "key": "connecticut",
        "label": "Connecticut",
        "short": "Conn.",
        "line1": (35, 1, "03423223322323222231232222322121"),
        "states1": "AAAAAB0AAIAAAAAALAAAYAAA///oAAAgAAMAgGgAABAABACASAAAEAAYAIBIAABgACAAgEgAAIAAwACAiAADAAEAAQEEAAwAAQABAQQAGAACAAEDBABgAAIAAQIEBUAABAABBgQagAD8AAGEBCAAAAAAAIQEQAAAAAAAhASAAAAAAACMBwAAAAAAAIgDgAAAAAAAiAcAAAAAAAD//gAAAAAAAJ/xAAAAAAAAgAEAAAAAAAEAAQAAAAAAAQABAAAAAAABAAHgAAD//AH/4CAAAAACAQCwEAAAAAIBAJAQAAAAAQEAmHAAAAABAQCZ4AAAAADBA+fgAAAAAWEd5GAAAA",
        "counties1": "AAAAAA2YTIAAAAAAPMnc4AAA/9/uTxwgAAPJ6OpiPBAABMmfy2d4EAAIxe8pP+wgABBHv8z8RcAAcF67zMbGAAGcWOd87YgAAg/5Lz+68AACGzETHfpgAAQzO+5+H0AAD+Mflj4agAD2IxOX3bAAAEY/Hrc8QAAAZ6Pe9RSAAAAndva/3wAAAH5W+qXvgAAAzS//qScAAAC97/75PgAAAO+03v/xAAAA/qnVsmkAAACd7z9+bgAAAJ+8LX5+AAAACpj9Un3gAAD//8//+aAAAIiPbSK5EAAAiIpJYv8QAAD/+3n//uAAAMbvz/S/4AAAY93PT+fgAAAvnzne5HAAAA",
        "line2": (71, 2, "1342532232123233443222232323232222222233121324222222222322132012121"),
        "states2": "AAAAAAAAAAAAKgAAAABAAAAAAAAAAAAAAXAAAAAAgAAAAAAAAAAAAAbQAAAAAHAAAAAAAAAAAAAEQAAAAAAoAAAAAAAAAAAACEAAAAAACAAAAAAA//////hAAAAAAAQAAAAAAwAAgAAIQAAAAAAEAAAAAAwAAIAACEAAAAAAAgAAAAAwAAGAABhAAAAAAAIAAAAAQAABAAAQQAAAAAABAAAAAIAAAQAAGEAAAAAABgAAAAEAAAEAAAhAAAAAABgAAAABAAABAAAQQAAAAAAgAAAAAgAAAIAAEEAAAAAAwAAAAAQAAACAACBgAAAABwAAAAAYAAAAgADAIAAAADwAAAAAYAAAAIADACAAAABAAAAAAYAAAAGAAgAgAAAAQAAAAAIAAAABAAIAIAAAAIAAAAACAAAAAQACACAAAAGAAAAABAAAAAEABgAgAAAGAAAAAAQAAAABAAYAIAAAGAAAAAAIAAAAAYAMACAAARAAAAAACAAAAACADAAgABagAAAAABAAAAAAgBgAIAAcwAAAAAAQAAAAAIAYACAAaAAAAAD/4AAAAAGAMAAgAYAAAAAAAAAAAAABQDAAIAYAAAAAAAAAAAAAAEAgACAYAAAAAAAAAAAAAABAIAAgIAAAAAAAAAAAAAAAQCAAIEAAAAAAAAAAAAAAAEAgADCAAAAAAAAAAAAAAABAIAAZAAAAAAAAAAAAAAAAQCAAGYAAAAAAAAAAAAAAAEAgAA6AAAAAAAAAAAAAAABAIAAGAAAAAAAAAAAAAAAAQEAABgAAAAAAAAAAAAAAAEBAABoAAAAAAAAAAAAAAABAgABoAAAAAAAAAAAAAAAAf/ABhAAAAAAAAAAAAAAAAEP//gcAAAAAAAAAAAAAAACAAAABAAAAAAAAAAAAAAAAgAAAAQAAAAAAAAAAAAAAAIAAAAIAAAAAAAAAAAAAAACAAAACAAAAAAAAAAAAAAABAAAABAAAAAAAAAAAAAAAAQAAAAQAAAAAAAAAAAAAAAEAAAAEAAAAAAAAAAAAAAADAAAAA8AAAAAAAAAAAAAAAgAAAAA4AAAAAAAAAAAAAAP///wACAAAAAAA////4AACAgBEAAQAAAAAAAAAADAAAgAARgAEAAAAAAAAAAAcAAIAAEIAAgAAAAAAAAAABAACAABCAAIAAAAAAAAAAAQAAgAAQQACAAAAAAAAAAAEAAIAAMCAGgAAAAAAAAAABgACAADAgHQAAAAAAAAAAAMAAgAAwMGUAAAAAAAAAAABgAIAAMHAiAAAAAAAAAAAAEACAAGGMPQAAAAAAAAAAACwAgAHmBcCAAAAAAAAAAABCAIAPOgUzAAAAAAAAAAAAwYEAeBoCDAAAAAAAA",
        "counties2": "AAAAAAAAAAAAU4CAIBBAAAAAAAAAAAAAAXGAgCBwgAAAAAAAAAAAAAbQgIBhoHAAAAAAAAAAAAAEUPDBwaAoAAAAAAAAAAAACFgQXgOQBAAAAAAA//////hYEGgCEAQAAAAAAyCA4ECISBAIBHACAAAAAAwggaDAiEgYBARAAgAAAAAwIEHhwRhOGAQCQAEAAAAAQCBB4uWQTgw8HiACAAAAAIAgQf5mmEEEduAgDAAAAAEAIEHMbIhBjlOgIBAAAAACACAhhhiQQMnQICAgAAAABAAQJ4axsGA4ECAQwAAAAAgAEfyDWWBgMDAgFwAAAAA2ABEAhAmgYHA0QDwAAAAAwYARgPwSIGBY+kBAAAAAAQDAEICIPh3gyJnAQAAAAAIA8BOBiOYHZo+IrEAAAAACAJn/AQ2CAnuPiB2AAAAABACPAgEDAgJp6YgGAAAAAAQDiQYBAwQCZDuQGAAAAAAIDAkEAY3EHigXERAAAAAACAgJA5/+fBg4Ax6gAAAAABAMCIP9whgIPAKcwAAAAAA//AyCA4MQPCcD6AAAAAD/6AQMggOBGKMhBgAAAAAAECgEHIMFQj9hoNgAAAAAABAoBmyDBEMhMeAgAAAAAAAQKA2FgWRDIxigQAAAAAAAEDgIBYGkRiIOoEAAAAAAAAg4iAzxPH4iAzCAAAAAAAAIP+gMfzxH44OZAAAAAAAACBQeCMGERD/iUYAAAAAAAAgUGQiBhEwi/n6AAAAAAAA/9hiQwIRIIhwFAAAAAAAA4JIY0L/P2EIEBwAAAAAAAECSCH+B6EhCBBoAAAAAAABAkwh75zhIgwboAAAAAAAAT5H48Hz4f0EBhAAAAAAAAGiRjyAjmFn//wcAAAAAAAAo34ggIRjICOGBAAAAAAAA/niIYEMQjAg4wgAAAAAAAINQiGHCE54YOEIAAAAAAACC0fhHM/2T8BBMAAAAAAAAgRHIXA4RFDAQ/AAAAAAAAIH/yGAIERyYC/wAAAAAAACAnE5AEDEP+BK8AAAAAAAAAIRBwB7jGTweMwAAAAAAAACIQEB/4hAECMD4AAAAAAAAiEBAwHv///3ASAAAAAAA////43BmBghGYEQAAAAAAECAQKYYYggIRCCEAAAAAABAgECYEGIIDEIhAgAAAAAAQMBAxCBCCAROYQIAAAAAAEBAQMQQQxwMexICAAAAAABAQP/EC0N118aUHAAAAAAAf/+GTg/Cz2D8ifQAAAAAAMAghEvwfsYwxPcUAAAAAAAgMLxZgEJ/kEXAmAAAAAAAIB3mcEBecImOMPQAAAAAABAPAmGw8nDPuB+EAAAAAAAIBQH5GMKwXOgQZgAAAAAADPmBDgUkseBoABgAAAAAAA",
        "gauges": [
            ("01129200", 2, 5, None, None, [271.2, 303.0, 354.0, 462.0, 680.0, 947.2, 1196.0]),
            ("01129500", 5, 10, None, [11.0, 13.0, 16.0, 17.0], [440.0, 545.0, 762.0, 1150.0, 1950.0, 3383.0, 4984.5]),
            ("01131500", 8, 15, None, [15.0, 18.0, 21.0, 23.0], [609.0, 811.8, 1230.0, 2060.0, 3690.0, 6392.0, 8516.0]),
            ("01144500", 14, 29, None, [20.0, 23.0, 27.0, 29.0], [1510.0, 1800.0, 3000.0, 5750.0, 10500.0, 16100.0, 20380.0]),
            ("01154500", 17, 36, None, [26.0, 28.0, 32.0, 35.0], [1920.0, 2240.0, 3645.0, 7080.0, 14400.0, 21660.0, 27870.0]),
            ("01170500", 22, 46, None, [26.0, 28.0, 32.0, 40.0], [2292.0, 3074.0, 5310.0, 11200.0, 20500.0, 31960.0, 39800.0]),
            ("01184000", 26, 54, [7.6, 7.76, 8.19, 9.03, 10.14, 11.41, 12.21], [14.0, 15.0, 17.0, 19.0], None),
            ("01193050", 30, 62, None, [5.0, 7.0, 10.5, 13.0], None),
        ],
    },
    {
        "key": "savannah",
        "label": "Savannah",
        "short": "Sav.",
        "line1": (23, 1, "233210101212110121120220102222101232000"),
        "states1": "AAIAD/+AAAAAAgBwAMAAAP///4AAIAAAEAADAAA+AAAQAAMAAAHwAAgABwAAAAgACAABwAAABAAIAABgAAACAAgAACAAAAGACAAAEAAAAMAEAAAQAAAAIAQAAAgAAAAQBAAACAAAAAgEAAAEAAAADwQAAAIAAAAwAgAAAQAAAEACAAAAgAAAQAIAAABAAACAAgAAAEAAAIACAAAAYAAAgAEAAAAwAAEAAQAAAAwAAQABAAAABAAGAAEAAAAEABgAAQAAAAQAIAAAgAAABgDAAACAAAADAQAAAIAAAAECAAAAwAAAAYQAAADAAAAAiAAAAIAAAADQAAAAgAAAAGAAAA",
        "counties1": "fLZz//+P+/hEotH5JNLumP///8k0YmqJF//zRT//e/051/4ttGn+ZWjR93XkZCwjz7//xnf8JiObP/7nPDv5f77X1X+mIxnP6JPf88PlH8NFnvTXNy3pbCf/X/5Mmuc4f6Y+P8jJ9wic/c5vOOv/D5X8/8u2/kcQ1n/W/+FIxaB+f7K0gizMwPPUb+tNFyhAks/JPlnPGIAT//4v4TYOgP9Ktdo/ewsAk0+XihzPkgCRybbK/UbsANM3yv8mR1AAXxM65aT0IABx/fuY93zAAG2d7R3JJwAAxvdvv0liAADk1nb/zMQAAP5/kvX32AAAxZze7XbwAAD81HOtLmAAAA",
        "line2": (47, 2, "222342423210101100121212121210101212201011321020221010131122221011311322217010"),
        "states2": "AAAACAAAAB/8AAAAAAAAAAAAAAgAAAPgD//AAAAAAAAAAAAIAAAGAAAAcAAAAAAAAAAACAAAPAAAAGgAAAAAAP///////+AAAAAIAAAAAAABAAAAAAEAAAAABAAAAAAAAQAAAAAGAAAAAAQAAAAAAACAAAAACAAAAAAH/gAAAAAAgAAAAAgAAAAAAAP/AAAAAIAAAAAYAAAAAAAAAIAAAACAAAAAGAAAAAAAAABAAAAAgAAAAA4AAAAAAAAAIAAAAIAAAAADAAAAAAAAABAAAABAAAAAAIAAAAAAAAAIAAAAQAAAAAB4AAAAAAAABAAAAEAAAAAACAAAAAAAAAIAAABAAAAAAAQAAAAAAAABAAAAQAAAAAAEAAAAAAAAAIAAAEAAAAAABAAAAAAAAABAAAAgAAAAAAIAAAAAAAAAIAAAIAAAAAACAAAAAAAAABAAACAAAAAAAwAAAAAAAAAIAAAgAAAAAAEAAAAAAAAABAAAIAAAAAABgAAAAAAAAAIAACAAAAAAAIAAAAAAAAABAAAQAAAAAABgAAAAAAAAAIAAEAAAAAAAMAAAAAAAAABHABAAAAAAAAgAAAAAAAAAeAAQAAAAAAAMAAAAAAAAAYAAEAAAAAAABAAAAAAAAAYAABAAAAAAAAYAAAAAAAAIAAAIAAAAAAACAAAAAAAAEAAACAAAAAAAAYAAAAAAABAAAAgAAAAAAABgAAAAAAAgAAAIAAAAAAAAEAAAAAAAIAAACAAAAAAAADAAAAAAAEAAAAgAAAAAAAAwAAAAAABAAAAEAAAAAAAAGAAAAAAAQAAABAAAAAAAAAwAAAAAAIAAAAQAAAAAAAAEAAAAAABAAAAEAAAAAAAABAAAAAAAgAAABAAAAAAAAAMAAAAAAQAAAAQAAAAAAAAAwAAAAAIAAAACAAAAAAAAACAAAAACAAAAAgAAAAAAAABAAAAAPAAAAAIAAAAAAAAAIAAAAEAAAAACAAAAAAAAABAAAACAAAAAAQAAAAAAAAAQAAADAAAAAAEAAAAAAAAAEAAABAAAAAABAAAAAAAAABAAAAgAAAAAAIAAAAAAAAAQAAAQAAAAAACAAAAAAAAADAAAYAAAAAAAgAAAAAAAAAYAAYAAAAAAAEAAAAAAAAABAAIAAAAAAABAAAAAAAAAAgAEAAAAAAAAQAAAAAAAAAEABAAAAAAAAGAAAAAAAAAAgAgAAAAAAAAwAAAAAAAAAQAQAAAAAAAAIAAAAAAAAAEAIAAAAAAAAEAAAAAAAAAAgMAAAAAAAACAAAAAAAAAAMEAAAAAAAAAgAAAAAAAAAAyAAAAAAAAAIAAAAAAAAAADAAAAAAAAAGAAAAAAAAAAAgAAAAAAA",
        "counties2": "HDhGGDYCIJ//iGBmx4PwgBAQhggfAiPiEP/Bn//FgQAQEMwIIINfgggYcwRwSIEAEDBMCCCD/oIIMHwEGHBBgP///////6DCBCAIBBB4QIABFNkCMIEgQgYgDAQISGBAASSZARkGMCIDoBwECMiwYAEnkfkNiBAiBH/3/xuPH+ADwhEJj8gQ4QQgEGH/BAgRB8OyDfl4EyGEIBggCMgMCQXAsgVSGB4xaDAYMAhoBAwIgP4Dkh4YMjgQEDAEEAQFEP+GfgsjEBIfHxh4BDgMA2CBg/oPIaAWA5D/SA4kDALBg4INs//4DAOwH8j+Yg+BAcePxMEQmDYGcAwHgkEQcgNYejxCEYhHDBAEBwHAoB8CUMIH4xEMiZgIBAsDmEABDHDCBCHdjwzQCDgQh//gAfBAggRCM/QEIA/IEIpAsA4QYIIcxBCCBh4fCGEQQRh4GGeCN7gQQwQZlgXw4CEMcAg//+MeGWF4MHODjHAiBsAEIGQ2Ea/5ziBgwYPYJgOAH/DEHBjEB4vwQEGBMCQBgG2/hDIPtBnh2MBggNgWAMCDMIQzMYwguYyAYIMOCgBHgxD/ccBMIMyDYFiME54AeIIQudDgrmBFBhh3mCB9AYACE6GQuRngfwwO4LAgHwIAgh4mP6UYPPOQA6BgQBmEAHwYOCdCCFMhoAIcQEAQiAAcCDhpwgRDMEAEAvCAEPAAN/gfuOeMTJigDAKw4CAQAD4P4RgodPiJEBYBn5hAIABiCEGQeEaITjAjgAIMQCAAQghgntDDCOwgwsAiAoBAAMIMIHOQgwd/GQIw9gGAQAACBH/hiIYEdv4CGxwAYIAAAgXR//v+HsIEAgwEADhAAAIGEESPI/OEAuYbCADngAD//BCEjCDAhAGdMcQBAgAAgQQQhIQQwEQAwNB7ggIAAIEGEP+CF4BEA+FAGMIEAACBAhDBhh6ASP5iQBjkPAAAgQP4wQm4QEkEJiAduEAAAIECHyHw+DnfBDQwFxCAAADxBwIRGMg2MQgYEDADAAAAE/8CDw0MOCCIEHwwBAAAADIBAhMHhM5AiBGvGAgAAAAiAeIQnoeDYHwTORgQAAAALgCe4LKOA8DDHAmYYAAAADmAx6HuegPBQKII/4AAAAA4f8cTOGMDcyBCCDoAAAAAwDB/HhhHAhIQQQgMAAAAAEAgcxwYpYZ2EGEYCAAAAABwIGIUHJ2H36AgsAgAAAAAcCAyND8YjRLgMcAwAAAAAF/gPydhCPkyWdPAQAAAAABAPEM/wQRxsmYcoEAAAAAAQCaC4EH4cKIiEPGAAAAAAGAjgiBBDFiiPRg+AAAAAABh4MIgPwyMog0IDAAAAAAA+QFiICEHAv4W/AQAAAAAAA",
        "gauges": [
            ("02176930", 1, 2, [0.69, 0.76, 0.91, 1.09, 1.31, 1.51, 1.73], [5.0, 7.0, 10.0, 15.0], None),
            ("02195520", 17, 39, [14.06, 14.23, 14.49, 14.88, 15.69, 16.59, 17.24], None, None),
            ("02197000", 20, 44, [96.83, 97.04, 97.63, 99.27, 101.5, 105.45, 108.72], [115.5, 117.5, 120.5, 129.5], None),
            ("021973269", 23, 50, [6.42, 6.66, 7.34, 9.06, 11.24, 15.12, 17.12], None, None),
            ("02197500", 27, 56, [4.18, 4.48, 5.29, 7.02, 9.25, 12.96, 14.62], [14.0, 15.0, 20.0, 25.0], None),
            ("02198500", 32, 65, [3.21, 3.5, 4.4, 6.18, 8.68, 11.66, 13.11], [10.0, 11.0, 15.0, 20.0], None),
            ("02198840", 35, 71, None, None, None),
            ("0219897993", 38, 76, None, None, None),
        ],
    },
    {
        "key": "apalachicola",
        "label": "Apalachicola",
        "short": "Apalach.",
        "line1": (35, 1, "223424332332212224222222212232212"),
        "states1": "YAR//+YAQABABAAgBAB/AEAEACACAACAQAQAMAEAAGCABAAQAIAAMAAIABAAgAAIAAgAEABAAAcACAAQACAACAAIABAAEAAQAAgAGAAIACAACAAIAAQAIAAIAAgAAgBAAAgACAACAYAAGAAIAAEGAAAQAAwAAQgAABAABAAAkAAAEAAEAADQAAAQAAwAAGAAABAACAAAQAAAEAAIAABAAAAQAAgAAIAAABAACAAAgAAAEAAMAACAAPwI//wAAQAADAiABAANAAAICEAH8AsAAAQIQAAP8QAABAjAAAARAAAD//8AAACAAAAgAMBAAIAAACAAQbAAgAAAYAAmCACAAA",
        "counties1": "",
        "line2": (70, 2, "2122334332443233333322322122212213422322122222212212323223212221"),
        "states2": "BAAAMB/////8GAAACAAAABwAABAAAAgAABAAABgAAAAwAAAQAAAIAAAgAAAf/wAAMAAAEAAACAAAIAAAAACAACAAABAAAAQAABAAAAAAQAAgAAAwAAAEAAAIAAAAACAAIAAAIAAABAAABwAAAAAQAOAAACAAAAQAAAGAAAAACADAAAAgAAAEAAAAgAAAAAQAgAAAIAAABAAAAMAAAAACAAAAACAAAAIAAABAAAAAAQAAAAAgAAACAAAAYAAAAACAAAAAIAAAAgAAACAAAAAAQAAAAGAAAAIAAAAQAAAAAD4AAABgAAACAAAACAAAAADBAAAAQAAAAgAAAAQAAAABAAAAAEAAAAEAAAACAAAAAgAAAABAAAABAAAAAQAAAAQAAAAAQAAAAQAAAACAAAAEAAAAAEAAAAEAAAAAgAAACAAAAABAAAABAAAAAEAAAAgAAAAAwAAAAQAAAAAgAAAEAAAAAMAAAACAAAAAGAAAGAAAAACAAAAAgAAAAAQAAGAAAAAAgAAAAIAAAAAEAACAAAAAAIAAAACAAAAABAABAAAAAACAAAAAgAAAAAQAAgAAAAAAgAAAAEAAAAAEAAQAAAAAAIAAAABAAAAAAwAYAAAAAAGAAAAAIAAAAACAYAAAAAABgAAAACAAAAAAgIAAAAAAAYAAAABgAAAAAIEAAAAAAAEAAAAAMAAAAACBAAAAAAABAAAAAGAAAAAAwgAAAAAAAQAAAABAAAAAAHQAAAAAAAEAAAAAwAAAAAAYAAAAAAABAAAAAIAAAAAAEAAAAAAAAQAAAACAAAAAACAAAAAAAAEAAAAAgAAAAABAAAAAAAABAAAAAMAAAAAAQAAAAAAAAQAAAABAAAAAAIAAAAAAAAEAAAAAQAAAAACAAAAAAAABAAAAAEAAAAABAAAAAAAAAQAAAABAAAAAAQAAAAAAAAEAAAAAQAAAAAEAAAAAAAABgAAAAEAAAAACAAAAAAAAAIAAAAAgAAAAAgAAAAD/4ACA////4AAAAAIAAAAAACAAgQAAACAAAAACAAAAAABgAIDAAAAQAAAA8gAAAAAAQACAIAAAH8AAAR4AAAAAAEAAgGAAAAA//gECAAAAAAAgAIBAAAAAAAH9AgAAAAAAMACAIAAAAAAABwIAAAAAABAAgEAAAAAAAAMCAAAAAAAYAIDB4AAAAAAAAQAAAAAAD8//nhwAAAAAAAEAAAAAAAAwAOADAAAAAAABAAAAAAAAEAAAAMAAAAAAAQAAAAAAAAgAAAAwADAAAACAAAAAAAAIAAAAEAAsAAAAgAAAAAAACAAAAAgAwgAAAIAAAAAAAAgAAAAIAwEAAACAAAAAAAAwAAAABAwBAAAAQAAAAA",
        "counties2": "jH/4sA///////yQ0OMSuZP4SKJjYiA9WN5s0PDiFu/Qy82+fcIgc97fxcmf//yEWN9FEttyIHOR9IdfEEwThC+YR/L+H7i/99VkU55ECQQ43/w6ghP7Mx7fPHDT+juEEbhEb4IQzjf/9/wwuHLqT9soR+jiEIzd1+SmeQgjhij+aERon//FkRFn970Jxo/wHk/8KIQQrxkRadoTz0y2ePd6H//EMRmf//iZc3Y+w0yFwhIQ5/I4iKPX/b8zEXPDAUOSETwUL/+nD8ftIZD5gQF+cvE2D0Zpp7PIqeHZv8H5WB/XIg+ESXpj+OjZ/yfCBV/xnyMQjE/X/5z5h5hhZANMkfUn4JuM7cSX6gb4QTgCRJcd/MH5/H1M3yQIPOIQA1zdERDHM0eKO9y6FgOaEAP+URcQbC5Fi9I38iePDCADY/3/EDBuRPxSQ19E9gMgAyCHIzBYSEdP//9Q/HIDsANhBiPwTn/8TVkZkG7fhEABeQQj34WCJk/I8LBxBshAAcf//onEgifMz5CnloZzgAMGhELZ/EIifvOf+JyHpAADBIRCURf/fxOfjEkR5AgAAxiEQnsfIUEW3vZHG/QQAAPj//5aGCHh/H7BhtxOYAAA94RCP/Q7t7b54eo0R4AAAZyEQkOH/hz3k2NqIkIAAAEMhEPjB8IRlx7T/jKEAAADCP/8IQYj8PSkl183BAAAAxCEREbEIh2fx81b35gAAAP/xERGPDMXFH3d29ngAAABGExEfAf/8ZYkYvE8YAAAAwhMXMYESMP/5EP7nkAAAAIM//SD/EhDiT/+zu+AAAAD/4iHwgxInotJnMtXAAAAAxLIhEI0T/v/6X/pvQAAAAESaIQkJ/iR9GcRuMMAAAABE//8EiE4kf/k4exiAAAAA/9aRDzBCJERJb9GYgAAAACcSkQ5/wj/+z8RJ54AAAAAlEpEN8MP8e4inziEAAAAAJJKR+QBCBGMIvif5AAAAACRWkQkAQgR///o/2gAAAAD/+p8J////6KJuEIYAAAAAKCPxGRCJCDiyJxDCAAAAACxCEZjQiWwQkk3e9AAAAAAnw/+YcIn0P/5o8w4AAAAA5G+QmDiIhfDf//0aAAAAACQqEJBIiMewmxCdPgAAAAAkEhiQOIjeaZMe1UIAAAAAFhEIkF6I4kYWGdOCAAAAAJ4JCJDCiIJP9/CRBgAAAAD3/8/zn/yDhBwwkfYAAAAA3TwwHOADgoQYPJ8dAAAAAHbwEAAAAEL/GCatEQAAAAD3wAgAAAA2Q/gjuREAAAAA88AIAAAADECkP0d5AAAAAJ9wEAAAAAzBwiJDiIAAAADPuPAAAAANggEiQQuAAAAAYo+gAAAAC4wBQ8EOgAAAAA",
        "gauges": [
            ("02330450", 0, 1, None, [4.0, 6.0, 8.0, 11.0], None),
            ("02334430", 4, 8, [-0.38, -0.33, -0.24, -0.05, 0.32, 0.94, 1.35], [8.0, 12.0, None, None], None),
            ("02335880", 7, 13, None, [11.0, 13.0, None, None], None),
            ("02338000", 10, 19, None, [15.0, 17.0, 21.0, 26.0], None),
            ("02339500", 13, 25, None, [14.0, 17.0, 19.0, 21.0], None),
            ("02342881", 18, 35, [186.9, 187.31, 188.0, 188.69, 189.23, 189.61, 189.85], None, None),
            ("02343241", 21, 41, None, [130.0, 134.0, 145.0, 160.0], None),
            ("02343801", 24, 45, None, [92.0, 106.0, 112.0, 124.0], None),
            ("02357700", 27, 52, None, [56.0, 63.0, 69.0, 74.0], None),
            ("02359170", 31, 61, None, [8.0, 9.5, 11.5, 13.5], None),
        ],
    },
    {
        "key": "suwannee",
        "label": "Suwannee",
        "short": "Suwannee",
        "line1": (34, 1, "110023243333212244545433222101113222232323"),
        "states1": "AAAAAAAABACAAAAAAAAIAIAAAAAAAAgAwAAAAAAAEABAAAAAAAAIACAAAAAAABAAIAAAAAAYEAAQAAAAAC4gAB/4AAAAQ/AAAA///gBgEAAAAAAD/yAQAAAAAAABIBAAAAAAAAEgEAAAAAAAAeAQAAAAAAAAwBAAAAAAAAAACAAAAAAAAAAIAAAAAAAAAAgAAAAAAAAACAAAAAAAAAAIAAAGAAAAAAgAAAkAAAAABAAACIAAAAAEAABwQAAAAAQAAYAgAAAABAACABAAAAACAAwACAAAAAIAMAAIAAAAAQDAAAQAAAABAAAABAAAAAEAAAACAAAAAIAAAAEAAAAAgA",
        "counties1": "IcIMj8OECAChggi8QQ6IAP//DKRhe1AAyEf75C/wOABIRCI8GBgIAChEIgwYGBAAKEQjGhgYEAAYRCIRn6YgAB//IiBowfAAIFf//ClgEADgYxhH/yNwAHhjMECJJLAAzMIgOMloEADDAkAmSdAQAIeGfmHI4BAAj/6HwQhAMAAEBIFBCH4wAAQFAWGPw6gAAgUBOJnC6AD/BwEMo0MIAIPmAQWcQYgAgCoBAqxAhACASYH+Q8+EAABwQIRA+MQAAYAhhEBgwgAGABEEQED+ABgAFgfAQEIAYAAIDGxcQQCAAAgIP2ZhAAAABBgIw+MAAAACcAQDooAAAAHABAE+gA",
        "line2": (69, 2, "1021100272123233434223423443221212323446445545443432323212210001210202202224231322132323232342"),
        "states2": "AAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAgAACAAAAAAAAAAAAAAAAA4AAAgAAAAAAAAAAAAAAAAIAAAEAAAAAAAAAAAAAAAACAAABAAAAAAAAAAAAAAAABAAAAIAAAAAAAAAAAAAAAAgAAAOAAAAAAAAAAAAAAAAEAAAAgAAAAAAAAAAAAAAAAgAAAEAAAAAAAAAAAAAAAAQAAABAAAAAAAAAAAAAAAAEAAAAIAAAAAAAAAAAAAAACAAAACAAAAAAAAAAAAAAAAgAAAAgAAAAAAAAAAAADgAIAAAAIAAAAAAAAAAAADPAEAAAADAAAAAAAAAAAAAgeBgAAAAf8AAAAAAAAAAAQAf8AAAAAA//wAAAAAAAAEAABAAAAAAAAD//gAAAAABAAAQAAAAAAAAAAH//AAAAQAAEAAAAAAAAAAAAAP/8ACAACAAAAAAAAAAAAAAAA/wgAAgAAAAAAAAAAAAAAAAIIAAIAAAAAAAAAAAAAAAADCAACAAAAAAAAAAAAAAAAAQgAAgAAAAAAAAAAAAAAAAEIAAIAAAAAAAAAAAAAAAABCAABAAAAAAAAAAAAAAAAARgAAQAAAAAAAAAAAAAAAADwAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAYAAAAAAAAAAAAIAAAAAAAZAAAAAAAAAAAACAAAAAAAEMAAAAAAAAAAAAgAAAAAACAgAAAAAAAAAAAIAAAAAABAGAAAAAAAAAAABAAAAAADgAQAAAAAAAAAAAQAAAAADAACAAAAAAAAAAAEAAAAABAAAQAAAAAAAAAABAAAAAAgAAEAAAAAAAAAAAIAAAAAwAAAgAAAAAAAAAACAAAAAQAAAEAAAAAAAAAAAQAAAAYAAAAgAAAAAAAAAAEAAAAIAAAAEAAAAAAAAAAAgAAAMAAAABAAAAAAAAAAAIAAAMAAAAAQAAAAAAAAAACAAAcAAAAACAAAAAAAAAAAQAA4AAAAAAgAAAAAAAAAAEAAAAAAAAAIAAAAAAAAAAAgAAAAAAAABAAAAAAAAAAAIAAAAAAAAAMAAAAAAAAAACAAAAAAAAAAgAAAAAAAAAAQAAAAAAAAAEAAAAAAAAAAEAAAAAAAAAAgAAAAAAAAAAgAA",
        "counties2": "CAEwBAAQgIBgDsAQACAAAAgBIAQAEED/4AcAEABgAACIA8AEACBPoCADABgAgAAAiAKABAAgyCAwAQAuwIAAAMgDgAQAQIggEAEBw4CAAAB////8AGBIIBAAnwBhAAAAYEAQJ//f+CAIALcAGQAAAOBAECAECAggDH/hAA+AAAAgQBAgBAQIIANAAQAAgAAAEIAQMAQED6ABQAGAAQAAABCAEBAEBACgAUABgAEAAAAIgBAQBAIA8AFAAYABAAAACIAQEAQDAcwBQAEAAgAAAAkAEBAEBgICAcADgAIAAAAJABAQBAQGAgB/jHAEAAAACgAQEAQIBgHAQIgeBgAAAAf+EBAEDAQAOEGQAf8AAAAGB///BAQEAAxBkAABAAAABAAEP//+BAAEQRAAAgAAABgABAQfv//4BEEQAAIAAAD8AAgGAIAgP//zCAECAAAAHAAQAgMAIABgjwgPogAAADeAEA4GACAAQIIIEPoAAAAggCAIBAAgAGCDCCAOAAAAIODgCAQAIAAggQhAAgAAACAjgBAEABPAMIEYgAIAAABAPAAQDAAWcBCBEQABAAAAwBgAEBgACBgwgbIAAQAAAIAgABAQABgHYIDUAAEAAABAP/8QP/gQAcCAGAABAAAAwH+B8GAIMAEAgBAAAQAAAIBgABCAD+ABAIAQAA8AAACAMAAQgAEgAQCAEAAJAAAAABAAEYABMAEAgB/8CIAAAAAQABMAARABAJ/wBAiAAAAAGAASAAEYAQD4UAeIgAAAABgAEgABBwEAgJAE+IAAAAAIABIAAQGBAwGQBABAAAAABAAWAAEAQQYHEAQAQAAAv/+AFAABACEEDBADAEAAAEABfBQAAQAghhgQAIBAAABAAAQ0AAEAEwNwEACAIAAAgAAITAABABcE4BAAgCAAAIAACEMAAQAMiDAQAIAgAABAABCAgAEACPgP0D/AIAAAQAAQgGAB//gwAHDAwBAAAMAAIwAQAIAQIAAxAGAQAAAAADwACACAMCAANgBgEAAAAADAAAgBgDAgABgAYBAAAAABAAAEAQAwEAAQAGAIAAAABgAABAMAIBAAEABh+AAAAAgAAAIEACAQABAAPwgAAAAwAAABmAA/EAAQACAEAAAAQAAAAGAAMfAAEAAgBAAAAIAAAABAACAcABPAIAIAAAMAAAAAQABgBPgecCACAAAcAAAAAEAAQAf/EBAgAQAA4AAAAAAgAMAAQfAYEAMAAAAAAAAAEACAAEBgCBwNAAAAAAAAAAgBgABAAA48CIAAAAAAAAAEAwAAYAAD5AiAAAAAAAAAAgYAACAABgQIQAAAAAAAAAE4AAAgAAIEeEAAAAAAAAABwAAAIAACB4AgAA",
        "gauges": [
            ("02314495", 10, 23, [3.45, 3.98, 5.07, 6.78, 10.0, 12.07, 13.16], None, None),
            ("02315500", 17, 38, [50.35, 50.7, 51.71, 53.66, 56.59, 62.74, 66.46], [69.0, 74.0, 80.0, 86.0], None),
            ("02315550", 20, 44, [37.7, 38.05, 39.16, 41.54, 45.02, 50.71, 53.44], [58.0, 60.0, 65.0, 72.0], None),
            ("02319800", 25, 56, [21.72, 21.88, 23.14, 25.62, 29.23, 33.5, 35.36], [43.0, 47.0, 52.0, 58.0], None),
            ("02320000", 28, 60, [17.5, 17.61, 18.19, 20.56, 24.8, 28.83, 31.46], [34.0, 35.0, 42.0, 48.0], None),
            ("02320500", 31, 69, [3.45, 3.64, 5.3, 8.09, 11.56, 15.16, 16.95], None, None),
            ("02323000", 34, 77, [4.89, 5.16, 6.68, 8.87, 11.61, 14.46, 15.88], [14.0, 17.0, 21.0, 24.0], None),
            ("02323500", 37, 83, [2.59, 2.93, 3.56, 4.45, 5.85, 7.69, 8.74], None, None),
            ("02323592", 41, 91, [0.31, 0.7, 1.15, 1.54, 1.87, 2.24, 2.46], None, None),
        ],
    },
    {
        "key": "stjohns",
        "label": "St. Johns",
        "short": "St Johns",
        "line1": (35, 30, "74764667565656644466556566067565666000"),
        "states1": "AAADggAAAAAAAAGCAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAIAAAEAAAAABQAAAIAAAAAYgAAAgAAAAGBAAACAAAAAgCAAAEAAAAAAIAAAQAAAAAAQAABAAAAAAAgAACAAAAAABAAAIAAAAAAEAAAQAAAAAAOAABAAAAAAAIAACAAAAAAAQAAEAAAAAABAAAQAAAAAAEAAAgAAAAAAgAACAAAAAACAAAIAAAAAAQAAAgAAAAABAAACAAAAAAEAAAIAAAAAAQAAAgAAAAABAAACAAAAAAEAAAEAAAAAAQAAAQAAAAAAgAAAgAAAAACAAACAAAAAAIAAAIAAAA",
        "counties1": "MkO6sgAAAADC5mniAAAAAP78SIYAAAAAwwxP/gAAAABjC1mdAAAAAP4I3pkAAAAAHg/zuQAAAAAZjKHIgAAAACBYoI+AAAAAwFDwjoAAAAAAIY/kQAAAAAATB57AAAAAAAwEG8AAAAAABAwYIAAAAAAEOBQgAAAAAAP/9hAAAAAAAINDEAAAAAAAgU/4AAAAAAD+TmQAAAAAAINP5AAAAAAAn9AyAAAAAAD40BIAAAAAAQD/9AAAAAAB4ZgUAAAAAAH/hhQAAAAAASCGEgAAAAABMIISAAAAAAEQgT8AAAAAAJCBkQAAAAAA///wgAAAAADgiZ+AAAAAAECIiIAAAA",
        "line2": (70, 61, "067506666466667654765566556656642445466655564656566666066075657654666756060000"),
        "states2": "AAAAAAAEQAgAAAAAAAAAAAAAAAAAAsAIAAAAAAAAAAAAAAAAAAPABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAOAAAAAAAAQAAAAAAAAAAACYAAAAAAAEAAAAAAAAAAABBgAAAAAABAAAAAAAAAAAAQEAAAAAAAIAAAAAAAAAAB4BAAAAAAACAAAAAAAAAAAgAIAAAAAAAgAAAAAAAAAAwACAAAAAAAEAAAAAAAAAAQAAYAAAAAABAAAAAAAAAAIAABAAAAAAAIAAAAAAAAAAAAAQAAAAAACAAAAAAAAAAAAAEAAAAAAAgAAAAAAAAAAAABAAAAAAAEAAAAAAAAAAAAAMAAAAAABAAAAAAAAAAAAAAwAAAAAAIAAAAAAAAAAAAAEAAAAAACAAAAAAAAAAAAAAgAAAAAAQAAAAAAAAAAAAAIAAAAAAEAAAAAAAAAAAAABAAAAAAAgAAAAAAAAAAAAAQAAAAAAIAAAAAAAAAAAAACAAAAAABAAAAAAAAAAAAAAmAAAAAAQAAAAAAAAAAAAAGgAAAAACAAAAAAAAAAAAAAIAAAAAAgAAAAAAAAAAAAACAAAAAAEAAAAAAAAAAAAAAgAAAAAAgAAAAAAAAAAAAAEAAAAAAIAAAAAAAAAAAAABAAAAAABAAAAAAAAAAAAAAIAAAAAAQAAAAAAAAAAAAACAAAAAACAAAAAAAAAAAAAAgAAAAAAgAAAAAAAAAAAAAIAAAAAAEAAAAAAAAAAAAAEAAAAAABAAAAAAAAAAAAABAAAAAAAQAAAAAAAAAAAAAQAAAAAAIAAAAAAAAAAAAAIAAAAAACAAAAAAAAAAAAAEAAAAAABAAAAAAAAAAAAABAAAAAAAQAAAAAAAAAAAAAQAAAAAAEAAAAAAAAAAAAAEAAAAAAAgAAAAAAAAAAAABAAAAAAAIAAAAAAAAAAAAAQAAAAAACAAAAAAAAAAAAAEAAAAAAAQAAAAAAAAAAAABAAAAAAAEAAAAAAAAAAAAAQAAAAAAAgAAAAAAAAAAAACAAAAAAAIAAAAAAAAAAAAAgAAAAAABAAAAAAAAAAAAAEAAAAAAAQAAAAAAAAAAAABAAAAAAACAAAAAAAAAAAAAQAAAAAAAgAAAAAAAAAAAAEAAAAAAAIAAAAAAAAAAAABAAAAAAABAAAAAAAAAAAAAQAAAAAAAQAAAAAAAAAAAACAAAAAAAEAAAAAAAA",
        "counties2": "hgggEAxESAQAAAAAAAAAALgIIB+GRpAEAAAAAAAAAABgCEAIZEOgBAAAAAAAAAAAQAjwGBxAwAQAAAAAAAAAAP/4//AQQIAEAAAAAAAAAACACQCQEECAHAAAAAAAAAAAQAsAkBBA/xQAAAAAAAAAAEAKAJgQf4HSAAAAAAAAAAAgCgCGEMKBcgAAAAAAAAAAIAoAgxCEgQIAAAAAAAAAAP+MAICRHIGBAAAAAAAAAAAAvADAsPiAgQAAAAAAAAAAASQAwHswgIEAAAAAAAAAAAFDAP/MD4fAgAAAAAAAAAACwMB4RAGYQIAAAAAAAAAAAwBAQMQA4GCAAAAAAAAAAAwAIECEAIBgQAAAAAAAAAAQACDAhACAb8AAAAAAAAAAIAARAPwAgDxAAAAAAAAAAMAACgCfAIAgQAAAAAAAAAAAAAQBAXy8MCAAAAAAAAAAAAAEAQHmxDAgAAAAAAAAAAAAAgIAJwIY4AAAAAAAAAAAAAEGACADeJAAAAAAAAAAAAAAmAAgAYhQAAAAAAAAAAAAAGAAIAGPyAAAAAAAAAAAAAAgAOABwAgAAAAAAAAAAAAAIACAAeAEAAAAAAAAAAAAABAAgAEgBAAAAAAAAAAAAAAQAcABEAIAAAAAAAAAAAAACA+wAQgCAAAAAAAAAAAAAA/wH/8EAQAAAAAAAAAAAAAGgAwgBAEAAAAAAAAAAAAAAIAMIAQAgAAAAAAAAAAAAABABiAHYIAAAAAAAAAAAAAAQAIg+K/AAAAAAAAAAAAAAEAEIIg4IAAAAAAAAAAAAAB//CCQECAAAAAAAAAAAAAAIAggn/AQAAAAAAAAAAAAACAGIIAYCAAAAAAAAAAAAAAgAaEADAgAAAAAAAAAAAAAQAehAAYEAAAAAAAAAAAAAH/8oQAEBAAAAAAAAAAAAABAAKEABggAAAAAAAAAAAAAgAC///4IAAAAAAAAAAAAAIAA4QACEAAAAAAAAAAAAAEAAYHAAhAAAAAAAAAAAAABAAEAYAIQAAAAAAAAAAAAAf//gDACEAAAAAAAAAAAAAEEAIAcAggAAAAAAAAAAAABBACAHAIIAAAAAAAAAAAAAQQAgAgCCAAAAAAAAAAAAAEGAIAEAgQAAAAAAAAAAAABAwCAAgIEAAAAAAAAAAAAAQEAgAICDgAAAAAAAAAAAAEBAIABB/oAAAAAAAAAAAAAgQCAAIYBAAAAAAAAAAAAAIEAgACCAQAAAAAAAAAAAAD//////wCAAAAAAAAAAAAAjgCAQMEAgAAAAAAAAAAAALgAgEDB/8AAAAAAAAAAAADAAIBBgEBAAAAAAAAAAAAAQACAQIBAIAAAAAAAAAAAAEAAgECAQCAAAAAAAA",
        "gauges": [
            ("02231342", 0, 2, [34.29, 34.54, 34.94, 35.23, 35.58, 36.07, 36.41], None, None),
            ("02232000", 7, 15, [1.68, 2.04, 2.71, 3.18, 3.99, 4.91, 5.87], None, None),
            ("02232400", 11, 21, [9.05, 9.56, 10.0, 11.06, 13.03, 14.08, 15.4], [15.8, 16.0, 16.5, 17.0], None),
            ("02234000", 14, 29, [0.94, 1.1, 1.57, 2.86, 4.9, 6.75, 8.18], [6.0, 8.0, 9.0, 10.0], None),
            ("02234500", 18, 36, [0.7, 0.86, 1.19, 1.93, 3.17, 4.28, 5.58], [4.2, 5.5, 7.0, 8.0], None),
            ("02236125", 22, 44, [0.63, 0.75, 1.03, 1.44, 2.04, 2.95, 3.38], [2.0, 2.3, 3.0, 4.0], None),
            ("02244040", 26, 54, [10.54, 10.65, 10.91, 11.25, 11.82, 12.51, 12.8], None, None),
            ("02246500", 35, 72, [10.51, 10.63, 10.87, 11.19, 11.66, 12.21, 12.45], None, None),
        ],
    },
    {
        "key": "roanoke",
        "label": "Roanoke",
        "short": "Roanoke",
        "line1": (4, 3, "24577000002010120105070002010610200612411321102000060120000010010320001241012421100227016007"),
        "states1": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAf//////////////4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        "counties1": "psAohe48PuoTwCDIC955rwngQHwYOeF3DtBAJxhgwhsNCPAhuEBOBjQHj8DMQHuNxAcD0IdAYPEIBARxgfnAYBgMBBEBD4GRPAwECcEHhxPH/AQOfQSOJoZ4CA4HBLhohEgIDAEF4PAE6AgOAQ2A4AZZyB4BCEBg8hDwH4EYPH//////////wAIBBCEgXgNAAgEEITDDAmACAwQhEMMEMQIDBCEQw8Qb/8IEITCASAeCP//hb4B//4ICEKHDgDANggIQowL8GA0CAhC+Ags4BJ4CER8EEfAE8gIRGYQQyAPD4hEwaDBnBsI+H+A4ICH4ggPwQBDwYfgCAgCAMwmYMA",
        "line2": (9, 6, "61324244567660060600000010610200200120121410011746006606010717222700101701022000160124112141313121101020001000660001217010100000100000210122321070012131010212443110102241702070222207710321766000767"),
        "states2": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB//////////////////////////////wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        "counties2": "hA74AAeAgBFmgAIAB/wIhAQ0MAAEAIAwPOAC4A7niGICFHAADABAIAC+Afg/g8jxAR9QAAgAcMAAg8A+PgDofACBnAAYABPAAYB4Y/wBvgYAgCcAEAAcYAGAB4BEAwE7AI5BgDAACBABgAwAfAYAzgCzgMAgABgOAYAYABAMAAwA4QBgeoAQAwOAEAAQGAAYAaAAIG2AEAE9gBAAEHgAGAYwABDAsBAA4MAQABHvACwIEAAVwM3gAEBwEAATgMBm8DAAGoALYADAGxAAHgBBg4BgABEACCEAgAeeABwAZgEAIAAgABA/AIAB8wBwADwAAMAAIAAQAoCAAQCAwAAkAAGAACAAEAGBgAEAg4AAxgABAAAgABAAgQABAH4AA4IBB4AAIAAgAIGAAwA8AAYCAgzwAGAAIABCfAMAJ8AcBAQwG4DgACAAYgIDACBAMAQYcA774AAgAEQB4wAwQOAIMEAcDkAAQAAoAB4AEMOACGBAEABAAEAAMAACABCHABjAwBAAQABAAFAAAgAQnAARAAAQMMAAQAAgAAIAE/AAcgAAGHCAAIAA8AACACNgAHQAAAg4gACAALgAAgAiwAB4AAAIEIAggACMAAIAQDAAOAAACACD2IABgAACAEAYABAAAAgBAYUAAQAAAgCACAAwAP4IAQGZAAH/4AIAgA/wP/////////////////////AAgAQAAgAgBAEEAB4AABwQAAAEAAIAIAQBBAAT8AAGMAAABAACACAEAQQAEBgADCAAAAQAAgAgBAEEACAMAAggAAAEAAIAIAQBAgAgBgAQMAAABAAGACAEAQIAIAIAEAwAAAQABgAgBAECACACABADAwAEAAYAIAQBAgBABAAgAIoABAAGACAEAQIAQATgIABeAAQABAAgBAEEAEADsCAANv//+AQAIAQBB+CAABBAACSABB/////8ARhwgAAIf//kgAQABAIAhAEQDQAAG8AAZIAEAAQCAIQBoAPgAA4AAESABAAEAgCEAWACsQADAABCgAQABAIBBAIAAh7wAQAAQgAEAAQCAQQCAAQAXACAAEMADAAEAgEGBgAEAIMDgAAgAAwABAIBA8YACACDBAAAIIAMAAQCAQE0AAgBgY8AADCB/AAEAgEBjAAQAQBpgAAQ/wwABAIBAIMAEAEAEEAACGAMAAQCAQEAwCACABhgAA9gDAAEAgIBADAgAgAIOwAwIA/4BAICBwAYQAYADD8AQGAMB/wCAgwADEAEAAQBMMDADAAEA//4AAaADAAEAe+AwAwAB/8AIAADgBoABAEVgAAMAAQAAEAAAQBhADwAHQAADAAEAABAAAcBgYBvAAkAAAwABAAAQAAJhgCBg4ADAA",
        "gauges": [
            ("02054500", 4, 14, None, [6.0, 8.0, 11.0, 13.0], [45.42, 52.0, 63.4, 106.0, 196.0, 322.6, 459.6]),
            ("02055000", 9, 25, None, [6.0, 10.0, 12.0, 16.0], [65.8, 76.44, 99.0, 157.0, 280.0, 497.2, 736.0]),
            ("02060500", 23, 59, None, [16.0, 18.0, 24.0, 29.0], [475.0, 523.4, 656.0, 924.0, 1410.0, 2186.0, 3198.0]),
            ("02062500", 31, 73, None, [20.0, 23.0, 27.0, 30.0], [545.2, 651.4, 867.0, 1210.0, 1780.0, 2736.0, 4146.0]),
            ("02066000", 39, 86, None, [21.0, 24.0, 30.0, 34.0], [630.6, 787.4, 1020.0, 1530.0, 2270.0, 3670.0, 5568.0]),
            ("02079500", 52, 112, None, None, None),
            ("02080500", 63, 135, [3.03, 3.09, 3.35, 4.05, 5.3, 6.63, 7.4], [9.0, 9.0, 12.0, 15.0], None),
            ("0208062765", 67, 141, [17.8, 18.27, 19.03, 21.18, 24.77, 29.59, 32.47], [45.0, 47.0, 50.0, 53.0], None),
            ("02081000", 73, 151, [5.37, 5.84, 6.65, 8.98, 12.99, 18.14, 21.01], [28.0, 28.0, 31.0, 34.0], None),
            ("02081028", 81, 169, [3.02, 3.23, 3.77, 5.56, 9.6, 13.82, 15.35], [18.0, 19.0, None, None], None),
            ("02081054", 85, 180, [4.48, 4.71, 5.02, 5.79, 7.82, 9.79, 10.4], [10.5, 12.0, 13.0, 15.0], None),
            ("02081094", 88, 188, [0.85, 1.08, 1.44, 1.75, 2.05, 2.42, 2.68], None, None),
            ("0208114150", 92, 196, [0.78, 1.0, 1.33, 1.61, 1.83, 2.04, 2.16], None, None),
        ],
    },
    {
        "key": "kentucky",
        "label": "Kentucky",
        "short": "Ky.",
        "line1": (51, 30, "543444464646464646764646364324644744564647444634252325644746366664765756564646644"),
        "states1": "AG4AAEYHAEAAQAAAK4iAIABAAAAQ8MBgAEAAAAAAYMABgAAAAAAxgAIAAAAAABMAAgAAAAAAHAAEAAAAAAAYABwAAAAAAAgAMAAAAAAACAAgAAAAAAAQACAAAAAAABAAQAAAAAAACABAAAAAAAAIAIAAAAAAAAQAAAAAAAAABAAAAAAAAAACAAAAAAAAAAEAAAAAAAAAAIAAAAAAAAAAgAAAAAAAAACgAAAAAAAAAGAAAAAAAAAAPAAAAAAAAAAMAAAAAAAAADwAAAAAAAAAZAAAAAAAAACGAAAAAAAAAQMAAAAAAAAGAAAAAAAAABgAAAAAAAAAYAAAAAAAAABAAA",
        "counties1": "Zv/yEX5HJEEj0fMRP8znLz/XkTcI+MH8ME8J2QgQ4LDh+YcJOBgxsIOwxw/sLFMZ8jB5G4cjnhuNH/G4w+Dav9zgkOxmkMnNUEEQhrT5+MFgQR3BmGcQgSDh50+MwRCGX9rsfkfCCMR4hixifz4ITuDM7kMhHwz+8X+5YeMC3OHWHxn/Eh4zIIwxHQ8dtiMgDCEfBPDD8bAGYXuIOeM7kAt5zIhvYx6vE58+z8YZEGEjgeNtjAcQPyHBIfD8DxAN/+0g0IQp0DyEnzEIR9jwZASEEwh9kCDGBEwdnseQ4YOEWghzhtu3gf5hsHEGZhxHC4LAIYYkaE4IhkBghBhEKQ",
        "line2": (102, 60, "44532443644463534666366464644466447635766605566447446346442242534636464745445656347474470544644463452253252234345744146644744663647665666467646647476056575474247547447644656535"),
        "states2": "AAA42AAAAAAwAAA7AAAQAAAAYCAAAAAAGDgAQQAAEAAAAEAAAAAAAAjGAIEAABAAAABAAAAAAAANgYGBgAAIAAAAIAAAAAAAAwBfAIAACAAAACAAAAAAAAAAMADAADgAAAAQAAAAAAAAAAAAcADgAAAAEAAAAAAAAAAAABgAgAAAACAAAAAAAAAAAAAEAIAAAABAAAAAAAAAAAAAAgEAAAABgAAAAAAAAAAAAAEBAAAABgAAAAAAAAAAAAABjwAAAAQAAAAAAAAAAAAAAfgAAAAIAAAAAAAAAAAAAAEAAAAACAAAAAAAAAAAAAABgAAAABAAAAAAAAAAAAAAAIAAAAAwAAAAAAAAAAAAAACAAAAD4AAAAAAAAAAAAAAAgAAABgAAAAAAAAAAAAAAAIAAAAQAAAAAAAAAAAAAAAEAAAAMAAAAAAAAAAAAAAABAAAACAAAAAAAAAAAAAAAAwAAAAgAAAAAAAAAAAAAAAMAAAAIAAAAAAAAAAAAAAABAAAAGAAAAAAAAAAAAAAAAIAAABAAAAAAAAAAAAAAAABAAAAQAAAAAAAAAAAAAAAAQAAAMAAAAAAAAAAAAAAAAEAAAMAAAAAAAAAAAAAAAABwAACAAAAAAAAAAAAAAAAAMAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABgAAAAAAAAAAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAYAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAA4AAAAAAAAAAAAAAAAAAAADgAAAAAAAAAAAAAAAAAAAAYAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAcAAAAAAAAAAAAAAAAAAAAG4AAAAAAAAAAAAAAAAAAAAFAAAAAAAAAAAAAAAAAAAACgAAAAAAAAAAAAAAAAAAABYAAAAAAAAAAAAAAAAAAAAjAAAAAAAAAAAAAAAAAAAAwQAAAAAAAAAAAAAAAAAAAQEAAAAAAAAAAAAAAAAAAAIBAAAAAAAAAAAAAAAAAAAEAIAAAAAAAAAAAAAAAAAACABAAAAAAAAAAAAAAAAAADAAMAAAAAAAAAAAAAAAAADAAAAAAAAAAAAAAAAAAAADAAAAAAAAAAAAAAAAAAAADAAAAAAAAAAAAAAAAAAAADAAAAAAAAAAAAAAAAAAAADAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAA",
        "counties2": "Dhg/zQYCAwEiABA7CBAQAQwMYnGeAgEBGjwQYQgQEAEMBmIA4gIBAxrnEKE4HhgHBAIhAcICAQIPgZDhIAIIfAQCIIcCAgEWAYBfQZACCYAF//C8AYMPLgCAMEGwA/kABwAwZgBBeWIAgACA8ADRAAIAMEMAQYHCAIABABgAiQAcADiDgCMAgQHAAgAEAIUAcABHAYA+AIGeYAeACgEDAEABhADgHAB6YCAEYBEBAQBABgYA4DQATgAgDDAxjwGD/wwCADBiAIUAHwgTIfgAjIGIAwAgwQGBAAaID8EQAYiAjgHw2YEDgMAMiAAhDAeIgRsCH4cBhsBgCHgAIYKMjkEwvAGBAJxALAhAAGCB0LMj4GABAQDwMF4IQgBCgLDDFgAwAQEAwDiHECeAb4DgATQAEAEBAEAPAyAtwLEAQAM8ADADA4DgBgPAOHMBAEADGAAgAw7joAYAwAwuAwCADwgAMAMYLiALwLAMAgIAgBwIAGwDkDggMCB4GAIBAEAQCHnDgvggOdAgHDAEAIBgMBmPQGYIIA4IEDzQCABAICAeAIAcCGAECBG/CBgAQBA4OACACAhgDAQOZgZwAEAg8PgAQDAEeBgECAID/gBwR/jIAKHgbE4IAggCABHA8PwOTgEfMLzDEAOIAgAQcKDYAyICAHGOgTwE+AQAGA0RCAAjAgD/BoD/BAYMAfgDCgQAIYwBwQOB4P4DCACQBgwCAMD4AwEBwYA+AfYDGAIEBAAAYAYBAfMAcgEDjBwGBgIAAEAMAQHmADFhANAEBAGCAAAwDAMAlgAQ+gBIBPYBggAAEBACD4sAMAYAOAWOB4MAACw4AvnBgCAdgdgGAeSBgAAkKAOAgYAgMGI4BAH84P8AxGYCAODAQDAeDgIBADhDAYZB/gDgwEBgHAHCAQAYAwECwAIHEGAuQBABcwEABAYDBYACHAww8YAgABECAAcGBg+AA/gGGYCBoAAZAgAG7oQCwAIIAx8Ax+AA/wMAAFuMAPACCAHhAHwgAb4BAAHg/A98IggA4YBAMAEBgQADYL/yAtoIAQCAIBAFAOEABhCAGQEOBAEAgCAQDwDjAAwQwAiAGAIBAIAQFDGAJgAQEAAQQBABCgBAHJ9BgCIAYBAAMGAgARYAYB9ZgYAmAMAIACAgIAGjAPBgZ8GANAGABAAQMNgAwYGcwDbBAPgHQAcAEBMEAIBDD4AcQcHuHGAAgBAaBgEAZgEAGGHiDXAgAIAQDAIGADQBAAg4NADAMADh8DgFDAAcAgAQDCgDgBADn5jgBZAACAMAEAggDEAYHABPgAjgAAQBwBAEIBBACHwAQQAYYAAMAMAQAiAQYAxEAEGAECAAGADAIAIgECAEgg",
        "gauges": [
            ("03277300", 3, 7, None, [8.0, 10.0, 12.0, 14.0], [9.28, 10.9, 15.25, 32.6, 66.4, 140.8, 258.9]),
            ("03277500", 11, 25, None, [16.0, 20.0, 27.0, 33.0], [61.3, 70.97, 108.0, 224.0, 503.0, 1010.0, 1576.5]),
            ("03280000", 21, 45, None, [23.0, 29.0, 31.0, 40.0], [144.0, 177.0, 265.0, 576.0, 1280.0, 2748.0, 4137.0]),
            ("03282000", 30, 65, None, [16.0, 20.0, 24.0, 30.0], [275.2, 328.0, 609.0, 1380.0, 3410.0, 7770.0, 10800.0]),
            ("03282120", 36, 76, None, [17.0, 21.0, 25.0, 31.0], [350.0, 432.0, 762.5, 1670.0, 3835.0, 8666.0, 12210.0]),
            ("03282290", 40, 84, None, None, [288.2, 353.2, 651.0, 1650.0, 4140.0, 8998.0, 12900.0]),
            ("03284000", 45, 96, [9.61, 9.71, 10.13, 11.14, 12.85, 15.2, 16.7], [24.0, 26.0, 35.0, 40.0], None),
            ("03284230", 49, 105, None, [28.0, None, None, None], [265.15, 364.3, 749.0, 2075.0, 5587.5, 12070.0, 17785.0]),
            ("03284500", 53, 112, None, [28.0, 30.0, 36.0, 40.0], [282.0, 398.4, 757.0, 2200.0, 6050.0, 12860.0, 20740.0]),
            ("03286500", 57, 122, None, [26.0, 30.0, 36.0, 39.0], [355.75, 522.0, 1107.5, 4065.0, 9270.0, 16450.0, 25700.0]),
            ("03287000", 62, 130, None, None, [382.2, 504.4, 982.0, 2710.0, 7550.0, 14800.0, 23000.0]),
            ("03287250", 65, 136, None, None, [400.8, 508.4, 1020.0, 2750.0, 7920.0, 15500.0, 24600.0]),
            ("03287500", 68, 143, [6.83, 6.93, 7.23, 7.95, 9.35, 10.79, 12.3], [29.0, 31.0, 35.0, 40.0], None),
            ("03290500", 74, 160, None, [30.0, 33.0, 43.0, 49.0], [460.4, 634.0, 1320.0, 3390.0, 9660.0, 19000.0, 28260.0]),
            ("03291585", 80, 174, [8.83, 8.96, 9.41, 10.47, 12.95, 17.17, 22.03], None, None),
        ],
    },
    {
        "key": "capefear",
        "label": "Cape Fear",
        "short": "C. Fear",
        "line1": (21, 2, "7000110212121211013322032111110100212232"),
        "states1": "MAAAAAAAAABAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOAAAAAAAAAAP/AAAAAAAAAAKAAAAAAAAQAIAAAAAAACAAQAAAAAAAQAB/+AAAAACAAAAEAAAAAIAAAAIAAABxAAAAAQAAAYoAAAAAgAACBAAAAABAAAwAAAAAACAAEAAAAAAAEAAgAAAAAAAIAEAAAAAAAAQAgAAAAAAAAgCAAAAAAAABAQAAAAAAAACZAAAA",
        "counties1": "/w+EIkkjo//mDf//y/D/1aQIhCTOXGFOPn+MJPhHYc/j8vwlPIjg/fFiT+VmiH/R2ebMP8F4zTJH5Ywggu+2IiIkaGGMhj//ehQ4b9j6EFnf///98Ekw4BOcaQsQiyDAE3JIhgmM+MCRMsiE7wjOsPkx6ceY6YecZ/P/6hC57CYiPiZzEI40wzIIIXkYhxeBGgwhSoiF14Y3///M/IQ/CKIIgmhC/CAQ4giBMEKEFyB7ycEYQYI4oA5/R7xhAsBAFwg8pJ2ZAAAhBHDih/4AAKGY2f8BpAAAeeifZ4MoAABuz+xmzCgAAEJnPCx4OAAAxDEeKBAQAAA0MRscCZAAAA",
        "line2": (42, 5, "6707000000121010222121112121220022101011232343222102321211201020022102001001021221223223"),
        "states2": "CwAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD/AAAAAAAAAAAAAAAAAAAAB//8AAAAAAAAAAAAAAAAAAAABQAAAAAAAAAAAAAAAAAAAAaAAAAAAAAAAAAAAAAAAAAEgAAAAAAAAAAAAAAAAwAAAEAAAAAAAAAAAAAAAAQAAABAAAAAAAAAAAAAAAAIAAAAIAAAAAAAAAAAAAAAEAAAACAAAAAAAAAAAAAAACAAAAAgAAAAAAAAAAAAAABAAAAAP///wAAAAAAAAAAAgAAAAAAAACAAAAAAAAAAAQAAAAAAAAAQAAAAAAAAAAIAAAAAAAAACAAAAAAAAAACAAAAAAAAAAQAAAAAAAA/BAAAAAAAAAACAAAAAAAAwMgAAAAAAAAAAQAAAAAAAwAoAAAAAAAAAACAAAAAAAwAMAAAAAAAAAAAQAAAAAAwAAAAAAAAAAAAACAAAAAAQAAAAAAAAAAAAAAQAAAAAYAAAAAAAAAAAAAACAAAAAIAAAAAAAAAAAAAAAQAAAAMAAAAAAAAAAAAAAACAAAAEAAAAAAAAAAAAAAAAQAAACAAAAAAAAAAAAAAAACAAAAgAAAAAAAAAAAAAAAAQAAAQAAAAAAAAAAAAAAAACAAAEAAAAAAAAAAAAAAAAAQAABAAAAAAAAAAAAAAAAACAAAgAAAAAAAAAAAAAAAAAQAAIAAAAAAAAAAAAAAAAACAAEAAAAAAAAAAAAAAAAAAQABAAAAAAAAAAAAAAAAAACAAgAAAAAAAAAAAAAAAAAAQ/IAAAAAAA",
        "counties2": "S4IAgEAgCAgYQgYFhAJ0LFBGAJdAIAgIEEIEBoQB5kMwOAD9/////9BDzADH/2MzUAgAwEAgCCDwTHgAeAFhiUgYAIBAIAggkHAeADACIMiMMACAQCAIIJBgE/gYAiBEB/AAgIAgCCCYQDAmOAMwbwIOD//AYAghj0AgQnABDPCCA3wII+AIIQ/AYEPMAY8AnAGCCD5gCCEEMEBAxAD6A6QBAggQYAghHAzAwEeBggJyAQQIEH/4IRgGgIAg7wIGsYMMDGBgCf/wA4OAIPoCBGBDeBvAYA8AQAEPQGAUBgQgP5ARwGAIAIAHsGGYBAQEEAQIEGBACACAHcAmBggEBAgEDiAYQAgAgDDAPAW//7wICAIgCEAIAQBgQDAEYECvBhgBIARACAWAwEB4BAAhwAfQATACQAg6eQB/iAIAEMDZ//4QA0AIcd4AMIQDAAgAMRAD/////4GGACCCBgBwAAEYAyAYgQCBAwBggwQAYAABD8EQEIEAwgGAQIMEACAAAQQ/EDBBgEQAgEDunwAwAAEGAwggQIAoAEHA2HjAcACBAgIMYMCAGADHgIDgYFgAQwEGBEDAgBAcvgCAgDCEAGIBBgPAQEAJ4wGAg4AvggD/4QYBzM/gdgEAfYLAIAGAEH/+And48NwBAEdCYEAGYAgEDQQMeBGEAgBARDAgCBgIBA6YDDwZBAIAQFgLIDAEBAwEsAgEBgYDAEBwByDgBQQIAMAIBBkCAQBAIAE5gAICCADgCAIQgwCAQB8BD4AEA4gAoAgCCIeAwEAQ8QCACAL4AKAIBBCMwGBAEAkHADAEH8CgCAQg+H/gQBAF/gBABA//v///4IBgEIAQB+AAgAQIAMCADCCAIBiAEAYAAQCMCABAgAQZADAM//ADAAIAyAwAQEAGDQAQBEAQAQACAGgEAIBgAgYAEALACAEPBAAcBACAcAEDACACgAgC8MgAC4fggbACB4AgAQAIAwAoAADEH5iYAwTAIAMABAwAEAABXAD3GP6MYH4BAAQwAAAAAjQAwAmAiCDHgIACwAAAAAYGAEAOANgRgGOBgQAAAAAEAgAgDwBQCQAe58IAAAAACAIAIBcAcAcAAPhkAAAAAJABAEBxgPfOAACIKAAAAADwAQPAQIOcfwABhBAAAAAAIAP+wECEGA2ADwQgAAAAAB8HIIDBGBgQwDgEQAAAAAAZxYBBgLAMEGBQBEAAAAAAEH7gJvhACCAwwASAAAAAADAMGB4IIAggGIAEgAAAAAAgEAQGBzgMQAUABQAAAAAA8BAEBgfEBIADAAUAAAAAAJAQBgYBGARAAQAGAAAAAAAIIAYCAG4DIACABgAAAAAADmAHAgCLgaAAQ/IAAAAAAA",
        "gauges": [
            ("02096500", 7, 16, [1.64, 1.72, 1.9, 2.3, 3.0, 4.82, 6.52], [16.0, 18.0, 23.0, 27.0], None),
            ("02096960", 11, 25, [2.79, 2.88, 3.11, 3.61, 4.31, 5.37, 6.46], [10.0, 11.0, 15.0, 17.0], None),
            ("02102500", 17, 37, [1.33, 1.41, 1.55, 2.11, 3.56, 6.2, 7.85], [13.0, 14.0, 19.0, 27.0], None),
            ("02104000", 21, 48, [9.58, 9.7, 9.95, 10.75, 13.13, 17.96, 21.5], [35.0, 35.0, 48.0, 58.0], None),
            ("02105500", 25, 54, [1.13, 1.22, 1.41, 1.94, 3.28, 5.29, 7.43], None, None),
            ("02105769", 30, 71, [14.71, 14.8, 15.03, 15.59, 16.79, 18.48, 19.53], [22.0, 24.0, 26.0, 28.0], None),
        ],
    },
]

# --- END GENERATED ---
