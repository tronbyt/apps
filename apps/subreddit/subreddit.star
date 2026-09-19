"""
Applet: Subreddit
Summary: Subreddit post
Description: Display the #1 post of a subreddit.
Author: Petros Fytilis
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/reddit_icon.png", REDDIT_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

REDDIT_ICON = REDDIT_ICON_ASSET.readall()

SCREEN_WIDTH = 64
STATUS_OK = 200
MAX_DURATION_SECONDS = 60
CACHE_TTL_SECONDS = 300
DEFAULT_SUBREDDIT = "games"

DEFAULT_LOCATION = """
{
	"lat": "40.6781784",
	"lng": "-73.9441579",
	"description": "Brooklyn, NY, USA",
	"locality": "Brooklyn",
	"place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
	"timezone": "America/New_York"
}
"""

REDDIT_API_URL_TEMPLATE = "https://www.reddit.com/r/{}/hot.json?limit=1"

def main(config):
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    timezone = loc["timezone"]
    subreddit = (config.get("subreddit") or DEFAULT_SUBREDDIT).strip()
    is_24h_format = config.bool("is_24h_format", False)

    return render.Root(
        max_age = MAX_DURATION_SECONDS,
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        _render_reddit_icon(),
                        render.Column(
                            main_align = "space_evenly",
                            cross_align = "end",
                            children = [
                                _render_clock(timezone, is_24h_format),
                                _render_subreddit(_hyphenate_subreddit(subreddit)),
                            ],
                        ),
                    ],
                ),
                _render_post_title(subreddit),
            ],
        ),
    )

def _hyphenate_subreddit(subreddit):
    label = "/r/" + subreddit

    if len(label) > 10:
        label = label[0:10] + "- " + label[10:]
    if len(label) > 22:
        label = label[0:22] + "- " + label[22:]
    if len(label) > 34:
        label = label[0:31] + "..."

    return label

def _render_reddit_icon():
    return render.Image(src = REDDIT_ICON)

def _render_clock(timezone, is_24h_format):
    now = time.now().in_location(timezone)
    clock_format = "15:04" if is_24h_format else "3:04 PM"
    return render.Animation(
        children =
            [
                render.Text(
                    content = now.format(clock_format if i < 10 else clock_format.replace(":", " ")),
                    font = "tom-thumb",
                )
                for i in range(20)
            ],
    )

def _render_subreddit(subreddit):
    nb_lines = len(subreddit.split())
    height = min(3, nb_lines) * 6
    return render.WrappedText(
        content = subreddit,
        color = "#ff3518",
        font = "tom-thumb",
        height = height,
    )

def _render_post_title(subreddit):
    post_title = _fetch_post_title(subreddit)
    return render.Marquee(
        child = render.Text(
            content = post_title,
            font = "tb-8",
        ),
        offset_start = SCREEN_WIDTH,
        offset_end = SCREEN_WIDTH,
        width = SCREEN_WIDTH,
    )

def _fetch_post_title(subreddit):
    print("Calling Reddit API for <{}>.".format(subreddit))
    rep = http.get(
        REDDIT_API_URL_TEMPLATE.format(subreddit),
        headers = {"User-agent": "PostmanRuntime/7.28.4"},
        ttl_seconds = CACHE_TTL_SECONDS,
    )
    if rep.status_code != STATUS_OK:
        print("Reddit request failed with status {}.".format(rep.status_code))
        return "Could not retrieve Reddit data"
    return _parse_post_title(rep.json())

def _parse_post_title(json):
    if json["data"] and json["data"]["children"] and len(json["data"]["children"]) > 0:
        post = json["data"]["children"][-1]
        if post["data"] and post["data"]["title"]:
            return post["data"]["title"]
    return "No post was found"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "subreddit",
                name = "Subreddit",
                desc = "Subreddit for which to display post .",
                icon = "reddit",
                default = DEFAULT_SUBREDDIT,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "is_24h_format",
                name = "24-hour clock",
                desc = "Enable 24-hour clock.",
                icon = "clock",
                default = False,
            ),
        ],
    )
