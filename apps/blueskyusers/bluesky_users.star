"""
Applet: Bluesky Users
Summary: Display Bluesky user count
Description: Display the total number of users on the Bluesky social network. Data courtesy of https://bsky-users.theo.io.
Author: Daniel Sitnik
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("images/bsky_logo.png", BSKY_LOGO_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

BSKY_LOGO = BSKY_LOGO_ASSET.readall()

DEFAULT_STAT_COLOR = "#3a83f7"
DEFAULT_DOT_SEPARATOR = False
CACHE_TTL = 120

def main(config):
    """Main app method.

    Args:
        config (config): App configuration.

    Returns:
        render.Root: Root widget tree.
    """

    # read config values
    number_color = config.str("number_color", DEFAULT_STAT_COLOR)
    dot_separator = config.bool("dot_separator", DEFAULT_DOT_SEPARATOR)

    # get data
    res = http.get("https://bsky-users.theo.io/api/stats", ttl_seconds = CACHE_TTL)

    # handle errors
    if res.status_code != 200:
        print("API error %d: %s" % (res.status_code, res.body()))
        return render_api_error(str(int(res.status_code)))

    # transform to json
    data = res.json()

    # read data properties
    user_count = data["last_user_count"]
    growth_per_second = math.ceil(data["growth_per_second"])

    # render frames to represent user count increase
    frames = render_frames(user_count, growth_per_second, number_color, dot_separator)

    # calculate frame delay to display all frames in 15 seconds
    delay = math.ceil(15000 / len(frames))

    # render display
    return render.Root(
        delay = delay,
        child = render.Box(
            color = "#000000",
            child = render.Column(
                main_align = "space_evenly",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Image(src = BSKY_LOGO, height = 10),
                            render.Box(width = 2, height = 1, color = "#000000"),
                            render.Text("Bluesky", font = "Dina_r400-6"),
                        ],
                    ),
                    render.Animation(
                        children = frames,
                    ),
                    render.Text("users", color = "#afbac7", font = "tom-thumb"),
                ],
            ),
        ),
    )

def render_frames(user_count, growth_per_second, number_color, dot_separator):
    """Renders the frames for a animation representing the user count increase.

    Args:
        user_count (int): Current number of users.
        growth_per_second (float): User growth rate per second.
        number_color (str): Color used to format the user count number.
        dot_separator (bool): Indicates if dot should be used as thousands separator.

    Returns:
        list: List of frames.
    """
    frames = []

    # calculates how many users we would have after 15 seconds with the current growth rate
    last_user_count = int(user_count + growth_per_second * 15)

    # diff between final and current count
    count_diff = int(last_user_count - user_count)

    # create frames
    for _ in range(count_diff):
        # check if user count has reached another million
        if user_count % 1000000 != 0:
            # most likely not, so just render the number
            frame_text = humanize.comma(int(user_count))
            if dot_separator:
                frame_text = frame_text.replace(",", ".")
            frames.append(render.Text(frame_text, color = number_color))
        else:
            # reached another million, render frames for a nice flashing animation!
            frames += render_million(user_count, number_color, dot_separator)
        user_count += 1

    return frames

def render_million(user_count, number_color, dot_separator):
    """Renders colored frames to show that the user count has reached another million.

    Args:
        user_count (int): Current number of users.
        number_color (str): Color used to format the user count number.
        dot_separator (bool): Indicates if dot should be used as thousands separator.

    Returns:
        list: List of frames.
    """
    frames = []

    frame_text = humanize.comma(int(user_count))
    if dot_separator:
        frame_text = frame_text.replace(",", ".")

    # add more frames with rainbow colors
    for _ in range(8):
        frames.append(render.Text(frame_text, color = number_color))
        frames.append(render.Text(frame_text, color = "#ffffff"))
        frames.append(render.Text(frame_text, color = "#ff0000"))
        frames.append(render.Text(frame_text, color = "#ff7f00"))
        frames.append(render.Text(frame_text, color = "#ffff00"))
        frames.append(render.Text(frame_text, color = "#00ff00"))
        frames.append(render.Text(frame_text, color = "#0000ff"))
        frames.append(render.Text(frame_text, color = "#4b0082"))
        frames.append(render.Text(frame_text, color = "#9400d3"))
        frames.append(render.Text(frame_text, color = number_color))

    return frames

def get_schema():
    """Creates the schema for the configuration screen.

    Returns:
        schema.Schema: The schema for the configuration screen.
    """
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "number_color",
                name = "Number color",
                desc = "The color of the user count number.",
                icon = "brush",
                default = DEFAULT_STAT_COLOR,
                palette = [DEFAULT_STAT_COLOR],
            ),
            schema.Toggle(
                id = "dot_separator",
                name = "Dot separator",
                desc = "Use dots as thousands separator.",
                icon = "circleDot",
                default = DEFAULT_DOT_SEPARATOR,
            ),
        ],
    )

def render_api_error(status_code):
    """Renders a view when there's an API error.

    Args:
        status_code (str): The http status code of the error.

    Returns:
        render.Root: Root widget tree.
    """
    return render.Root(
        child = render.Box(
            color = "#000000",
            child = render.Column(
                main_align = "space_evenly",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Image(src = BSKY_LOGO, height = 10),
                            render.Box(width = 2, height = 1, color = "#000000"),
                            render.Text("Bluesky", font = "Dina_r400-6"),
                        ],
                    ),
                    render.Text("API ERROR", color = "#ff0000"),
                    render.Text("CODE %d" % status_code, color = "#ffff00"),
                ],
            ),
        ),
    )
