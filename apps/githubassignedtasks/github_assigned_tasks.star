"""
Applet: GitHub Assigned Tasks
Summary: GitHub assigned issue count
Description: Displays the count of open GitHub issues assigned to you.
Author: Tavis
"""

load("http.star", "http")
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

def fetch_assigned_issues(access_token, state):
    return http.get(
        "https://api.github.com/search/issues?q=assignee:@me+is:{}+is:issue".format(state),
        headers = github_headers(access_token),
        ttl_seconds = 60,
    )

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

    if access_token:
        open_response = fetch_assigned_issues(access_token, "open")

        if open_response.status_code != 200:
            return render_error("Error with Access Token.", text_color)

        open_count = get_count(open_response)
        closed_count = 0

        if display_mode in ("both", "closed"):
            closed_response = fetch_assigned_issues(access_token, "closed")
            if closed_response.status_code != 200:
                return render_error("Error with Access Token.", text_color)

            closed_count = get_count(closed_response)

        min_tasks = int(config.get("min_tasks", "0"))
        if min_tasks > 0 and open_count <= min_tasks:
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
            schema.Text(
                id = "min_tasks",
                name = "Minimum open tasks",
                desc = "Only display when you have more than this many open assigned issues. Use 0 to always show.",
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
