"""
Applet: SlippiStats
Summary: Displays stats from SSBM
Description: Takes stats from SSBM replays uploaded to chartslp.com and shows you stats about your play.
Author: trbarron
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("images/bowser_0.webp", BOWSER_0 = "file")
load("images/bowser_1.webp", BOWSER_1 = "file")
load("images/bowser_2.webp", BOWSER_2 = "file")
load("images/bowser_3.webp", BOWSER_3 = "file")
load("images/dk_0.webp", DK_0 = "file")
load("images/dk_1.webp", DK_1 = "file")
load("images/dk_2.webp", DK_2 = "file")
load("images/dk_3.webp", DK_3 = "file")
load("images/dk_4.webp", DK_4 = "file")
load("images/dr_mario_0.webp", DR_MARIO_0 = "file")
load("images/dr_mario_1.webp", DR_MARIO_1 = "file")
load("images/dr_mario_2.webp", DR_MARIO_2 = "file")
load("images/dr_mario_3.webp", DR_MARIO_3 = "file")
load("images/dr_mario_4.webp", DR_MARIO_4 = "file")
load("images/falco_0.webp", FALCO_0 = "file")
load("images/falco_1.webp", FALCO_1 = "file")
load("images/falco_2.webp", FALCO_2 = "file")
load("images/falco_3.webp", FALCO_3 = "file")
load("images/falcon_0.webp", FALCON_0 = "file")
load("images/falcon_1.webp", FALCON_1 = "file")
load("images/falcon_2.webp", FALCON_2 = "file")
load("images/falcon_3.webp", FALCON_3 = "file")
load("images/falcon_4.webp", FALCON_4 = "file")
load("images/falcon_5.webp", FALCON_5 = "file")
load("images/fox_0.webp", FOX_0 = "file")
load("images/fox_1.webp", FOX_1 = "file")
load("images/fox_2.webp", FOX_2 = "file")
load("images/fox_3.webp", FOX_3 = "file")
load("images/game_and_watch_0.webp", GAME_AND_WATCH_0 = "file")
load("images/game_and_watch_1.webp", GAME_AND_WATCH_1 = "file")
load("images/game_and_watch_2.webp", GAME_AND_WATCH_2 = "file")
load("images/game_and_watch_3.webp", GAME_AND_WATCH_3 = "file")
load("images/ganondorf_0.webp", GANONDORF_0 = "file")
load("images/ganondorf_1.webp", GANONDORF_1 = "file")
load("images/ganondorf_2.webp", GANONDORF_2 = "file")
load("images/ganondorf_3.webp", GANONDORF_3 = "file")
load("images/ganondorf_4.webp", GANONDORF_4 = "file")
load("images/ice_climbers_0.webp", ICE_CLIMBERS_0 = "file")
load("images/ice_climbers_1.webp", ICE_CLIMBERS_1 = "file")
load("images/ice_climbers_2.webp", ICE_CLIMBERS_2 = "file")
load("images/ice_climbers_3.webp", ICE_CLIMBERS_3 = "file")
load("images/jigglypuff_0.webp", JIGGLYPUFF_0 = "file")
load("images/jigglypuff_1.webp", JIGGLYPUFF_1 = "file")
load("images/jigglypuff_2.webp", JIGGLYPUFF_2 = "file")
load("images/jigglypuff_3.webp", JIGGLYPUFF_3 = "file")
load("images/jigglypuff_4.webp", JIGGLYPUFF_4 = "file")
load("images/kirby_0.webp", KIRBY_0 = "file")
load("images/kirby_1.webp", KIRBY_1 = "file")
load("images/kirby_2.webp", KIRBY_2 = "file")
load("images/kirby_3.webp", KIRBY_3 = "file")
load("images/kirby_4.webp", KIRBY_4 = "file")
load("images/kirby_5.webp", KIRBY_5 = "file")
load("images/link_0.webp", LINK_0 = "file")
load("images/link_1.webp", LINK_1 = "file")
load("images/link_2.webp", LINK_2 = "file")
load("images/link_3.webp", LINK_3 = "file")
load("images/link_4.webp", LINK_4 = "file")
load("images/luigi_0.webp", LUIGI_0 = "file")
load("images/luigi_1.webp", LUIGI_1 = "file")
load("images/luigi_2.webp", LUIGI_2 = "file")
load("images/luigi_3.webp", LUIGI_3 = "file")
load("images/mario_23_0.webp", MARIO_23_0 = "file")
load("images/mario_23_1.webp", MARIO_23_1 = "file")
load("images/mario_23_2.webp", MARIO_23_2 = "file")
load("images/mario_23_3.webp", MARIO_23_3 = "file")
load("images/mario_23_4.webp", MARIO_23_4 = "file")
load("images/mario_8_0.webp", MARIO_8_0 = "file")
load("images/mario_8_1.webp", MARIO_8_1 = "file")
load("images/mario_8_2.webp", MARIO_8_2 = "file")
load("images/mario_8_3.webp", MARIO_8_3 = "file")
load("images/mario_8_4.webp", MARIO_8_4 = "file")
load("images/marth_0.webp", MARTH_0 = "file")
load("images/marth_1.webp", MARTH_1 = "file")
load("images/marth_2.webp", MARTH_2 = "file")
load("images/marth_3.webp", MARTH_3 = "file")
load("images/marth_4.webp", MARTH_4 = "file")
load("images/mewtwo_0.webp", MEWTWO_0 = "file")
load("images/mewtwo_1.webp", MEWTWO_1 = "file")
load("images/mewtwo_2.webp", MEWTWO_2 = "file")
load("images/mewtwo_3.webp", MEWTWO_3 = "file")
load("images/ness_0.webp", NESS_0 = "file")
load("images/ness_1.webp", NESS_1 = "file")
load("images/ness_2.webp", NESS_2 = "file")
load("images/ness_3.webp", NESS_3 = "file")
load("images/peach_0.webp", PEACH_0 = "file")
load("images/peach_1.webp", PEACH_1 = "file")
load("images/peach_2.webp", PEACH_2 = "file")
load("images/peach_3.webp", PEACH_3 = "file")
load("images/peach_4.webp", PEACH_4 = "file")
load("images/pichu_0.webp", PICHU_0 = "file")
load("images/pichu_1.webp", PICHU_1 = "file")
load("images/pichu_2.webp", PICHU_2 = "file")
load("images/pichu_3.webp", PICHU_3 = "file")
load("images/pikachu_0.webp", PIKACHU_0 = "file")
load("images/pikachu_1.webp", PIKACHU_1 = "file")
load("images/pikachu_2.webp", PIKACHU_2 = "file")
load("images/pikachu_3.webp", PIKACHU_3 = "file")
load("images/roy_0.webp", ROY_0 = "file")
load("images/roy_1.webp", ROY_1 = "file")
load("images/roy_2.webp", ROY_2 = "file")
load("images/roy_3.webp", ROY_3 = "file")
load("images/roy_4.webp", ROY_4 = "file")
load("images/samus_0.webp", SAMUS_0 = "file")
load("images/samus_1.webp", SAMUS_1 = "file")
load("images/samus_2.webp", SAMUS_2 = "file")
load("images/samus_3.webp", SAMUS_3 = "file")
load("images/samus_4.webp", SAMUS_4 = "file")
load("images/sheik_0.webp", SHEIK_0 = "file")
load("images/sheik_1.webp", SHEIK_1 = "file")
load("images/sheik_2.webp", SHEIK_2 = "file")
load("images/sheik_3.webp", SHEIK_3 = "file")
load("images/sheik_4.webp", SHEIK_4 = "file")
load("images/yoshi_0.webp", YOSHI_0 = "file")
load("images/yoshi_1.webp", YOSHI_1 = "file")
load("images/yoshi_2.webp", YOSHI_2 = "file")
load("images/yoshi_3.webp", YOSHI_3 = "file")
load("images/yoshi_4.webp", YOSHI_4 = "file")
load("images/yoshi_5.webp", YOSHI_5 = "file")
load("images/young_link_0.webp", YOUNG_LINK_0 = "file")
load("images/young_link_1.webp", YOUNG_LINK_1 = "file")
load("images/young_link_2.webp", YOUNG_LINK_2 = "file")
load("images/young_link_3.webp", YOUNG_LINK_3 = "file")
load("images/young_link_4.webp", YOUNG_LINK_4 = "file")
load("images/zelda_0.webp", ZELDA_0 = "file")
load("images/zelda_1.webp", ZELDA_1 = "file")
load("images/zelda_2.webp", ZELDA_2 = "file")
load("images/zelda_3.webp", ZELDA_3 = "file")
load("images/zelda_4.webp", ZELDA_4 = "file")
load("render.star", "render")
load("schema.star", "schema")

CHART_SLP_SERVER_URL = "https://chart-slp-server.herokuapp.com/api/matches?code="
DEFAULT_CODE = "TRB-328"

icons = {
    #c. falcon
    "0_0": FALCON_0.readall(),
    "0_1": FALCON_1.readall(),
    "0_2": FALCON_2.readall(),
    "0_3": FALCON_3.readall(),
    "0_4": FALCON_4.readall(),
    "0_5": FALCON_5.readall(),

    # dk
    "1_0": DK_0.readall(),
    "1_1": DK_1.readall(),
    "1_2": DK_2.readall(),
    "1_3": DK_3.readall(),
    "1_4": DK_4.readall(),

    # fox
    "2_0": FOX_0.readall(),
    "2_1": FOX_1.readall(),
    "2_2": FOX_2.readall(),
    "2_3": FOX_3.readall(),

    #G&W
    "3_0": GAME_AND_WATCH_0.readall(),
    "3_1": GAME_AND_WATCH_1.readall(),
    "3_2": GAME_AND_WATCH_2.readall(),
    "3_3": GAME_AND_WATCH_3.readall(),

    #kirby
    "4_0": KIRBY_0.readall(),
    "4_1": KIRBY_1.readall(),
    "4_2": KIRBY_2.readall(),
    "4_3": KIRBY_3.readall(),
    "4_4": KIRBY_4.readall(),
    "4_5": KIRBY_5.readall(),

    #bowser
    "5_0": BOWSER_0.readall(),
    "5_1": BOWSER_1.readall(),
    "5_2": BOWSER_2.readall(),
    "5_3": BOWSER_3.readall(),

    #link
    "6_0": LINK_0.readall(),
    "6_1": LINK_1.readall(),
    "6_2": LINK_2.readall(),
    "6_3": LINK_3.readall(),
    "6_4": LINK_4.readall(),

    #luigi
    "7_0": LUIGI_0.readall(),
    "7_1": LUIGI_1.readall(),
    "7_2": LUIGI_2.readall(),
    "7_3": LUIGI_3.readall(),

    #mario
    "8_0": MARIO_8_0.readall(),
    "8_1": MARIO_8_1.readall(),
    "8_2": MARIO_8_2.readall(),
    "8_3": MARIO_8_3.readall(),
    "8_4": MARIO_8_4.readall(),

    #marth
    "9_0": MARTH_0.readall(),
    "9_1": MARTH_1.readall(),
    "9_2": MARTH_2.readall(),
    "9_3": MARTH_3.readall(),
    "9_4": MARTH_4.readall(),

    #mew2
    "10_0": MEWTWO_0.readall(),
    "10_1": MEWTWO_1.readall(),
    "10_2": MEWTWO_2.readall(),
    "10_3": MEWTWO_3.readall(),

    #ness
    "11_0": NESS_0.readall(),
    "11_1": NESS_1.readall(),
    "11_2": NESS_2.readall(),
    "11_3": NESS_3.readall(),

    #peach
    "12_0": PEACH_0.readall(),
    "12_1": PEACH_1.readall(),
    "12_2": PEACH_2.readall(),
    "12_3": PEACH_3.readall(),
    "12_4": PEACH_4.readall(),

    #pikachu
    "13_0": PIKACHU_0.readall(),
    "13_1": PIKACHU_1.readall(),
    "13_2": PIKACHU_2.readall(),
    "13_3": PIKACHU_3.readall(),

    #ICs
    "14_0": ICE_CLIMBERS_0.readall(),
    "14_1": ICE_CLIMBERS_1.readall(),
    "14_2": ICE_CLIMBERS_2.readall(),
    "14_3": ICE_CLIMBERS_3.readall(),

    #puff
    "15_0": JIGGLYPUFF_0.readall(),
    "15_1": JIGGLYPUFF_1.readall(),
    "15_2": JIGGLYPUFF_2.readall(),
    "15_3": JIGGLYPUFF_3.readall(),
    "15_4": JIGGLYPUFF_4.readall(),

    #samus
    "16_0": SAMUS_0.readall(),
    "16_1": SAMUS_1.readall(),
    "16_2": SAMUS_2.readall(),
    "16_3": SAMUS_3.readall(),
    "16_4": SAMUS_4.readall(),

    #yoshi
    "17_0": YOSHI_0.readall(),
    "17_1": YOSHI_1.readall(),
    "17_2": YOSHI_2.readall(),
    "17_3": YOSHI_3.readall(),
    "17_4": YOSHI_4.readall(),
    "17_5": YOSHI_5.readall(),

    #zelda
    "18_0": ZELDA_0.readall(),
    "18_1": ZELDA_1.readall(),
    "18_2": ZELDA_2.readall(),
    "18_3": ZELDA_3.readall(),
    "18_4": ZELDA_4.readall(),

    #shiek
    "19_0": SHEIK_0.readall(),
    "19_1": SHEIK_1.readall(),
    "19_2": SHEIK_2.readall(),
    "19_3": SHEIK_3.readall(),
    "19_4": SHEIK_4.readall(),

    #falco
    "20_0": FALCO_0.readall(),
    "20_1": FALCO_1.readall(),
    "20_2": FALCO_2.readall(),
    "20_3": FALCO_3.readall(),

    #y.link
    "21_0": YOUNG_LINK_0.readall(),
    "21_1": YOUNG_LINK_1.readall(),
    "21_2": YOUNG_LINK_2.readall(),
    "21_3": YOUNG_LINK_3.readall(),
    "21_4": YOUNG_LINK_4.readall(),

    #dr. mario
    "22_0": DR_MARIO_0.readall(),
    "22_1": DR_MARIO_1.readall(),
    "22_2": DR_MARIO_2.readall(),
    "22_3": DR_MARIO_3.readall(),
    "22_4": DR_MARIO_4.readall(),

    #mario
    "23_0": MARIO_23_0.readall(),
    "23_1": MARIO_23_1.readall(),
    "23_2": MARIO_23_2.readall(),
    "23_3": MARIO_23_3.readall(),
    "23_4": MARIO_23_4.readall(),

    #roy
    "24_0": ROY_0.readall(),
    "24_1": ROY_1.readall(),
    "24_2": ROY_2.readall(),
    "24_3": ROY_3.readall(),
    "24_4": ROY_4.readall(),

    #pichu
    "25_0": PICHU_0.readall(),
    "25_1": PICHU_1.readall(),
    "25_2": PICHU_2.readall(),
    "25_3": PICHU_3.readall(),

    #dorf
    "26_0": GANONDORF_0.readall(),
    "26_1": GANONDORF_1.readall(),
    "26_2": GANONDORF_2.readall(),
    "26_3": GANONDORF_3.readall(),
    "26_4": GANONDORF_4.readall(),
}

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "code",
                name = "Slippi Code",
                desc = "Ex: TRB#328",
                icon = "user",
            ),
        ],
    )

def main(config):
    code = config.str("code", DEFAULT_CODE)
    code = code.replace("#", "-")

    print("Miss! Calling SLP API.")
    GET_URL = CHART_SLP_SERVER_URL + code

    rep = http.get(GET_URL, ttl_seconds = 43200)
    if rep.status_code != 200:
        fail("Chart SLP Request Failed with code")
    totalTime = rep.json()["totalTime"]
    totalTime = totalTime.split(":")
    totalTime = humanize.comma(int(totalTime[0])) + " hrs"
    totalGames = str(humanize.comma(int(rep.json()["totalMatches"]))) + "gs"
    winrate = str(int(rep.json()["winrate"])) + "% wr"
    iconName = str(int(rep.json()["main"])) + "_" + str(int(rep.json()["mainColor"]))

    data = {
        "totalTime": totalTime,
        "totalGames": totalGames,
        "winrate": winrate,
        "iconName": iconName,
    }
    localIconName = data["iconName"]
    charIcon = icons[localIconName]

    return render.Root(
        child = render.Box(
            # This Box exists to provide vertical centering
            render.Row(
                expanded = True,  # Use as much horizontal space as possible
                main_align = "space_evenly",  # Controls horizontal alignment
                cross_align = "center",  # Controls vertical alignment
                children = [
                    render.Padding(child = render.Image(src = charIcon), pad = (1, 1, 1, 1)),
                    render.Column(children = [
                        render.Text(
                            data["totalGames"],
                            font = "tb-8",
                        ),
                        render.Text(
                            content = data["winrate"],
                            font = "tb-8",
                        ),
                        render.Text(
                            content = data["totalTime"],
                            font = "tb-8",
                        ),
                    ]),
                ],
            ),
        ),
    )
