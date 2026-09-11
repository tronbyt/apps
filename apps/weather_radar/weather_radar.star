"""
Applet: Weather Radar
Summary: Live weather radar sweeps
Description: Display animated precipitation radar and atmospheric sweeps with vibrant color scaling.
Author: brombomb
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

WEATHER_MAPS_URL = "https://api.rainviewer.com/public/weather-maps.json"
IMAGE_URL_LAYOUT = "{host}{path}/256/{zoom}/{lat}/{lng}/{color}/0_{snow}.png"
OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lng}&current=temperature_2m,precipitation,wind_speed_10m,wind_gusts_10m&wind_speed_unit=mph&temperature_unit=fahrenheit"

DEFAULT_LOCATION = """{
  "lat": "33.7490",
  "lng": "-84.3880",
  "locality": "Atlanta",
  "timezone": "America/New_York"
}"""

# Zoom definitions: (zoom_level, display_label, precision)
# Note: RainViewer API v2 enforces a maximum zoom level of 7.
# For sub-75mi views (15-40 mi), we request zoom 7 and center-crop/scale
# the 256x256 tile on the display canvas.
ZOOM_CONFIGS = {
    "10": {"api_zoom": "7", "label": "18mi", "acc": "#.##", "scale": 4},
    "8": {"api_zoom": "7", "label": "40mi", "acc": "#.##", "scale": 2},
    "7": {"api_zoom": "7", "label": "75mi", "acc": "#.##", "scale": 1},
    "6": {"api_zoom": "6", "label": "150mi", "acc": "#.#", "scale": 1},
    "5": {"api_zoom": "5", "label": "300mi", "acc": "#.#", "scale": 1},
    "4": {"api_zoom": "4", "label": "600mi", "acc": "#.#", "scale": 1},
    "3": {"api_zoom": "3", "label": "1200mi", "acc": "#.0", "scale": 1},
}

# Color palettes for Windy-style bottom scale bar
COLOR_PALETTES = {
    # NEXRAD Level III Doppler: Light Green -> Green -> Yellow -> Orange -> Red -> Dark Red -> Magenta -> White
    "6": ["#00e400", "#009600", "#ffff00", "#ff7e00", "#ff0000", "#990000", "#ff00ff", "#ffffff"],
    # Universal Blue: Navy -> Teal -> Cyan -> Lime -> Yellow -> Red -> Violet
    "2": ["#004488", "#0088cc", "#00ccdd", "#77eebb", "#ffdd00", "#ff6600", "#ee0000", "#9900aa"],
    # Rainbow SELEX: Blue -> Cyan -> Green -> Yellow -> Orange -> Red -> Magenta
    "7": ["#0000ff", "#00aaff", "#00ff88", "#ffff00", "#ff8800", "#ff0000", "#cc00cc", "#ffffff"],
    # The Weather Channel (TWC)
    "4": ["#00bbff", "#00dd88", "#22ee00", "#ffff00", "#ff9900", "#ff0000", "#cc0099", "#ffffff"],
    # TITAN
    "3": ["#0000aa", "#0066cc", "#00ccff", "#00ff00", "#ffff00", "#ff6600", "#ff0000", "#ffffff"],
    # Dark Sky
    "8": ["#1f4287", "#278ea5", "#21e6c1", "#e8ffff", "#f5b971", "#f07865", "#d63447", "#ffffff"],
}

def get_live_weather(lat, lng):
    """Fetch live ambient weather metrics from Open-Meteo."""
    url = OPEN_METEO_URL.format(lat = lat, lng = lng)
    res = http.get(url, ttl_seconds = 300)
    if res.status_code != 200:
        return None
    data = res.json()
    return data.get("current", {})

def fetch_radar_manifest():
    """Fetch recent radar frames metadata from RainViewer."""
    res = http.get(WEATHER_MAPS_URL, ttl_seconds = 60)
    if res.status_code != 200:
        return None
    return res.json()

def fetch_frame_image(host, path, zoom, lat, lng, color_scheme, snow):
    """Fetch single radar tile from RainViewer."""
    url = IMAGE_URL_LAYOUT.format(
        host = host,
        path = path,
        zoom = zoom,
        lat = lat,
        lng = lng,
        color = color_scheme,
        snow = "1" if snow else "0",
    )

    # Cache past frames for 1 hour
    res = http.get(url, ttl_seconds = 3600)
    if res.status_code != 200:
        return None
    return res.body()

def render_color_scale(palette, width, scale):
    """Render a Windy-style color intensity scale bar across the bottom."""
    num_colors = len(palette)
    box_width = width // num_colors
    remainder = width - (box_width * num_colors)
    height = 2 * scale

    boxes = []
    for i in range(num_colors):
        extra = 1 if i < remainder else 0
        w = box_width + extra
        boxes.append(render.Box(
            width = w,
            height = height,
            color = palette[i],
        ))

    return render.Row(
        children = boxes,
    )

def render_reticle(width, height, scale):
    """Render a clean location reticle/crosshair at the exact center."""
    reticle_size = 5 * scale
    offset_x = (width - reticle_size) // 2
    offset_y = (height - reticle_size) // 2
    return render.Padding(
        pad = (offset_x, offset_y, 0, 0),
        child = render.Stack(
            children = [
                # Horizontal tick
                render.Padding(
                    pad = (0, (reticle_size - (1 * scale)) // 2, 0, 0),
                    child = render.Box(width = reticle_size, height = 1 * scale, color = "#ff3344dd"),
                ),
                # Vertical tick
                render.Padding(
                    pad = ((reticle_size - (1 * scale)) // 2, 0, 0, 0),
                    child = render.Box(width = 1 * scale, height = reticle_size, color = "#ff3344dd"),
                ),
                # Center bright pip
                render.Padding(
                    pad = ((reticle_size - (1 * scale)) // 2, (reticle_size - (1 * scale)) // 2, 0, 0),
                    child = render.Box(width = 1 * scale, height = 1 * scale, color = "#ffffff"),
                ),
            ],
        ),
    )

def render_hud(location_text, zoom_text, telemetry_text, scale, is_2x):
    """Render the top semi-transparent HUD banner with location and reading."""
    font = "tb-8" if is_2x else "tom-thumb"
    tag_font = "tom-thumb" if is_2x else "tom-thumb"
    pad_h = 2 * scale
    pad_v = 1 * scale

    left_items = [
        render.Text(
            content = location_text,
            color = "#ffffff",
            font = font,
            offset = -1,
        ),
    ]

    if zoom_text:
        left_items.append(
            render.Padding(
                pad = (2 * scale, 0, 0, 0),
                child = render.Text(
                    content = zoom_text,
                    color = "#77aacc",
                    font = tag_font,
                    offset = -1,
                ),
            ),
        )

    right_items = []
    if telemetry_text:
        right_items.append(
            render.Text(
                content = telemetry_text,
                color = "#ffea00",
                font = font,
                offset = -1,
            ),
        )

    return render.Padding(
        pad = (pad_h, pad_v, pad_h, 0),
        child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Row(
                    cross_align = "center",
                    children = left_items,
                ),
                render.Row(
                    cross_align = "center",
                    children = right_items,
                ),
            ],
        ),
    )

def main(config):
    width, height = canvas.size()
    scale = 2 if canvas.is2x() else 1
    is_2x = canvas.is2x()

    # Parse config options
    loc_json = config.get("location", DEFAULT_LOCATION)
    loc_data = json.decode(loc_json) if loc_json else json.decode(DEFAULT_LOCATION)
    raw_lat = float(loc_data.get("lat", "33.7490"))
    raw_lng = float(loc_data.get("lng", "-84.3880"))
    locality = loc_data.get("locality", "Radar")

    custom_name = config.get("location_name", "").strip()
    loc_name = custom_name if custom_name else locality
    loc_name_disp = loc_name.upper()[:10]

    zoom = config.get("zoom", "6")
    zoom_meta = ZOOM_CONFIGS.get(zoom, ZOOM_CONFIGS["6"])
    api_zoom = zoom_meta.get("api_zoom", "6")
    zoom_scale = zoom_meta.get("scale", 1)
    lat = humanize.float(zoom_meta["acc"], raw_lat)
    lng = humanize.float(zoom_meta["acc"], raw_lng)

    color_scheme = config.get("color_scheme", "6")
    palette = COLOR_PALETTES.get(color_scheme, COLOR_PALETTES["6"])

    snow = config.bool("snow", True)
    show_legend = config.bool("show_legend", True)
    show_reticle = config.bool("show_reticle", True)
    show_hud = config.bool("show_hud", True)
    only_precip = config.bool("only_precip", False)
    frame_speed = int(config.get("frame_speed", "350"))

    # Fetch live weather (wind / temp) for HUD
    telemetry_text = ""
    weather_info = get_live_weather(raw_lat, raw_lng)
    if weather_info:
        wind = weather_info.get("wind_speed_10m")
        temp = weather_info.get("temperature_2m")
        if wind != None:
            telemetry_text = "%dmph" % int(wind)
        elif temp != None:
            telemetry_text = "%d°" % int(temp)

    # Fetch radar images
    manifest = fetch_radar_manifest()
    frames_raw = []

    if manifest and "radar" in manifest and "past" in manifest["radar"]:
        host = manifest["host"]
        past_list = manifest["radar"]["past"]

        # Take the most recent 3 frames
        recent_frames = past_list[-3:] if len(past_list) >= 3 else past_list
        for f in recent_frames:
            img_bytes = fetch_frame_image(
                host = host,
                path = f["path"],
                zoom = api_zoom,
                lat = lat,
                lng = lng,
                color_scheme = color_scheme,
                snow = snow,
            )
            if img_bytes:
                frames_raw.append((f, img_bytes))

    # If network/API failed or no frames returned, skip rendering
    if not frames_raw:
        return []

    # Check precipitation detection (RainViewer empty tiles are <= 400 bytes)
    if only_precip:
        has_precip = any([len(img) > 450 for (_, img) in frames_raw])
        if not has_precip:
            return []

    # Assemble animated frames
    # Image is square (64x64 or scaled larger when center-cropped for close views).
    # Center the square map tile precisely inside the 64x32 or 128x64 canvas.
    tile_size = 64 * scale * zoom_scale
    tile_pad_left = (width - tile_size) // 2
    tile_pad_top = (height - tile_size) // 2

    rendered_frames = []
    total_frames = len(frames_raw)

    for idx, (frame_obj, img_bytes) in enumerate(frames_raw):
        # Time badge if no live wind
        time_badge = telemetry_text
        if not time_badge and frame_obj.get("time", 0) > 0:
            frame_time = time.from_timestamp(int(frame_obj["time"]))
            time_badge = frame_time.format("15:04")

        # Relative indicator e.g. "1/3", "2/3", "NOW"
        if not time_badge:
            time_badge = "NOW" if idx == total_frames - 1 else "-%dm" % ((total_frames - 1 - idx) * 5)

        layers = [
            # Solid deep dark radar background
            render.Box(width = width, height = height, color = "#04060b"),
            # Centered radar map tile
            render.Box(
                width = width,
                height = height,
                child = render.Padding(
                    pad = (tile_pad_left, tile_pad_top, 0, 0),
                    child = render.Image(
                        src = img_bytes,
                        width = tile_size,
                        height = tile_size,
                    ),
                ),
            ),
        ]

        # Reticle
        if show_reticle:
            layers.append(render_reticle(width, height, scale))

        # Top HUD overlay
        if show_hud:
            layers.append(
                render.Column(
                    children = [
                        render.Box(
                            width = width,
                            height = 8 * scale,
                            color = "#04060bcc",
                            child = render_hud(
                                location_text = loc_name_disp,
                                zoom_text = zoom_meta["label"],
                                telemetry_text = time_badge,
                                scale = scale,
                                is_2x = is_2x,
                            ),
                        ),
                    ],
                ),
            )

        # Bottom Windy-style color scale bar
        if show_legend:
            layers.append(
                render.Column(
                    main_align = "end",
                    children = [
                        render_color_scale(palette, width, scale),
                    ],
                ),
            )

        rendered_frames.append(render.Stack(children = layers))

    return render.Root(
        delay = frame_speed,
        child = render.Animation(children = rendered_frames),
    )

def get_schema():
    zoom_options = [
        schema.Option(display = "Neighborhood (~15-20 mi, Zoom 10)", value = "10"),
        schema.Option(display = "Local / City (~35-40 mi, Zoom 8)", value = "8"),
        schema.Option(display = "Metro (~75 mi, Zoom 7)", value = "7"),
        schema.Option(display = "Regional / State (~150 mi, Zoom 6)", value = "6"),
        schema.Option(display = "Sub-Regional (~300 mi, Zoom 5)", value = "5"),
        schema.Option(display = "Wide Region (~600 mi, Zoom 4)", value = "4"),
        schema.Option(display = "Continental (~1200 mi, Zoom 3)", value = "3"),
    ]

    color_options = [
        schema.Option(display = "NEXRAD Level III (Doppler)", value = "6"),
        schema.Option(display = "Universal Blue (Modern)", value = "2"),
        schema.Option(display = "Rainbow SELEX-IS (Windy style)", value = "7"),
        schema.Option(display = "The Weather Channel (TWC)", value = "4"),
        schema.Option(display = "TITAN (High Contrast)", value = "3"),
        schema.Option(display = "Dark Sky", value = "8"),
    ]

    speed_options = [
        schema.Option(display = "Fast (200 ms)", value = "200"),
        schema.Option(display = "Normal (350 ms)", value = "350"),
        schema.Option(display = "Slow (600 ms)", value = "600"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for radar scan",
                icon = "locationDot",
            ),
            schema.Text(
                id = "location_name",
                name = "Location Name",
                desc = "Custom display name (leave empty for city)",
                icon = "tag",
            ),
            schema.Dropdown(
                id = "zoom",
                name = "Radar Zoom",
                desc = "Geographic coverage radius",
                icon = "magnifyingGlassPlus",
                default = zoom_options[3].value,
                options = zoom_options,
            ),
            schema.Dropdown(
                id = "color_scheme",
                name = "Color Scheme",
                desc = "Precipitation color palette",
                icon = "palette",
                default = color_options[0].value,
                options = color_options,
            ),
            schema.Dropdown(
                id = "frame_speed",
                name = "Animation Speed",
                desc = "Speed of radar sweep animation",
                icon = "gaugeHigh",
                default = speed_options[1].value,
                options = speed_options,
            ),
            schema.Toggle(
                id = "snow",
                name = "Distinguish Snow",
                desc = "Display snowfall in separate shades from rain",
                icon = "snowflake",
                default = True,
            ),
            schema.Toggle(
                id = "show_legend",
                name = "Show Color Scale",
                desc = "Show Windy-style intensity scale along bottom",
                icon = "chartSimple",
                default = True,
            ),
            schema.Toggle(
                id = "show_reticle",
                name = "Show Center Reticle",
                desc = "Display crosshair marker at your exact location",
                icon = "crosshairs",
                default = True,
            ),
            schema.Toggle(
                id = "show_hud",
                name = "Show Top Info Bar",
                desc = "Display location name, zoom, and live metrics",
                icon = "circleInfo",
                default = True,
            ),
            schema.Toggle(
                id = "only_precip",
                name = "Only When Raining / Snowing",
                desc = "Skip rendering when no precipitation is on radar",
                icon = "cloudShowersHeavy",
                default = False,
            ),
        ],
    )
