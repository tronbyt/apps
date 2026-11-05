"""
Applet: Splat3 Challenges
Summary: Splatoon 3 Challenges
Description: Shows upcoming Challenges in Splatoon 3, their descriptions and modifiers, and the times they start at. Data provided by splatoon3.ink.
Author: MarkGamed7794
"""

# For some reason, the backgound stage images change colour a little bit. Anyone know why this happens?

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/icon_challenge.png", ICON_CHALLENGE_ASSET = "file")
load("images/icon_clam_blitz.png", ICON_CLAM_BLITZ_ASSET = "file")
load("images/icon_rainmaker.png", ICON_RAINMAKER_ASSET = "file")
load("images/icon_splat_zones.png", ICON_SPLAT_ZONES_ASSET = "file")
load("images/icon_tower_control.png", ICON_TOWER_CONTROL_ASSET = "file")
load("images/icon_turf_war.png", ICON_TURF_WAR_ASSET = "file")
load("images/num_1.png", NUM_1_ASSET = "file")
load("images/num_2.png", NUM_2_ASSET = "file")
load("images/num_3.png", NUM_3_ASSET = "file")
load("images/num_4.png", NUM_4_ASSET = "file")
load("images/num_5.png", NUM_5_ASSET = "file")
load("images/num_6.png", NUM_6_ASSET = "file")
load("images/stage_barnacle_dime.png", STAGE_BARNACLE_DIME_ASSET = "file")
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
load("images/stage_no_stage.png", STAGE_NO_STAGE_ASSET = "file")
load("images/stage_robo_rom_en.png", STAGE_ROBO_ROM_EN_ASSET = "file")
load("images/stage_scorch_gorge.png", STAGE_SCORCH_GORGE_ASSET = "file")
load("images/stage_shipshape_cargo_co.png", STAGE_SHIPSHAPE_CARGO_CO_ASSET = "file")
load("images/stage_sturgeon_shipyard.png", STAGE_STURGEON_SHIPYARD_ASSET = "file")
load("images/stage_um_ami_ruins.png", STAGE_UM_AMI_RUINS_ASSET = "file")
load("images/stage_undertow_spillway.png", STAGE_UNDERTOW_SPILLWAY_ASSET = "file")
load("images/stage_urchin_underpass.png", STAGE_URCHIN_UNDERPASS_ASSET = "file")
load("images/stage_wahoo_world.png", STAGE_WAHOO_WORLD_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

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
    "no_stage": STAGE_NO_STAGE_ASSET.readall(),
    "Barnacle & Dime": STAGE_BARNACLE_DIME_ASSET.readall(),
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

ICONS = {
    # mode icons
    "Turf War": ICON_TURF_WAR_ASSET.readall(),
    "Rainmaker": ICON_RAINMAKER_ASSET.readall(),
    "Tower Control": ICON_TOWER_CONTROL_ASSET.readall(),
    "Splat Zones": ICON_SPLAT_ZONES_ASSET.readall(),
    "Clam Blitz": ICON_CLAM_BLITZ_ASSET.readall(),
    "challenge": ICON_CHALLENGE_ASSET.readall(),
}
NUMBERS = [
    NUM_1_ASSET.readall(),
    NUM_2_ASSET.readall(),
    NUM_3_ASSET.readall(),
    NUM_4_ASSET.readall(),
    NUM_5_ASSET.readall(),
    NUM_6_ASSET.readall(),
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
        rep = http.get(STAGE_URL, ttl_seconds = 3600 * 2)
        if (rep.status_code != 200):
            failed = rep.status_code or -1
        else:
            stages = rep.json()  # Will it just let me do this?
            challenges = stages["data"]["eventSchedules"]["nodes"]

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
