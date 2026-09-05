"""
Applet: MLB WildCard Race
Summary: Display wild card race
Description: Displays the standings (in terms of games behind) for the MLB wild card in each league.
Author: Jake Manske
"""

load("animation.star", "animation")
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
GAMES_BACK_FONT = "tb-8"

NL_LEAGUE_ID = "104"
AL_LEAGUE_ID = "103"

HIGHLIGHT_COLOR = "#65FE08"

# get top 9 teams (almost everyone)
DISPLAY_LIMIT = 9

CACHE_TIMEOUT = 300  # five minutes

HTTP_SUCCESS_CODE = 200

SMALL_FONT = "CG-pixel-3x5-mono"
SMALL_FONT_COLOR = "#FFA700"

def main(config):
    league_id = config.get("league") or NL_LEAGUE_ID
    year = str(time.now().year)  #use current year

    standings = get_Standings(league_id, year)

    # if we have some widgets, we can display them now
    if len(standings) > 0:
        return render.Root(
            delay = 80,
            show_full_animation = True,
            child = render.Stack(
                children = [
                    animation.Transformation(
                        duration = 200,
                        height = 81,
                        keyframes = [
                            build_keyframe(5, 0.0),
                            build_keyframe(5, 0.25),
                            build_keyframe(-22, 0.40),
                            build_keyframe(-22, 0.60),
                            build_keyframe(-49, 0.70),
                            build_keyframe(-49, 1.0),
                        ],
                        child = render_WildCardStandings(standings),
                        wait_for_child = True,
                    ),
                    render_header(league_id),
                ],
            ),
        )
    else:
        # otherwise it means something went wrong or we are not yet in wild card standings time
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
                            content = "No wild card race to display for league year " + year,
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
        transforms = [animation.Translate(0, offset)],
        curve = "ease_in_out",
    )

def get_schema():
    options = [
        schema.Option(
            display = "National League",
            value = NL_LEAGUE_ID,
        ),
        schema.Option(
            display = "American League",
            value = AL_LEAGUE_ID,
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "league",
                name = "League",
                desc = "Which league to display the wild card race for.",
                icon = "baseballBatBall",
                default = NL_LEAGUE_ID,
                options = options,
            ),
        ],
    )

def render_header(league_id):
    text = "NL" if league_id == NL_LEAGUE_ID else "AL"
    text += " WILD CARD"
    return render.Box(
        height = 5,
        width = 64,
        color = "#000000",
        child = render_rainbow_word(text, "CG-pixel-4x5-mono"),
    )

def get_Standings(league_id, year):
    query_params = {
        "fields": "records,teamRecords,team,id,wildCardGamesBack,clinched,clinchIndicator,wildCardEliminationNumber",
        "standingsTypes": "wildCard",
        "leagueId": league_id,
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

    limiter = 0

    for team in records[0].get("teamRecords"):
        if limiter >= DISPLAY_LIMIT:
            break

        # get the team and how many games back they are
        # and whether they have clinched
        team_id = int(team.get("team").get("id"))
        games_back = team.get("wildCardGamesBack")
        clinched = team.get("clinched") or False
        elim_number = team.get("wildCardEliminationNumber")
        if elim_number != None and elim_number == "E":
            eliminated = True
        else:
            eliminated = False

        # add to list
        standings.append(
            {
                "TeamId": team_id,
                "GamesBack": games_back,
                "Clinched": clinched,
                "Eliminated": eliminated,
            },
        )
        limiter += 1

    return standings

def render_WildCardStandings(standings):
    team_widgets = []
    games_back_widgets = []
    pos = 1
    max_games_back_length = 0

    for info in standings:
        team_id = info.get("TeamId")
        clinched = info.get("Clinched")
        eliminated = info.get("Eliminated")

        # strip ".0", we don't need it
        games_back = info.get("GamesBack").removesuffix(".0")

        # keep track of games_back length so we can align everything
        if len(games_back) > max_games_back_length:
            max_games_back_length = len(games_back)
        team_widgets.append(render_Team(team_id, pos, clinched, eliminated))
        games_back_widgets.append(render_GamesBack(team_id, games_back, clinched))
        pos += 1

    return render.Stack(
        children = [
            render.Column(
                children = team_widgets,
            ),
            render.Column(
                cross_align = "end",
                children = games_back_widgets,
            ),
        ],
    )

def render_rainbow_word(word, font):
    colors = ["#e81416", "#ffa500", "#faeb36", "#79c314", "#487de7", "#4b369d", "#70369d"]
    widgets = []
    for j in range(7):
        rainbow_word = []
        for i in range(len(word)):
            letter = render.Text(
                content = word[i],
                font = font,
                color = colors[(j + i) % 7],
            )
            rainbow_word.append(letter)
        widgets.append(
            render.Row(
                children = rainbow_word,
            ),
        )
    return render.Animation(
        children = widgets,
    )

def render_Team(team_id, pos, clinched, eliminated):
    team = TEAM_INFO[team_id]
    logo_width = 20
    if clinched:
        abbrev = render_rainbow_word(TEAM_INFO[team_id].Abbreviation, GAMES_BACK_FONT)
        pos_widget = render_rainbow_word(str(pos), SMALL_FONT)
    else:
        abbrev = render.Text(
            content = team.Abbreviation,
            font = GAMES_BACK_FONT,
            color = team.ForegroundColor,
        )
        if eliminated:
            pos_widget = render_drop_shadow("E", SMALL_FONT, "#FF3131")
        else:
            pos_widget = render.Text(
                content = str(pos),
                font = SMALL_FONT,
                color = HIGHLIGHT_COLOR,
            )
    return render.Box(
        height = 9,
        width = 64,
        color = team.BackgroundColor,
        child = render.Row(
            main_align = "start",
            expanded = True,
            children = [
                pos_widget,
                render.Padding(
                    pad = (0, team.Offset, 0, 0),
                    child = render.Image(
                        src = team.Logo,
                        width = logo_width,
                    ),
                ),
                render.Box(
                    height = 1,
                    width = 1,
                ),
                render.Padding(
                    pad = (0, 1, 0, 0),
                    child = abbrev,
                ),
            ],
        ),
    )

def render_drop_shadow(text, font, foreground_color, background_color = "#000000"):
    return render.Stack(
        children = [
            render.Padding(
                pad = (0, 1, 0, 0),
                child = render.Text(
                    content = text,
                    font = font,
                    color = background_color,
                ),
            ),
            render.Text(
                content = text,
                font = font,
                color = foreground_color,
            ),
        ],
    )

def render_GamesBack(team_id, games_back, clinched):
    # "+1" is weird and has an extra space we should contend with
    offset = 64 - 4 * len(games_back) - (2 if games_back.startswith("+1") else 1)
    if clinched:
        gb_widget = render_rainbow_word(games_back, GAMES_BACK_FONT)
    else:
        gb_widget = render.Text(
            content = games_back,
            font = GAMES_BACK_FONT,
            color = TEAM_INFO[team_id].ForegroundColor,
        )
    return render.Row(
        children = [
            render.Box(
                height = 1,
                width = offset,
            ),
            render.Padding(
                pad = (0, 1, 0, 0),
                child = gb_widget,
            ),
        ],
    )

def get_BoxWidth(max_games_back_length):
    width = 0
    if max_games_back_length == 5:
        width = 64 - 4 * max_games_back_length - 1
    else:
        width = 64 - 4 * max_games_back_length
    return width

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

def struct_TeamDefinition(name, abbrev, logo, foreground_color, background_color, vertical_offset = -3):
    return struct(Name = name, Abbreviation = abbrev, Logo = logo, ForegroundColor = foreground_color, BackgroundColor = background_color, Offset = vertical_offset)

TEAM_INFO = {
    ARI_TEAM_ID: struct_TeamDefinition("Arizona DiamondBacks", "ARI", ARI_LOGO, "#E3D4AD", "#A71930"),
    ATH_TEAM_ID: struct_TeamDefinition("Athletics", "ATH", ATH_LOGO, "#EFB21E", "#003831", -6),
    ATL_TEAM_ID: struct_TeamDefinition("Atlanta Braves", "ATL", ATL_LOGO, "#FFFFFF", "#13274F", -6),
    BOS_TEAM_ID: struct_TeamDefinition("Boston Red Sox", "BOS", BOS_LOGO, "#FFFFFF", "#0C2340", -5),
    BAL_TEAM_ID: struct_TeamDefinition("Baltimore Orioles", "BAL", BAL_LOGO, "#DF4701", "#000000"),
    CHC_TEAM_ID: struct_TeamDefinition("Chicago Cubs", "CHC", CHC_LOGO, "#CC3433", "#0E3386", -5),
    CWS_TEAM_ID: struct_TeamDefinition("Chicago White Sox", "CWS", CWS_LOGO, "#C4CED4", "#27251F"),
    CIN_TEAM_ID: struct_TeamDefinition("Cincinnati Reds", "CIN", CIN_LOGO, "#FFFFFF", "#C6011F", -5),
    CLE_TEAM_ID: struct_TeamDefinition("Cleveland Guardians", "CLE", CLE_LOGO, "#FFFFFF", "#00385D", -6),
    COL_TEAM_ID: struct_TeamDefinition("Colorado Rockies", "COL", COL_LOGO, "#C4CED4", "#333366", -6),
    DET_TEAM_ID: struct_TeamDefinition("Detroit Tigers", "DET", DET_LOGO, "#FFFFFF", "#0C2340"),
    HOU_TEAM_ID: struct_TeamDefinition("Houston Astros", "HOU", HOU_LOGO, "#EB6E1F", "#002D62", -6),
    KC_TEAM_ID: struct_TeamDefinition("Kansas City Royals", "KC", KC_LOGO, "#BD9B60", "#004687", -6),
    LAA_TEAM_ID: struct_TeamDefinition("Los Angeles Angels", "LAA", LAA_LOGO, "#FFFFFF", "#BA0021", -10),
    LAD_TEAM_ID: struct_TeamDefinition("Los Angeles Dodgers", "LAD", LAD_LOGO, "#FFFFFF", "#005A9C", -8),
    MIA_TEAM_ID: struct_TeamDefinition("Miami Marlins", "MIA", MIA_LOGO, "#EF3340", "#000000"),
    MIL_TEAM_ID: struct_TeamDefinition("Milwaukee Brewers", "MIL", MIL_LOGO, "#FFC52F", "#12284B", -6),
    MIN_TEAM_ID: struct_TeamDefinition("Minnesota Twins", "MIN", MIN_LOGO, "#FFFFFF", "#002B5C"),
    NYM_TEAM_ID: struct_TeamDefinition("New York Mets", "NYM", NYM_LOGO, "#FF5910", "#002D72"),
    NYY_TEAM_ID: struct_TeamDefinition("New York Yankees", "NYY", NYY_LOGO, "#C4CED3", "#0C2340"),
    PHI_TEAM_ID: struct_TeamDefinition("Philadelphia Phillies", "PHI", PHI_LOGO, "#FFFFFF", "#E81828"),
    PIT_TEAM_ID: struct_TeamDefinition("Pittsburgh Pirates", "PIT", PIT_LOGO, "#FDB827", "#27251F", -6),
    SEA_TEAM_ID: struct_TeamDefinition("Seattle Mariners", "SEA", SEA_LOGO, "#C4CED4", "#0C2C56", -5),
    SD_TEAM_ID: struct_TeamDefinition("San Diego Padres", "SD", SD_LOGO, "#FFC425", "#2F241D"),
    STL_TEAM_ID: struct_TeamDefinition("St. Louis Cardinals", "STL", STL_LOGO, "#FFFFFF", "#C41E3A", -6),
    SF_TEAM_ID: struct_TeamDefinition("San Francisco Giants", "SF", SF_LOGO, "#FD5A1E", "#27251F"),
    TB_TEAM_ID: struct_TeamDefinition("Tampa Bay Rays", "TB", TB_LOGO, "#8FBCE6", "#092C5C"),
    TEX_TEAM_ID: struct_TeamDefinition("Texas Rangers", "TEX", TEX_LOGO, "#FFFFFF", "#003278"),
    TOR_TEAM_ID: struct_TeamDefinition("Toronto Blue Jays", "TOR", TOR_LOGO, "#FFFFFF", "#134A8E"),
    WAS_TEAM_ID: struct_TeamDefinition("Washington Nationals", "WAS", WAS_LOGO, "#FFFFFF", "#AB0003"),
}
