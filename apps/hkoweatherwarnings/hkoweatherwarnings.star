"""
Applet: HKO Weather Warnings
Summary: Hong Kong weather warnings
Description: Shows the weather warning(s) currently in force from the Hong Kong Observatory, with the official signal icon and the time each was issued.
Author: flynnlambrechts
"""

load("http.star", "http")
load("images/cold.png", COLD_FILE = "file")
load("images/fire_red.png", FIRE_RED_FILE = "file")
load("images/fire_yellow.png", FIRE_YELLOW_FILE = "file")
load("images/flood_nt.png", FLOOD_NT_FILE = "file")
load("images/frost.png", FROST_FILE = "file")
load("images/hot.png", HOT_FILE = "file")
load("images/landslip.png", LANDSLIP_FILE = "file")
load("images/monsoon.png", MONSOON_FILE = "file")
load("images/rain_amber.png", RAIN_AMBER_FILE = "file")
load("images/rain_black.png", RAIN_BLACK_FILE = "file")
load("images/rain_red.png", RAIN_RED_FILE = "file")
load("images/tc1.png", TC1_FILE = "file")
load("images/tc10.png", TC10_FILE = "file")
load("images/tc3.png", TC3_FILE = "file")
load("images/tc8ne.png", TC8NE_FILE = "file")
load("images/tc8nw.png", TC8NW_FILE = "file")
load("images/tc8se.png", TC8SE_FILE = "file")
load("images/tc8sw.png", TC8SW_FILE = "file")
load("images/tc9.png", TC9_FILE = "file")
load("images/thunderstorm.png", THUNDERSTORM_FILE = "file")
load("images/tsunami.png", TSUNAMI_FILE = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

WARNSUM_URL = "https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=warnsum&lang=en"

# warnsum's "code" field is the specific signal in force; this is an
# exhaustive map of every code the API can return to its official HKO icon.
ICON_FOR_CODE = {
    "WFIREY": FIRE_YELLOW_FILE.readall(),
    "WFIRER": FIRE_RED_FILE.readall(),
    "WFROST": FROST_FILE.readall(),
    "WHOT": HOT_FILE.readall(),
    "WCOLD": COLD_FILE.readall(),
    "WMSGNL": MONSOON_FILE.readall(),
    "WRAINA": RAIN_AMBER_FILE.readall(),
    "WRAINR": RAIN_RED_FILE.readall(),
    "WRAINB": RAIN_BLACK_FILE.readall(),
    "WFNTSA": FLOOD_NT_FILE.readall(),
    "WL": LANDSLIP_FILE.readall(),
    "TC1": TC1_FILE.readall(),
    "TC3": TC3_FILE.readall(),
    "TC8NE": TC8NE_FILE.readall(),
    "TC8SE": TC8SE_FILE.readall(),
    "TC8SW": TC8SW_FILE.readall(),
    "TC8NW": TC8NW_FILE.readall(),
    "TC9": TC9_FILE.readall(),
    "TC10": TC10_FILE.readall(),
    "WTMW": TSUNAMI_FILE.readall(),
    "WTS": THUNDERSTORM_FILE.readall(),
}

LABEL_FOR_CODE = {
    "WFIREY": "Fire Yellow",
    "WFIRER": "Fire Red",
    "WFROST": "Frost Alert",
    "WHOT": "Extreme Heat",
    "WCOLD": "Extreme Cold",
    "WMSGNL": "Monsoon Winds",
    "WRAINA": "Amber Rain",
    "WRAINR": "Red Rain",
    "WRAINB": "Black Rain",
    "WFNTSA": "NT Flooding",
    "WL": "Landslip",
    "TC1": "Typhoon Watch",
    "TC3": "Strong Winds",
    "TC8NE": "Gales NE",
    "TC8SE": "Gales SE",
    "TC8SW": "Gales SW",
    "TC8NW": "Gales NW",
    "TC9": "Storm Rising",
    "TC10": "Hurricane Force",
    "WTMW": "Tsunami Alert",
    "WTS": "Light- ning ",
}

WHITE = "#fff"
DIM = "#999"
GREEN = "#0c0"
BLACK_RAIN_DIM = "#555"
BLACK_RAIN_TEXT = "#000"

def main():
    scale = 2 if canvas.is2x() else 1

    resp = http.get(WARNSUM_URL, ttl_seconds = 120)

    if resp.status_code != 200:
        return []

    data = resp.json()

    # Test data to show all warnings
    # data = {
    #     "WFIREY": {"name": "Fire Danger Warning", "code": "WFIREY", "type": "Yellow", "actionCode": "ISSUE", "issueTime": "2026-06-16T08:00:00+08:00", "updateTime": "2026-06-16T08:00:00+08:00"},
    #     "WFIRER": {"name": "Fire Danger Warning", "code": "WFIRER", "type": "Red", "actionCode": "ISSUE", "issueTime": "2026-06-16T08:00:00+08:00", "updateTime": "2026-06-16T08:00:00+08:00"},
    #     "WFROST": {"name": "Frost Warning", "code": "WFROST", "actionCode": "ISSUE", "issueTime": "2026-06-16T08:00:00+08:00", "updateTime": "2026-06-16T08:00:00+08:00"},
    #     "WHOT": {"name": "Hot Weather Warning", "code": "WHOT", "actionCode": "ISSUE", "issueTime": "2026-06-16T08:00:00+08:00", "updateTime": "2026-06-16T08:00:00+08:00"},
    #     "WCOLD": {"name": "Cold Weather Warning", "code": "WCOLD", "actionCode": "ISSUE", "issueTime": "2026-06-16T08:00:00+08:00", "updateTime": "2026-06-16T08:00:00+08:00"},
    #     "WMSGNL": {"name": "Strong Monsoon Signal", "code": "WMSGNL", "actionCode": "ISSUE", "issueTime": "2026-06-16T08:00:00+08:00", "updateTime": "2026-06-16T08:00:00+08:00"},
    #     "WRAINA": {"name": "Rainstorm Warning Signal", "code": "WRAINA", "type": "Amber", "actionCode": "ISSUE", "issueTime": "2026-06-16T08:00:00+08:00", "updateTime": "2026-06-16T08:00:00+08:00"},
    #     "WRAINR": {"name": "Rainstorm Warning Signal", "code": "WRAINR", "type": "Red", "actionCode": "ISSUE", "issueTime": "2026-06-16T08:00:00+08:00", "updateTime": "2026-06-16T08:00:00+08:00"},
    #     "WRAINB": {"name": "Rainstorm Warning Signal", "code": "WRAINB", "type": "Black", "actionCode": "ISSUE", "issueTime": "2026-06-16T08:00:00+08:00", "updateTime": "2026-06-16T08:00:00+08:00"},
    #     "WFNTSA": {"name": "Flooding in the Northern New Territories", "code": "WFNTSA", "actionCode": "ISSUE", "issueTime": "2026-06-16T08:00:00+08:00", "updateTime": "2026-06-16T08:00:00+08:00"},
    #     "WL": {"name": "Landslip Warning", "code": "WL", "actionCode": "ISSUE", "issueTime": "2026-06-16T08:00:00+08:00", "updateTime": "2026-06-16T08:00:00+08:00"},
    #     "TC1": {"name": "Tropical Cyclone Warning Signal", "code": "TC1", "actionCode": "ISSUE", "issueTime": "2026-06-16T08:00:00+08:00", "updateTime": "2026-06-16T08:00:00+08:00"},
    #     "TC3": {"name": "Tropical Cyclone Warning Signal", "code": "TC3", "actionCode": "ISSUE", "issueTime": "2026-06-16T08:00:00+08:00", "updateTime": "2026-06-16T08:00:00+08:00"},
    #     "TC8NE": {"name": "Tropical Cyclone Warning Signal", "code": "TC8NE", "actionCode": "ISSUE", "issueTime": "2026-06-16T08:00:00+08:00", "updateTime": "2026-06-16T08:00:00+08:00"},
    #     "TC8SE": {"name": "Tropical Cyclone Warning Signal", "code": "TC8SE", "actionCode": "ISSUE", "issueTime": "2026-06-16T08:00:00+08:00", "updateTime": "2026-06-16T08:00:00+08:00"},
    #     "TC8SW": {"name": "Tropical Cyclone Warning Signal", "code": "TC8SW", "actionCode": "ISSUE", "issueTime": "2026-06-16T08:00:00+08:00", "updateTime": "2026-06-16T08:00:00+08:00"},
    #     "TC8NW": {"name": "Tropical Cyclone Warning Signal", "code": "TC8NW", "actionCode": "ISSUE", "issueTime": "2026-06-16T08:00:00+08:00", "updateTime": "2026-06-16T08:00:00+08:00"},
    #     "TC9": {"name": "Tropical Cyclone Warning Signal", "code": "TC9", "actionCode": "ISSUE", "issueTime": "2026-06-16T08:00:00+08:00", "updateTime": "2026-06-16T08:00:00+08:00"},
    #     "TC10": {"name": "Tropical Cyclone Warning Signal", "code": "TC10", "actionCode": "ISSUE", "issueTime": "2026-06-16T08:00:00+08:00", "updateTime": "2026-06-16T08:00:00+08:00"},
    #     "WTMW": {"name": "Tsunami Warning", "code": "WTMW", "actionCode": "ISSUE", "issueTime": "2026-06-16T08:00:00+08:00", "updateTime": "2026-06-16T08:00:00+08:00"},
    #     "WTS": {"name": "Thunderstorm Warning", "code": "WTS", "actionCode": "ISSUE", "issueTime": "2026-06-16T08:00:00+08:00", "updateTime": "2026-06-16T08:00:00+08:00"},
    # }
    warnings = [w for w in data.values() if w.get("actionCode") != "CANCEL"]

    if not warnings:
        return render.Root(child = no_warnings_frame(scale))

    frames = [warning_frame(w, scale) for w in warnings]

    return render.Root(
        delay = 2000,
        show_full_animation = True,
        child = render.Animation(children = frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )

def warning_frame(warning, scale):
    code = warning.get("code", "")
    icon_bytes = ICON_FOR_CODE.get(code)
    half_w = canvas.width() // 2
    full_h = 32 * scale
    is_black_rain = code == "WRAINB"

    time_color = BLACK_RAIN_DIM if is_black_rain else DIM
    label_color = BLACK_RAIN_TEXT if is_black_rain else WHITE

    if icon_bytes:
        icon_widget = render.Image(src = icon_bytes, width = half_w, height = full_h)
    else:
        icon_widget = render.Box(width = half_w, height = full_h)

    text_col = render.Box(
        width = half_w,
        height = full_h,
        color = WHITE if is_black_rain else None,
        child = render.Column(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = [
                render.Text(
                    content = issued_label(warning.get("issueTime")),
                    color = time_color,
                ),
                render.WrappedText(
                    content = bottom_label(warning),
                    color = label_color,
                    font = "CG-pixel-3x5-mono",
                    align = "center",
                    width = half_w,
                    linespacing = 1,
                    wordbreak = True,
                ),
            ],
        ),
    )

    row = render.Row(
        expanded = True,
        cross_align = "center",
        children = [icon_widget, text_col],
    )

    if is_black_rain:
        return render.Box(
            width = canvas.width(),
            height = full_h,
            color = WHITE,
            child = row,
        )
    return row

def bottom_label(warning):
    code = warning.get("code", "")
    name = warning.get("name", "")
    return LABEL_FOR_CODE.get(code, name.split(" ")[0] if name else "")

def issued_label(issue_time):
    if not issue_time:
        return ""
    return time.parse_time(issue_time).format("15:04")

def no_warnings_frame(scale):
    return render.Box(
        width = canvas.width(),
        height = 32 * scale,
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(
                    content = "HONG KONG",
                    font = "CG-pixel-3x5-mono" if scale == 1 else "terminus-12",
                    color = DIM,
                ),
                render.Text(
                    content = "NO WARNINGS",
                    font = "tb-8" if scale == 1 else "terminus-16",
                    color = GREEN,
                ),
                render.Text(
                    content = "IN FORCE",
                    font = "CG-pixel-3x5-mono" if scale == 1 else "terminus-12",
                    color = DIM,
                ),
            ],
        ),
    )
