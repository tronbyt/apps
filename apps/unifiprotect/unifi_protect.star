"""
Applet: UniFi Protect
Summary: Cameras on your panel
Description: Puts a UniFi Protect camera on your display: a live low-quality snapshot with the camera name, or a status board showing cameras online, the alarm arm state and UP Sense sensor alerts (open doors, water leaks, low batteries). By default it reaches your console through the UniFi cloud, which needs only an API key from unifi.ui.com. A local connection is also offered, but the display itself has to resolve your console's hostname and trust its certificate for that to work. Camera motion and doorbell ring events are not shown, because the official API only delivers those over WebSocket, which this runtime cannot open.
Author: nsluke
"""

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

# A sensor event is treated as "happening now" for this long.
ALERT_WINDOW_SEC = 900

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
    """Every name this console is known by, for matching the console setting."""
    ud = as_dict(h.get("userData"))
    rs = as_dict(h.get("reportedState"))
    out = []
    for v in [ud.get("name"), rs.get("name"), rs.get("hostname"), h.get("ipAddress")]:
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

def host_protect_state(h):
    """True / False / None for "this console runs Protect" - None means unknown.

    reportedState and the console group are both optional and their shape has
    changed between releases: applications has been seen as a list of names and
    as an object keyed by name, so both are read and neither is required. We
    only ever say "no Protect here" when a console positively reported its
    applications and Protect was absent from them, or was present and marked
    unsupported.
    """
    ud = as_dict(h.get("userData"))
    found = False
    for member in as_list(ud.get("consoleGroupMembers")):
        apps = as_dict(as_dict(member).get("roleAttributes")).get("applications")

        if type(apps) == "dict":
            for name in apps.keys():
                if type(name) != "string":
                    continue
                found = True
                if name.lower() == "protect" and app_supported(apps[name]):
                    return True
        elif type(apps) == "list":
            for name in apps:
                if type(name) != "string":
                    continue
                found = True
                if name.lower() == "protect":
                    return True
    if found:
        return False
    return None

def pick_host(hosts, wanted):
    needle = wanted.strip().lower()
    if needle == "":
        return hosts[0]
    for h in hosts:
        for name in host_names(h):
            if needle in name:
                return h
    return None

def resolve_host_id(root, key, wanted):
    """Look the console's hostId up in the cloud.

    Returns (host_id, card): a non-None card is a finished panel to render
    instead, so every failure below is a card rather than a raised error.
    """
    resp = ui_get(root, key, HOSTS_PATH, TTL_HOSTS)

    env = connector_error(resp)
    if env != None:
        return ("", connector_card(env))

    # A failure here is the cloud's, never Protect's - nothing has reached the
    # console yet - so it gets the cloud wording even when the body is not the
    # envelope. api.ui.com answers an unrecognised route with a bare text/plain
    # "404 page not found", which lands exactly here.
    if resp.status_code != 200:
        return ("", connector_card((resp.status_code, "")))
    if not is_json(resp):
        return ("", card("BAD REPLY", AMBER, "not the UniFi cloud"))

    hosts = []
    for h in as_list(as_dict(resp.json()).get("data")):
        if type(h) == "dict" and usable_id(h.get("id")):
            hosts.append(h)
    if len(hosts) == 0:
        return ("", card("NO CONSOLES", AMBER, "none on this account"))

    chosen = pick_host(hosts, wanted)
    if chosen == None:
        return ("", card("NO MATCH", AMBER, panel_text(wanted.strip(), "no such console")))
    if host_protect_state(chosen) == False:
        return ("", card("NO PROTECT", AMBER, "not on this console"))
    return (chosen["id"], None)

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

def pick_camera(cams, wanted):
    """Substring match on the camera name, else the first connected camera."""
    needle = wanted.strip().lower()
    if needle != "":
        for cam in cams:
            if needle in raw_name(cam).lower():
                return cam
        return None
    for cam in cams:
        if is_connected(cam):
            return cam
    if len(cams) > 0:
        return cams[0]
    return None

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
    # tail rather than insisting on the very last two bytes.
    tail = list(body[n - 64:].elem_ords())
    for i in range(len(tail) - 1):
        if tail[i] == 255 and tail[i + 1] == 217:
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

def snapshot_view(cloud, base, key, cam):
    w, h = canvas.size()
    label = camera_name(cam)

    resp = ui_get(
        base,
        key,
        "/cameras/%s/snapshot" % cam["id"],
        TTL_SNAPSHOT,
        params = {"highQuality": "false"},
    )

    # The connector's own envelope is checked before the 503, because both
    # layers use that code and they mean different things: the connector's 503
    # is a console it could not reach, Protect's is a camera that is down.
    env = transport_error(cloud, resp)
    if env != None:
        return connector_card(env)
    if resp.status_code == 503:
        return card("CAMERA OFFLINE", RED, label)
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

def sensor_battery_low(sensor):
    wireless = as_dict(as_dict(sensor.get("wirelessConnectionState")).get("batteryStatus"))
    if wireless.get("isLow") == True:
        return True
    return as_dict(sensor.get("batteryStatus")).get("isLow") == True

def sensor_alerts(sensors, now):
    """Roll a sensor list up into (opens, leaks, low batteries) name lists."""
    opens = []
    leaks = []
    low = []
    for sensor in sensors:
        if type(sensor) != "dict":
            continue
        label = panel_text(as_text(sensor.get("name"), "Sensor"), "Sensor").upper()
        if sensor.get("isOpened") == True:
            opens.append(label)
        leak_at = epoch_seconds(sensor.get("leakDetectedAt"))
        if leak_at != None and now - leak_at < ALERT_WINDOW_SEC:
            leaks.append(label)
        if sensor_battery_low(sensor):
            low.append(label)
    return (opens, leaks, low)

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

def calm_line(sensors, opens, leaks, low):
    """The second line when there is at most one thing to report."""
    total = len(sensors)
    if total == 0:
        return ("NO SENSORS", DIM)
    quiet = total - len(opens) - len(leaks) - len(low)
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

def status_view(cloud, base, key, cams):
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
    arm = {}
    arm_known = False
    if nvr_resp.status_code == 200 and is_json(nvr_resp):
        nvr_body = nvr_resp.json()
        if type(nvr_body) == "dict":
            arm = as_dict(nvr_body.get("armMode"))
            arm_known = True

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

    opens, leaks, low = sensor_alerts(sensors, time.now().unix)

    arm_status = arm.get("status", "")
    if type(arm_status) != "string":
        arm_status = ""
    if not arm_known:
        arm_status = "unknown"
    breaches = 0
    if arm_status == "breach":
        breaches = as_num(arm.get("breachEventCount")) or 0

    online = 0
    offline = []
    for cam in cams:
        if is_connected(cam):
            online += 1
        else:
            offline.append(camera_name(cam).upper())

    fraction = "%d/%d" % (online, len(cams))
    fraction_color = WHITE
    if len(offline) > 0:
        fraction_color = AMBER
    if online == 0:
        fraction_color = RED

    dot = GREEN
    if not arm_known or not sensors_known:
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
    # claim, and neither claim can be made off a call that failed.
    if not arm_known:
        alerts.append(("ALARM N/A", DIM))
    if not sensors_known:
        alerts.append(("SENSORS N/A", DIM))

    if len(alerts) > 0:
        line1 = alerts[0]
    else:
        line1 = ("ALL CLEAR", GREEN)
    if len(alerts) > 1:
        line2 = alerts[1]
    elif sensors_known:
        line2 = calm_line(sensors, opens, leaks, low)
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

def cloud_transport(key, host_raw, console):
    """Resolve cloud mode down to a base URL. Returns (base, card)."""
    root = cloud_root(host_raw)

    host_id, failed = resolve_host_id(root, key, console)
    if failed != None:
        return ("", failed)
    return (cloud_base(root, host_id), None)

def local_transport(host_raw):
    """Resolve local mode down to a base URL. Returns (base, card)."""
    scheme, host, problem = clean_host(host_raw)
    if problem == "empty":
        return ("", card("ADD CONSOLE", BLUE, "+ API KEY"))
    if problem != None:
        return ("", address_problem(problem))
    return (local_base(scheme, host), None)

def show_protect(cloud, base, key, view, wanted):
    """Everything after the transport.

    Identical for cloud and local but for one thing: only cloud has a connector
    in front of Protect, so only cloud can receive its failure envelope. The
    flag rides along with the base URL rather than being guessed from it.
    """
    resp = ui_get(base, key, "/cameras", TTL_CAMERAS)

    env = transport_error(cloud, resp)
    if env != None:
        return connector_card(env)
    if resp.status_code != 200:
        return status_card(resp.status_code)
    if not is_json(resp):
        return card("BAD REPLY", AMBER, "not Protect API")

    cams = clean_cameras(resp.json())
    if len(cams) == 0:
        return card("NO CAMERAS", AMBER, "none in Protect")

    if view == "status":
        return status_view(cloud, base, key, cams)

    cam = pick_camera(cams, wanted)
    if cam == None:
        return card("NO MATCH", AMBER, panel_text(wanted.strip(), "no such camera"))
    return snapshot_view(cloud, base, key, cam)

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
    if cloud:
        base, failed = cloud_transport(key, host_raw, console)
    else:
        base, failed = local_transport(host_raw)
    if failed != None:
        return failed

    return show_protect(cloud, base, key, view, wanted)

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
                desc = "Cloud mode only. Part of the console's name, if your account has more than one. Empty picks the first.",
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
                desc = "Part of the camera name to show, e.g. Front. Empty picks the first connected camera.",
                icon = "video",
            ),
        ],
    )
