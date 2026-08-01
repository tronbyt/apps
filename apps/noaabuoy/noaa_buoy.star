"""
Applet: NOAA Buoy
Summary: Display buoy weather data
Description: Display swell,wind,temperature,misc data for user specified buoy. Find buoy_id's here : https://www.ndbc.noaa.gov/obs.shtml
Author: tavdog
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("xpath.star", "xpath")

print_debug = True

default_location = """
{
    "lat": "20.8911",
    "lng": "-156.5047",
    "description": "Wailuku, HI, USA",
    "locality": "Maui",
    "place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
    "timezone": "America/Honolulu"
}
"""

def debug_print(arg):
    if print_debug:
        print(arg)

# Extract the value cell text following a label inside the Wave Summary table
# Looks for: ... <td>LABEL</td><td> VALUE </td>
def td_value(wave_section, label):
    i = wave_section.find(label)
    if i == -1:
        return None
    j = wave_section.find("</td><td", i)
    if j == -1:
        return None
    k = wave_section.find(">", j)
    if k == -1:
        return None
    l = wave_section.find("</td>", k)
    if l == -1:
        return None
    return wave_section[k + 1:l].strip()

def swell_over_threshold(thresh, units, data, use_wind_swell):  # assuming threshold is already in preferred units
    if use_wind_swell:
        height = data.get("WIND_WVHT", "0")
    else:
        height = data.get("WVHT", "0")
    if thresh == "" or float(thresh) == 0.0:
        return True
    elif units == "m":
        height = float(height) / 3.281
        height = int(height * 10)
        height = height / 10.0

    return float(height) >= float(thresh)

def FtoC(F):  # returns rounded to 1 decimal
    if F == "--":
        return "--"
    c = (float(F) - 32) * 0.55
    c = int(c * 10)
    return c / 10.0

HEX_CHARS = "0123456789abcdef"

def to_hex(val):
    """Convert 0-255 int to two-char hex string"""
    return HEX_CHARS[val // 16] + HEX_CHARS[val % 16]

def period_to_color(period, min_period = 10.0, max_period = 20.0):
    """Map swell period to color: blue (short period) -> red (long period)"""

    # Clamp period to range
    if period < min_period:
        period = min_period
    if period > max_period:
        period = max_period

    # Normalize to 0-1 range
    t = (period - min_period) / (max_period - min_period)

    # Blue (0,0,255) -> Cyan (0,255,255) -> Green (0,255,0) -> Yellow (255,255,0) -> Red (255,0,0)
    if t < 0.25:
        # Blue to Cyan
        r = 0
        g = int(255 * (t / 0.25))
        b = 255
    elif t < 0.5:
        # Cyan to Green
        r = 0
        g = 255
        b = int(255 * (1 - (t - 0.25) / 0.25))
    elif t < 0.75:
        # Green to Yellow
        r = int(255 * ((t - 0.5) / 0.25))
        g = 255
        b = 0
    else:
        # Yellow to Red
        r = 255
        g = int(255 * (1 - (t - 0.75) / 0.25))
        b = 0

    return "#" + to_hex(r) + to_hex(g) + to_hex(b)

def fetch_spec_data(buoy_id, use_wind_swell = False, days = 5):
    """Fetch spectral data from NOAA for swell graph"""
    url = "https://www.ndbc.noaa.gov/data/realtime2/%s.spec" % buoy_id.upper()
    debug_print("Fetching spec data from: " + url)

    resp = http.get(url, ttl_seconds = 1800)  # 30 min cache
    if resp.status_code != 200:
        debug_print("Failed to fetch spec data: " + str(resp.status_code))
        return None

    lines = resp.body().split("\n")
    data_points = []

    # Get current time for filtering
    now = time.now()

    # Calculate max age in seconds based on days parameter
    max_age_seconds = days * 24 * 60 * 60

    for line in lines:
        # Skip comment lines
        if line.startswith("#") or line.strip() == "":
            continue

        parts = line.split()
        if len(parts) < 10:
            continue

        # Parse: YY MM DD hh mm WVHT SwH SwP WWH WWP ...
        # Columns: 0=YY 1=MM 2=DD 3=hh 4=mm 5=WVHT 6=SwH 7=SwP 8=WWH 9=WWP
        year = parts[0]
        month = parts[1]
        day = parts[2]
        hour = parts[3]
        minute = parts[4]

        if use_wind_swell:
            # Use wind wave data (WWH, WWP)
            swh_str = parts[8]  # Wind Wave Height in meters
            swp_str = parts[9]  # Wind Wave Period in seconds
        else:
            # Use swell data (SwH, SwP)
            swh_str = parts[6]  # Swell Height in meters
            swp_str = parts[7]  # Swell Period in seconds

        # Skip MM (missing) values
        if swh_str == "MM" or swp_str == "MM":
            continue

        swh = float(swh_str)
        swp = float(swp_str)

        # Parse timestamp
        timestamp_str = "%s-%s-%sT%s:%s:00Z" % (year, month, day, hour, minute)
        ts = time.parse_time(timestamp_str, "2006-01-02T15:04:05Z")

        if ts == None:
            continue

        # Filter based on configured days
        age_seconds = (now - ts).seconds
        if age_seconds > max_age_seconds:
            continue

        # Convert height to feet for display
        swh_feet = swh * 3.281

        data_points.append({
            "ts": ts,
            "age_hours": age_seconds / 3600.0,
            "swh": swh_feet,
            "swp": swp,
        })

    # Sort by timestamp (oldest first for plotting)
    # Data comes newest first, so reverse
    data_points = list(reversed(data_points))

    debug_print("Parsed %d spec data points for %d days" % (len(data_points), days))
    return data_points

def render_swell_graph(data_points, buoy_name, h_unit_pref, t_unit_pref, data, use_wind_swell = False):
    """Render a swell height graph as background with text overlay"""
    if not data_points or len(data_points) < 2:
        return None

    # Display dimensions
    width = 64
    height = 32

    # Find min/max for scaling
    max_swh = 0.0
    for dp in data_points:
        if dp["swh"] > max_swh:
            max_swh = dp["swh"]

    # Add some padding to max
    max_swh = max_swh * 1.1
    if max_swh < 1.0:
        max_swh = 1.0
    min_swh = 0.0

    # Get time range
    max_age = data_points[0]["age_hours"] if data_points else 120.0
    min_age = data_points[-1]["age_hours"] if data_points else 0.0
    time_range = max_age - min_age
    if time_range < 1:
        time_range = 1

    # Create canvas for graph (full 32 height)
    canvas = []
    for _ in range(height):
        row = []
        for _ in range(width):
            row.append("#000000")
        canvas.append(row)

    # Plot each data point
    for dp in data_points:
        # X position (time - oldest on left, newest on right)
        x = int((max_age - dp["age_hours"]) / time_range * (width - 1))
        if x < 0:
            x = 0
        if x >= width:
            x = width - 1

        # Y position (height - higher values at top)
        y_norm = (dp["swh"] - min_swh) / (max_swh - min_swh)
        y = height - 1 - int(y_norm * (height - 1))
        if y < 0:
            y = 0
        if y >= height:
            y = height - 1

        # Color based on period (dimmed for background)
        color = period_to_color(dp["swp"])

        # Draw point (and fill below for area effect)
        for fill_y in range(y, height):
            # Fade color as we go down, also dim overall for background
            fade = (1.0 - (fill_y - y) / (height - y + 1) * 0.7) * 0.4
            r = int(int(color[1:3], 16) * fade)
            g = int(int(color[3:5], 16) * fade)
            b = int(int(color[5:7], 16) * fade)
            canvas[fill_y][x] = "#" + to_hex(r) + to_hex(g) + to_hex(b)

    # Build graph rows
    graph_rows = []
    for row in canvas:
        pixels = []
        for hex_color in row:
            pixels.append(render.Box(width = 1, height = 1, color = hex_color))
        graph_rows.append(render.Row(children = pixels))

    graph_widget = render.Column(children = graph_rows)

    # Get latest swell data for text overlay
    latest = data_points[-1] if data_points else None
    if latest:
        swh = latest["swh"]
        swp = latest["swp"]
    elif use_wind_swell:
        swh = float(data.get("WIND_WVHT", "0") or "0")
        swp = float(data.get("WIND_DPD", "0") or "0")
    else:
        swh = float(data.get("WVHT", "0") or "0")
        swp = float(data.get("DPD", "0") or "0")

    # Determine swell color based on height
    if swh < 2:
        swell_color = "#00AAFF"
    elif swh < 5:
        swell_color = "#AAEEDD"
    elif swh < 12:
        swell_color = "#00FF00"
    else:
        swell_color = "#FF0000"

    # Format height display
    unit_display = "f"
    if h_unit_pref == "meters":
        unit_display = "m"
        swh = swh / 3.281

    height_str = str(int(swh * 10) / 10.0)
    period_str = str(int(swp + 0.5))

    # Get direction (use wind wave direction if wind swell mode)
    if use_wind_swell:
        mwd = data.get("WIND_MWD", "--") or "--"
    else:
        mwd = data.get("MWD", "--") or "--"

    # Get water temp if available
    wtemp = ""
    if data.get("WTMP"):
        wt = data["WTMP"]
        if t_unit_pref == "C":
            wt = FtoC(wt)
        wt = int(float(wt) + 0.5)
        wtemp = " %s%s" % (str(wt), t_unit_pref)

    # Create text overlay (same as normal swell display)
    text_overlay = render.Box(
        width = 64,
        height = 32,
        child = render.Column(
            cross_align = "center",
            main_align = "center",
            expanded = True,
            children = [
                render.Text(
                    content = buoy_name,
                    font = "tb-8",
                    color = swell_color,
                ),
                render.Text(
                    content = "%s%s %ss" % (height_str, unit_display, period_str),
                    font = "6x13",
                    color = swell_color,
                ),
                render.Text(
                    content = "%s°%s" % (mwd, wtemp),
                    color = "#FFAA00",
                ),
            ],
        ),
    )

    return render.Root(
        child = render.Stack(
            children = [
                graph_widget,
                text_overlay,
            ],
        ),
    )

def fetch_data(buoy_id, last_data):
    debug_print("fetching....")
    data = dict()
    url = "https://www.ndbc.noaa.gov/station_page.php?station=%s" % buoy_id.lower()
    debug_print("url: " + url)
    resp = http.get(url, ttl_seconds = 600)  # 10 minutes http cache time
    debug_print(resp)
    if resp.status_code != 200 or "Invalid Station ID" in resp.body():
        if len(last_data) != 0:
            if "stale" not in last_data:
                last_data["stale"] = 1
            else:
                last_data["stale"] = last_data["stale"] + 1
            debug_print("stale counter to :" + str(last_data["stale"]))
            return last_data
        elif resp.status_code == 404:
            data["name"] = buoy_id
            data["error"] = "No Data"
            return data
        elif "Invalid Station ID" in resp.body():
            data["name"] = buoy_id
            data["error"] = "Invalid Station"
            return data
        else:
            data["name"] = buoy_id
            data["error"] = "Code: " + str(resp.status_code)
            return data

    html = resp.body()
    data["name"] = buoy_id  # fallback, no name in desktop page

    # Extract station name from page title if available
    title_match = re.findall(r"<title>.*Station (\w+) - (.+?) -.*</title>", html)
    if len(title_match) > 0:
        data["name"] = title_match[0][1].strip()

    # Weather Conditions section - try desktop format first
    weather_start = html.find('<section id="metdata"')
    if weather_start != -1:
        weather_end = html.find("</section>", weather_start)
        if weather_end != -1:
            weather_section = html[weather_start:weather_end]

            # Air Temperature
            atmp_match = re.findall(r"Air Temperature[^>]*</td><td[^>]*>\s*([0-9.]+)\s*°F", weather_section)
            if len(atmp_match) > 0:
                data["ATMP"] = atmp_match[0]

            # Water Temperature
            wtmp_match = re.findall(r"Water Temperature[^>]*</td><td[^>]*>\s*([0-9.]+)\s*°F", weather_section)
            if len(wtmp_match) > 0:
                data["WTMP"] = wtmp_match[0]

    # Wave Summary section - desktop format
    # First try to find structured table format (like the HTML you provided)
    wave_start = html.find('<section id="wavedata"')
    debug_print("Structured wave section search result: " + str(wave_start))
    wave_summary_found = False

    if wave_start != -1:
        # Found structured table format
        wave_section = ""
        wave_end = html.find("</section>", wave_start)
        if wave_end != -1:
            wave_summary_found = True
            wave_section = html[wave_start:wave_end]
            debug_print("Found structured wave section, length: " + str(len(wave_section)))

        # Parse desktop Wave Summary table using label->value td extraction
        # WVHT
        cell = td_value(wave_section, "Significant Wave Height (WVHT):")
        if cell != None:
            m = re.match(r"\s*([0-9.]+)\s*ft", cell)
            if len(m) > 0:
                data["WVHT"] = m[0][1]

        # SWH (prefer SWH for swell height; override WVHT if present)
        cell = td_value(wave_section, "Swell Height (SwH):")
        if cell != None:
            m = re.match(r"\s*([0-9.]+)\s*ft", cell)
            if len(m) > 0:
                data["SWH"] = m[0][1]

                # Always use SwH as the swell height shown by this app
                data["WVHT"] = data["SWH"]

        # DPD (swell period; override any other period)
        cell = td_value(wave_section, "Swell Period (SwP):")
        if cell != None:
            m = re.match(r"\s*([0-9.]+)\s*sec", cell)
            if len(m) > 0:
                data["DPD"] = m[0][1]
                data["WIND_DPD"] = None  # ensure UI uses swell period unless wind_swell is chosen

        # APD (fallback for DPD if missing)
        cell = td_value(wave_section, "Average Wave Period (APD):")
        if cell != None:
            m = re.match(r"\s*([0-9.]+)\s*sec", cell)
            if len(m) > 0:
                if "DPD" not in data:
                    data["DPD"] = m[0][1]
                data["APD"] = m[0][1]

        # MWD (use swell direction, not mean direction)
        cell = td_value(wave_section, "Swell Direction (SwD):")
        if cell != None:
            m = re.match(r"\s*([A-Z]+)", cell)
            if len(m) > 0:
                data["MWD"] = m[0][1]
                data["WIND_MWD"] = None  # ensure UI uses swell direction unless wind_swell is chosen

        # WIND_WVHT
        cell = td_value(wave_section, "Wind Wave Height (WWH):")
        if cell != None:
            m = re.match(r"\s*([0-9.]+)\s*ft", cell)
            if len(m) > 0:
                data["WIND_WVHT"] = m[0][1]

        # WIND_DPD
        cell = td_value(wave_section, "Wind Wave Period (WWP):")
        if cell != None:
            m = re.match(r"\s*([0-9.]+)\s*sec", cell)
            if len(m) > 0:
                data["WIND_DPD"] = m[0][1]

        # WIND_MWD
        cell = td_value(wave_section, "Wind Wave Direction (WWD):")
        if cell != None:
            m = re.match(r"\s*([A-Z]+)", cell)
            if len(m) > 0:
                data["WIND_MWD"] = m[0][1]

        # STEEPNESS
        cell = td_value(wave_section, "Wave Steepness (STEEPNESS):")
        if cell != None:
            m = re.match(r"\s*([A-Z]+)", cell)
            if len(m) > 0:
                data["STEEPNESS"] = m[0][1]

    # Additional data extraction for wind and other metrics from desktop format
    # Parse values directly from the Conditions table using td_value helper
    # Wind Direction (WDIR)
    cell = td_value(html, "Wind Direction (WDIR):")
    if cell != None:
        m = re.match(r"\s*([A-Z]+)", cell)
        if len(m) > 0:
            data["WDIR"] = m[0][1]

    # Wind Speed (WSPD)
    cell = td_value(html, "Wind Speed (WSPD):")
    if cell != None:
        m = re.match(r"\s*([0-9.]+)\s*kts", cell)
        if len(m) > 0:
            data["WSPD"] = m[0][1]

    # Fallbacks: use 10m or 20m wind speed if base WSPD missing
    if "WSPD" not in data:
        cell = td_value(html, "Wind Speed at 10 meters (WSPD10M):")
        if cell != None:
            m = re.match(r"\s*([0-9.]+)\s*kts", cell)
            if len(m) > 0:
                data["WSPD"] = m[0][1]
    if "WSPD" not in data:
        cell = td_value(html, "Wind Speed at 20 meters (WSPD20M):")
        if cell != None:
            m = re.match(r"\s*([0-9.]+)\s*kts", cell)
            if len(m) > 0:
                data["WSPD"] = m[0][1]

    # Wind Gust (GST)
    cell = td_value(html, "Wind Gust (GST):")
    if cell != None:
        m = re.match(r"\s*([0-9.]+)\s*kts", cell)
        if len(m) > 0:
            data["GST"] = m[0][1]

    # Air Temperature (ATMP)
    cell = td_value(html, "Air Temperature (ATMP):")
    if cell != None:
        m = re.match(r"\s*([0-9.]+)", cell)
        if len(m) > 0:
            data["ATMP"] = m[0][1]

    # Water Temperature (WTMP)
    cell = td_value(html, "Water Temperature (WTMP):")
    if cell != None:
        m = re.match(r"\s*([0-9.]+)", cell)
        if len(m) > 0:
            data["WTMP"] = m[0][1]

    # Atmospheric Pressure (PRES)
    cell = td_value(html, "Atmospheric Pressure (PRES):")
    if cell != None:
        m = re.match(r"\s*([0-9.]+)", cell)
        if len(m) > 0:
            data["PRES"] = m[0][1]

    # Pressure Tendency (PTDY) - store as raw cell, or parse numeric change if desired
    cell = td_value(html, "Pressure Tendency (PTDY):")
    if cell != None:
        # Capture signed numeric change
        m = re.match(r"\s*([+\-]?[0-9.]+)", cell)
        if len(m) > 0:
            data["PTDY"] = m[0][1]

    # Fallback to last_data for missing fields
    # If Wave Summary section was not found, mark data as stale and use last_data for swell fields
    if not wave_summary_found and len(last_data) != 0:
        if "stale" not in data:
            data["stale"] = 1
        else:
            data["stale"] = data["stale"] + 1
        debug_print("Wave Summary missing, using last data. Stale counter: " + str(data.get("stale", 0)))

        # Use last_data for swell-related fields when wave summary is missing
        for k in ["WVHT", "DPD", "MWD", "WIND_WVHT", "WIND_DPD", "WIND_MWD", "SWH", "APD", "STEEPNESS"]:
            if k not in data or data[k] == None:
                data[k] = last_data.get(k)

    # General fallback for all fields
    for k in ["WVHT", "DPD", "MWD", "WTMP", "ATMP", "WSPD", "GST", "WDIR", "WIND_WVHT", "WIND_DPD", "WIND_MWD", "SWH", "APD", "STEEPNESS"]:
        if k not in data or data[k] == None:
            data[k] = last_data.get(k)

    return data

def main(config):
    debug_print("##########################")
    data = dict()

    buoy_id = config.get("buoy_id", "")

    if buoy_id == "none" or buoy_id == "":  # if manual input is empty load from local selection
        local_selection = config.get("local_buoy_id", '{"display": "Station 51213 - South Lanai", "value": "51213"}')  # default is Waimea
        local_selection = json.decode(local_selection)
        if "value" in local_selection:
            buoy_id = local_selection["value"]
        else:
            buoy_id = "51213"

    buoy_name = config.get("buoy_name", "")
    h_unit_pref = config.get("h_units", "feet")
    t_unit_pref = config.get("t_units", "F")
    min_size = config.get("min_size", "0")

    # ensure we have a valid numer for min_size
    if len(re.findall("[0-9]+", min_size)) <= 0:
        min_size = "0"

    # CACHING FOR MAIN DATA OBJECT
    cache_key = "noaa_buoy_%s" % (buoy_id)
    cache_str = cache.get(cache_key)  #  not actually a json object yet, just a string
    if cache_str != None:  # and cache_str != "{}":
        debug_print("cache :" + cache_str)
        data = json.decode(cache_str)

    # CACHING FOR USECACHE : use this cache item to control wether to fetch new data or not, and update the main data cache
    usecache_key = "noaa_buoy_%s_usecache" % (buoy_id)
    usecache = cache.get(usecache_key)  #  not actually a json object yet, just a string
    if usecache and len(data) != 0:
        debug_print("using cache since usecache_key is set")
    else:
        debug_print("no usecache so fetching data")
        data = fetch_data(buoy_id, data)  # we pass in old data object so we can re-use data if missing from fetched data
        if data != None:
            if "stale" in data and data["stale"] > 2:
                debug_print("expring stale cache")

                # Custom cacheing determines if we have very stale data. Can't use http cache
                cache.set(cache_key, json.encode(data), ttl_seconds = 1)  # 1 sec expire almost immediately
            else:
                debug_print("Setting cache with : " + str(data))

                # Custom cacheing determines if we have very stale data. Can't use http cache
                cache.set(cache_key, json.encode(data), ttl_seconds = 1800)  # 30 minutes, should never actually expire because always getting re set

                # Custom cacheing determines if we have very stale data. Can't use http cache
                cache.set(cache_key + "_usecache", '{"usecache":"true"}', ttl_seconds = 600)  # 10 minutes

    if buoy_name == "" and "name" in data:
        debug_print("setting buoy_name to : " + data["name"])
        buoy_name = data["name"]

        # trim to max width of 14 chars or two words
        if len(buoy_name) > 14:
            buoy_name = buoy_name[:13]
            buoy_name = buoy_name.strip()

    # colors based on swell size
    color_small = "#00AAFF"  #blue
    color_medium = "#AAEEDD"  #cyanish
    color_big = "#00FF00"  #green
    color_huge = "#FF0000"  # red
    swell_color = color_medium

    # ERROR #################################################
    if "error" in data:  # if we have error key, then we got no good swell data, display the error
        #debug_print("buoy_id: " + str(buoy_id))
        return render.Root(
            child = render.Box(
                render.Column(
                    expanded = True,
                    cross_align = "center",
                    main_align = "space_evenly",
                    children = [
                        render.Text(
                            content = "Buoy:" + str(buoy_id),
                            font = "tb-8",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "Error",
                            font = "tb-8",
                            color = "#FF0000",
                        ),
                        render.Text(
                            content = data["error"],
                            color = "#FF0000",
                        ),
                    ],
                ),
            ),
        )

    elif config.bool("display_graph", False):
        # Check if wind swell mode is enabled
        use_wind_swell = config.bool("wind_swell", False)

        # Get graph duration in days (default 5, clamp to 1-40)
        graph_days_str = config.get("graph_days", "5")
        graph_days = 5
        if graph_days_str.isdigit():
            graph_days = int(graph_days_str)
            if graph_days < 1:
                graph_days = 1
            elif graph_days > 40:
                graph_days = 40

        # Fetch spectral data for graph
        spec_data = fetch_spec_data(buoy_id, use_wind_swell, graph_days)
        if spec_data and len(spec_data) >= 2:
            # Check size threshold against latest data point
            latest_swh = spec_data[-1]["swh"]  # Already in feet
            if h_unit_pref == "meters":
                latest_swh_display = latest_swh / 3.281
            else:
                latest_swh_display = latest_swh

            # Apply minimum size threshold
            if min_size != "0" and float(min_size) > 0:
                if latest_swh_display < float(min_size):
                    return []

            graph_result = render_swell_graph(spec_data, buoy_name if buoy_name else buoy_id, h_unit_pref, t_unit_pref, data, use_wind_swell)
            if graph_result:
                return graph_result

        # Fallback if no spec data available
        return render.Root(
            child = render.Box(
                render.Column(
                    cross_align = "center",
                    main_align = "center",
                    children = [
                        render.Text(
                            content = buoy_name if buoy_name else buoy_id,
                            font = "tb-8",
                            color = "#AAEEDD",
                        ),
                        render.Text(
                            content = "No Graph Data",
                            font = "tb-8",
                            color = "#FF0000",
                        ),
                    ],
                ),
            ),
        )

    elif (data.get("DPD") and config.bool("display_swell", True)):
        # If wind swell option is selected and wind swell data is present, display wind swell instead of ground swell
        show_wind_swell = config.bool("wind_swell", False)
        use_wind = show_wind_swell and data.get("WIND_WVHT") and data.get("WIND_DPD")
        if use_wind:
            height = data["WIND_WVHT"]
            period = data["WIND_DPD"]
            mwd = data.get("WIND_MWD", "--")
        else:
            height = data["WVHT"]
            period = data["DPD"]
            mwd = data.get("MWD", "--")
        if type(height) == type(""):
            if height.replace(".", "", 1).isdigit():
                height_f = float(height)
            else:
                height_f = 0.0
        else:
            height_f = float(height)
        if (height_f < 2):
            swell_color = color_small
        elif (height_f < 5):
            swell_color = color_medium
        elif (height_f < 12):
            swell_color = color_big
        elif (height_f >= 13):
            swell_color = color_huge

        unit_display = "f"
        if h_unit_pref == "meters":
            unit_display = "m"

            # Only convert if height is a number
            if type(height) == type("") and height.replace(".", "", 1).isdigit():
                height = float(height) / 3.281
                height = int(height * 10)
                height = height / 10.0
            elif type(height) != type(""):
                height = float(height) / 3.281
                height = int(height * 10)
                height = height / 10.0

        wtemp = ""
        if (data.get("WTMP") and config.bool("display_temps", True)):
            wt = data["WTMP"]
            if (t_unit_pref == "C"):
                wt = FtoC(wt)
            wt = int(float(wt) + 0.5)
            wtemp = " %s%s" % (str(wt), t_unit_pref)

        if not swell_over_threshold(min_size, h_unit_pref, data, use_wind):
            return []

        period_display = str(int(float(period) + 0.5)) if type(period) == type("") and period.replace(".", "", 1).isdigit() else str(period)
        return render.Root(
            child = render.Box(
                render.Column(
                    cross_align = "center",
                    main_align = "center",
                    children = [
                        render.Text(
                            content = buoy_name,
                            font = "tb-8",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "%s%s %ss" % (height, unit_display, period_display),
                            font = "6x13",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "%s°%s" % (mwd, wtemp),
                            color = "#FFAA00",
                        ),
                    ],
                ),
            ),
        )
        #WIND#################################################

    elif (data.get("WSPD") and data.get("WDIR") and config.bool("display_wind", True)):
        gust = ""
        avg = data["WSPD"]
        avg = str(int(float(avg) + 0.5))
        if "GST" in data:
            gust = data["GST"]
            gust = int(float(gust) + 0.5)
            gust = "g" + str(gust)

        atemp = ""
        if "ATMP" in data and config.get("display_temps") == "true":  # we have some room at the bottom for wtmp if desired
            at = data["ATMP"]
            if (t_unit_pref == "C"):
                at = FtoC(at)
            at = int(float(at) + 0.5)
            atemp = " %s%s" % (str(at), t_unit_pref)

        return render.Root(
            child = render.Box(
                render.Column(
                    cross_align = "center",
                    main_align = "center",
                    children = [
                        render.Text(
                            content = buoy_name,
                            font = "tb-8",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "%s%s kts" % (avg, gust),
                            font = "6x13",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "%s°%s" % (data["WDIR"], atemp),
                            color = "#FFAA00",
                        ),
                    ],
                ),
            ),
        )
        #TEMPS#################################################

    elif (config.bool("display_temps", False)):
        air = "--"
        if data.get("ATMP"):
            air = data["ATMP"]
            air = int(float(air) + 0.5)
        water = "--"
        if data.get("WTMP"):
            water = data["WTMP"]

        if (t_unit_pref == "C"):
            water = FtoC(water)
            air = FtoC(air)

        return render.Root(
            child = render.Box(
                render.Column(
                    cross_align = "center",
                    main_align = "center",
                    children = [
                        render.Text(
                            content = buoy_name,
                            font = "tb-8",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "Air:%s°%s" % (air, t_unit_pref),
                            font = "6x13",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "Water : %s°%s" % (water, t_unit_pref),
                            color = "#1166FF",
                        ),
                    ],
                ),
            ),
        )

    elif (config.bool("display_misc", False)):
        # MISC ################################################################
        # DEW with PRES with ATMP    or  TIDE with WTMP with SAL  or
        if "TIDE" in data:  # do some tide stuff, usually wtmp is included and somties SAL?
            water = "--"
            if data.get("WTMP"):
                water = data["WTMP"]

            if (t_unit_pref == "C"):
                water = FtoC(water)

            return render.Root(
                child = render.Box(
                    render.Column(
                        cross_align = "center",
                        main_align = "center",
                        children = [
                            render.Text(
                                content = buoy_name,
                                font = "tb-8",
                                color = swell_color,
                            ),
                            render.Text(
                                content = "Tide: %s %s" % (data["TIDE"], "ft"),
                                #font = "6x13",
                                color = swell_color,
                            ),
                            render.Text(
                                content = "Water : %s°%s" % (water, t_unit_pref),
                                color = "#1166FF",
                            ),
                        ],
                    ),
                ),
            )
        if data.get("DEW") or data.get("VIS"):
            lines = list()  # start with at least one blank
            if data.get("DEW"):
                dew = data["DEW"]
                if (t_unit_pref == "C"):
                    dew = FtoC(dew)

                lines.append("DEW: " + data["DEW"] + t_unit_pref)

            if data.get("VIS"):
                vis = data["VIS"]
                lines.append("VIS: " + vis)
                #debug_print("doing vis")

            if data.get("PRES"):
                lines.append("PRES: " + data["PRES"])

            if len(lines) < 2:
                lines.append("")
            return render.Root(
                child = render.Box(
                    render.Column(
                        cross_align = "center",
                        main_align = "center",
                        children = [
                            render.Text(
                                content = buoy_name,
                                font = "tb-8",
                                color = swell_color,
                            ),
                            render.Text(
                                content = lines[0],
                                #font = "6x13",
                                color = swell_color,
                            ),
                            render.Text(
                                content = lines[1],
                                color = "#1166FF",
                            ),
                        ],
                    ),
                ),
            )
            # Even if no misc data, check if we have swell data to display instead of "Nothing to Display"

        elif data.get("DPD"):
            # If wind swell option is selected and wind swell data is present, display wind swell instead of ground swell
            show_wind_swell = config.bool("wind_swell", False)
            use_wind = show_wind_swell and data.get("WIND_WVHT") and data.get("WIND_DPD")
            if use_wind:
                height = data["WIND_WVHT"]
                period = data["WIND_DPD"]
                mwd = data.get("WIND_MWD", "--")
            else:
                height = data["WVHT"]
                period = data["DPD"]
                mwd = data.get("MWD", "--")
            if type(height) == type(""):
                if height.replace(".", "", 1).isdigit():
                    height_f = float(height)
                else:
                    height_f = 0.0
            else:
                height_f = float(height)
            if (height_f < 2):
                swell_color = color_small
            elif (height_f < 5):
                swell_color = color_medium
            elif (height_f < 12):
                swell_color = color_big
            elif (height_f >= 13):
                swell_color = color_huge

            unit_display = "f"
            if h_unit_pref == "meters":
                unit_display = "m"

                # Only convert if height is a number
                if type(height) == type("") and height.replace(".", "", 1).isdigit():
                    height = float(height) / 3.281
                    height = int(height * 10)
                    height = height / 10.0
                elif type(height) != type(""):
                    height = float(height) / 3.281
                    height = int(height * 10)
                    height = height / 10.0

            wtemp = ""
            if (data.get("WTMP") and config.bool("display_temps", True)):
                wt = data["WTMP"]
                if (t_unit_pref == "C"):
                    wt = FtoC(wt)
                wt = int(float(wt) + 0.5)
                wtemp = " %s%s" % (str(wt), t_unit_pref)

            if not swell_over_threshold(min_size, h_unit_pref, data, use_wind):
                return []

            period_display = str(int(float(period) + 0.5)) if type(period) == type("") and period.replace(".", "", 1).isdigit() else str(period)

            # Add stale indicator if data is stale
            buoy_display_name = buoy_name
            if "stale" in data and data["stale"] > 0:
                buoy_display_name = buoy_name + "*"

            return render.Root(
                child = render.Box(
                    render.Column(
                        cross_align = "center",
                        main_align = "center",
                        children = [
                            render.Text(
                                content = buoy_display_name,
                                font = "tb-8",
                                color = swell_color,
                            ),
                            render.Text(
                                content = "%s%s %ss" % (height, unit_display, period_display),
                                font = "6x13",
                                color = swell_color,
                            ),
                            render.Text(
                                content = "%s°%s" % (mwd, wtemp),
                                color = "#FFAA00",
                            ),
                        ],
                    ),
                ),
            )
        else:
            return render.Root(
                child = render.Box(
                    render.Column(
                        cross_align = "center",
                        main_align = "center",
                        children = [
                            render.Text(
                                content = buoy_name,
                                font = "tb-8",
                                color = swell_color,
                            ),
                            render.Text(
                                content = "Nothing to",
                                font = "tb-8",
                                color = "#FF0000",
                            ),
                            render.Text(
                                content = "Display",
                                color = "#FF0000",
                            ),
                        ],
                    ),
                ),
            )
    else:
        # Check if we have swell data to display instead of "Nothing to Display"
        if data.get("DPD"):
            # If wind swell option is selected and wind swell data is present, display wind swell instead of ground swell
            show_wind_swell = config.bool("wind_swell", False)
            use_wind = show_wind_swell and data.get("WIND_WVHT") and data.get("WIND_DPD")
            if use_wind:
                height = data["WIND_WVHT"]
                period = data["WIND_DPD"]
                mwd = data.get("WIND_MWD", "--")
            else:
                height = data["WVHT"]
                period = data["DPD"]
                mwd = data.get("MWD", "--")
            if type(height) == type(""):
                if height.replace(".", "", 1).isdigit():
                    height_f = float(height)
                else:
                    height_f = 0.0
            else:
                height_f = float(height)
            if (height_f < 2):
                swell_color = color_small
            elif (height_f < 5):
                swell_color = color_medium
            elif (height_f < 12):
                swell_color = color_big
            elif (height_f >= 13):
                swell_color = color_huge

            unit_display = "f"
            if h_unit_pref == "meters":
                unit_display = "m"

                # Only convert if height is a number
                if type(height) == type("") and height.replace(".", "", 1).isdigit():
                    height = float(height) / 3.281
                    height = int(height * 10)
                    height = height / 10.0
                elif type(height) != type(""):
                    height = float(height) / 3.281
                    height = int(height * 10)
                    height = height / 10.0

            wtemp = ""
            if (data.get("WTMP") and config.bool("display_temps", True)):
                wt = data["WTMP"]
                if (t_unit_pref == "C"):
                    wt = FtoC(wt)
                wt = int(float(wt) + 0.5)
                wtemp = " %s%s" % (str(wt), t_unit_pref)

            if not swell_over_threshold(min_size, h_unit_pref, data, use_wind):
                return []

            period_display = str(int(float(period) + 0.5)) if type(period) == type("") and period.replace(".", "", 1).isdigit() else str(period)

            # Add stale indicator if data is stale
            buoy_display_name = buoy_name
            if "stale" in data and data["stale"] > 0:
                buoy_display_name = buoy_name + "*"

            return render.Root(
                child = render.Box(
                    render.Column(
                        cross_align = "center",
                        main_align = "center",
                        children = [
                            render.Text(
                                content = buoy_display_name,
                                font = "tb-8",
                                color = swell_color,
                            ),
                            render.Text(
                                content = "%s%s %ss" % (height, unit_display, period_display),
                                font = "6x13",
                                color = swell_color,
                            ),
                            render.Text(
                                content = "%s°%s" % (mwd, wtemp),
                                color = "#FFAA00",
                            ),
                        ],
                    ),
                ),
            )
        else:
            return render.Root(
                child = render.Box(
                    render.Column(
                        cross_align = "center",
                        main_align = "center",
                        children = [
                            render.Text(
                                content = buoy_name,
                                font = "tb-8",
                                color = swell_color,
                            ),
                            render.Text(
                                content = "Nothing to",
                                font = "tb-8",
                                color = "#FF0000",
                            ),
                            render.Text(
                                content = "Display",
                                color = "#FF0000",
                            ),
                        ],
                    ),
                ),
            )

def get_stations(location):
    station_options = list()

    #https://www.ndbc.noaa.gov/rss/ndbc_obs_search.php?lat=20.8911&lon=-156.5047
    loc = json.decode(location)  # See example location above.
    url = "https://www.ndbc.noaa.gov/rss/ndbc_obs_search.php?lat=%s&lon=%s" % (loc["lat"], loc["lng"])

    #debug_print(url)
    resp = http.get(url)
    if resp.status_code != 200:
        return []
    else:
        # channel/item/title
        # parse Station KLIH1 - 1615680 - KAHULUI, KAHULUI HARBOR, HI

        rss_titles = xpath.loads(resp.body()).query_all("/rss/channel/item/title")

        #debug_print(rss_titles)
        for rss_title in rss_titles:
            matches = re.match(r"Station\ (\w+) \-\s+(.+)$", rss_title)

            #debug_print(matches)
            if len(matches) > 0:
                #debug_print(matches[0][1] + " : " ,matches[0][0] )#+ matches[2])
                station_options.append(
                    schema.Option(
                        display = matches[0][0],
                        value = matches[0][1],
                    ),
                )
    return station_options

def get_schema():
    h_unit_options = [
        schema.Option(display = "feet", value = "feet"),
        schema.Option(display = "meters", value = "meters"),
    ]
    t_unit_options = [
        schema.Option(display = "C", value = "C"),
        schema.Option(display = "F", value = "F"),
    ]

    #    stations_list = get_stations(default_location)
    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "local_buoy_id",
                name = "Local Buoy",
                icon = "monument",
                desc = "Location Based Buoys",
                handler = get_stations,
            ),
            schema.Text(
                id = "buoy_id",
                name = "Buoy ID - optional",
                icon = "monument",
                desc = "",
            ),
            schema.Text(
                id = "buoy_name",
                name = "Custom Display Name",
                icon = "user",
                desc = "Leave blank to use NOAA defined name",
                default = "",
            ),
            schema.Toggle(
                id = "display_swell",
                name = "Display Swell",
                desc = "if available",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "wind_swell",
                name = "Display Wind Swell",
                desc = "instead of ground swell.",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "display_graph",
                name = "Display Swell Graph",
                desc = "Show swell height graph with period coloring (blue=short, red=long)",
                icon = "chartLine",
                default = False,
            ),
            schema.Text(
                id = "graph_days",
                name = "Graph Duration (days)",
                desc = "Number of days to display (1-40)",
                icon = "calendar",
                default = "5",
            ),
            schema.Toggle(
                id = "display_wind",
                name = "Display Wind",
                desc = "if available",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "display_temps",
                name = "Display Temperatures",
                icon = "gear",
                desc = "if available",
                default = True,
            ),
            schema.Toggle(
                id = "display_misc",
                name = "Display Misc.",
                desc = "if available",
                icon = "gear",
                default = True,
            ),
            schema.Dropdown(
                id = "h_units",
                name = "Height Units",
                icon = "quoteRight",
                desc = "Wave height units preference",
                options = h_unit_options,
                default = "feet",
            ),
            schema.Dropdown(
                id = "t_units",
                name = "Temperature Units",
                icon = "quoteRight",
                desc = "C or F",
                options = t_unit_options,
                default = "F",
            ),
            schema.Text(
                id = "min_size",
                name = "Minimum Swell Size",
                icon = "water",
                desc = "Only display if swell is above minimum size",
                default = "",
            ),
        ],
    )
