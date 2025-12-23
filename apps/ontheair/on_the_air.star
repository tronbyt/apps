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
    elif display_text == "custom":
        # Insert some custom text into the space
        custom_text = config.get("display_text_custom", "")
        custom_text_length = len(custom_text)
        custom_text_align = config.get("custom_text_align", opt_custom_text_align[0].value)

        typeface = "tb-8"

        if custom_text_length > 30:
            typeface = "CG-pixel-3x5-mono"

        #if custom_text_length <= 6:
        #    typeface = "10x20"
        #elif custom_text_length > 6:
        #    typeface = "6x13"
        #elif custom_text_length > 18:
        #    typeface = "tb-8"
        #elif custom_text_length > 30:
        #    typeface = "CG-pixel-3x5-mono"

        display_items.append(
            add_padding_to_child_element(
                render.Row(
                    main_align = custom_text_align,
                    cross_align = "center",
                    children = [
                        render.Box(
                            width = 62,
                            height = 30,
                            color = background_color,
                            child = render.WrappedText(
                                content = custom_text,
                                font = typeface,
                                color = text_color,
                                align = custom_text_align,
                                linespacing = 1,
                                width = 61,
                            ),
                        ),
                    ],
                ),
                1,
                1,
            ),
        )

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

opt_custom_text_align = [
    schema.Option(
        display = "Center",
        value = "center",
    ),
    schema.Option(
        display = "Left",
        value = "left",
    ),
    schema.Option(
        display = "Right",
        value = "right",
    ),
]

def more_options(display_text):
    if display_text == "custom":
        return [
            schema.Text(
                id = "display_text_custom",
                name = "Custom Text",
                desc = "Enter your own text. Try to keep it short.",
                icon = "gear",
                default = "RECORDING...",
            ),
            schema.Dropdown(
                id = "custom_text_align",
                name = "Custom Text Alignment",
                desc = "Choose the alignment for your custom text.",
                icon = "gear",
                options = opt_custom_text_align,
                default = opt_custom_text_align[0].value,
            ),
        ]
    elif display_text == "cat":
        return [
            schema.Toggle(
                id = "litter-box",
                name = "Litter Box",
                desc = "A toggle to enable a litter box.",
                icon = "gear",
                default = False,
            ),
        ]
    else:
        return []

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
            schema.Generated(
                id = "generated",
                source = "display_text",
                handler = more_options,
            ),
        ],
    )
