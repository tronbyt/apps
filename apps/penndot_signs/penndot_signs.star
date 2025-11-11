"""
Applet: PennDOT Signs
Summary: Display PennDOT DMS signs
Description: Display messages from PennDOT DMS signage on PA highways.
Author: radiocolin
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

API_URL = "https://www.511pa.com/List/GetData/MessageSigns?query=%7B%22columns%22%3A%5B%7B%22data%22%3Anull%2C%22name%22%3A%22%22%7D%2C%7B%22name%22%3A%22area%22%2C%22s%22%3Atrue%7D%2C%7B%22name%22%3A%22name%22%7D%2C%7B%22name%22%3A%22roadwayName%22%7D%2C%7B%22name%22%3A%22direction%22%7D%2C%7B%22data%22%3A%22phase1Image%22%2C%22name%22%3A%22message%22%7D%2C%7B%22data%22%3A%22phase2Image%22%2C%22name%22%3A%22message2%22%7D%2C%7B%22name%22%3A%22lastUpdated%22%7D%2C%7B%22data%22%3A8%2C%22name%22%3A%22%22%7D%5D%2C%22order%22%3A%5B%7B%22column%22%3A1%2C%22dir%22%3A%22asc%22%7D%5D%2C%22start%22%3A0%2C%22length%22%3A500%2C%22search%22%3A%7B%22value%22%3A%22%22%7D%7D&lang=en-US"
CACHE_TTL = 60

def main(config):
    """Display the selected PennDOT sign message.

    Args:
        config: App configuration containing sign_id.

    Returns:
        Render tree displaying sign message and name.
    """
    sign_id = config.str("sign_id")
    show_info_bar = config.bool("show_info_bar", True)

    if not sign_id:
        return render.Root(
            child = render.Text("Select a sign", color = "#F09F00"),
        )

    # Fetch sign data
    cached = cache.get("penndot_signs_data")
    if cached:
        sign_data = json.decode(cached)
    else:
        rep = http.get(API_URL)
        if rep.status_code != 200:
            return render.Root(
                child = render.Text("Error fetching data"),
            )
        sign_data = rep.json()
        cache.set("penndot_signs_data", json.encode(sign_data), ttl_seconds = CACHE_TTL)

    # Find the selected sign
    selected_sign = None
    for sign in sign_data.get("data", []):
        if sign.get("DT_RowId") == sign_id:
            selected_sign = sign
            break

    if not selected_sign:
        return render.Root(
            child = render.Text("Sign not found", color = "#F09F00"),
        )

    # Get message, images, and roadway name
    message = selected_sign.get("message", "")
    phase1_image = selected_sign.get("phase1Image")
    phase2_image = selected_sign.get("phase2Image")
    roadway_name = selected_sign.get("roadwayName", "Unknown")
    sign_name = selected_sign.get("name", "")

    # Parse milepost from sign name (e.g., "MP 4.35" or "MP 045.8")
    milepost = ""
    if sign_name and "MP" in sign_name.upper():
        # Find MP followed by a number
        parts = sign_name.upper().split("MP")
        if len(parts) > 1:
            # Get the part after "MP" and extract the number
            after_mp = parts[1].strip()

            # Extract digits and decimal point
            mp_value = ""
            for i in range(len(after_mp)):
                char = after_mp[i]
                if char.isdigit() or char == ".":
                    mp_value += char
                elif mp_value:
                    # Stop at first non-digit/non-decimal after we've started collecting
                    break
            if mp_value:
                # Remove leading zeros but keep decimal values
                mp_float = float(mp_value)
                milepost = " MP {}".format(mp_float)

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
            width = 64,
            height = 21,
        ) if phase1_image else None

        img2 = render.Image(
            src = base64.decode(phase2_image),
            width = 64,
            height = 21,
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
        for line in message_lines:
            message_widgets.append(
                render.Marquee(
                    width = 64,
                    align = "center",
                    child = render.Text(
                        content = line,
                        font = "tb-8",
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

    if show_info_bar:
        # With info bar: 26px content + 6px bar = 32px
        display_children.append(
            render.Box(
                width = 64,
                height = 26,
                child = content_widget,
            ),
        )

        # Build info bar content - create frames that pause on each line
        info_frames = []

        # Create frames for roadway name (hold for 90 frames = 3 seconds)
        roadway_widget = render.Box(
            width = 64,
            height = 6,
            color = "#F09F00",
            child = render.Row(
                expanded = True,
                main_align = "end",
                children = [
                    render.Text(
                        content = roadway_name,
                        font = "tom-thumb",
                        color = "#000",
                    ),
                ],
            ),
        )

        # If we have a milepost, alternate between roadway and milepost
        if milepost:
            milepost_widget = render.Box(
                width = 64,
                height = 6,
                color = "#F09F00",
                child = render.Row(
                    expanded = True,
                    main_align = "end",
                    children = [
                        render.Text(
                            content = milepost.strip(),
                            font = "tom-thumb",
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
                width = 64,
                height = 32,
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
    sign_options = []

    cached = cache.get("penndot_signs_data")
    if cached:
        sign_data = json.decode(cached)
    else:
        rep = http.get(API_URL)
        if rep.status_code != 200:
            # Return empty schema if API fails
            return schema.Schema(
                version = "1",
                fields = [
                    schema.Text(
                        id = "error",
                        name = "Error",
                        desc = "Unable to fetch sign data",
                        icon = "exclamationTriangle",
                    ),
                ],
            )

        sign_data = rep.json()
        cache.set("penndot_signs_data", json.encode(sign_data), ttl_seconds = CACHE_TTL)

    # Build dropdown options from sign data
    signs_list = []
    for sign in sign_data.get("data", []):
        roadway = sign.get("roadwayName", "Unknown")
        name = sign.get("name", "Unknown")
        sign_id = sign.get("DT_RowId", "")

        if sign_id:
            signs_list.append({
                "display": "{}: {}".format(roadway, name),
                "value": sign_id,
            })

    # Sort signs by display name (roadway + name)
    signs_list = sorted(signs_list, key = lambda s: s["display"])

    # Convert to schema options
    for sign in signs_list:
        sign_options.append(
            schema.Option(
                display = sign["display"],
                value = sign["value"],
            ),
        )

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "sign_id",
                name = "Select Sign",
                desc = "Choose a PennDOT sign to display",
                icon = "road",
                default = sign_options[0].value if sign_options else "",
                options = sign_options,
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
