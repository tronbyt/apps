"""
Applet: Big Clock
Summary: Display a large retro-style clock
Description: Display a large retro-style clock; the clock can change color
  at night based on sunrise and sunset times for a given location, supports
  24-hour and 12-hour variants and optionally flashes the separator.
Author: Joey Hoer
"""

load("encoding/json.star", "json")
load("images/number_0.png", NUMBER_0_ASSET = "file")
load("images/number_1.png", NUMBER_1_ASSET = "file")
load("images/number_2.png", NUMBER_2_ASSET = "file")
load("images/number_3.png", NUMBER_3_ASSET = "file")
load("images/number_4.png", NUMBER_4_ASSET = "file")
load("images/number_5.png", NUMBER_5_ASSET = "file")
load("images/number_6.png", NUMBER_6_ASSET = "file")
load("images/number_7.png", NUMBER_7_ASSET = "file")
load("images/number_8.png", NUMBER_8_ASSET = "file")
load("images/number_9.png", NUMBER_9_ASSET = "file")
load("images/sep.png", SEP_ASSET = "file")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("sunrise.star", "sunrise")
load("time.star", "time")

SEP = SEP_ASSET.readall()

# Default configuration values
DEFAULT_LOCATION = {
    "lat": 37.541290,
    "lng": -77.434769,
    "locality": "Richmond, VA",
}
DEFAULT_TIMEZONE = "US/Eastern"
DEFAULT_IS_24_HOUR_FORMAT = True
DEFAULT_HAS_LEADING_ZERO = False
DEFAULT_HAS_FLASHING_SEPERATOR = True
DEFAULT_COLOR_DAYTIME = "#FFFFFF"
DEFAULT_COLOR_NIGHTTIME = "#FFFFFF"
DEFAULT_SUNRISE_ELEVATION = "-1"  # -1 appears to be the default elevation for sunrise/sunset

# Constants
TTL = 21600  # 6 hours
NUMBER_IMGS = [
    NUMBER_0_ASSET.readall(),
    NUMBER_1_ASSET.readall(),
    NUMBER_2_ASSET.readall(),
    NUMBER_3_ASSET.readall(),
    NUMBER_4_ASSET.readall(),
    NUMBER_5_ASSET.readall(),
    NUMBER_6_ASSET.readall(),
    NUMBER_7_ASSET.readall(),
    NUMBER_8_ASSET.readall(),
    NUMBER_9_ASSET.readall(),
]

# Convert hex color to RGB tuple
def hex_to_rgb(color):
    # Expand 4 digit hex to 7 digit hex
    if len(color) == 4:
        x = "([A-Fa-f0-9])"
        matches = re.match("#%s%s%s" % (x, x, x), color)
        rgb_hex_list = list(matches[0])
        rgb_hex_list.pop(0)
        for i in range(len(rgb_hex_list)):
            rgb_hex_list[i] = rgb_hex_list[i] + rgb_hex_list[i]
        color = "#" + "".join(rgb_hex_list)

    # Split hex into RGB
    x = "([A-Fa-f0-9]{2})"
    matches = re.match("#%s%s%s" % (x, x, x), color)
    rgb_hex_list = list(matches[0])
    rgb_hex_list.pop(0)
    for i in range(len(rgb_hex_list)):
        rgb_hex_list[i] = int(rgb_hex_list[i], 16)
    rgb = tuple(rgb_hex_list)

    return rgb

# Convert RGB tuple to hex color
def rgb_to_hex(r, g, b):
    return "#" + str("%x" % ((1 << 24) + (r << 16) + (g << 8) + b))[1:]

# Mixes two colors by a given percentage.
#
# Args:
# color1 (tuple): RGB representation of the first color as a tuple of three integers (0-255).
# color2 (tuple): RGB representation of the second color as a tuple of three integers (0-255).
# percentage (float): Percentage of the first color in the mix (0.0 - 1.0).
#
# Returns:
# tuple: RGB representation of the mixed color as a tuple of three integers (0-255).
def mix_colors(color1, color2, percentage):
    r1, g1, b1 = hex_to_rgb(color1)
    r2, g2, b2 = hex_to_rgb(color2)

    # Calculate the mixed color components
    r = int(r1 * percentage + r2 * (1 - percentage))
    g = int(g1 * percentage + g2 * (1 - percentage))
    b = int(b1 * percentage + b2 * (1 - percentage))

    return rgb_to_hex(r, g, b)

# Calculate the proportion of x within the range defined by min_value and max_value,
# clamping the value between 0 and 1.
#
# Args:
# min_value: The minimum value of the range.
# max_value: The maximum value of the range.
# x: The value to calculate the proportion for.
#
# Returns:
# The proportion of x within the range, between 0 and 1.
def proportion_within_range(min_value, max_value, x):
    # Check if min_value and max_value are the same to avoid division by zero
    if min_value == max_value:
        return float(x >= min_value)

    # Calculate the proportion position of x within the range
    proportion = (x - min_value) / (max_value - min_value)

    # Clamp the result to be within 0 and 1
    return max(0, min(1, proportion))

# It would be easier to use a custom font, but we can use images instead.
# The images have a black background and transparent foreground. This
# allows us to change the color dynamically.
def get_num_image(num, color):
    return render.Box(
        width = 13,
        height = 32,
        color = color,
        child = render.Image(src = NUMBER_IMGS[int(num)]),
    )

def get_time_image(t, color, is_24_hour_format = True, has_leading_zero = False, has_seperator = True):
    hh = t.format("03")  # Format for 12 hour time
    if is_24_hour_format == True:
        hh = t.format("15")  # Format for 24 hour time
    mm = t.format("04")  # Format for minutes
    # ss = t.format("05")  # Format for seconds

    seperator = render.Box(
        width = 4,
        height = 14,
        color = color,
        child = render.Image(src = SEP),
    )
    if not has_seperator:
        seperator = render.Box(
            width = 4,
        )

    hh0 = get_num_image(int(hh[0]), color)
    if int(hh[0]) == 0 and has_leading_zero == False:
        hh0 = render.Box(
            width = 13,
        )

    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            hh0,
            get_num_image(int(hh[1]), color),
            seperator,
            get_num_image(int(mm[0]), color),
            get_num_image(int(mm[1]), color),
        ],
    )

def main(config):
    # Get the current time in 24 hour format
    location = config.get("location")
    loc = json.decode(location) if location else DEFAULT_LOCATION
    timezone = loc.get("timezone", time.tz())  # Utilize special timezone variable
    now = time.now()

    # Fetch latitude and longitude
    lat, lng = float(loc.get("lat")), float(loc.get("lng"))

    # Because the times returned by this API do not include the date, we need to
    # strip the date from "now" to get the current time in order to perform
    # acurate comparissons.
    # Local time must be localized with a timezone
    current_time = time.parse_time(now.in_location(timezone).format("3:04:05 PM"), format = "3:04:05 PM", location = timezone)
    day_end = time.parse_time("11:59:59 PM", format = "3:04:05 PM", location = timezone)

    # Get config values
    is_24_hour_format = config.bool("is_24_hour_format", DEFAULT_IS_24_HOUR_FORMAT)
    has_leading_zero = config.bool("has_leading_zero", DEFAULT_HAS_LEADING_ZERO)
    has_flashing_seperator = config.bool("has_flashing_seperator", DEFAULT_HAS_FLASHING_SEPERATOR)
    min_fade_elevation = int(config.get("min_fade_elevation", DEFAULT_SUNRISE_ELEVATION))

    # Set daytime color
    color_daytime = config.get("color_daytime", DEFAULT_COLOR_DAYTIME)

    # Set nighttime color
    color_nighttime = config.get("color_nighttime", DEFAULT_COLOR_NIGHTTIME)

    frames = []
    print_time = current_time

    # The API limit is ≈256kb (as reported by error messages).
    # However, sending a 256kb file doesn't seem to work.
    # Increase the duration to create an image containing multiple minutes
    # of frames to smooth out potential network issues.
    # Currently this does not work, becasue app rotation prevents the animation
    # from progressing past a few seconds.
    duration = 1  # in minutes; 1440 = 24 hours
    for _ in range(0, duration):
        color = mix_colors(color_daytime, color_nighttime, proportion_within_range(min_fade_elevation, int(DEFAULT_SUNRISE_ELEVATION), sunrise.elevation(lat, lng, now)))

        frames.append(get_time_image(print_time, color, is_24_hour_format = is_24_hour_format, has_leading_zero = has_leading_zero, has_seperator = True))

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
                frames.append(get_time_image(print_time, color, is_24_hour_format = is_24_hour_format, has_leading_zero = has_leading_zero, has_seperator = has_seperator))
        print_time = print_time + time.minute

        # If time is tomorrow, reset to today
        # This simplifies sunset/sunrise calculations
        if print_time > day_end:
            print_time = print_time - (time.hour * 24)

    return render.Root(
        delay = 500,  # in milliseconds
        max_age = 120,
        child = render.Box(
            child = render.Animation(
                children = frames,
            ),
        ),
    )

def get_schema():
    fade_options = [
        schema.Option(
            display = "None",
            value = DEFAULT_SUNRISE_ELEVATION,
        ),
        schema.Option(
            display = "Civil twilight",
            value = "-6",
        ),
        schema.Option(
            display = "Nautical twilight",
            value = "-12",
        ),
        schema.Option(
            display = "Astronomical twilight",
            value = "-18",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location defining time to display and daytime/nighttime colors",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "is_24_hour_format",
                name = "24 hour format",
                icon = "clock",
                desc = "Display the time in 24 hour format.",
                default = DEFAULT_IS_24_HOUR_FORMAT,
            ),
            schema.Toggle(
                id = "has_leading_zero",
                name = "Add leading zero",
                icon = "creativeCommonsZero",
                desc = "Ensure the clock always displays with a leading zero.",
                default = DEFAULT_HAS_LEADING_ZERO,
            ),
            schema.Toggle(
                id = "has_flashing_seperator",
                name = "Enable flashing separator",
                icon = "gear",
                desc = "Ensure the clock always displays with a leading zero.",
                default = DEFAULT_HAS_FLASHING_SEPERATOR,
            ),
            schema.Color(
                id = "color_daytime",
                icon = "sun",
                name = "Daytime color",
                desc = "The color to use during daytime.",
                default = DEFAULT_COLOR_DAYTIME,
                palette = [
                    "#FFFFFF",
                ],
            ),
            schema.Color(
                id = "color_nighttime",
                icon = "moon",
                name = "Nighttime color",
                desc = "The color to use during nighttime.",
                default = DEFAULT_COLOR_NIGHTTIME,
                palette = [
                    "#220000",
                ],
            ),
            schema.Dropdown(
                id = "min_fade_elevation",
                name = "Fade During",
                desc = "The time during which the nighttime and daytime colors will be mixed based on the sun's elevation.",
                icon = "circleHalfStroke",
                default = fade_options[0].value,
                options = fade_options,
            ),
        ],
    )
