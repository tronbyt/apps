"""
Applet: MeteoSwiss
Summary: MeteoSwiss Weather Forecast
Description: Weather forecasts from MeteoSwiss for Swiss locations.
Authors: LukiLeu

"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("i18n.star", "tr")

# Load weather symbol images
load("images/001.png", IMG_001 = "file")
load("images/002.png", IMG_002 = "file")
load("images/003.png", IMG_003 = "file")
load("images/004.png", IMG_004 = "file")
load("images/005.png", IMG_005 = "file")
load("images/006.png", IMG_006 = "file")
load("images/007.png", IMG_007 = "file")
load("images/008.png", IMG_008 = "file")
load("images/009.png", IMG_009 = "file")
load("images/010.png", IMG_010 = "file")
load("images/011.png", IMG_011 = "file")
load("images/012.png", IMG_012 = "file")
load("images/013.png", IMG_013 = "file")
load("images/014.png", IMG_014 = "file")
load("images/015.png", IMG_015 = "file")
load("images/016.png", IMG_016 = "file")
load("images/017.png", IMG_017 = "file")
load("images/018.png", IMG_018 = "file")
load("images/019.png", IMG_019 = "file")
load("images/020.png", IMG_020 = "file")
load("images/021.png", IMG_021 = "file")
load("images/022.png", IMG_022 = "file")
load("images/023.png", IMG_023 = "file")
load("images/024.png", IMG_024 = "file")
load("images/025.png", IMG_025 = "file")
load("images/026.png", IMG_026 = "file")
load("images/027.png", IMG_027 = "file")
load("images/028.png", IMG_028 = "file")
load("images/029.png", IMG_029 = "file")
load("images/030.png", IMG_030 = "file")
load("images/031.png", IMG_031 = "file")
load("images/032.png", IMG_032 = "file")
load("images/033.png", IMG_033 = "file")
load("images/034.png", IMG_034 = "file")
load("images/035.png", IMG_035 = "file")
load("images/036.png", IMG_036 = "file")
load("images/037.png", IMG_037 = "file")
load("images/038.png", IMG_038 = "file")
load("images/039.png", IMG_039 = "file")
load("images/040.png", IMG_040 = "file")
load("images/041.png", IMG_041 = "file")
load("images/042.png", IMG_042 = "file")
load("images/101.png", IMG_101 = "file")
load("images/102.png", IMG_102 = "file")
load("images/103.png", IMG_103 = "file")
load("images/104.png", IMG_104 = "file")
load("images/105.png", IMG_105 = "file")
load("images/106.png", IMG_106 = "file")
load("images/107.png", IMG_107 = "file")
load("images/108.png", IMG_108 = "file")
load("images/109.png", IMG_109 = "file")
load("images/110.png", IMG_110 = "file")
load("images/111.png", IMG_111 = "file")
load("images/112.png", IMG_112 = "file")
load("images/113.png", IMG_113 = "file")
load("images/114.png", IMG_114 = "file")
load("images/115.png", IMG_115 = "file")
load("images/116.png", IMG_116 = "file")
load("images/117.png", IMG_117 = "file")
load("images/118.png", IMG_118 = "file")
load("images/119.png", IMG_119 = "file")
load("images/120.png", IMG_120 = "file")
load("images/121.png", IMG_121 = "file")
load("images/122.png", IMG_122 = "file")
load("images/123.png", IMG_123 = "file")
load("images/124.png", IMG_124 = "file")
load("images/125.png", IMG_125 = "file")
load("images/126.png", IMG_126 = "file")
load("images/127.png", IMG_127 = "file")
load("images/128.png", IMG_128 = "file")
load("images/129.png", IMG_129 = "file")
load("images/130.png", IMG_130 = "file")
load("images/131.png", IMG_131 = "file")
load("images/132.png", IMG_132 = "file")
load("images/133.png", IMG_133 = "file")
load("images/134.png", IMG_134 = "file")
load("images/135.png", IMG_135 = "file")
load("images/136.png", IMG_136 = "file")
load("images/137.png", IMG_137 = "file")
load("images/138.png", IMG_138 = "file")
load("images/139.png", IMG_139 = "file")
load("images/140.png", IMG_140 = "file")
load("images/141.png", IMG_141 = "file")
load("images/142.png", IMG_142 = "file")
load("images/error_icon.png", IMG_ERROR = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Weather symbol images mapping
WEATHER_IMAGES = {
    1: IMG_001,
    2: IMG_002,
    3: IMG_003,
    4: IMG_004,
    5: IMG_005,
    6: IMG_006,
    7: IMG_007,
    8: IMG_008,
    9: IMG_009,
    10: IMG_010,
    11: IMG_011,
    12: IMG_012,
    13: IMG_013,
    14: IMG_014,
    15: IMG_015,
    16: IMG_016,
    17: IMG_017,
    18: IMG_018,
    19: IMG_019,
    20: IMG_020,
    21: IMG_021,
    22: IMG_022,
    23: IMG_023,
    24: IMG_024,
    25: IMG_025,
    26: IMG_026,
    27: IMG_027,
    28: IMG_028,
    29: IMG_029,
    30: IMG_030,
    31: IMG_031,
    32: IMG_032,
    33: IMG_033,
    34: IMG_034,
    35: IMG_035,
    36: IMG_036,
    37: IMG_037,
    38: IMG_038,
    39: IMG_039,
    40: IMG_040,
    41: IMG_041,
    42: IMG_042,
    101: IMG_101,
    102: IMG_102,
    103: IMG_103,
    104: IMG_104,
    105: IMG_105,
    106: IMG_106,
    107: IMG_107,
    108: IMG_108,
    109: IMG_109,
    110: IMG_110,
    111: IMG_111,
    112: IMG_112,
    113: IMG_113,
    114: IMG_114,
    115: IMG_115,
    116: IMG_116,
    117: IMG_117,
    118: IMG_118,
    119: IMG_119,
    120: IMG_120,
    121: IMG_121,
    122: IMG_122,
    123: IMG_123,
    124: IMG_124,
    125: IMG_125,
    126: IMG_126,
    127: IMG_127,
    128: IMG_128,
    129: IMG_129,
    130: IMG_130,
    131: IMG_131,
    132: IMG_132,
    133: IMG_133,
    134: IMG_134,
    135: IMG_135,
    136: IMG_136,
    137: IMG_137,
    138: IMG_138,
    139: IMG_139,
    140: IMG_140,
    141: IMG_141,
    142: IMG_142,
}

# Default station (first alphabetically sorted station from MeteoSwiss)
DEFAULT_STATION = """
{
    "value": "0",
    "text": "Invalid Station"
}
"""

# CSV delimiter used by MeteoSwiss data files
CSV_DELIMITER = ";"

def main(config):
    """Fetch and display MeteoSwiss weather forecast.

    Args:
        config: Configuration object.

    Returns:
        Rendered display widget.
    """

    # Get configuration
    station_config = config.get("station", DEFAULT_STATION)
    station = json.decode(station_config)
    forecast_type = config.get("forecast_type", "daily")

    # Check for valid station
    if station.get("value", "0") == "0":
        return error_display("No Station selected")

    # Fetch and process data based on forecast type
    if forecast_type == "3hour":
        # Fetch 3-hour forecast data
        weather_data = fetch_3hour_data()
        if not weather_data:
            return error_display("3hr API Error")

        # Process 3-hour forecast
        forecast_data = process_3hour_forecast(weather_data, station)
        if not forecast_data:
            return error_display("3hr No Forecasts")
    else:
        # Fetch daily weather data
        weather_data = fetch_weather_data()
        if not weather_data:
            return error_display("Weather API Error")

        # Process daily forecast
        forecast_data = process_forecast(weather_data, station)

    # Render the display
    return render_weather(forecast_data, forecast_type)

def get_stations_list():
    """Get MeteoSwiss stations list.

    Returns:
        List of station dictionaries sorted alphabetically. Each entry contains
        "point_id", "point_name", "point_type_id", and "postal_code".
    """
    cache_key = "meteoschweiz_stations_list"
    cached = cache.get(cache_key)
    if cached:
        return json.decode(cached)

    # Fetch stations CSV from MeteoSwiss OGD
    url = "https://data.geo.admin.ch/ch.meteoschweiz.ogd-local-forecasting/ogd-local-forcasting_meta_point.csv"

    # Cache the raw CSV response for 24 hours to avoid frequent rebuilds
    resp = http.get(url, ttl_seconds = 86400)
    if resp.status_code != 200:
        return []

    # Parse CSV and return stations
    lines = resp.body().split("\n")
    stations = []

    # Skip header and parse stations
    # CSV format: point_id;point_type_id;station_abbr;postal_code;point_name;...
    for line in lines[1:]:
        if not line.strip():
            continue

        # Parse CSV line (semicolon-delimited)
        parts = line.split(CSV_DELIMITER)

        if len(parts) >= 5:
            point_id = parts[0]
            point_type_id = parts[1]
            postal_code = parts[3]
            point_name = parts[4]
            point_name = point_name.replace("�", "").replace("?", "")

            # Only use stations of type 2 or 3
            if point_type_id == "2" or point_type_id == "3":
                # For type 2, append postal code to name
                display_name = point_name
                if point_type_id == "2" and postal_code:
                    display_name = "%s / %s" % (point_name, postal_code)

                if point_id and display_name:
                    stations.append({
                        "point_id": point_id,
                        "point_name": display_name,
                        "point_type_id": point_type_id,
                        "postal_code": postal_code,
                    })

    # Sort stations alphabetically by point_name
    stations = sorted(stations, key = lambda s: s["point_name"])

    # Store parsed list for 24 hours in Pixlet cache
    cache.set(cache_key, json.encode(stations), ttl_seconds = 86400)

    return stations

def fetch_weather_data():
    """Fetch weather data from MeteoSwiss STAC API.

    Returns:
        Dictionary with temperature and symbol data for all stations, or None on error.
    """

    # Check cache first
    cache_key = "meteoschweiz_weather_all"
    cached = cache.get(cache_key)

    if cached:
        cached_data = json.decode(cached)
        cached_date = cached_data.get("date", "")

        # Get current date in YYYYMMDD format
        current_date = time.now().in_location("Europe/Zurich").format("20060102")

        # Return cached data if date matches
        if cached_date == current_date:
            return cached_data

    # First, get the list of available data
    stac_url = "https://data.geo.admin.ch/api/stac/v1/collections/ch.meteoschweiz.ogd-local-forecasting/items"

    resp = http.get(stac_url, ttl_seconds = 3600)
    if resp.status_code != 200:
        return None

    data = json.decode(resp.body())
    items = data.get("features", [])

    if not items:
        return None

    # Get the most recent item
    latest_item = items[0]
    date_str = latest_item.get("properties", {}).get("datetime", "")

    # Extract date in format YYYYMMDD
    if "T" in date_str:
        date_part = date_str.split("T")[0].replace("-", "")
    else:
        date_part = date_str.replace("-", "")

    # Construct base URL for data files
    base_url = "https://data.geo.admin.ch/ch.meteoschweiz.ogd-local-forecasting/{}-ch/".format(date_part)

    # Fetch temperature and weather symbol data for all stations
    tre_min_url = base_url + "vnut12.lssw.{}0000.tre200pn.csv".format(date_part)
    tre_max_url = base_url + "vnut12.lssw.{}0000.tre200px.csv".format(date_part)
    symbol_url = base_url + "vnut12.lssw.{}0000.jp2000d0.csv".format(date_part)

    tre_min_data = fetch_csv_data(tre_min_url)
    tre_max_data = fetch_csv_data(tre_max_url)
    symbols_data = fetch_csv_data(symbol_url)

    # Ensure we have data and extract values
    if not tre_min_data or not tre_max_data or not symbols_data:
        return None

    weather_data = {
        "tre_min": tre_min_data.get("values", {}),
        "tre_max": tre_max_data.get("values", {}),
        "symbols": symbols_data.get("values", {}),
        "date": date_part,
    }

    # Cache for 6 hours (21600 seconds)
    cache.set(cache_key, json.encode(weather_data), ttl_seconds = 21600)

    return weather_data

def fetch_3hour_data():
    """Fetch 3-hour forecast data from MeteoSwiss STAC API.

    Returns:
        Dictionary with temperature, symbol, and precipitation data for all stations, or None on error.
    """

    # Check cache first
    cache_key = "meteoschweiz_3hour_all"
    cached = cache.get(cache_key)

    if cached:
        cached_data = json.decode(cached)
        cached_date = cached_data.get("date", "")

        # Get current date in YYYYMMDD format
        current_date = time.now().in_location("Europe/Zurich").format("20060102")

        # Return cached data if date matches
        if cached_date == current_date:
            return cached_data

    # First, get the list of available data
    stac_url = "https://data.geo.admin.ch/api/stac/v1/collections/ch.meteoschweiz.ogd-local-forecasting/items"

    resp = http.get(stac_url, ttl_seconds = 3600)
    if resp.status_code != 200:
        return None

    data = json.decode(resp.body())
    items = data.get("features", [])

    if not items:
        return None

    # Get the most recent item
    latest_item = items[0]
    date_str = latest_item.get("properties", {}).get("datetime", "")

    # Extract date in format YYYYMMDD
    if "T" in date_str:
        date_part = date_str.split("T")[0].replace("-", "")
    else:
        date_part = date_str.replace("-", "")

    # Construct base URL for data files
    base_url = "https://data.geo.admin.ch/ch.meteoschweiz.ogd-local-forecasting/{}-ch/".format(date_part)

    # Fetch 3-hour data: temperature, weather symbol, and precipitation
    tre_url = base_url + "vnut12.lssw.{}0000.tre200h0.csv".format(date_part)
    symbol_url = base_url + "vnut12.lssw.{}0000.jww003i0.csv".format(date_part)
    precip_url = base_url + "vnut12.lssw.{}0000.rre003i0.csv".format(date_part)

    temperature_data = fetch_csv_data(tre_url)
    symbols_data = fetch_csv_data(symbol_url)
    precipitation_data = fetch_csv_data(precip_url)

    # Ensure we have data with proper structure
    if not temperature_data or not symbols_data or not precipitation_data:
        return None

    weather_data = {
        "temperature": temperature_data.get("values", {}),
        "symbols": symbols_data.get("values", {}),
        "precipitation": precipitation_data.get("values", {}),
        "timestamps": temperature_data.get("timestamps", []),
        "date": date_part,
    }

    # Cache for 1 hour (3600 seconds) since 3-hour data updates more frequently
    cache.set(cache_key, json.encode(weather_data), ttl_seconds = 3600)

    return weather_data

def fetch_csv_data(url):
    """Fetch large CSV data in chunks to avoid caching issues.

    Downloads the file in 1MB chunks using HTTP Range requests, processing each
    chunk immediately to extract station data without loading the entire file.

    Args:
        url: URL to CSV file.

    Returns:
        Dictionary with two keys:
        - 'values': Dict mapping point_id to list of values
        - 'timestamps': List of timestamp strings from the CSV (YYYYMMDDHHMM format)
    """

    CHUNK_SIZE = 1024 * 1024  # 1MB chunks
    MAX_CHUNKS = 40  # Support files up to ~40MB
    station_data = {}
    timestamps = []
    leftover = ""

    # Download and process in chunks
    for chunk_num in range(MAX_CHUNKS):
        chunk_start = chunk_num * CHUNK_SIZE
        chunk_end = chunk_start + CHUNK_SIZE - 1

        # Request this chunk with Range header
        headers = {"Range": "bytes={}-{}".format(chunk_start, chunk_end)}
        resp = http.get(url, headers = headers, ttl_seconds = 1)

        # Check response - 206 is Partial Content
        if resp.status_code == 206:
            # Partial content received - process it
            chunk_data = resp.body()

            # Combine with leftover from previous chunk
            data = leftover + chunk_data

            # Split into lines
            lines = data.split("\n")

            # Save the last incomplete line for next chunk
            leftover = lines[-1]
            lines = lines[:-1]

            # On first chunk, extract and skip header
            if chunk_num == 0 and len(lines) > 0:
                # Skip header line
                lines = lines[1:]

            # Process lines in this chunk
            for line in lines:
                if not line.strip():
                    continue

                parts = line.split(CSV_DELIMITER)
                if len(parts) >= 4:
                    point_id = parts[0]
                    timestamp = parts[2]  # Date column in YYYYMMDDHHMM format
                    val = parts[3]

                    if point_id:
                        # Track unique timestamps across all stations
                        if timestamp and timestamp not in timestamps:
                            timestamps.append(timestamp)

                        # Store data for this station
                        if point_id not in station_data:
                            station_data[point_id] = []
                        station_data[point_id].append(float(val) if val and val != "-" else 0)

            # Check if we got less than requested (end of file)
            if len(chunk_data) < CHUNK_SIZE:
                # Process any remaining leftover
                if leftover.strip():
                    parts = leftover.split(CSV_DELIMITER)
                    if len(parts) >= 4:
                        point_id = parts[0]
                        timestamp = parts[2]
                        val = parts[3]
                        if point_id:
                            if timestamp and timestamp not in timestamps:
                                timestamps.append(timestamp)
                            if point_id not in station_data:
                                station_data[point_id] = []
                            station_data[point_id].append(float(val) if val and val != "-" else 0)
                break
        elif resp.status_code == 416:
            # Range not satisfiable - we've read past the end
            break
        else:
            # Some other error
            if chunk_num == 0:
                return {}
            else:
                # We got some data, return what we have
                break

    # Sort timestamps to ensure chronological order
    timestamps = sorted(timestamps)
    return {"values": station_data, "timestamps": timestamps}

def process_forecast(weather_data, station):
    """Process MeteoSwiss forecast data into daily forecasts.

    Args:
        weather_data: Dictionary with temperature and symbol data for all stations.
        station: Station dictionary with metadata.

    Returns:
        List of daily forecast dictionaries.
    """
    daily_data = []

    # Get station point_id
    station_point_id = station.get("value", "")
    if not station_point_id:
        return daily_data

    # Extract data for all stations
    tre_min_all = weather_data.get("tre_min", {})
    tre_max_all = weather_data.get("tre_max", {})
    symbols_all = weather_data.get("symbols", {})

    # Filter for the specific station
    tre_min = tre_min_all.get(station_point_id, [])
    tre_max = tre_max_all.get(station_point_id, [])
    symbols = symbols_all.get(station_point_id, [])

    # Process up to 3 days
    for i in range(min(3, len(tre_max))):
        # Calculate day time using timestamp arithmetic
        current_timestamp = time.now().unix
        day_time = time.from_timestamp(current_timestamp + 86400 * i).in_location("Europe/Zurich")

        symbol_code = int(symbols[i]) if i < len(symbols) and symbols[i] else 1

        daily_data.append({
            "high": tre_max[i] if i < len(tre_max) else 0,
            "low": tre_min[i] if i < len(tre_min) else 0,
            "symbol": symbol_code,
            "date": day_time,
        })

    return daily_data

def process_3hour_forecast(weather_data, station):
    """Process MeteoSwiss 3-hour forecast data.

    Args:
        weather_data: Dictionary with temperature, symbol, and precipitation data for all stations.
        station: Station dictionary with metadata.

    Returns:
        List of 3-hour forecast dictionaries (3 intervals).
    """
    forecast_data = []

    # Get station point_id
    station_point_id = station.get("value", "")
    if not station_point_id:
        return forecast_data

    # Extract data for all stations
    temperature_all = weather_data.get("temperature", {})
    symbols_all = weather_data.get("symbols", {})
    precipitation_all = weather_data.get("precipitation", {})

    # Filter for the specific station
    temperatures = temperature_all.get(station_point_id, [])
    symbols = symbols_all.get(station_point_id, [])
    precipitation = precipitation_all.get(station_point_id, [])
    timestamps = weather_data.get("timestamps", [])

    # Filter timestamps to 3-hour intervals (00, 03, 06, 09, 12, 15, 18, 21)
    # The data is hourly, so we need to select only 3-hour intervals
    three_hour_indices = []
    for idx, ts in enumerate(timestamps):
        if len(ts) >= 12:
            hour = int(ts[8:10])

            # Include timestamps at 3-hour intervals
            if hour % 3 == 0:
                three_hour_indices.append(idx)

    # Show next 3 forecast intervals from the 3-hour data
    num_intervals = min(3, len(three_hour_indices))
    for i in range(num_intervals):
        idx = three_hour_indices[i]

        # Parse timestamp from CSV (format: YYYYMMDDHHMM)
        timestamp_str = timestamps[idx]
        if len(timestamp_str) >= 12:
            year = int(timestamp_str[0:4])
            month = int(timestamp_str[4:6])
            day = int(timestamp_str[6:8])
            hour = int(timestamp_str[8:10])
            minute = int(timestamp_str[10:12])

            # Create time object from CSV timestamp
            forecast_time = time.time(year = year, month = month, day = day, hour = hour, minute = minute, location = "Europe/Zurich")

            symbol_code = int(symbols[idx]) if idx < len(symbols) else 1
            temp = temperatures[idx] if idx < len(temperatures) else 0
            precip = precipitation[idx] if idx < len(precipitation) else 0

            forecast_data.append({
                "temperature": temp,
                "symbol": symbol_code,
                "precipitation": precip,
                "time": forecast_time,
                "is_3hour": True,
            })

    return forecast_data

def render_weather(daily_data, forecast_type = "daily"):
    """Render weather forecast display (3-day or 3-hour view).

    Args:
        daily_data: List of forecast dictionaries (daily or 3-hour).
        forecast_type: Type of forecast ("daily" or "3hour").

    Returns:
        Rendered display root widget.
    """
    if not daily_data:
        return error_display("No Data")

    DIVIDER_WIDTH = 1
    HEIGHT = 32

    columns = []
    is_3hour = forecast_type == "3hour"

    for i, day in enumerate(daily_data):
        # Get weather icon using symbol code directly
        symbol_code = day.get("symbol", 1)
        weather_image = WEATHER_IMAGES.get(symbol_code, IMG_ERROR)
        weather_icon_src = weather_image.readall()

        # Build column children based on forecast type
        if is_3hour:
            # 3-hour forecast: show time and temperature
            time_str = day["time"].format("15:04")
            temp = int(day.get("temperature", 0))
            precip = day.get("precipitation", 0)

            # Format precipitation as percentage - always show it
            precip_str = "%d%%" % int(precip * 100)

            children = [
                # Weather icon
                render.Image(
                    src = weather_icon_src,
                    width = 12,
                    height = 12,
                ),
                # Time
                render.Text(
                    time_str,
                    font = "CG-pixel-3x5-mono",
                    color = "#FF0",
                ),
                # Temperature with custom degree symbol
                render.Row(
                    children = [
                        render.Text(
                            "%d" % temp,
                            font = "CG-pixel-3x5-mono",
                            color = "#FFF",
                        ),
                        render.Padding(
                            pad = (0, 0, 0, 2),
                            child = render.Circle(
                                diameter = 2,
                                color = "#FFF",
                            ),
                        ),
                    ],
                ),
                # Precipitation percentage
                render.Text(
                    precip_str,
                    font = "CG-pixel-3x5-mono",
                    color = "#08F",
                ),
            ]
        else:
            # Daily forecast: show day abbreviation and high/low temps
            day_abbr = day["date"].format("Mon")[:3].upper()
            day_abbr = tr(day_abbr)

            children = [
                # Weather icon
                render.Image(
                    src = weather_icon_src,
                    width = 12,
                    height = 12,
                ),
                # Day abbreviation
                render.Text(
                    day_abbr,
                    font = "CG-pixel-3x5-mono",
                    color = "#FF0",
                ),
                render.Row(
                    children = [
                        # High temp
                        render.Text(
                            "%d" % int(day["high"]),
                            font = "CG-pixel-3x5-mono",
                            color = "#FFF",
                        ),
                        render.Padding(
                            pad = (0, 0, 0, 2),
                            child = render.Circle(
                                diameter = 2,
                                color = "#FFF",
                            ),
                        ),
                    ],
                ),
                # Low temp
                render.Row(
                    children = [
                        render.Text(
                            "%d" % int(day["low"]),
                            font = "CG-pixel-3x5-mono",
                            color = "#888",
                        ),
                        render.Padding(
                            pad = (0, 0, 0, 2),
                            child = render.Circle(
                                diameter = 2,
                                color = "#FFF",
                            ),
                        ),
                    ],
                ),
            ]

        # Create column
        day_column = render.Column(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = children,
        )

        columns.append(day_column)

        # Add divider if not last column
        if i < 2:
            columns.append(
                render.Box(
                    width = DIVIDER_WIDTH,
                    height = HEIGHT,
                    color = "#444",
                ),
            )

    # Create display
    return render.Root(
        child = render.Stack(
            children = [
                render.Box(
                    width = 64,
                    height = HEIGHT,
                    color = "#000",
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    children = columns,
                ),
            ],
        ),
    )

def error_display(message):
    """Display error message on screen.

    Args:
        message: Error message to display.

    Returns:
        Rendered error display widget.
    """
    return render.Root(
        child = render.Row(
            children = [
                render.Box(
                    width = 20,
                    height = 32,
                    color = "#000",
                    child = render.Image(
                        src = IMG_ERROR.readall(),
                        width = 16,
                        height = 16,
                    ),
                ),
                render.Box(
                    padding = 0,
                    width = 44,
                    height = 32,
                    child =
                        render.WrappedText(
                            content = message,
                            color = "#FFF",
                            linespacing = 1,
                            font = "CG-pixel-4x5-mono",
                        ),
                ),
            ],
        ),
    )

def search_station(pattern):
    """Search stations matching a pattern.

    Args:
        pattern: Case-insensitive substring to match against station display name.

    Returns:
        List of `schema.Option` entries for the typeahead handler. If none are
        found, returns a single option indicating no stations were found.
    """
    stations_list = get_stations_list()
    pattern_l = pattern.lower()

    options = []
    for s in stations_list:
        name = s.get("point_name", "")
        pid = s.get("point_id", "")
        if not name or not pid:
            continue
        if pattern_l in name.lower():
            options.append(schema.Option(
                display = "%s (%s)" % (name, pid),
                value = pid,
            ))

    if not options:
        return [
            schema.Option(
                display = "No stations found",
                value = "No stations found",
            ),
        ]

    return options

def get_schema():
    """Define the app configuration schema.

    Returns:
        Schema object with configuration fields.
    """
    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "station",
                name = "Location",
                desc = "MeteoSwiss location for which to display the weather forecast.",
                icon = "locationDot",
                handler = search_station,
            ),
            schema.Dropdown(
                id = "forecast_type",
                name = "Forecast Type",
                desc = "Choose between daily forecast (3 days) or 3-hour intervals (9 hours)",
                icon = "clock",
                default = "daily",
                options = [
                    schema.Option(
                        display = "Daily (3 days)",
                        value = "daily",
                    ),
                    schema.Option(
                        display = "3-Hour Intervals (9 hours)",
                        value = "3hour",
                    ),
                ],
            ),
        ],
    )
