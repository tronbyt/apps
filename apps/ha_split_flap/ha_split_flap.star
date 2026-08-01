load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")

# --- Constants ---
CHAR_SET = " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!?[]{}()<>.-\"' "
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
TRANSITION_FRAMES, HOLD_FRAMES = 150, 40
CYCLE_FRAMES = TRANSITION_FRAMES + HOLD_FRAMES

# --- HA Fetch ---
def fetch_ha_state(ha_url, ha_token, entity, cache_duration):
    if not ha_url or not ha_token or not entity:
        return "CONFIG HA"

    headers = {
        "Authorization": "Bearer " + ha_token,
        "Content-Type": "application/json",
    }
    base_url = ha_url.rstrip("/")
    url = base_url + "/api/states/" + entity

    resp = http.get(url, headers = headers, ttl_seconds = cache_duration)
    if resp.status_code == 200:
        data = json.decode(resp.body())
        return str(data.get("state", "ERR"))
    return "ERR " + str(resp.status_code)

def fetch_ha_template(ha_url, ha_token, template_str, cache_duration):
    if not ha_url or not ha_token or not template_str:
        return "CONFIG HA"

    headers = {
        "Authorization": "Bearer " + ha_token,
        "Content-Type": "application/json",
    }
    base_url = ha_url.rstrip("/")
    url = base_url + "/api/template"

    body = json.encode({"template": template_str})
    resp = http.post(url, headers = headers, body = body, ttl_seconds = cache_duration)
    if resp.status_code == 200:
        return str(resp.body()).strip()
    return "ERR " + str(resp.status_code)

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
def format_number(val_str, num_format):
    if num_format == "none" or val_str == "ERR" or val_str == "CONFIG HA" or val_str.startswith("ERR "):
        return val_str

    is_num = True
    dots = 0
    for c in val_str.elems():
        if c == ".":
            dots += 1
        elif c == "-":
            pass
        elif c not in "0123456789":
            is_num = False
            break

    if is_num and dots <= 1 and val_str != "." and val_str != "-" and val_str != "-.":
        val = float(val_str)
        if num_format == "round":
            return str(int(math.round(val)))
        elif num_format == "floor":
            return str(int(math.floor(val)))
        elif num_format == "ceil":
            return str(int(math.ceil(val)))
        elif num_format == "truncate":
            return str(int(val))

    return val_str

def center_text(text, width):
    text = text.strip()
    if not text:
        return " " * width
    pad = width - len(text)
    if pad <= 0:
        return text[:width]
    left = pad // 2
    return (" " * left + text + " " * (pad - left))[:width]

def prepare_pages(texts, config):
    all_pages = []
    for input_text in texts:
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
        if not pages:
            pages = [" " * (COLS * ROWS)]
        all_pages.extend(pages)

    if not all_pages:
        all_pages = [" " * (COLS * ROWS)]
    return all_pages

# --- Main Logic ---
def main(config):
    SCALE = 2 if canvas.is2x() else 1
    FLAP_W, FLAP_H = 9 * SCALE, 10 * SCALE

    ha_url = config.str("ha_url")
    ha_token = config.str("ha_token")
    entities_str = config.str("entity", "")
    template_str = config.str("template", "")

    cache_duration_str = config.str("cache_duration", "300")
    cache_duration = 300
    if cache_duration_str.isdigit():
        cache_duration = int(cache_duration_str)

    before_text = config.str("before_text", "")
    after_text = config.str("after_text", "")
    num_format = config.str("number_format", "none")

    texts_to_render = []
    if template_str:
        val = fetch_ha_template(ha_url, ha_token, template_str, cache_duration)
        texts_to_render.append(val)
    elif entities_str:
        entities = [e.strip() for e in entities_str.split(",") if e.strip()]
        for e in entities:
            val = fetch_ha_state(ha_url, ha_token, e, cache_duration)
            val = format_number(val, num_format)
            texts_to_render.append(before_text + val + after_text)
    else:
        texts_to_render.append("CONFIG HA")

    # replace unrenderable chars with spaces
    clean_texts = []
    for txt in texts_to_render:
        clean_val = ""
        for c in txt.upper().elems():
            if CHAR_SET.find(c) != -1:
                clean_val += c
            else:
                clean_val += " "
        clean_texts.append(clean_val)

    pages = prepare_pages(clean_texts, config)

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
            for _ in range(300):
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
            schema.Text(
                id = "ha_url",
                name = "Home Assistant URL",
                desc = "e.g. https://homeassistant.local:8123",
                icon = "server",
            ),
            schema.Text(
                id = "ha_token",
                name = "Home Assistant Token",
                desc = "Long-lived access token from HA",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "template",
                name = "Jinja2 Template",
                desc = "Optional Jinja2 template (bypasses entity).",
                icon = "code",
            ),
            schema.Text(
                id = "entity",
                name = "Entity",
                desc = "Entity ID(s) to display (e.g. sensor.temp, sensor.humidity)",
                icon = "tag",
            ),
            schema.Text(
                id = "before_text",
                name = "Before Text",
                desc = "Text to display before the value",
                icon = "textWidth",
            ),
            schema.Text(
                id = "after_text",
                name = "After Text",
                desc = "Text to display after the value",
                icon = "textWidth",
            ),
            schema.Dropdown(
                id = "number_format",
                name = "Number Format",
                desc = "Format the sensor value if it is a number.",
                icon = "calculator",
                default = "none",
                options = [
                    schema.Option(display = "None", value = "none"),
                    schema.Option(display = "Round", value = "round"),
                    schema.Option(display = "Floor", value = "floor"),
                    schema.Option(display = "Ceiling", value = "ceil"),
                    schema.Option(display = "Truncate", value = "truncate"),
                ],
            ),
            schema.Text(
                id = "cache_duration",
                name = "Cache Duration",
                desc = "How long to cache data from Home Assistant (in seconds)",
                icon = "clock",
                default = "300",
            ),
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
