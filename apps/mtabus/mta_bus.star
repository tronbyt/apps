"""
Applet: MTA Bus
Summary: MTA bus stop tracker
Description: Track the arrival time for MTA buses.
* Requires an MTA Bus Time API key and MTA bus stop ID. You can request an API key at this URL: https://register.developer.obanyc.com/",
* You also need to set a bus stop ID. It should be a 6-digit number. Look it up at: https://bustime.mta.info/m/routes/",
Author: Kevin Eder
"""

load("animation.star", "animation")
load("http.star", "http")
load("images/bus_image_base_64.png", BUS_IMAGE_BASE_64_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BUS_IMAGE_BASE_64 = BUS_IMAGE_BASE_64_ASSET.readall()

CACHE_TTL_SECONDS = 60
BUSTIME_URL = "https://bustime.mta.info/api/siri/stop-monitoring.json?key={key}&OperatorRef=MTA&MonitoringRef={stop}"

BUS_ANIMATION_DURATION = 200

def main(config):
    is_key_set = "key" in config
    is_stop_set = "stop" in config
    bus_name = "Bus"
    response_was_error = False
    api_key = config.get("key")
    stop = config.str("stop") or ""

    visits, response_was_error = get_visits(api_key, stop)

    # Try to determine bus line name.
    if len(visits) > 0:
        visit_0 = visits[0]
        if "MonitoredVehicleJourney" in visit_0:
            journey = visit_0.get("MonitoredVehicleJourney")

            if "PublishedLineName" in journey:
                bus_name = journey.get("PublishedLineName")

    return render.Root(
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 11,
                    child = render.Text("Next {}".format(bus_name), font = "6x13"),
                ),
                render.Box(
                    width = 64,
                    height = 24,
                    child = render.Stack(
                        children = [
                            render.Column(
                                children = get_wait_time_rows(visits, is_key_set, is_stop_set, response_was_error),
                            ),
                            animation.Transformation(
                                child = render.Image(src = BUS_IMAGE_BASE_64, width = 26),
                                duration = BUS_ANIMATION_DURATION,
                                delay = 60,
                                keyframes = [
                                    animation.Keyframe(
                                        percentage = 0.0,
                                        transforms = [animation.Translate(-64, 0)],
                                    ),
                                    animation.Keyframe(
                                        percentage = 1.0,
                                        transforms = [animation.Translate(64, 0)],
                                    ),
                                ],
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def get_visits(api_key, stop):
    response = http.get(get_url(api_key, stop), ttl_seconds = CACHE_TTL_SECONDS)
    response_was_error = response.status_code != 200
    delivery = dict()

    if not response_was_error:
        delivery = response.json()["Siri"]["ServiceDelivery"]["StopMonitoringDelivery"][0]

    visits = delivery["MonitoredStopVisit"] if "MonitoredStopVisit" in delivery else []

    return visits, response_was_error

def get_url(key, stop):
    return BUSTIME_URL.format(key = key, stop = stop)

def get_wait_time_rows(visits, is_key_set, is_stop_set, response_was_error):
    result = list()

    # Check for the next bus.
    if len(visits) > 0:
        expected_arrival = get_expected_arrival(visits[0])

        if expected_arrival:
            result.append(get_minutes_row(time.parse_time(expected_arrival)))

    # Check for the bus after that.
    if len(visits) > 1:
        expected_arrival = get_expected_arrival(visits[1])

        if expected_arrival:
            result.append(get_minutes_row(time.parse_time(expected_arrival)))

    if not is_key_set:
        result.append(get_no_key_set_row())
    elif not is_stop_set:
        result.append(get_no_stop_set_row())
    elif response_was_error:
        result.append(get_api_error_row())
    elif len(result) < 1:
        result.append(get_no_visits_returned())

    return result

def get_minutes_row(arrival):
    diff = arrival - time.now()
    s = str(int(math.round(diff.minutes)))

    return render.Row(
        children = [render.Text("{} minutes".format(s), height = 9, color = "#ff9900")],
        main_align = "center",
        expanded = True,
    )

def get_no_key_set_row():
    return render.Column(
        children = [
            get_unknown_time_row(),
            get_error_text_row("No API key set."),
        ],
        main_align = "center",
        cross_align = "center",
    )

def get_no_stop_set_row():
    return render.Column(
        children = [
            get_unknown_time_row(),
            get_error_text_row("No stop set."),
        ],
        main_align = "center",
        cross_align = "center",
    )

def get_api_error_row():
    return render.Column(
        children = [
            get_unknown_time_row(),
            get_error_text_row("API error."),
        ],
        main_align = "center",
        cross_align = "center",
    )

def get_no_visits_returned():
    return render.Column(
        children = [
            get_unknown_time_row(),
            get_error_text_row("No ETA :("),
        ],
        main_align = "center",
    )

def get_error_text_row(text):
    return render.Row(
        children = [
            render.Text(
                text,
                height = 9,
                color = "#ff9900",
            ),
        ],
        expanded = True,
        main_align = "center",
        cross_align = "center",
    )

def get_unknown_time_row():
    return render.Row(
        children = [render.Text("?? minutes", height = 9, color = "#ff9900")],
        main_align = "center",
        expanded = True,
    )

def get_expected_arrival(visit):
    return visit["MonitoredVehicleJourney"]["MonitoredCall"].get("ExpectedArrivalTime", None)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "key",
                name = "MTA BusTime API Key",
                desc = "MTA BusTime Developer API Key. Request at: https://register.developer.obanyc.com/",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "stop",
                name = "MTA Bus Time Stop ID",
                desc = "Used to identify which bus stop to display. Look it up at: https://bustime.mta.info/m/routes/",
                icon = "bus",
            ),
        ],
    )
