"""
Applet: LIFX Lights
Summary: LIFX lights status
Description: View the current status and color of your lights.
Author: Daniel Sitnik
"""

load("http.star", "http")
load("images/lifx_logo.png", LIFX_LOGO_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

LIFX_LOGO = LIFX_LOGO_ASSET.readall()

# lifx API base URL
LIFX_URL = "https://api.lifx.com/v1"

# lifx logo

# default blink option
DEFAULT_BLINK = False

# default number of frames to animate blinking
DEFAULT_FRAMES = 15

# default color to fade to when blinking
DEFAULT_FADED_COLOR = "#000000"

def main(config):
    """
    Main app method.

        Parameters:
            config (config): The config object with the user's options.

        Returns:
            render (widget): The widget tree to be rendered on the Tidbyt.
    """
    token = config.str("token")
    light_id = config.str("light_id")
    blink = config.bool("blink", DEFAULT_BLINK)

    # if there's no token or light id, render the demo
    if token == None or light_id == None:
        return render_demo_setup()

    # render error message when no lights are found during config
    if light_id == "nolights":
        return render_error("No lights found", ":(")

    # render error message when listing the lights during config fails
    if light_id == "listlighterror":
        return render_error("Error listing lights", "Check token")

    # try to get the light information
    rep = http.get(LIFX_URL + "/lights/id:" + light_id, headers = {
        "Authorization": "Bearer " + token,
    })

    # render error if API fails
    if rep.status_code != 200:
        error = rep.json()["error"] or "Error calling LIFX API"
        return render_error(error, get_error_message_for_status_code(rep.status_code))

    light = rep.json()[0]

    hue = light["color"]["hue"]
    saturation = light["color"]["saturation"]
    brightness = light["brightness"]
    brightness_percent = int(brightness * 100)
    power = light["power"].upper()

    rgb = hsb_to_rgb(hue, saturation, brightness)

    return render.Root(
        child = render.Box(
            child = render.Column(
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = LIFX_LOGO, height = 10),
                    render.Marquee(
                        width = 60,
                        align = "center",
                        child = render.Padding(pad = (0, 1, 0, 0), child = render.Text(light["label"], font = "5x8")),
                    ),
                    render.Row(
                        expanded = False,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Padding(pad = (2, 1, 2, 0), child = get_circle_widget(rgb, power, blink)),
                            render.Padding(pad = (2, 1, 2, 0), child = render.Text(power)),
                            render.Padding(pad = (0, 1, 0, 0), child = render.Text("(%d%%)" % brightness_percent if power == "ON" else "")),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    """
    Returns the app configuration schema. Asks for the LIFX
    personal access token first, and then generates the next
    options dynamically.

        Returns:
            schema (schema): The configuration schema.
    """

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "token",
                name = "Personal Access Token",
                desc = "Token generated at https://cloud.lifx.com.",
                icon = "hashtag",
                secret = True,
            ),
            schema.Generated(
                id = "light_id",
                source = "token",
                handler = select_light,
            ),
        ],
    )

def select_light(token):
    """
    Used to list the user's lights from the LIFX API after the
    personal access token has been informed, and then return a
    dropdown to let the user select the light to monitor.

        Parameters:
            token (string): The persona access token.

        Returns:
            schema (schema): A dropdown schema with the light options.
    """

    print("Listing available lights from LIFX API")
    rep = http.get(LIFX_URL + "/lights/all", headers = {
        "Authorization": "Bearer " + token,
    })

    # handle API error returning a message on the dropdown :(
    if rep.status_code != 200:
        return [
            schema.Dropdown(
                id = "light_id",
                name = "Light",
                desc = "Select your light.",
                icon = "lightbulb",
                options = [schema.Option(display = "Error retrieving lights", value = "listlighterror")],
                default = "lighterror",
            ),
        ]

    # get API response
    lights = rep.json()
    print("Retrieved %d lights" % len(lights))

    options = []
    default = ""

    # loop through lights to build the dropdown options
    for light in lights:
        if default == "":
            default = light["id"]

        options.append(
            schema.Option(display = light["label"], value = light["id"]),
        )

    # if there were no lights, insert a dummy option in the dropdown
    if len(options) == 0:
        options = [schema.Option(display = "No lights found", value = "nolights")]
        default = "nolights"

    return [
        schema.Dropdown(
            id = "light_id",
            name = "Light",
            desc = "Select your light.",
            icon = "lightbulb",
            options = options,
            default = default,
        ),
        schema.Toggle(
            id = "blink",
            name = "Blink color",
            desc = "Blink color when light is on.",
            icon = "circleDot",
            default = DEFAULT_BLINK,
        ),
    ]

def render_demo_setup():
    """
    Used to render a preview/demonstration of the app
    requesting the user to go through the setup process.
    """

    label = "Demo Light (please setup)"
    rgb = "#ffff00"
    power = "ON"
    blink = False
    brightness_percent = 95

    return render.Root(
        child = render.Box(
            child = render.Column(
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = LIFX_LOGO, height = 10),
                    render.Marquee(width = 60, align = "center", child = render.Text(label, font = "5x8")),
                    render.Row(
                        expanded = False,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Padding(pad = (2, 0, 2, 0), child = get_circle_widget(rgb, power, blink)),
                            render.Padding(pad = (2, 0, 2, 0), child = render.Text(power)),
                            render.Text("(%d%%)" % brightness_percent if power == "ON" else ""),
                        ],
                    ),
                ],
            ),
        ),
    )

def render_error(error_message, complement = ""):
    """
    Used to render error messages on the Tidbyt and guide
    the user without having to resort to "fail".

        Parameters:
            error_message (string): The error message to display.
            complement (string): Optional message complement to display.

        Returns:
            An outlined Circle when the light is OFF, and a filled
            Circle when it's ON, possibly blinking.
    """

    return render.Root(
        child = render.Box(
            child = render.Column(
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = LIFX_LOGO, height = 10),
                    render.Marquee(width = 60, align = "center", child = render.Padding(pad = (0, 2, 0, 2), child = render.Text(error_message, font = "tom-thumb"))),
                    render.Marquee(width = 60, align = "center", child = render.Padding(pad = (0, 2, 0, 2), child = render.Text(complement, font = "tom-thumb"))),
                ],
            ),
        ),
    )

def get_circle_widget(color, power, blink):
    """
    Returns the Circle widget that will be used to represent the
    light status.

        Parameters:
            color (string): The current light color.
            power (string): The current light power state (ON/OFF).
            blink (boolean): If the Circle widget should blink or not.

        Returns:
            circle (widget): An outlined Circle when the light is OFF, and a filled
            Circle when it's ON, possibly blinking.
    """

    if power.upper() == "OFF":
        return render.Circle(
            color = color,
            diameter = 8,
            child = render.Circle(
                color = DEFAULT_FADED_COLOR,
                diameter = 6,
            ),
        )

    if power.upper() == "ON" and blink == True:
        return render.Animation(
            children = get_faded_color_frames(color, DEFAULT_FADED_COLOR),
        )
    else:
        return render.Circle(
            color = color,
            diameter = 8,
        )

def get_faded_color_frames(source_color, target_color):
    """
    Calculates the intermediary RGB colors necesary to create
    a fading effect between two colors.

        Parameters:
            source_color (string): The source RGB color.
            target_color (string): The target RGB color.

        Returns:
            frames: (widget[]) An array of frames where a Circle widget is animated
            with a fade out/fade in effect between the colors.
    """

    # convert source values to int
    source_int_r = int(source_color[1:3], 16)
    source_int_g = int(source_color[3:5], 16)
    source_int_b = int(source_color[5:], 16)

    # convert target values to int
    target_int_r = int(target_color[1:3], 16)
    target_int_g = int(target_color[3:5], 16)
    target_int_b = int(target_color[5:], 16)

    # compute increments/decrements
    range_r = (target_int_r - source_int_r) / DEFAULT_FRAMES
    range_g = (target_int_g - source_int_g) / DEFAULT_FRAMES
    range_b = (target_int_b - source_int_b) / DEFAULT_FRAMES

    # generate colors
    colors = []
    for i in range(0, DEFAULT_FRAMES - 1):
        # compute the color for the frame and convert to hex
        final_hex_r = "%x" % math.floor(i * range_r + source_int_r)
        final_hex_g = "%x" % math.floor(i * range_g + source_int_g)
        final_hex_b = "%x" % math.floor(i * range_b + source_int_b)

        # pad colors with 0 on the left when needed
        final_r = "0%s" % final_hex_r if len(final_hex_r) == 1 else final_hex_r
        final_g = "0%s" % final_hex_g if len(final_hex_g) == 1 else final_hex_g
        final_b = "0%s" % final_hex_b if len(final_hex_b) == 1 else final_hex_b

        # append to the list
        colors.append("#%s%s%s" % (final_r, final_g, final_b))

    # generate frames
    frames = []

    # generate frames to fade out the color
    for i in range(0, len(colors)):
        frames.append(
            render.Circle(
                color = colors[i],
                diameter = 8,
            ),
        )

    # generate frames in reverse order to fade back in
    for i in range(len(colors) - 1, -1, -1):
        frames.append(
            render.Circle(
                color = colors[i],
                diameter = 8,
            ),
        )

    return frames

def hsb_to_rgb(hue, saturation, brightness):
    """
    Converts a LIFX color in HSB to RGB.

        Parameters:
            hue (float): The color hue (between 0 and 360)
            saturation (float): The color saturation (between 0 and 1)
            brightness (float): The color brightness (between 0 and 1)

        Returns:
            color (string): The hexadecimal representation of the color (eg: #ff00aa)
    """
    red = int(255 * f_func(5, hue, saturation, brightness))
    green = int(255 * f_func(3, hue, saturation, brightness))
    blue = int(255 * f_func(1, hue, saturation, brightness))

    hex_red = ("%x" % red)
    hex_green = ("%x" % green)
    hex_blue = ("%x" % blue)

    if len(hex_red) == 1:
        hex_red = "0" + hex_red

    if len(hex_green) == 1:
        hex_green = "0" + hex_green

    if len(hex_blue) == 1:
        hex_blue = "0" + hex_blue

    return "#" + hex_red + hex_green + hex_blue

def k_func(n, hue):
    """
    Auxiliary function used to convert HSB to RGB.
    """
    return (n + hue / 60) % 6

def f_func(n, hue, saturation, brightness):
    """
    Auxiliary function used to convert HSB to RGB.
    """
    return brightness * (1 - saturation * max(0, min(k_func(n, hue), 4 - k_func(n, hue), 1)))

def get_error_message_for_status_code(status_code):
    """
    Returns the error message to be shown on the Tidbyt when
    the LIFX API returns an error.

        Parameters:
            status_code (int): The HTTP status code returned by LIFX API.

        Returns:
            message (string): The error message to be displayed.
    """

    if status_code == 400:
        return "Bad request"
    elif status_code == 401:
        return "Unauthorized"
    elif status_code == 403:
        return "Perm. denied"
    elif status_code == 404:
        return "Not found"
    elif status_code == 422:
        return "Malformed params"
    elif status_code == 426:
        return "Use HTTPS"
    elif status_code == 429:
        return "Rate limited"
    else:
        return "Server error (5xx)"
