"""
Applet: News
Summary: News feed display
Description: Select an RSS feed and receive the latest headlines in return.
Author: JeffLac (Recreation of Tidbyt Original)
"""

load("http.star", "http")
load("images/bbc.png", BBC_LOGO_ASSET = "file")
load("images/la_times_logo.png", LA_TIMES_LOGO_ASSET = "file")
load("images/wsj_logo.png", WSJ_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("xpath.star", "xpath")

# News source logos as base64-encoded images
BBC_LOGO = BBC_LOGO_ASSET.readall()
LA_TIMES_LOGO = LA_TIMES_LOGO_ASSET.readall()
WSJ_LOGO = WSJ_LOGO_ASSET.readall()

# News sources and their RSS feeds
NEWS_SOURCES = {
    # BBC feeds
    "BBC": {
        "url": "https://feeds.bbci.co.uk/news/rss.xml",
        "logo": BBC_LOGO,
    },
    "BBC Business": {
        "url": "https://feeds.bbci.co.uk/news/business/rss.xml",
        "logo": BBC_LOGO,
    },
    "BBC Education": {
        "url": "https://feeds.bbci.co.uk/news/education/rss.xml",
        "logo": BBC_LOGO,
    },
    "BBC Entertainment": {
        "url": "https://feeds.bbci.co.uk/news/entertainment_and_arts/rss.xml",
        "logo": BBC_LOGO,
    },
    "BBC Health": {
        "url": "https://feeds.bbci.co.uk/news/health/rss.xml",
        "logo": BBC_LOGO,
    },
    "BBC Politics": {
        "url": "https://feeds.bbci.co.uk/news/politics/rss.xml",
        "logo": BBC_LOGO,
    },
    "BBC Science": {
        "url": "https://feeds.bbci.co.uk/news/science_and_environment/rss.xml",
        "logo": BBC_LOGO,
    },
    "BBC Technology": {
        "url": "https://feeds.bbci.co.uk/news/technology/rss.xml",
        "logo": BBC_LOGO,
    },
    "BBC UK": {
        "url": "https://feeds.bbci.co.uk/news/uk/rss.xml",
        "logo": BBC_LOGO,
    },
    "BBC World": {
        "url": "https://feeds.bbci.co.uk/news/world/rss.xml",
        "logo": BBC_LOGO,
    },

    # LA Times feeds
    "LA Times": {
        "url": "https://www.latimes.com/rss2.0.xml",
        "logo": LA_TIMES_LOGO,
    },
    "LA Times Business": {
        "url": "https://www.latimes.com/business/rss2.0.xml",
        "logo": LA_TIMES_LOGO,
    },
    "LA Times California": {
        "url": "https://www.latimes.com/california/rss2.0.xml",
        "logo": LA_TIMES_LOGO,
    },
    "LA Times Entertainment": {
        "url": "https://www.latimes.com/entertainment-arts/rss2.0.xml",
        "logo": LA_TIMES_LOGO,
    },
    "LA Times Politics": {
        "url": "https://www.latimes.com/politics/rss2.0.xml",
        "logo": LA_TIMES_LOGO,
    },
    "LA Times Science": {
        "url": "https://www.latimes.com/science/rss2.0.xml",
        "logo": LA_TIMES_LOGO,
    },
    "LA Times Sports": {
        "url": "https://www.latimes.com/sports/rss2.0.xml",
        "logo": LA_TIMES_LOGO,
    },
    "LA Times World": {
        "url": "https://www.latimes.com/world-nation/rss2.0.xml",
        "logo": LA_TIMES_LOGO,
    },

    # WSJ feeds
    "WSJ US Business": {
        "url": "https://feeds.a.dj.com/rss/WSJcomUSBusiness.xml",
        "logo": WSJ_LOGO,
    },
    "WSJ Markets": {
        "url": "https://feeds.content.dowjones.io/public/rss/RSSMarketsMain",
        "logo": WSJ_LOGO,
    },
    "WSJ Technology": {
        "url": "https://feeds.a.dj.com/rss/RSSWSJD.xml",
        "logo": WSJ_LOGO,
    },
    "WSJ World": {
        "url": "https://feeds.a.dj.com/rss/RSSWorldNews.xml",
        "logo": WSJ_LOGO,
    },
}

# Default settings
DEFAULT_COLORS = {
    "date": "#ff0000",  # Red for date text
    "headline": "#ffcc00",  # Yellow for headlines
    "desc": "#ffffff",  # White for descriptions
}

# Cache time in seconds
CACHE_TTL = 900  # 15 minutes

def main(config):
    # Get the selected news source from config (default to BBC News)
    source_name = config.get("source", "BBC News")
    source_info = NEWS_SOURCES.get(source_name)

    if not source_info:
        return render.Root(
            child = render.Text("News source not found"),
        )

    # Get the current date in the desired format (e.g., "13 Mar")
    now = time.now()
    date_text = "%d %s" % (now.day, now.format("Jan")[:3])

    # Fetch and parse the RSS feed
    headlines = get_headlines(source_info["url"])

    if headlines == None or len(headlines) == 0:
        return render.Root(
            child = render.Text("Failed to load news"),
        )

    # Create header with logo and centered, larger date
    header = render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",  # Vertically center the elements
        children = [
            render.Image(src = source_info["logo"], width = 31, height = 15),
            render.Text(
                date_text,
                color = config.get("date_color", DEFAULT_COLORS["date"]),
                font = "5x8",
            ),
        ],
    )

    # Create text display for the first headline only
    headline_widget = render.Column(
        children = [
            # Title in yellow
            render.WrappedText(
                content = headlines[0]["title"],
                color = config.get("headline_color", DEFAULT_COLORS["headline"]),
                width = 64,
            ),
            # Description in white
            render.WrappedText(
                content = headlines[0]["description"],
                color = config.get("desc_color", DEFAULT_COLORS["desc"]),
                width = 64,
            ),
        ],
    )

    # Combine all elements into one scrollable column
    all_content = render.Column(
        children = [
            header,
            render.Box(width = 64, height = 1, color = "#333333"),  # Separator
            headline_widget,
        ],
    )

    # Render the full display with everything scrolling in one block
    return render.Root(
        delay = int(config.get("scroll_speed", "75")),
        child = render.Marquee(
            height = 32,  # Increased height to accommodate all content
            scroll_direction = "vertical",
            offset_start = 32,
            child = all_content,
        ),
    )

def get_headlines(feed_url):
    """Fetch and parse headlines from an RSS feed using xpath."""

    # Fetch the RSS feed
    resp = http.get(feed_url, ttl_seconds = CACHE_TTL)
    if resp.status_code != 200:
        return None

    # Parse the XML using xpath
    feed = xpath.loads(resp.body())

    # Extract titles and descriptions
    titles = feed.query_all("//item/title")
    descriptions = feed.query_all("//item/description")

    if len(titles) == 0 or len(descriptions) == 0:
        return None

    items = []

    # Changed: Only process the first item instead of multiple
    process_count = 1  # Only get the first item

    for i in range(process_count):
        title = titles[i]
        description = clean_html(descriptions[i])

        if title and description:
            items.append({
                "title": title,
                "description": description,
            })

    return items

def clean_html(text):
    """Remove HTML tags from text without loops."""

    # Use string.replace() repeatedly for commonly found HTML tags
    # (This is not comprehensive but handles common cases)
    cleaned = text

    # Replace common HTML tags with space
    common_tags = [
        "<p>",
        "</p>",
        "<div>",
        "</div>",
        "<span>",
        "</span>",
        "<strong>",
        "</strong>",
        "<em>",
        "</em>",
        "<a",
        "</a>",
        "<br>",
        "<br/>",
        "<br />",
        "<img",
        "/>",
        ">",
        "&nbsp;",
        "&amp;",
        "&quot;",
        "&lt;",
        "&gt;",
    ]

    for tag in common_tags:
        cleaned = cleaned.replace(tag, " ")

    # Handle any remaining tags with < and > by replacing blocks
    # Use string splitting as an alternative to loops
    parts = cleaned.split("<")
    if len(parts) > 1:
        result_parts = [parts[0]]

        for i in range(1, len(parts)):
            part = parts[i]
            tag_end = part.find(">")
            if tag_end >= 0:
                # Only keep text after the tag
                result_parts.append(part[tag_end + 1:])
            else:
                # No closing bracket, keep as is
                result_parts.append(part)

        cleaned = " ".join(result_parts)

    # Clean up excessive spaces by splitting and rejoining
    words = cleaned.split()
    return " ".join(words)

def get_schema():
    """Define the app configuration schema."""
    sources = []
    for name in NEWS_SOURCES:
        sources.append(
            schema.Option(
                display = name,
                value = name,
            ),
        )

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "source",
                name = "News Source",
                desc = "Select a news source to display headlines from.",
                icon = "newspaper",
                default = "BBC",
                options = sources,
            ),
        ],
    )
