"""
Applet: SlippiStats
Summary: Displays stats from SSBM
Description: Takes stats from SSBM replays uploaded to chartslp.com and shows you stats about your play.
Author: trbarron
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/icon_0_0.webp", ICON_0_0 = "file")
load("images/icon_0_1.webp", ICON_0_1 = "file")
load("images/icon_0_2.webp", ICON_0_2 = "file")
load("images/icon_0_3.webp", ICON_0_3 = "file")
load("images/icon_0_4.webp", ICON_0_4 = "file")
load("images/icon_0_5.webp", ICON_0_5 = "file")
load("images/icon_10_0.webp", ICON_10_0 = "file")
load("images/icon_10_1.webp", ICON_10_1 = "file")
load("images/icon_10_2.webp", ICON_10_2 = "file")
load("images/icon_10_3.webp", ICON_10_3 = "file")
load("images/icon_11_0.webp", ICON_11_0 = "file")
load("images/icon_11_1.webp", ICON_11_1 = "file")
load("images/icon_11_2.webp", ICON_11_2 = "file")
load("images/icon_11_3.webp", ICON_11_3 = "file")
load("images/icon_12_0.webp", ICON_12_0 = "file")
load("images/icon_12_1.webp", ICON_12_1 = "file")
load("images/icon_12_2.webp", ICON_12_2 = "file")
load("images/icon_12_3.webp", ICON_12_3 = "file")
load("images/icon_12_4.webp", ICON_12_4 = "file")
load("images/icon_13_0.webp", ICON_13_0 = "file")
load("images/icon_13_1.webp", ICON_13_1 = "file")
load("images/icon_13_2.webp", ICON_13_2 = "file")
load("images/icon_13_3.webp", ICON_13_3 = "file")
load("images/icon_14_0.webp", ICON_14_0 = "file")
load("images/icon_14_1.webp", ICON_14_1 = "file")
load("images/icon_14_2.webp", ICON_14_2 = "file")
load("images/icon_14_3.webp", ICON_14_3 = "file")
load("images/icon_15_0.webp", ICON_15_0 = "file")
load("images/icon_15_1.webp", ICON_15_1 = "file")
load("images/icon_15_2.webp", ICON_15_2 = "file")
load("images/icon_15_3.webp", ICON_15_3 = "file")
load("images/icon_15_4.webp", ICON_15_4 = "file")
load("images/icon_16_0.webp", ICON_16_0 = "file")
load("images/icon_16_1.webp", ICON_16_1 = "file")
load("images/icon_16_2.webp", ICON_16_2 = "file")
load("images/icon_16_3.webp", ICON_16_3 = "file")
load("images/icon_16_4.webp", ICON_16_4 = "file")
load("images/icon_17_0.webp", ICON_17_0 = "file")
load("images/icon_17_1.webp", ICON_17_1 = "file")
load("images/icon_17_2.webp", ICON_17_2 = "file")
load("images/icon_17_3.webp", ICON_17_3 = "file")
load("images/icon_17_4.webp", ICON_17_4 = "file")
load("images/icon_17_5.webp", ICON_17_5 = "file")
load("images/icon_18_0.webp", ICON_18_0 = "file")
load("images/icon_18_1.webp", ICON_18_1 = "file")
load("images/icon_18_2.webp", ICON_18_2 = "file")
load("images/icon_18_3.webp", ICON_18_3 = "file")
load("images/icon_18_4.webp", ICON_18_4 = "file")
load("images/icon_19_0.webp", ICON_19_0 = "file")
load("images/icon_19_1.webp", ICON_19_1 = "file")
load("images/icon_19_2.webp", ICON_19_2 = "file")
load("images/icon_19_3.webp", ICON_19_3 = "file")
load("images/icon_19_4.webp", ICON_19_4 = "file")
load("images/icon_1_0.webp", ICON_1_0 = "file")
load("images/icon_1_1.webp", ICON_1_1 = "file")
load("images/icon_1_2.webp", ICON_1_2 = "file")
load("images/icon_1_3.webp", ICON_1_3 = "file")
load("images/icon_1_4.webp", ICON_1_4 = "file")
load("images/icon_20_0.webp", ICON_20_0 = "file")
load("images/icon_20_1.webp", ICON_20_1 = "file")
load("images/icon_20_2.webp", ICON_20_2 = "file")
load("images/icon_20_3.webp", ICON_20_3 = "file")
load("images/icon_21_0.webp", ICON_21_0 = "file")
load("images/icon_21_1.webp", ICON_21_1 = "file")
load("images/icon_21_2.webp", ICON_21_2 = "file")
load("images/icon_21_3.webp", ICON_21_3 = "file")
load("images/icon_21_4.webp", ICON_21_4 = "file")
load("images/icon_22_0.webp", ICON_22_0 = "file")
load("images/icon_22_1.webp", ICON_22_1 = "file")
load("images/icon_22_2.webp", ICON_22_2 = "file")
load("images/icon_22_3.webp", ICON_22_3 = "file")
load("images/icon_22_4.webp", ICON_22_4 = "file")
load("images/icon_23_0.webp", ICON_23_0 = "file")
load("images/icon_23_1.webp", ICON_23_1 = "file")
load("images/icon_23_2.webp", ICON_23_2 = "file")
load("images/icon_23_3.webp", ICON_23_3 = "file")
load("images/icon_23_4.webp", ICON_23_4 = "file")
load("images/icon_24_0.webp", ICON_24_0 = "file")
load("images/icon_24_1.webp", ICON_24_1 = "file")
load("images/icon_24_2.webp", ICON_24_2 = "file")
load("images/icon_24_3.webp", ICON_24_3 = "file")
load("images/icon_24_4.webp", ICON_24_4 = "file")
load("images/icon_25_0.webp", ICON_25_0 = "file")
load("images/icon_25_1.webp", ICON_25_1 = "file")
load("images/icon_25_2.webp", ICON_25_2 = "file")
load("images/icon_25_3.webp", ICON_25_3 = "file")
load("images/icon_26_0.webp", ICON_26_0 = "file")
load("images/icon_26_1.webp", ICON_26_1 = "file")
load("images/icon_26_2.webp", ICON_26_2 = "file")
load("images/icon_26_3.webp", ICON_26_3 = "file")
load("images/icon_26_4.webp", ICON_26_4 = "file")
load("images/icon_2_0.webp", ICON_2_0 = "file")
load("images/icon_2_1.webp", ICON_2_1 = "file")
load("images/icon_2_2.webp", ICON_2_2 = "file")
load("images/icon_2_3.webp", ICON_2_3 = "file")
load("images/icon_3_0.webp", ICON_3_0 = "file")
load("images/icon_3_1.webp", ICON_3_1 = "file")
load("images/icon_3_2.webp", ICON_3_2 = "file")
load("images/icon_3_3.webp", ICON_3_3 = "file")
load("images/icon_4_0.webp", ICON_4_0 = "file")
load("images/icon_4_1.webp", ICON_4_1 = "file")
load("images/icon_4_2.webp", ICON_4_2 = "file")
load("images/icon_4_3.webp", ICON_4_3 = "file")
load("images/icon_4_4.webp", ICON_4_4 = "file")
load("images/icon_4_5.webp", ICON_4_5 = "file")
load("images/icon_5_0.webp", ICON_5_0 = "file")
load("images/icon_5_1.webp", ICON_5_1 = "file")
load("images/icon_5_2.webp", ICON_5_2 = "file")
load("images/icon_5_3.webp", ICON_5_3 = "file")
load("images/icon_6_0.webp", ICON_6_0 = "file")
load("images/icon_6_1.webp", ICON_6_1 = "file")
load("images/icon_6_2.webp", ICON_6_2 = "file")
load("images/icon_6_3.webp", ICON_6_3 = "file")
load("images/icon_6_4.webp", ICON_6_4 = "file")
load("images/icon_7_0.webp", ICON_7_0 = "file")
load("images/icon_7_1.webp", ICON_7_1 = "file")
load("images/icon_7_2.webp", ICON_7_2 = "file")
load("images/icon_7_3.webp", ICON_7_3 = "file")
load("images/icon_8_0.webp", ICON_8_0 = "file")
load("images/icon_8_1.webp", ICON_8_1 = "file")
load("images/icon_8_2.webp", ICON_8_2 = "file")
load("images/icon_8_3.webp", ICON_8_3 = "file")
load("images/icon_8_4.webp", ICON_8_4 = "file")
load("images/icon_9_0.webp", ICON_9_0 = "file")
load("images/icon_9_1.webp", ICON_9_1 = "file")
load("images/icon_9_2.webp", ICON_9_2 = "file")
load("images/icon_9_3.webp", ICON_9_3 = "file")
load("images/icon_9_4.webp", ICON_9_4 = "file")
load("render.star", "render")
load("schema.star", "schema")

CHART_SLP_SERVER_URL = "https://chart-slp-server.herokuapp.com/api/matches?code="
DEFAULT_CODE = "TRB-328"

# Load icon from base64 encoded data
# https://www.base64encoder.io/image-to-base64-converter/
icons = {
    #c. falcon
    "0_0": ICON_0_0.readall(),
    "0_1": ICON_0_1.readall(),
    "0_2": ICON_0_2.readall(),
    "0_3": ICON_0_3.readall(),
    "0_4": ICON_0_4.readall(),
    "0_5": ICON_0_5.readall(),

    # dk
    "1_0": ICON_1_0.readall(),
    "1_1": ICON_1_1.readall(),
    "1_2": ICON_1_2.readall(),
    "1_3": ICON_1_3.readall(),
    "1_4": ICON_1_4.readall(),

    # fox
    "2_0": ICON_2_0.readall(),
    "2_1": ICON_2_1.readall(),
    "2_2": ICON_2_2.readall(),
    "2_3": ICON_2_3.readall(),

    #G&W
    "3_0": ICON_3_0.readall(),
    "3_1": ICON_3_1.readall(),
    "3_2": ICON_3_2.readall(),
    "3_3": ICON_3_3.readall(),

    #kirby
    "4_0": ICON_4_0.readall(),
    "4_1": ICON_4_1.readall(),
    "4_2": ICON_4_2.readall(),
    "4_3": ICON_4_3.readall(),
    "4_4": ICON_4_4.readall(),
    "4_5": ICON_4_5.readall(),

    #bowser
    "5_0": ICON_5_0.readall(),
    "5_1": ICON_5_1.readall(),
    "5_2": ICON_5_2.readall(),
    "5_3": ICON_5_3.readall(),

    #link
    "6_0": ICON_6_0.readall(),
    "6_1": ICON_6_1.readall(),
    "6_2": ICON_6_2.readall(),
    "6_3": ICON_6_3.readall(),
    "6_4": ICON_6_4.readall(),

    #luigi
    "7_0": ICON_7_0.readall(),
    "7_1": ICON_7_1.readall(),
    "7_2": ICON_7_2.readall(),
    "7_3": ICON_7_3.readall(),

    #mario
    "8_0": ICON_8_0.readall(),
    "8_1": ICON_8_1.readall(),
    "8_2": ICON_8_2.readall(),
    "8_3": ICON_8_3.readall(),
    "8_4": ICON_8_4.readall(),

    #marth
    "9_0": ICON_9_0.readall(),
    "9_1": ICON_9_1.readall(),
    "9_2": ICON_9_2.readall(),
    "9_3": ICON_9_3.readall(),
    "9_4": ICON_9_4.readall(),

    #mew2
    "10_0": ICON_10_0.readall(),
    "10_1": ICON_10_1.readall(),
    "10_2": ICON_10_2.readall(),
    "10_3": ICON_10_3.readall(),

    #ness
    "11_0": ICON_11_0.readall(),
    "11_1": ICON_11_1.readall(),
    "11_2": ICON_11_2.readall(),
    "11_3": ICON_11_3.readall(),

    #peach
    "12_0": ICON_12_0.readall(),
    "12_1": ICON_12_1.readall(),
    "12_2": ICON_12_2.readall(),
    "12_3": ICON_12_3.readall(),
    "12_4": ICON_12_4.readall(),

    #pikachu
    "13_0": ICON_13_0.readall(),
    "13_1": ICON_13_1.readall(),
    "13_2": ICON_13_2.readall(),
    "13_3": ICON_13_3.readall(),

    #ICs
    "14_0": ICON_14_0.readall(),
    "14_1": ICON_14_1.readall(),
    "14_2": ICON_14_2.readall(),
    "14_3": ICON_14_3.readall(),

    #puff
    "15_0": ICON_15_0.readall(),
    "15_1": ICON_15_1.readall(),
    "15_2": ICON_15_2.readall(),
    "15_3": ICON_15_3.readall(),
    "15_4": ICON_15_4.readall(),

    #samus
    "16_0": ICON_16_0.readall(),
    "16_1": ICON_16_1.readall(),
    "16_2": ICON_16_2.readall(),
    "16_3": ICON_16_3.readall(),
    "16_4": ICON_16_4.readall(),

    #yoshi
    "17_0": ICON_17_0.readall(),
    "17_1": ICON_17_1.readall(),
    "17_2": ICON_17_2.readall(),
    "17_3": ICON_17_3.readall(),
    "17_4": ICON_17_4.readall(),
    "17_5": ICON_17_5.readall(),

    #zelda
    "18_0": ICON_18_0.readall(),
    "18_1": ICON_18_1.readall(),
    "18_2": ICON_18_2.readall(),
    "18_3": ICON_18_3.readall(),
    "18_4": ICON_18_4.readall(),

    #shiek
    "19_0": ICON_19_0.readall(),
    "19_1": ICON_19_1.readall(),
    "19_2": ICON_19_2.readall(),
    "19_3": ICON_19_3.readall(),
    "19_4": ICON_19_4.readall(),

    #falco
    "20_0": ICON_20_0.readall(),
    "20_1": ICON_20_1.readall(),
    "20_2": ICON_20_2.readall(),
    "20_3": ICON_20_3.readall(),

    #y.link
    "21_0": ICON_21_0.readall(),
    "21_1": ICON_21_1.readall(),
    "21_2": ICON_21_2.readall(),
    "21_3": ICON_21_3.readall(),
    "21_4": ICON_21_4.readall(),

    #dr. mario
    "22_0": ICON_22_0.readall(),
    "22_1": ICON_22_1.readall(),
    "22_2": ICON_22_2.readall(),
    "22_3": ICON_22_3.readall(),
    "22_4": ICON_22_4.readall(),

    #mario
    "23_0": ICON_23_0.readall(),
    "23_1": ICON_23_1.readall(),
    "23_2": ICON_23_2.readall(),
    "23_3": ICON_23_3.readall(),
    "23_4": ICON_23_4.readall(),

    #roy
    "24_0": ICON_24_0.readall(),
    "24_1": ICON_24_1.readall(),
    "24_2": ICON_24_2.readall(),
    "24_3": ICON_24_3.readall(),
    "24_4": ICON_24_4.readall(),

    #pichu
    "25_0": ICON_25_0.readall(),
    "25_1": ICON_25_1.readall(),
    "25_2": ICON_25_2.readall(),
    "25_3": ICON_25_3.readall(),

    #dorf
    "26_0": ICON_26_0.readall(),
    "26_1": ICON_26_1.readall(),
    "26_2": ICON_26_2.readall(),
    "26_3": ICON_26_3.readall(),
    "26_4": ICON_26_4.readall(),
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
    dataCached = cache.get(code)
    data = None

    if dataCached != None:
        print("Hit! Displaying cached data.")
        data = json.decode(dataCached)

        totalTime = dataCached

    else:
        print("Miss! Calling SLP API.")
        GET_URL = CHART_SLP_SERVER_URL + code

        rep = http.get(GET_URL)
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

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(code, json.encode(data), ttl_seconds = 43200)
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
