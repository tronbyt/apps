"""
Applet: PennDOT Signs
Summary: Display PennDOT DMS signs
Description: Display messages from PennDOT DMS signage on PA highways.
Author: radiocolin
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")

API_URL = "https://www.511pa.com/List/GetData/MessageSigns"
FILTERS_URL = "https://www.511pa.com/List/UniqueColumnValuesForMessageSigns/MessageSigns"
CACHE_TTL = 60

def get_query(start = 0, length = 100, roadway = None, search = ""):
    columns = [
        {"data": None, "name": ""},
        {"name": "area", "s": True},
        {"name": "name"},
        {"name": "roadwayName"},
        {"name": "direction"},
        {"data": "phase1Image", "name": "message"},
        {"data": "phase2Image", "name": "message2"},
        {"name": "lastUpdated"},
        {"data": 8, "name": ""},
    ]
    if roadway:
        columns[3]["search"] = {"value": roadway}

    query = {
        "columns": columns,
        "order": [{"column": 1, "dir": "asc"}],
        "start": start,
        "length": length,
        "search": {"value": search},
    }
    return json.encode(query)

def fetch_signs(roadway = None, search = "", limit = 0):
    signs = []
    start = 0

    # If limit is 0, we fetch all (with safety limit).
    # If limit is > 0, we fetch up to that amount.
    max_pages = 20 if limit == 0 else (limit + 99) // 100
    for _ in range(max_pages):
        query = get_query(start = start, length = 100, roadway = roadway, search = search)
        params = {"query": query, "lang": "en-US"}
        rep = http.get(API_URL, params = params, headers = {"X-Requested-With": "XMLHttpRequest"})
        if rep.status_code != 200:
            break
        data = rep.json()
        signs.extend(data.get("data", []))
        if limit > 0 and len(signs) >= limit:
            signs = signs[:limit]
            break
        if len(signs) >= data.get("recordsFiltered", 0) or len(data.get("data", [])) < 100:
            break
        start += 100
    return signs

def parse_milepost(sign):
    # Check name and message fields for MP or MM
    fields_to_check = [sign.get("name", ""), sign.get("message", "")]
    for text in fields_to_check:
        if not text:
            continue
        text_upper = text.upper().replace("<BR/>", " ")
        for marker in ["MP", "MM"]:
            if marker in text_upper:
                parts = text_upper.split(marker)
                if len(parts) > 1:
                    after_marker = parts[1].strip()
                    mp_value = ""
                    for i in range(len(after_marker)):
                        char = after_marker[i]
                        if char.isdigit() or char == ".":
                            mp_value += char
                        elif mp_value:
                            break
                    if mp_value:
                        # Normalize formatting
                        return "MP {}".format(float(mp_value))
    return ""

def main(config):
    """Display the selected PennDOT sign message.

    Args:
        config: App configuration containing sign_id.

    Returns:
        Render tree displaying sign message and name.
    """
    scale = 2 if canvas.is2x() else 1
    full_id = config.str("sign_id")
    show_info_bar = config.bool("show_info_bar", True)

    if not full_id:
        # Sensible default: fetch the first available sign
        signs = fetch_signs(limit = 1)
        if signs:
            full_id = "{}|{}".format(signs[0].get("roadwayName", "ALL"), signs[0].get("DT_RowId"))
        else:
            return render.Root(
                child = render.Text("No signs available", color = "#F09F00", font = "tb-8" if scale == 1 else "terminus-14"),
            )

    # Parse roadway and ID
    parts = full_id.split("|")
    if len(parts) == 2:
        roadway = parts[0]
        sign_id = parts[1]
    else:
        # Fallback for old configs
        roadway = "ALL"
        sign_id = full_id

    # Fetch sign data
    # We fetch only the relevant roadway to be efficient
    fetch_roadway = roadway if roadway != "ALL" else None
    signs = fetch_signs(roadway = fetch_roadway)

    selected_sign = None
    for sign in signs:
        if sign.get("DT_RowId") == sign_id:
            selected_sign = sign
            break

    if not selected_sign:
        return render.Root(
            child = render.Text("Sign not found", color = "#F09F00", font = "tb-8" if scale == 1 else "terminus-14"),
        )

    # Get message, images, and roadway name
    message = selected_sign.get("message", "")
    phase1_image = selected_sign.get("phase1Image")
    phase2_image = selected_sign.get("phase2Image")
    roadway_name = selected_sign.get("roadwayName", "Unknown")

    # Parse milepost
    milepost = parse_milepost(selected_sign)

    # If no message and no image, return empty
    if (not message or message == "NO_MESSAGE") and not phase1_image and not phase2_image:
        return []

    # Check if we have images instead of text
    content_widget = None

    if phase1_image or phase2_image:
        # Display image(s)
        frames = []

        # Decode and create images
        img1 = render.Image(
            src = base64.decode(phase1_image),
            width = 64 * scale,
            height = 21 * scale,
        ) if phase1_image else None

        img2 = render.Image(
            src = base64.decode(phase2_image),
            width = 64 * scale,
            height = 21 * scale,
        ) if phase2_image else None

        # Create animation frames - hold each image for 3 seconds (90 frames at 30fps)
        if img1 and img2:
            # Add 90 frames of first image
            frames.extend([img1] * 90)

            # Add 90 frames of second image
            frames.extend([img2] * 90)
            img_content = render.Animation(children = frames)
        elif img1:
            img_content = img1
        else:
            img_content = img2

        # Wrap image in Column with top alignment
        content_widget = render.Column(
            main_align = "start",
            children = [img_content],
        )
    else:
        # Display text message
        # Parse message - remove <br/> tags and split into lines
        message_lines = []
        if message:
            # Replace <br/> with newline and split
            message = message.replace("<br/>", "\n")
            message_lines = [line.strip() for line in message.split("\n") if line.strip()]

        # Build message display
        message_widgets = []
        message_font = "tb-8" if scale == 1 else "terminus-14"
        for line in message_lines:
            message_widgets.append(
                render.Marquee(
                    width = 64 * scale,
                    align = "center",
                    child = render.Text(
                        content = line,
                        font = message_font,
                        color = "#F09F00",
                    ),
                ),
            )

        content_widget = render.Column(
            main_align = "center",
            children = message_widgets,
        )

    # Build display with or without info bar
    display_children = []
    info_font = "tom-thumb" if scale == 1 else "terminus-12"

    if show_info_bar:
        # With info bar: 26px content + 6px bar = 32px
        display_children.append(
            render.Box(
                width = 64 * scale,
                height = 26 * scale,
                child = content_widget,
            ),
        )

        # Build info bar content - create frames that pause on each line
        info_frames = []

        # Create frames for roadway name (hold for 90 frames = 3 seconds)
        roadway_widget = render.Box(
            width = 64 * scale,
            height = 6 * scale,
            color = "#F09F00",
            child = render.Row(
                expanded = True,
                main_align = "end",
                children = [
                    render.Text(
                        content = roadway_name,
                        font = info_font,
                        color = "#000",
                    ),
                ],
            ),
        )

        # If we have a milepost, alternate between roadway and milepost
        if milepost:
            milepost_widget = render.Box(
                width = 64 * scale,
                height = 6 * scale,
                color = "#F09F00",
                child = render.Row(
                    expanded = True,
                    main_align = "end",
                    children = [
                        render.Text(
                            content = milepost.strip(),
                            font = info_font,
                            color = "#000",
                        ),
                    ],
                ),
            )

            # 90 frames of roadway, 90 frames of milepost
            info_frames.extend([roadway_widget] * 90)
            info_frames.extend([milepost_widget] * 90)

            display_children.append(render.Animation(children = info_frames))
        else:
            # Just show roadway name
            display_children.append(roadway_widget)
    else:
        # Without info bar: full 32px for content, centered
        display_children.append(
            render.Box(
                width = 64 * scale,
                height = 32 * scale,
                child = render.Column(
                    main_align = "center",
                    cross_align = "center",
                    children = [content_widget],
                ),
            ),
        )

    return render.Root(
        child = render.Column(
            children = display_children,
        ),
    )

def get_schema():
    """Build schema with dropdown of all available PennDOT signs.

    Returns:
        Schema with sign selection dropdown.
    """
    roadway_options = [schema.Option(display = "All Roads", value = "ALL")]

    # Fetch unique roadways
    query = get_query(length = 100)
    params = {"query": query, "lang": "en-US"}
    rep = http.get(FILTERS_URL, params = params, headers = {"X-Requested-With": "XMLHttpRequest"})
    if rep.status_code == 200:
        filter_data = rep.json()
        roadways = filter_data.get("roadwayName", [])
        for road in sorted(roadways):
            if road:
                roadway_options.append(schema.Option(display = road, value = road))

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "roadway",
                name = "Roadway",
                desc = "Filter signs by roadway",
                icon = "road",
                default = roadway_options[0].value,
                options = roadway_options,
            ),
            schema.Generated(
                id = "sign_id",
                source = "roadway",
                handler = get_signs,
            ),
            schema.Toggle(
                id = "show_info_bar",
                name = "Show Info Bar",
                desc = "Display roadway name at bottom",
                icon = "info",
                default = True,
            ),
        ],
    )

def get_signs(roadway):
    sign_options = []

    # If roadway is 'ALL', we only fetch the first 100 to avoid schema handler timeout.
    # Users can filter by roadway to see every sign on that road.
    fetch_roadway = roadway if roadway and roadway != "ALL" else None
    limit = 100 if roadway == "ALL" else 0
    signs = fetch_signs(roadway = fetch_roadway, limit = limit)

    signs_list = []
    for sign in signs:
        roadway_name = sign.get("roadwayName", "ALL")
        name = sign.get("name", "Unknown")
        sign_id = sign.get("DT_RowId", "")

        if sign_id:
            mp = parse_milepost(sign)
            display_name = name
            if mp:
                display_name = "{} ({})".format(name, mp)

            signs_list.append({
                "display": "{}: {}".format(roadway_name, display_name),
                "value": "{}|{}".format(roadway_name, sign_id),
            })

    # Sort signs by display name
    signs_list = sorted(signs_list, key = lambda s: s["display"])

    for sign in signs_list:
        sign_options.append(
            schema.Option(
                display = sign["display"],
                value = sign["value"],
            ),
        )

    return [
        schema.Dropdown(
            id = "sign_id",
            name = "Select Sign",
            desc = "Choose a PennDOT sign to display",
            icon = "road",
            default = sign_options[0].value if sign_options else "",
            options = sign_options,
        ),
    ]
