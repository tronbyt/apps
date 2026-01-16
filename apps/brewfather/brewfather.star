# ==============================================================================
# Brewfather Tronbyt App
# ==============================================================================
# Displays live fermentation status from Brewfather API v2.
#
# Features:
# - Multi-Device Support: Adapts layout for Standard (64x32) and Wide (128x64).
# - Batch Selection: User selects specific batch index via settings.
# - Smart Hiding: Toggle to hide app if no batches are active (Defaults to ON).
# - Performance Graphing: Downsamples data to ~60 points for smooth Filled Area Graphs.
# - Crash Protection: Filters null/invalid sensor data (SG < 0.9).
# - Glitch Fix: Sorts graph data by time to prevent diagonal artifacts.
# - Layout Fix: "Conditioning" uses smaller font on wide display to fit without scrolling.
#
# Development Disclosure:
# This code was streamlined and optimized with the assistance of Gemini (Google AI).
# ==============================================================================

load("encoding/base64.star", "base64")
load("http.star", "http")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")

# --- API CONFIGURATION ---
BATCH_LIST_BASE_URL = "https://api.brewfather.app/v2/batches"
BATCH_DETAIL_URL = "https://api.brewfather.app/v2/batches/{batch_id}"
READINGS_URL = "https://api.brewfather.app/v2/batches/{batch_id}/readings"

# --- HELPER FUNCTIONS ---

def get_auth_headers(user_id, api_key):
    """Encodes credentials for Basic Auth."""
    auth_string = base64.encode(user_id + ":" + api_key)
    return {"Authorization": "Basic " + auth_string}

def convert_temp(c, units):
    """Converts Celsius to Fahrenheit if needed."""
    if units == "F":
        return (c * 1.8) + 32
    return c

def format_decimal(value, multiplier):
    """Rounds a float to a specific decimal place."""
    rounded = math.round(value * multiplier)
    return str(rounded / multiplier)

def calculate_abv(og, fg):
    """Calculates ABV using standard formula."""
    if og == 0 or fg == 0:
        return 0.0
    return (og - fg) * 131.25

def calculate_att(og, fg):
    """Calculates apparent attenuation percentage."""
    if og <= 1.0:
        return 0.0
    return ((og - fg) / (og - 1.0)) * 100

def downsample(data, max_points = 60):
    """
    Reduces the dataset to 'max_points' to ensure the Filled Graph
    renders correctly without visual artifacts or "solid blocks".
    """
    if len(data) <= max_points:
        return data
    step = len(data) / float(max_points)
    result = []
    for i in range(max_points):
        index = int(i * step)
        if index < len(data):
            result.append(data[index])

    # Ensure the very latest reading is included
    if data[-1] != result[-1]:
        result.append(data[-1])
    return result

def render_message(message, is_wide):
    """Renders a scrolling message for empty states."""

    # Updated: Uses tb-8 instead of tom-thumb for better readability on standard screens
    font = "6x13" if is_wide else "tb-8"
    width = 128 if is_wide else 64
    height = 64 if is_wide else 32

    return render.Root(
        child = render.Box(
            width = width,
            height = height,
            color = "#1a1a1a",  # Match Background
            child = render.Marquee(
                width = width,
                child = render.Text(
                    content = message,
                    font = font,
                    color = "#ffcd00",  # Brewfather Yellow
                ),
            ),
        ),
    )

# --- MAIN APP LOGIC ---

def main(config):
    # 1. Device & Animation Settings
    is_wide = False
    if hasattr(canvas, "is2x"):
        is_wide = canvas.is2x()

    root_delay = 25 if is_wide else 50
    marquee_delay = 30

    # 2. Load User Config
    user_id = config.get("user_id")
    api_key = config.get("api_key")
    units = config.get("units", "F")
    target_index = int(config.get("batch_selector", "0"))

    hide_if_empty = config.bool("hide_if_empty", True)

    if not user_id or not api_key:
        return render.Root(child = render.WrappedText("Setup API Key"))

    headers = get_auth_headers(user_id, api_key)

    # 3. Fetch Active Batches
    active_batches = []

    def fetch_batches(status):
        url = BATCH_LIST_BASE_URL + "?status=" + status + "&sort=brewDate:desc"
        rep = http.get(url, headers = headers, ttl_seconds = 300)
        if rep.status_code == 200:
            return rep.json()
        return []

    active_batches.extend(fetch_batches("Fermenting"))
    active_batches.extend(fetch_batches("Conditioning"))

    unique_batches = []
    seen_ids = {}
    for b in active_batches:
        if b["_id"] not in seen_ids:
            unique_batches.append(b)
            seen_ids[b["_id"]] = True

    # 4. Handle Empty State
    if not unique_batches:
        if hide_if_empty:
            return []  # Returns nothing, removing app from rotation

        return render_message("There is nothing brewing here, go drink some beer!", is_wide)

    # 5. Select Target Batch
    if target_index >= len(unique_batches):
        msg = "Batch #%d: There is nothing brewing here, go drink some beer!" % (target_index + 1)
        return render_message(msg, is_wide)

    batch_id = unique_batches[target_index]["_id"]

    # 6. Fetch Full Details
    detail_rep = http.get(BATCH_DETAIL_URL.format(batch_id = batch_id), headers = headers, ttl_seconds = 300)
    if detail_rep.status_code != 200:
        return render.Root(child = render.Text("API Error: %d" % detail_rep.status_code))

    batch = detail_rep.json()
    recipe_name = batch.get("recipe", {}).get("name", "Unknown")
    batch_status = batch.get("status", "Unknown")

    # Determine OG
    og = 0.0
    og_val = batch.get("measuredOg") or batch.get("estimatedOg") or batch.get("recipe", {}).get("estimatedOg")
    if og_val:
        og = float(og_val)

    # 7. Fetch Readings
    readings_rep = http.get(READINGS_URL.format(batch_id = batch_id), headers = headers, ttl_seconds = 300)
    readings = []
    if readings_rep.status_code == 200:
        readings = readings_rep.json()

    # 8. Process Data
    raw_plot_data = []
    latest_sg = 0.0
    latest_temp = 0.0
    abv = 0.0
    att = 0.0

    valid_readings = [r for r in readings if (r.get("sg") or 0) > 0.9]

    if valid_readings:
        last_reading = valid_readings[-1]
        latest_sg = float(last_reading["sg"])
        latest_temp = convert_temp(float(last_reading.get("temp", 0)), units)

        if og > 1.0 and latest_sg > 1.0:
            abv = calculate_abv(og, latest_sg)
            att = calculate_att(og, latest_sg)

    if abv == 0.0:
        abv_val = batch.get("abv") or batch.get("recipe", {}).get("abv")
        if abv_val:
            abv = float(abv_val)

    abv_text = format_decimal(abv, 10.0) + "%"
    att_text = "0%"
    if att > 0:
        att_text = str(int(math.round(att))) + "%"

    if abv == 0.0 and latest_sg > 1.0:
        abv_text = "?"

    # 9. Build Graph Data
    for r in valid_readings:
        time_val = r.get("time")
        if time_val:
            raw_plot_data.append((float(time_val), float(r["sg"])))

    # Sort data by time to fix diagonal fill artifact
    raw_plot_data = sorted(raw_plot_data)

    plot_data = downsample(raw_plot_data, 60)

    # 10. Render Layout
    return render_layout(is_wide, recipe_name, batch_status, plot_data, latest_sg, latest_temp, abv_text, att_text, units, marquee_delay, root_delay)

def render_layout(is_wide, name, status, data, sg, temp, abv_text, att_text, units, m_delay, r_delay):
    temp_str = str(int(math.round(temp))) + "°"
    if is_wide:
        temp_str += units
    sg_str = format_decimal(sg, 1000.0)

    # --- BREWFATHER THEME COLORS ---
    bf_yellow = "#ffcd00"
    bf_red = "#e74c3c"
    bf_blue = "#3498db"
    bf_green = "#2ecc71"
    bf_white = "#ecf0f1"
    bf_grey = "#95a5a6"

    graph_line = "#c0392b"
    graph_fill = "#581616"  # Dark Red Fill
    c_bg = "#1a1a1a"

    # --- FONT LOGIC ---
    # Default big font for status
    status_font = "6x13"

    # If "Conditioning", it's too long for 6x13, so step down to tb-8 to avoid scrolling
    if status == "Conditioning":
        status_font = "tb-8"

    if is_wide:
        # ==========================================
        # WIDE LAYOUT (128x64)
        # ==========================================
        return render.Root(
            delay = r_delay,
            child = render.Column(
                children = [
                    # Header: "Currently Brewing: [Name]" (Always Yellow)
                    render.Box(
                        width = 128,
                        height = 16,
                        color = c_bg,
                        child = render.Marquee(
                            width = 128,
                            delay = m_delay,
                            child = render.Text("Currently Brewing: " + name, font = "6x13", color = bf_yellow),
                        ),
                    ),
                    # Content Body
                    render.Row(
                        expanded = True,
                        children = [
                            # Stats Column
                            render.Box(
                                width = 68,
                                height = 48,
                                child = render.Padding(
                                    pad = (1, 0, 1, 0),
                                    child = render.Column(
                                        main_align = "start",
                                        children = [
                                            # Status Text (White) - Uses smart font sizing
                                            render.Marquee(width = 66, delay = m_delay, child = render.Text(status, font = status_font, color = bf_white)),
                                            render.Box(width = 1, height = 3),  # Spacer
                                            render.Column(
                                                children = [
                                                    render.Row(expanded = True, main_align = "space_between", children = [render.Text("SG:", font = "tb-8", color = bf_grey), render.Text(sg_str, font = "tb-8", color = bf_red)]),
                                                    render.Row(expanded = True, main_align = "space_between", children = [render.Text("Temp:", font = "tb-8", color = bf_grey), render.Text(temp_str, font = "tb-8", color = bf_blue)]),
                                                    render.Row(expanded = True, main_align = "space_between", children = [render.Text("ABV:", font = "tb-8", color = bf_grey), render.Text(abv_text, font = "tb-8", color = bf_green)]),
                                                    render.Row(expanded = True, main_align = "space_between", children = [render.Text("Att:", font = "tb-8", color = bf_grey), render.Text(att_text, font = "tb-8", color = bf_white)]),
                                                ],
                                            ),
                                        ],
                                    ),
                                ),
                            ),
                            # Graph Box (Filled Graph Enabled)
                            render.Box(width = 60, height = 48, child = render.Plot(data = data, width = 60, height = 48, color = graph_line, fill = True, fill_color = graph_fill)),
                        ],
                    ),
                ],
            ),
        )
    else:
        # ==========================================
        # STANDARD LAYOUT (64x32)
        # ==========================================
        return render.Root(
            delay = r_delay,
            child = render.Column(
                children = [
                    # Header: "[Name] ([Status])" -> Name (Yellow), Status (White)
                    render.Box(
                        width = 64,
                        height = 8,
                        color = c_bg,
                        child = render.Marquee(
                            width = 64,
                            delay = m_delay,
                            child = render.Row(
                                children = [
                                    render.Text(name, font = "tom-thumb", color = bf_yellow),
                                    render.Text(" (" + status + ")", font = "tom-thumb", color = bf_white),
                                ],
                            ),
                        ),
                    ),
                    # Content Body
                    render.Row(
                        expanded = True,
                        children = [
                            # Stats Column (Uses TB-8 font for readability)
                            render.Box(
                                width = 40,
                                height = 24,
                                child = render.Padding(
                                    pad = (1, 0, 1, 0),
                                    child = render.Column(
                                        main_align = "space_between",
                                        children = [
                                            render.Row(expanded = True, main_align = "space_between", children = [render.Text("SG:", font = "tb-8", color = bf_grey), render.Text(sg_str, font = "tb-8", color = bf_red)]),
                                            render.Row(expanded = True, main_align = "space_between", children = [render.Text("TMP:", font = "tb-8", color = bf_grey), render.Text(temp_str, font = "tb-8", color = bf_blue)]),
                                            render.Row(expanded = True, main_align = "space_between", children = [render.Text("ABV:", font = "tb-8", color = bf_grey), render.Text(abv_text, font = "tb-8", color = bf_green)]),
                                        ],
                                    ),
                                ),
                            ),
                            # Graph Box (Filled Graph Enabled)
                            render.Box(width = 24, height = 24, child = render.Plot(data = data, width = 24, height = 24, color = graph_line, fill = True, fill_color = graph_fill)),
                        ],
                    ),
                ],
            ),
        )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(id = "user_id", name = "User ID", desc = "Brewfather User ID", icon = "user"),
            schema.Text(id = "api_key", name = "API Key", desc = "Brewfather API Key", icon = "key", secret = True),
            schema.Dropdown(
                id = "batch_selector",
                name = "Batch To Display",
                desc = "Select which active batch to show (Newest to Oldest)",
                icon = "list",
                default = "0",
                options = [
                    schema.Option(display = "Most Recent", value = "0"),
                    schema.Option(display = "2nd Newest", value = "1"),
                    schema.Option(display = "3rd Newest", value = "2"),
                    schema.Option(display = "4th Newest", value = "3"),
                    schema.Option(display = "5th Newest", value = "4"),
                ],
            ),
            schema.Toggle(
                id = "hide_if_empty",
                name = "Hide if no active batches",
                desc = "Do not display the app if there are no Fermenting or Conditioning batches.",
                icon = "eyeSlash",
                default = True,
            ),
            schema.Dropdown(
                id = "units",
                name = "Temperature Units",
                desc = "Select display units",
                icon = "ruler",
                default = "F",
                options = [
                    schema.Option(display = "Fahrenheit", value = "F"),
                    schema.Option(display = "Celsius", value = "C"),
                ],
            ),
        ],
    )
