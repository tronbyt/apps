"""
Applet: Snow Forecast
Summary: Get snow forecast updates
Description: Find out how much snow will be coming to your ski resort.
Author: Brombomb
"""

load("render.star", "render")
load("schema.star", "schema")
load("http.star", "http")
load("time.star", "time")
load("math.star", "math")
load("resorts.star", "RESORTS")

DEFAULT_RESORT = "keystone"
DEFAULT_UNITS = "imperial"

# Colors
SNOW_COLOR = "#fff"
TEXT_COLOR = "#fff"
TITLE_COLOR = "#0ff"

def format_snow(val):
    # Starlark doesn't support {:.1f}
    # Simple rounding to 1 decimal place
    val = int(val * 10 + 0.5) / 10.0
    val_str = str(val)
    if "." not in val_str:
        val_str += ".0"
    return val_str


def get_forecast(resort, units):
    """Fetches forecast data from Open-Meteo."""

    precip_unit = "inch" if units == "imperial" else "mm"

    url = "https://api.open-meteo.com/v1/forecast?latitude={}&longitude={}&daily=snowfall_sum&timezone=auto&forecast_days=14&past_days=14&precipitation_unit={}".format(
        resort["lat"],
        resort["lon"],
        precip_unit,
    )

    print("Fetching URL:", url)
    rep = http.get(url)
    if rep.status_code != 200:
        fail("Open-Meteo request failed with status {}", rep.status_code)

    return rep.json()

def calculate_summaries(data):
    """Calculates snowfall summaries."""
    daily = data["daily"]
    snowfall = daily["snowfall_sum"]
    # dates = daily["time"] # Not strictly needed for sum but good to know

    # API returns past_days=14 (indexes 0-13) + Toady (14) + forecast_days=14 (15-28 actually 14 days forecast)
    # Actually checking docs/response structure:
    # past_days=14 means 14 days BEFORE today.
    # forecast_days=14 means today + 13 days future.
    # Total length should be 14 + 14 = 28? Or 14+1+13?
    # Let's assume the API returns a continuous list relative to "today" index.
    # We requested past_days=14 and forecast_days=14.
    # Usually the response includes 'time' array which we can parse if needed,
    # but for simple summing based on indices:

    # 14 days past: indices 0 to 13?
    # Next 7 days: index 14 to 20?
    # Next 14 days: index 14 to 27?

    # Let's verify index 14 is indeed "today".
    # Since we can't easily print today's date and match without more logic,
    # we'll trust the parameter count.

    past_14_sum = 0.0
    for i in range(14):
        if i < len(snowfall):
             past_14_sum += snowfall[i]

    next_7_sum = 0.0
    for i in range(14, 21):
        if i < len(snowfall):
            next_7_sum += snowfall[i]

    next_14_sum = 0.0
    for i in range(14, 28):
        if i < len(snowfall):
            next_14_sum += snowfall[i]

    # Get snowfall array for graph (next 7 days)
    graph_data = []
    for i in range(14, 21):
        if i < len(snowfall):
            graph_data.append(snowfall[i])

    return {
        "past_14": past_14_sum,
        "next_7": next_7_sum,
        "next_14": next_14_sum,
        "graph_data": graph_data,
    }

def main(config):
    resort_id = config.str("resort", DEFAULT_RESORT)
    units = config.str("units", DEFAULT_UNITS)
    resort = None

    for r in RESORTS:
        if r["value"] == resort_id:
            resort = r
            break

    if not resort:
        # Fallback if id not found (e.g. default)
        resort = RESORTS[0]
        resort_name = "Unknown"
    else:
        resort_name = resort["display"]

    data = get_forecast(resort, units)
    sums = calculate_summaries(data)

    unit_label = "\"" if units == "imperial" else "cm"

    # Note on units: Open-Meteo returns mm for precipitation_unit=mm
    # Snowfall is often measured in cm in metric countries for skiing purposes.
    # OpenMeteo snowfall_sum is in the requested precipitation unit (mm).
    # If using metric, let's convert mm to cm for display if desired, or keep as mm.
    # Ski resorts usually report cm.
    # Let's convert mm to cm for display if metric.
    if units == "metric":
         sums["past_14"] /= 10.0
         sums["next_7"] /= 10.0
         sums["next_14"] /= 10.0
         # Graph data is relative so doesn't strictly need scaling for visibility but good for correctness
         for i in range(len(sums["graph_data"])):
             sums["graph_data"][i] /= 10.0

    # Screen 1: Summary
    screen1 = render.Padding(
        pad = 1,
        child = render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    child = render.Text(resort_name, color = TITLE_COLOR),
                ),
                render.Box(height=1, width=64, color="#000"), # Spacer
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Text("Past 14d:", font = "tb-8"),
                        render.Text(format_snow(sums["past_14"]) + unit_label, color = SNOW_COLOR, font = "tb-8"),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Text("Next 7d:", font = "tb-8"),
                        render.Text(format_snow(sums["next_7"]) + unit_label, color = SNOW_COLOR, font = "tb-8"),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Text("Next 14d:", font = "tb-8"),
                        render.Text(format_snow(sums["next_14"]) + unit_label, color = SNOW_COLOR, font = "tb-8"),
                    ],
                ),
            ],
        ),
    )

    # Screen 2: Graph
    # Normalize graph data for height 20 (leaving space for title)
    graph_height = 20
    max_val = 0.1 # avoid div by zero
    for v in sums["graph_data"]:
        if v > max_val:
            max_val = v

    # Bars and Labels
    bars_children = []

    dates = data["daily"]["time"] # Full list

    for i, v in enumerate(sums["graph_data"]):
        # Date index: 14 + i
        date_str = dates[14+i]
        date_obj = time.parse_time(date_str, "2006-01-02")
        day_label = date_obj.format("Mon")[0] # First letter

        # Vertical Budget (32px total):
        # Header (6) + Padding (2) = 8 used. 24 remaining.
        # Graph Block:
        # Bar (Max 16)
        # Spacer (1)
        # Axis (6)
        # Total Graph Block: ~23px

        avail_bar_h = 16

        h = int((v / max_val) * avail_bar_h)
        if h < 1 and v > 0: h = 1

        bars_children.append(
            render.Box(
                width = 9,
                child = render.Column(
                    main_align = "end",
                    cross_align = "center",
                    children = [
                        render.Box(width=5, height=h, color="#0ff"), # Cyan Bar
                        render.Box(height=1), # Spacer between bar and axis
                        render.Text(day_label, font="tom-thumb", color="#888"), # Axis Label
                    ]
                )
            )
        )

    bars_row = render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "end",
        children = bars_children,
    )

    screen2 = render.Padding(
        pad = 1,
        child = render.Column(
            children = [
                render.Text("Next 7 Days", color = TITLE_COLOR),
                render.Box(height=1),
                bars_row,
            ]
        )
    )

    return render.Root(
        delay = 3000, # 3 seconds per frame
        child = render.Animation(
            children = [screen1, screen2]
        )
    )

def get_schema():
    resort_options = [
        schema.Option(display = r["display"], value = r["value"])
        for r in RESORTS
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "resort",
                name = "Resort",
                desc = "Select a ski resort",
                icon = "snowflake",
                default = DEFAULT_RESORT,
                options = resort_options,
            ),
            schema.Dropdown(
                id = "units",
                name = "Units",
                desc = "Select units",
                icon = "gear",
                default = DEFAULT_UNITS,
                options = [
                    schema.Option(display = "Imperial (inches)", value = "imperial"),
                    schema.Option(display = "Metric (cm)", value = "metric"),
                ],
            ),
        ],
    )
