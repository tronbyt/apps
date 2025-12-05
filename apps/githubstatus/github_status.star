"""
Applet: GitHub Status
Summary: Monitor GitHub status
Description: Periodically call the GitHub status page and display any outages that occur.
Author: hross
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/github_icon.png", GITHUB_ICON_ASSET = "file")
load("images/github_icon_red.png", GITHUB_ICON_RED_ASSET = "file")
load("images/github_icon_yellow.png", GITHUB_ICON_YELLOW_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

GITHUB_ICON = GITHUB_ICON_ASSET.readall()
GITHUB_ICON_RED = GITHUB_ICON_RED_ASSET.readall()
GITHUB_ICON_YELLOW = GITHUB_ICON_YELLOW_ASSET.readall()

# statuspage.io GitHub status page ID component file
GITHUB_INCIDENTS_JSON = "https://kctbh9vrtdwd.statuspage.io/api/v2/components.json"

def main():
    # make an API request if cache is empty
    rep = http.get(GITHUB_INCIDENTS_JSON, ttl_seconds = 240)
    if rep.status_code != 200:
        fail("GitHub Status failed with status %d", rep.status_code)

    body = rep.body()

    statusJson = json.decode(body)

    op_state = "good"
    failing_components = []

    for component in statusJson["components"]:
        if component["status"] != "operational":
            if op_state == "good":
                op_state = component["status"]
            elif component["status"] != "partial_outage":
                op_state = component["status"]  # lowest status

            # add marquee text to outage info
            if (component["name"] and not "githubstatus.com" in component["name"]):
                failing_components.append(
                    render.Marquee(width = 48, child = render.Text(" " + component["name"], color = "#a00" if op_state != "partial_outage" else "#FFFF00")),
                )

    if (op_state == "good"):
        failing_components = [render.Marquee(width = 48, child = render.Text(" No Issues", color = "#0a0"))]

    # a lot of failures
    if (op_state != "good" and len(failing_components) > 4):
        failing_components = [
            render.Text("%d Services" % len(failing_components), color = "#a00" if op_state != "partial_outage" else "#FFFF00"),
            render.Text("    Down", color = "#a00" if op_state != "partial_outage" else "#FFFF00"),
        ]

    imgSrc = GITHUB_ICON
    if op_state == "partial_outage":
        imgSrc = GITHUB_ICON_YELLOW
    elif op_state != "good":
        imgSrc = GITHUB_ICON_RED

    return render.Root(
        child = render.Box(
            # This Box exists to provide vertical centering
            render.Row(
                expanded = True,  # Use as much horizontal space as possible
                main_align = "space_evenly",  # Controls horizontal alignment
                cross_align = "center",  # Controls vertical alignment
                children = [
                    render.Image(src = imgSrc, width = 15),
                    render.Column(
                        children = failing_components,
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
