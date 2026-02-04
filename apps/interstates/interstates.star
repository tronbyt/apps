"""
Applet: Interstates
Summary: Displays Interstate Maps
Description: Displays different Interstate highways.
Author: Robert Ison
"""

load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")
load("usa_map_data.star", "usa_map_data")
load("highways.star", "all_highways")

def get_best_corner(active_highway_points, width, height):
    # We are going to be more aggressive with the "Top" boxes 
    # to catch I-90 and I-94 which run very close to the top edge.
    
    # bw = box width, bh = box height
    bw, bh = 22, 20 
    
    corners = [
        # 1. Top Left
        {"pos": (1, 1), "x": (0, bw), "y": (0, bh)},
        # 2. Top Right
        {"pos": (width - 16, 1), "x": (width - bw, width), "y": (0, bh)},
        # 3. Bottom Left
        {"pos": (1, height - 17), "x": (0, bw), "y": (height - bh, height)},
        # 4. Bottom Right
        {"pos": (width - 16, height - 17), "x": (width - bw, width), "y": (height - bh, height)},
    ]

    for corner in corners:
        collision = False
        for px, py in active_highway_points:
            # If the red highway is ANYWHERE in this corner's box, we reject the corner.
            if (px >= corner["x"][0] and px <= corner["x"][1] and 
                py >= corner["y"][0] and py <= corner["y"][1]):
                collision = True
                break
        
        if not collision:
            return corner["pos"]

    # If the highway is literally everywhere, default to Bottom Left 
    # (usually the emptiest spot on a US map)
    return (1, height - 17)
    
def get_interstate_sign(number):
    num_str = str(number)
    is_three_digits = len(num_str) > 2

    if is_three_digits:
        font = "CG-pixel-4x5-mono"
        text_width = len(num_str) * 4 + (len(num_str) - 1)
        text_top = 5 # 5px tall font needs to be lowered to center in the blue
    else:
        font = "5x8"
        text_width = len(num_str) * 4 + (len(num_str) - 1)
        text_top = 4# 8px tall font sits higher

    left_padding = (15 - text_width) // 2

    return render.Stack(
        children = [
            # --- WHITE OUTLINE ---
            #add_padding_to_child_element(render.Box(width=13, height=1, color="#fff"), left=1, top=0),
            add_padding_to_child_element(render.Box(width=3, height=1, color="#fff"), left=0, top=0),
            add_padding_to_child_element(render.Box(width=3, height=1, color="#fff"), left=6, top=0),
            add_padding_to_child_element(render.Box(width=3, height=1, color="#fff"), left=12, top=0),
            add_padding_to_child_element(render.Box(width=15, height=8, color="#fff"), left=0, top=1),
            add_padding_to_child_element(render.Box(width=13, height=2, color="#fff"), left=1, top=9),
            add_padding_to_child_element(render.Box(width=11, height=2, color="#fff"), left=2, top=10),
            add_padding_to_child_element(render.Box(width=9, height=2, color="#fff"), left=3, top=12),
            add_padding_to_child_element(render.Box(width=7, height=1, color="#fff"), left=4, top=14),
            add_padding_to_child_element(render.Box(width=5, height=1, color="#fff"), left=5, top=15),
            add_padding_to_child_element(render.Box(width=3, height=1, color="#fff"), left=7, top=16),

            # # --- RED TOP BAR ---
            add_padding_to_child_element(render.Box(width=13, height=2, color="#cc0000"), left=1, top=2),

            # # --- BLUE BODY ---
            add_padding_to_child_element(render.Box(width=13, height=5, color="#003399"), left=1, top=4),
            add_padding_to_child_element(render.Box(width=11, height=2, color="#003399"), left=2, top=9),
            add_padding_to_child_element(render.Box(width=9, height=1, color="#003399"), left=3, top=11),
            add_padding_to_child_element(render.Box(width=7, height=2, color="#003399"), left=4, top=12),
            add_padding_to_child_element(render.Box(width=5, height=1, color="#003399"), left=5, top=14),

            # --- THE NUMBER ---
            add_padding_to_child_element(
                render.Text(content=num_str, font=font, color="#fff"),
                left=left_padding, 
                top=text_top
            ),
        ]
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

    #print("min_x: %s max_x:  %s , : min_y, %s: max_y: %s" % (min_x, max_x, min_y,max_y))

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
        #print("X: %s Y: %s" % (grid_x, grid_y))

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
    mode = config.get("mode", "single")
    selection = config.get("highway_selection", "random")
    highway_keys = all_highways.keys()

    # Highway Selection Logic
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
    
    # 1. Base Map (Green)
    map_grid = normalize_coordinates(mainland_coords, mainland_bounds, map_w, map_h)
    layers = [add_padding_to_child_element(get_plot(map_grid, width, height, color="#0f0"), off_x, off_y)]

    # 2. Highway Rendering & Collision Point Gathering
    active_points_on_screen = []
    
    if mode == "all":
        # Draw all background highways first (White)
        for h_name in highway_keys:
            if h_name != highway_name:
                h_coords = all_highways[h_name]
                h_grid = normalize_coordinates(h_coords, mainland_bounds, map_w, map_h)
                layers.append(add_padding_to_child_element(get_plot(h_grid, width, height, color="#fff"), off_x, off_y))
        
        # Draw the focused highway on top (Red)
        active_coords = all_highways[highway_name]
        active_grid = normalize_coordinates(active_coords, mainland_bounds, map_w, map_h)
        for pt in active_grid:
            active_points_on_screen.append((pt[0] + off_x, pt[1] + off_y))
        layers.append(add_padding_to_child_element(get_plot(active_grid, width, height, color="#f00"), off_x, off_y))

    else:
        # Single mode: just the one highway (White)
        active_coords = all_highways[highway_name]
        active_grid = normalize_coordinates(active_coords, mainland_bounds, map_w, map_h)
        for pt in active_grid:
            active_points_on_screen.append((pt[0] + off_x, pt[1] + off_y))
        layers.append(add_padding_to_child_element(get_plot(active_grid, width, height, color="#fff"), off_x, off_y))

    # 3. Position Sign (Checks only against the active_points_on_screen)
    sign_pos = get_best_corner(active_points_on_screen, width, height)
    layers.append(add_padding_to_child_element(get_interstate_sign(highway_number), sign_pos[0], sign_pos[1]))

    return render.Root(child = render.Stack(children = layers))
    
def get_schema():
    highway_options = [schema.Option(display="Random", value="random")]
    for h in sorted(all_highways.keys(), key=lambda x: int(x.split("-")[1])):
        highway_options.append(schema.Option(display=h, value=h))

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "mode",
                name = "Display Mode",
                desc = "How to show the interstates.",
                icon = "gear",
                default = "single",
                options = [
                    schema.Option(display = "Single Highway", value = "single"),
                    schema.Option(display = "Highlight in System", value = "all"),
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
        ],
    )
