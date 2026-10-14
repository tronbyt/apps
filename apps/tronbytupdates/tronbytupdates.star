"""
Applet: Tronbyt Updates
Summary: Display the latest app changes available on Tronbyt.
Description: Shows recently changed apps from a GitHub repository, using current app metadata.
Author: Robert Ison
"""

load("encoding/yaml.star", "yaml")
load("http.star", "http")
load("humanize.star", "humanize")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")


DEFAULT_REPO = "Tronbyt/apps"
DEFAULT_BRANCH = "main"

MAX_COMMITS = 30
MAX_ITEMS = 6

# Bound the work needed for unusually large commits.
FILES_PER_PAGE = 100
MAX_FILE_PAGES = 3

CACHE_TTL_UNAUTHENTICATED = 28800  # 8 hours
CACHE_TTL_AUTHENTICATED = 3600     # 1 hour

TRONBYT_PALETTE = [
    "#00FFFF",
    "#FFAA00",
    "#00FF00",
    "#0000FF",
    "#FFFF00",
    "#FF0000",
]

SCROLL_SPEED_OPTIONS = [
    schema.Option(display = "Slow Scroll", value = "60"),
    schema.Option(display = "Medium Scroll", value = "45"),
    schema.Option(display = "Fast Scroll", value = "30"),
]


def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "repo",
                name = "GitHub Repository",
                desc = "Repository in owner/name format. Default: Tronbyt/apps.",
                default = DEFAULT_REPO,
                icon = "github",
            ),
            schema.Text(
                id = "branch",
                name = "GitHub Branch",
                desc = "Branch to check. Default: main.",
                default = DEFAULT_BRANCH,
                icon = "tree",
            ),
            schema.Text(
                id = "github_token",
                name = "GitHub Token",
                desc = "Optional GitHub token. Refresh interval: 1 hour with a token, 8 hours without one.",
                default = "",
                icon = "key",
                secret = True,
            ),
            schema.Toggle(
                id = "hide_on_error",
                name = "Hide if no updates or errors.",
                desc = "Hide when there are no qualifying changes or no usable results. Partial results are displayed with a warning.",
                icon = "eye",
                default = True,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = SCROLL_SPEED_OPTIONS,
                default = "60",
            ),
            schema.Toggle(
                id = "instructions",
                name = "Display Instructions",
                desc = "Show setup and refresh information.",
                icon = "book",
                default = False,
            ),
        ],
    )


def get_delay(config):
    value = config.str("scroll", "60")

    # Avoid failing on an unexpected or stale configuration value.
    if value not in ["60", "45", "30"]:
        value = "60"

    delay = int(value)
    return delay // 2 if canvas.is2x() else delay


def get_fonts():
    if canvas.is2x():
        return {
            "small": "terminus-16",
            "large": "terminus-18",
            "small_width": 8,
            "large_width": 9,
        }

    return {
        "small": "5x8",
        "large": "5x8",
        "small_width": 5,
        "large_width": 5,
    }


def clean_text(value):
    if value == None:
        return ""

    return " ".join(str(value).split())


def person_name(value):
    if type(value) == "dict":
        return clean_text(
            value.get("name") or
            value.get("username") or
            value.get("login"),
        )

    return clean_text(value)


def normalize_authors(value):
    if type(value) == "list" or type(value) == "tuple":
        names = []

        for person in value:
            name = person_name(person)

            if name != "" and name not in names:
                names.append(name)

        return ", ".join(names) if names else "Unknown"

    return person_name(value) or "Unknown"


def is_broken(value):
    if value == None:
        return False

    return str(value).strip().lower() in [
        "true",
        "yes",
        "1",
        "on",
    ]


def validate_repo(repo):
    parts = repo.split("/")

    if len(parts) != 2:
        return False

    allowed = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_."

    for part in parts:
        if part == "" or part == "." or part == "..":
            return False

        for character in part.elems():
            if character not in allowed:
                return False

    return True


def encode_component(value):
    # url_encode uses query escaping; paths need %20 rather than +.
    return humanize.url_encode(value).replace("+", "%20")


def get_headers(token, raw = False):
    headers = {
        "Accept": (
            "application/vnd.github.raw+json"
            if raw else
            "application/vnd.github+json"
        ),
    }

    if token:
        headers["Authorization"] = "Bearer " + token

    return headers


def api_error(context, status_code):
    if status_code == 401:
        reason = "token rejected"
    elif status_code == 403:
        reason = "access denied or rate limited"
    elif status_code == 404:
        reason = "not found or not accessible"
    elif status_code == 429:
        reason = "rate limited"
    else:
        reason = "request failed"

    return "%s: HTTP %s (%s)" % (
        context,
        status_code,
        reason,
    )


def add_warning(warnings, message):
    if message and message not in warnings:
        warnings.append(message)


def get_changed_apps(commit_sha, repo, headers, cache_ttl):
    apps = []
    error = ""

    for page in range(1, MAX_FILE_PAGES + 1):
        url = "https://api.github.com/repos/%s/commits/%s?per_page=%s&page=%s" % (
            repo,
            commit_sha,
            FILES_PER_PAGE,
            page,
        )

        response = http.get(
            url = url,
            headers = headers,
            ttl_seconds = cache_ttl * 2,
        )

        if response.status_code != 200:
            error = api_error("Commit details", response.status_code)
            break

        details = response.json()

        if type(details) != "dict":
            error = "Unexpected commit-details response"
            break

        files = details.get("files", [])

        if type(files) != "list":
            error = "Unexpected changed-files response"
            break

        for changed_file in files:
            if type(changed_file) != "dict":
                continue

            # Include both sides of a rename.
            paths = [
                changed_file.get("filename", ""),
                changed_file.get("previous_filename", ""),
            ]

            for path in paths:
                if not path.startswith("apps/"):
                    continue

                parts = path.split("/")

                if len(parts) >= 3 and parts[1]:
                    folder = parts[1]

                    if folder not in apps:
                        apps.append(folder)

        if len(files) < FILES_PER_PAGE:
            break

        if page == MAX_FILE_PAGES:
            error = "Large commit: file scan may be incomplete"

    return {
        "apps": apps,
        "error": error,
    }
    
    
def get_manifest_info(app_folder, repo, snapshot_sha, headers, cache_ttl):
    for filename in ["manifest.yaml", "manifest.yml"]:
        url = "https://api.github.com/repos/%s/contents/apps/%s/%s?ref=%s" % (
            repo,
            encode_component(app_folder),
            filename,
            encode_component(snapshot_sha),
        )

        response = http.get(
            url = url,
            headers = headers,
            ttl_seconds = cache_ttl,
        )

        if response.status_code == 404:
            continue

        if response.status_code != 200:
            return {
                "info": None,
                "error": api_error("App metadata", response.status_code),
            }

        manifest = yaml.decode(response.body())

        if type(manifest) != "dict":
            return {
                "info": None,
                "error": "Invalid metadata for " + app_folder,
            }

        if is_broken(manifest.get("broken")):
            return {
                "info": None,
                "error": "",
            }

        name = clean_text(manifest.get("name"))

        if not name:
            return {
                "info": None,
                "error": "Missing app name for " + app_folder,
            }

        authors = manifest.get("authors") or manifest.get("author")

        description = clean_text(
            manifest.get("description") or
            manifest.get("desc") or
            manifest.get("summary"),
        )

        return {
            "info": {
                "name": name,
                "author": normalize_authors(authors),
                "description": description,
            },
            "error": "",
        }

    # No current manifest: ignore removed folders or non-app directories.
    return {
        "info": None,
        "error": "",
    }


def find_recent_app_changes(repo, branch, token, cache_ttl):
    headers = get_headers(token)
    raw_headers = get_headers(token, raw = True)

    commits_url = "https://api.github.com/repos/%s/commits?sha=%s&per_page=%s" % (
        repo,
        humanize.url_encode(branch),
        MAX_COMMITS,
    )

    response = http.get(
        url = commits_url,
        headers = headers,
        ttl_seconds = cache_ttl,
    )

    if response.status_code != 200:
        return {
            "items": [],
            "warnings": [],
            "error": api_error("Commit list", response.status_code),
        }

    commits = response.json()

    if type(commits) != "list":
        return {
            "items": [],
            "warnings": [],
            "error": "Unexpected commit-list response",
        }

    if not commits:
        return {
            "items": [],
            "warnings": [],
            "error": "",
        }

    if type(commits[0]) != "dict" or not commits[0].get("sha"):
        return {
            "items": [],
            "warnings": [],
            "error": "Missing branch snapshot",
        }

    # Use the newest commit from this cached branch listing.
    # Every manifest is read from the same snapshot.
    snapshot_sha = commits[0]["sha"]

    items = []
    warnings = []
    seen_folders = []

    for entry in commits:
        if type(entry) != "dict":
            add_warning(warnings, "Unexpected commit entry")
            continue

        commit_sha = entry.get("sha")

        if not commit_sha:
            add_warning(warnings, "Commit missing SHA")
            continue

        commit = entry.get("commit") or {}

        if type(commit) != "dict":
            add_warning(warnings, "Unexpected commit metadata")
            continue

        message = str(commit.get("message") or "")
        change = clean_text(message.split("\n")[0]) or "App files changed"

        committer = commit.get("committer") or {}
        author = commit.get("author") or {}

        commit_date = clean_text(
            committer.get("date") or author.get("date"),
        )

        changed = get_changed_apps(
            commit_sha,
            repo,
            headers,
            cache_ttl,
        )

        add_warning(warnings, changed["error"])

        for folder in changed["apps"]:
            if folder in seen_folders:
                continue

            # Keep only the newest observed change for each folder.
            seen_folders.append(folder)

            metadata = get_manifest_info(
                folder,
                repo,
                snapshot_sha,
                raw_headers,
                cache_ttl,
            )

            add_warning(warnings, metadata["error"])

            info = metadata["info"]

            if info == None:
                continue

            items.append({
                "app_folder": folder,
                "app_name": info["name"],
                "author": info["author"],
                "app_description": info["description"],
                "commit_date": commit_date,
                "change": change,
                "commit_sha": commit_sha,
            })

            if len(items) >= MAX_ITEMS:
                break

        if len(items) >= MAX_ITEMS:
            break

    return {
        "items": items,
        "warnings": warnings,
        "error": "",
    }


def render_lines(config, lines, colors):
    fonts = get_fonts()
    children = []
    offset = 0

    for index in range(len(lines)):
        is_title = index == 0
        font = fonts["large"] if is_title else fonts["small"]
        character_width = (
            fonts["large_width"] if is_title else fonts["small_width"]
        )

        children.append(
            render.Marquee(
                width = canvas.width(),
                offset_start = offset,
                child = render.Text(
                    lines[index],
                    font = font,
                    color = colors[index],
                ),
            ),
        )

        offset += character_width * len(lines[index]) // 2

    return render.Root(
        child = render.Column(children = children),
        show_full_animation = True,
        delay = get_delay(config),
    )


def display_instructions(config):
    return render_lines(
        config,
        [
            "Tronbyt Updates",
            "Shows up to 6 distinct apps changed in the latest 30 commits. Set a repository and branch.",
            "Optional GitHub token: refresh every 1 hour. Without a token: every 8 hours.",
            "Uses metadata from the latest checked branch snapshot. Broken apps and missing manifests are skipped.",
        ],
        [
            TRONBYT_PALETTE[0],
            TRONBYT_PALETTE[1],
            TRONBYT_PALETTE[1],
            TRONBYT_PALETTE[2],
        ],
    )


def display_error(config, message):
    return render_lines(
        config,
        ["Tronbyt Updates", message],
        [TRONBYT_PALETTE[5], TRONBYT_PALETTE[1]],
    )


def hide_or_error(config, message):
    if config.bool("hide_on_error", True):
        return []

    return display_error(config, message)


def join_names(names):
    if not names:
        return ""

    if len(names) == 1:
        return names[0]

    if len(names) == 2:
        return names[0] + " and " + names[1]

    return ", ".join(names[:-1]) + " and " + names[-1]


def display_updates(config, items, warnings):
    # Avoid random.number(0, 0) and ambiguity about its upper bound.
    index = 0

    if len(items) > 1:
        index = min(
            int(random.float() * len(items)),
            len(items) - 1,
        )

    selected = items[index]
    other_names = []

    for item in items:
        if item["app_folder"] == selected["app_folder"]:
            continue

        name = item["app_name"]

        if name not in other_names:
            other_names.append(name)

    row1 = "%s by %s" % (
        selected["app_name"],
        selected["author"],
    )

    row2 = "Changes: " + selected["change"]

    if selected["app_description"]:
        row2 = selected["app_description"] + " - " + row2

    lines = [row1, row2]
    colors = [TRONBYT_PALETTE[0], TRONBYT_PALETTE[1]]

    row3 = ""

    if other_names:
        row3 = "Also updated: " + join_names(other_names)

    if warnings:
        warning_text = "Partial results: " + "; ".join(warnings)
        row3 = row3 + " | " + warning_text if row3 else warning_text

    if row3:
        lines.append(row3)
        colors.append(
            TRONBYT_PALETTE[1] if warnings else TRONBYT_PALETTE[2],
        )

    return render_lines(config, lines, colors)


def main(config):
    if config.bool("instructions", False):
        return display_instructions(config)

    repo = (config.str("repo", DEFAULT_REPO) or "").strip()
    branch = (config.str("branch", DEFAULT_BRANCH) or "").strip()
    token = (config.str("github_token", "") or "").strip()

    repo = repo or DEFAULT_REPO
    branch = branch or DEFAULT_BRANCH

    if not validate_repo(repo):
        return hide_or_error(
            config,
            "Invalid repository. Use owner/name.",
        )

    cache_ttl = (
        CACHE_TTL_AUTHENTICATED
        if token else
        CACHE_TTL_UNAUTHENTICATED
    )

    result = find_recent_app_changes(
        repo,
        branch,
        token,
        cache_ttl,
    )

    if not result["items"]:
        message = result["error"]

        if not message and result["warnings"]:
            message = "; ".join(result["warnings"])

        if not message:
            message = "No qualifying app changes in the latest 30 commits."

        return hide_or_error(config, message)

    return display_updates(
        config,
        result["items"],
        result["warnings"],
    )