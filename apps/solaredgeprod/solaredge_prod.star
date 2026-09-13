"""
Applet: SolarEdge_Prod
Summary: SolarEdge daily production
Description: Monitor SolarEdge PV panel daily current and daily production.
Author: Billy_McSkintos
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("images/power_icon.png", POWER_ICON_ASSET = "file")
load("images/today_icon.png", TODAY_ICON_ASSET = "file")
load("images/tree_icon.png", TREE_ICON_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

POWER_ICON = POWER_ICON_ASSET.readall()
TODAY_ICON = TODAY_ICON_ASSET.readall()
TREE_ICON = TREE_ICON_ASSET.readall()

# ICONS --------------------------------- https://easy64.org/icons/material-ui-filled/
# Sun to represent current power

# Bird (swallow) to represent sum ∑ production (Today)

# Tree to represent environment benefits (equivalent Trees planted)

# END ICONS ----------------------------------------

# API ENDPOINTS
SE_DETAILS_URL = "https://monitoringapi.solaredge.com/site/{}/details"
SE_OVERVIEW_URL = "https://monitoringapi.solaredge.com/sites/{}/overview"
SE_POWER_URL = "https://monitoringapi.solaredge.com/sites/{}/power"
SE_ENVBEN_URL = "https://monitoringapi.solaredge.com/site/{}/envBenefits"

# SolarEdge API limit is 300 requests per day, which is about one per 5 minutes
CACHE_TTL = 300

# Dummy Data
DUMMY_DETAILS = {
    "details": {
        "Id": 93082,
        "name": "Smith, John CRM1234",
        "status": "Active",
        "peakPower": 8.04,
        "installationDate": "2022-11-10",
        "lastUpdateTime": "2023-02-08T13:32:57.597429300+02:00",
        "location": {
            "address": "2888 Main St",
            "city": "Green Bay",
            "state": "Wisconsin",
            "zip": "54311",
            "timeZone": "America/Los_Angeles",
            "country": "United States",
        },
    },
    "activationStatus": "Active",
    "note": "Created via API, triggered from CRM",
}
DUMMY_OVERVIEW = {
    "sitesOverviews": {
        "count": 1,
        "siteEnergyList": [
            {
                "siteId": 93082,
                "siteOverview": {
                    "lastUpdateTime": "2024-10-16 20:00:41",
                    "lifeTimeData": {
                        "energy": 8.6302544e7,
                    },
                    "lastYearData": {
                        "energy": 1.0232828e7,
                    },
                    "lastMonthData": {
                        "energy": 470202.0,
                    },
                    "lastDayData": {
                        "energy": 4973.0,
                    },
                    "currentPower": {
                        "power": 2.5,
                    },
                    "measuredBy": "INVERTER",
                },
            },
        ],
    },
}
DUMMY_POWER = {"powerDateValuesList": {"timeUnit": "QUARTER_OF_AN_HOUR", "unit": "Wh", "count": 1, "siteEnergyList": [{"siteId": 93082, "powerDataValueSeries": {"measuredBy": "INVERTER", "values": [{"date": "2024-09-26 00:00:00", "value": 0}, {"date": "2024-09-26 00:15:00", "value": 0}, {"date": "2024-09-26 00:30:00", "value": 0}, {"date": "2024-09-26 00:45:00", "value": 0}, {"date": "2024-09-26 01:00:00", "value": 0}, {"date": "2024-09-26 01:15:00", "value": 0}, {"date": "2024-09-26 01:30:00", "value": 0}, {"date": "2024-09-26 01:45:00", "value": 0}, {"date": "2024-09-26 02:00:00", "value": 0}, {"date": "2024-09-26 02:15:00", "value": 0}, {"date": "2024-09-26 02:30:00", "value": 0}, {"date": "2024-09-26 02:45:00", "value": 0}, {"date": "2024-09-26 03:00:00", "value": 0}, {"date": "2024-09-26 03:15:00", "value": 0}, {"date": "2024-09-26 03:30:00", "value": 0}, {"date": "2024-09-26 03:45:00", "value": 0}, {"date": "2024-09-26 04:00:00", "value": 0}, {"date": "2024-09-26 04:15:00", "value": 0}, {"date": "2024-09-26 04:30:00", "value": 0}, {"date": "2024-09-26 04:45:00", "value": 0}, {"date": "2024-09-26 05:00:00", "value": 0}, {"date": "2024-09-26 05:15:00", "value": 0}, {"date": "2024-09-26 05:30:00", "value": 0}, {"date": "2024-09-26 05:45:00", "value": 0}, {"date": "2024-09-26 06:00:00", "value": 0}, {"date": "2024-09-26 06:15:00", "value": 0}, {"date": "2024-09-26 06:30:00", "value": 0.0}, {"date": "2024-09-26 06:45:00", "value": 28.20339}, {"date": "2024-09-26 07:00:00", "value": 330.0702}, {"date": "2024-09-26 07:15:00", "value": 803.22736}, {"date": "2024-09-26 07:30:00", "value": 1229.7477}, {"date": "2024-09-26 07:45:00", "value": 1726.0985}, {"date": "2024-09-26 08:00:00", "value": 2314.6704}, {"date": "2024-09-26 08:15:00", "value": 2808.336}, {"date": "2024-09-26 08:30:00", "value": 3200.5237}, {"date": "2024-09-26 08:45:00", "value": 3861.0115}, {"date": "2024-09-26 09:00:00", "value": 2667.2664}, {"date": "2024-09-26 09:15:00", "value": 3702.738}, {"date": "2024-09-26 09:30:00", "value": 3899.0742}, {"date": "2024-09-26 09:45:00", "value": 4074.556}, {"date": "2024-09-26 10:00:00", "value": 5005.2114}, {"date": "2024-09-26 10:15:00", "value": 5219.524}, {"date": "2024-09-26 10:30:00", "value": 5401.679}, {"date": "2024-09-26 10:45:00", "value": 5482.9463}, {"date": "2024-09-26 11:00:00", "value": 5546.6094}, {"date": "2024-09-26 11:15:00", "value": 5618.715}, {"date": "2024-09-26 11:30:00", "value": 5787.866}, {"date": "2024-09-26 11:45:00", "value": 5838.005}, {"date": "2024-09-26 12:00:00", "value": 5878.04}, {"date": "2024-09-26 12:15:00", "value": 5812.9473}, {"date": "2024-09-26 12:30:00", "value": 5695.7544}, {"date": "2024-09-26 12:45:00", "value": 5627.9507}, {"date": "2024-09-26 13:00:00", "value": 5520.496}, {"date": "2024-09-26 13:15:00", "value": 5408.7124}, {"date": "2024-09-26 13:30:00", "value": 5269.7275}, {"date": "2024-09-26 13:45:00", "value": 5113.8677}, {"date": "2024-09-26 14:00:00", "value": 4870.078}, {"date": "2024-09-26 14:15:00", "value": 4447.6665}, {"date": "2024-09-26 14:30:00", "value": 4249.9507}, {"date": "2024-09-26 14:45:00", "value": 3917.5012}, {"date": "2024-09-26 15:00:00", "value": 3313.5635}, {"date": "2024-09-26 15:15:00", "value": 2951.1216}, {"date": "2024-09-26 15:30:00", "value": 2278.4043}, {"date": "2024-09-26 15:45:00", "value": 1451.3462}, {"date": "2024-09-26 16:00:00", "value": 754.223}, {"date": "2024-09-26 16:15:00", "value": 483.0793}, {"date": "2024-09-26 16:30:00", "value": 393.97345}, {"date": "2024-09-26 16:45:00", "value": 350.81155}, {"date": "2024-09-26 17:00:00", "value": 269.044}, {"date": "2024-09-26 17:15:00", "value": 183.84143}, {"date": "2024-09-26 17:30:00", "value": 146.71786}, {"date": "2024-09-26 17:45:00", "value": 114.39638}, {"date": "2024-09-26 18:00:00", "value": 89.0317}, {"date": "2024-09-26 18:15:00", "value": 27.960232}, {"date": "2024-09-26 18:30:00", "value": 0.0}, {"date": "2024-09-26 18:45:00", "value": 0.0}, {"date": "2024-09-26 19:00:00", "value": 0}, {"date": "2024-09-26 19:15:00", "value": 0}, {"date": "2024-09-26 19:30:00", "value": 0}, {"date": "2024-09-26 19:45:00", "value": 0}, {"date": "2024-09-26 20:00:00", "value": 0}, {"date": "2024-09-26 20:15:00", "value": 0}, {"date": "2024-09-26 20:30:00", "value": 0}, {"date": "2024-09-26 20:45:00", "value": 0.0}, {"date": "2024-09-26 21:00:00", "value": 0}, {"date": "2024-09-26 21:15:00", "value": 0}, {"date": "2024-09-26 21:30:00", "value": 0}, {"date": "2024-09-26 21:45:00", "value": 0}, {"date": "2024-09-26 22:00:00", "value": 0}, {"date": "2024-09-26 22:15:00", "value": 0}, {"date": "2024-09-26 22:30:00", "value": 0}, {"date": "2024-09-26 22:45:00", "value": 0}, {"date": "2024-09-26 23:00:00", "value": 0}, {"date": "2024-09-26 23:15:00", "value": 0}, {"date": "2024-09-26 23:30:00", "value": 0}, {"date": "2024-09-26 23:45:00", "value": 0}]}}]}}

DUMMY_ENV = {
    "envBenefits": {
        "gasEmissionSaved": {
            "units": "kg",
            "co2": 60670.688,
            "so2": 43841.69,
            "nox": 13981.012,
        },
        "treesPlanted": 1234.00,
        "lightBulbs": 261522.86,
    },
}

# END API ENDPOINTS

def main(config):
    api_key = config.str("api_key")
    site_id = humanize.url_encode(config.str("site_id", ""))
    headers = {"X-API-Key": api_key, "content-type": "application/json"}

    # API CALLS ----------------------------------------
    #   Details ---------------------------------------
    if api_key and site_id:
        url_details = SE_DETAILS_URL.format(site_id)
        res_details = http.get(url_details, headers = headers, ttl_seconds = CACHE_TTL)
        if res_details.status_code != 200:
            fail("SolarEdge Monitoring: Overview request failed with status %d", res_details.status_code)
    else:
        res_details = DUMMY_DETAILS

    #   Overview ---------------------------------------
    if api_key and site_id:
        url_overview = SE_OVERVIEW_URL.format(site_id)
        res_overview = http.get(url_overview, headers = headers, ttl_seconds = CACHE_TTL)
        if res_overview.status_code != 200:
            fail("SolarEdge Monitoring: Overview request failed with status %d", res_overview.status_code)
    else:
        res_overview = DUMMY_OVERVIEW

    timezone = config.get("timezone") or "America/Los_Angeles"
    startTime = time.now().in_location(timezone).format("2006-01-02 00:00:00")
    endTime = time.now().in_location(timezone).format("2006-01-02") + " 23:59:59"

    #   Power ---------------------------------------
    if api_key and site_id:
        url_power = SE_POWER_URL.format(site_id)
        params = {"startTime": startTime, "endTime": endTime}
        res_power = http.get(url_power, params = params, headers = headers, ttl_seconds = CACHE_TTL)
        if res_power.status_code != 200:
            fail("SolarEdge Monitoring: Power request failed with status %d", res_power.status_code)
    else:
        res_power = DUMMY_POWER

    #   Environmental Benefits ---------------------------------------
    if api_key and site_id:
        url_envben = SE_ENVBEN_URL.format(site_id)
        res_envben = http.get(url_envben, headers = headers, ttl_seconds = CACHE_TTL * 160)
        if res_envben.status_code != 200:
            fail("SolarEdge Monitoring: Overview request failed with status %d", res_envben.status_code)
    else:
        res_envben = DUMMY_ENV

    # END API CALLS ----------------------------------------

    # PARSE RESPONSES
    if api_key and site_id:
        peak_power = math.round(res_details.json()["details"]["peakPower"])
    else:
        peak_power = 8.04
    if api_key and site_id:
        current_power = str(float(math.round(res_overview.json()["sitesOverviews"]["siteEnergyList"][0]["siteOverview"]["currentPower"]["power"] / 100) / 10))
    else:
        current_power = 1.2
    if api_key and site_id:
        energy_today = math.round(res_overview.json()["sitesOverviews"]["siteEnergyList"][0]["siteOverview"]["lastDayData"]["energy"] * 0.001)
    else:
        energy_today = 34.5
    if api_key and site_id:
        trees_planted = math.round(res_envben.json()["envBenefits"]["treesPlanted"])
    else:
        trees_planted = 1234

    # Extract the values
    if api_key and site_id:
        values = res_power.json()["powerDateValuesList"]["siteEnergyList"][0]["powerDataValueSeries"]["values"]
    else:
        # o = DUMMY_POWER
        #values = o.json()["powerDateValuesList"]["siteEnergyList"][0]["powerDataValueSeries"]["values"]
        values = {"date": "2024-09-26 00:00:00", "value": 0}, {"date": "2024-09-26 00:15:00", "value": 0}, {"date": "2024-09-26 00:30:00", "value": 0}, {"date": "2024-09-26 00:45:00", "value": 0}, {"date": "2024-09-26 01:00:00", "value": 0}, {"date": "2024-09-26 01:15:00", "value": 0}, {"date": "2024-09-26 01:30:00", "value": 0}, {"date": "2024-09-26 01:45:00", "value": 0}, {"date": "2024-09-26 02:00:00", "value": 0}, {"date": "2024-09-26 02:15:00", "value": 0}, {"date": "2024-09-26 02:30:00", "value": 0}, {"date": "2024-09-26 02:45:00", "value": 0}, {"date": "2024-09-26 03:00:00", "value": 0}, {"date": "2024-09-26 03:15:00", "value": 0}, {"date": "2024-09-26 03:30:00", "value": 0}, {"date": "2024-09-26 03:45:00", "value": 0}, {"date": "2024-09-26 04:00:00", "value": 0}, {"date": "2024-09-26 04:15:00", "value": 0}, {"date": "2024-09-26 04:30:00", "value": 0}, {"date": "2024-09-26 04:45:00", "value": 0}, {"date": "2024-09-26 05:00:00", "value": 0}, {"date": "2024-09-26 05:15:00", "value": 0}, {"date": "2024-09-26 05:30:00", "value": 0}, {"date": "2024-09-26 05:45:00", "value": 0}, {"date": "2024-09-26 06:00:00", "value": 0}, {"date": "2024-09-26 06:15:00", "value": 0}, {"date": "2024-09-26 06:30:00", "value": 0.0}, {"date": "2024-09-26 06:45:00", "value": 28.20339}, {"date": "2024-09-26 07:00:00", "value": 330.0702}, {"date": "2024-09-26 07:15:00", "value": 803.22736}, {"date": "2024-09-26 07:30:00", "value": 1229.7477}, {"date": "2024-09-26 07:45:00", "value": 1726.0985}, {"date": "2024-09-26 08:00:00", "value": 2314.6704}, {"date": "2024-09-26 08:15:00", "value": 2808.336}, {"date": "2024-09-26 08:30:00", "value": 3200.5237}, {"date": "2024-09-26 08:45:00", "value": 3861.0115}, {"date": "2024-09-26 09:00:00", "value": 2667.2664}, {"date": "2024-09-26 09:15:00", "value": 3702.738}, {"date": "2024-09-26 09:30:00", "value": 3899.0742}, {"date": "2024-09-26 09:45:00", "value": 4074.556}, {"date": "2024-09-26 10:00:00", "value": 5005.2114}, {"date": "2024-09-26 10:15:00", "value": 5219.524}, {"date": "2024-09-26 10:30:00", "value": 5401.679}, {"date": "2024-09-26 10:45:00", "value": 5482.9463}, {"date": "2024-09-26 11:00:00", "value": 5546.6094}, {"date": "2024-09-26 11:15:00", "value": 5618.715}, {"date": "2024-09-26 11:30:00", "value": 5787.866}, {"date": "2024-09-26 11:45:00", "value": 5838.005}, {"date": "2024-09-26 12:00:00", "value": 5878.04}, {"date": "2024-09-26 12:15:00", "value": 5812.9473}, {"date": "2024-09-26 12:30:00", "value": 5695.7544}, {"date": "2024-09-26 12:45:00", "value": 5627.9507}, {"date": "2024-09-26 13:00:00", "value": 5520.496}, {"date": "2024-09-26 13:15:00", "value": 5408.7124}, {"date": "2024-09-26 13:30:00", "value": 5269.7275}, {"date": "2024-09-26 13:45:00", "value": 5113.8677}, {"date": "2024-09-26 14:00:00", "value": 4870.078}, {"date": "2024-09-26 14:15:00", "value": 4447.6665}, {"date": "2024-09-26 14:30:00", "value": 4249.9507}, {"date": "2024-09-26 14:45:00", "value": 3917.5012}, {"date": "2024-09-26 15:00:00", "value": 3313.5635}, {"date": "2024-09-26 15:15:00", "value": 2951.1216}, {"date": "2024-09-26 15:30:00", "value": 2278.4043}, {"date": "2024-09-26 15:45:00", "value": 1451.3462}, {"date": "2024-09-26 16:00:00", "value": 754.223}, {"date": "2024-09-26 16:15:00", "value": 483.0793}, {"date": "2024-09-26 16:30:00", "value": 393.97345}, {"date": "2024-09-26 16:45:00", "value": 350.81155}, {"date": "2024-09-26 17:00:00", "value": 269.044}, {"date": "2024-09-26 17:15:00", "value": 183.84143}, {"date": "2024-09-26 17:30:00", "value": 146.71786}, {"date": "2024-09-26 17:45:00", "value": 114.39638}, {"date": "2024-09-26 18:00:00", "value": 89.0317}, {"date": "2024-09-26 18:15:00", "value": 27.960232}, {"date": "2024-09-26 18:30:00", "value": 0.0}, {"date": "2024-09-26 18:45:00", "value": 0.0}, {"date": "2024-09-26 19:00:00", "value": 0}, {"date": "2024-09-26 19:15:00", "value": 0}, {"date": "2024-09-26 19:30:00", "value": 0}, {"date": "2024-09-26 19:45:00", "value": 0}, {"date": "2024-09-26 20:00:00", "value": 0}, {"date": "2024-09-26 20:15:00", "value": 0}, {"date": "2024-09-26 20:30:00", "value": 0}, {"date": "2024-09-26 20:45:00", "value": 0.0}, {"date": "2024-09-26 21:00:00", "value": 0}, {"date": "2024-09-26 21:15:00", "value": 0}, {"date": "2024-09-26 21:30:00", "value": 0}, {"date": "2024-09-26 21:45:00", "value": 0}, {"date": "2024-09-26 22:00:00", "value": 0}, {"date": "2024-09-26 22:15:00", "value": 0}, {"date": "2024-09-26 22:30:00", "value": 0}, {"date": "2024-09-26 22:45:00", "value": 0}, {"date": "2024-09-26 23:00:00", "value": 0}, {"date": "2024-09-26 23:15:00", "value": 0}, {"date": "2024-09-26 23:30:00", "value": 0}, {"date": "2024-09-26 23:45:00", "value": 0}

    # Create the data array
    data_array = []
    for i, entry in enumerate(values):
        value = entry["value"] if entry["value"] != None else 0.0
        data_array.append((i, value * 0.001))

    # RENDER APP
    return render.Root(
        render.Column(
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "center",
                    children = [
                        render.Image(src = POWER_ICON, height = 10, width = 8),
                        render.Text(content = "%s" % current_power),
                        render.Text(font = "tom-thumb", color = "#717171", content = "kW"),
                        render.Image(src = TODAY_ICON, height = 10, width = 9),
                        render.Text(content = "%d" % energy_today),
                        render.Text(font = "tom-thumb", color = "#717171", content = "kWh"),
                    ],
                ),
                render.Stack(
                    children = [
                        render.Row(
                            children = [
                                render.Plot(
                                    data = data_array,
                                    width = 64,
                                    height = 22,
                                    color = "#0f0",
                                    x_lim = (0, 95),
                                    y_lim = (0, peak_power),
                                    fill = True,
                                ),
                            ],
                        ),
                        render.Box(
                            padding = 1,
                            height = 24,
                            width = 20,
                            child =
                                render.Column(
                                    #main_align="end",
                                    children = [
                                        render.Row(
                                            main_align = "center",
                                            children = [
                                                render.Text(content = "%d" % trees_planted, font = "CG-pixel-3x5-mono"),
                                            ],
                                        ),
                                        render.Box(
                                            #padding=2,
                                            height = 13,
                                            width = 16,
                                            child =
                                                render.Row(
                                                    main_align = "center",
                                                    children = [
                                                        render.Image(src = TREE_ICON, height = 13, width = 14),
                                                    ],
                                                ),
                                        ),
                                    ],
                                ),
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
                id = "api_key",
                name = "API key",
                desc = "API key for the SolarEdge monitoring API.",
                icon = "key",
                default = "",
                secret = True,
            ),
            schema.Text(
                id = "site_id",
                name = "Site ID",
                desc = "The site ID, available from the monitoring portal.",
                icon = "solarPanel",
                default = "",
            ),
        ],
    )
