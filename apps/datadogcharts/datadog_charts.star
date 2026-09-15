"""
Applet: DataDog Charts
Summary: View your DataDog Dashboard Charts
Description: By default, displays the first chart on your DataDog dashboard.
Author: Gabe Ochoa
"""

load("http.star", "http")
load("images/img_365abaca.bin", IMG_365abaca_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Set your DataDog API and App keys here for development
DEFAULT_APP_KEY = None
DEFAULT_API_KEY = None
DEFAULT_DASHBOARD_ID = ""

DATADOG_ICON = IMG_365abaca_ASSET.readall()

def main(config):
    # Setup and validate config
    DD_SITE = config.get("dd_site") or "datadoghq.com"
    DD_API_URL = "https://api.{}/api/v1".format(DD_SITE)
    DD_API_KEY = config.get("api_key") or DEFAULT_API_KEY
    DD_APP_KEY = config.get("app_key") or DEFAULT_APP_KEY
    DASHBOARD_ID = config.get("dashboard_id") or DEFAULT_DASHBOARD_ID
    SHOW_LAST_VALUE = config.bool("show_last_value", True)
    CHART_TIME_RANGE = config.get("chart_time_range") or "1h"
    CHART_NAME = config.get("chart_name")

    ## APIs
    DD_DASHBOARD_API = "{}/dashboard".format(DD_API_URL)
    DD_METRICS_QUERY_API = "{}/query".format(DD_API_URL)

    if DD_API_KEY == None or DD_APP_KEY == None:
        return renderer("Set Datadog API and APP Key", fake_chart_data())

    print("Making request to {}/{}".format(DD_DASHBOARD_API, DASHBOARD_ID))
    dashboard_json = http.get(
        "{}/{}".format(DD_DASHBOARD_API, DASHBOARD_ID),
        headers = {"DD-API-KEY": DD_API_KEY, "DD-APPLICATION-KEY": DD_APP_KEY, "Accept": "application/json"},
        ttl_seconds = 6000,
    ).json()

    if dashboard_json.get("errors") != None:
        child = render.Row(
            cross_align = "center",
            main_align = "center",
            children = [
                render.WrappedText(content = dashboard_json.get("errors")[0]),
            ],
        )
        return render.Root(child = child)

    # Select the wideget to display from the chart name
    widget = None
    for w in dashboard_json.get("widgets"):
        if w.get("definition").get("title") == CHART_NAME:
            widget = w
            break

    # If no chart name was provided, use the first widget
    if widget == None:
        for w in dashboard_json.get("widgets"):
            if w.get("definition", {}).get("type") == "timeseries":
                widget = w
                break

    # check if the widget is a timeseries and if not, show an error
    if widget.get("definition").get("type") != "timeseries":
        child = render.Row(
            cross_align = "center",
            main_align = "center",
            children = [
                render.WrappedText(content = "Requested widget on dashboard is not a timeseries."),
            ],
        )
        return render.Root(child = child)

    # get the panel options
    title = widget.get("definition").get("title")
    query = widget.get("definition").get("requests")[0].get("queries")[0].get("query")

    # Query metrics API to get the list of points to plot

    # Compute the time range for the chart
    chart_time_range_seconds = time.parse_duration(CHART_TIME_RANGE).seconds
    to_time = time.now().unix
    from_time = to_time - chart_time_range_seconds

    print("Making query to DataDog API: ", query, str(from_time), str(to_time))
    query_response = http.get(
        DD_METRICS_QUERY_API,
        params = {"from": str(from_time), "to": str(to_time), "query": query},
        headers = {"DD-API-KEY": DD_API_KEY, "DD-APPLICATION-KEY": DD_APP_KEY, "Accept": "application/json"},
        ttl_seconds = 600,
    ).json()

    # Check if we got data, if not, show an error
    if len(query_response.get("series")) == 0:
        print("No data returned from query.")
        print(query_response)
        child = render.Row(
            cross_align = "center",
            main_align = "center",
            children = [
                render.WrappedText(content = "No data returned from query."),
            ],
        )
        return render.Root(child = child)
    elif query_response == None:
        # The Datadog API sometimes returns > 50MB of data which causes a context deadline exceeded error
        print("Error fetching data. Possibly too large of a response.")
        print(query_response)
        child = render.Marquee(
            width = 48,
            child = render.Text(content = "Error fetching data. Possibly too large of a response.", font = "6x13", color = "#fff"),
        )
        return render.Root(child = child)

    # Get the data from the response
    raw_points = query_response.get("series")[0].get("pointlist")

    # Convert datapoints into List[Tuple[float, float]]
    datapoints = []
    for point in raw_points:
        datapoints.append((point[0], point[1]))

    # Add the last value to the title
    if SHOW_LAST_VALUE:
        # convert scientific notation to decimal
        datapoint = "{}".format(datapoints[-1][1]).split(".")[0]
        title = "Last value: {}".format(datapoint)

    return renderer(title, datapoints)

def renderer(display_name, datapoints):
    logo = render.Image(src = DATADOG_ICON, width = 16, height = 16)
    text = render.Marquee(
        width = 48,
        child = render.Text(content = display_name, font = "6x13", color = "#fff"),
    )
    plot_row = render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "end",
        children = [
            render.Plot(
                data = datapoints,
                fill = True,
                width = 60,
                height = 24,
                color = "#0f0",
                color_inverted = "#f00",
            ),
        ],
    )

    empty_row = render.Column(
        main_align = "space_between",
        cross_align = "center",
        children = [],
    )

    top_row_columns_left = render.Column(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [logo],
    )
    top_row_columns_right = render.Column(
        expanded = True,
        cross_align = "center",
        children = [text],
    )

    top_row = render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [top_row_columns_left, top_row_columns_right],
    )
    bottom_row = render.Column(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [empty_row, plot_row],
    )

    root = render.Stack(
        children = [bottom_row, top_row],
    )

    return render.Root(child = root)

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

    chat_time_range_options = [
        schema.Option(
            display = "1 Hour",
            value = "1h",
        ),
        schema.Option(
            display = "4 Hours",
            value = "4h",
        ),
        schema.Option(
            display = "1 Day",
            value = "24h",
        ),
        schema.Option(
            display = "1 Week",
            value = "168h",
        ),
        schema.Option(
            display = "1 Month",
            value = "5040h",
        ),
        schema.Option(
            display = "3 Month",
            value = "15120h",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            # Datadog Site Options
            # https://docs.datadoghq.com/getting_started/site/
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
                name = "API Key",
                desc = "DataDog API Key",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "app_key",
                name = "App Key",
                desc = "DataDog App Key",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "dashboard_id",
                name = "Dashboard ID",
                desc = "DataDog Dashboard ID",
                icon = "key",
            ),
            schema.Text(
                id = "chart_name",
                name = "Chart Name",
                desc = "Name of the chart. If not provided or not found, the first chart on the dashboard will be used.",
                icon = "chartLine",
            ),
            schema.Dropdown(
                id = "chart_time_range",
                name = "Chart Time Range",
                desc = "The time range to query for the chart",
                icon = "clock",
                default = chat_time_range_options[0].value,
                options = chat_time_range_options,
            ),
            schema.Toggle(
                id = "show_last_value",
                name = "Show Chart Last Value or Name",
                desc = "Toggle showing the chart last value or name in the scrolling text",
                icon = "dashcube",
                default = True,
            ),
        ],
    )

def fake_chart_data():
    return [(1, 1), (2, 2), (3, 3), (4, 4), (5, 5), (6, 6), (7, 7), (8, 8)]
