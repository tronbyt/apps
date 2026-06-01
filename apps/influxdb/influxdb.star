load("encoding/base64.star", "base64")
load("http.star", "http")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_URL = "https://us-west-2-1.aws.cloud2.influxdata.com"
DEFAULT_QUERY = "SELECT value FROM cpu_load LIMIT 20"

def main(config):
    url = config.str("url", DEFAULT_URL)
    token = config.str("token", "")
    db = config.str("db", "")
    query = config.str("query", DEFAULT_QUERY)
    query2 = config.str("query2", "")

    unit = config.str("unit", "")
    unit2 = config.str("unit2", "")

    # Validation
    if not url:
        return render_error("Missing URL")

    # Fetch data or use dummy data if no token
    if not token:
        points1 = get_dummy_data()
        points2 = get_dummy_data(offset = 10) if query2 else None
    else:
        points1, error1 = get_data(url, db, query, token)
        if error1:
            return render_error(error1)

        points2 = None
        if query2:
            points2, error2 = get_data(url, db, query2, token)
            if error2:
                # If secondary query fails, maybe just show it? Or fail whole app?
                # Grafana app shows error if either fails.
                return render_error(error2)

    # Rendering
    plot_color = config.str("color", "#00ff00")
    plot_color2 = config.str("color2", "#0000ff")
    text_color = config.str("text_color", "#ffffff")
    text_color2 = config.str("text_color2", "#ffffff")
    title = config.str("title", "")

    # Set default title for dummy data if no title is configured
    if not token and not title:
        title = "Dummy Data"

    y_min_str = config.str("y_min", "")
    y_max_str = config.str("y_max", "")
    y_lim = (
        float(y_min_str) if y_min_str else None,
        float(y_max_str) if y_max_str else None,
    )

    width = 64
    height = 32
    font = "tb-8"
    title_height = 0
    text_font = "tom-thumb"

    if canvas.is2x():
        width = 128
        height = 64
        font = "6x13"
        text_font = "6x13"

    if title:
        if canvas.is2x():
            title_height = 14
        else:
            title_height = 9

    plot_height = height - title_height

    plot1 = render.Plot(
        data = points1,
        width = width,
        height = plot_height,
        color = plot_color,
        fill = True,
        fill_color = plot_color + "44",
        y_lim = y_lim,
    )

    final_plot = plot1

    if points2:
        plot2 = render.Plot(
            data = points2,
            width = width,
            height = plot_height,
            color = plot_color2,
            fill = True,
            fill_color = plot_color2 + "44",
            y_lim = y_lim,
        )
        final_plot = render.Stack(
            children = [plot1, plot2],
        )

    # Text overlay logic
    show_text = config.bool("show_text", True)

    if show_text:
        text_children = []

        # Helper to format value
        def format_val(val, u):
            # Round to 1 decimal place
            v = math.round(val * 10) / 10.0
            return str(v) + u

        val1 = points1[-1][1]
        text1 = render.Text(
            content = format_val(val1, unit),
            color = text_color,
            font = text_font,
        )
        text_children.append(text1)

        if points2:
            val2 = points2[-1][1]
            text2 = render.Text(
                content = format_val(val2, unit2),
                color = text_color2,
                font = text_font,
            )

            # Add spacer
            text_children.append(render.Box(width = 4, height = 1))
            text_children.append(text2)

        text_overlay = render.Box(
            child = render.Column(
                expanded = True,
                main_align = "end",  # Align to bottom
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        cross_align = "end",
                        children = text_children,
                    ),
                    # Add spacer to move text higher
                    render.Box(height = 6),
                ],
            ),
        )

        final_plot = render.Stack(
            children = [
                final_plot,
                text_overlay,
            ],
        )

    if title:
        child = render.Column(
            expanded = True,
            main_align = "start",
            cross_align = "center",
            children = [
                render.Box(
                    height = title_height,
                    child = render.Text(content = title, font = font, color = "#fff"),
                ),
                final_plot,
            ],
        )
    else:
        child = final_plot

    return render.Root(
        child = child,
    )

def get_dummy_data(offset = 0):
    points = []
    now_unix = time.now().unix
    for i in range(20):
        # Generate a sine wave pattern based on time
        # This ensures the graph moves over time in previews
        val = 50 + 40 * math.sin((now_unix + i * 10 + offset) / 10.0)
        points.append((i, val))
    return points

def get_data(url, db, query, token):
    params = {
        "q": query,
    }
    if db:
        params["db"] = db

    full_url = "{}/query".format(url.rstrip("/"))

    headers = {}
    if token:
        if ":" in token:
            headers["Authorization"] = "Basic {}".format(base64.encode(token))
        else:
            headers["Authorization"] = "Token {}".format(token)

    res = http.post(full_url, form_body = params, headers = headers)

    if res.status_code != 200:
        return None, "HTTP {}".format(res.status_code)

    if "application/json" not in res.headers.get("Content-Type", ""):
        return None, "Invalid Response: not JSON"

    data = res.json()

    if "results" not in data:
        return None, "Invalid Response"

    results = data["results"]
    if not results or "series" not in results[0]:
        return None, "No Data"

    series = results[0]["series"]
    if not series:
        return None, "No Series"

    # Take the first series
    first_series = series[0]
    columns = first_series.get("columns", [])
    values = first_series.get("values", [])

    if not values:
        return None, "Empty Series"

    # Find value column (first non-time column)
    value_idx = -1
    for i in range(len(columns)):
        if columns[i] != "time":
            value_idx = i
            break

    if value_idx == -1:
        return None, "No Value Column"

    # Extract points
    points = []
    for i in range(len(values)):
        val = values[i][value_idx]
        if type(val) == "float" or type(val) == "int":
            points.append((i, float(val)))

    if not points:
        return None, "No Numeric Data"

    return points, None

def render_error(msg):
    return render.Root(
        child = render.Box(
            child = render.WrappedText(msg, color = "#ff0000"),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "url",
                name = "InfluxDB URL",
                desc = "URL of InfluxDB instance",
                icon = "server",
                default = DEFAULT_URL,
            ),
            schema.Text(
                id = "token",
                name = "Token / Password",
                desc = "Auth Token or user:pass",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "db",
                name = "Database / Bucket",
                desc = "Database name (v1) or Bucket ID mapped (v2)",
                icon = "database",
            ),
            schema.Text(
                id = "query",
                name = "Query",
                desc = "InfluxQL Query",
                icon = "code",
                default = DEFAULT_QUERY,
            ),
            schema.Color(
                id = "color",
                name = "Plot Color",
                desc = "Color of the plot",
                icon = "brush",
                default = "#00ff00",
            ),
            schema.Text(
                id = "unit",
                name = "Unit",
                desc = "Unit to display next to the value",
                icon = "ruler",
                default = "",
            ),
            schema.Color(
                id = "text_color",
                name = "Text Color",
                desc = "Color of the value text",
                icon = "brush",
                default = "#ffffff",
            ),
            schema.Text(
                id = "query2",
                name = "Query 2 (Optional)",
                desc = "Second InfluxQL Query",
                icon = "code",
            ),
            schema.Color(
                id = "color2",
                name = "Plot Color 2",
                desc = "Color of the second plot",
                icon = "brush",
                default = "#0000ff",
            ),
            schema.Text(
                id = "unit2",
                name = "Unit 2",
                desc = "Unit for the second value",
                icon = "ruler",
                default = "",
            ),
            schema.Color(
                id = "text_color2",
                name = "Text Color 2",
                desc = "Color of the second value text",
                icon = "brush",
                default = "#ffffff",
            ),
            schema.Text(
                id = "title",
                name = "Title",
                desc = "Title to display above the plot",
                icon = "tag",
                default = "",
            ),
            schema.Text(
                id = "y_min",
                name = "Y Min",
                desc = "Minimum value for Y axis",
                icon = "arrowDown",
            ),
            schema.Text(
                id = "y_max",
                name = "Y Max",
                desc = "Maximum value for Y axis",
                icon = "arrowUp",
            ),
            schema.Toggle(
                id = "show_text",
                name = "Show Value Text",
                desc = "Show the most recent value as text",
                icon = "eye",
                default = True,
            ),
        ],
    )
