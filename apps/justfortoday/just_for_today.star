"""
Applet: Just For Today
Summary: Today's "Just for Today"
Description: Show today's N.A. "Just for Today".
Author: elliotstoner
"""

load("http.star", "http")
load("images/jft_header.png", JFT_HEADER_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

JFT_HEADER = JFT_HEADER_ASSET.readall()

JFT_SOURCE = "na-just-for-today"
FILE_TYPE = ".txt"
DEFAULT_TEXT = "God, grant me the serenity to accept the things I cannot change, the courage to change the things I can, and the wisdom to know the difference."

def getCurrentDate(config):
    timezone = config.get("timezone") or "America/New_York"
    now = time.now().in_location(timezone)
    return now.format("01-02")

def getJftText(config):
    curr_date = getCurrentDate(config)

    root_url = config.get("JFT_DATA_ROOT_URL")
    if root_url == None:
        return DEFAULT_TEXT
    req_url = "%s/%s/%s%s" % (
        root_url,
        JFT_SOURCE,
        curr_date,
        FILE_TYPE,
    )
    request = http.get(req_url, ttl_seconds = 86400)
    if (request.status_code != 200):
        return DEFAULT_TEXT
    jft_text = request.body()

    return jft_text

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "JFT_DATA_ROOT_URL",
                name = "JFT Data Root URL",
                desc = "The root URL for the JFT data.",
                icon = "link",
            ),
        ],
    )

def main(config):
    jft_text = getJftText(config)
    return render.Root(
        delay = 90,
        show_full_animation = True,
        child = render.Marquee(
            height = 32,
            scroll_direction = "vertical",
            offset_start = 32,
            child = render.Column(
                children = [
                    render.Image(
                        src = JFT_HEADER,
                    ),
                    render.WrappedText(
                        content = jft_text,
                        width = 64,
                        font = "tb-8",
                    ),
                ],
            ),
        ),
    )
