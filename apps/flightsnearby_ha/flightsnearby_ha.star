"""
Applet: Flights Nearby HA Flightradar
Summary: Flights Nearby HA
Description: Flights nearby using data from Flightradar integration in HA
Author: motoridersd
"""

load("cache.star", "cache")
load("db.star", "DB")
load("encoding/json.star", "json")
load("filter.star", "filter")
load("http.star", "http")
load("images/airliner.png", AIRLINER_ASSET = "file")
load("images/airliner@2x.png", AIRLINER_ASSET_2X = "file")
load("images/balloon.png", BALLOON_ASSET = "file")
load("images/balloon@2x.png", BALLOON_ASSET_2X = "file")
load("images/cessna.png", CESSNA_ASSET = "file")
load("images/cessna@2x.png", CESSNA_ASSET_2X = "file")
load("images/ground_emergency.png", GROUND_EMERGENCY_ASSET = "file")
load("images/ground_emergency@2x.png", GROUND_EMERGENCY_ASSET_2X = "file")
load("images/ground_fixed.png", GROUND_FIXED_ASSET = "file")
load("images/ground_fixed@2x.png", GROUND_FIXED_ASSET_2X = "file")
load("images/ground_service.png", GROUND_SERVICE_ASSET = "file")
load("images/ground_service@2x.png", GROUND_SERVICE_ASSET_2X = "file")
load("images/ground_unknown.png", GROUND_UNKNOWN_ASSET = "file")
load("images/ground_unknown@2x.png", GROUND_UNKNOWN_ASSET_2X = "file")
load("images/heavy_2e.png", HEAVY_2E_ASSET = "file")
load("images/heavy_2e@2x.png", HEAVY_2E_ASSET_2X = "file")
load("images/heavy_4e.png", HEAVY_4E_ASSET = "file")
load("images/heavy_4e@2x.png", HEAVY_4E_ASSET_2X = "file")
load("images/helicopter.png", HELICOPTER_ASSET = "file")
load("images/helicopter@2x.png", HELICOPTER_ASSET_2X = "file")
load("images/hi_perf.png", HI_PERF_ASSET = "file")
load("images/hi_perf@2x.png", HI_PERF_ASSET_2X = "file")
load("images/jet_nonswept.png", JET_NONSWEPT_ASSET = "file")
load("images/jet_nonswept@2x.png", JET_NONSWEPT_ASSET_2X = "file")
load("images/jet_swept.png", JET_SWEPT_ASSET = "file")
load("images/jet_swept@2x.png", JET_SWEPT_ASSET_2X = "file")
load("images/twin_large.png", TWIN_LARGE_ASSET = "file")
load("images/twin_large@2x.png", TWIN_LARGE_ASSET_2X = "file")
load("images/twin_small.png", TWIN_SMALL_ASSET = "file")
load("images/twin_small@2x.png", TWIN_SMALL_ASSET_2X = "file")
load("images/unknown.png", UNKNOWN_ASSET = "file")
load("images/unknown@2x.png", UNKNOWN_ASSET_2X = "file")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")

SHAPES = {
    "airliner": {"1x": AIRLINER_ASSET, "2x": AIRLINER_ASSET_2X},
    "balloon": {"1x": BALLOON_ASSET, "2x": BALLOON_ASSET_2X},
    "cessna": {"1x": CESSNA_ASSET, "2x": CESSNA_ASSET_2X},
    "heavy_2e": {"1x": HEAVY_2E_ASSET, "2x": HEAVY_2E_ASSET_2X},
    "heavy_4e": {"1x": HEAVY_4E_ASSET, "2x": HEAVY_4E_ASSET_2X},
    "helicopter": {"1x": HELICOPTER_ASSET, "2x": HELICOPTER_ASSET_2X},
    "hi_perf": {"1x": HI_PERF_ASSET, "2x": HI_PERF_ASSET_2X},
    "jet_nonswept": {"1x": JET_NONSWEPT_ASSET, "2x": JET_NONSWEPT_ASSET_2X},
    "jet_swept": {"1x": JET_SWEPT_ASSET, "2x": JET_SWEPT_ASSET_2X},
    "twin_large": {"1x": TWIN_LARGE_ASSET, "2x": TWIN_LARGE_ASSET_2X},
    "twin_small": {"1x": TWIN_SMALL_ASSET, "2x": TWIN_SMALL_ASSET_2X},
    "ground_emergency": {"1x": GROUND_EMERGENCY_ASSET, "2x": GROUND_EMERGENCY_ASSET_2X},
    "ground_service": {"1x": GROUND_SERVICE_ASSET, "2x": GROUND_SERVICE_ASSET_2X},
    "ground_unknown": {"1x": GROUND_UNKNOWN_ASSET, "2x": GROUND_UNKNOWN_ASSET_2X},
    "ground_fixed": {"1x": GROUND_FIXED_ASSET, "2x": GROUND_FIXED_ASSET_2X},
    "unknown": {"1x": UNKNOWN_ASSET, "2x": UNKNOWN_ASSET_2X},
}

TYPE_DESIGNATOR_ICONS = {
    "A10": "hi_perf",
    "A148": "hi_perf",
    "A225": "heavy_4e",
    "A3": "hi_perf",
    "A37": "jet_nonswept",
    "A5": "cessna",
    "A6": "hi_perf",
    "A700": "jet_nonswept",
    "AC80": "twin_small",
    "AC90": "twin_small",
    "AC95": "twin_small",
    "AJ27": "jet_nonswept",
    "AJET": "hi_perf",
    "AN28": "twin_small",
    "ARCE": "hi_perf",
    "AT3": "hi_perf",
    "ATG1": "jet_nonswept",
    "B18T": "twin_small",
    "B190": "twin_small",
    "B25": "twin_large",
    "B350": "twin_small",
    "B52": "heavy_4e",
    "B712": "jet_swept",
    "B721": "airliner",
    "B722": "airliner",
    "BALL": "balloon",
    "BE10": "twin_small",
    "BE20": "twin_small",
    "BE30": "twin_small",
    "BE32": "twin_small",
    "BE40": "jet_nonswept",
    "BE99": "twin_small",
    "BE9L": "twin_small",
    "BE9T": "twin_small",
    "BN2T": "twin_small",
    "BPOD": "jet_swept",
    "BU20": "twin_small",
    "C08T": "jet_swept",
    "C125": "twin_small",
    "C212": "twin_small",
    "C21T": "twin_small",
    "C22J": "jet_nonswept",
    "C25A": "jet_nonswept",
    "C25B": "jet_nonswept",
    "C25C": "jet_nonswept",
    "C25M": "jet_nonswept",
    "C425": "twin_small",
    "C441": "twin_small",
    "C46": "twin_large",
    "C500": "jet_nonswept",
    "C501": "jet_nonswept",
    "C510": "jet_nonswept",
    "C525": "jet_nonswept",
    "C526": "jet_nonswept",
    "C550": "jet_nonswept",
    "C551": "jet_nonswept",
    "C55B": "jet_nonswept",
    "C560": "jet_nonswept",
    "C56X": "jet_nonswept",
    "C650": "jet_swept",
    "C680": "jet_nonswept",
    "C68A": "jet_nonswept",
    "C750": "jet_swept",
    "C82": "twin_large",
    "CKUO": "hi_perf",
    "CL30": "jet_swept",
    "CL35": "jet_swept",
    "CL60": "jet_swept",
    "CRJ1": "jet_swept",
    "CRJ2": "jet_swept",
    "CRJ7": "jet_swept",
    "CRJ9": "jet_swept",
    "CRJX": "jet_swept",
    "CVLP": "twin_large",
    "D228": "twin_small",
    "DA36": "hi_perf",
    "DA50": "airliner",
    "DC10": "heavy_2e",
    "DC3": "twin_large",
    "DC3S": "twin_large",
    "DHA3": "twin_small",
    "DHC4": "twin_large",
    "DHC6": "twin_small",
    "DLH2": "hi_perf",
    "E110": "twin_small",
    "E135": "jet_swept",
    "E145": "jet_swept",
    "E29E": "hi_perf",
    "E45X": "jet_swept",
    "E500": "jet_nonswept",
    "E50P": "jet_nonswept",
    "E545": "jet_swept",
    "E55P": "jet_nonswept",
    "EA50": "jet_nonswept",
    "EFAN": "jet_nonswept",
    "EFUS": "hi_perf",
    "ELIT": "jet_nonswept",
    "EUFI": "hi_perf",
    "F1": "hi_perf",
    "F100": "jet_swept",
    "F111": "hi_perf",
    "F117": "hi_perf",
    "F14": "hi_perf",
    "F15": "hi_perf",
    "F22": "hi_perf",
    "F2TH": "jet_swept",
    "F4": "hi_perf",
    "F406": "twin_small",
    "F5": "hi_perf",
    "F900": "jet_swept",
    "FA50": "jet_swept",
    "FA5X": "jet_swept",
    "FA7X": "jet_swept",
    "FA8X": "jet_swept",
    "FJ10": "jet_nonswept",
    "FOUG": "jet_nonswept",
    "FURY": "hi_perf",
    "G150": "jet_swept",
    "G3": "airliner",
    "GENI": "hi_perf",
    "GL5T": "jet_swept",
    "GLEX": "jet_swept",
    "GLF2": "jet_swept",
    "GLF3": "jet_swept",
    "GLF4": "jet_swept",
    "GLF5": "jet_swept",
    "GLF6": "jet_swept",
    "GSPN": "jet_nonswept",
    "H25A": "jet_swept",
    "H25B": "jet_swept",
    "H25C": "jet_swept",
    "HA4T": "airliner",
    "HDJT": "jet_nonswept",
    "HERN": "jet_swept",
    "J8A": "hi_perf",
    "J8B": "hi_perf",
    "JH7": "hi_perf",
    "JS31": "twin_small",
    "JS32": "twin_small",
    "JU52": "twin_small",
    "L101": "heavy_2e",
    "LAE1": "hi_perf",
    "LEOP": "jet_nonswept",
    "LJ23": "jet_nonswept",
    "LJ24": "jet_nonswept",
    "LJ25": "jet_nonswept",
    "LJ28": "jet_nonswept",
    "LJ31": "jet_nonswept",
    "LJ35": "jet_nonswept",
    "LJ40": "jet_nonswept",
    "LJ45": "jet_nonswept",
    "LJ55": "jet_nonswept",
    "LJ60": "jet_nonswept",
    "LJ70": "jet_nonswept",
    "LJ75": "jet_nonswept",
    "LJ85": "jet_nonswept",
    "LTNG": "hi_perf",
    "M28": "twin_small",
    "MD11": "heavy_2e",
    "MD81": "jet_swept",
    "MD82": "jet_swept",
    "MD83": "jet_swept",
    "MD87": "jet_swept",
    "MD88": "jet_swept",
    "MD90": "jet_swept",
    "ME62": "jet_nonswept",
    "METR": "hi_perf",
    "MG19": "hi_perf",
    "MG25": "hi_perf",
    "MG29": "hi_perf",
    "MG31": "hi_perf",
    "MG44": "hi_perf",
    "MH02": "jet_nonswept",
    "MS76": "jet_nonswept",
    "MT2": "hi_perf",
    "MU2": "twin_small",
    "P180": "twin_small",
    "P2": "twin_large",
    "P68T": "twin_small",
    "PA47": "jet_nonswept",
    "PAT4": "twin_small",
    "PAY1": "twin_small",
    "PAY2": "twin_small",
    "PAY3": "twin_small",
    "PAY4": "twin_small",
    "PIAE": "hi_perf",
    "PIT4": "hi_perf",
    "PITE": "hi_perf",
    "PRM1": "jet_nonswept",
    "PRTS": "jet_nonswept",
    "Q5": "hi_perf",
    "R721": "airliner",
    "R722": "airliner",
    "RFAL": "hi_perf",
    "ROAR": "hi_perf",
    "S3": "hi_perf",
    "S32E": "hi_perf",
    "S37": "hi_perf",
    "S601": "jet_nonswept",
    "SATA": "jet_nonswept",
    "SB05": "jet_nonswept",
    "SC7": "twin_small",
    "SF50": "jet_nonswept",
    "SJ30": "jet_nonswept",
    "SLCH": "heavy_4e",
    "SM60": "twin_small",
    "SOL1": "jet_swept",
    "SOL2": "jet_swept",
    "SP33": "jet_nonswept",
    "SR71": "hi_perf",
    "SS2": "hi_perf",
    "SU15": "hi_perf",
    "SU24": "hi_perf",
    "SU25": "hi_perf",
    "SU27": "hi_perf",
    "SW2": "twin_small",
    "SW3": "twin_small",
    "SW4": "twin_small",
    "T154": "airliner",
    "T2": "jet_nonswept",
    "T22M": "hi_perf",
    "T37": "jet_nonswept",
    "T38": "jet_nonswept",
    "T4": "hi_perf",
    "TJET": "jet_nonswept",
    "TOR": "hi_perf",
    "TRIM": "twin_small",
    "TRIS": "twin_small",
    "TRMA": "twin_small",
    "TU22": "hi_perf",
    "VAUT": "hi_perf",
    "Y130": "hi_perf",
    "Y141": "airliner",
    "YK28": "hi_perf",
    "YK38": "airliner",
    "YK40": "airliner",
    "YK42": "airliner",
    "YURO": "hi_perf",
}
TYPE_DESCRIPTION_ICONS = {
    "H": "helicopter",
    "L1P": "cessna",
    "L1T": "cessna",
    "L1J": "hi_perf",
    "L2P": "twin_small",
    "L2T": "twin_large",
    "L2J-L": "jet_swept",
    "L2J-M": "airliner",
    "L2J-H": "heavy_2e",
    "L4T": "heavy_4e",
    "L4J-H": "heavy_4e",
}
CATEGORY_ICONS = {
    "A1": "cessna",
    "A2": "jet_nonswept",
    "A3": "airliner",
    "A4": "heavy_2e",
    "A5": "heavy_4e",
    "A6": "hi_perf",
    "A7": "helicopter",
    "B1": "cessna",
    "B2": "balloon",
    "B4": "cessna",
    "B7": "hi_perf",
    "C0": "ground_unknown",
    "C1": "ground_emergency",
    "C2": "ground_service",
    "C3": "ground_fixed",
    "C4": "ground_fixed",
    "C5": "ground_fixed",
    "C6": "ground_unknown",
    "C7": "ground_unknown",
}

def get_airplane_shape(flight):
    print(flight)
    if "aircraft_code" in flight:
        type_designator = flight["aircraft_code"]
    else:
        type_designator = None
    if type_designator in DB:
        x = DB[type_designator]
        type_description = x["desc"]
        wtc = x["wtc"]
    else:
        type_description = None
        wtc = None

    if type_designator in TYPE_DESIGNATOR_ICONS:
        return SHAPES[TYPE_DESIGNATOR_ICONS[type_designator]]

    if type_description != None and len(type_description) == 3:
        if wtc != None and len(wtc) == 1:
            type_description_with_wtc = type_description + "-" + wtc
            if type_description_with_wtc in TYPE_DESCRIPTION_ICONS:
                return SHAPES[TYPE_DESCRIPTION_ICONS[type_description_with_wtc]]

        if type_description in TYPE_DESCRIPTION_ICONS:
            return SHAPES[TYPE_DESCRIPTION_ICONS[type_description]]

        basic_type = type_description[0]
        if basic_type in TYPE_DESCRIPTION_ICONS:
            return SHAPES[TYPE_DESCRIPTION_ICONS[basic_type]]

    return SHAPES["unknown"]

def get_entity_status(ha_server, entity_id, token):
    if ha_server == None:
        #fail("Home Assistant server not configured")
        return None

    if entity_id == None:
        #fail("Entity ID not configured")
        return None

    if token == None:
        #fail("Bearer token not configured")
        return None

    state_res = None
    cache_key = "%s.%s" % (ha_server, entity_id)
    cached_res = cache.get(cache_key)
    if cached_res != None:
        state_res = json.decode(cached_res)
    else:
        rep = http.get("%s/api/states/%s" % (ha_server, entity_id), headers = {
            "Authorization": "Bearer %s" % token,
        })
        if rep.status_code != 200:
            return None

        state_res = rep.json()
        cache.set(cache_key, rep.body(), ttl_seconds = 10)
    return state_res

def get_ha_location(base_url, token):
    url = "%s/api/config" % base_url
    res = http.get(url, headers = {"Authorization": "Bearer %s" % token, "content-type": "application/json"}, ttl_seconds = 86400)
    if res.status_code != 200:
        return None
    data = res.json()
    return data.get("latitude"), data.get("longitude")

def calculate_radar_position(home_lat, home_lon, plane_lat, plane_lon, angle_offset = 0, radius_km = 50):
    # Simplified equirectangular projection for small distances
    # Scale: 32x32 radar screen, center at (16, 16)

    # Approx km per degree
    lat_deg_km = 111.0
    lon_deg_km = 111.0 * math.cos(math.radians(home_lat))

    # Relative coordinates in KM (Standard math: +Y North, +X East)
    # Original dy_km was (home - plane) * lat_deg => home(0) - plane(1) = -1. So +1 lat (North) gives -1 dy.
    # We want Standard Math Y: North is +Y. So (plane - home).
    rel_y = (plane_lat - home_lat) * lat_deg_km
    rel_x = (plane_lon - home_lon) * lon_deg_km

    # Rotate if offset provided
    if angle_offset != 0:
        angle_rad = math.radians(angle_offset)
        # Rotate point by +angle_offset (CCW) corresponds to rotating axes by -angle_offset?
        # Based on analysis: Point (1,0) [East] with Offset 90 should define East as Up (0,1).
        # (1,0) -> (0,1) is +90 deg rotation.

        cos_a = math.cos(angle_rad)
        sin_a = math.sin(angle_rad)

        rx = rel_x * cos_a - rel_y * sin_a
        ry = rel_x * sin_a + rel_y * cos_a
        rel_x = rx
        rel_y = ry

    scale_factor = 16.0 / radius_km

    # Map to screen coordinates
    # Screen X: 16 + rel_x * scale
    # Screen Y: 16 - rel_y * scale (because Y is inverted on screen: Up is -y)

    x = 16 + (rel_x * scale_factor)
    y = 16 - (rel_y * scale_factor)

    # Clamp to screen
    x = max(0, min(32, x))
    y = max(0, min(32, y))

    return x, y

def skip_execution():
    print("skip_execution")
    return []

def render_radar_view(flight, home_lat, home_lon, angle_offset = 0, scale = 1, colors = None, plane_img = None):
    if not home_lat or not home_lon:
        return render.Box(width = 64 * scale, height = 32 * scale, color = "#000", child = render.Text("No Loc"))

    plane_lat = flight["latitude"]
    plane_lon = flight["longitude"]

    px, py = calculate_radar_position(home_lat, home_lon, plane_lat, plane_lon, angle_offset)

    radar_visual = render.Stack(
        children = [
            render.Box(width = 32 * scale, height = 32 * scale, color = "#001100"),
            # Outer ring
            render.Circle(diameter = 32 * scale, color = colors["radar"]),
            render.Padding(
                pad = (1 * scale, 1 * scale, 0, 0),
                child = render.Circle(diameter = 30 * scale, color = "#001100"),
            ),
            # Inner ring
            render.Padding(
                pad = (8 * scale, 8 * scale, 0, 0),
                child = render.Circle(diameter = 16 * scale, color = colors["radar"]),
            ),
            render.Padding(
                pad = (9 * scale, 9 * scale, 0, 0),
                child = render.Circle(diameter = 14 * scale, color = "#001100"),
            ),
            # Center
            render.Padding(
                pad = (15 * scale, 15 * scale, 0, 0),
                child = render.Box(width = 2 * scale, height = 2 * scale, color = colors["home"]),
            ),
            # Plane Symbol
            # Wrapped in a container to center the rotation
            render.Padding(
                pad = (int((px * scale) - (8 * scale)), int((py * scale) - (8 * scale)), 0, 0),
                child = render.Box(
                    width = 16 * scale,
                    height = 16 * scale,
                    child = render.Column(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            filter.Rotate(
                                angle = flight["heading"] - angle_offset,
                                child = render.Image(src = plane_img, width = 10 * scale, height = 10 * scale) if plane_img else render.Box(width = 2 * scale, height = 2 * scale, color = "#ff0000"),
                            ),
                        ],
                    ),
                ),
            ),
        ],
    )

    return render.Row(
        expanded = True,
        main_align = "start",
        cross_align = "center",
        children = [
            radar_visual,
            render.Box(width = 1 * scale, height = 32 * scale, color = "#000"),  # Spacer
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "start",
                children = [
                    render.Text("Alt: %dk" % int((flight.get("altitude", 0) + 500) / 1000), font = "tom-thumb", color = colors["alt"]),
                    render.Text("Dst: %d" % int(flight.get("distance", 0)), font = "tom-thumb", color = colors["dst"]),
                    render.Text("Hdg: %d" % int(flight.get("heading", 0)), font = "tom-thumb", color = colors["hdg"]),
                    render.Text("Spd: %d" % int(flight.get("ground_speed", 0)), font = "tom-thumb", color = colors["spd"]),
                ],
            ),
        ],
    )

def filter_flight(flight, show_all_aircraft = False):
    return all([
        show_all_aircraft or flight["airline_icao"],
        flight["altitude"] >= 1000,
    ])

def main(config):
    #If hardcoding HA info in applet, replace values below with yours. REMOVE EVERYTHING AFTER THE = and add your values
    #For example, ha_server = "http://192.168.1.100:8123"
    #The config.get strings are only used for serving the applet via pixlet serve
    #ha_server, entity_id and token have to be updated with your own values.
    ha_server = config.get("homeassistant_server")  #Don't forget to include a port at the end of the URL if using one
    entity_id = config.get("homeassistant_entity_id")  #The FlightRadar24 Integration sensor, default is 'sensor.flightradar24_current_in_area'
    token = config.get("homeassistant_token")  #Your long lived access token
    radar_offset_str = config.get("radar_degree_offset", "0")
    radar_offset = int(radar_offset_str) if radar_offset_str.isdigit() else 0
    show_all_aircraft = config.bool("show_all_aircraft")

    airhex_url2 = config.get("airhex_tail_direction", "_30_30_f.png")
    if canvas.is2x():
        airhex_url2 = airhex_url2.replace("30_30", "60_60")
    airhex_url1 = "https://content.airhex.com/content/logos/airlines_"

    scale = 2 if canvas.is2x() else 1

    sorted_matches = []

    home_lat = None
    home_lon = None
    media_image = None

    if not ha_server or not entity_id or not token:
        # Dummy data for preview
        sorted_matches = [{
            "airline_icao": "UAL",
            "altitude": 35000,
            "flight_number": "UA531",
            "callsign": "UAL531",
            "airport_origin_code_iata": "DEN",
            "airport_destination_code_iata": "LAX",
            "aircraft_code": "B39M",
            "heading": 45,
            "latitude": 39.9,
            "longitude": -104.9,
            "distance": 10,
            "ground_speed": 343,
        }]

        # Dummy home location for preview
        home_lat = 39.8
        home_lon = -105.0
    else:
        entity_status = get_entity_status(ha_server, entity_id, token)
        extracted_attributes = entity_status["attributes"] if entity_status and "attributes" in entity_status else dict()
        flights = extracted_attributes["flights"] if "flights" in extracted_attributes else dict()
        matches_filters = [flight for flight in flights if filter_flight(flight, show_all_aircraft)]
        sorted_matches = sorted(
            matches_filters,
            key = lambda flight: flight["altitude"],
            reverse = False,
        )

        loc = get_ha_location(ha_server, token)
        if loc:
            home_lat, home_lon = loc

    if len(sorted_matches) == 0:
        return skip_execution()

    if media_image == None:
        if "airline_icao" in sorted_matches[0] and sorted_matches[0]["airline_icao"]:
            res = http.get("%s%s%s" % (airhex_url1, sorted_matches[0]["airline_icao"], airhex_url2), ttl_seconds = 86400)
            media_image = res.body()
        else:
            # Use small icon as fallback for non-commercial
            airplane_shape = get_airplane_shape(sorted_matches[0])
            media_image = airplane_shape["2x"].readall() if canvas.is2x() else airplane_shape["1x"].readall()

    airplane_shape = get_airplane_shape(sorted_matches[0])

    # Always set tiny_ico
    tiny_ico = airplane_shape["2x"].readall() if canvas.is2x() else airplane_shape["1x"].readall()

    lines = []

    #make a list of lines we'd prefer to have in order, we'll display the top 3 of them.
    if "flight_number" in sorted_matches[0] and sorted_matches[0]["flight_number"]:
        lines.append(render.Text("%s" % sorted_matches[0]["flight_number"]))
    elif "callsign" in sorted_matches[0] and sorted_matches[0]["callsign"]:
        lines.append(render.Text("%s" % sorted_matches[0]["callsign"]))

    if ("airport_origin_code_iata" in sorted_matches[0] and sorted_matches[0]["airport_origin_code_iata"]) or ("airport_destination_code_iata" in sorted_matches[0] and sorted_matches[0]["airport_destination_code_iata"]):
        origin = sorted_matches[0].get("airport_origin_code_iata") or "?"
        destination = sorted_matches[0].get("airport_destination_code_iata") or "?"
        line = render.Row(
            expanded = True,
            main_align = "between_evenly",
            children = [
                render.Text(origin),
                #render.Text("→", color="#00a"),
                render.Text("→", color = "#00a"),
                render.Text(destination),
            ],
        )
        lines.append(line)

    if "aircraft_code" in sorted_matches[0] and sorted_matches[0]["aircraft_code"] != None and tiny_ico:
        line = render.Row(
            children = [
                render.Box(
                    width = 10 * scale,
                    height = 10 * scale,
                    child = filter.Rotate(
                        child = render.Image(tiny_ico, height = 10 * scale),
                        angle = sorted_matches[0].get("heading", 0) - radar_offset,
                    ),
                ),
                render.Text(" %s" % sorted_matches[0]["aircraft_code"]),
            ],
        )
        lines.append(line)
    elif "aircraft_code" in sorted_matches[0] and sorted_matches[0]["aircraft_code"] != None:
        line = render.Text("%s" % sorted_matches[0]["aircraft_code"])
        lines.append(line)

    display = render.Row(
        children = [
            render.Box(
                width = 28 * scale,
                #child = render.Image(ico),
                child = render.Image(src = media_image, height = 30 * scale, width = 30 * scale),
            ),
            render.Box(
                child = render.Column(
                    expanded = True,
                    main_align = "space_evenly",
                    children = lines[:3],
                ),
            ),
        ],
    )

    radar = None
    if home_lat and home_lon:
        radar_colors = {
            "radar": config.get("radar_color", "#003300"),
            "home": config.get("home_color", "#00ff00"),
            "alt": config.get("altitude_color", "#ff0000"),
            "dst": config.get("distance_color", "#00ff00"),
            "hdg": config.get("heading_color", "#0000ff"),
            "spd": config.get("speed_color", "#ffff00"),
        }
        radar = render_radar_view(sorted_matches[0], home_lat, home_lon, radar_offset, scale, radar_colors, tiny_ico)

    if radar:
        return render.Root(
            delay = 7500,
            child = render.Animation(
                children = [display, radar],
            ),
        )

    return render.Root(
        child = display,
    )

def get_schema():
    airhex_logo_option = [
        schema.Option(
            display = "Regular",
            value = "_30_30_t.png",
        ),
        schema.Option(
            display = "Flipped",
            value = "_30_30_f.png",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "homeassistant_server",
                name = "Home Assistant Server",
                desc = "URL of Home Assistant server",
                icon = "server",
            ),
            schema.Text(
                id = "homeassistant_token",
                name = "Bearer Token",
                icon = "key",
                desc = "Long-lived access token for Home Assistant",
            ),
            schema.Text(
                id = "homeassistant_entity_id",
                name = "Entity ID",
                icon = "play",
                desc = "Entity ID of the Flight Radar entity in Home Assistant",
                default = "sensor.flightradar24_current_in_area",
            ),
            schema.Dropdown(
                id = "airhex_tail_direction",
                name = "Tail Direction",
                icon = "plane",
                desc = "Choose which tail logo you would like to use",
                default = airhex_logo_option[1].value,
                options = airhex_logo_option,
            ),
            schema.Toggle(
                id = "show_all_aircraft",
                name = "Show All Aircraft",
                desc = "Show all aircraft, not just commercial ones",
                icon = "plane",
                default = False,
            ),
            schema.Text(
                id = "radar_degree_offset",
                name = "Radar Degree Offset",
                icon = "compass",
                desc = "Rotate the radar view by this many degrees (e.g., 180 for due South).",
                default = "0",
            ),
            schema.Color(
                id = "radar_color",
                name = "Radar Color",
                desc = "Color of the radar rings",
                icon = "brush",
                default = "#003300",
            ),
            schema.Color(
                id = "home_color",
                name = "Home Color",
                desc = "Color of the home dot",
                icon = "brush",
                default = "#00ff00",
            ),
            schema.Color(
                id = "altitude_color",
                name = "Altitude Color",
                desc = "Color of the altitude text",
                icon = "brush",
                default = "#ff0000",
            ),
            schema.Color(
                id = "distance_color",
                name = "Distance Color",
                desc = "Color of the distance text",
                icon = "brush",
                default = "#00ff00",
            ),
            schema.Color(
                id = "heading_color",
                name = "Heading Color",
                desc = "Color of the heading text",
                icon = "brush",
                default = "#0000ff",
            ),
            schema.Color(
                id = "speed_color",
                name = "Speed Color",
                desc = "Color of the speed text",
                icon = "brush",
                default = "#ffff00",
            ),
        ],
    )
