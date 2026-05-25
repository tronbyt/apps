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
WHITESPACE = " \t\r\n"

def is_digit(char):
    return char in "0123456789"

def trim(text):
    text = str(text)
    start = -1
    end = -1
    for i in range(len(text)):
        if start == -1 and not (text[i] in WHITESPACE):
            start = i
    for i in range(len(text)):
        pos = len(text) - i - 1
        if end == -1 and not (text[pos] in WHITESPACE):
            end = pos + 1
    if start == -1:
        return ""
    return text[start:end]

def days_in_month(year, month):
    if month == 2:
        if is_leap_year(year):
            return 29
        return 28
    if month in [4, 6, 9, 11]:
        return 30
    if month in [1, 3, 5, 7, 8, 10, 12]:
        return 31
    return 0

def is_leap_year(year):
    return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)

def parse_date(value):
    if value == None:
        return None

    raw = trim(value)
    if len(raw) < 10:
        return None

    if raw[4:5] != "-" or raw[7:8] != "-":
        return None

    date_bits = raw[0:4] + raw[5:7] + raw[8:10]
    for i in range(len(date_bits)):
        if not is_digit(date_bits[i]):
            return None

    year = int(raw[0:4], 10)
    month = int(raw[5:7], 10)
    day = int(raw[8:10], 10)
    if month < 1 or month > 12:
        return None
    if day < 1 or day > days_in_month(year, month):
        return None

    return [year, month, day]

def pad2(value):
    text = str(value)
    if len(text) == 1:
        return "0" + text
    return text

def date_key(date):
    return str(date[0]) + "-" + pad2(date[1]) + "-" + pad2(date[2])

def days_before_year(year):
    prior_year = year - 1
    return prior_year * 365 + prior_year // 4 - prior_year // 100 + prior_year // 400

def date_to_ordinal(date):
    days = days_before_year(date[0]) + date[2]
    for month in range(1, date[1]):
        days += days_in_month(date[0], month)
    return days

def is_weekend(date):
    weekday = (date_to_ordinal(date) - 1) % 7
    return weekday == 5 or weekday == 6

def next_date(date):
    year = date[0]
    month = date[1]
    day = date[2] + 1
    if day > days_in_month(year, month):
        day = 1
        month += 1
    if month > 12:
        month = 1
        year += 1
    return [year, month, day]

def parse_days_off(days_off):
    dates = {}
    if days_off == None:
        return dates

    normalized = str(days_off).replace("\r", ",").replace("\n", ",").replace(";", ",")
    for item in normalized.split(","):
        parsed = parse_date(item)
        if parsed != None:
            dates[date_key(parsed)] = True
    return dates

def count_school_days(start_date, last_day, days_off):
    start = parse_date(start_date)
    end = parse_date(last_day)
    if start == None or end == None:
        return -1

    start_ord = date_to_ordinal(start)
    end_ord = date_to_ordinal(end)
    if start_ord > end_ord:
        return 0

    off_dates = parse_days_off(days_off)
    school_days = 0
    current = start
    for _ in range(end_ord - start_ord + 1):
        key = date_key(current)
        if not is_weekend(current) and not (key in off_dates):
            school_days += 1
        current = next_date(current)

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
    today = time.now().in_location(timezone).format("2006-01-02")
    last_day = config.get("last_day")
    if last_day == None or trim(last_day) == "":
        return render_setup("set last day")

    accent = config.str("accent_color", DEFAULT_ACCENT)
    days_off = config.str("days_off", "")
    count = count_school_days(today, last_day, days_off)

    if count == -1:
        return render_setup("check date")
    if count == 0 and date_to_ordinal(parse_date(today)) > date_to_ordinal(parse_date(last_day)):
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
