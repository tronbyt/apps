"""
Applet: Constellations
Summary: Displays visible constellations
Description: Displays visible constellations in your sky.
Author: Robert Ison
"""

load("constellations_data.star", "CONSTELLATIONS")
load("encoding/json.star", "json")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

default_location = """
{
	"lat": "28.53933",
	"lng": "-81.38325",
	"description": "Orlando, FL, USA",
	"locality": "Orlando",
	"place_id": "???",
	"timezone": "America/New_York"
}
"""

brightness_colors = [
    "#FFFFFF",  # 0: Brightest (mag < 2.0) - Sirius level
    "#FFEEBB",  # 1: Bright (mag 2.0-2.5) - Altair level
    "#DDDDDD",  # 2: Medium (mag 2.5-3.0) - average
    "#BBBBBB",  # 3: Faint (mag 3.0-3.5)
    "#AAAAAA",  # 4: Faintest (mag > 3.5)
]

def deg_to_rad(deg):
    return deg * math.pi / 180.0

def rad_to_deg(rad):
    return rad * 180.0 / math.pi
def get_constellation_bounds(stars_raw):
    """Calculates the min/max coordinates to auto-zoom perfectly."""
    min_x, max_x = 1000.0, -1000.0
    min_y, max_y = 1000.0, -1000.0
    
    for alt, az, star in stars_raw:
        # Simple projection: Azimuth as X, Altitude as Y
        if az < min_x: min_x = az
        if az > max_x: max_x = az
        if alt < min_y: min_y = alt
        if alt > max_y: max_y = alt
        
    return min_x, max_x, min_y, max_y

def julian_date(t):
    """Julian Date from time object"""
    year = t.year
    month = t.month
    day = t.day + t.hour / 24.0 + t.minute / 1440.0 + t.second / 86400.0

    if month <= 2:
        year -= 1
        month += 12

    A = math.floor(year / 100)
    B = 2 - A + math.floor(A / 4)

    return math.floor(365.25 * (year + 4716)) + math.floor(30.6001 * (month + 1)) + day + B - 1524.5

def local_sidereal_time(t, longitude_deg):
    """Local Sidereal Time in degrees"""
    JD = julian_date(t)
    T = (JD - 2451545.0) / 36525.0

    GMST = 280.46061837 + 360.98564736629 * (JD - 2451545.0) + \
           0.000387933 * T * T - T * T * T / 38710000.0

    GMST = ((GMST % 360) + 360) % 360
    LST = ((GMST + longitude_deg) % 360 + 360) % 360

    return LST

def azimuth_deg(ra_hours, dec_deg, lat_deg, lst_deg):
    """Compass direction (azimuth) in degrees (0=N, 90=E, 180=S, 270=W)"""
    ra_deg = ra_hours * 15.0

    ha_deg = lst_deg - ra_deg
    ha_deg = ((ha_deg % 360) + 360) % 360
    if ha_deg > 180:
        ha_deg -= 360

    ha_rad = deg_to_rad(ha_deg)
    dec_rad = deg_to_rad(dec_deg)
    lat_rad = deg_to_rad(lat_deg)

    # First get altitude (needed for azimuth formula)
    sin_alt = math.sin(dec_rad) * math.sin(lat_rad) + \
              math.cos(dec_rad) * math.cos(lat_rad) * math.cos(ha_rad)
    sin_alt = max(-1.0, min(1.0, sin_alt))
    alt_rad = math.asin(sin_alt)

    # Azimuth formula using altitude
    cos_az_num = math.sin(dec_rad) - math.sin(lat_rad) * sin_alt
    cos_az_den = math.cos(lat_rad) * math.cos(alt_rad)
    cos_az = cos_az_num / cos_az_den if cos_az_den != 0 else 0

    sin_az = math.sin(ha_rad) * math.cos(dec_rad) / math.cos(alt_rad) if math.cos(alt_rad) != 0 else 0

    az_rad = math.atan2(sin_az, cos_az)
    az_deg = rad_to_deg(az_rad)

    return ((az_deg + 360) % 360)

def altitude_deg(ra_hours, dec_deg, lat_deg, lst_deg):
    """Altitude above horizon in degrees"""
    ra_deg = ra_hours * 15.0

    ha_deg = lst_deg - ra_deg
    ha_deg = ((ha_deg % 360) + 360) % 360
    if ha_deg > 180:
        ha_deg -= 360

    # Convert to radians
    ha_rad = deg_to_rad(ha_deg)
    dec_rad = deg_to_rad(dec_deg)
    lat_rad = deg_to_rad(lat_deg)

    # Spherical trig: sin(alt) formula
    sin_alt = math.sin(dec_rad) * math.sin(lat_rad) + \
              math.cos(dec_rad) * math.cos(lat_rad) * math.cos(ha_rad)

    sin_alt = max(-1.0, min(1.0, sin_alt))
    alt_rad = math.asin(sin_alt)

    return rad_to_deg(alt_rad)

def get_cardinal_direction(az_deg):
    directions = [
        "N",
        "NNE",
        "NE",
        "ENE",
        "E",
        "ESE",
        "SE",
        "SSE",
        "S",
        "SSW",
        "SW",
        "WSW",
        "W",
        "WNW",
        "NW",
        "NNW",
    ]

    # Force proper rounding for Starlark
    index = int((az_deg + 11.25) / 22.5 + 0.0001) % 16  # +0.0001 fixes float truncation
    return directions[index]

def visible_constellations(t, lat_deg, lon_deg, threshold_deg = 10.0):
    lst_deg = local_sidereal_time(t, lon_deg)
    visible = []

    for c in CONSTELLATIONS:
        alt = altitude_deg(c["raHours"], c["decDeg"], lat_deg, lst_deg)
        az = azimuth_deg(c["raHours"], c["decDeg"], lat_deg, lst_deg)

        if alt > threshold_deg:
            visible.append({
                "id": c["id"],
                "name": c["name"],
                "altitude": math.floor(alt * 10) / 10.0,
                "azimuth": math.floor(az),
                "direction": get_cardinal_direction(az),
                "raHours": c["raHours"],
                "decDeg": c["decDeg"],
            })

    visible = sorted(visible, key = lambda x: -x["altitude"])
    return visible

def get_constellation_center(constellation_stars, t, lat_deg, lon_deg):
    lst_deg = local_sidereal_time(t, lon_deg)

    visible_stars_raw = []
    total_alt = 0.0
    total_az = 0.0

    for star in constellation_stars:
        alt = altitude_deg(star["raHours"], star["decDeg"], lat_deg, lst_deg)
        az = azimuth_deg(star["raHours"], star["decDeg"], lat_deg, lst_deg)
        if alt > 0.0:
            visible_stars_raw.append((alt, az, star))
            total_alt += alt
            total_az += az

    count = len(visible_stars_raw)
    if count == 0:
        return None, None, []

    center_alt = total_alt / count
    center_az = total_az / count
    return center_alt, center_az, visible_stars_raw

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    return render.Padding(pad = (left, top, right, bottom), child = element)

def render_constellation_screen(selected_constellation, t, lat_deg, lon_deg):
    lst_deg = local_sidereal_time(t, lon_deg)
    constellation_stars = selected_constellation["stars"]

    W = canvas.width()
    H = canvas.height()
    star_area_h = H - 7 
    
    visible_stars_raw = []
    for star in constellation_stars:
        alt = altitude_deg(star["raHours"], star["decDeg"], lat_deg, lst_deg)
        az = azimuth_deg(star["raHours"], star["decDeg"], lat_deg, lst_deg)
        if alt > 0.0:
            visible_stars_raw.append((alt, az, star))

    if not visible_stars_raw:
        return render.Root(child=render.Box(child=render.Text("Below Horizon", font="CG-pixel-4x5-mono")))

    # FIX 1: Use the OFFICIAL center for the direction and altitude indicator
    # This ensures the screen label matches your debug print exactly.
    official_alt = altitude_deg(selected_constellation["raHours"], selected_constellation["decDeg"], lat_deg, lst_deg)
    official_az = azimuth_deg(selected_constellation["raHours"], selected_constellation["decDeg"], lat_deg, lst_deg)
    dir_letter = get_cardinal_direction(official_az)

    # Calculate dynamic bounds for the stars themselves (auto-zoom)
    min_az, max_az, min_alt, max_alt = get_constellation_bounds(visible_stars_raw)
    span_az = max(5.0, max_az - min_az)
    span_alt = max(5.0, max_alt - min_alt)

    layers = [render.Box(width=W, height=H, color="#000011")]

    # Render Stars
    for i, (alt, az, star) in enumerate(visible_stars_raw):
        rel_x = int(2 + ((az - min_az) / span_az) * (W - 8))
        rel_y = int(1 + (1.0 - (alt - min_alt) / span_alt) * (star_area_h - 2))
        
        star_color = brightness_colors[min(i, 4)]
        layers.append(render.Padding(
            pad=(rel_x, rel_y, 0, 0),
            child=render.Box(width=1, height=1, color=star_color)
        ))

    # FIX 2: Height=1 for a single crisp dot
    dot_y = int((1.0 - (official_alt / 90.0)) * (star_area_h - 1))
    alt_color = "#00FF88" if official_alt > 60 else "#FFAA00" if official_alt > 30 else "#FF4400"
    
    layers.append(render.Padding(
        pad=(0, dot_y, 0, 0),
        child=render.Box(width=1, height=1, color=alt_color) 
    ))

    # Bottom Overlay
    layers.append(render.Padding(
        pad=(0, H-7, 0, 0),
        child=render.Box(
            width=W,
            child=render.Row(
                expanded=True,
                main_align="space_around",
                children=[
                    render.Text(dir_letter, color="#00FF44", font="CG-pixel-4x5-mono"),
                    render.Text(selected_constellation["name"][:12], color="#66AAFF", font="CG-pixel-4x5-mono"),
                ]
            )
        )
    ))

    return render.Root(child=render.Stack(children=layers))




def main(config):
    now = time.now()

    location = json.decode(config.get("location", default_location))
    lat = float(location["lat"])
    lon = float(location["lng"])

    visible = visible_constellations(now, lat, lon)

    print("Visible constellations (top 5):")

    #for i, c in enumerate(visible[:5]):
    for i, c in enumerate(visible):
        print("%s: %s (alt: %s°, dir: %s)" % (i + 1, c["name"], c["altitude"], c["direction"]))

    if len(visible) == 0:
        return render.Text("Clear skies!\nNo bright\npatterns visible", color = "#88AAFF")

    # Find full constellation data (with stars) matching top visible
    featured = None
    for c in CONSTELLATIONS:
        if c["id"] == visible[0]["id"]:
            featured = c
            break

    if featured == None:
        featured = CONSTELLATIONS[0]  # Fallback

    return render_constellation_screen(featured, now, lat, lon)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Your location to determine if the selected planet is visible.",
                icon = "locationDot",
            ),
        ],
    )
