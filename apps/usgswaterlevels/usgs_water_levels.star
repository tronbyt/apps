"""
USGS Water Levels Tidbyt App
Displays local lake and river water levels as a graph using USGS data
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Default USGS site ID (Lake Champlain at Burlington, VT)
DEFAULT_SITE_ID = "04294500"
CACHE_TTL_SECONDS = 3600  # 1 hour
USGS_API_BASE = "https://api.waterdata.usgs.gov/ogcapi/v0/collections"
USGS_SQUID = "https://api.waterdata.usgs.gov/squid/monitoring-locations"

GAUGE_SEARCH_RADIUS_KM = 25
GAUGE_PICKER_LIMIT = 50
GAUGE_PICKER_TTL = 86400
STREAM_SITE_TYPES = ["ST", "ST-CA", "ST-DCH", "ST-TS", "LK"]

# Parameters this app can display (lake + river dropdowns)
PICKER_PARAMS = [
    "62614",
    "00062",
    "62610",
    "62611",
    "00065",
    "00060",
    "72255",
    "00048",
    "00010",
    "00095",
]

production = True
debug_site_selection = False
default_location = """{
	"lat": "44.476",
	"lng": "-73.212",
	"description": "Burlington, VT, USA",
	"timezone": "America/New_York"
}"""

def debug_site(msg):
    if debug_site_selection:
        print("usgs-water-levels site: " + msg)

def main(config):
    site_id, bad_site = resolve_site(config, "site_id", "site_id_picker", DEFAULT_SITE_ID)
    if bad_site:
        return render.Root(
            child = render.Column(
                children = [
                    render.Text("USGS Water Levels", color = "#4A90E2"),
                    render.Text("Invalid site ID", color = "#FF6B6B", font = "tom-thumb"),
                ],
            ),
        )
    if not site_id:
        site_id = DEFAULT_SITE_ID
    debug_site("using site: " + site_id)
    water_body_type = config.get("water_body_type", "0")  # 0 for lakes, 1 for rivers
    param_code = config.get("param_code", "auto")  # auto or specific code
    custom_display_name = config.get("display_name", "")

    # Get fresh data, falling back to cache only when the fetch fails
    cache_key = "usgs_data_" + site_id + "_" + water_body_type + "_" + param_code
    cached_data = cache.get(cache_key)
    data = fetch_usgs_data(site_id, water_body_type, param_code)
    if data:
        cache.set(cache_key, json.encode(data), ttl_seconds = CACHE_TTL_SECONDS)
    elif cached_data != None:
        data = json.decode(cached_data)

    if not data:
        return render.Root(
            child = render.Column(
                children = [
                    render.Text("USGS Water Levels", color = "#4A90E2"),
                    render.Text("No data available", color = "#FF6B6B"),
                    render.Text("Check site ID: " + site_id, font = "tom-thumb"),
                ],
            ),
        )

    site_name = custom_display_name if custom_display_name else data["site_name"]

    # Create the display - 3 box layout
    return render.Root(
        child = render.Row(
            children = [
                # Left side: 85% of width for content
                render.Box(
                    width = 54,  # 85% of 64 pixels
                    child = render.Column(
                        children = [
                            # Top: marquee section
                            render.Box(
                                height = 12,
                                child = render.Column(
                                    children = [
                                        render.Marquee(
                                            width = 54,
                                            child = render.Text(site_name, color = "#4A90E2", font = "tom-thumb"),
                                        ) if len(site_name) > 12 else render.Text(site_name, color = "#888", font = "tom-thumb"),
                                        render.Text(data["param_description"], color = "#ff4", font = "tom-thumb"),
                                    ],
                                ),
                            ),
                            # Bottom: Large number display
                            render.Box(
                                height = 20,  # Remaining height
                                child = render.Column(
                                    main_align = "center",
                                    cross_align = "center",
                                    children = [
                                        # Large number with units beside it
                                        render.Row(
                                            main_align = "center",
                                            cross_align = "end",
                                            children = [
                                                render.Text(
                                                    str(int(data["current_value"] * 100) / 100),
                                                    color = "#4A90E2",
                                                    font = "6x13",
                                                ),
                                                render.Text(
                                                    " " + data["units"],
                                                    color = "#FFF",
                                                    font = "tom-thumb",
                                                ),
                                            ],
                                        ),
                                        # Small icon/description
                                        render.Text(
                                            get_param_icon(data["param_description"]),
                                            color = "#888",
                                            font = "tom-thumb",
                                        ),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ),
                # Right side: 15% of width, FULL HEIGHT for indicator
                render.Box(
                    width = 10,  # 15% of 64 pixels
                    height = 32,  # FULL display height
                    child = render_indicator(data["current_value"], data.get("high_30d"), data.get("low_30d")),
                ),
            ],
        ),
    )

def parse_site_id(raw):
    s = (raw or "").strip().upper()
    i = s.find("USGS-")
    if i >= 0:
        s = s[i + 5:]
    run = ""
    for c in s.elems():
        if c.isdigit():
            run += c
        elif run:
            if len(run) >= 8:
                break
            run = ""
    if len(run) >= 8 and len(run) <= 15:
        return run
    return None

def normalize_site_id(site_id):
    parsed = parse_site_id(site_id)
    if parsed:
        return parsed
    site_id = (site_id or "").strip()
    if site_id.startswith("USGS-"):
        site_id = site_id[5:]
    return site_id

def gauge_bounding_box(lat, lng, radius_km):
    R = 6371.0
    lat_r = math.radians(lat)
    dlat = math.degrees(radius_km / R)
    dlng = math.degrees(radius_km / R / math.cos(lat_r))
    return (lng - dlng, lat - dlat, lng + dlng, lat + dlat)

def haversine_km(lat1, lng1, lat2, lng2):
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = math.pow(math.sin(dlat / 2), 2) + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.pow(math.sin(dlng / 2), 2)
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

def has_picker_data(props):
    for p in props.get("observedParameters") or []:
        if p in PICKER_PARAMS:
            return True
    return False

def build_squid_gauge_url(bbox, since_date):
    min_lng, min_lat, max_lng, max_lat = bbox
    query = "mimeType=application/json&pageSize=%d" % GAUGE_PICKER_LIMIT
    query += "&boundingBox=%s,%s,%s,%s" % (min_lng, min_lat, max_lng, max_lat)
    query += "&dataCollectedSinceDatetime=" + since_date
    query += "&dataType=Continuous%20values"
    for code in STREAM_SITE_TYPES:
        query += "&siteTypeCode=" + code
    return USGS_SQUID + "?" + query

def fetch_squid_gauges(lat, lng):
    since_date = (time.now() - time.parse_duration("8760h")).format("2006-01-02")
    bbox = gauge_bounding_box(lat, lng, GAUGE_SEARCH_RADIUS_KM)
    resp = http.get(build_squid_gauge_url(bbox, since_date), ttl_seconds = GAUGE_PICKER_TTL)
    if resp.status_code != 200:
        return []

    seen = {}
    rows = []
    for f in (resp.json() or {}).get("features") or []:
        props = f.get("properties") or {}
        if not has_picker_data(props):
            continue
        site = parse_site_id(props.get("monitoringLocationIdentifier"))
        if not site or site in seen:
            continue
        geom = f.get("geometry") or {}
        coords = geom.get("coordinates") or []
        if len(coords) < 2:
            continue
        glng = float(coords[0])
        glat = float(coords[1])
        name = props.get("monitoringLocationName") or ("USGS " + site)
        rows.append({
            "site": site,
            "name": name,
            "dist": haversine_km(lat, lng, glat, glng),
        })
        seen[site] = True
    return sorted(rows, key = lambda r: r["dist"])

def gauge_picker_label(site, name):
    if len(name) > 40:
        name = name[:40]
    return site + " — " + name

def get_nearby_gauges(location):
    loc = json.decode(location)
    lat = float(loc["lat"])
    lng = float(loc["lng"])
    place = loc.get("description") or (loc.get("lat") + "," + loc.get("lng"))
    rows = fetch_squid_gauges(lat, lng)
    if not rows:
        debug_site('picker search at "%s": no gauges in bbox' % place)
        return [
            schema.Option(
                display = "No gauges found — use site ID below",
                value = "",
            ),
        ]
    options = []
    for row in rows:
        options.append(schema.Option(
            display = gauge_picker_label(row["site"], row["name"]),
            value = row["site"],
        ))
    debug_site('picker search at "%s": %d gauge(s)' % (place, len(options)))
    return options

def picker_site_value(raw):
    raw = (raw or "").strip()
    if not raw:
        return None
    if raw.startswith("{"):
        raw = (json.decode(raw).get("value") or "").strip()
    if not raw:
        return None
    return parse_site_id(raw)

def resolve_site(config, manual_key, picker_key, default):
    manual = (config.get(manual_key) or "").strip()
    if manual:
        site = parse_site_id(manual)
        if site == None:
            debug_site("%s: invalid manual entry %r" % (picker_key, manual))
            return None, True
        debug_site("%s: manual override -> %s" % (picker_key, site))
        return site, False
    picker_raw = (config.get(picker_key) or "").strip()
    site = picker_site_value(picker_raw)
    if site:
        display = ""
        if picker_raw.startswith("{"):
            display = (json.decode(picker_raw).get("display") or "").strip()
        if display:
            debug_site('%s: picker -> %s ("%s")' % (picker_key, site, display))
        else:
            debug_site("%s: picker -> %s" % (picker_key, site))
        return site, False
    if default:
        debug_site("%s: default -> %s" % (picker_key, default))
        return default, False
    debug_site("%s: none selected" % picker_key)
    return None, False

def gauge_picker_field(id, name, desc):
    if production:
        return schema.LocationBased(
            id = id,
            name = name,
            desc = desc,
            icon = "locationDot",
            handler = get_nearby_gauges,
        )
    options = get_nearby_gauges(default_location)
    if not options:
        options = [schema.Option(display = DEFAULT_SITE_ID, value = DEFAULT_SITE_ID)]
    return schema.Dropdown(
        id = id,
        name = name,
        desc = desc + " (local preview uses gauges near Burlington, VT).",
        icon = "locationDot",
        default = options[0].value,
        options = options,
    )

def monitoring_location_id(site_id):
    return "USGS-" + normalize_site_id(site_id)

def fetch_site_name(location_id):
    url = USGS_API_BASE + "/monitoring-locations/items/" + location_id
    resp = http.get(url, ttl_seconds = CACHE_TTL_SECONDS)
    if resp.status_code != 200:
        print("Error fetching site metadata: " + str(resp.status_code))
        return None

    props = resp.json().get("properties", {})
    return props.get("monitoring_location_name")

def get_param_codes(water_body_type, param_code):
    if param_code == "auto":
        if water_body_type == "0":
            return ["62614", "00062", "62610", "62611", "00065", "00010", "00095"]
        return ["00065", "00060", "72255", "00010", "00095", "00048", "62614", "00062", "62610", "62611"]
    return [param_code]

def fetch_usgs_data(site_id, water_body_type, param_code):
    site_id = normalize_site_id(site_id)
    if site_id == "":
        print("Empty site ID")
        return None

    location_id = monitoring_location_id(site_id)
    site_name = fetch_site_name(location_id)
    param_codes = get_param_codes(water_body_type, param_code)

    end_date = time.now()
    start_date_30d = time.now() - time.parse_duration("720h")  # 30 days
    start_str = start_date_30d.format("2006-01-02") + "T00:00:00Z"
    end_str = end_date.format("2006-01-02") + "T23:59:59Z"

    for param_code_to_try in param_codes:
        print("Trying parameter code: " + param_code_to_try)

        param_parts = []
        param_parts.append("monitoring_location_id=" + location_id)
        param_parts.append("parameter_code=" + param_code_to_try)
        param_parts.append("datetime=" + start_str + "/" + end_str)
        param_parts.append("limit=10000")
        full_url = USGS_API_BASE + "/continuous/items?" + "&".join(param_parts)

        print("Fetching USGS continuous data from: " + full_url)

        resp = http.get(full_url, ttl_seconds = CACHE_TTL_SECONDS)
        if resp.status_code != 200:
            print("Error fetching continuous data: " + str(resp.status_code))
            continue

        features = resp.json().get("features", [])
        if not features:
            print("No continuous data found for parameter " + param_code_to_try)
            continue

        processed_values = []
        for feature in features:
            val_str = feature.get("properties", {}).get("value")
            if val_str != None and val_str != "":
                processed_values.append(float(val_str))

        if not processed_values:
            print("No valid values found for parameter " + param_code_to_try)
            continue

        print("Found data with parameter code: " + param_code_to_try)

        high_30d = max(processed_values)
        low_30d = min(processed_values)
        current_value = processed_values[len(processed_values) - 1]

        recent_values = processed_values
        if len(processed_values) > 10:
            recent_values = processed_values[len(processed_values) - 10:]

        trend = "Unknown"
        if len(recent_values) >= 6:
            recent_vals = recent_values[len(recent_values) - 3:]
            older_vals = recent_values[:3]

            recent_total = 0
            for val in recent_vals:
                recent_total = recent_total + val
            recent_avg = recent_total / len(recent_vals)

            older_total = 0
            for val in older_vals:
                older_total = older_total + val
            older_avg = older_total / len(older_vals)

            if recent_avg > older_avg + 0.1:
                trend = "Rising"
            elif recent_avg < older_avg - 0.1:
                trend = "Falling"
            else:
                trend = "Stable"

        if param_code_to_try == "00010":
            current_value = (current_value * 9 / 5) + 32
            high_30d = (high_30d * 9 / 5) + 32
            low_30d = (low_30d * 9 / 5) + 32

        return {
            "site_name": site_name if site_name else site_id,
            "values": recent_values,
            "current_value": current_value,
            "high_30d": high_30d,
            "low_30d": low_30d,
            "trend": trend,
            "units": get_param_units(param_code_to_try),
            "param_description": get_param_description(param_code_to_try),
        }

    print("No data found for any parameter codes")
    return None

def get_param_description(param_code):
    # Get human-readable description for parameter code
    descriptions = {
        "62614": "Daily Level",
        "00010": "Water Temp",
        "00095": "Conductance",
        "00065": "Gage Height",
        "00060": "Flow Rate",
        "72255": "Velocity",
        "00048": "Gas Saturation",
        "00062": "Lake Level",
        "62610": "Lake Level",
        "62611": "Lake Level",
    }
    return descriptions.get(param_code, "Water Data")

def get_param_units(param_code):
    # Get units for parameter code
    units = {
        "00010": "°F",  # Temperature in Fahrenheit
        "00095": "μS/cm",
        "00065": "ft",  # Gage height in feet
        "00060": "cfs",  # Discharge in cubic feet per second
        "72255": "ft/s",  # Mean water velocity
        "00048": "%",  # Dissolved gas saturation
        "00062": "ft",  # Lake elevation in feet
        "62610": "ft",  # Lake elevation NGVD 1929 in feet
        "62611": "ft",  # Lake elevation NAVD 1988 in feet
        "62614": "ft",  # Daily lake level in feet
    }
    return units.get(param_code, "ft")

def get_param_icon(param_description):
    # Get a simple icon/symbol for the parameter type
    icons = {
        "Water Temp": "🌡️",
        "Conductance": "⚡",
        "Gage Height": "📏",
        "Flow Rate": "💨",
        "Velocity": "🏃",
        "Gas Saturation": "🫧",
        "Lake Level": "🌊",
        "Daily Level": "📊",
    }
    return icons.get(param_description, "💧")

def render_indicator(current_value, high_30d, low_30d):
    # Render a vertical indicator showing current value vs 30-day high/low
    if high_30d == None or low_30d == None:
        # No historical data, just show a simple indicator
        return render.Column(
            children = [
                render.Text("x", color = "#4A90E2", font = "tom-thumb"),
            ],
        )

    # Debug: print the values to see what's happening
    print("Current: " + str(current_value) + ", High: " + str(high_30d) + ", Low: " + str(low_30d))

    # Calculate where current value should be positioned (0 = top, 28 = bottom)
    range_val = high_30d - low_30d
    if range_val > 0:
        # Position ratio: 0.0 = at high (top), 1.0 = at low (bottom)
        position_ratio = (current_value - low_30d) / range_val

        # Invert so high values go to top: 1.0 = at high (top), 0.0 = at low (bottom)
        position_ratio = 1.0 - position_ratio

        # Scale to pixel range (0 to 28 pixels from top)
        x_position = int(position_ratio * 28)
    else:
        x_position = 14  # Middle if no range

    print("Position ratio: " + str(1.0 - (current_value - low_30d) / range_val if range_val > 0 else 0.5))
    print("X position (pixels from top): " + str(x_position))

    # Use Stack to position elements absolutely
    elements = []

    # Always show green dash at top (unless current is at/above high)
    if current_value >= high_30d:
        elements.append(
            render.Padding(
                pad = (0, 0, 0, 0),
                child = render.Text("x", color = "#4A90E2", font = "tom-thumb"),
            ),
        )
        print("Added X at top (replacing green dash)")
    else:
        elements.append(
            render.Padding(
                pad = (0, 0, 0, 0),
                child = render.Text("-", color = "#a7fc00", font = "tom-thumb"),
            ),
        )
        print("Added green dash at top")

    # Show blue X at calculated position if current is between high and low
    if current_value < high_30d and current_value > low_30d:
        elements.append(
            render.Padding(
                pad = (0, x_position, 0, 0),  # Calculated position from top
                child = render.Text("x", color = "#4A90E2", font = "tom-thumb"),
            ),
        )
        print("Added X at calculated position: " + str(x_position))

    # Always show red dash at bottom (unless current is at/below low)
    if current_value <= low_30d:
        elements.append(
            render.Padding(
                pad = (0, 28, 0, 0),  # 28 pixels from top (near bottom)
                child = render.Text("x", color = "#4A90E2", font = "tom-thumb"),
            ),
        )
        print("Added X at bottom (replacing red dash)")
    else:
        elements.append(
            render.Padding(
                pad = (0, 28, 0, 0),  # 28 pixels from top
                child = render.Text("-", color = "#FF6B6B", font = "tom-thumb"),
            ),
        )
        print("Added red dash at bottom")

    return render.Stack(
        children = elements,
    )

def render_graph(values):
    # Render a simple line graph that fills most of the screen
    if not values or len(values) < 2:
        return render.Text("No data", color = "#888", font = "tom-thumb")

    # Use most of the available screen space
    graph_width = 60  # Almost full width
    graph_height = 28  # Almost full height

    # Normalize values to fit in display area
    min_val = min(values)
    max_val = max(values)
    range_val = max_val - min_val if max_val != min_val else 1

    # Create a more detailed graph representation
    graph_bars = []
    for i in range(graph_width):
        # Map screen position to data point
        data_index = int((i / (graph_width - 1)) * (len(values) - 1))
        val = values[data_index]

        # Calculate bar height (normalized to graph height)
        bar_height = int(((val - min_val) / range_val) * graph_height)
        bar_height = max(1, min(bar_height, graph_height))  # Ensure valid range

        # Create vertical bar for this data point
        graph_bars.append(
            render.Box(
                width = 1,
                height = bar_height,
                color = "#4A90E2",
            ),
        )

    return render.Stack(
        children = [
            # Graph background
            render.Box(
                width = graph_width,
                height = graph_height,
                color = "#0a0a0a",
            ),
            # Graph bars
            render.Row(
                children = graph_bars,
                main_align = "start",
                cross_align = "end",
            ),
        ],
    )

def get_trend_color(trend):
    # Get color for trend indicator
    if trend == "Rising":
        return "#50E3C2"  # Green
    elif trend == "Falling":
        return "#FF6B6B"  # Red
    else:
        return "#FFD93D"  # Yellow

def get_lake_param_options():
    return [
        schema.Option(display = "Auto (tries multiple)", value = "auto"),
        schema.Option(display = "Daily Lake Level", value = "62614"),
        schema.Option(display = "Lake/Reservoir Elevation", value = "00062"),
        schema.Option(display = "Lake Elevation - NGVD 1929", value = "62610"),
        schema.Option(display = "Lake Elevation - NAVD 1988", value = "62611"),
        schema.Option(display = "Water Temperature", value = "00010"),
        schema.Option(display = "Specific Conductance", value = "00095"),
    ]

def get_river_param_options():
    return [
        schema.Option(display = "Auto (tries multiple)", value = "auto"),
        schema.Option(display = "Gage Height", value = "00065"),
        schema.Option(display = "Discharge (Flow)", value = "00060"),
        schema.Option(display = "Water Velocity", value = "72255"),
        schema.Option(display = "Dissolved Gas Saturation", value = "00048"),
        schema.Option(display = "Water Temperature", value = "00010"),
        schema.Option(display = "Specific Conductance", value = "00095"),
    ]

def param_options_for_water_body(water_body_type):
    if water_body_type == "1":
        options = get_river_param_options()
    else:
        options = get_lake_param_options()

    return [
        schema.Dropdown(
            id = "param_code",
            name = "Data Parameter",
            desc = "Choose what type of data to display",
            icon = "ruler",
            default = "auto",
            options = options,
        ),
    ]

def get_schema():
    picker_desc = "Lake and stream sites with recent data within about %d km of your location." % GAUGE_SEARCH_RADIUS_KM
    return schema.Schema(
        version = "1",
        fields = [
            gauge_picker_field(
                "site_id_picker",
                "Nearby Site",
                picker_desc,
            ),
            schema.Text(
                id = "site_id",
                name = "USGS Site ID",
                desc = "Optional override. Site number (e.g. 04294500 or USGS-04294500) or a waterdata.usgs.gov link.",
                icon = "water",
            ),
            schema.Text(
                id = "display_name",
                name = "Custom Display Name",
                desc = "Leave blank to use USGS defined name",
                icon = "user",
                default = "",
            ),
            schema.Dropdown(
                id = "water_body_type",
                name = "Water Body Type",
                desc = "Select the type of water body to monitor",
                icon = "water",
                default = "0",
                options = [
                    schema.Option(display = "Lake/Reservoir", value = "0"),
                    schema.Option(display = "River/Stream", value = "1"),
                ],
            ),
            schema.Generated(
                id = "param_code",
                source = "water_body_type",
                handler = param_options_for_water_body,
            ),
        ],
    )
