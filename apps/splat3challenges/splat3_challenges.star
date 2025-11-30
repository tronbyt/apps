"""
Applet: Splat3 Challenges
Summary: Splatoon 3 Challenges
Description: Shows upcoming Challenges in Splatoon 3, their descriptions and modifiers, and the times they start at. Data provided by splatoon3.ink.
Author: MarkGamed7794
"""

# For some reason, the backgound stage images change colour a little bit. Anyone know why this happens?

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/img_1223e945.png", IMG_1223e945_ASSET = "file")
load("images/img_1c185c3c.png", IMG_1c185c3c_ASSET = "file")
load("images/img_1c8630cf.png", IMG_1c8630cf_ASSET = "file")
load("images/img_1d1e5d00.png", IMG_1d1e5d00_ASSET = "file")
load("images/img_264baac6.png", IMG_264baac6_ASSET = "file")
load("images/img_26f3dfb7.png", IMG_26f3dfb7_ASSET = "file")
load("images/img_29c682ff.png", IMG_29c682ff_ASSET = "file")
load("images/img_37173444.png", IMG_37173444_ASSET = "file")
load("images/img_38503e0f.png", IMG_38503e0f_ASSET = "file")
load("images/img_42c1f93b.png", IMG_42c1f93b_ASSET = "file")
load("images/img_45be861c.png", IMG_45be861c_ASSET = "file")
load("images/img_46773268.png", IMG_46773268_ASSET = "file")
load("images/img_4ad14c5e.png", IMG_4ad14c5e_ASSET = "file")
load("images/img_524f7e6c.png", IMG_524f7e6c_ASSET = "file")
load("images/img_54d9e287.png", IMG_54d9e287_ASSET = "file")
load("images/img_6f1e72dd.png", IMG_6f1e72dd_ASSET = "file")
load("images/img_716049a6.png", IMG_716049a6_ASSET = "file")
load("images/img_7a5f54e3.png", IMG_7a5f54e3_ASSET = "file")
load("images/img_7b4345a6.png", IMG_7b4345a6_ASSET = "file")
load("images/img_80951f7b.png", IMG_80951f7b_ASSET = "file")
load("images/img_97dccdc6.png", IMG_97dccdc6_ASSET = "file")
load("images/img_9a84c8a3.png", IMG_9a84c8a3_ASSET = "file")
load("images/img_9fa938d8.png", IMG_9fa938d8_ASSET = "file")
load("images/img_a4e21a11.png", IMG_a4e21a11_ASSET = "file")
load("images/img_ab75d239.png", IMG_ab75d239_ASSET = "file")
load("images/img_b11944e7.png", IMG_b11944e7_ASSET = "file")
load("images/img_b8eb4cb0.png", IMG_b8eb4cb0_ASSET = "file")
load("images/img_bdfcaf6c.png", IMG_bdfcaf6c_ASSET = "file")
load("images/img_c42b8223.png", IMG_c42b8223_ASSET = "file")
load("images/img_cee0f222.png", IMG_cee0f222_ASSET = "file")
load("images/img_e4af894f.png", IMG_e4af894f_ASSET = "file")
load("images/img_ee31aae1.png", IMG_ee31aae1_ASSET = "file")
load("images/img_f32176a7.png", IMG_f32176a7_ASSET = "file")
load("images/img_f46c6046.png", IMG_f46c6046_ASSET = "file")
load("images/img_f5e25add.png", IMG_f5e25add_ASSET = "file")
load("images/img_f6784d84.png", IMG_f6784d84_ASSET = "file")
load("images/img_f797ca58.png", IMG_f797ca58_ASSET = "file")
load("images/img_fdb0c19c.png", IMG_fdb0c19c_ASSET = "file")

DEFAULT_TIMEZONE = "America/New_York"
DEFAULT_LOCATION = """
{
    "lat": "40.6781784",
    "lng": "-73.9441579",
    "description": "Brooklyn, NY, USA",
    "locality": "Brooklyn",
    "place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
    "timezone": "America/New_York"
}
"""

STAGE_IMG = {
    "no_stage": IMG_37173444_ASSET.readall(),
    "Barnacle & Dime": IMG_264baac6_ASSET.readall(),
    "Bluefin Depot": IMG_80951f7b_ASSET.readall(),
    "Brinewater Springs": IMG_97dccdc6_ASSET.readall(),
    "Crableg Capital": IMG_bdfcaf6c_ASSET.readall(),
    "Eeltail Alley": IMG_29c682ff_ASSET.readall(),
    "Flounder Heights": IMG_45be861c_ASSET.readall(),
    "Hagglefish Market": IMG_e4af894f_ASSET.readall(),
    "Hammerhead Bridge": IMG_4ad14c5e_ASSET.readall(),
    "Humpback Pump Track": IMG_7b4345a6_ASSET.readall(),
    "Inkblot Art Academy": IMG_b11944e7_ASSET.readall(),
    "Lemuria Hub": IMG_c42b8223_ASSET.readall(),
    "Mahi-Mahi Resort": IMG_46773268_ASSET.readall(),
    "MakoMart": IMG_ee31aae1_ASSET.readall(),
    "Manta Maria": IMG_fdb0c19c_ASSET.readall(),
    "Marlin Airport": IMG_1c8630cf_ASSET.readall(),
    "Mincemeat Metalworks": IMG_716049a6_ASSET.readall(),
    "Museum d'Alfonsino": IMG_ab75d239_ASSET.readall(),
    "Robo ROM-en": IMG_54d9e287_ASSET.readall(),
    "Scorch Gorge": IMG_38503e0f_ASSET.readall(),
    "Shipshape Cargo Co.": IMG_f5e25add_ASSET.readall(),
    "Sturgeon Shipyard": IMG_a4e21a11_ASSET.readall(),
    "Um'ami Ruins": IMG_b8eb4cb0_ASSET.readall(),
    "Undertow Spillway": IMG_f32176a7_ASSET.readall(),
    "Urchin Underpass": IMG_524f7e6c_ASSET.readall(),
    "Wahoo World": IMG_1223e945_ASSET.readall(),
}

ICONS = {
    # mode icons
    "Turf War": IMG_f46c6046_ASSET.readall(),
    "Rainmaker": IMG_1d1e5d00_ASSET.readall(),
    "Tower Control": IMG_9fa938d8_ASSET.readall(),
    "Splat Zones": IMG_6f1e72dd_ASSET.readall(),
    "Clam Blitz": IMG_1c185c3c_ASSET.readall(),
    "challenge": IMG_7a5f54e3_ASSET.readall(),
}
NUMBERS = [
    IMG_42c1f93b_ASSET.readall(),
    IMG_9a84c8a3_ASSET.readall(),
    IMG_f6784d84_ASSET.readall(),
    IMG_cee0f222_ASSET.readall(),
    IMG_f797ca58_ASSET.readall(),
    IMG_26f3dfb7_ASSET.readall(),
]

# thanks s3.ink!
STAGE_URL = "https://splatoon3.ink/data/schedules.json"

def generateErrorFrame(message):
    return render.Root(
        render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 17,
                    child = render.WrappedText(
                        message,
                        width = 64,
                        align = "center",
                        font = "tom-thumb",
                    ),
                ),
                render.Box(
                    width = 64,
                    height = 3,
                    color = "#000",
                    child = render.Box(
                        width = 64,
                        height = 1,
                        color = "#444",
                    ),
                ),
                render.Box(
                    width = 64,
                    height = 12,
                    child = render.WrappedText(
                        "Report this immediately!",
                        width = 64,
                        align = "center",
                        font = "tom-thumb",
                    ),
                ),
            ],
        ),
    )

def am_or_pm(t):
    # returns "a" or "p"
    return "a" if t.hour < 12 else "p"

def format_time_range(start, end):
    # note: only uses the time from the end time instead of both day and time
    return "%s%s-%s%s" % (start.format("01/02 3"), am_or_pm(start), end.format("3"), am_or_pm(end))

# remove HTML tags and replace with ASCII codes
def strip_tags(s):
    return s.replace("<br />", "\n").replace("—", "--")

def main(config):
    challenge_cache = cache.get("stages")
    challenges = None
    failed = None
    if (challenge_cache != None):
        # Data is cached, just use that
        challenge_cache = json.decode(challenge_cache)
        challenges = challenge_cache
    else:
        # Oh, we need new data
        rep = http.get(STAGE_URL)
        if (rep.status_code != 200):
            failed = rep.status_code or -1
        else:
            stages = rep.json()  # Will it just let me do this?
            challenges = stages["data"]["eventSchedules"]["nodes"]

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set("stages", json.encode(challenges), 3600 * 2)

    if (failed):
        return generateErrorFrame("API error!\nError code %d" % (failed or -1))

    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = loc.get("timezone", time.tz())  # Utilize special timezone variable
    now = time.now().in_location(timezone)

    BG_INFO = int(config.get("bginfo", "3"))

    #challenges = stages["data"]["eventSchedules"]["nodes"]
    closest_challenge = None
    closest_time = None
    closest_period = None
    for challenge in challenges:
        i = 0
        for period in challenge["timePeriods"]:
            i += 1
            if (not closest_time):
                if (time.parse_time(period["endTime"]) >= now):
                    closest_time = time.parse_time(period["endTime"])
                    closest_challenge = challenge
                    closest_period = {
                        "id": i,
                        "active": (time.parse_time(period["startTime"]) <= now) and (time.parse_time(period["endTime"]) >= now),
                        "period": period,
                    }
            elif (time.parse_time(period["endTime"]) < closest_time and time.parse_time(period["endTime"]) >= now):
                closest_time = time.parse_time(period["endTime"])
                closest_challenge = challenge
                closest_period = {
                    "id": i,
                    "active": time.parse_time(period["startTime"]) <= now,
                    "period": period,
                }

    if (not closest_challenge):
        return []

    # only one frame; we don't need to do any funny switching

    #print(closest_challenge)
    shown_challenge = {
        "name": strip_tags(closest_challenge["leagueMatchSetting"]["leagueMatchEvent"]["name"]),
        "desc": strip_tags(closest_challenge["leagueMatchSetting"]["leagueMatchEvent"]["regulation"]),
    }

    # generate a pretty description
    desc_elements = []
    desc_partition = shown_challenge["desc"].partition("・")
    desc_body, desc_stipulations = desc_partition[0].rstrip("\n"), (desc_partition[1] + desc_partition[2]).replace("・", "-").split("\n")

    # tagline
    desc_elements.append(
        render.Padding(
            pad = 1,
            child = render.WrappedText(
                closest_challenge["leagueMatchSetting"]["leagueMatchEvent"]["desc"],
                color = "#ff4",
                font = "tom-thumb",
            ),
        ),
    )

    # main body
    desc_elements.append(
        render.Padding(
            pad = 1,
            child = render.WrappedText(
                desc_body,
                color = "#fff",
                font = "tom-thumb",
            ),
        ),
    )

    # stipulations
    for stipulation in desc_stipulations:
        desc_elements.append(
            render.Padding(
                pad = 1,
                child = render.WrappedText(
                    stipulation,
                    color = "#aaa",
                    font = "tom-thumb",
                ),
            ),
        )

    body_stack = []
    if (BG_INFO & 2):
        stage_a = closest_challenge["leagueMatchSetting"]["vsStages"][0]["name"]
        stage_b = closest_challenge["leagueMatchSetting"]["vsStages"][1]["name"]
        body_stack.append(
            render.Row(
                children = [
                    render.Padding(
                        pad = (0, 1, 1, 0),
                        child = render.Image(STAGE_IMG[stage_a if stage_a in STAGE_IMG else "no_stage"]),
                    ),
                    render.Padding(
                        pad = (1, 1, 0, 0),
                        child = render.Image(STAGE_IMG[stage_b if stage_b in STAGE_IMG else "no_stage"]),
                    ),
                ],
            ),
        )
    if (BG_INFO == 3):
        body_stack.append(
            render.Box(
                height = 18,
                color = config.get("imgbrightness", "#0006"),
            ),
        )
    if (BG_INFO & 1):
        body_stack.append(
            render.Marquee(
                height = 18,
                offset_start = 18,  # start off screen
                offset_end = 17,  # end just as the text goes offscreen (instead of when it hits the header)
                scroll_direction = "vertical",
                child = render.Column(desc_elements),
            ),
        )

    return render.Root(
        delay = int(1000 / (7 * float(config.get("scrollspeed", "1")))),  # (7 px * scroll speed) / sec
        show_full_animation = True,
        child = render.Column(
            children = [
                # header
                render.Box(
                    color = "#b0b",
                    height = 7,
                    child = render.Padding(
                        pad = (1, 0, 0, 0),
                        child = render.Row(
                            children = [
                                render.Image(ICONS["challenge"]),
                                render.Padding(
                                    pad = 1,
                                    child = render.Marquee(
                                        width = 57,
                                        offset_start = 57,  # start off screen
                                        offset_end = 56,  # end before it comes back on screen
                                        child = render.Text(
                                            shown_challenge["name"],
                                            font = "CG-pixel-3x5-mono",
                                        ),
                                    ),
                                ),
                            ],
                        ),
                    ),
                ),
                # body
                render.Stack(
                    body_stack,
                ),
                # footer
                render.Box(
                    color = "#282" if closest_period["active"] else "#444",
                    height = 7,
                    child = render.Padding(
                        pad = (1, 0, 0, 0),
                        child = render.Row(
                            children = [
                                render.Stack(
                                    [
                                        render.Padding(
                                            pad = (3, 0, 0, 0),
                                            child = render.Image(ICONS[closest_challenge["leagueMatchSetting"]["vsRule"]["name"]]),
                                        ),
                                        render.Image(NUMBERS[closest_period["id"] - 1]),
                                    ],
                                ),
                                render.Padding(
                                    pad = 1,
                                    child = render.Text(
                                        format_time_range(time.parse_time(closest_period["period"]["startTime"]).in_location(timezone), time.parse_time(closest_period["period"]["endTime"]).in_location(timezone)),
                                        font = "tom-thumb",
                                    ),
                                ),
                            ],
                        ),
                    ),
                ),
            ],
        ),
    )

def brightness_schema(val):
    brightnessOptions = [
        schema.Option(
            display = "1 (darkest)",
            value = "#000d",
        ),
        schema.Option(
            display = "2",
            value = "#000b",
        ),
        schema.Option(
            display = "3",
            value = "#0009",
        ),
        schema.Option(
            display = "4",
            value = "#0007",
        ),
        schema.Option(
            display = "5 (brightest)",
            value = "#0005",
        ),
    ]
    if (val != "3"):
        return []
    return [schema.Dropdown(
        id = "imgbrightness",
        name = "Image Opacity",
        desc = "The opacity of the background stage images.",
        icon = "paintRoller",
        default = brightnessOptions[0].value,
        options = brightnessOptions,
    )]

def get_schema():
    bgOptions = [
        schema.Option(
            display = "Images + Description",
            value = "3",
        ),
        schema.Option(
            display = "Images Only",
            value = "2",
        ),
        schema.Option(
            display = "Description Only",
            value = "1",
        ),
    ]
    scrollSpeedOptions = [
        schema.Option(
            display = "Slowest",
            value = "0.5",
        ),
        schema.Option(
            display = "Slow",
            value = "0.75",
        ),
        schema.Option(
            display = "Medium",
            value = "1",
        ),
        schema.Option(
            display = "Fast",
            value = "1.3",
        ),
        schema.Option(
            display = "Fastest",
            value = "1.75",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "The location to display the time from.",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "bginfo",
                name = "Body Information",
                desc = "Whether to show the stage images, the challenge description, or both.",
                icon = "bars",
                default = bgOptions[0].value,
                options = bgOptions,
            ),
            schema.Dropdown(
                id = "scrollspeed",
                name = "Scroll Speed",
                desc = "The speed information scrolls at.",
                icon = "bars",
                default = scrollSpeedOptions[2].value,
                options = scrollSpeedOptions,
            ),
            schema.Generated(
                id = "genbright",
                source = "bginfo",
                handler = brightness_schema,
            ),
        ],
    )
