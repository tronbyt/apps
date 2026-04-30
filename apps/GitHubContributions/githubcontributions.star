"""
Applet: GitHub Contributions
Summary: Your GitHub contribution graph
Description: 7xN heatmap of your recent GitHub contributions. 
Setup: Get PAT at github.com/settings/tokens (repo scope)
Author: Robert Ison
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

GITHUB_GRAPHQL_URL = "https://api.github.com/graphql"
CACHE_TTL = 3600 * 4
CACHE_PREFIX = "github_contributions_"

CONTRIBUTION_COLORS = [
    "#1a1a1a",
    "#9be9a8",
    "#40c463",
    "#30a14e",
    "#216e39",
]

def get_contributions(username, token):
    cache_key = "{}_{}".format(CACHE_PREFIX, username.lower())
    cached = cache.get(cache_key)
    if cached:
        return json.decode(cached)

    query = """
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

    headers = {
        "Authorization": "bearer %s" % token,
        "Content-Type": "application/json",
    }

    from_date = (time.now() - time.parse_duration("3360h")).format("2006-01-02T15:04:05Z")
    to_date = time.now().format("2006-01-02T15:04:05Z")

    body = json.encode({
        "query": query,
        "variables": {"username": username, "from": from_date, "to": to_date},
    })

    req = http.post(GITHUB_GRAPHQL_URL, headers = headers, body = body)

    if req.status_code != 200:
        return None

    data = req.json()
    cache.set(cache_key, json.encode(data), ttl_seconds = CACHE_TTL)
    return data

def normalize_contributions(weeks_data):
    if not weeks_data or not weeks_data.get("weeks"):
        return []

    # Last 20 weeks
    weeks = weeks_data["weeks"][-20:]
    grid = [[0 for _ in weeks] for _ in range(7)]

    for week_idx, week in enumerate(weeks):
        for day in week.get("contributionDays", []):
            weekday = int(day["weekday"])
            count = int(day["contributionCount"])
            grid[weekday][week_idx] = (
                (1 if count > 0 else 0) +
                (1 if count >= 3 else 0) +
                (1 if count >= 5 else 0) +
                (1 if count >= 10 else 0)
            )

    return grid

def render_contribution_graph(grid):
    if not grid or not grid[0]:
        return render.Box()

    cols = len(grid[0])
    cell_width = 8 if canvas.is2x() else 4
    weekday_height = 8 if canvas.is2x() else 4
    weekend_height = 8 if canvas.is2x() else 3
    left_padding = 6 if canvas.is2x() else 2

    children = []

    for row in range(7):
        cell_height = weekend_height if row in (0, 6) else weekday_height
        row_children = []

        # Left padding
        row_children.append(render.Box(width = left_padding, height = cell_height, color = "#000"))

        for col in range(cols):
            level = grid[row][col]
            color = CONTRIBUTION_COLORS[level]
            row_children.append(render.Box(width = cell_width, height = cell_height, color = color))
            if col < cols - 1:
                # 1px gap
                row_children.append(render.Box(width = 1, height = cell_height, color = "#000"))

        children.append(render.Row(children = row_children))

        if row < 6:
            # Horizontal gap between rows
            children.append(render.Row(
                children = [render.Box(width = left_padding + cols * cell_width + (cols - 1), height = 1, color = "#000")],
            ))

    return render.Column(children = children)

def get_graph_width(cols):
    cell_width = 8 if canvas.is2x() else 4
    gap = 1
    left_padding = 6 if canvas.is2x() else 2
    return left_padding + cols * cell_width + (cols - 1) * gap

def ease_in_out(t):
    # Smooth step: starts slow, speeds up, slows down
    return t * t * (3 - 2 * t)

def viewport_frame(graph, offset, screen_width):
    # offset: 0         = leftmost view
    # offset: max_scroll = last week at right edge
    #
    # We use Marquee as a fixed-position viewport by pinning start=end.
    return render.Marquee(
        width = screen_width,
        child = graph,
        offset_start = -offset,
        offset_end = -offset,
    )

def get_phased_graph(grid):
    graph = render_contribution_graph(grid)

    if not grid or not grid[0]:
        return graph

    cols = len(grid[0])
    graph_width = get_graph_width(cols)
    screen_width = 128 if canvas.is2x() else 64
    
    # We want "half a screen" of black space at the start
    leading_space = screen_width // 8
    
    # Total scrollable distance now includes that extra leading space
    # We start at -leading_space and end at max_scroll
    max_scroll = graph_width - screen_width

    hold_frames = 15 
    hold_frames_end = 100  
    scroll_frames = 90 # Increased slightly because we're traveling further now
    children = []

    def make_frame(x_offset):
        return render.Box(
            width = screen_width,
            height = 32 if not canvas.is2x() else 64,
            child = render.Padding(
                # Adding leading_space to the offset to push the start of the graph 
                # into the middle of the screen initially.
                pad = (int(leading_space - x_offset), 0, 0, 0),
                child = graph,
            )
        )

    # 1) Start: Graph is pushed halfway into the screen, pause 3s
    start_frame = make_frame(0)
    children.extend([start_frame] * hold_frames)

    # 2) Scroll: Move from the starting "half-black" view to the end
    # We calculate the total distance to cover both the leading space AND the graph width
    total_distance = max_scroll + leading_space
    
    for i in range(scroll_frames):
        t = float(i) / scroll_frames
        eased = ease_in_out(t)
        # We scroll from 0 offset to the total distance
        children.append(make_frame(eased * total_distance))

    # 3) End: Current week is aligned to the right edge, pause 3s
    # After this, the Tidbyt loop will restart the animation from the beginning.
    end_frame = make_frame(total_distance)
    children.extend([end_frame] * hold_frames_end)

    # Fade to black/blank for 1 second before the loop restarts
    blank_frame = render.Box(width = screen_width, height = 32 if not canvas.is2x() else 64, color = "#000")
    children.extend([blank_frame] * 10)

    return render.Animation(children = children)
    
def main(config):
    username = config.str("username", "")
    token = config.str("token", "")

    if not username or not token:
        return render.Root(
            child = render.Text("Enter username & token"),
        )

    data = get_contributions(username, token)

    if not data or not data.get("data", {}).get("user"):
        return render.Root(
            child = render.Text("No contributions"),
        )

    weeks_data = data["data"]["user"]["contributionsCollection"]["contributionCalendar"]
    grid = normalize_contributions(weeks_data)

    return render.Root(
        delay = 100,  # 100ms per frame
        show_full_animation = True,
        child = get_phased_graph(grid),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "GitHub Username",
                desc = "Your GitHub username",
                icon = "person",
            ),
            schema.Text(
                id = "token",
                name = "Personal Access Token",
                desc = """Instructions to get a Personal Access Token:
1. Go to `github.com` → Profile Picture → Settings → Developer settings → Personal access tokens → Fine-grained tokens → **Generate new token**.
2. Use these settings:
    - **Name**: `Tronbyt Contributions`
    - **Expiration**: 90 days
    - **Permissions**: Grant read-only access for `Metadata`, `Email Address`, and `Profile`.
3. Copy the token (`ghp_...`) and paste it here. You won't see it again!""",
                icon = "key",
                secret = True,
            ),
        ],
    )
