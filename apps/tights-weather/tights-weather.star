load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")

def main(config):
    # Check for 2x mode
    is_2x = canvas.is2x()
    width, height = canvas.size()

    # Get location from schema or use default (San Francisco)
    location_json = config.get("location")
    if location_json:
        location = json.decode(location_json)
        lat = location.get("lat")
        lon = location.get("lng")
    else:
        # Default: San Francisco
        lat = "37.7749"
        lon = "-122.4194"

    # Fetch NOAA grid point info (cached for 24h as it doesn't change often)
    point_cache_key = "noaa_point_%s_%s" % (lat, lon)
    forecast_url = cache.get(point_cache_key)
    if not forecast_url:
        points_url = "https://api.weather.gov/points/%s,%s" % (lat, lon)

        # NOAA API requires a User-Agent
        resp = http.get(points_url, headers = {"User-Agent": "TidbytApp/TightsWeather"})
        if resp.status_code == 404:
            return render.Root(child = render.Text("NOAA: US Only", color = "#f00"))
        if resp.status_code != 200:
            return render.Root(child = render.Text("NOAA Err: %d" % resp.status_code))

        data = resp.json()
        forecast_url = data.get("properties", {}).get("forecastHourly")
        if forecast_url:
            cache.set(point_cache_key, forecast_url, ttl_seconds = 86400)

    if not forecast_url:
        return render.Root(child = render.Text("No Forecast URL"))

    # Fetch hourly forecast
    resp = http.get(forecast_url, headers = {"User-Agent": "TidbytApp/TightsWeather"})
    if resp.status_code != 200:
        return render.Root(child = render.Text("Forecast Error: %d" % resp.status_code))

    forecast_data = resp.json()
    periods = forecast_data.get("properties", {}).get("periods", [])
    if not periods:
        return render.Root(child = render.Text("No Data"))

    # Get current period
    current = periods[0]
    temp = int(current.get("temperature"))
    unit = current.get("temperatureUnit")
    wind = current.get("windSpeed")

    # Logic for tights with more flexibility and whimsy
    if temp >= 72:
        msg = "Free the legs!"
        color = "#fffd82"  # Yellow-ish
        icon = "😎"
    elif temp >= 66:
        msg = "Bare or sheer? Toss a coin!"
        color = "#ffe5aa"  # Peach-ish
        icon = "🎲"
    elif temp >= 60:
        msg = "Feel fancy in sheer tights!"
        color = "#ffcfd2"  # Pink/Skin tone
        icon = "💃"
    elif temp >= 52:
        msg = "Sheer or opaque? Dealer's choice!"
        color = "#d0d0d0"  # Light grey
        icon = "🃏"
    elif temp >= 45:
        msg = "Stay sleek in opaque tights!"
        color = "#a0a0a0"  # Grey
        icon = "🦵"
    else:
        msg = "Keep it cozy in fleece tights!"
        color = "#b185db"  # Purple-ish
        icon = "🧶"

    # Fonts based on resolution
    header_font = "tb-8" if is_2x else "CG-pixel-3x5-mono"
    body_font = "terminus-18" if is_2x else "tb-8"
    icon_font = "terminus-18" if is_2x else "tb-8"

    return render.Root(
        child = render.Box(
            color = "#000",
            width = width,
            height = height,
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Box(
                        color = "#222",
                        width = width,
                        height = 14 if is_2x else 7,
                        child = render.Text(content = "TIGHTS WEATHER?", color = "#ffcfd2", font = header_font),
                    ),
                    render.Row(
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(content = icon, font = icon_font),
                            render.Padding(
                                pad = (4 if is_2x else 2, 0, 0, 0),
                                child = render.Text(content = "%d°%s" % (temp, unit), font = body_font, color = "#ffffff"),
                            ),
                            render.Padding(
                                pad = (8 if is_2x else 4, 0, 0, 0),
                                child = render.Text(content = wind, font = body_font, color = "#99f"),
                            ),
                        ],
                    ),
                    render.Padding(
                        pad = (0, 0, 0, 2 if is_2x else 1),
                        child = render.Marquee(
                            width = width,
                            child = render.Text(content = msg, color = color, font = body_font),
                        ),
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for weather forecast",
                icon = "locationDot",
            ),
        ],
    )
