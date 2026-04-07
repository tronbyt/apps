# FBI Most Wanted Ticker — Blue & Gold Edition
# Author: Rosie Domenech
# Date: April 2026
# Description: Live FBI Most Wanted ticker with classic FBI blue & gold colors.
#              Reward amount drives color brightness — higher reward = brighter gold.

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

FBI_API = "https://api.fbi.gov/wanted/v1/list"
CACHE_KEY = "fbiwanted_v2"
CACHE_TTL = 3600

# FBI Blue palette
NAVY = "#003087"  # deep FBI navy — header bg
BLUE = "#0044CC"  # mid blue
BLUE_LT = "#2266FF"  # lighter blue — divider

# Gold palette — brightness by reward
GOLD_DIM = "#887700"  # no reward
GOLD_LOW = "#BBAA00"  # < $25K
GOLD_MID = "#FFD700"  # $25K–$100K
GOLD_HIGH = "#FFE84D"  # $100K–$500K
GOLD_MAX = "#FFFFFF"  # $500K+ (white hot)

WHITE = "#FFFFFF"
BLACK = "#000000"
SILVER = "#CCCCDD"
RED = "#FF3333"  # armed & dangerous only

def reward_color(reward_max):
    """Return gold color based on reward amount."""
    if reward_max >= 500000:
        return GOLD_MAX
    if reward_max >= 100000:
        return GOLD_HIGH
    if reward_max >= 25000:
        return GOLD_MID
    if reward_max > 0:
        return GOLD_LOW
    return GOLD_DIM

def strip_html(text):
    out = ""
    inside = False
    for c in text.elems():
        if c == "<":
            inside = True
        elif c == ">":
            inside = False
        elif not inside:
            out = out + c
    return out.strip()

def format_reward(reward_max):
    if reward_max >= 1000000:
        return "$%dM" % (reward_max // 1000000)
    if reward_max >= 1000:
        return "$%dK" % (reward_max // 1000)
    if reward_max > 0:
        return "$%d" % reward_max
    return ""

def get_wanted(max_items, category):
    cache_key = CACHE_KEY + "_" + category
    cached = cache.get(cache_key)
    if cached:
        return json.decode(cached)[:max_items]

    url = FBI_API
    if category != "all":
        url = FBI_API + "?field_offices=" + category

    resp = http.get(url, ttl_seconds = CACHE_TTL, headers = {
        "User-Agent": "tidbyt-fbiwanted/2.0",
    })

    if resp.status_code != 200:
        return [{"name": "FBI API unavailable", "charges": "", "reward_max": 0, "reward_str": "", "armed": False, "caution": ""}]

    data = json.decode(resp.body())
    items = data.get("items", [])

    wanted = []
    for item in items:
        name = item.get("title", "Unknown") or "Unknown"
        subjects = item.get("subjects", []) or []
        charges = subjects[0] if subjects else ""
        reward_max = item.get("reward_max", 0) or 0
        reward_str = format_reward(reward_max)
        warning = item.get("warning_message", "") or ""
        armed = "ARMED" in warning.upper() or "DANGEROUS" in warning.upper()
        caution = strip_html(item.get("caution", "") or "")

        wanted.append({
            "name": name,
            "charges": charges,
            "reward_max": reward_max,
            "reward_str": reward_str,
            "armed": armed,
            "caution": caution[:120] if caution else charges,
        })

        if len(wanted) >= max_items:
            break

    if not wanted:
        return [{"name": "No results found", "charges": "", "reward_max": 0, "reward_str": "", "armed": False, "caution": ""}]

    cache.set(cache_key, json.encode(wanted), ttl_seconds = CACHE_TTL)
    return wanted

def person_screen(person):
    name = person.get("name", "Unknown")
    charges = person.get("charges", "")
    reward_max = person.get("reward_max", 0)
    reward_str = person.get("reward_str", "")
    armed = person.get("armed", False)
    caution = person.get("caution", "") or charges

    gold = reward_color(reward_max)

    # Name color: white if max reward, gold otherwise, red if armed
    name_color = RED if armed else gold

    # Build scrolling ticker
    parts = []
    if charges:
        parts.append(charges)
    if reward_str:
        parts.append("Reward: " + reward_str)
    if armed:
        parts.append("ARMED & DANGEROUS")
    if caution and caution != charges:
        parts.append(caution)
    ticker = "  //  ".join(parts) if parts else name

    return render.Column(
        children = [
            # ── Header — FBI Navy ────────────────────
            render.Box(
                width = 64,
                height = 11,
                color = NAVY,
                child = render.Column(
                    children = [
                        # "FBI MOST WANTED" in gold
                        render.Padding(
                            pad = (2, 1, 0, 0),
                            child = render.Text(
                                content = "FBI MOST WANTED",
                                font = "CG-pixel-3x5-mono",
                                color = gold,
                            ),
                        ),
                        # Name scrolling
                        render.Padding(
                            pad = (2, 1, 0, 0),
                            child = render.Marquee(
                                width = 60,
                                offset_start = 0,
                                offset_end = 0,
                                child = render.Text(
                                    content = name,
                                    font = "CG-pixel-3x5-mono",
                                    color = name_color,
                                ),
                            ),
                        ),
                    ],
                ),
            ),
            # ── Gold divider ─────────────────────────
            render.Box(width = 64, height = 1, color = gold),
            # ── Scrolling details on navy ─────────────
            render.Box(
                width = 64,
                height = 20,
                color = "#001155",
                child = render.Padding(
                    pad = (0, 4, 0, 0),
                    child = render.Marquee(
                        width = 64,
                        offset_start = 64,
                        offset_end = 64,
                        child = render.Text(
                            content = ticker,
                            color = gold,
                        ),
                    ),
                ),
            ),
        ],
    )

def main(config):
    max_items = int(config.get("max_items") or "5")
    category = config.get("category") or "all"
    wanted = get_wanted(max_items, category)
    screens = [person_screen(p) for p in wanted]

    return render.Root(
        delay = 50,
        child = render.Sequence(children = screens),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "max_items",
                name = "Number of Persons",
                desc = "How many wanted persons to display",
                icon = "userSecret",
                default = "5",
                options = [
                    schema.Option(display = "3 persons", value = "3"),
                    schema.Option(display = "5 persons", value = "5"),
                    schema.Option(display = "8 persons", value = "8"),
                ],
            ),
            schema.Dropdown(
                id = "category",
                name = "Field Office",
                desc = "Filter by FBI field office",
                icon = "building",
                default = "all",
                options = [
                    schema.Option(display = "All Offices", value = "all"),
                    schema.Option(display = "New York", value = "newyork"),
                    schema.Option(display = "Los Angeles", value = "losangeles"),
                    schema.Option(display = "Chicago", value = "chicago"),
                    schema.Option(display = "Washington DC", value = "washingtondc"),
                    schema.Option(display = "Miami", value = "miami"),
                ],
            ),
        ],
    )
