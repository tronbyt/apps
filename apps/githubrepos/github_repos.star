"""
Applet: GitHub Badge
Summary: GitHub badge status
Description: Displays a GitHub badge for the status of the configured action.
Author: Cavallando
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/github_failed.png", GITHUB_FAILED_ICON = "file")
load("images/github_fault.png", GITHUB_FAULT_ICON = "file")
load("images/github_loading.png", GITHUB_LOADING_ICON = "file")
load("images/github_logo.png", GITHUB_LOGO_ASSET = "file")
load("images/github_neutral.png", GITHUB_NEUTRAL_ICON = "file")
load("images/github_success.png", GITHUB_SUCCESS_ICON = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEBUG = False
TEST_RUN = """{
    "total_count": 28,
    "workflow_runs": [
        {
            "conclusion": "success",
            "updated_at": "2025-03-14T04:25:26Z",
            "head_branch": "main",
            "status": "completed"
        }
    ]
}"""

GITHUB_LOGO = GITHUB_LOGO_ASSET.readall()
GITHUB_FAILED_ICON = GITHUB_FAILED_ICON.readall()
GITHUB_SUCCESS_ICON = GITHUB_SUCCESS_ICON.readall()
GITHUB_NEUTRAL_ICON = GITHUB_NEUTRAL_ICON.readall()
GITHUB_FAULT_ICON = GITHUB_FAULT_ICON.readall()
GITHUB_LOADING_ICON = GITHUB_LOADING_ICON.readall()

def should_show_jobs(repos, dwell_time):
    now = time.now()
    for repo in repos:
        if "data" not in repo:
            continue
        job = repo["data"]
        repo_name = str(repo.get("name", "unknown"))
        conclusion = str(job.get("conclusion", "unknown"))
        status = str(job.get("status", "unknown"))
        print("repo " + repo_name + " has conclusion: " + conclusion + ", status: " + status)

        # Show all repos if any repo is not success (including cancelled)
        if conclusion not in ["success", "cancelled"]:
            print("repo " + repo_name + " is not success, showing all jobs")
            return True

        # Show all repos if any success is recent
        updated_at = time.parse_time(job["updated_at"], format = "2006-01-02T15:04:05Z").in_location("UTC")
        duration = now - updated_at
        print("comparing " + str(duration.seconds) + " and " + str(dwell_time * 60) + " for repo " + repo_name)
        if duration.seconds <= dwell_time * 60:
            print("repo " + repo_name + " success is recent, showing all jobs")
            return True
        else:
            print("repo " + repo_name + " success is old")

    print("all repos have old successes, hiding all jobs")
    return False

def get_status_icon(status, conclusion):
    """Gets the decoded icon string for a given Workflow Status from github

    Args:
        status: The status of the workflow, can be anyone of the statuses found here
            https://docs.github.com/en/rest/actions/workflow-runs?apiVersion=2022-11-28#list-workflow-runs-for-a-workflow

    Returns:
    The appropriate icon string
    """
    if status == "failed" or status == "timed_out" or conclusion == "failure":
        return GITHUB_FAILED_ICON
    elif status == "completed" or status == "success":
        return GITHUB_SUCCESS_ICON
    elif (
        status == "cancelled" or
        status == "skipped" or
        status == "stale" or
        status == "neutral"
    ):
        return GITHUB_NEUTRAL_ICON
    elif status == "action_required":
        return GITHUB_FAULT_ICON
    else:
        return GITHUB_LOADING_ICON

def fetch_workflow_data(repos, access_token):
    """Fetches the workflow data from GitHub

    Args:
        config: The schema config from TidByt

    Returns:
        The workflow data if it can be found or an error message from the request
    """
    headers = {
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    if access_token:
        headers["Authorization"] = "Bearer {}".format(access_token)

    modified_repos = []
    print("repos are " + str(repos))
    for repo in repos:
        owner_name, repo_name, branch_name, workflow_id = repo["str"].split("/")
        if not DEBUG:
            resp = http.get(
                "https://api.github.com/repos/{}/{}/actions/workflows/{}/runs".format(
                    owner_name,
                    repo_name,
                    workflow_id,
                ),
                params = {"branch": branch_name, "per_page": "1", "page": "1"},
                headers = headers,
                ttl_seconds = 60,
            )
            data = resp.json()
            if (resp.status_code != 200):
                print("status_code : " + str(resp.status_code))
                print(data)
                return ("error", data.get("message"))
        else:
            data = json.decode(TEST_RUN)

        if data and data.get("workflow_runs"):
            repo_copy = {
                "owner": repo["owner"],
                "name": repo["name"],
                "branch": repo["branch"],
                "workflow": repo["workflow"],
                "str": repo["str"],
                "data": data.get("workflow_runs")[0],
            }
            modified_repos.append(repo_copy)
    return modified_repos, None

# def get_display_text(repo):
#     return config.get("display_text") or "{}/{}".format(repo[0], repo[1])

def render_status_badge(status, repos):
    # workflow_data is an array
    rows = []
    print(type(repos))
    if type(repos) == "list":
        for repo in repos:
            status = repo["data"]["status"]
            conclusion = repo["data"]["conclusion"]
            print("appending row " + status)
            rows.append(
                render.Row(
                    cross_align = "center",
                    children = [
                        render.Marquee(
                            width = 37,
                            child = render.Text(
                                content = repo["name"],
                                font = "tom-thumb",
                            ),
                        ),
                        render.Image(src = get_status_icon(status, conclusion)),
                    ],
                ),
            )
    else:
        print("error, got no data from github")
        rows.append(
            render.Row(
                cross_align = "center",
                children = [
                    render.Marquee(
                        width = 37,
                        child = render.Text(
                            content = repos,
                            font = "tom-thumb",
                        ),
                    ),
                    render.Image(src = get_status_icon(status)),
                ],
            ),
        )
    return render.Root(
        child = render.Stack(
            children = [
                # render.Padding(pad = (0, 1, 0, 0), child = render.Image(src = BADGE_BACKGROUND, width = 64, height = 30)),
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
                        render.Column(
                            expanded = True,
                            children = rows,
                        ),
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
    repo1 = config.str("repo1", "owner/repo/branch/workflow")
    repo2 = config.str("repo2", "owner/repo/branch/workflow")
    repo3 = config.str("repo3", "owner/repo/branch/workflow")
    repos_strs = [repo1, repo2, repo3]
    repos = []
    for repo in repos_strs:
        if (
            repo == "owner/repo/branch/workflow" or
            repo == ""
            # or len(repo.split("/")) < 4
        ):
            continue
        else:
            owner, name, branch, workflow = repo.split("/")
            repos.append(
                {
                    "owner": owner,
                    "name": name,
                    "branch": branch,
                    "workflow": workflow,
                    "str": repo,
                },
            )
    workflow_data = []
    workflow_data, err = fetch_workflow_data(repos, config.get("access_token", None))

    if err:
        return render_status_badge("failed", err)
        # elif len(workflow_data) == 0 and access_token == None:
        #     return render_status_badge("success", "no data")

    elif workflow_data and type(workflow_data) != "string":
        should_show = should_show_jobs(workflow_data, int(config.get("timeout", "0")))
        print("should_show_jobs returned: " + str(should_show))
        if not should_show:
            print("hiding all jobs, returning empty")
            return []

        print("showing all jobs")
        return render_status_badge("success", workflow_data)
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
                id = "repo1",
                name = "Repo 1",
                desc = "Repo 1",
                icon = "boxArchive",
                default = "owner/repo/branch/workflow",
            ),
            schema.Text(
                id = "repo2",
                name = "Repo 2",
                desc = "Repo 2",
                icon = "boxArchive",
                default = "owner/repo/branch/workflow",
            ),
            schema.Text(
                id = "repo3",
                name = "Repo 3",
                desc = "Repo 3",
                icon = "boxArchive",
                default = "owner/repo/branch/workflow",
            ),
            schema.Text(
                id = "timeout",
                name = "All Success Timeout",
                desc = "How long to show all green",
                icon = "clock",
                default = "0",
            ),
        ],
    )
