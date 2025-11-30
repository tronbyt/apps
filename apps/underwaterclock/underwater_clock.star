"""
Applet: Underwater Clock
Summary: Time underwater
Description: Displays the current time in an underwater scene that changes with the time of day.
Author: asea-aranion
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/img_02f72b37.png", IMG_02f72b37_ASSET = "file")
load("images/img_19d4139e.png", IMG_19d4139e_ASSET = "file")
load("images/img_2c164df3.png", IMG_2c164df3_ASSET = "file")
load("images/img_2ff6ac15.png", IMG_2ff6ac15_ASSET = "file")
load("images/img_30d472a3.png", IMG_30d472a3_ASSET = "file")
load("images/img_3440caf9.png", IMG_3440caf9_ASSET = "file")
load("images/img_47a95a80.png", IMG_47a95a80_ASSET = "file")
load("images/img_5522c826.png", IMG_5522c826_ASSET = "file")
load("images/img_5b300e7b.png", IMG_5b300e7b_ASSET = "file")
load("images/img_5b98a2c5.png", IMG_5b98a2c5_ASSET = "file")
load("images/img_6fd1dc5f.png", IMG_6fd1dc5f_ASSET = "file")
load("images/img_754cd438.png", IMG_754cd438_ASSET = "file")
load("images/img_79447aad.png", IMG_79447aad_ASSET = "file")
load("images/img_7bca54ec.png", IMG_7bca54ec_ASSET = "file")
load("images/img_7fa88b0d.png", IMG_7fa88b0d_ASSET = "file")
load("images/img_80da381d.png", IMG_80da381d_ASSET = "file")
load("images/img_84bf8ddb.png", IMG_84bf8ddb_ASSET = "file")
load("images/img_84e49083.png", IMG_84e49083_ASSET = "file")
load("images/img_85497e0b.png", IMG_85497e0b_ASSET = "file")
load("images/img_85acd69c.png", IMG_85acd69c_ASSET = "file")
load("images/img_98f8cba3.png", IMG_98f8cba3_ASSET = "file")
load("images/img_a77422f1.png", IMG_a77422f1_ASSET = "file")
load("images/img_a987eb9c.png", IMG_a987eb9c_ASSET = "file")
load("images/img_ad417eb4.png", IMG_ad417eb4_ASSET = "file")
load("images/img_ad87fe44.png", IMG_ad87fe44_ASSET = "file")
load("images/img_b691d187.png", IMG_b691d187_ASSET = "file")
load("images/img_b6b11a8e.png", IMG_b6b11a8e_ASSET = "file")
load("images/img_b85973fc.png", IMG_b85973fc_ASSET = "file")
load("images/img_cfb91d58.png", IMG_cfb91d58_ASSET = "file")
load("images/img_d409368d.png", IMG_d409368d_ASSET = "file")
load("images/img_edfa2de3.png", IMG_edfa2de3_ASSET = "file")
load("images/img_f1b40477.png", IMG_f1b40477_ASSET = "file")
load("images/img_f5b54992.png", IMG_f5b54992_ASSET = "file")

shark = [
    IMG_85acd69c_ASSET.readall(),
    IMG_3440caf9_ASSET.readall(),
]

fish = [
    IMG_d409368d_ASSET.readall(),
    IMG_a987eb9c_ASSET.readall(),
    IMG_79447aad_ASSET.readall(),
    IMG_98f8cba3_ASSET.readall(),
]

seagrass = [
    IMG_754cd438_ASSET.readall(),
    IMG_b6b11a8e_ASSET.readall(),
    IMG_5b300e7b_ASSET.readall(),
]

scenes = [
    IMG_7fa88b0d_ASSET.readall(),
    IMG_30d472a3_ASSET.readall(),
    IMG_85497e0b_ASSET.readall(),
    IMG_ad417eb4_ASSET.readall(),
    IMG_ad87fe44_ASSET.readall(),
    IMG_5b98a2c5_ASSET.readall(),
    IMG_19d4139e_ASSET.readall(),
    IMG_2c164df3_ASSET.readall(),
    IMG_84e49083_ASSET.readall(),
    IMG_7bca54ec_ASSET.readall(),
    IMG_2ff6ac15_ASSET.readall(),
    IMG_b85973fc_ASSET.readall(),
    IMG_6fd1dc5f_ASSET.readall(),
    IMG_02f72b37_ASSET.readall(),
    IMG_b691d187_ASSET.readall(),
    IMG_edfa2de3_ASSET.readall(),
    IMG_5522c826_ASSET.readall(),
    IMG_84bf8ddb_ASSET.readall(),
    IMG_a77422f1_ASSET.readall(),
    IMG_cfb91d58_ASSET.readall(),
    IMG_f5b54992_ASSET.readall(),
    IMG_f1b40477_ASSET.readall(),
    IMG_80da381d_ASSET.readall(),
    IMG_47a95a80_ASSET.readall(),
]

default_location = {
    "lat": 40.678,
    "lng": -73.944,
    "locality": "Brooklyn, New York",
    "timezone": "America/New_York",
}

def main(config):
    location = config.get("location")
    dec_location = json.decode(location) if location else default_location
    time_now = time.now().in_location(dec_location.get("timezone"))
    hour = int(time_now.format("15"))

    hour_2 = int(math.mod(hour - 2, 23))
    hour_1 = int(math.mod(hour - 1, 23))

    speed = float(config.get("speed", "15"))

    use_24hour = config.bool("24hour", False)
    time_format_colon = "3:04 PM"
    time_format_blank = "3 04 PM"
    if (use_24hour):
        time_format_colon = "15:04"
        time_format_blank = "15 04"

    show_fish = config.bool("showFish", True)

    animations = [
        render.Box(
            child = render.Animation(
                children = get_frames(hour_2, hour_1, hour, speed),
            ),
        ),
        render.Box(
            child = render.Animation(
                children = [
                    render.Text(content = time_now.format(time_format_colon), font = "Dina_r400-6"),
                    render.Text(content = time_now.format(time_format_blank), font = "Dina_r400-6"),
                ],
            ),
        ),
        render.Box(
            child = render.Animation(
                children = [
                    render.Image(base64.decode(seagrass[0])),
                    render.Image(base64.decode(seagrass[1])),
                    render.Image(base64.decode(seagrass[0])),
                    render.Image(base64.decode(seagrass[2])),
                ],
            ),
        ),
    ]

    if (show_fish):
        animations.append(
            render.Box(
                child = render.Animation(
                    children = [
                        render.Image(base64.decode(fish[3])),
                        render.Image(base64.decode(fish[0])),
                        render.Image(base64.decode(fish[1])),
                        render.Image(base64.decode(fish[2])),
                    ],
                ),
            ),
        )
        animations.append(
            render.Box(
                child = render.Animation(
                    children = [
                        render.Image(base64.decode(shark[0])),
                        render.Image(base64.decode(shark[1])),
                        render.Image(base64.decode(shark[1])),
                        render.Image(base64.decode(shark[0])),
                    ],
                ),
            ),
        )

    return render.Root(
        delay = 1000,
        child = render.Stack(
            children = animations,
        ),
    )

def get_frames(hour_2, hour_1, hour, cycle_speed):
    frames = [
        render.Image(base64.decode(scenes[hour_2])),
        render.Image(base64.decode(scenes[hour_1])),
    ]
    for _i in range(2, int(cycle_speed)):
        frames.append(render.Image(base64.decode(scenes[hour])))
    return frames

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                icon = "locationDot",
                desc = "Determines timezone for clock and scene day/night cycle.",
            ),
            schema.Toggle(
                id = "24hour",
                name = "24 Hour Time",
                icon = "clock",
                desc = "Choose whether to display 12-hour time (off) or 24-hour time (on).",
                default = False,
            ),
            schema.Toggle(
                id = "showFish",
                name = "Show Fish",
                icon = "fish",
                desc = "Choose whether to display animated fish or not.",
                default = True,
            ),
            schema.Dropdown(
                id = "speed",
                name = "App Cycle Speed",
                icon = "stopwatch",
                desc = "Determines duration of final scene.",
                default = "15",
                options = [
                    schema.Option(
                        display = "15 sec",
                        value = "15",
                    ),
                    schema.Option(
                        display = "10 sec",
                        value = "10",
                    ),
                    schema.Option(
                        display = "7.5 sec",
                        value = "7.5",
                    ),
                    schema.Option(
                        display = "5 sec",
                        value = "5",
                    ),
                ],
            ),
        ],
    )
