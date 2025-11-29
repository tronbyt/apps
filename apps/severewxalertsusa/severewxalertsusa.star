"""
Applet: SevereWxAlertsUsa
Summary: USA Severe WX Alerts
Description: Display count and contents of Severe Weather Alerts issued by the US National Weather Service for your location.
Author: aschechter88
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/exclamationpoint_img.png", EXCLAMATIONPOINT_IMG_ASSET = "file")
load("images/warning_img.png", WARNING_IMG_ASSET = "file")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

EXCLAMATIONPOINT_IMG = EXCLAMATIONPOINT_IMG_ASSET.readall()
WARNING_IMG = WARNING_IMG_ASSET.readall()

DEFAULT_LOCATION = """
{
	"lat": "47.2631",
    "lng": "-122.3447",
    "name": "Seattle"
}
"""

## run the main applications
def main(config):
    scale = 2 if canvas.is2x() else 1
    jsonLocation = json.decode(config.str("location") or DEFAULT_LOCATION)  ## set the location from the schema data or use the default
    if "locality" not in jsonLocation:
        jsonLocation["locality"] = config.str("display_name") or jsonLocation.get("name", "")[0:13]
    alerts = get_alerts(jsonLocation["lat"], jsonLocation["lng"])  ## call for the alerts for this location

    foundAlerts = 0  # default alert detection to false

    columnFrames = []  # Create the master list of frames for the sequence render

    ## check for alerts and count.
    foundAlerts += len(alerts)

    ## if found, render summary frame
    if (foundAlerts):  ## render the summary card and then each card
        columnFrames.append(render_summary_card_for_alerts(jsonLocation, foundAlerts, scale))

        alertCounter = 0  ## this...could have been done differently

        for alert in alerts:
            alertCounter += 1
            columnFrames.append(render_alert(alert, alertCounter, foundAlerts, scale))
    elif config.bool("alert_only", False):  ## no alerts, hide app
        return []
    else:  ## no alerts, show the green no alerts screen
        columnFrames.append(render_summary_card_zero_alerts(jsonLocation, scale))

    return render.Root(
        delay = 5000,
        show_full_animation = True,
        child = render.Animation(columnFrames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display alerts.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "display_name",
                name = "Display Nmae",
                desc = "A custom display name",
                icon = "quoteRight",
            ),
            schema.Toggle(
                id = "alert_only",
                name = "Alerts only",
                desc = "Enable to show app only when there are alerts.",
                icon = "eyeSlash",
                default = False,
            ),
        ],
    )

## Acquire the set of Weather Alerts for this lat/long point for both Forecast Zone and County level alerts. Return a dict.
def get_alerts(lat, long):
    ## truncate location for privacy without sacrificing useable accuracy
    truncatedLat = truncate_location_digits(lat)
    truncatedLong = truncate_location_digits(long)

    ## master list
    alerts = []

    ## check cache, 5 minutes TTL
    cachekey = "lawnchairs.severewxalertsusa." + truncatedLat + "." + truncatedLong  ##cache key is for a lat/long pair

    if (cache.get(cachekey) != None):
        ## cache hit
        alerts = json.decode(cache.get(cachekey))
        return alerts

    else:
        ## cache miss

        ## Get the alerts for the lat/long point and append them to the alerts dictionary.

        pointAlertsResponse = http.get("https://api.weather.gov/alerts/active?point=" + truncatedLat + "," + truncatedLong)

        if "features" not in pointAlertsResponse.json():
            return []
        for item in pointAlertsResponse.json()["features"]:
            ## filter out test alerts
            if (item["properties"]["status"] == "Test"):
                continue
            else:
                alerts.append(item)

        # set cache. cast object to jsonstring
        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(
            key = cachekey,
            value = json.encode(alerts),
            ttl_seconds = 300,
        )

        return alerts

## Render the alert frame
def render_alert(alert, alertIndex, totalAlerts, scale = 1):
    ## Master column.
    column = []

    ## top row - Alert count row
    alertCountRenderText = render.Text(
        content = "WX ALERT " + str(alertIndex) + "/" + str(totalAlerts),
        color = "#FFFF00",
        font = "CG-pixel-3x5-mono" if scale == 1 else "terminus-12",  # tiny
    )
    alertCountRenderBox = render.Box(
        child = alertCountRenderText,
        height = 5 if scale == 1 else 11,
    )
    alertCounterRenderRow = render.Row(
        children = [alertCountRenderBox],
        expanded = True,
        main_align = "center",
    )
    column.append(alertCounterRenderRow)  ## add top row to master column

    ## middle row - alert icon and text
    titleRowWidgets = []

    ## Severity Icon for moderate
    severity = alert["properties"]["severity"]
    icon_src = None
    if severity in ("Moderate", "Minor"):
        icon_src = EXCLAMATIONPOINT_IMG
    elif severity in ("Severe", "Extreme"):
        icon_src = WARNING_IMG

    if icon_src:
        box = render.Box(
            child = render.Image(
                src = icon_src,
                height = 16 * scale,
                width = 16 * scale,
            ),
            width = 16 * scale,
            height = 22 if scale == 1 else 40,
        )
        titleRowWidgets.append(box)

    ## Main Alert Text
    mainAlertText = alert["properties"]["event"]

    mainAlertTextWrappedWidget = render.WrappedText(
        content = mainAlertText.upper(),
        align = "center",
        font = "CG-pixel-3x5-mono" if scale == 1 else "terminus-14",  # tiny
        color = "#FF0000",  # red
        linespacing = 1 if scale == 1 else -1,
    )

    mainAlertTextWrappedWidget = render.Box(
        child = mainAlertTextWrappedWidget,
        height = 22 if scale == 1 else 40,
        width = 48 * scale,
    )
    titleRowWidgets.append(mainAlertTextWrappedWidget)

    titleRow = render.Row(
        children = titleRowWidgets,
        expanded = True,
        main_align = "center",
    )

    column.append(titleRow)

    ## bottom row - Alert Expiration Time

    ## "ends" is the key, but can be None for ongoing/until further notice events.
    ## see https://github.com/weather-gov/api/discussions/385#discussioncomment-592840

    if (alert["properties"]["ends"] == None):
        untilText = "ONGOING"
    else:
        alertExpirationTime = time.parse_time(alert["properties"]["ends"])
        untilText = "End: " + alertExpirationTime.format("15:04 Mon")  ## format date

    alertRenderText = render.WrappedText(
        untilText,
        align = "center",
        font = "CG-pixel-3x5-mono" if scale == 1 else "terminus-12",  ## make it small
    )
    alertRenderBox = render.Box(
        child = alertRenderText,
        height = 5 if scale == 1 else 11,
    )
    alertRow = render.Row(
        children = [alertRenderBox],
        expanded = True,
        main_align = "center",
    )

    column.append(alertRow)

    ## Return master column assembly
    return render.Column(
        children = column,
        main_align = "center",
    )

def render_summary_card_for_alerts(location, alerts, scale = 1):
    # master column list
    master_column = []

    # first row -- fixed title
    titleText = render.Text(
        content = "WEATHER ALERTS",
        color = "#FFFF00",
        font = "CG-pixel-3x5-mono" if scale == 1 else "terminus-12",  # tiny
    )
    titleBox = render.Box(
        child = titleText,
        height = 5 if scale == 1 else 11,
    )
    titleRow = render.Row(
        children = [titleBox],
        expanded = True,
        main_align = "center",
    )

    master_column.append(titleRow)

    ## text format
    alertsCountString = " ALERT"
    if (alerts > 1):
        alertsCountString += "S"

    ## center row
    alertsText = render.Text(
        content = str(alerts) + alertsCountString,
        color = "#FFFF00",
        font = "6x13" if scale == 1 else "terminus-24",
    )
    alertsBox = render.Box(
        child = alertsText,
        height = 16 * scale,
    )

    alertsRow = render.Row(
        children = [alertsBox],
        expanded = True,
        main_align = "center",
    )

    master_column.append(alertsRow)

    # location row -- bottom
    # location row -- bottom
    locationText = render.WrappedText(
        content = location["locality"][0:16],
        align = "center",
        font = "CG-pixel-3x5-mono" if scale == 1 else "terminus-14-light",  # tiny
        linespacing = 1,
    )
    locationBox = render.Box(
        child = locationText,
        height = 11 * scale,
    )
    locationRow = render.Row(
        children = [locationBox],
        expanded = True,
        main_align = "center",
    )

    master_column.append(locationRow)

    return render.Column(master_column)

def render_summary_card_zero_alerts(location, scale = 1):
    # master column list
    master_column = []

    # first row -- fixed title
    titleText = render.Text(
        content = "WEATHER ALERTS",
        color = "#FFFF00",
        font = "CG-pixel-3x5-mono" if scale == 1 else "terminus-12",  # tiny
    )
    titleBox = render.Box(
        child = titleText,
        height = 5 if scale == 1 else 11,
    )
    titleRow = render.Row(
        children = [titleBox],
        expanded = True,
        main_align = "center",
    )

    master_column.append(titleRow)

    ## center row
    alertsText = render.Text(
        content = "No Alerts",
        color = "#00FF00",
        font = "6x13" if scale == 1 else "terminus-24",
    )

    alertsBox = render.Box(
        child = alertsText,
        height = 17 if scale == 1 else 32,
    )

    alertsRow = render.Row(
        children = [alertsBox],
        expanded = True,
        main_align = "center",
    )

    master_column.append(alertsRow)

    # location row -- bottom
    locationText = render.WrappedText(
        content = location["locality"],
        align = "center",
        font = "CG-pixel-3x5-mono" if scale == 1 else "terminus-14-light",  # tiny
    )
    locationBox = render.Box(
        child = locationText,
        height = 10 * scale,
    )
    locationRow = render.Row(
        children = [locationBox],
        expanded = True,
        main_align = "center",
    )

    master_column.append(locationRow)

    return render.Column(master_column)

def truncate_location_digits(inputDigits):
    return str(int(math.round(float(inputDigits) * 200)) / 200)
