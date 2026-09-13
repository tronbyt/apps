load("render.star", "render")

LABEL_COLOR = "#888888"
GRID_COLOR = "#88888880"

def v_dash_line(height):
    dash, gap = 2, 2
    children = []
    y = 0
    colored = True
    for _ in range(height):
        if y >= height:
            break
        seg = min(dash if colored else gap, height - y)
        if colored:
            children.append(render.Box(width = 1, height = seg, color = GRID_COLOR))
        else:
            children.append(render.Box(width = 1, height = seg))
        y += seg
        colored = not colored
    return render.Column(children = children)

def _small_dot():
    # 1 px dot at row 5 of a 5 px line, with 1 px right spacing
    return render.Padding(
        pad = (0, 4, 1, 0),
        child = render.Box(width = 1, height = 1, color = LABEL_COLOR),
    )

def label_widget_width(n):
    # Mirrors the layout in y_label_widget. CG-pixel-3x5-mono is 3 px wide
    # per char with 1 px between chars, so N chars = 4*N - 1 px. Each dot
    # widget is 2 px wide (1 px dot + 1 px right pad).
    n = int(n)
    if n < 10:
        return 3
    if n < 100:
        return 7
    if n < 1000:
        return 7 + 2
    if n < 10000:
        return 7 + 4
    chars = len(str(n // 1000)) + 1  # digits of thousands + "k"
    return 4 * chars - 1

def y_label_widget(n):
    n = int(n)
    if n < 100:
        return render.Text(str(n), font = "CG-pixel-3x5-mono", color = LABEL_COLOR)
    if n < 1000:
        # First 2 digits + 1 narrow dot (e.g. 142 -> "14·")
        return render.Row(
            children = [
                render.Text(str(n // 10), font = "CG-pixel-3x5-mono", color = LABEL_COLOR),
                _small_dot(),
            ],
        )
    if n < 10000:
        # First 2 digits + 2 narrow dots (e.g. 1432 -> "14··")
        return render.Row(
            children = [
                render.Text(str(n // 100), font = "CG-pixel-3x5-mono", color = LABEL_COLOR),
                _small_dot(),
                _small_dot(),
            ],
        )
    return render.Text(str(n // 1000) + "k", font = "CG-pixel-3x5-mono", color = LABEL_COLOR)
