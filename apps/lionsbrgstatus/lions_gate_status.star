load("encoding/base64.star", "base64")
load("http.star", "http")
load("images/lane_back.png", LANE_BACK_ASSET = "file")
load("images/lane_closed.png", LANE_CLOSED_ASSET = "file")
load("images/lane_forward.png", LANE_FORWARD_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

LANE_BACK = LANE_BACK_ASSET.readall()
LANE_CLOSED = LANE_CLOSED_ASSET.readall()
LANE_FORWARD = LANE_FORWARD_ASSET.readall()

API_URL = "https://www.drivebc.ca/data/dms.json"
sign_number = "DMS 11_4"

ARROWS_API_URL = "https://b60n09kp22.execute-api.us-west-2.amazonaws.com/prod/getarrows"

def fetch_arrow_directions(api_key):
    headers = {"x-api-key": api_key}
    r = http.get(ARROWS_API_URL, headers = headers, ttl_seconds = 30)
    if r.status_code == 200:
        return r.json().get("arrow_directions", [])
    else:
        return []

def fetch_dms_data():
    r = http.get(API_URL)
    if r.status_code == 200:
        return r.json()
    else:
        return None

def get_sign_by_signNo(dms_data, sign_number):
    for sign in dms_data:
        if sign["location"]["signNo"] == sign_number:
            return sign
    return None

def get_image_src_for_direction(direction):
    """Return the appropriate image src based on arrow direction."""
    if direction == "back":
        return LANE_BACK
    elif direction == "forward":
        return LANE_FORWARD
    elif direction == "closed":
        return LANE_CLOSED
    else:
        return LANE_CLOSED  # default, can be changed as per requirement

def render_dms(api_key):
    dms_data = fetch_dms_data()
    arrow_directions = fetch_arrow_directions(api_key)
    dms_sign = get_sign_by_signNo(dms_data, sign_number)
    decoded_text = base64.decode(dms_sign["location"]["content"]["pages"][0]["lines"][0]["text"])
    decoded_text = decoded_text.replace("[nl]  ", " - ")
    sign_text = decoded_text.replace("[pt30o2]  ", "")

    lane_icons = []
    if arrow_directions:
        for direction in arrow_directions:
            lane_icons.append(render.Image(src = get_image_src_for_direction(direction), width = 10))
            lane_icons.append(render.Box(width = 11))

        # Remove the last gap after the last icon
        lane_icons.pop()
    else:
        lane_icons.append(render.Marquee(width = 64, child = render.Text("Lane status unavailable", font = "tb-8", color = "#B84")))

    return render.Root(
        child = render.Column(
            children = [
                render.Box(height = 1),
                render.Marquee(width = 64, child = render.Text(sign_text, font = "tb-8", color = "#B84")),
                render.Box(height = 1),
                render.Box(height = 1, color = "#666"),
                render.Box(height = 1),
                render.Text("Lane Status", font = "tom-thumb"),
                render.Box(height = 2),
                render.Row(
                    children = [
                        render.Box(width = 6),  # Initial gap
                    ] + lane_icons + [
                        render.Box(width = 8),  # End gap
                    ],
                ),
            ],
        ),
    )

def main(config):
    api_key = config.get("arrows_api_key")

    # special case for CI
    if api_key == None:
        return []

    return render_dms(api_key)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "arrows_api_key",
                name = "Arrows API Key",
                desc = "An Arrows API key to access the Arrows API.",
                icon = "key",
                secret = True,
            ),
        ],
    )
