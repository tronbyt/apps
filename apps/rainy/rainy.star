"""
Applet: Rainy?
Summary: Rain intensity ticker
Description: Two 24-hour rain-intensity bars from Open-Meteo hourly precipitation. Houston default.
Author: SamuLab
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CACHE_TTL = 300
BAR_X = 14
BAR_W = 48
BAR_H = 7
PX_PER_HOUR = 2
HOURS = 24

# gray -> cyan -> blue -> purple -> red (mm / hour)
INTENSITY = [
    (0.0, "#4B5563"),
    (0.2, "#22D3EE"),
    (1.0, "#3B82F6"),
    (2.5, "#A855F7"),
    (999.0, "#EF4444"),
]

DEFAULT_LOCATION = """{
    "lat": "29.7604",
    "lng": "-95.3698",
    "description": "Houston, TX",
    "locality": "Houston",
    "timezone": "America/Chicago"
}"""

def main(config):
    loc = _location(config)
    fc = _forecast(loc)
    if fc == None:
        return _error("No forecast")

    today = fc["today"]
    tomorrow = fc["tomorrow"]
    code = fc["code"]
    is_day = fc["is_day"]

    now = time.now().in_location(loc["timezone"])
    now_min = int(now.format("15")) * 60 + int(now.format("04"))

    # Calculate now indicator position on today's bar
    nx = BAR_X + int(now_min / 60.0 * PX_PER_HOUR)
    if nx < BAR_X:
        nx = BAR_X
    if nx > BAR_X + BAR_W - 1:
        nx = BAR_X + BAR_W - 1

    stack_children = [
        # Top banner: Dynamic weather icon + Rainy title
        render.Padding(
            pad = (1, 0, 0, 0),
            child = _header(code, is_day),
        ),
        # Today row: "TDY" + top bar
        render.Padding(
            pad = (1, 7, 0, 0),
            child = render.Text("TDY", font = "tom-thumb", color = "#9CA3AF"),
        ),
        render.Padding(
            pad = (BAR_X, 6, 0, 0),
            child = _bar(today),
        ),
        # Now indicator line on today's bar
        render.Padding(
            pad = (nx, 5, 0, 0),
            child = render.Box(width = 1, height = 9, color = "#FFFFFF"),
        ),
        # Time labels in between the two bars
        render.Padding(
            pad = (0, 14, 0, 0),
            child = _ticks(),
        ),
        # Tomorrow row: "TOM" + bottom bar
        render.Padding(
            pad = (1, 22, 0, 0),
            child = render.Text("TOM", font = "tom-thumb", color = "#9CA3AF"),
        ),
        render.Padding(
            pad = (BAR_X, 21, 0, 0),
            child = _bar(tomorrow),
        ),
    ]

    return render.Root(
        max_age = 600,
        child = render.Box(
            width = 64,
            height = 32,
            color = "#000000",
            child = render.Stack(children = stack_children),
        ),
    )

def _header(code, is_day):
    return render.Box(
        width = 62,
        height = 6,
        child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                _condition_icon(code, is_day),
                render.Text("Rainy?", font = "tom-thumb", color = "#38BDF8"),
            ],
        ),
    )

def _condition_icon(code, is_day):
    if code == None:
        code = 0
    if is_day == None:
        is_day = 1

    # Thunderstorm (WMO 95, 96, 99)
    if code in [95, 96, 99]:
        return _thunder_icon()
    # Rain / Drizzle / Showers
    elif code in [51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82]:
        return _rain_icon()
    # Snow (WMO 71, 73, 75, 77, 85, 86)
    elif code in [71, 73, 75, 77, 85, 86]:
        return _snow_icon()
    # Fog / Overcast (WMO 45, 48, 3)
    elif code in [45, 48, 3]:
        return _cloud_icon()
    # Partly cloudy (WMO 1, 2)
    elif code in [1, 2]:
        if is_day == 1:
            return _sun_cloud_icon()
        else:
            return _moon_cloud_icon()
    # Clear sky (WMO 0)
    else:
        if is_day == 1:
            return _sun_icon()
        else:
            return _moon_icon()

def _sun_icon():
    return render.Column(
        children = [
            render.Row(children = [render.Box(width = 3, height = 1, color = "#00000000"), render.Box(width = 2, height = 1, color = "#FACC15")]),
            render.Row(children = [render.Box(width = 1, height = 1, color = "#00000000"), render.Box(width = 6, height = 1, color = "#FACC15")]),
            render.Row(children = [render.Box(width = 8, height = 2, color = "#FDE047")]),
            render.Row(children = [render.Box(width = 1, height = 1, color = "#00000000"), render.Box(width = 6, height = 1, color = "#FACC15")]),
            render.Row(children = [render.Box(width = 3, height = 1, color = "#00000000"), render.Box(width = 2, height = 1, color = "#FACC15")]),
        ],
    )

def _moon_icon():
    return render.Column(
        children = [
            render.Row(children = [render.Box(width = 3, height = 1, color = "#00000000"), render.Box(width = 4, height = 1, color = "#FEF08A")]),
            render.Row(children = [render.Box(width = 2, height = 1, color = "#00000000"), render.Box(width = 3, height = 1, color = "#FEF08A"), render.Box(width = 2, height = 1, color = "#00000000"), render.Box(width = 1, height = 1, color = "#FEF08A")]),
            render.Row(children = [render.Box(width = 2, height = 1, color = "#00000000"), render.Box(width = 5, height = 1, color = "#FEF08A")]),
            render.Row(children = [render.Box(width = 3, height = 1, color = "#00000000"), render.Box(width = 4, height = 1, color = "#FEF08A")]),
            render.Row(children = [render.Box(width = 4, height = 1, color = "#00000000"), render.Box(width = 3, height = 1, color = "#FEF08A")]),
        ],
    )

def _sun_cloud_icon():
    return render.Column(
        children = [
            render.Row(children = [render.Box(width = 5, height = 1, color = "#00000000"), render.Box(width = 3, height = 1, color = "#FACC15")]),
            render.Row(children = [render.Box(width = 2, height = 1, color = "#00000000"), render.Box(width = 3, height = 1, color = "#38BDF8"), render.Box(width = 3, height = 1, color = "#FACC15")]),
            render.Row(children = [render.Box(width = 1, height = 1, color = "#00000000"), render.Box(width = 6, height = 1, color = "#7DD3FC")]),
            render.Row(children = [render.Box(width = 8, height = 2, color = "#38BDF8")]),
        ],
    )

def _moon_cloud_icon():
    return render.Column(
        children = [
            render.Row(children = [render.Box(width = 5, height = 1, color = "#00000000"), render.Box(width = 3, height = 1, color = "#FEF08A")]),
            render.Row(children = [render.Box(width = 2, height = 1, color = "#00000000"), render.Box(width = 3, height = 1, color = "#38BDF8"), render.Box(width = 3, height = 1, color = "#FEF08A")]),
            render.Row(children = [render.Box(width = 1, height = 1, color = "#00000000"), render.Box(width = 6, height = 1, color = "#7DD3FC")]),
            render.Row(children = [render.Box(width = 8, height = 2, color = "#38BDF8")]),
        ],
    )

def _cloud_icon():
    return render.Column(
        children = [
            render.Row(children = [render.Box(width = 2, height = 1, color = "#00000000"), render.Box(width = 3, height = 1, color = "#38BDF8")]),
            render.Row(children = [render.Box(width = 1, height = 1, color = "#00000000"), render.Box(width = 6, height = 1, color = "#7DD3FC")]),
            render.Row(children = [render.Box(width = 8, height = 2, color = "#38BDF8")]),
        ],
    )

def _rain_icon():
    f1 = render.Column(
        children = [
            render.Row(children = [render.Box(width = 2, height = 1, color = "#00000000"), render.Box(width = 3, height = 1, color = "#38BDF8")]),
            render.Row(children = [render.Box(width = 1, height = 1, color = "#00000000"), render.Box(width = 6, height = 1, color = "#7DD3FC")]),
            render.Row(children = [render.Box(width = 8, height = 2, color = "#38BDF8")]),
            render.Row(children = [render.Box(width = 1, height = 1, color = "#00000000"), render.Box(width = 1, height = 1, color = "#60A5FA"), render.Box(width = 3, height = 1, color = "#00000000"), render.Box(width = 1, height = 1, color = "#38BDF8")]),
        ],
    )
    f2 = render.Column(
        children = [
            render.Row(children = [render.Box(width = 2, height = 1, color = "#00000000"), render.Box(width = 3, height = 1, color = "#38BDF8")]),
            render.Row(children = [render.Box(width = 1, height = 1, color = "#00000000"), render.Box(width = 6, height = 1, color = "#7DD3FC")]),
            render.Row(children = [render.Box(width = 8, height = 2, color = "#38BDF8")]),
            render.Row(children = [render.Box(width = 3, height = 1, color = "#00000000"), render.Box(width = 1, height = 1, color = "#60A5FA"), render.Box(width = 2, height = 1, color = "#00000000"), render.Box(width = 1, height = 1, color = "#38BDF8")]),
        ],
    )
    return render.Animation(children = [f1, f2])

def _thunder_icon():
    f1 = render.Column(
        children = [
            render.Row(children = [render.Box(width = 2, height = 1, color = "#00000000"), render.Box(width = 3, height = 1, color = "#38BDF8")]),
            render.Row(children = [render.Box(width = 1, height = 1, color = "#00000000"), render.Box(width = 6, height = 1, color = "#7DD3FC")]),
            render.Row(children = [render.Box(width = 8, height = 2, color = "#38BDF8")]),
            render.Row(children = [render.Box(width = 3, height = 1, color = "#00000000"), render.Box(width = 2, height = 1, color = "#FACC15")]),
        ],
    )
    f2 = render.Column(
        children = [
            render.Row(children = [render.Box(width = 2, height = 1, color = "#00000000"), render.Box(width = 3, height = 1, color = "#FDE047")]),
            render.Row(children = [render.Box(width = 1, height = 1, color = "#00000000"), render.Box(width = 6, height = 1, color = "#7DD3FC")]),
            render.Row(children = [render.Box(width = 8, height = 2, color = "#38BDF8")]),
            render.Row(children = [render.Box(width = 2, height = 1, color = "#00000000"), render.Box(width = 3, height = 1, color = "#FACC15")]),
        ],
    )
    return render.Animation(children = [f1, f2])

def _snow_icon():
    return render.Column(
        children = [
            render.Row(children = [render.Box(width = 2, height = 1, color = "#00000000"), render.Box(width = 3, height = 1, color = "#38BDF8")]),
            render.Row(children = [render.Box(width = 1, height = 1, color = "#00000000"), render.Box(width = 6, height = 1, color = "#7DD3FC")]),
            render.Row(children = [render.Box(width = 8, height = 2, color = "#38BDF8")]),
            render.Row(children = [render.Box(width = 2, height = 1, color = "#00000000"), render.Box(width = 1, height = 1, color = "#FFFFFF"), render.Box(width = 2, height = 1, color = "#00000000"), render.Box(width = 1, height = 1, color = "#E0F2FE")]),
        ],
    )

def _bar(mm):
    segs = []
    for i in range(HOURS):
        segs.append(render.Box(width = PX_PER_HOUR, height = BAR_H, color = _color(mm[i])))
    return render.Row(children = segs)

def _ticks():
    color_tick = "#4B5563"
    color_text = "#6B7280"

    return render.Stack(
        children = [
            render.Padding(
                pad = (BAR_X, 2, 0, 0),
                child = render.Box(width = 1, height = 1, color = color_tick),
            ),
            render.Padding(
                pad = (BAR_X + 12 - 3, 0, 0, 0),
                child = render.Text("6A", font = "tom-thumb", color = color_text),
            ),
            render.Padding(
                pad = (BAR_X + 24, 2, 0, 0),
                child = render.Box(width = 1, height = 1, color = color_tick),
            ),
            render.Padding(
                pad = (BAR_X + 36 - 3, 0, 0, 0),
                child = render.Text("6P", font = "tom-thumb", color = color_text),
            ),
            render.Padding(
                pad = (BAR_X + BAR_W - 1, 2, 0, 0),
                child = render.Box(width = 1, height = 1, color = color_tick),
            ),
        ],
    )

def _color(mm):
    if mm == None or mm < 0:
        return "#23262B"
    last = INTENSITY[0][1]
    for threshold, color in INTENSITY:
        if mm <= threshold:
            return color
        last = color
    return last

def _forecast(loc):
    url = "https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&current=weather_code,is_day&hourly=precipitation&forecast_days=2&timezone=%s" % (
        str(loc["lat"]),
        str(loc["lng"]),
        loc["timezone"],
    )
    res = http.get(url, ttl_seconds = CACHE_TTL)
    if res.status_code != 200 or not res.body():
        return None
    data = res.json()
    if type(data) != "dict":
        return None

    current = data.get("current")
    code = 0
    is_day = 1
    if type(current) == "dict":
        if current.get("weather_code") != None:
            code = int(current["weather_code"])
        if current.get("is_day") != None:
            is_day = int(current["is_day"])

    hourly = data.get("hourly")
    if type(hourly) != "dict":
        return None
    times = hourly.get("time")
    precip = hourly.get("precipitation")
    if type(times) != "list" or type(precip) != "list":
        return None
    out = []
    n = len(times)
    if len(precip) < n:
        n = len(precip)
    for i in range(n):
        p = precip[i]
        mm = 0.0
        if type(p) == "int" or type(p) == "float":
            mm = float(p)
        out.append((times[i], mm))

    today, next_day = _split_days(out, loc["timezone"])
    return {
        "today": today,
        "tomorrow": next_day,
        "code": code,
        "is_day": is_day,
    }

def _split_days(hours, timezone):
    now = time.now().in_location(timezone)
    today_key = now.format("2006-01-02")
    tomorrow_key = (now + time.parse_duration("24h")).format("2006-01-02")
    today = [-1.0] * HOURS
    next_day = [-1.0] * HOURS
    for stamp, mm in hours:
        if type(stamp) != "string" or len(stamp) < 13:
            continue
        day = stamp[0:10]
        hour = int(stamp[11:13])
        if hour < 0 or hour > 23:
            continue
        if day == today_key:
            today[hour] = mm
        elif day == tomorrow_key:
            next_day[hour] = mm
    return today, next_day

def _geocode(query):
    q = ""
    for ch in query.elems():
        if ch == " ":
            q += "%20"
        elif ch == ",":
            q += "%2C"
        else:
            q += ch
    url = "https://geocoding-api.open-meteo.com/v1/search?name=%s&count=1" % q
    res = http.get(url, ttl_seconds = 86400)
    if res.status_code != 200 or not res.body():
        return None
    data = res.json()
    if type(data) != "dict":
        return None
    results = data.get("results")
    if type(results) != "list" or len(results) == 0:
        return None
    item = results[0]
    if type(item) != "dict":
        return None
    return {
        "lat": item.get("latitude"),
        "lng": item.get("longitude"),
        "tz": item.get("timezone"),
        "name": item.get("name"),
    }

def _location(config):
    lat = 29.7604
    lng = -95.3698
    label = "HOUSTON"
    tz = "America/Chicago"

    # Locality text input (geocoded automatically)
    loc_str = config.get("locality")
    if loc_str and type(loc_str) == "string" and loc_str.strip() != "":
        query = loc_str.strip()
        geo = _geocode(query)
        if geo != None:
            if geo.get("lat") != None:
                lat = float(str(geo["lat"]))
            if geo.get("lng") != None:
                lng = float(str(geo["lng"]))
            if geo.get("tz"):
                tz = str(geo["tz"])
            if geo.get("name"):
                label = str(geo["name"]).upper()

    # Timezone text input / dropdown override
    tz_ov = config.get("timezone")
    if tz_ov and type(tz_ov) == "string" and tz_ov.strip() != "":
        tz = tz_ov.strip()

    # Latitude & Longitude overrides (below timezone)
    lat_ov = config.get("lat_override")
    if lat_ov and type(lat_ov) == "string" and lat_ov.strip() != "":
        lat = float(lat_ov.strip())

    lng_ov = config.get("lng_override")
    if lng_ov and type(lng_ov) == "string" and lng_ov.strip() != "":
        lng = float(lng_ov.strip())

    # Fallback to schema.Location if provided in config
    raw_loc = config.get("location")
    if type(raw_loc) == "string" and raw_loc.startswith("{"):
        loc = json.decode(raw_loc)
        if type(loc) == "dict":
            if loc.get("lat") and not lat_ov:
                lat = float(str(loc["lat"]))
            if loc.get("lng") and not lng_ov:
                lng = float(str(loc["lng"]))
            if loc.get("timezone") and not tz_ov:
                tz = loc.get("timezone")

    return {"lat": lat, "lng": lng, "label": label if label else "HOUSTON", "timezone": tz}

def _error(msg):
    return render.Root(
        child = render.Box(
            color = "#000000",
            child = render.Column(
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text("RAINY?", font = "tom-thumb", color = "#22D3EE"),
                    render.Text(msg, font = "tom-thumb", color = "#E5E7EB"),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Search city or zip code",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "timezone",
                name = "Timezone",
                desc = "Select local timezone",
                icon = "clock",
                default = "America/Chicago",
                options = [
                    schema.Option(display = "America/Chicago (CT)", value = "America/Chicago"),
                    schema.Option(display = "America/New_York (ET)", value = "America/New_York"),
                    schema.Option(display = "America/Denver (MT)", value = "America/Denver"),
                    schema.Option(display = "America/Phoenix (MST)", value = "America/Phoenix"),
                    schema.Option(display = "America/Los_Angeles (PT)", value = "America/Los_Angeles"),
                    schema.Option(display = "America/Anchorage (AKST)", value = "America/Anchorage"),
                    schema.Option(display = "Pacific/Honolulu (HST)", value = "Pacific/Honolulu"),
                    schema.Option(display = "Europe/London (GMT/BST)", value = "Europe/London"),
                    schema.Option(display = "Europe/Paris (CET)", value = "Europe/Paris"),
                    schema.Option(display = "Asia/Tokyo (JST)", value = "Asia/Tokyo"),
                    schema.Option(display = "Asia/Dubai (GST)", value = "Asia/Dubai"),
                    schema.Option(display = "Australia/Sydney (AEST)", value = "Australia/Sydney"),
                ],
            ),
            schema.Text(
                id = "lat_override",
                name = "Latitude Override",
                desc = "Optional latitude override (e.g. 29.7604)",
                icon = "mapPin",
            ),
            schema.Text(
                id = "lng_override",
                name = "Longitude Override",
                desc = "Optional longitude override (e.g. -95.3698)",
                icon = "mapPin",
            ),
        ],
    )
