"""
Applet: Grafana
Summary: Display Grafana Metrics
Description: Show value or graph of various Grafana metrics from your instance.
Author: tavdog
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

TTL_SECONDS = 300  # 5 minutes
DEFAULT_GRAFANA_URL = ""
DEFAULT_KEY = ""
DEFAULT_INSTANCE = ""
DEBUG = True  # Set to False to disable debug output
JSON_DUMMY_DATA = """{"status":"success","data":{"resultType":"matrix","result":[{"metric":{"__name__":"node_load1","instance":"default","job":"integrations/node_exporter"},"values":[[1763712213,"0.06"],[1763712228,"0.06"],[1763712243,"0.13"],[1763712258,"0.13"],[1763712273,"0.13"],[1763712288,"0.13"],[1763712303,"0.41"],[1763712318,"0.41"],[1763712333,"0.41"],[1763712348,"0.41"],[1763712363,"0.27"],[1763712378,"0.27"],[1763712393,"0.27"],[1763712408,"0.27"],[1763712423,"0.3"],[1763712438,"0.3"],[1763712453,"0.3"],[1763712468,"0.3"],[1763712483,"0.19"],[1763712498,"0.19"],[1763712513,"0.19"]]}]}}"""
YELLOW = "#ffff00"  # Firefly palette color
GREEN = "#ADFF2F"  # Firefly palette color
ORANGE = "#FF4500"  # Firefly palette color
BLUE = "#0000FF"  # Firefly palette color
RED = "#FF0000"

def main(config):
    grafana_url = config.str("grafana_url", DEFAULT_GRAFANA_URL)
    api_key = config.str("api_key", DEFAULT_KEY)
    instance = config.str("instance", DEFAULT_INSTANCE)
    metric = config.str("metric", "node_load1")
    hours = int(config.get("hours_history", 24))
    display_graph = config.bool("display_graph")
    step_interval = config.str("step_interval", "1m")

    # Get the metric data
    metric_data = get_metric_data(grafana_url, api_key, instance, metric, hours, display_graph, step_interval)

    # Parse value range filters
    feed_value_range = parse_range(config.get("feed_value_range", None))
    feed2_value_range = parse_range(config.get("feed2_value_range", None))

    # check for feed2
    feed2 = None
    display_graph2 = config.bool("display_graph2")
    metric2 = config.str("metric2", "")
    if metric2:
        feed2 = get_metric_data(grafana_url, api_key, instance, metric2, hours, display_graph2, step_interval)

    if "error" in metric_data or (feed2 and "error" in feed2):  # if we have error key, then we display an error
        error_dict = dict()
        if ("error" in metric_data):
            error_dict = metric_data
        if (feed2 and "error" in feed2):
            error_dict = feed2
        error_string = error_dict["error"]
        if ("url" in error_string.lower() or "invalid" in error_string.lower()):
            error_message = error_string
        else:
            error_message = "Metric not found"
        return render.Root(
            child = render.Box(
                render.Column(
                    expanded = True,
                    main_align = "space_around",
                    children = [
                        render.Text(
                            content = "Grafana Error",
                            font = "tb-8",
                            color = RED,
                        ),
                        render.WrappedText(
                            content = error_message,
                            font = "tb-8",
                            color = ORANGE,
                        ),
                    ],
                ),
            ),
        )

    else:
        #FEED
        # build the feed_graph
        feed_graph = None

        # print(metric_data)
        if config.bool("display_graph") and len(metric_data["data"]) > 3:  # only make the graph if we have more than 3 points
            # interate through the points and convert to float and stick them an array
            points = []
            for i in range(len(metric_data["data"])):
                points.append((i, float(metric_data["data"][i][1])))

            # print("points " + str(points))
            y_lim = (None, None)
            min_max = config.get("y_min_max", None)
            if min_max and "," in min_max:
                (min, max) = min_max.split(",")
                y_lim = (float(min), float(max))
            feed_graph = render.Plot(
                data = points,
                width = 64,
                height = 32,
                color = config.str("graph_color", "#00c"),
                y_lim = y_lim,
            )

        # build feed2_graph
        feed2_graph = None
        if config.bool("display_graph2") and feed2 and len(feed2["data"]) > 3:  # only make the graph if we have more than 3 points
            # interate through the points and convert to float and stick them an array
            points = []
            for i in range(len(feed2["data"])):
                points.append((i, float(feed2["data"][i][1])))

            # print("points " + str(points))
            y2_lim = (None, None)
            min_max = config.get("y2_min_max", None)
            if min_max and "," in min_max:
                (min, max) = min_max.split(",")
                y2_lim = (float(min), float(max))
            feed2_graph = render.Plot(
                data = points,
                width = 64,
                height = 32,
                color = config.str("graph2_color", "#00c"),
                y_lim = y2_lim,
            )

        # Check if feed values are in range - if not, return empty
        feed_value = float(metric_data["data"][-1][1])
        if not is_in_range(feed_value, feed_value_range):
            return []

        # Check if feed2 exists and is in range
        if feed2:
            feed2_value = float(feed2["data"][-1][1])
            if not is_in_range(feed2_value, feed2_value_range):
                return []

            # Both feeds in range - show both values
            data_line = render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Text(
                        content = str(round(feed_value, 1)) + config.get("feed_units", "") + " ",
                        font = "6x13",
                        color = config.str("feed_color", None) or ORANGE,
                    ),
                    render.Text(
                        content = str(round(feed2_value, 1)) + config.get("feed2_units", ""),
                        font = "6x13",
                        color = config.str("feed2_color", None) or BLUE,
                    ),
                ],
            )
        else:
            # Only feed1 and it's in range
            data_line = render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Text(
                        content = str(round(feed_value, 2)) + config.get("feed_units", ""),
                        font = "6x13",
                        color = config.str("feed_color", None) or ORANGE,
                    ),
                ],
            )

        return render.Root(
            child = render.Stack(
                children = [
                    feed_graph,
                    feed2_graph,
                    render.Box(
                        render.Column(
                            expanded = True,
                            main_align = "space_around",
                            children = [
                                render.Row(
                                    expanded = True,
                                    main_align = "center",
                                    children = [
                                        render.WrappedText(
                                            content = config.str("feed_name", None) or instance,
                                            font = "tb-8",
                                            color = config.str("feed_color", None) or GREEN,
                                        ),
                                    ],
                                ),
                                data_line,
                            ],
                        ),
                    ),
                ],
            ),
        )

def get_metric_data(grafana_url, api_key, instance, metric, hours, need_time_series, step_interval = "1m"):
    if not grafana_url or not api_key or not instance:
        dummy = json.decode(JSON_DUMMY_DATA)

        # Parse dummy data into AdafruitIO-compatible format
        if dummy.get("status") == "success" and "data" in dummy:
            result = dummy["data"]["result"][0] if dummy["data"]["result"] else None
            if result and "values" in result:
                return {
                    "feed": {
                        "id": 1,
                        "name": instance,
                        "key": instance,
                    },
                    "data": [[str(v[0]), str(v[1])] for v in result["values"]],
                }
        return {"error": "No dummy data available"}

    # Build Prometheus query with the user-specified metric
    query = "%s{instance=\"%s\"}" % (metric, instance)

    if DEBUG:
        print("DEBUG: Query:", query)

    # If we need time series data (for graphs), use query_range
    # Otherwise use instant query which is faster
    if need_time_series:
        # Calculate time range for query
        now = time.now()
        end_time = int(now.unix)
        start_time = end_time - (hours * 3600)

        # Query range endpoint for time series data
        url = "https://%s/api/datasources/proxy/uid/grafanacloud-prom/api/v1/query_range?query=%s&start=%d&end=%d&step=%s" % (
            grafana_url,
            query,
            start_time,
            end_time,
            step_interval,
        )
    else:
        # Instant query endpoint for single value
        url = "https://%s/api/datasources/proxy/uid/grafanacloud-prom/api/v1/query?query=%s" % (
            grafana_url,
            query,
        )

    if DEBUG:
        print("DEBUG: Fetching metric from URL:", url)
        print("DEBUG: Using Bearer token:", api_key[:10] + "..." if len(api_key) > 10 else api_key)

    res = http.get(
        url,
        headers = {"Authorization": "Bearer " + api_key},
        ttl_seconds = TTL_SECONDS,
    )

    if res.status_code != 200:
        if DEBUG:
            print("DEBUG: API error - status code:", res.status_code)
            print("DEBUG: Response body:", res.body())
        return {"error": "API returned status %d" % res.status_code}

    data = res.json()
    if DEBUG:
        print("DEBUG: API Response:", data)

    if data.get("status") == "success" and "data" in data:
        results = data["data"].get("result", [])
        if not results:
            if DEBUG:
                print("DEBUG: No results found in response")
            return {"error": "No data returned for query"}

        # Get first result
        result = results[0]

        # Check if this is an instant query (single value) or range query (time series)
        if "value" in result:
            # Instant query returns: {"value": [timestamp, "value"]}
            value = result["value"]
            return {
                "feed": {
                    "id": 1,
                    "name": instance,
                    "key": instance,
                },
                "data": [[str(value[0]), str(value[1])]],
            }
        elif "values" in result:
            # Range query returns: {"values": [[timestamp, "value"], ...]}
            values = result["values"]
            if not values:
                return {"error": "No values in result"}

            return {
                "feed": {
                    "id": 1,
                    "name": instance,
                    "key": instance,
                },
                "data": [[str(v[0]), str(v[1])] for v in values],
            }
        else:
            return {"error": "Unexpected result format"}

    return {"error": "Invalid response format"}

def parse_range(range_str):
    """Parse a min-max range string like '10-20' into a tuple (min, max).
    Returns None if range_str is empty or invalid."""
    if not range_str:
        return None
    if "-" in range_str:
        parts = range_str.split("-")
        if len(parts) == 2:
            if parts[0] and parts[1]:
                # Use float() directly - if it fails, the app will show an error
                return (float(parts[0]), float(parts[1]))
    return None

def is_in_range(value, range_tuple):
    """Check if a value is within the specified range.
    If range_tuple is None, always returns True (no filtering)."""
    if not range_tuple:
        return True
    min_val = range_tuple[0]
    max_val = range_tuple[1]
    return value >= min_val and value <= max_val

def get_metric_dropdown(api_key, config):
    """Generate metric dropdown options from Grafana API"""
    if DEBUG:
        print("DEBUG: get_metric_dropdown called with api_key length:", len(api_key) if api_key else 0)

    if not api_key:
        if DEBUG:
            print("DEBUG: No api_key provided, returning empty list")
        return []

    grafana_url = config.str("grafana_url", "")
    if DEBUG:
        print("DEBUG: grafana_url from config:", grafana_url)

    if not grafana_url:
        if DEBUG:
            print("DEBUG: No grafana_url provided, returning empty list")
        return []

    # Fetch available metrics from Grafana
    url = "https://%s/api/datasources/proxy/uid/grafanacloud-prom/api/v1/label/__name__/values" % grafana_url

    if DEBUG:
        print("DEBUG: Fetching metrics from:", url)

    res = http.get(
        url,
        headers = {"Authorization": "Bearer " + api_key},
        ttl_seconds = TTL_SECONDS,
    )

    if DEBUG:
        print("DEBUG: Metrics API response status:", res.status_code)

    if res.status_code != 200:
        if DEBUG:
            print("DEBUG: Failed to fetch metrics, status:", res.status_code)
        return []

    data = res.json()
    if DEBUG:
        print("DEBUG: Metrics response status field:", data.get("status"))
        print("DEBUG: Number of metrics in response:", len(data.get("data", [])))

    options = []
    if data.get("status") == "success" and "data" in data:
        metrics = data["data"]
        if DEBUG:
            print("DEBUG: First 5 metrics:", metrics[:5])
        options = [
            schema.Option(display = metric, value = metric)
            for metric in metrics[:100]  # Limit to first 100 metrics
        ]
        if DEBUG:
            print("DEBUG: Created", len(options), "options for dropdown")

    if not options:
        if DEBUG:
            print("DEBUG: No options created, using default node_load1")
        options = [schema.Option(display = "node_load1", value = "node_load1")]

    if DEBUG:
        print("DEBUG: Returning dropdown with", len(options), "options")

    if DEBUG:
        print("DEBUG: About to check for selected metric")

    result = [
        schema.Dropdown(
            id = "metric",
            name = "Metric",
            desc = "Select Prometheus metric to query",
            icon = "chartLine",
            default = options[0].value if options else "node_load1",
            options = options,
        ),
    ]

    # Get the currently selected metric from config to show additional fields
    selected_metric = config.str("metric", "")
    if DEBUG:
        print("DEBUG: Currently selected metric from config:", selected_metric)
        print("DEBUG: selected_metric bool:", bool(selected_metric))

    if selected_metric:
        if DEBUG:
            print("DEBUG: Adding config fields for metric:", selected_metric)
        config_fields = get_config_fields_list(config)
        if DEBUG:
            print("DEBUG: Got", len(config_fields), "config fields")
        result.extend(config_fields)
    elif DEBUG:
        print("DEBUG: No metric selected, not adding config fields")

    if DEBUG:
        print("DEBUG: Returning", len(result), "total fields")

    return result

def get_config_fields_list():
    """Return list of configuration fields"""
    fields = [
        schema.Text(
            id = "feed_name",
            name = "Chart Label",
            icon = "tag",
            desc = "Optional Custom Label",
            default = "Grafana",
        ),
        schema.Color(
            id = "feed_color",
            name = "Metric 1 Color",
            desc = "Text Color",
            icon = "brush",
            default = "#b07f51",
        ),
        schema.Text(
            id = "feed_units",
            name = "Metric Units",
            icon = "quoteRight",
            desc = "Metric units (e.g., %, MB, req/s)",
        ),
        schema.Text(
            id = "feed_value_range",
            name = "Value Range Filter",
            icon = "filter",
            desc = "Only show app if in range (e.g., '10-20'). Leave blank to always show.",
            default = "",
        ),
        schema.Toggle(
            id = "display_graph",
            name = "Display Graph",
            desc = "A toggle to display the graph data in the background",
            icon = "compress",
            default = True,
        ),
        schema.Color(
            id = "graph_color",
            name = "Graph Color",
            desc = "Graph Color",
            icon = "brush",
            default = "#304463",
        ),
        schema.Text(
            id = "hours_history",
            name = "Graph history hours",
            desc = "",
            icon = "compress",
            default = "",
        ),
        schema.Text(
            id = "step_interval",
            name = "Data Point Interval",
            desc = "Time between data points (e.g., 15s, 1m, 5m, 1h)",
            icon = "clock",
            default = "1m",
        ),
        schema.Text(
            id = "y_min_max",
            name = "Graph min,max",
            desc = "Scale the graph by setting min and max. Leave blank to disable",
            icon = "compress",
            default = "",
        ),
    ]

    fields.append(
        schema.Text(
            id = "metric2",
            name = "Metric 2 (Optional)",
            desc = "Second Prometheus metric name (optional)",
            icon = "chartLine",
            default = "",
        ),
    )

    fields.extend([
        schema.Color(
            id = "feed2_color",
            name = "Metric 2 Color",
            desc = "Metric Color",
            icon = "brush",
            default = "#5c9949",
        ),
        schema.Text(
            id = "feed2_name",
            name = "Metric 2 Name",
            icon = "tag",
            desc = "Optional Custom Label",
            default = "",
        ),
        schema.Text(
            id = "feed2_units",
            name = "Metric 2 Units",
            icon = "quoteRight",
            desc = "Metric units preference",
        ),
        schema.Text(
            id = "feed2_value_range",
            name = "Metric 2 Value Range Filter",
            icon = "filter",
            desc = "Only show app if in range (e.g., '10-20'). Leave blank to always show.",
            default = "",
        ),
        schema.Toggle(
            id = "display_graph2",
            name = "Show Graph 2",
            desc = "A toggle to display the graph data in the background",
            icon = "compress",
            default = False,
        ),
        schema.Color(
            id = "graph2_color",
            name = "Graph 2 Color",
            desc = "Graph 2 Color",
            icon = "brush",
            default = "#5c4796",
        ),
        schema.Text(
            id = "y2_min_max",
            name = "Graph 2 min,max",
            desc = "Scale the graph by setting min and max. Leave blank to disable",
            icon = "compress",
            default = "",
        ),
    ])

    return fields

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "grafana_url",
                name = "Grafana Host",
                desc = "Grafana hostname (e.g., tronbyt.grafana.net)",
                icon = "server",
            ),
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "Grafana API Key or Service Account Token",
                icon = "key",
            ),
            schema.Text(
                id = "instance",
                name = "Instance",
                desc = "Instance name to query",
                icon = "server",
                default = "default",
            ),
            schema.Generated(
                id = "metric_gen",
                source = "api_key",
                handler = get_metric_dropdown,
            ),
        ],
    )

def round(num, precision):
    """Round a float to the specified number of significant digits"""
    return math.round(num * math.pow(10, precision)) / math.pow(10, precision)
