"""
Applet: SolarEdge summary
Summary: SolarEdge daily, monthly, annual and lifetime summary
Description: Daily, monthly, annual and lifetime energy production and consumption for your SolarEdge solar system
Author: ckyr (credit to ingmarstein for solaredge app)
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/plug_sum.gif", PLUG_SUM_ASSET = "file")
load("images/sun_sum.png", SUN_SUM_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

PLUG_SUM = PLUG_SUM_ASSET.readall()
SUN_SUM = SUN_SUM_ASSET.readall()

URL_ENERGY = "https://monitoringapi.solaredge.com/site/{}/energyDetails"
URL_SITE = "https://monitoringapi.solaredge.com/site/{}/details"

# SolarEdge API limit is 300 requests per day, cache for 5 minutes
CACHE_TTL = 300

# Colors
GRAY = "#777777"
RED = "#AA0000"
GREEN = "#00FF00"
WHITE = "#FFFFFF"

def get_time_zone(site_id, api_key):
    """Get the timezone for the site."""
    url = URL_SITE.format(site_id)
    rep = http.get(url, params = {"api_key": api_key}, ttl_seconds = CACHE_TTL)
    default_tz = "Etc/UTC"

    if rep.status_code == 200:
        data = json.decode(rep.body())
        if "details" in data and "location" in data["details"] and "timeZone" in data["details"]["location"]:
            default_tz = data["details"]["location"]["timeZone"]

    return default_tz

def get_energy_for_period(site_id, api_key, tz, time_unit):
    """Get production and consumption energy for a time period."""
    now = time.now().in_location(tz)

    # Format dates differently based on time unit using time.time() constructor
    if time_unit == "DAY":
        # For daily, use current date at midnight
        start_time = time.time(
            year = now.year,
            month = now.month,
            day = now.day,
            hour = 0,
            minute = 0,
            second = 0,
            location = tz,
        )
    elif time_unit == "MONTH":
        # For monthly, use first day of current month at midnight
        start_time = time.time(
            year = now.year,
            month = now.month,
            day = 1,
            hour = 0,
            minute = 0,
            second = 0,
            location = tz,
        )
    elif time_unit == "YEAR":
        # For yearly, use first day of current year at midnight
        start_time = time.time(
            year = now.year,
            month = 1,
            day = 1,
            hour = 0,
            minute = 0,
            second = 0,
            location = tz,
        )
    else:
        return None, None, "Invalid time unit"

    # Format dates as YYYY-MM-DD HH:MM:SS using Go-style format strings
    start_string = start_time.format("2006-01-02 15:04:05")
    now_string = now.format("2006-01-02 15:04:05")

    print("Requesting {} data from {} to {}".format(time_unit, start_string, now_string))

    rep = http.get(
        URL_ENERGY.format(site_id),
        params = {
            "api_key": api_key,
            "startTime": start_string,
            "endTime": now_string,
            "timeUnit": time_unit,
        },
        ttl_seconds = CACHE_TTL,
    )

    if rep.status_code != 200:
        error_msg = "API error {}: {}".format(rep.status_code, rep.body())
        print(error_msg)
        return None, None, error_msg

    data = rep.json()["energyDetails"]
    consumption = 0
    production = 0

    for meter in data["meters"]:
        if meter["type"] == "Consumption":
            for value in meter["values"]:
                if value.get("value"):
                    consumption += value["value"]
        elif meter["type"] == "Production":
            for value in meter["values"]:
                if value.get("value"):
                    production += value["value"]

    return production, consumption, None

def get_weekly_energy(site_id, api_key, tz):
    """Get production and consumption energy for today plus the last 6 full days (7 days total)."""
    now = time.now().in_location(tz)

    # Start at midnight 6 days ago (not 7, because we want 6 full days + today)
    six_days_ago = now - time.parse_duration("144h")  # 6 days * 24 hours

    # Start at midnight 6 days ago
    start_time = time.time(
        year = six_days_ago.year,
        month = six_days_ago.month,
        day = six_days_ago.day,
        hour = 0,
        minute = 0,
        second = 0,
        location = tz,
    )

    # Format dates as YYYY-MM-DD HH:MM:SS
    start_string = start_time.format("2006-01-02 15:04:05")
    now_string = now.format("2006-01-02 15:04:05")

    print("Requesting WEEK data from {} to {}".format(start_string, now_string))

    rep = http.get(
        URL_ENERGY.format(site_id),
        params = {
            "api_key": api_key,
            "startTime": start_string,
            "endTime": now_string,
            "timeUnit": "DAY",
        },
        ttl_seconds = CACHE_TTL,
    )

    if rep.status_code != 200:
        error_msg = "Week API error {}: {}".format(rep.status_code, rep.body())
        print(error_msg)
        return None, None, error_msg

    data = rep.json()["energyDetails"]
    consumption = 0
    production = 0

    # Sum all days
    for meter in data["meters"]:
        if meter["type"] == "Consumption":
            for value in meter["values"]:
                if value.get("value"):
                    consumption += value["value"]
        elif meter["type"] == "Production":
            for value in meter["values"]:
                if value.get("value"):
                    production += value["value"]

    return production, consumption, None

def get_lifetime_energy(site_id, api_key, tz):
    """Get lifetime production energy using energyDetails API."""
    now = time.now().in_location(tz)

    # Use a far-past date to capture all history
    start_time = time.time(
        year = 2000,
        month = 1,
        day = 1,
        hour = 0,
        minute = 0,
        second = 0,
        location = tz,
    )

    start_string = start_time.format("2006-01-02 15:04:05")
    now_string = now.format("2006-01-02 15:04:05")

    print("Requesting LIFETIME data from {} to {}".format(start_string, now_string))

    rep = http.get(
        URL_ENERGY.format(site_id),
        params = {
            "api_key": api_key,
            "startTime": start_string,
            "endTime": now_string,
            "timeUnit": "YEAR",
        },
        ttl_seconds = CACHE_TTL,
    )

    if rep.status_code != 200:
        error_msg = "Lifetime API error {}: {}".format(rep.status_code, rep.body())
        print(error_msg)
        return None, None, error_msg

    data = rep.json()["energyDetails"]
    consumption = 0
    production = 0

    # Sum all years
    for meter in data["meters"]:
        if meter["type"] == "Consumption":
            for value in meter["values"]:
                if value.get("value"):
                    consumption += value["value"]
        elif meter["type"] == "Production":
            for value in meter["values"]:
                if value.get("value"):
                    production += value["value"]

    return production, consumption, None

def format_energy(wh):
    """Format energy value with appropriate unit (kWh, MWh, or GWh)."""
    if wh == None:
        return "N/A"
    if wh >= 1000000000:  # >= 1 GWh
        return humanize.float("#,###.##", wh / 1000000000) + " GWh"
    elif wh >= 1000000:  # >= 1 MWh
        return humanize.float("#,###.##", wh / 1000000) + " MWh"
    else:  # kWh
        return humanize.float("#,###.##", wh / 1000) + " kWh"

def create_summary_frame(title, production, consumption):
    """Create a summary frame with title and energy values."""
    return render.Stack(
        children = [
            render.Column(
                main_align = "space_evenly",
                expanded = True,
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Text(title),
                        ],
                    ),
                    render.Row(
                        children = [
                            render.Column(
                                expanded = True,
                                main_align = "space_around",
                                cross_align = "center",
                                children = [
                                    render.Image(src = SUN_SUM),
                                    render.Image(src = PLUG_SUM),
                                ],
                            ),
                            render.Column(
                                expanded = True,
                                main_align = "space_around",
                                cross_align = "end",
                                children = [
                                    render.Text(
                                        content = " " + format_energy(production),
                                        font = "5x8",
                                        color = GREEN,
                                    ),
                                    render.Text(
                                        content = " " + format_energy(consumption),
                                        font = "5x8",
                                        color = RED,
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        ],
    )

def create_error_frame(message):
    """Create an error display frame."""
    return render.Box(
        render.WrappedText(
            content = message,
            color = RED,
            font = "tb-8",
        ),
    )

def main(config):
    api_key = config.str("api_key")
    site_id = config.str("site_id", "")

    frames = []

    # Get energy data
    if api_key and site_id:
        tz = get_time_zone(site_id, api_key)

        # Day
        day_prod, day_cons, day_err = get_energy_for_period(site_id, api_key, tz, "DAY")
        if day_err:
            return render.Root(create_error_frame("Day: " + day_err))
        frames.append(create_summary_frame("Energy Today", day_prod, day_cons))

        # Week (today + last 6 full days)
        week_prod, week_cons, week_err = get_weekly_energy(site_id, api_key, tz)
        if week_err:
            print("Week error: " + week_err)
            frames.append(create_error_frame("Week Error"))
        else:
            frames.append(create_summary_frame("Energy Week", week_prod, week_cons))

        # Month
        month_prod, month_cons, month_err = get_energy_for_period(site_id, api_key, tz, "MONTH")
        if month_err:
            print("Month error: " + month_err)
            frames.append(create_error_frame("Month Error"))
        else:
            frames.append(create_summary_frame("Energy Month", month_prod, month_cons))

        # Year
        year_prod, year_cons, year_err = get_energy_for_period(site_id, api_key, tz, "YEAR")
        if year_err:
            print("Year error: " + year_err)
            frames.append(create_error_frame("Year Error"))
        else:
            frames.append(create_summary_frame("Energy Year", year_prod, year_cons))

        # Lifetime (sum all years)
        lifetime_prod, lifetime_cons, lifetime_err = get_lifetime_energy(site_id, api_key, tz)
        if lifetime_err:
            print("Lifetime error: " + lifetime_err)
        else:
            frames.append(create_summary_frame("Energy Life", lifetime_prod, lifetime_cons))
    else:
        # Demo data if no credentials
        frames.append(create_summary_frame("Energy Today", 6282, 3141))
        frames.append(create_summary_frame("Energy Week", 43974, 21987))
        frames.append(create_summary_frame("Energy Month", 188460, 94230))
        frames.append(create_summary_frame("Energy Year", 2261520, 1130760))
        frames.append(create_summary_frame("Energy Life", 11307600, 0))

    # Return animation with frames
    return render.Root(
        delay = 3000,  # 3 seconds per frame
        child = render.Animation(children = frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API key",
                desc = "API key for the SolarEdge monitoring API.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "site_id",
                name = "Site ID",
                desc = "The site ID from the monitoring portal.",
                icon = "solarPanel",
            ),
        ],
    )