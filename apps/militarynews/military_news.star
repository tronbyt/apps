"""
Applet: Military News
Summary: Display Military News
Description: Displays Military News from Military.com.
Author: Robert Ison
"""

load("http.star", "http")  #HTTP Client
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("xpath.star", "xpath")  #XPath Expressions to read XML RSS Feed

CACHE_TTL_SECONDS = 86400  #1 Day

BRANCH_OPTIONS = [
    schema.Option(value = "air-force", display = "Air Force"),
    schema.Option(value = "army", display = "Army"),
    schema.Option(value = "coast-guard", display = "Coast Guard"),
    schema.Option(value = "marine-corps", display = "Marines"),
    schema.Option(value = "navy", display = "Navy"),
    schema.Option(value = "space-force", display = "Space Force"),
    schema.Option(display = "All Branches", value = "military"),
]

SCROLL_SPEED_OPTIONS = [
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

BRANCHES = [
    "air-force",
    "army",
    "coast-guard",
    "marine-corps",
    "navy",
    "space-force",
    "military",
]

BRANCH_COLOR_PALETTE = [
    # air-force
    ["#003594", "#B2B4B2", "#FFFFFF", "#FFC72C", "#FFC72C"],

    # army
    ["#FFCC01", "#F1E4C7", "#FFFFFF", "#7A8B6F", "#FFCC01"],

    # coast-guard
    ["#005DAA", "#FFFFFF", "#E6382F", "#9FD8FF", "#FFFFFF"],

    # marine-corps
    ["#CC101F", "#FFD500", "#FFFFFF", "#A77C29", "#FFD500"],

    # navy
    ["#E8B00F", "#C6CCD0", "#FFFFFF", "#088199", "#E8B00F"],

    # space-force
    ["#FFFFFF", "#C0C7D1", "#7FB3FF", "#8A8D8F", "#FFFFFF"],
]

BRANCH_FILTERS = {
    "air-force": [
        "air force topics",
        "air force bases",
        "air force",
        "airman",
        "airmen",
        "aircraft",
        "fighter aircraft",
        "attack aircraft",
        "surveillance aircraft",
        "unmanned aircraft systems",
    ],
    "army": [
        "><![cdata[army]]>",
        "army",
        "army rangers",
        "army training",
        "soldier",
        "soldiers",
        "west point",
    ],
    "coast-guard": [
        "coast guard",
        "uscg",
    ],
    "marine-corps": [
        "marine corps topics",
        "marine corps",
        "marine corps operations",
        "marine corps uniforms",
        "marine corps reserve",
        "marines",
    ],
    "navy": [
        "us navy topics",
        "navy",
        "sailor",
        "sailors",
        "fleet",
    ],
    "space-force": [
        "space force",
        "ussf",
        "guardian",
        "guardians",
    ],
}

def main(config):
    selected_branch = config.get("branch", BRANCH_OPTIONS[6].value)
    branch_index = BRANCHES.index(selected_branch)

    if selected_branch == "military":
        palette_index = randomize(0, len(BRANCHES) - 2)
        header = "All Branches"
    else:
        palette_index = branch_index
        header = BRANCH_OPTIONS[branch_index].display

    show_instructions = config.bool("instructions", False)
    if show_instructions:
        return show_instructions_screen(BRANCH_COLOR_PALETTE[palette_index], int(config.get("scroll", 45)))

    colors = BRANCH_COLOR_PALETTE[palette_index]
    rss_feed_url = "https://www.military.com/feed/daily-news/?viewMode=syndicationYahoo&articleCount=15"

    xml_data = get_military_news(rss_feed_url)
    if xml_data == None:
        return []

    number_of_items = xml_data.count("<item>")
    if number_of_items == 0:
        return []

    doc = xpath.loads(xml_data)

    item_blocks = xml_data.split("<item>")
    matching_items = []
    nonmatching_items = []

    for item_num in range(1, number_of_items + 1):
        raw_item = ""
        if item_num < len(item_blocks):
            raw_item = item_blocks[item_num].split("</item>")[0].lower()

        matched = False

        if selected_branch == "military":
            matched = True
        else:
            for keyword in BRANCH_FILTERS.get(selected_branch, []):
                if raw_item.find(keyword) >= 0:
                    matched = True
                    break

        if matched:
            matching_items.append(item_num)
        else:
            nonmatching_items.append(item_num)

    selected_items = []

    if selected_branch == "military":
        pool = matching_items[:]
        for _ in range(3):
            if len(pool) == 0:
                break
            pick_index = randomize(0, len(pool) - 1)
            selected_items.append(pool[pick_index])
            pool.pop(pick_index)
    elif len(matching_items) >= 3:
        pool = matching_items[:]
        for _ in range(3):
            if len(pool) == 0:
                break
            pick_index = randomize(0, len(pool) - 1)
            selected_items.append(pool[pick_index])
            pool.pop(pick_index)
    else:
        for item_num in matching_items:
            selected_items.append(item_num)

        pool = nonmatching_items[:]
        remaining_slots = 3 - len(selected_items)
        for _ in range(remaining_slots):
            if len(pool) == 0:
                break
            pick_index = randomize(0, len(pool) - 1)
            selected_items.append(pool[pick_index])
            pool.pop(pick_index)

    display_text_lines = []
    for item_num in selected_items:
        title = doc.query("//item[" + str(item_num) + "]/title") or ""
        display_text_lines.append(title)

    for _ in range(3 - len(display_text_lines)):
        display_text_lines.append("")

    return render.Root(
        render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    offset_start = 15,
                    child = render.Text(header, color = colors[4], font = "5x8"),
                ),
                render.Marquee(
                    width = 64,
                    offset_start = len(header) * 5,
                    child = render.Text(display_text_lines[0], color = colors[0], font = "5x8"),
                ),
                render.Marquee(
                    offset_start = len(display_text_lines[0]) * 5,
                    width = 64,
                    child = render.Text(display_text_lines[1], color = colors[1], font = "5x8"),
                ),
                render.Marquee(
                    offset_start = (len(display_text_lines[0]) + len(display_text_lines[1])) * 5,
                    width = 64,
                    child = render.Text(display_text_lines[2], color = colors[2], font = "5x8"),
                ),
            ],
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def get_military_news(rss):
    res = http.get(
        url = rss,
        headers = {
            "User-Agent": "curl/8.0",
            "Accept": "application/rss+xml, application/xml, text/xml, */*",
        },
        ttl_seconds = CACHE_TTL_SECONDS,
    )

    if res.status_code == 200:
        return res.body()
    else:
        return None

def show_instructions_screen(colors, delay):
    ##############################################################################################################################################################################################################################
    header = "Military News"
    instructions_1 = "Military.com hosts RSS feeds on Military specific news items from around the country. You select the branch of interest, or pick 'All Branches' to get news across all branches."
    instructions_2 = "The color display is based on the color palette of the branch of the news being presented. 3 random headlines will be presented at a time."
    instructions_3 = "To get more information on the artice titles presented, go to Military.com. "

    return render.Root(
        render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    offset_start = 15,
                    child = render.Text(header, color = colors[4], font = "5x8"),
                ),
                render.Marquee(
                    width = 64,
                    offset_start = len(header) * 5,
                    child = render.Text(instructions_1, color = colors[0]),
                ),
                render.Marquee(
                    offset_start = len(instructions_1) * 5,
                    width = 64,
                    child = render.Text(instructions_2, color = colors[1]),
                ),
                render.Marquee(
                    offset_start = (len(instructions_2) + len(instructions_1)) * 5,
                    width = 64,
                    child = render.Text(instructions_3, color = colors[2]),
                ),
            ],
        ),
        show_full_animation = True,
        delay = delay,
    )

def randomize(min, max):
    now = time.now()
    rand = int(str(now.nanosecond)[-6:-3]) / 1000
    return int(rand * (max + 1 - min) + min)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "instructions",
                name = "Show Instructions",
                desc = "",
                icon = "book",
                default = False,
            ),
            schema.Dropdown(
                id = "branch",
                name = "Branch",
                desc = "Military Branch",
                icon = "globe",
                options = BRANCH_OPTIONS,
                default = BRANCH_OPTIONS[0].value,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = SCROLL_SPEED_OPTIONS,
                default = SCROLL_SPEED_OPTIONS[0].value,
            ),
        ],
    )
