"""
Applet: Live Tennis
Summary: Live WTA, Challenger, ITF
Description: Live scores for the circuits ESPN does not carry. Every other tennis app in this repo reads site.api.espn.com, which serves exactly two tennis leagues, atp and wta, so Challenger and ITF have no app at all. This one reads the whole live slate from the Live Tennis API (livetennisapi.com) instead: pick Challenger, ITF, WTA or all tours and it shows whatever is on court right now, no tournament to choose. Per match: both surnames, the set score, the games in the current set and the point in the current game, with a green ball beside the server and a red bar beside a player holding break point. Rotates through the live matches, walking further down the slate each refresh. Needs a free API key (no card), whose quota is 100 requests a day: at the recommended 15 minute interval that is 1440/15 = 96 a day, and the response is cached for 900 seconds so the app cannot poll harder than that whatever the device asks.
Author: Ben Abulafia
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# GET /matches?status=live is a FREE-tier endpoint of the Live Tennis API.
# Confirmed against https://docs.livetennisapi.com/openapi.yaml (servers[0].url,
# paths./matches) and https://docs.livetennisapi.com/llms.txt ("GET /matches -
# List matches by lifecycle status (FREE)").
MATCHES_URL = "https://api.livetennisapi.com/api/public/v1/matches"

# The key travels in the X-API-Key header. openapi.yaml declares
# components.securitySchemes.apiKeyHeader as {type: apiKey, in: header,
# name: X-API-Key}; the ?token= query form is documented too but URLs leak
# into logs and referrers, so the header is the right choice here.
API_KEY_HEADER = "X-API-Key"

# Free tier quota, from llms.txt ("FREE ($0, no card) - live & upcoming
# matches, current scores ... 30 req/min, 100 req/day").
#
# The arithmetic that fixes the cadence:
#   1440 minutes in a day / 15 minute interval = 96 requests a day <= 100,
#   leaving 4 for the settings page and manual refreshes.
# manifest.yaml sets recommendedInterval: 15 to match (that field is in
# MINUTES - see update_intervals.txt in the repo root).
#
# CACHE_SECONDS is the part that does not depend on the device honouring the
# recommendation. pixlet serves the cached body until the TTL expires, so a
# device configured to refresh every minute still only reaches the API once
# per 900 seconds and stays inside the quota.
REFRESH_MINUTES = 15
CACHE_SECONDS = REFRESH_MINUTES * 60

# One page of the live slate. Big enough to hold a busy ITF day, small enough
# to parse well inside pixlet's render budget.
PAGE_LIMIT = 30

# Matches shown per render, and how long each is held.
#
# pixlet render rejects animations longer than 15s (--max-duration), so the
# budget is MATCHES_PER_RENDER * FRAMES_PER_MATCH * FRAME_DELAY_MS <= 15000.
# 3 * 45 * 100 = 13500ms leaves headroom.
MATCHES_PER_RENDER = 3
FRAMES_PER_MATCH = 45
FRAME_DELAY_MS = 100

# Live scores that stop updating are worse than no scores. A device that loses
# connectivity drops the app rather than leaving a frozen scoreboard up, after
# twice the refresh interval.
MAX_AGE_SECONDS = 2 * CACHE_SECONDS

# Display geometry, 64x32. The cells are fixed-width Boxes rather than padded
# strings because CG-pixel-3x5-mono advances 1-4px per glyph (see
# `pixlet community list-fonts`) - its spaces are narrower than its digits, so
# string padding would not line the two player rows up.
ROW_FONT = "CG-pixel-3x5-mono"
HEAD_FONT = "tom-thumb"
INNER_W = 62
BADGE_W = 14
MARKER_W = 4
NAME_W = 34
SETS_W = 5
GAMES_W = 9
POINTS_W = 9
NAME_CHARS = 8

BG = "#000000"
DIVIDER = "#1b2430"
NAME_COLOR = "#ffffff"
SETS_COLOR = "#ffd166"
GAMES_COLOR = "#cbd5e1"
POINTS_COLOR = "#ffffff"
SERVE_COLOR = "#22c55e"
BREAK_COLOR = "#ef4444"
FOOT_COLOR = "#64748b"
ALERT_COLOR = "#ef4444"

# Tour badge, keyed by the `tour` field on Match. openapi.yaml gives that field
# the closed vocabulary [atp, wta, challenger, itf, juniors, null] and states it
# shares the vocabulary of the ?tour= filter, so these are all the values an
# app can receive; null falls through to the default.
TOUR_BADGES = {
    "wta": ("WTA", "#c084fc"),
    "atp": ("ATP", "#38bdf8"),
    "challenger": ("CH", "#fb923c"),
    "itf": ("ITF", "#4ade80"),
    "juniors": ("JR", "#f472b6"),
}
DEFAULT_BADGE = ("TEN", "#94a3b8")

ALL_TOURS = "all"

TOUR_OPTIONS = [
    schema.Option(display = "Challenger", value = "challenger"),
    schema.Option(display = "ITF", value = "itf"),
    schema.Option(display = "WTA", value = "wta"),
    schema.Option(display = "All tours", value = ALL_TOURS),
]

TOUR_LABELS = {
    "challenger": "CHALLENGER",
    "itf": "ITF",
    "wta": "WTA",
    ALL_TOURS: "TENNIS",
}

# Shown when no API key is configured, so the app has something honest to draw
# and the catalogue preview shows the real layout. The first match carries a
# break point (p2 receiving at AD), the second does not.
SAMPLE_MATCHES = [
    {
        "tournament": "Challenger Seville",
        "tour": "challenger",
        "round": "Quarterfinal",
        "round_code": "QF",
        "players": {"p1": {"name": "Martin Landaluce"}, "p2": {"name": "Pablo Llamas Ruiz"}},
        "score": {
            "sets": [1, 0],
            "games": [[6, 4], [3, 5]],
            "points": ["30", "AD"],
            "server": 1,
            "is_tiebreak": False,
        },
    },
    {
        "tournament": "WTA Guadalajara",
        "tour": "wta",
        "round": "Round of 16",
        "round_code": "R16",
        "players": {"p1": {"name": "Renata Zarazua"}, "p2": {"name": "Emiliana Arango"}},
        "score": {
            # p1 took the first set 6-4 and the second is at 6-6, so the
            # points array is the running tiebreak count, not 0/15/30/40.
            "sets": [1, 0],
            "games": [[6, 6], [4, 6]],
            "points": ["3", "5"],
            "server": 2,
            "is_tiebreak": True,
        },
    },
]

def main(config):
    api_key = config.str("api_key", "").strip()
    tour = config.str("tour", "challenger")
    singles_only = config.bool("singles_only", True)

    if not api_key:
        # Not an error: the app is simply unconfigured. The sample slate with
        # the instruction in place of the footer says what to do and shows what
        # it will look like once it is done, which one line of text cannot.
        return render_slate(SAMPLE_MATCHES, 0, "ADD YOUR API KEY IN APP SETTINGS", ALERT_COLOR)

    matches, problem = fetch_live(api_key, tour, singles_only)

    if problem != None:
        return render_notice(problem)

    if len(matches) == 0:
        return render_notice("NO LIVE %s MATCHES" % TOUR_LABELS.get(tour, "TENNIS"))

    return render_slate(matches, rotation_offset(len(matches)), None, FOOT_COLOR)

def fetch_live(api_key, tour, singles_only):
    """Reads the live slate.

    Args:
        api_key: Live Tennis API key, sent in the X-API-Key header.
        tour: one of the ?tour= values, or ALL_TOURS to omit the filter.
        singles_only: add ?draw=singles.

    Returns:
        (matches, problem). Exactly one is meaningful: on success `problem` is
        None, otherwise `matches` is empty and `problem` is one short line to
        put on the display.
    """
    params = {
        "status": "live",
        "limit": str(PAGE_LIMIT),
    }

    if tour != ALL_TOURS:
        params["tour"] = tour

    if singles_only:
        # ?draw=singles. openapi.yaml is explicit that a row whose draw is null
        # - a team tie, or no stated event type - matches NEITHER value, so
        # this filter drops Davis Cup / BJK Cup rubbers as well as doubles.
        params["draw"] = "singles"

    response = http.get(
        url = MATCHES_URL,
        headers = {
            API_KEY_HEADER: api_key,
            "Accept": "application/json",
        },
        params = params,
        ttl_seconds = CACHE_SECONDS,
    )

    if response.status_code != 200:
        return ([], status_message(response))

    # Starlark has no exception handling and response.json() aborts the render
    # on a body that is not JSON - an ISP captive portal or a proxy error page
    # would take the app down. json.decode's second argument is the value
    # returned instead when decoding fails.
    body = json.decode(response.body(), None)

    if type(body) != "dict":
        return ([], "TENNIS API SENT A BAD REPLY")

    data = body.get("data")

    if type(data) != "list":
        return ([], "TENNIS API SENT A BAD REPLY")

    matches = []
    for match in data:
        if type(match) == "dict":
            matches.append(match)

    return (matches, None)

def status_message(response):
    """One readable line for a non-200 response."""
    code = response.status_code

    if code == 401:
        return "API KEY REJECTED - CHECK APP SETTINGS"

    if code == 403:
        # {"error": "upgrade_required"} - not expected on a FREE endpoint, but
        # a revoked or downgraded key can land here.
        return "THIS KEY CANNOT READ LIVE MATCHES"

    if code == 429:
        # Three shapes share this code (per-minute, per-day quota, and an abuse
        # block). The display cannot usefully tell them apart; the cure for all
        # three is to leave the refresh interval alone.
        return "RATE LIMITED - RAISE THE REFRESH INTERVAL"

    if code == 400:
        return "TENNIS API REFUSED THE REQUEST"

    if code >= 500:
        return "TENNIS API UNAVAILABLE (%d)" % code

    return "TENNIS API ERROR %d" % code

def rotation_offset(count):
    """First match of this cycle, so repeated refreshes walk the whole slate.

    Costs no extra requests: the window moves with the clock, not with a
    second call. The result is always a valid index - the largest offset is
    (windows - 1) * MATCHES_PER_RENDER, which is below `count` by the
    definition of windows - so render_slate always has at least one card.
    """
    if count <= MATCHES_PER_RENDER:
        return 0

    windows = (count + MATCHES_PER_RENDER - 1) // MATCHES_PER_RENDER
    cycle = int(time.now().unix) // CACHE_SECONDS

    return (cycle % windows) * MATCHES_PER_RENDER

def render_slate(matches, offset, footer_override, footer_color):
    """Rotates through up to MATCHES_PER_RENDER matches starting at offset."""
    frames = []

    for index in range(MATCHES_PER_RENDER):
        position = offset + index

        if position >= len(matches):
            break

        card = render_match(
            matches[position],
            position + 1,
            len(matches),
            footer_override,
            footer_color,
        )

        # Sequence advances one child per frame, so a card that should be held
        # for FRAMES_PER_MATCH frames is an Animation of that many copies.
        # Identical frames cost almost nothing in the encoded WebP.
        frames.append(render.Animation(children = [card for _ in range(FRAMES_PER_MATCH)]))

    return render.Root(
        delay = FRAME_DELAY_MS,
        max_age = MAX_AGE_SECONDS,
        show_full_animation = True,
        child = render.Sequence(children = frames),
    )

def render_match(match, position, total, footer_override, footer_color):
    """Draws one match on the 64x32 canvas."""
    players = match.get("players")

    if type(players) != "dict":
        players = {}

    score = match.get("score")

    if type(score) != "dict":
        # `score` is nullable on Match. A live row without one still deserves
        # the names.
        score = {}

    server = score.get("server")

    if server != 1 and server != 2:
        server = None

    is_tiebreak = score.get("is_tiebreak") == True
    break_point_for = break_point(score, server, is_tiebreak)

    badge, badge_color = TOUR_BADGES.get(match.get("tour"), DEFAULT_BADGE)

    if footer_override != None:
        footer = footer_override
    else:
        footer = "%s  %d/%d" % (round_label(match), position, total)

    return render.Box(
        width = 64,
        height = 32,
        color = BG,
        child = render.Padding(
            pad = (1, 0, 1, 0),
            child = render.Column(
                expanded = True,
                main_align = "space_between",
                children = [
                    render_header(badge, badge_color, match.get("tournament")),
                    render.Box(width = INNER_W, height = 1, color = DIVIDER),
                    render_player_row(players.get("p1"), score, 0, server, break_point_for),
                    render_player_row(players.get("p2"), score, 1, server, break_point_for),
                    render.Box(width = INNER_W, height = 1, color = DIVIDER),
                    render.Marquee(
                        width = INNER_W,
                        child = render.Text(content = footer, font = ROW_FONT, color = footer_color),
                    ),
                ],
            ),
        ),
    )

def render_header(badge, badge_color, tournament):
    name = tournament if type(tournament) == "string" and tournament != "" else "LIVE TENNIS"

    return render.Row(
        cross_align = "center",
        children = [
            # A fixed cell rather than a measured one: tom-thumb advances 4-6px
            # per glyph, so "WTA" is wider than three times anything and an
            # arithmetic guess would eat into the marquee.
            render.Box(
                width = BADGE_W,
                height = 6,
                child = render.Text(content = badge, font = HEAD_FONT, color = badge_color),
            ),
            render.Marquee(
                width = INNER_W - BADGE_W - 2,
                child = render.Text(content = name, font = HEAD_FONT, color = NAME_COLOR),
            ),
        ],
    )

def render_player_row(player, score, index, server, break_point_for):
    """One player's line: marker, surname, sets won, games, point."""
    name = surname(player.get("name") if type(player) == "dict" else None)

    return render.Row(
        cross_align = "center",
        children = [
            cell(MARKER_W, marker(index + 1, server, break_point_for)),
            left_cell(NAME_W, name, NAME_COLOR),
            cell(SETS_W, render.Text(
                content = number_text(score.get("sets"), index),
                font = ROW_FONT,
                color = SETS_COLOR,
            )),
            cell(GAMES_W, render.Text(
                content = current_games(score.get("games"), index),
                font = ROW_FONT,
                color = GAMES_COLOR,
            )),
            cell(POINTS_W, render.Text(
                content = point_text(score.get("points"), index),
                font = ROW_FONT,
                color = POINTS_COLOR,
            )),
        ],
    )

def marker(player_number, server, break_point_for):
    """A green ball for the server, a red bar for a player holding break point.

    The two can never collide on one row: break point belongs to the receiver.
    """
    if break_point_for == player_number:
        return render.Box(width = 2, height = 5, color = BREAK_COLOR)

    if server == player_number:
        return render.Circle(diameter = 3, color = SERVE_COLOR)

    # Transparent spacer: this row has neither the ball nor break point.
    return render.Box(width = 1, height = 1)

def break_point(score, server, is_tiebreak):
    """Which player, if either, is one point from breaking serve.

    The receiver holds break point when they are at advantage, or at 40 with
    the server behind - the server at 40 as well is deuce, not break point.
    A tiebreak has no break point: every point is a mini-break on one serve or
    the other, so the notion does not apply and the answer is None.

    Returns:
        1, 2, or None. None whenever the inputs do not prove a break point:
        no known server, a tiebreak, a missing points array, or a null entry
        in it - which openapi.yaml warns is observed live on completed matches.
    """

    # `server` is validated here and not only at the call site: this function
    # indexes the points array with it, so anything other than 1 or 2 has to
    # stop before the subscript rather than raise mid-render.
    if (server != 1 and server != 2) or is_tiebreak:
        return None

    points = score.get("points")

    if type(points) != "list" or len(points) < 2:
        return None

    receiver = 3 - server
    receiver_point = points[receiver - 1]
    server_point = points[server - 1]

    if type(receiver_point) != "string" or type(server_point) != "string":
        return None

    if receiver_point == "AD":
        return receiver

    if receiver_point == "40" and server_point in ("0", "15", "30"):
        return receiver

    return None

def current_games(games, index):
    """Games in the set being played, for one player.

    `games` is player-major: [[6, 3], [4, 4]] is 6-4 in the first set and 3-4
    in the second, so games[index] is this player's per-set list and its last
    entry is the current set. Completed matches are documented to carry an
    empty games array.
    """
    if type(games) != "list" or len(games) <= index:
        return "-"

    per_set = games[index]

    if type(per_set) != "list" or len(per_set) == 0:
        return "-"

    value = per_set[-1]

    if type(value) != "int":
        return "-"

    return str(value)

def number_text(values, index):
    """One entry of a plain integer array, or a dash."""
    if type(values) != "list" or len(values) <= index:
        return "-"

    value = values[index]

    if type(value) != "int":
        return "-"

    return str(value)

def point_text(points, index):
    """The in-game point.

    Tennis strings ("0", "15", "30", "40", "AD") outside a tiebreak and the
    running count ("0", "1", "2", ...) inside one. Entries can be null, so the
    type is checked rather than assumed.
    """
    if type(points) != "list" or len(points) <= index:
        return "-"

    value = points[index]

    if type(value) != "string" or value == "":
        return "-"

    return value

def round_label(match):
    code = match.get("round_code")

    if type(code) == "string" and code != "":
        return code

    name = match.get("round")

    if type(name) == "string" and name != "":
        return name.upper()

    return "LIVE"

def surname(name):
    """The name as it fits in NAME_CHARS of a 64px row.

    `players.p1.name` is a full name ("Chase Ferguson" in the API's own
    worked example), so the surname is the part worth the pixels.
    """
    if type(name) != "string":
        return "?"

    name = name.strip()

    if name == "":
        return "?"

    # A doubles team arrives as one string naming both players. Neither
    # surname fits whole, so both are kept and the cell clips them.
    if name.find("/") >= 0:
        sides = [one_surname(side) for side in name.split("/")]
        return truncate("/".join(sides))

    return truncate(one_surname(name))

def one_surname(name):
    parts = [part for part in name.strip().split(" ") if part != ""]

    if len(parts) == 0:
        return "?"

    last = parts[-1]

    # "Sabalenka A." puts the surname first and an initial last. A trailing
    # token of one letter is an initial, not a name.
    if len(last.replace(".", "")) <= 1 and len(parts) > 1:
        return parts[0]

    return last

def truncate(name):
    name = name.upper()

    if len(name) <= NAME_CHARS:
        return name

    return name[0:NAME_CHARS]

def cell(width, child):
    """Fixed-width column with its content centred."""
    return render.Box(width = width, height = 5, child = child)

def left_cell(width, text, color):
    """Fixed-width column with its text against the left edge.

    A Row with expanded = True fills the Box and leaves its single child at
    the start, which a Box alone would centre.
    """
    return render.Box(
        width = width,
        height = 5,
        child = render.Row(
            expanded = True,
            children = [render.Text(content = text, font = ROW_FONT, color = color)],
        ),
    )

def render_notice(message):
    """One short readable line, for every case with no scores to show."""
    return render.Root(
        delay = FRAME_DELAY_MS,
        max_age = MAX_AGE_SECONDS,
        child = render.Box(
            width = 64,
            height = 32,
            color = BG,
            child = render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text(content = "LIVE TENNIS", font = HEAD_FONT, color = SERVE_COLOR),
                    render.Box(width = 40, height = 2),
                    render.Marquee(
                        width = INNER_W,
                        align = "center",
                        child = render.Text(content = message, font = ROW_FONT, color = NAME_COLOR),
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "Live Tennis API key. The free tier needs no card and covers live matches on every tour: get one at https://livetennisapi.com",
                icon = "key",
                secret = True,
            ),
            schema.Dropdown(
                id = "tour",
                name = "Tour",
                desc = "Which circuit to follow. Challenger and ITF are the ones no other tennis app in this repo can reach.",
                icon = "trophy",
                default = TOUR_OPTIONS[0].value,
                options = TOUR_OPTIONS,
            ),
            schema.Toggle(
                id = "singles_only",
                name = "Singles only",
                desc = "Hide doubles. Also hides Davis Cup and BJK Cup rubbers, whose draw the API reports as unknown rather than guessing.",
                icon = "user",
                default = True,
            ),
        ],
    )
