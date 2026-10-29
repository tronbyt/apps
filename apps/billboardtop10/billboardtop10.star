"""
Applet: BillboardTop10
Summary: Display top 10 songs
Description: Displays Billboard songs with schedule-aware caching and update timing history.
Author: Robert Ison
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/billboard_icon.png", BILLBOARD_ICON_ASSET = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

def is_square():
    """True on a 64x64 panel.

    Panels are told apart by SHAPE, never by size: the 128x64 wide panel is
    also 64 tall.
    """
    w, h = canvas.size()
    return h == w

def center_on_square(child, width = None, height = None):
    """Centre `child` on the square (64x64); other panels get it unchanged.

    A scene hand-laid for 64x32 passes its size so the Box that centres it
    has the scene's bounds rather than the panel's.
    """
    if not is_square():
        return child
    if width != None and height != None:
        child = render.Box(width = width, height = height, child = child)
    return render.Box(width = canvas.width(), height = canvas.height(), child = child)

BILLBOARD_ICON = BILLBOARD_ICON_ASSET.readall()

DEFAULT_COLORS = [
    "#FFF",
    "#f41b1c",
    "#ffe400",
    "#00b5f8",
]

LIST_OPTIONS = [
    schema.Option(display = "U.S. Songs", value = "hot-100"),
    schema.Option(display = "Global Songs", value = "billboard-global-200"),
]

HOUR = 3600
DAY = 86400
WEEK = 7 * DAY

# Keep scheduling history separate from HTTP-response caching.
STATE_TTL = 120 * DAY
HTTP_TTL = 300

# Proposed initial check time: Tuesday 17:00 UTC.
# This is noon Eastern Standard Time / 1 PM Eastern Daylight Time.
# UTC avoids dependence on the server's configured timezone.
BASE_CHECK_HOUR_UTC = 17

POLL_INTERVAL = 6 * HOUR
LATE_POLL_INTERVAL = DAY
MAX_HISTORY = 8
MIN_LEARNING_SAMPLES = 3

# Do not keep displaying an indefinitely old live chart.
MAX_CHART_AGE = 30 * DAY

CACHE_PREFIX = "billboardtop10-adaptive-v1"

# Historical sample retained for previews and screenshots.
SAMPLE_SONGS = [
    ("Beat It", "Michael Jackson", 1, 12),
    ("Let's Dance", "David Bowie", 3, 8),
    ("Jeopardy", "Greg Kihn Band", 2, 16),
    ("Overkill", "Men At Work", 6, 6),
    ("She Blinded Me With Science", "Thomas Dolby", 7, 13),
    ("Come On Eileen", "Dexy's Midnight Runners", 4, 17),
    ("Flashdance...What A Feeling", "Irene Cara", 13, 7),
    ("Little Red Corvette", "Prince", 9, 12),
    ("Solitaire", "Laura Branigan", 11, 9),
    ("Der Kommissar", "After The Fire", 5, 14),
]

def clean_text(value):
    if value == None:
        return ""

    return " ".join(str(value).split())

def positive_integer(value):
    text = clean_text(value)

    if not text:
        return None

    for character in text.elems():
        if character not in "0123456789":
            return None

    number = int(text)
    return number if number > 0 else None

def is_leap_year(year):
    return (
        year % 4 == 0 and
        (year % 100 != 0 or year % 400 == 0)
    )

def month_lengths(year):
    return [
        31,
        29 if is_leap_year(year) else 28,
        31,
        30,
        31,
        30,
        31,
        31,
        30,
        31,
        30,
        31,
    ]

def days_since_epoch(year, month, day):
    total = 0

    for current_year in range(1970, year):
        total += 366 if is_leap_year(current_year) else 365

    lengths = month_lengths(year)

    for index in range(month - 1):
        total += lengths[index]

    return total + day - 1

def pad2(number):
    text = str(number)
    return "0" + text if len(text) < 2 else text

def pad4(number):
    text = str(number)
    return "0" * max(0, 4 - len(text)) + text

def date_from_days(days):
    year = 1970

    for current_year in range(1970, 3000):
        length = 366 if is_leap_year(current_year) else 365

        if days < length:
            break

        days -= length
        year += 1

    month = 1

    for length in month_lengths(year):
        if days < length:
            break

        days -= length
        month += 1

    return pad4(year) + "-" + pad2(month) + "-" + pad2(days + 1)

def parse_chart_date(value):
    text = clean_text(value)

    if len(text) != 10:
        return None

    parts = text.split("-")

    if len(parts) != 3:
        return None

    if len(parts[0]) != 4 or len(parts[1]) != 2 or len(parts[2]) != 2:
        return None

    year = positive_integer(parts[0])
    month = positive_integer(parts[1])
    day = positive_integer(parts[2])

    if year == None or month == None or day == None:
        return None

    if year < 1970 or year >= 3000:
        return None

    if month > 12:
        return None

    if day > month_lengths(year)[month - 1]:
        return None

    return days_since_epoch(year, month, day)

def publication_cycle(now):
    # Unix days are UTC calendar days.
    today = now // DAY

    # Sunday = 0; epoch day zero was Thursday = 4.
    weekday = (today + 4) % 7
    tuesday = today - ((weekday - 2) % 7)

    return {
        "base": tuesday * DAY + BASE_CHECK_HOUR_UTC * HOUR,
        "date": date_from_days(tuesday + 4),
    }

def sample_data():
    songs = {}

    for index in range(len(SAMPLE_SONGS)):
        title, artist, last_week, weeks = SAMPLE_SONGS[index]
        rank = index + 1

        songs[str(rank)] = {
            "rank": rank,
            "title": title,
            "artist": artist,
            "last_week": last_week,
            "weeks": str(weeks),
        }

    return {
        "date": "1983-05-14",
        "songs": songs,
    }

def normalize_chart(data):
    if type(data) != "dict":
        return None

    if data.get("error"):
        return None

    info = data.get("info")
    content = data.get("content")

    if type(info) != "dict" or type(content) != "dict":
        return None

    chart_date = clean_text(info.get("date"))

    if parse_chart_date(chart_date) == None:
        return None

    songs = {}

    # Cache a complete Top 10 regardless of the display-count setting.
    for rank in range(1, 11):
        item = content.get(str(rank))

        if type(item) != "dict":
            return None

        title = clean_text(item.get("title"))
        artist = clean_text(item.get("artist"))
        returned_rank = positive_integer(item.get("rank"))

        if not title or not artist or returned_rank != rank:
            return None

        songs[str(rank)] = {
            "rank": rank,
            "title": title,
            "artist": artist,
            "last_week": positive_integer(item.get("last week")),
            "weeks": clean_text(item.get("weeks on chart")),
        }

    return {
        "date": chart_date,
        "songs": songs,
    }

def api_error(status):
    if status == 401:
        return "API key rejected"
    if status == 403:
        return "API access denied"
    if status == 404:
        return "Requested chart unavailable"
    if status == 429:
        return "API rate limit reached"

    return "Billboard API HTTP %s" % status

def fetch_chart(api_key, chart_name, chart_date):
    response = http.get(
        url = "https://billboard-api2.p.rapidapi.com/%s" % chart_name,
        params = {
            "date": chart_date,
            "range": "1-10",
        },
        headers = {
            "X-RapidAPI-Host": "billboard-api2.p.rapidapi.com",
            "X-RapidAPI-Key": api_key,
        },
        ttl_seconds = HTTP_TTL,
    )

    if response.status_code != 200:
        return {
            "chart": None,
            "error": api_error(response.status_code),
            "status": response.status_code,
        }

    chart = normalize_chart(response.json())

    return {
        "chart": chart,
        "error": "" if chart != None else "Invalid or incomplete chart response",
        "status": response.status_code,
    }

def empty_state():
    return {
        "chart": None,
        "history": [],
        "last_check": 0,
        "next_check": 0,
        "probe_date": "",
        "last_old": 0,
        "failures": 0,
        "error": "",
    }

def load_state(key):
    stored = cache.get(key)

    if not stored:
        return empty_state()

    state = json.decode(stored)

    if type(state) != "dict":
        return empty_state()

    return state

def save_state(key, state):
    cache.set(
        key,
        json.encode(state),
        ttl_seconds = STATE_TTL,
    )

def learned_offset(state):
    offsets = []

    for observation in state.get("history", []):
        if type(observation) != "dict":
            continue

        lower = observation.get("lower")
        upper = observation.get("upper")

        if type(lower) != "int" or type(upper) != "int":
            continue

        # Exclude broad gaps, outages, and very late holiday observations.
        if lower < 0 or upper < lower:
            continue

        if upper > DAY or upper - lower > 8 * HOUR:
            continue

        offsets.append((lower + upper) // 2)

    if len(offsets) < MIN_LEARNING_SAMPLES:
        return 0

    ordered = sorted(offsets)
    middle = len(ordered) // 2

    if len(ordered) % 2:
        median = ordered[middle]
    else:
        median = (ordered[middle - 1] + ordered[middle]) // 2

    # Modest buffer after the estimated availability time.
    return min(median + HOUR, DAY)

def schedule_next(state, now):
    cycle = publication_cycle(now)
    planned = cycle["base"] + learned_offset(state)
    chart = state.get("chart")

    if chart != None and chart["date"] >= cycle["date"]:
        return planned + WEEK

    if now < planned:
        return planned

    interval = (
        POLL_INTERVAL if now < cycle["base"] + 2 * DAY else LATE_POLL_INTERVAL
    )

    next_check = now + interval

    # Do not sleep past the next weekly planned check.
    next_week = planned + WEEK

    if next_week > now:
        next_check = min(next_check, next_week)

    return next_check

def usable_chart(state, now):
    chart = state.get("chart")

    if type(chart) != "dict":
        return None

    chart_day = parse_chart_date(chart.get("date"))

    if chart_day == None:
        return None

    if now // DAY - chart_day > MAX_CHART_AGE // DAY:
        return None

    return chart

def record_transition(state, old_chart, new_chart, now, cycle):
    if old_chart == None:
        return

    if new_chart["date"] <= old_chart["date"]:
        return

    if new_chart["date"] != cycle["date"]:
        return

    last_old = state.get("last_old", 0)

    if state.get("probe_date") != cycle["date"] or not last_old:
        return

    observation = {
        "chart_date": new_chart["date"],
        "lower": last_old - cycle["base"],
        "upper": now - cycle["base"],
    }

    history = state.get("history", [])
    history.append(observation)
    state["history"] = history[-MAX_HISTORY:]

def get_chart(api_key, chart_name):
    now = int(time.now().unix)
    key = "%s-%s" % (CACHE_PREFIX, chart_name)
    state = load_state(key)
    current = usable_chart(state, now)

    if now < state.get("next_check", 0):
        return {
            "chart": current,
            "error": state.get("error", ""),
            "delayed": (
                current != None and
                current["date"] < publication_cycle(now)["date"] and
                now >= publication_cycle(now)["base"]
            ),
        }

    cycle = publication_cycle(now)

    if state.get("probe_date") != cycle["date"]:
        state["probe_date"] = cycle["date"]
        state["last_old"] = 0

    # Write a short reservation before fetching to reduce repeated calls
    # after a decoder/transport failure. This is not an atomic lock.
    state["last_check"] = now
    state["next_check"] = now + POLL_INTERVAL
    save_state(key, state)

    result = fetch_chart(api_key, chart_name, cycle["date"])
    candidate = result["chart"]
    probe_error = result["error"]

    # On an empty cache, make at most one extra request for last week.
    # Do not make a second request for authentication or quota failures.
    if candidate == None and current == None:
        if result["status"] in [200, 404]:
            previous_day = parse_chart_date(cycle["date"]) - 7
            fallback = fetch_chart(
                api_key,
                chart_name,
                date_from_days(previous_day),
            )

            if fallback["chart"] != None:
                candidate = fallback["chart"]

    if candidate != None:
        # Reject dates beyond the requested publication cycle.
        if candidate["date"] > cycle["date"]:
            candidate = None
            probe_error = "API returned an unexpected future chart"

    if candidate != None:
        old_chart = state.get("chart")

        # Never replace a newer chart with an older response.
        if old_chart == None or candidate["date"] >= old_chart["date"]:
            record_transition(state, old_chart, candidate, now, cycle)
            state["chart"] = candidate

        latest = state.get("chart")

        if latest != None and latest["date"] < cycle["date"]:
            state["last_old"] = now
            state["error"] = probe_error
        else:
            state["last_old"] = 0
            state["error"] = ""

        state["failures"] = 0
        state["next_check"] = schedule_next(state, now)

    else:
        state["error"] = probe_error
        state["failures"] = state.get("failures", 0) + 1

        # Successful responses containing older data, and unavailable
        # target dates, provide an observation that the update isn't ready.
        if result["status"] in [200, 404] and current != None:
            state["last_old"] = now

        retry = min(POLL_INTERVAL * state["failures"], DAY)

        if result["status"] in [401, 403, 429]:
            retry = DAY

        planned_next = schedule_next(state, now)
        state["next_check"] = max(now + retry, planned_next)

    save_state(key, state)
    chart = usable_chart(state, now)

    return {
        "chart": chart,
        "error": state.get("error", ""),
        "delayed": (
            chart != None and
            chart["date"] < cycle["date"] and
            now >= cycle["base"]
        ),
    }

def movement_indicator(current, previous):
    if previous == None:
        return ""

    if current < previous:
        return " (↑%s)" % (previous - current)

    if current > previous:
        return " (↓%s)" % (current - previous)

    return ""

def song_text(item, include_weeks = False):
    text = "%s by %s #%s%s" % (
        item["title"],
        item["artist"],
        item["rank"],
        movement_indicator(item["rank"], item["last_week"]),
    )

    if include_weeks and item["weeks"]:
        text += " - %s weeks on chart" % item["weeks"]

    return text

def songs_text(songs, start, end):
    parts = []

    for rank in range(start, end + 1):
        parts.append(song_text(songs[str(rank)]))

    return " * ".join(parts)

def list_display(value):
    for option in LIST_OPTIONS:
        if option.value == value:
            return option.display

    return LIST_OPTIONS[0].display

def get_delay(config):
    value = config.str("scroll", "60")

    if value not in ["60", "45", "30"]:
        value = "60"

    delay = int(value)
    return delay // 2 if canvas.is2x() else delay

def display_error(config, message):
    font = "terminus-16" if canvas.is2x() else "5x8"

    return render.Root(
        child = center_on_square(render.Column(
            children = [
                render.Text(
                    "Billboard",
                    font = font,
                    color = DEFAULT_COLORS[1],
                ),
                render.Marquee(
                    width = canvas.width(),
                    child = render.Text(
                        message,
                        font = font,
                        color = DEFAULT_COLORS[0],
                    ),
                ),
            ],
        )),
        show_full_animation = True,
        delay = get_delay(config),
    )

def friendly_chart_date(value):
    if parse_chart_date(value) == None:
        return clean_text(value)

    months = [
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December",
    ]

    parts = value.split("-")
    year = parts[0]
    month = int(parts[1])
    day = int(parts[2])

    return "%s %s, %s" % (
        months[month - 1],
        day,
        year,
    )

def display_chart(config, chart, chart_name, count, sample, result):
    double_size = canvas.is2x()
    font = "terminus-16" if double_size else "5x8"
    character_width = 8 if double_size else 5
    row_height = 16 if double_size else 8
    width = canvas.width()

    row1 = "%s - Top %s - %s" % (
        list_display(chart_name),
        count,
        friendly_chart_date(chart["date"]),
    )

    songs = chart["songs"]
    row2 = song_text(songs["1"], include_weeks = True)

    if count == 10:
        row3 = songs_text(songs, 2, 5)
        row4 = songs_text(songs, 6, 10)
    else:
        row3 = songs_text(songs, 2, 3)
        row4 = songs_text(songs, 4, 5)

    if sample:
        row4 += " (Sample Data)"
    elif result["error"]:
        row4 += " (Cached: %s)" % result["error"]
    elif result["delayed"]:
        row4 += " (Awaiting next chart)"

    # Preserve the icon, but let the Row allocate remaining header width.
    # Original layout reserves 7 pixels for the icon/header spacing.
    header_width = max(1, width - 7)

    header = render.Row(
        children = [
            render.Image(src = BILLBOARD_ICON),
            render.Box(
                width = 1,
                height = row_height,
                color = "#000000",
            ),
            render.Marquee(
                width = header_width,
                height = row_height,
                child = render.Text(
                    row1,
                    font = font,
                    color = config.str("color_1", DEFAULT_COLORS[0]),
                ),
            ),
        ],
    )

    return render.Root(
        child = center_on_square(render.Column(
            children = [
                header,
                render.Marquee(
                    width = width,
                    offset_start = 15,
                    child = render.Text(
                        row2,
                        font = font,
                        color = config.str("color_2", DEFAULT_COLORS[1]),
                    ),
                ),
                render.Marquee(
                    width = width,
                    offset_start = len(row2) * character_width,
                    child = render.Text(
                        row3,
                        font = font,
                        color = config.str("color_3", DEFAULT_COLORS[2]),
                    ),
                ),
                render.Marquee(
                    width = width,
                    offset_start = (len(row2) + len(row3)) * character_width,
                    child = render.Text(
                        row4,
                        font = font,
                        color = config.str("color_4", DEFAULT_COLORS[3]),
                    ),
                ),
            ],
        )),
        show_full_animation = True,
        delay = get_delay(config),
    )

def main(config):
    chart_name = config.str("list", LIST_OPTIONS[0].value)

    if chart_name not in ["hot-100", "billboard-global-200"]:
        chart_name = LIST_OPTIONS[0].value

    count_value = config.str("count", "10")
    count = 5 if count_value == "5" else 10
    api_key = (config.str("api_key", "") or "").strip()

    if not api_key:
        chart = sample_data()
        result = {
            "chart": chart,
            "error": "",
            "delayed": False,
        }

        return display_chart(
            config,
            chart,
            chart_name,
            count,
            True,
            result,
        )

    result = get_chart(api_key, chart_name)
    chart = result["chart"]

    if chart == None:
        if config.bool("hide_if_api_limit_reached", True):
            return []

        return display_error(
            config,
            result["error"] or "No usable Billboard chart available",
        )

    return display_chart(
        config,
        chart,
        chart_name,
        count,
        False,
        result,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "RapidAPI Key",
                desc = "Your RapidAPI key. Leave empty for the historical preview sample.",
                default = "",
                icon = "key",
                secret = True,
            ),
            schema.Dropdown(
                id = "list",
                name = "Billboard List",
                desc = "Each chart maintains its own refresh history.",
                icon = "list",
                default = LIST_OPTIONS[0].value,
                options = LIST_OPTIONS,
            ),
            schema.Dropdown(
                id = "count",
                name = "Number of Songs",
                desc = "Number of songs to display.",
                icon = "plusMinus",
                default = "10",
                options = [
                    schema.Option(display = "5", value = "5"),
                    schema.Option(display = "10", value = "10"),
                ],
            ),
            schema.Toggle(
                id = "hide_if_api_limit_reached",
                name = "Hide on API Error",
                desc = "Hide when no usable cached chart is available. Existing charts remain visible during refresh errors.",
                icon = "eye",
                default = True,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                default = "60",
                options = [
                    schema.Option(display = "Slow", value = "60"),
                    schema.Option(display = "Medium", value = "45"),
                    schema.Option(display = "Fast", value = "30"),
                ],
            ),
            schema.Color(
                id = "color_1",
                name = "Color",
                desc = "Line 1 Color",
                icon = "brush",
                default = DEFAULT_COLORS[0],
            ),
            schema.Color(
                id = "color_2",
                name = "Color",
                desc = "Line 2 Color",
                icon = "brush",
                default = DEFAULT_COLORS[1],
            ),
            schema.Color(
                id = "color_3",
                name = "Color",
                desc = "Line 3 Color",
                icon = "brush",
                default = DEFAULT_COLORS[2],
            ),
            schema.Color(
                id = "color_4",
                name = "Color",
                desc = "Line 4 Color",
                icon = "brush",
                default = DEFAULT_COLORS[3],
            ),
        ],
    )
