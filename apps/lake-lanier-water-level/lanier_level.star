load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

WATER_LEVEL_API = "https://attrhlvatssgurlriewu.supabase.co/functions/v1/water-level-api"

# Display mode: "A" for Simple Stats, "B" for Mini Chart, "alternate" to switch between modes
# This is used as a fallback when schema config is not available
DISPLAY_MODE = "alternate"

def get_color(feet_above_full):
    """Returns color based on feet above full pool level"""
    if feet_above_full >= -1:
        return "#00FF00"  # Green - Near or above full
    elif feet_above_full >= -3:
        return "#FFFF00"  # Yellow - Slightly below
    elif feet_above_full >= -5:
        return "#FFA500"  # Orange - Moderately below
    else:
        return "#FF0000"  # Red - Significantly below

def get_trend_icon(trend):
    """Returns icon character based on trend direction"""
    if trend == "up":
        return "↑"
    elif trend == "down":
        return "↓"
    else:
        return "→"

def format_float(value, decimals):
    """Format a float to a string with specified decimal places"""

    # Convert to float and then to string
    fval = float(value)
    str_val = str(fval)
    parts = str_val.split(".")

    if len(parts) == 1:
        # No decimal point, add zeros
        result = parts[0] + "."
        for _ in range(decimals):
            result = result + "0"
        return result
    else:
        # Has decimal point, pad or truncate
        decimal_part = parts[1]
        if len(decimal_part) < decimals:
            # Pad with zeros
            for _ in range(decimals - len(decimal_part)):
                decimal_part = decimal_part + "0"
        elif len(decimal_part) > decimals:
            # Truncate (simple truncation, not rounding)
            decimal_part = decimal_part[:decimals]
        return parts[0] + "." + decimal_part

def get_schema():
    """Returns schema for Tidbyt App Store submission"""
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "show_chart",
                name = "Show Chart",
                desc = "Show 7-day history chart",
                icon = "chartLine",
                default = False,
            ),
        ],
    )

def mode_a_simple_stats(_level, feet_above, trend):
    """Mode A - Simple Stats Display"""
    feet_above_str = format_float(feet_above, 1) + " ft from full"
    return render.Root(
        child = render.Column(
            children = [
                render.Text("Lake Lanier", color = "#4A90A4", font = "tb-8"),
                render.Text(feet_above_str, color = get_color(feet_above), font = "6x13"),
                render.Row(children = [
                    render.Text(get_trend_icon(trend), color = "#888"),
                ]),
            ],
        ),
    )

def mode_b_mini_chart(_level, trend, history_data):
    """Mode B - Mini Chart Display with 7-day history"""

    # Prepare data points for the chart
    data_points = []
    if len(history_data) > 0:
        # Create data points: (x_index, y_value)
        for i, record in enumerate(history_data):
            height = float(record["gage_height"])
            data_points.append((i, height))

    # Get color based on current level
    current_feet_above = float(history_data[-1]["feet_above_full"]) if len(history_data) > 0 else 0.0
    chart_color = get_color(current_feet_above)

    # Build chart display
    chart_widget = render.Text("No data", color = "#888")
    if len(data_points) > 0:
        heights = [float(d["gage_height"]) for d in history_data]
        chart_widget = render.Plot(
            data = data_points,
            width = 64,
            height = 16,
            color = chart_color,
            y_lim = (min(heights), max(heights)),
        )

    # Display feet from full
    feet_above_str = format_float(current_feet_above, 1) + " ft from full"
    return render.Root(
        child = render.Column(
            children = [
                # Top: Feet from full + trend
                render.Row(children = [
                    render.Text(feet_above_str, color = get_color(current_feet_above), font = "6x13"),
                    render.Text(" " + get_trend_icon(trend), color = "#888"),
                ]),
                # Bottom: 7-day historical chart
                chart_widget,
            ],
        ),
    )

def main(config = None):
    # Determine which mode to display
    # Priority: 1) Schema config (show_chart), 2) config parameter, 3) DISPLAY_MODE constant
    current_mode = DISPLAY_MODE
    use_chart = False

    # Check schema config first (for Tidbyt App Store)
    if config != None:
        if config.get("show_chart") != None:
            # Schema config takes priority
            use_chart = config.get("show_chart")
        elif config.get("mode") != None:
            # Fallback to mode parameter for direct usage
            current_mode = config.get("mode")

    # If schema config is set, use it; otherwise use current_mode
    if config != None and config.get("show_chart") != None:
        # Schema config mode
        if not use_chart:
            # Simple stats mode
            rep = http.get(WATER_LEVEL_API + "?endpoint=latest")
            if rep.status_code != 200:
                return render.Root(child = render.Text("API Error"))
            latest_data = rep.json()["data"]
            return mode_a_simple_stats(
                latest_data["gage_height"],
                latest_data["feet_above_full"],
                latest_data["trend"],
            )
        else:
            # Chart mode
            rep = http.get(WATER_LEVEL_API + "?endpoint=latest")
            if rep.status_code != 200:
                return render.Root(child = render.Text("API Error"))
            latest_data = rep.json()["data"]

            history_rep = http.get(WATER_LEVEL_API + "?endpoint=history&days=7&limit=100")
            if history_rep.status_code != 200:
                return mode_a_simple_stats(
                    latest_data["gage_height"],
                    latest_data["feet_above_full"],
                    latest_data["trend"],
                )

            history_json = history_rep.json()
            history_data = history_json.get("data", [])
            return mode_b_mini_chart(
                latest_data["gage_height"],
                latest_data["trend"],
                history_data,
            )

    # Legacy mode handling (for direct usage without schema)
    # Fetch latest water level data
    rep = http.get(WATER_LEVEL_API + "?endpoint=latest")
    if rep.status_code != 200:
        return render.Root(child = render.Text("API Error"))

    latest_data = rep.json()["data"]
    level = latest_data["gage_height"]
    feet_above = latest_data["feet_above_full"]
    trend = latest_data["trend"]

    # If Mode A, return simple stats
    if current_mode == "A":
        return mode_a_simple_stats(level, feet_above, trend)

    # If Mode B or alternate, fetch historical data and show chart
    if current_mode == "B" or current_mode == "alternate":
        history_rep = http.get(WATER_LEVEL_API + "?endpoint=history&days=7&limit=100")
        if history_rep.status_code != 200:
            # Fallback to Mode A if history fetch fails
            return mode_a_simple_stats(level, feet_above, trend)

        history_json = history_rep.json()
        history_data = history_json.get("data", [])

        # For alternate mode, switch based on whether we have enough data points
        if current_mode == "alternate":
            # Simple alternation: use chart if we have data, otherwise use stats
            if len(history_data) >= 7:
                return mode_b_mini_chart(level, trend, history_data)
            else:
                return mode_a_simple_stats(level, feet_above, trend)

        return mode_b_mini_chart(level, trend, history_data)

    # Default to Mode A
    return mode_a_simple_stats(level, feet_above, trend)
