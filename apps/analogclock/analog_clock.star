"""
Applet: Analog Clock
Summary: Shows a simple analog clock
Description: Shows a simple analog clock with month and day.
Author: Chris Jones (@IPv6Freely)
"""

load("encoding/json.star", "json")
load("images/hour_hand_1.png", HOUR_HAND_1_4137fc94_ASSET = "file")
load("images/hour_hand_10.png", HOUR_HAND_10_7d37aead_ASSET = "file")
load("images/hour_hand_11.png", HOUR_HAND_11_4ba7b21f_ASSET = "file")
load("images/hour_hand_12.png", HOUR_HAND_12_4c66af06_ASSET = "file")
load("images/hour_hand_2.png", HOUR_HAND_2_bc33df1e_ASSET = "file")
load("images/hour_hand_3.png", HOUR_HAND_3_0b76c5bc_ASSET = "file")
load("images/hour_hand_4.png", HOUR_HAND_4_d02f8ea9_ASSET = "file")
load("images/hour_hand_5.png", HOUR_HAND_5_9cddedc8_ASSET = "file")
load("images/hour_hand_6.png", HOUR_HAND_6_6345169d_ASSET = "file")
load("images/hour_hand_7.png", HOUR_HAND_7_6e5d182a_ASSET = "file")
load("images/hour_hand_8.png", HOUR_HAND_8_7ddec0a3_ASSET = "file")
load("images/hour_hand_9.png", HOUR_HAND_9_0c8895d3_ASSET = "file")
load("images/minute_hand_0.png", MINUTE_HAND_0_db41c79c_ASSET = "file")
load("images/minute_hand_10.png", MINUTE_HAND_10_ebbc8642_ASSET = "file")
load("images/minute_hand_15.png", MINUTE_HAND_15_0e24306c_ASSET = "file")
load("images/minute_hand_20.png", MINUTE_HAND_20_c29ed110_ASSET = "file")
load("images/minute_hand_25.png", MINUTE_HAND_25_cda3a3fb_ASSET = "file")
load("images/minute_hand_30.png", MINUTE_HAND_30_8352c7ac_ASSET = "file")
load("images/minute_hand_35.png", MINUTE_HAND_35_644c2d16_ASSET = "file")
load("images/minute_hand_40.png", MINUTE_HAND_40_e63414b5_ASSET = "file")
load("images/minute_hand_45.png", MINUTE_HAND_45_59fffc6d_ASSET = "file")
load("images/minute_hand_5.png", MINUTE_HAND_5_1604226e_ASSET = "file")
load("images/minute_hand_50.png", MINUTE_HAND_50_5a97b2b8_ASSET = "file")
load("images/minute_hand_55.png", MINUTE_HAND_55_291c2906_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

MINUTE_HANDS = {
    0: MINUTE_HAND_0_db41c79c_ASSET.readall(),
    5: MINUTE_HAND_5_1604226e_ASSET.readall(),
    10: MINUTE_HAND_10_ebbc8642_ASSET.readall(),
    15: MINUTE_HAND_15_0e24306c_ASSET.readall(),
    20: MINUTE_HAND_20_c29ed110_ASSET.readall(),
    25: MINUTE_HAND_25_cda3a3fb_ASSET.readall(),
    30: MINUTE_HAND_30_8352c7ac_ASSET.readall(),
    35: MINUTE_HAND_35_644c2d16_ASSET.readall(),
    40: MINUTE_HAND_40_e63414b5_ASSET.readall(),
    45: MINUTE_HAND_45_59fffc6d_ASSET.readall(),
    50: MINUTE_HAND_50_5a97b2b8_ASSET.readall(),
    55: MINUTE_HAND_55_291c2906_ASSET.readall(),
}

HOUR_HANDS = {
    1: HOUR_HAND_1_4137fc94_ASSET.readall(),
    2: HOUR_HAND_2_bc33df1e_ASSET.readall(),
    3: HOUR_HAND_3_0b76c5bc_ASSET.readall(),
    4: HOUR_HAND_4_d02f8ea9_ASSET.readall(),
    5: HOUR_HAND_5_9cddedc8_ASSET.readall(),
    6: HOUR_HAND_6_6345169d_ASSET.readall(),
    7: HOUR_HAND_7_6e5d182a_ASSET.readall(),
    8: HOUR_HAND_8_7ddec0a3_ASSET.readall(),
    9: HOUR_HAND_9_0c8895d3_ASSET.readall(),
    10: HOUR_HAND_10_7d37aead_ASSET.readall(),
    11: HOUR_HAND_11_4ba7b21f_ASSET.readall(),
    12: HOUR_HAND_12_4c66af06_ASSET.readall(),
}

DEFAULT_LOCATION = {
    "lat": 34.0522,
    "lng": -118.2437,
    "locality": "Los Angeles",
    "timezone": "US/Pacific",
}

def get_hour_hand(hour):
    return render.Box(
        width = 30,
        height = 30,
        child = render.Image(src = HOUR_HANDS[hour]),
    )

def get_minute_hand(rounded_minute):
    return render.Box(
        width = 30,
        height = 30,
        child = render.Image(src = MINUTE_HANDS[rounded_minute]),
    )

def main(config):
    location = config.get("location")
    loc = json.decode(location) if location else json.decode(str(DEFAULT_LOCATION))
    timezone = loc["timezone"]
    now = time.now().in_location(timezone)

    hour = int(now.format("3"))
    rounded_minute = (now.minute + 2) % 60 // 5 * 5
    day = now.day
    month = now.format("Jan").upper()

    return render.Root(
        max_age = 120,
        child = render.Row(
            main_align = "center",
            cross_align = "center",
            children = [
                render.Box(
                    width = 32,
                    height = 32,
                    color = "#000",
                    child = render.Stack(
                        children = [
                            render.Circle(diameter = 30, color = "#fff"),
                            get_minute_hand(rounded_minute),
                            get_hour_hand(hour),
                        ],
                    ),
                ),
                render.Box(
                    width = 32,
                    height = 30,
                    color = "#000",
                    child = render.Column(
                        children = [
                            render.Box(
                                width = 28,
                                height = 8,
                                color = "#990000",
                                child = render.Text(str(month)),
                            ),
                            render.Box(
                                width = 28,
                                height = 18,
                                color = "#FFF",
                                child = render.Text(str(day), color = "#000", font = "6x13"),
                            ),
                        ],
                    ),
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
                icon = "locationDot",
                desc = "Location for which to display time",
            ),
        ],
    )
