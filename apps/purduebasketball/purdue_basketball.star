"""
Applet: Purdue Basketball
Summary: Shows basketball record
Description: Shows Purdues bball record.
Author: Griffinov22
"""

load("http.star", "http")
load("images/purdue_logo.png", PURDUE_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

PURDUE_LOGO = PURDUE_LOGO_ASSET.readall()

def main(config):
    year = time.now().year
    api_key = config.str("api_key", "")

    cbb_stat_endpoint = "https://api.sportsdata.io/v3/cbb/scores/json/TeamSeasonStats/" + str(year) + "?key=" + api_key

    if (api_key == ""):
        return render.Root(
            child = render.Text("API KEY Needed"),
        )

    purdue_stat = get_purdue_stat(cbb_stat_endpoint)
    wins = int(purdue_stat["wins"])
    losses = int(purdue_stat["losses"])
    # child = render.Text("{}-{}".format(wins,losses))

    return render.Root(
        child = render.Box(
            # width=48,
            padding = 5,
            child = render.Column(
                children = [render.Row(
                    children = [
                        render.Image(src = PURDUE_LOGO, width = 24),
                        render.Text("{}-{}".format(wins, losses)),
                    ],
                    main_align = "space_between",
                    cross_align = "center",
                    expanded = True,
                )],
                cross_align = "center",
            ),
        ),
    )

def get_purdue_stat(endpoint):
    data = http.get(endpoint)
    if (data.status_code != 200):
        fail("could not fetch college sports api. You might want to look at your api key.")

    res = data.json()

    for obj in res:
        if (obj["Team"] == "PUR"):
            return {"wins": obj["Wins"], "losses": obj["Losses"]}

    return {"wins": 0, "losses": 0}

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "api key",
                desc = "API key you can get for free at https://sportsdata.io/",
                icon = "key",
                secret = True,
            ),
        ],
    )
