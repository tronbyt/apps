"""
Applet: Fly.io
Summary: Monitor Fly.io Apps
Description: View current status of your Fly.io App's machines.
Author: Cavallando
"""

load("animation.star", "animation")
load("http.star", "http")
load("images/fly_logo.png", FLY_LOGO_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

FLY_LOGO = FLY_LOGO_ASSET.readall()

PREVIEW_APP_NAME = "Welcome!"
PREVIEW_API_KEY = "preview-api-key"

FLY_API_BASE_URL = "https://api.machines.dev"

DOT_DIAMETER = 4
IMG_PAD = 1
TEXT_HEIGHT = 8
SCREEN_HEIGHT = 32
SCREEN_WIDTH = 64
LOGO_WIDTH = 12
LOGO_HEIGHT = 12

CHUNK_SCROLL_ANIMATION_FRAME_LEN = 150
CHUNK_SCROLL_ANIMATION_PAUSE_FRAME = 0.75

def get_machines(app_name, api_key):
    """
      Gets the machines from the fly.io endpoint
      Errors are returned via a "machine" object for easier rendering
    """
    machines = []

    # Config Validation/Error Handling
    if not app_name:
        machines.append({"name": "Missing App Name", "state": "error"})
    if not api_key:
        machines.append({"name": "Missing API Key", "state": "error"})
    if not api_key or not app_name:
        return machines

    # Render a preview of the app
    if app_name == PREVIEW_APP_NAME and api_key == PREVIEW_API_KEY:
        return [{"name": "Monitor your Fly.io App machines", "state": "preview"}]

    machines_url = "{}/v1/apps/{}/machines".format(FLY_API_BASE_URL, app_name)
    response = http.get(machines_url, headers = {"Authorization": "Bearer {}".format(api_key)}, ttl_seconds = 220)

    if (response.status_code != 200):
        return [{"name": "Error fetching machines", "state": "error"}]

    machines = response.json()
    if len(machines) == 0:
        return [{"name": "No machines", "state": "error"}]

    return machines

def get_status_img(machine):
    """
      Gets the status indicator based on the machine state
    """
    green = "#34D399"
    yellow = "#FFD700"
    red = "#FF0000"
    gray = "#94A3B8"
    blue = "#0057B7"

    status_color = red
    state = machine["state"]

    # Split if's for readability, no switch in starlark
    if state == "created":
        status_color = blue
    elif state == "starting":
        status_color = yellow
    elif state == "started":
        status_color = green
    elif state == "stopping":
        status_color = yellow
    elif state == "stopped":
        status_color = gray
    elif state == "suspending":
        status_color = yellow
    elif state == "suspended":
        status_color = gray
    elif state == "replacing":
        status_color = yellow
    elif state == "destroying":
        status_color = red
    elif state == "destroyed":
        status_color = red
    elif state == "preview":
        # custom state for preview in Tidbyt App
        status_color = blue

    return render.Padding(child = render.Circle(color = status_color, diameter = DOT_DIAMETER), pad = IMG_PAD)

def render_header(app_name):
    """
      Render the header in a row with the Fly.io logo and app name, app_name scrolls left in a marquee
    """
    return render.Row(
        cross_align = "center",
        children = [
            render.Padding(
                child = render.Image(src = FLY_LOGO, width = LOGO_WIDTH, height = LOGO_HEIGHT),
                pad = IMG_PAD,
            ),
            render.Marquee(child = render.Text(app_name), width = SCREEN_WIDTH - LOGO_WIDTH - IMG_PAD),
        ],
    )

def render_machine_name(machine):
    """
      Render a machine name with a horizontal marquee animation if the length is greater than the screen width
    """
    name_text = render.Text(machine["name"])
    name_len = len(machine["name"]) * 5

    # Delay based on when the chunk animation is paused, additional 30 subtracted for fine tuning
    name_delay = math.floor((100 * CHUNK_SCROLL_ANIMATION_PAUSE_FRAME)) - 30

    # Create a horizontal marquee for each machine name
    name_animation = animation.Transformation(
        child = name_text,
        duration = 100,
        delay = name_delay,
        direction = "normal",
        origin = animation.Origin(0, 0),
        height = TEXT_HEIGHT,
        keyframes = [
            animation.Keyframe(
                percentage = 0.0,
                transforms = [animation.Translate(x = 0, y = 0)],
                curve = "linear",
            ),
            animation.Keyframe(
                percentage = 1.0,
                transforms = [animation.Translate(x = -(name_len + IMG_PAD + DOT_DIAMETER), y = 0)],
                curve = "linear",
            ),
        ],
    )

    name_available_width = SCREEN_WIDTH - DOT_DIAMETER - IMG_PAD

    return render.Row(
        cross_align = "center",
        children = [
            get_status_img(machine),
            name_text if name_len < name_available_width else name_animation,
        ],
    )

def render_body(machines):
    """
        Renders the body content for the app
        Chunks the machines into groups of two, and slides each chunk in from right to left
        Keeps paging through all chunks. If there is text overflow then that is also animated across.
    """
    available_height = SCREEN_HEIGHT - LOGO_HEIGHT - (IMG_PAD * 2)
    visible_rows = math.floor(available_height / TEXT_HEIGHT)

    animated_widgets = []

    # Create a horizontal scrolling animation for each chunk of machines
    # Chunks should be made up of at most 2 machines
    # Each chunk animates horizontally in from the right, and pauses for a moment to let any names finish scrolling in
    # and then scrolls back out to the left
    for i in range(0, len(machines), visible_rows):
        chunk = machines[i:i + visible_rows]
        chunk_rows = []

        for machine in chunk:
            chunk_rows.append(render_machine_name(machine))

        chunk_column = render.Column(children = chunk_rows)

        # Create a horizontal scrolling animation for this chunk
        animated_widgets.append(animation.Transformation(
            child = chunk_column,
            duration = CHUNK_SCROLL_ANIMATION_FRAME_LEN,
            delay = 0,
            keyframes = [
                animation.Keyframe(
                    percentage = 0,
                    transforms = [animation.Translate(y = 0, x = SCREEN_WIDTH)],
                ),
                animation.Keyframe(
                    percentage = 0.25,
                    transforms = [animation.Translate(y = 0, x = 0)],
                ),
                animation.Keyframe(
                    percentage = 0.75,
                    transforms = [animation.Translate(y = 0, x = 0)],
                ),
                animation.Keyframe(
                    percentage = 1,
                    transforms = [animation.Translate(y = 0, x = -SCREEN_WIDTH)],
                ),
            ],
        ))

    return render.Sequence(children = animated_widgets)

def main(config):
    app_name = config.str("app_name", PREVIEW_APP_NAME)
    api_key = config.str("api_key", PREVIEW_API_KEY)

    machines = get_machines(app_name, api_key)

    return render.Root(
        child = render.Column(
            children = [
                render_header(app_name),
                render_body(machines),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "app_name",
                name = "App Name",
                desc = "The name of the Fly.io app to monitor.",
                icon = "server",
            ),
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "The API key to use to authenticate with the Fly.io API.",
                icon = "key",
                secret = True,
            ),
        ],
    )
