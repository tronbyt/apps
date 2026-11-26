"""
Applet: TiddlySynth
Summary: Pixel art synths
Description: Adorn your Tidbyt with an array of animated retro synths. Most of the classics are here, plus an evolving selection of wacky fantasy music making devices.
Author: Owain Rich
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/failsafe_image.png", FAILSAFE_IMAGE_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

FAILSAFE_IMAGE = FAILSAFE_IMAGE_ASSET.readall()

jsonUrl = "https://www.fourontuesday.com/tidbyt/synths/synths.json"

DEFAULT_TYPE = "all"

#this image will be rendered if we can't reach the server to parse json

jsonData = False

def main(config):
    synthType = config.get("SynthSelector", DEFAULT_TYPE)
    jsonData = getJsonData()
    synth = ""
    if jsonData != False:
        if synthType == "classic":
            synth = parseClassicSynth()
        if synthType == "fantasy":
            synth = parseFantasySynth()
        if synthType == "all":
            randomNumber = random.number(0, 1)
            if randomNumber == 0:
                synth = parseClassicSynth()
            if randomNumber == 1:
                synth = parseFantasySynth()
        synthData = http.get(synth)
        theSynth = synthData.body()
    else:
        theSynth = FAILSAFE_IMAGE
    return render.Root(
        render.Image(src = theSynth),
    )

#go and get json data and cache for 10 mins
def getJsonData():
    res = http.get(jsonUrl, ttl_seconds = 600)
    if res.status_code != 200:
        #fail("status %d from %s: %s" % (res.status_code, jsonUrl, res.body()))
        print("failed to get json data - using failsafe image instead!")
        return False
    else:
        jsonData = res.body()
        return jsonData

def parseClassicSynth():
    jsonData = getJsonData()
    jsonFeed = json.decode(jsonData)["classics"]
    randomIndex = random.number(0, len(jsonFeed) - 1)
    jsonItem = jsonFeed[randomIndex]
    classicSynth = jsonItem["url"]
    return classicSynth

def parseFantasySynth():
    jsonData = getJsonData()
    jsonFeed = json.decode(jsonData)["fantasy"]
    randomIndex = random.number(0, len(jsonFeed) - 1)
    jsonItem = jsonFeed[randomIndex]
    fantasySynth = jsonItem["url"]
    return fantasySynth

def get_schema():
    synthoptions = [
        schema.Option(
            display = "Classic Synths",
            value = "classic",
        ),
        schema.Option(
            display = "Fantasy Synths",
            value = "fantasy",
        ),
        schema.Option(
            display = "Classic and Fantasy",
            value = "all",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "SynthSelector",
                name = "Synths",
                desc = "Select what synths you want to see.",
                icon = "gaugeHigh",
                default = "all",
                options = synthoptions,
            ),
        ],
    )
