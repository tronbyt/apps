"""
Applet: Mailcow Updates
Summary: Mailcow server updates
Description: Shows when a new mailcow release is available for your mailcow servers, comparing the version each server is running with the latest release on GitHub.
Author: saltedlolly
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("hash.star", "hash")
load("http.star", "http")
load("images/mailcow.png", MAILCOW_LOGO = "file")
load("images/mailcow@2x.png", MAILCOW_LOGO_2X = "file")
load("re.star", "re")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

RELEASES_URL = "https://api.github.com/repos/mailcow/mailcow-dockerized/releases?per_page=20"
VERSION_PATH = "/api/v1/get/status/version"
MAX_SERVERS = 5

# How often to check GitHub for new releases, and each server's version. A server's version only changes when it's
# updated, so while it's behind it's rechecked more often, and its card goes soon after the update.
RELEASE_TTL = 60 * 60
SERVER_TTL = 60 * 60
SERVER_TTL_WHILE_BEHIND = 5 * 60

# After a server or GitHub can't be reached, how long to wait before trying it again
RETRY_AFTER = 15 * 60

# Each card is shown for PAGE_FRAMES frames of FRAME_DELAY ms. With several cards, they're repeated until the whole
# animation lasts at least MIN_ANIMATION_MS, so the display doesn't move on halfway through.
FRAME_DELAY = 500
PAGE_FRAMES = 9
MIN_ANIMATION_MS = 15000

AMBER = "#ffaa00"
GREEN = "#3cdc5a"
RED = "#ff5050"
WHITE = "#ffffff"
MUTED = "#999999"

def version_key(version):
    """[2026, 11, "b"] for "2026-11b", or None if it isn't a mailcow release tag (e.g. a commit ID on nightly)."""
    found = re.match(r"^(\d{4})-(\d{2})([a-z]?)$", version or "")
    if not found:
        return None
    return [int(found[0][1]), int(found[0][2]), found[0][3]]

def newer(a, b):
    """Whether release tag a is newer than release tag b."""
    return version_key(a) > version_key(b)

def releases():
    """mailcow's recent releases, newest first, as [{"tag": "2026-11b", "published": "2026-11-19T16:47:32Z"}, ...].
    The last list found
    is remembered, so a GitHub outage or rate limit doesn't stop the app. If GitHub couldn't be reached last time
    (see check()), the saved list is used for a while."""
    saved = cache.get("mailcow-releases")
    note = cache.get("mailcow-releases-attempt")
    if note == "started" or note == "failed":
        if note == "started":
            cache.set("mailcow-releases-attempt", "failed", ttl_seconds = RETRY_AFTER)
        return json.decode(saved) if saved else []
    cache.set("mailcow-releases-attempt", "started", ttl_seconds = 24 * 60 * 60)
    resp = http.get(RELEASES_URL, headers = {"Accept": "application/vnd.github+json"}, ttl_seconds = RELEASE_TTL)
    cache.set("mailcow-releases-attempt", "", ttl_seconds = 60)
    if resp.status_code == 200:
        found = []
        for release in resp.json():
            if release.get("draft") or release.get("prerelease") or not version_key(release.get("tag_name")):
                continue
            found.append({"tag": release["tag_name"], "published": release.get("published_at") or ""})
        found = sorted(found, key = lambda r: version_key(r["tag"]), reverse = True)
        if found:
            cache.set("mailcow-releases", json.encode(found), ttl_seconds = 30 * 24 * 60 * 60)
            return found
    return json.decode(saved) if saved else []

def server_version(server, latest):
    """The version the server is running, e.g. "2026-11a", and an error message if it couldn't be read."""
    key = "mailcow-version-%s" % hash.sha256(server["address"])
    saved = cache.get(key)
    if saved:
        saved = json.decode(saved)
        behind = latest and version_key(saved["version"]) and newer(latest, saved["version"])
        if not behind or time.now().unix - saved["checked"] < SERVER_TTL_WHILE_BEHIND:
            return saved["version"], None

    resp = http.get(server["address"] + VERSION_PATH, headers = {"X-API-Key": server["api_key"], "Accept": "application/json"})
    if resp.status_code in (401, 403):
        return None, "API key not accepted"
    if resp.status_code != 200:
        return None, "mailcow error %d" % resp.status_code
    body = json.decode(resp.body()) if resp.body().startswith("{") else {}
    version = body.get("version")
    if type(version) != "string" or not version:
        return None, "Can't read the version"
    cache.set(key, json.encode({"version": version, "checked": time.now().unix}), ttl_seconds = SERVER_TTL)
    return version, None

def check(server, latest):
    """The server's version, or an error.

    A request to a server that can't be reached stops the app with an error, which Starlark can't catch, so the
    display would just skip it. To show that instead, a note is left in the cache before contacting the server and
    cleared afterwards. If a run finds the note still there, the last attempt failed: it says so, and the server isn't
    tried again for RETRY_AFTER, so its failures don't stop the other servers' cards being shown.
    """
    attempt = "mailcow-attempt-%s" % hash.sha256(server["address"])
    note = cache.get(attempt)
    if note == "started" or note == "failed":
        if note == "started":
            cache.set(attempt, "failed", ttl_seconds = RETRY_AFTER)
        return None, "Can't connect"
    cache.set(attempt, "started", ttl_seconds = 24 * 60 * 60)
    version, error = server_version(server, latest)
    cache.set(attempt, "", ttl_seconds = 60)
    return version, error

def is_local_host(host):
    """localhost, .local names, or a private IPv4 address."""
    host = host.lower()
    if host.endswith(".local") or host == "localhost":
        return True
    parts = host.split(".")
    if len(parts) != 4 or not all([p.isdigit() for p in parts]):
        return False
    a, b = int(parts[0]), int(parts[1])
    return a == 10 or a == 127 or (a == 192 and b == 168) or (a == 172 and b >= 16 and b <= 31)

def host_name(address):
    return address.split("://", 1)[-1].split("/", 1)[0].split(":", 1)[0]

def servers_from(config):
    """The servers set up in the app's settings, in order."""
    count = config.str("server_count", "1")
    count = int(count) if count.isdigit() else 1
    found = []
    for n in range(1, min(count, MAX_SERVERS) + 1):
        address = config.str("address_%d" % n, "").strip().rstrip("/")
        if not address:
            continue
        found.append({
            "address": address,
            "api_key": config.str("api_key_%d" % n, "").strip(),
            "name": config.str("nickname_%d" % n, "").strip() if count > 1 else "",
        })
    return found

def cards_for(servers, release_list):
    """One card for each server that needs attention: an update, or a problem. Also how many are up to date, and the
    version they're on if they all agree."""
    latest = release_list[0]["tag"] if release_list else None
    cards = []
    up_to_date = []
    several = len(servers) > 1
    for server in servers:
        name = (server["name"] or host_name(server["address"])) if several else ""

        # The API key is sent with every check, so plain http is only allowed on your own network.
        local_http = server["address"].startswith("http://") and is_local_host(host_name(server["address"]))
        if not server["address"].startswith("https://") and not local_http:
            cards.append({"kind": "error", "name": name, "text": "Use an https:// address"})
            continue
        if not server["api_key"]:
            cards.append({"kind": "error", "name": name, "text": "Add your API key"})
            continue
        version, error = check(server, latest)
        if error:
            cards.append({"kind": "error", "name": name, "text": error})
        elif not latest:
            cards.append({"kind": "error", "name": name, "text": "Can't check GitHub for releases"})
        elif version_key(version) and newer(latest, version):
            cards.append({
                "kind": "update",
                "name": name,
                "from": version,
                "to": latest,
                "released": release_list[0].get("published", ""),
            })
        elif not version_key(version):
            # Not a release tag (e.g. a commit ID on the nightly branch), so it can't be compared. Only shown when
            # "Only show when there's an update" is off.
            cards.append({"kind": "info", "name": name, "text": "%s isn't a release" % version})
        else:
            up_to_date.append(version)
    return cards, up_to_date

def logo(scale):
    return render.Image(src = (MAILCOW_LOGO_2X if scale == 2 else MAILCOW_LOGO).readall())

def fit(text, font, width):
    """The text, shortened if it's wider than the display."""
    for n in range(len(text), 0, -1):
        cut = text if n == len(text) else text[:n - 1] + "."
        if render.Text(cut, font = font).size()[0] <= width:
            return cut
    return ""

def page(subtitle, lines, width, scale, fonts):
    """The logo beside "mailcow" and a subtitle, then some lines, in the middle of the display."""
    heading = [render.Text("mailcow", font = fonts["title"], color = WHITE)]
    if subtitle:
        heading.append(subtitle)
    children = [
        render.Row(
            cross_align = "center",
            children = [logo(scale), render.Box(width = 2 * scale, height = 1), render.Column(children = heading)],
        ),
    ]
    for i, line in enumerate(lines):
        children.append(render.Box(width = 1, height = (2 if i == 0 else 1) * scale))
        children.append(line)
    return render.Box(
        width = width,
        height = canvas.height(),
        child = render.Column(cross_align = "center", children = children),
    )

def beside_logo(width, scale):
    """How much room there is beside the logo."""
    return width - render.Image(src = (MAILCOW_LOGO_2X if scale == 2 else MAILCOW_LOGO).readall()).size()[0] - 2 * scale

def small(text, color, width, fonts):
    return render.Text(fit(text, fonts["small"], width), font = fonts["small"], color = color)

def versions_row(old, new, width, fonts):
    """e.g. "2026-10 > 2026-11b". If that's too wide for the display, without the spaces, then with short years
    ("26-10 > 26-11b")."""

    def width_of(parts):
        total = 0
        for text in parts:
            total += render.Text(text, font = fonts["small"]).size()[0]
        return total

    short_old, short_new = old[2:], new[2:]
    choices = [[old, " > ", new], [old, ">", new], [short_old, " > ", short_new], [short_old, ">", short_new]]
    parts = choices[-1]
    for choice in choices:
        if width_of(choice) <= width:
            parts = choice
            break
    return render.Row(
        children = [
            render.Text(parts[0], font = fonts["small"], color = MUTED),
            render.Text(parts[1], font = fonts["small"], color = MUTED),
            render.Text(parts[2], font = fonts["small"], color = WHITE),
        ],
    )

def release_day(published, tz):
    """e.g. "19 Nov" for "2026-11-19T16:47:32Z", in the display's time zone."""
    if not published:
        return ""
    return time.parse_time(published).in_location(tz).format("2 Jan")

def render_card(card, width, scale, fonts, tz):
    if card["kind"] in ("error", "info"):
        color = RED if card["kind"] == "error" else MUTED
        subtitle = small(card["name"], MUTED, beside_logo(width, scale), fonts) if card["name"] else None
        text = render.WrappedText(card["text"], font = fonts["small"], color = color, width = width, align = "center")
        return page(subtitle, [text], width, scale, fonts)

    lines = [versions_row(card["from"], card["to"], width, fonts)]
    if card["name"]:
        lines.append(small(card["name"], WHITE, width, fonts))

    # A square display has room to say when the new release came out.
    day = release_day(card.get("released", ""), tz)
    if day and canvas.width() == canvas.height():
        lines.append(render.Box(width = 1, height = 3))
        lines.append(small("Released " + day, MUTED, width, fonts))
    return page(render.Text("UPDATE", font = fonts["title"], color = AMBER), lines, width, scale, fonts)

def render_up_to_date(versions, width, scale, fonts):
    detail = versions[0] if len(versions) == 1 else "All %d servers" % len(versions)
    subtitle = small("Up to date", GREEN, beside_logo(width, scale), fonts)
    return page(subtitle, [small(detail, MUTED, width, fonts)], width, scale, fonts)

def animate(pages):
    """The pages one after another, each held for a few seconds, repeated to fill at least MIN_ANIMATION_MS."""
    frames = []
    for p in pages:
        frames.extend([p] * PAGE_FRAMES)
    length = len(frames) * FRAME_DELAY
    rounds = (MIN_ANIMATION_MS + length - 1) // length if len(pages) > 1 else 1
    return render.Animation(children = frames * rounds)

def main(config):
    width, height = canvas.size()
    scale = 2 if canvas.is2x() else 1
    fonts = {
        "title": "terminus-16" if scale == 2 else "tb-8",
        "small": "tb-8" if scale == 2 else "tom-thumb",
    }

    servers = servers_from(config)
    if not servers and not config.get("$tz"):
        # No settings, e.g. in `pixlet check` or a preview: show an example.
        cards = [
            {"kind": "update", "name": "mail.example.com", "from": "2026-10", "to": "2026-11b", "released": "2026-11-19T16:47:32Z"},
            {"kind": "update", "name": "Work mail", "from": "2026-11a", "to": "2026-11b", "released": "2026-11-19T16:47:32Z"},
        ]
        up_to_date = []
    elif not servers:
        cards = [{"kind": "error", "name": "", "text": "Add your mailcow server in the settings"}]
        up_to_date = []
    else:
        cards, up_to_date = cards_for(servers, releases())
        if config.bool("only_when_update", True):
            cards = [card for card in cards if card["kind"] != "info"]

    if cards:
        tz = config.get("$tz") or "UTC"
        pages = [render_card(card, width, scale, fonts, tz) for card in cards]
        child = pages[0] if len(pages) == 1 else animate(pages)
    elif config.bool("only_when_update", True):
        return []
    else:
        child = render_up_to_date(up_to_date, width, scale, fonts)

    return render.Root(
        delay = FRAME_DELAY,
        show_full_animation = len(cards) > 1,
        child = render.Box(width = width, height = height, child = child),
    )

def server_fields(count):
    count = int(count) if count.isdigit() else 1
    fields = []
    for n in range(1, min(count, MAX_SERVERS) + 1):
        label = " (server %d)" % n if count > 1 else ""
        fields.append(schema.Text(
            id = "address_%d" % n,
            name = "mailcow address" + label,
            desc = "The address you use for the mailcow web UI, starting with https://, e.g. https://mail.example.com",
            icon = "server",
        ))
        fields.append(schema.Text(
            id = "api_key_%d" % n,
            name = "Read-only API key" + label,
            desc = "Create one in mailcow under System > Configuration > Access > Administrators > API. See the app's README.",
            icon = "key",
            secret = True,
        ))
        if count > 1:
            fields.append(schema.Text(
                id = "nickname_%d" % n,
                name = "Nickname" + label + " (optional)",
                desc = "Shown on the display to tell your servers apart. Leave empty to show the domain name.",
                icon = "tag",
            ))
    return fields

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "only_when_update",
                name = "Only show when there's an update",
                desc = "Turn off to also show when your servers are up to date, so you can see it's working. Problems are always shown.",
                icon = "eyeSlash",
                default = True,
            ),
            schema.Dropdown(
                id = "server_count",
                name = "Number of mailcow servers",
                desc = "How many mailcow servers to check.",
                icon = "layerGroup",
                default = "1",
                options = [schema.Option(display = str(n), value = str(n)) for n in range(1, MAX_SERVERS + 1)],
            ),
            schema.Generated(
                id = "servers",
                source = "server_count",
                handler = server_fields,
            ),
        ],
    )
