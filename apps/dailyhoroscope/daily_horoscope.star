"""
Applet: Daily Horoscope
Summary: Daily horoscope
Description: Displays the daily horoscope for a specific sign from USA Today.
Author: frame-shift

Version 1.1.1
"""

load("encoding/base64.star", "base64")
load("html.star", "html")
load("http.star", "http")
load("humanize.star", "humanize")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/img_04259440.png", IMG_04259440_ASSET = "file")
load("images/img_125d6710.png", IMG_125d6710_ASSET = "file")
load("images/img_172c6fc5.png", IMG_172c6fc5_ASSET = "file")
load("images/img_1ffead42.png", IMG_1ffead42_ASSET = "file")
load("images/img_2c4c03b2.png", IMG_2c4c03b2_ASSET = "file")
load("images/img_4bd43207.png", IMG_4bd43207_ASSET = "file")
load("images/img_57ae7562.png", IMG_57ae7562_ASSET = "file")
load("images/img_58e7ceda.png", IMG_58e7ceda_ASSET = "file")
load("images/img_6350ed59.png", IMG_6350ed59_ASSET = "file")
load("images/img_63abc988.png", IMG_63abc988_ASSET = "file")
load("images/img_63e4fa16.png", IMG_63e4fa16_ASSET = "file")
load("images/img_68001971.png", IMG_68001971_ASSET = "file")
load("images/img_6ea6c5b0.png", IMG_6ea6c5b0_ASSET = "file")
load("images/img_9dfa334f.png", IMG_9dfa334f_ASSET = "file")
load("images/img_aafdd643.png", IMG_aafdd643_ASSET = "file")
load("images/img_ab5bfdd7.png", IMG_ab5bfdd7_ASSET = "file")
load("images/img_b09f0a92.png", IMG_b09f0a92_ASSET = "file")
load("images/img_b0d420cc.png", IMG_b0d420cc_ASSET = "file")
load("images/img_e4fdea21.png", IMG_e4fdea21_ASSET = "file")
load("images/img_fe65eea4.png", IMG_fe65eea4_ASSET = "file")

# Set default values
DEFAULT_SIGN = "aries"
DEFAULT_SPEED = "70"
DEFAULT_MOON = True
DEFAULT_COLOR = "#994BA1"

TTL = 3600  # One hour

# 12x12 zodiac icons w/ transparent bg
SIGN_ICONS = {
    "aries": IMG_6ea6c5b0_ASSET.readall(),
    "aquarius": IMG_04259440_ASSET.readall(),
    "cancer": IMG_fe65eea4_ASSET.readall(),
    "capricorn": IMG_aafdd643_ASSET.readall(),
    "gemini": IMG_58e7ceda_ASSET.readall(),
    "leo": IMG_6350ed59_ASSET.readall(),
    "libra": IMG_b0d420cc_ASSET.readall(),
    "pisces": IMG_4bd43207_ASSET.readall(),
    "sagittarius": IMG_125d6710_ASSET.readall(),
    "scorpio": IMG_63e4fa16_ASSET.readall(),
    "taurus": IMG_2c4c03b2_ASSET.readall(),
    "virgo": IMG_1ffead42_ASSET.readall(),
}

# 6x6 moon phase icons
MPHASE_ICONS = {
    "NM": IMG_b09f0a92_ASSET.readall(),
    "XC": IMG_e4fdea21_ASSET.readall(),
    "FQ": IMG_ab5bfdd7_ASSET.readall(),
    "XG": IMG_9dfa334f_ASSET.readall(),
    "FM": IMG_63abc988_ASSET.readall(),
    "NG": IMG_68001971_ASSET.readall(),
    "LQ": IMG_172c6fc5_ASSET.readall(),
    "NC": IMG_57ae7562_ASSET.readall(),
}

# Moon phases
MPHASES = {
    "new moon": "NM",
    "waxing crescent": "XC",
    "first quarter": "FQ",
    "waxing gibbous": "XG",
    "full moon": "FM",
    "waning gibbous": "NG",
    "last quarter": "LQ",
    "waning crescent": "NC",
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
    horoscope_url = "https://www.usatoday.com/horoscopes/daily/" + zodiac  # Updates daily at 09:00 UTC
    scope_response = http.get(horoscope_url, ttl_seconds = TTL)

    if scope_response.status_code != 200:
        return render_error("Could not reach source")

    scope_html = html(scope_response.body())

    # Parse date that horoscope was written
    date_extracted = scope_html.find("time").attr("datetime")

    if date_extracted == None:
        return render_error("Could not get date")

    date_parsed = time.parse_time(date_extracted, format = "2006-01-02")
    date_m = humanize.time_format("MMM", date_parsed).upper()
    date_d = humanize.time_format("d", date_parsed)

    # Parse horoscope
    horoscope_parsed = scope_html.find("p").eq(1).text()

    if horoscope_parsed == "":
        return render_error("Could not get horoscope")

    horoscope = edit_horoscope(horoscope_parsed)

    # Render moon data
    if show_moon:
        moon_phase, moon_sign = get_moon_info(date_parsed)
        moon_icon = base64.decode(MPHASE_ICONS[moon_phase])
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
    sign_img = base64.decode(SIGN_ICONS[zodiac])
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
    # Gets current moon phase and sign for horoscope date
    date_m = humanize.time_format("MMMM", date).lower()
    date_y = humanize.time_format("yyyy", date)
    date_d = humanize.time_format("d", date)

    moon_url = "https://mooncalendar.astro-seek.com/moon-phase-day-%s-%s-%s" % (date_d, date_m, date_y)

    moon_res = http.get(moon_url, ttl_seconds = TTL)

    if moon_res.status_code != 200:
        return render_error("Could not reach moon info")

    moon_html = html(moon_res.body())

    raw_phase = moon_html.find("table").eq(0).find("td").eq(5).text().strip().lower()  # moon phase e.g. 'waxing gibbous'
    raw_sign = moon_html.find("table").eq(0).find("td").eq(6).text().strip().lower()  # moon sign e.g. 'libra'

    # Remove superfluous time string if phase is New Moon / Full Moon
    edit_phase = re.sub(r"at.*", "", raw_phase)

    moon_phase = MPHASES[edit_phase]
    moon_sign = MSIGNS[raw_sign]

    return moon_phase, moon_sign

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
