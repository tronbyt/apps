"""
Applet: Discord Members
Summary: Discord Members Count
Description: Display the approximate member count for a given Discord server (via Invite ID).
Author: Dennis Zoma (https://zoma.dev)
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("images/twitter_icon.png", TWITTER_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

TWITTER_ICON = TWITTER_ICON_ASSET.readall()

DISCORD_API_URL = "https://discord.com/api/v9/invites/%s?with_counts=true"

def main(config):
    invite_id = config.get("invite_id", "r45MXG4kZc")

    url = DISCORD_API_URL % invite_id
    response = http.get(url, ttl_seconds = 240)

    if response.status_code != 200:
        fail("Discord request failed with status %d", response.status_code)

    body = response.json()

    if body == None or len(body) == 0 or body["guild"] == None or len(body["guild"]) == 0:
        formatted_members_count = "Not Found"
        server_name = "Check your invite ID"
    else:
        formatted_members_count = "%s members" % humanize.comma(int(body["approximate_member_count"]))
        server_name = body["guild"]["name"]

    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(TWITTER_ICON),
                            render.WrappedText(formatted_members_count),
                        ],
                    ),
                    render.Marquee(
                        width = 64,
                        align = "center",
                        offset_start = 10,
                        child = render.Text(
                            color = "#3c3c3c",
                            content = server_name,
                        ),
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "invite_id",
                name = "Invite ID",
                icon = "userPlus",
                desc = "Valid Discord Server Invite ID (Important: Set expiration to infinite)",
            ),
        ],
    )
