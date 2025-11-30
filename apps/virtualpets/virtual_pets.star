"""
Applet: Virtual Pets
Summary: Virtual pets
Description: Choose and name your own pet while watching the environment change with the seasons and time of day!
Author: frame-shift
"""

load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/autumn_a155f165.png", AUTUMN_a155f165_ASSET = "file")
load("images/inside_22e413c6.png", INSIDE_22e413c6_ASSET = "file")
load("images/spring_444b637d.png", SPRING_444b637d_ASSET = "file")
load("images/summer_7b049e9c.png", SUMMER_7b049e9c_ASSET = "file")
load("images/winter_b0402df9.png", WINTER_b0402df9_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Default values
DEFAULT_PET = "cat"
DEFAULT_NAME = "Fluffy"
DEFAULT_SHOW = True
DEFAULT_LOCATION = """
    {
	"lat": "40.69754",
	"lng": "-74.3093231",
	"description": "New York, NY, USA",
	"locality": "New York City",
	"timezone": "America/New_York"
    }
    """

# Backgrounds
INSIDE = INSIDE_22e413c6_ASSET.readall()
WINTER = WINTER_b0402df9_ASSET.readall()
SPRING = SPRING_444b637d_ASSET.readall()
SUMMER = SUMMER_7b049e9c_ASSET.readall()
AUTUMN = AUTUMN_a155f165_ASSET.readall()

# HTTP cache
TTL_TIME = 86400  # 24 hours is 86400

def main(config):
    # Run and display the app based on choices
    pet = config.str("choice_pet", DEFAULT_PET)
    name = config.str("choice_name", DEFAULT_NAME)
    show = config.bool("choice_show", DEFAULT_SHOW)

    # Determine hemisphere for correct season rendering
    location = config.get("choice_loc", DEFAULT_LOCATION)
    loc = json.decode(location)
    lat = float(loc["lat"])

    if lat >= 0:
        hemi = "north"
    else:
        hemi = "south"

    # Determine current season and time of day (period)
    timezone = loc.get("timezone")
    now = time.now().in_location(timezone)
    season, period = read_time(now, hemi)

    # Set animation delays and actions
    ani_action, ani_delay = render_action(pet)

    # Set filter for time of day
    filter = render_filter(period)

    # Render name row if 'Show name' toggled On
    if show == True:
        name_shadow, name_name = render_name(name)
    else:
        name_shadow, name_name = [None, None]

    # Render for display
    return render.Root(
        delay = ani_delay,
        child = render.Stack(
            children = [
                # Background
                render_bg(season, period),
                # Filter for scene
                filter,
                # Pet action
                ani_action,
                # Filter for pet
                filter,
                # Row for name shadow
                name_shadow,
                # Row for name
                name_name,
            ],
        ),
    )

def get_img(pet, action):
    # Fetch pet action images from common URL
    url = "https://raw.githubusercontent.com/frame-shift/images/main/Tidbyt/pets/%s-%s.gif" % (pet, action)

    # Fetch images from web
    res = http.get(url, ttl_seconds = TTL_TIME)

    # An error occured
    if res.status_code != 200:
        # In the event of a failure, return empty string
        return None

    # Grab and return responses body
    data = res.body()
    return data

def read_time(right_now, hemi):
    # Parse current time
    date_m = int(humanize.time_format("M", right_now))
    date_h = int(humanize.time_format("HH", right_now))

    # Determine season by hemisphere and month
    if hemi == "north":
        if 3 <= date_m and date_m <= 5:
            season = "spring"
        elif 6 <= date_m and date_m <= 8:
            season = "summer"
        elif 9 <= date_m and date_m <= 11:
            season = "autumn"
        else:
            season = "winter"
    elif 3 <= date_m and date_m <= 5:
        season = "autumn"
    elif 6 <= date_m and date_m <= 8:
        season = "winter"
    elif 9 <= date_m and date_m <= 11:
        season = "spring"
    else:
        season = "summer"

    # Determine time of day
    if 6 <= date_h and date_h <= 11:
        period = "morning"
    elif 12 <= date_h and date_h <= 17:
        period = "afternoon"
    elif 18 <= date_h and date_h <= 21:
        period = "evening"
    else:
        period = "night"

    # Return season and period
    return season, period

def render_filter(period):
    # Determine filter color by time of day
    if period == "morning":
        color_f = "#eea93320"
    elif period == "afternoon":
        color_f = "#00000000"
    elif period == "evening":
        color_f = "#582c5050"
    else:
        color_f = "#610c0420"

    return render.Box(
        color = color_f,
        width = 64,
        height = 32,
    )

def render_bg(season, period):
    # Determine background based on season + time of day
    if season == "spring":
        bg = SPRING
    elif season == "summer":
        bg = SUMMER
    elif season == "autumn":
        bg = AUTUMN
    else:
        bg = WINTER

    # Force background to night if time of day is night
    if period == "night":
        bg = INSIDE

    return render.Image(src = base64.decode(bg))

def render_action(pet):
    # Determine pet actions based on random numbers
    q = random.number(0, 3)  # For random action
    p = random.number(0, 36)  # For random pet location

    # Idle
    if q == 0:
        axn = render.Padding(
            child = render.Image(src = get_img(pet, "idle")),
            pad = (p, 0, 0, 0),
        )
        delay = 200

        # Play
    elif q == 1:
        axn = render.Padding(
            child = render.Image(src = get_img(pet, "play")),
            pad = (p, 0, 0, 0),
        )
        delay = 200

        # Sleep
    elif q == 2:
        axn = render.Padding(
            child = render.Image(src = get_img(pet, "sleep")),
            pad = (p, 0, 0, 0),
        )
        delay = 1250

        # Walk
    else:
        axn = animation.Transformation(
            child = render.Image(src = get_img(pet, "walk")),
            duration = 240,  # 240 is full 15 secs for Tidbyt display
            keyframes = [
                animation.Keyframe(
                    percentage = 0.0,
                    transforms = [animation.Translate(-30, 0)],
                ),
                animation.Keyframe(
                    percentage = 1.0,
                    transforms = [animation.Translate(70, 0)],
                ),
            ],
        )
        delay = 0

    return axn, delay

def render_name(name):
    # Render the name and shadow rows if toggled
    name_n = name.upper()
    font_n = "CG-pixel-3x5-mono"
    cir_d = 3
    shadow_c = "#000000"
    pad_name = (2, 2, 0, 0)
    pad_name_s = (pad_name[0], pad_name[1] + 1, pad_name[2], pad_name[3])
    pad_cir_s = (pad_name_s[0] + 1, pad_name_s[1], pad_name_s[2], pad_name_s[3])

    shadow_row = render.Row(
        main_align = "start",
        expanded = True,
        cross_align = "center",
        children = [
            render.Padding(
                child = render.Circle(color = shadow_c, diameter = cir_d),
                pad = pad_cir_s,
            ),
            render.Padding(
                child = render.Text(content = name_n, font = font_n, color = shadow_c),
                pad = pad_name_s,
            ),
        ],
    )

    name_row = render.Row(
        main_align = "start",
        expanded = True,
        cross_align = "center",
        children = [
            render.Padding(
                child = render.Circle(color = "#ff0000", diameter = cir_d),
                pad = pad_name,
            ),
            render.Padding(
                child = render.Text(content = name_n, font = font_n, color = "#ffffff"),
                pad = pad_name,
            ),
        ],
    )

    return shadow_row, name_row

def get_schema():
    # Options menu
    return schema.Schema(
        version = "1",
        fields = [
            # Select pet
            schema.Dropdown(
                id = "choice_pet",
                name = "Pet",
                desc = "Choose your favorite pet",
                icon = "paw",
                options = [
                    schema.Option(display = "Cat", value = "cat"),
                    schema.Option(display = "Dog", value = "dog"),
                    schema.Option(display = "Fox", value = "fox"),
                    schema.Option(display = "Hedgehog", value = "hedgehog"),
                    schema.Option(display = "Lizard", value = "lizard"),
                    schema.Option(display = "Parrot", value = "parrot"),
                    schema.Option(display = "Penguin", value = "penguin"),
                    schema.Option(display = "Raccoon", value = "raccoon"),
                    schema.Option(display = "Skunk", value = "skunk"),
                    schema.Option(display = "Turtle", value = "turtle"),
                ],
                default = DEFAULT_PET,
            ),

            # Select name
            schema.Text(
                id = "choice_name",
                name = "Pet name",
                desc = "Name your pet",
                icon = "pencil",
                default = DEFAULT_NAME,
            ),

            # Select show name toggle
            schema.Toggle(
                id = "choice_show",
                name = "Show name",
                desc = "A toggle to display or hide the pet name",
                icon = "eye",
                default = DEFAULT_SHOW,
            ),

            # Select location
            schema.Location(
                id = "choice_loc",
                name = "Location",
                icon = "locationDot",
                desc = "Your location changes which environments are displayed",
            ),
        ],
    )
