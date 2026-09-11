"""
Applet: WPBL Standings
Summary: Calculates and displays WPBL regular and postseason results
Description: Fetches game results, parses regular season standings and postseason series matchups, and toggles between them.
Author: zandif
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

GAMES_API_URL = "https://stats.womensprobaseballleague.com/v1/games?limit=100"
CACHE_TTL_SECONDS = 1800  # 30 minutes

# Colors sourced from each team's official palette per Wikipedia's infobox
# (verified hex, not guessed) — same values the Based iOS app uses. Dark
# primary + vivid secondary, mirroring how this file already treats teams
# like the Pirates/White Sox/Giants (dark bg, bright accent text).
TEAMS = {
    "Boston Hunters": ["BOS", "#00281F", "#F4801B", "Boston Hunters"],
    "Los Angeles Queens": ["LAQ", "#000000", "#B09067", "Los Angeles Queens"],
    "New York Heights": ["NYH", "#091C47", "#68C4E9", "New York Heights"],
    "San Francisco Firebells": ["SFF", "#2D1748", "#FF2100", "San Francisco Firebells"],
}

# Known team overrides (branding colors & fixed abbreviations)
TEAM_META = {
    "BOS": {"name": "BOS", "bg": "#00281F", "color": "#F4801B"},
    "LAQ": {"name": "LAQ", "bg": "#000000", "color": "#B09067"},
    "NYH": {"name": "NYH", "bg": "#091C47", "color": "#68C4E9"},
    "SFF": {"name": "SFF", "bg": "#2D1748", "color": "#FF2100"},
}

# Fallback palette for dynamically discovered teams
FALLBACK_PALETTE = [
    "#00E676",  # Green
    "#FFEA00",  # Yellow
    "#00E5FF",  # Cyan
    "#FF4081",  # Pink
    "#FF9100",  # Amber
    "#B388FF",  # Lavender
    "#76FF03",  # Lime
    "#FF6E40",  # Deep Orange
]

FONT_2X = {
    "CG-pixel-3x5-mono": "tom-thumb",
    "tom-thumb": "6x10",
    "tb-8": "terminus-16",
    "5x8": "terminus-16",
    "6x13": "terminus-24",
    "10x20": "terminus-32",
}

def get_font(name, scale):
    return FONT_2X.get(name, name) if scale == 2 else name

def get_fallback_color(code):
    """Derives a stable, readable accent color from a team code."""
    hash_val = 0
    for char in code.elems():
        hash_val = (hash_val * 31 + ord(char)) % len(FALLBACK_PALETTE)
    return FALLBACK_PALETTE[hash_val]

def normalize_team_key(raw_name):
    """Maps team name to 3-character code, generating an acronym for unknown teams."""
    val = str(raw_name).strip()
    upper_val = val.upper()

    # Check known teams first
    if "SAN FRANCISCO" in upper_val or "FIREBELLS" in upper_val or upper_val.startswith("SF"):
        return "SFF"
    if "LOS ANGELES" in upper_val or "QUEENS" in upper_val or upper_val.startswith("LA"):
        return "LAQ"
    if "NEW YORK" in upper_val or "HEIGHTS" in upper_val or upper_val.startswith("NY"):
        return "NYH"
    if "BOSTON" in upper_val or "HUNTERS" in upper_val or upper_val.startswith("BOS"):
        return "BOS"

    # For new/unknown teams: attempt acronym from multi-word names
    words = [w for w in upper_val.split(" ") if len(w) > 0]
    if len(words) >= 3:
        return (words[0][0] + words[1][0] + words[2][0])[:3]
    elif len(words) == 2:
        return (words[0][:2] + words[1][0])[:3]

    # Single-word name fallback: slice or pad to 3 chars
    clean = upper_val.replace(" ", "")
    if len(clean) >= 3:
        return clean[:3]
    elif len(clean) == 2:
        return clean + " "
    elif len(clean) == 1:
        return clean + "  "
    return "TBD"

def get_team_color(code):
    """Resolves color from TEAM_META or falls back to calculated palette color."""
    if code in TEAM_META:
        return TEAM_META[code]["color"]
    return get_fallback_color(code)

def get_team_bg(code):
    """Resolves background color from TEAM_META or falls back to dark default."""
    if code in TEAM_META:
        return TEAM_META[code]["bg"]
    return "#111111"

def parse_scores(game):
    """Extracts integer (home_score, away_score) from game object."""
    presto = game.get("presto_data")
    if type(presto) == "dict":
        score_obj = presto.get("score")
        if type(score_obj) == "dict":
            home_val = score_obj.get("home")
            away_val = score_obj.get("away")
            if home_val != None and away_val != None and str(home_val) != "" and str(away_val) != "":
                return int(home_val), int(away_val)

    state = game.get("state")
    if type(state) == "dict":
        home_val = state.get("home_score")
        away_val = state.get("away_score")
        if home_val != None and away_val != None:
            return int(home_val), int(away_val)

    home_val = game.get("home_score", game.get("home_runs"))
    away_val = game.get("away_score", game.get("away_runs"))
    if home_val != None and away_val != None and str(home_val) != "" and str(away_val) != "":
        return int(home_val), int(away_val)

    return None, None

def detect_playoff_round(game):
    """Identifies the series round (e.g. Finals vs Semifinals)."""
    text_check = (
        str(game.get("round", "")) + " " +
        str(game.get("series", "")) + " " +
        str(game.get("game_type", "")) + " " +
        str(game.get("eventTypeDescription", ""))
    ).lower()

    if "champ" in text_check or "final" in text_check and "semi" not in text_check:
        return "FINALS"
    return "SEMIFINALS"

def fetch_data():
    """Fetches games, splits into regular season standings and postseason series."""
    cached = cache.get("wpbl_all_data")
    if cached != None:
        return json.decode(cached)

    res = http.get(GAMES_API_URL, ttl_seconds = CACHE_TTL_SECONDS)
    if res.status_code != 200:
        return {"regular": [], "postseason": []}

    data = res.json()
    games = data if type(data) == "list" else data.get("games", data.get("data", []))

    # Initialize records dynamically
    regular_records = {}
    postseason_matchups = {}

    # Aggregate game results
    for g in games:
        status = str(g.get("status", "")).lower()
        is_final = "final" in status or "completed" in status or "closed" in status

        home_name = g.get("home_team_name", g.get("home_team", ""))
        away_name = g.get("away_team_name", g.get("away_team", ""))

        home_key = normalize_team_key(home_name)
        away_key = normalize_team_key(away_name)

        home_score, away_score = parse_scores(g)

        # Check game_type or nested eventType flags
        game_type = str(g.get("game_type", "")).lower()
        event_type = g.get("eventType")
        is_postseason_flag = False
        if type(event_type) == "dict":
            is_postseason_flag = event_type.get("isPostSeason", False)

        is_postseason = "post" in game_type or "playoff" in game_type or is_postseason_flag

        if is_postseason:
            # Sort keys to ensure matchup identity regardless of home/away
            round_label = detect_playoff_round(g)
            teams_sorted = [home_key, away_key]
            if home_key > away_key:
                teams_sorted = [away_key, home_key]

            # Unique key incorporates the round so Semifinals and Finals don't collide
            m_key = round_label + ":" + teams_sorted[0] + "-" + teams_sorted[1]
            team1, team2 = teams_sorted[0], teams_sorted[1]

            if m_key not in postseason_matchups:
                postseason_matchups[m_key] = {
                    "round": round_label,
                    "team1": team1,
                    "team2": team2,
                    "team1_color": get_team_color(team1),
                    "team2_color": get_team_color(team2),
                    "team1_bg": get_team_bg(team1),
                    "team2_bg": get_team_bg(team2),
                    "wins1": 0,
                    "wins2": 0,
                }

            if is_final and home_score != None and away_score != None:
                if home_score > away_score:
                    if home_key == team1:
                        postseason_matchups[m_key]["wins1"] += 1
                    else:
                        postseason_matchups[m_key]["wins2"] += 1
                elif away_score > home_score:
                    if away_key == team1:
                        postseason_matchups[m_key]["wins1"] += 1
                    else:
                        postseason_matchups[m_key]["wins2"] += 1

        else:
            # Regular Season aggregation
            for k in [home_key, away_key]:
                if k not in regular_records:
                    regular_records[k] = {
                        "team": k,
                        "wins": 0,
                        "losses": 0,
                        "color": get_team_color(k),
                    }

            if is_final and home_score != None and away_score != None:
                if home_score > away_score:
                    regular_records[home_key]["wins"] += 1
                    regular_records[away_key]["losses"] += 1
                elif away_score > home_score:
                    regular_records[away_key]["wins"] += 1
                    regular_records[home_key]["losses"] += 1

    # Format Regular Season Standings
    standings_list = []
    for team_code, row in regular_records.items():
        if row["team"] == "TBD" and row["wins"] == 0 and row["losses"] == 0:
            continue

        total_games = row["wins"] + row["losses"]
        pct = float(row["wins"]) / float(total_games) if total_games > 0 else 0.0
        standings_list.append({
            "team": row["team"],
            "wins": row["wins"],
            "losses": row["losses"],
            "pct": pct,
            "color": row["color"],
        })

    # Selection Sort (descending by Win PCT, then Wins)
    n = len(standings_list)
    for i in range(n):
        max_idx = i
        for j in range(i + 1, n):
            j_pct = standings_list[j]["pct"]
            max_pct = standings_list[max_idx]["pct"]
            if (j_pct > max_pct) or (j_pct == max_pct and standings_list[j]["wins"] > standings_list[max_idx]["wins"]):
                max_idx = j
        temp = standings_list[i]
        standings_list[i] = standings_list[max_idx]
        standings_list[max_idx] = temp

    # Calculate Games Behind (GB) & Assign Rank
    if len(standings_list) > 0:
        leader_w = standings_list[0]["wins"]
        leader_l = standings_list[0]["losses"]

        for idx, row in enumerate(standings_list):
            row["rank"] = str(idx + 1)
            if idx == 0 or (row["wins"] == 0 and row["losses"] == 0 and leader_w == 0):
                row["gb"] = "-"
            else:
                diff = (leader_w - row["wins"]) + (row["losses"] - leader_l)
                if diff <= 0:
                    row["gb"] = "-"
                elif diff % 2 == 0:
                    row["gb"] = str(diff // 2)
                else:
                    row["gb"] = str(diff // 2) + ".5"

    # Format Postseason Series (Prioritize FINALS first)
    finals_list = []
    semis_list = []
    for _, match in postseason_matchups.items():
        if match["round"] == "FINALS":
            finals_list.append(match)
        else:
            semis_list.append(match)

    postseason_list = finals_list + semis_list

    payload = {
        "regular": standings_list,
        "postseason": postseason_list,
    }

    cache.set("wpbl_all_data", json.encode(payload), ttl_seconds = CACHE_TTL_SECONDS)
    return payload

def render_row(item, is_alternate, scale):
    """Renders a single row on the display."""
    bg_color = "#111111" if is_alternate else "#000000"

    return render.Box(
        width = 64 * scale,
        height = 6 * scale,
        color = bg_color,
        child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                # Rank & Team Code
                render.Row(
                    cross_align = "center",
                    children = [
                        render.Box(
                            width = 7 * scale,
                            child = render.Text(
                                content = item["rank"],
                                font = get_font("tom-thumb", scale),
                                color = "#777777",
                            ),
                        ),
                        render.Text(
                            content = item["team"],
                            font = get_font("tom-thumb", scale),
                            color = item.get("color", "#FFFFFF"),
                        ),
                    ],
                ),
                # Symmetrical record column centered on dash with small gap on loss number
                render.Box(
                    width = 21 * scale,
                    child = render.Row(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Box(
                                width = 9 * scale,
                                child = render.Row(
                                    expanded = True,
                                    main_align = "end",
                                    children = [
                                        render.Text(
                                            content = str(item["wins"]),
                                            font = get_font("tom-thumb", scale),
                                            color = "#E0E0E0",
                                        ),
                                    ],
                                ),
                            ),
                            render.Box(
                                width = 3 * scale,
                                child = render.Row(
                                    expanded = True,
                                    main_align = "center",
                                    children = [
                                        render.Text(
                                            content = "-",
                                            font = get_font("tom-thumb", scale),
                                            color = "#888888",
                                        ),
                                    ],
                                ),
                            ),
                            render.Box(
                                width = 9 * scale,
                                child = render.Row(
                                    expanded = True,
                                    main_align = "start",
                                    children = [
                                        render.Padding(
                                            pad = (1 * scale, 0, 0, 0),
                                            child = render.Text(
                                                content = str(item["losses"]),
                                                font = get_font("tom-thumb", scale),
                                                color = "#E0E0E0",
                                            ),
                                        ),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ),
                # Games Behind (GB) - Right aligned
                render.Box(
                    width = 12 * scale,
                    child = render.Row(
                        expanded = True,
                        main_align = "end",
                        children = [
                            render.Text(
                                content = item["gb"],
                                font = get_font("tom-thumb", scale),
                                color = "#FFD700" if item["gb"] == "-" else "#AAAAAA",
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def render_postseason_card(item, card_height_unscaled, scale):
    """Renders a postseason matchup series card dynamically fitting available height."""
    round_label = item.get("round", "SERIES")
    is_finals = round_label == "FINALS"
    label_color = "#FFD700" if is_finals else "#888888"

    # Dynamic pill height based on available card slot
    pill_height = 12 if card_height_unscaled >= 24 else 9

    return render.Box(
        width = 64 * scale,
        height = card_height_unscaled * scale,
        color = "#000000",
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Text(
                    content = "CHAMPIONSHIP" if (is_finals and card_height_unscaled >= 20) else round_label,
                    font = get_font("CG-pixel-3x5-mono", scale),
                    color = label_color,
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_around",
                    cross_align = "center",
                    children = [
                        # Left Team
                        render.Box(
                            width = 25 * scale,
                            height = pill_height * scale,
                            color = item["team1_bg"],
                            child = render.Row(
                                expanded = True,
                                main_align = "space_between",
                                cross_align = "center",
                                children = [
                                    render.Padding(
                                        pad = (2 * scale, 0, 0, 0),
                                        child = render.Text(
                                            content = item["team1"],
                                            font = get_font("tom-thumb", scale),
                                            color = item["team1_color"],
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (0, 0, 3 * scale, 0),
                                        child = render.Text(
                                            content = str(item["wins1"]),
                                            font = get_font("tb-8", scale),
                                            color = "#FFFFFF" if item["wins1"] >= item["wins2"] else "#666666",
                                        ),
                                    ),
                                ],
                            ),
                        ),
                        render.Text(
                            content = "VS",
                            font = get_font("CG-pixel-3x5-mono", scale),
                            color = "#555555",
                        ),
                        # Right Team
                        render.Box(
                            width = 25 * scale,
                            height = pill_height * scale,
                            color = item["team2_bg"],
                            child = render.Row(
                                expanded = True,
                                main_align = "space_between",
                                cross_align = "center",
                                children = [
                                    render.Padding(
                                        pad = (3 * scale, 0, 0, 0),
                                        child = render.Text(
                                            content = str(item["wins2"]),
                                            font = get_font("tb-8", scale),
                                            color = "#FFFFFF" if item["wins2"] >= item["wins1"] else "#666666",
                                        ),
                                    ),
                                    render.Padding(
                                        pad = (0, 0, 2 * scale, 0),
                                        child = render.Text(
                                            content = item["team2"],
                                            font = get_font("tom-thumb", scale),
                                            color = item["team2_color"],
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def build_regular_view(standings, scale):
    """Builds the regular season standings view (header + rows)."""
    header = render.Box(
        width = 64 * scale,
        height = 8 * scale,
        color = "#00281F",
        child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Padding(
                    pad = (1 * scale, 0, 0, 0),
                    child = render.Text(
                        content = "WPBL",
                        font = get_font("tb-8", scale),
                        color = "#FFD700",
                    ),
                ),
                # Record column header positioned over the dash
                render.Padding(
                    pad = (0, 1 * scale, 0, 0),
                    child = render.Box(
                        width = 21 * scale,
                        child = render.Row(
                            expanded = True,
                            main_align = "start",
                            children = [
                                render.Padding(
                                    pad = (2 * scale, 0, 0, 0),
                                    child = render.Text(
                                        content = "REC" if scale == 1 else "RECORD",
                                        font = get_font("tom-thumb", scale),
                                        color = "#A0A0A0",
                                    ),
                                ),
                            ],
                        ),
                    ),
                ),
                render.Padding(
                    pad = (0, 1 * scale, 1 * scale, 0),
                    child = render.Text(
                        content = "GB",
                        font = get_font("tom-thumb", scale),
                        color = "#A0A0A0",
                    ),
                ),
            ],
        ),
    )

    # Render all available teams
    rows = []
    for i, team in enumerate(standings):
        rows.append(render_row(team, is_alternate = (i % 2 == 1), scale = scale))

    # If more than 4 teams, enable vertical scrolling with a 10s pause on top 4
    if len(rows) > 4:
        content_area = render.Box(
            width = 64 * scale,
            height = 24 * scale,
            child = render.Marquee(
                height = 24 * scale,
                scroll_direction = "vertical",
                delay = 100,  # 100 frames * ~100ms/frame = ~10 second hold on top rows
                child = render.Column(children = rows),
            ),
        )
    else:
        content_area = render.Column(children = rows)

    return render.Column(
        children = [
            header,
            content_area,
        ],
    )

def build_postseason_view(postseason, scale):
    """Builds the postseason series view supporting 1, 2, or 3+ series."""
    count = len(postseason)
    if count == 0:
        return render.Box(width = 64 * scale, height = 32 * scale)

    # 1 Matchup: Fill whole 32px height
    # 2 Matchups: Each gets 16px
    # 3+ Matchups (e.g. 2 Semis + 1 Finals): 16px each inside a vertical marquee with 10s hold
    slot_height = 32 if count == 1 else 16
    cards = []
    for match in postseason:
        cards.append(render_postseason_card(match, slot_height, scale))

    if count > 2:
        return render.Box(
            width = 64 * scale,
            height = 32 * scale,
            child = render.Marquee(
                height = 32 * scale,
                scroll_direction = "vertical",
                delay = 100,  # 10s hold on top series before cycling through the rest
                child = render.Column(children = cards),
            ),
        )

    return render.Column(
        expanded = True,
        main_align = "space_evenly",
        children = cards,
    )

def main(config):
    # Detect 2x display dynamically from config
    is_2x = config.bool("$2x", False) or config.get("$width") == "128" or config.get("display_size") == "128x64"
    scale = 2 if is_2x else 1

    data = fetch_data()
    regular_standings = data.get("regular", [])
    postseason_matches = data.get("postseason", [])

    regular_view = build_regular_view(regular_standings, scale)

    # If postseason games exist, hold each screen for 100 frames (~10s) using animation.Transformation
    if len(postseason_matches) > 0:
        postseason_view = build_postseason_view(postseason_matches, scale)

        return render.Root(
            delay = 100,
            child = render.Sequence(
                children = [
                    animation.Transformation(
                        child = render.Box(
                            width = 64 * scale,
                            height = 32 * scale,
                            child = postseason_view,
                        ),
                        duration = 100,
                        keyframes = [],
                    ),
                    animation.Transformation(
                        child = render.Box(
                            width = 64 * scale,
                            height = 32 * scale,
                            child = regular_view,
                        ),
                        duration = 100,
                        keyframes = [],
                    ),
                ],
            ),
        )

    return render.Root(
        delay = 100,
        child = regular_view,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
