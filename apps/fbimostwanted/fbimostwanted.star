"""
Applet: FBI Most Wanted
Summary: Top 10 Most Wanted by FBI
Description: Displays info on 10 most wanted criminals.
Author: Robert Ison
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")

FBI_BASE_URL = "https://api.fbi.gov/wanted/v1/list"
FBI_CACHE_NAME = "fbi_top_ten"
FBI_CACHE_TTL = 6 * 60 * 60  # 6 hours

FBI_BLUE = "#0033A0"  # Justice/loyalty (blue field)
FBI_GOLD = "#FFD61A"  # Value/history (stars, outlines, peaks)
FBI_RED = "#CF093F"  # Courage/valor/strength (red stripes)
FBI_WHITE = "#FFFFFF"  # Truth/light/peace (white stripes)

def safe_get(data, path):
    """Safely navigate nested dict access. Returns "" for missing keys or None values."""
    current = data
    for key in path:
        if type(current) != "dict" or key not in current:
            return ""
        current = current[key]
        if current == None or current == "None":
            return ""
    return current if current != None else ""

def clean_html(text):
    """Remove HTML tags recursively."""
    if not text:
        return ""
    if text.startswith("<"):
        end_tag = text.find(">")
        if end_tag != -1:
            return " " + clean_html(text[end_tag + 1:])
        return text
    return text[0] + clean_html(text[1:])

def cleanup_text(text):
    """Remove extra whitespace."""
    words = [w for w in text.split() if w]
    return " ".join(words)

def get_top_ten_wanted():
    cached = cache.get(FBI_CACHE_NAME)
    if cached != None:
        return json.decode(cached)

    all_items = []

    for page in range(1, 4):  # 4 pages
        url = "{}/?items=50&page={}".format(FBI_BASE_URL, page)

        resp = http.get(
            url = url,
            headers = {"Accept": "application/json", "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"},
            ttl_seconds = 0,  # We want fresh data after the cach expires, we don't want to cache the HTTP response
        )

        if resp.status_code != 200:
            print("Page {} failed: {}".format(page, resp.status_code))
            continue

        data = resp.json()
        if "items" in data:
            all_items.extend(data["items"])

    # Filter ONLY Ten Most Wanted
    top_ten = []
    for item in all_items:
        if "Ten Most Wanted Fugitives" in item.get("subjects", []):
            images = item.get("images", [])
            thumb = images[0].get("thumb", "") if len(images) > 0 else ""

            profile = {
                "title": safe_get(item, ["title"]),
                "reward_text": safe_get(item, ["reward_text"]),
                "thumbnail": thumb,
                "subjects": "; ".join(item.get("subjects", [])),
                "place_of_birth": safe_get(item, ["place_of_birth"]),
                "remarks": cleanup_text(clean_html(safe_get(item, ["remarks"]))),
                "uid": safe_get(item, ["uid"]),
            }

            top_ten.append(profile)

            if len(top_ten) >= 10:
                break  # Stop at 10

    # Cache refined Top 10 list
    cache.set(FBI_CACHE_NAME, json.encode(top_ten), FBI_CACHE_TTL)
    return top_ten

def main(config):
    top_ten = get_top_ten_wanted()

    if not top_ten:
        return render.Root(
            child = render.Text("No FBI data", color = "#ff0000"),
        )

    # Pick one at random
    selected = top_ten[random.number(0, len(top_ten) - 1)]

    if selected["thumbnail"] != "":
        artwork = http.get(selected["thumbnail"], headers = {"Accept": "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8", "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}, ttl_seconds = FBI_CACHE_TTL).body()
    else:
        artwork = None

    delay = int(config.get("scroll", "45"))
    if canvas.is2x():
        font = "terminus-16"
        image_width = 32
        font_width = 8
        delay = int(delay / 2)
    else:
        font = "5x8"
        image_width = 32
        font_width = 5

    row1 = selected["title"]
    row2 = "Reward: {}".format(selected["reward_text"])
    row3 = "Remarks: {}".format(selected["remarks"])
    row4 = "Place of Birth: {}".format(selected["place_of_birth"])

    return render.Root(
        child = render.Row(
            children = [
                render.Column(
                    children = [
                        render.Marquee(
                            width = int(canvas.width() - image_width),
                            child = render.Text(row1, font = font, color = FBI_GOLD),
                        ),
                        render.Marquee(
                            offset_start = len(row1) * font_width,
                            width = int(canvas.width() - image_width),
                            child = render.Text(row2, font = font, color = FBI_WHITE),
                        ),
                        render.Marquee(
                            offset_start = (len(row1) + len(row2)) * font_width,
                            width = int(canvas.width() - image_width),
                            child = render.Text(row3, font = font, color = FBI_RED),
                        ),
                        render.Marquee(
                            offset_start = (len(row1) + len(row2) + len(row3)) * font_width,
                            width = int(canvas.width()) - image_width,
                            child = render.Text(row4, font = font, color = FBI_BLUE),
                        ),
                    ],
                ),
                render.Image(src = artwork, width = 32) if selected["thumbnail"] != "" else render.Text("👮"),
            ],
        ),
        delay = delay,
        show_full_animation = True,
    )

def get_schema():
    scroll_speed_options = [
        schema.Option(
            display = "Slow Scroll",
            value = "60",
        ),
        schema.Option(
            display = "Medium Scroll",
            value = "45",
        ),
        schema.Option(
            display = "Fast Scroll",
            value = "30",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "scroll",
                name = "Scroll Speed",
                desc = "Speed of scrolling text.",
                icon = "clock",
                options = scroll_speed_options,
                default = "45",
            ),
        ],
    )
