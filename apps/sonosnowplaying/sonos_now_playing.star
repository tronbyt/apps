"""
Applet: Sonos Now Playing
Summary: What's playing on a Sonos
Description: Track, artist, album and art from a Sonos speaker, polled directly over the LAN.
Author: nsluke

Talks straight UPnP SOAP to the speaker on port 1400 - the same interface
the SoCo project and every local Sonos controller uses. No cloud account, no
OAuth, no API key. That only works because tronbyt-style servers render on
the same network as the speaker; Tidbyt's cloud renderer never could, which
is why the original app store had no local Sonos app.

Two calls per poll, both POST /MediaRenderer/AVTransport/Control:
  #GetPositionInfo  -> TrackMetaData: a DIDL-Lite XML document that arrives
                       XML-ESCAPED INSIDE the outer XML (&amp;lt; and friends),
                       so it is unescaped one level before the track fields
                       (dc:title, dc:creator, upnp:album, upnp:albumArtURI)
                       are pulled out - and those fields then get a second
                       unescape of their own text.
  #GetTransportInfo -> CurrentTransportState (PLAYING / PAUSED_PLAYBACK /
                       STOPPED / TRANSITIONING).

Both documents are mined with string scanning, not xpath: a malformed body
handed to xpath.loads aborts the render uncatchably, while a substring scan
degrades to empty fields no matter what the speaker sends. Radios put the
station in dc:title, live info in r:streamContent, and junk in dc:creator;
line-in and grouped speakers report TrackMetaData of "NOT_IMPLEMENTED".
albumArtURI is usually relative (/getaa?...) and the art behind it is a
300-640px JPEG with no server-side resize, so the decoded-then-downscaled
bytes are cached hard - but only after a render has proved they decode, and
only from the speaker itself: the art URI is chosen by the payload, not the
user, and both an undecodable body and an unreachable art host abort a render
uncatchably.

Field notes are from public protocol documentation (SoCo et al.); developed
against a local SOAP stub - no Sonos hardware was on this bench.
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")

CONTROL_PATH = "/MediaRenderer/AVTransport/Control"
SERVICE = "urn:schemas-upnp-org:service:AVTransport:1"

FRESH_TTL = 10  # LAN poll pace when the last call worked
RETRY_TTL = 60  # back off after any failure (incl. an aborted transport error)
STALE_TTL = 300  # ride a blip on the last reading; older than 5 min is a lie
ART_TTL = 3600  # art bytes for a given URI don't change

# tom-thumb advances 4px per character, and a marquee's cycle is
# child_width + width - 1 frames at 50ms - so a 45px line completes one full
# pass in 4n + 44 frames, which must fit pixlet's 300-frame (15s) animation
# cap. 63 and 60 are the longest strings that still finish; past that the
# marquee restarts mid-string and the tail is never displayed.
MAX_LINE = 63
MAX_LABEL = 60

# Square (64x64) panel geometry. The cover becomes the picture at 40x40 -
# 6.25x the area it gets as a thumbnail beside the text on a 2:1 panel - and
# the text lines fall underneath it across the whole panel instead of into a
# 45px gutter:  1 + 40 + 2 + 6 + 1 + 6 + 1 + 7 = 64.
# By the same arithmetic as MAX_LINE, a 60px marquee's cycle is 4n + 59
# frames, so 60 characters is the longest line that still completes one pass
# inside the 300-frame cap (measured: 60 chars -> 299 frames, 61 -> pinned).
# The status bar keeps its 55px marquee, so MAX_LABEL carries over unchanged.
SQ_ART = 40
SQ_LINE_W = 60
SQ_LINE = 60

# The embedded assets are 16x16 pixel art, so on a square panel they are drawn
# at an exact 2x and centred in the 40px frame rather than stretched to fill
# it. This renderer scales nearest-neighbour, so a 2.5x resample would widen
# some source pixels to 3 and leave others at 2 - which, on a drawing this
# small, visibly breaks the speaker cabinet's symmetry (checked side by side).
SQ_ASSET = 32

# Bytes legal in a URL host besides letters and digits: % - . : [ ] _ ~
HOST_PUNCT = [37, 45, 46, 58, 91, 93, 95, 126]

WHITE = "#FFFFFF"
DIM = "#9C9C9C"
FAINT = "#5E6673"
AMBER = "#FFA33A"
GREEN = "#3BD16F"
RED = "#FF3B30"
RULE = "#33363B"

# 16x16 pixel-art assets, embedded so the demo and artless states cost zero
# network. A sunset "album cover" for the demo card and a speaker cabinet for
# tracks that come with no art (radio, line-in).
DEMO_ART = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAiklEQVR42mNQE3IiCTFYSriQhBh85dxJQgyJKp4kIYZSLR+SEMPZgECSEMO9DHc09P9aDBxhyjK8a7BFRsiqIQhNAcP/GcYoCEMDmgKG/9t9URCmBlQFDJJKTmjoRpMNHGHKMojJWZOEGISlTDARxHisUgyCYrokIQY+ITU0BDQbjYGMGHj4FEhCADsy84HttfByAAAAAElFTkSuQmCC")
SPEAKER = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAATElEQVR42mNgoATEBDhgRfg0KMlJoSGiNExrSQEiWmog2UmkaYC4B+4qAhqAioSEROAIyCVKw//FVqRpINkGEjSQ7GmSg5W0xEcMAABagVSFzaH52QAAAABJRU5ErkJggg==")

def main(config):
    room = config.str("room", "").strip()
    label = (room if room != "" else "SONOS").upper()
    ip = config.str("ip", "").strip()
    api = config.str("api", "").strip()  # test hook: point at a local stub

    base = api
    if base == "" and ip != "":
        base = base_url(ip)
    if base == "":
        return render.Root(child = demo_card())
    if not valid_host(base):
        return render.Root(child = unreachable_card(base, label, "Check speaker IP"))

    d = get_now(base)
    if d == None:
        return render.Root(child = unreachable_card(base, label, "Speaker unreachable"))

    st = d.get("st", "PLAYING")
    if st == "STOPPED" or st == "NO_MEDIA_PRESENT":
        if config.bool("hide_idle", True):
            return []
        return render.Root(child = idle_card(label))

    title = d.get("ti", "")
    if title == "":
        title = "(no track info)"
    art = art_widget(art_url(d.get("art", ""), base, config.bool("remote_art", False)))
    return render.Root(
        child = panel_card(art, title, d.get("ar", ""), d.get("al", ""), glyph(st), label, AMBER),
    )

def base_url(ip):
    """Forgive pasted forms: '192.168.1.23', 'http://192.168.1.23/',
    '192.168.1.23:1400' all become http://192.168.1.23:1400. IPv6 literals
    ('fe80::1', '[fe80::1]', '[fe80::1]:1400') get the brackets a URL host
    needs - a bare 'colon means port is present' test would build an
    unparseable URL out of every IPv6 address."""
    h = ip
    if h.find("://") >= 0:
        h = h.split("://")[1]
    h = h.split("/")[0]
    if h.startswith("["):
        # already-bracketed IPv6: add the default port if none follows
        if h.find("]:") < 0:
            h = h + ":1400"
    elif h.count(":") > 1:
        # bare IPv6 literal: every colon is part of the address, not a port
        h = "[" + h + "]:1400"
    elif h.find(":") < 0:
        h = h + ":1400"
    return "http://" + h

def valid_host(base):
    """Does the host survive Go's URL parser? A room name typed into the
    Speaker IP box ('Living Room') builds a URL whose space makes http.post
    abort the render, and Starlark cannot catch that. Unlike a dead speaker
    this is permanent, purely local and free to detect, so anything outside
    the legal host alphabet takes the diagnostic card instead of the abort.
    Deliberately generous: letters (so 'sonos.local' works), digits, and the
    punctuation an IPv4/IPv6/hostname URL is allowed to carry."""
    if not base.startswith("http://") and not base.startswith("https://"):
        return False  # a schemeless API override would abort the same way
    h = base.split("://")[1].split("/")[0]
    if h == "" or len(h) > 255:
        return False
    for o in h.elem_ords():
        alnum = (o >= 48 and o <= 57) or (o >= 65 and o <= 90) or (o >= 97 and o <= 122)
        if not alnum and o not in HOST_PUNCT:
            return False
    return True

# ---------------------------------------------------------------- data layer

def get_now(base):
    """The two SOAP calls as one gated cycle. Gate-before-request: a transport
    error (unplugged speaker, wrong IP) aborts the render and Starlark cannot
    catch it, so the gate key - written BEFORE the request - limits the damage
    to one failed render per RETRY_TTL. Handled failures (non-200, non-XML)
    leave the same gate. Returns the extracted dict, or None."""
    ck = "snp:now:" + base
    gate = ck + ":gate"
    if cache.get(gate) != None:
        return stale(ck)
    cache.set(gate, "1", ttl_seconds = RETRY_TTL)

    pos = soap_call(base, "GetPositionInfo")
    if pos == None or pos.find("GetPositionInfoResponse") < 0:
        return stale(ck)
    tr = soap_call(base, "GetTransportInfo")
    if tr == None or tr.find("GetTransportInfoResponse") < 0:
        return stale(ck)

    d = extract(pos, tr, base)
    cache.set(ck, json.encode(d), ttl_seconds = STALE_TTL)
    cache.set(gate, "1", ttl_seconds = FRESH_TTL)
    return d

def stale(ck):
    raw = cache.get(ck)
    return json.decode(raw) if raw != None else None

def soap_call(base, action):
    """One UPnP SOAP action against the speaker. Returns the body only when it
    is 200 and smells like XML; None otherwise (the caller's gate is already
    set, so a broken speaker costs at most one probe per RETRY_TTL)."""
    body = (
        '<?xml version="1.0" encoding="utf-8"?>' +
        '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" ' +
        's:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">' +
        "<s:Body><u:" + action + ' xmlns:u="' + SERVICE + '">' +
        "<InstanceID>0</InstanceID>" +
        "</u:" + action + "></s:Body></s:Envelope>"
    )
    resp = http.post(
        base + CONTROL_PATH,
        headers = {
            "SOAPACTION": '"' + SERVICE + "#" + action + '"',
            "Content-Type": 'text/xml; charset="utf-8"',
        },
        body = body,
        ttl_seconds = 5,
    )
    if resp.status_code != 200:
        print("snp: " + action + " -> HTTP " + str(resp.status_code))
        return None
    out = resp.body().strip()
    if not out.startswith("<") or out.find("Envelope") < 0:
        print("snp: " + action + " returned non-SOAP body")
        return None
    return out

def extract(pos, tr, base):
    """The wire format's one real trick: TrackMetaData is a DIDL-Lite XML doc
    escaped inside the outer XML. Unescape one level to get real DIDL, then
    each field's own text gets a second unescape (a title like
    'Movement &amp;amp; Location' needs both)."""
    st = tag_text(tr, "CurrentTransportState").strip()
    if st == "":
        st = "PLAYING"  # a speaker that answered but omitted state: show, don't hide

    ti, ar, al, art = "", "", "", ""
    meta = unescape(tag_text(pos, "TrackMetaData"))
    if meta.find("<DIDL") >= 0:
        ti = clean(tag_text(meta, "dc:title"))
        art = absolutize(clean(tag_text(meta, "upnp:albumArtURI")), base)
        if tag_text(meta, "upnp:class").find("audioBroadcast") >= 0:
            # Radio: dc:title is the station, r:streamContent carries the live
            # "artist - song" line when the station sends one, and dc:creator
            # is transport junk (x-sonosapi urls) - never show it.
            stream = clean(tag_text(meta, "r:streamContent"))
            ar = stream if stream != "" else "Live radio"
        else:
            ar = clean(tag_text(meta, "dc:creator"))
            al = clean(tag_text(meta, "upnp:album"))
    return {"st": st, "ti": ti, "ar": ar, "al": al, "art": art}

def clean(s):
    return unescape(s).strip()

def absolutize(art, base):
    """albumArtURI is usually relative (/getaa?s=1&u=...) - the speaker itself
    serves the bytes on port 1400."""
    if art == "" or art.startswith("http://") or art.startswith("https://"):
        return art
    if art.startswith("/"):
        return base + art
    return base + "/" + art

def art_url(art, base, remote_ok):
    """Which art URIs this app is willing to fetch. Sonos serves its own art
    from :1400/getaa, and that is the default answer: an albumArtURI is chosen
    by the PAYLOAD, not by the user, so an absolute one pointing off the
    speaker (a service CDN, a station logo host) can abort the render of a
    perfectly healthy speaker with a DNS or connect error the moment the
    renderer has no route to it - which on a LAN-only tronbyt server is every
    time. Off-box art therefore falls through to the speaker glyph unless the
    user opts in. The trailing slash in the prefix test matters: it stops
    'http://10.0.0.5:1400.evil.example/' from passing as the speaker."""
    if art == "":
        return ""
    if art == base or art.startswith(base + "/"):
        return art
    return art if remote_ok else ""

def get_art(url):
    """Art bytes, cached base64 and keyed by the art URI, with the SOAP calls'
    gate discipline plus a two-step trust model.

    The envelope sniff below rejects obvious garbage, but Starlark cannot
    decode-test: a standards-valid file that Go's decoder refuses (an
    arithmetic-coded JPEG is the honest example) sails through the sniff and
    then aborts the render inside render.Image. So freshly fetched bytes are
    cached UNPROVEN, and only a render that actually survived the decode
    writes the ':ok' marker (see art_widget - render.Image decodes eagerly, so
    reaching the line after it IS the proof). Bytes without that marker are
    never handed to render.Image again: one undecodable body costs one aborted
    render, not an hour of them, and it can never outlive the speaker's return
    to health."""
    if url == "":
        return None
    ck = "snp:art:" + url
    cached = cache.get(ck)
    if cached != None:
        if cache.get(art_ok_key(url)) == None:
            # Cached but unproven: these bytes aborted the render that fetched
            # them (or an older build wrote them). Don't hand them to
            # render.Image again, and don't refetch either - the speaker would
            # just serve the same bytes. The speaker glyph until the TTL runs
            # out is the cheap, quiet answer.
            return None
        body = base64.decode(cached)
        if looks_like_image(body):
            return body
        return None

    if cache.get(ck + ":gate") != None:
        return None
    cache.set(ck + ":gate", "1", ttl_seconds = RETRY_TTL)

    resp = http.get(url, ttl_seconds = ART_TTL)
    if resp.status_code != 200:
        print("snp: art -> HTTP " + str(resp.status_code))
        return None
    body = resp.body()
    if not looks_like_image(body):
        print("snp: art bytes don't look like an image")
        return None
    cache.set(ck, base64.encode(body), ttl_seconds = ART_TTL)
    return body

def art_ok_key(url):
    """Marker that these art bytes have survived a render.Image decode."""
    return "snp:art:" + url + ":ok"

def looks_like_image(body):
    """Envelope sniff (JPEG/PNG/GIF): magic bytes at the front AND the
    format's end marker near the back. A header-only check waves truncated or
    garbage-after-magic bytes straight into render.Image, which aborts the
    whole render on undecodable data. It is a cheap filter, not a decoder -
    the real containment for 'passed the sniff, still won't decode' is the
    unproven-bytes rule in get_art.

    The end marker is searched across a window rather than demanded at a fixed
    offset, because trailing padding after the marker is common in the wild
    (art lifted out of ID3 APIC frames especially) and Go decodes those fine -
    a stricter sniff than the decoder just throws away art that would have
    rendered. The GIF window is tighter than the others: its trailer is a
    single byte (0x3B), so a wide window would match compressed data by
    accident. Byte values via elem_ords - Starlark string literals can't hold
    raw high bytes."""
    if len(body) < 50:
        return False
    head = list(body[0:4].elem_ords())
    if body.startswith("GIF8"):
        # GIF trailer 0x3B, allowing a little padding behind it
        for o in body[-16:].elem_ords():
            if o == 59:
                return True
        return False
    if head[0:3] == [255, 216, 255]:  # JPEG
        tail = list(body[-256:].elem_ords())
        for i in range(len(tail) - 1):  # EOI marker FF D9
            if tail[i] == 255 and tail[i + 1] == 217:
                return True
        return False
    if head == [137, 80, 78, 71]:  # PNG
        return body[-256:].find("IEND") >= 0
    return False

# ---------------------------------------------------- XML without a parser

def unescape(s):
    """One level of XML entity unescaping. &amp; strictly last, so one call
    peels exactly one layer of Sonos's nested escaping."""
    s = s.replace("&lt;", "<").replace("&gt;", ">")
    s = s.replace("&quot;", '"').replace("&apos;", "'")
    s = s.replace("&#34;", '"').replace("&#39;", "'")
    return s.replace("&amp;", "&")

def tag_text(doc, name):
    """Text of the first <name ...>...</name> element, by substring scan.
    Chosen over xpath.loads deliberately: a truncated or malformed document
    aborts the XML parser (and with it the render), while this returns ""
    for anything it can't find. Skips false prefix hits (<Track vs
    <TrackMetaData) and self-closed tags."""
    start = 0
    for _ in range(25):
        i = doc.find("<" + name, start)
        if i < 0:
            return ""
        after = i + 1 + len(name)
        nxt = doc[after:after + 1]
        if nxt != ">" and nxt != " " and nxt != "\t" and nxt != "\n" and nxt != "/":
            start = i + 1  # matched a longer tag name; keep looking
            continue
        j = doc.find(">", i)
        if j < 0:
            return ""
        if doc[j - 1:j] == "/":
            return ""  # self-closed: no text
        k = doc.find("</" + name + ">", j)
        if k < 0:
            return ""
        return doc[j + 1:k]
    return ""

# -------------------------------------------------------------------- views

def is_square():
    """True on a square panel, false on the 2:1 one.

    Branches on the panel's SHAPE, never its height: an aspect test is right
    at either scale (128x64 is wide, 128x128 is square) where `h == 64` is
    ambiguous between them. The slack keeps a merely tallish panel - 64x40 -
    on the wide branch.

    On scale, precisely, because the SQ_* constants below are absolute pixel
    counts and only hold on a 64-unit canvas: canvas.size() reports the
    DOUBLED canvas only for an app whose manifest sets `supports2x: true`
    (pixlet clears the 2x flag otherwise, and size() returns the scaled
    dimensions). This app's manifest does not set it, so canvas.size() is
    always the logical panel - 64x32 or 64x64 - and rendering at 2x is pure
    magnification of a 64-unit card. That is the precondition that keeps a
    fixed 64-wide layout centred instead of stranded in the corner of a
    128x128 canvas; opting into supports2x later would mean scaling SQ_ART,
    the line widths and the status bar to match. The predicate itself needs
    no change either way - it is already correct at both scales."""
    w, h = canvas.size()
    return h * 2 > w + 16

def panel_card(art, title, artist, album, state_glyph, label, label_color):
    """One card, two panels. Every state in this app - playing, radio, idle,
    demo, unreachable - is a card, so the shape test lives here once."""
    if is_square():
        return square_card(art, title, artist, state_glyph, label, label_color)
    return card(art, title, artist, album, state_glyph, label, label_color)

def card(art, title, artist, album, state_glyph, label, label_color):
    """16px art | three tom-thumb marquee lines, over a 7px status bar:
    play-state glyph + room label. 2 + 22 + 1 + 7 = 32."""
    return render.Column(
        children = [
            render.Box(width = 64, height = 2),
            render.Row(
                children = [
                    render.Padding(pad = (1, 3, 0, 0), child = art),
                    render.Padding(
                        pad = (2, 0, 0, 0),
                        child = render.Column(
                            children = [
                                line(title, WHITE),
                                render.Box(width = 1, height = 2),
                                line(artist, DIM),
                                render.Box(width = 1, height = 2),
                                line(album, FAINT),
                            ],
                        ),
                    ),
                ],
            ),
            render.Box(width = 64, height = 1, color = RULE),
            status_bar(state_glyph, label, label_color),
        ],
    )

def square_card(art, title, artist, state_glyph, label, label_color):
    """The 64x64 card: same colours, same font, same status bar - but the
    cover stops being a thumbnail and becomes the picture, 40x40 across the
    top with the text stacked full-width underneath instead of squeezed into
    a 45px gutter beside it. The album line is what pays for that: on this
    panel the sleeve IS the album, at 6.25x the area it gets on the 2:1 one,
    so the two lines that a cover cannot show - the track and who plays it -
    are the two that stay. 1 + 40 + 2 + 6 + 1 + 6 + 1 + 7 = 64."""
    return render.Column(
        children = [
            render.Box(width = 64, height = 1),
            render.Box(width = 64, height = SQ_ART, child = art),
            render.Box(width = 64, height = 2),
            sq_line(title, WHITE),
            render.Box(width = 64, height = 1),
            sq_line(artist, DIM),
            render.Box(width = 64, height = 1, color = RULE),
            status_bar(state_glyph, label, label_color),
        ],
    )

def status_bar(state_glyph, label, label_color):
    """Play-state glyph + room label. 64x7 on either panel - the wide card's
    bar was already full-width, so the square one keeps it pixel for pixel
    (and with it MAX_LABEL, which is tuned to this 55px marquee)."""
    return render.Box(
        width = 64,
        height = 7,
        child = render.Row(
            children = [
                render.Padding(pad = (1, 1, 0, 0), child = render.Box(width = 5, height = 5, child = state_glyph)),
                render.Padding(
                    pad = (2, 1, 0, 0),
                    child = render.Marquee(
                        width = 55,
                        child = render.Text(fit(label, MAX_LABEL), font = "tom-thumb", color = label_color),
                    ),
                ),
            ],
        ),
    )

def sq_line(text, color):
    """A full-width text line on the square panel. Wider viewport, shorter
    string budget: a 60px marquee takes 4n + 59 frames to complete a pass, so
    SQ_LINE is 60 where the 45px wide-panel line affords 63."""
    return render.Padding(
        pad = (2, 0, 0, 0),
        child = render.Marquee(
            width = SQ_LINE_W,
            child = render.Text(fit(text, SQ_LINE), font = "tom-thumb", color = color),
        ),
    )

def line(text, color):
    return render.Marquee(
        width = 45,
        child = render.Text(fit(text, MAX_LINE), font = "tom-thumb", color = color),
    )

def fit(s, limit):
    """Elide to what one full marquee pass can actually show. A string longer
    than the cap scrolls past the 15s animation cap, so the marquee restarts
    mid-string and the tail is NEVER on screen - an ellipsis at a length that
    completes is more honest than a promise the loop can't keep. Counted in
    codepoints, and cut on a codepoint boundary, so a unicode title can't be
    sliced into invalid UTF-8."""
    if len(s) <= limit:  # byte length; codepoints can only be fewer
        return s
    out = ""
    n = 0
    for c in s.codepoints():
        if n >= limit - 3:
            return out + "..."
        out += c
        n += 1
    return out

def art_widget(url):
    """The art tile - and the only place bytes are proved decodable.
    render.Image DECODES EAGERLY, inside this call, so a body Go's decoder
    refuses aborts the render right here and the cache.set below never runs.
    Reaching that line is therefore proof the bytes decoded, and it is what
    promotes them from unproven to reusable for the rest of ART_TTL."""
    body = get_art(url)
    if body == None:
        return asset_image(SPEAKER)
    px = SQ_ART if is_square() else 16
    img = render.Image(src = body, width = px, height = px)
    cache.set(art_ok_key(url), "1", ttl_seconds = ART_TTL)
    return img

def asset_image(src):
    """One of the two embedded 16x16 pixel-art tiles, at the size its panel
    wants: 16 on the 2:1 panel, an exact 2x on the square one (SQ_ASSET), so
    the drawn pixels stay square inside the 40px art frame."""
    px = SQ_ASSET if is_square() else 16
    return render.Image(src = src, width = px, height = px)

def glyph(st):
    if st == "PAUSED_PLAYBACK" or st == "PAUSED_RECORDING":
        return render.Row(
            children = [
                render.Box(width = 2, height = 5, color = AMBER),
                render.Box(width = 1, height = 5),
                render.Box(width = 2, height = 5, color = AMBER),
            ],
        )
    if st == "STOPPED":
        return render.Box(width = 4, height = 4, color = DIM)

    # PLAYING / TRANSITIONING: a blocky right-pointing triangle
    return render.Row(
        cross_align = "center",
        children = [
            render.Box(width = 1, height = 5, color = GREEN),
            render.Box(width = 1, height = 5, color = GREEN),
            render.Box(width = 1, height = 3, color = GREEN),
            render.Box(width = 1, height = 1, color = GREEN),
        ],
    )

def demo_card():
    """Default config: no speaker IP yet. Zero network - the art ships in the
    binary. Looks like the real thing, says so in the status bar."""
    return panel_card(
        asset_image(DEMO_ART),
        "Sunset Interlude",
        "The Analog Hearts",
        "Warm Static",
        glyph("PLAYING"),
        "DEMO - SET SPEAKER IP",
        AMBER,
    )

def idle_card(label):
    return panel_card(
        asset_image(SPEAKER),
        "Nothing playing",
        "",
        "",
        glyph("STOPPED"),
        label,
        DIM,
    )

def unreachable_card(base, label, why):
    """Two ways to have no speaker, told apart: nothing answered at an address
    that could exist ('Speaker unreachable'), or the address itself is not one
    ('Check speaker IP' - a room name in the IP box)."""
    host = base.replace("http://", "").replace("https://", "")
    return panel_card(
        asset_image(SPEAKER),
        why,
        host,
        "",
        render.Box(width = 4, height = 4, color = RED),
        label,
        DIM,
    )

# ------------------------------------------------------------------- schema

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ip",
                name = "Speaker IP address",
                desc = "LAN address of the Sonos speaker, e.g. 192.168.1.23. Your Sonos app lists it under Settings > About My System.",
                icon = "server",
                default = "",
            ),
            schema.Text(
                id = "room",
                name = "Room label",
                desc = "Name shown in the status bar, e.g. Living Room.",
                icon = "tag",
                default = "",
            ),
            schema.Toggle(
                id = "hide_idle",
                name = "Hide when stopped",
                desc = "Skip the app entirely while nothing is playing.",
                icon = "eyeSlash",
                default = True,
            ),
            schema.Toggle(
                id = "remote_art",
                name = "Allow art from the internet",
                desc = "Off by default: only art the speaker serves itself is fetched. Turn on if your stations' logos live on the web and this server has internet access.",
                icon = "globe",
                default = False,
            ),
        ],
    )
