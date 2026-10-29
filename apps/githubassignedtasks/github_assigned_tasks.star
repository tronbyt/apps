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

def fetch_assigned_issues(access_token):
    return http.get(
        "https://api.github.com/search/issues?q=assignee:@me+is:open+is:issue",
        headers = {"Accept": "application/vnd.github+json", "Authorization": "Bearer {}".format(access_token), "X-GitHub-Api-Version": "2022-11-28"},
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

def render_assigned_tasks(count, label, text_color):
    count = int(count)

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
                                child = render.Text(
                                    content = str(count),
                                    font = count_font(),
                                    color = text_color,
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
    task_label = config.get("task_label", "Assigned Tasks")
    if task_label == "":
        task_label = "Assigned Tasks"

    if access_token:
        response = fetch_assigned_issues(access_token)

        if response.status_code != 200:
            return render_error("Error with Access Token.", text_color)

        count = get_count(response)

        min_tasks = int(config.get("min_tasks", "0"))
        if min_tasks > 0 and count <= min_tasks:
            return []

        return render_assigned_tasks(count, task_label, text_color)
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
                name = "Minimum tasks to show",
                desc = "Only display when you have more than this many open assigned issues. Use 0 to always show.",
                icon = "eye",
                default = "0",
            ),
            schema.Text(
                id = "task_label",
                name = "Label",
                desc = "Text shown under the count (e.g. Assigned Tasks).",
                icon = "font",
                default = "Assigned Tasks",
            ),
            schema.Color(
                id = "text_color",
                name = "Text color",
                desc = "Color for the count and label.",
                icon = "palette",
                default = "#ffffff",
            ),
        ],
    )
