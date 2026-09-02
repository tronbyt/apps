"""
Applet: UniFi Network
Summary: WAN latency and clients
Description: Your UniFi network on one panel: WAN latency now, a 24-hour latency chart with packet loss marked in red, how many devices are up, and how many clients are on wifi and on cable. Reads the UniFi Cloud (Site Manager) API by default, so all it needs is one key from unifi.ui.com and no LAN name resolution. Cloud mode names the site it is showing and defaults to one you own; it does not chart the ISP speed figures that API reports, because those are the provisioned plan rate rather than live traffic. Local console mode shows live WAN throughput instead, for consoles whose hostname the display can resolve and whose certificate it trusts. An amber "!" beside the UNIFI tag means a firmware update is waiting.
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
SPARK_LOSS = "#6B1F1B"

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

# Round-trip latency, in ms, at which the hero reading stops being white-hot
# amber and starts being a complaint. A home WAN sits under 40; anything over
# AMBER_MS is a satellite link, a saturated uplink or a sick one.
AMBER_MS = 120
RED_MS = 250

# Above this a reading has stopped being a measurement and become a symptom,
# and it has also stopped fitting: the hero draws ">999" in red instead of a
# four or five digit number nobody reads across a room.
MAX_MS = 999

# How far back the hero may look for a current reading, in five minute bins.
# The newest bin is often still filling and reports nothing, which is what a
# fallback is for; an hour-old number presented as "now" is not.
STALE_BINS = 3

# Glyph cells the hero reserves for the reading when sizing the site label:
# three for every latency the panel can print, four for the ">999" clamp. Held
# constant across readings on purpose -- see latency_hero(). The stability is
# bought with label width: a reserved three cells is what turns "ARCHTOP" into
# "ARCHT." at every reading rather than only at three-digit ones, and this
# constant is the whole of that trade.
MS_GLYPHS = 3
MS_GLYPHS_OVER = 4

# Model strings of every UniFi box that routes: Dream Machine/Router/Wall, the
# UXG and USG gateways, and the Cloud Gateway line, whose models all carry the
# word "gateway". Matched against `model`, never against `name`, because `name`
# is whatever the owner typed and an access point called "Router" must not win.
GATEWAY_MODELS = ("gateway", "dream", "udm", "uxg", "usg", "ugw")

# Weakest signal of the three, and last, because "express" is a marketing word
# before it is a product line.
GATEWAY_MODELS_WEAK = ("express",)

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

def key_ok(key):
    """Whether this key can go in a header at all.

    Go's transport refuses a header value carrying a newline or any other
    control character, and refusing is a transport error: an uncatchable
    render abort, a blank panel with no card on it, and the app dropped from
    the rotation. A key pasted out of a file, or set through a JSON config
    where a trailing byte survived, is the ordinary way this happens. main()
    strips the obvious case; this catches the rest and says so on the panel.
    """
    for c in key.codepoints():
        if c < " " or c > "~":
            return False
    return True

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

def hero(l, view):
    """The one band big enough to be read across a room."""
    gw = view["gw"]
    if gw == "down":
        return big_line(l, "WAN DOWN", RED)
    if gw == "missing":
        return big_line(l, "NO GATEWAY", AMBER)
    if gw == "none":
        return big_line(l, "NO DEVICES", AMBER)
    if view["mode"] == "latency":
        return latency_hero(l, view["latency"], view["label"])
    return rate_hero(l, view["down"], view["up"])

def rate_hero(l, down, up):
    """Local mode: the console's own instantaneous uplink counters.

    The reading is coarse. Under a sustained, independently measured 355 Mbit/s
    download the same console's uplink.rxRateBps sampled 0.4, 12.9 and 102.1
    Mbit/s within half a minute, because it is whatever the last ~23 second
    heartbeat happened to catch rather than an average. It is shown to two
    significant figures for that reason, and the sparkline underneath it is
    where the shape of the traffic actually lives.
    """
    if down == None:
        return big_line(l, "NO DATA", DIM)

    d_txt = fmt_rate(down)
    u_txt = fmt_rate(up if up != None else 0)

    # Two 4-character rates at the hero font leave the readings 2px apart,
    # which merges them into one blob; shrink a size instead.
    #
    # Measured on the *widest* string the formatter can return, not on this
    # sample's: a rate that swings two decades between renders would otherwise
    # change font every minute, and the panel would appear to breathe. Four
    # glyphs at the hero advance is the cap fmt_rate is written to, and a "."
    # is narrower than a glyph cell, so this is a true worst case.
    worst = 4 * l["big_adv"] + 6 * l["s"]
    mid = 2 * worst + 4 * l["s"] > l["w"] - 2 * l["pad"]

    dwidget, _ = metric(l, d_txt, AMBER, True, mid)
    uwidget, _ = metric(l, u_txt, BLUE, False, mid)
    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [dwidget, uwidget],
    )

def latency_color(ms):
    """White is a reading, amber is a complaint, red is a problem."""
    if ms >= RED_MS:
        return RED
    if ms >= AMBER_MS:
        return AMBER
    return WHITE

def latency_hero(l, ms, label):
    """Cloud mode: round-trip latency now, and which site that is.

    Latency, not throughput, because the Site Manager API has no throughput to
    give: measured across 278 consecutive 5-minute periods its download_kbps
    and upload_kbps never moved once, and read 0 all day on a second, perfectly
    healthy connection. They are the provisioned plan rate. avgLatency,
    maxLatency and packetLoss are the fields that actually vary, so they are
    the ones on the panel.

    The site label earns its half of the row because an account can hold
    several sites and this API hands them back in an order the user never
    chose; a number with no name on it is a number from an arbitrary network.
    """
    parts = []
    budget = (l["w"] - 2 * l["pad"]) // l["s"]
    if ms != None:
        # A reading this far out of range is a dead or dying link rather than
        # a number to read, and five digits would not fit beside the label
        # anyway. Clamped rather than dropped: the old code discarded anything
        # over 999 and walked back to an older, healthier period, which put a
        # white 8 MS on a WAN sitting at 1400.
        txt = "%d" % ms
        glyphs = MS_GLYPHS
        if ms > MAX_MS:
            txt = ">%d" % MAX_MS
            glyphs = MS_GLYPHS_OVER

        # 1x units throughout, as in footer(): the 2x label font is relatively
        # narrower, so measuring each canvas on its own terms would truncate
        # the site name at one size and not the other.
        #
        # Sized on the widest reading the hero can print, not on this one, for
        # the reason rate_hero() gives about its own font: a budget that moves
        # with the metric took a letter off the site name as latency crossed
        # 10 ms and another as it crossed 100, so ARCHTOP became ARCHTO -- the
        # one thing on the panel that says WHICH network this is, changing
        # shape whenever the network did. Every printable reading now costs
        # the label the same three cells. Only the ">999" clamp costs a
        # fourth, and that is a state the panel is already shouting in.
        budget -= glyphs * 6 + 10 + 4
        parts.append(render.Row(
            cross_align = "center",
            children = [
                render.Text(content = txt, font = l["font_big"], color = latency_color(ms)),
                gap(l, 1),
                mark(l, GLYPH_MS, DIM),
            ],
        ))

    shown = fit_label(label, budget)
    if shown != "":
        # font_dom, not the label font: a site is named by its owner or by its
        # ISP, and both routinely contain the M, W and V that the 3px fonts
        # collapse into H and Y.
        parts.append(render.Text(content = shown, font = l["font_dom"], color = BLUE))

    if len(parts) == 0:
        return big_line(l, "NO DATA", DIM)
    return render.Row(
        expanded = True,
        main_align = "space_between" if len(parts) > 1 else "center",
        cross_align = "center",
        children = parts,
    )

# tb-8 advances, read off the shipped font by rendering "XH" and subtracting
# the ink width of "H": I, J and T are 4 wide, M, V, W and Y are 6, every other
# capital and every digit is 5, a space is 3 and a full stop is 2. Anything
# else is budgeted at 6, the widest cell in the face, so an unexpected glyph
# can only ever leave the label shorter than it had room for — never spill it
# off the edge of the panel, which nothing in the render tree would clip.
LABEL_NARROW = "IJT"
LABEL_WIDE = "MVWY"
LABEL_KNOWN = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

def char_adv(c):
    if c == " ":
        return 3
    if c == ".":
        return 2
    if c == "-":
        return 4
    if c in LABEL_NARROW:
        return 4
    if c in LABEL_WIDE:
        return 6
    if c in LABEL_KNOWN:
        return 5
    return 6

def label_width(txt):
    w = 0
    for c in txt.codepoints():
        w += char_adv(c)
    return w

def fit_label(txt, budget):
    """The most of a site name that fits, in 1x pixels.

    Whole name, else its first word, else as much of that word as fits with a
    full stop after it: an "ARCHTOP" is a site a person recognises, an
    "ARCHTOP FIB" is a glitch -- and so, more quietly, is an "ARCHTO", which a
    reader has no way to tell from a site actually called that. Anything cut
    mid-word says it was cut.
    """
    if txt == "" or budget <= 0:
        return ""
    if label_width(txt) <= budget:
        return txt
    first = txt.split(" ")[0]
    if first != "" and label_width(first) <= budget:
        return first
    room = budget - char_adv(".")
    out = ""
    w = 0
    for c in first.codepoints():
        cw = char_adv(c)
        if w + cw > room:
            break
        out += c
        w += cw
    if out == "":
        return ""
    return out + "."

def big_line(l, text, color):
    # The hero font is 5px wide, where W, V, M and N are unmistakable — these
    # strings would not be safe in the 3px label font.
    return render.Row(
        expanded = True,
        main_align = "center",
        cross_align = "center",
        children = [render.Text(content = text, font = l["font_big"], color = color)],
    )

def spark_heights(samples, body_h, s, scale):
    """Bar heights in pixels, one per sample, or [] when there is nothing to draw.

    Two scales, because the two modes chart quantities of different shape.
    "log" is for local mode's bits/sec: home WAN traffic spans several decades,
    so a linear scale flattens everything that is not the one big spike.
    "range" is for cloud mode's milliseconds, which span a handful of integers
    -- 8 to 12 across a real day -- where a log scale, or any scale anchored at
    zero, draws a solid rectangle and says nothing.
    """
    if len(samples) < 2:
        return []

    peak = 0
    for v in samples:
        if v > peak:
            peak = v

    out = []
    if scale == "log":
        if peak <= FLOOR_BPS:
            return []
        low = peak
        for v in samples:
            if v > FLOOR_BPS and v < low:
                low = v
        flat = low >= peak
        base = math.log(low)
        span = 1.0 if flat else math.log(peak) - base
        for v in samples:
            if v <= FLOOR_BPS:
                out.append(s)
            elif flat:
                out.append(body_h // 2)
            else:
                out.append(s + int((math.log(v) - base) / span * (body_h - s)))
        return out

    if peak <= 0:
        return []
    low = peak
    for v in samples:
        if v > 0 and v < low:
            low = v

    # A window whose peak never moves has no range to scale against, and it is
    # not a contrived case: latency on a healthy short-haul link sits on one
    # integer for hours. Half height for all of it -- flat, and honestly flat.
    #
    # This has to come BEFORE the base below, which is one unit under the
    # quietest reading: on a flat window that makes the span exactly one unit
    # and every bar the full height of the band, which is the solid filled
    # rectangle this scale exists to avoid.
    if low >= peak:
        for v in samples:
            out.append(s if v <= 0 else body_h // 2)
        return out

    # One unit below the quietest reading, so the quietest bar is still a bar
    # and not a gap in the chart.
    base = low - 1
    if base < 0:
        base = 0
    span = peak - base
    for v in samples:
        if v <= 0:
            out.append(s)
        else:
            out.append(s + (v - base) * (body_h - s) // span)
    return out

def sparkline(l, samples, flags, h, scale):
    """Bottom-anchored bars, newest at the right.

    A bar flagged in `flags` is drawn in red: cloud mode uses it to mark the
    five minute periods that dropped packets, which is the one thing a latency
    chart can show that the number above it cannot. The axis is always drawn,
    so an empty window reads as a chart filling up rather than as a dead band.
    """
    s = l["s"]
    body_h = h - s

    bars = []
    heights = spark_heights(samples, body_h, s, scale)
    for i in range(len(heights)):
        height = heights[i]
        if height > body_h:
            height = body_h
        lost = i < len(flags) and flags[i] > 0
        cap = RED if lost else AMBER
        if height <= s:
            bars.append(render.Box(width = s, height = s, color = cap))
        else:
            bars.append(render.Column(children = [
                render.Box(width = s, height = s, color = cap),
                render.Box(
                    width = s,
                    height = height - s,
                    color = SPARK_LOSS if lost else SPARK_BODY,
                ),
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

def labelled(l, value, label):
    return render.Row(
        cross_align = "center",
        children = [
            render.Text(content = value, font = l["font_sm"], color = WHITE),
            gap(l, 2),
            render.Text(content = label, font = l["font_txt"], color = DIM),
        ],
    )

def footer(l, wireless, wired, clients):
    """Client counts by medium.

    A lone "-" where a number belongs reads as a broken app, so an unknown
    count gives its rows to the sparkline instead.
    """
    groups = []

    if wireless != None and wired != None:
        groups.append(marked(l, GLYPH_WIFI, fmt_count(wireless)))
        groups.append(marked(l, GLYPH_WIRE, fmt_count(wired)))
    elif clients != None:
        groups.append(labelled(l, fmt_count(clients), "CLIENTS"))
    elif wireless != None:
        groups.append(marked(l, GLYPH_WIFI, fmt_count(wireless)))
    elif wired != None:
        groups.append(marked(l, GLYPH_WIRE, fmt_count(wired)))

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
    foot = footer(l, view["wireless"], view["wired"], view["clients"])

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
                child = hero(l, view),
            ),
        ),
        render.Padding(
            pad = (pad, 0, pad, 0),
            child = sparkline(l, view["samples"], view["flags"], spark_h, view["scale"]),
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

def is_public_ip(addr):
    """True for a dotted quad that is not on a private or link-local net.

    The one field on a real console's device row that gives the gateway away:
    every other device reports its LAN address, and the router reports the WAN
    address it holds. Anything unparseable, and anything inside RFC1918,
    loopback, link-local or the carrier-grade NAT block, is not evidence.
    """
    parts = addr.split(".")
    if len(parts) != 4:
        return False
    nums = []
    for p in parts:
        if p == "" or not p.isdigit() or len(p) > 3:
            return False
        n = int(p)
        if n > 255:
            return False
        nums.append(n)
    a = nums[0]
    b = nums[1]
    if a == 10 or a == 127 or a == 0:
        return False
    if a == 192 and b == 168:
        return False
    if a == 172 and b >= 16 and b <= 31:
        return False
    if a == 169 and b == 254:
        return False
    if a == 100 and b >= 64 and b <= 127:
        return False
    return True

def gateway_rank(device):
    """How sure we are that this device is the router. 0 means not a candidate.

    "First device whose features contains gateway" is what the API documents
    and it finds nothing on real hardware: a UniFi Dream Wall, which *is* the
    gateway for its site, reports features ["switching", "accessPoint"] and no
    gateway entry at all. Every device also carries an uplink block with a
    rate in it — the switch's uplink is its cable to the router — so "has
    uplink stats" is not a test either, and picking wrong would put LAN traffic
    on the panel labelled as WAN.

    So: the documented flag first, then the model, which is a vendor string
    rather than the owner's nickname, then the giveaway that this device holds
    the public address.
    """
    features = dget(device, "features", [])
    if type(features) == "list" and "gateway" in features:
        return 4
    model = as_text(dget(device, "model", "")).lower()
    for kw in GATEWAY_MODELS:
        if kw in model:
            return 3
    if is_public_ip(as_text(dget(device, "ipAddress", ""))):
        return 2
    for kw in GATEWAY_MODELS_WEAK:
        if kw in model:
            return 1
    return 0

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

    # The same undecodable-200 check the /sites call above makes, and here it
    # matters more: an empty device list is not an absence on this panel, it
    # is an assertion. Left unchecked, a captive portal's HTML rendered
    # "NO DEVICES", "0/0 UP" and a red dot -- a specific claim about the
    # network, built from a reply that never parsed -- above a footer still
    # counting the clients the calls that DID parse returned.
    device_body = resp_json(devices)
    if device_body == None:
        return (None, card(l, "NOT A CONSOLE", AMBER, "CHECK ADDRESS"))

    device_list = as_list(dget(device_body, "data", []))

    total = 0
    online = 0
    updatable = False
    gateway = None
    best = 0
    for d in device_list:
        if type(d) != "dict":
            continue
        total += 1
        up_now = dget(d, "state", "") == "ONLINE"
        if up_now:
            online += 1
        if dget(d, "firmwareUpdatable", False) == True:
            updatable = True

        # An online candidate beats an offline one of the same rank, but never
        # a stronger signal: a powered-down Dream Machine is still the gateway,
        # and a live access point holding a public address is still not.
        score = gateway_rank(d) * 2
        if score > 0 and up_now:
            score += 1
        if score > best:
            best = score
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

                # Units stay formally unresolved. Under a sustained,
                # independently measured 355 Mbit/s download this field peaked
                # at 102,144,744, which is 102 Mbit/s read as bits and 817
                # Mbit/s read as bytes; neither matches the load, and the same
                # run also read 384,520 twice in a row, so the sample is coarse
                # as well. Kept as bits, which is the UniFi UI's own convention
                # and matches the sibling rxRateLimitKbps field, and presented
                # as a rounded headline rather than a measurement.
                down = as_num(dget(uplink, "rxRateBps"))
                up = as_num(dget(uplink, "txRateBps"))

    clients = client_count(base, site_id, api_key, None)
    wireless = client_count(base, site_id, api_key, "type.eq('WIRELESS')")
    wired = None
    if clients != None and wireless != None:
        wired = clients - wireless
        if wired < 0:
            wired = 0

    # A gateway that is offline is the one state worth shouting about, so it
    # takes the hero row and turns the dot red.
    #
    # Not finding one is NOT that state, whatever the old code claimed. On real
    # hardware the router does not announce itself (see gateway_rank), so
    # "NO GATEWAY" here was a false alarm printed over a perfectly healthy
    # network. When nothing scores, the WAN half of the panel simply has no
    # reading and says so, and the device and client half is still true.
    gw = "ok"
    if total == 0:
        gw = "none"
    elif gateway != None and dget(gateway, "state", "") != "ONLINE":
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
        "label": "",
        "mode": "rate",
        "scale": "log",
        "flags": [],
    }, None)

def metric_time(row):
    return row[0]

def cloud_series(body, site_id):
    """Flattens isp-metrics periods into (time, avg_ms, max_ms, loss) rows.

    Latency and loss only. download_kbps and upload_kbps are in this payload
    and they are not throughput: across 278 consecutive five minute periods on
    a live account they never changed once (862000/39000 all day), and on a
    second, healthy console they read 0 for every period of the day. They are
    the provisioned plan rate, so a chart drawn from them is a filled
    rectangle or an empty band, and a hero drawn from them is a number that
    never moves. avgLatency, maxLatency and packetLoss are what actually vary.

    Every level here is optional in practice: the shape is version-dependent
    and a fresh console reports no periods at all. Sorted by metricTime rather
    than trusted to arrive ordered.

    Matched on siteId and nothing else. This endpoint answers for every console
    on the account -- and only for the ones the key owns, so two of three sites
    reported on the live account -- which means the first entry is routinely a
    different network from the one on the panel. Wearing a neighbouring site's
    latency and chart under this site's device and client counts is unmarked
    and unfalsifiable from across the room, so a site with no entry here gets
    an empty WAN half instead.

    Args:
        body: the decoded /v1/isp-metrics/5m payload, of any shape.
        site_id: the siteId of the site on the panel, possibly "".

    Returns:
        Rows for that site, or [] when none belong to it.
    """
    entry = None
    if site_id != "":
        for e in as_list(dget(body, "data", [])):
            if type(e) != "dict":
                continue
            if as_text(dget(e, "siteId", "")) == site_id:
                entry = e
                break
    if entry == None:
        return []

    rows = []
    for p in as_list(dget(entry, "periods", [])):
        if type(p) != "dict":
            continue
        wan = dget(dget(p, "data", {}), "wan", {})
        avg = as_num(dget(wan, "avgLatency"))
        peak = as_num(dget(wan, "maxLatency"))
        loss = as_num(dget(wan, "packetLoss"))
        rows.append((
            as_text(dget(p, "metricTime", "")),
            avg,
            peak if peak != None else avg,
            loss if loss != None and loss > 0 else 0,
        ))
    return sorted(rows, key = metric_time)

def downsample(values, target):
    """Squeezes a series onto the panel, keeping each bucket's peak.

    A 24 hour 5 minute series is up to 288 points against 62 columns; the mean
    would erase exactly the spikes the chart exists to show. Loss flags ride
    through here as 0/1 ints for the same reason: one bad period in a bucket
    has to survive the squeeze.
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

def site_haystacks(site):
    """Everything a user might reasonably type to mean this site.

    meta.name alone is not enough. On the live account all three sites are
    named "default" and described "Default"; what tells them apart is the ISP,
    the gateway model and the ids. So "archtop", "fios", "udw", a gateway MAC
    and a pasted siteId all have to work.
    """
    meta = dget(site, "meta", {})
    stats = dget(site, "statistics", {})
    isp = dget(stats, "ispInfo", {})
    return [
        as_text(dget(meta, "name", "")),
        as_text(dget(meta, "desc", "")),
        as_text(dget(isp, "name", "")),
        as_text(dget(isp, "organization", "")),
        as_text(dget(dget(stats, "gateway", {}), "shortname", "")),
        as_text(dget(meta, "gatewayMac", "")),
        as_text(dget(site, "siteId", "")),
        as_text(dget(site, "hostId", "")),
    ]

def site_label(site):
    """What to call this site on the panel.

    The owner's own name for it when they gave it one, and the ISP when they
    did not, which on real accounts is most of the time: "default" is the name
    every site is born with and few people ever change it.
    """
    meta = dget(site, "meta", {})
    for key in ("name", "desc"):
        txt = as_text(dget(meta, key, "")).strip()
        if txt != "" and txt.lower() != "default":
            return txt.upper()
    stats = dget(site, "statistics", {})
    txt = as_text(dget(dget(stats, "ispInfo", {}), "name", "")).strip()
    if txt != "":
        return txt.upper()
    return as_text(dget(dget(stats, "gateway", {}), "shortname", "")).strip().upper()

def site_matches(site, want):
    """Whether anything a user might type to mean this site contains `want`."""
    for hay in site_haystacks(site):
        if hay != "" and want in hay.lower():
            return True
    return False

def prefer_owned(sites):
    """Narrows a list of sites to the ones with the strongest claim to be ours.

    Ownership first, then admin, and the whole list back when neither tells
    them apart: narrowing to nothing would turn "which of these" into "none of
    these", which is a different and wrong answer.
    """
    owned = []
    for s in sites:
        if dget(s, "isOwner", False) == True:
            owned.append(s)
    if len(owned) > 0:
        return owned
    admin = []
    for s in sites:
        if as_text(dget(s, "permission", "")).lower() == "admin":
            admin.append(s)
    if len(admin) > 0:
        return admin
    return sites

def pick_site(body, want):
    """Chooses the site to show, and says whether the user chose it.

    With no site configured, prefers one the key owns. An account routinely
    carries consoles that were shared with it -- three sites on the live
    account, the first of them read-only and belonging to somebody else -- and
    data[0] is whatever order the API felt like. Someone else's network is
    never the sane default: it is not the one the owner wants on their wall,
    and it is the one the metrics endpoint declines to report on.

    A configured site gets the same care, because the field is a substring
    match and the strings are not distinctive. On the live account all three
    sites are named "default" and two report the same gateway shortname, so
    "default" -- the name UniFi gives every site and the one its own UI shows
    -- fits all three, and "udmpro" fits two. Taking the first was the old
    data[0] bug moved onto the configured path, where it was worse: it made
    filling the field in less safe than leaving it blank. So the matches are
    narrowed the way the blank case is, and an ambiguity that survives that is
    reported rather than resolved by list order.

    Args:
        body: the decoded /v1/sites payload, of any shape.
        want: the lowercased site the user asked for, or "".

    Returns:
        (site, count, hits) -- site is None when nothing matched or more than
        one did. count is how many sites the key can see and hits how many of
        them `want` fitted, both for the card that says so.
    """
    sites = []
    for s in as_list(dget(body, "data", [])):
        if type(s) == "dict":
            sites.append(s)

    if want != "":
        hits = []
        for s in sites:
            if site_matches(s, want):
                hits.append(s)

        # Deliberately no fallback: a named site that cannot be found must not
        # quietly become a different one.
        if len(hits) == 0:
            return (None, len(sites), 0)

        best = hits
        if len(best) > 1:
            best = prefer_owned(best)
        if len(best) == 1:
            return (best[0], len(sites), len(hits))
        return (None, len(sites), len(hits))

    picked = prefer_owned(sites)
    if len(picked) > 0:
        return (picked[0], len(sites), 0)
    return (None, 0, 0)

def cloud_view(l, config, api_key):
    """Fetches everything the panel needs from the Site Manager API.

    Two calls, no LAN dependency and no name the display has to resolve.

    Returns:
        (view, card) -- exactly one of the two is None.
    """
    base = cloud_base(config)

    sites = api_get(base + "/v1/sites", api_key, TTL_CLOUD)
    site_body = resp_json(sites)
    code = cloud_status(sites, site_body)
    if not ok2xx(code):
        return (None, http_card(l, code, "cloud"))
    if site_body == None:
        return (None, card(l, "NO REPLY", AMBER, "CHECK ADDRESS"))

    want = (config.str("site") or "").strip().lower()
    site, site_count, site_hits = pick_site(site_body, want)
    if site == None:
        if site_hits > 1:
            # Refused, not resolved: the sites this fits include, first in the
            # list on the live account, a read-only console belonging to
            # somebody else. Spelled without M, W or V like every other string
            # in this font -- "N SITES MATCH" reads "N SITES HATCH" -- and it
            # names the two fields that actually tell sites apart, since the
            # names on a real account do not.
            return (None, card(l, "%d SITES FIT" % site_hits, AMBER, "USE ISP OR ID"))
        if want != "" and site_count > 0:
            return (None, card(l, "NO SUCH SITE", AMBER, "%d SITES ON KEY" % site_count))
        return (None, card(l, "NO SITES", AMBER, "CHECK KEY SCOPE"))

    site_id = as_text(dget(site, "siteId", ""))

    # statistics and all of its children are loosely typed and change between
    # console releases -- the live payload carries percentages.txRetry,
    # ispInfo.asn, wans and wanMagic, none of which the spec mentions -- so
    # every level is read through dget, and an absent count stays None rather
    # than becoming a zero we would then present as fact.
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

    # Two different kinds of known, because the ratio needs both halves of it
    # and the hero needs only the first. Substituting zero for an absent
    # offlineDevice printed "9/9 UP" in white under a green dot -- an
    # unqualified all-clear assembled from a count that was never reported --
    # which is exactly what the note above says this block does not do.
    have_total = total != None
    ratio_known = have_total and offline != None
    online = 0
    if ratio_known:
        online = total - offline
        if online < 0:
            online = 0

    gw = "ok"
    if have_total and total == 0:
        gw = "none"
    elif gw_count != None and gw_count == 0:
        gw = "missing"
    elif gw_offline != None and gw_offline > 0:
        gw = "down"

    # GREEN is an assertion about the network and may only be made from data
    # we actually read. statistics and its children are version-dependent, and
    # the spec says so outright, so a console that renames or drops counts
    # leaves every field above None -- and a dot that defaults to green would
    # then show a steady all-clear while every device could be offline. When
    # nothing health-bearing parsed, the dot goes dim: unknown, not well.
    # Local mode has no such state, it reads the device list itself.
    health_known = len(issues) > 0
    for v in (total, offline, pending, gw_count, gw_offline, uptime):
        if v != None:
            health_known = True

    # ratio_known joins health_known for the same reason: green with no
    # offline count is a claim that every device is up, made without the
    # field that would say so.
    dot = GREEN
    if gw != "ok" or len(issues) > 0 or (uptime != None and uptime < 99):
        dot = RED
    elif (offline != None and offline > 0) or (pending != None and pending > 0):
        dot = AMBER
    elif not health_known or not ratio_known:
        dot = DIM

    clients = None
    if wireless != None and wired != None:
        # guestClient is not added in: whether it double-counts the wifi and
        # wired tallies is not documented, and a total that can exceed the
        # parts is worse than no total.
        clients = wireless + wired

    latency = None
    samples = []
    flags = []
    metrics = api_get(base + "/v1/isp-metrics/5m", api_key, TTL_CLOUD, {"duration": "24h"})
    metrics_body = resp_json(metrics)

    # A failure here is not fatal: /v1/sites already answered, so the device
    # and client half of the panel is good. Losing the series costs the hero
    # number and the chart, not the app.
    if ok2xx(cloud_status(metrics, metrics_body)):
        rows = cloud_series(metrics_body, site_id)
        columns = (l["w"] - 2 * l["pad"]) // l["s"]

        # The bars are the peak of each five minute bin, which is where a
        # latency chart has any shape at all: across a real day avgLatency held
        # two values (8 and 9) where maxLatency moved through five (8 to 12).
        # The hero above them stays the average, because that is the honest
        # answer to "what is my latency right now".
        samples = downsample([r[2] for r in rows if r[2] != None], columns)
        flags = downsample([1 if r[3] > 0 else 0 for r in rows if r[2] != None], columns)

        # Newest first, because the newest bin is the current reading, and
        # the walk back from it is bounded. The bin now filling can report
        # nothing yet, which is what a fallback is for; an hour-old number
        # presented as "now" is not. Unbounded, this scanned a whole day: a
        # WAN that had been down for an hour -- every recent bin 0 ms and 100%
        # loss -- printed the last healthy 8 MS in white, with a 1px red stub
        # at the edge of the chart as the only sign. Past STALE_BINS there is
        # no current reading and the panel says nothing rather than something
        # old.
        #
        # No upper bound here either. A reading over MAX_MS used to be
        # skipped, so a link sitting at 1400 ms all day rendered no number at
        # all and looked like a site with no metrics; the hero clamps it to
        # ">999" in red instead.
        for i in range(STALE_BINS):
            if i >= len(rows):
                break
            r = rows[len(rows) - 1 - i]
            if r[1] != None and r[1] > 0:
                latency = r[1]
                break

    # Latency is the only field in this payload that measures the WAN itself
    # -- the ISP speed figures never move -- and until now it coloured the
    # number and nothing else. A link at 400 ms drew a red reading under a
    # green dot, which across a room reads as an all-clear with something odd
    # in it rather than as a problem.
    if latency != None:
        if latency >= RED_MS:
            dot = RED
        elif latency >= AMBER_MS and dot == GREEN:
            dot = AMBER

    ratio, ratio_color = health(gw, online, total if ratio_known else 0, ratio_known)
    return ({
        "down": None,
        "up": None,
        "samples": samples,
        "flags": flags,
        "scale": "range",
        "mode": "latency",
        "label": site_label(site),
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

    # Stripped here rather than only tested stripped, which is what the old
    # line did: the untouched value was the one that went into the header. A
    # key pasted out of a file or a `cat` carries a trailing newline, Go's
    # transport refuses to send that header at all, and a transport error is
    # an uncatchable render abort -- a blank panel with no card on it and the
    # app gone from the rotation. Same failure class clean_host() spends its
    # length pre-empting for the address field, which had a guard where the
    # key had none.
    api_key = (config.str("api_key") or "").strip()
    if api_key == "":
        return setup_card(l, src)
    if not key_ok(api_key):
        return card(l, "BAD API KEY", RED, "CHECK FOR TYPOS")

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
                desc = "Cloud mode only, optional. Part of the site name, its ISP, its gateway model or its ID -- most sites are called \"Default\", so \"verizon\" or \"udm\" is often the thing that tells yours apart. A value that fits more than one site is reported, not guessed at. Blank picks a site you own.",
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
