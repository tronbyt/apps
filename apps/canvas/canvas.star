load("http.star", "http")
load("images/canvas_logo.png", CANVAS_LOGO_ASSET = "file")
load("random.star", "random")

#Add in the needed code bases
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

#Code for the canvas logo
CanvasLogo = CANVAS_LOGO_ASSET.readall()

def showEvent(event):
    return render.Column(
        children = [
            render.Text(content = event[1]),
            render.Text(content = event[0]),
        ],
    )

#Show an error
def makeError(type):
    return render.Root(
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            expanded = True,
            children = [
                render.Marquee(
                    width = 60,
                    scroll_direction = "horizontal",
                    offset_start = 10,
                    offset_end = 10,
                    child = render.Text(type),
                ),
            ],
        ),
    )

def getcourse(api_token):
    api_url = "https://canvas.instructure.com/api/v1/courses?per_page=30&access_token=" + api_token
    response = http.get(api_url, ttl_seconds = 3000)
    if response.status_code != 200:
        return [], "Can not Connect to Canvas"
    classes = []

    data = str(response.body()).split('"id"')
    if "Invalid access token." in data:
        return [], "Invalid access token."
    for course in data:
        if "created_at" in course:
            if len(course) >= 18:
                index = course.find("created_at")
                time_stamp = course[index + 13:index + 33]
                dur = time.now() - time.parse_time(time_stamp)
                if 8760 > dur.hours:
                    classes.append(course[1:course.index(",")])

    return classes, 0

def get_remote_assignments(api_token, course_id):
    api_url = "https://canvas.instructure.com/api/v1/courses/" + str(
        course_id,
    ) + "/assignments?bucket=upcoming&access_token=" + api_token
    print(api_url)
    rep = http.get(api_url, ttl_seconds = 300)
    if rep.status_code != 200:
        return [], "Can not Connect to Canvas"
    data = rep.json()
    return [
        (assignment["due_at"], assignment["name"] + "")
        for assignment in data
        if assignment["due_at"] != None and
           (time.parse_time(assignment["due_at"]) - time.now()).hours > 0 and
           (time.parse_time(assignment["due_at"]) - time.now()).hours < 200
    ]

def get_events(api_token, course_id):
    assignment_data = get_remote_assignments(api_token, course_id)
    return assignment_data, 0

def fake_events():
    first = ["2024-04-21T03:59:59Z", "Example Assigment #1"]
    second = ["2024-11-23T03:59:59Z", "Fake Homework #4"]
    return render.Root(
        child = render.Column(
            children = [
                showEvent(first),
                render.Box(width = 100, height = 1, color = "#ffffff"),
                showEvent(second),
            ],
        ),
    )

def main(config):
    api_token = config.get("msg", "")

    if api_token == "":
        return fake_events()

    classes, error_code = getcourse(api_token)

    if error_code != 0:
        return makeError(error_code)

    canvas_data = []
    for course in classes:
        event, error_code = get_events(api_token, course)
        if error_code != 0:
            return makeError(error_code)
        canvas_data = canvas_data + event

    if len(canvas_data) == 1:
        return render.Root(
            child = render.Column(
                children = [
                    showEvent(canvas_data[0]),
                    render.Box(width = 100, height = 1, color = "#ffffff"),
                ],
            ),
        )
    elif len(canvas_data) >= 2:
        index = random.number(0, len(canvas_data) - 2)
        return render.Root(
            child = render.Column(
                children = [
                    showEvent(canvas_data[index]),
                    render.Box(width = 100, height = 1, color = "#ffffff"),
                    showEvent(canvas_data[index + 1]),
                ],
            ),
        )
    elif len(canvas_data) == 0:
        if config.bool("no_assigment", False):
            return None
        else:
            return makeError("No More Assignments")
    else:
        return makeError("There was an unknown problem")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "msg",
                name = "Canvas API key",
                desc = "",
                icon = "compress",
                default = "",
                secret = True,
            ),
            schema.Toggle(
                id = "no_assigment",
                name = "Show Nothing",
                desc = "Show nothing when there are no assignments",
                icon = "gear",
                default = False,
            ),
        ],
    )
