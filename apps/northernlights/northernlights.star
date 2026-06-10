"""
Applet: Northern Lights
Summary: Northern Lights Data
Description: Displays the current Northern Lights data from the NOAA including the KP index, wind speed, Bz, and a brief summary of the most recent NOAA notifications. This data will show you the current space weather conditions for aurora level estimates.
Author: @objectivelabs
"""

load("http.star", "http")
load("images/northern_lights_icon_20px.png", NORTHERN_LIGHTS_ICON_20PX_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

# NOAA may reject anonymous clients; identify this community applet.
NOAA_HEADERS = {
    "User-Agent": "TidbytCommunity-NorthernLights/2 (+https://github.com/tidbyt/community)",
    "Accept": "application/json",
}

NORTHERN_LIGHTS_ICON_20PX = NORTHERN_LIGHTS_ICON_20PX_ASSET.readall()

#Noaa data APi urls
kp_url = "https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json"
windspeed_url = "https://services.swpc.noaa.gov/products/summary/solar-wind-speed.json"
bz_url = "https://services.swpc.noaa.gov/products/summary/solar-wind-mag-field.json"
alerts_url = "https://services.swpc.noaa.gov/products/alerts.json"

def fetch_json(url):
    """GET JSON from NOAA; returns None on failure (no fail() so the app still renders)."""
    resp = http.get(url, headers = NOAA_HEADERS, ttl_seconds = 300)
    if resp.status_code != 200:
        print("Request failed ", resp.status_code, " for ", url)
        return None
    return resp.json()

def latest_kp(data):
    """NOAA switched from table rows [[time, kp, ...], ...] to list of objects with Kp key."""
    if data == None or type(data) != "list" or len(data) < 1:
        return None
    row = data[len(data) - 1]
    if type(row) == "dict":
        v = row.get("Kp")
        if v != None:
            return v
    if type(row) == "list" and len(row) > 1:
        return row[1]
    return None

def latest_wind(data):
    """Wind product is now a list of objects with proton_speed; legacy was {WindSpeed: ...}."""
    if data == None:
        return None
    if type(data) == "dict":
        v = data.get("WindSpeed")
        if v != None:
            return v
    if type(data) == "list" and len(data) > 0:
        row = data[len(data) - 1]
        if type(row) == "dict":
            for key in ["proton_speed", "WindSpeed", "speed"]:
                v = row.get(key)
                if v != None:
                    return v
    return None

def latest_bz_nt(data):
    """Bz is now bz_gsm on the latest list row; legacy was top-level Bz."""
    if data == None:
        return None
    if type(data) == "dict":
        v = data.get("Bz")
        if v == None:
            v = data.get("bz_gsm")
        if v != None:
            return v
    if type(data) == "list" and len(data) > 0:
        row = data[len(data) - 1]
        if type(row) == "dict":
            for key in ["bz_gsm", "Bz"]:
                v = row.get(key)
                if v != None:
                    return v
    return None

def fmt_val(v):
    if v == None:
        return "--"
    return str(v)

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
    kp_data = fetch_json(kp_url)
    kp = latest_kp(kp_data)
    if kp != None:
        print("Kp: ", kp)

    windspeed_data = fetch_json(windspeed_url)
    windspeed = latest_wind(windspeed_data)
    if windspeed != None:
        print("WindSpeed: ", windspeed)

    bz_data = fetch_json(bz_url)
    bz = latest_bz_nt(bz_data)
    if bz != None:
        print("Bz: ", bz)

    alert_text = ""
    alert_data = fetch_json(alerts_url)
    if alert_data and type(alert_data) == "list" and len(alert_data) > 0:
        latest_alert_entry = alert_data[0]
        if type(latest_alert_entry) == "dict":
            msg = latest_alert_entry.get("message", "")
            if msg and type(msg) == "string":
                alert_text = parse_alert_message(msg)
                print("Alert value: ", alert_text)

    # Marquee only when NOAA reports an in-progress ALERT / WARNING / WATCH (see parse_alert_message).
    column_children = [
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
                        render.Text(content = fmt_val(kp), color = "#3abe3e"),
                    ],
                ),
                render.Column(
                    cross_align = "center",
                    children = [
                        render.Text(content = " Wind ", color = "#ffffff"),
                        render.Text(content = fmt_val(windspeed), color = "#3abe3e"),
                    ],
                ),
                render.Column(
                    cross_align = "center",
                    children = [
                        render.Text(content = "  Bz  ", color = "#ffffff"),
                        render.Text(content = fmt_val(bz), color = "#3abe3e"),
                    ],
                ),
            ],
        ),
    ]
    if alert_text:
        column_children.append(
            render.Marquee(
                width = 64,
                child = render.Text(alert_text, color = "#fff"),
            ),
        )

    return render.Root(
        child = render.Column(children = column_children),
    )

# Define the schema for the applet
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )
