"""
Applet: Die Scoreboard GT
Summary: Beer Die Scoreboard for GT
Description: Beer Die scoreboard with dropdown menus to keep track of score. Customized with logos for Bizz (5) and Buzz (7) with a red solo cup and Georgia Tech's mascot Buzz.
Author: zachtempel3
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")
load("images/img_949bdcc4.png", IMG_949bdcc4_ASSET = "file")
load("images/img_3f57dab3.png", IMG_3f57dab3_ASSET = "file")
load("images/img_4122336c.png", IMG_4122336c_ASSET = "file")
load("images/img_4a66d97e.png", IMG_4a66d97e_ASSET = "file")
load("images/img_abb7c3c4.png", IMG_abb7c3c4_ASSET = "file")
load("images/img_b5c3ddf3.png", IMG_b5c3ddf3_ASSET = "file")
load("images/img_ba0899cd.png", IMG_ba0899cd_ASSET = "file")
load("images/img_c3c685c2.png", IMG_c3c685c2_ASSET = "file")
load("images/img_c952e998.png", IMG_c952e998_ASSET = "file")
load("images/img_c97ef02d.png", IMG_c97ef02d_ASSET = "file")
load("images/img_e44c3784.png", IMG_e44c3784_ASSET = "file")
load("images/img_145cd676.png", IMG_145cd676_ASSET = "file")
load("images/img_a8dbf45f.png", IMG_a8dbf45f_ASSET = "file")

NUMBER_IMGS = [
    IMG_e44c3784_ASSET.readall(),  # 0
    IMG_4122336c_ASSET.readall(),  # 1
    IMG_c3c685c2_ASSET.readall(),  # 2
    IMG_4a66d97e_ASSET.readall(),  # 3
    IMG_3f57dab3_ASSET.readall(),  # 4
    IMG_abb7c3c4_ASSET.readall(),  # bizz
    IMG_c97ef02d_ASSET.readall(),  # 6
    IMG_c952e998_ASSET.readall(),  # buzz
    IMG_b5c3ddf3_ASSET.readall(),  # 8
    IMG_ba0899cd_ASSET.readall(),  # 9
]

def render_seperator():
    return render.Box(
        width = 2,
        height = 100,
        color = "#d30",
        child = render.Image(src = IMG_949bdcc4_ASSET.readall()
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
    IMG_145cd676_ASSET.readall(),  # 5
    IMG_a8dbf45f_ASSET.readall(),  # 7
]
