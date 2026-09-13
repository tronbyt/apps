"""
Applet: UV Daily
Summary: Hourly UV distribution
Description: The day's UV index as a color-coded hourly distribution: one bar per daylight hour colored by its EPA category, framed by sunrise and sunset, with the peak's time under its own bar. Data by Open-Meteo, UV from CAMS ENSEMBLE.
Author: iicky

One bar per daylight hour, colored by its EPA UV Index category, so the shape of
the day reads at a glance: when UV ramps up, where it peaks, and how much of the
clear-sky potential the cloud cover is taking away (drawn as a dim ghost behind
each bar). A white tick marks the current hour.

Hourly uv_index and uv_index_clear_sky come from Open-Meteo's air-quality API,
and daily sunrise/sunset from its forecast API. Neither needs a key. The two
calls are deliberate: the forecast API's own uv_index is very nearly identical
to its uv_index_clear_sky, so sourcing UV from there instead would silently
flatten the cloud-attenuation ghost to nothing.

Attribution is a license condition, not a courtesy: Open-Meteo's air-quality API
requires all users to credit both Open-Meteo and the CAMS ENSEMBLE data
provider. The credit is carried in the manifest description.
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

AIR_QUALITY_URL = "https://air-quality-api.open-meteo.com/v1/air-quality"
FORECAST_URL = "https://api.open-meteo.com/v1/forecast"

# Cache lifetimes are set by how often each source actually changes, not by how
# often the app redraws. The UV series comes from a model published roughly
# twice a day, and sunrise/sunset is astronomical: it shifts about a minute per
# day, so refetching it twice a day is already generous. Together these keep the
# app to ~10 requests a day instead of two on every redraw.
UV_TTL_SECONDS = 3 * 60 * 60
SUN_TTL_SECONDS = 12 * 60 * 60

# Every dimension is expressed at 1x and multiplied by SCALE, so a 2x device
# (128x64) gets the same layout at double the resolution rather than an upscaled
# 1x render. The row budget sums to 32 at 1x and therefore to HEIGHT at any
# scale. Requires supports2x in the manifest, which is what makes pixlet hand
# this app a 2x canvas at all.
WIDTH, HEIGHT = canvas.size()
SCALE = 2 if canvas.is2x() else 1

# Text rows are sized to the font's full line height rather than its glyph box,
# or the Box clips the labels' bottom pixel row. TOP_PAD plus the axis row's own
# spare pixel keep the panel from reading edge-to-edge.
TOP_PAD = 2 * SCALE
HEADER_H = 6 * SCALE
GAP_ABOVE_CHART = 1 * SCALE
CHART_H = 15 * SCALE
MARK_H = 1 * SCALE
GAP_BELOW_MARK = 1 * SCALE
AXIS_H = 6 * SCALE

# Side margin kept clear of bars so the chart never runs into the panel edge.
MARGIN_X = 2 * SCALE

# Per-hour column width bounds. The cap stops a short winter day from drawing
# absurdly fat bars; the floor keeps a long polar day legible.
MAX_PITCH = 6 * SCALE
MIN_PITCH = 2 * SCALE

# Fonts are chosen per scale rather than letting a 1x font be pixel-doubled, so
# 2x text is genuinely crisp. tom-thumb/CG-pixel-3x5-mono are 6px and 5px tall;
# terminus-12 and 6x10 are their closest doubles.
HEADER_FONT = "terminus-12" if SCALE == 2 else "tom-thumb"
AXIS_FONT = "6x10" if SCALE == 2 else "CG-pixel-3x5-mono"

# EPA UV Index categories as (exclusive upper bound, color, short label). The
# bounds sit on .5 so a rounded display value never disagrees with the color.
UV_BANDS = [
    (2.5, "#3ea72d", "LOW"),
    (5.5, "#fff300", "MOD"),
    (7.5, "#f18b00", "HIGH"),
    (10.5, "#e53210", "V.HI"),
    (99.0, "#b54eff", "EXTR"),
]

# Chart ceilings, snapped to the EPA band edges. A full-height bar therefore
# always means "topped out its category" rather than an arbitrary autoscale, and
# 6 acts as a floor so a calm day stays visibly small. Height is only ever
# comparable within a ceiling; color is what carries the absolute reading.
SCALE_STEPS = [6.0, 8.0, 11.0]

GHOST_COLOR = "#333333"

# White is reserved for the things worth finding first: the "UV" label, the
# peak's time, and the tick on the current hour. Everything else that is not a
# bar sits in the muted gray so it reads as chrome.
ACCENT_COLOR = "#ffffff"
MUTED_COLOR = "#9a9a9a"
NOW_COLOR = "#ffffff"
BAR_GAP = 1 * SCALE

# Below this a reading is treated as no UV: too small to round to 1, and not
# worth labeling as a peak.
UV_EPSILON = 0.05

# Widest advance of the axis font, used to place labels without measuring text:
# CG-pixel-3x5-mono advances 4px and paints 3, 6x10 advances 6. Narrow glyphs
# such as ":" advance less, so a run of n characters is at most this wide, and
# over-estimating only ever buys extra clearance.
AXIS_CHAR_W = 6 if SCALE == 2 else 4

# Clear pixels required between the peak label and an edge label before both are
# drawn; below this the peak label is nudged, or an edge label dropped.
LABEL_CLEARANCE = 4 * SCALE

# Shape of the synthetic day drawn before a location is configured. No real
# coordinates are assumed anywhere: a hard-coded city would render an
# authoritative-looking forecast that is wrong for everybody who lives
# elsewhere, so the unconfigured state is labeled instead.
DEMO_TAG = "DEMO"
DEMO_FIRST_HOUR = 6
DEMO_LAST_HOUR = 19
DEMO_PEAK_HOUR = 13
DEMO_PEAK_UV = 7.0
DEMO_GHOST_RATIO = 1.1

def ceil_int(value):
    truncated = int(value)
    if value > truncated:
        return truncated + 1
    return truncated

def round_int(value):
    return int(value + 0.5)

def as_float(value):
    """Open-Meteo leaves gaps in a series as null; treat those as no UV."""
    if value == None:
        return 0.0
    return float(value)

def uv_band(uv):
    for bound, color, label in UV_BANDS:
        if uv < bound:
            return color, label
    return UV_BANDS[-1][1], UV_BANDS[-1][2]

def hour_label(hour, clock_24h):
    if clock_24h:
        return str(hour)
    suffix = "P" if hour >= 12 else "A"
    display = hour % 12
    if display == 0:
        display = 12
    return str(display) + suffix

def clock_label(stamp, clock_24h):
    """'2026-08-23T06:14' -> '6:14', or '18:13' on a 24-hour clock.

    Hours are never zero-padded: the four pixels a leading zero costs are the
    difference between fitting the peak label between sunrise and sunset and
    dropping it on a 13-hour day. In 12-hour mode the meridiem is implied by
    position, sunrise being at the chart's left edge and sunset at its right.
    """
    hour = int(stamp[11:13])
    minute = stamp[14:16]
    if clock_24h:
        return str(hour) + ":" + minute
    display = hour % 12
    if display == 0:
        display = 12
    return str(display) + ":" + minute

def date_label(date, date_order):
    """'2026-08-24' -> '8/24' or '24/8'."""
    month = int(date[5:7])
    day = int(date[8:10])
    if date_order == "dmy":
        return str(day) + "/" + str(month)
    return str(month) + "/" + str(day)

def label_width(text):
    return AXIS_CHAR_W * len(text) - 1

def read_options(config):
    return {
        "show_ghost": config.bool("show_clear_sky", True),
        "clock_24h": config.bool("clock_24h", False),
        "date_order": config.str("date_order", "mdy"),
    }

def fetch_hourly(lat, lng):
    """Two days of hourly UV so the app stays useful after today's sunset."""
    resp = http.get(
        AIR_QUALITY_URL,
        params = {
            "latitude": lat,
            "longitude": lng,
            "hourly": "uv_index,uv_index_clear_sky",
            "timezone": "auto",
            "forecast_days": "2",
        },
        ttl_seconds = UV_TTL_SECONDS,
    )
    if resp.status_code != 200:
        return None
    return resp.json()

def fetch_sun(lat, lng):
    """Sunrise/sunset per local date. Returns {} on failure and skips dates with
    null times (polar day/night), which makes the chart fall back to bounding
    itself by the hours that carry any UV."""
    resp = http.get(
        FORECAST_URL,
        params = {
            "latitude": lat,
            "longitude": lng,
            "daily": "sunrise,sunset",
            "timezone": "auto",
            "forecast_days": "2",
        },
        ttl_seconds = SUN_TTL_SECONDS,
    )
    if resp.status_code != 200:
        return {}

    daily = resp.json().get("daily", {})
    dates = daily.get("time", [])
    sunrises = daily.get("sunrise", [])
    sunsets = daily.get("sunset", [])

    by_date = {}
    for i in range(len(dates)):
        if i < len(sunrises) and i < len(sunsets):
            if sunrises[i] != None and sunsets[i] != None:
                by_date[dates[i]] = (sunrises[i], sunsets[i])
    return by_date

def sun_never_sets(sun):
    """True when the sun stays up through the charted date. Open-Meteo reports
    the sunset on the following date (or at an earlier hour than sunrise), so
    there is no meaningful sunset clock time to label."""
    if sun[1][:10] != sun[0][:10]:
        return True
    return int(sun[1][11:13]) < int(sun[0][11:13])

def sun_window(sun):
    """Inclusive (first, last) local hour the sun is up. Under polar day the
    window is the whole date, which also stops the naive hour comparison from
    inverting and filtering out every row."""
    if sun_never_sets(sun):
        return int(sun[0][11:13]), 23
    return int(sun[0][11:13]), int(sun[1][11:13])

def daylight_rows(hourly, date, sun):
    """Rows of (hour, uv, clear_sky) for one local date.

    With sun times the span is sunrise hour through sunset hour, so the axis
    labels always describe the exact bars drawn. Without them, fall back to the
    hours carrying any clear-sky UV, which keeps a fully overcast day (uv_index
    flat at 0 all day) from collapsing to an empty chart.
    """
    times = hourly["time"]
    uv_series = hourly["uv_index"]
    clear_series = hourly["uv_index_clear_sky"]

    first_hour = 0
    last_hour = 23
    if sun != None:
        first_hour, last_hour = sun_window(sun)

    rows = []
    for i in range(len(times)):
        stamp = times[i]
        if not stamp.startswith(date):
            continue

        hour = int(stamp[11:13])
        uv = as_float(uv_series[i])
        clear = as_float(clear_series[i])

        if sun != None:
            if hour < first_hour or hour > last_hour:
                continue
        elif clear <= UV_EPSILON and uv <= UV_EPSILON:
            continue

        rows.append((hour, uv, clear))
    return rows

def pick_day(data, sun_by_date, now):
    """Today's curve, or tomorrow's once today's sun is spent."""
    hourly = data["hourly"]

    today_date = now.format("2006-01-02")
    today_sun = sun_by_date.get(today_date)
    today = daylight_rows(hourly, today_date, today_sun)

    if len(today) > 0 and now.hour <= today[-1][0]:
        return today, False, today_sun, today_date

    tomorrow_date = (now + time.parse_duration("24h")).format("2006-01-02")
    tomorrow_sun = sun_by_date.get(tomorrow_date)
    tomorrow = daylight_rows(hourly, tomorrow_date, tomorrow_sun)
    if len(tomorrow) > 0:
        return tomorrow, True, tomorrow_sun, tomorrow_date

    return today, False, today_sun, today_date

def peak_of(rows):
    peak_uv = 0.0
    peak_index = 0
    for i in range(len(rows)):
        if rows[i][1] > peak_uv:
            peak_uv = rows[i][1]
            peak_index = i
    return peak_uv, peak_index

def scale_top(rows):
    peak_uv, _ = peak_of(rows)
    for step in SCALE_STEPS:
        if peak_uv <= step:
            return step
    return float(ceil_int(peak_uv))

def bar_px(value, top):
    """Bar height in pixels, clamped to the chart on both ends.

    Every hour in the window gets at least one lit pixel: the sun is up by
    definition, and a blank leading column makes the whole chart read as
    off-center even when the layout is symmetric.

    The ceiling matters for the clear-sky ghost, which is not what sets the
    scale and so routinely exceeds it on a cloudy day. Without the clamp its
    height runs past CHART_H and bar_layer derives negative padding.
    """
    height = round_int(value / top * CHART_H)
    if height < 1:
        return 1
    if height > CHART_H:
        return CHART_H
    return height

def bar_layer(height, width, color):
    return render.Padding(
        pad = (0, CHART_H - height, 0, 0),
        child = render.Box(width = width, height = height, color = color),
    )

def bar_width(pitch):
    if pitch - BAR_GAP < 1:
        return 1
    return pitch - BAR_GAP

def hour_column(row, top, pitch, show_ghost):
    _, uv, clear = row
    color, _ = uv_band(uv)
    width = bar_width(pitch)

    layers = []
    if show_ghost and clear > uv:
        layers.append(bar_layer(bar_px(clear, top), width, GHOST_COLOR))
    layers.append(bar_layer(bar_px(uv, top), width, color))

    return render.Padding(
        pad = (0, 0, pitch - width, 0),
        child = render.Stack(children = layers),
    )

def marker_row(rows, pitch, now_hour):
    """A white tick under the hour we are living in. A None hour means the chart
    is not today's, so there is no current hour on it to mark."""
    cells = []
    for row in rows:
        if now_hour == None or row[0] != now_hour:
            cells.append(render.Box(width = pitch, height = MARK_H))
        else:
            cells.append(render.Padding(
                pad = (0, 0, pitch - bar_width(pitch), 0),
                child = render.Box(
                    width = bar_width(pitch),
                    height = MARK_H,
                    color = NOW_COLOR,
                ),
            ))
    return render.Row(children = cells)

def axis_label(text, color):
    return render.Text(
        content = text,
        font = AXIS_FONT,
        color = color,
    )

def placed_label(x, text, color):
    return render.Padding(pad = (x, 0, 0, 0), child = axis_label(text, color))

def axis_labels(rows, pitch, chart_w, sun, opts):
    """Placed (x, text, color) axis labels: sunrise and sunset framing the day
    in muted gray, plus the peak's time in white under its own bar.

    The peak label is centered on its bar and nudged clear when it would collide
    with an edge label, since a few pixels of alignment cost less than losing
    sunrise or sunset. A chart too narrow for all three keeps the peak alone,
    and a peak of zero (overcast or polar night) is not labeled as a peak.
    """
    clock_24h = opts["clock_24h"]
    peak_uv, peak_index = peak_of(rows)

    # Under polar day there is no sunset to name, so the edges fall back to the
    # first and last hour charted, which reads as the whole day being lit.
    if sun != None and not sun_never_sets(sun):
        start_text = clock_label(sun[0], clock_24h)
        end_text = clock_label(sun[1], clock_24h)
    else:
        start_text = hour_label(rows[0][0], clock_24h)
        end_text = hour_label(rows[-1][0], clock_24h)

    start_w = label_width(start_text)
    end_w = label_width(end_text)
    end_x = chart_w - end_w
    edges_fit = start_w + LABEL_CLEARANCE + end_w <= chart_w
    edges = [(0, start_text, MUTED_COLOR), (end_x, end_text, MUTED_COLOR)]

    if peak_uv <= UV_EPSILON:
        if edges_fit:
            return edges
        if start_w <= chart_w:
            return edges[:1]
        return []

    peak_text = hour_label(rows[peak_index][0], clock_24h)
    peak_w = label_width(peak_text)
    peak_x = peak_index * pitch + (bar_width(pitch) - peak_w) // 2

    if edges_fit:
        lower = start_w + LABEL_CLEARANCE
        upper = end_x - LABEL_CLEARANCE - peak_w
        if lower <= upper:
            if peak_x < lower:
                peak_x = lower
            if peak_x > upper:
                peak_x = upper
            return edges + [(peak_x, peak_text, ACCENT_COLOR)]
        return edges

    if peak_w > chart_w:
        return []
    if peak_x < 0:
        peak_x = 0
    if peak_x + peak_w > chart_w:
        peak_x = chart_w - peak_w
    return [(peak_x, peak_text, ACCENT_COLOR)]

def axis_row(rows, pitch, chart_w, sun, opts):
    # A full-width spacer pins the Stack to the chart width, so a dropped label
    # cannot let the enclosing Box re-center the remaining ones.
    children = [render.Box(width = chart_w, height = AXIS_H)]
    for x, text, color in axis_labels(rows, pitch, chart_w, sun, opts):
        children.append(placed_label(x, text, color))

    return render.Box(
        width = chart_w,
        height = AXIS_H,
        child = render.Stack(children = children),
    )

def header_row(rows, tag):
    """Labeled tag on the left, the peak reading on the right.

    The tag is the charted date, always named rather than only being flagged
    when it is tomorrow's, so the header says which day it is instead of merely
    that it is not today. "UV" is white and the tag muted beside it, so the eye
    lands on what the panel is before reading which day it covers.
    """
    peak_uv, _ = peak_of(rows)
    color, label = uv_band(peak_uv)

    return render.Box(
        width = WIDTH,
        height = HEADER_H,
        child = render.Padding(
            pad = (MARGIN_X, 0, MARGIN_X, 0),
            child = render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Row(children = [
                        render.Text(
                            content = "UV ",
                            font = HEADER_FONT,
                            color = ACCENT_COLOR,
                        ),
                        render.Text(
                            content = tag,
                            font = HEADER_FONT,
                            color = MUTED_COLOR,
                        ),
                    ]),
                    render.Text(
                        content = str(round_int(peak_uv)) + " " + label,
                        font = HEADER_FONT,
                        color = color,
                    ),
                ],
            ),
        ),
    )

def message(text):
    return render.Root(
        child = render.Box(
            child = render.WrappedText(
                content = text,
                font = HEADER_FONT,
                color = "#f18b00",
                align = "center",
            ),
        ),
    )

def resolve_location(config):
    """The configured location, or None when the app has not been set up.

    A location field arrives as a JSON string from pixlet, but the Tronbyt
    server stores it as an object and may hand it back already decoded.
    """
    raw = config.get("location")
    if not raw:
        return None
    if type(raw) == "string":
        return json.decode(raw)
    return raw

def demo_rows():
    """A synthetic arc for the unconfigured preview. Real coordinates are never
    guessed: forecasting some default city would look authoritative while being
    wrong for everyone who does not live there."""
    rows = []
    for hour in range(DEMO_FIRST_HOUR, DEMO_LAST_HOUR + 1):
        offset = hour - DEMO_PEAK_HOUR
        span = DEMO_PEAK_HOUR - DEMO_FIRST_HOUR
        factor = 1.0 - float(offset * offset) / float(span * span)
        if factor < 0.0:
            factor = 0.0
        uv = DEMO_PEAK_UV * factor
        rows.append((hour, uv, uv * DEMO_GHOST_RATIO))
    return rows

def chart_root(rows, sun, tag, now_hour, opts):
    top = scale_top(rows)

    pitch = (WIDTH - 2 * MARGIN_X) // len(rows)
    if pitch > MAX_PITCH:
        pitch = MAX_PITCH
    if pitch < MIN_PITCH:
        pitch = MIN_PITCH
    chart_w = pitch * len(rows)

    # Center on the lit width: the final column carries a trailing gap that is
    # never painted, so centering chart_w itself leans the bars left.
    left_pad = (WIDTH - (chart_w - BAR_GAP)) // 2

    return render.Root(
        delay = 0,
        child = render.Column(children = [
            render.Box(width = WIDTH, height = TOP_PAD),
            header_row(rows, tag),
            render.Box(width = WIDTH, height = GAP_ABOVE_CHART),
            render.Padding(
                pad = (left_pad, 0, 0, 0),
                child = render.Column(children = [
                    render.Row(children = [
                        hour_column(row, top, pitch, opts["show_ghost"])
                        for row in rows
                    ]),
                    marker_row(rows, pitch, now_hour),
                    render.Box(width = chart_w, height = GAP_BELOW_MARK),
                    axis_row(rows, pitch, chart_w, sun, opts),
                ]),
            ),
        ]),
    )

def main(config):
    opts = read_options(config)

    location = resolve_location(config)
    if location == None:
        return chart_root(demo_rows(), None, DEMO_TAG, None, opts)

    lat = location.get("lat")
    lng = location.get("lng")
    if lat == None or lng == None:
        return message("SET LOCATION")

    data = fetch_hourly(lat, lng)
    if data == None:
        return message("UV DATA UNAVAILABLE")

    tz = data.get("timezone", location.get("timezone", "UTC"))
    now = time.now().in_location(tz)

    rows, is_tomorrow, sun, day_date = pick_day(data, fetch_sun(lat, lng), now)
    if len(rows) == 0:
        return message("NO UV FORECAST")

    # The tick only means anything on today's chart.
    now_hour = None
    if not is_tomorrow:
        now_hour = now.hour

    tag = date_label(day_date, opts["date_order"])
    return chart_root(rows, sun, tag, now_hour, opts)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location used for the UV forecast.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "show_clear_sky",
                name = "Clear-sky ghost",
                desc = "Dim bars behind each hour showing UV without cloud cover.",
                icon = "cloud",
                default = True,
            ),
            schema.Toggle(
                id = "clock_24h",
                name = "24-hour clock",
                desc = "Show sunrise, sunset and peak times on a 24-hour clock.",
                icon = "clock",
                default = False,
            ),
            schema.Dropdown(
                id = "date_order",
                name = "Date order",
                desc = "Order used when the header shows tomorrow's date.",
                icon = "calendar",
                default = "mdy",
                options = [
                    schema.Option(display = "MM/DD", value = "mdy"),
                    schema.Option(display = "DD/MM", value = "dmy"),
                ],
            ),
        ],
    )
