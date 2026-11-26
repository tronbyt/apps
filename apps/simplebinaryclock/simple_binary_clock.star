"""
Applet: Simple Binary Clock
Summary: Time as rows of binary dots
Description: Shows the time as three rows of dots: hours on top, then minutes, then seconds. Each row is a binary number with the most significant bit on the left.
Author: bertrandom
"""

load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

ON_COLOR = "#ff0000"
OFF_COLOR = "#333"
BITS = 6
FRAMES = 60

def dot_size():
    width, height = canvas.size()
    if width == height:
        # Square (64x64) panel: a bit larger than 64x32, but kept small enough
        # to leave space between the dots.
        return 6
    if canvas.is2x():
        return 10
    return 5

def bit_row(n, size, blank = 0):
    # Most significant bit on the left. The leftmost `blank` positions are
    # left empty (same size as a dot) so columns stay aligned across rows.
    children = []
    for i in range(BITS):
        if i < blank:
            children.append(render.Box(width = size, height = size))
        else:
            children.append(render.Circle(
                color = ON_COLOR if (n >> (BITS - 1 - i)) & 1 else OFF_COLOR,
                diameter = size,
            ))
    return render.Row(
        expanded = True,
        main_align = "space_evenly",
        children = children,
    )

def hour_12(h):
    h = h % 12
    return 12 if h == 0 else h

def hour_row(h, size, use_24h, show_unused):
    # Unused high bits are always 0, so drawing them just shows unlit dots.
    if use_24h:
        # 0-23 needs 5 bits.
        return bit_row(h, size, blank = 0 if show_unused else 1)

    # 1-12 needs 4 bits.
    return bit_row(hour_12(h), size, blank = 0 if show_unused else 2)

def frame(t, size, use_24h, show_unused):
    return render.Column(
        expanded = True,
        main_align = "space_evenly",
        children = [
            hour_row(t.hour, size, use_24h, show_unused),
            bit_row(t.minute, size),
            bit_row(t.second, size),
        ],
    )

def main(config):
    # Tronbyt passes the display's time zone as "$tz".
    timezone = config.get("timezone") or config.get("$tz") or time.tz()
    use_24h = config.bool("use_24h", False)
    show_unused = config.bool("show_unused_hour_dots", True)
    size = dot_size()

    # Tronbyt renders an app's image while the previous image is still on
    # screen, so the first frame appears roughly one display time after it was
    # rendered. Shift the clock forward to compensate.
    offset = parse_offset(config.get("offset_secs"))
    start = time.now().in_location(timezone) + time.second * offset

    return render.Root(
        delay = 1000,
        show_full_animation = True,
        child = render.Animation(
            children = [frame(start + time.second * i, size, use_24h, show_unused) for i in range(FRAMES)],
        ),
    )

def parse_offset(value):
    if not value:
        return 0
    value = value.strip()
    digits = value[1:] if value.startswith("-") else value
    if not digits.isdigit():
        return 0
    return int(value)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "use_24h",
                name = "24-hour clock",
                desc = "Show hours as 0-23 instead of 1-12.",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = "show_unused_hour_dots",
                name = "Show unused hour dots",
                desc = "Draw unlit dots in the hour row's leftmost positions, which are never used.",
                icon = "circle",
                default = True,
            ),
            schema.Text(
                id = "offset_secs",
                name = "Display lag (seconds)",
                desc = "Your display gets each image while the one before it is still showing, so the clock can run behind by that long. Enter how many seconds to shift it forward. If this app is pinned, use its display time (e.g. 60). Leave at 0 if the time looks right.",
                icon = "stopwatch",
                default = "0",
            ),
        ],
    )
