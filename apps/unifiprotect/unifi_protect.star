"""
Applet: UniFi Protect
Summary: Cameras on your panel
Description: Puts a UniFi Protect camera on your display: a live low-quality snapshot with the camera name, or a status board showing cameras online, the alarm arm state and UP Sense sensor alerts (open doors, water leaks, low batteries). By default it reaches your console through the UniFi cloud, which needs only an API key from unifi.ui.com. A local connection is also offered, but the display itself has to resolve your console's hostname and trust its certificate for that to work. Camera motion and doorbell ring events are not shown, because the official API only delivers those over WebSocket, which this runtime cannot open.
Author: nsluke
"""

load("cache.star", "cache")
load("hash.star", "hash")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

BLUE = "#2E8BFF"
WHITE = "#E8E4DC"
DIM = "#6E7A8A"
GREEN = "#3ED860"
AMBER = "#FFB23C"
RED = "#F0524A"

# The header rule is the only structural line in the design, so it has to
# survive a panel dimmed for a living room. #16304F measured 1.6:1 against
# black and its red channel sat under the driver's usable PWM floor, which
# turned it into an uneven smear; this is ~2.5:1 and holds together.
RULE = "#24507F"
SCRIM = "#000000BE"
BLACK = "#000000"

# The Protect API's own path. In local mode it hangs off the console; in cloud
# mode off the connector. It is spelled once because it is the same API either
# way - the transport is the ONLY thing that differs between the two modes.
API_PATH = "/proxy/protect/integration/v1"

# The cloud transport. api.ui.com is in public DNS with an ordinary public
# certificate, which the console's own .ui.direct name is not: that name is
# synthesized by the gateway at TTL 0 and is NXDOMAIN at the authoritative
# nameservers, so it resolves only for clients whose resolver is the gateway.
# Cloud Key / UNVR owners, Pi-hole and Unbound forwarders, pfSense and Fritz!Box
# rebind protection, DoH and VPN clients all fail to resolve it - and a name
# that will not resolve is a transport error, which blanks the panel with no way
# for this app to explain itself. Hence cloud by default.
CLOUD_ROOT = "https://api.ui.com"
CONNECTOR_PATH = "/v1/connector/consoles/"
HOSTS_PATH = "/v1/hosts"

SOURCES = ("cloud", "local")

TTL_HOSTS = 3600
TTL_CAMERAS = 300
TTL_SNAPSHOT = 60
TTL_STATUS = 60

# How long the console the cameras were found on stays remembered. Long,
# because it only changes when hardware does, and because the alternative is
# re-running the scan below on every render.
TTL_HOST_MEMO = 21600

# How many consoles one render may ask for a camera list. The scan has to be
# allowed past the first - the account this was measured against answers with
# an empty list on the console the old code picked and three cameras two
# entries later - but the connector allows 100 requests a minute per console
# and the answer is memoed, so the budget stays small. A scan that runs out
# says so on the panel instead of guessing.
MAX_HOST_PROBES = 3

# A sensor event is treated as "happening now" for this long.
ALERT_WINDOW_SEC = 900

# How far back from the end of a snapshot the JPEG end-of-image marker is
# looked for.
EOI_WINDOW = 4096

WORDMARK = "UNIFI PROTECT"

# ---------------------------------------------------------------- scaling ---

def is2x():
    return canvas.is2x()

def px(n):
    """Scale a 1x pixel count to the current canvas."""
    if is2x():
        return n * 2
    return n

def font_tiny():
    if is2x():
        return "6x10"
    return "CG-pixel-3x5-mono"

def font_mid():
    if is2x():
        return "terminus-14"
    return "5x8"

def font_big():
    if is2x():
        return "10x20"
    return "6x10"

# Horizontal advance of one glyph, in real panel pixels, measured from the
# fonts pixlet ships. px() must NOT be used for these: at 2x the hero font
# goes 6 -> 10 and the tiny font 4 -> 6, not 12 and 8, so scaling the 1x
# numbers overestimates every string and the fitting maths comes out wrong.
def hero_advance():
    if is2x():
        return 10
    return 6

def tiny_advance():
    if is2x():
        return 6
    return 4

# ------------------------------------------------------------- safe access ---

def as_list(v):
    if type(v) == "list":
        return v
    return []

def as_dict(v):
    if type(v) == "dict":
        return v
    return {}

def as_text(v, fallback):
    if type(v) == "string" and v.strip() != "":
        return v.strip()
    return fallback

def as_num(v):
    """Return v as an int, or None if it isn't a usable number."""
    if type(v) == "int":
        return v
    if type(v) == "float":
        return int(v)
    return None

def epoch_seconds(v):
    """Normalize a UniFi timestamp (seconds or milliseconds) to seconds."""
    n = as_num(v)
    if n == None or n <= 0:
        return None
    if n > 100000000000:
        return n // 1000
    return n

# ------------------------------------------------------------------- text ---

# Every font on the panel is an ASCII bitmap: a Cyrillic, Greek or CJK name
# draws literally nothing, so "Двор" would render as an empty black strip that
# reads as a crash. Accented Latin drops the odd letter instead ("Café" ->
# "Caf"), which is quieter but just as wrong. Fold what folds, drop the rest,
# and fall back to a placeholder when nothing survives.
ASCII_PRINTABLE = (
    " !\"#$%&'()*+,-./0123456789:;<=>?@" +
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`" +
    "abcdefghijklmnopqrstuvwxyz{|}~"
)

TRANSLIT = {
    "À": "A",
    "Á": "A",
    "Â": "A",
    "Ã": "A",
    "Ä": "A",
    "Å": "A",
    "Ā": "A",
    "Ą": "A",
    "à": "a",
    "á": "a",
    "â": "a",
    "ã": "a",
    "ä": "a",
    "å": "a",
    "ā": "a",
    "ą": "a",
    "Æ": "AE",
    "æ": "ae",
    "Ç": "C",
    "Ć": "C",
    "Č": "C",
    "ç": "c",
    "ć": "c",
    "č": "c",
    "Ď": "D",
    "Đ": "D",
    "ď": "d",
    "đ": "d",
    "È": "E",
    "É": "E",
    "Ê": "E",
    "Ë": "E",
    "Ē": "E",
    "Ę": "E",
    "Ě": "E",
    "è": "e",
    "é": "e",
    "ê": "e",
    "ë": "e",
    "ē": "e",
    "ę": "e",
    "ě": "e",
    "Ì": "I",
    "Í": "I",
    "Î": "I",
    "Ï": "I",
    "Ī": "I",
    "ì": "i",
    "í": "i",
    "î": "i",
    "ï": "i",
    "ī": "i",
    "Ł": "L",
    "ł": "l",
    "Ñ": "N",
    "Ń": "N",
    "Ň": "N",
    "ñ": "n",
    "ń": "n",
    "ň": "n",
    "Ò": "O",
    "Ó": "O",
    "Ô": "O",
    "Õ": "O",
    "Ö": "O",
    "Ø": "O",
    "Ō": "O",
    "ò": "o",
    "ó": "o",
    "ô": "o",
    "õ": "o",
    "ö": "o",
    "ø": "o",
    "ō": "o",
    "Œ": "OE",
    "œ": "oe",
    "Ř": "R",
    "ř": "r",
    "Ś": "S",
    "Š": "S",
    "Ş": "S",
    "ś": "s",
    "š": "s",
    "ş": "s",
    "ß": "ss",
    "Ť": "T",
    "ť": "t",
    "Ù": "U",
    "Ú": "U",
    "Û": "U",
    "Ü": "U",
    "Ū": "U",
    "Ů": "U",
    "ù": "u",
    "ú": "u",
    "û": "u",
    "ü": "u",
    "ū": "u",
    "ů": "u",
    "Ý": "Y",
    "ý": "y",
    "ÿ": "y",
    "Ź": "Z",
    "Ż": "Z",
    "Ž": "Z",
    "ź": "z",
    "ż": "z",
    "ž": "z",
    "–": "-",
    "—": "-",
    "‑": "-",
    "·": ".",
    "…": "...",
    "“": "\"",
    "”": "\"",
    "‘": "'",
    "’": "'",
}

def panel_text(raw, fallback):
    """Fold a name down to glyphs the panel fonts actually draw.

    Anything with no ASCII equivalent becomes a space so words stay apart, and
    runs of spaces collapse, so a dropped glyph never leaves a visible gap.
    """
    if type(raw) != "string":
        return fallback
    out = ""
    for ch in raw.codepoints():
        if ch in ASCII_PRINTABLE:
            out += ch
        else:
            out += TRANSLIT.get(ch, " ")
    words = [w for w in out.split(" ") if w != ""]
    if len(words) == 0:
        return fallback
    return " ".join(words)

# ------------------------------------------------------------------- host ---

# Everything a legal URL host may contain. A character outside this set is not
# a DNS failure, it is a *parse* failure inside http.get, which aborts the
# render before a single packet leaves the device - the same uncatchable blank
# panel the IP check exists to pre-empt. A space ("my console.ui.direct") and a
# stray percent ("abc%zz.ui.direct") are the two that a human actually types.
HOST_CHARS = (
    "abcdefghijklmnopqrstuvwxyz" +
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ" +
    "0123456789.-_:[]"
)

def clean_host(raw):
    """Normalize a user-entered console address.

    Returns (scheme, host, problem) where problem is None, "empty", "ip",
    "mdns" or "bad". A bare IPv4 literal or a .local name can never present a
    publicly valid certificate, and a TLS failure aborts the render
    uncatchably, so we catch those up front. An explicit http:// is honoured as
    a deliberate plain-HTTP reverse-proxy setup and is never rejected.
    """
    h = raw.strip()
    if h == "":
        return ("https://", "", "empty")

    scheme = "https://"
    lowered = h.lower()
    if lowered.startswith("http://"):
        scheme = "http://"
        h = h[7:]
    elif lowered.startswith("https://"):
        h = h[8:]

    h = h.split("/")[0].strip()
    if h == "":
        return (scheme, "", "empty")

    for ch in h.codepoints():
        if ch not in HOST_CHARS:
            return (scheme, h, "bad")

    # ":80x" is another parse abort, so the port has to be checked too. An
    # IPv6 literal ends in "]" and its colons are part of the address.
    colon = h.rfind(":")
    if colon >= 0 and not h.endswith("]"):
        port = h[colon + 1:]
        if port == "" or not port.isdigit():
            return (scheme, h, "bad")

    if scheme == "http://":
        return (scheme, h, None)

    bare = h.split(":")[0]
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

# --------------------------------------------------------------- base url ---

# Everything below this line is shared by both modes. The two builders here are
# the entire difference between them: they produce a string that the Protect
# API path is appended to, and no other function in this file knows or cares
# which transport it is talking over.

def local_base(scheme, host):
    """Protect on the console itself: https://console/proxy/protect/..."""
    return scheme + host + API_PATH

def cloud_base(root, host_id):
    """Protect via the Site Manager Cloud Connector.

    The connector's {path} parameter INCLUDES the /proxy/... prefix - the
    official example is /proxy/network/integration/v1/sites - so the console's
    own path is appended whole rather than stripped.
    """
    return root + CONNECTOR_PATH + host_id + API_PATH

# Host ids are hex with colon separators. Anything else would be a URL *parse*
# failure inside http.get, which aborts the render before a packet is sent, so
# an id we do not recognise is refused rather than concatenated.
ID_CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:-_."

def usable_id(v):
    if type(v) != "string" or v == "":
        return False
    for ch in v.codepoints():
        if ch not in ID_CHARS:
            return False
    return True

# The only addresses the console field may point cloud mode at. The cloud key
# is account-wide, so it must never be handed to anything but api.ui.com: the
# console field is labelled local-mode-only, a user who set local mode up first
# still has their console address sitting in it, and switching to cloud must
# not quietly ship the unifi.ui.com key to that box - in cleartext, if the
# address was the plain-HTTP reverse proxy local mode allows. A loopback
# literal cannot be anybody's console, so it leaves the mock server reachable
# for testing and nothing else. Every other value is ignored, not carded: it is
# a leftover from the other mode, not a mistake the user made in this one.
LOOPBACK = ("127.0.0.1", "localhost", "[::1]", "::1")

def bare_host(h):
    """The host without its port. An IPv6 literal's own colons are not a port."""
    if h.startswith("["):
        end = h.find("]")
        if end > 0:
            return h[0:end + 1]
        return h
    return h.split(":")[0]

def cloud_root(host_raw):
    """The cloud API root: api.ui.com, or a loopback test override."""
    h = host_raw.strip()
    if not h.lower().startswith("http://"):
        return CLOUD_ROOT
    scheme, host, problem = clean_host(h)
    if problem != None:
        return CLOUD_ROOT
    if bare_host(host).lower() not in LOOPBACK:
        return CLOUD_ROOT
    return scheme + host

# ------------------------------------------------------------------ cards ---

def header_band(w):
    return render.Column(
        children = [
            render.Padding(
                pad = (px(1), px(1), 0, 0),
                child = render.Text(WORDMARK, font = font_tiny(), color = BLUE),
            ),
            render.Box(width = w, height = px(1), color = RULE),
        ],
    )

def card(title, title_color, detail):
    """A framed message: wordmark, rule, the reason, one dim detail line.

    Titles are app constants short enough to wrap to at most two lines. The
    detail is caller data of any length, so it goes in a Marquee: that pins it
    to exactly one line, which is all that is left under a two-line title, and
    scrolls the rest instead of wrapping off the bottom of the panel.
    """
    w = canvas.width()
    body = [
        render.WrappedText(
            content = title,
            font = font_mid(),
            color = title_color,
            width = w - px(3),
            align = "left",
        ),
    ]
    if detail != "":
        body.append(render.Box(width = px(1), height = px(2)))
        body.append(
            render.Marquee(
                width = w - px(3),
                align = "start",
                child = render.Text(detail, font = font_tiny(), color = DIM),
            ),
        )

    return render.Root(
        child = render.Column(
            expanded = True,
            children = [
                header_band(w),
                render.Padding(
                    pad = (px(2), px(1), px(1), 0),
                    child = render.Column(
                        expanded = True,
                        main_align = "center",
                        children = body,
                    ),
                ),
            ],
        ),
    )

def status_card(code):
    """A failure Protect itself reported (or the console in front of it)."""
    if code == 401:
        return card("BAD API KEY", RED, "check the key")
    if code == 403:
        return card("KEY LACKS ACCESS", RED, "check key scope")
    if code == 404:
        return card("NOT FOUND", AMBER, "is Protect on?")
    return card("HTTP %d" % code, AMBER, "console said no")

def connector_card(env):
    """A failure the *cloud connector* reported, before Protect was reached.

    Kept separate from status_card because the two mean different things to the
    person fixing it: a 404 here is "no such console on this account", not "no
    such camera", and the connector hands us a human-readable message to show
    instead of a guess. The message is server data, so it is folded to glyphs
    the panel can draw.
    """
    code, msg = env
    detail = panel_text(msg, "the cloud said no")
    if code == 401:
        return card("BAD API KEY", RED, detail)
    if code == 403:
        return card("KEY LACKS ACCESS", RED, detail)
    if code == 404:
        return card("NO CONSOLE", AMBER, detail)
    if code == 429:
        return card("RATE LIMITED", AMBER, detail)
    if code == 502 or code == 503 or code == 504:
        return card("CONSOLE OFFLINE", RED, detail)
    return card("CLOUD %d" % code, AMBER, detail)

# ------------------------------------------------------------------- http ---

def ui_get(base, key, path, ttl, params = {}):
    """One authenticated GET against a UniFi API - either transport, either API.

    X-API-Key is the spelling in the Site Manager spec and X-API-KEY the one in
    the Protect spec; HTTP header names are case-insensitive, so a single header
    serves both and the base URL stays the only difference between modes.
    """
    return http.get(
        base + path,
        headers = {"X-API-KEY": key, "Accept": "application/json"},
        params = params,
        ttl_seconds = ttl,
    )

def connector_error(resp):
    """The connector's own {code,httpStatusCode,message,traceId}, or None.

    The connector proxies Protect's response through untouched when it reaches
    it, and substitutes this envelope when it does not. Protect's own bodies
    are either an array or an object with no code/message pair, and the cloud's
    successful list responses carry `data`, so a string code+message with no
    `data` is what tells an envelope apart from everything else we can receive.
    Status code alone cannot: both layers answer 404.
    """
    if not is_json(resp):
        return None
    body = resp.json()
    if type(body) != "dict" or "data" in body:
        return None
    code = body.get("code")
    msg = body.get("message")
    if type(code) != "string" or type(msg) != "string":
        return None
    return (as_num(body.get("httpStatusCode")) or resp.status_code, msg)

def transport_error(cloud, resp):
    """connector_error, but only where a connector actually exists.

    In local mode the app talks to Protect directly, with nothing in front of
    it that could speak that envelope. A local body that happens to carry a
    code/message pair - a reverse proxy answering 404 with
    {"code":"NOT_FOUND","message":"no route"} - is not a connector failure, and
    narrating it as "NO CONSOLE" or "RATE LIMITED" describes a cloud the user
    is not using while hiding the local guidance they need.
    """
    if not cloud:
        return None
    return connector_error(resp)

def is_json(resp):
    """resp.json() raises on a body it cannot parse, and a raise blanks the panel.

    The content type alone is not enough: a console restarting behind a proxy
    answers 200 with Content-Type: application/json and Content-Length: 0, and
    an empty or half-written body raises just as hard as an HTML login page
    does. So the body is checked for structural completeness too.
    """
    ctype = as_dict(resp.headers).get("Content-Type", "")
    if type(ctype) != "string" or "json" not in ctype.lower():
        return False

    b = resp.body().strip()
    if b.startswith("{") and b.endswith("}"):
        return True
    return b.startswith("[") and b.endswith("]")

# ------------------------------------------------------------------ hosts ---

def host_names(h):
    """Every name this console is known by, for matching the console setting.

    userData.name is null on every host this account can see, so the labels a
    person would actually recognise all live under reportedState: the console
    name ("Dream Wall"), the hostname, and the hardware's own long and short
    names ("UniFi Dream Wall", "UDW"). All of them are offered.
    """
    ud = as_dict(h.get("userData"))
    rs = as_dict(h.get("reportedState"))
    hw = as_dict(rs.get("hardware"))
    out = []
    for v in [
        ud.get("name"),
        rs.get("name"),
        rs.get("hostname"),
        hw.get("name"),
        hw.get("shortname"),
        h.get("ipAddress"),
    ]:
        if type(v) == "string" and v.strip() != "":
            out.append(v.strip().lower())
    return out

def app_supported(entry):
    """Is an applications[] entry a console that can run this app?

    The object form of `applications` lists EVERY application the platform
    knows about, keyed by name, each with {owned, required, supported} - the
    Site Manager spec's own example carries protect on a console whose
    userData.apps is just ["users"]. So the key being present says nothing;
    only `supported: false` is a positive "not this hardware". `owned` is not
    usable for this: the same example has owned:false on `network`, which is
    also marked required:true, on a console that plainly runs it.
    """
    if type(entry) != "dict":
        return True
    return entry.get("supported") != False

def controller_protect_state(c):
    """True / False / None for one reportedState.controllers[] entry."""
    if type(c) != "dict":
        return None
    name = c.get("name")
    if type(name) != "string" or name.lower() != "protect":
        return None
    if c.get("isRunning") == True or c.get("state") == "active":
        return True
    if c.get("isInstalled") == False or c.get("installState") == "uninstalled":
        return False
    return None

def host_protect_hint(h):
    """True / False / None for "Protect runs here" - a RANKING hint only.

    Never an exclusion, and never a card. The field the Site Manager spec
    points at, userData.consoleGroupMembers[].roleAttributes.applications, is
    an EMPTY dict on every host this account can see - including a Dream Wall
    running Protect 7.2.105 with three connected cameras - and all of them
    report role "UNADOPTED". An empty dict is not an absence, so nothing in
    the host record may turn into "Protect is missing" on the panel. Only the
    Protect endpoint's own answer is allowed to say that.

    reportedState.controllers[] is the field that was right on all five
    consoles measured: {name, state, installState, isInstalled, isRunning} per
    application, with protect active and installed exactly where Protect
    answers. It leads, and `applications` stays behind it as a positive-only
    hint for firmware that fills it in.
    """
    rs = as_dict(h.get("reportedState"))
    for c in as_list(rs.get("controllers")):
        state = controller_protect_state(c)
        if state != None:
            return state

    ud = as_dict(h.get("userData"))
    for member in as_list(ud.get("consoleGroupMembers")):
        apps = as_dict(as_dict(member).get("roleAttributes")).get("applications")

        if type(apps) == "dict":
            for name in apps.keys():
                if type(name) != "string":
                    continue
                if name.lower() == "protect" and app_supported(apps[name]):
                    return True
        elif type(apps) == "list":
            for name in apps:
                if type(name) == "string" and name.lower() == "protect":
                    return True
    return None

def openable(h):
    """Can this key open this console at all?

    A cloud key reaches only the consoles its owner owns. Both `owner: false`
    consoles on the account this was measured against answered every connector
    request with 403 "user is not the owner of this host" - they are not worse
    candidates, they are consoles that can never answer, and spending a probe
    on one costs a console that could have. A blocked console is the same kind
    of dead end. Only an explicit false counts: a firmware that omits the field
    must not have its consoles thrown away.
    """
    return h.get("owner") != False and h.get("isBlocked") != True

def reachable(hosts):
    """The candidates worth spending the probe budget on.

    Filtering rather than ranking, because these consoles do not merely sort
    badly - they cannot be checked, so their refusal must not outrank what a
    console that DID answer said. Naming "Dream Machine" on the live account
    matches the owner's own UDM Pro and a stranger's UDM Pro (the model's long
    name is one of the names a console is known by); scanning both turned an
    honest empty camera list into "KEY LACKS ACCESS", which sends the user
    looking for a permissions problem they do not have.

    If the filter would empty the list it is dropped instead: a console the key
    cannot open is still the console the user asked about, and the 403's own
    wording explains that far better than "no such console" would.
    """
    out = []
    for h in hosts:
        if openable(h):
            out.append(h)
    if len(out) == 0:
        return hosts
    return out

def host_priority(h):
    """Rank for the scan below. Lower is asked first.

    A console the cloud reports as not connected goes to the back, because a
    console that is down cannot answer either - but a rank and not a filter,
    since this field is the cloud's last known state and a console that has
    just come back is still worth asking. Under that, one whose controllers report Protect
    running comes ahead of one that says nothing, which comes ahead of one
    that says Protect is uninstalled - and even that last group is still
    asked, because being wrong about it is exactly the bug this ordering
    exists to stop repeating. Ownership stays in the key for the case where
    every candidate is unowned and reachable() had to hand them all back.
    """
    if openable(h):
        owner = 0
    else:
        owner = 1

    state = as_dict(h.get("reportedState")).get("state")
    if type(state) == "string" and state.lower() != "connected":
        live = 1
    else:
        live = 0

    hint = host_protect_hint(h)
    if hint == True:
        rank = 0
    elif hint == None:
        rank = 1
    else:
        rank = 2
    return (owner, live, rank)

def rank_key(entry):
    """(priority, original index) - the host itself is never compared."""
    return (entry[0], entry[1])

def scan_order(hosts):
    """The hosts, best candidate first, ties in the order the cloud sent them."""
    ranked = []
    for i in range(len(hosts)):
        ranked.append((host_priority(hosts[i]), i, hosts[i]))

    out = []
    for entry in sorted(ranked, key = rank_key):
        out.append(entry[2])
    return out

def pick_hosts(hosts, wanted):
    """Every console the console setting names.

    A list rather than one console, because the names are not unique either:
    this account has two consoles both called "Video Recorder", one of which
    the key cannot open at all. Returning the first match handed the user a
    FORBIDDEN card while the other one sat there with four cameras on it.
    """
    needle = wanted.strip().lower()
    out = []
    for h in hosts:
        for name in host_names(h):
            if needle in name:
                out.append(h)
                break
    return out

# ------------------------------------------------------------ host memory ---

def memo_key(key, needle):
    """Cache key for the console this account's camera was last found on.

    The cache is shared by every render of this app on a server, so the key has
    to name the account - otherwise one person's console id is handed to
    another person's render, whose key cannot open it. It must not BE the API
    key either: the key is hashed and cut to 16 hex characters, which is plenty
    to keep two accounts apart and carries nothing back towards the secret.

    The camera query is hashed in alongside it because the answer depends on
    it: on the account this was measured against "Front Door" is on the UNVR
    and everything else is on the Dream Wall, so one memo per account would
    have the two configurations overwriting each other's answer every minute.
    """
    return "protect-console/" + hash.sha256(key + "\n" + needle)[0:16]

def remembered_first(order, key, needle):
    """The scan order with the last known good console moved to the front."""
    memo = cache.get(memo_key(key, needle))
    if type(memo) != "string" or memo == "":
        return order

    front = []
    rest = []
    for h in order:
        if h["id"] == memo:
            front.append(h)
        else:
            rest.append(h)
    return front + rest

# ------------------------------------------------------------- resolution ---

def no_cameras_card(count):
    """"No cameras" once it is a fact about every console that was asked."""
    if count < 2:
        return card("NO CAMERAS", AMBER, "none on this console")
    return card("NO CAMERAS", AMBER, "none on your consoles")

def host_label(h):
    """The name to put on the panel for one console.

    userData.name is null on every host this account can see, so the label a
    person recognises comes from reportedState - the console's own name first,
    then its hostname, then the hardware's long and short names.
    """
    rs = as_dict(h.get("reportedState"))
    hw = as_dict(rs.get("hardware"))
    for v in [
        as_dict(h.get("userData")).get("name"),
        rs.get("name"),
        rs.get("hostname"),
        hw.get("name"),
        hw.get("shortname"),
    ]:
        if type(v) == "string" and v.strip() != "":
            return panel_text(v, "console").upper()
    return "CONSOLE"

def console_scope(hosts, chosen):
    """The disclaimer line for a board that covers one console out of several.

    Empty when there is nothing to disclaim: one candidate console, or a local
    console, is the whole of what the user pointed this app at. With more than
    one it is not, and the status board's "3/3 CAMS - ALL CLEAR" would
    otherwise read as a claim about the account. It is a claim about one
    console, so the panel says which one and how many it did not look at.
    """
    if len(hosts) < 2:
        return ""
    return "1 OF %d CONSOLES: %s" % (len(hosts), host_label(chosen))

def console_serves(cams, wanted):
    """Can this console answer for the camera the setting names?

    The same resolution the panel will run, so a console is only accepted when
    it holds the camera that is actually going to be drawn - an out-of-range
    "#3" among two matches is a miss here exactly as it is there.
    """
    return pick_camera(ordered_cameras(cams), wanted) >= 0

def scan_hosts(root, key, hosts, memo, wanted):
    """Walk consoles looking for the wanted camera. Returns (id, cams, card, scope).

    hosts[0] is not an answer to "which console has the cameras". On the
    account this was measured against it is a Dream Machine Pro running
    Protect with nothing adopted to it, while the Dream Wall one entry later
    has three connected cameras - so taking the first host printed NO CAMERAS
    at a house full of them.

    Stopping at the first console that has ANY camera is the same mistake one
    step further in. On that account the Dream Wall answers second with three
    cameras and the walk ended there, while the owned UNVR two entries later
    holds "Front Door", "Side of House" and two called "Backyard" - so asking
    for Front Door printed NO MATCH at a camera that was connected and on the
    user's own console. What the scan is looking for is the camera the config
    names; a console with cameras but not that one is only the fallback.
    """
    order = scan_order(hosts)
    if memo:
        order = remembered_first(order, key, wanted)

    budget = MAX_HOST_PROBES
    if len(order) < budget:
        budget = len(order)

    empties = 0
    absents = 0
    first_failure = None
    fallback = None
    fallback_cams = []
    for i in range(budget):
        h = order[i]
        cams, failed, absent = fetch_cameras(True, cloud_base(root, h["id"]), key)
        if absent:
            absents += 1
        elif failed != None:
            if first_failure == None:
                first_failure = failed
        elif len(cams) > 0:
            if console_serves(cams, wanted):
                if memo:
                    cache.set(
                        memo_key(key, wanted),
                        h["id"],
                        ttl_seconds = TTL_HOST_MEMO,
                    )
                return (h["id"], cams, None, console_scope(order, h))
            if fallback == None:
                fallback = h
                fallback_cams = cams
        else:
            empties += 1

    if fallback != None:
        # Cameras exist, just not the one that was asked for. Saying so is only
        # honest once every console has been asked; until then the panel hands
        # back the console it did find, which draws the same NO MATCH card
        # scoped to that console rather than to an account it did not read.
        if budget < len(order):
            return ("", [], budget_card(budget, len(order)), "")
        return (
            fallback["id"],
            fallback_cams,
            None,
            console_scope(order, fallback),
        )

    # Nothing answered at all: the failure is the story, not the cameras.
    if empties == 0 and absents == 0 and first_failure != None:
        return ("", [], first_failure, "")

    if budget == len(order):
        # Every console on the account was asked. Only now is "no cameras" a
        # fact rather than an assumption about the one console we happened to
        # look at - and a console that errored could still be hiding some, so
        # its error still outranks the all-clear. A console that does not run
        # Protect at all ranks under one that does and simply has nothing
        # adopted: "adopt a camera" is the more useful of the two answers when
        # both are true of the account.
        if first_failure != None:
            return ("", [], first_failure, "")
        if empties > 0:
            return ("", [], no_cameras_card(len(order)), "")
        return ("", [], no_protect_card(len(order)), "")

    # The budget ran out first. Say so, rather than claiming an absence for
    # consoles that were never asked.
    return ("", [], budget_card(budget, len(order)), "")

def budget_card(asked, total):
    """The scan stopped short. What it did not ask, it does not claim."""
    return card("SET CONSOLE", BLUE, "checked %d of %d consoles" % (asked, total))

def resolve_cloud(root, key, console, wanted):
    """Cloud mode, from an API key to a console with the wanted camera on it.

    Returns (host_id, cams, card, scope): a non-None card is a finished panel
    to draw instead, so every failure below is a card rather than a raised
    error. The cameras come back with the console because finding one is what
    proves the other - they are the same request.
    """
    resp = ui_get(root, key, HOSTS_PATH, TTL_HOSTS)

    env = connector_error(resp)
    if env != None:
        return ("", [], connector_card(env), "")

    # A failure here is the cloud's, never Protect's - nothing has reached the
    # console yet - so it gets the cloud wording even when the body is not the
    # envelope. api.ui.com answers an unrecognised route with a bare text/plain
    # "404 page not found", which lands exactly here.
    if resp.status_code != 200:
        return ("", [], connector_card((resp.status_code, "")), "")
    if not is_json(resp):
        return ("", [], card("BAD REPLY", AMBER, "not the UniFi cloud"), "")

    hosts = []
    for h in as_list(as_dict(resp.json()).get("data")):
        if type(h) == "dict" and usable_id(h.get("id")):
            hosts.append(h)
    if len(hosts) == 0:
        return ("", [], card("NO CONSOLES", AMBER, "none on this account"), "")

    needle = console.strip()
    if needle == "":
        return scan_hosts(root, key, reachable(hosts), True, wanted)

    # A named console is not memoed: the setting already says which one, and
    # remembering a different answer would only fight it.
    named = pick_hosts(hosts, needle)
    if len(named) == 0:
        return (
            "",
            [],
            card("NO MATCH", AMBER, panel_text(needle, "no such console")),
            "",
        )
    return scan_hosts(root, key, reachable(named), False, wanted)

# ---------------------------------------------------------------- cameras ---

def raw_name(cam):
    """The name as Protect stores it - used for matching, not for drawing."""
    return as_text(cam.get("name"), "Camera")

def camera_name(cam):
    """The name as the panel can draw it."""
    return panel_text(raw_name(cam), "Camera")

def is_connected(cam):
    return cam.get("state", "") == "CONNECTED"

def clean_cameras(raw):
    """Cameras we can actually build a snapshot URL for.

    The id is interpolated into that URL, so it gets the same character check
    the cloud host id gets, and for the same reason: a character http.get
    cannot parse (a stray percent, a space) is not a request that fails, it is
    a render that aborts before any request is made, leaving a blank panel with
    no card. Protect's own ids are hex, so this only bites through a proxy or a
    future id format - and dropping the record is what keeps that a card.
    """
    out = []
    for cam in as_list(raw):
        if type(cam) != "dict":
            continue
        if not usable_id(cam.get("id")):
            continue
        out.append(cam)
    return out

def camera_sort_key(cam):
    """The id, then the name for the ids-collide case that should not happen."""
    return (as_text(cam.get("id"), ""), raw_name(cam).lower())

def ordered_cameras(cams):
    """A fixed order, whatever order Protect listed them in.

    Protect does not promise one, and both things below have to survive a
    reshuffle: "the first connected camera" must keep naming the same camera
    every minute, and the "(1/2)" a duplicate name is drawn with must keep
    pointing at the same physical device. Sorting on the id rather than the
    name is what makes that hold through a rename or a newly adopted camera
    too - the id is the only field on the record that never moves. It also
    happens to reproduce the order Protect already lists them in, because
    these ids are creation-ordered.
    """
    return sorted(cams, key = camera_sort_key)

def display_labels(cams):
    """One panel label per camera, numbered where a name is not unique.

    Duplicate names are not hypothetical: the account this was measured
    against has two cameras called exactly "G4 Instant" and, on another
    console, two called "Backyard". A panel that just says G4 INSTANT is
    asserting something it cannot know - which of the two - so a shared name
    is drawn as "G4 Instant (1/2)". The user can see both that there are two
    of them and which one they are looking at.
    """
    counts = {}
    for cam in cams:
        label = camera_name(cam)
        counts[label] = counts.get(label, 0) + 1

    seen = {}
    out = []
    for cam in cams:
        label = camera_name(cam)
        total = counts[label]
        if total < 2:
            out.append(label)
            continue
        n = seen.get(label, 0) + 1
        seen[label] = n
        out.append("%s (%d/%d)" % (label, n, total))
    return out

def parse_camera_query(raw):
    """Split "g4 instant #2" into ("g4 instant", 2); 0 means unspecified.

    A name alone cannot single out one of two cameras that share it, so the
    setting needs a way to say which - and the panel has already numbered them
    "(2/2)", so the number is the thing the user has in front of them.
    """
    q = raw.strip()
    at = q.rfind("#")
    if at < 0:
        return (q.lower(), 0)

    tail = q[at + 1:].strip()
    if tail == "" or not tail.isdigit():
        return (q.lower(), 0)
    n = int(tail)
    if n < 1:
        return (q.lower(), 0)
    return (q[0:at].strip().lower(), n)

def camera_matches(cams, needle):
    """Indexes of the cameras a query names, best kind of match only.

    An exact name beats a substring one, so a camera called "Drive" stays
    reachable on a console that also has a "Driveway" - under a plain
    substring sweep the longer name can shadow the shorter one forever.
    """
    out = []
    if needle == "":
        for i in range(len(cams)):
            out.append(i)
        return out

    exact = []
    partial = []
    for i in range(len(cams)):
        name = raw_name(cams[i]).lower()
        if name == needle:
            exact.append(i)
        elif needle in name:
            partial.append(i)
    if len(exact) > 0:
        return exact
    return partial

def pick_camera(cams, raw):
    """The index of the camera to draw, or -1 when the query matched nothing.

    Deterministic the whole way down: the list is already in a fixed order, an
    exact name outranks a substring, #N picks among equals, and a connected
    camera outranks a disconnected one. An out-of-range #N is a miss rather
    than a quiet fall back to the first match - being shown a different camera
    from the one you asked for is the exact failure this path exists to avoid.
    """
    needle, want = parse_camera_query(raw)
    matches = camera_matches(cams, needle)
    if len(matches) == 0:
        return -1

    if want > 0:
        if want > len(matches):
            return -1
        return matches[want - 1]

    for i in matches:
        if is_connected(cams[i]):
            return i
    return matches[0]

# ------------------------------------------------------- the camera list ---

# The connector's own wording for "that application is not on this console".
# Measured 2026-09-01 against a real owned console whose controllers report
# access installState "uninstalled":
#   403 {"code":"forbidden","httpStatusCode":403,
#        "message":"insufficient permissions for this endpoint"}
# An ownership failure on the same connector is the same status and the same
# envelope shape, and differs only in its sentence:
#   403 {... "message":"forbidden: access denied: user is not the owner of this host"}
# so the message is the only thing that tells them apart.
NOT_INSTALLED_MSG = "insufficient permissions for this endpoint"

def missing_application(env):
    """True when a connector 403 means Protect is not on that console.

    Worth splitting because the two 403s send the user to opposite places. The
    connector answers a request for an application the console does not run
    with the envelope above - never with Protect's own 404, which is
    {"error":"Entity 'endpoint' not found","name":"NOT_FOUND"} and was until
    now the only thing the NO PROTECT card fired on. So in cloud mode the most
    ordinary first-run failure there is - a UDM or UDR that runs Network but
    not Protect - was diagnosed as KEY LACKS ACCESS, and the user was sent to
    regenerate a key that was never the problem.
    """
    code, msg = env
    if code != 403:
        return False
    return NOT_INSTALLED_MSG in msg.lower()

def no_protect_card(count):
    """"Protect is not here" once it is a fact about every console asked."""
    if count < 2:
        return card("NO PROTECT", AMBER, "not on this console")
    return card("NO PROTECT", AMBER, "not on your consoles")

def fetch_cameras(cloud, base, key):
    """GET /cameras from one console. Returns (cams, card, absent).

    A non-None card is a finished panel. An empty list with no card is a
    console that answered and genuinely has nothing adopted to it - the only
    thing that is ever allowed to become "no cameras" on the display.

    `absent` is True when the console answered that Protect is not installed
    there at all. It is reported separately from an ordinary failure because
    during a scan the two rank differently: a console that errored could still
    be hiding cameras, while one without Protect never will.
    """
    resp = ui_get(base, key, "/cameras", TTL_CAMERAS)

    env = transport_error(cloud, resp)
    if env != None:
        if missing_application(env):
            return ([], no_protect_card(1), True)
        return ([], connector_card(env), False)

    # Direct evidence, and the only kind accepted for this claim: Protect
    # itself is not answering at this path. Nothing in the host record may say
    # it, because on real firmware the host record does not know.
    if resp.status_code == 404:
        return ([], no_protect_card(1), True)
    if resp.status_code != 200:
        return ([], status_card(resp.status_code), False)
    if not is_json(resp):
        return ([], card("BAD REPLY", AMBER, "not Protect API"), False)
    return (clean_cameras(resp.json()), None, False)

# --------------------------------------------------------------- snapshot ---

def looks_like_image(resp):
    """True only for a body we know render.Image can decode.

    A decode failure aborts the render uncatchably, so anything that is not a
    complete JPEG - an HTML login page served with the wrong content type, or
    a body a proxy cut short - has to be rejected before it reaches
    render.Image. Both ends are checked: a truncated snapshot keeps a perfectly
    good header and dies inside the decoder ("short Huffman data").
    """
    ctype = as_dict(resp.headers).get("Content-Type", "")
    if type(ctype) != "string" or "image" not in ctype.lower():
        return False

    body = resp.body()
    n = len(body)
    if n < 128:
        return False

    # JPEG start-of-image marker: FF D8.
    head = list(body[0:2].elem_ords())
    if head[0] != 255 or head[1] != 216:
        return False

    # JPEG end-of-image marker: FF D9. Some encoders pad after it, so scan the
    # tail rather than insisting on the very last two bytes - backwards, so
    # that the marker found is the file's own and not one belonging to an
    # embedded thumbnail that happens to fall inside the window.
    #
    # The window used to be 64 bytes, which is not what "tolerate padding"
    # means: this account's G3 Flex returns a 98 KB snapshot, and appending
    # 200 harmless bytes to it - fewer than a single EXIF block - pushed the
    # marker out of range and rendered NO IMAGE over a JPEG pixlet decodes
    # perfectly well. A few KB covers any trailer anyone has been seen to add
    # and still costs a few thousand comparisons only on the reject path,
    # where a body with no marker at all is what the guard is for.
    start = n - EOI_WINDOW
    if start < 0:
        start = 0
    tail = list(body[start:].elem_ords())
    for i in range(len(tail) - 1):
        j = len(tail) - 2 - i
        if tail[j] == 255 and tail[j + 1] == 217:
            return True
    return False

def name_strip(w, label, accent):
    return render.Stack(
        children = [
            render.Column(
                children = [
                    render.Box(width = w, height = px(1), color = accent),
                    render.Box(width = w, height = px(7), color = SCRIM),
                ],
            ),
            render.Padding(
                pad = (px(2), px(2), px(1), 0),
                child = render.Marquee(
                    width = w - px(3),
                    align = "start",
                    child = render.Text(label, font = font_tiny(), color = WHITE),
                ),
            ),
        ],
    )

# The snapshot qualities this app will ask for, best first. "true" is
# deliberately not among them: a full-HD request answers HTTP 400
# {"error":"Camera does not support full HD snapshot"} on hardware that cannot
# make one - measured on a G4 Instant - and it buys nothing anyway, because the
# default is already 640x360 against a panel whose longest edge is 128. It is a
# list rather than a constant so that a quality the camera rejects falls
# through to the next one instead of carding: anything added here degrades by
# construction rather than by somebody remembering to write the fallback.
SNAPSHOT_QUALITY = ["false"]

def fetch_snapshot(cloud, base, key, cam_id):
    """The best snapshot this camera will actually produce."""
    resp = None
    for quality in SNAPSHOT_QUALITY:
        resp = ui_get(
            base,
            key,
            "/cameras/%s/snapshot" % cam_id,
            TTL_SNAPSHOT,
            params = {"highQuality": quality},
        )
        if transport_error(cloud, resp) != None:
            return resp
        if resp.status_code != 400:
            return resp
    return resp

def protect_reason(resp, fallback):
    """Protect's own wording for a refusal.

    Its error bodies are {"error": ..., "name": "BAD_REQUEST"} - `error` and
    `name`, not the connector's `code` and `message` - so they never look like
    an envelope, and their one readable sentence would otherwise be thrown
    away in favour of a bare status number.
    """
    if not is_json(resp):
        return fallback
    body = resp.json()
    if type(body) != "dict":
        return fallback
    return panel_text(as_text(body.get("error"), fallback), fallback)

def snapshot_view(cloud, base, key, cam, label):
    w, h = canvas.size()

    resp = fetch_snapshot(cloud, base, key, cam["id"])

    # The connector's own envelope is checked before the 503, because both
    # layers use that code and they mean different things: the connector's 503
    # is a console it could not reach, Protect's is a camera that is down.
    env = transport_error(cloud, resp)
    if env != None:
        return connector_card(env)
    if resp.status_code == 503:
        return card("CAMERA OFFLINE", RED, label)

    # Every quality was refused. Protect explains these in words ("Camera does
    # not support full HD snapshot"), and its sentence beats "HTTP 400".
    if resp.status_code == 400:
        return card("NO SNAPSHOT", AMBER, protect_reason(resp, label))
    if resp.status_code != 200:
        return status_card(resp.status_code)
    if not looks_like_image(resp):
        return card("NO IMAGE", AMBER, label)

    accent = BLUE
    if not is_connected(cam):
        accent = AMBER

    return render.Root(
        child = render.Stack(
            children = [
                render.Box(width = w, height = h, color = BLACK),
                render.Row(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [render.Image(src = resp.body(), height = h)],
                ),
                render.Column(
                    expanded = True,
                    main_align = "end",
                    children = [name_strip(w, label, accent)],
                ),
            ],
        ),
    )

# ----------------------------------------------------------------- status ---

# Arm state is a badge, not the hero, because most Protect installs never turn
# the alarm on. A breach is the exception and takes the whole panel over.
# Each entry is (wordings longest-first, colour): the row shrinks the wording
# before it will let it overflow, and drops it to the ticker if even the
# shortest will not fit.
ARM_BADGES = {
    "armed": (["ARMED"], GREEN),
    "arming": (["ARMING"], AMBER),
    "breach": (["BREACH"], RED),
    # No three-letter "OFF" fallback: under the DIM "CAMS" label it reads as
    # "CAMS OFF". When neither wording fits, the row drops the alarm badge and
    # keeps the label - disabled is the state most installs sit in forever, so
    # saying nothing about it is honest. Armed and arming spill to the ticker.
    "disabled": (["ALARM OFF", "UNARMED"], DIM),
    # The NVR did not answer, or did not answer with JSON. Not the same thing
    # as disabled, and it must not be drawn as it: "ALARM OFF" under a green
    # ALL CLEAR while the alarm is actually in breach is the worst thing this
    # panel could say.
    "unknown": (["ALARM ?"], DIM),
}

ARM_TICKERS = {
    "armed": ("ALARM ARMED", GREEN),
    "arming": ("ALARM ARMING", AMBER),
}

# The arm states this app has wording for - Protect's own enum. A status
# outside it is treated as unread rather than drawn as nothing: "unknown" is
# in ARM_BADGES and says ALARM ?, whereas an unrecognised string silently
# produces no badge at all, which is indistinguishable from a disabled alarm.
ARM_STATES = ("armed", "arming", "breach", "disabled")

def sensor_battery_low(sensor):
    wireless = as_dict(as_dict(sensor.get("wirelessConnectionState")).get("batteryStatus"))
    if wireless.get("isLow") == True:
        return True
    return as_dict(sensor.get("batteryStatus")).get("isLow") == True

def sensor_connected(sensor):
    """False only when the sensor itself says it is not on the network.

    UP Sense reports `state` the way a camera does, and a sensor that has
    fallen off keeps serving its last known isOpened - so an unqualified
    "3 SENSORS OK" can be counting a door that nothing has heard from in a
    week. Only an explicit non-CONNECTED string counts: firmware that omits
    the field must not have its sensors written off as unreachable.
    """
    state = sensor.get("state")
    if type(state) != "string" or state.strip() == "":
        return True
    return state.strip().upper() == "CONNECTED"

def sensor_alerts(sensors, now):
    """Roll a sensor list up into (opens, leaks, low, unreachable, quiet).

    An unreachable sensor still contributes its alerts - a leak detector that
    reported water and then died is the one thing on this panel that must not
    go quiet - but it is never counted as OK, because nothing has confirmed
    that it is.
    """
    opens = []
    leaks = []
    low = []
    away = []
    quiet = 0
    for sensor in sensors:
        if type(sensor) != "dict":
            continue
        label = panel_text(as_text(sensor.get("name"), "Sensor"), "Sensor").upper()
        flagged = False
        if sensor.get("isOpened") == True:
            opens.append(label)
            flagged = True
        leak_at = epoch_seconds(sensor.get("leakDetectedAt"))
        if leak_at != None and now - leak_at < ALERT_WINDOW_SEC:
            leaks.append(label)
            flagged = True
        if sensor_battery_low(sensor):
            low.append(label)
            flagged = True

        if not sensor_connected(sensor):
            away.append(label)
        elif not flagged:
            quiet += 1
    return (opens, leaks, low, away, quiet)

def one_or_many(names, single_suffix, many_text, color):
    if len(names) == 1:
        return (names[0] + single_suffix, color)
    return (many_text % len(names), color)

def alert_lines(opens, leaks, low, offline, breaches):
    """Everything that is wrong, worst first, as short (text, color) lines."""
    alerts = []
    if len(leaks) > 0:
        alerts.append(one_or_many(leaks, " LEAK", "%d WATER LEAKS", RED))
    if len(offline) > 0:
        alerts.append(one_or_many(offline, " OFFLINE", "%d CAMS OFFLINE", RED))
    if breaches == 1:
        alerts.append(("ALARM TRIGGERED", RED))
    elif breaches > 1:
        alerts.append(("%d ALARM EVENTS" % breaches, RED))
    if len(opens) > 0:
        alerts.append(one_or_many(opens, " OPEN", "%d SENSORS OPEN", AMBER))
    if len(low) > 0:
        alerts.append(one_or_many(low, " LOW BATT", "%d LOW BATT", AMBER))
    return alerts

def calm_line(sensors, quiet):
    """The second line when there is at most one thing to report.

    `quiet` is counted per sensor rather than subtracted from the total: a
    sensor that is both open and low on battery is one sensor, not two, and
    one that is unreachable is not OK however quiet its last reading was.
    """
    total = len(sensors)
    if total == 0:
        return ("NO SENSORS", DIM)
    if quiet == 1:
        return ("1 SENSOR OK", DIM)
    if quiet > 0:
        return ("%d SENSORS OK" % quiet, DIM)
    if total == 1:
        return ("1 SENSOR", DIM)
    return ("%d SENSORS" % total, DIM)

def ticker(w, text, color):
    return render.Marquee(
        width = w - px(3),
        align = "start",
        child = render.Text(text, font = font_tiny(), color = color),
    )

def badge_column(lines):
    if len(lines) == 0:
        return render.Box(width = px(1), height = px(1))
    children = []
    for i in range(len(lines)):
        if i > 0:
            children.append(render.Box(width = px(1), height = px(1)))
        text, color = lines[i]
        children.append(render.Text(text, font = font_tiny(), color = color))
    return render.Column(cross_align = "end", children = children)

# Advances reserved between the hero and the badge column. Both fonts carry a
# 1px right sidebearing, so a 2px budget draws as 3 black columns - measured.
# It has to be a real gutter: at 3x5 pixel type one dark column is not one, and
# on a physical LED matrix adjacent lit pixels bloom into each other.
#
# There used to be a row of per-camera dots in this gap, sized from whatever
# space the badge left over. It is gone: it appeared or vanished according to
# the length of the arm-state word rather than the camera count, it could never
# fit above ~14 cameras (the installs that most wanted it), and at 1 camera the
# single 3x3 block sat one pixel from the badge and read as a bullet. The
# fraction hero and the "N CAMS OFFLINE" ticker already carry the same fact.
HERO_GUTTER = 2

# The badge column is two tiny lines plus a 1px gap, which is taller than the
# hero glyph; pinning the row keeps the tickers on the same scanline whether
# or not a badge survived the fit.
HERO_ROW_H = 11

def hero_width(hero, inverted):
    w = len(hero) * hero_advance()
    if inverted:
        w += px(2)
    return w

def badge_budget(hero, inverted):
    """Panel pixels left for the badge column beside this hero."""
    return canvas.width() - px(4) - hero_width(hero, inverted) - px(HERO_GUTTER)

def badge_width(badges):
    widest = 0
    for text, _ in badges:
        w = len(text) * tiny_advance()
        if w > widest:
            widest = w
    return widest

def fit_badges(options, avail):
    """The first badge set from options (widest first) that fits in avail px.

    Nothing else in the row is allowed to overflow: a Row that runs past 64px
    clips 3x5 type into unreadable garbage, and in the breach state it clipped
    the camera count into a *different, wrong* number.
    """
    for badges in options:
        if badge_width(badges) <= avail:
            return badges
    return []

def hero_row(hero, hero_color, badges, inverted):
    hero_widget = render.Text(hero, font = font_big(), color = hero_color)
    if inverted:
        hero_widget = render.Stack(
            children = [
                render.Box(
                    width = hero_width(hero, True),
                    height = px(10),
                    color = hero_color,
                ),
                render.Padding(
                    pad = (px(1), 0, 0, 0),
                    child = render.Text(hero, font = font_big(), color = BLACK),
                ),
            ],
        )

    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [hero_widget, badge_column(badges)],
    )

def status_badges(arm_status, fraction, fraction_color):
    """Pick the badge column and anything that got bumped to the tickers."""
    if arm_status == "breach":
        avail = badge_budget("BREACH", True)
        badges = fit_badges(
            [
                [(fraction, fraction_color), ("CAMS", DIM)],
                [(fraction, fraction_color)],
            ],
            avail,
        )
        if len(badges) == 0:
            return (badges, [("%s CAMS ONLINE" % fraction, fraction_color)])
        return (badges, [])

    avail = badge_budget(fraction, False)
    forms, color = ARM_BADGES.get(arm_status, ([], DIM))
    options = [[("CAMS", DIM), (f, color)] for f in forms]
    options += [[(f, color)] for f in forms]
    options.append([("CAMS", DIM)])
    badges = fit_badges(options, avail)

    armed_shown = False
    for text, _ in badges:
        if text in forms:
            armed_shown = True
    if armed_shown or arm_status not in ARM_TICKERS:
        return (badges, [])
    return (badges, [ARM_TICKERS[arm_status]])

def status_view(cloud, base, key, cams, labels, scope):
    """The board. Cameras are already in hand; the alarm and sensors are not.

    Those two calls each have their own outcome, tracked separately, because a
    failure is an UNKNOWN and never an absence. /cameras is cached for 300s and
    these for 60s, so the ordinary way to get here is with good camera data and
    a console that has since dropped off the connector - or a 429, once the
    100 req/min per-console budget is shared with another app. Rendering that
    as "ALARM OFF" and "NO SENSORS" under a green "ALL CLEAR" would be a
    security display asserting the opposite of the truth.
    """
    w = canvas.width()

    nvr_resp = ui_get(base, key, "/nvrs", TTL_STATUS)
    env = transport_error(cloud, nvr_resp)
    if env != None:
        return connector_card(env)

    # Parsing the envelope is not reading the alarm. `armMode` is optional in
    # the body, and a /nvrs that answers 200 {"id":...,"name":...} used to set
    # arm_known off the dict alone: arm_status fell through to "", which is a
    # key in neither ARM_BADGES nor ARM_TICKERS, so the ALARM ? badge, the
    # amber dot and the ALARM N/A line all stayed silent and the panel drew a
    # green ALL CLEAR over an arm state it had never seen. The alarm is known
    # only once a status has actually come out of it, and only a status this
    # app has wording for - a value it cannot draw is not one it may imply.
    arm = {}
    arm_known = False
    if nvr_resp.status_code == 200 and is_json(nvr_resp):
        nvr_body = nvr_resp.json()
        if type(nvr_body) == "dict":
            arm = as_dict(nvr_body.get("armMode"))
            reported = arm.get("status")
            if type(reported) == "string":
                arm_known = reported.strip().lower() in ARM_STATES

    sensors_resp = ui_get(base, key, "/sensors", TTL_STATUS)
    env = transport_error(cloud, sensors_resp)
    if env != None:
        return connector_card(env)
    sensors = []
    sensors_known = False
    if sensors_resp.status_code == 200 and is_json(sensors_resp):
        sensors_body = sensors_resp.json()
        if type(sensors_body) == "list":
            sensors = sensors_body
            sensors_known = True

    opens, leaks, low, away, quiet = sensor_alerts(sensors, time.now().unix)

    arm_status = "unknown"
    if arm_known:
        arm_status = arm["status"].strip().lower()
    breaches = 0
    if arm_status == "breach":
        breaches = as_num(arm.get("breachEventCount")) or 0

    online = 0
    offline = []
    for i in range(len(cams)):
        if is_connected(cams[i]):
            online += 1
        else:
            # The numbered label, not the bare name: with two cameras called
            # "Backyard" on one console, "BACKYARD OFFLINE" is half a fact.
            offline.append(labels[i].upper())

    fraction = "%d/%d" % (online, len(cams))
    fraction_color = WHITE
    if len(offline) > 0:
        fraction_color = AMBER
    if online == 0:
        fraction_color = RED

    dot = GREEN
    if not arm_known or not sensors_known or len(away) > 0 or scope != "":
        dot = AMBER
    if len(offline) > 0 or len(opens) > 0 or len(low) > 0:
        dot = AMBER
    if arm_status == "breach" or len(leaks) > 0:
        dot = RED

    badges, spillover = status_badges(arm_status, fraction, fraction_color)

    if arm_status == "breach":
        hero, hero_color = ("BREACH", RED)
    else:
        hero, hero_color = (fraction, fraction_color)

    alerts = alert_lines(opens, leaks, low, offline, breaches) + spillover

    # What we could not read ranks under what we did read, but above the
    # all-clear: those two lines are the only place the panel makes a positive
    # claim, and none of those claims can be made off a call that failed, a
    # sensor that is not answering, or a console that was never asked. The
    # scope goes last because it is the broadest of them and the one an
    # explicit Console setting turns off for good.
    if len(away) > 0:
        alerts.append(one_or_many(away, " N/A", "%d SENSORS N/A", DIM))
    if not arm_known:
        alerts.append(("ALARM N/A", DIM))
    if not sensors_known:
        alerts.append(("SENSORS N/A", DIM))
    if scope != "":
        alerts.append((scope, DIM))

    if len(alerts) > 0:
        line1 = alerts[0]
    else:
        line1 = ("ALL CLEAR", GREEN)
    if len(alerts) > 1:
        line2 = alerts[1]
    elif sensors_known:
        line2 = calm_line(sensors, quiet)
    else:
        # Nothing true is left to say about sensors; better a blank line than
        # a count of a list we never received.
        line2 = ("", DIM)

    frames = [hero_row(hero, hero_color, badges, False)]
    if arm_status == "breach":
        for _ in range(7):
            frames.append(frames[0])
        for _ in range(8):
            frames.append(hero_row(hero, hero_color, badges, True))

    return render.Root(
        child = render.Column(
            expanded = True,
            children = [
                render.Stack(
                    children = [
                        header_band(w),
                        render.Padding(
                            pad = (0, px(1), px(2), 0),
                            child = render.Row(
                                expanded = True,
                                main_align = "end",
                                children = [render.Circle(color = dot, diameter = px(3))],
                            ),
                        ),
                    ],
                ),
                render.Padding(
                    pad = (px(2), px(1), px(2), 0),
                    child = render.Box(
                        height = px(HERO_ROW_H),
                        child = render.Animation(children = frames),
                    ),
                ),
                render.Padding(
                    pad = (px(2), px(1), 0, 0),
                    child = render.Column(
                        children = [
                            ticker(w, line1[0], line1[1]),
                            render.Box(width = px(1), height = px(1)),
                            ticker(w, line2[0], line2[1]),
                        ],
                    ),
                ),
            ],
        ),
    )

# ------------------------------------------------------------------- main ---

def address_problem(problem):
    """The card for a console address we refuse to hand to http.get."""
    if problem == "bad":
        return card("BAD ADDRESS", AMBER, "check for typos")

    # Supersedes the older "use .ui.direct" advice. That name is not in public
    # DNS, so pointing people at it just moves the failure; what actually has
    # to be true is that this display can resolve the name and trust its cert.
    return card("NEEDS HOSTNAME", AMBER, "must resolve + valid cert")

def local_transport(host_raw):
    """Resolve local mode down to a base URL. Returns (base, card)."""
    scheme, host, problem = clean_host(host_raw)
    if problem == "empty":
        return ("", card("ADD CONSOLE", BLUE, "+ API KEY"))
    if problem != None:
        return ("", address_problem(problem))
    return (local_base(scheme, host), None)

def show_protect(cloud, base, key, cams, view, wanted, scope):
    """Everything after a console with cameras on it has been settled.

    Identical for cloud and local but for one thing: only cloud has a connector
    in front of Protect, so only cloud can receive its failure envelope. The
    flag rides along with the base URL rather than being guessed from it.
    """
    cams = ordered_cameras(cams)
    labels = display_labels(cams)

    if view == "status":
        return status_view(cloud, base, key, cams, labels, scope)

    i = pick_camera(cams, wanted)
    if i < 0:
        return card("NO MATCH", AMBER, panel_text(wanted.strip(), "no such camera"))
    return snapshot_view(cloud, base, key, cams[i], labels[i])

def main(config):
    source = config.str("source") or "cloud"
    host_raw = config.str("host") or ""
    api_key = config.str("api_key") or ""
    console = config.str("console") or ""
    view = config.str("view") or "snapshot"
    wanted = config.str("camera") or ""

    # A value saved by a future version of this schema must not reach a lookup.
    # Falling back to the default is deliberate: cloud needs no second field, so
    # an unrecognised mode degrades to the one that is most likely to work
    # rather than to a card the user cannot act on.
    if source not in SOURCES:
        source = "cloud"

    key = api_key.strip()

    # The setup cards come first and unconditionally: with no config at all this
    # app must render instantly and make zero HTTP calls, which is what CI
    # checks with the network switched off.
    if source == "local" and host_raw.strip() == "":
        return card("ADD CONSOLE", BLUE, "+ API KEY")
    if key == "":
        if source == "cloud":
            return card("ADD API KEY", BLUE, "unifi.ui.com")
        return card("ADD API KEY", BLUE, "in app settings")

    cloud = source == "cloud"
    scope = ""
    if cloud:
        # Cloud resolution hands the cameras back with the console, because
        # finding one is what proved the other: the console is chosen by
        # asking for a camera list, never by trusting the host record. The
        # camera goes in because it is half of that question - which console
        # has the cameras is not the same question as which console has THIS
        # camera, and only the second one is what the panel is about to draw.
        # The status board has no camera to look for, so it does not send one.
        target = wanted
        if view == "status":
            target = ""
        root = cloud_root(host_raw)
        host_id, cams, failed, scope = resolve_cloud(root, key, console, target)
        if failed != None:
            return failed
        base = cloud_base(root, host_id)
    else:
        base, failed = local_transport(host_raw)
        if failed != None:
            return failed
        cams, failed, _ = fetch_cameras(False, base, key)
        if failed != None:
            return failed
        if len(cams) == 0:
            return card("NO CAMERAS", AMBER, "none in Protect")

    return show_protect(cloud, base, key, cams, view, wanted, scope)

# ----------------------------------------------------------------- schema ---

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "source",
                name = "Connection",
                desc = "Cloud works anywhere. Local is faster but your display must resolve your console's hostname and trust its certificate.",
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
                desc = "Cloud: unifi.ui.com, Settings, API Keys. Local: your console's Settings, Control Plane, Integrations.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "console",
                name = "Console",
                desc = "Cloud mode only. Part of the console's name or model, e.g. Dream Wall or UDW. Leave it empty and the app finds the console your cameras are on.",
                icon = "server",
            ),
            schema.Text(
                id = "host",
                name = "Console address",
                desc = "Local mode only. Your console's hostname - it needs a certificate your display trusts, so a bare IP will not work.",
                icon = "networkWired",
            ),
            schema.Dropdown(
                id = "view",
                name = "View",
                desc = "Snapshot shows one camera. Status shows cameras, arm state and sensors.",
                icon = "images",
                default = "snapshot",
                options = [
                    schema.Option(display = "Camera snapshot", value = "snapshot"),
                    schema.Option(display = "Status board", value = "status"),
                ],
            ),
            schema.Text(
                id = "camera",
                name = "Camera",
                desc = "Part of the camera name to show, e.g. Front. Where two cameras share a name the display numbers them (1/2), and adding #2 picks the second one. Empty picks the first connected camera.",
                icon = "video",
            ),
        ],
    )
