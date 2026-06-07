load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# Local logos: add a load() + entry in LOCAL_LOGOS for each airline.
# Files go in images/<IATA>.png (16x16, icon only, no text).
# Uncomment each line once you've added the image file.
# load("images/AA.png", _AA = "file")
# load("images/AS.png", _AS = "file")
# load("images/B6.png", _B6 = "file")
# load("images/DL.png", _DL = "file")
# load("images/F9.png", _F9 = "file")
# load("images/HA.png", _HA = "file")
# load("images/NK.png", _NK = "file")
# load("images/SW.png", _SW = "file")  # Southwest uses WN IATA code
# load("images/UA.png", _UA = "file")
# load("images/WN.png", _WN = "file")

LOCAL_LOGOS = {
    # "AA": _AA,
    # "AS": _AS,
    # "B6": _B6,
    # "DL": _DL,
    # "F9": _F9,
    # "HA": _HA,
    # "NK": _NK,
    # "UA": _UA,
    # "WN": _WN,
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
    local = LOCAL_LOGOS.get(iata_code)
    if local:
        return local
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

    # Pick the closest flight, preferring ones with route data
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
                        render.Box(width = 16, height = 16),
                        render.Column(
                            children = [
                                render.Marquee(
                                    width = 32,
                                    child = render.Text(content = flight_num, color = "#FFFFFF", font = "tb-8"),
                                ),
                                render.Marquee(
                                    width = 32,
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
