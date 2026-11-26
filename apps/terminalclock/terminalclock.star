"""
Applet: Terminal Clock
Summary: A shell that types "date"
Description: A cursor blinks behind a shell prompt, then the command "date"
             is typed letter by letter and the terminal prints the current
             date and time the way GNU date does. The terminal wraps lines
             like a real one; the date output is split into date, time and
             year so that it fits the panel.
Author: Sonic-79
"""

load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TZ = "Europe/Berlin"
DEFAULT_PROMPT = "root@tb~>"
DEFAULT_LEAD = "15"
MAX_PROMPT = 40

COMMAND = "date"

# GNU date in the C locale ("Mon Jan _2 15:04:05 MST 2006"), broken into
# date / time and zone / year so that no line is wider than 16 characters
DATE_LAYOUTS = ["Mon Jan _2", "15:04:05 MST", "2006"]

TICK_MS = 100
BLINK_TICKS = 5  # cursor on 500 ms, off 500 ms
START_BLINKS = 15  # cursor blinks behind the empty prompt first
KEY_DELAYS = [3, 2, 3, 2]  # ticks before each typed letter of COMMAND
ENTER_DELAY = 5  # pause before Enter
TOTAL_TICKS = 150  # 15 s

# Character cell per panel type. 1x: tom-thumb (3x5 glyphs, 4 px advance)
# gives 16 columns; 2x: 6x10 gives 21 columns. "cursor" is the row of the
# underscore cursor inside the cell.
GEOMETRY_1X = {"font": "tom-thumb", "w": 4, "h": 6, "top": 1, "left": 0, "cursor": 5, "cursor_w": 3}
GEOMETRY_2X = {"font": "6x10", "w": 6, "h": 10, "top": 2, "left": 1, "cursor": 9, "cursor_w": 5}

# tom-thumb draws "@" like an "e" with a dot; this one is 4 px wide and
# reads as "@" on the panel. Rows start at the cap height of the font.
CUSTOM_GLYPHS_1X = {
    "@": [".##.", "#..#", "#.##", "#...", ".##."],
}

# scheme -> (prompt colour, text colour)
SCHEMES = {
    "green": ("#33ff33", "#33ff33"),
    "amber": ("#ffb000", "#ffb000"),
    "white": ("#ffffff", "#ffffff"),
    "bash": ("#ff4040", "#c0c0c0"),
}

def layout(segments, cols, rows):
    """Wraps (text, colour) segments into terminal lines like a real
    terminal does: hard wrap after `cols` characters, newline starts a new
    line. Returns the last `rows` lines and the cursor position."""
    lines = [[]]
    for text, color in segments:
        for ch in text.codepoints():
            if ch == "\n":
                lines.append([])
                continue
            if len(lines[-1]) == cols:
                lines.append([])
            lines[-1].append((ch, color))

    # the cursor sits behind the last character; a full line wraps it
    if len(lines[-1]) == cols:
        lines.append([])
    cursor = (len(lines) - 1, len(lines[-1]))

    first = max(0, len(lines) - rows)
    return lines[first:], (cursor[0] - first, cursor[1])

def custom_glyph(rows, x, y, color):
    pixels = []
    for dy, row in enumerate(rows):
        for dx, px in enumerate(row.codepoints()):
            if px == "#":
                pixels.append(render.Padding(
                    pad = (x + dx, y + dy, 0, 0),
                    child = render.Box(width = 1, height = 1, color = color),
                ))
    return pixels

def screen(segments, cursor_on, cursor_color, geo, custom):
    width, height = canvas.size()
    cols = (width - geo["left"]) // geo["w"]
    rows = (height - geo["top"]) // geo["h"]
    lines, cursor = layout(segments, cols, rows)

    def x_of(c):
        return geo["left"] + c * geo["w"]

    def y_of(r):
        return geo["top"] + r * geo["h"]

    # full-size first child, so the Stack is never centred by the Box
    children = [render.Box(width = width, height = height)]
    for r, line in enumerate(lines):
        for c, cell in enumerate(line):
            ch, color = cell
            if ch == " ":
                continue
            if ch in custom:
                children.extend(custom_glyph(custom[ch], x_of(c), y_of(r) + 1, color))
                continue
            children.append(render.Padding(
                pad = (x_of(c), y_of(r), 0, 0),
                child = render.Text(content = ch, color = color, font = geo["font"]),
            ))
    if cursor_on:
        children.append(render.Padding(
            pad = (x_of(cursor[1]), y_of(cursor[0]) + geo["cursor"], 0, 0),
            child = render.Box(width = geo["cursor_w"], height = 1, color = cursor_color),
        ))
    return render.Box(color = "#000000", child = render.Stack(children = children))

def blink(tick):
    return (tick // BLINK_TICKS) % 2 == 0

def parse_lead(value):
    value = (value or "").strip()
    if value == "" or not value.isdigit():
        return int(DEFAULT_LEAD)
    return min(int(value), 120)

def main(config):
    tz = config.get("timezone") or config.get("$tz") or DEFAULT_TZ
    prompt_color, text_color = SCHEMES.get(config.get("scheme", "green"), SCHEMES["green"])
    prompt = (config.get("prompt") or DEFAULT_PROMPT)[:MAX_PROMPT]

    if canvas.is2x():
        geo, custom = GEOMETRY_2X, {}
    else:
        geo, custom = GEOMETRY_1X, CUSTOM_GLYPHS_1X

    # Devices fetch the next image while the current app is still on
    # screen, so this one is rendered roughly one display time early.
    lead_s = parse_lead(config.get("lead", DEFAULT_LEAD))

    # tick at which Enter is pressed
    enter_tick = START_BLINKS
    for d in KEY_DELAYS:
        enter_tick += d
    enter_tick += ENTER_DELAY

    shown = time.now().in_location(tz) + time.parse_duration(
        "%dms" % (lead_s * 1000 + enter_tick * TICK_MS),
    )
    output = "\n".join([shown.format(l) for l in DATE_LAYOUTS])

    def frame(segments, cursor_on):
        return screen(segments, cursor_on, text_color, geo, custom)

    frames = []

    # 1. empty prompt, blinking cursor
    for t in range(START_BLINKS):
        frames.append(frame([(prompt, prompt_color)], blink(t)))

    # 2. type the command; the cursor stays on while typing
    typed = ""
    for i, d in enumerate(KEY_DELAYS):
        for _ in range(d):
            frames.append(frame([(prompt, prompt_color), (typed, text_color)], True))
        typed += COMMAND[i]
    for _ in range(ENTER_DELAY):
        frames.append(frame([(prompt, prompt_color), (typed, text_color)], True))

    # 3. Enter: output plus a fresh prompt, cursor blinks until the end
    done = [
        (prompt, prompt_color),
        (typed + "\n" + output + "\n", text_color),
        (prompt, prompt_color),
    ]
    t = 0
    for _ in range(TOTAL_TICKS - len(frames)):
        frames.append(frame(done, blink(t)))
        t += 1

    return render.Root(
        delay = TICK_MS,
        show_full_animation = True,
        child = render.Animation(children = frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "scheme",
                name = "Colors",
                desc = "Color scheme of the terminal.",
                icon = "terminal",
                default = "green",
                options = [
                    schema.Option(display = "Green phosphor", value = "green"),
                    schema.Option(display = "Amber", value = "amber"),
                    schema.Option(display = "White", value = "white"),
                    schema.Option(display = "Bash (red prompt)", value = "bash"),
                ],
            ),
            schema.Text(
                id = "prompt",
                name = "Prompt",
                desc = "Shell prompt in front of the command. Long prompts wrap like in a real terminal.",
                icon = "dollarSign",
                default = DEFAULT_PROMPT,
            ),
            schema.Text(
                id = "lead",
                name = "Lead time (seconds)",
                desc = "How long before it is shown the image is rendered; added to the displayed time. Usually the display time of the previous app.",
                icon = "clock",
                default = DEFAULT_LEAD,
            ),
        ],
    )
