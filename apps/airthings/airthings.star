"""
Applet: AirThings
Summary: Environment sensor readings
Description: Environment sensor readings from an AirThings sensor.
Author: joshspicer
"""

# AirThings Environment Sensor Applet
#
# Copyright (c) 2022 Josh Spicer <hello@joshspicer.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    # Require secrets
    clientId = config.get("clientId")
    clientSecret = config.get("clientSecret")
    serialNumber = config.get("serialNumber")

    # Options
    skipRenderIfAllGreen = config.bool("skipRenderIfAllGreen")
    onlyDisplayNotNormal = config.bool("onlyDisplayNotNormal")
    enableScrolling = config.bool("enableScrolling", True)
    scrollSpeed = int(config.get("scrollSpeed", "100"))
    fontSize = config.get("fontSize", "medium")
    tempUnit = config.get("tempUnit", "celsius")

    # Thresholds - with safe defaults to prevent breaking changes
    co2_yellow = int(config.get("co2_yellow") or "800")
    co2_red = int(config.get("co2_red") or "1000")
    pm25_yellow = int(config.get("pm25_yellow") or "10")
    pm25_red = int(config.get("pm25_red") or "25")
    temp_f_yellow = int(config.get("temp_f_yellow") or "72")
    temp_f_red = int(config.get("temp_f_red") or "77")
    temp_c_yellow = int(config.get("temp_c_yellow") or "22")
    temp_c_red = int(config.get("temp_c_red") or "25")
    voc_yellow = int(config.get("voc_yellow") or "250")
    voc_red = int(config.get("voc_red") or "2000")
    humidity_low = int(config.get("humidity_low") or "30")
    humidity_yellow = int(config.get("humidity_yellow") or "60")
    humidity_red = int(config.get("humidity_red") or "70")
    radon_yellow = float(config.get("radon_yellow") or "2.7")
    radon_red = float(config.get("radon_red") or "4.0")

    hidePm25 = config.bool("hidePm25")
    hideVoc = config.bool("hideVoc")
    hideTemp = config.bool("hideTemp")
    hideCo2 = config.bool("hideCo2")
    hideHumidity = config.bool("hideHumidity")
    hideRadon = config.bool("hideRadon")

    if not clientId or not clientSecret or not serialNumber:
        return render.Root(
            child = render.WrappedText(
                content = "AirThings credentials missing.",
            ),
        )

    # Key unique to the user to fetch cached access_token
    ACCESS_TOKEN_CACHE_KEY = "%s-%s-%s" % (clientId, serialNumber, clientSecret)
    SAMPLES_CACHE_KEY = "samples-%s-%s" % (clientId, serialNumber)

    access_token = cache.get(ACCESS_TOKEN_CACHE_KEY)
    if access_token == None or access_token == "":
        print("[+] Refreshing Token...")
        access_token = client_credentials_grant_flow(config, ACCESS_TOKEN_CACHE_KEY)
    else:
        print("[+] Using Cached Token...")

    # Read samples from cache if available
    samplesString = cache.get(SAMPLES_CACHE_KEY)

    if samplesString == None or samplesString == "":
        print("[+] Fetching Samples...")

        # https://developer.airthings.com/consumer-api-docs/#operation/Device%20samples%20latest-values
        samples = get_samples(config, access_token, SAMPLES_CACHE_KEY)
    else:
        print("[+] Using Cached Samples...")
        samples = json.decode(samplesString)

    print(samples)

    co2 = samples["data"]["co2"]
    if "pm25" in samples["data"]:
        pm25 = samples["data"]["pm25"]
    else:
        pm25 = -1
    
    # Convert temperature based on user preference
    temp_celsius = samples["data"]["temp"]
    if tempUnit == "fahrenheit":
        temp = (temp_celsius * 9 / 5) + 32
        temp_threshold_yellow = temp_f_yellow
        temp_threshold_red = temp_f_red
    else:  # celsius (original behavior)
        temp = temp_celsius
        temp_threshold_yellow = temp_c_yellow
        temp_threshold_red = temp_c_red
    
    voc = samples["data"]["voc"]
    humidity = samples["data"]["humidity"]
    
    # Get radon short term value and convert from Bq/m³ to pCi/L
    if "radonShortTermAvg" in samples["data"]:
        radon_bq = samples["data"]["radonShortTermAvg"]
        # Convert Bq/m³ to pCi/L (1 Bq/m³ = 0.027 pCi/L)
        radon = radon_bq * 0.027
    else:
        radon = -1

    # https://help.airthings.com/en/articles/5367327-view-understanding-the-sensor-thresholds
    co2_color = "#0f0"
    pm25_color = "#0f0"
    temp_color = "#0f0"
    voc_color = "#0f0"
    humidity_color = "#0f0"
    radon_color = "#0f0"

    if co2 > co2_red:
        co2_color = "#f00"
    elif co2 > co2_yellow:
        co2_color = "#ff0"

    if pm25 > pm25_red:
        pm25_color = "#f00"
    elif pm25 > pm25_yellow:
        pm25_color = "#ff0"

    # Temperature thresholds based on selected unit
    if temp > temp_threshold_red:
        temp_color = "#f00"
    elif temp > temp_threshold_yellow:
        temp_color = "#ff0"

    if voc > voc_red:
        voc_color = "#f00"
    elif voc > voc_yellow:
        voc_color = "#ff0"

    if humidity > humidity_red or humidity < humidity_low:
        humidity_color = "#f00"
    elif humidity > humidity_yellow:
        humidity_color = "#ff0"

    # Radon thresholds (pCi/L)
    if radon > radon_red:
        radon_color = "#f00"
    elif radon > radon_yellow:
        radon_color = "#ff0"

    allGreen = True
    nonNormalValues = []
    for (sample, hidden, displayName) in [
        (temp_color, hideTemp, "Temp"),
        (humidity_color, hideHumidity, "Humidity"),
        (co2_color, hideCo2, "Co2"),
        (pm25_color, hidePm25, "Pm2.5"),
        (voc_color, hideVoc, "VOC"),
        (radon_color, hideRadon, "Radon"),
    ]:
        if not onlyDisplayNotNormal and hidden:
            continue

        if not sample == "#0f0":
            allGreen = False
            if onlyDisplayNotNormal:
                nonNormalValues.append(displayName)
            break

    if skipRenderIfAllGreen and allGreen:
        # Skip rendering
        print("All green, nothing to report!")
        return []

    items = []
    if pm25 == -1:
        pm25 = "n/a"
    if radon == -1:
        radon = "n/a"
    else:
        # Round radon to 1 decimal place
        radon = int(radon * 10) / 10
    
    # Round temperature to 1 decimal place
    temp = int(temp * 10) / 10
    
    # Set font based on fontSize option
    if fontSize == "small":
        font = "tom-thumb"
    elif fontSize == "large":
        font = "6x13"
    else:  # medium
        font = "tb-8"
    
    for (hide, reading, color, displayName) in [
        (hideTemp, temp, temp_color, "Temp"),
        (hideHumidity, humidity, humidity_color, "Humidity"),
        (hideCo2, co2, co2_color, "Co2"),
        (hidePm25, pm25, pm25_color, "Pm2.5"),
        (hideVoc, voc, voc_color, "VOC"),
        (hideRadon, radon, radon_color, "Radon"),
    ]:
        if not onlyDisplayNotNormal and hide:
            continue

        if onlyDisplayNotNormal and not displayName in nonNormalValues:
            continue

        items.append(
            render.Row(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Text(
                        content = displayName,
                        color = color,
                        font = font,
                    ),
                    render.Text(
                        content = str(reading),
                        color = color,
                        font = font,
                    ),
                ],
            ),
        )

    if enableScrolling:
        return render.Root(
            child = render.Marquee(
                height = 32,
                scroll_direction = "vertical",
                offset_start = 32,
                offset_end = 32,
                child = render.Column(
                    children = items,
                ),
            ),
            delay = scrollSpeed,
            max_age = 120,
        )
    else:
        return render.Root(
            child = render.Column(
                children = items,
            ),
        )

def get_samples(config, access_token, SAMPLES_CACHE_KEY):
    serial_number = config["serialNumber"]
    if serial_number == None:
        fail("serial_number is required")

    url = "https://ext-api.airthings.com/v1/devices/" + serial_number + "/latest-samples"
    headers = {
        "Authorization": "Bearer " + access_token,
    }
    res = http.get(url, headers = headers)

    if res.status_code != 200:
        print("Error fetching samples: %s" % (res.body()))
        fail("fetching samples failed with status code: %d - %s" % (res.status_code, res.body()))

    status = res.json()

    # Cache samples for 5 minutes
    # TODO: Determine if this cache call can be converted to the new HTTP cache.
    cache.set(SAMPLES_CACHE_KEY, res.body(), 60 * 5)

    return status

def client_credentials_grant_flow(config, access_token_cache_key):
    clientSecret = config.str("clientSecret")
    clientId = config.str("clientId")

    form_body = dict(
        client_id = clientId,
        client_secret = clientSecret,
        grant_type = "client_credentials",
        scope = "read:device:current_values",
    )

    res = http.post(
        url = "https://accounts-api.airthings.com/v1/token",
        headers = {
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept": "*/*",
        },
        form_body = form_body,
    )

    if res.status_code == 200:
        print("Success")
    else:
        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(access_token_cache_key, "")
        print("Error Fetching access_token: %s" % (res.body()))
        fail("token request failed with status code: %d - %s" % (res.status_code, res.body()))

    token_params = res.json()
    access_token = token_params["access_token"]
    expires_in = token_params["expires_in"]

    # TODO: Determine if this cache call can be converted to the new HTTP cache.
    cache.set(access_token_cache_key, access_token, ttl_seconds = int(expires_in) - 30)
    return access_token

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "clientSecret",
                name = "AirThings API Client Secret",
                desc = "REQUIRED: API secret from https://dashboard.airthings.com/integrations/api-integration",
                icon = "gear",
            ),
            schema.Text(
                id = "clientId",
                name = "AirThings API Client Id",
                desc = "REQUIRED: Client Id from https://dashboard.airthings.com/integrations/api-integration",
                icon = "gear",
            ),
            schema.Text(
                id = "serialNumber",
                name = "Serial Number for AirThings Device",
                desc = "REQUIRED: Taken from the target device on https://dashboard.airthings.com/",
                icon = "gear",
            ),
            schema.Toggle(
                id = "skipRenderIfAllGreen",
                name = "Skip Render If All Green",
                desc = "If all readings are normal, skip rendering this applet",
                icon = "arrowLeft",
                default = False,
            ),
            schema.Toggle(
                id = "onlyDisplayNotNormal",
                name = "Only display non-normal readings",
                desc = "Only displays readings that are not normal (green). NOTE: Ignores individual preferences below when enabled.",
                icon = "arrowLeft",
                default = False,
            ),
            schema.Toggle(
                id = "enableScrolling",
                name = "Enable Scrolling",
                desc = "Enable vertical scrolling to show all readings",
                icon = "arrowsUpDown",
                default = True,
            ),
            schema.Dropdown(
                id = "scrollSpeed",
                name = "Scroll Speed",
                desc = "Control the speed of the scrolling display",
                icon = "gauge",
                default = "100",
                options = [
                    schema.Option(
                        display = "Very Slow",
                        value = "100",
                    ),
                    schema.Option(
                        display = "Slow",
                        value = "80",
                    ),
                    schema.Option(
                        display = "Normal",
                        value = "60",
                    ),
                    schema.Option(
                        display = "Fast",
                        value = "40",
                    ),
                    schema.Option(
                        display = "Very Fast",
                        value = "20",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "fontSize",
                name = "Font Size",
                desc = "Control the size of the text",
                icon = "textHeight",
                default = "medium",
                options = [
                    schema.Option(
                        display = "Small",
                        value = "small",
                    ),
                    schema.Option(
                        display = "Medium",
                        value = "medium",
                    ),
                    schema.Option(
                        display = "Large",
                        value = "large",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "tempUnit",
                name = "Temperature Unit",
                desc = "Display temperature in Celsius or Fahrenheit",
                icon = "temperatureHalf",
                default = "celsius",
                options = [
                    schema.Option(
                        display = "Celsius (°C)",
                        value = "celsius",
                    ),
                    schema.Option(
                        display = "Fahrenheit (°F)",
                        value = "fahrenheit",
                    ),
                ],
            ),
            schema.Text(
                id = "co2_yellow",
                name = "CO2 Yellow Threshold",
                desc = "CO2 level (ppm) for yellow warning",
                icon = "triangleExclamation",
                default = "800",
            ),
            schema.Text(
                id = "co2_red",
                name = "CO2 Red Threshold",
                desc = "CO2 level (ppm) for red alert",
                icon = "triangleExclamation",
                default = "1000",
            ),
            schema.Text(
                id = "pm25_yellow",
                name = "PM2.5 Yellow Threshold",
                desc = "PM2.5 level (µg/m³) for yellow warning",
                icon = "triangleExclamation",
                default = "10",
            ),
            schema.Text(
                id = "pm25_red",
                name = "PM2.5 Red Threshold",
                desc = "PM2.5 level (µg/m³) for red alert",
                icon = "triangleExclamation",
                default = "25",
            ),
            schema.Text(
                id = "temp_f_yellow",
                name = "Temperature °F Yellow Threshold",
                desc = "Temperature (°F) for yellow warning",
                icon = "triangleExclamation",
                default = "72",
            ),
            schema.Text(
                id = "temp_f_red",
                name = "Temperature °F Red Threshold",
                desc = "Temperature (°F) for red alert",
                icon = "triangleExclamation",
                default = "77",
            ),
            schema.Text(
                id = "temp_c_yellow",
                name = "Temperature °C Yellow Threshold",
                desc = "Temperature (°C) for yellow warning",
                icon = "triangleExclamation",
                default = "22",
            ),
            schema.Text(
                id = "temp_c_red",
                name = "Temperature °C Red Threshold",
                desc = "Temperature (°C) for red alert",
                icon = "triangleExclamation",
                default = "25",
            ),
            schema.Text(
                id = "voc_yellow",
                name = "VOC Yellow Threshold",
                desc = "VOC level (ppb) for yellow warning",
                icon = "triangleExclamation",
                default = "250",
            ),
            schema.Text(
                id = "voc_red",
                name = "VOC Red Threshold",
                desc = "VOC level (ppb) for red alert",
                icon = "triangleExclamation",
                default = "2000",
            ),
            schema.Text(
                id = "humidity_low",
                name = "Humidity Low Threshold",
                desc = "Humidity (%) below which triggers red alert",
                icon = "triangleExclamation",
                default = "30",
            ),
            schema.Text(
                id = "humidity_yellow",
                name = "Humidity Yellow Threshold",
                desc = "Humidity (%) for yellow warning",
                icon = "triangleExclamation",
                default = "60",
            ),
            schema.Text(
                id = "humidity_red",
                name = "Humidity Red Threshold",
                desc = "Humidity (%) for red alert",
                icon = "triangleExclamation",
                default = "70",
            ),
            schema.Text(
                id = "radon_yellow",
                name = "Radon Yellow Threshold",
                desc = "Radon level (pCi/L) for yellow warning",
                icon = "triangleExclamation",
                default = "2.7",
            ),
            schema.Text(
                id = "radon_red",
                name = "Radon Red Threshold",
                desc = "Radon level (pCi/L) for red alert (EPA recommends 4.0)",
                icon = "triangleExclamation",
                default = "4.0",
            ),
            schema.Toggle(
                id = "hidePm25",
                name = "Hide Pm2.5",
                desc = "Hide Pm2.5 reading",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "hideVoc",
                name = "Hide VOC",
                desc = "Hide VOC reading",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "hideHumidity",
                name = "Hide Humidity",
                desc = "Hide Humidity reading",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "hideTemp",
                name = "Hide Temperature",
                desc = "Hide Temperature reading",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "hideCo2",
                name = "Hide CO2",
                desc = "Hide CO2 reading",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "hideRadon",
                name = "Hide Radon",
                desc = "Hide Radon short-term reading",
                icon = "gear",
                default = False,
            ),
        ],
    )
