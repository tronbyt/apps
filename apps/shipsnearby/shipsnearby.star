"""
Applet: Ships Nearby
Summary: Display ships in a bounding box
Description: Shows vessel names within a geographic bounding box using VesselAPI.com.
Author: tavdog
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# Container ship icon (32x10 pixels)
CONTAINER_ICON = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAKCAYAAADVTVykAAAAWElEQVR4nGNgoAO4c+fOfxCmh104LSfbESdsbP6DsE3KFgheEADGJ7bYQDAO+aHvAJiBMIvgFqNZSEg+ICAKBQ9+B6BroAXG7Wsbt//0wgPqCOLSAJ0sBgABdYfIAQVTYgAAAABJRU5ErkJggg==")

# Cargo/bulk carrier ship icon (32x10 pixels)
CARGO_ICON = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACAAAAAKCAYAAADVTVykAAAAkElEQVR4nGNgoAMwMrL5D8LY5JgYBhgw0tqCO3fuoPhcRUWFcVCFAAsuiby8CqxxRiqYNGkOaVGQB7X4EZcNRRZXHOlA4S8zQpg3aVIHI9YQ0LBJ+b/r3Bsom4GqAGYuzJ4bR+YwYg0BkCQDjQHMcqwOQHaEiAbC1ZSANzdEMCzG6wAYsEkJoDg0jszZgNcOAESuLXbaOFrzAAAAAElFTkSuQmCC")

# Tugboat icon (24x10 pixels)
TUG_ICON = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAKCAYAAACuaZ5oAAAASklEQVR4nGNgoAAYGdn8B2FKzBgYC+7cufMfG6aqBXJyGnCDYWyqWkCxDzQ0jP6Ti3EamhJg8x+EtxgZUYwHxgJkQDODybUIl34AGGjZ9C3FCkUAAAAASUVORK5CYII=")

API_URL = "https://api.vesselapi.com/v1/location/vessels/bounding-box"

DEFAULT_BBOX = "-123.0,45.0,-122.0,46.0"

# Display options for info lines
DISPLAY_OPTIONS = [
    schema.Option(display = "Speed & Course", value = "speed_course"),
    schema.Option(display = "Nav Status", value = "nav_status"),
    schema.Option(display = "Vessel Type", value = "vessel_type"),
    schema.Option(display = "Callsign", value = "call_sign"),
    schema.Option(display = "Country", value = "country"),
    schema.Option(display = "Dimensions", value = "dimensions"),
    schema.Option(display = "Year Built", value = "year_built"),
    schema.Option(display = "Gross Tonnage", value = "gross_tonnage"),
    schema.Option(display = "Deadweight", value = "deadweight_tonnage"),
    schema.Option(display = "Operating Status", value = "operating_status"),
    schema.Option(display = "Owner", value = "owner_name"),
    schema.Option(display = "Manager", value = "manager_name"),
    schema.Option(display = "MMSI", value = "mmsi"),
    schema.Option(display = "IMO", value = "imo"),
    schema.Option(display = "Coordinates", value = "coordinates"),
    schema.Option(display = "Heading", value = "heading"),
    schema.Option(display = "None", value = "none"),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "VesselAPI Key",
                desc = "Your API key from vesselapi.com",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "bbox",
                name = "Bounding Box",
                desc = "Format: minLon,minLat,maxLon,maxLat (e.g., -122.72,45.55,-122.65,45.62)",
                icon = "mapPin",
                default = DEFAULT_BBOX,
            ),
            schema.Dropdown(
                id = "line2",
                name = "Line 2 Info",
                desc = "Information to display on the second line",
                icon = "alignLeft",
                default = "speed_course",
                options = DISPLAY_OPTIONS,
            ),
            schema.Dropdown(
                id = "line3",
                name = "Line 3 Info",
                desc = "Information to display on the third line",
                icon = "alignLeft",
                default = "nav_status",
                options = DISPLAY_OPTIONS,
            ),
        ],
    )

def fetch_vessel_details(vessel, api_key):
    """Fetch detailed vessel information from the API."""
    imo = vessel.get("imo")
    mmsi = vessel.get("mmsi")
    print("imo: " + str(imo) + " mmsi: " + str(mmsi))
    id_type = "imo" if imo else "mmsi"
    id_val = str(imo) if imo else str(mmsi)
    url = "https://api.vesselapi.com/v1/vessel/" + id_val + "?filter.idType=" + id_type
    print("vessel url: " + url)
    response = http.get(
        url,
        headers = {"Authorization": "Bearer " + api_key},
        ttl_seconds = 60,
    )
    print("vessel status: " + str(response.status_code))
    if response.status_code != 200:
        return {}
    data = json.decode(response.body())
    v = data.get("vessel", {})
    print("vessel_type: " + v.get("vessel_type", ""))
    return {
        "vessel_type": v.get("vessel_type", ""),
        "call_sign": v.get("call_sign", ""),
        "country": v.get("country", ""),
        "length": v.get("length", ""),
        "breadth": v.get("breadth", ""),
        "draft": v.get("draft", ""),
        "year_built": v.get("year_built", ""),
        "gross_tonnage": v.get("gross_tonnage", ""),
        "deadweight_tonnage": v.get("deadweight_tonnage", ""),
        "operating_status": v.get("operating_status", ""),
        "owner_name": v.get("owner_name", ""),
        "manager_name": v.get("manager_name", ""),
    }

def fetch_vessels(bbox, api_key):
    print("bbox: " + bbox)
    parts = bbox.strip().split(",")
    print("parts: " + str(parts))
    if len(parts) < 4:
        return None, "Invalid bbox: need 4 values (minLon,minLat,maxLon,maxLat)"
    params = {
        "filter.latBottom": parts[1],
        "filter.latTop": parts[3],
        "filter.lonLeft": parts[0],
        "filter.lonRight": parts[2],
        "pagination.limit": "20",
    }
    print("params: " + str(params))
    response = http.get(
        API_URL,
        params = params,
        headers = {
            "Authorization": "Bearer " + api_key,
        },
        ttl_seconds = 60,
    )
    print("status: " + str(response.status_code))
    body = response.body()
    print("body: " + body)
    if response.status_code != 200:
        return None, "API error " + str(response.status_code) + ": " + body
    data = json.decode(body)
    vessels = data.get("vessels", [])
    print("vessels count: " + str(len(vessels)))
    return vessels, None

NAV_STATUS = {
    0: "Underway",
    1: "Anchor",
    2: "Not cmd",
    3: "Restrict",
    4: "Moored",
    5: "Aground",
    6: "Fishing",
    7: "Sailing",
    8: "Reserved",
    9: "Reserved",
    10: "Reserved",
    11: "AIS-SART",
    12: "Undef",
    13: "Undefined",
    14: "AIS-SART",
    15: "N/A",
}

def get_info_text(option, vessel, details):
    """Return the text for a given display option."""
    if option == "speed_course":
        sog = vessel.get("sog", 0)
        cog = vessel.get("cog", 0)
        return str(sog) + " kn - " + str(cog) + "°"
    elif option == "nav_status":
        nav_stat = vessel.get("nav_status", 15)
        return NAV_STATUS.get(nav_stat, "N/A")
    elif option == "vessel_type":
        vtype = details.get("vessel_type", "")
        return vtype if vtype else "Unknown"
    elif option == "call_sign":
        call_sign = details.get("call_sign", "")
        return call_sign if call_sign else "N/A"
    elif option == "country":
        country = details.get("country", "")
        return country if country else "N/A"
    elif option == "dimensions":
        length = details.get("length", "")
        breadth = details.get("breadth", "")
        if length and breadth:
            return str(length) + "m x " + str(breadth) + "m"
        return "N/A"
    elif option == "year_built":
        year = details.get("year_built", "")
        return "Built: " + str(year) if year else "N/A"
    elif option == "gross_tonnage":
        gt = details.get("gross_tonnage", "")
        return "GT: " + str(gt) if gt else "N/A"
    elif option == "deadweight_tonnage":
        dwt = details.get("deadweight_tonnage", "")
        return "DWT: " + str(dwt) if dwt else "N/A"
    elif option == "operating_status":
        status = details.get("operating_status", "")
        return status if status else "N/A"
    elif option == "owner_name":
        owner = details.get("owner_name", "")
        if owner and len(owner) > 20:
            owner = owner[:17] + "..."
        return owner if owner else "N/A"
    elif option == "manager_name":
        manager = details.get("manager_name", "")
        if manager and len(manager) > 20:
            manager = manager[:17] + "..."
        return manager if manager else "N/A"
    elif option == "mmsi":
        mmsi = vessel.get("mmsi", "")
        return "MMSI: " + str(mmsi) if mmsi else "MMSI: N/A"
    elif option == "imo":
        imo = vessel.get("imo", "")
        return "IMO: " + str(imo) if imo else "IMO: N/A"
    elif option == "coordinates":
        lat = vessel.get("latitude", 0)
        lon = vessel.get("longitude", 0)

        # Format to 3 decimal places
        lat_str = str(int(lat * 1000) / 1000.0)
        lon_str = str(int(lon * 1000) / 1000.0)
        return lat_str + ", " + lon_str
    elif option == "heading":
        hdg = vessel.get("heading", "")
        return "Hdg: " + str(hdg) + "°" if hdg else "Hdg: N/A"
    elif option == "none":
        return ""
    return ""

def render_view(vessels, api_key, line2_opt, line3_opt):
    if len(vessels) == 0:
        return []

    v = vessels[0]
    name = v.get("vessel_name", "Unknown")
    details = fetch_vessel_details(v, api_key)
    vtype = details.get("vessel_type", "")
    if vtype:
        dash_idx = vtype.find(" - ")
        if dash_idx > 0:
            vtype = vtype[:dash_idx]
        vtype = vtype.strip()
        vtype_display = vtype
        if len(vtype_display) > 15:
            vtype_display = vtype_display[:12] + "..."
        name_line = name + " (" + vtype_display + ")"
    else:
        name_line = name

    # Select icon based on vessel type
    vtype_lower = vtype.lower() if vtype else ""
    if vtype_lower == "tug":
        icon = TUG_ICON
    elif vtype_lower == "container ship" or "container" in vtype_lower:
        icon = CONTAINER_ICON
    else:
        icon = CARGO_ICON

    # Build info lines based on user selection
    info_lines = [render.Text(name_line, font = "tom-thumb", color = "#fff")]

    line2_text = get_info_text(line2_opt, v, details)
    if line2_text:
        info_lines.append(render.Text(line2_text, font = "tom-thumb", color = "#aaa"))

    line3_text = get_info_text(line3_opt, v, details)
    if line3_text:
        info_lines.append(render.Text(line3_text, font = "tom-thumb", color = "#aaa"))

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    main_align = "center",
                    expanded = True,
                    children = [
                        render.Padding(
                            pad = (0, 1, 0, 1),
                            child = render.Image(src = icon),
                        ),
                    ],
                ),
                render.Padding(
                    pad = (1, 0, 1, 0),
                    child = render.Column(
                        children = info_lines,
                    ),
                ),
            ],
        ),
    )

def render_error(err):
    return render.Root(
        child = render.Padding(
            child = render.Text(err, font = "tom-thumb", color = "#f00"),
            pad = 1,
        ),
    )

def main(config):
    api_key = config.get("api_key", "")
    if api_key == "":
        return render_error("API key required")
    bbox = config.get("bbox", DEFAULT_BBOX)
    if bbox == "":
        bbox = DEFAULT_BBOX
    line2_opt = config.get("line2", "speed_course")
    line3_opt = config.get("line3", "nav_status")
    vessels, err = fetch_vessels(bbox, api_key)
    if err:
        return render_error(err)
    return render_view(vessels, api_key, line2_opt, line3_opt)
