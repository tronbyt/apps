"""
Applet: Nixel Clock
Summary: Pixel Nixie Clock
Description: It's a Nixie Clock made from Pixels!
Author: saltedlolly
Thanks: Joey Hoer, whose "Big Number Clock" code this is based on.
Notes: Numbers are 15 pixels wide. Seperator is 4 pixels wide. This is the widest you can effectively make a digital clock to fill all 64 pixels while maintaining numbers of equal width with space for a seperator.
On 2x displays everything is twice the size, using 2x artwork made from the original source images. On square displays the clock is centred.
"""

load("images/images.star", "IMAGE_SETS")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TIMEZONE = "Europe/London"
DEFAULT_IS_24_HOUR_FORMAT = False
DEFAULT_HAS_LEADING_ZERO = True
DEFAULT_HAS_FLASHING_SEPERATOR = False
DEFAULT_HAS_GLOW = True
DEFAULT_CLOCK_STYLE = "round_brighter"

SCALE = 2 if canvas.is2x() else 1
DIGIT_WIDTH = 15 * SCALE
SEP_WIDTH = 4 * SCALE
CLOCK_HEIGHT = 32 * SCALE

# The glow animation loops every GLOW_FRAMES * FRAME_DELAY milliseconds. The
# blinking colon is on for two frames and off for two, so GLOW_FRAMES must be
# a multiple of 4 or the blink stutters where the loop restarts.
FRAME_DELAY = 250
GLOW_FRAMES = 16

# How much each tube dims at its darkest, as an alpha value (0-255) of a black
# overlay. Black stays black, so only the lit parts of the tubes change.
GLOW_MAX_DIM = 20

# The dimming moves in steps of this size. A tube only changes on the frames
# where it crosses a step, which keeps the animation small enough to send.
GLOW_STEP = 4

# Each tube (four digits and the separator) gets its own slow waves so they
# never pulse together. The cycle counts divide GLOW_FRAMES, so the loop is
# seamless: (cycles per loop, phase) for two waves.
GLOW_WAVES = [
    [(1, 0.00), (2, 0.40)],
    [(1, 0.55), (2, 0.10)],
    [(1, 0.30), (2, 0.75)],
    [(1, 0.85), (2, 0.20)],
    [(1, 0.65), (2, 0.50)],
]

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
                name = "Blinking colon",
                icon = "gear",
                desc = "Blink the colon once a second.",
                default = DEFAULT_HAS_FLASHING_SEPERATOR,
            ),
            schema.Toggle(
                id = "has_glow",
                name = "Glow",
                icon = "lightbulb",
                desc = "Gently vary the brightness of each tube, as if lit.",
                default = DEFAULT_HAS_GLOW,
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
    has_glow = config.bool("has_glow", DEFAULT_HAS_GLOW)
    clock_style = config.get("clock_style", DEFAULT_CLOCK_STYLE)
    if clock_style not in IMAGE_SETS:
        clock_style = DEFAULT_CLOCK_STYLE

    # Set image variables for current Clock Style
    if SCALE == 2:
        clock_style = clock_style + "_2x"
    image_set = IMAGE_SETS[clock_style]
    SEP = image_set["sep"].readall()
    NUMBER_IMGS = [img.readall() for img in image_set["digits"]]

    # Without the glow, the flashing separator needs two frames (on and off,
    # 500ms each) and a steady clock needs one. With the glow, every frame
    # differs, and the separator flashes every second frame.
    number_of_frames = 1
    if has_glow:
        number_of_frames = GLOW_FRAMES
    elif has_flashing_seperator:
        number_of_frames = 2

    frames = []
    for frame in range(number_of_frames):
        has_seperator = True
        if has_flashing_seperator:
            if has_glow:
                has_seperator = (frame * FRAME_DELAY // 500) % 2 == 0
            else:
                has_seperator = frame == 0
        dims = [0, 0, 0, 0, 0]
        if has_glow:
            dims = [get_glow_dim(waves, frame) for waves in GLOW_WAVES]
        frames.append(get_time_image(current_time, NUMBER_IMGS, SEP, dims, is_24_hour_format = is_24_hour_format, has_leading_zero = has_leading_zero, has_seperator = has_seperator))

    # The clock is 64x32 (128x64 on 2x displays). Centre it on taller displays.
    width, height = canvas.size()
    return render.Root(
        delay = FRAME_DELAY if has_glow else 500,  # in milliseconds
        max_age = 120,
        child = render.Box(
            width = width,
            height = height,
            child = render.Animation(
                children = frames,
            ),
        ),
    )

def get_glow_dim(waves, frame):
    # Two sine waves mixed to an irregular, slow pulse between 0 and 1.
    level = 0.0
    for cycles, phase in waves:
        level += math.sin(2 * math.pi * (cycles * frame / GLOW_FRAMES + phase))
    level = (level / len(waves) + 1) / 2
    return int(level * GLOW_MAX_DIM / GLOW_STEP + 0.5) * GLOW_STEP

def dim(widget, width, height, amount):
    if amount <= 0:
        return widget
    return render.Stack(
        children = [
            widget,
            render.Box(
                width = width,
                height = height,
                color = "#000000" + "0123456789abcdef"[amount // 16] + "0123456789abcdef"[amount % 16],
            ),
        ],
    )

# It would be easier to use a custom font, but we can use images instead.
# The images have a black background and transparent foreground. This
# allows us to change the color dynamically.
def get_num_image(num, NUMBER_IMGS, amount):
    return dim(
        render.Box(
            width = DIGIT_WIDTH,
            height = CLOCK_HEIGHT,
            child = render.Image(src = NUMBER_IMGS[int(num)]),
        ),
        DIGIT_WIDTH,
        CLOCK_HEIGHT,
        amount,
    )

def get_time_image(t, NUMBER_IMGS, SEP, dims, is_24_hour_format = True, has_leading_zero = False, has_seperator = True):
    hh = t.format("03")  # Formet for 12 hour time
    if is_24_hour_format == True:
        hh = t.format("15")  # Format for 24 hour time
    mm = t.format("04")

    seperator = dim(
        render.Box(
            width = SEP_WIDTH,
            height = CLOCK_HEIGHT,
            child = render.Image(src = SEP),
        ),
        SEP_WIDTH,
        CLOCK_HEIGHT,
        dims[4],
    )
    if not has_seperator:
        seperator = render.Box(
            width = SEP_WIDTH,
            height = CLOCK_HEIGHT,
        )

    hh0 = get_num_image(int(hh[0]), NUMBER_IMGS, dims[0])
    if int(hh[0]) == 0 and has_leading_zero == False:
        hh0 = render.Box(
            width = DIGIT_WIDTH,
            height = CLOCK_HEIGHT,
        )

    return render.Row(
        cross_align = "center",
        children = [
            hh0,
            get_num_image(int(hh[1]), NUMBER_IMGS, dims[1]),
            seperator,
            get_num_image(int(mm[0]), NUMBER_IMGS, dims[2]),
            get_num_image(int(mm[1]), NUMBER_IMGS, dims[3]),
        ],
    )
