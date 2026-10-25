load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

# --- Constants ---
CHAR_SET = " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!?[]{}()<> "
COLOR_CHARS = "[]{}()<>"
COLOR_MAP = {
    "[": "#E53935",
    "]": "#FB8C00",
    "{": "#FDD835",
    "}": "#43A047",
    "(": "#1E88E5",
    ")": "#3949AB",
    "<": "#8E24AA",
    ">": "#FFFFFF",
}
COLS, ROWS = 7, 3
TRANSITION_FRAMES, HOLD_FRAMES = 150, 100  # Longer hold for clock, longer transition to prevent snapping
CYCLE_FRAMES = TRANSITION_FRAMES + HOLD_FRAMES

# --- UI Components ---
def render_flap(char, scale, width, height):
    font = "terminus-16" if scale == 2 else "tb-8"
    inner_w, inner_h = width - 2 * scale, height - 2 * scale
    color = COLOR_MAP.get(char)
    plate_color = color if color else "#222"

    stack_children = [render.Box(width = inner_w, height = inner_h)]
    if not color:
        stack_children.append(render.Box(child = render.Text(content = char, font = font, color = "#eee")))

    # Split line
    stack_children.append(
        render.Padding(
            pad = (0, inner_h // 2, 0, 0),
            child = render.Box(width = inner_w, height = 1, color = "#000"),
        ),
    )

    return render.Box(
        width = width,
        height = height,
        padding = 1 * scale,
        color = "#111",
        child = render.Box(width = inner_w, height = inner_h, color = plate_color, child = render.Stack(children = stack_children)),
    )

# --- Logic Helpers ---
def center_text(text, width):
    text = text.strip()
    if not text:
        return " " * width
    pad = width - len(text)
    if pad <= 0:
        return text[:width]
    left = pad // 2
    return (" " * left + text + " " * (pad - left))[:width]

def prepare_clock_message(config):
    now = time.now()
    t_str = now.format("15:04" if config.bool("24h") else "3:04")

    line1 = now.format("Jan 02").upper()
    line2 = t_str
    line3 = now.format("Monday").upper()
    if len(line3) > COLS:
        line3 = now.format("Mon").upper()

    message = ""
    for line in [line1, line2, line3]:
        line = center_text(line, COLS)
        if config.bool("random_colors"):
            processed = ""
            for c in line.elems():
                processed += COLOR_CHARS[random.number(0, 7)] if c == " " else c
            line = processed
        message += line
    return message

# --- Main Logic ---
def main(config):
    SCALE = 2 if canvas.is2x() else 1
    FLAP_W, FLAP_H = 9 * SCALE, 10 * SCALE
    target_message = prepare_clock_message(config)

    speed_map = {"fast": 1, "slow": 4, "medium": 2}
    speed = speed_map.get(config.get("flip_speed", "medium"), 2)
    reveal_type = config.get("reveal_type", "random")

    flap_seqs = [[] for _ in range(COLS * ROWS)]
    for i in range(COLS * ROWS):
        target_char = target_message[i]
        r, c = i // COLS, i % COLS

        # Start character: random for initial reveal
        curr_idx = random.number(0, len(CHAR_SET) - 1)

        # Initial Delay
        delay = 0
        if reveal_type == "row":
            delay = r * 10
        elif reveal_type == "wave":
            delay = c * 5
        else:
            delay = random.number(0, 20)

        for _ in range(delay):
            flap_seqs[i].append(CHAR_SET[curr_idx])

        # Shuffle
        target_idx = CHAR_SET.find(target_char)
        if target_idx == -1:
            target_idx = 0
        min_flips = 15  # More flips for clock look

        flips = 0
        for _ in range(300):
            curr_idx = (curr_idx + 1) % len(CHAR_SET)
            flips += 1
            for _ in range(speed):
                if len(flap_seqs[i]) < TRANSITION_FRAMES:
                    flap_seqs[i].append(CHAR_SET[curr_idx])
            if curr_idx == target_idx and flips >= min_flips:
                break
            if len(flap_seqs[i]) >= TRANSITION_FRAMES:
                break

        # Fill and Hold
        for _ in range(TRANSITION_FRAMES):
            if len(flap_seqs[i]) < TRANSITION_FRAMES:
                flap_seqs[i].append(target_char)
        for _ in range(HOLD_FRAMES):
            flap_seqs[i].append(target_char)

    # Composite
    frames = []
    for f in range(CYCLE_FRAMES):
        rows = []
        for r in range(ROWS):
            row_flaps = [render_flap(flap_seqs[r * COLS + c][f], SCALE, FLAP_W, FLAP_H) for c in range(COLS)]
            rows.append(render.Row(children = row_flaps))
        frames.append(render.Box(child = render.Column(children = rows)))

    return render.Root(child = render.Animation(children = frames))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(id = "random_colors", name = "Random Colors", desc = "Replace spaces with color flaps.", icon = "palette", default = False),
            schema.Toggle(id = "24h", name = "24h Format", desc = "Use 24-hour time.", icon = "clock", default = False),
            schema.Dropdown(
                id = "flip_speed",
                name = "Flip Speed",
                desc = "Mechanical speed.",
                icon = "gauge",
                default = "medium",
                options = [schema.Option(display = "Fast", value = "fast"), schema.Option(display = "Medium", value = "medium"), schema.Option(display = "Slow", value = "slow")],
            ),
            schema.Dropdown(
                id = "reveal_type",
                name = "Reveal Style",
                desc = "Transition pattern.",
                icon = "stairs",
                default = "random",
                options = [schema.Option(display = "Random", value = "random"), schema.Option(display = "Row by Row", value = "row"), schema.Option(display = "Left-to-Right Wave", value = "wave")],
            ),
        ],
    )
