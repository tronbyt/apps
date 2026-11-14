"""
Applet: Plausible Analytics
Summary: Plausible Analytics Display
Description: Display you website's analytics from your Plausible Analytics account.
Author: brettohland
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("images/globe_image.png", GLOBE_IMAGE_ASSET = "file")
load("images/plausible_logo.png", PLAUSIBLE_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

GLOBE_IMAGE = GLOBE_IMAGE_ASSET.readall()
PLAUSIBLE_LOGO = PLAUSIBLE_LOGO_ASSET.readall()

METRIC_OPTIONS = [
    schema.Option(
        display = "Pageviews",
        value = "pageviews",
    ),
    schema.Option(
        display = "Visitors",
        value = "visitors",
    ),
    schema.Option(
        display = "Bounce Rate",
        value = "bounce_rate",
    ),
    schema.Option(
        display = "Visit Duration",
        value = "visit_duration",
    ),
    schema.Option(
        display = "Visits/Session",
        value = "visits",
    ),
]

TIME_PERIOD_OPTIONS = [
    schema.Option(
        display = "Today",
        value = "day",
    ),
    schema.Option(
        display = "Last 7 days",
        value = "7d",
    ),
    schema.Option(
        display = "Last 30 days",
        value = "30d",
    ),
    schema.Option(
        display = "This Month",
        value = "month",
    ),
    schema.Option(
        display = "Last 6 months",
        value = "6mo",
    ),
    schema.Option(
        display = "Last 12 months",
        value = "12mo",
    ),
    schema.Option(
        display = "All Time",
        value = "custom",
    ),
]

CHART_TIME_PERIOD_OPTIONS = [
    schema.Option(
        display = "Last 7 days",
        value = "7d",
    ),
    schema.Option(
        display = "Last 30 days",
        value = "30d",
    ),
    schema.Option(
        display = "This Month",
        value = "month",
    ),
    schema.Option(
        display = "Last 6 months",
        value = "6mo",
    ),
    schema.Option(
        display = "Last 12 months",
        value = "12mo",
    ),
]

# API URL for Plausible
PLAUSIBLE_API_URL = "https://plausible.io/api/v1/stats/"

# Config/Schema Keys
DOMAIN_KEY = "domain"
PLAUSIBLE_API_KEY = "plausible_api_key"
METRIC_KEY = "metric"
TIME_PERIOD_KEY = "time_period"

SHOULD_SHOW_CHART_KEY = "should_show_chart"
CHART_TIME_PERIOD_KEY = "chart_time_period"

FAVICON_PATH_KEY = "favicon_path_key"
FAVICON_PATH = "favicon_path"
FAVICON_FILENAMES = ["favicon.png", "favicon-16x16.png", "favicon-32x32.png"]

# Cache identifiers and TTL values
REQUEST_CACHE_ID = "plausible_request"
REQUEST_CACHE_TTL = 600  # 10 minutes
FAVICON_CACHE_ID = "plausible_favicon"
FAVICON_CACHE_TTL = 86400  # 1 day
DISABLE_CACHE = False  # Useful while debugging

# Fallback Images

def main(config):
    # Show the demo screen for the store page.
    if config.get(DOMAIN_KEY) == None and config.get(PLAUSIBLE_API_KEY) == None:
        print("Domain and API key are missing, rendering demo.")
        return render_demo_screen()

    time_period = config.get(TIME_PERIOD_KEY) or TIME_PERIOD_OPTIONS[0].value
    metric = config.get(METRIC_KEY) or METRIC_OPTIONS[0].value
    token = config.get(PLAUSIBLE_API_KEY)
    chart_time_period = config.get(CHART_TIME_PERIOD_KEY)
    domain = sanitize_domain(config.get(DOMAIN_KEY))
    should_show_chart = config.bool(SHOULD_SHOW_CHART_KEY)
    custom_favicon_path = config.get(FAVICON_PATH_KEY)

    # Alert the user if the domain is bad
    if domain == None:
        print("Invalid domain, rendering error screen")
        return render_error_screen("Domain not set correctly")

    # Alert the user if the Plausible API Token is missing
    if token == None:
        print("API key missing, rendering error screen")
        return render_error_screen("Plausible API Key is missing!")

    # Fetch the stat for the given metric from Plausible.io
    stats_response = get_plausible_data("aggregate", token, domain, time_period, metric)

    stats_dict = stats_response[0]
    response_code = stats_response[1]

    # A 401 error says that the API key and site ID provided to Plausible was incorrect.
    if response_code == 401:
        return render_error_screen("Invalid API Key or domain used.")

    # Make sure that we have data, and that the returned response code was 200.
    if stats_dict == None and response_code != 200:
        return render_error_screen("Request failed")

    # Safely get the metric in question
    metric_dict = stats_dict.get(metric)

    # Verify that we got the correct response
    if metric_dict == None:
        return render_error_screen("Invalid Response from Plausible")

    # Safely get the value (as a string)
    stat_string = metric_dict.get("value")

    # Verify that we got the correct response here too
    if stat_string == None:
        return render_error_screen("Invalid Response from Plausible")

    # Convert the value into an integer
    stat = int(stat_string)

    # Bounce rate and visit duration need special suffixes, otherwise run the compact_number
    # method on the value to get a string that fits into 6 digits.
    formatted_stat = ""
    if metric == "bounce_rate":
        formatted_stat = stat + "%"
    elif metric == "visit_duration":
        formatted_stat = stat + "s"
    else:
        formatted_stat = compact_number(stat)

    # Get the favicon based on if the user wants to set a custom favicon or not
    if custom_favicon_path != None:
        favicon = get_favicon(domain, custom_favicon_path)
    else:
        favicon = get_favicon(domain, None)

    # Determine if the user wants to show the historical chart or not.
    # If yes, fetch the data from Plausible.io's API and convert it to the format render.Plot needs
    # If no, do nothing
    # Either way, the end result is a list of children that will be rendered later
    if should_show_chart:
        results = get_plausible_data("timeseries", token, domain, chart_time_period, metric)

        # Verify that the data was returned and that it was a 200 status code.
        if results[0] != None or results[1] != 200:
            # The error state is to just return the larger text as the chart's data was invalid.
            rendered_stats = render.Padding(
                pad = (0, 3, 0, 0),
                child = render.Marquee(
                    width = 37,
                    align = "center",
                    child = render.Text(formatted_stat, font = "10x20"),
                ),
            )
            rendered_plot = None

        plot_data = convert_result_for_plot(results[0], metric)
        number_of_data_points = len(plot_data[0]) - 1
        largest_value = plot_data[1]
        rendered_stats = render.Text(formatted_stat, font = "6x13")
        rendered_plot = render_plot(plot_data[0], number_of_data_points, largest_value)
    else:
        rendered_stats = render.Padding(
            pad = (0, 3, 0, 0),
            child = render.Marquee(
                width = 37,
                align = "center",
                child = render.Text(formatted_stat, font = "10x20"),
            ),
        )
        rendered_plot = None

    return render_screen(
        favicon,
        rendered_stats,
        rendered_plot,
        metric.replace("_", " ") + " " + make_description_text(time_period),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = DOMAIN_KEY,
                name = "Domain",
                desc = "The domain who's stats are being tracked by Plausible.io",
                icon = "link",
                default = "",
            ),
            schema.Text(
                id = PLAUSIBLE_API_KEY,
                name = "Plausible API Key",
                desc = "Get it at plausible.io/settings",
                icon = "key",
                default = "",
                secret = True,
            ),
            schema.Dropdown(
                id = METRIC_KEY,
                name = "Metric",
                desc = "Choose the site metric you'd like to display",
                icon = "table",
                default = METRIC_OPTIONS[0].value,
                options = METRIC_OPTIONS,
            ),
            schema.Dropdown(
                id = TIME_PERIOD_KEY,
                name = "Time Period",
                desc = "Choose the time period for the counter display",
                icon = "calendar",
                default = TIME_PERIOD_OPTIONS[0].value,
                options = TIME_PERIOD_OPTIONS,
            ),
            schema.Dropdown(
                id = CHART_TIME_PERIOD_KEY,
                name = "Chart Time Period",
                desc = "Customize the time period for the chart",
                icon = "chartLine",
                default = CHART_TIME_PERIOD_OPTIONS[0].value,
                options = CHART_TIME_PERIOD_OPTIONS,
            ),
            schema.Text(
                id = FAVICON_PATH_KEY,
                name = "Advanced: Favicon Path",
                desc = "The relative path to the favicon on your site (eg: favicons/). Note: The favicon must be named favicon.png, favicon-16x16.png, or favicon-32x32.png",
                icon = "icons",
                default = "",
            ),
            schema.Toggle(
                id = SHOULD_SHOW_CHART_KEY,
                name = "Advanced: Chart Visibility",
                desc = "Optionally show or hide the historical chart",
                icon = "eyeSlash",
                default = True,
            ),
        ],
    )

# These values are unfortunately duplicated from the options constants defined for the schema
def make_description_text(time_period):
    if time_period == "day":
        return "Today"

    if time_period == "7d":
        return "Last 7 days"

    if time_period == "30d":
        return "Last 30 days"

    if time_period == "month":
        return "This month"

    if time_period == "6mo":
        return "Last 6 months"

    if time_period == "12mo":
        return "Last 12 months"

    return "Total"

# Converts a large number into a compact string that is 6 characters or less.
# Values under 10,000 will be returned as-is eg. 120 stays 120
# Values over 10,000 will have the suffix "K" eg. 12,345 becomes 12.34K
# Values over 1,000,000 will have the suffix "M" eg. 1,234,567 becomes 1.23M
# Values over 1,000,000,000 will have the suffix "B" eg, 1,234,456,789 becomes 1.23B
# Values over a billion will return the string "A LOT!" (What are you? Google?)
def compact_number(number):
    value_string = str(number)

    # Get length of string
    character_count = len(value_string)

    # Return the string if it's 4 characters or less
    if character_count <= 4:
        return humanize.comma(number)

    # Thousands
    if character_count <= 6:
        return decorate_value(value_string, character_count - 3, "K")

    # Millions
    if character_count <= 9:
        return decorate_value(value_string, character_count - 6, "M")

    # Billions
    if character_count <= 12:
        return decorate_value(value_string, character_count - 9, "B")

    # Yikes, that's a lot
    return "A LOT!"

# Takes a string, grabs the first 4 characters,  and decorates it with the decimal separator
# and the correct suffix eg. "1234" becomes "1.234K".
# It will also remove any trailing "0" eg. 1010 becomes "1.01K" and 1000 becomes "1K".
# characters
#    value: Any string to decorate
#    decimal_index: The index in the string where to place the decimal separator (1, 2, or 3)
#    suffix: The character to place at the end of the string ("K", "M", or "B")
def decorate_value(value, decimal_index, suffix):
    # Convert the string to a list
    value_list = list(value.elems())

    # Take the first 4 characters
    cropped_list = value_list[:4]

    # Insert the "." character at the decimal_index
    cropped_list.insert(decimal_index, ".")

    # Smash it back into a string
    joined = "".join(cropped_list)

    # Loop through and remove any and all trailing "0" characters
    for _ in range(len(joined)):
        joined = joined.removesuffix("0")

    # Remove a trailing decimal separator if present
    joined = joined.removesuffix(".")

    # Return the joined string, with the suffix added
    return joined + suffix

# Removes the chance for human error. Does its best to remove
# the scheme and "www" subdomain if present.
def sanitize_domain(domain):
    # Strip out any and all whitespace characters
    stripped_domain = "".join(domain.split())

    # Check for empty at first
    if stripped_domain == "" or stripped_domain == None:
        print("Invalid domain %s" % domain)
        return None

    # Lowercae the URL since the Tidbyt app is agressive about adding
    # capital letters to the beginning of entered strings.
    stripped_domain.lower()

    # Strip out "http://" or "https://"
    prefix_free_domain = stripped_domain.split("://").pop()

    # Remove "www."
    final_url = prefix_free_domain.removeprefix("www.")

    # Do one final check to make sure we have at least a valid host
    # ie. "something.tld"
    if len(final_url.split(".")) < 2:
        print("Invalid domain %s" % domain)
        return None

    print("Sanitized domain: %s" % final_url)
    return final_url

# Makes a request to the domain, and will attempt to return the site's favicon
# icon by assuming the three most common favicon filenames.
# Defaults to GLOBE_IMAGE if it fails.
def get_favicon(domain, favicon_path):
    favicon_url = "http://" + domain + "/"

    if favicon_path != None:
        # Normalize the favicon path by stripping any possible leading and trailing "/" characters, before
        # re-adding them. To give ourselves a high chance of getting it right.
        formatted_favicon_path = "/" + favicon_path.strip("/") + "/"
        favicon_url = favicon_url + formatted_favicon_path

    for f in FAVICON_FILENAMES:
        final_url = favicon_url + f
        response = http.get(final_url, ttl_seconds = FAVICON_CACHE_TTL)
        if response.status_code != 200:
            continue
        favicon = response.body()
        return favicon

    return GLOBE_IMAGE

# Makes a call to the plausible.io stats endpoint.
#    endpoint: the path to the API to call eg. "/aggregate" or "/timeseries"
#    toke: The Auth token
#    domain: The domain to check
#    time_period: The time period to check (doesn't support custom date ranges)
#    metric: The metric value to return
def get_plausible_data(endpoint, token, domain, time_period, metric):
    print("Getting data from Plausible:  %s" % ",".join([domain, time_period, metric]))

    site_id_param = "?site_id=" + domain
    time_period_param = "&period=" + time_period
    metrics_param = "&metrics=" + metric
    request_url = PLAUSIBLE_API_URL + endpoint + site_id_param + time_period_param + metrics_param

    # If the user selected "all", we have to add an additional "date" query parameter
    if time_period == "custom":
        past = "2000-01-01"
        now = humanize.time_format("yyyy-MM-dd", time.now())
        request_url = request_url + "&date=" + past + "," + now

    response = http.get(
        request_url,
        headers = {
            "Authorization": "Bearer " + token,
        },
        ttl_seconds = REQUEST_CACHE_TTL,
    )

    # We return the status code in the event of an error because Plausible uses
    # error codes as indicators as to why things failed.
    if response.status_code != 200:
        return (None, response.status_code)

    # Safely unwrap the results object.
    results = response.json().get("results")

    # Return an error if it's invalid.
    if results == None:
        return (None, 500)

    return (results, 200)

# Takes the API result from Plausible and converts it to the
# list required by the render.Plot method.
# Could probably be optimized by the zip method.
def convert_result_for_plot(results, metric):
    final_data = []
    largest_value = 0
    for i, r in enumerate(results):
        safe_value = 0
        if r[metric] != None:
            safe_value = r[metric]
        final_data.append((i, safe_value))
        if safe_value > largest_value:
            largest_value = safe_value
    return (final_data, largest_value)

# Render the screen using the provided values
def render_screen(favicon, rendered_stats, rendered_plot, marquee_text):
    return render.Root(
        render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Row(
                    expanded = True,
                    main_align = "end",
                    cross_align = "center",
                    children = [
                        render.Padding(
                            pad = (0, 1, 2, 0),
                            child = render.Image(favicon, width = 20, height = 20),
                        ),
                        render.Column(
                            main_align = "center",
                            cross_align = "center",
                            children = [
                                rendered_stats,
                                rendered_plot,
                            ],
                        ),
                    ],
                ),
                render.Box(
                    width = 1,
                    height = 2,
                ),
                render.Marquee(
                    width = 64,
                    height = 6,
                    align = "center",
                    child = render.Text(
                        marquee_text,
                        font = "CG-pixel-3x5-mono",
                    ),
                ),
            ],
        ),
    )

# Builds the standart chart
def render_plot(data, max_x, max_y):
    return render.Plot(
        data = data,
        width = 40,
        height = 12,
        color = "#0F0",
        x_lim = (0, max_x),
        y_lim = (0, max_y),
        fill = True,
    )

# Render the demo screen (used for the store in the app)
def render_demo_screen():
    rendered_stats = render.Text("9001", font = "6x13")
    rendered_plot = render_plot([(0, 3.35), (1, 2.15), (2, 2.37), (3, 0.31), (4, 3.53), (5, 1.31), (6, 1.3), (7, 4.60), (8, 3.33), (9, 5.92)], 9, 6)
    return render_screen(GLOBE_IMAGE, rendered_stats, rendered_plot, "Pageviews all time")

# Render the error screen
def render_error_screen(message):
    return render.Root(
        child = render.Column(
            children = [
                render.Padding(
                    pad = 2,
                    child = render.Image(
                        PLAUSIBLE_LOGO,
                        width = 60,
                    ),
                ),
                render.Padding(
                    pad = (0, 2, 2, 0),
                    child = render.Marquee(
                        width = 64,
                        height = 10,
                        align = "center",
                        child = render.Text(message),
                    ),
                ),
            ],
        ),
    )
