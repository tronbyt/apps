"""
Applet: Daily Horoscope
Summary: See your daily horoscope
Description: Displays the daily horoscope for a specific sign from USA Today.
Author: frame-shift

Version 1.3
"""

load("encoding/json.star", "json")
load("html.star", "html")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/aquarius.webp", AQUARIUS_ICON_ASSET = "file")
load("images/aries.webp", ARIES_ICON_ASSET = "file")
load("images/cancer.webp", CANCER_ICON_ASSET = "file")
load("images/capricorn.webp", CAPRICORN_ICON_ASSET = "file")
load("images/first_quarter.webp", FIRST_QUARTER_ICON_ASSET = "file")
load("images/full_moon.webp", FULL_MOON_ICON_ASSET = "file")
load("images/gemini.webp", GEMINI_ICON_ASSET = "file")
load("images/last_quarter.webp", LAST_QUARTER_ICON_ASSET = "file")
load("images/leo.webp", LEO_ICON_ASSET = "file")
load("images/libra.webp", LIBRA_ICON_ASSET = "file")
load("images/new_moon.webp", NEW_MOON_ICON_ASSET = "file")
load("images/pisces.webp", PISCES_ICON_ASSET = "file")
load("images/sagittarius.webp", SAGITTARIUS_ICON_ASSET = "file")
load("images/scorpio.webp", SCORPIO_ICON_ASSET = "file")
load("images/taurus.webp", TAURUS_ICON_ASSET = "file")
load("images/virgo.webp", VIRGO_ICON_ASSET = "file")
load("images/waning_crescent.webp", WANING_CRESCENT_ICON_ASSET = "file")
load("images/waning_gibbous.webp", WANING_GIBBOUS_ICON_ASSET = "file")
load("images/waxing_crescent.webp", WAXING_CRESCENT_ICON_ASSET = "file")
load("images/waxing_gibbous.webp", WAXING_GIBBOUS_ICON_ASSET = "file")
load("math.star", "math")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Set default values
DEFAULT_SIGN = "aries"
DEFAULT_SPEED = "70"
DEFAULT_MOON = True
DEFAULT_COLOR = "#994BA1"

TTL = 3600  # One hour

# 12x12 zodiac icons w/ transparent bg
SIGN_ICONS = {
    "aries": ARIES_ICON_ASSET.readall(),
    "aquarius": AQUARIUS_ICON_ASSET.readall(),
    "cancer": CANCER_ICON_ASSET.readall(),
    "capricorn": CAPRICORN_ICON_ASSET.readall(),
    "gemini": GEMINI_ICON_ASSET.readall(),
    "leo": LEO_ICON_ASSET.readall(),
    "libra": LIBRA_ICON_ASSET.readall(),
    "pisces": PISCES_ICON_ASSET.readall(),
    "sagittarius": SAGITTARIUS_ICON_ASSET.readall(),
    "scorpio": SCORPIO_ICON_ASSET.readall(),
    "taurus": TAURUS_ICON_ASSET.readall(),
    "virgo": VIRGO_ICON_ASSET.readall(),
}

# 6x6 moon phase icons
MPHASE_ICONS = {
    "NM": NEW_MOON_ICON_ASSET.readall(),
    "XC": WAXING_CRESCENT_ICON_ASSET.readall(),
    "FQ": FIRST_QUARTER_ICON_ASSET.readall(),
    "XG": WAXING_GIBBOUS_ICON_ASSET.readall(),
    "FM": FULL_MOON_ICON_ASSET.readall(),
    "NG": WANING_GIBBOUS_ICON_ASSET.readall(),
    "LQ": LAST_QUARTER_ICON_ASSET.readall(),
    "NC": WANING_CRESCENT_ICON_ASSET.readall(),
}

# Moon signs
MSIGNS = {
    "aries": "Ari",
    "aquarius": "Aqu",
    "cancer": "Can",
    "capricorn": "Cap",
    "gemini": "Gem",
    "leo": "Leo",
    "libra": "Lib",
    "pisces": "Pis",
    "sagittarius": "Sag",
    "scorpio": "Sco",
    "taurus": "Tau",
    "virgo": "Vir",
}

def render_error(code):
    # Render error messages
    return render.Root(
        render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.WrappedText(
                    color = "#ff00ff",
                    content = "Horoscope error",
                    font = "CG-pixel-4x5-mono",
                    align = "center",
                ),
                render.Box(
                    width = 64,
                    height = 1,
                    color = "#ff00ff",
                ),
                render.WrappedText(
                    content = code,
                    font = "tb-8",
                    align = "center",
                ),
            ],
        ),
    )

def main(config):
    # Render for display
    zodiac = config.str("zodiac_choice", DEFAULT_SIGN)
    show_moon = config.bool("moon_choice", DEFAULT_MOON)
    sign_color = config.str("color_choice", DEFAULT_COLOR)

    # Fetch horoscope data
    horoscope_url = "https://play.usatoday.com/horoscopes/daily/" + zodiac  # Updates daily at 09:00 UTC
    scope_response = http.get(horoscope_url, ttl_seconds = TTL)

    if scope_response.status_code != 200:
        return render_error("Could not reach source")

    scope_html = html(scope_response.body())
    json_extract = scope_html.find("script").filter("#__NEXT_DATA__").text()
    scope_json = json.decode(json_extract)

    # Parse date that horoscope was written
    date_extracted = scope_json.get("props", {}).get("pageProps", {}).get("dehydratedState", {}).get("queries", [{}])[0].get("state", {}).get("data", {}).get("horoscopesDaily", {}).get("horoscopes", [{}])[0].get("date")

    if date_extracted == None:
        return render_error("Could not get date")

    date_parsed = time.parse_time(date_extracted, format = "2006-01-02")
    date_m = humanize.time_format("MMM", date_parsed).upper()
    date_d = humanize.time_format("d", date_parsed)

    # Parse horoscope
    horoscope_extracted = scope_json.get("props", {}).get("pageProps", {}).get("dehydratedState", {}).get("queries", [{}])[0].get("state", {}).get("data", {}).get("horoscopesDaily", {}).get("horoscopes", [{}])[0].get("horoscope")
    horoscope_parsed = re.sub(".*\n", "", horoscope_extracted or "")

    if horoscope_parsed == "":
        return render_error("Could not get horoscope")

    horoscope = edit_horoscope(horoscope_parsed)

    # Render moon data
    if show_moon:
        moon_phase, moon_sign = get_moon_info(date_parsed)
        moon_icon = MPHASE_ICONS[moon_phase]
        m_width = 40

        moon_info = render.Column(
            cross_align = "center",
            children = [
                render.Row(
                    children = [
                        render.Box(color = "#000", width = 1, height = 1),
                        render.Box(color = sign_color + "33", height = 1, width = m_width - 2),
                        render.Box(color = "#000", width = 1, height = 1),
                    ],
                ),
                render.Box(color = sign_color + "33", height = 1, width = m_width),
                render.Stack(
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "center",
                            cross_align = "center",
                            children = [
                                render.Box(color = sign_color + "33", height = 6, width = m_width),
                            ],
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "center",
                            cross_align = "start",
                            children = [
                                render.Padding(
                                    child = render.Image(src = moon_icon),
                                    pad = (1, 0, 0, 0),
                                ),
                                render.Padding(
                                    child = render.Text(content = "in", color = "#00ffffaa", font = "tom-thumb"),
                                    pad = (3, 0, 3, 0),
                                ),
                                render.Padding(
                                    child = render.Text(content = moon_sign, color = "#00ffff", font = "CG-pixel-4x5-mono"),
                                    pad = (0, 0, 0, 0),
                                ),
                            ],
                        ),
                    ],
                ),
                render.Box(color = sign_color + "33", height = 1, width = m_width),
                render.Row(
                    children = [
                        render.Box(color = "#000", width = 1, height = 1),
                        render.Box(color = sign_color + "33", height = 1, width = m_width - 2),
                        render.Box(color = "#000", width = 1, height = 1),
                    ],
                ),
                render.Box(color = "#000", height = 3),
            ],
        )

    else:
        moon_info = render.Box(
            color = "#00000000",
            width = 1,
            height = 1,
        )

    # Set the zodiac icon
    sign_img = SIGN_ICONS[zodiac]
    zodiac_icon = render.Padding(
        child = render.Stack(
            children = [
                render.Column(
                    children = [
                        render.Row(
                            children = [
                                render.Box(color = "#000", width = 1, height = 1),
                                render.Box(color = sign_color, width = 10, height = 1),
                                render.Box(color = "#000", width = 1, height = 1),
                            ],
                        ),
                        render.Box(color = sign_color, width = 12, height = 10),
                        render.Row(
                            children = [
                                render.Box(color = "#000", width = 1, height = 1),
                                render.Box(color = sign_color, width = 10, height = 1),
                                render.Box(color = "#000", width = 1, height = 1),
                            ],
                        ),
                    ],
                ),
                render.Image(src = sign_img),
            ],
        ),
        pad = (0, 0, 2, 4),
    )

    # Display everything
    scroll_speed = int(config.str("speed_choice", DEFAULT_SPEED))
    date_font = "CG-pixel-3x5-mono"
    date_color = "#ffda9c"

    return render.Root(
        delay = scroll_speed,
        show_full_animation = True,
        child = render.Row(
            children = [
                render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        zodiac_icon,
                        render.Padding(
                            child = render.Text(
                                content = date_m,
                                font = date_font,
                                color = date_color,
                            ),
                            pad = (0, 0, 0, 1),
                        ),
                        render.Text(
                            content = date_d,
                            font = date_font,
                            color = date_color,
                        ),
                    ],
                ),
                render.Marquee(
                    child = render.Column(
                        children = [
                            moon_info,
                            render.WrappedText(
                                content = horoscope,
                                font = "tom-thumb",
                            ),
                        ],
                    ),
                    scroll_direction = "vertical",
                    height = 32,
                    offset_start = 26,
                    offset_end = -32,
                ),
            ],
        ),
    )

def edit_horoscope(horoscope):
    # Fixes horoscope to prevent display from cutting off long words
    horoscope_list = horoscope.split()
    horoscope_edit = []
    char_limit = 12

    for w in horoscope_list:
        # Replace apostrophe if it exists
        word = re.sub(r"’", "'", w)
        w_length = len(word)

        # Check last character of word, keep word passes safety list
        pattern_end = r".$"
        last_char = re.findall(pattern_end, word)[0]
        safe_for_last = [".", ",", "!", "'", "-", "i", ")", "1", ":", ";", "`", "|"]

        if w_length == (char_limit + 1) and last_char in safe_for_last:
            horoscope_edit.append(word)

            # Hyphenate and line break at final 'syllable'
        elif w_length > char_limit:
            pattern_end = r"([^aeiouy])([aeiouy]*?[^aeiouy\s]*)$"  # Finds final 'syllable'
            w_end = re.findall(pattern_end, word)[0]
            w_end_length = len(w_end)
            w_start_length = w_length - w_end_length
            pattern_start = r"(^\S{%s})" % w_start_length
            w_start = re.findall(pattern_start, word)[0]
            w_edit = w_start + "-\n" + w_end

            # Replace original word with edited word
            horoscope_edit.append(w_edit)

        else:
            horoscope_edit.append(word)

    return " ".join(horoscope_edit)

def get_moon_info(date):
    # Moon phase and sign at noon UTC on the horoscope date
    noon_utc = time.parse_time(
        date.format("2006-01-02") + "T12:00:00Z",
        format = "2006-01-02T15:04:05Z",
    )

    # Phase from Sun-Moon elongation
    moon_lon = _meeus_moon_lon(noon_utc)
    sun_lon = _sun_longitude(noon_utc)
    elongation = _normalize_deg(moon_lon - sun_lon)

    # Cardinal phase if event falls on this day; otherwise intermediate by quadrant
    if _near_cardinal(elongation, 0.0):
        moon_phase = "NM"
    elif _near_cardinal(elongation, 90.0):
        moon_phase = "FQ"
    elif _near_cardinal(elongation, 180.0):
        moon_phase = "FM"
    elif _near_cardinal(elongation, 270.0):
        moon_phase = "LQ"
    elif elongation < 90.0:
        moon_phase = "XC"
    elif elongation < 180.0:
        moon_phase = "XG"
    elif elongation < 270.0:
        moon_phase = "NG"
    else:
        moon_phase = "NC"

    moon_sign = MSIGNS[_meeus_moon_sign(noon_utc)]

    return moon_phase, moon_sign

def _near_cardinal(elongation, cardinal):
    # True if elongation is within ~6 deg (~half a day) of a cardinal point
    diff = elongation - cardinal
    if diff < 0:
        diff = -diff
    if diff > 180.0:
        diff = 360.0 - diff
    return diff < 6.0

# --- Meeus lunar longitude (Ch 47) and solar longitude (Ch 25) ---
_DEG2RAD = math.pi / 180.0

_ZODIAC_SIGNS = [
    "aries",
    "taurus",
    "gemini",
    "cancer",
    "leo",
    "virgo",
    "libra",
    "scorpio",
    "sagittarius",
    "capricorn",
    "aquarius",
    "pisces",
]

# Periodic terms for the moon longitude (Sigma-l) (Meeus Table 47.A)
# Each row: [D, M, M', F, coefficient (millionths of a degree)]
_MOON_LON_TERMS = [
    [0, 0, 1, 0, 6288774],
    [2, 0, -1, 0, 1274027],
    [2, 0, 0, 0, 658314],
    [0, 0, 2, 0, 213618],
    [0, 1, 0, 0, -185116],
    [0, 0, 0, 2, -114332],
    [2, 0, -2, 0, 58793],
    [2, -1, -1, 0, 57066],
    [2, 0, 1, 0, 53322],
    [2, -1, 0, 0, 45758],
    [0, 1, -1, 0, -40923],
    [1, 0, 0, 0, -34720],
    [0, 1, 1, 0, -30383],
    [2, 0, 0, -2, 15327],
    [0, 0, 1, 2, -12528],
    [0, 0, 1, -2, 10980],
    [4, 0, -1, 0, 10675],
    [0, 0, 3, 0, 10034],
    [4, 0, -2, 0, 8548],
    [2, 1, -1, 0, -7888],
    [2, 1, 0, 0, -6766],
    [1, 0, -1, 0, -5163],
    [1, 1, 0, 0, 4987],
    [2, -1, 1, 0, 4036],
    [2, 0, 2, 0, 3994],
    [4, 0, 0, 0, 3861],
    [2, 0, -3, 0, 3665],
    [0, 1, -2, 0, -2689],
    [2, 0, -1, 2, -2602],
    [2, -1, -2, 0, 2390],
    [1, 0, 1, 0, -2348],
    [2, -2, 0, 0, 2236],
    [0, 1, 2, 0, -2120],
    [0, 2, 0, 0, -2069],
    [2, -2, -1, 0, 2048],
    [2, 0, 1, -2, -1773],
    [2, 0, 0, 2, -1595],
    [4, -1, -1, 0, 1215],
    [0, 0, 2, 2, -1110],
    [3, 0, -1, 0, -892],
    [2, 1, 1, 0, -810],
    [4, -1, -2, 0, 759],
    [0, 2, -1, 0, -713],
    [2, 2, -1, 0, -700],
    [2, 1, -2, 0, 691],
    [2, -1, 0, -2, 596],
    [4, 0, 1, 0, 549],
    [0, 0, 4, 0, 537],
    [4, -1, 0, 0, 520],
    [1, 0, -2, 0, -487],
    [2, 1, 0, -2, -399],
    [0, 0, 2, -2, -381],
    [1, 1, 1, 0, 351],
    [3, 0, -2, 0, -340],
    [4, 0, -3, 0, 330],
    [2, -1, 2, 0, 327],
    [0, 2, 1, 0, -323],
    [1, 1, -1, 0, 299],
    [2, 0, 3, 0, 294],
]

def _normalize_deg(d):
    # Reduce an angle to [0, 360)
    d = d % 360.0
    if d < 0:
        d = d + 360.0
    return d

def _julian_day(year, month, day, hour, minute, second):
    # Compute Julian Day Number from Gregorian calendar date (Meeus Ch 7)
    y = year
    m = month
    if m <= 2:
        y = y - 1
        m = m + 12
    a = int(y // 100)
    b = 2 - a + int(a // 4)
    day_frac = day + (hour + minute / 60.0 + second / 3600.0) / 24.0
    return int(365.25 * (y + 4716)) + int(30.6001 * (m + 1)) + day_frac + b - 1524.5

def _meeus_moon_lon(t):
    # Ecliptic longitude of moon in degrees (Meeus Ch 47)
    year = int(t.format("2006"))
    month = int(t.format("1"))
    day = int(t.format("2"))
    hour = int(t.format("15"))
    minute = int(t.format("4"))
    second = int(t.format("5"))

    jd = _julian_day(year, month, day, hour, minute, second)
    tc = (jd - 2451545.0) / 36525.0
    tc2 = tc * tc
    tc3 = tc2 * tc
    tc4 = tc3 * tc

    lp = _normalize_deg(218.3164477 + 481267.88123421 * tc - 0.0015786 * tc2 + tc3 / 538841.0 - tc4 / 65194000.0)
    d = _normalize_deg(297.8501921 + 445267.1114034 * tc - 0.0018819 * tc2 + tc3 / 545868.0 - tc4 / 113065000.0)
    m = _normalize_deg(357.5291092 + 35999.0502909 * tc - 0.0001536 * tc2 + tc3 / 24490000.0)
    mp = _normalize_deg(134.9633964 + 477198.8675055 * tc + 0.0087414 * tc2 + tc3 / 69699.0 - tc4 / 14712000.0)
    f = _normalize_deg(93.2720950 + 483202.0175233 * tc - 0.0036539 * tc2 - tc3 / 3526000.0 + tc4 / 863310000.0)

    a1 = _normalize_deg(119.75 + 131.849 * tc)
    a2 = _normalize_deg(53.09 + 479264.290 * tc)

    e = 1.0 - 0.002516 * tc - 0.0000074 * tc2
    e2 = e * e

    sigma_l = 0.0
    for row in _MOON_LON_TERMS:
        d_c = row[0]
        m_c = row[1]
        mp_c = row[2]
        f_c = row[3]
        coeff = row[4]
        arg = (d_c * d + m_c * m + mp_c * mp + f_c * f) * _DEG2RAD
        term = coeff * math.sin(arg)
        m_abs = m_c
        if m_abs < 0:
            m_abs = -m_abs
        if m_abs == 1:
            term = term * e
        elif m_abs == 2:
            term = term * e2
        sigma_l = sigma_l + term

    sigma_l = sigma_l + 3958.0 * math.sin(a1 * _DEG2RAD)
    sigma_l = sigma_l + 1962.0 * math.sin((lp - f) * _DEG2RAD)
    sigma_l = sigma_l + 318.0 * math.sin(a2 * _DEG2RAD)

    return _normalize_deg(lp + sigma_l / 1000000.0)

def _meeus_moon_sign(t):
    # Return zodiac sign moon is in at time t
    lon = _meeus_moon_lon(t)
    sign_index = int(lon / 30.0)
    if sign_index > 11:
        sign_index = 0
    return _ZODIAC_SIGNS[sign_index]

def _sun_longitude(t):
    # Apparent ecliptic longitude of the sun in degrees (Meeus Ch 25)
    year = t.year
    month = t.month
    day = t.day
    hour = t.hour
    minute = t.minute
    second = t.second

    jd = _julian_day(year, month, day, hour, minute, second)
    tc = (jd - 2451545.0) / 36525.0
    tc2 = tc * tc

    l0 = _normalize_deg(280.46646 + 36000.76983 * tc + 0.0003032 * tc2)
    m = _normalize_deg(357.52911 + 35999.05029 * tc - 0.0001537 * tc2)
    m_rad = m * _DEG2RAD

    c = (1.914602 - 0.004817 * tc - 0.000014 * tc2) * math.sin(m_rad)
    c = c + (0.019993 - 0.000101 * tc) * math.sin(2.0 * m_rad)
    c = c + 0.000289 * math.sin(3.0 * m_rad)

    return _normalize_deg(l0 + c)

def get_schema():
    # Options menu
    return schema.Schema(
        version = "1",
        fields = [
            # Select zodiac sign
            schema.Dropdown(
                id = "zodiac_choice",
                name = "Zodiac sign",
                desc = "The zodiac sign you wish to follow",
                icon = "star",
                options = [
                    schema.Option(display = "Aries", value = "aries"),
                    schema.Option(display = "Taurus", value = "taurus"),
                    schema.Option(display = "Gemini", value = "gemini"),
                    schema.Option(display = "Cancer", value = "cancer"),
                    schema.Option(display = "Leo", value = "leo"),
                    schema.Option(display = "Virgo", value = "virgo"),
                    schema.Option(display = "Libra", value = "libra"),
                    schema.Option(display = "Scorpio", value = "scorpio"),
                    schema.Option(display = "Sagittarius", value = "sagittarius"),
                    schema.Option(display = "Capricorn", value = "capricorn"),
                    schema.Option(display = "Aquarius", value = "aquarius"),
                    schema.Option(display = "Pisces", value = "pisces"),
                ],
                default = DEFAULT_SIGN,
            ),

            # Select icon color
            schema.Color(
                id = "color_choice",
                name = "Icon color",
                desc = "Choose a color for the zodiac icon",
                icon = "palette",
                palette = [
                    DEFAULT_COLOR,  # purple
                    "#A59418",  # yellow
                    "#0F7F3F",  # green
                    "#AC1E27",  # red
                    "#2B8ABA",  # blue
                ],
                default = DEFAULT_COLOR,
            ),

            # Toggle show moon info
            schema.Toggle(
                id = "moon_choice",
                name = "Show moon phase/sign",
                desc = "Show or hide the current moon phase/sign",
                icon = "moon",
                default = DEFAULT_MOON,
            ),

            # Select scroll speed
            schema.Dropdown(
                id = "speed_choice",
                name = "Scroll speed",
                desc = "How fast the horoscope scrolls",
                icon = "gaugeSimpleHigh",
                options = [
                    schema.Option(display = "Slower", value = "120"),
                    schema.Option(display = "Slow", value = "90"),
                    schema.Option(display = "Normal", value = DEFAULT_SPEED),
                    schema.Option(display = "Fast", value = "55"),
                    schema.Option(display = "Faster", value = "40"),
                ],
                default = DEFAULT_SPEED,
            ),
        ],
    )
