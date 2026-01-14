# ==============================================================================
# Brewfather Tronbyt App
# ==============================================================================
# Displays live fermentation status from Brewfather API v2.
# Features:
# - Supports both Standard (Gen 1) and Wide (Gen 2) Tidbyt displays.
# - Fetches live SG, Temp, ABV, and Attenuation.
# - Calculates "Live ABV" manually to avoid "Recipe ABV" fallback.
# - Renders a specific gravity trend graph.
#
# Development Disclosure:
# This code was streamlined and optimized with the assistance of Gemini (Google AI).
# ==============================================================================

load("encoding/base64.star", "base64")
load("http.star", "http")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")

# --- CONFIGURATION ---
BATCH_LIST_URL = "https://api.brewfather.app/v2/batches?status=Fermenting"
BATCH_DETAIL_URL = "https://api.brewfather.app/v2/batches/{batch_id}"
READINGS_URL = "https://api.brewfather.app/v2/batches/{batch_id}/readings"

def get_auth_headers(user_id, api_key):
    auth_string = base64.encode(user_id + ":" + api_key)
    return {"Authorization": "Basic " + auth_string}

def convert_temp(c, units):
    if units == "F":
        return (c * 1.8) + 32
    return c

def format_decimal(value, multiplier):
    rounded = math.round(value * multiplier)
    return str(rounded / multiplier)

def calculate_abv(og, fg):
    if og == 0 or fg == 0:
        return 0.0
    return (og - fg) * 131.25

def calculate_att(og, fg):
    if og <= 1.0:
        return 0.0
    return ((og - fg) / (og - 1.0)) * 100

def main(config):
    # --- DISPLAY DETECTION & ANIMATION SETTINGS ---
    is_wide = False
    if hasattr(canvas, "is2x"):
        is_wide = canvas.is2x()

    # Gen 2 needs faster refresh (25ms) for smoothness, but Marquee needs delay (1)
    # to prevent text from flying by too fast.
    marquee_delay = 1 if is_wide else 0
    root_delay = 25 if is_wide else 50

    user_id = config.get("user_id")
    api_key = config.get("api_key")
    units = config.get("units", "F")

    if not user_id or not api_key:
        return render.Root(child = render.WrappedText("Setup API Key"))

    headers = get_auth_headers(user_id, api_key)

    # 1. FIND ACTIVE BATCH ID
    list_rep = http.get(BATCH_LIST_URL, headers = headers, ttl_seconds = 300)
    if list_rep.status_code != 200:
        return render.Root(child = render.Text("List API: %d" % list_rep.status_code))

    batches = list_rep.json()
    if not batches:
        return render.Root(child = render.Text("No Batch"))

    batch_id = batches[0]["_id"]

    # 2. FETCH FULL BATCH DETAILS
    # We need the specific batch endpoint to get the "measuredOg" or "estimatedOg" fields.
    detail_rep = http.get(BATCH_DETAIL_URL.format(batch_id = batch_id), headers = headers, ttl_seconds = 300)
    if detail_rep.status_code != 200:
        return render.Root(child = render.Text("Detail API: %d" % detail_rep.status_code))

    batch = detail_rep.json()

    recipe_name = batch.get("recipe", {}).get("name", "Unknown")
    batch_status = batch.get("status", "Fermenting")

    # 3. DETERMINE ORIGINAL GRAVITY (OG)
    # Critical for calculating ABV. Priority: Measured > Estimated > Recipe
    og = 0.0
    og_val = batch.get("measuredOg") or batch.get("estimatedOg") or batch.get("recipe", {}).get("estimatedOg")
    if og_val:
        og = float(og_val)

    # 4. FETCH READINGS (Tilt/Hydrometer Data)
    readings_rep = http.get(READINGS_URL.format(batch_id = batch_id), headers = headers, ttl_seconds = 300)
    readings = []
    if readings_rep.status_code == 200:
        readings = readings_rep.json()

    # 5. PROCESS DATA
    plot_data = []
    latest_sg = 0.0
    latest_temp = 0.0
    abv = 0.0
    att = 0.0

    # Filter for readings that actually contain gravity data
    valid_readings = [r for r in readings if "sg" in r]
    if valid_readings:
        last_reading = valid_readings[-1]
        latest_sg = float(last_reading["sg"])
        latest_temp = convert_temp(float(last_reading.get("temp", 0)), units)

    # --- CALCULATE LIVE STATS ---
    # We calculate manually to ensure we see "Current ABV" based on the latest reading,
    # rather than the "Projected ABV" the API often returns for incomplete batches.
    if og > 1.0 and latest_sg > 1.0:
        abv = calculate_abv(og, latest_sg)
        att = calculate_att(og, latest_sg)

    # Fallback: Use API ABV if manual calculation failed (e.g. missing OG)
    if abv == 0.0:
        abv_val = batch.get("abv") or batch.get("recipe", {}).get("abv")
        if abv_val:
            abv = float(abv_val)

    abv_text = format_decimal(abv, 10.0) + "%"

    # Format Attenuation
    att_text = "0%"
    if att > 0:
        att_text = str(int(math.round(att))) + "%"

    # Visual warning if we have a reading but failed to calc ABV (implies missing OG)
    if abv == 0.0 and latest_sg > 1.0:
        abv_text = "?"

    # Populate graph data points
    for r in readings:
        sg_val = r.get("sg")
        time_val = r.get("time")
        if sg_val != None and time_val != None:
            plot_data.append((float(time_val), float(sg_val)))

    return render_layout(is_wide, recipe_name, batch_status, plot_data, latest_sg, latest_temp, abv_text, att_text, units, marquee_delay, root_delay)

def render_layout(is_wide, name, status, data, sg, temp, abv_text, att_text, units, m_delay, r_delay):
    temp_str = str(int(math.round(temp))) + "°"
    if is_wide:
        temp_str += units
    sg_str = format_decimal(sg, 1000.0)

    # --- BREWFATHER COLOR THEME ---
    bf_yellow = "#ffcd00"
    bf_red = "#e74c3c"
    bf_blue = "#3498db"
    bf_green = "#2ecc71"
    bf_white = "#ecf0f1"
    bf_grey = "#95a5a6"

    # Graph Colors
    graph_line = "#c0392b"
    graph_fill = "#581616"
    c_bg = "#1a1a1a"

    if is_wide:
        # ==========================================
        # LAYOUT: WIDE (128x64) - GEN 2
        # ==========================================
        return render.Root(
            delay = r_delay,
            child = render.Column(
                children = [
                    # HEADER
                    render.Box(width = 128, height = 16, color = c_bg, child = render.Marquee(width = 128, delay = m_delay, child = render.Text("Currently Brewing: " + name, font = "6x13", color = bf_yellow))),
                    # BODY
                    render.Row(
                        expanded = True,
                        children = [
                            # STATS COLUMN
                            render.Box(
                                width = 68,
                                height = 48,
                                child = render.Padding(
                                    pad = (1, 0, 1, 0),
                                    child = render.Column(
                                        main_align = "start",
                                        children = [
                                            render.Marquee(width = 66, delay = m_delay, child = render.Text(status, font = "6x13", color = bf_white)),
                                            render.Box(width = 1, height = 3),  # Spacer to push stats down
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
                            # GRAPH COLUMN
                            render.Box(width = 60, height = 48, child = render.Plot(data = data, width = 60, height = 48, color = graph_line, fill = True, fill_color = graph_fill)),
                        ],
                    ),
                ],
            ),
        )
    else:
        # ==========================================
        # LAYOUT: STANDARD (64x32) - GEN 1
        # ==========================================
        return render.Root(
            delay = r_delay,
            child = render.Column(
                children = [
                    # HEADER (Tom-Thumb for height efficiency)
                    render.Box(
                        width = 64,
                        height = 8,
                        color = c_bg,
                        child = render.Marquee(
                            width = 64,
                            delay = m_delay,
                            child = render.Row(
                                children = [
                                    render.Text("Brewing: " + name, font = "tb-8", color = bf_yellow),
                                    render.Text(" (" + status + ")", font = "tb-8", color = bf_white),
                                ],
                            ),
                        ),
                    ),
                    # BODY (Tight layout using TB-8)
                    render.Row(
                        expanded = True,
                        children = [
                            # TEXT COLUMN (Widened to 40px to fit TB-8)
                            render.Box(
                                width = 40,
                                height = 24,
                                child = render.Padding(
                                    pad = (1, 0, 1, 0),
                                    child = render.Column(
                                        main_align = "space_between",  # Stacks rows top-to-bottom
                                        children = [
                                            render.Row(expanded = True, main_align = "space_between", children = [render.Text("SG:", font = "tb-8", color = bf_grey), render.Text(sg_str, font = "tb-8", color = bf_red)]),
                                            render.Row(expanded = True, main_align = "space_between", children = [render.Text("TMP:", font = "tb-8", color = bf_grey), render.Text(temp_str, font = "tb-8", color = bf_blue)]),
                                            render.Row(expanded = True, main_align = "space_between", children = [render.Text("ABV:", font = "tb-8", color = bf_grey), render.Text(abv_text, font = "tb-8", color = bf_green)]),
                                        ],
                                    ),
                                ),
                            ),
                            # GRAPH COLUMN (Narrowed to 24px)
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
