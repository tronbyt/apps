"""
Applet: Interstates
Summary: Displays Interstate Maps
Description: Displays different Interstate highways.
Author: Robert Ison
"""

load("highways.star", "all_highways")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")
load("usa_map_data.star", "usa_map_data")

def get_best_corner(highway_name, width, height):
    default_pos = (1, 1)

    top_right_highways = ["I-15", "I-4", "I-91"]
    bottom_left_highways = ["I-20", "I-90", "I-94", "I-84"]
    bottom_right_highways = ["I-80", "I-70", "I-5", "I-87"]

    if highway_name in top_right_highways:
        return (width - 16, 1)
    if highway_name in bottom_left_highways:
        return (1, height - 17)
    if highway_name in bottom_right_highways:
        return (width - 16, height - 17)

    return default_pos

def get_interstate_sign(number):
    num_str = str(number)
    is_three_digits = len(num_str) > 2

    if is_three_digits:
        font = "CG-pixel-4x5-mono"
        text_width = len(num_str) * 4 + (len(num_str) - 1)
        text_top = 6
    else:
        font = "5x8"
        text_width = len(num_str) * 4 + (len(num_str) - 1)
        text_top = 5

    left_padding = (15 - text_width) // 2

    left_padding = left_padding + 1 if number > 300 else left_padding

    return render.Stack(
        children = [
            add_padding_to_child_element(render.Box(width = 3, height = 1, color = "#fff"), left = 0, top = 0),
            add_padding_to_child_element(render.Box(width = 3, height = 1, color = "#fff"), left = 6, top = 0),
            add_padding_to_child_element(render.Box(width = 3, height = 1, color = "#fff"), left = 12, top = 0),
            add_padding_to_child_element(render.Box(width = 15, height = 12, color = "#fff"), left = 0, top = 1),
            add_padding_to_child_element(render.Box(width = 13, height = 2, color = "#fff"), left = 1, top = 13),
            add_padding_to_child_element(render.Box(width = 11, height = 1, color = "#fff"), left = 2, top = 15),
            add_padding_to_child_element(render.Box(width = 9, height = 1, color = "#fff"), left = 3, top = 16),

            add_padding_to_child_element(render.Box(width = 13, height = 2, color = "#cc0000"), left = 1, top = 2),

            add_padding_to_child_element(render.Box(width = 13, height = 9, color = "#003399"), left = 1, top = 4),
            add_padding_to_child_element(render.Box(width = 11, height = 2, color = "#003399"), left = 2, top = 13),
            add_padding_to_child_element(render.Box(width = 9, height = 1, color = "#003399"), left = 3, top = 15),

            add_padding_to_child_element(
                render.Text(content = num_str, font = font, color = "#fff"),
                left = left_padding,
                top = text_top,
            ),
        ],
    )

def get_bounds(coordinates):
    """
    Looks through the coordinates and determins the min and max x and y coordinates

    Args:
        coordinates (List of lists): The coordinates

    Returns:
        dictionary of min and max coordinates

    """
    if not coordinates:
        return {"min_x": None, "max_x": None, "min_y": None, "max_y": None}

    min_x = coordinates[0][0]
    max_x = coordinates[0][0]
    min_y = coordinates[0][1]
    max_y = coordinates[0][1]

    for coord in coordinates:
        x, y = coord[0], coord[1]
        if x < min_x:
            min_x = x
        if x > max_x:
            max_x = x
        if y < min_y:
            min_y = y
        if y > max_y:
            max_y = y

    return {"min_x": min_x, "max_x": max_x, "min_y": min_y, "max_y": max_y}

def normalize_coordinates(coords, bounds, grid_width, grid_height):
    # Extract all coordinate pairs from the nested structure
    raw_coords = []
    for point in coords:
        raw_coords.append((point[0], point[1]))

    # Initialize min/max values
    min_x = bounds["min_x"]
    max_x = bounds["max_x"]
    min_y = bounds["min_y"]
    max_y = bounds["max_y"]

    # Function to scale values to fit within the grid
    def scale(value, min_val, max_val, new_min, new_max):
        return int((value - min_val) * (new_max - new_min) / (max_val - min_val) + new_min)

    # Normalize coordinates to fit within the grid
    grid_points = []

    for coord in raw_coords:
        x = coord[0]
        y = coord[1]
        grid_x = scale(x, min_x, max_x, 0, grid_width - 1)
        grid_y = scale(y, min_y, max_y, 0, grid_height - 1)
        grid_points.append((grid_x, grid_y))  # Allow duplicates

    return grid_points  # Return as a list with duplicates allowed

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
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )

    return padded_element

def main(config):
    map_color = config.get("map_color", "#0f0")
    highlight_color = config.get("highlight_color", "#f00")
    system_color = config.get("system_color", "#444")
    show_sign = config.bool("show_sign", True)

    mode = config.get("mode", "all")
    selection = config.get("highway_selection", "random")
    highway_keys = sorted(all_highways.keys(), key = lambda x: int(x.split("-")[1]))


    if selection == "random":
        random_index = int(time.now().unix // 15) % len(highway_keys)
        highway_name = highway_keys[random_index]
    else:
        highway_name = selection

    highway_number = int(highway_name.split("-")[1])
    mainland_coords = usa_map_data["coordinates"][0][0]
    mainland_bounds = get_bounds(mainland_coords)

    width, height = canvas.width(), canvas.height()
    map_w, map_h, off_x, off_y = width - 3, height - 4, 4, -2

    layers = []

    # 2. USA Map Outline
    map_grid = normalize_coordinates(mainland_coords, mainland_bounds, map_w, map_h)
    layers.append(add_padding_to_child_element(get_plot(map_grid, width, height, color = map_color), off_x, off_y))

    # 3. Background Highways
    if mode == "all":
        for h_name in highway_keys:
            if h_name != highway_name:
                h_coords = all_highways[h_name]
                h_grid = normalize_coordinates(h_coords, mainland_bounds, map_w, map_h)
                layers.append(add_padding_to_child_element(get_plot(h_grid, width, height, color = system_color), off_x, off_y))

    # 4. Animated Highlighted Highway
    active_coords = all_highways[highway_name]
    active_grid = normalize_coordinates(active_coords, mainland_bounds, map_w, map_h)

    animation_frames = []

    # Drawing Phase
    for i in range(1, len(active_grid) + 1):
        partial_grid = active_grid[:i]
        frame = add_padding_to_child_element(
            get_plot(partial_grid, width, height, color = highlight_color),
            off_x,
            off_y,
        )
        animation_frames.append(frame)

    # Rest Phase: Add the full highway for ~30 more frames
    # At a 100ms delay, 30 frames = 3 seconds of "rest"
    full_highway_frame = animation_frames[-1]
    for _ in range(30):
        animation_frames.append(full_highway_frame)

    animated_highway = render.Animation(
        children = animation_frames,
    )
    layers.append(animated_highway)

    if show_sign:
        sign_pos = get_best_corner(highway_name, width, height)
        layers.append(add_padding_to_child_element(get_interstate_sign(highway_number), sign_pos[0], sign_pos[1]))

    delay = 50 if canvas.is2x() else 100

    return render.Root(child = render.Stack(children = layers), delay = delay)

def get_schema():
    highway_options = [schema.Option(display = "Random", value = "random")]
    for h in sorted(all_highways.keys(), key = lambda x: int(x.split("-")[1])):
        highway_options.append(schema.Option(display = h, value = h))

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "mode",
                name = "Display Mode",
                desc = "How to show the interstates.",
                icon = "display",
                default = "all",
                options = [
                    schema.Option(display = "Single Highway", value = "single"),
                    schema.Option(display = "Highlight one but show all", value = "all"),
                ],
            ),
            schema.Dropdown(
                id = "highway_selection",
                name = "Interstate",
                desc = "Select a specific highway.",
                icon = "road",
                default = "random",
                options = highway_options,
            ),
            schema.Toggle(
                id = "show_sign",
                name = "Show Sign",
                desc = "Show the interstate sign in the corner.",
                icon = "shield",
                default = True,
            ),
            schema.Color(
                id = "map_color",
                name = "Map Color",
                desc = "Color of the USA outline.",
                icon = "map",
                default = "#0f0",
            ),
            schema.Color(
                id = "highlight_color",
                name = "Highlight Color",
                desc = "Color of the selected highway.",
                icon = "brush",
                default = "#f00",
            ),
            schema.Color(
                id = "system_color",
                name = "Other Highways",
                desc = "Color of the background highways.",
                icon = "circleNodes",
                default = "#444",
            ),
        ],
    )
