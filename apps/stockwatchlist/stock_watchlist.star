"""
Applet: Stock Watchlist
Summary: Your stock & ETF watchlist
Description: Up to 100 US stocks and ETFs with market indices on page one. Delayed prices and changes from US Stock & ETF Prices on RapidAPI. A free BASIC key works for five tickers with infrequent updates; paid plans support larger lists and more frequent updates.
Author: Sudhanshu Singh
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("hash.star", "hash")
load("http.star", "http")
load("humanize.star", "humanize")
load("re.star", "re")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

API_URL = ""  # optional full quotes URL or API base; default is the public RapidAPI gateway
API_HOST = "us-stock-etf-prices.p.rapidapi.com"
URL_HINT = "rapidapi.com"
UPGRADE_URL = "rapidapi.com/logicione/api/us-stock-etf-prices"  # swap this one constant for a short link later
UPGRADE_SCROLL_MS = 5000  # reserve a full brisk pass, independently of static page delays
UPGRADE_FRAME_MS = 25  # Root delay: one tom-thumb UPGRADE_URL pass stays under 5s, and 1500 ms holds divide evenly

ET = "America/New_York"
LOOPBACK_RE = "^http://127\\.0\\.0\\.1:[0-9]{1,5}(/[A-Za-z0-9_-]+)*$"  # tests only
ISO_RE = "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\\.[0-9]+)?(Z|[+-][0-9]{2}:[0-9]{2})$"
SYMBOL_RE = "^[A-Z]{1,5}(\\.[A-Z]{1,2})?$"  # the API's rule; one bad symbol fails the whole request with a 400
CHUNK = 5  # RapidAPI callers may send at most 5 symbols per request (server rule); each chunk is a billed request
MAX_SYMBOLS = 100
MAX_REQUESTS_PER_RENDER = 5  # provider limit: 5 requests/second, including indices
RENDER_BUDGET_SECONDS = 15
REQUEST_TIMEOUT_SECONDS = 5  # Pixlet's HTTP deadline; leave room for one in-flight request
DEFAULT_SYMBOLS = "SPY,QQQ,AAPL,MSFT,NVDA"
INDEX_SYMBOLS = ["DJI", "SPX", "NDX", "RUT", "VIX"]
INDEX_LABELS = {"DJI": "DOW", "SPX": "S&P", "NDX": "NDX", "RUT": "RUT", "VIX": "VIX"}
FREE_MAX = 1000  # a positive request limit below this identifies BASIC; zero means unknown
FREE_SLOTS = ((9, 50), (11, 50), (13, 50), (15, 50), (16, 25))  # ET; a free plan calls once per slot
FREE_DAILY = 5  # a free plan never calls more than this in any 24 h, even without rate-limit headers
PAID_TTL = 540  # inside the window; Tronbyt renders about every 10 min (recommendedInterval)
FREE_TTL = 7200  # persistent HTTP cache protects BASIC from frequent Tronbyt renders
COLD_TTL = 3600  # at most one off-schedule call (made only because there is nothing to show yet) an hour
LAST_GOOD_TTL = 7 * 86400
DAY = 86400

TEXT = "#ffffff"
UP = "#00d26a"
DOWN = "#ff3b30"
FLAT = "#9e9e9e"
EXT = "#ffb000"
DIM = "#5a5a5a"
STALE = "#ff8c00"
SYM = "#ffe066"
FONT = "tom-thumb"

def main(config):
    started = time.now().unix  # wall clock, independent of the test/scheduling ET clock
    key = config.str("rapidapi_key", "").strip()  # a pasted newline would make the header invalid and crash the render
    tokens, more = parse_symbols(config.str("symbols", "") or DEFAULT_SYMBOLS)
    identity = hash.sha256(key + json.encode(tokens))
    state = {"page_key": "page:" + identity}
    state["page_offset"] = max(to_int(config.str("page_offset", ""), to_int(cache.get(state["page_key"]), 0)), 0)
    state["plan_limit"] = max(to_int(cache.get("lim:" + hash.sha256(key)), to_int(config.str("plan_limit", ""), 0)), 0)
    root = watchlist(config, key, tokens, more, state, started)
    print("STATE page_offset=%d plan_limit=%d" % (state["page_offset"], state["plan_limit"]))
    return root

def watchlist(config, key, tokens, more, state, started):
    if not key:
        return notice_root(["ADD RAPIDAPI KEY", "FREE KEY WORKS", "FIRST 5 TICKERS", UPGRADE_URL], EXT)

    now = now_et(config)
    ext = config.bool("extended", False)

    # Rendering remains useful from the actual session open, before delayed-data fetch slots.
    lo, hi = (4 * 60, 20 * 60 + 15) if ext else (9 * 60 + 30, 16 * 60 + 30)
    k = hash.sha256(key)
    state["market_closed"] = weekend(now) or minutes(now) < lo or minutes(now) >= hi or bool(cache.get("dormant:" + k))
    state["show_indices"] = config.bool("show_indices", True)
    ik = "last-indices:" + hash.sha256(key)
    state["indices"] = decode_obj(cache.get(ik))
    if state["indices"]:
        state["indices"]["_old"] = [s for s in INDEX_SYMBOLS if type(state["indices"].get(s)) == "dict"]
    wanted = [s for s, ok in tokens if ok]

    # The cache module is shared by every install of the app, hence keys hashed with the RapidAPI key.
    lh = hash.sha256(key + ",".join(wanted))  # per key and ticker list
    last = decode_obj(cache.get("last:" + lh))
    lim = state["plan_limit"]
    free = is_free(lim)
    indices_covered = state["indices"] != None and not [s for s in INDEX_SYMBOLS if type(state["indices"].get(s)) != "dict"]

    # Confirmed BASIC spends only its first-chunk ticker probe per slot; indices use cache/no-data.
    # Unknown plans use the paid budget until a response identifies BASIC or exhausts quota.
    index_call = state["show_indices"] and (in_window(now, ext) or not indices_covered)
    quote_requests = MAX_REQUESTS_PER_RENDER - (1 if index_call and not free else 0)

    # One request per CHUNK tickers. A free plan gets the first chunk only, so its 5 requests a day stay 5.
    chunks = [wanted[i:i + CHUNK] for i in range(0, len(wanted), CHUNK)]
    if free:
        state["page_offset"] = 0
    shown, notes = free_view(tokens, chunks, lim)
    state["page_offset"] %= max(len(shown), 1)
    offset = state["page_offset"]

    # Fetch exactly the same contiguous window that the board can display. No quote cache is
    # needed to continue on the next launchd invocation. Invalid rows count toward page capacity.
    capacity = min(CHUNK * quote_requests, page_layout(len(shown), last, now, ext, False, notes, indices = state["show_indices"])[0])
    window = shown[offset:offset + capacity]
    if [s for s, ok in window if ok]:
        # A fetched quote may add a status line, even when the cached window had none.
        capacity = min(capacity, page_layout(len(shown), last, now, ext, False, notes, reserve_status = True, indices = state["show_indices"])[0])
        window = window[:capacity]
    state["window_end"] = offset + len(window)
    selected = [s for s, ok in window if ok]
    fetch = [selected[i:i + CHUNK] for i in range(0, len(selected), CHUNK)]
    if free and chunks:
        fetch = [chunks[0]]
    until = to_int(cache.get("pause:" + k), 0)
    if until > now.unix:
        return board(shown, more, last, now, ext, state = state, cached = True, dim = free, notices = notes + [pause_notice(lim, until, now, k)])
    if not fetch and (free or not index_call):
        return board(shown, more, last, now, ext, state = state, notices = notes)
    if free:
        recent = recent_calls(now, k)
        if len(recent) >= FREE_DAILY:
            return board(shown, more, last, now, ext, state = state, cached = True, dim = True)

    # A stored answer only counts as something to show when it has every ticker this update would fetch, so a
    # chunk that never answered (or a list first fetched under the free rules) is fetched again, hourly off-hours.
    covered = last != None and not [s for c in fetch for s in c if type(last.get(s)) != "dict"]
    if state["show_indices"] and not free:
        covered = covered and indices_covered  # missing indices must also wake a paid list off-hours
    ttl, claims = schedule(now, k, lh, free, ext, covered)
    if ttl == None:
        if last != None:
            return board(shown, more, last, now, ext, state = state, cached = True, notices = notes)
        if free:  # this slot already spent (e.g. on the list before an edit)
            return board(shown, more, last, now, ext, state = state, cached = True)
        return board(shown, more, last, now, ext, state = state, cached = True, notices = notes) if state["show_indices"] else empty_root(state)

    # Claimed before the calls, so one that fails or times out (Pixlet aborts at 5 s; RapidAPI may still bill
    # the late 200) spends its slot instead of being retried on every render.
    undo = [(ck, cache.get(ck), t) for ck, _, t in claims]
    for ck, value, t in claims:
        cache.set(ck, value, ttl_seconds = t)
    if [ck for ck, value, _ in claims if cache.get(ck) != value]:
        # Pixlet's cache swallows write errors (a Redis at maxmemory refuses SETs but answers GETs). Without the
        # claim nothing would stop the next render calling again, so make no call at all.
        print("quotes: cache write failed, not calling")
        return board(shown, more, last, now, ext, state = state, cached = True, notices = notes) if last or state["show_indices"] else empty_root(state)

    todo, skipped = fetch, {}
    if last != None and [ck for ck, _, _ in claims if ck.startswith("cold:")]:
        skipped = {s: True for c in todo if not [s for s in c if type(last.get(s)) != "dict"] for s in c}
        todo = [c for c in todo if [s for s in c if type(last.get(s)) != "dict"]]  # off-hours: only what is missing

    # Mark unfetched prices old before the first call, then commit each returned chunk separately.
    # A later request/render timeout cannot lose quotes that have already arrived.
    merged = dict(last or {})
    old = {s: True for s in (merged.get("_old") or [])}
    for c in (chunks[:1] if free else chunks):
        for s in c:
            if num((merged.get(s) or {}).get("price")) != None:
                old[s] = True
    data, notices, fresh_any, paused = {}, [], False, False
    attempted, fresh_calls = {}, 0
    jobs = [("quotes", c) for c in todo]
    if index_call:
        at = 1 if jobs else 0  # learn the plan from quotes before spending an indices request
        jobs = jobs[:at] + [("indices", INDEX_SYMBOLS)] + jobs[at:]
    for i, (endpoint, c) in enumerate(jobs):
        if i >= MAX_REQUESTS_PER_RENDER or time.now().unix - started >= RENDER_BUDGET_SECONDS - REQUEST_TIMEOUT_SECONDS:
            break
        if i > 0 and is_free(lim):
            break  # a free plan's one request; a fresh first answer showing a paid plan carries on
        if endpoint == "quotes" and i > 0:
            # The first answer can reveal a status line or a plan notice. Recompute before
            # spending another request, so a short dwell never fetches extra unseen chunks.
            current_shown, current_notes = free_view(tokens, chunks, lim)
            current_data = {s: merged[s] for s, ok in window if ok and s in merged}
            capacity = min(capacity, page_layout(len(current_shown), current_data, now, ext, False, current_notes + notices, indices = state["show_indices"])[0])
            window = window[:capacity]
            allowed = {s: True for s, ok in window if ok}
            c = [s for s in c if s in allowed]
            if not c:
                break
        if endpoint == "indices":
            # Persist old markers before calling: failure or a later render timeout keeps last-good prices dim.
            state["indices"] = dict(state["indices"] or {})
            state["indices"]["_old"] = [s for s in INDEX_SYMBOLS if type(state["indices"].get(s)) == "dict"]
            cache.set(ik, json.encode(state["indices"]), ttl_seconds = LAST_GOOD_TTL)
        resp = http.get(
            api_url(config, endpoint),
            params = {"symbols": ",".join(c)},
            headers = {"X-RapidAPI-Key": key, "X-RapidAPI-Host": API_HOST},
            ttl_seconds = ttl,
        )
        if endpoint == "quotes":
            attempted.update({s: True for s in c})
        hdr = {name.lower(): value for name, value in resp.headers.items()}
        fresh = hdr.get("tidbyt-cache-status") != "HIT"  # a cached response replays old rate-limit headers
        if fresh:
            fresh_calls += 1
        text = resp.body()
        body = json.decode(text, None)  # error bodies may be HTML
        got = body.get("data") if type(body) == "dict" else None
        got = got if type(got) == "dict" else {}
        chunk_data = {s: got[s] for s in c if type(got.get(s)) == "dict"}
        error = (body.get("error") or body.get("message")) if type(body) == "dict" else None
        message = (error if type(error) == "string" else text).lower()
        quota_body = "quota" in message and any([word in message for word in ["exceeded", "exhausted", "used up", "depleted"]])
        if resp.status_code == 200 and (chunk_data or not quota_body):
            # Successful data wins over stale remaining counters and incidental quota wording.
            if endpoint == "indices":
                index_old = {s: True for s in state["indices"].get("_old", [])}
                merge_prices(state["indices"], chunk_data, index_old)
                cache.set(ik, json.encode(state["indices"]), ttl_seconds = LAST_GOOD_TTL)
            else:
                data.update(chunk_data)
                merge_prices(merged, chunk_data, old)
                cache.set("last:" + lh, json.encode(merged), ttl_seconds = LAST_GOOD_TTL)
            if fresh:
                fresh_any = True
                learned = to_int(hdr.get("x-ratelimit-requests-limit"), 0)
                lim = learned if learned > 0 else lim
                state["plan_limit"] = lim

                # Outlive a weekend; a missing header retains the known limit, or zero (unknown).
                cache.set("lim:" + k, str(lim), ttl_seconds = LAST_GOOD_TTL)
            continue

        # RapidAPI's requests-* headers describe the plan budget; the short headers can
        # describe a per-second burst. A positive plan budget contradicts quota exhaustion.
        remaining = to_int(hdr.get("x-ratelimit-requests-remaining"), None)
        short_remaining = to_int(hdr.get("x-ratelimit-remaining"), 1)
        short_reset = to_int(hdr.get("x-ratelimit-reset"), 0)
        burst = (
            "per-second" in message or "per second" in message or "requests/second" in message or
            (short_remaining <= 0 and 0 < short_reset and short_reset <= 60)
        )
        quota_error = not burst and (remaining <= 0 if remaining != None else quota_body)
        if resp.status_code == 429 or quota_body:
            if quota_error:
                learned = to_int(hdr.get("x-ratelimit-requests-limit"), 0)
                lim = learned if learned > 0 else lim
                lim = lim if lim > 0 else FREE_DAILY
                state["plan_limit"] = lim
                cache.set("lim:" + k, str(lim), ttl_seconds = LAST_GOOD_TTL)
                notices.append(pause_notice(lim, pause(k, now, hdr.get("x-ratelimit-requests-reset")), now, k))
                paused = True
            else:
                notices.append((["RATE LIMITED", "try again shortly"], EXT))
                if "\"message\"" in text and not fresh_any:
                    release(undo, now)  # RapidAPI burst errors are unbilled; origin errors retain claims
            break  # the remaining chunks would get the same answer
        if endpoint == "quotes" and resp.status_code in (401, 403) and "\"message\"" in text:
            if not data:
                release(undo, now)  # RapidAPI bills neither: the call right after subscribing must not wait a slot
                return notice_root(["KEY REJECTED", "Wrong key or", "not subscribed", URL_HINT], DOWN)  # not stored; HTTP cache replays it
            break
        print("%s: HTTP %d" % (endpoint, resp.status_code))  # the other chunks may still answer

    if not free and is_free(lim) and (fresh_any or paused):
        # BASIC may first be identified by indices or a later chunk. Count every fresh request
        # already spent on the paid/unknown path, or a sixth could fit in the rolling day.
        spent = [now.unix for _ in range(max(fresh_calls, 1))]
        cache.set("calls:" + k, ",".join([str(t) for t in recent_calls(now, k) + spent]), ttl_seconds = DAY)
        if free_slot(now) != None:
            cache.set("slot:" + k, free_slot(now), ttl_seconds = DAY)
    shown, notes = free_view(tokens, chunks, lim)  # the plan may have been learned just now

    # Stop the display window where fetching stopped (deadline, quota, or a rejected key).
    # Off-hours, already cached rows skipped by todo still belong to this window.
    end = len(window)
    for i, (s, ok) in enumerate(window):
        if ok and s not in attempted and s not in skipped:
            end = i
            break
    state["window_end"] = offset + end
    if is_free(lim):
        state["page_offset"] = 0
        state["window_end"] = min(len(shown), capacity)
    notices = notes + notices
    if not data:
        if last:
            return board(shown, more, last, now, ext, state = state, cached = True, dim = paused and is_free(lim), notices = notices, old = old)
        if paused:
            return board(shown, more, None, now, ext, state = state, notices = notices)
        return board(shown, more, merged, now, ext, state = state, notices = notices, old = old) if state["show_indices"] or notices else empty_root(state)

    priced = {s: e for s, e in data.items() if num(e.get("price")) != None}
    if fresh_any:
        secs, per_list = holiday(now, priced.values())
        if secs:
            cache.set("dormant:" + (lh if per_list else k), "1", ttl_seconds = secs)
    return board(shown, more, merged, now, ext, state = state, notices = notices, old = old)

# ------------------------------------------------------------------ input and clock

def merge_prices(merged, data, old):
    for s, e in data.items():
        if num(e.get("price")) != None:
            merged[s] = e
            old.pop(s, None)
        elif num((merged.get(s) or {}).get("price")) == None:
            merged[s] = e  # retain no-data answers, but never erase a last-good price
    merged["_old"] = sorted(old.keys())

def api_url(config, endpoint = "quotes"):
    """Public gateway, optional full quotes URL/API base, or a strict loopback test mock."""
    base = config.str("api_base", "")

    # LOOPBACK_RE already anchors the whole URL (^...$) and rejects userinfo/query.
    # Pixlet's re.match returns captured groups, not the full match, so do not
    # compare match[0] to base. Python's $ still matches before a final newline.
    if base and "\n" not in base and "\r" not in base and re.match(LOOPBACK_RE, base):
        return base + "/v1/" + endpoint
    url = config.str("api_url", "") or API_URL or "https://us-stock-etf-prices.p.rapidapi.com"
    base = url[:-len("/v1/quotes")] if url.endswith("/v1/quotes") else url.rstrip("/")
    return base + "/v1/" + endpoint

def now_et(config):
    fake = config.str("fake_now_et", "")  # tests only, e.g. 2026-11-02T10:15
    if fake:
        return time.parse_time(fake, format = "2006-01-02T15:04", location = ET)
    return time.now().in_location(ET)

def parse_symbols(raw):
    """([(symbol, valid)] in the user's order, deduplicated; how many were dropped past MAX_SYMBOLS).
    Invalid tokens are shown, never sent: one would fail the whole request."""
    tokens, seen = [], {}
    for t in raw.upper().replace(" ", ",").split(","):
        t = t.strip().lstrip("$").replace("-", ".")
        if t and t not in seen:
            seen[t] = True
            tokens.append((t, len(re.match(SYMBOL_RE, t)) > 0))
    return tokens[:MAX_SYMBOLS], max(len(tokens) - MAX_SYMBOLS, 0)

def decode_obj(s):
    v = json.decode(s, None) if s else None
    return v if type(v) == "dict" else None

def to_int(s, default):
    s = str(s).strip() if s != None else ""
    return int(s) if s.lstrip("-").isdigit() else default

def minutes(now):
    return now.hour * 60 + now.minute

def weekend(now):
    return now.format("Mon") in ("Sat", "Sun")

def next_at(now, h, m, weekdays = False):
    """The next h:m ET after now (Go's time.Date normalises day overflow and DST)."""
    for i in range(8):
        t = time.time(year = now.year, month = now.month, day = now.day + i, hour = h, minute = m, location = ET)
        if t.unix > now.unix and not (weekdays and weekend(t)):
            return t
    return now

# ------------------------------------------------------------------ when to call

def dwell_ms():
    """The device's dwell time: Tronbyt passes it as the encoder ceiling, and frames past it are cut."""
    ms = canvas.max_duration_ms()
    return ms if ms > 0 else 15000

def free_view(tokens, chunks, lim):
    """BASIC shows its first chunk. Successful responses never add an upgrade notice."""
    if not is_free(lim) or len(chunks) < 2:
        return tokens, []
    extra = {s: True for c in chunks[1:] for s in c}
    return [t for t in tokens if t[0] not in extra], []

def is_free(lim):
    return 0 < lim and lim < FREE_MAX

def recent_calls(now, k):
    """Unix times of this key's free-plan calls in the last 24 h. A rolling window, not a calendar day: when
    RapidAPI's daily quota resets is unknown (reportedly at the time of subscription)."""
    return [t for t in [to_int(x, 0) for x in (cache.get("calls:" + k) or "").split(",")] if t > now.unix - DAY]

def release(undo, now):
    """Hand back the claims of a call RapidAPI did not bill. From the call list only this call's entry is removed,
    so a call claimed meanwhile by another render on the same key stays counted."""
    for ck, old, t in undo:
        if ck.startswith("calls:"):
            ts = [x for x in (cache.get(ck) or "").split(",") if x]
            if str(now.unix) in ts:
                ts.remove(str(now.unix))  # one entry only: two renders in the same second each claimed one
            old = ",".join(ts)
        cache.set(ck, old or "", ttl_seconds = t)

def free_slot(now):
    """The latest free-plan slot at or before now today, as 'YYYY-MM-DD HH:MM', or None."""
    if weekend(now):
        return None
    done = [s for s in FREE_SLOTS if s[0] * 60 + s[1] <= minutes(now)]
    if not done:
        return None
    h, m = done[-1]
    return time.time(year = now.year, month = now.month, day = now.day, hour = h, minute = m, location = ET).format("2006-01-02 15:04")

def in_window(now, ext):
    if weekend(now):
        return False
    lo, hi = (4 * 60 + 15, 20 * 60 + 15) if ext else (9 * 60 + 50, 16 * 60 + 30)
    return lo <= minutes(now) and minutes(now) < hi

def schedule(now, k, lh, free, ext, covered):
    """(ttl, claims): the HTTP TTL for a call now, or None to show the last answer instead, and the cache markers
    (key, value, ttl) to set before calling.

    The ET clock and cache-module markers decide. The HTTP TTL only dedupes renders: Pixlet jitters it by ±10 %,
    so it must never schedule (an early expiry on a soft BASIC plan is a billed call). A free plan calls at most
    once per slot and once an hour off-slot per key, whatever the edits: Tronbyt's settings page re-renders the
    preview on every keystroke, and each new ticker list is a new request. A paid plan's off-hours call for a
    list with nothing to show yet is once an hour per list. covered: a stored answer with every ticker
    this update fetches (honours dormancy; otherwise a call fills it in).
    """
    if (cache.get("dormant:" + k) or cache.get("dormant:" + lh)) and covered:
        return None, []
    if free:
        count = ("calls:" + k, ",".join([str(t) for t in recent_calls(now, k) + [now.unix]]), DAY)
        slot = free_slot(now)
        if slot == None:
            if covered or cache.get("cold:" + k):
                return None, []
            return FREE_TTL, [("cold:" + k, "1", COLD_TTL), count]
        if cache.get("slot:" + k) == slot:
            return None, []
        return FREE_TTL, [("slot:" + k, slot, DAY), count]
    if in_window(now, ext):
        return PAID_TTL, []
    if covered or cache.get("cold:" + lh):
        return None, []
    return PAID_TTL, [("cold:" + lh, "1", COLD_TTL)]

def pause(k, now, reset):
    """Stop calling until the quota resets (X-Ratelimit-Requests-Reset seconds, else the next 09:50 ET); returns
    that time. The marker lives at most a day, so a user who upgrades is not locked out until a monthly reset;
    that costs one probe a day."""
    secs = to_int(reset, 0)
    if secs <= 0:
        secs = next_at(now, 9, 50, weekdays = True).unix - now.unix
    until = now.unix + secs
    cache.set("pause:" + k, str(until), ttl_seconds = min(max(secs, 60), DAY))
    return until

def holiday(now, priced):
    """(seconds to go dormant, per ticker list?), or (0, False). Until 04:00 ET when every priced entry is 'closed' on a weekday between 04:15
    and 20:00 (a market holiday); an hour when after 10:30 ET there is still nothing for today's session (the
    origin's clock fallback can miss a holiday, but stored previous-session rows can look the same on a normal
    day, so only briefly and per list). Stale entries do not count: a feed outage is not a holiday."""
    live = [e for e in priced if not is_stale(e)]
    if weekend(now) or not live:
        return 0, False
    m = minutes(now)
    if 4 * 60 + 15 <= m and m < 20 * 60 and all([e.get("market_status") == "closed" for e in live]):
        return next_at(now, 4, 0).unix - now.unix, False
    today = now.format("2006-01-02")
    if m >= 10 * 60 + 30 and all([str(e.get("session_date")) < today for e in live]):
        return 3600, True  # depends on which tickers are listed, so per list
    return 0, False

# ------------------------------------------------------------------ notices

def pause_notice(lim, until, now, k):
    if lim < FREE_MAX:
        used = "FREE: %d/DAY USED" % lim if lim > 0 else "FREE LIMIT USED"
        return [used, "NEXT " + next_free_call(until, k).format("Mon 15:04").upper(), "PRO: ALL DAY", UPGRADE_URL], EXT
    left = max(until - now.unix, 0) // 60
    d, h, m = left // 1440, left % 1440 // 60, left % 60
    dur, short = ("%dD %dH" % (d, h), "%dD" % d) if d else (("%dH %dM" % (h, m), "%dH" % h) if h else ("%dM" % m, ""))
    dur = dur if len(dur) <= 6 else short  # "RESETS IN " leaves 6 of the line's 16 characters
    return ["QUOTA USED UP", "RESETS IN " + dur, UPGRADE_URL], EXT

def next_free_call(until, k):
    """When a free plan next calls once blocked until `until`: right then if the slot open at that moment is
    unspent, else at the next slot."""
    t = time.from_timestamp(until).in_location(ET)
    slot = free_slot(t)
    if slot != None and cache.get("slot:" + k) != slot:
        return t
    return free_slot_after(t)

def free_slot_after(now):
    """The next free-plan slot after now."""
    for i in range(8):
        day = time.time(year = now.year, month = now.month, day = now.day + i, location = ET)
        for h, m in FREE_SLOTS:
            t = time.time(year = day.year, month = day.month, day = day.day, hour = h, minute = m, location = ET)
            if t.unix > now.unix and not weekend(t):
                return t
    return now

def upgrade_link():
    # Marquee.delay is a start hold in frames, not milliseconds; Root.delay is the tick (1px/frame).
    return render.Marquee(
        width = 64,
        scroll_direction = "horizontal",
        offset_start = 0,
        offset_end = 64,  # scroll the last character fully out before looping
        child = render.Text(UPGRADE_URL, font = FONT, color = TEXT),
    )

def notice_page(lines, color):
    return render.Column(children = [
        upgrade_link() if line == UPGRADE_URL else render.Text(line, font = FONT, color = color if i == 0 else TEXT)
        for i, line in enumerate(lines)
    ])

def notice_root(lines, color):
    child = notice_page(lines, color)
    if UPGRADE_URL in lines:
        return render.Root(delay = UPGRADE_FRAME_MS, child = child)
    return render.Root(child = child)

def empty_root(state):
    # Keep failures visible during an active session; skip only an empty, closed market.
    return [] if state.get("market_closed", False) else notice_root(["SERVICE DOWN", "try later"], FLAT)

# ------------------------------------------------------------------ board

def num(v):
    """A JSON number as a float, else None: the API is ours, but a stray string must not crash the render."""
    return float(v) if type(v) in ("int", "float") else None

def is_stale(e):
    return e.get("is_stale") or e.get("quote_status") == "stale"

def view(e, ext, today):
    """(price, pct, kind, extended): what one row shows. kind is 'live', 'pm', 'ah', 'closed' or 'stale'.

    % is vs the previous session's close. session_date is trusted over market_status: the regular session
    (and its 16:00-16:20 delayed tail) is session_date == today with a running quote. Pre-market the reference
    is the last close (`price`), so a ticker with no trade yet shows no %; after hours it is previous_close, so
    the % includes the after-hours move. With extended hours off, those phases show the last session's result.
    """
    price, pct = num(e.get("price")), num(e.get("change_percentage"))
    if is_stale(e):
        return price, None, "stale", False
    if e.get("session_date") == today and e.get("quote_status") in ("delayed", "live"):
        return price, pct, "live", False
    ms, xp, prev = e.get("market_status"), num(e.get("extended_price")), num(e.get("previous_close"))
    if ext and ms == "early_hours":
        if xp != None:
            return xp, num(e.get("extended_change_percentage")), "pm", True
        return price, None, "pm", False
    if ext and ms == "after_hours":
        if xp != None and prev and pct != None:
            return xp, (xp - prev) / prev * 100, "ah", True
        return price, pct, "ah", False
    return price, pct, "closed", False

def fmt_price(p):
    """Whole dollars (owner's call: frees width); cents under $10, tenths of a cent under $1; 746k from $100,000."""
    if p >= 100000:
        return humanize.float("#.", p / 1000) + "k"
    if p >= 10:
        return humanize.float("#.", p)
    if p >= 1:
        return humanize.float("#.##", p)
    return humanize.float("#.###", p)

def fmt_pct(c):
    """(text, color): signed, so colour is not the only cue; one decimal under 100 %, which keeps a gap after a
    5-digit price on 64 px (two decimals would touch it)."""
    a = abs(c)
    s = humanize.float("#.#" if a < 100 else "#.", a)
    if s == "0.0":
        return "0.0%", FLAT
    return ("+" if c > 0 else "-") + s + "%", (UP if c > 0 else DOWN)

def fmt_change(c):
    """Signed index points in the 20px cell, including moves smaller than a tenth."""
    if c == None:
        return "--", FLAT
    if c == 0:
        return "0.0", FLAT
    a = abs(c)
    s = humanize.float("#." if a >= 10 else "#.#", a)
    if s in ("0", "0.0"):
        s = "<0.1"
    return ("+" if c > 0 else "-") + s, (UP if c > 0 else DOWN)

def cell(text, width, color, align = "end"):
    return render.Box(
        width = width,
        height = 6,
        child = render.Row(expanded = True, main_align = align, children = [render.Text(text, font = FONT, color = color)]),
    )

def note_row(sym, text):
    return render.Row(children = [cell(sym[:5], 20, FLAT, "start"), cell(text, 44, FLAT)])

def quote_row(sym, v, dim):
    price, pct, _, extended = v
    pct_text, pct_color = fmt_pct(pct) if pct != None else ("--", FLAT)
    return render.Row(children = [
        cell(sym, 20, SYM, "start"),
        cell(fmt_price(price), 20, DIM if dim else (EXT if extended else TEXT)),
        cell(pct_text, 24, DIM if dim else pct_color),
    ])

def hhmm(iso):
    ok = type(iso) == "string" and re.match(ISO_RE, iso)
    return time.parse_time(iso).in_location(ET).format("15:04") if ok else ""

def status_line(rows, cached):
    """None in the regular session with fresh prices (5 rows fit); else which prices these are, and when."""
    kinds = [v[2] for e, v in rows]
    if not kinds or (not cached and all([k == "live" for k in kinds])):
        return None
    if all([k == "stale" for k in kinds]):
        label, color, kind = "STALE", STALE, "stale"
    elif "pm" in kinds:
        label, color, kind = "PRE-MKT", EXT, "pm"
    elif "ah" in kinds:
        label, color, kind = "AFTER HRS", EXT, "ah"
    elif "live" in kinds:
        label, color, kind = "AS OF", FLAT, "live"
    else:
        return None  # closed-session prices need no header; leave that row for prices

    # the time of a row of the labelled kind, an extended trade first (a ticker with no pre-market trade must not
    # put 16:00 next to PRE-MKT)
    match = [r for r in rows if r[1][2] == kind]
    e, v = ([r for r in match if r[1][3]] + match + rows)[0]
    when = hhmm(e.get("extended_as_of") if v[3] else e.get("as_of"))
    return render.Row(
        expanded = True,
        main_align = "space_between",
        children = [render.Text(label, font = FONT, color = color), render.Text(when, font = FONT, color = FLAT)],
    )

def page_layout(_total, data, now, ext, cached, notices, reserve_status = False, indices = False):
    """Capacity and shared board geometry; useful status and notice lines consume rows."""
    priced = [
        (e, view(e, ext, now.format("2006-01-02")))
        for s, e in (data or {}).items()
        if type(e) == "dict" and num(e.get("price")) != None
    ]
    status = status_line(priced, cached)
    n = 4 if status or reserve_status else 5
    static_ms = dwell_ms() - (1500 if indices else 0)
    scroll_ms = notice_scroll_ms(notices)
    budget = max(static_ms // 1500, 1)
    inline = []
    if notices and (budget == 1 or static_ms - scroll_ms < 1500):
        inline = [render.Text(lines[0], font = FONT, color = color) for lines, color in notices[:2] if lines]
        notices = []
        n -= len(inline)
    elif len(notices) > budget - 1:
        notices = [([line for lines, _ in notices for line in lines[:2]], notices[-1][1])]

    # A marquee supplies many frames with its own delay. Reserve its entire pass before
    # sizing static pages, rather than counting it as one Root-delay frame.
    scroll_ms = notice_scroll_ms(notices)
    static_notices = len([lines for lines, _ in notices if UPGRADE_URL not in lines])
    budget = max((static_ms - scroll_ms) // 1500, 1)
    return max(budget - static_notices, 1) * n, n, status, inline, notices

def notice_scroll_ms(notices):
    return UPGRADE_SCROLL_MS * len([lines for lines, _ in notices if UPGRADE_URL in lines])

def board(tokens, more, data, now, ext, cached = False, dim = False, notices = [], old = None, state = None):
    """Quote pages, then notices. During active sessions leave no-data rows if needed.
    The offset counts rows, so changes in page size cannot skip tickers."""
    if state and state.get("market_closed", False) and not notices:
        have_quotes = any([ok and type((data or {}).get(s)) == "dict" and num(data[s].get("price")) != None for s, ok in tokens])
        indices = (state.get("indices") or {}) if state.get("show_indices", False) else {}
        have_indices = any([type(indices.get(s)) == "dict" and any([num(indices[s].get(field)) != None for field in ("price", "change", "change_percentage")]) for s in INDEX_SYMBOLS])
        if not have_quotes and not have_indices:
            return []
    if old == None:
        old = {s: True for s in ((data or {}).get("_old") or [])}
    today = now.format("2006-01-02")
    offset = state["page_offset"] % len(tokens) if state and tokens else 0
    end = state.get("window_end", len(tokens)) if state else len(tokens)
    window = tokens[offset:end]
    rows = []
    for sym, ok in window:
        e = (data or {}).get(sym) if ok else None
        if not ok:
            rows.append(note_row(sym, "invalid"))
        elif type(e) != "dict" or num(e.get("price")) == None:
            rows.append(note_row(sym, "no data"))
        else:
            v = view(e, ext, today)
            rows.append(quote_row(sym, v, dim or v[2] == "stale" or sym in old))

    window_data = {s: data[s] for s, ok in window if ok and data and s in data}
    indices = state != None and state.get("show_indices", False)
    capacity, n, status, inline, notices = page_layout(len(tokens), window_data, now, ext, cached, notices, indices = indices)
    top = []
    if status:
        top = [status, render.Box(width = 64, height = 1, color = "#222")]

    # Tight dwells inline only essential status; a full URL pass gets a dedicated page
    # only when it leaves enough time for indices and at least one ticker page.
    slot_ms = dwell_ms()
    if more and end >= len(tokens):
        rows.append(note_row("+%d" % more, "more"))  # only input beyond MAX_SYMBOLS

    selected = rows[:capacity]
    pages = [indices_page(state.get("indices"))] if indices else []
    for i in range(0, len(selected), n):
        pages.append(render.Padding(
            pad = (0, 1 if not status else 0, 0, 0),
            child = render.Column(children = top + selected[i:i + n] + inline),
        ))
    if selected and state:
        state["page_offset"] = 0 if is_free(state["plan_limit"]) else (offset + min(len(selected), len(window))) % len(tokens)
        cache.set(state["page_key"], str(state["page_offset"]), ttl_seconds = LAST_GOOD_TTL)
    pages += [notice_page(lines, color) for lines, color in notices]
    if not pages:
        return notice_root(["SERVICE DOWN", "try later"], FLAT)
    scroll_ms = notice_scroll_ms(notices)
    if len(pages) == 1:
        if scroll_ms:
            return render.Root(delay = UPGRADE_FRAME_MS, child = pages[0])
        return render.Root(child = pages[0])

    # Below 3 s, share the dwell between indices and one ticker page so neither is truncated.
    minimum = min(1500, slot_ms // 2) if indices else 1500
    notice_n = scroll_ms // UPGRADE_SCROLL_MS
    static_n = len(pages) - notice_n
    hold_ms = min(max((slot_ms - scroll_ms) // max(static_n, 1), minimum), 5000)

    # Animation snapshots each child once, so a nested Marquee would not scroll.
    # Sequence plays each child's frames in order; static pages are held by repetition.
    if notice_n:
        hold = max(hold_ms // UPGRADE_FRAME_MS, 1)
        children = [render.Animation(children = [page] * hold) for page in pages[:static_n]] + pages[static_n:]
        return render.Root(delay = UPGRADE_FRAME_MS, child = render.Sequence(children = children))
    return render.Root(delay = hold_ms, child = render.Animation(children = pages))

def index_view(e):
    # Indices have no quote session fields; their stale flag alone controls dimming.
    return num(e.get("price")), num(e.get("change_percentage")), ("stale" if is_stale(e) else "live"), False

def index_row(label, e, dim):
    change = num(e.get("change"))
    if change == None:
        price, previous = num(e.get("price")), num(e.get("previous_close"))
        change = price - previous if price != None and previous != None else None
    change_text, change_color = fmt_change(change)
    pct = num(e.get("change_percentage"))
    pct_text, pct_color = fmt_pct(pct) if pct != None else ("--", FLAT)
    return render.Row(children = [
        cell(label, 20, SYM, "start"),
        cell(change_text, 20, DIM if dim else change_color),
        cell(pct_text, 24, DIM if dim else pct_color),
    ])

def indices_page(data):
    rows = []
    old = (data or {}).get("_old") or []
    for s in INDEX_SYMBOLS:
        label = INDEX_LABELS.get(s, s)
        e = (data or {}).get(s)
        if type(e) != "dict" or not any([num(e.get(field)) != None for field in ("price", "change", "change_percentage")]):
            rows.append(note_row(label, "no data"))
        else:
            v = index_view(e)
            rows.append(index_row(label, e, v[2] == "stale" or s in old))
    return render.Padding(pad = (0, 1, 0, 0), child = render.Column(children = rows))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "rapidapi_key",
                name = "RapidAPI key",
                desc = "Your key for US Stock & ETF Prices on RapidAPI. Free BASIC works for the first 5 tickers with infrequent updates. Paid plans support more tickers or more frequent updates.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "symbols",
                name = "Tickers",
                desc = "Comma-separated, up to 100, e.g. SPY,AAPL,BRK.B. Up to 20 tickers per update with indices, 25 without; longer lists rotate. Free BASIC: first 5 only.",
                icon = "chartLine",
                default = DEFAULT_SYMBOLS,
            ),
            schema.Toggle(
                id = "show_indices",
                name = "Market indices",
                desc = "Page one shows DOW, S&P, NDX, RUT and VIX; ticker prices start on the next pages. Turn off to show tickers only. Free BASIC uses cached indices only.",
                icon = "chartLine",
                default = True,
            ),
            schema.Toggle(
                id = "extended",
                name = "Pre-market & after hours",
                desc = "Also update 4:15-9:30 and 16:00-20:15 ET with pre-market and after-hours prices (paid plans).",
                icon = "moon",
                default = False,
            ),
        ],
    )
