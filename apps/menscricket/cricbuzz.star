load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")

TEAM_SCHEDULE_URL = "https://www.cricbuzz.com/cricket-team/{team_name}/{team_id}/schedule"
TEAM_RESULTS_URL = "https://www.cricbuzz.com/cricket-team/{team_name}/{team_id}/results"
MATCH_PAGE_URL = "https://www.cricbuzz.com/live-cricket-scores/{match_id}"

USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36"

ONE_HOUR = 3600
ONE_MINUTE = 60

def _get_cached_past_matches(team_id, team_name):
    team_name = team_name.lower().replace(" ", "-")
    return _get_cached_matches(TEAM_RESULTS_URL.format(team_name = team_name, team_id = team_id))

def _get_cached_scheduled_matches(team_id, team_name):
    team_name = team_name.lower().replace(" ", "-")
    return _get_cached_matches(TEAM_SCHEDULE_URL.format(team_name = team_name, team_id = team_id))

def _get_cached_matches(url):
    cached_data = cache.get(url)
    if cached_data:
        print("---HIT for {}".format(url))
        return json.decode(cached_data)
    print("--MISS for {}".format(url))
    res = _fetch_url(url)

    matches = []

    if "teamMatchesData" in res:
        mi_marker = '"matchInfo":'
        if '\\"matchInfo\\":' in res:
            mi_marker = '\\"matchInfo\\":'

        search_idx = res.find("teamMatchesData")
        if search_idx == -1:
            search_idx = 0

        for _ in range(50):
            mi_start = res.find(mi_marker, search_idx)
            if mi_start == -1:
                break

            mi_obj_str = _extract_json_object(res, mi_start + len(mi_marker), mi_marker.startswith("\\"))
            if not mi_obj_str:
                search_idx = mi_start + len(mi_marker)
                continue

            if mi_marker.startswith("\\"):
                unescaped = mi_obj_str.replace('\\"', '"').replace("\\\\", "\\")
                mi_data = json.decode(unescaped)
            else:
                mi_data = json.decode(mi_obj_str)

            if not mi_data:
                search_idx = mi_start + len(mi_marker) + len(mi_obj_str)
                continue

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

            if "team1Score" in miniscore and "inngs1" in miniscore["team1Score"]:
                if "inningsId" not in miniscore:
                    miniscore["inningsId"] = miniscore["team1Score"]["inngs1"].get("inningsId", 0)

            matches.append({
                "matchHeader": match_header,
                "matchInfo": mi_data,
                "miniscore": miniscore,
            })

            search_idx = mi_start + len(mi_marker) + len(mi_obj_str)

    if matches:
        print("Extracted {} matches from schedule/results".format(len(matches)))
        cache.set(url, json.encode(matches), ONE_HOUR)
        return matches

    return []

def _fetch_match_detail(match_id, live = False):
    url = MATCH_PAGE_URL.format(match_id = match_id)
    cached_data = cache.get(url)
    if cached_data:
        print("---HIT for {}".format(url))
        return json.decode(cached_data)

    print("--MISS for {}".format(url))
    html = _fetch_url(url)
    match_data = _scrape_match_data(html)

    if not match_data or "matchHeader" not in match_data:
        print("NULL match details for {}".format(url))
        return {}

    cache_ttl = ONE_MINUTE if live else 5 * ONE_MINUTE
    match_state = match_data.get("matchHeader", {}).get("state", "Preview").lower()
    if not live and match_state in ["complete", "abandon", "upcoming"]:
        cache_ttl = 4 * ONE_HOUR
    if not live and match_state in ["preview"]:
        cache_ttl = ONE_HOUR

    cache.set(url, json.encode(match_data), cache_ttl)
    return match_data

def _fetch_url(url):
    res = http.get(url = url, headers = {"User-Agent": USER_AGENT})

    if res.status_code == 204:
        cache.set(url, json.encode({}), 5 * ONE_MINUTE)
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

def _scrape_match_data(html):
    data = {}

    escaped = False
    mh_marker = '"matchHeader":'
    mi_marker = '"matchInfo":'
    ms_marker = '"miniscore":'
    v_marker = '"venue":'

    if '\\"matchHeader\\":' in html:
        escaped = True
        mh_marker = '\\"matchHeader\\":'
        mi_marker = '\\"matchInfo\\":'
        ms_marker = '\\"miniscore\\":'
        v_marker = '\\"venue\\":'

    mh_start = html.find(mh_marker)
    if mh_start != -1:
        mh_obj_str = _extract_json_object(html, mh_start + len(mh_marker), escaped)
        if mh_obj_str:
            if escaped:
                unescaped = mh_obj_str.replace('\\"', '"').replace("\\\\", "\\")
                data["matchHeader"] = json.decode(unescaped)
            else:
                data["matchHeader"] = json.decode(mh_obj_str)

    mi_start = html.find(mi_marker)
    if mi_start != -1:
        mi_obj_str = _extract_json_object(html, mi_start + len(mi_marker), escaped)
        if mi_obj_str:
            if escaped:
                unescaped = mi_obj_str.replace('\\"', '"').replace("\\\\", "\\")
                data["matchInfo"] = json.decode(unescaped)
            else:
                data["matchInfo"] = json.decode(mi_obj_str)

    ms_start = html.find(ms_marker)
    if ms_start != -1:
        ms_obj_str = _extract_json_object(html, ms_start + len(ms_marker), escaped)
        if ms_obj_str:
            if escaped:
                unescaped = ms_obj_str.replace('\\"', '"').replace("\\\\", "\\")
                data["miniscore"] = json.decode(unescaped)
            else:
                data["miniscore"] = json.decode(ms_obj_str)

    if "matchHeader" in data and "venue" not in data["matchHeader"]:
        v_start = html.find(v_marker, mh_start)
        if v_start != -1:
            v_obj_str = _extract_json_object(html, v_start + len(v_marker), escaped)
            if v_obj_str:
                if escaped:
                    unescaped = v_obj_str.replace('\\"', '"').replace("\\\\", "\\")
                    data["matchHeader"]["venue"] = json.decode(unescaped)
                else:
                    data["matchHeader"]["venue"] = json.decode(v_obj_str)

    return data

def load_display_match(team_id, team_name, supported_team_ids, now_ms, result_days, fixture_days):
    result_matches = _get_cached_past_matches(team_id, team_name)
    scheduled_matches = _get_cached_scheduled_matches(team_id, team_name)

    past_match = _first_supported_detail(result_matches, team_id, supported_team_ids)
    next_match = _first_supported_match(scheduled_matches, team_id, supported_team_ids)

    if next_match:
        state = next_match["matchHeader"].get("state", "").lower()
        innings_id = next_match.get("miniscore", {}).get("inningsId", 0)
        if state in ["in progress", "live"] or innings_id > 0:
            live_match = _fetch_match_detail(next_match["matchHeader"]["matchId"], live = True)
            if live_match and "matchHeader" in live_match:
                return _normalize_match("live", live_match)

    if past_match:
        header = past_match["matchHeader"]
        complete_ms = header.get("matchCompleteTimestamp", header.get("matchStartTimestamp", 0))
        if now_ms <= complete_ms + result_days * 24 * 60 * 60 * 1000:
            return _normalize_match("past", past_match)

    if next_match:
        start_ms = next_match["matchHeader"].get("matchStartTimestamp", 0)
        if fixture_days == None or now_ms > start_ms - fixture_days * 24 * 60 * 60 * 1000:
            return _normalize_match("upcoming", next_match)

    return None

def _first_supported_detail(matches, team_id, supported_team_ids):
    for match in matches:
        detail = _fetch_match_detail(match) if type(match) == "string" else None
        if detail == None and _is_supported_match(match, team_id, supported_team_ids):
            detail = _fetch_match_detail(match["matchHeader"]["matchId"])
        if detail and _is_supported_match(detail, team_id, supported_team_ids):
            return detail
    return None

def _first_supported_match(matches, team_id, supported_team_ids):
    for match in matches:
        candidate = _fetch_match_detail(match) if type(match) == "string" else match
        if candidate and _is_supported_match(candidate, team_id, supported_team_ids):
            return candidate
    return None

def _is_supported_match(match, team_id, supported_team_ids):
    header = match.get("matchHeader", {})
    team_1_id = str(header.get("team1", {}).get("id", ""))
    team_2_id = str(header.get("team2", {}).get("id", ""))
    return team_1_id in supported_team_ids and team_2_id in supported_team_ids and team_id in [team_1_id, team_2_id]

def _normalize_match(kind, raw):
    header = raw.get("matchHeader", {})
    match_info = raw.get("matchInfo", {})
    scorecard = raw.get("miniscore", {})
    teams = _normalize_teams(header, scorecard, kind)
    result = header.get("result", {})

    return struct(
        kind = kind,
        match_id = str(header.get("matchId", "")),
        format = header.get("matchFormat", "").lower(),
        state = header.get("state", "").lower(),
        status = _preferred_status(scorecard, header, match_info),
        day_number = _positive_day_number(match_info, header, scorecard),
        start_ms = header.get("matchStartTimestamp", 0),
        complete_ms = header.get("matchCompleteTimestamp", 0),
        description = header.get("matchDescription", ""),
        venue = struct(
            city = header.get("venue", {}).get("city", ""),
            country = header.get("venue", {}).get("country", ""),
        ),
        teams = teams,
        innings_id = scorecard.get("inningsId", 0),
        batting_team_id = str(scorecard.get("batTeam", {}).get("teamId", "")),
        recent_overs = scorecard.get("recentOvsStats", ""),
        current_rate = scorecard.get("currentRunRate", 0),
        required_rate = scorecard.get("requiredRunRate", 0),
        remaining_runs = scorecard.get("remRunsToWin", 0),
        target = scorecard.get("target", 0),
        batting_score = scorecard.get("batTeam", {}).get("teamScore", 0),
        remaining_overs = scorecard.get("oversRem", 0),
        result = struct(
            type = result.get("resultType", ""),
            winning_team_id = str(result.get("winningteamId", "")),
            margin = result.get("winningMargin", 0),
            by_runs = result.get("winByRuns", False),
            by_innings = result.get("winByInnings", False),
        ),
        result_status = header.get("status", ""),
    )

def _normalize_teams(header, scorecard, kind):
    team_1 = header.get("team1", {})
    team_2 = header.get("team2", {})
    order = [str(team_1.get("id", "")), str(team_2.get("id", ""))]
    names = {
        order[0]: team_1.get("name", ""),
        order[1]: team_2.get("name", ""),
    }
    abbreviations = {}

    team_info = header.get("matchTeamInfo", [])
    if team_info:
        info = team_info[0]
        batting_id = str(info.get("battingTeamId", ""))
        bowling_id = str(info.get("bowlingTeamId", ""))
        order = [batting_id, bowling_id]
        abbreviations[batting_id] = info.get("battingTeamShortName", "")
        abbreviations[bowling_id] = info.get("bowlingTeamShortName", "")

    innings_by_team = {order[0]: [], order[1]: []}
    innings = scorecard.get("matchScoreDetails", {}).get("inningsScoreList", [])
    for raw_innings in innings:
        innings_team_id = str(raw_innings.get("batTeamId", ""))
        if innings_team_id in innings_by_team:
            innings_by_team[innings_team_id].append(struct(
                score = raw_innings.get("score", 0),
                wickets = raw_innings.get("wickets", 0),
                overs = raw_innings.get("overs", 0),
                declared = raw_innings.get("isDeclared", False),
            ))

    batting_team_id = str(scorecard.get("batTeam", {}).get("teamId", ""))
    batters = _normalize_batters(scorecard)
    bowler = _normalize_bowler(scorecard)
    teams = []
    for team_key in order:
        team_batters = batters if team_key == batting_team_id else []
        team_bowler = bowler if kind == "past" and team_key != batting_team_id else None
        teams.append(struct(
            id = team_key,
            name = names.get(team_key, ""),
            abbr = abbreviations.get(team_key, ""),
            innings = innings_by_team.get(team_key, []),
            batters = team_batters,
            bowler = team_bowler,
        ))
    return teams

def _normalize_batters(scorecard):
    batters = []
    for key in ["batsmanStriker", "batsmanNonStriker"]:
        raw = scorecard.get(key, {})
        if not raw:
            continue
        name = raw.get("name", raw.get("batName", ""))
        runs = raw.get("runs", raw.get("batRuns", ""))
        balls = raw.get("balls", raw.get("batBalls", ""))
        if not name:
            name = " ".join(scorecard.get("lastWicket", "Wicket Out").split(" ")[:2])
            runs = "out"
        batters.append(struct(name = name, runs = runs, balls = balls))
    return batters

def _normalize_bowler(scorecard):
    raw = scorecard.get("bowlerStriker", {})
    if not raw:
        return None
    return struct(
        name = raw.get("name", raw.get("bowlName", "")),
        overs = raw.get("overs", raw.get("bowlOvs", 0)),
        runs = raw.get("runs", raw.get("bowlRuns", 0)),
        wickets = raw.get("wickets", raw.get("bowlWkts", 0)),
    )

def _preferred_status(scorecard, header, match_info):
    for raw_status in [scorecard.get("status", ""), header.get("status", ""), match_info.get("status", "")]:
        status = raw_status.strip() if raw_status and raw_status != "$undefined" else ""
        if status:
            return status.split(" - ")[0]
    return ""

def _positive_day_number(match_info, header, scorecard):
    for value in [match_info.get("dayNumber"), header.get("dayNumber"), scorecard.get("dayNumber")]:
        if value and value != "$undefined" and int(value) > 0:
            return int(value)
    return None

def _extract_json_object(text, start_index, escaped = False):
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
    backslashes = 0
    start_capture = i

    for j in range(i, len(text)):
        char = text[j]

        if char == "\\":
            backslashes += 1
            continue

        if char == '"':
            is_delimiter = False

            if escaped:
                if backslashes % 2 != 0:
                    effective_slashes = (backslashes + 1) // 2
                    if effective_slashes % 2 != 0:
                        is_delimiter = True
            elif backslashes % 2 == 0:
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
