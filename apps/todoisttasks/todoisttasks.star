"""
Applet: Todoist Tasks
Summary: Integrates with Todoist
Description: Shows up to 3 tasks on your To-Do list, sorted by priority. Use the filter option to further sort your tasks by using parameters such as 'today', tomorrow', 'overdue' etc.
Author: Based on zephyern's code, rewritten by ChatGTP4 with directions from Noste. I have no idea how code works.
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

DEFAULT_FILTER = "today | overdue"
DEFAULT_SHOW_IF_EMPTY = True

NO_TASKS_CONTENT = "No Tasks :)"

TODOIST_URL = "https://api.todoist.com/rest/v2/tasks"

OAUTH2_CLIENT_ID = secret.decrypt("AV6+xWcEQOfChp6DT4pbNdlJxTUzWzCkB+5yEIf8EP4/0PWuFsV+U1vNeV5LanJ12L/rnluXAeLQy9wki7zsxaOeeqGO1vLI47J1UR0um63dgzXTVj+Tdj9+m02XCPGWuhHE/oengWdSvjAVtfFW2qcUwMYFORNauBD1m7qH/fu4kzNWsnY=")
OAUTH2_CLIENT_SECRET = secret.decrypt("AV6+xWcER6NHS+ZGzXEJ5a7JaRuCiTKmcifK5zlxUgjz3/HW0FkTq9LJSB+fsLPNjuOdnHQSfX3h5YPTcK7K7Onu1B2O3DV5F8T4edaIWTVg1FkMnfD7a4vrCXp74pxvwlvktrKQwjq9nsPGRw4MlKx/rBRKhfjadwx1xl0VKHMdH/dc2yQ=")

def main(config):
    token = config.get("auth") or config.get("dev_api_key")

    if not token:
        return render.Root(
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Circle(
                        diameter = 6,
                        color = "#9b9b9b",
                        child = render.Circle(color = "#3cba54", diameter = 2),
                    ),
                    render.Box(
                        width = 46,
                        child = render.Marquee(
                            child = render.Text(content = "Please connect your Todoist account."),
                            width = 46,
                        ),
                    ),
                ],
            ),
        )

    filter = config.get("filter") or DEFAULT_FILTER
    rep = http.get(TODOIST_URL, headers = {"Authorization": "Bearer %s" % token}, params = {"filter": filter}, ttl_seconds = 60)

    sorted_tasks = None
    if rep.status_code == 200:
        tasks = rep.json()
        sorted_tasks = sorted(tasks, key = lambda task: task["priority"], reverse = True)
    elif rep.status_code == 204:
        sorted_tasks = []

    if sorted_tasks == None:
        return render.Root(child = render.WrappedText("Error fetching tasks"))

    if not sorted_tasks:
        if not config.bool("show", DEFAULT_SHOW_IF_EMPTY):
            return []

        return render.Root(
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Circle(
                        diameter = 6,
                        color = "#3cba54",  # Green color
                        child = render.Circle(color = "#332726", diameter = 2),
                    ),
                    render.Box(
                        width = 46,
                        child = render.Text(content = NO_TASKS_CONTENT),
                    ),
                ],
            ),
        )

    # We have tasks
    task_descriptions = [task["content"] for task in sorted_tasks[:3]]
    task_priority = [task["priority"] for task in sorted_tasks[:3]]

    content = []
    for desc in task_descriptions:
        if type(desc) == "list":  # Starlark type check
            desc = " ".join(desc)
        content.append(desc)

    colors = ["#9b9b9b", "#48a9e6", "#f8b43a", "#ed786c"]

    children = []
    for i, task_desc in enumerate(content):
        children.append(render.Marquee(
            child = render.Text(content = task_desc),
            offset_start = 2,
            width = 46,
        ))

    # Update circle colors based on the priority of the tasks
    circle_colors = [colors[int(priority) - 1] for priority in task_priority]

    # Generate circle children based on the number of tasks
    circle_children = []
    for i in range(len(content)):
        circle_children.append(render.Circle(
            diameter = 6,
            color = circle_colors[i],
            child = render.Circle(color = "#332726", diameter = 2),
        ))

    return render.Root(
        delay = 100,
        max_age = 86400,
        child = render.Box(
            width = 64,
            height = 32,
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Column(
                        expanded = True,
                        cross_align = "center",
                        main_align = "space_evenly",
                        children = circle_children,
                    ),
                    render.Column(
                        expanded = True,
                        cross_align = "center",
                        main_align = "space_evenly",
                        children = children,
                    ),
                ],
            ),
        ),
    )

def oauth_handler(params):
    params = json.decode(params)
    res = http.post(
        url = "https://todoist.com/oauth/access_token",
        headers = {
            "Accept": "application/json",
        },
        form_body = dict(
            code = params["code"],
            client_id = OAUTH2_CLIENT_ID,
            client_secret = OAUTH2_CLIENT_SECRET,
        ),
        form_encoding = "application/x-www-form-urlencoded",
    )
    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    access_token = token_params["access_token"]

    return access_token

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Todoist",
                desc = "Connect your Todoist account.",
                icon = "squareCheck",
                handler = oauth_handler,
                client_id = OAUTH2_CLIENT_ID or "fake-client-id",
                authorization_endpoint = "https://todoist.com/oauth/authorize",
                scopes = [
                    "data:read",
                ],
            ),
            schema.Text(
                id = "filter",
                name = "Filter",
                desc = "Filter to apply to tasks.",
                icon = "filter",
                default = DEFAULT_FILTER,
            ),
            schema.Toggle(
                id = "show",
                name = "Show When No Tasks",
                desc = "Show this app when there are no tasks.",
                icon = "eye",
                default = DEFAULT_SHOW_IF_EMPTY,
            ),
        ],
    )
