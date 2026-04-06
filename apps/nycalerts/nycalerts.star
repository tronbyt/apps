# NYC Emergency Alerts Tidbyt App
# Author: Rosie Domenech
# Date: April 2026
# Description: Scrolls live NYC emergency alerts from the official
#              Notify NYC / Everbridge RSS feed on your Tidbyt 64x32 display.

load("cache.star", "cache")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

RSS_URL = "https://feeds.everbridge.net/feeds/453003085617722/rss/rss.xml"
CACHE_KEY = "nycalerts_v1"
CACHE_TTL = 300  # 5 minutes — emergency data must be fresh

BLACK = "#000000"
WHITE = "#FFFFFF"
RED = "#FF2222"
BLUE = "#0055CC"
YELLOW = "#FFD700"
ORANGE = "#FF8800"
GREEN = "#00CC44"
DKBLUE = "#001A44"
DKRED = "#1A0000"

# Category color coding
CAT_COLORS = {
    "Infra": ORANGE,  # Infrastructure (gas, water, power)
    "Traffic": YELLOW,  # Traffic disruptions
    "Transit": BLUE,  # MTA/transit
    "Safety": RED,  # Emergency/safety
    "Health": GREEN,  # Public health
    "Weather": ORANGE,  # Weather
}

def parse_feed(body, max_items):
    """Parse English-only alerts from Notify NYC RSS feed."""
    alerts = []
    items = body.split("<item>")

    for item in items[1:]:
        # Only grab English alerts (filter out multilingual duplicates)
        author_start = item.find("<author>")
        author_end = item.find("</author>")
        if author_start == -1:
            continue
        author = item[author_start + 8:author_end]
        if "[English]" not in author:
            continue

        # Title
        t_start = item.find("<title>")
        t_end = item.find("</title>")
        if t_start == -1:
            continue
        title = item[t_start + 7:t_end].strip()
        if title.startswith("Notify NYC - "):
            title = title[13:]

        # Description
        d_start = item.find("<description>")
        d_end = item.find("</description>")
        desc = ""
        if d_start != -1:
            desc = item[d_start + 13:d_end].strip()

            # Strip HTML entities
            desc = desc.replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">")

            # Strip "To view this message in..." suffix
            cut = desc.find("To view this message in")
            if cut != -1:
                desc = desc[:cut].strip()

            # Strip "Notification issued..." prefix
            cut2 = desc.find("\n\n")
            if cut2 != -1 and cut2 < 60:
                desc = desc[cut2:].strip()

        # Category
        c_start = item.find("<category>")
        c_end = item.find("</category>")
        category = "Safety"
        if c_start != -1:
            category = item[c_start + 10:c_end].strip()

        if title:
            alerts.append({
                "title": title,
                "desc": desc,
                "category": category,
            })

        if len(alerts) >= max_items:
            break

    return alerts

def get_alerts(max_items):
    cached = cache.get(CACHE_KEY)
    if cached != None:
        parts = cached.split("|||")
        alerts = []
        for p in parts:
            if ":::" in p:
                bits = p.split(":::")
                if len(bits) >= 2:
                    alerts.append({
                        "title": bits[0],
                        "desc": bits[1] if len(bits) > 1 else "",
                        "category": bits[2] if len(bits) > 2 else "Safety",
                    })
        return alerts[:max_items]

    resp = http.get(RSS_URL, ttl_seconds = CACHE_TTL, headers = {
        "User-Agent": "tidbyt-nycalerts/1.0",
    })

    if resp.status_code != 200:
        return [{"title": "NYC alerts unavailable", "desc": "", "category": "Safety"}]

    alerts = parse_feed(resp.body(), max_items)

    if not alerts:
        return [{"title": "No active NYC alerts", "desc": "", "category": "Safety"}]

    cached_str = "|||".join([
        a["title"] + ":::" + a["desc"] + ":::" + a["category"]
        for a in alerts
    ])
    cache.set(CACHE_KEY, cached_str, ttl_seconds = CACHE_TTL)
    return alerts

def alert_color(category):
    return CAT_COLORS.get(category, RED)

def main(config):
    max_alerts = int(config.get("max_alerts") or "5")
    alerts = get_alerts(max_alerts)
    total = len(alerts)
    no_alerts = total == 1 and "No active" in alerts[0]["title"]

    # Build one screen per alert cycling through
    screens = []
    for _, alert in enumerate(alerts):
        color = GREEN if no_alerts else alert_color(alert.get("category", "Safety"))
        header_bg = "#003300" if no_alerts else DKRED

        # Use description if available, otherwise title
        ticker_text = alert["desc"] if alert["desc"] else alert["title"]
        if not ticker_text:
            ticker_text = alert["title"]

        screen = render.Column(
            children = [
                # ── Header ──────────────────────────────────
                render.Box(
                    width = 64,
                    height = 11,
                    color = header_bg,
                    child = render.Column(
                        children = [
                            render.Padding(
                                pad = (2, 1, 0, 0),
                                child = render.Text(
                                    content = "NYC ALERTS",
                                    font = "CG-pixel-3x5-mono",
                                    color = WHITE,
                                ),
                            ),
                            render.Padding(
                                pad = (2, 1, 0, 0),
                                child = render.Marquee(
                                    width = 60,
                                    offset_start = 0,
                                    offset_end = 0,
                                    child = render.Text(
                                        content = alert["title"],
                                        font = "CG-pixel-3x5-mono",
                                        color = color,
                                    ),
                                ),
                            ),
                        ],
                    ),
                ),
                # ── Divider ─────────────────────────────────
                render.Box(width = 64, height = 1, color = color),
                # ── Scrolling description ────────────────────
                render.Box(
                    width = 64,
                    height = 20,
                    color = BLACK,
                    child = render.Padding(
                        pad = (0, 4, 0, 0),
                        child = render.Marquee(
                            width = 64,
                            offset_start = 64,
                            offset_end = 64,
                            child = render.Text(
                                content = ticker_text,
                                font = "tb-8",
                                color = WHITE,
                            ),
                        ),
                    ),
                ),
            ],
        )
        screens.append(screen)

    return render.Root(
        delay = 50,
        child = render.Sequence(children = screens),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "max_alerts",
                name = "Number of Alerts",
                desc = "How many recent NYC alerts to cycle through",
                icon = "triangleExclamation",
                default = "5",
                options = [
                    schema.Option(display = "3 alerts", value = "3"),
                    schema.Option(display = "5 alerts", value = "5"),
                    schema.Option(display = "8 alerts", value = "8"),
                ],
            ),
        ],
    )
