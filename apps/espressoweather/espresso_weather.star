"""
Applet: Espresso Weather
Summary: Weather in espresso tones
Description: Current temperature, animated pixel-art conditions, daily high/low and precipitation chance in a warm espresso palette. Powered by Open-Meteo — works worldwide, no API key.
Author: adamlee117097
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_LOCATION = """
{
    "lat": "40.729",
    "lng": "-73.954",
    "description": "Brooklyn, NY, USA",
    "locality": "Brooklyn",
    "timezone": "America/New_York"
}
"""

GOLD = "#FFB000"
AMBER = "#8A6420"
DIM = "#5A3D08"
CLOUD = "#8C8478"
RAIN = "#5B8DB8"
SNOW_C = "#D8D8D8"
FLASH = "#FFE066"
HI_RED = "#FF4D2E"
LO_BLUE = "#4FA0E0"
COLD_BLUE = "#7EC8FF"
MOON = "#D8B45A"

PAL = {
    "y": GOLD,
    "g": CLOUD,
    "b": RAIN,
    "w": SNOW_C,
    "f": FLASH,
    "m": MOON,
    "h": "#78889B",
    "u": HI_RED,
    "v": LO_BLUE,
}

SUN = [
    ".......yy.......",
    ".......yy.......",
    "..y..........y..",
    "...y........y...",
    "......yyyy......",
    ".....yyyyyy.....",
    "....yyyyyyyy....",
    "yy..yyyyyyyy..yy",
    "yy..yyyyyyyy..yy",
    "....yyyyyyyy....",
    ".....yyyyyy.....",
    "......yyyy......",
    "...y........y...",
    "..y..........y..",
    ".......yy.......",
    ".......yy.......",
]

MOON_ICON = [
    "......mmmm......",
    "....mmmmmm......",
    "...mmmm....m....",
    "..mmm.....mmm...",
    "..mmm......m....",
    ".mmm............",
    ".mmm............",
    ".mmm............",
    ".mmm............",
    ".mmm............",
    "..mmm...........",
    "..mmmm..........",
    "...mmmmm........",
    "....mmmmmmm.....",
    "......mmmm......",
    "................",
]

CLOUD_ICON = [
    "................",
    "................",
    "......ggggg.....",
    "....ggggggg.....",
    "...ggggggggg....",
    "..ggggggggggg...",
    ".ggggggggggggg..",
    ".gggggggggggggg.",
    ".gggggggggggggg.",
    "..gggggggggggg..",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
]

PARTSUN = [
    "................",
    ".y..yy..........",
    "...yyyy.........",
    "..yyyyyy........",
    "..yyyyyy........",
    "..yyyyyy........",
    "..yyyy.ggggg....",
    "...ggggggggg....",
    "..ggggggggggg...",
    ".ggggggggggggg..",
    ".gggggggggggggg.",
    "..gggggggggggg..",
    "................",
    "................",
    "................",
    "................",
]

FOG = [
    "................",
    "................",
    "..gggggggggg....",
    "................",
    "....gggggggggg..",
    "................",
    "..gggggggggg....",
    "................",
    "....gggggggggg..",
    "................",
    "..gggggggggg....",
    "................",
    "................",
    "................",
    "................",
    "................",
]

CLOUD_TOP = [
    "......ggggg.....",
    "....ggggggg.....",
    "...ggggggggg....",
    "..ggggggggggg...",
    ".ggggggggggggg..",
    ".gggggggggggggg.",
    ".gggggggggggggg.",
    "..gggggggggggg..",
]

BOLT = [
    "......fff.......",
    ".....fff........",
    "....ffffff......",
    "......fff.......",
    ".....fff........",
    "....ff..........",
    "...f............",
    "................",
]

UP_ARROW = [
    "..u..",
    ".uuu.",
    "uuuuu",
]

DOWN_ARROW = [
    "vvvvv",
    ".vvv.",
    "..v..",
]

DROP = [
    ".b.",
    "bbb",
    "bbb",
    ".b.",
]

def bitmap(rows):
    out = []
    for row in rows:
        cells = []
        for ch in row.elems():
            if ch in PAL:
                cells.append(render.Box(width = 1, height = 1, color = PAL[ch]))
            else:
                cells.append(render.Box(width = 1, height = 1))
        out.append(render.Row(children = cells))
    return render.Column(children = out)

def falling_frames(char, cols, n_frames):
    """Cloud with single flakes drifting straight down beneath it, looping."""
    frames = []
    drop_rows = 8
    for f in range(n_frames):
        rows = list(CLOUD_TOP)
        for r in range(drop_rows):
            line = ""
            for c in range(16):
                hit = False
                for i, col in enumerate(cols):
                    if c == col and (r - f + i * 3) % drop_rows == 0:
                        hit = True
                line += char if hit else "."
            rows.append(line)
        frames.append(bitmap(rows))
    return frames

def rain_cloud():
    # blue-gray storm cloud, like the rain-cloud emoji
    return [row.replace("g", "h") for row in CLOUD_TOP]

def rain_frames():
    """Slanted 2px rain streaks under a blue-gray cloud (a la the emoji)."""
    frames = []
    drop_rows = 8
    bases = [5, 8, 11, 14]
    for f in range(drop_rows):
        rows = rain_cloud()
        for r in range(drop_rows):
            line = ""
            for c in range(16):
                hit = False
                for i, base in enumerate(bases):
                    p = (f + i * 3) % drop_rows
                    if (r == p or r == p - 1) and c == base - (r // 2):
                        hit = True
                line += "b" if hit else "."
            rows.append(line)
        frames.append(bitmap(rows))
    return frames

def storm_frames():
    frames = []
    for f in range(8):
        rows = rain_cloud()
        if f in (2, 3):  # lightning flash
            rows += BOLT
        else:
            for r in range(8):
                line = ""
                for c in range(16):
                    line += "b" if (c in (3, 11) and (r - f) % 8 < 2) else "."
                rows.append(line)
        frames.append(bitmap(rows))
    return frames

# WMO weather code -> (label, icon kind)
def describe(code, is_day):
    if code >= 95:
        return "T-STORMS", storm_frames()
    if code in (71, 73, 75, 77, 85, 86):
        return "SNOW", falling_frames("w", [2, 6, 10, 13], 8)
    if code in (56, 57, 66, 67):
        return "FRZ RAIN", rain_frames()
    if code in (51, 53, 55):
        return "DRIZZLE", rain_frames()
    if code in (61, 63, 65, 80, 81, 82):
        return "SHOWERS", rain_frames()
    if code in (45, 48):
        return "FOG", [bitmap(FOG)]
    if code == 3:
        return "CLOUDY", [bitmap(CLOUD_ICON)]
    if code == 2:
        if is_day:
            return "PARTLY CLOUDY", [bitmap(PARTSUN)]
        return "PARTLY CLOUDY", [bitmap(MOON_ICON)]
    if code == 1:
        if is_day:
            return "MOSTLY SUNNY", [bitmap(PARTSUN)]
        return "MOSTLY CLEAR", [bitmap(MOON_ICON)]
    if is_day:
        return "SUNNY", [bitmap(SUN)]
    return "CLEAR", [bitmap(MOON_ICON)]

def temp_color(t, celsius):
    cold = 0 if celsius else 32
    hot = 32 if celsius else 90
    if t <= cold:
        return COLD_BLUE
    if t >= hot:
        return HI_RED
    return GOLD

def degree_mark(color):
    return render.Padding(
        pad = (1, 2, 0, 0),
        child = render.Column(
            children = [
                render.Row(children = [
                    render.Box(width = 1, height = 1),
                    render.Box(width = 2, height = 1, color = color),
                    render.Box(width = 1, height = 1),
                ]),
                render.Row(children = [
                    render.Box(width = 1, height = 2, color = color),
                    render.Box(width = 2, height = 2),
                    render.Box(width = 1, height = 2, color = color),
                ]),
                render.Row(children = [
                    render.Box(width = 1, height = 1),
                    render.Box(width = 2, height = 1, color = color),
                    render.Box(width = 1, height = 1),
                ]),
            ],
        ),
    )

def offline(msg):
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            children = [
                render.Row(expanded = True, main_align = "center", children = [
                    render.Text(content = "WEATHER", font = "tom-thumb", color = AMBER),
                ]),
                render.Row(expanded = True, main_align = "center", children = [
                    render.Text(content = msg, font = "tom-thumb", color = DIM),
                ]),
            ],
        ),
    )

DAY_LABELS = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]

def forecast_col(label, icon_frames, temp_text, temp_col):
    return render.Column(
        cross_align = "center",
        children = [
            render.Text(content = label, font = "tom-thumb", color = AMBER),
            render.Animation(children = icon_frames),
            render.Text(content = temp_text, color = temp_col),
        ],
    )

def main(config):
    loc = json.decode(config.get("location") or DEFAULT_LOCATION)
    celsius = config.bool("celsius", False)
    unit = "celsius" if celsius else "fahrenheit"

    url = ("https://api.open-meteo.com/v1/forecast" +
           "?latitude=" + str(loc["lat"]) +
           "&longitude=" + str(loc["lng"]) +
           "&current=temperature_2m,weather_code,is_day" +
           "&daily=weather_code,temperature_2m_max&forecast_days=3" +
           "&temperature_unit=" + unit + "&timezone=auto")

    res = http.get(url, ttl_seconds = 600)
    if res.status_code != 200:
        return offline("OFFLINE")
    data = res.json()
    if "current" not in data or "daily" not in data:
        return offline("NO DATA")

    cur = data["current"]
    t = float(cur.get("temperature_2m", 0))
    temp = int(t + 0.5) if t >= 0 else int(t - 0.5)
    is_day = cur.get("is_day", 1) == 1
    now_icon = describe(int(cur.get("weather_code", 0)), is_day)[1]

    cols = [forecast_col("NOW", now_icon, str(temp) + "\u00b0", temp_color(temp, celsius))]

    daily = data["daily"]
    for i in range(len(daily["time"])):
        if len(cols) >= 3:
            break
        high = int(float(daily["temperature_2m_max"][i]) + 0.5)
        if i == 0:
            # only show today's high while it is still ahead of the current temp
            if high <= temp:
                continue
            label = "TODAY"
        else:
            day = time.parse_time(daily["time"][i] + "T12:00:00Z")
            label = DAY_LABELS[humanize.day_of_week(day)]
        day_icon = describe(int(daily["weather_code"][i]), True)[1]
        cols.append(forecast_col(label, day_icon, str(high) + "\u00b0", GOLD))

    return render.Root(
        delay = 180,
        child = render.Row(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = cols,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location to show weather for.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "celsius",
                name = "Celsius",
                desc = "Show temperatures in Celsius.",
                icon = "temperatureHalf",
                default = False,
            ),
        ],
    )
