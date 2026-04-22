"""
Applet: Ships Nearby
Summary: Display ships near Indonesia
Description: Shows vessels near Indonesia using Marinesia API.
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

API_URL = "https://api.marinesia.com/api/v1/vessel/nearby"

DEFAULT_BBOX = "105,-7.5,107,-5"

DISPLAY_OPTIONS = [
    schema.Option(display = "Auto", value = "auto"),
    schema.Option(display = "Speed & Course", value = "speed_course"),
    schema.Option(display = "Nav Status", value = "nav_status"),
    schema.Option(display = "Vessel Type", value = "vessel_type"),
    schema.Option(display = "Flag", value = "flag"),
    schema.Option(display = "IMO", value = "imo"),
    schema.Option(display = "MMSI", value = "mmsi"),
    schema.Option(display = "Dimensions", value = "dimensions"),
    schema.Option(display = "Coordinates", value = "coordinates"),
    schema.Option(display = "Heading", value = "heading"),
    schema.Option(display = "Draft", value = "draught"),
    schema.Option(display = "Destination", value = "destination"),
    schema.Option(display = "ETA", value = "eta"),
    schema.Option(display = "None", value = "none"),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "Your API key from marinesia.com",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "bbox",
                name = "Bounding Box",
                desc = "Format: long_min,lat_min,long_max,lat_max (e.g., 105,-7.5,107,-5)",
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

def fetch_vessels(bbox, api_key):
    parts = bbox.strip().split(",")
    if len(parts) < 4:
        return None, "Invalid bbox: need 4 values (long_min,lat_min,long_max,lat_max)"
    params = {
        "key": api_key,
        "long_min": parts[0],
        "lat_min": parts[1],
        "long_max": parts[2],
        "lat_max": parts[3],
    }
    print("params: " + str(params))
    response = http.get(
        API_URL,
        params = params,
        ttl_seconds = 30,
    )
    print("status: " + str(response.status_code))
    body = response.body()
    print("body: " + body)
    if response.status_code == 404:
        return [], None
    if response.status_code != 200:
        return None, "API error: " + str(response.status_code)
    data = json.decode(response.body())
    if data.get("error", True):
        return None, data.get("message", "API error")
    vessels = data.get("data", [])
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

AUTO_PRIORITY = [
    "dest",
    "type",
    "flag",
    "imo",
    "mmsi",
    "coords",
    "hdt",
    "draft",
    "eta",
]

def get_info_text(option, vessel, skip_field = ""):
    if option == "auto":
        for field in AUTO_PRIORITY:
            if field == skip_field:
                continue
            if field == "dest":
                dest = vessel.get("dest", "")
                if dest:
                    return dest, field
            elif field == "type":
                vtype = vessel.get("type", "")
                if vtype:
                    return vtype, field
            elif field == "flag":
                flag = vessel.get("flag", "")
                if flag:
                    return flag, field
            elif field == "imo":
                imo = vessel.get("imo", 0)
                if imo:
                    return "IMO: " + str(imo), field
            elif field == "mmsi":
                mmsi = vessel.get("mmsi", "")
                if mmsi:
                    return "MMSI: " + str(mmsi), field
            elif field == "coords":
                lat = vessel.get("lat", 0)
                lng = vessel.get("lng", 0)
                if lat and lng:
                    return str(int(lat * 1000) / 1000.0) + ", " + str(int(lng * 1000) / 1000.0), field
            elif field == "hdt":
                hdt = vessel.get("hdt", "")
                if hdt:
                    return "Hdg: " + str(hdt), field
            elif field == "draft":
                draught = vessel.get("draught", 0)
                if draught:
                    return "Draft: " + str(draught) + "m", field
            elif field == "eta":
                eta = vessel.get("eta", "")
                if eta:
                    return "ETA: " + eta, field
        return "", ""
    if option == "speed_course":
        sog = vessel.get("sog", 0)
        cog = vessel.get("cog", 0)
        return str(sog) + " kn - " + str(cog) + "°", ""
    elif option == "nav_status":
        status = vessel.get("status", 15)
        return NAV_STATUS.get(status, "N/A"), ""
    elif option == "vessel_type":
        vtype = vessel.get("type", "")
        return vtype if vtype else "Unknown", "type"
    elif option == "flag":
        flag = vessel.get("flag", "")
        return flag if flag else "N/A", "flag"
    elif option == "imo":
        imo = vessel.get("imo", 0)
        return "IMO: " + str(imo) if imo else "N/A", "imo"
    elif option == "mmsi":
        mmsi = vessel.get("mmsi", "")
        return "MMSI: " + str(mmsi) if mmsi else "N/A", "mmsi"
    elif option == "dimensions":
        a = vessel.get("a", 0)
        b = vessel.get("b", 0)
        c = vessel.get("c", 0)
        d = vessel.get("d", 0)
        if a and b and c and d:
            return str(a) + "x" + str(b) + "x" + str(c) + "m", "dims"
        return "N/A", ""
    elif option == "coordinates":
        lat = vessel.get("lat", 0)
        lng = vessel.get("lng", 0)
        lat_str = str(int(lat * 1000) / 1000.0)
        lng_str = str(int(lng * 1000) / 1000.0)
        return lat_str + ", " + lng_str, "coords"
    elif option == "heading":
        hdt = vessel.get("hdt", "")
        return "Hdg: " + str(hdt) if hdt else "N/A", "hdt"
    elif option == "draught":
        draught = vessel.get("draught", 0)
        return "Draft: " + str(draught) + "m" if draught else "Draft: N/A", "draft"
    elif option == "destination":
        dest = vessel.get("dest", "")
        return dest if dest else "N/A", "dest"
    elif option == "eta":
        eta = vessel.get("eta", "")
        return "ETA: " + eta if eta else "N/A", "eta"
    elif option == "none":
        return "", ""
    return "", ""

def render_view(vessels, line2_opt, line3_opt):
    if len(vessels) == 0:
        return []

    # Find vessel with a name, pick newest by ts
    v = None
    for vv in vessels:
        name = vv.get("name")
        if name:
            if v == None or vv.get("ts", "") > v.get("ts", ""):
                v = vv

    if not v:
        # Use newest by mmsi
        for vv in vessels:
            mmsi = vv.get("mmsi")
            if mmsi:
                if v == None or vv.get("ts", "") > v.get("ts", ""):
                    v = vv
        if not v:
            return []

    name = v.get("name") or ""
    vtype = v.get("type") or ""

    name_line = name + (" (" + vtype + ")" if vtype else "")

    vtype_lower = vtype.lower() if vtype else ""
    if vtype_lower == "tug":
        icon = TUG_ICON
    elif vtype_lower == "container ship" or "container" in vtype_lower:
        icon = CONTAINER_ICON
    else:
        icon = CARGO_ICON

    info_lines = [render.Text(name_line, font = "tom-thumb", color = "#fff")]

    line2_result = get_info_text(line2_opt, v, "")
    if line2_result:
        info_lines.append(render.Text(line2_result[0], font = "tom-thumb", color = "#aaa"))

    line3_skip = line2_result[1] if (line2_opt == "auto" and line3_opt == "auto") else ""
    line3_result = get_info_text(line3_opt, v, line3_skip)
    if line3_result:
        info_lines.append(render.Text(line3_result[0], font = "tom-thumb", color = "#aaa"))

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
    return render_view(vessels, line2_opt, line3_opt)
