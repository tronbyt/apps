"""
Applet: HA Columns
Summary: Multi-column Home Assistant sensor display
Description: Displays Home Assistant sensors in configurable columns (2-4 columns supported)
Author: Mitchell Scott
"""

load("http.star", "http")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")

FONT_DEFAULT = "default"
DEFAULT_LABEL_FONT = "tb-8"
DEFAULT_LABEL_FONT_2X = "terminus-14"
DEFAULT_VALUE_FONT = "tb-8"
DEFAULT_VALUE_FONT_2X = "terminus-16"
DEFAULT_COLUMN_COUNT = "2"
DEFAULT_LABEL_COLOR = "#FF0"
DEFAULT_VALUE_COLOR = "#FFF"
DEFAULT_DIVIDER_COLOR = "#444"

def main(config):
    scale = 2 if canvas.is2x() else 1
    column_count = int(config.get("column_count", DEFAULT_COLUMN_COUNT))

    columns = []
    for i in range(1, column_count + 1):
        label = config.get("col%d_label" % i, "Col %d" % i)
        label_color = config.get("col%d_label_color" % i, DEFAULT_LABEL_COLOR)
        value_color = config.get("col%d_value_color" % i, DEFAULT_VALUE_COLOR)
        sensor1 = fetch_sensor(config.get("col%d_sensor1_entity" % i), config)
        sensor2 = fetch_sensor(config.get("col%d_sensor2_entity" % i), config)

        if sensor1 == None or sensor2 == None:
            return render.Root(
                child = render.Box(
                    render.Text("Check sensor config", font = "tb-8", color = "#f00"),
                ),
            )

        columns.append({
            "label": label,
            "label_color": label_color,
            "value_color": value_color,
            "sensor1": sensor1,
            "sensor2": sensor2,
        })

    label_font = config.get("label_font")
    if not label_font or label_font == FONT_DEFAULT:
        if column_count >= 4:
            label_font = "terminus-12" if scale == 2 else "tom-thumb"
        elif column_count >= 3:
            label_font = "terminus-12" if scale == 2 else "tb-8"
        else:
            label_font = DEFAULT_LABEL_FONT_2X if scale == 2 else DEFAULT_LABEL_FONT

    value_font = config.get("value_font")
    if not value_font or value_font == FONT_DEFAULT:
        if column_count >= 4:
            value_font = "terminus-14" if scale == 2 else "tb-8"
        elif column_count >= 3:
            value_font = "terminus-16" if scale == 2 else "tb-8"
        else:
            value_font = DEFAULT_VALUE_FONT_2X if scale == 2 else DEFAULT_VALUE_FONT

    divider_color = config.get("divider_color", DEFAULT_DIVIDER_COLOR)

    return render.Root(
        child = render_columns(
            columns,
            label_font,
            value_font,
            divider_color,
            scale,
        ),
    )

def fetch_sensor(entity_id, config):
    if not entity_id or not config.get("ha_url") or not config.get("ha_token"):
        return None

    url = config.get("ha_url") + "/api/states/" + entity_id
    headers = {"Authorization": "Bearer " + config.get("ha_token")}

    rep = http.get(url, ttl_seconds = 60, headers = headers)
    if rep.status_code != 200:
        return None

    data = rep.json()
    state = data.get("state")
    if not state:
        return None

    isnum = (state.count(".") == 1 and state.replace(".", "").isdigit()) or state.isdigit()
    if not isnum:
        return None

    return float(state)

def render_columns(columns, label_font, value_font, divider_color, scale):
    DIVIDER_WIDTH = 1 * scale
    HEIGHT = 32 * scale

    children = []
    for i, col in enumerate(columns):
        children.append(
            render_column(
                col["label"],
                col["label_color"],
                col["sensor1"],
                col["sensor2"],
                label_font,
                value_font,
                col["value_color"],
                scale,
            ),
        )

        if i < len(columns) - 1:
            children.append(
                render.Box(
                    width = DIVIDER_WIDTH,
                    height = HEIGHT,
                    color = divider_color,
                ),
            )

    return render.Row(
        expanded = True,
        main_align = "space_evenly",
        children = children,
    )

def render_column(label, label_color, sensor1, sensor2, label_font, value_font, value_color, scale):
    degree_symbol = "°" if scale == 2 else ""

    sensor1_rounded = math.round(sensor1 * 10) / 10
    sensor2_rounded = int(math.round(sensor2))

    return render.Column(
        expanded = True,
        main_align = "space_around",
        cross_align = "center",
        children = [
            render.Text(
                label,
                font = label_font,
                color = label_color,
            ),
            render.Text(
                str(sensor1_rounded) + degree_symbol,
                font = value_font,
                color = value_color,
            ),
            render.Text(
                "%d%%" % sensor2_rounded,
                font = value_font,
                color = value_color,
            ),
        ],
    )

def generate_column_fields(column_count):
    if not column_count:
        column_count = DEFAULT_COLUMN_COUNT

    count = int(column_count)
    fields = []

    for i in range(1, count + 1):
        fields.extend([
            schema.Text(
                id = "col%d_label" % i,
                name = "Column %d Label" % i,
                desc = "Label for column %d" % i,
                icon = "tag",
                default = "Col %d" % i,
            ),
            schema.Color(
                id = "col%d_label_color" % i,
                name = "Column %d Label Color" % i,
                desc = "Color for column %d label" % i,
                icon = "brush",
                default = DEFAULT_LABEL_COLOR,
            ),
            schema.Color(
                id = "col%d_value_color" % i,
                name = "Column %d Value Color" % i,
                desc = "Color for column %d values" % i,
                icon = "brush",
                default = DEFAULT_VALUE_COLOR,
            ),
            schema.Text(
                id = "col%d_sensor1_entity" % i,
                name = "Column %d Sensor 1" % i,
                desc = "Entity ID for column %d, row 1" % i,
                icon = "gauge",
            ),
            schema.Text(
                id = "col%d_sensor2_entity" % i,
                name = "Column %d Sensor 2" % i,
                desc = "Entity ID for column %d, row 2" % i,
                icon = "gauge",
            ),
        ])

    return fields

def get_schema():
    fonts = [
        schema.Option(display = "Default", value = FONT_DEFAULT),
    ]
    fonts.extend([
        schema.Option(display = key, value = value)
        for key, value in sorted(render.fonts.items())
    ])

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ha_url",
                name = "Home Assistant URL",
                desc = "Full URL to your Home Assistant instance (e.g., http://homeassistant.local:8123)",
                icon = "home",
            ),
            schema.Text(
                id = "ha_token",
                name = "Home Assistant Token",
                desc = "Long-lived access token from User Settings",
                icon = "key",
                secret = True,
            ),
            schema.Dropdown(
                id = "column_count",
                name = "Number of Columns",
                desc = "How many columns to display (2-4)",
                icon = "table",
                options = [
                    schema.Option(display = "2 Columns", value = "2"),
                    schema.Option(display = "3 Columns", value = "3"),
                    schema.Option(display = "4 Columns", value = "4"),
                ],
                default = DEFAULT_COLUMN_COUNT,
            ),
            schema.Dropdown(
                id = "label_font",
                name = "Label Font",
                desc = "Font for column labels",
                icon = "font",
                options = fonts,
                default = FONT_DEFAULT,
            ),
            schema.Dropdown(
                id = "value_font",
                name = "Value Font",
                desc = "Font for sensor values",
                icon = "font",
                options = fonts,
                default = FONT_DEFAULT,
            ),
            schema.Color(
                id = "divider_color",
                name = "Divider Color",
                desc = "Color for column dividers",
                icon = "brush",
                default = DEFAULT_DIVIDER_COLOR,
            ),
            schema.Generated(
                id = "generated_columns",
                source = "column_count",
                handler = generate_column_fields,
            ),
        ],
    )
