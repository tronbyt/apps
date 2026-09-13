"""
Applet: Nixel Clock
Summary: Pixel Nixie Clock
Description: It's a Nixie Clock made from Pixels!
Author: Olly Stedall @saltedlolly
Thanks: Joey Hoer, whose "Big Number Clock" code this is based on.
Notes: Numbers are 15 pixels wide. Seperator is 4 pixels wide. This is the widest you can effectively make a digital clock to fill all 64 pixels while maintaining numbers of equal width with space for a seperator.
"""

load("images/images.star", "IMAGE_SETS")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TIMEZONE = "Europe/London"
DEFAULT_IS_24_HOUR_FORMAT = False
DEFAULT_HAS_LEADING_ZERO = True
DEFAULT_HAS_FLASHING_SEPERATOR = False
DEFAULT_CLOCK_STYLE = "round_brighter"

def get_schema():
    styleoptions = [
        schema.Option(
            display = "Round (Darker)",
            value = "round_darker",
        ),
        schema.Option(
            display = "Round (Brighter)",
            value = "round_brighter",
        ),
        schema.Option(
            display = "Tall (Darker)",
            value = "tall_darker",
        ),
        schema.Option(
            display = "Tall (Brighter)",
            value = "tall_brighter",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "clock_style",
                name = "Clock style",
                icon = "gear",
                desc = "Change current clock style.",
                default = styleoptions[0].value,
                options = styleoptions,
            ),
            schema.Toggle(
                id = "is_24_hour_format",
                name = "24 hour format",
                icon = "clock",
                desc = "Toggle between 12/24hr clock.",
                default = DEFAULT_IS_24_HOUR_FORMAT,
            ),
            schema.Toggle(
                id = "has_leading_zero",
                name = "Leading zero",
                icon = "creativeCommonsZero",
                desc = "Show/hide leading zero.",
                default = DEFAULT_HAS_LEADING_ZERO,
            ),
            schema.Toggle(
                id = "has_flashing_seperator",
                name = "Flashing separator",
                icon = "gear",
                desc = "Enable/disable flashing number seperator.",
                default = DEFAULT_HAS_FLASHING_SEPERATOR,
            ),
        ],
    )

def main(config):
    # Get the current time in 24 hour format
    timezone = time.tz()  # Utilize special timezone variable
    current_time = time.parse_time(time.now().in_location(timezone).format("3:04:05 PM"), format = "3:04:05 PM", location = timezone)

    # Get config values
    is_24_hour_format = config.bool("is_24_hour_format", DEFAULT_IS_24_HOUR_FORMAT)
    has_leading_zero = config.bool("has_leading_zero", DEFAULT_HAS_LEADING_ZERO)
    has_flashing_seperator = config.bool("has_flashing_seperator", DEFAULT_HAS_FLASHING_SEPERATOR)
    clock_style = config.get("clock_style", DEFAULT_CLOCK_STYLE)

    # Set image variables for current Clock Style
    image_set = IMAGE_SETS.get(clock_style, IMAGE_SETS[DEFAULT_CLOCK_STYLE])
    SEP = image_set["sep"]
    NUMBER_IMGS = image_set["digits"]

    # troubleshooting....
    #    print("NUMBER_IMGS = " + NUMBER_IMGS)

    frames = []
    print_time = current_time

    # The API limit is ≈256kb (as reported by error messages).
    # However, sending a 256kb file doesn't seem to work.
    # Increase the duration to create an image containing multples minutes
    # of frames to smooth out potential network issues.
    # Currently this does not work, becasue app rotation prevents the animation
    # from progressing past a few seconds.
    duration = 1  # in minutes; 1440 = 24 hours
    for _ in range(0, duration):
        frames.append(get_time_image(print_time, NUMBER_IMGS, SEP, is_24_hour_format = is_24_hour_format, has_leading_zero = has_leading_zero, has_seperator = True))

        if has_flashing_seperator:
            # If the duration is greater than one minute,
            # generate one frame for each flash of the seperator for the whole minute
            number_of_frames = 1
            if duration > 1:
                # Two frames per second, minus one because first frame is created above
                number_of_frames = 60 * 2 - 1
            for j in range(0, number_of_frames):
                has_seperator = False
                if j % 2:
                    has_seperator = True
                frames.append(get_time_image(print_time, NUMBER_IMGS, SEP, is_24_hour_format = is_24_hour_format, has_leading_zero = has_leading_zero, has_seperator = has_seperator))
        print_time = print_time + time.minute

    return render.Root(
        delay = 500,  # in milliseconds
        max_age = 120,
        child = render.Box(
            child = render.Animation(
                children = frames,
            ),
        ),
    )

# It would be easier to use a custom font, but we can use images instead.
# The images have a black background and transparent foreground. This
# allows us to change the color dynamically.
def get_num_image(num, NUMBER_IMGS):
    return render.Box(
        width = 15,
        height = 32,
        child = render.Image(src = NUMBER_IMGS[int(num)].readall()),
    )

def get_time_image(t, NUMBER_IMGS, SEP, is_24_hour_format = True, has_leading_zero = False, has_seperator = True):
    hh = t.format("03")  # Formet for 12 hour time
    if is_24_hour_format == True:
        hh = t.format("15")  # Format for 24 hour time
    mm = t.format("04")

    seperator = render.Box(
        width = 4,
        height = 32,
        child = render.Image(src = SEP.readall()),
    )
    if not has_seperator:
        seperator = render.Box(
            width = 4,
            height = 15,
        )

    hh0 = get_num_image(int(hh[0]), NUMBER_IMGS)
    if int(hh[0]) == 0 and has_leading_zero == False:
        hh0 = render.Box(
            width = 15,
        )

    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            hh0,
            get_num_image(int(hh[1]), NUMBER_IMGS),
            seperator,
            get_num_image(int(mm[0]), NUMBER_IMGS),
            get_num_image(int(mm[1]), NUMBER_IMGS),
        ],
    )
