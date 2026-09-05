"""
Applet: ISS Tracker
Summary: Tracks the ISS Position
Description: Tracks the position of the International Space Station using LAT/LONG coordinates.
Author: Chris Jones (@IPv6Freely)
"""

load("http.star", "http")
load("images/iss_logo.png", ISS_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

ISS_LOGO = ISS_LOGO_ASSET.readall()

ISS_URL = "http://api.open-notify.org/iss-now.json"

def get_ISS():
    resp = http.get(ISS_URL)

    if resp.status_code != 200:
        return "API Error"

    data = resp.json()

    timestamp = time.from_timestamp(int(data["timestamp"])).format("15:04:03")
    lat = data["iss_position"]["latitude"]
    lon = data["iss_position"]["longitude"]

    return timestamp, lat, lon

def main():
    timestamp, lat, lon = get_ISS()

    return render.Root(
        child = render.Box(
            color = "#0b0e28",
            child = render.Row(
                children = [
                    render.Box(
                        width = 22,
                        child = render.Image(width = 20, height = 20, src = ISS_LOGO),
                    ),
                    render.Column(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(height = 10, color = "#fff", font = "tb-8", content = str(lat)),
                            render.Text(height = 10, color = "#fff", font = "tb-8", content = str(lon)),
                            render.Text(height = 10, color = "#fff", font = "tb-8", content = str(timestamp)),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
