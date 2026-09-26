"""
Applet: Gitlab Pipeline
Summary: Shows Pipeline status
Description: Shows the status of the most recent pipeline in a selected Gitlab project.
Author: Sven Ringger
"""

load("http.star", "http")
load("images/canceled.png", CANCELED_ASSET = "file")
load("images/createdpendingskipped.png", CREATEDPENDINGSKIPPED_ASSET = "file")
load("images/failed.png", FAILED_ASSET = "file")
load("images/manual.png", MANUAL_ASSET = "file")
load("images/running.png", RUNNING_ASSET = "file")
load("images/success.png", SUCCESS_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

CANCELED = CANCELED_ASSET.readall()
CREATEDPENDINGSKIPPED = CREATEDPENDINGSKIPPED_ASSET.readall()
FAILED = FAILED_ASSET.readall()
MANUAL = MANUAL_ASSET.readall()
RUNNING = RUNNING_ASSET.readall()
SUCCESS = SUCCESS_ASSET.readall()

pipeline_dict = dict([("invalid", [FAILED, "API CALL FAILED!"]), ("FAILED", [FAILED, "BUILD FAILED!"]), ("SUCCESS", [SUCCESS, "Success"]), ("RUNNING", [RUNNING, "Running"]), ("created", [CREATEDPENDINGSKIPPED, "Created"]), ("pending", [CREATEDPENDINGSKIPPED, "Pending"]), ("skipped", [CREATEDPENDINGSKIPPED, "Skipped"]), ("CANCELED", [CANCELED, "Canc eled"]), ("MANUAL", [MANUAL, "Set to MANUAL"])])

def main(config):
    token = config.get("api-token") or "example"
    projectId = config.get("project-id") or "example"
    print(token, projectId)
    branch = config.get("branch")
    status = get_pipeline_status(token, projectId, branch)
    ICON = render.Image(src = pipeline_dict.get(status)[0])
    padding = render.Box(width = 1, height = 12, color = "#000000")
    box = render.Column(
        children = [
            padding,
            render.WrappedText(content = pipeline_dict.get(status)[1], font = "tom-thumb"),
        ],
    )
    return render.Root(
        child = render.Row(
            children =
                [ICON, padding, box],
        ),
    )

def get_pipeline_status(accesstoken, id, ref):
    #simply as an example for preview in store, i know its really not elegant, might change it in the future
    if accesstoken == "example":
        if id == "example":
            return "SUCCESS"

    # Set the GitLab API endpoint and access token
    api_endpoint = "https://gitlab.com/api/v4"

    # Specify the project and branch for which to check the pipeline status
    pipeline_url = "%s/projects/%s/pipelines?ref=%s&access_token=%s" % (api_endpoint, id, ref, accesstoken)

    #Gitlab request limit is 150 calls per user per minute, so caching is not needed
    pipeline_data = http.get(pipeline_url)
    if pipeline_data.status_code != 200:
        return "invalid"
    pipeline_data = pipeline_data.json()
    most_recent_pipeline = pipeline_data[0]
    return most_recent_pipeline["status"]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api-token",
                name = "Your Gitlab access token",
                desc = "Your Gitlab access token",
                icon = "gitlab",
                default = "",
                secret = True,
            ),
            schema.Text(
                id = "project-id",
                name = "Project-Id",
                desc = "The id of the project you want to track.",
                icon = "hashtag",
                default = "",
            ),
            schema.Text(
                id = "branch",
                name = "Branch",
                desc = "The branch you want to track.",
                icon = "codeBranch",
                default = "main",
            ),
        ],
    )
