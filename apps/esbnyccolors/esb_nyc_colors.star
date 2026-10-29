"""
Applet: ESB NYC Colors
Summary: Empire State Bld Colors
Description: Shows today's colors of the Empire State Building.
Author: sklose
"""

load("http.star", "http")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

# Built every two hours from esbnyc.com/about/tower-lights. Each day carries
# up to 4 hex colors in title order, a pattern (static, sparkle, rotating) and,
# for a rotation through several color sets such as a run of flags, frames.
FEED_URL = "https://raw.githubusercontent.com/jvivona/tidbyt-data/main/esbnyc/lights.json"
TIMEZONE = "America/New_York"
MAX_COLORS = 4

WIDTH, HEIGHT = canvas.size()

# 64x32 classic, 128x64 wide (2x) and 64x64 square: widths scale with WS,
# heights with VS, so the square panel gets a taller drawing, not a wider one.
WS = WIDTH // 64
VS = HEIGHT // 32
IS_2X = canvas.is2x()

# Marquees move a pixel a frame, so 2x halves the delay to keep the speed.
DELAY_HORIZONTAL = 25 if IS_2X else 50
DELAY_VERTICAL = 50 if IS_2X else 100
ROTATE_MS = 1000
SPARKLE_MS = 200
SPARKLE_STEPS = 10
SPARKLE_DOTS = 5
SPARKLE_COLOR = "#fff"

FONT_TITLE = "terminus-12" if IS_2X else "tom-thumb"
FONT_TITLE_HEIGHT = 12 if IS_2X else 6
FONT_TICKER = "terminus-16" if IS_2X else "tb-8"
FONT_TICKER_HEIGHT = 16 if IS_2X else 8
TITLE_COLOR = "#fd0"
FONT_VERTICAL = "terminus-12" if IS_2X else "tom-thumb"

# Tower sections top to bottom as (width, height) on a 64x32 panel: antenna,
# crown (two steps), upper body and base. The heights add up to 32.
TOWER = [
    [(2, 9)],
    [(4, 2), (6, 3)],
    [(10, 9)],
    [(14, 9)],
]
TOWER_WIDTH = 14 * WS

def main(config):
    day = todays_lights(config.get("dev_date"))
    if day == None:
        return []

    pattern = day.get("pattern") or "static"
    frames = color_frames(day, pattern)
    if config.bool("vertical-mode", True):
        return render_vertically(day, frames, pattern)
    return render_horizontally(day, frames, pattern)

def todays_lights(dev_date):
    """Today's entry (New York date) from the feed, or None to skip this cycle.

    ``dev_date`` (YYYY-MM-DD, not in the schema) previews another day.
    """
    rep = http.get(FEED_URL, ttl_seconds = 3600)
    if rep.status_code != 200:
        return None
    today = dev_date or time.now().in_location(TIMEZONE).format("2006-01-02")
    for day in rep.json().get("days") or []:
        if day.get("date") == today and day.get("colors"):
            return day
    return None

def color_frames(day, pattern):
    """The color sets to show in turn; a single set unless the lights rotate.

    A rotation with frames (a run of flags) shows each set; one without moves
    the title's colors along by one each step.
    """
    colors = day["colors"][:MAX_COLORS]
    if pattern != "rotating":
        return [colors]
    frames = [f[:MAX_COLORS] for f in (day.get("frames") or []) if f]
    if frames:
        return frames
    return [colors[i:] + colors[:i] for i in range(len(colors))]

def animated(draw, frames, pattern, delay, sparkle_areas):
    """``draw(colors)`` for each frame, held long enough to read, or sparkling."""
    if pattern == "sparkle":
        base = draw(frames[0])
        hold = max(1, SPARKLE_MS // delay)
        children = []
        for _ in range(SPARKLE_STEPS):
            children.extend([render.Stack(children = [base] + sparkles(sparkle_areas))] * hold)
        return render.Animation(children = children)

    if len(frames) == 1:
        return draw(frames[0])
    hold = max(1, ROTATE_MS // delay)
    children = []
    for colors in frames:
        children.extend([draw(colors)] * hold)
    return render.Animation(children = children)

def sparkles(areas):
    """A few white dots, each inside one of the lit areas (x, y, w, h)."""
    dots = []
    for _ in range(SPARKLE_DOTS):
        x, y, w, h = areas[random.number(0, len(areas) - 1)]
        dots.append(render.Padding(
            pad = (x + random.number(0, w - WS), y + random.number(0, h - VS), 0, 0),
            child = render.Box(width = WS, height = VS, color = SPARKLE_COLOR),
        ))
    return dots

def frame_budget(delay):
    """Frames that fit the dwell the server gave this app; 0 means no limit."""
    ms = canvas.max_duration_ms()
    return ms // delay if ms > 0 else 0

def fitted_marquee(candidates, budget):
    """The first marquee that scrolls through within the budget.

    Candidates go from the fullest text to the shortest. When none fits, the
    shortest is used and the dwell cuts its tail off.
    """
    for marquee in candidates:
        # frame_count() lays out on a 64x32 canvas unless given real bounds
        if budget == 0 or marquee.frame_count((0, 0, WIDTH, HEIGHT)) <= budget:
            return marquee
    return candidates[-1]

def tower(colors):
    """The building, its sections colored top to bottom, cycling the colors."""
    rows = []
    for i, section in enumerate(TOWER):
        for w, h in section:
            rows.append(render.Box(width = w * WS, height = h * VS, color = colors[i % len(colors)]))
    return render.Column(cross_align = "center", children = rows)

def tower_areas():
    """Where sparkles can land on the tower: the crown down, not the antenna."""
    areas = []
    y = 0
    for i, section in enumerate(TOWER):
        for w, h in section:
            if i > 0:
                areas.append(((TOWER_WIDTH - w * WS) // 2, y, w * WS, h * VS))
            y += h * VS
    return areas

def render_horizontally(day, frames, pattern):
    """Title in gold across the top, concentric color boxes centered in the
    middle and the description as a ticker along the bottom.

    Both lines scroll only when wider than the panel. A description that won't
    scroll through within the dwell is cut off; the title is already shown.
    """
    title = day.get("title") or ""
    description = day.get("description") or ""
    rows = [render.Marquee(
        width = WIDTH,
        align = "center",
        child = render.Text(content = title, font = FONT_TITLE, color = TITLE_COLOR),
    )]
    box_height = HEIGHT - FONT_TITLE_HEIGHT - 2 * VS
    if description:
        box_height -= FONT_TICKER_HEIGHT
    rows.append(animated(
        lambda colors: nested_boxes(colors, WIDTH, box_height),
        frames,
        pattern,
        DELAY_HORIZONTAL,
        [(0, 0, WIDTH, box_height)],
    ))
    if description:
        rows.append(render.Marquee(
            width = WIDTH,
            child = render.Text(content = description, font = FONT_TICKER),
        ))
    return render.Root(
        delay = DELAY_HORIZONTAL,
        child = render.Column(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = rows,
        ),
    )

def nested_boxes(colors, width, height):
    """Concentric boxes, the first color outermost."""
    n = len(colors)
    child = render.Box(
        width = width - (n - 1) * (width // n),
        height = height - (n - 1) * (height // n),
        color = colors[n - 1],
    )
    for i in range(n - 2, -1, -1):
        child = render.Box(
            width = width - i * (width // n),
            height = height - i * (height // n),
            color = colors[i],
            child = child,
        )
    return child

def render_vertically(day, frames, pattern):
    text_width = WIDTH - TOWER_WIDTH - WS
    title = render.WrappedText(content = day.get("title") or "", width = text_width, font = FONT_VERTICAL, color = TITLE_COLOR)
    candidates = [[title]]
    if day.get("description"):
        description = render.WrappedText(content = day["description"], width = text_width, font = FONT_VERTICAL)
        candidates = [[title, description], [description]]
    marquee = fitted_marquee(
        [
            render.Marquee(height = HEIGHT, scroll_direction = "vertical", child = render.Column(children = lines))
            for lines in candidates
        ],
        frame_budget(DELAY_VERTICAL),
    )
    return render.Root(
        delay = DELAY_VERTICAL,
        child = render.Row(
            children = [
                animated(tower, frames, pattern, DELAY_VERTICAL, tower_areas()),
                render.Padding(pad = (WS, 0, 0, 0), child = marquee),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "vertical-mode",
                name = "Vertical Mode",
                desc = "Scroll text vertically",
                icon = "user",
                default = True,
            ),
        ],
    )
