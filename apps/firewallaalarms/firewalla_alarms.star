"""
Applet: Firewalla Security
Summary: Firewalla security & alarms
Description: Displays real-time security status and active alarms for your Firewalla network. Features an alert ticker when threats occur and an all-clear shield status when secure.
Author: brombomb
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")

FIRE_RED = "#FF1744"
FIRE_ORANGE = "#FF5722"
AMBER = "#FFB300"
GREEN = "#00E676"
CYAN = "#00E5FF"
WHITE = "#ECEFF1"
DIM = "#78909C"
DARK_BG = "#0D1117"
ALERT_BG = "#1C0A0A"
SAFE_BG = "#0A1812"

TTL_SECONDS = 60

DEMO_ALARMS = [
    {
        "aid": 101,
        "message": "Abnormal Upload: Work-MacBook (3.8 GB)",
        "ts": 1725380000,
    },
    {
        "aid": 102,
        "message": "New Device: Unknown ESP32 (192.168.1.189)",
        "ts": 1725382000,
    },
]

SHIELD_ROWS = [
    "#####",
    "#...#",
    "#####",
    ".###.",
    "..#..",
]

ALERT_ROWS = [
    "..#..",
    ".###.",
    "##.##",
    "#####",
]

def draw_mark(rows, color, s):
    children = []
    for r in rows:
        cells = []
        for ch in r.codepoints():
            if ch == "#":
                cells.append(render.Box(width = s, height = s, color = color))
            else:
                cells.append(render.Box(width = s, height = s, color = "#00000000"))
        children.append(render.Row(children = cells))
    return render.Column(children = children)

def get_base_url(config):
    source = config.str("source", "local")
    if source == "local":
        raw = config.str("local_url", "").strip()
        if raw == "":
            raw = config.str("domain", "").strip()
        if raw == "":
            return ""
        if not raw.startswith("http://") and not raw.startswith("https://"):
            raw = "http://" + raw
        return raw.rstrip("/")
    else:
        raw = config.str("domain", "").strip()
        if raw == "":
            raw = config.str("local_url", "").strip()
        if raw == "":
            return ""
        if not raw.startswith("http://") and not raw.startswith("https://"):
            raw = "https://" + raw
        host = raw.split("://")[-1]
        if "." not in host and ":" not in host:
            raw = raw + ".firewalla.net"
        return raw.rstrip("/")

def get_layout():
    two = canvas.is2x()
    s = 2 if two else 1
    w = canvas.width()
    h = canvas.height()
    return {
        "two": two,
        "s": s,
        "w": w,
        "h": h,
        "font_sm": "Dina_r400-6" if two else "tom-thumb",
        "font_mid": "6x10" if two else "CG-pixel-3x5-mono",
        "font_hero": "terminus-16" if two else "tb-8",
        "delay": 25 if two else 50,
        "track_w": w - (2 * s),
    }

def fetch_alarms(base_url, token, alert_filter):
    headers = {
        "Accept": "application/json",
    }
    if token != "":
        headers["Authorization"] = "Token " + token

    params = {}
    if alert_filter == "security":
        params["filter"] = "security"

    alarms_resp = http.get(base_url + "/v2/alarms", headers = headers, params = params, ttl_seconds = TTL_SECONDS)
    if alarms_resp.status_code != 200:
        return None

    alarms_data = json.decode(alarms_resp.body(), {})
    results = alarms_data.get("results", [])

    # Filter client-side as well in case backend returns raw alarms
    filtered = []
    for a in results:
        atype = (a.get("type") or "").upper()
        msg = (a.get("message") or "").lower()
        if alert_filter == "security":
            is_sec = (
                "INTEL" in atype or
                "SECURITY" in atype or
                "VULNERABILITY" in atype or
                "OPENPORT" in atype or
                "SPOOFING" in atype or
                "BLOCKED" in atype or
                "blocked" in msg or
                "suspicious" in msg or
                "malware" in msg or
                "exploit" in msg
            )
            if is_sec:
                filtered.append(a)
        else:
            filtered.append(a)

    results = filtered
    count = len(results)

    return {
        "count": count,
        "alarms": results,
    }

def render_alarm_state(l, alarm_count, alarms):
    s = l["s"]
    two = l["two"]

    first_msg = alarms[0]["message"] if len(alarms) > 0 else "Security alert detected"

    badge_icon = draw_mark(ALERT_ROWS, FIRE_RED, s)
    badge_text = "%d ALERTS" % alarm_count if two else "%d" % alarm_count

    header = render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            render.Row(
                cross_align = "center",
                children = [
                    render.Text(content = "🔥 ", font = l["font_sm"]),
                    render.Text(
                        content = "SECURITY" if two else "ALERT",
                        font = l["font_mid"],
                        color = WHITE,
                    ),
                ],
            ),
            render.Row(
                cross_align = "center",
                children = [
                    badge_icon,
                    render.Box(width = 2 * s, height = s),
                    render.Text(
                        content = badge_text,
                        font = l["font_sm"],
                        color = FIRE_RED,
                    ),
                ],
            ),
        ],
    )

    # Scrolling message box with explicit height
    content_area = render.Box(
        color = ALERT_BG,
        height = 42 if two else 21,
        padding = s,
        child = render.Column(
            cross_align = "start",
            main_align = "center",
            children = [
                render.Row(
                    cross_align = "center",
                    children = [
                        draw_mark(ALERT_ROWS, AMBER, s),
                        render.Box(width = 2 * s, height = s),
                        render.Text(
                            content = "THREAT DETECTED" if two else "THREAT",
                            font = l["font_sm"],
                            color = AMBER,
                        ),
                    ],
                ),
                render.Box(width = s, height = 2 * s),
                render.Marquee(
                    width = l["track_w"] - 2 * s,
                    delay = l["delay"],
                    child = render.Text(
                        content = first_msg,
                        font = l["font_mid"] if two else l["font_sm"],
                        color = WHITE,
                    ),
                ),
            ],
        ),
    )

    return render.Column(
        expanded = True,
        main_align = "space_between",
        children = [
            header,
            content_area,
        ],
    )

def render_secure_state(l):
    s = l["s"]
    two = l["two"]

    badge_icon = draw_mark(SHIELD_ROWS, GREEN, s)
    badge_text = "SECURE" if two else "OK"

    header = render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            render.Row(
                cross_align = "center",
                children = [
                    render.Text(content = "🔥 ", font = l["font_sm"]),
                    render.Text(
                        content = "SECURITY",
                        font = l["font_mid"],
                        color = WHITE,
                    ),
                ],
            ),
            render.Row(
                cross_align = "center",
                children = [
                    badge_icon,
                    render.Box(width = 2 * s, height = s),
                    render.Text(
                        content = badge_text,
                        font = l["font_sm"],
                        color = GREEN,
                    ),
                ],
            ),
        ],
    )

    center_area = render.Box(
        color = SAFE_BG,
        height = 42 if two else 21,
        padding = s,
        child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Column(
                    cross_align = "start",
                    children = [
                        render.Text(content = "ALL CLEAR", font = l["font_hero"], color = GREEN),
                        render.Text(content = "0 active threats", font = l["font_sm"], color = DIM),
                    ],
                ),
                draw_mark(SHIELD_ROWS, GREEN, 2 * s if two else s),
            ],
        ),
    )

    return render.Column(
        expanded = True,
        main_align = "space_between",
        children = [
            header,
            center_area,
        ],
    )

def main(config):
    l = get_layout()
    s = l["s"]

    token = config.str("api_token", "").strip()
    only_on_alerts = config.bool("only_on_alerts", False)
    alert_filter = config.str("alert_filter", "security")

    base_url = get_base_url(config)
    data = None

    if base_url != "":
        data = fetch_alarms(base_url, token, alert_filter)

    if data == None:
        data = {
            "count": 1,
            "alarms": DEMO_ALARMS,
        }

    alarm_count = data["count"]
    alarms = data["alarms"]

    # Silent sentinel mode: return [] if user configured to only show during active alarms
    if only_on_alerts and alarm_count == 0:
        return []

    if alarm_count > 0:
        content = render_alarm_state(l, alarm_count, alarms)
    else:
        content = render_secure_state(l)

    return render.Root(
        child = render.Box(
            color = DARK_BG,
            padding = s,
            child = content,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "source",
                name = "Connection Mode",
                desc = "Select whether to connect via Local Docker Bridge (MSP Lite / LAN) or Firewalla Cloud MSP.",
                icon = "networkWired",
                default = "local",
                options = [
                    schema.Option(display = "Local Bridge (Docker / LAN)", value = "local"),
                    schema.Option(display = "Firewalla Cloud MSP (Paid Plan)", value = "cloud"),
                ],
            ),
            schema.Text(
                id = "local_url",
                name = "Bridge Address",
                desc = "Local bridge address (e.g. http://192.168.1.50:7153)",
                icon = "server",
                default = "http://192.168.1.1:7153",
            ),
            schema.Dropdown(
                id = "alert_filter",
                name = "Alert Filter",
                desc = "Choose which alarms to display on screen",
                icon = "filter",
                default = "security",
                options = [
                    schema.Option(display = "Security Threats Only (Intel, Malware, Suspicious IPs)", value = "security"),
                    schema.Option(display = "All Active Alarms (including Video & Uploads)", value = "all"),
                ],
            ),
            schema.Text(
                id = "domain",
                name = "Cloud MSP Domain",
                desc = "Cloud mode only: your MSP domain (e.g. xyz.firewalla.net)",
                icon = "globe",
            ),
            schema.Text(
                id = "api_token",
                name = "API Token",
                desc = "Cloud mode only: Personal Access Token from MSP account settings",
                icon = "key",
                secret = True,
            ),
            schema.Toggle(
                id = "only_on_alerts",
                name = "Alerts Only (Silent Sentinel)",
                desc = "Only display in the Tronbyt carousel when active alarms exist",
                icon = "bell",
                default = False,
            ),
        ],
    )
