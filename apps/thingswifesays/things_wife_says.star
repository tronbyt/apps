"""
Applet: Things Wife Says
Summary: Show phrases
Description: Enter phrases your wife says and app will cycle through them.
Author: vipulchhajer
"""

load("images/wife1.png", WIFE1_ASSET = "file")
load("images/wife2.png", WIFE2_ASSET = "file")
load("images/wife3.png", WIFE3_ASSET = "file")
load("images/wife4.png", WIFE4_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

WIFE1 = WIFE1_ASSET.readall()
WIFE2 = WIFE2_ASSET.readall()
WIFE3 = WIFE3_ASSET.readall()
WIFE4 = WIFE4_ASSET.readall()

default_phrase1 = "It's fineee"
default_phrase2 = "Is it really tho?"
default_phrase3 = "That's hella tight"
default_phrase4 = "I'm gonna sleep in"
default_phrase5 = "I'm taking a short nap mmmkay?"

#Load images

def main(config):
    PHRASES = [
        config.str("phrase1", default_phrase1),
        config.str("phrase2", default_phrase2),
        config.str("phrase3", default_phrase3),
        config.str("phrase4", default_phrase4),
        config.str("phrase5", default_phrase5),
    ]

    WIFE = None

    wifeSelect = config.str("wife-preset", 1)

    if (wifeSelect == "4"):
        WIFE = WIFE4
    elif (wifeSelect == "3"):
        WIFE = WIFE3
    elif (wifeSelect == "2"):
        WIFE = WIFE2
    else:
        WIFE = WIFE1

    random.seed(time.now().unix // 60)
    index = random.number(0, 4)
    phrase = PHRASES[index]

    return render.Root(
        child = render.Box(
            child = render.Row(
                main_align = "center",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Box(
                        color = "#333333",  #remove color background if picture is used
                        child = render.Image(src = WIFE),
                        width = 22,
                        height = 30,
                    ),
                    render.Box(
                        child = render.Marquee(
                            height = 30,
                            offset_start = 6,
                            offset_end = 6,
                            child = render.WrappedText(
                                content = phrase,
                                width = 40,
                                # color="#f44336"
                            ),
                            scroll_direction = "vertical",
                        ),
                        width = 42,
                        height = 32,
                        padding = 1,
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "phrase1",
                name = "phrase 1",
                desc = "a thing your wife says",
                icon = "faceSmile",
            ),
            schema.Text(
                id = "phrase2",
                name = "phrase 2",
                desc = "another thing your wife says",
                icon = "faceSmile",
            ),
            schema.Text(
                id = "phrase3",
                name = "phrase 3",
                desc = "third thing your wife says",
                icon = "faceSmile",
            ),
            schema.Text(
                id = "phrase4",
                name = "phrase 4",
                desc = "fourth thing your wife says",
                icon = "faceSmile",
            ),
            schema.Text(
                id = "phrase5",
                name = "phrase 5",
                desc = "fifth thing your wife says",
                icon = "faceSmile",
            ),
            schema.Text(
                id = "wife-preset",
                name = "Wife Preset (1-4)",
                desc = "Wife Preset",
                icon = "faceSmile",
            ),
        ],
    )
