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

# Icons

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

    if time_unit == "DAY":
        start_string = humanize.time_format("yyyy-MM-dd 00:00:00", now)
    elif time_unit == "MONTH":
        start_string = humanize.time_format("yyyy-MM-01 00:00:00", now)
    elif time_unit == "YEAR":
        start_string = humanize.time_format("yyyy-01-01 00:00:00", now)
    else:
        return None, None

    now_string = humanize.time_format("yyyy-MM-dd HH:mm:ss", now)

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
        print("API error:", rep.status_code)
        return None, None

    data = rep.json()["energyDetails"]
    consumption = 0
    production = 0

    for meter in data["meters"]:
        if meter["type"] == "Consumption":
            for value in meter["values"]:
                consumption += value["value"]
        elif meter["type"] == "Production":
            for value in meter["values"]:
                production += value["value"]

    return production, consumption

def get_lifetime_energy(site_id, api_key, tz):
    """Get lifetime production energy using energyDetails API."""

    # Get installation date or use a very early date
    now = time.now().in_location(tz)
    start_string = "2000-01-01 00:00:00"  # Use early date to capture all history
    now_string = humanize.time_format("yyyy-MM-dd HH:mm:ss", now)

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
        print("Lifetime API error:", rep.status_code, rep.body())
        return None, None

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

    return production, consumption

def format_energy(wh):
    """Format energy value with appropriate unit (kWh, MWh, or GWh)."""
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

def main(config):
    api_key = config.str("api_key")
    site_id = config.str("site_id", "")

    frames = []

    # Get energy data
    if api_key and site_id:
        tz = get_time_zone(site_id, api_key)

        # Day
        day_prod, day_cons = get_energy_for_period(site_id, api_key, tz, "DAY")
        if day_prod == None:
            return render.Root(render.Box(render.WrappedText("API Error", color = RED)))
        frames.append(create_summary_frame("Energy Today", day_prod, day_cons))

        # Month
        month_prod, month_cons = get_energy_for_period(site_id, api_key, tz, "MONTH")
        if month_prod != None:
            frames.append(create_summary_frame("Energy Month", month_prod, month_cons))

        # Year
        year_prod, year_cons = get_energy_for_period(site_id, api_key, tz, "YEAR")
        if year_prod != None:
            frames.append(create_summary_frame("Energy Year", year_prod, year_cons))

        # Lifetime (sum all years)
        lifetime_prod, lifetime_cons = get_lifetime_energy(site_id, api_key, tz)
        if lifetime_prod != None:
            frames.append(create_summary_frame("Energy Life", lifetime_prod, lifetime_cons))
    else:
        # Demo data if no credentials
        frames.append(create_summary_frame("Energy Today", 6282, 3141))
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
