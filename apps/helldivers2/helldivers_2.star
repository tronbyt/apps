"""
Applet: Helldivers 2
Summary: View current player count
Description: Shows the current player count.
Author: Daniel Sitnik
"""

load("http.star", "http")
load("images/h2_logo.webp", H2_LOGO_ASSET = "file")
load("render.star", "render")

H2_LOGO = H2_LOGO_ASSET.readall()

H2_URL = "https://api.live.prod.thehelldiversgame.com/api/WarSeason/801/Status"

def main():
    res = http.get(H2_URL, ttl_seconds = 900)

    # handle api errors
    if res.status_code != 200:
        print("API error %d: %s" % (res.status_code, res.body()))
        return render_error(res.status_code)

    data = res.json()

    player_count = 0
    for planet in data["planetStatus"]:
        player_count += int(planet["players"])

    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = H2_LOGO),
                    render.Text(content = str(player_count), color = "#fcea3f"),
                ],
            ),
        ),
    )

def render_error(status_code):
    message = "API error %d" % status_code

    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = H2_LOGO),
                    render.Marquee(
                        align = "center",
                        width = 38,
                        child = render.Text(content = message, color = "#f00"),
                    ),
                ],
            ),
        ),
    )
