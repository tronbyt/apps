load("humanize.star", "humanize")
load("render.star", "render")
load("time.star", "time")

FRAME_DELAY = 4000

BLACK_COLOR = "#222222"
WHITE_COLOR = "#FFFFFF"

def render_scoreboard(match, team_styles, tz, now, scale):
    layout = _layout(scale)
    if match.kind == "live":
        return _render_live(match, team_styles, layout)
    if match.kind == "past":
        return _render_past(match, team_styles, tz, layout)
    return _render_upcoming(match, team_styles, tz, now, layout)

def _layout(scale):
    if scale not in [1, 2]:
        fail("scale must be 1 or 2")
    return struct(
        scale = scale,
        large_font = "terminus-14" if scale == 2 else "CG-pixel-4x5-mono",
        small_font = "terminus-12" if scale == 2 else "CG-pixel-3x5-mono",
        player_font = "terminus-12" if scale == 2 else "tom-thumb",
        team_font = "terminus-16" if scale == 2 else "tb-8",
        score_height = 7 * scale,
        player_height = 6 * scale,
        team_height = 8 * scale,
        versus_height = 9 * scale,
        status_height = 5 * scale,
        inset = 1 * scale,
        score_gap = 2 * scale,
        width = 64 * scale,
        marquee_delay = 20 * scale,
        scroll_frame_delay = 50 // scale,
    )

def _render_live(match, team_styles, layout):
    is_test = match.format == "test"
    team_scores = _team_scores(match, team_styles)

    player_rows = [[], []]
    for index in range(len(match.teams)):
        team = match.teams[index]
        style = team_styles[team.id]
        for batter in team.batters:
            player_rows[index].append(_render_batter_row(batter, style.fg_color, layout))

    row_team_1 = _render_team_score_row(team_scores[0], layout)
    row_team_2 = _render_team_score_row(team_scores[1], layout)
    statuses = ["", "", "", ""]
    default_status = ""

    if is_test:
        default_status = _test_status(match)
        overs_remaining = _safe_float(match.remaining_overs)
        if overs_remaining > 0:
            statuses[2] = "Overs rem - {}".format(humanize.float("#.#", overs_remaining))
        else:
            statuses[2] = "{} Innings".format(humanize.ordinal(int(match.innings_id)))
        runs_to_win = _runs_to_win(match)
        if runs_to_win > 0:
            statuses[0] = "{} runs to win".format(int(runs_to_win))
    else:
        recent_balls = match.recent_overs.split(" ")
        last_six = []
        for ball in reversed(recent_balls):
            if len(last_six) == 6:
                break
            if ball in ["|", "...", ""]:
                continue
            last_six.append(ball)
        default_status = "..." + " ".join(reversed(last_six))
        statuses[1] = "Run Rate: {}".format(humanize.float("#.#", float(match.current_rate)))
        if match.innings_id == 2:
            statuses[0] = "{} runs to win".format(int(_safe_float(match.remaining_runs)))
            statuses[2] = "Reqd Rate: {}".format(humanize.float("#.#", float(match.required_rate)))

    columns = []
    for status in statuses:
        children = [row_team_1]
        children.extend(player_rows[0])
        children.append(row_team_2)
        children.extend(player_rows[1])
        children.append(_render_status_row(status if status else default_status, layout))
        columns.append(render.Column(children = children))

    return _render_status_animation(columns, layout)

def _render_past(match, team_styles, tz, layout):
    team_scores = _team_scores(match, team_styles)
    score_rows = [_render_team_score_row(team_score, layout) for team_score in team_scores]
    player_rows = []
    for team in match.teams:
        style = team_styles[team.id]
        if team.batters:
            player_rows.append(_render_batter_row(team.batters[0], style.fg_color, layout))
        elif team.bowler:
            player_rows.append(_render_bowler_row(team.bowler, style.fg_color, layout))
        else:
            player_rows.append(None)

    result_status = _result_status(match, team_scores)
    match_start = time.from_timestamp(match.start_ms // 1000).in_location(tz)
    date_status = match_start.format("Jan 2 2006")
    columns = []
    for index in range(4):
        status = date_status if index == 3 else result_status
        columns.append(
            render.Column(
                children = [
                    score_rows[0],
                    player_rows[0],
                    score_rows[1],
                    player_rows[1],
                    _render_status_row(status, layout),
                ],
            ),
        )

    return _render_status_animation(columns, layout)

def _render_upcoming(match, team_styles, tz, now, layout):
    match_start = time.from_timestamp(match.start_ms // 1000).in_location(tz)
    match_time_status = match_start.format("Jan 2 - 3:04 PM")
    time_to_start = match_start - now
    if time_to_start < time.parse_duration("48h"):
        match_time_status = humanize.time(match_start)
    elif time_to_start < time.parse_duration("168h"):
        match_time_status = match_start.format("Mon - 3:04 PM")

    team_rows = []
    for team in match.teams:
        style = team_styles[team.id]
        team_rows.append(_render_team_row(team.name, style.fg_color, style.bg_color, layout))

    vs_row = render.Row(
        main_align = "center",
        expanded = True,
        children = [render.Box(height = layout.versus_height, child = render.Text(content = "vs", color = WHITE_COLOR, font = layout.small_font))],
    )
    venue = match.venue.city
    if len(venue) < 14:
        country = match.venue.country
        for style in team_styles.values():
            if country.lower() == style.name.lower():
                country = style.abbr
                break
        venue = "{}, {}".format(venue, country)

    state_status = match_time_status if match.state in ["preview", "upcoming"] else match.state
    statuses = [match.description, state_status, state_status, venue]
    frames = []
    hold_frames = FRAME_DELAY // layout.scroll_frame_delay
    for status in statuses:
        column = render.Column(
            children = [
                team_rows[0],
                vs_row,
                team_rows[1],
                _render_status_row(status, layout),
            ],
        )
        frames.extend([column] * hold_frames)

    return render.Root(
        delay = layout.scroll_frame_delay,
        show_full_animation = True,
        child = render.Animation(children = frames),
    )

def _team_scores(match, team_styles):
    scores = []
    for team in match.teams:
        style = team_styles[team.id]
        score = 0
        wickets = 0
        overs = 0
        for innings in reversed(team.innings):
            if match.format == "test":
                innings_score = str(innings.score)
                if innings.wickets < 10:
                    innings_score = "{}/{}{}".format(innings.score, innings.wickets, "d" if innings.declared else "")
                score = "{} & {}".format(score, innings_score) if score else innings_score
            else:
                score = innings.score
                wickets = innings.wickets
                overs = innings.overs
        scores.append(struct(
            id = team.id,
            name = team.name,
            abbr = team.abbr if team.abbr else style.abbr,
            score = score,
            wickets = wickets,
            overs = overs,
            fg_color = style.fg_color,
            bg_color = style.bg_color,
        ))
    return scores

def _test_status(match):
    if match.status:
        return match.status
    if match.day_number != None and match.day_number > 0:
        return "Day {} {}".format(match.day_number, match.state).strip()
    return match.state if match.state else "Test match"

def _runs_to_win(match):
    remaining = _safe_float(match.remaining_runs)
    target = _safe_float(match.target)
    if remaining == 0 and target > 0:
        return target - _safe_float(match.batting_score)
    return remaining

def _result_status(match, team_scores):
    result = match.result
    if not result.type:
        return match.result_status
    if result.type == "tie":
        return "Match tied"
    if result.type == "noresult":
        return "Match abandoned"
    if result.type == "draw":
        return "Match draw"

    win_type = " runs" if result.by_runs else " wkts"
    innings_win = "in & " if result.by_innings else ""
    winner = team_scores[0].abbr if result.winning_team_id == team_scores[0].id else team_scores[1].abbr
    return "{} by {}{}{}{}".format(winner, innings_win, result.margin, win_type, "")

def _render_team_score_row(team_score, layout):
    wicket_display = ""
    over_display = ""
    if team_score.overs:
        over_display = " {}".format(_rounded_overs(team_score.overs))
    if team_score.overs and team_score.wickets != 10:
        wicket_display = "/{}".format(team_score.wickets)

    if not team_score.score and not team_score.wickets:
        score_display = "-"
    else:
        score_display = "{}{}{}".format(team_score.score, wicket_display, over_display)

    split_score = score_display.split(" ")
    first_score = render.Text(content = split_score[0], color = team_score.fg_color, font = layout.small_font)
    score_columns = [first_score]
    score_width = first_score.size()[0]
    for value in split_score[1:]:
        text = render.Text(content = value, color = team_score.fg_color, font = layout.small_font)
        score_columns.append(render.Padding(pad = (layout.score_gap, 0, 0, 0), child = text))
        score_width += layout.score_gap + text.size()[0]

    score_row = render.Row(children = score_columns)
    team_name = team_score.name if layout.scale == 2 else team_score.abbr
    team_text = render.Text(content = team_name, color = team_score.fg_color, font = layout.large_font)
    team_label = render.Row(children = [team_text])
    if layout.scale == 2:
        team_label = render.Marquee(
            width = layout.width - layout.inset - layout.score_gap - score_width,
            delay = layout.marquee_delay,
            child = team_text,
        )

    return render.Box(
        height = layout.score_height,
        color = team_score.bg_color,
        child = render.Padding(
            pad = (layout.inset, 0, 0, 0),
            child = render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    team_label,
                    score_row,
                ],
            ),
        ),
    )

def _render_batter_row(batter, fg_color, layout):
    balls = "({})".format(batter.balls) if batter.balls else ""
    return _render_player_row(_player_name(batter.name, layout), "{}{}".format(batter.runs, balls), fg_color, layout)

def _render_bowler_row(bowler, fg_color, layout):
    overs = _rounded_overs(bowler.overs)
    overs = str(int(overs)) if overs > 10 else str(overs)
    return _render_player_row(
        _player_name(bowler.name, layout),
        "{}-{}-{}".format(overs, bowler.runs, bowler.wickets),
        fg_color,
        layout,
    )

def _render_player_row(left_text, right_text, fg_color, layout):
    return render.Box(
        height = layout.player_height,
        child = render.Padding(
            pad = (layout.inset, 0, 0, 0),
            child = render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Column(cross_align = "start", children = [render.Text(content = left_text, color = fg_color, font = layout.player_font)]),
                    render.Column(cross_align = "end", children = [render.Text(content = right_text, color = fg_color, font = layout.small_font)]),
                ],
            ),
        ),
    )

def _render_team_row(name, fg_color, bg_color, layout):
    content = name.upper()
    text = render.Text(content = content, color = fg_color, font = layout.team_font)
    if layout.scale == 2 and text.size()[0] > layout.width:
        text = render.Text(content = content, color = fg_color, font = layout.small_font)
    return render.Box(
        height = layout.team_height,
        color = bg_color,
        child = render.Marquee(
            width = layout.width,
            align = "center",
            delay = layout.marquee_delay,
            child = text,
        ),
    )

def _render_status_animation(columns, layout):
    if layout.scale == 1:
        return render.Root(
            delay = FRAME_DELAY,
            child = render.Animation(children = columns),
        )

    frames = []
    hold_frames = FRAME_DELAY // layout.scroll_frame_delay
    for column in columns:
        frames.extend([column] * hold_frames)
    return render.Root(
        delay = layout.scroll_frame_delay,
        child = render.Animation(children = frames),
    )

def _render_status_row(text, layout):
    content = []
    for word in text.split(" "):
        content.append(
            render.Padding(
                pad = (layout.inset, 0, layout.inset, 0),
                child = render.Text(content = word, color = WHITE_COLOR, font = layout.small_font),
            ),
        )
    return render.Padding(
        pad = (0, layout.inset, 0, 0),
        child = render.Box(
            height = layout.status_height,
            color = BLACK_COLOR,
            child = render.Row(main_align = "center", expanded = True, children = content),
        ),
    )

def _player_name(name, layout):
    first = name.split(" ")[0]
    last = name.split(" ")[-1]
    display = first[0] + ". " + last
    return display if layout.scale == 2 or len(display) <= 7 else last[:7]

def _rounded_overs(overs):
    if overs % 1 > 0.5:
        return int(overs) + 1
    if overs % 1 == 0:
        return int(overs)
    return overs

def _safe_float(value):
    if type(value) == "string":
        if value == "$undefined":
            return 0.0
        return float(value)
    return float(value) if value else 0.0
