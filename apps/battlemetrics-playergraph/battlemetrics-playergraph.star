load("api.star", "fetch_24h_history", "fetch_server_name")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("render.star", "render")
load("schema.star", "schema")
load("utils.star", "round_up_y_max", "truncate")
load("widgets.star", "GRID_COLOR", "label_widget_width", "v_dash_line", "y_label_widget")

LINE_COLOR = "#e03030"
FILL_COLOR = "#5a1010"

def render_title(name, use_marquee):
    if not use_marquee:
        return render.Box(
            width = 64,
            height = 6,
            child = render.Text(truncate(name), font = "tom-thumb", color = "#ffffff"),
        )

    text = render.Text(name, font = "tom-thumb", color = "#ffffff")
    cw, _ch = text.size()

    if cw <= 64:
        return render.Box(width = 64, height = 6, child = text)

    DELAY_FRAMES = 50
    HOLD_FRAMES = 30

    scroll_part = render.Marquee(
        width = 64,
        offset_end = 128,
        delay = DELAY_FRAMES,
        child = text,
    )

    hold_frame = render.Box(
        width = 64,
        height = 6,
        child = render.Padding(
            child = text,
            pad = (64 - cw, 0, 0, 0),
        ),
    )

    return render.Box(
        width = 64,
        height = 6,
        child = render.Sequence(
            children = [
                scroll_part,
                render.Animation(children = [hold_frame] * HOLD_FRAMES),
            ],
        ),
    )

def render_graph(values, h_lines_count, show_v_lines, v_lines_count):
    plot_data = [(float(i), float(v)) for i, v in enumerate(values)]
    n = len(values)
    y_max = round_up_y_max(max(values))

    GRAPH_HEIGHT = 26

    # Top line is always at y_max; remaining lines step down by y_max/N.
    # Pixel rows are rounded so labels (5px tall) and grid lines stay aligned.
    h_values = [y_max * (h_lines_count - i) // h_lines_count for i in range(h_lines_count)]
    h_positions = [(i * GRAPH_HEIGHT + h_lines_count // 2) // h_lines_count for i in range(h_lines_count)]

    # Shrink the label column to the widest label actually shown
    LABEL_WIDTH = max([label_widget_width(v) for v in h_values])
    PLOT_WIDTH = 64 - LABEL_WIDTH - 1  # -1 for the 1px spacer between labels and graph

    label_children = [y_label_widget(h_values[0])]
    for i in range(1, h_lines_count):
        gap = h_positions[i] - h_positions[i - 1] - 5  # 5 = label glyph height
        if gap > 0:
            label_children.append(render.Box(width = LABEL_WIDTH, height = gap))
        label_children.append(y_label_widget(h_values[i]))

    # Pad the bottom so the Column fills GRAPH_HEIGHT; otherwise the wrapping
    # Box would vertically center the labels, knocking them off the grid lines.
    trailing = GRAPH_HEIGHT - (h_positions[-1] + 5)
    if trailing > 0:
        label_children.append(render.Box(width = LABEL_WIDTH, height = trailing))
    y_labels = render.Column(children = label_children)

    grid_children = [render.Box(width = PLOT_WIDTH, height = 1, color = GRID_COLOR)]
    for i in range(1, h_lines_count):
        gap = h_positions[i] - h_positions[i - 1] - 1
        if gap > 0:
            grid_children.append(render.Box(width = PLOT_WIDTH, height = gap))
        grid_children.append(render.Box(width = PLOT_WIDTH, height = 1, color = GRID_COLOR))
    grid = render.Column(children = grid_children)

    plot = render.Plot(
        data = plot_data,
        width = PLOT_WIDTH,
        height = GRAPH_HEIGHT,
        color = LINE_COLOR,
        fill = True,
        fill_color = FILL_COLOR,
        x_lim = (0.0, float(n - 1)),
        y_lim = (0.0, float(y_max)),
    )

    stack_children = [plot, grid]
    if show_v_lines:
        v_positions = [(i + 1) * PLOT_WIDTH // (v_lines_count + 1) for i in range(v_lines_count)]
        v_children = []
        prev_x = 0
        for x in v_positions:
            gap = x - prev_x
            if gap > 0:
                v_children.append(render.Box(width = gap, height = GRAPH_HEIGHT))
            v_children.append(v_dash_line(GRAPH_HEIGHT))
            prev_x = x + 1
        stack_children.append(render.Row(children = v_children))

    return render.Row(
        children = [
            render.Box(width = LABEL_WIDTH, height = GRAPH_HEIGHT, child = y_labels),
            render.Box(width = 1, height = GRAPH_HEIGHT),
            render.Stack(children = stack_children),
        ],
    )

def render_missing_server_id():
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text("BattleMetrics", font = "tb-8", color = "#ffffff"),
                render.Box(height = 4),
                render.Text("MISSING", font = "tb-8", color = "#ff3333"),
                render.Text("SERVER ID", font = "tb-8", color = "#ff3333"),
            ],
        ),
    )

def render_error_state(name):
    return render.Root(
        max_age = 60,
        child = render.Column(
            expanded = True,
            main_align = "space_between",
            children = [
                render.Box(
                    width = 64,
                    height = 6,
                    child = render.Text(truncate(name), font = "tom-thumb", color = "#ffffff"),
                ),
                render.Column(
                    expanded = True,
                    main_align = "center",
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "center",
                            children = [
                                render.Text("== API ERROR ==", font = "tom-thumb", color = "#ff3333"),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def main(config):
    server_id = config.get("server_id")
    if not server_id:
        return render_missing_server_id()

    custom_title = config.get("custom_title") or ""
    use_marquee = config.get("title_marquee") != "false"
    show_v_lines = config.get("show_v_lines") == "true"
    v_lines_count = int(config.get("v_lines_count") or "2")
    h_lines_count = int(config.get("h_lines_count") or "3")

    history = fetch_24h_history(server_id)
    if history == None or len(history) == 0:
        cached_json = cache.get("bm_history_" + server_id)
        if cached_json != None:
            history = json.decode(cached_json)
        else:
            cached_name = cache.get("bm_history_name_" + server_id)
            if custom_title != "":
                display_name = custom_title
            elif cached_name != None:
                display_name = cached_name
            else:
                display_name = "Unknown"
            return render_error_state(display_name)

    # Sort by timestamp ascending (ISO 8601 sorts lexicographically = chronologically)
    pairs = sorted([[p["attributes"]["timestamp"], p["attributes"]["value"]] for p in history])
    values = [pair[1] for pair in pairs]

    if custom_title != "":
        display_name = custom_title
    else:
        name = fetch_server_name(server_id)
        display_name = name if name != None else "Unknown"

    return render.Root(
        max_age = 1800,
        child = render.Column(
            children = [
                render_title(display_name, use_marquee),
                render_graph(values, h_lines_count, show_v_lines, v_lines_count),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "server_id",
                name = "Server ID",
                desc = "BattleMetrics server ID",
                icon = "server",
            ),
            schema.Text(
                id = "custom_title",
                name = "Custom title",
                desc = "Override the server name shown on the display",
                icon = "tag",
            ),
            schema.Toggle(
                id = "title_marquee",
                name = "Scroll title",
                desc = "Scroll the server name instead of truncating it",
                icon = "arrowsLeftRight",
                default = True,
            ),
            schema.Dropdown(
                id = "h_lines_count",
                name = "Horizontal lines",
                desc = "Number of horizontal grid lines",
                icon = "gripLines",
                default = "3",
                options = [
                    schema.Option(display = "1 (top)", value = "1"),
                    schema.Option(display = "2 (top, 1/2)", value = "2"),
                    schema.Option(display = "3 (top, 2/3, 1/3)", value = "3"),
                    schema.Option(display = "4 (top, 3/4, 2/4, 1/4)", value = "4"),
                ],
            ),
            schema.Toggle(
                id = "show_v_lines",
                name = "Vertical lines",
                desc = "Show vertical grid lines on the graph",
                icon = "gripLinesVertical",
                default = False,
            ),
            schema.Dropdown(
                id = "v_lines_count",
                name = "Vertical lines count",
                desc = "Number of vertical grid lines (when enabled)",
                icon = "gripLinesVertical",
                default = "2",
                options = [
                    schema.Option(display = "1", value = "1"),
                    schema.Option(display = "2", value = "2"),
                    schema.Option(display = "3", value = "3"),
                ],
            ),
        ],
    )
