load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# Airline logos embedded as base64-encoded 32x32 PNGs.
# To add a new airline: encode with `base64 -i logo.png | tr -d '\n'`
# and add a constant + entry in LOCAL_LOGOS below.
_AA_B64 = "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"
_AS_B64 = "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"
_B6_B64 = "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"
_DL_B64 = "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"
_F9_B64 = "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"
_UA_B64 = "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"
_WN_B64 = "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"

LOCAL_LOGOS = {
    "AA": _AA_B64,
    "AS": _AS_B64,
    "B6": _B6_B64,
    "DL": _DL_B64,
    "F9": _F9_B64,
    "UA": _UA_B64,
    "WN": _WN_B64,
}

FR24_BASE = "https://fr24api.flightradar24.com"
LOGO_BASE = "https://pics.avs.io/32/32"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "FR24 API Token",
                desc = "Your Flightradar24 API Bearer token (fr24api.flightradar24.com)",
                icon = "key",
                default = "",
            ),
            schema.Text(
                id = "lat",
                name = "Latitude",
                desc = "Your location latitude (e.g. 41.8781)",
                icon = "mapPin",
                default = "",
            ),
            schema.Text(
                id = "lon",
                name = "Longitude",
                desc = "Your location longitude (e.g. -87.6298)",
                icon = "mapPin",
                default = "",
            ),
            schema.Text(
                id = "radius",
                name = "Search Radius (km)",
                desc = "How far to look for aircraft overhead (default: 50)",
                icon = "plane",
                default = "50",
            ),
        ],
    )

def dist_sq(lat1, lon1, lat2, lon2):
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    return dlat * dlat + dlon * dlon

def fmt_alt(alt_ft):
    if alt_ft >= 18000:
        return "FL%d" % (alt_ft // 100)
    if alt_ft >= 1000:
        k = alt_ft // 1000
        r = (alt_ft % 1000) // 100
        if r > 0:
            return "%d,%d00ft" % (k, r)
        return "%d,000ft" % k
    return "%dft" % alt_ft

def iata_from_flight(flight_num):
    code = ""
    for c in flight_num.elems():
        if c >= "0" and c <= "9":
            break
        code = code + c
    return code

def fetch_logo(iata_code):
    if not iata_code:
        return None
    b64 = LOCAL_LOGOS.get(iata_code)
    if b64:
        return base64.decode(b64)
    rep = http.get("%s/%s.png" % (LOGO_BASE, iata_code), ttl_seconds = 86400)
    if rep.status_code != 200:
        return None
    return rep.body()

def main(config):
    api_key = config.get("api_key") or ""
    lat_str = (config.get("lat") or "").strip()
    lon_str = (config.get("lon") or "").strip()
    radius_str = (config.get("radius") or "50").strip()

    if not api_key or not lat_str or not lon_str:
        return error_screen("setup needed")

    lat = float(lat_str)
    lon = float(lon_str)
    radius = float(radius_str) if radius_str else 50.0

    d_lat = radius / 111.0
    d_lon = radius / 85.0
    bounds = "%f,%f,%f,%f" % (lat + d_lat, lat - d_lat, lon - d_lon, lon + d_lon)

    url = "%s/api/live/flight-positions/full?bounds=%s&limit=50" % (FR24_BASE, bounds)
    rep = http.get(
        url,
        headers = {
            "Authorization": "Bearer %s" % api_key,
            "Accept-Version": "v1",
            "Accept": "application/json",
        },
        ttl_seconds = 60,
    )

    if rep.status_code != 200:
        return error_screen("HTTP %d" % rep.status_code)

    data = rep.json()
    flights = (data.get("data") or [])

    if not flights:
        return no_flights_screen()

    best = None
    best_dist = None
    best_has_route = False

    for f in flights:
        flat = f.get("lat")
        flon = f.get("lon")
        if flat == None or flon == None:
            continue
        has_route = (f.get("orig_iata") or "") != "" and (f.get("dest_iata") or "") != ""
        d = dist_sq(lat, lon, flat, flon)
        if best == None:
            best = f
            best_dist = d
            best_has_route = has_route
        elif has_route and not best_has_route:
            best = f
            best_dist = d
            best_has_route = has_route
        elif has_route == best_has_route and d < best_dist:
            best = f
            best_dist = d
            best_has_route = has_route

    if not best:
        return no_flights_screen()

    flight_num = best.get("flight") or best.get("callsign") or "???"
    aircraft_type = best.get("type") or "???"
    orig = best.get("orig_iata") or "???"
    dest = best.get("dest_iata") or "???"
    alt_ft = int(best.get("alt") or 0)
    gspeed = int(best.get("gspeed") or 0)

    iata = iata_from_flight(flight_num)
    logo_bytes = fetch_logo(iata)

    route = "%s>%s" % (orig, dest)
    alt_label = fmt_alt(alt_ft)
    speed_label = "%dkts" % gspeed

    if logo_bytes:
        logo_widget = render.Image(src = logo_bytes, width = 16, height = 16)
    else:
        logo_widget = render.Box(width = 16, height = 16)

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        logo_widget,
                        render.Box(width = 12, height = 16),
                        render.Column(
                            children = [
                                render.Marquee(
                                    width = 36,
                                    child = render.Text(content = flight_num, color = "#FFFFFF", font = "tb-8"),
                                ),
                                render.Marquee(
                                    width = 36,
                                    child = render.Text(content = route, color = "#00CCFF", font = "tb-8"),
                                ),
                            ],
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Text(content = aircraft_type, color = "#6699FF", font = "tb-8"),
                        render.Text(content = speed_label, color = "#FF8844", font = "tb-8"),
                    ],
                ),
                render.Text(content = alt_label, color = "#00FF88", font = "tb-8"),
            ],
        ),
    )

def no_flights_screen():
    return render.Root(
        child = render.Box(
            child = render.Column(
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text(content = "no flights", color = "#555555", font = "tb-8"),
                    render.Text(content = "overhead", color = "#555555", font = "tb-8"),
                ],
            ),
        ),
    )

def error_screen(msg):
    return render.Root(
        child = render.Column(
            children = [
                render.Text(content = "overhead", color = "#FFFFFF", font = "tb-8"),
                render.Text(content = "flights", color = "#FFFFFF", font = "tb-8"),
                render.Text(content = msg, color = "#FF4444", font = "tb-8"),
            ],
        ),
    )
