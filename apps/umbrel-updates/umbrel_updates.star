"""
Applet: Umbrel Updates
Summary: Updates for your Umbrel apps
Description: Shows which apps installed on your Umbrel home server have an update available. Needs umbrelOS 2.0 or later.
Author: saltedlolly
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("hash.star", "hash")
load("http.star", "http")
load("images/ok.png", OK_ICON = "file")
load("images/ok@2x.png", OK_ICON_2X = "file")
load("images/umbrel.png", UMBREL_LOGO = "file")
load("images/umbrel@2x.png", UMBREL_LOGO_2X = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")

# How this app identifies itself to umbrelOS. Umbrel shows it in the list of signed-in devices
# (Settings > Account), where its session can be signed out.
CLIENT = {
    "id": "tronbyt-umbrel-updates",
    "platform": "tronbyt",
    "deviceClass": "display",
    "appVersion": "1.0",
    "appBuild": "1",
    "osVersion": "pixlet",
}

# An access token lasts an hour; refresh it a little early
ACCESS_TOKEN_TTL = 50 * 60

# How often to ask the Umbrel for updates
RESULT_TTL = 10 * 60

AMBER = "#ffaa00"
GREEN = "#3cdc5a"
RED = "#ff5050"
WHITE = "#ffffff"
MUTED = "#999999"

# Shown when the app hasn't been set up, e.g. in the app store's preview
DEMO = {
    "installed": 18,
    "updates": [
        {"name": "Nextcloud", "version": "31.0.4"},
        {"name": "Immich", "version": "1.135.0"},
        {"name": "Home Assistant", "version": "2025.10.2"},
        {"name": "Jellyfin", "version": "10.10.7"},
    ],
}

def is_local_host(host):
    """umbrel.local and other .local names, or a private IPv4 address."""
    host = host.split(":")[0].lower()
    if host.endswith(".local") or host == "localhost":
        return True
    parts = host.split(".")
    if len(parts) != 4 or not all([p.isdigit() for p in parts]):
        return False
    a, b = int(parts[0]), int(parts[1])
    return a == 10 or a == 127 or (a == 192 and b == 168) or (a == 172 and b >= 16 and b <= 31)

def base_url(address):
    address = address.strip().rstrip("/")
    if not address:
        return ""
    if address.startswith("https://") and is_local_host(address[len("https://"):].split("/")[0]):
        # On your own network, Umbrel's HTTPS certificate is one that only your Umbrel trusts, so a Tronbyt server
        # can't check it. Its plain HTTP address works the same.
        address = "http://" + address[len("https://"):]
    elif not (address.startswith("http://") or address.startswith("https://")):
        address = "http://" + address
    return address

def refresh_access_token(base, device_token):
    """Swaps the long-lived device token for an access token, which lasts an hour."""
    resp = http.post(
        base + "/trpc/user.refreshNativeAccess",
        headers = {"Content-Type": "application/json"},
        json_body = {"deviceToken": device_token, "client": CLIENT},
    )
    if resp.status_code == 401:
        return None, "Umbrel didn't accept the device token"
    if resp.status_code == 404:
        return None, "Needs umbrelOS 2.0 or later"
    if resp.status_code != 200:
        return None, "Umbrel error %d" % resp.status_code
    return resp.json()["result"]["data"]["accessToken"], None

def query(base, path, access_token):
    resp = http.get(base + "/trpc/" + path, headers = {"Authorization": "Bearer " + access_token})
    if resp.status_code != 200:
        return resp.status_code, None
    return 200, resp.json()["result"]["data"]

def fetch_updates(base, device_token):
    """The apps with an update available, and how many apps are installed."""
    key = "umbrel-%s" % hash.sha256(base + "|" + device_token)
    cached = cache.get(key + "-result")
    if cached:
        return json.decode(cached), None

    access_token = cache.get(key + "-access")
    refreshed = False
    if not access_token:
        access_token, error = refresh_access_token(base, device_token)
        if error:
            return None, error
        refreshed = True

    status, updates = query(base, "apps.updates", access_token)
    if status == 401 and not refreshed:
        # Another copy of this app (e.g. on a second display) may have refreshed the token since
        access_token, error = refresh_access_token(base, device_token)
        if error:
            return None, error
        status, updates = query(base, "apps.updates", access_token)
    if status == 404:
        return None, "Needs umbrelOS 2.0 or later"
    if status != 200:
        return None, "Umbrel error %d" % status
    cache.set(key + "-access", access_token, ttl_seconds = ACCESS_TOKEN_TTL)

    # Names for the app IDs. Only the name of each app is used.
    names = {}
    installed = 0
    status, apps = query(base, "apps.list", access_token)
    if status == 200:
        for app in apps:
            installed += 1
            if app.get("name"):
                names[app["id"]] = app["name"]

    result = {
        "installed": installed,
        "updates": sorted(
            [{"name": names.get(u["id"], u["id"]), "version": u["version"]} for u in updates],
            key = lambda u: u["name"].lower(),
        ),
    }
    cache.set(key + "-result", json.encode(result), ttl_seconds = RESULT_TTL)
    return result, None

def plural(count, word):
    return "%d %s%s" % (count, word, "" if count == 1 else "s")

def umbrel_logo(scale):
    """Umbrel's logo, drawn as pixel art in Umbrel's purple."""
    return render.Image(src = (UMBREL_LOGO_2X if scale == 2 else UMBREL_LOGO).readall())

def render_updates(result, width, scale, fonts):
    updates = result["updates"]
    title = plural(len(updates), "update").upper()

    # "12 UPDATES" is too wide beside the logo on a 64-pixel-wide display, so use a smaller font from 10 updates
    title_font = fonts["title"] if scale == 2 or len(title) <= 9 else "tom-thumb"
    header = render.Row(
        cross_align = "center",
        children = [
            umbrel_logo(scale),
            render.Box(width = 2 * scale, height = 1),
            render.Text(title, font = title_font, color = AMBER),
        ],
    )

    rows = []
    for u in updates:
        rows.append(render.WrappedText(u["name"], font = fonts["name"], color = WHITE, width = width))
        rows.append(render.Text(u["version"], font = fonts["small"], color = MUTED))
        rows.append(render.Box(width = 1, height = 2 * scale))

    return render.Column(
        children = [
            header,
            render.Box(width = width, height = scale, color = "#333333"),
            render.Box(width = 1, height = scale),
            render.Marquee(
                width = width,
                height = canvas.height() - fonts["header_height"] - 2 * scale,
                scroll_direction = "vertical",
                offset_start = 0,
                offset_end = 0,
                child = render.Column(children = rows),
            ),
        ],
    )

def centred(width, scale, children):
    """The logo above some lines, in the middle of the display."""
    return render.Box(
        width = width,
        height = canvas.height(),
        child = render.Column(
            cross_align = "center",
            children = [umbrel_logo(scale), render.Box(width = 1, height = 3 * scale)] + children,
        ),
    )

def render_up_to_date(result, width, scale, fonts):
    lines = [
        render.Row(
            cross_align = "center",
            children = [
                render.Image(src = (OK_ICON_2X if scale == 2 else OK_ICON).readall()),
                render.Box(width = 2 * scale, height = 1),
                render.Text("UP TO DATE", font = fonts["title"], color = GREEN),
            ],
        ),
    ]
    if result["installed"]:
        lines.append(render.Box(width = 1, height = scale))
        lines.append(render.Text(plural(result["installed"], "app"), font = fonts["small"], color = MUTED))
    return centred(width, scale, lines)

def render_message(text, width, scale, fonts):
    return centred(width, scale, [render.WrappedText(text, font = fonts["small"], color = RED, width = width, align = "center")])

def main(config):
    width, height = canvas.size()
    scale = 2 if canvas.is2x() else 1
    fonts = {
        "title": "terminus-16" if scale == 2 else "tb-8",
        "name": "terminus-14" if scale == 2 else "tb-8",
        "small": "tb-8" if scale == 2 else "tom-thumb",
        "header_height": 16 if scale == 2 else 8,
    }

    base = base_url(config.str("umbrel_url", ""))
    device_token = config.str("device_token", "").strip()
    if not base or not device_token:
        result, error = DEMO, None
    else:
        result, error = fetch_updates(base, device_token)

    if error:
        child = render_message(error, width, scale, fonts)
    elif result["updates"]:
        child = render_updates(result, width, scale, fonts)
    elif config.bool("hide_when_up_to_date", False):
        return []
    else:
        child = render_up_to_date(result, width, scale, fonts)

    return render.Root(
        delay = 100 // scale,
        child = render.Box(width = width, height = height, child = child),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "umbrel_url",
                name = "Umbrel address",
                desc = "Your Umbrel's address on your network, e.g. http://192.168.1.100",
                icon = "server",
            ),
            schema.Text(
                id = "device_token",
                name = "Device token",
                desc = "From signing in to your Umbrel once (see the app's README)",
                icon = "key",
                secret = True,
            ),
            schema.Toggle(
                id = "hide_when_up_to_date",
                name = "Only show when there are updates",
                desc = "Skip this app when all your Umbrel apps are up to date",
                icon = "eyeSlash",
                default = False,
            ),
        ],
    )
