"""
Applet: Stocks (Classic)
Summary: Classic one-symbol stocks
Description: A faithful recreation of Tidbyt's first-party Stocks app: one symbol, price, day change, and an intraday sparkline.
Author: nsluke

The original first-party Stocks app died with its data provider. This is the
same panel, rebuilt: SYMBOL and price on top, the day's change under it in
green or red, and the current (or most recent) session's price line filling
the bottom half, filled in the day's color.

Data: Cboe's delayed-quote CDN (cdn.cboe.com), keyless and UA-agnostic —
verified live before this was written. Yahoo's chart API 429s from plain
curl with or without a browser UA, and Stooq now sits behind a JavaScript
proof-of-work challenge, so neither is shippable from pixlet. Cboe field
notes: quotes are ~500B of flat JSON (current_price, price_change,
price_change_percent, prev_day_close, open, last_trade_time); the intraday
chart is 1-minute OHLC bars, ~90KB over a full session, so only the closes
survive into cache, resampled to <= 64 points (the panel is 64px wide).
An UNKNOWN or lowercase symbol returns HTTP 403 with an XML body from S3,
not a 404 — sniff before decoding. Index symbols are fetched with a leading
underscore (_SPX) and echoed back with a caret (^SPX). Everything is
US-listed and USD; non-US listings simply aren't found, so there is no
wrong-currency case to mishandle. Prices run ~15 minutes behind.

Three traps in that feed, all found by rendering real tickers and all
handled below, because each one otherwise renders as confident nonsense:
  - A minute with no print is emitted as an all-zero OHLC bar carrying real
    share volume (CHPT: 96 of 389 bars). Those are markers, not $0.00
    prices — dropped in get_series, or the sparkline is a barcode.
  - A symbol the feed no longer carries answers 200 with an all-zero record
    stamped last_trade_time 2000-01-01T00:00:00 (MULN, FFIE, NKLA). Without
    a sniff it renders as a live, unchanged $0.00 — see not_traded().
  - The intraday chart keeps serving a thinly-traded symbol's LAST charted
    session indefinitely (GEVO: a 2-week-old session under today's quote;
    BRK.A: 4.5 months). The chart's own date is therefore checked against
    the quote's last trade before the line is allowed on the panel.

Outside 09:30-16:00 ET on weekdays (or when the last trade is from an older
session — holidays, the delayed first minutes of the open) a dim dot marks
the reading as "most recent session" rather than live.

On a 64x64 panel the chart is the thing worth growing, since it is what the
first-party app was built around: symbol and price stop sharing a row and
the sparkline takes 38 of the 64 rows instead of 16, with yesterday's close
drawn across it as a dim level whenever the session crossed it. Same points
(the panel is no wider), same colours, same dot — see square_layout(). When
there is no session to draw at all, the square panel does NOT keep the tall
header and 38 black rows under it: the reading centres instead, the way the
message cards do — see square_no_chart().
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

API_BASE = "https://cdn.cboe.com"
QUOTE_PATH = "/api/global/delayed_quotes/quotes/"
CHART_PATH = "/api/global/delayed_quotes/charts/intraday/"

FRESH_LIVE = 300  # inside market hours: re-poll every 5 min
FRESH_IDLE = 900  # outside them nothing can move; the chart alone is ~90KB
RETRY_TTL = 60  # back off after a failure
STALE_TTL = 86400  # serve last good extract up to a day through an outage

# The feed's "I don't carry this symbol" stamp (verified on MULN/FFIE/NKLA).
NO_TRADE_TIME = "2000-01-01T00:00:00"

# Path-safe characters that actually occur in US tickers. Anything else —
# '%' above all, which aborts http.get on an invalid escape — is refused
# before it can reach a URL.
SYMBOL_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.^-"
MAX_SYMBOL = 24

WHITE = "#FFFFFF"
GREY = "#9C9C9C"
DIM = "#5C6470"
GREEN = "#2ECC71"
GREEN_FILL = "#0C4322"
RED = "#FF4136"
RED_FILL = "#571511"
GREY_FILL = "#2A2A2A"
AMBER = "#FFA33A"

MAX_POINTS = 64  # one cached close per panel column, at most

# Square (64x64) panel proportions. The original app was built around its
# sparkline, so that is what the extra rows buy: a 38px chart instead of a
# 16px strip, with the symbol, price and change stacked above it. The point
# count is deliberately NOT raised — the panel is still 64 columns wide.
SQ_PLOT_H = 38
SQ_GAP_H = 2
SQ_SYMBOL_CHARS = 12  # tb-8 runs ~5px/char; 12 fills the 62px inside the margins

def main(config):
    sym = normalize(config.str("symbol", "AAPL"))
    if not is_symbol(sym):
        return render.Root(child = message_card(sym, "bad symbol", "check symbol"))
    base = api_base(config.str("api", API_BASE))  # CLI-only test hook
    show_pct = config.bool("percent", False)

    q = get_quote(sym, base)
    if q == "nf":
        return render.Root(child = message_card(sym, "not found", "check symbol"))
    if q == "nd":
        return render.Root(child = message_card(sym, "not traded", "delisted?"))
    if q == None:
        return render.Root(child = message_card(sym, "no data", "retrying soon"))

    closes = session_closes(get_series(sym, base), q)

    price = q["price"]
    if price == None and len(closes) > 0:
        price = closes[-1]
    if price == None:
        return render.Root(child = message_card(display_symbol(q, sym), "no price data", "halted or new"))

    chg, pct = day_change(q, price)
    direction = chg
    if direction == None and len(closes) > 1:
        direction = closes[-1] - closes[0]
    color, fill = GREY, GREY_FILL
    if direction != None:
        color, fill = (GREEN, GREEN_FILL) if direction >= 0 else (RED, RED_FILL)

    # 64x64 panels get their own layout; wide panels keep the one below.
    if is_square():
        return render.Root(
            child = square_layout(
                display_symbol(q, sym),
                price,
                chg,
                pct,
                color,
                fill,
                closes,
                q,
                show_pct,
            ),
        )

    return render.Root(
        child = render.Column(
            children = [
                top_row(display_symbol(q, sym), price),
                change_row(chg, pct, color, show_pct, market_closed(q)),
                sparkline(closes, q, price, color, fill),
            ],
        ),
    )

def normalize(raw):
    s = raw.strip().upper()
    if s.startswith("$"):
        s = s[1:]
    if s == "":
        s = "AAPL"
    return s

def is_symbol(s):
    """A ticker this app is willing to put in a URL. The not-found card
    exists for bad user input, and every class of it must reach that card
    rather than aborting inside http.get — which is what '%' does, since
    Go rejects the malformed escape before the request is even made."""
    if len(s) == 0 or len(s) > MAX_SYMBOL:
        return False
    for i in range(len(s)):
        if s[i] not in SYMBOL_CHARS:
            return False
    return True

def api_base(raw):
    """Test hook, deliberately absent from get_schema() (same shape as the
    NFL exemplar's). Anything that isn't an http(s) origin falls back to the
    real CDN instead of aborting the render on an unsupported scheme."""
    b = raw.strip()
    if b.startswith("http://") or b.startswith("https://"):
        return b
    return API_BASE

def display_symbol(q, sym):
    return q["sym"] if q["sym"] != "" else sym

# ---------------------------------------------------------------- data layer

def fetch_json(url, gate_key, fresh_ttl):
    """Gate-before-request: a transport error aborts the render and Starlark
    cannot catch it, so the gate key (written before the request) limits the
    damage to one failed render per RETRY_TTL. Returns the decoded dict, the
    string "nf" on a 403/404 (Cboe's S3 serves unknown symbols as 403 XML),
    or None on any other failure."""
    if cache.get(gate_key) != None:
        return None  # recently fetched or recently failed; caller uses cache
    cache.set(gate_key, "1", ttl_seconds = RETRY_TTL)
    resp = http.get(url, ttl_seconds = RETRY_TTL)

    # Strip first: the sniff is here to reject HTML error pages, and a CDN
    # re-upload or a pretty-printer that adds one trailing newline must not
    # take the app to "no data" for the life of the install.
    body = resp.body().strip()
    if resp.status_code == 403 or resp.status_code == 404:
        cache.set(gate_key, "1", ttl_seconds = fresh_ttl)
        return "nf"
    if resp.status_code != 200:
        print("stkc: " + url[:60] + " -> " + str(resp.status_code))
        return None
    if not (body.startswith("{") and body.endswith("}")):
        print("stkc: non-JSON body from " + url[:60])
        return None
    cache.set(gate_key, "1", ttl_seconds = fresh_ttl)
    return json.decode(body)

def url_symbol(sym):
    # Indexes are ^SPX to humans but _SPX.json on the CDN (verified live).
    if sym.startswith("^"):
        return "_" + sym[1:]
    return sym

def get_quote(sym, base):
    """The ~500B quote, extracted small and cached so an outage serves the
    last good reading. Returns a dict, "nf" for an unknown symbol with no
    history, "nd" for one the feed carries but has no data for, or None when
    there is nothing at all to show."""
    ck = "stkc:q:" + sym + ":" + base
    d = fetch_json(base + QUOTE_PATH + url_symbol(sym) + ".json", ck + ":gate", poll_ttl())

    if d == "nf":
        # A valid symbol that momentarily 403s recovers on the next open
        # gate; only a symbol with no last-good data reads as not-found.
        raw = cache.get(ck)
        if raw != None:
            got = json.decode(raw)
            if "nf" not in got:
                return got
        cache.set(ck, json.encode({"nf": "nf"}), ttl_seconds = poll_ttl())
        return "nf"

    if d == None:
        raw = cache.get(ck)
        if raw == None:
            return None
        got = json.decode(raw)
        if "nf" not in got:
            return got

        # A cached verdict, not a quote: never let one back out as a dict
        # the layout would then index for a price it does not have.
        return "nd" if got["nf"] == "nd" else "nf"

    data = d.get("data", None)
    if type(data) != "dict":
        return None
    q = {
        "sym": data.get("symbol", "") if type(data.get("symbol", "")) == "string" else "",
        "price": nonzero(to_f(data.get("current_price", None))),
        "chg": to_f(data.get("price_change", None)),
        "pct": to_f(data.get("price_change_percent", None)),
        "prev": to_f(data.get("prev_day_close", None)),
        "open": nonzero(to_f(data.get("open", None))),
        "ltt": data.get("last_trade_time", "") if type(data.get("last_trade_time", "")) == "string" else "",
    }

    # A symbol the feed has dropped is a 200 with an all-zero record, not a
    # 403 — cache the verdict, never the zeros, or "0.00 +0.00 +0.00%" gets
    # rendered in green as though it were a real unchanged quote.
    if not_traded(q):
        cache.set(ck, json.encode({"nf": "nd"}), ttl_seconds = poll_ttl())
        return "nd"

    cache.set(ck, json.encode(q), ttl_seconds = STALE_TTL)
    return q

def not_traded(q):
    """The feed's no-data sentinel. Only the epoch last_trade_time counts:
    it is the one field that is unambiguous. (Indexes legitimately report
    volume 0, so volume is deliberately not part of this test — ^SPX would
    fail it. A merely null price is a different, softer case: the chart can
    still carry the panel, so it keeps the existing no-price fallback.)"""
    return q["ltt"] == NO_TRADE_TIME

def get_series(sym, base):
    """The intraday closes, resampled to <= 64 points BEFORE caching: the raw
    chart is ~90KB of 1-minute OHLC over a full session and the panel only
    has 64 columns. Returns {"c": [floats], "d": "YYYY-MM-DD"} or None."""
    ck = "stkc:c:" + sym + ":" + base
    d = fetch_json(base + CHART_PATH + url_symbol(sym) + ".json", ck + ":gate", poll_ttl())

    if d == None or d == "nf":
        raw = cache.get(ck)
        return json.decode(raw) if raw != None else None

    bars = d.get("data", [])
    if type(bars) != "list":
        bars = []
    closes = []
    date = ""
    for b in bars:
        if type(b) != "dict":
            continue
        if date == "":
            dt = b.get("datetime", "")
            if type(dt) == "string" and len(dt) >= 10:
                date = dt[:10]
        p = b.get("price", None)
        if type(p) != "dict":
            continue
        c = to_f(p.get("close", None))

        # A minute in which the symbol did not print comes back as an
        # all-zero OHLC bar carrying real share volume — a "no trade"
        # marker, not a $0.00 price. Thinly-traded names are full of them
        # (CHPT: 96 of 389 bars) and plotting them shreds the line.
        if c == None or c == 0:
            continue
        closes.append(c)

    closes = resample(closes, MAX_POINTS)
    out = {"c": [r3(c) for c in closes], "d": date}

    # An empty session (holiday gaps, brand-new listing) is a real
    # observation, not a failure — but it must never overwrite a cached
    # session that has actual points.
    if len(closes) > 0 or cache.get(ck) == None:
        cache.set(ck, json.encode(out), ttl_seconds = STALE_TTL)
    return out

def session_closes(series, q):
    """The closes, but only when they belong to the SAME session as the
    price above them. The chart endpoint keeps serving a thinly-traded
    symbol's last charted session indefinitely — GEVO's was two weeks stale
    and BRK.A's four months, both under a live quote — so an unchecked line
    would draw one day's shape beneath another day's price and change. On a
    mismatch the panel falls through to the honest two-point open->price
    line. (No date on either side means nothing to disagree about: keep the
    series rather than throw away good data over a missing field.)"""
    if series == None:
        return []
    day = series.get("d", "")
    ltt = q["ltt"]
    if day != "" and len(ltt) >= 10 and day != ltt[:10]:
        return []
    return series.get("c", [])

def resample(vals, n):
    if len(vals) <= n:
        return vals
    out = []
    for i in range(n):
        out.append(vals[i * (len(vals) - 1) // (n - 1)])
    return out

def to_f(v):
    t = type(v)
    if t == "int" or t == "float":
        return float(v)
    return None

def nonzero(v):
    """$0.00 is the feed's way of saying "nothing here", never a price: no
    US-listed security quotes at zero. Folding it into None routes it to the
    already-designed no-price fallbacks instead of onto the panel."""
    return None if v == 0 else v

def r3(x):
    if x < 0:
        return -(int(-x * 1000 + 0.5)) / 1000.0
    return int(x * 1000 + 0.5) / 1000.0

# ------------------------------------------------------------------ helpers

def day_change(q, price):
    """Change and percent from the quote when it has them, recomputed from
    prev_day_close when it doesn't. (None, None) when neither is possible."""
    chg = q["chg"]
    pct = q["pct"]

    # A zero previous close is no baseline at all: without the guard the
    # whole of today's price gets presented as today's gain.
    if chg == None and q["prev"] != None and q["prev"] != 0:
        chg = price - q["prev"]
    if pct == None and chg != None and q["prev"] != None and q["prev"] != 0:
        pct = chg / q["prev"] * 100
    return chg, pct

def in_session():
    """Clock only: inside 09:30-16:00 ET on a weekday. Holidays look open
    here and are caught by the last-trade date in market_closed()."""
    now = time.now().in_location("America/New_York")
    wd = now.format("Mon")
    if wd == "Sat" or wd == "Sun":
        return False
    hm = int(now.format("15")) * 60 + int(now.format("04"))
    return hm >= 9 * 60 + 30 and hm < 16 * 60

def poll_ttl():
    """Poll pace. Overnight and all weekend the session is finished and the
    ~90KB chart cannot change, so re-pulling it every 5 minutes is pure
    waste; 15 minutes still picks the new session up well inside the feed's
    own 15-minute delay."""
    return FRESH_LIVE if in_session() else FRESH_IDLE

def market_closed(q):
    """True outside 09:30-16:00 ET weekdays, or when the last trade belongs
    to an older session (holidays; the delayed first minutes of the open)."""
    if not in_session():
        return True
    ltt = q["ltt"]
    if len(ltt) >= 10 and ltt[:10] != time.now().in_location("America/New_York").format("2006-01-02"):
        return True
    return False

def fmt_f(x, dp):
    """Fixed-point float format via int math (no round()/math module)."""
    neg = x < 0
    if neg:
        x = -x
    scale = 1
    for _ in range(dp):
        scale *= 10
    n = int(x * scale + 0.5)
    s = str(n // scale)
    if dp > 0:
        frac = str(n % scale)
        s = s + "." + "0" * (dp - len(frac)) + frac
    return ("-" if neg else "") + s

def fmt_price(p):
    # Adaptive precision so big prices still fit beside the symbol — and so
    # a sub-dollar stock reads as 0.0031 rather than "0.00", which is the
    # very nothing-here reading the feed's own zeros are meant to carry.
    if abs_f(p) < 1:
        return fmt_f(p, 4)
    if p < 1000:
        return fmt_f(p, 2)
    if p < 10000:
        return fmt_f(p, 1)
    return fmt_f(p, 0)

def fmt_change(chg):
    s = fmt_f(chg, 2 if abs_f(chg) < 100 else (1 if abs_f(chg) < 10000 else 0))
    return s if chg < 0 else "+" + s

def fmt_pct(pct):
    s = fmt_f(pct, 2 if abs_f(pct) < 10 else 1)
    return (s if pct < 0 else "+" + s) + "%"

def abs_f(x):
    return -x if x < 0 else x

# ------------------------------------------------------------------- layout

def is_square():
    """True on a 64x64 panel, false on the classic 2:1 one.

    Branches on the canvas's SHAPE, never its size: a 2x wide panel reports
    128x64 and a 2x square one 128x128, so a bare height test reads both as
    64-tall and gets one of them wrong. The slack keeps a merely tallish
    panel on the wide branch.
    """
    w, h = canvas.size()
    return h * 2 > w + 16

def top_row(sym, price):
    """SYMBOL left, price right, both tb-8 — the first-party look. The
    symbol yields to the price: tb-8 runs ~5px/char, so truncate the symbol
    to whatever the price leaves of the 62px inside the margins."""
    price_str = fmt_price(price)
    room = (62 - 5 * len(price_str) - 2) // 5
    if room < 2:
        room = 2
    return render.Padding(
        pad = (1, 1, 1, 0),
        child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Text(sym[:room], font = "tb-8", color = WHITE),
                render.Text(price_str, font = "tb-8", color = WHITE),
            ],
        ),
    )

def change_texts(chg, pct, color, show_pct):
    """The change as one or two Texts: the leading form in the day's color,
    the other form in grey when both fit. Shared by the wide change row and
    the square no-chart card so the two can never word it differently."""
    if chg == None:
        primary, secondary = "--", ""
    elif show_pct:
        primary = fmt_pct(pct) if pct != None else fmt_change(chg)
        secondary = fmt_change(chg) if pct != None else ""
    else:
        primary = fmt_change(chg)
        secondary = fmt_pct(pct) if pct != None else ""

    texts = [render.Text(primary, font = "tom-thumb", color = color)]
    if secondary != "" and 4 * (len(primary) + 1 + len(secondary)) <= 56:
        texts.append(render.Text(" " + secondary, font = "tom-thumb", color = GREY))
    return texts

def change_row(chg, pct, color, show_pct, closed):
    """The day change, colored; the other form of it in grey when it fits;
    a dim dot on the right when the reading is a past session's."""
    right = []
    if closed:
        right = [render.Box(width = 2, height = 2, color = DIM)]

    return render.Padding(
        pad = (1, 1, 1, 0),
        child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [render.Row(children = change_texts(chg, pct, color, show_pct))] + right,
        ),
    )

def plot_points(closes, q, price):
    """The points a session line would be drawn from: the session's closes,
    or the honest two-point open->price line when there is no series at all
    (holiday gap, brand-new listing). Empty when there is nothing whatever
    to plot — a quote with a price but no open and no closes, which is a
    pre-market or halted-then-resumed reading. Both layouts ask this one
    question so they cannot disagree about whether a chart exists."""
    if len(closes) >= 2:
        return closes
    if q["open"] != None and price != None:
        return [q["open"], price]
    return []

def sparkline(closes, q, price, color, fill):
    """The session's price line, filled, in the day's color. With nothing at
    all to plot, dark glass: on a 2:1 panel that is a 16px strip under a
    full-height reading, which is a different (and much smaller) hole than
    the same strip would be on a square one — see square_no_chart()."""
    pts = plot_points(closes, q, price)
    if len(pts) < 2:
        return render.Box(width = 64, height = 16)

    lo, hi = pts[0], pts[0]
    for v in pts:
        if v < lo:
            lo = v
        if v > hi:
            hi = v
    pad = (hi - lo) * 0.05
    if pad == 0:
        pad = 1.0

    return render.Plot(
        data = [(float(i), pts[i]) for i in range(len(pts))],
        width = 64,
        height = 16,
        color = color,
        color_inverted = color,
        fill = True,
        fill_color = fill,
        x_lim = (0.0, float(len(pts) - 1)),
        y_lim = (lo - pad, hi + pad),
    )

# ------------------------------------------------- square (64x64) layout

def square_layout(sym, price, chg, pct, color, fill, closes, q, show_pct):
    """The same panel, re-proportioned for a square one.

    Not the 2:1 layout with black underneath it: the symbol and the price
    stop sharing a row (so neither has to yield width to the other) and the
    sparkline — the thing the first-party app was built around — grows from
    a 16px strip to 38px, most of the panel. 17 + 7 + 2 + 38 = 64 exactly.
    Colours, fonts and the market-closed dot are the wide layout's own;
    `change_row` is literally the same function.

    The one case that is NOT just re-proportioned is a reading with no
    session line at all. Growing an empty plot to 38 rows grows the hole
    with it, so that state gets its own centred card instead.
    """
    pts = plot_points(closes, q, price)
    if len(pts) < 2:
        return square_no_chart(sym, price, chg, pct, color, show_pct, q)

    return render.Column(
        children = [
            square_head(sym, price),
            change_row(chg, pct, color, show_pct, market_closed(q)),
            render.Box(width = 64, height = SQ_GAP_H),
            square_sparkline(pts, q, color, fill),
        ],
    )

def square_no_chart(sym, price, chg, pct, color, show_pct, q):
    """A real quote with nothing to plot under it.

    Reached when the quote has a price but no open and the chart is empty —
    a pre-market reading, or a name halted before it printed. The wide panel
    absorbs this in 16 dark rows beneath a reading that already fills the
    other 16; a square panel would have to leave 38 of its 64 rows black
    under a header pinned to the top, which is the one thing this layout
    exists to stop. So the reading centres instead, in the same shape
    `message_card` uses, with a grey line naming what is missing — the
    ticker, its price, its change, and no pretence of a session.
    """
    right = []
    if market_closed(q):
        right = [
            render.Box(width = 3, height = 1),
            render.Box(width = 2, height = 2, color = DIM),
        ]

    return render.Box(
        width = 64,
        height = 64,
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(sym[:SQ_SYMBOL_CHARS], font = "tb-8", color = WHITE),
                render.Text(fmt_price(price), font = "tb-8", color = WHITE),
                render.Box(width = 1, height = 2),
                render.Row(
                    cross_align = "center",
                    children = change_texts(chg, pct, color, show_pct) + right,
                ),
                render.Box(width = 1, height = 2),
                render.Text("no chart data", font = "tom-thumb", color = GREY),
            ],
        ),
    )

def square_head(sym, price):
    """SYMBOL over price, both tb-8, both left. On the 2:1 panel these share
    one row and the symbol is truncated to whatever the price leaves of it;
    with a row each, the price is never a reason to shorten the ticker."""
    return render.Padding(
        pad = (1, 1, 1, 0),
        child = render.Column(
            children = [
                render.Text(sym[:SQ_SYMBOL_CHARS], font = "tb-8", color = WHITE),
                render.Text(fmt_price(price), font = "tb-8", color = WHITE),
            ],
        ),
    )

def square_sparkline(pts, q, color, fill):
    """The session line with SQ_PLOT_H rows instead of 16.

    Same points (still <= 64 — the panel is no wider, and `plot_points` has
    already resolved the two-point open->price fallback), same day colour
    and fill. The height is the whole change, plus the one thing 16 rows had
    no room for: the previous close as a dim level, so the fill has a
    visible line to be above or below. There is no empty case here — with
    fewer than two points `square_layout` never gets this far.
    """
    lo, hi = pts[0], pts[0]
    for v in pts:
        if v < lo:
            lo = v
        if v > hi:
            hi = v
    pad = (hi - lo) * 0.05
    if pad == 0:
        pad = 1.0

    x_lim = (0.0, float(len(pts) - 1))
    y_lim = (lo - pad, hi + pad)
    line = render.Plot(
        data = [(float(i), pts[i]) for i in range(len(pts))],
        width = 64,
        height = SQ_PLOT_H,
        color = color,
        color_inverted = color,
        fill = True,
        fill_color = fill,
        x_lim = x_lim,
        y_lim = y_lim,
    )

    ref = baseline(q, lo, hi)
    if ref == None:
        return line

    # A second Plot on the SAME limits rather than a Box at a row computed
    # here: the renderer does the value->pixel mapping either way, so this
    # one cannot drift a row off the level it claims to mark.
    return render.Stack(
        children = [
            line,
            render.Plot(
                data = [(x_lim[0], ref), (x_lim[1], ref)],
                width = 64,
                height = SQ_PLOT_H,
                color = DIM,
                color_inverted = DIM,
                x_lim = x_lim,
                y_lim = y_lim,
            ),
        ],
    )

def baseline(q, lo, hi):
    """Yesterday's close, but only when the session actually straddles it.

    Skipped with no previous close to draw (and on a zero one, the same
    not-a-baseline the change math already refuses). Skipped when the whole
    session sits on one side of it: the level would land in the 5% headroom
    and read as a frame along the top or bottom edge, and it would be saying
    what the green or red change row has said already. A level earns its row
    when the day crossed it — then it marks which parts of the session were
    up and which were down, which is the one thing 16 rows had no room for.
    """
    prev = q["prev"]
    if prev == None or prev == 0:
        return None
    if prev <= lo or prev >= hi:
        return None
    return prev

def message_card(sym, line1, line2):
    # The cards centre in whatever panel they land on: on a square one a
    # 32px box would strand the whole message in the top half.
    return render.Box(
        width = 64,
        height = 64 if is_square() else 32,
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(sym[:12], font = "tb-8", color = AMBER),
                render.Box(width = 1, height = 2),
                render.Text(line1, font = "tom-thumb", color = WHITE),
                render.Text(line2, font = "tom-thumb", color = GREY),
            ],
        ),
    )

# -------------------------------------------------------------------- schema

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "symbol",
                name = "Symbol",
                desc = "Ticker symbol: US-listed stocks and ETFs, or ^SPX-style indexes.",
                icon = "chartLine",
                default = "AAPL",
            ),
            schema.Toggle(
                id = "percent",
                name = "Percent change",
                desc = "Lead with the day change as a percentage instead of dollars.",
                icon = "percent",
                default = False,
            ),
        ],
    )
