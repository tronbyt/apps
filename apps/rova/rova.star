"""
Applet: ROVA
Summary: Dutch waste collection days
Description: Next ROVA collection day per waste type, with trashcan icons.
Author: bertvm
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

API_URL = "https://www.rova.nl/api/waste-calendar/upcoming"
CACHE_TTL = 21600
TAKE = 50
DEFAULT_POSTALCODE = "8017BA"
DEFAULT_HOUSE_NUMBER = "11"
DEFAULT_TIMEZONE = "Europe/Amsterdam"
API_HEADERS = {
    "Accept": "application/json",
    "User-Agent": "Mozilla/5.0 (compatible; Tronbyt-ROVA/1.0)",
}

ROVA_GREEN = "#6BBF44"
MUTED = "#888888"
WHITE = "#FFFFFF"

# 9x12 trashcan icons (PNG).
ICON_GFT = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAkAAAAMCAYAAACwXJejAAAAO0lEQVR42mNgQAJaOQr/YZgBG3DbZPYfHRNUgKJQ1EzgPyEMVmQ7Wx+OIx64oPCxKkLHg9okgkFADAAAbJ6eI3Wj74EAAAAASUVORK5CYII=")
ICON_PMD = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAkAAAAMCAYAAACwXJejAAAAO0lEQVR42mNgQAILQ3n+wzADNvC/R+Q/OiaoAEVhgBbbf0IYrOhZlRAc/98ghcLHqggdD2qTCAYBMQAATTy53XUnq68AAAAASUVORK5CYII=")
ICON_PAPER = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAkAAAAMCAYAAACwXJejAAAAO0lEQVR42mNgQAIKsT3/YZgBGzCZ9fQ/OiaoAEWhgJ7bf0IYrEiv7QQcOx36j8LHqggdD2qTCAYBMQAAYN69jnBBSJ0AAAAASUVORK5CYII=")
ICON_REST = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAkAAAAMCAYAAACwXJejAAAAO0lEQVR42mNgQAIJCQn/YZgBG5g3b95/dExQAYpCAwOD/4QwWFFXVxccnzhxAoWPVRE6HtQmEQwCYgAAJv3HPPrrkBYAAAAASUVORK5CYII=")
ICON_GLASS = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAkAAAAMCAYAAACwXJejAAAAO0lEQVR42mNgQAJCRUX/YZgBG5Ddvfs/OiaoAEUhp6Xlf0IYrEhq8WI4Vn3zBoWPVRE6HtQmEQwCYgAA+3+2cYJIwmQAAAAASUVORK5CYII=")
ICON_TEXTILE = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAkAAAAMCAYAAACwXJejAAAAO0lEQVR42mNgQALJ+pX/YZgBG1jsd+w/OiaoAEWhobjNf0IYrKjPZS0cn036hcLHqggdD2qTCAYBMQAAf+e+qxhtglUAAAAASUVORK5CYII=")
ICON_GARDEN = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAkAAAAMCAYAAACwXJejAAAAO0lEQVR42mNgQAJeyRL/YZgBG6herPEfHRNUgKJQ1ZDnPyEMVpTdpwzHs88aofCxKkLHg9okgkFADAAAkbajz1g4KgcAAAAASUVORK5CYII=")
ICON_TREE = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAkAAAAMCAYAAACwXJejAAAAOklEQVR42mNgQAIK4cr/YZgBGzDpt/yPjgkqQFEooC34nxAGK9KrNYJjp60eKHysitDxoDaJYBAQAwAMhpKYwRDMGwAAAABJRU5ErkJggg==")
ICON_DEFAULT = base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAkAAAAMCAYAAACwXJejAAAAOklEQVR42mNgQAITJ078D8MM2MD79+//o2OCClAUenh4/CeEwYouXLgAxyCAzMeqCB0PapMIBgExAAAJgv62tucYUAAAAABJRU5ErkJggg==")

DAY_NL = {
    "Sun": "zo",
    "Mon": "ma",
    "Tue": "di",
    "Wed": "wo",
    "Thu": "do",
    "Fri": "vr",
    "Sat": "za",
}

MONTH_NL = {
    "Jan": "jan",
    "Feb": "feb",
    "Mar": "mrt",
    "Apr": "apr",
    "May": "mei",
    "Jun": "jun",
    "Jul": "jul",
    "Aug": "aug",
    "Sep": "sep",
    "Oct": "okt",
    "Nov": "nov",
    "Dec": "dec",
}

WASTE_META = {
    "GFT": {"label": "GFT", "color": "#3D9B2F", "icon": ICON_GFT},
    "PMD": {"label": "PMD", "color": "#E67A12", "icon": ICON_PMD},
    "PAP": {"label": "PAP", "color": "#2E86C8", "icon": ICON_PAPER},
    "PAPIER": {"label": "PAP", "color": "#2E86C8", "icon": ICON_PAPER},
    "LOSPAP": {"label": "PAP", "color": "#2E86C8", "icon": ICON_PAPER},
    "RST": {"label": "REST", "color": "#8A8A8A", "icon": ICON_REST},
    "RESTAFVAL": {"label": "REST", "color": "#8A8A8A", "icon": ICON_REST},
    "GLAS": {"label": "GLAS", "color": "#1AA3A3", "icon": ICON_GLASS},
    "TEXTIEL": {"label": "TEX", "color": "#8E44AD", "icon": ICON_TEXTILE},
    "SNOEIAFVAL": {"label": "SNOEI", "color": "#6B8E23", "icon": ICON_GARDEN},
    "KERSTBOOM": {"label": "BOOM", "color": "#2E7D32", "icon": ICON_TREE},
}

def main(config):
    postalcode = _normalize_postalcode(config.str("postalcode", DEFAULT_POSTALCODE))
    house_number = (config.str("housenumber", DEFAULT_HOUSE_NUMBER) or "").strip()
    addition = (config.str("addition", "") or "").strip()
    timezone = config.get("timezone") or DEFAULT_TIMEZONE

    if not postalcode or not house_number:
        return _root(_message("Set postcode", "and huisnummer"))

    pickups = _next_pickup_per_type(postalcode, house_number, addition, timezone)
    if pickups == None:
        return _root(_message("ROVA", "geen data"))
    if not pickups:
        return _root(_message("ROVA", "geen ophaaldagen"))

    is2x = canvas.is2x()
    scale = 2 if is2x else 1
    header_font = "tb-8" if is2x else "CG-pixel-3x5-mono"
    ticker_font = "tb-8" if is2x else "tom-thumb"

    ticker_children = []
    for pickup in pickups:
        ticker_children.append(_ticker_item(pickup, ticker_font, scale))

    if addition:
        address = "%s %s%s" % (postalcode, house_number, addition)
    else:
        address = "%s %s" % (postalcode, house_number)

    return _root(
        render.Column(
            expanded = True,
            main_align = "space_between",
            children = [
                render.Padding(
                    pad = (1 * scale, 1 * scale, 1 * scale, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                        children = [
                            render.Text("ROVA", font = header_font, color = ROVA_GREEN),
                            render.Text(address, font = header_font, color = WHITE),
                        ],
                    ),
                ),
                render.Padding(
                    pad = (0, 0, 0, 1 * scale),
                    child = render.Marquee(
                        width = 64 * scale,
                        height = 24 * scale,
                        offset_start = 0,
                        offset_end = 0,
                        scroll_direction = "vertical",
                        align = "start",
                        child = render.Column(children = ticker_children),
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "postalcode",
                name = "Postal code",
                desc = "Dutch postal code, for example 8017BA.",
                icon = "user",
                default = DEFAULT_POSTALCODE,
            ),
            schema.Text(
                id = "housenumber",
                name = "House number",
                desc = "House number as used on rova.nl/afvalkalender.",
                icon = "user",
                default = DEFAULT_HOUSE_NUMBER,
            ),
            schema.Text(
                id = "addition",
                name = "Addition",
                desc = "House letter or addition, if any.",
                icon = "user",
                default = "",
            ),
        ],
    )

def _next_pickup_per_type(postalcode, house_number, addition, timezone):
    res = http.get(
        API_URL,
        params = {
            "postalcode": postalcode,
            "houseNumber": house_number,
            "addition": addition,
            "take": str(TAKE),
        },
        headers = API_HEADERS,
        ttl_seconds = CACHE_TTL,
    )
    if res.status_code != 200:
        return None

    body = res.body()
    if body == None or body.strip() == "" or body.strip() == "[]":
        return []

    data = res.json()
    if type(data) != "list":
        return None

    now = time.now().in_location(timezone)
    today = _date_key(now)
    tomorrow = _date_key(now + time.parse_duration("24h"))

    seen = {}
    pickups = []
    for item in data:
        waste = item.get("wasteType") or {}
        code = (waste.get("code") or "").upper()
        date_str = item.get("date") or ""
        if not code or not date_str or code in seen:
            continue

        pickup_time = time.parse_time(date_str).in_location(timezone)
        key = _date_key(pickup_time)
        if key < today:
            continue

        seen[code] = True
        meta = WASTE_META.get(code, {
            "label": code[:4],
            "color": WHITE,
            "icon": ICON_DEFAULT,
        })
        pickups.append({
            "code": code,
            "label": meta["label"],
            "color": meta["color"],
            "icon": meta["icon"],
            "when": _format_when(key, today, tomorrow, pickup_time),
        })

    return pickups

def _ticker_item(pickup, font, scale):
    return render.Padding(
        pad = (1 * scale, 0, 1 * scale, 1 * scale),
        child = render.Row(
            cross_align = "center",
            children = [
                render.Image(src = pickup["icon"], width = 9 * scale, height = 12 * scale),
                render.Padding(
                    pad = (2 * scale, 0, 0, 0),
                    child = render.Row(
                        children = [
                            render.Text(pickup["label"], font = font, color = pickup["color"]),
                            render.Box(width = 3 * scale, height = 1),
                            render.Text(pickup["when"], font = font, color = WHITE),
                        ],
                    ),
                ),
            ],
        ),
    )

def _format_when(key, today, tomorrow, pickup_time):
    if key == today:
        return "vandaag"
    if key == tomorrow:
        return "morgen"
    day = DAY_NL.get(pickup_time.format("Mon"), pickup_time.format("Mon").lower())
    month = MONTH_NL.get(pickup_time.format("Jan"), pickup_time.format("Jan").lower())
    return "%s %s %s" % (day, pickup_time.format("2").strip(), month)

def _date_key(t):
    return t.format("2006-01-02")

def _normalize_postalcode(value):
    if value == None:
        return ""
    return value.replace(" ", "").upper()

def _message(title, subtitle):
    sub_font = "tb-8" if canvas.is2x() else "tom-thumb"
    return render.Column(
        expanded = True,
        main_align = "center",
        cross_align = "center",
        children = [
            render.Text(title, font = "tb-8", color = ROVA_GREEN),
            render.Text(subtitle, font = sub_font, color = MUTED),
        ],
    )

def _root(child):
    return render.Root(
        delay = 80,
        max_age = 3600,
        show_full_animation = True,
        child = child,
    )
