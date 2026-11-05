"""
Applet: Florida Lighthouses
Summary: Displays Florida lighthouses
Description: Displays Florida lighthouse locations and highlights visited sites.
Author: Robert Ison
"""

load("florida_cities.star", "FLORIDA_CITIES")
load("florida_lighthouses.star", "FLORIDA_LIGHTHOUSES")
load("florida_map.star", "FLORIDA_MAP")
load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load(
    "support_files/lighthouse_animation.gif",
    LIGHTHOUSE_GIF_ASSET = "file",
)
load(
    "support_files/lighthouse_animation_2x.gif",
    LIGHTHOUSE_GIF_2X_ASSET = "file",
)

MAP_CITIES_COLOR = "#ff0000"
VISITED_COLOR = "#ffff00"
UNVISITED_COLOR = "#565a06"
BRIGHT_OUTLINE_COLOR = "#ffffff"
DULL_OUTLINE_COLOR = "#111111"

# Preserve these IDs so existing visited selections still match.
CONFIG_PATTERN_LIGHTHOUSES = "Item_%s_%s"

def is_square():
    """True when the canvas is square."""
    width, height = canvas.size()
    return width == height

def get_layout():
    """Resolve scene, map, artwork, and text sizing together.

    Square panels retain the original 64x32 scene, centered on the
    panel. Square layout takes precedence over the 2x flag.
    """
    square = is_square()
    use_2x = canvas.is2x() and not square

    if square:
        scene_width = 64
        scene_height = 32
    else:
        scene_width = canvas.width()
        scene_height = canvas.height()

    if use_2x:
        map_width = 80
        map_height = 50
        count_font = "terminus-16"
        count_height = 16
        count_margin = 2
    else:
        map_width = 45
        map_height = 30
        count_font = "5x8"
        count_height = 8
        count_margin = 1

    return {
        "square": square,
        "use_2x": use_2x,
        "scene_width": scene_width,
        "scene_height": scene_height,
        "map_pixel_size": [
            min(map_width, scene_width),
            min(map_height, scene_height),
        ],
        "count_font": count_font,
        "count_height": count_height,
        "count_margin": count_margin,
    }

def center_on_square(child, layout):
    """Center an already-bounded scene on square panels."""
    if not layout["square"]:
        return child

    return render.Box(
        width = canvas.width(),
        height = canvas.height(),
        child = child,
    )

def lighthouse_setting_id(longitude, latitude):
    return CONFIG_PATTERN_LIGHTHOUSES % (
        longitude,
        latitude,
    )

def visited_lighthouse_count(config):
    """Count selected lighthouse entries, not illuminated pixels."""
    count = 0

    for lighthouse in FLORIDA_LIGHTHOUSES:
        if config.bool(
            lighthouse_setting_id(
                lighthouse[3],
                lighthouse[4],
            ),
            False,
        ):
            count += 1

    return count

def append_visited_count(children, config, color, layout):
    text = "{}/{}".format(
        visited_lighthouse_count(config),
        len(FLORIDA_LIGHTHOUSES),
    )

    margin = layout["count_margin"]

    x = margin
    y = max(
        0,
        layout["scene_height"] -
        layout["count_height"] -
        margin,
    )

    children.append(
        render.Padding(
            child = render.Text(
                text,
                color = color,
                font = layout["count_font"],
            ),
            pad = (x, y, 0, 0),
        ),
    )

def main(config):
    layout = get_layout()

    is_display_cities = config.bool("displayMajorCities", False)
    is_display_picks = config.bool("pickVisits", False)
    is_display_art = config.bool("displayArtwork", True)
    is_display_count = config.bool("showVisitedCount", False)

    # Avoid an unexpectedly empty lighthouse layer when
    # highlighting is disabled.
    hide_unvisited = (
        config.bool("hideUnvisited", False) and
        is_display_picks
    )

    cities_color = (
        config.get("citiesColor", MAP_CITIES_COLOR) or
        MAP_CITIES_COLOR
    )
    visited_color = (
        config.get("visitedColor", VISITED_COLOR) or
        VISITED_COLOR
    )
    unvisited_color = (
        config.get("unvisitedColor", UNVISITED_COLOR) or
        UNVISITED_COLOR
    )

    # Coordinate order is longitude, latitude.
    lighthouse_coordinates = [
        [lighthouse[3], lighthouse[4]]
        for lighthouse in FLORIDA_LIGHTHOUSES
    ]

    # Preserve the original geographic framing:
    # map outline, expanded as needed for lighthouse locations.
    map_area = define_map_area(FLORIDA_MAP)
    map_area = define_map_area(
        lighthouse_coordinates,
        map_area,
    )

    # Establish the scene's minimum bounds independently of the
    # artwork, map markers, cities, and visited count.
    map_items = [
        render.Box(
            width = layout["scene_width"],
            height = layout["scene_height"],
        ),
    ]

    if map_area == None:
        return render.Root(
            child = center_on_square(
                render.Stack(children = map_items),
                layout,
            ),
        )

    if is_display_art:
        if layout["use_2x"]:
            lighthouse_animation = LIGHTHOUSE_GIF_2X_ASSET.readall()
        else:
            lighthouse_animation = LIGHTHOUSE_GIF_ASSET.readall()

        map_items.append(
            render.Image(src = lighthouse_animation),
        )

    map_outline_color = (
        DULL_OUTLINE_COLOR if is_display_art else BRIGHT_OUTLINE_COLOR
    )

    # Map outline.
    append_items_to_render(
        map_items,
        get_map_points(
            FLORIDA_MAP,
            map_area,
            layout["map_pixel_size"],
        ),
        map_outline_color,
    )

    # Major cities.
    if is_display_cities:
        append_items_to_render(
            map_items,
            get_map_points(
                FLORIDA_CITIES,
                map_area,
                layout["map_pixel_size"],
            ),
            cities_color,
        )

    # All lighthouse locations, unless visited-only view is active.
    if not hide_unvisited:
        append_items_to_render(
            map_items,
            get_map_points(
                lighthouse_coordinates,
                map_area,
                layout["map_pixel_size"],
            ),
            unvisited_color,
        )

    # Any selected lighthouse lights its pixel, even when
    # another lighthouse projects to that same pixel.
    if is_display_picks:
        append_items_to_render(
            map_items,
            get_map_points(
                lighthouse_coordinates,
                map_area,
                layout["map_pixel_size"],
                config,
            ),
            visited_color,
        )

    # The count reflects saved selections even when visited
    # highlighting is temporarily switched off.
    if is_display_count:
        append_visited_count(
            map_items,
            config,
            visited_color,
            layout,
        )

    return render.Root(
        child = center_on_square(
            render.Stack(children = map_items),
            layout,
        ),
    )

def define_map_area(map_coordinates, existing_area = None):
    if existing_area != None:
        longitude_range = [
            existing_area[0][0],
            existing_area[0][1],
        ]
        latitude_range = [
            existing_area[1][0],
            existing_area[1][1],
        ]
    elif map_coordinates:
        longitude_range = [
            map_coordinates[0][0],
            map_coordinates[0][0],
        ]
        latitude_range = [
            map_coordinates[0][1],
            map_coordinates[0][1],
        ]
    else:
        return None

    for longitude, latitude in map_coordinates:
        longitude_range[0] = min(
            longitude_range[0],
            longitude,
        )
        longitude_range[1] = max(
            longitude_range[1],
            longitude,
        )
        latitude_range[0] = min(
            latitude_range[0],
            latitude,
        )
        latitude_range[1] = max(
            latitude_range[1],
            latitude,
        )

    return [longitude_range, latitude_range]

def get_map_points(
        map_coordinates,
        map_area,
        pixel_area,
        config = None):
    width = pixel_area[0]
    height = pixel_area[1]

    if width <= 0 or height <= 0:
        return []

    # Stored as columns: map_array[x][y].
    map_array = [
        [0 for y in range(height)]
        for x in range(width)
    ]

    if map_area == None:
        return map_array

    min_longitude = map_area[0][0]
    max_longitude = map_area[0][1]
    min_latitude = map_area[1][0]
    max_latitude = map_area[1][1]

    longitude_span = max_longitude - min_longitude
    latitude_span = max_latitude - min_latitude

    for longitude, latitude in map_coordinates:
        # Preserve geographic framing rather than moving
        # outlying coordinates onto an unrelated edge pixel.
        if longitude < min_longitude or longitude > max_longitude:
            continue

        if latitude < min_latitude or latitude > max_latitude:
            continue

        if config != None:
            if not config.bool(
                lighthouse_setting_id(longitude, latitude),
                False,
            ):
                continue

        if longitude_span > 0:
            x = int(math.round(
                (longitude - min_longitude) /
                longitude_span *
                (width - 1),
            ))
        else:
            x = (width - 1) // 2

        if latitude_span > 0:
            y = height - 1 - int(math.round(
                (latitude - min_latitude) /
                latitude_span *
                (height - 1),
            ))
        else:
            y = (height - 1) // 2

        if x < 0 or x >= width or y < 0 or y >= height:
            continue

        # Shared pixels are intentional: any included location
        # is enough to illuminate the pixel.
        map_array[x][y] = 1

    return map_array

def append_items_to_render(children, points, color):
    for x in range(len(points)):
        for y in range(len(points[x])):
            if points[x][y] > 0:
                children.append(
                    render.Padding(
                        child = render.Circle(
                            diameter = 1,
                            color = color,
                        ),
                        pad = (x, y, 0, 0),
                    ),
                )

    return children

def get_lighthouses(enabled):
    if str(enabled).lower() != "true":
        return []

    items = sorted(
        FLORIDA_LIGHTHOUSES,
        key = lambda item: item[0],
    )

    return [
        schema.Toggle(
            id = lighthouse_setting_id(
                item[3],
                item[4],
            ),
            name = item[0],
            desc = str(item[5]) if item[5] != None else "",
            icon = "towerCell",
            default = False,
        )
        for item in items
    ]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "displayArtwork",
                name = "Show Background Artwork",
                desc = "Display the animated lighthouse background.",
                icon = "photoFilm",
                default = True,
            ),
            schema.Toggle(
                id = "displayMajorCities",
                name = "Show Major Cities",
                desc = "Display major Florida cities.",
                icon = "city",
                default = False,
            ),
            schema.Toggle(
                id = "pickVisits",
                name = "Highlight Visited Lighthouses",
                desc = "Highlight your selected lighthouse locations.",
                icon = "highlighter",
                default = False,
            ),
            schema.Generated(
                id = "lighthouseList",
                source = "pickVisits",
                handler = get_lighthouses,
            ),
            schema.Toggle(
                id = "hideUnvisited",
                name = "Hide Unvisited Lighthouses",
                desc = (
                    "Show only visited lighthouse markers when " +
                    "Highlight Visited Lighthouses is enabled."
                ),
                icon = "towerCell",
                default = False,
            ),
            schema.Toggle(
                id = "showVisitedCount",
                name = "Show Visited Count",
                desc = (
                    "Show visited/total in the lower-left corner " +
                    "of the map scene. " +
                    "Counts lighthouse entries, not map pixels."
                ),
                icon = "info",
                default = False,
            ),
            schema.Color(
                id = "visitedColor",
                name = "Visited Lighthouse Color",
                desc = "Color of visited markers and the optional count.",
                icon = "brush",
                default = VISITED_COLOR,
            ),
            schema.Color(
                id = "unvisitedColor",
                name = "Unvisited Lighthouse Color",
                desc = "Color of unvisited lighthouse markers.",
                icon = "brush",
                default = UNVISITED_COLOR,
            ),
            schema.Color(
                id = "citiesColor",
                name = "Major City Color",
                desc = "Color of major city markers.",
                icon = "brush",
                default = MAP_CITIES_COLOR,
            ),
        ],
    )
