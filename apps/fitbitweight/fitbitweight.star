"""
Applet: FitbitWeight
Summary: Displays recent weigh-ins
Description: Displays your Fitbit recent weigh-ins.
Author: Robert Ison
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("humanize.star", "humanize")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

# App Settings
CACHE_TTL = 60 * 60 * 24  # updates once daily
FITBIT_TOKEN_URL = "https://api.fitbit.com/oauth2/token"
FITBIT_DATA_URL = "https://api.fitbit.com/1/user/-/body/%s/date/today/max.json"
FITBIT_DATA_KEYS = ("weight", "fat", "bmi")

# Fitbit Data Display
DISPLAY_FONT = "CG-pixel-3x5-mono"
FAT_COLOR = "#b9d9eb"
KILOGRAMS_TO_POUNDS_MULTIPLIER = 2.2
WEIGHT_COLOR = "#00B0B9"
WHITE_COLOR = "#FFF"

# Canvas
SCREEN_WIDTH = canvas.width()
SCREEN_HEIGHT = canvas.height()

def main(config):
    refresh_token = cache.get("fitbit_refresh_token")
    auth_code = config.get("auth_code")  # one-time Fitbit authorization code
    client_id = config.get("client_id")
    client_secret = config.get("client_secret")

    if not client_id or not client_secret:
        return []

    access_token = None

    # If we don't have a refresh token yet but we *do* have an auth code,
    # first exchange the code for access+refresh tokens.
    if not refresh_token and auth_code:
        print("Using auth_code flow")
        access_token, refresh_token = exchange_code_for_tokens(auth_code, client_id, client_secret)

        # Cache refresh token for future runs (30 days TTL)
        cache.set("fitbit_refresh_token", refresh_token, ttl_seconds = 30 * 24 * 3600)
    elif not refresh_token:
        # No refresh token and no auth code: nothing we can do
        print("No auth_code or refresh_token; exiting")
        return []

    # If we didn't just get an access_token from the code exchange,
    # do the normal refresh flow.
    if access_token == None:
        access_token, new_refresh_token = get_access_token(refresh_token, client_id, client_secret)

        # Store new refresh token in cache for future runs (30 days TTL)
        cache.set("fitbit_refresh_token", new_refresh_token, ttl_seconds = 30 * 24 * 3600)

    period = config.get("period") or "0"
    system = config.get("system") or "imperial"
    secondary_display = config.get("second") or "none"

    # Fetch data
    weight_json = get_data_from_fitbit(access_token, FITBIT_DATA_URL % "weight")
    fat_json = get_data_from_fitbit(access_token, FITBIT_DATA_URL % "fat")
    bmi_json = get_data_from_fitbit(access_token, FITBIT_DATA_URL % "bmi")

    # Default values
    current_weight = 0
    first_weight = 0
    current_fat = 0
    current_bmi = 0
    first_weight_date = None

    # Process data
    if weight_json != None and len(weight_json["body-weight"]) > 0:
        current_weight = float(weight_json["body-weight"][-1]["value"])
        first_weight = float(get_starting_value(weight_json, period, "value"))
        if first_weight < 0:
            first_weight = 0
        first_weight_date = get_starting_value(weight_json, period, "dateTime")

    if fat_json != None and len(fat_json["body-fat"]) > 0:
        current_fat = float(fat_json["body-fat"][-1]["value"])

    if bmi_json != None and len(bmi_json["body-bmi"]) > 0:
        current_bmi = float(bmi_json["body-bmi"][-1]["value"])

    # Convert to imperial if needed
    if system == "metric":
        display_units = "KGs"
    else:
        display_units = "LBs"
        current_weight *= KILOGRAMS_TO_POUNDS_MULTIPLIER
        first_weight *= KILOGRAMS_TO_POUNDS_MULTIPLIER

    weight_change = current_weight - first_weight
    sign = "+" if weight_change > 0 else ""

    weight_plot = get_plot_from_data(weight_json, period)
    fat_plot = get_plot_from_data(fat_json, period)

    display_weight = "%s%s " % (humanize.comma(int(current_weight * 100) // 100.0), display_units)

    # Build numbers row
    if secondary_display == "bodyfat" and current_fat > 0:
        numbers_row = render.Row(
            main_align = "left",
            children = [
                render.Text(display_weight, color = WEIGHT_COLOR, font = DISPLAY_FONT),
                render.Marquee(
                    width = int(SCREEN_WIDTH / 2),
                    child = render.Text(
                        "%s%% body fat" % (humanize.comma(int(current_fat * 100) // 100.0)),
                        color = FAT_COLOR,
                        font = DISPLAY_FONT,
                    ),
                ),
            ],
        )
    elif secondary_display == "bmi" and current_bmi > 0:
        display_color = get_bmi_display(current_bmi)
        numbers_row = render.Row(
            main_align = "left",
            children = [
                render.Text(display_weight, color = WEIGHT_COLOR, font = DISPLAY_FONT),
                render.Marquee(
                    width = int(SCREEN_WIDTH / 2),
                    child = render.Text(
                        "BMI: %s %s" % (humanize.comma(int(current_bmi * 100) // 100.0), display_color[0]),
                        color = display_color[1],
                        font = DISPLAY_FONT,
                    ),
                ),
            ],
        )
    else:
        first_weight_display = "" if first_weight_date == -1 else "since %s " % first_weight_date
        numbers_row = render.Row(
            main_align = "left",
            children = [
                render.Text(display_weight, color = WHITE_COLOR, font = DISPLAY_FONT),
                render.Marquee(
                    width = int(SCREEN_WIDTH / 2),
                    child = render.Text(
                        "%s%s %s %s" %
                        (
                            sign,
                            humanize.comma(int(weight_change * 100) // 100.0),
                            display_units,
                            first_weight_display,
                        ),
                        color = WEIGHT_COLOR,
                        font = DISPLAY_FONT,
                    ),
                ),
            ],
        )

    # Build display rows
    rows = [numbers_row]
    rows.append(render.Box(height = 1))  # 1 pixel horizontal separator

    if secondary_display == "bmi":
        rows.append(get_plot_display_from_plot(weight_plot, WEIGHT_COLOR, 26))
    elif secondary_display == "bodyfat":
        rows.append(get_plot_display_from_plot(weight_plot, WEIGHT_COLOR))
        rows.append(get_plot_display_from_plot(fat_plot, FAT_COLOR))
    else:
        rows.append(get_plot_display_from_plot(weight_plot, WEIGHT_COLOR, 26))

    return render.Root(
        child = render.Column(
            expanded = True,
            children = rows,
        ),
    )

def exchange_code_for_tokens(auth_code, client_id, client_secret):
    # Build Basic auth header
    auth_raw = client_id + ":" + client_secret
    auth_b64 = base64.encode(auth_raw)

    headers = {
        "Authorization": "Basic " + auth_b64,
        "Content-Type": "application/x-www-form-urlencoded",
    }

    # MUST match your Fitbit app redirect URI exactly
    redirect_uri = "http://localhost/"  # e.g. "https://example.com/fitbit/callback"

    form_body = {
        "grant_type": "authorization_code",
        "code": auth_code,
        "redirect_uri": redirect_uri,
    }

    res = http.post(
        url = FITBIT_TOKEN_URL,
        headers = headers,
        form_body = form_body,
        ttl_seconds = 1800,
    )

    if res.status_code != 200:
        fail("Fitbit code exchange failed: %d - %s" % (res.status_code, res.body()))

    token_params = res.json()

    # Returns both tokens; caller should cache the refresh_token
    return token_params["access_token"], token_params["refresh_token"]

def get_access_token(refresh_token, client_id, client_secret):
    print("get_access_token using refresh_token:", refresh_token)

    auth_raw = client_id + ":" + client_secret
    auth_b64 = base64.encode(auth_raw)

    headers = {
        "Authorization": "Basic " + auth_b64,
        "Content-Type": "application/x-www-form-urlencoded",
    }

    form_body = {
        "grant_type": "refresh_token",
        "refresh_token": refresh_token,
    }

    res = http.post(
        url = FITBIT_TOKEN_URL,
        headers = headers,
        form_body = form_body,
        ttl_seconds = 1800,
    )

    if res.status_code != 200:
        fail("Fitbit token refresh failed: %d - %s" % (res.status_code, res.body()))

    token_params = res.json()

    # Fitbit returns a new refresh_token; you must store it
    return token_params["access_token"], token_params["refresh_token"]

def get_data_from_fitbit(access_token, data_url):
    res = http.get(
        url = data_url,
        headers = {"Authorization": "Bearer %s" % access_token},
        ttl_seconds = CACHE_TTL,
    )
    if res.status_code == 200:
        return res.json()
    else:
        return None

def get_starting_value(json_data, period, itemName = "value"):
    for i in json_data:
        for item in json_data[i]:
            current_date = get_timestamp_from_date(item["dateTime"])
            date_diff = time.now() - current_date
            days = math.floor(date_diff.hours // 24)
            number_of_days = int(period)
            if number_of_days == 0 or days < number_of_days:
                return item[itemName]
    return -1

def get_timestamp_from_date(date_string):
    date_parts = str(date_string).split("-")
    return time.time(year = int(date_parts[0]), month = int(date_parts[1]), day = int(date_parts[2]))

def get_days_between(day1, day2):
    date_diff = day1 - day2
    days = math.floor(date_diff.hours // 24)
    return days

def get_plot_from_data(json_data, period):
    plot = [(0, 0)]
    if json_data == None:
        return plot

    oldest_date = None
    starting_value = None
    number_of_days = int(period)

    for i in json_data:
        for item in json_data[i]:
            current_date = get_timestamp_from_date(item["dateTime"])
            current_value = float(item["value"])
            days = get_days_between(time.now(), current_date)

            if number_of_days == 0 or days < number_of_days:
                if starting_value == None:
                    starting_value = current_value
                if oldest_date == None or current_date < oldest_date:
                    oldest_date = current_date

    plot = [(0, starting_value or 0)]
    for i in json_data:
        for item in json_data[i]:
            current_date = get_timestamp_from_date(item["dateTime"])
            current_value = float(item["value"])
            days = get_days_between(time.now(), current_date)
            if number_of_days == 0 or days < number_of_days:
                x_val = get_days_between(current_date, oldest_date)
                plot.append((x_val, current_value))

    return plot

def get_plot_display_from_plot(plot, color = WHITE_COLOR, height = 13):
    return render.Plot(
        data = plot,
        width = SCREEN_WIDTH,
        height = height,
        color = color,
        fill = True,
    )

def get_bmi_display(bmi):
    if bmi < 19:
        return ("Underweight", "#01b0f1")
    elif bmi < 25:
        return ("Healthy", "#5fa910")
    elif bmi < 30:
        return ("Overweight", "#ff0")
    elif bmi < 40:
        return ("Obese", "#e77a22")
    else:
        return ("Extremely Obese", "#f00")

#------------------------
# Schema
#------------------------
def get_schema():
    period_options = [
        schema.Option(value = "7", display = "7 Days"),
        schema.Option(value = "30", display = "30 Days"),
        schema.Option(value = "60", display = "2 Months"),
        schema.Option(value = "90", display = "3 Months"),
        schema.Option(value = "180", display = "6 Months"),
        schema.Option(value = "360", display = "1 Year"),
        schema.Option(value = "720", display = "2 Years"),
        schema.Option(value = "1825", display = "5 Years"),
        schema.Option(value = "0", display = "Maximum Allowed"),
    ]

    measurement_options = [
        schema.Option(value = "metric", display = "Metric"),
        schema.Option(value = "imperial", display = "Imperial"),
    ]

    secondary_options = [
        schema.Option(value = "none", display = "None - just display weight"),
        schema.Option(value = "bodyfat", display = "Body Fat Percentage"),
        schema.Option(value = "bmi", display = "BMI"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "client_id",
                name = "Fitbit Client ID",
                desc = "Your Fitbit app client ID.",
                icon = "user",
                secret = True,
            ),
            schema.Text(
                id = "client_secret",
                name = "Fitbit Client Secret",
                desc = "Your Fitbit app client secret.",
                icon = "user",
                secret = True,
            ),
            schema.Text(
                id = "auth_code",
                name = "Fitbit Auth Code",
                desc = "Your Fitbit authorization code.",
                icon = "user",
                secret = True,
            ),
            schema.Dropdown(
                id = "period",
                name = "Period",
                desc = "The length of time to chart.",
                icon = "stopwatch",
                options = period_options,
                default = period_options[0].value,
            ),
            schema.Dropdown(
                id = "system",
                name = "Measurement",
                desc = "Choose Imperial or Metric",
                icon = "ruler",
                options = measurement_options,
                default = "metric",
            ),
            schema.Dropdown(
                id = "second",
                name = "Secondary Measurement",
                desc = "Choose the secondary item to plot",
                icon = "squarePollVertical",
                options = secondary_options,
                default = "none",
            ),
        ],
    )
