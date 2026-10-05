"""
Applet: NFL Play By Play
Summary: Follow your NFL team live
Description: Live game state for your NFL team, in the spirit of Tidbyt's original first-party Football app.
Author: nsluke

Four states, matching the original:
  idle    - logo, record, and a team-color marquee scrolling division standings
  pregame - kickoff time beside side-by-side team panels (game day only)
  live    - quarter, clock, down & distance, field position, possession,
            timeouts, score on team-color bands
  final   - FIN beside the score bands

Data: ESPN's public scoreboard + standings JSON (no key). Everything the live
view needs is on the scoreboard's competitions[0].situation. Field notes:
situation is absent on pre/post games; mid-stoppage it can be degenerate
(down -1, possession null, stale isRedZone) - treat that as "no active down".
possession is a team ID, not an abbreviation. team.color has no '#'.
period 5+ is OT. state stays "in" at halftime (status.type.name says HALFTIME).
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

API_BASE = "https://site.api.espn.com"
SCOREBOARD_PATH = "/apis/site/v2/sports/football/nfl/scoreboard"
STANDINGS_PATH = "/apis/v2/sports/football/nfl/standings?level=3"

FRESH_LIVE = 10  # live game: re-poll every 10s (ESPN serves max-age=2; a play cycle is ~40s)
FRESH_IDLE = 600  # no live game: every 10 min
RETRY_TTL = 60  # back off after a failure
STALE_TTL = 21600  # serve last good extract up to 6h through an outage
STANDINGS_TTL = 3600
LOGO_TTL = 86400

WHITE = "#FFFFFF"
GREY = "#9C9C9C"
DARKGREY = "#4A4A4A"
AMBER = "#FFA33A"
RED = "#FF3B30"

TEAMS = {
    "ARI": "Arizona Cardinals",
    "ATL": "Atlanta Falcons",
    "BAL": "Baltimore Ravens",
    "BUF": "Buffalo Bills",
    "CAR": "Carolina Panthers",
    "CHI": "Chicago Bears",
    "CIN": "Cincinnati Bengals",
    "CLE": "Cleveland Browns",
    "DAL": "Dallas Cowboys",
    "DEN": "Denver Broncos",
    "DET": "Detroit Lions",
    "GB": "Green Bay Packers",
    "HOU": "Houston Texans",
    "IND": "Indianapolis Colts",
    "JAX": "Jacksonville Jaguars",
    "KC": "Kansas City Chiefs",
    "LAC": "Los Angeles Chargers",
    "LAR": "Los Angeles Rams",
    "LV": "Las Vegas Raiders",
    "MIA": "Miami Dolphins",
    "MIN": "Minnesota Vikings",
    "NE": "New England Patriots",
    "NO": "New Orleans Saints",
    "NYG": "New York Giants",
    "NYJ": "New York Jets",
    "PHI": "Philadelphia Eagles",
    "PIT": "Pittsburgh Steelers",
    "SEA": "Seattle Seahawks",
    "SF": "San Francisco 49ers",
    "TB": "Tampa Bay Buccaneers",
    "TEN": "Tennessee Titans",
    "WSH": "Washington Commanders",
}

# Teams whose ESPN primary color is too dark/illegible on the panel
# (convention borrowed from the community nflscores app).
ALT_COLOR = {
    "LAC": "#1281c4",
    "LAR": "#003594",
    "MIA": "#008E97",
    "NO": "#1a1a1a",
    "SEA": "#002244",
    "TB": "#34302B",
    "TEN": "#0C2340",
}

def main(config):
    team = config.str("team", "PHI")
    tz = config.get("$tz") or "America/New_York"
    base = config.str("api", API_BASE)  # test hook: point at a local stub

    game = get_game(team, base)
    now = time.now().in_location(tz)

    if game != None:
        kick = time.parse_time(game["date"], format = "2006-01-02T15:04Z").in_location(tz)
        if game["state"] == "in":
            return render.Root(child = live_view(game, final = False))
        if game["state"] == "post" and game["status_name"] == "STATUS_FINAL":
            # Genuinely final (postponed/canceled also report state "post" —
            # those fall through to idle rather than faking a 0-0 FIN).
            # Show the final for a day, then fall back to idle.
            if now - kick < time.parse_duration("24h"):
                return render.Root(child = live_view(game, final = True))
        if game["state"] == "pre" and same_day(kick, now):
            return pregame_root(game, team, kick, base)

    if config.bool("gameday_only", False):
        return []
    return idle_root(team, base)

def same_day(a, b):
    return a.format("2006-01-02") == b.format("2006-01-02")

# ---------------------------------------------------------------- data layer

def fetch_json(url, gate_key, fresh_ttl):
    """Gate-before-request: a transport error aborts the render and Starlark
    cannot catch it, so the gate key (written before the request) limits the
    damage to one failed render per RETRY_TTL."""
    if cache.get(gate_key) != None:
        return None  # recently fetched or recently failed; caller uses cache
    cache.set(gate_key, "1", ttl_seconds = RETRY_TTL)
    resp = http.get(url, ttl_seconds = RETRY_TTL)
    body = resp.body()
    if resp.status_code != 200:
        print("pbp: " + url[:60] + " -> " + str(resp.status_code))
        return None
    if not (body.startswith("{") and body.endswith("}")):
        print("pbp: non-JSON body from " + url[:60])
        return None
    cache.set(gate_key, "1", ttl_seconds = fresh_ttl)
    return json.decode(body)

def get_game(team, base):
    """Extract the focus team's event from the scoreboard into a small dict,
    cached so an ESPN outage serves the last good reading."""
    ck = "pbp:g:" + team
    d = fetch_json(base + SCOREBOARD_PATH, ck + ":gate", FRESH_LIVE)
    if d == None:
        raw = cache.get(ck)
        if raw == None:
            return None
        g = json.decode(raw)
        return None if "none" in g else g  # no-game marker, not a game

    game = None
    for ev in d.get("events", []):
        comp = ev.get("competitions", [{}])[0]
        sides = comp.get("competitors", [])
        if len(sides) != 2:
            continue
        if team in [s.get("team", {}).get("abbreviation", "") for s in sides]:
            game = extract_game(ev, comp, sides)
            break

    if game == None:
        cache.set(ck, json.encode({"none": True}), ttl_seconds = STALE_TTL)
        cache.set(ck + ":gate", "1", ttl_seconds = FRESH_IDLE)  # bye week: poll slowly
        return None
    cache.set(ck, json.encode(game), ttl_seconds = STALE_TTL)

    # Poll slowly when nothing is live.
    if game["state"] != "in":
        cache.set(ck + ":gate", "1", ttl_seconds = FRESH_IDLE)
    return game

def extract_game(ev, comp, sides):
    status = ev.get("status", {})
    stype = status.get("type", {})
    away, home = None, None
    for s in sides:
        if s.get("homeAway") == "home":
            home = s
        else:
            away = s
    if home == None or away == None:
        away, home = sides[0], sides[1]

    game = {
        "state": stype.get("state", "pre"),
        "status_name": stype.get("name", ""),
        "detail": stype.get("shortDetail", ""),
        "period": int(status.get("period", 0)),
        "clock": status.get("displayClock", ""),
        "date": ev.get("date", ""),
        "away": extract_team(away),
        "home": extract_team(home),
    }

    sit = comp.get("situation", None)
    if sit != None and game["state"] == "in":
        down = int(sit.get("down", -1) or -1)
        poss = sit.get("possession", None)
        game["sit"] = {
            "down_text": sit.get("shortDownDistanceText", "") or "",
            "spot": sit.get("possessionText", "") or "",
            "red": bool(sit.get("isRedZone", False)) and down >= 1,
            "poss": poss if poss else "",
            "hto": int(sit.get("homeTimeouts", 3)),
            "ato": int(sit.get("awayTimeouts", 3)),
            "valid": down >= 1 and poss != None and poss != "",
        }
    return game

def extract_team(side):
    t = side.get("team", {})
    abbr = t.get("abbreviation", "?")
    return {
        "id": str(t.get("id", "")),
        "abbr": abbr,
        "score": side.get("score", "0"),
        "color": team_color(abbr, t.get("color", "222222")),
        "alt": "#" + t.get("alternateColor", "ffffff"),
        "logo": t.get("logo", ""),
    }

def team_color(abbr, hex):
    if abbr in ALT_COLOR:
        return ALT_COLOR[abbr]
    c = "#" + hex
    if c.lower() in ("#ffffff", "#000000"):
        return "#222222"
    return c

def get_standings(team, base):
    """Division entry list for the focus team + its record, small-cached."""
    ck = "pbp:s:" + team
    d = fetch_json(base + STANDINGS_PATH, ck + ":gate", STANDINGS_TTL)
    if d == None:
        raw = cache.get(ck)
        return json.decode(raw) if raw != None else None

    out = None
    for conf in d.get("children", []):
        for div in conf.get("children", []):
            entries = div.get("standings", {}).get("entries", [])
            abbrs = [e.get("team", {}).get("abbreviation", "") for e in entries]
            if team not in abbrs:
                continue
            lines = []
            record = ""
            for i, e in enumerate(entries):
                a = e.get("team", {}).get("abbreviation", "?")
                lines.append(str(i + 1) + ":" + a)
                if a == team:
                    for st in e.get("stats", []):
                        if st.get("name") == "overall":
                            record = st.get("displayValue", "")
            out = {"marquee": "  ".join(lines), "record": record, "div": div.get("abbreviation", div.get("name", ""))}
    if out != None:
        cache.set(ck, json.encode(out), ttl_seconds = STALE_TTL)
    return out

def get_logo(url, abbr):
    """Logo bytes via ESPN's combiner (server-side resize keeps it crisp),
    kept in cache.star so a CDN outage can't abort renders: the un-gated
    http.get path only runs when we have no cached copy AND no recent
    failure. Returns None on failure - callers draw a colored box."""
    ck = "pbp:l:" + abbr
    cached = cache.get(ck)
    if cached != None:
        return base64.decode(cached)
    if cache.get(ck + ":gate") != None:
        return None  # recent failure; don't risk an aborting fetch every render
    cache.set(ck + ":gate", "1", ttl_seconds = RETRY_TTL)

    if url == "":
        url = "https://a.espncdn.com/i/teamlogos/nfl/500/scoreboard/" + abbr.lower() + ".png"
    dark = url.replace("/500/scoreboard", "/500-dark/scoreboard").replace("a.espncdn.com/", "a.espncdn.com/combiner/i?img=/")
    dark = dark.replace("/combiner/i?img=/i/", "/combiner/i?img=/i/") + "&h=50&w=50"
    resp = http.get(dark, ttl_seconds = LOGO_TTL)
    if resp.status_code != 200 or len(resp.body()) < 100:
        print("pbp: logo fetch failed for " + abbr)
        return None
    cache.set(ck, base64.encode(resp.body()), ttl_seconds = LOGO_TTL * 7)
    return resp.body()

# ------------------------------------------------------------------ helpers

def luminance(color):
    c = color.lstrip("#")
    if len(c) < 6:
        return 0
    v = [hex_byte(c[0:2]), hex_byte(c[2:4]), hex_byte(c[4:6])]
    return (299 * v[0] + 587 * v[1] + 114 * v[2]) // 1000

def hex_byte(s):
    digits = "0123456789abcdef"
    s = s.lower()
    if len(s) != 2 or digits.find(s[0]) < 0 or digits.find(s[1]) < 0:
        return 0
    return digits.find(s[0]) * 16 + digits.find(s[1])

def text_on(bg):
    return "#111111" if luminance(bg) > 150 else WHITE

def accent_on(bg, accent):
    """Team accent color for the abbreviation, unless it vanishes on the band."""
    diff = luminance(accent) - luminance(bg)
    if diff < 0:
        diff = -diff
    if diff < 60:
        return text_on(bg)
    return accent

def quarter_label(game):
    name = game["status_name"]
    p = game["period"]
    if name == "STATUS_HALFTIME":
        return "HALF"
    if p == 1:
        return "1st"
    if p == 2:
        return "2nd"
    if p == 3:
        return "3rd"
    if p == 4:
        return "4th"
    if p == 5:
        return "OT"
    if p > 5:
        return str(p - 4) + "OT"
    return ""

def logo_cell(team, size):
    body = get_logo(team["logo"], team["abbr"])
    if body != None:
        return render.Box(width = size, height = size, child = render.Image(src = body, width = size, height = size))
    return render.Box(
        width = size,
        height = size,
        color = team["color"],
        child = render.Text(team["abbr"][0:1], font = "tom-thumb", color = text_on(team["color"])),
    )

# ------------------------------------------------------------------- states

def live_view(game, final):
    sit = game.get("sit", None)
    left = []
    if final:
        fin = "FIN"
        if game["period"] > 4:
            fin = "F/OT"
        left = [
            render.Text(fin, font = "tb-8", color = WHITE),
        ]
    elif game["status_name"] == "STATUS_HALFTIME":
        left = [render.Text("HALF", font = "tb-8", color = WHITE)]
    else:
        left = [
            render.Text(quarter_label(game), font = "tom-thumb", color = GREY),
            render.Text(game["clock"], font = "tb-8", color = WHITE),
        ]
        if sit != None and sit["valid"]:
            spot_color = RED if sit["red"] else AMBER
            left.append(render.Box(width = 27, height = 2))
            left.append(render.Text(compact_down(sit["down_text"]), font = "tom-thumb", color = WHITE))
            left.append(render.Text(sit["spot"], font = "tom-thumb", color = spot_color))

    return render.Row(
        children = [
            render.Box(
                width = 27,
                height = 32,
                child = render.Column(
                    main_align = "center",
                    cross_align = "center",
                    children = left,
                ),
            ),
            render.Box(width = 1, height = 32, color = DARKGREY),
            render.Column(
                children = [
                    band(game["away"], game, sit, is_home = False),
                    band(game["home"], game, sit, is_home = True),
                ],
            ),
        ],
    )

def compact_down(text):
    # "1st & 10" -> "1st&10", "3rd & Goal" -> "3rd&GL": 6 tom-thumb chars
    # is the most the 27px column fits, so hard-cap it.
    t = text.replace(" & ", "&").replace("Goal", "GL")
    return t[0:6]

def band(team, game, sit, is_home):
    bg = team["color"]
    has_ball = sit != None and sit["valid"] and sit["poss"] == team["id"]
    touts = -1
    if sit != None and game["state"] == "in":
        touts = sit["hto"] if is_home else sit["ato"]

    name_row = [render.Text(team["abbr"], font = "tom-thumb", color = accent_on(bg, team["alt"]))]
    if has_ball:
        ball_color = RED if sit["red"] else AMBER
        name_row.append(render.Box(width = 1, height = 1))
        name_row.append(render.Box(width = 3, height = 3, color = ball_color))

    pips = []
    if touts >= 0:
        for i in range(3):
            pips.append(render.Box(width = 1, height = 2, color = WHITE if i < touts else "#333333"))
            if i < 2:
                pips.append(render.Box(width = 1, height = 1))

    return render.Stack(
        children = [
            render.Box(width = 36, height = 16, color = bg),
            render.Padding(
                pad = (1, 1, 0, 0),
                child = render.Row(
                    children = [
                        logo_cell(team, 14),
                        render.Padding(
                            pad = (2, 0, 0, 0),
                            child = render.Column(
                                children = [
                                    render.Row(cross_align = "center", children = name_row),
                                    render.Text(str(team["score"]), font = "tb-8", color = WHITE),
                                ],
                            ),
                        ),
                    ],
                ),
            ),
            render.Padding(
                pad = (34, 4, 0, 0),
                child = render.Column(children = pips),
            ),
        ],
    )

def pregame_root(game, team, kick, base):
    st = get_standings(team, base)
    away, home = game["away"], game["home"]
    panels = render.Row(
        children = [
            pre_panel(away),
            pre_panel(home),
        ],
    )
    left = render.Box(
        width = 27,
        height = 25,
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text("START", font = "tom-thumb", color = GREY),
                render.Text(kick.format("3:04"), font = "tb-8", color = WHITE),
            ],
        ),
    )
    focus = game["home"] if game["home"]["abbr"] == team else game["away"]
    body = render.Column(
        children = [
            render.Row(children = [left, render.Box(width = 1, height = 25, color = DARKGREY), panels]),
            marquee_strip(st, focus["color"]),
        ],
    )
    return render.Root(child = body, show_full_animation = True)

def pre_panel(team):
    return render.Box(
        width = 18,
        height = 25,
        color = team["color"],
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                logo_cell(team, 14),
                render.Text(team["abbr"], font = "tom-thumb", color = text_on(team["color"])),
            ],
        ),
    )

def idle_root(team, base):
    st = get_standings(team, base)
    color = "#222222"
    logo_url = "https://a.espncdn.com/i/teamlogos/nfl/500/scoreboard/" + team.lower() + ".png"
    fake = {"abbr": team, "color": color, "alt": WHITE, "logo": logo_url, "id": "", "score": ""}
    record = st["record"] if st != None else ""
    body = render.Column(
        children = [
            render.Box(
                width = 64,
                height = 25,
                child = render.Row(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        logo_cell(fake, 22),
                        render.Box(width = 4, height = 1),
                        render.Column(
                            cross_align = "center",
                            children = [
                                render.Text(team, font = "tb-8", color = GREY),
                                render.Text(record, font = "tom-thumb", color = WHITE),
                            ],
                        ),
                    ],
                ),
            ),
            marquee_strip(st, team_idle_color(team, base)),
        ],
    )
    return render.Root(child = body, show_full_animation = True)

def team_idle_color(team, base):
    """Focus team's primary color for the marquee strip when the team isn't
    on the scoreboard (idle days). One tiny fetch, cached a week."""
    ck = "pbp:c:" + team
    cached = cache.get(ck)
    if cached != None:
        return cached
    color = ALT_COLOR.get(team, "#333333")
    d = fetch_json(base + "/apis/site/v2/sports/football/nfl/teams/" + team, ck + ":gate", LOGO_TTL)
    if d != None:
        color = team_color(team, d.get("team", {}).get("color", "333333"))

        # Only cache what we actually fetched - a failure must not pin the
        # grey fallback for a week (fetch_json's gate handles retry pacing).
        cache.set(ck, color, ttl_seconds = LOGO_TTL * 7)
    return color

def marquee_strip(st, color):
    if st == None or st.get("marquee", "") == "":
        return render.Box(width = 64, height = 7, color = "#111111")
    return render.Box(
        width = 64,
        height = 7,
        color = color,
        child = render.Marquee(
            width = 64,
            child = render.Text(" " + st["marquee"], font = "tom-thumb", color = text_on(color)),
        ),
    )

# -------------------------------------------------------------------- schema

def get_schema():
    options = [schema.Option(display = TEAMS[a], value = a) for a in sorted(TEAMS.keys())]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "team",
                name = "Team",
                desc = "The team to follow.",
                icon = "football",
                default = "PHI",
                options = options,
            ),
            schema.Toggle(
                id = "gameday_only",
                name = "Game day only",
                desc = "Hide the app entirely on days your team doesn't play.",
                icon = "calendarDay",
                default = False,
            ),
        ],
    )
