"""
Applet: Homefiniti
Summary: Homefiniti visitor stats
Description: View live visitor stats of your Homefiniti-hosted website.
Author: Donald Mull Jr
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/envelope_icon.png", ENVELOPE_ICON_ASSET = "file")
load("images/oneil.png", ONEIL_ICON_ASSET = "file")
load("images/person_icon.png", PERSON_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

ENVELOPE_ICON = ENVELOPE_ICON_ASSET.readall()
PERSON_ICON = PERSON_ICON_ASSET.readall()

TTL_SECONDS = 60

# 24x24
ONEIL_ICON = ONEIL_ICON_ASSET.readall()

API_URL = "https://app.homefiniti.com/api/v2/tidbyt_summary/"

def get_real_data(config):
    api_key = config.str("api_key")

    if not api_key:
        fail("No API key specified")

    # note: fails with "Bad Request" if there is no user-agent or the default "go" user agent
    response = http.get(API_URL, ttl_seconds = TTL_SECONDS, headers = {"user-agent": "tidbyt", "x-tidbyt-access-token": api_key, "accept": "application/json"})
    response_json = json.decode(response.body())
    visits_today = response_json["stats"]["visits_today"]["value"]
    visits_60_minutes = response_json["stats"]["visits_60_minutes"]["value"]
    leads_today = response_json["stats"]["leads_today"]["value"]
    logo = response_json["ui"].get("logo", None) or ONEIL_ICON

    return (visits_today, visits_60_minutes, leads_today, logo)

def main(config):
    api_key = config.str("api_key")

    if api_key:
        (visits_today, visits_60_minutes, leads_today, logo) = get_real_data(config)
    else:
        visits_today = config.str("visits_today", "99999")
        visits_60_minutes = config.str("visits_60_minutes", "999")
        leads_today = config.str("leads_today", "999")
        logo = ONEIL_ICON

    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "space_between",
            children = [
                render.Padding(
                    pad = (0, -1, 0, -1),
                    child = render.Column(
                        children = [
                            render.Text("NOW"),
                            render.Row(
                                cross_align = "center",
                                children = [
                                    render.Padding(child = render.Image(src = PERSON_ICON), pad = (0, 0, 2, 1)),
                                    render.Text(str(visits_60_minutes) + " "),
                                ],
                            ),
                            render.Box(width = 2, height = 2),  # spacer
                            render.Text("TODAY"),
                            render.Row(
                                cross_align = "center",
                                children = [
                                    render.Padding(child = render.Image(src = PERSON_ICON), pad = (0, 0, 2, 1)),
                                    render.Text(str(visits_today) + " "),
                                ],
                            ),
                        ],
                    ),
                ),
                render.Column(
                    children = [
                        render.Image(src = logo),
                        render.Box(width = 2, height = 1),  # spacer
                        render.Row(
                            cross_align = "center",
                            children = [
                                render.Padding(child = render.Image(src = ENVELOPE_ICON), pad = (0, 1, 2, 1)),
                                render.Text(str(leads_today) + " "),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "Homefiniti API key",
                icon = "key",
                secret = True,
            ),
        ],
    )
