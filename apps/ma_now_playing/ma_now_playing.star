"""
Applet: MA Now Playing
Summary: Music Assistant Now Playing
Description: The cover, title, artist, and the playlist or album a Music Assistant player is playing, with a progress bar that runs while it's on screen. With nothing playing it shows a clock, or skips its turn.
Author: gcrft123
"""

load("animation.star", "animation")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

FRAME_MS = 100  # the Now Playing screen's frame length
MUSIC_FRAMES = 300  # 30 s at 100 ms; Tronbyt cuts the animation to the app's display time
CLOCK_FRAMES = 60  # 30 s at 500 ms, so the colon blinks once a second
SCROLL_PAUSE = 10  # frames held at each end of a ping-pong
COVER_SIZE = "160"  # an image proxy size big enough for the 2x cover
COVER_TTL = 3600  # seconds a cover stays in Pixlet's HTTP cache

WHITE = "#ffffff"
GREY = "#8a8f98"
DIM = "#3a3a3a"
ERROR = "#ff6b6b"
TILE = "#1c1f24"

GLYPHS = {
    "playlist": ["####.", ".....", "####.", ".....", "##.#."],
    "album": [".###.", "#...#", "#.#.#", "#...#", ".###."],
    "note": ["..###", "..#.#", "..#..", "###..", "###.."],
}

# ---------------------------------------------------------------- layout

def is_square():
    w, h = canvas.size()
    return h == w

def layout():
    """Sizes and fonts for the display: 64x32, 128x64 (2x), or 64x64 (square)."""
    w, h = canvas.size()
    if canvas.is2x():
        return struct(
            w = w,
            h = h,
            s = 2,
            square = False,
            art = 48,
            gap = 6,
            bar = 4,
            title = "terminus-18",
            small = "terminus-14",
            clock = "terminus-32",
            date = "terminus-16",
        )
    return struct(
        w = w,
        h = h,
        s = 1,
        square = is_square(),
        art = 32 if is_square() else 24,
        gap = 3,
        bar = 2,
        title = "tb-8",
        small = "tom-thumb",
        clock = "10x20",
        date = "tb-8" if is_square() else "tom-thumb",
    )

# ---------------------------------------------------------------- drawing

def text(content, font, color):
    return render.Text(content = content, font = font, color = color)

def dot(x, y, color, size):
    return render.Padding(pad = (x, y, 0, 0), child = render.Box(width = size, height = size, color = color))

def glyph(name, color, s):
    rows = GLYPHS[name]
    dots = []
    for y, row in enumerate(rows):
        for x in range(len(row)):
            if row[x] == "#":
                dots.append(dot(x * s, y * s, color, s))
    return render.Stack(children = [render.Box(width = len(rows[0]) * s, height = len(rows) * s)] + dots)

def shifted(child, dx):
    """`child` moved dx pixels sideways (negative is left), for one frame."""
    return animation.Transformation(
        child = child,
        duration = 1,
        keyframes = [
            animation.Keyframe(percentage = 0.0, transforms = [animation.Translate(dx, 0)]),
            animation.Keyframe(percentage = 1.0, transforms = [animation.Translate(dx, 0)]),
        ],
    )

def pingpong(child, width, height, room, step, wait = 0):
    """`child` (`width` wide) in `room` pixels: still when it fits, otherwise
    sliding `step` pixels a frame to show its end and back, pausing at each
    end. `wait` adds frames to the first pause, so lines that scroll together
    don't move in step."""
    if width <= room:
        return child

    # Lay the child out at its full width first; inside `room` it would be cut off before it moves.
    child = render.Box(width = width, height = height, child = child)
    travel = width - room
    moves = list(range(step, travel, step)) + [travel]
    offsets = [0] * (SCROLL_PAUSE + wait) + [-m for m in moves] + [-travel] * SCROLL_PAUSE + [-m for m in reversed(moves[:-1])]
    return render.Box(width = room, height = height, child = render.Animation(children = [shifted(child, dx) for dx in offsets]))

def line(content, font, color, room, L, wait = 0):
    """One line of text, scrolling when it's wider than `room`."""
    t = text(content, font, color)
    w, h = t.size()
    return pingpong(t, w, h, room, L.s, wait)

def hex2(n):
    n = max(0, min(255, int(n + 0.5)))
    return "0123456789abcdef"[n // 16] + "0123456789abcdef"[n % 16]

def led_accent(rgb):
    """A cover's accent color made to read on LEDs: vivid and bright, or white
    when the cover has no color worth showing."""
    if not rgb or len(rgb) < 3:
        return WHITE
    r, g, b = rgb[0] / 255.0, rgb[1] / 255.0, rgb[2] / 255.0
    hi, lo = max(r, g, b), min(r, g, b)
    if hi == 0 or (hi - lo) / hi < 0.2:
        return WHITE

    # HSV, then saturation clamped to 0.55-0.9 and value raised to 0.85
    d = hi - lo
    if hi == r:
        h = ((g - b) / d) % 6
    elif hi == g:
        h = (b - r) / d + 2
    else:
        h = (r - g) / d + 4
    s = max(0.55, min(d / hi, 0.9))
    v = max(0.85, hi)
    c = v * s
    x = c * (1 - abs(h % 2 - 1))
    m = v - c
    rr, gg, bb = [(c, x, 0), (x, c, 0), (0, c, x), (0, x, c), (x, 0, c), (c, 0, x)][int(h) % 6]
    return "#" + hex2((rr + m) * 255) + hex2((gg + m) * 255) + hex2((bb + m) * 255)

# ---------------------------------------------------------------- Music Assistant

def api(base, token, command, args = {}):
    """One command on Music Assistant's HTTP API: (result, error message)."""
    resp = http.post(
        base + "/api",
        headers = {"Authorization": "Bearer " + token, "Content-Type": "application/json"},
        json_body = {"command": command, "args": args, "message_id": "tronbyt"},
    )
    if resp.status_code == 401:
        return None, "TOKEN REJECTED"
    if resp.status_code == 403:
        return None, "TOKEN CAN'T READ"
    if resp.status_code == 503:
        return None, "MA NOT SET UP"
    if resp.status_code >= 400:
        return None, "MA ERROR %d" % resp.status_code
    return json.decode(resp.body()), None

def is_mirror(p):
    """A player that's only following another (a synced member, or a member
    of an active group). The one it follows is listed too."""
    return bool(p.get("synced_to")) or (bool(p.get("active_group")) and p.get("active_group") != p.get("player_id"))

def pick_player(players, wanted):
    """The player to show: the one named in the config, or else one that's
    playing before one that's paused, a group's leader before its members."""
    usable = [p for p in players if p.get("available") and p.get("enabled", True)]
    if wanted:
        w = wanted.strip().lower()
        for p in usable:
            if p.get("player_id", "").lower() == w or (p.get("display_name") or p.get("name") or "").lower() == w:
                return p, None
        return None, "NO PLAYER " + wanted.upper()
    found = []
    for p in usable:
        media = p.get("current_media") or {}
        if p.get("playback_state") in ("playing", "paused") and media.get("title"):
            found.append(((0 if p["playback_state"] == "playing" else 1, 1 if is_mirror(p) else 0, p.get("name") or ""), p))
    if not found:
        return None, None
    return sorted(found, key = lambda f: f[0])[0][1], None

def elapsed(player, queue, now):
    """Where the song is, in seconds, from whichever report is freshest."""
    playing = player.get("playback_state") == "playing"
    media = player.get("current_media") or {}
    if queue and queue.get("current_item") and queue.get("state") in ("playing", "paused"):
        pos, stamp, speed = queue.get("elapsed_time"), queue.get("elapsed_time_last_updated"), queue.get("playback_speed") or 1.0
    elif media.get("elapsed_time") != None:
        pos, stamp, speed = media.get("elapsed_time"), media.get("elapsed_time_last_updated"), 1.0
    else:
        pos, stamp, speed = player.get("elapsed_time"), player.get("elapsed_time_last_updated"), 1.0
    pos = float(pos or 0)
    if playing and stamp:
        pos += max(0.0, now - float(stamp)) * speed
    return pos

def source_of(queue, media):
    """The playlist (or album) the song was started from: (name, glyph)."""
    item = (queue or {}).get("current_item") or {}
    container = (item.get("origin") or {}).get("container")
    if not container and (queue or {}).get("sources"):
        container = queue["sources"][0]
    if container and container.get("name"):
        return container["name"], ("album" if container.get("media_type") == "album" else "playlist")
    if media.get("album"):
        return media["album"], "album"
    return "", "album"

def cover_url(base, url):
    """The cover through Music Assistant's image proxy at a small size,
    reached at the configured address, or the URL as given if it's elsewhere."""
    i = url.find("/imageproxy/")
    if i < 0:
        return url
    path = url[i:]
    q = path.find("?")
    if q >= 0:
        path = path[:q]
    return base + path + "?size=" + COVER_SIZE + "&fmt=png"

def fetch_cover(base, url):
    if not url:
        return None
    resp = http.get(cover_url(base, url), ttl_seconds = COVER_TTL)
    kind = (resp.headers.get("Content-Type") or "").lower()
    if resp.status_code != 200 or "svg" in kind or not resp.body():
        return None
    return resp.body()

def now_playing(base, token, wanted):
    """What to draw: (the Now Playing fields or None, an error or None)."""
    players, err = api(base, token, "players/all")
    if err:
        return None, err
    player, err = pick_player(players or [], wanted)
    if not player:
        return None, err
    media = player.get("current_media") or {}
    if player.get("playback_state") not in ("playing", "paused") or not media.get("title"):
        return None, None
    queue = None
    if media.get("source_id"):
        queue, _ = api(base, token, "player_queues/get", {"queue_id": media["source_id"]})
    source, kind = source_of(queue, media)
    duration = media.get("duration") or ((queue or {}).get("current_item") or {}).get("duration") or 0
    palette = media.get("palette") or {}
    return {
        "playing": player["playback_state"] == "playing",
        "title": media.get("title") or "",
        "artist": media.get("artist") or media.get("album_artist") or "",
        "source": source,
        "source_kind": kind,
        "art": fetch_cover(base, media.get("image_url") or ""),
        "color": led_accent(palette.get("accent") or palette.get("primary")),
        "position": elapsed(player, queue, time.now().unix_nano / 1e9),
        "duration": float(duration),
    }, None

# ---------------------------------------------------------------- Now Playing

def art_widget(data, size, s):
    """The cover with its corners rounded off; a note on a dark tile when there's no cover."""
    if data:
        base = render.Image(src = data, width = size, height = size)
    else:
        base = render.Box(width = size, height = size, color = TILE, child = glyph("note", GREY, s))
    e = size - s
    corners = []
    for x, y in [(0, 0), (s, 0), (0, s)]:
        corners += [dot(x, y, "#000000", s), dot(e - x, y, "#000000", s), dot(x, e - y, "#000000", s), dot(e - x, e - y, "#000000", s)]
    return render.Stack(children = [base] + corners)

def paused_mark(s):
    """Two pause bars in a dark tile, for the cover's corner."""
    return render.Box(width = 7 * s, height = 7 * s, color = "#000000", child = render.Row(children = [
        render.Box(width = 2 * s, height = 5 * s, color = WHITE),
        render.Box(width = s, height = 5 * s),
        render.Box(width = 2 * s, height = 5 * s, color = WHITE),
    ]))

def progress(position, duration, color, moving, L):
    """A bar across the bottom that advances 0.1 s a frame from `position`, or stays put."""
    w, h = L.w, L.bar
    if duration <= 0:
        return render.Box(width = w, height = h, color = DIM)
    frames = []
    last = -1
    for i in range(MUSIC_FRAMES if moving else 1):
        done = min(w, int((position + i * FRAME_MS / 1000.0) / duration * w + 0.5))
        if done == last:
            frames.append(frames[-1])
            continue
        last = done
        frames.append(render.Row(children = (
            ([render.Box(width = done, height = h, color = color)] if done > 0 else []) +
            ([render.Box(width = w - done, height = h, color = DIM)] if done < w else [])
        )))
    return render.Animation(children = frames)

def music_rows(np, color, room, L):
    """Title, artist, and source, each scrolling on its own when it's too wide."""
    s = L.s
    rows = [
        line(np["title"], L.title, WHITE, room, L),
        render.Box(width = 1, height = s),
        line(np["artist"], L.small, color, room, L, wait = 15),
    ]
    if np["source"]:
        src = text(np["source"], L.small, GREY)
        sw, sh = src.size()
        row = render.Row(cross_align = "center", children = [glyph(np["source_kind"], GREY, s), render.Box(width = 2 * s, height = 1), src])
        rows += [render.Box(width = 1, height = s), pingpong(row, 7 * s + sw, sh, room, s, 30)]
    return rows

def music_screen(np, L):
    paused = not np["playing"]
    color = GREY if paused else np["color"]
    s = L.s
    cover = render.Stack(children = [art_widget(np["art"], L.art, s)] + (
        [render.Padding(pad = (L.art - 8 * s, L.art - 8 * s, 0, 0), child = paused_mark(s))] if paused else []
    ))
    above = L.h - L.bar

    if L.square:
        # Cover centered on top, the text centered under it.
        top = 2
        body = render.Column(children = [
            render.Box(width = L.w, height = L.art + top, child = render.Padding(pad = (0, top, 0, 0), child = cover)),
            render.Box(width = L.w, height = above - L.art - top, child = render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = music_rows(np, color, L.w - 2, L),
            )),
        ])
    else:
        # Cover on the left and text on the right, both centered above the bar.
        room = L.w - L.art - L.gap
        body = render.Row(children = [
            render.Box(width = L.art, height = above, child = cover),
            render.Box(width = L.gap, height = 1),
            render.Box(width = room, height = above, child = render.Column(
                expanded = True,
                main_align = "center",
                children = music_rows(np, color, room, L),
            )),
        ])
    return render.Root(delay = FRAME_MS, child = render.Column(children = [body, progress(np["position"], np["duration"], color, not paused, L)]))

# ---------------------------------------------------------------- Nothing Playing

def two(n):
    return ("0" if n < 10 else "") + str(n)

def clock_frame(t, hour24, colon, notes, color, L):
    hh = two(t.hour) if hour24 else str(t.hour % 12 or 12)

    # The colon goes dark rather than away, so the digits don't move.
    time_row = render.Row(children = [
        text(hh, L.clock, WHITE),
        text(":", L.clock, WHITE if colon else "#000000"),
        text(two(t.minute), L.clock, WHITE),
    ])
    return render.Box(width = L.w, height = L.h, child = render.Column(
        expanded = True,
        main_align = "center",
        cross_align = "center",
        children = [
            time_row,
            render.Box(width = 1, height = 2 * L.s + (2 if L.square else 0)),
        ] + [line(n, L.date, color, L.w - 2, L) for n in notes],
    ))

def clock_screen(config, L, error = None):
    """The time, with the date (or what's wrong) under it. The colon blinks,
    and the minute turns over on time while it's on screen."""
    hour24 = config.bool("hour24", False)
    now = time.now()
    frames = []
    for i in range(CLOCK_FRAMES):
        t = now + time.parse_duration("%dms" % (i * 500))
        colon = (t.nanosecond // 500000000) % 2 == 0
        if error:
            notes = [error]
        elif L.square:
            notes = [t.format("Monday").upper(), t.format("Jan 2").upper()]
        else:
            notes = [t.format("Mon Jan 2").upper()]
        frames.append(clock_frame(t, hour24, colon, notes, ERROR if error else GREY, L))
    return render.Root(delay = 500, child = render.Animation(children = frames))

def setup_screen(L):
    s = L.s
    return render.Root(child = render.Box(width = L.w, height = L.h, child = render.Column(
        expanded = True,
        main_align = "center",
        cross_align = "center",
        children = [
            render.Row(cross_align = "center", children = [glyph("note", WHITE, s), render.Box(width = 3 * s, height = 1), text("NOW PLAYING", L.small, WHITE)]),
            render.Box(width = 1, height = 3 * s),
            render.WrappedText(content = "Add your Music Assistant URL and token", font = "terminus-12" if s == 2 else L.small, color = GREY, width = L.w - 4 * s, align = "center"),
        ],
    )))

# ---------------------------------------------------------------- main

def main(config):
    L = layout()
    base = (config.str("ma_url", "") or "").strip().rstrip("/")
    token = (config.str("ma_token", "") or "").strip()
    if not base or not token:
        return setup_screen(L)
    if "://" not in base:
        base = "http://" + base
    np, err = now_playing(base, token, config.str("player", ""))
    if np:
        return music_screen(np, L)
    if config.str("idle", "clock") == "skip" and not err:
        return []
    return clock_screen(config, L, err)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ma_url",
                name = "Music Assistant URL",
                desc = "Where Tronbyt reaches Music Assistant, like http://192.168.1.10:8095.",
                icon = "server",
            ),
            schema.Text(
                id = "ma_token",
                name = "Token",
                desc = "A long-lived access token from Music Assistant's Settings → Profile.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "player",
                name = "Player",
                desc = "A player's name or ID. Blank shows whichever is playing.",
                icon = "volumeHigh",
                default = "",
            ),
            schema.Dropdown(
                id = "idle",
                name = "Nothing playing",
                desc = "What to show when nothing is playing or paused.",
                icon = "clock",
                default = "clock",
                options = [
                    schema.Option(display = "Clock", value = "clock"),
                    schema.Option(display = "Skip in rotation", value = "skip"),
                ],
            ),
            schema.Toggle(
                id = "hour24",
                name = "24-hour clock",
                desc = "Show the clock in 24-hour time.",
                icon = "clock",
                default = False,
            ),
        ],
    )
