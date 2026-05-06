"""
Applet: MlbDivStandings
Summary: MLB Division Standings
Description: Display the standings for the MLB division of your choice.
Author: Jake Manske
"""

load("animation.star", "animation")
load("http.star", "http")
load("images/al.png", AL_ASSET = "file")
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
load("images/nl.png", NL_ASSET = "file")
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

AL = AL_ASSET.readall()
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
NL = NL_ASSET.readall()
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

CACHE_TIMEOUT = 300  # five minutes

HTTP_SUCCESS_CODE = 200

SMALL_FONT = "CG-pixel-3x5-mono"
SMALL_FONT_COLOR = "#FFA700"

def main(config):
    division_id = int(config.get("division") or NL_CENTRAL)
    year = str(time.now().year)  # use current year

    standings = get_Standings(division_id, year)

    # if we have some widgets, we can display them now
    if len(standings) > 0:
        return render.Root(
            delay = 80,
            show_full_animation = True,
            child = render.Row(
                children = [
                    render_lefter(division_id),
                    animation.Transformation(
                        duration = 180,
                        width = 295,
                        keyframes = [
                            build_keyframe(0, 0.0),
                            build_keyframe(0, 0.08),
                            build_keyframe(-59, 0.25),
                            build_keyframe(-118, 0.50),
                            build_keyframe(-177, 0.75),
                            build_keyframe(-236, 0.9),
                            build_keyframe(-236, 1.0),
                        ],
                        child = render_DivisionStandings(standings),
                        wait_for_child = True,
                    ),
                ],
            ),
        )
    else:
        # otherwise it means something went wrong or we are not yet in standings time
        # display zero-state image
        return render.Root(
            child = render.Stack(
                children = [
                    render.Image(
                        src = MLB_LEAGUE_IMAGE,
                    ),
                    render.Marquee(
                        width = 64,
                        child = render.Text(
                            content = "No standings to display for league year " + year,
                            color = SMALL_FONT_COLOR,
                            font = SMALL_FONT,
                        ),
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

def get_schema():
    options = [
        schema.Option(
            display = "AL West",
            value = str(AL_WEST),
        ),
        schema.Option(
            display = "AL Central",
            value = str(AL_CENTRAL),
        ),
        schema.Option(
            display = "AL East",
            value = str(AL_EAST),
        ),
        schema.Option(
            display = "NL West",
            value = str(NL_WEST),
        ),
        schema.Option(
            display = "NL Central",
            value = str(NL_CENTRAL),
        ),
        schema.Option(
            display = "NL East",
            value = str(NL_EAST),
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "division",
                name = "Division",
                desc = "Which division to display standings for.",
                icon = "baseballBatBall",
                default = str(NL_CENTRAL),
                options = options,
            ),
        ],
    )

def render_lefter(division_id):
    div = DIVISION_MAP.get(division_id)
    lefter = [
        render.Image(
            src = div.Logo,
        ),
        render.Box(
            width = 1,
            height = 1,
        ),
    ]
    div_text = div.Name
    for i in range(len(div_text)):
        lefter.append(
            render_american_word(div_text[i], "CG-pixel-4x5-mono"),
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

def get_Standings(division_id, year):
    if NAT_LEAGUE.get(division_id) != None:
        league_id = NAT_LEAGUE_ID
    else:
        league_id = AMER_LEAGUE_ID

    query_params = {
        "fields": "records,teamRecords,team,id,divisionRank,division,divisionGamesBack,clinched,clinchIndicator,wins,losses",
        "standingsTypes": "regularSeason",
        "leagueId": str(league_id),
        "season": year,
    }

    standings_data = http.get(MLB_STANDINGS_URL, params = query_params, ttl_seconds = CACHE_TIMEOUT)

    standings = []

    # if the http request failed above, return empty standings object
    if standings_data.status_code != HTTP_SUCCESS_CODE:
        return standings

    records = standings_data.json().get("records")

    # if we did not get anything back because there is no data
    # could be too early in the year for data to be displayed
    # either way we need to not fail, return empty standings list
    # we will consume this later and render a different screen
    if len(records) == 0:
        return standings

    for division in records:
        if int(division.get("division").get("id")) == division_id:
            for team in division.get("teamRecords"):
                # get the team and how many games back they are
                # get win-loss
                # and whether they have clinched
                # add to list
                clinch_indicator = team.get("clinchIndicator")
                standings.append(
                    struct(
                        TeamId = int(team.get("team").get("id")),
                        GamesBack = team.get("divisionGamesBack"),
                        Clinched =
                            # "y" is division and "z" is best overall record
                            True if team.get("clinched") and (clinch_indicator == "y" or clinch_indicator == "z") else False,
                        Wins = str(int(team.get("wins"))),
                        Losses = str(int(team.get("losses"))),
                        DivisionRank = str(int(team.get("divisionRank"))),
                    ),
                )
            break  # found our division

    return standings

def render_DivisionStandings(standings):
    team_widgets = []

    for info in standings:
        team_widgets.append(render_team_card(info))

    return render.Row(
        children = team_widgets,
    )

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

def render_rainbow_word(word, font):
    colors = ["#e81416", "#ffa500", "#faeb36", "#79c314", "#487de7", "#4b369d", "#70369d"]
    return render_flashy_word(word, font, colors, 1)

def render_american_word(word, font):
    colors = ["#B31942", "#FFFFFF", "#0A3161"]
    return render_flashy_word(word, font, colors, 4)

def render_team_card(info):
    team_id = info.TeamId
    clinched = info.Clinched
    team = TEAM_INFO[team_id]
    logo_width = 32
    return render.Box(
        height = 32,
        width = 59,
        color = team.BackgroundColor,
        child = render.Row(
            main_align = "space_evenly",
            expanded = True,
            children = [
                render.Padding(
                    pad = (0, 0, 0, 0),
                    child = render.Image(
                        src = team.Logo,
                        width = logo_width,
                    ),
                ),
                render.Column(
                    main_align = "space_evenly",
                    cross_align = "center" if clinched else "end",
                    expanded = True,
                    children = render_record_info(team, clinched, info.Wins, info.Losses, info.GamesBack, info.DivisionRank),
                ),
            ],
        ),
    )

def render_record_info(team, clinched, wins, losses, games_back, div_rank):
    games_back_prefix = "GB" if len(games_back) >= 4 and games_back.endswith(".5") else "GB:"
    if not clinched:
        return [
            render.Text(
                content = "{}-{}".format(wins, losses),
                font = SMALL_FONT,
                color = team.ForegroundColor,
            ),
            render.Text(
                content = games_back_prefix + games_back.removesuffix(".0"),
                font = SMALL_FONT,
                color = team.ForegroundColor,
            ),
            render.Text(
                content = "RANK:" + div_rank,
                font = SMALL_FONT,
                color = team.ForegroundColor,
            ),
        ]
    else:
        return [
            render_rainbow_word("{}-{}".format(wins, losses), SMALL_FONT),
            render_rainbow_word("DIV", SMALL_FONT),
            render_rainbow_word("CHAMP", SMALL_FONT),
        ]

#################
## TEAM CONFIG ##
#################
# division IDs
NL_WEST = 203
NL_CENTRAL = 205
NL_EAST = 204
AL_WEST = 200
AL_CENTRAL = 202
AL_EAST = 201

# league IDs
NAT_LEAGUE_ID = 104
AMER_LEAGUE_ID = 103

NAT_LEAGUE = {NL_WEST: True, NL_CENTRAL: True, NL_EAST: True}
AMER_LEAGUE = {AL_WEST: True, AL_CENTRAL: True, AL_EAST: True}

DIVISION_MAP = {
    NL_WEST: struct(Name = "WEST", Logo = NL),
    NL_CENTRAL: struct(Name = "CENT", Logo = NL),
    NL_EAST: struct(Name = "EAST", Logo = NL),
    AL_WEST: struct(Name = "WEST", Logo = AL),
    AL_CENTRAL: struct(Name = "CENT", Logo = AL),
    AL_EAST: struct(Name = "EAST", Logo = AL),
}

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

def struct_TeamDefinition(name, abbrev, logo, foreground_color, background_color):
    return struct(Name = name, Abbreviation = abbrev, Logo = logo, ForegroundColor = foreground_color, BackgroundColor = background_color)

TEAM_INFO = {
    ARI_TEAM_ID: struct_TeamDefinition("Arizona DiamondBacks", "ARI", ARI_LOGO, "#E3D4AD", "#A71930"),
    ATH_TEAM_ID: struct_TeamDefinition("Athletics", "ATH", ATH_LOGO, "#EFB21E", "#003831"),
    ATL_TEAM_ID: struct_TeamDefinition("Atlanta Braves", "ATL", ATL_LOGO, "#FFFFFF", "#13274F"),
    BOS_TEAM_ID: struct_TeamDefinition("Boston Red Sox", "BOS", BOS_LOGO, "#FFFFFF", "#0C2340"),
    BAL_TEAM_ID: struct_TeamDefinition("Baltimore Orioles", "BAL", BAL_LOGO, "#DF4701", "#000000"),
    CHC_TEAM_ID: struct_TeamDefinition("Chicago Cubs", "CHC", CHC_LOGO, "#CC3433", "#0E3386"),
    CWS_TEAM_ID: struct_TeamDefinition("Chicago White Sox", "CWS", CWS_LOGO, "#C4CED4", "#27251F"),
    CIN_TEAM_ID: struct_TeamDefinition("Cincinnati Reds", "CIN", CIN_LOGO, "#FFFFFF", "#C6011F"),
    CLE_TEAM_ID: struct_TeamDefinition("Cleveland Guardians", "CLE", CLE_LOGO, "#FFFFFF", "#00385D"),
    COL_TEAM_ID: struct_TeamDefinition("Colorado Rockies", "COL", COL_LOGO, "#C4CED4", "#333366"),
    DET_TEAM_ID: struct_TeamDefinition("Detroit Tigers", "DET", DET_LOGO, "#FFFFFF", "#0C2340"),
    HOU_TEAM_ID: struct_TeamDefinition("Houston Astros", "HOU", HOU_LOGO, "#EB6E1F", "#002D62"),
    KC_TEAM_ID: struct_TeamDefinition("Kansas City Royals", "KC", KC_LOGO, "#BD9B60", "#004687"),
    LAA_TEAM_ID: struct_TeamDefinition("Los Angeles Angels", "LAA", LAA_LOGO, "#FFFFFF", "#BA0021"),
    LAD_TEAM_ID: struct_TeamDefinition("Los Angeles Dodgers", "LAD", LAD_LOGO, "#FFFFFF", "#005A9C"),
    MIA_TEAM_ID: struct_TeamDefinition("Miami Marlins", "MIA", MIA_LOGO, "#EF3340", "#000000"),
    MIL_TEAM_ID: struct_TeamDefinition("Milwaukee Brewers", "MIL", MIL_LOGO, "#FFC52F", "#12284B"),
    MIN_TEAM_ID: struct_TeamDefinition("Minnesota Twins", "MIN", MIN_LOGO, "#FFFFFF", "#002B5C"),
    NYM_TEAM_ID: struct_TeamDefinition("New York Mets", "NYM", NYM_LOGO, "#FF5910", "#002D72"),
    NYY_TEAM_ID: struct_TeamDefinition("New York Yankees", "NYY", NYY_LOGO, "#C4CED3", "#0C2340"),
    PHI_TEAM_ID: struct_TeamDefinition("Philadelphia Phillies", "PHI", PHI_LOGO, "#FFFFFF", "#E81828"),
    PIT_TEAM_ID: struct_TeamDefinition("Pittsburgh Pirates", "PIT", PIT_LOGO, "#FDB827", "#27251F"),
    SEA_TEAM_ID: struct_TeamDefinition("Seattle Mariners", "SEA", SEA_LOGO, "#C4CED4", "#0C2C56"),
    SD_TEAM_ID: struct_TeamDefinition("San Diego Padres", "SD", SD_LOGO, "#FFC425", "#2F241D"),
    STL_TEAM_ID: struct_TeamDefinition("St. Louis Cardinals", "STL", STL_LOGO, "#FFFFFF", "#C41E3A"),
    SF_TEAM_ID: struct_TeamDefinition("San Francisco Giants", "SF", SF_LOGO, "#FD5A1E", "#27251F"),
    TB_TEAM_ID: struct_TeamDefinition("Tampa Bay Rays", "TB", TB_LOGO, "#8FBCE6", "#092C5C"),
    TEX_TEAM_ID: struct_TeamDefinition("Texas Rangers", "TEX", TEX_LOGO, "#FFFFFF", "#003278"),
    TOR_TEAM_ID: struct_TeamDefinition("Toronto Blue Jays", "TOR", TOR_LOGO, "#FFFFFF", "#134A8E"),
    WAS_TEAM_ID: struct_TeamDefinition("Washington Nationals", "WAS", WAS_LOGO, "#FFFFFF", "#AB0003"),
}
