"""
Applet: Podcast Tracker
Summary: Latest episode of your show
Description: Artwork, title, and freshness of the newest episode of any podcast, found by name on Apple Podcasts or straight from an RSS feed URL.
Author: nsluke

Layout (2:1 panel): 16px artwork tile (episode length under it) | show name
over an episode-title marquee, with the age at the bottom and an amber NEW
badge while the episode is under 36 hours old.

Layout (square panel): podcast artwork is square, so a square panel can show
it the way a phone does -- one big centred cover, 40px on a 64x64 -- with the
show name, the episode-title marquee and an age/NEW + length footer stacked
underneath it. The 2:1 strip has no room for that and squeezes the cover into
a 16px chip beside the text; the square one does not have to. The text block
below the cover costs a fixed 24 rows, so a square panel under 40 rows tall has
no room left for a cover worth the name and drops it: the text spreads over the
whole frame instead. Drawing one anyway is not a smaller cover, it is a Column
taller than the panel, and a Column that overruns doesn't shrink -- it pushes
the footer off the bottom edge.

Data, two steps, both keyless:
  1. iTunes Search API resolves a show name -> feedUrl + artworkUrl100.
     The artwork URL ends in /100x100bb.jpg and that segment can be rewritten
     to /16x16bb.jpg so the CDN resizes server-side: the render decodes a
     ~900 byte JPEG instead of a 600px sleeve (the album_art lesson). The
     rewritten size is whatever the panel actually draws -- 16 on the strip,
     40-odd on the square -- so neither panel upscales a thumbnail nor
     downscales a sleeve, and since the size is in the URL it is also in the
     artwork cache key. The mzstatic CDN has 403'd pixlet's default Go
     user-agent before, so every request sends a browser-ish UA.
  2. The RSS feed itself for channel title + first item. Feeds can be
     multi-MB (Relay ~3MB, some Libsyn feeds ~16MB), so the few fields are
     extracted immediately and only those are cached; the parse is paid once
     per FRESH_FEED window.

Field notes from probing real feeds: pubDate day-of-month is NOT reliably
zero-padded ("Wed, 2 Sep 2026...", simplecast) and the zone can be numeric or
named ("GMT", Relay) - Go's RFC1123 layouts reject one or the other, and a
time.parse_time failure aborts the render, so dates are parsed by hand and an
unparseable one just omits the age. itunes:duration is "HH:MM:SS", "MM:SS",
or bare seconds depending on the host. In RSS-URL mode there is no Apple
artwork; the feed's own itunes:image/@href (then channel image/url) is used,
capped at ART_MAX_BYTES because those images are full-size covers - over the
cap the app draws its pixel-mic tile instead of decoding megapixels forever.

Three things reach http.get and render.Image that this app does not control,
and each one aborts a render uncatchably, so each is fenced:
  - URLs. A feed's href can be relative ("/img/cover.jpg") and a typed feed
    URL can be missing its scheme; http.get raises on both. Third-party URLs
    must already be absolute http(s) (absolute_http); typed ones get https://
    added or a card (typed_url).
  - Image bytes. Header magic alone passes a truncated download, so the
    format terminator is checked too - and because no sniff can prove bytes
    are decodable, get_art stamps the fetch unconfirmed and main confirms it
    only after the card (and so render.Image) is built. Cached bytes still
    unconfirmed on a later render are the bytes that killed the render before,
    and get buried - one lost frame instead of a cache lifetime of them.
  - Bodies that are 200 but unusable. That is the origin's steady state, not
    an outage, so the gate holds for BAD_FEED_TTL instead of RETRY_TTL - a
    4MB feed that will never parse must not be re-downloaded every minute.
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")
load("xpath.star", "xpath")

ITUNES_BASE = "https://itunes.apple.com"

# The artwork CDN (is1-ssl.mzstatic.com) has hard-rejected Go-default user
# agents (measured 10/10 403s by the album_art app); the search endpoint
# doesn't care. Send it everywhere so there is one rule to remember.
USER_AGENT = "tronbyt:podcast-tracker:1.0 (+https://github.com/tronbyt/apps)"

# A transport error or a bad status is an outage: come back in a minute. A
# 200 whose body is unusable is what this origin always serves, and treating
# that as an outage is how a 4MB feed turns into ~5GB of downloads a day.
RETRY_TTL = 60
BAD_FEED_TTL = 1800

FRESH_FEED = 1800  # re-read the feed every 30 min
STALE_TTL = 172800  # serve the last good extract up to 48h through an outage
RESOLVE_TTL = 259200  # show name -> feed URL mapping, re-checked every 3d
NOTFOUND_TTL = 3600  # "no such show" is a real answer, but re-ask hourly
IMAGE_TTL = 86400

# Cached artwork is the one thing that can abort a render with no network
# involved, so it ages out in hours, carries a receipt (ART_UNCONFIRMED until
# a render has actually drawn it), and can be buried outright (ART_TOMBSTONE).
# Covers over the byte cap never stop costing a megapixel decode per render,
# so they are buried too.
IMAGE_STORE = 21600
ART_UNCONFIRMED = "0"
ART_CONFIRMED = "1"
ART_TOMBSTONE = "-"
ART_MAX_BYTES = 300000

# Bumped whenever the shape or the lifetime of a cached value changes, so a
# server that has been running the previous build starts clean instead of
# rendering extracts written under the old rules.
CACHE_GEN = "v2"

# One marquee frame per pixel at ~6px a character: a 110-character title ran
# a 35s cycle, and show_full_animation asks the panel to sit through all of
# it. Clipping shorter and stepping a little faster keeps it under ~20s.
TITLE_CLIP = 72
ROOT_DELAY = 40

# Rows the square layout spends on everything below the cover: the rule, the
# show name, the title marquee, the footer and the gaps between them. The
# cover gets the rest, so it grows with the panel instead of being pinned to
# a number that happens to suit a 64x64 one.
#
# SQUARE_ART_MIN is a threshold, not a floor: below it there is no cover at
# all. Clamping a too-small remainder back up to a minimum would ask for more
# rows than the panel has, and the overrun comes off the bottom - the footer
# first, then the title.
SQUARE_TEXT_H = 24
SQUARE_ART_MIN = 16

# 36h of "new". 6h of clock/zone slop is forgivable on a pubDate; further
# ahead than that is junk, not a brand-new episode. A duration over a day
# means the host published milliseconds.
NEW_WINDOW = 129600
FUTURE_SLACK = 21600
DUR_MAX = 86400

WHITE = "#FFFFFF"
GREY = "#9C9C9C"
DIM = "#9aa4b8"
AMBER = "#FFA33A"
RULE = "#1c1f2a"
TILE_BG = "#161821"

# Image markers that can't be spelled in a Starlark literal: JPEG starts FF D8
# (base64 "/9g=") and ends FF D9; GIF ends with the 0x3B trailer.
JPEG_SOI = "/9g="
JPEG_EOI = base64.decode("/9k=")
GIF_TERM = base64.decode("Ow==")

MONTHS = {
    "Jan": 1,
    "Feb": 2,
    "Mar": 3,
    "Apr": 4,
    "May": 5,
    "Jun": 6,
    "Jul": 7,
    "Aug": 8,
    "Sep": 9,
    "Oct": 10,
    "Nov": 11,
    "Dec": 12,
}

ZONES = {
    "GMT": 0,
    "UT": 0,
    "UTC": 0,
    "Z": 0,
    "EST": -18000,
    "EDT": -14400,
    "CST": -21600,
    "CDT": -18000,
    "MST": -25200,
    "MDT": -21600,
    "PST": -28800,
    "PDT": -25200,
}

# Sunset "cover" for the zero-network demo card. Fetched artwork gets the CDN
# to resize to exactly the pixels the panel draws; an embedded asset has no
# CDN, so it is embedded once per size a real panel asks for -- 16 for the 2:1
# strip's chip, 40 for a 64x64 square, 104 for a 128x128 one. Each is the same
# sky, sun and furrowed foreground redrawn at that size, not the one below it
# stretched: 40 -> 104 is 2.6x, which breaks a flat gradient into uneven two-
# and three-pixel bands, and that is the exact failure the square layout was
# built to stop doing to real covers.
DEMO_ART_16 = """
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAnUlEQVR42mPQEzMhCTFYyRiRhBjclAxJ
QgxBGgaY6P+JGAjClGKI09NDQ3DVEIQmy5BloouMoOrerIIiMBdZAUOZlQ4ywqoBWQFDk4MWMsKqAVkB
Q5+bJhpC8wOaLMMsHw1MBFeNKcWwLEiNJMRgJSdFEmJQExGDIDcVKTgbD5dBS0RMC8yHMAhyGfTAfCAJ
R/i5DEC+kYgYHBHkAgBI3N3Sf6M3xAAAAABJRU5ErkJggg==
"""

DEMO_ART_40 = """
iVBORw0KGgoAAAANSUhEUgAAACgAAAAoCAIAAAADnC86AAABfklEQVR42sXUv0rDUBgF8PMQl4sEVE
Rpm6RNmlQpVJEi/qGIIh0cRHBwcXBxcHFwcHFwcXBxcHHo4JP4ML6DtlwaQpN898s14cJvuLk5nLOk
RSA3rUC81LMCfadnBbaXYyswXI2twP5aZAVG65GB3+/LhFkDThpdvvReVqkqjFtdJnpV4bfh3As5OK
sKsxAX7VCLv6pwOnEVBFr5Az9fM3mvOJ24jgJa4WRaJqOtxU2vQ9Ov5m1ra3G71aGZDWtrcddv08yG
tbW4H7RpZsPaWjzs+DSzYW0tHnd9mtlXra3F09DTKvs75nTiec/TKvvPxenEy4HLwV9lFuL1yGXirP
Lb8DZq8dGrparwftwykN4za8DHadMKfJ41rcBk3LACgxXHCnvDDSEXHG44U9n7ajNoCpmm0guXdWTg
CplQ6fRNVlUZeEIqKp085qowA19If55W5yLVZtCZn6YHQuUZqFMgJKGOzGw4FJKg0pVnEAlJUOk6Mo
iFLKLSROA/mT82n6ifHuDkjwAAAABJRU5ErkJggg==
"""

DEMO_ART_104 = """
iVBORw0KGgoAAAANSUhEUgAAAGgAAABoCAMAAAAqwkWTAAABDlBMVEX/7Kr/yFymUiakUSajUCahUCef
TyeeTiecTSeaTCeZSyiXSiiVSiiUSSiSSCiQRymPRimNRimLRSmKRCmIQyqGQiqFQSqDQCqBQCqAPyp+
Pit8PSt7PCt5PCt3Oyt2Oix0OSxyOCxxNyxvNixtNi1sNS1qNC1oMy1nMi1lMi5jMS5iMC5gLy5eLi5d
LS9bLC9ZLC9YKy9WKi9UKTBTKDBRKDBPJzBOJjBMJTBKJDFGJBpJIzFHIjFFIjFEITFCIDJAHzI/HjI9
HjI7HTI6HDM6Hho4GzM2GjM1GTMzGDMxGDQwFzQuFjQyFBYxFBYwFBYvFBYuFBYtFBYsFBYrFBYqFBYp
FBYoFBYnFBYmFBZrNiMAAAACPUlEQVR42u3W144aQRCF4b+dc84555yNc46wNrALvP+LeN1a2d6BPlVt
RiVZ8neFVDPnv1kt8DUIX4LwOQifgvAxCB+C8D4Ib4PwJgivg/AqCC+D8CIIz4PwLAhPg/CkRlql6lUe
+6UpFS/zyCkVeN/noU8qcg7wwCNJrgnuOySDZ4N7tmRyjHDXlBzsFe5Ykos5w21DcrJ2uGXwhqwdbmrJ
zRjihpQq6CWuS9NzrJi+6CWuKcXMzJSc4qoiMjNScooriu40S3KKy4LVaZbUFpeE2pDa4qJgdholtcUF
oTaktjhflmpDSYxxrszRaZTEGGfL6kNijDNl9SExxumy+pAY41RZ/R+DGOOkUBtSW5wQakNqi+NC7b8g
tcUxoTaktjgqpLqviaS2OKLUffHJKQ4rSZaaVznFIanmN4Ne4qCUSj+DZhz0Egc0/886Y4j9mj9kDLHP
4O1YO+y1+DrmDHssvpA5w26Tp2OvsMtmdxwj7HSwOp4NdriojG+B7T7ljnOAbV6zM+7X2VqhWal5ly11
flcqX2RzEDYFYWMQNgRhfRDWBWFtENYE4V2Q/6F/IDRp6Pw0KfrrM0GdCeNV8pPjojnOBHXGjP6QnxwV
zXUmqDNi6Zf85FLRnGeCOh0WV+QnF4vmPhPU6TDM8pPDohbOBHWGDJblj4OiVs4EdQb0+/ljv6ilM0Gd
Pvnj96LWzgR1cuhbUX6ynTNBneXQQlF+sq0zQZ0FeiX5yV5rZ4I6Pbqz5Se7RfVngjrdHzOqRKMifFkE
AAAAAElFTkSuQmCC
"""

# Ascending, so demo_art() can walk it and stop at the first one big enough.
DEMO_ART_TWINS = [(16, DEMO_ART_16), (40, DEMO_ART_40), (104, DEMO_ART_104)]

def main(config):
    mode = config.str("find_by", "search")
    show = config.str("show", "").strip()
    typed_rss = config.str("rss_url", "").strip()
    want_art = config.bool("artwork", True)

    # A cleared field yields "" rather than the schema default, so the test
    # hooks fall back here instead of sending http.get a scheme-less URL.
    base = typed_url(config.str("api", ITUNES_BASE))
    if base == "":
        base = ITUNES_BASE
    typed_proxy = config.str("feedproxy", "").strip()

    now = time.now().unix

    if (mode == "rss" and typed_rss == "") or (mode != "rss" and show == ""):
        demo = {
            "show": "Your Podcast Here",
            "title": "The latest episode title lands here",
            "epoch": now - 7200,
            "dur": 1681,
            "noeps": False,
        }
        art = demo_art() if want_art else None
        return root_card(episode_card(demo, art, now, want_art))

    rss = typed_url(typed_rss)
    proxy = typed_url(typed_proxy)
    if (mode == "rss" and rss == "") or (typed_proxy != "" and proxy == ""):
        return root_card(message_card("PODCAST TRACKER", "Bad feed URL", "needs http:// or https://"))

    data, err = get_episode(mode, show, rss, base, proxy)

    if data == None:
        if err == "notfound":
            return root_card(message_card("PODCAST TRACKER", "Show not found", "no Apple match for \"" + show + "\""))
        return root_card(message_card(show if show != "" else "PODCAST TRACKER", "Feed unavailable", "retrying shortly"))

    if data.get("noeps", False):
        return root_card(message_card(data.get("show", "") or "PODCAST TRACKER", "No episodes yet", "check back soon"))

    art = None
    art_url = ""
    px = art_px()
    if want_art and px > 0:
        art_url = data.get("art", "")
        art = get_art(art_url, px)

    card = episode_card(data, art, now, want_art)

    # Building the card is what calls render.Image, so getting here means the
    # bytes decoded. get_art buries any fetch that never reached this line.
    if art != None:
        confirm_art(art_url, px)
    return root_card(card)

def root_card(child):
    return render.Root(delay = ROOT_DELAY, show_full_animation = True, child = child)

# ---------------------------------------------------------------- panel shape

def is_square():
    """True on a square panel, false on the 2:1 one.

    Branch on the canvas SHAPE, never its size: a 2x device reports the
    doubled canvas -- 128x64 when it is wide, 128x128 when it is square -- so
    a bare height test calls both of those 64-tall and gets one of them wrong.
    The slack keeps a merely tallish panel on the wide branch.
    """
    w, h = canvas.size()
    return h * 2 > w + 16

def square_art_px():
    """The cover's edge on a square panel: whatever height the text block
    doesn't need, never wider than the panel. 40 on a 64x64, 104 on a 128x128.

    Zero when what's left is under SQUARE_ART_MIN -- a square panel shorter
    than SQUARE_TEXT_H + SQUARE_ART_MIN rows cannot have both, and the text is
    the half that carries the information. Zero is the answer, not a clamped
    minimum: the minimum would need more rows than the panel has, and the
    overrun is silent, so the panel would just stop drawing the footer."""
    w, h = canvas.size()
    px = h - SQUARE_TEXT_H
    if px > w:
        px = w
    if px < SQUARE_ART_MIN:
        return 0
    return px

def art_px():
    """How many pixels of cover to ask the CDN for -- which is exactly how
    many this panel is about to draw. Zero means it will draw none, so there
    is nothing to ask for."""
    if is_square():
        return square_art_px()
    return 16

def demo_art():
    """The zero-network demo cover at the size this panel draws: the smallest
    embedded twin that does not have to be stretched to fill it. Every shipping
    panel hits one exactly; anything in between is scaled down rather than up,
    because blowing a cover up is the one thing the square layout exists to
    stop doing. None when the panel is drawing no cover at all."""
    px = art_px()
    if px <= 0:
        return None
    pick = DEMO_ART_TWINS[-1]
    for twin in DEMO_ART_TWINS:
        if twin[0] >= px:
            pick = twin
            break
    return base64.decode(pick[1].replace("\n", ""))

# ------------------------------------------------------------------- URL fence

def absolute_http(u):
    """A URL supplied by someone else (a feed's itunes:image href, Apple's
    feedUrl): usable as-is or not at all. http.get raises uncatchably on a
    relative "/img/cover.jpg" or a protocol-relative "//cdn/x.jpg", and
    guessing a scheme for a stranger's host only turns that into a DNS abort,
    so anything not already absolute gets dropped and the mic glyph drawn."""
    u = u.strip()
    low = u.lower()
    if low.startswith("http://") or low.startswith("https://"):
        return u
    return ""

def typed_url(u):
    """A URL the user typed. Pasting a feed address without its scheme is
    normal ("feeds.npr.org/510318/podcast.xml"), so https:// is added; a
    non-http scheme or a bare path can't be fixed and returns "", which the
    caller turns into a card rather than an aborted render."""
    u = u.strip()
    if u == "":
        return ""
    low = u.lower()
    if low.startswith("http://") or low.startswith("https://"):
        return u
    if u.find("://") >= 0 or u.startswith("/"):
        return ""
    return "https://" + u

# ---------------------------------------------------------------- data layer

def get_episode(mode, show, rss, base, proxy):
    """Returns (extract, err): extract may be stale; err is "" when there is
    something to show, else "notfound" / "unreachable"."""
    src = ("r:" + rss if mode == "rss" else "s:" + show.lower()) + "|" + base + "|" + proxy
    ck = "pt:" + CACHE_GEN + ":ep:" + src
    gate = ck + ":gate"
    raw = cache.get(ck)
    cached = json.decode(raw) if raw != None else None

    if cache.get(gate) != None:
        # Recently fetched or recently failed: no network this render.
        return cached, ("" if cached != None else "unreachable")

    feed_url = ""
    art_hint = ""
    if mode == "rss":
        feed_url = rss
    else:
        res = resolve_show(show, base)
        if res == None:
            return cached, ("" if cached != None else "unreachable")
        if res.get("none", False):
            return cached, ("" if cached != None else "notfound")

        # Apple's feedUrl is third-party text like any other.
        feed_url = absolute_http(res.get("feed", ""))
        art_hint = res.get("art", "")

    if proxy != "":
        feed_url = proxy
    if feed_url == "":
        return cached, ("" if cached != None else "unreachable")

    data = fetch_feed(feed_url, gate)
    if data == None:
        return cached, ("" if cached != None else "unreachable")

    if art_hint != "":
        # mzstatic art resizes server-side to 16px; always prefer it.
        data["art"] = art_hint
    cache.set(ck, json.encode(data), ttl_seconds = STALE_TTL)
    return data, ""

def resolve_show(term, base):
    """Show name -> {feed, art} via the iTunes Search API, or {"none": True}
    when Apple has no usable match, or None when the search is unreachable."""
    ck = "pt:" + CACHE_GEN + ":res:" + term.lower() + "|" + base
    raw = cache.get(ck)
    if raw != None:
        return json.decode(raw)
    gate = ck + ":gate"
    if cache.get(gate) != None:
        return None
    cache.set(gate, "1", ttl_seconds = RETRY_TTL)

    resp = http.get(
        base + "/search",
        params = {"media": "podcast", "limit": "1", "term": term},
        headers = {"User-Agent": USER_AGENT},
        ttl_seconds = RETRY_TTL,
    )
    if resp.status_code != 200:
        print("podcast: search -> " + str(resp.status_code))
        return None
    body = resp.body().strip()
    if not (body.startswith("{") and body.endswith("}")):
        # 200 and not JSON: whatever is on that host, it isn't the API.
        print("podcast: non-JSON search body")
        cache.set(gate, "1", ttl_seconds = BAD_FEED_TTL)
        return None
    d = json.decode(body)

    results = d.get("results", [])
    feed = ""
    art = ""
    if len(results) > 0:
        feed = results[0].get("feedUrl", "") or ""
        art = results[0].get("artworkUrl100", "") or ""
    if feed == "":
        # A real answer (including a result with no feed): cache it briefly.
        out = {"none": True}
        cache.set(ck, json.encode(out), ttl_seconds = NOTFOUND_TTL)
        return out
    out = {"feed": feed, "art": art}
    cache.set(ck, json.encode(out), ttl_seconds = RESOLVE_TTL)
    return out

def fetch_feed(url, gate):
    """Gate-before-request (a transport error aborts the render uncatchably),
    sniff-before-parse (a CDN error page must not reach xpath.loads), and
    extract-then-drop: only a few small fields survive a multi-MB body."""
    cache.set(gate, "1", ttl_seconds = RETRY_TTL)
    resp = http.get(url, headers = {"User-Agent": USER_AGENT}, ttl_seconds = RETRY_TTL)
    if resp.status_code != 200:
        print("podcast: feed -> " + str(resp.status_code))
        return None
    body = resp.body()

    # Skip any BOM/junk before the first tag (can't spell 0xEF in a Starlark
    # literal, so hunt for "<" instead).
    i = body.find("<")
    if i < 0:
        return unusable(gate, "no markup in feed body")
    if i > 0:
        body = body[i:]
    head = body[0:300].strip()
    if not (head.startswith("<?xml") or head.startswith("<rss")):
        return unusable(gate, "body is not RSS")

    # rfind, not a fixed tail window: caching plugins bolt a "Performance
    # optimized by..." comment on after </rss>, and a perfectly good feed
    # must not be rejected for it.
    if body.find("<channel") < 0 or body.rfind("</rss>") < 0:
        return unusable(gate, "truncated or channel-less feed")

    d = xpath.loads(body)

    # An item with no <title> is still an episode: key "are there episodes?"
    # off the item, not off one optional child of it.
    it_title = txt(d, "/rss/channel/item[1]/title")
    if it_title == "":
        it_title = txt(d, "/rss/channel/item[1]/itunes:title")
    if it_title == "":
        desc = txt(d, "/rss/channel/item[1]/description")
        if desc.find("<") < 0:
            it_title = desc
    pub = txt(d, "/rss/channel/item[1]/pubDate")
    has_item = (
        it_title != "" or pub != "" or
        txt(d, "/rss/channel/item[1]/enclosure/@url") != "" or
        txt(d, "/rss/channel/item[1]/guid") != ""
    )

    art = txt(d, "/rss/channel/itunes:image/@href")
    if art == "":
        art = txt(d, "/rss/channel/image/url")

    cache.set(gate, "1", ttl_seconds = FRESH_FEED)
    return {
        "show": clip(txt(d, "/rss/channel/title"), 48),
        "title": clip(it_title, TITLE_CLIP) if it_title != "" else ("Untitled episode" if has_item else ""),
        "epoch": parse_pubdate(pub),
        "dur": parse_duration_s(txt(d, "/rss/channel/item[1]/itunes:duration")),
        "art": art,
        "noeps": not has_item,
    }

def unusable(gate, why):
    """A 200 whose body will never parse is a property of the origin, not an
    outage: hold the gate for BAD_FEED_TTL so the body isn't re-downloaded
    every RETRY_TTL for as long as the app is installed."""
    print("podcast: " + why)
    cache.set(gate, "1", ttl_seconds = BAD_FEED_TTL)
    return None

def art_target(url, px):
    """The URL artwork is actually fetched from: absolute http(s) only, with
    the mzstatic size segment rewritten so the CDN hands back exactly the
    pixels this panel draws -- 16 for the 2:1 tile, 40-odd for the square
    cover. Asking for the size we render is the whole album_art lesson, and
    because the size lives in the URL it lives in the cache key too, so the
    two panels can never serve each other's bytes. "" means "don't fetch
    anything". In RSS-URL mode there is no size segment to rewrite: the feed's
    own cover comes at whatever size the host serves, bounded by
    ART_MAX_BYTES, and render.Image scales it to the tile."""
    url = absolute_http(url)
    if url.endswith("/100x100bb.jpg"):
        return url[0:len(url) - 13] + str(px) + "x" + str(px) + "bb.jpg"
    return url

def get_art(url, px):
    """Artwork bytes, cached base64. render.Image aborts on bytes it can't
    decode and no sniff can prove decodability, so this pairs the sniff with a
    receipt: a fetch stamps ART_UNCONFIRMED alongside the bytes, and main
    stamps ART_CONFIRMED only once the card - and so render.Image - has been
    built. Cached bytes that are still unconfirmed on a later render are the
    bytes that killed the render before, and get tombstoned. Stamping on the
    fetch (rather than only clearing on success) is what keeps a receipt from
    one generation of bytes vouching for the next."""
    target = art_target(url, px)
    if target == "":
        return None

    ck = art_cache_key(target)
    cached = cache.get(ck)
    if cached != None:
        if cached == ART_TOMBSTONE:
            return None
        if cache.get(ck + ":ok") != ART_CONFIRMED:
            print("podcast: cover art aborted a render; dropping it")
            cache.set(ck, ART_TOMBSTONE, ttl_seconds = IMAGE_STORE)
            return None
        return base64.decode(cached)

    gate = ck + ":gate"
    if cache.get(gate) != None:
        return None
    cache.set(gate, "1", ttl_seconds = RETRY_TTL)

    resp = http.get(target, headers = {"User-Agent": USER_AGENT}, ttl_seconds = IMAGE_TTL)
    if resp.status_code != 200:
        print("podcast: art -> " + str(resp.status_code))
        return None
    b = resp.body()
    if len(b) < 50 or len(b) > ART_MAX_BYTES:
        # A cover this size is what this feed always serves: remember the
        # verdict instead of re-downloading a megabyte every minute.
        return tombstone_art(ck, "art size out of bounds: " + str(len(b)))
    if not looks_like_image(b):
        return tombstone_art(ck, "art bytes are not a whole image")

    cache.set(ck, base64.encode(b), ttl_seconds = IMAGE_STORE)
    cache.set(ck + ":ok", ART_UNCONFIRMED, ttl_seconds = IMAGE_STORE)
    cache.set(gate, "1", ttl_seconds = IMAGE_STORE)
    return b

def art_cache_key(target):
    return "pt:" + CACHE_GEN + ":art:" + target

def tombstone_art(ck, why):
    print("podcast: " + why)
    cache.set(ck, ART_TOMBSTONE, ttl_seconds = IMAGE_STORE)
    cache.set(ck + ":gate", "1", ttl_seconds = IMAGE_STORE)
    return None

def confirm_art(url, px):
    """Only ever reached after the card - and so render.Image - was built, so
    reaching it proves these bytes decoded."""
    target = art_target(url, px)
    if target != "":
        cache.set(art_cache_key(target) + ":ok", ART_CONFIRMED, ttl_seconds = IMAGE_STORE)

def looks_like_image(b):
    """PNG / GIF / JPEG header AND terminator. Header magic alone passes a
    truncated download - the first 54 bytes of a PNG still say "PNG" - and
    those bytes abort render.Image, so the tail has to agree: PNG ends with
    an IEND chunk, JPEG with FF D9, GIF with 0x3B. Starlark forbids "\\xff"
    in a literal, so those two come from base64."""
    if b[1:4] == "PNG":
        return b[-64:].rfind("IEND") >= 0
    if b[0:4] == "GIF8":
        return b[-8:].rfind(GIF_TERM) >= 0
    if base64.encode(b[0:2]) == JPEG_SOI:
        return b[-64:].rfind(JPEG_EOI) >= 0
    return False

# ------------------------------------------------------------------ parsing

def txt(d, q):
    v = d.query(q)
    return v.strip() if v != None else ""

def clip(s, n):
    s = s.strip()
    if len(s) > n:
        return s[0:n - 3] + "..."
    return s

def to_int(s):
    """Digits-only parse; -1 on anything else. int() would abort the render."""
    digits = "0123456789"
    if s == "":
        return -1
    n = 0
    for ch in s.elems():
        v = digits.find(ch)
        if v < 0:
            return -1
        n = n * 10 + v
    return n

def parse_pubdate(s):
    """RFC-822-ish pubDate -> unix epoch, or -1. Hand-rolled because real
    feeds mix unpadded days, numeric offsets, and named zones, and a failed
    time.parse_time aborts the render."""
    if s == "":
        return -1
    c = s.find(",")
    if c >= 0:
        s = s[c + 1:]
    parts = [p for p in s.split(" ") if p != ""]
    if len(parts) < 4:
        return -1

    day = to_int(parts[0])
    mon = MONTHS.get(parts[1][0:3].capitalize(), 0)
    year = to_int(parts[2])
    if year >= 0 and year < 100:
        year += 2000
    tp = parts[3].split(":")
    if len(tp) < 2:
        return -1
    hh = to_int(tp[0])
    mm = to_int(tp[1])
    ss = to_int(tp[2]) if len(tp) > 2 else 0
    if day < 1 or day > 31 or mon < 1 or year < 1970 or year > 2100:
        return -1
    if hh < 0 or hh > 23 or mm < 0 or mm > 59 or ss < 0 or ss > 60:
        return -1

    off = tz_offset(parts[4]) if len(parts) > 4 else 0
    return civil_to_epoch(year, mon, day, hh, mm, ss) - off

def tz_offset(z):
    head = z[0:1]
    if head == "+" or head == "-":
        v = to_int(z[1:])
        if v < 0:
            return 0
        sec = (v // 100) * 3600 + (v % 100) * 60
        return sec if head == "+" else -sec
    return ZONES.get(z.upper(), 0)

def civil_to_epoch(y, m, d, hh, mm, ss):
    """Days-from-civil (Hinnant); pure integer math, no time module."""
    yy = y - 1 if m <= 2 else y
    era = yy // 400
    yoe = yy - era * 400
    mp = (m + 9) % 12
    doy = (153 * mp + 2) // 5 + d - 1
    doe = yoe * 365 + yoe // 4 - yoe // 100 + doy
    days = era * 146097 + doe - 719468
    return days * 86400 + hh * 3600 + mm * 60 + ss

def parse_duration_s(s):
    """itunes:duration -> seconds: "HH:MM:SS", "MM:SS", or bare seconds
    depending on the host. -1 on anything else (e.g. ISO 8601 garbage, or a
    bare field that is really milliseconds - 3612000 is not a 1003 hour
    episode, and "1003h" doesn't fit the 18px artwork column)."""
    if s == "":
        return -1
    parts = s.split(":")
    if len(parts) > 3:
        return -1
    total = 0
    for p in parts:
        v = to_int(p.strip())
        if v < 0:
            return -1
        total = total * 60 + v
    if total > DUR_MAX:
        return -1
    return total

def dur_label(sec):
    if sec <= 0:
        return ""
    h = sec // 3600
    m = (sec % 3600) // 60
    if h > 9:
        return str(h) + "h"
    if h > 0:
        return str(h) + "h" + ("0" + str(m) if m < 10 else str(m))
    if m < 1:
        m = 1
    return str(m) + "m"

def age_label(epoch, now):
    d = now - epoch
    if d < 0:
        d = 0
    if d < 90:
        return "now"
    if d < 3600:
        return str(d // 60) + "m ago"
    if d < 172800:
        return str(d // 3600) + "h ago"
    if d < 86400 * 14:
        return str(d // 86400) + "d ago"
    if d < 86400 * 70:
        return str(d // 604800) + "w ago"
    return str(d // 2629800) + "mo ago"

# ------------------------------------------------------------------- render

def episode_card(data, art_bytes, now, want_art):
    epoch = data.get("epoch", -1)
    if epoch > now + FUTURE_SLACK:
        # Pre-dated or timezone-mangled. An episode that hasn't happened yet
        # is not "now", and must not hold the NEW badge lit for months.
        epoch = -1
    fresh = epoch > 0 and now - epoch < NEW_WINDOW
    age = age_label(epoch, now) if epoch > 0 else ""
    dur = dur_label(data.get("dur", -1))

    if is_square():
        return square_card(data, age, dur, fresh, art_bytes, want_art)

    if not want_art:
        return wide_card(data, age, dur, fresh)

    bottom = []
    if fresh:
        bottom.append(new_badge())
        bottom.append(render.Box(width = 1, height = 1))
    bottom.append(render.Text(age, font = "tom-thumb", color = WHITE if fresh else GREY))

    return render.Row(
        children = [
            art_tile(art_bytes, dur),
            render.Box(width = 1, height = 32, color = RULE),
            render.Padding(
                pad = (2, 0, 0, 0),
                child = info_col(43, data.get("show", ""), data.get("title", ""), render.Row(cross_align = "center", children = bottom)),
            ),
        ],
    )

def wide_card(data, age, dur, fresh):
    """Artwork toggled off: the text gets the whole panel and the episode
    length joins the bottom row."""
    return render.Padding(pad = (1, 0, 1, 0), child = info_col(62, data.get("show", ""), data.get("title", ""), age_row(age, dur, fresh)))

def age_row(age, dur, fresh):
    """Footer: age on the left behind the NEW badge while it is lit, episode
    length pushed to the right. Written for the artwork-off wide card, and the
    square layout's footer is the same row - a full-width panel is a full-width
    panel whichever way it got there."""
    left = []
    if fresh:
        left.append(new_badge())
        left.append(render.Box(width = 2, height = 1))
    left.append(render.Text(age, font = "tom-thumb", color = WHITE if fresh else GREY))
    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            render.Row(cross_align = "center", children = left),
            render.Text(dur, font = "tom-thumb", color = DIM),
        ],
    )

def info_col(w, show, title, bottom):
    return render.Column(
        children = [
            render.Marquee(width = w, child = render.Text(show, font = "tom-thumb", color = DIM)),
            render.Box(width = w, height = 2),
            render.Marquee(width = w, child = render.Text(title, font = "tb-8", color = WHITE)),
            render.Box(width = w, height = 9),
            bottom,
        ],
    )

def art_tile(art_bytes, dur):
    img = mic_glyph(16)
    if art_bytes != None:
        img = render.Image(src = art_bytes, width = 16, height = 16)
    return render.Column(
        children = [
            render.Padding(pad = (1, 1, 0, 0), child = img),
            render.Box(width = 18, height = 3),
            render.Box(width = 18, height = 6, child = render.Text(dur, font = "tom-thumb", color = DIM)),
        ],
    )

# ------------------------------------------------------ square (64x64) layout

def square_card(data, age, dur, fresh, art_bytes, want_art):
    """Podcast artwork is square, and a square panel is the one that can say
    so: the cover goes up top at 40px - six and a quarter times the area of
    the 2:1 panel's 16px chip - and the text column that used to sit beside it
    unstacks underneath. Show name, episode-title marquee, then the footer,
    which is the same age/NEW + length row the wide card already uses when the
    artwork is off. Nothing is new here except where it sits: same fonts, same
    colours, same hairline rule, turned through ninety degrees.

    A panel with no room for a cover takes the artwork-off card whether the
    artwork was wanted or not: those rows have to come from somewhere, and
    taking them from the cover is the only option that doesn't take them from
    the bottom of the panel."""
    show = data.get("show", "")
    title = data.get("title", "")
    px = square_art_px()
    if not want_art or px == 0:
        return square_text_card(show, title, age, dur, fresh)

    w, _ = canvas.size()
    img = mic_glyph(px)
    if art_bytes != None:
        img = render.Image(src = art_bytes, width = px, height = px)
    return render.Column(
        children = [
            render.Box(width = w, height = px, child = img),
            render.Box(width = w, height = 1, color = RULE),
            render.Padding(
                pad = (1, 0, 1, 0),
                child = render.Column(
                    children = [
                        render.Marquee(width = w - 2, child = render.Text(show, font = "tom-thumb", color = DIM)),
                        render.Box(height = 1),
                        render.Marquee(width = w - 2, child = render.Text(title, font = "tb-8", color = WHITE)),
                        render.Box(height = 1),
                        age_row(age, dur, fresh),
                    ],
                ),
            ),
        ],
    )

def square_spread(head, middle, foot):
    """Three rows over the whole square panel: masthead and rule up top, the
    loud line on the centre line, the footer on the floor. What a square card
    with no cover needs -- with nothing to hang them under, three rows huddled
    at the top would leave two thirds of the frame black."""
    w, h = canvas.size()
    return render.Box(
        width = w,
        height = h,
        child = render.Padding(
            pad = (1, 1, 1, 1),
            child = render.Column(
                expanded = True,
                main_align = "space_between",
                children = [head, middle, foot],
            ),
        ),
    )

def square_head(text):
    """Masthead line with the hairline rule under it -- the rule's other job,
    when there is no cover for it to sit beneath."""
    w, _ = canvas.size()
    return render.Column(
        children = [
            render.Marquee(width = w - 2, child = render.Text(text, font = "tom-thumb", color = DIM)),
            render.Box(height = 1),
            render.Box(width = w - 2, height = 1, color = RULE),
        ],
    )

def square_text_card(show, title, age, dur, fresh):
    """Artwork off on a square panel -- or on so short a square panel that the
    text block alone fills it."""
    w, _ = canvas.size()
    return square_spread(
        square_head(show),
        render.Marquee(width = w - 2, child = render.Text(title, font = "tb-8", color = WHITE)),
        age_row(age, dur, fresh),
    )

def square_message_card(top, msg, hint):
    """Setup / error card on a square panel: the glyph takes the cover's slot
    and the three lines take the caption's, so a failure still looks like this
    app rather than a different one. On a panel with no room for the cover the
    glyph goes with it and the three lines take the frame."""
    w, _ = canvas.size()
    px = square_art_px()
    if px == 0:
        return square_spread(
            square_head(top),
            render.Marquee(width = w - 2, child = render.Text(msg, font = "tb-8", color = WHITE)),
            render.Marquee(width = w - 2, child = render.Text(hint, font = "tom-thumb", color = GREY)),
        )
    return render.Column(
        children = [
            render.Box(width = w, height = px, child = mic_glyph(px)),
            render.Box(width = w, height = 1, color = RULE),
            render.Padding(
                pad = (1, 0, 1, 0),
                child = render.Column(
                    children = [
                        render.Marquee(width = w - 2, child = render.Text(top, font = "tom-thumb", color = DIM)),
                        render.Box(height = 1),
                        render.Marquee(width = w - 2, child = render.Text(msg, font = "tb-8", color = WHITE)),
                        render.Box(height = 2),
                        render.Marquee(width = w - 2, child = render.Text(hint, font = "tom-thumb", color = GREY)),
                    ],
                ),
            ),
        ],
    )

def new_badge():
    # 13 wide: "47h ago" (28px) + 1px gap + badge must fit the 43px column.
    return render.Box(
        width = 13,
        height = 7,
        color = AMBER,
        child = render.Text("NEW", font = "tom-thumb", color = "#161616"),
    )

def mic_glyph(size):
    """Pixel microphone for covers we can't (or shouldn't) fetch. Drawn in
    16x16 design units and mapped onto `size` pixels, so the square panel gets
    a full-size glyph in the cover's slot rather than a 16px stamp adrift in
    it. Each rectangle's far edge is mapped as well as its near one, which is
    what keeps a non-integer scale from opening seams between them."""
    px = [
        (6, 2, 4, 8, "#c7ccd8"),
        (6, 2, 1, 8, "#e9edf4"),
        (4, 7, 1, 4, "#79818f"),
        (11, 7, 1, 4, "#79818f"),
        (5, 11, 6, 1, "#79818f"),
        (7, 12, 2, 2, "#79818f"),
        (5, 14, 6, 1, "#8b93a2"),
    ]
    kids = [render.Box(width = size, height = size, color = TILE_BG)]
    for x, y, w, h, c in px:
        x0 = x * size // 16
        y0 = y * size // 16
        kids.append(render.Padding(
            pad = (x0, y0, 0, 0),
            child = render.Box(
                width = (x + w) * size // 16 - x0,
                height = (y + h) * size // 16 - y0,
                color = c,
            ),
        ))
    return render.Stack(children = kids)

def message_card(top, msg, hint):
    """Setup / error card: mic tile + three lines, same bones as the episode
    card so failures don't look like a different app."""
    if is_square():
        return square_message_card(top, msg, hint)
    return render.Row(
        children = [
            render.Column(children = [render.Padding(pad = (1, 1, 0, 0), child = mic_glyph(16))]),
            render.Padding(pad = (2, 0, 0, 0), child = render.Box(width = 1, height = 32, color = RULE)),
            render.Padding(
                pad = (2, 0, 0, 0),
                child = render.Column(
                    children = [
                        render.Box(width = 42, height = 2),
                        render.Marquee(width = 42, child = render.Text(top, font = "tom-thumb", color = DIM)),
                        render.Box(width = 42, height = 3),
                        render.Marquee(width = 42, child = render.Text(msg, font = "tb-8", color = WHITE)),
                        render.Box(width = 42, height = 4),
                        render.Marquee(width = 42, child = render.Text(hint, font = "tom-thumb", color = GREY)),
                    ],
                ),
            ),
        ],
    )

# -------------------------------------------------------------------- schema

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "find_by",
                name = "Find by",
                desc = "How to locate the show.",
                icon = "podcast",
                default = "search",
                options = [
                    schema.Option(display = "Show name (Apple)", value = "search"),
                    schema.Option(display = "RSS feed URL", value = "rss"),
                ],
            ),
            schema.Text(
                id = "show",
                name = "Show name",
                desc = "Podcast to look up on Apple Podcasts.",
                icon = "magnifyingGlass",
                default = "",
            ),
            schema.Text(
                id = "rss_url",
                name = "RSS feed URL",
                desc = "Used when 'Find by' is set to RSS feed URL.",
                icon = "rss",
                default = "",
            ),
            schema.Toggle(
                id = "artwork",
                name = "Show artwork",
                desc = "Cover art tile on the left.",
                icon = "image",
                default = True,
            ),
        ],
    )
