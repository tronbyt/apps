"""
Applet: NTS Radio
Summary: Shows live show on NTS
Description: Shows live show info for NTS Radio.
Author: M0ntyP
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/nts_image.png", NTS_IMAGE_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

NTS_IMAGE = NTS_IMAGE_ASSET.readall()

API = "https://www.nts.live/api/v2/live"

def main(config):
    SelectedChannelName = config.get("Channel", "1")

    CacheData = get_cachable_data(API, 60)
    API_JSON = json.decode(CacheData)

    Channel = int(SelectedChannelName) - 1
    NTS_DECODED = NTS_IMAGE

    BroadcastTitle = API_JSON["results"][Channel]["now"]["broadcast_title"]

    return render.Root(
        delay = 75,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 21,
                    child = render.Image(src = NTS_DECODED, width = 20, height = 20),
                ),
                render.Box(
                    width = 64,
                    height = 2,
                    padding = 0,
                ),
                render.Marquee(
                    width = 64,
                    child = render.Text(content = BroadcastTitle, color = "#fff", font = "CG-pixel-4x5-mono"),
                ),
                render.Box(
                    width = 64,
                    height = 4,
                    padding = 0,
                ),
            ],
        ),
    )

ChannelOptions = [
    schema.Option(
        display = "Channel 1",
        value = "1",
    ),
    schema.Option(
        display = "Channel 2",
        value = "2",
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "Channel",
                name = "Channel",
                desc = "Choose your channel",
                icon = "radio",
                default = ChannelOptions[0].value,
                options = ChannelOptions,
            ),
        ],
    )

def get_cachable_data(url, timeout):
    res = http.get(url = url, ttl_seconds = timeout)

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()
