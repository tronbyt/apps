"""
Applet: Instagram
Summary: Instagram Follows
Description: Your Instagram followers count.
Author: Daniel Sitnik
"""

load("http.star", "http")
load("images/ig_icon.png", IG_ICON_ASSET = "file")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

IG_ICON = IG_ICON_ASSET.readall()

CACHE_TTL = 14400

DEFAULT_USERNAME = "hellotidbyt"
DEFAULT_FOLLOWERS_COLOR = "#fff"
DEFAULT_USERNAME_COLOR = "#d6366b"

def main(config):
    """Main app method.

    Args:
        config (config): App configuration.

    Returns:
        render.Root: Root widget tree.
    """

    # get username from config
    username = config.str("username", DEFAULT_USERNAME)
    count_color = config.str("count_color", DEFAULT_FOLLOWERS_COLOR)
    username_color = config.str("username_color", DEFAULT_USERNAME_COLOR)

    # get user's page
    res = http.get("https://www.instagram.com/%s/" % username, ttl_seconds = CACHE_TTL, headers = {
        "accept-language": "en-US,en;q=1.0",
    })

    # handle api errors
    if res.status_code != 200:
        print("API error %d: %s" % (res.status_code, res.body()))
        return render_error(str(res.status_code))

    # get html content
    html = res.body()

    # try to find number of followers
    matches = re.match("(\\w+) Followers,", html)

    # render user not found message if there are no RegEx matches
    if (len(matches) == 0):
        print("No matches returned from RegExp for username %s" % username)
        return render_user_not_found(username)

    # extract number from RegEx
    followers = matches[0][1]

    return render.Root(
        child = render.Column(
            main_align = "space_around",
            children = [
                render.Box(
                    height = 22,
                    child = render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(src = IG_ICON, height = 18),
                            render.Column(
                                main_align = "space_around",
                                cross_align = "start",
                                children = [
                                    render.Text(content = followers, color = count_color),
                                    render.Text(content = "followers", font = "tb-8", color = count_color),
                                ],
                            ),
                        ],
                    ),
                ),
                render.Box(
                    child = render.Marquee(
                        width = 60,
                        child = render.Text(
                            content = "@%s" % username,
                            font = "tb-8",
                            color = username_color,
                        ),
                    ),
                ),
            ],
        ),
    )

def get_schema():
    """Creates the schema for the configuration screen.

    Returns:
        schema.Schema: The schema for the configuration screen.
    """

    color_palette = ["#405de6", "#5851d8", "#833ab4", "#c13584", "#e1306c", "#fd1d1d", "#f56040", "#f77737", "#fcaf45", "#ffdc80"]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "Username",
                desc = "Username name without @.",
                icon = "instagram",
                default = DEFAULT_USERNAME,
            ),
            schema.Color(
                id = "count_color",
                name = "Followers Color",
                desc = "Color for the number of followers.",
                icon = "brush",
                default = DEFAULT_FOLLOWERS_COLOR,
                palette = color_palette,
            ),
            schema.Color(
                id = "username_color",
                name = "Username Color",
                desc = "Color for the username.",
                icon = "brush",
                default = DEFAULT_USERNAME_COLOR,
                palette = color_palette,
            ),
        ],
    )

def render_user_not_found(username):
    """Renders a user not found message when the follower count
        is not found in the page's HTML.

    Args:
        username (string): The username to render.

    Returns:
        render.Root: Root widget tree.
    """

    return render.Root(
        child = render.Column(
            main_align = "space_around",
            children = [
                render.Box(
                    height = 22,
                    child = render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(src = IG_ICON, height = 18),
                            render.Column(
                                main_align = "space_around",
                                cross_align = "start",
                                children = [
                                    render.Text(content = "user not", color = "#f00"),
                                    render.Text(content = "found", color = "#f00"),
                                ],
                            ),
                        ],
                    ),
                ),
                render.Box(
                    width = 64,
                    child = render.Marquee(
                        width = 64,
                        child = render.Text("@%s" % username, font = "tb-8", color = "#ff0"),
                    ),
                ),
            ],
        ),
    )

def render_error(status_code):
    """Renders the status code when there are API errors.

    Args:
        status_code (string): The http status code.

    Returns:
        render.Root: Root widget tree to show an error.
    """

    return render.Root(
        child = render.Column(
            main_align = "space_around",
            children = [
                render.Box(
                    height = 22,
                    child = render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(src = IG_ICON, height = 18),
                            render.Column(
                                main_align = "space_around",
                                cross_align = "start",
                                children = [
                                    render.Text(content = "code", color = "#f00"),
                                    render.Text(content = status_code, color = "#f00"),
                                ],
                            ),
                        ],
                    ),
                ),
                render.Box(
                    width = 64,
                    child = render.Text("API Error", font = "tb-8", color = "#ff0"),
                ),
            ],
        ),
    )
