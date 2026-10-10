"""
Applet: RevenueCat
Summary: Subscription metrics at a glance
Description: Shows 28-day revenue for one RevenueCat project, with a cumulative
sparkline, the change against the previous 28 days, MRR and active
subscriptions. Data is pulled from the RevenueCat v2 API twice a day, at local
noon and midnight.
Author: Ryan Taylor
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

API_BASE = "https://api.revenuecat.com/v2"
DEFAULT_TIMEZONE = "America/New_York"

# Data is refreshed at local noon and midnight. TTLs are clamped to this range
# so a clock skew or a bad timezone can never pin the cache open or hammer the
# API, which allows 25 requests per minute on the metrics endpoints.
MIN_TTL_SECONDS = 60
MAX_TTL_SECONDS = 12 * 60 * 60

# The overview endpoint reports revenue over a 28-day window, so the sparkline
# covers the same span and its cumulative curve lands on the headline number.
REVENUE_WINDOW_DAYS = 28

# Index of the revenue series within the revenue chart's measures.
REVENUE_MEASURE = 0

# Stands in for a project selection when the key cannot list any projects.
NO_PROJECT = "none"

# The project list pages forward with a cursor. The cap bounds the walk at 500
# projects, far past any real account, so a malformed cursor cannot loop.
PROJECT_PAGE_SIZE = 100
MAX_PROJECT_PAGES = 5

# Frame delay in milliseconds. A 2x canvas scrolls twice the pixels for the
# same apparent distance, so halving the frame delay holds the speed steady.
# This belongs on render.Root: Marquee's own delay is an initial pause counted
# in frames, not a speed control.
ROOT_DELAY = 50
ROOT_DELAY_2X = 25

BACKGROUND_COLOR = "#000000"
BRAND_COLOR = "#F2545B"
LABEL_COLOR = "#7A8195"
HERO_COLOR = "#FFFFFF"
VALUE_COLOR = "#D8DCE6"
UP_COLOR = "#3DDC84"
DOWN_COLOR = "#FF5A5F"
FLAT_COLOR = "#7A8195"

# Overview metric ids returned by /metrics/overview.
METRIC_MRR = "mrr"
METRIC_REVENUE = "revenue"
METRIC_ACTIVE_SUBSCRIPTIONS = "active_subscriptions"

CURRENCY_SYMBOLS = {
    "USD": "$",
    "EUR": "€",
    "GBP": "£",
    "AUD": "$",
    "CAD": "$",
    "JPY": "¥",
    "BRL": "R$",
    "KRW": "₩",
    "CNY": "¥",
    "MXN": "$",
}

CURRENCY_OPTIONS = [
    schema.Option(display = "US Dollar", value = "USD"),
    schema.Option(display = "Euro", value = "EUR"),
    schema.Option(display = "British Pound", value = "GBP"),
    schema.Option(display = "Australian Dollar", value = "AUD"),
    schema.Option(display = "Canadian Dollar", value = "CAD"),
    schema.Option(display = "Japanese Yen", value = "JPY"),
    schema.Option(display = "Brazilian Real", value = "BRL"),
    schema.Option(display = "South Korean Won", value = "KRW"),
    schema.Option(display = "Chinese Yuan", value = "CNY"),
    schema.Option(display = "Mexican Peso", value = "MXN"),
]

DEMO_REVENUE = 9140.0
DEMO_MRR = 4281.0
DEMO_SUBSCRIPTIONS = 312

# Daily revenue, oldest first. The first 28 days are the baseline window and
# the last 28 sum to DEMO_REVENUE, so the sample renders a +18.0% change.
DEMO_DAILY_REVENUE = [
    152.0,
    169.0,
    186.0,
    203.0,
    221.0,
    238.0,
    255.0,
    272.0,
    289.0,
    206.0,
    224.0,
    241.0,
    258.0,
    275.0,
    292.0,
    310.0,
    327.0,
    344.0,
    261.0,
    278.0,
    295.0,
    313.0,
    330.0,
    347.0,
    364.0,
    381.0,
    399.0,
    316.0,
    241.0,
    198.0,
    312.0,
    287.0,
    355.0,
    402.0,
    268.0,
    224.0,
    301.0,
    338.0,
    294.0,
    376.0,
    418.0,
    282.0,
    247.0,
    329.0,
    361.0,
    308.0,
    394.0,
    436.0,
    291.0,
    263.0,
    347.0,
    383.0,
    325.0,
    411.0,
    458.0,
    291.0,
]

def seconds_until_next_refresh(timezone):
    """Returns seconds remaining until the next local noon or midnight."""
    now = time.now().in_location(timezone)
    midnight = time.time(
        year = now.year,
        month = now.month,
        day = now.day,
        location = timezone,
    )
    noon = midnight + time.parse_duration("12h")
    next_midnight = midnight + time.parse_duration("24h")

    target = noon if now < noon else next_midnight
    remaining = int((target - now).seconds)

    return max(MIN_TTL_SECONDS, min(MAX_TTL_SECONDS, remaining))

def revenuecat_get(path, api_key, params, ttl_seconds):
    """Calls the RevenueCat v2 API. Returns the decoded body, or None."""
    response = http.get(
        url = "{}{}".format(API_BASE, path),
        headers = {
            "Authorization": "Bearer {}".format(api_key),
            "Accept": "application/json",
        },
        params = params,
        ttl_seconds = ttl_seconds,
    )

    if response.status_code != 200:
        print("RevenueCat {} returned {}".format(path, response.status_code))
        return None

    return response.json()

def fetch_overview(api_key, project_id, currency, ttl_seconds):
    """Returns {metric_id: value} for the project's overview metrics."""
    body = revenuecat_get(
        "/projects/{}/metrics/overview".format(project_id),
        api_key,
        {"currency": currency},
        ttl_seconds,
    )

    if body == None:
        return None

    metrics = {}
    for metric in body.get("metrics", []):
        metric_id = metric.get("id")
        if metric_id != None:
            metrics[metric_id] = metric.get("value")

    return metrics

def fetch_daily_revenue(api_key, project_id, currency, timezone, ttl_seconds):
    """Returns daily revenue for the window, oldest first. Empty if unavailable."""

    # Twice the display window: the older half is the baseline the percentage
    # is measured against, at no extra request. A few spare days cover the
    # incomplete rows dropped below, so both windows stay full length.
    today = time.now().in_location(timezone)
    span_days = 2 * REVENUE_WINDOW_DAYS + 3
    start = today - time.parse_duration("{}h".format(span_days * 24))

    body = revenuecat_get(
        "/projects/{}/charts/revenue".format(project_id),
        api_key,
        {
            "resolution": "day",
            "start_date": start.format("2006-01-02"),
            "end_date": today.format("2006-01-02"),
            "currency": currency,
        },
        ttl_seconds,
    )

    if body == None:
        return []

    daily = []
    for row in body.get("values", []):
        # The revenue chart interleaves several measures, one row each per day:
        # revenue is measure 0, with transactions and ad impressions after it.
        if type(row) != "dict" or row.get("measure") != REVENUE_MEASURE:
            continue

        # The current day is still accumulating. Including it would understate
        # the window and drag the comparison down until the day closes.
        if row.get("incomplete"):
            continue

        value = row.get("value")
        if type(value) in ("int", "float"):
            daily.append(float(value))

    return daily

def running_total(daily):
    """Turns daily amounts into a cumulative curve ending at the window total."""
    total = 0.0
    cumulative = []
    for amount in daily:
        total += amount
        cumulative.append(total)

    return cumulative

def window_totals(daily):
    """Returns (recent, previous) revenue totals for the two 28-day windows.

    Shorter comparisons are worthless on low-volume apps: a single purchase
    landing either side of a 7-day boundary swings the result from -97% to
    +182%. Whole windows are stable.
    """
    recent = 0.0
    previous = 0.0

    for index in range(len(daily)):
        age = len(daily) - 1 - index
        if age < REVENUE_WINDOW_DAYS:
            recent += daily[index]
        elif age < 2 * REVENUE_WINDOW_DAYS:
            previous += daily[index]

    return (recent, previous)

def change_percent(recent, previous):
    """Percent change, or None when there is no baseline to divide by."""
    if previous == 0:
        return None

    return (recent - previous) / previous * 100

def one_decimal(value):
    """Formats a float to one decimal place. Starlark has no format specs."""
    negative = value < 0
    magnitude = -value if negative else value
    scaled = int(magnitude * 10 + 0.5)

    return "{}{}.{}".format("-" if negative else "", scaled // 10, scaled % 10)

def currency_symbol(currency):
    return CURRENCY_SYMBOLS.get(currency, "")

def format_money(value, currency):
    """Formats money to fit a 64px-wide display: $4,281 or $12.3k."""
    symbol = currency_symbol(currency)

    if value == None:
        return "{}--".format(symbol)

    amount = float(value)
    if amount >= 1000000:
        return "{}{}m".format(symbol, one_decimal(amount / 1000000))
    if amount >= 100000:
        return "{}{}k".format(symbol, int(amount / 1000 + 0.5))
    if amount >= 10000:
        return "{}{}k".format(symbol, one_decimal(amount / 1000))

    return "{}{}".format(symbol, humanize.comma(int(amount)))

def compact_money(value, currency):
    """Money for the footer, where only about seven characters fit."""
    symbol = currency_symbol(currency)

    if value == None:
        return "{}--".format(symbol)

    amount = float(value)
    if amount >= 1000000:
        return "{}{}m".format(symbol, one_decimal(amount / 1000000))
    if amount >= 1000:
        return "{}{}k".format(symbol, one_decimal(amount / 1000))

    return "{}{}".format(symbol, int(amount))

def format_count(value):
    if value == None:
        return "--"

    count = int(value)
    if count >= 10000:
        return "{}k".format(one_decimal(count / 1000.0))

    return humanize.comma(count)

def trend_color(recent, previous):
    """Colors the sparkline by whether revenue grew against the prior window.

    A cumulative curve only ever rises, so its own shape says nothing. Earning
    revenue where there was none before still counts as growth, even though
    the percentage for it is undefined.
    """
    if recent > previous:
        return UP_COLOR
    if recent < previous:
        return DOWN_COLOR
    return FLAT_COLOR

def format_change(change, recent, previous):
    """The percentage, or NEW when revenue started from no baseline."""
    if change == None:
        return "NEW" if recent > previous else ""
    if change > 0.05:
        return "+{}%".format(one_decimal(change))
    if change < -0.05:
        return "{}%".format(one_decimal(change))
    return "0.0%"

def render_sparkline(history, width, height, color):
    """Draws history as 1px-wide bars so it stays crisp on the matrix."""
    if len(history) < 2 or width < 2 or height < 1:
        return render.Box(width = width, height = height)

    low = min(history)
    high = max(history)
    span = high - low

    bars = []
    last_index = len(history) - 1
    for column in range(width):
        sample = history[last_index * column // (width - 1)]

        if span > 0:
            filled = 1 + int((sample - low) / span * (height - 1))
        else:
            filled = height

        bar = render.Box(width = 1, height = filled, color = color)

        # A zero-height Box is treated as unsized and expands to fill, so the
        # empty space above a full-height bar is left out entirely.
        if filled < height:
            bar = render.Column(
                children = [
                    render.Box(width = 1, height = height - filled),
                    bar,
                ],
            )

        bars.append(bar)

    return render.Row(cross_align = "end", children = bars)

def render_message(title, message):
    scale = 2 if canvas.is2x() else 1
    title_font = "6x13" if not canvas.is2x() else "terminus-16"

    return render.Root(
        delay = ROOT_DELAY_2X if canvas.is2x() else ROOT_DELAY,
        child = render.Box(
            color = BACKGROUND_COLOR,
            child = render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text(content = title, font = title_font, color = BRAND_COLOR),
                    render.Marquee(
                        width = canvas.width() - 4 * scale,
                        align = "center",
                        child = render.Text(
                            content = message,
                            font = "tb-8" if not canvas.is2x() else "terminus-16",
                            color = VALUE_COLOR,
                        ),
                    ),
                ],
            ),
        ),
    )

def render_dashboard(title, revenue, mrr, subscriptions, daily, currency, is_demo):
    width, height = canvas.size()
    scale = 2 if canvas.is2x() else 1
    is_2x = canvas.is2x()

    label_font = "tb-8" if is_2x else "CG-pixel-3x5-mono"
    hero_font = "10x20" if is_2x else "6x13"

    inner_width = width - 2 * scale

    # Only the most recent window is drawn; the older half is the baseline.
    window = daily[-REVENUE_WINDOW_DAYS:] if len(daily) > REVENUE_WINDOW_DAYS else daily
    history = running_total(window)
    recent, previous = window_totals(daily)
    change = change_percent(recent, previous)
    sparkline_color = trend_color(recent, previous)
    header_text = "{}D REV - {}".format(REVENUE_WINDOW_DAYS, title.upper())
    if is_demo:
        header_text += " (DEMO)"

    header = render.Row(
        cross_align = "center",
        children = [
            render.Box(
                width = 2 * scale,
                height = 2 * scale,
                color = LABEL_COLOR if is_demo else BRAND_COLOR,
            ),
            render.Box(width = 2 * scale, height = 1),
            render.Marquee(
                width = inner_width - 4 * scale,
                child = render.Text(content = header_text, font = label_font, color = LABEL_COLOR),
            ),
        ],
    )

    # Hero and footer use space_between so neither row depends on knowing the
    # pixel width of the text it holds.
    hero = render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "end",
        children = [
            render.Text(
                content = format_money(revenue, currency),
                font = hero_font,
                color = HERO_COLOR,
            ),
            render.Padding(
                pad = (0, 0, 0, 2 * scale),
                child = render.Text(
                    content = format_change(change, recent, previous),
                    font = label_font,
                    color = sparkline_color,
                ),
            ),
        ],
    )

    footer = render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            # About fifteen characters fit across the footer, so both halves
            # stay compact enough for a four-figure MRR not to collide.
            render.Text(
                content = "{}/mo".format(compact_money(mrr, currency)),
                font = label_font,
                color = BRAND_COLOR,
            ),
            render.Text(
                content = "{} SUB".format(format_count(subscriptions)),
                font = label_font,
                color = VALUE_COLOR,
            ),
        ],
    )

    return render.Root(
        delay = ROOT_DELAY_2X if is_2x else ROOT_DELAY,
        child = render.Box(
            width = width,
            height = height,
            color = BACKGROUND_COLOR,
            child = render.Padding(
                pad = (1 * scale, 0, 1 * scale, 0),
                child = render.Column(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        header,
                        hero,
                        render_sparkline(history, inner_width, 6 * scale, sparkline_color),
                        footer,
                    ],
                ),
            ),
        ),
    )

def main(config):
    api_key = config.get("api_key", "")
    project_id = config.get("project_id", "")
    currency = config.get("currency", "USD")
    timezone = config.get("$tz", DEFAULT_TIMEZONE)
    display_name = config.get("display_name", "").strip()

    if not api_key:
        return render_dashboard(
            display_name if display_name else "RevenueCat",
            DEMO_REVENUE,
            DEMO_MRR,
            DEMO_SUBSCRIPTIONS,
            DEMO_DAILY_REVENUE,
            currency,
            True,
        )

    ttl_seconds = seconds_until_next_refresh(timezone)

    # The project dropdown is populated by a schema handler that only runs
    # while the settings page is open, so a saved key can arrive here with no
    # project set. An account with a single project needs no choice made.
    projects = []
    if not project_id or project_id == NO_PROJECT or not display_name:
        projects = fetch_projects(api_key, ttl_seconds)

    if not project_id or project_id == NO_PROJECT:
        if len(projects) == 0:
            return render_message("RevCat", "Check the API key in the app settings")

        # Falling back to the first project beats a dead end: the settings page
        # only offers the project dropdown while the key field is being edited,
        # so refusing to render would leave nothing to act on. The header names
        # whichever project is shown.
        project_id = projects[0].get("id")

    overview = fetch_overview(api_key, project_id, currency, ttl_seconds)
    if overview == None:
        return render_message("RevCat", "Could not reach the RevenueCat API")

    # The sparkline is a nice-to-have. If the chart call fails the numbers
    # still render.
    daily = fetch_daily_revenue(api_key, project_id, currency, timezone, ttl_seconds)

    return render_dashboard(
        display_name if display_name else project_name(projects, project_id),
        overview.get(METRIC_REVENUE),
        overview.get(METRIC_MRR),
        overview.get(METRIC_ACTIVE_SUBSCRIPTIONS),
        daily,
        currency,
        False,
    )

def fetch_projects(api_key, ttl_seconds):
    """Returns the account's projects, or an empty list when unreachable.

    The endpoint pages forward with a cursor, so a single request would
    silently truncate an account holding more projects than one page.
    """
    projects = []
    cursor = ""

    for _page in range(MAX_PROJECT_PAGES):
        params = {"limit": str(PROJECT_PAGE_SIZE)}
        if cursor:
            params["starting_after"] = cursor

        body = revenuecat_get("/projects", api_key, params, ttl_seconds)
        if body == None:
            break

        items = body.get("items", [])
        projects.extend(items)

        if not body.get("next_page") or not items:
            break

        cursor = items[-1].get("id")
        if not cursor:
            break

    return projects

def project_name(projects, project_id):
    """Resolves a project id to its name, falling back to the id itself."""
    for project in projects:
        if project.get("id") == project_id:
            return project.get("name", project_id)

    return project_id

def list_projects(api_key):
    """Schema handler: turns the entered API key into a project dropdown."""
    if not api_key:
        return []

    body = revenuecat_get("/projects", api_key, {"limit": "20"}, MIN_TTL_SECONDS)
    if body == None:
        return []

    options = []
    for project in body.get("items", []):
        project_id = project.get("id")
        if project_id != None:
            options.append(
                schema.Option(
                    display = project.get("name", project_id),
                    value = project_id,
                ),
            )

    return options

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "A RevenueCat v2 secret key (sk_...) with read access to Charts & Metrics. Edit this field to refresh the project list below.",
                icon = "key",
                secret = True,
            ),
            schema.Generated(
                id = "project_generated",
                source = "api_key",
                handler = project_schema,
            ),
            schema.Text(
                id = "display_name",
                name = "Display Name",
                desc = "Name shown in the header. Defaults to the RevenueCat project name.",
                icon = "tag",
            ),
            schema.Dropdown(
                id = "currency",
                name = "Currency",
                desc = "Currency used for MRR.",
                icon = "dollarSign",
                default = "USD",
                options = CURRENCY_OPTIONS,
            ),
        ],
    )

def project_schema(api_key):
    options = list_projects(api_key)

    # Pixlet rejects a dropdown with an empty default, so an unusable key still
    # has to yield one option to select.
    if not options:
        options = [schema.Option(display = "Enter a valid API key", value = NO_PROJECT)]

    return [
        schema.Dropdown(
            id = "project_id",
            name = "Project",
            desc = "The RevenueCat project to display.",
            icon = "folder",
            default = options[0].value,
            options = options,
        ),
    ]
