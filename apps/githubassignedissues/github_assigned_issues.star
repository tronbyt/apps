"""
Applet: GitHub Assigned Issues
Summary: GitHub assigned issue count
Description: Displays the count of open GitHub issues assigned to you.
Author: tavdog
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("images/github_image.png", GITHUB_IMAGE_ASSET = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")

GITHUB_IMAGE = GITHUB_IMAGE_ASSET.readall()

def github_headers(access_token):
    return {
        "Accept": "application/vnd.github+json",
        "Authorization": "Bearer {}".format(access_token),
        "X-GitHub-Api-Version": "2022-11-28",
    }

def fetch_user_login(access_token):
    response = http.get(
        "https://api.github.com/user",
        headers = github_headers(access_token),
        ttl_seconds = 3600,
    )
    if response.status_code != 200:
        return ""

    login = response.json().get("login", "")
    if login == None:
        return ""

    return login

def repo_scope_error(repo_scope, repo_filter, user_login):
    repo_filter = (repo_filter or "").strip()
    if repo_scope == "single" and repo_filter == "":
        return "Set repository."

    if repo_scope == "org" and repo_filter == "":
        return "Set organization."

    if repo_scope == "mine" and user_login == "":
        return "Could not load user."

    return ""

def build_issue_query(state, repo_scope, repo_filter, user_login):
    err = repo_scope_error(repo_scope, repo_filter, user_login)
    if err != "":
        return None

    query = "assignee:@me is:{} is:issue".format(state)
    repo_filter = (repo_filter or "").strip()

    if repo_scope == "single":
        query = query + " repo:" + repo_filter
    elif repo_scope == "org":
        query = query + " org:" + repo_filter
    elif repo_scope == "mine":
        query = query + " user:" + user_login

    return query

def fetch_assigned_issues(access_token, query):
    if query == None:
        return None

    return http.get(
        "https://api.github.com/search/issues?q=" + humanize.url_encode(query),
        headers = github_headers(access_token),
        ttl_seconds = 60,
    )

def repo_filter_fields(repo_scope):
    if repo_scope == "org":
        return [
            schema.Text(
                id = "repo_filter",
                name = "Organization",
                desc = "GitHub organization login (e.g. tronbyt).",
                icon = "building",
            ),
        ]

    if repo_scope == "single":
        return [
            schema.Text(
                id = "repo_filter",
                name = "Repository",
                desc = "Repository as owner/name (e.g. tronbyt/apps).",
                icon = "github",
            ),
        ]

    return []

def get_count(response):
    body = response.json()
    if "total_count" not in body:
        return 0

    return int(body["total_count"])

def count_font():
    if canvas.is2x():
        return "terminus-16"

    return "6x13"

def count_display(open_count, closed_count, display_mode, open_color, closed_color, text_color):
    font = count_font()
    open_count = int(open_count)
    closed_count = int(closed_count)

    if display_mode == "both":
        return render.Row(
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(content = str(open_count), font = font, color = open_color),
                render.Text(content = " - ", font = font, color = text_color),
                render.Text(content = str(closed_count), font = font, color = closed_color),
            ],
        )

    if display_mode == "closed":
        return render.Text(content = str(closed_count), font = font, color = closed_color)

    return render.Text(content = str(open_count), font = font, color = open_color)

def render_assigned_tasks(open_count, closed_count, display_mode, label, text_color, open_color, closed_color):
    return render.Root(
        # Laid out for 64x32; bound it to that and centre it on taller panels (64x64).
        child = render.Box(width = canvas.width(), height = canvas.height(), child = render.Box(width = 64, height = 32, child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.Box(
                    width = 64,
                    height = 16,
                    child = render.Row(
                        expanded = True,
                        main_align = "space_around",
                        cross_align = "center",
                        children = [
                            render.Padding(
                                pad = (1, 1, 1, 1),
                                child = render.Image(GITHUB_IMAGE, height = 12),
                            ),
                            render.Padding(
                                pad = (1, 1, 1, 1),
                                child = count_display(
                                    open_count,
                                    closed_count,
                                    display_mode,
                                    open_color,
                                    closed_color,
                                    text_color,
                                ),
                            ),
                        ],
                    ),
                ),
                render.Box(
                    width = 64,
                    height = 16,
                    child = render.Row(
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(content = label, color = text_color),
                        ],
                    ),
                ),
            ],
        ))),
    )

def render_error(err, text_color):
    return render.Root(
        # Laid out for 64x32; bound it to that and centre it on taller panels (64x64).
        child = render.Box(width = canvas.width(), height = canvas.height(), child = render.Box(width = 64, height = 32, child = render.Stack(
            children = [
                render.Padding(
                    pad = (0, 2, 0, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "space_around",
                        cross_align = "center",
                        children = [
                            render.Padding(
                                pad = (1, 1, 1, 1),
                                child = render.Image(GITHUB_IMAGE, height = 14),
                            ),
                            render.WrappedText(str(err), color = text_color),
                        ],
                    ),
                ),
            ],
        ))),
    )

def main(config):
    """Main render function for the App
    Args:
        config: The schema config from TidByt
    Returns:
        A Root view to render to the app
    """
    access_token = config.get("access_token") or None
    text_color = config.get("text_color", "#ffffff")
    open_color = config.get("open_color", "#3fb950")
    closed_color = config.get("closed_color", "#8957e5")
    task_label = config.get("task_label", "Assigned Tasks")
    display_mode = config.get("display_mode", "open")
    if display_mode not in ("open", "both", "closed"):
        display_mode = "open"

    if task_label == "":
        task_label = "Assigned Tasks"

    repo_scope = config.get("repo_scope", "all")
    if repo_scope not in ("all", "mine", "org", "single"):
        repo_scope = "all"

    repo_filter = config.get("repo_filter", "")

    if access_token:
        user_login = ""
        if repo_scope == "mine":
            user_login = fetch_user_login(access_token)

        scope_err = repo_scope_error(repo_scope, repo_filter, user_login)
        if scope_err != "":
            return render_error(scope_err, text_color)

        open_query = build_issue_query("open", repo_scope, repo_filter, user_login)
        open_response = fetch_assigned_issues(access_token, open_query)

        if open_response == None or open_response.status_code != 200:
            return render_error("Error with Access Token.", text_color)

        open_count = get_count(open_response)
        closed_count = 0

        if display_mode in ("both", "closed"):
            closed_query = build_issue_query("closed", repo_scope, repo_filter, user_login)
            closed_response = fetch_assigned_issues(access_token, closed_query)
            if closed_response == None or closed_response.status_code != 200:
                return render_error("Error with Access Token.", text_color)

            closed_count = get_count(closed_response)

        min_tasks = int(config.get("min_tasks", "0"))
        show = min_tasks == 0 or open_count >= min_tasks
        if not show:
            return []

        return render_assigned_tasks(
            open_count,
            closed_count,
            display_mode,
            task_label,
            text_color,
            open_color,
            closed_color,
        )
    else:
        return render_error("No Access Token.", text_color)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "access_token",
                name = "Github Personal Access Token",
                desc = "Personal Access token (repo scope for private issues)",
                icon = "lock",
                secret = True,
            ),
            schema.Dropdown(
                id = "repo_scope",
                name = "Repository scope",
                desc = "Which repositories to include in assigned issue counts.",
                icon = "github",
                default = "all",
                options = [
                    schema.Option(display = "All repositories", value = "all"),
                    schema.Option(display = "Only repositories I own", value = "mine"),
                    schema.Option(display = "An organization", value = "org"),
                    schema.Option(display = "Single repository", value = "single"),
                ],
            ),
            schema.Generated(
                id = "repo_filter_generated",
                source = "repo_scope",
                handler = repo_filter_fields,
            ),
            schema.Text(
                id = "min_tasks",
                name = "Minimum open tasks",
                desc = "Only display when you have at least this many open assigned issues. Use 0 to always show.",
                icon = "eye",
                default = "0",
            ),
            schema.Dropdown(
                id = "display_mode",
                name = "Show tasks",
                desc = "Which assigned issue counts to display.",
                icon = "list",
                default = "open",
                options = [
                    schema.Option(display = "Open", value = "open"),
                    schema.Option(display = "Open + Closed", value = "both"),
                    schema.Option(display = "Closed", value = "closed"),
                ],
            ),
            schema.Text(
                id = "task_label",
                name = "Label",
                desc = "Text shown under the count (e.g. Assigned Tasks).",
                icon = "font",
                default = "Assigned Tasks",
            ),
            schema.Color(
                id = "open_color",
                name = "Open task color",
                desc = "Color for the open task count.",
                icon = "palette",
                default = "#3fb950",
            ),
            schema.Color(
                id = "closed_color",
                name = "Closed task color",
                desc = "Color for the closed task count.",
                icon = "palette",
                default = "#8957e5",
            ),
            schema.Color(
                id = "text_color",
                name = "Label color",
                desc = "Color for the label and the dash between open and closed counts.",
                icon = "palette",
                default = "#ffffff",
            ),
        ],
    )
