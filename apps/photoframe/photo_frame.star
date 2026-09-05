"""
Applet: Photo Frame
Summary: One photo, smart-cropped
Description: Shows a photo from a URL, resized and smart-cropped server-side so the subject survives 64x32. Fetched via the images.weserv.nl proxy; point it at public image URLs.
Author: nsluke

The point of this app over the naive display-an-image apps: the resize happens
SERVER-SIDE at images.weserv.nl, so the device decodes a ~1KB 64x32 JPEG
instead of scaling a multi-megapixel photo in RAM, and `a=attention` crops
toward the busiest region so faces and subjects survive the 2:1 frame instead
of being squashed or beheaded.

weserv behavior, verified live 2026-09-01/02:
  - /?url=<urlencoded origin URL>&w=64&h=32&fit=cover&a=attention&output=jpg
    -> exactly 64x32 baseline JPEG, ~0.7-1.1KB. fit=contain + cbg=000000
    letterboxes on black; fit=fill stretches. All three 200.
  - the url= value works with or without a scheme; the scheme is KEPT (https
    assumed when missing) so https-only origins that don't answer on port 80
    still resolve.
  - every origin-side failure (dead DNS, origin 404, origin serves HTML) comes
    back as HTTP 400/404 + a small {"status":"error",...} JSON body - never a
    200 that isn't an image. We still magic-sniff the bytes before
    render.Image, because a transport-level surprise (captive portal,
    misconfigured proxy override) would otherwise abort the render uncatchably.

Two properties keep an uncatchable abort from becoming a permanent one:

  - Every fetch is gated (cache key written BEFORE the request, 60s retry TTL
    on failure, 6h on success) because an http transport error aborts a pixlet
    render and Starlark cannot catch it.
  - Bytes are cached only AFTER render.Image has decoded them. The decode runs
    inside the Starlark call, so an undecodable body aborts before its
    cache.set is reached - the 7-day display cache therefore only ever holds
    bytes this build already rendered once, and no fetch can poison it. The
    magic+trailer sniff still runs first, because turning a truncated download
    into an error card is better than spending an abort on it, but the sniff
    is a filter, not the guarantee.

Display bytes are cached base64 for 7 days keyed by proxy|mode|url; a weserv
outage serves the last good photo. If weserv itself misbehaves (5xx, or a 200
that isn't an image) and nothing is cached, we fall back to fetching the origin
URL directly - size-capped at 300KB, since in that mode the DEVICE pays the
decode+scale cost the proxy normally absorbs, and the fit mode has to be
applied here rather than server-side (see fitted_image). Direct bytes get their
own cache key: they are the original photo at its own aspect ratio, so the
render treatment differs from proxy output and the two must not be confused.
When weserv reports the ORIGIN is bad (its 400/404 JSON error), the direct
fetch is skipped on purpose: retrying a dead or typo'd hostname ourselves
would be the transport-error abort the gate exists to prevent. One direction
of that residual cannot be closed: a scheme-less config value is promoted to
https:// (right for weserv and for almost every origin), so a proxy outage in
front of an origin that only speaks plain HTTP aborts the direct fetch on the
TLS handshake - gated to one render per RETRY_TTL, the same uncatchable class
as a refused connection.

With no URL configured (the default), it renders a built-in dusk scene drawn
entirely from pixlet primitives: zero network, safe for CI and the store demo.

On a 64x64 panel the app asks the proxy for a 64x64 crop instead of a 64x32
one and hangs it edge to edge. That is the whole square layout, and it is the
one that matters for a photo app: the same `a=attention` crop over a square
frame keeps roughly twice the picture, so a portrait or a 4:3 snapshot loses a
sliver where the 2:1 slice threw away half of it. All three fit modes keep
their meaning (cover fills, contain letterboxes inside the square, fill
stretches), the requested dimensions are part of the cache key so a wide and a
square panel sharing a server never serve each other's crop, the drawn
placeholder is composed for 64 rows rather than stretched, and the caption
strip stays exactly what it is on the wide panel - seven rows along the very
bottom. Panels are told apart by SHAPE, never size: see is_square().

The proxy base can be overridden via the "proxy" config value - a test hook
for pointing the app at a stub server. It is deliberately NOT a schema field
(users would only break their app with it), and like every other URL we hand
to http.get it goes through parseable_url first, because http.get aborts the
render on a URL Go's net/url cannot parse.
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")

PROXY_BASE = "https://images.weserv.nl"

FRESH_TTL = 21600  # re-fetch the photo every 6h
STALE_TTL = 604800  # serve the last good bytes up to 7d through an outage
RETRY_TTL = 60  # back off after any failure

PROXY_CAP = 60000  # weserv output is ~1KB; anything bigger is not our JPEG
DIRECT_CAP = 300000  # direct fallback: the device decodes this itself

TRAILER_SCAN = 8192  # tail searched for the end-of-image marker

# Some CDNs 403 pixlet's default Go user-agent (measured on the album_art
# CDN: 10/10 blocked without a UA, 10/10 fine with one). Cheap insurance.
USER_AGENT = "tronbyt:photo-frame:1.0 (+https://github.com/tronbyt/apps)"

WHITE = "#FFFFFF"
AMBER = "#FFC46B"
SHADE = "#000000B4"

def main(config):
    url = normalize_url(config.str("img_url", ""))
    mode = config.str("mode", "cover")
    if mode not in ("cover", "contain", "fill"):
        mode = "cover"
    caption = config.str("caption", "").strip()
    proxy = config.str("proxy", PROXY_BASE).strip()
    if proxy == "":
        proxy = PROXY_BASE
    proxy = proxy.rstrip("/")

    # Every drawn row below is derived from this, and it is the only thing the
    # square panel changes: the frame is 64 wide either way, and 64 tall
    # instead of 32. It is also the height the PROXY is asked to crop to.
    ph = 64 if is_square() else 32

    if url == "":
        return render.Root(child = placeholder("ADD IMAGE URL", True, ph))
    if not parseable_url(proxy):
        # A malformed proxy override would abort every render inside http.get.
        return render.Root(child = placeholder("BAD PROXY URL", False, ph))

    photo = get_photo(url, mode, proxy, ph)
    if photo == None:
        return render.Root(child = placeholder("CHECK IMAGE URL", False, ph))
    return render.Root(child = photo_view(photo, caption, ph))

def is_square():
    """True on a square panel, false on the 2:1 one.

    Branches on the panel's SHAPE, never its size. A 2x device reports the
    doubled canvas - 128x64 when it is wide, 128x128 when it is square - so a
    height test would call both of those 64 tall and get one of them wrong.
    The slack keeps a merely tallish panel on the wide branch.
    """
    w, h = canvas.size()
    return h * 2 > w + 16

# ---------------------------------------------------------------- URL checks

def normalize_url(url):
    """Trim, and assume https when no scheme is given. The scheme is kept and
    sent to weserv (verified it accepts full URLs) because scheme-less means
    port 80, and https-only origins never answer there."""
    url = url.strip()
    if url == "":
        return ""
    if url.startswith("//"):
        return "https:" + url
    if url.find("://") < 0:
        return "https://" + url
    return url

DIGITS = "0123456789"
HEXDIGITS = "0123456789abcdefABCDEF"
HOST_CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"

def parseable_url(url):
    """True only when Go's net/url is certain to PARSE this URL, for every URL
    we hand to http.get ourselves (the proxy base and the direct-fetch origin).
    An unparseable one aborts the whole render inside http.get and Starlark
    cannot catch it, so anything this cannot certify gets the error card
    instead. The url= PARAM does not need this - http.get percent-encodes
    params, and weserv judges bad values safely server-side.

    Probed against pixlet 0.34 (Go 1.x net/url), which rejects exactly: a '%'
    in the path or the FRAGMENT not followed by two hex digits, a control byte
    anywhere, a port segment that is not all digits, and a host carrying
    characters net/url reserves. Spaces, non-ASCII and the shell-looking
    punctuation all parse fine inside the PATH and are allowed through. Hosts
    are held to the unreserved set (so no userinfo, no IPv6 literal, no
    sub-delims): those are certifiable by inspection, anything else would be a
    guess."""
    if not (url.startswith("https://") or url.startswith("http://")):
        return False
    rest = url[url.find("://") + 3:]
    if not printable(rest):  # one control byte and net/url rejects the lot
        return False

    auth = cut_before(rest, "/?#")
    host = auth
    port_at = host.rfind(":")
    if port_at >= 0:
        if not all_in(host[port_at + 1:], DIGITS):  # net/url: "invalid port"
            return False
        host = host[:port_at]
    if host.find(".") <= 0 or not all_in(host, HOST_CHARS):
        return False

    # net/url cuts the fragment off first and UNESCAPES it, then splits the
    # query off the path and unescapes only the path. So path and fragment are
    # both held to the escape rule; the raw query never is (verified all three
    # on pixlet 0.34: "#%zz" and "/a%2" abort, "?a=%zz" fetches fine).
    tail = rest[len(auth):]
    frag_at = tail.find("#")
    if frag_at >= 0:
        if not escapes_ok(tail[frag_at + 1:]):
            return False
        tail = tail[:frag_at]
    return escapes_ok(cut_before(tail, "?"))

def cut_before(s, seps):
    """The prefix of s up to the first byte in seps (all of s when none)."""
    cut = len(s)
    for sep in seps.elems():
        i = s.find(sep)
        if i >= 0 and i < cut:
            cut = i
    return s[:cut]

def all_in(s, allowed):
    for c in s.elems():
        if allowed.find(c) < 0:
            return False
    return True

def printable(s):
    """No control byte: net/url rejects the whole URL for one of those."""
    for o in s.elem_ords():
        if o < 32 or o == 127:
            return False
    return True

def escapes_ok(s):
    """Every '%' followed by two hex digits, as net/url's path unescape wants."""
    for i in range(len(s)):
        if s[i] != "%":
            continue
        if i + 3 > len(s) or not all_in(s[i + 1:i + 3], HEXDIGITS):
            return False
    return True

# ---------------------------------------------------------------- byte tools

def ub(b, i):
    """Unsigned byte at i; -1 past either end, so callers need no bounds check."""
    if i < 0 or i >= len(b):
        return -1
    return b[i:i + 1].elem_ords()[0]

def be16(b, i):
    return ub(b, i) * 256 + ub(b, i + 1)

def be32(b, i):
    return be16(b, i) * 65536 + be16(b, i + 2)

def le16(b, i):
    return ub(b, i) + 256 * ub(b, i + 1)

def le24(b, i):
    return le16(b, i) + 65536 * ub(b, i + 2)

def le32(b, i):
    return le16(b, i) + 65536 * le16(b, i + 2)

def has_pair(b, a, c):
    """True when the byte pair (a, c) appears anywhere in b."""
    e = b.elem_ords()
    for i in range(len(e) - 1):
        if e[i] == a and e[i + 1] == c:
            return True
    return False

def looks_image(b):
    """Magic-sniff AND trailer-check before render.Image. Rejecting garbage
    here spends an error card instead of an abort; it is a filter, not a
    decodability proof (no Starlark check is - see get_photo, which only
    caches bytes render.Image already decoded).

    The trailer is SEARCHED for rather than required at the very end: a
    truncated download has no trailer anywhere and is still rejected, but a
    complete file carrying trailing data - a Motion Photo JPEG with an MP4
    appended, a block-padded upload - decodes fine and must not be thrown
    away. Each format's search is as tight as its marker allows: JPEG's FF D9
    and PNG's IEND are distinctive enough to look for anywhere in the tail,
    while GIF's trailer is the single common byte 0x3B, so it only counts when
    it sits at the very end or nothing but NUL padding follows it."""
    n = len(b)
    if n < 12:
        return False
    start = n - TRAILER_SCAN
    if start < 0:
        start = 0
    if ub(b, 0) == 255 and ub(b, 1) == 216 and ub(b, 2) == 255:  # JPEG
        return has_pair(b[start:], 255, 217)  # FF D9 end-of-image marker
    if ub(b, 0) == 137 and b[1:4] == "PNG":
        i = b.rfind("IEND")  # final chunk; its 4-byte CRC follows
        return i >= 0 and n >= i + 8
    if b[:4] == "GIF8":
        i = b.rfind(";")  # 0x3B trailer byte
        if i < 0:
            return False
        pad = n - i - 1
        return pad == 0 or (pad <= TRAILER_SCAN and all_ord(b[i + 1:], 0))
    if b[:4] == "RIFF" and b[8:12] == "WEBP":
        return n >= le32(b, 4) + 8  # declared RIFF payload + the 8-byte header
    return False

def all_ord(b, o):
    """True when every byte of b is o (bounded by the caller's slice)."""
    for x in b.elem_ords():
        if x != o:
            return False
    return True

SOF_NOT = [196, 200, 204]  # C4 DHT, C8 JPG-ext, CC DAC sit inside the SOF range

def image_size(b):
    """(width, height) in pixels from the container header, or None when the
    header is not one this can read. Only the direct-origin path needs it -
    proxy output is already 64x32 - and only to compare against the panel's
    2:1, so None simply means "fall back to width-only scaling"."""
    if len(b) < 30:
        return None
    size = None
    if ub(b, 0) == 255 and ub(b, 1) == 216:
        size = jpeg_size(b)
    elif ub(b, 0) == 137 and b[1:4] == "PNG" and b[12:16] == "IHDR":
        size = (be32(b, 16), be32(b, 20))
    elif b[:4] == "GIF8":
        size = (le16(b, 6), le16(b, 8))
    elif b[:4] == "RIFF" and b[8:12] == "WEBP":
        size = webp_size(b)
    if size == None or size[0] <= 0 or size[1] <= 0:
        return None
    return size

def jpeg_size(b):
    """Walk the marker segments to the first SOF, which carries the frame size.
    Bounded: real files reach SOF in a handful of segments, and SOS (the start
    of entropy-coded data) always follows it."""
    n = len(b)
    i = 2
    for _ in range(96):
        if i + 9 > n or ub(b, i) != 255:
            return None
        m = ub(b, i + 1)
        if m == 255:  # fill byte before the real marker
            i += 1
        elif m == 216 or m == 1 or (m >= 208 and m <= 215):  # SOI/TEM/RSTn
            i += 2
        elif m == 218 or m == 217:  # SOS/EOI: past every SOF
            return None
        elif m >= 192 and m <= 207 and m not in SOF_NOT:
            return (be16(b, i + 7), be16(b, i + 5))
        else:
            seg = be16(b, i + 2)
            if seg < 2:
                return None
            i += 2 + seg
    return None

def webp_size(b):
    """VP8X carries the canvas size; VP8 (lossy) and VP8L (lossless) carry the
    frame size in their own bit-packed headers."""
    kind = b[12:16]
    if kind == "VP8X":
        return (le24(b, 24) + 1, le24(b, 27) + 1)
    if kind == "VP8 ":
        if ub(b, 23) != 157 or ub(b, 24) != 1 or ub(b, 25) != 42:
            return None  # missing start code: not a frame header we can read
        return (le16(b, 26) % 16384, le16(b, 28) % 16384)
    if kind == "VP8L" and ub(b, 20) == 47:
        v = le32(b, 21)  # 14 bits width-1 then 14 bits height-1
        return (v % 16384 + 1, (v // 16384) % 16384 + 1)
    return None

# ---------------------------------------------------------------- data layer

def proxy_params(url, mode, ph):
    """The proxy is asked for exactly the pixels the panel has - 64x32 or
    64x64. Verified live against weserv 2026-09-03: all three fit modes return
    exactly 64x64 for h=64, ~1.2-1.8KB. Asking for the square directly is what
    makes the square layout worth having: `a=attention` gets to keep the whole
    height of the subject instead of a 2:1 band through it."""
    p = {
        "url": url,
        "w": "64",
        "h": str(ph),
        "output": "jpg",  # guarantees a single frame: decode cost is fixed
    }
    if mode == "contain":
        p["fit"] = "contain"
        p["cbg"] = "000000"  # letterbox on black, not weserv's default white
    elif mode == "fill":
        p["fit"] = "fill"
    else:
        p["fit"] = "cover"
        p["a"] = "attention"  # crop toward the busiest region (faces survive)
    return p

def fetch_image(url, gate_key, params, cap):
    """Gate-before-request: a transport error aborts the render and Starlark
    cannot catch it, so the gate key (written before the request) limits the
    damage to one failed render per RETRY_TTL.

    Returns (bytes, verdict): ("ok" with bytes) or None bytes with "gated",
    "origin" (the proxy answered with its origin-error JSON: the user's URL is
    bad, retrying it directly can only make things worse) or "proxy" (the
    server itself misbehaved: 5xx, oversized body, non-image bytes)."""
    if cache.get(gate_key) != None:
        return None, "gated"  # recently fetched or recently failed
    cache.set(gate_key, "1", ttl_seconds = RETRY_TTL)
    resp = http.get(url, params = params, headers = {"User-Agent": USER_AGENT}, ttl_seconds = RETRY_TTL)
    body = resp.body()
    if resp.status_code != 200:
        print("photo_frame: " + url[:60] + " -> " + str(resp.status_code))
        if resp.status_code in (400, 404) and body.startswith("{\"status\":\"error\""):
            return None, "origin"  # weserv's verified failure shape
        return None, "proxy"
    if len(body) > cap:
        print("photo_frame: body too big (" + str(len(body)) + "B) from " + url[:60])
        return None, "proxy"
    if not looks_image(body):
        print("photo_frame: non-image bytes from " + url[:60])
        return None, "proxy"
    cache.set(gate_key, "1", ttl_seconds = FRESH_TTL)
    return body, "ok"

def get_photo(url, mode, proxy, ph):
    """The decoded photo widget for this exact config, or None. Order: fresh
    proxy fetch -> cached proxy bytes -> direct origin fetch (own gate, only
    when the PROXY was at fault) -> cached direct bytes.

    Every cache.set here sits AFTER the fitted_image() that decodes the same
    bytes, so a body that render.Image chokes on aborts before it can be
    stored: the display cache only ever holds bytes already proven renderable,
    and a decoder-hostile origin costs one aborted render per gate window
    instead of poisoning the 7-day key for the whole outage. Proxy and direct
    bytes live under separate keys because they need different fitting.

    The REQUESTED DIMENSIONS are part of the key. They have to be: one server
    drives every panel it owns, so a 64x32 and a 64x64 device on the same
    server ask for the same photo in the same mode and get back genuinely
    different crops. Without the dimensions in the key whichever rendered
    first would hand its crop to the other for up to seven days."""
    ck = "photo_frame:3:" + proxy + "|" + mode + "|64x" + str(ph) + "|" + url

    body, verdict = fetch_image(proxy + "/", ck + ":gate", proxy_params(url, mode, ph), PROXY_CAP)
    if body != None:
        img = fitted_image(body, mode, True, ph)
        cache.set(ck, base64.encode(body), ttl_seconds = STALE_TTL)
        return img

    raw = cache.get(ck)
    if raw != None:
        return fitted_image(base64.decode(raw), mode, True, ph)

    if verdict != "proxy" or not parseable_url(url):
        return None

    body, _ = fetch_image(url, ck + ":dgate", {}, DIRECT_CAP)
    if body != None:
        img = fitted_image(body, mode, False, ph)
        cache.set(ck + ":d", base64.encode(body), ttl_seconds = STALE_TTL)
        return img

    raw = cache.get(ck + ":d")
    if raw != None:
        return fitted_image(base64.decode(raw), mode, False, ph)
    return None

# -------------------------------------------------------------------- states

def fitted_image(body, mode, proxied, ph):
    """Decode the bytes and size them for a 64 x ph panel. Constructing the
    Image is what decodes, so this is also the point where undecodable bytes
    abort - callers cache only after it returns.

    Proxy output is already exactly the panel (64x32 or 64x64, since
    proxy_params asks for ph), so it goes in full-bleed either way. Direct
    origin bytes are the ORIGINAL photo, so the fit mode has to be honored
    here or the dropdown would silently mean nothing during a proxy outage.
    Measured on pixlet 0.34 with banded test images: width+height stretches to
    the box (= fill); one axis alone scales to that axis keeping the aspect
    ratio, which the centering Box then letterboxes or center-crops. So the
    axis to pin is whichever gives the wanted result for this photo's shape -
    and which axis that is depends on the panel, which is why the comparison
    below is against ph rather than a hardcoded 2:1."""
    if proxied:
        return render.Image(src = body, width = 64)
    if mode == "fill":
        return render.Image(src = body, width = 64, height = ph)

    size = image_size(body)
    if size == None:
        return render.Image(src = body, width = 64)  # unreadable header: aspect-safe default

    wide = size[0] * ph > size[1] * 64  # wider than the panel's own aspect
    if mode == "contain":
        pin_width = wide  # a wide photo fits inside the panel by its width
    else:
        pin_width = not wide  # cover: a tall photo has to overflow vertically
    if pin_width:
        return render.Image(src = body, width = 64)
    return render.Image(src = body, height = ph)

def photo_view(img, caption, ph):
    """The photo full-bleed on black, with the optional caption strip over it.
    Square panels get a bigger photo, not a photo with a margin: the Box is the
    whole panel and the strip stays seven rows on its bottom edge."""
    base = render.Box(
        width = 64,
        height = ph,
        color = "#000000",
        child = img,
    )
    if caption == "":
        return base
    return render.Stack(
        children = [
            base,
            render.Padding(
                pad = (0, ph - 7, 0, 0),
                child = render.Box(
                    width = 64,
                    height = 7,
                    color = SHADE,
                    child = render.Marquee(
                        width = 62,
                        child = render.Text(caption, font = "tom-thumb", color = WHITE),
                    ),
                ),
            ),
        ],
    )

# A dusk-over-water scene from pure primitives: the zero-network default and
# the fetch-error card. Same palette on both panels, composed twice rather
# than stretched or padded. Layout maps (y):
#   2:1     0-19 sky, sun disc 8-15, peaks 10-19, water 20-31, note 25-31.
#   square  0-39 sky, sun disc 16-31, peaks 20-39, water 40-63, note 57-63.

SKY = ["#1B1240", "#2C1A52", "#452260", "#672C64", "#93405C", "#C05A48", "#E87E36", "#F7A53C"]
SKY_H = [3, 3, 3, 3, 2, 2, 2, 2]

# 40 rows for the square panel's sky, keeping the wide gradient's habit of
# thinning toward the horizon so the warm end stays compressed near the water.
SKY_H_SQ = [6, 6, 6, 5, 5, 4, 4, 4]

WATER = ["#8A4058", "#7A3754", "#6A2F50", "#5B284B", "#4D2246", "#411C41", "#36173C", "#2D1338", "#251034", "#1E0D30", "#180A2C", "#130828"]
SUN = "#FFD98C"
MTN_BACK = "#3A1D52"
MTN_FRONT = "#26123E"

def at(x, y, w, h, color):
    return render.Padding(pad = (x, y, 0, 0), child = render.Box(width = w, height = h, color = color))

def peak(cx, top, rows, color):
    """Triangle silhouette: apex at (cx, top), widening 2px per row."""
    out = []
    for i in range(rows):
        x = cx - i
        w = 2 * i + 2
        if x < 0:
            w = w + x
            x = 0
        if x + w > 64:
            w = 64 - x
        out.append(at(x, top + i, w, 1, color))
    return out

def placeholder(note, setup, ph):
    """The scene for a 64 x ph panel, titled when it is the setup card, with
    the note strip on the bottom edge. Only the scene beneath differs by
    panel; the title and the strip are the same seven-row furniture on both."""
    if ph == 64:
        layers = square_scene()
        title_y = 6
    else:
        layers = wide_scene()
        title_y = 2

    if setup:
        layers.append(render.Padding(pad = (11, title_y + 1, 0, 0), child = render.Text("PHOTO FRAME", font = "tom-thumb", color = "#00000080")))
        layers.append(render.Padding(pad = (10, title_y, 0, 0), child = render.Text("PHOTO FRAME", font = "tom-thumb", color = WHITE)))

    layers.append(render.Padding(
        pad = (0, ph - 7, 0, 0),
        child = render.Box(
            width = 64,
            height = 7,
            color = SHADE,
            child = render.Text(note, font = "tom-thumb", color = AMBER),
        ),
    ))
    return render.Stack(children = layers)

def wide_scene():
    layers = []

    sky = []
    for i in range(len(SKY)):
        sky.append(render.Box(width = 64, height = SKY_H[i], color = SKY[i]))
    layers.append(render.Column(children = sky))

    water = []
    for c in WATER:
        water.append(render.Box(width = 64, height = 1, color = c))
    layers.append(render.Padding(pad = (0, 20, 0, 0), child = render.Column(children = water)))

    # Sun low over the water, its glint dashed down the swell.
    for x, y, w in [(43, 8, 6), (41, 9, 10), (40, 10, 12), (40, 11, 12), (40, 12, 12), (40, 13, 12), (41, 14, 10), (43, 15, 6)]:
        layers.append(at(x, y, w, 1, SUN))
    for x, y, w, c in [(42, 20, 8, "#FFC985"), (44, 22, 5, "#E8A86E"), (43, 24, 4, "#C9895E"), (45, 26, 3, "#A86E52")]:
        layers.append(at(x, y, w, 1, c))

    layers.extend(peak(11, 10, 10, MTN_BACK))
    layers.extend(peak(56, 13, 7, MTN_BACK))
    layers.extend(peak(24, 15, 5, MTN_FRONT))
    return layers

def square_scene():
    """The same dusk, composed for 64 rows. Every element grows into the extra
    height rather than floating in it: eight taller sky bands, twelve water
    colors two rows each, a round sun instead of the squat ellipse that reads
    right on a 2:1 panel (and set the same fraction of the way down its much
    deeper sky), peaks twice as tall, and six glint dashes running the length
    of the water instead of four crammed into twelve rows."""
    layers = []

    sky = []
    for i in range(len(SKY)):
        sky.append(render.Box(width = 64, height = SKY_H_SQ[i], color = SKY[i]))
    layers.append(render.Column(children = sky))

    water = []
    for c in WATER:
        water.append(render.Box(width = 64, height = 2, color = c))
    layers.append(render.Padding(pad = (0, 40, 0, 0), child = render.Column(children = water)))

    # Sun low over the water, its glint dashed down the swell. A 16px disc
    # centred on x=44, the same side of the frame it sits on when wide.
    for x, y, w in [(41, 16, 6), (39, 17, 10), (38, 18, 12), (37, 19, 14), (37, 20, 14), (36, 21, 16), (36, 22, 16), (36, 23, 16), (36, 24, 16), (36, 25, 16), (36, 26, 16), (37, 27, 14), (37, 28, 14), (38, 29, 12), (39, 30, 10), (41, 31, 6)]:
        layers.append(at(x, y, w, 1, SUN))
    for x, y, w, c in [(38, 40, 12, "#FFC985"), (39, 43, 10, "#FFC985"), (40, 46, 8, "#E8A86E"), (41, 50, 6, "#E8A86E"), (42, 54, 4, "#C9895E"), (43, 58, 3, "#A86E52")]:
        layers.append(at(x, y, w, 1, c))

    layers.extend(peak(11, 20, 20, MTN_BACK))
    layers.extend(peak(56, 26, 14, MTN_BACK))
    layers.extend(peak(24, 30, 10, MTN_FRONT))
    return layers

# -------------------------------------------------------------------- schema

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "img_url",
                name = "Image URL",
                desc = "Link to a photo (JPEG, PNG, GIF, or WebP). Must be publicly reachable - it is fetched via the images.weserv.nl proxy.",
                icon = "image",
                default = "",
            ),
            schema.Dropdown(
                id = "mode",
                name = "Fit",
                desc = "How the photo fills the panel.",
                icon = "image",
                default = "cover",
                options = [
                    schema.Option(display = "Smart crop (fill)", value = "cover"),
                    schema.Option(display = "Fit whole photo", value = "contain"),
                    schema.Option(display = "Stretch", value = "fill"),
                ],
            ),
            schema.Text(
                id = "caption",
                name = "Caption",
                desc = "Optional caption, overlaid along the bottom.",
                icon = "font",
                default = "",
            ),
            # NOTE: the "proxy" config value is read in main() as a test hook
            # but is deliberately not a schema field - see the module docstring.
        ],
    )
