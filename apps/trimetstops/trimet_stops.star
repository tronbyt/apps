# https://developer.trimet.org/ws_docs/arrivals2_ws.shtml

load("http.star", "http")
load("images/trimet_logo.png", TRIMET_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

TRIMET_LOGO = TRIMET_LOGO_ASSET.readall()

DEFAULT_APP_ID = "PLEASE_REGISTER_WITH_TRIMET"
DEFAULT_LOC_ID = 5103
CACHE_TIME_IN_SECONDS = 30
BUS_COLOR = "#0E4C8C"

def main(config):
    trimet_app_id = config.str("trimet_app_id", DEFAULT_APP_ID)
    loc_id = config.str("loc_id", DEFAULT_LOC_ID)
    trimet_api_url = "https://developer.trimet.org/ws/v2/arrivals?locIDs=%s&appID=%s" % (loc_id, trimet_app_id)

    trimet_data = http.get(trimet_api_url, ttl_seconds = CACHE_TIME_IN_SECONDS)
    stop_rows = []

    if trimet_data.status_code != 200:
        print("Trimet request failed with status %d" % trimet_data.status_code)
    else:
        print("Cache hit!" if (trimet_data.headers.get("Tidbyt-Cache-Status") == "HIT") else "Cache miss!")

        location_name = "%s - %s" % (trimet_data.json()["resultSet"]["location"][0]["desc"], trimet_data.json()["resultSet"]["location"][0]["dir"])

        stop_rows.append(
            render.Row(
                children = [
                    render.Marquee(
                        child = render.Text(location_name),
                        width = 64,
                        offset_start = 32,
                        offset_end = 32,
                        align = "start",
                    ),
                ],
            ),
        )

        if (len(trimet_data.json()["resultSet"]["arrival"]) > 0):
            stop_rows.append(add_stop_row(trimet_data.json()["resultSet"]["arrival"][0]))

            if (len(trimet_data.json()["resultSet"]["arrival"]) > 1):
                stop_rows.append(add_stop_row(trimet_data.json()["resultSet"]["arrival"][1]))

    return render.Root(
        child = render.Row(
            children = [
                render.Image(src = TRIMET_LOGO),
                render.Column(
                    children = stop_rows,
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                ),
            ],
        ),
    )

def add_stop_row(row):
    # trimet sends data in milliseconds since epoch, convert to seconds
    # estimated time is more accurate than scheduled time
    route = str(int(row["route"]))

    arrival_in_minutes = calculate_arrival_time_in_minutes(time.from_timestamp(int(row["estimated" if ("estimated" in row) else "scheduled"] * 0.001)))

    return render.Row(
        children = [
            render.Circle(
                color = BUS_COLOR,
                diameter = 10,
                child = render.Marquee(
                    child = render.Text(route),
                    align = "center",
                    width = 10,
                    offset_start = 32,
                    offset_end = 32,
                ),
            ),
            render.Marquee(
                child = render.Text("%s" % arrival_in_minutes),
                align = "start",
                width = 15,
                offset_start = 32,
                offset_end = 32,
            ),
        ],
        expanded = True,
        main_align = "space_around",
        cross_align = "center",
    )

def calculate_arrival_time_in_minutes(arrival):
    delta_arrival = arrival - time.now()

    if (delta_arrival.minutes < 10):
        return " %s" % int(delta_arrival.minutes)
    else:
        return "%s" % int(delta_arrival.minutes)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "trimet_app_id",
                name = "Trimet APP ID",
                desc = "Register here: https://developer.trimet.org/appid/registration/",
                icon = "user",
            ),
            schema.Text(
                id = "loc_id",
                name = "Trimet Stop ID",
                desc = "The Stop ID that you would like to track with the app.",
                icon = "user",
            ),
        ],
    )
