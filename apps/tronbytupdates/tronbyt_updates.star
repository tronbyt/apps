"""
Applet: TronByt Updates
Summary:   Display new and updated Apps available on TronByt.
Description: This app shows recently added or updated apps on TronByt by fetching data from a specified GitHub repository.
Author: Robert Ison
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_REPO = "tronbyt/apps"
DEFAULT_BRANCH = "main"
MAX_COMMITS = 20
MAX_ITEMS = 10

CACHE_TTL_UNAUTHENTICATED = 14400  # 4 hours
CACHE_TTL_AUTHENTICATED = 1800  # 30 minutes

SCROLL_SPEED_OPTIONS = [
    schema.Option(
        display = "Slow Scroll",
        value = "60",
    ),
    schema.Option(
        display = "Medium Scroll",
        value = "45",
    ),
    schema.Option(
        display = "Fast Scroll",
        value = "30",
    ),
]

def display_instructions(config, is_double_size):
    delay = int(config.get("scroll", 45))
    delay = int(delay / 2) if is_double_size else delay

    font = "5x8" if not is_double_size else "terminus-14"

    ##############################################################################################################################################################################################################################
    instructions_1 = "This app shows recently added or updated apps on TronByt from the tronbyt/apps GitHub repository, however you can change to another TronByt App repository."
    instructions_2 = "Enter GitHub Personal Access Token for more frequent updates. GitHub.com go to Settings → Developer settings → Personal access tokens → Tokens (classic) → "
    instructions_3 = "→ Generate new token (classic)  Select 'repo' scope → Copy token. Leave empty for less frequent updates."
    return render.Root(
        render.Column(
            children = [
                render.Marquee(
                    width = canvas.width(),
                    child = render.Text("TronByt Updates", color = "#00FFFF", font = font),
                ),
                render.Marquee(
                    width = canvas.width(),
                    child = render.Text(instructions_1, color = "#FFAA00", font = font),
                ),
                render.Marquee(
                    offset_start = len(instructions_1) * 5,
                    width = canvas.width(),
                    child = render.Text(instructions_2, color = "#FFAA00", font = font),
                ),
                render.Marquee(
                    offset_start = (len(instructions_2) + len(instructions_1)) * 5,
                    width = canvas.width(),
                    child = render.Text(instructions_3, color = "#FFAA00", font = font),
                ),
            ],
        ),
        show_full_animation = True,
        delay = delay,
    )

def get_app_from_files(commit_details):
    files = commit_details.get("files", [])
    apps = []
    for f in files:
        path = f.get("filename", "")
        if path.startswith("apps/"):
            parts = path.split("/")
            if len(parts) >= 3:
                app = parts[1]
                if app not in apps:
                    apps.append(app)
    return apps

def get_manifest_info(app_folder, tree_sha, headers, cache_ttl):
    tree_url = "https://api.github.com/repos/tronbyt/apps/git/trees/{}?recursive=1".format(tree_sha)
    resp = http.get(url = tree_url, headers = headers, ttl_seconds = cache_ttl)
    if resp.status_code != 200:
        return None

    tree = resp.json().get("tree", [])

    manifest_url = None
    for item in tree:
        path = item.get("path", "")
        if (path.startswith("apps/{}/".format(app_folder)) and
            ("manifest" in path.lower()) and
            item["type"] == "blob"):
            manifest_url = item["url"]
            break

    if not manifest_url:
        return None

    resp = http.get(url = manifest_url, headers = headers, ttl_seconds = cache_ttl)
    if resp.status_code != 200:
        return None

    data = resp.json()
    content = base64.decode(data.get("content", ""))

    if content.startswith("---"):
        end = content.find("\n---\n")
        if end != -1:
            content = content[end + 5:]

    lines = content.split("\n")
    manifest = {}
    for line in lines:
        line = line.strip()
        if ":" in line and not line.startswith("#"):
            parts = line.split(":", 1)
            key = parts[0].strip().lower()
            value = parts[1].strip()
            if key == "name":
                manifest["name"] = value
            elif key in ["author", "authors"]:
                manifest["author"] = value
            elif key in ["desc", "description", "summary"]:
                manifest["description"] = value

    if manifest.get("broken", False):
        return None

    if manifest.get("name"):
        return {
            "name": manifest["name"],
            "author": manifest.get("author", "Unknown"),
            "description": manifest.get("description", ""),
        }

    return None

def summarize_commit(commit_details, headers, cache_ttl):
    change = commit_details["commit"]["message"].split("\n")[0]
    commit_date = commit_details["commit"]["author"]["date"][:16]
    apps = get_app_from_files(commit_details)

    if not apps:
        return None

    app_folder = apps[0]
    tree_sha = commit_details["commit"]["tree"]["sha"]

    manifest_info = get_manifest_info(app_folder, tree_sha, headers, cache_ttl)
    if manifest_info:
        return {
            "app_name": manifest_info["name"],
            "author": manifest_info["author"],
            "app_description": manifest_info["description"],
            "commit_date": commit_date,
            "change": change,
        }

    return {
        "app_name": app_folder,
        "author": "Unknown",
        "app_description": "",
        "commit_date": commit_date,
        "change": change,
    }

def find_recent_app_changes(repo, branch, headers, cache_ttl, max_commits, max_items):
    commits_url = "https://api.github.com/repos/{}/commits?sha={}&per_page={}".format(repo, branch, max_commits)
    resp = http.get(url = commits_url, headers = headers, ttl_seconds = cache_ttl)
    if resp.status_code != 200:
        return []

    commits = resp.json()
    items = []

    for c in commits:
        details_resp = http.get(url = c["url"], headers = headers, ttl_seconds = cache_ttl)
        if details_resp.status_code != 200:
            continue

        details = details_resp.json()
        if details and details.get("files"):
            summary = summarize_commit(details, headers, cache_ttl)
            if summary:
                items.append(summary)
                if len(items) >= max_items:
                    break
    return items

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "repo",
                name = "GitHub Repository",
                desc = "GitHub repository (default: tronbyt/apps)",
                default = DEFAULT_REPO,
                icon = "github",
            ),
            schema.Text(
                id = "branch",
                name = "GitHub Branch",
                desc = "GitHub branch (default: main)",
                default = DEFAULT_BRANCH,
                icon = "tree",
            ),
            schema.Text(
                id = "github_token",
                name = "GitHub Token",
                desc = "GitHub Personal Access Token for higher rate limits (30min cache). Get from: Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token (classic) → Select 'repo' scope → Copy token. Leave empty for 4hr cache (unauthenticated).",
                default = "",
                icon = "key",
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = SCROLL_SPEED_OPTIONS,
                default = SCROLL_SPEED_OPTIONS[0].value,
            ),
            schema.Toggle(
                id = "instructions",
                name = "Display Instructions",
                desc = "",
                icon = "book",
                default = False,
            ),
        ],
    )

def main(config):
    show_instructions = config.bool("instructions", False)
    if show_instructions:
        return display_instructions(config, canvas.is2x())

    github_token = config.get("github_token", "").strip()

    if github_token:
        headers = {"Authorization": "token {}".format(github_token)}
        cache_ttl = CACHE_TTL_AUTHENTICATED
    else:
        headers = {}
        cache_ttl = CACHE_TTL_UNAUTHENTICATED

    repo = config.get("repo", DEFAULT_REPO)
    branch = config.get("branch", DEFAULT_BRANCH)

    items = find_recent_app_changes(
        repo = repo,
        branch = branch,
        headers = headers,
        cache_ttl = cache_ttl,
        max_commits = MAX_COMMITS,
        max_items = MAX_ITEMS,
    )

    if not items:
        return []
    else:
        # Pick random index instead
        random.seed(int(time.now().unix))
        random_index = int(random.number(0, len(items)))
        selected_item = items[random_index]

        # Get other app names (comma delimited with "and")
        other_app_names = []
        for idx, item in enumerate(items):
            if idx != random_index:
                other_app_names.append(item["app_name"])

        # Fancy comma list with "and"
        if len(other_app_names) == 0:
            other_list_text = ""
        elif len(other_app_names) == 1:
            other_list_text = other_app_names[0]
        elif len(other_app_names) == 2:
            other_list_text = "{} and {}".format(other_app_names[0], other_app_names[1])
        else:
            # "App1, App2, App3 and App4"
            other_list_text = ", ".join(other_app_names[:-1]) + " and " + other_app_names[-1]

        screen_width = canvas.width()

        if canvas.is2x():
            small_font = "terminus-16"
            large_font = "terminus-18"
            small_font_width = 16
            large_font_width = 18

        else:
            small_font = "5x8"
            large_font = "5x8"
            small_font_width = 6
            large_font_width = 8

        row1 = "{} by {}".format(selected_item["app_name"], selected_item["author"])
        row2 = "{} - Changes: {}".format(selected_item["app_description"], selected_item["change"])
        row3 = "Also updated: {}".format(other_list_text)

        row2_offset = large_font_width * len(row1) // 2
        row3_offset = row2_offset + ((small_font_width * len(row2)) // 2)

        body = render.Column(
            children = [
                render.Marquee(render.Text(row1, font = large_font, color = "#00FFFF"), width = screen_width),
                render.Marquee(render.Text(row2, font = small_font, color = "#FFAA00"), width = screen_width, offset_start = row2_offset),
                render.Marquee(render.Text(row3, font = small_font, color = "#00FF00"), width = screen_width, offset_start = row3_offset),
            ],
        )

    delay = int(config.get("scroll", 45))
    delay = int(delay / 2) if canvas.is2x() else delay

    return render.Root(
        child = body,
        show_full_animation = True,
        delay = delay,
    )
