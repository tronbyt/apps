"""
Applet: GitHub Badge
Summary: GitHub badge status
Description: Displays a GitHub badge for the status of the configured action.
Author: Cavallando
"""

load("http.star", "http")
load("images/badge_background.png", BADGE_BACKGROUND_ASSET = "file")
load("images/github_failed_icon.png", GITHUB_FAILED_ICON_ASSET = "file")
load("images/github_fault_icon.png", GITHUB_FAULT_ICON_ASSET = "file")
load("images/github_loading_icon.png", GITHUB_LOADING_ICON_ASSET = "file")
load("images/github_logo.png", GITHUB_LOGO_ASSET = "file")
load("images/github_neutral_icon.png", GITHUB_NEUTRAL_ICON_ASSET = "file")
load("images/github_success_icon.png", GITHUB_SUCCESS_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

BADGE_BACKGROUND = BADGE_BACKGROUND_ASSET.readall()
GITHUB_FAILED_ICON = GITHUB_FAILED_ICON_ASSET.readall()
GITHUB_FAULT_ICON = GITHUB_FAULT_ICON_ASSET.readall()
GITHUB_LOADING_ICON = GITHUB_LOADING_ICON_ASSET.readall()
GITHUB_LOGO = GITHUB_LOGO_ASSET.readall()
GITHUB_NEUTRAL_ICON = GITHUB_NEUTRAL_ICON_ASSET.readall()
GITHUB_SUCCESS_ICON = GITHUB_SUCCESS_ICON_ASSET.readall()

DEFAULT_BRANCH = "main"

def get_status_icon(status):
    """Gets the decoded icon string for a given Workflow Status from github 

    Args:
        status: The status of the workflow, can be anyone of the statuses found here
            https://docs.github.com/en/rest/actions/workflow-runs?apiVersion=2022-11-28#list-workflow-runs-for-a-workflow

    Returns:
    The appropriate icon string
    """
    if status == "completed" or status == "success":
        return GITHUB_SUCCESS_ICON
    elif status == "failed" or status == "timed_out":
        return GITHUB_FAILED_ICON
    elif status == "cancelled" or status == "skipped" or status == "stale" or status == "neutral":
        return GITHUB_NEUTRAL_ICON
    elif status == "action_required":
        return GITHUB_FAULT_ICON
    else:
        return GITHUB_LOADING_ICON

def fetch_workflow_data(config):
    """Fetches the workflow data from GitHub

    Args:
        config: The schema config from TidByt

    Returns:
        The workflow data if it can be found or an error message from the request
    """
    access_token = config.str("access_token")
    repo_name = config.str("repo_name")
    owner_name = config.str("owner_name")
    workflow_id = config.str("workflow_id")
    branch = config.str("branch", DEFAULT_BRANCH)

    headers = {"Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28"}
    if access_token:
        headers["Authorization"] = "Bearer {}".format(access_token)

    data = http.get(
        "https://api.github.com/repos/{}/{}/actions/workflows/{}/runs".format(owner_name, repo_name, workflow_id),
        params = {"branch": branch, "per_page": "1", "page": "1"},
        headers = headers,
        ttl_seconds = 240,
    ).json()

    if data and data.get("workflow_runs"):
        return data.get("workflow_runs")[0], None
    elif data.get("message"):
        return [], data.get("message")

    return [], "Error occurred"

def get_display_text(config):
    return config.get("display_text") or "{}/{}".format(config.str("owner_name"), config.str("repo_name"))

def render_status_badge(status, display_text):
    return render.Root(
        child = render.Stack(
            children = [
                render.Padding(pad = (0, 1, 0, 0), child = render.Image(src = BADGE_BACKGROUND, width = 64, height = 30)),
                render.Row(
                    expanded = True,
                    cross_align = "center",
                    children = [
                        render.Padding(
                            pad = (1, 9, 2, 10),
                            child = render.Image(
                                width = 13,
                                height = 13,
                                src = GITHUB_LOGO,
                            ),
                        ),
                        render.Marquee(
                            width = 37,
                            child = render.Text(content = display_text, font = "tom-thumb"),
                        ),
                        render.Image(src = get_status_icon(status)),
                    ],
                ),
            ],
        ),
    )

def main(config):
    """Main render function for the App

    Args:
        config: The schema config from TidByt

    Returns:
        A Root view to render to the app
    """
    access_token = config.get("access_token") or None
    display_text = get_display_text(config)

    workflow_data = []
    err = None
    workflow_data, err = fetch_workflow_data(config)

    if err:
        return render_status_badge("failed", err)
    elif len(workflow_data) == 0 and access_token == None:
        return render_status_badge("success", "tidbyt/pixlet")
    elif workflow_data and type(workflow_data) != "string":
        status = workflow_data.get("status")

        return render_status_badge(status, display_text)
    elif workflow_data:
        return render_status_badge("failed", workflow_data)
    else:
        return render_status_badge("failed", "Could not connect to GitHub")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "access_token",
                name = "GitHub Personal Access Token",
                desc = "Personal Access token (optional, only required for private repos)",
                icon = "lock",
                secret = True,
            ),
            schema.Text(
                id = "repo_name",
                name = "Repo Name",
                desc = "Name of the repository",
                icon = "boxArchive",
                default = "pixlet",
            ),
            schema.Text(
                id = "owner_name",
                name = "User/Org Name",
                desc = "Name of the user/organization that the repo belongs to",
                icon = "user",
                default = "tidbyt",
            ),
            schema.Text(
                id = "workflow_id",
                name = "Workflow",
                desc = "The ID or File name of the workflow file (e.g., deploy.yml)",
                icon = "lock",
                default = "main.yml",
            ),
            schema.Text(
                id = "display_text",
                name = "Display text",
                desc = "Text to display for the workflow, defaults to user/repo",
                icon = "font",
            ),
            schema.Text(
                id = "branch",
                name = "Branch name",
                desc = "Name of the branch to listen for workflow runs, defaults to main",
                icon = "codeBranch",
                default = "main",
            ),
        ],
    )
