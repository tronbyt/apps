"""
Applet: WPBL Live Ticker
Summary: Live WPBL scorebug
Description: Shows a live game state bug for one or more Women's Pro
    Baseball League teams — check any combination of the 4 clubs to rotate
    through all of them. Score, inning, balls and strikes, base runners,
    outs, and current batter. Falls back to a matchup card before first
    pitch and a final card after the game.
Author: Colin Weir
"""

load("cache.star", "cache")
load("http.star", "http")

# Cropped from each team's official brand kit (Reverse mark, cream/white on
# the team's own primary color — the exact same hex this file uses below for
# that team's row background, so the square logo blends seamlessly into it).
load("images/boston.png", BOSTON_LOGO = "file")
load("images/laq.png", LAQ_LOGO = "file")
load("images/nyh.png", NYH_LOGO = "file")
load("images/sff.png", SFF_LOGO = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

# 2x renders at 128x64 instead of 64x32. Every pixel dimension below is
# defined in 1x terms and passed through px() at the call site; bitmap fonts
# are fixed-size, so 2x swaps in a taller face via font() instead of scaling
# glyphs, same pattern documented in AGENTS.md.
SCALE = 2 if canvas.is2x() else 1

def px(n):
    return n * SCALE

FONT_2X = {
    "tom-thumb": "6x10",
    "5x8": "terminus-16",
    "6x13": "terminus-24",
    "10x20": "terminus-32",
}

def font(name):
    return FONT_2X.get(name, name) if SCALE == 2 else name

# Unofficial, reverse-engineered API — see WPBL.md at the root of this repo
# for the full write-up. No auth, no CORS, Presto Sports data underneath.
GAMES_URL = "https://stats.womensprobaseballleague.com/v1/games?limit=0"
BOXSCORE_URL = "https://stats.womensprobaseballleague.com/v1/games/%s/boxscore"

DEFAULT_TEAM = "9f08or2mffx81409"  # Boston Hunters
DEFAULT_TZ = "America/Phoenix"

GAMES_TTL = 300  # schedule/status list — which game is "today's" changes slowly
LIVE_TTL = 20  # boxscore — score, count, bases, last play

# Run scored flash. FRAME_DELAY is milliseconds per frame, so the numbers
# below give a 1 second strobe followed by 9 seconds of the settled bug.
FRAME_DELAY = 100
FLASH_FRAMES = 10
NOTE_FRAMES = 20
SETTLE_FRAMES = 100
PANEL_FRAMES = 45  # 4.5 seconds per postgame panel

SCORE_MEMORY = 14400  # remember the score for 4 hours, roughly one game

RED = "#e11d1d"
DIM = "#3a3a3a"
BASE_ON = "#ffcc00"
BASE_OFF = "#2a2200"
WHITE = "#ffffff"
AMBER = "#ffb000"
BLACK = "#000000"

# Reaching base reads yellow, outs read white, mistakes read red.
GOOD = BASE_ON
OUT_WHITE = WHITE
BAD = "#ff4040"

# team_id: [abbreviation, row background, row text color, full name]
# Colors sourced from each team's official palette per Wikipedia's infobox
# (verified hex, not guessed) — same values the Based iOS app uses. Dark
# primary + vivid secondary, mirroring how this file already treats teams
# like the Pirates/White Sox/Giants (dark bg, bright accent text).
TEAMS = {
    "9f08or2mffx81409": ["BOS", "#00281F", "#F4801B", "Boston Hunters"],
    "v4gisr4rbgmn67b0": ["LAQ", "#000000", "#B09067", "Los Angeles Queens"],
    "fttth861nft1j2s7": ["NYH", "#091C47", "#68C4E9", "New York Heights"],
    "vhubhz8li07tmgq8": ["SFF", "#2D1748", "#FF2100", "San Francisco Firebells"],
}

# Fixed rotation/display order — same order the checkboxes appear in.
TEAM_IDS = ["9f08or2mffx81409", "v4gisr4rbgmn67b0", "fttth861nft1j2s7", "vhubhz8li07tmgq8"]

def team_info(team_id):
    return TEAMS.get(team_id, ["WPBL", "#222222", "#ffffff", "WPBL"])

TEAM_LOGOS = {
    "9f08or2mffx81409": BOSTON_LOGO,
    "v4gisr4rbgmn67b0": LAQ_LOGO,
    "fttth861nft1j2s7": NYH_LOGO,
    "vhubhz8li07tmgq8": SFF_LOGO,
}

def last_name(full_name):
    if not full_name:
        return ""
    parts = full_name.split(" ")
    name = parts[-1].upper()
    if len(name) > 9:
        name = name[:9]
    return name

def num(value, fallback = 0):
    """Pixlet's JSON decoder can hand back floats. Force whole numbers."""
    if value == None:
        return fallback
    return int(value)

def format_scheduled(game, tz, layout, fallback = "TBD"):
    """A malformed/missing scheduled_start shouldn't crash the whole
    render — Starlark has no try/except, so this checks before parsing
    rather than catching a failure after the fact."""
    scheduled_start = game.get("scheduled_start", "")
    if scheduled_start == "":
        return fallback
    return time.parse_time(scheduled_start).in_location(tz).format(layout)

# ---------- schedule / boxscore fetching ----------

def fetch_games():
    resp = http.get(GAMES_URL, ttl_seconds = GAMES_TTL)
    if resp.status_code != 200:
        return []
    return resp.json().get("games", []) or []

def team_games(games, team_id):
    return [
        g
        for g in games
        if g.get("home_team_id") == team_id or g.get("away_team_id") == team_id
    ]

def is_final_status(status):
    return (status or "").find("Final") >= 0

def sched_date(g, tz):
    """scheduled_start is UTC — comparing its raw date substring against a
    tz-local "today" would misfile any game near the UTC day boundary (WPBL's
    17:00-23:30 UTC evening games sit close to it), so this converts to the
    same tz before taking the date."""
    scheduled_start = g.get("scheduled_start") or ""
    if scheduled_start == "":
        return ""
    return time.parse_time(scheduled_start).in_location(tz).format("2006-01-02")

def pick_today_game(games, team_id, today, tz):
    """WPBL's schedule carries stale "Not Started" duplicate game_ids that
    were superseded by a different game_id once the real game was played
    (observed: two dead "Not Started" stubs for the same matchup/day sitting
    alongside the real completed game, the stubs' updated_at frozen months or
    days before the real one's). updated_at is the reliable freshness signal
    — it's recent for whichever record is actually live or just went final,
    and stale for an abandoned duplicate — so the most recently updated
    game for today is always the one worth showing."""
    mine = [g for g in team_games(games, team_id) if sched_date(g, tz) == today]
    if len(mine) == 0:
        return None
    return sorted(mine, key = lambda g: g.get("updated_at") or "", reverse = True)[0]

def fetch_next_game(games, team_id, after_start):
    """Earliest upcoming game for this team after the given ISO timestamp."""
    mine = [
        g
        for g in team_games(games, team_id)
        if not is_final_status(g.get("status", "")) and (g.get("scheduled_start") or "") > after_start
    ]
    if len(mine) == 0:
        return None
    return sorted(mine, key = lambda g: g.get("scheduled_start") or "")[0]

def fetch_boxscore(game_id):
    resp = http.get(BOXSCORE_URL % game_id, ttl_seconds = LIVE_TTL)
    if resp.status_code != 200:
        return None
    return resp.json().get("boxscore", {})

def find_side(teams, side):
    for t in teams:
        if t.get("side") == side:
            return t
    return {}

# ---------- play-by-play notation ----------

# WPBL's narrative uses these short lowercase tokens after "to" (e.g.
# "grounded out to 3b", "double play p to 2b to 1b"). Verified against
# real completed games, not guessed — see WPBL.md.
POSITION_MAP = {
    "pitcher": "1",
    "p": "1",
    "catcher": "2",
    "c": "2",
    "1b": "3",
    "2b": "4",
    "3b": "5",
    "ss": "6",
    "shortstop": "6",
    "lf": "7",
    "cf": "8",
    "rf": "9",
}

def match_position(raw_token):
    token = raw_token.strip(".,;()")
    return POSITION_MAP.get(token, "")

def fielding_position(narrative):
    """Position codes in the order the ball touched them, e.g. '6-4-3'."""
    tokens = narrative.lower().split(" ")
    positions = []
    for i, token in enumerate(tokens):
        if token != "to":
            continue
        if len(positions) == 0 and i > 0:
            leading = match_position(tokens[i - 1])
            if leading != "":
                positions.append(leading)
        if i + 1 < len(tokens):
            mapped = match_position(tokens[i + 1])
            if mapped != "":
                positions.append(mapped)
    return "-".join(positions)

def narrative_reached_on_error(narrative):
    lower = narrative.lower()
    return lower.find("reached") >= 0 and lower.find("on an error") >= 0

def error_position(narrative):
    lower = narrative.lower()
    marker = "on an error by "
    idx = lower.find(marker)
    if idx < 0:
        return ""
    rest = narrative[idx + len(marker):]
    token = rest.split(" ")[0].split(",")[0].strip(".,;()")
    return match_position(token.lower())

# Simple one to one event_type mappings. Everything else is computed.
SIMPLE = {
    "single": ("1B", GOOD),
    "double": ("2B", GOOD),
    "triple": ("3B", GOOD),
    "home_run": ("HR", GOOD),
    "walk": ("BB", GOOD),
    "intentional_walk": ("IBB", GOOD),
    "intent_walk": ("IBB", GOOD),
    "hit_by_pitch": ("HBP", GOOD),
    "wild_pitch": ("WP", BAD),
    "passed_ball": ("PB", BAD),
    "balk": ("BK", BAD),
    "stolen_base": ("SB", GOOD),
    "caught_stealing": ("CS", OUT_WHITE),
    "pickoff": ("PO", OUT_WHITE),
}

def play_notation(play):
    """Returns (main text, sub text, color) or None if the play log entry
    (substitution notice, failed pickoff attempt, etc.) has no notation."""
    narrative = play.get("narrative", "")
    event_type = play.get("event_type", "")

    # WPBL tags "reached first on an error" with event_type "unknown", the
    # same generic tag used for pure substitution/administrative notices —
    # the narrative text is the only reliable signal, so check it first.
    if narrative_reached_on_error(narrative):
        return ("E" + error_position(narrative), "", BAD)

    if event_type in SIMPLE:
        text, color = SIMPLE[event_type]
        return (text, "", color)

    if event_type == "strikeout":
        return ("K", "", AMBER if narrative.lower().find("looking") >= 0 else OUT_WHITE)

    if event_type == "sacrifice":
        if narrative.lower().find("bunt") >= 0:
            return ("SAC", "", OUT_WHITE)
        return ("SF" + fielding_position(narrative), "", OUT_WHITE)

    if event_type == "fielders_choice":
        return ("FC" + fielding_position(narrative), "", OUT_WHITE)

    if event_type == "groundout":
        chain = fielding_position(narrative)
        return (chain if chain != "" else "GO", "", OUT_WHITE)

    if event_type in ["flyout", "foul_out"]:
        chain = fielding_position(narrative)
        return ("F" + chain.split("-")[-1] if chain != "" else "FO", "", OUT_WHITE)

    if event_type == "lineout":
        chain = fielding_position(narrative)
        return ("L" + chain.split("-")[-1] if chain != "" else "LO", "", OUT_WHITE)

    if event_type == "popup":
        chain = fielding_position(narrative)
        return ("P" + chain.split("-")[-1] if chain != "" else "PU", "", OUT_WHITE)

    if event_type in ["forceout", "force_out"]:
        chain = fielding_position(narrative)
        return (chain if chain != "" else "FO", "", OUT_WHITE)

    if event_type == "out":
        # WPBL tags plenty of routine batted-ball outs (mostly double plays
        # and force outs) with the generic event_type "out" rather than
        # "groundout"/"flyout"/etc. — disambiguate from the narrative text,
        # same approach the Based iOS app's WPBL scorecard uses.
        lower = narrative.lower()
        chain = fielding_position(narrative)
        sub = "DP" if lower.find("double play") >= 0 else ""
        if lower.find("triple play") >= 0:
            return ("TP", "", OUT_WHITE)
        if lower.find("fly") >= 0:
            return ("F" + chain.split("-")[-1] if chain != "" else "FO", sub, OUT_WHITE)
        if lower.find("line") >= 0:
            return ("L" + chain.split("-")[-1] if chain != "" else "LO", sub, OUT_WHITE)
        if lower.find("pop") >= 0:
            return ("P" + chain.split("-")[-1] if chain != "" else "PU", sub, OUT_WHITE)
        if lower.find("foul") >= 0:
            return ("F" + chain.split("-")[-1] if chain != "" else "FO", sub, OUT_WHITE)
        if chain != "":
            return (chain, sub, OUT_WHITE)
        return ("OUT", "", OUT_WHITE)

    return None

def fetch_last_meaningful_play(plays):
    """Most recent play log entry that produced notation worth showing —
    skips substitutions, failed pickoff attempts, and other bare notices."""
    if not plays:
        return None
    for play in reversed(plays):
        if play_notation(play) != None:
            return play
    return None

def detect_play(game_id, play, override):
    """Only fire on a play we have not shown before."""
    if play == None:
        return None
    index = num(play.get("sequence"), -1)
    if index < 0:
        return None

    key = "play_%s" % game_id
    previous = override if override else cache.get(key)
    cache.set(key, str(index), ttl_seconds = SCORE_MEMORY)

    if not previous or previous == str(index):
        return None
    return play_notation(play)

def note_block(note):
    """Takes over the whole 34x24 (logical) right block, so it can go big."""
    main, sub, color = note

    if sub != "":
        main_font = "6x13"
    elif len(main) <= 3:
        main_font = "10x20"
    elif len(main) <= 5:
        main_font = "6x13"
    else:
        main_font = "5x8"

    children = [render.Text(main, font = font(main_font), color = color)]
    if sub != "":
        children.append(render.Text(sub, font = font("tom-thumb"), color = "#888888"))

    return render.Box(
        width = px(34),
        height = px(24),
        color = BLACK,
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = children,
        ),
    )

# ---------- drawing primitives ----------

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
        width = px(8),
        height = px(8),
        color = BLACK,
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.Box(width = px(w), height = px(1), color = color)
                for w in widths
            ],
        ),
    )

def out_dot(recorded):
    return render.Circle(diameter = px(5), color = RED if recorded else DIM)

def info_bar(left_text, right_text):
    return render.Box(
        width = px(64),
        height = px(8),
        color = "#101010",
        child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Padding(
                    pad = (px(2), 0, 0, 0),
                    child = render.Text(left_text, font = font("tom-thumb"), color = WHITE),
                ),
                render.Padding(
                    pad = (0, 0, px(2), 0),
                    child = render.Text(right_text, font = font("tom-thumb"), color = AMBER),
                ),
            ],
        ),
    )

def team_row(team_id, runs, batting, flash = False):
    abbr, bg, fg, _ = team_info(team_id)
    if flash:
        # Invert the row so it reads across the room.
        bg = WHITE
        fg = BLACK

    return render.Box(
        width = px(30),
        height = px(12),
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
                            width = px(1),
                            height = px(8),
                            color = AMBER if batting else bg,
                        ),
                        render.Padding(
                            pad = (px(2), 0, 0, 0),
                            child = render.Text(abbr, font = font("5x8"), color = fg),
                        ),
                    ],
                ),
                render.Padding(
                    pad = (0, 0, px(2), 0),
                    child = render.Text(str(runs), font = font("5x8"), color = fg),
                ),
            ],
        ),
    )

def arrow(pointing_up, visible):
    """Drawn row by row so both directions match. The text characters
    ^ and v are different shapes and look nothing alike at this size."""
    if not visible:
        return render.Box(width = px(5), height = px(3), color = BLACK)

    widths = [1, 3, 5] if pointing_up else [5, 3, 1]
    return render.Column(
        cross_align = "center",
        children = [
            render.Box(width = px(w), height = px(1), color = AMBER)
            for w in widths
        ],
    )

def inning_column(inning, is_top):
    return render.Box(
        width = px(10),
        height = px(24),
        color = BLACK,
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                arrow(True, is_top),
                render.Padding(
                    pad = (0, px(2), 0, px(2)),
                    child = render.Text(str(inning), font = font("tom-thumb"), color = WHITE),
                ),
                arrow(False, not is_top),
            ],
        ),
    )

def diamond(on_first, on_second, on_third):
    return render.Stack(
        children = [
            render.Box(width = px(24), height = px(14), color = BLACK),
            render.Padding(pad = (px(8), 0, 0, 0), child = base(on_second)),
            render.Padding(pad = (0, px(6), 0, 0), child = base(on_third)),
            render.Padding(pad = (px(16), px(6), 0, 0), child = base(on_first)),
        ],
    )

def outs_row(outs):
    return render.Box(
        width = px(24),
        height = px(10),
        color = BLACK,
        child = render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Padding(pad = (px(1), 0, px(1), 0), child = out_dot(outs > 0)),
                render.Padding(pad = (px(1), 0, px(1), 0), child = out_dot(outs > 1)),
                render.Padding(pad = (px(1), 0, px(1), 0), child = out_dot(outs > 2)),
            ],
        ),
    )

def state_block(status, note):
    if note != None:
        return note_block(note)

    inning = num(status.get("inning"), 1)
    is_top = status.get("half", "top") != "bottom"

    return render.Row(
        children = [
            inning_column(inning, is_top),
            render.Column(
                children = [
                    diamond(
                        status.get("first_base", "") != "",
                        status.get("second_base", "") != "",
                        status.get("third_base", "") != "",
                    ),
                    outs_row(num(status.get("outs"))),
                ],
            ),
        ],
    )

# ---------- screens ----------

def live_frame(away_id, home_id, status, lit_side, note):
    """One full 64x32 frame. lit_side is None, "away", or "home"."""
    away_runs = num(status.get("away_runs"))
    home_runs = num(status.get("home_runs"))
    is_top = status.get("half", "top") != "bottom"

    if lit_side != None:
        scorer = away_id if lit_side == "away" else home_id
        header = "%s SCORES" % team_info(scorer)[0]
        trailer = ""
    else:
        header = last_name(status.get("batter_name", ""))
        trailer = "%d-%d" % (num(status.get("balls")), num(status.get("strikes")))

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
                    state_block(status, note),
                ],
            ),
        ],
    )

def live_frames(away_id, home_id, status, scored_side, note):
    """Always a list — a single steady-state frame when nothing just
    happened, or the full flash/settle sequence when it did."""
    if scored_side == None and note == None:
        return [live_frame(away_id, home_id, status, None, None)]

    frames = []
    active = NOTE_FRAMES if note != None else FLASH_FRAMES
    for i in range(active):
        lit = None
        if scored_side != None and i < FLASH_FRAMES and i % 2 == 0:
            lit = scored_side
        frames.append(live_frame(away_id, home_id, status, lit, note))

    frames += repeat(live_frame(away_id, home_id, status, None, None), SETTLE_FRAMES)

    return frames

def detect_run(game_id, away_runs, home_runs, override):
    """Compare against the last render. Returns "away", "home", or None."""
    key = "score_%s" % game_id
    current = "%d-%d" % (away_runs, home_runs)

    previous = override if override else cache.get(key)
    cache.set(key, current, ttl_seconds = SCORE_MEMORY)

    if not previous or previous == current:
        return None

    parts = previous.split("-")
    if len(parts) != 2:
        return None

    # A malformed override (bad config value, corrupt cache entry) would
    # otherwise crash int() with no way to catch it — Starlark has no
    # exception handling, so this checks before converting.
    if not parts[0].isdigit() or not parts[1].isdigit():
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

def wide_row(team_id, text):
    """Full-width row, for screens with no bases to make room for."""
    abbr, bg, fg, _ = team_info(team_id)

    return render.Box(
        width = px(64),
        height = px(12),
        color = bg,
        child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Padding(
                    pad = (px(3), 0, 0, 0),
                    child = render.Text(abbr, font = font("5x8"), color = fg),
                ),
                render.Padding(
                    pad = (0, 0, px(3), 0),
                    child = render.Text(text, font = font("5x8"), color = fg),
                ),
            ],
        ),
    )

def flat_screen(away_id, home_id, header, away_text, home_text):
    return render.Column(
        children = [
            info_bar(header, ""),
            wide_row(away_id, away_text),
            wide_row(home_id, home_text),
        ],
    )

def pregame_screen(game, tz):
    away_id = game.get("away_team_id", "")
    home_id = game.get("home_team_id", "")
    header = format_scheduled(game, tz, "3:04PM")
    return flat_screen(away_id, home_id, header, "-", "-")

def logo_block(team_id, size):
    """WPBL's own hosted logo images sit behind a Cloudflare bot challenge
    that blocks server-side fetches (verified: direct requests get a 403
    with cf-mitigated: challenge), so real crests are bundled locally
    instead — cropped from each team's brand kit, see TEAM_LOGOS above.
    Falls back to a colored initial block for any team not in that map."""
    logo = TEAM_LOGOS.get(team_id)
    if logo != None:
        return render.Image(src = logo.readall(), width = px(size), height = px(size))

    abbr, bg, fg, _ = team_info(team_id)
    return render.Box(
        width = px(size),
        height = px(size),
        color = bg,
        child = render.Text(abbr, font = font("tom-thumb"), color = fg),
    )

def slim_bar(text, center = False):
    if center:
        return render.Box(
            width = px(64),
            height = px(6),
            color = "#101010",
            child = render.Text(text, font = font("tom-thumb"), color = WHITE),
        )

    return render.Box(
        width = px(64),
        height = px(6),
        color = "#101010",
        child = render.Row(
            expanded = True,
            cross_align = "center",
            children = [
                render.Padding(
                    pad = (px(2), 0, 0, 0),
                    child = render.Text(text, font = font("tom-thumb"), color = WHITE),
                ),
            ],
        ),
    )

def score_font_for(away_runs, home_runs):
    return "5x8" if (away_runs > 9 or home_runs > 9) else "6x13"

def final_screen(boxscore):
    teams = boxscore.get("teams", []) or []
    away = find_side(teams, "away")
    home = find_side(teams, "home")
    away_id = away.get("id", "")
    home_id = home.get("id", "")
    away_runs = num((away.get("totals") or {}).get("runs"))
    home_runs = num((home.get("totals") or {}).get("runs"))

    score_font = font(score_font_for(away_runs, home_runs))

    def score_of(value, won):
        return render.Text(
            str(value),
            font = score_font,
            color = BASE_ON if won else "#dddddd",
        )

    return render.Column(
        children = [
            render.Box(
                width = px(64),
                height = px(24),
                color = BLACK,
                child = render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        logo_block(away_id, 20),
                        score_of(away_runs, away_runs > home_runs),
                        render.Text("-", font = font("tom-thumb"), color = "#8a8a8a"),
                        score_of(home_runs, home_runs > away_runs),
                        logo_block(home_id, 20),
                    ],
                ),
            ),
            render.Box(
                width = px(64),
                height = px(8),
                color = "#141414",
                child = render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Text(away.get("record", "") or "0-0", font = font("tom-thumb"), color = "#7a7a7a"),
                        render.Text("FINAL", font = font("tom-thumb"), color = WHITE),
                        render.Text(home.get("record", "") or "0-0", font = font("tom-thumb"), color = "#7a7a7a"),
                    ],
                ),
            ),
        ],
    )

def next_logos(game, tz):
    away_id = game.get("away_team_id", "")
    home_id = game.get("home_team_id", "")
    start_text = format_scheduled(game, tz, "Mon 3:04PM")

    return render.Column(
        children = [
            render.Box(
                width = px(64),
                height = px(26),
                color = BLACK,
                child = render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        logo_block(away_id, 24),
                        render.Text("@", font = font("6x13"), color = WHITE),
                        logo_block(home_id, 24),
                    ],
                ),
            ),
            slim_bar(start_text, True),
        ],
    )

def next_screen_empty():
    return render.Column(
        children = [
            slim_bar("NEXT"),
            render.Box(
                width = px(64),
                height = px(26),
                color = BLACK,
                child = render.Text("NO GAME", font = font("5x8"), color = DIM),
            ),
        ],
    )

def repeat(node, n):
    return [node for _ in range(n)]

def postgame_frames(boxscore, games, team_id, finished_game, tz):
    """Final with records, then the next matchup in logos."""
    upcoming = fetch_next_game(games, team_id, finished_game.get("scheduled_start") or "")

    panels = [final_screen(boxscore)]
    panels.append(next_logos(upcoming, tz) if upcoming != None else next_screen_empty())

    frames = []
    for panel in panels:
        frames += repeat(panel, PANEL_FRAMES)
    return frames

def message(text):
    return render.Box(
        child = render.WrappedText(text, font = font("tom-thumb"), color = "#777"),
    )

# ---------- entry point ----------

def selected_teams(config):
    return [tid for tid in TEAM_IDS if config.bool("team_%s" % tid, tid == DEFAULT_TEAM)]

def team_screen(team_id, games, today, tz, hide_idle, score_override, play_override):
    """One team's current frames, plus live-flash metadata (max_age,
    show_full_animation) when live — None for every other state.
    `frames` is always a list, possibly empty (idle + hide_idle)."""
    game = pick_today_game(games, team_id, today, tz)
    if game == None:
        if hide_idle:
            return [], None
        return [message("%s: no game today" % team_info(team_id)[3])], None

    status_text = game.get("status", "")

    if status_text == "Not Started":
        return [pregame_screen(game, tz)], None

    game_id = game.get("game_id", "")
    if game_id == "":
        return [message("%s: malformed game data" % team_info(team_id)[3])], None

    box = fetch_boxscore(game_id)
    if box == None:
        return [message("%s: fetch error" % team_info(team_id)[3])], None

    if is_final_status(box.get("game_status", status_text)):
        return postgame_frames(box, games, team_id, game, tz), None

    # Live (or a status string we don't recognize — safest to try live).
    live_status = box.get("status", {}) or {}
    away_id = game.get("away_team_id", "")
    home_id = game.get("home_team_id", "")

    scored_side = detect_run(
        game_id,
        num(live_status.get("away_runs")),
        num(live_status.get("home_runs")),
        score_override,
    )

    note = detect_play(
        game_id,
        fetch_last_meaningful_play(box.get("plays")),
        play_override,
    )

    frames = live_frames(away_id, home_id, live_status, scored_side, note)
    live_meta = (LIVE_TTL, scored_side != None or note != None)
    return frames, live_meta

def main(config):
    tz = config.get("$tz", DEFAULT_TZ)
    hide_idle = config.bool("hide_idle", True)
    teams = selected_teams(config)

    if len(teams) == 0:
        return [] if hide_idle else render.Root(child = message("No team selected"))

    games = fetch_games()

    # "Today" in the device's own timezone, not UTC — WPBL's evening games
    # (17:00-23:30 UTC) already sit close to the UTC day boundary, so a
    # viewer whose local midnight falls in that window would otherwise see
    # today's/tomorrow's game misfiled by a day right when it matters most.
    today = time.now().in_location(tz).format("2006-01-02")

    if len(teams) == 1:
        # Single team: preserve the exact original behavior (no rotation
        # overhead, live-flash max_age/show_full_animation hints intact).
        frames, live_meta = team_screen(
            teams[0],
            games,
            today,
            tz,
            hide_idle,
            config.get("prev_score", ""),
            config.get("prev_play", ""),
        )
        if len(frames) == 0:
            return []

        child = frames[0] if len(frames) == 1 else render.Animation(children = frames)

        if live_meta != None:
            max_age, show_full = live_meta
            return render.Root(child = child, delay = FRAME_DELAY, max_age = max_age, show_full_animation = show_full)
        if len(frames) > 1:
            return render.Root(child = child, delay = FRAME_DELAY)
        return render.Root(child = child)

    # Multiple teams: rotate through each selected team's screen in turn.
    # The single-game "prev_score"/"prev_play" override doesn't generalize
    # to more than one game at once, so every team falls back to cache.star
    # for its own flash-detection state (the common no-op case anyway).
    all_frames = []
    seen_game_ids = {}
    any_live = False
    for team_id in teams:
        # WPBL only has 4 teams, so two selected teams playing each other
        # is a real, common case — without this, their shared game would
        # show twice back to back with an identical score. Whichever team
        # comes first in TEAM_IDS order "claims" the game; the other is
        # skipped for this slot (its own distinct next-game panel included).
        today_game = pick_today_game(games, team_id, today, tz)
        game_id = today_game.get("game_id") if today_game != None else None
        if game_id != None:
            if game_id in seen_game_ids:
                continue
            seen_game_ids[game_id] = True

        frames, live_meta = team_screen(team_id, games, today, tz, hide_idle, "", "")
        any_live = any_live or live_meta != None

        # A lone frame (idle message, pregame card, error, or a quiet live
        # bug) would otherwise flash by in a single FRAME_DELAY tick — hold
        # it for a full panel's worth like the postgame/live-flash sequences
        # already do.
        if len(frames) == 1:
            frames = repeat(frames[0], PANEL_FRAMES)

        all_frames += frames

    if len(all_frames) == 0:
        return []

    # At least one selected team is live right now — refresh at the same
    # cadence as the single-team path so scores don't lag behind just
    # because more than one team is being watched.
    if any_live:
        return render.Root(child = render.Animation(children = all_frames), delay = FRAME_DELAY, max_age = LIVE_TTL)
    return render.Root(child = render.Animation(children = all_frames), delay = FRAME_DELAY)

def get_schema():
    team_toggles = [
        schema.Toggle(
            id = "team_%s" % team_id,
            name = TEAMS[team_id][3],
            desc = "Follow the %s." % TEAMS[team_id][3],
            icon = "baseball",
            default = team_id == DEFAULT_TEAM,
        )
        for team_id in TEAM_IDS
    ]
    return schema.Schema(
        version = "1",
        fields = team_toggles + [
            schema.Toggle(
                id = "hide_idle",
                name = "Skip on off days",
                desc = "Hide a team's turn in the rotation when it has no game.",
                icon = "eyeSlash",
                default = True,
            ),
        ],
    )
