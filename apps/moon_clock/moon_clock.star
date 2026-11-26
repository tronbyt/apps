load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("moon_assets.star", "get_moon_image")
load("render.star", "render")
load("schema.star", "schema")
load("sunrise.star", "sunrise")
load("time.star", "time")

def get_dynamic_moon_data(now, timezone_str, day_first):
    REFERENCE_NEW_MOON = 1704974220
    LUNAR_CYCLE = 2551442.877
    diff = now.unix - REFERENCE_NEW_MOON
    phase_float = (diff % LUNAR_CYCLE) / LUNAR_CYCLE
    phase_index = int(phase_float * 30)

    illum_val = (1 - math.cos(phase_float * 2 * math.pi)) / 2
    illumination_pct = int(illum_val * 100)

    cycles_to_new = 1.0 - phase_float
    cycles_to_full = 0.5 - phase_float
    if cycles_to_full < 0:
        cycles_to_full += 1.0

    sec_to_new = (cycles_to_new * LUNAR_CYCLE)
    sec_to_full = (cycles_to_full * LUNAR_CYCLE)

    next_new_time = (now + time.parse_duration("%ds" % int(sec_to_new))).in_location(timezone_str)
    next_full_time = (now + time.parse_duration("%ds" % int(sec_to_full))).in_location(timezone_str)

    # Handle Date Ordering
    date_format = "02/01" if day_first else "01/02"

    return {
        "phase_index": phase_index,
        "illumination": illumination_pct,
        "next_new_str": next_new_time.format(date_format),
        "next_full_str": next_full_time.format(date_format),
    }

def main(config):
    # 1. Defaults (Tigard, Oregon)
    lat, lng = 45.42, -122.77
    timezone = "America/Los_Angeles"

    loc_str = config.get("location")
    if loc_str:
        loc_data = json.decode(loc_str)
        lat = float(loc_data.get("lat", lat))
        lng = float(loc_data.get("lng", lng))
        timezone = loc_data.get("timezone", timezone)
    else:
        res = http.get("http://ip-api.com/json/", ttl_seconds = 86400)
        if res.status_code == 200:
            ip_data = res.json()
            if ip_data.get("status") == "success":
                lat = ip_data.get("lat", lat)
                lng = ip_data.get("lon", lng)
                timezone = ip_data.get("timezone", timezone)

    # 2. Preferences & Checks
    is_military = config.bool("military_time", False)
    day_first = config.bool("date_format_day_first", False)
    time_format = "15:04" if is_military else "03:04"

    # 3. Final Time Calculation
    now = time.now().in_location(timezone)

    s_rise = sunrise.sunrise(lat, lng, now)
    s_set = sunrise.sunset(lat, lng, now)
    is_night = now.unix < s_rise.unix or now.unix >= s_set.unix

    if is_night:
        c_time, illum_text_color, moon_overlay = "#FF0000", "#FFC107", "#00000080"
    else:
        c_time, illum_text_color, moon_overlay = "#00FF00", "#FFC107", "#00000033"

    data = get_dynamic_moon_data(now, timezone, day_first)

    # Southern Hemisphere adjustment
    current_phase = data["phase_index"]
    if lat < 0:
        current_phase = (30 - current_phase) % 30

    moon_image_bytes = get_moon_image(current_phase)

    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "start",
            cross_align = "center",
            children = [
                render.Stack(
                    children = [
                        render.Image(src = moon_image_bytes, width = 32, height = 32),
                        render.Box(width = 32, height = 32, color = moon_overlay),
                        render.Box(
                            width = 32,
                            height = 32,
                            child = render.Column(
                                expanded = True,
                                main_align = "center",
                                cross_align = "center",
                                children = [
                                    render.Text(
                                        content = str(data["illumination"]) + "%",
                                        color = illum_text_color,
                                        font = "6x13",
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
                render.Box(width = 1, height = 1),
                render.Column(
                    main_align = "center",
                    cross_align = "end",
                    expanded = True,
                    children = [
                        render.Text(content = now.format(time_format), color = c_time, font = "6x13"),
                        render.Box(width = 1, height = 2),
                        render.Row(
                            main_align = "end",
                            expanded = True,
                            children = [
                                render.Text(content = "F:", color = "#FFA500", font = "tb-8"),
                                render.Text(content = data["next_full_str"], color = "#00CCFF", font = "tb-8"),
                            ],
                        ),
                        render.Row(
                            main_align = "end",
                            expanded = True,
                            children = [
                                render.Text(content = "N:", color = "#FFA500", font = "tb-8"),
                                render.Text(content = data["next_new_str"], color = "#00CCFF", font = "tb-8"),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Manual Location Override",
                desc = "Overrides automatic IP detection",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "military_time",
                name = "Military Time",
                desc = "Display time in 24-hour format.",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = "date_format_day_first",
                name = "Date Format",
                desc = "ON for Day/Month (31/05), OFF for Month/Day (05/31).",
                icon = "calendarDay",
                default = False,
            ),
        ],
    )
