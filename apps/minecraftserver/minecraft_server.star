"""
Applet: Minecraft Server
Summary: Minecraft Server Activity
Description: View Minecraft Server Activity and icon.
Author: Michael Blades
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("images/img_0e5f994f.png", IMG_0e5f994f_ASSET = "file")

def main(config):
    minecraftURL = config.get("server", "mc.azitoth.com")

    apiURL = "".join(["https://api.mcsrvstat.us/2/", minecraftURL])
    result = http.get(apiURL, ttl_seconds = 60)
    if result.status_code != 200:
        return render_error("Server unavailable (HTTP %d)" % result.status_code)
    result_json = result.json()

    # Check if the server was found/is online
    if "online" in result_json and result_json["online"] == False:
        return render_error("Server not found or offline")
    if "players" not in result_json:
        return render_error("Server not found or offline")

    onlinePlayers = result_json["players"]["online"] if "players" in result_json else 0
    maxPlayers = result_json["players"]["max"] if "players" in result_json else 0
    motd = result_json["motd"]["clean"][0] if "motd" in result_json and len(result_json["motd"]["clean"]) > 0 else ""
    motd2 = result_json["motd"]["clean"][1] if "motd" in result_json and len(result_json["motd"]["clean"]) > 1 else ""

    iconURL = result_json["icon"].split(",")[1] if "icon" in result_json else IMG_0e5f994f_ASSET.readall()

    serverIcon = base64.decode(iconURL)

    return render.Root(
        child = render.Box(
            render.Row(
                cross_align = "center",
                children = [
                    render.Image(src = serverIcon, width = 25, height = 25),
                    render.Column(
                        children = [
                            render.Marquee(
                                width = 40,
                                child = render.Text(
                                    "%d Online" % onlinePlayers,
                                ),
                            ),
                            render.Marquee(
                                width = 40,
                                child = render.Text("%d Max" % maxPlayers),
                            ),
                            render.Marquee(
                                width = 64,
                                child = render.Text("%s" % motd),
                            ),
                            render.Marquee(
                                width = 64,
                                child = render.Text("%s" % motd2),
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def render_error(message):
    return render.Root(
        child = render.Box(
            render.WrappedText(
                content = message,
                align = "center",
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "server",
                name = "Server URL",
                desc = "URL or IP of Minecraft Server",
                icon = "server",
            ),
        ],
    )
