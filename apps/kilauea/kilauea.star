"""
Applet: Kilauea
Summary: Kilauea volcano status
Description: Displays the current USGS alert level and color code for Kilauea volcano in Hawaii.
Author: Tavis
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

URL = "https://volcanoes.usgs.gov/rss/vhpcaprss.xml"

COLOR_MAP = {
    "green": "#00ff00",
    "yellow": "#ffff00",
    "orange": "#ff8800",
    "red": "#ff0000",
}

CAM_URL = "https://volcanoes.usgs.gov/cams/V3cam/images/M.jpg"

def main(_config):
    rep = http.get(URL, ttl_seconds = 300)
    if rep.status_code != 200:
        return render_error(str(rep.status_code))

    text = rep.body()
    alert_level, color_code = extract_status(text)

    if not alert_level:
        return render_error("No data")

    color_hex = COLOR_MAP.get(color_code.lower(), "#ffffff")

    cam_rep = http.get(CAM_URL, ttl_seconds = 60, headers = {"User-Agent": "Mozilla/5.0", "Referer": "https://volcanoes.usgs.gov/"})
    if cam_rep.status_code != 200:
        return render_error("Img: %d" % cam_rep.status_code)

    image = cam_rep.body()

    return render.Root(
        child = render.Stack(
            children = [
                render.Image(image, width = 64, height = 32),
                render.Padding(
                    pad = (0, 24, 0, 0),
                    child = render.Text("Kilauea", font = "tb-8", color = color_hex),
                ),
            ],
        ),
    )

def extract_status(text):
    idx = text.find("HVO Kilauea ")
    if idx == -1:
        return None, None

    start = text.find("<volcano:alertlevel>", idx) + len("<volcano:alertlevel>")
    end = text.find("<", start)
    if end <= start:
        return None, None
    alert_level = text[start:end].strip()

    color_start = text.find("<volcano:colorcode>", idx) + len("<volcano:colorcode>")
    color_end = text.find("<", color_start)
    if color_end <= color_start:
        return None, None
    color_code = text[color_start:color_end].strip()

    return alert_level, color_code

def render_error(msg):
    return render.Root(
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text("Kilauea", font = "tb-8"),
                render.Text(msg, font = "tb-8"),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
