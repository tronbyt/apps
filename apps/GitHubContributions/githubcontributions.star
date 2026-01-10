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
CACHE_TTL = 3600*4  # 4 hours
CACHE_PREFIX = "github_contributions_"

# Exact GitHub contribution colors (0-4 levels)
CONTRIBUTION_COLORS = [
    "#1a1a1a",  # 0
    "#9be9a8",  # 1-2
    "#40c463",  # 3-4
    "#30a14e",  # 5-9
    "#216e39",  # 10+
]

def get_contributions(username, token):
    """Fetch contribution calendar via GitHub GraphQL"""
    cache_key = "{}_{}".format(CACHE_PREFIX, username.lower())
    cached = cache.get(cache_key)
    if cached:
        return json.decode(cached)

    query = """
    query($username: String!, $from: DateTime!, $to: DateTime!) {
      user(login: $username) {
        contributionsCollection(from: $from, to: $to) {
          contributionCalendar {
            totalContributions
            weeks {
              firstDay
              contributionDays {
                date
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

    from_date = (time.now() - time.parse_duration("2130h")).format("2006-01-02T15:04:05Z")
    to_date = time.now().format("2006-01-02T15:04:05Z")

    body = json.encode({
        "query": query,
        "variables": {"username": username, "from": from_date, "to": to_date},
    })

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
    """Convert weeks → 7xN grid [weekday][week]"""
    if not weeks_data or not weeks_data.get("weeks"):
        return []

    number_weeks = 13 if canvas.is2x() else 12

    weeks = weeks_data["weeks"][-number_weeks:]
    grid = [[0 for _ in weeks] for _ in range(7)]  # 7 days x N weeks

    for week_idx, week in enumerate(weeks):
        if week_idx >= len(grid[0]):
            break
        for day in week.get("contributionDays", []):
            weekday = int(day["weekday"])
            count = int(day["contributionCount"])
            grid[weekday][week_idx] = min(count, 4)  # Cap at level 4

    return grid

def render_contribution_graph(grid):
    cols = len(grid[0])  # 10
    cell_width = 8 if canvas.is2x() else 4  # Fixed 4px instead of dynamic ~5px
    weekday_height = 8 if canvas.is2x() else 4
    weekend_height = 8 if canvas.is2x() else 3
    left_padding = 6 if canvas.is2x() else 2

    children = []

    if canvas.is2x():
        children.append(render.Box(width = left_padding + cols * cell_width + (cols - 1) * 1, height = 1, color = "#000"))

    for row in range(7):  # Days (Sun-Sat): 0=Sun, 6=Sat
        cell_height = weekend_height if row in (0, 6) else weekday_height

        row_children = []

        # left_padding px left padding
        row_children.append(render.Box(width = left_padding, height = cell_height, color = "#000"))

        # Grid cells - now 4px wide
        for col in range(cols):
            level = grid[row][col]
            color = CONTRIBUTION_COLORS[level]
            row_children.append(render.Box(width = cell_width, height = cell_height, color = color))
            if col < cols - 1:
                row_children.append(render.Box(width = 1, height = cell_height, color = "#000"))

        children.append(render.Row(expanded = True, main_align = "start", children = row_children))

        # Separator matches new total width (2+40+9=51px)
        if row < 6:
            children.append(render.Row(
                expanded = True,
                main_align = "start",
                children = [render.Box(width = 51, height = 1, color = "#000")],
            ))

    return render.Column(main_align = "start", children = children)

def main(config):
    username = config.str("username", "")
    token = config.str("token", "")

    if not username or not token:
        return render.Root(
            child = render.Marquee(
                child = render.Text("Enter username & token", color = "#f00"),
                width = 64,
            ),
        )

    data = get_contributions(username, token)

    if not data or not data.get("data", {}).get("user"):
        return render.Root(
            child = render.Marquee(
                child = render.Text("No contributions", color = "#f80"),
                width = 64,
            ),
        )

    weeks_data = data["data"]["user"]["contributionsCollection"]["contributionCalendar"]
    grid = normalize_contributions(weeks_data)

    return render.Root(
        delay = 3000,
        show_full_animation = True,
        child = render.Column(
            children = [
                render_contribution_graph(grid),
            ],
        ),
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
                desc = """Step 1: Github.com → Profile Picture  → Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token
Step 2:. Name: "Tronbyt Contributions" | Expiration: 90 days | Select Repositories | Permissions: Add 3 Items:
Repositories: Metadata: Read Only → Account: Email Address: Read Only → Account: Profile: Read Only
3. Copy the token (ghp_xxx...) and paste it here.""
""",
                icon = "key",
                secret = True,
            ),
        ],
    )
