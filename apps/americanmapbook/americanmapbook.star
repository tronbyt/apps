"""
Applet: American Mapbook
Summary: American Mapbook
Description: Tracking your visits across the USA
Author: Robert Ison
"""

load(
    "americanmapbook_data.star",
    "presidential_libraries",
    "usa_capitols",
    "usa_map_data",
    "usa_national_parks",
    "world_heritage_sites",
)
load("render.star", "canvas", "render")
load("schema.star", "schema")

# Map outline, unvisited locations, visited locations.
DEFAULT_COLORS = ["#009A17", "#708090", "#FFD700"]

FRAME_DELAY = 75
FINAL_HOLD_FRAMES = 100

# These subgroup numbers belong to this specific usa_map_data dataset.
# Recheck them if the source geometry or its subgroup order changes.
MAINLAND_SECTION_INDEXES = [1]
HAWAII_SECTION_INDEXES = [2, 3, 4, 5, 6]
ALASKA_SECTION_INDEXES = [7, 8, 9]

TRACKING_OPTIONS = [
    schema.Option(value = "national_parks", display = "National Parks"),
    schema.Option(
        value = "presidential_libraries",
        display = "Presidential Libraries",
    ),
    schema.Option(value = "capitols", display = "State Capitols"),
    schema.Option(
        value = "world_heritage_sites",
        display = "World Heritage Sites",
    ),
]

def show_instructions_screen():
    width, _ = canvas.size()
    is2x = canvas.is2x()
    font = "terminus-14" if is2x else "CG-pixel-3x5-mono"
    character_width = 8 if is2x else 4

    messages = [
        "American Mapbook",
        "Choose National Parks, Presidential Libraries, State Capitols, or World Heritage Sites in settings. Mark the places you have visited in the checklist.",
        "The map draws first, then unvisited places, then visited places. Default colors: green outline, grey unvisited, yellow visited. Change colors in settings. Nearby places may share a pixel.",
        "Turn on Count to show visited locations, not distinct dots. Alaska and Hawaii appear as insets. Turn off Show Instructions to return to your map.",
    ]

    children = []
    offset = 15

    for index in range(len(messages)):
        message = messages[index]

        children.append(
            render.Marquee(
                width = width,
                offset_start = offset,
                child = render.Text(
                    content = message,
                    font = font,
                    color = "#65D0E6" if index == 0 else "#F4A306",
                ),
            ),
        )

        offset += len(message) * character_width

    return render.Root(
        delay = FRAME_DELAY,
        child = render.Column(children = children),
        show_full_animation = True,
    )

def slugify(value):
    return (
        value
            .replace(" ", "_")
            .replace(".", "")
            .replace(",", "")
            .replace("'", "")
            .replace("-", "_")
    )

def get_visit_setting_id(preface, state, name):
    """Preserve the IDs already used by each category's saved settings.

    Presidential libraries historically used slugify().
    Capitols, parks and heritage sites replaced spaces only.

    Both schema generation and main() must call this helper so punctuation
    cannot make a saved toggle differ from the setting being read.
    """
    if preface == "PRESIDENTIAL":
        state_id = slugify(state)
        name_id = slugify(name)
    else:
        state_id = state.replace(" ", "_")
        name_id = name.replace(" ", "_")

    return "%s_%s_%s" % (preface, state_id, name_id)

def get_bounds(coordinates):
    if not coordinates:
        return None

    xs = [coord[0] for coord in coordinates]
    ys = [coord[1] for coord in coordinates]

    return {
        "min_x": min(xs),
        "max_x": max(xs),
        "min_y": min(ys),
        "max_y": max(ys),
    }

def scale_coordinate(value, min_value, max_value, grid_size):
    if max_value == min_value:
        # All points share this coordinate: place them in the middle.
        return int((grid_size - 1) / 2)

    return int(
        (value - min_value) *
        (grid_size - 1) /
        (max_value - min_value),
    )

def normalize_coordinates(coords, bounds, grid_width, grid_height):
    return [
        (
            scale_coordinate(
                point[0],
                bounds["min_x"],
                bounds["max_x"],
                grid_width,
            ),
            scale_coordinate(
                point[1],
                bounds["min_y"],
                bounds["max_y"],
                grid_height,
            ),
        )
        for point in coords
    ]

def get_plot(grid_points, width, height, color = "#ff0"):
    return render.Plot(
        data = grid_points,
        width = width,
        height = height,
        color = color,
        x_lim = (0, width - 1),
        y_lim = (0, height - 1),
    )

def get_dot(color, size = 1):
    return render.Box(
        width = size,
        height = size,
        color = color,
    )

def add_padding_to_child_element(
        element,
        left = 0,
        top = 0,
        right = 0,
        bottom = 0):
    return render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )

def convert_point_for_map(point, offset, height):
    # Plot coordinates start at bottom-left; widget placement is top-left.
    # The last visible pixel row is height - 1, not height.
    converted_x = point[0] + offset[2]
    converted_y = height - 1 - point[1] + offset[3]
    return converted_x, converted_y

def is_square():
    """Identify square panels by shape, not by height.

    A 128x64 panel is also 64 pixels tall, but its 2:1 shape should retain
    the wide-panel map arrangement.
    """
    width, height = canvas.size()
    return width == height

def get_map_index(subgroup_number):
    if subgroup_number in MAINLAND_SECTION_INDEXES:
        return 0
    elif subgroup_number in HAWAII_SECTION_INDEXES:
        return 1
    elif subgroup_number in ALASKA_SECTION_INDEXES:
        return 2
    return -1

def get_tracking_details(tracking_type):
    if tracking_type == "national_parks":
        return usa_national_parks, "PARK", "park"
    elif tracking_type == "world_heritage_sites":
        return world_heritage_sites, "HERITAGE", "site"
    elif tracking_type == "presidential_libraries":
        return presidential_libraries, "PRESIDENTIAL", "site"

    return usa_capitols, "STATE", "location"

def get_count_box(count, width, height, font, color, is2x):
    display_text = render.Text(
        content = str(count),
        font = font,
        color = color,
    )
    text_width, text_height = display_text.size()
    pad = 2 if is2x else 1

    return add_padding_to_child_element(
        render.Box(
            color = "#000",
            width = text_width,
            height = text_height,
            child = display_text,
        ),
        width - pad - text_width,
        height - pad - text_height,
    )

def get_animation_frame(
        items,
        show_count,
        count,
        width,
        height,
        font,
        color,
        is2x):
    # Snapshot the visible items so subsequent additions cannot alter
    # what this particular frame is intended to contain.
    frame_children = list(items)

    if show_count:
        frame_children.append(
            get_count_box(
                count,
                width,
                height,
                font,
                color,
                is2x,
            ),
        )

    return render.Stack(children = frame_children)

def error_screen(message, width, font):
    return render.Root(
        child = render.WrappedText(
            content = message,
            width = width,
            align = "center",
            color = "#ff0000",
            font = font,
        ),
    )

def main(config):
    if config.bool("show_instructions", False):
        return show_instructions_screen()

    width, height = canvas.size()
    width, height = canvas.size()
    is2x = canvas.is2x()
    font = "terminus-14" if is2x else "CG-pixel-3x5-mono"

    # Markers intentionally remain one pixel on every display.
    dot_size = 1

    show_count = config.bool("showCount", False)
    map_color = config.get("map_outline_color") or DEFAULT_COLORS[0]
    unvisited_color = config.get("unvisited_color") or DEFAULT_COLORS[1]
    visited_color = config.get("visited_color") or DEFAULT_COLORS[2]

    # Group the geometry into mainland, Hawaii and Alaska while preserving
    # each subgroup separately for drawing individual outline segments.
    map_coordinates = [[], [], []]
    outline_sections = []

    subgroup_counter = 0
    for group in usa_map_data["coordinates"]:
        for subgroup in group:
            subgroup_counter += 1
            map_index = get_map_index(subgroup_counter)

            if map_index != -1 and subgroup:
                outline_sections.append((map_index, subgroup))

                for coordinate in subgroup:
                    map_coordinates[map_index].append(
                        (coordinate[0], coordinate[1]),
                    )

    map_bounds = [
        get_bounds(coordinates)
        for coordinates in map_coordinates
    ]

    if None in map_bounds:
        return error_screen(
            "Map data missing: check mainland, Hawaii and Alaska sections.",
            width,
            font,
        )

    # Four pixels of left offset means the normalized mainland can occupy
    # width - 4 pixels without placing its rightmost point off-screen.
    map_width = width - 4
    map_height = height - 2

    # Plot coordinates are bottom-origin. Negative top padding lifts the
    # canvas-sized plot and its normalized map into their intended position.
    map_lift = -2
    inset_lift = 0

    # Keep the mainland approximately 2:1 on square panels rather than
    # stretching it vertically. Move the insets down with the mainland.
    if is_square():
        map_height = map_width // 2
        map_lift = -((height - map_height) // 2)
        inset_lift = map_lift

    # Each entry is:
    # [normalized width, normalized height, horizontal offset, vertical offset]
    offsets = [
        [map_width, map_height, 4, map_lift],
        [16, 16, 20, -2 + inset_lift] if is2x else [10, 10, 10, inset_lift],
        [20, 20, 2, -2 + inset_lift] if is2x else [12, 12, 0, inset_lift],
    ]

    animation_frames = []
    items_to_plot = []

    # Add one outline section per frame. Unassigned or empty subgroups do
    # not create duplicate animation frames.
    for map_index, subgroup in outline_sections:
        offset = offsets[map_index]
        grid_points = normalize_coordinates(
            subgroup,
            map_bounds[map_index],
            offset[0],
            offset[1],
        )

        plot = get_plot(grid_points, width, height, map_color)

        items_to_plot.append(
            add_padding_to_child_element(
                plot,
                offset[2],
                offset[3],
            ),
        )

        animation_frames.append(
            render.Stack(children = list(items_to_plot)),
        )

    tracking_type = config.get("type") or TRACKING_OPTIONS[0].value
    locations, preface, name_field = get_tracking_details(tracking_type)

    if locations == None:
        return error_screen(
            "Location data unavailable.",
            width,
            font,
        )

    unvisited_coordinates = [[], [], []]
    visited_coordinates = [[], [], []]

    for location in locations:
        map_index = location["map"] - 1

        # Preserve the original behavior: entries outside the three
        # supported map groups are not plotted or included in the count.
        if 0 <= map_index and map_index < len(map_bounds):
            setting_id = get_visit_setting_id(
                preface,
                location["state"],
                location[name_field],
            )

            coordinates = (
                location["coordinates"]["lon"],
                location["coordinates"]["lat"],
            )

            if config.bool(setting_id, False):
                visited_coordinates[map_index].append(coordinates)
            else:
                unvisited_coordinates[map_index].append(coordinates)

    # Draw unvisited locations first.
    for map_index, coordinates in enumerate(unvisited_coordinates):
        offset = offsets[map_index]
        grid_points = normalize_coordinates(
            coordinates,
            map_bounds[map_index],
            offset[0],
            offset[1],
        )

        for point in grid_points:
            converted_x, converted_y = convert_point_for_map(
                point,
                offset,
                height,
            )

            items_to_plot.append(
                add_padding_to_child_element(
                    get_dot(unvisited_color, dot_size),
                    converted_x,
                    converted_y,
                ),
            )

            animation_frames.append(
                render.Stack(children = list(items_to_plot)),
            )

    # Visited locations are drawn last so they remain visible when multiple
    # locations occupy the same pixel. The count tracks locations, not pixels.
    total_visited = 0

    for map_index, coordinates in enumerate(visited_coordinates):
        offset = offsets[map_index]
        grid_points = normalize_coordinates(
            coordinates,
            map_bounds[map_index],
            offset[0],
            offset[1],
        )

        for point in grid_points:
            converted_x, converted_y = convert_point_for_map(
                point,
                offset,
                height,
            )

            total_visited += 1

            items_to_plot.append(
                add_padding_to_child_element(
                    get_dot(visited_color, dot_size),
                    converted_x,
                    converted_y,
                ),
            )

            animation_frames.append(
                get_animation_frame(
                    items_to_plot,
                    show_count,
                    total_visited,
                    width,
                    height,
                    font,
                    visited_color,
                    is2x,
                ),
            )

    # Build the final scene once, then repeat it to preserve the original
    # final hold: 100 frames at 75 milliseconds each, nominally 7.5 seconds.
    # This also displays a zero count when no locations are marked visited.
    final_frame = get_animation_frame(
        items_to_plot,
        show_count,
        total_visited,
        width,
        height,
        font,
        visited_color,
        is2x,
    )

    for _ in range(FINAL_HOLD_FRAMES):
        animation_frames.append(final_frame)

    return render.Root(
        delay = FRAME_DELAY,
        child = render.Animation(
            children = animation_frames,
        ),
    )

def get_location_options(locations):
    sorted_locations = sorted(
        locations,
        key = lambda entry: entry["state"],
    )

    return [
        schema.Toggle(
            id = get_visit_setting_id(
                "STATE",
                location["state"],
                location["location"],
            ),
            name = location["state"],
            desc = "%s, %s" % (
                location["location"],
                location["state"],
            ),
            icon = "landmarkDome",
            default = False,
        )
        for location in sorted_locations
    ]

def get_national_park_options(parks):
    sorted_parks = sorted(
        parks,
        key = lambda entry: (entry["state"], entry["park"]),
    )

    return [
        schema.Toggle(
            id = get_visit_setting_id(
                "PARK",
                park["state"],
                park["park"],
            ),
            name = park["park"].replace(" National Park", ""),
            desc = "%s, %s" % (park["park"], park["state"]),
            icon = "tree",
            default = False,
        )
        for park in sorted_parks
    ]

def get_world_heritage_options(sites):
    sorted_sites = sorted(
        sites,
        key = lambda entry: (entry["state"], entry["site"]),
    )

    return [
        schema.Toggle(
            id = get_visit_setting_id(
                "HERITAGE",
                site["state"],
                site["site"],
            ),
            name = site["site"],
            desc = "%s, %s" % (site["site"], site["state"]),
            icon = "locationPin",
            default = False,
        )
        for site in sorted_sites
    ]

def get_presidential_library_options(libraries):
    sorted_libraries = sorted(
        libraries,
        key = lambda entry: (entry["state"], entry["site"]),
    )

    return [
        schema.Toggle(
            id = get_visit_setting_id(
                "PRESIDENTIAL",
                library["state"],
                library["site"],
            ),
            name = library["site"],
            desc = "%s, %s" % (
                library["site"],
                library["state"],
            ),
            icon = "landmarkDome",
            default = False,
        )
        for library in sorted_libraries
    ]

def get_tracking_items(tracking_type):
    if tracking_type == "capitols":
        return get_location_options(usa_capitols)
    elif tracking_type == "national_parks":
        return get_national_park_options(usa_national_parks)
    elif tracking_type == "world_heritage_sites":
        return get_world_heritage_options(world_heritage_sites)
    elif tracking_type == "presidential_libraries":
        return get_presidential_library_options(presidential_libraries)

    return get_location_options(usa_capitols)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "show_instructions",
                name = "Show Instructions",
                desc = "Show scrolling help instead of your map",
                icon = "circleInfo",
                default = False,
            ),
            schema.Toggle(
                id = "showCount",
                name = "Count",
                desc = "Display the Count of Visited Items?",
                icon = "calculator",
                default = False,
            ),
            schema.Color(
                id = "map_outline_color",
                name = "Map",
                desc = "Map Outline Color",
                icon = "brush",
                default = DEFAULT_COLORS[0],
            ),
            schema.Color(
                id = "unvisited_color",
                name = "Unvisited",
                desc = "Unvisited Dot Color",
                icon = "brush",
                default = DEFAULT_COLORS[1],
            ),
            schema.Color(
                id = "visited_color",
                name = "Visited",
                desc = "Visited Dot Color",
                icon = "brush",
                default = DEFAULT_COLORS[2],
            ),
            schema.Dropdown(
                id = "type",
                name = "Tracking",
                desc = "What do you want to track?",
                icon = "mapLocation",
                options = TRACKING_OPTIONS,
                default = TRACKING_OPTIONS[0].value,
            ),
            schema.Generated(
                id = "typelist",
                source = "type",
                handler = get_tracking_items,
            ),
        ],
    )
