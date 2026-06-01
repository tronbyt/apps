load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")

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
TRANSITION_FRAMES, HOLD_FRAMES = 80, 40
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

def prepare_pages(input_text, config):
    words = input_text.upper().split(" ")
    lines, current_line = [], ""

    # Word wrapping
    for word in words:
        if not word:
            continue
        if len(word) > COLS:
            if current_line:
                lines.append(current_line)
            for i in range(0, len(word), COLS):
                lines.append(word[i:i + COLS])
            current_line = ""
            continue
        if len(current_line) + len(word) + (1 if current_line else 0) <= COLS:
            current_line = (current_line + " " if current_line else "") + word
        else:
            lines.append(current_line)
            current_line = word
    if current_line:
        lines.append(current_line)

    # Group into pages
    pages = []
    for i in range(0, min(len(lines), ROWS * 3), ROWS):
        p_lines = lines[i:i + ROWS]
        formatted = ""
        for j in range(ROWS):
            line = p_lines[j] if j < len(p_lines) else ""
            if config.bool("center_text"):
                line = center_text(line, COLS)
            line = (line + " " * COLS)[:COLS]

            # Color processing
            if config.bool("random_colors"):
                processed = ""
                for c in line.elems():
                    processed += COLOR_CHARS[random.number(0, 7)] if c == " " else c
                line = processed
            formatted += line
        pages.append(formatted)
    return pages

# --- Main Logic ---
def main(config):
    SCALE = 2 if canvas.is2x() else 1
    FLAP_W, FLAP_H = 9 * SCALE, 10 * SCALE
    pages = prepare_pages(config.get("message", "HELLO PIXEL BOARD"), config)

    speed_map = {"fast": 1, "slow": 4, "medium": 2}
    speed = speed_map.get(config.get("flip_speed", "medium"), 2)
    reveal_type = config.get("reveal_type", "random")

    # Pre-calculate all flap sequences
    flap_seqs = [[] for _ in range(COLS * ROWS)]
    for p_idx, page in enumerate(pages):
        prev_page = pages[p_idx - 1] if p_idx > 0 else None
        limit = (p_idx * CYCLE_FRAMES) + TRANSITION_FRAMES

        for i in range(COLS * ROWS):
            target_char = page[i]
            r, c = i // COLS, i % COLS

            # Find start index
            start_char = prev_page[i] if prev_page else None
            curr_idx = CHAR_SET.find(start_char) if start_char else random.number(0, len(CHAR_SET) - 1)
            if curr_idx == -1:
                curr_idx = 0

            # Initial Delay
            delay = 0
            if p_idx == 0:
                if reveal_type == "row":
                    delay = r * 10
                elif reveal_type == "wave":
                    delay = c * 5
                else:
                    delay = random.number(0, 20)
            else:
                delay = random.number(0, 10)

            for _ in range(delay):
                flap_seqs[i].append(CHAR_SET[curr_idx])

            # Shuffle
            target_idx = CHAR_SET.find(target_char)
            if target_idx == -1:
                target_idx = 0
            min_flips = 10 if p_idx == 0 else 5

            flips = 0
            for _ in range(200):
                curr_idx = (curr_idx + 1) % len(CHAR_SET)
                flips += 1
                for _ in range(speed):
                    if len(flap_seqs[i]) < limit:
                        flap_seqs[i].append(CHAR_SET[curr_idx])
                if curr_idx == target_idx and flips >= min_flips:
                    break
                if len(flap_seqs[i]) >= limit:
                    break

            # Fill to limit then Hold
            for _ in range(TRANSITION_FRAMES):
                if len(flap_seqs[i]) < limit:
                    flap_seqs[i].append(target_char)
            for _ in range(HOLD_FRAMES):
                flap_seqs[i].append(target_char)

    # Composite frames
    frames = []
    for f in range(len(pages) * CYCLE_FRAMES):
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
            schema.Text(id = "message", name = "Message", desc = "Text to display.", icon = "message", default = "HELLO PIXEL BOARD"),
            schema.Toggle(id = "random_colors", name = "Random Colors", desc = "Replace spaces with color flaps.", icon = "palette", default = False),
            schema.Toggle(id = "center_text", name = "Center Text", desc = "Center words on each line.", icon = "alignCenter", default = False),
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
