"""
Applet: Mens Cricket
Summary: Display cricket scores
Description: For a selected team, this app shows the scorecard for a current match. If no match in progress, it will display scorecard for a recently completed match. If none of these, it will display the next match details in user's local timezone.
Author: adilansari

v 1.0 - Initial version with T20/ODI match support
v 1.1 - Using CricBuzz API for match data and adding Test match support
v 1.2 - Add Big Bash League team support
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# API
TEAM_SCHEDULE_URL = "https://www.cricbuzz.com/cricket-team/{team_name}/{team_id}/schedule"
TEAM_RESULTS_URL = "https://www.cricbuzz.com/cricket-team/{team_name}/{team_id}/results"
MATCH_PAGE_URL = "https://www.cricbuzz.com/live-cricket-scores/{match_id}"

USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36"

# Timings
ONE_HOUR = 3600  # 1 hour
ONE_MINUTE = 60  # 1 minute
DEFAULT_SCREEN = render.Root(
    child = render.WrappedText(
        content = "Match cannot be displayed. Please choose a different team.",
        font = "tom-thumb",
    ),
)

# Config
DEFAULT_TEAM_ID = "2"
DEFAULT_PAST_RESULT_DAYS = 3
ALWAYS_SHOW_FIXTURES_SCHEMA_KEY = "Always"

# Styling
LRG_FONT = "CG-pixel-4x5-mono"
SML_FONT = "CG-pixel-3x5-mono"
BLACK_COLOR = "#222222"
WHITE_COLOR = "#FFFFFF"
CHARCOAL_COLOR = "#36454F"

def render_current_match(match, tz):
    match_data = fetch_live_score(match["matchHeader"]["matchId"])

    # If fetch failed or returned empty data, check if we can use the passed match object
    if not match_data or "matchHeader" not in match_data:
        if "matchHeader" in match:
            match_data = match
        else:
            return render_next_match(match, tz)

    details = match_data.get("matchHeader", {})
    scorecard = match_data.get("miniscore", {})

    if not details:
        return render_next_match(match, tz)

    is_test_match = details["matchFormat"].lower() == "test"
    team_scores = [
        {
            "id": "",
            "abbr": "",
            "score": 0,
            "wickets": 0,
            "overs": 0,
            "player_row_1": None,
            "player_row_2": None,
            "team_settings": None,
        },
        {
            "id": "",
            "abbr": "",
            "score": 0,
            "wickets": 0,
            "overs": 0,
            "team_settings": None,
        },
    ]
    live_inning = scorecard.get("inningsId", 0)
    if live_inning == 0 or "matchScoreDetails" not in scorecard:
        return render_next_match(match_data, tz)
    for ing in scorecard["matchScoreDetails"]["inningsScoreList"]:
        if live_inning == ing["inningsId"]:
            team_scores[0]["id"] = ing["batTeamId"]
            team_scores[0]["abbr"] = ing["batTeamName"]

    if details["matchTeamInfo"][0]["battingTeamId"] == team_scores[0]["id"]:
        team_scores[1]["id"] = details["matchTeamInfo"][0]["bowlingTeamId"]
        team_scores[1]["abbr"] = details["matchTeamInfo"][0]["bowlingTeamShortName"]
    else:
        team_scores[1]["id"] = details["matchTeamInfo"][0]["battingTeamId"]
        team_scores[1]["abbr"] = details["matchTeamInfo"][0]["battingTeamShortName"]

    for ts in team_scores:
        ts["team_settings"] = team_settings_by_id[str(ts["id"])]

    for ing in reversed(scorecard["matchScoreDetails"]["inningsScoreList"]):
        ts = team_scores[0] if ing["batTeamId"] == team_scores[0]["id"] else team_scores[1]
        if is_test_match:
            in_score = str(ing["score"])
            if ing["wickets"] < 10:
                in_score = "{}/{}{}".format(ing["score"], ing["wickets"], "d" if ing["isDeclared"] else "")
            if ts["score"]:
                ts["score"] = "{} & {}".format(ts["score"], in_score)
            else:
                ts["score"] = in_score
        else:
            ts["score"] = ing["score"]
            ts["wickets"] = ing["wickets"]
            ts["overs"] = ing["overs"]

    for k, m in [("batsmanStriker", "player_row_1"), ("batsmanNonStriker", "player_row_2")]:
        if scorecard.get(k, {}):
            name = scorecard[k].get("name", scorecard[k].get("batName", ""))
            runs = scorecard[k].get("runs", scorecard[k].get("batRuns", ""))
            balls = scorecard[k].get("balls", scorecard[k].get("batBalls", ""))
            if not name:
                name = " ".join(scorecard.get("lastWicket", "Wicket Out").split(" ")[:2])
                runs = "out"
            ts = team_scores[0] if scorecard["batTeam"]["teamId"] == team_scores[0]["id"] else team_scores[1]
            ts[m] = render_batsmen_row(name, runs, balls, ts["team_settings"].fg_color)

    row_team_1 = render_team_score_row(team_scores[0]["abbr"], team_scores[0]["score"], team_scores[0]["wickets"], team_scores[0]["overs"], team_scores[0]["team_settings"].fg_color, team_scores[0]["team_settings"].bg_color)
    row_team_2 = render_team_score_row(team_scores[1]["abbr"], team_scores[1]["score"], team_scores[1]["wickets"], team_scores[1]["overs"], team_scores[1]["team_settings"].fg_color, team_scores[1]["team_settings"].bg_color)
    statuses, render_columns = ["", "", "", ""], []
    default_match_status = ""
    if is_test_match:
        day_number, match_state = details.get("dayNumber", 0), details["state"].lower()
        default_match_status = "Day {} {}".format(day_number, match_state)
        overs_rem = _safe_float(scorecard.get("oversRem", 0))
        if overs_rem > 0:
            statuses[2] = "Overs rem - {}".format(humanize.float("#.#", float(overs_rem)))
        else:
            statuses[2] = "{} Innings".format(humanize.ordinal(int(live_inning)))
        need_runs = _safe_float(scorecard.get("remRunsToWin", 0))
        target = _safe_float(scorecard.get("target", 0))
        team_score = _safe_float(scorecard["batTeam"]["teamScore"])
        if need_runs == 0 and target > 0:
            need_runs = target - team_score
        if need_runs > 0:
            statuses[0] = "{} runs to win".format(int(need_runs))
    else:
        recent_balls = scorecard["recentOvsStats"].split(" ")
        last_6_balls = []
        for b in reversed(recent_balls):
            if len(last_6_balls) == 6:
                break
            if b in ["|", "..."]:
                continue
            last_6_balls.append(b)
        default_match_status = "..." + " ".join(reversed(last_6_balls))
        current_run_rate = "Run Rate: {}".format(humanize.float("#.#", float(scorecard["currentRunRate"])))
        statuses[1] = current_run_rate
        if live_inning == 2:
            need_runs = _safe_float(scorecard["remRunsToWin"])
            statuses[0] = "{} runs to win".format(int(need_runs))
            reqd_run_rate = "Reqd Rate: {}".format(humanize.float("#.#", float(scorecard["requiredRunRate"])))
            statuses[2] = reqd_run_rate

    for i in range(len(statuses)):
        if not statuses[i]:
            statuses[i] = default_match_status
        render_columns.append(
            render.Column(
                children = [
                    row_team_1,
                    team_scores[0]["player_row_1"],
                    team_scores[0]["player_row_2"],
                    row_team_2,
                    render_status_row(statuses[i]),
                ],
            ),
        )
    return render.Root(
        delay = int(4000),
        child = render.Animation(
            children = render_columns,
        ),
    )

def render_next_match(match_data, tz):
    details = match_data["matchHeader"]
    match_start_time = time.from_timestamp(details["matchStartTimestamp"] // 1000).in_location(tz)
    match_time_status = match_start_time.format("Jan 2 - 3:04 PM")
    time_to_start = match_start_time - time.now().in_location(tz)
    if time_to_start < time.parse_duration("48h"):
        match_time_status = humanize.time(match_start_time)
    elif time_to_start < time.parse_duration("168h"):
        match_time_status = match_start_time.format("Mon - 3:04 PM")

    team_1_id, team_1_name = str(details["team1"]["id"]), details["team1"]["name"]
    team_2_id, team_2_name = str(details["team2"]["id"]), details["team2"]["name"]

    team_1_settings = team_settings_by_id[team_1_id]
    team_2_settings = team_settings_by_id[team_2_id]

    match_title_status = details["matchDescription"]
    match_venue_status = details["venue"]["city"]
    if len(match_venue_status) < 14:
        country = details["venue"]["country"]
        for tm in team_settings_by_id.values():
            if country.lower() == tm.name.lower():
                country = tm.abbr
                break

        match_venue_status = "{}, {}".format(match_venue_status, country)

    team_1_row = render_team_row(team_1_name, team_1_settings.fg_color, team_1_settings.bg_color)
    vs_row = render.Row(
        main_align = "center",
        expanded = True,
        children = [
            render.Box(height = 9, child = render.Text(content = "vs", color = WHITE_COLOR, font = SML_FONT)),
        ],
    )
    team_2_row = render_team_row(team_2_name, team_2_settings.fg_color, team_2_settings.bg_color)
    match_venue_status_row = render_status_row(match_venue_status)
    match_title_status_row = render_status_row(match_title_status)
    match_state = details["state"].lower()
    match_state_status = match_time_status if match_state in ["preview", "upcoming"] else match_state
    match_state_status_row = render_status_row(match_state_status)
    return render.Root(
        delay = 4000,
        child = render.Animation(
            children = [
                render.Column(
                    children = [
                        team_1_row,
                        vs_row,
                        team_2_row,
                        match_title_status_row,
                    ],
                ),
                render.Column(
                    children = [
                        team_1_row,
                        vs_row,
                        team_2_row,
                        match_state_status_row,
                    ],
                ),
                render.Column(
                    children = [
                        team_1_row,
                        vs_row,
                        team_2_row,
                        match_state_status_row,
                    ],
                ),
                render.Column(
                    children = [
                        team_1_row,
                        vs_row,
                        team_2_row,
                        match_venue_status_row,
                    ],
                ),
            ],
        ),
    )

def render_past_match(match, tz):
    details, scorecard = match["matchHeader"], match["miniscore"]
    is_test_match = details["matchFormat"].lower() == "test"
    match_start = time.from_timestamp(details["matchStartTimestamp"] // 1000).in_location(tz)
    match_dt_status = match_start.format("Jan 2 2006")

    team_scores = [
        {
            "id": details["matchTeamInfo"][0]["battingTeamId"],
            "abbr": details["matchTeamInfo"][0]["battingTeamShortName"],
            "score": 0,
            "wickets": 0,
            "overs": 0,
            "player_row": None,
            "team_settings": None,
        },
        {
            "id": details["matchTeamInfo"][0]["bowlingTeamId"],
            "abbr": details["matchTeamInfo"][0]["bowlingTeamShortName"],
            "score": 0,
            "wickets": 0,
            "overs": 0,
            "player_row": None,
            "team_settings": None,
        },
    ]

    for ts in team_scores:
        ts["team_settings"] = team_settings_by_id[str(ts["id"])]

    for ing in reversed(scorecard["matchScoreDetails"]["inningsScoreList"]):
        ts = team_scores[0] if ing["batTeamId"] == team_scores[0]["id"] else team_scores[1]
        if is_test_match:
            in_score = str(ing["score"])
            if ing["wickets"] < 10:
                in_score = "{}/{}{}".format(ing["score"], ing["wickets"], "d" if ing["isDeclared"] else "")
            if ts["score"]:
                ts["score"] = "{} & {}".format(ts["score"], in_score)
            else:
                ts["score"] = in_score
        else:
            ts["score"] = ing["score"]
            ts["wickets"] = ing["wickets"]
            ts["overs"] = ing["overs"]

    # find last innings batsman and bowler
    if len(scorecard.get("bowlerStriker", {})) > 0:
        name = scorecard["bowlerStriker"].get("name", scorecard["bowlerStriker"].get("bowlName", ""))
        ovs = scorecard["bowlerStriker"].get("overs", scorecard["bowlerStriker"].get("bowlOvs", 0))
        runs = scorecard["bowlerStriker"].get("runs", scorecard["bowlerStriker"].get("bowlRuns", 0))
        wkts = scorecard["bowlerStriker"].get("wickets", scorecard["bowlerStriker"].get("bowlWkts", 0))
        ts = team_scores[0] if scorecard["batTeam"]["teamId"] != team_scores[0]["id"] else team_scores[1]
        ts["player_row"] = render_bowler_row(name, ovs, runs, wkts, ts["team_settings"].fg_color)

    if len(scorecard.get("batsmanStriker", {})) > 0:
        name = scorecard["batsmanStriker"].get("name", scorecard["batsmanStriker"].get("batName", ""))
        runs = scorecard["batsmanStriker"].get("runs", scorecard["batsmanStriker"].get("batRuns", 0))
        balls = scorecard["batsmanStriker"].get("balls", scorecard["batsmanStriker"].get("batBalls", 0))
        ts = team_scores[0] if scorecard["batTeam"]["teamId"] == team_scores[0]["id"] else team_scores[1]
        ts["player_row"] = render_batsmen_row(name, runs, balls, ts["team_settings"].fg_color)

    match_result_status = details["status"]
    if "result" in details:
        result = details["result"]
        if result["resultType"] == "tie":
            match_result_status = "Match tied"
        elif result["resultType"] == "noresult":
            match_result_status = "Match abandoned"
        elif result["resultType"] == "draw":
            match_result_status = "Match draw"
        else:
            win_type = " runs" if result["winByRuns"] else " wkts"
            inn_win = "in & " if result["winByInnings"] else ""
            win_by = "by " + inn_win + str(result["winningMargin"]) + win_type
            win_team_abbr = team_scores[0]["abbr"] if result["winningteamId"] == team_scores[0]["id"] else team_scores[1]["abbr"]
            match_result_status = win_team_abbr + " " + win_by

    team_1_score_row = render_team_score_row(team_scores[0]["abbr"], team_scores[0]["score"], team_scores[0]["wickets"], team_scores[0]["overs"], team_scores[0]["team_settings"].fg_color, team_scores[0]["team_settings"].bg_color)
    team_1_player_row = team_scores[0]["player_row"]
    team_2_score_row = render_team_score_row(team_scores[1]["abbr"], team_scores[1]["score"], team_scores[1]["wickets"], team_scores[1]["overs"], team_scores[1]["team_settings"].fg_color, team_scores[1]["team_settings"].bg_color)
    team_2_player_row = team_scores[1]["player_row"]
    match_result_status_row = render_status_row(match_result_status)
    match_dt_status_row = render_status_row(match_dt_status)

    columns = []
    for i in range(4):
        stat_row = match_dt_status_row if i == 3 else match_result_status_row
        columns.append(
            render.Column(
                children = [
                    team_1_score_row,
                    team_1_player_row,
                    team_2_score_row,
                    team_2_player_row,
                    stat_row,
                ],
            ),
        )
    return render.Root(
        delay = int(4000),
        child = render.Animation(
            children = columns,
        ),
    )

def render_team_score_row(abbr, score, wickets, overs, fg_color, bg_color):
    wkt_display, over_display = "", ""
    if overs:
        over_display = " {}".format(rounded_overs(overs))
    if overs and wickets != 10:
        wkt_display = "/{}".format(wickets)

    if not score and not wickets:
        score_display = "-"
    else:
        score_display = "{}{}{}".format(score, wkt_display, over_display)

    split_score = score_display.split(" ")
    score_columns = [
        render.Text(content = split_score[0], color = fg_color, font = SML_FONT),
    ]
    for s in split_score[1:]:
        txt = render.Text(content = s, color = fg_color, font = SML_FONT)
        txt = render.Padding(pad = (2, 0, 0, 0), child = txt)
        score_columns.append(txt)

    rendered_display = render.Box(
        height = 7,
        color = bg_color,
        child = render.Padding(
            pad = (1, 0, 0, 0),
            child = render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Row(
                        children = [render.Text(content = abbr, color = fg_color, font = LRG_FONT)],
                    ),
                    render.Row(
                        children = score_columns,
                    ),
                ],
            ),
        ),
    )

    return rendered_display

def render_batsmen_row(name, runs, balls, fg_color = WHITE_COLOR, bg_color = ""):
    left_text = reduce_player_name(name)
    balls_text = "({})".format(balls) if balls else ""
    right_text = "{}{}".format(runs, balls_text)
    return render_player_row(left_text, right_text, fg_color, bg_color)

def render_bowler_row(name, overs, runs, wickets, fg_color = WHITE_COLOR, bg_color = ""):
    left_text = reduce_player_name(name)

    # remove decimal from overs
    overs = rounded_overs(overs)
    overs = str(int(overs)) if overs > 10 else str(overs)
    right_text = "{}-{}-{}".format(overs, runs, wickets)
    return render_player_row(left_text, right_text, fg_color, bg_color)

def render_player_row(left_text, right_text, fg_color, bg_color):
    return render.Box(
        height = 6,
        color = bg_color,
        child = render.Padding(
            pad = (1, 0, 0, 0),
            child = render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Column(
                        cross_align = "start",
                        children = [render.Text(content = left_text, color = fg_color, font = "tom-thumb")],
                    ),
                    render.Column(
                        cross_align = "end",
                        children = [render.Text(content = right_text, color = fg_color, font = SML_FONT)],
                    ),
                ],
            ),
        ),
    )

def render_team_row(name, fg_color, bg_color):
    name = name.upper()
    return render.Box(
        height = 8,
        color = bg_color,
        child = render.Row(
            expanded = True,
            main_align = "center",
            children = [
                render.Text(content = name, color = fg_color, font = "tb-8"),
            ],
        ),
    )

def render_status_row(text, fg_color = WHITE_COLOR, bg_color = BLACK_COLOR):
    text_split = text.split(" ")
    content_columns = []
    for s in text_split:
        content_columns.append(
            render.Padding(
                pad = (1, 0, 1, 0),
                child = render.Text(content = s, color = fg_color, font = SML_FONT),
            ),
        )

    return render.Padding(
        pad = (0, 1, 0, 0),
        child = render.Box(
            height = 5,
            color = bg_color,
            child = render.Row(
                main_align = "center",
                expanded = True,
                children = content_columns,
            ),
        ),
    )

def reduce_player_name(name):
    first, last = name.split(" ")[0], name.split(" ")[-1]
    display = first[0] + "." + last
    if len(display) <= 7:
        return display
    else:
        return last[:7]

def rounded_overs(overs):
    if overs % 1 > 0.5:
        return int(overs) + 1
    elif overs % 1 == 0:
        return int(overs)
    return overs

def _team_setting(id, name, abbr, fg_color, bg_color):
    return {
        "id": str(id),
        "name": name,
        "abbr": abbr,
        "fg_color": fg_color,
        "bg_color": bg_color,
    }

team_settings_by_id = {
    ts.id: ts
    for ts in [
        struct(**_team_setting("96", "Afghanistan", "AFG", "#D32011", BLACK_COLOR)),
        struct(**_team_setting("4", "Australia", "AUS", "#FFCE00", "#006A4A")),
        struct(**_team_setting("6", "Bangladesh", "BAN", "#F42A41", "#006A4E")),
        struct(**_team_setting("9", "England", "ENG", "#FFFFFF", "#CE1124")),
        struct(**_team_setting("2", "India", "IND", "#FFAC1C", "#050CEB")),
        struct(**_team_setting("27", "Ireland", "IRE", "#169B62", "#FF883E")),
        struct(**_team_setting("24", "Netherlands", "NED", "#FFFFFF", "#FF4F00")),
        struct(**_team_setting("13", "New Zealand", "NZ", "#FFFFFF", "#008080")),
        struct(**_team_setting("3", "Pakistan", "PAK", "#FFFFFF", "#115740")),
        struct(**_team_setting("23", "Scotland", "SCO", "#FFFFFF", "#005EB8")),
        struct(**_team_setting("11", "South Africa", "SA", "#FFB81C", "#007749")),
        struct(**_team_setting("5", "Sri Lanka", "SL", "#EB7400", "#0A2351")),
        struct(**_team_setting("15", "United States", "USA", "#B31942", "#003087")),
        struct(**_team_setting("10", "West Indies", "WI", "#f2b10e", "#660000")),
        struct(**_team_setting("12", "Zimbabwe", "ZIM", "#FCE300", "#EF3340")),
        struct(**_team_setting("63", "Kolkata Knight Riders", "KKR", "#F7D54E", "#3A225D")),
        struct(**_team_setting("65", "Punjab Kings", "PK", "#D3D3D3", "#DD1F2D")),
        struct(**_team_setting("62", "Mumbai Indians", "MI", "#E9530D", "#004B8D")),
        struct(**_team_setting("966", "Lucknow Giants", "LSG", "#F28B00", "#0057E2")),
        struct(**_team_setting("971", "Gujarat Titans", "GT", "#DBBE6E", "#002244")),
        struct(**_team_setting("255", "Sunrisers Hyderabad", "SRH", "#FCCB11", "#B02528")),
        struct(**_team_setting("61", "Delhi Capitals", "DC", "#D71921", "#282968")),
        struct(**_team_setting("59", "Royal Challengers Bangalore", "RCB", "#D1AB3E", "#EC1C24")),
        struct(**_team_setting("58", "Chennai Super Kings", "CSK", "#FFFF3C", "#2B5DA8")),
        struct(**_team_setting("64", "Rajasthan Royals", "RR", "#C3A11F", "#074EA2")),

        # Big Bash League Teams
        struct(**_team_setting("199", "Adelaide Strikers", "ADS", "#FFFFFF", "#0084D6")),
        struct(**_team_setting("193", "Brisbane Heat", "BRH", "#FFFFFF", "#27A6B0")),
        struct(**_team_setting("194", "Hobart Hurricanes", "HBH", "#FFFFFF", "#674398")),
        struct(**_team_setting("195", "Melbourne Renegades", "MLR", "#FFFFFF", "#EE343F")),
        struct(**_team_setting("196", "Melbourne Stars", "MLS", "#FFFFFF", "#287246")),
        struct(**_team_setting("197", "Perth Scorchers", "PRS", "#FFFFFF", "#CC5A1E")),
        struct(**_team_setting("198", "Sydney Sixers", "SYS", "#FFFFFF", "#EC2A90")),
        struct(**_team_setting("192", "Sydney Thunder", "SYT", "#FFFFFF", "#7CB002")),
    ]
}

team_list_schema_options = [schema.Option(display = ts.name, value = ts.id) for ts in team_settings_by_id.values()]
past_results_day_options = [
    schema.Option(
        display = "1",
        value = "1",
    ),
    schema.Option(
        display = "2",
        value = "2",
    ),
    schema.Option(
        display = "3",
        value = "3",
    ),
    schema.Option(
        display = "5",
        value = "5",
    ),
    schema.Option(
        display = "7",
        value = "7",
    ),
    schema.Option(
        display = "30",
        value = "30",
    ),
    schema.Option(
        display = "90",
        value = "90",
    ),
]
upcoming_fixtures_day_options = [
    schema.Option(
        display = "1",
        value = "1",
    ),
    schema.Option(
        display = "2",
        value = "2",
    ),
    schema.Option(
        display = "3",
        value = "3",
    ),
    schema.Option(
        display = "5",
        value = "5",
    ),
    schema.Option(
        display = "7",
        value = "7",
    ),
    schema.Option(
        display = ALWAYS_SHOW_FIXTURES_SCHEMA_KEY,
        value = ALWAYS_SHOW_FIXTURES_SCHEMA_KEY,
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "team",
                name = "Team",
                desc = "Choose your team",
                icon = "tag",
                default = team_list_schema_options[1].value,
                options = team_list_schema_options,
            ),
            schema.Dropdown(
                id = "days_back",
                name = "# of days back to show scores",
                desc = "Number of days back to search for scores",
                icon = "arrowLeft",
                default = "1",
                options = past_results_day_options,
            ),
            schema.Dropdown(
                id = "days_forward",
                name = "# of days forward to show fixtures",
                desc = "Number of days forward to search for fixtures",
                icon = "arrowRight",
                default = ALWAYS_SHOW_FIXTURES_SCHEMA_KEY,
                options = upcoming_fixtures_day_options,
            ),
        ],
    )

def get_cached_past_matches(team_id, team_name):
    team_name = team_name.lower().replace(" ", "-")
    return _get_cached_matches(TEAM_RESULTS_URL.format(team_name = team_name, team_id = team_id))

def get_cached_scheduled_matches(team_id, team_name):
    team_name = team_name.lower().replace(" ", "-")
    return _get_cached_matches(TEAM_SCHEDULE_URL.format(team_name = team_name, team_id = team_id))

def _get_cached_matches(url):
    cached_data = cache.get(url)
    if cached_data:
        print("---HIT for {}".format(url))
        return json.decode(cached_data)
    print("--MISS for {}".format(url))
    res = fetch_url(url)

    matches = []

    if "teamMatchesData" in res:
        # We process the JSON text manually to extract match objects
        # Strategy: find "matchInfo" keys, then parse the object
        # Also look for "matchScore"

        # Check if the keys are escaped
        mi_marker = '"matchInfo":'
        if '\\"matchInfo\\":' in res:
            mi_marker = '\\"matchInfo\\":'

        search_idx = res.find("teamMatchesData")
        if search_idx == -1:
            search_idx = 0

        for _ in range(50):  # Safety limit to avoid infinite loops
            mi_start = res.find(mi_marker, search_idx)
            if mi_start == -1:
                break

            mi_obj_str = _extract_json_object(res, mi_start + len(mi_marker), mi_marker.startswith("\\"))
            if not mi_obj_str:
                search_idx = mi_start + len(mi_marker)
                continue

            # Handle potential escaping for json.decode
            if mi_marker.startswith("\\"):
                # It's escaped, try to unescape
                unescaped = mi_obj_str.replace('\\"', '"').replace("\\\\", "\\")
                mi_data = json.decode(unescaped)
            else:
                mi_data = json.decode(mi_obj_str)

            if not mi_data:
                search_idx = mi_start + len(mi_marker) + len(mi_obj_str)
                continue

            # Map matchInfo to matchHeader format
            match_header = {
                "matchId": str(mi_data.get("matchId", "")),
                "matchDescription": mi_data.get("matchDesc", ""),
                "matchFormat": mi_data.get("matchFormat", ""),
                "matchType": mi_data.get("matchType", ""),
                "matchStartTimestamp": int(mi_data.get("startDate", 0)),
                "matchCompleteTimestamp": int(mi_data.get("endDate", mi_data.get("startDate", 0))),
                "state": mi_data.get("state", ""),
                "status": mi_data.get("status", ""),
                "team1": {
                    "id": str(mi_data.get("team1", {}).get("teamId", "")),
                    "name": mi_data.get("team1", {}).get("teamName", ""),
                },
                "team2": {
                    "id": str(mi_data.get("team2", {}).get("teamId", "")),
                    "name": mi_data.get("team2", {}).get("teamName", ""),
                },
                "venue": {
                    "city": mi_data.get("venueInfo", {}).get("city", ""),
                    "country": "",
                    "name": mi_data.get("venueInfo", {}).get("ground", ""),
                },
            }

            # Look for matchScore
            miniscore = {}
            ms_marker = '"matchScore":'
            if mi_marker.startswith("\\"):
                ms_marker = '\\"matchScore\\":'

            mi_end_idx = mi_start + len(mi_marker) + len(mi_obj_str)
            next_chunk = res[mi_end_idx:mi_end_idx + 1000]
            ms_local_idx = next_chunk.find(ms_marker)

            if ms_local_idx != -1:
                ms_start = mi_end_idx + ms_local_idx
                ms_obj_str = _extract_json_object(res, ms_start + len(ms_marker), ms_marker.startswith("\\"))
                if ms_obj_str:
                    if ms_marker.startswith("\\"):
                        unescaped_ms = ms_obj_str.replace('\\"', '"').replace("\\\\", "\\")
                        miniscore = json.decode(unescaped_ms)
                    else:
                        miniscore = json.decode(ms_obj_str)

            # Simple miniscore mapping for inningsId
            if "team1Score" in miniscore and "inngs1" in miniscore["team1Score"]:
                if "inningsId" not in miniscore:
                    miniscore["inningsId"] = miniscore["team1Score"]["inngs1"].get("inningsId", 0)

            matches.append({
                "matchHeader": match_header,
                "miniscore": miniscore,
            })

            search_idx = mi_start + len(mi_marker) + len(mi_obj_str)

    if matches:
        print("Extracted {} matches from schedule/results".format(len(matches)))
        cache.set(url, json.encode(matches), ONE_HOUR)
        return matches

    return []

def fetch_match_comm(match_id):
    url = MATCH_PAGE_URL.format(match_id = match_id)
    cached_data = cache.get(url)
    if cached_data:
        print("---HIT for {}".format(url))
        return json.decode(cached_data)

    print("--MISS for {}".format(url))
    html = fetch_url(url)
    match_data = _scrape_match_data(html)

    if not match_data or "matchHeader" not in match_data:
        print("NULL match details for {}".format(url))
        return {}

    cache_ttl = 5 * ONE_MINUTE
    match_state = match_data.get("matchHeader", {}).get("state", "Preview").lower()
    if match_state in ["complete", "abandon", "upcoming"]:
        # completed/way in future matches can be cached for longer as they are less likely to change now
        cache_ttl = 4 * ONE_HOUR
    if match_state in ["preview"]:
        # matches about to start within next 1 day
        cache_ttl = ONE_HOUR

    cache.set(url, json.encode(match_data), cache_ttl)
    return match_data

def fetch_live_score(match_id):
    url = MATCH_PAGE_URL.format(match_id = match_id)
    cached_data = cache.get(url)
    if cached_data:
        decoded = json.decode(cached_data)
        if decoded and "matchHeader" in decoded:
            print("---HIT for {}".format(url))
            return decoded

    print("--MISS for {}".format(url))
    html = fetch_url(url)
    match_data = _scrape_match_data(html)

    if match_data and "matchHeader" in match_data:
        cache.set(url, json.encode(match_data), ONE_MINUTE)

    return match_data

def fetch_url(url):
    res = http.get(url = url, headers = {"User-Agent": USER_AGENT})

    if res.status_code == 204:
        cache.set(url, json.encode({}), 5 * ONE_MINUTE)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

def _scrape_match_data(html):
    data = {}

    # Detect escaped mode
    escaped = False
    mh_marker = '"matchHeader":'
    ms_marker = '"miniscore":'
    v_marker = '"venue":'

    if '\\"matchHeader\\":' in html:
        escaped = True
        mh_marker = '\\"matchHeader\\":'
        ms_marker = '\\"miniscore\\":'
        v_marker = '\\"venue\\":'

    # matchHeader
    mh_start = html.find(mh_marker)
    if mh_start != -1:
        mh_obj_str = _extract_json_object(html, mh_start + len(mh_marker), escaped)
        if mh_obj_str:
            if escaped:
                unescaped = mh_obj_str.replace('\\"', '"').replace("\\\\", "\\")
                data["matchHeader"] = json.decode(unescaped)
            else:
                data["matchHeader"] = json.decode(mh_obj_str)

    # miniscore
    ms_start = html.find(ms_marker)
    if ms_start != -1:
        ms_obj_str = _extract_json_object(html, ms_start + len(ms_marker), escaped)
        if ms_obj_str:
            if escaped:
                unescaped = ms_obj_str.replace('\\"', '"').replace("\\\\", "\\")
                data["miniscore"] = json.decode(unescaped)
            else:
                data["miniscore"] = json.decode(ms_obj_str)

    # venue (inject into matchHeader if found and not present)
    if "matchHeader" in data and "venue" not in data["matchHeader"]:
        v_start = html.find(v_marker, mh_start)  # Search after matchHeader
        if v_start != -1:
            v_obj_str = _extract_json_object(html, v_start + len(v_marker), escaped)
            if v_obj_str:
                if escaped:
                    unescaped = v_obj_str.replace('\\"', '"').replace("\\\\", "\\")
                    data["matchHeader"]["venue"] = json.decode(unescaped)
                else:
                    data["matchHeader"]["venue"] = json.decode(v_obj_str)

    return data

def _extract_json_object(text, start_index, escaped = False):
    # Skip whitespace
    i = start_index
    for _ in range(len(text) - start_index):
        if i >= len(text):
            return None
        if text[i] not in [" ", "\t", "\n", "\r"]:
            break
        i += 1

    if text[i] != "{":
        return None

    balance = 0
    in_string = False

    # For escaped mode logic
    backslashes = 0

    start_capture = i

    for j in range(i, len(text)):
        char = text[j]

        if char == "\\":
            backslashes += 1
            continue

        if char == '"':
            # Determine if this is a string delimiter or a literal quote
            is_delimiter = False

            if escaped:
                # In escaped mode:
                # \" (odd backslashes) is delimiter
                if backslashes % 2 != 0:
                    effective_slashes = (backslashes + 1) // 2
                    if effective_slashes % 2 != 0:
                        is_delimiter = True
            else:
                # Standard mode
                # Even backslashes (0, 2...) -> Delimiter
                if backslashes % 2 == 0:
                    is_delimiter = True

            if is_delimiter:
                in_string = not in_string

        backslashes = 0

        if not in_string:
            if char == "{":
                balance += 1
            elif char == "}":
                balance -= 1
                if balance == 0:
                    return text[start_capture:j + 1]

    return None

def _safe_float(val):
    if type(val) == "string":
        if val == "$undefined":
            return 0.0
        return float(val)

    return float(val) if val else 0.0

def main(config):
    tz = time.tz()
    team_id = config.get("team", DEFAULT_TEAM_ID)
    fixture_days = config.get("days_forward", ALWAYS_SHOW_FIXTURES_SCHEMA_KEY)
    result_days = int(config.get("days_back", DEFAULT_PAST_RESULT_DAYS))
    now = time.now().in_location(tz)
    team_settings = team_settings_by_id[team_id]
    if not team_settings:
        return DEFAULT_SCREEN

    # These now return lists of match objects (dictionaries), not just IDs
    result_matches = get_cached_past_matches(team_settings.id, team_settings.name)
    scheduled_matches = get_cached_scheduled_matches(team_settings.id, team_settings.name)

    current_match, past_match, next_match = None, None, None

    # Process past matches
    for match_data in result_matches:
        if type(match_data) == "string":
            # Old cache format (ID only)
            full_match_data = fetch_match_comm(match_data)
            if full_match_data and "matchHeader" in full_match_data:
                # Check teams for legacy flow
                if str(full_match_data["matchHeader"]["team1"]["id"]) not in team_settings_by_id:
                    continue
                if str(full_match_data["matchHeader"]["team2"]["id"]) not in team_settings_by_id:
                    continue
                past_match = full_match_data
                break
            continue

        m_team1_id = str(match_data["matchHeader"]["team1"]["id"])
        m_team2_id = str(match_data["matchHeader"]["team2"]["id"])

        if m_team1_id not in team_settings_by_id or m_team2_id not in team_settings_by_id:
            continue

        if team_id not in [m_team1_id, m_team2_id]:
            continue

        # Try to fetch full details for the *selected* match to get scorecard
        full_match_data = fetch_match_comm(match_data["matchHeader"]["matchId"])
        if full_match_data and "matchHeader" in full_match_data:
            past_match = full_match_data
            break

    # Process scheduled matches
    for match_data in scheduled_matches:
        if type(match_data) == "string":
            # Old cache format (ID only) - for schedule, fetch might fail if it's future
            # But we can try. If it fails, we skip.
            # Actually, if it's future, fetch_match_comm uses scraping now, so it might work
            # IF the individual match page exists and has data.
            # But we know it often doesn't for far future matches.
            # So this might fail to show anything until cache clears.
            # But it's better than crashing.
            full_match_data = fetch_match_comm(match_data)
            if full_match_data and "matchHeader" in full_match_data:
                if str(full_match_data["matchHeader"]["team1"]["id"]) not in team_settings_by_id:
                    continue
                if str(full_match_data["matchHeader"]["team2"]["id"]) not in team_settings_by_id:
                    continue
                if team_id not in [str(full_match_data["matchHeader"]["team1"]["id"]), str(full_match_data["matchHeader"]["team2"]["id"])]:
                    continue
                next_match = full_match_data
                break
            continue

        m_team1_id = str(match_data["matchHeader"]["team1"]["id"])
        m_team2_id = str(match_data["matchHeader"]["team2"]["id"])

        if m_team1_id not in team_settings_by_id or m_team2_id not in team_settings_by_id:
            continue

        if team_id not in [m_team1_id, m_team2_id]:
            continue

        next_match = match_data
        break

    if next_match:
        # Check if it's actually live
        state = next_match["matchHeader"]["state"].lower()
        if state in ["in progress", "live"] or next_match.get("miniscore", {}).get("inningsId", 0) > 0:
            # It's live! Try to fetch live details
            live_data = fetch_live_score(next_match["matchHeader"]["matchId"])
            if live_data and "matchHeader" in live_data:
                current_match = live_data
            else:
                current_match = next_match  # Fallback to schedule data

    match_to_render, render_fn = None, None
    if current_match:
        match_to_render, render_fn = current_match, render_current_match
    if past_match and not match_to_render:
        complete_ts = past_match["matchHeader"].get("matchCompleteTimestamp")
        if not complete_ts:
            complete_ts = past_match["matchHeader"].get("matchStartTimestamp", 0)

        match_time = time.from_timestamp(complete_ts // 1000).in_location(tz)
        result_days_duration = time.parse_duration("{}h".format(result_days * 24))
        if now <= match_time + result_days_duration:
            match_to_render, render_fn = past_match, render_past_match
    if next_match and not match_to_render:
        if fixture_days == ALWAYS_SHOW_FIXTURES_SCHEMA_KEY:
            match_to_render, render_fn = next_match, render_next_match
        else:
            match_time = time.from_timestamp(next_match["matchHeader"]["matchStartTimestamp"] // 1000).in_location(tz)
            fixture_days_duration = time.parse_duration("{}h".format(int(fixture_days) * 24))
            if now > match_time - fixture_days_duration:
                match_to_render, render_fn = next_match, render_next_match

    if not match_to_render:
        return []
    return render_fn(match_to_render, tz)
