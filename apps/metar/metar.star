"""
Applet: METAR
Author: Alexander Valys
Summary: METAR aviation weather
Description: Show METAR (aviation weather) text for one airport or flight
    category (VFR/IFR/etc.) for up to 15 airports. Separate airport identifiers
    by commas to display multiple airports.
"""

load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")

ADDS_URL = "https://aviationweather.gov/api/data/metar?ids=%s&format=json&hours=2"
DEFAULT_AIRPORT = "KJFK, KLGA, KBOS, KDCA"

# encryption, schema
# fail expired, add timeout to Root
# play with fonts

MAX_AGE = 60 * 10

def normalize_airport(airport):
    # Users often enter 3-letter US airport codes (e.g. JFK); prepend
    # the US ICAO prefix "K" so lookups work without it.
    if len(airport) == 3:
        return "K" + airport
    return airport

def decoded_result_for_airport(airport):
    rep = http.get(ADDS_URL % airport, ttl_seconds = 60)
    if rep.status_code == 204:
        return {
            "color": "#000000",
            "text": "Invalid airport code %s" % airport,
            "flight_category": "ERR",
        }
    elif rep.status_code != 200:
        return {
            "color": "#4d2424ff",
            "text": "Received error %s for %s" % (rep.status_code, airport),
            "flight_category": "ERR",
        }

    json_data = rep.json()
    if not json_data or len(json_data) == 0:
        return {
            "color": "#000000",
            "text": "No METAR data available for %s" % airport,
            "flight_category": "ERR",
        }

    result = dict(json_data[0])

    if result["rawOb"] == "":
        return {
            "color": "#000000",
            "text": "Could not parse METAR",
            "flight_category": "ERR",
        }

    response = {
        "color": color_for_state(result["fltCat"]),
        "text": result["rawOb"],
        "flight_category": result["fltCat"],
    }
    return response

def color_for_state(category):
    if category == "VFR":
        return "#00FF00"
    elif category == "IFR":
        return "#FF0000"
    elif category == "MVFR":
        return "#0088FF"
    elif category == "LIFR":
        return "#FF00FF"
    elif category == "ERR" or category == "UNK":
        return "#000000"
    else:
        print("Unknown category %s" % category)
        return "#FFFFFF"

def render_single_airport(config, airport):
    use_small_font = config.get("use_small_font") or False

    result = decoded_result_for_airport(airport)
    text = result["text"]
    color = result["color"]

    if use_small_font:
        text_widget = render.WrappedText(
            text,
            color = "#FFFFFF",
            font = "tom-thumb",
            linespacing = 0,
            width = canvas.width(),
        )

        return render.Root(
            child = render.Column([
                render.Box(height = 2, width = canvas.width(), color = color),
                render.Marquee(
                    text_widget,
                    offset_start = 8,
                    offset_end = 48,
                    scroll_direction = "vertical",
                    height = canvas.height(),
                ),
            ]),
            delay = 200,
            max_age = MAX_AGE,
        )
    else:
        text_widget = render.WrappedText(
            text,
            color = "#FFFFFF",
            font = "tb-8",
            linespacing = 0,
            width = canvas.width() - 2,
        )

        return render.Root(
            child = render.Row([
                render.Marquee(
                    text_widget,
                    offset_start = 8,
                    offset_end = 48,
                    scroll_direction = "vertical",
                    height = canvas.height(),
                ),
                render.Box(height = canvas.height(), width = 2, color = color),
            ]),
            delay = 200,
            max_age = MAX_AGE,
        )

def is_square():
    """True on a 64x64 panel.

    Panels are told apart by SHAPE, never by size: the 128x64 wide panel is
    also 64 tall, but it has the width for the side-by-side layout.
    """
    w, h = canvas.size()
    return h == w

def full_row(airport):
    """One airport across the full panel width: code, blob, flight category."""
    result = decoded_result_for_airport(airport)
    color = result["color"]
    return render.Row(
        [
            # Create a fixed-width box for the airport code so the
            # flight categories line up
            render.Stack([
                render.Box(width = 24, height = 8),
                render.Text(airport.upper() + " "),
            ]),
            render.Circle(color = color, diameter = 6),
            render.Text(" %s" % result["flight_category"], color = color),
        ],
        cross_align = "center",
    )

def render_four_airports(airports):
    row_widgets = [full_row(airport) for airport in airports]

    return render.Root(
        child = render.Marquee(
            render.Column(row_widgets),
            height = canvas.height(),
            offset_start = canvas.height(),
            scroll_direction = "vertical",
        ),
        delay = 100,
        max_age = MAX_AGE,
    )

def render_eight_airports(airports):
    # Eight airports are split into two columns because only four 8px rows fit
    # on a 64x32 panel. A square panel has the rows for all eight at full
    # width, which also leaves room for each one's flight category rather than
    # just its colour blob.
    if is_square():
        return render.Root(
            child = render.Marquee(
                render.Column([full_row(airport) for airport in airports]),
                height = canvas.height(),
                offset_start = canvas.height(),
                scroll_direction = "vertical",
            ),
            delay = 100,
            max_age = MAX_AGE,
        )

    left_widgets = []
    for airport in airports[:4]:
        result = decoded_result_for_airport(airport)
        color = result["color"]
        left_widgets.append(
            render.Row(
                [
                    # Create a fixed-width box for the airport code so the
                    # flight categories line up
                    render.Stack([
                        render.Box(width = 24, height = 8),
                        render.Text(airport.upper() + " "),
                    ]),
                    render.Circle(color = color, diameter = 6),
                ],
                cross_align = "center",
            ),
        )
    right_widgets = []
    for airport in airports[4:]:
        result = decoded_result_for_airport(airport)
        color = result["color"]
        right_widgets.append(
            render.Row(
                [

                    # Create a fixed-width box for the airport code so the
                    # flight categories line up
                    render.Stack([
                        render.Box(width = 24, height = 8),
                        render.Text(airport.upper() + " "),
                    ]),
                    render.Circle(color = color, diameter = 6),
                    render.Text(" %s" % result["flight_category"], color = color),
                ],
                cross_align = "center",
                expanded = True,
                main_align = "center",
            ),
        )

    return render.Root(
        child = render.Marquee(
            render.Row([
                render.Column(left_widgets),
                render.Box(width = 3, height = canvas.height()),
                render.Column(right_widgets),
            ]),
            height = canvas.height(),
            offset_start = canvas.height(),
            scroll_direction = "vertical",
        ),
        delay = 100,
        max_age = MAX_AGE,
    )

def render_fifteen_airports(airports):
    font = "tom-thumb"
    code_height = 6
    code_width = 12
    blob_diam = 4
    middle_spacer = 1

    left_widgets = []
    for airport in airports[:5]:
        result = decoded_result_for_airport(airport)
        color = result["color"]
        left_widgets.append(
            render.Row(
                [
                    # Create a fixed-width box for the airport code so the
                    # flight categories line up
                    render.Stack([
                        render.Box(width = code_width, height = code_height),
                        render.Text(airport.upper(), font = font),
                    ]),
                    render.Circle(color = color, diameter = blob_diam),
                ],
                cross_align = "center",
            ),
        )
    mid_widgets = []
    for airport in airports[5:10]:
        result = decoded_result_for_airport(airport)
        color = result["color"]
        mid_widgets.append(
            render.Row(
                [
                    # Create a fixed-width box for the airport code so the
                    # flight categories line up
                    render.Stack([
                        render.Box(width = code_width, height = code_height),
                        render.Text(airport.upper(), font = font),
                    ]),
                    render.Circle(color = color, diameter = blob_diam),
                ],
                cross_align = "center",
            ),
        )
    right_widgets = []
    for airport in airports[10:15]:
        result = decoded_result_for_airport(airport)
        color = result["color"]
        right_widgets.append(
            render.Row(
                [
                    # Create a fixed-width box for the airport code so the
                    # flight categories line up
                    render.Stack([
                        render.Box(width = code_width, height = code_height),
                        render.Text(airport.upper(), font = font),
                    ]),
                    render.Circle(color = color, diameter = blob_diam),
                ],
                cross_align = "center",
            ),
        )

    return render.Root(
        child = render.Box(render.Marquee(
            render.Row([
                render.Column(left_widgets),
                render.Box(width = middle_spacer, height = canvas.height()),
                render.Column(mid_widgets),
                render.Box(width = middle_spacer, height = canvas.height()),
                render.Column(right_widgets),
            ]),
            height = canvas.height(),
            offset_start = canvas.height(),
            scroll_direction = "vertical",
        )),
        delay = 100,
        max_age = MAX_AGE,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "icao",
                name = "Airport(s)",
                desc = "Comma-separated list of ICAO airport codes. Use just one for METAR text. 3-letter US codes (e.g. JFK) are automatically prefixed with K.",
                icon = "plane",
            ),
            schema.Toggle(
                id = "use_small_font",
                name = "Use Small Font",
                desc = "When displaying a single airport, use compressed text.",
                icon = "compress",
                default = False,
            ),
        ],
    )

def main(config):
    airports = config.get("icao") or DEFAULT_AIRPORT
    airports = airports.upper()
    airports = [normalize_airport(a.strip()) for a in airports.split(",")]
    if len(airports) == 1:
        return render_single_airport(config, airports[0])
    elif len(airports) <= 4:
        return render_four_airports(airports)
    elif len(airports) <= 8:
        return render_eight_airports(airports)
    else:
        return render_fifteen_airports(airports)
