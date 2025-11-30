"""
Applet: Splatoon 3 Stages
Summary: Splatoon 3 map rotations
Description: Fetches and shows the current Splatoon 3 map rotations. Data provided by splatoon3.ink.
Author: MarkGamed7794
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/img_1223e945.png", IMG_1223e945_ASSET = "file")
load("images/img_1c8630cf.png", IMG_1c8630cf_ASSET = "file")
load("images/img_264baac6.png", IMG_264baac6_ASSET = "file")
load("images/img_29c682ff.png", IMG_29c682ff_ASSET = "file")
load("images/img_3002522d.png", IMG_3002522d_ASSET = "file")
load("images/img_32f24af5.png", IMG_32f24af5_ASSET = "file")
load("images/img_37173444.png", IMG_37173444_ASSET = "file")
load("images/img_38503e0f.png", IMG_38503e0f_ASSET = "file")
load("images/img_45be861c.png", IMG_45be861c_ASSET = "file")
load("images/img_46773268.png", IMG_46773268_ASSET = "file")
load("images/img_4ad14c5e.png", IMG_4ad14c5e_ASSET = "file")
load("images/img_524f7e6c.png", IMG_524f7e6c_ASSET = "file")
load("images/img_54d9e287.png", IMG_54d9e287_ASSET = "file")
load("images/img_716049a6.png", IMG_716049a6_ASSET = "file")
load("images/img_7b4345a6.png", IMG_7b4345a6_ASSET = "file")
load("images/img_80951f7b.png", IMG_80951f7b_ASSET = "file")
load("images/img_912f6184.png", IMG_912f6184_ASSET = "file")
load("images/img_97dccdc6.png", IMG_97dccdc6_ASSET = "file")
load("images/img_9988b66f.png", IMG_9988b66f_ASSET = "file")
load("images/img_9f1de678.png", IMG_9f1de678_ASSET = "file")
load("images/img_a4e21a11.png", IMG_a4e21a11_ASSET = "file")
load("images/img_a8dce8f7.png", IMG_a8dce8f7_ASSET = "file")
load("images/img_ab75d239.png", IMG_ab75d239_ASSET = "file")
load("images/img_b11944e7.png", IMG_b11944e7_ASSET = "file")
load("images/img_b8eb4cb0.png", IMG_b8eb4cb0_ASSET = "file")
load("images/img_bdfcaf6c.png", IMG_bdfcaf6c_ASSET = "file")
load("images/img_c171d3fa.png", IMG_c171d3fa_ASSET = "file")
load("images/img_c42b8223.png", IMG_c42b8223_ASSET = "file")
load("images/img_e4af894f.png", IMG_e4af894f_ASSET = "file")
load("images/img_e85ab87d.png", IMG_e85ab87d_ASSET = "file")
load("images/img_ee31aae1.png", IMG_ee31aae1_ASSET = "file")
load("images/img_f32176a7.png", IMG_f32176a7_ASSET = "file")
load("images/img_f5e25add.png", IMG_f5e25add_ASSET = "file")
load("images/img_fdb0c19c.png", IMG_fdb0c19c_ASSET = "file")

# thanks s3.ink!
STAGE_URL = "https://splatoon3.ink/data/schedules.json"

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

SALMON_STAGE_IMG = {
    "Bonerattle Arena": IMG_9f1de678_ASSET.readall(),
    "Gone Fission Hydroplant": IMG_32f24af5_ASSET.readall(),
    "Grand Splatlands Bowl": IMG_c171d3fa_ASSET.readall(),
    "Marooner's Bay": IMG_e85ab87d_ASSET.readall(),
    "Jammin' Salmon Junction": IMG_a8dce8f7_ASSET.readall(),
    "Sockeye Station": IMG_3002522d_ASSET.readall(),
    "Spawning Grounds": IMG_912f6184_ASSET.readall(),
    "Salmonid Smokeyard": IMG_9988b66f_ASSET.readall(),
}

ICONS = {
}

BATTLE_TYPES = {
    "regular": struct(title = "Regular Battle", colours = ["#080"]),
    "series": struct(title = "Anarchy Series", colours = ["#850"]),
    "open": struct(title = "Anarchy Open", colours = ["#820"]),
    "x": struct(title = "X Battle", colours = ["#086"]),
    "salmon": struct(title = "Salmon Run", colours = ["#740"]),
    "eggstra": struct(title = "Eggstra Work", colours = ["#880"]),
    "bigrun": struct(title = "Big Run", colours = ["#408"]),
    "festopen": struct(title = "Splatfest Battle", colours = []),
    "festpro": struct(title = "Splatfest Battle", colours = []),
}

# ------------ DATA PROCESSING ------------ #

def parseMatchSetting(setting):
    # Container for gamemode and stages

    return struct(
        type = setting["__typename"],
        stages = [stage["name"] for stage in setting["vsStages"]],  # becomes a list of strings
        rule = setting["vsRule"]["name"],
        ranked_type = None if "bankaraMode" not in setting else setting["bankaraMode"],
        fest_type = None if "festMode" not in setting else setting["festMode"],
    )

def parseMatch(match, key):
    # Container for start/end times of a regular match setting

    # Keys:
    # Regular -> regularMatchSetting
    # Ranked  -> bankaraMatchSettings
    # X       -> xMatchSetting
    # Fest    -> festMatchSettings
    # Salmon  -> setting

    setting, open_setting, pro_setting = None, None, None

    if (match[key]):
        if (key == "bankaraMatchSettings" or key == "festMatchSettings"):
            # Special case for Ranked
            for schedule in [parseMatchSetting(setting) for setting in match[key]]:
                # Overengineered? Yes. Works? Yes.
                if (schedule.ranked_type == "CHALLENGE" or schedule.fest_type == "CHALLENGE"):
                    pro_setting = schedule
                elif (schedule.ranked_type == "OPEN" or schedule.fest_type == "REGULAR"):  # OPEN for ranked
                    open_setting = schedule
        else:
            setting = parseMatchSetting(match[key])
    else:
        # Key does not exist; return None
        return None

    # The times are not parsed since that prevents serialization
    return struct(
        start_time = match["startTime"],
        end_time = match["endTime"],
        setting = setting,
        open_setting = open_setting,
        series_setting = pro_setting,
    )

def parseTimetableEntry(entry):
    # This has only been used for Tricolor stages during the Grand Fest.
    # I don't know why they changed it. Was it just to make my life harder?

    return struct(
        start_time = entry["startTime"],
        end_time = entry["endTime"],
        tricolor_stage = entry["festMatchSettings"][0]["vsStages"][0]["name"],
    )

def parseSalmonRunMatchSetting(setting):
    return struct(
        boss = (setting["boss"]["name"] if setting["boss"] else "(no boss)"),
        stage = setting["coopStage"]["name"],
        weapons = [struct(name = weapon["name"], img = weapon["image"]["url"]) for weapon in setting["weapons"]],
    )

def parseSalmonRunMatch(match):
    # Salmon Run is different enough that this is more practical
    return struct(
        start_time = match["startTime"],
        end_time = match["endTime"],
        setting = parseSalmonRunMatchSetting(match["setting"]),
    )

def parseJSONResponse(resp):
    # Takes in the raw JSON response from the server and organizes it into lists of matches.

    # List comprehensions my beloved
    return struct(
        regular = [parseMatch(match, "regularMatchSetting") for match in resp["data"]["regularSchedules"]["nodes"]],
        ranked = [parseMatch(match, "bankaraMatchSettings") for match in resp["data"]["bankaraSchedules"]["nodes"]],
        x = [parseMatch(match, "xMatchSetting") for match in resp["data"]["xSchedules"]["nodes"]],
        fest = [parseMatch(match, "festMatchSettings") for match in resp["data"]["festSchedules"]["nodes"]],
        salmon = [parseSalmonRunMatch(match) for match in resp["data"]["coopGroupingSchedule"]["regularSchedules"]["nodes"]],
        bigrun = [parseSalmonRunMatch(match) for match in resp["data"]["coopGroupingSchedule"]["bigRunSchedules"]["nodes"]],
        eggstra = [parseSalmonRunMatch(match) for match in resp["data"]["coopGroupingSchedule"]["teamContestSchedules"]["nodes"]],
    )

def getCurrentMatch(matches, now):
    # Returns the currently scheduled match out of a list.
    for match in matches:
        if (not match):
            continue
        if (time.parse_time(match.start_time) <= now and now <= time.parse_time(match.end_time)):
            return match
    return struct(
        setting = None,
        series_setting = None,
        open_setting = None,
    )

# ------------ RENDERING ------------ #

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

def generateGeneralFrame(header_text, header_colours, img_a, img_b, footer, weapon_urls = None, tricol_text = None):
    # Generates the standardized frame format.

    # If the given colours can't be divided evenly across the header, bias some of them to fit the full 64px
    width_biases = [0 for c in header_colours]
    center = len(header_colours) // 2
    required_biases = 64 % len(header_colours)
    for i in range(center - math.floor(required_biases / 2.0), center + math.floor(required_biases / 2.0) + 1):
        width_biases[i] = 1

    header = render.Stack(
        [
            render.Row(
                # I can't do list comprehensions by index, so I just keep popping the biases list instead
                [render.Box(width = 64 // len(header_colours) + width_biases.pop(0), height = 7, color = c) for c in header_colours],
            ),
            render.Box(
                height = 7,
                child = render.Padding(
                    pad = (0, 1, 0, 0),
                    child = render.Text(
                        header_text,
                        font = "tom-thumb",
                        color = "#fff",
                    ),
                ),
            ),
        ],
    )

    # Images, or Salmon Run icons
    images = None
    if (weapon_urls):
        weapon_images = [loadImage(img.img) for img in weapon_urls]
        images = render.Row(
            [
                # Weapons
                render.Column(
                    [
                        render.Padding(
                            render.Row(weapon_images[0:2]),
                            pad = (0, 0, 4, 0),
                        ),
                        render.Padding(
                            render.Row(weapon_images[2:4]),
                            pad = (4, 0, 0, 0),
                        ),
                    ],
                ),
                # Stage
                render.Padding(
                    render.Image(SALMON_STAGE_IMG[img_a] if img_a in SALMON_STAGE_IMG else STAGE_IMG["no_stage"]),
                    pad = (1, 1, 0, 1),
                ),
            ],
        )
    else:
        render_img_a = render.Image(STAGE_IMG[img_a if img_a in STAGE_IMG else "no_stage"])
        render_img_b = None
        if (tricol_text):
            render_img_b = render.Box(
                width = 31,
                height = 17,
                child = render.WrappedText(
                    tricol_text,
                    width = 31,
                    color = "#88f",
                    font = "tom-thumb",
                ),
            )
        else:
            render_img_b = render.Image(STAGE_IMG[img_b if img_b in STAGE_IMG else "no_stage"])

        images = render.Padding(
            render.Row(
                [
                    render_img_a,
                    render.Box(width = 2, height = 2),
                    render_img_b,
                ],
            ),
            pad = (0, 1, 0, 1),
        )

    # Footer
    footer = render.Box(
        height = 7,
        child = render.Text(
            footer,
            font = "tom-thumb",
            color = "#fff",
        ),
    )

    return render.Column([header, images, footer])

def loadImage(url):
    IMG_SIZE = 14
    BOX_SIZE = 9
    req = http.get(url)

    if (req.status_code != 200):
        # Should never happen but just in case
        # TODO: replace with better icon
        return render.Box(width = IMG_SIZE, height = BOX_SIZE, child = render.Image(STAGE_IMG["no_stage"], width = IMG_SIZE, height = IMG_SIZE))

    # Bad cropping is still cropping
    return render.Box(width = IMG_SIZE, height = BOX_SIZE, child = render.Image(req.body(), width = IMG_SIZE, height = IMG_SIZE))

def generateFrame(battle, battle_type, extra):
    # Takes a specified title, header colour, and battle and returns the prettified frame.

    colour_scheme = BATTLE_TYPES[battle_type]
    if (not battle):
        # Fallback
        return generateGeneralFrame(colour_scheme.title, colour_scheme.colours, "no_stage", "no_stage", "No current data!")

    # Regular/Anarchy/X
    if (battle_type == "regular" or battle_type == "series" or battle_type == "open" or battle_type == "x"):
        return generateGeneralFrame(colour_scheme.title, colour_scheme.colours, battle.stages[0], battle.stages[1], battle.rule)

    # Splatfest
    if (battle_type == "festopen"):
        return generateGeneralFrame(colour_scheme.title, extra, battle.stages[0], battle.stages[1], battle.rule + " (Open)")
    if (battle_type == "festpro"):
        return generateGeneralFrame(colour_scheme.title, extra, battle.stages[0], battle.stages[1], battle.rule + " (Pro)")

    # Salmon
    if (battle_type == "salmon"):
        return generateGeneralFrame(colour_scheme.title, colour_scheme.colours, battle.stage, None, battle.boss, battle.weapons)

    if (battle_type == "eggstra" or battle_type == "bigrun"):
        end_time = getDurationString(extra)
        return generateGeneralFrame(colour_scheme.title, colour_scheme.colours, battle.stage, None, "Ends in " + end_time, battle.weapons)

    return generateGeneralFrame("Unknown", ["#888"], "no_stage", "no_stage", "type? " + battle_type)

def rgb2hex(array):
    return "#%x%x%x%x%x%x" % (int(array[0]) // 16, int(array[0]) % 16, int(array[1]) // 16, int(array[1]) % 16, int(array[2]) // 16, int(array[2]) % 16)

def getDurationString(duration):
    days = duration // (24 * time.hour)
    hours = (duration - days * 24 * time.hour) // (1 * time.hour)
    minutes = (duration - hours * time.hour - days * 24 * time.hour) // time.minute

    if (days > 0):
        return "%dd %dh" % (days, hours)

    if (hours > 0):
        return "%dh %dm" % (hours, minutes)

    return "%dm" % minutes

def main(config):
    stage_cache = cache.get("stages")
    stages = None
    failed = None
    if (stage_cache != None):
        # Data is cached, just use that
        stages = json.decode(stage_cache)
    else:
        # Oh, we need new data
        rep = http.get(STAGE_URL)
        if (rep.status_code != 200):
            failed = rep.status_code or -1
        else:
            stages = rep.json()  # Will it just let me do this?

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set("stages", json.encode(stages), 3600 * 2)

    if (failed):
        return generateErrorFrame("API error!\nError code %d" % (failed or -1))

    parsed_data = parseJSONResponse(stages)

    # Make the data better
    splatfest = None
    splatfest_colours = []

    now = time.now()

    if (stages["data"]["festSchedules"] and stages["data"]["currentFest"]):
        use_timetable = len(stages["data"]["currentFest"].get("timetable") or []) > 0
        if (now >= time.parse_time(stages["data"]["currentFest"]["startTime"]) and now <= time.parse_time(stages["data"]["currentFest"]["endTime"])):
            teams = stages["data"]["currentFest"]["teams"]

            if (use_timetable):
                tricol_timetable = [parseTimetableEntry(entry) for entry in stages["data"]["currentFest"]["timetable"]]
                tricol_stage = getCurrentMatch(tricol_timetable, now).tricolor_stage
            else:
                tricol_stage = stages["data"]["currentFest"]["tricolorStages"][0]["name"]

            splatfest_colours = [
                rgb2hex([teams[0]["color"]["r"] * 150, teams[0]["color"]["g"] * 150, teams[0]["color"]["b"] * 150]),
                rgb2hex([teams[1]["color"]["r"] * 150, teams[1]["color"]["g"] * 150, teams[1]["color"]["b"] * 150]),
                rgb2hex([teams[2]["color"]["r"] * 150, teams[2]["color"]["g"] * 150, teams[2]["color"]["b"] * 150]),
            ]

            splatfest = struct(
                tricolor_stage = tricol_stage,
                start_time = time.parse_time(stages["data"]["currentFest"]["startTime"]),
                halftime = time.parse_time(stages["data"]["currentFest"]["midtermTime"]),
                end_time = time.parse_time(stages["data"]["currentFest"]["endTime"]),
                colours = splatfest_colours,
            )

    eggstra_on = False
    big_run_on = False
    if (len(parsed_data.eggstra) > 0):  # TODO: See if there's a better way to detect this
        eggstra_on = True
    if (len(parsed_data.bigrun) > 0):  # TODO: See if there's a better way to detect this
        big_run_on = True

    frames = {
        "regular": generateFrame(getCurrentMatch(parsed_data.regular, now).setting, "regular", None),
        "series": generateFrame(getCurrentMatch(parsed_data.ranked, now).series_setting, "series", None),
        "open": generateFrame(getCurrentMatch(parsed_data.ranked, now).open_setting, "open", None),
        "x": generateFrame(getCurrentMatch(parsed_data.x, now).setting, "x", None),
        "salmon": generateFrame(getCurrentMatch(parsed_data.salmon, now).setting, "salmon", None),
    }
    if (eggstra_on):
        current_match = getCurrentMatch(parsed_data.eggstra, now)
        if (current_match.setting):
            frames["eggstra"] = generateFrame(current_match.setting, "eggstra", time.parse_time(current_match.end_time) - now)
        else:
            eggstra_on = False

    if (big_run_on):
        current_match = getCurrentMatch(parsed_data.bigrun, now)
        if (current_match.setting):
            frames["bigrun"] = generateFrame(current_match.setting, "bigrun", time.parse_time(current_match.end_time) - now)
        else:
            big_run_on = False

    if (splatfest):
        frames["festopen"] = generateFrame(getCurrentMatch(parsed_data.fest, now).open_setting, "festopen", splatfest_colours)
        frames["festpro"] = generateFrame(getCurrentMatch(parsed_data.fest, now).series_setting, "festpro", splatfest_colours)

        bottom_str = "?"
        if (now < splatfest.halftime):
            time_diff = splatfest.halftime - now
            bottom_str = "Halftime starts: " + getDurationString(time_diff)
        elif (now < splatfest.end_time):
            time_diff = splatfest.end_time - now
            bottom_str = "Fest ends in: " + getDurationString(time_diff)
        else:
            bottom_str = "Fest ends soon!"

        frames["tricolor"] = generateGeneralFrame("Tricolor Battle", splatfest_colours, splatfest.tricolor_stage, None, "Tricol. Turf War", None, bottom_str)

    render_frames = []
    if (not splatfest):
        if (config.bool("show_regular")):
            render_frames.append(frames["regular"])
        if (config.bool("show_series")):
            render_frames.append(frames["series"])
        if (config.bool("show_open")):
            render_frames.append(frames["open"])
        if (config.bool("show_x")):
            render_frames.append(frames["x"])
        if (config.bool("show_salmon")):
            if (big_run_on):
                render_frames.append(frames["bigrun"])
            else:
                render_frames.append(frames["salmon"])
        if (config.bool("show_eggstra") and eggstra_on):
            render_frames.append(frames["eggstra"])

        if (len(render_frames) == 0):
            render_frames.append(frames["regular"])
    else:
        if (config.bool("show_fest_open")):
            render_frames.append(frames["festopen"])
        if (config.bool("show_fest_pro")):
            render_frames.append(frames["festpro"])
        if (config.bool("show_tricolor")):
            render_frames.append(frames["tricolor"])
        if (config.bool("show_salmon")):
            render_frames.append(frames["salmon"])
        if (config.bool("show_eggstra") and eggstra_on):
            render_frames.append(frames["eggstra"])

        if (len(render_frames) == 0):
            render_frames.append(frames["festopen"])

    anim_length = int(config.str("speed") or 15000)
    return render.Root(
        delay = int(anim_length / len(render_frames)),
        child = render.Animation(render_frames),
    )

def get_schema():
    speed_options = [
        schema.Option(
            display = "Normal",
            value = "15000",
        ),
        schema.Option(
            display = "Quick",
            value = "10000",
        ),
        schema.Option(
            display = "Turbo",
            value = "7500",
        ),
        schema.Option(
            display = "Plaid",
            value = "5000",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "speed",
                name = "Animation Speed",
                desc = "Match this with the Tidbyt app cycle speed to ensure that the stage rotations take the whole length of time the app is shown.",
                icon = "stopwatch",
                default = speed_options[0].value,
                options = speed_options,
            ),
            schema.Toggle(
                id = "show_regular",
                name = "Regular Battle",
                desc = "Whether or not to include Regular Battles in the rotation.",
                icon = "paintRoller",
                default = True,
            ),
            schema.Toggle(
                id = "show_series",
                name = "Anarchy (Series)",
                desc = "Whether or not to include Series Anarchy Battles in the rotation.",
                icon = "signal",
                default = True,
            ),
            schema.Toggle(
                id = "show_open",
                name = "Anarchy (Open)",
                desc = "Whether or not to include Open Anarchy Battles in the rotation.",
                icon = "tableTennisPaddleBall",
                default = True,
            ),
            schema.Toggle(
                id = "show_x",
                name = "X Battle",
                desc = "Whether or not to include X Battles in the rotation.",
                icon = "x",
                default = False,
            ),
            schema.Toggle(
                id = "show_salmon",
                name = "Salmon Run",
                desc = "Whether or not to include Salmon Run rotations in the rotation.",
                icon = "fish",
                default = False,
            ),
            schema.Toggle(
                id = "show_eggstra",
                name = "Eggstra Work",
                desc = "Whether or not to include Eggstra Work rotations in the rotation.",
                icon = "fishFins",
                default = False,
            ),
            schema.Toggle(
                id = "show_fest_open",
                name = "Splatfest (Open)",
                desc = "Whether or not to include Open Splatfest Battles in the rotation during a Splatfest.",
                icon = "gift",
                default = False,
            ),
            schema.Toggle(
                id = "show_fest_pro",
                name = "Splatfest (Pro)",
                desc = "Whether or not to include Pro Splatfest Battles in the rotation during a Splatfest.",
                icon = "barsProgress",
                default = False,
            ),
            schema.Toggle(
                id = "show_tricolor",
                name = "Splatfest (Tricolor)",
                desc = "Whether or not to include Tricolor Battles in the rotation during a Splatfest.",
                icon = "shapes",
                default = False,
            ),
        ],
    )
