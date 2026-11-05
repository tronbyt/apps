"""
Applet: Should I Deploy
Summary: Display shouldideploy.today
Description: Display shouldideploy.today answer.
Author: humbertogontijo
"""

load("cache.star", "cache")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")

SHOULD_I_DEPLOY_URL = "https://shouldideploy.today/api?tz="
DEFAULT_TIMEZONE = "UTC"

def is_square():
    """True on a 64x64 panel.

    Panels are told apart by SHAPE, never by size: the 128x64 wide panel is
    also 64 tall.
    """
    w, h = canvas.size()
    return h == w

def main(config):
    tz = config.get("tz", DEFAULT_TIMEZONE)
    resp_cache = cache.get("api_message")
    if resp_cache != None:
        msg_txt = resp_cache
    else:
        resp = http.get(SHOULD_I_DEPLOY_URL + tz)
        if resp.status_code != 200:
            fail("Request failed with status %d", resp.status_code)
        msg_txt = resp.json()["message"]

        cache.set("api_message", msg_txt, ttl_seconds = 120)

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.WrappedText(
                            content = "Should I Deploy Today?",
                            color = "#D2691E",
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        _render_message(msg_txt),
                    ],
                ),
            ],
        ),
    )

def _render_message(msg_txt):
    if is_square():
        # Square panel: wrap the verdict under the title instead of a one-line ticker.
        return render.Marquee(
            height = canvas.height() - 16,
            scroll_direction = "vertical",
            child = render.WrappedText(content = msg_txt, width = canvas.width(), align = "center"),
        )
    return render.Marquee(width = 60, child = render.Text(content = msg_txt))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "tz",
                name = "Timezone",
                desc = "Timezone to send with the request for shouldideploy.today.",
                icon = "businessTime",
                default = DEFAULT_TIMEZONE,
            ),
        ],
    )
