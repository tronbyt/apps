"""
Applet: Catfact
Summary: A random fact about a cat
Description: Calls an external API and retrieves a random cat fact and renders it. Rotating every 4 minutes.
Author: broepke
"""

load("http.star", "http")
load("images/cat_icon.png", CAT_ICON_ASSET = "file")
load("render.star", "render")

CAT_ICON = CAT_ICON_ASSET.readall()

CAT_URL = "https://catfact.ninja/fact"

# https://www.pixilart.com/art/tidycat-sr2866c333cb471

def main():
    """Main entry point of the applicaiton.  Returns the rendering for the Tidbyt applet.

    Returns:
        render.Root: The rendering for the Tidbyt applet.
    """

    print("Calling Cat Fact API.")
    rep = http.get(CAT_URL, ttl_seconds = 240)

    if rep.status_code != 200:
        fail("Request failed with status %d", rep.status_code)

    response = rep.json()["fact"]

    return render.Root(
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Image(
                            width = 8,
                            height = 8,
                            src = CAT_ICON,
                        ),
                        render.Text(
                            "Cat Fact:",
                            offset = 0,
                            height = 10,
                            color = "#FFFFFF",
                        ),
                    ],
                ),
                render.Marquee(
                    height = 24,
                    scroll_direction = "vertical",
                    offset_start = 24,
                    child =
                        render.Column(
                            main_align = "space_between",
                            children = render_text(response),
                        ),
                ),
            ],
        ),
    )

def render_text(fact_text):
    cat_text = []
    cat_text.append(render.WrappedText(fact_text))

    return (cat_text)
