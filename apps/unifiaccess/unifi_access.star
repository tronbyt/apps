"""
Applet: UniFi Access
Summary: Doors and entry log
Description: Shows the most recent UniFi Access door opening - who badged in, which door, and how long ago - above a lock board that colours every door green for locked and amber for unlocked. A refused badge turns the whole entry red. When nothing has been opened it lists the doors instead. Access has no cloud API, so the display reads your Access API server directly on port 12445, which means it has to resolve that server's hostname and trust the certificate that server presents. Your console's remote-access hostname will not do - that certificate covers port 443 only, and nothing answers on 12445 with it. Give the Access API server a certificate of its own, or front it with a reverse proxy that already has one.
Author: nsluke
"""

load("encoding/json.star", "json")
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
RULE = "#1D2733"

# The Access API listens on its own port with its own certificate.
DEFAULT_PORT = "12445"
DOORS_TTL = 30
LOGS_TTL = 30

# Anything larger than this is milliseconds, not seconds (1e11s is year 5138).
MILLIS_CUTOFF = 100000000000

# Below this many doors the band draws one bar per door and they stay wide
# enough to count; above it the bars would be 2-3px on a diffused panel, so we
# print the tally in words instead.
MAX_BARS = 8

# Text lines the board has room for under the header.
MAX_BOARD_ROWS = 4

# Characters the header's right slot can hold beside the app tag. Measured
# rather than guessed, and the same number at both scales: 1x leaves 62px after
# the padding, of which the tag advances 24 at 4px a character, and 2x leaves
# 124 of which the tag advances 48 at 8. A tenth character lands on the tag in
# both. Past this the Row stops right-aligning and spills off the panel edge,
# cutting the value mid-word.
HEADER_RIGHT_MAX = 9

# At or below this many doors the board spells the lock state out per door
# rather than leaning on a colour chip alone.
BOARD_WORD_MAX = 2

# Characters a host cannot contain. Each one either makes the URL unparsable
# (a space from a sloppy paste is the common one), silently reinterprets the
# rest of the address as a path, userinfo or query, or is a byte no resolver
# will ever answer for. All three abort the render before a card can be drawn,
# so the address is refused here instead. Non-ASCII is deliberately absent:
# Go punycodes an accented hostname and resolves it (verified), so an IDN
# address is not ours to refuse.
HOST_BAD_CHARS = " \t\n\r\"'`<>\\^{}|#%?@[]()&$!*+,;="

# Everything an IPv6 literal is made of: hex digits, the colons between them,
# and the dots of an IPv4-mapped tail like ::ffff:192.168.1.1.
HOST_V6_CHARS = "0123456789abcdefABCDEF:."

# Second line of the error card, keyed by its headline. Each one is short
# enough to sit inside the panel margins rather than scrolling.
PROBLEM_DETAIL = {
    "BAD API KEY": "check the token",
    "KEY LACKS ACCESS": "add view perms",
    "NOT FOUND": "check the port",
    "BAD RESPONSE": "wrong endpoint",
    "API ERROR": "server refused",
}

def ipv6_host(scheme, h):
    """Classifies an address that is shaped like an IPv6 literal.

    A bare literal is bracketed here, because without brackets it is not a URL
    host at all and http.get aborts the render on the string that results. What
    sits inside the brackets is then checked, loosely: a mistyped literal - a
    stray bracket, a trailing colon, a third colon run - aborts exactly as hard
    as a bare one, and that abort is the one thing the http:// escape hatch
    cannot rescue, so a typo has to be told apart from an address here.

    Returns:
      The same (scheme, host, problem) tuple clean_host returns. "ip" means a
      well-formed literal, which no publicly valid certificate will cover;
      "chars" means it is not an address at all.
    """
    literal = h
    port = ""
    if h.startswith("["):
        close = h.find("]")
        if close < 0:
            return (scheme, h, "chars")
        literal = h[1:close]
        port = h[close + 1:]
        if port != "" and (not port.startswith(":") or not port[1:].isdigit()):
            return (scheme, h, "chars")

    if literal == "":
        return (scheme, h, "chars")
    for i in range(len(literal)):
        if not literal[i] in HOST_V6_CHARS:
            return (scheme, h, "chars")

    # One run of omitted groups, and no group left hanging off either end.
    if literal.find(":::") >= 0:
        return (scheme, h, "chars")
    if literal.endswith(":") and not literal.endswith("::"):
        return (scheme, h, "chars")
    if literal.startswith(":") and not literal.startswith("::"):
        return (scheme, h, "chars")

    return (scheme, "[" + literal + "]" + port, "ip")

def clean_host(raw):
    """Normalizes a user-entered console address.

    Args:
      raw: the raw config string, possibly None.

    Returns:
      A (scheme, host, problem) tuple. problem is one of None, "empty", "ip",
      "mdns" or "chars". An address literal or a .local name can never present
      a publicly valid certificate, so we flag them rather than letting the TLS
      failure abort the render. An explicit http:// is honoured, because
      fronting the Access API with a plain-HTTP reverse proxy on the LAN is a
      legitimate - and here quite common - way to solve the certificate
      problem, so the returned host stays usable even when a problem is
      reported alongside it.
    """
    h = (raw or "").strip()
    scheme = "https://"
    low = h.lower()
    if low.startswith("http://"):
        scheme = "http://"
        h = h[7:]
    elif low.startswith("https://"):
        h = h[8:]

    h = h.split("/")[0].strip()
    if h == "":
        return (scheme, "", "empty")

    # IPv6 literals, both spellings. More than one colon is the tell: a
    # hostname takes at most one, for its port, and a bare IPv6 address cannot
    # carry a port anyway.
    if h.startswith("[") or h.count(":") > 1:
        return ipv6_host(scheme, h)

    for i in range(len(h)):
        if h[i] in HOST_BAD_CHARS:
            return (scheme, h, "chars")

    hostname = h.split(":")[0]
    parts = hostname.split(".")
    if len(parts) == 4:
        numeric = True
        for p in parts:
            if not p.isdigit():
                numeric = False
        if numeric:
            return (scheme, h, "ip")

    if hostname.lower().endswith(".local"):
        return (scheme, h, "mdns")

    return (scheme, h, None)

def with_port(host):
    """Appends the Access API port when the user did not supply one.

    A bracketed IPv6 host is nothing but colons, so the port has to be looked
    for after the closing bracket rather than anywhere in the string. Missing
    that sends the request to 443 - the console's web UI - instead of the
    Access API on 12445.
    """
    has_port = ":" in host
    if host.startswith("["):
        has_port = "]:" in host
    if has_port:
        return host
    return host + ":" + DEFAULT_PORT

def unwrap(resp):
    """Validates the {code, msg, data} envelope every Access endpoint returns.

    The body is parsed with json.decode's default argument rather than
    resp.json(), because resp.json() raises on a malformed body and a raised
    error aborts the render uncatchably. A reverse proxy in front of the
    Access API can absolutely answer 200 with an HTML error page - or a
    truncated body - while still labelling it application/json, so the
    Content-Type header is not a safe gate.

    Returns:
      A (data, problem) tuple. problem is None on success, otherwise a short
      uppercase reason suitable for an error card.
    """
    code = resp.status_code
    if code == 401:
        return (None, "BAD API KEY")
    if code == 403:
        return (None, "KEY LACKS ACCESS")
    if code == 404:
        return (None, "NOT FOUND")
    if code != 200:
        return (None, "HTTP %d" % code)

    body = json.decode(resp.body(), None)
    if type(body) != "dict":
        return (None, "BAD RESPONSE")
    if body.get("code", "") != "SUCCESS":
        return (None, "API ERROR")
    return (body.get("data", None), None)

def fetch_doors(base, headers):
    resp = http.get(base + "/doors", headers = headers, ttl_seconds = DOORS_TTL)
    data, problem = unwrap(resp)
    if problem != None:
        return ([], problem)

    # Ubiquiti serialises an empty collection as null often enough that a
    # missing list has to mean "no doors", not "wrong endpoint".
    if data == None:
        return ([], None)
    if type(data) != "list":
        return ([], "BAD RESPONSE")

    doors = []
    for d in data:
        if type(d) == "dict":
            doors.append(d)
    return (doors, None)

def fetch_last_entry(base, headers):
    """Fetches the newest door_openings log entry, or None."""
    resp = http.post(
        base + "/system/logs",
        headers = headers,
        params = {"page_num": "1", "page_size": "5"},
        json_body = {"topic": "door_openings"},
        ttl_seconds = LOGS_TTL,
    )
    data, problem = unwrap(resp)
    if problem != None:
        return (None, problem)
    if type(data) != "dict":
        return (None, None)

    hits = data.get("hits", None)
    if type(hits) != "list" or len(hits) == 0:
        return (None, None)

    first = hits[0]
    if type(first) != "dict":
        return (None, None)
    source = first.get("_source", None)
    if type(source) != "dict":
        return (None, None)
    return (source, None)

def text_or_empty(value):
    """Returns a trimmed string, treating None and the API's "N/A" as empty."""
    if type(value) != "string":
        return ""
    trimmed = value.strip()
    if trimmed.upper() == "N/A":
        return ""
    return trimmed

def target_name(source, want_type):
    """Pulls a display name out of the log entry's target list."""
    targets = source.get("target", None)
    if type(targets) != "list":
        return ""
    for t in targets:
        if type(t) != "dict":
            continue
        if t.get("type", "") == want_type:
            name = text_or_empty(t.get("display_name", ""))
            if name != "":
                return name
    return ""

def relative_time(published, now_unix):
    """Formats an epoch (seconds or milliseconds) as a 1-3 character age."""
    if type(published) not in ["int", "float"]:
        return ""
    stamp = int(published)
    if stamp > MILLIS_CUTOFF:
        stamp = stamp // 1000
    if stamp <= 0:
        return ""

    age = now_unix - stamp
    if age < 0:
        age = 0
    if age < 60:
        return "now"
    if age < 3600:
        return "%dm" % (age // 60)
    if age < 86400:
        return "%dh" % (age // 3600)
    if age < 86400 * 365:
        return "%dd" % (age // 86400)
    return "%dy" % (age // (86400 * 365))

def denied(result):
    """A result that is neither "ACCESS" nor missing means someone was refused."""
    return result != "ACCESS" and result != ""

def result_color(result):
    if result == "ACCESS":
        return GREEN
    if result == "":
        return DIM
    return RED

def lock_word(status):
    if status == "lock":
        return "LOCKED"
    if status == "unlock":
        return "UNLOCKED"
    return "UNKNOWN"

def door_color(door):
    status = door.get("door_lock_relay_status", "")
    if status == "lock":
        return GREEN
    if status == "unlock":
        return AMBER
    return DIM

def door_label(door, index):
    name = text_or_empty(door.get("name", ""))
    if name != "":
        return name
    name = text_or_empty(door.get("full_name", ""))
    if name != "":
        return name
    return "Door %d" % (index + 1)

def door_count_label(count):
    if count == 1:
        return "1 DOOR"
    return "%d DOORS" % count

def style():
    """Returns the pixel geometry and fonts for the current canvas.

    The small font is tom-thumb rather than CG-pixel-3x5-mono: both advance
    4px per character, but CG-pixel silently drops every non-ASCII glyph, and
    door names and cardholder names are exactly where accented characters turn
    up. "line" and "big" are the line heights of the two fonts, and
    "title_max" is the longest headline the big font fits across the panel.
    """
    width, height = canvas.size()
    if canvas.is2x():
        return {
            "s": 2,
            "w": width,
            "h": height,
            "tiny": "6x10",
            "line": 10,
            "body": "terminus-16",
            "big": 16,
            "title_max": 14,
            "delay": 30,
        }
    return {
        "s": 1,
        "w": width,
        "h": height,
        "tiny": "tom-thumb",
        "line": 6,
        "body": "tb-8",
        "big": 8,
        "title_max": 12,
        "delay": 60,
    }

def header(st, right_text, right_color):
    """The app tag plus a short right-aligned value.

    A value too long to sit beside the tag takes the whole line and the tag
    stands down. The Row would otherwise lay the two out left to right and run
    the value off the panel, and the values long enough to do that are the ones
    reporting an unlocked door - the one thing on this panel that must never be
    cut off mid-word. The app is still named on every card and on the entry
    view; a door nobody locked is the more urgent use of the line.
    """
    s = st["s"]
    children = [
        render.Text("ACCESS", font = st["tiny"], color = BLUE),
        render.Text(right_text, font = st["tiny"], color = right_color),
    ]
    if len(right_text) > HEADER_RIGHT_MAX:
        children = [render.Text(right_text, font = st["tiny"], color = right_color)]
    return render.Padding(
        pad = (s, 0, s, 0),
        child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = children,
        ),
    )

def rule(st, color):
    return render.Box(width = st["w"], height = 2 * st["s"], color = color)

def scroller(st, width, content, font, color):
    return render.Marquee(
        width = width,
        delay = st["delay"],
        child = render.Text(content, font = font, color = color),
    )

def card(st, title, title_color, detail):
    """The setup / error card shared by every failure path.

    A headline only drops to the small font when it physically cannot fit the
    panel in the big one, so the size change reads as a consequence of the
    words rather than a decision.
    """
    s = st["s"]
    title_font = st["body"]
    if len(title) > st["title_max"]:
        title_font = st["tiny"]
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text("UNIFI ACCESS", font = st["tiny"], color = BLUE),
                render.Box(width = st["w"], height = 2 * s),
                render.Box(width = 24 * s, height = s, color = title_color),
                render.Box(width = st["w"], height = 2 * s),
                render.Marquee(
                    width = st["w"],
                    align = "center",
                    delay = st["delay"],
                    child = render.Text(title, font = title_font, color = title_color),
                ),
                render.Box(width = st["w"], height = s),
                render.Marquee(
                    width = st["w"],
                    align = "center",
                    delay = st["delay"],
                    child = render.Text(detail, font = st["tiny"], color = DIM),
                ),
            ],
        ),
    )

def lock_tally(doors):
    """Counts lock states and returns a (sentence, colour) summary."""
    total = len(doors)
    locked = 0
    unlocked = 0
    for door in doors:
        status = door.get("door_lock_relay_status", "")
        if status == "lock":
            locked += 1
        elif status == "unlock":
            unlocked += 1
    if unlocked > 0:
        return ("%d/%d UNLOCKED" % (unlocked, total), AMBER)
    if locked == total:
        return ("%d LOCKED" % total, GREEN)
    return (door_count_label(total), DIM)

def lock_band(st, doors):
    """The bottom strip: the lock state of every door.

    One bar per door while the bars stay countable. A single door gets its
    state spelled out, because one lonely rectangle says nothing on its own,
    and so does a site with more doors than the panel can draw bars for.
    """
    s = st["s"]
    gap = s
    children = []

    if len(doors) == 1:
        door = doors[0]
        color = door_color(door)
        children = [
            render.Box(width = 10 * s, height = 6 * s, color = color),
            render.Padding(
                pad = (3 * s, 0, 0, 0),
                child = render.Text(
                    lock_word(door.get("door_lock_relay_status", "")),
                    font = st["tiny"],
                    color = color,
                ),
            ),
        ]
    elif len(doors) > MAX_BARS:
        sentence, color = lock_tally(doors)
        children = [
            render.Marquee(
                width = st["w"] - 2 * s,
                align = "center",
                delay = st["delay"],
                child = render.Text(sentence, font = st["tiny"], color = color),
            ),
        ]
    else:
        avail = st["w"] - 2 * s
        bar_w = (avail - gap * (len(doors) - 1)) // len(doors)
        if bar_w > 16 * s:
            bar_w = 16 * s
        if bar_w < 2 * s:
            bar_w = 2 * s

        for index, door in enumerate(doors):
            right = gap
            if index == len(doors) - 1:
                right = 0
            children.append(
                render.Padding(
                    pad = (0, 0, right, 0),
                    child = render.Box(width = bar_w, height = 6 * s, color = door_color(door)),
                ),
            )

    return render.Padding(
        pad = (s, s, s, 2 * s),
        child = render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = children,
        ),
    )

def entry_view(st, source, doors, now_unix):
    """Latest entry on top, door lock board along the bottom."""
    s = st["s"]
    event = source.get("event", {})
    if type(event) != "dict":
        event = {}
    actor = source.get("actor", {})
    if type(actor) != "dict":
        actor = {}

    result = ""
    raw_result = event.get("result", "")
    if type(raw_result) == "string":
        result = raw_result.strip().upper()

    who = text_or_empty(actor.get("display_name", ""))
    message = text_or_empty(event.get("display_message", ""))
    if who == "":
        who = message
    if who == "":
        who = "Unknown"

    # Fall through door -> reader device -> message -> credential, never
    # repeating whatever already landed on the name line.
    where = target_name(source, "door")
    if where == "":
        where = target_name(source, "UAH")
    if where == "" and message != who:
        where = message
    if where == "":
        auth = source.get("authentication", {})
        if type(auth) == "dict":
            where = text_or_empty(auth.get("credential_provider", ""))
    if where == "":
        where = "Door opened"

    age = relative_time(event.get("published", 0), now_unix)

    # A refused badge is the loudest thing this app can report, so it takes
    # the name, the rule and the door line rather than a 1px hairline.
    name_color = WHITE
    where_color = DIM
    if denied(result):
        name_color = RED
        where_color = RED

    # Both lines live in ONE marquee. Independent marquees of different
    # content lengths drift out of phase and their blank gaps eventually line
    # up, which empties the whole information area for several frames.
    body = render.Padding(
        pad = (s, s, s, 0),
        child = render.Marquee(
            width = st["w"] - 2 * s,
            delay = st["delay"],
            child = render.Column(
                children = [
                    render.Text(who, font = st["body"], color = name_color),
                    render.Text(where, font = st["tiny"], color = where_color),
                ],
            ),
        ),
    )

    children = [
        header(st, age, WHITE),
        rule(st, result_color(result)),
        body,
    ]
    if len(doors) > 0:
        children.append(lock_band(st, doors))
    else:
        children.append(
            render.Padding(
                pad = (s, 3 * s, s, 0),
                child = render.Row(
                    expanded = True,
                    main_align = "center",
                    children = [render.Text("NO DOORS", font = st["tiny"], color = DIM)],
                ),
            ),
        )

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_between",
            children = children,
        ),
    )

def door_block(st, door, index):
    """A door name with its lock state spelled out underneath."""
    s = st["s"]
    color = door_color(door)
    return render.Column(
        children = [
            scroller(st, st["w"] - 2 * s, door_label(door, index), st["tiny"], WHITE),
            render.Row(
                cross_align = "center",
                children = [
                    render.Box(width = 4 * s, height = 4 * s, color = color),
                    render.Padding(
                        pad = (2 * s, 0, 0, 0),
                        child = render.Text(
                            lock_word(door.get("door_lock_relay_status", "")),
                            font = st["tiny"],
                            color = color,
                        ),
                    ),
                ],
            ),
        ],
    )

def spread(blocks, block_h, avail):
    """Distributes fixed-height blocks down the space the board actually has.

    A top-anchored board leaves a one-door site as twelve lit rows above
    twenty black ones, so the slack is spread between the blocks instead.
    """
    count = len(blocks)
    slack = avail - count * block_h
    if slack < 0:
        slack = 0
    gap = 0
    if count > 1:
        gap = slack // (count - 1)
    lead = (slack - gap * (count - 1)) // 2

    children = []
    if lead > 0:
        children.append(render.Box(width = 1, height = lead))
    for index, block in enumerate(blocks):
        children.append(block)
        if gap > 0 and index < count - 1:
            children.append(render.Box(width = 1, height = gap))
    return children

def door_row(st, door, index):
    """A door name behind a lock-coloured chip, one panel line tall.

    Only a name too long for the line scrolls; the marquee is a no-op for the
    rest, so a board of short names sits perfectly still and the chip stays
    lit whatever the name is doing.
    """
    s = st["s"]
    return render.Row(
        cross_align = "center",
        children = [
            render.Box(width = 4 * s, height = 5 * s, color = door_color(door)),
            render.Padding(
                pad = (2 * s, 0, 0, 0),
                child = scroller(
                    st,
                    st["w"] - 8 * s,
                    door_label(door, index),
                    st["tiny"],
                    WHITE,
                ),
            ),
        ],
    )

def board_order(doors):
    """Sorts the doors a truncated board must not drop to the top.

    Only used when the board has more doors than rows: the row that must
    survive the cut is the one that is open, then the one whose state the API
    would not say. Each door keeps its original position so an unnamed door is
    still numbered by where it sits in the site, not by where it was moved to.
    """
    open_doors = []
    unknown = []
    locked = []
    for index, door in enumerate(doors):
        status = door.get("door_lock_relay_status", "")
        if status == "unlock":
            open_doors.append((index, door))
        elif status == "lock":
            locked.append((index, door))
        else:
            unknown.append((index, door))
    return open_doors + unknown + locked

def board_view(st, doors):
    """Full-panel door board, used when the entry log is empty."""
    s = st["s"]
    line = st["line"]
    avail = st["h"] - (line + 2 * s)
    count = len(doors)

    # The same sentence the lock band prints, for the same reason: the header
    # is the only line guaranteed to be on screen, and a board that has to drop
    # rows must not be the one view of this data that hides an open door.
    sentence, sentence_color = lock_tally(doors)

    if count <= BOARD_WORD_MAX:
        blocks = []
        for index, door in enumerate(doors):
            blocks.append(door_block(st, door, index))
        body = render.Column(children = spread(blocks, 2 * line, avail))
    else:
        rows = []
        for index, door in enumerate(doors):
            rows.append((index, door))
        overflow = 0
        if count > MAX_BOARD_ROWS:
            rows = board_order(doors)[:MAX_BOARD_ROWS - 1]
            overflow = count - (MAX_BOARD_ROWS - 1)

        blocks = []
        for index, door in rows:
            blocks.append(door_row(st, door, index))
        if overflow > 0:
            blocks.append(
                render.Padding(
                    pad = (6 * s, 0, 0, 0),
                    child = render.Text("+%d MORE" % overflow, font = st["tiny"], color = DIM),
                ),
            )
        body = render.Column(children = spread(blocks, line, avail))

    return render.Root(
        child = render.Column(
            children = [
                header(st, sentence, sentence_color),
                rule(st, RULE),
                render.Padding(pad = (s, 0, s, 0), child = body),
            ],
        ),
    )

def main(config):
    st = style()

    raw_host = config.str("host", "")
    token = (config.str("token", "") or "").strip()
    scheme, host, problem = clean_host(raw_host)

    # "ADD API HOST", not "ADD CONSOLE": the address this app wants is the
    # Access API server on 12445, and pointing it at the console instead is the
    # one mistake that cannot be rendered - the console answers 443 with a
    # certificate that does not cover 12445, and nothing listens on 12445 with
    # it (bench-verified), so the render aborts before any card can explain it.
    # Twelve characters also keeps the headline in the body font, which is what
    # separates it from the detail line underneath.
    if problem == "empty" or token == "":
        return card(st, "ADD API HOST", DIM, "+ API TOKEN")

    # A character that cannot sit in a URL host - a space left in by a sloppy
    # paste, most often - has no scheme that saves it. http.get raises on the
    # unparsable URL, and a raised error aborts the render with no card at all,
    # every render, until the address is edited. So this one is fatal under
    # http:// too, unlike the certificate problems below.
    if problem == "chars":
        return card(st, "NEEDS HOSTNAME", AMBER, "check for typos")

    # A bare IP or .local name over https will fail TLS verification, which
    # aborts the render uncatchably. Say so instead. Deliberately NOT "use the
    # .ui.direct name": that certificate covers the console on 443 only, and
    # nothing answers on 12445 with it (bench-verified). The requirement here
    # is a name this display can resolve, served by a certificate it trusts.
    # "with valid cert" rather than the longer "valid cert required": at 15
    # characters it sits still, and every other detail line here fits too. The
    # spelt-out version scrolls, and a 19-character marquee in a 16-character
    # window is blank for most of its cycle - on the one card whose entire job
    # is to explain the problem.
    if problem != None and scheme == "https://":
        return card(st, "NEEDS HOSTNAME", AMBER, "with valid cert")

    base = scheme + with_port(host) + "/api/v1/developer"
    headers = {
        "Authorization": "Bearer " + token,
        "Accept": "application/json",
    }

    doors, doors_problem = fetch_doors(base, headers)
    if doors_problem != None:
        return card(st, doors_problem, RED, PROBLEM_DETAIL.get(doors_problem, "server error"))

    # The log is the nice-to-have half. A token scoped to Space but not System
    # Log answers /doors and refuses /system/logs, and older Access firmware
    # has no /system/logs at all - neither is a reason to replace a board we
    # can already draw with an error card, least of all a 404 card that tells
    # the user to check a port /doors just succeeded on. Only card out when the
    # board cannot be drawn either.
    source, log_problem = fetch_last_entry(base, headers)
    if log_problem != None:
        if len(doors) == 0:
            return card(st, log_problem, RED, PROBLEM_DETAIL.get(log_problem, "server error"))
        return board_view(st, doors)

    if source != None:
        return entry_view(st, source, doors, int(time.now().unix))

    if len(doors) == 0:
        return card(st, "NO DOORS", AMBER, "none in access")

    return board_view(st, doors)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "host",
                name = "Access API server",
                desc = "Hostname of the Access API server, with an optional :port - 12445 is assumed. Access has no cloud API, so the display talks to this server directly and must both resolve the name you enter here and trust the certificate that server presents. Your console's remote-access hostname will not do - that certificate covers port 443 only, and nothing answers on 12445 with it. Either give the Access API server a certificate of its own (POST /api/v1/developer/api_server/certificates) or put a reverse proxy that already has one in front of it and enter the proxy's address instead. A bare IP address can never work over https.",
                icon = "server",
            ),
            schema.Text(
                id = "token",
                name = "API token",
                desc = "Access > Settings > General > Advanced > API Token > Create New, granting the Space and System Log view permissions. Space alone is enough to show the door board; System Log is what adds the most recent entry above it. This is the Access API token specifically - a UniFi Cloud or Site Manager key will not open this door.",
                icon = "key",
                secret = True,
            ),
        ],
    )
