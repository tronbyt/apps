"""
LA Street Sweeping — counts down to your next Los Angeles street sweep with a
side-view sweeper truck that closes in as the day approaches.

The user provides only a weekday + week-pattern + time per side of the street.
The actual sweep dates come straight from the City of LA's public Google Calendar
feeds (1st & 3rd weeks, 2nd & 4th weeks, non-posted). Those feeds are already
holiday-adjusted and contain no phantom 5th-week dates, so resolving the next
sweep is a pure feed filter: the earliest feed date on the user's weekday that is
not in the past. No address lookup, no geocoding, no date arithmetic.
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

TZ = "America/Los_Angeles"
FEED_TTL = 43200  # 12h

# City of LA public street-sweeping calendars (iCal feeds).
CAL_13 = "c_7dc9b767bb83b8b5a86d6aef0c6aa411720a0dacff1d0ade94d975cdae87f12f@group.calendar.google.com"
CAL_24 = "c_92bc24213759fa41d19b1dac3901e2e48f802b80f3eb873c6cb12cc7c79e5c3c@group.calendar.google.com"
CAL_NP = "c_8c46500e6adf5de64cf055f9b08525a208fdaa11464aa64f4bb39228959c9ec9@group.calendar.google.com"

# palette
SKY = "#15151b"
ROAD = "#33333a"
CURB = "#8f8f97"
BAR = "#101016"
WHITE = "#ffffff"
GREEN = "#3ad353"
AMBER = "#f0a32a"
RED = "#ff5b5b"
FONT = "tom-thumb"

# car (side view, nose left)
C_BODY = "#e0473d"
C_DARK = "#b5332c"
C_WIN = "#bfe3f0"
TIRE = "#1b1b20"
HUB = "#777781"
HEAD = "#fff2b0"

# sweeper (side view, cab left)
S_BODY = "#eef1f3"
S_TRIM = "#3aa05a"
S_DARK = "#aeb6bc"
S_WIN = "#bfe3f0"
BEACON = "#ffae3b"
BRUSH = "#f4c430"
BRUSH2 = "#c9991c"
SPARK = "#fff6c2"

DAYS = [("Mon", "Monday"), ("Tue", "Tuesday"), ("Wed", "Wednesday"), ("Thu", "Thursday"), ("Fri", "Friday"), ("Sat", "Saturday"), ("Sun", "Sunday")]
PATTERNS = [("24", "2nd & 4th"), ("13", "1st & 3rd"), ("all", "Every week"), ("np", "Non-posted")]

# ---------------------------------------------------------------- data layer

def feed_url(cal_id):
    return "https://calendar.google.com/calendar/ical/" + cal_id.replace("@", "%40") + "/public/basic.ics"

def fetch_dates(cal_id):
    resp = http.get(feed_url(cal_id), ttl_seconds = FEED_TTL)
    if resp.status_code != 200:
        return []
    out = []
    for line in resp.body().split("\n"):
        if line.startswith("DTSTART"):
            tail = line.strip().split(":")[-1]
            if len(tail) >= 8 and tail[:8].isdigit():
                out.append(tail[:8])
    return out

def dates_for_pattern(pattern):
    if pattern == "13":
        return fetch_dates(CAL_13)
    if pattern == "np":
        return fetch_dates(CAL_NP)
    if pattern == "all":
        return fetch_dates(CAL_13) + fetch_dates(CAL_24)
    return fetch_dates(CAL_24)

# ---------------------------------------------------------------- date logic

def resolve_next_sweep(today_str, weekday, feed_dates):
    best = None
    for d in feed_dates:
        if d < today_str:
            continue
        if best != None and d >= best:
            continue
        t = time.parse_time(d, format = "20060102", location = TZ)
        if t.format("Mon") == weekday:
            best = d
    return best

def days_between(a_str, b_str):
    a = time.parse_time(a_str, format = "20060102", location = TZ)
    b = time.parse_time(b_str, format = "20060102", location = TZ)
    return int((b - a).hours / 24 + 0.5)

# ---------------------------------------------------------------- config

def read_side(config, sfx, def_day, def_pat):
    return {
        "weekday": config.get("day_" + sfx, def_day),
        "pattern": config.get("pattern_" + sfx, def_pat),
        "start": config.get("start_" + sfx, "10:00"),
        "end": config.get("end_" + sfx, "12:00"),
    }

def to_min(hhmm):
    parts = hhmm.split(":")
    return int(parts[0]) * 60 + int(parts[1])

def hr(hhmm):
    h = hhmm.split(":")[0].lstrip("0")
    return h if h else "0"

def time_label(side):
    return hr(side["start"]) + "-" + hr(side["end"])

def date_label(side, sweep_str):
    # e.g. "THU 6/11" — the next sweep's weekday + month/day, unambiguously future
    md = time.parse_time(sweep_str, format = "20060102", location = TZ).format("1/2")
    return side["weekday"].upper() + " " + md

# ---------------------------------------------------------------- sprites

def px(x, y, w, h, color):
    return render.Padding(pad = (x, y, 0, 0), child = render.Box(width = w, height = h, color = color))

def car():
    return render.Stack(children = [
        render.Box(width = 26, height = 14),
        px(2, 5, 22, 5, C_BODY),
        px(1, 6, 1, 3, C_BODY),
        px(24, 6, 1, 3, C_BODY),
        px(8, 1, 10, 4, C_BODY),
        px(8, 1, 1, 1, ROAD),
        px(17, 1, 1, 1, ROAD),
        px(9, 2, 4, 3, C_WIN),
        px(14, 2, 3, 3, C_WIN),
        px(3, 9, 20, 2, C_DARK),
        px(4, 9, 6, 1, ROAD),
        px(15, 9, 6, 1, ROAD),
        px(4, 10, 6, 4, TIRE),
        px(15, 10, 6, 4, TIRE),
        px(4, 13, 1, 1, ROAD),
        px(9, 13, 1, 1, ROAD),
        px(15, 13, 1, 1, ROAD),
        px(20, 13, 1, 1, ROAD),
        px(6, 11, 2, 2, HUB),
        px(17, 11, 2, 2, HUB),
        px(1, 6, 1, 1, HEAD),
    ])

def sweeper():
    return render.Stack(children = [
        render.Box(width = 26, height = 15),
        px(7, 2, 17, 9, S_BODY),
        px(7, 6, 17, 2, S_TRIM),
        px(23, 3, 1, 6, S_DARK),
        px(1, 4, 7, 6, S_BODY),
        px(2, 5, 4, 3, S_WIN),
        px(1, 9, 7, 1, S_DARK),
        px(7, 1, 16, 1, S_DARK),
        px(12, 0, 2, 1, BEACON),
        px(3, 10, 6, 4, TIRE),
        px(16, 10, 6, 4, TIRE),
        px(3, 13, 1, 1, ROAD),
        px(8, 13, 1, 1, ROAD),
        px(16, 13, 1, 1, ROAD),
        px(21, 13, 1, 1, ROAD),
        px(5, 11, 2, 2, HUB),
        px(18, 11, 2, 2, HUB),
        px(0, 9, 4, 4, BRUSH),
        px(0, 9, 1, 1, ROAD),
        px(3, 9, 1, 1, ROAD),
        px(1, 10, 1, 1, BRUSH2),
        px(2, 11, 1, 1, BRUSH2),
    ])

# ---------------------------------------------------------------- render

def state_for(days, in_window):
    # -> (sweeper_x, car_present, sparkle, accent, count_label)
    if in_window:
        return (12, False, True, RED, "NOW")
    if days <= 0:
        return (14, False, True, RED, "TODAY")
    if days == 1:
        return (28, True, False, RED, "1d")
    if days == 2:
        return (31, True, False, AMBER, "2d")
    if days == 3:
        return (35, True, False, GREEN, "3d")
    if days == 4:
        return (40, True, False, GREEN, "4d")
    return (44, True, False, GREEN, str(days) + "d")

def topbar(label, count, color):
    return render.Stack(children = [
        render.Box(width = 64, height = 7, color = BAR),
        render.Padding(pad = (2, 1, 0, 0), child = render.Text(content = label, font = FONT, color = WHITE)),
        render.Padding(pad = (44, 1, 0, 0), child = render.Text(content = count, font = FONT, color = color)),
    ])

def scene(sweeper_x, car_present, sparkle, time_lbl):
    ground = 21
    layers = [
        render.Box(width = 64, height = 25, color = SKY),
        px(0, ground - 7, 64, 7, ROAD),
        px(0, ground, 64, 4, CURB),
    ]
    if car_present:
        layers.append(render.Padding(pad = (3, ground - 14, 0, 0), child = car()))
    else:
        layers.append(px(5, ground - 6, 1, 1, SPARK))
        layers.append(px(9, ground - 9, 1, 1, SPARK))
        layers.append(px(14, ground - 5, 1, 1, SPARK))
    layers.append(render.Padding(pad = (sweeper_x, ground - 15, 0, 0), child = sweeper()))
    if sparkle:
        layers.append(px(sweeper_x - 2, ground - 2, 1, 1, SPARK))
        layers.append(px(sweeper_x - 3, ground - 5, 1, 1, SPARK))

    # the no-parking time window, secondary, tucked under the header
    layers.append(render.Padding(pad = (2, 0, 0, 0), child = render.Text(content = time_lbl, font = FONT, color = CURB)))
    return render.Stack(children = layers)

def frame(date_lbl, time_lbl, count, color, sweeper_x, car_present, sparkle):
    return render.Column(children = [
        topbar(date_lbl, count, color),
        scene(sweeper_x, car_present, sparkle, time_lbl),
    ])

def message(text):
    return render.Root(child = render.Box(child = render.WrappedText(content = text, font = FONT, color = WHITE)))

# ---------------------------------------------------------------- main

def main(config):
    dev = config.get("dev_today")
    if dev and len(dev) == 8 and dev.isdigit():
        now = time.parse_time(dev, format = "20060102", location = TZ)
        now_min = 9 * 60
    else:
        now = time.now().in_location(TZ)
        now_min = now.hour * 60 + now.minute
    today_str = now.format("20060102")

    sides = [read_side(config, "a", "Thu", "24")]
    if config.bool("side_b", False):
        sides.append(read_side(config, "b", "Wed", "13"))

    best = None
    for s in sides:
        nxt = resolve_next_sweep(today_str, s["weekday"], dates_for_pattern(s["pattern"]))
        if nxt == None:
            continue
        du = days_between(today_str, nxt)
        if best == None or du < best["days"]:
            best = {"days": du, "side": s, "date": nxt}

    if best == None:
        return message("No upcoming sweep found. Check your settings.")

    side = best["side"]
    in_window = best["days"] == 0 and now_min >= to_min(side["start"]) and now_min <= to_min(side["end"])
    sx, car_present, sparkle, accent, count = state_for(best["days"], in_window)
    return render.Root(child = frame(
        date_label(side, best["date"]),
        time_label(side),
        count,
        accent,
        sx,
        car_present,
        sparkle,
    ))

# ---------------------------------------------------------------- schema

def time_options():
    out = []
    for h in range(5, 21):
        hh = str(h) if h >= 10 else "0" + str(h)
        for m in ["00", "30"]:
            v = hh + ":" + m
            out.append(schema.Option(value = v, display = v))
    return out

def side_fields(sfx, name, def_day, def_pat):
    return [
        schema.Dropdown(
            id = "day_" + sfx,
            name = name + " day",
            desc = "Day this side is swept. Look up your address at streets.lacity.gov/services/street-sweeping",
            icon = "calendarDay",
            default = def_day,
            options = [schema.Option(value = v, display = d) for v, d in DAYS],
        ),
        schema.Dropdown(
            id = "pattern_" + sfx,
            name = name + " weeks",
            desc = "Which weeks of the month (from your sign / the city lookup).",
            icon = "calendarWeek",
            default = def_pat,
            options = [schema.Option(value = v, display = d) for v, d in PATTERNS],
        ),
        schema.Dropdown(
            id = "start_" + sfx,
            name = name + " start time",
            desc = "Start of the no-parking window.",
            icon = "clock",
            default = "10:00",
            options = time_options(),
        ),
        schema.Dropdown(
            id = "end_" + sfx,
            name = name + " end time",
            desc = "End of the no-parking window.",
            icon = "clock",
            default = "12:00",
            options = time_options(),
        ),
    ]

def other_side_fields(side_b):
    if side_b == "true":
        return side_fields("b", "Other side", "Wed", "13")
    return []

def get_schema():
    fields = side_fields("a", "Your side", "Thu", "24")
    fields.append(schema.Toggle(
        id = "side_b",
        name = "Track the other side too",
        desc = "LA sweeps opposite curbs on different days. Find both at streets.lacity.gov/services/street-sweeping.",
        icon = "car",
        default = False,
    ))
    fields.append(schema.Generated(
        id = "other_side",
        source = "side_b",
        handler = other_side_fields,
    ))
    return schema.Schema(version = "1", fields = fields)
