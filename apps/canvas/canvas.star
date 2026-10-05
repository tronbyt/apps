load("encoding/base64.star", "base64")
load("http.star", "http")

#Add in the needed code bases
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_CANVAS_BASE_URL = "https://canvas.instructure.com"
COURSES_CACHE_TTL_SECONDS = 3000
ASSIGNMENTS_CACHE_TTL_SECONDS = 300
PLANNER_OVERRIDES_CACHE_TTL_SECONDS = 300
DEFAULT_DUE_DATE_CUTOFF_DAYS = "8"
MAX_DUE_DATE_CUTOFF_DAYS = 365
MAX_PLANNER_OVERRIDE_PAGES = 10
PLANNER_OVERRIDES_PER_PAGE = 100
PAGE_MIN_FRAME_COUNT = 60
FRAME_DELAY_MS = 50

# Embedded so older Tronbyt Server releases do not need to resolve image files.
CANVAS_LOGO_BASE64 = "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"
CANVAS_DISCUSSION_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAYAAABw4pVUAAADS0lEQVR4nO3dO4sUQRSG4cVcQVEQRBPvC5uYCCom3i8ggiBqYmKoYG5saOA/MBA11kAwdiMzf8HidRMTQU2krNIdGJs+3XV6Ts35avo78CYu21PVzwbOdC27FEJYAmpPbHnMeQM0exVGPt4ABGmMNwBBGuMNQJDGeAMQpDHeALkgb2OvF6yfNYOsAKzNujWCYEUQsAgCFkHAIghYBAGLIGARBCyCgEUQsKoAuR570NIOgLWNEmRMEQQsgoBFELAIApYI8mTk3UcDGfu8DASBGoKADUHAhiBgUwXIeuzkgnVb2GsVIGtOiyzZirBXgjhFELAIAhZBwCIIWAQBiyBgEQQsgoBFELBGBXIj9tuhLYo1jgrkpnCd0kMQIYIQ5O8QRIggYCBXYx8d2qxYowTyJrZrqp3KvU/a1rhOX5/aFmMFUkMSSNvcG3D9Z4rri0MQebQoBFGmBUmjQSGIsiEgaXJRCKJsKEiaHBQokO2xYwZtVb6uBci32GoQ/hs6NX0oEsj7jetnZQVi9T7ksvJ1LUAm70PSD8O7nvV1oUggJzTrJMj/bwxnQSGIstx36kNRCKJM89FJDsrdxvcQRJn2sywtChTI8dhzg44oX7ckiBYFCqSGhn7am4tCEGWzfPyeg7Iu/DtBhGZ9HpKD0jYEEbJ4QDUEhSBCVk8MtSgEEbJ8hKtBIYiQ9TP1XBSCCJU45JCDQhChUqdO+lAIIlTyGFAXCkGESp/LklBMQL7HHhs05MPCZaPXbvZU2KvlQbk2FBMQq3moWUzscOxr4TU1x/rkYhOlWpBDYf4YaUocJZ1GqRIkYXwpvBZpSp3tnaBUB+KJkabkYeuEslvzPd4gB2OfC6+hb7xOv4sgVwx6JGy2C+RA6Mb4EbtjtL6ujnrd/LasLnRLuKkSSA7GKe+b45EHyP4g/G7ExowWIziA5GCc9r4pns0TZF/491tP0oweI8wRpA8j/V3Y0WOEOYHsjX0Qvp4mYZzxvhEolQZ5EYgBBdI1CeOs9w1AywuEGEAgxAACSRjnvDeN3DxBiAEE8it23nuzNTQPEGIAgRADCCRhXPDeYG2VAiEGEEjCuOi9sVqzBiEGEAgxgECuxS55b2YRsrrQJu+NLEp/AFEuUsjSalaSAAAAAElFTkSuQmCC"
CANVAS_QUIZ_BASE64 = "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"

#Canvas item icons
CANVAS_ASSIGNMENT_ICON = base64.decode(CANVAS_LOGO_BASE64)
CANVAS_DISCUSSION_ICON = base64.decode(CANVAS_DISCUSSION_BASE64)
CANVAS_QUIZ_ICON = base64.decode(CANVAS_QUIZ_BASE64)

#Method to make an event
def showEvent(event, page_label = ""):
    date_children = [
        render.Text(event[0][5:10], color = "#d52e3a", font = "5x8"),
    ]
    if page_label != "":
        date_children.append(render.Text(page_label, color = "#aaaaaa", font = "tom-thumb"))

    return render.Row(
        cross_align = "center",
        children = [
            render.Padding(
                pad = (2, 0, 2, 0),
                child = render.Image(src = event[2], width = 13),
            ),
            render.Column(
                children = [
                    render.Marquee(
                        width = 40,
                        child = render.Text(event[1]),
                    ),
                    render.Box(
                        width = 47,
                        height = 8,
                        child = render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "center",
                            children = date_children,
                        ),
                    ),
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

def normalize_base_url(base_url):
    base_url = base_url.strip().rstrip("/")
    if base_url == "":
        return DEFAULT_CANVAS_BASE_URL
    if not base_url.startswith("http://") and not base_url.startswith("https://"):
        return "https://" + base_url
    return base_url

def get_courses(api_token, base_url):
    response = http.get(
        base_url + "/api/v1/courses",
        headers = {"Authorization": "Bearer " + api_token},
        params = {
            "enrollment_state": "active",
            "per_page": "100",
        },
        ttl_seconds = COURSES_CACHE_TTL_SECONDS,
    )
    if response.status_code == 401:
        return [], "Invalid access token."
    if response.status_code != 200:
        return [], "Can not Connect to Canvas"

    data = response.json()
    if type(data) != "list":
        return [], "Invalid Canvas response"

    courses = []
    for course in data:
        if type(course) != "dict":
            continue
        course_id = course.get("id")
        if type(course_id) == "int" or type(course_id) == "float":
            courses.append(str(int(course_id)))
        elif type(course_id) == "string" and course_id != "":
            courses.append(course_id)
    return courses, 0

def normalize_id(value):
    if type(value) == "int" or type(value) == "float":
        return str(int(value))
    if type(value) == "string":
        return value
    return ""

def get_assignment_icon(assignment):
    submission_types = assignment.get("submission_types", [])
    if type(submission_types) != "list":
        submission_types = []

    if "discussion_topic" in submission_types or type(assignment.get("discussion_topic")) == "dict":
        return CANVAS_DISCUSSION_ICON
    if "online_quiz" in submission_types or normalize_id(assignment.get("quiz_id")) != "":
        return CANVAS_QUIZ_ICON
    return CANVAS_ASSIGNMENT_ICON

def assignment_is_submitted(assignment):
    submission = assignment.get("submission")
    if type(submission) != "dict":
        return False

    if submission.get("excused") == True:
        return True

    submitted_at = submission.get("submitted_at")
    if type(submitted_at) == "string" and submitted_at != "":
        return True

    workflow_state = submission.get("workflow_state")
    return workflow_state in ["submitted", "graded", "pending_review"]

def get_completed_assignment_ids(api_token, base_url):
    completed_assignment_ids = {}

    for page in range(1, MAX_PLANNER_OVERRIDE_PAGES + 1):
        response = http.get(
            base_url + "/api/v1/planner/overrides",
            headers = {"Authorization": "Bearer " + api_token},
            params = {
                "page": str(page),
                "per_page": str(PLANNER_OVERRIDES_PER_PAGE),
            },
            ttl_seconds = PLANNER_OVERRIDES_CACHE_TTL_SECONDS,
        )
        if response.status_code == 401:
            return {}, "Invalid access token."
        if response.status_code != 200:
            return {}, "Can not read Canvas To Do"

        overrides = response.json()
        if type(overrides) != "list":
            return {}, "Invalid Canvas To Do response"

        for override in overrides:
            if type(override) != "dict" or override.get("marked_complete") != True:
                continue

            assignment_id = normalize_id(override.get("assignment_id"))
            if assignment_id == "":
                plannable_type = override.get("plannable_type")
                if type(plannable_type) == "string":
                    normalized_type = plannable_type.lower().replace("_", "")
                    if normalized_type in ["assignment", "subassignment", "peerreviewsubassignment"]:
                        assignment_id = normalize_id(override.get("plannable_id"))

            if assignment_id != "":
                completed_assignment_ids[assignment_id] = True

        if len(overrides) < PLANNER_OVERRIDES_PER_PAGE:
            break

    return completed_assignment_ids, 0

def get_remote_assignments(api_token, base_url, course_id, due_date_cutoff_hours, completed_assignment_ids, hide_completed_todos):
    response = http.get(
        base_url + "/api/v1/courses/" + str(course_id) + "/assignments",
        headers = {"Authorization": "Bearer " + api_token},
        params = {
            "bucket": "future",
            "include[]": "submission",
            "order_by": "due_at",
            "per_page": "100",
        },
        ttl_seconds = ASSIGNMENTS_CACHE_TTL_SECONDS,
    )
    if response.status_code == 401:
        return [], "Invalid access token."
    if response.status_code != 200:
        return [], "Can not Connect to Canvas"

    data = response.json()
    if type(data) != "list":
        return [], "Invalid Canvas response"

    assignments = []
    now = time.now()
    for assignment in data:
        if type(assignment) != "dict":
            continue

        assignment_id = normalize_id(assignment.get("id"))
        if hide_completed_todos and (assignment_id in completed_assignment_ids or assignment_is_submitted(assignment)):
            continue

        due_at = assignment.get("due_at")
        if type(due_at) != "string" or due_at == "":
            continue

        due_time = time.parse_time(due_at)
        if due_time <= now or (due_time - now).hours > due_date_cutoff_hours:
            continue

        name = assignment.get("name")
        if type(name) != "string" or name == "":
            name = "Untitled Assignment"
        assignments.append((due_at, name, get_assignment_icon(assignment)))

    return assignments, 0

def get_events(api_token, base_url, course_id, due_date_cutoff_hours, completed_assignment_ids, hide_completed_todos):
    return get_remote_assignments(api_token, base_url, course_id, due_date_cutoff_hours, completed_assignment_ids, hide_completed_todos)

def get_due_date_cutoff_hours(config):
    cutoff_days = str(config.get("due_date_cutoff_days", DEFAULT_DUE_DATE_CUTOFF_DAYS)).strip()
    if not cutoff_days.isdigit() or int(cutoff_days) < 1:
        cutoff_days = DEFAULT_DUE_DATE_CUTOFF_DAYS
    return min(int(cutoff_days), MAX_DUE_DATE_CUTOFF_DAYS) * 24

def make_assignment_page(assignments, page_number, total_pages):
    page_label = "{}/{}".format(page_number, total_pages)
    children = [
        showEvent(assignments[0], page_label if len(assignments) == 1 else ""),
        render.Box(width = 100, height = 1, color = "#ffffff"),
    ]
    if len(assignments) == 2:
        children.append(showEvent(assignments[1], page_label))
    return render.Column(children = children)

def render_assignment_pages(assignments):
    assignments = sorted(assignments, key = lambda assignment: time.parse_time(assignment[0]).unix)
    total_pages = (len(assignments) + 1) // 2
    pages = [
        make_assignment_page(assignments[index:index + 2], index // 2 + 1, total_pages)
        for index in range(0, len(assignments), 2)
    ]

    if len(pages) == 1:
        return render.Root(child = pages[0])

    page_animations = [
        render.Animation(children = [page] * max(PAGE_MIN_FRAME_COUNT, page.frame_count()))
        for page in pages
    ]
    return render.Root(
        child = render.Sequence(children = page_animations),
        delay = FRAME_DELAY_MS,
        show_full_animation = True,
    )

def fake_events():
    assignment = ["2024-04-21T03:59:59Z", "Example Assignment", get_assignment_icon({})]
    quiz = ["2024-11-23T03:59:59Z", "Example Quiz", get_assignment_icon({"submission_types": ["online_quiz"]})]
    discussion = ["2024-11-24T03:59:59Z", "Example Discussion", get_assignment_icon({"submission_types": ["discussion_topic"]})]
    return render_assignment_pages([assignment, quiz, discussion])

def main(config):
    api_token = config.get("msg", "")
    base_url = normalize_base_url(config.get("base_url", DEFAULT_CANVAS_BASE_URL))
    due_date_cutoff_hours = get_due_date_cutoff_hours(config)
    hide_completed_todos = config.bool("hide_completed_todos", False)

    if api_token == "":
        return fake_events()

    classes, error_code = get_courses(api_token, base_url)

    if error_code != 0:
        return makeError(error_code)

    completed_assignment_ids = {}
    if hide_completed_todos:
        completed_assignment_ids, error_code = get_completed_assignment_ids(api_token, base_url)
        if error_code != 0:
            return makeError(error_code)

    canvas_data = []
    for course in classes:
        event, error_code = get_events(api_token, base_url, course, due_date_cutoff_hours, completed_assignment_ids, hide_completed_todos)
        if error_code != 0:
            return makeError(error_code)
        canvas_data = canvas_data + event

    if len(canvas_data) > 0:
        return render_assignment_pages(canvas_data)
    elif len(canvas_data) == 0:
        if config.bool("no_assigment", False):
            return []
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
            ),
            schema.Text(
                id = "base_url",
                name = "Canvas URL",
                desc = "Your institution's Canvas URL",
                icon = "globe",
                default = DEFAULT_CANVAS_BASE_URL,
            ),
            schema.Text(
                id = "due_date_cutoff_days",
                name = "Due within (days)",
                desc = "Show assignments due within 1-365 days",
                icon = "calendar",
                default = DEFAULT_DUE_DATE_CUTOFF_DAYS,
            ),
            schema.Toggle(
                id = "hide_completed_todos",
                name = "Hide completed To Do items",
                desc = "Hide assignments marked done in the Canvas To Do list",
                icon = "check",
                default = False,
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
