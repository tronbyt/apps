"""
Applet: Gartner News
Summary: Gartner News Display
Description: Display Gartner News Feed.
Author: Robert Ison
"""

load("http.star", "http")  #HTTP Client
load("images/gartner_logo.png", GARTNER_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")  #XPath Expressions to read XML RSS Feed

GARTNER_LOGO = GARTNER_LOGO_ASSET.readall()

def main(config):
    """ Main

    Args:
        config: Configuration Items to control how the app is displayed
    Returns:
        The display inforamtion for the Tidbyt
    """
    GARTNER_RSS_URL = "https://www.gartner.com/en/newsroom/rss"

    number_of_items = 0
    seconds_xml_valid_for = 6 * 60 * 60  #6 hours

    gartner_xml = http.get(GARTNER_RSS_URL, headers = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.1", "Accept": "text/html,application/xhtml+xml,application/xml"}, ttl_seconds = seconds_xml_valid_for)

    if gartner_xml.status_code == 200:
        xml_body = gartner_xml.body()
        number_of_items = xml_body.count("<item>")
    else:
        xml_body = None
        number_of_items = 0

    if number_of_items == 0:
        return []
    else:
        display_text = ["", ""]  # number of display_text rows to display is two
        text_limit = 180
        marquee_row = 0

        for i in range(1, number_of_items + 1):
            current_query = "//item[" + str(i) + "]/title"
            current_title = xpath.loads(xml_body).query(current_query)
            current_query = "//item[" + str(i) + "]/pubDate"

            if len(display_text[marquee_row]) + len(current_title) > text_limit:
                if marquee_row < len(display_text) - 1:
                    marquee_row = marquee_row + 1
                else:
                    break

            if len(display_text[marquee_row]) == 0:
                display_text[marquee_row] = current_title
            else:
                display_text[marquee_row] = "%s - %s" % (display_text[marquee_row], current_title)

    return render.Root(
        render.Column(
            children = [
                render.Row(
                    children = [
                        render.Image(GARTNER_LOGO),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(height = 3),
                    ],
                ),
                render.Row(
                    children = [
                        render.Marquee(
                            width = 64,
                            offset_start = 5,
                            offset_end = 64,
                            child = render.Text(display_text[0], color = "#FFf000", font = "5x8"),  #display_text[0], --5x8 allows 180 (900) -- CG-pixel-3x5-mono allows 227 (681) -- CG-pixel-4x5-mono allows 180
                        ),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(height = 3),
                    ],
                ),
                render.Row(
                    children = [
                        render.Marquee(
                            width = 64,
                            offset_start = len(display_text[0]) * 5,
                            offset_end = 64,
                            child = render.Text(display_text[1], color = "#FFF000", font = "tb-8"),  #display_text[1]  --6x13 allows 152 -- Dina_r400-6 allows 152 (900)
                        ),
                    ],
                ),
            ],
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

scroll_speed_options = [
    schema.Option(
        display = "Slow Scroll",
        value = "60",
    ),
    schema.Option(
        display = "Medium Scroll",
        value = "45",
    ),
    schema.Option(
        display = "Fast Scroll",
        value = "30",
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "scroll",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
        ],
    )
