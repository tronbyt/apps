"""
Applet: GitHub Contributions
Summary: Your GitHub contribution graph
Description: Scrolling 7xN heatmap of your recent GitHub contributions.
Setup: Configure your GitHub username and personal access token.
Author: Robert Ison
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("hmac.star", "hmac")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")


GITHUB_GRAPHQL_URL = "https://api.github.com/graphql"

CACHE_TTL = 3600 * 4
FALLBACK_CACHE_TTL = 3600 * 24 * 7
CACHE_PREFIX = "github_contributions_v3"

WEEKS_TO_SHOW = 30

FRAME_DELAY_MS = 100
HOLD_FRAMES_START = 15
HOLD_FRAMES_END = 100
SCROLL_FRAMES = 90
BLACK_TRANSITION_FRAMES = 10

BACKGROUND_COLOR = "#000000"

CONTRIBUTION_COLORS = [
    "#1a1a1a",
    "#9be9a8",
    "#40c463",
    "#30a14e",
    "#216e39",
]

GITHUB_QUERY = """
query($username: String!, $from: DateTime!, $to: DateTime!) {
  user(login: $username) {
    contributionsCollection(from: $from, to: $to) {
      contributionCalendar {
        weeks {
          contributionDays {
            contributionCount
            weekday
          }
        }
      }
    }
  }
}
"""

def cached_fallback_or_error(fallback_key, error):
    cached = cache.get(fallback_key)

    if cached:
        data = json.decode(cached)
        calendar = extract_calendar(data)

        if calendar != None and normalize_contributions(calendar):
            print(
                "GitHub Contributions: using last successful calendar",
            )

            return {
                "calendar": calendar,
                "error": None,
            }

    return {
        "calendar": None,
        "error": error,
    }

def get_layout():
    is_2x = canvas.is2x()

    return {
        "screen_width": 128 if is_2x else 64,
        "screen_height": 64 if is_2x else 32,
        "cell_width": 8 if is_2x else 4,
        "weekday_height": 8 if is_2x else 4,
        "weekend_height": 8 if is_2x else 3,
        "left_padding": 6 if is_2x else 2,
        "gap": 1,
    }


def get_cache_key(username, token):
    # Separate cached data by authentication context without storing
    # the raw token in the cache key.
    fingerprint = hmac.sha256(
        token,
        "github-contributions-cache-v2",
    )

    return "{}_{}_{}".format(
        CACHE_PREFIX,
        username.lower(),
        fingerprint,
    )


def extract_calendar(data):
    if type(data) != "dict" or data.get("errors"):
        return None

    payload = data.get("data")
    if type(payload) != "dict":
        return None

    user = payload.get("user")
    if type(user) != "dict":
        return None

    collection = user.get("contributionsCollection")
    if type(collection) != "dict":
        return None

    calendar = collection.get("contributionCalendar")
    if type(calendar) != "dict":
        return None

    weeks = calendar.get("weeks")
    if type(weeks) != "list" or not weeks:
        return None

    return calendar


def get_contributions(username, token):
    cache_key = get_cache_key(username, token)
    fallback_key = "{}_last_success".format(cache_key)

    # First use the normal four-hour cache.
    cached = cache.get(cache_key)

    if cached:
        cached_data = json.decode(cached)
        calendar = extract_calendar(cached_data)

        if calendar != None and normalize_contributions(calendar):
            return {
                "calendar": calendar,
                "error": None,
            }

    # Fresh cache is missing or unusable: try GitHub.
    now = time.now()
    start = now - time.parse_duration(
        "{}h".format(WEEKS_TO_SHOW * 7 * 24),
    )

    date_format = "2006-01-02T15:04:05Z07:00"

    body = json.encode({
        "query": GITHUB_QUERY,
        "variables": {
            "username": username,
            "from": start.format(date_format),
            "to": now.format(date_format),
        },
    })

    response = http.post(
        GITHUB_GRAPHQL_URL,
        headers = {
            "Authorization": "Bearer {}".format(token),
            "Content-Type": "application/json",
            "Accept": "application/vnd.github+json",
            "User-Agent": "Tronbyt-GitHub-Contributions",
        },
        body = body,
        ttl_seconds = 0,
    )

    status = response.status_code

    if status != 200:
        print("GitHub Contributions: HTTP {}".format(status))

        if status == 401:
            error = "Check GitHub token"
        elif status == 403:
            error = "GitHub access/rate limit"
        elif status == 429:
            error = "GitHub rate limit"
        else:
            error = "GitHub HTTP {}".format(status)

        return cached_fallback_or_error(
            fallback_key,
            error,
        )

    data = response.json()

    if type(data) != "dict":
        print("GitHub Contributions: unexpected response format")

        return cached_fallback_or_error(
            fallback_key,
            "GitHub response error",
        )

    if data.get("errors"):
        print("GitHub Contributions: GraphQL query returned errors")

        return cached_fallback_or_error(
            fallback_key,
            "GitHub query/access error",
        )

    payload = data.get("data")

    if type(payload) == "dict" and payload.get("user") == None:
        return cached_fallback_or_error(
            fallback_key,
            "GitHub user not found",
        )

    calendar = extract_calendar(data)

    if calendar == None:
        print("GitHub Contributions: missing contribution calendar")

        return cached_fallback_or_error(
            fallback_key,
            "GitHub calendar unavailable",
        )

    # Confirm the calendar contains usable days before replacing
    # either cache. A valid all-zero calendar still passes.
    if not normalize_contributions(calendar):
        print("GitHub Contributions: calendar has no valid day values")

        return cached_fallback_or_error(
            fallback_key,
            "GitHub: no valid day values",
        )

    encoded_data = json.encode(data)

    # Normal cache controls how often we refresh.
    cache.set(
        cache_key,
        encoded_data,
        ttl_seconds = CACHE_TTL,
    )

    # Backup is updated only after a successful, validated fetch.
    cache.set(
        fallback_key,
        encoded_data,
        ttl_seconds = FALLBACK_CACHE_TTL,
    )

    return {
        "calendar": calendar,
        "error": None,
    }
    
def contribution_level(count):
    if count >= 10:
        return 4
    elif count >= 5:
        return 3
    elif count >= 3:
        return 2
    elif count > 0:
        return 1

    return 0


def normalize_contributions(calendar):
    if not calendar or not calendar.get("weeks"):
        return []

    weeks = calendar["weeks"][-WEEKS_TO_SHOW:]
    num_weeks = len(weeks)

    grid = [
        [None for _ in range(num_weeks)]
        for _ in range(7)
    ]

    valid_days = 0

    for week_idx, week in enumerate(weeks):
        for day in week.get("contributionDays", []):
            weekday_value = day.get("weekday")
            count_value = day.get("contributionCount")

            if weekday_value == None or count_value == None:
                continue

            weekday = int(weekday_value)
            count = int(count_value)

            if weekday < 0 or weekday > 6 or count < 0:
                continue

            grid[weekday][week_idx] = contribution_level(count)
            valid_days += 1

    if valid_days == 0:
        return []

    return grid
    
def get_graph_width(cols, layout):
    if cols <= 0:
        return 0

    return (
        layout["left_padding"] +
        cols * layout["cell_width"] +
        (cols - 1) * layout["gap"]
    )


def get_graph_height(layout):
    return (
        5 * layout["weekday_height"] +
        2 * layout["weekend_height"] +
        6 * layout["gap"]
    )


def render_visible_row(levels, row_height, graph_x, layout):
    screen_width = layout["screen_width"]
    cell_width = layout["cell_width"]
    gap = layout["gap"]

    children = []
    cursor = 0

    for col, level in enumerate(levels):
        cell_left = (
            graph_x +
            layout["left_padding"] +
            col * (cell_width + gap)
        )
        cell_right = cell_left + cell_width

        # Clip the cell to the visible horizontal viewport.
        visible_left = max(0, cell_left)
        visible_right = min(screen_width, cell_right)

        if visible_right <= visible_left:
            continue

        if visible_left > cursor:
            children.append(render.Box(
                width = visible_left - cursor,
                height = row_height,
                color = BACKGROUND_COLOR,
            ))

        color = (
            BACKGROUND_COLOR
            if level == None
            else CONTRIBUTION_COLORS[level]
        )

        children.append(render.Box(
            width = visible_right - visible_left,
            height = row_height,
            color = color,
        ))

        cursor = visible_right

    # Fill any remaining viewport space, including entirely blank rows.
    if cursor < screen_width:
        children.append(render.Box(
            width = screen_width - cursor,
            height = row_height,
            color = BACKGROUND_COLOR,
        ))

    return render.Row(
        children = children,
        main_align = "start",
        cross_align = "start",
    )


def render_graph_frame(grid, graph_x, layout):
    screen_width = layout["screen_width"]
    screen_height = layout["screen_height"]

    children = []

    # Explicitly center vertically without a centering wrapper.
    unused_height = max(
        0,
        screen_height - get_graph_height(layout),
    )
    top_padding = unused_height // 2
    bottom_padding = unused_height - top_padding

    if top_padding > 0:
        children.append(render.Box(
            width = screen_width,
            height = top_padding,
            color = BACKGROUND_COLOR,
        ))

    for row in range(7):
        row_height = (
            layout["weekend_height"]
            if row in (0, 6)
            else layout["weekday_height"]
        )

        children.append(render_visible_row(
            grid[row],
            row_height,
            graph_x,
            layout,
        ))

        if row < 6:
            children.append(render.Box(
                width = screen_width,
                height = layout["gap"],
                color = BACKGROUND_COLOR,
            ))

    if bottom_padding > 0:
        children.append(render.Box(
            width = screen_width,
            height = bottom_padding,
            color = BACKGROUND_COLOR,
        ))

    return render.Column(
        children = children,
        main_align = "start",
        cross_align = "start",
    )


def ease_in_out(t):
    return t * t * (3 - 2 * t)


def get_phased_graph(grid, layout):
    if not grid or not grid[0]:
        return render.Box(
            width = layout["screen_width"],
            height = layout["screen_height"],
            color = BACKGROUND_COLOR,
        )

    graph_width = get_graph_width(len(grid[0]), layout)
    screen_width = layout["screen_width"]

    # A short graph does not need a scrolling animation.
    if graph_width <= screen_width:
        return render_graph_frame(grid, 0, layout)

    leading_space = screen_width // 8
    max_scroll = graph_width - screen_width
    total_distance = max_scroll + leading_space

    start_frame = render_graph_frame(
        grid,
        leading_space,
        layout,
    )
    end_frame = render_graph_frame(
        grid,
        -max_scroll,
        layout,
    )

    children = []
    children.extend([start_frame] * HOLD_FRAMES_START)

    # Reuse frames when easing rounds to the same pixel position.
    frames_by_x = {
        leading_space: start_frame,
        -max_scroll: end_frame,
    }

    frame_count = max(2, SCROLL_FRAMES)

    for i in range(frame_count):
        t = float(i) / (frame_count - 1)
        distance = int(ease_in_out(t) * total_distance + 0.5)
        graph_x = leading_space - distance

        if graph_x not in frames_by_x:
            frames_by_x[graph_x] = render_graph_frame(
                grid,
                graph_x,
                layout,
            )

        children.append(frames_by_x[graph_x])

    children.extend([end_frame] * HOLD_FRAMES_END)

    if BLACK_TRANSITION_FRAMES > 0:
        blank_frame = render.Box(
            width = layout["screen_width"],
            height = layout["screen_height"],
            color = BACKGROUND_COLOR,
        )

        children.extend(
            [blank_frame] * BLACK_TRANSITION_FRAMES,
        )

    return render.Animation(children = children)


def message_root(message, layout):
    return render.Root(
        delay = FRAME_DELAY_MS,
        child = render.Box(
            width = layout["screen_width"],
            height = layout["screen_height"],
            color = BACKGROUND_COLOR,
            child = render.Marquee(
                width = layout["screen_width"],
                child = render.Text(message),
            ),
        ),
    )


def main(config):
    layout = get_layout()

    username = config.str("username", "").strip()
    token = config.str("token", "").strip()

    if not username or not token:
        return message_root(
            "Enter username & token",
            layout,
        )

    result = get_contributions(username, token)

    if result["error"]:
        return message_root(result["error"], layout)

    grid = normalize_contributions(result["calendar"])

    if not grid:
        return message_root(
            "GitHub: no valid day values",
            layout,
        )

    return render.Root(
        delay = FRAME_DELAY_MS,
        show_full_animation = True,
        child = get_phased_graph(grid, layout),
    )


def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "GitHub Username",
                desc = "GitHub login name, not your display name.",
                icon = "person",
            ),
            schema.Text(
                id = "token",
                name = "Personal Access Token",
                desc = """Create a GitHub personal access token:

Documented classic-token setup:
1. Open GitHub Settings > Developer settings.
2. Select Personal access tokens > Tokens (classic).
3. Generate a token named "Tronbyt Contributions".
4. Choose an expiration, such as 90 days.
5. Select read:user. Do not grant the broad repo scope
   just for this contribution-calendar query.
6. Copy the token and paste it here.

Classic tokens begin with ghp_.
Fine-grained tokens begin with github_pat_ and use a
different permission model; this app does not prescribe
a tested fine-grained permission configuration.

Private/internal contribution visibility depends on
GitHub permissions, profile settings, and organization
policies. This app does not bypass those restrictions.

Keep your token secret. Replace it here when it expires.""",
                icon = "key",
                secret = True,
            ),
        ],
    )