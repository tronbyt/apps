"""
Applet: Surflive Proxy
Summary: Live surf conditions (via proxy)
Description: Shows the current surf conditions for a surf spot, plus a short
    multi-day wave-height forecast, routed through a self-hosted proxy sidecar
    that handles Surfline's Cloudflare bot protection.
Author: tronbyt
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/wave.png", WAVE_ICON_ASSET = "file")
load("images/wind.png", WIND_ICON_ASSET = "file")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

#### CONFIG THINGS

WAVE_ICON = WAVE_ICON_ASSET.readall()
WIND_ICON = WIND_ICON_ASSET.readall()
WAVE_ICON_WIDTH = 10

# FORECAST API (fetched indirectly through the proxy sidecar)
SURFLINE_FORECASTS_URL = "https://services.surfline.com/kbyg/spots/forecasts"

# 15 minutes
ENABLE_CACHE = True
CACHE_TTL_SECONDS = 60 * 15

# How many 3-hourly forecast entries to request. 5 days * 8 entries/day (every
# 3 hours) comfortably covers FORECAST_DAYS below with room to spare, and is
# one single fetch shared by both the "current conditions" screen and the
# "daily forecast" screen -- we don't make a second request for the forecast.
FORECAST_REQUEST_DAYS = 6
FORECAST_INTERVAL_HOURS = 3

# Number of daily columns to show on the forecast screen. 5 fits comfortably
# on a 64px-wide display (~12-13px per column); 8 does not.
FORECAST_DAYS = 5

# Single-pixel grid line color between/around forecast day cells.
FORECAST_BORDER_COLOR = "#666"

# Day-abbreviation labels. Most days are unambiguous with a single letter;
# Tue/Thu (both start with "T") and Sat/Sun (both start with "S") need a
# second letter to stay distinguishable.
DAY_ABBREV = {
    "Mon": "M",
    "Tue": "Tu",
    "Wed": "W",
    "Thu": "Th",
    "Fri": "F",
    "Sat": "Sa",
    "Sun": "Su",
}

# Solid 5x5-pixel arrow glyphs, one per 45-degree compass octant (index 0 =
# N/0deg, 1 = NE/45deg, ... 7 = NW/315deg, clockwise -- matching how a
# compass reads on screen). Each glyph is a proper chevron-tipped arrow: a
# pointed head (a peak, or an offset diagonal tip for the intercardinals)
# leading a straight shaft/tail. The previous 4x4 version's flare-vs-taper
# shapes read as an ambiguous double-sided "L" at this size; a real pointed
# tip with a centered shaft is unambiguous even for opposite directions like
# N vs S. Growing from 4x4 to 5x5 costs 1px of height, which fits by
# consuming a pixel of previously-unused center-alignment slack in the wind
# row -- no other layout size changed.
WIND_ARROW_GLYPHS = [
    [
        # N (0deg): peaked head on top, straight shaft down the middle
        [0, 1, 1, 1, 0],
        [1, 1, 1, 1, 1],
        [0, 0, 1, 0, 0],
        [0, 0, 1, 0, 0],
        [0, 0, 1, 0, 0],
    ],
    [
        # NE (45deg): tip at top-right, shaft running to bottom-left
        [0, 0, 1, 1, 1],
        [0, 0, 0, 1, 1],
        [0, 0, 1, 0, 1],
        [0, 1, 0, 0, 0],
        [1, 0, 0, 0, 0],
    ],
    [
        # E (90deg): peaked head on the right, straight shaft down the middle
        [0, 0, 0, 1, 0],
        [0, 0, 0, 0, 1],
        [1, 1, 1, 1, 1],
        [0, 0, 0, 0, 1],
        [0, 0, 0, 1, 0],
    ],
    [
        # SE (135deg): tip at bottom-right, shaft running to top-left
        [1, 0, 0, 0, 0],
        [0, 1, 0, 0, 0],
        [0, 0, 1, 0, 1],
        [0, 0, 0, 1, 1],
        [0, 0, 1, 1, 1],
    ],
    [
        # S (180deg): peaked head on the bottom, straight shaft up the middle
        [0, 0, 1, 0, 0],
        [0, 0, 1, 0, 0],
        [0, 0, 1, 0, 0],
        [1, 1, 1, 1, 1],
        [0, 1, 1, 1, 0],
    ],
    [
        # SW (225deg): tip at bottom-left, shaft running to top-right
        [0, 0, 0, 0, 1],
        [0, 0, 0, 1, 0],
        [1, 0, 1, 0, 0],
        [1, 1, 0, 0, 0],
        [1, 1, 1, 0, 0],
    ],
    [
        # W (270deg): peaked head on the left, straight shaft down the middle
        [0, 1, 0, 0, 0],
        [1, 0, 0, 0, 0],
        [1, 1, 1, 1, 1],
        [1, 0, 0, 0, 0],
        [0, 1, 0, 0, 0],
    ],
    [
        # NW (315deg): tip at top-left, shaft running to bottom-right
        [1, 1, 1, 0, 0],
        [1, 1, 0, 0, 0],
        [1, 0, 1, 0, 0],
        [0, 0, 0, 1, 0],
        [0, 0, 0, 0, 1],
    ],
]

# Wave-height color thresholds (inclusive lower bound), in feet. Ordered
# ascending; the last matching threshold wins. When metric display is
# selected these are converted to meters via FT_TO_M so the color coding
# stays meaningful in either unit system.
WAVE_HEIGHT_COLOR_THRESHOLDS_FT = [
    (0, "#fff"),
    (2, "#0c0"),
    (4, "#ff0"),
    (7, "#f80"),
    (10, "#f00"),
]

# Unit conversion factors. Surfline's API reports wave height in feet and
# wind speed in knots regardless of query params, so all metric/imperial
# display conversion happens client-side from those native units.
FT_TO_M = 0.3048
KNOTS_TO_MPH = 1.15078
KNOTS_TO_KMH = 1.852

# How long each screen (current conditions, then forecast) is shown before
# cycling to the next, in milliseconds.
SCREEN_DELAY_MS = 4000

# DEFAULTS
DEFAULT_SPOT_NAME = "Pacific Beach"
DEFAULT_SPOT_ID = "5842041f4e65fad6a7708841"

# Assumes the sidecar is deployed alongside tronbyt-server on the same Docker
# network/compose project, reachable by container name (e.g.
# http://tronbyt-sidecar:8080). There's no programmatic default for this
# (see schema below and main()): the app skips all network calls entirely
# until proxy_url is explicitly configured, since an unresolvable/
# unreachable host makes pixlet's http.get() raise a hard, uncatchable
# Starlark error (unlike a non-2xx response, which this app already handles
# gracefully) -- this would otherwise crash `pixlet check` and any
# unconfigured install.

def main(config):
    proxy_url = config.get("proxy_url", "").strip().rstrip("/")
    proxy_token = config.get("proxy_token", "")

    spot_id = config.get("spot_id", DEFAULT_SPOT_ID).strip()
    if not spot_id:
        spot_id = DEFAULT_SPOT_ID

    spot_name = config.get("spot_name", "").strip()
    if not spot_name:
        spot_name = DEFAULT_SPOT_NAME

    use_wave_height = (config.get("use_wave_height") == "true")
    forecast_use_wave_height = (config.get("forecast_use_wave_height") == "true")
    metric = (config.get("metric") == "true")
    tzname = config.get("$tz", "UTC")

    # No proxy_url configured yet: skip the network call entirely rather than
    # falling back to a guessed hostname. An unconfigured/unreachable host
    # makes http.get() raise a hard Starlark error (not a catchable non-2xx
    # response), which would otherwise crash `pixlet check` and any
    # freshly-installed, not-yet-configured app instance.
    if not proxy_url:
        return render_setup_prompt(spot_name)

    conditions = get_conditions(proxy_url, proxy_token, spot_id, tzname, metric, forecast_use_wave_height)

    print("spot_name={} conditions={}".format(spot_name, json.encode(conditions)))

    if conditions == None:
        return render.Root(
            child = render.Column(
                expanded = True,
                main_align = "start",
                cross_align = "center",
                children = [
                    render_spot_name(spot_name),
                    render.Row(expanded = True, main_align = "center", children = [render.Text(content = "ERROR", color = "#f00")]),
                ],
            ),
        )

    # skip render if waves are smaller than specified in config min_height.
    # min_height's dropdown is always expressed in feet, so gate on the raw
    # (pre-unit-conversion) feet values regardless of the display unit.
    if config.bool("use_wave_height"):
        if conditions["wave"]["max_ft"] < int(config.get("min_height", "0")):
            return []
    elif conditions["wave"]["swell_height_ft"] < int(config.get("min_height", "0")):
        return []

    screens = [render_current_screen(spot_name, conditions, use_wave_height)]
    if conditions["daily_forecast"]:
        screens.append(render_forecast_screen(conditions["daily_forecast"], metric))

    return render.Root(
        delay = SCREEN_DELAY_MS,
        child = render.Animation(children = screens),
    )

def render_setup_prompt(spot_name):
    """Shown instead of live conditions when proxy_url hasn't been
    configured yet -- no network call is made in this case (see main()).
    """
    return render.Root(
        child = render.Box(
            width = canvas.width(),
            height = canvas.height(),
            color = "#000",
            child = render.Column(
                expanded = True,
                main_align = "start",
                cross_align = "center",
                children = [
                    render_spot_name(spot_name),
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        children = [
                            render.WrappedText(
                                content = "Set Proxy Sidecar URL in config",
                                width = canvas.width() - 4,
                                align = "center",
                                font = "tom-thumb",
                                color = "#f80",
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def render_current_screen(spot_name, conditions, use_wave_height):
    # Wrapped in an opaque, full-canvas Box: each Animation frame is encoded
    # cropped to its own visible-content bounding box, and by default frames
    # are composited with dispose=none/blend=yes, so a frame that only fills
    # part of the canvas lets the *previous* frame's pixels show through
    # underneath it. Forcing every pixel opaque (even the background)
    # guarantees each screen fully replaces the last one.
    return render.Box(
        width = canvas.width(),
        height = canvas.height(),
        color = "#000",
        child = render.Column(
            expanded = True,
            main_align = "start",
            cross_align = "center",
            children = [
                render_spot_name(spot_name),
                render_surf_and_period(conditions["wave"], use_wave_height),
                render_wind(conditions["wind"]),
            ],
        ),
    )

def render_spot_name(spot_name, font = ""):
    text = render.Text(content = spot_name, font = font) if font else render.Text(content = spot_name)
    return render.Row(expanded = True, main_align = "center", children = [text])

def render_surf_and_period(wave, use_wave_height):
    if use_wave_height:
        content = "{min}-{max}{wave_height_unit} @ {period}s".format(**wave)
    else:
        content = "{swell_height}{wave_height_unit} @ {period}s".format(**wave)

    if size_str(content) >= canvas.width() - WAVE_ICON_WIDTH - 1:
        render_content = render.Marquee(
            width = canvas.width() - WAVE_ICON_WIDTH - 1,
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
                    content = "{direction} {speed}{unit}".format(**wind),
                ),
            ),
        ],
    )

    return render.Padding(
        pad = (0, 2, 0, 0),
        child = row,
    )

def render_forecast_screen(daily_forecast, metric):
    # The spot name is intentionally omitted here: it's already shown
    # prominently on the current-conditions screen a moment earlier in the
    # same render cycle, so dropping it here frees vertical space for the
    # wind row (arrow + speed stacked) above the forecast grid.
    return render.Box(
        width = canvas.width(),
        height = canvas.height(),
        color = "#000",
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render_forecast_grid(daily_forecast, metric),
            ],
        ),
    )

def render_forecast_grid(daily_forecast, metric):
    """Render the daily forecast as a bordered grid: one column per day, a
    single-pixel border around the whole grid, and a single shared
    single-pixel divider between adjacent day cells (not a double line).
    A wind row (direction arrow + speed) sits directly above the grid,
    sharing the same per-day column widths so each arrow lines up over its
    day's cell, immediately on top of the grid's top border.
    """
    n = len(daily_forecast)
    row_height = 18
    wind_row_height = 12

    # Distribute available width evenly across cells, with (n + 1) 1px
    # divider lines (left edge, between each pair of cells, right edge)
    # subtracted first. Any remainder pixels are handed to the first few
    # cells so the grid's total width matches canvas.width() exactly.
    divider_count = n + 1
    available = canvas.width() - divider_count
    base_width = available // n
    extra = available % n
    cell_widths = [base_width + 1 if i < extra else base_width for i in range(n)]

    # The wind row reuses the exact same column widths as the grid below it,
    # but with plain (invisible) 1px spacers instead of visible divider
    # lines, so only the grid itself is bordered.
    wind_row_children = [render.Box(width = 1, height = wind_row_height, color = "#000")]
    for i, day in enumerate(daily_forecast):
        wind_row_children.append(render_wind_cell(day, cell_widths[i], wind_row_height))
        wind_row_children.append(render.Box(width = 1, height = wind_row_height, color = "#000"))

    row_children = [render.Box(width = 1, height = row_height, color = FORECAST_BORDER_COLOR)]
    for i, day in enumerate(daily_forecast):
        row_children.append(render_forecast_cell(day, cell_widths[i], row_height, metric))
        row_children.append(render.Box(width = 1, height = row_height, color = FORECAST_BORDER_COLOR))

    grid_width = canvas.width()

    return render.Column(
        cross_align = "start",
        children = [
            render.Row(children = wind_row_children),
            render.Box(width = grid_width, height = 1, color = FORECAST_BORDER_COLOR),
            render.Row(children = row_children),
            render.Box(width = grid_width, height = 1, color = FORECAST_BORDER_COLOR),
        ],
    )

def render_wind_cell(day, width, height):
    return render.Box(
        width = width,
        height = height,
        color = "#000",
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                wind_arrow(day["wind_direction_deg"]),
                render.Box(width = 1, height = 1, color = "#000"),  # nudge the speed number down 1px, off the arrow
                render.Text(content = str(day["wind_speed"]), font = "tom-thumb", color = "#999"),
            ],
        ),
    )

def wind_arrow(direction_deg):
    """A solid 5x5-pixel arrow glyph snapped to the nearest of 8 compass
    directions (N, NE, E, SE, S, SW, W, NW). Each glyph is a chevron-tipped
    arrow with a pointed head and a straight shaft -- that's what makes each
    of the 8 glyphs, especially opposite directions, clearly distinguishable
    at this size. All pixels solid white, no greys/anti-aliasing; drawn as a
    fixed lookup table of 5x5 boolean grids rather than a rotated polygon
    (which read as an ambiguous blob) or the earlier flare/taper design
    (which read as an ambiguous double-sided "L").
    """
    octant = int(math.round(direction_deg / 45.0)) % 8
    grid = WIND_ARROW_GLYPHS[octant]
    rows = []
    for row in grid:
        cells = [render.Box(width = 1, height = 1, color = "#fff" if v else "#000") for v in row]
        rows.append(render.Row(children = cells))
    return render.Column(children = rows)

def render_forecast_cell(day, width, height, metric):
    return render.Box(
        width = width,
        height = height,
        color = "#000",
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(content = day["label"], font = "tom-thumb"),
                render.Text(content = height_display_text(day["height"], width, metric), font = "tom-thumb", color = wave_height_color(day["height"], metric)),
                render.Text(content = "{}s".format(day["period"]), font = "tom-thumb", color = "#999"),
            ],
        ),
    )

def height_display_text(height, cell_width, metric):
    """Append a unit suffix to the daily height number: `"` (feet/inches
    mark) for imperial, `m` for metric. A single digit plus suffix (8px in
    tom-thumb) always fits even in the narrowest 11px day column, but a
    2-digit height plus suffix needs 12px, which only the 3 wider day
    columns have -- so the suffix is dropped for 2-digit heights in the 2
    narrower (11px) columns to avoid clipping.
    """
    text = str(height)
    unit = "m" if metric else "\""
    needed_width = 8 if len(text) == 1 else 12
    if needed_width <= cell_width:
        return text + unit
    return text

def wave_height_color(height, metric):
    """Map a swell height to a color, per WAVE_HEIGHT_COLOR_THRESHOLDS_FT
    (ascending; the last threshold at or below `height` wins). Thresholds
    are converted to meters first when displaying in metric, so the
    color-coding stays meaningful in either unit system.
    """
    thresholds = WAVE_HEIGHT_COLOR_THRESHOLDS_FT
    if metric:
        thresholds = [(threshold * FT_TO_M, color) for threshold, color in WAVE_HEIGHT_COLOR_THRESHOLDS_FT]

    color = thresholds[0][1]
    for threshold, threshold_color in thresholds:
        if height >= threshold:
            color = threshold_color
    return color

def size_str(s):
    """Return the size in pixels for a given string. This depends on the font used."""
    return len(s) * 5

def proxy_fetch(proxy_url, proxy_token, target_url):
    """Fetch a target URL through the proxy sidecar's generic /fetch endpoint.

    The sidecar handles Cloudflare bot-protection (TLS fingerprinting and, if
    necessary, an on-demand headless-browser challenge solve) and returns the
    upstream JSON response unmodified.
    """
    headers = {}
    if proxy_token:
        headers["X-Proxy-Token"] = proxy_token

    fetch_url = "{proxy_url}/fetch?url={target_url}".format(
        proxy_url = proxy_url,
        target_url = humanize.url_encode(target_url),
    )

    r = http.get(fetch_url, headers = headers, ttl_seconds = CACHE_TTL_SECONDS)

    if r.status_code != 200:
        print("Error fetching via proxy: status={} url={}".format(r.status_code, target_url))
        return None

    return r.json()

def get_conditions(proxy_url, proxy_token, spot_id, tzname, metric, forecast_use_wave_height):
    wave = get_wave_forecast(proxy_url, proxy_token, spot_id, tzname, metric, forecast_use_wave_height)
    wind = get_wind_forecast(proxy_url, proxy_token, spot_id, tzname, metric)

    if wave == None or wind == None:
        return None

    # Merge the per-day wind (direction/speed) into the wave-derived daily
    # forecast by calendar date, rather than assuming the two API responses'
    # entries line up positionally.
    daily_forecast = []
    for day in wave["daily_forecast"]:
        wind_day = wind["daily"].get(day["date_key"], {"speed": 0, "direction_deg": 0})
        daily_forecast.append({
            "label": day["label"],
            "height": day["height"],
            "period": day["period"],
            "wind_speed": wind_day["speed"],
            "wind_direction_deg": wind_day["direction_deg"],
        })

    conditions = {
        "wave": wave["current"],
        "daily_forecast": daily_forecast,
        "wind": wind["current"],
    }

    return conditions

def get_wave_forecast(proxy_url, proxy_token, spot_id, tzname, metric, forecast_use_wave_height):
    data = get_forecast(proxy_url, proxy_token, "wave", spot_id, days = FORECAST_REQUEST_DAYS, interval_hours = FORECAST_INTERVAL_HOURS)
    if data == None:
        return None

    entries = data["data"]["wave"]

    current = wave_entry_to_current(get_closest_forecast(entries), metric)
    daily_forecast = build_daily_forecast(entries, tzname, metric, forecast_use_wave_height)

    return {
        "current": current,
        "daily_forecast": daily_forecast,
    }

def wave_entry_to_current(entry, metric):
    surf = entry["surf"]
    dominant_swell = get_dominant_swell(entry)

    min_ft = int(math.round(surf["min"]))
    max_ft = int(math.round(surf["max"]))
    swell_height_ft = round1(dominant_swell["height"])

    min_disp, unit = convert_height(min_ft, metric)
    max_disp, _ = convert_height(max_ft, metric)
    swell_disp, _ = convert_height(swell_height_ft, metric)

    return dict(
        ts = int(math.round(entry["timestamp"])),
        period = int(math.round(dominant_swell["period"])),
        min = round1(min_disp) if metric else int(math.round(min_disp)),
        max = round1(max_disp) if metric else int(math.round(max_disp)),
        swell_height = round1(swell_disp),
        wave_height_unit = unit,
        # Raw (pre-conversion, feet) values, kept only so main()'s
        # min_height gate -- whose dropdown is always expressed in feet --
        # stays correct regardless of the selected display unit.
        max_ft = max_ft,
        swell_height_ft = swell_height_ft,
    )

def convert_height(value_ft, metric):
    """Convert a height in feet to the configured display unit."""
    if metric:
        return value_ft * FT_TO_M, "m"
    return value_ft, "ft"

def convert_speed(value_knots, metric):
    """Convert a speed in knots (Surfline's native wind speed unit) to the
    configured display unit."""
    if metric:
        return value_knots * KNOTS_TO_KMH, "km/h"
    return value_knots * KNOTS_TO_MPH, "mph"

def round1(value):
    """Round to one decimal place."""
    return math.round(value * 10) / 10

def get_dominant_swell(entry):
    """Return the dominant swell for a wave forecast entry (highest
    optimalScore among swells with nonzero height), or a zeroed placeholder
    if none qualify. Shared by the current-conditions and daily-forecast
    period calculations so both use the same "which swell matters" logic.
    """

    # Remove any height=0 swells, not sure why the forecast has these
    swells = [s for s in entry["swells"] if s["height"]]

    if len(swells) == 0:
        return {
            "height": 0,
            "period": 0,
        }

    # Sort by optimalScore
    return sorted(swells, key = lambda s: -s["optimalScore"])[0]

def build_daily_forecast(entries, tzname, metric, use_wave_height):
    """Group the raw 3-hourly wave entries into up to FORECAST_DAYS daily
    buckets (in the device's timezone), each holding that day's peak swell
    height AND peak wave (surf) height independently (whichever 3-hourly
    entry has the higher value for each, not necessarily the same entry),
    plus the period of the dominant swell. `use_wave_height` selects which
    of the two peak heights is exposed as the displayed "height" field. The
    forecast API returns entries in chronological order, so the first
    FORECAST_DAYS distinct calendar days encountered are today plus the next
    few days.
    """
    daily_by_key = {}
    order = []

    for entry in entries:
        t = time.from_timestamp(int(entry["timestamp"])).in_location(tzname)
        date_key = t.format("2006-01-02")
        dominant_swell = get_dominant_swell(entry)
        swell_height_ft = dominant_swell["height"]
        wave_height_ft = entry["surf"]["max"]
        period = int(math.round(dominant_swell["period"]))

        if date_key not in daily_by_key:
            daily_by_key[date_key] = {
                "label": DAY_ABBREV.get(t.format("Mon"), t.format("Mon")),
                "swell_height_ft": swell_height_ft,
                "wave_height_ft": wave_height_ft,
                "period": period,
            }
            order.append(date_key)
        else:
            if swell_height_ft > daily_by_key[date_key]["swell_height_ft"]:
                daily_by_key[date_key]["swell_height_ft"] = swell_height_ft
                daily_by_key[date_key]["period"] = period
            if wave_height_ft > daily_by_key[date_key]["wave_height_ft"]:
                daily_by_key[date_key]["wave_height_ft"] = wave_height_ft

    daily_forecast = []
    for date_key in order[:FORECAST_DAYS]:
        d = daily_by_key[date_key]
        height_ft = d["wave_height_ft"] if use_wave_height else d["swell_height_ft"]
        height_disp, _ = convert_height(height_ft, metric)
        daily_forecast.append({
            "date_key": date_key,
            "label": d["label"],
            "height": int(math.round(height_disp)),
            "period": d["period"],
        })

    return daily_forecast

def get_wind_forecast(proxy_url, proxy_token, spot_id, tzname, metric):
    data = get_forecast(proxy_url, proxy_token, "wind", spot_id, days = FORECAST_REQUEST_DAYS, interval_hours = FORECAST_INTERVAL_HOURS)
    if data == None:
        return None

    entries = data["data"]["wind"]
    closest = get_closest_forecast(entries)
    speed_disp, unit = convert_speed(closest["speed"], metric)

    current = {
        "ts": int(math.round(closest["timestamp"])),
        "score": closest["optimalScore"],
        "unit": unit,
        "speed": int(math.round(speed_disp)),
        "direction": direction_to_human(closest["direction"]),
        "direction_deg": closest["direction"],
    }

    return {
        "current": current,
        "daily": build_daily_wind(entries, tzname, metric),
    }

def build_daily_wind(entries, tzname, metric):
    """Group the raw wind entries into daily buckets keyed by calendar date
    (in the device's timezone), each holding the direction/speed at that
    day's peak wind speed. Returned as a date_key -> {speed, direction_deg}
    dict so callers can merge it into the wave-derived daily forecast by
    date rather than assuming the two API responses line up positionally.
    """
    daily_by_key = {}

    for entry in entries:
        t = time.from_timestamp(int(entry["timestamp"])).in_location(tzname)
        date_key = t.format("2006-01-02")
        speed_knots = entry["speed"]

        if date_key not in daily_by_key or speed_knots > daily_by_key[date_key]["speed_knots"]:
            daily_by_key[date_key] = {"speed_knots": speed_knots, "direction_deg": entry["direction"]}

    result = {}
    for date_key, d in daily_by_key.items():
        speed_disp, _ = convert_speed(d["speed_knots"], metric)
        result[date_key] = {"speed": int(math.round(speed_disp)), "direction_deg": d["direction_deg"]}

    return result

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

def get_forecast(proxy_url, proxy_token, f_type, spot_id, days, interval_hours):
    """Return the raw forecast payload for a given type, fetched through the
    proxy sidecar.
    """

    # Surfline's edge WAF currently 404s the literal, well-known lowercase
    # "wave" path (a commonly scraped endpoint) while still serving identical
    # data under any other casing, e.g. "Wave". The JSON payload keys are
    # unaffected by this and remain lowercase, so only the URL path segment
    # needs the override -- f_type (used below for the response/dict key)
    # stays lowercase.
    path_type = "Wave" if f_type == "wave" else f_type

    url = "{base_url}/{path_type}?spotId={spot_id}&intervalHours={interval_hours}&days={days}".format(
        base_url = SURFLINE_FORECASTS_URL,
        path_type = path_type,
        spot_id = spot_id,
        interval_hours = interval_hours,
        days = days,
    )

    data = proxy_fetch(proxy_url, proxy_token, url)
    if data == None:
        print("Error fetching {f_type} forecast for spot_id={spot_id}".format(f_type = f_type, spot_id = spot_id))
        return None

    return data

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
            schema.Text(
                id = "proxy_url",
                name = "Proxy Sidecar URL",
                desc = "Base URL of the surfline-proxy sidecar (required), e.g. http://tronbyt-sidecar:8080",
                icon = "server",
                default = "",
            ),
            schema.Text(
                id = "proxy_token",
                name = "Proxy Auth Token",
                desc = "Optional shared secret expected by the sidecar (X-Proxy-Token header)",
                icon = "key",
                default = "",
                secret = True,
            ),
            schema.Text(
                id = "spot_id",
                name = "Spot ID",
                desc = "Surfline spot ID. Find it in the spot's surfline.com URL, e.g. " +
                       "surfline.com/surf-report/pacific-beach/5842041f4e65fad6a7708841 " +
                       "-> 5842041f4e65fad6a7708841",
                icon = "compass",
                default = DEFAULT_SPOT_ID,
            ),
            schema.Text(
                id = "spot_name",
                name = "Display Name",
                icon = "compass",
                desc = "Name to display on the screen (does not need to match Surfline)",
                default = DEFAULT_SPOT_NAME,
            ),
            schema.Toggle(
                id = "use_wave_height",
                name = "Display Surf Height",
                desc = "Display the surf or swell height (off=swell)",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "forecast_use_wave_height",
                name = "Forecast: Display Surf Height",
                desc = "In the multi-day forecast grid, display each day's peak surf or swell height (off=swell)",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "metric",
                name = "Metric Units",
                desc = "Show wave height in meters and wind speed in km/h instead of feet/mph",
                icon = "rulerHorizontal",
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
