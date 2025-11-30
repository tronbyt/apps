"""
Applet: Qlock
Summary: Advanced clock
Description: Custom clock with time, binary, beats, and date; all with a custom font.
Author: craigerskine
"""

load("encoding/base64.star", "base64")
load("images/img_at.png", IMG_AT_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/img_0132286b.png", IMG_0132286b_ASSET = "file")
load("images/img_17ad0c23.png", IMG_17ad0c23_ASSET = "file")
load("images/img_1c2b41fa.png", IMG_1c2b41fa_ASSET = "file")
load("images/img_21b03914.png", IMG_21b03914_ASSET = "file")
load("images/img_44b72c8f.png", IMG_44b72c8f_ASSET = "file")
load("images/img_53c1c737.png", IMG_53c1c737_ASSET = "file")
load("images/img_58c1289c.png", IMG_58c1289c_ASSET = "file")
load("images/img_5d766eab.png", IMG_5d766eab_ASSET = "file")
load("images/img_709b45a4.png", IMG_709b45a4_ASSET = "file")
load("images/img_764ea92a.png", IMG_764ea92a_ASSET = "file")
load("images/img_ae32bbd7.png", IMG_ae32bbd7_ASSET = "file")
load("images/img_b65ee8af.png", IMG_b65ee8af_ASSET = "file")
load("images/img_b80c46a4.png", IMG_b80c46a4_ASSET = "file")
load("images/img_cd13b529.png", IMG_cd13b529_ASSET = "file")
load("images/img_d100a076.png", IMG_d100a076_ASSET = "file")
load("images/img_d1ca41ac.png", IMG_d1ca41ac_ASSET = "file")
load("images/img_d3697eee.png", IMG_d3697eee_ASSET = "file")
load("images/img_df32fb41.png", IMG_df32fb41_ASSET = "file")
load("images/img_e9950e65.png", IMG_e9950e65_ASSET = "file")
load("images/img_fcd88a12.png", IMG_fcd88a12_ASSET = "file")

IMG_AT = IMG_AT_ASSET.readall()

# contants
COLOR_LIGHT = "#FFF"
COLOR_MEDIUM = "#AAA"
COLOR_DARK = "#444"
COLOR_ACTIVE = "#60A5FA"

FONT_LG = {
    0: IMG_21b03914_ASSET.readall(),
    1: IMG_b65ee8af_ASSET.readall(),
    2: IMG_ae32bbd7_ASSET.readall(),
    3: IMG_d100a076_ASSET.readall(),
    4: IMG_44b72c8f_ASSET.readall(),
    5: IMG_764ea92a_ASSET.readall(),
    6: IMG_cd13b529_ASSET.readall(),
    7: IMG_d1ca41ac_ASSET.readall(),
    8: IMG_58c1289c_ASSET.readall(),
    9: IMG_1c2b41fa_ASSET.readall(),
}

FONT_SM = {
    0: IMG_d3697eee_ASSET.readall(),
    1: IMG_e9950e65_ASSET.readall(),
    2: IMG_fcd88a12_ASSET.readall(),
    3: IMG_709b45a4_ASSET.readall(),
    4: IMG_df32fb41_ASSET.readall(),
    5: IMG_5d766eab_ASSET.readall(),
    6: IMG_53c1c737_ASSET.readall(),
    7: IMG_b80c46a4_ASSET.readall(),
    8: IMG_17ad0c23_ASSET.readall(),
    9: IMG_0132286b_ASSET.readall(),
}

def zero_pad(number, width):
    return "0" * (width - len(str(number))) + str(number)

def to_binary(value, bits):
    lines = []
    for i in range(bits):
        color = COLOR_ACTIVE if value & (1 << (bits - 1 - i)) else COLOR_DARK
        lines.append(render.Box(width = 3, height = 1, color = color))
    return render.Column(children = lines)

def render_digits(value, width, font = FONT_SM, color = COLOR_MEDIUM, spacing = 1):
    padded_value = zero_pad(value, width)
    digits = [render_digit(padded_value[i], font, color) for i in range(width)]
    spaced_digits = []
    for i, digit in enumerate(digits):
        spaced_digits.append(digit)
        if i < len(digits) - 1:
            spaced_digits.append(render.Box(width = spacing, height = 1))
    return spaced_digits

def render_digit(digit, font, color):
    return render.Stack(children = [
        render.Box(width = 5 if font == FONT_LG else (2 if digit == "1" else 3), height = 10 if font == FONT_LG else 5, color = color),
        render.Image(src = base64.decode(font[int(digit)])),
    ])

def main(config):
    timezone = config.get("timezone") or "America/Chicago"
    now = time.now().in_location(timezone)
    bmt = time.now().in_location("Europe/Zurich")

    hours = now.hour % 12 or 12
    minutes = now.minute

    # seconds = now.second
    month = now.month
    day = now.day

    # beats
    seconds_since_midnight = (bmt.hour * 3600) + (bmt.minute * 60) + bmt.second
    beats = int((seconds_since_midnight / 86.4))
    beats = beats % 1000

    time_digits = (
        render_digits(hours, 2, FONT_LG, COLOR_LIGHT, spacing = 2) +
        [render.Box(width = 14, height = 1)] +
        render_digits(minutes, 2, FONT_LG, COLOR_LIGHT, spacing = 2)
        # rendering seconds is stupidly dificult
        # +
        # [render.Box(width = 10, height = 1)] +
        # render_digits(seconds, 2, FONT_LG, COLOR_LIGHT, spacing = 2)
    )

    beats_render = render_digits(beats, 3)

    date_digits = (
        render_digits(month, 2) +
        [render.Padding(pad = (1, 2, 1, 0), child = render.Box(width = 2, height = 1, color = COLOR_DARK))] +
        render_digits(day, 2)
    )

    return render.Root(
        delay = 864,
        max_age = 120,
        child = render.Column(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = [
                render.Row(children = time_digits),
                render.Row(
                    children = [
                        to_binary(hours // 10, 4),
                        render.Box(width = 4, height = 1),
                        to_binary(hours % 10, 4),
                        render.Box(width = 16, height = 1),
                        to_binary(minutes // 10, 4),
                        render.Box(width = 4, height = 1),
                        to_binary(minutes % 10, 4),
                        # rendering seconds is stupidly dificult
                        # render.Box(width = 12, height = 1),
                        # to_binary(seconds // 10, 4),
                        # render.Box(width = 4, height = 1),
                        # to_binary(seconds % 10, 4),
                    ],
                ),
                render.Padding(
                    pad = (12, 0, 12, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                        children = [
                            render.Row(children = date_digits),
                            render.Row(
                                children = [
                                    render.Stack(
                                        children = [
                                            render.Box(width = 5, height = 5, color = "#666"),
                                            render.Image(src = IMG_AT),
                                        ],
                                    ),
                                    render.Box(width = 2, height = 1),
                                    render.Row(children = beats_render),
                                ],
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        # fields = [
        #   schema.Toggle(
        #     id = 'show_date',
        #     name = 'Display Date',
        #     desc = '',
        #     icon = 'calendar',
        #     default = True,
        #   ),
        #   schema.Toggle(
        #     id = 'show_beats',
        #     name = 'Display Beats',
        #     desc = '',
        #     icon = 'clock',
        #     default = True,
        #   ),
        # ],
    )
