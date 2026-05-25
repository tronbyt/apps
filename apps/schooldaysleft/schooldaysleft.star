"""
Applet: School Days Left
Summary: Count school days left
Description: Count actual school days left, excluding weekends and configured days off.
Author: Rourke McNamara
"""

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TIMEZONE = "America/Los_Angeles"
DEFAULT_ACCENT = "#7AB0FF"

def parse_date(value):
    if not value:
        return None
    raw = str(value).strip()
    if not raw:
        return None

    # Try parsing using time.parse_time
    # Note: format "2006-01-02" is standard in Starlark time module
    t = time.parse_time(raw, format = "2006-01-02")
    if t == None:
        # Try without time if only date provided
        t = time.parse_time(raw.split("T")[0], format = "2006-01-02")

    return t

def parse_days_off(days_off):
    dates = {}
    if not days_off:
        return dates

    normalized = str(days_off).replace("\r", ",").replace("\n", ",").replace(";", ",")
    for item in normalized.split(","):
        parsed = parse_date(item)
        if parsed != None:
            dates[parsed.format("2006-01-02")] = True
    return dates

def count_school_days(start_date, last_day, days_off):
    start = parse_date(start_date)
    end = parse_date(last_day)
    if not start or not end:
        return -1

    if start > end:
        return 0

    off_dates = parse_days_off(days_off)
    school_days = 0
    current = start

    # Duration of one day
    one_day = time.parse_duration("24h")

    # Iterate from start to end (inclusive)
    # Using a simple loop and comparison since start_ord/end_ord logic is replaced by time objects
    for _ in range(366 * 2):  # Safety limit for ~2 years
        if current > end:
            break

        day_str = current.format("2006-01-02")
        is_weekend = current.format("Mon") in ("Sat", "Sun")

        if not is_weekend and not (day_str in off_dates):
            school_days += 1

        current += one_day

    return school_days

def render_setup(message):
    return render.Root(
        child = render.Box(
            color = "#050505",
            child = render.Column(
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text(content = "School", font = "5x8", color = DEFAULT_ACCENT),
                    render.Text(content = message, font = "tom-thumb", color = "#FFFFFF"),
                ],
            ),
        ),
    )

def render_done(accent):
    return render.Root(
        delay = 500,
        child = render.Animation(
            children = [
                render.Box(
                    color = "#052215",
                    child = render.Column(
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(content = "School's", font = "5x8", color = "#FFFFFF"),
                            render.Text(content = "OUT", font = "6x13", color = accent),
                        ],
                    ),
                ),
                render.Box(
                    color = "#031426",
                    child = render.Column(
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(content = "School is", font = "tom-thumb", color = "#FFFFFF"),
                            render.Text(content = "SUMMER", font = "5x8", color = "#FFD166"),
                        ],
                    ),
                ),
            ],
        ),
    )

def render_chalkboard(count, accent):
    count_text = str(count)
    return render.Root(
        child = render.Box(
            color = "#042215",
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Text(content = count_text, font = "6x13", color = "#FFFFFF"),
                    render.Text(content = "school days", font = "tom-thumb", color = "#DDE7D6"),
                    render.Text(content = "left", font = "tom-thumb", color = "#DDE7D6"),
                    render.Row(
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Box(width = 8, height = 1, color = accent),
                            render.Box(width = 4, height = 1, color = "#FFFFFF"),
                            render.Box(width = 8, height = 1, color = accent),
                            render.Box(width = 4, height = 1, color = "#FFFFFF"),
                            render.Box(width = 8, height = 1, color = accent),
                        ],
                    ),
                ],
            ),
        ),
    )

def render_app(config):
    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)
    today_str = now.format("2006-01-02")
    last_day = config.get("last_day")

    if not last_day or not str(last_day).strip():
        return render_setup("set last day")

    accent = config.str("accent_color", DEFAULT_ACCENT)
    days_off = config.str("days_off", "")
    count = count_school_days(today_str, last_day, days_off)

    if count == -1:
        return render_setup("check date")

    start_t = parse_date(today_str)
    end_t = parse_date(last_day)

    if count == 0 and start_t > end_t:
        return render_done(accent)

    return render_chalkboard(count, accent)

def get_app_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.DateTime(
                id = "last_day",
                name = "Last Day",
                desc = "The final school day.",
                icon = "calendarDays",
            ),
            schema.Text(
                id = "days_off",
                name = "Days Off",
                desc = "YYYY-MM-DD dates to skip, one per line or comma separated.",
                icon = "calendarMinus",
                default = "",
            ),
            schema.Color(
                id = "accent_color",
                name = "Accent Color",
                desc = "Highlight color.",
                icon = "brush",
                default = DEFAULT_ACCENT,
                palette = [
                    "#7AB0FF",
                    "#FFD166",
                    "#78DECC",
                    "#BFEDC4",
                    "#DBB5FF",
                ],
            ),
        ],
    )

def main(config):
    return render_app(config)

def get_schema():
    return get_app_schema()
