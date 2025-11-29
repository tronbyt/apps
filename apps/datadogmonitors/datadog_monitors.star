"""
Applet: DataDog Monitors
Summary: View your DataDog Monitors
Description: By default displays any monitors that are in the status alert but allows for customizing the query yourself based on DataDog's syntax.
Author: Cavallando
"""
# I'm new to starlark, sorry if this looks bad :)

load("animation.star", "animation")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/alert_icon.png", ALERT_ICON_ASSET = "file")
load("images/check_icon.png", CHECK_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

ALERT_ICON = ALERT_ICON_ASSET.readall()
CHECK_ICON = CHECK_ICON_ASSET.readall()

CACHE_KEY_PREFIX = "monitors_cached"
DEFAULT_QUERY = "status:alert"
DEFAULT_APP_KEY = None
DEFAULT_API_KEY = None

def main(config):
    DD_SITE = config.get("dd_site") or "datadoghq.com"
    DD_API_URL = "https://api.{}/api/v1".format(DD_SITE)
    DD_API_KEY = config.get("api_key") or DEFAULT_API_KEY
    DD_APP_KEY = config.get("app_key") or DEFAULT_APP_KEY

    CACHE_KEY = "{}-{}-{}".format(CACHE_KEY_PREFIX, DD_API_KEY, DD_APP_KEY)
    monitors_query = config.str("custom_query", DEFAULT_QUERY)

    monitors_cached = cache.get(CACHE_KEY)

    if monitors_cached != None:
        data = json.decode(monitors_cached)
    elif DD_API_KEY != None and DD_APP_KEY != None:
        data = http.get(
            "{}/monitor/search".format(DD_API_URL),
            params = {"query": monitors_query},
            headers = {"DD-API-KEY": DD_API_KEY, "DD-APPLICATION-KEY": DD_APP_KEY, "Accept": "application/json"},
        ).json()

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(CACHE_KEY, json.encode(data), ttl_seconds = 240)
    else:
        data = {"monitors": []}

    success_image = render.Image(src = CHECK_ICON, height = 20, width = 20)
    error_image = render.Image(width = 18, height = 18, src = ALERT_ICON)

    if (data.get("monitors") == None):
        child = render.Row(
            cross_align = "center",
            main_align = "center",
            children = [
                error_image,
                render.WrappedText(align = "center", content = "Could not connect to DataDog"),
            ],
        )
    else:
        monitors = list(data.get("monitors"))

        child = render.Row(
            expanded = True,
            cross_align = "center",
            main_align = "center",
            children = [
                render.Box(child = success_image, width = 18),
                render.Text(content = "No issues!"),
            ],
        )

        if (len(monitors) > 0):
            keyframes = [
                animation.Keyframe(
                    percentage = 0.0,
                    transforms = [animation.Translate(-100, 0)],
                    curve = "linear",
                ),
                animation.Keyframe(
                    percentage = 0.25,
                    transforms = [animation.Translate(0, 0)],
                    curve = "linear",
                ),
                animation.Keyframe(
                    percentage = 0.75,
                    transforms = [animation.Translate(0, 0)],
                    curve = "linear",
                ),
                animation.Keyframe(
                    percentage = 1,
                    transforms = [animation.Translate(100, 0)],
                    curve = "linear",
                ),
            ]
            children = []
            for monitor in monitors:
                children.append(
                    animation.Transformation(
                        duration = 150,
                        child = render.WrappedText(width = 25, height = 25, content = monitor.get("name", "Monitor Triggered")),
                        keyframes = keyframes,
                    ),
                )
            child = render.Row(
                expanded = False,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Box(width = 18, height = 18, child = render.Image(width = 18, height = 18, src = ALERT_ICON)),
                    render.Sequence(children = children),
                ],
            )

    return render.Root(child = child)

def get_schema():
    dd_site_options = [
        schema.Option(
            display = "US1",
            value = "datadoghq.com",
        ),
        schema.Option(
            display = "US3",
            value = "us3.datadoghq.com",
        ),
        schema.Option(
            display = "US5",
            value = "us5.datadoghq.com",
        ),
        schema.Option(
            display = "EU",
            value = "datadoghq.eu",
        ),
        schema.Option(
            display = "Gov",
            value = "ddog-gov.com",
        ),
        schema.Option(
            display = "Japan",
            value = "ap1.datadoghq.com",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "dd_site",
                name = "Datadog Site",
                desc = "Datadog Site",
                icon = "globe",
                default = dd_site_options[0].value,
                options = dd_site_options,
            ),
            schema.Text(
                id = "api_key",
                name = "DataDog API Key",
                desc = "API Key from your settings",
                icon = "lock",
                default = "",
                secret = True,
            ),
            schema.Text(
                id = "app_key",
                name = "DataDog Application Key",
                desc = "A DataDog user account Application Key generated by the user",
                icon = "lock",
                default = "",
                secret = True,
            ),
            schema.Text(
                id = "custom_query",
                name = "Override Query",
                desc = "Override completely searching for monitors",
                icon = "magnifyingGlass",
                default = DEFAULT_QUERY,
            ),
        ],
    )
