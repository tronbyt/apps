"""
Applet: Northern Lights
Summary: Northern Lights Data
Description: Displays the current Northern Lights data from the NOAA including the KP index, wind speed, Bz, and a brieft summary of the most resent NOAA notifications. This data will show you the current space weather conditions for aurura level estimates.
Author: @objectivelabs
"""

load("cache.star", "cache")
load("http.star", "http")
load("images/northern_lights_icon_20px.png", NORTHERN_LIGHTS_ICON_20PX_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

NORTHERN_LIGHTS_ICON_20PX = NORTHERN_LIGHTS_ICON_20PX_ASSET.readall()

#base 64 encoded northern lights image logo

#Noaa data APi urls
kp_url = "https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json"
windspeed_url = "https://services.swpc.noaa.gov/products/summary/solar-wind-speed.json"
bz_url = "https://services.swpc.noaa.gov/products/summary/solar-wind-mag-field.json"
alerts_url = "https://services.swpc.noaa.gov/products/alerts.json"

# Fetch data from the given URL
def fetch_data(url):
    resp = http.get(url)
    if resp.status_code != 200:
        fail("Request failed with status " + str(resp.status_code))
    return resp.json()

# Parse the alert message to extract the event type and predicted storm level
def parse_alert_message(alert):
    # Split the alert message into lines for easier parsing
    lines = alert.split("\r\n")
    event_type = None
    predicted_level = None
    active_warning = False

    for line in lines:
        line = line.strip()

        # Determine the event type and set active_warning accordingly
        if "ALERT" in line:
            event_type = "ALERT"
            active_warning = True  # Set active_warning to True for ALERT
        elif "WARNING" in line:
            event_type = "WARNING"
            active_warning = True  # Set active_warning to True for WARNING
        elif "WATCH" in line:
            event_type = "WATCH"
            active_warning = True  # Set active_warning to True for WATCH
        elif "SUMMARY" in line:
            event_type = "SUMMARY"
            # Decide if SUMMARY should set active_warning (currently left as False)

        # Extract predicted storm level from 'NOAA Scale: ' line
        if line.startswith("NOAA Scale: "):
            predicted_level = line[len("NOAA Scale: "):].strip()

        # For WATCH messages, extract predicted level differently
        if event_type == "WATCH" and "WATCH:" in line:
            idx = line.find("Geomagnetic Storm Category ")
            if idx != -1:
                start = idx + len("Geomagnetic Storm Category ")
                end = line.find(" Predicted", start)
                if end != -1:
                    predicted_level = line[start:end].strip()
                else:
                    predicted_level = line[start:].strip()
            else:
                # In case 'Geomagnetic Storm Category' is not found
                predicted_level = line.replace("WATCH:", "").strip()

    # Format the output based on whether there's an active warning
    if active_warning:
        event = event_type if event_type else "N/A"
        level = predicted_level if predicted_level else "None"
        summary = event + ": " + level + " active"
    else:
        summary = ""  # Return empty string if no active warning

    return summary

# Main function to fetch data and render the UI
def main():
    # Check if the data is already cached
    kp = cache.get("kp") or False
    windspeed = cache.get("windspeed") or False
    bz = cache.get("bz") or False
    alert = cache.get("alert") or False

    # If KP is not cached, fetch new data and cache for 5 minutes (300 seconds)
    if not kp:
        kp_data = fetch_data(kp_url)
        if kp_data and len(kp_data) > 1:
            # KP index is the second item in this list (index 1)
            latest_entry = kp_data[-1]
            kp = latest_entry[1]  # Extract KP value
            print("Kp: ", kp)
            cache.set("kp", kp, ttl_seconds = 300)  # Cache the latest KP value

    # If WindSpeed is not cached, fetch new data and cache for 5 minutes (300 seconds)
    if not windspeed:
        windspeed_data = fetch_data(windspeed_url)

        # Directly access the 'WindSpeed' key from the JSON object
        if "WindSpeed" in windspeed_data:
            windspeed = windspeed_data["WindSpeed"]
            print("WindSpeed: ", windspeed)
            cache.set("windspeed", windspeed, ttl_seconds = 300)
        else:
            print("WindSpeed data not available in the response")

    # If Bz is not cached, fetch new data and cache for 5 minutes (300 seconds)
    if not bz:
        bz_data = fetch_data(bz_url)

        # Directly access the 'Bz' key from the JSON object
        if "Bz" in bz_data:
            bz = bz_data["Bz"]
            print("Bz: ", bz)
            cache.set("bz", bz, ttl_seconds = 300)
        else:
            print("Bz data not available in the response")

    # If Alert is not cached, fetch new data and cache for 5 minutes (300 seconds)
    if not alert:
        alert_data = fetch_data(alerts_url)
        if alert_data and len(alert_data) > 0:
            # The latest data entry is the last item in the list (-1 index)
            # Alert index is the second item in this list (index 1)
            latest_alert_entry = alert_data[0]
            alert = latest_alert_entry["message"]  # Extract KP value
            alert = parse_alert_message(alert)
            print("Alert value: ", alert)
            cache.set("alert", alert, ttl_seconds = 300)  # Cache the latest KP value

    # Render the UI
    return render.Root(
        child = render.Column(
            children = [
                # First Row with just the logo
                render.Row(
                    main_align = "center",
                    children = [
                        render.Image(src = NORTHERN_LIGHTS_ICON_20PX, width = 64, height = 8),
                    ],
                ),
                # Second Row with three columns for KP, Wind, Bz
                render.Row(
                    main_align = "space_between",
                    children = [
                        render.Column(
                            cross_align = "center",
                            children = [
                                render.Text(content = "  Kp  ", color = "#ffffff"),
                                render.Text(content = str(kp), color = "#3abe3e"),
                            ],
                        ),
                        render.Column(
                            cross_align = "center",
                            children = [
                                render.Text(content = " Wind ", color = "#ffffff"),
                                render.Text(content = str(windspeed), color = "#3abe3e"),
                            ],
                        ),
                        render.Column(
                            cross_align = "center",
                            children = [
                                render.Text(content = "  Bz  ", color = "#ffffff"),
                                render.Text(content = str(bz), color = "#3abe3e"),
                            ],
                        ),
                    ],
                ),
                # Third Row for Marquee of NOAA alerts
                render.Marquee(
                    width = 64,
                    child = render.Text(alert, color = "#fff"),
                ),
            ],
        ),
    )

# Define the schema for the applet
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
