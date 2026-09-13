"""
Applet: Lichess ELO
Summary: Track your Lichess rating
Description: Shows your Lichess username and ratings for the game types you choose (bullet, blitz, rapid, classical, and more), along with your recent rating progress.
Author: trbarron
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

LICHESS_KNIGHT = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAASUlEQVR4nK1PQQ4AIAgS///nuuSWSpNDnByCoFnBOqh8wKuYzdTABIzzewEAU0VXarQEdvmFJJwSAMArIVVSE5JBEbeEr4b4bwM1wzfySltMQAAAAABJRU5ErkJggg==
""")

LICHESS_USER_URL = "https://lichess.org/api/user/%s"
DEFAULT_USERNAME = "trbarron"
ONE_HOUR = 3600

# Maps a schema option value to the Lichess "perfs" key, a short display
# label, and a label color.
PERF_TYPES = {
    "ultraBullet": ("ultraBullet", "ULT", "#e0a3ff"),
    "bullet": ("bullet", "BUL", "#f5a623"),
    "blitz": ("blitz", "BLZ", "#ffd700"),
    "rapid": ("rapid", "RAP", "#4caf50"),
    "classical": ("classical", "CLA", "#bdbdbd"),
    "correspondence": ("correspondence", "COR", "#8d6e63"),
    "chess960": ("chess960", "960", "#26c6da"),
    "puzzle": ("puzzle", "PZL", "#ab47bc"),
}

OPTIONS = [
    schema.Option(display = "Bullet", value = "bullet"),
    schema.Option(display = "Blitz", value = "blitz"),
    schema.Option(display = "Rapid", value = "rapid"),
    schema.Option(display = "Classical", value = "classical"),
    schema.Option(display = "UltraBullet", value = "ultraBullet"),
    schema.Option(display = "Correspondence", value = "correspondence"),
    schema.Option(display = "Chess960", value = "chess960"),
    schema.Option(display = "Puzzles", value = "puzzle"),
    schema.Option(display = "None", value = "none"),
]

def get_diff_color(score):
    if score < 0:
        return "#ff5555"
    elif score > 0:
        return "#55ff55"
    else:
        return "#888888"

def get_diff_string(score):
    if score > 0:
        return "+%d" % score
    elif score < 0:
        return "%d" % score
    else:
        return ""

def message(text):
    return render.Root(
        child = render.Box(
            child = render.WrappedText(
                content = text,
                align = "center",
                width = 60,
            ),
        ),
    )

def stat_row(value, perfs, show_change):
    if value == "none" or value not in PERF_TYPES:
        return None

    perf_key, label, color = PERF_TYPES[value]
    perf = perfs.get(perf_key)
    if perf == None or "rating" not in perf:
        return None

    children = [
        render.Box(
            width = 16,
            height = 8,
            child = render.Text(content = label, color = color),
        ),
        render.Text(content = "%d" % perf["rating"]),
    ]

    if show_change:
        prog = perf.get("prog", 0)
        diff = get_diff_string(prog)
        if diff != "":
            children.append(render.Box(width = 2, height = 8))
            children.append(render.Text(content = diff, color = get_diff_color(prog)))

    return render.Row(
        cross_align = "center",
        children = children,
    )

def main(config):
    username = config.str("username", DEFAULT_USERNAME).strip()
    if username == "":
        username = DEFAULT_USERNAME

    show_change = config.bool("show_change", True)

    resp = http.get(LICHESS_USER_URL % username, ttl_seconds = ONE_HOUR)
    if resp.status_code == 404:
        return message("User '%s' not found" % username)
    if resp.status_code != 200:
        return message("Lichess error %d" % resp.status_code)

    data = resp.json()
    if data.get("closed") or data.get("disabled"):
        return message("Account %s is closed" % username)

    perfs = data.get("perfs", {})
    display_name = data.get("username", username)

    rows = []
    for sel in [config.str("stat1", "bullet"), config.str("stat2", "blitz"), config.str("stat3", "rapid")]:
        row = stat_row(sel, perfs, show_change)
        if row != None:
            rows.append(row)

    if len(rows) == 0:
        rows.append(render.Text(content = "No ratings", color = "#888888"))

    header = render.Row(
        cross_align = "center",
        children = [
            render.Padding(
                pad = (0, 0, 2, 0),
                child = render.Image(src = LICHESS_KNIGHT, width = 8, height = 8),
            ),
            render.Marquee(
                width = 54,
                child = render.Text(content = display_name, color = "#dda0ff"),
            ),
        ],
    )

    body = render.Column(
        expanded = True,
        main_align = "space_evenly",
        children = rows,
    )

    return render.Root(
        child = render.Column(
            children = [
                render.Box(height = 8, child = header),
                render.Box(height = 24, child = body),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "Lichess Username",
                desc = "The Lichess account to track",
                icon = "user",
                default = DEFAULT_USERNAME,
            ),
            schema.Dropdown(
                id = "stat1",
                name = "Game Type #1",
                desc = "First rating to show",
                icon = "chessPawn",
                default = "bullet",
                options = OPTIONS,
            ),
            schema.Dropdown(
                id = "stat2",
                name = "Game Type #2",
                desc = "Second rating to show",
                icon = "chessPawn",
                default = "blitz",
                options = OPTIONS,
            ),
            schema.Dropdown(
                id = "stat3",
                name = "Game Type #3",
                desc = "Third rating to show",
                icon = "chessPawn",
                default = "rapid",
                options = OPTIONS,
            ),
            schema.Toggle(
                id = "show_change",
                name = "Show Rating Change",
                desc = "Show recent rating progress",
                icon = "chartLine",
                default = True,
            ),
        ],
    )
