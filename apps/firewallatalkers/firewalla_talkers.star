"""
Applet: Firewalla Top Talkers
Summary: Top bandwidth consumers
Description: Displays top bandwidth-consuming devices on your Firewalla network. Supports toggling between the last hour and the last 24 hours to spot active hogs or daily heavy hitters.
Author: brombomb
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

FIRE_ORANGE = "#FF5722"
FIRE_RED = "#E53935"
AMBER = "#FFB300"
CYAN = "#00E5FF"
WHITE = "#ECEFF1"
DIM = "#78909C"
DARK_BG = "#0D1117"
BAR_BG = "#1F2633"

BAR_COLORS = ["#FF5722", "#FFA726", "#42A5F5"]

TTL_SECONDS = 60

DEMO_TALKERS_1H = [
    {"name": "Apple TV 4K", "total": 1975000000, "download": 1910000000, "upload": 65000000},
    {"name": "Work MacBook", "total": 880000000, "download": 540000000, "upload": 340000000},
    {"name": "Gaming PC", "total": 430000000, "download": 400000000, "upload": 30000000},
]

DEMO_TALKERS_24H = [
    {"name": "Apple TV 4K", "total": 15890000000, "download": 15300000000, "upload": 590000000},
    {"name": "Home Server", "total": 9120000000, "download": 3200000000, "upload": 5920000000},
    {"name": "Gaming PC", "total": 5420000000, "download": 5100000000, "upload": 320000000},
]

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

def fmt_bytes(b):
    if b < 1024:
        return "%dB" % b
    if b < 1048576:
        return "%dK" % (b // 1024)
    if b < 1073741824:
        mb = b // 1048576
        if mb < 10:
            return "%d.%dM" % (mb, ((b % 1048576) * 10) // 1048576)
        return "%dM" % mb
    gb = b // 1073741824
    if gb < 10:
        return "%d.%dG" % (gb, ((b % 1073741824) * 10) // 1073741824)
    return "%dG" % gb

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
        "bar_h": 2 * s,
        "delay": 25 if two else 50,
    }

def fetch_talkers(base_url, token, period):
    headers = {
        "Accept": "application/json",
    }
    if token != "":
        headers["Authorization"] = "Token " + token

    now = time.now().unix
    window_sec = 3600 if period == "1h" else 86400
    begin = now - window_sec
    end = now

    # Try flows API grouped by device
    query = "ts:%d-%d" % (begin, end)
    flows_resp = http.get(
        base_url + "/v2/flows",
        headers = headers,
        params = {
            "period": period,
            "query": query,
            "limit": "3",
            "sortBy": "total:desc",
            "groupBy": "device",
        },
        ttl_seconds = TTL_SECONDS,
    )

    talkers = []
    if flows_resp.status_code == 200:
        flows_data = json.decode(flows_resp.body(), {})
        results = flows_data.get("results", [])
        for f in results:
            dev = f.get("device", {})
            name = dev.get("name") or dev.get("ip") or "Unknown"
            total = f.get("total", 0)
            down = f.get("download", 0)
            up = f.get("upload", 0)
            if total > 0:
                talkers.append({"name": name, "total": total, "download": down, "upload": up})

    # Fallback to /v2/devices if flows endpoint returned no aggregated records
    if len(talkers) == 0:
        devs_resp = http.get(base_url + "/v2/devices", headers = headers, ttl_seconds = TTL_SECONDS)
        if devs_resp.status_code == 200:
            devs = json.decode(devs_resp.body(), [])

            # Sort devices by totalDownload + totalUpload
            sorted_devs = []
            for d in devs:
                down = d.get("totalDownload", 0)
                up = d.get("totalUpload", 0)
                total = down + up
                name = d.get("name") or d.get("ip") or "Unknown"
                if total > 0:
                    sorted_devs.append({"name": name, "total": total, "download": down, "upload": up})

            # Simple insertion sort for top 3
            for i in range(len(sorted_devs)):
                for j in range(i + 1, len(sorted_devs)):
                    if sorted_devs[j]["total"] > sorted_devs[i]["total"]:
                        tmp = sorted_devs[i]
                        sorted_devs[i] = sorted_devs[j]
                        sorted_devs[j] = tmp
            talkers = sorted_devs[:3]

    return talkers

def render_device_row(l, rank, dev, max_bytes, color):
    s = l["s"]
    two = l["two"]
    name = dev["name"]
    total = dev["total"]

    track_w = l["w"] - (2 * s)
    bar_w = int(math.round((total * track_w) / max_bytes)) if max_bytes > 0 else 2
    if bar_w < 2 * s:
        bar_w = 2 * s
    if bar_w > track_w:
        bar_w = track_w

    num_text = "%d." % rank
    name_max_len = 16 if two else 9
    display_name = name if len(name) <= name_max_len else name[:name_max_len]

    text_line = render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            render.Row(
                cross_align = "center",
                children = [
                    render.Text(content = num_text, font = l["font_sm"], color = color),
                    render.Box(width = s, height = s),
                    render.Text(content = display_name, font = l["font_sm"], color = WHITE),
                ],
            ),
            render.Text(content = fmt_bytes(total), font = l["font_sm"], color = color),
        ],
    )

    bar_line = render.Row(
        children = [
            render.Box(width = bar_w, height = s, color = color),
            render.Box(width = track_w - bar_w, height = s, color = "#172338"),
        ],
    )

    return render.Column(
        children = [
            text_line,
            bar_line,
        ],
    )

def main(config):
    l = get_layout()
    s = l["s"]

    token = config.str("api_token", "").strip()
    period = config.str("period", "1h")
    if period not in ("1h", "24h"):
        period = "1h"

    base_url = get_base_url(config)
    talkers = []

    if base_url != "":
        talkers = fetch_talkers(base_url, token, period)

    if len(talkers) == 0:
        talkers = DEMO_TALKERS_1H if period == "1h" else DEMO_TALKERS_24H

    max_bytes = talkers[0]["total"] if len(talkers) > 0 else 1

    # Header with window badge
    badge_label = "1 HR" if period == "1h" else "24 HR"
    badge_color = CYAN if period == "1h" else FIRE_ORANGE

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
                        content = "TOP TALKERS" if l["two"] else "TALKERS",
                        font = l["font_mid"],
                        color = WHITE,
                    ),
                ],
            ),
            render.Text(
                content = badge_label,
                font = l["font_sm"],
                color = badge_color,
            ),
        ],
    )

    children = [header]
    for i in range(min(3, len(talkers))):
        color = BAR_COLORS[i % len(BAR_COLORS)]
        children.append(render_device_row(l, i + 1, talkers[i], max_bytes, color))

    return render.Root(
        child = render.Box(
            color = DARK_BG,
            padding = s,
            child = render.Column(
                expanded = True,
                main_align = "space_between",
                children = children,
            ),
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
            schema.Dropdown(
                id = "period",
                name = "Time Window",
                desc = "Select the period for bandwidth tracking",
                icon = "clock",
                default = "1h",
                options = [
                    schema.Option(display = "Last 1 Hour (Active Hogs)", value = "1h"),
                    schema.Option(display = "Last 24 Hours (Daily Total)", value = "24h"),
                ],
            ),
        ],
    )
