"""
Applet: Zapier
Summary: Integrate with Zapier
Description: The Zapier app allows you to trigger information on your Tidbyt from a Zap.
Author: Tidbyt
"""

load("images/icon_generic.png", ICON_GENERIC_ASSET = "file")
load("images/icon_github.png", ICON_GITHUB_ASSET = "file")
load("images/icon_shopify.png", ICON_SHOPIFY_ASSET = "file")
load("images/icon_slack.png", ICON_SLACK_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    primary = config.str("primary", "")
    secondary = config.str("secondary", "")
    alternate = config.str("alternate", "")

    notification_type = config.str("type", DEFAULT_TYPE)
    icon = MESSAGE_TYPES[notification_type]["icon"]
    alt_color = MESSAGE_TYPES[notification_type]["color"]

    # Return if there is no primary text
    if primary == "":
        return []

    # Center core notification if there is no alt text.
    if alternate == "":
        return render.Root(
            child = render.Box(
                padding = 2,
                child = render.Column(
                    expanded = True,
                    main_align = "start",
                    children = [
                        render.Box(
                            height = 5,
                        ),
                        render_core(primary, secondary, icon),
                        render.Box(
                            height = 5,
                        ),
                    ],
                ),
            ),
        )

    # Render the full view if there is an alt text.
    return render.Root(
        child = render.Box(
            padding = 2,
            child = render.Column(
                expanded = True,
                main_align = "start",
                children = [
                    render_core(primary, secondary, icon),
                    render.Box(
                        height = 1,
                    ),
                    render.Marquee(
                        width = 60,
                        child = render.Text(
                            content = alternate.upper(),
                            color = alt_color,
                        ),
                    ),
                ],
            ),
        ),
    )

def render_core(primary, secondary, icon):
    if secondary == "":
        return render.Box(
            height = 20,
            child = render.Row(
                children = [
                    render.Image(
                        src = icon,
                        width = 16,
                        height = 18,
                    ),
                    render.Box(width = 2),
                    render.Column(
                        children = [
                            render.Box(height = 4),
                            render.Marquee(
                                width = 42,
                                child = render.Text(
                                    content = primary,
                                ),
                            ),
                        ],
                    ),
                ],
            ),
        )

    return render.Box(
        height = 20,
        child = render.Row(
            children = [
                render.Image(
                    src = icon,
                    width = 16,
                    height = 18,
                ),
                render.Box(width = 2),
                render.Column(
                    children = [
                        render.Marquee(
                            width = 42,
                            child = render.Text(
                                content = primary,
                            ),
                        ),
                        render.Box(height = 2),
                        render.Marquee(
                            width = 42,
                            child = render.Text(
                                content = secondary,
                                color = "#8C8C8C",
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = v["name"],
            value = k,
        )
        for k, v in MESSAGE_TYPES.items()
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "primary",
                name = "Primary Text",
                desc = "Primary message text.",
                icon = "heading",
            ),
            schema.Text(
                id = "secondary",
                name = "Secondary Text",
                desc = "Secondary message text.",
                icon = "font",
            ),
            schema.Text(
                id = "alternate",
                name = "Alternate Text",
                desc = "Secondary message text.",
                icon = "font",
            ),
            schema.Dropdown(
                id = "type",
                name = "Notification Type",
                desc = "The type of notification to display.",
                icon = "gear",
                default = DEFAULT_TYPE,
                options = options,
            ),
        ],
    )

DEFAULT_TYPE = "generic"

# To add an icon, create a 16x18 pixel png file and run the following and paste
# the results: cat icon.png | base64 | fold | pbcopy

GENERIC_ICON = ICON_GENERIC_ASSET.readall()

SLACK_ICON = ICON_SLACK_ASSET.readall()

SHOPIFY_ICON = ICON_SHOPIFY_ASSET.readall()

GITHUB_ICON = ICON_GITHUB_ASSET.readall()

MESSAGE_TYPES = {
    "generic": {
        "name": "Generic",
        "icon": GENERIC_ICON,
        "color": "#7AB0FF",
    },
    "slack": {
        "name": "Slack",
        "icon": SLACK_ICON,
        "color": "#2EB67D",
    },
    "shopify": {
        "name": "Shopify",
        "icon": SHOPIFY_ICON,
        "color": "#95BF47",
    },
    "github": {
        "name": "GitHub",
        "icon": GITHUB_ICON,
        "color": "#FFFFFF",
    },
}
