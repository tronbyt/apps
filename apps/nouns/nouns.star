"""
Applet: Nouns
Summary: Show current Noun auction
Description: Displays the Noun currently under auction and bid details.
Author: miracle2k
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "canvas", "render")
load("time.star", "time")

def is_square():
    """True on a 64x64 panel.

    Panels are told apart by SHAPE, never by size: the 128x64 wide panel is
    also 64 tall.
    """
    w, h = canvas.size()
    return h == w

def main():
    screen = render_screen()

    # Centre the block on the square (64x64); other panels unchanged.
    return render.Root(child = (render.Box(width = canvas.width(), height = canvas.height(), child = screen)) if is_square() else screen)

def render_screen():
    rep = http.post(
        "https://api.goldsky.com/api/public/project_cldf2o9pqagp43svvbk5u3kmo/subgraphs/nouns/0.1.0/gn",
        body = json.encode({
            "query": """
                query {
                    auctions(first:1, orderDirection: desc, orderBy: endTime) {
                        id,
                        amount,
                        startTime,
                        endTime,
                        bidder {
                            id,
                        },
                        settled
                        noun {
                            id,      
                        }
                    }
                }
            """,
        }),
        headers = {
            "content-type": "application/json",
        },
        ttl_seconds = 60,
    )
    if rep.status_code != 200:
        return render.WrappedText("API Error: %d" % rep.status_code, color = "#ff0000")
    auction = rep.json()["data"]["auctions"][0]

    img_data = http.get("https://noun.pics/{}.jpg".format(auction["noun"]["id"]), ttl_seconds = 3600 * 6).body()
    img = render.Image(src = img_data, width = 32)

    ether = int(auction["amount"]) / 1000000000000000000

    time_text = humanize.relative_time(time.now(), time.from_timestamp(int(auction["endTime"])))
    time_text = time_text.replace(" hours", "h")
    time_text = time_text.replace(" hour", "h")
    time_text = time_text.replace(" minutes", "m")
    time_text = time_text.replace(" minute", "m")
    time_text = time_text.replace(" seconds", "s")
    time_text = time_text.replace(" second", "s")

    # render two columns
    return render.Row(
        expanded = True,
        children = [
            img,
            render.Box(
                color = "#000000",
                child = render.Column(
                    expanded = True,
                    cross_align = "center",
                    #main_align="space_around",
                    main_align = "space_evenly",
                    children = [
                        # Without this box, the text centering
                        # of the middle row depends on the length
                        # of the last row...
                        render.Box(
                            height = 6,
                            child = render.Text("{}".format(auction["noun"]["id"]), font = "tom-thumb", color = "#ffffff"),
                        ),
                        render.Row(
                            children = [
                                render.Text("Ξ", font = "5x8", color = "#ffffffcc"),
                                render.Text("{}".format(humanize.comma(ether)), font = "tb-8", color = "#ffffff"),
                            ],
                        ),
                        render.Text("{}".format(time_text), font = "tom-thumb", color = "#ffffff77"),
                    ],
                ),
            ),
        ],
    )
