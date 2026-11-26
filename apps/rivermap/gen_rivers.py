"""Precompute river maps for the River Map Tronbyt app.

For each river in RIVERS this fetches (once, cached under cache/):
  - the river's mainstem line (geoconnex reference mainstems, from NHDPlus V2)
  - USGS gauges on the mainstem (NLDI), kept if they reported gage height in the last week
  - each gauge's gage-height percentiles over the last 5 years (USGS daily values)
  - each gauge's NWS flood stages (NWPS), dropped if NWS stage and USGS gage height disagree
  - state and county outlines around the river (Census TIGERweb)

then projects everything onto the 64x32 and 128x64 canvases and writes the result into
river_map.star, between the GENERATED markers at the end of the file.

Usage:
    python gen_rivers.py                  # all rivers
    python gen_rivers.py brazos trinity   # just these; the others are kept from the last run
    python gen_rivers.py --emit           # rewrite the app from the last run, no network

Needs Python 3 and requests. USGS allows about 1000 requests an hour per IP without an API
key; the script waits out 429s and caches every response (RIVERMAP_CACHE, default
~/.cache/rivermap), so a re-run picks up where the last one stopped. RIVERMAP_CACHE_ONLY=1
rebuilds from the cache without calling USGS.
"""

import concurrent.futures as cf
import hashlib
import json
import math
import os
import sys
import time
import urllib.parse

import requests

HERE = os.path.dirname(os.path.abspath(__file__))
APP = os.path.join(HERE, "river_map.star")
CACHE = os.environ.get("RIVERMAP_CACHE") or os.path.join(os.path.expanduser("~"), ".cache", "rivermap")
os.makedirs(CACHE, exist_ok=True)
RUN_FILE = os.path.join(CACHE, "rivers.json")

MAINSTEMS = "https://reference.geoconnex.us/collections/mainstems/items"
NLDI = "https://api.water.usgs.gov/nldi/linked-data"
USGS = "https://api.waterdata.usgs.gov/ogcapi/v0/collections"
NWPS = "https://api.water.noaa.gov/nwps/v1"
TIGER = "https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb/State_County/MapServer"

# key, label, short label, mainstem name at outlet, optional (lon, lat) point on the river to
# pick between rivers with the same name (otherwise the one with the largest drainage wins)
RIVERS = [
    ("mississippi", "Mississippi", "Miss.", "Mississippi River", None),
    ("missouri", "Missouri", "Mo.", "Missouri River", None),
    ("ohio", "Ohio", "Ohio", "Ohio River", None),
    ("arkansas", "Arkansas", "Ark.", "Arkansas River", None),
    ("redsouth", "Red", "Red", ["Red River", "Lower Atchafalaya River"], (-92.45, 31.32)),
    ("tennessee", "Tennessee", "Tenn.", "Tennessee River", None),
    ("cumberland", "Cumberland", "Cumb.", "Cumberland River", None),
    ("wabash", "Wabash", "Wabash", "Wabash River", None),
    ("illinois", "Illinois", "Ill.", "id:324005", None),
    ("wisconsin", "Wisconsin", "Wis.", "Wisconsin River", None),
    ("minnesota", "Minnesota", "Minn.", "Minnesota River", None),
    ("rednorth", "Red of the North", "Red N", "Red River of the North", None),
    ("platte", "Platte", "Platte", "Platte River", (-96.0, 41.05)),
    ("kansas", "Kansas", "Kan.", "Kansas River", None),
    ("canadian", "Canadian", "Can.", "Canadian River", None),
    ("yellowstone", "Yellowstone", "Yellow.", "Yellowstone River", None),
    ("snake", "Snake", "Snake", "Snake River", (-117.0, 44.0)),
    ("columbia", "Columbia", "Col.", "Columbia River", None),
    ("willamette", "Willamette", "Will.", "Willamette River", None),
    ("sacramento", "Sacramento", "Sac.", "Sacramento River", None),
    ("sanjoaquin", "San Joaquin", "S. Joaq.", ["San Joaquin River", "New York Slough"], (-121.3, 37.8)),
    ("colorado", "Colorado", "Colo.", "Colorado River", (-114.6, 33.6)),
    ("coloradotx", "Colorado (TX)", "Colo. TX", "Colorado River", (-96.0, 29.0)),
    ("gila", "Gila", "Gila", "Gila River", None),
    ("riogrande", "Rio Grande", "Rio Gr.", "Rio Grande", None),
    ("pecos", "Pecos", "Pecos", "Pecos River", None),
    ("brazos", "Brazos", "Brazos", "Brazos River", None),
    ("trinity", "Trinity", "Trinity", "Trinity River", (-94.75, 29.9)),
    ("sabine", "Sabine", "Sabine", "Sabine River", (-93.75, 30.2)),
    ("neches", "Neches", "Neches", "Neches River", None),
    ("guadalupe", "Guadalupe", "Guad.", "id:2652346", None),
    ("nueces", "Nueces", "Nueces", "Nueces River", None),
    ("hudson", "Hudson", "Hudson", "Hudson River", None),
    ("delaware", "Delaware", "Del.", "id:2122629", None),
    ("susquehanna", "Susquehanna", "Susq.", "Susquehanna River", None),
    ("potomac", "Potomac", "Potomac", "Potomac River", None),
    ("james", "James", "James", "James River", (-77.5, 37.5)),
    ("connecticut", "Connecticut", "Conn.", "Connecticut River", None),
    ("savannah", "Savannah", "Sav.", "Savannah River", None),
    ("apalachicola", "Apalachicola", "Apalach.", "Apalachicola River", None),
    ("suwannee", "Suwannee", "Suwannee", "Suwannee River", None),
    ("stjohns", "St. Johns", "St Johns", "id:2501419", None),
    ("roanoke", "Roanoke", "Roanoke", "Roanoke River", None),
    ("kentucky", "Kentucky", "Ky.", "Kentucky River", None),
    ("capefear", "Cape Fear", "C. Fear", "Cape Fear River", None),
    ("penobscot", "Penobscot", "Penob.", "Penobscot River", None),
]

CANVASES = {"1": (64, 32, 1), "2": (128, 64, 2)}
MARGIN_1X = 1  # px kept clear around the map at 1x
MAX_GAUGES = 30
MIN_GAUGE_GAP_1X = 3  # px along the river between chosen gauges at 1x
ACTIVE_DAYS = 7
STATS_DAYS = 1826
PCTS = [5, 10, 25, 50, 75, 90, 95]

session = requests.Session()
session.headers["User-Agent"] = "rivermap-generator"


# RIVERMAP_CACHE_ONLY=1: never call the rate-limited USGS Water Data API; use what's cached
CACHE_ONLY_USGS = os.environ.get("RIVERMAP_CACHE_ONLY") == "1"


class NotCached(Exception):
    pass


def cached_get(url, params=None, ttl=30 * 86400, kind="json", retries=6, cache_only=False):
    key = url + "?" + urllib.parse.urlencode(sorted((params or {}).items()))
    h = hashlib.sha1(key.encode()).hexdigest()
    path = os.path.join(CACHE, h + ("." + kind))
    if os.path.exists(path) and time.time() - os.path.getmtime(path) < ttl:
        with open(path, encoding="utf-8") as f:
            text = f.read()
        return json.loads(text) if kind == "json" else text
    if cache_only or (CACHE_ONLY_USGS and "waterdata.usgs.gov" in url):
        raise NotCached(url)
    last = None
    for attempt in range(retries):
        try:
            r = session.get(url, params=params, timeout=180)
            if r.status_code == 429:
                wait = int(r.headers.get("Retry-After") or 60) + 5
                print("  429, waiting %ds" % wait, flush=True)
                time.sleep(wait)
                last = "429"
                continue
            if r.status_code == 404:
                text = "null" if kind == "json" else ""
                break
            r.raise_for_status()
            text = r.text
            break
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(2 + attempt * 3)
    else:
        raise RuntimeError("GET failed %s: %s" % (url, last))
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    return json.loads(text) if kind == "json" else text


# --- Sources ---


def find_mainstem(name, hint):
    # name: a name at outlet, or a list of acceptable ones. With a hint point, search the
    # mainstems crossing a small box around it (the API ignores name filters with bbox).
    if isinstance(name, str) and name.startswith("id:"):
        d = cached_get(MAINSTEMS + "/" + name[3:], {"f": "json", "skipGeometry": "true"})
        return d["properties"]
    names = [name] if isinstance(name, str) else list(name)
    if hint:
        lon, lat = hint
        params = {
            "f": "json",
            "skipGeometry": "true",
            "limit": "200",
            "bbox": "%f,%f,%f,%f" % (lon - 0.1, lat - 0.1, lon + 0.1, lat + 0.1),
        }
        feats = (cached_get(MAINSTEMS, params) or {}).get("features", [])
    else:
        feats = []
        for n in names:
            params = {"f": "json", "name_at_outlet": n, "skipGeometry": "true", "limit": "200"}
            feats += (cached_get(MAINSTEMS, params) or {}).get("features", [])
    all_feats = feats
    feats = [
        f
        for f in feats
        if not f["properties"].get("superseded") and f["properties"].get("name_at_outlet") in names
    ]
    if not feats:
        seen = sorted(
            {(f["properties"].get("name_at_outlet"), round(f["properties"].get("outlet_drainagearea_sqkm") or 0)) for f in all_feats},
            key=lambda x: -x[1],
        )[:8]
        raise RuntimeError("no mainstem named %s; nearby: %s" % (names, seen))
    feats.sort(key=lambda f: -(f["properties"].get("outlet_drainagearea_sqkm") or 0))
    return feats[0]["properties"]


def mainstem_line(ms_id):
    d = cached_get(MAINSTEMS + "/" + ms_id, {"f": "json"})
    g = d["geometry"]
    if g["type"] == "LineString":
        return g["coordinates"]
    # MultiLineString: chain the parts end to end
    parts = g["coordinates"]
    line = list(parts[0])
    for p in parts[1:]:
        line.extend(p)
    return line


def mainstem_gauges(outlet_comid, head_comid, ms_uri):
    feats = []
    for comid, nav in [(outlet_comid, "UM"), (head_comid, "DM")]:
        d = cached_get("%s/comid/%s/navigation/%s/nwissite" % (NLDI, comid, nav), {"distance": "9999"})
        feats += (d or {}).get("features", [])
    out = []
    seen = set()
    for f in feats:
        p = f["properties"]
        if p.get("mainstem") and p["mainstem"] != ms_uri:
            continue
        ident = p["identifier"]
        # 15-digit ids are lat/long-numbered sites, nearly all wells and springs
        if not ident.startswith("USGS-") or len(ident) > 15 or ident in seen:
            continue
        seen.add(ident)
        lon, lat = f["geometry"]["coordinates"][:2]
        out.append({"id": ident[5:], "name": p.get("name", ""), "lon": lon, "lat": lat})
    return out


def latest_stage(ids):
    # {site: (iso_time, value)}
    res = {}
    for i in range(0, len(ids), 50):
        batch = ids[i : i + 50]
        text = cached_get(
            USGS + "/latest-continuous/items",
            {
                "f": "csv",
                "parameter_code": "00065",
                "monitoring_location_id": ",".join("USGS-" + s for s in batch),
                "properties": "monitoring_location_id,time,value",
                "skipGeometry": "true",
                "limit": "1000",
            },
            ttl=86400,
            kind="csv",
        )
        lines = text.strip().splitlines()
        if not lines:
            continue
        hdr = lines[0].split(",")
        for ln in lines[1:]:
            row = ln.split(",")
            r = dict(zip(hdr, row))
            try:
                res[r["monitoring_location_id"][5:]] = (r["time"], float(r["value"]))
            except (KeyError, ValueError):
                pass
    return res


def percentile(vals, p):
    k = (len(vals) - 1) * p / 100.0
    lo = math.floor(k)
    hi = math.ceil(k)
    return vals[lo] + (vals[hi] - vals[lo]) * (k - lo)


def stage_stats_batch(sites, param="00065"):
    # {site: [p5..p95]} from daily mean gage height, several sites per request
    rows_by = {}
    for i in range(0, len(sites), 8):
        batch = sites[i : i + 8]
        off = 0
        while True:
            try:
                text = cached_get(
                    USGS + "/daily/items",
                {
                    "f": "csv",
                    "monitoring_location_id": ",".join("USGS-" + s for s in batch),
                    "parameter_code": param,
                    "statistic_id": "00003",
                    "time": "P%dD" % STATS_DAYS,
                    "limit": "20000",
                    "offset": str(off),
                    "properties": "monitoring_location_id,value",
                    "skipGeometry": "true",
                },
                kind="csv",
                )
            except NotCached:
                break
            lines = text.strip().splitlines()
            if len(lines) < 2:
                break
            hdr = lines[0].split(",")
            si, vi = hdr.index("monitoring_location_id"), hdr.index("value")
            for ln in lines[1:]:
                row = ln.split(",")
                try:
                    v = float(row[vi])
                    if math.isfinite(v):
                        rows_by.setdefault(row[si][5:], []).append(v)
                except (ValueError, IndexError):
                    pass
            if len(lines) - 1 < 20000:
                break
            off += 20000
    out = {}
    for site, vals in rows_by.items():
        if len(vals) < 300:
            continue
        vals.sort()
        ps = [round(percentile(vals, p), 2) for p in PCTS]
        if ps[-1] - ps[0] >= 0.05:
            out[site] = ps
    return out


STATS_API = "https://api.waterdata.usgs.gov/statistics/v0/observationNormals"


def record_stats(site, param="00065", cache_only=False):
    # Gage-height percentiles over the gauge's period of record, from USGS's day-of-year
    # percentiles pooled over the year. None if USGS has none.
    try:
        d = cached_get(
            STATS_API,
            {"monitoring_location_id": "USGS-" + site, "parameter_code": param, "computation_type": "percentile"},
            cache_only=cache_only,
        )
    except NotCached:
        return None
    pool = []
    for f in (d or {}).get("features", []):
        for series in f["properties"].get("data", []):
            if series.get("parameter_code") != param:
                continue
            for v in series.get("values", []):
                if v.get("time_of_year_type") != "day_of_year":
                    continue
                try:
                    pool.extend(x for x in (float(y) for y in v["values"]) if math.isfinite(x))
                except (TypeError, ValueError):
                    pass
    if len(pool) < 7 * 300:
        return None
    pool.sort()
    ps = [round(percentile(pool, p), 2) for p in PCTS]
    return ps if ps[-1] - ps[0] >= 0.05 else None


def flood_stages(site, usgs_now):
    d = cached_get(NWPS + "/gauges/" + site, ttl=7 * 86400)
    if not d:
        return None
    fl = d.get("flood") or {}
    if (fl.get("stageUnits") or "ft") != "ft":
        return None
    cats = fl.get("categories") or {}
    out = []
    for k in ["action", "minor", "moderate", "major"]:
        s = (cats.get(k) or {}).get("stage")
        out.append(round(float(s), 2) if s is not None and s > -900 else None)
    if all(v is None for v in out):
        return None
    # NWS sometimes reports stage on a different datum than USGS gage height
    obs = ((d.get("status") or {}).get("observed") or {}).get("primary")
    if obs is not None and obs > -900 and usgs_now is not None and abs(obs - usgs_now) > 1.0:
        return "datum"
    return out


def tiger_rings(layer, bbox, offset):
    rings = []
    off = 0
    while True:
        d = cached_get(
            "%s/%d/query" % (TIGER, layer),
            {
                "geometry": "%f,%f,%f,%f" % bbox,
                "geometryType": "esriGeometryEnvelope",
                "inSR": "4326",
                "outSR": "4326",
                "spatialRel": "esriSpatialRelIntersects",
                "outFields": "NAME",
                "maxAllowableOffset": "%f" % offset,
                "resultOffset": str(off),
                "resultRecordCount": "500",
                "f": "geojson",
            },
            ttl=365 * 86400,
        )
        feats = d.get("features", [])
        for f in feats:
            g = f.get("geometry") or {}
            if g.get("type") == "Polygon":
                rings.extend(g["coordinates"])
            elif g.get("type") == "MultiPolygon":
                for poly in g["coordinates"]:
                    rings.extend(poly)
        if len(feats) < 500 and not d.get("exceededTransferLimit"):
            break
        off += len(feats)
    return rings


# --- Geometry ---


def dp_simplify(pts, tol):
    # Douglas-Peucker; returns indices of kept points
    n = len(pts)
    if n < 3:
        return list(range(n))
    keep = [False] * n
    keep[0] = keep[-1] = True
    stack = [(0, n - 1)]
    tol2 = tol * tol
    while stack:
        a, b = stack.pop()
        ax, ay = pts[a]
        bx, by = pts[b]
        dx, dy = bx - ax, by - ay
        L2 = dx * dx + dy * dy
        best, bi = -1.0, -1
        for i in range(a + 1, b):
            px, py = pts[i]
            if L2 == 0:
                d2 = (px - ax) ** 2 + (py - ay) ** 2
            else:
                t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / L2))
                d2 = (px - ax - t * dx) ** 2 + (py - ay - t * dy) ** 2
            if d2 > best:
                best, bi = d2, i
        if best > tol2:
            keep[bi] = True
            stack.append((a, bi))
            stack.append((bi, b))
    return [i for i in range(n) if keep[i]]


def bresenham(x0, y0, x1, y1):
    pts = []
    dx = abs(x1 - x0)
    dy = -abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx + dy
    while True:
        pts.append((x0, y0))
        if x0 == x1 and y0 == y1:
            break
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy
    return pts


class Projection:
    def __init__(self, line):
        lons = [p[0] for p in line]
        lats = [p[1] for p in line]
        self.k = math.cos(math.radians((min(lats) + max(lats)) / 2))
        xs = [lo * self.k for lo in lons]
        ys = [-la for la in lats]
        x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
        w, h = max(x1 - x0, 1e-6), max(y1 - y0, 1e-6)
        W, H, _ = CANVASES["1"]
        avail_w, avail_h = W - 2 * MARGIN_1X, H - 2 * MARGIN_1X
        self.s = min(avail_w / w, avail_h / h)
        # centre the river in the canvas
        self.ox = (W - w * self.s) / 2 - x0 * self.s
        self.oy = (H - h * self.s) / 2 - y0 * self.s

    def px(self, lon, lat, scale=1):
        return (
            (lon * self.k * self.s + self.ox) * scale,
            (-lat * self.s + self.oy) * scale,
        )

    def bbox(self, pad_px=2):
        # lon/lat extent of the whole 1x canvas plus a little
        W, H, _ = CANVASES["1"]
        lon0 = (-pad_px - self.ox) / self.s / self.k
        lon1 = (W + pad_px - self.ox) / self.s / self.k
        lat1 = -((-pad_px - self.oy) / self.s)
        lat0 = -((H + pad_px - self.oy) / self.s)
        return (lon0, lat0, lon1, lat1)

    def deg_per_px(self, scale):
        return 1.0 / (self.s * scale)


def cumulative(pts):
    c = [0.0]
    for i in range(1, len(pts)):
        c.append(c[-1] + math.dist(pts[i - 1], pts[i]))
    return c


def raster_river(proj, line, scale):
    W, H, _ = CANVASES[str(scale)]
    pts = [proj.px(lo, la, scale) for lo, la in line]
    cum = cumulative(pts)
    total = cum[-1] or 1.0
    keep = dp_simplify(pts, 0.35)
    pix = []  # (x, y, t)
    for a, b in zip(keep, keep[1:]):
        xa, ya = int(math.floor(pts[a][0])), int(math.floor(pts[a][1]))
        xb, yb = int(math.floor(pts[b][0])), int(math.floor(pts[b][1]))
        seg = bresenham(xa, ya, xb, yb)
        ta, tb = cum[a] / total, cum[b] / total
        for j, (x, y) in enumerate(seg):
            t = ta + (tb - ta) * (j / max(len(seg) - 1, 1))
            if pix and (pix[-1][0], pix[-1][1]) == (x, y):
                continue
            pix.append((max(0, min(W - 1, x)), max(0, min(H - 1, y)), t))
    # drop immediate back-steps (A B A) which make the chain code wobble
    out = []
    for p in pix:
        if len(out) >= 2 and (out[-2][0], out[-2][1]) == (p[0], p[1]):
            out.pop()
            continue
        if out and (out[-1][0], out[-1][1]) == (p[0], p[1]):
            continue
        out.append(p)
    return out


DIRS = {(1, 0): "0", (1, 1): "1", (0, 1): "2", (-1, 1): "3", (-1, 0): "4", (-1, -1): "5", (0, -1): "6", (1, -1): "7"}


def chain_code(pix):
    s = []
    for (xa, ya, _), (xb, yb, _) in zip(pix, pix[1:]):
        s.append(DIRS[(xb - xa, yb - ya)])
    return "".join(s)


def project_on_line(pts, cum, p):
    # fraction along the line of the closest point to p, and the distance to it
    best, bt = float("inf"), 0.0
    total = cum[-1] or 1.0
    px_, py_ = p
    for i in range(len(pts) - 1):
        ax, ay = pts[i]
        bx, by = pts[i + 1]
        dx, dy = bx - ax, by - ay
        L2 = dx * dx + dy * dy
        t = 0.0 if L2 == 0 else max(0.0, min(1.0, ((px_ - ax) * dx + (py_ - ay) * dy) / L2))
        d2 = (px_ - ax - t * dx) ** 2 + (py_ - ay - t * dy) ** 2
        if d2 < best:
            best = d2
            bt = (cum[i] + t * math.sqrt(L2)) / total
    return bt, math.sqrt(best)


def raster_rings(proj, rings, scale):
    W, H, _ = CANVASES[str(scale)]
    bits = [[0] * W for _ in range(H)]
    for ring in rings:
        pts = [proj.px(lo, la, scale) for lo, la in ring]
        keep = dp_simplify(pts, 0.5)
        for a, b in zip(keep, keep[1:]):
            xa, ya = int(math.floor(pts[a][0])), int(math.floor(pts[a][1]))
            xb, yb = int(math.floor(pts[b][0])), int(math.floor(pts[b][1]))
            if max(abs(xa), abs(xb), abs(ya), abs(yb)) > 4000:
                continue
            if (xa < 0 and xb < 0) or (ya < 0 and yb < 0) or (xa >= W and xb >= W) or (ya >= H and yb >= H):
                continue
            for x, y in bresenham(xa, ya, xb, yb):
                if 0 <= x < W and 0 <= y < H:
                    bits[y][x] = 1
    return bits


B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"


def encode_bits(bits):
    flat = [b for row in bits for b in row]
    while len(flat) % 6:
        flat.append(0)
    out = []
    for i in range(0, len(flat), 6):
        v = 0
        for b in flat[i : i + 6]:
            v = (v << 1) | b
        out.append(B64[v])
    return "".join(out)


# --- Per river ---


def build_river(spec):
    key, label, short, name, hint = spec
    t0 = time.time()
    ms = find_mainstem(name, hint)
    ms_id = str(ms["id"])
    line = mainstem_line(ms_id)
    outlet = ms["outlet_nhdpv2_comid"].rsplit("/", 1)[-1]
    proj = Projection(line)

    # gauges
    head = ms["head_nhdpv2_comid"].rsplit("/", 1)[-1]
    cands = mainstem_gauges(outlet, head, "https://geoconnex.us/ref/mainstems/" + ms_id)
    latest = latest_stage([g["id"] for g in cands])
    cutoff = time.strftime("%Y-%m-%d", time.gmtime(time.time() - ACTIVE_DAYS * 86400))
    active = [g for g in cands if g["id"] in latest and latest[g["id"]][0][:10] >= cutoff]

    pts1 = [proj.px(lo, la, 1) for lo, la in line]
    cum1 = cumulative(pts1)
    km_per_px1 = proj.deg_per_px(1) * 111.0
    for g in active:
        g["t"], d = project_on_line(pts1, cum1, proj.px(g["lon"], g["lat"], 1))
        g["off_km"] = d * km_per_px1
    active = [g for g in active if g["off_km"] < 5.0]

    with cf.ThreadPoolExecutor(6) as ex:
        floods = list(ex.map(lambda g: flood_stages(g["id"], latest[g["id"]][1]), active))
    datum_drops = 0
    for g, f in zip(active, floods):
        if f == "datum":
            datum_drops += 1
            f = None
        g["f"] = f

    pix = {sc: raster_river(proj, line, int(sc)) for sc in CANVASES}

    def index_of(t, plist):
        best, bi = 2.0, 0
        for i, p in enumerate(plist):
            if abs(p[2] - t) < best:
                best, bi = abs(p[2] - t), i
        return bi

    for g in active:
        g["i"] = {sc: index_of(g["t"], pix[sc]) for sc in CANVASES}

    # thin: best-informed gauges first, keep MIN gap along the 1x line
    n1 = len(pix["1"])
    gap = max(MIN_GAUGE_GAP_1X, n1 // MAX_GAUGES)

    def prio(g):
        return 1 if g["f"] else 0

    chosen = []
    for g in sorted(active, key=lambda g: (-prio(g), g["t"])):
        if len(chosen) >= MAX_GAUGES:
            break
        if all(abs(g["i"]["1"] - c["i"]["1"]) >= gap for c in chosen):
            chosen.append(g)
    chosen.sort(key=lambda g: g["t"])

    # percentiles: period-of-record statistics, else five years of daily means
    # (per-gauge statistics cost one request each, so only those already fetched are used)
    rec = [record_stats(g["id"], cache_only=True) for g in chosen]
    if CACHE_ONLY_USGS:
        old_batches = stage_stats_batch([g["id"] for g in active])
        rec = [r or old_batches.get(g["id"]) for g, r in zip(chosen, rec)]
    missing = [g["id"] for g, r in zip(chosen, rec) if not r]
    daily = stage_stats_batch(missing) if missing else {}
    for g, r in zip(chosen, rec):
        g["p"] = r or daily.get(g["id"])
    # no gage-height percentiles: flow (cfs) percentiles instead, coloured by live flow
    noq = [g for g in chosen if not g["p"]]
    qmap = stage_stats_batch([g["id"] for g in noq], "00060") if noq else {}
    for g in chosen:
        g["q"] = None if g["p"] else (record_stats(g["id"], "00060", cache_only=True) or qmap.get(g["id"]))

    # outlines
    bbox = proj.bbox()
    off = proj.deg_per_px(2) * 0.5
    states = tiger_rings(0, bbox, off)
    counties = tiger_rings(1, bbox, off)
    outlines = {}
    for sc in CANVASES:
        outlines[sc] = {
            "s": encode_bits(raster_rings(proj, states, int(sc))),
            "c": encode_bits(raster_rings(proj, counties, int(sc))),
        }

    print(
        "%-12s ms=%-8s %6.0f km  pts=%-6d px1=%-4d px2=%-4d gauges %3d cand %3d active %2d chosen (%d stage pct, %d flow pct, %d flood, %d datum-drop)  %.0fs"
        % (
            key,
            ms_id,
            ms.get("lengthkm") or 0,
            len(line),
            len(pix["1"]),
            len(pix["2"]),
            len(cands),
            len(active),
            len(chosen),
            sum(1 for g in chosen if g["p"]),
            sum(1 for g in chosen if g["q"]),
            sum(1 for g in chosen if g["f"]),
            datum_drops,
            time.time() - t0,
        ),
        flush=True,
    )
    return {
        "key": key,
        "label": label,
        "short": short,
        "mainstem": ms_id,
        "lengthkm": ms.get("lengthkm"),
        "line": {sc: {"x": pix[sc][0][0], "y": pix[sc][0][1], "c": chain_code(pix[sc])} for sc in CANVASES},
        "outlines": outlines,
        "gauges": [
            {"id": g["id"], "name": g["name"], "i": g["i"], "p": g["p"], "f": g["f"], "q": g["q"]} for g in chosen
        ],
    }


def star_value(v):
    if v is None:
        return "None"
    if isinstance(v, bool):
        return "True" if v else "False"
    if isinstance(v, (int,)):
        return str(v)
    if isinstance(v, float):
        s = ("%.2f" % v).rstrip("0").rstrip(".")
        if "." not in s:
            s += ".0"
        return s
    if isinstance(v, str):
        return json.dumps(v)
    if isinstance(v, list):
        return "[" + ", ".join(star_value(x) for x in v) + "]"
    raise TypeError(v)


MAX_COUNTY_FILL = float(os.environ.get("RIVERMAP_COUNTY_FILL", "0.6"))  # county lines covering more of the canvas than this are left out


def bit_fill(enc, sc):
    W, H, _ = CANVASES[sc]
    ones = sum(bin(B64.index(c)).count("1") for c in enc)
    return ones / float(W * H)


def emit(rivers):
    dropped = [r["key"] for r in rivers if len(r["gauges"]) < 2]
    if dropped:
        print("  left out (fewer than 2 live gauges): %s" % ", ".join(dropped))
    rivers = [r for r in rivers if len(r["gauges"]) >= 2]
    out = ["# --- GENERATED by gen_rivers.py; do not edit by hand ---", ""]
    out.append("RIVERS = [")
    for r in rivers:
        out.append("    {")
        out.append('        "key": %s,' % json.dumps(r["key"]))
        out.append('        "label": %s,' % json.dumps(r["label"]))
        out.append('        "short": %s,' % json.dumps(r["short"]))
        for sc in CANVASES:
            ln = r["line"][sc]
            out.append('        "line%s": (%d, %d, "%s"),' % (sc, ln["x"], ln["y"], ln["c"]))
            out.append('        "states%s": "%s",' % (sc, r["outlines"][sc]["s"]))
            cty = r["outlines"][sc]["c"]
            fill = bit_fill(cty, sc)
            if fill > MAX_COUNTY_FILL:
                print("  %s %sx: counties cover %.0f%%, left out" % (r["key"], sc, fill * 100))
                cty = ""
            out.append('        "counties%s": "%s",' % (sc, cty))
        out.append('        "gauges": [')
        for g in r["gauges"]:
            out.append(
                '            ("%s", %d, %d, %s, %s, %s),'
                % (g["id"], g["i"]["1"], g["i"]["2"], star_value(g["p"]), star_value(g["f"]), star_value(g.get("q")))
            )
        out.append("        ],")
        out.append("    },")
    out.append("]")
    out.append("")
    out.append("# --- END GENERATED ---")
    data = "\n".join(out) + "\n"
    with open(APP, encoding="utf-8") as f:
        src = f.read()
    start = src.index("# --- GENERATED")
    end = src.index("# --- END GENERATED ---") + len("# --- END GENERATED ---\n")
    with open(APP, "w", encoding="utf-8", newline="\n") as f:
        f.write(src[:start] + data + src[end:])
    print("wrote %d rivers into %s (%d bytes)" % (len(rivers), APP, os.path.getsize(APP)))


def main():
    if sys.argv[1:] == ["--emit"]:
        with open(RUN_FILE, encoding="utf-8") as f:
            emit(json.load(f))
        return
    want = set(sys.argv[1:])
    specs = [s for s in RIVERS if not want or s[0] in want]
    results = {}
    with cf.ThreadPoolExecutor(2) as ex:
        futs = {ex.submit(build_river, s): s[0] for s in specs}
        for fu in cf.as_completed(futs):
            k = futs[fu]
            try:
                results[k] = fu.result()
            except Exception as e:  # noqa: BLE001
                print("FAILED %s: %s" % (k, e), flush=True)
    rivers = [results[s[0]] for s in specs if s[0] in results]
    if want:
        # partial run: keep the other rivers from the previous run
        prev = {}
        if os.path.exists(RUN_FILE):
            with open(RUN_FILE, encoding="utf-8") as f:
                prev = {r["key"]: r for r in json.load(f)}
        prev.update({r["key"]: r for r in rivers})
        rivers = [prev[s[0]] for s in RIVERS if s[0] in prev]
    with open(RUN_FILE, "w", encoding="utf-8") as f:
        json.dump(rivers, f)
    emit(rivers)


if __name__ == "__main__":
    main()
