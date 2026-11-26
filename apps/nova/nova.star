"""
Applet: Nova
Summary: Now playing on Nova
Description: Shows the current playing song on Nova for various stations around Australia.
Author: M0ntyP
"""

load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

CACHE_TIMEOUT = 60

NOWPLAYING_PREFIX_URL = "https://np.tritondigital.com/public/nowplaying?mountName="
NOWPLAYING_SUFFIX_URL = "&numberToFetch=1&eventType=track&request.preventCache=1687472073814"

def is_square():
    """True on a 64x64 panel.

    Panels are told apart by SHAPE, never by size: the 128x64 wide panel is
    also 64 tall.
    """
    w, h = canvas.size()
    return h == w

def main(config):
    StationSelection = config.get("station", "NOVA_919")
    NOWPLAYING_URL = NOWPLAYING_PREFIX_URL + StationSelection + NOWPLAYING_SUFFIX_URL

    feed = get_cachable_data(NOWPLAYING_URL, CACHE_TIMEOUT)
    rss = xpath.loads(feed)
    heading = rss.query_all("//nowplaying-info-list/nowplaying-info/property name")
    artist = ""
    songtitle = ""

    if len(heading) == 6:
        artist = heading[4]
    elif len(heading) == 5:
        artist = heading[3]
    songtitle = heading[2]

    return render.Root(
        delay = 100,
        show_full_animation = True,
        # The bands total 32 rows; on a square panel the column expands and
        # spreads them down the panel.
        child = render.Column(
            expanded = is_square(),
            main_align = "space_evenly",
            children = [
                render.Box(
                    width = 64,
                    height = 7,
                    padding = 0,
                    color = "#f00",
                    child = render.Text(content = "Nova", color = "#fff", font = "CG-pixel-4x5-mono", offset = 0),
                ),
                render.Box(
                    width = 64,
                    height = 8,
                    padding = 0,
                    color = "#000",
                    child = render.Text("NOW PLAYING...", color = "#fff", font = "CG-pixel-3x5-mono", offset = 0),
                ),
                render.Box(
                    width = 64,
                    height = 2,
                    padding = 0,
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(content = songtitle, color = "#42f545", font = "CG-pixel-3x5-mono"),
                ),
                render.Box(
                    width = 64,
                    height = 3,
                    padding = 0,
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(content = artist, color = "#fff", font = "CG-pixel-3x5-mono", offset = 0),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Choose the station",
                desc = "Choose the station",
                icon = "radio",
                default = StationOptions[0].value,
                options = StationOptions,
            ),
        ],
    )

def get_cachable_data(url, timeout):
    res = http.get(url = url, ttl_seconds = timeout)

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

StationOptions = [
    schema.Option(
        display = "Nova 91.9 (Adelaide)",
        value = "NOVA_919",
    ),
    schema.Option(
        display = "Nova 106.9 (Brisbane)",
        value = "NOVA_1069",
    ),
    schema.Option(
        display = "Nova 100 (Melbourne)",
        value = "NOVA_100",
    ),
    schema.Option(
        display = "Nova 93.7 (Perth)",
        value = "NOVA_937",
    ),
    schema.Option(
        display = "Nova 96.9 (Sydney)",
        value = "NOVA_969",
    ),
]
