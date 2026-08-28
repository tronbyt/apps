"""
Applet: GTA 6 Countdown
Summary: Counts down to GTA 6
Description: Days, hours, minutes and seconds until Grand Theft Auto VI on 19 November 2026. Runs to midnight in your own timezone, and takes a target date of your own if the release moves again.
Author: nsluke

A LukeByt original.

The lockup is a hand-drawn numeral that runs cobalt into hot pink into amber
down its own height, rimmed in gold at the top and deep purple at the point.
Every glyph in the file is an original bitmap drawn as run-length boxes: no
font files, no game assets, nothing lifted.

Rockstar has announced the date but never an hour, which is why the clock runs
to local midnight, and the date is a config field because this release has
already moved twice.
"""

load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

# --- Animation budget -------------------------------------------------------
# One frame per second for a minute, which matches how often the server is
# asked to come back. Encoding stops at whatever slot length the device has, so
# only the head of this is ever written to the file; the rest is there so a
# board with a long dwell does not run out of clock and start the minute again.
DELAY_MS = 1000
FRAME_COUNT = 60
MAX_AGE = 60

# --- The date ---------------------------------------------------------------
# The date Rockstar has announced: 19 November 2026, checked against their own
# site on 2026-08-28. No launch time has ever been announced. Both console
# storefronts encode a rolling regional midnight, so local midnight is the
# honest target.
TARGET_YEAR = 2026
TARGET_MONTH = 11
TARGET_DAY = 19

WIDTH = 64
HEIGHT = 32

# --- Palette ----------------------------------------------------------------
BG = "#07070d"
INK = "#ffffff"
LABEL = "#ff9c3c"

# The mark's face runs top to bottom, not left to right: cobalt into hot pink
# at the halfway line, then pink into amber. Its edge is a bright inner rim
# that is gold at the top and deep purple at the point, which is what makes
# the thing glow on a black panel without any outline at all.
FACE_TOP = (43, 96, 218)
FACE_MID = (255, 76, 185)
FACE_BOT = (230, 149, 62)
RIM_TOP = (255, 188, 36)
RIM_MID = (255, 73, 185)
RIM_BOT = (109, 1, 109)

HEXD = "0123456789abcdef"

# 3x5 label font, hand-drawn. Advance is glyph width + 1.
SMALL = {
    "A": [".#.", "#.#", "###", "#.#", "#.#"],
    "B": ["##.", "#.#", "##.", "#.#", "##."],
    "C": ["###", "#..", "#..", "#..", "###"],
    "D": ["##.", "#.#", "#.#", "#.#", "##."],
    "E": ["###", "#..", "##.", "#..", "###"],
    "F": ["###", "#..", "##.", "#..", "#.."],
    "G": ["###", "#..", "#.#", "#.#", "###"],
    "H": ["#.#", "#.#", "###", "#.#", "#.#"],
    "I": ["###", ".#.", ".#.", ".#.", "###"],
    "J": ["..#", "..#", "..#", "#.#", "###"],
    "K": ["#.#", "#.#", "##.", "#.#", "#.#"],
    "L": ["#..", "#..", "#..", "#..", "###"],
    "M": ["#...#", "##.##", "#.#.#", "#...#", "#...#"],
    "N": ["#..#", "##.#", "#.##", "#..#", "#..#"],
    "O": ["###", "#.#", "#.#", "#.#", "###"],
    "P": ["##.", "#.#", "##.", "#..", "#.."],
    "Q": ["###", "#.#", "#.#", "###", "..#"],
    "R": ["##.", "#.#", "##.", "#.#", "#.#"],
    "S": ["###", "#..", "###", "..#", "###"],
    "T": ["###", ".#.", ".#.", ".#.", ".#."],
    "U": ["#.#", "#.#", "#.#", "#.#", "###"],
    "V": ["#.#", "#.#", "#.#", "#.#", ".#."],
    "W": ["#...#", "#...#", "#.#.#", "##.##", "#...#"],
    "X": ["#.#", "#.#", ".#.", "#.#", "#.#"],
    "Y": ["#.#", "#.#", ".#.", ".#.", ".#."],
    "Z": ["###", "..#", ".#.", "#..", "###"],
    "0": ["###", "#.#", "#.#", "#.#", "###"],
    "1": [".#.", "##.", ".#.", ".#.", "###"],
    "2": ["###", "..#", "###", "#..", "###"],
    "3": ["###", "..#", "###", "..#", "###"],
    "4": ["#.#", "#.#", "###", "..#", "..#"],
    "5": ["###", "#..", "###", "..#", "###"],
    "6": ["###", "#..", "###", "#.#", "###"],
    "7": ["###", "..#", ".#.", ".#.", ".#."],
    "8": ["###", "#.#", "###", "#.#", "###"],
    "9": ["###", "#.#", "###", "..#", "###"],
    ":": [".", "#", ".", "#", "."],
    ".": [".", ".", ".", ".", "#"],
    "!": ["#", "#", "#", ".", "#"],
    "-": ["...", "...", "###", "...", "..."],
    "'": ["#", "#", ".", ".", "."],
    "/": ["..#", "..#", ".#.", "#..", "#.."],
    "+": ["...", ".#.", "###", ".#.", "..."],
    " ": ["..", "..", "..", "..", ".."],
}

# Hero numerals at cap 13: 3px stems, a 3px counter and a 3px bar. Most are a
# solid block with slots cut out of one edge; 0, 6, 8 and 9 keep an enclosed
# counter, the 4 is the only wide one, and the 7 owns the only diagonal.
#
# Two deliberate departures from the heavy display faces this is reaching for.
# Theirs run a counter barely a pixel wide, which at 1:1 closes under an LED
# panel's bloom until 0 and 8 are the same white slab; three pixels costs a
# little weight and buys twenty pixels of difference between them. And theirs
# draw the 1 as a bare stem, which is fine on a poster and unreadable on a
# counter that spends its last fortnight showing 19, 11 and 1, so this one
# takes a flag.
BIG = {
    "0": [".#######.", "#########", "#########", "###...###", "###...###", "###...###", "###...###", "###...###", "###...###", "###...###", "#########", "#########", ".#######."],
    "1": ["...###...", "..####...", ".#####...", "...###...", "...###...", "...###...", "...###...", "...###...", "...###...", "...###...", "...###...", "...###...", "...###..."],
    "2": [".#######.", "#########", "#########", "......###", "......###", "#########", "#########", "#########", "###......", "###......", "#########", "#########", "#########"],
    "3": [".#######.", "#########", "#########", "......###", "......###", "#########", "#########", "#########", "......###", "......###", "#########", "#########", ".#######."],
    "4": ["###...###.", "###...###.", "###...###.", "###...###.", "###...###.", "###...###.", "##########", "##########", "##########", "......###.", "......###.", "......###.", "......###."],
    "5": ["#########", "#########", "#########", "###......", "###......", "#########", "#########", "#########", "......###", "......###", "#########", "#########", ".#######."],
    "6": [".#######.", "#########", "#########", "###......", "###......", "#########", "#########", "#########", "###...###", "###...###", "#########", "#########", ".#######."],
    "7": ["#########", "#########", "#########", "......###", "......###", ".....###.", ".....###.", "....###..", "....###..", "...###...", "...###...", "..###....", "..###...."],
    "8": [".#######.", "#########", "#########", "###...###", "###...###", "#########", "#########", "#########", "###...###", "###...###", "#########", "#########", ".#######."],
    "9": [".#######.", "#########", "#########", "###...###", "###...###", "#########", "#########", "#########", "......###", "......###", "#########", "#########", ".#######."],
    ":": ["....", "....", "....", "####", "####", "....", "....", "....", "####", "####", "....", "....", "...."],
}

# A Roman numeral VI at sixteen pixels: a tapered wedge and a bar. The counter
# runs about half the height — deep enough that the wedge reads as a V rather
# than a shoulder tapering to a point, shallow enough that the arms keep some
# mass for the gradient to run down. There is no room for letterform detail at
# this size and no attempt at any — the sunset ramp running down it is what
# does the recognising. The unlit column between the two glyphs is deliberate;
# without it they fuse into one shape.
MARK_V = ["######....######", "######....######", ".#####....#####.", "..####....####..", "..####....####..", "..#####..#####..", "...####..####...", "...####..####...", "....#######.....", "....########....", ".....######.....", ".....######.....", "......####......", "......####......", ".......##.......", ".......##......."]
MARK_I = ["#####"] * 16

# --- Pixel plumbing ---------------------------------------------------------

def hx(v):
    v = int(v)
    if v < 0:
        v = 0
    if v > 255:
        v = 255
    return HEXD[v // 16] + HEXD[v % 16]

def rgb(r, g, b):
    return "#" + hx(r) + hx(g) + hx(b)

def ramp(low, mid, high, steps):
    """A three-stop ramp turned into one colour per row, worked out once so
    the frame loop never has to build a colour string."""
    out = []
    span = float(steps - 1)
    if span <= 0:
        span = 1.0
    for i in range(steps):
        f = float(i) / span
        if f < 0.5:
            a = low
            b = mid
            t = f * 2.0
        else:
            a = mid
            b = high
            t = (f - 0.5) * 2.0
        out.append(rgb(
            a[0] + (b[0] - a[0]) * t,
            a[1] + (b[1] - a[1]) * t,
            a[2] + (b[2] - a[2]) * t,
        ))
    return out

def is_ink(glyph, x, y):
    if y < 0 or y >= len(glyph):
        return False
    row = glyph[y]
    if x < 0 or x >= len(row):
        return False
    return row[x] != "."

def blit_mark(fb, glyph, x, y, face, rim):
    """Face colour by row, except on the outermost pixel of the shape, which
    takes the rim colour instead. That one substitution is the whole edge
    treatment on the real mark."""
    for gy in range(len(glyph)):
        row = glyph[gy]
        for gx in range(len(row)):
            if row[gx] == ".":
                continue
            edge = not is_ink(glyph, gx - 1, gy) or not is_ink(glyph, gx + 1, gy)
            edge = edge or not is_ink(glyph, gx, gy - 1) or not is_ink(glyph, gx, gy + 1)
            if edge:
                put(fb, x + gx, y + gy, rim[gy])
            else:
                put(fb, x + gx, y + gy, face[gy])

def new_frame():
    return [[BG] * WIDTH for _ in range(HEIGHT)]

def put(fb, x, y, color):
    if x >= 0 and x < WIDTH and y >= 0 and y < HEIGHT:
        fb[y][x] = color

def blit(fb, glyph, x, y, color, scale):
    """Draw one glyph. A scale above 1 fattens it into a chunkier cut of the
    same letterform rather than needing a second set of bitmaps."""
    for gy in range(len(glyph)):
        row = glyph[gy]
        for gx in range(len(row)):
            if row[gx] != ".":
                if scale == 1:
                    put(fb, x + gx, y + gy, color)
                else:
                    for sy in range(scale):
                        for sx in range(scale):
                            put(fb, x + gx * scale + sx, y + gy * scale + sy, color)

def text_width(font, s, scale):
    total = 0
    for ch in s.elems():
        glyph = font.get(ch)
        if glyph == None:
            total += 2 * scale + scale
        else:
            total += len(glyph[0]) * scale + scale
    if total > 0:
        total -= scale
    return total

def draw_text(fb, font, s, x, y, color, scale):
    for ch in s.elems():
        glyph = font.get(ch)
        if glyph == None:
            x += 2 * scale + scale
        else:
            blit(fb, glyph, x, y, color, scale)
            x += len(glyph[0]) * scale + scale
    return x

def runs(row):
    out = []
    start = 0
    cur = row[0]
    for x in range(1, len(row)):
        if row[x] != cur:
            out.append((x - start, cur))
            start = x
            cur = row[x]
    out.append((len(row) - start, cur))
    return out

def emit(fb, scale):
    """One Box per run of like-coloured pixels. A full repaint of the panel
    costs a couple of hundred widgets, which is nothing across 120 frames."""
    rows = []
    for y in range(HEIGHT):
        cells = []
        for run in runs(fb[y]):
            cells.append(render.Box(width = run[0] * scale, height = scale, color = run[1]))
        rows.append(render.Row(children = cells))
    return render.Column(children = rows)

# --- The lockup -------------------------------------------------------------

WORDMARK = ["GRAND", "THEFT", "AUTO"]
MARK_H = 16
MARK_W = 16 + 1 + 5
WORD_W = 20
LOCKUP_X = (WIDTH - MARK_W - 3 - WORD_W) // 2
WORD_X = LOCKUP_X + MARK_W + 3

def draw_lockup(fb):
    """Numeral on the left, the three words stacked tight against it."""
    face = ramp(FACE_TOP, FACE_MID, FACE_BOT, MARK_H)
    rim = ramp(RIM_TOP, RIM_MID, RIM_BOT, MARK_H)
    blit_mark(fb, MARK_V, LOCKUP_X, 0, face, rim)
    blit_mark(fb, MARK_I, LOCKUP_X + 17, 0, face, rim)
    for i in range(len(WORDMARK)):
        word_w = text_width(SMALL, WORDMARK[i], 1)
        draw_text(fb, SMALL, WORDMARK[i], WORD_X + (WORD_W - word_w) // 2, i * 6, INK, 1)

# --- Countdown arithmetic ---------------------------------------------------

def resolve_target(config, tz):
    """The configured instant if there is one, otherwise midnight local on
    release day. Starlark cannot catch a parse error, so nothing unvalidated
    ever reaches time.parse_time — a mistyped date falls back rather than
    taking the whole app down."""
    parsed = parse_target(config.str("target", "").strip(), tz)
    if parsed != None:
        return parsed
    return time.time(
        year = TARGET_YEAR,
        month = TARGET_MONTH,
        day = TARGET_DAY,
        hour = 0,
        minute = 0,
        second = 0,
        location = tz,
    )

def digits(text, low, high):
    """An integer in range, or None. Every field of the config date goes
    through here before it is allowed near the time module. The year is capped
    well short of the point where a duration in nanoseconds overflows its
    int64 and the countdown starts reporting a confident wrong number."""
    if len(text) == 0 or len(text) > 6 or not text.isdigit():
        return None
    value = int(text)
    if value < low or value > high:
        return None
    return value

def split_zone(raw):
    """Peel an RFC 3339 zone off the end. Returns the rest of the string and
    the zone's offset in minutes, or None for a floating time."""
    if raw.endswith("Z") or raw.endswith("z"):
        return (raw[:-1], 0)
    if len(raw) > 6:
        tail = raw[len(raw) - 6:]
        sign = tail[0:1]
        if (sign == "+" or sign == "-") and tail[3:4] == ":":
            hours = digits(tail[1:3], 0, 23)
            minutes = digits(tail[4:6], 0, 59)
            if hours != None and minutes != None:
                offset = hours * 60 + minutes
                if sign == "-":
                    offset = -offset
                return (raw[:len(raw) - 6], offset)
    return (raw, None)

def parse_target(raw, tz):
    if raw == "":
        return None
    body = split_zone(raw)
    stamp = body[0]
    offset = body[1]

    stamp = stamp.replace("T", " ").replace("t", " ")
    parts = stamp.split(" ")
    date_bits = parts[0].split("-")
    if len(date_bits) != 3:
        return None
    year = digits(date_bits[0], 1970, 2200)
    month = digits(date_bits[1], 1, 12)
    day = digits(date_bits[2], 1, 31)
    if year == None or month == None or day == None:
        return None

    hour = 0
    minute = 0
    second = 0
    if len(parts) > 1 and parts[1] != "":
        clock_bits = parts[1].split(".")[0].split(":")
        if len(clock_bits) < 2 or len(clock_bits) > 3:
            return None
        hour = digits(clock_bits[0], 0, 23)
        minute = digits(clock_bits[1], 0, 59)
        second = 0
        if len(clock_bits) == 3:
            second = digits(clock_bits[2], 0, 60)
        if hour == None or minute == None or second == None:
            return None
        if second == 60:
            second = 59

    # A floating time means whatever the panel calls midnight; a stamp that
    # carries its own zone is pinned to that instant wherever the panel is.
    if offset == None:
        return time.time(year = year, month = month, day = day, hour = hour, minute = minute, second = second, location = tz)
    moment = time.time(year = year, month = month, day = day, hour = hour, minute = minute, second = second, location = "UTC")
    if offset == 0:
        return moment
    return moment - time.parse_duration(str(offset) + "m")

def split_remaining(seconds):
    days = seconds // 86400
    rest = seconds % 86400
    return (days, rest // 3600, (rest % 3600) // 60, rest % 60)

def two(n):
    if n < 10:
        return "0" + str(n)
    return str(n)

# --- Frames -----------------------------------------------------------------

BLOCK_Y = 19
GAP = 3

def unit_label(value, singular, plural):
    if value == 1:
        return singular
    return plural

def countdown_parts(days, hours, minutes, seconds):
    """The largest unit still standing becomes the hero, and whatever is left
    under it becomes the running line. On the last day that turns the display
    into an hours clock, then a minutes one, then a bare seconds count."""
    if days > 0:
        return (str(days), unit_label(days, "DAY", "DAYS"), two(hours) + ":" + two(minutes) + ":" + two(seconds))
    if hours > 0:
        return (str(hours), unit_label(hours, "HOUR", "HOURS"), two(minutes) + ":" + two(seconds))
    if minutes > 0:
        return (str(minutes), unit_label(minutes, "MIN", "MINS"), two(seconds))
    return (str(seconds), unit_label(seconds, "SECOND", "SECONDS"), "")

def draw_countdown(fb, days, hours, minutes, seconds):
    parts = countdown_parts(days, hours, minutes, seconds)
    hero = parts[0]
    label = parts[1]
    clock = parts[2]
    hero_w = text_width(BIG, hero, 1)
    label_w = text_width(SMALL, label, 1)
    clock_w = text_width(SMALL, clock, 1)
    side_w = label_w
    if clock_w > side_w:
        side_w = clock_w
    total = hero_w + GAP + side_w

    # A target far enough out to need five digits would run off the panel, so
    # the running line is the first thing to go.
    if total > WIDTH and clock != "":
        clock = ""
        side_w = label_w
        total = hero_w + GAP + side_w

    # A target centuries out leaves no room for the unit beside the number,
    # so the number takes the whole block on its own.
    if total > WIDTH:
        x = (WIDTH - hero_w) // 2
        if x < 0:
            x = 0
        draw_text(fb, BIG, hero, x, BLOCK_Y, INK, 1)
        return

    x = (WIDTH - total) // 2
    if x < 0:
        x = 0
    draw_text(fb, BIG, hero, x, BLOCK_Y, INK, 1)
    side_x = x + hero_w + GAP
    if clock == "":
        draw_text(fb, SMALL, label, side_x, BLOCK_Y + 4, LABEL, 1)
        return
    draw_text(fb, SMALL, label, side_x + (side_w - label_w) // 2, BLOCK_Y + 1, LABEL, 1)
    draw_text(fb, SMALL, clock, side_x + (side_w - clock_w) // 2, BLOCK_Y + 8, INK, 1)

def draw_launched(fb, elapsed):
    """The day it lands, the block is a title card. After that the counter
    turns around and starts counting up, so the app is still worth a slot in
    the rotation a year later."""
    if elapsed < 86400:
        banner = "OUT NOW"
        width = text_width(SMALL, banner, 2)
        draw_text(fb, SMALL, banner, (WIDTH - width) // 2, BLOCK_Y + 1, INK, 2)
        return
    days = elapsed // 86400
    hero = str(days)
    label = unit_label(days, "DAY", "DAYS")
    hero_w = text_width(BIG, hero, 1)
    label_w = text_width(SMALL, label, 1)
    since_w = text_width(SMALL, "SINCE", 1)
    side_w = label_w
    if since_w > side_w:
        side_w = since_w
    total = hero_w + GAP + side_w
    x = (WIDTH - total) // 2
    if x < 0:
        x = 0
    draw_text(fb, BIG, hero, x, BLOCK_Y, INK, 1)
    side_x = x + hero_w + GAP
    draw_text(fb, SMALL, label, side_x + (side_w - label_w) // 2, BLOCK_Y + 1, LABEL, 1)
    draw_text(fb, SMALL, "SINCE", side_x + (side_w - since_w) // 2, BLOCK_Y + 8, INK, 1)

def build_frame(base, remaining, scale):
    fb = [row[:] for row in base]
    if remaining > 0:
        parts = split_remaining(remaining)
        draw_countdown(fb, parts[0], parts[1], parts[2], parts[3])
    else:
        draw_launched(fb, -remaining)
    return emit(fb, scale)

def main(config):
    scale = 2 if canvas.is2x() else 1
    tz = time.tz()
    if not time.is_valid_timezone(tz):
        tz = "UTC"
    now = time.now().in_location(tz)
    target = resolve_target(config, tz)

    # Round up, or the banner lands while a fraction of a second is still on
    # the clock.
    left = (target - now).seconds
    remaining = int(left)
    if left > remaining:
        remaining += 1

    base = new_frame()
    draw_lockup(base)

    # The phone widget is a still, so spend nothing on frames it will not play.
    if config.bool("$widget", False):
        return render.Root(child = build_frame(base, remaining, scale))

    # Once it has launched nothing moves any more, so one frame is the whole
    # animation and the encoder is spared fifty-nine copies of it.
    if remaining <= 0:
        return render.Root(child = build_frame(base, remaining, scale))

    frames = []
    for i in range(FRAME_COUNT):
        frames.append(build_frame(base, remaining - i, scale))

    return render.Root(
        delay = DELAY_MS,
        max_age = MAX_AGE,
        child = render.Animation(children = frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.DateTime(
                id = "target",
                name = "Release date",
                desc = "Override the target. Leave empty for midnight on 19 November 2026 in your timezone.",
                icon = "calendar",
            ),
        ],
    )
