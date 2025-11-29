"""
Applet: CircleCI
Summary: CircleCI Build Statuses
Description: Status of latest execution of pipeline in CircleCI.
Author: barbosa
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("images/circleci_logo_green.png", CIRCLECI_LOGO_GREEN_ASSET = "file")
load("images/circleci_logo_red.png", CIRCLECI_LOGO_RED_ASSET = "file")
load("images/circleci_logo_white.png", CIRCLECI_LOGO_WHITE_ASSET = "file")
load("images/circleci_logo_yellow.png", CIRCLECI_LOGO_YELLOW_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CIRCLECI_LOGO_GREEN = CIRCLECI_LOGO_GREEN_ASSET.readall()
CIRCLECI_LOGO_RED = CIRCLECI_LOGO_RED_ASSET.readall()
CIRCLECI_LOGO_WHITE = CIRCLECI_LOGO_WHITE_ASSET.readall()
CIRCLECI_LOGO_YELLOW = CIRCLECI_LOGO_YELLOW_ASSET.readall()

CIRCLECI_PIPELINES_API_URL = "https://circleci.com/api/v2/project/{}/pipeline"
CIRCLECI_WORKFLOWS_API_URL = "https://circleci.com/api/v2/pipeline/{}/workflow"

def main(config):
    if config.get("api_token") == None:
        return render_fail("Please inform API token")

    if config.get("vcs") == None:
        return render_fail("Please inform vcs type")

    if config.get("org") == None:
        return render_fail("Please inform org name")

    if config.get("repo") == None:
        return render_fail("Please inform repo name")

    latest_pipeline = fetch_latest_pipeline(config)
    if latest_pipeline == None:
        return render_fail("Can't fetch pipeline")

    latest_workflow = fetch_latest_workflow(config, pipeline_id = latest_pipeline.get("id"))
    if latest_workflow == None:
        return render_fail("Can't fetch workflow")

    return render_widget(config, latest_pipeline, latest_workflow)

def fetch_latest_pipeline(config):
    api_token = config.str("api_token")
    project_slug = "{}/{}/{}".format(config.str("vcs"), config.str("org"), config.str("repo"))

    params = {
        "circle-token": api_token,
    }

    branch = config.str("branch")
    if branch:
        params["branch"] = branch

    response = http.get(CIRCLECI_PIPELINES_API_URL.format(project_slug), params = params)

    print("{} ({})".format(project_slug, branch or "all branches"))

    if response.status_code != 200:
        return None

    pipelines = response.json()
    items = pipelines.get("items")

    if len(items) == 0:
        return None

    return items[0]

def fetch_latest_workflow(config, pipeline_id):
    api_token = config.get("api_token")

    response = http.get(CIRCLECI_WORKFLOWS_API_URL.format(pipeline_id), params = {
        "circle-token": api_token,
    })

    if response.status_code != 200:
        return None

    workflows = response.json()
    latest_workflow = workflows.get("items")[0]
    print("Workflow Status:", latest_workflow.get("status"))

    return latest_workflow

def logo_for_status(status):
    mapping = {
        "success": CIRCLECI_LOGO_GREEN,
        "running": CIRCLECI_LOGO_YELLOW,
        "failed": CIRCLECI_LOGO_RED,
        "error": CIRCLECI_LOGO_RED,
        "failing": CIRCLECI_LOGO_RED,
    }

    print("Pipeline Status:", status)

    return mapping.get(status, CIRCLECI_LOGO_WHITE)

def render_widget(config, latest_pipeline, latest_workflow):
    repo_name = config.str("repo")
    status = latest_workflow.get("status")

    author = latest_pipeline["trigger"]["actor"]["login"]
    avatar_url = latest_pipeline["trigger"]["actor"]["avatar_url"]

    avatar = None
    if avatar_url != None:
        avatar = http.get(avatar_url).body()

    stopped_at = time.parse_time(latest_workflow["stopped_at"])
    when = humanize.time(stopped_at)

    return render.Root(
        child = render.Padding(
            pad = 2,
            child = render.Column(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Row(
                        children = [
                            render.Image(src = logo_for_status(status), width = 8, height = 8),
                            render.Box(width = 2, height = 8),
                            render.Text(repo_name),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Image(src = avatar, width = 16, height = 16) if avatar_url else render.Box(width = 16, height = 16, color = "666"),
                            render.Box(width = 2, height = 16),
                            render.Marquee(
                                width = 48,
                                child = render.Column(
                                    children = [
                                        render.Text(author),
                                        render.Text(when),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def render_fail(message):
    return render.Root(
        child = render.Padding(
            pad = 2,
            child = render.Column(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Row(
                        children = [
                            render.Image(src = CIRCLECI_LOGO_RED, width = 8, height = 8),
                            render.Box(width = 2, height = 8),
                            render.Text(content = "Error", color = "f77"),
                        ],
                    ),
                    render.Marquee(
                        width = 64,
                        child = render.WrappedText(content = message, width = 64, align = "left"),
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_token",
                name = "API Token",
                desc = "Your CircleCI Personal Token",
                icon = "key",
                secret = True,
            ),
            schema.Dropdown(
                id = "vcs",
                name = "VCS",
                desc = "Version Control System",
                icon = "github",
                default = "gh",
                options = [
                    schema.Option(
                        display = "GitHub",
                        value = "gh",
                    ),
                    schema.Option(
                        display = "Bitbucket",
                        value = "bb",
                    ),
                ],
            ),
            schema.Text(
                id = "org",
                name = "Org",
                desc = "Organization that contains repo",
                icon = "building",
            ),
            schema.Text(
                id = "repo",
                name = "Repo",
                desc = "Repository you want to watch",
                icon = "book",
            ),
            schema.Text(
                id = "branch",
                name = "Branch",
                desc = "Filter by branch",
                icon = "codeBranch",
            ),
        ],
    )
