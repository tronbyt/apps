"""
Applet: Ntfy Pulse Listener
Summary: Ambient alerts from ntfy
Description: Polls an ntfy topic for real-time push alerts, displaying urgent notifications or an ambient health pulse.
Author: brombomb
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/ntfy_icon.png", NTFY_ICON_ASSET = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")

NTFY_TEAL = "#439f8d"
ORANGE = "#ff8800"
RED = "#ff3333"
YELLOW = "#ffcc00"
GREEN = "#00ff66"
CYAN = "#0db7ed"
WHITE = "#ffffff"
MUTED = "#8899aa"
BG_COLOR = "#000000"

SAMPLE_ALERT = {
    "id": "sample_1",
    "time": 1725580000,
    "event": "message",
    "topic": "homelab-alerts",
    "title": "Homelab Incident",
    "message": "Uptime Kuma: Service [Plex] is DOWN",
    "priority": 4,
    "tags": ["warning"],
}

def get_priority_meta(p):
    if p >= 5:
        return {"label": "URGENT", "color": RED, "bg": "#330000"}
    elif p == 4:
        return {"label": "HIGH", "color": ORANGE, "bg": "#331500"}
    elif p == 3:
        return {"label": "ALERT", "color": YELLOW, "bg": "#332800"}
    elif p == 2:
        return {"label": "INFO", "color": CYAN, "bg": "#002033"}
    else:
        return {"label": "LOW", "color": MUTED, "bg": "#111822"}

def parse_topic_url(raw_topic, raw_server):
    """Extract server URL and clean topic name from a topic URL or raw topic string."""
    topic_str = raw_topic.strip() if raw_topic else ""
    server_str = raw_server.strip() if raw_server else "https://ntfy.sh"

    if topic_str.startswith("http://") or topic_str.startswith("https://"):
        url = topic_str
    elif "/" in topic_str:
        url = "https://" + topic_str
    else:
        url = None

    if url:
        parts = url.split("://", 1)
        protocol = parts[0]
        rest = parts[1]

        if "?" in rest:
            rest = rest.split("?")[0]
        if rest.endswith("/"):
            rest = rest[:-1]

        slash_idx = rest.find("/")
        if slash_idx != -1:
            server = protocol + "://" + rest[:slash_idx]
            path = rest[slash_idx + 1:].strip()
            for suffix in ["/json", "/sse", "/ws", "/raw"]:
                if path.endswith(suffix):
                    path = path[:-len(suffix)]
            return server, path
        else:
            return protocol + "://" + rest, ""

    server = server_str if server_str else "https://ntfy.sh"
    if server.endswith("/"):
        server = server[:-1]
    return server, topic_str

def is_image(data):
    """Safely validate image bytes for PNG, JPEG, GIF, or WebP."""
    if not data or len(data) < 8:
        return False
    if data[1:4] == "PNG":
        return True
    if data[:3] == "GIF":
        return True
    if data[:4] == "RIFF" and len(data) >= 12 and data[8:12] == "WEBP":
        return True
    if ord(data[0]) in [65533, 255] and ord(data[1]) in [65533, 216] and ord(data[2]) in [65533, 255]:
        return True
    return False

def fetch_icon(icon_url):
    """Fetch external notification icon with caching."""
    if not icon_url:
        return None
    cache_key = "ntfy_ico_data_" + icon_url
    cached = cache.get(cache_key)
    if cached:
        return cached

    res = http.get(icon_url, headers = {"User-Agent": "Tronbyt-ntfy-Pulse"}, ttl_seconds = 3600)
    if res.status_code == 200:
        body = res.body()
        if is_image(body):
            cache.set(cache_key, body, ttl_seconds = 3600)
            return body
    return None

def fetch_ntfy_messages(server_url, topic, auth_token, window_min):
    if not topic or topic.strip() == "":
        return [SAMPLE_ALERT]

    clean_server = server_url.strip() if server_url and server_url.strip() != "" else "https://ntfy.sh"
    if clean_server.endswith("/"):
        clean_server = clean_server[:-1]

    clean_topic = topic.strip()
    endpoint = "%s/%s/json?poll=1&since=%dm" % (clean_server, clean_topic, window_min)

    cache_key = "ntfy_" + endpoint
    cached = cache.get(cache_key)
    if cached:
        return json.decode(cached)

    headers = {"User-Agent": "Tronbyt-ntfy-Pulse"}
    if auth_token and auth_token.strip() != "":
        headers["Authorization"] = "Bearer " + auth_token.strip()

    res = http.get(endpoint, headers = headers, ttl_seconds = 30)
    if res.status_code != 200:
        print("Failed to query ntfy topic:", res.status_code, endpoint)
        return None

    raw_body = res.body()
    lines = raw_body.split("\n")
    messages = []
    for line in lines:
        cleaned = line.strip()
        if not cleaned:
            continue
        msg_obj = json.decode(cleaned)
        if msg_obj.get("event") == "message":
            messages.append(msg_obj)

    cache.set(cache_key, json.encode(messages), ttl_seconds = 30)
    return messages

def render_alert_view(scale, width, height, alert, icon_bytes, display_name, font_title, font_main, font_tiny):
    icon_width = 11 * scale
    icon_height = 11 * scale

    priority = alert.get("priority", 3)
    p_meta = get_priority_meta(priority)

    title = alert.get("title") or display_name or alert.get("topic") or "ntfy Alert"
    message = alert.get("message", "")

    header = render.Row(
        expanded = True,
        cross_align = "center",
        main_align = "space_between",
        children = [
            render.Row(
                cross_align = "center",
                children = [
                    render.Image(src = icon_bytes, width = icon_width, height = icon_height),
                    render.Box(width = 2 * scale, height = 1),
                    render.Text(title[:12 if scale == 1 else 18], font = font_title, color = WHITE),
                ],
            ),
            render.Box(
                color = p_meta["bg"],
                child = render.Padding(
                    pad = (2 * scale, 1 * scale, 2 * scale, 1 * scale),
                    child = render.Text(p_meta["label"], font = font_tiny, color = p_meta["color"]),
                ),
            ),
        ],
    )

    body_height = height - (14 * scale)
    bottom_label = display_name if display_name else "ntfy"

    return render.Column(
        expanded = True,
        children = [
            render.Padding(pad = (2 * scale, 1 * scale, 2 * scale, 1 * scale), child = header),
            render.Box(width = width, height = 1 * scale, color = p_meta["color"]),
            render.Box(
                width = width,
                height = body_height,
                color = "#150000" if priority >= 4 else "#00101a",
                child = render.Padding(
                    pad = (3 * scale, 2 * scale, 3 * scale, 2 * scale),
                    child = render.Column(
                        expanded = True,
                        main_align = "space_around",
                        cross_align = "start",
                        children = [
                            render.Marquee(
                                width = width - (6 * scale),
                                child = render.Text(message, font = font_main, color = p_meta["color"]),
                            ),
                            render.Row(
                                cross_align = "center",
                                main_align = "space_between",
                                expanded = True,
                                children = [
                                    render.Text("Active Alert", font = font_tiny, color = MUTED),
                                    render.Text(bottom_label[:12 if scale == 1 else 20], font = font_tiny, color = NTFY_TEAL),
                                ],
                            ),
                        ],
                    ),
                ),
            ),
        ],
    )

def render_ambient_pulse(scale, width, label, window_min, icon_bytes, font_title, font_main, font_tiny):
    icon_width = 11 * scale
    icon_height = 11 * scale

    header = render.Row(
        cross_align = "center",
        children = [
            render.Image(src = icon_bytes, width = icon_width, height = icon_height),
            render.Box(width = 3 * scale, height = 1),
            render.Text(label[:12 if scale == 1 else 20], font = font_title, color = NTFY_TEAL),
        ],
    )

    return render.Column(
        expanded = True,
        main_align = "space_between",
        children = [
            render.Padding(pad = (2 * scale, 2 * scale, 2 * scale, 0), child = header),
            render.Column(
                cross_align = "center",
                expanded = True,
                main_align = "center",
                children = [
                    render.Row(
                        cross_align = "center",
                        children = [
                            render.Text("♥ ", font = font_main, color = GREEN),
                            render.Text("PULSE OK", font = font_main, color = WHITE),
                        ],
                    ),
                    render.Text("No alerts in %dm" % window_min, font = font_tiny, color = MUTED),
                ],
            ),
            render.Box(width = width, height = 2 * scale, color = "#003b1e"),
        ],
    )

def main(config):
    width, height = canvas.size()
    scale = 2 if canvas.is2x() else 1

    font_title = "tb-8" if scale == 1 else "terminus-14"
    font_main = "tb-8" if scale == 1 else "terminus-14"
    font_tiny = "tom-thumb" if scale == 1 else "tb-8"

    raw_server = config.str("server_url", "https://ntfy.sh")
    raw_topic = config.str("topic", "")
    server_url, topic = parse_topic_url(raw_topic, raw_server)

    display_name = config.str("display_name", "").strip()
    auth_token = config.str("auth_token", "")
    window_min = int(config.str("window_minutes", "15"))
    quiet_when_idle = config.bool("quiet_when_idle", False)
    min_priority = int(config.str("min_priority", "3"))

    messages = fetch_ntfy_messages(server_url, topic, auth_token, window_min)

    if messages == None:
        return render.Root(
            child = render.Box(
                width = width,
                height = height,
                child = render.Column(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Text("ntfy Error", font = font_main, color = RED),
                        render.Text("Check URL / Topic", font = font_tiny, color = MUTED),
                    ],
                ),
            ),
        )

    # Filter messages meeting minimum priority
    valid_alerts = [m for m in messages if m.get("priority", 3) >= min_priority]

    # Resolve display label
    label = display_name if display_name else (topic if topic else "ntfy")
    default_icon = NTFY_ICON_ASSET.readall()

    if not valid_alerts:
        if quiet_when_idle:
            return []

        # Check if topic has a cached icon from a recent notification
        cached_icon = cache.get("ntfy_topic_ico_" + topic) if topic else None
        icon_bytes = cached_icon if cached_icon else default_icon

        root_child = render_ambient_pulse(
            scale,
            width,
            label,
            window_min,
            icon_bytes,
            font_title,
            font_main,
            font_tiny,
        )
    else:
        # Show newest alert
        latest_alert = valid_alerts[-1]

        # Extract icon from ntfy alert (explicit icon URL or image attachment)
        icon_url = latest_alert.get("icon")
        if not icon_url:
            att = latest_alert.get("attachment")
            if type(att) == "dict" and att.get("type", "").startswith("image/"):
                icon_url = att.get("url")

        icon_bytes = None
        if icon_url and type(icon_url) == "string":
            icon_url = icon_url.strip()
            if icon_url.startswith("/"):
                icon_url = server_url + icon_url
            if icon_url.startswith("http://") or icon_url.startswith("https://"):
                icon_bytes = fetch_icon(icon_url)

        if icon_bytes:
            if topic:
                cache.set("ntfy_topic_ico_" + topic, icon_bytes, ttl_seconds = 86400)
        else:
            cached_icon = cache.get("ntfy_topic_ico_" + topic) if topic else None
            icon_bytes = cached_icon if cached_icon else default_icon

        root_child = render_alert_view(
            scale,
            width,
            height,
            latest_alert,
            icon_bytes,
            display_name,
            font_title,
            font_main,
            font_tiny,
        )

    delay = 40 // scale
    return render.Root(
        delay = delay,
        child = render.Box(
            width = width,
            height = height,
            color = BG_COLOR,
            child = root_child,
        ),
    )

def get_schema():
    priority_options = [
        schema.Option(display = "Any Priority (1+)", value = "1"),
        schema.Option(display = "Low+ (2+)", value = "2"),
        schema.Option(display = "Default+ (3+)", value = "3"),
        schema.Option(display = "High+ (4+)", value = "4"),
        schema.Option(display = "Urgent Only (5)", value = "5"),
    ]

    window_options = [
        schema.Option(display = "5 Minutes", value = "5"),
        schema.Option(display = "15 Minutes", value = "15"),
        schema.Option(display = "30 Minutes", value = "30"),
        schema.Option(display = "60 Minutes", value = "60"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "topic",
                name = "Topic or URL",
                desc = "ntfy topic URL (e.g. https://ntfy.sh/mytopic) or topic name",
                icon = "bell",
            ),
            schema.Text(
                id = "display_name",
                name = "Display Name",
                desc = "Custom display name for header (e.g. Homelab, Alerts)",
                icon = "tag",
            ),
            schema.Text(
                id = "auth_token",
                name = "Access Token (Optional)",
                desc = "Token for private or protected topics",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "server_url",
                name = "ntfy Server (Optional)",
                desc = "Server base URL if not included in topic URL (default https://ntfy.sh)",
                icon = "server",
                default = "https://ntfy.sh",
            ),
            schema.Dropdown(
                id = "window_minutes",
                name = "Alert Window",
                desc = "How long an alert remains visible",
                icon = "clock",
                default = "15",
                options = window_options,
            ),
            schema.Dropdown(
                id = "min_priority",
                name = "Minimum Priority",
                desc = "Only display alerts with at least this priority",
                icon = "triangleExclamation",
                default = "3",
                options = priority_options,
            ),
            schema.Toggle(
                id = "quiet_when_idle",
                name = "Quiet When Idle",
                desc = "Skip rendering when there are no active alerts",
                icon = "bellSlash",
                default = False,
            ),
        ],
    )
