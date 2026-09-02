"""
Applet: Habit Streak
Summary: Streak flame for any habit
Description: A streak counter for any habit, fully offline. Set your streak
start date and the last day you completed the habit; the app derives the
streak, tells you when you're due, and shows a month of history as dots.
Author: nsluke

Pixlet apps can't receive button input, so this is the honest v1 model:
the streak is DERIVED from two dates the user keeps updated in config
("streak started" and "last completed"). Update "last completed" each time
you do the habit; if you break the streak, move "streak started" too.
A server-push integration (mark done from a phone) is future work.

There is deliberately no network here at all - the entire app is date math,
and all of it runs on LOCAL calendar dates in the user's timezone (never raw
24h deltas, which get midnight and DST wrong). Dates are converted to a civil
serial day number (days since 1970-01-01, pure integer math - the Hinnant
days_from_civil algorithm) so "yesterday", "weekday before today" and week
counts are exact across DST transitions.

Cadence rules (a streak is alive while no due day has been fully missed):
  daily    - alive if last completed is today or yesterday
  weekdays - alive if no weekday lies strictly between last-completed and
             today (so a Friday completion survives until Monday ends)
  weekly   - alive if last completed is within the past 7 days

Config parsing is paranoid because a transport-free app can still be killed
by config: time.parse_time on a garbage string aborts the render uncatchably,
so DateTime values are regex-sniffed and parsed by hand, colors are
regex-validated and floored for brightness, the Location blob is sniffed
before json.decode, and zone names are existence-checked with
time.is_valid_timezone before use. A DateTime is a real instant (converted
into the user's timezone before its calendar date is taken) unless it is a
bare YYYY-MM-DD or a fraction-less midnight-UTC stamp, which are the two
date-only shapes; see parse_when().

With both dates unset (the CI/store default) the app renders a demo streak,
labeled "demo mode" in the corner so a real device never lies to its owner.
A date the user DID set but that can't be read never falls through to that
demo - it gets the red "check dates" card instead, so the panel never prints
a fabricated number under someone's own habit name.
"""

load("encoding/json.star", "json")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_ACCENT = "#FFA500"
DEFAULT_TZ = "America/New_York"

WHITE = "#FFFFFF"
GREY = "#9C9C9C"
DIM = "#666666"
AMBER = "#FFB020"
RED = "#FF5348"

# Brightness floor for the user's accent, on its hardest-driven channel.
# 0x66 is DIM's level: a floored accent is never dimmer than the app's own
# dimmest text. See readable().
MIN_LEVEL = 0x66

DOT_BEFORE = "#1E1E1E"  # due day before the streak started (or padding)
DOT_MISS = "#532B2B"  # due day inside the window with no completion
DOT_TODAY_PENDING = "#FFFFFF"

# Flame sprite, 11x11. o = outer (accent), i = inner, c = core, . = clear.
# Three frames of flicker; frame order o1,o2,o1,o3 reads as a soft waver.
FLAME_1 = [
    ".....o.....",
    "....oo.....",
    "....ooo....",
    "...ooooo...",
    "..ooiioo...",
    "..oiiiioo..",
    ".ooiicioo..",
    ".oiiccioo..",
    ".oiicciio..",
    "..oiiiio...",
    "...oooo....",
]

FLAME_2 = [
    "......o....",
    ".....oo....",
    "....ooo....",
    "....oooo...",
    "...oiiooo..",
    "..ooiiioo..",
    "..oiicioo..",
    ".ooiccioo..",
    ".oiicciio..",
    "..oiiiio...",
    "...oooo....",
]

FLAME_3 = [
    "...........",
    "....o......",
    "....oo.....",
    "...oooo....",
    "...oiioo...",
    "..ooiiioo..",
    "..oiicioo..",
    ".ooiccioo..",
    ".oiicciio..",
    "..oiiiio...",
    "...oooo....",
]

CADENCES = ["daily", "weekdays", "weekly"]

def main(config):
    accent = clean_color(config.get("accent", DEFAULT_ACCENT))
    name = config.get("habit", "") or "My Habit"
    cadence = config.get("cadence", "daily")
    if cadence not in CADENCES:
        cadence = "daily"
    show_grid = config.bool("grid", True)
    tz = get_tz(config)
    today = today_serial(config, tz)

    raw_started = (config.get("started", "") or "").strip()
    raw_done = (config.get("completed", "") or "").strip()
    started = parse_when(raw_started, tz)
    done = parse_when(raw_done, tz)

    # "Unset" and "set but unreadable" are different states and must not share
    # a code path: routing an unreadable date into the demo branch would print
    # a fabricated streak under the user's own habit name.
    unreadable = []
    if raw_started != "" and started == None:
        unreadable.append("'streak started'")
    if raw_done != "" and done == None:
        unreadable.append("'last completed'")
    if len(unreadable) > 0:
        return root(error_view("can't read " + " and ".join(unreadable) + " - re-pick in settings"))

    if started == None and done == None:
        # CI/store default: a demo streak, honestly labeled.
        return root(streak_view(name, accent, show_grid, "daily", today - 11, today, today, demo = True))
    if started == None or done == None:
        return root(setup_view(started, done, accent))
    if started > today and done > today:
        # Both dates in the future reads as "starting soon", not an error.
        return root(setup_view(None, None, accent, msg = "streak starts " + str(started - today) + "d from now - come back then"))
    if done > today:
        done = today  # a future completion is at best "today"
    if started > done:
        return root(error_view("'streak started' is after 'last completed' - fix your dates in settings"))
    return root(streak_view(name, accent, show_grid, cadence, started, done, today, demo = False))

def root(child):
    return render.Root(delay = 120, child = child)

# ------------------------------------------------------------- date parsing

def to_int(s):
    """Digits-only parse; -1 on anything else. int() would abort the render."""
    digits = "0123456789"
    if s == "":
        return -1
    n = 0
    for ch in s.elems():
        d = digits.find(ch)
        if d < 0:
            return -1
        n = n * 10 + d
    return n

def days_from_civil(y, m, d):
    """Days since 1970-01-01 from a calendar date. Pure integer math (the
    Hinnant algorithm), so no DST or midnight ambiguity can touch it."""
    y2 = y - (1 if m <= 2 else 0)
    era = y2 // 400
    yoe = y2 - era * 400
    mp = (m + 9) % 12
    doy = (153 * mp + 2) // 5 + d - 1
    doe = yoe * 365 + yoe // 4 - yoe // 100 + doy
    return era * 146097 + doe - 719468

def dow(serial):
    """0 = Monday ... 6 = Sunday (1970-01-01 was a Thursday)."""
    return (serial + 3) % 7

def weekdays_between(a, b):
    """Count of weekdays in [a, b] inclusive; 0 when the range is empty."""
    if b < a:
        return 0
    n = b - a + 1
    count = (n // 7) * 5
    for i in range(n % 7):
        if dow(a + i) < 5:
            count += 1
    return count

def parse_when(val, tz):
    """A DateTime config value as a local calendar serial, or None.

    None (not a negative number) is the unset/unparseable sentinel: civil
    serials are legitimately negative for pre-1970 dates, and 1969-12-31 is
    exactly -1, so sign-testing the serial would misread pre-epoch dates as
    missing. time.parse_time on a garbage string aborts the render
    uncatchably, so the string is regex-sniffed and picked apart by hand.

    Date-only vs. real instant is decided by the FRACTIONAL-SECONDS group,
    never by the clock reading. The companion app encodes DateTime with
    ISO8601DateFormatter([.withInternetDateTime, .withFractionalSeconds]) in
    GMT, so every value a picker sends carries ".SSS"; date-only values
    arrive as a bare YYYY-MM-DD (CLI) or a fraction-less "...T00:00:00Z".
    Reading the clock instead would misfile every round-hour evening pick
    made in a whole-hour negative-offset zone - 8 PM EDT, 7 PM EST/CDT, 6 PM
    CST/MDT, 5 PM MST/PDT and 4 PM PST all encode as exactly
    00:00:00.000Z - as the following UTC day.

    Out-of-range fields (month 13, Feb 30) flow through time.time, which
    normalizes instead of erroring - verified against this pixlet."""
    if val == None or val == "":
        return None
    s = val.strip()
    if len(re.match(r"^\d\d\d\d-\d\d-\d\d$", s)) > 0:
        return days_from_civil(to_int(s[0:4]), to_int(s[5:7]), to_int(s[8:10]))
    if len(re.match(r"^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d", s)) == 0:
        return None
    y = to_int(s[0:4])
    mo = to_int(s[5:7])
    d = to_int(s[8:10])
    hh = to_int(s[11:13])
    mi = to_int(s[14:16])
    ss = to_int(s[17:19])

    # Offset tail: "Z", "+HH:MM", "-HH:MM", or nothing (treated as UTC).
    # Fractional seconds may sit in between - and their presence is what
    # marks the value as a real instant rather than a date-only stamp.
    off = 0
    rest = s[19:]
    has_frac = len(rest) > 1 and rest[0] == "." and to_int(rest[1:2]) >= 0
    for i in range(len(rest)):
        c = rest[i]
        if c == "Z":
            break
        if c == "+" or c == "-":
            o = rest[i:]
            if len(o) >= 6:
                oh = to_int(o[1:3])
                om = to_int(o[4:6])
                if oh >= 0 and om >= 0 and oh <= 23 and om <= 59:
                    off = oh * 60 + om
                    if c == "-":
                        off = -off
            break

    if not has_frac and hh == 0 and mi == 0 and ss == 0 and off == 0:
        return days_from_civil(y, mo, d)

    utc = time.time(year = y, month = mo, day = d, hour = hh, minute = mi - off, second = ss, location = "UTC")
    local = utc.in_location(tz)
    return days_from_civil(local.year, local.month, local.day)

def get_tz(config):
    """Timezone from the Location field, else the device's $tz, else a sane
    default. The blob is sniffed before json.decode, the zone name is shape-
    checked by regex, and then existence-checked with time.is_valid_timezone
    (verified present in this pixlet: Fake/Zone -> False, real zones -> True)
    so a well-formed-but-fake zone can never reach Go's LoadLocation, which
    would abort the render uncatchably."""
    loc = config.get("location", "")
    if loc != None and loc.startswith("{") and loc.endswith("}"):
        blob = json_decode_safe(loc)
        if blob != None:
            tz = blob.get("timezone", "")
            if type(tz) == "string" and len(re.match(r"^[A-Za-z][A-Za-z0-9_+\-/]*$", tz)) > 0 and time.is_valid_timezone(tz):
                return tz
    tz = config.get("$tz", "") or ""
    if len(re.match(r"^[A-Za-z][A-Za-z0-9_+\-/]*$", tz)) > 0 and time.is_valid_timezone(tz):
        return tz
    return DEFAULT_TZ

def json_decode_safe(s):
    # json.decode's optional default (verified in this pixlet) is the one
    # spot Starlark lets us swallow a parse error.
    return json.decode(s, None)

def today_serial(config, tz):
    """Today as a civil serial in the user's timezone."""

    # Test hook: pin "today" (YYYY-MM-DD) so every documented state renders
    # deterministically from the CLI. Deliberately NOT a schema field -
    # pixlet passes unknown keys straight through to config.get, so
    # `pixlet render ... dev_today=YYYY-MM-DD` and `pixlet serve` reach it
    # while the phone app and web config UI can't (a user who filled it in
    # would freeze "today" and see a permanently fake live streak).
    override = config.get("dev_today", "")
    if override != None and len(re.match(r"^\d\d\d\d-\d\d-\d\d$", override.strip())) > 0:
        o = override.strip()
        return days_from_civil(to_int(o[0:4]), to_int(o[5:7]), to_int(o[8:10]))
    now = time.now().in_location(tz)
    return days_from_civil(now.year, now.month, now.day)

# ------------------------------------------------------------- streak logic

def compute(cadence, start, done, today):
    """The one rule: a streak is alive while no due day has been fully
    missed. Length counts due days from start to last-completed inclusive."""
    if cadence == "weekly":
        gap = today - done
        alive = gap <= 7
        due = alive and gap == 7
        count = (done - start) // 7 + 1
        ended = gap - 7
        unit = "week"
    elif cadence == "weekdays":
        missed = weekdays_between(done + 1, today - 1)
        alive = missed == 0
        due = alive and done < today and dow(today) < 5
        count = weekdays_between(start, done)
        if count < 1:
            count = 1  # completed at least once, even if only on a weekend
        ended = today - next_weekday(done)
        unit = "day"
    else:
        gap = today - done
        alive = gap <= 1
        due = alive and gap == 1
        count = done - start + 1
        ended = gap - 1
        unit = "day"
    return {"alive": alive, "due": due, "count": count, "ended": ended, "unit": unit}

def next_weekday(serial):
    for i in range(1, 4):
        if dow(serial + i) < 5:
            return serial + i
    return serial + 1

def count_label(st):
    n = st["count"]
    return str(n) + " " + st["unit"] + ("" if n == 1 else "s")

# -------------------------------------------------------------------- views

def streak_view(name, accent, show_grid, cadence, start, done, today, demo):
    st = compute(cadence, start, done, today)
    body_h = 25 if show_grid else 32

    if st["due"]:
        status = render.Row(
            cross_align = "center",
            children = [
                render.Box(width = 3, height = 3, color = AMBER),
                render.Box(width = 2, height = 1),
                render.Text("due today", font = "tom-thumb", color = AMBER),
            ],
        )
    elif st["alive"]:
        status = render.Text(count_label(st), font = "tom-thumb", color = accent)
    else:
        # One scrolling line carries both the epitaph and the fix; a second
        # marquee under it would just fight for the eye.
        status = render.Marquee(
            width = 40,
            child = render.Text(
                "ended " + str(st["ended"]) + "d ago - update dates to restart",
                font = "tom-thumb",
                color = GREY,
            ),
        )

    if demo:
        line3 = render.Text("demo mode", font = "tom-thumb", color = DIM)
    else:
        line3 = render.Text(cadence, font = "tom-thumb", color = DIM)

    right = render.Box(
        width = 42,
        height = body_h,
        child = render.Column(
            main_align = "center",
            children = [
                render.Marquee(width = 40, child = render.Text(name, font = "tom-thumb", color = WHITE)),
                render.Box(width = 1, height = 2),
                status,
                render.Box(width = 1, height = 2),
                line3,
            ],
        ),
    )

    kids = [render.Row(children = [left_column(st, accent, body_h), right])]
    if show_grid:
        kids.append(grid_strip(cadence, start, done, today, accent))
    return render.Column(children = kids)

def left_column(st, accent, body_h):
    number_color = accent if st["alive"] else GREY
    n = st["count"]
    label = str(n) if n <= 9999 else "9999+"
    font = "6x13" if len(label) <= 3 else ("tb-8" if len(label) <= 4 else "tom-thumb")
    return render.Box(
        width = 22,
        height = body_h,
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                flame(accent, dead = not st["alive"]),
                render.Box(width = 1, height = 1),
                render.Text(label, font = font, color = number_color),
            ],
        ),
    )

def setup_view(started, done, accent, msg = ""):
    if msg == "":
        if started == None and done == None:
            msg = "set 'streak started' and 'last completed' in settings"
        elif started == None:
            msg = "set 'streak started' in settings"
        else:
            msg = "set 'last completed' in settings"
    return card(accent, "Habit Streak", WHITE, msg, GREY)

def error_view(msg):
    # Always the default accent: a config error should look the same on every
    # device, and the accent itself may be part of what's misconfigured.
    return card(DEFAULT_ACCENT, "check dates", RED, msg, GREY)

def card(accent, title, title_color, msg, msg_color):
    return render.Row(
        children = [
            render.Box(
                width = 15,
                height = 32,
                child = flame(accent, dead = False),
            ),
            render.Box(
                width = 49,
                height = 32,
                child = render.Column(
                    main_align = "center",
                    children = [
                        render.Text(title, font = "tom-thumb", color = title_color),
                        render.Box(width = 1, height = 3),
                        render.Marquee(width = 47, child = render.Text(msg, font = "tom-thumb", color = msg_color)),
                    ],
                ),
            ),
        ],
    )

# ------------------------------------------------------------------- sprite

def flame(accent, dead):
    if dead:
        pal = {"o": "#4A4A4A", "i": "#6A6A6A", "c": "#8A8A8A"}
        return sprite(FLAME_1, pal)
    pal = {"o": accent, "i": lighten(accent, 40), "c": lighten(accent, 75)}
    return render.Animation(
        children = [
            sprite(FLAME_1, pal),
            sprite(FLAME_2, pal),
            sprite(FLAME_1, pal),
            sprite(FLAME_3, pal),
        ],
    )

def sprite(rows, pal):
    out = []
    for row in rows:
        boxes = []
        for ch in row.elems():
            color = pal.get(ch, "")
            if color == "":
                boxes.append(render.Box(width = 1, height = 1))
            else:
                boxes.append(render.Box(width = 1, height = 1, color = color))
        out.append(render.Row(children = boxes))
    return render.Column(children = out)

# --------------------------------------------------------------------- grid

def grid_strip(cadence, start, done, today, accent):
    """The last 28 due days as 2px dots, oldest top-left. Filled = inside the
    streak window, dark red = due but missed, near-black = before the streak,
    white = today waiting to be logged (2px dots can't draw a literal
    outline, so 'today outlined' becomes 'today in white')."""
    cells = grid_cells(cadence, start, done, today, accent)
    rows = []
    for r in range(2):
        boxes = []
        for i in range(14):
            boxes.append(render.Box(width = 2, height = 2, color = cells[r * 14 + i]))
            if i < 13:
                boxes.append(render.Box(width = 2, height = 2))
        rows.append(render.Row(children = boxes))
    return render.Box(
        width = 64,
        height = 7,
        child = render.Column(
            main_align = "center",
            children = [rows[0], render.Box(width = 1, height = 1), rows[1]],
        ),
    )

def grid_cells(cadence, start, done, today, accent):
    if cadence == "weekly":
        return week_cells(start, done, today, accent)

    # Walk back from today collecting due days (60 covers 28 weekdays).
    serials = []
    for i in range(60):
        s = today - i
        if cadence == "weekdays" and dow(s) >= 5:
            continue
        serials.append(s)
        if len(serials) == 28:
            break
    serials = serials[::-1]

    cells = []
    for s in serials:
        if s == today and done < today:
            cells.append(DOT_TODAY_PENDING)
        elif s < start:
            cells.append(DOT_BEFORE)
        elif s <= done:
            cells.append(lighten(accent, 45) if s == today else accent)
        else:
            cells.append(DOT_MISS)
    return cells

def week_cells(start, done, today, accent):
    """28 week-buckets ending today; a bucket is filled if any of its 7 days
    falls inside [start, done]."""
    cells = []
    for k in range(27, -1, -1):
        high = today - 7 * k
        low = high - 6
        if k == 0 and done < low:
            cells.append(DOT_TODAY_PENDING)
        elif high < start:
            cells.append(DOT_BEFORE)
        elif low <= done:
            cells.append(lighten(accent, 45) if k == 0 else accent)
        else:
            cells.append(DOT_MISS)
    return cells

# ------------------------------------------------------------------- colors

def clean_color(c):
    """schema.Color always hands back a valid hex, but the CLI can hand back
    anything, and an invalid color string aborts the render inside Box/Text.
    A shape-valid color still has to survive the panel, so it is brightness-
    floored on the way out - see readable()."""
    if c == None:
        return DEFAULT_ACCENT
    s = c.strip()
    if not s.startswith("#"):
        s = "#" + s
    if len(re.match(r"^#[0-9a-fA-F]{6}$", s)) > 0:
        return readable(s)
    return DEFAULT_ACCENT

def readable(color):
    """Lift an accent too dark to see on a black panel up to the minimum
    readable level, keeping its hue and saturation.

    The streak number, the status line and every filled history dot are drawn
    in the raw accent, and #000000 is a legal pick in schema.Color's picker -
    without a floor the whole readout goes black on black. An LED pixel's
    apparent brightness is set by its hardest-driven channel, so the floor is
    on the peak channel, and it is the app's own dimmest text color (DIM) so
    a floored accent is never dimmer than the cadence label beside it. Pure
    black has no hue to preserve, so it lands on DIM itself."""
    c = color.lstrip("#")
    r = hex_byte(c[0:2])
    g = hex_byte(c[2:4])
    b = hex_byte(c[4:6])
    peak = max(r, g, b)
    if peak >= MIN_LEVEL:
        return color
    if peak == 0:
        return DIM
    return "#" + hex2(r * MIN_LEVEL // peak) + hex2(g * MIN_LEVEL // peak) + hex2(b * MIN_LEVEL // peak)

def hex_byte(s):
    digits = "0123456789abcdef"
    s = s.lower()
    if len(s) != 2 or digits.find(s[0]) < 0 or digits.find(s[1]) < 0:
        return 0
    return digits.find(s[0]) * 16 + digits.find(s[1])

def hex2(n):
    digits = "0123456789abcdef"
    if n < 0:
        n = 0
    if n > 255:
        n = 255
    return digits[n // 16] + digits[n % 16]

def lighten(color, pct):
    """Mix a #rrggbb color toward white by pct (0-100)."""
    c = color.lstrip("#")
    r = hex_byte(c[0:2])
    g = hex_byte(c[2:4])
    b = hex_byte(c[4:6])
    r += (255 - r) * pct // 100
    g += (255 - g) * pct // 100
    b += (255 - b) * pct // 100
    return "#" + hex2(r) + hex2(g) + hex2(b)

# ------------------------------------------------------------------- schema

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "habit",
                name = "Habit",
                desc = "What you're keeping the streak for.",
                icon = "fire",
                default = "My Habit",
            ),
            schema.DateTime(
                id = "started",
                name = "Streak started",
                desc = "The day this streak began.",
                icon = "calendar",
            ),
            schema.DateTime(
                id = "completed",
                name = "Last completed",
                desc = "The most recent day you did the habit. Update it each time.",
                icon = "calendarDay",
            ),
            schema.Dropdown(
                id = "cadence",
                name = "Cadence",
                desc = "How often the habit is due.",
                icon = "clock",
                default = "daily",
                options = [
                    schema.Option(display = "Daily", value = "daily"),
                    schema.Option(display = "Weekdays", value = "weekdays"),
                    schema.Option(display = "Weekly", value = "weekly"),
                ],
            ),
            schema.Color(
                id = "accent",
                name = "Flame color",
                desc = "Color of the flame and streak count.",
                icon = "brush",
                default = DEFAULT_ACCENT,
            ),
            schema.Toggle(
                id = "grid",
                name = "Show history dots",
                desc = "A month of due-days as dots along the bottom.",
                icon = "toggleOn",
                default = True,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Used only for its timezone - all streak math runs on your local calendar.",
                icon = "locationDot",
            ),
        ],
    )
