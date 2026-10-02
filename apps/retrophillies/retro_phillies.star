"""Alternate MLB: live pitch and play animation. Local beta, separate from original scoreboard."""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

FONT = {"A": ["010", "101", "111", "101", "101"], "B": ["110", "101", "110", "101", "110"], "C": ["011", "100", "100", "100", "011"], "D": ["110", "101", "101", "101", "110"], "E": ["111", "100", "110", "100", "111"], "F": ["111", "100", "110", "100", "100"], "G": ["011", "100", "101", "101", "011"], "H": ["101", "101", "111", "101", "101"], "I": ["111", "010", "010", "010", "111"], "K": ["101", "101", "110", "101", "101"], "L": ["100", "100", "100", "100", "111"], "N": ["101", "111", "111", "111", "101"], "O": ["010", "101", "101", "101", "010"], "P": ["110", "101", "110", "100", "100"], "R": ["110", "101", "110", "101", "101"], "S": ["011", "100", "010", "001", "110"], "T": ["111", "010", "010", "010", "010"], "U": ["101", "101", "101", "101", "111"], "V": ["101", "101", "101", "101", "010"], "W": ["101", "101", "111", "111", "101"], "X": ["101", "101", "010", "101", "101"], "Y": ["101", "101", "010", "010", "010"], "0": ["111", "101", "101", "101", "111"], "1": ["010", "110", "010", "010", "111"], "2": ["110", "001", "010", "100", "111"], "3": ["110", "001", "010", "001", "110"], "4": ["101", "101", "111", "001", "001"], "5": ["111", "100", "110", "001", "110"], "6": ["011", "100", "111", "101", "111"], "7": ["111", "001", "010", "010", "010"], "8": ["111", "101", "111", "101", "111"], "9": ["111", "101", "111", "001", "110"], "-": ["000", "000", "111", "000", "000"], ":": ["000", "010", "000", "010", "000"], ">": ["100", "010", "001", "010", "100"], "M": ["101", "111", "111", "101", "101"], "J": ["011", "001", "001", "101", "010"], "Q": ["010", "101", "101", "111", "011"], "?": ["110", "001", "010", "000", "010"], "/": ["001", "001", "010", "100", "100"]}
FONT["Z"] = ["111", "001", "010", "100", "111"]
INK = "#101a19"
WHITE = "#f8efda"
GRAY = "#a9b5ac"
GOLD = "#ffcf55"
GRASS = "#327645"
DIRT = "#ad7845"
LINE = "#dbd4a4"
PLAYER = ["..rrr...", "..rss...", "...s....", "..www...", ".wwgw...", "..www...", "...rw...", "..www...", "..ww.w..", ".ww..w..", ".kk..kk."]
VICTORY = ["..rrr.s.", "..rss.s.", "...s.ww.", "..wwww..", ".wwgw...", "..www...", "...rw...", "..www...", "..ww.w..", ".ww..w..", ".kk..kk."]
BATTER = ["......tt..", "......t...", "..rrr.t...", ".rrrrrt...", "..ssd.t...", "..ss.wss..", "...wwwss..", "..wwwww...", "..wgwww...", "...rwr....", "...www....", "..ww.ww...", "..wg..w...", ".ww...ww..", ".kk...kk.."]
SWING = ["..........", "..........", "..rrr.....", ".rrrrr....", "..ssd.....", "..ss......", "...wwssstt", "..wwww....", "..wgwww...", "...rwr....", "...www....", "..ww.ww...", "..wg..w...", ".ww...ww..", ".kk...kk.."]

def num(v):
    return str(int(v)) if type(v) in ["int", "float"] else str(v)

def color(team):
    return {"PHI": "#d93a47", "ATL": "#203e62", "BOS": "#BD3039", "DET": "#182d49", "NYM": "#2853a0", "LAD": "#245aaa", "NYY": "#243345"}.get(team, "#335981")

def pixel(c, x, y, col):
    x = int(x)
    y = int(y)
    if x >= 0 and x < 64 and y >= 0 and y < 32:
        c[y][x] = col

def box(c, x, y, w, h, col):
    for j in range(int(y), int(y + h)):
        for i in range(int(x), int(x + w)):
            pixel(c, i, j, col)

def line(c, x, y, xx, yy, col):
    n = max(abs(int(xx - x)), abs(int(yy - y)), 1)
    for i in range(n + 1):
        pixel(c, x + (xx - x) * i / n, y + (yy - y) * i / n, col)

def text(c, s, x, y, col = WHITE, clip = None):
    for i, ch in enumerate(str(s).upper().elems()):
        for j, row in enumerate(FONT.get(ch, [])):
            for k, p in enumerate(row.elems()):
                if p == "1" and (clip == None or (x + i * 4 + k >= clip[0] and x + i * 4 + k < clip[1])):
                    pixel(c, x + i * 4 + k, y + j, col)

def centered(c, s, y, col = WHITE):
    text(c, s, (64 - (len(s) * 4 - 1)) // 2, y, col)

def fitted(c, s, x, y, width, t, col = WHITE):
    length = len(s) * 4 - 1
    overflow = max(0, length - width)
    offset = int(overflow * min(1, max(0, (t - 0.35) / 2.0)))
    text(c, s, x - offset, y, col, [x, x + width])

def surname(c, s, t):
    width = len(s) * 4 - 1
    if width <= 41:
        text(c, s, 58 - width, 27, WHITE)
    else:
        fitted(c, s, 17, 27, 41, t)

def sprite(c, rows, x, y, team, mirror = False):
    pal = {"r": color(team), "w": WHITE, "g": "#bbc4b0", "s": "#d8a06e", "d": "#925d42", "k": INK, "b": "#203e62", "t": "#deb775"}
    for j, row in enumerate(rows):
        for i, ch in enumerate(row.elems()):
            if ch in pal:
                pixel(c, x + (len(row) - 1 - i if mirror else i), y + j, pal[ch])

def diamond(c, x, y, r, fill, col):
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if abs(dx) + abs(dy) <= r:
                pixel(c, x + dx, y + dy, col if fill or abs(dx) + abs(dy) == r else INK)

def bases(c, x, y, r, occupied, small = False):
    for a, b in [([x, y + r], [x + r, y]), ([x + r, y], [x, y - r]), ([x, y - r], [x - r, y]), ([x - r, y], [x, y + r])]:
        line(c, a[0], a[1], b[0], b[1], "#55695d")
    for i, p in enumerate([[x + r, y], [x, y - r], [x - r, y]]):
        diamond(c, p[0], p[1], 1 if small else 2, i + 1 in occupied, GOLD if i + 1 in occupied else GRAY)
    pixel(c, x, y + r, WHITE)

def park(c):
    box(c, 0, 0, 64, 32, GRASS)
    box(c, 0, 7, 64, 4, "#233d4d")
    for i in range(0, 64, 3):
        pixel(c, i, 8, "#d8a06e" if i % 2 else GRAY)
    box(c, 0, 11, 64, 2, "#668ba0")

def field_background(c):
    park(c)
    for y in range(10, 32):
        r = int(17 * (1 - abs(y - 23) / 8))
        if r > 0:
            box(c, 31 - r, y, r * 2, 1, DIRT)
    for y in range(18, 29):
        r = int(10 * (1 - abs(y - 23) / 5))
        if r > 0:
            box(c, 31 - r, y, r * 2, 1, GRASS)
    line(c, 31, 31, 4, 18, LINE)
    line(c, 31, 31, 59, 18, LINE)

def header(c, s):
    box(c, 0, 0, 64, 7, INK)
    score = s.get("away", "?") + " " + num(s.get("awayScore", 0)) + " " + s.get("home", "?") + " " + num(s.get("homeScore", 0))
    inning = ("T" if s.get("top", True) else "B") + num(s.get("inning", 1))
    ix = 61 - len(inning) * 4
    if len(score) * 4 > ix - 2:
        score = s.get("away", "?") + num(s.get("awayScore", 0)) + " " + s.get("home", "?") + num(s.get("homeScore", 0))
    text(c, score, 1, 1, WHITE, [0, ix - 1])
    text(c, inning, ix, 1, GOLD)

def footer(c, s, t, result = ""):
    box(c, 0, 26, 64, 6, INK)
    text(c, num(s.get("balls", 0)) + "-" + num(s.get("strikes", 0)), 2, 27)
    if result:
        text(c, result, 39, 27, GOLD, [38, 64])
    elif s.get("outs", 0) >= 3:
        text(c, "3 OUT", 39, 27, GOLD)
    elif t % 10 < 4.8:
        text(c, num(s.get("outs", 0)) + " OUT", 39, 27, GOLD)
    elif t % 10 >= 5 and t % 10 < 9.8:
        surname(c, s.get("batter", "?"), t % 10 - 5)

def batter_scene(c, s, t, chart = False, ep = None):
    park(c)
    for y in range(13, 26):
        box(c, 15 - (y - 13) // 3, y, 18 + (y - 13) // 2, 1, DIRT)
    line(c, 12, 25, 34, 25, LINE)
    header(c, s)
    swing = chart and ep != None and ep.get("swing", False) and t >= 2.35 and t < 2.8
    rows = SWING if swing else BATTER
    mirror = s.get("batSide") == "L"
    dip = 0 if chart else (1 if t % 1.4 > 0.65 and t % 1.4 < 1 else 0)
    sprite(c, rows[:11], 17, 11 + dip, s.get("batTeam", "PHI"), mirror)
    sprite(c, rows[11:], 17, 22, s.get("batTeam", "PHI"), mirror)
    box(c, 34, 7, 30, 19, INK)
    if chart:
        box(c, 41, 11, 11, 13, GRAY)
        box(c, 42, 12, 9, 11, "#29453d")
        for x in [45, 48]:
            line(c, x, 12, x, 22, "#3c5d4c")
        for y in [15, 19]:
            line(c, 42, y, 50, y, "#3c5d4c")
        for p in ep.get("markers", []):
            box(c, p[0], p[1], 2, 2, "#697a65")
        p = ep.get("marker")
        if p != None and t >= 1.6:
            f = min(1, (t - 1.6) / 0.75)
            col = WHITE if t < 2.35 else ("#74dba0" if ep.get("call") == "BALL" else GOLD)
            box(c, 57 + (p[0] - 57) * f, 8 + (p[1] - 8) * f, 2, 2, col)
        box(c, 1, 12, 13, 13, INK)
        bases(c, 7, 18, 4, s.get("bases", []), True)
    else:
        bases(c, 48, 16, 6, s.get("bases", []))
    footer(c, s, t + s.get("uiTime", 0), ep.get("call", "").replace("IN PLAY", "INPLAY") if chart and t >= 2.35 else "")

def pregame(c, s, t):
    field_background(c)
    box(c, 0, 0, 31, 7, color(s.get("away")))
    box(c, 31, 0, 33, 7, color(s.get("home")))
    text(c, s.get("away", "?"), 9, 1)
    text(c, s.get("home", "?"), 42, 1)
    box(c, 30, 7, 1, 19, WHITE)
    box(c, 31, 7, 33, 19, INK)
    text(c, "START", 38, 10, GRAY)
    text(c, s.get("start", "TBD"), max(32, 47 - len(s.get("start", "TBD")) * 2), 18)
    sprite(c, PLAYER, 11, 14, s.get("away", "PHI"))
    wind = t % 3 < 0.9
    line(c, 15, 17, 19 if wind else 18, 14 if wind else 19, "#d8a06e")
    box(c, 19 if wind else 18, 13 if wind else 18, 2, 2, "#72502e")
    box(c, 0, 26, 64, 6, INK)
    centered(c, s.get("seriesLabel", "PREGAME") if t % 8 < 4 else s.get("gameLabel", s.get("day", "")), 27, GOLD)

def final(c, s, t):
    field_background(c)
    box(c, 0, 0, 64, 7, INK)
    centered(c, "FINAL", 1, GOLD)
    box(c, 0, 7, 33, 19, INK)
    box(c, 33, 7, 1, 19, WHITE)
    for side, y in [("away", 10), ("home", 19)]:
        box(c, 0, y, 1, 5, color(s.get(side)))
        text(c, s.get(side, "?"), 2, y)
        text(c, num(s.get(side + "Score", 0)), 21, y, GOLD if s.get(side + "Score", 0) == max(s.get("awayScore", 0), s.get("homeScore", 0)) else WHITE)
    winner = s.get("away") if s.get("awayScore", 0) > s.get("homeScore", 0) else s.get("home")
    phase = t % 3
    air = phase >= 0.45 and phase < 1.35
    lift = 2 if phase >= 0.65 and phase < 1.15 else (1 if air else 0)
    sprite(c, VICTORY if air else PLAYER, 45, 13 - lift, winner)
    box(c, 0, 26, 64, 6, INK)
    centered(c, s.get("seriesResult", winner + " WINS"), 27, GOLD)

def field(c, s, ep, t):
    box(c, 0, 0, 64, 32, "#4c9251")
    for y in range(10, 29):
        r = int(14 * (1 - abs(y - 19) / 9))
        if r > 0:
            box(c, 31 - r, y, r * 2 + 1, 1, DIRT)
    line(c, 31, 25, 2, 9, LINE)
    line(c, 31, 25, 60, 9, LINE)
    points = [[31, 25], [45, 18], [31, 10], [17, 18], [31, 25]]
    for p in points:
        box(c, p[0], p[1], 2, 1, WHITE)
    defense = color(s.get("home") if s.get("top", True) else s.get("away"))
    for x, y in [[12, 12], [35, 8], [52, 12], [22, 17], [40, 15], [31, 19]]:
        box(c, x, y, 2, 1, defense)
        pixel(c, x, y + 1, "#d8a06e")
        box(c, x, y + 2, 2, 1, defense)
        pixel(c, x, y + 3, WHITE)
    hit = ep.get("hit", {})
    location = num(hit.get("location", ""))
    endpoint = {"7": [12, 12], "8": [31, 9], "9": [52, 12], "6": [22, 17], "4": [40, 15], "3": [45, 18], "5": [17, 18], "1": [31, 19], "2": [31, 27]}.get(location)
    if endpoint != None and t < 3:
        f = min(1, t / 2.4)
        arc = 0 if hit.get("trajectory") in ["ground_ball", "bunt_grounder"] else int(4 * (1 - abs(2 * f - 1)))
        pixel(c, 31 + (endpoint[0] - 31) * f, 25 + (endpoint[1] - 25) * f - arc, WHITE)
    moving = [move[0] for move in ep.get("runners", [])]
    for base in ep.get("beforeBases", []):
        if base not in moving:
            p = points[base]
            box(c, p[0], p[1] - 2, 2, 2, color(s.get("batTeam")))
    for move in ep.get("runners", []):
        progress = move[0] + (move[1] - move[0]) * min(1, t / 5)
        segment = min(3, int(progress))
        f = progress - segment
        a = points[segment]
        b = points[segment + 1]
        x = a[0] + (b[0] - a[0]) * f
        y = a[1] + (b[1] - a[1]) * f
        box(c, x, y - 2, 2, 2, color(s.get("batTeam")))
        pixel(c, x, y, WHITE)
    header(c, s)
    if t > 3:
        box(c, 0, 26, 64, 6, INK)
        label = ep.get("outcome", "IN PLAY")
        fitted(c, label, 2, 27, 60, t - 3, GOLD)

PHANATIC = ["......rrr...........", ".....rrrrrr.........", "...gggbbbo..........", "..fgggwwwgg......d..", "..gggbwwkggggggggd..", ".fgggggwwggggggggd..", "..gggggggggggggggd..", "..fggggggggg........", "...gwwwwwwwgg.......", "..ggwwrrwwwwgg......", "..ggwwrwrwwwgg......", "...gwwrrwwwwg.......", "....gggggggg........", "...fggggggggg.......", "....gggggggg........", ".....gg..gg........."]
MASCOT_COLORS = {"g": "#7bc63b", "f": "#589934", "d": "#347331", "l": "#b4de59", "r": "#d83f47", "w": "#fff2dc", "k": "#101a19", "b": "#69bfe0", "o": "#dc854e"}

def mascot(c, a, b, t, moving):
    a = int(a)
    b = int(b)
    step = int(t * 6) % 2 if moving else 0
    line(c, a + 4, b + 13, a - 2, b + 13 + step, MASCOT_COLORS["d"])
    line(c, a - 2, b + 13 + step, a - 4, b + 10, MASCOT_COLORS["g"])
    line(c, a - 3, b + 12, a - 4, b + 10, MASCOT_COLORS["b"])
    for j, row in enumerate(PHANATIC):
        for i, ch in enumerate(row.elems()):
            if ch in MASCOT_COLORS:
                pixel(c, a + i, b + j, MASCOT_COLORS[ch])
    left = 3 if moving and step else 4
    right = 9 if moving and step else 8
    box(c, a + left, b + 16, 3, 2, MASCOT_COLORS["g"])
    box(c, a + right, b + 16 - (1 if moving and step else 0), 3, 2, MASCOT_COLORS["f"])
    box(c, a + left - 1, b + 18, 5, 1, MASCOT_COLORS["d"])
    box(c, a + right, b + 18 - (1 if moving and step else 0), 5, 1, MASCOT_COLORS["d"])

def inning_break(c, s, t):
    box(c, 0, 8, 64, 24, "#254631")
    box(c, 0, 8, 64, 3, "#263d48")
    for i in range(1, 64, 4):
        pixel(c, i, 9, "#688077")
    box(c, 0, 30, 64, 2, "#6a8b43")
    header(c, s)
    q = t % 10

    # Identical, still beginning/end poses absorb app-refresh timing jitter.
    if q < 3:
        shift = 0
    elif q < 4.5:
        shift = int((q - 3) * 60 + 0.5)
    elif q < 5.5:
        shift = -70
    elif q < 7:
        shift = int(-70 * (1 - (q - 5.5) / 1.5) + 0.5)
    else:
        shift = 0
    moving = (q >= 3 and q < 4.5) or (q >= 5.5 and q < 7)
    a = 42 + shift
    b = 10 + (int(t * 6) % 2 if moving else 0)
    line(c, 38 + shift, 22, a + 2, b + 10, LINE)
    box(c, 4 + shift, 17, 34, 10, "#d93a47")
    box(c, 5 + shift, 18, 32, 8, WHITE)
    inning = int(s.get("inning", 1))
    suffix = "TH" if inning % 100 in [11, 12, 13] else {1: "ST", 2: "ND", 3: "RD"}.get(inning % 10, "TH")
    label = ("MID " if s.get("top", True) else "END ") + str(inning) + suffix
    text(c, label, 5 + shift + (32 - (len(label) * 4 - 1)) // 2, 20, "#d93a47")
    mascot(c, a, b, t, moving)

def frame(s, t):
    c = [[INK for _ in range(64)] for _ in range(32)]
    mode = s.get("mode")
    if mode == "pre":
        pregame(c, s, t)
    elif mode == "final" and not (s.get("episode") and s["episode"].get("age", 0) + t < s["episode"].get("duration", 0)):
        final(c, s, t)
    elif mode in ["stale", "delay", "held", "unavailable"]:
        header(c, s)
        centered(c, "FEED DELAY" if mode in ["stale", "unavailable"] else "GAME DELAY", 15, GOLD)
    else:
        ep = s.get("episode")
        age = ep.get("age", 0) + t if ep else 99999
        if ep and age < ep.get("duration", 0):
            state = dict(ep)
            state["uiTime"] = s.get("uiTime", 0)
            pitch_end = 8 if ep.get("isPitch") else 0
            field_end = pitch_end + (6 if ep.get("inplay") else 0)
            if age < pitch_end:
                if age < 2.35:
                    state["balls"] = ep["beforeCount"][0]
                    state["strikes"] = ep["beforeCount"][1]
                    state["outs"] = ep["beforeCount"][2]
                state["bases"] = ep.get("beforeBases", [])
                state["awayScore"] = ep["beforeScores"][0]
                state["homeScore"] = ep["beforeScores"][1]
                batter_scene(c, state, age, True, ep)
            elif age < field_end:
                field(c, state, ep, age - pitch_end)
            elif ep.get("scorers") and age < field_end + len(ep["scorers"]) * 4:
                who = ep["scorers"][min(len(ep["scorers"]) - 1, int((age - field_end) / 4))]
                header(c, state)
                fitted(c, who, max(1, 32 - len(who) * 2), 12, min(62, len(who) * 4 - 1), (age - field_end) % 4, WHITE)
                centered(c, "SCORES", 21, GOLD)
            else:
                header(c, state)
                label = ep.get("outcome") or ep.get("call", "PLAY")
                fitted(c, label, max(1, 32 - len(label) * 2), 15, min(62, len(label) * 4 - 1), age - field_end, GOLD)
        elif s.get("outs", 0) >= 3 and s.get("mascot", True):
            inning_break(c, s, t)
        else:
            batter_scene(c, s, t)
    scale = 1
    rows = []
    for row in c:
        runs = []
        start = 0
        for x in range(1, 65):
            if x == 64 or row[x] != row[start]:
                runs.append(render.Box(width = (x - start) * scale, height = scale, color = row[start]))
                start = x
        rows.append(render.Row(children = runs))
    return render.Column(children = rows)

def main(config):
    if config.get("fixture"):
        s = json.decode(config["fixture"])
    else:
        endpoint = config.get("feed_url", "").rstrip("/")
        if not endpoint:
            return render.Root(child = render.Column(children = [render.Text("RETRO PHILLIES", font = "CG-pixel-3x5-mono", color = "#ffcf55"), render.Text("SET COMPANION", font = "CG-pixel-3x5-mono"), render.Text("SEE README", font = "CG-pixel-3x5-mono")]))
        consumer = config.get("consumer", "display1")
        if not consumer or len(consumer) > 48 or any([ch not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_" for ch in consumer.elems()]):
            return render.Root(child = render.Text("Check display ID"))
        response = http.get(endpoint + "/retro-baseball?consumer=" + consumer, ttl_seconds = 1)
        if response.status_code != 200:
            return render.Root(child = render.Text("Feed unavailable"))
        s = response.json()
        s["uiTime"] = time.now().unix
    role = config.get("role", "rotation")
    if role == "postseason" and not s.get("active", False):
        return []
    if role == "allgames" and not s.get("inGameWindow", False):
        return []
    s["mascot"] = config.bool("mascot", True)
    return render.Root(delay = 200, child = render.Animation(children = [frame(s, i / 5.0) for i in range(50)]))

def get_schema():
    return schema.Schema(version = "1", fields = [
        schema.Text(id = "feed_url", name = "Companion URL", desc = "Requires the separately installed Retro Phillies companion; see app README. URL reachable by your Tronbyt server.", icon = "link", default = ""),
        schema.Text(id = "consumer", name = "Display ID", desc = "Choose a unique letters/numbers ID for each physical display. Use the same ID for its rotation and focus copies.", icon = "tv", default = "display1"),
        schema.Dropdown(id = "role", name = "App role", desc = "For focus, install a second copy and enable Tronbyt Autopin on that copy. Keep Autopin OFF on the normal rotation copy.", icon = "flag", default = "rotation", options = [schema.Option(display = "Normal rotation", value = "rotation"), schema.Option(display = "Postseason focus", value = "postseason"), schema.Option(display = "All-game focus", value = "allgames")]),
        schema.Toggle(id = "mascot", name = "Phanatic inning breaks", desc = "Show the mascot towing a MID/END banner between halves.", icon = "flag", default = True),
    ])
