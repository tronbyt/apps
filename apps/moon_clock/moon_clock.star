load("render.star", "render")
load("time.star", "time")
load("http.star", "http")
load("math.star", "math")
load("schema.star", "schema")
load("encoding/json.star", "json")
load("sunrise.star", "sunrise")

# 1. Load the files directly as modules
load("moon_clock_images/moon-01.png", IMAGE_01 = "file")
load("moon_clock_images/moon-02.png", IMAGE_02 = "file")
load("moon_clock_images/moon-03.png", IMAGE_03 = "file")
load("moon_clock_images/moon-04.png", IMAGE_04 = "file")
load("moon_clock_images/moon-05.png", IMAGE_05 = "file")
load("moon_clock_images/moon-06.png", IMAGE_06 = "file")
load("moon_clock_images/moon-07.png", IMAGE_07 = "file")
load("moon_clock_images/moon-08.png", IMAGE_08 = "file")
load("moon_clock_images/moon-09.png", IMAGE_09 = "file")
load("moon_clock_images/moon-10.png", IMAGE_10 = "file")
load("moon_clock_images/moon-11.png", IMAGE_11 = "file")
load("moon_clock_images/moon-12.png", IMAGE_12 = "file")
load("moon_clock_images/moon-13.png", IMAGE_13 = "file")
load("moon_clock_images/moon-14.png", IMAGE_14 = "file")
load("moon_clock_images/moon-15.png", IMAGE_15 = "file")
load("moon_clock_images/moon-16.png", IMAGE_16 = "file")
load("moon_clock_images/moon-17.png", IMAGE_17 = "file")
load("moon_clock_images/moon-18.png", IMAGE_18 = "file")
load("moon_clock_images/moon-19.png", IMAGE_19 = "file")
load("moon_clock_images/moon-20.png", IMAGE_20 = "file")
load("moon_clock_images/moon-21.png", IMAGE_21 = "file")
load("moon_clock_images/moon-22.png", IMAGE_22 = "file")
load("moon_clock_images/moon-23.png", IMAGE_23 = "file")
load("moon_clock_images/moon-24.png", IMAGE_24 = "file")
load("moon_clock_images/moon-25.png", IMAGE_25 = "file")
load("moon_clock_images/moon-26.png", IMAGE_26 = "file")
load("moon_clock_images/moon-27.png", IMAGE_27 = "file")
load("moon_clock_images/moon-28.png", IMAGE_28 = "file")
load("moon_clock_images/moon-29.png", IMAGE_29 = "file")
load("moon_clock_images/moon-30.png", IMAGE_30 = "file")

# 2. Store the file handles in a list
IMAGES = [
    IMAGE_01, IMAGE_02, IMAGE_03, IMAGE_04, IMAGE_05,
    IMAGE_06, IMAGE_07, IMAGE_08, IMAGE_09, IMAGE_10,
    IMAGE_11, IMAGE_12, IMAGE_13, IMAGE_14, IMAGE_15,
    IMAGE_16, IMAGE_17, IMAGE_18, IMAGE_19, IMAGE_20,
    IMAGE_21, IMAGE_22, IMAGE_23, IMAGE_24, IMAGE_25,
    IMAGE_26, IMAGE_27, IMAGE_28, IMAGE_29, IMAGE_30,
]

def get_dynamic_moon_data(now, timezone_str):
    REFERENCE_NEW_MOON = 1768776720
    LUNAR_CYCLE = 2551442.877
    diff = now.unix - REFERENCE_NEW_MOON
    phase_float = (diff % LUNAR_CYCLE) / LUNAR_CYCLE
    phase_index = int(phase_float * 30)
    illum_val = (1 - math.cos(phase_float * 2 * 3.14159)) / 2
    illumination_pct = int(illum_val * 100)
    cycles_to_new = 1.0 - phase_float
    cycles_to_full = 0.5 - phase_float
    if cycles_to_full < 0:
        cycles_to_full += 1.0
    sec_to_new = (cycles_to_new * LUNAR_CYCLE) - 43200
    sec_to_full = (cycles_to_full * LUNAR_CYCLE) - 43200
    next_new_time = (now + time.parse_duration("%ds" % int(sec_to_new))).in_location(timezone_str)
    next_full_time = (now + time.parse_duration("%ds" % int(sec_to_full))).in_location(timezone_str)
    return {
        "phase_index": phase_index,
        "illumination": illumination_pct,
        "next_new_str": next_new_time.format("01/02"),
        "next_full_str": next_full_time.format("01/02"),
    }

def main(config):
    timezone = config.get("timezone") or "America/Los_Angeles"
    now = time.now().in_location(timezone)
    lat, lng = 45.42, -122.77 
    loc_str = config.get("location")
    if loc_str:
        loc_data = json.decode(loc_str)
        lat = float(loc_data.get("lat", lat))
        lng = float(loc_data.get("lng", lng))
    s_rise = sunrise.sunrise(lat, lng, now)
    s_set = sunrise.sunset(lat, lng, now)
    is_night = now.unix < s_rise.unix or now.unix >= s_set.unix
    if is_night:
        c_time, illum_text_color, moon_overlay = "#FF0000", "#FFC107", "#00000080"
    else:
        c_time, illum_text_color, moon_overlay = "#00FF00", "#FFC107", "#00000033"
    
    data = get_dynamic_moon_data(now, timezone)
    
    # 3. Use the .readall() method on the file handle
    moon_image_bytes = IMAGES[data["phase_index"]].readall()

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
                        render.Text(content = now.format("03:04"), color = c_time, font = "6x13"),
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
                name = "Location",
                desc = "Location for sunrise/sunset and timezone",
                icon = "locationDot",
            ),
        ],
    )