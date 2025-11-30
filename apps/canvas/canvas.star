load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("random.star", "random")

#Add in the needed code bases
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/img_55a84839.png", IMG_55a84839_ASSET = "file")

#Code for the canvas logo
CanvasLogo = IMG_55a84839_ASSET.readall(),
                ],
            ),
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
    class_cache = cache.get("class_data-" + api_token)

    if class_cache != None:
        print("Using Cached Courses")
        classes = class_cache.split(",")
        return classes, 0
    else:
        api_url = "https://canvas.instructure.com/api/v1/courses?per_page=30&access_token=" + api_token
        response = http.get(api_url)
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

        #cache for one day
        cache_data = ",".join(classes)

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("class_data-" + api_token, cache_data, ttl_seconds = 3000)
        return classes, 0

def get_cached_assignments(course_id, api_token):
    cache_string = cache.get(str(course_id) + "-" + api_token)
    if cache_string != None:
        first_split = cache_string.split(";")
        if "" in first_split:
            first_split.remove("")
        return [a.split(",") for a in first_split]
    return None

def get_remote_assignments(api_token, course_id):
    api_url = "https://canvas.instructure.com/api/v1/courses/" + str(
        course_id,
    ) + "/assignments?bucket=upcoming&access_token=" + api_token
    print(api_url)
    rep = http.get(api_url)
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

def cache_assignments(course_id, assignments, api_token):
    cache_string = ";".join([a[0] + "," + a[1] for a in assignments])

    # TODO: Determine if this cache call can be converted to the new HTTP cache.
    cache.set(str(course_id) + "-" + api_token, cache_string, ttl_seconds = 300)

def get_events(api_token, course_id):
    assignment_data = get_cached_assignments(course_id, api_token)
    if assignment_data == None:
        print("Not Using Cached Classes for" + str(course_id))
        assignment_data = get_remote_assignments(api_token, course_id)
        cache_assignments(course_id, assignment_data, api_token)
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
