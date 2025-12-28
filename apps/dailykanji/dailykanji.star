"""
Applet: DailyKanji
Summary: Displays a random Kanji
Description: Displays a random Kanji character with translation.
Author: Robert Ison
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

# Sample fallback kanji data
KANJI_SAMPLE_DATA = """
{"character": "辛", "meaning": {"english": "pungent, hard, spicy"}, "onyomi": {"romaji": "shin"}, "kunyomi": {"romaji": "kara, karai, karasa"}}
"""

# URLs
KANJI_IMAGE_LOOKUP_URL = "https://assets.imgix.net/~text?w=150&h=150&txt-size=75&txt-color=ff0&txt-align=left&txt-font=Arial&txt64="
KANJI_ALIVE_URL = "https://kanjialive-api.p.rapidapi.com/api/public/kanji/{}"

# Cache
CACHE_PREFIX = "DailyKanji:v1:"
KANJI_TTL = 60 * 60 * 2  # 2 hours

# Kanji grouped by JLPT level (expandable)
KANJI_BY_LEVEL = {
    5: ["国", "日", "事", "人", "一", "見", "本", "子", "出", "年", "大", "言", "学", "分", "中", "記", "会", "新", "月", "時", "力", "気", "上", "下", "私", "二", "三", "四", "五", "六", "七", "八", "九", "十"],
    4: ["朝", "用", "書", "手", "間", "合", "方", "社", "検", "目", "関", "作", "特", "何", "体", "動", "集", "発", "最", "内", "法", "広", "来", "田", "理", "物", "開"],
    3: ["意", "能", "個", "僕", "通", "面", "回", "代", "利", "経", "使", "車", "編", "同", "平", "音", "読", "少", "食", "道", "世", "結", "真", "考", "公", "野"],
    2: ["信", "多", "更", "活", "選", "題", "屋", "論", "済", "有", "身", "線", "味", "著", "顔", "売", "空", "続", "第", "様", "海", "始", "校", "英", "勝"],
    1: ["想", "原", "指", "円", "店", "死", "容", "流", "過", "保", "町", "足", "介", "料", "安", "着", "健", "調", "芸", "違", "研", "古", "参", "番", "館"],
}

# Map dropdown values to JLPT numbers
LEVEL_TO_JLPT = {
    "beginner": 5,
    "elementary": 4,
    "intermediate": 3,
    "advanced": 2,
    "expert": 1,
}

def get_allowed_kanji(max_jlpt_level):
    """
    Return all kanji for selected level and easier levels.
    """
    allowed = []
    for level, kanji_list in KANJI_BY_LEVEL.items():
        if level >= max_jlpt_level:
            allowed.extend(kanji_list)
    return allowed

def get_random_kanji(allowed_kanji, max_jlpt_level):
    """
    Get a pseudo-random kanji based on the date. This ensures the same
    kanji is shown for the entire day for all users with the same settings,
    which is ideal for caching.
    """
    if not allowed_kanji:
        return "日"

    now = time.now()
    y = now.year
    m = now.month
    d = now.day
    seed = y * 10000 + m * 100 + d + max_jlpt_level

    # Lightweight integer hash (xorshift-style) to create a pseudo-random number
    x = seed
    x ^= x << 13
    x ^= x >> 17
    x ^= x << 5

    # Use the hash to pick an index within the bounds of the allowed_kanji list
    idx = x % len(allowed_kanji)
    return allowed_kanji[idx]

def get_kanji_information(selected_kanji, api_key):
    """
    Fetch kanji info from KanjiAlive API. Returns None if fails.
    """
    res = http.get(
        url = KANJI_ALIVE_URL.format(selected_kanji),
        headers = {
            "X-RapidAPI-Host": "kanjialive-api.p.rapidapi.com",
            "X-RapidAPI-Key": api_key,
        },
    )
    if res.status_code != 200:
        return None
    data = res.json()
    if not data or "kanji" not in data:
        return None
    return data["kanji"]

def add_padding(element, left = 0, top = 0, right = 0, bottom = 0):
    return render.Padding(pad = (left, top, right, bottom), child = element)

def main(config):
    SCREEN_WIDTH = canvas.width()

    if canvas.is2x():
        FONT = "6x10-rounded"
        FONT_HEIGHT = 10
        V_SPACING = 1
    else:
        FONT = "5x8"
        FONT_HEIGHT = 8
        V_SPACING = 2

    api_key = config.get("api_key", "")
    selected_level = config.get("max_level", "beginner")
    max_jlpt = LEVEL_TO_JLPT.get(selected_level, 5)

    # Cache keys per level
    cache_key_data = CACHE_PREFIX + "data:" + str(max_jlpt)
    cache_key_image = CACHE_PREFIX + "image:" + str(max_jlpt)

    # Load cache
    kanji_data_obj = None
    kanji_image_src = cache.get(cache_key_image)
    cached_data = cache.get(cache_key_data)
    if cached_data:
        kanji_data_obj = json.decode(cached_data)

    if kanji_data_obj == None:
        # Pick kanji from allowed levels
        allowed_kanji = get_allowed_kanji(max_jlpt)
        kanji_char = get_random_kanji(allowed_kanji, max_jlpt)

        # Try KanjiAlive API
        api_data = None
        if api_key != "":
            api_data = get_kanji_information(kanji_char, api_key)
        if api_data:
            kanji_data_obj = api_data
        else:
            # fallback
            # On failure, fall back to the complete static sample data.
            # This ensures the character, meaning, and readings are consistent.
            kanji_data_obj = json.decode(KANJI_SAMPLE_DATA)

        # Create image
        kanji_image_url = KANJI_IMAGE_LOOKUP_URL + base64.encode(kanji_data_obj["character"])
        kanji_image_src = http.get(kanji_image_url).body()

        # Cache results
        cache.set(cache_key_data, json.encode(kanji_data_obj), ttl_seconds = KANJI_TTL)
        cache.set(cache_key_image, kanji_image_src, ttl_seconds = KANJI_TTL)

    # Prepare rows
    meaning = kanji_data_obj.get("meaning", {}).get("english", "")
    onyomi = kanji_data_obj.get("onyomi", {}).get("romaji", "")
    kunyomi = kanji_data_obj.get("kunyomi", {}).get("romaji", "")

    if meaning == "n/a":
        meaning = ""
    if onyomi == "n/a":
        onyomi = ""
    if kunyomi == "n/a":
        kunyomi = ""

    rows = [meaning, onyomi, kunyomi]

    text_colors = ["#65d0e6", "#f4a306", "#e77c05"]

    display_items = []
    image_width = int(SCREEN_WIDTH + 1)

    # Vertically center the text block
    num_rows = len(rows)
    total_text_height = (num_rows * FONT_HEIGHT) + ((num_rows - 1) * V_SPACING)
    top_margin = (32 - total_text_height) // 2

    # Kanji image
    if canvas.is2x():
        display_items.append(add_padding(render.Image(
            height = image_width,
            width = image_width,
            src = kanji_image_src,
        ), -11, -27))
    else:
        display_items.append(add_padding(render.Image(
            height = image_width,
            width = image_width,
            src = kanji_image_src,
        ), -6, -13))

    # Meaning / On / Kun
    for i, row_text in enumerate(rows):
        display_items.append(add_padding(
            render.Marquee(width = int(SCREEN_WIDTH / 2), child = render.Text(row_text, color = text_colors[i], font = FONT)),
            left = int(SCREEN_WIDTH / 2),
            top = top_margin + i * (FONT_HEIGHT + V_SPACING),
        ))

    scroll_delay = int(config.get("scroll", "45"))
    return render.Root(
        render.Stack(children = display_items),
        show_full_animation = True,
        delay = scroll_delay // 2 if canvas.is2x() else scroll_delay,
    )

def get_schema():
    scroll_speed_options = [schema.Option(display = d, value = v) for d, v in [("Slow Scroll", "60"), ("Medium Scroll", "45"), ("Fast Scroll", "30")]]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "RapidAPI key for KanjiAlive (optional)",
                icon = "code",
                default = "",
                secret = True,
            ),
            schema.Dropdown(
                id = "max_level",
                name = "Difficulty Level",
                desc = "Show kanji up to this difficulty",
                icon = "graduationCap",
                options = [
                    schema.Option("Beginner", "beginner"),
                    schema.Option("Elementary", "elementary"),
                    schema.Option("Intermediate", "intermediate"),
                    schema.Option("Advanced", "advanced"),
                    schema.Option("Expert", "expert"),
                ],
                default = "beginner",
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll Speed",
                desc = "Speed of the scrolling text",
                icon = "scroll",
                options = scroll_speed_options,
                default = "45",
            ),
        ],
    )
