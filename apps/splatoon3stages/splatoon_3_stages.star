"""
Applet: Splatoon 3 Stages
Summary: Splatoon 3 map rotations
Description: Fetches and shows the current Splatoon 3 map rotations. Data provided by splatoon3.ink.
Author: MarkGamed7794
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/salmon_stage_bonerattle_arena.png", SALMON_STAGE_BONERATTLE_ARENA_ASSET = "file")
load("images/salmon_stage_gone_fission_hydroplant.png", SALMON_STAGE_GONE_FISSION_HYDROPLANT_ASSET = "file")
load("images/salmon_stage_grand_splatlands_bowl.png", SALMON_STAGE_GRAND_SPLATLANDS_BOWL_ASSET = "file")
load("images/salmon_stage_jammin__salmon_junction.png", SALMON_STAGE_JAMMIN_SALMON_JUNCTION_ASSET = "file")
load("images/salmon_stage_marooner_s_bay.png", SALMON_STAGE_MAROONER_S_BAY_ASSET = "file")
load("images/salmon_stage_salmonid_smokeyard.png", SALMON_STAGE_SALMONID_SMOKEYARD_ASSET = "file")
load("images/salmon_stage_sockeye_station.png", SALMON_STAGE_SOCKEYE_STATION_ASSET = "file")
load("images/salmon_stage_spawning_grounds.png", SALMON_STAGE_SPAWNING_GROUNDS_ASSET = "file")
load("images/stage_barnacle___dime.png", STAGE_BARNACLE__DIME_ASSET = "file")
load("images/stage_bluefin_depot.png", STAGE_BLUEFIN_DEPOT_ASSET = "file")
load("images/stage_brinewater_springs.png", STAGE_BRINEWATER_SPRINGS_ASSET = "file")
load("images/stage_crableg_capital.png", STAGE_CRABLEG_CAPITAL_ASSET = "file")
load("images/stage_eeltail_alley.png", STAGE_EELTAIL_ALLEY_ASSET = "file")
load("images/stage_flounder_heights.png", STAGE_FLOUNDER_HEIGHTS_ASSET = "file")
load("images/stage_hagglefish_market.png", STAGE_HAGGLEFISH_MARKET_ASSET = "file")
load("images/stage_hammerhead_bridge.png", STAGE_HAMMERHEAD_BRIDGE_ASSET = "file")
load("images/stage_humpback_pump_track.png", STAGE_HUMPBACK_PUMP_TRACK_ASSET = "file")
load("images/stage_inkblot_art_academy.png", STAGE_INKBLOT_ART_ACADEMY_ASSET = "file")
load("images/stage_lemuria_hub.png", STAGE_LEMURIA_HUB_ASSET = "file")
load("images/stage_mahi_mahi_resort.png", STAGE_MAHI_MAHI_RESORT_ASSET = "file")
load("images/stage_makomart.png", STAGE_MAKOMART_ASSET = "file")
load("images/stage_manta_maria.png", STAGE_MANTA_MARIA_ASSET = "file")
load("images/stage_marlin_airport.png", STAGE_MARLIN_AIRPORT_ASSET = "file")
load("images/stage_mincemeat_metalworks.png", STAGE_MINCEMEAT_METALWORKS_ASSET = "file")
load("images/stage_museum_d_alfonsino.png", STAGE_MUSEUM_D_ALFONSINO_ASSET = "file")
load("images/stage_robo_rom_en.png", STAGE_ROBO_ROM_EN_ASSET = "file")
load("images/stage_scorch_gorge.png", STAGE_SCORCH_GORGE_ASSET = "file")
load("images/stage_shipshape_cargo_co.png", STAGE_SHIPSHAPE_CARGO_CO_ASSET = "file")
load("images/stage_sturgeon_shipyard.png", STAGE_STURGEON_SHIPYARD_ASSET = "file")
load("images/stage_um_ami_ruins.png", STAGE_UM_AMI_RUINS_ASSET = "file")
load("images/stage_undertow_spillway.png", STAGE_UNDERTOW_SPILLWAY_ASSET = "file")
load("images/stage_unknown.png", STAGE_UNKNOWN_ASSET = "file")
load("images/stage_urchin_underpass.png", STAGE_URCHIN_UNDERPASS_ASSET = "file")
load("images/stage_wahoo_world.png", STAGE_WAHOO_WORLD_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# thanks s3.ink!
STAGE_URL = "https://splatoon3.ink/data/schedules.json"

STAGE_IMG = {
    "no_stage": STAGE_UNKNOWN_ASSET.readall(),
    "Barnacle & Dime": STAGE_BARNACLE__DIME_ASSET.readall(),
    "Bluefin Depot": STAGE_BLUEFIN_DEPOT_ASSET.readall(),
    "Brinewater Springs": STAGE_BRINEWATER_SPRINGS_ASSET.readall(),
    "Crableg Capital": STAGE_CRABLEG_CAPITAL_ASSET.readall(),
    "Eeltail Alley": STAGE_EELTAIL_ALLEY_ASSET.readall(),
    "Flounder Heights": STAGE_FLOUNDER_HEIGHTS_ASSET.readall(),
    "Hagglefish Market": STAGE_HAGGLEFISH_MARKET_ASSET.readall(),
    "Hammerhead Bridge": STAGE_HAMMERHEAD_BRIDGE_ASSET.readall(),
    "Humpback Pump Track": STAGE_HUMPBACK_PUMP_TRACK_ASSET.readall(),
    "Inkblot Art Academy": STAGE_INKBLOT_ART_ACADEMY_ASSET.readall(),
    "Lemuria Hub": STAGE_LEMURIA_HUB_ASSET.readall(),
    "Mahi-Mahi Resort": STAGE_MAHI_MAHI_RESORT_ASSET.readall(),
    "MakoMart": STAGE_MAKOMART_ASSET.readall(),
    "Manta Maria": STAGE_MANTA_MARIA_ASSET.readall(),
    "Marlin Airport": STAGE_MARLIN_AIRPORT_ASSET.readall(),
    "Mincemeat Metalworks": STAGE_MINCEMEAT_METALWORKS_ASSET.readall(),
    "Museum d'Alfonsino": STAGE_MUSEUM_D_ALFONSINO_ASSET.readall(),
    "Robo ROM-en": STAGE_ROBO_ROM_EN_ASSET.readall(),
    "Scorch Gorge": STAGE_SCORCH_GORGE_ASSET.readall(),
    "Shipshape Cargo Co.": STAGE_SHIPSHAPE_CARGO_CO_ASSET.readall(),
    "Sturgeon Shipyard": STAGE_STURGEON_SHIPYARD_ASSET.readall(),
    "Um'ami Ruins": STAGE_UM_AMI_RUINS_ASSET.readall(),
    "Undertow Spillway": STAGE_UNDERTOW_SPILLWAY_ASSET.readall(),
    "Urchin Underpass": STAGE_URCHIN_UNDERPASS_ASSET.readall(),
    "Wahoo World": STAGE_WAHOO_WORLD_ASSET.readall(),
}

SALMON_STAGE_IMG = {
    "Bonerattle Arena": SALMON_STAGE_BONERATTLE_ARENA_ASSET.readall(),
    "Gone Fission Hydroplant": SALMON_STAGE_GONE_FISSION_HYDROPLANT_ASSET.readall(),
    "Grand Splatlands Bowl": SALMON_STAGE_GRAND_SPLATLANDS_BOWL_ASSET.readall(),
    "Marooner's Bay": SALMON_STAGE_MAROONER_S_BAY_ASSET.readall(),
    "Jammin' Salmon Junction": SALMON_STAGE_JAMMIN_SALMON_JUNCTION_ASSET.readall(),
    "Sockeye Station": SALMON_STAGE_SOCKEYE_STATION_ASSET.readall(),
    "Spawning Grounds": SALMON_STAGE_SPAWNING_GROUNDS_ASSET.readall(),
    "Salmonid Smokeyard": SALMON_STAGE_SALMONID_SMOKEYARD_ASSET.readall(),
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
