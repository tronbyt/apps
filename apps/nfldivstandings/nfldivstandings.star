"""
Applet: NflDivStandings
Summary: Show NFL division standings
Description: Displays NFL division standings for your favorite division.
Author: Jake Manske
"""

load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("images/img_02b6b944.png", IMG_02b6b944_ASSET = "file")
load("images/img_0684d182.png", IMG_0684d182_ASSET = "file")
load("images/img_0a427d3d.png", IMG_0a427d3d_ASSET = "file")
load("images/img_23fdee3d.png", IMG_23fdee3d_ASSET = "file")
load("images/img_2a9528de.png", IMG_2a9528de_ASSET = "file")
load("images/img_2ce0b95d.png", IMG_2ce0b95d_ASSET = "file")
load("images/img_2ded6fe3.png", IMG_2ded6fe3_ASSET = "file")
load("images/img_44ef2435.png", IMG_44ef2435_ASSET = "file")
load("images/img_46d5297b.png", IMG_46d5297b_ASSET = "file")
load("images/img_4be90796.png", IMG_4be90796_ASSET = "file")
load("images/img_4f8cf2d6.png", IMG_4f8cf2d6_ASSET = "file")
load("images/img_53b0cafe.png", IMG_53b0cafe_ASSET = "file")
load("images/img_68324f0a.png", IMG_68324f0a_ASSET = "file")
load("images/img_76fdd79e.png", IMG_76fdd79e_ASSET = "file")
load("images/img_96953582.png", IMG_96953582_ASSET = "file")
load("images/img_9939009d.png", IMG_9939009d_ASSET = "file")
load("images/img_99a5176b.png", IMG_99a5176b_ASSET = "file")
load("images/img_a50d5a2c.png", IMG_a50d5a2c_ASSET = "file")
load("images/img_a63bbc79.png", IMG_a63bbc79_ASSET = "file")
load("images/img_a67e36e7.png", IMG_a67e36e7_ASSET = "file")
load("images/img_a842f1a5.png", IMG_a842f1a5_ASSET = "file")
load("images/img_aabc28c7.png", IMG_aabc28c7_ASSET = "file")
load("images/img_b5681a13.png", IMG_b5681a13_ASSET = "file")
load("images/img_b6636184.png", IMG_b6636184_ASSET = "file")
load("images/img_bc02d3f3.png", IMG_bc02d3f3_ASSET = "file")
load("images/img_c7e67f66.png", IMG_c7e67f66_ASSET = "file")
load("images/img_daf9f036.png", IMG_daf9f036_ASSET = "file")
load("images/img_dfb7ae17.png", IMG_dfb7ae17_ASSET = "file")
load("images/img_e654c4a4.png", IMG_e654c4a4_ASSET = "file")
load("images/img_eaceb8dc.png", IMG_eaceb8dc_ASSET = "file")
load("images/img_ee3cd44a.png", IMG_ee3cd44a_ASSET = "file")
load("images/img_eef6e8d0.png", IMG_eef6e8d0_ASSET = "file")

STANDINGS_URL = "https://site.api.espn.com/apis/v2/sports/football/nfl/standings"
STANDINGS_TTL_SECONDS = 300  # 5 minutes
HTTP_OK = 200
RECORD_FONT = "CG-pixel-4x5-mono"

def main(config):
    division_id = config.get("division") or "10"  # NFC North default

    standings = get_standings(division_id)

    # if we get no standings at all
    # could be due to some HTTP failure or we just don't have data
    # just take the app out of the rotation so we don't display something weird
    if len(standings) == 0:
        return []

    # otherwise render it up
    return render.Root(
        delay = 80,
        show_full_animation = True,
        child = render.Row(
            children = [
                render.Box(
                    width = 5,
                    height = 32,
                    child = render_lefter(division_id),
                ),
                animation.Transformation(
                    duration = 180,
                    width = 236,
                    keyframes = [
                        build_keyframe(0, 0.0),
                        build_keyframe(-59, 0.33),
                        build_keyframe(-118, 0.66),
                        build_keyframe(-177, 1.0),
                    ],
                    child = render_division_standings(standings),
                    wait_for_child = True,
                ),
            ],
        ),
    )

def build_keyframe(offset, pct):
    return animation.Keyframe(
        percentage = pct,
        transforms = [animation.Translate(offset, 0)],
        curve = "ease_in_out",
    )

def get_standings(division_id):
    query_params = {
        "group": division_id,
    }

    # hit the endpoint and cache things for 5 minutes
    response = http.get(STANDINGS_URL, params = query_params, ttl_seconds = STANDINGS_TTL_SECONDS)

    standings = []

    # return nothing if endpoint failed
    if response.status_code != HTTP_OK:
        return []

    # get standings attribute from the response
    standings_raw = response.json().get("standings")

    # if there are no standings to display, return empty array
    if standings_raw == None:
        return []

    for team in standings_raw.get("entries"):
        standings.append(parse_team(team.get("team"), team.get("stats")))

    return standings

def render_logo(info):
    return render.Image(
        src = info.Logo,
    )

def render_division_standings(standings):
    cards = []
    rank = 1

    # sort by playoff seed, it seems to be the most accurate
    # the API endpoint appears to return the standings results in an indeterminate order
    # we have to do the sort ourselves
    for team in sorted(standings, get_rank):
        cards.append(render_team_card(team, rank))
        rank += 1
    return render.Row(
        children = cards,
    )

def get_rank(team):
    return team.Rank

def render_team_card(team, rank):
    info = TEAM_INFO[team.Id]
    logo_width = 59
    return render.Box(
        height = 32,
        width = logo_width,
        color = info.BackgroundColor,
        child = render.Stack(
            children = [
                render.Padding(
                    pad = (0, info.Offset, 0, 0),
                    child = render_logo(info),
                ),
                render.Column(
                    children = [
                        render.Box(
                            width = logo_width,
                            height = 26,
                        ),
                        render.Box(
                            width = logo_width,
                            height = 6,
                            color = info.BackgroundColor,
                            child = render.Row(
                                main_align = "space_evenly",
                                cross_align = "end",
                                expanded = True,
                                children = [
                                    render_div_position(rank, team.ClinchIndicator, info),
                                    render_team_record(team, info),
                                ],
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def render_team_record(team, info):
    return render.Text(
        content = team.Record,
        color = info.ForegroundColor,
        font = RECORD_FONT,
    )

def render_div_position(rank, clinchIndicator, info):
    if clinchIndicator != None and clinchIndicator != "e":
        div_position = [
            render_rainbow_word(str(rank), RECORD_FONT),
            render.Padding(
                pad = (3 if rank == 1 else 4, 0, 0, 0),
                child = render_rainbow_word("." + "(" + clinchIndicator + ")", RECORD_FONT),
            ),
        ]
    else:
        div_position = [
            render.Text(
                content = str(rank),
                color = info.ForegroundColor,
                font = RECORD_FONT,
            ),
            render.Padding(
                pad = (3 if rank == 1 else 4, 0, 0, 0),
                child = render.Text(
                    content = ".",
                    color = info.ForegroundColor,
                    font = RECORD_FONT,
                ),
            ),
        ]
    return render.Stack(
        children = div_position,
    )

def render_lefter(division_id):
    div = DIVISION_MAP.get(division_id)
    lefter = []
    for i in range(len(div)):
        lefter.append(
            render_american_word(div[i], RECORD_FONT),
        )
        lefter.append(
            render.Box(
                height = 1,
                width = 1,
            ),
        )
    return render.Box(
        height = 32,
        width = 5,
        child = render.Column(
            children = lefter,
        ),
    )

def render_rainbow_word(word, font):
    colors = ["#e81416", "#ffa500", "#faeb36", "#79c314", "#487de7", "#4b369d", "#70369d"]
    return render_flashy_word(word, font, colors, 1)

def render_american_word(word, font):
    colors = ["#B31942", "#FFFFFF", "#0A3161"]
    return render_flashy_word(word, font, colors, 4)

def render_flashy_word(word, font, colors, repeater):
    widgets = []
    flash_list = []

    # set up the color list
    for color in colors:
        for _ in range(repeater):
            flash_list.append(color)

    ranger = len(flash_list)

    for j in range(ranger):
        flashy_word = []
        for i in range(len(word)):
            letter = render.Text(
                content = word[i],
                font = font,
                color = flash_list[(j + i) % ranger],
            )
            flashy_word.append(letter)
        widgets.append(
            render.Row(
                children = flashy_word,
            ),
        )
    return render.Animation(
        children = widgets,
    )

def parse_team(team_raw, stats_raw):
    abbrev = team_raw.get("abbreviation")
    id = int(team_raw.get("id"))

    # initialize variables
    # the API result is annoying and forces us to loop through
    record = None
    rank = None
    clincher = None
    for stat in stats_raw:
        record = get_element(stat, "overall") if record == None else record
        clincher = get_element(stat, "clincher") if clincher == None else clincher

        # this is what we will sort by to make sure the standings are in the right order
        rank = get_element(stat, "playoffSeed") if rank == None else rank

        # break the loop if we have everything we need
        if record != None and rank != None and clincher != None:
            break

    return build_team_struct(id, abbrev, record, rank, clincher)

def build_team_struct(id, abbrev, record, rank, clincher):
    # rank may be 0 if it is too early to rank teams
    # in which case sort those teams to the bottom
    if rank == "0":
        rank = "32"
    return struct(Id = id, Abbreviation = abbrev, Record = record, Rank = int(rank), ClinchIndicator = clincher)

def get_element(stat, element):
    name = stat.get("name")
    if name == element:
        return stat.get("displayValue")
    return None

def get_schema():
    options = [
        schema.Option(
            display = "AFC East",
            value = "4",
        ),
        schema.Option(
            display = "AFC North",
            value = "12",
        ),
        schema.Option(
            display = "AFC South",
            value = "13",
        ),
        schema.Option(
            display = "AFC West",
            value = "6",
        ),
        schema.Option(
            display = "NFC East",
            value = "1",
        ),
        schema.Option(
            display = "NFC North",
            value = "10",
        ),
        schema.Option(
            display = "NFC South",
            value = "11",
        ),
        schema.Option(
            display = "NFC West",
            value = "3",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "division",
                name = "Division",
                desc = "The division to display standings for.",
                icon = "football",
                default = "10",
                options = options,
            ),
        ],
    )

DIVISION_MAP = {
    "1": "EAST",
    "3": "WEST",
    "4": "EAST",
    "6": "WEST",
    "10": "NORTH",
    "11": "SOUTH",
    "12": "NORTH",
    "13": "SOUTH",
}

def team_ctor(fg, bg, logo, offset = -15):
    return struct(ForegroundColor = fg, BackgroundColor = bg, Logo = logo, Offset = offset)

# LOGOS
ATL_LOGO = base64.decode(
    IMG_daf9f036_ASSET.readall(),
)
ARI_LOGO = base64.decode(
    IMG_0a427d3d_ASSET.readall(),
)
BAL_LOGO = base64.decode(
    IMG_b6636184_ASSET.readall(),
)
BUF_LOGO = base64.decode(
    IMG_ee3cd44a_ASSET.readall(),
)
CAR_LOGO = base64.decode(
    IMG_bc02d3f3_ASSET.readall(),
)
CHI_LOGO = base64.decode(
    IMG_02b6b944_ASSET.readall(),
)
CIN_LOGO = base64.decode(
    IMG_e654c4a4_ASSET.readall(),
)
CLE_LOGO = base64.decode(
    IMG_23fdee3d_ASSET.readall(),
)
DAL_LOGO = base64.decode(
    IMG_eaceb8dc_ASSET.readall(),
)
DEN_LOGO = base64.decode(
    IMG_9939009d_ASSET.readall(),
)
DET_LOGO = base64.decode(
    IMG_eef6e8d0_ASSET.readall(),
)
GB_LOGO = base64.decode(
    IMG_a63bbc79_ASSET.readall(),
)
HOU_LOGO = base64.decode(
    IMG_76fdd79e_ASSET.readall(),
)
IND_LOGO = base64.decode(
    IMG_b5681a13_ASSET.readall(),
)
JAX_LOGO = base64.decode(
    IMG_99a5176b_ASSET.readall(),
)
KC_LOGO = base64.decode(
    IMG_46d5297b_ASSET.readall(),
)
LAC_LOGO = base64.decode(
    IMG_68324f0a_ASSET.readall(),
)
LAR_LOGO = base64.decode(
    IMG_96953582_ASSET.readall(),
)
MIA_LOGO = base64.decode(
    IMG_53b0cafe_ASSET.readall(),
)
MIN_LOGO = base64.decode(
    IMG_aabc28c7_ASSET.readall(),
)
NE_LOGO = base64.decode(
    IMG_4f8cf2d6_ASSET.readall(),
)
NO_LOGO = base64.decode(
    IMG_c7e67f66_ASSET.readall(),
)
NYG_LOGO = base64.decode(
    IMG_a50d5a2c_ASSET.readall(),
)
NYJ_LOGO = base64.decode(
    IMG_4be90796_ASSET.readall(),
)
OAK_LOGO = base64.decode(
    IMG_0684d182_ASSET.readall(),
)
PHI_LOGO = base64.decode(
    IMG_a67e36e7_ASSET.readall(),
)
PIT_LOGO = base64.decode(
    IMG_a842f1a5_ASSET.readall(),
)
SEA_LOGO = base64.decode(
    IMG_2a9528de_ASSET.readall(),
)
SF_LOGO = base64.decode(
    IMG_44ef2435_ASSET.readall(),
)
TB_LOGO = base64.decode(
    IMG_2ce0b95d_ASSET.readall(),
)
TEN_LOGO = base64.decode(
    IMG_2ded6fe3_ASSET.readall(),
)
WSH_LOGO = base64.decode(
    IMG_dfb7ae17_ASSET.readall(),
)

TEAM_INFO = {
    # ATL
    1: team_ctor("#A71930", "#000000", ATL_LOGO, -10),
    # BUF
    2: team_ctor("#FFFFFF", "#00338D", BUF_LOGO),
    # CHI
    3: team_ctor("#C83803", "#0B162A", CHI_LOGO),
    # CIN
    4: team_ctor("#FB4F14", "#000000", CIN_LOGO),
    # CLE
    5: team_ctor("#FF3C00", "#311D00", CLE_LOGO),
    # DAL
    6: team_ctor("#869397", "#041E42", DAL_LOGO),
    # DEN
    7: team_ctor("#FB4F14", "#002244", DEN_LOGO),
    # DET
    8: team_ctor("#B0B7BC", "#0076B6", DET_LOGO),
    # GB
    9: team_ctor("#FFB612", "#203731", GB_LOGO, -17),
    # TEN
    10: team_ctor("#4B92DB", "#0C2340", TEN_LOGO, -19),
    # IND
    11: team_ctor("#FFFFFF", "#002C5F", IND_LOGO, -7),
    # KC
    12: team_ctor("#FFB81C", "#E31837", KC_LOGO, -17),
    # OAK
    13: team_ctor("#A5ACAF", "#000000", OAK_LOGO, -12),
    # LAR
    14: team_ctor("#FFA300", "#003594", LAR_LOGO),
    # MIA
    15: team_ctor("#FFFFFF", "#008E97", MIA_LOGO),
    # MIN
    16: team_ctor("#FFC62F", "#4F2683", MIN_LOGO),
    # NE
    17: team_ctor("#B0B7BC", "#002244", NE_LOGO, -17),
    # NO
    18: team_ctor("#D3BC8D", "#000000", NO_LOGO, -19),
    # NYG
    19: team_ctor("#FFFFFF", "#0B2265", NYG_LOGO),
    # NYJ
    20: team_ctor("#FFFFFF", "#125740", NYJ_LOGO, -17),
    # PHI
    21: team_ctor("#ACC0C6", "#004C54", PHI_LOGO, -19),
    # ARI
    22: team_ctor("#97233F", "#000000", ARI_LOGO, -19),
    # PIT
    23: team_ctor("#FFB612", "#101820", PIT_LOGO),
    # LAC
    24: team_ctor("#FFC20E", "#0080C6", LAC_LOGO, -17),
    # SF
    25: team_ctor("#B3995D", "#AA0000", SF_LOGO, -17),
    # SEA
    26: team_ctor("#A5ACAF", "#002244", SEA_LOGO, -16),
    # TB
    27: team_ctor("#D50A0A", "#0A0A08", TB_LOGO),
    # WSH
    28: team_ctor("#FFB612", "#5A1414", WSH_LOGO),
    # CAR
    29: team_ctor("#0085CA", "#101820", CAR_LOGO),
    # JAX
    30: team_ctor("#006778", "#101820", JAX_LOGO),
    # BAL
    33: team_ctor("#9E7C0C", "#000000", BAL_LOGO, -16),
    # HOU
    34: team_ctor("#A71930", "#03202F", HOU_LOGO),
}
