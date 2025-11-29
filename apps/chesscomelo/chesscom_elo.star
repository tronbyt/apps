"""
Applet: Chess.com ELO
Summary: Track your Chess.com ELO
Description: Track your ELO from Chess.com from a variety of game types.
Author: UnBurn
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/blitz_icon.png", BLITZ_ICON_ASSET = "file")
load("images/bullet_icon.png", BULLET_ICON_ASSET = "file")
load("images/chess_com_icon.png", CHESS_COM_ICON_ASSET = "file")
load("images/daily_icon.png", DAILY_ICON_ASSET = "file")
load("images/no_profile_icon.png", NO_PROFILE_ICON_ASSET = "file")
load("images/puzzle_icon.png", PUZZLE_ICON_ASSET = "file")
load("images/rapid_icon.png", RAPID_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

BLITZ_ICON = BLITZ_ICON_ASSET.readall()
BULLET_ICON = BULLET_ICON_ASSET.readall()
CHESS_COM_ICON = CHESS_COM_ICON_ASSET.readall()
DAILY_ICON = DAILY_ICON_ASSET.readall()
NO_PROFILE_ICON = NO_PROFILE_ICON_ASSET.readall()
PUZZLE_ICON = PUZZLE_ICON_ASSET.readall()
RAPID_ICON = RAPID_ICON_ASSET.readall()

ICONS = {"bullet": BULLET_ICON, "lightning": BLITZ_ICON, "rapid": RAPID_ICON, "chess": DAILY_ICON, "tactics": PUZZLE_ICON}

options = [
    schema.Option(
        display = "Rapid",
        value = "rapid",
    ),
    schema.Option(
        display = "Blitz",
        value = "lightning",
    ),
    schema.Option(
        display = "Bullet",
        value = "bullet",
    ),
    schema.Option(
        display = "Daily",
        value = "chess",
    ),
    schema.Option(
        display = "Puzzles",
        value = "tactics",
    ),
    schema.Option(
        display = "None",
        value = "none",
    ),
]

ONE_HOUR_IN_SECONDS = 3600

CHESS_COM_URL = "https://www.chess.com"
CHESS_COM_STATS_ENDPOINT = "%s/callback/member/stats" % CHESS_COM_URL
CHESS_COM_PROFILE_ENDPOINT = "https://api.chess.com/pub/player"
DEFAULT_USERNAME = "magnuscarlsen"

def get_diff_color(score):
    if score < 0:
        return "#ff0000"
    elif score > 0:
        return "#00ff00"
    else:
        return "#ffffff"

#
def get_diff_string(score):
    if score > 0:
        return "+%d" % score
    elif score < 0:
        return "%d" % score
    else:
        return ""

def get_stats(username):
    endpoint = "%s/%s" % (CHESS_COM_STATS_ENDPOINT, username)

    cache_key = "stats=%s" % endpoint
    cached_values = cache.get(cache_key)
    if cached_values == None:
        resp = http.get(endpoint).json()

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(cache_key, json.encode(resp), ttl_seconds = ONE_HOUR_IN_SECONDS)
        return resp["stats"]
    else:
        return json.decode(cached_values)["stats"]

def get_profile_image(username):
    endpoint = "%s/%s" % (CHESS_COM_PROFILE_ENDPOINT, username)

    cache_key = "profile=%s" % endpoint
    img = cache.get(cache_key)
    if img == None:
        resp = http.get(endpoint).json()
        if "avatar" in resp.keys():
            img = http.get(resp["avatar"]).body()
        else:
            img = NO_PROFILE_ICON

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(cache_key, img, ttl_seconds = ONE_HOUR_IN_SECONDS)

    return img

def main(config):
    username = config.str("username", DEFAULT_USERNAME)
    if username == "":
        username = DEFAULT_USERNAME

    stat1 = config.str("stat1", options[0].value)
    stat2 = config.str("stat2", options[1].value)
    stat3 = config.str("stat3", options[2].value)
    show_change = config.bool("show_elo_change", True)

    profile_image = get_profile_image(username)

    resp = get_stats(username)
    stats = dict()
    diff = dict()

    for rating in resp:
        if "rating" not in rating["stats"].keys() or rating["stats"]["rating"] == "Unrated":
            continue
        stats[rating["key"]] = int(rating["stats"]["rating"])
        if "rating_time_change_value" in rating["stats"].keys():
            diff[rating["key"]] = int(rating["stats"]["rating_time_change_value"])
        else:
            diff[rating["key"]] = 0
    stats_to_render = []
    for stat in [stat1, stat2, stat3]:
        if stat in stats.keys():
            children = [
                render.Image(src = ICONS[stat], width = 8, height = 8),
                render.Text("%d" % stats[stat]),
            ]
            if show_change:
                children.append(
                    render.Text(get_diff_string(diff[stat]), color = get_diff_color(diff[stat])),
                )
            stats_to_render.append(
                render.Row(
                    main_align = "center",
                    cross_align = "center",
                    children = children,
                ),
            )

    if len(stats_to_render) == 0:
        stats_to_render.append(
            render.Row(
                main_align = "center",
                children = [
                    render.Padding(pad = 2, child = render.WrappedText("No stats found", height = 20)),
                ],
            ),
        )

    render_username = render.Marquee(
        width = 56,
        child = render.Text(username),
    )
    render_chesscom_icon = render.Padding(
        pad = (0, 1, 0, 0),
        child = render.Image(
            src = CHESS_COM_ICON,
            width = 7,
            height = 7,
        ),
    )

    render_profile_icon = render.Image(src = profile_image, width = 20, height = 20)

    render_stats = render.Column(
        main_align = "center",
        children = stats_to_render,
    )

    render_header = render.Row(
        main_align = "start",
        cross_align = "center",
        children = [render_chesscom_icon, render_username],
    )

    render_body = render.Row(
        expanded = True,
        main_align = "center",
        cross_align = "center",
        children = [render_profile_icon, render_stats],
    )

    return render.Root(
        child = render.Column(
            children = [
                render.Box(height = 8, child = render_header),
                render.Box(child = render_body),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "Chess.com Username",
                desc = "Username to keep track of",
                icon = "user",
                default = DEFAULT_USERNAME,
            ),
            schema.Dropdown(
                id = "stat1",
                name = "Game Type #1",
                desc = "First ELO to track",
                default = options[0].value,
                options = options,
                icon = "chessPawn",
            ),
            schema.Dropdown(
                id = "stat2",
                name = "Game Type #2",
                desc = "Second ELO to track",
                default = options[1].value,
                options = options,
                icon = "chessPawn",
            ),
            schema.Dropdown(
                id = "stat3",
                name = "Game Type #3",
                desc = "Third ELO to track",
                default = options[2].value,
                options = options,
                icon = "chessPawn",
            ),
            schema.Toggle(
                id = "show_elo_change",
                name = "Show Change",
                desc = "Show how far you've grown or fallen",
                icon = "chartLine",
                default = True,
            ),
        ],
    )
