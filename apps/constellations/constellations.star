"""
Applet: Constellations
Summary: Displays visible constellations
Description: Displays visible constellations in your sky.
Author: Robert Ison
"""

load("render.star","canvas", "render")
load("schema.star", "schema")
load("math.star", "math")
load("time.star", "time")
load("encoding/json.star", "json")  
load("constellations_data.star", "CONSTELLATIONS")

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
    "#AAAAAA"   # 4: Faintest (mag > 3.5)
]

def deg_to_rad(deg):
    return deg * math.pi / 180.0

def rad_to_deg(rad):
    return rad * 180.0 / math.pi

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
        "N", "NNE", "NE", "ENE",
        "E", "ESE", "SE", "SSE", 
        "S", "SSW", "SW", "WSW",
        "W", "WNW", "NW", "NNW"
    ]
    # Force proper rounding for Starlark
    index = int((az_deg + 11.25) / 22.5 + 0.0001) % 16  # +0.0001 fixes float truncation
    return directions[index]
def visible_constellations(t, lat_deg, lon_deg, threshold_deg=10.0):
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
    
    visible = sorted(visible, key=lambda x: -x["altitude"])
    return visible
def get_constellation_center(constellation_stars, t, lat_deg, lon_deg):
    """Calculate center from visible stars - SINGLE source of truth"""
    lst_deg = local_sidereal_time(t, lon_deg)
    total_alt, total_az = 0, 0
    count = 0
    visible_stars_raw = []
    
    for star in constellation_stars:
        alt = altitude_deg(star["raHours"], star["decDeg"], lat_deg, lst_deg)
        az = azimuth_deg(star["raHours"], star["decDeg"], lat_deg, lst_deg)
        if alt > 0.0:
            visible_stars_raw.append((alt, az, star))
            total_alt += alt
            total_az += az
            count += 1
    
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
    
    screen_width = canvas.width()
    screen_height = canvas.height()
    
    brightness_colors = ["#FFFFFF", "#FFEEBB", "#DDDDDD", "#BBBBBB", "#AAAAAA"]
    
    # Calculate center from visible stars
    total_alt, total_az = 0, 0
    count = 0
    visible_stars_raw = []
    
    for star in constellation_stars:
        alt = altitude_deg(star["raHours"], star["decDeg"], lat_deg, lst_deg)
        az = azimuth_deg(star["raHours"], star["decDeg"], lat_deg, lst_deg)
        if alt > 0.0:
            visible_stars_raw.append((alt, az, star))
            total_alt += alt
            total_az += az
            count += 1
    
    if count == 0:
        return render.Text("Below\nhorizon", color="#FFFFFF", font="CG-pixel-4x5-mono")
    
    center_alt = altitude_deg(selected_constellation["raHours"], selected_constellation["decDeg"], lat_deg, lst_deg)
    center_az = azimuth_deg(selected_constellation["raHours"], selected_constellation["decDeg"], lat_deg, lst_deg)
    
    # YOUR REQUESTED DIMENSIONS
    star_cols = screen_width - 1      # 63px for stars (col 0 = height indicator)
    star_rows = screen_height - 5     # 27px for stars (5px bottom text space)
    
    # **SIMPLE AUTO-ZOOM: Fill 90% of available space**
    visible_stars_raw_pos = []
    for i, (star_alt, star_az, star) in enumerate(visible_stars_raw):
        # X: azimuth relative to center (-180° to +180° → 0.0 to 1.0)
        rel_az = ((star_az - center_az + 180) % 360) - 180
        x_raw = (rel_az + 180) / 360.0
        
        # Y: altitude + Dec spread (prevents bunching)
        base_y = (90.0 - star_alt) / 90.0           # 0=zenith, 1=horizon
        dec_spread = (star["decDeg"] - 10.0) / 40.0 # Hercules 10-36° Dec
        y_raw = base_y - dec_spread * 0.3           # Spread vertically
        
        visible_stars_raw_pos.append((x_raw, y_raw, i, star))
    
    # Find bounds and map to YOUR screen dimensions
    min_x, max_x = 1.0, 0.0
    min_y, max_y = 1.0, 0.0
    for x_raw, y_raw, i, star in visible_stars_raw_pos:
        min_x = min(min_x, x_raw)
        max_x = max(max_x, x_raw)
        min_y = min(min_y, y_raw)
        max_y = max(max_y, y_raw)
    
    span_x = max(0.1, max_x - min_x)
    span_y = max(0.1, max_y - min_y)
    
    visible_stars = []
    for x_raw, y_raw, i, star in visible_stars_raw_pos:
        screen_x = int(1 + (x_raw - min_x) / span_x * star_cols * 0.9)
        screen_y = int(1 + (y_raw - min_y) / span_y * star_rows * 0.9)
        screen_x = max(1, min(star_cols, screen_x))
        screen_y = max(1, min(star_rows-1, screen_y))
        visible_stars.append((screen_x, screen_y, i))
    
    dir_letter = get_cardinal_direction(center_az)
    
    # Build starfield using YOUR dimensions
    starfield_rows = []
    for row in range(star_rows):
        row_pixels = []
        
        # Height indicator (column 0)
        dot_row = int((90.0 - center_alt) / 90.0 * star_rows)
        if row == dot_row:
            alt_color = "#00FF88" if center_alt > 60 else "#FFAA00" if center_alt > 30 else "#FF4400"
            row_pixels.append(render.Box(width=1, height=1, color=alt_color))
        else:
            row_pixels.append(render.Box(width=1, height=1, color="#000011"))
        
        # Stars (columns 1-63)
        for col in range(1, screen_width):
            color = "#000011"
            for star_x, star_y, star_idx in visible_stars:
                if col == star_x and row == star_y:
                    level = min(star_idx, 4)
                    color = brightness_colors[level]
                    break
            row_pixels.append(render.Box(width=1, height=1, color=color))
        
        starfield_rows.append(render.Row(children=row_pixels))
    
    # Fill bottom 5 rows with black
    for i in range(5):
        filler = render.Row([render.Box(width=screen_width, height=1, color="#000011")])
        starfield_rows.append(filler)
    
    starfield = render.Column(children=starfield_rows)
    
    # Direction overlay
    screen_center_x = int(star_cols / 2 + 1)
    dir_y = screen_height - 5
    direction_pos = add_padding_to_child_element(
        render.Text(dir_letter, color="#00FF44", font="CG-pixel-4x5-mono"),
        left=screen_center_x, top=dir_y
    )
    
    return render.Root(render.Stack(children=[starfield, direction_pos]))
def main(config):
    now = time.now()

    location = json.decode(config.get("location", default_location))
    lat = float(location["lat"])
    lon = float(location["lng"])

    visible = visible_constellations(now, lat, lon)

    print("Visible constellations (top 5):")
    #for i, c in enumerate(visible[:5]):
    for i, c in enumerate(visible):
        print("%s: %s (alt: %s°, dir: %s)" % (i+1, c["name"], c["altitude"], c["direction"]))

    if len(visible) == 0:
        return render.Text("Clear skies!\nNo bright\npatterns visible", color="#88AAFF")
    
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

