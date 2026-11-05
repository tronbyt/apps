"""
Applet: Cursive
Summary: Display text in cursive handwriting
Description: Displays user-defined text in cursive handwriting style.
Author: Robert Ison
"""

load("cursive_letters.star", "CURSIVE_LETTERS")
load("render.star", "canvas", "render")
load("schema.star", "schema")

# ============================================================
# CURSIVE LETTER DATA
# Each letter is a FLAT list of [x, y] pixels.
# Order matters — pixels are drawn in this exact sequence.
# Use recorder.html to recreate letters.
# The dots in the box indicate the intended start/end points.
# Starting point is not an issue for capital letters.
# ============================================================

SCREEN_WIDTH = canvas.width()
SCREEN_HEIGHT = canvas.height()

FINAL_HOLD_FRAMES = 40
UNSUPPORTED_CHARACTER_SPACING = 2

# ============================================================
# RENDER HELPERS
# ============================================================

def dot(x, y, color = "#fff000"):
    return render.Padding(
        pad = (int(x), int(y), 0, 0),
        child = render.Box(
            width = 1,
            height = 1,
            color = color,
        ),
    )

# ============================================================
# BUILD ANIMATION FRAMES WITH SCROLLING
# ============================================================

def build_frames(word, pen_color = "#fff000"):
    frames = []
    drawn = []

    cursor_x = 0
    max_px = 0
    shift = 0

    for i in range(len(word)):
        ch = word[i]
        letter = CURSIVE_LETTERS.get(ch)

        # Treat unsupported characters and empty definitions
        # as spacing.
        if not letter:
            cursor_x += UNSUPPORTED_CHARACTER_SPACING
            continue

        # Draw pixels in their recorded order.
        for pt in letter:
            x, y = pt
            px = cursor_x + x
            py = y

            # Track the rightmost position without rescanning
            # the complete drawing history.
            max_px = max(max_px, px)
            new_shift = max(0, max_px - (SCREEN_WIDTH - 1))

            # Once a point scrolls off the left edge, it can
            # never become visible again.
            if new_shift > shift:
                retained = []

                for d in drawn:
                    if d[0] >= new_shift:
                        retained.append(d)

                drawn = retained
                shift = new_shift

            # Keep only points that can appear onscreen.
            if (
                px >= shift and
                py >= 0 and
                py < SCREEN_HEIGHT
            ):
                drawn.append([px, py])

            visible_dots = []

            for d in drawn:
                vx = d[0] - shift

                if vx >= 0 and vx < SCREEN_WIDTH:
                    visible_dots.append(
                        dot(vx, d[1], pen_color),
                    )

            frames.append(
                render.Stack(children = visible_dots),
            )

        # Preserve the tested letter-connection behavior.
        cursor_x = cursor_x + letter[-1][0] - 1

    # Ensure the animation always contains at least one frame.
    if not frames:
        return [render.Stack(children = [])]

    # Hold the completed drawing for visibility.
    final_frame = frames[-1]

    for _ in range(FINAL_HOLD_FRAMES):
        frames.append(final_frame)

    return frames

# ============================================================
# APPLET ENTRY POINT
# ============================================================

def main(config):
    return render.Root(
        delay = int(config.get("scroll", 45)),
        child = render.Animation(
            children = build_frames(
                config.get("displaytext", "What a Great App"),
                config.get("pen_color", "#fff000"),
            ),
        ),
        show_full_animation = True,
    )

# ============================================================
# CONFIGURATION SCHEMA
# ============================================================

def get_schema():
    scroll_speed_options = [
        schema.Option(
            display = "Slow Scroll",
            value = "60",
        ),
        schema.Option(
            display = "Medium Scroll",
            value = "45",
        ),
        schema.Option(
            display = "Fast Scroll",
            value = "30",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "displaytext",
                name = "Display Text",
                desc = "What text to display in cursive.",
                default = "What a Great App",
                icon = "envelopeOpenText",
            ),
            schema.Color(
                id = "pen_color",
                name = "Color",
                desc = "Pen color for drawing the text.",
                icon = "brush",
                default = "#fff000",
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll Speed",
                desc = "Speed of scrolling text.",
                icon = "clock",
                options = scroll_speed_options,
                default = "45",
            ),
        ],
    )
