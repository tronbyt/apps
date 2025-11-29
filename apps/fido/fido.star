"""
Applet: Fido
Summary: A pixel pal
Description: Fido is a pixel pal that will sit, walk, and feast inside your Tidbyt.
Author: yonodactyl
"""

load("cache.star", "cache")
load("http.star", "http")
load("images/fence.png", FENCE_ASSET = "file")
load("images/grass.png", GRASS_ASSET = "file")
load("images/sky.png", SKY_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

FENCE = FENCE_ASSET.readall()
GRASS = GRASS_ASSET.readall()
SKY = SKY_ASSET.readall()

# CONFIG
TTL = 86400
DEFAULT_TIMEZONE = "America/New_York"
DEFAULT_BIRTHDAY = "2022-12-29T10:00:00Z"
LAST_DAY_WALKED = "2022-12-28T10:00:00Z"
HOURS_IN_YEAR = 8760
HOURS_IN_MONTH = 730
DEFAULT_PAL_NAME = "Fido"

# Static Base64 Image Data

# Animated Actions
BALL_THROW = "https://raw.githubusercontent.com/Yonodactyl/TidbytGIFs/main/Fido/ball_throw.gif"

# Pet Actions
PET_ACTIONS = {
    "Sit": "https://raw.githubusercontent.com/Yonodactyl/TidbytGIFs/main/Fido/fido_sit.gif",
    "Walk": "https://raw.githubusercontent.com/Yonodactyl/TidbytGIFs/main/Fido/fido_walk.gif",
    "Fetch": "https://raw.githubusercontent.com/Yonodactyl/TidbytGIFs/main/Fido/fido_fetch.gif",
}
FIDO_FETCH = PET_ACTIONS["Fetch"]

def main(config):
    # Set configuration variables
    timezone = time.tz()
    pet_name = config.get("pet_name", DEFAULT_PAL_NAME)
    pet_birthday = config.str("pet_birthday", DEFAULT_BIRTHDAY)

    action_config = config.get("pet_action", PET_ACTIONS["Sit"])
    if action_config == "random":
        idx = random.number(0, len(PET_ACTIONS) - 1)  #-1 because indices start at zero
        action_config = PET_ACTIONS.values()[idx]

    stats_config = config.bool("showing_stats", False)

    # Grab the pets age - returned in hours
    pet_age = return_dog_age_in_hours(timezone, pet_birthday)

    action = get_cached(action_config)

    if action == None:
        # Render text placeholder in the event that data doesnt exist
        return render.Root(
            child = render.Box(
                child = render.Marquee(
                    width = 64,
                    child = render.Text("There is no Pal here"),
                ),
            ),
        )
    else:
        # Main Render for the the dog and environment.
        return render.Root(
            delay = 150,
            child = render.Stack(
                children = [
                    render.Image(src = SKY),  # Furthest Background
                    render.Image(src = FENCE),  # Background Element
                    render.Image(src = action),  # Your Pet
                    interacting_object(action_config),
                    render.Image(src = GRASS),  # Foreground Element
                    # Pet Name and Age Banner
                    render.Box(
                        height = 7,
                        width = 64 if stats_config else 32,
                        color = "#000",
                        child = pet_info(pet_name.upper(), pet_age) if stats_config else return_pal(pet_name.upper()),
                    ),
                ],
            ),
        )

# Object Interaction
def interacting_object(action_config):
    """
    Handle potential object interactions - in this case fetching the ball
    """
    if action_config == FIDO_FETCH:
        action = get_cached(BALL_THROW)
        return render.Image(src = action)

    return None

# Returns the pet information like the name and age
def pet_info(name, pet_age):
    return render.Column(
        expanded = True,
        children = [
            render.Row(
                children = [
                    return_pal(name),
                    return_pal_age(pet_age),
                ],
            ),
        ],
    )

# Dog Age Calculation Helper
# This function returns the age of the dog in a readable format. i.e. - `1 y` or `28 d` (1 year or 28 days, respectively)
def convert_hours_to_age(pet_age):
    years = pet_age.hours / HOURS_IN_YEAR

    # TODO: Clean this function up some time to better return days - maybe the humanize module can help?
    if years < 1 and years > 0:
        age = str("{days}d").format(days = int(pet_age.hours / 24))  # Handle days
    elif years < 0:
        age = "Time Traveler"  # Handle case where the user puts the birthdate in the future
    else:
        age = str("{years}y").format(years = int(years / 1))  # Handle years

    return age

# Returns the age of the dog in Hours.
def return_dog_age_in_hours(timezone, birthdate):
    current_time = time.now().in_location(timezone)
    start_time = time.parse_time(birthdate)

    return current_time - start_time

# AGE HANDLERS

# Returns the name of the Pal in either a Text or Marquee+Text variant.
def return_pal(name):
    # This is determined by the length of the name of the pet.
    # Anything above 7 should be rendered as scrolling text because it wont fit within the bounds of the Box.
    if len(name) <= 7:
        return return_wrapped_text(name, width = 32)
    else:
        return return_marquee_text(name, width = 32)

# Returns the age of the Pal in a formatted string
def return_pal_age(pet_age):
    converted_age = convert_hours_to_age(pet_age)
    formatted_age_str = "Age:{age}".format(age = converted_age)

    if len(formatted_age_str) <= 7:
        return return_wrapped_text(formatted_age_str, color = "#add8e6", align = "center")
    else:
        return return_marquee_text(formatted_age_str, color = "#add8e6", width = 30)

# Returns left aligned, 32 pixel wide and high Wrapped Text with the passed in parameter.
def return_wrapped_text(text, color = "#fff", align = "left", width = 32):
    return render.Padding(
        pad = (1, 1, 0, 0),
        child = render.WrappedText(
            content = text,
            color = color,
            font = "tom-thumb",
            width = width,
            align = align,
        ),
    )

# Returns 32 pixel wide, 7 pixel high (default) Marquee Text with the passed in parameter.
def return_marquee_text(text, color = "#fff", width = 32, direction = "horizontal"):
    return render.Padding(
        pad = (1, 1, 0, 0),
        child = render.Marquee(
            width = width,
            scroll_direction = direction,
            child = render.WrappedText(
                content = text,
                color = color,
                font = "tom-thumb",
                align = "left",
            ),
            offset_start = 1,
            offset_end = 1,
        ),
    )

def get_schema():
    # Pal action to be performed
    pal_action = [
        schema.Option(display = action, value = image)
        for action, image in PET_ACTIONS.items()
    ]
    pal_action.insert(0, schema.Option(display = "Random", value = "random"))

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "pet_name",
                name = "Pet Name",
                desc = "What is your pet's name?",
                icon = "pencil",
                default = "FIDO",
            ),
            schema.DateTime(
                id = "pet_birthday",
                name = "Pet Birthday",
                desc = "When is your pet's birthday?",
                icon = "calendarDay",
            ),
            schema.Dropdown(
                id = "pet_action",
                name = "Action",
                desc = "What should your pet do?",
                icon = "dog",
                default = pal_action[1].value,  #default is Sit
                options = pal_action,
            ),
            schema.Toggle(
                id = "showing_stats",
                name = "Stats",
                desc = "Show or hide stats",
                icon = "barsProgress",
                default = False,
            ),
        ],
    )

# HELPER
def get_cached(url, ttl_seconds = TTL):
    # Attempt to grab the cache
    data = cache.get(url)

    if data:
        # Cache exist - returning this data
        return data

    # No cache - continuing to the web
    res = http.get(url)

    # An error occured
    if res.status_code != 200:
        # In the event of a failure, we should return an empty string
        return None

    # Grab responses body
    data = res.body()

    # Set cache and dont try again until the next day
    # TODO: Determine if this cache call can be converted to the new HTTP cache.
    cache.set(url, data, ttl_seconds = ttl_seconds)

    # Return the data we got from the web
    return data
