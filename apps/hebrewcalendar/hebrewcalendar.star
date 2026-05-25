"""
Applet: Hebrew Calendar
Author: betzmosk
Summary: Shabbat times & parshah
Description: Shows today's Hebrew date, the weekly Torah portion, and candle lighting and Havdalah times for the upcoming Shabbat (Jewish Sabbath) or Jewish holiday, for any location worldwide. Powered by the Hebcal REST API.
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# ── Fallback coords (Brooklyn, NY) used when no city has been selected ───────
DEFAULT_LAT = "40.6501"
DEFAULT_LNG = "-73.9496"

# ── Colour palette ────────────────────────────────────────────────────────────
COLOR_PARSHAH = "#FFD700"  # gold   – parshah name
COLOR_HOLIDAY = "#FF6B6B"  # coral  – Yom Tov name
COLOR_CANDLES = "#FF8C00"  # amber  – candle lighting
COLOR_HAVDALAH = "#9B59B6"  # violet – havdalah
COLOR_LABEL = "#888888"  # grey   – row labels
COLOR_ERROR = "#FF4444"  # red    – error states

# ── Hebcal API ────────────────────────────────────────────────────────────────
# Note: the havdalah parameter is NOT included here; it is appended dynamically
# by havdalah_param() based on the user's chosen method.
HEBCAL_URL = (
    "https://www.hebcal.com/shabbat" +
    "?cfg=json" +
    "&latitude=%s" +
    "&longitude=%s" +
    "&leyning=off"  # skip aliyah details to keep response small
)

# Hebcal Gregorian→Hebrew date converter
HEBCAL_CONVERTER_URL = "https://www.hebcal.com/converter?cfg=json&g2h=1&date="

# Optional date suffix appended when a specific date is configured.
# Hebcal uses gy/gm/gd for Gregorian year/month/day.
DATE_SUFFIX = "&gy=%s&gm=%s&gd=%s"

# Havdalah method dropdown option values
HAVDALAH_TZEIT = "tzeit"  # tzeit hakochavim – 3 stars (~8.5° below horizon)
HAVDALAH_DEGREES = "degrees"  # custom degrees below horizon
HAVDALAH_MINUTES = "minutes"  # custom minutes after sunset
HAVDALAH_RT = "rabeinu_tam"  # Rabbeinu Tam – 72 min after sunset
HAVDALAH_50 = "50min"  # 50 min after sunset

# ── Animation: 5 seconds per slide ───────────────────────────────────────────
SLIDE_DELAY_MS = 5000

# ── Photon geocoding (komoot, OSM-based, optimised for typeahead speed) ───────
# No API key required.  Results come back in GeoJSON FeatureCollection format.
# Coordinates are [lng, lat] per GeoJSON convention.
PHOTON_URL = "https://photon.komoot.io/api/?q=%s&limit=5&lang=en"

# ─────────────────────────────────────────────────────────────────────────────

def search_city(pattern):
    """Typeahead handler: returns matching cities for the typed string.

    Uses Photon (photon.komoot.io) which is optimised for fast autocomplete
    and returns GeoJSON FeatureCollection responses.
    """
    if len(pattern) < 2:
        return []

    encoded = pattern.replace(" ", "+")
    resp = http.get(
        PHOTON_URL % encoded,
        ttl_seconds = 86400,
    )
    if resp.status_code != 200:
        return []

    options = []
    for feature in resp.json().get("features", []):
        coords = feature.get("geometry", {}).get("coordinates", [])
        if len(coords) < 2:
            continue

        # GeoJSON order is [longitude, latitude]
        lng = str(coords[0])
        lat = str(coords[1])

        props = feature.get("properties", {})

        # Prefer the specific city name; fall back to the feature's own name.
        city = props.get("city") or props.get("name", "")
        state = props.get("state", "")
        country = props.get("country", "")

        if city == "":
            continue

        label = city
        if state != "":
            label = label + ", " + state
        if country != "":
            label = label + ", " + country

        val = json.encode({"lat": lat, "lng": lng, "label": label})
        options.append(schema.Option(display = label, value = val))
    return options

def is_numeric(s):
    """Return True if s represents a non-negative number (int or float)."""
    if s == "":
        return False
    dot_seen = False
    for ch in s.elems():
        if ch == ".":
            if dot_seen:
                return False
            dot_seen = True
        elif ch < "0" or ch > "9":
            return False
    return True

def havdalah_param(method, value):
    """Return the Hebcal query-string fragment for the chosen havdalah method.

    method  value field used?  Hebcal param
    ──────  ─────────────────  ────────────────────────────────────────────
    tzeit   no                 M=on  (3 stars, ~8.5° below horizon)
    degrees yes (float, °)     havdalahDeg=N
    minutes yes (int, min)     m=N
    rabeinu_tam no             m=72
    50min   no                 m=50
    """
    if method == HAVDALAH_DEGREES:
        deg = value if is_numeric(value) else "8.5"
        return "&havdalahDeg=" + deg
    elif method == HAVDALAH_MINUTES:
        mins = value if is_numeric(value) else "42"
        return "&m=" + mins
    elif method == HAVDALAH_RT:
        return "&m=72"
    elif method == HAVDALAH_50:
        return "&m=50"
    else:
        return "&M=on"  # default: tzeit hakochavim

def fetch_hebrew_date(date_str):
    """Return today's Hebrew date string (e.g. '24 Nisan 5786') via Hebcal converter.

    date_str: Gregorian date in YYYY-MM-DD format (today's date).
    Returns "" on any failure so callers can degrade gracefully.
    """
    res = http.get(HEBCAL_CONVERTER_URL + date_str, ttl_seconds = 86400)
    if res.status_code != 200:
        return ""
    data = res.json()
    if data == None:
        return ""
    hd = int(data.get("hd", 0))
    hm = data.get("hm", "")
    hy = int(data.get("hy", 0))
    if hd == 0 or hm == "" or hy == 0:
        return ""
    return str(hd) + " " + hm + " " + str(hy)

def fetch_shabbat(lat, lng, date = "", havdalah_method = HAVDALAH_TZEIT, havdalah_value = ""):
    url = HEBCAL_URL % (lat, lng)
    url = url + havdalah_param(havdalah_method, havdalah_value)
    if date != "":
        # date is "YYYY-MM-DD"; split into parts for the API
        parts = date.split("-")
        if len(parts) == 3:
            url = url + DATE_SUFFIX % (parts[0], parts[1], parts[2])
    resp = http.get(url, ttl_seconds = 86400)
    if resp.status_code != 200:
        return None
    return resp.json()

def extract_time(title):
    """'Candle lighting: 7:25pm' -> '7:25pm'"""
    parts = title.split(": ")
    return parts[-1] if len(parts) > 1 else title

def weekday_label(iso_date_str):
    """Return a 3-letter weekday from an ISO 8601 datetime string.

    '2025-09-22T18:30:00-04:00' -> 'Mon'
    Falls back to '...' if the string is malformed.
    """
    if "T" not in iso_date_str:
        return "..."
    date_part = iso_date_str.split("T")[0]
    t = time.parse_time(date_part, format = "2006-01-02", location = "UTC")
    return t.format("Mon")

def clean_holiday_name(title):
    """Strip the Hebrew year from a holiday title.

    'Rosh Hashana 5786'    -> 'Rosh Hashana'
    'Pesach I 5786'        -> 'Pesach I'
    'Shavuot'              -> 'Shavuot'   (unchanged, no year)
    """
    parts = title.split(" ")
    cleaned = []
    for p in parts:
        # Hebrew years are always 4-digit numbers starting with '5'
        if len(p) == 4 and p.startswith("5"):
            break
        cleaned.append(p)
    return " ".join(cleaned)

def render_error(msg):
    return render.Root(
        child = render.Box(
            width = 64,
            height = 32,
            child = render.WrappedText(
                content = msg,
                width = 62,
                color = COLOR_ERROR,
                font = "tom-thumb",
            ),
        ),
    )

def event_row(label, t, time_color):
    """One info row: grey label ▸ coloured time value."""
    return render.Row(
        children = [
            render.Text(label, color = COLOR_LABEL, font = "tom-thumb"),
            render.Box(width = 2, height = 5),
            render.Text(t, color = time_color, font = "tom-thumb"),
        ],
    )

def text_row(text, color):
    """A full-width text row with no label/time pair.

    Used in the no-times slide to show the parsha on its own line.
    """
    return render.Row(
        children = [
            render.Marquee(
                width = 60,
                child = render.Text(text, color = color, font = "tom-thumb"),
                scroll_direction = "horizontal",
            ),
        ],
    )

def make_slide(hebrew_date, display_name, name_color, rows):
    """Build one 64×32 slide.

    hebrew_date:  Hebrew calendar date shown on the top row (e.g. "24 Nisan 5786").
    display_name: Parsha/holiday name shown on the second row.
    rows:         List of at most 2 pre-built event_row() widgets.

    Pixel budget:
      0px  top pad
      8px  Hebrew date  (tb-8, white)
      1px  gap
      5px  display name (tom-thumb, gold/coral)
      2px  gap before row 1
      5px  row 1 (tom-thumb)
      2px  gap before row 2
      5px  row 2 (tom-thumb)
      4px  bottom pad
     ─────
     32px
    """
    children = [
        # Top row: Hebrew date in white tb-8
        render.Marquee(
            width = 64,
            child = render.Text(
                content = hebrew_date,
                color = "#FFFFFF",
                font = "tb-8",
            ),
            scroll_direction = "horizontal",
        ),
    ]

    # Second row: parsha / holiday name — omitted when there is nothing to show.
    if display_name != "":
        children.append(
            render.Padding(
                pad = (2, 1, 0, 0),
                child = render.Marquee(
                    width = 60,
                    child = render.Text(
                        content = display_name,
                        color = name_color,
                        font = "tom-thumb",
                    ),
                    scroll_direction = "horizontal",
                ),
            ),
        )

    for i, row in enumerate(rows[:2]):
        gap = [2, 2][i]
        children.append(
            render.Padding(pad = (2, gap, 0, 0), child = row),
        )

    return render.Column(children = children)

# ─────────────────────────────────────────────────────────────────────────────

def resolve_location(raw_loc):
    """Return (lat, lng) from the location config value.

    The value is either:
      a) A JSON string from a typeahead selection  → {"lat":..., "lng":...}
      b) A plain city-name string typed manually   → geocode via Photon

    Falls back to New York City if nothing resolves.
    """
    if not raw_loc:
        return (DEFAULT_LAT, DEFAULT_LNG)

    # Strip surrounding whitespace first so trailing spaces never block geocoding.
    loc_str = raw_loc.strip()

    if loc_str.startswith("{"):
        outer = json.decode(loc_str)

        # pixlet serve wraps Typeahead selections as:
        #   {"display": "...", "text": "...", "value": "<inner JSON string>"}
        # If that "value" key is present, decode the inner JSON to get lat/lng.
        inner_str = outer.get("value", "")
        if inner_str != "" and inner_str.startswith("{"):
            loc = json.decode(inner_str)
        else:
            # Fallback: the outer dict is itself the location data.
            loc = outer

        return (loc.get("lat", DEFAULT_LAT), loc.get("lng", DEFAULT_LNG))

    # Require at least 4 characters before geocoding so that partial keystrokes
    # like "B", "Ba", "Bal" don't resolve to wrong cities mid-typing.
    if len(loc_str) < 4:
        return (DEFAULT_LAT, DEFAULT_LNG)

    # Plain text: run a geocoding search and take the top result
    options = search_city(loc_str)
    if len(options) > 0:
        loc = json.decode(options[0].value)
        return (loc.get("lat", DEFAULT_LAT), loc.get("lng", DEFAULT_LNG))

    return (DEFAULT_LAT, DEFAULT_LNG)

def build_display_name(holiday, holiday_on_shabbat, rosh_chodesh_month, rosh_chodesh_dates, parshah, shabbat_imminent = True):
    """Compute the second-row display string and its colour.

    Rules (in priority order):
      1. Holiday falls on Saturday AND Shabbat is imminent (today ≥ Thursday):
            "Shabbat, <Holiday> | Parshat <parsha>"              (coral)
      2. Rosh Chodesh falls on Saturday AND Shabbat is imminent:
            "Shabbat, Rosh Chodesh <month> | Parshat <parsha>"  (coral)
      3. Holiday on a weekday (or Shabbat not yet imminent):
            "<Holiday> | Parshat <parsha>"                       (coral)
      4. Rosh Chodesh on a weekday:
            "Rosh Chodesh <month> | Parshat <parsha>"           (coral)
      5. Plain Shabbat (imminent):
            "Shabbat | Parshat <parsha>"                         (gold)
      6. Weekday, no holiday:
            "Parshat <parsha>"                                   (gold)

    shabbat_imminent must be True for the "Shabbat, " prefix to appear.
    It should only be set True when today is within 1 day of the final
    (Shabbat) candle — NOT for the whole multi-day event window.

    The " | Parshat …" suffix is omitted when parsha is empty.
    """

    # Detect whether any Rosh Chodesh date falls on Saturday.
    is_shabbat_rc = False
    for rc_date in rosh_chodesh_dates:
        if len(rc_date) >= 10:
            rc_time = time.parse_time(rc_date[:10], "2006-01-02", "UTC")
            if rc_time.format("Mon") == "Sat":
                is_shabbat_rc = True
                break

    parsha_part = ("Parshat " + parshah) if parshah != "" else ""

    # The "Shabbat, " prefix is only shown when Shabbat is actually imminent
    # (today is Thursday or Friday, within 1 day of the Shabbat candle).
    # Earlier in a multi-day Yom Tov week the holiday label stands alone.
    if holiday != "" and holiday_on_shabbat and shabbat_imminent:
        prefix = "Shabbat, " + holiday
        color = COLOR_HOLIDAY
    elif is_shabbat_rc and shabbat_imminent:
        prefix = "Shabbat, Rosh Chodesh " + rosh_chodesh_month
        color = COLOR_HOLIDAY
    elif holiday != "":
        prefix = holiday
        color = COLOR_HOLIDAY
    elif rosh_chodesh_month != "":
        prefix = "Rosh Chodesh " + rosh_chodesh_month
        color = COLOR_HOLIDAY
    else:
        prefix = ""
        color = COLOR_PARSHAH

    if prefix != "" and parsha_part != "":
        return (prefix + " | " + parsha_part, color)
    elif prefix != "":
        return (prefix, color)
    elif parsha_part != "":
        # Only prepend "Shabbat | " when Shabbat is actually imminent
        # (within 1 day of candle lighting).  On Mon–Wed it would be misleading.
        if shabbat_imminent:
            return ("Shabbat | " + parsha_part, color)
        return (parsha_part, color)
    else:
        return ("Shabbat" if shabbat_imminent else "", color)

def within_24h_of_candle(candle_date_str, now, one_day):
    """Return True if now is within 24 hours before the candle lighting time.

    Parses the full ISO 8601 datetime from Hebcal (e.g. '2026-05-21T19:45:00-04:00')
    so the window opens at the exact candle time minus 24h, not at midnight.
    Falls back to a midnight-based check for date-only strings.
    """
    if "T" in candle_date_str:
        candle_dt = time.parse_time(candle_date_str, "2006-01-02T15:04:05Z07:00", "UTC")
        return now >= candle_dt - one_day
    candle_d = time.parse_time(candle_date_str[:10], "2006-01-02", "UTC")
    return now >= candle_d - one_day

def is_split_week(candles, havdalah):
    """Return True when Yom Tov ends mid-week (before Shabbat).

    Detected by finding a havdalah whose date falls before the final candle
    (the Shabbat candle lighting).  Requires at least 2 candles and 2 havdalahs.

    Examples:
      Split  – Pesach last days: candles=[Wed, Fri], havdalah=[Thu, Sat]
               Thu havdalah < Fri candle → True
      Bundled – Pesach 1st days: candles=[Wed, Thu, Fri], havdalah=[Sat]
               Only 1 havdalah → False
      Bundled – Shabbat→YT: candles=[Fri, Sat], havdalah=[Mon]
               Mon havdalah > Sat candle → False
    """
    if len(candles) < 2 or len(havdalah) < 2:
        return False
    return havdalah[0]["date"] < candles[-1]["date"]

def main(config):
    # ── Resolve location ──────────────────────────────────────────────────────
    lat, lng = resolve_location(config.get("location"))
    havdalah_method = config.get("havdalah_method") or HAVDALAH_TZEIT
    havdalah_value = config.get("havdalah_value") or ""

    # ── Fetch data ────────────────────────────────────────────────────────────
    data = fetch_shabbat(lat, lng, havdalah_method = havdalah_method, havdalah_value = havdalah_value)
    if data == None:
        return render_error("Hebcal API error")

    # ── Today's date ─────────────────────────────────────────────────────────
    # Normally derived from time.now().  Pass `today=YYYY-MM-DD` to override
    # (useful for testing a specific day within a holiday week).
    now = time.now()
    today_str = config.get("today") or now.format("2006-01-02")
    today_hdate = fetch_hebrew_date(today_str)

    # ── Parse API items ───────────────────────────────────────────────────────
    parshah = ""
    holiday = ""  # any holiday that is NOT Rosh Chodesh
    holiday_date = ""  # ISO date string of the first non-RC holiday item
    holiday_on_shabbat = False  # True when any holiday item falls on a Saturday
    rosh_chodesh_month = ""  # "Nisan", "Iyyar", … — empty if Rosh Hashana
    rosh_chodesh_dates = []  # all dates for RC items (2-day RC = 2 entries)
    candles = []  # [{"time": "7:25pm", "date": "2025-09-22T..."}]
    havdalah = []  # [{"time": "8:17pm",  "date": "2025-09-22T..."}]

    for item in data.get("items", []):
        cat = item.get("category", "")
        subcat = item.get("subcat", "")
        title = item.get("title", "")

        if cat == "holiday" and subcat == "roshchodesh":
            # Collect all RC dates (may span 2 days); capture month once.
            # Never show "Rosh Chodesh" for Rosh Hashana (Tishrei).
            if "Tishrei" not in title:
                if rosh_chodesh_month == "" and "Rosh Chodesh " in title:
                    raw_month = title.split("Rosh Chodesh ")[1].strip()
                    rosh_chodesh_month = clean_holiday_name(raw_month)
                rosh_chodesh_dates.append(item.get("date", ""))

        elif cat == "holiday":
            # major, minor, modern, fast, shabbat — all non-RC holiday types.
            # Check every matching item so that day-2 of a 2-day Yom Tov on
            # Saturday (e.g. Rosh Hashana Fri–Sat) is detected correctly.
            d = item.get("date", "")
            if len(d) >= 10:
                t = time.parse_time(d[:10], "2006-01-02", "UTC")
                if t.format("Mon") == "Sat":
                    holiday_on_shabbat = True
            if holiday == "":
                holiday = clean_holiday_name(title)
                holiday_date = item.get("date", "")

        elif cat == "parashat" and parshah == "":
            parshah = title.replace("Parashat ", "")

        elif cat == "candles":
            t = extract_time(item.get("title", ""))
            if t != "":
                candles.append({"time": t, "date": item.get("date", "")})

        elif cat == "havdalah":
            t = extract_time(item.get("title", ""))
            if t != "":
                havdalah.append({"time": t, "date": item.get("date", "")})

    if len(candles) == 0 and len(havdalah) == 0:
        return render_error("No Shabbat data")

    multi_candle = len(candles) > 1
    one_day = time.parse_duration("24h")

    # ── Drop events that have already passed ──────────────────────────────────
    # The device updates once a day at sunset.  By the time the new image is
    # pushed, yesterday's candle-lighting is stale.  Keep only events whose
    # date is today or later so the display stays accurate on day 2+ of a
    # multi-day holiday.
    # Structure detection (is_split_week, multi_candle) uses the full original
    # lists so the week layout is understood correctly even when past items
    # have already been filtered out for display.
    candles_disp = [c for c in candles if c["date"][:10] >= today_str]
    havdalah_disp = [h for h in havdalah if h["date"][:10] >= today_str]

    # ── Temporal filter 1: holiday label ─────────────────────────────────────
    # A holiday that overlaps with Shabbat (holiday_on_shabbat) or produces
    # extra candle lightings (multi_candle) is always shown this week.
    # A mid-week holiday with no Shabbat connection (e.g. Yom Hashoah,
    # Yom Ha'atzmaut) is only shown when today is within the window
    # [holiday_date − 1 day, last havdalah date or holiday_date itself].
    if holiday != "" and not holiday_on_shabbat and not multi_candle:
        if holiday_date != "":
            hol_t = time.parse_time(holiday_date[:10], "2006-01-02", "UTC")
            day_before = (hol_t - one_day).format("2006-01-02")
            hol_end = holiday_date[:10]
            if not (day_before <= today_str and today_str <= hol_end):
                holiday = ""
                holiday_on_shabbat = False
        else:
            holiday = ""

    # ── Temporal filter 2: candle / Havdalah times ───────────────────────────
    # Display time rows when now is within [first candle − 24h, last havdalah].
    # The start uses the exact candle datetime so the window opens 24 hours
    # before the actual candle lighting time, not from the previous midnight.
    show_times = False
    near_shabbat = False  # True only when today ≥ 1 day before the LAST candle
    last_hav_date = ""  # saved so we can trim candles_disp below
    if candles_disp:
        last_hav_date = havdalah_disp[-1]["date"][:10] if havdalah_disp else candles_disp[-1]["date"][:10]
        show_times = (within_24h_of_candle(candles_disp[0]["date"], now, one_day) and today_str <= last_hav_date)
    elif havdalah_disp:
        # All candles are past; still show the remaining havdalah today.
        last_hav_date = havdalah_disp[-1]["date"][:10]
        show_times = (today_str <= last_hav_date)

    # ── Trim candles_disp to the current event window ────────────────────────
    # The Hebcal API sometimes returns candles for a future holiday cluster
    # (e.g., the last-days-of-Pesach candle when querying Pesach I week).
    # Any candle that falls AFTER the last havdalah belongs to a different
    # cluster and must be dropped so it never bleeds into Case B/C slides.
    if last_hav_date != "":
        candles_disp = [c for c in candles_disp if c["date"][:10] <= last_hav_date]

    # near_shabbat is computed AFTER trimming so candles_disp[-1] is the true
    # last candle of the current event window (e.g., the Friday candle, not a
    # later Chol-HaMoed candle from a future cluster).
    #
    # We use a STRICT threshold: today must be on or after the last candle date
    # itself (Friday / Yom Tov candle day).  Allowing one day earlier (Thursday)
    # would cause "Shabbat, Pesach" to appear on a Yom Tov weekday.
    if candles_disp:
        last_c_date = candles_disp[-1]["date"][:10]
        near_shabbat = (last_c_date <= today_str and today_str <= last_hav_date)
    elif havdalah_disp:
        near_shabbat = show_times  # past candles → we are in / past Shabbat

    # ── Decide display name and colour ────────────────────────────────────────
    # Pass near_shabbat (not show_times) so "Shabbat, Holiday" only appears
    # when we are actually close to the Shabbat component of the event.
    display_name, name_color = build_display_name(
        holiday,
        holiday_on_shabbat,
        rosh_chodesh_month,
        rosh_chodesh_dates,
        parshah,
        shabbat_imminent = near_shabbat,
    )

    # ── Build event rows from the filtered (future) data ─────────────────────
    candle_rows = []
    for c in candles_disp:
        # Keep weekday labels when this is a multi-candle week even if some
        # days have already been filtered out — the context is still useful.
        label = weekday_label(c["date"]) + " " if multi_candle else "Candles "
        candle_rows.append(event_row(label, c["time"], COLOR_CANDLES))

    havdalah_rows = [
        event_row("Havdalah", h["time"], COLOR_HAVDALAH)
        for h in havdalah_disp
    ]

    # ── Assemble slides ───────────────────────────────────────────────────────
    #
    # CASE 0 – Outside the display window (times not yet / no longer relevant)
    #   Single slide; no time rows shown.
    #   [ <Hebrew date>          ]
    #   [ Holiday / RC           ]  (coral)
    #   [ Parshat <parsha>       ]  (gold)   ← only when a holiday/RC is also shown
    #
    # CASE A – Split week: Yom Tov ends before Shabbat
    #   Each event cluster (YT block and Shabbat) gets its OWN 1-day window so
    #   the two slides never appear together unless today sits in both windows
    #   (i.e. the YT Havdalah day is also the day-before for the Shabbat candle).
    #   Slide 1 (coral)            Slide 2 (gold)
    #   [ <Hebrew date>       ]    [ <Hebrew date>              ]
    #   [ Pesach | Parshat …  ]    [ Shabbat | Parshat Shemini  ]
    #   [ Havdalah 8:11pm     ]    [ Candles  7:11pm            ]
    #                              [ Havdalah 8:13pm            ]
    #
    # CASE B – Bundled multi-candle: Yom Tov runs into Shabbat  (show_times=True)
    #   Filtered rows only.
    #   Slide 1 (coral)                    Slide 2 (coral, if needed)
    #   [ <Hebrew date>           ]        [ <Hebrew date>          ]
    #   [ Pesach | Parshat …      ]        [ Pesach | Parshat …     ]
    #   [ Thu 8:03pm (remaining)  ]        [ Havdalah 8:05pm        ]
    #   [ Fri 7:04pm              ]
    #
    # CASE C – Normal Shabbat / single-candle Yom Tov  (show_times=True) → 1 slide
    #   [ <Hebrew date>   ]
    #   [ Shabbat | …     ]
    #   [ Candles  …      ]
    #   [ Havdalah …      ]
    #
    slides = []

    if is_split_week(candles, havdalah):
        # ── Case A: split week — independent 1-day window per event cluster ─────
        # The final candle / final havdalah mark the Shabbat boundary.
        shab_c_date = candles[-1]["date"][:10]
        shab_h_date = havdalah[-1]["date"][:10]

        # Unfiltered per-cluster lists (for window edge calculation)
        yt_c_full = [c for c in candles if c["date"][:10] < shab_c_date]
        yt_h_full = [h for h in havdalah if h["date"][:10] < shab_h_date]
        shab_c_full = [c for c in candles if c["date"][:10] == shab_c_date]
        shab_h_full = [h for h in havdalah if h["date"][:10] == shab_h_date]

        # Filtered (future) per-cluster lists for display
        yt_c_disp = [c for c in candles_disp if c["date"][:10] < shab_c_date]
        yt_h_disp = [h for h in havdalah_disp if h["date"][:10] < shab_h_date]
        shab_c_disp = [c for c in candles_disp if c["date"][:10] == shab_c_date]
        shab_h_disp = [h for h in havdalah_disp if h["date"][:10] == shab_h_date]

        # YT window: [first YT candle − 24h, last YT havdalah]
        show_yt = False
        if yt_c_full:
            last_yt_hav = yt_h_full[-1]["date"][:10] if yt_h_full else yt_c_full[-1]["date"][:10]
            show_yt = (within_24h_of_candle(yt_c_full[0]["date"], now, one_day) and today_str <= last_yt_hav)

        # Shabbat window: [Shabbat candle − 24h, Shabbat havdalah]
        show_shab_split = False
        if shab_c_full:
            last_shab_hav = shab_h_full[-1]["date"][:10] if shab_h_full else shab_c_full[-1]["date"][:10]
            show_shab_split = (within_24h_of_candle(shab_c_full[0]["date"], now, one_day) and today_str <= last_shab_hav)

        yt_raw = holiday if holiday != "" else "Yom Tov"
        yt_name, yt_color = build_display_name(
            yt_raw,
            holiday_on_shabbat,
            rosh_chodesh_month,
            rosh_chodesh_dates,
            parshah,
        )

        if show_yt and (yt_c_disp or yt_h_disp):
            multi_yt_disp = len(yt_c_disp) > 1
            yt_c_rows = []
            for c in yt_c_disp:
                lbl = weekday_label(c["date"]) + " " if multi_yt_disp else "Candles "
                yt_c_rows.append(event_row(lbl, c["time"], COLOR_CANDLES))
            yt_h_rows = [event_row("Havdalah", h["time"], COLOR_HAVDALAH) for h in yt_h_disp]

            if multi_yt_disp:
                slides.append(make_slide(today_hdate, yt_name, yt_color, yt_c_rows[:2]))
                yt_extra = yt_c_rows[2:] + yt_h_rows
                if len(yt_extra) > 0:
                    slides.append(make_slide(today_hdate, yt_name, yt_color, yt_extra[:2]))
            else:
                slides.append(make_slide(today_hdate, yt_name, yt_color, yt_c_rows + yt_h_rows))

        if show_shab_split and (shab_c_disp or shab_h_disp):
            shab_name, shab_color = build_display_name(
                "",
                False,
                rosh_chodesh_month,
                rosh_chodesh_dates,
                parshah,
            )
            shab_rows = (
                [event_row("Candles ", c["time"], COLOR_CANDLES) for c in shab_c_disp] +
                [event_row("Havdalah", h["time"], COLOR_HAVDALAH) for h in shab_h_disp]
            )
            slides.append(make_slide(today_hdate, shab_name, shab_color, shab_rows))

        # Outside both windows: fall through to label-only display below.

    if not slides:
        if not show_times:
            # ── Case 0: outside the 1-day window — show label + parsha, no times ──
            # When display_name combines an event label and the parsha (e.g.
            # "Rosh Hashana | Parshat Haazinu"), split them so the holiday/RC name
            # appears on row 2 and the parsha gets its own row 3.
            #
            # For holidays connected to Shabbat or with multiple candle lightings
            # (e.g. Shavuot, Pesach, Rosh Hashana), the temporal filter at line 524
            # is skipped, so the holiday label would otherwise appear all week.
            # Suppress it here — Case B/C shows it correctly once show_times=True.
            holiday_case0 = "" if (holiday_on_shabbat or multi_candle) else holiday
            label_nm, label_col = build_display_name(
                holiday_case0,
                holiday_on_shabbat,
                rosh_chodesh_month,
                rosh_chodesh_dates,
                parshah,
                shabbat_imminent = False,
            )
            parts = label_nm.split(" | ")
            if len(parts) > 1:
                slides.append(make_slide(
                    today_hdate,
                    parts[0],
                    label_col,
                    [text_row(parts[1], COLOR_PARSHAH)],
                ))
            else:
                slides.append(make_slide(today_hdate, label_nm, label_col, []))
        elif multi_candle:
            # ── Case B: bundled multi-candle (YT into Shabbat, or Shabbat into YT) ──
            slides.append(make_slide(today_hdate, display_name, name_color, candle_rows[:2]))
            extra = candle_rows[2:] + havdalah_rows
            if len(extra) > 0:
                slides.append(make_slide(today_hdate, display_name, name_color, extra[:2]))

        else:
            # ── Case C: normal Shabbat or single-candle Yom Tov ──
            slides.append(make_slide(today_hdate, display_name, name_color, candle_rows + havdalah_rows))

    # Safety: if all events were still filtered out, show label only
    if len(slides) == 0:
        label_nm, label_col = build_display_name(
            holiday,
            holiday_on_shabbat,
            rosh_chodesh_month,
            rosh_chodesh_dates,
            parshah,
            shabbat_imminent = False,
        )
        slides.append(make_slide(today_hdate, label_nm, label_col, []))

    # ── Render ────────────────────────────────────────────────────────────────
    if len(slides) == 1:
        return render.Root(max_age = 86400, child = slides[0])

    return render.Root(
        max_age = 86400,
        delay = SLIDE_DELAY_MS,
        child = render.Animation(children = slides),
    )

# ── Schema ────────────────────────────────────────────────────────────────────
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "location",
                name = "Location",
                desc = "Start typing a city name to see matching options.",
                icon = "placeOfWorship",
                handler = search_city,
            ),
            schema.Dropdown(
                id = "havdalah_method",
                name = "Havdalah Method",
                desc = "How to calculate the end of Shabbat / Yom Tov.",
                icon = "moon",
                default = HAVDALAH_TZEIT,
                options = [
                    schema.Option(display = "Tzeit Hakochavim (3 stars, ~8.5°)", value = HAVDALAH_TZEIT),
                    schema.Option(display = "Degrees Below Horizon", value = HAVDALAH_DEGREES),
                    schema.Option(display = "Halachic Minutes After Sunset", value = HAVDALAH_MINUTES),
                    schema.Option(display = "Rabbeinu Tam (72 min)", value = HAVDALAH_RT),
                    schema.Option(display = "50 Minutes After Sunset", value = HAVDALAH_50),
                ],
            ),
            schema.Text(
                id = "havdalah_value",
                name = "Custom Havdalah Value",
                desc = "Degrees (e.g. 8.5) or minutes (e.g. 42). Only used when 'Degrees' or 'Halachic Minutes' is selected above.",
                icon = "clock",
                default = "",
            ),
        ],
    )
