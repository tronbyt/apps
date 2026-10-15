"""
Applet: Tronbyt Server Updates
Summary: Tronbyt Server updates
Description: Shows when a new version of Tronbyt Server is available, comparing the version your server is running with the latest release on GitHub.
Author: saltedlolly
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("hash.star", "hash")
load("http.star", "http")
load("images/ok.png", OK_ICON = "file")
load("images/ok@2x.png", OK_ICON_2X = "file")
load("images/tronbyt.png", TRONBYT_LOGO = "file")
load("images/tronbyt@2x.png", TRONBYT_LOGO_2X = "file")
load("re.star", "re")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

# Apps run inside the Tronbyt server, which listens on port 8000 unless it's been changed
DEFAULT_SERVER_URL = "http://localhost:8000"
RELEASES_URL = "https://api.github.com/repos/tronbyt/server/releases/latest"

# How often to check GitHub for a new release, and the server's own version. The server's version only changes
# when it's updated, so it's rechecked often only while it's behind the latest release, so the update message goes
# soon after the server is updated.
RELEASE_TTL = 6 * 60 * 60
SERVER_TTL = 6 * 60 * 60
SERVER_TTL_WHILE_BEHIND = 5 * 60

AMBER = "#ffaa00"
GREEN = "#3cdc5a"
RED = "#ff5050"
WHITE = "#ffffff"
MUTED = "#999999"

def version_numbers(version):
    """[2, 4, 0] for "v2.4.0" or "2.4.0-rc1", or None if it isn't a version."""
    found = re.match(r"^v?(\d+)\.(\d+)\.(\d+)", version)
    if not found:
        return None
    return [int(n) for n in found[0][1:4]]

def server_version(base, latest):
    """The version the server shows at the bottom of its pages, e.g. "Server v2.4.0", from its login page, which
    doesn't need a login. Later, the server may be able to give apps its version directly."""
    key = "tronbyt-server-version-%s" % hash.sha256(base)
    saved = cache.get(key)
    if saved:
        saved = json.decode(saved)
        behind = latest and version_numbers(saved["version"]) and version_numbers(latest) > version_numbers(saved["version"])
        if not behind or time.now().unix - saved["checked"] < SERVER_TTL_WHILE_BEHIND:
            return saved["version"], None

    resp = http.get(base + "/auth/login")
    if resp.status_code != 200:
        return None, "Tronbyt server error %d" % resp.status_code

    # The footer reads e.g. "Server v2.4.0 (<a ...>eb1a5ae</a>)". "Server" can be translated, so look for a
    # version on its own line just before the commit link or the end of the footer.
    found = re.match(r"(?m)^\S*\s*(v\d+\.\d+\.\d+[^\s<(]*)\s*(\(<a|</div>)", resp.body())
    if not found:
        return None, "Can't find the server's version"
    version = found[0][1]
    cache.set(key, json.encode({"version": version, "checked": time.now().unix}), ttl_seconds = SERVER_TTL)
    return version, None

def latest_release():
    """The latest Tronbyt Server release on GitHub, e.g. "v2.5.0". The last one found is remembered, so a GitHub
    outage or rate limit doesn't stop the app."""
    resp = http.get(RELEASES_URL, headers = {"Accept": "application/vnd.github+json"}, ttl_seconds = RELEASE_TTL)
    if resp.status_code == 200:
        tag = resp.json().get("tag_name", "")
        if version_numbers(tag):
            cache.set("tronbyt-server-latest", tag, ttl_seconds = 30 * 24 * 60 * 60)
            return tag
    return cache.get("tronbyt-server-latest")

def check(base):
    """The server's version and the latest release.

    A request to a server that can't be reached stops the app with an error, which Starlark can't catch, so the
    display would just skip it. To show that instead, a note is left in the cache before contacting the server and
    cleared afterwards. If a run finds the note still there, the last attempt failed: it says so, and leaves the next
    run to try again.
    """
    attempt = "tronbyt-server-attempt-%s" % hash.sha256(base)
    if cache.get(attempt) == "started":
        cache.set(attempt, "", ttl_seconds = 60)
        return None, None, "Can't connect to your Tronbyt server or GitHub"
    cache.set(attempt, "started", ttl_seconds = 24 * 60 * 60)
    latest = latest_release()
    current, error = server_version(base, latest)
    cache.set(attempt, "", ttl_seconds = 60)

    if error:
        return None, None, error
    if not version_numbers(current):
        return None, None, "Can't read the server's version"
    if not latest:
        return None, None, "Can't check GitHub for new versions"
    return current, latest, None

def logo(scale):
    return render.Image(src = (TRONBYT_LOGO_2X if scale == 2 else TRONBYT_LOGO).readall())

def centred(width, scale, children):
    """The logo above some lines, in the middle of the display."""
    return render.Box(
        width = width,
        height = canvas.height(),
        child = render.Column(
            cross_align = "center",
            children = [logo(scale), render.Box(width = 1, height = 2 * scale)] + children,
        ),
    )

def render_update(current, latest, width, scale, fonts):
    return centred(width, scale, [
        render.Text("UPDATE", font = fonts["title"], color = AMBER),
        render.Box(width = 1, height = scale),
        render.Row(
            children = [
                render.Text(current, font = fonts["small"], color = MUTED),
                render.Text(" > ", font = fonts["small"], color = MUTED),
                render.Text(latest, font = fonts["small"], color = WHITE),
            ],
        ),
        render.Box(width = 1, height = scale),
        render.Text("Tronbyt Server", font = fonts["small"], color = MUTED),
    ])

def render_up_to_date(current, width, scale, fonts):
    return centred(width, scale, [
        render.Row(
            cross_align = "center",
            children = [
                render.Image(src = (OK_ICON_2X if scale == 2 else OK_ICON).readall()),
                render.Box(width = 2 * scale, height = 1),
                render.Text("UP TO DATE", font = fonts["title"], color = GREEN),
            ],
        ),
        render.Box(width = 1, height = scale),
        render.Text("Server " + current, font = fonts["small"], color = MUTED),
    ])

def render_message(text, width, scale, fonts):
    return centred(width, scale, [render.WrappedText(text, font = fonts["small"], color = RED, width = width, align = "center")])

def main(config):
    width, height = canvas.size()
    scale = 2 if canvas.is2x() else 1
    fonts = {
        "title": "terminus-16" if scale == 2 else "tb-8",
        "small": "tb-8" if scale == 2 else "tom-thumb",
    }

    # The setting defaults to the usual address. With no address at all (in the app store's preview), show an example.
    base = config.str("server_url", "").strip().rstrip("/")
    if not base:
        current, latest, error = "v2.4.0", "v2.5.0", None
    else:
        if not (base.startswith("http://") or base.startswith("https://")):
            base = "http://" + base
        current, latest, error = check(base)

    if error:
        child = render_message(error, width, scale, fonts)
    elif version_numbers(latest) > version_numbers(current):
        child = render_update(current, latest, width, scale, fonts)
    elif config.bool("only_when_update", True):
        return []
    else:
        child = render_up_to_date(current, width, scale, fonts)

    return render.Root(child = render.Box(width = width, height = height, child = child))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "only_when_update",
                name = "Only show when there's an update",
                desc = "Turn off to also show when your server is up to date, so you can see it's working",
                icon = "eyeSlash",
                default = True,
            ),
            schema.Text(
                id = "server_url",
                name = "Server address",
                desc = "Where the app can reach your Tronbyt server. The default works unless your server uses a different port.",
                icon = "server",
                default = DEFAULT_SERVER_URL,
            ),
        ],
    )
