"""
Applet: Trivia
Summary: Random trivia question
Description: Displays a random trivia question with category and difficulty.
Author: Jack Sherbal
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

# Open Trivia DB (https://opentdb.com): free, no key. It allows one request every 5 seconds per address and at most
# 50 questions per request, so a batch is fetched and shown one at a time. Text is requested base64-encoded, so it
# arrives without HTML entities.
NUM_QUESTIONS = 50
OPEN_TRIVIA_DB = "https://opentdb.com/api.php?amount=%d&encode=base64" % NUM_QUESTIONS
CACHE_TTL_SECONDS = 15 * NUM_QUESTIONS

def decode(value):
    return base64.decode(value)

def get_data():
    """The next question, or None if Open Trivia DB can't be reached."""
    question_index = int(cache.get("question_index") or "0")

    rep = http.get(OPEN_TRIVIA_DB, ttl_seconds = CACHE_TTL_SECONDS)
    if rep.status_code != 200:
        print("Open Trivia DB request failed with status %d" % rep.status_code)
        return None
    data = json.decode(rep.body())
    questions = data.get("results") or []
    if data.get("response_code") != 0 or not questions:
        print("Open Trivia DB returned no questions (response code %s)" % data.get("response_code"))
        return None

    cache.set("question_index", str(question_index + 1), ttl_seconds = CACHE_TTL_SECONDS)
    question = questions[question_index % len(questions)]
    return {
        "difficulty": decode(question["difficulty"]),
        "category": decode(question["category"]),
        "question": decode(question["question"]),
        "answer": decode(question["correct_answer"]),
    }

def remove_chars(strr):
    return re.compile(r"<[^>]+>").sub("", strr)

def calc_delay(question, category):
    Q_LEN = len(question) + len(category)

    if Q_LEN < 30:
        return 15

    elif Q_LEN < 40:
        return 10

    elif Q_LEN < 50:
        return 5

    return 0

def main(config):
    body = get_data()
    if not body:
        return []
    value = body["difficulty"].upper()
    question = remove_chars(body["question"])
    answer = remove_chars(body["answer"])
    category = remove_chars(body["category"])

    DELAY = int(config.str("scroll_speed", DEFAULT_SPEED)) + calc_delay(question, category)
    ANSWER_DELAY = config.str("answer_delay", DEFAULT_ANSWER_DELAY)

    return render.Root(
        child = render.Box(
            child = render.Column(
                children = [
                    render.Box(
                        child = render.WrappedText(
                            content = value,
                            color = "#d69f4c",
                            font = "CG-pixel-4x5-mono",
                            height = 6,
                            align = "center",
                        ),
                        height = 6,
                    ),
                    render.Box(
                        height = 1,
                        color = "#fff",
                    ),
                    render.Box(
                        height = 1,
                    ),
                    render.Box(
                        child = render.Marquee(
                            child = render.Column(
                                children = [
                                    render.WrappedText(
                                        content = "Category:\n%s\n----------\n \n%s\n----------\n %s%s" % (category, question, ANSWER_DELAY, answer),
                                        font = "tb-8",
                                        align = "center",
                                    ),
                                ],
                            ),
                            height = 24,
                            offset_start = 22,
                            scroll_direction = "vertical",
                            align = "center",
                        ),
                    ),
                ],
            ),
            color = "#060CE9",
        ),
        delay = DELAY,
    )

DEFAULT_SPEED = "70"
DEFAULT_ANSWER_DELAY = "\n \n"

def get_schema():
    scroll_speed = [
        schema.Option(display = "Slower", value = "110"),
        schema.Option(display = "Slow", value = "90"),
        schema.Option(display = "Normal (Default)", value = DEFAULT_SPEED),
        schema.Option(display = "Fast", value = "60"),
        schema.Option(display = "Faster", value = "40"),
    ]
    answer_delay = [
        schema.Option(display = "Slower", value = "\n \n \n \n"),
        schema.Option(display = "Slow", value = "\n \n \n"),
        schema.Option(display = "Normal (Default)", value = DEFAULT_ANSWER_DELAY),
        schema.Option(display = "Fast", value = "\n"),
        schema.Option(display = "Immediate", value = " "),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "scroll_speed",
                name = "Scroll speed",
                desc = "Text scrolling speed",
                icon = "personRunning",
                default = DEFAULT_SPEED,
                options = scroll_speed,
            ),
            schema.Dropdown(
                id = "answer_delay",
                name = "Answer delay",
                desc = "How long before answer shows",
                icon = "clock",
                default = DEFAULT_ANSWER_DELAY,
                options = answer_delay,
            ),
        ],
    )
