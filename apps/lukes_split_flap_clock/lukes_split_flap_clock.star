"""
Applet: Luke's Split Flap Clock
Summary: Split flap clock that holds
Description: A mechanical split flap board that flips once and then holds
still — no re-flipping mid-rotation. Clock layouts or a custom message,
six themes, color cards, and four reveal patterns.
Author: nsluke

The no-re-flip trick: the frame budget (35s) is sized past any normal app
dwell, and the server truncates the encoded animation to the dwell, so each
rotation slot plays exactly one flip sequence followed by a hold.

Forked from split_flap_clock by Brombomb, rebuilt: two-tone plates,
flap-flash motion frames, natural drum landing (no snap), themes, layouts,
message-board mode, and a colon that's actually on the drum.
"""

load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

# --- Drum ---
DRUM = " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:.-!?&[]{}()<>"
COLOR_CHARS = "[]{}()<>"
COLOR_MAP = {
    "[": "#B3423A",  # red
    "]": "#C1731F",  # orange
    "{": "#C9A227",  # yellow
    "}": "#3E8E4B",  # green
    "(": "#2F6FB3",  # blue
    ")": "#5A55B0",  # indigo
    "<": "#8A4DA6",  # purple
    ">": "#C9C9C9",  # white
}

THEMES = {
    "amber": {"text": "#FFB000", "top": "#2A2520", "bottom": "#1C1814", "line": "#00000099", "flash": "#FFD98A", "bezel": "#0D0D0D"},
    "classic": {"text": "#F2F2F2", "top": "#2C2C31", "bottom": "#1E1E23", "line": "#00000099", "flash": "#BFC3CC", "bezel": "#0D0D0D"},
    # Blackout: plates and bezel are true black (LEDs off) — only the text,
    # flip flashes, and color cards light up on the panel.
    "blackout": {"text": "#F2F2F2", "top": "#000000", "bottom": "#000000", "line": "#00000099", "flash": "#B0B0B8", "bezel": "#000000"},
    "crt": {"text": "#38FF70", "top": "#182219", "bottom": "#101812", "line": "#00000099", "flash": "#9CFFB8", "bezel": "#0D0D0D"},
    "ice": {"text": "#9BD4FF", "top": "#20262E", "bottom": "#161B22", "line": "#00000099", "flash": "#D6ECFF", "bezel": "#0D0D0D"},
    "paper": {"text": "#26221C", "top": "#D9D3C7", "bottom": "#C3BCAE", "line": "#00000055", "flash": "#FFFFFF", "bezel": "#0D0D0D"},
}

COLS, ROWS = 7, 3
MIN_FLIPS = 15

# The no-re-flip fix: 700 frames @50ms = 35s. The server caps the encoded
# animation at the app's display time, so any dwell up to 35s gets exactly
# one flip sequence followed by a hold to the end of the slot.
# The transition must land by frame 95 (4.75s) so even a 5s dwell shows a
# settled board rather than being cut mid-flip.
TRANSITION_FRAMES = 95
CYCLE_FRAMES = 700

def render_flap(char, flash, theme, scale, width, height):
    font = "terminus-16" if scale == 2 else "tb-8"
    inner_w, inner_h = width - 2 * scale, height - 2 * scale
    card = COLOR_MAP.get(char)

    # Plate: bottom-color base with a lighter top half (light falls on the
    # upper card of a real flap), or a solid color card with the same sheen.
    if card:
        base, top = card, "#FFFFFF1A"
    else:
        base, top = theme["bottom"], theme["top"]

    stack_children = [
        render.Box(width = inner_w, height = inner_h, color = base),
        render.Box(width = inner_w, height = inner_h // 2, color = top),
    ]

    if not card and char != " ":
        text_color = theme["text"] + ("99" if flash else "")
        glyph = render.Text(content = char, font = font, color = text_color)
        if scale == 2:
            # terminus-16 rides high in the tile; drop it 2px so the split
            # line crosses mid-glyph like it does at 1x
            glyph = render.Padding(pad = (0, 4, 0, 0), child = glyph)
        stack_children.append(render.Box(child = glyph))

    # Split line: translucent so it dims the glyph's middle row instead of
    # erasing it; flashes bright on flip frames (the falling card catching light).
    line_color = theme["flash"] + "CC" if flash else theme["line"]
    stack_children.append(
        render.Padding(
            pad = (0, inner_h // 2, 0, 0),
            child = render.Box(width = inner_w, height = scale, color = line_color),
        ),
    )

    return render.Box(
        width = width,
        height = height,
        padding = 1 * scale,
        color = theme["bezel"],
        child = render.Box(width = inner_w, height = inner_h, child = render.Stack(children = stack_children)),
    )

def center_text(text, width):
    text = text.strip()
    if not text:
        return " " * width
    pad = width - len(text)
    if pad <= 0:
        return text[:width]
    left = pad // 2
    return (" " * left + text + " " * (pad - left))[:width]

def is_mark(o):
    # Combining marks, ZWJ, and variation selectors modify the previous
    # character — dropping them (vs blanking) keeps words intact for
    # decomposed input like e + U+0301 and multi-codepoint emoji.
    return (
        (o >= 0x0300 and o <= 0x036F) or
        (o >= 0x1AB0 and o <= 0x1AFF) or
        (o >= 0x20D0 and o <= 0x20FF) or
        (o >= 0xFE00 and o <= 0xFE0F) or
        (o >= 0xFE20 and o <= 0xFE2F) or
        o == 0x200D
    )

def sanitize(text):
    out = ""
    for c in text.upper().codepoints():  # codepoints, not elems: one blank per char, not per byte
        if DRUM.find(c) != -1:
            out += c
        elif not is_mark(ord(c)):
            out += " "
    return out

def wrap_message(text):
    lines = []
    current = ""
    for word in sanitize(text).split(" "):
        if not word:
            continue
        for _ in range(4):  # hard-split words longer than a row
            if len(word) <= COLS:
                break
            if current:
                lines.append(current)
                current = ""
            lines.append(word[:COLS])
            word = word[COLS:]
        if not current:
            current = word
        elif len(current) + 1 + len(word) <= COLS:
            current += " " + word
        else:
            lines.append(current)
            current = word
    if current:
        lines.append(current)
    lines = lines[:ROWS]
    for _ in range(ROWS - len(lines)):
        lines.append("")
    return lines

def build_lines(config):
    now = time.now()

    # Optional explicit override wins; otherwise follow the device timezone.
    tz = config.get("timezone", "").strip()
    if not tz:
        tz = config.get("$tz", "")
    if tz:
        now = now.in_location(tz)

    if config.bool("24h"):
        t_str = now.format("15:04")
    elif config.bool("pad_hour"):
        t_str = now.format("03:04")
    else:
        t_str = now.format("3:04")

    if config.get("date_format", "mmm_dd") == "dd_mmm":
        d_str = now.format("02 Jan").upper()
    else:
        d_str = now.format("Jan 02").upper()

    day = now.format("Monday").upper()
    if len(day) > COLS:
        day = now.format("Mon").upper()

    layout = config.get("layout", "clock")
    if layout == "message":
        message = config.get("message", "")
        if not sanitize(message).strip():
            message = "HELLO WORLD"  # a cleared field would otherwise show a dead board
        return wrap_message(message)
    elif layout == "day_first":
        return [day, t_str, d_str]
    elif layout == "time_only":
        return ["", t_str, ""]
    return [d_str, t_str, day]

def prepare_message(config):
    message = ""
    for line in build_lines(config):
        line = center_text(line, COLS)
        if config.get("filler", "blank") == "color":
            processed = ""
            for c in line.elems():
                processed += COLOR_CHARS[random.number(0, 7)] if c == " " else c
            line = processed
        message += line
    return message

def main(config):
    scale = 2 if canvas.is2x() else 1
    flap_w, flap_h = 9 * scale, 10 * scale
    theme = THEMES.get(config.get("theme", "amber"), THEMES["amber"])
    target_message = prepare_message(config)

    speed = {"fast": 1, "medium": 2, "slow": 4}.get(config.get("flip_speed", "medium"), 2)
    reveal_type = config.get("reveal_type", "random")

    # Per-flap sequence of (char, flash) tuples.
    flap_seqs = []
    for i in range(COLS * ROWS):
        target_char = target_message[i]
        r, c = i // COLS, i % COLS

        if reveal_type == "row":
            delay = r * 10
        elif reveal_type == "wave":
            delay = c * 5
        elif reveal_type == "center":
            delay = abs(c - COLS // 2) * 6 + r * 2
        else:
            delay = random.number(0, 20)

        target_idx = DRUM.find(target_char)
        if target_idx == -1:
            target_idx = 0

        # Natural landing: pick a flip count that fits the transition window,
        # then start that many cards back on the drum. Every flap lands on its
        # target by spinning — no forced snap at the window edge.
        max_flips = (TRANSITION_FRAMES - delay - 1) // speed
        max_flips = min(max_flips, len(DRUM) - 1)
        flips = random.number(MIN_FLIPS, max(MIN_FLIPS, max_flips))

        seq = []
        idx = (target_idx - flips) % len(DRUM)
        for _ in range(delay):
            seq.append((DRUM[idx], False))
        for _ in range(flips):
            idx = (idx + 1) % len(DRUM)
            seq.append((DRUM[idx], True))
            for _ in range(speed - 1):
                seq.append((DRUM[idx], False))
        for _ in range(TRANSITION_FRAMES - len(seq)):
            seq.append((target_char, False))
        flap_seqs.append(seq)

    # Composite. Flap renders are memoized — most frames repeat most tiles.
    flap_cache = {}

    def flap(char, flash):
        key = (char, flash)
        if key not in flap_cache:
            flap_cache[key] = render_flap(char, flash, theme, scale, flap_w, flap_h)
        return flap_cache[key]

    frames = []
    for f in range(TRANSITION_FRAMES):
        rows = []
        for r in range(ROWS):
            rows.append(render.Row(children = [
                flap(flap_seqs[r * COLS + c][f][0], flap_seqs[r * COLS + c][f][1])
                for c in range(COLS)
            ]))
        frames.append(render.Box(child = render.Column(children = rows)))

    # Hold: one settled frame object, repeated. The encoder merges identical
    # frames into a single long-duration frame, so this costs almost nothing.
    settled = frames[-1]
    for _ in range(CYCLE_FRAMES - TRANSITION_FRAMES):
        frames.append(settled)

    return render.Root(child = render.Animation(children = frames))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "theme",
                name = "Theme",
                desc = "Board color scheme.",
                icon = "palette",
                default = "amber",
                options = [
                    schema.Option(display = "LED Amber", value = "amber"),
                    schema.Option(display = "Classic White", value = "classic"),
                    schema.Option(display = "White on Black", value = "blackout"),
                    schema.Option(display = "Green CRT", value = "crt"),
                    schema.Option(display = "Ice Blue", value = "ice"),
                    schema.Option(display = "Paper (inverted)", value = "paper"),
                ],
            ),
            schema.Dropdown(
                id = "layout",
                name = "Layout",
                desc = "What the board shows.",
                icon = "list",
                default = "clock",
                options = [
                    schema.Option(display = "Date / Time / Day", value = "clock"),
                    schema.Option(display = "Day / Time / Date", value = "day_first"),
                    schema.Option(display = "Time only", value = "time_only"),
                    schema.Option(display = "Custom message", value = "message"),
                ],
            ),
            schema.Text(
                id = "message",
                name = "Message",
                desc = "Shown in Custom message layout. A-Z 0-9 :.-!?& plus color cards [](){}<>.",
                icon = "message",
                default = "HELLO WORLD",
            ),
            schema.Dropdown(
                id = "filler",
                name = "Empty flaps",
                desc = "What blank tiles show.",
                icon = "fill",
                default = "blank",
                options = [
                    schema.Option(display = "Blank", value = "blank"),
                    schema.Option(display = "Color cards", value = "color"),
                ],
            ),
            schema.Text(
                id = "timezone",
                name = "Timezone",
                desc = "Optional IANA timezone override, e.g. America/New_York. Leave empty to use the device timezone.",
                icon = "globe",
                default = "",
            ),
            schema.Toggle(id = "24h", name = "24-hour time", desc = "Use 24-hour time.", icon = "clock", default = False),
            schema.Toggle(id = "pad_hour", name = "Pad hour", desc = "Show 03:04 instead of 3:04.", icon = "hashtag", default = False),
            schema.Dropdown(
                id = "date_format",
                name = "Date format",
                desc = "Order of the date line.",
                icon = "calendar",
                default = "mmm_dd",
                options = [
                    schema.Option(display = "AUG 16", value = "mmm_dd"),
                    schema.Option(display = "16 AUG", value = "dd_mmm"),
                ],
            ),
            schema.Dropdown(
                id = "flip_speed",
                name = "Flip speed",
                desc = "Mechanical speed.",
                icon = "gauge",
                default = "medium",
                options = [
                    schema.Option(display = "Fast", value = "fast"),
                    schema.Option(display = "Medium", value = "medium"),
                    schema.Option(display = "Slow", value = "slow"),
                ],
            ),
            schema.Dropdown(
                id = "reveal_type",
                name = "Reveal style",
                desc = "Transition pattern.",
                icon = "stairs",
                default = "random",
                options = [
                    schema.Option(display = "Random", value = "random"),
                    schema.Option(display = "Row by row", value = "row"),
                    schema.Option(display = "Left-to-right wave", value = "wave"),
                    schema.Option(display = "Center out", value = "center"),
                ],
            ),
        ],
    )
