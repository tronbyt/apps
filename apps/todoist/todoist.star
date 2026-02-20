"""
Applet: Todoist
Summary: Integration with Todoist
Description: Shows the number of tasks you have due today.
Author: zephyern/oleksii-ivanov
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("images/todoist_icon.png", TODOIST_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

TODOIST_ICON = TODOIST_ICON_ASSET.readall()

DEFAULT_NAME = "Todoist"
DEFAULT_FILTER = "today | overdue"
DEFAULT_SHOW_IF_EMPTY = True

NO_TASKS_CONTENT = "No Tasks :)"

TODOIST_URL = "https://api.todoist.com/api/v1/tasks/filter"

def main(config):
    token = config.get("api_key")
    if token:
        filter_name = "%s" % (config.get("name") or DEFAULT_NAME)
        filter = config.get("filter") or DEFAULT_FILTER

        print("Querying for tasks.")
        rep = http.get(TODOIST_URL, headers = {"Authorization": "Bearer %s" % token}, params = {"query": filter}, ttl_seconds = 60)

        if rep.status_code == 200:
            data = rep.json()
            tasks = data.get("results", [])
            num_tasks = len(tasks)
        elif rep.status_code == 204:
            num_tasks = 0
        else:
            num_tasks = -1

        if num_tasks == -1:
            content = "Error"
        elif num_tasks == 0:
            content = NO_TASKS_CONTENT
        else:
            content = humanize.plural(int(num_tasks), "Task")

        if (content == NO_TASKS_CONTENT and not config.bool("show")):
            # Don't display the app in the user's rotation
            return []

    else:
        # This is used to display the app preview image
        # when the user isn't logged in.
        filter_name = "Todoist"
        content = "4 Tasks"

    return render.Root(
        delay = 500,
        max_age = 86400,
        child =
            render.Box(
                render.Row(
                    expanded = True,
                    main_align = "space_evenly",
                    children = [
                        render.Image(src = TODOIST_ICON),
                        render.Column(
                            children = [
                                render.Marquee(child = render.Text(content = filter_name), width = 40),
                                render.Text(content = content),
                            ],
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
                id = "api_key",
                name = "API Key",
                desc = "Your Todoist API token. Find it in Todoist Settings > Integrations > Developer.",
                icon = "key",
            ),
            schema.Text(
                id = "name",
                name = "Name",
                desc = "Name to display",
                icon = "iCursor",
                default = DEFAULT_NAME,
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
