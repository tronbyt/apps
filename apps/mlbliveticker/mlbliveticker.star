"""
Applet: Dodgers Live Ticker
Summary: Live MLB scorebug
Description: Shows a live game state bug for any MLB team. Score, inning,
    balls and strikes, base runners, outs, and current batter. Falls back to
    a matchup card before first pitch and a final card after the game.
Author: Garrett Eddington
"""

load("cache.star", "cache")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

SCHEDULE_URL = "https://statsapi.mlb.com/api/v1/schedule?sportId=1&teamId=%s"
NEXT_URL = ("https://statsapi.mlb.com/api/v1/schedule?sportId=1&teamId=%s" +
            "&startDate=%s&endDate=%s")
LINESCORE_URL = "https://statsapi.mlb.com/api/v1/game/%s/linescore"

# The fields filter takes this feed from roughly 670 KB down to 54 KB.
PLAY_URL = ("https://statsapi.mlb.com/api/v1/game/%s/playByPlay?fields=" +
            "allPlays,result,event,eventType,isOut,about,atBatIndex," +
            "isComplete,hasOut,runners,credits,position,code,credit," +
            "playEvents,details,call")

DEFAULT_TEAM = "119"  # Los Angeles Dodgers
DEFAULT_TZ = "America/Phoenix"

LIVE_TTL = 20
IDLE_TTL = 900

# Run scored flash. FRAME_DELAY is milliseconds per frame, so the numbers
# below give a 1 second strobe followed by 9 seconds of the settled bug.
FRAME_DELAY = 100
FLASH_FRAMES = 10
NOTE_FRAMES = 20
SETTLE_FRAMES = 100
PANEL_FRAMES = 45  # 4.5 seconds per postgame panel

# Fonts for the final panel. Bitmap fonts come in fixed sizes, so these
# step 8 to 10 to 13 rather than one pixel at a time. Swap and reload.
#   tom-thumb(6), CG-pixel-4x5-mono(5), 5x8(8), tb-8(8), 6x10(10),
#   Dina_r400-6(10), 6x13(13), 10x20(20)
# 6x13 is the one with the serif tails.
ABBR_FONT = "Dina_r400-6"
SCORE_FONT = "6x10"
SCORE_MEMORY = 14400  # remember the score for 4 hours, roughly one game

RED = "#e11d1d"
DIM = "#3a3a3a"
BASE_ON = "#ffcc00"
BASE_OFF = "#2a2200"
WHITE = "#ffffff"
AMBER = "#ffb000"
BLACK = "#000000"

# id: [abbreviation, row background, row text color]
TEAMS = {
    "108": ["LAA", "#ba0021", "#ffffff"],
    "109": ["ARI", "#a71930", "#e3d4ad"],
    "110": ["BAL", "#df4601", "#ffffff"],
    "111": ["BOS", "#bd3039", "#ffffff"],
    "112": ["CHC", "#0e3386", "#ffffff"],
    "113": ["CIN", "#c6011f", "#ffffff"],
    "114": ["CLE", "#00385d", "#e50022"],
    "115": ["COL", "#333366", "#c4ced4"],
    "116": ["DET", "#0c2340", "#fa4616"],
    "117": ["HOU", "#002d62", "#eb6e1f"],
    "118": ["KC", "#004687", "#bd9b60"],
    "119": ["LAD", "#005a9c", "#ffffff"],
    "120": ["WSH", "#ab0003", "#ffffff"],
    "121": ["NYM", "#002d72", "#ff5910"],
    "133": ["ATH", "#003831", "#efb21e"],
    "134": ["PIT", "#111111", "#fdb827"],
    "135": ["SD", "#2f241d", "#ffc425"],
    "136": ["SEA", "#0c2c56", "#005c5c"],
    "137": ["SF", "#111111", "#fd5a1e"],
    "138": ["STL", "#c41e3a", "#ffffff"],
    "139": ["TB", "#092c5c", "#8fbce6"],
    "140": ["TEX", "#003278", "#c0111f"],
    "141": ["TOR", "#134a8e", "#ffffff"],
    "142": ["MIN", "#002b5c", "#d31145"],
    "143": ["PHI", "#e81828", "#ffffff"],
    "144": ["ATL", "#13274f", "#ce1141"],
    "145": ["CWS", "#111111", "#c4ced4"],
    "146": ["MIA", "#00a3e0", "#111111"],
    "147": ["NYY", "#132448", "#ffffff"],
    "158": ["MIL", "#12284b", "#ffc52f"],
}

def team_info(team_id):
    return TEAMS.get(str(team_id), ["MLB", "#222222", "#ffffff"])

def last_name(full_name):
    if not full_name:
        return ""
    parts = full_name.split(" ")
    name = parts[-1].upper()
    if len(name) > 9:
        name = name[:9]
    return name

def fetch_game(team_id):
    resp = http.get(SCHEDULE_URL % team_id, ttl_seconds = IDLE_TTL)
    if resp.status_code != 200:
        return None
    dates = resp.json().get("dates", [])
    if len(dates) == 0:
        return None
    games = dates[0].get("games", [])
    if len(games) == 0:
        return None

    # Doubleheaders: prefer whichever game is actually in progress.
    for g in games:
        if g.get("status", {}).get("abstractGameState") == "Live":
            return g
    return games[0]

def num(value, fallback = 0):
    """Pixlet's JSON decoder can hand back floats. Force whole numbers."""
    if value == None:
        return fallback
    return int(value)

def fetch_linescore(game_pk):
    resp = http.get(LINESCORE_URL % num(game_pk), ttl_seconds = LIVE_TTL)
    if resp.status_code != 200:
        return {"fetch_error": resp.status_code}
    return resp.json()

# ---------- drawing primitives ----------

def fetch_last_play(game_pk):
    """Most recent completed play that produced a result worth showing."""
    resp = http.get(PLAY_URL % num(game_pk), ttl_seconds = LIVE_TTL)
    if resp.status_code != 200:
        return None
    plays = resp.json().get("allPlays", [])
    for i in range(len(plays)):
        play = plays[len(plays) - 1 - i]
        if not play.get("about", {}).get("isComplete"):
            continue
        if play.get("result", {}).get("event", "") != "":
            return play
    return None

def error_position(play):
    for runner in play.get("runners", []):
        for credit in runner.get("credits", []):
            if credit.get("credit", "").find("error") >= 0:
                return credit.get("position", {}).get("code", "")
    return ""

def fielder_chain(play):
    """Position codes in the order they touched the ball: 6, 4, 3."""
    seq = []
    for runner in play.get("runners", []):
        for credit in runner.get("credits", []):
            if credit.get("credit") not in ["f_assist", "f_putout"]:
                continue
            code = credit.get("position", {}).get("code", "")
            if code == "":
                continue
            if len(seq) == 0 or seq[-1] != code:
                seq.append(code)
    return seq

def strikeout_looking(play):
    """True if the third strike was called rather than swung at."""
    events = play.get("playEvents", [])
    for i in range(len(events)):
        code = events[len(events) - 1 - i].get("details", {}).get("call", {}).get("code", "")
        if code != "":
            return code == "C"
    return False

# Batted ball outs that score by letter plus position rather than a chain.
AIR_OUTS = {
    "Flyout": "F",
    "Pop Out": "P",
    "Lineout": "L",
    "Sac Fly": "SF",
}

DOUBLE_PLAYS = [
    "grounded_into_double_play",
    "double_play",
    "strikeout_double_play",
    "sac_fly_double_play",
]

# Reaching base reads yellow, outs read white, mistakes read red.
GOOD = BASE_ON
OUT_WHITE = WHITE
BAD = "#ff4040"

# Simple one to one event mappings. Everything else is computed.
SIMPLE = {
    "single": ("1B", GOOD),
    "double": ("2B", GOOD),
    "triple": ("3B", GOOD),
    "home_run": ("HR", GOOD),
    "walk": ("BB", GOOD),
    "intent_walk": ("IBB", GOOD),
    "hit_by_pitch": ("HBP", GOOD),
    "catcher_interf": ("CI", GOOD),
    "sac_bunt": ("SAC", OUT_WHITE),
    "wild_pitch": ("WP", BAD),
    "passed_ball": ("PB", BAD),
}

def play_notation(play):
    """Returns (main text, sub text, color) or None."""
    result = play.get("result", {})
    event = result.get("event", "")
    event_type = result.get("eventType", "")

    if event_type in SIMPLE:
        text, color = SIMPLE[event_type]
        return (text, "", color)

    if event_type in ["strikeout", "strikeout_double_play"]:
        # Amber marks a called third strike, the backwards K you would
        # write on a scorecard. There is no glyph for it at this size.
        return ("K", "", AMBER if strikeout_looking(play) else OUT_WHITE)

    if event_type in ["field_error", "error"]:
        return ("E" + error_position(play), "", BAD)

    if event_type.startswith("stolen_base"):
        return ("SB", "", GOOD)
    if event_type.startswith("caught_stealing"):
        return ("CS", "", OUT_WHITE)
    if event_type.startswith("pickoff"):
        return ("PO", "", OUT_WHITE)

    chain = fielder_chain(play)
    is_dp = event_type in DOUBLE_PLAYS
    sub = "DP" if is_dp else ""

    if event in AIR_OUTS and len(chain) > 0:
        return (AIR_OUTS[event] + chain[-1], sub, OUT_WHITE)

    if len(chain) > 0:
        return ("-".join(chain), sub, OUT_WHITE)

    if event == "":
        return None
    return (event.upper()[:5], "", OUT_WHITE)

def detect_play(game_pk, play, override):
    """Only fire on an out we have not shown before."""
    if play == None:
        return None
    index = num(play.get("about", {}).get("atBatIndex"), -1)
    if index < 0:
        return None

    key = "play_%s" % num(game_pk)
    previous = override if override else cache.get(key)
    cache.set(key, str(index), ttl_seconds = SCORE_MEMORY)

    if not previous or previous == str(index):
        return None
    return play_notation(play)

def note_block(note):
    """Takes over the whole 34x24 right block, so it can go big."""
    main, sub, color = note

    if sub != "":
        main_font = "6x13"
    elif len(main) <= 3:
        main_font = "10x20"
    elif len(main) <= 5:
        main_font = "6x13"
    else:
        main_font = "5x8"

    children = [render.Text(main, font = main_font, color = color)]
    if sub != "":
        children.append(render.Text(sub, font = "tom-thumb", color = "#888888"))

    return render.Box(
        width = 34,
        height = 24,
        color = BLACK,
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = children,
        ),
    )

def base(occupied):
    """Drawn row by row, since Pixlet has no rotate. Home plate is at the
    bottom of the group, so second is top, third left, first right."""
    if occupied:
        widths = [1, 3, 5, 7, 5, 3, 1]
        color = BASE_ON
    else:
        widths = [1, 3, 1]
        color = BASE_OFF

    return render.Box(
        width = 8,
        height = 8,
        color = BLACK,
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.Box(width = w, height = 1, color = color)
                for w in widths
            ],
        ),
    )

def out_dot(recorded):
    return render.Circle(diameter = 5, color = RED if recorded else DIM)

def info_bar(left_text, right_text):
    return render.Box(
        width = 64,
        height = 8,
        color = "#101010",
        child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Padding(
                    pad = (2, 0, 0, 0),
                    child = render.Text(left_text, font = "tom-thumb", color = WHITE),
                ),
                render.Padding(
                    pad = (0, 0, 2, 0),
                    child = render.Text(right_text, font = "tom-thumb", color = AMBER),
                ),
            ],
        ),
    )

def team_row(team_id, runs, batting, flash = False):
    abbr, bg, fg = team_info(team_id)
    if flash:
        # Invert the row so it reads across the room.
        bg = WHITE
        fg = BLACK

    return render.Box(
        width = 30,
        height = 12,
        color = bg,
        child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Row(
                    cross_align = "center",
                    children = [
                        # One pixel wide, so a two digit score still fits.
                        render.Box(
                            width = 1,
                            height = 8,
                            color = AMBER if batting else bg,
                        ),
                        render.Padding(
                            pad = (2, 0, 0, 0),
                            child = render.Text(abbr, font = "5x8", color = fg),
                        ),
                    ],
                ),
                render.Padding(
                    pad = (0, 0, 2, 0),
                    child = render.Text(str(runs), font = "5x8", color = fg),
                ),
            ],
        ),
    )

def arrow(pointing_up, visible):
    """Drawn row by row so both directions match. The text characters
    ^ and v are different shapes and look nothing alike at this size."""
    if not visible:
        return render.Box(width = 5, height = 3, color = BLACK)

    widths = [1, 3, 5] if pointing_up else [5, 3, 1]
    return render.Column(
        cross_align = "center",
        children = [
            render.Box(width = w, height = 1, color = AMBER)
            for w in widths
        ],
    )

def inning_column(inning, is_top):
    return render.Box(
        width = 10,
        height = 24,
        color = BLACK,
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                arrow(True, is_top),
                render.Padding(
                    pad = (0, 2, 0, 2),
                    child = render.Text(str(inning), font = "tom-thumb", color = WHITE),
                ),
                arrow(False, not is_top),
            ],
        ),
    )

def diamond(on_first, on_second, on_third):
    return render.Stack(
        children = [
            render.Box(width = 24, height = 14, color = BLACK),
            render.Padding(pad = (8, 0, 0, 0), child = base(on_second)),
            render.Padding(pad = (0, 6, 0, 0), child = base(on_third)),
            render.Padding(pad = (16, 6, 0, 0), child = base(on_first)),
        ],
    )

def outs_row(outs):
    return render.Box(
        width = 24,
        height = 10,
        color = BLACK,
        child = render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Padding(pad = (1, 0, 1, 0), child = out_dot(outs > 0)),
                render.Padding(pad = (1, 0, 1, 0), child = out_dot(outs > 1)),
                render.Padding(pad = (1, 0, 1, 0), child = out_dot(outs > 2)),
            ],
        ),
    )

def state_block(ls, note):
    if note != None:
        return note_block(note)

    inning = num(ls.get("currentInning"), 1)
    state = ls.get("inningState", "Top")
    is_top = state in ["Top", "Middle"]
    offense = ls.get("offense", {})

    return render.Row(
        children = [
            inning_column(inning, is_top),
            render.Column(
                children = [
                    diamond(
                        "first" in offense,
                        "second" in offense,
                        "third" in offense,
                    ),
                    outs_row(num(ls.get("outs"))),
                ],
            ),
        ],
    )

# ---------- screens ----------

def live_frame(game, ls, lit_side, note):
    """One full 64x32 frame. lit_side is None, "away", or "home"."""
    away_id = num(game["teams"]["away"]["team"]["id"])
    home_id = num(game["teams"]["home"]["team"]["id"])
    teams = ls.get("teams", {})
    away_runs = num(teams.get("away", {}).get("runs"))
    home_runs = num(teams.get("home", {}).get("runs"))
    is_top = ls.get("inningState", "Top") in ["Top", "Middle"]

    if lit_side != None:
        scorer = away_id if lit_side == "away" else home_id
        header = "%s SCORES" % team_info(scorer)[0]
        trailer = ""
    else:
        header = last_name(ls.get("offense", {}).get("batter", {}).get("fullName", ""))
        trailer = "%d-%d" % (num(ls.get("balls")), num(ls.get("strikes")))

    return render.Column(
        children = [
            info_bar(header, trailer),
            render.Row(
                children = [
                    render.Column(
                        children = [
                            team_row(away_id, away_runs, is_top, lit_side == "away"),
                            team_row(home_id, home_runs, not is_top, lit_side == "home"),
                        ],
                    ),
                    state_block(ls, note),
                ],
            ),
        ],
    )

def live_screen(game, ls, scored_side, note):
    if scored_side == None and note == None:
        return live_frame(game, ls, None, None)

    frames = []
    active = NOTE_FRAMES if note != None else FLASH_FRAMES
    for i in range(active):
        lit = None
        if scored_side != None and i < FLASH_FRAMES and i % 2 == 0:
            lit = scored_side
        frames.append(live_frame(game, ls, lit, note))

    for _ in range(SETTLE_FRAMES):
        frames.append(live_frame(game, ls, None, None))

    return render.Animation(children = frames)

def detect_run(game_pk, away_runs, home_runs, override):
    """Compare against the last render. Returns "away", "home", or None."""
    key = "score_%s" % game_pk
    current = "%d-%d" % (away_runs, home_runs)

    previous = override if override else cache.get(key)
    cache.set(key, current, ttl_seconds = SCORE_MEMORY)

    if not previous or previous == current:
        return None

    parts = previous.split("-")
    if len(parts) != 2:
        return None

    prev_away = int(parts[0])
    prev_home = int(parts[1])

    # If both moved in one gap, favor whichever gained more.
    if home_runs - prev_home > away_runs - prev_away:
        return "home"
    if away_runs > prev_away:
        return "away"
    if home_runs > prev_home:
        return "home"
    return None

def flat_screen(game, header, away_runs, home_runs):
    away_id = num(game["teams"]["away"]["team"]["id"])
    home_id = num(game["teams"]["home"]["team"]["id"])
    return render.Column(
        children = [
            info_bar(header, ""),
            wide_row(away_id, str(away_runs)),
            wide_row(home_id, str(home_runs)),
        ],
    )

def pregame_screen(game, tz):
    start = time.parse_time(game["gameDate"]).in_location(tz)
    return flat_screen(game, start.format("3:04PM"), "-", "-")

LOGO_URL = "https://a.espncdn.com/i/teamlogos/mlb/500/%s.png"

# ESPN uses its own slugs, which do not match MLB team ids or the
# abbreviations above. Note oak for the Athletics and chw for the White Sox.
ESPN_SLUGS = {
    "108": "laa",
    "109": "ari",
    "110": "bal",
    "111": "bos",
    "112": "chc",
    "113": "cin",
    "114": "cle",
    "115": "col",
    "116": "det",
    "117": "hou",
    "118": "kc",
    "119": "lad",
    "120": "wsh",
    "121": "nym",
    "133": "oak",
    "134": "pit",
    "135": "sd",
    "136": "sea",
    "137": "sf",
    "138": "stl",
    "139": "tb",
    "140": "tex",
    "141": "tor",
    "142": "min",
    "143": "phi",
    "144": "atl",
    "145": "chw",
    "146": "mia",
    "147": "nyy",
    "158": "mil",
}

NICKNAMES = {
    "108": "Angels",
    "109": "Diamondbacks",
    "110": "Orioles",
    "111": "Red Sox",
    "112": "Cubs",
    "113": "Reds",
    "114": "Guardians",
    "115": "Rockies",
    "116": "Tigers",
    "117": "Astros",
    "118": "Royals",
    "119": "Dodgers",
    "120": "Nationals",
    "121": "Mets",
    "133": "Athletics",
    "134": "Pirates",
    "135": "Padres",
    "136": "Mariners",
    "137": "Giants",
    "138": "Cardinals",
    "139": "Rays",
    "140": "Rangers",
    "141": "Blue Jays",
    "142": "Twins",
    "143": "Phillies",
    "144": "Braves",
    "145": "White Sox",
    "146": "Marlins",
    "147": "Yankees",
    "158": "Brewers",
}

def nickname(team_id):
    return NICKNAMES.get(str(num(team_id)), "")

def logo(team_id, size):
    """Falls back to a colored initial block if the fetch fails."""
    slug = ESPN_SLUGS.get(str(num(team_id)), "")
    abbr, bg, fg = team_info(num(team_id))

    if slug == "":
        return render.Box(
            width = size,
            height = size,
            color = bg,
            child = render.Text(abbr, font = "tom-thumb", color = fg),
        )

    resp = http.get(LOGO_URL % slug, ttl_seconds = 604800)
    if resp.status_code != 200:
        return render.Box(
            width = size,
            height = size,
            color = bg,
            child = render.Text(abbr, font = "tom-thumb", color = fg),
        )

    return render.Image(src = resp.body(), width = size, height = size)

def fetch_next_game(team_id, tz):
    """First scheduled game in the next ten days."""
    now = time.now().in_location(tz)
    start = now.format("2006-01-02")
    end = (now + time.parse_duration("240h")).format("2006-01-02")

    resp = http.get(NEXT_URL % (team_id, start, end), ttl_seconds = IDLE_TTL)
    if resp.status_code != 200:
        return None

    for date in resp.json().get("dates", []):
        for game in date.get("games", []):
            if game.get("status", {}).get("abstractGameState") == "Preview":
                return game
    return None

def wide_row(team_id, text):
    """Full 64 pixel row, for screens with no bases to make room for."""
    abbr, bg, fg = team_info(team_id)

    return render.Box(
        width = 64,
        height = 12,
        color = bg,
        child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Padding(
                    pad = (3, 0, 0, 0),
                    child = render.Text(abbr, font = "5x8", color = fg),
                ),
                render.Padding(
                    pad = (0, 0, 3, 0),
                    child = render.Text(text, font = "5x8", color = fg),
                ),
            ],
        ),
    )

def slim_bar(text, center = False):
    if center:
        return render.Box(
            width = 64,
            height = 6,
            color = "#101010",
            child = render.Text(text, font = "tom-thumb", color = WHITE),
        )

    return render.Box(
        width = 64,
        height = 6,
        color = "#101010",
        child = render.Row(
            expanded = True,
            cross_align = "center",
            children = [
                render.Padding(
                    pad = (2, 0, 0, 0),
                    child = render.Text(text, font = "tom-thumb", color = WHITE),
                ),
            ],
        ),
    )

def bold_text(text, font, color):
    """No bold font exists at this size, so double strike it one pixel over."""
    return render.Stack(
        children = [
            render.Text(text, font = font, color = color),
            render.Padding(
                pad = (1, 0, 0, 0),
                child = render.Text(text, font = font, color = color),
            ),
        ],
    )

def bold_tall(text, font, color):
    """Double strike downward, so the glyph thickens without getting
    wider. That keeps a bold score centered on an unbold one."""
    return render.Stack(
        children = [
            render.Text(text, font = font, color = color),
            render.Padding(
                pad = (0, 1, 0, 0),
                child = render.Text(text, font = font, color = color),
            ),
        ],
    )

def cell(width, height, child):
    """Explicitly centers both ways rather than trusting the box."""
    return render.Box(
        width = width,
        height = height,
        color = "#00000000",
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [child],
        ),
    )

def team_line(entry, right_text, emphasize):
    """13 pixel row, three evenly weighted zones."""
    abbr, bg, fg = team_info(num(entry["team"]["id"]))
    record = entry.get("leagueRecord", {})
    rec = "%d-%d" % (num(record.get("wins")), num(record.get("losses")))

    # Color alone marks the winner. Any double strike distorts the glyph.
    score = render.Text(
        right_text,
        font = SCORE_FONT,
        color = BASE_ON if emphasize else fg,
    )

    return render.Box(
        width = 64,
        height = 13,
        color = bg,
        child = render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Padding(
                    pad = (0, 2, 0, 0),
                    child = render.Text(abbr, font = ABBR_FONT, color = fg),
                ),
                render.Padding(
                    pad = (0, 2, 0, 0),
                    child = render.Text(rec, font = "tom-thumb", color = fg),
                ),
                render.Padding(
                    pad = (0, 2, 0, 0),
                    child = score,
                ),
            ],
        ),
    )

def final_screen(game):
    away = game["teams"]["away"]
    home = game["teams"]["home"]
    away_id = num(away["team"]["id"])
    home_id = num(home["team"]["id"])
    away_runs = num(away.get("score"))
    home_runs = num(home.get("score"))

    def record_of(entry):
        r = entry.get("leagueRecord", {})
        return "%d-%d" % (num(r.get("wins")), num(r.get("losses")))

    # Apple TV style: logos anchoring the ends, scores inboard, details
    # in a bar underneath. Transparent logos, so no circles eating space.
    score_font = "5x8" if (away_runs > 9 or home_runs > 9) else "6x13"

    def score_of(value, won):
        return render.Text(
            str(value),
            font = score_font,
            color = BASE_ON if won else "#dddddd",
        )

    return render.Column(
        children = [
            render.Box(
                width = 64,
                height = 24,
                color = BLACK,
                child = render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        logo(away_id, 20),
                        score_of(away_runs, away_runs > home_runs),
                        render.Text("-", font = "tom-thumb", color = "#8a8a8a"),
                        score_of(home_runs, home_runs > away_runs),
                        logo(home_id, 20),
                    ],
                ),
            ),
            render.Box(
                width = 64,
                height = 8,
                color = "#141414",
                child = render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Text(record_of(away), font = "tom-thumb", color = "#7a7a7a"),
                        render.Text("FINAL", font = "tom-thumb", color = WHITE),
                        render.Text(record_of(home), font = "tom-thumb", color = "#7a7a7a"),
                    ],
                ),
            ),
        ],
    )

def next_logos(game, tz):
    away_id = num(game["teams"]["away"]["team"]["id"])
    home_id = num(game["teams"]["home"]["team"]["id"])
    start = time.parse_time(game["gameDate"]).in_location(tz)

    return render.Column(
        children = [
            render.Box(
                width = 64,
                height = 26,
                color = BLACK,
                child = render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        logo(away_id, 24),
                        render.Text("@", font = "6x13", color = WHITE),
                        logo(home_id, 24),
                    ],
                ),
            ),
            slim_bar(start.format("Mon 3:04PM"), True),
        ],
    )

def next_screen(game, tz):
    if game == None:
        return render.Column(
            children = [
                slim_bar("NEXT"),
                render.Box(
                    width = 64,
                    height = 26,
                    color = BLACK,
                    child = render.Text("NO GAME", font = "5x8", color = DIM),
                ),
            ],
        )
    return next_logos(game, tz)

def postgame_rotation(game, team_id, tz):
    """Final with records, the next matchup in logos, then spelled out."""
    upcoming = fetch_next_game(team_id, tz)

    panels = [final_screen(game)]
    if upcoming != None:
        panels.append(next_logos(upcoming, tz))
    else:
        panels.append(next_screen(None, tz))

    frames = []
    for panel in panels:
        for _ in range(PANEL_FRAMES):
            frames.append(panel)
    return render.Animation(children = frames)

def message(text):
    return render.Box(
        child = render.WrappedText(text, font = "tom-thumb", color = "#777"),
    )

# ---------- entry point ----------

def main(config):
    team_id = config.get("team", DEFAULT_TEAM)
    tz = config.get("$tz", DEFAULT_TZ)

    game = fetch_game(team_id)
    if game == None:
        if config.bool("hide_idle", True):
            return []
        return render.Root(child = message("No game today"))

    state = game.get("status", {}).get("abstractGameState", "")

    if state == "Live":
        ls = fetch_linescore(game["gamePk"])
        if "fetch_error" in ls:
            return render.Root(child = message("HTTP %s" % ls["fetch_error"]))

        teams = ls.get("teams", {})
        scored_side = detect_run(
            num(game["gamePk"]),
            num(teams.get("away", {}).get("runs")),
            num(teams.get("home", {}).get("runs")),
            config.get("prev_score", ""),
        )

        note = detect_play(
            game["gamePk"],
            fetch_last_play(game["gamePk"]),
            config.get("prev_play", ""),
        )

        return render.Root(
            child = live_screen(game, ls, scored_side, note),
            delay = FRAME_DELAY,
            max_age = LIVE_TTL,
            show_full_animation = scored_side != None or note != None,
        )

    if state == "Final":
        return render.Root(
            child = postgame_rotation(game, team_id, tz),
            delay = FRAME_DELAY,
        )

    return render.Root(child = pregame_screen(game, tz))

def get_schema():
    options = [
        schema.Option(display = "%s" % v[0], value = k)
        for k, v in TEAMS.items()
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "team",
                name = "Team",
                desc = "Which club to track.",
                icon = "baseball",
                default = DEFAULT_TEAM,
                options = options,
            ),
            schema.Toggle(
                id = "hide_idle",
                name = "Skip on off days",
                desc = "Hide the app entirely when there is no game.",
                icon = "eyeSlash",
                default = True,
            ),
        ],
    )
