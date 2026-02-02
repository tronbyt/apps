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
load("sunrise.star", "sunrise")
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

# Maintainable color indexing
brightness_colors = [
    "#FFFFFF",  # 0: Sirius
    "#FFF4D6",  # 1: Altair
    "#C0C0C0",  # 2: Medium
    "#808080",  # 3: Faint
    "#555555",  # 4: Faintest
]

twinkle_colors = [
    "#E0F2FF",  # 0: Cool blue shift
    "#FFE082",  # 1: Warm gold shift
    "#FFFFFF",  # 2: Flash to white
    "#BDBDBD",  # 3: Brighten
    "#888888",  # 4: Brighten
]

def display_instructions(config):
    instructions_1 = "Displays constellations you can currently unless it is daytime, it'll show you what you can see at sundown."
    instructions_2 = "Dot on the far left in green indicates how high in the sky you need to look. "
    instructions_3 = "Green text indicates direction you must look. Constellation name displayed in blue."
    app_title = "Constellations"

    delay = int(config.get("scroll", 45))
    if canvas.is2x():
        delay = int(delay / 2)

    return render.Root(
        render.Column(
            children = [
                render.Marquee(width = canvas.width(), child = render.Text(app_title, color = "#65d0e6", font = "5x8")),
                render.Marquee(width = canvas.width(), offset_start = len(app_title) * 5, child = render.Text(instructions_1, color = "#f4a306", font = "5x8")),
                render.Marquee(offset_start = len(instructions_1) * 5, width = canvas.width(), child = render.Text(instructions_2, color = "#f4a306", font = "5x8")),
                render.Marquee(offset_start = (len(instructions_2) + len(instructions_1)) * 5, width = canvas.width(), child = render.Text(instructions_3, color = "#f4a306", font = "5x8")),
            ],
        ),
        delay = delay,
        show_full_animation = True,
    )

def deg_to_rad(deg): return deg * math.pi / 180.0
def rad_to_deg(rad): return rad * 180.0 / math.pi

def get_constellation_bounds(stars_raw):
    if not stars_raw: return 0, 0, 0, 0
    anchor_az = stars_raw[0][1]
    min_x, max_x, min_y, max_y = 1000.0, -1000.0, 1000.0, -1000.0
    for alt, az, _ in stars_raw:
        diff = (az - anchor_az + 180) % 360 - 180
        adj = anchor_az + diff
        if adj < min_x: min_x = adj
        if adj > max_x: max_x = adj
        if alt < min_y: min_y = alt
        if alt > max_y: max_y = alt
    return min_x, max_x, min_y, max_y

def julian_date(t):
    y, m = t.year, t.month
    day = t.day + t.hour / 24.0 + t.minute / 1440.0 + t.second / 86400.0
    if m <= 2: y -= 1; m += 12
    A = math.floor(y / 100)
    B = 2 - A + math.floor(A / 4)
    return math.floor(365.25 * (y + 4716)) + math.floor(30.6001 * (m + 1)) + day + B - 1524.5

def local_sidereal_time(t, longitude_deg):
    JD = julian_date(t)
    T = (JD - 2451545.0) / 36525.0
    GMST = 280.46061837 + 360.98564736629 * (JD - 2451545.0) + 0.000387933 * T * T - T * T * T / 38710000.0
    return ((GMST + longitude_deg) % 360 + 360) % 360

def azimuth_deg(ra_hours, dec_deg, lat_deg, lst_deg):
    ra_deg = ra_hours * 15.0
    ha_deg = (lst_deg - ra_deg + 360) % 360
    if ha_deg > 180: ha_deg -= 360
    ha_rad, dec_rad, lat_rad = deg_to_rad(ha_deg), deg_to_rad(dec_deg), deg_to_rad(lat_deg)
    sin_alt = math.sin(dec_rad) * math.sin(lat_rad) + math.cos(dec_rad) * math.cos(lat_rad) * math.cos(ha_rad)
    sin_alt = max(-1.0, min(1.0, sin_alt))
    alt_rad = math.asin(sin_alt)
    cos_az_num = math.sin(dec_rad) - math.sin(lat_rad) * sin_alt
    cos_az_den = math.cos(lat_rad) * math.cos(alt_rad)
    cos_az = cos_az_num / cos_az_den if cos_az_den != 0 else 0
    sin_az = math.sin(ha_rad) * math.cos(dec_rad) / math.cos(alt_rad) if math.cos(alt_rad) != 0 else 0
    return (rad_to_deg(math.atan2(sin_az, cos_az)) + 360) % 360

def altitude_deg(ra_hours, dec_deg, lat_deg, lst_deg):
    ra_deg = ra_hours * 15.0
    ha_deg = (lst_deg - ra_deg + 360) % 360
    if ha_deg > 180: ha_deg -= 360
    ha_rad, dec_rad, lat_rad = deg_to_rad(ha_deg), deg_to_rad(dec_deg), deg_to_rad(lat_deg)
    sin_alt = math.sin(dec_rad) * math.sin(lat_rad) + math.cos(dec_rad) * math.cos(lat_rad) * math.cos(ha_rad)
    return rad_to_deg(math.asin(max(-1.0, min(1.0, sin_alt))))

def get_cardinal_direction(az_deg):
    directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
    return directions[int((az_deg + 11.25) / 22.5 + 0.0001) % 16]

def visible_constellations(t, lat_deg, lon_deg, threshold_deg = 10.0):
    lst_deg = local_sidereal_time(t, lon_deg)
    visible = []
    for c in CONSTELLATIONS:
        alt = altitude_deg(c["raHours"], c["decDeg"], lat_deg, lst_deg)
        if alt > threshold_deg:
            az = azimuth_deg(c["raHours"], c["decDeg"], lat_deg, lst_deg)
            visible.append({
                "id": c["id"], "name": c["name"], "altitude": math.floor(alt * 10) / 10.0,
                "azimuth": math.floor(az), "direction": get_cardinal_direction(az),
                "raHours": c["raHours"], "decDeg": c["decDeg"],
            })
    return sorted(visible, key = lambda x: -x["altitude"])

def render_constellation_screen(selected_constellation, t, lat_deg, lon_deg, show_altitude_indicator):
    lst_deg = local_sidereal_time(t, lon_deg)
    W, H = canvas.width(), canvas.height()
    star_area_h = H - 8

    visible_stars_raw = []
    for star in selected_constellation["stars"]:
        alt = altitude_deg(star["raHours"], star["decDeg"], lat_deg, lst_deg)
        if alt > 0.0:
            az = azimuth_deg(star["raHours"], star["decDeg"], lat_deg, lst_deg)
            visible_stars_raw.append((alt, az, star))

    if not visible_stars_raw:
        return render.Root(child = render.Box(child = render.Text("Below Horizon")))

    official_alt = altitude_deg(selected_constellation["raHours"], selected_constellation["decDeg"], lat_deg, lst_deg)
    official_az = azimuth_deg(selected_constellation["raHours"], selected_constellation["decDeg"], lat_deg, lst_deg)
    dir_letter = get_cardinal_direction(official_az)

    min_az, max_az, min_alt, max_alt = get_constellation_bounds(visible_stars_raw)
    span_az, span_alt = max(5.0, max_az - min_az), max(5.0, max_alt - min_alt)
    anchor_az = visible_stars_raw[0][1]

    # Pre-calculate positions and color indices
    star_positions = []
    for i, (alt, az, _) in enumerate(visible_stars_raw):
        diff = (az - anchor_az + 180) % 360 - 180
        adj_az = anchor_az + diff
        rel_x = int(3 + ((adj_az - min_az) / span_az) * (W - 10))
        rel_y = int(1 + (1.0 - (alt - min_alt) / span_alt) * (star_area_h - 2))
        star_positions.append((rel_x, rel_y, min(i, 4)))

    # Frame generation with index-based twinkle lookup
    animation_frames = []
    for frame_idx in range(8):
        frame_layers = [render.Box(width = W, height = H, color = "#000000")]
        for i, (x, y, color_idx) in enumerate(star_positions):
            # Select color based on index, not string matching
            if (i * 7 + frame_idx * 3) % 10 == 1:
                display_color = twinkle_colors[color_idx]
            else:
                display_color = brightness_colors[color_idx]

            frame_layers.append(render.Padding(
                pad = (x, y, 0, 0),
                child = render.Box(width = 1, height = 1, color = display_color),
            ))
        animation_frames.append(render.Stack(children = frame_layers))

    altitude_dot = render.Box()
    if show_altitude_indicator:
        dot_y = int((1.0 - (official_alt / 90.0)) * (star_area_h - 1))
        altitude_dot = render.Padding(pad = (0, dot_y, 0, 0), child = render.Box(width = 1, height = 1, color = "#00FF88"))

    ui_bar = render.Padding(
        pad = (0, H - 7, 0, 0),
        child = render.Row(
            expanded = True, main_align = "start", cross_align = "center",
            children = [
                render.Padding(pad = (1, 0, 3, 0), child = render.Text(dir_letter, color = "#00FF44", font = "CG-pixel-4x5-mono")),
                render.Box(width = W - 18, height = 7, child = render.Marquee(width = W - 18, child = render.Text(selected_constellation["name"], color = "#66AAFF", font = "CG-pixel-4x5-mono"))),
            ],
        ),
    )

    return render.Root(
        delay = 150,
        child = render.Stack(children = [render.Animation(children = animation_frames), altitude_dot, ui_bar]),
    )

def main(config):
    show_instructions = config.bool("instructions", False)
    show_altitude_indicator = config.bool("alt_indicator", True)
    if show_instructions: return display_instructions(config)

    now = time.now()
    location = json.decode(config.get("location", default_location))
    lat, lon, tz = float(location["lat"]), float(location["lng"]), location["timezone"]

    s_rise, s_set = sunrise.sunrise(lat, lon, now).in_location(tz), sunrise.sunset(lat, lon, now).in_location(tz)
    effective_time = s_set if now > s_rise and now < s_set else now

    constellation_dict = {c["id"]: c for c in CONSTELLATIONS} if type(CONSTELLATIONS) == "list" else CONSTELLATIONS
    candidates = visible_constellations(effective_time, lat, lon, threshold_deg = 30.0)
    if not candidates: candidates = visible_constellations(effective_time, lat, lon, threshold_deg = 15.0)
    if not candidates: return render.Root(child = render.Box(child = render.Text("Cloudy Skies", font = "CG-pixel-4x5-mono")))

    random.seed(now.minute)
    featured = constellation_dict.get(candidates[random.number(0, len(candidates) - 1)]["id"]) or constellation_dict.values()[0]

    return render_constellation_screen(featured, effective_time, lat, lon, show_altitude_indicator)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(id = "location", name = "Location", desc = "Your location.", icon = "locationDot"),
            schema.Toggle(id = "alt_indicator", name = "Display Altitude Indicator", desc = "Show height dot", icon = "angleLeft", default = True),
            schema.Toggle(id = "instructions", name = "Display Instructions", desc = "Show help", icon = "book", default = False),
        ],
    )