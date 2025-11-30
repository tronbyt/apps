"""
Applet: MLB Magic Number
Summary: Display magic number
Description: Displays the magic number or the elimination number of your favorite MLB team.
Author: Jake Manske
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("images/ari_logo.png", ARI_LOGO_ASSET = "file")
load("images/ath_logo.png", ATH_LOGO_ASSET = "file")
load("images/atl_logo.png", ATL_LOGO_ASSET = "file")
load("images/bal_logo.png", BAL_LOGO_ASSET = "file")
load("images/bos_logo.png", BOS_LOGO_ASSET = "file")
load("images/chc_logo.png", CHC_LOGO_ASSET = "file")
load("images/cin_logo.png", CIN_LOGO_ASSET = "file")
load("images/cle_logo.png", CLE_LOGO_ASSET = "file")
load("images/col_logo.png", COL_LOGO_ASSET = "file")
load("images/cws_logo.png", CWS_LOGO_ASSET = "file")
load("images/det_logo.png", DET_LOGO_ASSET = "file")
load("images/hou_logo.png", HOU_LOGO_ASSET = "file")
load("images/kc_logo.png", KC_LOGO_ASSET = "file")
load("images/laa_logo.png", LAA_LOGO_ASSET = "file")
load("images/lad_logo.png", LAD_LOGO_ASSET = "file")
load("images/mia_logo.png", MIA_LOGO_ASSET = "file")
load("images/mil_logo.png", MIL_LOGO_ASSET = "file")
load("images/min_logo.png", MIN_LOGO_ASSET = "file")
load("images/mlb_league_image.png", MLB_LEAGUE_IMAGE_ASSET = "file")
load("images/nym_logo.png", NYM_LOGO_ASSET = "file")
load("images/nyy_logo.png", NYY_LOGO_ASSET = "file")
load("images/phi_logo.png", PHI_LOGO_ASSET = "file")
load("images/pit_logo.png", PIT_LOGO_ASSET = "file")
load("images/sd_logo.png", SD_LOGO_ASSET = "file")
load("images/sea_logo.png", SEA_LOGO_ASSET = "file")
load("images/sf_logo.png", SF_LOGO_ASSET = "file")
load("images/stl_logo.png", STL_LOGO_ASSET = "file")
load("images/tb_logo.png", TB_LOGO_ASSET = "file")
load("images/tex_logo.png", TEX_LOGO_ASSET = "file")
load("images/tor_logo.png", TOR_LOGO_ASSET = "file")
load("images/was_logo.png", WAS_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/img_c45ecc90.png", IMG_c45ecc90_ASSET = "file")

ARI_LOGO = ARI_LOGO_ASSET.readall()
ATH_LOGO = ATH_LOGO_ASSET.readall()
ATL_LOGO = ATL_LOGO_ASSET.readall()
BAL_LOGO = BAL_LOGO_ASSET.readall()
BOS_LOGO = BOS_LOGO_ASSET.readall()
CHC_LOGO = CHC_LOGO_ASSET.readall()
CIN_LOGO = CIN_LOGO_ASSET.readall()
CLE_LOGO = CLE_LOGO_ASSET.readall()
COL_LOGO = COL_LOGO_ASSET.readall()
CWS_LOGO = CWS_LOGO_ASSET.readall()
DET_LOGO = DET_LOGO_ASSET.readall()
HOU_LOGO = HOU_LOGO_ASSET.readall()
KC_LOGO = KC_LOGO_ASSET.readall()
LAA_LOGO = LAA_LOGO_ASSET.readall()
LAD_LOGO = LAD_LOGO_ASSET.readall()
MIA_LOGO = MIA_LOGO_ASSET.readall()
MIL_LOGO = MIL_LOGO_ASSET.readall()
MIN_LOGO = MIN_LOGO_ASSET.readall()
MLB_LEAGUE_IMAGE = MLB_LEAGUE_IMAGE_ASSET.readall()
NYM_LOGO = NYM_LOGO_ASSET.readall()
NYY_LOGO = NYY_LOGO_ASSET.readall()
PHI_LOGO = PHI_LOGO_ASSET.readall()
PIT_LOGO = PIT_LOGO_ASSET.readall()
SD_LOGO = SD_LOGO_ASSET.readall()
SEA_LOGO = SEA_LOGO_ASSET.readall()
SF_LOGO = SF_LOGO_ASSET.readall()
STL_LOGO = STL_LOGO_ASSET.readall()
TB_LOGO = TB_LOGO_ASSET.readall()
TEX_LOGO = TEX_LOGO_ASSET.readall()
TOR_LOGO = TOR_LOGO_ASSET.readall()
WAS_LOGO = WAS_LOGO_ASSET.readall()

MLB_STANDINGS_URL = "https://statsapi.mlb.com/api/v1/standings"

DEFAULT_TEAM = "158"  # Milwaukee Brewers
COMMON_FONT = "CG-pixel-3x5-mono"
BIG_NUMBER_FONT = "10x20"
BRIGHT_RED = "#FF0000"
DARK_RED = "#8B0000"
HTTP_OK = 200

def main(config):
    team_id = get_team_to_follow(config)

    info = http_get_number(team_id)

    if info.Clinched or info.Magic or info.Eliminated or not info.HasData:
        background_color = TEAM_INFO[team_id].BackgroundColor
        if info.Clinched or info.Magic:
            delay = 100
        else:
            delay = 0
    else:  # if you are in danger of being eliminated, get black background
        background_color = "#000000"
        delay = 100

    return render.Root(
        delay = delay,
        child = render.Row(
            children = [
                render_logo(team_id, 32),
                render.Box(
                    height = 32,
                    width = 32,
                    color = background_color,
                    child = render_number_info(team_id, info),
                ),
            ],
        ),
    )

def render_number_info(team_id, info):
    children = []
    center = False
    if not info.Success:
        children = render_failure(team_id, info.ResponseCode)
        center = True
    elif info.Clinched:
        children = render_clinched()
        center = True
    elif info.Magic:
        children = render_magic(info.Number)
        center = True
    elif info.Eliminated:
        children = render_record(team_id, info.Wins, info.Losses, info.DivisionRank)
        center = False
    elif not info.HasData:
        children = render_no_data(team_id)
        center = True
    else:
        children = render_elim(info.Number)
        center = True
    return render.Column(
        cross_align = "center" if center else "start",
        main_align = "space_between",
        children = children,
    )

def render_no_data(team_id):
    color = TEAM_INFO[team_id].ForegroundColor

    # send back good luck message for upcoming season
    phrase = ["good", "luck", "in", str(time.now().year)]
    widgets = []
    for i in range(len(phrase)):
        widgets.append(
            render.Text(
                content = phrase[i],
                font = COMMON_FONT,
                color = color,
            ),
        )
        widgets.append(
            render.Box(
                height = 1,
            ),
        )
    return widgets

def render_failure(team_id, error_code):
    color = TEAM_INFO[team_id].ForegroundColor
    return [
        render.Image(
            src = MLB_LEAGUE_IMAGE,
            width = 32,
        ),
        render.Text(
            content = "HTTP",
            font = COMMON_FONT,
            color = color,
        ),
        render.Text(
            content = "error",
            font = COMMON_FONT,
            color = color,
        ),
        render.Box(
            height = 1,
        ),
        render.Text(
            content = str(error_code),
            font = COMMON_FONT,
            color = color,
        ),
    ]

def render_magic(number):
    widgets = [
        render.Animation(
            children = render_rainbow_word("magic", COMMON_FONT),
        ),
        render.Box(
            height = 1,
            width = 1,
        ),
        render.Animation(
            children = render_rainbow_word("#", "tb-8"),
        ),
        render.Animation(
            children = render_rainbow_word(str(number), BIG_NUMBER_FONT),
        ),
    ]
    return widgets

def render_clinched():
    widgets = [
        render.Animation(
            children = render_rainbow_word("clinched", COMMON_FONT),
        ),
        render.Box(
            height = 1,
            width = 1,
        ),
        render.Image(
            src = CHECKMARK,
        ),
    ]
    return widgets

def get_team_to_follow(config):
    return int(config.str("team", DEFAULT_TEAM))

def is_response_OK(request):
    return request.status_code == HTTP_OK

def render_logo(team_id, size):
    return render.Image(
        src = TEAM_INFO[team_id].Logo,
        width = size,
    )

def render_rainbow_word(word, font):
    colors = ["#e81416", "#ffa500", "#faeb36", "#79c314", "#487de7", "#4b369d", "#70369d"]
    colors_length = len(colors)
    widgets = []
    for j in range(colors_length):
        rainbow_word = []
        for i in range(len(word)):
            letter = render.Text(
                content = word[i],
                font = font,
                color = colors[(j + i) % colors_length],
            )
            rainbow_word.append(letter)
        widgets.append(
            render.Row(
                children = rainbow_word,
            ),
        )
    return widgets

def render_record(team_id, wins, losses, division_rank):
    win_counter = []
    loss_counter = []
    div_rank_array = []
    text_color = TEAM_INFO[team_id].ForegroundColor
    bg_color = TEAM_INFO[team_id].BackgroundColor

    build_record_arrays(team_id, wins, 0, win_counter, loss_counter, div_rank_array)
    build_record_arrays(team_id, losses, wins, loss_counter, win_counter, div_rank_array)

    # add frames for the division rank
    for j in range(100):
        win_counter.append(
            render.Text(
                content = str(wins),
                font = COMMON_FONT,
                color = text_color,
            ),
        )
        loss_counter.append(
            render.Text(
                content = str(losses),
                font = COMMON_FONT,
                color = text_color,
            ),
        )
        div_rank_array.append(
            render.Text(
                content = str(division_rank),
                color = text_color if j % 30 < 15 else bg_color,
                font = BIG_NUMBER_FONT,
            ),
        )
    widgets = [
        render.Row(
            children = [
                render.Text(
                    content = "W: ",
                    font = COMMON_FONT,
                    color = text_color,
                ),
                render.Animation(
                    children = win_counter,
                ),
            ],
        ),
        render.Box(
            height = 1,
        ),
        render.Row(
            children = [
                render.Text(
                    content = "L: ",
                    font = COMMON_FONT,
                    color = text_color,
                ),
                render.Animation(
                    children = loss_counter,
                ),
            ],
        ),
        render.Box(
            height = 1,
        ),
        render.Stack(
            children = [
                render.Text(
                    content = "div rank",
                    font = COMMON_FONT,
                    color = text_color,
                ),
                render.Column(
                    cross_align = "center",
                    children = [
                        render.Box(
                            height = 3,
                        ),
                        render.Animation(
                            children = div_rank_array,
                        ),
                    ],
                ),
            ],
        ),
    ]
    return widgets

def build_record_arrays(team_id, total, static_number, incr_array, static_array, rank_array):
    text_color = TEAM_INFO[team_id].ForegroundColor
    bg_color = TEAM_INFO[team_id].BackgroundColor

    for j in range(total + 1):
        incr_array.append(
            render.Text(
                content = str(j),
                font = COMMON_FONT,
                color = text_color,
            ),
        )
        static_array.append(
            render.Text(
                content = str(static_number),
                font = COMMON_FONT,
                color = text_color,
            ),
        )
        rank_array.append(
            render.Text(
                content = "0",
                color = bg_color,
                font = BIG_NUMBER_FONT,
            ),
        )

def render_elim(number):
    bright = render_elim_with_hue(number, BRIGHT_RED, DARK_RED)
    dark = render_elim_with_hue(number, DARK_RED, BRIGHT_RED)

    widgets = []
    for _ in range(10):
        widgets.append(bright)
    for _ in range(10):
        widgets.append(dark)
    return [
        render.Animation(
            children = widgets,
        ),
    ]

def render_elim_with_hue(number, on_hue, off_hue):
    return render.Column(
        cross_align = "center",
        main_align = "space_between",
        children = [
            render.Text(
                content = "elim",
                font = COMMON_FONT,
                color = on_hue,
            ),
            render.Box(
                height = 1,
                width = 1,
            ),
            render.Text(
                content = "#",
                color = off_hue,
            ),
            render.Text(
                content = number,
                font = BIG_NUMBER_FONT,
                color = on_hue,
            ),
        ],
    )

######################
## HTTP REQUEST API ##
######################
def http_get_number(team_id):
    query_params = {
        "fields": "records,division,id,teamRecords,team,magicNumber,eliminationNumberDivision,clinched,clinchIndicator,divisionRank,wins,losses",
        "leagueId": str(TEAM_INFO[team_id].LeagueId),
        "season": str(time.now().year),
    }

    # cache response for 5 minutes
    response = http.get(MLB_STANDINGS_URL, params = query_params, ttl_seconds = 300)

    number = "0"
    magic = False
    clinched = False
    division_rank = "0"
    eliminated = False
    wins = 0
    losses = 0
    has_data = True

    # keep track of where we are, we might need to get the NEXT record to fully calculate our magic number
    index = 0
    if is_response_OK(response):
        for record in response.json().get("records"):
            # if it matches our division, loop through teams to find our team
            if int(record.get("division").get("id")) == TEAM_INFO[team_id].DivisionId:
                for team_record in record.get("teamRecords"):
                    index += 1
                    if int(team_record.get("team").get("id")) == team_id:
                        wins = int(team_record.get("wins"))
                        losses = int(team_record.get("losses"))
                        division_rank = int(team_record.get("divisionRank"))

                        # see if we have clinched and our clinch indicator tells us we have the division
                        clinched = team_record.get("clinched")
                        if clinched:
                            indicator = team_record.get("clinchIndicator")

                            # indicator of y means division
                            # indicator of z means best record in league
                            # an indicator of x means we have clinched a wild card
                            # but we care about division winners here
                            clinched = True if indicator == "y" or indicator == "z" else False

                        # if team did not yet clinch division, see if it has a magic number
                        if not clinched:
                            number = team_record.get("magicNumber")

                            # if we do not have a magic number, we will have elimination number
                            # or be actually eliminated from division contention
                            if number == None:
                                number = team_record.get("eliminationNumberDivision")
                                eliminated = True if number == "E" else False
                            else:
                                magic = True

                                # if we have not clinched yet our magic number is a dash
                                # it means we need the elimination number of the team right after us
                                # MLB API stops displaying magic number for division leader after they clinch wild card
                                if number == "-":
                                    number = record.get("teamRecords")[index].get("eliminationNumberDivision")

                                    # if the second place team is eliminated, it means we have indeed clinched the division
                                    # there is a short window of time where the clinch indicator has yet to be updated
                                    # we can override the clinched flag here
                                    if number == "E":
                                        clinched = True

                        break  # we found our team
                break  # we found our division
    else:
        return struct(Number = number, Magic = magic, Clinched = clinched, DivisionRank = division_rank, Eliminated = eliminated, Wins = wins, Losses = losses, Success = False, ResponseCode = response.status_code, HasData = False)

    # if we got nothing, it is probably because the season has not yet started
    # use this to render the "good luck" image
    if wins == 0 and losses == 0:
        has_data = False
    return struct(Number = number, Magic = magic, Clinched = clinched, DivisionRank = division_rank, Eliminated = eliminated, Wins = wins, Losses = losses, Success = True, ResponseCode = response.status_code, HasData = has_data)

CHECKMARK = base64.decode(
    IMG_c45ecc90_ASSET.readall(),
)

#################
## TEAM CONFIG ##
#################
LAA_TEAM_ID = 108  #Los Angeles Angels
ARI_TEAM_ID = 109  #Arizona Diamondbacks
BAL_TEAM_ID = 110  #Baltimore Orioles
BOS_TEAM_ID = 111  #Boston Red Sox
CHC_TEAM_ID = 112  #Chicago Cubs
CIN_TEAM_ID = 113  #Cincinnati Reds
CLE_TEAM_ID = 114  #Cleveland Guardians
COL_TEAM_ID = 115  #Colorado Rockies
DET_TEAM_ID = 116  #Detroit Tigers
HOU_TEAM_ID = 117  #Houston Astros
KC_TEAM_ID = 118  #Kansas City Royals
LAD_TEAM_ID = 119  #Los Angeles Dodgers
WAS_TEAM_ID = 120  #Washington Nationals
NYM_TEAM_ID = 121  #New York Mets
ATH_TEAM_ID = 133  #Athletics
PIT_TEAM_ID = 134  #Pittsburgh Pirates
SD_TEAM_ID = 135  #San Diego Padres
SEA_TEAM_ID = 136  #Seattle Mariners
SF_TEAM_ID = 137  #San Francisco Giants
STL_TEAM_ID = 138  #St. Louis Cardinals
TB_TEAM_ID = 139  #Tampa Bay Rays
TEX_TEAM_ID = 140  #Texas Rangers
TOR_TEAM_ID = 141  #Toronto Blue Jays
MIN_TEAM_ID = 142  #Minnesota Twins
PHI_TEAM_ID = 143  #Philadelphia Phillies
ATL_TEAM_ID = 144  #Atlanta Braves
CWS_TEAM_ID = 145  #Chicago White Sox
MIA_TEAM_ID = 146  #Miami Marlins
NYY_TEAM_ID = 147  #New York Yankees
MIL_TEAM_ID = 158  #Milwaukee Brewers

#id: 108 - Los Angeles Angels

#id: 109 - Arizona Diamondbacks

#id: 110 - Baltimore Orioles

#id: 111 - Boston Red Sox

#id: 112 - Chicago Cubs

#id: 113 - Cincinnati Reds

#id: 114 - Cleveland Guardians

#id: 115 - Colorado Rockies

#id: 116 - Detroit Tigers

#id: 117 - Houston Astros

#id: 118 - Kansas City Royals

#id: 119 - Los Angeles Dodgers

#id: 120 - Washington Nationals

#id: 121 - New York Mets

#id: 133 - Athletics

#id: 134 - Pittsburgh Pirates

#id: 135 - San Diego Padres

#id: 136 - Seattle Mariners

#id: 137 - San Francisco Giants

#id: 138 - St. Louis Cardinals

#id: 139 - Tampa Bay Rays

#id: 140 - Texas Rangers

#id: 141 - Toronto Blue Jays

#id: 142 - Minnesota Twins

#id: 143 - Philadelphia Phillies

#id: 144 - Atlanta Braves

#id: 145 - Chicago White Sox

#id: 146 - Miami Marlins

#id: 147 - New York Yankees

#id: 158 - Milwaukee Brewers

# league IDs
NAT_LEAGUE_ID = 104
AMER_LEAGUE_ID = 103

# division IDs
NL_WEST = 203
NL_CENTRAL = 205
NL_EAST = 204
AL_WEST = 200
AL_CENTRAL = 202
AL_EAST = 201

def struct_TeamDefinition(name, abbrev, logo, foreground_color, background_color, id, leagueId, divisionId):
    return struct(Name = name, Abbreviation = abbrev, Logo = logo, ForegroundColor = foreground_color, BackgroundColor = background_color, Id = id, LeagueId = leagueId, DivisionId = divisionId)

TEAM_INFO = {
    ARI_TEAM_ID: struct_TeamDefinition("Arizona DiamondBacks", "ARI", ARI_LOGO, "#E3D4AD", "#A71930", ARI_TEAM_ID, NAT_LEAGUE_ID, NL_WEST),
    ATH_TEAM_ID: struct_TeamDefinition("Athletics", "ATH", ATH_LOGO, "#EFB21E", "#003831", ATH_TEAM_ID, AMER_LEAGUE_ID, AL_WEST),
    ATL_TEAM_ID: struct_TeamDefinition("Atlanta Braves", "ATL", ATL_LOGO, "#FFFFFF", "#13274F", ATL_TEAM_ID, NAT_LEAGUE_ID, NL_EAST),
    BOS_TEAM_ID: struct_TeamDefinition("Boston Red Sox", "BOS", BOS_LOGO, "#FFFFFF", "#0C2340", BOS_TEAM_ID, AMER_LEAGUE_ID, AL_EAST),
    BAL_TEAM_ID: struct_TeamDefinition("Baltimore Orioles", "BAL", BAL_LOGO, "#DF4701", "#000000", BAL_TEAM_ID, AMER_LEAGUE_ID, AL_EAST),
    CHC_TEAM_ID: struct_TeamDefinition("Chicago Cubs", "CHC", CHC_LOGO, "#CC3433", "#0E3386", CHC_TEAM_ID, NAT_LEAGUE_ID, NL_CENTRAL),
    CWS_TEAM_ID: struct_TeamDefinition("Chicago White Sox", "CWS", CWS_LOGO, "#C4CED4", "#27251F", CWS_TEAM_ID, AMER_LEAGUE_ID, AL_CENTRAL),
    CIN_TEAM_ID: struct_TeamDefinition("Cincinnati Reds", "CIN", CIN_LOGO, "#FFFFFF", "#C6011F", CIN_TEAM_ID, NAT_LEAGUE_ID, NL_CENTRAL),
    CLE_TEAM_ID: struct_TeamDefinition("Cleveland Guardians", "CLE", CLE_LOGO, "#FFFFFF", "#00385D", CLE_TEAM_ID, AMER_LEAGUE_ID, AL_CENTRAL),
    COL_TEAM_ID: struct_TeamDefinition("Colorado Rockies", "COL", COL_LOGO, "#C4CED4", "#333366", COL_TEAM_ID, NAT_LEAGUE_ID, NL_WEST),
    DET_TEAM_ID: struct_TeamDefinition("Detroit Tigers", "DET", DET_LOGO, "#FFFFFF", "#0C2340", DET_TEAM_ID, AMER_LEAGUE_ID, AL_CENTRAL),
    HOU_TEAM_ID: struct_TeamDefinition("Houston Astros", "HOU", HOU_LOGO, "#EB6E1F", "#002D62", HOU_TEAM_ID, AMER_LEAGUE_ID, AL_WEST),
    KC_TEAM_ID: struct_TeamDefinition("Kansas City Royals", "KC", KC_LOGO, "#BD9B60", "#004687", KC_TEAM_ID, AMER_LEAGUE_ID, AL_CENTRAL),
    LAA_TEAM_ID: struct_TeamDefinition("Los Angeles Angels", "LAA", LAA_LOGO, "#FFFFFF", "#BA0021", LAA_TEAM_ID, AMER_LEAGUE_ID, AL_WEST),
    LAD_TEAM_ID: struct_TeamDefinition("Los Angeles Dodgers", "LAD", LAD_LOGO, "#FFFFFF", "#005A9C", LAD_TEAM_ID, NAT_LEAGUE_ID, NL_WEST),
    MIA_TEAM_ID: struct_TeamDefinition("Miami Marlins", "MIA", MIA_LOGO, "#00A3E0", "#000000", MIA_TEAM_ID, NAT_LEAGUE_ID, NL_EAST),
    MIL_TEAM_ID: struct_TeamDefinition("Milwaukee Brewers", "MIL", MIL_LOGO, "#FFC52F", "#12284B", MIL_TEAM_ID, NAT_LEAGUE_ID, NL_CENTRAL),
    MIN_TEAM_ID: struct_TeamDefinition("Minnesota Twins", "MIN", MIN_LOGO, "#FFFFFF", "#002B5C", MIN_TEAM_ID, AMER_LEAGUE_ID, AL_CENTRAL),
    NYM_TEAM_ID: struct_TeamDefinition("New York Mets", "NYM", NYM_LOGO, "#FF5910", "#002D72", NYM_TEAM_ID, NAT_LEAGUE_ID, NL_EAST),
    NYY_TEAM_ID: struct_TeamDefinition("New York Yankees", "NYY", NYY_LOGO, "#C4CED3", "#0C2340", NYY_TEAM_ID, AMER_LEAGUE_ID, AL_EAST),
    PHI_TEAM_ID: struct_TeamDefinition("Philadelphia Phillies", "PHI", PHI_LOGO, "#FFFFFF", "#E81828", PHI_TEAM_ID, NAT_LEAGUE_ID, NL_EAST),
    PIT_TEAM_ID: struct_TeamDefinition("Pittsburgh Pirates", "PIT", PIT_LOGO, "#FDB827", "#27251F", PIT_TEAM_ID, NAT_LEAGUE_ID, NL_CENTRAL),
    SEA_TEAM_ID: struct_TeamDefinition("Seattle Mariners", "SEA", SEA_LOGO, "#C4CED4", "#0C2C56", SEA_TEAM_ID, AMER_LEAGUE_ID, AL_WEST),
    SD_TEAM_ID: struct_TeamDefinition("San Diego Padres", "SD", SD_LOGO, "#FFC425", "#2F241D", SD_TEAM_ID, NAT_LEAGUE_ID, NL_WEST),
    STL_TEAM_ID: struct_TeamDefinition("St. Louis Cardinals", "STL", STL_LOGO, "#FFFFFF", "#C41E3A", STL_TEAM_ID, NAT_LEAGUE_ID, NL_CENTRAL),
    SF_TEAM_ID: struct_TeamDefinition("San Francisco Giants", "SF", SF_LOGO, "#FD5A1E", "#27251F", SF_TEAM_ID, NAT_LEAGUE_ID, NL_WEST),
    TB_TEAM_ID: struct_TeamDefinition("Tampa Bay Rays", "TB", TB_LOGO, "#8FBCE6", "#092C5C", TB_TEAM_ID, AMER_LEAGUE_ID, AL_EAST),
    TEX_TEAM_ID: struct_TeamDefinition("Texas Rangers", "TEX", TEX_LOGO, "#FFFFFF", "#003278", TEX_TEAM_ID, AMER_LEAGUE_ID, AL_WEST),
    TOR_TEAM_ID: struct_TeamDefinition("Toronto Blue Jays", "TOR", TOR_LOGO, "#FFFFFF", "#134A8E", TOR_TEAM_ID, AMER_LEAGUE_ID, AL_EAST),
    WAS_TEAM_ID: struct_TeamDefinition("Washington Nationals", "WAS", WAS_LOGO, "#FFFFFF", "#AB0003", WAS_TEAM_ID, NAT_LEAGUE_ID, NL_EAST),
}

# SCHEMA

def get_schema():
    team_options = []
    for team in TEAM_INFO.values():
        team_options.append(
            schema.Option(
                display = team.Name,
                value = str(team.Id),
            ),
        )
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "team",
                name = "Team",
                desc = "MLB Team to follow.",
                icon = "baseballBatBall",
                options = team_options,
                default = "158",  # MILWAUKEE BREWERS
            ),
        ],
    )
