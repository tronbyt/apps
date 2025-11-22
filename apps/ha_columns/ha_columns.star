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

def _get_default_fonts(column_count, scale):
    if column_count >= 4:
        label_font = "terminus-12" if scale == 2 else "tom-thumb"
        value_font = "terminus-14" if scale == 2 else "tb-8"
    elif column_count >= 3:
        label_font = "terminus-12" if scale == 2 else "tb-8"
        value_font = "terminus-16" if scale == 2 else "tb-8"
    else:
        label_font = DEFAULT_LABEL_FONT_2X if scale == 2 else DEFAULT_LABEL_FONT
        value_font = DEFAULT_VALUE_FONT_2X if scale == 2 else DEFAULT_VALUE_FONT

    return label_font, value_font

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

        if sensor1 == None:
            sensor1 = {"value": None, "unit": ""}
        if sensor2 == None:
            sensor2 = {"value": None, "unit": ""}

        sensor1_decimals = int(config.get("col%d_sensor1_decimals" % i, "1"))
        sensor2_decimals = int(config.get("col%d_sensor2_decimals" % i, "1"))
        sensor1_unit_override = config.get("col%d_sensor1_unit" % i, "")
        sensor2_unit_override = config.get("col%d_sensor2_unit" % i, "")

        columns.append({
            "label": label,
            "label_color": label_color,
            "value_color": value_color,
            "sensor1": sensor1,
            "sensor2": sensor2,
            "sensor1_decimals": sensor1_decimals,
            "sensor2_decimals": sensor2_decimals,
            "sensor1_unit_override": sensor1_unit_override,
            "sensor2_unit_override": sensor2_unit_override,
        })

    label_font = config.get("label_font")
    value_font = config.get("value_font")
    if not label_font or label_font == FONT_DEFAULT or not value_font or value_font == FONT_DEFAULT:
        default_label_font, default_value_font = _get_default_fonts(column_count, scale)
        if not label_font or label_font == FONT_DEFAULT:
            label_font = default_label_font
        if not value_font or value_font == FONT_DEFAULT:
            value_font = default_value_font

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

    isnum = state.strip().lstrip("-").replace(".", "", 1).isdigit()
    if not isnum:
        return None

    attributes = data.get("attributes", {})
    unit = attributes.get("unit_of_measurement", "")

    return {
        "value": float(state),
        "unit": unit if unit else "",
    }

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
                col["sensor1_decimals"],
                col["sensor2_decimals"],
                col["sensor1_unit_override"],
                col["sensor2_unit_override"],
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

def render_column(label, label_color, sensor1_data, sensor2_data, sensor1_decimals, sensor2_decimals, sensor1_unit_override, sensor2_unit_override, label_font, value_font, value_color, scale):
    sensor1_value = sensor1_data["value"]
    sensor2_value = sensor2_data["value"]

    if sensor1_value == None:
        sensor1_text = "N/A"
    else:
        if sensor1_decimals == 0:
            sensor1_formatted = str(int(math.round(sensor1_value)))
        elif sensor1_decimals == 1:
            sensor1_formatted = str(math.round(sensor1_value * 10) / 10)
        else:
            sensor1_formatted = str(math.round(sensor1_value * 100) / 100)

        sensor1_unit = sensor1_unit_override if sensor1_unit_override else sensor1_data["unit"]
        sensor1_text = sensor1_formatted + sensor1_unit if scale == 2 else sensor1_formatted

    if sensor2_value == None:
        sensor2_text = "N/A"
    else:
        if sensor2_decimals == 0:
            sensor2_formatted = str(int(math.round(sensor2_value)))
        elif sensor2_decimals == 1:
            sensor2_formatted = str(math.round(sensor2_value * 10) / 10)
        else:
            sensor2_formatted = str(math.round(sensor2_value * 100) / 100)

        sensor2_unit = sensor2_unit_override if sensor2_unit_override else sensor2_data["unit"]
        sensor2_text = sensor2_formatted + sensor2_unit if scale == 2 else sensor2_formatted

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
                sensor1_text,
                font = value_font,
                color = value_color,
            ),
            render.Text(
                sensor2_text,
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
            schema.Dropdown(
                id = "col%d_sensor1_decimals" % i,
                name = "Column %d Sensor 1 Decimals" % i,
                desc = "Decimal places for sensor 1",
                icon = "gear",
                options = [
                    schema.Option(display = "0 decimals", value = "0"),
                    schema.Option(display = "1 decimal", value = "1"),
                    schema.Option(display = "2 decimals", value = "2"),
                ],
                default = "1",
            ),
            schema.Text(
                id = "col%d_sensor1_unit" % i,
                name = "Column %d Sensor 1 Unit" % i,
                desc = "Override unit for sensor 1 (leave blank to use HA unit)",
                icon = "tag",
                default = "",
            ),
            schema.Text(
                id = "col%d_sensor2_entity" % i,
                name = "Column %d Sensor 2" % i,
                desc = "Entity ID for column %d, row 2" % i,
                icon = "gauge",
            ),
            schema.Dropdown(
                id = "col%d_sensor2_decimals" % i,
                name = "Column %d Sensor 2 Decimals" % i,
                desc = "Decimal places for sensor 2",
                icon = "gear",
                options = [
                    schema.Option(display = "0 decimals", value = "0"),
                    schema.Option(display = "1 decimal", value = "1"),
                    schema.Option(display = "2 decimals", value = "2"),
                ],
                default = "1",
            ),
            schema.Text(
                id = "col%d_sensor2_unit" % i,
                name = "Column %d Sensor 2 Unit" % i,
                desc = "Override unit for sensor 2 (leave blank to use HA unit)",
                icon = "tag",
                default = "",
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
