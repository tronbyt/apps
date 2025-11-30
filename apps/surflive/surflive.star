"""
Applet: Surflive
Summary: Live surf conditions
Description: Shows the current surf conditions for a surf spot.
Author: rcarton
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/img_bb48d7f8.png", IMG_bb48d7f8_ASSET = "file")

#### CONFIG THINGS

# DISPLAY
WIDTH = 64
HEIGHT = 32

WAVE_ICON = IMG_bb48d7f8_ASSET.readall():
        spot = json.decode(config.get("spot"))
        spot_name = spot["display"]
        spot_id = spot["value"]
    else:
        spot_name = DEFAULT_SPOT_NAME
        spot_id = DEFAULT_SPOT_ID

    if config.get("spot_name"):
        spot_name = config.get("spot_name")

    use_wave_height = (config.get("use_wave_height") == "true")

    conditions = get_conditions(spot_id)

    print("spot_name={} conditions={}".format(spot_name, json.encode(conditions)))

    if conditions != None:
        top_level = [
            render_spot_name(spot_name),
            render_surf_and_period(conditions["wave"], use_wave_height),
            render_wind(conditions["wind"]),
        ]
    else:
        top_level = [
            render_spot_name(spot_name),
            render.Row(expanded = True, main_align = "center", children = [render.Text(content = "ERROR", color = "#f00")]),
        ]

    # skip render if waves are smaller than specified in config min_height
    if config.bool("use_wave_height"):
        if conditions["wave"]["max"] < int(config.get("min_height", "0")):
            return []
    elif conditions["wave"]["swell_height"] < int(config.get("min_height", "0")):
        return []

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "start",
            cross_align = "center",
            children = top_level,
        ),
    )

def render_spot_name(spot_name):
    return render.Row(expanded = True, main_align = "center", children = [render.Text(content = spot_name)])

def render_surf_and_period(wave, use_wave_height):
    if use_wave_height:
        content = "{min}-{max}{wave_height_unit} @ {period}s".format(**wave)
    else:
        content = "{swell_height}{wave_height_unit} @ {period}s".format(**wave)

    if size_str(content) >= WIDTH - WAVE_ICON_WIDTH - 1:
        render_content = render.Marquee(
            width = WIDTH - WAVE_ICON_WIDTH - 1,
            child = render.Text(content = content),
        )
    else:
        render_content = render.Text(content = content)

    row = render.Row(
        cross_align = "center",
        main_align = "center",
        expanded = True,
        children = [
            render.Padding(pad = (0, 0, 1, 0), child = render.Image(src = WAVE_ICON)),
            render.Padding(
                pad = (0, 1, 0, 0),
                child = render_content,
            ),
        ],
    )

    return render.Padding(
        pad = (0, 2, 0, 0),
        child = row,
    )

def render_wind(wind):
    row = render.Row(
        cross_align = "center",
        main_align = "center",
        expanded = True,
        children = [
            render.Padding(pad = (0, 0, 2, 0), child = render.Image(src = WIND_ICON)),
            render.Padding(
                pad = (0, 1, 0, 0),
                child = render.Text(
                    content = "{direction} {speed}kts".format(**wind),
                ),
            ),
        ],
    )

    return render.Padding(
        pad = (0, 2, 0, 0),
        child = row,
    )

def size_str(s):
    """Return the size in pixels for a given string. This depends on the font used."""
    return len(s) * 5

def get_cache_name(key):
    return "SURFLIVE_{key}".format(key = key)

def get_conditions(spot_id):
    cache_key = get_cache_name("conditions_{spot_id}".format(spot_id = spot_id))
    cached_conditions = cache.get(cache_key)

    if ENABLE_CACHE and cached_conditions != None:
        print("Using cached conditions, key={cache_key}".format(cache_key = cache_key))
        return json.decode(cached_conditions)

    wave = get_wave_forecast(spot_id)
    wind = get_wind_forecast(spot_id)

    if wave == None or wind == None:
        return None

    conditions = {
        "wave": wave,
        "wind": get_wind_forecast(spot_id),
    }

    # TODO: Determine if this cache call can be converted to the new HTTP cache.
    cache.set(cache_key, json.encode(conditions), ttl_seconds = CACHE_TTL_SECONDS)
    return conditions

def get_wave_forecast(spot_id):
    wf = get_forecast("wave", spot_id)

    if wf == None:
        return None

    units = wf["units"]
    surf = wf["wave"]["surf"]

    # Find the dominant swells
    # Remove any height=0 swells, not sure why the forecast has these
    swells = [s for s in wf["wave"]["swells"] if s["height"]]

    if len(swells) == 0:
        dominant_swell = {
            "height": 0,
            "period": 0,
        }
    else:
        # Sort by optimalScore
        dominant_swell = sorted(swells, key = lambda s: -s["optimalScore"])[0]

    # Round to the first digit
    swell_height = math.round(dominant_swell["height"]) + math.round((dominant_swell["height"] - math.round(dominant_swell["height"])) * 10) / 10

    return dict(
        ts = int(math.round(wf["wave"]["timestamp"])),
        period = int(math.round(dominant_swell["period"])),
        min = int(math.round(surf["min"])),
        max = int(math.round(surf["max"])),
        swell_height = swell_height,
        wave_height_unit = units["waveHeight"].lower(),
    )

def get_wind_forecast(spot_id):
    wf = get_forecast("wind", spot_id)

    if wf == None:
        return None

    units = wf["units"]
    wind = wf["wind"]

    return {
        "ts": int(math.round(wind["timestamp"])),
        "score": wind["optimalScore"],
        "unit": units["windSpeed"].lower(),
        "speed": int(math.round(wind["speed"])),
        "direction": direction_to_human(wind["direction"]),
        "direction_deg": wind["direction"],
    }

def direction_to_human(num):
    """Convert a compass angle to a human wind or swell direction."""
    val = int((num / 22.5) + 0.5)
    arr = [
        "N",
        "NNE",
        "NE",
        "ENE",
        "E",
        "ESE",
        "SE",
        "SSE",
        "S",
        "SSW",
        "SW",
        "WSW",
        "W",
        "WNW",
        "NW",
        "NNW",
    ]
    return arr[(val % 16)]

def get_forecast(f_type, spot_id):
    """Return the forecast for a given type"""

    url = "{base_url}/{f_type}?spotId={spot_id}&intervalHours=1&days=2".format(
        base_url = SURFLINE_FORECASTS_URL,
        f_type = f_type,
        spot_id = spot_id,
    )
    r = http.get(url)

    if r.status_code != 200:
        print("Error fetching {f_type} forecast for spot_id={spot_id}".format(f_type = f_type, spot_id = spot_id))
        return None

    data = r.json()
    units = data["associated"]["units"]
    forecast = get_closest_forecast(data["data"][f_type])

    return {
        "units": units,
        f_type: forecast,
    }

def get_closest_forecast(forecasts):
    """Go through the forecasts until we find the closest timestamp."""

    ts_now = time.now().unix
    last_wf = None
    curr_min = None
    for wf in forecasts:
        ts = wf["timestamp"]
        ts_diff = math.fabs(ts_now - ts)
        if curr_min != None and ts_diff > curr_min:
            return last_wf
        curr_min = ts_diff
        last_wf = wf
    fail("No forecast found")

def search_spots(query):
    """Return a list of spots queried by name"""
    if len(query) < 3:
        return []

    url = SEARCH_URL.format(
        query = query,
    )

    r = http.get(url)

    if r.status_code != 200:
        fail("Error fetching spots, query={query}".format(query = query))

    return r.json()["spots"]

def search_handler(query):
    spots = search_spots(query)
    return [schema.Option(display = s["name"], value = s["_id"]) for s in spots]

def get_schema():
    min_height_options = [
        schema.Option(display = "0 ft", value = "0"),
        schema.Option(display = "1 ft", value = "1"),
        schema.Option(display = "2 ft", value = "2"),
        schema.Option(display = "3 ft", value = "3"),
        schema.Option(display = "4 ft", value = "4"),
        schema.Option(display = "6 ft", value = "6"),
        schema.Option(display = "8 ft", value = "8"),
        schema.Option(display = "10 ft", value = "10"),
        schema.Option(display = "15 ft", value = "15"),
        schema.Option(display = "20 ft", value = "20"),
        schema.Option(display = "25 ft", value = "25"),
        schema.Option(display = "30 ft", value = "30"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "spot",
                name = "Spot Name",
                desc = "Spot Name in Surfline",
                icon = "compass",
                handler = search_handler,
            ),
            schema.Text(
                id = "spot_name",
                name = "Display Name",
                icon = "compass",
                desc = "Optional spot name to display",
                default = "",
            ),
            schema.Toggle(
                id = "use_wave_height",
                name = "Display Surf Height",
                desc = "Display the surf or swell height (off=swell)",
                icon = "gear",
                default = False,
            ),
            schema.Dropdown(
                id = "min_height",
                name = "Mininum Size",
                icon = "gear",
                desc = "Minimum wave size to display",
                options = min_height_options,
                default = "0",
            ),
        ],
    )
