load("images/candle_image.png", CANDLE_IMAGE_ASSET = "file")
load("images/main_menorah_image.png", MAIN_MENORAH_IMAGE_ASSET = "file")
load("render.star", "render")
load("time.star", "time")

CANDLE_IMAGE = CANDLE_IMAGE_ASSET.readall()
MAIN_MENORAH_IMAGE = MAIN_MENORAH_IMAGE_ASSET.readall()

def get_hanukkah_dates(year):
    hanukkah_dates = {
        2024: "2024-12-25T00:00:00Z",
        2025: "2025-12-14T00:00:00Z",
        2026: "2026-12-04T00:00:00Z",
        2027: "2027-12-24T00:00:00Z",
        2028: "2028-12-12T00:00:00Z",
        2029: "2029-12-01T00:00:00Z",
        2030: "2030-12-20T00:00:00Z",
    }
    hanukkah_first_day = time.parse_time(hanukkah_dates[year])
    hanukkah_last_day = hanukkah_first_day + time.parse_duration("192h")
    return hanukkah_first_day, hanukkah_last_day

def main():
    tz = time.tz()
    current_time = time.now().in_location(tz)
    current_year = current_time.year

    if current_year > 2030:
        return render.Root(
            child = render.WrappedText(
                content = "This app only supports years up to 2030.",
                color = "#ff0000",
                font = "CG-pixel-4x5-mono",
            ),
        )

    hanukkah_first_day, hanukkah_last_day = get_hanukkah_dates(current_year)

    if current_time > hanukkah_last_day:
        main_child = render.WrappedText(
            content = "Hanukkah is over for %d.See you next year!" % current_year,
            color = "#0000ff",
            font = "CG-pixel-4x5-mono",
        )
    elif current_time < hanukkah_first_day:
        countdown_days = int((hanukkah_first_day - current_time).hours / 24) + 1
        if countdown_days == 1:
            main_child = render.WrappedText("Hanukkah starts tomorrow!", font = "tb-8", color = "#0000ff")
        else:
            main_child = render.WrappedText("Hanukkah starts in %d days!" % countdown_days, font = "tb-8", color = "#0000ff")
    else:
        num_candles = int((current_time - hanukkah_first_day).hours / 24) + 1
        candles = []
        offset_widths = [0, 80, 96, 112, 136, 152, 168, 184]
        for i in range(0, num_candles):
            candles.append(render.Box(width = offset_widths[i], child = render.Image(src = CANDLE_IMAGE)))
        candles.append(render.Image(src = MAIN_MENORAH_IMAGE))
        main_child = render.Stack(children = candles)

    return render.Root(child = main_child)
