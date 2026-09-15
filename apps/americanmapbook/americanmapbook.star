"""
Applet: American Mapbook
Summary: American Mapbook
Description: Tracking your visits across the USA
Author: Robert Ison
"""

load("americanmapbook_data.star", "presidential_libraries", "usa_capitols", "usa_map_data", "usa_national_parks", "world_heritage_sites")
load("render.star", "canvas", "render")
load("schema.star", "schema")

DEFAULT_COLORS = ["#009A17", "#708090", "#FFD700"]  #map, unvisited, visited

def get_bounds(coordinates):
    xs = [coord[0] for coord in coordinates]
    ys = [coord[1] for coord in coordinates]

    return {
        "min_x": min(xs),
        "max_x": max(xs),
        "min_y": min(ys),
        "max_y": max(ys),
    }

def normalize_coordinates(coords, bounds, grid_width, grid_height):
    raw_coords = []
    for point in coords:
        raw_coords.append((point[0], point[1]))

    # Initialize min/max values
    min_x = bounds["min_x"]
    max_x = bounds["max_x"]
    min_y = bounds["min_y"]
    max_y = bounds["max_y"]

    def scale(value, min_val, max_val, new_min, new_max):
        if max_val == min_val:
            # Degenerate case: all points share the same coordinate; put them in the middle.
            return int((new_min + new_max) / 2)
        return int((value - min_val) * (new_max - new_min) / (max_val - min_val) + new_min)

    grid_points = []
    for coord in raw_coords:
        x = coord[0]
        y = coord[1]
        grid_x = scale(x, min_x, max_x, 0, grid_width - 1)
        grid_y = scale(y, min_y, max_y, 0, grid_height - 1)
        grid_points.append((grid_x, grid_y))

    return grid_points

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

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    return render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )

def convert_point_for_map(point, offset, height):
    converted_x = point[0] + offset[2]
    converted_y = height - point[1] + offset[3]
    return converted_x, converted_y

def main(config):
    # Holds the coordinates of the outline of the different maps
    mainland_coordinates = []
    hawaii_coordinates = []
    alaska_coordinates = []

    # The usa_map_data coordinates come in multiple subgroups.
    # For mapping purposes, group them into mainland, Hawaii, and Alaska.
    # Group geojson subgroups into mainland, Hawaii, and Alaska
    MAINLAND_SECTION_INDEXES = [1]
    HAWAII_SECTION_INDEXES = [2, 3, 4, 5, 6]
    ALASKA_SECTION_INDEXES = [7, 8, 9]

    mainland_sections = MAINLAND_SECTION_INDEXES
    hawaii_sections = HAWAII_SECTION_INDEXES
    alaska_sections = ALASKA_SECTION_INDEXES

    map_color = config.get("map_outline_color", DEFAULT_COLORS[0])
    unvisited_color = config.get("unvisited_color", DEFAULT_COLORS[1])
    visited_color = config.get("visited_color", DEFAULT_COLORS[2])

    subgroup_counter = 0
    for group in usa_map_data["coordinates"]:
        for subgroup in group:
            subgroup_counter = subgroup_counter + 1

            for coordinate in subgroup:
                if subgroup_counter in mainland_sections:
                    mainland_coordinates.append([coordinate[0], coordinate[1]])
                elif subgroup_counter in hawaii_sections:
                    hawaii_coordinates.append([coordinate[0], coordinate[1]])
                elif subgroup_counter in alaska_sections:
                    alaska_coordinates.append([coordinate[0], coordinate[1]])

    # now that we have all the coordinates of the three map sections, let's figure out the bounds to help us map properly on our tidbyt display
    mainland_bounds = get_bounds(mainland_coordinates)
    hawaii_bounds = get_bounds(hawaii_coordinates)
    alaska_bounds = get_bounds(alaska_coordinates)

    # keep track of the three different maps
    maps = [mainland_bounds, hawaii_bounds, alaska_bounds]

    # Create frames for display
    animation_frames = []  # Build the animation gradually instead of rendering everything at once.
    items_to_plot = []  # Keep track of everything currently visible in the animation.

    width, height = canvas.width(), canvas.height()
    is2x = canvas.is2x()
    font = "terminus-14" if is2x else "CG-pixel-3x5-mono"
    dot_size = 1  #if is2x else 1

    # This map of USA includes Alaska and Hawaii
    # Offset for Mainland, Hawaii, Alaska - width of map, height of map, move right, move up
    offsets = [
        [width - 3, height - 2, 4, -2],
        [16, 16, 20, -2] if is2x else [10, 10, 10, 0],
        [20, 20, 2, -2] if is2x else [12, 12, 0, 0],
    ]

    # now that we figured out the bounds for each geographic area, we can
    # calculate the plot points
    subgroup_counter = 0
    for group in usa_map_data["coordinates"]:
        for subgroup in group:
            subgroup_counter = subgroup_counter + 1
            offset_idx = -1
            if subgroup_counter in mainland_sections:
                offset_idx = 0
            elif subgroup_counter in hawaii_sections:
                offset_idx = 1
            elif subgroup_counter in alaska_sections:
                offset_idx = 2
            if offset_idx != -1:
                bounds = maps[offset_idx]
                offset_vals = offsets[offset_idx]
                gridpoints = normalize_coordinates(subgroup, bounds, offset_vals[0], offset_vals[1])
                plot = get_plot(gridpoints, width, height, map_color)
                padded_plot = add_padding_to_child_element(plot, offset_vals[2], offset_vals[3])
                items_to_plot.append(padded_plot)

            # Animation Frames start with each group of outlines for USA areas
            animation_frames.append(render.Stack(children = items_to_plot))

    # now add all items
    group_coordinates = [[], [], []]
    visited_group_coordinates = [[], [], []]

    #defaults
    usa_locations = usa_capitols
    preface = "PARK"
    config_item = "park"

    tracking_type = config.get("type", TRACKING_OPTIONS[0].value)
    if tracking_type == "national_parks":
        usa_locations = usa_national_parks
        preface = "PARK"
        config_item = "park"
    elif tracking_type == "world_heritage_sites":
        usa_locations = world_heritage_sites
        preface = "HERITAGE"
        config_item = "site"
    elif tracking_type == "presidential_libraries":
        usa_locations = presidential_libraries
        preface = "PRESIDENTIAL"
        config_item = "site"
    else:
        usa_locations = usa_capitols
        preface = "STATE"
        config_item = "location"

    total_visited = 0

    if usa_locations != None:
        for location in usa_locations:
            idx = location["map"] - 1
            if (0 <= idx) and (idx < len(group_coordinates)):
                if config.get("%s_%s_%s" % (preface, slugify(location["state"]), slugify(location[config_item.lower()]))) == "true":
                    visited_group_coordinates[idx].append([location["coordinates"]["lon"], location["coordinates"]["lat"]])
                else:
                    group_coordinates[idx].append([location["coordinates"]["lon"], location["coordinates"]["lat"]])

        # Loop through all three groups of unvisited
        for i, group in enumerate(group_coordinates):
            gridpoints = normalize_coordinates(group, maps[i], offsets[i][0], offsets[i][1])

            for point in gridpoints:
                # The plot coordinates start at the bottom left
                # however, the coordinates of the individual dots start at the top right
                # also, these points are moved around to fit on the 'inset' map they belong to
                # these formulae account for those adjustments to get the items on the right spot on the right map
                converted_x, converted_y = convert_point_for_map(point, offsets[i], height)

                items_to_plot.append(add_padding_to_child_element(get_dot(unvisited_color, dot_size), converted_x, converted_y))

                # Next set of frames is MAP + unvisited Items one at a time
                animation_frames.append(render.Stack(children = items_to_plot))

        # Loop through all three groups of visited
        for i, group in enumerate(visited_group_coordinates):
            gridpoints = normalize_coordinates(group, maps[i], offsets[i][0], offsets[i][1])

            for point in gridpoints:
                converted_x, converted_y = convert_point_for_map(point, offsets[i], height)
                total_visited = total_visited + 1

                # Add the visited dot
                items_to_plot.append(
                    add_padding_to_child_element(
                        get_dot(visited_color, dot_size),
                        converted_x,
                        converted_y,
                    ),
                )

                # Prepare a frame-specific children list so we don't keep stacking count boxes
                frame_children = list(items_to_plot)

                if config.get("showCount") == "true":
                    display_text = render.Text(
                        content = str(total_visited),
                        font = font,
                        color = visited_color,
                    )
                    text_w, text_h = display_text.size()
                    pad = 2 if is2x else 1
                    count_box = add_padding_to_child_element(
                        render.Box(
                            color = "#000",
                            width = text_w,
                            height = text_h,
                            child = display_text,
                        ),
                        width - pad - text_w,
                        height - pad - text_h,
                    )
                    frame_children.append(count_box)

                # For each visited point, add a frame with map + unvisited + visited (+ optional count)
                animation_frames.append(render.Stack(children = frame_children))

    # Add several frames of the final product to keep on screen for longer
    for _ in range(100):
        final_items = list(items_to_plot)

        if config.get("showCount") == "true":
            display_text = render.Text(
                content = str(total_visited),
                font = font,
                color = visited_color,
            )
            text_w, text_h = display_text.size()
            pad = 2 if is2x else 1

            final_items.append(
                add_padding_to_child_element(
                    render.Box(
                        color = "#000",
                        width = text_w,
                        height = text_h,
                        child = display_text,
                    ),
                    width - pad - text_w,
                    height - pad - text_h,
                ),
            )

        animation_frames.append(render.Stack(children = final_items))

    return render.Root(
        delay = 75,
        child = render.Animation(
            children = animation_frames,
        ),
    )

def get_location_options(locations):
    sorted_locations = sorted(locations, key = lambda entry: entry["state"])

    return [
        schema.Toggle(id = "STATE_%s_%s" % (location["state"].replace(" ", "_"), location["location"].replace(" ", "_")), name = location["state"], desc = "%s, %s" % (location["location"], location["state"]), icon = "landmarkDome", default = False)
        for location in sorted_locations
    ]

def get_national_park_options(parks):
    sorted_parks = sorted(parks, key = lambda entry: (entry["state"], entry["park"]))

    return [
        schema.Toggle(id = "PARK_%s_%s" % (park["state"].replace(" ", "_"), park["park"].replace(" ", "_")), name = park["park"].replace(" National Park", ""), desc = "%s, %s" % (park["park"], park["state"]), icon = "tree", default = False)
        for park in sorted_parks
    ]

def get_world_heritage_options(sites):
    sorted_sites = sorted(sites, key = lambda entry: (entry["state"], entry["site"]))

    return [
        schema.Toggle(id = "HERITAGE_%s_%s" % (site["state"].replace(" ", "_"), site["site"].replace(" ", "_")), name = site["site"], desc = "%s, %s" % (site["site"], site["state"]), icon = "locationPin", default = False)
        for site in sorted_sites
    ]

def get_presidential_library_options(libraries):
    sorted_libraries = sorted(libraries, key = lambda entry: (entry["state"], entry["site"]))

    return [
        schema.Toggle(
            id = "PRESIDENTIAL_%s_%s" % (
                slugify(library["state"]),
                slugify(library["site"]),
            ),
            name = library["site"],
            desc = "%s, %s" % (library["site"], library["state"]),
            icon = "landmarkDome",
            default = False,
        )
        for library in sorted_libraries
    ]

TRACKING_OPTIONS = [
    schema.Option(value = "national_parks", display = "National Parks"),
    schema.Option(value = "presidential_libraries", display = "Presidential Libraries"),
    schema.Option(value = "capitols", display = "State Capitols"),
    schema.Option(value = "world_heritage_sites", display = "World Heritage Sites"),
]

def slugify(value):
    return (
        value
            .replace(" ", "_")
            .replace(".", "")
            .replace(",", "")
            .replace("'", "")
            .replace("-", "_")
    )

def get_tracking_items(tracking_type):
    if tracking_type == "capitols":
        return get_location_options(usa_capitols)
    elif tracking_type == "national_parks":
        return get_national_park_options(usa_national_parks)
    elif tracking_type == "world_heritage_sites":
        return get_world_heritage_options(world_heritage_sites)
    elif tracking_type == "presidential_libraries":
        return get_presidential_library_options(presidential_libraries)
    else:
        return get_location_options(usa_capitols)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "showCount",
                name = "Count",
                desc = "Display the Count of Visited Items?",
                icon = "calculator",
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
