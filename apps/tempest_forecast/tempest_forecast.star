load("http.star", "http")

# --- ASSET LOADING ---
load("images/cloudy.png", CLOUDY_ASSET = "file")
load("images/foggy.png", FOGGY_ASSET = "file")
load("images/haily.png", HAILY_ASSET = "file")
load("images/rainy.png", RAINY_ASSET = "file")
load("images/sleety.png", SLEETY_ASSET = "file")
load("images/snowy.png", SNOWY_ASSET = "file")
load("images/sunny.png", SUNNY_ASSET = "file")
load("images/sunnyish.png", SUNNYISH_ASSET = "file")
load("images/thundery.png", THUNDERY_ASSET = "file")
load("images/tornady.png", TORNADY_ASSET = "file")
load("images/windy.png", WINDY_ASSET = "file")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

ICON_DATA = {
    "clear": SUNNY_ASSET,
    "partly": SUNNYISH_ASSET,
    "cloudy": CLOUDY_ASSET,
    "rain": RAINY_ASSET,
    "snow": SNOWY_ASSET,
    "sleet": SLEETY_ASSET,
    "thunder": THUNDERY_ASSET,
    "fog": FOGGY_ASSET,
    "hail": HAILY_ASSET,
    "wind": WINDY_ASSET,
    "tornado": TORNADY_ASSET,
}

# --- CONFIGURATION ---
TEMPEST_FORECAST_URL = "https://swd.weatherflow.com/swd/rest/better_forecast?station_id={station_id}&token={token}"

# --- HELPER FUNCTIONS ---
def _convert_temp(temp_c, units):
    if units == "F":
        return (temp_c * 1.8) + 32
    return temp_c

def get_icon_asset(icon_text):
    for key, data in ICON_DATA.items():
        if key in icon_text:
            return data
    return ICON_DATA["clear"]

def main(config):
    # --- TRONBYT DETECTION ---
    # Automatically detects if the display is Wide (128x64)
    is_wide = canvas.is2x()

    station_id = config.get("station")
    token = config.get("token")
    units = config.get("units", "F")

    if not station_id or not token:
        return render.Root(
            child = render.WrappedText("Please configure Station ID and Token."),
        )

    if "." in station_id:
        station_id = station_id.split(".")[0]

    # --- FETCH DATA ---
    res = http.get(url = TEMPEST_FORECAST_URL.format(station_id = station_id, token = token), ttl_seconds = 300)
    if res.status_code != 200:
        return render.Root(child = render.WrappedText("Err: %d" % res.status_code))

    data = res.json()
    daily_forecast = data.get("forecast", {}).get("daily", [])

    if len(daily_forecast) < 2:
        return render.Root(child = render.Text("No Data"))

    # Always show 3 days, regardless of screen size
    next_days = daily_forecast[1:4]

    # --- RENDER LOGIC ---
    if is_wide:
        return render_wide_layout(next_days, units)
    else:
        return render_standard_layout(next_days, units)

# --- LAYOUT: STANDARD (64x32) ---
def render_standard_layout(days_data, units):
    forecast_columns = []
    divider = render.Column(children = [render.Box(width = 1, height = 32, color = "#5A5A5A")])

    for i, day_data in enumerate(days_data):
        timestamp = day_data.get("day_start_local", 0)
        day_name = time.from_timestamp(int(timestamp)).format("Mon")

        high = _convert_temp(day_data.get("air_temp_high", 0), units)
        low = _convert_temp(day_data.get("air_temp_low", 0), units)

        high_str = "H:%d" % int(math.round(high))
        low_str = "L:%d" % int(math.round(low))
        icon_asset = get_icon_asset(day_data.get("icon", "clear-day"))

        col_children = [
            render.Image(width = 13, height = 13, src = icon_asset),
            render.Text(day_name.upper(), font = "CG-pixel-3x5-mono", color = "#ffffff"),
            render.Box(width = 1, height = 2),
            render.Text(high_str, font = "tom-thumb", color = "#FA8072"),
            render.Text(low_str, font = "tom-thumb", color = "#0096FF"),
        ]

        forecast_columns.append(
            render.Column(children = col_children, main_align = "center", cross_align = "center"),
        )

        if i < len(days_data) - 1:
            forecast_columns.append(divider)

    return render.Root(
        child = render.Stack(
            children = [
                render.Row(children = forecast_columns, main_align = "space_evenly", expanded = True),
            ],
        ),
    )

# --- LAYOUT: WIDE (128x64) ---
def render_wide_layout(days_data, units):
    forecast_columns = []

    # Divider is taller (64px) and thicker (optional, but keeping 1px is cleaner)
    divider = render.Column(children = [render.Box(width = 1, height = 64, color = "#5A5A5A")])

    for i, day_data in enumerate(days_data):
        timestamp = day_data.get("day_start_local", 0)
        day_name = time.from_timestamp(int(timestamp)).format("Monday")  # Full name fits better!

        high = day_data.get("air_temp_high", 0)
        low = day_data.get("air_temp_low", 0)

        if units == "F":
            high = _convert_temp(day_data.get("air_temp_high", 0), units)
            low = _convert_temp(day_data.get("air_temp_low", 0), units)

        high_str = "H:%d" % int(math.round(high))
        low_str = "L:%d" % int(math.round(low))
        icon_asset = get_icon_asset(day_data.get("icon", "clear-day"))

        col_children = [
            # SCALED UP ICON: 26x26 (2x the original 13x13)
            render.Image(width = 26, height = 26, src = icon_asset),

            # LARGER FONT: terminus-12
            render.Text(day_name, font = "terminus-12", color = "#ffffff"),
            render.Box(width = 1, height = 2),  # Padding

            # LARGER TEMPS
            render.Text(high_str, font = "terminus-12", color = "#FA8072"),
            render.Text(low_str, font = "terminus-12", color = "#0096FF"),
        ]

        forecast_columns.append(
            render.Column(children = col_children, main_align = "center", cross_align = "center"),
        )

        if i < len(days_data) - 1:
            forecast_columns.append(divider)

    return render.Root(
        child = render.Stack(
            children = [
                render.Row(children = forecast_columns, main_align = "space_evenly", expanded = True),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "station",
                name = "Station ID",
                desc = "Tempest Station ID",
                icon = "locationDot",
            ),
            schema.Text(
                id = "token",
                name = "Token",
                desc = "Tempest API Token",
                icon = "key",
				secret = True,
            ),
            schema.Dropdown(
                id = "units",
                name = "Units",
                desc = "Temperature Unit",
                icon = "ruler",
                default = "F",
                options = [
                    schema.Option(display = "Fahrenheit", value = "F"),
                    schema.Option(display = "Celsius", value = "C"),
                ],
            ),
        ],
    )
