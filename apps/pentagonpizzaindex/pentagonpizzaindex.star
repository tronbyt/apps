load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

PIZZINT_URL = "https://www.pizzint.watch/"
CACHE_KEY = "pizzint-doughcon-level"
CACHE_TTL = 300

BG_DARK = "#080c12"

# Small 8x8 pizza icon.
PIZZA_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAAGYktHRAAAAAAAAPlDu38AAAAHdElNRQfqAhkOHiInZYoAAAAA/klEQVQY013BzUoCURgG4Pc7P/OjaaElBsWILixauYqCsFV35B10By2DYO4gIiJoUeuCIKgQRFpEVtYMMTKNHs85077noa2gfN9eL3cYEf4bRdlYNJf9zmG3DtIGxABrAC4ZCos+wttxTUTJbHh3PWw1A4Xa7gIGJ98wWQ5ndQmPPyzhRnBWKbv7GyUr8tyi1HDBifCQOLj4UGe86MsXLcROS1Nj9pxApwZpKnGVydd+NOtxo21KDlcrlcLBZkBusS7xFHv2JjbHjmQh325XoQn9UWa8qnD31ETQaZyfjybzXq5tKjgjWGXmypfh5ee86zFae5/ao7ev3yibavwBOetqflKB2HYAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDItMjVUMTQ6MzA6MzQrMDA6MDAaKLlDAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTAyLTI1VDE0OjMwOjM0KzAwOjAwa3UB/wAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wMi0yNVQxNDozMDozNCswMDowMDxgICAAAABZdEVYdHN2Zzpjb21tZW50ACBQaXp6YSBiYXNlIAogUGl6emEgc2F1Y2UvdG9wcGluZ3MgCiBDaGVlc2UgdG9wcGluZ3MgCiBQaXp6YSBvdXRsaW5lL2JvcmRlcnMgE3aJwAAAAABJRU5ErkJggg==
""")

def get_theme(level):
    if level == 4:
        return {"state": "#00e5ff", "outline": "#00e5ff", "fill": "#0b4d5c"}
    elif level == 3:
        return {"state": "#ffd600", "outline": "#ffd600", "fill": "#5f5000"}
    elif level == 2:
        return {"state": "#ff9100", "outline": "#ff9100", "fill": "#603500"}
    elif level == 1:
        return {"state": "#ff1744", "outline": "#ff1744", "fill": "#5f0c1f"}
    else:
        return {"state": "#8b98a8", "outline": "#8b98a8", "fill": "#2e3a4a"}

def _digit_from_window(text):
    for i in range(len(text)):
        ch = text[i]
        if ch in ("1", "2", "3", "4", "5"):
            return int(ch)
    return None

def _parse_level(body):
    lower = body.lower()

    # Pattern 1: "doughcon" followed by a nearby digit.
    idx = lower.find("doughcon")
    if idx != -1:
        level = _digit_from_window(lower[idx:idx + 40])
        if level != None:
            return level

    # Pattern 2: embedded app payload around "optempo" with "level".
    idx = lower.find("\"optempo\"")
    if idx != -1:
        window = lower[idx:idx + 500]
        marker = "\"level\":"
        lvl_idx = window.find(marker)
        if lvl_idx != -1:
            level = _digit_from_window(window[lvl_idx:lvl_idx + 20])
            if level != None:
                return level

    # Pattern 3: fallback generic level marker.
    marker = "\"level\":"
    lvl_idx = lower.find(marker)
    if lvl_idx != -1:
        level = _digit_from_window(lower[lvl_idx:lvl_idx + 20])
        if level != None:
            return level

    # Pattern 4: textual fallback if numeric markers are missing.
    if "business as usual" in lower:
        return 4
    if "increased watch" in lower:
        return 4
    if "elevated" in lower:
        return 3
    if "high alert" in lower:
        return 2
    if "maximum" in lower or "imminent crisis" in lower:
        return 1

    return 0

def get_level():
    cached = cache.get(CACHE_KEY)
    if cached != None and cached in ("1", "2", "3", "4", "5"):
        return int(cached)

    resp = http.get(PIZZINT_URL, ttl_seconds = CACHE_TTL)
    if resp.status_code != 200:
        return 0

    level = _parse_level(resp.body())
    if level in (1, 2, 3, 4, 5):
        cache.set(CACHE_KEY, str(level), ttl_seconds = CACHE_TTL)
        return level

    return 0

def _header():
    return render.Box(
        height = 8,
        child = render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Image(src = PIZZA_ICON),
                render.Box(width = 2, height = 1),
                render.Text(
                    "Pizza Index",
                    font = "tom-thumb",
                    color = "#ffffff",
                ),
            ],
        ),
    )

def _state_card(level, theme):
    level_str = str(level) if level in (1, 2, 3, 4, 5) else "?"

    return render.Padding(
        pad = (2, 1, 2, 1),
        child = render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Box(
                    width = 60,
                    height = 20,
                    color = theme["outline"],
                    child = render.Padding(
                        pad = (1, 1, 1, 1),
                        child = render.Box(
                            width = 58,
                            height = 18,
                            color = theme["fill"],
                            child = render.Row(
                                expanded = True,
                                main_align = "center",
                                cross_align = "center",
                                children = [
                                    render.Text(
                                        "DOUGHCON {}".format(level_str),
                                        font = "5x8",
                                        color = theme["state"],
                                    ),
                                ],
                            ),
                        ),
                    ),
                ),
            ],
        ),
    )

def main(_config):
    level = get_level()
    theme = get_theme(level)

    return render.Root(
        delay = 75,
        child = render.Box(
            width = 64,
            height = 32,
            color = BG_DARK,
            child = render.Column(
                expanded = True,
                cross_align = "center",
                children = [
                    render.Padding(
                        pad = (0, 1, 0, 0),
                        child = _header(),
                    ),
                    _state_card(level, theme),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(version = "1", fields = [])
