"""
Applet: Interstates
Summary: Displays Interstate Maps
Description: Displays Interstate highways with bounded route animations and adaptive shield placement.
Author: Robert Ison
"""

load("highways.star", "all_highways")
load("math.star", "math")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("usa_map_data.star", "usa_map_data")

FRAME_DELAY = 100
DRAW_FRAMES = 40
HOLD_FRAMES = 30
SHIELD_WIDTH = 15
SHIELD_HEIGHT = 17

def numeric(value):
    return type(value) == "int" or type(value) == "float"

def sequence(value):
    return type(value) == "list" or type(value) == "tuple"

def point(value):
    return sequence(value) and len(value) >= 2 and numeric(value[0]) and numeric(value[1])

def highway_number(name):
    if type(name) != "string" or not name.startswith("I-"):
        return None
    text = name[2:]
    if not text or len(text) > 3:
        return None
    for character in text.elems():
        if character not in "0123456789":
            return None
    number = int(text)
    return number if number > 0 else None

def geometry_segments(value):
    # Iterative traversal: Starlark does not allow recursive functions.
    # Supports flat paths, nested paths/rings, and common GeoJSON wrappers.
    pending = [value]
    result = []
    for _ in range(12):
        following = []
        for node in pending:
            if type(node) == "dict":
                if node.get("coordinates") != None:
                    following.append(node["coordinates"])
                elif node.get("geometry") != None:
                    following.append(node["geometry"])
                elif node.get("features") != None:
                    following.append(node["features"])
                elif node.get("geometries") != None:
                    following.append(node["geometries"])
            elif sequence(node) and node:
                has_points = False
                for item in node:
                    if point(item):
                        has_points = True
                if has_points:
                    # Invalid entries split paths rather than bridging gaps.
                    current = []
                    for item in node:
                        if point(item):
                            current.append((item[0], item[1]))
                        else:
                            if current:
                                result.append(current)
                                current = []
                            if sequence(item) or type(item) == "dict":
                                following.append(item)
                    if current:
                        result.append(current)
                else:
                    following.extend(node)
        pending = following
        if not pending:
            break
    return result

def ring_area(coords):
    if len(coords) < 3:
        return 0
    total = 0.0
    for index in range(len(coords)):
        first = coords[index]
        second = coords[(index + 1) % len(coords)]
        total += first[0] * second[1] - second[0] * first[1]
    return abs(total) / 2.0

def mainland_ring():
    rings = geometry_segments(usa_map_data)
    best = None
    best_area = 0
    for ring in rings:
        area = ring_area(ring)
        if area > best_area:
            best = ring
            best_area = area
    return best

def get_bounds(coords):
    if not coords:
        return None
    xs = [item[0] for item in coords]
    ys = [item[1] for item in coords]
    bounds = {"min_x": min(xs), "max_x": max(xs), "min_y": min(ys), "max_y": max(ys)}
    if bounds["min_x"] == bounds["max_x"] or bounds["min_y"] == bounds["max_y"]:
        return None
    return bounds

def normalize_coordinates(coords, bounds, width, height):
    points = []
    for x, y in coords:
        px = int((x - bounds["min_x"]) / (bounds["max_x"] - bounds["min_x"]) * (width - 1))
        py = int((y - bounds["min_y"]) / (bounds["max_y"] - bounds["min_y"]) * (height - 1))
        current = (px, py)
        if not points or points[-1] != current:
            points.append(current)
    return points

def padding(child, left = 0, top = 0):
    return render.Padding(pad = (left, top, 0, 0), child = child)

def plot_path(coords, width, height, color):
    if len(coords) == 1:
        x, y = coords[0]
        if x < 0 or x >= width or y < 0 or y >= height:
            return render.Box(width = 1, height = 1, color = "#000000")
        return padding(render.Box(width = 1, height = 1, color = color), x, height - 1 - y)
    return render.Plot(data = coords, width = width, height = height, color = color, x_lim = (0, width - 1), y_lim = (0, height - 1))

def paths_widget(paths, width, height, color):
    children = [plot_path(path, width, height, color) for path in paths if path]
    return render.Stack(children = children) if children else render.Box(width = 1, height = 1, color = "#000000")

def route_geometry(name):
    return geometry_segments(all_highways[name])

def random_index(count):
    return 0 if count <= 1 else min(int(random.float() * count), count - 1)

def get_interstate_sign(number):
    text = str(number)
    font = "CG-pixel-4x5-mono" if len(text) > 2 else "5x8"
    label = render.Text(content = text, font = font, color = "#FFFFFF")
    text_width, _ = label.size()
    left = max(0, (SHIELD_WIDTH - text_width) // 2)
    top = 6 if len(text) > 2 else 5

    # Keep the original hand-built 15 x 17 shield.
    boxes = [
        (0, 0, 3, 1, "#FFFFFF"),
        (6, 0, 3, 1, "#FFFFFF"),
        (12, 0, 3, 1, "#FFFFFF"),
        (0, 1, 15, 12, "#FFFFFF"),
        (1, 13, 13, 2, "#FFFFFF"),
        (2, 15, 11, 1, "#FFFFFF"),
        (3, 16, 9, 1, "#FFFFFF"),
        (1, 2, 13, 2, "#CC0000"),
        (1, 4, 13, 9, "#003399"),
        (2, 13, 11, 2, "#003399"),
        (3, 15, 9, 1, "#003399"),
    ]
    children = [padding(render.Box(width = w, height = h, color = color), x, y) for x, y, w, h, color in boxes]
    children.append(padding(label, left, top))
    return render.Stack(children = children)

def preferred_corner(name):
    if name in ["I-15", "I-4", "I-91"]:
        return 1
    if name in ["I-20", "I-90", "I-94", "I-84"]:
        return 2
    if name in ["I-80", "I-70", "I-5", "I-87"]:
        return 3
    return 0

def screen_pixels(paths, map_width, map_height, left, top):
    # Rasterize segments for corner scoring, including sparse source paths.
    pixels = {}
    for path in paths:
        for index in range(len(path)):
            x1, y1 = path[index]
            x2, y2 = path[index + 1] if index + 1 < len(path) else path[index]
            steps = max(abs(x2 - x1), abs(y2 - y1), 1)

            # Bound scoring work for coordinates outside the mainland bounds.
            steps = min(steps, 4 * (map_width + map_height))
            for step in range(steps + 1):
                x = int(x1 + (x2 - x1) * step / float(steps))
                y = int(y1 + (y2 - y1) * step / float(steps))
                if x >= 0 and x < map_width and y >= 0 and y < map_height:
                    pixels[(x + left, map_height - 1 - y + top)] = True
    return pixels

def get_best_corner(name, paths, width, height, map_width, map_height, left, top):
    corners = [(1, 1), (width - SHIELD_WIDTH - 1, 1), (1, height - SHIELD_HEIGHT - 1), (width - SHIELD_WIDTH - 1, height - SHIELD_HEIGHT - 1)]
    preferred = preferred_corner(name)
    order = [preferred] + [index for index in range(4) if index != preferred]
    pixels = screen_pixels(paths, map_width, map_height, left, top)
    best = corners[preferred]
    best_score = None
    for index in order:
        x, y = corners[index]
        score = 0
        for px, py in pixels:
            if px >= x and px < x + SHIELD_WIDTH and py >= y and py < y + SHIELD_HEIGHT:
                score += 1
        if best_score == None or score < best_score:
            best_score = score
            best = (x, y)
    return best

def fixed_route_pixels(paths, width, height):
    pixels = []
    seen = {}

    for path in paths:
        for index in range(len(path)):
            x1, y1 = path[index]

            if index + 1 < len(path):
                x2, y2 = path[index + 1]
            else:
                x2, y2 = x1, y1

            dx = x2 - x1
            dy = y2 - y1
            steps = max(abs(dx), abs(dy), 1)

            # Prevent malformed/outlying coordinates from causing
            # unbounded work.
            steps = min(steps, 4 * (width + height))

            for step in range(steps + 1):
                fraction = step / float(steps)

                x = int(math.round(x1 + dx * fraction))
                y = int(math.round(y1 + dy * fraction))

                if x < 0 or x >= width or y < 0 or y >= height:
                    continue

                # Plot coordinates increase upward;
                # widget coordinates increase downward.
                position = (x, height - 1 - y)

                if position not in seen:
                    seen[position] = True
                    pixels.append(position)

    return pixels

def drawing_frames(paths, width, height, color, left, top):
    pixels = fixed_route_pixels(paths, width, height)

    if not pixels:
        return []

    # Construct each pixel once at its permanent location.
    pixel_widgets = [
        padding(
            render.Box(
                width = 1,
                height = 1,
                color = color,
            ),
            left + position[0],
            top + position[1],
        )
        for position in pixels
    ]

    frames = []

    for frame in range(1, DRAW_FRAMES + 1):
        count = (
            len(pixel_widgets) * frame + DRAW_FRAMES - 1
        ) // DRAW_FRAMES

        frames.append(
            render.Stack(
                children = pixel_widgets[:count],
            ),
        )

    full_frame = render.Stack(children = pixel_widgets)
    frames[-1] = full_frame

    for _ in range(HOLD_FRAMES):
        frames.append(full_frame)

    return frames

def error_screen(message):
    return render.Root(child = render.Marquee(width = canvas.width(), child = render.Text(message, font = "5x8", color = "#FFFF00")), show_full_animation = True, delay = FRAME_DELAY)

def main(config):
    if type(all_highways) != "dict":
        return error_screen("Interstate data is not a dictionary")
    keys = sorted([name for name in all_highways.keys() if highway_number(name) != None], key = lambda name: (highway_number(name), name))
    if not keys:
        return error_screen("No valid Interstate names available")
    selection = config.str("highway_selection", "random")
    selected_paths = route_geometry(selection) if selection in keys else []
    if not selected_paths:
        usable = [name for name in keys if route_geometry(name)]
        if not usable:
            return error_screen("No usable Interstate coordinates available")
        selection = usable[random_index(len(usable))]
        selected_paths = route_geometry(selection)
    mainland = mainland_ring()
    bounds = get_bounds(mainland)
    if bounds == None:
        return error_screen("Mainland map geometry has invalid bounds")
    width, height = canvas.width(), canvas.height()
    left, top = 1, 1
    map_width, map_height = width - 2, height - 2
    if map_width < 2 or map_height < 2:
        return error_screen("Canvas too small for Interstate map")
    active = [normalize_coordinates(path, bounds, map_width, map_height) for path in selected_paths]
    layers = []
    mode = config.str("mode", "all")
    if mode not in ["all", "single"]:
        mode = "all"
    if mode == "all":
        background = []
        for name in keys:
            if name != selection:
                background.extend([normalize_coordinates(path, bounds, map_width, map_height) for path in route_geometry(name)])
        if background:
            layers.append(padding(paths_widget(background, map_width, map_height, config.str("system_color", "#444")), left, top))
    outline = normalize_coordinates(mainland, bounds, map_width, map_height)
    layers.append(padding(paths_widget([outline], map_width, map_height, config.str("map_color", "#0F0")), left, top))
    frames = drawing_frames(active, map_width, map_height, config.str("highlight_color", "#F00"), left, top)
    layers.append(render.Animation(children = frames))
    if config.bool("show_sign", True):
        if width >= SHIELD_WIDTH + 2 and height >= SHIELD_HEIGHT + 2:
            x, y = get_best_corner(selection, active, width, height, map_width, map_height, left, top)
            layers.append(padding(get_interstate_sign(highway_number(selection)), x, y))
    return render.Root(child = render.Stack(children = layers), show_full_animation = True, delay = FRAME_DELAY)

def get_schema():
    keys = sorted([name for name in all_highways.keys() if highway_number(name) != None], key = lambda name: (highway_number(name), name))
    options = [schema.Option(display = "Random", value = "random")]
    options.extend([schema.Option(display = name, value = name) for name in keys])
    return schema.Schema(version = "1", fields = [
        schema.Dropdown(id = "mode", name = "Display Mode", desc = "How to show the Interstates.", icon = "display", default = "all", options = [schema.Option(display = "Single Highway", value = "single"), schema.Option(display = "Highlight one but show all", value = "all")]),
        schema.Dropdown(id = "highway_selection", name = "Interstate", desc = "Select a route or choose randomly on each render.", icon = "road", default = "random", options = options),
        schema.Toggle(id = "show_sign", name = "Show Sign", desc = "Choose a corner with the least selected-route overlap.", icon = "shield", default = True),
        schema.Color(id = "map_color", name = "Map Color", desc = "Color of the USA outline.", icon = "map", default = "#0F0"),
        schema.Color(id = "highlight_color", name = "Highlight Color", desc = "Color of the selected highway.", icon = "brush", default = "#F00"),
        schema.Color(id = "system_color", name = "Other Highways", desc = "Color of background highways.", icon = "circleNodes", default = "#444"),
    ])
