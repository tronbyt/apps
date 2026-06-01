"""
Applet: Underwater Clock
Summary: Time underwater
Description: Displays the current time in an underwater scene that changes with the time of day.
Author: asea-aranion
"""

load("encoding/json.star", "json")
load("images/fish_1.png", FISH_1_ASSET = "file")
load("images/fish_2.png", FISH_2_ASSET = "file")
load("images/fish_3.png", FISH_3_ASSET = "file")
load("images/fish_4.png", FISH_4_ASSET = "file")
load("images/scene_0.png", SCENE_0_ASSET = "file")
load("images/scene_1.png", SCENE_1_ASSET = "file")
load("images/scene_10.png", SCENE_10_ASSET = "file")
load("images/scene_11.png", SCENE_11_ASSET = "file")
load("images/scene_12.png", SCENE_12_ASSET = "file")
load("images/scene_13.png", SCENE_13_ASSET = "file")
load("images/scene_14.png", SCENE_14_ASSET = "file")
load("images/scene_15.png", SCENE_15_ASSET = "file")
load("images/scene_16.png", SCENE_16_ASSET = "file")
load("images/scene_17.png", SCENE_17_ASSET = "file")
load("images/scene_18.png", SCENE_18_ASSET = "file")
load("images/scene_19.png", SCENE_19_ASSET = "file")
load("images/scene_2.png", SCENE_2_ASSET = "file")
load("images/scene_20.png", SCENE_20_ASSET = "file")
load("images/scene_21.png", SCENE_21_ASSET = "file")
load("images/scene_22.png", SCENE_22_ASSET = "file")
load("images/scene_23.png", SCENE_23_ASSET = "file")
load("images/scene_3.png", SCENE_3_ASSET = "file")
load("images/scene_4.png", SCENE_4_ASSET = "file")
load("images/scene_5.png", SCENE_5_ASSET = "file")
load("images/scene_6.png", SCENE_6_ASSET = "file")
load("images/scene_7.png", SCENE_7_ASSET = "file")
load("images/scene_8.png", SCENE_8_ASSET = "file")
load("images/scene_9.png", SCENE_9_ASSET = "file")
load("images/seagrass_1.png", SEAGRASS_1_ASSET = "file")
load("images/seagrass_2.png", SEAGRASS_2_ASSET = "file")
load("images/seagrass_3.png", SEAGRASS_3_ASSET = "file")
load("images/shark_1.png", SHARK_1_ASSET = "file")
load("images/shark_2.png", SHARK_2_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

shark = [
    SHARK_1_ASSET.readall(),
    SHARK_2_ASSET.readall(),
]

fish = [
    FISH_1_ASSET.readall(),
    FISH_2_ASSET.readall(),
    FISH_3_ASSET.readall(),
    FISH_4_ASSET.readall(),
]

seagrass = [
    SEAGRASS_1_ASSET.readall(),
    SEAGRASS_2_ASSET.readall(),
    SEAGRASS_3_ASSET.readall(),
]

scenes = [
    SCENE_0_ASSET.readall(),
    SCENE_1_ASSET.readall(),
    SCENE_2_ASSET.readall(),
    SCENE_3_ASSET.readall(),
    SCENE_4_ASSET.readall(),
    SCENE_5_ASSET.readall(),
    SCENE_6_ASSET.readall(),
    SCENE_7_ASSET.readall(),
    SCENE_8_ASSET.readall(),
    SCENE_9_ASSET.readall(),
    SCENE_10_ASSET.readall(),
    SCENE_11_ASSET.readall(),
    SCENE_12_ASSET.readall(),
    SCENE_13_ASSET.readall(),
    SCENE_14_ASSET.readall(),
    SCENE_15_ASSET.readall(),
    SCENE_16_ASSET.readall(),
    SCENE_17_ASSET.readall(),
    SCENE_18_ASSET.readall(),
    SCENE_19_ASSET.readall(),
    SCENE_20_ASSET.readall(),
    SCENE_21_ASSET.readall(),
    SCENE_22_ASSET.readall(),
    SCENE_23_ASSET.readall(),
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
                    render.Image(seagrass[0]),
                    render.Image(seagrass[1]),
                    render.Image(seagrass[0]),
                    render.Image(seagrass[2]),
                ],
            ),
        ),
    ]

    if (show_fish):
        animations.append(
            render.Box(
                child = render.Animation(
                    children = [
                        render.Image(fish[3]),
                        render.Image(fish[0]),
                        render.Image(fish[1]),
                        render.Image(fish[2]),
                    ],
                ),
            ),
        )
        animations.append(
            render.Box(
                child = render.Animation(
                    children = [
                        render.Image(shark[0]),
                        render.Image(shark[1]),
                        render.Image(shark[1]),
                        render.Image(shark[0]),
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
        render.Image(scenes[hour_2]),
        render.Image(scenes[hour_1]),
    ]
    for _i in range(2, int(cycle_speed)):
        frames.append(render.Image(scenes[hour]))
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
