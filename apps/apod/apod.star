"""
Applet: NASA APOD
Summary: NASA's daily space picture
Description: NASA's Astronomy Picture of the Day, full bleed on the matrix.
Author: nsluke

The spirit of Tidbyt's first-party JWST app, pointed at the richer daily
source. One picture a day, edge to edge, with the title on a translucent
strip along the bottom.

Data: https://api.nasa.gov/planetary/apod (thumbs=true). Verified by hand
before this was written; field notes that differ from folklore:
  - api.nasa.gov sits behind api-umbrella and answers anywhere from 0.3s to
    5.5s, against pixlet's ~5s http deadline. A blown deadline is a TRANSPORT
    error, which aborts the whole render: Starlark never gets control back,
    so no amount of downstream fallback runs. Everything here is arranged so
    that costs at most one render in a while, never the next one too:
      * a cold-cache first render draws the starfield without any network at
        all (BOOT_HOLD), while still serving anything already cached;
      * once today's entry is in hand nothing is fetched again until
        tomorrow - APOD is immutable once published, so a render that has
        the picture has nothing to win and a whole render to lose;
      * the gate key that bounds a hanging dependency is written BEFORE the
        request and held longer than the app's own 240s cadence (much longer
        when there is a good picture to fall back on), so a failed attempt
        genuinely suppresses the following renders instead of every one of
        them repeating it.
  - Video days do NOT reliably have thumbnail_url: YouTube embeds do,
    self-hosted .mp4 days return thumbnail_url of "" (empty string).
    Those fall back to the starfield title card with a play glyph.
  - DEMO_KEY is rate limited per IP (observed x-ratelimit-limit: 10 per
    window). Harmless at a 6h fresh TTL; heavy users can paste their own
    free key.

Source images are often multi-megabyte, so they are never fetched raw:
images.weserv.nl resizes server-side to exactly 64x32 (~800 bytes of
baseline JPEG, verified end to end). Bytes that render.Image cannot decode
are the other uncatchable abort, so they are decoded BEFORE they reach the
3-day cache, and a cached entry is demoted to a 1s TTL for exactly as long
as it spends in the decoder. A bad picture can cost one render; it can never
replay from cache for three days.
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

API_BASE = "https://api.nasa.gov"
APOD_PATH = "/planetary/apod"
PROXY_BASE = "https://images.weserv.nl"
DEMO_KEY = "DEMO_KEY"
NASA_TZ = "America/New_York"  # APOD's own publication clock

FRESH_TTL = 21600  # re-ask the API at most every 6h (APOD flips once a day)
STALE_TTL = 259200  # serve the last good picture up to 3 days through an outage
HOLD_COLD = 600  # gate held around a request while nothing is cached yet
HOLD_STALE = 3600  # ... and much longer once there is a picture to fall back on
HTTP_TTL = 60  # pixlet's own response cache; the gates above do the pacing
BOOT_HOLD = 30  # first 30s after a cold cache: serve cache, touch no network
BOOT_TTL = 7776000
MAX_ART = 65536  # the proxy returns ~800B of 64x32 JPEG; nothing is near this

INK = "#FFFFFF"
DIM = "#9C9C9C"
AMBER = "#FFA33A"
SHADE = "#000000C0"
NIGHT = "#00000E"

def main(config):
    # api/proxy are hidden test hooks, deliberately NOT schema fields: they
    # point the app at a local stub and there is nothing here a user should
    # be typing into.
    api_conf = url_conf(config, "api")
    base = api_conf if api_conf else API_BASE
    proxy = url_conf(config, "proxy") or PROXY_BASE
    key = (config.get("api_key") or "").strip() or DEMO_KEY
    show_title = config.bool("show_title", True)
    show_date = config.bool("show_date", False)

    # The first renders after a cold cache stay off the network entirely -
    # see the docstring. Cached work is still served, so on a server that has
    # run before this costs nothing at all.
    live = api_conf != None or not boot_holding()

    today = nasa_today()
    apod = get_apod(base, key, live, today)
    img = get_art(proxy, apod, live)

    if apod != None and apod["date"] != "" and apod["date"] != today:
        # A picture up to STALE_TTL old must never pass for today's. The chip
        # is the only thing on the panel that says otherwise, so here it is
        # not the user's to switch off.
        show_date = True

    if img != None:
        body = picture_view(img, apod, show_title, show_date)
    else:
        body = starfield_card(apod, show_title, show_date)
    return render.Root(child = body, show_full_animation = True)

def url_conf(config, field):
    """A hidden hook's value, but only if it is an absolute http(s) URL.
    Anything else is ignored rather than handed to http.get, where a bad
    scheme is a transport error - an abort, not something catchable."""
    v = config.get(field)
    if v == None:
        return None
    v = v.strip()
    if v.startswith("http://") or v.startswith("https://"):
        return v
    return None

def nasa_today():
    """Today by APOD's own clock, so the staleness chip means the same thing
    in every timezone the panel might be sitting in."""
    return time.now().in_location(NASA_TZ).format("2006-01-02")

def boot_holding():
    now = time.now().unix
    ts = cache.get("apod:v1:boot")
    if ts == None:
        cache.set("apod:v1:boot", str(now), ttl_seconds = BOOT_TTL)
        return True
    t = to_int(ts)
    if t < 0:
        return False
    return now - t < BOOT_HOLD

# ---------------------------------------------------------------- data layer

def fetch_json(url, params):
    """Fetch and validate. None means "nothing usable" and is never an abort;
    the caller owns the gate that bounds the aborts we cannot catch."""
    resp = http.get(url, params = params, ttl_seconds = HTTP_TTL)
    body = resp.body().strip()
    if resp.status_code != 200:
        print("apod: API -> " + str(resp.status_code))
        return None
    if not (body.startswith("{") and body.endswith("}")):
        print("apod: non-JSON body from API")
        return None
    d = json.decode(body, None)
    if d == None:
        # Braced but broken JSON (truncated, missing commas): json.decode's
        # 1-arg form would abort the render.
        print("apod: undecodable JSON from API")
        return None
    return d

def get_apod(base, key, live, today):
    """Today's entry, extracted to a small dict and cached so an outage
    serves the last good reading. Keyed by base + api key: a config change
    must never read another config's data."""
    ck = "apod:v1:d:" + base + ":" + key
    gk = ck + ":gate"
    cached = decode_extract(cache.get(ck))

    if not live:
        return cached  # boot hold: whatever we have, no network
    if cached != None and cached["date"] == today:
        return cached  # today's picture is already in hand and cannot change
    if cache.get(gk) != None:
        return cached  # recently fetched, or recently failed

    # Gate BEFORE the request. A hanging or unreachable api.nasa.gov aborts
    # the render from inside http.get, and this write is the only thing that
    # survives it - so hold it well past the 240s render cadence, and an hour
    # when yesterday's cosmos is there to show instead.
    cache.set(gk, "1", ttl_seconds = HOLD_STALE if cached != None else HOLD_COLD)

    d = fetch_json(base + APOD_PATH, {"api_key": key, "thumbs": "true"})
    if d == None:
        return cached
    apod = extract_apod(d)
    if apod == None:
        # 200 + JSON but not APOD-shaped: keep the gate, never cache junk as
        # a success, serve whatever good reading we still have.
        print("apod: unusable payload")
        return cached
    cache.set(ck, json.encode(apod), ttl_seconds = STALE_TTL)
    cache.set(gk, "1", ttl_seconds = FRESH_TTL)
    return apod

def decode_extract(raw):
    """Read back what extract_apod wrote, defensively: the 1-arg json.decode
    aborts the render on a bad value, and every caller indexes all four
    fields."""
    if raw == None:
        return None
    d = json.decode(raw, None)
    if type(d) != "dict":
        return None
    for k in ["title", "date", "media", "src"]:
        if type(d.get(k, None)) != "string":
            return None
    return d

def extract_apod(d):
    """media_type image -> url; video -> thumbnail_url (often ""!); anything
    else -> title-only card. Every field defensively stringified: the API
    has served nulls."""
    title = strv(d, "title")
    date = strv(d, "date")
    media = strv(d, "media_type")
    src = ""
    if media == "image":
        src = strv(d, "url")
    elif media == "video":
        src = strv(d, "thumbnail_url")
    if len(title) > 110:
        title = title[0:107] + "..."
    if title == "" and src == "":
        return None
    return {"title": title, "date": date, "media": media, "src": src}

def strv(d, k):
    v = d.get(k, "")
    return v if type(v) == "string" else ""

def get_art(proxy, apod, live):
    """The day's picture at exactly 64x32 via the weserv resizing proxy - the
    source images are often multi-megabyte and must never be fetched raw.
    Returns the decoded widget, because decoding is itself a failure point:
    bytes render.Image rejects abort the render, so nothing reaches the
    3-day cache until the decoder has accepted it. None -> starfield card."""
    if apod == None or apod["src"] == "":
        return None
    date = apod["date"] if apod["date"] != "" else "na"
    ck = "apod:v1:i:" + proxy + ":" + date + ":" + apod["src"]

    cached = cache.get(ck)
    if cached != None:
        # Probation: the entry is demoted to a 1s TTL before its bytes go
        # anywhere near the decoder, and promoted back only once the decoder
        # has accepted them. A body that sniffs clean and still aborts
        # therefore costs one render - it cannot replay from cache for three
        # days, which is exactly what the sniff alone could not prevent.
        cache.set(ck, cached, ttl_seconds = 1)
        art = base64.decode(cached)
        if looks_jpeg(art):
            img = render.Image(src = art, width = 64, height = 32)
            cache.set(ck, cached, ttl_seconds = STALE_TTL)
            return img
        print("apod: cached art no longer sniffs as JPEG; dropped")

    if not live:
        return None
    gk = ck + ":gate"
    if cache.get(gk) != None:
        return None  # recently fetched, or recently failed
    cache.set(gk, "1", ttl_seconds = HOLD_COLD)  # gate before the request

    src = apod["src"]
    if src.startswith("https://"):
        src = src[8:]
    elif src.startswith("http://"):
        src = src[7:]
    resp = http.get(
        proxy,
        params = {
            "url": src,
            "w": "64",
            "h": "32",
            "fit": "cover",
            "a": "attention",
            "output": "jpg",
        },
        ttl_seconds = HTTP_TTL,
    )
    body = resp.body()
    if resp.status_code != 200 or not looks_jpeg(body):
        print("apod: art fetch failed (" + str(resp.status_code) + ")")
        return None
    img = render.Image(src = body, width = 64, height = 32)  # decode, then cache
    cache.set(ck, base64.encode(body), ttl_seconds = STALE_TTL)
    return img

def looks_jpeg(body):
    """A decodable baseline JPEG, not merely something shaped like one. SOI +
    EOI is also what a middle-corrupted 200 looks like, so walk the marker
    segments to the start of scan - every length field has to land exactly on
    the next marker - and insist on a frame header and a Huffman table.
    (\\xff literals are illegal in Starlark; elem_ords reads bytes.)"""
    n = len(body)
    if n < 125 or n > MAX_ART:
        return False
    o = list(body.elem_ords())
    if o[0] != 255 or o[1] != 216 or o[n - 2] != 255 or o[n - 1] != 217:
        return False
    i = 2
    sof = False
    dht = False
    for _ in range(64):
        if i + 1 >= n or o[i] != 255:
            return False
        m = o[i + 1]
        if m == 255:  # fill byte ahead of the real marker
            i += 1
            continue
        if m == 216 or m == 1 or (m >= 208 and m <= 215):  # SOI, TEM, RSTn
            i += 2
            continue
        if i + 3 >= n:
            return False
        seglen = o[i + 2] * 256 + o[i + 3]
        if seglen < 2 or i + 2 + seglen > n:
            return False
        if m == 218:  # SOS: entropy-coded data from here, stop walking
            return sof and dht
        if m == 196:  # DHT
            dht = True
        elif m >= 192 and m <= 207 and m != 200 and m != 204:  # SOFn
            sof = True
        i += 2 + seglen
    return False

# ------------------------------------------------------------------ helpers

def to_int(s):
    """Digits-only parse; -1 on anything else. int() would abort the render."""
    digits = "0123456789"
    if s == "":
        return -1
    n = 0
    for ch in s.elems():
        d = digits.find(ch)
        if d < 0:
            return -1
        n = n * 10 + d
    return n

MONTHS = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]

def fmt_date(date):
    """"2026-09-02" -> "SEP 2"; anything malformed -> "" (chip is skipped)."""
    parts = date.split("-")
    if len(parts) != 3:
        return ""
    m = to_int(parts[1])
    day = to_int(parts[2])
    if m < 1 or m > 12 or day < 1 or day > 31:
        return ""
    return MONTHS[m - 1] + " " + str(day)

def date_seed(date):
    """A stable per-day seed for the starfield (first 8 digits of the date,
    else today), so the fallback sky doesn't reshuffle every render."""
    n = 0
    count = 0
    for ch in date.elems():
        d = "0123456789".find(ch)
        if d >= 0:
            n = n * 10 + d
            count += 1
        if count >= 8:
            break
    if count == 0:
        return to_int(time.now().format("20060102"))
    return n

# ------------------------------------------------------------------- states

def picture_view(img, apod, show_title, show_date):
    """The main event: the picture edge to edge, caption furniture on top."""
    layers = [img]
    if show_date:
        ds = fmt_date(apod["date"])
        if ds != "":
            layers.append(date_chip(ds))
    if apod["media"] == "video":
        layers.append(render.Padding(
            pad = (54, 1, 0, 0),
            child = render.Box(width = 9, height = 7, color = SHADE, child = play_glyph()),
        ))
    if show_title and apod["title"] != "":
        layers.append(title_bar(apod["title"], video = False))
    return render.Stack(children = layers)

def date_chip(ds):
    return render.Padding(
        pad = (1, 1, 0, 0),
        child = render.Box(
            width = 4 * len(ds) + 3,
            height = 7,
            color = SHADE,
            child = render.Text(ds, font = "tom-thumb", color = AMBER),
        ),
    )

def title_bar(title, video):
    kids = []
    marquee_w = 62
    if video:
        kids = [play_glyph(), render.Box(width = 2, height = 1)]
        marquee_w = 57
    kids.append(render.Marquee(
        width = marquee_w,
        child = render.Text(title, font = "tom-thumb", color = INK),
    ))
    return render.Padding(
        pad = (0, 25, 0, 0),
        child = render.Box(
            width = 64,
            height = 7,
            color = SHADE,
            child = render.Row(cross_align = "center", children = kids),
        ),
    )

def play_glyph():
    return render.Row(
        cross_align = "center",
        children = [
            render.Box(width = 1, height = 5, color = INK),
            render.Box(width = 1, height = 3, color = INK),
            render.Box(width = 1, height = 1, color = INK),
        ],
    )

def star_color():
    r = random.number(0, 99)
    if r < 55:
        return "#4E5566"
    if r < 82:
        return "#D8DEE8"
    if r < 92:
        return "#9DB4FF"
    return "#FFD9A0"

def starfield_card(apod, show_title, show_date):
    """Every path that has no picture ends here: cold boot, API down with
    nothing cached, a video day with no thumbnail, a hostile payload. Drawn
    procedurally, seeded by the APOD date so the sky holds still all day.
    With a title to show it becomes the title card; otherwise the wordmark."""
    date = ""
    title = ""
    video = False
    if apod != None:
        date = apod["date"]
        title = apod["title"]
        video = apod["media"] == "video"
    random.seed(date_seed(date))

    layers = [render.Box(width = 64, height = 32, color = NIGHT)]
    for _ in range(42):
        x = random.number(0, 63)
        y = random.number(0, 31)
        layers.append(render.Padding(
            pad = (x, y, 0, 0),
            child = render.Box(width = 1, height = 1, color = star_color()),
        ))
    for i in range(3):
        # One bright cross per third of the panel so they never clump.
        x = random.number(2 + i * 22, 16 + i * 22)
        y = random.number(3, 21)
        layers.append(render.Padding(
            pad = (x - 1, y, 0, 0),
            child = render.Box(width = 3, height = 1, color = INK),
        ))
        layers.append(render.Padding(
            pad = (x, y - 1, 0, 0),
            child = render.Box(width = 1, height = 3, color = INK),
        ))

    if title != "" and show_title:
        if show_date:
            ds = fmt_date(date)
            if ds != "":
                layers.append(date_chip(ds))
        layers.append(title_bar(title, video))
    else:
        layers.append(render.Box(
            width = 64,
            height = 32,
            child = render.Column(
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text("APOD", font = "tb-8", color = INK),
                    render.Box(width = 22, height = 1, color = AMBER),
                    render.Box(width = 1, height = 1),
                    render.Text("NASA", font = "tom-thumb", color = DIM),
                ],
            ),
        ))
    return render.Stack(children = layers)

# -------------------------------------------------------------------- schema

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "NASA API key",
                desc = "Optional. The shared DEMO_KEY works out of the box; grab a free key at api.nasa.gov if you run several devices.",
                icon = "key",
                default = "",
            ),
            schema.Toggle(
                id = "show_title",
                name = "Show title",
                desc = "The picture's title on a strip along the bottom.",
                icon = "font",
                default = True,
            ),
            schema.Toggle(
                id = "show_date",
                name = "Show date",
                desc = "A small date stamp in the corner. Always shown when the picture isn't today's.",
                icon = "calendar",
                default = False,
            ),
        ],
    )
