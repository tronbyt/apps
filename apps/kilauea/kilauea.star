"""
Applet: Kilauea
Summary: USGS volcano status
Description: Displays the current USGS alert level and webcam for Kilauea volcano.
Author: Tavis
"""

load("http.star", "http")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")

URL = "https://volcanoes.usgs.gov/rss/vhpcaprss.xml"

COLOR_MAP = {
    "green": "#00ff0078",
    "yellow": "#ffff0084",
    "orange": "#ff88009d",
    "red": "#ff000080",
}

CAM_URLS = {
    "random": None,
    "v3cam": "https://volcanoes.usgs.gov/cams/V3cam/images/M.jpg",
    "v1cam": "https://volcanoes.usgs.gov/cams/V1cam/images/M.jpg",
    "v2cam": "https://volcanoes.usgs.gov/cams/V2cam/images/M.jpg",
}

LEVEL_ORDER = {
    "normal": 0,
    "advisory": 1,
    "watch": 2,
    "warning": 3,
}

LEVELS = [
    schema.Option(display = "Normal", value = "normal"),
    schema.Option(display = "Advisory", value = "advisory"),
    schema.Option(display = "Watch", value = "watch"),
    schema.Option(display = "Warning", value = "warning"),
]

def main(config):
    is_wide = hasattr(canvas, "is2x") and canvas.is2x()
    height = 64 if is_wide else 32
    text_y = 56 if is_wide else 24

    cam_id = config.get("cam", "random")
    if cam_id == "random":
        cam_keys = [k for k in CAM_URLS.keys() if k != "random"]
        cam_id = cam_keys[random.number(0, len(cam_keys) - 1)]
    cam_url = CAM_URLS.get(cam_id, CAM_URLS["v3cam"])
    min_level = config.get("min_level", "normal")
    show_label = config.bool("show_label", True)

    rep = http.get(URL, ttl_seconds = 300)
    if rep.status_code != 200:
        return render_error(str(rep.status_code))

    text = rep.body()
    alert_level, color_code = extract_status(text)

    if not alert_level:
        return render_error("No data")

    current_level = LEVEL_ORDER.get(alert_level.lower(), 0)
    threshold = LEVEL_ORDER.get(min_level, 0)
    if current_level < threshold:
        return []

    color_hex = COLOR_MAP.get(color_code.lower(), "#ffffff")

    # Crop by scaling image larger than canvas and offset to center
    scale = 2 if is_wide else 1
    img_width = 70 * scale
    img_height = 36 * scale
    img_offset_y = (img_height - height) // 2

    cam_rep = http.get(cam_url, ttl_seconds = 60, headers = {"User-Agent": "Mozilla/5.0", "Referer": "https://volcanoes.usgs.gov/"})
    if cam_rep.status_code != 200:
        return render_error("Img: %d" % cam_rep.status_code)

    image = cam_rep.body()

    return render.Root(
        child = render.Stack(
            children = [
                render.Padding(
                    pad = (0, -img_offset_y, 0, 0),
                    child = render.Image(image, width = img_width, height = img_height),
                ),
                render.Padding(
                    pad = (0, text_y, 0, 0),
                    child = render.Text("Kilauea", font = "tb-8", color = color_hex) if show_label else render.Box(),
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
        fields = [
            schema.Dropdown(
                id = "cam",
                name = "Webcam",
                desc = "Select a webcam view",
                icon = "camera",
                options = [
                    schema.Option(display = "Random", value = "random"),
                    schema.Option(display = "South (V3cam)", value = "v3cam"),
                    schema.Option(display = "West (V1cam)", value = "v1cam"),
                    schema.Option(display = "East (V2cam)", value = "v2cam"),
                ],
                default = "random",
            ),
            schema.Dropdown(
                id = "min_level",
                name = "Min Alert Level",
                desc = "Only show if alert level is at or above this",
                icon = "volcano",
                options = LEVELS,
                default = "normal",
            ),
            schema.Toggle(
                id = "show_label",
                name = "Show Label",
                desc = "Display the 'Kilauea' label on the image",
                icon = "eye",
                default = True,
            ),
        ],
    )
