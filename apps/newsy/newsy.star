"""
Newsy — Tidbyt Pixlet applet.
64x32 RSS headline ticker. Up to 3 configurable feeds.
"""

load("render.star", "render")
load("http.star", "http")
load("schema.star", "schema")
load("xpath.star", "xpath")
load("random.star", "random")

DEFAULT_FEED1 = "https://news.google.com/rss?hl=en-US&gl=US&ceid=US:en"
DEFAULT_FEED2 = "https://feeds.bbci.co.uk/news/rss.xml"
DEFAULT_FEED3 = "https://feeds.npr.org/1001/rss.xml"
DEFAULT_FEED4 = "https://news.google.com/rss/search?q=source:%22Associated+Press%22&hl=en-US&gl=US&ceid=US:en"
DEFAULT_FEED5 = ""
DIVIDER = " +++ "
CACHE_TTL_SECONDS = 300

def main(config):
    delay = int(config.get("scroll_speed", "25"))
    max_items = int(config.get("max_items", "2"))
    font_size = config.get("font_size", "6x13")

    raw_feeds = [
        (config.get("feed1", DEFAULT_FEED1), _label_for(config.get("feed1", DEFAULT_FEED1), DEFAULT_FEED1, "GOOGLE", 1)),
        (config.get("feed2", DEFAULT_FEED2), _label_for(config.get("feed2", DEFAULT_FEED2), DEFAULT_FEED2, "BBC", 2)),
        (config.get("feed3", DEFAULT_FEED3), _label_for(config.get("feed3", DEFAULT_FEED3), DEFAULT_FEED3, "NPR", 3)),
        (config.get("feed4", DEFAULT_FEED4), _label_for(config.get("feed4", DEFAULT_FEED4), DEFAULT_FEED4, "AP", 4)),
        (config.get("feed5", DEFAULT_FEED5), _label_for(config.get("feed5", DEFAULT_FEED5), DEFAULT_FEED5, "CUSTOM", 5)),
    ]

    active_feeds = []
    for url, label in raw_feeds:
        if url and url.strip():
            active_feeds.append((url.strip(), label))

    if not active_feeds:
        current_feed_label = ""
        headlines = ["No active feeds"]
    else:
        randomize = config.get("random_start", "true") == "true"
        if randomize and len(active_feeds) > 1:
            start_idx = random.number(0, len(active_feeds) - 1)
            active_feeds = active_feeds[start_idx:] + active_feeds[:start_idx]

        current_url, current_feed_label = active_feeds[0]
        headlines = _fetch_titles(current_url, max_items)

    if not headlines:
        ticker = "No headlines available"
    else:
        ticker = DIVIDER.join(headlines)

    # Pixlet Marquee is horizontal by default: text enters from the right
    # and travels left (natural reading direction). There is no LTR reverse.
    return render.Root(
        delay = delay,
        child = render.Column(
            expanded = True,
            children = [
                render.Box(
                    height = 8,
                    color = "#111827",
                    child = render.Padding(
                        pad = (2, 1, 2, 0),
                        child = render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "center",
                            children = [
                                render.Text(
                                    content = "NEWSY",
                                    font = "tom-thumb",
                                    color = "#F87171",
                                ),
                                render.Text(
                                    content = current_feed_label,
                                    font = "tom-thumb",
                                    color = "#60A5FA",
                                ),
                            ],
                        ),
                    ),
                ),
                render.Box(height = 1, color = "#F87171"),
                render.Box(
                    height = 23,
                    color = "#020617",
                    child = render.Marquee(
                        width = 64,
                        offset_start = 64,
                        offset_end = 64,
                        child = render.Text(
                            content = ticker,
                            font = font_size,
                            color = "#E5E7EB",
                        ),
                    ),
                ),
            ],
        ),
    )

def _label_for(url, default_url, default_name, slot_num):
    url = url.strip() if url else ""
    if not url:
        return ""
    if url == default_url:
        return default_name
    elif url == DEFAULT_FEED1:
        return "GOOGLE"
    elif url == DEFAULT_FEED2:
        return "BBC"
    elif url == DEFAULT_FEED3:
        return "NPR"
    elif url == DEFAULT_FEED4:
        return "AP"
    else:
        return "FEED %d" % slot_num if slot_num < 5 else "CUSTOM"

def _fetch_titles(url, max_items):
    res = http.get(url, ttl_seconds = CACHE_TTL_SECONDS)
    if res.status_code != 200:
        return ["Feed unavailable"]

    body = res.body()
    if not body:
        return ["Empty feed"]

    doc = xpath.loads(body)
    titles = doc.query_all("/rss/channel/item/title")
    if not titles:
        titles = doc.query_all("//item/title")

    cleaned = []
    for title in titles:
        title = title.strip()
        if title:
            cleaned.append(title)
        if len(cleaned) >= max_items:
            break

    if not cleaned:
        return ["No items"]
    return cleaned

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "feed1",
                name = "Feed 1 (Google News)",
                desc = "RSS feed URL. Defaults to Google News Top Stories.",
                icon = "rss",
                default = DEFAULT_FEED1,
            ),
            schema.Text(
                id = "feed2",
                name = "Feed 2 (BBC News)",
                desc = "RSS feed URL. Defaults to BBC News Top Stories.",
                icon = "rss",
                default = DEFAULT_FEED2,
            ),
            schema.Text(
                id = "feed3",
                name = "Feed 3 (NPR)",
                desc = "RSS feed URL. Defaults to NPR News.",
                icon = "rss",
                default = DEFAULT_FEED3,
            ),
            schema.Text(
                id = "feed4",
                name = "Feed 4 (Associated Press)",
                desc = "RSS feed URL. Defaults to Associated Press Top Stories.",
                icon = "rss",
                default = DEFAULT_FEED4,
            ),
            schema.Text(
                id = "feed5",
                name = "Feed 5 (Custom)",
                desc = "Optional fifth RSS feed URL.",
                icon = "rss",
                default = DEFAULT_FEED5,
            ),
            schema.Dropdown(
                id = "scroll_speed",
                name = "Scroll speed",
                desc = "Marquee frame delay on the 64x32 display.",
                icon = "gaugeHigh",
                default = "25",
                options = [
                    schema.Option(display = "Slow (40ms)", value = "40"),
                    schema.Option(display = "Normal (30ms)", value = "30"),
                    schema.Option(display = "Fast (25ms)", value = "25"),
                    schema.Option(display = "Very Fast (15ms)", value = "15"),
                ],
            ),
            schema.Dropdown(
                id = "max_items",
                name = "Headlines per feed",
                desc = "How many titles to pull from the active feed per display cycle.",
                icon = "list",
                default = "2",
                options = [
                    schema.Option(display = "1", value = "1"),
                    schema.Option(display = "2", value = "2"),
                    schema.Option(display = "3", value = "3"),
                    schema.Option(display = "5", value = "5"),
                ],
            ),
            schema.Dropdown(
                id = "font_size",
                name = "Font size",
                desc = "Ticker text size on the lower display area.",
                icon = "textHeight",
                default = "6x13",
                options = [
                    schema.Option(display = "Large (6x13)", value = "6x13"),
                    schema.Option(display = "Extra Large (10x20)", value = "10x20"),
                    schema.Option(display = "Medium (6x10)", value = "6x10"),
                    schema.Option(display = "Small (5x8)", value = "5x8"),
                ],
            ),
            schema.Toggle(
                id = "random_start",
                name = "Randomize start feed",
                desc = "Randomly select which active feed loads first on each refresh.",
                icon = "shuffle",
                default = True,
            ),
        ],
    )
