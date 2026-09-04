"""
Pixel Art Feed.

Shows artwork from r/PixelArt. Picks a post from the chosen feed, pulls the
full-resolution original from i.redd.it, and scales it to the panel with
nearest-neighbour so the pixels stay pixels. No API key required.

Art that isn't the shape of the panel is panned rather than squashed: tall
pieces drift top to bottom, panoramas left to right, with a beat of
stillness at each end. Animated GIFs keep animating while they pan.

Reddit's .json API is bot-blocked (403) but the Atom feeds are open, so this
reads .rss and parses it with xpath. Anonymous reddit allows roughly one
request a minute, so the parsed post list is cached and reused across
renders rather than fetched per frame.

KNOWN LIMITATION: reddit also blocks by TLS fingerprint, and the fingerprint
Go presents depends on whether the CPU has hardware AES. Hosts without it —
every Raspberry Pi, whose ARM cores lack the crypto extensions — get a 403
block page from reddit.com no matter what this app sends, while x86 hosts
are served normally. Nothing here can change that, so those hosts can point
"Feed mirror" at something on their own network that fetches the feed with a
client reddit accepts (curl, python) and serves it back over plain HTTP.
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("random.star", "random")
load("re.star", "re")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")
load("xpath.star", "xpath")

USER_AGENT = "tronbyt:pixel-art-feed:1.0 (+https://github.com/tronbyt/apps)"

# Anonymous reddit allows roughly one feed read a minute and answers a
# lasting block page to anything that keeps pushing past it, while a device
# re-renders its apps every rotation pass. So the parsed post list is held
# in cache.star rather than re-fetched per render: one read feeds hours of
# renders, and the art still changes every time because a post is drawn at
# random from the ~70 in the list.
#
# This is deliberately cache.star and not http ttl_seconds alone. ttl_seconds
# caches the response, but a non-200 is only held for 5s, so a blocked or
# rate-limited feed would be retried on every render — and there would be
# nothing to draw in the meantime. Caching the parsed list instead gives two
# useful TTLs: FRESH_TTL is when a refresh is attempted, STALE_TTL is how
# long the existing list stays usable, and between them the app keeps
# showing known-good art while it retries. FAIL_COOLDOWN backs a failed
# feed off rather than hammering it.
STALE_TTL = 6 * 3600
FRESH_TTL = 3600
FAIL_COOLDOWN = 300
FEED_TTL = 900
IMAGE_TTL = 1800

# Decode-cost guard. render.Image expands EVERY GIF frame to full-size
# RGBA *before* scaling down, so cost is width x height x frames. Measured
# on real r/PixelArt posts: the median animated post is ~24M, but the tail
# is savage — a 1536x1536 x303 frame post is 715M, i.e. 2.9GB of RGBA.
# 40M (~160MB) keeps roughly three quarters of animated posts and every
# static one, and stays inside a Pi Zero 2 W's 512MB.
MAX_COST = 40 * 1000 * 1000
MAX_PIXELS = 12 * 1000 * 1000

# Two hard limits make a candidate's size worth knowing before fetching it:
# a body over 20MB aborts the whole app rather than returning an error, and
# every request has a fixed 5s timeout. Roughly one r/PixelArt post in
# eighty is over 20MB. A 4KB ranged request answers both questions — total
# size from Content-Range, dimensions from the header — for almost nothing.
MAX_BYTES = 4 * 1024 * 1024
PROBE_RANGE = "bytes=0-8191"
MAX_TRIES = 6

# Frame-counting signatures. Starlark string literals can't hold raw high
# bytes, so they come in via base64; counting them is a native Go substring
# scan, cheap even on a multi-megabyte body.
#
# Graphic-control extensions (0x21 0xF9 0x04) are the obvious marker but are
# OPTIONAL in GIF89a — a legal animation can carry none, and trusting them
# alone reports such a file as a single frame and waves a 200MB decode
# straight past MAX_COST. Image separators (0x00 0x2C) are counted too and
# the larger wins: both can over-count on a chance match in LZW data, which
# only ever rejects art, never admits a bomb.
GIF_GCE = base64.decode("IfkE")
GIF_SEP = base64.decode("ACw=")

DELAY_MS = 50

# A pan has to FINISH inside the slot or the bottom of the picture is never
# seen: the encoder stops adding frames at the app's dwell, which is 15s by
# default. Lead-in plus the slowest pan is 12.2s, so every speed lands with
# room to spare even on a short slot.
PAN_SECONDS = {"slow": 11, "medium": 8, "fast": 5}
HOLD_SECONDS = 1.2

# Ceiling on pan distance. Scaling to the panel's width multiplies by aspect
# ratio alone, which neither size guard measures: a 178-byte 1x50000 PNG
# passes every limit and then expands to 2GB. Longer strips are shown whole.
MAX_TRAVEL = 4000

# The pan runs once and then rests on the last frame for the remainder of
# a 35s budget. The server truncates the encoded animation to the app's
# dwell, so any slot shorter than this gets one unhurried pass instead of
# restarting from the top partway through — and the tail costs nothing,
# since a still image's repeated frames are merged by the encoder and
# frames past the dwell are never rendered at all.
BUDGET_SECONDS = 35

# Feed id -> (listing, time window). "random" is resolved per render.
FEEDS = {
    "hot": ("hot", ""),
    "new": ("new", ""),
    "top_day": ("top", "day"),
    "top_week": ("top", "week"),
    "top_month": ("top", "month"),
    "top_year": ("top", "year"),
    "top_all": ("top", "all"),
}
RANDOM_POOL = ["hot", "top_day", "top_week", "top_month", "top_year", "top_all"]

IMAGE_EXTS = [".png", ".jpg", ".jpeg", ".gif", ".webp"]

# Gallery memory. Picking at random out of ~70 candidates repeats a piece
# often enough to notice, so recent post ids are parked in the cache and
# passed over while anything fresh is left. A cache miss is harmless — the
# app just loses the preference, not correctness.
RECENT_KEY = "recent"
RECENT_KEEP = 24
RECENT_TTL = 6 * 3600

def main(config):
    # Seed from the clock: some pixlet builds seed the RNG from a coarse
    # time bucket, which would show the same picture on every render.
    random.seed(time.now().unix_nano)

    # canvas reports the real panel, so the widget coordinates are the
    # panel's own pixels — 64x32, or 128x64 on a wide device.
    scale = 2 if canvas.is2x() else 1
    w, h = canvas.width(), canvas.height()

    subreddit = clean_subreddit(config.str("subreddit", "PixelArt"))
    feed_id = config.str("feed", "top_month")
    if feed_id == "random":
        feed_id = RANDOM_POOL[random.number(0, len(RANDOM_POOL) - 1)]

    # Nothing to show: yield the slot to the next app rather than sitting
    # on it with an error card. The feed is cached for hours, so this only
    # happens on a cold start or a genuine outage.
    posts = load_posts(subreddit, feed_id, feed_base(config))
    if len(posts) == 0:
        return []

    art = choose_art(posts)
    if art == None:
        return []

    overlay = caption_bar(caption_for(art["post"], config), w, h, scale)

    return render.Root(
        delay = DELAY_MS,
        child = build_art(art, w, h, overlay, config.str("oversize", "pan"), config.str("pan_speed", "medium")),
    )

# --- Feed ---

def load_posts(subreddit, feed_id, base):
    """The post list for this feed, fetching only when it needs to.

    Renders are far more frequent than the feed changes, so the list is
    served from the cache and only refreshed once it goes stale. If the
    refresh fails, the stale list keeps being used rather than dropping
    the app to an error card.
    """
    key = "posts:%s:%s" % (subreddit, feed_id)
    cached = decode_posts(cache.get(key))

    if len(cached) > 0 and cache.get("fresh:" + key) != None:
        return cached

    # Back off rather than retrying a failing feed every render. Per feed,
    # because "Fully random" rotates through six of them and one being
    # unavailable must not stop the other five from refreshing.
    if cache.get("cooldown:" + key) != None:
        return cached

    posts = fetch_posts(subreddit, feed_id, base)
    if len(posts) == 0:
        cache.set("cooldown:" + key, "1", ttl_seconds = FAIL_COOLDOWN)
        return cached

    cache.set(key, encode_posts(posts), ttl_seconds = STALE_TTL)
    cache.set("fresh:" + key, "1", ttl_seconds = FRESH_TTL)
    return posts

def encode_posts(posts):
    rows = []
    for p in posts:
        rows.append("\t".join([
            field(p["id"]),
            field(p["src"]),
            field(p["title"]),
            field(p["author"]),
        ]))
    return "\n".join(rows)

def decode_posts(raw):
    # Deliberately split-based rather than JSON: this parses whatever it
    # is handed without ever raising, and a raised error would take the
    # whole app down with it.
    posts = []
    if raw == None:
        return posts
    for row in raw.split("\n"):
        f = row.split("\t")
        if len(f) == 4 and f[1] != "":
            posts.append({"id": f[0], "src": f[1], "title": f[2], "author": f[3]})
    return posts

def field(v):
    return v.replace("\t", " ").replace("\n", " ").replace("\r", " ")

def clean_subreddit(raw):
    s = raw.strip().strip("/")
    if s.lower().startswith("r/"):
        s = s[2:]

    # Keep it to the characters reddit actually allows in a sub name so a
    # stray path or query can't be appended to the feed URL.
    out = ""
    for ch in s.elems():
        if ch.isalnum() or ch == "_":
            out += ch
    return out if out != "" else "PixelArt"

def feed_base(config):
    """Where feeds are read from: reddit, or a mirror standing in for it.

    See the KNOWN LIMITATION note at the top of this file for when a mirror
    is needed. Anything that isn't a plain http(s) origin is ignored.
    """
    relay = config.str("relay", "").strip().rstrip("/")

    # A hand-typed address that doesn't parse makes http.get raise, which
    # takes the app down rather than returning an error, so anything that
    # doesn't look like a bare origin is ignored in favour of reddit.
    if relay.find(" ") >= 0 or relay.find("\t") >= 0 or relay.find("\n") >= 0:
        return "https://www.reddit.com"
    if relay.startswith("http://") or relay.startswith("https://"):
        return relay
    return "https://www.reddit.com"

def fetch_posts(subreddit, feed_id, base):
    listing, window = FEEDS.get(feed_id, FEEDS["top_month"])
    url = "%s/r/%s/%s.rss?limit=100" % (base, subreddit, listing)
    if window != "":
        url += "&t=" + window

    resp = http.get(url, headers = {"User-Agent": USER_AGENT}, ttl_seconds = FEED_TTL)
    if resp.status_code != 200:
        return []

    # Reddit sometimes answers with an HTML interstitial rather than the
    # feed. xpath.loads() raises on anything that isn't well-formed XML,
    # and a raised error aborts the app instead of returning a value, so
    # the body has to be vetted before it gets there. Checking both ends
    # rejects a page that isn't a feed and a feed that arrived truncated.
    body = resp.body().strip()
    if not body.startswith("<?xml") or not body.endswith("</feed>"):
        return []
    if body.find("<entry") < 0:
        return []

    doc = xpath.loads(body)
    posts = []

    # Every field is read off the entry node itself. The feed regularly
    # drops a media:thumbnail or an author (deleted accounts), so reading
    # the document with parallel query_all lists would silently pair one
    # post's title with another post's picture.
    for node in doc.query_all_nodes("//entry"):
        html = node_text(node, "./content")
        if html == "":
            continue

        # The [link] anchor carries the untouched original. Gallery posts
        # and videos only offer a 140px or video-still thumbnail, so they
        # are skipped rather than shown as mush.
        found = re.findall(r'https://i\.redd\.it/[^"\s<]+', html)
        if len(found) == 0:
            continue

        src = found[0]
        if not has_image_ext(src):
            continue

        posts.append({
            "id": node_text(node, "./id"),
            "src": src,
            "title": node_text(node, "./title"),
            "author": node_text(node, "./author/name"),
        })

    return posts

def node_text(node, path):
    v = node.query(path)
    return v if v != None else ""

def has_image_ext(url):
    lower = url.lower()
    for ext in IMAGE_EXTS:
        if lower.endswith(ext):
            return True
    return False

# --- Selection ---

def choose_art(posts):
    """Try posts at random until one decodes cheaply enough to display."""
    seen = recent_ids()
    fresh = []
    stale = []
    for i in range(len(posts)):
        if posts[i]["id"] != "" and posts[i]["id"] in seen:
            stale.append(i)
        else:
            fresh.append(i)

    # Fall back to the whole feed once there isn't enough unseen art left
    # to give the retry loop room.
    pool = fresh if len(fresh) >= MAX_TRIES else fresh + stale
    tries = MAX_TRIES if len(pool) > MAX_TRIES else len(pool)

    for _ in range(tries):
        post = posts[pool.pop(random.number(0, len(pool) - 1))]

        body = fetch_art(post["src"])
        if body == None or len(body) > MAX_BYTES:
            continue

        dims = probe(body)
        if dims == None:
            continue

        iw, ih, frames, delay = dims
        if iw <= 0 or ih <= 0 or iw * ih * frames > MAX_COST:
            continue

        remember(post["id"], seen)
        return {
            "post": post,
            "body": body,
            "iw": iw,
            "ih": ih,
            "frames": frames,
            "delay": delay,
        }

    return None

def recent_ids():
    raw = cache.get(RECENT_KEY)
    return raw.split(",") if raw != None and raw != "" else []

def remember(post_id, seen):
    if post_id == "":
        return
    seen.append(post_id)
    if len(seen) > RECENT_KEEP:
        seen = seen[len(seen) - RECENT_KEEP:]
    cache.set(RECENT_KEY, ",".join(seen), ttl_seconds = RECENT_TTL)

def fetch_art(src):
    """Size-check a candidate with a ranged read, then fetch it in full."""
    head = http.get(
        src,
        headers = {"User-Agent": USER_AGENT, "Range": PROBE_RANGE},
        ttl_seconds = IMAGE_TTL,
    )

    if head.status_code == 200:
        # Range ignored, so this already is the whole file — and small
        # enough to have arrived, since anything huge would have aborted.
        return head.body()

    if head.status_code != 206:
        return None

    total = content_range_total(head.headers.get("Content-Range"))
    if total < 0 or total > MAX_BYTES:
        return None

    # Dimensions are in the first few bytes for every format we accept, so
    # an outsized canvas can be dropped before paying for the download.
    # A prefix can't be trusted for the frame count, only the size.
    dims = probe(head.body())
    if dims != None and dims[0] * dims[1] > MAX_PIXELS:
        return None

    full = http.get(src, headers = {"User-Agent": USER_AGENT}, ttl_seconds = IMAGE_TTL)
    if full.status_code != 200:
        return None
    return full.body()

def content_range_total(value):
    """Total size out of a 'bytes 0-8191/123456' header, or -1."""
    if value == None:
        return -1
    at = value.rfind("/")
    if at < 0:
        return -1
    tail = value[at + 1:].strip()
    if tail == "" or tail == "*" or not tail.isdigit():
        return -1
    return int(tail)

# --- Header probing ---
#
# Reading width/height/frame-count out of the raw bytes lets an oversized
# post be dropped before render.Image ever allocates for it. Note that
# ord() is UTF-8 aware and returns 65533 for any byte above 0x7F — only
# elem_ords() reports true byte values.

def probe(body):
    """(width, height, frames, frame_delay_ms) from the header, or None."""
    if len(body) < 30:
        return None
    o = body.elem_ords()

    if body[0:3] == "GIF":
        w = o[6] + o[7] * 256
        h = o[8] + o[9] * 256

        frames = max(body.count(GIF_GCE), body.count(GIF_SEP))

        # Read the first extension's delay (centiseconds) so playback speed
        # is known without building a render.Image just to ask it.
        delay = 0
        at = body.find(GIF_GCE)
        if at >= 0 and at + 5 < len(body):
            delay = (o[at + 4] + o[at + 5] * 256) * 10

        return (w, h, frames if frames > 0 else 1, delay)

    if o[0] == 137 and body[1:4] == "PNG":
        w = o[16] * 16777216 + o[17] * 65536 + o[18] * 256 + o[19]
        h = o[20] * 16777216 + o[21] * 65536 + o[22] * 256 + o[23]
        return (w, h, 1, 0)

    if o[0] == 255 and o[1] == 216:
        return probe_jpeg(body, o)

    # WebP: 'RIFF' .... 'WEBP'
    if body[0:4] == "RIFF" and body[8:12] == "WEBP":
        return probe_webp(body, o)

    return None

def probe_jpeg(body, o):
    n = len(body)
    i = 2

    # Walk the segment chain to the start-of-frame marker. Bounded so a
    # malformed file can't spin.
    for _ in range(128):
        if i + 9 >= n or o[i] != 255:
            return None
        marker = o[i + 1]

        # Standalone markers carry no length payload.
        if marker == 216 or marker == 217 or (marker >= 208 and marker <= 215):
            i += 2
            continue

        seglen = o[i + 2] * 256 + o[i + 3]
        if seglen < 2:
            return None

        # SOF0..SOF15, excluding DHT(C4), JPG(C8) and DAC(CC).
        if marker >= 192 and marker <= 207 and marker != 196 and marker != 200 and marker != 204:
            h = o[i + 5] * 256 + o[i + 6]
            w = o[i + 7] * 256 + o[i + 8]
            return (w, h, 1, 0)

        i += 2 + seglen

    return None

def probe_webp(body, o):
    if len(body) < 30:
        return None
    tag = body[12:16]

    if tag == "VP8X":
        w = 1 + o[24] + o[25] * 256 + o[26] * 65536
        h = 1 + o[27] + o[28] * 256 + o[29] * 65536

        # An extended WebP may be animated; frames aren't cheap to count,
        # so assume a costly one and let MAX_COST arbitrate.
        frames = 24 if (o[20] % 4) >= 2 else 1
        return (w, h, frames, 0)

    if tag == "VP8L":
        b0, b1, b2, b3 = o[21], o[22], o[23], o[24]
        bits = b0 + b1 * 256 + b2 * 65536 + b3 * 16777216
        return (1 + (bits % 16384), 1 + ((bits // 16384) % 16384), 1, 0)

    if tag == "VP8 ":
        return (o[26] + o[27] * 256, o[28] + o[29] * 256, 1, 0)

    return None

# --- Layout ---

def build_art(art, w, h, overlay, mode, speed):
    """Scale the piece for the panel, panning it if it overflows."""
    iw, ih = art["iw"], art["ih"]
    by_width = fit(iw, ih, w, 0)
    by_height = fit(iw, ih, 0, h)

    if mode == "fit":
        # Whole piece on screen, letterboxed.
        sw, sh = by_width if by_width[1] <= h else by_height
        return still(art, sw, sh, w, h, overlay)

    if mode == "fill":
        # Cover the panel, centre-cropping the overflow.
        sw, sh = by_width if by_width[1] >= h else by_height
        return still(art, sw, sh, w, h, overlay)

    # Pan mode. Fit across the panel first; if the piece is so wide that
    # doing so leaves it as a thin band, fit its height and pan sideways
    # instead. Either way nothing is cropped — it's all shown, in time.
    sw, sh = by_width
    if sh < h * 6 // 10:
        sw, sh = by_height

    if sh > h and sh - h <= MAX_TRAVEL:
        return pan(art, sw, sh, w, h, "vertical", speed, overlay)
    if sw > w and sw - w <= MAX_TRAVEL:
        return pan(art, sw, sh, w, h, "horizontal", speed, overlay)

    # Too long a strip to pan: show the whole thing rather than spend the
    # slot creeping across a fraction of it.
    sw, sh = by_width if by_width[1] <= h else by_height
    return still(art, sw, sh, w, h, overlay)

def fit(iw, ih, w, h):
    """Scale to the given width or height, keeping the aspect ratio."""
    if w > 0:
        return (w, max(1, ih * w // iw))
    return (max(1, iw * h // ih), h)

def image(art, sw, sh):
    # An animated GIF advances one of its own frames per rendered frame.
    # Holding each for its native delay keeps it playing at real speed
    # instead of sprinting while the pan crawls. The delay comes from the
    # header so the picture is only ever decoded once.
    hold = 1
    if art["frames"] > 1 and art["delay"] > DELAY_MS:
        hold = art["delay"] // DELAY_MS
    return render.Image(src = art["body"], width = sw, height = sh, hold_frames = hold)

def still(art, sw, sh, w, h, overlay):
    return over(placed(image(art, sw, sh), (w - sw) // 2, (h - sh) // 2), overlay)

def pan(art, sw, sh, w, h, axis, speed, overlay):
    img = image(art, sw, sh)
    vertical = axis == "vertical"
    travel = (sh - h) if vertical else (sw - w)
    across = (w - sw) // 2 if vertical else (h - sh) // 2

    steps = max(1, PAN_SECONDS.get(speed, 11) * 1000 // DELAY_MS)
    hold = int(HOLD_SECONDS * 1000 / DELAY_MS)

    # One widget per distinct offset, reused across frames: the pan runs
    # for many more frames than there are pixels to travel.
    #
    # The caption is composited into each frame rather than stacked over
    # the finished animation. A Stack reports the frame count of its
    # longest child, so a scrolling caption could outlast the pan — and
    # render.Animation wraps any frame index past its own length, which
    # would restart the pan partway through the slot.
    cache = {}
    for offset in range(travel + 1):
        if vertical:
            cache[offset] = over(placed(img, across, -offset), overlay)
        else:
            cache[offset] = over(placed(img, -offset, across), overlay)

    tail = BUDGET_SECONDS * 1000 // DELAY_MS - hold - steps
    if tail < hold:
        tail = hold

    frames_out = []
    for _ in range(hold):
        frames_out.append(cache[0])
    for i in range(steps):
        frames_out.append(cache[ease(i, steps, travel)])
    for _ in range(tail):
        frames_out.append(cache[travel])

    return render.Animation(children = frames_out)

def over(art, overlay):
    return art if overlay == None else render.Stack(children = [art, overlay])

def ease(i, steps, travel):
    """Smoothstep the pan so it drifts up to speed and settles, not snaps."""
    if steps < 2:
        return travel
    t = float(i) / float(steps - 1)
    return int(travel * (t * t * (3.0 - 2.0 * t)) + 0.5)

def placed(child, dx, dy):
    # Negative padding is the supported way to offset a child; the root
    # canvas clips whatever falls outside the panel.
    return render.Padding(pad = (dx, dy, 0, 0), child = child)

# --- Caption ---

def caption_for(post, config):
    style = config.str("caption", "none")
    title = post["title"]
    author = post["author"]
    if author.startswith("/u/"):
        author = author[3:]

    if style == "artist" and author != "":
        return "u/" + author
    if style == "title" and title != "":
        return title
    if style == "both":
        if title != "" and author != "":
            return "%s — u/%s" % (title, author)
        return title if title != "" else ("u/" + author if author != "" else "")
    return ""

def printable(text):
    """Reduce a post title to characters the panel fonts can actually draw.

    An emoji is drawn as a 10px full-colour bitmap whatever font is asked
    for, and render.Box does not clip its child, so a single one in a 6px
    strip spills up over the artwork. Scripts the font has no glyphs for
    (CJK, Cyrillic) are dropped silently and leave holes. Both go, and the
    gaps they leave are squeezed back out.
    """
    out = ""
    for cp in text.codepoint_ords():
        if (cp >= 0x20 and cp <= 0x7E) or (cp >= 0xA0 and cp <= 0x24F):
            out += chr(cp)
        else:
            out += " "
    return " ".join(out.split())

def caption_bar(raw, w, h, scale):
    """Bottom credit strip, or None when there's nothing to say."""
    text = printable(raw)
    if text == "":
        return None

    font = "tb-8" if scale == 2 else "tom-thumb"
    bar_h = 16 if scale == 2 else 6

    bar = render.Box(
        width = w,
        height = bar_h,
        # Scrim rather than a solid bar: the art still reads underneath.
        color = "#000000C0",
        child = render.Marquee(
            width = w - 2,
            child = render.Text(text, font = font, color = "#E6E6E6"),
        ),
    )

    return placed(bar, 0, h - bar_h)

# --- Schema ---

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "feed",
                name = "Feed",
                desc = "Which slice of the subreddit to draw from.",
                icon = "arrowDownWideShort",
                default = "top_month",
                options = [
                    schema.Option(display = "Fully random", value = "random"),
                    schema.Option(display = "Hot right now", value = "hot"),
                    schema.Option(display = "Newest", value = "new"),
                    schema.Option(display = "Top today", value = "top_day"),
                    schema.Option(display = "Top this week", value = "top_week"),
                    schema.Option(display = "Top this month", value = "top_month"),
                    schema.Option(display = "Top this year", value = "top_year"),
                    schema.Option(display = "Top of all time", value = "top_all"),
                ],
            ),
            schema.Dropdown(
                id = "oversize",
                name = "Odd shapes",
                desc = "What to do with art that isn't the shape of the panel.",
                icon = "cropSimple",
                default = "pan",
                options = [
                    schema.Option(display = "Pan across it", value = "pan"),
                    schema.Option(display = "Fit the whole piece", value = "fit"),
                    schema.Option(display = "Fill the panel (crops)", value = "fill"),
                ],
            ),
            schema.Dropdown(
                id = "pan_speed",
                name = "Pan speed",
                desc = "How long a pan takes end to end.",
                icon = "gaugeHigh",
                default = "medium",
                options = [
                    schema.Option(display = "Slow", value = "slow"),
                    schema.Option(display = "Medium", value = "medium"),
                    schema.Option(display = "Fast", value = "fast"),
                ],
            ),
            schema.Dropdown(
                id = "caption",
                name = "Credit",
                desc = "Overlay the artist or title along the bottom.",
                icon = "signature",
                default = "none",
                options = [
                    schema.Option(display = "Nothing", value = "none"),
                    schema.Option(display = "Artist", value = "artist"),
                    schema.Option(display = "Title", value = "title"),
                    schema.Option(display = "Title and artist", value = "both"),
                ],
            ),
            schema.Text(
                id = "subreddit",
                name = "Subreddit",
                desc = "Where the art comes from. Any image-led subreddit works.",
                icon = "reddit",
                default = "PixelArt",
            ),
            schema.Text(
                id = "relay",
                name = "Feed mirror (advanced)",
                desc = "Leave empty. Only needed if reddit returns 403 on your server, which it does on Raspberry Pi hosts: the address of something on your network that mirrors reddit's .rss feeds, e.g. http://192.168.1.10:8791",
                icon = "server",
                default = "",
            ),
        ],
    )
