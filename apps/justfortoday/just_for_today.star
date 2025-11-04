"""
Applet: Just For Today
Summary: Today's "Just for Today"
Description: Show today's N.A. "Just for Today".
Author: elliotstoner
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

JFT_HEADER = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAHCAYAAAC4NEsKAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAnklEQVQ4jd1VQQ7AIAgry/7/ZXYZSYMg4G7rRedobZVEAaAAoKoQEXRR1U/1PNfQ0fiy13XEKmCGOMgEFuY0VAX2tRwA//Rz+/ZjBg7A/IlGxq/WIn2bs69WB3ji7oayjUVk6Ypup0R8Xovqurg6NxCZ5019LY+Vbrf2FOY76+zbCthM1FbeqOd1THiNaQjmRz4z78YJc+B9Bf6M3eE/k3mm7Mey7SMAAAAASUVORK5CYII=
""")

JFT_SOURCE = "na-just-for-today"
FILE_TYPE = ".txt"
DEFAULT_TEXT = "God, grant me the serenity to accept the things I cannot change, the courage to change the things I can, and the wisdom to know the difference."

def getCurrentDate(config):
    timezone = config.get("timezone") or "America/New_York"
    now = time.now().in_location(timezone)
    return now.format("01-02")

def getJftText(config):
    curr_date = getCurrentDate(config)
    jft_text = cache.get(curr_date)
    if jft_text == None:
        root_url = config.get("JFT_DATA_ROOT_URL")
        if root_url == None:
            return DEFAULT_TEXT
        req_url = "%s/%s/%s%s" % (
            root_url,
            JFT_SOURCE,
            curr_date,
            FILE_TYPE,
        )
        request = http.get(req_url)
        if (request.status_code != 200):
            return DEFAULT_TEXT
        jft_text = request.body()
        cache.set(curr_date, jft_text, ttl_seconds = 86400)
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
