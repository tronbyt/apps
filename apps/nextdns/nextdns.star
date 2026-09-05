"""
Applet: NextDNS
Summary: NextDNS Account Stats
Description: Displays NextDNS account total query & total blocked query counts + 7-day activity graph.
Author: ndhotsky
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("images/nextdns_logo.png", NEXTDNS_LOGO_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

NEXTDNS_LOGO = NEXTDNS_LOGO_ASSET.readall()

# Endpoints
BASE_URL = "https://api.nextdns.io"
TIME_SERIES_URL = ";series?"
ANALYTICS_STATUS_ENDPOINT = "/profiles/{}/analytics/status"

# STYLING
GREEN = "#00cc00"
RED = "#ff4136"

def build_get_request(endpoint, api_key, **kwargs):
    """
    Builds the URL and headers component of an HTTP GET request

    Args:
        endpoint: NextDNS endpoint
        api_key: NextDNS account api key
        **kwargs: optionally specify additional arggs to append to the url for time series requests

    Returns:
        URL string and headers dictionary containing NextDNS API key
    """
    suffix = ""

    if kwargs.get("since"):
        suffix = TIME_SERIES_URL + "from={}".format(kwargs["since"])
        if kwargs.get("interval"):
            suffix = suffix + "&interval={}".format(kwargs["interval"])
        if kwargs.get("limit"):
            suffix = suffix + "&limit={}".format(kwargs["limit"])

    url = BASE_URL + endpoint + suffix
    headers = {"X-Api-Key": api_key}

    return url, headers

def query_nextdns(api_key, profile_id, endpoint, **kwargs):
    """
    Queries NextDNS' API with caching enabled

    Args:
        api_key: NextDNS API key
        profile_id: NextDNS profile id
        endpoint: NextDNS API endpoint
        **kwargs: Used to specify NextDNS API url parameters when applicable

    Returns:
        New or cached JSON response from NextDNS
    """
    endpoint = endpoint.format(profile_id)
    url, headers = build_get_request(endpoint, api_key, since = kwargs.get("since", None), interval = kwargs.get("interval", None), limit = kwargs.get("limit", None))

    resp = http.get(url, headers = headers, ttl_seconds = 240)
    if resp.status_code != 200:
        fail("NextDNS %s request failed with status %d", endpoint, resp.status_code)

    return resp.json()

def create_plot(datapoints):
    """
    Generates plot data from supplied datapoints

    Args:
        datapoints: list of floats

    Returns:
        list of tuples (index, datapoint_to_display)
    """
    plot = []
    index = 0

    for query_ct in datapoints:
        plot.append((index, query_ct))
        index += 1

    return plot

def get_secrets(config):
    """
    Loads secrets from configuration entries

    Fatal error is raised if either secret returns a blank value

    Args:
        config: user-defined config values from the Tidbyt interface

    Returns:
        Dictionary containing `profile_id` and `api_key` secrets
    """
    profile_id = config.get("profile_id", "").strip()
    api_key = config.get("api_key", "").strip()

    if profile_id == "" or api_key == "":
        return render.Root(
            child = render.WrappedText(
                "Missing NextDNS profile id or api key value: please configure and restart app",
                color = "#ff0000",
            ),
        )

    return {
        "profile_id": profile_id,
        "api_key": api_key,
    }

def main(config):
    """
    Queries the analytics status NextDNS for total queries and total blocked, and plots the last 7 days of activity

    Args:
        config: user-defined config values from the Tidbyt interface

    Returns:
        Rendered pixlet
    """
    secrets = get_secrets(config)
    if type(secrets) == "Root":
        return secrets

    # get stats
    analytics = query_nextdns(secrets["api_key"], secrets["profile_id"], ANALYTICS_STATUS_ENDPOINT)
    total_queries = humanize.float("#,###.", math.round(analytics["data"][0]["queries"]))
    total_blocked = humanize.float("#,###.", math.round(analytics["data"][1]["queries"]))

    # get plots
    graph = query_nextdns(secrets["api_key"], secrets["profile_id"], ANALYTICS_STATUS_ENDPOINT, since = "-7d", interval = "10800", limit = 7)
    total_queries_plot = create_plot(graph["data"][0]["queries"])
    blocked_queries_plot = create_plot(graph["data"][1]["queries"])

    return render.Root(
        render.Column(
            expanded = True,
            main_align = "space_between",
            children = [
                render.Padding(
                    pad = (2, 1, 1, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "space_between",
                        children = [
                            render.Column(
                                children = [
                                    render.Text("NEXT", font = "5x8"),
                                    render.Row(
                                        children = [
                                            render.Text("DNS", font = "5x8"),
                                            render.Image(NEXTDNS_LOGO, width = 7),
                                        ],
                                    ),
                                ],
                            ),
                            render.Column(
                                cross_align = "end",
                                children = [
                                    render.Text(str(total_queries)),
                                    render.Text(str(total_blocked), color = RED),
                                ],
                            ),
                        ],
                    ),
                ),
                render.Row(
                    expanded = True,
                    children = [
                        render.Stack(
                            children = [
                                render.Plot(
                                    data = total_queries_plot[1:],
                                    width = 64,
                                    height = 14,
                                    color = GREEN,
                                    fill = True,
                                    y_lim = (0, max(graph["data"][0]["queries"])),
                                ),
                                render.Plot(
                                    data = blocked_queries_plot[1:],
                                    width = 64,
                                    height = 14,
                                    color = RED,
                                    fill = True,
                                    fill_color = "#660500",
                                    y_lim = (0, max(graph["data"][1]["queries"]) * 3),
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "profile_id",
                name = "Profile ID",
                desc = "NextDNS profile ID value",
                icon = "user",
            ),
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "NextDNS API key value",
                icon = "key",
                secret = True,
            ),
        ],
    )

# Assets
