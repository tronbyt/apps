"""
Applet: Nightscout
Summary: Displays Nightscout CGM Data
Description: Displays Continuous Glucose Monitoring (CGM) blood sugar data (BG, Trend, Delta, IOB, COB) from Nightscout. Will display blood sugar as mg/dL or mmol/L. Optionally display historical readings on a graph. Also a clock.
For support, join the Nightscout for Tidbyt Facebook group.
(v2.6.2)
Authors: Paul Murphy, Jason Hanson, Jeremy Tavener
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("hash.star", "hash")
load("http.star", "http")
load("math.star", "math")
load("render.star", "canvas", "render")
load("sample_entries.json", SAMPLE_DATA = "file")
load("schema.star", "schema")
load("sunrise.star", "sunrise")
load("time.star", "time")

IS_2X = canvas.is2x()
SCALE = 2 if IS_2X else 1

FONT_TINY = "terminus-14-light" if IS_2X else "tom-thumb"
FONT_SMALL = "terminus-14-light" if IS_2X else "tb-8"
FONT_SMALL_NARROW = "6x13" if IS_2X else "5x8"
FONT_MEDIUM = "terminus-28" if IS_2X else "6x13"
FONT_LARGE = "terminus-32" if IS_2X else "10x20"
FONT_ARROW = "10x20" if IS_2X else "tb-8"

COLOR_BLACK = "#000"
COLOR_PINK = "#F8A7A7"
COLOR_RED = "#C00"
COLOR_DARK_RED = "#911"
COLOR_BRIGHT_RED = "#F10404"
COLOR_YELLOW = "#ff8"
COLOR_ORANGE = "#d61"
COLOR_GREEN = "#2b3"
COLOR_BRIGHT_GREEN = "#03FF20"
COLOR_DARK_GREEN = "#087C15"
COLOR_BLUE = "#00D0FF"
COLOR_DARK_BLUE = "#0676FF"
COLOR_PURPLE = "#7701FF"
COLOR_MAGENTA = "#FF00D0"
COLOR_GREY = "#777"
COLOR_WHITE = "#fff"
COLOR_NIGHT = "#444"
COLOR_HOURS = "#222"
PALETTE = [
    COLOR_BLACK,
    COLOR_WHITE,
    COLOR_GREY,
    COLOR_RED,
    COLOR_DARK_RED,
    COLOR_PINK,
    COLOR_ORANGE,
    COLOR_YELLOW,
    COLOR_BRIGHT_GREEN,
    COLOR_GREEN,
    COLOR_DARK_GREEN,
    COLOR_BLUE,
    COLOR_DARK_BLUE,
    COLOR_PURPLE,
    COLOR_MAGENTA,
    COLOR_BRIGHT_RED,
]

DEFAULT_DISPLAY_UNIT = "mgdl"
DEFAULT_NORMAL_HIGH = 180
DEFAULT_NORMAL_LOW = 100
DEFAULT_URGENT_HIGH = 200
DEFAULT_URGENT_LOW = 70

DEFAULT_SHOW_GRAPH = True
DEFAULT_SHOW_GRAPH_HOUR_BARS = True
DEFAULT_EXPAND_GRAPH_HEIGHT = True
DEFAULT_GRAPH_HEIGHT = 300
DEFAULT_CLOCK_OPTION = "Clock"
DEFAULT_CLOCK_COLOR = COLOR_ORANGE
DEFAULT_NIGHT_COLOR = COLOR_NIGHT
DEFAULT_ID_BORDER_COLOR = COLOR_BLACK
DEFAULT_IN_RANGE_BG_COLOR = COLOR_GREEN
DEFAULT_HIGH_BG_COLOR = COLOR_YELLOW
DEFAULT_LOW_BG_COLOR = COLOR_YELLOW
DEFAULT_URGENT_HIGH_COLOR = COLOR_RED
DEFAULT_URGENT_LOW_COLOR = COLOR_RED
DEFAULT_TIME_AGO_COLOR = COLOR_GREY
DEFAULT_SHOW_24_HOUR_TIME = False
DEFAULT_NIGHT_MODE = False
GRAPH_BOTTOM = 40

MIN_CACHE_TTL = 10 * time.second
READING_AGE_THRESHOLD = 5 * time.minute + 30 * time.second

DEFAULT_LOCATION = """
{
    "lat": "40.666250",
    "lng": "-111.910780",
    "description": "Taylorsville, UT, USA",
    "locality": "Taylorsville",
    "place_id": "ChIJ_wlEps6LUocRJ9DmE4xv9OI",
    "timezone": "America/Denver"
}
"""

DEFAULT_NSURL = ""
DEFAULT_NSTOKEN = ""

ARROWS = {
    "None": "",
    "NONE": "",
    "DoubleDown": "↓↓",
    "DoubleUp": "↑↑",
    "Flat": "→",
    "FortyFiveDown": "↘",
    "FortyFiveUp": "↗",
    "SingleDown": "↓",
    "SingleUp": "↑",
    "Error": "?",
    "Dash": "-",
    "NOT COMPUTABLE": "?",
}

def main(config):
    UTC_TIME_NOW = time.now().in_location("UTC")
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    now = time.now().in_location(loc["timezone"])
    lat, lng = float(loc["lat"]), float(loc["lng"])
    sun_rise = sunrise.sunrise(lat, lng, now)
    sun_set = sunrise.sunset(lat, lng, now)
    nightscout_url = config.get("nightscout_url", DEFAULT_NSURL)
    nightscout_token = config.get("nightscout_token", DEFAULT_NSTOKEN)
    show_graph = config.bool("show_graph", DEFAULT_SHOW_GRAPH)
    show_graph_hour_bars = config.bool("show_graph_hour_bars", DEFAULT_SHOW_GRAPH_HOUR_BARS)
    expand_graph_height = config.bool("expand_graph_height", DEFAULT_EXPAND_GRAPH_HEIGHT)
    display_unit = config.get("display_unit", DEFAULT_DISPLAY_UNIT)
    clock_option = config.get("clock_option", DEFAULT_CLOCK_OPTION)
    clock_color = config.get("clock_color", DEFAULT_CLOCK_COLOR)
    iob_color = config.get("iob_color", DEFAULT_CLOCK_COLOR)
    cob_color = config.get("cob_color", DEFAULT_CLOCK_COLOR)
    id_border_color = config.get("id_border_color", DEFAULT_ID_BORDER_COLOR)
    in_range_color = config.get("in_range_color", DEFAULT_IN_RANGE_BG_COLOR)
    high_color = config.get("high_color", DEFAULT_HIGH_BG_COLOR)
    low_color = config.get("low_color", DEFAULT_LOW_BG_COLOR)
    urgent_high_color = config.get("urgent_high_color", DEFAULT_URGENT_HIGH_COLOR)
    urgent_low_color = config.get("urgent_low_color", DEFAULT_URGENT_LOW_COLOR)
    night_color = config.get("night_color", DEFAULT_NIGHT_COLOR)
    time_ago_color = config.get("time_ago_color", DEFAULT_TIME_AGO_COLOR)
    show_24_hour_time = config.bool("show_24_hour_time", DEFAULT_SHOW_24_HOUR_TIME)
    night_mode = config.bool("night_mode", DEFAULT_NIGHT_MODE)
    nightscout_iob = "n/a"
    nightscout_cob = "n/a"
    sample_data = False

    if nightscout_url == "":
        sample_data = True
        nightscout_data = get_sample_data(display_unit)
    else:
        nightscout_data, status_code = get_nightscout_data(nightscout_url, nightscout_token, show_graph, display_unit)
        if status_code > 200:
            return display_failure("Nightscout Error: " + str(status_code) + " " + http.status_text(status_code))

    # Pull the data from the cache
    sgv_current_mgdl = int(nightscout_data["sgv_current"])
    sgv_delta = nightscout_data["sgv_delta"]
    latest_reading_dt = nightscout_data["latest_reading_date"]
    direction = nightscout_data["direction"]
    nightscout_iob = nightscout_data["iob"]
    nightscout_cob = nightscout_data["cob"]
    history = nightscout_data["history"]

    if display_unit == "mgdl":
        graph_height = int(str(config.get("mgdl_graph_height", DEFAULT_GRAPH_HEIGHT)))
        normal_high = int(str(config.get("mgdl_normal_high", DEFAULT_NORMAL_HIGH)))
        normal_low = int(str(config.get("mgdl_normal_low", DEFAULT_NORMAL_LOW)))
        urgent_high = int(str(config.get("mgdl_urgent_high", DEFAULT_URGENT_HIGH)))
        urgent_low = int(str(config.get("mgdl_urgent_low", DEFAULT_URGENT_LOW)))
        str_current = str(int(sgv_current_mgdl))

        # Delta
        str_delta = str(int(sgv_delta))
        if (int(sgv_delta) >= 0):
            str_delta = "+" + str_delta
    else:
        graph_height = int(float(config.get("mmol_graph_height", mgdl_to_mmol(DEFAULT_GRAPH_HEIGHT))) * 18)
        normal_high = int(float(config.get("mmol_normal_high", mgdl_to_mmol(DEFAULT_NORMAL_HIGH))) * 18)
        normal_low = int(float(config.get("mmol_normal_low", mgdl_to_mmol(DEFAULT_NORMAL_LOW))) * 18)
        urgent_high = int(float(config.get("mmol_urgent_high", mgdl_to_mmol(DEFAULT_URGENT_HIGH))) * 18)
        urgent_low = int(float(config.get("mmol_urgent_low", mgdl_to_mmol(DEFAULT_URGENT_LOW))) * 18)

        sgv_current = mgdl_to_mmol(sgv_current_mgdl)
        str_current = str(sgv_current)

        str_delta = str(sgv_delta)
        if (str_delta == "0.0"):
            str_delta = "+0"
        elif (sgv_delta > 0):
            str_delta = "+" + str_delta

    str_delta = str_delta.replace("0", "O")

    left_col_width = 50 if IS_2X else 28
    graph_width = 74 if IS_2X else 34

    OLDEST_READING_TARGET = UTC_TIME_NOW - graph_width * 5 * time.minute

    reading_mins_ago = int((UTC_TIME_NOW - latest_reading_dt).minutes)

    if (reading_mins_ago < 1):
        human_reading_ago = "<1 min ago"
    elif (reading_mins_ago == 1):
        human_reading_ago = "1 min ago"
    else:
        hours_ago = str(int(reading_mins_ago / 60))
        mins_ago = int(math.mod(int(reading_mins_ago), 60))
        human_reading_ago = (hours_ago + ":" + ("0" + str(mins_ago) if mins_ago < 10 else str(mins_ago)) + " ago") if int(hours_ago) > 0 else str(mins_ago) + " mins ago"

    ago_dashes = "-" * reading_mins_ago
    full_ago_dashes = ago_dashes

    # Default state is yellow to make the logic easier
    color_reading = COLOR_YELLOW
    color_delta = COLOR_YELLOW
    color_arrow = COLOR_YELLOW
    color_ago = time_ago_color
    color_graph_urgent_high = urgent_high_color
    color_graph_high = high_color
    color_graph_normal = in_range_color
    color_graph_low = low_color
    color_graph_urgent_low = urgent_low_color
    color_graph_lines = COLOR_GREY
    color_clock = clock_color
    color_iob = iob_color
    color_cob = cob_color
    color_id_border = id_border_color
    hour_marker_color = COLOR_HOURS

    if (reading_mins_ago > 5):
        # The information is stale (i.e. over 5 minutes old) - overrides everything.
        color_reading = color_ago
        color_delta = color_ago
        color_arrow = color_ago
        color_iob = color_ago
        color_cob = color_ago
        direction = "None"
        str_delta = human_reading_ago
        ago_dashes = ">" + str(reading_mins_ago)
        full_ago_dashes = ""
    elif (sgv_current_mgdl < normal_high and sgv_current_mgdl > normal_low):
        # We're in the normal range, so use in_range_color.
        color_reading = in_range_color
        color_delta = in_range_color
        color_arrow = in_range_color
    elif (sgv_current_mgdl >= normal_high and sgv_current_mgdl < urgent_high):
        # We're in the  high range, so use high_color.
        color_reading = high_color
        color_delta = high_color
        color_arrow = high_color
    elif (sgv_current_mgdl >= urgent_high):
        # We're in the urgent high range, so use urgent_high_color.
        color_reading = urgent_high_color
        color_delta = urgent_high_color
        color_arrow = urgent_high_color
    elif (sgv_current_mgdl <= normal_low and sgv_current_mgdl > urgent_low):
        # We're in the  low range, so use low_color.
        color_reading = low_color
        color_delta = low_color
        color_arrow = low_color
    elif (sgv_current_mgdl <= urgent_low):
        # We're in the urgent low range, so use urgent_low_color.
        color_reading = urgent_low_color
        color_delta = urgent_low_color
        color_arrow = urgent_low_color

    if (night_mode and (now > sun_set or now < sun_rise)):
        color_reading = night_color
        color_delta = night_color
        color_arrow = night_color
        color_ago = night_color
        color_graph_urgent_high = night_color
        color_graph_high = night_color
        color_graph_normal = night_color
        color_graph_low = night_color
        color_graph_urgent_low = night_color
        color_graph_lines = night_color
        color_clock = night_color
        hour_marker_color = night_color

    # Build layouts
    if clock_option == "None":
        one_column_string, left_column_string = build_no_clock_layouts(
            str_current,
            str_delta,
            direction,
            reading_mins_ago,
            full_ago_dashes,
            color_reading,
            color_delta,
            color_arrow,
            color_ago,
            color_id_border,
            left_col_width,
        )
    else:
        one_column_string, left_column_string = build_clock_layouts(
            clock_option,
            now,
            show_24_hour_time,
            nightscout_iob,
            nightscout_cob,
            str_current,
            str_delta,
            direction,
            reading_mins_ago,
            full_ago_dashes,
            color_reading,
            color_delta,
            color_arrow,
            color_ago,
            color_clock,
            color_iob,
            color_cob,
            color_id_border,
            left_col_width,
        )

    # Assemble output
    if not show_graph:
        output = [
            render.Box(
                render.Row(
                    main_align = "space_evenly",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Column(
                            cross_align = "center",
                            main_align = "space_between",
                            expanded = True,
                            children = one_column_string,
                        ),
                    ],
                ),
            ),
        ]
    else:
        graph_plot, graph_hour_bars, graph_height = build_graph(
            history,
            graph_width,
            graph_height,
            expand_graph_height,
            normal_high,
            normal_low,
            urgent_high,
            urgent_low,
            color_graph_normal,
            color_graph_high,
            color_graph_urgent_high,
            color_graph_low,
            color_graph_urgent_low,
            show_graph_hour_bars,
            hour_marker_color,
            OLDEST_READING_TARGET,
        )
        output = build_two_column_output(
            left_column_string,
            graph_plot,
            graph_hour_bars,
            graph_width,
            graph_height,
            normal_low,
            normal_high,
            color_graph_lines,
            color_id_border,
        )

    if sample_data == True:
        output = [
            render.Stack(
                children = [
                    render.Row(
                        children = output,
                    ),
                    render.Animation(
                        children = [
                            render.WrappedText(
                                width = 64 * SCALE,
                                align = "center",
                                font = "terminus-32-light" if IS_2X else "10x20",
                                color = "#f00",
                                linespacing = 0 if IS_2X else -6,
                                content = "SAMPLE DATA",
                            ),
                            render.Box(),
                        ],
                    ),
                ],
            ),
        ]

    return render.Root(
        max_age = 120,
        child = render.Row(
            children = output,
        ),
        delay = 500,
    )

def build_no_clock_layouts(str_current, str_delta, direction, reading_mins_ago, full_ago_dashes, color_reading, color_delta, color_arrow, color_ago, color_id_border, left_col_width):
    """Builds one_column_string and left_column_string for no-clock mode."""
    if (reading_mins_ago > 5):
        one_column_delta_row = [
            render.Box(
                width = 2 * SCALE,
                height = 17 * SCALE,
            ),
            render.Row(
                cross_align = "center",
                main_align = "center",
                expanded = True,
                children = [
                    render.WrappedText(
                        content = str_delta,
                        font = "terminus-20-light" if IS_2X else "5x8",
                        color = color_delta,
                        align = "center",
                        linespacing = -3 * SCALE,
                    ),
                ],
            ),
        ]
    else:
        one_column_delta_row = [
            render.Box(
                width = 2 * SCALE,
                height = 16 * SCALE,
            ),
            render.Row(
                cross_align = "center",
                main_align = "center",
                expanded = True,
                children = [
                    render.Box(
                        width = 2 * SCALE,
                        height = SCALE,
                    ),
                    render.Text(
                        content = str_delta,
                        font = "terminus-20-light" if IS_2X else "6x13",
                        color = color_delta,
                        offset = 0,
                    ),
                    render.Text(
                        content = " " + ARROWS[direction],
                        font = FONT_ARROW,
                        color = color_arrow,
                        offset = 0,
                    ),
                ],
            ),
        ]

    one_column_string = [
        render.Stack(
            children = [
                render.Box(
                    height = 32 * SCALE,
                    width = 64 * SCALE,
                    color = color_id_border,
                    child = render.Box(
                        height = 30 * SCALE,
                        width = 62 * SCALE,
                        color = COLOR_BLACK,
                    ),
                ),
                render.Column(
                    main_align = "start",
                    cross_align = "center",
                    children = [
                        render.Row(
                            cross_align = "center",
                            main_align = "space_evenly",
                            expanded = True,
                            children = [
                                render.Text(
                                    content = str_current,
                                    font = FONT_LARGE,
                                    color = color_reading,
                                    offset = 0,
                                ),
                            ],
                        ),
                    ],
                ),
                render.Column(
                    main_align = "start",
                    cross_align = "center",
                    children = one_column_delta_row,
                ),
                render.Column(
                    main_align = "start",
                    cross_align = "center",
                    children = [
                        render.Box(height = 26 * SCALE),
                        render.Row(
                            cross_align = "center",
                            main_align = "space_evenly",
                            expanded = True,
                            children = [
                                render.Text(
                                    content = full_ago_dashes,
                                    font = FONT_TINY,
                                    color = color_ago,
                                    offset = -SCALE,
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    ]

    if (reading_mins_ago > 5):
        left_delta_row = [
            render.WrappedText(
                content = str_delta,
                font = "10x13" if IS_2X else "CG-pixel-3x5-mono",
                color = color_delta,
                linespacing = 2 * SCALE,
                width = left_col_width,
                height = 14 * SCALE,
                align = "center",
            ),
        ]
    else:
        left_delta_row = [
            render.Text(
                content = str_delta,
                font = FONT_SMALL,
                color = color_delta,
                offset = 0,
            ),
            render.Box(
                height = SCALE,
                width = 4 if IS_2X else 1,
            ),
            render.Text(
                content = ARROWS[direction],
                font = FONT_SMALL_NARROW,
                color = color_arrow,
                offset = 0,
            ),
        ]

    left_column_string = [
        render.Row(
            children = [
                render.Box(
                    height = 3 * SCALE,
                    width = SCALE,
                ),
            ],
        ),
        render.Row(
            children = [
                render.WrappedText(
                    content = str_current,
                    font = FONT_MEDIUM,
                    color = color_reading,
                    width = left_col_width,
                    height = 14 * SCALE,
                    align = "center",
                ),
            ],
        ),
        render.Row(
            children = left_delta_row,
        ),
        render.Row(
            children = [
                render.Box(
                    height = 2 * SCALE,
                    width = SCALE,
                ),
            ],
        ),
        render.Row(
            main_align = "start",
            cross_align = "start",
            children = [
                render.WrappedText(
                    content = full_ago_dashes,
                    font = FONT_TINY,
                    color = color_ago,
                    width = left_col_width,
                    align = "center",
                ),
            ],
        ),
    ]

    return one_column_string, left_column_string

def build_clock_layouts(clock_option, now, show_24_hour_time, nightscout_iob, nightscout_cob, str_current, str_delta, direction, reading_mins_ago, full_ago_dashes, color_reading, color_delta, color_arrow, color_ago, color_clock, color_iob, color_cob, color_id_border, left_col_width):
    """Builds one_column_string and left_column_string for clock/IOB/COB mode."""
    lg_clock_row = []
    sm_clock_row = []

    if clock_option == "Clock":
        formats = [
            now.format("15:04" if show_24_hour_time else "3:04"),
            now.format("15 04" if show_24_hour_time else "3 04"),
        ]

        lg_clock_row = [
            render.Box(height = SCALE),
            render.Row(
                cross_align = "center",
                main_align = "space_evenly",
                expanded = True,
                children = [
                    render.Animation(
                        children = [
                            render.Text(
                                content = content,
                                font = FONT_MEDIUM,
                                color = color_clock,
                            )
                            for content in formats
                        ],
                    ),
                ],
            ),
        ]

        sm_clock_row = [
            render.WrappedText(
                content = content,
                font = FONT_TINY,
                color = color_clock,
                width = left_col_width,
                align = "center",
                height = 6 * SCALE,
            )
            for content in formats
        ]

    elif clock_option == "IOB" or clock_option == "COB":
        lg_clock_row = [
            render.Box(height = 14 * SCALE),
            render.Row(
                cross_align = "center",
                main_align = "space_evenly",
                expanded = True,
                children = [
                    render.Text(
                        content = nightscout_iob if clock_option == "IOB" else nightscout_cob,
                        font = "terminus-24" if IS_2X else "6x13",
                        color = color_iob if clock_option == "IOB" else color_cob,
                    ),
                ],
            ),
        ]

        sm_clock_row = [
            render.WrappedText(
                content = nightscout_iob if clock_option == "IOB" else nightscout_cob,
                font = "6x10" if IS_2X else "tom-thumb",
                color = color_iob if clock_option == "IOB" else color_cob,
                width = left_col_width,
                align = "center",
                height = 6 * SCALE,
            ),
        ]

    # One column layout (no graph)
    if (reading_mins_ago > 5):
        one_column_delta_row = [
            render.Box(
                width = 2 * SCALE,
                height = 14 * SCALE if clock_option == "Clock" else SCALE,
            ),
            render.Row(
                cross_align = "center",
                main_align = "start",
                expanded = True,
                children = [
                    render.Box(
                        width = 7 * SCALE,
                        height = 18 * SCALE,
                    ),
                    render.WrappedText(
                        content = str_current,
                        font = FONT_MEDIUM,
                        color = color_reading,
                        width = 40 if IS_2X else 18,
                        align = "center",
                        height = 18 * SCALE,
                    ),
                    render.Box(
                        width = 4 * SCALE,
                        height = 18 * SCALE,
                    ),
                    render.WrappedText(
                        content = str_delta,
                        font = "terminus-12" if IS_2X else "tom-thumb",
                        color = color_delta,
                        align = "center",
                        width = 30 * SCALE,
                        linespacing = 0,
                        height = 14 * SCALE,
                    ),
                    render.Box(
                        width = 5 * SCALE,
                        height = 18 * SCALE,
                    ),
                ],
            ),
        ]
    else:
        one_column_delta_row = [
            render.Box(height = 14 * SCALE if clock_option == "Clock" else SCALE),
            render.Row(
                cross_align = "center",
                main_align = "center",
                expanded = True,
                children = [
                    render.Text(
                        content = str_current,
                        font = FONT_MEDIUM,
                        color = color_reading,
                    ),
                    render.Text(
                        content = " " + str_delta,
                        font = FONT_SMALL,
                        color = color_delta,
                        offset = -SCALE,
                    ),
                    render.Text(
                        content = " " + ARROWS[direction],
                        font = FONT_ARROW,
                        color = color_arrow,
                        offset = -SCALE,
                    ),
                ],
            ),
        ]

    one_column_string = [
        render.Stack(
            children = [
                render.Box(
                    height = 32 * SCALE,
                    width = 64 * SCALE,
                    color = color_id_border,
                    child = render.Box(
                        height = 30 * SCALE,
                        width = 62 * SCALE,
                        color = COLOR_BLACK,
                    ),
                ),
                render.Column(
                    main_align = "start",
                    cross_align = "center",
                    children = lg_clock_row,
                ),
                render.Column(
                    main_align = "start",
                    cross_align = "center",
                    children = one_column_delta_row,
                ),
                render.Column(
                    main_align = "start",
                    cross_align = "center",
                    children = [
                        render.Box(height = 27 * SCALE),
                        render.Row(
                            cross_align = "center",
                            main_align = "space_evenly",
                            expanded = True,
                            children = [
                                render.Text(
                                    content = full_ago_dashes,
                                    font = FONT_TINY,
                                    color = color_ago,
                                    offset = 0,
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    ]

    # Left column layout (for graph mode)
    if (reading_mins_ago > 5):
        left_delta_row = [
            render.Box(
                width = left_col_width,
                height = 20 if IS_2X else 12,
                child = render.WrappedText(
                    content = str_delta,
                    font = "6x10" if IS_2X else "CG-pixel-3x5-mono",
                    color = color_delta,
                    linespacing = 0 if IS_2X else 1,
                    align = "center",
                ),
            ),
        ]
    else:
        left_delta_row = [
            render.Text(
                content = str_delta,
                font = FONT_SMALL,
                color = color_delta,
                offset = 0,
            ),
            render.Box(
                height = 14 if IS_2X else 9,
                width = 4 if IS_2X else 1,
            ),
            render.Text(
                content = ARROWS[direction],
                font = FONT_SMALL_NARROW,
                color = color_arrow,
                offset = 0,
            ),
        ]

    left_column_string = [
        render.Row(
            children = [
                render.Box(
                    height = SCALE,
                    width = SCALE,
                ),
            ],
        ),
        render.Row(
            main_align = "center",
            cross_align = "start",
            children = [
                render.WrappedText(
                    content = str_current,
                    font = FONT_MEDIUM,
                    color = color_reading,
                    width = left_col_width,
                    height = 12 * SCALE,
                    align = "center",
                ),
            ],
        ),
        render.Row(
            children = left_delta_row,
        ),
        render.Row(
            main_align = "center",
            cross_align = "start",
            children = [
                render.Animation(
                    sm_clock_row,
                ),
            ],
        ),
        render.Row(
            main_align = "center",
            cross_align = "start",
            children = [
                render.Text(
                    content = full_ago_dashes,
                    font = FONT_TINY,
                    color = color_ago,
                    offset = SCALE,
                ),
            ],
        ),
    ]

    return one_column_string, left_column_string

def build_graph(history, graph_width, graph_height, expand_graph_height, normal_high, normal_low, urgent_high, urgent_low, color_graph_normal, color_graph_high, color_graph_urgent_high, color_graph_low, color_graph_urgent_low, show_graph_hour_bars, hour_marker_color, oldest_reading_target):
    """Builds graph plot data and hour bar markers."""
    graph_plot = []
    graph_hour_bars = []
    start_time = oldest_reading_target.unix

    bucketed = {}
    for hp in history:
        slot = int((hp[0] - start_time) / 300)
        if 0 <= slot and slot < graph_width:
            bucketed[slot] = hp[1]

    if expand_graph_height:
        for slot in range(graph_width):
            graph_height = max(graph_height, bucketed.get(slot, 0))

    for point in range(graph_width):
        min_time = start_time + point * 300
        max_time = min_time + 299
        this_point = bucketed.get(point, 0)

        if this_point > 0:
            this_point = max(GRAPH_BOTTOM, min(this_point, graph_height))

        graph_point_color = color_graph_normal

        if this_point >= normal_high:
            graph_point_color = color_graph_high
        elif this_point >= urgent_high:
            graph_point_color = color_graph_urgent_high
        elif this_point <= normal_low:
            graph_point_color = color_graph_low
        elif this_point <= urgent_low:
            graph_point_color = color_graph_urgent_low

        if show_graph_hour_bars:
            min_hour = time.from_timestamp(min_time, 0).hour
            max_hour = time.from_timestamp(max_time, 0).hour
            if min_hour != max_hour:
                # Add hour marker at this point
                graph_hour_bars.append(
                    render.Padding(
                        pad = (point, 0, 0, 0),
                        child = render.Box(
                            width = 1,
                            height = 30 * SCALE,
                            color = hour_marker_color,
                        ),
                    ),
                )

        graph_plot.append(
            render.Plot(
                data = [
                    (0, this_point),
                    (1, this_point),
                ],
                width = 1,
                height = 30 * SCALE,
                color = graph_point_color,
                color_inverted = graph_point_color,
                fill = False,
                x_lim = (0, 1),
                y_lim = (GRAPH_BOTTOM, graph_height),
            ),
        )

    return graph_plot, graph_hour_bars, graph_height

def build_two_column_output(left_column_string, graph_plot, graph_hour_bars, graph_width, graph_height, normal_low, normal_high, color_graph_lines, color_id_border):
    """Assembles the two-column layout with left column and graph."""
    return [
        render.Stack(
            children = [
                render.Box(
                    height = 32 * SCALE,
                    width = 64 * SCALE,
                    color = color_id_border,
                    child =
                        render.Box(
                            height = 30 * SCALE,
                            width = 62 * SCALE,
                            color = COLOR_BLACK,
                        ),
                ),
                render.Box(
                    height = 32 * SCALE,
                    width = 64 * SCALE,
                    child =
                        render.Box(
                            render.Row(
                                main_align = "center",
                                cross_align = "start",
                                expanded = True,
                                children = [
                                    render.Column(
                                        children = [
                                            render.Box(
                                                width = SCALE,
                                                height = 32 * SCALE,
                                            ),
                                        ],
                                    ),
                                    render.Column(
                                        cross_align = "center",
                                        main_align = "start",
                                        expanded = True,
                                        children = left_column_string,
                                    ),
                                    render.Column(
                                        cross_align = "start",
                                        main_align = "start",
                                        expanded = False,
                                        children = [
                                            render.Box(
                                                height = SCALE,
                                                width = graph_width,
                                            ),
                                            render.Stack(
                                                children = [
                                                    render.Stack(
                                                        children = graph_hour_bars,
                                                    ),
                                                    render.Plot(
                                                        data = [
                                                            (0, normal_low),
                                                            (1, normal_low),
                                                        ],
                                                        width = graph_width,
                                                        height = 30 * SCALE,
                                                        color = color_graph_lines,
                                                        color_inverted = color_graph_lines,
                                                        fill = False,
                                                        x_lim = (0, 1),
                                                        y_lim = (GRAPH_BOTTOM, graph_height),
                                                    ),
                                                    render.Plot(
                                                        data = [
                                                            (0, normal_high),
                                                            (1, normal_high),
                                                        ],
                                                        width = graph_width,
                                                        height = 30 * SCALE,
                                                        color = color_graph_lines,
                                                        color_inverted = color_graph_lines,
                                                        fill = False,
                                                        x_lim = (0, 1),
                                                        y_lim = (GRAPH_BOTTOM, graph_height),
                                                    ),
                                                    render.Row(
                                                        main_align = "start",
                                                        cross_align = "start",
                                                        expanded = True,
                                                        children = graph_plot,
                                                    ),
                                                ],
                                            ),
                                        ],
                                    ),
                                ],
                            ),
                        ),
                ),
            ],
        ),
    ]

def display_unit_options(display_unit):
    if display_unit == "mgdl":
        graph_height = DEFAULT_GRAPH_HEIGHT
        normal_high = DEFAULT_NORMAL_HIGH
        normal_low = DEFAULT_NORMAL_LOW
        urgent_high = DEFAULT_URGENT_HIGH
        urgent_low = DEFAULT_URGENT_LOW
        unit = "mg/dL"
    else:
        graph_height = mgdl_to_mmol(DEFAULT_GRAPH_HEIGHT)
        normal_high = mgdl_to_mmol(DEFAULT_NORMAL_HIGH)
        normal_low = mgdl_to_mmol(DEFAULT_NORMAL_LOW)
        urgent_high = mgdl_to_mmol(DEFAULT_URGENT_HIGH)
        urgent_low = mgdl_to_mmol(DEFAULT_URGENT_LOW)
        unit = "mmol/L"

    return [
        schema.Text(
            id = display_unit + "_graph_height",
            name = "Graph Height",
            desc = "Height of Graph (in " + unit + ") (Default " + str(graph_height) + ")",
            icon = "rulerVertical",
            default = str(graph_height),
        ),
        schema.Toggle(
            id = "expand_graph_height",
            name = "Expand Graph Height",
            desc = "When enabled, the graph height expands to fit the highest value shown.",
            icon = "chartLine",
            default = DEFAULT_EXPAND_GRAPH_HEIGHT,
        ),
        schema.Color(
            id = "in_range_color",
            name = "In Range Color",
            desc = "Color of readings when BG is in range (Between the High and Low values)",
            icon = "brush",
            default = DEFAULT_IN_RANGE_BG_COLOR,
            palette = PALETTE,
        ),
        schema.Text(
            id = display_unit + "_normal_high",
            name = "High Threshold (in " + unit + ")",
            desc = "High Readings Threshold (default " + str(normal_high) + ")",
            icon = "droplet",
            default = str(normal_high),
        ),
        schema.Color(
            id = "high_color",
            name = "High BG Color",
            desc = "Color of readings when BG is above the High Threshold and Below the Urgent High Threshold",
            icon = "brush",
            default = DEFAULT_HIGH_BG_COLOR,
            palette = PALETTE,
        ),
        schema.Text(
            id = display_unit + "_normal_low",
            name = "Low Threshold (in " + unit + ")",
            desc = "Anything below this is displayed yellow unless it is below the Urgent Low Threshold (default " + str(normal_low) + ")",
            icon = "droplet",
            default = str(normal_low),
        ),
        schema.Color(
            id = "low_color",
            name = "Low BG Color",
            desc = "Color of readings when BG is below the Low Threshold and Above the Urgent Low Threshold",
            icon = "brush",
            default = DEFAULT_LOW_BG_COLOR,
            palette = PALETTE,
        ),
        schema.Text(
            id = display_unit + "_urgent_high",
            name = "Urgent High Threshold (in " + unit + ")",
            desc = "Anything above this is displayed red (Default " + str(urgent_high) + ")",
            icon = "droplet",
            default = str(urgent_high),
        ),
        schema.Color(
            id = "urgent_high_color",
            name = "Urgent High BG Color",
            desc = "Color of readings when BG is Above the Urgent High Threshold",
            icon = "brush",
            default = DEFAULT_URGENT_HIGH_COLOR,
            palette = PALETTE,
        ),
        schema.Text(
            id = display_unit + "_urgent_low",
            name = "Urgent Low Threshold (in " + unit + ")",
            desc = "Anything below this is displayed red (Default " + str(urgent_low) + ")",
            icon = "droplet",
            default = str(urgent_low),
        ),
        schema.Color(
            id = "urgent_low_color",
            name = "Urgent Low BG Color",
            desc = "Color of readings when BG is Below the Urgent Low Threshold",
            icon = "brush",
            default = DEFAULT_URGENT_LOW_COLOR,
            palette = PALETTE,
        ),
        schema.Color(
            id = "time_ago_color",
            name = "Dashes/time ago color",
            desc = "Color of the dashes and time ago message.",
            icon = "brush",
            default = DEFAULT_TIME_AGO_COLOR,
            palette = PALETTE,
        ),
    ]

def get_schema():
    clock_options = [
        schema.Option(
            display = "None",
            value = "None",
        ),
        schema.Option(
            display = "Clock",
            value = "Clock",
        ),
        schema.Option(
            display = "Insulin on Board",
            value = "IOB",
        ),
        schema.Option(
            display = "Carbs on Board",
            value = "COB",
        ),
    ]

    unit_options = [
        schema.Option(
            display = "mg/dL",
            value = "mgdl",
        ),
        schema.Option(
            display = "mmol/L",
            value = "mmol",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "nightscout_url",
                name = "Nightscout URL",
                desc = "Your Nightscout URL (i.e. yournightscoutID.heroku.com)",
                icon = "link",
            ),
            schema.Text(
                id = "nightscout_token",
                name = "Nightscout Token",
                desc = "Token for Nightscout Subject with 'readable' Role (optional)",
                icon = "key",
                secret = True,
            ),
            schema.Color(
                id = "id_border_color",
                name = "ID Border Color",
                desc = "Color of the border. Used for differentiating between multiple T1D's in a household",
                icon = "idBadge",
                default = DEFAULT_ID_BORDER_COLOR,
                palette = PALETTE,
            ),
            schema.Dropdown(
                id = "display_unit",
                name = "Unit of Measure (mg/dL or mmol/L)",
                desc = "Select unit of measure to display readings and delta (mg/dL or mmol/L)",
                icon = "droplet",
                default = unit_options[0].value,
                options = unit_options,
            ),
            schema.Toggle(
                id = "show_graph",
                name = "Show Graph",
                desc = "Show graph along with reading",
                icon = "chartLine",
                default = True,
            ),
            schema.Toggle(
                id = "show_graph_hour_bars",
                name = "Show Graph Hours",
                desc = "Show hour makings on the graph",
                icon = "chartColumn",
                default = DEFAULT_SHOW_GRAPH_HOUR_BARS,
            ),
            schema.Generated(
                id = "graph_options",
                source = "display_unit",
                handler = display_unit_options,
            ),
            schema.Dropdown(
                id = "clock_option",
                name = "Show Clock/IOB/COB",
                desc = "Show Clock, Insulin on Board, or Carbs on Board along with reading",
                icon = "gear",
                default = clock_options[1].value,
                options = clock_options,
            ),
            schema.Color(
                id = "clock_color",
                name = "Clock Color",
                desc = "Color of clock",
                icon = "brush",
                default = DEFAULT_CLOCK_COLOR,
                palette = PALETTE,
            ),
            schema.Color(
                id = "iob_color",
                name = "IOB Color",
                desc = "Color of IOB display",
                icon = "brush",
                default = DEFAULT_CLOCK_COLOR,
                palette = PALETTE,
            ),
            schema.Color(
                id = "cob_color",
                name = "COB Color",
                desc = "Color of COB display",
                icon = "brush",
                default = DEFAULT_CLOCK_COLOR,
                palette = PALETTE,
            ),
            schema.Toggle(
                id = "show_24_hour_time",
                name = "Show 24 Hour Time",
                desc = "Show 24 hour time format",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = "night_mode",
                name = "Night Mode",
                desc = "Dim display between sunset and sunrise",
                icon = "moon",
                default = False,
            ),
            schema.Color(
                id = "night_color",
                name = "Night Mode Color",
                desc = "Color applied when Night Mode is active",
                icon = "brush",
                default = DEFAULT_NIGHT_COLOR,
                palette = PALETTE,
            ),
        ],
    )

def build_url(url, path):
    proto = "http" if url.startswith("http://") else "https"
    host = url.removeprefix(proto + "://")
    host = host.split("/")[0]
    return proto + "://" + host + path

# This method returns a tuple of a nightscout_data and a status_code.
def get_nightscout_data(nightscout_url, nightscout_token, show_graph, display_unit):
    json_url = build_url(nightscout_url, "/api/v2/properties/bgnow,iob,delta,direction,cob")
    encoded_token = hash.sha1(nightscout_token) if nightscout_token else ""
    headers = {"API-Secret": encoded_token} if encoded_token else {}
    cache_key = json_url + ":" + hash.sha1(encoded_token)

    cached = cache.get(cache_key)
    if cached:
        ns_properties = json.decode(cached)
    else:
        # Request latest properties from the Nightscout URL
        resp = http.get(json_url, headers = headers)
        if resp.status_code != 200:
            return None, resp.status_code

        ns_properties = resp.json()

    sgv_current = ""
    sgv_delta = ""
    latest_reading_date = ""
    direction = ""
    iob = "n/a"
    cob = "n/a"
    nightscout_history = []

    if "bgnow" in ns_properties:
        if "last" in ns_properties["bgnow"]:
            sgv_current = str(int(ns_properties["bgnow"]["last"]))
        if "mills" in ns_properties["bgnow"]:
            latest_reading_date = time.from_timestamp(int(ns_properties["bgnow"]["mills"] / 1000))
    if "delta" in ns_properties:
        if "absolute" in ns_properties["delta"]:
            sgv_delta = ns_properties["delta"]["absolute"]
            sgv_delta = int(sgv_delta)
            if display_unit == "mmol":
                sgv_delta = mgdl_to_mmol(int(sgv_delta))
    if "direction" in ns_properties:
        if "value" in ns_properties["direction"]:
            direction = ns_properties["direction"]["value"]
    if "iob" in ns_properties:
        if "display" in ns_properties["iob"]:
            iob = str(ns_properties["iob"]["display"]) + "u"
    if "cob" in ns_properties:
        if "display" in ns_properties["cob"]:
            cob = str(ns_properties["cob"]["display"]) + "g"

    ttl_seconds = MIN_CACHE_TTL
    if latest_reading_date:
        reading_age = time.now() - latest_reading_date
        ttl = max(READING_AGE_THRESHOLD - reading_age, MIN_CACHE_TTL)
        ttl_seconds = int(ttl.seconds)

    if not cached:
        cache.set(cache_key, json.encode(ns_properties), ttl_seconds = ttl_seconds)

    if show_graph:
        nightscout_history, status = get_nightscout_history(nightscout_url, nightscout_token, latest_reading_date, ttl_seconds)
        if status != 200:
            nightscout_history = []

    data = {
        "sgv_current": sgv_current,
        "sgv_delta": sgv_delta,
        "latest_reading_date": latest_reading_date,
        "direction": direction,
        "iob": iob,
        "cob": cob,
        "history": nightscout_history,
    }

    return data, 200

def get_nightscout_history(nightscout_url, nightscout_token, latest_reading_date, ttl_seconds):
    if not latest_reading_date:
        latest_reading_date = time.now()
    oldest_reading = str((latest_reading_date - 4 * time.hour).unix)
    json_url = build_url(nightscout_url, "/api/v2/entries.json?count=200&find[date][$gte]=" + oldest_reading)
    encoded_token = hash.sha1(nightscout_token) if nightscout_token else None
    headers = {"API-Secret": encoded_token} if encoded_token else {}

    # Request latest entries from the Nightscout URL
    resp = http.get(json_url, headers = headers, ttl_seconds = ttl_seconds)
    if resp.status_code != 200:
        return [], resp.status_code

    history = [
        (int(int(x["date"]) / 1000), int(x["sgv"]))
        for x in resp.json()
        if "sgv" in x
    ]

    return history, resp.status_code

def mgdl_to_mmol(mgdl):
    mmol = float(math.round((mgdl / 18) * 10) / 10)
    return mmol

def display_failure(msg):
    return render.Root(
        max_age = 120,
        child = render.Box(
            color = COLOR_RED,
            width = 64 * SCALE,
            height = 32 * SCALE,
            child = render.Box(
                color = "#000",
                width = 62 * SCALE,
                height = 30 * SCALE,
                child = render.WrappedText(
                    width = 60 * SCALE,
                    content = msg,
                    color = COLOR_NIGHT,
                    font = "terminus-12" if IS_2X else "tom-thumb",
                    align = "center",
                ),
            ),
        ),
    )

def get_sample_data(display_unit):
    entries = json.decode(SAMPLE_DATA.readall())
    now = time.now()
    d3min = 3 * time.minute - 10 * time.second
    delta = entries[-1] - entries[-2]
    return {
        "sgv_current": str(entries[-1]),
        "sgv_delta": delta if display_unit == "mgdl" else mgdl_to_mmol(delta),
        "latest_reading_date": now - d3min,
        "direction": "Flat",
        "iob": "0.00u",
        "cob": "0.0g",
        "history": [
            ((now - ((len(entries) - k) * 5 * time.minute - d3min)).unix, v)
            for k, v in enumerate(entries)
        ],
    }
