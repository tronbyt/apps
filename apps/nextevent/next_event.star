load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_ICS_URL = "https://ics.calendarlabs.com/76/8d23255e/US_Holidays.ics"
DEFAULT_TITLE = "Next event"

# Matches the app's recommended refresh interval.
CACHE_TTL_SECONDS = 300

def main(config):
    location = config.str("loc")
    location = json.decode(location) if location else {}
    timezone = location.get(
        "timezone",
        time.tz(),
    )
    ics_url = config.str("url", DEFAULT_ICS_URL)
    now = time.now().in_location(timezone)

    # The calendar is downloaded and parsed right here (see the iCalendar
    # section below), so the app needs no service outside of Tronbyt.
    calendar = fetch_calendar(ics_url)
    if calendar == None:
        bottom = render_message("Can't load", "calendar")
    else:
        next_event = find_next_event(calendar, now, timezone)
        bottom = render_bottom(next_event, now, timezone)

    return render.Root(
        child = render.Column(
            cross_align = "center",
            main_align = "space_around",
            children = render_top(config) + bottom,
        ),
    )

def fetch_calendar(url):
    """Downloads an iCalendar feed, or returns None if it's unavailable."""
    url = url.strip()

    # Calendar apps often share subscription links as webcal://, which is
    # served over HTTPS.
    if url.startswith("webcal://"):
        url = "https://" + url[len("webcal://"):]
    if not url.startswith("https://") and not url.startswith("http://"):
        return None

    response = http.get(url, ttl_seconds = CACHE_TTL_SECONDS)
    if response.status_code != 200:
        return None
    body = response.body()
    return body if "BEGIN:VCALENDAR" in body.upper() else None

def render_top(config):
    return [
        render.Marquee(
            child = render.Text(
                content = config.str("title", DEFAULT_TITLE),
                color = "#ffea00",
            ),
            width = 64,
            align = "center",
        ),
        render.Box(
            color = "#ffea00",
            height = 1,
        ),
    ]

def render_bottom(next_event, now, timezone):
    if next_event == None:
        return render_message("No more", "events")

    return [
        render.Box(
            color = "#000",
            height = 3,
        ),
        render.Marquee(
            child = render.Text(
                content = next_event["title"],
            ),
            width = 64,  # Full width
            align = "center",
        ),
        render.Box(
            color = "#000",
            height = 1,
        ),
        render.Text(
            # Date
            content = pretty_date(next_event["start"], now, timezone),
        ),
    ]

def pretty_date(start, now, timezone):
    """Shows relative dates for events today or tomorrow, e.g. "May 27" otherwise."""
    tomorrow = time.time(year = now.year, month = now.month, day = now.day + 1, location = timezone)
    start_date = start.format("2006-01-02")
    if start_date == now.format("2006-01-02"):
        return "Today"
    if start_date == tomorrow.format("2006-01-02"):
        return "Tomorrow"
    return "{} {}".format(start.format("Jan"), start.day)

def render_message(first_line, second_line):
    return [
        render.Box(
            color = "#000",
            height = 3,
        ),
        render.Text(
            content = first_line,
        ),
        render.Text(
            content = second_line,
        ),
    ]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "loc",
                name = "Location",
                desc = "Location for timezone awareness",
                icon = "locationDot",
            ),
            schema.Text(
                id = "url",
                name = "iCalendar URL",
                desc = "The URL of the iCalendar file.",
                icon = "calendar",
                default = DEFAULT_ICS_URL,
            ),
            schema.Text(
                id = "title",
                name = "The title displayed above the next event",
                desc = "What are the events on this calendar?",
                icon = "calendar",
                default = DEFAULT_TITLE,
            ),
        ],
    )

# iCalendar
#
# Finds the first event in an .ics feed still to come at a given moment: the
# earliest start after it, or an all-day event on that day. Recurring events
# (RRULE, RDATE, EXDATE, and instances moved or cancelled via RECURRENCE-ID)
# are expanded here, and TZID time zones are resolved through the IANA
# database or the feed's own VTIMEZONE definitions.
#
# Times are handled as "local seconds": seconds since 1970-01-01T00:00 on the
# wall clock of a zone. Zones are "UTC", an IANA name, or "vtz:<TZID>" for a
# zone that is only defined by a VTIMEZONE in the feed.

DAY = 86400

# Upper bound on the recurrence periods (days, weeks, months or years) scanned
# per event past today, so a rule that never matches can't stall rendering.
MAX_PERIODS = 5000

# Daylight saving changes shift a zone's offset by at most this much, so wall
# times further than this from now are certainly before or after it.
MAX_OFFSET_CHANGE = 3 * 3600

EVENT_PROPS = {
    "DTSTART": True,
    "EXDATE": True,
    "RDATE": True,
    "RECURRENCE-ID": True,
    "RRULE": True,
    "STATUS": True,
    "SUMMARY": True,
    "UID": True,
}

TIMEZONE_PROPS = {
    "DTSTART": True,
    "RDATE": True,
    "RRULE": True,
    "TZOFFSETFROM": True,
    "TZOFFSETTO": True,
}

# Properties that can appear more than once in a component.
LIST_PROPS = {"EXDATE": True, "RDATE": True}

WEEKDAYS = {"MO": 0, "TU": 1, "WE": 2, "TH": 3, "FR": 4, "SA": 5, "SU": 6}

FREQUENCIES = {"DAILY": True, "WEEKLY": True, "MONTHLY": True, "YEARLY": True}

# Valid but rarely used rule parts. Events whose rule uses them only occur on
# their DTSTART (and any RDATEs).
UNSUPPORTED_RULE_PARTS = {"BYWEEKNO": True, "BYYEARDAY": True}

# Rule parts that pick times within a day. Only one time per day is supported:
# the one DTSTART names.
TIME_PARTS = {"BYHOUR": 3600, "BYMINUTE": 60, "BYSECOND": 1}

def find_next_event(ics_text, now, timezone):
    """Returns the first event in `ics_text` still to come at `now`.

    That is the event with the earliest start after `now`, or an all-day event
    on the current day. Floating times and all-day events are read in
    `timezone`. The result is a dict with the event's "title", its "start" as a
    time in `timezone` and whether it is "all_day", or None if nothing is left.
    """
    text = normalize_markers(unfold(ics_text))
    ctx = new_context(text, now, timezone)
    events = []
    for block in components(text, "VEVENT"):
        block = own_text(block)
        if not is_past_one_off(block, ctx["cutoff"]):
            events.append(parse_props(block.split("\n"), EVENT_PROPS))

    # Moved or cancelled instances of a series are published as separate
    # VEVENTs with a RECURRENCE-ID. The series must skip those slots.
    replaced = {}
    for props in events:
        if "RECURRENCE-ID" in props and "UID" in props:
            replaced.setdefault(props["UID"][0], []).append(props["RECURRENCE-ID"])

    upcoming = []
    for props in events:
        if "DTSTART" not in props or props.get("STATUS", ("", {}))[0].upper() == "CANCELLED":
            continue
        start = next_start(ctx, props, replaced.get(props.get("UID", ("", {}))[0], []))
        if start != None:
            upcoming.append((start["lsec"] - zone_now(ctx, start["zone"]), start, props))
    if not upcoming:
        return None

    # Wall-clock distance from now is within MAX_OFFSET_CHANGE of the real
    # distance, so only starts close to the nearest one need exact instants.
    nearest = min([ahead for ahead, _, _ in upcoming])
    best = None
    for ahead, start, props in upcoming:
        if ahead <= nearest + 2 * MAX_OFFSET_CHANGE:
            unix = to_unix(ctx, start["zone"], start["lsec"])
            if best == None or unix < best["unix"]:
                best = {"all_day": start["date"], "props": props, "unix": unix}
    title = unescape(best["props"].get("SUMMARY", ("", {}))[0]).strip()
    return {
        "all_day": best["all_day"],
        "start": time.from_timestamp(best["unix"]).in_location(timezone),
        "title": title or "(No title)",
    }

def next_start(ctx, props, replaced):
    """The event's first start after now, as a parsed value, or None.

    For a recurring event this is its first remaining instance. `replaced`
    lists the RECURRENCE-IDs of instances published as separate VEVENTs.
    """
    rrule = props.get("RRULE")
    rdates = props.get("RDATE", [])
    if "RECURRENCE-ID" in props:
        # A single moved instance of a series, not a series of its own.
        rrule = None
        rdates = []

    start = parse_value(ctx, props["DTSTART"][0], props["DTSTART"][1])
    if start == None:
        return None
    zone = start["zone"]
    if rrule == None and not rdates:
        return start if is_upcoming(ctx, zone, start["lsec"], start["date"]) else None

    excluded = {}
    excluded_days = {}
    for prop in props.get("EXDATE", []) + replaced:
        for value in list_values(ctx, prop):
            lsec = in_zone(ctx, value, zone)
            if value["date"] or start["date"]:
                excluded_days[lsec // DAY] = True
            else:
                excluded[lsec] = True

    # DTSTART is always the first instance, whether or not the rule matches it.
    candidates = [start["lsec"]]
    for prop in rdates:
        candidates.extend([in_zone(ctx, value, zone) for value in list_values(ctx, prop)])
    rule = parse_rrule(rrule[0], start["lsec"]) if rrule != None else None
    if rule != None and rule["until"] != None:
        rule["until"] = until_lsec(ctx, rule["until"], start)
        if rule["until"] == None:
            rule = None
    if rule != None:
        lsec = next_occurrence(ctx, rule, start, excluded, excluded_days)
        if lsec != None:
            candidates.append(lsec)

    best = None
    for lsec in candidates:
        if lsec not in excluded and lsec // DAY not in excluded_days and is_upcoming(ctx, zone, lsec, start["date"]):
            if best == None or lsec < best:
                best = lsec
    if best == None:
        return None
    return {"date": start["date"], "lsec": best, "zone": zone}

def is_past_one_off(block, cutoff):
    """Whether a VEVENT's own text is a non-recurring event dated before the cutoff.

    Large feeds are mostly past meetings, so this skips them without parsing
    every line. Anything it can't judge cheaply is kept.
    """
    if "\nRRULE" in block or "\nRDATE" in block or "\nRECURRENCE-ID" in block:
        return False
    start = block.find("\nDTSTART")
    if start < 0:
        return False
    line = block[start + 1:].partition("\n")[0]
    key = date_key(line.rpartition(":")[2])
    return key > 0 and key < cutoff

def list_values(ctx, prop):
    """Parses the comma-separated values of an EXDATE, RDATE or RECURRENCE-ID.

    Values dated before the context's cutoff are dropped: they can't affect
    which instance comes next.
    """
    text, params = prop
    if params.get("VALUE", "").upper() == "PERIOD":
        return []
    values = []
    for item in text.split(","):
        if date_key(item) >= ctx["cutoff"]:
            value = parse_value(ctx, item, params)
            if value != None:
                values.append(value)
    return values

def until_lsec(ctx, text, start):
    """A rule's UNTIL as local seconds in the zone of the event's DTSTART."""
    value = parse_value(ctx, text, {})
    if value == None:
        return None
    if value["date"]:
        # A date bound includes the whole day.
        return value["lsec"] + (0 if start["date"] else DAY - 1)
    if text.strip().upper().endswith("Z"):
        return in_zone(ctx, value, start["zone"])
    return value["lsec"]

# Recurrence rules

def parse_rrule(text, start):
    """Parses an RRULE value, or returns None for rules that can't be expanded.

    `start` is the DTSTART of the rule's component as local seconds. UNTIL is
    kept as the raw value for the caller to interpret.
    """
    rule = {
        "byday": [],
        "bymonth": [],
        "bymonthday": [],
        "bysetpos": [],
        "count": None,
        "freq": None,
        "interval": 1,
        "until": None,
        "wkst": 0,
    }
    for part in text.upper().split(";"):
        key, _, value = part.partition("=")
        key = key.strip()
        value = value.strip()
        if key == "FREQ":
            rule["freq"] = value
        elif key == "INTERVAL" or key == "COUNT":
            number = to_int(value)
            if number == None or number < 1:
                return None
            rule[key.lower()] = number
        elif key == "UNTIL":
            rule["until"] = value
        elif key == "WKST":
            if value not in WEEKDAYS:
                return None
            rule["wkst"] = WEEKDAYS[value]
        elif key == "BYDAY":
            for item in value.split(","):
                item = item.strip()
                nth = to_int(item[:-2]) if len(item) > 2 else 0
                if nth == None or item[-2:] not in WEEKDAYS:
                    return None
                rule["byday"].append((nth, WEEKDAYS[item[-2:]]))
        elif key == "BYMONTH" or key == "BYMONTHDAY" or key == "BYSETPOS":
            for item in value.split(","):
                number = to_int(item)
                if number == None or number == 0:
                    return None
                rule[key.lower()].append(number)
        elif key in TIME_PARTS:
            # Some producers restate DTSTART's time of day in the rule, which
            # changes nothing. Anything else would mean several instances a day.
            unit = TIME_PARTS[key]
            if to_int(value) != start % DAY // unit % (24 if unit == 3600 else 60):
                return None
        elif key in UNSUPPORTED_RULE_PARTS:
            return None
    if rule["freq"] not in FREQUENCIES:
        return None
    rule["weekdays"] = [wd for _, wd in rule["byday"]]
    return rule

def next_occurrence(ctx, rule, start, excluded, excluded_days):
    """The first upcoming instance generated by `rule`, or None.

    `start` is the event's parsed DTSTART; the result is local seconds in its
    zone. Excluded instances still count towards COUNT.
    """
    zone = start["zone"]
    start_day = start["lsec"] // DAY
    time_of_day = start["lsec"] % DAY
    year, month, day_of_month = civil_from_days(start_day)

    # Instances before today only matter for tallying a COUNT, so without one
    # the scan starts at the period before today's.
    today = zone_now(ctx, zone) // DAY
    elapsed = max(0, elapsed_periods(rule, start_day, today) // rule["interval"])
    period = 0 if rule["count"] != None else max(0, elapsed - 1)

    seen = 0
    for _ in range(elapsed - period + MAX_PERIODS + 1):
        for day in period_days(rule, period * rule["interval"], start_day, year, month, day_of_month):
            if day < start_day:
                continue
            lsec = day * DAY + time_of_day
            if rule["until"] != None and lsec > rule["until"]:
                return None
            seen += 1
            if rule["count"] != None and seen > rule["count"]:
                return None
            if lsec not in excluded and day not in excluded_days and is_upcoming(ctx, zone, lsec, start["date"]):
                return lsec
        period += 1
    return None

def elapsed_periods(rule, start_day, day):
    """Whole frequency units (days, weeks, months or years) from start_day to day."""
    if rule["freq"] == "DAILY":
        return day - start_day
    if rule["freq"] == "WEEKLY":
        return (day - week_start(start_day, rule["wkst"])) // 7
    start_year, start_month, _ = civil_from_days(start_day)
    year, month, _ = civil_from_days(day)
    if rule["freq"] == "MONTHLY":
        return (year - start_year) * 12 + month - start_month
    return year - start_year

def period_days(rule, offset, start_day, year, month, day_of_month):
    """Sorted candidate days of the period `offset` units after DTSTART's period."""
    freq = rule["freq"]
    if freq == "DAILY":
        day = start_day + offset
        days = [day] if day_matches(rule, day) else []
    elif freq == "WEEKLY":
        first = week_start(start_day, rule["wkst"]) + offset * 7
        weekdays = rule["weekdays"] or [weekday(start_day)]
        days = unique_sorted([first + (wd - rule["wkst"]) % 7 for wd in weekdays])
        if rule["bymonth"]:
            days = [day for day in days if civil_from_days(day)[1] in rule["bymonth"]]
    elif freq == "MONTHLY":
        months = month - 1 + offset
        year, month = year + months // 12, months % 12 + 1
        if rule["bymonth"] and month not in rule["bymonth"]:
            days = []
        else:
            days = month_days(rule, year, month, day_of_month)
    else:
        days = year_days(rule, year + offset, month, day_of_month)
    return select_positions(days, rule["bysetpos"])

def day_matches(rule, day):
    """Whether a DAILY candidate passes the rule's BYDAY/BYMONTH/BYMONTHDAY limits."""
    if rule["weekdays"] and weekday(day) not in rule["weekdays"]:
        return False
    if not rule["bymonth"] and not rule["bymonthday"]:
        return True
    year, month, day_of_month = civil_from_days(day)
    if rule["bymonth"] and month not in rule["bymonth"]:
        return False
    return not rule["bymonthday"] or monthday_matches(rule["bymonthday"], year, month, day_of_month)

def month_days(rule, year, month, default_day):
    """Sorted candidate days of a month from BYDAY and/or BYMONTHDAY.

    Without either, the month's `default_day` (DTSTART's day) if it exists.
    """
    first = days_from_civil(year, month, 1)
    length = days_in_month(year, month)
    if rule["byday"]:
        days = weekdays_between(rule["byday"], first, first + length - 1)
        if rule["bymonthday"]:
            days = [day for day in days if monthday_matches(rule["bymonthday"], year, month, day - first + 1)]
    elif rule["bymonthday"]:
        days = [first + n - 1 if n > 0 else first + length + n for n in rule["bymonthday"]]
        days = [day for day in days if day >= first and day < first + length]
    elif default_day <= length:
        days = [first + default_day - 1]
    else:
        days = []
    return unique_sorted(days)

def year_days(rule, year, default_month, default_day):
    """Sorted candidate days of a year for a YEARLY rule."""
    days = []
    if rule["bymonth"]:
        for month in rule["bymonth"]:
            days.extend(month_days(rule, year, month, default_day))
    elif rule["byday"]:
        # Without BYMONTH, ordinals like 20MO count from the start of the year.
        first = days_from_civil(year, 1, 1)
        days = weekdays_between(rule["byday"], first, days_from_civil(year, 12, 31))
        if rule["bymonthday"]:
            matching = []
            for day in days:
                y, m, d = civil_from_days(day)
                if monthday_matches(rule["bymonthday"], y, m, d):
                    matching.append(day)
            days = matching
    elif rule["bymonthday"]:
        for month in range(1, 13):
            days.extend(month_days(rule, year, month, default_day))
    else:
        days = month_days(rule, year, default_month, default_day)
    return unique_sorted(days)

def weekdays_between(byday, first, last):
    """Days in [first, last] matching BYDAY entries such as MO, 2TU or -1FR."""
    days = []
    for nth, wd in byday:
        if nth == 0:
            days.extend(range(first + (wd - weekday(first)) % 7, last + 1, 7))
        elif nth > 0:
            days.append(first + (wd - weekday(first)) % 7 + (nth - 1) * 7)
        else:
            days.append(last - (weekday(last) - wd) % 7 + (nth + 1) * 7)
    return [day for day in days if day >= first and day <= last]

def monthday_matches(bymonthday, year, month, day_of_month):
    return day_of_month in bymonthday or day_of_month - days_in_month(year, month) - 1 in bymonthday

def select_positions(days, positions):
    """Applies BYSETPOS to a period's sorted candidate days."""
    if not positions:
        return days
    count = len(days)
    return unique_sorted([days[n - 1 if n > 0 else count + n] for n in positions if n <= count and -n <= count])

def unique_sorted(days):
    return sorted({day: True for day in days}.keys())

# Dates, times and zones

def parse_value(ctx, text, params):
    """Parses a DATE or DATE-TIME value, or returns None if it's malformed.

    Returns a dict with "lsec" (local seconds), "zone" and whether it is a
    "date". Dates and floating times belong to the display zone.
    """
    text = text.strip().upper()
    if len(text) < 8 or not text[:8].isdigit():
        return None
    day = days_from_civil(int(text[:4]), int(text[4:6]), int(text[6:8]))
    if len(text) == 8 or params.get("VALUE", "").upper() == "DATE":
        return {"date": True, "lsec": day * DAY, "zone": ctx["tz"]}
    clock = text[9:].rstrip("Z")
    if text[8] != "T" or len(clock) < 4 or not clock.isdigit():
        return None
    seconds = int(clock[:2]) * 3600 + int(clock[2:4]) * 60 + int(clock[4:6] or "0")
    if text.endswith("Z"):
        zone = "UTC"
    elif params.get("TZID"):
        zone = resolve_tzid(ctx, params["TZID"])
    else:
        zone = ctx["tz"]
    return {"date": False, "lsec": day * DAY + seconds, "zone": zone}

def date_key(text):
    """The YYYYMMDD prefix of a DATE or DATE-TIME value as an int, or 0."""
    digits = text.strip()[:8]
    return int(digits) if len(digits) == 8 and digits.isdigit() else 0

def date_key_of(day):
    """The YYYYMMDD of a day number as an int, comparable with date_key."""
    year, month, day_of_month = civil_from_days(day)
    return year * 10000 + month * 100 + day_of_month

def resolve_tzid(ctx, tzid):
    """Maps a TZID parameter to a zone, falling back to the display zone."""
    zone = ctx["tzids"].get(tzid)
    if zone != None:
        return zone

    zone = ctx["tz"]
    found = False

    # Some producers prefix IANA names with a vendor path, as in
    # /mozilla.org/20070129_1/Europe/Berlin.
    parts = tzid.strip().strip("/").split("/")
    for i in range(len(parts)):
        name = "/".join(parts[i:])
        if name and name != "Local" and time.is_valid_timezone(name):
            zone = name
            found = True
            break

    # Otherwise use the feed's own definition, as Outlook does with names
    # such as "Eastern Standard Time".
    if not found and tzid in ctx["vtimezones"]:
        observances = parse_vtimezone(ctx, ctx["vtimezones"][tzid])
        if observances:
            zone = "vtz:" + tzid
            ctx["vtz_observances"][zone] = observances

    ctx["tzids"][tzid] = zone
    return zone

def zone_now(ctx, zone):
    """The current time as local seconds in `zone`."""
    if zone not in ctx["now_lsec"]:
        ctx["now_lsec"][zone] = unix_to_lsec(ctx, zone, ctx["now"])
    return ctx["now_lsec"][zone]

def is_upcoming(ctx, zone, lsec, all_day):
    """Whether a wall-clock time in `zone` is still to come.

    An all-day event counts until its day is over. Comparing wall-clock times
    is exact except close to a daylight saving change, so times near now are
    compared as instants.
    """
    if all_day:
        lsec += DAY
    ahead = lsec - zone_now(ctx, zone)
    if ahead > MAX_OFFSET_CHANGE or ahead < -MAX_OFFSET_CHANGE:
        return ahead > 0
    return to_unix(ctx, zone, lsec) > ctx["now"]

def in_zone(ctx, value, zone):
    """A parsed value as local seconds in `zone`. Dates are not converted."""
    if value["date"] or value["zone"] == zone:
        return value["lsec"]
    return unix_to_lsec(ctx, zone, to_unix(ctx, value["zone"], value["lsec"]))

def to_unix(ctx, zone, lsec):
    """The instant of a wall-clock time in `zone`.

    As RFC 5545 specifies, a time skipped by a daylight saving change is read
    with the offset from before the change, and a repeated time means its
    first occurrence.
    """
    if zone == "UTC":
        return lsec
    if zone.startswith("vtz:"):
        return lsec - vtimezone_offset(ctx["vtz_observances"][zone], lsec, False)
    year, month, day = civil_from_days(lsec // DAY)
    seconds = lsec % DAY
    t = time.time(
        year = year,
        month = month,
        day = day,
        hour = seconds // 3600,
        minute = seconds % 3600 // 60,
        second = seconds % 60,
        location = zone,
    )

    # time.time() resolves skipped and repeated times differently from zone
    # to zone, so check against the offset in effect a day earlier.
    earlier = unix_to_lsec(ctx, zone, t.unix - DAY) - (t.unix - DAY)
    if days_from_civil(t.year, t.month, t.day) * DAY + t.hour * 3600 + t.minute * 60 + t.second != lsec:
        return lsec - earlier
    first = lsec - earlier
    if first < t.unix and unix_to_lsec(ctx, zone, first) == lsec:
        return first
    return t.unix

def unix_to_lsec(ctx, zone, unix):
    """The wall-clock time in `zone` at a UTC instant, as local seconds."""
    if zone == "UTC":
        return unix
    if zone.startswith("vtz:"):
        return unix + vtimezone_offset(ctx["vtz_observances"][zone], unix, True)
    local = time.from_timestamp(unix).in_location(zone)
    return days_from_civil(local.year, local.month, local.day) * DAY + local.hour * 3600 + local.minute * 60 + local.second

def parse_vtimezone(ctx, block):
    """Reads a VTIMEZONE's observances, STANDARD ones first."""
    observances = []
    for kind in ("STANDARD", "DAYLIGHT"):
        for sub in components(block, kind):
            props = parse_props(sub.split("\n"), TIMEZONE_PROPS)
            offset = parse_offset(props["TZOFFSETTO"][0]) if "TZOFFSETTO" in props else None
            previous = parse_offset(props["TZOFFSETFROM"][0]) if "TZOFFSETFROM" in props else offset
            start = parse_value(ctx, props["DTSTART"][0], {}) if "DTSTART" in props else None
            if offset == None or previous == None or start == None:
                continue
            rdates = []
            for prop in props.get("RDATE", []):
                rdates.extend([parse_value(ctx, item, {}) for item in prop[0].split(",")])
            observances.append({
                "offset": offset,
                "previous": previous,
                "rdates": [value["lsec"] for value in rdates if value != None],
                "rule": parse_rrule(props["RRULE"][0], start["lsec"]) if "RRULE" in props else None,
                "start": start["lsec"],
            })
    return observances

def vtimezone_offset(observances, seconds, utc):
    """The UTC offset in effect at `seconds`, a UTC instant if `utc` or else a local time."""
    offset = observances[0]["offset"]
    latest = None
    for observance in observances:
        # Onsets are wall-clock times on the previous offset. A local time
        # skipped when clocks go forward keeps the previous offset.
        if utc:
            onset = latest_onset(observance, seconds + observance["previous"])
        else:
            onset = latest_onset(observance, seconds - max(0, observance["offset"] - observance["previous"]))
        if onset != None and (latest == None or onset - observance["previous"] > latest):
            latest = onset - observance["previous"]
            offset = observance["offset"]
    return offset

def latest_onset(observance, lsec):
    """When `observance` last took effect at or before local time `lsec`, or None."""
    if observance["start"] > lsec:
        return None
    latest = observance["start"]
    for onset in observance["rdates"]:
        if onset <= lsec and onset > latest:
            latest = onset

    rule = observance["rule"]
    if rule == None or rule["freq"] != "YEARLY":
        return latest
    start_year, start_month, start_day = civil_from_days(observance["start"] // DAY)
    year = civil_from_days(lsec // DAY)[0]
    for y in (year, year - 1):
        days = year_days(rule, y, start_month, start_day) if y >= start_year else []
        if not days or (rule["until"] != None and date_key_of(days[0]) > date_key(rule["until"])):
            continue
        onset = days[0] * DAY + observance["start"] % DAY
        if onset <= lsec:
            return max(latest, onset)
    return latest

def parse_offset(text):
    """Parses a UTC offset such as -0500 or +0530 into seconds."""
    text = text.strip()
    if len(text) < 5 or text[0] not in "+-" or not text[1:].isdigit():
        return None
    seconds = int(text[1:3]) * 3600 + int(text[3:5]) * 60 + int(text[5:7] or "0")
    return -seconds if text[0] == "-" else seconds

def new_context(text, now, timezone):
    vtimezones = {}
    for block in components(text, "VTIMEZONE"):
        tzid = parse_props(own_text(block).split("\n"), {"TZID": True}).get("TZID")
        if tzid != None:
            vtimezones[tzid[0]] = block

    # Values dated before the cutoff are in the past in every zone.
    local = now.in_location(timezone)
    return {
        "cutoff": date_key_of(days_from_civil(local.year, local.month, local.day) - 2),
        "now": now.unix,
        "now_lsec": {},
        "tz": timezone,
        "tzids": {},
        "vtimezones": vtimezones,
        "vtz_observances": {},
    }

# Calendar arithmetic on days since 1970-01-01 (proleptic Gregorian).

def days_from_civil(year, month, day):
    if month <= 2:
        year -= 1
    era = year // 400
    year_of_era = year - era * 400
    day_of_year = (153 * (month + (9 if month <= 2 else -3)) + 2) // 5 + day - 1
    day_of_era = year_of_era * 365 + year_of_era // 4 - year_of_era // 100 + day_of_year
    return era * 146097 + day_of_era - 719468

def civil_from_days(days):
    days += 719468
    era = days // 146097
    day_of_era = days - era * 146097
    year_of_era = (day_of_era - day_of_era // 1460 + day_of_era // 36524 - day_of_era // 146096) // 365
    day_of_year = day_of_era - (365 * year_of_era + year_of_era // 4 - year_of_era // 100)
    shifted_month = (5 * day_of_year + 2) // 153
    day = day_of_year - (153 * shifted_month + 2) // 5 + 1
    month = shifted_month + 3 if shifted_month < 10 else shifted_month - 9
    return year_of_era + era * 400 + (1 if month <= 2 else 0), month, day

def weekday(day):
    """Day of the week, Monday = 0."""
    return (day + 3) % 7

def week_start(day, wkst):
    return day - (weekday(day) - wkst) % 7

def days_in_month(year, month):
    if month == 2:
        return 29 if year % 4 == 0 and (year % 100 != 0 or year % 400 == 0) else 28
    return 30 if month in (4, 6, 9, 11) else 31

# Content lines

def unfold(text):
    """Normalizes line endings and joins folded lines (RFC 5545, 3.1)."""
    text = "\n" + text.replace("\r\n", "\n").replace("\r", "\n")
    return text.replace("\n ", "").replace("\n\t", "")

def normalize_markers(text):
    """Upper-cases BEGIN:/END: lines, whose names are case-insensitive.

    Feeds nearly always write them in upper case already, so the pass over
    every line only runs when no event is found that way.
    """
    if "\nBEGIN:VEVENT" in text:
        return text
    lines = text.split("\n")
    for i, line in enumerate(lines):
        prefix = line[:6].upper()
        if prefix.startswith("BEGIN:") or prefix.startswith("END:"):
            lines[i] = line.upper()
    return "\n".join(lines)

def components(text, name):
    """The bodies of all `name` components in unfolded text."""
    return [chunk.partition("\nEND:" + name)[0] for chunk in text.split("\nBEGIN:" + name)[1:]]

def own_text(body):
    """A component's text, without nested components such as VALARM."""
    parts = body.split("\nBEGIN:")
    own = parts[0]
    for part in parts[1:]:
        name = part.partition("\n")[0].strip()
        own += "\n" + part.partition("\nEND:" + name)[2]
    return own

def parse_props(lines, wanted):
    """Maps property names in `wanted` to (value, params) tuples.

    Properties in LIST_PROPS map to a list of every occurrence; others keep
    their first occurrence.
    """
    props = {}
    for line in lines:
        colon = line.find(":")
        if colon < 1:
            continue
        semi = line.find(";", 0, colon)
        name = (line[:semi] if semi > 0 else line[:colon]).upper()
        if name not in wanted:
            continue
        params = {}
        if semi > 0:
            if "\"" in line[semi:colon]:
                colon = unquoted_colon(line)
                if colon < 0:
                    continue
            for param in line[semi + 1:colon].split(";"):
                key, _, value = param.partition("=")
                params[key.strip().upper()] = value.strip().strip("\"")
        prop = (line[colon + 1:].strip(), params)
        if name in LIST_PROPS:
            props.setdefault(name, []).append(prop)
        elif name not in props:
            props[name] = prop
    return props

def unquoted_colon(line):
    """The index of the first colon outside a quoted parameter value, or -1."""
    position = 0
    for i, chunk in enumerate(line.split("\"")):
        if i % 2 == 0 and ":" in chunk:
            return position + chunk.find(":")
        position += len(chunk) + 1
    return -1

def unescape(text):
    """Decodes TEXT escapes (RFC 5545, 3.3.11); line breaks become spaces."""
    return "\\".join([
        part.replace("\\n", " ").replace("\\N", " ").replace("\\,", ",").replace("\\;", ";")
        for part in text.split("\\\\")
    ])

def to_int(text):
    """Parses an optionally signed integer, or returns None."""
    text = text.strip()
    digits = text.lstrip("+-")
    if not digits.isdigit() or len(text) - len(digits) > 1:
        return None
    return -int(digits) if text.startswith("-") else int(digits)
