"""
Applet: Hacker News
Summary: Hacker News Top Stories
Description: See recent top stories submitted to Hacker News with info about upvotes and number of comments.
Author: Nick Comer
"""

load("http.star", "http")
load("images/yc_icon.png", YC_ICON_ASSET = "file")
load("render.star", "render")

YC_ICON = YC_ICON_ASSET.readall()

TOP_STORIES_DATA_ENDPOINT = "https://hn-top-tidbyt-prod.nkcmr.dev/top-stories.json"

def main():
    resp = http.get(TOP_STORIES_DATA_ENDPOINT)
    if resp.status_code != 200:
        fail("Data request failed with status %d", resp.status_code)

    stories = resp.json()["stories"]

    story_widgets = []
    for i in range(len(stories)):
        column_widgets = [
            render.WrappedText(stories[i]["title"], font = "5x8"),
            render.Box(width = 1, height = 2),  # padding
            render.Row(children = [
                render.Text("points:   ", font = "tom-thumb", color = "#ccc"),
                render.Text("%d" % (stories[i]["score"]), font = "tom-thumb", color = "#f60"),
            ]),
            render.Box(width = 1, height = 1),  # padding
            render.Row(children = [
                render.Text("comments: ", font = "tom-thumb", color = "#ccc"),
                render.Text("%d" % (stories[i]["descendants"]), font = "tom-thumb", color = "#f60"),
            ]),
        ]
        if i < (len(stories) - 1):
            column_widgets.extend([
                render.Box(height = 1, color = "#ccc"),
                render.Box(width = 1, height = 2),  # padding
            ])
        story_widgets.append(
            render.Column(
                children = column_widgets,
            ),
        )

    return render.Root(
        delay = 80,
        child = render.Column(
            children = [
                render.Box(width = 1, height = 1),  # padding
                render.Row(
                    main_align = "start",
                    children = [
                        render.Row(
                            children = [
                                render.Box(width = 1, height = 1),  # padding
                                render.Image(src = YC_ICON, width = 10, height = 10),
                                render.Box(width = 3, height = 1),  # padding
                                render.Column(
                                    children = [
                                        render.Box(width = 1, height = 3),  # padding
                                        render.Text("Hacker News", font = "tom-thumb"),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
                render.Box(width = 1, height = 1),  # padding
                render.Box(height = 1, color = "#ccc"),
                render.Box(width = 1, height = 1),  # padding
                render.Marquee(
                    scroll_direction = "vertical",
                    height = 18,
                    child = render.Column(
                        children = story_widgets,
                    ),
                ),
            ],
        ),
    )
