"""
Applet: Birthdays
Summary: Upcoming birthday countdowns
Description: Displays upcoming birthdays with an animated cake and cycles through any occurring within the configured lookahead window.
Author: zandif
"""

load("encoding/json.star", "json")
load("images/celebrate_1.png", CELEBRATE_1_ASSET = "file")
load("images/celebrate_2.png", CELEBRATE_2_ASSET = "file")
load("images/celebrate_3.png", CELEBRATE_3_ASSET = "file")
load("images/celebrate_4.png", CELEBRATE_4_ASSET = "file")
load("images/celebrate_5.png", CELEBRATE_5_ASSET = "file")
load("images/celebrate_6.png", CELEBRATE_6_ASSET = "file")
load("images/celebrate_7.png", CELEBRATE_7_ASSET = "file")
load("images/celebrate_8.png", CELEBRATE_8_ASSET = "file")
load("images/countdown_1.png", COUNTDOWN_1_ASSET = "file")
load("images/countdown_2.png", COUNTDOWN_2_ASSET = "file")
load("images/countdown_3.png", COUNTDOWN_3_ASSET = "file")
load("images/countdown_4.png", COUNTDOWN_4_ASSET = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

# Simpler 4-frame flickering-candle cake animation for upcoming countdowns
COUNTDOWN_FRAMES = [
    COUNTDOWN_1_ASSET.readall(),
    COUNTDOWN_2_ASSET.readall(),
    COUNTDOWN_3_ASSET.readall(),
    COUNTDOWN_4_ASSET.readall(),
]

# Special 8-frame celebration animation (firework burst, confetti & sparkles) for birthday day
CELEBRATE_FRAMES = [
    CELEBRATE_1_ASSET.readall(),
    CELEBRATE_2_ASSET.readall(),
    CELEBRATE_3_ASSET.readall(),
    CELEBRATE_4_ASSET.readall(),
    CELEBRATE_5_ASSET.readall(),
    CELEBRATE_6_ASSET.readall(),
    CELEBRATE_7_ASSET.readall(),
    CELEBRATE_8_ASSET.readall(),
]

DEFAULT_COUNT = 3
DEFAULT_LOOKAHEAD_DAYS = 14
DEFAULT_BIRTHDAYS = [
    ("Alice", "2008-08-25"),
    ("Bob", "09-02"),
    ("Charlie", "12-15"),
]

DAYS_IN_MONTH = [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

FRAME_DELAY_MS = 50
COUNTDOWN_HOLD_FRAMES = 4  # 200ms per frame x 4 frames = 800ms per cycle
CELEBRATE_HOLD_FRAMES = 2  # 100ms per frame x 8 frames = 800ms per cycle
CYCLE_MS = 800
MAX_ANIMATION_MS = 15000
ANIM_WIDTH = 17
ANIM_HEIGHT = 26

def is_leap_year(year):
    return (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)

def resolve_day_for_year(month, day, year):
    if month == 2 and day == 29 and not is_leap_year(year):
        return 28
    return day

def parse_positive_int(s, default):
    if not s:
        return default
    cleaned = s.strip()
    if not cleaned.isdigit():
        return default
    val = int(cleaned)
    return val if val > 0 else default

def parse_date(date_str):
    # Parses MM-DD, MM/DD, YYYY-MM-DD, or MM-DD-YYYY
    parts = [p.strip() for p in date_str.replace("/", "-").split("-")]
    if len(parts) not in [2, 3]:
        return None

    for part in parts:
        if not part or not part.isdigit():
            return None

    birth_year = None
    if len(parts) == 2:
        month = int(parts[0])
        day = int(parts[1])
    elif len(parts[0]) == 4:
        birth_year = int(parts[0])
        month = int(parts[1])
        day = int(parts[2])
    elif len(parts[2]) == 4:
        month = int(parts[0])
        day = int(parts[1])
        birth_year = int(parts[2])
    else:
        return None

    if month < 1 or month > 12:
        return None
    if day < 1 or day > DAYS_IN_MONTH[month]:
        return None
    if birth_year != None and month == 2 and day == 29 and not is_leap_year(birth_year):
        return None

    return month, day, birth_year

def calculate_days(bday_month, bday_day, now):
    # Compute calendar-day differences in UTC using already-localized (Y, M, D)
    # to avoid DST spring-forward/fall-back off-by-one errors.
    today_utc = time.time(year = now.year, month = now.month, day = now.day, location = "UTC")

    target_year = now.year
    target_day = resolve_day_for_year(bday_month, bday_day, target_year)
    target_utc = time.time(year = target_year, month = bday_month, day = target_day, location = "UTC")

    days = (target_utc.unix - today_utc.unix) // 86400

    if days < 0:
        target_year += 1
        next_day = resolve_day_for_year(bday_month, bday_day, target_year)
        next_target_utc = time.time(year = target_year, month = bday_month, day = next_day, location = "UTC")
        days = (next_target_utc.unix - today_utc.unix) // 86400

    return days, target_year

def resolve_timezone(config):
    location_str = config.get("location")
    if location_str:
        loc = json.decode(location_str)
        if type(loc) == "dict" and loc.get("timezone"):
            return loc.get("timezone")
    return config.get("$tz") or time.tz() or "America/New_York"

def ordinal_suffix(value):
    if value % 100 in [11, 12, 13]:
        return "th"
    last_digit = value % 10
    if last_digit == 1:
        return "st"
    elif last_digit == 2:
        return "nd"
    elif last_digit == 3:
        return "rd"
    return "th"

def render_birthday_card(name, days, age, anim_imgs, anim_hold_frames, anim_cycles, is_2x):
    scale = 2 if is_2x else 1
    text_width = 44 * scale
    name_font = "terminus-16" if is_2x else "tb-8"
    sub_font = "6x10" if is_2x else "CG-pixel-3x5-mono"
    badge_font = "6x10" if is_2x else "CG-pixel-3x5-mono"
    badge_char_w = 6 if is_2x else 4
    badge_pad_x = 8 if is_2x else 3
    badge_height = 15 if is_2x else 9

    cycle_frames = []
    for img in anim_imgs:
        cycle_frames.extend([img] * anim_hold_frames)
    anim_frames = cycle_frames * anim_cycles

    name_widget = render.Marquee(
        width = text_width,
        align = "center",
        child = render.Text(
            content = name,
            color = "#ffffff",
            font = name_font,
        ),
    )

    if days == 0:
        spacer = render.Box(width = text_width, height = scale)
        text_children = [
            spacer,
            render.Text(
                content = "HAPPY" if is_2x else "Happy",
                color = "#ffd700",
                font = sub_font,
            ),
        ]

        if age != None:
            age_label = "%d%s" % (age, ordinal_suffix(age))
            text_children.extend([
                spacer,
                render.Text(
                    content = age_label.upper() if is_2x else age_label,
                    color = "#ffd700",
                    font = sub_font,
                ),
            ])

        text_children.extend([
            spacer,
            render.Text(
                content = "BIRTHDAY" if is_2x else "Birthday",
                color = "#ffd700",
                font = sub_font,
            ),
            spacer,
            name_widget,
            spacer,
        ])
    else:
        if days == 1:
            badge_text = "TOMORROW"
            badge_color = "#ffaa00"
            badge_bg = "#2b1c00"
        else:
            badge_text = "IN %d DAYS" % days if is_2x else "in %d days" % days
            badge_color = "#00e5ff"
            badge_bg = "#002a33"

        text_children = [name_widget]

        if age != None:
            text_children.extend([
                render.Box(width = text_width, height = scale),
                render.Text(
                    content = "AGE %d" % age if is_2x else "Age %d" % age,
                    color = "#ffd700",
                    font = sub_font,
                ),
                render.Box(width = text_width, height = 2 * scale),
            ])
        else:
            text_children.append(render.Box(width = text_width, height = 3 * scale))

        badge_width = min(text_width, len(badge_text) * badge_char_w + badge_pad_x)
        text_children.append(
            render.Box(
                width = badge_width,
                height = badge_height,
                color = badge_bg,
                child = render.Text(
                    content = badge_text,
                    color = badge_color,
                    font = badge_font,
                ),
            ),
        )

    text_block = render.Column(
        expanded = True,
        main_align = "center",
        cross_align = "center",
        children = text_children,
    )

    return render.Row(
        expanded = True,
        main_align = "center",
        cross_align = "center",
        children = [
            # Animated birthday cake & celebration on the left
            render.Padding(
                pad = (1 * scale, 0, 2 * scale, 0),
                child = render.Animation(children = anim_frames),
            ),
            # Birthday info on the right
            text_block,
        ],
    )

def main(config):
    is_2x = canvas.is2x()
    scale = 2 if is_2x else 1
    anim_width = ANIM_WIDTH * scale
    anim_height = ANIM_HEIGHT * scale
    countdown_imgs = [
        render.Image(src = frame, width = anim_width, height = anim_height)
        for frame in COUNTDOWN_FRAMES
    ]
    celebrate_imgs = [
        render.Image(src = frame, width = anim_width, height = anim_height)
        for frame in CELEBRATE_FRAMES
    ]

    timezone = resolve_timezone(config)
    now = time.now().in_location(timezone)

    count = parse_positive_int(config.get("bday_count"), DEFAULT_COUNT)
    lookahead_days = parse_positive_int(config.get("lookahead_days"), DEFAULT_LOOKAHEAD_DAYS)

    # Only use sample birthdays when no birthday slots have been filled in yet
    has_any_entry = False
    for i in range(count):
        idx = str(i + 1)
        if (config.get("bday_name_" + idx) or "").strip() or (config.get("bday_date_" + idx) or "").strip():
            has_any_entry = True
            break

    entries = []
    if has_any_entry:
        for i in range(count):
            idx = str(i + 1)
            name = (config.get("bday_name_" + idx) or "").strip()
            date_str = (config.get("bday_date_" + idx) or "").strip()
            if name and date_str:
                entries.append((name, date_str))
    else:
        entries = DEFAULT_BIRTHDAYS

    upcoming = []
    nearest = []
    nearest_days = None

    for name, date_str in entries:
        parsed = parse_date(date_str)
        if not parsed:
            continue

        month, day, birth_year = parsed
        days, next_bday_year = calculate_days(month, day, now)

        upcoming_age = None
        if birth_year != None:
            age_candidate = next_bday_year - birth_year
            if age_candidate >= 1:
                upcoming_age = age_candidate

        bday_item = {
            "name": name,
            "days": days,
            "age": upcoming_age,
        }

        if nearest_days == None or days < nearest_days:
            nearest_days = days
            nearest = [bday_item]
        elif days == nearest_days:
            nearest.append(bday_item)

        if days <= lookahead_days:
            upcoming.append(bday_item)

    if len(upcoming) > 0:
        display_list = sorted(upcoming, key = lambda x: x["days"])
    elif len(nearest) > 0:
        display_list = nearest
    else:
        return render.Root(
            child = render.Box(
                child = render.Text(
                    "No Birthdays",
                    color = "#888888",
                    font = "terminus-16" if is_2x else "tb-8",
                ),
            ),
        )

    # Single birthday card: simple candle flicker before birthday, special celebration on birthday
    if len(display_list) == 1:
        item = display_list[0]
        is_today = item["days"] == 0
        return render.Root(
            delay = FRAME_DELAY_MS,
            child = render_birthday_card(
                item["name"],
                item["days"],
                item["age"],
                celebrate_imgs if is_today else countdown_imgs,
                CELEBRATE_HOLD_FRAMES if is_today else COUNTDOWN_HOLD_FRAMES,
                1,
                is_2x,
            ),
        )

    # Multiple birthdays: scale cycles per person to fit within 15s when possible
    cycles_per_person = MAX_ANIMATION_MS // (len(display_list) * CYCLE_MS)
    if cycles_per_person > 5:
        cycles_per_person = 5
    elif cycles_per_person < 2:
        cycles_per_person = 2

    cards = [
        render_birthday_card(
            item["name"],
            item["days"],
            item["age"],
            celebrate_imgs if item["days"] == 0 else countdown_imgs,
            CELEBRATE_HOLD_FRAMES if item["days"] == 0 else COUNTDOWN_HOLD_FRAMES,
            cycles_per_person,
            is_2x,
        )
        for item in display_list
    ]

    return render.Root(
        delay = FRAME_DELAY_MS,
        show_full_animation = True,
        child = render.Sequence(children = cards),
    )

def generate_schema(param):
    # Support both dictionary config objects and direct string values
    count_str = None
    if type(param) == "dict":
        count_str = param.get("bday_count")
    elif type(param) == "string":
        count_str = param

    count = parse_positive_int(count_str, DEFAULT_COUNT)
    fields = []

    for i in range(count):
        idx = str(i + 1)
        fields.append(
            schema.Text(
                id = "bday_name_" + idx,
                name = "Birthday %s Name" % idx,
                desc = "Name of person %s" % idx,
                icon = "user",
                default = "",
            ),
        )
        fields.append(
            schema.Text(
                id = "bday_date_" + idx,
                name = "Birthday %s Date" % idx,
                desc = "Date for person %s (YYYY-MM-DD or MM-DD)" % idx,
                icon = "cakeCandles",
                default = "",
            ),
        )

    return fields

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location used to determine your local timezone (optional)",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "lookahead_days",
                name = "Multi-Birthday Window",
                desc = "Cycle through all birthdays within this many days (otherwise shows the next upcoming birthday)",
                icon = "calendar",
                default = str(DEFAULT_LOOKAHEAD_DAYS),
                options = [
                    schema.Option(display = "7 days", value = "7"),
                    schema.Option(display = "14 days", value = "14"),
                    schema.Option(display = "30 days", value = "30"),
                    schema.Option(display = "60 days", value = "60"),
                    schema.Option(display = "90 days", value = "90"),
                    schema.Option(display = "All (365 days)", value = "365"),
                ],
            ),
            schema.Dropdown(
                id = "bday_count",
                name = "Number of Birthdays",
                desc = "How many birthdays to track",
                icon = "listOl",
                default = str(DEFAULT_COUNT),
                options = [
                    schema.Option(display = str(i), value = str(i))
                    for i in range(1, 31)
                ],
            ),
            schema.Generated(
                id = "generated_schema",
                source = "bday_count",
                handler = generate_schema,
            ),
        ],
    )
