"""
App: Hurricane Map
Summary: Show current hurricanes/cyclones
Desc: Displays current tropical depressions, storms, hurricanes, cyclones, and typhoons across the globe. Data from the NHC and JTWC.
Author: frame-shift
"""

load("encoding/base64.star", "base64")
load("helper.star", "STR_TO_NUM", "map_patterns", "sym_patterns")
load("http.star", "http")
load("math.star", "math")
load("re.star", "re")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

# Default settings
DEFAULT_HIDE = True
DEFAULT_NAMES = True
DEFAULT_MAP = "G0"
DEFAULT_SYM_SIZE = "medium"
DEFAULT_COLORS = {
    "MAP": "#00436A",
    "OCEAN": "#000C13",
    "TD": "#6EC1EA",
    "TS": "#4DFFFF",
    1: "#FFFFD9",
    2: "#FFD98C",
    3: "#FF9E59",
    4: "#FF738A",
    5: "#A188FC",
}

# Rendering assists
BLANK_PX = render.Box(width = 1, height = 1, color = "#00000000")
MAP_BOUNDS = {
    # These are the edges of each map; top/bottom = lat, left/right = lon
    "G0": {"top": 66.5133, "left": -180.0, "bottom": -66.5133, "right": 180.0},
    "G180": {"top": 66.5133, "left": 0.0, "bottom": -66.5133, "right": 360.0},
    "EP": {"top": 60.0, "left": 162.0502, "bottom": 5.0, "right": -57.0502},
    "WP": {"top": 60.0, "left": 69.5502, "bottom": 5.0, "right": -149.5502},
    "SP": {"top": -5.0, "left": 117.0502, "bottom": -60.0, "right": -102.0502},
    "SI": {"top": -5.0, "left": 2.0502, "bottom": -60.0, "right": 142.9498},
    "NI": {"top": 60.0, "left": -5.4498, "bottom": 5.0, "right": 135.4498},
    "NA": {"top": 60.0, "left": -120.4498, "bottom": 5.0, "right": 20.4498},
}

# HTTP assists
URL_NHC = "https://www.nhc.noaa.gov/CurrentStorms.json"
URL_JTWC = "https://www.metoc.navy.mil/jtwc/rss/jtwc.rss"
HEADERS = {"Cache-Control": "no-cache", "User-Agent": "Tronbyt/hurricane_map"}
REFRESH_RATE = 3600  # 1 hour (seconds)

# Text parsing assists
PATTERN_WEBTXT = r"(https?:\/\/[^\s'\"<>]+\d+web\.txt)(.*?)<\/a>"
PATTERN_POS = r"\d{6}Z.+?-+?\sNEAR\s(\d.+?[N|S])\s*?(\d.+?[E|W])"
PATTERN_WIND = r"MAX SUSTAINED WINDS.*?(\d+).*?KT"
PATTERN_NAME = r"SUBJ.+?\d([A-Z])\s\((.+?)\)"
TD_NHC_SUFFIX = ["-E", "-C"]  # All possible NHC suffixes for TDs
NUM_STRS = list(STR_TO_NUM.keys())

def main(config):
    """Render the selected hurricane map with active storm symbols.

    Args:
        config: (config object) App schema containing map, display, and symbol options.

    Returns:
        render.Root: (render.Root | None) The rendered hurricane map display, or None if hidden.
    """
    map_choice = config.str("map_choice", DEFAULT_MAP)
    hide_if_quiet = config.bool("hide_if_quiet", DEFAULT_HIDE)
    show_names = config.bool("show_names", DEFAULT_NAMES)
    sym_size = config.str("sym_size", DEFAULT_SYM_SIZE)
    map_color = config.str("map_color", DEFAULT_COLORS["MAP"])
    ocean_color = config.str("ocean_color", DEFAULT_COLORS["OCEAN"])

    # Build map and storms
    map = build_map(map_choice, map_color)
    storm_data = (get_nhc() or []) + (get_jtwc() or [])
    if hide_if_quiet and not storm_data:  # Hide if no storm data exists
        return None

    storms = [build_storm(s["lat"], s["lon"], s["wind"], s["name"], sym_size, map_choice, config) for s in storm_data]
    storms = [s for s in storms if s]
    if hide_if_quiet and not storms:  # Hide if no storm data in selected basin
        return None

    if show_names:
        name_banner = make_name_banner([(s["name"], s["intensity"], s["display_lon"]) for s in storms])
    else:
        name_banner = BLANK_PX
    delay = 25 if canvas.is2x() else 50

    return render.Root(
        show_full_animation = True,
        delay = delay,
        child = render.Stack(
            # First child is bottom layer; last is top
            children = [
                render.Box(color = ocean_color),
                map,
                render.Stack(children = [s["symbol"] for s in storms]),
                name_banner,
            ],
        ),
    )

def map_pattern_to_svg(map_choice, color):
    """Build a 128x64 SVG map from the selected basin pattern.

    Args:
        map_choice: (str) Basin code used to select the map pattern.
        color: (str) Color value used for land pixels.

    Returns:
        bytes: (bytes) Base64-decoded SVG image data ready for render.Image.
    """
    if map_choice == "EP":
        map = map_patterns.ep
    elif map_choice == "NA":
        map = map_patterns.na
    elif map_choice == "NI":
        map = map_patterns.ni
    elif map_choice == "SI":
        map = map_patterns.si
    elif map_choice == "SP":
        map = map_patterns.sp
    elif map_choice == "WP":
        map = map_patterns.wp
    elif map_choice == "G180":
        map = map_patterns.g180
    else:
        map = map_patterns.g0

    # Dynamically construct SVG of map using selected map_pattern and color
    max_width, max_height = (128, 64)  # Max dimensions of map
    svg = "<svg xmlns='http://www.w3.org/2000/svg' width='%s' height='%s'>" % (max_width, max_height)
    for y in range(max_height):
        for x in range(max_width):
            if x < len(map[y]) and map[y][x] == "1":
                svg += "<rect x='%d' y='%d' width='1' height='1' fill='%s' />" % (x, y, color)
    svg += "</svg>"

    return base64.decode(base64.encode(svg))

def build_map(map_choice, color):
    """Build the selected basin map image.

    Args:
        map_choice: (str) Basin code used to select the map pattern.
        color: (str) Hexadecimal color for land pixels.

    Returns:
        render.Image: (render.Image) The map rendered at the current display scale.
    """
    scale = 2 if canvas.is2x() else 1

    return render.Image(
        src = map_pattern_to_svg(map_choice, color),
        width = 64 * scale,
        height = 32 * scale,
    )

def calc_intensity(wind):
    """Map wind speed to a Saffir-Simpson intensity label.

    Args:
        wind: (int) Wind speed in knots.

    Returns:
        intensity: (str | int) "TD", "TS", or a Saffir-Simpson category from 1 to 5.
    """
    if wind <= 33:  # Tropical Depression
        return "TD"
    elif wind >= 34 and wind <= 63:  # Tropical Storm
        return "TS"
    elif wind >= 64 and wind <= 82:  # Cat 1
        return 1
    elif wind >= 83 and wind <= 95:  # Cat 2
        return 2
    elif wind >= 96 and wind <= 112:  # Cat 3
        return 3
    elif wind >= 113 and wind <= 136:  # Cat 4
        return 4
    else:  # Cat 5
        return 5

def make_name_banner(storms):
    """Build a storm name banner sorted by horizontal display position.

    Args:
        storms: (list[tuple]) List of (name, intensity, location) tuples.

    Returns:
        render.Padding: (render.Padding) A marquee of storm names with intensity labels.
    """
    storm_names = []
    for s in storms:
        name, intensity, loc = s
        if type(intensity) == "int":
            intensity = "H" + str(intensity)
        storm_names.append((intensity + " " + name, loc))

    # Sort names from left to right on the display
    if len(storm_names) == 1:
        names = storm_names[0][0]
    else:
        sorted_names = sorted(storm_names, key = lambda x: x[1])
        names = [n[0] for n in sorted_names]
        names = "   ".join(names)

    # Set render attributes based on scale
    scale = 2 if canvas.is2x() else 1
    if scale == 2:
        box_height = 12
        font = "terminus-14"
        pad_top = -2
    else:
        box_height = 5
        font = "CG-pixel-4x5-mono"  # Use CG-pixel-4x5-mono, CG-pixel-3x5-mono, or tom-thumb
        pad_top = 0

    return render.Padding(
        pad = (0, pad_top, 0, 0),
        child = render.Stack(
            children = [
                render.Box(height = box_height, color = "#000000A0"),
                render.Marquee(
                    width = 64 * scale,
                    align = "center",
                    offset_start = int(64 * scale * 0.75),
                    child = render.Text(
                        content = names.upper(),
                        font = font,
                        color = "#FFFFFFAA",
                    ),
                ),
            ],
        ),
    )

def build_symbol(wind, sym_size, config):
    """Build a storm symbol for a given wind speed.

    Args:
        wind: (int) Wind speed in knots.
        sym_size: (str) Symbol size as "small", "medium", or "large".
        config: (config object) Configuration used to resolve color definitions.

    Returns:
        render.Stack: (render.Stack) Rendered storm symbol.
    """
    ss = calc_intensity(wind)

    # Set symbol pattern
    if sym_size == "small":
        patterns = sym_patterns.small
    elif sym_size == "medium":
        patterns = sym_patterns.medium
    else:
        patterns = sym_patterns.large
    pattern = patterns["HU"] if type(ss) == "int" else patterns[ss]
    pattern_size = len(pattern[0])

    # Set symbol color
    if type(ss) == "int":
        color_key = "cat" + str(ss) + "_color"
    else:
        color_key = ss.lower() + "_color"
    color = config.str(color_key, DEFAULT_COLORS[ss])

    # Build symbol
    filled_px = render.Box(width = 1, height = 1, color = color)
    built_sym = []
    for row in range(pattern_size):
        for col in range(pattern_size):
            padding = (col, row, 0, 0)
            pixel = filled_px if pattern[row][col] == "1" else BLANK_PX
            built_sym.append(render.Padding(child = pixel, pad = padding))

    return render.Stack(children = built_sym)

def merc(lat):
    """Convert a latitude coordinate to its Mercator projection value.

    Args:
        lat: (float) Latitude in degrees.

    Returns:
        mercator value: (float) Mercator projection value for the latitude.
    """
    return math.log(math.tan(math.pi / 4 + math.radians(lat) / 2))

def lat_to_row(lat, lat_top, lat_bottom, height):
    """Convert a latitude value to the corresponding map row.

    Args:
        lat: (float) Latitude in degrees.
        lat_top: (float) Latitude at the top edge of the map.
        lat_bottom: (float) Latitude at the bottom edge of the map.
        height: (int) Map height in pixels.

    Returns:
        row: (int | None) Map row index, or None if the point is off the map.
    """
    row = math.floor((merc(lat_top) - merc(lat)) / (merc(lat_top) - merc(lat_bottom)) * height)

    return row if 0 <= row and row < height else None

def lon_to_col(lon, lon_left, lon_right, width):
    """Convert a longitude value to the corresponding map column.

    Args:
        lon: (float) Longitude in degrees.
        lon_left: (float) Longitude at the left edge of the map.
        lon_right: (float) Longitude at the right edge of the map.
        width: (int) Map width in pixels.

    Returns:
        column: (int | None) Map column index, or None if the point is off the map.
    """
    span = (lon_right - lon_left) % 360 or 360
    col = math.floor(((lon - lon_left) % 360) / span * width)

    return col if 0 <= col and col < width else None

def build_storm(lat, lon, wind, name, sym_size, map_choice, config):
    """Build a storm marker and metadata for display on the selected map.

    Args:
        lat: (float) Latitude of the storm center in degrees.
        lon: (float) Longitude of the storm center in degrees.
        wind: (int) Storm wind speed in knots.
        name: (str) Storm name to display.
        sym_size: (str) Symbol size as "small", "medium", or "large".
        map_choice: (str) Name of the map to use.
        config: (config object) Configuration used to render the storm symbol.

    Returns:
        storm: (dict | None) Storm display metadata and rendered symbol, or None if the storm is off the map.
    """
    symbol = build_symbol(wind, sym_size, config)
    sym_dim = math.sqrt(len(symbol.children))  # Width/height of symbol
    pad_adj = int((sym_dim - 1) // 2)  # Ensures center of symbol at correct location on display
    top = MAP_BOUNDS[map_choice]["top"]
    bottom = MAP_BOUNDS[map_choice]["bottom"]
    left = MAP_BOUNDS[map_choice]["left"]
    right = MAP_BOUNDS[map_choice]["right"]

    # Set pixel locations on display
    scale = 2 if canvas.is2x() else 1
    display_lat = lat_to_row(lat, top, bottom, 32 * scale)
    display_lon = lon_to_col(lon, left, right, 64 * scale)
    if display_lat == None or display_lon == None:  # Returns None if storm off the map
        return None

    pad_top = display_lat - pad_adj
    pad_left = display_lon - pad_adj
    storm = render.Padding(
        child = symbol,
        pad = (pad_left, pad_top, 0, 0),
    )

    return {
        "symbol": storm,
        "name": name,
        "intensity": calc_intensity(wind),
        "display_lon": pad_left,
    }

def format_name(name):
    """Normalize a storm name for display.

    Args:
        name: (str | tuple) Storm name from NHC or JTWC.

    Returns:
        name: (str) Storm name formatted for the map.
    """
    is_nhc = type(name) == "string"  # NHC names always a string; JTWC names always a tuple

    if is_nhc:
        # ----- NHC names -----
        name = name.upper()
        for suffix in TD_NHC_SUFFIX:  # If name ends in suffix, then it is a TD
            if name.endswith(suffix):
                return STR_TO_NUM[name[:-2]] + suffix[-1]
        if name in NUM_STRS:  # If name is a number, then it is still TD just with no suffix
            return STR_TO_NUM[name]
        else:  # All other names are non-number
            return name

    else:
        # ----- JTWC names -----
        j_name = name[0][2].upper()
        j_suffix = name[0][1].upper()
        if j_name in NUM_STRS:  # If name is a number, then it is TD
            return STR_TO_NUM[j_name] + j_suffix
        else:  # For all other non-number storm names
            return j_name

def get_nhc():
    """Fetch active tropical cyclone data from the NHC.

    Returns:
        storms: (list[dict] | None) Active storm metadata with name, latitude, longitude,
            and wind speed for each storm in the NHC advisory feed.
    """
    resp = http.get(url = URL_NHC, headers = HEADERS, ttl_seconds = REFRESH_RATE)
    if resp.status_code != 200:
        print("NHC request failed with status %s" % str(resp.status_code))
        return None

    decoded = resp.json()
    if "activeStorms" not in decoded:
        return None

    nhc_storms = decoded["activeStorms"]
    if len(nhc_storms) == 0:
        return None

    storms = []
    for storm in nhc_storms:
        storms.append(
            {
                "name": format_name(storm["name"]),
                "lat": storm["latitudeNumeric"],
                "lon": storm["longitudeNumeric"],
                "wind": int(storm["intensity"]),
            },
        )

    return storms

def parse_jtwc(url):
    """Parse a single JTWC warning page into a normalized storm record.

    Args:
        url: (str) URL for a JTWC warning text file.

    Returns:
        storm: (dict | None) Parsed storm data with normalized name, latitude, longitude,
            and wind speed, or None if the data cannot be parsed.
    """
    resp = http.get(url = url, headers = HEADERS, ttl_seconds = REFRESH_RATE)
    if resp.status_code != 200:
        print("JTWC Warning request failed with status %s" % str(resp.status_code))
        return None

    # Extract data
    pos = re.match(PATTERN_POS, resp.body())
    winds = re.match(PATTERN_WIND, resp.body())
    name = re.match(PATTERN_NAME, resp.body())
    if not pos or not winds or not name:
        return None

    # Parse latitude
    lat = pos[0][1]
    lat_dir = 1 if lat[-1].upper() == "N" else -1
    lat_float = float(lat.rstrip("NS"))

    # Parse longitude
    lon = pos[0][2]
    lon_dir = 1 if lon[-1].upper() == "E" else -1
    lon_float = float(lon.rstrip("EW"))

    return {
        "name": format_name(name),
        "lat": lat_float * lat_dir,
        "lon": lon_float * lon_dir,
        "wind": int(winds[0][1]),
    }

def get_jtwc():
    """Fetch active tropical cyclone warnings from the JTWC RSS feed.

    Returns:
        storms: (list[dict] | None) JTWC storm records for active warnings that are not
            already represented by NHC basins.
    """
    resp = http.get(url = URL_JTWC, headers = HEADERS, ttl_seconds = REFRESH_RATE)
    if resp.status_code != 200:
        print("JTWC request failed with status %s" % str(resp.status_code))
        return None

    xml = xpath.loads(resp.body())
    xml_storms = xml.query_all("/rss/channel/item/description")
    if not xml_storms:
        print("JTWC RSS cannot be loaded")
        return None

    # Get web.txt URLs for storms; these are official JTWC warnings
    storm_urls = []
    for storm in xml_storms:
        results = re.match(PATTERN_WEBTXT, storm)
        for match in results:
            is_warning = re.search("Warning", match[0])  # Ensures only established storms
            is_nhc_basin = re.search(r"(ep|cp)\d+?web", match[0])  # Removes storms already covered by NHC
            if is_warning and not is_nhc_basin:
                storm_urls.append(match[1])
    if not storm_urls:
        return None

    # Set storm data from warning URLs
    storms = [parse_jtwc(u) for u in storm_urls]
    storms = [s for s in storms if s]  # Removes storms that could not be parsed

    return storms

def get_schema():
    """Build the app configuration schema for the hurricane map.

    Returns:
        schema.Schema: (schema.Schema) The configurable map UI including basin, symbol style,
            and display settings.
    """
    map_options = [
        schema.Option(
            display = "Global (0° Centered)",
            value = "G0",
        ),
        schema.Option(
            display = "Global (180° Centered)",
            value = "G180",
        ),
        schema.Option(
            display = "Northern Atlantic",
            value = "NA",
        ),
        schema.Option(
            display = "Eastern Pacific",
            value = "EP",
        ),
        schema.Option(
            display = "Western Pacific",
            value = "WP",
        ),
        schema.Option(
            display = "Southern Pacific",
            value = "SP",
        ),
        schema.Option(
            display = "Northern Indian",
            value = "NI",
        ),
        schema.Option(
            display = "Southern Indian",
            value = "SI",
        ),
    ]

    sym_size_options = [
        schema.Option(
            display = "Small",
            value = "small",
        ),
        schema.Option(
            display = "Medium",
            value = "medium",
        ),
        schema.Option(
            display = "Large",
            value = "large",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "map_choice",
                name = "Basin map",
                desc = "Select the hurricane basin to display",
                icon = "map",
                default = DEFAULT_MAP,
                options = map_options,
            ),
            schema.Toggle(
                id = "hide_if_quiet",
                name = "Hide if quiet",
                desc = "Hide this app if no storms exist in the selected basin",
                icon = "eyeSlash",
                default = DEFAULT_HIDE,
            ),
            schema.Toggle(
                id = "show_names",
                name = "Show names",
                desc = "Show the names of displayed storms, sorted from left to right",
                icon = "hurricane",
                default = DEFAULT_NAMES,
            ),
            schema.Dropdown(
                id = "sym_size",
                name = "Symbol size",
                desc = "Size of storm symbols",
                icon = "maximize",
                default = DEFAULT_SYM_SIZE,
                options = sym_size_options,
            ),
            schema.Color(
                id = "map_color",
                name = "Land color",
                desc = "Color of land on the map",
                icon = "brush",
                default = DEFAULT_COLORS["MAP"],
                palette = [
                    DEFAULT_COLORS["MAP"],
                ],
            ),
            schema.Color(
                id = "ocean_color",
                name = "Ocean color",
                desc = "Color of oceans on the map",
                icon = "brush",
                default = DEFAULT_COLORS["OCEAN"],
                palette = [
                    DEFAULT_COLORS["OCEAN"],
                ],
            ),
            schema.Color(
                id = "td_color",
                name = "Tropical Depression color",
                desc = "Symbol color for Tropical Depressions",
                icon = "brush",
                default = DEFAULT_COLORS["TD"],
                palette = [
                    DEFAULT_COLORS["TD"],
                ],
            ),
            schema.Color(
                id = "ts_color",
                name = "Tropical Storm color",
                desc = "Symbol color for Tropical Storms",
                icon = "brush",
                default = DEFAULT_COLORS["TS"],
                palette = [
                    DEFAULT_COLORS["TS"],
                ],
            ),
            schema.Color(
                id = "cat1_color",
                name = "Category 1 color",
                desc = "Symbol color for Category 1 storms",
                icon = "brush",
                default = DEFAULT_COLORS[1],
                palette = [
                    DEFAULT_COLORS[1],
                ],
            ),
            schema.Color(
                id = "cat2_color",
                name = "Category 2 color",
                desc = "Symbol color for Category 2 storms",
                icon = "brush",
                default = DEFAULT_COLORS[2],
                palette = [
                    DEFAULT_COLORS[2],
                ],
            ),
            schema.Color(
                id = "cat3_color",
                name = "Category 3 color",
                desc = "Symbol color for Category 3 storms",
                icon = "brush",
                default = DEFAULT_COLORS[3],
                palette = [
                    DEFAULT_COLORS[3],
                ],
            ),
            schema.Color(
                id = "cat4_color",
                name = "Category 4 color",
                desc = "Symbol color for Category 4 storms",
                icon = "brush",
                default = DEFAULT_COLORS[4],
                palette = [
                    DEFAULT_COLORS[4],
                ],
            ),
            schema.Color(
                id = "cat5_color",
                name = "Category 5 color",
                desc = "Symbol color for Category 5 storms",
                icon = "brush",
                default = DEFAULT_COLORS[5],
                palette = [
                    DEFAULT_COLORS[5],
                ],
            ),
        ],
    )
