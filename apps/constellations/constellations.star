"""
Applet: Constellations
Summary: Displays visible constellations
Description: Displays constellations above your horizon, or previews sunset during daytime.
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

DEFAULT_LOCATION = """
{
    "lat": "28.53933",
    "lng": "-81.38325",
    "description": "Orlando, FL, USA",
    "locality": "Orlando",
    "place_id": "",
    "timezone": "America/New_York"
}
"""

BRIGHTNESS_COLORS = [
    "#FFFFFF",
    "#E4E4E4",
    "#BDBDBD",
    "#909090",
    "#666666",
]

TWINKLE_COLORS = [
    "#E0F2FF",
    "#F0F4FF",
    "#D4DCEE",
    "#A8B2C4",
    "#808A9C",
]

DIRECTIONS = [
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

FONT = "CG-pixel-4x5-mono"

# Text and other widgets advance every 50 ms.
FRAME_DELAY = 50

# Each twinkle phase lasts four rendered frames: 200 ms.
# Eight phases produce a complete 1.6-second cycle.
TWINKLE_PHASE_COUNT = 8
TWINKLE_FRAMES_PER_PHASE = 4
FRAME_COUNT = TWINKLE_PHASE_COUNT * TWINKLE_FRAMES_PER_PHASE

def clamp(value, low, high):
    return max(low, min(high, value))

def deg_to_rad(deg):
    return deg * math.pi / 180.0

def rad_to_deg(rad):
    return rad * 180.0 / math.pi

def message_screen(message):
    return render.Root(
        child = render.Box(
            child = render.Marquee(
                width = canvas.width(),
                child = render.Text(
                    message,
                    color = "#66AAFF",
                    font = FONT,
                ),
            ),
        ),
    )

def display_instructions():
    lines = [
        ("Constellations", "#65D0E6"),
        (
            "Shows constellations above your horizon. During daytime, previews their positions at sunset.",
            "#F4A306",
        ),
        (
            "Green dot shows the constellation's approximate height: bottom is the horizon, middle is halfway up, top is overhead.",
            "#F4A306",
        ),
        (
            "Green letters show which direction to face. UP means nearly overhead. Blue text names the constellation.",
            "#F4A306",
        ),
    ]

    children = []
    offset = 0

    for text, color in lines:
        children.append(
            render.Marquee(
                width = canvas.width(),
                offset_start = offset,
                child = render.Text(
                    text,
                    color = color,
                    font = "5x8",
                ),
            ),
        )
        offset += len(text) * 5

    delay = 45
    if canvas.is2x():
        delay = delay // 2

    return render.Root(
        child = render.Column(children = children),
        delay = delay,
        show_full_animation = True,
    )

def julian_date(t):
    # Calendar fields must represent UTC, not local wall-clock time.
    t = t.in_location("UTC")

    year = t.year
    month = t.month

    day = (
        t.day +
        t.hour / 24.0 +
        t.minute / 1440.0 +
        t.second / 86400.0
    )

    if month <= 2:
        year -= 1
        month += 12

    century = math.floor(year / 100)
    correction = 2 - century + math.floor(century / 4)

    return (
        math.floor(365.25 * (year + 4716)) +
        math.floor(30.6001 * (month + 1)) +
        day +
        correction -
        1524.5
    )

def local_sidereal_time(t, longitude_deg):
    jd = julian_date(t)
    centuries = (jd - 2451545.0) / 36525.0

    gmst = (
        280.46061837 +
        360.98564736629 * (jd - 2451545.0) +
        0.000387933 * centuries * centuries -
        centuries * centuries * centuries / 38710000.0
    )

    return (gmst + longitude_deg) % 360.0

def horizontal_position(ra_hours, dec_deg, lat_rad, lst_deg):
    hour_angle = deg_to_rad(
        (lst_deg - float(ra_hours) * 15.0 + 180.0) % 360.0 - 180.0,
    )
    dec = deg_to_rad(float(dec_deg))

    sin_dec = math.sin(dec)
    cos_dec = math.cos(dec)
    sin_lat = math.sin(lat_rad)
    cos_lat = math.cos(lat_rad)
    cos_ha = math.cos(hour_angle)

    # Unit vector in the observer's east/north/up coordinate system.
    east = -cos_dec * math.sin(hour_angle)
    north = sin_dec * cos_lat - cos_dec * sin_lat * cos_ha
    up = sin_dec * sin_lat + cos_dec * cos_lat * cos_ha

    altitude = rad_to_deg(math.asin(clamp(up, -1.0, 1.0)))
    azimuth = (rad_to_deg(math.atan2(east, north)) + 360.0) % 360.0

    return {
        "altitude": altitude,
        "azimuth": azimuth,
        "east": east,
        "north": north,
        "up": up,
    }

def get_cardinal_direction(azimuth):
    return DIRECTIONS[int((azimuth + 11.25) / 22.5) % 16]

def brightness_index(star, original_index):
    # An explicit index takes priority.
    explicit = star.get("brightness_index")
    if explicit == None:
        explicit = star.get("brightnessIndex")

    if explicit != None:
        return int(clamp(int(explicit), 0, 4))

    magnitude = star.get("magnitude")
    if magnitude == None:
        magnitude = star.get("mag")
    if magnitude == None:
        magnitude = star.get("vmag")
    if magnitude == None:
        magnitude = star.get("Vmag")

    if magnitude != None:
        magnitude = float(magnitude)

        if magnitude < 1.0:
            return 0
        if magnitude < 2.0:
            return 1
        if magnitude < 3.0:
            return 2
        if magnitude < 4.0:
            return 3
        return 4

    # Stable display ranking, not measured brightness.
    return min(original_index, 4)

def normalize_constellations():
    if type(CONSTELLATIONS) == "dict":
        return CONSTELLATIONS.values()
    return CONSTELLATIONS

def evaluate_constellation(constellation, lat_rad, lst_deg):
    stars = constellation.get("stars", [])
    visible_stars = []

    for original_index, star in enumerate(stars):
        position = horizontal_position(
            star["raHours"],
            star["decDeg"],
            lat_rad,
            lst_deg,
        )

        if position["altitude"] > 0.0:
            visible_stars.append({
                "east": position["east"],
                "north": position["north"],
                "up": position["up"],
                "color_index": brightness_index(star, original_index),
                "source_index": original_index,
            })

    reference = horizontal_position(
        constellation["raHours"],
        constellation["decDeg"],
        lat_rad,
        lst_deg,
    )

    return {
        "name": constellation["name"],
        "reference": reference,
        "stars": visible_stars,
        "total_stars": len(stars),
    }

def eligible_constellations(evaluated, threshold):
    eligible = []

    for constellation in evaluated:
        total = constellation["total_stars"]
        count = len(constellation["stars"])

        # Require a recognizable amount of the supplied star pattern.
        required = min(3, total)

        if (
            total > 0 and
            count >= required and
            count * 2 >= total and
            constellation["reference"]["altitude"] > threshold
        ):
            eligible.append(constellation)

    return eligible

def project_stars(stars, width, height):
    # Center the projection on the mean visible-star direction.
    east_sum = 0.0
    north_sum = 0.0
    up_sum = 0.0

    for star in stars:
        east_sum += star["east"]
        north_sum += star["north"]
        up_sum += star["up"]

    horizontal_length = math.sqrt(
        east_sum * east_sum + north_sum * north_sum,
    )

    if horizontal_length < 0.000001:
        center_az = 0.0
    else:
        center_az = math.atan2(east_sum, north_sum)

    center_alt = math.atan2(up_sum, horizontal_length)

    sin_az = math.sin(center_az)
    cos_az = math.cos(center_az)
    sin_alt = math.sin(center_alt)
    cos_alt = math.cos(center_alt)

    # Screen-right follows increasing azimuth.
    # Screen-up follows increasing altitude at the projection center.
    projected = []

    for star in stars:
        x = star["east"] * cos_az - star["north"] * sin_az
        y = (
            -star["east"] * sin_alt * sin_az -
            star["north"] * sin_alt * cos_az +
            star["up"] * cos_alt
        )

        projected.append({
            "x": x,
            "y": y,
            "color_index": star["color_index"],
            "source_index": star["source_index"],
        })

    min_x = projected[0]["x"]
    max_x = min_x
    min_y = projected[0]["y"]
    max_y = min_y

    for star in projected:
        min_x = min(min_x, star["x"])
        max_x = max(max_x, star["x"])
        min_y = min(min_y, star["y"])
        max_y = max(max_y, star["y"])

    left = 3
    right = width - 2
    top = 1
    bottom = height - 2

    available_width = max(1, right - left)
    available_height = max(1, bottom - top)

    # A common scale preserves projected proportions.
    span_x = max(0.000001, max_x - min_x)
    span_y = max(0.000001, max_y - min_y)

    scale = min(
        available_width / span_x,
        available_height / span_y,
    )

    center_x = (min_x + max_x) / 2.0
    center_y = (min_y + max_y) / 2.0
    screen_center_x = (left + right) / 2.0
    screen_center_y = (top + bottom) / 2.0

    positions = []

    for star in projected:
        x = int(
            screen_center_x + (star["x"] - center_x) * scale + 0.5,
        )
        y = int(
            screen_center_y - (star["y"] - center_y) * scale + 0.5,
        )

        positions.append({
            "x": int(clamp(x, left, right)),
            "y": int(clamp(y, top, bottom)),
            "color_index": star["color_index"],
            "source_index": star["source_index"],
        })

    return positions

def merge_overlapping_stars(positions):
    # Keep one star per pixel, choosing the brighter base brightness.
    # Equal-brightness ties keep the first star for stable animation.
    merged = []
    pixel_indices = {}

    for star in positions:
        key = (star["x"], star["y"])
        existing_index = pixel_indices.get(key)

        if existing_index == None:
            pixel_indices[key] = len(merged)
            merged.append(star)
        elif star["color_index"] < merged[existing_index]["color_index"]:
            merged[existing_index] = star

    return merged

def twinkle_color(color_index, source_index, frame_index):
    # Hold each phase for several frames without slowing the marquee.
    phase = (
        frame_index // TWINKLE_FRAMES_PER_PHASE +
        source_index * 3
    ) % TWINKLE_PHASE_COUNT

    brighter = max(0, color_index - 1)
    dimmer = min(len(BRIGHTNESS_COLORS) - 1, color_index + 1)

    # Gradual cycle: peak, tinted shoulder, base, dim, base, shoulder.
    # Adjacent stars use staggered phases and never disappear.
    if phase == 0:
        return BRIGHTNESS_COLORS[brighter]

    if phase == 1 or phase == 7:
        return TWINKLE_COLORS[color_index]

    if phase == 3 or phase == 4:
        return BRIGHTNESS_COLORS[dimmer]

    return BRIGHTNESS_COLORS[color_index]

def render_constellation_screen(
        constellation,
        show_altitude_indicator,
        sunset_preview):
    width = canvas.width()
    height = canvas.height()
    star_area_height = height - 8

    stars = constellation["stars"]
    if not stars:
        return message_screen("Below horizon")

    positions = merge_overlapping_stars(
        project_stars(stars, width, star_area_height),
    )

    frames = []

    for frame_index in range(FRAME_COUNT):
        layers = [
            render.Box(
                width = width,
                height = height,
                color = "#000000",
            ),
        ]

        for star in positions:
            layers.append(
                render.Padding(
                    pad = (star["x"], star["y"], 0, 0),
                    child = render.Box(
                        width = 1,
                        height = 1,
                        color = twinkle_color(
                            star["color_index"],
                            star["source_index"],
                            frame_index,
                        ),
                    ),
                ),
            )

        frames.append(render.Stack(children = layers))

    reference = constellation["reference"]

    layers = [
        render.Animation(children = frames),
    ]

    if show_altitude_indicator:
        altitude = clamp(reference["altitude"], 0.0, 90.0)
        dot_y = int(
            (1.0 - altitude / 90.0) * (star_area_height - 1) + 0.5,
        )

        layers.append(
            render.Padding(
                pad = (0, dot_y, 0, 0),
                child = render.Box(
                    width = 1,
                    height = 1,
                    color = "#00FF88",
                ),
            ),
        )

    direction = (
        "UP" if reference["altitude"] >= 88.0 else get_cardinal_direction(reference["azimuth"])
    )

    label = constellation["name"]
    if sunset_preview:
        label += " @ sunset"

    # Separate positioned boxes prevent long direction labels
    # from pushing the name past the right edge.
    direction_width = len(direction) * 4
    name_left = 1 + direction_width + 3
    name_width = max(1, width - name_left)

    layers.append(
        render.Padding(
            pad = (1, height - 7, 0, 0),
            child = render.Text(
                direction,
                color = "#00FF44",
                font = FONT,
            ),
        ),
    )

    layers.append(
        render.Padding(
            pad = (name_left, height - 7, 0, 0),
            child = render.Box(
                width = name_width,
                height = 7,
                child = render.Marquee(
                    width = name_width,
                    child = render.Text(
                        label,
                        color = "#66AAFF",
                        font = FONT,
                    ),
                ),
            ),
        ),
    )

    return render.Root(
        delay = FRAME_DELAY,
        child = render.Stack(children = layers),
    )

def main(config):
    if config.bool("instructions", False):
        return display_instructions()

    show_altitude_indicator = config.bool("alt_indicator", True)

    location_raw = config.get("location") or DEFAULT_LOCATION
    location = json.decode(location_raw)

    lat = float(location["lat"])
    lon = float(location["lng"])
    timezone = location.get("timezone") or "UTC"

    if lat < -90.0 or lat > 90.0 or lon < -180.0 or lon > 180.0:
        return message_screen("Invalid location")

    now = time.now()
    local_now = now.in_location(timezone)

    effective_time = now
    sunset_preview = False

    # elevation_time returns None when this crossing never occurs.
    # -0.833 degrees approximates the conventional sunrise/sunset level.
    crossings = sunrise.elevation_time(
        lat,
        lon,
        -0.833,
        local_now,
    )

    if crossings != None:
        sunset_time = crossings[1]

        if (
            sunset_time != None and
            now < sunset_time and
            sunrise.elevation(lat, lon, now) > -0.833
        ):
            effective_time = sunset_time
            sunset_preview = True

    constellations = normalize_constellations()
    if not constellations:
        return message_screen("No constellation data")

    lat_rad = deg_to_rad(lat)
    lst_deg = local_sidereal_time(effective_time, lon)

    evaluated = []

    for constellation in constellations:
        evaluated.append(
            evaluate_constellation(
                constellation,
                lat_rad,
                lst_deg,
            ),
        )

    candidates = eligible_constellations(evaluated, 30.0)

    if not candidates:
        candidates = eligible_constellations(evaluated, 15.0)

    if not candidates:
        return message_screen("No constellations above limit")

    # Full UTC minute gives stable selection within a minute,
    # without repeating the same 60 seeds every hour.
    utc_now = now.in_location("UTC")
    minute_seed = (
        (
            (
                (
                    utc_now.year * 13 + utc_now.month
                ) * 32 + utc_now.day
            ) * 24 + utc_now.hour
        ) * 60 + utc_now.minute
    )

    random.seed(minute_seed)

    # A fixed broad range also handles a single candidate safely.
    selected_index = random.number(0, 1000000000) % len(candidates)
    selected = candidates[selected_index]

    return render_constellation_screen(
        selected,
        show_altitude_indicator,
        sunset_preview,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Your observing location.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "alt_indicator",
                name = "Display Altitude Indicator",
                desc = "Show the constellation's approximate height: bottom is horizon, top is overhead.",
                icon = "angleLeft",
                default = True,
            ),
            schema.Toggle(
                id = "instructions",
                name = "Display Instructions",
                desc = "Show help instead of constellations.",
                icon = "book",
                default = False,
            ),
        ],
    )
