"""
Applet: Wortuhr
Summary: German word clock
Description: Shows the time as a sentence ("ES IST HALB ACHT") in a 16x5
             letter grid: the words of the current time light up, all other
             letters stay dim. Neighbouring words alternate between two
             colours so they stay readable. Five-minute steps; four dots at the
             bottom count the extra minutes.
Author: Sonic-79
"""

load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TZ = "Europe/Berlin"
FONT = "tom-thumb"  # 3x5 glyphs, 4 px advance
FONT_2X = "6x10"  # 128x64 panels: 6 px glyphs in 8x12 cells

BG = "#000000"
DEFAULT_ON = "#ffffff"
DEFAULT_ON2 = "#ffb02e"  # second colour, keeps neighbouring words apart
OFF = "#2b2b2b"

# 16 x 5 letters. Hour words share letters where they never light up together
# (ZWEI/EINS, SECHS/SIEBEN, ZEHN/NEUN, ELF/FÜNF). K, Q and X are fillers.
GRID = [
    "ESISTVIERTELFÜNF",
    "ZEHNKVORNACHHALB",
    "ZWEINSDREIELFÜNF",
    "SECHSIEBENQACHTX",
    "ZEHNEUNVIERZWÖLF",
]

# word -> (row, first column, length)
WORDS = {
    "ES": (0, 0, 2),
    "IST": (0, 2, 3),
    "VIERTEL": (0, 5, 7),
    "M_FUENF": (0, 12, 4),
    "M_ZEHN": (1, 0, 4),
    "VOR": (1, 5, 3),
    "NACH": (1, 8, 4),
    "HALB": (1, 12, 4),
    "H2": (2, 0, 4),
    "H1": (2, 2, 4),
    "H3": (2, 6, 4),
    "H11": (2, 10, 3),
    "H5": (2, 12, 4),
    "H6": (3, 0, 5),
    "H7": (3, 4, 6),
    "H8": (3, 11, 4),
    "H10": (4, 0, 4),
    "H9": (4, 3, 4),
    "H4": (4, 7, 4),
    "H12": (4, 11, 5),
}

# five-minute step -> (words before the hour, hour offset)
STEPS = [
    ([], 0),  # ES IST ACHT
    (["M_FUENF", "NACH"], 0),  # FÜNF NACH ACHT
    (["M_ZEHN", "NACH"], 0),  # ZEHN NACH ACHT
    (["VIERTEL", "NACH"], 0),  # VIERTEL NACH ACHT
    (["M_ZEHN", "VOR", "HALB"], 1),  # ZEHN VOR HALB NEUN
    (["M_FUENF", "VOR", "HALB"], 1),  # FÜNF VOR HALB NEUN
    (["HALB"], 1),  # HALB NEUN
    (["M_FUENF", "NACH", "HALB"], 1),  # FÜNF NACH HALB NEUN
    (["M_ZEHN", "NACH", "HALB"], 1),  # ZEHN NACH HALB NEUN
    (["VIERTEL", "VOR"], 1),  # VIERTEL VOR NEUN
    (["M_ZEHN", "VOR"], 1),  # ZEHN VOR NEUN
    (["M_FUENF", "VOR"], 1),  # FÜNF VOR NEUN
]

# Words that touch each other in the grid get different colours so that
# "ES IST", "IST VIERTEL" or "NACH HALB" do not run together: these words use
# the second colour, everything else the first. The hour is always second.
SECOND_COLOR = ["IST", "VOR", "NACH"] + ["H%d" % n for n in range(1, 13)]

# tom-thumb has no umlauts, so these two are drawn by hand (3x5, plus an
# empty sixth row so they are as tall as a line of text)
UMLAUTS = {
    "Ü": ["a.a", "...", "a.a", "a.a", "aaa", "..."],
    "Ö": ["a.a", "...", "aaa", "a.a", "aaa", "..."],
}

def glyph(rows, color):
    lines = []
    for row in rows:
        cells = []
        for ch in row.elems():
            if ch == ".":
                cells.append(render.Box(width = 1, height = 1))
            else:
                cells.append(render.Box(width = 1, height = 1, color = color))
        lines.append(render.Row(children = cells))
    return render.Column(children = lines)

def letter(ch, color, scale):
    """One cell of the grid: 4x6 px, or 8x12 px on 2x panels."""
    if scale == 2:
        # 6x10 has umlauts; centre its 6 px glyphs in the 8 px cell
        return render.Box(
            width = 8,
            height = 12,
            child = render.Text(content = ch, color = color, font = FONT_2X),
        )
    if ch in UMLAUTS:
        child = glyph(UMLAUTS[ch], color)
    else:
        child = render.Text(content = ch, color = color, font = FONT)
    return render.Box(
        width = 4,
        height = 6,
        child = render.Row(
            expanded = True,
            main_align = "start",
            children = [child],
        ),
    )

def lit_cells(hour, minute):
    """Dict (row, col) -> colour index (0 or 1) of the letters that light up."""
    step = minute // 5
    words, offset = STEPS[step]
    h = (hour + offset) % 12
    if h == 0:
        h = 12
    active = ["ES", "IST"] + words + ["H%d" % h]

    cells = {}
    for name in active:
        row, col, length = WORDS[name]
        for i in range(length):
            cells[(row, col + i)] = 1 if name in SECOND_COLOR else 0
    return cells

def minute_dots(extra, color, scale):
    """Four dots at the bottom: one per minute past the five-minute step."""
    children = []
    for i in range(4):
        if i > 0:
            children.append(render.Box(width = 3 * scale, height = scale))
        children.append(render.Box(
            width = 2 * scale,
            height = scale,
            color = color if i < extra else OFF,
        ))
    return render.Row(expanded = True, main_align = "center", children = children)

def main(config):
    tz = config.get("timezone") or config.get("$tz") or DEFAULT_TZ
    colors = [config.get("color", DEFAULT_ON), config.get("color2", DEFAULT_ON2)]

    now = time.now().in_location(tz)
    hour = now.hour
    minute = now.minute

    # for testing: set "test_time" to e.g. "07:30" in the config
    test_time = config.get("test_time", "")
    if test_time != "":
        parts = test_time.split(":")
        hour = int(parts[0])
        minute = int(parts[1])

    cells = lit_cells(hour, minute)

    scale = 2 if canvas.is2x() else 1

    rows = []
    for r, line in enumerate(GRID):
        rows.append(render.Row(
            children = [
                letter(ch, colors[cells[(r, c)]] if (r, c) in cells else OFF, scale)
                for c, ch in enumerate(line.codepoints())
            ],
        ))
    rows.append(minute_dots(minute % 5, colors[0], scale))

    # The grid is 64x31 (128x62 on 2x panels); taller canvases such as
    # 64x64 panels get it centred vertically.
    return render.Root(
        child = render.Box(
            color = BG,
            child = render.Column(
                expanded = True,
                main_align = "center",
                children = [render.Padding(
                    pad = (scale, 0, 0, 0),
                    child = render.Column(children = rows),
                )],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "color",
                name = "Leuchtfarbe 1",
                desc = "Farbe für ES, die Minutenwörter und HALB",
                icon = "brush",
                default = DEFAULT_ON,
            ),
            schema.Color(
                id = "color2",
                name = "Leuchtfarbe 2",
                desc = "Farbe für IST, VOR/NACH und die Stunde",
                icon = "brush",
                default = DEFAULT_ON2,
            ),
        ],
    )
