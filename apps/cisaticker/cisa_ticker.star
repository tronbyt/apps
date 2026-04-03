# CISA Alert Ticker
# Author: Rosie Domenech
# Date: April 2026
# Description: Shows top 3 CISA alerts simultaneously on the Tidbyt 64x32 display.
#              Each alert scrolls independently in its own row.

load("cache.star", "cache")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

CISA_RSS = "https://www.cisa.gov/uscert/ncas/alerts.xml"
CACHE_KEY = "cisa_alerts_v3"
CACHE_TTL = 1800  # 30 minutes

RED = "#CC0000"
YELLOW = "#FFD700"
WHITE = "#FFFFFF"
GOLD = "#FFD700"
BLUE = "#88CCFF"
BLACK = "#000000"
DIM = "#333333"

def get_alerts(max_alerts):
    cached = cache.get(CACHE_KEY)
    if cached != None:
        return cached.split("|||")[:max_alerts]

    resp = http.get(CISA_RSS, ttl_seconds = CACHE_TTL)
    if resp.status_code != 200:
        return ["CISA feed unavailable"]

    body = resp.body()
    titles = []

    items = body.split("<item>")
    for item in items[1:]:
        start = item.find("<title>")
        end = item.find("</title>")
        if start == -1 or end == -1:
            continue
        title = item[start + 7:end].strip()
        if title.startswith("<![CDATA["):
            title = title[9:]
        if title.endswith("]]>"):
            title = title[:-3]
        title = title.strip()
        if title:
            titles.append(title)
        if len(titles) >= 10:
            break

    if not titles:
        return ["No CISA alerts found"]

    cache.set(CACHE_KEY, "|||".join(titles), ttl_seconds = CACHE_TTL)
    return titles[:max_alerts]

def alert_row(text, color):
    return render.Box(
        width = 64,
        height = 7,
        color = BLACK,
        child = render.Padding(
            pad = (0, 1, 0, 0),
            child = render.Marquee(
                width = 64,
                offset_start = 64,
                offset_end = 64,
                child = render.Text(
                    content = text,
                    font = "tom-thumb",
                    color = color,
                ),
            ),
        ),
    )

def main(_):
    alerts = get_alerts(3)
    for _ in range(3 - len(alerts)):
        alerts.append("No further alerts")

    return render.Root(
        delay = 30,
        child = render.Column(
            children = [
                render.Box(
                    width = 64,
                    height = 8,
                    color = RED,
                    child = render.Padding(
                        pad = (3, 1, 0, 0),
                        child = render.Text(
                            content = "CISA TOP ALERTS",
                            font = "CG-pixel-3x5-mono",
                            color = WHITE,
                        ),
                    ),
                ),
                render.Box(width = 64, height = 1, color = YELLOW),
                alert_row(alerts[0], WHITE),
                render.Box(width = 64, height = 1, color = DIM),
                alert_row(alerts[1], GOLD),
                render.Box(width = 64, height = 1, color = DIM),
                alert_row(alerts[2], BLUE),
            ],
        ),
    )

def get_schema():
    return schema.Schema(version = "1", fields = [])
