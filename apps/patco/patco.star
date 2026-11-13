"""
Applet: PATCO
Summary: Next PATCO trains
Description: Shows the next scheduled PATCO Speedline trains at your station, toward Philadelphia, toward Lindenwold, or both. PATCO has no real-time tracking, so times come from PATCO's published GTFS schedule, refreshed daily (including holiday and special-event service).
Author: John Abella
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

# Pre-processed timetables, rebuilt daily from PATCO's GTFS feed by
# github.com/jabella/patco-schedule. One small JSON file per station.
DATA_URL = "https://raw.githubusercontent.com/jabella/patco-schedule/main/data/v1/stops/%s.json"
DATA_VERSION = 1
HTTP_TTL = 6 * 3600  # schedules change rarely; the daily job keeps the source fresh
FALLBACK_TTL = 14 * 86400  # last good copy, used if GitHub is unreachable

TZ = "America/New_York"  # PATCO's schedule is in Eastern time no matter where the display is

# GTFS stop_id -> (menu name, short display name)
STATIONS = [
    ("1", "Lindenwold", "Lindenwold"),
    ("2", "Ashland", "Ashland"),
    ("3", "Woodcrest", "Woodcrest"),
    ("4", "Haddonfield", "Haddonfield"),
    ("5", "Westmont", "Westmont"),
    ("6", "Collingswood", "Collingswood"),
    ("7", "Ferry Avenue", "Ferry Ave"),
    ("8", "Broadway (Walter Rand)", "Broadway"),
    ("9", "City Hall (Camden)", "City Hall"),
    ("10", "Franklin Square", "Franklin Sq"),
    ("11", "8th & Market", "8th & Market"),
    ("12", "9-10th & Locust", "9-10th&Locust"),
    ("13", "12-13th & Locust", "12-13th&Locust"),
    ("14", "15-16th & Locust", "15-16th&Locust"),
]
SHORT_NAME = {s[0]: s[2] for s in STATIONS}
DEFAULT_STATION = "4"

DIRS = ["phl", "lnd"]
DIR_LABEL = {"phl": "PHL", "lnd": "LND"}
DIR_NAME = {"phl": "Philadelphia", "lnd": "Lindenwold"}

# ---- colors ----
C_PATCO = "#BC0035"  # PATCO route color from the GTFS feed
C_TEXT = "#FFFFFF"
C_DIM = "#8A8A8A"
C_DIR = {"phl": "#5AC8FA", "lnd": "#FFB000"}
C_SOON = "#2ECC40"  # train leaving within 5 minutes (after walk time)
C_ERR = "#FF4136"
C_LAST = "#FF4136"  # final train before the overnight gap

# A train counts as the night's last one when the next is this far behind it.
# (Weekend owl trains run hourly, so a 2.5 hour gap only happens overnight.)
LAST_GAP_MINUTES = 150

WIDTH, HEIGHT = canvas.size()
SCALE = 2 if canvas.is2x() else 1
FONT_SMALL = "terminus-12" if SCALE == 2 else "tom-thumb"
FONT_BIG = "terminus-16" if SCALE == 2 else "tb-8"
FONT_HUGE = "terminus-32" if SCALE == 2 else "10x20"  # big countdown layout
FONT_HUGE_CLOCK = "terminus-16" if SCALE == 2 else "6x13"  # clock times in that layout
HEADER_H = 8 * SCALE

# ---------------------------------------------------------------- data

def fetch_station(stop_id):
    """Return the decoded timetable for a station, or None."""
    url = DATA_URL % stop_id
    key = "patco_v%d_%s" % (DATA_VERSION, stop_id)
    resp = http.get(url, ttl_seconds = HTTP_TTL)
    if resp.status_code == 200:
        body = resp.body()
        cache.set(key, body, ttl_seconds = FALLBACK_TTL)
    else:
        print("PATCO: %s returned %d, trying cached copy" % (url, resp.status_code))
        body = cache.get(key)
    if not body:
        return None
    data = json.decode(body)
    if type(data) != "dict" or data.get("v") != DATA_VERSION:
        return None
    return data

def day_noon(now, offset_days):
    """Noon on the calendar day `offset_days` from now (noon dodges DST edges)."""
    noon = time.time(year = now.year, month = now.month, day = now.day, hour = 12, location = TZ)
    return time.from_timestamp(noon.unix + 86400 * offset_days).in_location(TZ)

def departures(data, direction, now, earliest, count):
    """Next `count` departures at or after unix time `earliest`, as Time values.

    Each service day's minutes count from that day's midnight and may run past
    1440 for after-midnight trips, so look back one day and ahead two.
    """
    out = []
    for offset in [-1, 0, 1, 2]:
        noon = day_noon(now, offset)
        for svc in data["days"].get(noon.format("20060102"), []):
            for m in data["services"].get(svc, {}).get(direction, []):
                t = time.time(
                    year = noon.year,
                    month = noon.month,
                    day = noon.day,
                    hour = (m % 1440) // 60,
                    minute = m % 60,
                    location = TZ,
                )
                if m >= 1440:
                    t = time.from_timestamp(t.unix + 86400 * (m // 1440)).in_location(TZ)
                if t.unix >= earliest:
                    out.append(t)
    out = sorted(out, key = lambda t: t.unix)
    return out[:count]

def upcoming(data, direction, now, earliest, count):
    """Next `count` departures as structs with .t (Time) and .last (bool)."""
    deps = departures(data, direction, now, earliest, count + 1)
    out = []
    for i, t in enumerate(deps[:count]):
        last = i + 1 < len(deps) and (deps[i + 1].unix - t.unix) // 60 >= LAST_GAP_MINUTES
        out.append(struct(t = t, last = last))

    # Nothing after the last train matters until morning.
    for i, d in enumerate(out):
        if d.last:
            return out[:i + 1]
    return out

def serves(data, direction):
    for svc in data["services"].values():
        if len(svc.get(direction, [])) > 0:
            return True
    return False

def covers_today(data, now):
    today = now.format("20060102")
    return data.get("first_day", "") <= today and today <= data.get("last_day", "")

# ---------------------------------------------------------------- formatting

def mins_until(t, now):
    return (t.unix - now.unix) // 60

def fmt_clock(t):
    return t.format("3:04")

def when_color(d, now, walk):
    if d.last:
        return C_LAST
    return C_SOON if mins_until(d.t, now) - walk <= 5 else C_TEXT

# ---------------------------------------------------------------- widgets

def text(s, font = None, color = C_TEXT):
    return render.Text(s, font = font or FONT_SMALL, color = color)

def header(label, right = None, right_color = C_TEXT):
    """Red station bar across the top. Scrolls if the text doesn't fit."""
    items = [text(label.upper())]
    if right:
        items.append(text(" " + right, color = right_color))
    content = render.Row(children = items)
    return render.Box(
        width = WIDTH,
        height = HEADER_H,
        color = C_PATCO,
        child = render.Padding(
            pad = (SCALE, 0, 0, 0),
            child = render.Marquee(width = WIDTH - SCALE, child = content, align = "start"),
        ),
    )

def both_row(direction, deps, now, countdown, walk, height):
    """One direction as a short list: `PHL  4, 19 min` (or clock times)."""
    label = text(DIR_LABEL[direction], color = C_DIR[direction])
    if len(deps) == 0:
        right = text("no trains", color = C_DIM)
    else:
        # Minutes read best as a list with one unit, as on the PATH and subway
        # apps. Past the hour, or with the countdown off, show the clock time.
        as_minutes = countdown and mins_until(deps[0].t, now) < 60
        if as_minutes:
            deps = [d for d in deps if mins_until(d.t, now) < 60]
        children = []
        for i, d in enumerate(deps):
            if i > 0:
                children.append(text(", " if as_minutes else " ", font = FONT_BIG, color = C_DIM))
            if as_minutes:
                m = mins_until(d.t, now)
                value = "now" if m <= 0 else str(m)
            else:
                value = fmt_clock(d.t)
            color = when_color(d, now, walk) if i == 0 or d.last else C_DIM
            children.append(text(value, font = FONT_BIG if (i == 0 or as_minutes) else FONT_SMALL, color = color))
        if deps[-1].last:
            children.append(text(" LAST", color = C_LAST))
        elif as_minutes:
            children.append(text(" min", color = C_DIM))
        right = render.Row(children = children, cross_align = "center")
    return render.Box(
        width = WIDTH,
        height = height,
        child = render.Padding(
            pad = (SCALE, 0, SCALE, 0),
            child = render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [label, right],
            ),
        ),
    )

def single_row(d, now, countdown, walk, height):
    left = render.Text(fmt_clock(d.t), font = FONT_BIG, color = when_color(d, now, walk))
    m = mins_until(d.t, now)
    tags = []
    if countdown and m < 60:
        tags.append(text("now" if m <= 0 else "%dm" % m, color = C_DIM))
    if d.last:
        tags.append(text((" " if tags else "") + "LAST", color = C_LAST))
    return render.Box(
        width = WIDTH,
        height = height,
        child = render.Padding(
            pad = (SCALE, 0, SCALE, 0),
            child = render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [left, render.Row(children = tags)],
            ),
        ),
    )

def big_column(direction, deps, now, walk, width, show_label):
    """Countdown layout: one large number per direction, readable across a room.

    With a walk time set, the number is minutes until you should leave.
    """
    children = []
    if show_label:
        children.append(text(DIR_LABEL[direction], color = C_DIR[direction]))
    if len(deps) == 0:
        children.append(render.Box(width = width, height = 20 * SCALE, child = text("none", color = C_DIM)))
        children.append(text(""))
    else:
        d = deps[0]
        m = mins_until(d.t, now) - walk
        value = str(max(m, 0))
        font = FONT_HUGE
        caption = "min"
        if m >= 60:
            value = fmt_clock(d.t)
            font = FONT_HUGE_CLOCK
            caption = ""
        elif walk > 0 and m <= 0:
            value = "GO"
            caption = "now"
        elif m <= 0:
            value = "NOW"
            caption = ""
        elif walk > 0:
            caption = "to leave"
        color = C_LAST if d.last else (C_SOON if m <= (1 if walk > 0 else 5) else C_TEXT)
        if d.last:
            caption = "LAST"
        children.append(render.Box(width = width, height = 20 * SCALE, child = render.Text(value, font = font, color = color)))
        children.append(text(caption, color = C_LAST if d.last else C_DIM))
    return render.Column(cross_align = "center", children = children)

def message(title, lines, color = C_DIM):
    return render.Root(
        child = render.Column(
            children = [
                header(title),
                render.Padding(
                    pad = (SCALE, SCALE, SCALE, 0),
                    child = render.WrappedText(lines, font = FONT_SMALL, color = color, width = WIDTH - 2 * SCALE),
                ),
            ],
        ),
    )

# ---------------------------------------------------------------- main

def main(config):
    stop_id = config.str("station", DEFAULT_STATION)
    if stop_id not in SHORT_NAME:
        stop_id = DEFAULT_STATION
    mode = config.str("direction", "both")
    countdown = config.bool("countdown", True)
    walk = int(config.str("walk", "0"))
    layout = config.str("layout", "list")
    name = SHORT_NAME[stop_id]

    data = fetch_station(stop_id)
    if data == None:
        return message(name, "Schedule unavailable", C_ERR)

    now = time.now().in_location(TZ)
    if not covers_today(data, now):
        return message(name, "Schedule expired - waiting for PATCO update", C_ERR)

    # Only count trains you can still make after walking to the platform.
    earliest = now.unix + 60 * walk

    available = [d for d in DIRS if serves(data, d)]
    if mode in available:
        shown = [mode]
    else:
        shown = available  # "both", or a direction this station doesn't have (end of the line)

    body_h = HEIGHT - HEADER_H

    if len(shown) == 0:
        return message(name, "No trains scheduled")

    if layout == "big":
        col_w = WIDTH // len(shown)
        cols = [big_column(d, upcoming(data, d, now, earliest, 1), now, walk, col_w, len(available) > 1) for d in shown]
        return render.Root(child = render.Row(expanded = True, main_align = "space_around", children = cols))

    if len(shown) == 2:
        row_h = body_h // 2
        rows = [both_row(d, upcoming(data, d, now, earliest, 2), now, countdown, walk, row_h) for d in shown]
        return render.Root(child = render.Column(children = [header(name)] + rows))

    direction = shown[0]
    row_h = 8 * SCALE
    n = body_h // row_h
    deps = upcoming(data, direction, now, earliest, n)

    # End-of-line stations only have one direction, so the label adds nothing there.
    top = header(name) if len(available) == 1 else header(name, DIR_LABEL[direction], C_DIR[direction])
    if len(deps) == 0:
        return message(name, "No trains to %s soon" % DIR_NAME[direction])
    rows = [single_row(d, now, countdown, walk, row_h) for d in deps]
    return render.Root(child = render.Column(children = [top] + rows))

# ---------------------------------------------------------------- schema

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Station",
                desc = "The station you board at",
                icon = "trainSubway",
                default = DEFAULT_STATION,
                options = [schema.Option(display = s[1], value = s[0]) for s in STATIONS],
            ),
            schema.Dropdown(
                id = "direction",
                name = "Direction",
                desc = "Which trains to show",
                icon = "arrowsLeftRight",
                default = "both",
                options = [
                    schema.Option(display = "Both directions", value = "both"),
                    schema.Option(display = "To Philadelphia (westbound)", value = "phl"),
                    schema.Option(display = "To Lindenwold (eastbound)", value = "lnd"),
                ],
            ),
            schema.Dropdown(
                id = "layout",
                name = "Layout",
                desc = "A short list of departures, or one big countdown readable across the room",
                icon = "tableList",
                default = "list",
                options = [
                    schema.Option(display = "Departure list", value = "list"),
                    schema.Option(display = "Big countdown", value = "big"),
                ],
            ),
            schema.Dropdown(
                id = "walk",
                name = "Time to reach the platform",
                desc = "Hide trains you can't make it to",
                icon = "personWalking",
                default = "0",
                options = [schema.Option(display = "%d min" % m if m else "None", value = str(m)) for m in [0, 2, 3, 5, 7, 10, 15, 20]],
            ),
            schema.Toggle(
                id = "countdown",
                name = "Show minutes until departure",
                desc = "Show '4m' instead of the clock time for trains within the hour",
                icon = "clock",
                default = True,
            ),
        ],
    )
