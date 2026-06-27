"""
Applet: Dad Jokes
Summary: Random dad jokes
Description: Displays random dad jokes fetched from icanhazdadjoke.com with vertically scrolling text.
Author: kbromberger
"""

load("cache.star", "cache")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

AUTHOR = "Dad"
API_URL = "https://icanhazdadjoke.com/"
HEADERS = {
    "Accept": "application/json",
    "User-Agent": "Tronbyt Dad Jokes App (https://github.com/tronbyt/pixlet)",
}

DEFAULT_JOKE_COLOR = "#FFB600"
DEFAULT_AUTHOR_COLOR = "#FFA500"

def main(config):
    joke = get_joke()
    joke_length = len(joke)

    display_font = config.str("font", "tb-8")
    joke_color = config.str("joke_color", DEFAULT_JOKE_COLOR)
    author_color = config.str("author_color", DEFAULT_AUTHOR_COLOR)
    show_author = config.bool("show_author", True)

    if joke_length <= 150:
        delay = 120
    elif joke_length <= 250:
        delay = 95
    else:
        delay = 80

    children = [
        render.WrappedText(
            content = joke,
            width = 64,
            font = display_font,
            color = joke_color,
        ),
    ]

    if show_author:
        children.append(render.Box(height = 8, width = 64))
        children.append(render.WrappedText(
            content = "- " + AUTHOR,
            width = 64,
            font = display_font,
            color = author_color,
        ))

    return render.Root(
        delay = delay,
        child = render.Marquee(
            height = 32,
            offset_start = 35,
            offset_end = -80,
            scroll_direction = "vertical",
            child = render.Column(
                children = children,
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "joke_color",
                name = "Joke Color",
                desc = "Color for the joke text",
                icon = "palette",
                default = DEFAULT_JOKE_COLOR,
            ),
            schema.Color(
                id = "author_color",
                name = "Author Color",
                desc = "Color for the '- Dad' attribution text",
                icon = "palette",
                default = DEFAULT_AUTHOR_COLOR,
            ),
            schema.Dropdown(
                id = "font",
                name = "Font",
                desc = "Font for the joke text",
                icon = "font",
                default = "tb-8",
                options = [
                    schema.Option(display = "tb-8 (default)", value = "tb-8"),
                    schema.Option(display = "5x8", value = "5x8"),
                    schema.Option(display = "Dina (monospace)", value = "Dina_r400-6"),
                    schema.Option(display = "6x13 (large)", value = "6x13"),
                    schema.Option(display = "tom-thumb (tiny)", value = "tom-thumb"),
                    schema.Option(display = "3x5 (smallest)", value = "CG-pixel-3x5-mono"),
                    schema.Option(display = "4x5", value = "CG-pixel-4x5-mono"),
                ],
            ),
            schema.Toggle(
                id = "show_author",
                name = "Show '- Dad'",
                desc = "Show the author attribution after the joke",
                icon = "user",
                default = True,
            ),
        ],
    )

def get_joke():
    cached = cache.get("dad_joke")
    if cached != None:
        return cached

    res = http.get(url = API_URL, headers = HEADERS)

    if res.status_code != 200:
        return "Why did the programmer quit? Because he didn't get arrays."

    joke = res.json()["joke"]
    cache.set("dad_joke", joke, ttl_seconds = 300)
    return joke
