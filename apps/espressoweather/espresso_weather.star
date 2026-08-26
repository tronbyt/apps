"""
Applet: Espresso Weather
Summary: Weather in espresso tones
Description: Current temperature, animated pixel-art conditions, daily high/low and precipitation chance in a warm espresso palette. Powered by Open-Meteo — works worldwide, no API key.
Author: adamlee117097
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

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
MOON = "#D8B45A"

PAL = {
    "y": GOLD,
    "g": CLOUD,
    "b": RAIN,
    "w": SNOW_C,
    "f": FLASH,
    "m": MOON,
    "u": "#C8860A",
    "v": DIM,
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
    """Cloud with 2px precipitation streaks falling beneath it, looping."""
    frames = []
    drop_rows = 8
    for f in range(n_frames):
        rows = list(CLOUD_TOP)
        for r in range(drop_rows):
            line = ""
            for c in range(16):
                hit = False
                for i, col in enumerate(cols):
                    if c == col and (r - f + i * 3) % drop_rows < 2:
                        hit = True
                line += char if hit else "."
            rows.append(line)
        frames.append(bitmap(rows))
    return frames

def storm_frames():
    frames = []
    for f in range(8):
        rows = list(CLOUD_TOP)
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
        return "FRZ RAIN", falling_frames("b", [2, 6, 10, 13], 8)
    if code in (51, 53, 55):
        return "DRIZZLE", falling_frames("b", [2, 6, 10, 13], 8)
    if code in (61, 63, 65, 80, 81, 82):
        return "SHOWERS", falling_frames("b", [2, 6, 10, 13], 8)
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

def degree_mark():
    return render.Padding(
        pad = (1, 2, 0, 0),
        child = render.Column(
            children = [
                render.Row(children = [
                    render.Box(width = 1, height = 1),
                    render.Box(width = 2, height = 1, color = GOLD),
                    render.Box(width = 1, height = 1),
                ]),
                render.Row(children = [
                    render.Box(width = 1, height = 2, color = GOLD),
                    render.Box(width = 2, height = 2),
                    render.Box(width = 1, height = 2, color = GOLD),
                ]),
                render.Row(children = [
                    render.Box(width = 1, height = 1),
                    render.Box(width = 2, height = 1, color = GOLD),
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

def main(config):
    loc = json.decode(config.get("location") or DEFAULT_LOCATION)
    unit = "celsius" if config.bool("celsius", False) else "fahrenheit"

    url = ("https://api.open-meteo.com/v1/forecast" +
           "?latitude=" + str(loc["lat"]) +
           "&longitude=" + str(loc["lng"]) +
           "&current=temperature_2m,weather_code,is_day" +
           "&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max" +
           "&hourly=precipitation_probability&forecast_hours=6&forecast_days=1" +
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
    label, icon_frames = describe(int(cur.get("weather_code", 0)), is_day)

    daily = data["daily"]
    hi = int(float(daily["temperature_2m_max"][0]) + 0.5)
    lo = int(float(daily["temperature_2m_min"][0]) + 0.5)

    pop = int(daily.get("precipitation_probability_max", [0])[0] or 0)
    for p in data.get("hourly", {}).get("precipitation_probability", [])[:6]:
        if p != None and int(p) > pop:
            pop = int(p)

    top = render.Box(
        height = 20,
        child = render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Padding(
                    pad = (0, 1, 3, 0),
                    child = render.Animation(children = icon_frames),
                ),
                render.Text(content = str(temp), font = "10x20", color = GOLD),
                degree_mark(),
            ],
        ),
    )

    label_row = render.Box(
        height = 6,
        child = render.Text(content = label, font = "tom-thumb", color = AMBER),
    )

    divider = render.Box(width = 64, height = 1, color = "#33220A")

    footer = render.Box(
        height = 5,
        child = render.Padding(
            pad = (2, 0, 2, 0),
            child = render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Row(
                        children = [
                            render.Padding(pad = (0, 1, 1, 0), child = bitmap(UP_ARROW)),
                            render.Text(content = str(hi), font = "tom-thumb", color = AMBER),
                            render.Box(width = 4, height = 1),
                            render.Padding(pad = (0, 1, 1, 0), child = bitmap(DOWN_ARROW)),
                            render.Text(content = str(lo), font = "tom-thumb", color = DIM),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Padding(pad = (0, 0, 1, 0), child = bitmap(DROP)),
                            render.Text(content = str(pop) + "%", font = "tom-thumb", color = RAIN if pop >= 30 else DIM),
                        ],
                    ),
                ],
            ),
        ),
    )

    return render.Root(
        delay = 180,
        child = render.Column(
            children = [top, label_row, divider, footer],
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
