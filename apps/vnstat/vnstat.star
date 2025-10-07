"""
Applet: VNStat Network Monitor
Summary: Network usage statistics
Description: Display network usage statistics from VNStat via OPNsense API including total and monthly data transfer amounts.
Author: StarrLord
"""

load("animation.star", "animation")
load("http.star", "http")
load("math.star", "math")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Constants
DEFAULT_CACHE_TTL = 300  # 5 minutes
DEFAULT_BASE_URL = "http://192.168.1.1"

# Colors
COLOR_PRIMARY = "#00FF00"
COLOR_SECONDARY = "#FFFF00"
COLOR_TEXT = "#FFFFFF"
COLOR_ERROR = "#FF0000"
COLOR_BACKGROUND = "#000000"
COLOR_HEADER = "#333333"

# Fonts
FONT_SMALL = "tom-thumb"
FONT_MEDIUM = "tb-8"
FONT_LARGE = "6x13"

def main(config):
    """Main function that renders the Tidbyt display"""

    # Get configuration - handle empty strings properly
    base_url = config.get("baseUrl", DEFAULT_BASE_URL)
    api_key = config.get("apiKey", "")
    api_secret = config.get("apiSecret", "")
    cache_ttl = int(config.get("cacheTtl") or DEFAULT_CACHE_TTL)

    # Clean up configuration values (strip whitespace, treat empty as None)
    if base_url:
        base_url = base_url.strip()
        if not base_url:
            base_url = None
    if api_key:
        api_key = api_key.strip()
        if not api_key:
            api_key = None
    if api_secret:
        api_secret = api_secret.strip()
        if not api_secret:
            api_secret = None

    # Debug: Show what we actually received
    debug_info = "URL:{} KEY:{} SECRET:{}".format(
        "OK" if base_url else "MISSING",
        "OK" if api_key else "MISSING",
        "OK" if api_secret else "MISSING"
    )

    # Check for required configuration with debug info
    missing_fields = []
    if not base_url:
        missing_fields.append("Base URL")
    if not api_key:
        missing_fields.append("API Key")
    if not api_secret:
        missing_fields.append("API Secret")
    
    if missing_fields:
        return error_display("Missing: {} | {}".format(", ".join(missing_fields), debug_info))
    
    # Fetch real data
    data, error = fetch_vnstat_data(base_url, api_key, api_secret, cache_ttl)
    if error:
        return error_display("API: {} | URL: {}".format(error, base_url))
    if not data or (data["total_received"] == 0 and data["total_transmitted"] == 0):
        return error_display("No Data Available")
    
    status_message = "LIVE"

    # Create sliding animation like weather.star
    return render.Root(
        max_age = cache_ttl,
        delay = 100,  # 100ms per frame
        child = render.Animation(
            children = create_simple_sliding_frames(data, status_message),
        ),
    )

def create_simple_sliding_frames(data, status_message):
    """Create simple sliding animation frames"""
    frames = []
    
    # Create the 4 metric displays
    displays = [
        create_metric_display("Today RX", format_bytes(data["total_received"]), COLOR_PRIMARY, status_message),
        create_metric_display("Today TX", format_bytes(data["total_transmitted"]), COLOR_SECONDARY, status_message),
        create_metric_display("Month RX", format_bytes(data["monthly_received"]), COLOR_PRIMARY, status_message),
        create_metric_display("Month TX", format_bytes(data["monthly_transmitted"]), COLOR_SECONDARY, status_message),
    ]
    
    static_frames = 30  # 3 seconds static
    slide_frames = 8    # 0.8 seconds sliding
    
    for i in range(len(displays)):
        current_display = displays[i]
        next_display = displays[(i + 1) % len(displays)]
        
        # Static frames showing current display
        for _ in range(static_frames):
            frames.append(current_display)
        
        # Sliding frames to next display
        for frame in range(slide_frames):
            slide_progress = (frame + 1) / slide_frames
            slide_distance = int(64 * slide_progress)
            
            frames.append(render.Stack(
                children = [
                    # Current display sliding out left
                    render.Padding(
                        pad = (-slide_distance, 0, 0, 0),
                        child = current_display,
                    ),
                    # Next display sliding in from right
                    render.Padding(
                        pad = (64 - slide_distance, 0, 0, 0),
                        child = next_display,
                    ),
                ],
            ))
    
    return frames

def create_slide_frame(current_metric, next_metric, slide_progress, status_message):
    """Create a single frame of the sliding animation"""
    slide_distance = int(64 * slide_progress)  # How far to slide (0 to 64 pixels)
    
    return render.Stack(
        children = [
            # Current metric sliding out to the left
            render.Padding(
                pad = (-slide_distance, 0, 0, 0),
                child = create_metric_display(
                    current_metric["label"],
                    current_metric["value"],
                    current_metric["color"],
                    status_message
                ),
            ),
            # Next metric sliding in from the right
            render.Padding(
                pad = (64 - slide_distance, 0, 0, 0),
                child = create_metric_display(
                    next_metric["label"],
                    next_metric["value"],
                    next_metric["color"],
                    status_message
                ),
            ),
        ],
    )

def create_metric_display(label, value, color, status):
    """Create a display for a single metric"""
    return render.Column(
        expanded = True,
        main_align = "space_between",
        children = [
            # Header
            render.Box(
                height = 8,
                color = COLOR_HEADER,
                child = render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Padding(
                            pad = (2, 1, 0, 0),
                            child = render.Text(
                                content = label,
                                font = FONT_SMALL,
                                color = COLOR_TEXT,
                            ),
                        ),
                        render.Padding(
                            pad = (0, 1, 2, 0),
                            child = render.Text(
                                content = status,
                                font = FONT_SMALL,
                                color = COLOR_TEXT,
                            ),
                        ),
                    ],
                ),
            ),
            # Main content
            render.Box(
                height = 24,
                color = COLOR_BACKGROUND,
                child = render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Text(
                            content = value,
                            font = FONT_LARGE,
                            color = color,
                        ),
                    ],
                ),
            ),
        ],
    )

def fetch_vnstat_data(base_url, api_key, api_secret, cache_ttl):
    """Fetch network statistics from VNStat API"""

    # Construct the API URL
    endpoint = "/api/vnstat/service/daily"
    url = base_url.rstrip("/") + endpoint

    # Make the API request with basic authentication
    response = http.get(
        url = url,
        auth = (api_key, api_secret),
        ttl_seconds = cache_ttl,
    )

    if response.status_code != 200:
        return None, "API Error: {}".format(response.status_code)

    # Parse the JSON response first
    json_data = response.json()
    if not json_data:
        return None, "Invalid JSON response"
    
    if "response" not in json_data:
        return None, "No 'response' field in JSON"
    
    raw_data = json_data["response"]
    return parse_vnstat_response(raw_data), None

def parse_vnstat_response(raw_data):
    """Parse VNStat response text and extract statistics"""

    # Clean up the raw text - handle escaped characters from JSON
    clean_text = raw_data.replace("\\n", "\n").replace("\\/", "/")
    lines = clean_text.strip().split("\n")

    # Initialize totals for monthly data (sum of all daily entries)
    monthly_received = 0.0
    monthly_transmitted = 0.0
    
    # Initialize today's estimated data
    today_received = 0.0
    today_transmitted = 0.0

    # Process data lines to calculate monthly totals 
    for line in lines:
        # Skip non-data lines - only process lines with dates
        if not line or "estimated" in line or line.startswith("---") or "day" in line:
            continue
            
        # Look for lines with date pattern MM/DD/YY (this matches daily data lines)
        if re.search(r"\d{2}/\d{2}/\d{2}", line) and "GiB" in line:
            # Split by pipe and extract GiB values using string manipulation
            parts = line.split("|")
            if len(parts) >= 3:
                # Extract RX value (first part after date)
                rx_part = parts[0].strip()
                if "GiB" in rx_part:
                    # Find the number before " GiB"
                    rx_text = rx_part.split("GiB")[0].strip()
                    rx_words = rx_text.split()
                    if rx_words:
                        rx_str = rx_words[-1]
                        if "." in rx_str or rx_str.isdigit():
                            monthly_received += float(rx_str)
                
                # Extract TX value (second part)
                tx_part = parts[1].strip()
                if "GiB" in tx_part:
                    # Find the number before " GiB"
                    tx_text = tx_part.split("GiB")[0].strip()
                    tx_words = tx_text.split()
                    if tx_words:
                        tx_str = tx_words[-1]
                        if "." in tx_str or tx_str.isdigit():
                            monthly_transmitted += float(tx_str)

    # Find and parse estimated line for today's usage
    for line in lines:
        if "estimated" in line:
            # Split by pipe and extract GiB values using string manipulation
            parts = line.split("|")
            if len(parts) >= 3:
                # Extract RX value (first part after "estimated")
                rx_part = parts[0].strip()
                if "GiB" in rx_part:
                    # Find the number before " GiB"
                    rx_text = rx_part.split("GiB")[0].strip()
                    rx_words = rx_text.split()
                    if rx_words:
                        rx_str = rx_words[-1]
                        if "." in rx_str or rx_str.isdigit():
                            today_received = float(rx_str)
                
                # Extract TX value (second part)
                tx_part = parts[1].strip()
                if "GiB" in tx_part:
                    # Find the number before " GiB"
                    tx_text = tx_part.split("GiB")[0].strip()
                    tx_words = tx_text.split()
                    if tx_words:
                        tx_str = tx_words[-1]
                        if "." in tx_str or tx_str.isdigit():
                            today_transmitted = float(tx_str)
            break

    # Return the four metrics to display: Today's estimated usage and Total monthly usage
    return {
        "total_received": today_received,      # Today's estimated RX (from estimated line)
        "total_transmitted": today_transmitted, # Today's estimated TX (from estimated line)
        "monthly_received": monthly_received,   # Total month RX (sum of all daily data)
        "monthly_transmitted": monthly_transmitted, # Total month TX (sum of all daily data)
    }

def format_bytes(gb_value):
    """Format bytes for display"""
    if gb_value >= 1000:
        tb_value = math.round(gb_value / 100) / 10  # Round to 1 decimal place
        return "{}TB".format(tb_value)
    elif gb_value >= 1:
        gb_rounded = math.round(gb_value * 10) / 10  # Round to 1 decimal place
        return "{}GB".format(gb_rounded)
    else:
        mb_value = math.round(gb_value * 1000)
        return "{}MB".format(mb_value)

def error_display(message):
    """Display an error message"""
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(
                    content = "VNStat ERROR",
                    font = FONT_MEDIUM,
                    color = COLOR_ERROR,
                ),
                render.Text(
                    content = message,
                    font = FONT_SMALL,
                    color = COLOR_ERROR,
                ),
            ],
        ),
    )

def get_schema():
    """Define the configuration schema"""

    cache_options = [
        schema.Option(
            display = "5 minutes",
            value = "300",
        ),
        schema.Option(
            display = "15 minutes",
            value = "900",
        ),
        schema.Option(
            display = "30 minutes",
            value = "1800",
        ),
        schema.Option(
            display = "1 hour",
            value = "3600",
        ),
        schema.Option(
            display = "4 hours",
            value = "14400",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "baseUrl",
                name = "Base URL",
                desc = "The base URL of your OPNsense router (e.g., http://192.168.1.1)",
                icon = "link",
                default = DEFAULT_BASE_URL,
            ),
            schema.Text(
                id = "apiKey",
                name = "API Key",
                desc = "Your OPNsense API key for VNStat access",
                icon = "key",
            ),
            schema.Text(
                id = "apiSecret",
                name = "API Secret",
                desc = "Your OPNsense API secret for VNStat access",
                icon = "lock",
            ),
            schema.Dropdown(
                id = "cacheTtl",
                name = "Refresh Interval",
                desc = "How often to fetch new data",
                icon = "clock",
                default = cache_options[1].value,
                options = cache_options,
            ),
        ],
    )

