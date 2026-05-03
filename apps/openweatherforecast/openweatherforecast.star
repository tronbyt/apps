"""
Applet: OpenWeaather Forecast
Summary: 3-Day Weather Forecast
Description: V0.3 Display 3-day weather forecast using OpenWeather One Call API 3.0.
Author: colin_is
"""

# V0.1: Initial release using One Call API 3.0.
# V0.2: Switched to /data/2.5/forecast (free plan). Aggregates 3-hour slots into
#        daily summaries: min/max temp across all slots, icon from midday slot.
# V0.3: Switched back to One Call API 3.0 for true daily temp.min / temp.max.

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

OW_GEO_URL = "http://api.openweathermap.org/geo/1.0/zip"
OW_FORECAST_URL = "https://api.openweathermap.org/data/3.0/onecall"
OW_ICON_URL = "https://openweathermap.org/img/wn/%s.png"

DAY_NAMES = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

GEO_CACHE_TTL = 86400  # 24 hours — zip codes rarely change
FORECAST_CACHE_TTL = 3600  # 1 hour — minimize OW API calls
ICON_CACHE_TTL = 86400  # 24 hours — OW icons are static

COLUMN_WIDTH = 21  # 64px display / 3 columns ≈ 21px
ICON_SIZE = 12
FONT1 = "tom-thumb"  # 5x8 pixel font;
FONT2 = "CG-pixel-3x5-mono"  # 3x5 compact pixel font; ~19px wide for "H:99°"

def day_name_from_unix(ts):
    """Return 3-letter day abbreviation (e.g. 'Mon') from a Unix UTC timestamp.

    The Unix epoch (ts=0) was a Thursday. Using Sun=0 convention:
    Thu=4, so offset by +4 before taking mod 7.
    """
    day_index = (int(ts) // 86400 + 4) % 7
    return DAY_NAMES[day_index]

def get_lat_lon(api_key, zip_code):
    """Geocode a US ZIP code to (lat, lon) via OW Geocoding API.

    Cached for 24 hours since zip-to-coordinate mapping is stable.
    Returns (lat, lon) or (None, None) on error.
    """
    cache_key = "owf_geo_" + zip_code
    cached = cache.get(cache_key)
    if cached:
        coords = json.decode(cached)
        return coords["lat"], coords["lon"]

    resp = http.get(OW_GEO_URL, params = {
        "zip": zip_code + ",US",
        "appid": api_key,
    })
    if resp.status_code != 200:
        print("OW geocoding error:", resp.status_code, resp.body())
        return None, None

    data = json.decode(resp.body())
    lat = data.get("lat")
    lon = data.get("lon")
    if lat == None or lon == None:
        return None, None

    cache.set(cache_key, json.encode({"lat": lat, "lon": lon}), ttl_seconds = GEO_CACHE_TTL)
    return lat, lon

def get_forecast(api_key, lat, lon, units):
    """Fetch 3-day forecast from OW One Call API 3.0.

    Uses the daily array which provides true calendar-day temp.min / temp.max
    (not derived from 3-hour slots). Returns a list of 3 dicts, or None on error.
    Cached for 1 hour (cache key includes units to avoid stale unit mismatch).
    """
    cache_key = "owf_daily_" + str(lat) + "_" + str(lon) + "_" + units
    cached = cache.get(cache_key)
    if cached:
        return json.decode(cached)

    resp = http.get(OW_FORECAST_URL, params = {
        "lat": str(lat),
        "lon": str(lon),
        "units": units,
        "exclude": "current,minutely,hourly,alerts",
        "appid": api_key,
    })
    if resp.status_code != 200:
        print("OW forecast error:", resp.status_code, resp.body())
        return None

    items = json.decode(resp.body()).get("daily", [])
    if len(items) < 3:
        return None

    daily = []
    for i in range(3):
        d = items[i]
        temp = d.get("temp", {})
        weather_list = d.get("weather", [])
        icon_code = weather_list[0].get("icon", "01d") if len(weather_list) > 0 else "01d"

        daily.append({
            "dt": d["dt"],
            "temp_min": temp.get("min", 0),
            "temp_max": temp.get("max", 0),
            "icon": icon_code,
        })

    cache.set(cache_key, json.encode(daily), ttl_seconds = FORECAST_CACHE_TTL)
    return daily

def get_icon(icon_code):
    """Fetch and cache an OW weather icon PNG.

    Renders the image at 15×15 inside a 12×12 Box to crop OW whitespace while
    keeping the icon centered. Returns a blank Box on failure.
    """
    cache_key = "owf_icon_" + icon_code
    cached = cache.get(cache_key)
    if cached:
        img = render.Image(src = base64.decode(cached), width = 15, height = 15)
        return render.Box(width = ICON_SIZE, height = ICON_SIZE, child = img)

    resp = http.get(OW_ICON_URL % icon_code)
    if resp.status_code != 200:
        return render.Box(width = ICON_SIZE, height = ICON_SIZE - 4)

    cache.set(cache_key, base64.encode(resp.body()), ttl_seconds = ICON_CACHE_TTL)
    img = render.Image(src = resp.body(), width = 15, height = 15)
    return render.Box(width = ICON_SIZE, height = ICON_SIZE, child = img)

def render_day_col(day):
    """Render a single day's forecast column.

    Layout (top to bottom, icon flush to top, 1px gaps between text lines):
      - Weather icon (ICON_SIZE x ICON_SIZE)
      - Day abbreviation (e.g. Mon)
      - 1px spacer
      - H:max° (e.g. H:57°)
      - 1px spacer
      - L:min° (e.g. L:25°)
    """
    day_name = day_name_from_unix(day["dt"])
    temp_max = int(day["temp_max"])
    temp_min = int(day["temp_min"])

    return render.Box(
        width = COLUMN_WIDTH,
        child = render.Column(
            main_align = "start",
            cross_align = "center",
            children = [
                render.Text(content = day_name, font = FONT2),
                get_icon(day["icon"]),
                render.Box(height = 1),
                render.Text(content = "H:" + str(temp_max) + "°", font = FONT1, color = "#f0f70e"),
                render.Box(height = 1),
                render.Text(content = "L:" + str(temp_min) + "°", font = FONT1, color = "#1187f2"),
            ],
        ),
    )

def error_display(msg):
    """Return a scrolling error marquee."""
    return render.Root(
        child = render.Marquee(
            width = 64,
            child = render.Text(msg),
            offset_start = 32,
            offset_end = 32,
        ),
    )

def main(config):
    api_key = config.get("openweather_api_key", "")
    zip_code = config.get("zip_code", "")

    if not api_key:
        return error_display("Add OpenWeather API key in settings")
    if not zip_code:
        return error_display("Add ZIP code in settings")

    lat, lon = get_lat_lon(api_key, zip_code)
    if lat == None or lon == None:
        return error_display("ZIP lookup failed — check API key & ZIP")

    units = "metric" if config.bool("units_celsius", False) else "imperial"

    daily = get_forecast(api_key, lat, lon, units)
    if daily == None or len(daily) < 3:
        return error_display("Forecast unavailable")

    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "start",
            children = [
                render_day_col(daily[0]),
                render_day_col(daily[1]),
                render_day_col(daily[2]),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "openweather_api_key",
                name = "OpenWeather API Key",
                desc = "Your API key from https://home.openweathermap.org/api_keys",
                icon = "key",
            ),
            schema.Text(
                id = "zip_code",
                name = "ZIP Code",
                desc = "US ZIP code for your forecast location (e.g., 90210)",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "units_celsius",
                name = "Use Celsius",
                desc = "Display temperatures in °C instead of °F",
                icon = "temperatureHalf",
                default = False,
            ),
        ],
    )
