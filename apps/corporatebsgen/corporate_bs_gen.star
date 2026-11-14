load("http.star", "http")
load("images/corp_icon.png", CORP_ICON_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

CORP_ICON = CORP_ICON_ASSET.readall()

CORPORATE_BS = "https://corporatebs-generator.sameerkumar.website/"

def main(config):
    # Logo can be toggled on or off and scrolling direction can be set to
    # horizontal or vertical
    SCROLL_DIRECTION = config.get("scroll_direction", "horizontal")
    SHOW_LOGO = config.bool("show_logo", False)

    # set up the display elements
    titlePadding = 0
    marqueeFont = "tb-8"
    if SHOW_LOGO:
        logoBox = render.Box(
            height = 12,
            color = "000",
            child = render.Image(src = CORP_ICON, width = 14),
        )
    else:
        logoBox = None

        # If there's no logo being shown, take advantage of the space
        if SCROLL_DIRECTION == "horizontal":
            titlePadding = 5
            marqueeFont = "6x13"

    titleBox = render.Padding(
        pad = (0, 0, 0, titlePadding),
        child = render.Box(
            height = 10,
            color = "000",
            child = render.Text("CORPORATE BS", height = 10, color = "B74830"),
        ),
    )

    # fetch the corporate BS phrase
    rep = http.get(CORPORATE_BS, ttl_seconds = 43200)
    if rep.status_code != 200:
        fail("Corporate BS request failed with status %d", rep.status_code)

    phrase = rep.json()["phrase"]

    if SCROLL_DIRECTION == "horizontal":
        return render.Root(
            child = render.Stack(
                children = [
                    render.Column(
                        children = [
                            logoBox,
                            titleBox,
                            render.Marquee(
                                child = render.Text(
                                    "%s" % phrase,
                                    color = "DAF7A6",
                                    font = marqueeFont,
                                ),
                                width = 64,
                                offset_start = 32,
                                offset_end = 32,
                            ),
                        ],
                    ),
                ],
            ),
        )
    else:
        # Switch from tb-8 to tom-thumb if there are any words with greater
        # than 12 letters
        marqueeFont = "tb-8"
        marqueeFontHeight = 8
        longestWord = max(phrase.split(), key = len)
        if len(longestWord) > 12:
            marqueeFont = "tom-thumb"
            marqueeFontHeight = 6

        # Guess at a height for the vertical marquee that doesn't leave too
        # much space between scrolls
        marqueeLines = int(math.round(len(phrase) * marqueeFontHeight / 64))
        marqueeHeight = marqueeLines * (marqueeFontHeight + 2)
        if marqueeHeight <= 22:
            marqueeHeight = 23

        return render.Root(
            delay = 100,
            child = render.Column(
                children = [
                    logoBox,
                    titleBox,
                    render.Marquee(
                        offset_start = 8,
                        offset_end = 8,
                        height = 22,
                        scroll_direction = "vertical",
                        align = "end",
                        child = render.Column(
                            main_align = "center",
                            children = [
                                render.Box(
                                    height = marqueeHeight,
                                    child = render.WrappedText(
                                        "%s" % phrase,
                                        color = "DAF7A6",
                                        align = "center",
                                        font = marqueeFont,
                                    ),
                                ),
                            ],
                        ),
                    ),
                ],
            ),
        )

# Options for scroll direction and logo toggle
def get_schema():
    scroll_direction = [
        schema.Option(display = "Horizontal", value = "horizontal"),
        schema.Option(display = "Vertical", value = "vertical"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "show_logo",
                name = "Show Logo",
                desc = "Yes/No",
                icon = "poop",
                default = True,
            ),
            schema.Dropdown(
                id = "scroll_direction",
                name = "Scroll Direction",
                desc = "Horizontal or vertical",
                default = scroll_direction[0].value,
                options = scroll_direction,
                icon = "scroll",
            ),
        ],
    )
