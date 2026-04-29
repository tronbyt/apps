"""
Applet: FlyTheL
Summary: Show MLB Win/Loss Status
Description: Displays whether your chosen MLB team has recently won or lost.
Author: Jake Manske
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/ari_logo.png", ARI_LOGO_ASSET = "file")
load("images/ath_logo.png", ATH_LOGO_ASSET = "file")
load("images/atl_logo.png", ATL_LOGO_ASSET = "file")
load("images/bal_logo.png", BAL_LOGO_ASSET = "file")
load("images/bos_logo.png", BOS_LOGO_ASSET = "file")
load("images/bottom_inning.png", BOTTOM_INNING_ASSET = "file")
load("images/chc_logo.png", CHC_LOGO_ASSET = "file")
load("images/cin_logo.png", CIN_LOGO_ASSET = "file")
load("images/cle_logo.png", CLE_LOGO_ASSET = "file")
load("images/col_logo.png", COL_LOGO_ASSET = "file")
load("images/cws_logo.png", CWS_LOGO_ASSET = "file")
load("images/det_logo.png", DET_LOGO_ASSET = "file")
load("images/empty_base_img.png", EMPTY_BASE_IMG_ASSET = "file")
load("images/hou_logo.png", HOU_LOGO_ASSET = "file")
load("images/kc_logo.png", KC_LOGO_ASSET = "file")
load("images/laa_logo.png", LAA_LOGO_ASSET = "file")
load("images/lad_logo.png", LAD_LOGO_ASSET = "file")
load("images/mia_logo.png", MIA_LOGO_ASSET = "file")
load("images/mil_logo.png", MIL_LOGO_ASSET = "file")
load("images/min_logo.png", MIN_LOGO_ASSET = "file")
load("images/mlb_league_image.png", MLB_LEAGUE_IMAGE_ASSET = "file")
load("images/no_out.png", NO_OUT_ASSET = "file")
load("images/nym_logo.png", NYM_LOGO_ASSET = "file")
load("images/nyy_logo.png", NYY_LOGO_ASSET = "file")
load("images/occupied_base_img.png", OCCUPIED_BASE_IMG_ASSET = "file")
load("images/out.png", OUT_ASSET = "file")
load("images/phi_logo.png", PHI_LOGO_ASSET = "file")
load("images/pit_logo.png", PIT_LOGO_ASSET = "file")
load("images/sd_logo.png", SD_LOGO_ASSET = "file")
load("images/sea_logo.png", SEA_LOGO_ASSET = "file")
load("images/sf_logo.png", SF_LOGO_ASSET = "file")
load("images/stl_logo.png", STL_LOGO_ASSET = "file")
load("images/tb_logo.png", TB_LOGO_ASSET = "file")
load("images/tex_logo.png", TEX_LOGO_ASSET = "file")
load("images/top_inning.png", TOP_INNING_ASSET = "file")
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
BOTTOM_INNING = BOTTOM_INNING_ASSET.readall()
CHC_LOGO = CHC_LOGO_ASSET.readall()
CIN_LOGO = CIN_LOGO_ASSET.readall()
CLE_LOGO = CLE_LOGO_ASSET.readall()
COL_LOGO = COL_LOGO_ASSET.readall()
CWS_LOGO = CWS_LOGO_ASSET.readall()
DET_LOGO = DET_LOGO_ASSET.readall()
EMPTY_BASE_IMG = EMPTY_BASE_IMG_ASSET.readall()
HOU_LOGO = HOU_LOGO_ASSET.readall()
KC_LOGO = KC_LOGO_ASSET.readall()
LAA_LOGO = LAA_LOGO_ASSET.readall()
LAD_LOGO = LAD_LOGO_ASSET.readall()
MIA_LOGO = MIA_LOGO_ASSET.readall()
MIL_LOGO = MIL_LOGO_ASSET.readall()
MIN_LOGO = MIN_LOGO_ASSET.readall()
MLB_LEAGUE_IMAGE = MLB_LEAGUE_IMAGE_ASSET.readall()
NO_OUT = NO_OUT_ASSET.readall()
NYM_LOGO = NYM_LOGO_ASSET.readall()
NYY_LOGO = NYY_LOGO_ASSET.readall()
OCCUPIED_BASE_IMG = OCCUPIED_BASE_IMG_ASSET.readall()
OUT = OUT_ASSET.readall()
PHI_LOGO = PHI_LOGO_ASSET.readall()
PIT_LOGO = PIT_LOGO_ASSET.readall()
SD_LOGO = SD_LOGO_ASSET.readall()
SEA_LOGO = SEA_LOGO_ASSET.readall()
SF_LOGO = SF_LOGO_ASSET.readall()
STL_LOGO = STL_LOGO_ASSET.readall()
TB_LOGO = TB_LOGO_ASSET.readall()
TEX_LOGO = TEX_LOGO_ASSET.readall()
TOP_INNING = TOP_INNING_ASSET.readall()
TOR_LOGO = TOR_LOGO_ASSET.readall()
WAS_LOGO = WAS_LOGO_ASSET.readall()

DEFAULT_TIMEZONE = "America/Chicago"
DEFAULT_RELATIVE = "relative"
FIVE_WIDE_FONT = "CG-pixel-4x5-mono"
DEFAULT_TEAM = "112"
DEFAULT_HOUR_TO_SWITCH = "10"
OK = 200
SMALL_FONT = "CG-pixel-3x5-mono"
SMALL_FONT_COLOR = "#39FF14"
INNING_COLOR = "#ffd500"
LIVE_DATA_CACHE_TTL = 300  # cache live data for 5 minutes in case API calls fail

# this is used in case the cache is empty so we do not bomb out completely
DEFAULT_LIVE_DATA = """
{
    "plays": {
        "allPlays": [
            {
                "result": {
                    "isCompleted": true,
                    "event": "",
                    "eventType": "",
                    "description": ""
                },
                "about": {
                    "halfInning": "top",
                    "isTopInning": true,
                    "inning": 1,
                    "isScoringPlay": false
                },
                "count": {
                    "balls": 0,
                    "strikes": 0,
                    "outs": 0
                },
                "matchup": {
                    "batter": {
                        "id": 0
                    },
                    "pitcher": {
                        "id": 0
                    }
                },
                "runners": [
                    {
                        "details": {
                            "event": "Groundout",
                            "eventType": "field_out",
                            "runner": {
                                "id": 0
                            }
                        },
                        "credits": [
                            {
                                "position": {
                                    "code": "1"
                                }
                            }
                        ]
                    }
                ]
            }
        ],
        "currentPlay": {
            "matchup": { }
        }
    },
    "linescore": {
        "currentInning": 1,
        "isTopInning": true,
        "teams": {
            "home": {
                "runs": 0,
                "hits": 0,
                "errors": 0
            },
            "away": {
                "runs": 0,
                "hits": 0,
                "errors": 0
            }
        },
        "balls": 0,
        "strikes": 0,
        "outs": 0
    },
    "boxscore": {
        "teams": {
            "home": {
                "players": {
                    "parentTeamId": 144
                },
                "battingOrder": [

                ]
            },
            "away": {
                "players": {
                    "parentTeamId": 144
                },
                "battingOrder": [

                ]
            }
        }
    }
}
"""
DEFAULT_GAME_DATA = """
{
    "players": {

    }
}
"""
MLB_SCHED_ENDPOINT = "/api/v1/schedule/games/"
MLB_BASE_URL = "https://statsapi.mlb.com{0}"

def main(config):
    timezone = time.tz()
    team = config.str("team", DEFAULT_TEAM)
    hour_to_switch = int(config.str("hour", DEFAULT_HOUR_TO_SWITCH))
    relative_or_absolute = config.str("game_time", DEFAULT_RELATIVE)

    # get schedule
    response = get_sched(team, timezone)

    # if API call is not successful render generic error screen
    if response.status_code != OK:
        return render.Root(
            child = render_http_error(response),
        )

    # we are good, go ahead and start processing the schedule
    sched = response.json()

    # figure out what to display
    current_hour = get_now(timezone).hour
    yesterday = get_yesterday_date(timezone)

    game = None
    if current_hour < hour_to_switch:
        # want to do yesterday's game, if it exists (will be 0-index if it is there)
        event = sched.get("dates")[0]
        if event.get("date") == yesterday:
            # TODO: add handling for doubleheaders somehow
            game = event.get("games")[0]

    # if we didn't find a game above, find one now
    if not game:
        # loop through events until we find one to display
        for event in sched.get("dates"):
            if event.get("date") > yesterday:
                # TODO: add handling for doubleheaders somehow
                game = event.get("games")[0]
                break  # we found what we wanted, break

    # if we still have no game, it means no games are scheduled for the next week
    # display zero state image
    if not game:
        widget = render_no_games(team)
    else:
        widget = render_game(game, team, timezone, relative_or_absolute)

    return render.Root(
        show_full_animation = True,
        child = widget,
    )

def render_no_games(team):
    team = int(team)
    return render.Row(
        children = [
            render.Image(
                src = TEAM_INFO[team].Logo,
            ),
            render.Box(
                width = 32,
                height = 32,
                color = TEAM_INFO[team].BackgroundColor,
                child = render.WrappedText(
                    align = "center",
                    content = "no games for the next week",
                    linespacing = 1,
                    font = SMALL_FONT,
                    color = TEAM_INFO[team].ForegroundColor,
                ),
            ),
        ],
    )

def get_time_to_game(game, timezone, relative_or_absolute):
    # if start time is in the past, say "starting now"
    game_time = time.parse_time(game.get("gameDate")).in_location(timezone)

    time_to_game = get_now(timezone) - game_time

    if time_to_game > time.parse_duration("0s"):
        return struct(Imminent = True, Message = "starting now")

    if relative_or_absolute == "relative":
        # otherwise say how close to the game we are
        relative = humanize.time(game_time).split(" ")

        # don't crash if we don't have the length we are expecting
        if len(relative) < 2:
            return struct(Imminent = True, Message = "starting now")
        return struct(Imminent = False, Message = "in " + relative[0] + " " + relative[1])
    else:
        nice_time = humanize.time_format("M/d K:mm", game_time)
        hour = game_time.hour
        if hour >= 12:
            meridiem = "PM"
        else:
            meridiem = "AM"
        return struct(Imminent = False, Message = str(nice_time + meridiem))

def get_now(timezone):
    return time.now().in_location(timezone)

def render_http_error(response):
    return render.Stack(
        children = [
            render.Image(
                src = MLB_LEAGUE_IMAGE,
            ),
            render.Marquee(
                width = 64,
                child = render.Text(
                    content = "HTTP error: " + str(response.status_code),
                    color = SMALL_FONT_COLOR,
                    font = SMALL_FONT,
                ),
            ),
        ],
    )

def render_game(game, team, timezone, relative_or_absolute):
    # get the game state
    status = game.get("statusFlags")

    # if game is cancelled/postponed/delayed or in pre-game, show that
    if should_render_preview(status):
        return render_preview(game, timezone, status, relative_or_absolute)

    # game is finished, render final
    if status.get("isFinal"):
        return render_final(game, team)

    # otherwise the game must be in progress, so render that
    return render_in_progress(game)

def should_render_preview(status):
    return status.get("isCancelled") or status.get("isSuspended") or status.get("isPostponed") or status.get("isDelayed") or status.get("isPreGameDelay") or status.get("isInGameDelay") or status.get("isPreview") or status.get("isWarmup")

def render_final(game, team):
    away = game.get("teams").get("away")
    winner = False
    if str(int(away.get("team").get("id"))) == team:
        winner = away.get("isWinner")
    else:
        winner = game.get("teams").get("home").get("isWinner")
    return render_flag(team, winner)

def render_flag(team, winner):
    team = int(team)

    # cubs get the special flag
    if team == CHC_TEAM_ID:
        fg = TEAM_INFO[team].BackgroundColor if winner else "#FFFFFF"
        bg = "#FFFFFF" if winner else TEAM_INFO[team].BackgroundColor
    else:
        bg = TEAM_INFO[team].BackgroundColor if winner else TEAM_INFO[team].ForegroundColor
        fg = TEAM_INFO[team].ForegroundColor if winner else TEAM_INFO[team].BackgroundColor
    return render.Box(
        height = 32,
        width = 64,
        color = bg,
        child = render_W(fg) if winner else render_L(fg),
    )

def render_preview(game, timezone, status, relative_or_absolute):
    msg = ""
    if status.get("isCancelled"):
        msg = "cancelled"
    if status.get("isSuspended"):
        msg = "suspended"
    if status.get("isPostponed"):
        msg = "postponed"
    if status.get("isDelayed") or status.get("isPreGameDelay") or status.get("isInGameDelay"):
        msg = "delayed"

    away_id = get_away_team_id(game)
    home_id = get_home_team_id(game)

    game_time = get_time_to_game(game, timezone, relative_or_absolute)

    footer = None
    if len(msg) > 0:
        footer = render_preview_msg(msg, False)
    elif game_time.Imminent:
        footer = render_preview_msg(game_time.Message, True)
    else:
        footer = render_pitcher_preview(game, game_time.Message)

    return render.Column(
        cross_align = "center",
        children = [
            render.Row(
                children = [
                    render.Image(
                        src = TEAM_INFO[away_id].Logo,
                        width = 26,
                    ),
                    render.Text(
                        content = "at",
                        font = "6x13",
                        color = INNING_COLOR,
                    ),
                    render.Image(
                        src = TEAM_INFO[home_id].Logo,
                        width = 26,
                    ),
                ],
            ),
            footer,
        ],
    )

def render_preview_msg(msg, flashy):
    return render.Box(
        height = 6,
        width = 64,
        child = render.Text(
            font = FIVE_WIDE_FONT,
            content = msg,
        ) if not flashy else render_rainbow_word(msg, FIVE_WIDE_FONT),
    )

def render_pitcher_preview(game, time_to_game):
    away = get_away_team_id(game)
    away_pitcher = get_away_probable_pitcher(game)
    home = get_home_team_id(game)
    home_pitcher = get_home_probable_pitcher(game)

    return animation.Transformation(
        duration = 200,
        height = 24,
        keyframes = [
            build_keyframe(0, 0.0),
            build_keyframe(-6, 0.25),
            build_keyframe(-12, 0.5),
            build_keyframe(-18, 0.75),
            build_keyframe(-18, 1.0),
        ],
        wait_for_child = True,
        child = render.Column(
            children = [
                render.Box(
                    height = 6,
                    width = 64,
                    child = render.Text(
                        font = FIVE_WIDE_FONT,
                        content = time_to_game,
                    ),
                ),
                render_player(away, away_pitcher),
                render.Box(
                    height = 6,
                    width = 64,
                    child = render_american_word("versus", FIVE_WIDE_FONT),
                ),
                render_player(home, home_pitcher),
            ],
        ),
    )

def build_keyframe(offset, pct):
    return animation.Keyframe(
        percentage = pct,
        transforms = [animation.Translate(0, offset)],
        curve = "ease_in_out",
    )

def render_player(team, player):
    team = int(team)
    bg = TEAM_INFO[team].BackgroundColor
    fg = TEAM_INFO[team].ForegroundColor
    sanitized = ""

    # sanitize the pitcher name
    # the font we use cannot handle diacritical marks
    if player != None:
        sanitized = sanitize_name(player.get("useLastName"))

    return render.Box(
        height = 6,
        width = 64,
        color = bg,
        child = render.Text(
            font = FIVE_WIDE_FONT if len(sanitized) < 14 else SMALL_FONT,
            color = fg,
            content = sanitized if player != None else "TBD",
        ),
    )

def sanitize_name(name):
    return name.replace("ó", "o").replace("í", "i").replace("é", "e").replace("á", "a").replace("ñ", "n")

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

def render_in_progress(game):
    # we have to make another API call here
    # but if a game is in progress, we do not want to fail because an API call failed
    url = MLB_BASE_URL.format(game.get("link"))

    # hit the API again to get current in-game live data
    query_params = {
        "fields": ",".join(LIVE_DATA_FIELDS),
    }

    # refresh this every 15 seconds to stay up to date
    response = http.get(url, params = query_params, ttl_seconds = 15)

    # this is our cache key
    cache_key = str(int(game.get("gamePk")))

    # if the API call failed for some reason, get the linescore from the last successful call
    if response.status_code != OK:
        data = cache.get(cache_key)
        if data != None:
            live_data = json.decode(data).get("liveData")
            game_data = json.decode(data).get("gameData")
        else:
            live_data = json.decode(DEFAULT_LIVE_DATA)
            game_data = json.decode(DEFAULT_GAME_DATA)
    else:
        decoded = response.json()
        live_data = decoded.get("liveData")
        game_data = decoded.get("gameData")

        # cache this data
        # we almost never look it up because we are using http cache almost all of the time
        # but in case the http call fails for some reason, we want to be able to use the latest result we got from the API
        cache.set(key = cache_key, value = json.encode(decoded), ttl_seconds = LIVE_DATA_CACHE_TTL)

    return render.Stack(
        children = [
            render.Column(
                children = [
                    render_in_progress_header(live_data, game_data),
                    render_competitors(game),
                    render.Box(
                        height = 1,
                        width = 1,
                    ),
                    render_in_progress_footer(live_data),
                ],
            ),
            render_state(live_data),
        ],
    )

def render_in_progress_footer(live_data):
    return render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            render_linescore(live_data, "away"),
            render_linescore(live_data, "home"),
        ],
    )

def render_competitors(game):
    away_id = get_away_team_id(game)
    home_id = get_home_team_id(game)

    return render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            render_team_logo(away_id),
            render_team_logo(home_id),
        ],
    )

def render_team_logo(team_id):
    return render.Image(
        src = TEAM_INFO[team_id].Logo,
        width = 21,
    )

def process_play(play):
    # cache the result node
    result_node = play.get("result")

    # parse the result
    outcome = result_node.get("eventType")
    event = result_node.get("event")
    desc = result_node.get("description")

    # get the outcome code from our map
    code = PLAY_OUTCOME_MAP.get(outcome, "")

    # if it is an error or a certain kind of field out, it is easy to render more details
    if outcome == "field_error" or (outcome == "field_out" and (event == "Flyout" or event == "Lineout" or event == "Pop Out")):
        # get the credits
        # TODO: figure out a good way to render things like 6-3 putout
        abbrev = ""
        if outcome == "field_error":
            abbrev = "E"
        elif event == "Flyout" or event == "Lineout" or event == "Pop Out":
            abbrev = event[0]
        for runner in play.get("runners"):
            details = runner.get("details")
            if details.get("eventType") == outcome:
                credits = runner.get("credits")
                if len(credits) > 0:
                    position_code = int(credits[0].get("position").get("code"))

                    # if we got this far, update the code we display from our map to something more desscriptive
                    code = abbrev + str(position_code)

        # if it is a strikeout, we can make it forward or backward K
    elif outcome == "strikeout":
        if desc.find("called out") > -1:
            return render_backward_K()
        else:
            return render.Row(
                children = [
                    render.Box(
                        height = 1,
                        width = 1,
                    ),
                    render.Text(
                        font = FIVE_WIDE_FONT,
                        color = INNING_COLOR,
                        content = code,
                    ),
                ],
            )

    # make it flashy if there was a run scored
    if play.get("about").get("isScoringPlay"):
        widget = render_rainbow_word(code, SMALL_FONT)
    else:
        widget = render.Text(
            font = SMALL_FONT,
            color = INNING_COLOR,
            content = code,
        )
    return widget

def render_backward_K():
    color = INNING_COLOR
    return render.Row(
        children = [
            render.Column(
                children = [
                    render_block(1, 1, color),
                    render_blank_block(1, 3),
                    render_block(1, 1, color),
                ],
            ),
            render.Column(
                children = [
                    render_blank_block(1, 1),
                    render_block(1, 1, color),
                    render_blank_block(1, 1),
                    render_block(1, 1, color),
                ],
            ),
            render.Column(
                children = [
                    render_blank_block(1, 2),
                    render_block(1, 1, color),
                ],
            ),
            render_block(1, 5, color),
        ],
    )

def render_in_progress_header(live_data, game_data):
    play = get_play_to_process(live_data)

    # get the batter and pitcher
    matchup = play.get("matchup")
    batter_id = matchup.get("batter").get("id")
    pitcher_id = matchup.get("pitcher").get("id")
    boxscore = live_data.get("boxscore").get("teams")

    away_team_lineup = boxscore.get("away").get("battingOrder")
    home_team_lineup = boxscore.get("home").get("battingOrder")
    home_players = boxscore.get("home").get("players")
    away_players = boxscore.get("away").get("players")

    batter_dict_id = "ID" + str(int(batter_id))
    pitcher_dict_id = "ID" + str(int(pitcher_id))
    batter = home_players.get(batter_dict_id)
    pitcher = away_players.get(pitcher_dict_id)

    # if we didn't find the batter, flip from home to away
    if batter == None:
        batter = away_players.get(batter_dict_id)
        pitcher = home_players.get(pitcher_dict_id)
        lineup = away_team_lineup
    else:
        lineup = home_team_lineup

    # do not use .index here
    # it throws an error if the element is not in the list
    # instead loop over the list
    order = "?"
    for i in range(len(lineup)):
        if batter_id == lineup[i]:
            order = i + 1
            break

    # can be no pitcher if API calls failed and cache was not populated
    if pitcher != None:
        pitches = int(pitcher.get("stats").get("pitching").get("numberOfPitches") or 0)
    else:
        pitches = 0

    # get the team of each player
    # this is more straightforward than trying to figure out
    # who is at bat based on top/bottom of inning, which is less reliable
    if batter != None and pitcher != None:
        batter_team_id = int(batter.get("parentTeamId"))
        pitcher_team_id = int(pitcher.get("parentTeamId"))
    else:
        batter_team_id = int(DEFAULT_TEAM)
        pitcher_team_id = int(DEFAULT_TEAM)

    # go back to the overall player dictionary to get the last name
    batter = game_data.get("players").get(batter_dict_id)
    if batter != None:
        batter_name = sanitize_name(batter.get("useLastName"))
    else:
        batter_name = "???"
    pitcher = game_data.get("players").get(pitcher_dict_id)
    if pitcher != None:
        pitcher_name = sanitize_name(pitcher.get("useLastName"))
    else:
        pitcher_name = "???"

    matchup_array = []
    ranger = 100
    for _ in range(ranger):
        matchup_array.append(
            render.Box(
                width = 64,
                height = 5,
                color = TEAM_INFO[batter_team_id].BackgroundColor,
                child = render.Text(
                    content = str(order) + "." + batter_name,
                    font = FIVE_WIDE_FONT if len(batter_name) < 12 else SMALL_FONT,
                    color = TEAM_INFO[batter_team_id].ForegroundColor,
                ),
            ),
        )
    for _ in range(ranger):
        matchup_array.append(
            render.Box(
                width = 64,
                height = 5,
                color = TEAM_INFO[pitcher_team_id].BackgroundColor,
                child = render.Row(
                    children = [
                        render.Text(
                            content = pitcher_name,
                            font = FIVE_WIDE_FONT if len(pitcher_name) < 12 else SMALL_FONT,
                            color = TEAM_INFO[pitcher_team_id].ForegroundColor,
                        ),
                        render.Box(
                            width = 2,
                            height = 1,
                        ),
                        render.Text(
                            content = str(pitches),
                            font = FIVE_WIDE_FONT,
                            color = TEAM_INFO[pitcher_team_id].ForegroundColor,
                        ),
                    ],
                ),
            ),
        )
    return render.Animation(
        children = matchup_array,
    )

def render_linescore(live_data, team_type):
    runs = get_runs(live_data, team_type)
    hits = get_hits(live_data, team_type)
    errors = get_errors(live_data, team_type)

    # dynamically size linescore font based on whether runs or hits are double digits
    if len(runs) >= 2 or len(hits) >= 2:
        font = SMALL_FONT
    else:
        font = FIVE_WIDE_FONT
    return render.Row(
        children = [
            render.Text(
                font = font,
                content = runs,
            ),
            render_separator(),
            render.Box(
                height = 1,
                width = 1,
            ),
            render.Text(
                font = font,
                content = hits,
            ),
            render_separator(),
            render.Box(
                height = 1,
                width = 1,
            ),
            render.Text(
                font = font,
                content = errors,
            ),
        ],
    )

def get_runs(game, team_type):
    return str(int(game.get("linescore").get("teams").get(team_type).get("runs")))

def get_hits(game, team_type):
    return str(int(game.get("linescore").get("teams").get(team_type).get("hits")))

def get_errors(game, team_type):
    return str(int(game.get("linescore").get("teams").get(team_type).get("errors")))

def render_inning(inning, half_inning, outs):
    array = []
    if outs == 3:
        if half_inning == "top":
            content = "MID"
        else:
            content = "END"
        content += " " if inning < 10 else ""
        array.append(
            render.Text(
                content = content,
                font = SMALL_FONT,
                color = INNING_COLOR,
            ),
        )
    array.append(
        render.Text(
            content = str(inning),
            font = FIVE_WIDE_FONT,
            color = INNING_COLOR,
        ),
    )
    if outs < 3:
        is_top = half_inning == "top"
        array.append(
            render.Padding(
                pad = (0, 1 if is_top else 2, 0, 0),
                child = render.Image(
                    src = TOP_INNING if is_top else BOTTOM_INNING,
                ),
            ),
        )

    return render.Row(
        expanded = True,
        main_align = "center",
        children = array,
    )

def get_play_to_process(live_data):
    # need the most recent completed play
    # start by seeing if the most recent play is completed
    # if it is not, then the one right before it will be
    all_plays = live_data.get("plays").get("allPlays")
    play = all_plays[-1]

    if not play.get("about").get("isComplete") and len(all_plays) > 1:
        play = all_plays[len(all_plays) - 2]
    return play

def render_state(live_data):
    play = get_play_to_process(live_data)
    inning = int(play.get("about").get("inning"))
    half_inning = play.get("about").get("halfInning")
    outs = int(play.get("count").get("outs"))

    return render.Padding(
        pad = (22, 3, 0, 0),
        child = render.Box(
            height = 32,
            width = 22,
            child = render.Column(
                main_align = "start",
                cross_align = "center",
                children = [
                    render_inning(inning, half_inning, outs),
                    render.Box(
                        height = 1,
                        width = 1,
                    ),
                    render_bases(live_data),
                    render.Box(
                        height = 1,
                        width = 1,
                    ),
                    render_current_outs(outs),
                    render.Box(
                        height = 1,
                        width = 1,
                    ),
                    process_play(play),
                ],
            ),
        ),
    )

def render_count(balls, strikes):
    content = ""
    if balls == 4:
        content = "BB"
    elif strikes == 3:
        content = "K"
    else:
        content = str(balls) + "-" + str(strikes)
    return render.Text(
        font = SMALL_FONT,
        content = content,
        color = INNING_COLOR,
    )

def render_bases(live_data):
    if live_data.get("plays").get("currentPlay") == None:
        first = EMPTY_BASE_IMG
        second = EMPTY_BASE_IMG
        third = EMPTY_BASE_IMG
    else:
        matchup = live_data.get("plays").get("currentPlay").get("matchup")
        first = OCCUPIED_BASE_IMG if matchup.get("postOnFirst") != None else EMPTY_BASE_IMG
        second = OCCUPIED_BASE_IMG if matchup.get("postOnSecond") != None else EMPTY_BASE_IMG
        third = OCCUPIED_BASE_IMG if matchup.get("postOnThird") != None else EMPTY_BASE_IMG

    return render.Stack(
        children = [
            render.Row(
                children = [
                    render.Box(
                        height = 4,
                        width = 3,
                    ),
                    render.Column(
                        cross_align = "center",
                        children = [
                            render.Image(
                                src = second,  # second base
                            ),
                        ],
                    ),
                ],
            ),
            render.Padding(
                pad = (0, 4, 0, 0),
                child = render.Row(
                    children = [
                        render.Image(
                            src = third,  # third base
                        ),
                        render.Box(
                            width = 1,
                            height = 1,
                        ),
                        render.Image(
                            src = first,  # first base
                        ),
                    ],
                ),
            ),
        ],
    )

def get_sched(team, timezone):
    yesterday = get_now(timezone) - time.parse_duration("86400s")
    future = yesterday + time.parse_duration("518400s")
    query_params = {
        "teamId": team,
        "sportId": "1",
        "startDate": get_date(yesterday),
        "endDate": get_date(future),
        "hydrate": "statusFlags,linescore,person,probablePitcher",  # hydrate stuff so we don't have to hit API again
        "fields": ",".join(SCHED_FIELDS),
    }
    url = MLB_BASE_URL.format(MLB_SCHED_ENDPOINT)

    # cache schedule info for 60 seconds
    return http.get(url, params = query_params, ttl_seconds = 60)

SCHED_FIELDS = (
    "dates",
    "date",
    "games",
    "gamePk",
    "game",
    "link",
    "gameDate",
    "statusFlags",
    "isFinal",
    "isPreview",
    "isWarmup",
    "isCancelled",
    "isClassicDoubleHeader",
    "isDoubleHeader",
    "isPostponed",
    "isDelayed",
    "isPreGameDelay",
    "isInGameDelay",
    "isSuspended",
    "isWinner",
    "linescore",
    "away",
    "home",
    "teams",
    "team",
    "id",
    "probablePitcher",
    "useLastName",
)

LIVE_DATA_FIELDS = (
    "liveData",
    "plays",
    "allPlays",
    "currentPlay",
    "atBatIndex",
    "matchup",
    "postOnFirst",
    "postOnSecond",
    "postOnThird",
    "linescore",
    "isTopInning",
    "currentInning",
    "outs",
    "count",
    "balls",
    "strikes",
    "teams",
    "home",
    "away",
    "runs",
    "hits",
    "count",
    "outs",
    "errors",
    "result",
    "eventType",
    "event",
    "description",
    "runners",
    "details",
    "about",
    "inning",
    "halfInning",
    "isScoringPlay",
    "isComplete",
    "credits",
    "position",
    "code",
    "gameData",
    "players",
    "id",
    "useLastName",
    "batter",
    "pitcher",
    "stats",
    "pitching",
    "numberOfPitches",
    "parentTeamId",
    "battingOrder",
    "team",
    "boxscore",
)

def get_yesterday_date(timezone):
    yesterday = get_now(timezone) - time.parse_duration("86400s")
    return get_date(yesterday)

def get_schema():
    hour_options = []
    for hour in [4, 5, 6, 7, 8, 9, 10, 11]:
        hour_options.append(
            schema.Option(
                display = str(hour),
                value = str(hour),
            ),
        )
    team_options = []
    for team in TEAM_INFO.values():
        team_options.append(
            schema.Option(
                display = team.Name,
                value = str(team.Id),
            ),
        )
    game_time_options = []
    game_time_options.append(
        schema.Option(
            display = "Relative",
            value = "relative",
        ),
    )
    game_time_options.append(
        schema.Option(
            display = "Absolute",
            value = "absolute",
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
                default = DEFAULT_TEAM,  # CHICAGO CUBS
            ),
            schema.Dropdown(
                id = "hour",
                name = "Hour of the Day",
                desc = "The hour of the day to switch from yesterday's result to upcoming game.",
                icon = "clock",
                options = hour_options,
                default = DEFAULT_HOUR_TO_SWITCH,
            ),
            schema.Dropdown(
                id = "game_time",
                name = "Relative or Absolute",
                desc = "Whether to display the upcoming game time in relative or absolute terms.",
                icon = "hourglass",
                options = game_time_options,
                default = DEFAULT_RELATIVE,
            ),
        ],
    )

def get_date(timestamp):
    month = str(timestamp.month)
    day = str(timestamp.day)
    month = "0" + month if len(month) == 1 else month
    day = "0" + day if len(day) == 1 else day
    return str(timestamp.year) + "-" + month + "-" + day

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

# utility functions

def render_W(color):
    return render.Column(
        children = [
            render.Row(
                children = [
                    render_block(6, 2, color),
                    render_blank_block(8, 2),
                    render_block(6, 2, color),
                    render_blank_block(8, 2),
                    render_block(6, 2, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(1, 2),
                    render_block(5, 2, color),
                    render_blank_block(7, 2),
                    render_block(8, 2, color),
                    render_blank_block(7, 2),
                    render_block(5, 2, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(2, 1),
                    render_block(5, 1, color),
                    render_blank_block(6, 1),
                    render_block(8, 1, color),
                    render_blank_block(6, 1),
                    render_block(5, 1, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(2, 2),
                    render_block(5, 2, color),
                    render_blank_block(5, 2),
                    render_block(10, 2, color),
                    render_blank_block(5, 2),
                    render_block(5, 2, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(2, 1),
                    render_block(5, 1, color),
                    render_blank_block(5, 1),
                    render_block(4, 1, color),
                    render_blank_block(2, 1),
                    render_block(4, 1, color),
                    render_blank_block(5, 1),
                    render_block(5, 1, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(3, 2),
                    render_block(5, 2, color),
                    render_blank_block(3, 2),
                    render_block(5, 2, color),
                    render_blank_block(2, 2),
                    render_block(5, 2, color),
                    render_blank_block(3, 2),
                    render_block(5, 2, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(3, 1),
                    render_block(5, 1, color),
                    render_blank_block(3, 1),
                    render_block(4, 1, color),
                    render_blank_block(4, 1),
                    render_block(4, 1, color),
                    render_blank_block(3, 1),
                    render_block(5, 1, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(3, 1),
                    render_block(5, 1, color),
                    render_blank_block(2, 1),
                    render_block(5, 1, color),
                    render_blank_block(4, 1),
                    render_block(5, 1, color),
                    render_blank_block(2, 1),
                    render_block(5, 1, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(4, 2),
                    render_block(5, 2, color),
                    render_blank_block(1, 2),
                    render_block(5, 2, color),
                    render_blank_block(4, 2),
                    render_block(5, 2, color),
                    render_blank_block(1, 2),
                    render_block(5, 2, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(4, 1),
                    render_block(5, 1, color),
                    render_blank_block(1, 1),
                    render_block(4, 1, color),
                    render_blank_block(6, 1),
                    render_block(4, 1, color),
                    render_blank_block(1, 1),
                    render_block(5, 1, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(5, 2),
                    render_block(9, 2, color),
                    render_blank_block(6, 2),
                    render_block(9, 2, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(5, 2),
                    render_block(8, 2, color),
                    render_blank_block(8, 2),
                    render_block(8, 2, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(6, 1),
                    render_block(7, 1, color),
                    render_blank_block(8, 1),
                    render_block(7, 1, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(6, 1),
                    render_block(6, 1, color),
                    render_blank_block(10, 1),
                    render_block(6, 1, color),
                ],
            ),
            render.Row(
                children = [
                    render_blank_block(7, 1),
                    render_block(5, 1, color),
                    render_blank_block(10, 1),
                    render_block(5, 1, color),
                ],
            ),
        ],
    )

def render_blank_block(width, height):
    return render.Box(
        width = width,
        height = height,
    )

def render_block(width, height, color):
    return render.Box(
        width = width,
        height = height,
        color = color,
    )

def render_L(color):
    return render.Row(
        children = [
            render.Box(
                width = 4,
                height = 23,
                color = color,
            ),
            render.Column(
                children = [
                    render.Box(
                        width = 12,
                        height = 19,
                    ),
                    render.Box(
                        width = 12,
                        height = 4,
                        color = color,
                    ),
                ],
            ),
        ],
    )

def get_away_team_id(game):
    return get_team_id(game, "away")

def get_home_team_id(game):
    return get_team_id(game, "home")

def get_team_id(game, team_type):
    return int(game.get("teams").get(team_type).get("team").get("id"))

def get_away_probable_pitcher(game):
    return get_probable_pitcher(game, "away")

def get_home_probable_pitcher(game):
    return get_probable_pitcher(game, "home")

def get_probable_pitcher(game, team_type):
    return game.get("teams").get(team_type).get("probablePitcher")

def render_separator():
    return render.Box(
        height = 5,
        width = 1,
        color = "373737",
    )

def render_current_outs(number_of_outs):
    if number_of_outs == 0 or number_of_outs > 2:
        return render.Row(
            children = render_outs(NO_OUT, NO_OUT),
        )
    if number_of_outs == 1:
        return render.Row(
            children = render_outs(OUT, NO_OUT),
        )
    return render.Row(
        children = render_outs(OUT, OUT),
    )

def render_outs(one_out, two_out):
    return [
        render.Image(
            src = one_out,
        ),
        render.Box(
            width = 1,
            height = 1,
        ),
        render.Image(
            src = two_out,
        ),
    ]

PLAY_OUTCOME_MAP = {
    "catcher_interf": "CI",
    "caught_stealing_2b": "CS",
    "caught_stealing_3b": "CS",
    "caught_stealing_home": "CS",
    "double": "2B",
    "double_play": "DP",
    "fielders_choice": "FC",
    "fielders_choice_out": "FC",
    "field_error": "E",
    "field_out": "OUT",
    "force_out": "FO",
    "game_advisory": "",
    "grounded_into_double_play": "GDP",
    "hit_by_pitch": "HBP",
    "home_run": "HR",
    "intent_walk": "IBB",
    "other_out": "OUT",
    "pickoff_1b": "OUT",
    "pickoff_caught_stealing_2b": "CS",
    "pickoff_caught_stealing_3b": "CS",
    "sac_fly": "SF",
    "sac_bunt": "SAC",
    "single": "1B",
    "stolen_base_2b": "SB",
    "stolen_base_3b": "SB",
    "stolen_base_home": "SB",
    "strikeout": "K",
    "strikeout_double_play": "KDP",
    "triple": "3B",
    "walk": "BB",
}
