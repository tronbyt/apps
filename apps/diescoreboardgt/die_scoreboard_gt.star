"""
Applet: Die Scoreboard GT
Summary: Beer Die Scoreboard for GT
Description: Beer Die scoreboard with dropdown menus to keep track of score. Customized with logos for Bizz (5) and Buzz (7) with a red solo cup and Georgia Tech's mascot Buzz.
Author: zachtempel3
"""

load("images/num_0.png", NUM_0_ASSET = "file")
load("images/num_1.png", NUM_1_ASSET = "file")
load("images/num_2.png", NUM_2_ASSET = "file")
load("images/num_3.png", NUM_3_ASSET = "file")
load("images/num_4.png", NUM_4_ASSET = "file")
load("images/num_6.png", NUM_6_ASSET = "file")
load("images/num_8.png", NUM_8_ASSET = "file")
load("images/num_9.png", NUM_9_ASSET = "file")
load("images/num_bizz.png", NUM_BIZZ_ASSET = "file")
load("images/num_buzz.png", NUM_BUZZ_ASSET = "file")
load("images/old_num_5.png", OLD_NUM_5_ASSET = "file")
load("images/old_num_7.png", OLD_NUM_7_ASSET = "file")
load("images/separator.png", SEPARATOR_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

NUMBER_IMGS = [
    NUM_0_ASSET.readall(),  # 0
    NUM_1_ASSET.readall(),  # 1
    NUM_2_ASSET.readall(),  # 2
    NUM_3_ASSET.readall(),  # 3
    NUM_4_ASSET.readall(),  # 4
    NUM_BIZZ_ASSET.readall(),  # bizz
    NUM_6_ASSET.readall(),  # 6
    NUM_BUZZ_ASSET.readall(),  # buzz
    NUM_8_ASSET.readall(),  # 8
    NUM_9_ASSET.readall(),  # 9
]

def render_seperator():
    return render.Box(
        width = 2,
        height = 100,
        color = "#d30",
        child = render.Image(src = SEPARATOR_ASSET.readall()),
    )

def get_num_image(num):
    specialNum = int(num)
    if specialNum == 5 or specialNum == 7:
        return render.Box(
            width = 32,
            height = 32,
            color = "000",
            child = render.Image(src = NUMBER_IMGS[specialNum]),
        )
    else:
        return render.Box(
            width = 13,
            height = 32,
            color = "fff",
            child = render.Image(src = NUMBER_IMGS[specialNum]),
        )

def main(config):
    firstTeamScore = "%s" % config.str("team1", "00")
    secondTeamScore = "%s" % config.str("team2", "00")

    if int(firstTeamScore) == 5 or int(firstTeamScore) == 7:
        if int(secondTeamScore) == 5 or int(secondTeamScore) == 7:
            return render.Root(
                child = render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "space_evenly",
                    children = [
                        get_num_image(firstTeamScore),
                        get_num_image(secondTeamScore),
                    ],
                ),
            )
        else:
            return render.Root(
                child = render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "space_evenly",
                    children = [
                        get_num_image(firstTeamScore),
                        render_seperator(),
                        get_num_image(secondTeamScore[0]),
                        get_num_image(secondTeamScore[-1]),
                    ],
                ),
            )

    if int(secondTeamScore) == 5 or int(secondTeamScore) == 7:
        return render.Root(
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "space_evenly",
                children = [
                    get_num_image(firstTeamScore[0]),
                    get_num_image(firstTeamScore[-1]),
                    render_seperator(),
                    get_num_image(secondTeamScore),
                ],
            ),
        )

    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "space_evenly",
            children = [
                get_num_image(firstTeamScore[0]),
                get_num_image(firstTeamScore[-1]),
                render_seperator(),
                get_num_image(secondTeamScore[0]),
                get_num_image(secondTeamScore[-1]),
            ],
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = "0",
            value = "00",
        ),
        schema.Option(
            display = "1",
            value = "01",
        ),
        schema.Option(
            display = "2",
            value = "02",
        ),
        schema.Option(
            display = "3",
            value = "03",
        ),
        schema.Option(
            display = "4",
            value = "04",
        ),
        schema.Option(
            display = "5",
            value = "05",
        ),
        schema.Option(
            display = "6",
            value = "06",
        ),
        schema.Option(
            display = "7",
            value = "07",
        ),
        schema.Option(
            display = "8",
            value = "08",
        ),
        schema.Option(
            display = "9",
            value = "09",
        ),
        schema.Option(
            display = "10",
            value = "10",
        ),
        schema.Option(
            display = "11",
            value = "11",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "team1",
                name = "Team 1 Score",
                desc = "Input Team 1 Score",
                icon = "1",
                default = "00",
                options = options,
            ),
            schema.Dropdown(
                id = "team2",
                name = "Team 2 Score",
                desc = "Input Team 2 Score",
                icon = "2",
                default = "00",
                options = options,
            ),
        ],
    )

OLD_NUMS = [
    OLD_NUM_5_ASSET.readall(),  # 5
    OLD_NUM_7_ASSET.readall(),  # 7
]
