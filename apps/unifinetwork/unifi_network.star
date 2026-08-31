"""
Applet: UniFi Network
Summary: Live network activity
Description: Live WAN throughput, a download sparkline, device health and client counts from your UniFi sites. Reads the UniFi Cloud (Site Manager) API by default, so all it needs is one key from unifi.ui.com and no LAN name resolution; cloud mode charts the real 24-hour ISP series. A local console mode is there for consoles whose hostname the display can resolve and whose certificate it trusts. An amber "!" beside the UNIFI tag means a firmware update is waiting.
Author: nsluke
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("hash.star", "hash")
load("http.star", "http")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")

BLUE = "#2E8BFF"
WHITE = "#E8E4DC"
DIM = "#6E7A8A"
GREEN = "#3ED860"
AMBER = "#FFB23C"
RED = "#F0524A"
SPARK_BODY = "#7A4A10"

# Cloud (Site Manager) transport. api.ui.com is in public DNS and carries an
# ordinary public certificate, so it resolves and verifies from any network.
# The console's own .ui.direct name does neither: measured against the
# authoritative nameservers for id.ui.direct it is NXDOMAIN, because the
# console synthesizes the record itself at TTL 0. It answers only for clients
# whose resolver is the UniFi gateway, and a name that does not resolve is a
# transport error, which aborts the render with nothing on the panel. Hence
# cloud is the default and local is the advanced option.
CLOUD_API = "https://api.ui.com"
LOCAL_PATH = "/proxy/network/integration/v1"

SOURCES = ("cloud", "local")

TTL_SITES = 3600
TTL_LIVE = 45
TTL_CLOUD = 120

MAX_SAMPLES = 60
CACHE_TTL = 3600

# Sparkline bars are log-scaled from this floor up to the window peak.
FLOOR_BPS = 100000

# Hand-drawn marks, because no font at this size can carry the words.
#
# Read out of the shipped BDFs, CG-pixel-3x5-mono is H "#.#/#.#/###/#.#/#.#",
# M the same with the bar one row up and W the same with it one row down, and
# V is Y with the bar moved down one. tom-thumb is worse: M, N and W differ by
# a single lit row each. Widening does not help — CG-pixel-4x5-mono keeps the
# identical H/M/W construction at 4px. So "WIFI" and "WIRED" render as "HIFI"
# and "HIRED" in either 3px font, and a font swap cannot fix it.
#
# Draw the labels instead: a wifi mark and an RJ45 plug, 5x5 at 1x and doubled
# at 2x, built from the same render.Box rows the arrows and the sparkline use.
# (pixlet's built-in icon names are schema-field decorations — they are not
# panel widgets, and no image assets are wanted here.)
#
# Ascending bars, not the arc the brief suggested: a 5x5 arc is three short
# horizontal dashes stacked, which reads as an antenna or a stray "T" rather
# than as wifi. Rendered side by side, the bars win at every panel scale.
GLYPH_WIFI = [
    "....#",
    "..#.#",
    "..#.#",
    "#.#.#",
    "#.#.#",
]

# Cable up, connector body, contacts along the bottom edge.
GLYPH_WIRE = [
    "..#..",
    "..#..",
    "#####",
    "#####",
    ".#.#.",
]

# "MS" at 5 and 3 columns: the same trap costs the unit its M, so the unit is
# drawn too rather than dropped. The S is CG-pixel-3x5-mono's own S bitmap,
# copied glyph for glyph so the unit matches the rest of the panel's lettering
# — and so it cannot be misread as a 5, whose top row is "###" where the S's
# is ".##".
GLYPH_MS = [
    "#...#..##",
    "##.##.#..",
    "#.#.#..#.",
    "#...#...#",
    "#...#.##.",
]

# Every string set in font_txt is spelled without M, W or V, because those are
# the three letters that collapse into H and Y at 1x (see the note above). N,
# U and Y survive: CG-pixel's N has a top-left corner no other glyph has, and
# with V purged there is nothing left for Y to be mistaken for. The hero and
# domain fonts (6x10, tb-8, Dina) all carry true M/W/V glyphs, so strings set
# in those are unconstrained.

def layout():
    """Panel geometry and fonts for the current canvas.

    Returns:
        A dict of sizes so 1x (64x32) and 2x (128x64) share one layout.
    """
    two = canvas.is2x()
    s = 2 if two else 1
    return {
        "s": s,
        "w": canvas.width(),
        "pad": s,

        # Numerals and the "!" only: every word label on the panel is either
        # drawn (the footer marks) or set in font_txt, because this font's
        # W, V, M and N are one lit row apart from H.
        "font_sm": "Dina_r400-6" if two else "tom-thumb",

        # Prose, the app tag and the "UP" label. CG-pixel's N carries a
        # top-left corner that tom-thumb's does not, so UNIFI does not read as
        # UMIFI. Same 4px advance and 5px cap as tom-thumb, so the width
        # budgets below hold for either. Dina at 2x for its true full stop
        # (6x10's is a 3x3 cross).
        "font_txt": "Dina_r400-6" if two else "CG-pixel-3x5-mono",

        # The one literal the copy rules cannot bend: unifi.ui.com has an M in
        # it and it is an address, not prose. tb-8 is proportional with a true
        # three-stem M, and the whole domain measures 52px of the 60 available.
        # Dina at 2x already has a real M, so 2x needs no special case.
        "font_dom": "Dina_r400-6" if two else "tb-8",
        "sm_adv": 6 if two else 4,
        "sm_h": 10 if two else 6,
        "font_big": "10x20" if two else "6x10",
        "big_adv": 10 if two else 6,
        "big_h": 20 if two else 10,

        # Rows between the bottom of the font box and its baseline, so a
        # hand-drawn decimal point lands where the font's own would.
        "big_drop": 4 if two else 2,
        "font_mid": "6x10" if two else "tb-8",
        "mid_adv": 6 if two else 5,
        "mid_drop": 2 if two else 1,
        "spark_h": 18 if two else 7,
    }

def pick_source(config):
    """Reads the transport choice, never trusting it to be a known value."""
    src = config.str("source") or ""
    if src not in SOURCES:
        return SOURCES[0]
    return src

# Everything a legal URL host may contain. A character outside this set is not
# a DNS failure, it is a *parse* failure inside http.get, which aborts the
# render before a single packet leaves the device — the same uncatchable blank
# panel the IP check exists to pre-empt. A space ("my console.ui.direct") and a
# stray percent ("abc%zz.ui.direct") are the two a human actually types; "@" is
# excluded too, because userinfo moves the real destination past every check
# below it.
HOST_CHARS = (
    "abcdefghijklmnopqrstuvwxyz" +
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ" +
    "0123456789.-_:[]"
)

def clean_host(raw):
    """Normalizes a user-entered console address.

    Args:
        raw: whatever the user typed in the config field.

    Returns:
        (scheme, host, error) where error is None, "empty", "bad", "ip" or
        "mdns". "bad" is the one that applies whatever the scheme: an address
        http.get cannot parse never becomes a request, only a blank panel.
    """
    h = raw.strip()
    if h == "":
        return ("https://", "", "empty")

    # An explicit http:// is honoured (some users front the console with a
    # plain-HTTP reverse proxy on the LAN); otherwise default to https.
    scheme = "https://"
    lower = h.lower()
    if lower.startswith("http://"):
        scheme = "http://"
        h = h[7:]
    elif lower.startswith("https://"):
        h = h[8:]
    h = h.split("/")[0].strip()
    if h == "":
        return (scheme, "", "empty")

    for ch in h.codepoints():
        if ch not in HOST_CHARS:
            return (scheme, h, "bad")

    # ":80x" is another parse abort, so the port has to be checked too, and
    # digits alone are not enough: ":99999999999999" parses and then dies in
    # the dialer, which is the same blank panel. An IPv6 literal ends in "]"
    # and its own colons are part of the address.
    colon = h.rfind(":")
    if colon >= 0 and not h.endswith("]"):
        port = h[colon + 1:]
        if port == "" or not port.isdigit():
            return (scheme, h, "bad")
        if len(port) > 5 or int(port) > 65535:
            return (scheme, h, "bad")

    bare = h.split(":")[0]

    # A bare IPv4 literal can never present a publicly valid certificate.
    parts = bare.split(".")
    if len(parts) == 4:
        numeric = True
        for p in parts:
            if not p.isdigit():
                numeric = False
        if numeric:
            return (scheme, h, "ip")
    if bare.lower().endswith(".local"):
        return (scheme, h, "mdns")
    return (scheme, h, None)

# Cloud mode's endpoint is not configurable. The Console address field is
# labelled local-mode-only but stays on screen in cloud mode, so it used to
# steer both, and that was two failures at once: the account-wide unifi.ui.com
# key went to a box that is not Ubiquiti — in cleartext, if the address was
# the plain-HTTP reverse proxy local mode allows — and the request went to a
# name the display may not resolve, which is a transport error, an aborted
# render and a blank panel. That last one is the exact failure cloud mode
# exists to avoid. So no schema field reaches this: it is api.ui.com or
# nothing.
#
# The mock server this app is verified against still needs a way in, so the
# base comes from mock_base, which is deliberately absent from get_schema and
# therefore unreachable from the app's setup UI. It is loopback-only on top of
# that, so even someone who found the key cannot aim a display at a third
# party.
MOCK_HOSTS = ("127.0.0.1", "localhost")

def cloud_base(config):
    """Site Manager endpoint: api.ui.com, or the loopback mock in testing."""
    raw = (config.str("mock_base") or "").strip()
    if not raw.lower().startswith("http://"):
        return CLOUD_API

    # clean_host also rejects what http.get cannot parse — a bad port or a
    # stray character there would abort the render, and this path may never
    # be a way to cause that.
    scheme, host, problem = clean_host(raw)
    if problem == "empty" or problem == "bad":
        return CLOUD_API
    if host.split(":")[0].lower() not in MOCK_HOSTS:
        return CLOUD_API
    return scheme + host

def dget(d, key, default = None):
    """Reads a key from a value that may not be a dict, never failing."""
    if type(d) != "dict":
        return default
    v = d.get(key, default)
    if v == None:
        return default
    return v

def as_num(v):
    """Returns v as an int, or None when it is not a number."""
    t = type(v)
    if t == "int":
        return v
    if t == "float":
        return int(v)
    return None

def as_list(v):
    """Returns v when it is a list, otherwise an empty one."""
    if type(v) == "list":
        return v
    return []

def as_text(v):
    """Returns v when it is a string, otherwise an empty one."""
    if type(v) == "string":
        return v
    return ""

def api_get(url, key, ttl, params = {}):
    return http.get(
        url,
        headers = {"X-API-KEY": key, "Accept": "application/json"},
        params = params,
        ttl_seconds = ttl,
    )

def resp_json(resp):
    """Decodes a response body, returning None when it is not JSON.

    resp.json() raises on an unparseable body, which aborts the render
    uncatchably: an empty 200, a truncated reply or a proxy login page would
    take the app off the panel. json.decode's default swallows all of that.
    """
    return json.decode(resp.body(), None)

def cloud_status(resp, body):
    """Effective status code of a Site Manager reply.

    The API wraps both success and failure in an envelope carrying its own
    httpStatusCode, and the connector can hand back a 200 whose envelope
    reports the upstream's 4xx. Trust the envelope when it disagrees.
    """
    code = resp.status_code
    inner = as_num(dget(body, "httpStatusCode"))
    if inner != None and inner >= 400:
        return inner
    return code

def ok2xx(code):
    return code >= 200 and code < 300

def fmt_scaled(v, div, suffix):
    whole = v // div
    if whole < 10:
        return "%d.%d%s" % (whole, (v % div) * 10 // div, suffix)
    return "%d%s" % (whole, suffix)

def fmt_rate(bps):
    """Formats a bits/sec rate in at most 4 characters.

    The hero row has no room for a fifth glyph, so every branch is capped: the
    scaled forms roll over into the next unit before they reach 4 digits.
    """
    if bps <= 0:
        return "0"
    if bps < 1000:
        return "%db" % bps
    if bps < 1000000:
        return fmt_scaled(bps, 1000, "K")
    if bps < 1000000000:
        return fmt_scaled(bps, 1000000, "M")
    if bps < 1000000000000:
        return fmt_scaled(bps, 1000000000, "G")
    if bps < 1000000000000000:
        return fmt_scaled(bps, 1000000000000, "T")
    return "MAX"

def fmt_count(n):
    """Formats a client count in at most 4 characters, without a decimal."""
    if n < 10000:
        return "%d" % n
    return "%dK" % (n // 1000)

def gap(l, units):
    return render.Box(width = units * l["s"], height = units * l["s"])

def mark_row(l, row, color):
    """One scanline of a hand-drawn mark, run-length encoded."""
    s = l["s"]
    cells = []
    run = 0
    prev = "."
    for i in range(len(row)):
        c = "#" if row[i] == "#" else "."
        if c != prev:
            if run > 0:
                if prev == "#":
                    cells.append(render.Box(width = run * s, height = s, color = color))
                else:
                    cells.append(render.Box(width = run * s, height = s))
            prev = c
            run = 0
        run += 1
    if run > 0:
        if prev == "#":
            cells.append(render.Box(width = run * s, height = s, color = color))
        else:
            cells.append(render.Box(width = run * s, height = s))
    return render.Row(children = cells)

def mark(l, rows, color):
    """A hand-drawn mark: '#' is a lit pixel, doubled at 2x."""
    return render.Column(children = [mark_row(l, r, color) for r in rows])

def card(l, title, title_color, detail):
    """Full-panel message: the app tag, a bold reason and one detail line."""
    children = [
        render.Text(content = "UNIFI", font = l["font_txt"], color = BLUE),
        gap(l, 1),
        render.WrappedText(
            content = title,
            font = l["font_txt"],
            color = title_color,
            width = l["w"] - 2 * l["pad"],
            linespacing = l["s"],
            align = "center",
        ),
    ]
    if detail != "":
        children.append(gap(l, 2))
        children.append(render.WrappedText(
            content = detail,
            font = l["font_txt"],
            color = DIM,
            width = l["w"] - 2 * l["pad"],
            linespacing = l["s"],
            align = "center",
        ))
    return render.Root(
        child = render.Box(
            padding = l["pad"],
            child = render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = children,
            ),
        ),
    )

def setup_card(l, src):
    """What to add before the app can show anything.

    The second line is set in font_dom for cloud because it is a domain the
    user has to type somewhere else; local's second line is prose and stays in
    the label font.
    """
    if src == "local":
        lines = ["ADD CONSOLE", "+ API KEY"]
        line2_font = l["font_txt"]
    else:
        lines = ["ADD API KEY", "UNIFI.UI.COM"]
        line2_font = l["font_dom"]
    return render.Root(
        child = render.Box(
            padding = l["pad"],
            child = render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text(content = "UNIFI", font = l["font_big"], color = BLUE),
                    gap(l, 2),
                    render.Text(content = lines[0], font = l["font_txt"], color = DIM),
                    gap(l, 1),
                    render.Text(content = lines[1], font = line2_font, color = DIM),
                ],
            ),
        ),
    )

def http_card(l, code, src):
    cloud = src == "cloud"
    if code == 401:
        # Not "CHECK UNIFI.UI.COM": that M is unreadable in the label font, and
        # the setup card already carries the address in a font that can spell
        # it. Here the useful distinction is which key was wrong.
        return card(l, "BAD API KEY", RED, "CHECK CLOUD KEY" if cloud else "CHECK CONSOLE KEY")
    if code == 403:
        return card(l, "KEY LACKS ACCESS", RED, "CHECK KEY SCOPE")
    if code == 404:
        return card(l, "NOT FOUND", AMBER, "CLOUD API CHANGED" if cloud else "CHECK APP IS INSTALLED")

    # The Site Manager API is rate limited per key; a 1 minute app that gets
    # throttled should say so rather than blame the key. Neither "TOO MANY
    # CALLS" nor "RATE LIMITED" survives the label font — they come out
    # "TOO HANY CALLS" and "RATE LIHITED".
    if code == 429:
        return card(l, "THROTTLED", AMBER, "TRY AGAIN SOON")

    # 5xx is the far end failing, not refusing: say so rather than blaming
    # the request.
    if code >= 500:
        return card(l, "HTTP %d" % code, AMBER, "CLOUD ERROR" if cloud else "CONSOLE ERROR")
    return card(l, "HTTP %d" % code, AMBER, "REQUEST REFUSED")

def arrow(l, color, down):
    """A chunky 5x5 triangle, scaled for the canvas."""
    s = l["s"]
    widths = [5, 5, 3, 3, 1] if down else [1, 3, 3, 5, 5]
    rows = []
    for w in widths:
        rows.append(render.Box(width = w * s, height = s, color = color))
    return render.Column(cross_align = "center", children = rows)

def glyph_w(l, c, adv, mid):
    """Advance of one rate glyph, including the hand-drawn decimal point."""
    if c == ".":
        return 3 * l["s"]
    if mid and l["s"] == 1:
        # tb-8 is proportional; these are the only widths our charset uses.
        if c == "M":
            return 6
        if c == "T":
            return 4
        return 5
    return adv

def number(l, txt, color, font, adv, drop, mid):
    """A rate with a real dot for its decimal point.

    6x10's full stop is a 3x3 cross, so "9.8G" reads as "9+8G". Drawing the
    separator as a 1px box at the baseline keeps the number a number.

    Returns:
        (widget, width_in_pixels)
    """
    w = 0
    for i in range(len(txt)):
        w += glyph_w(l, txt[i], adv, mid)

    parts = txt.split(".")
    children = [render.Text(content = parts[0], font = font, color = color)]
    for i in range(1, len(parts)):
        children.append(render.Padding(
            pad = (l["s"], 0, l["s"], drop),
            child = render.Box(width = l["s"], height = l["s"], color = color),
        ))
        children.append(render.Text(content = parts[i], font = font, color = color))
    return (render.Row(cross_align = "end", children = children), w)

def metric(l, txt, color, down, mid):
    font = l["font_mid"] if mid else l["font_big"]
    adv = l["mid_adv"] if mid else l["big_adv"]
    drop = l["mid_drop"] if mid else l["big_drop"]
    value, w = number(l, txt, color, font, adv, drop, mid)
    return (
        render.Row(
            cross_align = "center",
            children = [arrow(l, color, down), gap(l, 1), value],
        ),
        w + 6 * l["s"],
    )

def hero(l, down, up, gw):
    """The one band big enough to be read across a room."""
    if gw == "down":
        return big_line(l, "WAN DOWN", RED)
    if gw == "missing":
        return big_line(l, "NO GATEWAY", AMBER)
    if gw == "none":
        return big_line(l, "NO DEVICES", AMBER)
    if down == None:
        return big_line(l, "NO DATA", DIM)

    d_txt = fmt_rate(down)
    u_txt = fmt_rate(up if up != None else 0)

    # Two 4-character rates at the hero font leave the readings 2px apart,
    # which merges them into one blob; shrink a size instead.
    _, dw = metric(l, d_txt, AMBER, True, False)
    _, uw = metric(l, u_txt, BLUE, False, False)
    mid = dw + uw + 4 * l["s"] > l["w"] - 2 * l["pad"]

    dwidget, _ = metric(l, d_txt, AMBER, True, mid)
    uwidget, _ = metric(l, u_txt, BLUE, False, mid)
    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [dwidget, uwidget],
    )

def big_line(l, text, color):
    # The hero font is 5px wide, where W, V, M and N are unmistakable — these
    # strings would not be safe in the 3px label font.
    return render.Row(
        expanded = True,
        main_align = "center",
        cross_align = "center",
        children = [render.Text(content = text, font = l["font_big"], color = color)],
    )

def sparkline(l, samples, h):
    """Bottom-anchored bars of download rate, newest at the right.

    Bars are log-scaled across the window's own range: home WAN traffic spans
    several decades, so a linear scale flattens everything that is not the one
    big spike. The axis is always drawn, so an empty window reads as a chart
    filling up rather than as a dead band.
    """
    s = l["s"]
    body_h = h - s

    peak = 0
    for v in samples:
        if v > peak:
            peak = v

    bars = []
    if len(samples) >= 2 and peak > FLOOR_BPS:
        low = peak
        for v in samples:
            if v > FLOOR_BPS and v < low:
                low = v

        flat = low >= peak
        base = math.log(low)
        span = 1.0 if flat else math.log(peak) - base

        for v in samples:
            if v <= FLOOR_BPS:
                height = s
            elif flat:
                height = body_h // 2
            else:
                height = s + int((math.log(v) - base) / span * (body_h - s))
            if height <= s:
                bars.append(render.Box(width = s, height = s, color = AMBER))
            else:
                bars.append(render.Column(children = [
                    render.Box(width = s, height = s, color = AMBER),
                    render.Box(width = s, height = height - s, color = SPARK_BODY),
                ]))

    if len(bars) == 0:
        body = render.Box(height = body_h)
    else:
        body = render.Box(
            height = body_h,
            child = render.Row(
                expanded = True,
                main_align = "end",
                cross_align = "end",
                children = bars,
            ),
        )

    # The axis is always drawn: a band that is black until data arrives reads
    # as a broken panel, not as a chart with no data yet.
    return render.Column(children = [body, render.Box(height = s, color = DIM)])

def header(l, ratio, ratio_color, dot_color, updatable):
    """UNIFI tag (and firmware "!") left, device ratio and health dot right.

    Built to a width budget: the health dot is the last thing on the panel
    worth losing, so the "UP" label and then the "!" go first.
    """
    s = l["s"]
    adv = l["sm_adv"]
    avail = l["w"] - 2 * l["pad"]

    dot_w = 3 * s
    right_w = dot_w
    if ratio != "":
        right_w += len(ratio) * adv + 2 * s
    left_w = 5 * adv
    bang = updatable and left_w + adv + 2 * s + right_w <= avail
    if bang:
        left_w += adv + 2 * s
    label = ratio != "" and left_w + right_w + 2 * adv + 2 * s <= avail

    left = [render.Text(content = "UNIFI", font = l["font_txt"], color = BLUE)]
    if bang:
        left.append(gap(l, 2))

        # Kept on the left, away from the ratio and the dot: three amber
        # marks in one cluster are three indistinguishable specks at
        # panel distance.
        left.append(render.Text(content = "!", font = l["font_sm"], color = AMBER))

    right = []
    if ratio != "":
        right.append(render.Text(content = ratio, font = l["font_sm"], color = ratio_color))
    if label:
        right.append(gap(l, 2))

        # "UP", not "DEV": V is Y with two lit rows instead of three in both
        # 3px fonts, so the old label read as DEY.
        right.append(render.Text(content = "UP", font = l["font_txt"], color = DIM))
    if len(right) > 0:
        right.append(gap(l, 2))
    right.append(render.Box(width = dot_w, height = dot_w, color = dot_color))

    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            render.Row(cross_align = "center", children = left),
            render.Row(cross_align = "center", children = right),
        ],
    )

def marked(l, glyph, value):
    """A drawn mark, then its number."""
    return render.Row(
        cross_align = "center",
        children = [
            mark(l, glyph, DIM),
            gap(l, 2),
            render.Text(content = value, font = l["font_sm"], color = WHITE),
        ],
    )

def latency_group(l, value):
    """A number, then a drawn "MS"."""
    return render.Row(
        cross_align = "center",
        children = [
            render.Text(content = value, font = l["font_sm"], color = WHITE),
            gap(l, 1),
            mark(l, GLYPH_MS, DIM),
        ],
    )

def labelled(l, value, label):
    return render.Row(
        cross_align = "center",
        children = [
            render.Text(content = value, font = l["font_sm"], color = WHITE),
            gap(l, 2),
            render.Text(content = label, font = l["font_txt"], color = DIM),
        ],
    )

def footer(l, wireless, wired, clients, latency):
    """Client counts by medium, with latency when there is room for it.

    A lone "-" where a number belongs reads as a broken app, so an unknown
    count gives its rows to the sparkline instead.

    All the width arithmetic is in 1x units on purpose. The 2x label font is
    relatively narrower than the 1x one, so measuring each canvas on its own
    terms would split the footer at one size and not the other, and the two
    sizes would show different facts for the same data.
    """
    groups = []
    used = 0

    if wireless != None and wired != None:
        a = fmt_count(wireless)
        b = fmt_count(wired)
        groups.append(marked(l, GLYPH_WIFI, a))
        groups.append(marked(l, GLYPH_WIRE, b))
        used = (len(a) + len(b)) * 4 + 2 * (5 + 2)
    elif clients != None:
        txt = fmt_count(clients)
        groups.append(labelled(l, txt, "CLIENTS"))
        used = len(txt) * 4 + 2 + 7 * 4
    elif wireless != None:
        txt = fmt_count(wireless)
        groups.append(marked(l, GLYPH_WIFI, txt))
        used = len(txt) * 4 + 5 + 2
    elif wired != None:
        txt = fmt_count(wired)
        groups.append(marked(l, GLYPH_WIRE, txt))
        used = len(txt) * 4 + 5 + 2

    if latency != None:
        txt = "%d" % latency
        if used + len(groups) * 4 + len(txt) * 4 + 1 + 9 <= 62:
            groups.append(latency_group(l, txt))

    if len(groups) == 0:
        return None
    align = "space_between" if len(groups) > 1 else "center"
    return render.Row(
        expanded = True,
        main_align = align,
        cross_align = "center",
        children = groups,
    )

def panel(l, view):
    s = l["s"]
    pad = l["pad"]
    foot = footer(l, view["wireless"], view["wired"], view["clients"], view["latency"])

    spark_h = l["spark_h"]
    if foot == None:
        spark_h += l["sm_h"] + s

    children = [
        render.Padding(
            pad = (pad, s, pad, 0),
            child = render.Box(
                height = l["sm_h"],
                child = header(l, view["ratio"], view["ratio_color"], view["dot"], view["updatable"]),
            ),
        ),
        render.Box(height = s),
        render.Padding(
            pad = (pad, 0, pad, 0),
            child = render.Box(
                height = l["big_h"],
                child = hero(l, view["down"], view["up"], view["gw"]),
            ),
        ),
        render.Padding(
            pad = (pad, 0, pad, 0),
            child = sparkline(l, view["samples"], spark_h),
        ),
    ]
    if foot != None:
        children.append(render.Box(height = s))
        children.append(render.Padding(
            pad = (pad, 0, pad, 0),
            child = render.Box(height = l["sm_h"], child = foot),
        ))

    return render.Root(child = render.Column(children = children))

def health(gw, online, total, known):
    """Ratio string, its colour, and the health dot, shared by both modes."""
    if not known:
        return ("", WHITE)
    ratio_color = WHITE
    if gw == "down":
        ratio_color = RED
    elif online < total:
        ratio_color = AMBER
    return ("%d/%d" % (online, total), ratio_color)

def history(host, sample):
    """Keeps a rolling list of download samples for the local sparkline.

    Cloud mode does not come here: it charts the real 24 hour ISP series
    instead. The in-memory cache is lost when the server restarts; a cold
    cache just means the sparkline grows back in from the right.
    """
    key = "unifi_net_hist_%s" % hash.md5(host)[:10]
    stored = cache.get(key)
    samples = []
    if type(stored) == "string" and stored != "":
        for part in stored.split(","):
            if part.isdigit():
                samples.append(int(part))
    if sample == None:
        return samples

    samples.append(sample)
    if len(samples) > MAX_SAMPLES:
        samples = samples[len(samples) - MAX_SAMPLES:]
    cache.set(key, ",".join([str(v) for v in samples]), ttl_seconds = CACHE_TTL)
    return samples

def client_count(base, site_id, key, filter):
    params = {"limit": "1"}
    if filter != None:
        params["filter"] = filter
    resp = api_get(base + "/sites/" + site_id + "/clients", key, TTL_LIVE, params)
    if resp.status_code != 200:
        return None
    return as_num(dget(resp_json(resp), "totalCount"))

def local_view(l, config, api_key):
    """Fetches everything the panel needs from a console on the LAN.

    Returns:
        (view, card) — exactly one of the two is None.
    """
    host_raw = config.str("host") or ""
    scheme, host, err = clean_host(host_raw)
    if err == "empty":
        return (None, setup_card(l, "local"))
    if err == "bad":
        # Not a DNS problem and not scheme-dependent: http.get cannot build a
        # URL from this at all, and an unbuilt URL is a blank panel.
        return (None, card(l, "BAD ADDRESS", AMBER, "CHECK FOR TYPOS"))
    if err != None and scheme == "https://":
        # The display, not the phone that configured it, is what has to
        # resolve this name and trust its certificate. The spec's wording was
        # "NEEDS HOSTNAME", which the label font spells "NEEDS HOSTNAHE".
        return (None, card(l, "NEEDS A HOST", AMBER, "TRUSTED CERT NEEDED"))

    base = scheme + host + LOCAL_PATH

    sites = api_get(base + "/sites", api_key, TTL_SITES, {"limit": "1"})
    if sites.status_code != 200:
        return (None, http_card(l, sites.status_code, "local"))

    # A 200 that is not JSON means we are talking to something that is not a
    # console — a captive portal or a reverse proxy's own page.
    site_body = resp_json(sites)
    if site_body == None:
        return (None, card(l, "NOT A CONSOLE", AMBER, "CHECK ADDRESS"))

    site_list = as_list(dget(site_body, "data", []))
    site_id = ""
    if len(site_list) > 0:
        site_id = as_text(dget(site_list[0], "id", ""))
    if site_id == "":
        return (None, card(l, "NO SITES", AMBER, "CHECK KEY SCOPE"))

    devices = api_get(base + "/sites/" + site_id + "/devices", api_key, TTL_LIVE, {"limit": "200"})
    if devices.status_code != 200:
        return (None, http_card(l, devices.status_code, "local"))

    device_list = as_list(dget(resp_json(devices), "data", []))

    total = 0
    online = 0
    updatable = False
    gateway = None
    for d in device_list:
        if type(d) != "dict":
            continue
        total += 1
        if dget(d, "state", "") == "ONLINE":
            online += 1
        if dget(d, "firmwareUpdatable", False) == True:
            updatable = True
        features = dget(d, "features", [])
        if gateway == None and type(features) == "list" and "gateway" in features:
            gateway = d

    down = None
    up = None
    if gateway != None:
        gw_id = as_text(dget(gateway, "id", ""))
        if gw_id != "":
            stats = api_get(
                base + "/sites/" + site_id + "/devices/" + gw_id + "/statistics/latest",
                api_key,
                TTL_LIVE,
            )
            if stats.status_code == 200:
                uplink = dget(resp_json(stats), "uplink")

                # Units are undocumented: treated as bits/sec, which matches the
                # UniFi UI and the sibling rxRateLimitKbps field. Re-verify
                # against a live console. Cloud mode has no such doubt — its
                # download_kbps is documented as kilobits.
                down = as_num(dget(uplink, "rxRateBps"))
                up = as_num(dget(uplink, "txRateBps"))

    clients = client_count(base, site_id, api_key, None)
    wireless = client_count(base, site_id, api_key, "type.eq('WIRELESS')")
    wired = None
    if clients != None and wireless != None:
        wired = clients - wireless
        if wired < 0:
            wired = 0

    # A gateway that is offline or absent is the one state worth shouting
    # about, so it takes the hero row and turns the dot red.
    gw = "ok"
    if total == 0:
        gw = "none"
    elif gateway == None:
        gw = "missing"
    elif dget(gateway, "state", "") != "ONLINE":
        gw = "down"

    if gw == "ok":
        dot = AMBER if total > online else GREEN
    else:
        dot = RED

    ratio, ratio_color = health(gw, online, total, True)
    return ({
        "down": down,
        "up": up,
        "samples": history(host, down),
        "ratio": ratio,
        "ratio_color": ratio_color,
        "dot": dot,
        "gw": gw,
        "updatable": updatable,
        "wireless": wireless,
        "wired": wired,
        "clients": clients,
        "latency": None,
    }, None)

def metric_time(row):
    return row[0]

def cloud_series(body, site_id, strict):
    """Flattens isp-metrics periods into (time, down_kbps, up_kbps, ms) rows.

    Every level here is optional in practice: the shape is version-dependent,
    a fresh console reports no periods at all, and the newest bin is often
    still filling. Sorted by metricTime rather than trusted to arrive ordered.

    This endpoint answers for every console on the account, and only sites
    with a UniFi gateway report at all, so the first entry is routinely a
    different network from the one on the panel. When the user named a site
    and nothing here belongs to it, strict keeps the WAN half empty: showing
    the neighbouring site's throughput, latency and sparkline underneath this
    site's device and client counts is unmarked and unfalsifiable from the
    panel. Where no site was named, the first entry is the documented
    fallback and stays.

    Args:
        body: the decoded /v1/isp-metrics/5m payload, of any shape.
        site_id: the siteId of the site on the panel, possibly "".
        strict: True when the user named that site and we found it.

    Returns:
        Rows for the chosen site, or [] when strict and none belong to it.
    """
    entry = None
    for e in as_list(dget(body, "data", [])):
        if type(e) != "dict":
            continue
        if entry == None and not strict:
            entry = e
        if site_id != "" and as_text(dget(e, "siteId", "")) == site_id:
            entry = e
            break
    if entry == None:
        return []

    rows = []
    for p in as_list(dget(entry, "periods", [])):
        if type(p) != "dict":
            continue
        wan = dget(dget(p, "data", {}), "wan", {})
        d = as_num(dget(wan, "download_kbps"))
        u = as_num(dget(wan, "upload_kbps"))
        rows.append((
            as_text(dget(p, "metricTime", "")),
            d if d != None else 0,
            u if u != None else 0,
            as_num(dget(wan, "avgLatency")),
        ))
    return sorted(rows, key = metric_time)

def downsample(values, target):
    """Squeezes a series onto the panel, keeping each bucket's peak.

    A 24 hour 5 minute series is up to 288 points against 62 columns; the mean
    would erase exactly the bursts the chart exists to show.
    """
    n = len(values)
    if n <= target or target <= 0:
        return values
    out = []
    for i in range(target):
        lo = i * n // target
        hi = (i + 1) * n // target
        if hi <= lo:
            hi = lo + 1
        top = 0
        for j in range(lo, hi):
            if values[j] > top:
                top = values[j]
        out.append(top)
    return out

def pick_site(body, want):
    """Chooses a site by name or description, else the first one.

    Args:
        body: the decoded /v1/sites payload, of any shape.
        want: the lowercased site the user asked for, or "".

    Returns:
        (site, matched) — matched is True only when a name was asked for and
        found. An unmatched name falls back to the first site for the whole
        panel, so its metrics may fall back too; a matched one may not.
    """
    sites = as_list(dget(body, "data", []))
    chosen = None
    for s in sites:
        if type(s) != "dict":
            continue
        if chosen == None:
            chosen = s
        if want == "":
            continue
        meta = dget(s, "meta", {})
        name = as_text(dget(meta, "name", "")).lower()
        desc = as_text(dget(meta, "desc", "")).lower()
        if (name != "" and want in name) or (desc != "" and want in desc):
            return (s, True)
    return (chosen, False)

def cloud_view(l, config, api_key):
    """Fetches everything the panel needs from the Site Manager API.

    Two calls, no LAN dependency and no name the display has to resolve.

    Returns:
        (view, card) — exactly one of the two is None.
    """
    base = cloud_base(config)

    sites = api_get(base + "/v1/sites", api_key, TTL_CLOUD)
    site_body = resp_json(sites)
    code = cloud_status(sites, site_body)
    if not ok2xx(code):
        return (None, http_card(l, code, "cloud"))
    if site_body == None:
        return (None, card(l, "NO REPLY", AMBER, "CHECK ADDRESS"))

    site, named = pick_site(site_body, (config.str("site") or "").strip().lower())
    if site == None:
        return (None, card(l, "NO SITES", AMBER, "CHECK KEY SCOPE"))

    site_id = as_text(dget(site, "siteId", ""))

    # statistics and all of its children are loosely typed and change between
    # console releases: every level is read through dget, and an absent count
    # stays None rather than becoming a zero we would then present as fact.
    stats = dget(site, "statistics", {})
    counts = dget(stats, "counts", {})
    total = as_num(dget(counts, "totalDevice"))
    offline = as_num(dget(counts, "offlineDevice"))
    pending = as_num(dget(counts, "pendingUpdateDevice"))
    gw_count = as_num(dget(counts, "gatewayDevice"))
    gw_offline = as_num(dget(counts, "offlineGatewayDevice"))
    wireless = as_num(dget(counts, "wifiClient"))
    wired = as_num(dget(counts, "wiredClient"))
    uptime = as_num(dget(dget(stats, "percentages", {}), "wanUptime"))
    issues = as_list(dget(stats, "internetIssues", []))

    known = total != None
    online = 0
    if known:
        online = total - (offline if offline != None else 0)
        if online < 0:
            online = 0

    gw = "ok"
    if known and total == 0:
        gw = "none"
    elif gw_count != None and gw_count == 0:
        gw = "missing"
    elif gw_offline != None and gw_offline > 0:
        gw = "down"

    # GREEN is an assertion about the network and may only be made from data
    # we actually read. statistics and its children are version-dependent, and
    # the spec says so outright, so a console that renames or drops counts
    # leaves every field above None — and a dot that defaults to green would
    # then show a steady all-clear while every device could be offline. When
    # nothing health-bearing parsed, the dot goes dim: unknown, not well.
    # Local mode has no such state, it reads the device list itself.
    health_known = len(issues) > 0
    for v in (total, offline, pending, gw_count, gw_offline, uptime):
        if v != None:
            health_known = True

    dot = GREEN
    if gw != "ok" or len(issues) > 0 or (uptime != None and uptime < 99):
        dot = RED
    elif (offline != None and offline > 0) or (pending != None and pending > 0):
        dot = AMBER
    elif not health_known:
        dot = DIM

    clients = None
    if wireless != None and wired != None:
        # guestClient is not added in: whether it double-counts the wifi and
        # wired tallies is not documented, and a total that can exceed the
        # parts is worse than no total.
        clients = wireless + wired

    down = None
    up = None
    latency = None
    samples = []
    metrics = api_get(base + "/v1/isp-metrics/5m", api_key, TTL_CLOUD, {"duration": "24h"})
    metrics_body = resp_json(metrics)

    # A failure here is not fatal: /v1/sites already answered, so the device
    # and client half of the panel is good. Losing the series costs the hero
    # row and the chart, not the app.
    if ok2xx(cloud_status(metrics, metrics_body)):
        rows = cloud_series(metrics_body, site_id, named)

        # download_kbps is documented as kilobits; the sparkline and the rate
        # formatter both work in bits/sec, as local mode's uplink does.
        samples = downsample(
            [r[1] * 1000 for r in rows],
            (l["w"] - 2 * l["pad"]) // l["s"],
        )

        # The newest bin is usually still filling and reads all zeros, which
        # would show a live link as idle; fall back to the last one that moved.
        pick = None
        for i in range(len(rows)):
            r = rows[len(rows) - 1 - i]
            if r[1] != 0 or r[2] != 0:
                pick = r
                break
        if pick == None and len(rows) > 0:
            pick = rows[len(rows) - 1]
        if pick != None:
            down = pick[1] * 1000
            up = pick[2] * 1000
            latency = pick[3]
            if latency != None and (latency < 0 or latency > 999):
                latency = None

    ratio, ratio_color = health(gw, online, total if known else 0, known)
    return ({
        "down": down,
        "up": up,
        "samples": samples,
        "ratio": ratio,
        "ratio_color": ratio_color,
        "dot": dot,
        "gw": gw,
        "updatable": pending != None and pending > 0,
        "wireless": wireless,
        "wired": wired,
        "clients": clients,
        "latency": latency,
    }, None)

def main(config):
    l = layout()
    src = pick_source(config)

    api_key = config.str("api_key") or ""
    if api_key.strip() == "":
        return setup_card(l, src)

    if src == "local":
        view, msg = local_view(l, config, api_key)
    else:
        view, msg = cloud_view(l, config, api_key)
    if msg != None:
        return msg
    return panel(l, view)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "source",
                name = "Connection",
                desc = "Cloud reads api.ui.com and works from any network. Local talks to the console directly and needs the display to resolve its hostname and trust its certificate.",
                icon = "cloud",
                default = "cloud",
                options = [
                    schema.Option(display = "UniFi Cloud (recommended)", value = "cloud"),
                    schema.Option(display = "Local console (advanced)", value = "local"),
                ],
            ),
            schema.Text(
                id = "api_key",
                name = "API key",
                desc = "Cloud: an API key from unifi.ui.com, Settings > API Keys. Local: a Network API key from Control Plane > Integrations on the console.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "site",
                name = "Site",
                desc = "Cloud mode only, optional. Part of the site name; blank uses your first site.",
                icon = "sitemap",
            ),
            schema.Text(
                id = "host",
                name = "Console address",
                desc = "Local mode only: the hostname of your console. A bare IP or a .local name cannot present a certificate the display will trust. Cloud mode ignores this field.",
                icon = "server",
            ),
        ],
    )
