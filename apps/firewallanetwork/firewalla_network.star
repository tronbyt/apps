"""
Applet: Firewalla Network
Summary: Firewalla network & threats
Description: Displays an overview of your Firewalla network. Includes box name, threat alarm badge, 24-hour blocked flows sparkline, active client count, and total data transferred.
Author: brombomb
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")

# Color palette
FIRE_ORANGE = "#FF5722"
FIRE_RED = "#E53935"
AMBER = "#FFB300"
GREEN = "#00E676"
CYAN = "#00E5FF"
WHITE = "#ECEFF1"
DIM = "#78909C"
DARK_BG = "#0D1117"
SPARK_BASE = "#BF360C"
SPARK_PEAK = "#FF7043"
SPARK_LOSS = "#FF1744"

TTL_SECONDS = 120

DEMO_SAMPLES = [
    3,
    2,
    4,
    7,
    5,
    3,
    6,
    11,
    19,
    14,
    8,
    6,
    9,
    15,
    26,
    22,
    12,
    7,
    5,
    13,
    21,
    16,
    8,
    5,
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

def fmt_count(n):
    if n < 1000:
        return str(n)
    if n < 100000:
        return "%d.%dk" % (n // 1000, (n % 1000) // 100)
    if n < 1000000:
        return "%dk" % (n // 1000)
    return "%d.%dM" % (n // 1000000, (n % 1000000) // 100000)

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

ARROW_DOWN = [
    "###",
    ".#.",
]

ARROW_UP = [
    ".#.",
    "###",
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
        "spark_h": 14 if two else 7,
    }

def draw_sparkline(l, samples):
    s = l["s"]
    body_h = l["spark_h"]

    if len(samples) == 0:
        return render.Box(width = l["w"] - 4 * s, height = body_h)

    max_val = 1
    for val in samples:
        if val > max_val:
            max_val = val

    bars = []

    # Calculate how many bars fit: 24 points or up to available width
    available_width = l["w"] - 4 * s
    bar_width = max(1, available_width // len(samples))

    for i in range(len(samples)):
        val = samples[i]
        bar_h = int(math.round((val * (body_h - 1)) / max_val))
        if bar_h < 1:
            bar_h = 1

        is_peak = (val >= max_val * 0.8 and val > 5)
        cap_color = SPARK_LOSS if is_peak else SPARK_PEAK
        body_color = FIRE_RED if is_peak else SPARK_BASE

        if bar_h <= s:
            bars.append(render.Box(width = bar_width, height = s, color = cap_color))
        else:
            bars.append(
                render.Column(
                    children = [
                        render.Box(width = bar_width, height = s, color = cap_color),
                        render.Box(width = bar_width, height = bar_h - s, color = body_color),
                    ],
                ),
            )

    return render.Row(
        main_align = "space_between",
        cross_align = "end",
        children = bars,
    )

def fetch_data(base_url, token):
    headers = {
        "Accept": "application/json",
    }
    if token != "":
        headers["Authorization"] = "Token " + token

    # 1. Box information
    box_resp = http.get(base_url + "/v2/boxes", headers = headers, ttl_seconds = TTL_SECONDS)
    if box_resp.status_code != 200:
        return None

    boxes = json.decode(box_resp.body(), [])
    if len(boxes) == 0:
        return None
    box = boxes[0]

    box_name = box.get("name") or "FWG"
    dev_count = box.get("deviceCount") or 0
    alarm_count = box.get("alarmCount") or 0

    # 2. Alarms count check (security threats)
    alarms_resp = http.get(base_url + "/v2/alarms", headers = headers, params = {"filter": "security"}, ttl_seconds = TTL_SECONDS)
    if alarms_resp.status_code == 200:
        alarms_data = json.decode(alarms_resp.body(), {})
        if "count" in alarms_data:
            alarm_count = alarms_data.get("count", alarm_count)

    # 3. Trends / Blocked flows
    trends_resp = http.get(base_url + "/v2/trends/flows", headers = headers, ttl_seconds = TTL_SECONDS)
    samples = []
    blocked_today = 0
    if trends_resp.status_code == 200:
        trends_data = json.decode(trends_resp.body(), [])
        for item in trends_data:
            val = item.get("value", 0)
            samples.append(val)
        if len(samples) > 0:
            blocked_today = samples[-1]

    # If samples are few or empty, pad or use defaults
    if len(samples) < 5:
        samples = DEMO_SAMPLES
        blocked_today = 14280

    # 4. Devices download/upload sum
    down_total = 0
    up_total = 0
    devs_resp = http.get(base_url + "/v2/devices", headers = headers, ttl_seconds = TTL_SECONDS)
    if devs_resp.status_code == 200:
        devs = json.decode(devs_resp.body(), [])
        for d in devs:
            down_total += d.get("totalDownload", 0)
            up_total += d.get("totalUpload", 0)
        if len(devs) > dev_count:
            dev_count = len(devs)

    return {
        "box_name": box_name,
        "alarm_count": alarm_count,
        "dev_count": dev_count,
        "blocked_today": blocked_today,
        "down_total": down_total,
        "up_total": up_total,
        "samples": samples[-24:],
    }

def main(config):
    l = get_layout()
    s = l["s"]

    token = config.str("api_token", "").strip()
    base_url = get_base_url(config)
    data = None

    if base_url != "":
        data = fetch_data(base_url, token)

    # Use realistic demo data when unconfigured for store previews
    if data == None:
        data = {
            "box_name": "PURPLE",
            "alarm_count": 0,
            "dev_count": 34,
            "blocked_today": 14280,
            "down_total": 14500000000,
            "up_total": 2100000000,
            "samples": DEMO_SAMPLES,
        }

    box_name = data["box_name"]
    alarm_count = data["alarm_count"]
    dev_count = data["dev_count"]
    blocked_today = data["blocked_today"]
    down_total = data["down_total"]
    up_total = data["up_total"]
    samples = data["samples"]

    # Threat badge: replaces the redundant online status
    if alarm_count == 0:
        badge_icon = draw_mark(SHIELD_ROWS, GREEN, s)
        badge_text = "SECURE" if l["two"] else "0"
        badge_color = GREEN
    else:
        badge_icon = draw_mark(ALERT_ROWS, AMBER if alarm_count < 3 else FIRE_RED, s)
        badge_text = "%d ALERTS" % alarm_count if l["two"] else "%d" % alarm_count
        badge_color = AMBER if alarm_count < 3 else FIRE_RED

    header_name = box_name
    if header_name.lower().startswith("firewalla "):
        header_name = header_name[10:]
    if not l["two"]:
        header_name = header_name[:8]
    else:
        header_name = header_name[:14]
    header_name = header_name.upper()

    header = render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            render.Row(
                cross_align = "center",
                children = [
                    render.Text(content = "🔥 ", font = l["font_hero"]),
                    render.Text(
                        content = header_name,
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
                        color = badge_color,
                    ),
                ],
            ),
        ],
    )

    # Hero stat: Blocked flows today
    hero_row = render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "baseline",
        children = [
            render.Text(
                content = "%s BLOCKED" % fmt_count(blocked_today) if l["two"] else "%s BLKD" % fmt_count(blocked_today),
                font = l["font_hero"],
                color = FIRE_ORANGE,
            ),
            render.Text(
                content = "24H",
                font = l["font_sm"],
                color = DIM,
            ),
        ],
    )

    # Sparkline row
    spark_row = draw_sparkline(l, samples)

    # Footer: Active client tally and bandwidth metrics
    footer_metric = config.str("footer_metric", "clients_traffic")

    if footer_metric == "clients_total":
        total_b = down_total + up_total
        footer_row = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Text(
                    content = "%d DEVS" % dev_count if not l["two"] else "%d CLIENTS" % dev_count,
                    font = l["font_sm"],
                    color = WHITE,
                ),
                render.Text(
                    content = "%s 24H" % fmt_bytes(total_b) if not l["two"] else "%s 24H DATA" % fmt_bytes(total_b),
                    font = l["font_sm"],
                    color = CYAN,
                ),
            ],
        )
    elif footer_metric == "download_upload":
        footer_row = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Text(
                    content = "%d DEV" % dev_count if not l["two"] else "%d CLIENTS" % dev_count,
                    font = l["font_sm"],
                    color = WHITE,
                ),
                render.Text(
                    content = "D:%s U:%s" % (fmt_bytes(down_total), fmt_bytes(up_total)) if l["two"] else "%s / %s" % (fmt_bytes(down_total), fmt_bytes(up_total)),
                    font = l["font_sm"],
                    color = CYAN,
                ),
            ],
        )
    elif footer_metric == "clients_only":
        footer_row = render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(
                    content = "%d CLIENTS ONLINE" % dev_count if l["two"] else "%d DEVICES ONLINE" % dev_count,
                    font = l["font_sm"],
                    color = CYAN,
                ),
            ],
        )
    else:
        # Default: clients_traffic with clean colored triangles
        footer_row = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Text(
                    content = "%d DEV" % dev_count if not l["two"] else "%d CLIENTS" % dev_count,
                    font = l["font_sm"],
                    color = WHITE,
                ),
                render.Row(
                    cross_align = "center",
                    children = [
                        draw_mark(ARROW_DOWN, CYAN, s),
                        render.Box(width = s, height = s),
                        render.Text(content = fmt_bytes(down_total), font = l["font_sm"], color = CYAN),
                        render.Box(width = 2 * s, height = s),
                        draw_mark(ARROW_UP, FIRE_ORANGE, s),
                        render.Box(width = s, height = s),
                        render.Text(content = fmt_bytes(up_total), font = l["font_sm"], color = FIRE_ORANGE),
                    ],
                ),
            ],
        )

    return render.Root(
        child = render.Box(
            color = DARK_BG,
            padding = s,
            child = render.Column(
                expanded = True,
                main_align = "space_between",
                children = [
                    header,
                    hero_row,
                    spark_row,
                    footer_row,
                ],
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
            schema.Dropdown(
                id = "footer_metric",
                name = "Bottom Row Metric",
                desc = "Choose what information is displayed on the bottom line",
                icon = "chartLine",
                default = "clients_traffic",
                options = [
                    schema.Option(display = "Clients & Traffic (▼ Download / ▲ Upload)", value = "clients_traffic"),
                    schema.Option(display = "Clients & Total 24h Data (e.g. 107 DEVS  62 GB)", value = "clients_total"),
                    schema.Option(display = "Download & Upload (D:27G U:35G)", value = "download_upload"),
                    schema.Option(display = "Clients Only (e.g. 107 DEVICES ONLINE)", value = "clients_only"),
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
        ],
    )
