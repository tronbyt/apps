"""
Applet: Todoist Next
Summary: Todoist next due/overdue
Description: Displays the next due or overdue task from todoist.
Author: alisdair(https://discuss.tidbyt.com/t/todoist-integration/502/5), Updated by: akeslo
"""

load("http.star", "http")
load("images/zen_icon.png", ZEN_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

ZEN_ICON = ZEN_ICON_ASSET.readall()

TODOIST_API_BASE_URL = "https://api.todoist.com/rest/v2"

TODOIST_API_TASKS_URL = TODOIST_API_BASE_URL + "/tasks?filter=(overdue|today)"

MODEL_KEY_TEXT = "text"
MODEL_KEY_DUE = "due"
MODEL_KEY_ZEN = False

CACHE_KEY_MODEL = "todoist_model"

# Load Icon as Base 64

def dateStringToTime(dateString):
    return time.parse_time(dateString, "2006-01-02")

def renderDate(dateString):
    return dateStringToTime(dateString).format("Jan-02")

def isOverdue(date):
    current = time.now()
    currentDay = time.time(year = current.year, month = current.month, day = current.day)
    return date < currentDay

def main(config):
    # Download tasks

    TOKEN = config.get("TodoistAPIToken", "False")
    resp = http.get(TODOIST_API_TASKS_URL, headers = {"Authorization": "Bearer " + TOKEN})

    if resp.status_code == 200:
        parsed = resp.json()

        # Compute model to display
        model = None
        for task in parsed:
            due = dateStringToTime(task["due"]["date"])
            thisModel = {MODEL_KEY_TEXT: task["content"]}
            if isOverdue(due):
                thisModel.update([(MODEL_KEY_DUE, task["due"]["date"])])
            if model == None:
                model = thisModel
                continue
            if model.get(MODEL_KEY_DUE) == None:
                if thisModel.get(MODEL_KEY_DUE) != None:
                    model = thisModel
                    continue
            elif due < dateStringToTime(model[MODEL_KEY_DUE]):
                model = thisModel
                continue
        if model == None:
            model = {
                MODEL_KEY_TEXT: "Todoist Zero!",
                MODEL_KEY_ZEN: True,
            }

        # Render model
        HEADER = "#f00"
        CLR = "#fa0"
        if model.get(MODEL_KEY_ZEN) == True:
            CLR = "#fff"

        children = [
            render.WrappedText(
                content = model[MODEL_KEY_TEXT],
                color = CLR,
            ),
        ]

        if model.get(MODEL_KEY_DUE) != None:
            children.append(
                render.Text(
                    content = "Late: " + renderDate(model.get(MODEL_KEY_DUE)),
                    color = "#f00",
                    font = "CG-pixel-4x5-mono",
                ),
            )

        if model.get(MODEL_KEY_ZEN) == True:
            children.append(
                render.Image(src = ZEN_ICON),
            )
        else:
            children.insert(
                0,
                render.WrappedText(
                    content = "Todoist",
                    color = HEADER,
                ),
            )
    else:
        children = [
            render.WrappedText(
                content = "Config Error",
            ),
        ]

    return render.Root(
        render.Row(
            children = [render.Column(
                children = children,
                expanded = True,
                main_align = "space_around",
                cross_align = "center",
            )],
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
        ),
        max_age = 600,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "TodoistAPIToken",
                name = "Todoist API Token",
                desc = "Enter Token",
                icon = "key",
                secret = True,
            ),
        ],
    )
