"""
Applet: Twitch Live
Summary: A streamer's live frame
Description: Put in one Twitch channel and the panel shows what that stream looks like right now, scaled down to the pixels you have. When the channel is not streaming it says OFFLINE instead. The picture is the preview frame Twitch publishes for the channel, which the service regenerates every few minutes, so it is a window onto the stream rather than live video - nothing on a panel this size could decode video anyway.
Author: nsluke
"""

load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")

PREVIEW = "https://static-cdn.jtvnw.net/previews-ttv/live_user_"

# A channel that is offline, that never existed, or whose name is merely
# spelled wrong all get the same answer: a 302 to one shared placeholder
# image. http.get follows redirects, so what comes back is a perfectly valid
# 200 carrying a perfectly wrong picture, and the only thing that gives it
# away is where the reply finally came from. resp.url is the LAST request the
# client made rather than the first, which is what makes this readable at all.
OFFLINE_HOST_PATH = "/ttv-static/"

# Twitch regenerates a channel's preview every five minutes -- its own reply
# says max-age=300 -- so a shorter TTL than this buys nothing but traffic.
# It is still well under five so that a channel coming online shows up on the
# panel in about a minute rather than in six.
TTL = 60

# Long enough to ride out a server hiccup, short enough that a dark panel is
# better than a picture of a stream that ended while the display was cut off.
MAX_AGE = 900

WHITE = "#E8E4DC"
DIM = "#7C7484"
PURPLE = "#A970FF"

# A Twitch login is lowercase letters, digits and underscores, and at most 25
# of them. The check is not pedantry: a character http.get cannot put in a URL
# is a parse failure inside the call, which aborts the render before a packet
# leaves the device -- a blank panel with no card on it and the app dropped
# from the rotation.
LOGIN_CHARS = "abcdefghijklmnopqrstuvwxyz0123456789_"
LOGIN_MAX = 25

def is_square():
    """Branch on canvas SHAPE, not size: a 2x wide panel reports 128x64 and a
    2x square one 128x128, so a bare height test gets both wrong."""
    w, h = canvas.size()
    return h == w

def fonts():
    """One font pair for every canvas.

    The channel name is the one string here the app does not choose, so it is
    set in a face with true M, W and V glyphs. At 3px those three collapse
    into H and Y, which would quietly rename a third of the channels on
    Twitch.
    """
    two = canvas.is2x()
    return {
        "big": "10x20" if two else "6x10",
        "name": "Dina_r400-6" if two else "tb-8",
        "s": 2 if two else 1,
    }

def clean_login(raw):
    """Turns whatever the user typed into a channel login.

    Lowercased, and that is the whole reason this function exists. The CDN
    path is case sensitive and the name Twitch puts on the channel page is
    not: somebody who copies "JynxZi" off the page gets the offline
    placeholder for a channel that is streaming, forever, with nothing on the
    panel to say why. A pasted URL and a leading @ are taken too, because
    those are the other two things people paste into a box that says channel.
    """
    h = raw.strip().lower()
    for prefix in ("https://", "http://"):
        if h.startswith(prefix):
            h = h[len(prefix):]
    if h.startswith("www."):
        h = h[4:]
    if h.startswith("twitch.tv/"):
        h = h[len("twitch.tv/"):]
    if h.startswith("@"):
        h = h[1:]
    return h.split("/")[0].split("?")[0].strip()

def login_ok(login):
    if login == "" or len(login) > LOGIN_MAX:
        return False
    for c in login.codepoints():
        if c not in LOGIN_CHARS:
            return False
    return True

def frame_size():
    """What to ask the CDN for, which is also exactly what gets drawn.

    The size lives in the URL and Twitch resizes server side, so the panel
    never scales a pixel of its own and never pays to carry one it will throw
    away: a 64x32 frame is 1.3 KB. The two wide canvases take the whole panel.
    A square one asks for 16:9 at panel width instead of a square crop of a
    widescreen picture, and gives the rows underneath to the channel name.
    """
    w, h = canvas.size()
    if is_square():
        return (w, w * 9 // 16)
    return (w, h)

# tb-8 advances, read off the shipped font: I, J and T are 4 wide, M, V, W and
# Y are 6, every other capital and every digit is 5. Anything else -- an
# underscore, most obviously -- is budgeted at 6, the widest cell in the face,
# so an unexpected glyph can only ever leave the name shorter than it had room
# for, never spill it off a panel edge that nothing here would clip.
NARROW = "IJT"
WIDE = "MVWY"
KNOWN = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

def char_adv(c):
    if c in NARROW:
        return 4
    if c in WIDE:
        return 6
    if c in KNOWN:
        return 5
    return 6

def fit_name(name, room):
    """As much of the channel name as fits, measured glyph by glyph."""
    out = ""
    w = 0
    for c in name.codepoints():
        cw = char_adv(c)
        if w + cw > room:
            return out
        out += c
        w += cw
    return out

def name_line(l, login):
    shown = fit_name(login.upper(), (canvas.width() - 2 * l["s"]) // l["s"])
    if shown == "":
        return render.Box(width = 1, height = 1)
    return render.Text(content = shown, font = l["name"], color = PURPLE)

def notice(title, login):
    """Full-panel message, with the channel it is about underneath it."""
    l = fonts()
    children = [render.Text(content = title, font = l["big"], color = WHITE)]
    if login != "":
        children.append(render.Box(height = l["s"]))
        children.append(name_line(l, login))
    return render.Root(
        child = render.Box(
            padding = l["s"],
            child = render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = children,
            ),
        ),
    )

def wrapped(text):
    """For the strings too long to set in the hero font at 64 columns."""
    l = fonts()
    return render.Root(
        child = render.Box(
            padding = l["s"],
            child = render.WrappedText(
                content = text,
                font = l["name"],
                color = DIM,
                width = canvas.width() - 2 * l["s"],
                align = "center",
            ),
        ),
    )

def live(body, login, fw, fh):
    """The frame, full bleed on a wide panel and letterboxed on a square one."""
    l = fonts()
    img = render.Image(src = body, width = fw, height = fh)
    if not is_square():
        return render.Root(max_age = MAX_AGE, child = img)
    return render.Root(
        max_age = MAX_AGE,
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [img, render.Box(height = 2 * l["s"]), name_line(l, login)],
        ),
    )

def main(config):
    login = clean_login(config.str("channel") or "")
    if login == "":
        return wrapped("ADD A TWITCH CHANNEL")
    if not login_ok(login):
        return wrapped("THAT IS NOT A CHANNEL NAME")

    fw, fh = frame_size()
    resp = http.get(
        PREVIEW + login + "-" + str(fw) + "x" + str(fh) + ".jpg",
        ttl_seconds = TTL,
    )
    if resp.status_code != 200:
        return notice("HTTP %d" % resp.status_code, login)

    # Not "this channel is offline": the placeholder is also what a name with
    # a typo in it gets, and the panel cannot tell those apart. OFFLINE is the
    # honest half of it, and the name underneath is what lets someone standing
    # in front of the panel work out which it is.
    if OFFLINE_HOST_PATH in resp.url:
        return notice("OFFLINE", login)

    return live(resp.body(), login, fw, fh)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "channel",
                name = "Channel",
                desc = "The streamer's Twitch name, as it appears in their twitch.tv address. Pasting the whole address works too.",
                icon = "twitch",
            ),
        ],
    )
