"""
Applet: Constellations
Summary: Displays visible constellations
Description: Displays visible constellations in your sky.
Author: Robert Ison
"""

load("constellations_data.star", "CONSTELLATIONS")
load("encoding/json.star", "json")
load("math.star", "math")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("sunrise.star", "sunrise")  #to calcuate day/night and when planets will be visible
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

def display_instructions(config):
    ##############################################################################################################################################################################################################################
    instructions_1 = "Displays constellations you can currently unless it is daytime, it'll show you what you can see at sundown."
    instructions_2 = "Dot on the far left in green indicates how high in the sky you need to look. "
    instructions_3 = "Green text indicates direction you must look. Constellation name displayed in blue."
    app_title = "Constellations"

    return render.Root(
        render.Column(
            children = [
                render.Marquee(
                    width = canvas.width(),
                    child = render.Text(app_title, color = "#65d0e6", font = "5x8"),
                ),
                render.Marquee(
                    width = canvas.width(),
                    offset_start = len(app_title) * 5,
                    child = render.Text(instructions_1, color = "#f4a306", font = "5x8"),
                ),
                render.Marquee(
                    offset_start = len(instructions_1) * 5,
                    width = canvas.width(),
                    child = render.Text(instructions_2, color = "#f4a306", font = "5x8"),
                ),
                render.Marquee(
                    offset_start = (len(instructions_2) + len(instructions_1)) * 5,
                    width = canvas.width(),
                    child = render.Text(instructions_3, color = "#f4a306", font = "5x8"),
                ),
            ],
        ),
        delay = int(config.get("scroll", 45)),
        show_full_animation = True,
    )

def deg_to_rad(deg):
    return deg * math.pi / 180.0

def rad_to_deg(rad):
    return rad * 180.0 / math.pi

def get_constellation_bounds(stars_raw):
    if not stars_raw:
        return 0, 0, 0, 0

    # FIX: Use the first star as an anchor to handle the 0/360 degree wrap
    anchor_az = stars_raw[0][1]

    min_x, max_x = 1000.0, -1000.0
    min_y, max_y = 1000.0, -1000.0

    for alt, az, _ in stars_raw:
        # Calculate relative distance from anchor (-180 to +180)
        diff = (az - anchor_az + 180) % 360 - 180
        adjusted_az = anchor_az + diff

        if adjusted_az < min_x:
            min_x = adjusted_az
        if adjusted_az > max_x:
            max_x = adjusted_az
        if alt < min_y:
            min_y = alt
        if alt > max_y:
            max_y = alt

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

def render_constellation_screen(selected_constellation, t, lat_deg, lon_deg, show_altitude_indicator):
    # ... (Sidereal time and visibility check remains the same) ...
    lst_deg = local_sidereal_time(t, lon_deg)
    constellation_stars = selected_constellation["stars"]
    W, H = canvas.width(), canvas.height()
    star_area_h = H - 8  # Increased slightly for better text clearance

    visible_stars_raw = []
    for star in constellation_stars:
        alt = altitude_deg(star["raHours"], star["decDeg"], lat_deg, lst_deg)
        az = azimuth_deg(star["raHours"], star["decDeg"], lat_deg, lst_deg)
        if alt > 0.0:
            visible_stars_raw.append((alt, az, star))

    if not visible_stars_raw:
        return render.Root(child = render.Box(child = render.Text("Below Horizon")))

    official_alt = altitude_deg(selected_constellation["raHours"], selected_constellation["decDeg"], lat_deg, lst_deg)
    official_az = azimuth_deg(selected_constellation["raHours"], selected_constellation["decDeg"], lat_deg, lst_deg)
    dir_letter = get_cardinal_direction(official_az)

    # Use the fixed bounds logic
    min_az, max_az, min_alt, max_alt = get_constellation_bounds(visible_stars_raw)
    span_az, span_alt = max(5.0, max_az - min_az), max(5.0, max_alt - min_alt)
    anchor_az = visible_stars_raw[0][1]

    layers = [render.Box(width = W, height = H, color = "#000000")]

    # Render Stars with wrap-around correction
    for i, (alt, az, star) in enumerate(visible_stars_raw):
        diff = (az - anchor_az + 180) % 360 - 180
        adj_az = anchor_az + diff

        rel_x = int(3 + ((adj_az - min_az) / span_az) * (W - 10))
        rel_y = int(1 + (1.0 - (alt - min_alt) / span_alt) * (star_area_h - 2))

        layers.append(render.Padding(
            pad = (rel_x, rel_y, 0, 0),
            child = render.Box(width = 1, height = 1, color = brightness_colors[min(i, 4)]),
        ))

    # Altitude Dot (Column 0)
    if show_altitude_indicator:
        dot_y = int((1.0 - (official_alt / 90.0)) * (star_area_h - 1))
        layers.append(render.Padding(pad = (0, dot_y, 0, 0), child = render.Box(width = 1, height = 1, color = "#00FF88")))

    # Bottom Overlay with Pixel-Perfect Alignment
    layers.append(render.Padding(
        pad = (0, H - 7, 0, 0),
        child = render.Row(
            expanded = True,
            main_align = "start",
            cross_align = "center",  # FIX: Aligns the vertical centers of both text blocks
            children = [
                render.Padding(
                    pad = (1, 0, 3, 0),
                    child = render.Text(
                        dir_letter,
                        color = "#00FF44",
                        font = "CG-pixel-4x5-mono",
                    ),
                ),
                render.Box(
                    width = W - 18,
                    height = 7,  # Explicit height helps stabilize the row
                    child = render.Marquee(
                        width = W - 18,
                        child = render.Text(
                            selected_constellation["name"],
                            color = "#66AAFF",
                            font = "CG-pixel-4x5-mono",
                        ),
                    ),
                ),
            ],
        ),
    ))

    return render.Root(child = render.Stack(children = layers))

def main(config):
    show_instructions = config.bool("instructions", False)
    show_altitude_indicator = config.bool("alt_indicator", True)

    if show_instructions:
        return display_instructions(config)

    now = time.now()
    location = json.decode(config.get("location", default_location))
    lat = float(location["lat"])
    lon = float(location["lng"])
    tz = location["timezone"]

    # 1. Daytime logic (as we built before)
    s_rise = sunrise.sunrise(lat, lon, now).in_location(tz)
    s_set = sunrise.sunset(lat, lon, now).in_location(tz)

    if now > s_rise and now < s_set:
        effective_time = s_set
        #display_mode = "Tonight"

    else:
        effective_time = now
        #display_mode = "Now"

    # 2. Filter constellations > 30 degrees
    # We use your visible_constellations function but with a 30.0 threshold
    candidates = visible_constellations(effective_time, lat, lon, threshold_deg = 30.0)

    # Fallback: If nothing is > 30, try > 15 to ensure we show SOMETHING
    if len(candidates) == 0:
        candidates = visible_constellations(effective_time, lat, lon, threshold_deg = 15.0)

    if len(candidates) == 0:
        return render.Root(child = render.Box(child = render.Text("Cloudy Skies", font = "CG-pixel-4x5-mono")))

    # 3. Pick one at random
    # We seed it with the current hour so it doesn't flicker every second,
    # but changes once a minute
    random.seed(now.minute)
    choice_index = random.number(0, len(candidates) - 1)
    chosen_summary = candidates[choice_index]

    # 4. Fetch full data (with stars) for the chosen one
    featured = None
    for c in CONSTELLATIONS:
        if c["id"] == chosen_summary["id"]:
            featured = c
            break

    # fallback safety
    if not featured:
        featured = CONSTELLATIONS[0]

    return render_constellation_screen(featured, effective_time, lat, lon, show_altitude_indicator)

def get_schema():
    scroll_speed_options = [
        schema.Option(
            display = "Slow Scroll",
            value = "60",
        ),
        schema.Option(
            display = "Medium Scroll",
            value = "45",
        ),
        schema.Option(
            display = "Fast Scroll",
            value = "30",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Your location to determine if the selected planet is visible.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "alt_indicator",
                name = "Display Altitude Indicator",
                desc = "Show colored dot on left most column to indicate how high to look",
                icon = "angleLeft",  #"info",
                default = True,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
            schema.Toggle(
                id = "instructions",
                name = "Display Instructions",
                desc = "",
                icon = "book",  #"info",
                default = False,
            ),
        ],
    )
