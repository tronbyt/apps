"""
Applet: HurricaneTracker
Summary: Hurricane Tracking Info
Description: Displays NHC information on the nearest tracked tropical system.
Author: Robert Ison
"""

load("animation.star", "animation")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/hurricane_animation.png", HURRICANE_ANIMATION_ASSET = "file")
load("images/nhc_icon.png", NHC_ICON_ASSET = "file")
load(
    "images/tropical_storm_animation.png",
    TROPICAL_STORM_ANIMATION_ASSET = "file",
)
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")
load("xpath.star", "xpath")

HURRICANE_ANIMATION = HURRICANE_ANIMATION_ASSET.readall()
NHC_ICON = NHC_ICON_ASSET.readall()
TROPICAL_STORM_ANIMATION = TROPICAL_STORM_ANIMATION_ASSET.readall()

BASIN_URLS = {
    "atlantic": "https://www.nhc.noaa.gov/index-at.xml",
    "eastern_pacific": "https://www.nhc.noaa.gov/index-ep.xml",
    "central_pacific": "https://www.nhc.noaa.gov/index-cp.xml",
}

BASIN_TITLES = {
    "atlantic": "Atlantic",
    "eastern_pacific": "Eastern North Pacific",
    "central_pacific": "Central North Pacific",
}

DEFAULT_LOCATION = """
{
    "lat": "28.53985",
    "lng": "-81.38380",
    "description": "Orlando, FL, USA",
    "locality": "Orlando",
    "timezone": "America/New_York"
}
"""

NHC_COLOR_ALT = "#0085ca"
OLD_UPDATE_COLOR = "#ffaa00"

CACHE_TTL = 10 * 60

# Optional developer override. Normally leave False and use
# the Show Sample Data setting instead.
DEBUG_MODE = False

# Match this to the actual width of the image assets.
ICON_WIDTH = 16

BASIN_OPTIONS = [
    schema.Option(value = "atlantic", display = "Atlantic Basin"),
    schema.Option(
        value = "eastern_pacific",
        display = "Eastern Pacific Basin",
    ),
    schema.Option(
        value = "central_pacific",
        display = "Central Pacific Basin",
    ),
]

SCROLL_SPEED_OPTIONS = [
    schema.Option(value = "60", display = "Slow"),
    schema.Option(value = "45", display = "Medium"),
    schema.Option(value = "30", display = "Fast"),
]

ROTATION_SPEED_OPTIONS = [
    schema.Option(
        value = "10000",
        display = "Slow — 10 seconds per revolution",
    ),
    schema.Option(
        value = "6000",
        display = "Medium — 6 seconds per revolution",
    ),
    schema.Option(
        value = "4000",
        display = "Fast — 4 seconds per revolution",
    ),
]

OLD_UPDATE_OPTIONS = [
    schema.Option(value = "6", display = "6 hours"),
    schema.Option(value = "12", display = "12 hours"),
    schema.Option(value = "24", display = "24 hours"),
    schema.Option(value = "0", display = "Disable old-update label"),
]

def display_instructions(scroll_speed):
    texts = [
        (
            "Tracks the nearest system in your selected basin. " +
            "Developing outlook disturbances aren't shown."
        ),
        (
            "Shows distance & direction to the storm center, " +
            "winds, pressure & movement."
        ),
        "Orange header means an old update, not increased danger.",
        (
            "Other tracked systems follow when enabled. " +
            "Follow official guidance for local threats."
        ),
    ]

    rows = staggered_text_rows(
        texts,
        [
            canvas.width(),
            canvas.width(),
            canvas.width(),
            canvas.width(),
        ],
        [
            NHC_COLOR_ALT,
            "#fff",
            OLD_UPDATE_COLOR,
            "#ff0",
        ],
        display_font(),
    )

    return render.Root(
        delay = scroll_speed,
        show_full_animation = True,
        child = render.Column(
            children = rows,
        ),
    )

def format_distance(miles):
    text = str(int(math.round(miles)))
    formatted = ""

    for index in range(len(text)):
        if index > 0 and (len(text) - index) % 3 == 0:
            formatted += ","

        formatted += text[index]

    return formatted

def display_font():
    return "terminus-16" if canvas.is2x() else "5x8"

def character_width():
    return 8 if canvas.is2x() else 5

def clean_text(value):
    if value == None:
        return ""

    return " ".join(str(value).split())

def log_error(message):
    print("[HurricaneTracker ERROR] " + message)

def display_status(title, message, scroll_speed):
    font = display_font()

    return render.Root(
        delay = scroll_speed,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Marquee(
                    width = canvas.width(),
                    child = render.Text(
                        title,
                        color = NHC_COLOR_ALT,
                        font = font,
                    ),
                ),
                render.Marquee(
                    width = canvas.width(),
                    offset_start = max(
                        character_width() * 4,
                        len(title) * character_width(),
                    ),
                    child = render.Text(
                        message,
                        color = "#ff0",
                        font = font,
                    ),
                ),
            ],
        ),
    )

def display_error(message, show_errors, scroll_speed):
    # Always record detected errors in Show Render Debug.
    log_error(message)

    # This option controls only the physical display.
    if not show_errors:
        return []

    return display_status(
        "Hurricane Feed Error",
        message,
        scroll_speed,
    )

def animated_storm_icon(storm_type, scroll_speed, rotation_ms):
    normalized_type = clean_text(storm_type).lower()

    if normalized_type not in ["hurricane", "tropical storm"]:
        return render.Box(
            width = ICON_WIDTH,
            height = ICON_WIDTH,
            child = render.Image(
                src = NHC_ICON,
                width = ICON_WIDTH,
                height = ICON_WIDTH,
            ),
        )

    # Compensate for the render's frame delay so rotation speed
    # stays approximately constant when scroll speed changes.
    frame_delay = max(1, int(scroll_speed))

    rotation_frames = max(
        2,
        int(math.round(float(rotation_ms) / frame_delay)),
    )

    image = storm_icon(storm_type)
    frames = []

    for index in range(rotation_frames):
        angle = 360.0 * index / rotation_frames

        # Fixed-angle children inside render.Animation allow
        # continuous looping while longer text continues scrolling.
        frames.append(
            animation.Transformation(
                child = render.Image(
                    src = image,
                    width = ICON_WIDTH,
                    height = ICON_WIDTH,
                ),
                width = ICON_WIDTH,
                height = ICON_WIDTH,
                duration = 1,
                origin = animation.Origin(0.5, 0.5),
                wait_for_child = False,
                keyframes = [
                    animation.Keyframe(
                        percentage = 0.0,
                        transforms = [
                            animation.Rotate(angle),
                        ],
                    ),
                    animation.Keyframe(
                        percentage = 1.0,
                        transforms = [
                            animation.Rotate(angle),
                        ],
                    ),
                ],
            ),
        )

    return render.Box(
        width = ICON_WIDTH,
        height = ICON_WIDTH,
        child = render.Animation(
            children = frames,
        ),
    )

def parse_decimal(value):
    if value == None:
        return None

    text = str(value).strip()

    if not text:
        return None

    unsigned = text

    if unsigned[0] == "-" or unsigned[0] == "+":
        unsigned = unsigned[1:]

    if not unsigned:
        return None

    decimal_points = 0
    digits = 0

    for index in range(len(unsigned)):
        character = unsigned[index]

        if character == ".":
            decimal_points += 1

            if decimal_points > 1:
                return None
        elif character in "0123456789":
            digits += 1
        else:
            return None

    if digits == 0:
        return None

    return float(text)

def parse_coordinates(latitude, longitude):
    latitude = parse_decimal(latitude)
    longitude = parse_decimal(longitude)

    if latitude == None or longitude == None:
        return None

    if latitude < -90 or latitude > 90:
        return None

    if longitude < -180 or longitude > 180:
        return None

    return [latitude, longitude]

def parse_storm_center(center):
    text = clean_text(center)

    if not text:
        return None

    parts = text.replace(",", " ").split()

    if len(parts) != 2:
        return None

    return parse_coordinates(parts[0], parts[1])

def distance(lat_1, lng_1, lat_2, lng_2):
    lat_1 = math.radians(float(lat_1))
    lat_2 = math.radians(float(lat_2))
    lng_1 = math.radians(float(lng_1))
    lng_2 = math.radians(float(lng_2))

    d_lat = lat_2 - lat_1
    d_lng = lng_2 - lng_1

    haversine = (
        math.pow(math.sin(d_lat / 2), 2) +
        math.cos(lat_1) *
        math.cos(lat_2) *
        math.pow(math.sin(d_lng / 2), 2)
    )

    haversine = max(0.0, min(1.0, haversine))

    return 3959.9986576 * (
        2 * math.atan2(
            math.sqrt(haversine),
            math.sqrt(1 - haversine),
        )
    )

def get_bearing(lat_1, lng_1, lat_2, lng_2):
    lat_1 = math.radians(float(lat_1))
    lat_2 = math.radians(float(lat_2))
    lng_1 = math.radians(float(lng_1))
    lng_2 = math.radians(float(lng_2))

    longitude_difference = lng_2 - lng_1

    x = math.cos(lat_2) * math.sin(longitude_difference)

    y = (
        math.cos(lat_1) * math.sin(lat_2) -
        math.sin(lat_1) *
        math.cos(lat_2) *
        math.cos(longitude_difference)
    )

    bearing = math.degrees(math.atan2(x, y)) % 360

    compass_points = [
        "North",
        "Northeast",
        "East",
        "Southeast",
        "South",
        "Southwest",
        "West",
        "Northwest",
    ]

    index = int(math.round(bearing / 45)) % 8

    return compass_points[index]

def basin_title(xml, basin):
    title = clean_text(xml.query("/rss/channel/title"))

    if not title:
        return BASIN_TITLES[basin]

    return title.replace(
        "CPHC",
        "",
    ).replace(
        "NHC",
        "",
    ).strip() or BASIN_TITLES[basin]

def parse_publication_time(published_time):
    text = clean_text(published_time)

    if not text:
        return None

    # Remove the weekday prefix to accept one- or two-digit days.
    if "," in text:
        text = text.split(",", 1)[1].strip()

    parts = text.split()

    if len(parts) != 5:
        log_error(
            "Unexpected publication date: {}".format(
                repr(published_time),
            ),
        )
        return None

    if parts[4].upper() in ["GMT", "UTC", "UT", "Z"]:
        parts[4] = "+0000"

    return time.parse_time(
        " ".join(parts),
        format = "2 Jan 2006 15:04:05 -0700",
    )

def format_update_age(seconds):
    seconds = max(0, int(seconds))
    minutes = seconds // 60

    if minutes < 1:
        return "Less than 1m ago"

    if minutes < 60:
        return "{}m ago".format(minutes)

    hours = minutes // 60
    remaining_minutes = minutes % 60

    if hours < 24:
        if remaining_minutes > 0:
            return "{}h {}m ago".format(hours, remaining_minutes)

        return "{}h ago".format(hours)

    days = hours // 24
    remaining_hours = hours % 24

    if remaining_hours > 0:
        return "{}d {}h ago".format(days, remaining_hours)

    return "{}d ago".format(days)

def update_information(
        published_time,
        timezone,
        current_time,
        show_age,
        old_update_hours,
        is_sample):
    published = parse_publication_time(published_time)

    if published == None:
        return {
            "text": "Update time unavailable",
            "old": False,
        }

    local_text = published.in_location(timezone).format(
        "Jan 2, 3:04 PM MST",
    )

    # Historical sample dates are intentional. Avoid a huge age
    # label or old-update warning when viewing sample data.
    if is_sample:
        return {
            "text": "Sample updated: " + local_text,
            "old": False,
        }

    age_seconds = max(
        0,
        current_time - published.unix,
    )

    is_old = (
        old_update_hours > 0 and
        age_seconds >= old_update_hours * 3600
    )

    text = "Updated: " + local_text

    if show_age:
        text += " | " + format_update_age(age_seconds)

    if is_old:
        text = "OLD UPDATE | " + text

    return {
        "text": text,
        "old": is_old,
    }

def read_storms(xml, observer_coordinates):
    items = xml.query_all("/rss/channel/item")
    storms = []
    seen_identifiers = []
    cyclone_entry_count = 0

    for index in range(len(items)):
        item_path = "/rss/channel/item[{}]".format(index + 1)
        cyclone_path = item_path + "/nhc:Cyclone"

        cyclone_nodes = xml.query_all(cyclone_path)

        if not cyclone_nodes:
            continue

        cyclone_entry_count += 1

        name = clean_text(
            xml.query(cyclone_path + "/nhc:name"),
        )
        storm_type = clean_text(
            xml.query(cyclone_path + "/nhc:type"),
        )
        center_text = xml.query(cyclone_path + "/nhc:center")
        coordinates = parse_storm_center(center_text)

        if not name:
            log_error(
                "Skipping cyclone item {}: missing name".format(index + 1),
            )
            continue

        if coordinates == None:
            log_error(
                "Skipping {}: invalid center {}".format(
                    name,
                    repr(center_text),
                ),
            )
            continue

        identifier = clean_text(
            xml.query(cyclone_path + "/nhc:atcf"),
        ).upper()

        if not identifier:
            identifier = "item-{}".format(index + 1)

        if identifier in seen_identifiers:
            continue

        seen_identifiers.append(identifier)

        advisory_time = clean_text(
            xml.query(cyclone_path + "/nhc:datetime"),
        )

        published_time = clean_text(
            xml.query(item_path + "/pubDate"),
        )

        storm_distance = distance(
            observer_coordinates[0],
            observer_coordinates[1],
            coordinates[0],
            coordinates[1],
        )

        storms.append({
            "id": identifier,
            "name": name,
            "type": storm_type or "Tropical system",
            "movement": clean_text(
                xml.query(cyclone_path + "/nhc:movement"),
            ),
            "pressure": clean_text(
                xml.query(cyclone_path + "/nhc:pressure"),
            ),
            "wind": clean_text(
                xml.query(cyclone_path + "/nhc:wind"),
            ),
            "headline": clean_text(
                xml.query(cyclone_path + "/nhc:headline"),
            ),
            "advisory_time": advisory_time,
            "published_time": published_time,
            "distance": storm_distance,
            "bearing": get_bearing(
                observer_coordinates[0],
                observer_coordinates[1],
                coordinates[0],
                coordinates[1],
            ),
        })

    return {
        "storms": sorted(
            storms,
            key = lambda storm: storm["distance"],
        ),
        "cyclone_entries": cyclone_entry_count,
    }

def storm_icon(storm_type):
    normalized_type = clean_text(storm_type).lower()

    if normalized_type == "hurricane":
        return HURRICANE_ANIMATION

    if normalized_type == "tropical storm":
        return TROPICAL_STORM_ANIMATION

    return NHC_ICON

def storm_label(storm):
    return "{} {}".format(
        storm["type"],
        storm["name"],
    )

def nearest_storm_details(storm):
    parts = [
        "{}: {} miles {} of you".format(
            storm_label(storm),
            format_distance(storm["distance"]),
            storm["bearing"],
        ),
        "Winds: {}".format(storm["wind"] or "unavailable"),
        "Pressure: {}".format(storm["pressure"] or "unavailable"),
        "Movement: {}".format(storm["movement"] or "unavailable"),
    ]

    return " | ".join(parts)

def storm_headlines(storms, show_other_systems):
    nearest = storms[0]

    parts = [
        "{}: {}".format(
            storm_label(nearest),
            nearest["headline"] or "No headline supplied",
        ),
    ]

    if show_other_systems and len(storms) > 1:
        parts.append("OTHER TRACKED SYSTEMS")

        for storm in storms[1:]:
            parts.append(
                "{}: Winds {} | {} miles away".format(
                    storm_label(storm),
                    storm["wind"] or "unavailable",
                    format_distance(storm["distance"]),
                ),
            )

    return " | ".join(parts)

def staggered_text_rows(texts, widths, colors, font):
    widgets = []
    offset = 0
    char_width = character_width()

    for index in range(len(texts)):
        text = texts[index]
        text_width = len(text) * char_width
        available_width = widths[index]

        if text_width <= available_width:
            widgets.append(
                render.Text(
                    text,
                    color = colors[index],
                    font = font,
                ),
            )
        else:
            widgets.append(
                render.Marquee(
                    width = available_width,
                    offset_start = offset,
                    child = render.Text(
                        text,
                        color = colors[index],
                        font = font,
                    ),
                ),
            )

            offset += max(
                char_width * 4,
                text_width - available_width // 4,
            )

    return widgets

def display_storm(
        title,
        storms,
        scroll_speed,
        is_sample,
        timezone,
        current_time,
        rotation_ms,
        show_age,
        old_update_hours,
        show_other_systems):
    nearest = storms[0]

    update = update_information(
        nearest.get("published_time"),
        timezone,
        current_time,
        show_age,
        old_update_hours,
        is_sample,
    )

    row1 = title + " | " + update["text"]

    if is_sample:
        row1 = "SAMPLE | " + row1

    row2 = nearest_storm_details(nearest)
    row3 = storm_headlines(storms, show_other_systems)

    font = display_font()
    title_color = OLD_UPDATE_COLOR if update["old"] else NHC_COLOR_ALT

    rows = staggered_text_rows(
        [row1, row2, row3],
        [
            canvas.width() - ICON_WIDTH,
            canvas.width(),
            canvas.width(),
        ],
        [
            title_color,
            "#fff",
            "#ff0",
        ],
        font,
    )

    return render.Root(
        show_full_animation = True,
        delay = scroll_speed,
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Box(
                            width = canvas.width() - ICON_WIDTH,
                            height = ICON_WIDTH,
                            child = rows[0],
                        ),
                        animated_storm_icon(
                            nearest["type"],
                            scroll_speed,
                            rotation_ms,
                        ),
                    ],
                ),
                rows[1],
                rows[2],
            ],
        ),
    )

def main(config):
    scroll_speed = max(1, int(config.get("scroll", "60")))

    if config.bool("show_instructions", False):
        return display_instructions(scroll_speed)

    basin = config.get("basin", "atlantic") or "atlantic"
    hide_quiet = config.bool("hide_quiet", True)
    show_errors = config.bool("display_errors", False)

    rotation_ms = max(
        1000,
        int(config.get("rotation_speed", "6000")),
    )
    show_age = config.bool("show_update_age", True)
    old_update_hours = max(
        0,
        int(config.get("old_update_hours", "12")),
    )
    show_other_systems = config.bool("show_other_systems", True)
    is_sample = DEBUG_MODE or config.bool("sample_mode", False)

    if basin not in BASIN_URLS:
        log_error(
            "Unknown basin {}; using Atlantic".format(repr(basin)),
        )
        basin = "atlantic"

    location = json.decode(
        config.get("location", DEFAULT_LOCATION),
    )

    if type(location) != "dict":
        return display_error(
            "Location configuration is invalid",
            show_errors,
            scroll_speed,
        )

    observer_coordinates = parse_coordinates(
        location.get("lat"),
        location.get("lng"),
    )

    if observer_coordinates == None:
        return display_error(
            "Location coordinates are invalid",
            show_errors,
            scroll_speed,
        )

    timezone = (
        location.get("timezone") or
        config.get("$tz") or
        time.tz()
    )

    if is_sample:
        basin_xml = get_sample_rss()
    else:
        response = http.get(
            url = BASIN_URLS[basin],
            ttl_seconds = CACHE_TTL,
        )

        if response.status_code != 200:
            return display_error(
                "NHC request failed: HTTP {}".format(
                    response.status_code,
                ),
                show_errors,
                scroll_speed,
            )

        basin_xml = response.body()

        if not basin_xml or not basin_xml.strip():
            return display_error(
                "NHC returned an empty feed",
                show_errors,
                scroll_speed,
            )

    xml = xpath.loads(basin_xml)

    if not xml.query_all("/rss/channel"):
        return display_error(
            "Response is missing an RSS channel",
            show_errors,
            scroll_speed,
        )

    title = basin_title(xml, basin)
    result = read_storms(xml, observer_coordinates)
    storms = result["storms"]

    if not storms:
        if result["cyclone_entries"] > 0:
            return display_error(
                "Cyclone entries found, but none has usable location data",
                show_errors,
                scroll_speed,
            )

        if hide_quiet:
            return []

        if is_sample:
            title = "SAMPLE | " + title

        return display_status(
            title,
            "No tracked tropical cyclones | Outlook disturbances not shown",
            scroll_speed,
        )

    return display_storm(
        title,
        storms,
        scroll_speed,
        is_sample,
        timezone,
        time.now().unix,
        rotation_ms,
        show_age,
        old_update_hours,
        show_other_systems,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "show_instructions",
                name = "Show Instructions",
                desc = (
                    "Show four scrolling help rows instead of " +
                    "live hurricane tracking."
                ),
                icon = "info",
                default = False,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = (
                    "Calculate distance and direction to the nearest " +
                    "tracked system, and display update times locally."
                ),
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "basin",
                name = "Hurricane Basin",
                desc = "Which hurricane basin do you want to monitor?",
                icon = "globe",
                options = BASIN_OPTIONS,
                default = "atlantic",
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Text scrolling speed.",
                icon = "stopwatch",
                options = SCROLL_SPEED_OPTIONS,
                default = "60",
            ),
            schema.Dropdown(
                id = "rotation_speed",
                name = "Storm Rotation Speed",
                desc = (
                    "Approximate time for one full revolution, " +
                    "independent of text scrolling speed."
                ),
                icon = "stopwatch",
                options = ROTATION_SPEED_OPTIONS,
                default = "6000",
            ),
            schema.Toggle(
                id = "show_update_age",
                name = "Show Update Age",
                desc = (
                    "Show how long ago the selected system's feed item " +
                    "was published. Historical sample data is exempt."
                ),
                icon = "info",
                default = True,
            ),
            schema.Dropdown(
                id = "old_update_hours",
                name = "Old Update Threshold",
                desc = (
                    "Label the selected system's update OLD UPDATE " +
                    "and change the header color after this age. " +
                    "This is a freshness label, not a storm-threat alert."
                ),
                icon = "stopwatch",
                options = OLD_UPDATE_OPTIONS,
                default = "12",
            ),
            schema.Toggle(
                id = "show_other_systems",
                name = "Show Other Tracked Systems",
                desc = (
                    "Append other systems, nearest first, after the " +
                    "selected system's headline."
                ),
                icon = "globe",
                default = True,
            ),
            schema.Toggle(
                id = "hide_quiet",
                name = "Hide When No Tracked Systems",
                desc = (
                    "Skip the app when the feed contains no cyclone " +
                    "entries. Developing outlook disturbances are not shown."
                ),
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "display_errors",
                name = "Display Errors",
                desc = (
                    "Show detected HTTP, feed-structure, and data errors " +
                    "on the display. Errors are also printed to Render Debug."
                ),
                icon = "info",
                default = False,
            ),
            schema.Toggle(
                id = "sample_mode",
                name = "Show Sample Data",
                desc = (
                    "Use the historical-style test systems instead of " +
                    "the live feed. The display is clearly labeled SAMPLE."
                ),
                icon = "gear",
                default = False,
            ),
        ],
    )

def get_sample_rss():
    sample_storms = [
        [
            "AAA",
            "29.3, -86.5",
            "AL012013",
            (
                "...TROPICAL STORM FORMS IN THE EAST-CENTRAL GULF OF MEXICO... " +
                "...TROPICAL STORM WARNING ISSUED FOR PARTS OF THE " +
                "FLORIDA WEST COAST..."
            ),
        ],
        [
            "BARBARA",
            "25.2, -86.5",
            "EP022013",
            (
                "...TROPICAL STORM FORMS IN THE EAST-CENTRAL GULF OF MEXICO... " +
                "...TROPICAL STORM WARNING ISSUED FOR PARTS OF THE " +
                "FLORIDA WEST COAST..."
            ),
        ],
        [
            "Rob",
            "25.1, -90.5",
            "AL032013",
            "...TROPICAL STORM FORMS...",
        ],
        [
            "Zelda",
            "23.3, -79.5",
            "AL042013",
            (
                "...TROPICAL STORM FORMS IN THE EAST-CENTRAL GULF OF MEXICO... " +
                "...TROPICAL STORM WARNING ISSUED FOR PARTS OF THE " +
                "FLORIDA WEST COAST..."
            ),
        ],
    ]

    items = []

    for storm in sample_storms:
        items.append("""
<item>
    <title>Sample summary for {name}</title>
    <pubDate>Wed, 05 Jun 2013 22:00:00 GMT</pubDate>
    <nhc:Cyclone>
        <nhc:center>{center}</nhc:center>
        <nhc:type>TROPICAL STORM</nhc:type>
        <nhc:name>{name}</nhc:name>
        <nhc:atcf>{identifier}</nhc:atcf>
        <nhc:datetime>6:00 PM EDT Wed Jun 5</nhc:datetime>
        <nhc:movement>N at 3 mph</nhc:movement>
        <nhc:pressure>1002 mb</nhc:pressure>
        <nhc:wind>40 mph</nhc:wind>
        <nhc:headline>{headline}</nhc:headline>
    </nhc:Cyclone>
</item>
""".format(
            name = storm[0],
            center = storm[1],
            identifier = storm[2],
            headline = storm[3],
        ))

    return """
<rss xmlns:nhc="http://www.nhc.noaa.gov" version="2.0">
    <channel>
        <title>NHC Sample Basin</title>
        <description>Historical-style synthetic test data, not current conditions.</description>
        {items}
    </channel>
</rss>
""".format(
        items = "\n".join(items),
    )
