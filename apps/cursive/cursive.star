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
# Each letter is a FLAT list of [x, y] pixels
# Order matters — pixels are drawn in this exact sequence
# Use the recorder.html to recreate letters.
# Note, the dots in the box indicate the start and end points you should aim for.
# Also, starting point not an issue for Capital letters.
# ============================================================

SCREEN_WIDTH = canvas.width()
SCREEN_HEIGHT = canvas.height()

# ============================================================
# RENDER HELPERS
# ============================================================

def dot(x, y, color = "#fff000"):
    return render.Padding(
        pad = (int(x), int(y), 0, 0),
        child = render.Box(width = 1, height = 1, color = color),
    )

# ============================================================
# BUILD ANIMATION FRAMES WITH SCROLLING
# ============================================================

def build_frames(word, pen_color = "#fff000"):
    frames = []
    drawn = []

    cursor_x = 0  # absolute x-coordinate

    # Visible dots
    visible_dots = []

    for i in range(len(word)):
        ch = word[i]
        if ch not in CURSIVE_LETTERS:
            cursor_x += 2
            continue

        letter = CURSIVE_LETTERS[ch]

        # Draw pixels in order
        for pt in letter:
            x, y = pt
            px = cursor_x + x
            py = y

            drawn.append([px, py])

            # Scroll if needed
            shift = 0
            max_px = 0

            visible_dots = []
            for d in drawn:
                if d[0] > max_px:
                    max_px = d[0]
            if max_px >= SCREEN_WIDTH:
                shift = max_px - (SCREEN_WIDTH - 1)

            for d in drawn:
                vx = d[0] - shift
                vy = d[1]
                if vx >= 0 and vx < SCREEN_WIDTH and vy >= 0 and vy < SCREEN_HEIGHT:
                    visible_dots.append(dot(vx, vy, pen_color))

            frames.append(render.Stack(children = visible_dots))

        # Move cursor_x to the absolute x of the last point dra
        cursor_x = cursor_x + letter[-1][0] - 1

    # Hold final frame for visibility
    if frames:
        final_frame = frames[-1]
        for _ in range(40):
            frames.append(final_frame)

        frames.append(render.Stack(children = visible_dots))

    return frames

def main(config):
    return render.Root(
        delay = int(config.get("scroll", 45)),
        child = render.Animation(
            children = build_frames(config.get("displaytext", "What a Great App"), config.get("pen_color", "#fff000")),
        ),
        show_full_animation = True,
    )

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
