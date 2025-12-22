"""
Applet: On The Air
Summary: Notify of "On [The] Air" status
Description:  Displays "On [The] Air" sign that can be updated to let others know you're not available.
Author: Jake Harvey
"""

load("render.star", "render")
load("schema.star", "schema")

def main(config):
    display_status = config.get("display_state", opt_display_status[0].value)
    display_text = config.get("display_text", opt_display_text[0].value)
    outline_color = "#fff"
    text_color = "#fff"
    background_color = "#f00"

    display_items = []

    if display_status == "hide":
        return []
    elif display_status == "off":
        text_color = "#5b5c61"
        background_color = "#c80900"
        outline_color = "#5b5c61"

    display_items.append(render.Box(width = 64, height = 32, color = outline_color))

    if display_text == "on_the_air":
        typeface = "6x13"
        display_items.append(
            add_padding_to_child_element(
                render.Box(
                    width = 62,
                    height = 30,
                    color = background_color,
                    child = render.Row(
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text("ON", font = typeface, color = text_color),
                            render.Box(width = 2, height = 1),
                            render.Text("THE", font = typeface, color = text_color),
                            render.Box(width = 2, height = 1),
                            render.Text("AIR", font = typeface, color = text_color),
                        ],
                    ),
                ),
                1,
                1,
            ),
        )
    elif display_text == "on_air":
        # Original version
        display_items.append(add_padding_to_child_element(render.Box(width = 62, height = 30, color = background_color), 1, 1))
        display_items.append(add_padding_to_child_element(render.Text("ON", font = "10x20", color = text_color), 5, 7))
        display_items.append(add_padding_to_child_element(render.Text("AIR", font = "10x20", color = text_color), 28, 7))

    return render.Root(
        render.Stack(
            children = display_items,
        ),
    )

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )
    return padded_element

opt_display_text = [
    schema.Option(
        display = "ON THE AIR",
        value = "on_the_air",
    ),
    schema.Option(
        display = "ON AIR",
        value = "on_air",
    ),
    schema.Option(
        display = "Custom",
        value = "custom",
    ),
]

opt_display_status = [
    schema.Option(
        display = "On Air",
        value = "on",
    ),
    schema.Option(
        display = "Not On Air",
        value = "off",
    ),
    schema.Option(
        display = "Hide",
        value = "hide",
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "display_state",
                name = "Display State",
                desc = "What do you want to display?",
                icon = "stopwatch",
                options = opt_display_status,
                default = opt_display_status[0].value,
            ),
            schema.Dropdown(
                id = "display_text",
                name = "Display Text",
                desc = "Choose the text to display on the sign.",
                icon = "font",
                options = opt_display_text,
                default = opt_display_text[0].value,
            ),
        ],
    )
